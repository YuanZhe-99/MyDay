# Adaptive Layout

How MyDay!!!!! decides what to do with the extra room a tablet, a desktop window, or an unfolded
foldable gives it — and, just as importantly, when it decides to do nothing.

Every number on this page lives in exactly one place in the code:
`lib/shared/utils/adaptive_layout.dart`. That module imports nothing from Flutter, so every rule is
a pure function that can be checked at fifty viewports in milliseconds
(`test/adaptive_layout_test.dart`). **If a widget file contains a numeric width comparison, it is a
bug** — the number belongs here and the page calls a named predicate.

The conventions are shared with the sibling apps in this series; the portable write-up they were
taken from is `ADAPTIVE-LAYOUT-GUIDE.md`, kept beside the repositories.

## The three rules

Three separate questions get three separate rules, and none of them is routed through another:

| Question | Rule | Measures |
|---|---|---|
| May this layout split? | `canSplitLayout(width, height)` | The whole screen's **shape** |
| Where does navigation live? | `useNavigationRail(screenWidth)` | **Width only** |
| How many of these fit? | `columnCapacity(contentWidth, minItemWidth: …)` | The **content box** width |

## Rule A — when may a layout split?

```dart
const splitMinWidth  = 600.0;  // Material medium width class; Android sw600dp
const splitMinHeight = 480.0;  // compact/medium height boundary
const splitMinAspect = 0.82;   // width / height
```

All three conditions must hold. None of them alone is enough.

### The aspect test is the load-bearing one

This is why the rule is **not** a plain width breakpoint, and it exists because of one device.

The Galaxy Z Fold 8 unfolds to a **4:3 landscape** panel (2448 x 1848 px). Held in portrait it is
3:4 — *narrower relative to its height than the near-square Fold 7 it replaced*, despite being
newer. The Fold 8 Ultra went the other way. One generation spans roughly 672 – 954 logical pixels
unfolded, and **one device needs two different answers at one width**. No width threshold can
produce that; an aspect test can.

Pixel counts are authoritative. Logical pixels depend on the density bucket and on Samsung's
user-adjustable *Display size* setting, so treat dp figures as ranges.

| Device | Inner panel, px | Portrait W:H | Portrait W, dp | Portrait | Landscape |
|---|---|---|---|---|---|
| Galaxy Z Fold 5 | 1812 x 2176 | 0.83 | 659–690 | split | split |
| Galaxy Z Fold 6 | 1856 x 2160 | 0.86 | 675–707 | split | split |
| **Galaxy Z Fold 8** | **2448 x 1848 (4:3 landscape)** | **0.755** | **672–704** | **single** | **split** |
| Galaxy Z Fold 7 | 1968 x 2184 | 0.90 | 716–750 | split | split |
| Galaxy Z Fold 8 Ultra | 2256 x 2504 | 0.90 | 820–859 | split | split |
| Pixel 9 / 10 Pro Fold | 2076 x 2152 | 0.96 | 755–791 | split | split |

`0.82` sits near the middle of the gap between the Fold 8's `0.755` and the Fold 7 / Ultra's
`0.90` — about 9% of margin on each side. Changing this constant is a whole-app behavior change.

### The width floor

Every unfolded panel clears 600 dp by at least ~59 dp even at the denser end of its range, and
every folded cover screen sits well below it (Fold 7 / Ultra ~ 360 dp, Fold 8 ~ 356–416 dp,
Pixel 10 Pro Fold ~ 411 dp). The floor separates "unfolded" from "cover screen" without naming a
device.

### The height floor

The aspect test alone admits **wide and short** viewports. Without the floor, a folded Fold 8 cover
screen in landscape (~657 x 416 dp) and an ordinary phone in landscape (~915 x 412 dp) would both
split into two cramped panes. Google's guidance agrees independently: on a phone or an open
flippable in landscape, width is medium but height is compact, and two-pane layouts are not
practical there.

### The consequence, accepted up front

The rule is about **shape, not device class**. A 4:3 tablet in portrait (768 x 1024 → 0.75) and a
16:10 tablet in portrait (0.625) stay single-column, exactly like the Fold 8 in portrait. Both
split in landscape. If someone reports "my tablet doesn't split in portrait", that is the rule
working.

## Rule B — where does navigation live? (width only)

```dart
const navRailMinWidth = 600.0;
const navRailWidth    = 81.0;  // 80 dp NavigationRail + 1 dp VerticalDivider
```

`useNavigationRail` is **width only, on purpose, and is not routed through `canSplitLayout`.** A
rail is not a split. It trades width — abundant whenever the test passes — for height, which is
not. The case it helps most is precisely the one the split rule rejects: a phone in landscape at
915 x 412, where a bottom bar spends 19% of the height on navigation while 915 dp of width sits
unused.

`ShellScaffold` (`lib/shared/widgets/shell_scaffold.dart`) builds the rail and the bottom bar from
**one destination list**, so a destination can never end up in one and not the other, or in a
different order between them — including the Intimacy destination, which is filtered out in that
one place when the module is hidden. The rail sets `groupAlignment: 0`: the default top alignment
is for rails that sit under a leading menu button or FAB, and MyDay's has neither, so
top-aligned destinations would leave the whole lower half of a tall rail empty. It is wrapped in
`SingleChildScrollView` + `ConstrainedBox(minHeight:)` because a rail can appear at compact heights
(915 x 412), where it must scroll rather than overflow.

Pages inside the shell compute capacities from `shellContentWidth(screenWidth)`, which subtracts
the rail exactly when the rail is showing. **Pages pushed on top of the shell** — everything
reached with `Navigator.push` — have no rail to subtract; they measure their own
`LayoutBuilder` constraints and must not call `shellContentWidth`.

Deliberately not done: a `NavigationDrawer` above 1240 dp. The rail is correct through extra-large,
and a third navigation mode is not worth its cost.

## Rule C — how many fit? (adaptive minimum width)

`columnCapacity` asks how many columns of a stated minimum width fit a content box, rather than
hardcoding a count per breakpoint. One gap is added to the numerator so the arithmetic pays for the
gaps *between* columns rather than one after every column.

Each caller brings the minimum its own content needs, and the constant's doc comment states where
the number came from.

`listColumnCount` combines the gate and the capacity for user-pinnable counts, and **clamps rather
than rejects** a stored preference. That is what lets a preference chosen on a desktop survive
being carried onto a folded phone and come back on unfolding. The control that sets it
(`listColumnsButton` in `lib/shared/widgets/adaptive_tile_grid.dart`) is **hidden**, not disabled,
when capacity is 1, so it never appears on a phone or a cover screen. The preference is stored in
`storage_config.json`, which is device-local and never synced — window size is a property of the
device, not of the account.

## Measure the screen for the gate, the content box for the capacity

This asymmetry is deliberate and easy to get wrong.

- **Gate** (`canSplitLayout`, `useNavigationRail`) reads `MediaQuery.sizeOf(context)` — the whole
  screen. Measuring the split decision against the `Scaffold` body would subtract the app bar from
  the height and inflate the ratio, reading a Fold 8 in portrait as 0.80 instead of 0.755 and
  leaving almost no margin under the threshold.
- **Capacity and pane widths** read what the content actually gets: `shellContentWidth(screenWidth)`
  less the page's own padding, or `LayoutBuilder`'s `constraints.maxWidth`.

The gate asks about the window's *shape*, which the rail does not change. The capacity asks how
much room is left, which the rail very much does.

## Adoption status

The policy module and both shared widgets landed whole in **v1.4.0**, together with the shell's
adoption of Rule B. Rules A and C are provided by the module and exercised by
`test/adaptive_layout_test.dart`; the pages that call them are being converted in subsequent
releases, page by page, and each page's own decision is recorded here as it lands.

| Surface | Rule it uses | Since |
|---|---|---|
| `ShellScaffold` — rail vs bottom bar | B (width only) | v1.4.0 |

**One inline breakpoint is still outstanding.** `intimacy_page.dart`'s toy/partner detail summary
card still carries `constraints.maxWidth >= 720 / >= 360` for its metric grid; it is routed through
`columnCapacity` when that page is converted. Until then, the invariant above is a rule the code is
being brought to, not a claim about the whole tree. The check is:

```bash
grep -rnE "maxWidth *[<>]=? *[0-9]|size\.width *[<>]=? *[0-9]" lib/
```

## Divergences from the guide, recorded on purpose

1. **No `shellListBottomInset`.** The guide has shell pages drop their bottom-bar reservation when
   a rail appears. MyDay's `Scaffold` does not set `extendBody`, so the body already ends above the
   bottom bar — the `SizedBox(height: 80)` spacers in the shell pages are **FAB clearance**, and
   the FAB stays bottom-right in both modes. They are correct at 80 either way, and a named
   constant that never varies would be a number with nothing to say.
2. **Stored column preferences are for the shell's own list surfaces only.** Pages pushed on top of
   the shell are to use auto capacity with no stored preference and no column button, so the
   settings surface does not grow one control per sub-page.

## Divergence from Google's guidance, stated on purpose

Google's adaptive-layout guidance says window size classes are "explicitly not determined by the
size of the device screen" and are "not intended for *isTablet*-type logic", and directs apps to
decide from available width rather than aspect ratio.

This convention **deliberately diverges on exactly one point: the aspect test.** It is not an
oversight. Width alone cannot give the Fold 8 two different answers in its two orientations, and
that behavior — split in landscape, single column in portrait — is the requirement the rule exists
to satisfy.

Everything else follows Google exactly: the width and height floors are its breakpoints, the column
capacity is its feed guidance, and the navigation rail at medium width and up is its recommendation
verbatim.

## Folding and unfolding at runtime

`android/app/src/main/AndroidManifest.xml` declares `screenLayout|screenSize|smallestScreenSize|
density` (among others) in the activity's `configChanges`. The window then resizes **without
restarting the activity**, so everything reading `MediaQuery.sizeOf` re-evaluates on the next
frame. That is all "switch automatically when the device unfolds" needs — no lifecycle work, no
state to save and restore. Without it the activity recreates and any un-persisted page state is
lost mid-fold. See [platform-notes.md](platform-notes.md).

## Testing

1. **Pure-function tests** (`test/adaptive_layout_test.dart`): every threshold at `n - 1` and `n`,
   every clamp at both ends, and loop assertions for invariants across a range. Each viewport names
   the real device it stands for, so a regression reports the device it would break rather than a
   bare number.
2. **Widget tests** on the rendered pages at the same geometries (`test/shell_nav_ui_test.dart` and
   the per-page layout tests): assert relative positions (same `y`, different `x`) rather than
   absolute pixels, and always `expect(tester.takeException(), isNull)` to catch overflow stripes.
3. Two things bite in widget tests:
   - **`flutter_test` renders every glyph of its default font as a full em square**, inflating a
     Latin label to roughly 2.5x its real width, so a layout test can report overflow at a width
     that is perfectly comfortable in production. Layout tests are therefore driven in Simplified
     Chinese (`Locale('zh')` plus Chinese `find.text` targets) — CJK glyphs really are square, so
     the test measures the real production layout. The test files say so in their header comments.
   - **The default 800 x 600 test viewport passes `canSplitLayout`.** Any test that cares must pin
     an explicit viewport, or it will silently start exercising a two-pane path.
4. **Live resize on desktop** across each threshold, plus a soft-keyboard check on any pane that is
   supposed not to scroll.

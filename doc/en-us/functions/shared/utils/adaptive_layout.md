# lib/shared/utils/adaptive_layout.dart

The app-wide layout policy module: every threshold, every clamp, and every rule that decides what
MyDay does with the room a tablet, a desktop window, or an unfolded foldable gives it. **It imports
nothing** — not `package:flutter/*`, not even `dart:math` — so every decision is a pure function
testable without pumping a widget tree, and one device answers the same way everywhere in the app.

The prose derivation of each number lives in [../../../adaptive-layout.md](../../../adaptive-layout.md);
this page is the declaration-by-declaration reference. The consumers are
[../widgets/shell_scaffold.md](../widgets/shell_scaffold.md) (the navigation rail) and
[../widgets/adaptive_tile_grid.md](../widgets/adaptive_tile_grid.md) (multi-column list rows and
the column-count control).

The invariant this module exists to protect: **a numeric width comparison inside a widget file is a
bug.** The number belongs here, with a doc comment saying where it came from, and the page calls a
named predicate.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `splitMinWidth` | top-level `const double` | B | Minimum viewport width before a layout may split (600). |
| `splitMinHeight` | top-level `const double` | B | Minimum viewport height before a layout may split (480). |
| `splitMinAspect` | top-level `const double` | B | Minimum width-to-height ratio before a layout may split (0.82). |
| `listTileGap` | top-level `const double` | B | Horizontal gap between columns of a multi-column list (12). |
| `listMaxColumns` | top-level `const int` | B | Ceiling on list columns however wide the window is (4). |
| `listColumnsAuto` | top-level `const int` | B | Column preference meaning "use whatever fits" (0). |
| `navRailMinWidth` | top-level `const double` | B | Minimum screen width before the shell shows a navigation rail (600). |
| `navRailWidth` | top-level `const double` | B | Logical pixels the rail takes from the content when shown (81). |
| [`canSplitLayout`](#cansplitlayout) | top-level function | A | Report whether a layout may split into panes or columns. |
| [`useNavigationRail`](#usenavigationrail) | top-level function | A | Report whether the shell should show a navigation rail. |
| [`shellContentWidth`](#shellcontentwidth) | top-level function | A | Return the width a shell page's content actually receives. |
| [`columnCapacity`](#columncapacity) | top-level function | A | Return how many columns of a given minimum width fit a content box. |
| [`listRowCount`](#listrowcount) | top-level function | A | Return how many rows a list of items needs at a column count. |
| [`listColumnCount`](#listcolumncount) | top-level function | A | Return the number of columns a list should actually render. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/utils/adaptive_layout.dart` reports 6 against 14
rows. The eight top-level `const` declarations carry a prose doc comment stating where their value
came from rather than a `Purpose:` block, matching how the index treats top-level constants
elsewhere; they are part of the file's surface and therefore get rows. All six functions are Tier A
per the blanket rule for top-level functions under `shared/`. The constants are Tier B: their whole
content is the value and the reason for it, both of which the table and
[../../../adaptive-layout.md](../../../adaptive-layout.md) already carry.

## Constants

The three split thresholds, the two navigation-rail figures, and the three list figures are the
whole numeric surface of MyDay's layout policy. Their values are shared with the sibling apps and
must not be changed without reading [../../../adaptive-layout.md](../../../adaptive-layout.md)
first — `splitMinAspect` in particular is a whole-app behavior change.

| Constant | Value | Where the number came from |
|---|---|---|
| `splitMinWidth` | `600.0` | Material's *medium* width class and Android's `sw600dp` tablet threshold. Every unfolded foldable panel clears it by ~59 dp; every folded cover screen sits well below it. |
| `splitMinHeight` | `480.0` | The boundary between Android's compact and medium height classes. Without it the aspect test would admit wide, short viewports — a folded cover screen or a phone held in landscape — and split them into two cramped panes. |
| `splitMinAspect` | `0.82` | Sits near the middle of the gap between the Galaxy Z Fold 8's 0.755 (4:3 panel held in portrait) and the Fold 7 / Fold 8 Ultra's 0.90, ~9% of margin on each side. |
| `listTileGap` | `12.0` | The spacing between columns; also the gap term in `columnCapacity`'s arithmetic. |
| `listMaxColumns` | `4` | A ceiling so a very wide desktop window does not shred a list into unreadably narrow columns. |
| `listColumnsAuto` | `0` | The sentinel preference value meaning "derive from width"; distinct from any real column count, which starts at 1. |
| `navRailMinWidth` | `600.0` | Material's *medium* width class, where Google's guidance moves navigation to the side. Equal to `splitMinWidth` by coincidence of the same Material breakpoint, not by dependency — the two rules are deliberately independent. |
| `navRailWidth` | `81.0` | An 80 dp `NavigationRail` plus the 1 dp `VerticalDivider` beside it. |

## Documentation

### `bool canSplitLayout(double width, double height)` <a id="cansplitlayout"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/adaptive_layout.dart` (line 51)
- **Purpose:** Answer the app-wide question "may this layout split into panes or columns?" from the
  shape of the whole screen.
- **Inputs:** `width`, `height` — the viewport size in logical pixels, normally
  `MediaQuery.sizeOf(context)`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:**
  1. `width < splitMinWidth` → `false`.
  2. `height < splitMinHeight` → `false`.
  3. `height <= 0` → `false` (guards the division below against a degenerate viewport).
  4. Return `width / height >= splitMinAspect`.
- **Usage:**
  ```dart
  final screen = MediaQuery.sizeOf(context);
  if (!canSplitLayout(screen.width, screen.height)) return singleColumnBody;
  ```
- **Notes:** Three independent conditions, because none of them alone is enough. The aspect test is
  the load-bearing one: it is what lets a Galaxy Z Fold 8 split in landscape (4:3) but not in
  portrait (3:4) — one device needing two different answers at one width, which no width threshold
  can produce. The consequence to accept is that this is a rule about **shape, not device class**:
  a 4:3 tablet in portrait (0.75) stays single-column exactly like the Fold 8 does. Pass the
  **screen** size, never the `Scaffold` body's — subtracting the app bar from the height inflates
  the ratio and would read a Fold 8 in portrait as 0.80 rather than 0.755.

### `bool useNavigationRail(double screenWidth)` <a id="usenavigationrail"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/adaptive_layout.dart` (line 68)
- **Purpose:** Decide whether the shell renders its destinations as a side `NavigationRail` or a
  bottom `NavigationBar`.
- **Inputs:** `screenWidth` — the whole screen width in logical pixels.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `screenWidth >= navRailMinWidth`.
- **Usage:**
  ```dart
  if (!useNavigationRail(MediaQuery.sizeOf(context).width)) {
    return Scaffold(body: widget.child, bottomNavigationBar: NavigationBar(...));
  }
  ```
  (`lib/shared/widgets/shell_scaffold.dart` — see
  [../widgets/shell_scaffold.md#build](../widgets/shell_scaffold.md#build).)
- **Notes:** **Width only, deliberately, and must not be routed through `canSplitLayout`.** A rail
  is not a split: it trades width, which is abundant whenever this returns true, for height, which
  is not. The case it helps most is exactly the one `canSplitLayout` rejects on purpose — a phone
  held in landscape at 915 x 412, where a bottom bar spends 19% of the height on navigation while
  915 logical pixels of width sit unused.

### `double shellContentWidth(double screenWidth)` <a id="shellcontentwidth"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/adaptive_layout.dart` (line 80)
- **Purpose:** Return the width a page **inside the shell** actually receives, with the navigation
  rail subtracted whenever the rail is showing.
- **Inputs:** `screenWidth` — the whole screen width in logical pixels.
- **Returns:** `double`, never negative.
- **Side effects:** None.
- **Algorithm:** `useNavigationRail(screenWidth) ? screenWidth - navRailWidth : screenWidth`,
  floored at 0.
- **Usage:**
  ```dart
  final contentWidth = shellContentWidth(MediaQuery.sizeOf(context).width);
  final columns = columnCapacity(contentWidth - 32, minItemWidth: 320);
  ```
- **Notes:** Pass the result wherever a **capacity** is being computed, and keep passing the
  untouched screen size to `canSplitLayout`, which asks about the window's shape rather than the
  room left inside it. **Pages pushed on top of the shell** — everything reached with
  `Navigator.push` — have no rail to subtract, so their `LayoutBuilder` constraints already are the
  whole width; calling this there would silently lose 81 dp.

### `int columnCapacity(double contentWidth, {required double minItemWidth, double gap = listTileGap, int maxColumns = listMaxColumns})` <a id="columncapacity"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/adaptive_layout.dart` (line 97)
- **Purpose:** Answer "how many columns of this content's own minimum width fit in this box?"
  instead of hardcoding a column count per breakpoint.
- **Inputs:** `contentWidth` — the width available, in logical pixels; `minItemWidth` — the
  narrowest one column may be; `gap` — spacing between columns; `maxColumns` — a ceiling however
  wide the box is.
- **Returns:** `int`, at least 1 and at most `maxColumns`.
- **Side effects:** None.
- **Algorithm:**
  1. `ceiling = maxColumns < 1 ? 1 : maxColumns`.
  2. `contentWidth <= 0` → return 1.
  3. `minItemWidth <= 0` → return `ceiling`.
  4. Return `((contentWidth + gap) / (minItemWidth + gap)).floor().clamp(1, ceiling)`.
- **Usage:**
  ```dart
  final columns = columnCapacity(contentWidth, minItemWidth: 320, maxColumns: 3);
  ```
- **Notes:** The `+ gap` in the numerator is the whole trick: it makes the arithmetic pay for the
  gaps *between* columns rather than one after every column, so two 320-wide columns need 652 and
  not 664. Every caller brings its own `minItemWidth`, and the constant carrying that number
  states in its doc comment what content the number is measuring. The two degenerate guards mean a
  caller can pass a not-yet-laid-out width without special-casing it.

### `int listRowCount(int itemCount, int columns)` <a id="listrowcount"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/adaptive_layout.dart` (line 116)
- **Purpose:** Return how many rows a flat list of items occupies at a given column count.
- **Inputs:** `itemCount`, `columns`.
- **Returns:** `int` — 0 for an empty list, otherwise the ceiling division.
- **Side effects:** None.
- **Algorithm:** `itemCount <= 0` → 0; `perRow = columns < 1 ? 1 : columns`; return
  `(itemCount + perRow - 1) ~/ perRow`.
- **Usage:** Called by `adaptiveTileRows` to drive its row builder — see
  [../widgets/adaptive_tile_grid.md#adaptivetilerows](../widgets/adaptive_tile_grid.md#adaptivetilerows).
- **Notes:** The last row may be short; callers pad it with empty cells so the remaining tiles keep
  their width instead of stretching across the row.

### `int listColumnCount({required double screenWidth, required double screenHeight, required double contentWidth, required double minItemWidth, required int preference, int maxColumns = listMaxColumns})` <a id="listcolumncount"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/adaptive_layout.dart` (line 136)
- **Purpose:** Combine the split gate, the capacity, and a stored user preference into the single
  number of columns a list should render.
- **Inputs:** `screenWidth`, `screenHeight` — the whole screen, which decides whether splitting is
  allowed at all; `contentWidth` — the width the list itself gets; `minItemWidth` — the narrowest
  one column may be; `preference` — `listColumnsAuto` or a pinned count; `maxColumns`.
- **Returns:** `int`, at least 1.
- **Side effects:** None.
- **Algorithm:**
  1. `!canSplitLayout(screenWidth, screenHeight)` → return 1.
  2. `capacity = columnCapacity(contentWidth, minItemWidth: minItemWidth, maxColumns: maxColumns)`.
  3. `preference == listColumnsAuto` → return `capacity`.
  4. Return `preference.clamp(1, capacity)`.
- **Usage:**
  ```dart
  final columns = listColumnCount(
    screenWidth: screen.width,
    screenHeight: screen.height,
    contentWidth: shellContentWidth(screen.width),
    minItemWidth: 320,
    preference: settings.someListColumns,
    maxColumns: 3,
  );
  ```
- **Notes:** The gate reads the **screen** while the capacity reads the **list's own width**,
  deliberately — see `canSplitLayout`'s Notes for why measuring the body would break the Fold 8
  case. A pinned preference is **clamped, not rejected**: that is what lets a choice made on a
  desktop survive being carried onto a folded phone and come back on unfolding, rather than being
  overwritten with 1. The control that sets the preference is hidden entirely when capacity is 1,
  so it never appears on a phone or a cover screen.

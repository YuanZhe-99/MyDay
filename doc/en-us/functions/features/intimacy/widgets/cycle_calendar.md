# lib/features/intimacy/widgets/cycle_calendar.dart

Rendering layer for cycle tracking: the stable person-color palette, a single day's indicator
widget, the legend, and a one-person month calendar. It consumes `CyclePrediction`/`CycleDayInfo`
from `services/cycle_predictor.dart` (see
[Body Metrics — Cycle prediction](../../../../algorithms/body-metrics.md#cycle-prediction) for how
phases/fertile-window/ovulation/predicted-starts are computed) and renders exactly the visual
language documented in
[Intimacy](../../../../features/intimacy.md#the-body-layer-v124): solid menses, semi-opaque fertile
window, faint follicular/luteal, a centered ovulation dot, and filled-vs-hollow leading dots for
actual-vs-predicted period starts. `widgets/body_section.dart` embeds `CycleCalendar`/`CycleLegend`
for a single person (in the Body tab), and `views/intimacy_page.dart`'s home calendar calls
`buildCycleDayIndicator` directly, once per visible person, to draw the multi-person overlay rows
described in that same concept-doc section. `cyclePersonColor` (the palette-lookup function actually
called by both consumers) lives in `widgets/body_section.dart`, not in this file — this file only
owns the `cyclePersonPalette` constant it reads from.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `cyclePersonPalette` | top-level constant | B | The 8-color stable palette; slot 0 is always the user, slots 1+ are partners by sorted id. |
| `PersonCycleOverlay` (constructor) | constructor (`PersonCycleOverlay`) | B | Create a person cycle overlay value (key, display name, color, prediction). |
| [`buildCycleDayIndicator`](#buildcycledayindicator) | top-level function | A | Build one day's phase-color bar plus ovulation/start-marker dots for one person. |
| `CycleLegend` (constructor) | constructor (`CycleLegend`) | B | Create a cycle legend instance. |
| `CycleLegend.build` | method (`CycleLegend`) | B | Render the optional per-person chip row plus the phase/ovulation/start-marker legend. |
| `CycleCalendar` (constructor) | constructor (`CycleCalendar`) | B | Create a single-person cycle calendar instance. |
| `CycleCalendar.createState` | method (`CycleCalendar`) | B | Create the mutable `_CycleCalendarState`. |
| `_CycleCalendarState.build` | method (`_CycleCalendarState`) | B | Render the month header (prev/next), weekday row, and day grid. |
| `_CycleCalendarState._buildDayGrid` | method (widget helper) | B | Lay out the month's days into weekday-aligned rows, each cell showing its indicator. |

`grep -c 'Purpose:' lib/features/intimacy/widgets/cycle_calendar.dart` reports 8, one less than the
9 rows above. The difference is `cyclePersonPalette` (line 12): it is a plain top-level `const List
<Color>` with only an ordinary `///` doc comment (no `Purpose:` block), so it does not appear in the
grep count but is still a real top-level declaration and is included in the table for completeness,
consistent with how plain data constants are handled elsewhere in this doc set. Every one of the 8
`/// Purpose:` blocks sits directly above the real declaration it documents — no misattached blocks
(documenting a call site instead of a declaration) were found — and no other undocumented real
declaration (method, getter, setter) exists in the file. Tier split: 1 Tier A, 8 Tier B (counting
`cyclePersonPalette`).

**Reconciliation:** `grep -c 'Purpose:' lib/features/intimacy/widgets/cycle_calendar.dart` reports 8, matching 8 of the 9 rows above exactly. The extra row is `cyclePersonPalette`, a top-level constant colour list with no `Purpose:` block that is nonetheless a real declaration used by `cyclePersonColor`.

## Documentation

### `Widget buildCycleDayIndicator(Color color, CycleDayInfo? info, {double height = 4})` <a id="buildcycledayindicator"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/widgets/cycle_calendar.dart` (line 51)
- **Purpose:** Build the small per-day cycle indicator for one person on one day: a phase-colored
  bar at solid/semi-opaque/faint opacity, an optional centered ovulation dot, and an optional
  leading filled-or-hollow start-day dot.
- **Inputs:** `color` — the person's stable palette color; `info` — that day's `CycleDayInfo` from
  `CyclePrediction.days`, or `null` if the day carries no cycle classification; `height` — bar
  thickness in logical pixels, default `4`.
- **Returns:** `Widget` — an empty `SizedBox(height: height)` when `info` is `null`; otherwise a
  `SizedBox(height: height + 2)` wrapping a `Stack` with the bar and any marker dots.
- **Side effects:** None.
- **Algorithm:**
  1. If `info == null`, return an empty `SizedBox(height: height)` immediately (no cycle data for
     this day).
  2. Compute `opacity` with a `switch` on `info.phase`: `menstrual` → `1.0` (solid); `follicular` →
     `0.55` if `info.inFertileWindow` else `0.18`; `luteal` → `0.55` if in the fertile window else
     `0.32`.
  3. Build a rounded `Container` bar of the given `height`, colored `color.withValues(alpha:
     opacity)`.
  4. If `info.isOvulationDay`, add a centered filled circle of `color` (diameter `height + 2`) on
     top of the bar.
  5. If `info.isActualStart || info.isPredictedStart`, add a leading circle (diameter `height + 2`,
     aligned `centerLeft`): filled with `color` when `info.isActualStart`, otherwise unfilled with
     just a `color` border (`width: 1.2`) — filled marks an actual recorded start, hollow marks a
     predicted one, matching the documented indicator legend.
  6. Return everything inside a `Stack(clipBehavior: Clip.none)` so the dots (which are 2px taller
     than the bar) can overflow the bar's own height without clipping.
- **Usage:**
  ```dart
  // Single-person month calendar (this file, _buildDayGrid, line 383):
  buildCycleDayIndicator(widget.personColor, info),

  // Multi-person home-calendar overlay row (views/intimacy_page.dart, line 2191):
  child: buildCycleDayIndicator(
    cycleOverlays[o].color,
    cycleOverlays[o].prediction.days[date],
    height: 3,
  ),
  ```
- **Notes:** The four opacity constants (`1.0`, `0.55`, `0.18`, `0.32`) are re-declared independently
  inside `CycleLegend.build`'s `bar(...)` calls so the legend swatches visually match this function's
  output — there is no shared constant between the two, so changing one without the other would make
  the legend lie about what the calendar actually shows.

## Related pages

- [Body Metrics — Cycle prediction](../../../../algorithms/body-metrics.md#cycle-prediction) — how
  `CyclePrediction`/`CycleDayInfo` (phase, fertile window, ovulation, actual/predicted start) are
  computed; this file only renders that data, it never derives it.
- [Intimacy](../../../../features/intimacy.md#the-body-layer-v124) — the indicator-rendering
  contract (solid/semi-opaque/faint, ovulation dot, filled/hollow start markers) this file
  implements, and the home-calendar multi-person overlay that also calls
  `buildCycleDayIndicator` directly.
- [`body_page.dart`](../views/body_page.md) — hosts `BodySectionView`, which in turn embeds
  `CycleCalendar`/`CycleLegend` from this file for the user's own cycle tracking.

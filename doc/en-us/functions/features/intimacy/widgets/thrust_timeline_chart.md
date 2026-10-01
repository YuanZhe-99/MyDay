# lib/features/intimacy/widgets/thrust_timeline_chart.dart

`ThrustTimelineChart` (v1.5.5) draws one timed session's cumulative thrust count against the
stopwatch, as described in
[Intimacy — Thrust timeline chart](../../../../features/intimacy.md#thrust-timeline-chart). It is a
stateless `fl_chart` `LineChart` with two series built by
[`ThrustTimeline`](../utils/thrust_timeline.md): the raw cumulative count as a faint **step line**
([`cumulativeSpots`](../utils/thrust_timeline.md#cumulativespots)) and a dashed, curved **moving
average** fit line ([`smoothedSpots`](../utils/thrust_timeline.md#smoothedspots)), plus a two-entry
legend. Its only caller is the record detail page
([`record_detail_page.dart`](../views/record_detail_page.md)), which shows it only when
`IntimacyRecord.hasThrustTimeline` is true.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ThrustTimelineChart({timeline, duration, height = 220})` | constructor (`ThrustTimelineChart`) | B | Create a thrust timeline chart. |
| [`niceStep`](#nicestep) | static method (`ThrustTimelineChart`) | A | Pick a round axis step (1, 2 or 5 times a power of ten) that yields about `targetTicks` ticks. |
| [`formatMinutes`](#formatminutes) | static method (`ThrustTimelineChart`) | A | Format a minute value as an x-axis label (`m` below an hour, `h:mm` from an hour on). |
| [`build`](#build) | method (`ThrustTimelineChart`) | A | Build the chart and its legend, or nothing with fewer than two presses. |
| `_LegendItem({color, dashed, label})` | constructor (`_LegendItem`) | B | Create one legend entry. |
| `_LegendItem.build` | method (`_LegendItem`) | B | Build a short solid or two-segment dashed swatch followed by its label. |

`grep -c 'Purpose:' lib/features/intimacy/widgets/thrust_timeline_chart.dart` reports 6, matching
all 6 rows above exactly (3 Tier A, 3 Tier B). The widget fields (`timeline`, `duration`, `height`;
`color`, `dashed`, `label`) are plain data holders.

## Documentation

### `static double niceStep(double range, int targetTicks, {double minStep = 1})` <a id="nicestep"></a>
- **Kind:** static method of `ThrustTimelineChart`
- **Source:** `lib/features/intimacy/widgets/thrust_timeline_chart.dart` (line 33)
- **Purpose:** Choose grid and label intervals that land on round numbers.
- **Inputs:** `range` — the axis span; `targetTicks` — desired tick count; `minStep` — floor.
- **Returns:** `double` — `1`, `2`, `5` or `10` times a power of ten, at least `minStep`.
- **Side effects:** None.
- **Algorithm:** A non-positive `range` or `targetTicks` returns `minStep`. Otherwise `raw = range /
  targetTicks`, `magnitude = 10^floor(log10(raw))`, `normalized = raw / magnitude`; round
  `normalized` up to the first of 1, 2, 5, 10, multiply back by `magnitude`, and take the maximum
  with `minStep`.
- **Usage:**
  ```dart
  // build, lines 80 and 83:
  final yStep = niceStep(total, 4);
  final xStep = niceStep(maxX, 5);
  ```
- **Notes:** Public for tests (`test/record_detail_page_test.dart`: `niceStep(160, 4) == 50`,
  `niceStep(1000, 4) == 500`, `niceStep(7, 5) == 2`, `niceStep(0, 5) == 1`). The default
  `minStep` of 1 keeps the y grid on whole repetitions and the x grid on whole minutes.

### `static String formatMinutes(double minutes)` <a id="formatminutes"></a>
- **Kind:** static method of `ThrustTimelineChart`
- **Source:** `lib/features/intimacy/widgets/thrust_timeline_chart.dart` (line 55)
- **Purpose:** Label the time axis and the tooltip compactly.
- **Inputs:** `minutes`.
- **Returns:** `String` — the rounded minute count below 60 (`'12'`), otherwise `h:mm` (`'1:15'`).
- **Side effects:** None.
- **Algorithm:** `total = minutes.round()`; below 60 return it as is; otherwise `total ~/ 60`, a
  colon, and `total % 60` padded to two digits.
- **Usage:** The bottom axis's `getTitlesWidget` and the tooltip text in `build`.
- **Notes:** Public for tests. The axis name (`intimacyThrustTimelineMinutes`) says the unit is
  minutes, which is why below an hour the label is a bare number.

### `Widget build(BuildContext context)` <a id="build"></a>
- **Kind:** method of `ThrustTimelineChart` (override of `StatelessWidget.build`)
- **Source:** `lib/features/intimacy/widgets/thrust_timeline_chart.dart` (line 70)
- **Purpose:** Draw the step line, the fit line, the axes, and the legend.
- **Inputs:** `context`; the widget's `timeline`, `duration` and `height`.
- **Returns:** A `Column` of the chart (`SizedBox(height: height)`) and a centred legend `Wrap`, or
  `SizedBox.shrink()` when the timeline has fewer than two events.
- **Side effects:** None.
- **Algorithm:**
  1. Build `raw` and `smooth` from the timeline with `durationMs = duration.inMilliseconds`;
     `maxX` is the later of the two series' last x (falling back to 1 when non-positive).
  2. `yStep = niceStep(total, 4)`; `maxY = ceil(total * 1.05 / yStep) * yStep` — about 5% of
     headroom, rounded up to a grid line, so the final plateau does not sit on the border.
     `xStep = niceStep(maxX, 5)`.
  3. Grid: horizontal lines every `yStep` (`outlineVariant` at alpha 0.3), dashed vertical lines
     every `xStep` (alpha 0.2); left axis labels are whole counts, bottom labels are
     `formatMinutes` under the axis name `intimacyThrustTimelineMinutes`; no top or right titles.
  4. Series 0, the raw count: `isStepLineChart: true`, not curved, primary color at alpha 0.45,
     width 1.5, no dots.
  5. Series 1, only when `smooth` is non-empty: curved with `curveSmoothness: 0.3` and
     `preventCurveOverShooting: true`, full primary color, width 2, `dashArray: [6, 4]`, no dots,
     and a faint area below it (alpha 0.08).
  6. Tooltip: only series 0 produces an item, `'<count> · <formatMinutes(x)>'` on
     `inverseSurface`.
  7. Legend: a solid swatch labelled `intimacyThrustCount` and a dashed swatch labelled
     `intimacyThrustTimelineSmoothed`.
- **Usage:**
  ```dart
  // record_detail_page.dart, build, lines 195-198:
  ThrustTimelineChart(
    timeline: record.thrustTimeline!,
    duration: record.duration,
  ),
  ```
- **Notes:** Neither series visibly dips: the raw series is a step function of positive deltas,
  the smoothed values are non-decreasing by construction, and overshoot prevention stops the curve
  interpolation from bulging below a flat stretch between them. The tooltip deliberately reports
  the raw count only — the moving average is a visual aid, not a figure to read off.

## Related pages

- [`thrust_timeline.dart`](../utils/thrust_timeline.md) — the data model and both series.
- [`record_detail_page.dart`](../views/record_detail_page.md) — the only page that shows this
  chart.
- [`intimacy_trend_chart.dart`](intimacy_trend_chart.md) — the module's across-records trend
  chart, which uses the same solid-raw / dashed-smoothed convention with EWMA smoothing.
- [Intimacy — Thrust timeline chart](../../../../features/intimacy.md#thrust-timeline-chart).

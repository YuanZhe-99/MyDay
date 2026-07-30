# lib/features/intimacy/widgets/intimacy_trend_chart.dart

The Intimacy module's single record-metric trend chart, introduced in v1.3.2. It replaced four
separate `fl_chart` line charts — pleasure+frequency and duration+thrust-count on the intimacy home
page, plus near-verbatim copies of both inside the old `_FilteredRecordsTrendSection` on the
partner/toy detail pages — with one widget that both surfaces embed. Five metrics are selectable,
including the derived thrust rate; the selection and the time range are persisted and synced. See
[The consolidated trend chart](../../../../features/intimacy.md#the-consolidated-trend-chart-v132)
for the feature description and
[Data Formats](../../../../data-formats.md#intimacy--intimacy_datajson) for the persisted
`chartSettings` shape.

The widget is deliberately `StatelessWidget`: the selection lives in the caller so that one
persisted `IntimacyChartSettings` value can drive every place the chart appears. Writes are
reported through `onSettingsChanged` and land in
[`_saveChartSettings`](../views/intimacy_page.md#savechartsettings).

The toy daily-cost trend chart is **not** part of this widget and stays in
[`intimacy_page.dart`](../views/intimacy_page.md) — it plots money over a projected date timeline
on a log scale with its own all/active/retired scope selector. That page does, however, reuse the
public `IntimacyChartRange` enum declared here.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `IntimacyChartMetric.new` | constructor (`IntimacyChartMetric`) | B | Bind a metric enum value to its persisted string id. |
| [`IntimacyChartMetric.fromId`](#metricfromid) | static method (`IntimacyChartMetric`) | A | Resolve a persisted metric id, or null when unrecognized. |
| `IntimacyChartRange.new` | constructor (`IntimacyChartRange`) | B | Bind a range enum value to its persisted string id. |
| [`IntimacyChartRange.fromId`](#rangefromid) | static method (`IntimacyChartRange`) | A | Resolve a persisted range id, or null when unrecognized. |
| [`IntimacyChartRange.cutoffFrom`](#cutofffrom) | method (`IntimacyChartRange`) | A | Return the earliest datetime this range includes. |
| `_MetricSpec.new` | constructor (`_MetricSpec`) | B | Trivial forwarding constructor. |
| [`_MetricSpec.ceilingFor`](#ceilingfor) | method (`_MetricSpec`) | A | Snap an observed maximum up to a clean axis ceiling. |
| [`_metricSpecs`](#metricspecs) | top-level function | A | Build the per-metric specification table for the current theme. |
| [`buildRawSpots`](#buildrawspots) | top-level function | A | Build unsmoothed spots for a per-record metric. |
| [`buildEwmaSpots`](#buildewmaspots) | top-level function | A | Build an EWMA-smoothed curve for a per-record metric. |
| [`buildRawFrequencySpots`](#buildrawfrequencyspots) | top-level function | A | Build raw records-per-week spots using a 7-day rolling window. |
| [`buildEwmaFrequencySpots`](#buildewmafrequencyspots) | top-level function | A | Build an EWMA-smoothed records-per-week curve. |
| `_MetricSeries.new` | constructor (`_MetricSeries`) | B | Trivial forwarding constructor. |
| `_MetricSeries.hasData` | getter (`_MetricSeries`) | B | Whether the series has at least two points to draw. |
| `IntimacyTrendChart.new` | constructor | B | Trivial forwarding constructor. |
| `_range` | getter (`IntimacyTrendChart`) | B | The persisted range id resolved to an enum, falling back to the default. |
| [`_selectedMetrics`](#selectedmetrics) | getter (`IntimacyTrendChart`) | A | The persisted metric ids resolved to metrics, in canonical order. |
| [`_toggleMetric`](#togglemetric) | method (`IntimacyTrendChart`) | A | Toggle one metric and report the new selection. |
| [`_dateInterval`](#dateinterval) | method (`IntimacyTrendChart`) | A | Return the bottom-axis date-label interval for the plotted span. |
| [`IntimacyTrendChart.build`](#build) | method (widget) | A | Prepare every selected metric's series and lay out the card. |
| `_rangeChips` | method (widget helper) | B | Build the six compact time-range choice chips. |
| [`_buildMetricSelector`](#buildmetricselector) | method (widget helper) | A | Build the metric filter chips, which double as the legend. |
| [`_buildChart`](#buildchart) | method (widget helper) | A | Build the multi-metric `LineChart` itself. |
| `_axisTitles` | method (widget helper) | B | Build side titles that relabel the 0-1 plot space in real units. |
| [`_normalize`](#normalize) | static method (`IntimacyTrendChart`) | A | Scale a metric's real values into the shared 0-1 plot space. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/intimacy/widgets/intimacy_trend_chart.dart`
reports 25, matching all 25 rows above exactly (16 Tier A, 9 Tier B). Enum values themselves
(`pleasure`, `frequency`, …) are not declarations in this sense and carry no doc block; their
meanings are tabulated in
[The consolidated trend chart](../../../../features/intimacy.md#the-consolidated-trend-chart-v132).

## The rendering contract

The five metrics have incompatible units, so the chart does not use a real y-axis. The plot space
is a unitless `minY: 0, maxY: 1`, and every selected metric is normalized into it against its own
snapped ceiling from `_MetricSpec.ceilingFor`. Real values are restored for the axes and tooltips
by multiplying back by that ceiling.

- The **first** drawable metric in canonical order owns the labelled **left** axis; the **second**
  owns the **right** axis. Both are drawn in the series' own color.
- Further metrics are drawn with no axis at all and are read from the tooltip.
- Every metric draws **twice**: a thin solid line (alpha 0.45, width 1.5) for the raw per-record
  values, then a dashed `[6, 4]` line (width 2) for the EWMA curve. Only the primary metric's EWMA
  line gets a `belowBarData` fill.
- `lineBarsData` order is therefore `[raw₀, ewma₀, raw₁, ewma₁, …]`, which the tooltip callback
  relies on: it ignores even bar indices and maps odd index `i` to `drawable[i ~/ 2]`.
- The empty state (`intimacyChartNoData`) covers both "fewer than two records in range" and "no
  selected metric has two or more points in range".

Colors and ceiling step tables were carried over verbatim from the four charts this widget
replaced, so existing charts look unchanged; `thrustRate` is the only new entry.

## Documentation

### `static IntimacyChartMetric? fromId(String id)` <a id="metricfromid"></a>
- **Kind:** static method of `IntimacyChartMetric`
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 36)
- **Purpose:** Resolve a persisted identifier back to a metric.
- **Inputs:** `id`.
- **Returns:** `IntimacyChartMetric?` — null when the id is unrecognized.
- **Side effects:** None.
- **Notes:** Returning null rather than throwing is the forward-compatibility contract: an id
  written by a newer build is skipped for drawing but stays in the persisted list.

### `static IntimacyChartRange? fromId(String id)` <a id="rangefromid"></a>
- **Kind:** static method of `IntimacyChartRange`
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 68)
- **Purpose:** Resolve a persisted identifier back to a range.
- **Inputs:** `id`.
- **Returns:** `IntimacyChartRange?` — null when the id is unrecognized.
- **Side effects:** None.
- **Notes:** The `_range` getter pairs this with a fallback to `defaultRange`, so an unknown range
  renders as 3M without losing the stored string.

### `DateTime cutoffFrom(DateTime now)` <a id="cutofffrom"></a>
- **Kind:** method of `IntimacyChartRange`
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 80)
- **Purpose:** Return the earliest datetime included by this range.
- **Inputs:** `now`, the reference point (normally the current local time).
- **Returns:** `DateTime`.
- **Side effects:** None.
- **Algorithm:** `oneWeek` subtracts seven days; `oneMonth`/`threeMonths`/`sixMonths` and
  `oneYear` step the calendar month or year back and keep the day-of-month; `all` returns the
  `DateTime(2000)` sentinel.
- **Notes:** This is the single copy of a cutoff `switch` that existed in three places before
  v1.3.2. `_ToyCostOverviewPageState._historyStart` still keeps its own variant because its `all`
  case resolves to the earliest toy purchase date instead.

### `double ceilingFor(double maxObserved)` <a id="ceilingfor"></a>
- **Kind:** method of `_MetricSpec`
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 151)
- **Purpose:** Snap a maximum observed value up to a clean axis ceiling.
- **Inputs:** `maxObserved`.
- **Returns:** `double`.
- **Side effects:** None.
- **Algorithm:**
  1. Apply the metric's `headroom` multiplier and clamp up to its `minCeiling`.
  2. Return the first entry in `ceilSteps` that is at least that large.
  3. Past the last step, round up to the next `ceilFallbackStep` multiple.
- **Notes:** Generalizes the four hand-written `freqCeil`/`minCeil`/`thrustCeil`/`minuteCeil` local
  functions the old charts each defined inline, with the same step tables.

### `Map<IntimacyChartMetric, _MetricSpec> _metricSpecs(ThemeData theme)` <a id="metricspecs"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 166)
- **Purpose:** Return the metric specification table for the current theme.
- **Inputs:** `theme` — used for the pleasure series' themed color.
- **Returns:** `Map<IntimacyChartMetric, _MetricSpec>` with an entry for every enum value.
- **Side effects:** None.
- **Notes:** Takes `theme` rather than being a `const` table because pleasure alone uses
  `colorScheme.primary`; the other four use fixed high-contrast colors so they stay distinguishable
  in both light and dark themes. `frequency` is the only entry with a null `value` extractor — it
  is derived from the gaps between records, not from any single record, so the build method routes
  it to the dedicated frequency spot builders.

### `List<FlSpot> buildRawSpots(List<IntimacyRecord> visible, double? Function(IntimacyRecord) value)` <a id="buildrawspots"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 239)
- **Purpose:** Build raw (unsmoothed) spots for a per-record metric.
- **Inputs:** `visible` records already limited to the selected range, and the `value` extractor.
- **Returns:** `List<FlSpot>` with `x` in milliseconds since epoch.
- **Side effects:** None.
- **Notes:** Records the extractor rejects are skipped rather than plotted as zero, so a session
  with no thrust count does not drag the thrust-rate line down to the axis.

### `List<FlSpot> buildEwmaSpots(List<IntimacyRecord> allData, DateTime visibleFrom, double? Function(IntimacyRecord) value, {double halfLifeDays = 7})` <a id="buildewmaspots"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 259)
- **Purpose:** Build an EWMA-smoothed curve for a per-record metric.
- **Inputs:** `allData` sorted ascending, `visibleFrom`, the `value` extractor, `halfLifeDays`.
- **Returns:** `List<FlSpot>`.
- **Side effects:** None.
- **Algorithm:**
  1. Collect the records the extractor accepts, with their values.
  2. Seed the average with the first value and walk forward.
  3. For each step compute `alpha = 1 - exp(-dt / tau)` where `tau = halfLifeDays` in milliseconds,
     so the smoothing factor adapts to the real gap between records rather than assuming an even
     spacing.
  4. Emit a spot only once the record is at or after `visibleFrom`.
- **Notes:** Warming up over records outside the visible range is deliberate — it means changing
  the time range pans the window without changing the curve's shape. This single function replaced
  five near-identical per-metric copies (pleasure, duration, thrust count, and duplicates of the
  first two on the filtered page).

### `List<FlSpot> buildRawFrequencySpots(List<IntimacyRecord> allData, DateTime visibleFrom)` <a id="buildrawfrequencyspots"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 298)
- **Purpose:** Build raw frequency spots — records per week over a rolling window.
- **Inputs:** `allData` sorted ascending, `visibleFrom`.
- **Returns:** `List<FlSpot>`.
- **Side effects:** None.
- **Algorithm:** For each record, walk backwards counting records whose timestamp is within the
  preceding seven days, stopping at the first one that is not.
- **Notes:** Unchanged from the pre-v1.3.2 implementation.

### `List<FlSpot> buildEwmaFrequencySpots(List<IntimacyRecord> allData, DateTime visibleFrom, {double halfLifeDays = 14})` <a id="buildewmafrequencyspots"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 329)
- **Purpose:** Build an EWMA-smoothed frequency curve in records per week.
- **Inputs:** `allData` sorted ascending, `visibleFrom`, `halfLifeDays`.
- **Returns:** `List<FlSpot>`.
- **Side effects:** None.
- **Algorithm:** Each gap contributes an instantaneous rate of `7 days / gap`, smoothed with the
  same adaptive alpha as `buildEwmaSpots`. Starts from an estimate of one per week.
- **Notes:** Frequency uses a 14-day half-life rather than the 7-day default, because an
  instantaneous gap-derived rate is far noisier than a directly recorded value. Unchanged from the
  pre-v1.3.2 implementation.

### `List<IntimacyChartMetric> get _selectedMetrics` <a id="selectedmetrics"></a>
- **Kind:** getter of `IntimacyTrendChart`
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 427)
- **Purpose:** Resolve the persisted metric ids to metrics in canonical order.
- **Inputs:** None.
- **Returns:** `List<IntimacyChartMetric>`.
- **Side effects:** None.
- **Algorithm:** Filter `IntimacyChartMetric.values` by the persisted id set — which also imposes
  canonical order regardless of the stored list's order — and fall back to the default metrics if
  nothing recognizable remains.
- **Notes:** Unrecognized ids are skipped here but left untouched in `settings`, so they survive
  the round trip back to whichever build wrote them.

### `void _toggleMetric(IntimacyChartMetric metric)` <a id="togglemetric"></a>
- **Kind:** method of `IntimacyTrendChart`
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 447)
- **Purpose:** Toggle one metric and report the new selection.
- **Inputs:** `metric`.
- **Returns:** None.
- **Side effects:** Invokes `onSettingsChanged`.
- **Algorithm:** Copy the persisted id list, add or remove this metric's id, and report. If
  removing would leave no recognized metric, return without reporting at all.
- **Notes:** Refusing the last removal is what guarantees the chart never has to render an empty
  plot; the tap is silently a no-op rather than showing an error. Operating on a copy of the raw id
  list keeps unrecognized ids in place.

### `double _dateInterval(List<IntimacyRecord> visible)` <a id="dateinterval"></a>
- **Kind:** method of `IntimacyTrendChart`
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 463)
- **Purpose:** Return the bottom-axis label interval for the plotted span.
- **Inputs:** `visible`.
- **Returns:** `double` — an interval in milliseconds.
- **Side effects:** None.
- **Algorithm:** Day-count thresholds 7/30/90/180/365/730 map to 2/7/21/45/90/180-day intervals,
  falling through to yearly.
- **Notes:** Keeps roughly five to eight labels across any range. Single copy of what used to be
  duplicated between the main and filtered charts.

### `Widget build(BuildContext context)` <a id="build"></a>
- **Kind:** method of `IntimacyTrendChart`
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 483)
- **Purpose:** Build the current widget subtree for the active UI state.
- **Inputs:** `context`.
- **Returns:** The widget tree: title + range chips row, metric selector, and a 220px chart area.
- **Side effects:** Creates UI widgets from the current state.
- **Algorithm:**
  1. Sort a copy of `records` ascending and compute the range cutoff.
  2. For each selected metric, build its raw and EWMA series — routing `frequency` to the
     dedicated gap-based builders — and snap a ceiling from the maximum observed value.
  3. Keep only series with at least two points as `drawable`.
  4. Render the empty state when fewer than two records are in range or nothing is drawable;
     otherwise call `_buildChart`.
- **Notes:** Series are recomputed on every build, matching the pre-v1.3.2 behavior; the record
  counts involved are small enough that memoizing has not been necessary.

### `Widget _buildMetricSelector(...)` <a id="buildmetricselector"></a>
- **Kind:** method of `IntimacyTrendChart` (widget helper)
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 612)
- **Purpose:** Build the metric selector, which doubles as the chart legend.
- **Inputs:** `theme`, `l10n`, the `specs` table, and the `selected` metrics.
- **Returns:** `Widget` — a `Wrap` of `FilterChip`s, one per metric.
- **Side effects:** None.
- **Notes:** Each chip's avatar is the same 10x2 colored line swatch the old `_legendItem` drew, so
  selected chips read as a legend and deselected ones read as available metrics. This is why the
  consolidated chart needs no separate legend row despite showing more series than either chart it
  replaced. Chip density matches the range chips beside them.

### `Widget _buildChart(...)` <a id="buildchart"></a>
- **Kind:** method of `IntimacyTrendChart` (widget helper)
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 653)
- **Purpose:** Build the multi-metric line chart itself.
- **Inputs:** `theme`, `l10n`, the `drawable` series, and the `visible` records.
- **Returns:** `Widget` — the `LineChart`.
- **Side effects:** None.
- **Algorithm:** Emits a raw bar then an EWMA bar per series, assigns the left and right axes to
  the first two series, and builds tooltip rows for odd bar indices only, printing the date once.
- **Notes:** See [The rendering contract](#the-rendering-contract) above. The bar ordering is load
  bearing — the tooltip maps bar index back to metric arithmetically rather than by lookup.

### `static List<FlSpot> _normalize(List<FlSpot> spots, double ceiling)` <a id="normalize"></a>
- **Kind:** static method of `IntimacyTrendChart`
- **Source:** `lib/features/intimacy/widgets/intimacy_trend_chart.dart` (line 822)
- **Purpose:** Scale a metric's real values into the shared 0-1 plot space.
- **Inputs:** `spots`, `ceiling`.
- **Returns:** `List<FlSpot>`.
- **Side effects:** None.
- **Notes:** Clamps to `0..1` so a single outlier cannot escape the plot area, and returns empty
  for a non-positive ceiling rather than dividing by zero.

## Related pages

- [Intimacy](../../../../features/intimacy.md) — the feature this chart belongs to.
- [`intimacy_page.dart`](../views/intimacy_page.md) — both hosts of this widget, and the toy
  daily-cost chart that stayed behind.
- [`intimacy_record.dart`](../models/intimacy_record.md) — `IntimacyRecord.thrustsPerMinute` and
  the persisted `IntimacyChartSettings`.
- [Data Formats](../../../../data-formats.md#intimacy--intimacy_datajson) — the `chartSettings`
  JSON shape.
- [Sync](../../../../sync.md) — how the selection merges under settings last-write-wins.

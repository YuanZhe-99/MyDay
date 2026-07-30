import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../models/intimacy_record.dart';

/// A metric the consolidated intimacy trend chart can plot.
///
/// The declaration order is the canonical order: it decides chip order, and
/// which selected metrics get the labelled left and right axes.
enum IntimacyChartMetric {
  pleasure('pleasure'),
  frequency('frequency'),
  duration('duration'),
  thrustCount('thrustCount'),
  thrustRate('thrustRate');

  /// Stable identifier persisted in `intimacy_data.json`.
  final String id;

  /// Purpose: Create an intimacy chart metric enum value.
  /// Inputs: `id`, the persisted identifier.
  /// Returns: A new `IntimacyChartMetric` value.
  /// Side effects: None.
  /// Notes: Never persist the enum index — only `id` is a compatibility contract.
  const IntimacyChartMetric(this.id);

  /// Purpose: Resolve a persisted identifier back to a metric.
  /// Inputs: `id`.
  /// Returns: The matching `IntimacyChartMetric`, or null when unrecognized.
  /// Side effects: None.
  /// Notes: Unknown ids come from newer builds and are deliberately tolerated.
  static IntimacyChartMetric? fromId(String id) {
    for (final metric in IntimacyChartMetric.values) {
      if (metric.id == id) return metric;
    }
    return null;
  }
}

/// A selectable time window for the trend chart.
enum IntimacyChartRange {
  oneWeek('1w'),
  oneMonth('1m'),
  threeMonths('3m'),
  sixMonths('6m'),
  oneYear('1y'),
  all('all');

  /// Stable identifier persisted in `intimacy_data.json`.
  final String id;

  /// Purpose: Create an intimacy chart range enum value.
  /// Inputs: `id`, the persisted identifier.
  /// Returns: A new `IntimacyChartRange` value.
  /// Side effects: None.
  /// Notes: Never persist the enum index — only `id` is a compatibility contract.
  const IntimacyChartRange(this.id);

  /// Purpose: Resolve a persisted identifier back to a range.
  /// Inputs: `id`.
  /// Returns: The matching `IntimacyChartRange`, or null when unrecognized.
  /// Side effects: None.
  /// Notes: Unknown ids come from newer builds and are deliberately tolerated.
  static IntimacyChartRange? fromId(String id) {
    for (final range in IntimacyChartRange.values) {
      if (range.id == id) return range;
    }
    return null;
  }

  /// Purpose: Return the earliest datetime included by this range.
  /// Inputs: `now`, the reference point (normally the current local time).
  /// Returns: `DateTime`.
  /// Side effects: None.
  /// Notes: `all` returns a sentinel far enough back to include every record.
  DateTime cutoffFrom(DateTime now) => switch (this) {
    IntimacyChartRange.oneWeek => now.subtract(const Duration(days: 7)),
    IntimacyChartRange.oneMonth => DateTime(now.year, now.month - 1, now.day),
    IntimacyChartRange.threeMonths => DateTime(
      now.year,
      now.month - 3,
      now.day,
    ),
    IntimacyChartRange.sixMonths => DateTime(now.year, now.month - 6, now.day),
    IntimacyChartRange.oneYear => DateTime(now.year - 1, now.month, now.day),
    IntimacyChartRange.all => DateTime(2000),
  };
}

const Color _frequencyColor = Color(0xFF00796B);
const Color _durationColor = Color(0xFFF57C00);
const Color _thrustCountColor = Color(0xFF8E24AA);
const Color _thrustRateColor = Color(0xFF1565C0);

/// Everything the chart needs to know about one metric: how to read it off a
/// record, how to smooth it, how to scale it, and how to label it.
class _MetricSpec {
  final IntimacyChartMetric metric;
  final Color color;
  final String Function(AppLocalizations l10n) label;

  /// Extracts the metric's value from a record, or null when unavailable.
  /// Null for [IntimacyChartMetric.frequency], which is derived from the gaps
  /// between records rather than from any single record.
  final double? Function(IntimacyRecord record)? value;

  /// EWMA half-life in days.
  final double halfLifeDays;

  /// Clean ceilings the axis snaps up to, smallest first.
  final List<double> ceilSteps;

  /// Rounding granularity for values past the last step.
  final double ceilFallbackStep;

  /// Headroom applied before snapping, and the smallest allowed ceiling.
  final double headroom;
  final double minCeiling;

  /// Renders a real (un-normalized) value for axes, tooltips, and legends.
  final String Function(double value) format;

  /// Purpose: Create a metric specification.
  /// Inputs: All chart-facing properties of a single metric.
  /// Returns: A new `_MetricSpec` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _MetricSpec({
    required this.metric,
    required this.color,
    required this.label,
    required this.value,
    required this.halfLifeDays,
    required this.ceilSteps,
    required this.ceilFallbackStep,
    required this.headroom,
    required this.minCeiling,
    required this.format,
  });

  /// Purpose: Snap a maximum observed value up to a clean axis ceiling.
  /// Inputs: `maxObserved`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Applies this metric's headroom and floor before snapping so axis
  /// labels land on round numbers, matching the pre-consolidation charts.
  double ceilingFor(double maxObserved) {
    final target = math.max(maxObserved * headroom, minCeiling);
    for (final step in ceilSteps) {
      if (step >= target) return step;
    }
    return (target / ceilFallbackStep).ceil() * ceilFallbackStep;
  }
}

/// Purpose: Return the metric specification table for the current theme.
/// Inputs: `theme`, used for the pleasure series' themed color.
/// Returns: `Map<IntimacyChartMetric, _MetricSpec>`.
/// Side effects: None.
/// Notes: Colors and ceiling step tables are carried over verbatim from the
/// separate charts this widget replaced, so existing charts look unchanged.
Map<IntimacyChartMetric, _MetricSpec> _metricSpecs(ThemeData theme) {
  return {
    IntimacyChartMetric.pleasure: _MetricSpec(
      metric: IntimacyChartMetric.pleasure,
      color: theme.colorScheme.primary,
      label: (l10n) => l10n.intimacyPleasure,
      value: (record) =>
          record.pleasureLevel > 0 ? record.pleasureLevel.toDouble() : null,
      halfLifeDays: 7,
      ceilSteps: const [5.5],
      ceilFallbackStep: 5.5,
      headroom: 1.0,
      minCeiling: 5.5,
      format: (value) => value.toStringAsFixed(1),
    ),
    IntimacyChartMetric.frequency: _MetricSpec(
      metric: IntimacyChartMetric.frequency,
      color: _frequencyColor,
      label: (l10n) => l10n.intimacyFrequency,
      value: null,
      halfLifeDays: 14,
      ceilSteps: const [1, 2, 3, 5, 7, 10, 14, 20],
      ceilFallbackStep: 5,
      headroom: 1.1,
      minCeiling: 1,
      format: (value) => '${value.toStringAsFixed(1)}/wk',
    ),
    IntimacyChartMetric.duration: _MetricSpec(
      metric: IntimacyChartMetric.duration,
      color: _durationColor,
      label: (l10n) => l10n.intimacyDuration,
      value: (record) => record.duration.inSeconds > 0
          ? record.duration.inSeconds / 60.0
          : null,
      halfLifeDays: 7,
      ceilSteps: const [5, 10, 15, 20, 30, 45, 60, 90, 120],
      ceilFallbackStep: 30,
      headroom: 1.15,
      minCeiling: 5,
      format: (value) => '${value.toStringAsFixed(0)}m',
    ),
    IntimacyChartMetric.thrustCount: _MetricSpec(
      metric: IntimacyChartMetric.thrustCount,
      color: _thrustCountColor,
      label: (l10n) => l10n.intimacyThrustCount,
      value: (record) => record.resolvedThrustCount,
      halfLifeDays: 7,
      ceilSteps: const [100, 200, 300, 500, 800, 1000, 1500],
      ceilFallbackStep: 500,
      headroom: 1.1,
      minCeiling: 100,
      format: (value) => value.toStringAsFixed(0),
    ),
    IntimacyChartMetric.thrustRate: _MetricSpec(
      metric: IntimacyChartMetric.thrustRate,
      color: _thrustRateColor,
      label: (l10n) => l10n.intimacyThrustRate,
      value: (record) => record.thrustsPerMinute,
      halfLifeDays: 7,
      ceilSteps: const [10, 20, 30, 50, 80, 100, 150, 200],
      ceilFallbackStep: 50,
      headroom: 1.1,
      minCeiling: 10,
      format: (value) => '${value.toStringAsFixed(0)}/min',
    ),
  };
}

/// Purpose: Build raw (unsmoothed) spots for a per-record metric.
/// Inputs: `visible` records already limited to the selected range, and `value`.
/// Returns: `List<FlSpot>`.
/// Side effects: None.
/// Notes: Records the extractor rejects are skipped rather than plotted as zero.
List<FlSpot> buildRawSpots(
  List<IntimacyRecord> visible,
  double? Function(IntimacyRecord record) value,
) {
  final spots = <FlSpot>[];
  for (final record in visible) {
    final y = value(record);
    if (y == null) continue;
    spots.add(FlSpot(record.datetime.millisecondsSinceEpoch.toDouble(), y));
  }
  return spots;
}

/// Purpose: Build an EWMA-smoothed curve for a per-record metric.
/// Inputs: `allData` sorted ascending, `visibleFrom`, `value`, `halfLifeDays`.
/// Returns: `List<FlSpot>`.
/// Side effects: None.
/// Notes: Uses records before `visibleFrom` for warm-up but only emits spots at
/// or after it, so changing the range never changes the curve's shape. The
/// smoothing factor adapts to the real gap between records.
List<FlSpot> buildEwmaSpots(
  List<IntimacyRecord> allData,
  DateTime visibleFrom,
  double? Function(IntimacyRecord record) value, {
  double halfLifeDays = 7,
}) {
  final valid = <IntimacyRecord>[];
  final values = <double>[];
  for (final record in allData) {
    final y = value(record);
    if (y == null) continue;
    valid.add(record);
    values.add(y);
  }
  if (valid.isEmpty) return [];

  final tau = halfLifeDays * 86400 * 1000;
  final spots = <FlSpot>[];
  double ewma = values.first;
  DateTime prevTime = valid.first.datetime;

  for (int i = 0; i < valid.length; i++) {
    final record = valid[i];
    final dtMs = record.datetime.difference(prevTime).inMilliseconds.toDouble();
    final alpha = 1.0 - math.exp(-dtMs / tau);
    ewma = alpha * values[i] + (1 - alpha) * ewma;
    if (!record.datetime.isBefore(visibleFrom)) {
      spots.add(FlSpot(record.datetime.millisecondsSinceEpoch.toDouble(), ewma));
    }
    prevTime = record.datetime;
  }
  return spots;
}

/// Purpose: Build raw frequency spots — records per week over a rolling window.
/// Inputs: `allData` sorted ascending, `visibleFrom`.
/// Returns: `List<FlSpot>`.
/// Side effects: None.
/// Notes: For each record, counts the records within the preceding 7 days.
List<FlSpot> buildRawFrequencySpots(
  List<IntimacyRecord> allData,
  DateTime visibleFrom,
) {
  if (allData.isEmpty) return [];
  const windowMs = 7 * 86400 * 1000;
  final spots = <FlSpot>[];
  for (int i = 0; i < allData.length; i++) {
    final record = allData[i];
    final tMs = record.datetime.millisecondsSinceEpoch;
    int count = 0;
    for (int j = i; j >= 0; j--) {
      if (tMs - allData[j].datetime.millisecondsSinceEpoch <= windowMs) {
        count++;
      } else {
        break;
      }
    }
    if (!record.datetime.isBefore(visibleFrom)) {
      spots.add(FlSpot(tMs.toDouble(), count.toDouble()));
    }
  }
  return spots;
}

/// Purpose: Build an EWMA-smoothed frequency curve in records per week.
/// Inputs: `allData` sorted ascending, `visibleFrom`, `halfLifeDays`.
/// Returns: `List<FlSpot>`.
/// Side effects: None.
/// Notes: Frequency has no per-record value, so each gap contributes an
/// instantaneous rate of `7 days / gap`. Starts from an estimate of 1 per week.
List<FlSpot> buildEwmaFrequencySpots(
  List<IntimacyRecord> allData,
  DateTime visibleFrom, {
  double halfLifeDays = 14,
}) {
  if (allData.isEmpty) return [];
  final tau = halfLifeDays * 86400 * 1000;
  final spots = <FlSpot>[];
  double ewma = 1.0;
  DateTime prevTime = allData.first.datetime;

  for (final record in allData) {
    final dtMs = record.datetime.difference(prevTime).inMilliseconds.toDouble();
    if (dtMs > 0) {
      final rate = 7.0 * 86400 * 1000 / dtMs;
      final alpha = 1.0 - math.exp(-dtMs / tau);
      ewma = alpha * rate + (1 - alpha) * ewma;
    }
    if (!record.datetime.isBefore(visibleFrom)) {
      spots.add(FlSpot(record.datetime.millisecondsSinceEpoch.toDouble(), ewma));
    }
    prevTime = record.datetime;
  }
  return spots;
}

/// One metric's prepared, un-normalized series plus the ceiling it scales by.
class _MetricSeries {
  final _MetricSpec spec;
  final List<FlSpot> raw;
  final List<FlSpot> ewma;
  final double ceiling;

  /// Purpose: Create a prepared metric series.
  /// Inputs: `spec`, `raw`, `ewma`, `ceiling`.
  /// Returns: A new `_MetricSeries` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _MetricSeries({
    required this.spec,
    required this.raw,
    required this.ewma,
    required this.ceiling,
  });

  /// Purpose: Report whether this series has enough points to be worth drawing.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: A single point cannot form a line, matching the previous charts.
  bool get hasData => raw.length >= 2 || ewma.length >= 2;
}

/// The single consolidated trend chart for the Intimacy module.
///
/// Replaces the four separate per-metric charts that previously lived on the
/// intimacy home page and the partner/toy detail pages. All five metrics share
/// one plot area: each is normalized into a unitless 0–1 space against its own
/// snapped ceiling, and real values are restored for the axes and tooltips.
class IntimacyTrendChart extends StatelessWidget {
  /// Records to plot. Warm-up uses all of them; the range only limits display.
  final List<IntimacyRecord> records;

  /// The current, persisted metric and range selection.
  final IntimacyChartSettings settings;

  /// Reports a new selection so the host can persist and sync it.
  final ValueChanged<IntimacyChartSettings> onSettingsChanged;

  /// Purpose: Create the consolidated intimacy trend chart.
  /// Inputs: `records`, `settings`, `onSettingsChanged`.
  /// Returns: A new `IntimacyTrendChart` instance.
  /// Side effects: None.
  /// Notes: Stateless by design — the selection lives with the caller so one
  /// persisted value can drive every place the chart appears.
  const IntimacyTrendChart({
    super.key,
    required this.records,
    required this.settings,
    required this.onSettingsChanged,
  });

  /// Purpose: Resolve the persisted range id to a range, falling back safely.
  /// Inputs: None.
  /// Returns: `IntimacyChartRange`.
  /// Side effects: None.
  /// Notes: An unrecognized id (written by a newer build) renders as the default.
  IntimacyChartRange get _range =>
      IntimacyChartRange.fromId(settings.range) ??
      IntimacyChartRange.fromId(IntimacyChartSettings.defaultRange)!;

  /// Purpose: Resolve the persisted metric ids to metrics in canonical order.
  /// Inputs: None.
  /// Returns: `List<IntimacyChartMetric>`.
  /// Side effects: None.
  /// Notes: Unrecognized ids are skipped for drawing but stay in `settings`, so
  /// they survive the round trip. If nothing recognizable remains, the defaults
  /// are drawn rather than an empty chart.
  List<IntimacyChartMetric> get _selectedMetrics {
    final ids = settings.metrics.toSet();
    final selected = IntimacyChartMetric.values
        .where((metric) => ids.contains(metric.id))
        .toList();
    if (selected.isNotEmpty) return selected;
    return IntimacyChartMetric.values
        .where(
          (metric) => IntimacyChartSettings.defaultMetrics.contains(metric.id),
        )
        .toList();
  }

  /// Purpose: Toggle one metric and report the new selection.
  /// Inputs: `metric`.
  /// Returns: None.
  /// Side effects: Invokes `onSettingsChanged`.
  /// Notes: Deselecting the last visible metric is refused, so the chart is
  /// never asked to render with nothing selected. Unrecognized ids in the
  /// persisted list are carried through untouched.
  void _toggleMetric(IntimacyChartMetric metric) {
    final ids = List<String>.of(settings.metrics);
    if (ids.contains(metric.id)) {
      if (_selectedMetrics.length <= 1) return;
      ids.remove(metric.id);
    } else {
      ids.add(metric.id);
    }
    onSettingsChanged(settings.copyWith(metrics: ids));
  }

  /// Purpose: Return the bottom-axis label interval for the plotted span.
  /// Inputs: `visible`.
  /// Returns: `double` — an interval in milliseconds.
  /// Side effects: None.
  /// Notes: Keeps roughly five to eight labels across any range.
  double _dateInterval(List<IntimacyRecord> visible) {
    if (visible.length < 2) return 1;
    final spanDays =
        visible.last.datetime.difference(visible.first.datetime).inDays;
    const day = 86400 * 1000.0;
    if (spanDays <= 7) return 2 * day;
    if (spanDays <= 30) return 7 * day;
    if (spanDays <= 90) return 21 * day;
    if (spanDays <= 180) return 45 * day;
    if (spanDays <= 365) return 90 * day;
    if (spanDays <= 730) return 180 * day;
    return 365 * day;
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Selected metric chips double as the chart's legend.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final specs = _metricSpecs(theme);
    final selected = _selectedMetrics;

    final allSorted = List<IntimacyRecord>.of(records)
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
    final cutoff = _range.cutoffFrom(DateTime.now());
    final visible = allSorted
        .where((record) => record.datetime.isAfter(cutoff))
        .toList();
    final visibleFrom = visible.isNotEmpty
        ? visible.first.datetime
        : DateTime.now();

    final series = <_MetricSeries>[];
    for (final metric in selected) {
      final spec = specs[metric]!;
      final List<FlSpot> raw;
      final List<FlSpot> ewma;
      if (metric == IntimacyChartMetric.frequency) {
        raw = buildRawFrequencySpots(allSorted, visibleFrom);
        ewma = buildEwmaFrequencySpots(
          allSorted,
          visibleFrom,
          halfLifeDays: spec.halfLifeDays,
        );
      } else {
        raw = buildRawSpots(visible, spec.value!);
        ewma = buildEwmaSpots(
          allSorted,
          visibleFrom,
          spec.value!,
          halfLifeDays: spec.halfLifeDays,
        );
      }
      final observed = [...raw, ...ewma];
      final maxObserved = observed.isEmpty
          ? 0.0
          : observed.map((spot) => spot.y).reduce(math.max);
      series.add(
        _MetricSeries(
          spec: spec,
          raw: raw,
          ewma: ewma,
          ceiling: spec.ceilingFor(maxObserved),
        ),
      );
    }
    final drawable = series.where((entry) => entry.hasData).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.intimacyTrend,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ..._rangeChips(l10n),
            ],
          ),
          const SizedBox(height: 8),
          _buildMetricSelector(theme, l10n, specs, selected),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: visible.length < 2 || drawable.isEmpty
                ? Center(
                    child: Text(
                      l10n.intimacyChartNoData,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : _buildChart(theme, l10n, drawable, visible),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  /// Purpose: Build the compact time-range selector chips.
  /// Inputs: `l10n`.
  /// Returns: `List<Widget>`.
  /// Side effects: None.
  /// Notes: Range labels stay unlocalized abbreviations except `All`, matching
  /// the weight module's chips.
  List<Widget> _rangeChips(AppLocalizations l10n) {
    const labels = {
      IntimacyChartRange.oneWeek: '1W',
      IntimacyChartRange.oneMonth: '1M',
      IntimacyChartRange.threeMonths: '3M',
      IntimacyChartRange.sixMonths: '6M',
      IntimacyChartRange.oneYear: '1Y',
    };
    final current = _range;
    return IntimacyChartRange.values.map((range) {
      final label = labels[range] ?? l10n.weightAll;
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          selected: current == range,
          onSelected: (_) =>
              onSettingsChanged(settings.copyWith(range: range.id)),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      );
    }).toList();
  }

  /// Purpose: Build the metric selector, which doubles as the chart legend.
  /// Inputs: `theme`, `l10n`, `specs`, `selected`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Selected chips carry the series' color swatch, so the selector
  /// replaces the static legend rows the separate charts used to need.
  Widget _buildMetricSelector(
    ThemeData theme,
    AppLocalizations l10n,
    Map<IntimacyChartMetric, _MetricSpec> specs,
    List<IntimacyChartMetric> selected,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: IntimacyChartMetric.values.map((metric) {
        final spec = specs[metric]!;
        final isSelected = selected.contains(metric);
        return FilterChip(
          avatar: Container(
            width: 10,
            height: 2,
            color: isSelected
                ? spec.color
                : spec.color.withValues(alpha: 0.35),
          ),
          label: Text(
            spec.label(l10n),
            style: const TextStyle(fontSize: 11),
          ),
          selected: isSelected,
          onSelected: (_) => _toggleMetric(metric),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        );
      }).toList(),
    );
  }

  /// Purpose: Build the multi-metric line chart itself.
  /// Inputs: `theme`, `l10n`, `drawable` series, and the `visible` records.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: The plot space is a unitless 0–1; every series divides by its own
  /// ceiling to get there. The first two drawable series own the left and right
  /// axes; any further series are drawn without an axis and read from tooltips.
  Widget _buildChart(
    ThemeData theme,
    AppLocalizations l10n,
    List<_MetricSeries> drawable,
    List<IntimacyRecord> visible,
  ) {
    final localeName = l10n.localeName;
    final primary = drawable.first;
    final secondary = drawable.length > 1 ? drawable[1] : null;
    final spanDays =
        visible.last.datetime.difference(visible.first.datetime).inDays;
    final dateFormat = spanDays > 730
        ? DateFormat('yyyy', localeName)
        : spanDays > 365
        ? DateFormat('M/yy', localeName)
        : DateFormat('M/d', localeName);

    // Series order must match the tooltip's bar-index lookup below: for each
    // metric the raw line is emitted first, then its EWMA line.
    final bars = <LineChartBarData>[];
    for (final entry in drawable) {
      bars.add(
        LineChartBarData(
          spots: _normalize(entry.raw, entry.ceiling),
          isCurved: false,
          color: entry.spec.color.withValues(alpha: 0.45),
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
        ),
      );
      bars.add(
        LineChartBarData(
          spots: _normalize(entry.ewma, entry.ceiling),
          isCurved: true,
          curveSmoothness: 0.3,
          color: entry.spec.color,
          barWidth: 2,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
          belowBarData: entry == primary
              ? BarAreaData(
                  show: true,
                  color: entry.spec.color.withValues(alpha: 0.08),
                )
              : null,
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            strokeWidth: 0.5,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _dateInterval(visible),
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  dateFormat.format(
                    DateTime.fromMillisecondsSinceEpoch(value.toInt()),
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: _axisTitles(theme, primary, 36),
          ),
          rightTitles: AxisTitles(
            sideTitles: secondary == null
                ? const SideTitles(showTitles: false)
                : _axisTitles(theme, secondary, 40),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        minY: 0,
        maxY: 1,
        lineBarsData: bars,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => theme.colorScheme.inverseSurface,
            getTooltipItems: (touchedSpots) {
              bool datePrinted = false;
              return touchedSpots.map((spot) {
                // Only the EWMA line of each metric is worth a tooltip row.
                if (spot.barIndex.isEven) return null;
                final entry = drawable[spot.barIndex ~/ 2];
                final actual = spot.y * entry.ceiling;
                final text =
                    '${entry.spec.label(l10n)}: ${entry.spec.format(actual)}';
                final dateSuffix = datePrinted
                    ? ''
                    : '\n${DateFormat('MMM d', localeName).format(DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()))}';
                datePrinted = true;
                return LineTooltipItem(
                  '$text$dateSuffix',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Purpose: Build side titles that relabel the 0–1 plot space in real units.
  /// Inputs: `theme`, `entry`, `reservedSize`.
  /// Returns: `SideTitles`.
  /// Side effects: None.
  /// Notes: Labels are drawn in the series' own color so it is obvious which
  /// axis belongs to which metric.
  SideTitles _axisTitles(
    ThemeData theme,
    _MetricSeries entry,
    double reservedSize,
  ) {
    return SideTitles(
      showTitles: true,
      reservedSize: reservedSize,
      interval: 0.25,
      getTitlesWidget: (value, meta) => SideTitleWidget(
        meta: meta,
        child: Text(
          entry.spec.format(value * entry.ceiling),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: entry.spec.color,
          ),
        ),
      ),
    );
  }

  /// Purpose: Scale a metric's real values into the shared 0–1 plot space.
  /// Inputs: `spots`, `ceiling`.
  /// Returns: `List<FlSpot>`.
  /// Side effects: None.
  /// Notes: Values are clamped so an outlier cannot escape the plot area.
  static List<FlSpot> _normalize(List<FlSpot> spots, double ceiling) {
    if (ceiling <= 0) return const [];
    return spots
        .map((spot) => FlSpot(spot.x, (spot.y / ceiling).clamp(0.0, 1.0)))
        .toList();
  }
}

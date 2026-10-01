import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../utils/thrust_timeline.dart';

/// The cumulative thrust count of one timed session, with a smoothed fit line.
class ThrustTimelineChart extends StatelessWidget {
  final ThrustTimeline timeline;
  final Duration duration;
  final double height;

  /// Purpose: Create a thrust timeline chart.
  /// Inputs: `timeline` — the record's presses; `duration` — the record's
  /// duration, which sets the x-axis end; `height` — chart height.
  /// Returns: A new `ThrustTimelineChart` instance.
  /// Side effects: None.
  /// Notes: Renders nothing with fewer than two presses.
  const ThrustTimelineChart({
    super.key,
    required this.timeline,
    required this.duration,
    this.height = 220,
  });

  /// Purpose: Pick a round axis step that yields about `targetTicks` ticks.
  /// Inputs: `range` — the axis span; `targetTicks` — desired tick count.
  /// Returns: `double` — 1, 2 or 5 times a power of ten, at least `minStep`.
  /// Side effects: None.
  /// Notes: Public for tests.
  static double niceStep(double range, int targetTicks, {double minStep = 1}) {
    if (range <= 0 || targetTicks <= 0) return minStep;
    final raw = range / targetTicks;
    final magnitude = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final normalized = raw / magnitude;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    return math.max(nice * magnitude, minStep);
  }

  /// Purpose: Format a minute value as an x-axis label.
  /// Inputs: `minutes`.
  /// Returns: `String` — `m` below an hour, `h:mm` from an hour on.
  /// Side effects: None.
  /// Notes: Public for tests.
  static String formatMinutes(double minutes) {
    final total = minutes.round();
    if (total < 60) return '$total';
    final h = total ~/ 60;
    final m = (total % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Purpose: Build the chart and its legend.
  /// Inputs: `context`.
  /// Returns: The chart widget, or an empty box with fewer than two presses.
  /// Side effects: None.
  /// Notes: The raw series is a step line; the smoothed series is dashed and
  /// curved with overshoot prevention, so neither visibly dips.
  @override
  Widget build(BuildContext context) {
    if (timeline.events.length < 2) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = theme.colorScheme.primary;
    final durationMs = duration.inMilliseconds;
    final raw = timeline.cumulativeSpots(durationMs: durationMs);
    final smooth = timeline.smoothedSpots(durationMs: durationMs);
    final maxX = math.max(raw.last.x, smooth.isEmpty ? 0.0 : smooth.last.x);
    final total = timeline.total.toDouble();
    final yStep = niceStep(total, 4);
    // A little headroom so the final plateau does not sit on the border.
    final maxY = (total * 1.05 / yStep).ceil() * yStep;
    final xStep = niceStep(maxX, 5);
    final gridColor = theme.colorScheme.outlineVariant;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(fontSize: 9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX <= 0 ? 1 : maxX,
              minY: 0,
              maxY: maxY <= 0 ? 1 : maxY,
              gridData: FlGridData(
                show: true,
                horizontalInterval: yStep,
                verticalInterval: xStep,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: gridColor.withValues(alpha: 0.3),
                  strokeWidth: 0.5,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: gridColor.withValues(alpha: 0.2),
                  strokeWidth: 0.5,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(
                    l10n.intimacyThrustTimelineMinutes,
                    style: labelStyle,
                  ),
                  axisNameSize: 14,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: xStep,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(formatMinutes(value), style: labelStyle),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: yStep,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(value.toInt().toString(), style: labelStyle),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: gridColor.withValues(alpha: 0.3)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: raw,
                  isStepLineChart: true,
                  isCurved: false,
                  color: color.withValues(alpha: 0.45),
                  barWidth: 1.5,
                  dotData: const FlDotData(show: false),
                ),
                if (smooth.isNotEmpty)
                  LineChartBarData(
                    spots: smooth,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    preventCurveOverShooting: true,
                    color: color,
                    barWidth: 2,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.08),
                    ),
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  getTooltipItems: (touched) => touched.map((spot) {
                    if (spot.barIndex != 0) return null;
                    return LineTooltipItem(
                      '${spot.y.toInt()} · ${formatMinutes(spot.x)}',
                      TextStyle(
                        color: theme.colorScheme.onInverseSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            _LegendItem(
              color: color.withValues(alpha: 0.45),
              dashed: false,
              label: l10n.intimacyThrustCount,
            ),
            _LegendItem(
              color: color,
              dashed: true,
              label: l10n.intimacyThrustTimelineSmoothed,
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final bool dashed;
  final String label;

  /// Purpose: Create one legend entry.
  /// Inputs: `color`, `dashed` — line style; `label`.
  /// Returns: A new `_LegendItem` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _LegendItem({
    required this.color,
    required this.dashed,
    required this.label,
  });

  /// Purpose: Build a short line swatch followed by its label.
  /// Inputs: `context`.
  /// Returns: The legend row.
  /// Side effects: None.
  /// Notes: A dashed swatch is two short segments.
  @override
  Widget build(BuildContext context) {
    final segment = Container(width: 8, height: 2, color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed) ...[
          segment,
          const SizedBox(width: 4),
          segment,
        ] else
          Container(width: 20, height: 2, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

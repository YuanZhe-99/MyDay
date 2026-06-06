import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/services/auto_sync_service.dart';
import '../../../shared/services/reminder_service.dart';
import '../../../shared/utils/week_grouping.dart';
import '../../../shared/widgets/app_date_picker.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../../../shared/widgets/unsaved_changes_guard.dart';
import '../models/weight_record.dart';
import '../services/weight_storage.dart';

const Color _weightChartColor = Color(0xFF1565C0);
const Color _weightTrendChartColor = Color(0xFF2E7D32);
const Color _bustChartColor = Color(0xFFD81B60);
const Color _waistChartColor = Color(0xFFF57C00);
const Color _hipChartColor = Color(0xFF6A1B9A);

/// Purpose: Create a decimal text input formatter with a fixed precision limit.
/// Inputs: `decimalPlaces`.
/// Returns: `TextInputFormatter`.
/// Side effects: None.
/// Notes: Allows temporary empty and decimal-point text while editing.
TextInputFormatter _decimalInputFormatter(int decimalPlaces) {
  return TextInputFormatter.withFunction((oldValue, newValue) {
    if (newValue.text.isEmpty) return newValue;
    final pattern = RegExp('^\\d*\\.?\\d{0,$decimalPlaces}\$');
    return pattern.hasMatch(newValue.text) ? newValue : oldValue;
  });
}

class WeightPage extends ConsumerStatefulWidget {
  /// Purpose: Create a weight page instance.
  /// Inputs: None.
  /// Returns: A new `WeightPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const WeightPage({super.key});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  ConsumerState<WeightPage> createState() => _WeightPageState();
}

enum _ChartRange { oneWeek, oneMonth, threeMonths, sixMonths, oneYear, all }

class _WeightPageState extends ConsumerState<WeightPage> {
  double? _height; // cm
  List<WeightRecord> _records = [];
  bool _loaded = false;
  _ChartRange _chartRange = _ChartRange.oneMonth;

  // Reminder settings
  String _reminderMode = 'none'; // 'none' | 'once' | 'twice'
  TimeOfDay? _weightMorningReminder;
  TimeOfDay? _weightEveningReminder;
  int _reminderGraceMinutes = 180;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    _loadData();
    AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  }

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Releases owned resources and unregisters listeners.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    AutoSyncService.instance.removeOnLocalDataChanged(_loadData);
    super.dispose();
  }

  /// Purpose: Provide the internal load data helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadData() async {
    final data = await WeightStorage.load();
    setState(() {
      if (data != null) {
        _height = data.height;
        _records = data.records;
        _reminderMode = data.reminderMode;
        _weightMorningReminder =
            data.morningHour != null && data.morningMinute != null
            ? TimeOfDay(hour: data.morningHour!, minute: data.morningMinute!)
            : null;
        _weightEveningReminder =
            data.eveningHour != null && data.eveningMinute != null
            ? TimeOfDay(hour: data.eveningHour!, minute: data.eveningMinute!)
            : null;
        _reminderGraceMinutes = data.reminderGraceMinutes;
      }
      _loaded = true;
    });
    ReminderService.instance.updateWeightData(
      records: _records,
      morningHour: _weightMorningReminder?.hour,
      morningMinute: _weightMorningReminder?.minute,
      eveningHour: _weightEveningReminder?.hour,
      eveningMinute: _weightEveningReminder?.minute,
      reminderGraceMinutes: _reminderGraceMinutes,
    );
  }

  /// Purpose: Provide the internal save data helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _saveData() async {
    await WeightStorage.save(
      WeightData(
        height: _height,
        records: _records,
        reminderMode: _reminderMode,
        morningHour: _weightMorningReminder?.hour,
        morningMinute: _weightMorningReminder?.minute,
        eveningHour: _weightEveningReminder?.hour,
        eveningMinute: _weightEveningReminder?.minute,
        reminderGraceMinutes: _reminderGraceMinutes,
        settingsModifiedAt: DateTime.now().toUtc(),
      ),
    );
    ReminderService.instance.updateWeightData(
      records: _records,
      morningHour: _weightMorningReminder?.hour,
      morningMinute: _weightMorningReminder?.minute,
      eveningHour: _weightEveningReminder?.hour,
      eveningMinute: _weightEveningReminder?.minute,
      reminderGraceMinutes: _reminderGraceMinutes,
    );
    AutoSyncService.instance.notifySaved();
  }

  /// Purpose: Return latest record.
  /// Inputs: None.
  /// Returns: `WeightRecord?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  WeightRecord? get _latestRecord {
    if (_records.isEmpty) return null;
    final sorted = List<WeightRecord>.from(_records)
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    return sorted.first;
  }

  /// Purpose: Return current bmi.
  /// Inputs: None.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  double? get _currentBMI {
    final latest = _latestRecord;
    if (latest == null) return null;
    return WeightData.calculateBMI(_height, latest.weight);
  }

  /// Weight change over the selected chart range.
  /// Purpose: Return weight change.
  /// Inputs: None.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  double? get _weightChange {
    final data = _chartRecords;
    if (data.length < 2) return null;
    return data.last.weight - data.first.weight;
  }

  /// Purpose: Return tracking days.
  /// Inputs: None.
  /// Returns: `int?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  int? get _trackingDays {
    final data = _chartRecords;
    if (data.length < 2) return null;
    return data.last.datetime.difference(data.first.datetime).inDays;
  }

  /// Recent weight range.
  /// Purpose: Return recent range.
  /// Inputs: None.
  /// Returns: `(double, double)?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  (double, double)? get _recentRange {
    if (_records.isEmpty) return null;
    final sorted = List<WeightRecord>.from(_records)
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    final recent = sorted.take(7).toList();
    final min = recent.map((r) => r.weight).reduce(math.min);
    final max = recent.map((r) => r.weight).reduce(math.max);
    return (min, max);
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weightTitle),
        actions: [
          IconButton(
            icon: Icon(
              _reminderMode != 'none'
                  ? Icons.notifications_active
                  : Icons.notifications_none,
            ),
            tooltip: l10n.weightReminder,
            onPressed: _showReminderSettings,
          ),
          IconButton(
            icon: const Icon(Icons.height),
            tooltip: l10n.weightSetHeight,
            onPressed: _setHeight,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? _buildEmptyState(theme, l10n)
          : _buildContent(theme, l10n, settings.weekStartDay),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Purpose: Provide the internal build empty state helper for this file.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.weightNoRecords,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (_height == null)
            TextButton(
              onPressed: _setHeight,
              child: Text(l10n.weightSetHeight),
            ),
        ],
      ),
    );
  }

  /// Purpose: Provide the internal build content helper for this file.
  /// Inputs: `theme`, `l10n`, and `weekStartDay`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildContent(
    ThemeData theme,
    AppLocalizations l10n,
    int weekStartDay,
  ) {
    final latest = _latestRecord!;
    final bmi = _currentBMI;
    final change = _weightChange;
    final days = _trackingDays;
    final range = _recentRange;
    final timeSince = _timeSinceLastRecord(latest.datetime, l10n);

    return ListView(
      children: [
        // ── Summary card (like the reference UI) ──
        _buildSummaryCard(
          theme,
          l10n,
          latest,
          bmi,
          change,
          days,
          range,
          timeSince,
        ),
        const SizedBox(height: 16),

        // ── Chart section ──
        _buildChartSection(theme, l10n),
        const SizedBox(height: 16),

        // ── Today / Recent records ──
        _buildRecordsList(theme, l10n, weekStartDay),
      ],
    );
  }

  /// Purpose: Provide the internal build summary card helper for this file.
  /// Inputs: Key parameters such as `theme`, `l10n`, `latest`, `bmi`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildSummaryCard(
    ThemeData theme,
    AppLocalizations l10n,
    WeightRecord latest,
    double? bmi,
    double? change,
    int? days,
    (double, double)? range,
    String timeSince,
  ) {
    final effectiveMeasurements = WeightData.effectiveMeasurementsUpTo(
      _records,
      latest.datetime,
    );
    final measurements = _latestMeasurementStats(effectiveMeasurements, l10n);
    final waistHipRatio = WeightData.calculateWaistHipRatio(
      effectiveMeasurements.waistCm,
      effectiveMeasurements.hipCm,
    );
    final stats = [
      if (range != null)
        _buildStatLabel(
          theme,
          l10n.weightRecent,
          '${range.$1.toStringAsFixed(0)}–${range.$2.toStringAsFixed(0)}',
        ),
      if (bmi != null)
        _buildStatLabel(
          theme,
          'BMI',
          bmi.toStringAsFixed(1),
          trailing: _buildBMIBar(theme, bmi),
        ),
      for (final measurement in measurements)
        _buildStatLabel(theme, measurement.$1, measurement.$2),
      if (waistHipRatio != null)
        _buildStatLabel(
          theme,
          l10n.weightWaistHipRatio,
          waistHipRatio.toStringAsFixed(2),
          trailing: _buildWaistHipRatioBar(theme, waistHipRatio),
        ),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time since & change row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeSince,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            latest.weight.toStringAsFixed(1),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.weightUnitKg,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (change != null && days != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$days ${l10n.weightDays}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            change < 0
                                ? Icons.arrow_downward
                                : change > 0
                                ? Icons.arrow_upward
                                : Icons.remove,
                            color: change < 0
                                ? Colors.blue
                                : change > 0
                                ? Colors.red
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${change.abs().toStringAsFixed(1)} ${l10n.weightUnitKg}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: change < 0
                                  ? Colors.blue
                                  : change > 0
                                  ? Colors.red
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            Wrap(spacing: 20, runSpacing: 12, children: stats),
          ],
        ),
      ),
    );
  }

  /// Purpose: Return effective body measurement labels and values.
  /// Inputs: `measurements`, `l10n`.
  /// Returns: `List<(String, String)>`.
  /// Side effects: None.
  /// Notes: Omits fields that do not have a current inherited value.
  List<(String, String)> _latestMeasurementStats(
    EffectiveWeightMeasurements measurements,
    AppLocalizations l10n,
  ) {
    return [
      if (measurements.bustCm != null)
        (l10n.weightBust, '${measurements.bustCm!.toStringAsFixed(1)} cm'),
      if (measurements.waistCm != null)
        (l10n.weightWaist, '${measurements.waistCm!.toStringAsFixed(1)} cm'),
      if (measurements.hipCm != null)
        (l10n.weightHip, '${measurements.hipCm!.toStringAsFixed(1)} cm'),
    ];
  }

  /// Purpose: Provide the internal build stat label helper for this file.
  /// Inputs: `theme`, `label`, `value`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildStatLabel(
    ThemeData theme,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88, maxWidth: 168),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing],
            ],
          ),
        ],
      ),
    );
  }

  /// Purpose: Provide the internal build bmi bar helper for this file.
  /// Inputs: `theme`, `bmi`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildBMIBar(ThemeData theme, double bmi) {
    // BMI categories: <18.5 underweight, 18.5-25 normal, 25-30 overweight, 30+ obese
    final position = ((bmi - 15) / 25).clamp(0.0, 1.0).toDouble();
    return _buildSegmentedScaleBar(theme, const [
      (Colors.blue, 7),
      (Colors.green, 6),
      (Colors.orange, 5),
      (Colors.red, 7),
    ], position);
  }

  /// Purpose: Build a compact waist-hip ratio category bar.
  /// Inputs: `theme`, `ratio`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Uses universal visual thresholds around 0.80, 0.90, and 1.00.
  Widget _buildWaistHipRatioBar(ThemeData theme, double ratio) {
    final position = ((ratio - 0.65) / 0.45).clamp(0.0, 1.0).toDouble();
    return _buildSegmentedScaleBar(theme, const [
      (Colors.green, 15),
      (Colors.orange, 10),
      (Colors.deepOrange, 10),
      (Colors.red, 10),
    ], position);
  }

  /// Purpose: Build a shared segmented scale bar with a marker.
  /// Inputs: `theme`, `segments`, `position`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: `position` is clamped to the visible bar width.
  Widget _buildSegmentedScaleBar(
    ThemeData theme,
    List<(Color, int)> segments,
    double position,
  ) {
    const width = 60.0;
    final markerLeft = (width * position.clamp(0.0, 1.0)) - 2;
    return SizedBox(
      width: width,
      height: 8,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < segments.length; i++)
                Expanded(
                  flex: segments[i].$2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: segments[i].$1.withValues(alpha: 0.6),
                      borderRadius: i == 0
                          ? const BorderRadius.horizontal(
                              left: Radius.circular(4),
                            )
                          : i == segments.length - 1
                          ? const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          Positioned(
            left: markerLeft,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chart ──

  /// Purpose: Provide the internal build chart section helper for this file.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Renders separate weight and measurement charts that share the range picker.
  Widget _buildChartSection(ThemeData theme, AppLocalizations l10n) {
    final labels = {
      _ChartRange.oneWeek: '1W',
      _ChartRange.oneMonth: '1M',
      _ChartRange.threeMonths: '3M',
      _ChartRange.sixMonths: '6M',
      _ChartRange.oneYear: '1Y',
      _ChartRange.all: l10n.weightAll,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weightChart,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: labels.entries.map((e) {
              return ChoiceChip(
                label: Text(e.value, style: const TextStyle(fontSize: 11)),
                selected: _chartRange == e.key,
                onSelected: (_) => setState(() => _chartRange = e.key),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildChartLegendItem(
                _weightChartColor,
                theme.textTheme.labelSmall,
                l10n.weightTitle,
                trendColor: _weightTrendChartColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 220, child: _buildChart(theme, l10n)),
          const SizedBox(height: 16),
          Text(
            l10n.weightMeasurementTrend,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildChartLegendItem(
                _bustChartColor,
                theme.textTheme.labelSmall,
                l10n.weightBust,
              ),
              _buildChartLegendItem(
                _waistChartColor,
                theme.textTheme.labelSmall,
                l10n.weightWaist,
              ),
              _buildChartLegendItem(
                _hipChartColor,
                theme.textTheme.labelSmall,
                l10n.weightHip,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 190, child: _buildMeasurementChart(theme, l10n)),
        ],
      ),
    );
  }

  /// Purpose: Build a compact line legend item for raw and smoothed series.
  /// Inputs: `color`, `labelStyle`, `label`, `trendColor`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: The solid segment represents actual values and the dashed segment represents smoothing.
  Widget _buildChartLegendItem(
    Color color,
    TextStyle? labelStyle,
    String label, {
    Color? trendColor,
  }) {
    final dashedColor = trendColor ?? color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 2, color: color),
        const SizedBox(width: 2),
        Container(width: 4, height: 2, color: dashedColor.withValues(alpha: 0)),
        Container(
          width: 6,
          height: 2,
          color: dashedColor.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(label, style: labelStyle),
      ],
    );
  }

  /// Purpose: Return chart records.
  /// Inputs: None.
  /// Returns: `List<WeightRecord>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<WeightRecord> get _chartRecords {
    final now = DateTime.now();
    final cutoff = switch (_chartRange) {
      _ChartRange.oneWeek => now.subtract(const Duration(days: 7)),
      _ChartRange.oneMonth => DateTime(now.year, now.month - 1, now.day),
      _ChartRange.threeMonths => DateTime(now.year, now.month - 3, now.day),
      _ChartRange.sixMonths => DateTime(now.year, now.month - 6, now.day),
      _ChartRange.oneYear => DateTime(now.year - 1, now.month, now.day),
      _ChartRange.all => DateTime(2000),
    };
    final filtered = _records.where((r) => r.datetime.isAfter(cutoff)).toList()
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
    return filtered;
  }

  /// Purpose: Provide the internal build chart helper for this file.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Shows weight actual values and EWMA smoothing only.
  Widget _buildChart(ThemeData theme, AppLocalizations l10n) {
    final data = _chartRecords;
    if (data.length < 2) {
      return Center(
        child: Text(
          l10n.commonNoData,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(
        e.value.datetime.millisecondsSinceEpoch.toDouble(),
        e.value.weight,
      );
    }).toList();

    final allSorted = List<WeightRecord>.from(_records)
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
    final ewmaSpots = _buildWeightEwmaSpots(allSorted, data.first.datetime);

    final minW = data.map((r) => r.weight).reduce(math.min);
    final maxW = data.map((r) => r.weight).reduce(math.max);
    final yPad = math.max((maxW - minW) * 0.2, 0.5);
    final weightMinY = minW - yPad;
    final weightMaxY = maxW + yPad;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _weightInterval(maxW - minW),
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
              reservedSize: 32,
              interval: _dateInterval(data),
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) =>
                  _buildDateTitle(theme, data, value, meta, l10n.localeName),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: _weightInterval(maxW - minW),
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toStringAsFixed(maxW - minW <= 2 ? 1 : 0),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: _weightChartColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        minY: weightMinY,
        maxY: weightMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: _weightChartColor.withValues(alpha: 0.55),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _weightChartColor.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: ewmaSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: _weightTrendChartColor,
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => switch (spot.barIndex) {
              1 => _weightTrendChartColor,
              _ => _weightChartColor,
            },
            getTooltipItems: (spots) => spots.asMap().entries.map((entry) {
              final s = entry.value;
              final date = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
              return LineTooltipItem(
                '${l10n.weightTitle}: ${s.y.toStringAsFixed(1)} ${l10n.weightUnitKg}\n${DateFormat('MMM d', l10n.localeName).format(date)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Purpose: Build the body-measurement trend chart.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Bust, waist, and hip use centimeters on a shared axis.
  Widget _buildMeasurementChart(ThemeData theme, AppLocalizations l10n) {
    final data = _chartRecords;
    if (data.length < 2) {
      return Center(
        child: Text(
          l10n.commonNoData,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final cutoff = data.first.datetime;
    final timeline = WeightData.effectiveMeasurementTimeline(_records);
    final visibleTimeline = timeline
        .where((point) => !point.datetime.isBefore(cutoff))
        .toList();
    final bustSpots = _buildMeasurementSpots(
      visibleTimeline,
      (point) => point.bustCm,
    );
    final waistSpots = _buildMeasurementSpots(
      visibleTimeline,
      (point) => point.waistCm,
    );
    final hipSpots = _buildMeasurementSpots(
      visibleTimeline,
      (point) => point.hipCm,
    );
    final bustEwmaSpots = _buildMeasurementEwmaSpots(
      timeline,
      cutoff,
      (point) => point.bustCm,
    );
    final waistEwmaSpots = _buildMeasurementEwmaSpots(
      timeline,
      cutoff,
      (point) => point.waistCm,
    );
    final hipEwmaSpots = _buildMeasurementEwmaSpots(
      timeline,
      cutoff,
      (point) => point.hipCm,
    );
    final hasEnoughData = [
      bustSpots,
      waistSpots,
      hipSpots,
    ].any((spots) => spots.length >= 2);
    if (!hasEnoughData) {
      return Center(
        child: Text(
          l10n.commonNoData,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final allSpots = [
      ...bustSpots,
      ...waistSpots,
      ...hipSpots,
      ...bustEwmaSpots,
      ...waistEwmaSpots,
      ...hipEwmaSpots,
    ];
    final (minY, maxY) = _measurementAxisRange(allSpots);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _measurementInterval(maxY - minY),
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
              reservedSize: 32,
              interval: _dateInterval(data),
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) =>
                  _buildDateTitle(theme, data, value, meta, l10n.localeName),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: _measurementInterval(maxY - minY),
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toStringAsFixed(0),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: _waistChartColor,
                  ),
                ),
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
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          _buildMeasurementChartLine(bustSpots, _bustChartColor),
          _buildMeasurementChartLine(
            bustEwmaSpots,
            _bustChartColor,
            smoothed: true,
          ),
          _buildMeasurementChartLine(waistSpots, _waistChartColor),
          _buildMeasurementChartLine(
            waistEwmaSpots,
            _waistChartColor,
            smoothed: true,
          ),
          _buildMeasurementChartLine(hipSpots, _hipChartColor),
          _buildMeasurementChartLine(
            hipEwmaSpots,
            _hipChartColor,
            smoothed: true,
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => switch (spot.barIndex) {
              0 || 1 => _bustChartColor,
              2 || 3 => _waistChartColor,
              _ => _hipChartColor,
            },
            getTooltipItems: (spots) {
              return spots.asMap().entries.map((entry) {
                final s = entry.value;
                if (s.barIndex.isEven) return null;
                final date = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
                final label = switch (s.barIndex) {
                  1 => l10n.weightBust,
                  3 => l10n.weightWaist,
                  _ => l10n.weightHip,
                };
                return LineTooltipItem(
                  '$label: ${s.y.toStringAsFixed(1)} cm\n${DateFormat('MMM d', l10n.localeName).format(date)}',
                  const TextStyle(
                    color: Colors.white,
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

  /// Purpose: Build a bottom-axis date label for chart titles.
  /// Inputs: `theme`, `data`, `value`, `meta`, and `localeName`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Uses shorter formats for dense ranges to reduce label overlap.
  Widget _buildDateTitle(
    ThemeData theme,
    List<WeightRecord> data,
    double value,
    TitleMeta meta,
    String localeName,
  ) {
    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    final spanDays = data.last.datetime.difference(data.first.datetime).inDays;
    final fmt = spanDays > 730
        ? DateFormat('yyyy', localeName)
        : spanDays > 365
        ? DateFormat('M/yy', localeName)
        : DateFormat('M/d', localeName);
    return SideTitleWidget(
      meta: meta,
      child: Text(
        fmt.format(date),
        style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
      ),
    );
  }

  /// Purpose: Build chart spots for one effective measurement field.
  /// Inputs: `data`, `selectValue`.
  /// Returns: `List<FlSpot>`.
  /// Side effects: None.
  /// Notes: Values are already inherited from previous explicit measurements.
  List<FlSpot> _buildMeasurementSpots(
    List<EffectiveWeightMeasurementPoint> data,
    double? Function(EffectiveWeightMeasurementPoint point) selectValue,
  ) {
    return data
        .map((point) {
          final value = selectValue(point);
          if (value == null) return null;
          return FlSpot(
            point.datetime.millisecondsSinceEpoch.toDouble(),
            value,
          );
        })
        .whereType<FlSpot>()
        .toList();
  }

  /// Purpose: Return a padded centimeter axis range for measurement series.
  /// Inputs: `spots`.
  /// Returns: `(double, double)`.
  /// Side effects: None.
  /// Notes: Uses a minimum visible range so near-identical measurements remain readable.
  (double, double) _measurementAxisRange(List<FlSpot> spots) {
    if (spots.isEmpty) return (0, 1);
    final minCm = spots.map((spot) => spot.y).reduce(math.min);
    final maxCm = spots.map((spot) => spot.y).reduce(math.max);
    final pad = math.max((maxCm - minCm) * 0.15, 2.0);
    final low = math.max(0, minCm - pad);
    return (low.toDouble(), maxCm + pad);
  }

  /// Purpose: Build a body-measurement line for the measurement trend chart.
  /// Inputs: `spots`, `color`, `smoothed`.
  /// Returns: `LineChartBarData`.
  /// Side effects: None.
  /// Notes: Actual values are solid; smoothed values are dashed and curved.
  LineChartBarData _buildMeasurementChartLine(
    List<FlSpot> spots,
    Color color, {
    bool smoothed = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: smoothed,
      curveSmoothness: 0.3,
      color: smoothed ? color : color.withValues(alpha: 0.45),
      barWidth: smoothed ? 2 : 1.5,
      dashArray: smoothed ? [6, 4] : null,
      dotData: const FlDotData(show: false),
    );
  }

  /// EWMA smoothed weight trend. τ = 7 days half-life.
  /// [allData] must include all records sorted oldest→newest for warm-up accuracy.
  /// Only emits spots for records on or after [visibleFrom].
  /// Purpose: Provide the internal build weight ewma spots helper for this file.
  /// Inputs: `allData`, `visibleFrom`, `halfLifeDays`.
  /// Returns: `List<FlSpot>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<FlSpot> _buildWeightEwmaSpots(
    List<WeightRecord> allData,
    DateTime visibleFrom, {
    double halfLifeDays = 7,
  }) {
    if (allData.isEmpty) return [];
    final tau = halfLifeDays * 86400 * 1000; // in ms
    double ewma = allData.first.weight;
    DateTime prevTime = allData.first.datetime;
    final spots = <FlSpot>[];
    for (final r in allData) {
      final dtMs = r.datetime.difference(prevTime).inMilliseconds.toDouble();
      final alpha = 1.0 - math.exp(-dtMs / tau);
      ewma = alpha * r.weight + (1 - alpha) * ewma;
      if (!r.datetime.isBefore(visibleFrom)) {
        spots.add(FlSpot(r.datetime.millisecondsSinceEpoch.toDouble(), ewma));
      }
      prevTime = r.datetime;
    }
    return spots;
  }

  /// Purpose: Build EWMA smoothed spots for one effective body measurement field.
  /// Inputs: `allData`, `visibleFrom`, `selectValue`, `halfLifeDays`.
  /// Returns: `List<FlSpot>`.
  /// Side effects: None.
  /// Notes: Missing fields are skipped until their first explicit measurement exists.
  List<FlSpot> _buildMeasurementEwmaSpots(
    List<EffectiveWeightMeasurementPoint> allData,
    DateTime visibleFrom,
    double? Function(EffectiveWeightMeasurementPoint point) selectValue, {
    double halfLifeDays = 7,
  }) {
    if (allData.isEmpty) return [];
    final tau = halfLifeDays * 86400 * 1000;
    double? ewma;
    DateTime? prevTime;
    final spots = <FlSpot>[];
    for (final point in allData) {
      final value = selectValue(point);
      if (value == null) continue;
      if (ewma == null || prevTime == null) {
        ewma = value;
      } else {
        final dtMs = point.datetime
            .difference(prevTime)
            .inMilliseconds
            .toDouble();
        final alpha = 1.0 - math.exp(-dtMs / tau);
        ewma = alpha * value + (1 - alpha) * ewma;
      }
      if (!point.datetime.isBefore(visibleFrom)) {
        spots.add(
          FlSpot(point.datetime.millisecondsSinceEpoch.toDouble(), ewma),
        );
      }
      prevTime = point.datetime;
    }
    return spots;
  }

  /// Purpose: Provide the internal weight interval helper for this file.
  /// Inputs: `range`.
  /// Returns: `double`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  double _weightInterval(double range) {
    if (range <= 2) return 0.5;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    return 5;
  }

  /// Purpose: Return a readable y-axis interval for centimeter measurements.
  /// Inputs: `range`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Keeps measurement labels sparse enough for compact chart heights.
  double _measurementInterval(double range) {
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 25) return 5;
    return 10;
  }

  /// Purpose: Provide the internal date interval helper for this file.
  /// Inputs: `data`.
  /// Returns: `double`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  double _dateInterval(List<WeightRecord> data) {
    if (data.length < 2) return 1;
    final spanMs = data.last.datetime
        .difference(data.first.datetime)
        .inMilliseconds
        .toDouble();
    final spanDays = spanMs / (86400 * 1000);
    // Choose a clean interval in milliseconds based on total span
    const day = 86400 * 1000.0;
    if (spanDays <= 7) return 3 * day;
    if (spanDays <= 30) return 10 * day;
    if (spanDays <= 90) return 30 * day;
    if (spanDays <= 180) return 60 * day;
    if (spanDays <= 365) return 120 * day;
    if (spanDays <= 730) return 240 * day;
    if (spanDays <= 1825) return 365 * day; // annual labels
    return 730 * day; // 2-year labels
  }

  // ── Records list ──

  /// Purpose: Provide the internal build records list helper for this file.
  /// Inputs: `theme`, `l10n`, and `weekStartDay`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildRecordsList(
    ThemeData theme,
    AppLocalizations l10n,
    int weekStartDay,
  ) {
    final sorted = List<WeightRecord>.from(_records)
      ..sort((a, b) => b.datetime.compareTo(a.datetime));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weightHistory,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildGroupedRecordTiles(
            theme,
            l10n,
            sorted.take(20).toList(),
            weekStartDay,
          ),
          if (sorted.length > 20)
            Center(
              child: TextButton(
                onPressed: () => _showAllRecords(context, weekStartDay),
                child: Text(l10n.weightShowAll),
              ),
            ),
        ],
      ),
    );
  }

  /// Purpose: Provide the internal build grouped record tiles helper for this file.
  /// Inputs: `theme`, `l10n`, `records`, and `weekStartDay`.
  /// Returns: `List<Widget>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<Widget> _buildGroupedRecordTiles(
    ThemeData theme,
    AppLocalizations l10n,
    List<WeightRecord> records,
    int weekStartDay,
  ) {
    final groups = groupByWeek(
      records,
      (record) => record.datetime,
      weekStartDay: weekStartDay,
    );
    return [
      for (final group in groups) ...[
        _buildWeekHeader(theme, l10n, group),
        ...group.items.map((record) => _buildRecordTile(theme, l10n, record)),
      ],
    ];
  }

  /// Purpose: Provide the internal build week header helper for this file.
  /// Inputs: `theme`, `l10n`, `group`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildWeekHeader(
    ThemeData theme,
    AppLocalizations l10n,
    WeekGroup<WeightRecord> group,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        l10n.commonWeekGroup(
          group.year,
          group.week,
          formatMonthDayRange(
            group.start,
            group.end,
            localeName: l10n.localeName,
          ),
        ),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Purpose: Provide the internal build record tile helper for this file.
  /// Inputs: `theme`, `l10n`, `record`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildRecordTile(
    ThemeData theme,
    AppLocalizations l10n,
    WeightRecord record,
  ) {
    final bmi = WeightData.calculateBMI(_height, record.weight);
    final measurements = _formatMeasurements(record, l10n);
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) => confirmDelete(
        context,
        AppLocalizations.of(context)!.commonThisRecord,
      ),
      onDismissed: (_) {
        setState(() => _records.removeWhere((r) => r.id == record.id));
        _saveData();
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.monitor_weight_outlined,
            color: theme.colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          '${record.weight.toStringAsFixed(1)} ${l10n.weightUnitKg}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            DateFormat(
              'MMM d, yyyy  HH:mm',
              l10n.localeName,
            ).format(record.datetime),
            if (bmi != null) 'BMI ${bmi.toStringAsFixed(1)}',
            ?measurements,
            if (record.notes != null && record.notes!.isNotEmpty) record.notes,
          ].join(' · '),
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => _editRecord(record),
      ),
    );
  }

  /// Purpose: Format optional body measurements for a history row.
  /// Inputs: `record`, `l10n`.
  /// Returns: `String?`.
  /// Side effects: None.
  /// Notes: Omits missing and non-positive measurements.
  String? _formatMeasurements(WeightRecord record, AppLocalizations l10n) {
    final parts = [
      if (record.bustCm != null && record.bustCm! > 0)
        '${l10n.weightBust} ${record.bustCm!.toStringAsFixed(1)} cm',
      if (record.waistCm != null && record.waistCm! > 0)
        '${l10n.weightWaist} ${record.waistCm!.toStringAsFixed(1)} cm',
      if (record.hipCm != null && record.hipCm! > 0)
        '${l10n.weightHip} ${record.hipCm!.toStringAsFixed(1)} cm',
    ];
    if (parts.isEmpty) return null;
    return parts.join(' / ');
  }

  /// Purpose: Provide the internal show all records helper for this file.
  /// Inputs: `context`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _showAllRecords(BuildContext context, int weekStartDay) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sorted = List<WeightRecord>.from(_records)
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: _buildGroupedRecordTiles(theme, l10n, sorted, weekStartDay),
        ),
      ),
    );
  }

  // ── Actions ──

  /// Purpose: Provide the internal show reminder settings helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _showReminderSettings() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: Text(l10n.weightReminder),
                  ),
                  const Divider(height: 1),

                  RadioGroup<String>(
                    groupValue: _reminderMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _reminderMode = value;
                        switch (value) {
                          case 'none':
                            _weightMorningReminder = null;
                            _weightEveningReminder = null;
                          case 'once':
                            _weightMorningReminder ??= const TimeOfDay(
                              hour: 8,
                              minute: 0,
                            );
                            _weightEveningReminder = null;
                          case 'twice':
                            _weightMorningReminder ??= const TimeOfDay(
                              hour: 8,
                              minute: 0,
                            );
                            _weightEveningReminder ??= const TimeOfDay(
                              hour: 21,
                              minute: 0,
                            );
                        }
                      });
                      setSheetState(() {});
                      _saveData();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Off
                        RadioListTile<String>(
                          value: 'none',
                          title: Text(l10n.weightReminderNone),
                        ),

                        // Once daily
                        RadioListTile<String>(
                          value: 'once',
                          title: Text(l10n.weightReminderOnce),
                        ),

                        // Twice daily
                        RadioListTile<String>(
                          value: 'twice',
                          title: Text(l10n.weightReminderTwice),
                        ),
                      ],
                    ),
                  ),

                  if (_reminderMode != 'none') ...[
                    const Divider(height: 1),

                    // Morning time picker
                    ListTile(
                      leading: const Icon(Icons.wb_sunny_outlined),
                      title: Text(l10n.weightReminderMorning),
                      subtitle: Text(_weightMorningReminder?.format(ctx) ?? ''),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime:
                              _weightMorningReminder ??
                              const TimeOfDay(hour: 8, minute: 0),
                        );
                        if (picked != null) {
                          setState(() => _weightMorningReminder = picked);
                          setSheetState(() {});
                          _saveData();
                        }
                      },
                    ),

                    if (_reminderMode == 'twice')
                      ListTile(
                        leading: const Icon(Icons.nightlight_outlined),
                        title: Text(l10n.weightReminderEvening),
                        subtitle: Text(
                          _weightEveningReminder?.format(ctx) ?? '',
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime:
                                _weightEveningReminder ??
                                const TimeOfDay(hour: 21, minute: 0),
                          );
                          if (picked != null) {
                            setState(() => _weightEveningReminder = picked);
                            setSheetState(() {});
                            _saveData();
                          }
                        },
                      ),

                    ListTile(
                      leading: const Icon(Icons.timer_off_outlined),
                      title: Text(l10n.weightReminderSkipWindow),
                      subtitle: Text(
                        l10n.weightReminderSkipWindowValue(
                          _formatReminderGraceHours(),
                        ),
                      ),
                      onTap: () => _editReminderGrace(ctx, setSheetState),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Purpose: Provide the internal format reminder grace hours helper for this file.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _formatReminderGraceHours() {
    final hours = _reminderGraceMinutes / 60;
    return hours == hours.roundToDouble()
        ? hours.toInt().toString()
        : hours.toStringAsFixed(1);
  }

  /// Purpose: Provide the internal edit reminder grace helper for this file.
  /// Inputs: `context`, `setSheetState`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _editReminderGrace(
    BuildContext context,
    StateSetter setSheetState,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _formatReminderGraceHours());
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.weightReminderSkipWindow),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_decimalInputFormatter(1)],
          decoration: InputDecoration(
            labelText: l10n.weightReminderSkipWindowHours,
            suffixText: 'h',
          ),
          onSubmitted: (_) {
            _saveReminderGrace(dialogContext, controller, setSheetState);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              _saveReminderGrace(dialogContext, controller, setSheetState);
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  /// Purpose: Provide the internal save reminder grace helper for this file.
  /// Inputs: `dialogContext`, `controller`, `setSheetState`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _saveReminderGrace(
    BuildContext dialogContext,
    TextEditingController controller,
    StateSetter setSheetState,
  ) {
    final hours = double.tryParse(controller.text.trim());
    if (hours == null || hours < 0 || hours > 24) return;
    Navigator.pop(dialogContext);
    setState(() => _reminderGraceMinutes = (hours * 60).round());
    setSheetState(() {});
    _saveData();
  }

  /// Purpose: Provide the internal add record helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _addRecord() async {
    final result = await showDialog<WeightRecord>(
      context: context,
      builder: (_) => _WeightRecordDialog(
        height: _height,
        lastWeight: _latestRecord?.weight,
      ),
    );
    if (result != null) {
      setState(() => _records.add(result));
      await _saveData();
    }
  }

  /// Purpose: Open the edit dialog for an existing weight record.
  /// Inputs: `record`.
  /// Returns: `Future<void>`.
  /// Side effects: Updates local records and persists weight data when saved.
  /// Notes: Keeps the original record id and refreshes `modifiedAt`.
  Future<void> _editRecord(WeightRecord record) async {
    final result = await showDialog<WeightRecord>(
      context: context,
      builder: (_) =>
          _WeightRecordDialog(height: _height, initialRecord: record),
    );
    if (result != null) {
      setState(() {
        final index = _records.indexWhere((item) => item.id == record.id);
        if (index >= 0) _records[index] = result;
      });
      await _saveData();
    }
  }

  /// Purpose: Provide the internal set height helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _setHeight() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: _height?.toStringAsFixed(1) ?? '',
    );
    final initialHeightText = controller.text.trim();

    /// Purpose: Save the currently entered height value and close the dialog.
    /// Inputs: `guard`.
    /// Returns: None.
    /// Side effects: Pops the dialog, updates local height state, and persists weight data.
    /// Notes: Internal helper used within this function only.
    void saveHeight(UnsavedChangesController guard) {
      final val = double.tryParse(controller.text.trim());
      if (val != null && val > 0) {
        guard.pop();
        setState(() => _height = val);
        _saveData();
      }
    }

    showDialog(
      context: context,
      builder: (context) => UnsavedChangesGuard(
        hasUnsavedChanges: () => controller.text.trim() != initialHeightText,
        builder: (context, guard) => AlertDialog(
          title: Text(l10n.weightSetHeight),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalInputFormatter(1)],
            decoration: InputDecoration(
              labelText: l10n.weightHeightCm,
              suffixText: 'cm',
            ),
            onSubmitted: (_) {
              saveHeight(guard);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => guard.maybeDiscardAndPop(),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => saveHeight(guard),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Provide the internal time since last record helper for this file.
  /// Inputs: `dt`, `l10n`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _timeSinceLastRecord(DateTime dt, AppLocalizations l10n) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return l10n.weightToday;
    if (diff.inDays == 1) return l10n.weightYesterday;
    if (diff.inDays < 7) return '${diff.inDays} ${l10n.weightDaysAgo}';
    final weeks = diff.inDays ~/ 7;
    return '$weeks ${l10n.weightWeeksAgo}';
  }
}

// ── Add/edit weight dialog ──

class _WeightRecordDialog extends StatefulWidget {
  final double? height;
  final double? lastWeight;
  final WeightRecord? initialRecord;

  /// Purpose: Create a weight record dialog instance.
  /// Inputs: Optional `lastWeight` and `initialRecord`.
  /// Returns: A new `_WeightRecordDialog` instance.
  /// Side effects: None.
  /// Notes: Internal helper used for both adding and editing records.
  const _WeightRecordDialog({this.height, this.lastWeight, this.initialRecord});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<_WeightRecordDialog> createState() => _WeightRecordDialogState();
}

class _WeightRecordDialogState extends State<_WeightRecordDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _bustController;
  late final TextEditingController _waistController;
  late final TextEditingController _hipController;
  late final TextEditingController _noteController;
  late DateTime _date;
  late final String _initialSignature;

  /// Purpose: Return whether this dialog is editing an existing record.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  bool get _isEditing => widget.initialRecord != null;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    _weightController = TextEditingController(
      text:
          record?.weight.toStringAsFixed(1) ??
          widget.lastWeight?.toStringAsFixed(1) ??
          '',
    );
    _bustController = TextEditingController(
      text: _formatInitialMeasurement(record?.bustCm),
    );
    _waistController = TextEditingController(
      text: _formatInitialMeasurement(record?.waistCm),
    );
    _hipController = TextEditingController(
      text: _formatInitialMeasurement(record?.hipCm),
    );
    _noteController = TextEditingController(text: record?.notes ?? '');
    _date = record?.datetime ?? DateTime.now();
    _initialSignature = _signature();
  }

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Releases owned resources and unregisters listeners.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    _weightController.dispose();
    _bustController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bmi = _previewBMI;

    return UnsavedChangesGuard(
      hasUnsavedChanges: _hasUnsavedChanges,
      builder: (context, guard) => Dialog(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? l10n.weightEditRecord : l10n.weightAddRecord,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Weight input
              TextField(
                controller: _weightController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalInputFormatter(1)],
                decoration: InputDecoration(
                  labelText: l10n.weightKg,
                  suffixText: l10n.weightUnitKg,
                  helperText: bmi != null
                      ? 'BMI: ${bmi.toStringAsFixed(1)}'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(guard),
              ),
              const SizedBox(height: 12),

              // Optional body measurements
              Text(
                l10n.weightMeasurements,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMeasurementField(
                      l10n.weightBust,
                      _bustController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMeasurementField(
                      l10n.weightWaist,
                      _waistController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMeasurementField(
                      l10n.weightHip,
                      _hipController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Note
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: l10n.weightNote,
                  hintText: l10n.weightNoteHint,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(guard),
              ),
              const SizedBox(height: 12),

              // Date picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('yyyy-MM-dd  HH:mm').format(_date)),
                onTap: () async {
                  final pickedDate = await showAppDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    title: l10n.commonDate,
                  );
                  if (pickedDate != null && mounted) {
                    final pickedTime = await showTimePicker(
                      // ignore: use_build_context_synchronously
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_date),
                    );
                    setState(() {
                      final time = pickedTime ?? TimeOfDay.fromDateTime(_date);
                      _date = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => guard.maybeDiscardAndPop(),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _submit(guard),
                    child: Text(_isEditing ? l10n.commonSave : l10n.commonAdd),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Purpose: Provide the internal has unsaved changes helper for this file.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  bool _hasUnsavedChanges() => _signature() != _initialSignature;

  /// Purpose: Provide the internal signature helper for this file.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _signature() => formSignature([
    _weightController.text.trim(),
    _bustController.text.trim(),
    _waistController.text.trim(),
    _hipController.text.trim(),
    _noteController.text.trim(),
    _date,
  ]);

  /// Purpose: Build one optional measurement input field.
  /// Inputs: `label`, `controller`.
  /// Returns: `Widget`.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Internal helper used within this file only.
  Widget _buildMeasurementField(
    String label,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_decimalInputFormatter(1)],
      decoration: InputDecoration(labelText: label, suffixText: 'cm'),
      textInputAction: TextInputAction.next,
    );
  }

  /// Purpose: Return preview bmi.
  /// Inputs: None.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  double? get _previewBMI {
    final w = double.tryParse(_weightController.text.trim());
    if (w == null || w <= 0) return null;
    return WeightData.calculateBMI(widget.height, w);
  }

  /// Purpose: Format a persisted measurement value for dialog initialization.
  /// Inputs: `value`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Non-positive values are treated as absent.
  String _formatInitialMeasurement(double? value) {
    if (value == null || value <= 0) return '';
    return value.toStringAsFixed(1);
  }

  /// Purpose: Parse a positive optional measurement from a text controller.
  /// Inputs: `controller`.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Empty, zero, negative, and malformed values are stored as absent.
  double? _optionalMeasurement(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim());
    if (value == null || value <= 0) return null;
    return value;
  }

  /// Purpose: Provide the internal submit helper for this file.
  /// Inputs: `guard`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _submit(UnsavedChangesController guard) {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;

    final bustCm = _optionalMeasurement(_bustController);
    final waistCm = _optionalMeasurement(_waistController);
    final hipCm = _optionalMeasurement(_hipController);
    final notes = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;
    final record =
        widget.initialRecord?.copyWith(
          weight: weight,
          bustCm: bustCm,
          clearBustCm: bustCm == null,
          waistCm: waistCm,
          clearWaistCm: waistCm == null,
          hipCm: hipCm,
          clearHipCm: hipCm == null,
          datetime: _date,
          notes: notes,
          clearNotes: notes == null,
        ) ??
        WeightRecord(
          weight: weight,
          bustCm: bustCm,
          waistCm: waistCm,
          hipCm: hipCm,
          datetime: _date,
          notes: notes,
        );
    guard.pop(record);
  }
}

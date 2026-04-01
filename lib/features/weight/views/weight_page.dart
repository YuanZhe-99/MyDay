import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/auto_sync_service.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../models/weight_record.dart';
import '../services/weight_storage.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

enum _ChartRange { oneWeek, oneMonth, threeMonths, sixMonths, oneYear, all }

class _WeightPageState extends State<WeightPage> {
  double? _height; // cm
  List<WeightRecord> _records = [];
  bool _loaded = false;
  _ChartRange _chartRange = _ChartRange.oneMonth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await WeightStorage.load();
    setState(() {
      if (data != null) {
        _height = data.height;
        _records = data.records;
      }
      _loaded = true;
    });
  }

  Future<void> _saveData() async {
    await WeightStorage.save(WeightData(
      height: _height,
      records: _records,
    ));
    AutoSyncService.instance.notifySaved();
  }

  WeightRecord? get _latestRecord {
    if (_records.isEmpty) return null;
    final sorted = List<WeightRecord>.from(_records)
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    return sorted.first;
  }

  double? get _currentBMI {
    final latest = _latestRecord;
    if (latest == null) return null;
    return WeightData.calculateBMI(_height, latest.weight);
  }

  /// Weight change over the tracking period.
  double? get _weightChange {
    if (_records.length < 2) return null;
    final sorted = List<WeightRecord>.from(_records)
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
    return sorted.last.weight - sorted.first.weight;
  }

  int? get _trackingDays {
    if (_records.length < 2) return null;
    final sorted = List<WeightRecord>.from(_records)
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
    return sorted.last.datetime.difference(sorted.first.datetime).inDays;
  }

  /// Recent weight range.
  (double, double)? get _recentRange {
    if (_records.isEmpty) return null;
    final sorted = List<WeightRecord>.from(_records)
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    final recent = sorted.take(7).toList();
    final min = recent.map((r) => r.weight).reduce(math.min);
    final max = recent.map((r) => r.weight).reduce(math.max);
    return (min, max);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weightTitle),
        centerTitle: true,
        actions: [
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
              : _buildContent(theme, l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_weight_outlined,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(l10n.weightNoRecords,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
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

  Widget _buildContent(ThemeData theme, AppLocalizations l10n) {
    final latest = _latestRecord!;
    final bmi = _currentBMI;
    final change = _weightChange;
    final days = _trackingDays;
    final range = _recentRange;
    final timeSince = _timeSinceLastRecord(latest.datetime, l10n);

    return ListView(
      children: [
        // ── Summary card (like the reference UI) ──
        _buildSummaryCard(theme, l10n, latest, bmi, change, days, range, timeSince),
        const SizedBox(height: 16),

        // ── Chart section ──
        _buildChartSection(theme, l10n),
        const SizedBox(height: 16),

        // ── Today / Recent records ──
        _buildRecordsList(theme, l10n),
      ],
    );
  }

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
                      Text(timeSince,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(latest.weight.toStringAsFixed(1),
                              style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Text('kg',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (change != null && days != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$days ${l10n.weightDays}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
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
                            '${change.abs().toStringAsFixed(1)} kg',
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
            // Bottom stats row
            Row(
              children: [
                // Recent range
                if (range != null)
                  Expanded(
                    child: _buildStatLabel(
                      theme,
                      l10n.weightRecent,
                      '${range.$1.toStringAsFixed(0)}–${range.$2.toStringAsFixed(0)}',
                    ),
                  ),
                // BMI
                if (bmi != null)
                  Expanded(
                    child: _buildStatLabel(
                      theme,
                      'BMI',
                      bmi.toStringAsFixed(1),
                      trailing: _buildBMIBar(theme, bmi),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatLabel(ThemeData theme, String label, String value,
      {Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            if (trailing != null) ...[const SizedBox(width: 6), trailing],
          ],
        ),
      ],
    );
  }

  Widget _buildBMIBar(ThemeData theme, double bmi) {
    // BMI categories: <18.5 underweight, 18.5-25 normal, 25-30 overweight, 30+ obese
    const colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    final position = ((bmi - 15).clamp(0, 25) / 25).clamp(0.0, 1.0);
    return SizedBox(
      width: 60,
      height: 8,
      child: Stack(
        children: [
          Row(
            children: colors
                .map((c) => Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.6),
                          borderRadius: colors.indexOf(c) == 0
                              ? const BorderRadius.horizontal(
                                  left: Radius.circular(4))
                              : colors.indexOf(c) == 3
                                  ? const BorderRadius.horizontal(
                                      right: Radius.circular(4))
                                  : null,
                        ),
                      ),
                    ))
                .toList(),
          ),
          Positioned(
            left: (60 * position) - 2,
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
          Row(
            children: [
              Text(l10n.weightChart,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              // Range picker chips
              ...labels.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ChoiceChip(
                      label: Text(e.value,
                          style: const TextStyle(fontSize: 11)),
                      selected: _chartRange == e.key,
                      onSelected: (_) =>
                          setState(() => _chartRange = e.key),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: _buildChart(theme),
          ),
        ],
      ),
    );
  }

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
    final filtered = _records
        .where((r) => r.datetime.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
    return filtered;
  }

  Widget _buildChart(ThemeData theme) {
    final data = _chartRecords;
    if (data.isEmpty) {
      return Center(
          child: Text('No data',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(
        e.value.datetime.millisecondsSinceEpoch.toDouble(),
        e.value.weight,
      );
    }).toList();

    final minW = data.map((r) => r.weight).reduce(math.min);
    final maxW = data.map((r) => r.weight).reduce(math.max);
    final yPad = math.max((maxW - minW) * 0.2, 0.5);

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
              reservedSize: 28,
              interval: _dateInterval(data),
              getTitlesWidget: (value, meta) {
                final date =
                    DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    DateFormat('MMM d').format(date),
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(value.toStringAsFixed(0),
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        minY: minW - yPad,
        maxY: maxW + yPad,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: theme.colorScheme.primary,
            barWidth: 2,
            dotData: FlDotData(
              show: data.length <= 30,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: theme.colorScheme.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final date = DateTime.fromMillisecondsSinceEpoch(
                  s.x.toInt());
              return LineTooltipItem(
                '${s.y.toStringAsFixed(1)} kg\n${DateFormat('MMM d').format(date)}',
                TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  double _weightInterval(double range) {
    if (range <= 2) return 0.5;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    return 5;
  }

  double _dateInterval(List<WeightRecord> data) {
    if (data.length < 2) return 1;
    final span = data.last.datetime
        .difference(data.first.datetime)
        .inMilliseconds
        .toDouble();
    return math.max(span / 4, 1);
  }

  // ── Records list ──

  Widget _buildRecordsList(ThemeData theme, AppLocalizations l10n) {
    final sorted = List<WeightRecord>.from(_records)
      ..sort((a, b) => b.datetime.compareTo(a.datetime));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.weightHistory,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...sorted.take(20).map((r) => _buildRecordTile(theme, r)),
          if (sorted.length > 20)
            Center(
              child: TextButton(
                onPressed: () => _showAllRecords(context),
                child: Text(l10n.weightShowAll),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(ThemeData theme, WeightRecord record) {
    final bmi = WeightData.calculateBMI(_height, record.weight);
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child:
            Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) => confirmDelete(context, 'this record'),
      onDismissed: (_) {
        setState(() => _records.removeWhere((r) => r.id == record.id));
        _saveData();
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.monitor_weight_outlined,
              color: theme.colorScheme.onPrimaryContainer, size: 20),
        ),
        title: Text('${record.weight.toStringAsFixed(1)} kg',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            DateFormat('MMM d, yyyy  HH:mm').format(record.datetime),
            if (bmi != null) 'BMI ${bmi.toStringAsFixed(1)}',
            if (record.notes != null && record.notes!.isNotEmpty) record.notes,
          ].join(' · '),
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showAllRecords(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<WeightRecord>.from(_records)
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView.builder(
          controller: controller,
          itemCount: sorted.length,
          itemBuilder: (context, i) =>
              _buildRecordTile(theme, sorted[i]),
        ),
      ),
    );
  }

  // ── Actions ──

  Future<void> _addRecord() async {
    final result = await showDialog<WeightRecord>(
      context: context,
      builder: (_) => _AddWeightDialog(
        height: _height,
        lastWeight: _latestRecord?.weight,
      ),
    );
    if (result != null) {
      setState(() => _records.add(result));
      await _saveData();
    }
  }

  void _setHeight() {
    final l10n = AppLocalizations.of(context)!;
    final controller =
        TextEditingController(text: _height?.toStringAsFixed(1) ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.weightSetHeight),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
          ],
          decoration: InputDecoration(
            labelText: l10n.weightHeightCm,
            suffixText: 'cm',
          ),
          onSubmitted: (_) {
            final val = double.tryParse(controller.text.trim());
            if (val != null && val > 0) {
              Navigator.pop(context);
              setState(() => _height = val);
              _saveData();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(context);
                setState(() => _height = val);
                _saveData();
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  String _timeSinceLastRecord(DateTime dt, AppLocalizations l10n) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return l10n.weightToday;
    if (diff.inDays == 1) return l10n.weightYesterday;
    if (diff.inDays < 7) return '${diff.inDays} ${l10n.weightDaysAgo}';
    final weeks = diff.inDays ~/ 7;
    return '$weeks ${l10n.weightWeeksAgo}';
  }
}

// ── Add weight dialog ──

class _AddWeightDialog extends StatefulWidget {
  final double? height;
  final double? lastWeight;

  const _AddWeightDialog({this.height, this.lastWeight});

  @override
  State<_AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends State<_AddWeightDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _noteController;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
        text: widget.lastWeight?.toStringAsFixed(1) ?? '');
    _noteController = TextEditingController();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bmi = _previewBMI;

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.weightAddRecord,
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            // Weight input
            TextField(
              controller: _weightController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,1}')),
              ],
              decoration: InputDecoration(
                labelText: l10n.weightKg,
                suffixText: 'kg',
                helperText:
                    bmi != null ? 'BMI: ${bmi.toStringAsFixed(1)}' : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
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
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),

            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('yyyy-MM-dd  HH:mm').format(_date)),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.commonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.commonAdd),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double? get _previewBMI {
    final w = double.tryParse(_weightController.text.trim());
    if (w == null || w <= 0) return null;
    return WeightData.calculateBMI(widget.height, w);
  }

  void _submit() {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;

    final record = WeightRecord(
      weight: weight,
      datetime: _date,
      notes: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );
    Navigator.pop(context, record);
  }
}

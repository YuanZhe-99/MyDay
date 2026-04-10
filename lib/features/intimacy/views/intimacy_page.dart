import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/auto_sync_service.dart';
import '../../../shared/services/image_service.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../models/intimacy_record.dart';
import '../services/intimacy_storage.dart';
import '../widgets/add_record_dialog.dart';
import '../widgets/timer_page.dart';

enum _SortMode { dateDesc, dateAsc, pleasureDesc, durationDesc }
enum _FilterMode { all, solo, partnered, orgasm, noOrgasm }
enum _IntimacyChartRange { oneWeek, oneMonth, threeMonths, sixMonths, oneYear, all }

class IntimacyPage extends StatefulWidget {
  const IntimacyPage({super.key});

  @override
  State<IntimacyPage> createState() => _IntimacyPageState();
}

class _IntimacyPageState extends State<IntimacyPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  List<Partner> _partners = [];
  List<Toy> _toys = [];
  List<Position> _positions = [];
  List<IntimacyRecord> _records = [];
  List<TimerHistoryEntry> _timerHistory = [];
  int? _timerHistoryRetentionDays;
  DateTime _settingsModifiedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _loaded = false;

  _SortMode _sortMode = _SortMode.dateDesc;
  _FilterMode _filterMode = _FilterMode.all;
  _IntimacyChartRange _chartRange = _IntimacyChartRange.threeMonths;
  final bool _showChart = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  }

  @override
  void dispose() {
    AutoSyncService.instance.removeOnLocalDataChanged(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await IntimacyStorage.load();
    setState(() {
      if (data != null) {
        _partners = data.partners;
        _toys = data.toys;
        _positions = data.positions;
        _records = data.records;
        _timerHistory = data.timerHistory;
        _timerHistoryRetentionDays = data.timerHistoryRetentionDays;
        _settingsModifiedAt = data.settingsModifiedAt;
      }
      _loaded = true;
    });
  }

  Future<void> _saveData() async {
    await IntimacyStorage.save(IntimacyData(
      partners: _partners,
      toys: _toys,
      positions: _positions,
      records: _records,
      timerHistory: _timerHistory,
      timerHistoryRetentionDays: _timerHistoryRetentionDays,
      settingsModifiedAt: _settingsModifiedAt,
    ));
    AutoSyncService.instance.notifySaved();
  }

  Set<DateTime> get _markedDates {
    return _records
        .map((r) => DateTime(r.datetime.year, r.datetime.month, r.datetime.day))
        .toSet();
  }

  List<IntimacyRecord> get _filteredRecords {
    var list = List<IntimacyRecord>.from(_records);

    // Date filter (calendar selection)
    if (_selectedDate != null) {
      list = list.where((r) {
        final d = r.datetime;
        return d.year == _selectedDate!.year &&
            d.month == _selectedDate!.month &&
            d.day == _selectedDate!.day;
      }).toList();
    }

    // Type filter
    switch (_filterMode) {
      case _FilterMode.solo:
        list = list.where((r) => r.isSolo).toList();
      case _FilterMode.partnered:
        list = list.where((r) => !r.isSolo).toList();
      case _FilterMode.orgasm:
        list = list.where((r) => r.hadOrgasm).toList();
      case _FilterMode.noOrgasm:
        list = list.where((r) => !r.hadOrgasm).toList();
      case _FilterMode.all:
        break;
    }

    // Sort
    switch (_sortMode) {
      case _SortMode.dateDesc:
        list.sort((a, b) => b.datetime.compareTo(a.datetime));
      case _SortMode.dateAsc:
        list.sort((a, b) => a.datetime.compareTo(b.datetime));
      case _SortMode.pleasureDesc:
        list.sort((a, b) => b.pleasureLevel.compareTo(a.pleasureLevel));
      case _SortMode.durationDesc:
        list.sort((a, b) => b.duration.compareTo(a.duration));
    }

    return list;
  }

  Future<void> _addRecord() async {
    final record = await showDialog<IntimacyRecord>(
      context: context,
      builder: (_) => AddRecordDialog(partners: _partners, toys: _toys, positions: _positions),
    );
    if (record != null) {
      setState(() => _records.insert(0, record));
      await _saveData();
    }
  }

  void _deleteRecord(IntimacyRecord record) {
    setState(() => _records.removeWhere((r) => r.id == record.id));
    _saveData();
  }

  Future<void> _editRecord(IntimacyRecord record) async {
    final updated = await showDialog<IntimacyRecord>(
      context: context,
      builder: (_) =>
          AddRecordDialog(record: record, partners: _partners, toys: _toys, positions: _positions),
    );
    if (updated != null) {
      setState(() {
        final index = _records.indexWhere((r) => r.id == updated.id);
        if (index != -1) _records[index] = updated;
      });
      await _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.intimacyTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: AppLocalizations.of(context)!.intimacyTimer,
            onPressed: () async {
              final result = await Navigator.push<TimerPageResult>(
                context,
                MaterialPageRoute(
                    builder: (_) => TimerPage(
                          partners: _partners,
                          toys: _toys,
                          positions: _positions,
                          timerHistory: _timerHistory,
                          timerHistoryRetentionDays:
                              _timerHistoryRetentionDays,
                        )),
              );
              if (result != null) {
                bool needSave = false;
                if (result.record != null) {
                  setState(() => _records.insert(0, result.record!));
                  needSave = true;
                }
                if (result.updatedHistory != null) {
                  setState(
                      () => _timerHistory = result.updatedHistory!);
                  needSave = true;
                }
                if (result.retentionChanged) {
                  setState(() {
                    _timerHistoryRetentionDays =
                        result.updatedRetentionDays;
                    _settingsModifiedAt = DateTime.now().toUtc();
                  });
                  needSave = true;
                }
                if (needSave) await _saveData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppLocalizations.of(context)!.intimacyManage,
            onPressed: () => _showManageMenu(context),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar
                _CalendarWidget(
                  focusedMonth: _focusedMonth,
                  selectedDate: _selectedDate,
                  markedDates: _markedDates,
                  onMonthChanged: (month) {
                    setState(() => _focusedMonth = month);
                  },
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate =
                          _selectedDate == date ? null : date; // toggle
                    });
                  },
                ),
                const Divider(height: 1),

                // Trend chart section
                if (_records.length >= 2 && _showChart)
                  _buildChartSection(theme),

                // Records header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('MMM d').format(_selectedDate!)
                            : AppLocalizations.of(context)!.intimacyAllRecords,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedDate = null),
                          child: Text(AppLocalizations.of(context)!.intimacyShowAll),
                        ),
                      ],
                    ],
                  ),
                ),

                // Sort & filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      _buildSortChip(context),
                      const SizedBox(width: 6),
                      _buildFilterChip(context),
                    ],
                  ),
                ),

                Expanded(
                  child: _filteredRecords.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)!.intimacyNoRecords,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            return Dismissible(
                              key: ValueKey(record.id),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                color: theme.colorScheme.primary,
                                child: Icon(Icons.edit_outlined,
                                    color: theme.colorScheme.onPrimary),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: theme.colorScheme.error,
                                child: Icon(Icons.delete_outline,
                                    color: theme.colorScheme.onError),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction ==
                                    DismissDirection.startToEnd) {
                                  _editRecord(record);
                                  return false;
                                }
                                return confirmDelete(
                                    context, 'this record');
                              },
                              onDismissed: (_) => _deleteRecord(record),
                              child: _RecordTile(
                                record: record,
                                partner: record.partnerId != null
                                    ? _partners.where((p) => p.id == record.partnerId).firstOrNull
                                    : null,
                                toys: record.toyIds
                                    .map((id) => _toys.where((t) => t.id == id).firstOrNull)
                                    .whereType<Toy>()
                                    .toList(),
                                positions: record.positionIds
                                    .map((id) => _positions.where((p) => p.id == id).firstOrNull)
                                    .whereType<Position>()
                                    .toList(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSortChip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      _SortMode.dateDesc: l10n.intimacySortNewest,
      _SortMode.dateAsc: l10n.intimacySortOldest,
      _SortMode.pleasureDesc: l10n.intimacySortPleasure,
      _SortMode.durationDesc: l10n.intimacySortDuration,
    };
    return PopupMenuButton<_SortMode>(
      initialValue: _sortMode,
      onSelected: (v) => setState(() => _sortMode = v),
      itemBuilder: (_) => labels.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      child: Chip(
        avatar: const Icon(Icons.sort, size: 18),
        label: Text(labels[_sortMode]!),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      _FilterMode.all: l10n.intimacyFilterAll,
      _FilterMode.solo: l10n.intimacyFilterSolo,
      _FilterMode.partnered: l10n.intimacyFilterPartnered,
      _FilterMode.orgasm: l10n.intimacyFilterOrgasm,
      _FilterMode.noOrgasm: l10n.intimacyFilterNoOrgasm,
    };
    return PopupMenuButton<_FilterMode>(
      initialValue: _filterMode,
      onSelected: (v) => setState(() => _filterMode = v),
      itemBuilder: (_) => labels.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      child: Chip(
        avatar: const Icon(Icons.filter_list, size: 18),
        label: Text(labels[_filterMode]!),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // ── Trend chart ──

  List<IntimacyRecord> get _chartRecords {
    final now = DateTime.now();
    final cutoff = switch (_chartRange) {
      _IntimacyChartRange.oneWeek => now.subtract(const Duration(days: 7)),
      _IntimacyChartRange.oneMonth => DateTime(now.year, now.month - 1, now.day),
      _IntimacyChartRange.threeMonths => DateTime(now.year, now.month - 3, now.day),
      _IntimacyChartRange.sixMonths => DateTime(now.year, now.month - 6, now.day),
      _IntimacyChartRange.oneYear => DateTime(now.year - 1, now.month, now.day),
      _IntimacyChartRange.all => DateTime(2000),
    };
    return _records
        .where((r) => r.datetime.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
  }

  /// Build EWMA smoothed curve for pleasure level.
  /// Uses adaptive alpha based on time gap with half-life of [halfLifeDays].
  /// Processes [allData] for warm-up but only emits spots at/after [visibleFrom].
  List<FlSpot> _buildEwmaPleasureSpots(
    List<IntimacyRecord> allData,
    DateTime visibleFrom, {
    double halfLifeDays = 7,
  }) {
    if (allData.isEmpty) return [];
    final tau = halfLifeDays * 86400 * 1000; // half-life in ms
    final spots = <FlSpot>[];
    double ewma = allData.first.pleasureLevel.toDouble();
    DateTime prevTime = allData.first.datetime;

    for (final r in allData) {
      final dtMs = r.datetime.difference(prevTime).inMilliseconds.toDouble();
      final alpha = 1.0 - math.exp(-dtMs / tau);
      ewma = alpha * r.pleasureLevel + (1 - alpha) * ewma;
      if (!r.datetime.isBefore(visibleFrom)) {
        spots.add(FlSpot(
          r.datetime.millisecondsSinceEpoch.toDouble(),
          ewma,
        ));
      }
      prevTime = r.datetime;
    }
    return spots;
  }

  /// Build EWMA smoothed curve for frequency (records per week).
  /// Processes [allData] for warm-up but only emits spots at/after [visibleFrom].
  List<FlSpot> _buildEwmaFrequencySpots(
    List<IntimacyRecord> allData,
    DateTime visibleFrom, {
    double halfLifeDays = 14,
  }) {
    if (allData.isEmpty) return [];
    final tau = halfLifeDays * 86400 * 1000;
    final spots = <FlSpot>[];
    double ewma = 1.0; // initial estimate: 1 per week
    DateTime prevTime = allData.first.datetime;

    for (int i = 0; i < allData.length; i++) {
      final r = allData[i];
      final dtMs = r.datetime.difference(prevTime).inMilliseconds.toDouble();
      if (dtMs > 0) {
        // Instantaneous rate: 7 days / gap = records per week
        final rate = 7.0 * 86400 * 1000 / dtMs;
        final alpha = 1.0 - math.exp(-dtMs / tau);
        ewma = alpha * rate + (1 - alpha) * ewma;
      }
      if (!r.datetime.isBefore(visibleFrom)) {
        spots.add(FlSpot(
          r.datetime.millisecondsSinceEpoch.toDouble(),
          ewma,
        ));
      }
      prevTime = r.datetime;
    }
    return spots;
  }

  Widget _buildChartSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      _IntimacyChartRange.oneWeek: '1W',
      _IntimacyChartRange.oneMonth: '1M',
      _IntimacyChartRange.threeMonths: '3M',
      _IntimacyChartRange.sixMonths: '6M',
      _IntimacyChartRange.oneYear: '1Y',
      _IntimacyChartRange.all: l10n.weightAll,
    };

    final data = _chartRecords;
    final allSorted = List<IntimacyRecord>.from(_records)
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
    final cutoff = data.isNotEmpty ? data.first.datetime : DateTime.now();
    final pleasureSpots = _buildEwmaPleasureSpots(allSorted, cutoff);
    final frequencySpots = _buildEwmaFrequencySpots(allSorted, cutoff);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.intimacyTrend,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
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
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              Container(width: 16, height: 2, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(l10n.intimacyPleasure, style: theme.textTheme.labelSmall),
              const SizedBox(width: 16),
              Container(
                width: 16, height: 2,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: theme.colorScheme.tertiary,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignCenter,
                  )),
                ),
              ),
              const SizedBox(width: 4),
              Text(l10n.intimacyFrequency, style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: data.length < 2
                ? Center(child: Text(l10n.intimacyChartNoData,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
                : _buildChart(theme, pleasureSpots, frequencySpots, data),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _buildChart(
    ThemeData theme,
    List<FlSpot> pleasureSpots,
    List<FlSpot> frequencySpots,
    List<IntimacyRecord> data,
  ) {
    final maxFreq = frequencySpots.isEmpty
        ? 5.0
        : frequencySpots.map((s) => s.y).reduce(math.max);
    // Snap freqMax to a clean ceiling so right-axis labels land on round numbers
    double freqCeil(double v) {
      const steps = [1.0, 2.0, 3.0, 5.0, 7.0, 10.0, 14.0, 20.0];
      for (final s in steps) {
        if (s >= v) return s;
      }
      return (v / 5).ceil() * 5.0;
    }
    final freqMax = freqCeil(math.max(maxFreq * 1.1, 1.0));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
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
              interval: _chartDateInterval(data),
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                final spanDays = data.last.datetime.difference(data.first.datetime).inDays;
                final fmt = spanDays > 30 ? DateFormat('M/d') : DateFormat('MMM d');
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    fmt.format(date),
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble()) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text('${value.toInt()}',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble()) return const SizedBox.shrink();
                final actualFreq = value / 5 * freqMax;
                final label = freqMax <= 3
                    ? actualFreq.toStringAsFixed(1)
                    : actualFreq.toStringAsFixed(0);
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        minY: 0,
        maxY: 5.5,
        lineBarsData: [
          // Pleasure EWMA line (solid, primary color)
          LineChartBarData(
            spots: pleasureSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: theme.colorScheme.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          // Frequency EWMA line (dashed, tertiary color, scaled to fit 0-5)
          LineChartBarData(
            spots: frequencySpots
                .map((s) => FlSpot(s.x, (s.y / freqMax) * 5))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: theme.colorScheme.tertiary,
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.asMap().entries.map((entry) {
                final s = entry.value;
                final date = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
                if (entry.key == 0) {
                  return LineTooltipItem(
                    '${AppLocalizations.of(context)!.intimacyPleasure}: ${s.y.toStringAsFixed(1)}\n${DateFormat('MMM d').format(date)}',
                    TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                } else {
                  final actualFreq = s.y / 5 * freqMax;
                  return LineTooltipItem(
                    '${AppLocalizations.of(context)!.intimacyFrequency}: ${actualFreq.toStringAsFixed(1)}/wk',
                    TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 11,
                    ),
                  );
                }
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _chartDateInterval(List<IntimacyRecord> data) {
    if (data.length < 2) return 1;
    final spanMs = data.last.datetime
        .difference(data.first.datetime)
        .inMilliseconds
        .toDouble();
    final spanDays = spanMs / (86400 * 1000);
    const day = 86400 * 1000.0;
    if (spanDays <= 7) return day;
    if (spanDays <= 30) return 7 * day;
    if (spanDays <= 90) return 21 * day;
    if (spanDays <= 180) return 45 * day;
    if (spanDays <= 365) return 90 * day;
    return 120 * day;
  }

  void _showManageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people),
              title: Text(AppLocalizations.of(context)!.intimacyPartners),
              trailing: Text('${_partners.length}'),
              onTap: () {
                Navigator.pop(context);
                _openPartnerManagement();
              },
            ),
            ListTile(
              leading: const Icon(Icons.toys),
              title: Text(AppLocalizations.of(context)!.intimacyToys),
              trailing: Text('${_toys.length}'),
              onTap: () {
                Navigator.pop(context);
                _openToyManagement();
              },
            ),
            ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: Text(AppLocalizations.of(context)!.intimacyPositions),
              trailing: Text('${_positions.length}'),
              onTap: () {
                Navigator.pop(context);
                _openPositionManagement();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPartnerManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PartnerManagementPage(
          partners: _partners,
          records: _records,
          toys: _toys,
          onChanged: (updated) {
            setState(() => _partners = updated);
            _saveData();
          },
        ),
      ),
    );
  }

  Future<void> _openToyManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ToyManagementPage(
          toys: _toys,
          records: _records,
          partners: _partners,
          onChanged: (updated) {
            setState(() => _toys = updated);
            _saveData();
          },
        ),
      ),
    );
  }

  Future<void> _openPositionManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PositionManagementPage(
          positions: _positions,
          records: _records,
          onChanged: (updated) {
            setState(() => _positions = updated);
            _saveData();
          },
        ),
      ),
    );
  }
}

// Simple calendar grid widget
class _CalendarWidget extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final Set<DateTime> markedDates;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime) onDateSelected;

  const _CalendarWidget({
    required this.focusedMonth,
    required this.selectedDate,
    required this.markedDates,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = focusedMonth.year;
    final month = focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onMonthChanged(
                  DateTime(year, month - 1, 1),
                ),
              ),
              Text(
                DateFormat('yyyy MMMM').format(focusedMonth),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onMonthChanged(
                  DateTime(year, month + 1, 1),
                ),
              ),
            ],
          ),
        ),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Day grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildDayGrid(context, startWeekday, daysInMonth, year, month),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDayGrid(
      BuildContext context, int startWeekday, int daysInMonth, int year, int month) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final rows = <Widget>[];
    var day = 1 - startWeekday;

    while (day <= daysInMonth) {
      final cells = <Widget>[];
      for (var i = 0; i < 7; i++) {
        if (day < 1 || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 36)));
        } else {
          final date = DateTime(year, month, day);
          final isMarked = markedDates.contains(date);
          final isSelected = selectedDate == date;
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          cells.add(Expanded(
            child: GestureDetector(
              onTap: () => onDateSelected(date),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : isMarked
                          ? theme.colorScheme.primaryContainer
                          : null,
                  border: isToday && !isSelected
                      ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : isMarked
                              ? theme.colorScheme.onPrimaryContainer
                              : null,
                      fontWeight: isMarked || isToday ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ),
            ),
          ));
        }
        day++;
      }
      rows.add(Row(children: cells));
    }
    return Column(children: rows);
  }
}

class _RecordTile extends StatelessWidget {
  final IntimacyRecord record;
  final Partner? partner;
  final List<Toy> toys;
  final List<Position> positions;

  const _RecordTile({
    required this.record,
    this.partner,
    this.toys = const [],
    this.positions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, HH:mm').format(record.datetime);
    final durationStr = '${record.duration.inMinutes}min';
    final stars =
        '★' * record.pleasureLevel + '☆' * (5 - record.pleasureLevel);

    final partnerLabel = partner != null
        ? (partner!.emoji != null ? '${partner!.emoji} ${partner!.name}' : partner!.name)
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!record.isSolo && partner?.imagePath != null)
                  FutureBuilder<File>(
                    future: ImageService.resolve(partner!.imagePath!),
                    builder: (context, snap) {
                      if (snap.hasData && snap.data!.existsSync()) {
                        return CircleAvatar(
                          radius: 12,
                          backgroundImage: FileImage(snap.data!),
                        );
                      }
                      return Icon(Icons.favorite, size: 18, color: theme.colorScheme.primary);
                    },
                  )
                else
                  Icon(
                    record.isSolo ? Icons.person : Icons.favorite,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                const SizedBox(width: 8),
                Text(
                  record.isSolo ? AppLocalizations.of(context)!.intimacySolo : partnerLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  stars,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(durationStr, style: theme.textTheme.bodySmall),
                if (record.hadOrgasm)
                  Icon(Icons.favorite, size: 14, color: theme.colorScheme.tertiary),
                if (record.watchedPorn) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.ondemand_video, size: 14, color: theme.colorScheme.onSurfaceVariant),
                ],
                if (record.location != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.location_on_outlined,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(record.location!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            if (toys.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: toys.map((t) {
                  final label = t.emoji != null ? '${t.emoji} ${t.name}' : t.name;
                  if (t.imagePath != null) {
                    return FutureBuilder<File>(
                      future: ImageService.resolve(t.imagePath!),
                      builder: (context, snap) {
                        if (snap.hasData && snap.data!.existsSync()) {
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundImage: FileImage(snap.data!),
                              radius: 12,
                            ),
                            label: Text(t.name),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }
                        return Chip(
                          label: Text(label),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      },
                    );
                  }
                  return Chip(
                    label: Text(label),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            if (positions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: positions.map((p) {
                  final label = p.emoji != null ? '${p.emoji} ${p.name}' : p.name;
                  return Chip(
                    label: Text(label),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                record.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Partner Management ─────────────────────────────────────────────
class _PartnerManagementPage extends StatefulWidget {
  final List<Partner> partners;
  final List<IntimacyRecord> records;
  final List<Toy> toys;
  final ValueChanged<List<Partner>> onChanged;

  const _PartnerManagementPage({
    required this.partners,
    required this.records,
    required this.toys,
    required this.onChanged,
  });

  @override
  State<_PartnerManagementPage> createState() =>
      _PartnerManagementPageState();
}

class _PartnerManagementPageState extends State<_PartnerManagementPage> {
  late List<Partner> _partners;

  static const _commonEmojis = [
    '👩', '👨', '👩‍🦰', '👨‍🦰', '👱‍♀️', '👱', '🧑', '👧',
    '💑', '❤️', '💕', '😍', '🥰', '💋', '🌹', '✨',
  ];

  @override
  void initState() {
    super.initState();
    _partners = List.of(widget.partners);
  }

  void _addPartner() => _showEditDialog(null);

  void _editPartner(Partner p) => _showEditDialog(p);

  void _deletePartner(Partner p) {
    setState(() => _partners.removeWhere((x) => x.id == p.id));
    widget.onChanged(_partners);
  }

  void _showPartnerRecords(Partner p) {
    final related = widget.records
        .where((r) => r.partnerId == p.id)
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FilteredRecordsPage(
          title: p.name,
          records: related,
          partners: _partners,
          toys: widget.toys,
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Partner? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? selectedEmoji = existing?.emoji;
    String? imagePath = existing?.imagePath;
    DateTime? startDate = existing?.startDate;
    DateTime? endDate = existing?.endDate;
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? l10n.intimacyAddPartner : l10n.intimacyEditPartner),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.commonName),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Text(l10n.commonEmojiOptional,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                _buildImageRow(imagePath, Theme.of(context), (path) {
                  setDialogState(() {
                    imagePath = path;
                    if (path != null) selectedEmoji = null;
                  });
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.maxFinite,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _commonEmojis.map((emoji) {
                      final isSelected = emoji == selectedEmoji;
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setDialogState(() {
                          selectedEmoji = isSelected ? null : emoji;
                          if (!isSelected) imagePath = null;
                        }),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _DatePickerTile(
                  label: l10n.intimacyStartDate,
                  date: startDate,
                  onPick: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => startDate = picked);
                  },
                  onClear: () => setDialogState(() => startDate = null),
                ),
                _DatePickerTile(
                  label: l10n.intimacyEndDate,
                  date: endDate,
                  onPick: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => endDate = picked);
                  },
                  onClear: () => setDialogState(() => endDate = null),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.commonSave)),
          ],
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        if (existing != null) {
          final idx = _partners.indexWhere((p) => p.id == existing.id);
          if (idx != -1) {
            _partners[idx] = Partner(
              id: existing.id,
              name: nameCtrl.text.trim(),
              emoji: selectedEmoji,
              imagePath: imagePath,
              startDate: startDate,
              endDate: endDate,
            );
          }
        } else {
          _partners.add(Partner(
            name: nameCtrl.text.trim(),
            emoji: selectedEmoji,
            imagePath: imagePath,
            startDate: startDate,
            endDate: endDate,
          ));
        }
      });
      widget.onChanged(_partners);
    }
  }

  Widget _buildImageRow(String? imagePath, ThemeData theme, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        if (imagePath != null)
          FutureBuilder<File>(
            future: ImageService.resolve(imagePath),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(snap.data!, width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => onChanged(null),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 12, color: theme.colorScheme.onError),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        if (imagePath != null) const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.image_outlined, size: 16),
          label: Text(imagePath != null ? AppLocalizations.of(context)!.commonChange : AppLocalizations.of(context)!.commonPickImage),
          onPressed: () async {
            final path = await ImageService.pickAndSaveImage();
            if (path != null) onChanged(path);
          },
        ),
      ],
    );
  }

  String _partnerSubtitle(Partner p, int recordCount) {
    final parts = <String>[
      AppLocalizations.of(context)!.intimacyRecordCount(recordCount),
    ];
    if (p.startDate != null || p.endDate != null) {
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final start = p.startDate != null ? fmt(p.startDate!) : '?';
      final end = p.endDate != null ? fmt(p.endDate!) : '';
      parts.add(end.isEmpty ? '$start ~' : '$start ~ $end');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.intimacyPartners),
        centerTitle: true,
      ),
      body: _partners.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.intimacyNoPartners))
          : ListView.builder(
              itemCount: _partners.length,
              itemBuilder: (context, index) {
                final p = _partners[index];
                final recordCount = widget.records
                    .where((r) => r.partnerId == p.id)
                    .length;
                return Dismissible(
                  key: ValueKey(p.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    color: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.edit_outlined,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.error,
                    child: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onError),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _editPartner(p);
                      return false;
                    }
                    return confirmDelete(context, p.name);
                  },
                  onDismissed: (_) => _deletePartner(p),
                  child: ListTile(
                    leading: _buildPartnerAvatar(p),
                    title: Text(p.name),
                    subtitle: Text(_partnerSubtitle(p, recordCount)),
                    onTap: () => _showPartnerRecords(p),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPartner,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPartnerAvatar(Partner p) {
    if (p.imagePath != null) {
      return FutureBuilder<File>(
        future: ImageService.resolve(p.imagePath!),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.existsSync()) {
            return CircleAvatar(backgroundImage: FileImage(snap.data!));
          }
          return CircleAvatar(child: Text(p.emoji ?? p.name[0]));
        },
      );
    }
    return CircleAvatar(child: Text(p.emoji ?? p.name[0]));
  }
}

// ─── Toy Management ─────────────────────────────────────────────────
class _ToyManagementPage extends StatefulWidget {
  final List<Toy> toys;
  final List<IntimacyRecord> records;
  final List<Partner> partners;
  final ValueChanged<List<Toy>> onChanged;

  const _ToyManagementPage({
    required this.toys,
    required this.records,
    required this.partners,
    required this.onChanged,
  });

  @override
  State<_ToyManagementPage> createState() => _ToyManagementPageState();
}

class _ToyManagementPageState extends State<_ToyManagementPage> {
  late List<Toy> _toys;

  static const _commonEmojis = [
    '🎀', '🧸', '💎', '🔮', '🎯', '🪄', '🌡️', '💫',
    '🎁', '🦋', '🌸', '🍭', '⭐', '🔥', '💜', '✨',
  ];

  @override
  void initState() {
    super.initState();
    _toys = List.of(widget.toys);
  }

  void _addToy() => _showEditDialog(null);

  void _editToy(Toy t) => _showEditDialog(t);

  void _deleteToy(Toy t) {
    setState(() => _toys.removeWhere((x) => x.id == t.id));
    widget.onChanged(_toys);
  }

  void _showToyRecords(Toy t) {
    final related = widget.records
        .where((r) => r.toyIds.contains(t.id))
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FilteredRecordsPage(
          title: t.name,
          records: related,
          partners: widget.partners,
          toys: _toys,
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Toy? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final linkCtrl = TextEditingController(text: existing?.purchaseLink ?? '');
    final priceCtrl = TextEditingController(
      text: existing?.price != null ? existing!.price!.toString() : '',
    );
    String? selectedEmoji = existing?.emoji;
    String? imagePath = existing?.imagePath;
    DateTime? purchaseDate = existing?.purchaseDate;
    DateTime? retiredDate = existing?.retiredDate;
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? l10n.intimacyAddToy : l10n.intimacyEditToy),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.commonName),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Text(l10n.commonEmojiOptional,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                _buildImageRow(imagePath, Theme.of(context), (path) {
                  setDialogState(() {
                    imagePath = path;
                    if (path != null) selectedEmoji = null;
                  });
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.maxFinite,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _commonEmojis.map((emoji) {
                      final isSelected = emoji == selectedEmoji;
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setDialogState(() {
                          selectedEmoji = isSelected ? null : emoji;
                          if (!isSelected) imagePath = null;
                        }),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _DatePickerTile(
                  label: l10n.intimacyPurchaseDate,
                  date: purchaseDate,
                  onPick: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: purchaseDate ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => purchaseDate = picked);
                  },
                  onClear: () => setDialogState(() => purchaseDate = null),
                ),
                _DatePickerTile(
                  label: l10n.intimacyRetiredDate,
                  date: retiredDate,
                  onPick: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: retiredDate ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => retiredDate = picked);
                  },
                  onClear: () => setDialogState(() => retiredDate = null),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.intimacyPurchaseLink,
                    prefixIcon: const Icon(Icons.link, size: 20),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.intimacyPrice,
                    prefixIcon: const Icon(Icons.attach_money, size: 20),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.commonSave)),
          ],
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final link = linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim());
      setState(() {
        if (existing != null) {
          final idx = _toys.indexWhere((t) => t.id == existing.id);
          if (idx != -1) {
            _toys[idx] = Toy(
              id: existing.id,
              name: nameCtrl.text.trim(),
              emoji: selectedEmoji,
              imagePath: imagePath,
              purchaseDate: purchaseDate,
              retiredDate: retiredDate,
              purchaseLink: link,
              price: price,
            );
          }
        } else {
          _toys.add(Toy(
            name: nameCtrl.text.trim(),
            emoji: selectedEmoji,
            imagePath: imagePath,
            purchaseDate: purchaseDate,
            retiredDate: retiredDate,
            purchaseLink: link,
            price: price,
          ));
        }
      });
      widget.onChanged(_toys);
    }
  }

  Widget _buildImageRow(String? imagePath, ThemeData theme, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        if (imagePath != null)
          FutureBuilder<File>(
            future: ImageService.resolve(imagePath),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(snap.data!, width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => onChanged(null),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 12, color: theme.colorScheme.onError),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        if (imagePath != null) const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.image_outlined, size: 16),
          label: Text(imagePath != null ? AppLocalizations.of(context)!.commonChange : AppLocalizations.of(context)!.commonPickImage),
          onPressed: () async {
            final path = await ImageService.pickAndSaveImage();
            if (path != null) onChanged(path);
          },
        ),
      ],
    );
  }

  String _toySubtitle(Toy t, int recordCount) {
    final parts = <String>[
      AppLocalizations.of(context)!.intimacyRecordCount(recordCount),
    ];
    if (t.purchaseDate != null) {
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      parts.add(fmt(t.purchaseDate!));
    }
    if (t.retiredDate != null) {
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      parts.add('⊘ ${fmt(t.retiredDate!)}');
    }
    if (t.price != null) {
      parts.add('\$${t.price!.toStringAsFixed(2)}');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.intimacyToys),
        centerTitle: true,
      ),
      body: _toys.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.intimacyNoToys))
          : ListView.builder(
              itemCount: _toys.length,
              itemBuilder: (context, index) {
                final t = _toys[index];
                final recordCount = widget.records
                    .where((r) => r.toyIds.contains(t.id))
                    .length;
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    color: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.edit_outlined,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.error,
                    child: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onError),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _editToy(t);
                      return false;
                    }
                    return confirmDelete(context, t.name);
                  },
                  onDismissed: (_) => _deleteToy(t),
                  child: ListTile(
                    leading: _buildToyAvatar(t),
                    title: Text(t.name),
                    subtitle: Text(_toySubtitle(t, recordCount)),
                    onTap: () => _showToyRecords(t),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addToy,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildToyAvatar(Toy t) {
    if (t.imagePath != null) {
      return FutureBuilder<File>(
        future: ImageService.resolve(t.imagePath!),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.existsSync()) {
            return CircleAvatar(backgroundImage: FileImage(snap.data!));
          }
          return CircleAvatar(child: Text(t.emoji ?? t.name[0]));
        },
      );
    }
    return CircleAvatar(child: Text(t.emoji ?? t.name[0]));
  }
}

// ─── Position Management ────────────────────────────────────────────
class _PositionManagementPage extends StatefulWidget {
  final List<Position> positions;
  final List<IntimacyRecord> records;
  final ValueChanged<List<Position>> onChanged;

  const _PositionManagementPage({
    required this.positions,
    required this.records,
    required this.onChanged,
  });

  @override
  State<_PositionManagementPage> createState() =>
      _PositionManagementPageState();
}

class _PositionManagementPageState extends State<_PositionManagementPage> {
  late List<Position> _positions;

  static const _commonEmojis = [
    '🔝', '🔄', '🐕', '🪑', '🦋', '🌙', '🌟', '💫',
    '🔀', '🎯', '🧘', '🤸', '🏋️', '🧗', '💃', '✨',
  ];

  @override
  void initState() {
    super.initState();
    _positions = List.of(widget.positions);
  }

  void _addPosition() => _showEditDialog(null);

  void _editPosition(Position p) => _showEditDialog(p);

  void _deletePosition(Position p) {
    setState(() => _positions.removeWhere((x) => x.id == p.id));
    widget.onChanged(_positions);
  }

  void _importDefaults() {
    final l10n = AppLocalizations.of(context)!;
    final defaultPositions = [
      {'name': l10n.positionMissionary, 'emoji': '🔝'},
      {'name': l10n.positionCowgirl, 'emoji': '🤠'},
      {'name': l10n.positionDoggyStyle, 'emoji': '🐕'},
      {'name': l10n.positionReverseCowgirl, 'emoji': '🔄'},
      {'name': l10n.positionSpooning, 'emoji': '🌙'},
      {'name': l10n.positionStanding, 'emoji': '🧗'},
      {'name': l10n.position69, 'emoji': '🔀'},
      {'name': l10n.positionLotus, 'emoji': '🧘'},
      {'name': l10n.positionProneBone, 'emoji': '🦋'},
    ];
    final existingNames = _positions.map((p) => p.name.toLowerCase()).toSet();
    var added = 0;
    for (final preset in defaultPositions) {
      if (!existingNames.contains((preset['name'] as String).toLowerCase())) {
        _positions.add(Position(
          name: preset['name'] as String,
          emoji: preset['emoji'] as String,
        ));
        added++;
      }
    }
    if (added > 0) {
      setState(() {});
      widget.onChanged(_positions);
    }
  }

  Future<void> _showEditDialog(Position? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? selectedEmoji = existing?.emoji;
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null
              ? l10n.intimacyAddPosition
              : l10n.intimacyEditPosition),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: l10n.commonName),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Text(l10n.commonEmojiOptional,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.maxFinite,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _commonEmojis.map((emoji) {
                      final isSelected = emoji == selectedEmoji;
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setDialogState(() {
                          selectedEmoji = isSelected ? null : emoji;
                        }),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : null,
                            border: isSelected
                                ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.commonSave)),
          ],
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        if (existing != null) {
          final idx = _positions.indexWhere((p) => p.id == existing.id);
          if (idx != -1) {
            _positions[idx] = Position(
              id: existing.id,
              name: nameCtrl.text.trim(),
              emoji: selectedEmoji,
            );
          }
        } else {
          _positions.add(Position(
            name: nameCtrl.text.trim(),
            emoji: selectedEmoji,
          ));
        }
      });
      widget.onChanged(_positions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.intimacyPositions),
        centerTitle: true,
        actions: [
          if (_positions.isEmpty)
            TextButton(
              onPressed: _importDefaults,
              child: Text(l10n.intimacyImportDefaults),
            )
          else
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'import') _importDefaults();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'import',
                  child: Text(l10n.intimacyImportDefaults),
                ),
              ],
            ),
        ],
      ),
      body: _positions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.intimacyNoPositions),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _importDefaults,
                    icon: const Icon(Icons.download),
                    label: Text(l10n.intimacyImportDefaults),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _positions.length,
              itemBuilder: (context, index) {
                final p = _positions[index];
                final recordCount = widget.records
                    .where((r) => r.positionIds.contains(p.id))
                    .length;
                return Dismissible(
                  key: ValueKey(p.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    color: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.edit_outlined,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.error,
                    child: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onError),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _editPosition(p);
                      return false;
                    }
                    return confirmDelete(context, p.name);
                  },
                  onDismissed: (_) => _deletePosition(p),
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Text(p.emoji ?? p.name[0])),
                    title: Text(p.name),
                    subtitle: Text(l10n.intimacyRecordCount(recordCount)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPosition,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Filtered Records (by partner or toy) ───────────────────────────
class _FilteredRecordsPage extends StatelessWidget {
  final String title;
  final List<IntimacyRecord> records;
  final List<Partner> partners;
  final List<Toy> toys;

  const _FilteredRecordsPage({
    required this.title,
    required this.records,
    required this.partners,
    required this.toys,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: records.isEmpty
          ? Center(child: Text(l10n.intimacyNoRecords))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final partner = record.partnerId != null
                    ? partners
                        .where((p) => p.id == record.partnerId)
                        .firstOrNull
                    : null;
                final recordToys = record.toyIds
                    .map((id) => toys.where((t) => t.id == id).firstOrNull)
                    .whereType<Toy>()
                    .toList();
                return _RecordTile(
                  record: record,
                  partner: partner,
                  toys: recordToys,
                );
              },
            ),
    );
  }
}

// ─── Shared date picker tile ────────────────────────────────────────
class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        date != null ? Icons.event_available : Icons.event_outlined,
        size: 20,
        color: date != null ? theme.colorScheme.primary : null,
      ),
      title: Text(
        date != null
            ? '$label: ${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
            : label,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: date != null
          ? IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          : null,
      onTap: onPick,
    );
  }
}

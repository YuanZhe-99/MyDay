import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/services/auto_sync_service.dart';
import '../../../shared/services/image_service.dart';
import '../../../shared/utils/week_grouping.dart';
import '../../../shared/widgets/app_date_picker.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../../../shared/widgets/unsaved_changes_guard.dart';
import '../models/intimacy_record.dart';
import '../services/cycle_predictor.dart';
import '../services/intimacy_storage.dart';
import '../widgets/add_record_dialog.dart';
import '../widgets/body_section.dart';
import '../widgets/cycle_calendar.dart';
import '../widgets/timer_page.dart';
import 'body_page.dart';

enum _SortMode { dateDesc, dateAsc, pleasureDesc, durationDesc }

enum _FilterMode { all, solo, partnered, orgasm, noOrgasm }

enum _IntimacyChartRange {
  oneWeek,
  oneMonth,
  threeMonths,
  sixMonths,
  oneYear,
  all,
}

enum _ToyCostScope { all, active, retired }

const Color _intimacyFrequencyChartColor = Color(0xFF00796B);
const Color _intimacyDurationChartColor = Color(0xFFF57C00);
const Color _intimacyThrustChartColor = Color(0xFF8E24AA);

/// Purpose: Return a record's estimated thrust count in actual repetitions.
/// Inputs: `record`.
/// Returns: `double?`.
/// Side effects: None.
/// Notes: The stored value is multiplied by the user-selected x1 or x100 unit.
double? _recordThrustCount(IntimacyRecord record) {
  final count = record.thrustCount;
  if (count == null || count <= 0) return null;
  return count * record.thrustCountUnit.toDouble();
}

/// Purpose: Build EWMA smoothed thrust-count spots for a trend chart.
/// Inputs: `allData`, `visibleFrom`, `halfLifeDays`.
/// Returns: `List<FlSpot>`.
/// Side effects: None.
/// Notes: Uses earlier records for warm-up but only emits visible-range spots.
List<FlSpot> _buildEwmaThrustCountSpots(
  List<IntimacyRecord> allData,
  DateTime visibleFrom, {
  double halfLifeDays = 7,
}) {
  final validData = allData
      .where((record) => _recordThrustCount(record) != null)
      .toList();
  if (validData.isEmpty) return [];
  final tau = halfLifeDays * 86400 * 1000;
  final spots = <FlSpot>[];
  double ewma = _recordThrustCount(validData.first)!;
  DateTime prevTime = validData.first.datetime;

  for (final record in validData) {
    final dtMs = record.datetime.difference(prevTime).inMilliseconds.toDouble();
    final alpha = 1.0 - math.exp(-dtMs / tau);
    final count = _recordThrustCount(record)!;
    ewma = alpha * count + (1 - alpha) * ewma;
    if (!record.datetime.isBefore(visibleFrom)) {
      spots.add(
        FlSpot(record.datetime.millisecondsSinceEpoch.toDouble(), ewma),
      );
    }
    prevTime = record.datetime;
  }
  return spots;
}

class IntimacyPage extends ConsumerStatefulWidget {
  /// Purpose: Create an intimacy page instance.
  /// Inputs: None.
  /// Returns: A new `IntimacyPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const IntimacyPage({super.key});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  ConsumerState<IntimacyPage> createState() => _IntimacyPageState();
}

class _IntimacyPageState extends ConsumerState<IntimacyPage> {
  static const _defaultVisibleRecordCount = 20;

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  List<Partner> _partners = [];
  List<Toy> _toys = [];
  List<Position> _positions = [];
  List<IntimacyRecord> _records = [];
  List<TimerHistoryEntry> _timerHistory = [];
  IntimacyTimerSession? _timerSession;
  DateTime _timerSessionModifiedAt = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );
  BodyProfile? _userBody;
  DateTime _userBodyModifiedAt = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );
  List<CycleRecord> _cycleRecords = [];
  int? _timerHistoryRetentionDays;
  Map<String, String> _partnerSortModes = {};
  Map<String, List<String>> _partnerCustomOrders = {};
  Map<String, String> _toySortModes = {};
  Map<String, List<String>> _toyCustomOrders = {};
  DateTime _settingsModifiedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _loaded = false;
  String? _loadError;

  _SortMode _sortMode = _SortMode.dateDesc;
  _FilterMode _filterMode = _FilterMode.all;
  _IntimacyChartRange _chartRange = _IntimacyChartRange.threeMonths;
  final bool _showChart = true;

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
  /// Notes: Existing but unreadable intimacy data is shown as an error and is
  /// never treated as an empty dataset. Reloads disable writes until complete.
  Future<void> _loadData() async {
    if (_loaded && mounted) setState(() => _loaded = false);
    IntimacyData? data;
    try {
      data = await IntimacyStorage.load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loaded = true;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _loadError = null;
      if (data != null) {
        _partners = data.partners;
        _toys = data.toys;
        _positions = data.positions;
        _records = data.records;
        _timerHistory = data.timerHistory;
        _timerSession = data.timerSession;
        _timerSessionModifiedAt = data.timerSessionModifiedAt;
        _userBody = data.userBody;
        _userBodyModifiedAt = data.userBodyModifiedAt;
        _cycleRecords = List<CycleRecord>.of(data.cycleRecords);
        _timerHistoryRetentionDays = data.timerHistoryRetentionDays;
        _partnerSortModes = Map.of(data.partnerSortModes);
        _partnerCustomOrders = data.partnerCustomOrders.map(
          (key, value) => MapEntry(key, List<String>.of(value)),
        );
        _toySortModes = Map.of(data.toySortModes);
        _toyCustomOrders = data.toyCustomOrders.map(
          (key, value) => MapEntry(key, List<String>.of(value)),
        );
        _settingsModifiedAt = data.settingsModifiedAt;
      }
      _loaded = true;
    });
  }

  /// Purpose: Provide the internal save data helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Refuses to save while loading or while the intimacy file is
  /// unreadable so incomplete in-memory state cannot overwrite it.
  Future<void> _saveData() async {
    if (!_loaded) return;
    if (_loadError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.intimacyDataWriteBlocked,
            ),
          ),
        );
      }
      return;
    }
    await IntimacyStorage.save(
      IntimacyData(
        partners: _partners,
        toys: _toys,
        positions: _positions,
        records: _records,
        timerHistory: _timerHistory,
        timerSession: _timerSession,
        timerSessionModifiedAt: _timerSessionModifiedAt,
        userBody: _userBody,
        userBodyModifiedAt: _userBodyModifiedAt,
        cycleRecords: _cycleRecords,
        timerHistoryRetentionDays: _timerHistoryRetentionDays,
        partnerSortModes: _partnerSortModes,
        partnerCustomOrders: _partnerCustomOrders,
        toySortModes: _toySortModes,
        toyCustomOrders: _toyCustomOrders,
        settingsModifiedAt: _settingsModifiedAt,
      ),
    );
    AutoSyncService.instance.notifySaved();
  }

  /// Purpose: Persist timer page changes while the timer page is still open.
  /// Inputs: Timer history/session values plus change flags from `TimerPage`.
  /// Returns: `Future<void>`.
  /// Side effects: Updates page state, writes intimacy data, and notifies auto-sync.
  /// Notes: Timer session timestamps are separate from general settings timestamps.
  Future<void> _saveTimerState({
    required List<TimerHistoryEntry> history,
    required IntimacyTimerSession? session,
    required bool historyChanged,
    required bool timerSessionChanged,
    required int? retentionDays,
    required bool retentionChanged,
  }) async {
    setState(() {
      _timerHistory = List<TimerHistoryEntry>.of(history);
      _timerSession = session;
      _timerHistoryRetentionDays = retentionDays;
      if (timerSessionChanged) {
        _timerSessionModifiedAt = DateTime.now().toUtc();
      }
      if (retentionChanged) {
        _settingsModifiedAt = DateTime.now().toUtc();
      }
    });
    if (historyChanged || timerSessionChanged || retentionChanged) {
      await _saveData();
    }
  }

  /// Purpose: Return marked dates.
  /// Inputs: None.
  /// Returns: `Set<DateTime>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Set<DateTime> get _markedDates {
    return _records
        .map((r) => DateTime(r.datetime.year, r.datetime.month, r.datetime.day))
        .toSet();
  }

  /// Purpose: Build cycle overlays for everyone shown on the home calendar.
  /// Inputs: `l10n` for the user's display label.
  /// Returns: `List<PersonCycleOverlay>`.
  /// Side effects: None.
  /// Notes: Only people with both cycle tracking and the show-on-calendar
  /// option enabled appear; colors stay stable per person.
  List<PersonCycleOverlay> _buildCycleOverlays(AppLocalizations l10n) {
    final overlays = <PersonCycleOverlay>[];
    final allPartnerIds = _partners.map((p) => p.id).toList()..sort();
    final windowStart = DateTime(
      _focusedMonth.year,
      _focusedMonth.month - 1,
      1,
    );
    final windowEnd = DateTime(_focusedMonth.year, _focusedMonth.month + 2, 0);

    CyclePrediction predictionFor(String? personId) => predictCycle(
      actualStarts: _cycleRecords
          .where((c) => c.personId == personId)
          .map((c) => c.day),
      windowStart: windowStart,
      windowEnd: windowEnd,
    );

    final userBody = _userBody;
    if (userBody != null &&
        userBody.cycleEnabled &&
        userBody.showCycleOnCalendar) {
      overlays.add(
        PersonCycleOverlay(
          personKey: 'user',
          displayName: l10n.intimacyCycleMe,
          color: cyclePersonColor(
            personId: null,
            allPartnerIdsSorted: const [],
          ),
          prediction: predictionFor(null),
        ),
      );
    }
    for (final partner in _partners) {
      final body = partner.body;
      if (body == null || !body.cycleEnabled || !body.showCycleOnCalendar) {
        continue;
      }
      overlays.add(
        PersonCycleOverlay(
          personKey: partner.id,
          displayName: partner.name,
          color: cyclePersonColor(
            personId: partner.id,
            allPartnerIdsSorted: allPartnerIds,
          ),
          prediction: predictionFor(partner.id),
        ),
      );
    }
    return overlays;
  }

  /// Purpose: Build the legend and selected-day cycle strip for the home calendar.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `List<Widget>` empty when no overlays are visible.
  /// Side effects: None.
  /// Notes: The selected-day strip names each person so it is always clear
  /// whose cycle information is shown; all derived values read as estimates.
  List<Widget> _buildCycleCalendarExtras(
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final overlays = _buildCycleOverlays(l10n);
    if (overlays.isEmpty) return const [];
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: CycleLegend(people: overlays),
      ),
    ];
    final selected = _selectedDate;
    if (selected != null) {
      final lines = <String>[];
      for (final overlay in overlays) {
        final info = overlay.prediction.days[selected];
        if (info == null) continue;
        final parts = <String>[];
        if (info.isActualStart) {
          parts.add(l10n.intimacyCycleActualStart);
        } else if (info.isPredictedStart) {
          parts.add(l10n.intimacyCyclePredictedStart);
        }
        parts.add(switch (info.phase) {
          CyclePhase.menstrual => l10n.intimacyCyclePhaseMenstrual,
          CyclePhase.follicular => l10n.intimacyCyclePhaseFollicular,
          CyclePhase.luteal => l10n.intimacyCyclePhaseLuteal,
        });
        if (info.isOvulationDay) parts.add(l10n.intimacyCycleOvulation);
        if (info.inFertileWindow) parts.add(l10n.intimacyCycleFertileWindow);
        final suffix = info.isEstimated
            ? ' ${l10n.intimacyCycleEstimatedSuffix}'
            : '';
        lines.add('${overlay.displayName}: ${parts.join(' · ')}$suffix');
      }
      if (lines.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              lines.join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  /// Purpose: Return filtered records.
  /// Inputs: None.
  /// Returns: `List<IntimacyRecord>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
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

  /// Purpose: Provide the internal add record helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _addRecord() async {
    final activePartners = _partners.where((p) => p.endDate == null).toList();
    final activeToys = _toys.where((t) => t.retiredDate == null).toList();
    final record = await showDialog<IntimacyRecord>(
      context: context,
      builder: (_) => AddRecordDialog(
        partners: activePartners,
        toys: activeToys,
        positions: _positions,
      ),
    );
    if (record != null) {
      setState(() => _records.insert(0, record));
      await _saveData();
    }
  }

  /// Purpose: Provide the internal delete record helper for this file.
  /// Inputs: `record`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _deleteRecord(IntimacyRecord record) {
    setState(() => _records.removeWhere((r) => r.id == record.id));
    _saveData();
  }

  /// Purpose: Provide the internal edit record helper for this file.
  /// Inputs: `record`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _editRecord(IntimacyRecord record) async {
    final activePartners = _partners.where((p) => p.endDate == null).toList();
    final activeToys = _toys.where((t) => t.retiredDate == null).toList();
    final updated = await showDialog<IntimacyRecord>(
      context: context,
      builder: (_) => AddRecordDialog(
        record: record,
        partners: activePartners,
        toys: activeToys,
        positions: _positions,
      ),
    );
    if (updated != null) {
      setState(() {
        final index = _records.indexWhere((r) => r.id == updated.id);
        if (index != -1) _records[index] = updated;
      });
      await _saveData();
    }
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Shows a blocking recovery view while intimacy data is unreadable.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    final filteredRecords = _filteredRecords;
    final visibleRecords = _selectedDate == null
        ? filteredRecords.take(_defaultVisibleRecordCount).toList()
        : filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.intimacyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: l10n.intimacyTimer,
            onPressed: _loaded && _loadError == null
                ? () async {
                    final result = await Navigator.push<TimerPageResult>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TimerPage(
                          partners: _partners
                              .where((p) => p.endDate == null)
                              .toList(),
                          toys: _toys
                              .where((t) => t.retiredDate == null)
                              .toList(),
                          positions: _positions,
                          timerHistory: _timerHistory,
                          timerSession: _timerSession,
                          timerHistoryRetentionDays: _timerHistoryRetentionDays,
                          onStateChanged: _saveTimerState,
                        ),
                      ),
                    );
                    if (result != null) {
                      bool needSave = false;
                      if (result.record != null) {
                        setState(() => _records.insert(0, result.record!));
                        needSave = true;
                      }
                      if (result.updatedHistory != null &&
                          result.historyChanged) {
                        setState(() => _timerHistory = result.updatedHistory!);
                        needSave = true;
                      }
                      if (result.timerSessionChanged) {
                        setState(() {
                          _timerSession = result.updatedTimerSession;
                          _timerSessionModifiedAt = DateTime.now().toUtc();
                        });
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
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.intimacyManage,
            onPressed: _loaded && _loadError == null
                ? () => _showManageMenu(context)
                : null,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _IntimacyDataError(message: _loadError!, onRetry: _loadData)
          : ListView(
              children: [
                // Calendar
                _CalendarWidget(
                  focusedMonth: _focusedMonth,
                  selectedDate: _selectedDate,
                  markedDates: _markedDates,
                  weekStartDay: settings.weekStartDay,
                  onMonthChanged: (month) {
                    setState(() => _focusedMonth = month);
                  },
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = _selectedDate == date
                          ? null
                          : date; // toggle
                    });
                  },
                  cycleOverlays: _buildCycleOverlays(l10n),
                ),
                ..._buildCycleCalendarExtras(theme, l10n),
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
                            ? DateFormat(
                                'MMM d',
                                l10n.localeName,
                              ).format(_selectedDate!)
                            : l10n.intimacyAllRecords,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() => _selectedDate = null),
                          child: Text(l10n.intimacyShowAll),
                        ),
                      ],
                    ],
                  ),
                ),

                // Sort & filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      _buildSortChip(context),
                      const SizedBox(width: 6),
                      _buildFilterChip(context),
                    ],
                  ),
                ),

                // Records list (inline, no nested ListView)
                if (filteredRecords.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        l10n.intimacyNoRecords,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else ...[
                  ..._buildRecordListWidgets(
                    theme,
                    visibleRecords,
                    settings.weekStartDay,
                  ),
                  if (_selectedDate == null &&
                      filteredRecords.length > _defaultVisibleRecordCount)
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            _showAllRecords(context, settings.weekStartDay),
                        child: Text(l10n.intimacyShowAllRecords),
                      ),
                    ),
                ],

                // FAB clearance
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loaded && _loadError == null ? _addRecord : null,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Purpose: Show the complete filtered intimacy record list.
  /// Inputs: `context` and `weekStartDay`.
  /// Returns: None.
  /// Side effects: Opens a bottom sheet and may trigger record edit/delete flows from its rows.
  /// Notes: Used only for the default no-date view so the page itself stays lightweight.
  void _showAllRecords(BuildContext context, int weekStartDay) {
    final theme = Theme.of(context);
    final records = _filteredRecords;
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
          children: _buildRecordListWidgets(theme, records, weekStartDay),
        ),
      ),
    );
  }

  /// Purpose: Provide the internal build record list widgets helper for this file.
  /// Inputs: `theme`, `records`, and `weekStartDay`.
  /// Returns: `List<Widget>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<Widget> _buildRecordListWidgets(
    ThemeData theme,
    List<IntimacyRecord> records,
    int weekStartDay,
  ) {
    if (_selectedDate != null) {
      return records.map(_buildRecordDismissible).toList();
    }

    final groups = groupByWeek(
      records,
      (record) => record.datetime,
      descending: _sortMode != _SortMode.dateAsc,
      weekStartDay: weekStartDay,
    );
    return [
      for (final group in groups) ...[
        _buildWeekHeader(theme, group),
        ...group.items.map(_buildRecordDismissible),
      ],
    ];
  }

  /// Purpose: Provide the internal build week header helper for this file.
  /// Inputs: `theme`, `group`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildWeekHeader(ThemeData theme, WeekGroup<IntimacyRecord> group) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
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

  /// Purpose: Provide the internal build record dismissible helper for this file.
  /// Inputs: `record`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildRecordDismissible(IntimacyRecord record) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: theme.colorScheme.primary,
        child: Icon(Icons.edit_outlined, color: theme.colorScheme.onPrimary),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editRecord(record);
          return false;
        }
        return confirmDelete(
          context,
          AppLocalizations.of(context)!.commonThisRecord,
        );
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
  }

  /// Purpose: Provide the internal build sort chip helper for this file.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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

  /// Purpose: Provide the internal build filter chip helper for this file.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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

  /// Purpose: Return chart records.
  /// Inputs: None.
  /// Returns: `List<IntimacyRecord>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<IntimacyRecord> get _chartRecords {
    final now = DateTime.now();
    final cutoff = switch (_chartRange) {
      _IntimacyChartRange.oneWeek => now.subtract(const Duration(days: 7)),
      _IntimacyChartRange.oneMonth => DateTime(
        now.year,
        now.month - 1,
        now.day,
      ),
      _IntimacyChartRange.threeMonths => DateTime(
        now.year,
        now.month - 3,
        now.day,
      ),
      _IntimacyChartRange.sixMonths => DateTime(
        now.year,
        now.month - 6,
        now.day,
      ),
      _IntimacyChartRange.oneYear => DateTime(now.year - 1, now.month, now.day),
      _IntimacyChartRange.all => DateTime(2000),
    };
    return _records.where((r) => r.datetime.isAfter(cutoff)).toList()
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
  }

  /// Build EWMA smoothed curve for duration (in minutes).
  /// Processes [allData] for warm-up but only emits spots at/after [visibleFrom].
  /// Purpose: Provide the internal build ewma duration spots helper for this file.
  /// Inputs: `allData`, `visibleFrom`, `halfLifeDays`.
  /// Returns: `List<FlSpot>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<FlSpot> _buildEwmaDurationSpots(
    List<IntimacyRecord> allData,
    DateTime visibleFrom, {
    double halfLifeDays = 7,
  }) {
    final validData = allData
        .where((record) => record.duration.inSeconds > 0)
        .toList();
    if (validData.isEmpty) return [];
    final tau = halfLifeDays * 86400 * 1000;
    final spots = <FlSpot>[];
    final firstMin = validData.first.duration.inSeconds / 60.0;
    double ewma = firstMin;
    DateTime prevTime = validData.first.datetime;

    for (final r in validData) {
      final dtMs = r.datetime.difference(prevTime).inMilliseconds.toDouble();
      final alpha = 1.0 - math.exp(-dtMs / tau);
      final durationMin = r.duration.inSeconds / 60.0;
      ewma = alpha * durationMin + (1 - alpha) * ewma;
      if (!r.datetime.isBefore(visibleFrom)) {
        spots.add(FlSpot(r.datetime.millisecondsSinceEpoch.toDouble(), ewma));
      }
      prevTime = r.datetime;
    }
    return spots;
  }

  /// Build raw frequency spots — records per week using a 7-day rolling window.
  /// For each record, counts records within the preceding 7 days (inclusive).
  /// Processes [allData] but only emits spots at/after [visibleFrom].
  /// Purpose: Provide the internal build raw frequency spots helper for this file.
  /// Inputs: `allData`, `visibleFrom`.
  /// Returns: `List<FlSpot>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<FlSpot> _buildRawFrequencySpots(
    List<IntimacyRecord> allData,
    DateTime visibleFrom,
  ) {
    if (allData.isEmpty) return [];
    const windowMs = 7 * 86400 * 1000;
    final spots = <FlSpot>[];
    for (int i = 0; i < allData.length; i++) {
      final r = allData[i];
      final tMs = r.datetime.millisecondsSinceEpoch;
      int count = 0;
      for (int j = i; j >= 0; j--) {
        if (tMs - allData[j].datetime.millisecondsSinceEpoch <= windowMs) {
          count++;
        } else {
          break;
        }
      }
      if (!r.datetime.isBefore(visibleFrom)) {
        spots.add(FlSpot(tMs.toDouble(), count.toDouble()));
      }
    }
    return spots;
  }

  /// Build EWMA smoothed curve for pleasure level.
  /// Uses adaptive alpha based on time gap with half-life of [halfLifeDays].
  /// Processes [allData] for warm-up but only emits spots at/after [visibleFrom].
  /// Purpose: Provide the internal build ewma pleasure spots helper for this file.
  /// Inputs: `allData`, `visibleFrom`, `halfLifeDays`.
  /// Returns: `List<FlSpot>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<FlSpot> _buildEwmaPleasureSpots(
    List<IntimacyRecord> allData,
    DateTime visibleFrom, {
    double halfLifeDays = 7,
  }) {
    final validData = allData
        .where((record) => record.pleasureLevel > 0)
        .toList();
    if (validData.isEmpty) return [];
    final tau = halfLifeDays * 86400 * 1000; // half-life in ms
    final spots = <FlSpot>[];
    double ewma = validData.first.pleasureLevel.toDouble();
    DateTime prevTime = validData.first.datetime;

    for (final r in validData) {
      final dtMs = r.datetime.difference(prevTime).inMilliseconds.toDouble();
      final alpha = 1.0 - math.exp(-dtMs / tau);
      ewma = alpha * r.pleasureLevel + (1 - alpha) * ewma;
      if (!r.datetime.isBefore(visibleFrom)) {
        spots.add(FlSpot(r.datetime.millisecondsSinceEpoch.toDouble(), ewma));
      }
      prevTime = r.datetime;
    }
    return spots;
  }

  /// Build EWMA smoothed curve for frequency (records per week).
  /// Processes [allData] for warm-up but only emits spots at/after [visibleFrom].
  /// Purpose: Provide the internal build ewma frequency spots helper for this file.
  /// Inputs: `allData`, `visibleFrom`, `halfLifeDays`.
  /// Returns: `List<FlSpot>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
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
        spots.add(FlSpot(r.datetime.millisecondsSinceEpoch.toDouble(), ewma));
      }
      prevTime = r.datetime;
    }
    return spots;
  }

  /// Purpose: Provide the internal build chart section helper for this file.
  /// Inputs: `theme`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Uses high-contrast fixed colors for combined trend series.
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
    final pleasureData = data
        .where((record) => record.pleasureLevel > 0)
        .toList();
    final durationData = data
        .where((record) => record.duration.inSeconds > 0)
        .toList();
    final thrustData = data
        .where((record) => _recordThrustCount(record) != null)
        .toList();
    final cutoff = data.isNotEmpty ? data.first.datetime : DateTime.now();
    final pleasureSpots = _buildEwmaPleasureSpots(allSorted, cutoff);
    final frequencySpots = _buildEwmaFrequencySpots(allSorted, cutoff);
    final durationSpots = _buildEwmaDurationSpots(allSorted, cutoff);
    final thrustSpots = _buildEwmaThrustCountSpots(allSorted, cutoff);
    // Raw (actual) spots — no EWMA smoothing
    final rawPleasureSpots = pleasureData
        .map(
          (r) => FlSpot(
            r.datetime.millisecondsSinceEpoch.toDouble(),
            r.pleasureLevel.toDouble(),
          ),
        )
        .toList();
    final rawFrequencySpots = _buildRawFrequencySpots(allSorted, cutoff);
    final rawDurationSpots = durationData
        .map(
          (r) => FlSpot(
            r.datetime.millisecondsSinceEpoch.toDouble(),
            r.duration.inSeconds / 60.0,
          ),
        )
        .toList();
    final rawThrustSpots = thrustData
        .map(
          (r) => FlSpot(
            r.datetime.millisecondsSinceEpoch.toDouble(),
            _recordThrustCount(r)!,
          ),
        )
        .toList();
    final hasDurationOrThrustData =
        rawDurationSpots.length >= 2 ||
        durationSpots.length >= 2 ||
        rawThrustSpots.length >= 2 ||
        thrustSpots.length >= 2;

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
              ...labels.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 11)),
                    selected: _chartRange == e.key,
                    onSelected: (_) => setState(() => _chartRange = e.key),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Legend — pleasure & frequency
          Row(
            children: [
              _legendItem(
                theme.colorScheme.primary,
                theme.textTheme.labelSmall,
                l10n.intimacyPleasure,
              ),
              const SizedBox(width: 16),
              _legendItem(
                _intimacyFrequencyChartColor,
                theme.textTheme.labelSmall,
                l10n.intimacyFrequency,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: data.length < 2
                ? Center(
                    child: Text(
                      l10n.intimacyChartNoData,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : _buildChart(
                    theme,
                    rawPleasureSpots,
                    pleasureSpots,
                    rawFrequencySpots,
                    frequencySpots,
                    data,
                  ),
          ),
          const SizedBox(height: 12),
          // Legend — duration
          Row(
            children: [
              _legendItem(
                _intimacyDurationChartColor,
                theme.textTheme.labelSmall,
                l10n.intimacyDuration,
              ),
              const SizedBox(width: 16),
              _legendItem(
                _intimacyThrustChartColor,
                theme.textTheme.labelSmall,
                l10n.intimacyThrustCount,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: !hasDurationOrThrustData
                ? Center(
                    child: Text(
                      l10n.intimacyChartNoData,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : _buildDurationChart(
                    theme,
                    rawDurationSpots,
                    durationSpots,
                    rawThrustSpots,
                    thrustSpots,
                    data,
                  ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  /// Purpose: Provide the internal build chart helper for this file.
  /// Inputs: Key parameters such as `theme`, `rawPleasureSpots`, `pleasureSpots`, `rawFrequencySpots`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Pleasure uses the theme primary color; frequency uses fixed teal for contrast.
  Widget _buildChart(
    ThemeData theme,
    List<FlSpot> rawPleasureSpots,
    List<FlSpot> pleasureSpots,
    List<FlSpot> rawFrequencySpots,
    List<FlSpot> frequencySpots,
    List<IntimacyRecord> data,
  ) {
    // Compute freqMax from both EWMA and raw spots
    final allFreqSpots = [...frequencySpots, ...rawFrequencySpots];
    final maxFreq = allFreqSpots.isEmpty
        ? 5.0
        : allFreqSpots.map((s) => s.y).reduce(math.max);
    // Snap freqMax to a clean ceiling so right-axis labels land on round numbers
    /// Purpose: Return a rounded-up frequency ceiling for chart labels.
    /// Inputs: `v`.
    /// Returns: `double`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    double freqCeil(double v) {
      const steps = [1.0, 2.0, 3.0, 5.0, 7.0, 10.0, 14.0, 20.0];
      for (final s in steps) {
        if (s >= v) return s;
      }
      return (v / 5).ceil() * 5.0;
    }

    final freqMax = freqCeil(math.max(maxFreq * 1.1, 1.0));
    final l10n = AppLocalizations.of(context)!;
    final localeName = l10n.localeName;

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
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                final spanDays = data.last.datetime
                    .difference(data.first.datetime)
                    .inDays;
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
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${value.toInt()}',
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                  ),
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
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
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
                      color: _intimacyFrequencyChartColor,
                    ),
                  ),
                );
              },
            ),
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
        maxY: 5.5,
        lineBarsData: [
          // Raw pleasure — thin solid primary
          LineChartBarData(
            spots: rawPleasureSpots,
            isCurved: false,
            color: theme.colorScheme.primary.withValues(alpha: 0.45),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
          // Pleasure EWMA — dashed primary
          LineChartBarData(
            spots: pleasureSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: theme.colorScheme.primary,
            barWidth: 2.5,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          // Raw frequency — thin solid tertiary (scaled to 0-5)
          LineChartBarData(
            spots: rawFrequencySpots
                .map((s) => FlSpot(s.x, (s.y.clamp(0, freqMax) / freqMax) * 5))
                .toList(),
            isCurved: false,
            color: _intimacyFrequencyChartColor.withValues(alpha: 0.45),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
          // Frequency EWMA — dashed tertiary (scaled to 0-5)
          LineChartBarData(
            spots: frequencySpots
                .map((s) => FlSpot(s.x, (s.y / freqMax) * 5))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: _intimacyFrequencyChartColor,
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => spot.barIndex == 3
                ? _intimacyFrequencyChartColor
                : theme.colorScheme.primary,
            getTooltipItems: (spots) {
              return spots.asMap().entries.map((entry) {
                final s = entry.value;
                final date = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
                // Only show tooltip for EWMA series (indices 1 and 3); skip raw (0 and 2)
                if (s.barIndex == 1) {
                  return LineTooltipItem(
                    '${l10n.intimacyPleasure}: ${s.y.toStringAsFixed(1)}\n${DateFormat('MMM d', localeName).format(date)}',
                    TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                } else if (s.barIndex == 3) {
                  final actualFreq = s.y / 5 * freqMax;
                  return LineTooltipItem(
                    '${AppLocalizations.of(context)!.intimacyFrequency}: ${actualFreq.toStringAsFixed(1)}/wk',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Purpose: Provide the internal build duration chart helper for this file.
  /// Inputs: `theme`, duration spots, thrust-count spots, and `data`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Duration and thrust-count series use fixed high-contrast colors.
  Widget _buildDurationChart(
    ThemeData theme,
    List<FlSpot> rawDurationSpots,
    List<FlSpot> durationSpots,
    List<FlSpot> rawThrustSpots,
    List<FlSpot> thrustSpots,
    List<IntimacyRecord> data,
  ) {
    final allDurSpots = [...durationSpots, ...rawDurationSpots];
    final maxMin = allDurSpots.isEmpty
        ? 30.0
        : allDurSpots.map((s) => s.y).reduce(math.max);
    final allThrustSpots = [...thrustSpots, ...rawThrustSpots];
    final maxThrust = allThrustSpots.isEmpty
        ? 100.0
        : allThrustSpots.map((s) => s.y).reduce(math.max);
    // Snap to a clean ceiling (minutes)
    /// Purpose: Return a rounded-up duration ceiling for chart labels.
    /// Inputs: `v`.
    /// Returns: `double`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    double minCeil(double v) {
      const steps = [5.0, 10.0, 15.0, 20.0, 30.0, 45.0, 60.0, 90.0, 120.0];
      for (final s in steps) {
        if (s >= v) return s;
      }
      return (v / 30).ceil() * 30.0;
    }

    /// Purpose: Return a rounded-up thrust-count ceiling for chart labels.
    /// Inputs: `v`.
    /// Returns: `double`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    double thrustCeil(double v) {
      const steps = [100.0, 200.0, 300.0, 500.0, 800.0, 1000.0, 1500.0];
      for (final s in steps) {
        if (s >= v) return s;
      }
      return (v / 500).ceil() * 500.0;
    }

    final yMax = minCeil(math.max(maxMin * 1.15, 5.0));
    final thrustMax = thrustCeil(math.max(maxThrust * 1.1, 100.0));
    final l10n = AppLocalizations.of(context)!;
    final localeName = l10n.localeName;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
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
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                final spanDays = data.last.datetime
                    .difference(data.first.datetime)
                    .inDays;
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
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${value.toInt()}m',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: _intimacyDurationChartColor,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: allThrustSpots.isNotEmpty,
              reservedSize: 38,
              interval: math.max(yMax / 4, 1),
              getTitlesWidget: (value, meta) {
                final actual = value / yMax * thrustMax;
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    actual.toStringAsFixed(0),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: _intimacyThrustChartColor,
                    ),
                  ),
                );
              },
            ),
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
        maxY: yMax,
        lineBarsData: [
          // Raw duration — thin solid secondary
          LineChartBarData(
            spots: rawDurationSpots,
            isCurved: false,
            color: _intimacyDurationChartColor.withValues(alpha: 0.45),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
          // Duration EWMA — dashed secondary
          LineChartBarData(
            spots: durationSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: _intimacyDurationChartColor,
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _intimacyDurationChartColor.withValues(alpha: 0.08),
            ),
          ),
          // Raw thrust count — thin solid tertiary (scaled to duration axis)
          LineChartBarData(
            spots: rawThrustSpots
                .map(
                  (s) =>
                      FlSpot(s.x, (s.y.clamp(0, thrustMax) / thrustMax) * yMax),
                )
                .toList(),
            isCurved: false,
            color: _intimacyThrustChartColor.withValues(alpha: 0.45),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
          // Thrust count EWMA — dashed tertiary (scaled to duration axis)
          LineChartBarData(
            spots: thrustSpots
                .map((s) => FlSpot(s.x, (s.y / thrustMax) * yMax))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: _intimacyThrustChartColor,
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => spot.barIndex == 3
                ? _intimacyThrustChartColor
                : _intimacyDurationChartColor,
            getTooltipItems: (spots) {
              return spots.asMap().entries.map((entry) {
                final s = entry.value;
                final date = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
                if (s.barIndex == 1) {
                  return LineTooltipItem(
                    '${l10n.intimacyDuration}: ${s.y.toStringAsFixed(1)}min\n${DateFormat('MMM d', localeName).format(date)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                } else if (s.barIndex == 3) {
                  final actual = s.y / yMax * thrustMax;
                  return LineTooltipItem(
                    '${l10n.intimacyThrustCount}: ${actual.toStringAsFixed(0)}\n${DateFormat('MMM d', localeName).format(date)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Legend item: solid line + dashed line + label for a given [color].
  /// Purpose: Provide the internal legend item helper for this file.
  /// Inputs: `color`, `labelStyle`, `label`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _legendItem(Color color, TextStyle? labelStyle, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 2, color: color),
        const SizedBox(width: 2),
        Container(width: 4, height: 2, color: color.withValues(alpha: 0)),
        Container(width: 6, height: 2, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(label, style: labelStyle),
      ],
    );
  }

  /// Purpose: Provide the internal chart date interval helper for this file.
  /// Inputs: `data`.
  /// Returns: `double`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  double _chartDateInterval(List<IntimacyRecord> data) {
    if (data.length < 2) return 1;
    final spanMs = data.last.datetime
        .difference(data.first.datetime)
        .inMilliseconds
        .toDouble();
    final spanDays = spanMs / (86400 * 1000);
    const day = 86400 * 1000.0;
    if (spanDays <= 7) return 2 * day; // every-other-day labels
    if (spanDays <= 30) return 7 * day; // weekly labels
    if (spanDays <= 90) return 21 * day; // tri-weekly labels
    if (spanDays <= 180) return 45 * day; // ~6-week labels
    if (spanDays <= 365) return 90 * day; // quarterly labels
    if (spanDays <= 730) return 180 * day; // semi-annual labels
    return 365 * day; // annual labels
  }

  /// Purpose: Provide the internal show manage menu helper for this file.
  /// Inputs: `context`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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
            ListTile(
              leading: const Icon(Icons.self_improvement),
              title: Text(AppLocalizations.of(context)!.intimacyBody),
              onTap: () {
                Navigator.pop(context);
                _openBodySettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Provide the internal open body settings helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: User body edits bump the dedicated `userBodyModifiedAt` LWW
  /// timestamp instead of the general settings timestamp.
  Future<void> _openBodySettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BodySettingsPage(
          userBody: _userBody,
          cycleRecords: _cycleRecords,
          onUserBodyChanged: (profile) {
            setState(() {
              _userBody = profile;
              _userBodyModifiedAt = DateTime.now().toUtc();
            });
            _saveData();
          },
          onCycleRecordsChanged: (records) {
            setState(() => _cycleRecords = List<CycleRecord>.of(records));
            _saveData();
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  /// Purpose: Provide the internal open partner management helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _openPartnerManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PartnerManagementPage(
          partners: _partners,
          records: _records,
          toys: _toys,
          positions: _positions,
          sortModes: _partnerSortModes,
          customOrders: _partnerCustomOrders,
          onChanged: (updated) {
            setState(() => _partners = updated);
            _saveData();
          },
          onRecordsChanged: (updated) {
            setState(() => _records = updated);
            _saveData();
          },
          cycleRecords: _cycleRecords,
          onCycleRecordsChanged: (updated) {
            setState(() => _cycleRecords = List<CycleRecord>.of(updated));
            _saveData();
          },
          onSortChanged: (modes, orders) {
            setState(() {
              _partnerSortModes = Map.of(modes);
              _partnerCustomOrders = orders.map(
                (key, value) => MapEntry(key, List<String>.of(value)),
              );
              _settingsModifiedAt = DateTime.now().toUtc();
            });
            _saveData();
          },
        ),
      ),
    );
  }

  /// Purpose: Provide the internal open toy management helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _openToyManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ToyManagementPage(
          toys: _toys,
          records: _records,
          partners: _partners,
          positions: _positions,
          sortModes: _toySortModes,
          customOrders: _toyCustomOrders,
          onChanged: (updated) {
            setState(() => _toys = updated);
            _saveData();
          },
          onRecordsChanged: (updated) {
            setState(() => _records = updated);
            _saveData();
          },
          onSortChanged: (modes, orders) {
            setState(() {
              _toySortModes = Map.of(modes);
              _toyCustomOrders = orders.map(
                (key, value) => MapEntry(key, List<String>.of(value)),
              );
              _settingsModifiedAt = DateTime.now().toUtc();
            });
            _saveData();
          },
        ),
      ),
    );
  }

  /// Purpose: Provide the internal open position management helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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

class _IntimacyDataError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  /// Purpose: Show a blocking intimacy data read error.
  /// Inputs: `message`, `onRetry`.
  /// Returns: A new `_IntimacyDataError` instance.
  /// Side effects: None.
  /// Notes: Keeps write actions unavailable while the intimacy JSON is unreadable.
  const _IntimacyDataError({required this.message, required this.onRetry});

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.intimacyDataUnreadableTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.intimacyDataUnreadableMessage,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SelectableText(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.intimacyDataRetry),
            ),
          ],
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
  final int weekStartDay;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime) onDateSelected;

  /// Cycle overlays for people whose show-on-calendar option is enabled.
  final List<PersonCycleOverlay> cycleOverlays;

  /// At most this many per-person indicator rows render inside a day cell.
  static const int _maxOverlayRows = 3;

  /// Purpose: Create a calendar widget instance.
  /// Inputs: Focused month, selected date, marked dates, week start, and callbacks.
  /// Returns: A new `_CalendarWidget` instance.
  /// Side effects: None.
  /// Notes: Weekday values use Dart's Monday=1 through Sunday=7 numbering.
  const _CalendarWidget({
    required this.focusedMonth,
    required this.selectedDate,
    required this.markedDates,
    required this.weekStartDay,
    required this.onMonthChanged,
    required this.onDateSelected,
    this.cycleOverlays = const [],
  });

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = focusedMonth.year;
    final month = focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingBlanks = leadingBlankDaysForMonth(
      firstDay,
      weekStartDay: weekStartDay,
    );
    final localeName = AppLocalizations.of(context)!.localeName;

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
                onPressed: () => onMonthChanged(DateTime(year, month - 1, 1)),
              ),
              Text(
                DateFormat('yyyy MMMM', localeName).format(focusedMonth),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onMonthChanged(DateTime(year, month + 1, 1)),
              ),
            ],
          ),
        ),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (final weekday in weekdaySequence(weekStartDay))
                Expanded(
                  child: Center(
                    child: Text(
                      localizedWeekdayLabel(weekday, localeName),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Day grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildDayGrid(
            context,
            leadingBlanks,
            daysInMonth,
            year,
            month,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Purpose: Provide the internal build day grid helper for this file.
  /// Inputs: Key parameters such as `context`, `leadingBlanks`, `daysInMonth`, `year`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildDayGrid(
    BuildContext context,
    int leadingBlanks,
    int daysInMonth,
    int year,
    int month,
  ) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final rows = <Widget>[];
    var day = 1 - leadingBlanks;
    final overlayRowCount = cycleOverlays.length > _maxOverlayRows
        ? _maxOverlayRows
        : cycleOverlays.length;
    // Each overlay row is a 5 px indicator plus 1 px top padding.
    final overlayExtra = overlayRowCount * 6.0;
    final cellHeight = 36.0 + overlayExtra;

    while (day <= daysInMonth) {
      final cells = <Widget>[];
      for (var i = 0; i < 7; i++) {
        if (day < 1 || day > daysInMonth) {
          cells.add(Expanded(child: SizedBox(height: cellHeight)));
        } else {
          final date = DateTime(year, month, day);
          final isMarked = markedDates.contains(date);
          final isSelected =
              selectedDate != null && _isSameDay(selectedDate!, date);
          final isToday =
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          cells.add(
            Expanded(
              child: GestureDetector(
                onTap: () => onDateSelected(date),
                child: Column(
                  children: [
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isMarked
                            ? theme.colorScheme.primaryContainer
                            : null,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 1.5,
                              )
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
                            fontWeight: isMarked || isToday
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                      ),
                    ),
                    // One thin indicator row per visible person so cycles
                    // never overwrite each other or the record marker.
                    for (var o = 0; o < overlayRowCount; o++)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 3,
                          right: 3,
                          top: 1,
                        ),
                        child: buildCycleDayIndicator(
                          cycleOverlays[o].color,
                          cycleOverlays[o].prediction.days[date],
                          height: 3,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
        day++;
      }
      rows.add(Row(children: cells));
    }
    return Column(children: rows);
  }

  /// Purpose: Return whether two date values represent the same calendar day.
  /// Inputs: `a`, `b`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Time components are ignored.
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _RecordTile extends StatelessWidget {
  final IntimacyRecord record;
  final Partner? partner;
  final List<Toy> toys;
  final List<Position> positions;

  /// Purpose: Create a record tile instance.
  /// Inputs: `toys`.
  /// Returns: A new `_RecordTile` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _RecordTile({
    required this.record,
    this.partner,
    this.toys = const [],
    this.positions = const [],
  });

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Shows affirmative condom status text only when protection was used.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat(
      'MMM d, HH:mm',
      l10n.localeName,
    ).format(record.datetime);
    final durationStr = '${record.duration.inMinutes}min';
    final thrustStr = record.thrustCount != null && record.thrustCount! > 0
        ? '${l10n.intimacyThrustCountShort}: ${record.thrustCount} x${record.thrustCountUnit}'
        : null;
    final stars = '★' * record.pleasureLevel + '☆' * (5 - record.pleasureLevel);

    final partnerLabel = partner != null
        ? (partner!.emoji != null
              ? '${partner!.emoji} ${partner!.name}'
              : partner!.name)
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
                      return Icon(
                        Icons.favorite,
                        size: 18,
                        color: theme.colorScheme.primary,
                      );
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
                  record.isSolo ? l10n.intimacySolo : partnerLabel,
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
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  stars,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(durationStr, style: theme.textTheme.bodySmall),
                  ],
                ),
                if (thrustStr != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(thrustStr, style: theme.textTheme.bodySmall),
                    ],
                  ),
                if (record.hadOrgasm)
                  Icon(
                    Icons.favorite,
                    size: 14,
                    color: theme.colorScheme.tertiary,
                  ),
                if (record.watchedPorn) ...[
                  Icon(
                    Icons.ondemand_video,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
                if (record.usedCondom)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.intimacyUsedCondomStatus,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                if (record.location != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(record.location!, style: theme.textTheme.bodySmall),
                    ],
                  ),
              ],
            ),
            if (toys.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: toys.map((t) {
                  final label = t.emoji != null
                      ? '${t.emoji} ${t.name}'
                      : t.name;
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
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }
                        return Chip(
                          label: Text(label),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
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
                  final label = p.emoji != null
                      ? '${p.emoji} ${p.name}'
                      : p.name;
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
  final List<Position> positions;
  final Map<String, String> sortModes;
  final Map<String, List<String>> customOrders;
  final ValueChanged<List<Partner>> onChanged;
  final ValueChanged<List<IntimacyRecord>> onRecordsChanged;
  final List<CycleRecord> cycleRecords;
  final ValueChanged<List<CycleRecord>> onCycleRecordsChanged;
  final void Function(
    Map<String, String> sortModes,
    Map<String, List<String>> customOrders,
  )
  onSortChanged;

  /// Purpose: Create a partner management page instance.
  /// Inputs: None.
  /// Returns: A new `_PartnerManagementPage` instance.
  /// Side effects: None.
  /// Notes: Cycle records flow through to the partner detail Body tab.
  const _PartnerManagementPage({
    required this.partners,
    required this.records,
    required this.toys,
    required this.positions,
    required this.sortModes,
    required this.customOrders,
    required this.onChanged,
    required this.onRecordsChanged,
    required this.cycleRecords,
    required this.onCycleRecordsChanged,
    required this.onSortChanged,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<_PartnerManagementPage> createState() => _PartnerManagementPageState();
}

class _PartnerManagementPageState extends State<_PartnerManagementPage> {
  late List<Partner> _partners;
  late List<IntimacyRecord> _records;
  late List<CycleRecord> _cycleRecords;
  late Map<String, String> _sortModes;
  late Map<String, List<String>> _customOrders;
  final Map<String, bool> _reordering = {};

  static const _statusActive = 'active';
  static const _statusInactive = 'inactive';
  static const _sortDate = 'date';
  static const _sortCount = 'count';
  static const _sortName = 'name';
  static const _sortCustom = 'custom';

  static const _commonEmojis = [
    '👩',
    '👨',
    '👩‍🦰',
    '👨‍🦰',
    '👱‍♀️',
    '👱',
    '🧑',
    '👧',
    '💑',
    '❤️',
    '💕',
    '😍',
    '🥰',
    '💋',
    '🌹',
    '✨',
  ];

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    _partners = List.of(widget.partners);
    _records = List.of(widget.records);
    _cycleRecords = List.of(widget.cycleRecords);
    _sortModes = Map.of(widget.sortModes);
    _customOrders = widget.customOrders.map(
      (key, value) => MapEntry(key, List<String>.of(value)),
    );
  }

  /// Purpose: Provide the internal notify sort helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _notifySort() => widget.onSortChanged(_sortModes, _customOrders);

  /// Purpose: Provide the internal status key helper for this file.
  /// Inputs: `isInactive`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _statusKey(bool isInactive) =>
      isInactive ? _statusInactive : _statusActive;

  /// Purpose: Provide the internal sort mode helper for this file.
  /// Inputs: `statusKey`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _sortMode(String statusKey) => _sortModes[statusKey] ?? _sortCustom;

  /// Purpose: Provide the internal compare text helper for this file.
  /// Inputs: `a`, `b`.
  /// Returns: `int`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  int _compareText(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  /// Purpose: Provide the internal compare nullable dates helper for this file.
  /// Inputs: `a`, `b`.
  /// Returns: `int`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  int _compareNullableDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  /// Purpose: Provide the internal partner record count helper for this file.
  /// Inputs: `partner`.
  /// Returns: `int`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  int _partnerRecordCount(Partner partner) =>
      _records.where((r) => r.partnerId == partner.id).length;

  /// Purpose: Provide the internal normalized order helper for this file.
  /// Inputs: `statusKey`.
  /// Returns: `List<String>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<String> _normalizedOrder(String statusKey) {
    final isInactive = statusKey == _statusInactive;
    final allIds = _partners
        .where((p) => (p.endDate != null) == isInactive)
        .map((p) => p.id)
        .toList();
    final allIdSet = allIds.toSet();
    final seen = <String>{};
    final normalized = <String>[
      for (final id in _customOrders[statusKey] ?? const <String>[])
        if (allIdSet.contains(id) && seen.add(id)) id,
    ];
    for (final id in allIds) {
      if (seen.add(id)) normalized.add(id);
    }
    return normalized;
  }

  /// Purpose: Provide the internal sort partners helper for this file.
  /// Inputs: `statusKey`, `partners`.
  /// Returns: `List<Partner>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<Partner> _sortPartners(String statusKey, List<Partner> partners) {
    final list = List<Partner>.of(partners);
    switch (_sortMode(statusKey)) {
      case _sortDate:
        list.sort((a, b) {
          final byDate = _compareNullableDates(a.startDate, b.startDate);
          return byDate != 0 ? byDate : _compareText(a.name, b.name);
        });
      case _sortCount:
        list.sort((a, b) {
          final byCount = _partnerRecordCount(
            b,
          ).compareTo(_partnerRecordCount(a));
          return byCount != 0 ? byCount : _compareText(a.name, b.name);
        });
      case _sortName:
        list.sort((a, b) => _compareText(a.name, b.name));
      case _sortCustom:
      default:
        final order = _normalizedOrder(statusKey);
        final fallbackIndex = order.length;
        list.sort((a, b) {
          final ai = order.indexOf(a.id);
          final bi = order.indexOf(b.id);
          final byOrder = (ai == -1 ? fallbackIndex : ai).compareTo(
            bi == -1 ? fallbackIndex : bi,
          );
          return byOrder != 0 ? byOrder : _compareText(a.name, b.name);
        });
    }
    return list;
  }

  /// Purpose: Provide the internal set sort mode helper for this file.
  /// Inputs: `statusKey`, `mode`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _setSortMode(String statusKey, String mode) {
    setState(() {
      if (mode == _sortCustom && !_customOrders.containsKey(statusKey)) {
        final isInactive = statusKey == _statusInactive;
        final current = _partners
            .where((p) => (p.endDate != null) == isInactive)
            .toList();
        _customOrders[statusKey] = _sortPartners(
          statusKey,
          current,
        ).map((p) => p.id).toList();
      }
      _sortModes[statusKey] = mode;
      if (mode == _sortCustom) {
        _customOrders[statusKey] = _normalizedOrder(statusKey);
      } else {
        _reordering[statusKey] = false;
      }
    });
    _notifySort();
  }

  /// Purpose: Provide the internal append partner to custom order if needed helper for this file.
  /// Inputs: `partner`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _appendPartnerToCustomOrderIfNeeded(Partner partner) {
    final statusKey = _statusKey(partner.endDate != null);
    if (_sortMode(statusKey) != _sortCustom) return;
    _customOrders[statusKey] = _normalizedOrder(statusKey);
  }

  /// Purpose: Provide the internal remove partner from custom orders helper for this file.
  /// Inputs: `partnerId`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _removePartnerFromCustomOrders(String partnerId) {
    for (final entry in _customOrders.entries) {
      entry.value.remove(partnerId);
    }
  }

  /// Purpose: Provide the internal reorder partners helper for this file.
  /// Inputs: `statusKey`, `partners`, `oldIndex`, `newIndex`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _reorderPartners(
    String statusKey,
    List<Partner> partners,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex--;
    final ids = partners.map((p) => p.id).toList();
    if (oldIndex < 0 ||
        oldIndex >= ids.length ||
        newIndex < 0 ||
        newIndex > ids.length) {
      return;
    }
    final reordered = List<String>.of(ids);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    setState(() {
      _customOrders[statusKey] = reordered;
      _sortModes[statusKey] = _sortCustom;
    });
    _notifySort();
  }

  /// Purpose: Provide the internal add partner helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _addPartner() => _showEditDialog(null);

  /// Purpose: Provide the internal edit partner helper for this file.
  /// Inputs: `p`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _editPartner(Partner p) => _showEditDialog(p);

  /// Purpose: Provide the internal delete partner helper for this file.
  /// Inputs: `p`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Also removes the deleted partner's cycle records so their
  /// `personId` does not dangle; activity records intentionally keep their
  /// stored partner id and render with a blank partner label.
  void _deletePartner(Partner p) {
    setState(() {
      _partners.removeWhere((x) => x.id == p.id);
      _cycleRecords.removeWhere((c) => c.personId == p.id);
    });
    _removePartnerFromCustomOrders(p.id);
    widget.onChanged(_partners);
    widget.onCycleRecordsChanged(_cycleRecords);
    _notifySort();
  }

  /// Purpose: Provide the internal break up partner helper for this file.
  /// Inputs: `p`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Separation automatically stops showing this partner's cycle on
  /// the home-page calendar; the user may re-enable it manually later.
  void _breakUpPartner(Partner p) {
    final now = DateTime.now();
    // Remove from list, re-add at end with endDate set
    setState(() {
      _partners.removeWhere((x) => x.id == p.id);
      _partners.add(
        Partner(
          id: p.id,
          name: p.name,
          emoji: p.emoji,
          imagePath: p.imagePath,
          startDate: p.startDate,
          endDate: now,
          body: p.body?.copyWith(showCycleOnCalendar: false),
        ),
      );
    });
    _removePartnerFromCustomOrders(p.id);
    _appendPartnerToCustomOrderIfNeeded(
      _partners.firstWhere((x) => x.id == p.id),
    );
    widget.onChanged(_partners);
    _notifySort();
  }

  /// Purpose: Provide the internal show partner records helper for this file.
  /// Inputs: `p`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _showPartnerRecords(Partner p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FilteredRecordsPage(
          title: p.name,
          records: _records,
          partnerId: p.id,
          partners: _partners,
          toys: widget.toys,
          positions: widget.positions,
          onRecordsChanged: (updated) {
            setState(() => _records = updated);
            widget.onRecordsChanged(_records);
          },
          onPartnerChanged: (updated) {
            setState(() {
              final idx = _partners.indexWhere((x) => x.id == updated.id);
              if (idx != -1) _partners[idx] = updated;
            });
            widget.onChanged(_partners);
          },
          cycleRecords: _cycleRecords,
          onCycleRecordsChanged: (updated) {
            setState(() => _cycleRecords = List.of(updated));
            widget.onCycleRecordsChanged(_cycleRecords);
          },
        ),
      ),
    );
  }

  /// Purpose: Provide the internal show edit dialog helper for this file.
  /// Inputs: `existing`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _showEditDialog(Partner? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? selectedEmoji = existing?.emoji;
    String? imagePath = existing?.imagePath;
    DateTime? startDate = existing?.startDate;
    DateTime? endDate = existing?.endDate;
    final l10n = AppLocalizations.of(context)!;

    /// Purpose: Return the current partner edit form signature.
    /// Inputs: None.
    /// Returns: `String`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    String signature() => formSignature([
      nameCtrl.text.trim(),
      selectedEmoji,
      imagePath,
      startDate,
      endDate,
    ]);
    final initialSignature = signature();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => UnsavedChangesGuard(
        hasUnsavedChanges: () => signature() != initialSignature,
        builder: (ctx, guard) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(
              existing == null
                  ? l10n.intimacyAddPartner
                  : l10n.intimacyEditPartner,
            ),
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
                  Text(
                    l10n.commonEmojiOptional,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : null,
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
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
                      final picked = await showAppDatePicker(
                        context: ctx,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        title: l10n.intimacyStartDate,
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                    onClear: () => setDialogState(() => startDate = null),
                  ),
                  _DatePickerTile(
                    label: l10n.intimacyEndDate,
                    date: endDate,
                    onPick: () async {
                      final picked = await showAppDatePicker(
                        context: ctx,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        title: l10n.intimacyEndDate,
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                    onClear: () => setDialogState(() => endDate = null),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => guard.maybeDiscardAndPop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => guard.pop(true),
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      Partner? savedPartner;
      final oldStatusKey = existing != null
          ? _statusKey(existing.endDate != null)
          : null;
      setState(() {
        if (existing != null) {
          final idx = _partners.indexWhere((p) => p.id == existing.id);
          if (idx != -1) {
            // Newly marking the partner as separated stops showing their
            // cycle on the home-page calendar (re-enable is manual).
            final newlySeparated = existing.endDate == null && endDate != null;
            savedPartner = Partner(
              id: existing.id,
              name: nameCtrl.text.trim(),
              emoji: selectedEmoji,
              imagePath: imagePath,
              startDate: startDate,
              endDate: endDate,
              body: newlySeparated
                  ? existing.body?.copyWith(showCycleOnCalendar: false)
                  : existing.body,
            );
            _partners[idx] = savedPartner!;
          }
        } else {
          savedPartner = Partner(
            name: nameCtrl.text.trim(),
            emoji: selectedEmoji,
            imagePath: imagePath,
            startDate: startDate,
            endDate: endDate,
          );
          _partners.add(savedPartner!);
        }
      });
      if (savedPartner != null) {
        final newStatusKey = _statusKey(savedPartner!.endDate != null);
        if (oldStatusKey != null && oldStatusKey != newStatusKey) {
          _removePartnerFromCustomOrders(savedPartner!.id);
        }
        if (oldStatusKey == null || oldStatusKey != newStatusKey) {
          _appendPartnerToCustomOrderIfNeeded(savedPartner!);
        }
      }
      widget.onChanged(_partners);
      _notifySort();
    }
  }

  /// Purpose: Provide the internal build image row helper for this file.
  /// Inputs: `imagePath`, `theme`, `onChanged`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildImageRow(
    String? imagePath,
    ThemeData theme,
    ValueChanged<String?> onChanged,
  ) {
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
                    child: Image.file(
                      snap.data!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
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
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: theme.colorScheme.onError,
                        ),
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
          label: Text(
            imagePath != null
                ? AppLocalizations.of(context)!.commonChange
                : AppLocalizations.of(context)!.commonPickImage,
          ),
          onPressed: () async {
            final path = await ImageService.pickAndSaveImage();
            if (path != null) onChanged(path);
          },
        ),
      ],
    );
  }

  /// Purpose: Provide the internal partner subtitle helper for this file.
  /// Inputs: `p`, `recordCount`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _partnerSubtitle(Partner p, int recordCount) {
    final parts = <String>[
      AppLocalizations.of(context)!.intimacyRecordCount(recordCount),
    ];
    if (p.startDate != null || p.endDate != null) {
      /// Purpose: Format a date for the partner subtitle.
      /// Inputs: `d`.
      /// Returns: `String`.
      /// Side effects: None.
      /// Notes: Internal helper used within this function only.
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final start = p.startDate != null ? fmt(p.startDate!) : '?';
      final end = p.endDate != null ? fmt(p.endDate!) : '';
      parts.add(end.isEmpty ? '$start ~' : '$start ~ $end');
    }
    return parts.join(' · ');
  }

  /// Purpose: Return active partners.
  /// Inputs: None.
  /// Returns: `List<Partner>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Partner> get _activePartners => _sortPartners(
    _statusActive,
    _partners.where((p) => p.endDate == null).toList(),
  );

  /// Purpose: Return inactive partners.
  /// Inputs: None.
  /// Returns: `List<Partner>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Partner> get _inactivePartners => _sortPartners(
    _statusInactive,
    _partners.where((p) => p.endDate != null).toList(),
  );

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = _activePartners;
    final inactive = _inactivePartners;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.intimacyPartners), centerTitle: true),
      body: _partners.isEmpty
          ? Center(child: Text(l10n.intimacyNoPartners))
          : ListView(
              children: [
                if (active.isNotEmpty)
                  _buildPartnerSection(
                    title: l10n.intimacyActivePartners,
                    statusKey: _statusActive,
                    partners: active,
                  ),
                if (inactive.isNotEmpty)
                  _buildPartnerSection(
                    title: l10n.intimacyPastPartners,
                    statusKey: _statusInactive,
                    partners: inactive,
                  ),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPartner,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Purpose: Provide the internal build partner section helper for this file.
  /// Inputs: None.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildPartnerSection({
    required String title,
    required String statusKey,
    required List<Partner> partners,
  }) {
    final isReordering =
        _reordering[statusKey] == true && _sortMode(statusKey) == _sortCustom;
    return Column(
      children: [
        _buildManagedSectionHeader(
          title: title,
          count: partners.length,
          statusKey: statusKey,
        ),
        if (isReordering)
          _buildPartnerReorderList(statusKey, partners)
        else
          ...partners.map(_buildPartnerTile),
      ],
    );
  }

  /// Purpose: Provide the internal build managed section header helper for this file.
  /// Inputs: None.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildManagedSectionHeader({
    required String title,
    required int count,
    required String statusKey,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCustom = _sortMode(statusKey) == _sortCustom;
    final isReordering = _reordering[statusKey] == true;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (isCustom && count > 1)
            IconButton(
              icon: Icon(isReordering ? Icons.check : Icons.reorder),
              tooltip: isReordering
                  ? l10n.financeSortDone
                  : l10n.financeSortReorder,
              onPressed: () => setState(() {
                _reordering[statusKey] = !isReordering;
              }),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.financeSortBy,
            onSelected: (mode) => _setSortMode(statusKey, mode),
            itemBuilder: (_) => [
              _managedSortItem(
                statusKey: statusKey,
                value: _sortDate,
                label: l10n.intimacySortByRelationshipDate,
              ),
              _managedSortItem(
                statusKey: statusKey,
                value: _sortCount,
                label: l10n.intimacySortByUseCount,
              ),
              _managedSortItem(
                statusKey: statusKey,
                value: _sortName,
                label: l10n.financeSortByName,
              ),
              _managedSortItem(
                statusKey: statusKey,
                value: _sortCustom,
                label: l10n.financeSortCustom,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Purpose: Provide the internal managed sort item helper for this file.
  /// Inputs: None.
  /// Returns: `PopupMenuEntry<String>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  PopupMenuEntry<String> _managedSortItem({
    required String statusKey,
    required String value,
    required String label,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            _sortMode(statusKey) == value
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  /// Purpose: Provide the internal build partner reorder list helper for this file.
  /// Inputs: `statusKey`, `partners`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildPartnerReorderList(String statusKey, List<Partner> partners) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: partners.length,
      onReorderItem: (oldIndex, newIndex) {
        final oldStyleNewIndex = newIndex > oldIndex ? newIndex + 1 : newIndex;
        _reorderPartners(statusKey, partners, oldIndex, oldStyleNewIndex);
      },
      proxyDecorator: (child, index, animation) {
        return Material(elevation: 4, child: child);
      },
      itemBuilder: (context, index) {
        final partner = partners[index];
        return ListTile(
          key: ValueKey('partner-reorder-${partner.id}'),
          leading: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
          title: Text(partner.name),
          subtitle: Text(
            _partnerSubtitle(partner, _partnerRecordCount(partner)),
          ),
        );
      },
    );
  }

  /// Purpose: Provide the internal build partner tile helper for this file.
  /// Inputs: `p`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildPartnerTile(Partner p) {
    final l10n = AppLocalizations.of(context)!;
    final isInactive = p.endDate != null;
    final recordCount = _partnerRecordCount(p);
    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.edit_outlined,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: isInactive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.tertiary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              isInactive ? Icons.delete_outline : Icons.heart_broken_outlined,
              color: Theme.of(context).colorScheme.onTertiary,
            ),
            const SizedBox(width: 8),
            if (!isInactive)
              Text(
                l10n.intimacyBreakUp,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 20),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editPartner(p);
          return false;
        }
        if (isInactive) {
          return confirmDelete(context, p.name);
        }
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.intimacyBreakUp),
            content: Text(p.name),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.intimacyBreakUp),
              ),
            ],
          ),
        );
        if (confirm == true) {
          _breakUpPartner(p);
        }
        return false;
      },
      onDismissed: (_) => _deletePartner(p),
      child: ListTile(
        leading: _buildPartnerAvatar(p),
        title: Text(
          p.name,
          style: isInactive
              ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
              : null,
        ),
        subtitle: Text(_partnerSubtitle(p, recordCount)),
        onTap: () => _showPartnerRecords(p),
      ),
    );
  }

  /// Purpose: Provide the internal build partner avatar helper for this file.
  /// Inputs: `p`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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
  final List<Position> positions;
  final Map<String, String> sortModes;
  final Map<String, List<String>> customOrders;
  final ValueChanged<List<Toy>> onChanged;
  final ValueChanged<List<IntimacyRecord>> onRecordsChanged;
  final void Function(
    Map<String, String> sortModes,
    Map<String, List<String>> customOrders,
  )
  onSortChanged;

  /// Purpose: Create a toy management page instance.
  /// Inputs: None.
  /// Returns: A new `_ToyManagementPage` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _ToyManagementPage({
    required this.toys,
    required this.records,
    required this.partners,
    required this.positions,
    required this.sortModes,
    required this.customOrders,
    required this.onChanged,
    required this.onRecordsChanged,
    required this.onSortChanged,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<_ToyManagementPage> createState() => _ToyManagementPageState();
}

class _ToyManagementPageState extends State<_ToyManagementPage> {
  late List<Toy> _toys;
  late List<IntimacyRecord> _records;
  late Map<String, String> _sortModes;
  late Map<String, List<String>> _customOrders;
  final Map<String, bool> _reordering = {};

  static const _statusActive = 'active';
  static const _statusInactive = 'inactive';
  static const _sortDate = 'date';
  static const _sortCount = 'count';
  static const _sortName = 'name';
  static const _sortCustom = 'custom';

  static const _commonEmojis = [
    '🎀',
    '🧸',
    '💎',
    '🔮',
    '🎯',
    '🪄',
    '🌡️',
    '💫',
    '🎁',
    '🦋',
    '🌸',
    '🍭',
    '⭐',
    '🔥',
    '💜',
    '✨',
  ];

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    _toys = List.of(widget.toys);
    _records = List.of(widget.records);
    _sortModes = Map.of(widget.sortModes);
    _customOrders = widget.customOrders.map(
      (key, value) => MapEntry(key, List<String>.of(value)),
    );
  }

  /// Purpose: Provide the internal notify sort helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _notifySort() => widget.onSortChanged(_sortModes, _customOrders);

  /// Purpose: Provide the internal status key helper for this file.
  /// Inputs: `isRetired`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _statusKey(bool isRetired) =>
      isRetired ? _statusInactive : _statusActive;

  /// Purpose: Provide the internal sort mode helper for this file.
  /// Inputs: `statusKey`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _sortMode(String statusKey) => _sortModes[statusKey] ?? _sortCustom;

  /// Purpose: Provide the internal compare text helper for this file.
  /// Inputs: `a`, `b`.
  /// Returns: `int`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  int _compareText(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  /// Purpose: Provide the internal compare nullable dates helper for this file.
  /// Inputs: `a`, `b`.
  /// Returns: `int`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  int _compareNullableDates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  /// Purpose: Provide the internal toy record count helper for this file.
  /// Inputs: `toy`.
  /// Returns: `int`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  int _toyRecordCount(Toy toy) =>
      _records.where((r) => r.toyIds.contains(toy.id)).length;

  /// Purpose: Format an intimacy toy cost amount for display.
  /// Inputs: `amount`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Toy prices currently use plain dollar display.
  String _formatMoney(double amount) => '\$${amount.toStringAsFixed(2)}';

  /// Purpose: Sum total recorded toy costs.
  /// Inputs: `toys`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Toys without a price contribute zero.
  double _totalToyCost(List<Toy> toys) =>
      toys.fold(0.0, (sum, toy) => sum + toy.totalCost());

  /// Purpose: Sum average daily costs when they can be calculated.
  /// Inputs: `toys`.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Returns null when no toy has both price and purchase date.
  double? _totalDailyToyCost(List<Toy> toys) {
    var total = 0.0;
    var hasDailyCost = false;
    for (final toy in toys) {
      final dailyCost = toy.averageDailyCost();
      if (dailyCost == null) continue;
      hasDailyCost = true;
      total += dailyCost;
    }
    return hasDailyCost ? total : null;
  }

  /// Purpose: Provide the internal normalized order helper for this file.
  /// Inputs: `statusKey`.
  /// Returns: `List<String>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<String> _normalizedOrder(String statusKey) {
    final isRetired = statusKey == _statusInactive;
    final allIds = _toys
        .where((t) => (t.retiredDate != null) == isRetired)
        .map((t) => t.id)
        .toList();
    final allIdSet = allIds.toSet();
    final seen = <String>{};
    final normalized = <String>[
      for (final id in _customOrders[statusKey] ?? const <String>[])
        if (allIdSet.contains(id) && seen.add(id)) id,
    ];
    for (final id in allIds) {
      if (seen.add(id)) normalized.add(id);
    }
    return normalized;
  }

  /// Purpose: Provide the internal sort toys helper for this file.
  /// Inputs: `statusKey`, `toys`.
  /// Returns: `List<Toy>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<Toy> _sortToys(String statusKey, List<Toy> toys) {
    final list = List<Toy>.of(toys);
    switch (_sortMode(statusKey)) {
      case _sortDate:
        list.sort((a, b) {
          final byDate = _compareNullableDates(a.purchaseDate, b.purchaseDate);
          return byDate != 0 ? byDate : _compareText(a.name, b.name);
        });
      case _sortCount:
        list.sort((a, b) {
          final byCount = _toyRecordCount(b).compareTo(_toyRecordCount(a));
          return byCount != 0 ? byCount : _compareText(a.name, b.name);
        });
      case _sortName:
        list.sort((a, b) => _compareText(a.name, b.name));
      case _sortCustom:
      default:
        final order = _normalizedOrder(statusKey);
        final fallbackIndex = order.length;
        list.sort((a, b) {
          final ai = order.indexOf(a.id);
          final bi = order.indexOf(b.id);
          final byOrder = (ai == -1 ? fallbackIndex : ai).compareTo(
            bi == -1 ? fallbackIndex : bi,
          );
          return byOrder != 0 ? byOrder : _compareText(a.name, b.name);
        });
    }
    return list;
  }

  /// Purpose: Provide the internal set sort mode helper for this file.
  /// Inputs: `statusKey`, `mode`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _setSortMode(String statusKey, String mode) {
    setState(() {
      if (mode == _sortCustom && !_customOrders.containsKey(statusKey)) {
        final isRetired = statusKey == _statusInactive;
        final current = _toys
            .where((t) => (t.retiredDate != null) == isRetired)
            .toList();
        _customOrders[statusKey] = _sortToys(
          statusKey,
          current,
        ).map((t) => t.id).toList();
      }
      _sortModes[statusKey] = mode;
      if (mode == _sortCustom) {
        _customOrders[statusKey] = _normalizedOrder(statusKey);
      } else {
        _reordering[statusKey] = false;
      }
    });
    _notifySort();
  }

  /// Purpose: Provide the internal append toy to custom order if needed helper for this file.
  /// Inputs: `toy`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _appendToyToCustomOrderIfNeeded(Toy toy) {
    final statusKey = _statusKey(toy.retiredDate != null);
    if (_sortMode(statusKey) != _sortCustom) return;
    _customOrders[statusKey] = _normalizedOrder(statusKey);
  }

  /// Purpose: Provide the internal remove toy from custom orders helper for this file.
  /// Inputs: `toyId`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _removeToyFromCustomOrders(String toyId) {
    for (final entry in _customOrders.entries) {
      entry.value.remove(toyId);
    }
  }

  /// Purpose: Provide the internal reorder toys helper for this file.
  /// Inputs: `statusKey`, `toys`, `oldIndex`, `newIndex`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _reorderToys(
    String statusKey,
    List<Toy> toys,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex--;
    final ids = toys.map((t) => t.id).toList();
    if (oldIndex < 0 ||
        oldIndex >= ids.length ||
        newIndex < 0 ||
        newIndex > ids.length) {
      return;
    }
    final reordered = List<String>.of(ids);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    setState(() {
      _customOrders[statusKey] = reordered;
      _sortModes[statusKey] = _sortCustom;
    });
    _notifySort();
  }

  /// Purpose: Provide the internal add toy helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _addToy() => _showEditDialog(null);

  /// Purpose: Provide the internal edit toy helper for this file.
  /// Inputs: `t`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _editToy(Toy t) => _showEditDialog(t);

  /// Purpose: Provide the internal delete toy helper for this file.
  /// Inputs: `t`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _deleteToy(Toy t) {
    setState(() => _toys.removeWhere((x) => x.id == t.id));
    _removeToyFromCustomOrders(t.id);
    widget.onChanged(_toys);
    _notifySort();
  }

  /// Purpose: Provide the internal retire toy helper for this file.
  /// Inputs: `t`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _retireToy(Toy t) {
    final now = DateTime.now();
    setState(() {
      _toys.removeWhere((x) => x.id == t.id);
      _toys.add(
        Toy(
          id: t.id,
          name: t.name,
          emoji: t.emoji,
          imagePath: t.imagePath,
          purchaseDate: t.purchaseDate,
          retiredDate: now,
          purchaseLink: t.purchaseLink,
          price: t.price,
        ),
      );
    });
    _removeToyFromCustomOrders(t.id);
    _appendToyToCustomOrderIfNeeded(_toys.firstWhere((x) => x.id == t.id));
    widget.onChanged(_toys);
    _notifySort();
  }

  /// Purpose: Provide the internal show toy records helper for this file.
  /// Inputs: `t`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _showToyRecords(Toy t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FilteredRecordsPage(
          title: t.name,
          records: _records,
          toyId: t.id,
          partners: widget.partners,
          toys: _toys,
          positions: widget.positions,
          onRecordsChanged: (updated) {
            setState(() => _records = updated);
            widget.onRecordsChanged(_records);
          },
        ),
      ),
    );
  }

  /// Purpose: Show the aggregate toy-cost overview page.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Pushes a route onto the navigator.
  /// Notes: The overview covers all, active, and retired toy cost groups.
  void _showToyCostOverview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ToyCostOverviewPage(toys: _toys)),
    );
  }

  /// Purpose: Provide the internal show edit dialog helper for this file.
  /// Inputs: `existing`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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

    /// Purpose: Return the current toy edit form signature.
    /// Inputs: None.
    /// Returns: `String`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    String signature() => formSignature([
      nameCtrl.text.trim(),
      linkCtrl.text.trim(),
      priceCtrl.text.trim(),
      selectedEmoji,
      imagePath,
      purchaseDate,
      retiredDate,
    ]);
    final initialSignature = signature();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => UnsavedChangesGuard(
        hasUnsavedChanges: () => signature() != initialSignature,
        builder: (ctx, guard) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(
              existing == null ? l10n.intimacyAddToy : l10n.intimacyEditToy,
            ),
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
                  Text(
                    l10n.commonEmojiOptional,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : null,
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
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
                      final picked = await showAppDatePicker(
                        context: ctx,
                        initialDate: purchaseDate ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        title: l10n.intimacyPurchaseDate,
                      );
                      if (picked != null) {
                        setDialogState(() => purchaseDate = picked);
                      }
                    },
                    onClear: () => setDialogState(() => purchaseDate = null),
                  ),
                  _DatePickerTile(
                    label: l10n.intimacyRetiredDate,
                    date: retiredDate,
                    onPick: () async {
                      final picked = await showAppDatePicker(
                        context: ctx,
                        initialDate: retiredDate ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        title: l10n.intimacyRetiredDate,
                      );
                      if (picked != null) {
                        setDialogState(() => retiredDate = picked);
                      }
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => guard.maybeDiscardAndPop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => guard.pop(true),
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final link = linkCtrl.text.trim().isEmpty ? null : linkCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim());
      Toy? savedToy;
      final oldStatusKey = existing != null
          ? _statusKey(existing.retiredDate != null)
          : null;
      setState(() {
        if (existing != null) {
          final idx = _toys.indexWhere((t) => t.id == existing.id);
          if (idx != -1) {
            savedToy = Toy(
              id: existing.id,
              name: nameCtrl.text.trim(),
              emoji: selectedEmoji,
              imagePath: imagePath,
              purchaseDate: purchaseDate,
              retiredDate: retiredDate,
              purchaseLink: link,
              price: price,
            );
            _toys[idx] = savedToy!;
          }
        } else {
          savedToy = Toy(
            name: nameCtrl.text.trim(),
            emoji: selectedEmoji,
            imagePath: imagePath,
            purchaseDate: purchaseDate,
            retiredDate: retiredDate,
            purchaseLink: link,
            price: price,
          );
          _toys.add(savedToy!);
        }
      });
      if (savedToy != null) {
        final newStatusKey = _statusKey(savedToy!.retiredDate != null);
        if (oldStatusKey != null && oldStatusKey != newStatusKey) {
          _removeToyFromCustomOrders(savedToy!.id);
        }
        if (oldStatusKey == null || oldStatusKey != newStatusKey) {
          _appendToyToCustomOrderIfNeeded(savedToy!);
        }
      }
      widget.onChanged(_toys);
      _notifySort();
    }
  }

  /// Purpose: Provide the internal build image row helper for this file.
  /// Inputs: `imagePath`, `theme`, `onChanged`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildImageRow(
    String? imagePath,
    ThemeData theme,
    ValueChanged<String?> onChanged,
  ) {
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
                    child: Image.file(
                      snap.data!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
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
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: theme.colorScheme.onError,
                        ),
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
          label: Text(
            imagePath != null
                ? AppLocalizations.of(context)!.commonChange
                : AppLocalizations.of(context)!.commonPickImage,
          ),
          onPressed: () async {
            final path = await ImageService.pickAndSaveImage();
            if (path != null) onChanged(path);
          },
        ),
      ],
    );
  }

  /// Purpose: Provide the internal toy subtitle helper for this file.
  /// Inputs: `t`, `recordCount`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _toySubtitle(Toy t, int recordCount) {
    final l10n = AppLocalizations.of(context)!;
    final parts = <String>[l10n.intimacyRecordCount(recordCount)];
    if (t.purchaseDate != null) {
      /// Purpose: Format a purchase date for the toy subtitle.
      /// Inputs: `d`.
      /// Returns: `String`.
      /// Side effects: None.
      /// Notes: Internal helper used within this function only.
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      parts.add(fmt(t.purchaseDate!));
    }
    if (t.retiredDate != null) {
      /// Purpose: Format a retired date for the toy subtitle.
      /// Inputs: `d`.
      /// Returns: `String`.
      /// Side effects: None.
      /// Notes: Internal helper used within this function only.
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      parts.add('⊘ ${fmt(t.retiredDate!)}');
    }
    if (t.price != null) {
      parts.add('\$${t.price!.toStringAsFixed(2)}');
    }
    final dailyCost = t.averageDailyCost();
    if (dailyCost != null) {
      parts.add('${l10n.intimacyDailyCost}: \$${dailyCost.toStringAsFixed(2)}');
    }
    return parts.join(' · ');
  }

  /// Purpose: Return active toys.
  /// Inputs: None.
  /// Returns: `List<Toy>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Toy> get _activeToys => _sortToys(
    _statusActive,
    _toys.where((t) => t.retiredDate == null).toList(),
  );

  /// Purpose: Return retired toys.
  /// Inputs: None.
  /// Returns: `List<Toy>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Toy> get _retiredToys => _sortToys(
    _statusInactive,
    _toys.where((t) => t.retiredDate != null).toList(),
  );

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = _activeToys;
    final retired = _retiredToys;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.intimacyToys), centerTitle: true),
      body: _toys.isEmpty
          ? Center(child: Text(l10n.intimacyNoToys))
          : ListView(
              children: [
                _buildActiveCostSummary(active),
                if (active.isNotEmpty)
                  _buildToySection(
                    title: l10n.intimacyActiveToys,
                    statusKey: _statusActive,
                    toys: active,
                  ),
                if (retired.isNotEmpty)
                  _buildToySection(
                    title: l10n.intimacyRetiredToys,
                    statusKey: _statusInactive,
                    toys: retired,
                  ),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addToy,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Purpose: Build the active-toy cost summary entry on the toy page.
  /// Inputs: `activeToys`.
  /// Returns: `Widget`.
  /// Side effects: Creates UI widgets and may navigate to the cost overview.
  /// Notes: Shows only active totals here; the overview has all/active/retired groups.
  Widget _buildActiveCostSummary(List<Toy> activeToys) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dailyCost = _totalDailyToyCost(activeToys);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showToyCostOverview,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.intimacyActiveCost,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCostMetric(
                        theme,
                        l10n.intimacyTotalCost,
                        _formatMoney(_totalToyCost(activeToys)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCostMetric(
                        theme,
                        l10n.intimacyDailyCost,
                        dailyCost == null ? '-' : _formatMoney(dailyCost),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Purpose: Build a compact cost metric column.
  /// Inputs: `theme`, `label`, `value`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Shared by the toy page's active-cost summary.
  Widget _buildCostMetric(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  /// Purpose: Provide the internal build toy section helper for this file.
  /// Inputs: None.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildToySection({
    required String title,
    required String statusKey,
    required List<Toy> toys,
  }) {
    final isReordering =
        _reordering[statusKey] == true && _sortMode(statusKey) == _sortCustom;
    return Column(
      children: [
        _buildManagedSectionHeader(
          title: title,
          count: toys.length,
          statusKey: statusKey,
        ),
        if (isReordering)
          _buildToyReorderList(statusKey, toys)
        else
          ...toys.map(_buildToyTile),
      ],
    );
  }

  /// Purpose: Provide the internal build managed section header helper for this file.
  /// Inputs: None.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildManagedSectionHeader({
    required String title,
    required int count,
    required String statusKey,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCustom = _sortMode(statusKey) == _sortCustom;
    final isReordering = _reordering[statusKey] == true;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (isCustom && count > 1)
            IconButton(
              icon: Icon(isReordering ? Icons.check : Icons.reorder),
              tooltip: isReordering
                  ? l10n.financeSortDone
                  : l10n.financeSortReorder,
              onPressed: () => setState(() {
                _reordering[statusKey] = !isReordering;
              }),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.financeSortBy,
            onSelected: (mode) => _setSortMode(statusKey, mode),
            itemBuilder: (_) => [
              _managedSortItem(
                statusKey: statusKey,
                value: _sortDate,
                label: l10n.intimacySortByPurchaseDate,
              ),
              _managedSortItem(
                statusKey: statusKey,
                value: _sortCount,
                label: l10n.intimacySortByUseCount,
              ),
              _managedSortItem(
                statusKey: statusKey,
                value: _sortName,
                label: l10n.financeSortByName,
              ),
              _managedSortItem(
                statusKey: statusKey,
                value: _sortCustom,
                label: l10n.financeSortCustom,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Purpose: Provide the internal managed sort item helper for this file.
  /// Inputs: None.
  /// Returns: `PopupMenuEntry<String>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  PopupMenuEntry<String> _managedSortItem({
    required String statusKey,
    required String value,
    required String label,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            _sortMode(statusKey) == value
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  /// Purpose: Provide the internal build toy reorder list helper for this file.
  /// Inputs: `statusKey`, `toys`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildToyReorderList(String statusKey, List<Toy> toys) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: toys.length,
      onReorderItem: (oldIndex, newIndex) {
        final oldStyleNewIndex = newIndex > oldIndex ? newIndex + 1 : newIndex;
        _reorderToys(statusKey, toys, oldIndex, oldStyleNewIndex);
      },
      proxyDecorator: (child, index, animation) {
        return Material(elevation: 4, child: child);
      },
      itemBuilder: (context, index) {
        final toy = toys[index];
        return ListTile(
          key: ValueKey('toy-reorder-${toy.id}'),
          leading: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
          title: Text(toy.name),
          subtitle: Text(_toySubtitle(toy, _toyRecordCount(toy))),
        );
      },
    );
  }

  /// Purpose: Provide the internal build toy tile helper for this file.
  /// Inputs: `t`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildToyTile(Toy t) {
    final l10n = AppLocalizations.of(context)!;
    final isRetired = t.retiredDate != null;
    final recordCount = _toyRecordCount(t);
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Theme.of(context).colorScheme.primary,
        child: Icon(
          Icons.edit_outlined,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: isRetired
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.tertiary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              isRetired ? Icons.delete_outline : Icons.archive_outlined,
              color: Theme.of(context).colorScheme.onTertiary,
            ),
            const SizedBox(width: 8),
            if (!isRetired)
              Text(
                l10n.intimacyRetire,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 20),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editToy(t);
          return false;
        }
        if (isRetired) {
          return confirmDelete(context, t.name);
        }
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.intimacyRetire),
            content: Text(t.name),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.intimacyRetire),
              ),
            ],
          ),
        );
        if (confirm == true) {
          _retireToy(t);
        }
        return false;
      },
      onDismissed: (_) => _deleteToy(t),
      child: ListTile(
        leading: _buildToyAvatar(t),
        title: Text(
          t.name,
          style: isRetired
              ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
              : null,
        ),
        subtitle: Text(_toySubtitle(t, recordCount)),
        onTap: () => _showToyRecords(t),
      ),
    );
  }

  /// Purpose: Provide the internal build toy avatar helper for this file.
  /// Inputs: `t`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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

  /// Purpose: Create a position management page instance.
  /// Inputs: None.
  /// Returns: A new `_PositionManagementPage` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _PositionManagementPage({
    required this.positions,
    required this.records,
    required this.onChanged,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<_PositionManagementPage> createState() =>
      _PositionManagementPageState();
}

class _PositionManagementPageState extends State<_PositionManagementPage> {
  late List<Position> _positions;

  static const _commonEmojis = [
    '🔝',
    '🔄',
    '🐕',
    '🪑',
    '🦋',
    '🌙',
    '🌟',
    '💫',
    '🔀',
    '🎯',
    '🧘',
    '🤸',
    '🏋️',
    '🧗',
    '💃',
    '✨',
  ];

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    _positions = List.of(widget.positions);
  }

  /// Purpose: Provide the internal add position helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _addPosition() => _showEditDialog(null);

  /// Purpose: Provide the internal edit position helper for this file.
  /// Inputs: `p`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _editPosition(Position p) => _showEditDialog(p);

  /// Purpose: Provide the internal delete position helper for this file.
  /// Inputs: `p`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _deletePosition(Position p) {
    setState(() => _positions.removeWhere((x) => x.id == p.id));
    widget.onChanged(_positions);
  }

  /// Purpose: Provide the internal import defaults helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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
        _positions.add(
          Position(
            name: preset['name'] as String,
            emoji: preset['emoji'] as String,
          ),
        );
        added++;
      }
    }
    if (added > 0) {
      setState(() {});
      widget.onChanged(_positions);
    }
  }

  /// Purpose: Provide the internal show edit dialog helper for this file.
  /// Inputs: `existing`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _showEditDialog(Position? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? selectedEmoji = existing?.emoji;
    final l10n = AppLocalizations.of(context)!;

    /// Purpose: Return the current position edit form signature.
    /// Inputs: None.
    /// Returns: `String`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    String signature() => formSignature([nameCtrl.text.trim(), selectedEmoji]);
    final initialSignature = signature();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => UnsavedChangesGuard(
        hasUnsavedChanges: () => signature() != initialSignature,
        builder: (ctx, guard) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(
              existing == null
                  ? l10n.intimacyAddPosition
                  : l10n.intimacyEditPosition,
            ),
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
                  Text(
                    l10n.commonEmojiOptional,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : null,
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
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
                onPressed: () => guard.maybeDiscardAndPop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => guard.pop(true),
                child: Text(l10n.commonSave),
              ),
            ],
          ),
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
          _positions.add(
            Position(name: nameCtrl.text.trim(), emoji: selectedEmoji),
          );
        }
      });
      widget.onChanged(_positions);
    }
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
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
                    child: Icon(
                      Icons.edit_outlined,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.error,
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onError,
                    ),
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
                    leading: CircleAvatar(child: Text(p.emoji ?? p.name[0])),
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
class _FilteredRecordsPage extends ConsumerStatefulWidget {
  final String title;
  final List<IntimacyRecord> records;
  final String? partnerId;
  final String? toyId;
  final List<Partner> partners;
  final List<Toy> toys;
  final List<Position> positions;
  final ValueChanged<List<IntimacyRecord>> onRecordsChanged;

  /// Partner-mode extras: body tab data and callbacks. All null for toys.
  final ValueChanged<Partner>? onPartnerChanged;
  final List<CycleRecord>? cycleRecords;
  final ValueChanged<List<CycleRecord>>? onCycleRecordsChanged;

  /// Purpose: Create a filtered records page instance.
  /// Inputs: The title, records, optional partner/toy filter, and update callback.
  /// Returns: A new `_FilteredRecordsPage` instance.
  /// Side effects: None.
  /// Notes: Partner detail pages render Records/Body tabs when the body
  /// callbacks are provided; toy detail pages keep the single-scroll layout.
  const _FilteredRecordsPage({
    required this.title,
    required this.records,
    this.partnerId,
    this.toyId,
    required this.partners,
    required this.toys,
    required this.positions,
    required this.onRecordsChanged,
    this.onPartnerChanged,
    this.cycleRecords,
    this.onCycleRecordsChanged,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  ConsumerState<_FilteredRecordsPage> createState() =>
      _FilteredRecordsPageState();
}

class _FilteredRecordsPageState extends ConsumerState<_FilteredRecordsPage> {
  late List<IntimacyRecord> _records;
  Partner? _partner;
  List<CycleRecord> _cycleRecords = [];

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Copies incoming records so detail edits can update the visible page immediately.
  @override
  void initState() {
    super.initState();
    _records = List.of(widget.records);
    _partner = widget.partners
        .where((p) => p.id == widget.partnerId)
        .firstOrNull;
    _cycleRecords = List.of(widget.cycleRecords ?? const []);
  }

  /// Purpose: React to parent widget changes after this state has been created.
  /// Inputs: `oldWidget`.
  /// Returns: None.
  /// Side effects: May refresh the local record copy.
  /// Notes: Keeps this page aligned if the parent supplies a replaced records list.
  @override
  void didUpdateWidget(covariant _FilteredRecordsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.records, oldWidget.records)) {
      _records = List.of(widget.records);
    }
    if (!identical(widget.cycleRecords, oldWidget.cycleRecords)) {
      _cycleRecords = List.of(widget.cycleRecords ?? const []);
    }
  }

  /// Purpose: Report whether this page shows the partner Records/Body tabs.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Toy detail pages never get a body tab.
  bool get _hasBodyTab =>
      widget.partnerId != null &&
      _partner != null &&
      widget.onPartnerChanged != null &&
      widget.onCycleRecordsChanged != null;

  /// Purpose: Return records matching this detail page's partner or toy filter.
  /// Inputs: None.
  /// Returns: `List<IntimacyRecord>`.
  /// Side effects: None.
  /// Notes: Records are shown newest first, matching account transaction details.
  List<IntimacyRecord> get _filteredRecords {
    final filtered = _records.where((record) {
      if (widget.partnerId != null) return record.partnerId == widget.partnerId;
      if (widget.toyId != null) return record.toyIds.contains(widget.toyId);
      return true;
    }).toList();
    filtered.sort((a, b) => b.datetime.compareTo(a.datetime));
    return filtered;
  }

  /// Purpose: Return the toy represented by this filtered detail page.
  /// Inputs: None.
  /// Returns: `Toy?`.
  /// Side effects: None.
  /// Notes: Partner detail pages return null so cost UI stays toy-only.
  Toy? get _selectedToy {
    final toyId = widget.toyId;
    if (toyId == null) return null;
    return widget.toys.where((toy) => toy.id == toyId).firstOrNull;
  }

  /// Purpose: Return partners available in the add/edit record dialog.
  /// Inputs: Optional partner id that must be included.
  /// Returns: `List<Partner>`.
  /// Side effects: None.
  /// Notes: Active partners are shown, plus the current detail or edited record partner if inactive.
  List<Partner> _dialogPartners({String? includePartnerId}) {
    final includeIds = {?widget.partnerId, ?includePartnerId};
    final seen = <String>{};
    return [
      for (final partner in widget.partners)
        if ((partner.endDate == null || includeIds.contains(partner.id)) &&
            seen.add(partner.id))
          partner,
    ];
  }

  /// Purpose: Return toys available in the add/edit record dialog.
  /// Inputs: Optional toy ids that must be included.
  /// Returns: `List<Toy>`.
  /// Side effects: None.
  /// Notes: Active toys are shown, plus the current detail or edited record toys if retired.
  List<Toy> _dialogToys({Iterable<String> includeToyIds = const []}) {
    final includeIds = {?widget.toyId, ...includeToyIds};
    final seen = <String>{};
    return [
      for (final toy in widget.toys)
        if ((toy.retiredDate == null || includeIds.contains(toy.id)) &&
            seen.add(toy.id))
          toy,
    ];
  }

  /// Purpose: Notify the parent that the full record list changed.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Triggers parent persistence through the provided callback.
  /// Notes: Sends a defensive copy so the parent owns its list instance.
  void _notifyRecordsChanged() => widget.onRecordsChanged(List.of(_records));

  /// Purpose: Add a new record from this filtered detail page.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Opens a dialog, updates local records, and notifies the parent.
  /// Notes: The current partner or toy is preselected for faster entry.
  Future<void> _addRecord() async {
    final record = await showDialog<IntimacyRecord>(
      context: context,
      builder: (_) => AddRecordDialog(
        partners: _dialogPartners(includePartnerId: widget.partnerId),
        toys: _dialogToys(
          includeToyIds: widget.toyId != null ? [widget.toyId!] : const [],
        ),
        positions: widget.positions,
        initialPartnerId: widget.partnerId,
        initialToyIds: widget.toyId != null ? [widget.toyId!] : const [],
      ),
    );
    if (record == null) return;
    setState(() => _records.insert(0, record));
    _notifyRecordsChanged();
  }

  /// Purpose: Edit an existing record from this filtered detail page.
  /// Inputs: `record`.
  /// Returns: `Future<void>`.
  /// Side effects: Opens a dialog, updates local records, and notifies the parent.
  /// Notes: If the edit removes the current partner or toy, the record disappears from this filter.
  Future<void> _editRecord(IntimacyRecord record) async {
    final updated = await showDialog<IntimacyRecord>(
      context: context,
      builder: (_) => AddRecordDialog(
        record: record,
        partners: _dialogPartners(includePartnerId: record.partnerId),
        toys: _dialogToys(includeToyIds: record.toyIds),
        positions: widget.positions,
      ),
    );
    if (updated == null) return;
    setState(() {
      final index = _records.indexWhere((r) => r.id == updated.id);
      if (index != -1) _records[index] = updated;
    });
    _notifyRecordsChanged();
  }

  /// Purpose: Delete an existing record from this filtered detail page.
  /// Inputs: `record`.
  /// Returns: None.
  /// Side effects: Updates local records and notifies the parent.
  /// Notes: The Dismissible confirmation is handled by the caller before this runs.
  void _deleteRecord(IntimacyRecord record) {
    setState(() => _records.removeWhere((r) => r.id == record.id));
    _notifyRecordsChanged();
  }

  /// Purpose: Format a duration for summary metrics.
  /// Inputs: `duration`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Keeps short values compact and longer values readable.
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${duration.inMinutes}m';
  }

  /// Purpose: Format an intimacy toy cost amount for display.
  /// Inputs: `amount`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Toy prices currently use the same plain dollar display as toy subtitles.
  String _formatMoney(double amount) => '\$${amount.toStringAsFixed(2)}';

  /// Purpose: Build the top summary card for this filtered record set.
  /// Inputs: `theme`, `records`, optional `toy`.
  /// Returns: `Widget`.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Toy detail pages include cost metrics beside record averages.
  Widget _buildSummaryCard(
    ThemeData theme,
    List<IntimacyRecord> records, {
    Toy? toy,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final avgPleasure = records.isEmpty
        ? null
        : records.fold<int>(0, (sum, record) => sum + record.pleasureLevel) /
              records.length;
    final avgDuration = records.isEmpty
        ? null
        : Duration(
            seconds:
                (records.fold<int>(
                          0,
                          (sum, record) => sum + record.duration.inSeconds,
                        ) /
                        records.length)
                    .round(),
          );
    final metrics = [
      (
        label: l10n.intimacyAvgPleasure,
        value: avgPleasure == null
            ? '-'
            : '${avgPleasure.toStringAsFixed(1)}/5',
      ),
      (
        label: l10n.intimacyAvgDuration,
        value: avgDuration == null ? '-' : _formatDuration(avgDuration),
      ),
      if (toy != null)
        (
          label: l10n.intimacyTotalCost,
          value: toy.hasCostData ? _formatMoney(toy.totalCost()) : '-',
        ),
      if (toy != null)
        (
          label: l10n.intimacyDailyCost,
          value: toy.averageDailyCost() == null
              ? '-'
              : _formatMoney(toy.averageDailyCost()!),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.intimacyRecordCount(records.length),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720
                      ? math.min(metrics.length, 4)
                      : constraints.maxWidth >= 360
                      ? math.min(metrics.length, 2)
                      : 1;
                  final itemWidth =
                      (constraints.maxWidth - (columns - 1) * 16) / columns;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 14,
                    children: [
                      for (final metric in metrics)
                        SizedBox(
                          width: itemWidth,
                          child: _buildSummaryMetric(
                            theme,
                            metric.label,
                            metric.value,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Purpose: Build one summary metric inside the detail summary card.
  /// Inputs: `theme`, `label`, `value`.
  /// Returns: `Widget`.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Internal helper used within this file only.
  Widget _buildSummaryMetric(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Purpose: Build a dismissible record row for this filtered detail page.
  /// Inputs: `record`.
  /// Returns: `Widget`.
  /// Side effects: May trigger edit or delete flows.
  /// Notes: Mirrors the main intimacy record list behavior.
  Widget _buildRecordDismissible(IntimacyRecord record) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: theme.colorScheme.primary,
        child: Icon(Icons.edit_outlined, color: theme.colorScheme.onPrimary),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editRecord(record);
          return false;
        }
        return confirmDelete(
          context,
          AppLocalizations.of(context)!.commonThisRecord,
        );
      },
      onDismissed: (_) => _deleteRecord(record),
      child: _RecordTile(
        record: record,
        partner: record.partnerId != null
            ? widget.partners
                  .where((partner) => partner.id == record.partnerId)
                  .firstOrNull
            : null,
        toys: record.toyIds
            .map((id) => widget.toys.where((toy) => toy.id == id).firstOrNull)
            .whereType<Toy>()
            .toList(),
        positions: record.positionIds
            .map(
              (id) => widget.positions
                  .where((position) => position.id == id)
                  .firstOrNull,
            )
            .whereType<Position>()
            .toList(),
      ),
    );
  }

  /// Purpose: Build grouped record list widgets for this filtered detail page.
  /// Inputs: `theme`, `records`, and `weekStartDay`.
  /// Returns: `List<Widget>`.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Uses the same configurable week grouping style as the main intimacy history.
  List<Widget> _buildRecordListWidgets(
    ThemeData theme,
    List<IntimacyRecord> records,
    int weekStartDay,
  ) {
    final groups = groupByWeek(
      records,
      (record) => record.datetime,
      descending: true,
      weekStartDay: weekStartDay,
    );
    return [
      for (final group in groups) ...[
        _buildWeekHeader(theme, group),
        ...group.items.map(_buildRecordDismissible),
      ],
    ];
  }

  /// Purpose: Build an ISO-week header for a filtered record group.
  /// Inputs: `theme`, `group`.
  /// Returns: `Widget`.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Internal helper used within this file only.
  Widget _buildWeekHeader(ThemeData theme, WeekGroup<IntimacyRecord> group) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
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

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_hasBodyTab) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title), centerTitle: true),
        body: _buildRecordsListView(context),
        floatingActionButton: FloatingActionButton(
          onPressed: _addRecord,
          child: const Icon(Icons.add),
        ),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              centerTitle: true,
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.intimacyTabRecords),
                  Tab(text: l10n.intimacyBody),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildRecordsListView(context),
                _buildBodyTab(context),
              ],
            ),
            floatingActionButton: AnimatedBuilder(
              animation: tabController,
              builder: (context, _) => tabController.index == 0
                  ? FloatingActionButton(
                      onPressed: _addRecord,
                      child: const Icon(Icons.add),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }

  /// Purpose: Build the existing summary/trend/record-list scroll view.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Shared by the plain toy layout and the partner Records tab.
  Widget _buildRecordsListView(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);
    final records = _filteredRecords;
    final selectedToy = _selectedToy;
    return ListView(
      children: [
        _buildSummaryCard(theme, records, toy: selectedToy),
        if (records.length >= 2) _FilteredRecordsTrendSection(records: records),
        const Divider(height: 1),
        if (records.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                l10n.intimacyNoRecords,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ..._buildRecordListWidgets(theme, records, settings.weekStartDay),
        const SizedBox(height: 80),
      ],
    );
  }

  /// Purpose: Build the partner Body tab hosting the shared body section.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Partner body data stays on the partner and is never synced to
  /// the Weight module; edits bump the partner record for LWW sync.
  Widget _buildBodyTab(BuildContext context) {
    final partner = _partner!;
    final allPartnerIds = widget.partners.map((p) => p.id).toList()..sort();
    return ListView(
      children: [
        BodySectionView(
          mode: BodySectionMode.partner,
          profile: partner.body,
          personId: partner.id,
          personColor: cyclePersonColor(
            personId: partner.id,
            allPartnerIdsSorted: allPartnerIds,
          ),
          cycleRecords: _cycleRecords,
          onProfileChanged: (profile) {
            final updated = partner.copyWith(
              body: profile.isEmpty ? null : profile,
              clearBody: profile.isEmpty,
            );
            if (mounted) {
              setState(() => _partner = updated);
            } else {
              _partner = updated;
            }
            widget.onPartnerChanged!(updated);
          },
          onCycleRecordsChanged: (records) {
            if (mounted) {
              setState(() => _cycleRecords = List.of(records));
            } else {
              _cycleRecords = List.of(records);
            }
            widget.onCycleRecordsChanged!(records);
          },
        ),
      ],
    );
  }
}

class _ToyCostOverviewPage extends StatefulWidget {
  final List<Toy> toys;

  /// Purpose: Create an aggregate toy-cost overview page instance.
  /// Inputs: `toys`.
  /// Returns: A new `_ToyCostOverviewPage` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _ToyCostOverviewPage({required this.toys});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<_ToyCostOverviewPage> createState() => _ToyCostOverviewPageState();
}

class _ToyCostOverviewPageState extends State<_ToyCostOverviewPage> {
  _ToyCostScope _scope = _ToyCostScope.all;
  _IntimacyChartRange _chartRange = _IntimacyChartRange.oneYear;

  /// Purpose: Return toys included in the current cost scope.
  /// Inputs: None.
  /// Returns: `List<Toy>`.
  /// Side effects: None.
  /// Notes: Scope filtering is independent from the management page's visual sort mode.
  List<Toy> get _selectedToys => switch (_scope) {
    _ToyCostScope.all => widget.toys,
    _ToyCostScope.active =>
      widget.toys.where((toy) => toy.retiredDate == null).toList(),
    _ToyCostScope.retired =>
      widget.toys.where((toy) => toy.retiredDate != null).toList(),
  };

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Retired scope shows finalized costs only, not a trend chart.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final selectedToys = _selectedToys;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.intimacyToyCosts), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildScopeSelector(l10n),
          const SizedBox(height: 12),
          _buildSummaryCard(theme, l10n, selectedToys),
          const SizedBox(height: 12),
          if (_scope == _ToyCostScope.retired)
            _buildFinalizedCostNote(theme, l10n)
          else
            _buildTrendCard(theme, l10n, selectedToys),
        ],
      ),
    );
  }

  /// Purpose: Build the all/active/retired scope selector.
  /// Inputs: `l10n`.
  /// Returns: `Widget`.
  /// Side effects: May update local scope state.
  /// Notes: Active and retired labels reuse the existing toy section labels.
  Widget _buildScopeSelector(AppLocalizations l10n) {
    return SegmentedButton<_ToyCostScope>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(value: _ToyCostScope.all, label: Text(l10n.weightAll)),
        ButtonSegment(
          value: _ToyCostScope.active,
          label: Text(l10n.intimacyActiveToys),
        ),
        ButtonSegment(
          value: _ToyCostScope.retired,
          label: Text(l10n.intimacyRetiredToys),
        ),
      ],
      selected: {_scope},
      onSelectionChanged: (selection) {
        setState(() => _scope = selection.first);
      },
    );
  }

  /// Purpose: Build the current scope's aggregate cost summary card.
  /// Inputs: `theme`, `l10n`, `toys`.
  /// Returns: `Widget`.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Total cost includes undated toys; daily cost only includes dated toys.
  Widget _buildSummaryCard(
    ThemeData theme,
    AppLocalizations l10n,
    List<Toy> toys,
  ) {
    final dailyCost = _totalDailyCost(toys);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _scopeLabel(l10n, _scope),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCostMetric(
                    theme,
                    l10n.intimacyTotalCost,
                    _moneyText(_totalCost(toys)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCostMetric(
                    theme,
                    l10n.intimacyDailyCost,
                    dailyCost == null ? '-' : _moneyText(dailyCost),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Build a compact aggregate cost metric column.
  /// Inputs: `theme`, `label`, `value`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Widget _buildCostMetric(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  /// Purpose: Build the retired-cost finalized note.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Retired toys do not render a future trend because their cost is fixed.
  Widget _buildFinalizedCostNote(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l10n.intimacyRetiredCostFinalized,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Purpose: Build the aggregate daily-cost trend card.
  /// Inputs: `theme`, `l10n`, `toys`.
  /// Returns: `Widget`.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: All scope treats retired toy daily costs as finalized fixed values.
  Widget _buildTrendCard(
    ThemeData theme,
    AppLocalizations l10n,
    List<Toy> toys,
  ) {
    final labels = {
      _IntimacyChartRange.oneWeek: '1W',
      _IntimacyChartRange.oneMonth: '1M',
      _IntimacyChartRange.threeMonths: '3M',
      _IntimacyChartRange.sixMonths: '6M',
      _IntimacyChartRange.oneYear: '1Y',
      _IntimacyChartRange.all: l10n.weightAll,
    };
    final today = _dateOnly(DateTime.now());
    final historyStart = _historyStart(today, toys);
    final futureEnd = _futureEnd(today, historyStart, toys);
    final dates = _timeline(historyStart, today, futureEnd, toys);
    final trendData = _buildTrendData(dates, today, toys);
    final hasData =
        trendData.historySpots.isNotEmpty || trendData.futureSpots.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.intimacyCostTrend,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final entry in labels.entries)
                  ChoiceChip(
                    label: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _chartRange == entry.key,
                    onSelected: (_) => setState(() => _chartRange = entry.key),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasData)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    l10n.intimacyChartNoData,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              _buildCostChart(theme, l10n, trendData),
          ],
        ),
      ),
    );
  }

  /// Purpose: Build the aggregate daily-cost line chart.
  /// Inputs: `theme`, `l10n`, `trendData`.
  /// Returns: `Widget`.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Values use a log scale so early high daily cost does not flatten later points.
  Widget _buildCostChart(
    ThemeData theme,
    AppLocalizations l10n,
    _ToyCostTrendData trendData,
  ) {
    final series = [
      (
        label: l10n.intimacyCostHistory,
        color: theme.colorScheme.primary,
        spots: trendData.historySpots,
        dashed: false,
      ),
      (
        label: l10n.intimacyCostProjection,
        color: theme.colorScheme.primary,
        spots: trendData.futureSpots,
        dashed: true,
      ),
    ].where((item) => item.spots.isNotEmpty).toList();
    final allSpots = series.expand((item) => item.spots).toList();
    final minX = allSpots.map((spot) => spot.x).reduce(math.min);
    final maxX = allSpots.map((spot) => spot.x).reduce(math.max);
    final xPadding = minX == maxX ? const Duration(days: 1).inMilliseconds : 0;
    final bounds = _chartBounds(trendData.minY, trendData.maxY);
    final transformedMinY = _logTransform(bounds.minY);
    final transformedMaxY = _logTransform(bounds.maxY);
    final yRange = transformedMaxY - transformedMinY;
    final horizontalInterval = yRange > 0 ? yRange / 4 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            for (final item in series)
              _legendLine(item.color, item.label, item.dashed),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: minX - xPadding,
              maxX: maxX + xPadding,
              minY: transformedMinY,
              maxY: transformedMaxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: horizontalInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: _dateInterval(minX, maxX),
                    minIncluded: false,
                    maxIncluded: false,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        value.toInt(),
                      );
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          _dateLabel(date, minX, maxX, l10n.localeName),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: horizontalInterval,
                    getTitlesWidget: (value, meta) {
                      if (value == transformedMinY ||
                          value == transformedMaxY) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          _axisText(_logInverse(value)),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              lineBarsData: [
                for (final item in series)
                  LineChartBarData(
                    spots: [
                      for (final spot in item.spots)
                        FlSpot(spot.x, _logTransform(spot.y)),
                    ],
                    isCurved: item.spots.length > 2,
                    curveSmoothness: 0.16,
                    preventCurveOverShooting: true,
                    color: item.color,
                    barWidth: 2.5,
                    dashArray: item.dashed ? [7, 5] : null,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: !item.dashed,
                      color: item.color.withAlpha(20),
                    ),
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((spot) {
                    final item = series[spot.barIndex];
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      spot.x.toInt(),
                    );
                    return LineTooltipItem(
                      '${DateFormat('MMM d', l10n.localeName).format(date)}\n'
                      '${item.label}: ${_moneyText(_logInverse(spot.y))}',
                      TextStyle(
                        color: item.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Purpose: Build a compact line legend marker.
  /// Inputs: `color`, `label`, `dashed`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Matches the solid/history and dashed/projection chart styles.
  Widget _legendLine(Color color, String label, bool dashed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 2,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(1),
          ),
          child: dashed
              ? Row(
                  children: [
                    Container(width: 7, color: color),
                    const SizedBox(width: 4),
                    Container(width: 7, color: color),
                  ],
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// Purpose: Build the daily-cost spots for the selected time range.
  /// Inputs: `dates`, `today`, `toys`.
  /// Returns: `_ToyCostTrendData`.
  /// Side effects: None.
  /// Notes: The current day is included in both history and projection lines.
  _ToyCostTrendData _buildTrendData(
    List<DateTime> dates,
    DateTime today,
    List<Toy> toys,
  ) {
    final historySpots = <FlSpot>[];
    final futureSpots = <FlSpot>[];
    final values = <double>[];

    for (final date in dates) {
      final value = _dailyCostAt(date, toys);
      if (value == null) continue;
      values.add(value);
      final spot = FlSpot(date.millisecondsSinceEpoch.toDouble(), value);
      if (!date.isAfter(today)) historySpots.add(spot);
      if (!date.isBefore(today)) futureSpots.add(spot);
    }

    if (values.isEmpty) {
      return const _ToyCostTrendData(
        historySpots: [],
        futureSpots: [],
        minY: 0,
        maxY: 0,
      );
    }

    return _ToyCostTrendData(
      historySpots: historySpots,
      futureSpots: futureSpots,
      minY: values.reduce(math.min),
      maxY: values.reduce(math.max),
    );
  }

  /// Purpose: Calculate aggregate average daily cost on a specific date.
  /// Inputs: `date`, `toys`.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Returns null until at least one included toy can be costed for that date.
  double? _dailyCostAt(DateTime date, List<Toy> toys) {
    var total = 0.0;
    var hasValue = false;
    for (final toy in toys) {
      final value = _toyDailyCostAt(toy, date);
      if (value == null) continue;
      hasValue = true;
      total += value;
    }
    return hasValue ? total : null;
  }

  /// Purpose: Calculate one toy's average daily cost on a specific date.
  /// Inputs: `toy`, `date`.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Retired toys contribute their finalized daily cost in all-scope trends.
  double? _toyDailyCostAt(Toy toy, DateTime date) {
    if (!toy.hasCostData || toy.purchaseDate == null) return null;
    final purchaseDate = _dateOnly(toy.purchaseDate!);
    if (date.isBefore(purchaseDate)) return null;
    if (_scope == _ToyCostScope.all && toy.retiredDate != null) {
      return toy.averageDailyCost();
    }
    var serviceEnd = date;
    if (toy.retiredDate != null) {
      final retiredDate = _dateOnly(toy.retiredDate!);
      if (retiredDate.isBefore(serviceEnd)) serviceEnd = retiredDate;
    }
    if (serviceEnd.isBefore(purchaseDate)) return null;
    final days = serviceEnd.difference(purchaseDate).inDays + 1;
    return toy.totalCost() / math.max(1, days);
  }

  /// Purpose: Return the first date shown for the selected cost range.
  /// Inputs: `today`, `toys`.
  /// Returns: `DateTime`.
  /// Side effects: None.
  /// Notes: The all range starts at the earliest purchase date when available.
  DateTime _historyStart(DateTime today, List<Toy> toys) {
    final start = switch (_chartRange) {
      _IntimacyChartRange.oneWeek => today.subtract(const Duration(days: 7)),
      _IntimacyChartRange.oneMonth => DateTime(
        today.year,
        today.month - 1,
        today.day,
      ),
      _IntimacyChartRange.threeMonths => DateTime(
        today.year,
        today.month - 3,
        today.day,
      ),
      _IntimacyChartRange.sixMonths => DateTime(
        today.year,
        today.month - 6,
        today.day,
      ),
      _IntimacyChartRange.oneYear => DateTime(
        today.year - 1,
        today.month,
        today.day,
      ),
      _IntimacyChartRange.all =>
        _earliestPurchaseDate(toys) ??
            DateTime(today.year - 1, today.month, today.day),
    };
    return start.isAfter(today) ? today : start;
  }

  /// Purpose: Return the projected end date for the selected cost range.
  /// Inputs: `today`, `historyStart`, `toys`.
  /// Returns: `DateTime`.
  /// Side effects: None.
  /// Notes: Mirrors MyDevice by projecting forward for the same range length.
  DateTime _futureEnd(DateTime today, DateTime historyStart, List<Toy> toys) {
    final days = today.difference(historyStart).inDays.abs();
    var futureEnd = today.add(Duration(days: math.max(days, 30)));
    for (final toy in toys) {
      final purchaseDate = toy.purchaseDate == null
          ? null
          : _dateOnly(toy.purchaseDate!);
      if (purchaseDate != null && purchaseDate.isAfter(futureEnd)) {
        futureEnd = purchaseDate.add(const Duration(days: 30));
      }
    }
    return futureEnd;
  }

  /// Purpose: Return the earliest purchase date in a toy collection.
  /// Inputs: `toys`.
  /// Returns: `DateTime?`.
  /// Side effects: None.
  /// Notes: Only dated toys can anchor the all-range chart.
  DateTime? _earliestPurchaseDate(List<Toy> toys) {
    DateTime? earliest;
    for (final toy in toys) {
      final purchaseDate = toy.purchaseDate;
      if (purchaseDate == null) continue;
      final date = _dateOnly(purchaseDate);
      if (earliest == null || date.isBefore(earliest)) earliest = date;
    }
    return earliest;
  }

  /// Purpose: Create sampled dates for the selected cost range.
  /// Inputs: `historyStart`, `today`, `futureEnd`, `toys`.
  /// Returns: `List<DateTime>`.
  /// Side effects: None.
  /// Notes: Purchase, retirement, today, and end dates are always included.
  List<DateTime> _timeline(
    DateTime historyStart,
    DateTime today,
    DateTime futureEnd,
    List<Toy> toys,
  ) {
    final totalDays = math.max(1, futureEnd.difference(historyStart).inDays);
    final step = totalDays <= 240
        ? const Duration(days: 1)
        : totalDays <= 1800
        ? const Duration(days: 7)
        : const Duration(days: 30);
    final dates = <DateTime>[];
    for (
      var date = historyStart;
      !date.isAfter(futureEnd);
      date = date.add(step)
    ) {
      dates.add(_dateOnly(date));
    }
    dates.add(today);
    dates.add(futureEnd);
    for (final toy in toys) {
      if (toy.purchaseDate != null) dates.add(_dateOnly(toy.purchaseDate!));
      if (toy.retiredDate != null) dates.add(_dateOnly(toy.retiredDate!));
    }
    dates.sort();

    final deduped = <DateTime>[];
    for (final date in dates) {
      if (deduped.isEmpty || deduped.last != date) deduped.add(date);
    }
    return deduped;
  }

  /// Purpose: Return a date-only value for day-based cost calculations.
  /// Inputs: `date`.
  /// Returns: `DateTime`.
  /// Side effects: None.
  /// Notes: Keeps cost days stable regardless of the original timestamp.
  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Purpose: Return padded chart bounds for daily-cost values.
  /// Inputs: `minY`, `maxY`.
  /// Returns: A min/max record.
  /// Side effects: None.
  /// Notes: Keeps flat zero-cost charts visible.
  ({double minY, double maxY}) _chartBounds(double minY, double maxY) {
    if (minY == maxY) {
      final padding = minY.abs() * 0.1;
      final safePadding = padding == 0 ? 1.0 : padding;
      return (minY: math.min(0, minY - safePadding), maxY: maxY + safePadding);
    }

    final padding = (maxY - minY).abs() * 0.1;
    return (minY: math.min(0, minY - padding), maxY: maxY + padding);
  }

  /// Purpose: Transform a cost value for log-scale charting.
  /// Inputs: `value`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Supports zero and negative values without infinities.
  double _logTransform(double value) {
    if (value == 0) return 0;
    final sign = value < 0 ? -1 : 1;
    return sign * math.log(value.abs() + 1) / math.ln10;
  }

  /// Purpose: Convert a log-scale chart value back to cost.
  /// Inputs: `value`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Mirrors `_logTransform` for labels and tooltips.
  double _logInverse(double value) {
    if (value == 0) return 0;
    final sign = value < 0 ? -1 : 1;
    return (sign * (math.pow(10, value.abs()) - 1)).toDouble();
  }

  /// Purpose: Return a bottom-axis date interval in milliseconds.
  /// Inputs: `minX`, `maxX`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Uses broad thresholds to avoid crowded date labels.
  double _dateInterval(double minX, double maxX) {
    final spanDays = (maxX - minX).abs() / (86400 * 1000);
    const day = 86400 * 1000.0;
    if (spanDays <= 7) return 2 * day;
    if (spanDays <= 30) return 7 * day;
    if (spanDays <= 90) return 21 * day;
    if (spanDays <= 180) return 45 * day;
    if (spanDays <= 365) return 90 * day;
    if (spanDays <= 730) return 180 * day;
    return 365 * day;
  }

  /// Purpose: Format a chart date-axis label.
  /// Inputs: `date`, `minX`, `maxX`, `localeName`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Uses years for long ranges and month/day for shorter ranges.
  String _dateLabel(
    DateTime date,
    double minX,
    double maxX,
    String localeName,
  ) {
    final spanDays = (maxX - minX).abs() / (86400 * 1000);
    final formatter = spanDays > 730
        ? DateFormat('yyyy', localeName)
        : spanDays > 365
        ? DateFormat('M/yy', localeName)
        : DateFormat('M/d', localeName);
    return formatter.format(date);
  }

  /// Purpose: Format a money amount for chart tooltips.
  /// Inputs: `amount`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Toy prices currently use plain dollar display.
  String _moneyText(double amount) => '\$${amount.toStringAsFixed(2)}';

  /// Purpose: Format a compact axis value.
  /// Inputs: `value`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Keeps large costs readable on narrow left axes.
  String _axisText(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 1000000) return '$sign${(abs / 1000000).toStringAsFixed(1)}m';
    if (abs >= 1000) return '$sign${(abs / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  /// Purpose: Sum total recorded toy costs.
  /// Inputs: `toys`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Toys without a price contribute zero.
  double _totalCost(List<Toy> toys) =>
      toys.fold(0.0, (sum, toy) => sum + toy.totalCost());

  /// Purpose: Sum average daily costs when they can be calculated.
  /// Inputs: `toys`.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Returns null when no toy has both price and purchase date.
  double? _totalDailyCost(List<Toy> toys) {
    var total = 0.0;
    var hasDailyCost = false;
    for (final toy in toys) {
      final dailyCost = toy.averageDailyCost();
      if (dailyCost == null) continue;
      hasDailyCost = true;
      total += dailyCost;
    }
    return hasDailyCost ? total : null;
  }

  /// Purpose: Return the localized label for a toy-cost scope.
  /// Inputs: `l10n`, `scope`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  String _scopeLabel(AppLocalizations l10n, _ToyCostScope scope) {
    return switch (scope) {
      _ToyCostScope.all => l10n.weightAll,
      _ToyCostScope.active => l10n.intimacyActiveToys,
      _ToyCostScope.retired => l10n.intimacyRetiredToys,
    };
  }
}

class _ToyCostTrendData {
  final List<FlSpot> historySpots;
  final List<FlSpot> futureSpots;
  final double minY;
  final double maxY;

  /// Purpose: Create toy cost trend data for chart rendering.
  /// Inputs: History/future spots and y-axis bounds.
  /// Returns: A new `_ToyCostTrendData` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _ToyCostTrendData({
    required this.historySpots,
    required this.futureSpots,
    required this.minY,
    required this.maxY,
  });
}

class _FilteredRecordsTrendSection extends StatefulWidget {
  final List<IntimacyRecord> records;

  /// Purpose: Create a filtered record trend section instance.
  /// Inputs: `records`.
  /// Returns: A new `_FilteredRecordsTrendSection` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _FilteredRecordsTrendSection({required this.records});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<_FilteredRecordsTrendSection> createState() =>
      _FilteredRecordsTrendSectionState();
}

class _FilteredRecordsTrendSectionState
    extends State<_FilteredRecordsTrendSection> {
  _IntimacyChartRange _chartRange = _IntimacyChartRange.threeMonths;

  /// Purpose: Return chart records for the current selected range.
  /// Inputs: None.
  /// Returns: `List<IntimacyRecord>`.
  /// Side effects: None.
  /// Notes: The source records are already filtered to the current partner or toy.
  List<IntimacyRecord> get _chartRecords {
    final now = DateTime.now();
    final cutoff = switch (_chartRange) {
      _IntimacyChartRange.oneWeek => now.subtract(const Duration(days: 7)),
      _IntimacyChartRange.oneMonth => DateTime(
        now.year,
        now.month - 1,
        now.day,
      ),
      _IntimacyChartRange.threeMonths => DateTime(
        now.year,
        now.month - 3,
        now.day,
      ),
      _IntimacyChartRange.sixMonths => DateTime(
        now.year,
        now.month - 6,
        now.day,
      ),
      _IntimacyChartRange.oneYear => DateTime(now.year - 1, now.month, now.day),
      _IntimacyChartRange.all => DateTime(2000),
    };
    return widget.records.where((r) => r.datetime.isAfter(cutoff)).toList()
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
  }

  /// Purpose: Build EWMA smoothed pleasure spots for a filtered chart.
  /// Inputs: `allData`, `visibleFrom`, `halfLifeDays`.
  /// Returns: `List<FlSpot>`.
  /// Side effects: None.
  /// Notes: Uses earlier records for warm-up but only emits visible-range spots.
  List<FlSpot> _buildEwmaPleasureSpots(
    List<IntimacyRecord> allData,
    DateTime visibleFrom, {
    double halfLifeDays = 7,
  }) {
    final validData = allData
        .where((record) => record.pleasureLevel > 0)
        .toList();
    if (validData.isEmpty) return [];
    final tau = halfLifeDays * 86400 * 1000;
    final spots = <FlSpot>[];
    double ewma = validData.first.pleasureLevel.toDouble();
    DateTime prevTime = validData.first.datetime;

    for (final record in validData) {
      final dtMs = record.datetime
          .difference(prevTime)
          .inMilliseconds
          .toDouble();
      final alpha = 1.0 - math.exp(-dtMs / tau);
      ewma = alpha * record.pleasureLevel + (1 - alpha) * ewma;
      if (!record.datetime.isBefore(visibleFrom)) {
        spots.add(
          FlSpot(record.datetime.millisecondsSinceEpoch.toDouble(), ewma),
        );
      }
      prevTime = record.datetime;
    }
    return spots;
  }

  /// Purpose: Build EWMA smoothed duration spots for a filtered chart.
  /// Inputs: `allData`, `visibleFrom`, `halfLifeDays`.
  /// Returns: `List<FlSpot>`.
  /// Side effects: None.
  /// Notes: Durations are charted in minutes.
  List<FlSpot> _buildEwmaDurationSpots(
    List<IntimacyRecord> allData,
    DateTime visibleFrom, {
    double halfLifeDays = 7,
  }) {
    final validData = allData
        .where((record) => record.duration.inSeconds > 0)
        .toList();
    if (validData.isEmpty) return [];
    final tau = halfLifeDays * 86400 * 1000;
    final spots = <FlSpot>[];
    double ewma = validData.first.duration.inSeconds / 60.0;
    DateTime prevTime = validData.first.datetime;

    for (final record in validData) {
      final dtMs = record.datetime
          .difference(prevTime)
          .inMilliseconds
          .toDouble();
      final alpha = 1.0 - math.exp(-dtMs / tau);
      final durationMin = record.duration.inSeconds / 60.0;
      ewma = alpha * durationMin + (1 - alpha) * ewma;
      if (!record.datetime.isBefore(visibleFrom)) {
        spots.add(
          FlSpot(record.datetime.millisecondsSinceEpoch.toDouble(), ewma),
        );
      }
      prevTime = record.datetime;
    }
    return spots;
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Uses high-contrast fixed colors for combined trend series.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
    final allSorted = List<IntimacyRecord>.from(widget.records)
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
    final cutoff = data.isNotEmpty ? data.first.datetime : DateTime.now();
    final pleasureData = data
        .where((record) => record.pleasureLevel > 0)
        .toList();
    final durationData = data
        .where((record) => record.duration.inSeconds > 0)
        .toList();
    final thrustData = data
        .where((record) => _recordThrustCount(record) != null)
        .toList();
    final rawPleasureSpots = pleasureData
        .map(
          (record) => FlSpot(
            record.datetime.millisecondsSinceEpoch.toDouble(),
            record.pleasureLevel.toDouble(),
          ),
        )
        .toList();
    final pleasureSpots = _buildEwmaPleasureSpots(allSorted, cutoff);
    final rawDurationSpots = durationData
        .map(
          (record) => FlSpot(
            record.datetime.millisecondsSinceEpoch.toDouble(),
            record.duration.inSeconds / 60.0,
          ),
        )
        .toList();
    final durationSpots = _buildEwmaDurationSpots(allSorted, cutoff);
    final rawThrustSpots = thrustData
        .map(
          (record) => FlSpot(
            record.datetime.millisecondsSinceEpoch.toDouble(),
            _recordThrustCount(record)!,
          ),
        )
        .toList();
    final thrustSpots = _buildEwmaThrustCountSpots(allSorted, cutoff);
    final hasDurationOrThrustData =
        rawDurationSpots.length >= 2 ||
        durationSpots.length >= 2 ||
        rawThrustSpots.length >= 2 ||
        thrustSpots.length >= 2;

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
              ...labels.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ChoiceChip(
                    label: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _chartRange == entry.key,
                    onSelected: (_) => setState(() => _chartRange = entry.key),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendItem(
                theme.colorScheme.primary,
                theme.textTheme.labelSmall,
                l10n.intimacyPleasure,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: data.length < 2
                ? Center(
                    child: Text(
                      l10n.intimacyChartNoData,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : _buildPleasureChart(
                    theme,
                    rawPleasureSpots,
                    pleasureSpots,
                    data,
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendItem(
                _intimacyDurationChartColor,
                theme.textTheme.labelSmall,
                l10n.intimacyDuration,
              ),
              const SizedBox(width: 16),
              _legendItem(
                _intimacyThrustChartColor,
                theme.textTheme.labelSmall,
                l10n.intimacyThrustCount,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: !hasDurationOrThrustData
                ? Center(
                    child: Text(
                      l10n.intimacyChartNoData,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : _buildDurationChart(
                    theme,
                    rawDurationSpots,
                    durationSpots,
                    rawThrustSpots,
                    thrustSpots,
                    data,
                  ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  /// Purpose: Build the filtered pleasure trend chart.
  /// Inputs: `theme`, `rawPleasureSpots`, `pleasureSpots`, `data`.
  /// Returns: `Widget`.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Raw values are solid and EWMA values are dashed, matching the main chart style.
  Widget _buildPleasureChart(
    ThemeData theme,
    List<FlSpot> rawPleasureSpots,
    List<FlSpot> pleasureSpots,
    List<IntimacyRecord> data,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = l10n.localeName;
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
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                final spanDays = data.last.datetime
                    .difference(data.first.datetime)
                    .inDays;
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
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${value.toInt()}',
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                  ),
                );
              },
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
        minY: 0,
        maxY: 5.5,
        lineBarsData: [
          LineChartBarData(
            spots: rawPleasureSpots,
            isCurved: false,
            color: theme.colorScheme.primary.withValues(alpha: 0.45),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: pleasureSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: theme.colorScheme.primary,
            barWidth: 2.5,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.asMap().entries.map((entry) {
                if (entry.key == 0) return null;
                final spot = entry.value;
                final date = DateTime.fromMillisecondsSinceEpoch(
                  spot.x.toInt(),
                );
                return LineTooltipItem(
                  '${l10n.intimacyPleasure}: ${spot.y.toStringAsFixed(1)}\n${DateFormat('MMM d', localeName).format(date)}',
                  TextStyle(
                    color: theme.colorScheme.onPrimary,
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

  /// Purpose: Build the filtered duration trend chart.
  /// Inputs: `theme`, duration spots, thrust-count spots, and `data`.
  /// Returns: `Widget`.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Duration and thrust-count series use fixed high-contrast colors.
  Widget _buildDurationChart(
    ThemeData theme,
    List<FlSpot> rawDurationSpots,
    List<FlSpot> durationSpots,
    List<FlSpot> rawThrustSpots,
    List<FlSpot> thrustSpots,
    List<IntimacyRecord> data,
  ) {
    final allDurationSpots = [...durationSpots, ...rawDurationSpots];
    final maxMinutes = allDurationSpots.isEmpty
        ? 30.0
        : allDurationSpots.map((spot) => spot.y).reduce(math.max);
    final allThrustSpots = [...thrustSpots, ...rawThrustSpots];
    final maxThrust = allThrustSpots.isEmpty
        ? 100.0
        : allThrustSpots.map((spot) => spot.y).reduce(math.max);

    /// Purpose: Return a rounded-up duration ceiling for chart labels.
    /// Inputs: `value`.
    /// Returns: `double`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    double minuteCeil(double value) {
      const steps = [5.0, 10.0, 15.0, 20.0, 30.0, 45.0, 60.0, 90.0, 120.0];
      for (final step in steps) {
        if (step >= value) return step;
      }
      return (value / 30).ceil() * 30.0;
    }

    /// Purpose: Return a rounded-up thrust-count ceiling for chart labels.
    /// Inputs: `value`.
    /// Returns: `double`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    double thrustCeil(double value) {
      const steps = [100.0, 200.0, 300.0, 500.0, 800.0, 1000.0, 1500.0];
      for (final step in steps) {
        if (step >= value) return step;
      }
      return (value / 500).ceil() * 500.0;
    }

    final yMax = minuteCeil(math.max(maxMinutes * 1.15, 5.0));
    final thrustMax = thrustCeil(math.max(maxThrust * 1.1, 100.0));
    final l10n = AppLocalizations.of(context)!;
    final localeName = l10n.localeName;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
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
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                final spanDays = data.last.datetime
                    .difference(data.first.datetime)
                    .inDays;
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
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${value.toInt()}m',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: _intimacyDurationChartColor,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: allThrustSpots.isNotEmpty,
              reservedSize: 38,
              interval: math.max(yMax / 4, 1),
              getTitlesWidget: (value, meta) {
                final actual = value / yMax * thrustMax;
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    actual.toStringAsFixed(0),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: _intimacyThrustChartColor,
                    ),
                  ),
                );
              },
            ),
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
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: rawDurationSpots,
            isCurved: false,
            color: _intimacyDurationChartColor.withValues(alpha: 0.45),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: durationSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: _intimacyDurationChartColor,
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: _intimacyDurationChartColor.withValues(alpha: 0.08),
            ),
          ),
          LineChartBarData(
            spots: rawThrustSpots
                .map(
                  (spot) => FlSpot(
                    spot.x,
                    (spot.y.clamp(0, thrustMax) / thrustMax) * yMax,
                  ),
                )
                .toList(),
            isCurved: false,
            color: _intimacyThrustChartColor.withValues(alpha: 0.45),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: thrustSpots
                .map((spot) => FlSpot(spot.x, (spot.y / thrustMax) * yMax))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: _intimacyThrustChartColor,
            barWidth: 2,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => spot.barIndex == 3
                ? _intimacyThrustChartColor
                : _intimacyDurationChartColor,
            getTooltipItems: (spots) {
              return spots.asMap().entries.map((entry) {
                final spot = entry.value;
                final date = DateTime.fromMillisecondsSinceEpoch(
                  spot.x.toInt(),
                );
                if (spot.barIndex == 1) {
                  return LineTooltipItem(
                    '${l10n.intimacyDuration}: ${spot.y.toStringAsFixed(1)}min\n${DateFormat('MMM d', localeName).format(date)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                } else if (spot.barIndex == 3) {
                  final actual = spot.y / yMax * thrustMax;
                  return LineTooltipItem(
                    '${l10n.intimacyThrustCount}: ${actual.toStringAsFixed(0)}\n${DateFormat('MMM d', localeName).format(date)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Purpose: Build a legend item for the filtered charts.
  /// Inputs: `color`, `labelStyle`, `label`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Matches the main intimacy chart legend style.
  Widget _legendItem(Color color, TextStyle? labelStyle, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 2, color: color),
        const SizedBox(width: 2),
        Container(width: 4, height: 2, color: color.withValues(alpha: 0)),
        Container(width: 6, height: 2, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(label, style: labelStyle),
      ],
    );
  }

  /// Purpose: Return the chart date-axis interval for filtered charts.
  /// Inputs: `data`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Uses the same interval thresholds as the main intimacy charts.
  double _chartDateInterval(List<IntimacyRecord> data) {
    if (data.length < 2) return 1;
    final spanMs = data.last.datetime
        .difference(data.first.datetime)
        .inMilliseconds
        .toDouble();
    final spanDays = spanMs / (86400 * 1000);
    const day = 86400 * 1000.0;
    if (spanDays <= 7) return 2 * day;
    if (spanDays <= 30) return 7 * day;
    if (spanDays <= 90) return 21 * day;
    if (spanDays <= 180) return 45 * day;
    if (spanDays <= 365) return 90 * day;
    if (spanDays <= 730) return 180 * day;
    return 365 * day;
  }
}

// ─── Shared date picker tile ────────────────────────────────────────
class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  /// Purpose: Create a date picker tile instance.
  /// Inputs: None.
  /// Returns: A new `_DatePickerTile` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
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

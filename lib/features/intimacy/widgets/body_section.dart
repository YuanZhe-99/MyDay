import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/auto_sync_service.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../../todo/services/todo_storage.dart';
import '../../weight/models/weight_record.dart';
import '../../weight/services/weight_storage.dart';
import '../models/intimacy_record.dart';
import '../services/body_metrics.dart';
import '../services/cycle_predictor.dart';
import 'cycle_calendar.dart';

/// storage_config.json key for the local-only weight-sync warning opt-out.
const String bodyWeightSyncWarningDisabledKey =
    'intimacyBodyWeightSyncWarningDisabled';

/// Whether a body section edits the user's own profile or a partner's.
enum BodySectionMode { user, partner }

/// Purpose: Pick the stable cycle color for a person.
/// Inputs: `personId` (null = the user), `allPartnerIdsSorted`.
/// Returns: `Color`.
/// Side effects: None.
/// Notes: The user always takes palette slot 0; partners take slots by
/// their position among all partner ids sorted, so colors stay stable when
/// individual people toggle their calendar visibility.
Color cyclePersonColor({
  required String? personId,
  required List<String> allPartnerIdsSorted,
}) {
  if (personId == null) return cyclePersonPalette.first;
  final index = allPartnerIdsSorted.indexOf(personId);
  final slots = cyclePersonPalette.length - 1;
  return cyclePersonPalette[1 + ((index < 0 ? 0 : index) % slots)];
}

/// Shared body-record section used by the user's Body page and the
/// partner details Body tab. Renders measurement, bra, cycle, and PSI
/// cards; every field is optional and auto-saved.
class BodySectionView extends ConsumerStatefulWidget {
  final BodySectionMode mode;
  final BodyProfile? profile;

  /// null for the user; the partner id in partner mode.
  final String? personId;
  final Color personColor;
  final List<CycleRecord> cycleRecords;
  final ValueChanged<BodyProfile> onProfileChanged;
  final ValueChanged<List<CycleRecord>> onCycleRecordsChanged;

  /// Purpose: Create a body section view instance.
  /// Inputs: Mode, profile, person identity/color, cycle records, callbacks.
  /// Returns: A new `BodySectionView` instance.
  /// Side effects: None.
  /// Notes: In user mode bust/waist/hip mirror the Weight module's latest
  /// record and edits create new weight records; in partner mode they live
  /// on the partner's profile and never touch the Weight module.
  const BodySectionView({
    super.key,
    required this.mode,
    required this.profile,
    required this.personId,
    required this.personColor,
    required this.cycleRecords,
    required this.onProfileChanged,
    required this.onCycleRecordsChanged,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  ConsumerState<BodySectionView> createState() => _BodySectionViewState();
}

class _BodySectionViewState extends ConsumerState<BodySectionView> {
  double? _bust;
  double? _waist;
  double? _hip;

  bool _weightLoaded = false;
  bool _syncWarningDisabled = false;
  bool _syncWarningAcknowledged = false;
  Timer? _weightCommitTimer;
  bool _weightCommitPending = false;

  DateTime? _selectedCycleDate;

  BodyProfile get _profile => widget.profile ?? const BodyProfile();

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Loads weight data and the warning opt-out flag in user mode.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    if (widget.mode == BodySectionMode.user) {
      _loadUserMeasurements();
    } else {
      _bust = _profile.bustCm;
      _waist = _profile.waistCm;
      _hip = _profile.hipCm;
      _weightLoaded = true;
    }
  }

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Flushes a pending weight-record commit.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    _weightCommitTimer?.cancel();
    if (_weightCommitPending) {
      // Fire-and-forget: the page is going away but the burst must still
      // produce its weight record.
      _commitWeightRecord();
    }
    super.dispose();
  }

  /// Purpose: Load the latest weight measurement values and the warning flag.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Reads weight data and storage config, updates state.
  /// Notes: User mode only. Each of bust/waist/hip independently shows its
  /// most recent positive value, so a newer record missing a field falls
  /// back to the last earlier record that contains it.
  Future<void> _loadUserMeasurements() async {
    final data = await WeightStorage.load();
    final config = await TodoStorage.readConfig();
    if (!mounted) return;
    setState(() {
      final records = data?.records ?? const <WeightRecord>[];
      final latest = _latestRecord(records);
      final effective = latest != null
          ? WeightData.effectiveMeasurementsUpTo(records, latest.datetime)
          : null;
      _bust = effective?.bustCm;
      _waist = effective?.waistCm;
      _hip = effective?.hipCm;
      _syncWarningDisabled = config[bodyWeightSyncWarningDisabledKey] == true;
      _weightLoaded = true;
    });
  }

  /// Purpose: Return the newest weight record by datetime.
  /// Inputs: `records`.
  /// Returns: `WeightRecord?`.
  /// Side effects: None.
  /// Notes: Matches the weight page's latest-record ordering.
  WeightRecord? _latestRecord(List<WeightRecord> records) {
    if (records.isEmpty) return null;
    final sorted = List<WeightRecord>.of(records)
      ..sort((a, b) => b.datetime.compareTo(a.datetime));
    return sorted.first;
  }

  /// Purpose: Persist the warning opt-out flag to local storage config.
  /// Inputs: `disabled`.
  /// Returns: `Future<void>`.
  /// Side effects: Writes storage_config.json; never synced.
  /// Notes: Unchecking re-enables the warning for future edits.
  Future<void> _setSyncWarningDisabled(bool disabled) async {
    setState(() {
      _syncWarningDisabled = disabled;
      if (!disabled) _syncWarningAcknowledged = false;
    });
    final config = await TodoStorage.readConfig();
    config[bodyWeightSyncWarningDisabledKey] = disabled;
    await TodoStorage.writeConfig(config);
  }

  /// Purpose: Gate the first measurement edit behind the sync warning.
  /// Inputs: None.
  /// Returns: `Future<bool>` true when editing may proceed.
  /// Side effects: May show the warning dialog and persist the opt-out flag.
  /// Notes: Only used for bust/waist/hip in user mode.
  Future<bool> _confirmWeightSync() async {
    if (_syncWarningDisabled || _syncWarningAcknowledged) return true;
    final l10n = AppLocalizations.of(context)!;
    var dontRemind = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.intimacyBodyWeightSyncWarningTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.intimacyBodyWeightSyncWarning),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: dontRemind,
                onChanged: (v) =>
                    setDialogState(() => dontRemind = v ?? false),
                title: Text(l10n.intimacyBodyDontRemindAgain),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      _syncWarningAcknowledged = true;
      if (dontRemind) await _setSyncWarningDisabled(true);
      return true;
    }
    return false;
  }

  /// Purpose: Record a measurement change and schedule the weight commit.
  /// Inputs: `apply` mutation of the pending display values.
  /// Returns: None.
  /// Side effects: In user mode debounces one new weight record per editing
  /// burst; in partner mode pushes the profile immediately.
  /// Notes: Historical weight records are never modified.
  void _onMeasurementChanged(void Function() apply) {
    // Commits can arrive from a field's dispose during route teardown, so
    // only rebuild when this state is still mounted.
    if (mounted) {
      setState(apply);
    } else {
      apply();
    }
    if (widget.mode == BodySectionMode.user) {
      _weightCommitPending = true;
      _weightCommitTimer?.cancel();
      _weightCommitTimer = Timer(const Duration(seconds: 2), () {
        _commitWeightRecord();
      });
    } else {
      widget.onProfileChanged(
        _profile.copyWith(
          bustCm: _bust,
          clearBustCm: _bust == null,
          waistCm: _waist,
          clearWaistCm: _waist == null,
          hipCm: _hip,
          clearHipCm: _hip == null,
        ),
      );
    }
  }

  /// Purpose: Create one new weight record from the displayed measurements.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Appends a record to weight_data.json and notifies
  /// auto-sync; existing records and weight settings stay untouched.
  /// Notes: Reuses the latest record's weight, or 0 when none exists.
  Future<void> _commitWeightRecord() async {
    if (!_weightCommitPending) return;
    _weightCommitPending = false;
    final data = await WeightStorage.load() ?? WeightData(records: []);
    final latest = _latestRecord(data.records);
    final record = WeightRecord(
      weight: latest?.weight ?? 0,
      bustCm: _bust,
      waistCm: _waist,
      hipCm: _hip,
    );
    final next = WeightData(
      height: data.height,
      records: [...data.records, record],
      reminderMode: data.reminderMode,
      morningHour: data.morningHour,
      morningMinute: data.morningMinute,
      eveningHour: data.eveningHour,
      eveningMinute: data.eveningMinute,
      reminderGraceMinutes: data.reminderGraceMinutes,
      settingsModifiedAt: data.settingsModifiedAt,
    );
    await WeightStorage.save(next);
    AutoSyncService.instance.notifySaved();
  }

  /// Purpose: Return this person's recorded period start days.
  /// Inputs: None.
  /// Returns: `Set<DateTime>`.
  /// Side effects: None.
  /// Notes: Deduplicated by calendar date.
  Set<DateTime> get _myCycleDays => widget.cycleRecords
      .where((c) => c.personId == widget.personId)
      .map((c) => c.day)
      .toSet();

  /// Purpose: Compute this person's cycle prediction for display.
  /// Inputs: None.
  /// Returns: `CyclePrediction`.
  /// Side effects: None.
  /// Notes: The window covers all history plus ~13 months ahead so the
  /// calendar can browse past and future months.
  CyclePrediction get _prediction {
    final days = _myCycleDays;
    if (days.isEmpty) return CyclePrediction.empty;
    final earliest = days.reduce((a, b) => a.isBefore(b) ? a : b);
    return predictCycle(
      actualStarts: days,
      windowStart: DateTime(earliest.year, earliest.month - 1, 1),
      windowEnd: DateTime.now().add(const Duration(days: 400)),
    );
  }

  /// Purpose: Add a period start record for the selected calendar date.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Pushes the updated cycle record list to the parent.
  /// Notes: Duplicate dates for the same person are rejected silently.
  void _addCycleStart() {
    final date = _selectedCycleDate;
    if (date == null || _myCycleDays.contains(date)) return;
    widget.onCycleRecordsChanged([
      ...widget.cycleRecords,
      CycleRecord(
        personId: widget.personId,
        date: CycleRecord.formatDate(date),
      ),
    ]);
  }

  /// Purpose: Delete the period start record on the selected calendar date.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Pushes the updated cycle record list to the parent.
  /// Notes: Asks for confirmation through the shared delete dialog.
  Future<void> _deleteCycleStart() async {
    final date = _selectedCycleDate;
    if (date == null) return;
    final l10n = AppLocalizations.of(context)!;
    final label = DateFormat.yMMMd(l10n.localeName).format(date);
    if (!await confirmDelete(context, label)) return;
    final dateStr = CycleRecord.formatDate(date);
    widget.onCycleRecordsChanged([
      for (final c in widget.cycleRecords)
        if (!(c.personId == widget.personId && c.date == dateStr)) c,
    ]);
  }

  /// Purpose: Push a profile mutation to the parent.
  /// Inputs: `updated`.
  /// Returns: None.
  /// Side effects: Triggers the parent's auto-save.
  /// Notes: None.
  void _updateProfile(BodyProfile updated) {
    widget.onProfileChanged(updated);
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Renders as a plain column so parents embed it in their lists.
  @override
  Widget build(BuildContext context) {
    if (!_weightLoaded) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMeasurementsCard(context),
        _buildBraCard(context),
        _buildCycleCard(context),
        _buildPsiCard(context),
        if (widget.mode == BodySectionMode.user)
          _buildWarningSettingCard(context),
      ],
    );
  }

  /// Purpose: Build the bust/waist/hip measurement card with the WHR row.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: The waist-to-hip ratio is read-only and appears only when both
  /// displayed waist and hip values are positive.
  Widget _buildMeasurementsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isUser = widget.mode == BodySectionMode.user;
    final whr = WeightData.calculateWaistHipRatio(_waist, _hip);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.intimacyBodyMeasurements,
              style: theme.textTheme.titleMedium,
            ),
            if (isUser)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l10n.intimacyBodyMeasurementsFromWeight,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: l10n.weightBust,
                    value: _bust,
                    beforeEdit: isUser ? _confirmWeightSync : null,
                    onCommitted: (v) =>
                        _onMeasurementChanged(() => _bust = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    label: l10n.weightWaist,
                    value: _waist,
                    beforeEdit: isUser ? _confirmWeightSync : null,
                    onCommitted: (v) =>
                        _onMeasurementChanged(() => _waist = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    label: l10n.weightHip,
                    value: _hip,
                    beforeEdit: isUser ? _confirmWeightSync : null,
                    onCommitted: (v) => _onMeasurementChanged(() => _hip = v),
                  ),
                ),
              ],
            ),
            if (whr != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Text(
                      l10n.weightWaistHipRatio,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      whr.toStringAsFixed(2),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Build the underbust and bra-size estimation card.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: Only raw measurements are stored; the size recalculates live.
  Widget _buildBraCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final standard = braStandardFromCode(_profile.braStandard);
    final bust = _bust;
    final underbust = _profile.underbustCm;
    final estimate = (bust != null && underbust != null)
        ? estimateBraSize(
            bustCm: bust,
            underbustCm: underbust,
            standard: standard,
          )
        : null;
    final outOfRange =
        bust != null && underbust != null && bust > 0 && underbust > 0 &&
        estimate == null;

    String standardLabel(BraStandard s) => switch (s) {
      BraStandard.eu => l10n.intimacyBraStandardEu,
      BraStandard.frEs => l10n.intimacyBraStandardFrEs,
      BraStandard.jp => l10n.intimacyBraStandardJp,
      BraStandard.uk => l10n.intimacyBraStandardUk,
      BraStandard.us => l10n.intimacyBraStandardUs,
      BraStandard.auNz => l10n.intimacyBraStandardAuNz,
    };

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.intimacyBraSize, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _NumberField(
                    label: l10n.intimacyBodyUnderbust,
                    value: underbust,
                    onCommitted: (v) => _updateProfile(
                      _profile.copyWith(
                        underbustCm: v,
                        clearUnderbustCm: v == null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<BraStandard>(
                    initialValue: standard,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.intimacyBraStandard,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final s in BraStandard.values)
                        DropdownMenuItem(
                          value: s,
                          child: Text(
                            standardLabel(s),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (s) {
                      if (s == null) return;
                      _updateProfile(
                        _profile.copyWith(braStandard: braStandardCode(s)),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: l10n.intimacyBraHelpTitle,
                  onPressed: () => _showBraHelp(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${l10n.intimacyBraEstimatedSize}: ',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  estimate?.display ?? (outOfRange ? '' : '—'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (outOfRange)
                  Expanded(
                    child: Text(
                      l10n.intimacyBraOutOfRange,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
            if (standard == BraStandard.us && estimate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.intimacyBraUsVariance,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.intimacyBraEstimateDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Show the bra-standard help dialog.
  /// Inputs: `context`.
  /// Returns: None.
  /// Side effects: Opens a dialog.
  /// Notes: Explains each supported standard plus the estimate disclaimer.
  void _showBraHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    Widget entry(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(body, style: theme.textTheme.bodySmall),
        ],
      ),
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.intimacyBraHelpTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              entry(l10n.intimacyBraStandardEu, l10n.intimacyBraHelpEu),
              entry(l10n.intimacyBraStandardFrEs, l10n.intimacyBraHelpFrEs),
              entry(l10n.intimacyBraStandardJp, l10n.intimacyBraHelpJp),
              entry(l10n.intimacyBraStandardUk, l10n.intimacyBraHelpUk),
              entry(l10n.intimacyBraStandardUs, l10n.intimacyBraHelpUs),
              entry(l10n.intimacyBraStandardAuNz, l10n.intimacyBraHelpAuNz),
              Text(
                l10n.intimacyBraEstimateDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  /// Purpose: Build the menstrual-cycle tracking card.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: The calendar is permanently visible while tracking is enabled;
  /// predictions recalculate immediately on every add/delete.
  Widget _buildCycleCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final enabled = _profile.cycleEnabled;
    final prediction = enabled ? _prediction : CyclePrediction.empty;
    final myDays = _myCycleDays;
    final selected = _selectedCycleDate;
    final selectedInfo = selected != null ? prediction.days[selected] : null;
    final selectedHasRecord = selected != null && myDays.contains(selected);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.intimacyCycleTitle, style: theme.textTheme.titleMedium),
            SwitchListTile(
              value: enabled,
              onChanged: (v) =>
                  _updateProfile(_profile.copyWith(cycleEnabled: v)),
              title: Text(l10n.intimacyCycleEnable),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            if (enabled) ...[
              CycleCalendar(
                personColor: widget.personColor,
                prediction: prediction,
                selectedDate: selected,
                onDateSelected: (date) => setState(() {
                  _selectedCycleDate =
                      selected != null &&
                          selected.year == date.year &&
                          selected.month == date.month &&
                          selected.day == date.day
                      ? null
                      : date;
                }),
              ),
              const SizedBox(height: 8),
              CycleLegend(people: const [], showPeople: false),
              const SizedBox(height: 8),
              if (myDays.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${l10n.intimacyCycleLength(prediction.cycleLengthDays)} '
                    '${l10n.intimacyCycleEstimatedSuffix}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              if (selected != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCycleDateSummary(
                          l10n,
                          selected,
                          selectedInfo,
                          selectedHasRecord,
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (selectedHasRecord)
                      TextButton.icon(
                        onPressed: _deleteCycleStart,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(l10n.commonDelete),
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: _addCycleStart,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.intimacyCycleAddStart),
                      ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.intimacyCycleStartHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.intimacyCycleDisclaimer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SwitchListTile(
                value: _profile.showCycleOnCalendar,
                onChanged: (v) => _updateProfile(
                  _profile.copyWith(showCycleOnCalendar: v),
                ),
                title: Text(
                  widget.mode == BodySectionMode.user
                      ? l10n.intimacyCycleShowOnCalendarUser
                      : l10n.intimacyCycleShowOnCalendarPartner,
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Purpose: Summarize the selected cycle date for the action row.
  /// Inputs: `l10n`, `date`, `info`, `hasRecord`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Marks every derived value as estimated.
  String _selectedCycleDateSummary(
    AppLocalizations l10n,
    DateTime date,
    CycleDayInfo? info,
    bool hasRecord,
  ) {
    final dateLabel = DateFormat.yMMMd(l10n.localeName).format(date);
    if (hasRecord) return '$dateLabel · ${l10n.intimacyCycleActualStart}';
    if (info == null) return dateLabel;
    final parts = <String>[];
    if (info.isPredictedStart) parts.add(l10n.intimacyCyclePredictedStart);
    parts.add(switch (info.phase) {
      CyclePhase.menstrual => l10n.intimacyCyclePhaseMenstrual,
      CyclePhase.follicular => l10n.intimacyCyclePhaseFollicular,
      CyclePhase.luteal => l10n.intimacyCyclePhaseLuteal,
    });
    if (info.isOvulationDay) parts.add(l10n.intimacyCycleOvulation);
    if (info.inFertileWindow) parts.add(l10n.intimacyCycleFertileWindow);
    return '$dateLabel · ${parts.join(' · ')} '
        '${l10n.intimacyCycleEstimatedSuffix}';
  }

  /// Purpose: Build the penis measurement and PSI card.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: PSI is shown as a bare reference number with the neutral
  /// explanation and the statistical citation; no qualitative wording.
  Widget _buildPsiCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final psi = calculatePsi(
      lengthCm: _profile.erectLengthCm,
      baseCircumferenceCm: _profile.baseCircumferenceCm,
      frontCircumferenceCm: _profile.frontCircumferenceCm,
    );
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.intimacyPsiSection, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    label: l10n.intimacyPsiErectLength,
                    value: _profile.erectLengthCm,
                    onCommitted: (v) => _updateProfile(
                      _profile.copyWith(
                        erectLengthCm: v,
                        clearErectLengthCm: v == null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    label: l10n.intimacyPsiBaseCircumference,
                    value: _profile.baseCircumferenceCm,
                    onCommitted: (v) => _updateProfile(
                      _profile.copyWith(
                        baseCircumferenceCm: v,
                        clearBaseCircumferenceCm: v == null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    label: l10n.intimacyPsiFrontCircumference,
                    value: _profile.frontCircumferenceCm,
                    onCommitted: (v) => _updateProfile(
                      _profile.copyWith(
                        frontCircumferenceCm: v,
                        clearFrontCircumferenceCm: v == null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (psi != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Text(
                      '${l10n.intimacyPsiValue}: ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      psi.toStringAsFixed(1),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.intimacyPsiExplanation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.intimacyPsiReference,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Purpose: Build the bottom warning opt-out setting card.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: None.
  /// Notes: User mode only; reflects the local storage_config flag and
  /// unchecking re-enables the sync warning.
  Widget _buildWarningSettingCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SwitchListTile(
        value: _syncWarningDisabled,
        onChanged: _setSyncWarningDisabled,
        title: Text(l10n.intimacyBodyDontRemindAgain),
        subtitle: Text(l10n.intimacyBodyDontRemindAgainDesc),
      ),
    );
  }
}

/// Auto-saving optional decimal input field used across the body section.
class _NumberField extends StatefulWidget {
  final String label;
  final double? value;
  final ValueChanged<double?> onCommitted;

  /// Optional gate invoked before the first edit (weight-sync warning).
  final Future<bool> Function()? beforeEdit;

  /// Purpose: Create a number field instance.
  /// Inputs: `label`, `value`, `onCommitted`, optional `beforeEdit` gate.
  /// Returns: A new `_NumberField` instance.
  /// Side effects: None.
  /// Notes: Commits on focus loss or after a short typing pause; an empty
  /// field commits null so every measurement stays optional.
  const _NumberField({
    required this.label,
    required this.value,
    required this.onCommitted,
    this.beforeEdit,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  double? _lastCommitted;
  bool _gatePassed = false;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers the focus listener.
  /// Notes: None.
  @override
  void initState() {
    super.initState();
    _lastCommitted = widget.value;
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode.addListener(_onFocusChanged);
  }

  /// Purpose: React to parent widget changes after this state has been created.
  /// Inputs: `oldWidget`.
  /// Returns: None.
  /// Side effects: Refreshes the visible text when the value changes outside.
  /// Notes: Never overwrites text while the user is editing the field.
  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _lastCommitted && !_focusNode.hasFocus) {
      _lastCommitted = widget.value;
      _controller.text = _format(widget.value);
    }
  }

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Flushes a pending commit.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    _debounce?.cancel();
    _commit();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Purpose: Format a value for display without a trailing `.0`.
  /// Inputs: `value`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Null renders as an empty optional field.
  String _format(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  /// Purpose: Commit the field text when focus leaves the field.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May invoke the commit callback.
  /// Notes: None.
  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _debounce?.cancel();
      _commit();
    }
  }

  /// Purpose: Parse and commit the current text when it changed.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Invokes `onCommitted` with the parsed value or null.
  /// Notes: Unparseable non-empty text is ignored until it becomes valid.
  void _commit() {
    final text = _controller.text.trim();
    double? parsed;
    if (text.isEmpty) {
      parsed = null;
    } else {
      final value = double.tryParse(text);
      if (value == null || value < 0) return;
      parsed = value > 0 ? value : null;
    }
    if (parsed == _lastCommitted) return;
    _lastCommitted = parsed;
    widget.onCommitted(parsed);
  }

  /// Purpose: Run the optional edit gate before letting the field focus.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May show the gate dialog, then focuses the field.
  /// Notes: The gate runs once per field; the parent dedupes per visit.
  Future<void> _handleTap() async {
    if (_gatePassed || widget.beforeEdit == null) {
      _focusNode.requestFocus();
      return;
    }
    final allowed = await widget.beforeEdit!();
    if (!mounted || !allowed) return;
    _gatePassed = true;
    _focusNode.requestFocus();
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final gated = widget.beforeEdit != null && !_gatePassed;
    final field = TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text;
          if (text.isEmpty) return newValue;
          return RegExp(r'^\d*\.?\d{0,1}$').hasMatch(text)
              ? newValue
              : oldValue;
        }),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: 'cm',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 1500), _commit);
      },
    );
    if (!gated) return field;
    return GestureDetector(
      onTap: _handleTap,
      child: AbsorbPointer(child: field),
    );
  }
}

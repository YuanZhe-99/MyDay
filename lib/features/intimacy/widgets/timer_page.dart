import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../models/intimacy_record.dart';
import 'add_record_dialog.dart';

/// Purpose: Describe how timer state changes are persisted outside this page.
/// Inputs: Timer history/session snapshots plus per-field change flags.
/// Returns: `Future<void>`.
/// Side effects: Implementations usually write updated intimacy data to storage.
/// Notes: Used so accidental app exits still keep the latest stopwatch state.
typedef TimerStateChanged =
    Future<void> Function({
      required List<TimerHistoryEntry> history,
      required IntimacyTimerSession? session,
      required bool historyChanged,
      required bool timerSessionChanged,
      required int? retentionDays,
      required bool retentionChanged,
    });

/// Result returned from TimerPage: either a new record, or updated timer
/// session / history / retention, or both.
class TimerPageResult {
  final IntimacyRecord? record;
  final List<TimerHistoryEntry>? updatedHistory;
  final IntimacyTimerSession? updatedTimerSession;
  final int? updatedRetentionDays;
  final bool historyChanged;
  final bool timerSessionChanged;

  /// true if retention was explicitly set (even if null = permanent)
  final bool retentionChanged;

  /// Purpose: Create a timer page result instance.
  /// Inputs: `historyChanged`, `timerSessionChanged`, and `retentionChanged`.
  /// Returns: A new `TimerPageResult` instance.
  /// Side effects: None.
  /// Notes: None.
  const TimerPageResult({
    this.record,
    this.updatedHistory,
    this.updatedTimerSession,
    this.updatedRetentionDays,
    this.historyChanged = false,
    this.timerSessionChanged = false,
    this.retentionChanged = false,
  });
}

class TimerPage extends StatefulWidget {
  final List<Partner> partners;
  final List<Toy> toys;
  final List<Position> positions;
  final List<TimerHistoryEntry> timerHistory;
  final IntimacyTimerSession? timerSession;
  final int? timerHistoryRetentionDays;
  final TimerStateChanged onStateChanged;

  /// Purpose: Create a timer page instance.
  /// Inputs: `positions`, current timer state, and persistence callback.
  /// Returns: A new `TimerPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const TimerPage({
    super.key,
    required this.partners,
    required this.toys,
    this.positions = const [],
    required this.timerHistory,
    this.timerSession,
    this.timerHistoryRetentionDays,
    required this.onStateChanged,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  // Wall-clock based timer: immune to screen-off / app-suspend.
  DateTime? _firstStartedAt; // wall-clock moment the user first pressed Start
  DateTime? _startedAt; // wall-clock moment the timer was (re)started
  Duration _accumulated = Duration.zero; // elapsed before last pause
  Timer? _ticker;
  bool _running = false;

  late List<TimerHistoryEntry> _history;
  late int? _retentionDays;
  bool _retentionChanged = false;
  bool _historyChanged = false;
  bool _timerSessionChanged = false;

  /// Purpose: Return elapsed.
  /// Inputs: None.
  /// Returns: `Duration`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  Duration get _elapsed =>
      _accumulated +
      (_running && _startedAt != null
          ? DateTime.now().difference(_startedAt!)
          : Duration.zero);

  // ── lifecycle ──────────────────────────────────────────────────────

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _retentionDays = widget.timerHistoryRetentionDays;
    _history = _applyRetention(List.of(widget.timerHistory));
    if (_history.length != widget.timerHistory.length) {
      _historyChanged = true;
    }
    final session = widget.timerSession;
    if (session != null) {
      _firstStartedAt = session.firstStartedAt;
      _startedAt = session.running ? session.startedAt : null;
      _accumulated = session.accumulated;
      _running = session.running;
      if (_running) _ensureTicker();
    }
  }

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Releases owned resources and unregisters listeners.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  /// Purpose: Implement the did change app lifecycle state behavior for this file.
  /// Inputs: `state`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _running) {
      _ensureTicker();
      setState(() {});
    }
  }

  // ── retention ──────────────────────────────────────────────────────

  /// Purpose: Provide the internal apply retention helper for this file.
  /// Inputs: `entries`.
  /// Returns: `List<TimerHistoryEntry>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<TimerHistoryEntry> _applyRetention(List<TimerHistoryEntry> entries) {
    if (_retentionDays == null) return entries; // permanent
    final cutoff = DateTime.now().subtract(Duration(days: _retentionDays!));
    return entries.where((e) => e.start.isAfter(cutoff)).toList();
  }

  // ── timer controls ─────────────────────────────────────────────────

  /// Purpose: Provide the internal start helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _start() async {
    _firstStartedAt ??= DateTime.now();
    _startedAt = DateTime.now();
    _running = true;
    _ensureTicker();
    setState(() {});
    await _persistState(timerSessionChanged: true);
  }

  /// Purpose: Provide the internal pause helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _pause() async {
    if (_running && _startedAt != null) {
      _accumulated += DateTime.now().difference(_startedAt!);
    }
    _startedAt = null;
    _running = false;
    _ticker?.cancel();
    setState(() {});
    await _persistState(timerSessionChanged: true);
  }

  /// Purpose: Provide the internal reset helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _reset() async {
    _accumulated = Duration.zero;
    _firstStartedAt = null;
    _startedAt = null;
    _running = false;
    _ticker?.cancel();
    setState(() {});
    await _persistState(timerSessionChanged: true);
  }

  /// Purpose: Provide the internal ensure ticker helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _ensureTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  /// Purpose: Return session start time.
  /// Inputs: None.
  /// Returns: `DateTime?`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  DateTime? get _sessionStartTime => _firstStartedAt;

  /// Purpose: Return a persistable snapshot of the current timer session.
  /// Inputs: None.
  /// Returns: `IntimacyTimerSession?`.
  /// Side effects: None.
  /// Notes: Null means there is no interrupted or active stopwatch to restore.
  IntimacyTimerSession? get _timerSession {
    final firstStartedAt = _firstStartedAt;
    if (firstStartedAt == null) return null;
    return IntimacyTimerSession(
      firstStartedAt: firstStartedAt,
      startedAt: _running ? _startedAt : null,
      accumulated: _accumulated,
      running: _running,
    );
  }

  /// Purpose: Persist timer state changes while the timer page is still open.
  /// Inputs: Change flags for history, timer session, and retention settings.
  /// Returns: `Future<void>`.
  /// Side effects: Asks the parent page to write updated intimacy data to storage.
  /// Notes: State is written on user actions, not every displayed timer tick.
  Future<void> _persistState({
    bool historyChanged = false,
    bool timerSessionChanged = false,
    bool retentionChanged = false,
  }) async {
    if (historyChanged) _historyChanged = true;
    if (timerSessionChanged) _timerSessionChanged = true;
    if (retentionChanged) _retentionChanged = true;
    if (!historyChanged && !timerSessionChanged && !retentionChanged) return;
    await widget.onStateChanged(
      history: _history,
      session: _timerSession,
      historyChanged: historyChanged,
      timerSessionChanged: timerSessionChanged,
      retentionDays: _retentionDays,
      retentionChanged: retentionChanged,
    );
  }

  // ── pop helpers ─────────────────────────────────────────────────────

  /// Purpose: Provide the internal pop with history if changed helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _popWithHistoryIfChanged() {
    if (_historyChanged || _timerSessionChanged || _retentionChanged) {
      Navigator.pop(
        context,
        TimerPageResult(
          updatedHistory: _history,
          updatedTimerSession: _timerSession,
          updatedRetentionDays: _retentionDays,
          historyChanged: _historyChanged,
          timerSessionChanged: _timerSessionChanged,
          retentionChanged: _retentionChanged,
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  // ── save ────────────────────────────────────────────────────────────

  /// Purpose: Provide the internal save record helper for this file.
  /// Inputs: `prefillDuration`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _saveRecord({Duration? prefillDuration}) async {
    final elapsed = prefillDuration ?? _elapsed;
    final sessionStart = prefillDuration != null
        ? DateTime.now().subtract(elapsed)
        : (_sessionStartTime ?? DateTime.now().subtract(elapsed));
    if (prefillDuration == null) await _pause();

    // Add to history
    if (prefillDuration == null) {
      final entry = TimerHistoryEntry(start: sessionStart, duration: elapsed);
      setState(() {
        _history.insert(0, entry);
        _history = _applyRetention(_history);
        _historyChanged = true;
      });
      await _persistState(historyChanged: true);
    }
    if (!mounted) return;

    final record = await showDialog<IntimacyRecord>(
      context: context,
      builder: (_) => AddRecordDialog(
        prefillDuration: elapsed,
        partners: widget.partners,
        toys: widget.toys,
        positions: widget.positions,
      ),
    );

    if (record != null && mounted) {
      final clearedTimerSession = prefillDuration == null;
      if (clearedTimerSession) {
        _accumulated = Duration.zero;
        _firstStartedAt = null;
        _startedAt = null;
        _running = false;
        _ticker?.cancel();
        await _persistState(timerSessionChanged: true);
        if (!mounted) return;
      }
      Navigator.pop(
        context,
        TimerPageResult(
          record: record,
          updatedHistory: _history,
          updatedTimerSession: _timerSession,
          updatedRetentionDays: _retentionDays,
          historyChanged: _historyChanged,
          timerSessionChanged: clearedTimerSession,
          retentionChanged: _retentionChanged,
        ),
      );
    }
  }

  // ── formatting ──────────────────────────────────────────────────────

  /// Purpose: Provide the internal format duration helper for this file.
  /// Inputs: `d`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Purpose: Provide the internal format date time helper for this file.
  /// Inputs: `dt`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _formatDateTime(DateTime dt) =>
      DateFormat('MM/dd HH:mm:ss').format(dt);

  /// Purpose: Confirm and restore a timer history entry as a running stopwatch.
  /// Inputs: `entry`.
  /// Returns: `Future<void>`.
  /// Side effects: Opens a confirmation dialog, removes history, and persists timer state.
  /// Notes: Any current running timer keeps ticking while the confirmation dialog is open.
  Future<void> _confirmRestoreHistory(TimerHistoryEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.intimacyTimerRestoreConfirmTitle),
        content: Text(l10n.intimacyTimerRestoreConfirmMessage),
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
    );
    if (confirmed != true || !mounted) return;

    _ticker?.cancel();
    setState(() {
      _history.remove(entry);
      _historyChanged = true;
      _firstStartedAt = entry.start;
      _startedAt = DateTime.now();
      _accumulated = entry.duration;
      _running = true;
      _timerSessionChanged = true;
    });
    _ensureTicker();
    await _persistState(historyChanged: true, timerSessionChanged: true);
  }

  // ── build ───────────────────────────────────────────────────────────

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isRunning = _running;
    final hasElapsed = _elapsed > Duration.zero;
    final sessionStart = _sessionStartTime;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _popWithHistoryIfChanged();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.intimacyTimer), centerTitle: true),
        body: Column(
          children: [
            // ── main timer area ──
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (sessionStart != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${l10n.intimacyTimerStartedAt} ${_formatDateTime(sessionStart)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),

                    Text(
                      _formatDuration(_elapsed),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w300,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 48),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (!isRunning && !hasElapsed)
                          FilledButton.icon(
                            onPressed: () => _start(),
                            icon: const Icon(Icons.play_arrow),
                            label: Text(l10n.intimacyStart),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),

                        if (isRunning) ...[
                          OutlinedButton.icon(
                            onPressed: () => _pause(),
                            icon: const Icon(Icons.pause),
                            label: Text(l10n.intimacyPause),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _saveRecord(),
                            icon: const Icon(Icons.stop),
                            label: Text(l10n.intimacyStopSave),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],

                        if (!isRunning && hasElapsed) ...[
                          OutlinedButton.icon(
                            onPressed: () => _start(),
                            icon: const Icon(Icons.play_arrow),
                            label: Text(l10n.intimacyResume),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _saveRecord(),
                            icon: const Icon(Icons.save),
                            label: Text(l10n.commonSave),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _reset(),
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.intimacyReset),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── history section ──
            if (_history.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.intimacyTimerHistory,
                      style: theme.textTheme.titleSmall,
                    ),
                    const Spacer(),
                    // Retention picker
                    _buildRetentionChip(theme, l10n),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () async {
                        setState(() {
                          _history.clear();
                          _historyChanged = true;
                        });
                        await _persistState(historyChanged: true);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l10n.intimacyTimerClearHistory),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),
              for (final entry in _history)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.timer_outlined, size: 20),
                  title: Text(
                    _formatDuration(entry.duration),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  subtitle: Text(
                    _formatDateTime(entry.start),
                    style: theme.textTheme.bodySmall,
                  ),
                  onTap: () => _saveRecord(prefillDuration: entry.duration),
                  trailing: IconButton(
                    tooltip: l10n.intimacyTimerRestore,
                    icon: const Icon(Icons.restore, size: 20),
                    onPressed: () => _confirmRestoreHistory(entry),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  /// Purpose: Provide the internal build retention chip helper for this file.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildRetentionChip(ThemeData theme, AppLocalizations l10n) {
    final labels = {
      3: l10n.intimacyTimerRetention3d,
      7: l10n.intimacyTimerRetention7d,
      14: l10n.intimacyTimerRetention14d,
      -1: l10n.intimacyTimerRetentionForever,
    };

    final currentKey = _retentionDays ?? -1;

    return PopupMenuButton<int>(
      initialValue: currentKey,
      onSelected: (value) async {
        setState(() {
          _retentionDays = value == -1 ? null : value;
          _retentionChanged = true;
          _history = _applyRetention(_history);
          _historyChanged = true;
        });
        await _persistState(historyChanged: true, retentionChanged: true);
      },
      itemBuilder: (_) => labels.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      child: Chip(
        avatar: const Icon(Icons.schedule, size: 16),
        label: Text(labels[currentKey]!, style: const TextStyle(fontSize: 11)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

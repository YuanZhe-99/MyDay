import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../todo/services/todo_storage.dart';
import '../models/intimacy_record.dart';
import 'add_record_dialog.dart';

/// A single timer history entry (independent of IntimacyRecord).
class TimerHistoryEntry {
  final DateTime start;
  final Duration duration;
  const TimerHistoryEntry({required this.start, required this.duration});

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'durationMs': duration.inMilliseconds,
      };

  factory TimerHistoryEntry.fromJson(Map<String, dynamic> json) {
    // Support legacy entries that stored 'end' instead of 'durationMs'
    if (json.containsKey('durationMs')) {
      return TimerHistoryEntry(
        start: DateTime.parse(json['start'] as String),
        duration: Duration(milliseconds: json['durationMs'] as int),
      );
    }
    final start = DateTime.parse(json['start'] as String);
    final end = DateTime.parse(json['end'] as String);
    return TimerHistoryEntry(start: start, duration: end.difference(start));
  }
}

/// Simple file persistence for timer history (max 3 entries).
class _TimerHistoryStorage {
  static const _fileName = 'timer_history.json';

  static Future<File> _getFile() async {
    final appDir = await TodoStorage.getAppDir();
    return File('${appDir.path}/$_fileName');
  }

  static Future<List<TimerHistoryEntry>> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => TimerHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<TimerHistoryEntry> entries) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(entries.map((e) => e.toJson()).toList()));
  }
}

class TimerPage extends StatefulWidget {
  final List<Partner> partners;
  final List<Toy> toys;

  const TimerPage({
    super.key,
    required this.partners,
    required this.toys,
  });

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  // Wall-clock based timer: immune to screen-off / app-suspend.
  DateTime? _firstStartedAt;  // wall-clock moment the user first pressed Start
  DateTime? _startedAt;       // wall-clock moment the timer was (re)started
  Duration _accumulated = Duration.zero; // elapsed before last pause
  Timer? _ticker;
  bool _running = false;

  // History — max 3, persisted, not linked to saved records, clearable.
  final List<TimerHistoryEntry> _history = [];

  Duration get _elapsed =>
      _accumulated +
      (_running && _startedAt != null
          ? DateTime.now().difference(_startedAt!)
          : Duration.zero);

  // ── lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app resumes from background / screen-on, restart the UI ticker
    // so the display catches up with wall-clock elapsed time immediately.
    if (state == AppLifecycleState.resumed && _running) {
      _ensureTicker();
      setState(() {}); // force redraw with correct elapsed
    }
  }

  // ── timer controls ─────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final entries = await _TimerHistoryStorage.load();
    if (mounted) setState(() => _history..clear()..addAll(entries));
  }

  Future<void> _persistHistory() async {
    await _TimerHistoryStorage.save(_history);
  }

  void _start() {
    _firstStartedAt ??= DateTime.now();
    _startedAt = DateTime.now();
    _running = true;
    _ensureTicker();
    setState(() {});
  }

  void _pause() {
    if (_running && _startedAt != null) {
      _accumulated += DateTime.now().difference(_startedAt!);
    }
    _startedAt = null;
    _running = false;
    _ticker?.cancel();
    setState(() {});
  }

  void _reset() {
    _accumulated = Duration.zero;
    _firstStartedAt = null;
    _startedAt = null;
    _running = false;
    _ticker?.cancel();
    setState(() {});
  }

  void _ensureTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  /// The wall-clock time when the user first pressed Start this session.
  DateTime? get _sessionStartTime => _firstStartedAt;

  // ── save ────────────────────────────────────────────────────────────

  Future<void> _saveRecord() async {
    final elapsed = _elapsed;
    final sessionStart = _sessionStartTime ?? DateTime.now().subtract(elapsed);
    _pause();

    // Add to history and persist
    final entry = TimerHistoryEntry(
      start: sessionStart,
      duration: elapsed,
    );
    setState(() {
      _history.insert(0, entry);
      if (_history.length > 3) _history.removeLast();
    });
    _persistHistory();

    final record = await showDialog<IntimacyRecord>(
      context: context,
      builder: (_) => AddRecordDialog(
        prefillDuration: elapsed,
        partners: widget.partners,
        toys: widget.toys,
      ),
    );

    if (record != null && mounted) {
      Navigator.pop(context, record);
    }
  }

  // ── formatting ──────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatDateTime(DateTime dt) => DateFormat('MM/dd HH:mm:ss').format(dt);

  // ── build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isRunning = _running;
    final hasElapsed = _elapsed > Duration.zero;
    final sessionStart = _sessionStartTime;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.intimacyTimer),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── main timer area ──
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Current session start time
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

                  // Timer display
                  Text(
                    _formatDuration(_elapsed),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w300,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Control buttons
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (!isRunning && !hasElapsed)
                        FilledButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.intimacyStart),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                        ),

                      if (isRunning) ...[
                        OutlinedButton.icon(
                          onPressed: _pause,
                          icon: const Icon(Icons.pause),
                          label: Text(l10n.intimacyPause),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _saveRecord,
                          icon: const Icon(Icons.stop),
                          label: Text(l10n.intimacyStopSave),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],

                      if (!isRunning && hasElapsed) ...[
                        OutlinedButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.intimacyResume),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _saveRecord,
                          icon: const Icon(Icons.save),
                          label: Text(l10n.commonSave),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _reset,
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
                  Icon(Icons.history, size: 18, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    l10n.intimacyTimerHistory,
                    style: theme.textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _history.clear());
                      _persistHistory();
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
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/auto_sync_service.dart';
import '../../../shared/services/reminder_service.dart';
import '../models/task.dart';
import '../services/todo_storage.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/edit_task_dialog.dart';
import '../widgets/task_section.dart';

class TodoPage extends StatefulWidget {
  /// Purpose: Create a todo page instance.
  /// Inputs: None.
  /// Returns: A new `TodoPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const TodoPage({super.key});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  DateTime _selectedDate = DateTime.now();
  bool _loaded = false;

  // Daily tasks are templates — shown every day, completion tracked per-date
  List<Task> _dailyTemplates = [];

  // One-time tasks with scheduled dates
  List<Task> _oneTimeTasks = [];

  // Per-date completion log for daily templates
  DailyCompletionLog _dailyLog = DailyCompletionLog();

  // Per-date user score for each todo day
  DailyScoreLog _dailyScores = DailyScoreLog();

  // Reminder state
  TimeOfDay? _morningReminderTime;
  TimeOfDay? _completionReminderTime;
  Map<String, String> _taskSortModes = {};
  Map<String, List<String>> _taskCustomOrders = {};
  DateTime _settingsModifiedAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const _taskSortCreated = 'createdDate';
  static const _taskSortDue = 'dueDate';
  static const _taskSortName = 'name';
  static const _taskSortCustom = 'custom';

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
    final data = await TodoStorage.load();
    setState(() {
      if (data != null) {
        _dailyTemplates = data.dailyTemplates;
        _oneTimeTasks = data.oneTimeTasks;
        _dailyLog = data.dailyLog;
        _dailyScores = data.dailyScores;
        _taskSortModes = Map.of(data.taskSortModes);
        _taskCustomOrders = data.taskCustomOrders.map(
          (key, value) => MapEntry(key, List<String>.of(value)),
        );
        _settingsModifiedAt = data.settingsModifiedAt;
        if (data.morningReminderHour != null &&
            data.morningReminderMinute != null) {
          _morningReminderTime = TimeOfDay(
            hour: data.morningReminderHour!,
            minute: data.morningReminderMinute!,
          );
        }
        if (data.completionReminderHour != null &&
            data.completionReminderMinute != null) {
          _completionReminderTime = TimeOfDay(
            hour: data.completionReminderHour!,
            minute: data.completionReminderMinute!,
          );
        }
      }
      _loaded = true;
    });
    _syncReminders();
  }

  /// Purpose: Provide the internal save data helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _saveData() async {
    await TodoStorage.save(
      TodoData(
        dailyTemplates: _dailyTemplates,
        oneTimeTasks: _oneTimeTasks,
        dailyLog: _dailyLog,
        dailyScores: _dailyScores,
        morningReminderHour: _morningReminderTime?.hour,
        morningReminderMinute: _morningReminderTime?.minute,
        completionReminderHour: _completionReminderTime?.hour,
        completionReminderMinute: _completionReminderTime?.minute,
        taskSortModes: _taskSortModes,
        taskCustomOrders: _taskCustomOrders,
        settingsModifiedAt: _settingsModifiedAt,
      ),
    );
    _syncReminders();
    AutoSyncService.instance.notifySaved();
  }

  // --- Reminder ---

  /// Purpose: Provide the internal sync reminders helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _syncReminders() {
    ReminderService.instance.updateData(
      dailyTemplates: _dailyTemplates,
      oneTimeTasks: _oneTimeTasks,
      dailyLog: _dailyLog,
      morningReminderTime: _morningReminderTime,
      completionReminderTime: _completionReminderTime,
    );
  }

  /// Purpose: Provide the internal show daily reminder settings helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _showDailyReminderSettings() async {
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
                    title: Text(
                      AppLocalizations.of(ctx)?.todoDailyReminders ??
                          'Daily Reminders',
                    ),
                  ),
                  const Divider(height: 1),

                  // Morning reminder
                  ListTile(
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: Text(
                      AppLocalizations.of(ctx)?.todoMorningReminder ??
                          'Morning Plan',
                    ),
                    subtitle: Text(
                      _morningReminderTime != null
                          ? _morningReminderTime!.format(ctx)
                          : AppLocalizations.of(ctx)?.todoRemindReviewHint ??
                                'Remind to review today\'s Todo list',
                    ),
                    trailing: _morningReminderTime != null
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                            onPressed: () {
                              setState(() => _morningReminderTime = null);
                              setSheetState(() {});
                              _saveData();
                            },
                          )
                        : null,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime:
                            _morningReminderTime ??
                            const TimeOfDay(hour: 8, minute: 0),
                      );
                      if (picked != null) {
                        setState(() => _morningReminderTime = picked);
                        setSheetState(() {});
                        _saveData();
                      }
                    },
                  ),

                  // Completion reminder
                  ListTile(
                    leading: const Icon(Icons.checklist),
                    title: Text(
                      AppLocalizations.of(ctx)?.todoCompletionReminder ??
                          'Completion Check',
                    ),
                    subtitle: Text(
                      _completionReminderTime != null
                          ? _completionReminderTime!.format(ctx)
                          : AppLocalizations.of(ctx)?.todoRemindUndoneHint ??
                                'Remind if tasks are still undone',
                    ),
                    trailing: _completionReminderTime != null
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                            onPressed: () {
                              setState(() => _completionReminderTime = null);
                              setSheetState(() {});
                              _saveData();
                            },
                          )
                        : null,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime:
                            _completionReminderTime ??
                            const TimeOfDay(hour: 21, minute: 0),
                      );
                      if (picked != null) {
                        setState(() => _completionReminderTime = picked);
                        setSheetState(() {});
                        _saveData();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Helpers ---

  /// Purpose: Provide the internal is same day helper for this file.
  /// Inputs: `a`, `b`.
  /// Returns: `bool`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Purpose: Return is today.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  bool get _isToday => _isSameDay(_selectedDate, DateTime.now());

  /// Purpose: Return the Monday that starts the selected date's week.
  /// Inputs: None.
  /// Returns: `DateTime`.
  /// Side effects: None.
  /// Notes: The todo week calendar uses Monday as the first day.
  DateTime get _selectedWeekStart {
    final selected = _dateOnly(_selectedDate);
    return selected.subtract(
      Duration(days: selected.weekday - DateTime.monday),
    );
  }

  /// Purpose: Return the seven dates shown in the inline week calendar.
  /// Inputs: None.
  /// Returns: `List<DateTime>`.
  /// Side effects: None.
  /// Notes: The list always represents the selected date's week.
  List<DateTime> get _selectedWeekDates => [
    for (var i = 0; i < 7; i++) _selectedWeekStart.add(Duration(days: i)),
  ];

  /// Purpose: Return the localized short weekday label for a date weekday.
  /// Inputs: `l10n`, `weekday`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Weekday uses Dart's Monday=1 through Sunday=7 numbering.
  String _weekdayLabel(AppLocalizations l10n, int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return l10n.todoWeekMon;
      case DateTime.tuesday:
        return l10n.todoWeekTue;
      case DateTime.wednesday:
        return l10n.todoWeekWed;
      case DateTime.thursday:
        return l10n.todoWeekThu;
      case DateTime.friday:
        return l10n.todoWeekFri;
      case DateTime.saturday:
        return l10n.todoWeekSat;
      case DateTime.sunday:
      default:
        return l10n.todoWeekSun;
    }
  }

  /// Daily tasks for selected date — show template with per-date completion,
  /// filtered by startDate <= selectedDate and (deletedDate == null or deletedDate > selectedDate)
  /// Purpose: Return daily for date.
  /// Inputs: None.
  /// Returns: `List<Task>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Task> get _dailyForDate {
    final selDate = _dateOnly(_selectedDate);
    final list = _dailyTemplates
        .where((t) {
          final start = _dateOnly(t.startDate ?? t.createdDate);
          return !start.isAfter(selDate) &&
              (t.deletedDate == null ||
                  _dateOnly(t.deletedDate!).isAfter(selDate));
        })
        .map((t) {
          final done = _dailyLog.isCompleted(_selectedDate, t.id);
          // Map subtask completion from per-date log
          final mappedSubs = t.subtasks.map((s) {
            final subDone = _dailyLog.isSubtaskCompleted(_selectedDate, s.id);
            return subDone != s.isCompleted
                ? s.copyWith(isCompleted: subDone)
                : s;
          }).toList();
          final needsCopy = done != t.isCompleted || mappedSubs != t.subtasks;
          return needsCopy
              ? t.copyWith(isCompleted: done, subtasks: mappedSubs)
              : t;
        })
        .toList();
    return _sortTasks(list, TaskType.daily);
  }

  /// Strip time from DateTime for comparison
  /// Purpose: Provide the internal date only helper for this file.
  /// Inputs: `d`.
  /// Returns: `DateTime`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Purpose: Provide the internal task type key helper for this file.
  /// Inputs: `type`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _taskTypeKey(TaskType type) => type.name;

  /// Purpose: Provide the internal task sort mode helper for this file.
  /// Inputs: `type`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _taskSortMode(TaskType type) =>
      _taskSortModes[_taskTypeKey(type)] ?? _taskSortCreated;

  /// Purpose: Provide the internal touch settings helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _touchSettings() {
    _settingsModifiedAt = DateTime.now().toUtc();
  }

  /// Purpose: Provide the internal tasks for type helper for this file.
  /// Inputs: `type`.
  /// Returns: `List<Task>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<Task> _tasksForType(TaskType type) {
    if (type == TaskType.daily) return List.of(_dailyTemplates);
    return _oneTimeTasks.where((t) => t.type == type).toList();
  }

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

  /// Purpose: Provide the internal compare task fallback helper for this file.
  /// Inputs: `a`, `b`.
  /// Returns: `int`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  int _compareTaskFallback(Task a, Task b) {
    final byCreated = a.createdDate.compareTo(b.createdDate);
    if (byCreated != 0) return byCreated;
    return _compareText(a.title, b.title);
  }

  /// Purpose: Provide the internal task due sort date helper for this file.
  /// Inputs: `task`.
  /// Returns: `DateTime?`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  DateTime? _taskDueSortDate(Task task) =>
      task.dueDate ?? task.scheduledDate ?? task.startDate;

  /// Purpose: Provide the internal normalized task order helper for this file.
  /// Inputs: `type`.
  /// Returns: `List<String>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<String> _normalizedTaskOrder(TaskType type) {
    final key = _taskTypeKey(type);
    final allIds = _tasksForType(type).map((t) => t.id).toList();
    final allIdSet = allIds.toSet();
    final seen = <String>{};
    final normalized = <String>[
      for (final id in _taskCustomOrders[key] ?? const <String>[])
        if (allIdSet.contains(id) && seen.add(id)) id,
    ];
    for (final id in allIds) {
      if (seen.add(id)) normalized.add(id);
    }
    return normalized;
  }

  /// Purpose: Provide the internal sort tasks for mode helper for this file.
  /// Inputs: `tasks`, `type`, `mode`.
  /// Returns: `List<Task>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<Task> _sortTasksForMode(List<Task> tasks, TaskType type, String mode) {
    final list = List<Task>.of(tasks);
    switch (mode) {
      case _taskSortDue:
        list.sort((a, b) {
          final byDate = _compareNullableDates(
            _taskDueSortDate(a),
            _taskDueSortDate(b),
          );
          return byDate != 0 ? byDate : _compareTaskFallback(a, b);
        });
      case _taskSortName:
        list.sort((a, b) {
          final byName = _compareText(a.title, b.title);
          return byName != 0 ? byName : _compareTaskFallback(a, b);
        });
      case _taskSortCustom:
        final order = _normalizedTaskOrder(type);
        final fallbackIndex = order.length;
        list.sort((a, b) {
          final ai = order.indexOf(a.id);
          final bi = order.indexOf(b.id);
          final byOrder = (ai == -1 ? fallbackIndex : ai).compareTo(
            bi == -1 ? fallbackIndex : bi,
          );
          return byOrder != 0 ? byOrder : _compareTaskFallback(a, b);
        });
      case _taskSortCreated:
      default:
        list.sort(_compareTaskFallback);
    }
    return list;
  }

  /// Purpose: Provide the internal sort tasks helper for this file.
  /// Inputs: `tasks`, `type`.
  /// Returns: `List<Task>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<Task> _sortTasks(List<Task> tasks, TaskType type) =>
      _sortTasksForMode(tasks, type, _taskSortMode(type));

  /// Purpose: Provide the internal append task to custom order if needed helper for this file.
  /// Inputs: `task`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _appendTaskToCustomOrderIfNeeded(Task task) {
    if (_taskSortMode(task.type) != _taskSortCustom) return;
    _taskCustomOrders[_taskTypeKey(task.type)] = _normalizedTaskOrder(
      task.type,
    );
    _touchSettings();
  }

  /// Purpose: Provide the internal remove task from custom orders helper for this file.
  /// Inputs: `taskId`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _removeTaskFromCustomOrders(String taskId) {
    var changed = false;
    for (final entry in _taskCustomOrders.entries) {
      changed = entry.value.remove(taskId) || changed;
    }
    if (changed) _touchSettings();
  }

  /// Purpose: Provide the internal on task sort mode changed helper for this file.
  /// Inputs: `type`, `mode`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _onTaskSortModeChanged(TaskType type, String mode) {
    final key = _taskTypeKey(type);
    setState(() {
      final currentMode = _taskSortMode(type);
      if (mode == _taskSortCustom && !_taskCustomOrders.containsKey(key)) {
        _taskCustomOrders[key] = _sortTasksForMode(
          _tasksForType(type),
          type,
          currentMode,
        ).map((t) => t.id).toList();
      }
      _taskSortModes[key] = mode;
      if (mode == _taskSortCustom) {
        _taskCustomOrders[key] = _normalizedTaskOrder(type);
      }
      _touchSettings();
    });
    _saveData();
  }

  /// Purpose: Provide the internal on task reorder helper for this file.
  /// Inputs: `type`, `visibleTasks`, `oldIndex`, `newIndex`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _onTaskReorder(
    TaskType type,
    List<Task> visibleTasks,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex--;
    final key = _taskTypeKey(type);
    final visibleIds = visibleTasks.map((t) => t.id).toList();
    if (oldIndex < 0 ||
        oldIndex >= visibleIds.length ||
        newIndex < 0 ||
        newIndex > visibleIds.length) {
      return;
    }

    final reorderedVisible = List<String>.of(visibleIds);
    final moved = reorderedVisible.removeAt(oldIndex);
    reorderedVisible.insert(newIndex, moved);

    setState(() {
      final visibleSet = visibleIds.toSet();
      final order = _normalizedTaskOrder(type);
      var replacementIndex = 0;
      _taskCustomOrders[key] = [
        for (final id in order)
          if (visibleSet.contains(id))
            reorderedVisible[replacementIndex++]
          else
            id,
      ];
      _taskSortModes[key] = _taskSortCustom;
      _touchSettings();
    });
    _saveData();
  }

  /// Whether a one-time task should be visible on the selected date:
  /// - Completed: show on scheduledDate AND completedDate, not in between
  /// - Not completed: show from scheduledDate through today (carry forward)
  /// Purpose: Provide the internal one time visible on date helper for this file.
  /// Inputs: `t`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  bool _oneTimeVisibleOnDate(Task t) {
    if (t.scheduledDate == null) return false;
    final selDate = _dateOnly(_selectedDate);
    final sched = _dateOnly(t.scheduledDate!);
    if (t.isCompleted && t.completedDate != null) {
      final completed = _dateOnly(t.completedDate!);
      return _isSameDay(selDate, sched) || _isSameDay(selDate, completed);
    }
    // Not completed: show on exact scheduled date (even if future),
    // or carry forward from scheduled date through today
    final today = _dateOnly(DateTime.now());
    return _isSameDay(selDate, sched) ||
        (!sched.isAfter(selDate) && !selDate.isAfter(today));
  }

  /// One-time routine tasks for selected date
  /// Purpose: Return routine for date.
  /// Inputs: None.
  /// Returns: `List<Task>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Task> get _routineForDate {
    final list = _oneTimeTasks
        .where(
          (t) => t.type == TaskType.routineOnce && _oneTimeVisibleOnDate(t),
        )
        .toList();
    return _sortTasks(list, TaskType.routineOnce);
  }

  /// One-time work tasks for selected date
  /// Purpose: Return work for date.
  /// Inputs: None.
  /// Returns: `List<Task>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Task> get _workForDate {
    final list = _oneTimeTasks
        .where((t) => t.type == TaskType.workOnce && _oneTimeVisibleOnDate(t))
        .toList();
    return _sortTasks(list, TaskType.workOnce);
  }

  // --- Calendar helpers ---

  /// Daily templates visible on a given date (respects startDate/deletedDate)
  /// Purpose: Provide the internal daily templates for date helper for this file.
  /// Inputs: `date`.
  /// Returns: `List<Task>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Task> _dailyTemplatesForDate(DateTime date) {
    final d = _dateOnly(date);
    return _dailyTemplates.where((t) {
      final start = _dateOnly(t.startDate ?? t.createdDate);
      return !start.isAfter(d) &&
          (t.deletedDate == null || _dateOnly(t.deletedDate!).isAfter(d));
    }).toList();
  }

  /// Purpose: Provide the internal all daily completed on helper for this file.
  /// Inputs: `date`.
  /// Returns: `bool`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  bool _allDailyCompletedOn(DateTime date) {
    final templates = _dailyTemplatesForDate(date);
    if (templates.isEmpty) return false;
    for (final t in templates) {
      if (!_dailyLog.isCompleted(date, t.id)) return false;
    }
    return true;
  }

  /// Purpose: Provide the internal all tasks completed on helper for this file.
  /// Inputs: `date`.
  /// Returns: `bool`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  bool _allTasksCompletedOn(DateTime date) {
    if (!_allDailyCompletedOn(date)) return false;
    final selDate = _dateOnly(date);
    for (final t in _oneTimeTasks) {
      if (t.scheduledDate == null) continue;
      final sched = _dateOnly(t.scheduledDate!);
      bool visible;
      if (t.isCompleted && t.completedDate != null) {
        final completed = _dateOnly(t.completedDate!);
        visible = _isSameDay(selDate, sched) || _isSameDay(selDate, completed);
      } else {
        final today = _dateOnly(DateTime.now());
        visible = !sched.isAfter(selDate) && !selDate.isAfter(today);
      }
      if (visible && !t.isCompleted) return false;
    }
    return true;
  }

  /// Purpose: Provide the internal some daily completed on helper for this file.
  /// Inputs: `date`.
  /// Returns: `bool`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  bool _someDailyCompletedOn(DateTime date) {
    final templates = _dailyTemplatesForDate(date);
    if (templates.isEmpty) return false;
    bool anyDone = false;
    bool allDone = true;
    for (final t in templates) {
      if (_dailyLog.isCompleted(date, t.id)) {
        anyDone = true;
      } else {
        allDone = false;
      }
    }
    return anyDone && !allDone;
  }

  /// Purpose: Check whether a future date has one-time tasks scheduled exactly on it.
  /// Inputs: `date`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Daily templates and carried-forward overdue one-time tasks are intentionally ignored.
  bool _hasFutureScheduledOneTimeTask(DateTime date) {
    final target = _dateOnly(date);
    final today = _dateOnly(DateTime.now());
    if (!target.isAfter(today)) return false;
    return _oneTimeTasks.any((t) {
      if (t.type == TaskType.daily || t.scheduledDate == null) return false;
      return _isSameDay(_dateOnly(t.scheduledDate!), target);
    });
  }

  /// Purpose: Provide the internal show calendar helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _showCalendar() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _CalendarDialog(
        selectedDate: _selectedDate,
        allDailyCompleted: _allDailyCompletedOn,
        allTasksCompleted: _allTasksCompletedOn,
        someDailyCompleted: _someDailyCompletedOn,
        hasFutureScheduledOneTimeTask: _hasFutureScheduledOneTimeTask,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // --- Actions ---

  /// Purpose: Provide the internal change date helper for this file.
  /// Inputs: `delta`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _changeDate(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
  }

  /// Purpose: Update the score assigned to the selected todo day.
  /// Inputs: `score`, `save`.
  /// Returns: None.
  /// Side effects: Mutates the daily score log, refreshes UI, and may save todo data.
  /// Notes: Scores are clamped by `DailyScoreLog` before being stored.
  void _setDailyScore(int score, {bool save = true}) {
    setState(() {
      _dailyScores.setScore(
        _selectedDate,
        score,
        modifiedAt: DateTime.now().toUtc(),
      );
    });
    if (save) _saveData();
  }

  /// Purpose: Provide the internal toggle task helper for this file.
  /// Inputs: `task`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _toggleTask(Task task) {
    Task? completedWithRecurrence;
    setState(() {
      if (task.type == TaskType.daily) {
        // Toggle per-date completion
        _dailyLog.toggle(_selectedDate, task.id);
        // Auto-complete / uncomplete subtasks to match
        final nowCompleted = _dailyLog.isCompleted(_selectedDate, task.id);
        // Find the template to get subtask IDs
        final tpl = _dailyTemplates.firstWhere(
          (t) => t.id == task.id,
          orElse: () => task,
        );
        if (tpl.subtasks.isNotEmpty) {
          _dailyLog.setSubtasksCompleted(
            _selectedDate,
            tpl.subtasks.map((s) => s.id),
            nowCompleted,
          );
        }
      } else {
        // One-time task: toggle permanent completion
        final index = _oneTimeTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          final t = _oneTimeTasks[index];
          final nowCompleting = !t.isCompleted;
          // Auto-complete / uncomplete subtasks
          final updatedSubs = t.subtasks
              .map((s) => s.copyWith(isCompleted: nowCompleting))
              .toList();
          // Must construct directly to allow clearing completedDate to null
          _oneTimeTasks[index] = Task(
            id: t.id,
            title: t.title,
            note: t.note,
            emoji: t.emoji,
            type: t.type,
            isCompleted: nowCompleting,
            reminderTime: t.reminderTime,
            subtasks: updatedSubs,
            createdDate: t.createdDate,
            completedDate: nowCompleting ? _selectedDate : null,
            scheduledDate: t.scheduledDate,
            deletedDate: t.deletedDate,
            startDate: t.startDate,
            dueDate: t.dueDate,
            recurrence: t.recurrence,
          );
          if (nowCompleting && t.recurrence != null) {
            completedWithRecurrence = _oneTimeTasks[index];
          }
        }
      }
    });
    _saveData();
    if (completedWithRecurrence != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _offerNextOccurrence(completedWithRecurrence!);
      });
    }
  }

  /// Purpose: Provide the internal offer next occurrence helper for this file.
  /// Inputs: `completedTask`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _offerNextOccurrence(Task completedTask) async {
    final l10n = AppLocalizations.of(context)!;
    final nextDate = completedTask.recurrence!.nextDate(
      completedTask.scheduledDate ?? completedTask.createdDate,
    );
    final nextTask = Task(
      title: completedTask.title,
      note: completedTask.note,
      emoji: completedTask.emoji,
      type: completedTask.type,
      subtasks: completedTask.subtasks
          .map((s) => SubTask(title: s.title))
          .toList(),
      scheduledDate: nextDate,
      reminderTime: completedTask.reminderTime,
      recurrence: completedTask.recurrence,
    );
    final task = await showDialog<Task>(
      context: context,
      builder: (_) => AddTaskDialog(
        defaultDate: nextDate,
        initialTask: nextTask,
        dialogTitle: l10n.todoNextOccurrence,
      ),
    );
    if (task != null && mounted) {
      setState(() {
        _oneTimeTasks.add(task);
        _appendTaskToCustomOrderIfNeeded(task);
      });
      _saveData();
    }
  }

  /// Purpose: Provide the internal delete task helper for this file.
  /// Inputs: `task`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _deleteTask(Task task) {
    setState(() {
      if (task.type == TaskType.daily) {
        final index = _dailyTemplates.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          final t = _dailyTemplates[index];
          final start = _dateOnly(t.startDate ?? t.createdDate);
          final delDate = _dateOnly(_selectedDate);
          if (_isSameDay(start, delDate)) {
            // Same day as start — permanently remove
            _removeTaskFromCustomOrders(task.id);
            _dailyTemplates.removeAt(index);
          } else {
            // Soft-delete: set deletedDate so it stops showing from this date onward
            _dailyTemplates[index] = t.copyWith(deletedDate: _selectedDate);
          }
        }
      } else {
        _removeTaskFromCustomOrders(task.id);
        _oneTimeTasks.removeWhere((t) => t.id == task.id);
      }
    });
    _saveData();
  }

  /// Purpose: Provide the internal toggle subtask helper for this file.
  /// Inputs: `task`, `subtask`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _toggleSubtask(Task task, SubTask subtask) {
    setState(() {
      if (task.type == TaskType.daily) {
        // Daily tasks: per-date subtask completion
        _dailyLog.toggleSubtask(_selectedDate, subtask.id);
      } else {
        // One-time tasks: toggle on the task directly
        final taskIndex = _oneTimeTasks.indexWhere((t) => t.id == task.id);
        if (taskIndex == -1) return;
        final subs = _oneTimeTasks[taskIndex].subtasks.map((s) {
          if (s.id == subtask.id) {
            return s.copyWith(isCompleted: !s.isCompleted);
          }
          return s;
        }).toList();
        _oneTimeTasks[taskIndex] = _oneTimeTasks[taskIndex].copyWith(
          subtasks: subs,
        );
      }
    });
    _saveData();
  }

  /// Purpose: Provide the internal add task helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _addTask() async {
    final task = await showDialog<Task>(
      context: context,
      builder: (_) => AddTaskDialog(defaultDate: _selectedDate),
    );
    if (task != null) {
      setState(() {
        if (task.type == TaskType.daily) {
          _dailyTemplates.add(task);
        } else {
          _oneTimeTasks.add(task);
        }
        _appendTaskToCustomOrderIfNeeded(task);
      });
      _saveData();
    }
  }

  /// Purpose: Provide the internal edit task helper for this file.
  /// Inputs: `task`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _editTask(Task task) async {
    // Find the original template (un-mapped) for daily tasks
    final originalTask = task.type == TaskType.daily
        ? _dailyTemplates.firstWhere((t) => t.id == task.id, orElse: () => task)
        : task;
    bool permanentlyDeleted = false;
    final updated = await showDialog<Task>(
      context: context,
      builder: (_) => EditTaskDialog(
        task: originalTask,
        onPermanentDelete: originalTask.deletedDate != null
            ? () {
                permanentlyDeleted = true;
                setState(() {
                  _dailyTemplates.removeWhere((t) => t.id == originalTask.id);
                });
                _saveData();
              }
            : null,
      ),
    );
    if (updated != null && !permanentlyDeleted) {
      setState(() {
        if (task.type == TaskType.daily) {
          final index = _dailyTemplates.indexWhere((t) => t.id == updated.id);
          if (index != -1) _dailyTemplates[index] = updated;
        } else {
          final index = _oneTimeTasks.indexWhere((t) => t.id == updated.id);
          if (index != -1) _oneTimeTasks[index] = updated;
        }
      });
      _saveData();
    }
  }

  /// Purpose: Build the inline calendar for the selected date's week.
  /// Inputs: `theme`, `l10n`.
  /// Returns: A widget showing seven selectable day cells plus calendar controls.
  /// Side effects: Creates UI widgets and wires date-selection callbacks.
  /// Notes: The full month picker remains available from the calendar icon.
  Widget _buildWeekCalendar(ThemeData theme, AppLocalizations l10n) {
    final dateFormat = DateFormat('yyyy-MM-dd (EEE)', l10n.localeName);
    final compactDateFormat = DateFormat('MM/dd', l10n.localeName);
    final weekStart = _selectedWeekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final range =
        '${compactDateFormat.format(weekStart)} - '
        '${compactDateFormat.format(weekEnd)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeDate(-7),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                  },
                  child: Column(
                    children: [
                      Text(
                        dateFormat.format(_selectedDate),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _isToday ? range : l10n.todoTapReturnToday,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _isToday
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.primary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: _showCalendar,
                tooltip: l10n.todoCalendar,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeDate(7),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final date in _selectedWeekDates)
                _buildWeekDayCell(date, theme, l10n),
            ],
          ),
        ],
      ),
    );
  }

  /// Purpose: Build one selectable day in the inline week calendar.
  /// Inputs: `date`, `theme`, `l10n`.
  /// Returns: A widget representing one day cell.
  /// Side effects: Creates UI widgets and may change the selected date when tapped.
  /// Notes: Reuses the same completion and scheduled-task markers as the month picker.
  Widget _buildWeekDayCell(
    DateTime date,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final allDone = _allTasksCompletedOn(date);
    final dailyDone = _allDailyCompletedOn(date);
    final someDone = _someDailyCompletedOn(date);
    final hasScheduledTodo = _hasFutureScheduledOneTimeTask(date);
    final hasMarkers = allDone || dailyDone || someDone || hasScheduledTodo;
    final colorScheme = theme.colorScheme;

    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = colorScheme.primaryContainer;
    } else if (allDone) {
      backgroundColor = colorScheme.primary.withValues(alpha: 0.12);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: backgroundColor ?? Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isToday
                ? BorderSide(color: colorScheme.primary, width: 1.5)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _selectedDate = date),
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayLabel(l10n, date.weekday),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: allDone && !isSelected
                          ? colorScheme.primary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 10,
                    child: hasMarkers
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (allDone)
                                Icon(
                                  Icons.check_circle,
                                  size: 9,
                                  color: colorScheme.primary,
                                )
                              else if (dailyDone)
                                Icon(
                                  Icons.circle,
                                  size: 7,
                                  color: colorScheme.tertiary,
                                )
                              else if (someDone)
                                Icon(
                                  Icons.circle,
                                  size: 7,
                                  color: colorScheme.outline,
                                ),
                              if ((allDone || dailyDone || someDone) &&
                                  hasScheduledTodo)
                                const SizedBox(width: 2),
                              if (hasScheduledTodo)
                                Icon(
                                  Icons.event_note,
                                  size: 9,
                                  color: colorScheme.secondary,
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Purpose: Build the score editor shown at the bottom of the todo list.
  /// Inputs: `theme`, `l10n`.
  /// Returns: A widget for viewing and editing the selected day's score.
  /// Side effects: Creates UI widgets and wires score-edit callbacks.
  /// Notes: The score range is the inclusive -5 to 5 range defined by `DailyScoreLog`.
  Widget _buildDailyScoreCard(ThemeData theme, AppLocalizations l10n) {
    final score = _dailyScores.scoreFor(_selectedDate);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.todoDailyScore,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$score',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: score == 0
                        ? theme.colorScheme.onSurfaceVariant
                        : score > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.todoDailyScoreHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton.outlined(
                  icon: const Icon(Icons.remove),
                  onPressed: score <= DailyScoreLog.minScore
                      ? null
                      : () => _setDailyScore(score - 1),
                ),
                Expanded(
                  child: Slider(
                    value: score.toDouble(),
                    min: DailyScoreLog.minScore.toDouble(),
                    max: DailyScoreLog.maxScore.toDouble(),
                    divisions: DailyScoreLog.maxScore - DailyScoreLog.minScore,
                    label: '$score',
                    onChanged: (value) {
                      final nextScore = value.round();
                      if (nextScore == score) return;
                      _setDailyScore(nextScore, save: false);
                    },
                    onChangeEnd: (value) => _saveData(),
                  ),
                ),
                IconButton.outlined(
                  icon: const Icon(Icons.add),
                  onPressed: score >= DailyScoreLog.maxScore
                      ? null
                      : () => _setDailyScore(score + 1),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DailyScoreLog.minScore}',
                  style: theme.textTheme.labelSmall,
                ),
                Text('0', style: theme.textTheme.labelSmall),
                Text(
                  '+${DailyScoreLog.maxScore}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTodo),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color:
                  (_morningReminderTime != null ||
                      _completionReminderTime != null)
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: l10n.todoDailyReminders,
            onPressed: _showDailyReminderSettings,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildWeekCalendar(theme, l10n),
                const Divider(height: 1),

                // Task list: 3 sections
                Expanded(
                  child: ListView(
                    children: [
                      TaskSectionWidget(
                        title: l10n.todoSectionDaily,
                        icon: Icons.repeat,
                        color: theme.colorScheme.primary,
                        tasks: _dailyForDate,
                        taskType: TaskType.daily,
                        sortMode: _taskSortMode(TaskType.daily),
                        onSortModeChanged: (mode) =>
                            _onTaskSortModeChanged(TaskType.daily, mode),
                        onReorder: (tasks, oldIndex, newIndex) =>
                            _onTaskReorder(
                              TaskType.daily,
                              tasks,
                              oldIndex,
                              newIndex,
                            ),
                        onToggle: _toggleTask,
                        onDelete: _deleteTask,
                        onEdit: _editTask,
                        onSubtaskToggle: _toggleSubtask,
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      TaskSectionWidget(
                        title: l10n.todoSectionRoutine,
                        icon: Icons.today,
                        color: theme.colorScheme.tertiary,
                        tasks: _routineForDate,
                        taskType: TaskType.routineOnce,
                        sortMode: _taskSortMode(TaskType.routineOnce),
                        onSortModeChanged: (mode) =>
                            _onTaskSortModeChanged(TaskType.routineOnce, mode),
                        onReorder: (tasks, oldIndex, newIndex) =>
                            _onTaskReorder(
                              TaskType.routineOnce,
                              tasks,
                              oldIndex,
                              newIndex,
                            ),
                        onToggle: _toggleTask,
                        onDelete: _deleteTask,
                        onEdit: _editTask,
                        onSubtaskToggle: _toggleSubtask,
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      TaskSectionWidget(
                        title: l10n.todoSectionWork,
                        icon: Icons.work_outline,
                        color: theme.colorScheme.secondary,
                        tasks: _workForDate,
                        taskType: TaskType.workOnce,
                        sortMode: _taskSortMode(TaskType.workOnce),
                        onSortModeChanged: (mode) =>
                            _onTaskSortModeChanged(TaskType.workOnce, mode),
                        onReorder: (tasks, oldIndex, newIndex) =>
                            _onTaskReorder(
                              TaskType.workOnce,
                              tasks,
                              oldIndex,
                              newIndex,
                            ),
                        onToggle: _toggleTask,
                        onDelete: _deleteTask,
                        onEdit: _editTask,
                        onSubtaskToggle: _toggleSubtask,
                      ),
                      _buildDailyScoreCard(theme, l10n),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Calendar Dialog ---

class _CalendarDialog extends StatefulWidget {
  final DateTime selectedDate;
  final bool Function(DateTime) allDailyCompleted;
  final bool Function(DateTime) allTasksCompleted;
  final bool Function(DateTime) someDailyCompleted;
  final bool Function(DateTime) hasFutureScheduledOneTimeTask;

  /// Purpose: Create a calendar dialog instance.
  /// Inputs: `selectedDate`, completion callbacks, scheduled-task callback.
  /// Returns: A new `_CalendarDialog` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _CalendarDialog({
    required this.selectedDate,
    required this.allDailyCompleted,
    required this.allTasksCompleted,
    required this.someDailyCompleted,
    required this.hasFutureScheduledOneTimeTask,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late DateTime _viewMonth;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  /// Purpose: Provide the internal prev month helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
    });
  }

  /// Purpose: Provide the internal next month helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
    });
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
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun
    final totalCells = ((startWeekday - 1) + daysInMonth + 6) ~/ 7 * 7;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(
                  DateFormat('MMMM yyyy', l10n.localeName).format(_viewMonth),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Weekday headers
            Row(
              children:
                  [
                        l10n.todoWeekMon,
                        l10n.todoWeekTue,
                        l10n.todoWeekWed,
                        l10n.todoWeekThu,
                        l10n.todoWeekFri,
                        l10n.todoWeekSat,
                        l10n.todoWeekSun,
                      ]
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 4),

            // Day grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                final dayOffset = index - (startWeekday - 1);
                if (dayOffset < 0 || dayOffset >= daysInMonth) {
                  return const SizedBox.shrink();
                }
                final day = dayOffset + 1;
                final date = DateTime(_viewMonth.year, _viewMonth.month, day);
                final isSelected =
                    date.year == widget.selectedDate.year &&
                    date.month == widget.selectedDate.month &&
                    date.day == widget.selectedDate.day;
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                final allDone = widget.allTasksCompleted(date);
                final dailyDone = widget.allDailyCompleted(date);
                final someDone = widget.someDailyCompleted(date);
                final hasScheduledTodo = widget.hasFutureScheduledOneTimeTask(
                  date,
                );

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context, date),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: allDone
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : isSelected
                          ? theme.colorScheme.primaryContainer
                          : null,
                      border: isToday
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : null,
                            color: allDone ? theme.colorScheme.primary : null,
                          ),
                        ),
                        if (allDone ||
                            dailyDone ||
                            someDone ||
                            hasScheduledTodo)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (allDone)
                                Icon(
                                  Icons.check_circle,
                                  size: 8,
                                  color: theme.colorScheme.primary,
                                )
                              else if (dailyDone)
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: theme.colorScheme.tertiary,
                                )
                              else if (someDone)
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: theme.colorScheme.outline,
                                ),
                              if ((allDone || dailyDone || someDone) &&
                                  hasScheduledTodo)
                                const SizedBox(width: 2),
                              if (hasScheduledTodo)
                                Icon(
                                  Icons.event_note,
                                  size: 8,
                                  color: theme.colorScheme.secondary,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Legend
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                _CalendarLegendItem(
                  icon: Icons.circle,
                  iconSize: 6,
                  color: theme.colorScheme.outline,
                  label: l10n.todoCalendarSomeDaily,
                ),
                _CalendarLegendItem(
                  icon: Icons.circle,
                  iconSize: 6,
                  color: theme.colorScheme.tertiary,
                  label: l10n.todoCalendarAllDaily,
                ),
                _CalendarLegendItem(
                  icon: Icons.check_circle,
                  iconSize: 8,
                  color: theme.colorScheme.primary,
                  label: l10n.todoCalendarAllDone,
                ),
                _CalendarLegendItem(
                  icon: Icons.event_note,
                  iconSize: 8,
                  color: theme.colorScheme.secondary,
                  label: l10n.todoCalendarScheduledTodo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarLegendItem extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color color;
  final String label;

  /// Purpose: Create a compact calendar legend item.
  /// Inputs: `icon`, `iconSize`, `color`, `label`.
  /// Returns: A new `_CalendarLegendItem` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _CalendarLegendItem({
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.label,
  });

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

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
  const TodoPage({super.key});

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

  // Reminder state
  TimeOfDay? _morningReminderTime;
  TimeOfDay? _completionReminderTime;

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
    final data = await TodoStorage.load();
    setState(() {
      if (data != null) {
        _dailyTemplates = data.dailyTemplates;
        _oneTimeTasks = data.oneTimeTasks;
        _dailyLog = data.dailyLog;
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

  Future<void> _saveData() async {
    await TodoStorage.save(TodoData(
      dailyTemplates: _dailyTemplates,
      oneTimeTasks: _oneTimeTasks,
      dailyLog: _dailyLog,
      morningReminderHour: _morningReminderTime?.hour,
      morningReminderMinute: _morningReminderTime?.minute,
      completionReminderHour: _completionReminderTime?.hour,
      completionReminderMinute: _completionReminderTime?.minute,
    ));
    _syncReminders();
    AutoSyncService.instance.notifySaved();
  }

  // --- Reminder ---

  void _syncReminders() {
    ReminderService.instance.updateData(
      dailyTemplates: _dailyTemplates,
      oneTimeTasks: _oneTimeTasks,
      dailyLog: _dailyLog,
      morningReminderTime: _morningReminderTime,
      completionReminderTime: _completionReminderTime,
    );
  }

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
                    title: Text(AppLocalizations.of(ctx)?.todoDailyReminders ?? 'Daily Reminders'),
                  ),
                  const Divider(height: 1),

                  // Morning reminder
                  ListTile(
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: Text(AppLocalizations.of(ctx)?.todoMorningReminder ?? 'Morning Plan'),
                    subtitle: Text(_morningReminderTime != null
                        ? _morningReminderTime!.format(ctx)
                        : AppLocalizations.of(ctx)?.todoRemindReviewHint ?? 'Remind to review today\'s Todo list'),
                    trailing: _morningReminderTime != null
                        ? IconButton(
                            icon: Icon(Icons.close,
                                size: 18,
                                color: Theme.of(ctx).colorScheme.error),
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
                        initialTime: _morningReminderTime ??
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
                    title: Text(AppLocalizations.of(ctx)?.todoCompletionReminder ?? 'Completion Check'),
                    subtitle: Text(_completionReminderTime != null
                        ? _completionReminderTime!.format(ctx)
                        : AppLocalizations.of(ctx)?.todoRemindUndoneHint ?? 'Remind if tasks are still undone'),
                    trailing: _completionReminderTime != null
                        ? IconButton(
                            icon: Icon(Icons.close,
                                size: 18,
                                color: Theme.of(ctx).colorScheme.error),
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
                        initialTime: _completionReminderTime ??
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isToday => _isSameDay(_selectedDate, DateTime.now());

  /// Daily tasks for selected date — show template with per-date completion,
  /// filtered by startDate <= selectedDate and (deletedDate == null or deletedDate > selectedDate)
  List<Task> get _dailyForDate {
    final selDate = _dateOnly(_selectedDate);
    return _dailyTemplates
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
        return subDone != s.isCompleted ? s.copyWith(isCompleted: subDone) : s;
      }).toList();
      final needsCopy = done != t.isCompleted || mappedSubs != t.subtasks;
      return needsCopy ? t.copyWith(isCompleted: done, subtasks: mappedSubs) : t;
    }).toList();
  }

  /// Strip time from DateTime for comparison
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Whether a one-time task should be visible on the selected date:
  /// - Completed: show on scheduledDate AND completedDate, not in between
  /// - Not completed: show from scheduledDate through today (carry forward)
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
  List<Task> get _routineForDate {
    return _oneTimeTasks
        .where((t) => t.type == TaskType.routineOnce && _oneTimeVisibleOnDate(t))
        .toList();
  }

  /// One-time work tasks for selected date
  List<Task> get _workForDate {
    return _oneTimeTasks
        .where((t) => t.type == TaskType.workOnce && _oneTimeVisibleOnDate(t))
        .toList();
  }

  // --- Calendar helpers ---

  /// Daily templates visible on a given date (respects startDate/deletedDate)
  List<Task> _dailyTemplatesForDate(DateTime date) {
    final d = _dateOnly(date);
    return _dailyTemplates.where((t) {
      final start = _dateOnly(t.startDate ?? t.createdDate);
      return !start.isAfter(d) &&
          (t.deletedDate == null || _dateOnly(t.deletedDate!).isAfter(d));
    }).toList();
  }

  bool _allDailyCompletedOn(DateTime date) {
    final templates = _dailyTemplatesForDate(date);
    if (templates.isEmpty) return false;
    for (final t in templates) {
      if (!_dailyLog.isCompleted(date, t.id)) return false;
    }
    return true;
  }

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

  Future<void> _showCalendar() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _CalendarDialog(
        selectedDate: _selectedDate,
        allDailyCompleted: _allDailyCompletedOn,
        allTasksCompleted: _allTasksCompletedOn,
        someDailyCompleted: _someDailyCompletedOn,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // --- Actions ---

  void _changeDate(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
  }

  void _toggleTask(Task task) {
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
          );
        }
      }
    });
    _saveData();
  }

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
            _dailyTemplates.removeAt(index);
          } else {
            // Soft-delete: set deletedDate so it stops showing from this date onward
            _dailyTemplates[index] = t.copyWith(deletedDate: _selectedDate);
          }
        }
      } else {
        _oneTimeTasks.removeWhere((t) => t.id == task.id);
      }
    });
    _saveData();
  }

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
        _oneTimeTasks[taskIndex] = _oneTimeTasks[taskIndex].copyWith(subtasks: subs);
      }
    });
    _saveData();
  }

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
      });
      _saveData();
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('yyyy-MM-dd (EEE)', l10n.localeName);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTodo),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: (_morningReminderTime != null ||
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
          // Date navigation bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDate(-1),
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
                        if (!_isToday)
                          Text(
                            l10n.todoTapReturnToday,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
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
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),
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
                  onToggle: _toggleTask,
                  onDelete: _deleteTask,
                  onEdit: _editTask,
                  onSubtaskToggle: _toggleSubtask,
                ),
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

  const _CalendarDialog({
    required this.selectedDate,
    required this.allDailyCompleted,
    required this.allTasksCompleted,
    required this.someDailyCompleted,
  });

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth =
        DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final daysInMonth =
        DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
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
              children: [l10n.todoWeekMon, l10n.todoWeekTue, l10n.todoWeekWed, l10n.todoWeekThu, l10n.todoWeekFri, l10n.todoWeekSat, l10n.todoWeekSun]
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ))
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
                final date =
                    DateTime(_viewMonth.year, _viewMonth.month, day);
                final isSelected =
                    date.year == widget.selectedDate.year &&
                        date.month == widget.selectedDate.month &&
                        date.day == widget.selectedDate.day;
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                final allDone = widget.allTasksCompleted(date);
                final dailyDone = widget.allDailyCompleted(date);
                final someDone = widget.someDailyCompleted(date);

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context, date),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: allDone
                          ? theme.colorScheme.primary
                              .withValues(alpha: 0.2)
                          : isSelected
                              ? theme.colorScheme.primaryContainer
                              : null,
                      border: isToday
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2)
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
                            color: allDone
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        if (allDone)
                          Icon(Icons.check_circle,
                              size: 8,
                              color: theme.colorScheme.primary)
                        else if (dailyDone)
                          Icon(Icons.circle,
                              size: 6,
                              color: theme.colorScheme.tertiary)
                        else if (someDone)
                          Icon(Icons.circle,
                              size: 6,
                              color: theme.colorScheme.outline),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle,
                    size: 6, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(l10n.todoCalendarSomeDaily, style: theme.textTheme.bodySmall),
                const SizedBox(width: 12),
                Icon(Icons.circle,
                    size: 6, color: theme.colorScheme.tertiary),
                const SizedBox(width: 4),
                Text(l10n.todoCalendarAllDaily, style: theme.textTheme.bodySmall),
                const SizedBox(width: 12),
                Icon(Icons.check_circle,
                    size: 8, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(l10n.todoCalendarAllDone, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:uuid/uuid.dart';

enum TaskType { daily, routineOnce, workOnce }

class SubTask {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime modifiedAt;

  SubTask({
    String? id,
    required this.title,
    this.isCompleted = false,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now();

  SubTask copyWith({String? title, bool? isCompleted, DateTime? modifiedAt}) {
    return SubTask(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        modifiedAt: json['modifiedAt'] != null
            ? DateTime.parse(json['modifiedAt'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class Task {
  final String id;
  final String title;
  final String? emoji;
  final TaskType type;
  final bool isCompleted;
  final DateTime? reminderTime;
  final List<SubTask> subtasks;
  final DateTime createdDate;
  final DateTime? completedDate;
  /// For one-time tasks: the date this task is scheduled on.
  /// For daily tasks: null (they are templates shown every day).
  final DateTime? scheduledDate;
  /// For daily tasks: the date this template was soft-deleted.
  /// null means the template is still active.
  final DateTime? deletedDate;
  /// For daily tasks: the date this template becomes active.
  /// Defaults to the selected date at creation time.
  final DateTime? startDate;
  final DateTime modifiedAt;

  Task({
    String? id,
    required this.title,
    this.emoji,
    required this.type,
    this.isCompleted = false,
    this.reminderTime,
    this.subtasks = const [],
    DateTime? createdDate,
    this.completedDate,
    this.scheduledDate,
    this.deletedDate,
    this.startDate,
    DateTime? modifiedAt,
  })  : id = id ?? const Uuid().v4(),
        createdDate = createdDate ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? emoji,
    TaskType? type,
    bool? isCompleted,
    DateTime? reminderTime,
    List<SubTask>? subtasks,
    DateTime? completedDate,
    DateTime? scheduledDate,
    DateTime? deletedDate,
    bool clearDeletedDate = false,
    DateTime? startDate,
    DateTime? modifiedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderTime: reminderTime ?? this.reminderTime,
      subtasks: subtasks ?? this.subtasks,
      createdDate: createdDate,
      completedDate: completedDate ?? this.completedDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      deletedDate: clearDeletedDate ? null : (deletedDate ?? this.deletedDate),
      startDate: startDate ?? this.startDate,
      modifiedAt: modifiedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'type': type.name,
        'isCompleted': isCompleted,
        'reminderTime': reminderTime?.toIso8601String(),
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'createdDate': createdDate.toIso8601String(),
        'completedDate': completedDate?.toIso8601String(),
        'scheduledDate': scheduledDate?.toIso8601String(),
        'deletedDate': deletedDate?.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String?,
        type: TaskType.values.byName(json['type'] as String),
        isCompleted: json['isCompleted'] as bool? ?? false,
        reminderTime: json['reminderTime'] != null
            ? DateTime.parse(json['reminderTime'] as String)
            : null,
        subtasks: (json['subtasks'] as List<dynamic>?)
                ?.map((s) => SubTask.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        createdDate: DateTime.parse(json['createdDate'] as String),
        completedDate: json['completedDate'] != null
            ? DateTime.parse(json['completedDate'] as String)
            : null,
        scheduledDate: json['scheduledDate'] != null
            ? DateTime.parse(json['scheduledDate'] as String)
            : null,
        deletedDate: json['deletedDate'] != null
            ? DateTime.parse(json['deletedDate'] as String)
            : null,
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'] as String)
            : null,
        modifiedAt: json['modifiedAt'] != null
            ? DateTime.parse(json['modifiedAt'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
}

/// Tracks per-date completion state for daily (template) tasks.
/// Key = date string 'yyyy-MM-dd', Value = set of completed task IDs.
class DailyCompletionLog {
  final Map<String, Set<String>> _log = {};
  /// Per-date subtask completion: dateKey → set of completed subtask IDs.
  final Map<String, Set<String>> _subLog = {};

  DailyCompletionLog();

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool isCompleted(DateTime date, String taskId) {
    return _log[dateKey(date)]?.contains(taskId) ?? false;
  }

  void toggle(DateTime date, String taskId) {
    final key = dateKey(date);
    _log.putIfAbsent(key, () => {});
    if (_log[key]!.contains(taskId)) {
      _log[key]!.remove(taskId);
    } else {
      _log[key]!.add(taskId);
    }
  }

  Set<String> completedIds(DateTime date) =>
      _log[dateKey(date)] ?? {};

  // --- Subtask per-date tracking ---

  bool isSubtaskCompleted(DateTime date, String subtaskId) {
    return _subLog[dateKey(date)]?.contains(subtaskId) ?? false;
  }

  void toggleSubtask(DateTime date, String subtaskId) {
    final key = dateKey(date);
    _subLog.putIfAbsent(key, () => {});
    if (_subLog[key]!.contains(subtaskId)) {
      _subLog[key]!.remove(subtaskId);
    } else {
      _subLog[key]!.add(subtaskId);
    }
  }

  void setSubtasksCompleted(DateTime date, Iterable<String> subtaskIds, bool completed) {
    final key = dateKey(date);
    _subLog.putIfAbsent(key, () => {});
    if (completed) {
      _subLog[key]!.addAll(subtaskIds);
    } else {
      _subLog[key]!.removeAll(subtaskIds);
    }
  }

  Set<String> completedSubtaskIds(DateTime date) =>
      _subLog[dateKey(date)] ?? {};

  Map<String, dynamic> toJson() => {
        'tasks': _log.map((key, value) => MapEntry(key, value.toList())),
        'subtasks': _subLog.map((key, value) => MapEntry(key, value.toList())),
      };

  factory DailyCompletionLog.fromJson(Map<String, dynamic> json) {
    final log = DailyCompletionLog();
    // Support old format (flat map of date→taskIds) and new format ({tasks, subtasks})
    if (json.containsKey('tasks')) {
      (json['tasks'] as Map<String, dynamic>).forEach((key, value) {
        log._log[key] = (value as List<dynamic>).map((e) => e as String).toSet();
      });
      if (json['subtasks'] != null) {
        (json['subtasks'] as Map<String, dynamic>).forEach((key, value) {
          log._subLog[key] = (value as List<dynamic>).map((e) => e as String).toSet();
        });
      }
    } else {
      // Old format: flat map is task log only
      json.forEach((key, value) {
        log._log[key] = (value as List<dynamic>).map((e) => e as String).toSet();
      });
    }
    return log;
  }

  /// Merge two logs by taking the union of completed IDs per date.
  factory DailyCompletionLog.merge(DailyCompletionLog a, DailyCompletionLog b) {
    final merged = DailyCompletionLog();
    final allDates = {...a._log.keys, ...b._log.keys};
    for (final date in allDates) {
      merged._log[date] = {...(a._log[date] ?? {}), ...(b._log[date] ?? {})};
    }
    final allSubDates = {...a._subLog.keys, ...b._subLog.keys};
    for (final date in allSubDates) {
      merged._subLog[date] = {...(a._subLog[date] ?? {}), ...(b._subLog[date] ?? {})};
    }
    return merged;
  }
}

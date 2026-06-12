import 'package:uuid/uuid.dart';

enum TaskType { daily, routineOnce, workOnce }

/// How a one-time task recurs after completion.
enum RecurrenceType { everyNDays, monthlyOnDay, yearlyOnMonthDay }

class TaskRecurrence {
  final RecurrenceType type;

  /// Days between occurrences (used by [RecurrenceType.everyNDays]).
  final int intervalDays;

  /// Day of month (1-31), used by [RecurrenceType.monthlyOnDay] and [RecurrenceType.yearlyOnMonthDay].
  final int dayOfMonth;

  /// Month of year (1-12), used by [RecurrenceType.yearlyOnMonthDay].
  final int monthOfYear;

  /// Purpose: Create a task recurrence instance.
  /// Inputs: `intervalDays`.
  /// Returns: A new `TaskRecurrence._` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const TaskRecurrence._({
    required this.type,
    this.intervalDays = 0,
    this.dayOfMonth = 0,
    this.monthOfYear = 0,
  });

  /// Purpose: Create a task recurrence instance.
  /// Inputs: `days`.
  /// Returns: A new `TaskRecurrence.everyNDays` instance.
  /// Side effects: None.
  /// Notes: None.
  const TaskRecurrence.everyNDays(int days)
    : this._(type: RecurrenceType.everyNDays, intervalDays: days);

  /// Purpose: Create a task recurrence instance.
  /// Inputs: `day`.
  /// Returns: A new `TaskRecurrence.monthlyOnDay` instance.
  /// Side effects: None.
  /// Notes: None.
  const TaskRecurrence.monthlyOnDay(int day)
    : this._(type: RecurrenceType.monthlyOnDay, dayOfMonth: day);

  /// Purpose: Create a task recurrence instance.
  /// Inputs: `month`, `day`.
  /// Returns: A new `TaskRecurrence.yearlyOnMonthDay` instance.
  /// Side effects: None.
  /// Notes: None.
  const TaskRecurrence.yearlyOnMonthDay(int month, int day)
    : this._(
        type: RecurrenceType.yearlyOnMonthDay,
        monthOfYear: month,
        dayOfMonth: day,
      );

  /// Returns the next scheduled date relative to [from].
  /// Purpose: Compute the next date for the current state.
  /// Inputs: `from`.
  /// Returns: `DateTime`.
  /// Side effects: None.
  /// Notes: None.
  DateTime nextDate(DateTime from) {
    switch (type) {
      case RecurrenceType.everyNDays:
        return from.add(Duration(days: intervalDays));
      case RecurrenceType.monthlyOnDay:
        var month = from.month + 1;
        var year = from.year;
        if (month > 12) {
          month = 1;
          year++;
        }
        final lastDay = DateTime(year, month + 1, 0).day;
        return DateTime(year, month, dayOfMonth.clamp(1, lastDay));
      case RecurrenceType.yearlyOnMonthDay:
        final lastDay = DateTime(from.year + 1, monthOfYear + 1, 0).day;
        return DateTime(
          from.year + 1,
          monthOfYear,
          dayOfMonth.clamp(1, lastDay),
        );
    }
  }

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'intervalDays': intervalDays,
    'dayOfMonth': dayOfMonth,
    'monthOfYear': monthOfYear,
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `TaskRecurrence.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory TaskRecurrence.fromJson(Map<String, dynamic> json) =>
      TaskRecurrence._(
        type: RecurrenceType.values.byName(json['type'] as String),
        intervalDays: json['intervalDays'] as int? ?? 0,
        dayOfMonth: json['dayOfMonth'] as int? ?? 0,
        monthOfYear: json['monthOfYear'] as int? ?? 0,
      );
}

class SubTask {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime modifiedAt;

  /// Purpose: Create a sub task instance.
  /// Inputs: `isCompleted`.
  /// Returns: A new `SubTask` instance.
  /// Side effects: None.
  /// Notes: None.
  SubTask({
    String? id,
    required this.title,
    this.isCompleted = false,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Create a copy of this value with selected fields replaced.
  /// Inputs: `modifiedAt`.
  /// Returns: `SubTask`.
  /// Side effects: None.
  /// Notes: None.
  SubTask copyWith({String? title, bool? isCompleted, DateTime? modifiedAt}) {
    return SubTask(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      modifiedAt: modifiedAt ?? DateTime.now().toUtc(),
    );
  }

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `SubTask.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
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
  final String? note;
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

  /// For one-time tasks: optional due date for reminder purposes.
  final DateTime? dueDate;

  /// For one-time tasks: optional recurrence — when completed, prompt to create the next occurrence.
  final TaskRecurrence? recurrence;
  final DateTime modifiedAt;

  /// Purpose: Create a task instance.
  /// Inputs: `isCompleted`.
  /// Returns: A new `Task` instance.
  /// Side effects: None.
  /// Notes: None.
  Task({
    String? id,
    required this.title,
    this.note,
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
    this.dueDate,
    this.recurrence,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       createdDate = createdDate ?? DateTime.now(),
       modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Create a copy of this value with selected fields replaced.
  /// Inputs: `clearNote`.
  /// Returns: `Task`.
  /// Side effects: None.
  /// Notes: None.
  Task copyWith({
    String? title,
    String? note,
    bool clearNote = false,
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
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskRecurrence? recurrence,
    bool clearRecurrence = false,
    DateTime? modifiedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      note: clearNote ? null : (note ?? this.note),
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
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      modifiedAt: modifiedAt ?? DateTime.now().toUtc(),
    );
  }

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
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
    'dueDate': dueDate?.toIso8601String(),
    'recurrence': recurrence?.toJson(),
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `Task.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    note: json['note'] as String?,
    emoji: json['emoji'] as String?,
    type: TaskType.values.byName(json['type'] as String),
    isCompleted: json['isCompleted'] as bool? ?? false,
    reminderTime: json['reminderTime'] != null
        ? DateTime.parse(json['reminderTime'] as String)
        : null,
    subtasks:
        (json['subtasks'] as List<dynamic>?)
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
    dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : null,
    recurrence: json['recurrence'] != null
        ? TaskRecurrence.fromJson(json['recurrence'] as Map<String, dynamic>)
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

  /// Purpose: Create a daily completion log instance.
  /// Inputs: None.
  /// Returns: A new `DailyCompletionLog` instance.
  /// Side effects: None.
  /// Notes: None.
  DailyCompletionLog();

  /// Purpose: Implement the date key behavior for this file.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: None.
  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Purpose: Implement the is completed behavior for this file.
  /// Inputs: `date`, `taskId`.
  /// Returns: `bool`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: None.
  bool isCompleted(DateTime date, String taskId) {
    return _log[dateKey(date)]?.contains(taskId) ?? false;
  }

  /// Purpose: Implement the toggle behavior for this file.
  /// Inputs: `date`, `taskId`.
  /// Returns: None.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: None.
  void toggle(DateTime date, String taskId) {
    final key = dateKey(date);
    _log.putIfAbsent(key, () => {});
    if (_log[key]!.contains(taskId)) {
      _log[key]!.remove(taskId);
    } else {
      _log[key]!.add(taskId);
    }
  }

  /// Purpose: Implement the completed ids behavior for this file.
  /// Inputs: `date`.
  /// Returns: `Set<String>`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: None.
  Set<String> completedIds(DateTime date) => _log[dateKey(date)] ?? {};

  // --- Subtask per-date tracking ---

  /// Purpose: Implement the is subtask completed behavior for this file.
  /// Inputs: `date`, `subtaskId`.
  /// Returns: `bool`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: None.
  bool isSubtaskCompleted(DateTime date, String subtaskId) {
    return _subLog[dateKey(date)]?.contains(subtaskId) ?? false;
  }

  /// Purpose: Implement the toggle subtask behavior for this file.
  /// Inputs: `date`, `subtaskId`.
  /// Returns: None.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: None.
  void toggleSubtask(DateTime date, String subtaskId) {
    final key = dateKey(date);
    _subLog.putIfAbsent(key, () => {});
    if (_subLog[key]!.contains(subtaskId)) {
      _subLog[key]!.remove(subtaskId);
    } else {
      _subLog[key]!.add(subtaskId);
    }
  }

  /// Purpose: Implement the set subtasks completed behavior for this file.
  /// Inputs: `date`, `subtaskIds`, `completed`.
  /// Returns: None.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: None.
  void setSubtasksCompleted(
    DateTime date,
    Iterable<String> subtaskIds,
    bool completed,
  ) {
    final key = dateKey(date);
    _subLog.putIfAbsent(key, () => {});
    if (completed) {
      _subLog[key]!.addAll(subtaskIds);
    } else {
      _subLog[key]!.removeAll(subtaskIds);
    }
  }

  /// Purpose: Implement the completed subtask ids behavior for this file.
  /// Inputs: `date`.
  /// Returns: `Set<String>`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: None.
  Set<String> completedSubtaskIds(DateTime date) =>
      _subLog[dateKey(date)] ?? {};

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'tasks': _log.map((key, value) => MapEntry(key, value.toList())),
    'subtasks': _subLog.map((key, value) => MapEntry(key, value.toList())),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `DailyCompletionLog.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory DailyCompletionLog.fromJson(Map<String, dynamic> json) {
    final log = DailyCompletionLog();
    // Support old format (flat map of date→taskIds) and new format ({tasks, subtasks})
    if (json.containsKey('tasks')) {
      (json['tasks'] as Map<String, dynamic>).forEach((key, value) {
        log._log[key] = (value as List<dynamic>)
            .map((e) => e as String)
            .toSet();
      });
      if (json['subtasks'] != null) {
        (json['subtasks'] as Map<String, dynamic>).forEach((key, value) {
          log._subLog[key] = (value as List<dynamic>)
              .map((e) => e as String)
              .toSet();
        });
      }
    } else {
      // Old format: flat map is task log only
      json.forEach((key, value) {
        log._log[key] = (value as List<dynamic>)
            .map((e) => e as String)
            .toSet();
      });
    }
    return log;
  }

  /// Merge two logs by taking the union of completed IDs per date.
  /// Purpose: Create a daily completion log instance.
  /// Inputs: `a`, `b`.
  /// Returns: A new `DailyCompletionLog.merge` instance.
  /// Side effects: None.
  /// Notes: None.
  factory DailyCompletionLog.merge(DailyCompletionLog a, DailyCompletionLog b) {
    final merged = DailyCompletionLog();
    final allDates = {...a._log.keys, ...b._log.keys};
    for (final date in allDates) {
      merged._log[date] = {...(a._log[date] ?? {}), ...(b._log[date] ?? {})};
    }
    final allSubDates = {...a._subLog.keys, ...b._subLog.keys};
    for (final date in allSubDates) {
      merged._subLog[date] = {
        ...(a._subLog[date] ?? {}),
        ...(b._subLog[date] ?? {}),
      };
    }
    return merged;
  }
}

class DailyScoreEntry {
  final int score;
  final DateTime modifiedAt;

  /// Purpose: Create a per-day score entry.
  /// Inputs: `score`, `modifiedAt`.
  /// Returns: A new `DailyScoreEntry` instance.
  /// Side effects: None.
  /// Notes: Scores are clamped to the supported todo day-score range.
  DailyScoreEntry({required int score, DateTime? modifiedAt})
    : score = DailyScoreLog.normalizeScore(score),
      modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Serialize this score entry into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'score': score,
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create a score entry from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `DailyScoreEntry` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading persisted or synced todo scores.
  factory DailyScoreEntry.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'];
    return DailyScoreEntry(
      score: rawScore is num ? rawScore.round() : 0,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Tracks a user-assigned score for each todo day.
/// Key = date string 'yyyy-MM-dd', Value = score entry for that day.
class DailyScoreLog {
  static const int minScore = -5;
  static const int maxScore = 5;

  final Map<String, DailyScoreEntry> _scores = {};

  /// Purpose: Create an empty daily score log.
  /// Inputs: None.
  /// Returns: A new `DailyScoreLog` instance.
  /// Side effects: None.
  /// Notes: Missing dates read as the default score of zero.
  DailyScoreLog();

  /// Purpose: Clamp a raw score into the supported todo score range.
  /// Inputs: `score`.
  /// Returns: An integer between -5 and 5.
  /// Side effects: None.
  /// Notes: Use this before storing scores from UI, API, or JSON input.
  static int normalizeScore(int score) =>
      score.clamp(minScore, maxScore).toInt();

  /// Purpose: Return whether this log has no explicit score entries.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: An absent score is still displayed to users as zero.
  bool get isEmpty => _scores.isEmpty;

  /// Purpose: Read the score for a day.
  /// Inputs: `date`.
  /// Returns: The stored score, or zero when no score exists for the day.
  /// Side effects: None.
  /// Notes: Dates are normalized to yyyy-MM-dd keys.
  int scoreFor(DateTime date) {
    return _scores[DailyCompletionLog.dateKey(date)]?.score ?? 0;
  }

  /// Purpose: Store the score for a day.
  /// Inputs: `date`, `score`, `modifiedAt`.
  /// Returns: None.
  /// Side effects: Mutates this log's explicit score entry for the day.
  /// Notes: Setting zero is preserved so resets can sync across devices.
  void setScore(DateTime date, int score, {DateTime? modifiedAt}) {
    _scores[DailyCompletionLog.dateKey(date)] = DailyScoreEntry(
      score: score,
      modifiedAt: modifiedAt,
    );
  }

  /// Purpose: Serialize this score log into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map keyed by yyyy-MM-dd date strings.
  /// Side effects: None.
  /// Notes: Keys are sorted for stable persisted output.
  Map<String, dynamic> toJson() {
    final sortedKeys = _scores.keys.toList()..sort();
    return {for (final key in sortedKeys) key: _scores[key]!.toJson()};
  }

  /// Purpose: Create a score log from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `DailyScoreLog` instance.
  /// Side effects: None.
  /// Notes: Legacy numeric values are accepted with an epoch modified time.
  factory DailyScoreLog.fromJson(Map<String, dynamic> json) {
    final log = DailyScoreLog();
    json.forEach((key, value) {
      if (value is Map) {
        log._scores[key] = DailyScoreEntry.fromJson(
          value.map(
            (childKey, childValue) => MapEntry(childKey as String, childValue),
          ),
        );
      } else if (value is num) {
        log._scores[key] = DailyScoreEntry(
          score: value.round(),
          modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
        );
      }
    });
    return log;
  }

  /// Purpose: Merge two daily score logs.
  /// Inputs: `local`, `remote`.
  /// Returns: A new `DailyScoreLog` containing the latest entry for each day.
  /// Side effects: None.
  /// Notes: Equal timestamps prefer the local entry for deterministic sync.
  factory DailyScoreLog.merge(DailyScoreLog local, DailyScoreLog remote) {
    final merged = DailyScoreLog();
    final allDates = {...local._scores.keys, ...remote._scores.keys};
    for (final date in allDates) {
      final localEntry = local._scores[date];
      final remoteEntry = remote._scores[date];
      if (localEntry == null) {
        merged._scores[date] = remoteEntry!;
      } else if (remoteEntry == null ||
          localEntry.modifiedAt.isAfter(remoteEntry.modifiedAt) ||
          localEntry.modifiedAt == remoteEntry.modifiedAt) {
        merged._scores[date] = localEntry;
      } else {
        merged._scores[date] = remoteEntry;
      }
    }
    return merged;
  }
}

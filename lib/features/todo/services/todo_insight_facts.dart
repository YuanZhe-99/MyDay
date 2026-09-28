import '../../ai/services/insight_prompts.dart';
import '../models/task.dart';

/// Purpose: Drop the time of day.
/// Inputs: `d`.
/// Returns: `DateTime` at local midnight.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Purpose: List the daily templates shown on a date.
/// Inputs: `templates`, `date`.
/// Returns: `List<Task>`.
/// Side effects: None.
/// Notes: Same rule as the Todo page: visible from `startDate ?? createdDate`
/// until the day before `deletedDate`.
List<Task> dailyTemplatesOn(List<Task> templates, DateTime date) {
  final d = _day(date);
  return templates.where((t) {
    final start = _day(t.startDate ?? t.createdDate);
    return !start.isAfter(d) &&
        (t.deletedDate == null || _day(t.deletedDate!).isAfter(d));
  }).toList();
}

/// Purpose: Decide whether a one-time task is shown on a date.
/// Inputs: `t`, `date`, `today`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Same rule as the Todo page: a completed task shows on its scheduled
/// and completed dates; an open task shows on its scheduled date and is
/// carried forward from then through today.
bool oneTimeVisibleOn(Task t, DateTime date, DateTime today) {
  if (t.scheduledDate == null) return false;
  final sel = _day(date);
  final sched = _day(t.scheduledDate!);
  if (t.isCompleted && t.completedDate != null) {
    final done = _day(t.completedDate!);
    return sel == sched || sel == done;
  }
  final t0 = _day(today);
  return sel == sched || (!sched.isAfter(sel) && !sel.isAfter(t0));
}

/// Purpose: Format a time of day.
/// Inputs: `d`.
/// Returns: `HH:mm`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Purpose: Join task titles for one fact line, capped.
/// Inputs: `titles`, `max`.
/// Returns: `String` — `none` when empty, `+k more` when capped.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
String _list(List<String> titles, int max) {
  if (titles.isEmpty) return 'none';
  final shown = titles.take(max).join('; ');
  final more = titles.length - max;
  return more > 0 ? '$shown; +$more more' : shown;
}

/// Purpose: Count the tasks in a list that are overdue on a date.
/// Inputs: `tasks`, `today`.
/// Returns: `int`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
int _overdue(List<Task> tasks, DateTime today) => tasks
    .where((t) => t.dueDate != null && _day(t.dueDate!).isBefore(today))
    .length;

/// Purpose: Build the Todo card's facts for the current time of day.
/// Inputs: `now` — local time; the page's `dailyTemplates`, `oneTimeTasks`,
/// `dailyLog`, `dailyScores`; `maxTasks` per line; `maxTitleRunes` per
/// title; `includeTitles` — false builds the counts-only variant the store
/// falls back to when the model declines or returns nothing for the titled
/// one.
/// Returns: `InsightFacts?` — null when there is nothing on today or
/// tomorrow to talk about.
/// Side effects: None.
/// Notes: Task titles are sent (a plan needs them), trimmed and capped, each
/// with at most one qualifier: `overdue`, `due <date>` or a reminder time.
/// Task notes and subtask titles never are. Morning (before 12:00): today's
/// plan. Afternoon (12:00–18:00): progress and what is left. Evening (from
/// 18:00): a review of today and a suggestion for tomorrow. Kept deliberately
/// plain since v1.5.1: the on-device model answered the other modules but not
/// the longer, more decorated Todo prompt of v1.5.0.
InsightFacts? buildTodoInsightFacts({
  required DateTime now,
  required List<Task> dailyTemplates,
  required List<Task> oneTimeTasks,
  required DailyCompletionLog dailyLog,
  required DailyScoreLog dailyScores,
  int maxTasks = 8,
  int maxTitleRunes = 24,
  bool includeTitles = true,
}) {
  final today = _day(now);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final bucket = todoBucketFor(now);
  String title(Task t) => clipTitle(t.title, maxTitleRunes);

  final daily = dailyTemplatesOn(dailyTemplates, today);
  final doneIds = dailyLog.completedIds(today);
  final dailyDone = daily.where((t) => doneIds.contains(t.id)).toList();
  final dailyOpen = daily.where((t) => !doneIds.contains(t.id)).toList();

  final oneTime = oneTimeTasks
      .where((t) => oneTimeVisibleOn(t, today, today))
      .toList();
  final oneDone = oneTime.where((t) => t.isCompleted).toList();
  final oneOpen = oneTime.where((t) => !t.isCompleted).toList();

  String describeOpen(Task t) {
    final due = t.dueDate;
    final r = t.reminderTime;
    final String? qualifier;
    if (due != null && _day(due).isBefore(today)) {
      qualifier = 'overdue';
    } else if (due != null) {
      qualifier = 'due ${factDate(due)}';
    } else if (r != null) {
      qualifier = _hm(r);
    } else {
      qualifier = null;
    }
    return qualifier == null ? title(t) : '${title(t)} ($qualifier)';
  }

  String openCounts(List<Task> habits, List<Task> tasks) {
    final parts = <String>[];
    if (habits.isNotEmpty) parts.add('${habits.length} daily habits');
    if (tasks.isNotEmpty) {
      final overdue = _overdue(tasks, today);
      parts.add(
        '${tasks.length} one-off tasks'
        '${overdue > 0 ? ' ($overdue overdue)' : ''}',
      );
    }
    return parts.isEmpty ? 'none' : parts.join(', ');
  }

  final tomorrowDaily = dailyTemplatesOn(dailyTemplates, tomorrow);
  final tomorrowOne = oneTimeTasks
      .where(
        (t) =>
            !t.isCompleted &&
            t.scheduledDate != null &&
            _day(t.scheduledDate!) == tomorrow,
      )
      .toList();

  if (daily.isEmpty &&
      oneTime.isEmpty &&
      (bucket != InsightTimeBucket.evening ||
          (tomorrowDaily.isEmpty && tomorrowOne.isEmpty))) {
    return null;
  }

  final quoted = includeTitles
      ? <String>{
          for (final t in [...daily, ...oneTime, ...tomorrowOne]) title(t),
        }.toList()
      : const <String>[];

  final lines = <String>[
    '- Today: ${factDate(today)} (${factWeekday(today)})',
  ];
  final List<InsightSlot> slots;
  switch (bucket) {
    case InsightTimeBucket.morning:
    case InsightTimeBucket.none:
      if (includeTitles) {
        lines
          ..add(
            '- Daily habits today (${daily.length}): '
            '${_list([for (final t in daily) title(t)], maxTasks)}',
          )
          ..add(
            '- One-off tasks today (${oneOpen.length} open): '
            '${_list([for (final t in oneOpen) describeOpen(t)], maxTasks)}',
          );
      } else {
        lines
          ..add('- Daily habits today: ${daily.length}')
          ..add('- One-off tasks today: ${openCounts(const [], oneOpen)}');
      }
      final score = dailyScores.scoreFor(yesterday);
      if (score != 0) {
        lines.add("- Yesterday's self-rating: $score on a -5 to 5 scale");
      }
      slots = const [
        InsightSlot('plan', "Today's plan, in one sentence."),
        InsightSlot('first', 'Which task to start with, and why.'),
        InsightSlot('tip', 'One practical tip for today.'),
      ];
    case InsightTimeBucket.afternoon:
      final ahead = [
        for (final t in [...dailyOpen, ...oneOpen])
          if (t.reminderTime != null &&
              (t.reminderTime!.hour * 60 + t.reminderTime!.minute) >
                  now.hour * 60 + now.minute)
            includeTitles
                ? '${title(t)} at ${_hm(t.reminderTime!)}'
                : _hm(t.reminderTime!),
      ];
      lines.add(
        '- Done so far: ${dailyDone.length} of ${daily.length} daily habits, '
        '${oneDone.length} of ${oneTime.length} one-off tasks',
      );
      if (includeTitles) {
        lines.add(
          '- Still open: '
          '${_list([for (final t in dailyOpen) title(t), for (final t in oneOpen) describeOpen(t)], maxTasks)}',
        );
      } else {
        lines.add('- Still open: ${openCounts(dailyOpen, oneOpen)}');
      }
      if (ahead.isNotEmpty) {
        lines.add('- Reminders still ahead today: ${_list(ahead, maxTasks)}');
      }
      slots = const [
        InsightSlot('progress', 'How today is going so far.'),
        InsightSlot('remaining', 'What to focus on for the rest of the day.'),
        InsightSlot('tip', 'One practical tip for the afternoon.'),
      ];
    case InsightTimeBucket.evening:
      lines.add(
        '- Done today: ${dailyDone.length} of ${daily.length} daily habits, '
        '${oneDone.length} of ${oneTime.length} one-off tasks',
      );
      if (includeTitles) {
        lines
          ..add(
            '- Completed: '
            '${_list([for (final t in [...dailyDone, ...oneDone]) title(t)], maxTasks)}',
          )
          ..add(
            '- Left undone: '
            '${_list([for (final t in [...dailyOpen, ...oneOpen]) title(t)], maxTasks)}',
          );
      } else {
        lines.add('- Left undone: ${openCounts(dailyOpen, oneOpen)}');
      }
      final score = dailyScores.scoreFor(today);
      if (score != 0) {
        lines.add("- Today's self-rating: $score on a -5 to 5 scale");
      }
      lines.add('- Daily habits tomorrow: ${tomorrowDaily.length}');
      if (includeTitles) {
        lines.add(
          '- One-off tasks scheduled for tomorrow: '
          '${_list([for (final t in tomorrowOne) title(t)], maxTasks)}',
        );
      } else {
        lines.add(
          '- One-off tasks scheduled for tomorrow: ${tomorrowOne.length}',
        );
      }
      slots = const [
        InsightSlot('summary', 'How today went.'),
        InsightSlot(
          'tomorrow',
          'What to do first tomorrow, counting anything left undone.',
        ),
        InsightSlot('encouragement', 'One short, sincere encouragement.'),
      ];
  }
  return InsightFacts(
    module: InsightModule.todo,
    bucket: bucket,
    lines: lines,
    slots: slots,
    quotedTerms: quoted,
  );
}

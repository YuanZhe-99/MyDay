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

/// Purpose: Build the Todo card's facts for the current time of day.
/// Inputs: `now` — local time; the page's `dailyTemplates`, `oneTimeTasks`,
/// `dailyLog`, `dailyScores`; `maxTasks` per line; `maxTitleRunes` per title.
/// Returns: `InsightFacts?` — null when there is nothing on today or
/// tomorrow to talk about.
/// Side effects: None.
/// Notes: Task titles are sent (a plan needs them), trimmed and capped. Task
/// notes and subtask titles never are. Morning (before 12:00): today's plan.
/// Afternoon (12:00–18:00): progress and what is left. Evening (from 18:00):
/// a review of today and a suggestion for tomorrow.
InsightFacts? buildTodoInsightFacts({
  required DateTime now,
  required List<Task> dailyTemplates,
  required List<Task> oneTimeTasks,
  required DailyCompletionLog dailyLog,
  required DailyScoreLog dailyScores,
  int maxTasks = 12,
  int maxTitleRunes = 40,
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
    final parts = <String>[t.type == TaskType.workOnce ? 'work' : 'routine'];
    final sched = t.scheduledDate;
    if (sched != null && _day(sched).isBefore(today)) {
      parts.add('carried over since ${factDate(sched)}');
    }
    final due = t.dueDate;
    if (due != null) {
      parts.add(
        _day(due).isBefore(today)
            ? 'overdue since ${factDate(due)}'
            : 'due ${factDate(due)}',
      );
    }
    final r = t.reminderTime;
    if (r != null) parts.add('reminder ${_hm(r)}');
    return '${title(t)} (${parts.join(', ')})';
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

  final quoted = <String>{
    for (final t in [...daily, ...oneTime, ...tomorrowOne]) title(t),
  }.toList();

  final lines = <String>[
    '- Today: ${factDate(today)} (${factWeekday(today)})',
  ];
  final List<InsightSlot> slots;
  switch (bucket) {
    case InsightTimeBucket.morning:
    case InsightTimeBucket.none:
      lines
        ..add(
          '- Daily habits today (${daily.length}): '
          '${_list([for (final t in daily) title(t)], maxTasks)}',
        )
        ..add(
          '- One-off tasks today (${oneOpen.length} open): '
          '${_list([for (final t in oneOpen) describeOpen(t)], maxTasks)}',
        );
      final score = dailyScores.scoreFor(yesterday);
      if (score != 0) lines.add("- Yesterday's self-rating (-5..5): $score");
      slots = const [
        InsightSlot('plan', "Sum up today's plan in one sentence."),
        InsightSlot('first', 'Which one or two tasks to start with, and why.'),
        InsightSlot('tip', 'One practical tip for getting through today.'),
      ];
    case InsightTimeBucket.afternoon:
      final ahead = [
        for (final t in [...dailyOpen, ...oneOpen])
          if (t.reminderTime != null &&
              (t.reminderTime!.hour * 60 + t.reminderTime!.minute) >
                  now.hour * 60 + now.minute)
            '${title(t)} at ${_hm(t.reminderTime!)}',
      ];
      lines
        ..add(
          '- Done so far: ${dailyDone.length} of ${daily.length} daily habits, '
          '${oneDone.length} of ${oneTime.length} one-off tasks',
        )
        ..add(
          '- Still open: '
          '${_list([for (final t in dailyOpen) title(t), for (final t in oneOpen) describeOpen(t)], maxTasks)}',
        )
        ..add('- Reminders still ahead today: ${_list(ahead, maxTasks)}');
      slots = const [
        InsightSlot('progress', 'Describe how today is going so far.'),
        InsightSlot('remaining', 'What to focus on for the rest of the day.'),
        InsightSlot('tip', 'One practical tip for the afternoon.'),
      ];
    case InsightTimeBucket.evening:
      lines
        ..add(
          '- Done today: ${dailyDone.length} of ${daily.length} daily habits, '
          '${oneDone.length} of ${oneTime.length} one-off tasks',
        )
        ..add(
          '- Completed: '
          '${_list([for (final t in [...dailyDone, ...oneDone]) title(t)], maxTasks)}',
        )
        ..add(
          '- Left undone: '
          '${_list([for (final t in [...dailyOpen, ...oneOpen]) title(t)], maxTasks)}',
        );
      final score = dailyScores.scoreFor(today);
      if (score != 0) lines.add("- Today's self-rating (-5..5): $score");
      lines
        ..add('- Daily habits tomorrow: ${tomorrowDaily.length}')
        ..add(
          '- One-off tasks scheduled for tomorrow: '
          '${_list([for (final t in tomorrowOne) title(t)], maxTasks)}',
        );
      slots = const [
        InsightSlot('summary', 'Sum up how today went.'),
        InsightSlot(
          'tomorrow',
          'Suggest what to do first tomorrow, including anything left undone.',
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

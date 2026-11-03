import 'package:myapps_widget/myapps_widget.dart';

import '../../features/intimacy/models/intimacy_record.dart';
import '../../features/intimacy/utils/thrust_timeline.dart';
import '../../features/todo/models/task.dart';
import '../../features/todo/services/todo_storage.dart';
import 'home_widget_payloads.dart';

/// The result of applying widget actions to one data file.
class HomeWidgetActionResult<T> {
  /// Purpose: Hold the outcome of an apply pass.
  /// Inputs: `data` — the data after the actions; `applied` — ids of every
  /// action consumed (including skipped ones); `changed` — whether `data`
  /// differs from the input.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: Skipped actions are still "applied" so they leave the queue.
  const HomeWidgetActionResult({
    required this.data,
    required this.applied,
    required this.changed,
  });

  /// The data after the actions.
  final T data;

  /// Ids of every consumed action, in queue order.
  final List<String> applied;

  /// Whether anything changed and needs writing.
  final bool changed;
}

/// Pure appliers for the actions queued by interactive widget controls.
/// The semantics match the native overlays described in
/// `doc/en-us/features/home-screen-widgets.md`.
abstract final class HomeWidgetActions {
  /// Purpose: Apply queued `myday.todo` actions to Todo data.
  /// Inputs: `data`; `actions` — oldest first; `now` — for `modifiedAt`.
  /// Returns: The updated data, consumed ids and whether anything changed.
  /// Side effects: Mutates `data.dailyLog` in place when a daily task changes.
  /// Notes: `setDone` sets a state, so a re-delivered action is harmless.
  /// Completing a recurring one-time task is skipped (its checkbox opens the
  /// app instead, for the next-occurrence prompt); unknown ids are skipped.
  static HomeWidgetActionResult<TodoData> applyTodo(
    TodoData data,
    List<WidgetAction> actions, {
    DateTime? now,
  }) {
    final stamp = (now ?? DateTime.now()).toUtc();
    final oneTime = List<Task>.of(data.oneTimeTasks);
    final applied = <String>[];
    var changed = false;
    for (final action in actions) {
      applied.add(action.id);
      if (action.action != 'setDone') continue;
      final id = action.args['id'];
      final done = action.args['done'];
      final date = DateTime.tryParse('${action.args['date']}');
      if (id is! String || done is! bool || date == null) continue;
      final day = DateTime(date.year, date.month, date.day);
      final daily = data.dailyTemplates.where((t) => t.id == id).firstOrNull;
      if (daily != null) {
        if (data.dailyLog.isCompleted(day, id) == done) continue;
        data.dailyLog.toggle(day, id);
        if (daily.subtasks.isNotEmpty) {
          data.dailyLog.setSubtasksCompleted(
            day,
            daily.subtasks.map((s) => s.id),
            done,
          );
        }
        changed = true;
        continue;
      }
      final index = oneTime.indexWhere((t) => t.id == id);
      if (index < 0) continue;
      final t = oneTime[index];
      if (t.isCompleted == done) continue;
      if (done && t.recurrence != null) continue;
      oneTime[index] = Task(
        id: t.id,
        title: t.title,
        note: t.note,
        emoji: t.emoji,
        type: t.type,
        isCompleted: done,
        reminderTime: t.reminderTime,
        subtasks: [for (final s in t.subtasks) s.copyWith(isCompleted: done)],
        createdDate: t.createdDate,
        completedDate: done ? day : null,
        scheduledDate: t.scheduledDate,
        deletedDate: t.deletedDate,
        startDate: t.startDate,
        dueDate: t.dueDate,
        recurrence: t.recurrence,
        modifiedAt: stamp,
      );
      changed = true;
    }
    if (!changed) {
      return HomeWidgetActionResult(
        data: data,
        applied: applied,
        changed: false,
      );
    }
    return HomeWidgetActionResult(
      data: TodoData(
        dailyTemplates: data.dailyTemplates,
        oneTimeTasks: oneTime,
        dailyLog: data.dailyLog,
        dailyScores: data.dailyScores,
        morningReminderHour: data.morningReminderHour,
        morningReminderMinute: data.morningReminderMinute,
        completionReminderHour: data.completionReminderHour,
        completionReminderMinute: data.completionReminderMinute,
        taskSortModes: data.taskSortModes,
        taskCustomOrders: data.taskCustomOrders,
        settingsModifiedAt: data.settingsModifiedAt,
      ),
      applied: applied,
      changed: true,
    );
  }

  /// Purpose: Apply queued `myday.timer` actions to a timer session.
  /// Inputs: `session` — the current session or null; `actions` — oldest
  /// first.
  /// Returns: The new session, consumed ids and whether anything changed.
  /// Side effects: None.
  /// Notes: `start` creates or resumes at the tap instant, `pause` folds the
  /// running segment into the elapsed time, `add` records `n` repetitions at
  /// the elapsed time of the tap. Counts are stored like the timer page:
  /// unit 100 when the total is a multiple of 100, otherwise unit 1.
  static HomeWidgetActionResult<IntimacyTimerSession?> applyTimer(
    IntimacyTimerSession? session,
    List<WidgetAction> actions,
  ) {
    var firstStartedAt = session?.firstStartedAt;
    var startedAt = session?.running == true ? session?.startedAt : null;
    var accumulated = session?.accumulated ?? Duration.zero;
    var running = session?.running ?? false;
    var timeline = session == null
        ? ThrustTimeline.empty()
        : _timelineOf(session);
    final applied = <String>[];
    var changed = false;
    Duration elapsedAt(DateTime at) => running && startedAt != null
        ? accumulated + at.difference(startedAt)
        : accumulated;
    for (final action in actions) {
      applied.add(action.id);
      final at = action.at.toLocal();
      switch (action.action) {
        case 'start':
          if (running) continue;
          firstStartedAt ??= at;
          startedAt = at;
          running = true;
          changed = true;
        case 'pause':
          if (!running || startedAt == null) continue;
          final segment = at.difference(startedAt);
          accumulated += segment.isNegative ? Duration.zero : segment;
          startedAt = null;
          running = false;
          changed = true;
        case 'add':
          if (firstStartedAt == null) continue;
          final n = action.args['n'];
          final delta = n is num ? n.toInt() : HomeWidgetPayloads.timerStep;
          final next = timeline.add(elapsedAt(at).inMilliseconds, delta);
          if (identical(next, timeline)) continue;
          timeline = next;
          changed = true;
      }
    }
    if (!changed || firstStartedAt == null) {
      return HomeWidgetActionResult(
        data: session,
        applied: applied,
        changed: false,
      );
    }
    final total = timeline.total;
    final unit = total > 0 && total % 100 != 0 ? 1 : 100;
    return HomeWidgetActionResult(
      data: IntimacyTimerSession(
        firstStartedAt: firstStartedAt,
        startedAt: running ? startedAt : null,
        accumulated: accumulated,
        running: running,
        thrustCount: unit == 1 ? total : total ~/ 100,
        thrustCountUnit: unit,
        thrustTimeline: timeline,
      ),
      applied: applied,
      changed: true,
    );
  }

  /// Purpose: Return a session's thrust timeline, seeding one from its count.
  /// Inputs: `session`.
  /// Returns: `ThrustTimeline`.
  /// Side effects: None.
  /// Notes: Mirrors `TimerPage._restoreTimeline`, seeding pre-1.5.5 counts at
  /// the session's accumulated time.
  static ThrustTimeline _timelineOf(IntimacyTimerSession session) {
    final actual = HomeWidgetPayloads.sessionCount(session);
    final timeline = session.thrustTimeline;
    if (timeline != null && timeline.total == actual) return timeline;
    return ThrustTimeline.seed(session.accumulated.inMilliseconds, actual);
  }
}

import 'package:intl/intl.dart';

import '../../features/finance/models/finance.dart';
import '../../features/finance/services/balance_util.dart';
import '../../features/finance/services/exchange_rate_storage.dart';
import '../../features/finance/services/finance_storage.dart';
import '../../features/finance/services/subscription_summary.dart';
import '../../features/intimacy/models/intimacy_record.dart';
import '../../features/intimacy/services/cycle_predictor.dart';
import '../../features/todo/models/task.dart';
import '../../features/todo/services/todo_storage.dart';
import '../../features/weight/models/weight_record.dart';
import '../../l10n/app_localizations.dart';
import '../utils/week_grouping.dart';

/// Pure builders for the home-screen widget payloads. Each returns the
/// app-owned `payload` object of one MyApps-Widget envelope; the formats are
/// documented in `doc/en-us/features/home-screen-widgets.md`.
abstract final class HomeWidgetPayloads {
  /// Most Todo items written per day.
  static const maxTodoItems = 30;

  /// Most applied action ids carried in a payload.
  static const maxAppliedActions = 50;

  /// Most weights in the sparkline.
  static const maxWeightPoints = 30;

  /// Amount added by the timer widget's button.
  static const timerStep = 100;

  /// Purpose: Format a local calendar date as `yyyy-MM-dd`.
  /// Inputs: `date`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Same key as `DailyCompletionLog.dateKey`, used by the native readers.
  static String dayKey(DateTime date) => DailyCompletionLog.dateKey(date);

  /// Purpose: Format a time of day as `HH:mm`.
  /// Inputs: `time`, or null.
  /// Returns: `String`; empty for null.
  /// Side effects: None.
  /// Notes: Uses the value's own wall clock.
  static String hhmm(DateTime? time) => time == null
      ? ''
      : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  // ── Todo ──────────────────────────────────────────────────────────────

  /// Purpose: Build the `myday.todo` payload.
  /// Inputs: `data` (null when no file exists); `now` — local time; `l10n`;
  /// `localeTag` for date labels; `appliedActions`; `mask`.
  /// Returns: The payload map with today and tomorrow.
  /// Side effects: None.
  /// Notes: Each day lists what the Todo page would show for that date.
  static Map<String, dynamic> todo(
    TodoData? data, {
    required DateTime now,
    required AppLocalizations l10n,
    required String localeTag,
    List<String> appliedActions = const [],
    bool mask = false,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final dateFormat = DateFormat.MMMEd(localeTag);
    return {
      'days': [
        for (final day in [today, addCalendarDays(today, 1)])
          {
            'date': dayKey(day),
            'label': dateFormat.format(day),
            'score': data?.dailyScores.scoreFor(day),
            'items': data == null
                ? const <Map<String, dynamic>>[]
                : todoItems(data, day: day, today: today),
          },
      ],
      'appliedActions': _tail(appliedActions),
      'mask': mask,
      'labels': {
        'new': l10n.hwTodoNew,
        'left': l10n.hwTodoLeft('{n}'),
        'progress': l10n.hwTodoProgress('{n}', '{m}'),
        'tomorrow': l10n.hwTodoTomorrow,
        'overdue': l10n.hwTodoOverdue,
        'allDone': l10n.hwTodoAllDone,
        'nothing': l10n.hwTodoNothing,
        'score': l10n.hwTodoScore,
        'stale': l10n.hwOpenToUpdate,
        'placeholder': 'MyDay',
      },
    };
  }

  /// Purpose: List one day's Todo rows in display order.
  /// Inputs: `data`; `day` — the date shown; `today` — the real current date.
  /// Returns: Up to [maxTodoItems] item maps.
  /// Side effects: None.
  /// Notes: Visibility mirrors `TodoPage._dailyForDate` and
  /// `_oneTimeVisibleOnDate`. Order: overdue, open by reminder time (none
  /// last, section order as tie-break), then completed.
  static List<Map<String, dynamic>> todoItems(
    TodoData data, {
    required DateTime day,
    required DateTime today,
  }) {
    DateTime d(DateTime v) => DateTime(v.year, v.month, v.day);
    final rows = <(Map<String, dynamic>, int, bool, bool, String)>[];
    var index = 0;
    for (final t in data.dailyTemplates) {
      if (t.type != TaskType.daily) continue;
      final start = d(t.startDate ?? t.createdDate);
      if (start.isAfter(day)) continue;
      if (t.deletedDate != null && !d(t.deletedDate!).isAfter(day)) continue;
      final done = data.dailyLog.isCompleted(day, t.id);
      rows.add((
        _todoItem(t, done: done),
        index++,
        false,
        done,
        hhmm(t.reminderTime),
      ));
    }
    for (final type in [TaskType.routineOnce, TaskType.workOnce]) {
      for (final t in data.oneTimeTasks) {
        if (t.type != type || t.scheduledDate == null) continue;
        final sched = d(t.scheduledDate!);
        final bool visible;
        if (t.isCompleted && t.completedDate != null) {
          visible = sched == day || d(t.completedDate!) == day;
        } else {
          visible =
              sched == day ||
              (!sched.isAfter(day) && !day.isAfter(addCalendarDays(today, 1)));
        }
        if (!visible) continue;
        final due = t.dueDate == null ? null : d(t.dueDate!);
        final late =
            !t.isCompleted &&
            (sched.isBefore(day) || (due != null && due.isBefore(day)));
        rows.add((
          _todoItem(t, done: t.isCompleted, late: late, sched: sched == day),
          index++,
          late,
          t.isCompleted,
          hhmm(t.reminderTime),
        ));
      }
    }
    rows.sort((a, b) {
      int rank(bool late, bool done) => done ? 2 : (late ? 0 : 1);
      final byRank = rank(a.$3, a.$4).compareTo(rank(b.$3, b.$4));
      if (byRank != 0) return byRank;
      if (!a.$4 && a.$5 != b.$5) {
        if (a.$5.isEmpty) return 1;
        if (b.$5.isEmpty) return -1;
        return a.$5.compareTo(b.$5);
      }
      return a.$2.compareTo(b.$2);
    });
    return [for (final r in rows.take(maxTodoItems)) r.$1];
  }

  /// Purpose: Serialize one Todo row.
  /// Inputs: `t`; `done`; optional `late`, `sched`.
  /// Returns: The item map.
  /// Side effects: None.
  /// Notes: Short keys keep the shared store small.
  static Map<String, dynamic> _todoItem(
    Task t, {
    required bool done,
    bool late = false,
    bool sched = false,
  }) => {
    'id': t.id,
    't': t.title,
    'e': t.emoji ?? '',
    'k': t.type.name,
    'done': done,
    'time': hhmm(t.reminderTime),
    'late': late,
    'rec': t.type != TaskType.daily && t.recurrence != null,
    'sched': sched,
  };

  // ── Weight ────────────────────────────────────────────────────────────

  /// Purpose: Build the `myday.weight` payload.
  /// Inputs: `data` (null without a file); `now`; `l10n`; `mask`.
  /// Returns: The payload map.
  /// Side effects: None.
  /// Notes: `change30` compares with the latest record at or before 30 days
  /// earlier, falling back to the oldest record of the last 30 days.
  static Map<String, dynamic> weight(
    WeightData? data, {
    required DateTime now,
    required AppLocalizations l10n,
    bool mask = false,
  }) {
    final records = [...?data?.records]
      ..sort((a, b) => a.datetime.compareTo(b.datetime));
    final latest = records.isEmpty ? null : records.last;
    double? change30;
    double? previous;
    double? bmi;
    var points = <double>[];
    if (latest != null) {
      final cutoff = latest.datetime.subtract(const Duration(days: 30));
      final before = records.where((r) => !r.datetime.isAfter(cutoff));
      final window = records.where((r) => r.datetime.isAfter(cutoff)).toList();
      final base = before.isNotEmpty ? before.last : window.first;
      if (!identical(base, latest)) {
        change30 = _round1(latest.weight - base.weight);
      }
      if (records.length > 1) previous = records[records.length - 2].weight;
      bmi = WeightData.calculateBMI(data?.height, latest.weight);
      points = [
        for (final r in window.skip(
          window.length > maxWeightPoints ? window.length - maxWeightPoints : 0,
        ))
          _round1(r.weight),
      ];
    }
    final remind =
        data != null &&
            data.reminderMode != 'none' &&
            data.morningHour != null &&
            data.morningMinute != null
        ? hhmm(DateTime(2000, 1, 1, data.morningHour!, data.morningMinute!))
        : '';
    return {
      'latest': latest == null
          ? null
          : {
              'kg': _round1(latest.weight),
              'at': latest.datetime.toUtc().millisecondsSinceEpoch,
            },
      'previousKg': previous == null ? null : _round1(previous),
      'change30': change30,
      'bmi': bmi == null ? null : _round1(bmi),
      'points': points,
      'remindAt': remind,
      'mask': mask,
      'labels': {
        'title': l10n.hwWeightTitle,
        'log': l10n.hwWeightLog,
        'unit': 'kg',
        'change30': l10n.hwWeight30Days,
        'bmi': 'BMI',
        'notLogged': l10n.hwWeightNotLogged,
        'noData': l10n.hwNoRecords,
        'today': l10n.hwTodayAt('{n}'),
        'daysAgo': l10n.hwDaysAgo('{n}'),
        'placeholder': 'MyDay',
        'stale': l10n.hwOpenToUpdate,
      },
    };
  }

  // ── Finance ───────────────────────────────────────────────────────────

  /// Purpose: Build the `myday.finance` payload.
  /// Inputs: `data` (null without a file); `rates`; `now`; `l10n`;
  /// `localeTag`; `mask`.
  /// Returns: The payload map with formatted amounts.
  /// Side effects: None.
  /// Notes: Totals match the Finance home summary: every expense and income
  /// transaction of the calendar month, converted at its own rate snapshot.
  static Map<String, dynamic> finance(
    FinanceData? data, {
    required ExchangeRateData rates,
    required DateTime now,
    required AppLocalizations l10n,
    required String localeTag,
    bool mask = false,
  }) {
    final currency = data?.defaultCurrency ?? 'CNY';
    final symbol = currencySymbol(currency);
    final format = NumberFormat('#,##0.##');
    String money(double v) =>
        '${v < 0 ? '-' : ''}$symbol${format.format(v.abs())}';
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);
    var expense = 0.0;
    var income = 0.0;
    final byCategory = <String, double>{};
    for (final t in data?.transactions ?? const <Transaction>[]) {
      if (t.date.isBefore(start) || !t.date.isBefore(end)) continue;
      if (t.type == TransactionType.transfer) continue;
      final v = convertCurrency(
        rates.ratesAt(t.rateSnapshotId),
        t.amount,
        t.currency,
        currency,
      );
      if (t.type == TransactionType.expense) {
        expense += v;
        byCategory[t.categoryId ?? ''] =
            (byCategory[t.categoryId ?? ''] ?? 0) + v;
      } else {
        income += v;
      }
    }
    Map<String, dynamic>? top;
    if (byCategory.isNotEmpty && expense > 0) {
      final best = byCategory.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      final category = data?.categories
          .where((c) => c.id == best.key)
          .firstOrNull;
      top = {
        'name': category?.name ?? l10n.hwFinanceUncategorized,
        'emoji': category?.emoji ?? '',
        'amount': money(best.value),
        'share': (best.value / expense * 100).round(),
      };
    }
    final dayFormat = DateFormat.Md(localeTag);
    final bills = [
      for (final (sub, at) in upcomingSubscriptions(
        data?.subscriptions ?? const [],
        days: 7,
        now: now,
      ).take(3))
        {
          'name': sub.name,
          'emoji': sub.emoji ?? '',
          'day': dayKey(at),
          'date': dayFormat.format(at),
          'amount':
              '${currencySymbol(sub.currency)}${format.format(sub.amount)}',
        },
    ];
    return {
      'month': DateFormat('yyyy-MM').format(start),
      'monthLabel': DateFormat.MMMM(localeTag).format(start),
      'expense': money(expense),
      'income': money(income),
      'net': money(income - expense),
      'netNegative': income - expense < 0,
      'top': top,
      'bills': bills,
      'mask': mask,
      'labels': {
        'add': l10n.hwFinanceAdd,
        'expense': l10n.hwFinanceExpense,
        'income': l10n.hwFinanceIncome,
        'net': l10n.hwFinanceNet,
        'top': l10n.hwFinanceTop,
        'billsSoon': l10n.hwFinanceBillsSoon('{n}'),
        'noBills': l10n.hwFinanceNoBills,
        'placeholder': 'MyDay',
        'stale': l10n.hwOpenToUpdate,
      },
    };
  }

  // ── Intimacy ──────────────────────────────────────────────────────────

  /// Purpose: Build the `myday.intimacy` payload.
  /// Inputs: `data` (null without a file); `now`; `l10n`; `mask`.
  /// Returns: The payload map.
  /// Side effects: None.
  /// Notes: The cycle line uses only the user's own records (`personId`
  /// null) and only when the user's cycle tracking is enabled.
  static Map<String, dynamic> intimacy(
    IntimacyData? data, {
    required DateTime now,
    required AppLocalizations l10n,
    bool mask = false,
  }) {
    final records = data?.records ?? const <IntimacyRecord>[];
    final last = records.isEmpty
        ? null
        : records.reduce((a, b) => a.datetime.isAfter(b.datetime) ? a : b);
    final month = records
        .where(
          (r) => r.datetime.year == now.year && r.datetime.month == now.month,
        )
        .toList();
    final timed = month.where((r) => r.duration > Duration.zero).toList();
    final avg = timed.isEmpty
        ? null
        : (timed.fold<int>(0, (s, r) => s + r.duration.inSeconds) /
                  timed.length /
                  60)
              .round();
    var cycleNext = '';
    if (data?.userBody?.cycleEnabled == true) {
      final today = DateTime(now.year, now.month, now.day);
      final prediction = predictCycle(
        actualStarts: [
          for (final c in data!.cycleRecords)
            if (c.personId == null) ?DateTime.tryParse(c.date),
        ],
        windowStart: today,
        windowEnd: addCalendarDays(today, 120),
      );
      final next = prediction.predictedStarts
          .where((s) => !dateOnly(s).isBefore(today))
          .firstOrNull;
      if (next != null) cycleNext = dayKey(next);
    }
    return {
      'lastAt': last?.datetime.toUtc().millisecondsSinceEpoch,
      'month': DateFormat('yyyy-MM').format(now),
      'monthCount': month.length,
      'avgMinutes': avg,
      'cycleNext': cycleNext,
      'mask': mask,
      'labels': {
        'title': l10n.hwPrivateTitle,
        'add': l10n.hwPrivateAdd,
        'daysAgo': l10n.hwPrivateDaysAgo,
        'today': l10n.hwPrivateToday,
        'month': l10n.hwPrivateMonth('{n}'),
        'avg': l10n.hwPrivateAvg('{n}'),
        'cycleIn': l10n.hwPrivateCycleIn('{n}'),
        'cycleToday': l10n.hwPrivateCycleToday,
        'noData': l10n.hwNoRecords,
        'placeholder': 'MyDay',
        'stale': l10n.hwOpenToUpdate,
      },
    };
  }

  // ── Timer ─────────────────────────────────────────────────────────────

  /// Purpose: Build the `myday.timer` payload.
  /// Inputs: `data` (null without a file); `l10n`; `appliedActions`; `mask`.
  /// Returns: The payload map.
  /// Side effects: None.
  /// Notes: `session.count` is the actual repetition count; `last` is the
  /// latest of the records and the timer history.
  static Map<String, dynamic> timer(
    IntimacyData? data, {
    required AppLocalizations l10n,
    List<String> appliedActions = const [],
    bool mask = false,
  }) {
    final session = data?.timerSession;
    (DateTime, Duration)? last;
    for (final r in data?.records ?? const <IntimacyRecord>[]) {
      if (last == null || r.datetime.isAfter(last.$1)) {
        last = (r.datetime, r.duration);
      }
    }
    for (final h in data?.timerHistory ?? const <TimerHistoryEntry>[]) {
      if (last == null || h.start.isAfter(last.$1)) {
        last = (h.start, h.duration);
      }
    }
    return {
      'session': session == null
          ? null
          : {
              'running': session.running,
              'startedAt': session.running
                  ? session.startedAt?.toUtc().millisecondsSinceEpoch
                  : null,
              'accumulatedMs': session.accumulated.inMilliseconds,
              'count': sessionCount(session),
            },
      'last': last == null
          ? null
          : {
              'at': last.$1.toUtc().millisecondsSinceEpoch,
              'durationMs': last.$2.inMilliseconds,
            },
      'step': timerStep,
      'appliedActions': _tail(appliedActions),
      'mask': mask,
      'labels': {
        'title': l10n.hwTimerTitle,
        'running': l10n.hwTimerRunning,
        'paused': l10n.hwTimerPaused,
        'count': l10n.hwTimerCount('{n}'),
        'start': l10n.hwTimerStart,
        'resume': l10n.hwTimerResume,
        'pause': l10n.hwTimerPause,
        'finish': l10n.hwTimerFinish,
        'last': l10n.hwTimerLast('{n}', '{m}'),
        'lastToday': l10n.hwTimerLastToday('{m}'),
        'idle': l10n.hwTimerIdle,
        'placeholder': 'MyDay',
        'stale': l10n.hwOpenToUpdate,
      },
    };
  }

  /// Purpose: Return a timer session's actual repetition count.
  /// Inputs: `session`.
  /// Returns: `int`.
  /// Side effects: None.
  /// Notes: Prefers the timeline total; otherwise count × unit.
  static int sessionCount(IntimacyTimerSession session) {
    final timeline = session.thrustTimeline;
    if (timeline != null) return timeline.total;
    if (session.thrustCount <= 0) return 0;
    return session.thrustCountUnit == 1
        ? session.thrustCount
        : session.thrustCount * session.thrustCountUnit;
  }

  /// Purpose: Keep the newest applied action ids.
  /// Inputs: `ids`.
  /// Returns: At most [maxAppliedActions] ids.
  /// Side effects: None.
  /// Notes: Renderers only need the ids still waiting in the queue.
  static List<String> _tail(List<String> ids) => ids.length > maxAppliedActions
      ? ids.sublist(ids.length - maxAppliedActions)
      : List.of(ids);

  /// Purpose: Round to one decimal.
  /// Inputs: `v`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: None.
  static double _round1(double v) => (v * 10).round() / 10;
}

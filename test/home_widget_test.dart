import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_day/features/finance/models/finance.dart';
import 'package:my_day/features/finance/services/exchange_rate_storage.dart';
import 'package:my_day/features/finance/services/finance_storage.dart';
import 'package:my_day/features/intimacy/models/intimacy_record.dart';
import 'package:my_day/features/intimacy/utils/thrust_timeline.dart';
import 'package:my_day/features/todo/models/task.dart';
import 'package:my_day/features/todo/services/todo_storage.dart';
import 'package:my_day/features/weight/models/weight_record.dart';
import 'package:my_day/l10n/app_localizations.dart';
import 'package:my_day/shared/services/home_widget_actions.dart';
import 'package:my_day/shared/services/home_widget_payloads.dart';
import 'package:my_day/shared/services/home_widget_service.dart';
import 'package:myapps_widget/myapps_widget.dart';

/// Purpose: Build a queued widget action for tests.
/// Inputs: `id`, `action`, `at`, optional `args` and `kind`.
/// Returns: `WidgetAction`.
/// Side effects: None.
/// Notes: None.
WidgetAction act(
  String id,
  String action,
  DateTime at, {
  Map<String, dynamic> args = const {},
  String kind = HomeWidgetService.timerKind,
}) => WidgetAction(id: id, kind: kind, action: action, at: at, args: args);

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final now = DateTime(2026, 11, 2, 9);
  final today = DateTime(2026, 11, 2);
  setUpAll(() => initializeDateFormatting('en'));

  /// Purpose: Build Todo data with a daily task and three one-time tasks.
  /// Inputs: None.
  /// Returns: `TodoData`.
  /// Side effects: None.
  /// Notes: Fresh per test because the completion log mutates in place.
  TodoData todoData() => TodoData(
    dailyTemplates: [
      Task(
        id: 'd1',
        title: 'Water',
        type: TaskType.daily,
        startDate: DateTime(2026, 10, 1),
        subtasks: [SubTask(id: 's1', title: 'Glass')],
      ),
      Task(
        id: 'd2',
        title: 'Gone',
        type: TaskType.daily,
        startDate: DateTime(2026, 10, 1),
        deletedDate: DateTime(2026, 11, 2),
      ),
    ],
    oneTimeTasks: [
      Task(
        id: 'late',
        title: 'Bills',
        type: TaskType.routineOnce,
        scheduledDate: DateTime(2026, 10, 30),
      ),
      Task(
        id: 'gym',
        title: 'Gym',
        type: TaskType.workOnce,
        scheduledDate: today,
        reminderTime: DateTime(2026, 11, 2, 18),
      ),
      Task(
        id: 'dentist',
        title: 'Dentist',
        type: TaskType.routineOnce,
        scheduledDate: DateTime(2026, 11, 3),
        recurrence: const TaskRecurrence.everyNDays(30),
      ),
    ],
    dailyLog: DailyCompletionLog(),
  );

  group('Todo payload', () {
    test('lists today and tomorrow in display order', () {
      final p = HomeWidgetPayloads.todo(
        todoData(),
        now: now,
        l10n: l10n,
        localeTag: 'en',
      );
      final days = p['days'] as List;
      expect(days.map((d) => d['date']), ['2026-11-02', '2026-11-03']);
      final ids = (days[0]['items'] as List).map((i) => i['id']).toList();
      // Overdue first, then the timed task, then untimed; deleted daily gone.
      expect(ids, ['late', 'gym', 'd1']);
      final late = (days[0]['items'] as List).first as Map;
      expect(late['late'], isTrue);
      expect((days[0]['items'] as List)[1]['time'], '18:00');
      final tomorrow = (days[1]['items'] as List).cast<Map>();
      final dentist = tomorrow.firstWhere((i) => i['id'] == 'dentist');
      expect(dentist['sched'], isTrue);
      expect(dentist['rec'], isTrue);
      // Open one-time tasks carry forward into tomorrow.
      expect(tomorrow.map((i) => i['id']), contains('gym'));
    });

    test('completed tasks sort last and stay listed', () {
      final data = todoData();
      data.dailyLog.toggle(today, 'd1');
      final items = HomeWidgetPayloads.todoItems(
        data,
        day: today,
        today: today,
      );
      expect(items.last['id'], 'd1');
      expect(items.last['done'], isTrue);
    });
  });

  group('Todo actions', () {
    test('setDone completes a daily task and its subtasks idempotently', () {
      final data = todoData();
      final action = act(
        'a1',
        'setDone',
        now,
        kind: HomeWidgetService.todoKind,
        args: {'id': 'd1', 'date': '2026-11-02', 'done': true},
      );
      final r = HomeWidgetActions.applyTodo(data, [action, action]);
      expect(r.changed, isTrue);
      expect(r.applied, ['a1', 'a1']);
      expect(r.data.dailyLog.isCompleted(today, 'd1'), isTrue);
      expect(r.data.dailyLog.isSubtaskCompleted(today, 's1'), isTrue);
    });

    test('setDone completes a one-time task on the given date', () {
      final r = HomeWidgetActions.applyTodo(todoData(), [
        act(
          'a',
          'setDone',
          now,
          kind: HomeWidgetService.todoKind,
          args: {'id': 'gym', 'date': '2026-11-02', 'done': true},
        ),
      ]);
      final gym = r.data.oneTimeTasks.firstWhere((t) => t.id == 'gym');
      expect(gym.isCompleted, isTrue);
      expect(gym.completedDate, today);
    });

    test('recurring completions and unknown ids are consumed unchanged', () {
      final r = HomeWidgetActions.applyTodo(todoData(), [
        act(
          'a',
          'setDone',
          now,
          kind: HomeWidgetService.todoKind,
          args: {'id': 'dentist', 'date': '2026-11-03', 'done': true},
        ),
        act(
          'b',
          'setDone',
          now,
          kind: HomeWidgetService.todoKind,
          args: {'id': 'nope', 'date': '2026-11-02', 'done': true},
        ),
      ]);
      expect(r.changed, isFalse);
      expect(r.applied, ['a', 'b']);
    });
  });

  group('Timer actions', () {
    test('start, add and pause build a session at the tap instants', () {
      final t0 = DateTime(2026, 11, 2, 22);
      final r = HomeWidgetActions.applyTimer(null, [
        act('1', 'start', t0),
        act('2', 'add', t0.add(const Duration(minutes: 1)), args: {'n': 100}),
        act('3', 'pause', t0.add(const Duration(minutes: 5))),
        act('4', 'pause', t0.add(const Duration(minutes: 6))),
      ]);
      final s = r.data!;
      expect(s.running, isFalse);
      expect(s.accumulated, const Duration(minutes: 5));
      expect(s.thrustCount, 1);
      expect(s.thrustCountUnit, 100);
      expect(s.thrustTimeline!.events.single.elapsedMs, 60000);
    });

    test('resume continues from the accumulated time', () {
      final t0 = DateTime(2026, 11, 2, 22);
      final paused = IntimacyTimerSession(
        firstStartedAt: t0,
        accumulated: const Duration(minutes: 3),
        running: false,
        thrustCount: 7,
        thrustCountUnit: 1,
        thrustTimeline: ThrustTimeline.seed(1000, 7),
      );
      final r = HomeWidgetActions.applyTimer(paused, [
        act('1', 'start', t0.add(const Duration(minutes: 10))),
        act('2', 'add', t0.add(const Duration(minutes: 11)), args: {'n': 100}),
      ]);
      final s = r.data!;
      expect(s.running, isTrue);
      expect(s.startedAt, t0.add(const Duration(minutes: 10)));
      expect(HomeWidgetPayloads.sessionCount(s), 107);
      expect(s.thrustCountUnit, 1);
      expect(s.thrustTimeline!.events.last.elapsedMs, 4 * 60000);
    });

    test('add without a session is ignored', () {
      final r = HomeWidgetActions.applyTimer(null, [
        act('1', 'add', now, args: {'n': 100}),
      ]);
      expect(r.changed, isFalse);
      expect(r.data, isNull);
    });
  });

  test('weight payload computes change, BMI and points', () {
    final p = HomeWidgetPayloads.weight(
      WeightData(
        height: 170,
        reminderMode: 'once',
        morningHour: 7,
        morningMinute: 30,
        records: [
          WeightRecord(weight: 64, datetime: DateTime(2026, 9, 20)),
          WeightRecord(weight: 63.6, datetime: DateTime(2026, 10, 20)),
          WeightRecord(weight: 62.4, datetime: DateTime(2026, 11, 2, 7)),
        ],
      ),
      now: now,
      l10n: l10n,
    );
    expect((p['latest'] as Map)['kg'], 62.4);
    expect(p['change30'], -1.6);
    expect(p['previousKg'], 63.6);
    expect(p['bmi'], 21.6);
    expect(p['points'], [63.6, 62.4]);
    expect(p['remindAt'], '07:30');
  });

  test('finance payload totals the month in the default currency', () {
    final food = Category(
      id: 'food',
      name: 'Food',
      emoji: '🍜',
      icon: const IconRef(codePoint: 0xe532),
      type: TransactionType.expense,
    );
    final rates = ExchangeRateData(
      currentSnapshotId: 's',
      snapshots: {
        's': RateSnapshot(id: 's', rates: {'CNY': 1, 'USD': 0.5}),
      },
    );
    final p = HomeWidgetPayloads.finance(
      FinanceData(
        accounts: const [],
        categories: [food],
        transactions: [
          Transaction(
            type: TransactionType.expense,
            amount: 100,
            accountId: 'a',
            categoryId: 'food',
            date: DateTime(2026, 11, 1),
          ),
          Transaction(
            type: TransactionType.income,
            amount: 1000,
            accountId: 'a',
            date: DateTime(2026, 11, 2),
          ),
          Transaction(
            type: TransactionType.expense,
            amount: 999,
            accountId: 'a',
            date: DateTime(2026, 10, 31),
          ),
        ],
      ),
      rates: rates,
      now: now,
      l10n: l10n,
      localeTag: 'en',
    );
    expect(p['month'], '2026-11');
    expect(p['expense'], '¥100');
    expect(p['income'], '¥1,000');
    expect(p['net'], '¥900');
    expect((p['top'] as Map)['name'], 'Food');
    expect((p['top'] as Map)['share'], 100);
  });

  test('timer payload reports the session and the last entry', () {
    final t0 = DateTime(2026, 11, 2, 22);
    final p = HomeWidgetPayloads.timer(
      IntimacyData(
        partners: const [],
        toys: const [],
        positions: const [],
        records: const [],
        timerHistory: [
          TimerHistoryEntry(
            start: DateTime(2026, 10, 30),
            duration: const Duration(minutes: 24),
          ),
        ],
        timerSession: IntimacyTimerSession(
          firstStartedAt: t0,
          startedAt: t0,
          accumulated: Duration.zero,
          running: true,
          thrustCount: 34,
        ),
      ),
      l10n: l10n,
    );
    final session = p['session'] as Map;
    expect(session['running'], isTrue);
    expect(session['count'], 3400);
    expect((p['last'] as Map)['durationMs'], 24 * 60000);
    expect(p['step'], 100);
  });

  group('Deep links', () {
    tearDown(() => HomeWidgetLaunch.pending.value = null);

    test('route widget links to tabs and queue the request', () {
      expect(
        HomeWidgetLaunch.redirect(
          Uri.parse('myday://widget/myday.todo?do=toggle&id=t1'),
          intimacyVisible: true,
        ),
        '/todo',
      );
      final request = HomeWidgetLaunch.take({HomeWidgetService.todoKind})!;
      expect(request.action, 'toggle');
      expect(request.id, 't1');
      expect(HomeWidgetLaunch.pending.value, isNull);
      expect(
        HomeWidgetLaunch.redirect(
          Uri.parse('/myday.timer?do=timer'),
          intimacyVisible: true,
        ),
        '/intimacy',
      );
    });

    test('hidden Intimacy and other paths', () {
      expect(
        HomeWidgetLaunch.redirect(
          Uri.parse('/myday.intimacy?do=add'),
          intimacyVisible: false,
        ),
        '/todo',
      );
      expect(HomeWidgetLaunch.pending.value, isNull);
      expect(
        HomeWidgetLaunch.redirect(Uri.parse('/todo'), intimacyVisible: true),
        isNull,
      );
    });
  });

  test('privacy choices map to envelope levels and defaults', () {
    expect(
      HomeWidgetService.envelopePrivacy(
        HomeWidgetService.todoKind,
        HomeWidgetPrivacyChoice.show,
      ),
      WidgetPrivacy.normal,
    );
    expect(
      HomeWidgetService.envelopePrivacy(
        HomeWidgetService.weightKind,
        HomeWidgetPrivacyChoice.show,
      ),
      WidgetPrivacy.sensitive,
    );
    expect(
      HomeWidgetService.envelopePrivacy(
        HomeWidgetService.todoKind,
        HomeWidgetPrivacyChoice.iconOnly,
      ),
      WidgetPrivacy.hidden,
    );
    expect(
      HomeWidgetService.defaultSettings(HomeWidgetService.intimacyKind).privacy,
      HomeWidgetPrivacyChoice.maskValues,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/ai/services/insight_prompts.dart';
import 'package:my_day/features/finance/models/finance.dart';
import 'package:my_day/features/finance/services/exchange_rate_storage.dart';
import 'package:my_day/features/finance/services/finance_insight_facts.dart';
import 'package:my_day/features/intimacy/models/intimacy_record.dart';
import 'package:my_day/features/intimacy/services/intimacy_insight_facts.dart';
import 'package:my_day/features/todo/models/task.dart';
import 'package:my_day/features/todo/services/todo_insight_facts.dart';
import 'package:my_day/features/weight/models/weight_record.dart';
import 'package:my_day/features/weight/services/weight_insight_facts.dart';

/// Purpose: Build a rate table with one snapshot.
/// Inputs: None.
/// Returns: `ExchangeRateData` where 1 USD = 7 CNY.
/// Side effects: None.
/// Notes: Test helper.
ExchangeRateData _rates() {
  final snap = RateSnapshot(id: 's1', rates: const {'USD_CNY': 7.0});
  return ExchangeRateData(currentSnapshotId: 's1', snapshots: {'s1': snap});
}

/// Purpose: Test the pure fact builders behind the insight cards.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The privacy assertions are the load-bearing ones: nothing a user
/// typed as a note, and nothing identifying, may appear in a prompt.
void main() {
  group('todo buckets', () {
    test('boundaries are 12:00 and 18:00', () {
      expect(
        todoBucketFor(DateTime(2026, 9, 28, 11, 59)),
        InsightTimeBucket.morning,
      );
      expect(
        todoBucketFor(DateTime(2026, 9, 28, 12)),
        InsightTimeBucket.afternoon,
      );
      expect(
        todoBucketFor(DateTime(2026, 9, 28, 17, 59)),
        InsightTimeBucket.afternoon,
      );
      expect(
        todoBucketFor(DateTime(2026, 9, 28, 18)),
        InsightTimeBucket.evening,
      );
    });
  });

  group('todo facts', () {
    final created = DateTime(2026, 9, 1);
    late Task run;
    late Task retired;
    late Task future;
    late Task report;
    late Task tomorrow;
    late DailyCompletionLog log;
    late DailyScoreLog scores;

    setUp(() {
      run = Task(
        id: 'run',
        title: 'Morning run',
        note: 'SECRET-NOTE',
        type: TaskType.daily,
        createdDate: created,
        subtasks: [SubTask(title: 'SECRET-SUBTASK')],
      );
      retired = Task(
        id: 'retired',
        title: 'Old habit',
        type: TaskType.daily,
        createdDate: created,
        deletedDate: DateTime(2026, 9, 28),
      );
      future = Task(
        id: 'future',
        title: 'Future habit',
        type: TaskType.daily,
        createdDate: created,
        startDate: DateTime(2026, 10, 1),
      );
      report = Task(
        id: 'report',
        title: 'Write report',
        type: TaskType.workOnce,
        createdDate: created,
        scheduledDate: DateTime(2026, 9, 26),
        reminderTime: DateTime(2026, 9, 26, 15, 30),
      );
      tomorrow = Task(
        id: 'tomorrow',
        title: 'Dentist',
        type: TaskType.routineOnce,
        createdDate: created,
        scheduledDate: DateTime(2026, 9, 29),
      );
      log = DailyCompletionLog();
      scores = DailyScoreLog();
    });

    InsightFacts? build(DateTime now) => buildTodoInsightFacts(
      now: now,
      dailyTemplates: [run, retired, future],
      oneTimeTasks: [report, tomorrow],
      dailyLog: log,
      dailyScores: scores,
    );

    test('morning lists only what the Todo page shows today', () {
      scores.setScore(DateTime(2026, 9, 27), 3);
      final facts = build(DateTime(2026, 9, 28, 9))!;
      final text = facts.lines.join('\n');
      expect(facts.bucket, InsightTimeBucket.morning);
      expect(text, contains('Morning run'));
      expect(text, isNot(contains('Old habit')));
      expect(text, isNot(contains('Future habit')));
      expect(text, contains('Write report'));
      expect(text, contains('Write report (15:30)'));
      expect(text, isNot(contains('carried over')));
      expect(text, contains("Yesterday's self-rating: 3 on a -5 to 5 scale"));
      expect(facts.slots.map((s) => s.id), ['plan', 'first', 'tip']);
    });

    test('afternoon counts completions and reminders still ahead', () {
      log.toggle(DateTime(2026, 9, 28), 'run');
      final facts = build(DateTime(2026, 9, 28, 13))!;
      final text = facts.lines.join('\n');
      expect(text, contains('Done so far: 1 of 1 daily habits'));
      expect(text, contains('Write report at 15:30'));
      expect(facts.slots.first.id, 'progress');
    });

    test('evening reviews today and looks at tomorrow', () {
      final facts = build(DateTime(2026, 9, 28, 20))!;
      final text = facts.lines.join('\n');
      expect(text, contains('Left undone: Morning run; Write report'));
      expect(text, contains('scheduled for tomorrow: Dentist'));
      expect(facts.slots.map((s) => s.id), [
        'summary',
        'tomorrow',
        'encouragement',
      ]);
    });

    test('notes and subtasks never reach the prompt', () {
      for (final hour in [9, 13, 20]) {
        final prompt = insightPrompt(build(DateTime(2026, 9, 28, hour))!);
        expect(prompt, isNot(contains('SECRET')));
      }
    });

    test('titles are quoted terms and are capped', () {
      final many = [
        for (var i = 0; i < 20; i++)
          Task(
            title: 'Task $i',
            type: TaskType.daily,
            createdDate: created,
          ),
      ];
      final facts = buildTodoInsightFacts(
        now: DateTime(2026, 9, 28, 9),
        dailyTemplates: many,
        oneTimeTasks: const [],
        dailyLog: log,
        dailyScores: scores,
        maxTasks: 5,
      )!;
      expect(facts.lines.join('\n'), contains('+15 more'));
      expect(facts.quotedTerms, contains('Task 0'));
    });

    test('nothing to say returns null', () {
      expect(
        buildTodoInsightFacts(
          now: DateTime(2026, 9, 28, 9),
          dailyTemplates: const [],
          oneTimeTasks: const [],
          dailyLog: log,
          dailyScores: scores,
        ),
        isNull,
      );
    });

    test('canonical form is stable and follows the data', () {
      final a = build(DateTime(2026, 9, 28, 9))!.canonical();
      final b = build(DateTime(2026, 9, 28, 10))!.canonical();
      expect(a, b);
      log.toggle(DateTime(2026, 9, 28), 'run');
      final c = build(DateTime(2026, 9, 28, 13))!.canonical();
      expect(c, isNot(a));
    });

    test('the counts-only variant carries no titles and the same slots', () {
      final overdue = Task(
        id: 'overdue',
        title: 'Pay rent',
        type: TaskType.workOnce,
        createdDate: created,
        scheduledDate: DateTime(2026, 9, 26),
        dueDate: DateTime(2026, 9, 27),
      );
      for (final hour in [9, 13, 20]) {
        final now = DateTime(2026, 9, 28, hour);
        final titled = buildTodoInsightFacts(
          now: now,
          dailyTemplates: [run],
          oneTimeTasks: [report, overdue, tomorrow],
          dailyLog: log,
          dailyScores: scores,
        )!;
        final plain = buildTodoInsightFacts(
          now: now,
          dailyTemplates: [run],
          oneTimeTasks: [report, overdue, tomorrow],
          dailyLog: log,
          dailyScores: scores,
          includeTitles: false,
        )!;
        final text = plain.lines.join('\n');
        expect(text, isNot(contains('Morning run')));
        expect(text, isNot(contains('Pay rent')));
        expect(text, isNot(contains('Dentist')));
        expect(text, contains('1 overdue'));
        expect(plain.quotedTerms, isEmpty);
        expect(
          plain.slots.map((s) => s.id).toList(),
          titled.slots.map((s) => s.id).toList(),
        );
        // The evening review lists bare titles; the other buckets qualify.
        if (hour < 18) {
          expect(titled.lines.join('\n'), contains('Pay rent (overdue)'));
        }
      }
    });
  });

  group('finance facts', () {
    final now = DateTime(2026, 9, 28, 10);
    late Account card;
    late List<Transaction> txs;
    late Subscription sub;

    setUp(() {
      card = Account(
        id: 'a1',
        type: AccountType.credit,
        bankOrApp: 'SECRET-BANK',
        name: 'SECRET-ACCOUNT',
        currency: 'USD',
        cardNumber: '4111111111111111',
        expiryDate: '12/30',
        securityCode: '987',
      );
      txs = [
        Transaction(
          type: TransactionType.expense,
          amount: 10,
          currency: 'USD',
          rateSnapshotId: 's1',
          accountId: 'a1',
          categoryId: 'food',
          note: 'SECRET-NOTE',
          date: DateTime(2026, 9, 3),
        ),
        Transaction(
          type: TransactionType.income,
          amount: 1000,
          currency: 'CNY',
          accountId: 'a1',
          date: DateTime(2026, 8, 1),
        ),
      ];
      sub = Subscription(
        name: 'Streaming',
        startDate: DateTime(2026, 1, 1),
        billingCycleType: BillingCycleType.monthly,
        amount: 70,
        accountId: 'a1',
        note: 'SECRET-SUB-NOTE',
        nextBillingDate: DateTime(2026, 9, 30),
      );
    });

    InsightFacts build() => buildFinanceInsightFacts(
      now: now,
      accounts: [card],
      categories: [
        Category(
          id: 'food',
          name: 'Food',
          icon: const IconRef(codePoint: 1),
          type: TransactionType.expense,
        ),
      ],
      transactions: txs,
      subscriptions: [sub],
      rateData: _rates(),
      defaultCurrency: 'CNY',
    )!;

    test('card details, bank names and notes never reach the prompt', () {
      final prompt = insightPrompt(build());
      for (final secret in [
        '4111',
        '12/30',
        '987',
        'SECRET',
      ]) {
        expect(prompt, isNot(contains(secret)), reason: secret);
      }
    });

    test('four months of flow in the default currency', () {
      final text = build().lines.join('\n');
      expect(text, contains('2026-06 income'));
      expect(text, contains('2026-09 (so far) income 0 CNY, spending 70 CNY'));
      expect(text, contains('2026-08 income 1000 CNY'));
      expect(text, contains('Food 70 CNY'));
    });

    test('subscriptions are summarized with renewals', () {
      final facts = build();
      final text = facts.lines.join('\n');
      expect(text, contains('Active subscriptions: 1'));
      expect(text, contains('Streaming on 2026-09-30'));
      expect(facts.quotedTerms, containsAll(['Food', 'Streaming']));
      expect(facts.slots.map((s) => s.id), [
        'flowSummary',
        'flowAdvice',
        'subSummary',
        'subAdvice',
      ]);
    });

    test('no transactions and no subscriptions returns null', () {
      expect(
        buildFinanceInsightFacts(
          now: now,
          accounts: [card],
          categories: const [],
          transactions: const [],
          subscriptions: const [],
          rateData: _rates(),
          defaultCurrency: 'CNY',
        ),
        isNull,
      );
    });
  });

  group('weight facts', () {
    test('trend, BMI and carried-forward measurements, no notes', () {
      final now = DateTime(2026, 9, 28, 8);
      final facts = buildWeightInsightFacts(
        now: now,
        heightCm: 170,
        records: [
          WeightRecord(
            weight: 70,
            waistCm: 80,
            hipCm: 100,
            datetime: DateTime(2026, 9, 1),
            notes: 'SECRET-NOTE',
          ),
          WeightRecord(weight: 69, datetime: DateTime(2026, 9, 25)),
          WeightRecord(weight: 68.5, datetime: DateTime(2026, 9, 27)),
        ],
      )!;
      final text = facts.lines.join('\n');
      expect(text, contains('Latest weight: 68.5 kg on 2026-09-27'));
      expect(text, contains('BMI: 23.7'));
      expect(text, contains('-0.5 kg over 7 days'));
      expect(text, contains('-1.5 kg over 30 days'));
      expect(text, contains('waist 80 cm, hip 100 cm'));
      expect(text, contains('Waist-to-hip ratio: 0.8'));
      expect(insightPrompt(facts), isNot(contains('SECRET')));
    });

    test('no records returns null', () {
      expect(
        buildWeightInsightFacts(
          now: DateTime(2026, 9, 28),
          heightCm: 170,
          records: const [],
        ),
        isNull,
      );
    });
  });

  group('intimacy facts', () {
    final now = DateTime(2026, 9, 28, 22);
    final records = [
      IntimacyRecord(
        type: 'Regular',
        partnerId: 'SECRET-PARTNER',
        toyIds: const ['SECRET-TOY'],
        positionIds: const ['SECRET-POSITION'],
        location: 'SECRET-LOCATION',
        pleasureLevel: 4,
        duration: const Duration(minutes: 20),
        thrustCount: 123456,
        notes: 'SECRET-NOTE',
        hadOrgasm: true,
        usedCondom: true,
        watchedPorn: true,
        datetime: DateTime(2026, 9, 20),
      ),
      IntimacyRecord(
        type: 'Solo',
        isSolo: true,
        pleasureLevel: 3,
        duration: Duration.zero,
        datetime: DateTime(2026, 8, 20),
      ),
    ];
    const body = BodyProfile(
      underbustCm: 70,
      braStandard: 'eu',
      cycleEnabled: true,
      erectLengthCm: 99,
    );

    test('only statistics and body facts, nothing identifying', () {
      final facts = buildIntimacyInsightFacts(
        now: now,
        records: records,
        userBody: body,
        cycleRecords: [CycleRecord(date: '2026-09-10')],
        weightRecords: [
          WeightRecord(weight: 55, bustCm: 85, datetime: DateTime(2026, 9, 1)),
        ],
      )!;
      final prompt = insightPrompt(facts);
      for (final secret in ['SECRET', '123456', '99', 'porn']) {
        expect(prompt, isNot(contains(secret)), reason: secret);
      }
      final text = facts.lines.join('\n');
      expect(text, contains('Last 30 days: 1 entries (1 with a partner'));
      expect(text, contains('average length 20 min'));
      expect(text, contains('protection used in 100% of partnered'));
      expect(text, contains('bust 85 cm'));
      expect(text, contains('underbust 70 cm'));
      expect(text, contains('Cycle (estimate)'));
      expect(text, contains('last recorded start 2026-09-10'));
      expect(facts.slots.map((s) => s.id), ['trend', 'advice', 'body']);
    });

    test('partner cycles are not the user cycle', () {
      final facts = buildIntimacyInsightFacts(
        now: now,
        records: records,
        userBody: body,
        cycleRecords: [CycleRecord(personId: 'p1', date: '2026-09-10')],
        weightRecords: const [],
      )!;
      final text = facts.lines.join('\n');
      expect(text, isNot(contains('Cycle')));
      expect(facts.slots.map((s) => s.id), ['trend', 'advice', 'body']);
    });

    test('body slot is requested only with body facts', () {
      final facts = buildIntimacyInsightFacts(
        now: now,
        records: records,
        userBody: null,
        cycleRecords: const [],
        weightRecords: const [],
      )!;
      expect(facts.slots.map((s) => s.id), ['trend', 'advice']);
    });

    test('no records and no body facts returns null', () {
      expect(
        buildIntimacyInsightFacts(
          now: now,
          records: const [],
          userBody: null,
          cycleRecords: const [],
          weightRecords: const [],
        ),
        isNull,
      );
    });
  });
}

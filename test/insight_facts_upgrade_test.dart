import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/ai/services/insight_prompts.dart';
import 'package:my_day/features/finance/models/finance.dart';
import 'package:my_day/features/finance/services/exchange_rate_storage.dart';
import 'package:my_day/features/finance/services/finance_analysis_insight_facts.dart';
import 'package:my_day/features/finance/services/finance_insight_facts.dart';
import 'package:my_day/features/intimacy/services/intimacy_insight_facts.dart';
import 'package:my_day/features/todo/models/task.dart';
import 'package:my_day/features/todo/services/todo_insight_facts.dart';
import 'package:my_day/features/weight/models/weight_record.dart';
import 'package:my_day/features/weight/services/weight_insight_facts.dart';

/// Purpose: Build a one-snapshot rate table, everything already in CNY.
/// Inputs: None.
/// Returns: `ExchangeRateData`.
/// Side effects: None.
/// Notes: Test helper.
ExchangeRateData _rates() => ExchangeRateData(
  currentSnapshotId: 's1',
  snapshots: {'s1': RateSnapshot(id: 's1', rates: const {})},
);

/// Purpose: Build a CNY expense or income.
/// Inputs: `amount`, `date`, `category`, `type`.
/// Returns: `Transaction`.
/// Side effects: None.
/// Notes: Test helper.
Transaction _tx(
  double amount,
  DateTime date,
  String category, {
  TransactionType type = TransactionType.expense,
}) => Transaction(
  type: type,
  amount: amount,
  currency: 'CNY',
  rateSnapshotId: 's1',
  accountId: 'a1',
  categoryId: category,
  date: date,
);

/// Purpose: Test the facts added in 1.8.1 (prompt version 4).
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: The numbers the model is asked to interpret are worked out in
/// Dart, so each is checked exactly.
void main() {
  final categories = [
    for (final (id, name) in [('food', 'Dining'), ('bus', 'Transport')])
      Category(
        id: id,
        name: name,
        icon: const IconRef(codePoint: 1),
        type: TransactionType.expense,
      ),
  ];

  test('todo: 7-day habit rate and overdue share', () {
    final run = Task(
      id: 'run',
      title: 'Run',
      type: TaskType.daily,
      createdDate: DateTime(2026, 9, 1),
    );
    final late = Task(
      id: 'late',
      title: 'Taxes',
      type: TaskType.workOnce,
      createdDate: DateTime(2026, 9, 1),
      scheduledDate: DateTime(2026, 9, 20),
      dueDate: DateTime(2026, 9, 25),
    );
    final log = DailyCompletionLog();
    for (final day in [21, 22, 23, 24, 25]) {
      log.toggle(DateTime(2026, 9, day), 'run');
    }
    final facts = buildTodoInsightFacts(
      now: DateTime(2026, 9, 28, 9),
      dailyTemplates: [run],
      oneTimeTasks: [late],
      dailyLog: log,
      dailyScores: DailyScoreLog(),
    )!;
    expect(facts.lines, contains('- Last 7 days habit completion: 71%'));
    expect(
      facts.lines,
      contains('- Overdue share of open one-off tasks: 1 of 1 (100%)'),
    );
    // No rating yesterday, so the tip does not ask about one.
    expect(facts.slots.last.ask, isNot(contains('self-rating')));
    expect(
      recentHabitCompletion([run], DailyCompletionLog(), DateTime(2026, 9, 1)),
      isNull,
    );
  });

  test('finance: pace, top-category change and subscription share', () {
    final txs = [
      _tx(300, DateTime(2026, 8, 5), 'food'),
      _tx(310, DateTime(2026, 8, 20), 'bus'),
      _tx(600, DateTime(2026, 9, 3), 'food'),
      for (final m in [6, 7]) _tx(620, DateTime(2026, m, 10), 'bus'),
    ];
    final sub = Subscription(
      name: 'Streaming',
      startDate: DateTime(2026, 1, 1),
      billingCycleType: BillingCycleType.monthly,
      amount: 62,
      currency: 'CNY',
      accountId: 'a1',
      nextBillingDate: DateTime(2026, 9, 30),
    );
    final facts = buildFinanceInsightFacts(
      now: DateTime(2026, 9, 10, 10),
      accounts: const [],
      categories: categories,
      transactions: txs,
      subscriptions: [sub],
      rateData: _rates(),
      defaultCurrency: 'CNY',
    )!;
    final text = facts.lines.join('\n');
    // 600 / 10 days = 60 a day against 610 / 31 = 19.7.
    expect(
      text,
      contains(
        '- Daily spending pace vs last month: +205% (60 CNY vs 20 CNY per day)',
      ),
    );
    // Dining 600 now, 300 by 10 August.
    expect(
      text,
      contains('- Top category vs the same days last month: Dining +300 CNY'),
    );
    expect(text, contains('- Subscriptions share of monthly spending: 10%'));
    expect(facts.slots.map((s) => s.id), [
      'flowSummary',
      'flowAdvice',
      'subSummary',
      'subAdvice',
    ]);
  });

  test('weight: the trend pattern is classified in Dart', () {
    WeightRecord w(double kg, int month, int day) =>
        WeightRecord(weight: kg, datetime: DateTime(2026, month, day, 8));
    final now = DateTime(2026, 9, 28, 20);
    String? pattern(List<WeightRecord> rs) => weightTrendPattern(rs, now);
    // -2 kg over the month, then -1.2 kg in the last week: accelerating.
    expect(
      pattern([w(70, 8, 30), w(69.2, 9, 21), w(68, 9, 28)]),
      startsWith('accelerating loss'),
    );
    // A month of loss, then flat: plateau.
    expect(
      pattern([w(72, 8, 30), w(70, 9, 21), w(70.1, 9, 28)]),
      startsWith('plateau after a 30-day loss'),
    );
    // Losing for a month, gaining this week: reversal.
    expect(
      pattern([w(72, 8, 30), w(70, 9, 21), w(70.8, 9, 28)]),
      startsWith('reversal against the 30-day loss'),
    );
    expect(pattern([w(70, 9, 28)]), isNull);
  });

  test('analysis: shares, peaks and change against the previous period', () {
    final txs = [
      _tx(100, DateTime(2026, 8, 3), 'food'),
      _tx(100, DateTime(2026, 8, 20), 'bus'),
      _tx(400, DateTime(2026, 9, 5), 'food'),
      _tx(100, DateTime(2026, 9, 18), 'bus'),
      _tx(1000, DateTime(2026, 9, 25), 'pay', type: TransactionType.income),
    ];
    final facts = buildFinanceAnalysisInsightFacts(
      now: DateTime(2026, 10, 19),
      start: DateTime(2026, 9),
      end: DateTime(2026, 10),
      kind: 'month',
      transactions: txs,
      categories: categories,
      rateData: _rates(),
      defaultCurrency: 'CNY',
    )!;
    final text = facts.lines.join('\n');
    expect(
      text,
      contains('- Period: 2026-09-01 to 2026-09-30 (month, 30 days)'),
    );
    expect(text, contains('- Change vs the previous 30 days: spending +150%'));
    expect(text, contains('Dining 400 CNY (80%); Transport 100 CNY (20%)'));
    expect(
      text,
      contains('- Peak spending day: 2026-09-05 400 CNY (80% of the period)'),
    );
    expect(
      text,
      contains('- Peak spending week: the 7 days from 2026-09-01 400 CNY'),
    );
    expect(
      text,
      contains(
        '- Largest category shift vs the previous period: Dining +300 CNY',
      ),
    );
    expect(facts.module, InsightModule.financeAnalysis);
    expect(facts.quotedTerms, containsAll(['CNY', 'Dining']));
    // A period in progress counts only the days so far.
    final now = buildFinanceAnalysisInsightFacts(
      now: DateTime(2026, 9, 10, 12),
      start: DateTime(2026, 9),
      end: DateTime(2026, 10),
      kind: 'month',
      transactions: txs,
      categories: categories,
      rateData: _rates(),
      defaultCurrency: 'CNY',
    )!;
    expect(
      now.lines,
      contains('- Period: 2026-09-01 to 2026-09-10 (month, 10 days, so far)'),
    );
    expect(
      buildFinanceAnalysisInsightFacts(
        now: DateTime(2026, 10, 19),
        start: DateTime(2025),
        end: DateTime(2026),
        kind: 'year',
        transactions: txs,
        categories: categories,
        rateData: _rates(),
        defaultCurrency: 'CNY',
      ),
      isNull,
    );
  });

  test('intimacy: a label left in an answer is explained', () {
    const names = {'partner A': 'Alex', 'toy 1': 'Wand'};
    expect(intimacyLabelLegend(['和伴侣A一起评分最高。'], names), 'Partner A = Alex');
    expect(
      intimacyLabelLegend(['パートナーAとトイ1'], names),
      'Partner A = Alex · Toy 1 = Wand',
    );
    expect(intimacyLabelLegend(['和 Alex 一起。'], names), isNull);
    expect(intimacyLabelLegend(['toy 10'], names), isNull);
  });
}

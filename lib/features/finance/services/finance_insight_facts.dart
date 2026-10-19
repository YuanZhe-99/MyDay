import '../../ai/services/insight_prompts.dart';
import '../models/finance.dart';
import 'balance_util.dart';
import 'exchange_rate_storage.dart';
import 'subscription_summary.dart';

/// How many past months, besides the current one, the trend covers.
const int financeInsightPastMonths = 3;

/// Purpose: Format a money amount for a fact line.
/// Inputs: `amount`, `currency`.
/// Returns: `String` such as `1234 CNY`, rounded to whole units.
/// Side effects: None.
/// Notes: Whole units keep the fingerprint stable against tiny rate changes.
String _money(double amount, String currency) => '${amount.round()} $currency';

/// Purpose: Format a ratio change as a signed whole percent.
/// Inputs: `change` — e.g. `0.18` for an 18 % rise.
/// Returns: `String` such as `+18%` or `-5%`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
String _signedPercent(double change) {
  final p = (change * 100).round();
  return '${p >= 0 ? '+' : ''}$p%';
}

/// Purpose: Find the expense category with the largest total in a period.
/// Inputs: `transactions`; `names` — category id to name; `conv` — converts
/// a transaction to the default currency; `start` inclusive, `end` exclusive.
/// Returns: `(String, double)?` — the category name (`uncategorised` for an
/// unknown id) and its total, or null when nothing was spent.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
(String, double)? _topExpenseCategory(
  List<Transaction> transactions,
  Map<String, String> names,
  double Function(Transaction) conv,
  DateTime start,
  DateTime end,
) {
  final totals = <String, double>{};
  for (final t in transactions) {
    if (t.type != TransactionType.expense) continue;
    if (t.date.isBefore(start) || !t.date.isBefore(end)) continue;
    final name = names[t.categoryId] ?? 'uncategorised';
    totals[name] = (totals[name] ?? 0) + conv(t);
  }
  if (totals.isEmpty) return null;
  final top = totals.entries.reduce((a, b) => b.value > a.value ? b : a);
  return (top.key, top.value);
}

/// Purpose: Build the Finance card's facts.
/// Inputs: `now` — local time; the page's `accounts`, `categories`,
/// `transactions`, `subscriptions`, `rateData`, `defaultCurrency`.
/// Returns: `InsightFacts?` — null when there are no transactions and no
/// active subscriptions.
/// Side effects: None.
/// Notes: Only aggregates in the default currency, category names and
/// subscription names are sent. The builder reads nothing from an account
/// except its id, currency and balance, and never reads a note: card
/// numbers, expiry dates, security codes, bank names and notes cannot reach
/// the model. Conversions follow the Finance page: each transaction at the
/// rate snapshot it was recorded under, balances at current rates. Since
/// 1.8.1 the builder also works out the daily spending pace against last
/// month, the top category's change against the same days of last month and
/// the subscriptions' share of average monthly spending, so the model only
/// has to interpret them.
InsightFacts? buildFinanceInsightFacts({
  required DateTime now,
  required List<Account> accounts,
  required List<Category> categories,
  required List<Transaction> transactions,
  required List<Subscription> subscriptions,
  required ExchangeRateData rateData,
  required String defaultCurrency,
  int maxNames = 5,
}) {
  final activeSubs = subscriptions.where((s) => s.isActive).toList();
  if (transactions.isEmpty && activeSubs.isEmpty) return null;
  final cur = defaultCurrency;
  double conv(Transaction t) => convertCurrency(
    rateData.ratesAt(t.rateSnapshotId),
    t.amount,
    t.currency,
    cur,
  );

  final lines = <String>[
    '- Today: ${factDate(now)}, day ${now.day} of '
        '${DateTime(now.year, now.month + 1, 0).day} in this month',
    '- Currency: $cur',
  ];

  // Month-by-month income and spending, oldest first.
  final monthRows = <String>[];
  // Spending per month, index 0 = this month (so far), 1 = last month, …
  final spendingBack = List<double>.filled(financeInsightPastMonths + 1, 0);
  for (var back = financeInsightPastMonths; back >= 0; back--) {
    final start = DateTime(now.year, now.month - back);
    final end = DateTime(now.year, now.month - back + 1);
    var income = 0.0;
    var expense = 0.0;
    var count = 0;
    for (final t in transactions) {
      if (t.date.isBefore(start) || !t.date.isBefore(end)) continue;
      if (t.type == TransactionType.income) {
        income += conv(t);
        count++;
      } else if (t.type == TransactionType.expense) {
        expense += conv(t);
        count++;
      }
    }
    spendingBack[back] = expense;
    final label =
        '${start.year}-${start.month.toString().padLeft(2, '0')}'
        '${back == 0 ? ' (so far)' : ''}';
    monthRows.add(
      '$label income ${_money(income, cur)}, spending ${_money(expense, cur)}, '
      '$count entries',
    );
  }
  lines.add('- Monthly income and spending: ${monthRows.join('; ')}');

  // Top spending categories this month and last month.
  final names = {for (final c in categories) c.id: c.name};
  final quoted = <String>{};
  String topCategories(DateTime start, DateTime end) {
    final totals = <String, double>{};
    for (final t in transactions) {
      if (t.type != TransactionType.expense) continue;
      if (t.date.isBefore(start) || !t.date.isBefore(end)) continue;
      final name = names[t.categoryId] ?? 'uncategorised';
      totals[name] = (totals[name] ?? 0) + conv(t);
    }
    final top = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (top.isEmpty) return 'none';
    return [
      for (final e in top.take(3))
        () {
          final name = clipTitle(e.key, 30);
          quoted.add(name);
          return '$name ${_money(e.value, cur)}';
        }(),
    ].join('; ');
  }

  final thisMonth = DateTime(now.year, now.month);
  final nextMonth = DateTime(now.year, now.month + 1);
  final lastMonth = DateTime(now.year, now.month - 1);
  lines
    ..add(
      '- Top spending categories this month: '
      '${topCategories(thisMonth, nextMonth)}',
    )
    ..add(
      '- Top spending categories last month: '
      '${topCategories(lastMonth, thisMonth)}',
    );

  // Pace, worked out here because a small model cannot divide reliably:
  // this month's spending per day so far against last month's per day.
  final daysLastMonth = DateTime(now.year, now.month, 0).day;
  if (spendingBack[1] > 0) {
    final pace = spendingBack[0] / now.day;
    final before = spendingBack[1] / daysLastMonth;
    lines.add(
      '- Daily spending pace vs last month: '
      '${_signedPercent(pace / before - 1)} '
      '(${_money(pace, cur)} vs ${_money(before, cur)} per day)',
    );
  }

  // This month's top category against the same days of last month, so a
  // month in progress is not compared with a whole one.
  double categoryTotal(String name, DateTime start, DateTime end) {
    var sum = 0.0;
    for (final t in transactions) {
      if (t.type != TransactionType.expense) continue;
      if (t.date.isBefore(start) || !t.date.isBefore(end)) continue;
      if ((names[t.categoryId] ?? 'uncategorised') == name) sum += conv(t);
    }
    return sum;
  }

  final topNow = _topExpenseCategory(
    transactions,
    names,
    conv,
    thisMonth,
    nextMonth,
  );
  if (topNow != null) {
    final sameDays = DateTime(
      lastMonth.year,
      lastMonth.month,
      (now.day < daysLastMonth ? now.day : daysLastMonth) + 1,
    );
    final delta = topNow.$2 - categoryTotal(topNow.$1, lastMonth, sameDays);
    final name = clipTitle(topNow.$1, 30);
    quoted.add(name);
    lines.add(
      '- Top category vs the same days last month: $name '
      '${delta >= 0 ? '+' : '-'}${_money(delta.abs(), cur)}',
    );
  }

  // Net worth across accounts, in the default currency.
  if (accounts.isNotEmpty) {
    final current = rateData.currentRates;
    var total = 0.0;
    for (final a in accounts) {
      total += convertCurrency(
        current,
        accountBalance(a, transactions, rateData),
        a.currency,
        cur,
      );
    }
    lines.add(
      '- Total across ${accounts.length} accounts: ${_money(total, cur)}',
    );
  }

  // Subscriptions.
  final summary = summarizeSubscriptions(
    subscriptions: subscriptions,
    transactions: transactions,
    rateData: rateData,
    defaultCurrency: cur,
    now: now,
  );
  lines.add('- Active subscriptions: ${activeSubs.length}');
  if (activeSubs.isNotEmpty) {
    final costly = [...activeSubs]
      ..sort((a, b) {
        double monthly(Subscription s) =>
            convertCurrency(rateData.currentRates, s.amount, s.currency, cur) /
            (s.billingCycleType == BillingCycleType.monthly
                ? s.billingInterval
                : s.billingInterval * 12);
        return monthly(b).compareTo(monthly(a));
      });
    final costlyNames = [
      for (final s in costly.take(maxNames)) clipTitle(s.name, 30),
    ];
    quoted.addAll(costlyNames);
    lines
      ..add(
        '- Subscription cost: ${_money(summary.monthlyDue, cur)} per month '
        'projected, ${_money(summary.monthlyAvg, cur)} per month observed, '
        '${_money(summary.yearlyAvg, cur)} per year',
      )
      ..add('- Costliest subscriptions: ${costlyNames.join('; ')}');
    final fullMonths = spendingBack.skip(1).toList();
    final avgSpending =
        fullMonths.fold(0.0, (a, b) => a + b) / fullMonths.length;
    if (avgSpending > 0) {
      lines.add(
        '- Subscriptions share of monthly spending: '
        '${(summary.monthlyDue / avgSpending * 100).round()}% '
        '(projected subscriptions against the average of the last '
        '${fullMonths.length} complete months)',
      );
    }
    final upcoming = upcomingSubscriptions(subscriptions, days: 7, now: now);
    final upcomingText = [
      for (final (s, date) in upcoming.take(maxNames))
        '${clipTitle(s.name, 30)} on ${factDate(date)}',
    ];
    quoted.addAll([for (final (s, _) in upcoming) clipTitle(s.name, 30)]);
    lines.add(
      '- Renewals in the next 7 days: '
      '${upcomingText.isEmpty ? 'none' : upcomingText.join('; ')}',
    );
  }

  return InsightFacts(
    module: InsightModule.finance,
    bucket: InsightTimeBucket.none,
    lines: lines,
    slots: const [
      InsightSlot(
        'flowSummary',
        "Compare this month's daily spending pace and net savings trend "
            "against the past months without reading out every month's "
            'numbers.',
      ),
      InsightSlot(
        'flowAdvice',
        "Name the top spending category driving this month's outflow and "
            'suggest one specific way to cap it.',
      ),
      InsightSlot(
        'subSummary',
        'Evaluate the subscription burden as a share of monthly spending and '
            'highlight any upcoming 7-day renewals.',
      ),
      InsightSlot(
        'subAdvice',
        'Name the costliest active subscription and suggest a concrete review '
            'action (e.g. pause, downgrade, or check usage before renewal).',
      ),
    ],
    quotedTerms: quoted.toList(),
  );
}

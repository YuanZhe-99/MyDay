import '../../ai/services/insight_prompts.dart';
import '../models/finance.dart';
import 'balance_util.dart';
import 'exchange_rate_storage.dart';

/// How many categories one share line lists at most.
const int financeAnalysisMaxCategories = 3;

/// The slots the analysis card asks for.
const List<InsightSlot> financeAnalysisInsightSlots = [
  InsightSlot(
    'periodPattern',
    'Explain the concentration of spending or income in this selected period '
        '(e.g. whether one category or peak week dominated).',
  ),
  InsightSlot(
    'periodAdvice',
    'Suggest one concrete budget adjustment based on the largest category '
        'shift in this period.',
  ),
];

/// Purpose: Format a money amount for a fact line.
/// Inputs: `amount`, `currency`.
/// Returns: `String` such as `1234 CNY`, rounded to whole units.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
String _money(double amount, String currency) => '${amount.round()} $currency';

/// Purpose: Format a change as a signed whole percent.
/// Inputs: `now`, `before`.
/// Returns: `String?` — e.g. `+12%`, or null when `before` is zero.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
String? _change(double now, double before) {
  if (before <= 0) return null;
  final p = ((now / before - 1) * 100).round();
  return '${p >= 0 ? '+' : ''}$p%';
}

/// Purpose: Build the Finance analysis card's facts for the period the
/// Analysis page shows.
/// Inputs: `now` — local time; `start` — the period's first day; `end` —
/// the day after its last; `kind` — `year`, `month`, `day` or `custom`;
/// `transactions`; `categories`; `rateData`; `defaultCurrency`.
/// Returns: `InsightFacts?` — null when nothing was spent or earned in the
/// period.
/// Side effects: None.
/// Notes: Added in 1.8.1. Everything the model is asked to interpret is
/// worked out here: the top three spending and income categories with their
/// shares, the peak spending day (periods of two days or more) and week
/// (fourteen days or more), the change of both totals against the previous
/// period of the same length, and the category whose spending moved most
/// against it. A period still in progress is compared over the days elapsed
/// so far, against the same number of days before it. Only amounts in the
/// default currency, converted at each transaction's rate snapshot, and
/// category names are sent.
InsightFacts? buildFinanceAnalysisInsightFacts({
  required DateTime now,
  required DateTime start,
  required DateTime end,
  required String kind,
  required List<Transaction> transactions,
  required List<Category> categories,
  required ExchangeRateData rateData,
  required String defaultCurrency,
}) {
  final cur = defaultCurrency;
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  // A period in progress counts only the days that have happened.
  final inProgress = end.isAfter(tomorrow) && start.isBefore(tomorrow);
  final until = inProgress ? tomorrow : end;
  final days = until.difference(start).inHours ~/ 24;
  if (days <= 0) return null;
  final prevStart = DateTime(start.year, start.month, start.day - days);

  double conv(Transaction t) => convertCurrency(
    rateData.ratesAt(t.rateSnapshotId),
    t.amount,
    t.currency,
    cur,
  );
  final names = {for (final c in categories) c.id: c.name};
  String nameOf(Transaction t) => names[t.categoryId] ?? 'uncategorised';
  List<Transaction> within(
    DateTime from,
    DateTime to,
    TransactionType type,
  ) => [
    for (final t in transactions)
      if (t.type == type && !t.date.isBefore(from) && t.date.isBefore(to)) t,
  ];
  Map<String, double> byCategory(List<Transaction> ts) {
    final out = <String, double>{};
    for (final t in ts) {
      out[nameOf(t)] = (out[nameOf(t)] ?? 0) + conv(t);
    }
    return out;
  }

  final spent = within(start, until, TransactionType.expense);
  final earned = within(start, until, TransactionType.income);
  if (spent.isEmpty && earned.isEmpty) return null;
  final spentBefore = within(prevStart, start, TransactionType.expense);
  final earnedBefore = within(prevStart, start, TransactionType.income);
  double total(List<Transaction> ts) => ts.fold(0.0, (s, t) => s + conv(t));
  final spentTotal = total(spent);
  final earnedTotal = total(earned);

  final quoted = <String>{cur};
  String shares(Map<String, double> totals, double sum) {
    final top = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in top.take(financeAnalysisMaxCategories))
        () {
          final name = clipTitle(e.key, 30);
          quoted.add(name);
          return '$name ${_money(e.value, cur)} '
              '(${(e.value / sum * 100).round()}%)';
        }(),
    ].join('; ');
  }

  final last = DateTime(until.year, until.month, until.day - 1);
  final lines = <String>[
    '- Today: ${factDate(today)}',
    '- Period: ${factDate(start)} to ${factDate(last)} ($kind, $days '
        'day${days == 1 ? '' : 's'}${inProgress ? ', so far' : ''})',
    '- Currency: $cur',
    '- Spending: ${_money(spentTotal, cur)} in ${spent.length} entries; '
        'income: ${_money(earnedTotal, cur)} in ${earned.length} entries',
  ];
  final spendChange = _change(spentTotal, total(spentBefore));
  final incomeChange = _change(earnedTotal, total(earnedBefore));
  if (spendChange != null || incomeChange != null) {
    lines.add(
      '- Change vs the previous $days '
      'day${days == 1 ? '' : 's'}: ${[if (spendChange != null) 'spending $spendChange', if (incomeChange != null) 'income $incomeChange'].join(', ')}',
    );
  }
  if (spentTotal > 0) {
    lines.add(
      '- Top spending categories: '
      '${shares(byCategory(spent), spentTotal)}',
    );
  }
  if (earnedTotal > 0) {
    lines.add(
      '- Top income categories: ${shares(byCategory(earned), earnedTotal)}',
    );
  }

  // Peaks, only where a period has more than one of them.
  if (spentTotal > 0 && days >= 2) {
    final perDay = <DateTime, double>{};
    for (final t in spent) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      perDay[d] = (perDay[d] ?? 0) + conv(t);
    }
    final peak = perDay.entries.reduce((a, b) => b.value > a.value ? b : a);
    lines.add(
      '- Peak spending day: ${factDate(peak.key)} ${_money(peak.value, cur)} '
      '(${(peak.value / spentTotal * 100).round()}% of the period)',
    );
    if (days >= 14) {
      final perWeek = <int, double>{};
      for (final e in perDay.entries) {
        final week = e.key.difference(start).inHours ~/ (24 * 7);
        perWeek[week] = (perWeek[week] ?? 0) + e.value;
      }
      final top = perWeek.entries.reduce((a, b) => b.value > a.value ? b : a);
      final from = DateTime(start.year, start.month, start.day + top.key * 7);
      lines.add(
        '- Peak spending week: the 7 days from ${factDate(from)} '
        '${_money(top.value, cur)} '
        '(${(top.value / spentTotal * 100).round()}% of the period)',
      );
    }
  }

  // The category whose spending moved most against the previous period.
  final nowBy = byCategory(spent);
  final beforeBy = byCategory(spentBefore);
  final shifts = {
    for (final name in {...nowBy.keys, ...beforeBy.keys})
      name: (nowBy[name] ?? 0) - (beforeBy[name] ?? 0),
  };
  if (shifts.isNotEmpty && spentBefore.isNotEmpty) {
    final biggest = shifts.entries.reduce(
      (a, b) => b.value.abs() > a.value.abs() ? b : a,
    );
    if (biggest.value.abs() >= 1) {
      final name = clipTitle(biggest.key, 30);
      quoted.add(name);
      lines.add(
        '- Largest category shift vs the previous period: $name '
        '${biggest.value >= 0 ? '+' : '-'}${_money(biggest.value.abs(), cur)}',
      );
    }
  }

  return InsightFacts(
    module: InsightModule.financeAnalysis,
    bucket: InsightTimeBucket.none,
    lines: lines,
    slots: financeAnalysisInsightSlots,
    quotedTerms: quoted.toList(),
  );
}

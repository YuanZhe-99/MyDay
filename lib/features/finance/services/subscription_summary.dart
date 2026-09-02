import '../models/finance.dart';
import 'balance_util.dart';
import 'exchange_rate_storage.dart';

/// The three headline figures the subscriptions page and the finance home's
/// subscription overview both show, in the default currency.
typedef SubscriptionSummary = ({
  double monthlyDue,
  double monthlyAvg,
  double yearlyAvg,
});

/// Sort mode identifier: soonest next billing date first, undated last.
const subscriptionSortNextRenewal = 'nextRenewal';

/// Sort mode identifier: case-insensitive by name.
const subscriptionSortName = 'name';

/// Sort mode identifier: the user's own drag order.
const subscriptionSortCustom = 'custom';

/// Purpose: Compute the monthly due, monthly average and yearly average of the
/// active subscriptions in the default currency.
/// Inputs: `subscriptions` (inactive ones are ignored), `transactions` (only
/// those tagged with a `subscriptionId` count), `rateData`, `defaultCurrency`,
/// and `now`, injectable for tests.
/// Returns: `SubscriptionSummary`.
/// Side effects: None.
/// Notes: Monthly due is the projected cost — each amount divided by its
/// interval in months, converted at the current rates. Monthly average is the
/// observed cost — subscription-tagged transaction totals, each converted at
/// the rate snapshot it was recorded under, divided by the months elapsed since
/// the earliest one — and falls back to the projection below two full months
/// of history. Yearly average is twelve times the projection. One
/// implementation, so the home page and the subscriptions page can never show
/// different figures for the same data.
SubscriptionSummary summarizeSubscriptions({
  required List<Subscription> subscriptions,
  required List<Transaction> transactions,
  required ExchangeRateData rateData,
  required String defaultCurrency,
  DateTime? now,
}) {
  final currentRates = rateData.currentRates;
  var monthlyDue = 0.0;
  for (final sub in subscriptions) {
    if (!sub.isActive) continue;
    final months = sub.billingCycleType == BillingCycleType.monthly
        ? sub.billingInterval
        : sub.billingInterval * 12;
    monthlyDue += convertCurrency(
      currentRates,
      sub.amount / months,
      sub.currency,
      defaultCurrency,
    );
  }

  var monthlyAvg = monthlyDue;
  final subTxs = transactions.where((t) => t.subscriptionId != null).toList();
  if (subTxs.isNotEmpty) {
    final earliest = subTxs
        .map((t) => t.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final today = now ?? DateTime.now();
    final months =
        (today.year - earliest.year) * 12 + today.month - earliest.month;
    if (months >= 2) {
      final total = subTxs.fold(
        0.0,
        (sum, t) =>
            sum +
            convertCurrency(
              rateData.ratesAt(t.rateSnapshotId),
              t.amount,
              t.currency,
              defaultCurrency,
            ),
      );
      monthlyAvg = total / months;
    }
  }

  return (
    monthlyDue: monthlyDue,
    monthlyAvg: monthlyAvg,
    yearlyAvg: monthlyDue * 12,
  );
}

/// Purpose: Return a copy of `list` sorted by a subscription sort mode.
/// Inputs: `list`; `mode` — one of [subscriptionSortNextRenewal],
/// [subscriptionSortName], [subscriptionSortCustom]; `customOrder` — the ids in
/// the user's drag order, read only in custom mode.
/// Returns: `List<Subscription>` — a new list; the input is not mutated.
/// Side effects: None.
/// Notes: Unknown modes sort by next renewal, with undated subscriptions last.
/// In custom mode, ids missing from `customOrder` go to the end, and an empty
/// `customOrder` leaves the input order untouched — the subscriptions page
/// relies on that when custom mode is first selected.
List<Subscription> sortSubscriptions(
  List<Subscription> list, {
  required String mode,
  required List<String> customOrder,
}) {
  final sorted = List<Subscription>.of(list);
  switch (mode) {
    case subscriptionSortName:
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    case subscriptionSortCustom:
      if (customOrder.isNotEmpty) {
        sorted.sort((a, b) {
          final ai = customOrder.indexOf(a.id);
          final bi = customOrder.indexOf(b.id);
          final aIdx = ai == -1 ? customOrder.length : ai;
          final bIdx = bi == -1 ? customOrder.length : bi;
          return aIdx.compareTo(bIdx);
        });
      }
    default:
      sorted.sort((a, b) {
        final aNext = a.nextBillingDate;
        final bNext = b.nextBillingDate;
        if (aNext == null && bNext == null) return 0;
        if (aNext == null) return 1;
        if (bNext == null) return -1;
        return aNext.compareTo(bNext);
      });
  }
  return sorted;
}

/// Purpose: Return the subscriptions whose next billing date falls within
/// `days` days of today, soonest first.
/// Inputs: `subscriptions`, `days`, and `now`, injectable for tests.
/// Returns: `List<(Subscription, DateTime)>` — each with its next billing date.
/// Side effects: None.
/// Notes: At-expiry cancellations are excluded — they keep showing in
/// subscription lists but must not raise a renewal reminder — and so are
/// immediately cancelled subscriptions. The comparison is by calendar day, so
/// a subscription billing later today is included.
List<(Subscription, DateTime)> upcomingSubscriptions(
  List<Subscription> subscriptions, {
  required int days,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final limit = today.add(Duration(days: days));
  final result = <(Subscription, DateTime)>[];
  for (final sub in subscriptions) {
    if (sub.cancelType == CancelType.atExpiry) continue;
    if (!sub.isActive && sub.cancelType == CancelType.immediate) continue;
    final next = sub.nextBillingDate;
    if (next == null) continue;
    final nextDay = DateTime(next.year, next.month, next.day);
    if (!nextDay.isAfter(limit)) result.add((sub, next));
  }
  result.sort((a, b) => a.$2.compareTo(b.$2));
  return result;
}

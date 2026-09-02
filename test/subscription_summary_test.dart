import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/finance/models/finance.dart';
import 'package:my_day/features/finance/services/exchange_rate_storage.dart';
import 'package:my_day/features/finance/services/subscription_summary.dart';

/// Purpose: Verify the subscription statistics, sorting and upcoming-renewal
/// helpers shared by the subscriptions page and the finance home overview.
/// Inputs: None.
/// Returns: None.
/// Side effects: Runs test assertions.
/// Notes: These used to be private methods of the subscriptions page and had
/// no tests; now that a second surface reads them, their contract is pinned.
void main() {
  final rates = ExchangeRateData(
    currentSnapshotId: 'now',
    snapshots: {
      'now': RateSnapshot(id: 'now', rates: {'USD_CNY': 7.0}),
      'old': RateSnapshot(id: 'old', rates: {'USD_CNY': 6.0}),
    },
  );

  Subscription sub({
    String id = 's',
    String name = 'Sub',
    double amount = 12,
    String currency = 'CNY',
    BillingCycleType cycle = BillingCycleType.monthly,
    int interval = 1,
    bool isActive = true,
    CancelType? cancelType,
    DateTime? next,
  }) => Subscription(
    id: id,
    name: name,
    startDate: DateTime(2026, 1, 1),
    billingCycleType: cycle,
    billingInterval: interval,
    amount: amount,
    currency: currency,
    accountId: 'acc',
    isActive: isActive,
    cancelType: cancelType,
    cancelledAt: cancelType != null ? DateTime(2026, 6, 1) : null,
    nextBillingDate: next,
  );

  Transaction tx(DateTime date, double amount, {String? snapshot}) =>
      Transaction(
        type: TransactionType.expense,
        amount: amount,
        currency: 'USD',
        rateSnapshotId: snapshot,
        accountId: 'acc',
        subscriptionId: 's',
        date: date,
      );

  group('summarizeSubscriptions', () {
    test('monthly due divides each amount by its interval in months', () {
      final summary = summarizeSubscriptions(
        subscriptions: [
          sub(id: 'a', amount: 12), // 12 / month
          sub(id: 'b', amount: 30, interval: 3), // 10 / month
          sub(id: 'c', amount: 120, cycle: BillingCycleType.yearly), // 10
          sub(
            id: 'd',
            amount: 480,
            cycle: BillingCycleType.yearly,
            interval: 2,
          ), // 20
        ],
        transactions: const [],
        rateData: rates,
        defaultCurrency: 'CNY',
      );
      expect(summary.monthlyDue, closeTo(52, 1e-9));
      expect(summary.yearlyAvg, closeTo(624, 1e-9));
    });

    test('converts at the current rates and ignores inactive subscriptions', () {
      final summary = summarizeSubscriptions(
        subscriptions: [
          sub(id: 'a', amount: 10, currency: 'USD'), // 70 CNY
          sub(id: 'b', amount: 99, isActive: false),
        ],
        transactions: const [],
        rateData: rates,
        defaultCurrency: 'CNY',
      );
      expect(summary.monthlyDue, closeTo(70, 1e-9));
    });

    test('monthly average falls back to the projection below two months', () {
      final now = DateTime(2026, 9, 1);
      // Elapsed months count calendar months, so history reaching back into
      // August is one month old on 1 September, however many entries it has.
      for (final history in [
        <Transaction>[],
        [tx(DateTime(2026, 8, 1), 5)],
        [tx(DateTime(2026, 8, 1), 5), tx(DateTime(2026, 8, 20), 5)],
      ]) {
        final summary = summarizeSubscriptions(
          subscriptions: [sub(amount: 12)],
          transactions: history,
          rateData: rates,
          defaultCurrency: 'CNY',
          now: now,
        );
        expect(summary.monthlyAvg, summary.monthlyDue);
      }
    });

    test('monthly average uses observed history at its own rate snapshots', () {
      final summary = summarizeSubscriptions(
        subscriptions: [sub(amount: 12)],
        transactions: [
          tx(DateTime(2026, 6, 1), 10, snapshot: 'old'), // 60 CNY
          tx(DateTime(2026, 7, 1), 10), // current: 70 CNY
          tx(DateTime(2026, 8, 1), 10), // 70 CNY
          Transaction(
            type: TransactionType.expense,
            amount: 999,
            accountId: 'acc',
            date: DateTime(2026, 8, 2),
          ), // not a subscription transaction
        ],
        rateData: rates,
        defaultCurrency: 'CNY',
        now: DateTime(2026, 9, 1),
      );
      // 200 CNY over the three months since June.
      expect(summary.monthlyAvg, closeTo(200 / 3, 1e-9));
      expect(summary.monthlyDue, closeTo(12, 1e-9));
    });
  });

  group('sortSubscriptions', () {
    final a = sub(id: 'a', name: 'beta', next: DateTime(2026, 9, 10));
    final b = sub(id: 'b', name: 'Alpha', next: DateTime(2026, 9, 5));
    final c = sub(id: 'c', name: 'gamma');

    test('next renewal puts the soonest first and undated last', () {
      final sorted = sortSubscriptions(
        [a, c, b],
        mode: subscriptionSortNextRenewal,
        customOrder: const [],
      );
      expect(sorted.map((s) => s.id), ['b', 'a', 'c']);
    });

    test('an unknown mode behaves like next renewal', () {
      final sorted = sortSubscriptions(
        [a, c, b],
        mode: 'something-newer',
        customOrder: const [],
      );
      expect(sorted.map((s) => s.id), ['b', 'a', 'c']);
    });

    test('name is case-insensitive', () {
      final sorted = sortSubscriptions(
        [a, c, b],
        mode: subscriptionSortName,
        customOrder: const [],
      );
      expect(sorted.map((s) => s.id), ['b', 'a', 'c']);
    });

    test('custom follows the order and sends unknown ids to the end', () {
      final sorted = sortSubscriptions(
        [a, b, c],
        mode: subscriptionSortCustom,
        customOrder: const ['c', 'a'],
      );
      expect(sorted.map((s) => s.id), ['c', 'a', 'b']);
    });

    test('custom with an empty order leaves the input order alone', () {
      final sorted = sortSubscriptions(
        [c, a, b],
        mode: subscriptionSortCustom,
        customOrder: const [],
      );
      expect(sorted.map((s) => s.id), ['c', 'a', 'b']);
    });

    test('never mutates the input list', () {
      final input = [a, c, b];
      sortSubscriptions(
        input,
        mode: subscriptionSortName,
        customOrder: const [],
      );
      expect(input.map((s) => s.id), ['a', 'c', 'b']);
    });
  });

  group('upcomingSubscriptions', () {
    final now = DateTime(2026, 9, 1, 15);

    test('includes billing dates within the window, soonest first', () {
      final result = upcomingSubscriptions(
        [
          sub(id: 'late', next: DateTime(2026, 9, 3, 23, 59)),
          sub(id: 'today', next: DateTime(2026, 9, 1, 8)), // earlier today
          sub(id: 'tomorrow', next: DateTime(2026, 9, 2)),
          sub(id: 'beyond', next: DateTime(2026, 9, 5)),
          sub(id: 'undated'),
        ],
        days: 3,
        now: now,
      );
      expect(result.map((e) => e.$1.id), ['today', 'tomorrow', 'late']);
    });

    test('excludes at-expiry and immediately cancelled subscriptions', () {
      final result = upcomingSubscriptions(
        [
          sub(
            id: 'expiring',
            cancelType: CancelType.atExpiry,
            next: DateTime(2026, 9, 2),
          ),
          sub(
            id: 'gone',
            isActive: false,
            cancelType: CancelType.immediate,
            next: DateTime(2026, 9, 2),
          ),
          sub(id: 'live', next: DateTime(2026, 9, 2)),
        ],
        days: 3,
        now: now,
      );
      expect(result.map((e) => e.$1.id), ['live']);
    });
  });
}

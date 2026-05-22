import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/finance/models/finance.dart';
import 'package:my_day/features/finance/services/subscription_processor.dart';

/// Purpose: Exercise subscription transaction catch-up behavior.
/// Inputs: None.
/// Returns: None.
/// Side effects: Temporarily overrides the subscription processor clock.
/// Notes: None.
void main() {
  tearDown(() {
    SubscriptionProcessor.debugNowOverride = null;
  });

  test('skips existing random-id billing transactions and advances date', () {
    SubscriptionProcessor.debugNowOverride = DateTime(2026, 5, 20, 12);
    final sub = Subscription(
      id: 'sub-1',
      name: 'Google Fi',
      startDate: DateTime(2026, 4, 13),
      billingCycleType: BillingCycleType.monthly,
      amount: 17.15,
      currency: 'USD',
      accountId: 'account-1',
      nextBillingDate: DateTime(2026, 4, 13),
    );
    final existing = [
      Transaction(
        id: 'legacy-april-id',
        type: TransactionType.expense,
        amount: 17.15,
        currency: 'USD',
        accountId: 'account-1',
        subscriptionId: sub.id,
        date: DateTime(2026, 4, 13),
      ),
      Transaction(
        id: 'legacy-may-id',
        type: TransactionType.expense,
        amount: 17.15,
        currency: 'USD',
        accountId: 'account-1',
        subscriptionId: sub.id,
        date: DateTime(2026, 5, 13),
      ),
    ];

    final result = SubscriptionProcessor.process([sub], existing);

    expect(result.changed, isTrue);
    expect(result.txs, isEmpty);
    expect(result.subs.single.nextBillingDate, DateTime(2026, 6, 13));
  });

  test('uses stable ids for newly generated billing transactions', () {
    SubscriptionProcessor.debugNowOverride = DateTime(2026, 5, 20, 12);
    final sub = Subscription(
      id: 'sub-2',
      name: 'Music',
      startDate: DateTime(2026, 5, 13),
      billingCycleType: BillingCycleType.monthly,
      amount: 9.99,
      currency: 'USD',
      accountId: 'account-1',
      nextBillingDate: DateTime(2026, 5, 13),
    );

    final result = SubscriptionProcessor.process([sub], const []);

    expect(result.changed, isTrue);
    expect(result.txs.length, 1);
    expect(
      result.txs.single.id,
      SubscriptionProcessor.transactionIdForBilling(
        sub.id,
        DateTime(2026, 5, 13),
      ),
    );
    expect(result.subs.single.nextBillingDate, DateTime(2026, 6, 13));
  });
}

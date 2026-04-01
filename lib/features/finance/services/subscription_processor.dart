import '../models/finance.dart';

/// Processes subscription renewals using the persisted [nextBillingDate] field.
///
/// When `now >= sub.nextBillingDate`, a transaction is generated at that date
/// and nextBillingDate is advanced to the next cycle. Loops to catch up if
/// the app was not opened for multiple cycles.
class SubscriptionProcessor {
  /// Set this to override DateTime.now() for testing / debugging.
  static DateTime? debugNowOverride;

  static DateTime get _now => debugNowOverride ?? DateTime.now();

  static ({List<Subscription> subs, List<Transaction> txs, bool changed}) process(
    List<Subscription> subscriptions,
    List<Transaction> existingTransactions,
  ) {
    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    final updatedSubs = <Subscription>[];
    final newTxs = <Transaction>[];
    bool changed = false;

    for (final sub in subscriptions) {
      // Skip immediately cancelled subscriptions
      if (!sub.isActive && sub.cancelType == CancelType.immediate) {
        updatedSubs.add(sub);
        continue;
      }

      // Migration: if nextBillingDate is not set, compute it now
      var nbd = sub.nextBillingDate;
      if (nbd == null) {
        nbd = sub.calculateNextBillingDate(after: today.subtract(const Duration(days: 1)));
        if (nbd == null) {
          // No future billing dates (e.g. cancelled)
          updatedSubs.add(sub);
          continue;
        }
        // Persist the computed nextBillingDate without generating transactions
        updatedSubs.add(_withNextBillingDate(sub, nbd));
        changed = true;
        continue;
      }

      final nbdDay = DateTime(nbd.year, nbd.month, nbd.day);

      // Generate transactions for each overdue billing date
      var cursor = nbdDay;
      bool subChanged = false;
      while (!cursor.isAfter(today)) {
        // Respect atExpiry cancellation
        if (sub.cancelType == CancelType.atExpiry &&
            sub.cancelledAt != null &&
            cursor.isAfter(sub.cancelledAt!)) {
          break;
        }

        newTxs.add(Transaction(
          type: TransactionType.expense,
          amount: sub.amount,
          currency: sub.currency,
          accountId: sub.accountId,
          categoryId: sub.categoryId,
          subscriptionId: sub.id,
          note: sub.name,
          date: cursor,
        ));

        // Advance to next cycle
        final first = sub.firstBillingDate;
        if (sub.billingCycleType == BillingCycleType.monthly) {
          cursor = DateTime(cursor.year, cursor.month + sub.billingInterval, first.day);
        } else {
          cursor = DateTime(cursor.year + sub.billingInterval, first.month, first.day);
        }
        subChanged = true;
      }

      // Check if an atExpiry sub has now expired
      final expired = sub.cancelType == CancelType.atExpiry &&
          sub.cancelledAt != null &&
          !nbdDay.isAfter(today) &&
          cursor.isAfter(sub.cancelledAt!);

      if (subChanged || (expired && sub.isActive)) {
        updatedSubs.add(_withNextBillingDate(
          sub, cursor, isActive: expired ? false : sub.isActive,
        ));
        changed = true;
      } else {
        updatedSubs.add(sub);
      }
    }

    return (subs: updatedSubs, txs: newTxs, changed: changed);
  }

  static Subscription _withNextBillingDate(Subscription sub, DateTime date, {bool? isActive}) {
    return Subscription(
      id: sub.id,
      name: sub.name,
      emoji: sub.emoji,
      imagePath: sub.imagePath,
      startDate: sub.startDate,
      trialDays: sub.trialDays,
      billingCycleType: sub.billingCycleType,
      billingInterval: sub.billingInterval,
      amount: sub.amount,
      currency: sub.currency,
      accountId: sub.accountId,
      categoryId: sub.categoryId,
      note: sub.note,
      isActive: isActive ?? sub.isActive,
      cancelledAt: sub.cancelledAt,
      cancelType: sub.cancelType,
      nextBillingDate: date,
    );
  }
}

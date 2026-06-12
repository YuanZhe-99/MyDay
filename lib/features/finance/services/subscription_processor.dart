import '../models/finance.dart';

/// Processes subscription renewals using the persisted [nextBillingDate] field.
///
/// When `now >= sub.nextBillingDate`, a transaction is generated at that date
/// and nextBillingDate is advanced to the next cycle. Loops to catch up if
/// the app was not opened for multiple cycles.
class SubscriptionProcessor {
  /// Set this to override DateTime.now() for testing / debugging.
  static DateTime? debugNowOverride;

  /// Purpose: Build the business key for a subscription billing day.
  /// Inputs: `subscriptionId`, `date`.
  /// Returns: A stable key string.
  /// Side effects: None.
  /// Notes: Used for idempotency across older random transaction IDs and newer stable IDs.
  static String billingDateKey(String subscriptionId, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final dateKey =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return '$subscriptionId|$dateKey';
  }

  /// Purpose: Build the stable transaction id for a subscription billing day.
  /// Inputs: `subscriptionId`, `date`.
  /// Returns: A deterministic transaction id string.
  /// Side effects: None.
  /// Notes: New generated subscription transactions use this so sync can merge same-day generation.
  static String transactionIdForBilling(String subscriptionId, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final dateKey =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return 'subscription_${subscriptionId}_$dateKey';
  }

  /// Purpose: Return now.
  /// Inputs: None.
  /// Returns: `DateTime`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static DateTime get _now => debugNowOverride ?? DateTime.now();

  /// Purpose: Generate overdue subscription transactions and advance persisted billing dates.
  /// Inputs: `subscriptions`, `existingTransactions`.
  /// Returns: `({List<Subscription> subs, List<Transaction> txs, bool changed})`.
  /// Side effects: None.
  /// Notes: Returns updated subscriptions plus any generated transactions for catch-up billing.
  static ({List<Subscription> subs, List<Transaction> txs, bool changed})
  process(
    List<Subscription> subscriptions,
    List<Transaction> existingTransactions,
  ) {
    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    final billedKeys = _existingBillingKeys(existingTransactions);
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
        nbd = sub.calculateNextBillingDate(
          after: today.subtract(const Duration(days: 1)),
        );
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

        final billingKey = billingDateKey(sub.id, cursor);
        if (!billedKeys.contains(billingKey)) {
          newTxs.add(
            Transaction(
              id: transactionIdForBilling(sub.id, cursor),
              type: TransactionType.expense,
              amount: sub.amount,
              currency: sub.currency,
              accountId: sub.accountId,
              categoryId: sub.categoryId,
              subscriptionId: sub.id,
              note: sub.name,
              date: cursor,
            ),
          );
          billedKeys.add(billingKey);
        }

        // Advance to next cycle (month-end anchors clamped, never drifting)
        cursor = Subscription.nextBillingCursor(
          cursor: cursor,
          cycleType: sub.billingCycleType,
          interval: sub.billingInterval,
          anchor: sub.firstBillingDate,
        );
        subChanged = true;
      }

      // Check if an atExpiry sub has now expired
      final expired =
          sub.cancelType == CancelType.atExpiry &&
          sub.cancelledAt != null &&
          !nbdDay.isAfter(today) &&
          cursor.isAfter(sub.cancelledAt!);

      if (subChanged || (expired && sub.isActive)) {
        updatedSubs.add(
          _withNextBillingDate(
            sub,
            cursor,
            isActive: expired ? false : sub.isActive,
          ),
        );
        changed = true;
      } else {
        updatedSubs.add(sub);
      }
    }

    return (subs: updatedSubs, txs: newTxs, changed: changed);
  }

  /// Purpose: Collect subscription billing days already represented by transactions.
  /// Inputs: `transactions`.
  /// Returns: A set of subscription billing day keys.
  /// Side effects: None.
  /// Notes: Existing historical transactions may have random IDs, so key by subscription/date instead.
  static Set<String> _existingBillingKeys(List<Transaction> transactions) {
    return {
      for (final tx in transactions)
        if (tx.subscriptionId != null)
          billingDateKey(tx.subscriptionId!, tx.date),
    };
  }

  /// Purpose: Provide the internal with next billing date helper for this file.
  /// Inputs: `sub`, `date`, `isActive`.
  /// Returns: `Subscription`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Subscription _withNextBillingDate(
    Subscription sub,
    DateTime date, {
    bool? isActive,
  }) {
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

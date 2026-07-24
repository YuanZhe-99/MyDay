# Subscription Billing

Source: `lib/features/finance/services/subscription_processor.dart` (read in full) and the
`nextBillingCursor`/`calculateNextBillingDate`/`billingDatesBefore` helpers on `Subscription` in
`lib/features/finance/models/finance.dart`. See [Finance](../features/finance.md) for where this
fits in the module, and
[Subscription Billing Walkthrough](../examples/subscription-billing-walkthrough.md) for concrete
dates.

## Month-end clamping: `Subscription.nextBillingCursor`

```dart
static DateTime nextBillingCursor({
  required DateTime cursor,
  required BillingCycleType cycleType,
  required int interval,
  required DateTime anchor,
}) {
  final int year;
  final int month;
  if (cycleType == BillingCycleType.monthly) {
    year = cursor.year;
    month = cursor.month + interval;
  } else {
    year = cursor.year + interval;
    month = anchor.month;
  }
  // Day 0 of the following month is the last day of the target month.
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = anchor.day < lastDay ? anchor.day : lastDay;
  return DateTime(year, month, day);
}
```

This is the **single** function every billing-date advance in the app goes through — both the
model's own `calculateNextBillingDate`/`billingDatesBefore` and `SubscriptionProcessor`'s catch-up
loop. The key trick is `DateTime(year, month + 1, 0)`: passing day `0` to `DateTime` in Dart yields
the last day of the *previous* month relative to `month + 1` — i.e. the last day of `month` itself.
That value, `lastDay`, is then used to clamp the anchor's day-of-month:

```dart
final day = anchor.day < lastDay ? anchor.day : lastDay;
```

So the **anchor day** (the day-of-month from the subscription's `firstBillingDate`, i.e.
`startDate + trialDays`) is preserved every cycle *unless* the target month is too short to contain
it, in which case the cursor lands on that month's actual last day instead of Dart's default
overflow behavior (which would otherwise roll `DateTime(2026, 2, 31)` forward into March). Notice
that `month` is allowed to exceed `12` (e.g. `month = 13`) — Dart's `DateTime` constructor already
normalizes a 13th "month" into January of `year + 1`, so the function doesn't need its own
year-rollover branch for the monthly case; only day-of-month needs the explicit clamp.

- **Monthly cycles** advance `month` by `interval` within the same `year` variable (letting
  `DateTime`'s constructor roll the year over naturally when `month > 12`).
- **Yearly cycles** advance `year` by `interval` and pin `month` to the anchor's month — so a yearly
  subscription anchored on Feb 29 clamps to Feb 28 in non-leap years (`lastDay` for February in a
  non-leap year is 28), and back to Feb 29 whenever the target year is a leap year.

Concrete monthly example: an anchor of **Jan 31** bills **Feb 28** (or 29 in a leap year), then
**Mar 31**, then **Apr 30**, then **May 31**, … — the anchor day (31) is re-applied every cycle,
clamped only when necessary, so the subscription never permanently drifts to a different
day-of-month the way naive `DateTime(year, month + 1, day)` arithmetic would (which would turn
Jan 31 → Mar 3 after passing through February).

## Idempotent billing-day generation

`SubscriptionProcessor.billingDateKey(subscriptionId, date)` builds a **business key** —
`'$subscriptionId|yyyy-MM-dd'` — independent of any transaction id. `_existingBillingKeys(...)`
scans all existing transactions and collects this key for every transaction that has a
`subscriptionId`, regardless of whether that transaction's own `id` is an older random UUID
(historical, pre-idempotency transactions) or a newer **stable id**:

```dart
static String transactionIdForBilling(String subscriptionId, DateTime date) =>
    'subscription_${subscriptionId}_yyyy-MM-dd';
```

Because the stable id is deterministic per subscription+day, generating it twice (e.g. once locally
and once after a sync merge sees the same subscription from another device) produces the *same*
transaction id both times — so a `mergeRecords`-style id-keyed merge naturally treats them as the
same record instead of creating a duplicate. The `process()` loop only appends a new transaction
when `billingKey` is **not already** in `billedKeys`, so re-running the processor against a
transaction list that already contains that day's charge (by either id scheme) is a no-op for that
day.

## Hourly renewal catch-up and multi-cycle catch-up

`SubscriptionProcessor.process(subscriptions, existingTransactions)` runs (per `AGENTS.md`) on an
hourly cadence via the reminder loop. For each subscription:

1. **Immediately-cancelled** subscriptions are passed through unchanged.
2. **Migration case:** if `nextBillingDate` was never persisted (an older subscription predating
   this field), it's computed once via `calculateNextBillingDate(after: yesterday)` and persisted
   without generating any transaction for that pass — this avoids retroactively billing for a
   subscription that simply hadn't been touched by this code path yet.
3. **Catch-up loop:** starting from the persisted `nextBillingDate`, the cursor advances one cycle
   at a time via `nextBillingCursor` (respecting `atExpiry` cancellation cutoffs), generating one
   transaction per overdue billing day it passes, **until the cursor is no longer `<= today`**. If
   the app was closed for three missed monthly cycles, this loop generates all three transactions
   and lands the cursor on the correct next-future date in one pass — this is the "multi-cycle
   catch-up" behavior.
4. **At-expiry expiration check:** if the subscription's `cancelType` is `atExpiry`, its
   `cancelledAt` is set, the pre-loop `nextBillingDate` was not already after today, and the
   post-loop cursor is after `cancelledAt`, the subscription is marked `isActive = false` in the
   same update.

The function returns `(subs, txs, changed)` — updated subscriptions, newly generated transactions,
and whether anything changed at all (so the caller can skip a save when nothing needed updating).

## Related pages

- [Finance](../features/finance.md) — where `SubscriptionProcessor` sits among the other Finance
  services.
- [Subscription Billing Walkthrough](../examples/subscription-billing-walkthrough.md) — the Jan 31
  anchor advancing through Feb/Mar/Apr with concrete calendar dates.
- [Data Formats](../data-formats.md) — the full `Subscription` field list.

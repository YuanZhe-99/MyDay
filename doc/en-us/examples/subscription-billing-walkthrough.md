# Subscription Billing Walkthrough: A Jan-31 Monthly Subscription

A concrete-date worked example of
[`Subscription.nextBillingCursor`'s month-end clamping](../algorithms/subscription-billing.md) and
`SubscriptionProcessor`'s catch-up billing, computed by hand-tracing the real algorithm in
`lib/features/finance/models/finance.dart` and `lib/features/finance/services/
subscription_processor.dart`. 2026 is not a leap year, so February has 28 days that year.

## Setup

```dart
final sub = Subscription(
  id: 'sub-abc',
  name: 'Streaming Plan',
  startDate: DateTime(2026, 1, 31),
  trialDays: 0,
  billingCycleType: BillingCycleType.monthly,
  billingInterval: 1,
  amount: 9.99,
  currency: 'USD',
  accountId: 'acc-1',
);
```

`firstBillingDate = startDate + trialDays = 2026-01-31`. This date is the **anchor** for every
future cursor advance — its day-of-month, `31`, is what every subsequent `nextBillingCursor` call
tries to preserve.

## Step 1 — First run on Jan 31, 2026: migration branch

The subscription was just created, so `nextBillingDate` is still unset.
`SubscriptionProcessor.process()` hits the migration branch:

```dart
nbd = sub.calculateNextBillingDate(after: today.subtract(const Duration(days: 1)));
```

With `after = 2026-01-30`, `calculateNextBillingDate` starts `cursor` at the anchor
(`2026-01-31`) and the `while (!cursor.isAfter(after))` loop doesn't even run once, because
`2026-01-31` is already after `2026-01-30`. So `nbd = 2026-01-31` — this first run **only persists**
`nextBillingDate = 2026-01-31` on the subscription. No transaction is generated yet; that avoids
retroactively billing for a subscription the processor hasn't actually walked through yet.

## Step 2 — Later the same day (or any run with `today >= Jan 31`): first bill

Now `nbd = 2026-01-31` is set. `nbdDay = 2026-01-31`. `cursor` starts there.

- `cursor (Jan 31).isAfter(today)` is false → enter the loop.
- `billingDateKey('sub-abc', Jan 31) = 'sub-abc|2026-01-31'` is not yet in `billedKeys` → generate
  a transaction: `id: 'subscription_sub-abc_2026-01-31'`, `date: 2026-01-31`, `amount: 9.99`.
- Advance: `nextBillingCursor(cursor: Jan 31, cycleType: monthly, interval: 1, anchor: Jan 31)`:
  - `year = 2026`, `month = 1 + 1 = 2` (February).
  - `lastDay = DateTime(2026, 3, 0).day = 28` (Feb 2026 has 28 days — day 0 of March is the last
    day of February).
  - `day = anchor.day (31) < lastDay (28) ? 31 : 28` → **28** (31 is not less than 28).
  - Result: **`2026-02-28`**.
- `cursor (Feb 28).isAfter(today = Jan 31)` is true → loop stops.

One transaction generated (Jan 31, $9.99); `nextBillingDate` persisted as **`2026-02-28`**.

## Step 3 — App reopened on Apr 5, 2026: multi-cycle catch-up

The user didn't open the app again until **April 5**. One `process()` call now needs to catch up
**two** missed cycles (February and March) in a single pass.

`nbd = 2026-02-28`, `today = 2026-04-05`. The loop runs twice before `cursor` finally exceeds
`today`:

| Iteration | `cursor` at start | Billed? | `nextBillingCursor` advance | New `cursor` |
| --- | --- | --- | --- | --- |
| 1 | `2026-02-28` | Not yet billed → generate tx for **Feb 28**, $9.99 | `month = 2+1=3` (March); `lastDay = DateTime(2026,4,0).day = 31`; `day = 31 < 31 ? 31 : 31 = 31` | `2026-03-31` |
| 2 | `2026-03-31` | Not yet billed → generate tx for **Mar 31**, $9.99 | `month = 3+1=4` (April); `lastDay = DateTime(2026,5,0).day = 30`; `day = 31 < 30 ? 31 : 30 = 30` | `2026-04-30` |
| — | `2026-04-30` | `cursor.isAfter(today = Apr 5)` is true → loop stops | — | — |

Two transactions are generated in this single pass — Feb 28 and Mar 31 — and `nextBillingDate` is
persisted as **`2026-04-30`**. Note the anchor day (31) survived February's clamp to 28 without
being permanently lost: March correctly billed on the 31st again, and only April (30 days) clamped
it down to the 30th. This is exactly the "never skips or drifts months" guarantee: naive
`DateTime(year, month + 1, day)` arithmetic would instead overflow `Feb 31` into `Mar 3`, and every
later cycle would then be anchored on day 3 instead of day 31 forever.

## Step 4 — Continuing the pattern

If nothing else changes, the next few cursors (still anchored on day 31) are:

- `2026-04-30` → `2026-05-31` (May has 31 days, no clamp needed)
- `2026-05-31` → `2026-06-30` (June clamps to 30)
- `2026-06-30` → `2026-07-31` (July has 31, anchor fully restored again)

## Idempotency across devices

If this same subscription also exists on a second device that independently ran its own catch-up
and generated a transaction for, say, March 31 before this device synced, both transactions carry
the identical stable id `subscription_sub-abc_2026-03-31` (see
[Subscription Billing](../algorithms/subscription-billing.md#idempotent-billing-day-generation)).
When [three-way merge](../algorithms/three-way-merge.md) runs on `finance_data.json`, the two
`Transaction` records for that id are treated as the same record rather than duplicated — and even
before sync, `_existingBillingKeys` on either device would have recognized the other's transaction
by its `subscriptionId|date` business key regardless of which device (or transaction-id scheme)
originally created it, so a second local catch-up run never bills March 31 twice either.

## Related pages

- [Subscription Billing](../algorithms/subscription-billing.md) — the algorithm this walkthrough
  traces.
- [Finance](../features/finance.md) — where `SubscriptionProcessor` fits into the module.
- [Three-Way Merge](../algorithms/three-way-merge.md) — how generated transactions merge across
  devices.

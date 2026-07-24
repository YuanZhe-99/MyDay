# lib/features/finance/services/subscription_processor.dart

`SubscriptionProcessor` is the hourly renewal engine for subscriptions: given the persisted
`nextBillingDate` on each [`Subscription`](../models/finance.md#subscription-new), it generates one
transaction per overdue billing day (catching up multiple missed cycles in a single pass if the app
was closed for a while), advances the cursor via
[`Subscription.nextBillingCursor`](../models/finance.md#nextbillingcursor), and flips a subscription
inactive once an `atExpiry` cancellation's cutoff has passed. Read in full — this file has no logic
beyond what's shown below. See
[Subscription Billing](../../../../algorithms/subscription-billing.md) for the complete algorithm
write-up (idempotent billing-day generation, hourly/multi-cycle catch-up, at-expiry expiration) and
[Finance](../../../../features/finance.md#subscription-processing) for how this fits the feature.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `debugNowOverride` (static field) | field | B | Test/debug override for `DateTime.now()` — no Purpose block (see Reconciliation). |
| [`billingDateKey`](#billingdatekey) | static method (`SubscriptionProcessor`) | A | Build the idempotency business key for a subscription billing day. |
| [`transactionIdForBilling`](#transactionidforbilling) | static method (`SubscriptionProcessor`) | A | Build the deterministic transaction id for a subscription billing day. |
| `_now` | static getter (`SubscriptionProcessor`) | B | Return `debugNowOverride ?? DateTime.now()`. |
| [`process`](#process) | static method (`SubscriptionProcessor`) | A | Generate overdue subscription transactions and advance persisted billing dates. |
| [`_existingBillingKeys`](#existingbillingkeys) | static method (`SubscriptionProcessor`) | A | Collect subscription billing days already represented by transactions. |
| [`_withNextBillingDate`](#withnextbillingdate) | static method (`SubscriptionProcessor`) | A | Copy a subscription with `nextBillingDate`/`isActive` replaced. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/services/subscription_processor.dart`
returns 6, matching the 6 documented rows above exactly — each block sits immediately above its real
static method or getter declaration; none were found misattached above a call-site statement. The
table has one additional row beyond those 6: the plain `static DateTime? debugNowOverride;` field,
which carries no `/// Purpose:` block, consistent with this codebase's convention of documenting
callable members rather than plain data fields. Cross-checking every `static`/`get` declaration in
the file against this list turned up no undocumented callable declaration. `billingDateKey`,
`transactionIdForBilling`, `process`, `_existingBillingKeys`, and `_withNextBillingDate` are
classified Tier A — the first two build the idempotency keys the whole billing algorithm depends on
(documented in detail in `subscription-billing.md`), and the latter three contain the core
loop/branching logic; `_now` is classified Tier B as a trivial one-line null-coalescing getter.

## Documentation

### `static String billingDateKey(String subscriptionId, DateTime date)` <a id="billingdatekey"></a>
- **Kind:** static method of `SubscriptionProcessor`
- **Source:** `lib/features/finance/services/subscription_processor.dart` (line 17)
- **Purpose:** Build the business key `'<subscriptionId>|yyyy-MM-dd'` used to detect whether a
  subscription has already billed on a given calendar day, independent of any transaction id.
- **Inputs:** `subscriptionId`; `date` — only the year/month/day are used.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** Truncate `date` to midnight, zero-pad year/month/day, and interpolate as
  `'$subscriptionId|$dateKey'`.
- **Usage:**
  ```dart
  final billingKey = billingDateKey(sub.id, cursor);
  if (!billedKeys.contains(billingKey)) { ... }
  ```
  (`lib/features/finance/services/subscription_processor.dart:97-98`, inside [`process`](#process);
  also used to build the `billedKeys` set in
  [`_existingBillingKeys`](#existingbillingkeys).)
- **Notes:** See [Subscription Billing](../../../../algorithms/subscription-billing.md#idempotent-billing-day-generation)
  for why this business key — not the transaction's own `id` — is what makes re-running `process`
  against an already-billed day a no-op, recognizing both older random-id and newer stable-id
  transactions alike.

### `static String transactionIdForBilling(String subscriptionId, DateTime date)` <a id="transactionidforbilling"></a>
- **Kind:** static method of `SubscriptionProcessor`
- **Source:** `lib/features/finance/services/subscription_processor.dart` (line 29)
- **Purpose:** Build the deterministic transaction id `'subscription_<subscriptionId>_yyyy-MM-dd'`
  assigned to newly-generated billing transactions, so the same subscription+day always produces the
  same id.
- **Inputs:** `subscriptionId`; `date` — only the year/month/day are used.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** Truncate `date` to midnight, zero-pad year/month/day, and interpolate as
  `'subscription_${subscriptionId}_$dateKey'`.
- **Usage:**
  ```dart
  newTxs.add(
    Transaction(
      id: transactionIdForBilling(sub.id, cursor),
      type: TransactionType.expense,
      amount: sub.amount,
      ...
    ),
  );
  ```
  (`lib/features/finance/services/subscription_processor.dart:100-101`, inside [`process`](#process).)
- **Notes:** Because this id is deterministic per subscription+day, generating it independently on
  two devices (e.g. once locally, once after a sync merge sees the same subscription) produces the
  *same* id both times, so an id-keyed merge treats them as one record instead of duplicating —
  detailed in [Subscription Billing](../../../../algorithms/subscription-billing.md#idempotent-billing-day-generation).

### `static ({List<Subscription> subs, List<Transaction> txs, bool changed}) process(List<Subscription> subscriptions, List<Transaction> existingTransactions)` <a id="process"></a>
- **Kind:** static method of `SubscriptionProcessor`
- **Source:** `lib/features/finance/services/subscription_processor.dart` (line 48)
- **Purpose:** Run one hourly (or on-demand) renewal pass over every subscription: generate a
  transaction for each overdue billing day, catching up multiple missed cycles in one call, and mark
  `atExpiry`-cancelled subscriptions inactive once their cutoff has passed.
- **Inputs:** `subscriptions` — the full current list; `existingTransactions` — used to detect
  already-billed days via [`_existingBillingKeys`](#existingbillingkeys).
- **Returns:** `({subs, txs, changed})` — `subs` is the full updated subscription list (same length,
  order-preserving), `txs` is only the newly-generated transactions, `changed` is `true` if any
  subscription's persisted state changed at all (so the caller can skip a save when nothing did).
- **Side effects:** None (pure function over its inputs — the only implicit input is `_now`, i.e.
  `debugNowOverride ?? DateTime.now()`).
- **Algorithm:** See [Subscription Billing](../../../../algorithms/subscription-billing.md#hourly-renewal-catch-up-and-multi-cycle-catch-up)
  for the full walkthrough. In brief, per subscription:
  1. Pass through unchanged if immediately cancelled.
  2. **Migration case:** if `nextBillingDate` was never persisted, compute it once via
     `calculateNextBillingDate(after: yesterday)` and persist it without generating a transaction for
     this pass.
  3. **Catch-up loop:** starting from the persisted `nextBillingDate`, advance one cycle at a time via
     [`Subscription.nextBillingCursor`](../models/finance.md#nextbillingcursor) (stopping early at an
     `atExpiry` cutoff), generating one transaction per overdue day via
     [`billingDateKey`](#billingdatekey)/[`transactionIdForBilling`](#transactionidforbilling), until
     the cursor is no longer `<= today`.
  4. **At-expiry check:** if the subscription is `atExpiry`-cancelled, its pre-loop
     `nextBillingDate` wasn't already past today, and the post-loop cursor is past `cancelledAt`,
     mark it `isActive = false` in the same update.
- **Usage:**
  ```dart
  final result = SubscriptionProcessor.process(_subscriptions, _transactions);
  if (result.changed) {
    setState(() {
      _subscriptions = result.subs;
      _transactions = [..._transactions, ...result.txs];
    });
  }
  ```
  (`lib/features/finance/views/finance_page.dart:145-150`, `_processSubscriptions`; the same shape
  runs from `lib/shared/services/reminder_service.dart:964-968` on the hourly reminder loop
  referenced in `AGENTS.md`.)
- **Notes:** If the app was closed for three missed monthly cycles, this single call generates all
  three transactions and lands the cursor on the correct next-future date — the "multi-cycle
  catch-up" behavior documented in `subscription-billing.md`.

### `static Set<String> _existingBillingKeys(List<Transaction> transactions)` <a id="existingbillingkeys"></a>
- **Kind:** static method of `SubscriptionProcessor`
- **Source:** `lib/features/finance/services/subscription_processor.dart` (line 154)
- **Purpose:** Collect the set of subscription billing-day keys already represented among existing
  transactions, regardless of whether each transaction's own `id` is an older random UUID or a newer
  stable id.
- **Inputs:** `transactions` — the full existing transaction list.
- **Returns:** `Set<String>` of [`billingDateKey`](#billingdatekey) values.
- **Side effects:** None.
- **Algorithm:** Set comprehension over `transactions`, including `billingDateKey(tx.subscriptionId!,
  tx.date)` for every transaction with a non-null `subscriptionId`.
- **Usage:** Called once at the top of [`process`](#process): `final billedKeys =
  _existingBillingKeys(existingTransactions);`.
- **Notes:** Keying by subscription id + calendar day (not transaction id) is what makes this
  recognize historical random-id transactions as already-billed, per
  [Subscription Billing](../../../../algorithms/subscription-billing.md#idempotent-billing-day-generation).

### `static Subscription _withNextBillingDate(Subscription sub, DateTime date, {bool? isActive})` <a id="withnextbillingdate"></a>
- **Kind:** static method of `SubscriptionProcessor`
- **Source:** `lib/features/finance/services/subscription_processor.dart` (line 167)
- **Purpose:** Return a copy of a subscription with `nextBillingDate` replaced and `isActive`
  optionally overridden, carrying every other field over unchanged.
- **Inputs:** `sub`; `date` — the new `nextBillingDate`; `isActive` — optional override (used to flip
  an expired `atExpiry` subscription inactive).
- **Returns:** A new `Subscription`.
- **Side effects:** None.
- **Algorithm:** Construct a new `Subscription` copying every field from `sub` verbatim except
  `nextBillingDate: date` and `isActive: isActive ?? sub.isActive`.
- **Usage:** Called from both branches of [`process`](#process) that need to persist a new cursor —
  the migration-case branch (`_withNextBillingDate(sub, nbd)`) and the catch-up-loop branch
  (`_withNextBillingDate(sub, cursor, isActive: expired ? false : sub.isActive)`).
- **Notes:** This is `Subscription`'s copy-with-style helper in all but name — `Subscription` itself
  has no `copyWith` method, so `SubscriptionProcessor` reconstructs the object field-by-field
  instead.

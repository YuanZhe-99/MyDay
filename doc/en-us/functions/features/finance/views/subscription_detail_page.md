# lib/features/finance/views/subscription_detail_page.dart

Detail page for one [`Subscription`](../../../../features/finance.md#model): shows a summary card
(billing cycle label, total spent to date, next-billing/expiry date, cancellation date) followed by
the grouped list of transactions billed to it, with swipe-to-edit/delete. See
[Finance](../../../../features/finance.md#subscription-processing) for how `nextBillingDate` and
`cancelType` are produced by `SubscriptionProcessor`, and
[Subscription Billing](../../../../algorithms/subscription-billing.md) for the month-end clamping
behind them. This page itself does no billing/cancellation logic — it only displays and edits the
transactions a subscription has already generated.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SubscriptionDetailPage({...})` | constructor (`SubscriptionDetailPage`) | B | Create a subscription detail page instance. |
| `createState` | method (`SubscriptionDetailPage`) | B | Create the mutable state object for this widget. |
| `initState` | method (`_SubscriptionDetailPageState`) | B | Copy `widget.transactions` into local mutable state. |
| [`_filtered`](#filtered) | getter (`_SubscriptionDetailPageState`) | A | Return this subscription's transactions, newest first. |
| [`_totalSpent`](#totalspent) | getter (`_SubscriptionDetailPageState`) | A | Sum this subscription's transactions, converted to the default currency. |
| `_deleteTransaction` | method (`_SubscriptionDetailPageState`) | B | Remove a transaction from local state and notify the parent. |
| [`_editTransaction`](#edittransaction) | method (`_SubscriptionDetailPageState`) | A | Edit a billed transaction while preserving its `subscriptionId`. |
| `build` | method (`_SubscriptionDetailPageState`) | B | Build the summary card and transaction list. |
| `_TxTile({...})` | constructor (`_TxTile`) | B | Create a tx tile instance. |
| `build` | method (`_TxTile`) | B | Build one transaction's list tile. |
| `_buildLeading` | method (`_TxTile`, widget helper) | B | Build the tile's leading avatar (subscription/account image or a fallback icon). |
| `defaultAvatar` (nested in `_buildLeading`) | local function (widget helper) | B | Build the fallback subscription avatar. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/views/subscription_detail_page.dart`
returns 12, matching the 12 rows above exactly — every block sits immediately above its real
declaration (a constructor, `createState`, `initState`, a getter, a method, or the nested local
function inside `_buildLeading`); none were found misattached above a call-site statement, and no
undocumented real declaration was found. The class declarations themselves
(`SubscriptionDetailPage`, `_SubscriptionDetailPageState`, `_TxTile`) and their plain widget fields
carry no `/// Purpose:` block, consistent with this codebase's convention of documenting callable
members rather than classes or data fields.

## Documentation

### `List<Transaction> get _filtered` <a id="filtered"></a>
- **Kind:** getter of `_SubscriptionDetailPageState`
- **Source:** `lib/features/finance/views/subscription_detail_page.dart` (line 70)
- **Purpose:** Return every transaction billed to this subscription, most recent first.
- **Inputs:** None (reads `_transactions`, `widget.subscription.id`).
- **Returns:** `List<Transaction>`.
- **Side effects:** None.
- **Algorithm:**
  1. Filter `_transactions` to those whose `subscriptionId` equals `widget.subscription.id`.
  2. Sort the result descending by `date` (most recent first).
- **Usage:**
  ```dart
  final filtered = _filtered;
  ...
  child: filtered.isEmpty ? Center(...) : buildGroupedTransactionList(context, filtered, ...),
  ```
- **Notes:** Filters purely by `subscriptionId` — if a transaction were ever re-pointed at a
  different subscription (not exposed anywhere in this UI), it would silently drop out of this
  list on next rebuild.

### `double get _totalSpent` <a id="totalspent"></a>
- **Kind:** getter of `_SubscriptionDetailPageState`
- **Source:** `lib/features/finance/views/subscription_detail_page.dart` (line 81)
- **Purpose:** Sum every transaction billed to this subscription, converted into the app's default
  currency using the exchange rate that was in effect when each transaction was recorded.
- **Inputs:** None (reads [`_filtered`](#filtered), `widget.rateData`, `widget.defaultCurrency`).
- **Returns:** `double`, in `widget.defaultCurrency`.
- **Side effects:** None.
- **Algorithm:**
  1. Start from [`_filtered`](#filtered) (this subscription's transactions).
  2. For each transaction, resolve the rate snapshot in effect via
     `widget.rateData.ratesAt(t.rateSnapshotId)`
     ([`ExchangeRateData.ratesAt`](../services/exchange_rate_storage.md#ratesat)) and convert
     `t.amount` from `t.currency` to `widget.defaultCurrency` via
     [`convertCurrency`](../services/balance_util.md#convertcurrency).
  3. Fold (sum) the converted amounts, starting from `0.0`.
- **Usage:**
  ```dart
  Text(
    '${l10n.financeTotalSpent}: $sym${numberFormat.format(_totalSpent)}',
    ...
  )
  ```
- **Notes:** Converts at each transaction's own historical rate snapshot, not at today's rate, so
  the total reflects what was actually paid rather than a re-conversion at current rates.

### `Future<void> _editTransaction(Transaction tx)` <a id="edittransaction"></a>
- **Kind:** method of `_SubscriptionDetailPageState`
- **Source:** `lib/features/finance/views/subscription_detail_page.dart` (lines 110-144)
- **Purpose:** Open the add/edit transaction dialog for an existing subscription-billed
  transaction, then reapply this transaction's `subscriptionId` onto whatever
  `AddTransactionDialog` returns, since that dialog has no notion of subscriptions.
- **Inputs:** `tx` — the `Transaction` being edited.
- **Returns:** `Future<void>`.
- **Side effects:** Shows `AddTransactionDialog`
  ([`../widgets/add_transaction_dialog.md`](../widgets/add_transaction_dialog.md)); on confirmation,
  replaces the matching entry in `_transactions` and calls `widget.onTransactionsChanged`.
- **Algorithm:**
  1. Show `AddTransactionDialog` pre-filled with `tx`.
  2. If the user confirms (the dialog returns non-null), rebuild a brand-new `Transaction` copying
     every field from the dialog's result *except* `subscriptionId`, which is taken from the
     original `tx.subscriptionId` instead — the dialog result would otherwise have no
     `subscriptionId` at all.
  3. Replace the matching transaction (by `id`) in `_transactions` inside `setState`.
  4. Notify the parent via `widget.onTransactionsChanged`.
- **Usage:**
  ```dart
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.startToEnd) {
      _editTransaction(tx);
      return false;
    }
    return confirmDelete(context, l10n.financeThisTransaction);
  },
  ```
- **Notes:** This is the only place in the file that reconstructs a `Transaction` via its full
  constructor instead of `copyWith` — necessary specifically to guarantee `subscriptionId` survives
  the round-trip through a dialog that doesn't know about subscriptions. Contrast with
  `category_detail_page.dart`'s `_editTransaction`, which has no such field to preserve and simply
  stores the dialog's result as-is.

## Related pages

- [Finance](../../../../features/finance.md) — `Subscription`/`Transaction` model fields and the
  cancel/restore semantics implemented elsewhere (`subscriptions_page.dart`).
- [`ExchangeRateStorage`](../services/exchange_rate_storage.md) — `ratesAt`, the historical-snapshot
  lookup used by [`_totalSpent`](#totalspent).
- [`balance_util.dart`](../services/balance_util.md) — `convertCurrency`, the cross-currency
  conversion used by [`_totalSpent`](#totalspent).
- [`add_transaction_dialog.dart`](../widgets/add_transaction_dialog.md) — the dialog shown by
  [`_editTransaction`](#edittransaction).
- [`grouped_transaction_list.dart`](../widgets/grouped_transaction_list.md) — `buildGroupedTransactionList`,
  used to render the date-grouped transaction list in `build`.

# lib/features/finance/views/category_detail_page.dart

Drill-down page for one [`Category`](../../../../features/finance.md#model) (or, when `categoryId`
is `null`, the "uncategorized" bucket for a transaction type): a monthly summary card followed by
the grouped list of matching transactions, with swipe-to-edit/delete and a floating add button.
This is the page `categories_page.dart` and the Finance analysis page's clickable category
breakdown both push to when a category is tapped. See
[Finance](../../../../features/finance.md#views-and-analysis-page) for how this fits into the
category drill-down feature.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `CategoryDetailPage({...})` | constructor (`CategoryDetailPage`) | B | Create a category detail page instance. |
| `createState` | method (`CategoryDetailPage`) | B | Create the mutable state object for this widget. |
| `initState` | method (`_CategoryDetailPageState`) | B | Copy `widget.transactions` into local mutable state. |
| [`_filtered`](#filtered) | getter (`_CategoryDetailPageState`) | A | Return transactions matching this page's type and category, newest first. |
| [`_monthFiltered`](#monthfiltered) | getter (`_CategoryDetailPageState`) | A | Restrict `_filtered` to the current calendar month. |
| [`_monthTotal`](#monthtotal) | getter (`_CategoryDetailPageState`) | A | Sum this month's matching transactions, converted to the default currency. |
| [`_addTransaction`](#addtransaction) | method (`_CategoryDetailPageState`) | A | Add a transaction pre-seeded with this page's category and type. |
| `_deleteTransaction` | method (`_CategoryDetailPageState`) | B | Remove a transaction from local state and notify the parent. |
| `_editTransaction` | method (`_CategoryDetailPageState`) | B | Edit a transaction and replace it in local state. |
| `build` | method (`_CategoryDetailPageState`) | B | Build the monthly summary card and transaction list. |
| `_TxTile({...})` | constructor (`_TxTile`) | B | Create a tx tile instance. |
| `build` | method (`_TxTile`) | B | Build one transaction's list tile. |
| `_buildLeading` | method (`_TxTile`, widget helper) | B | Build the tile's leading avatar (account image or a fallback icon). |
| `defaultAvatar` (nested in `_buildLeading`) | local function (widget helper) | B | Build the fallback category transaction avatar. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/views/category_detail_page.dart`
returns 14, matching the 14 rows above exactly — every block sits immediately above its real
declaration (a constructor, `createState`, `initState`, a getter, a method, or the nested local
function inside `_buildLeading`); none were found misattached above a call-site statement, and no
undocumented real declaration was found. The class declarations themselves (`CategoryDetailPage`,
`_CategoryDetailPageState`, `_TxTile`) and their plain widget fields carry no `/// Purpose:` block,
consistent with this codebase's convention of documenting callable members rather than classes or
data fields.

## Documentation

### `List<Transaction> get _filtered` <a id="filtered"></a>
- **Kind:** getter of `_CategoryDetailPageState`
- **Source:** `lib/features/finance/views/category_detail_page.dart` (line 74)
- **Purpose:** Return every transaction matching this page's transaction type and category —
  including the "uncategorized" case, where `widget.categoryId` is `null` — most recent first.
- **Inputs:** None (reads `_transactions`, `widget.transactionType`, `widget.categoryId`).
- **Returns:** `List<Transaction>`.
- **Side effects:** None.
- **Algorithm:**
  1. Filter `_transactions` to those whose `type` equals `widget.transactionType` **and** whose
     `categoryId` equals `widget.categoryId`.
  2. Sort the result descending by `date`.
- **Usage:**
  ```dart
  final filtered = _filtered;
  ...
  child: filtered.isEmpty ? Center(...) : buildGroupedTransactionList(context, filtered, ...),
  ```
- **Notes:** A `null == null` match on `categoryId` is what makes this page double as the
  "uncategorized" view: constructing it with `categoryId: null` selects every transaction of the
  given type that has no category assigned, rather than matching nothing.

### `List<Transaction> get _monthFiltered` <a id="monthfiltered"></a>
- **Kind:** getter of `_CategoryDetailPageState`
- **Source:** `lib/features/finance/views/category_detail_page.dart` (lines 89-94)
- **Purpose:** Further restrict [`_filtered`](#filtered) to transactions dated in the current
  calendar month, for the monthly summary card.
- **Inputs:** None (reads [`_filtered`](#filtered) and the device's current date).
- **Returns:** `List<Transaction>`.
- **Side effects:** None.
- **Algorithm:** Capture `DateTime.now()`, then filter [`_filtered`](#filtered) to entries whose
  `date.year`/`date.month` both match the current year/month.
- **Usage:**
  ```dart
  double get _monthTotal {
    return _monthFiltered.fold(0.0, (sum, t) => sum + convertCurrency(...));
  }
  ```
- **Notes:** Recomputed on every access (not cached), so the summary stays correct if the page is
  left open across a month boundary and rebuilds.

### `double get _monthTotal` <a id="monthtotal"></a>
- **Kind:** getter of `_CategoryDetailPageState`
- **Source:** `lib/features/finance/views/category_detail_page.dart` (lines 101-113)
- **Purpose:** Sum this month's matching transactions, converted into the app's default currency
  using the exchange rate in effect when each transaction was recorded.
- **Inputs:** None (reads [`_monthFiltered`](#monthfiltered), `widget.rateData`,
  `widget.defaultCurrency`).
- **Returns:** `double`, in `widget.defaultCurrency`.
- **Side effects:** None.
- **Algorithm:** For each transaction in [`_monthFiltered`](#monthfiltered), resolve
  `widget.rateData.ratesAt(t.rateSnapshotId)`
  ([`ExchangeRateData.ratesAt`](../services/exchange_rate_storage.md#ratesat)) and convert
  `t.amount` from `t.currency` to `widget.defaultCurrency` via
  [`convertCurrency`](../services/balance_util.md#convertcurrency); fold (sum) the results.
- **Usage:**
  ```dart
  Text(
    '$sym${numberFormat.format(_monthTotal)}',
    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: totalColor),
  )
  ```
- **Notes:** Like `subscription_detail_page.dart`'s `_totalSpent`, converts at each transaction's
  own historical rate snapshot rather than at today's rate.

### `Future<void> _addTransaction()` <a id="addtransaction"></a>
- **Kind:** method of `_CategoryDetailPageState`
- **Source:** `lib/features/finance/views/category_detail_page.dart` (lines 120-137)
- **Purpose:** Open the add-transaction dialog pre-seeded with this page's category and transaction
  type, so a transaction added from a category's detail page lands in that category by default.
- **Inputs:** None (reads `widget.category`, `widget.transactionType`, `widget.rateData`,
  `widget.defaultCurrency`, `widget.accountPickerSettings`).
- **Returns:** `Future<void>`.
- **Side effects:** Shows `AddTransactionDialog`
  ([`../widgets/add_transaction_dialog.md`](../widgets/add_transaction_dialog.md)); on confirmation
  inserts the new transaction into `_transactions` and calls `widget.onTransactionsChanged`.
- **Algorithm:**
  1. Show `AddTransactionDialog` with `initialCategoryId: widget.category?.id` (`null` for the
     uncategorized view) and `initialType: widget.transactionType` pre-filled.
  2. If the user confirms, insert the resulting transaction at index `0` of `_transactions` and
     notify the parent via `widget.onTransactionsChanged`.
- **Usage:**
  ```dart
  floatingActionButton: FloatingActionButton(
    onPressed: _addTransaction,
    child: const Icon(Icons.add),
  ),
  ```
- **Notes:** The insert position (index `0`) doesn't actually determine display order — the list
  shown in `build` always re-derives from [`_filtered`](#filtered), whose own date sort takes over
  regardless of insertion order. Unlike `subscription_detail_page.dart` (which has no add button —
  subscription transactions are generated by `SubscriptionProcessor`), this page lets the user add
  directly.

## Related pages

- [Finance](../../../../features/finance.md) — `Category` model fields and the category
  drill-down/breakdown feature this page implements the "detail" half of (the breakdown itself is
  computed in `analysis_page.dart`).
- [`ExchangeRateStorage`](../services/exchange_rate_storage.md) — `ratesAt`, used by
  [`_monthTotal`](#monthtotal).
- [`balance_util.dart`](../services/balance_util.md) — `convertCurrency`, used by
  [`_monthTotal`](#monthtotal).
- [`add_transaction_dialog.dart`](../widgets/add_transaction_dialog.md) — the dialog shown by
  [`_addTransaction`](#addtransaction) and `_editTransaction`.
- [`grouped_transaction_list.dart`](../widgets/grouped_transaction_list.md) — `buildGroupedTransactionList`,
  used to render the date-grouped transaction list in `build`.

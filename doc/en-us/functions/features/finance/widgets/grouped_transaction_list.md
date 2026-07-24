# lib/features/finance/widgets/grouped_transaction_list.dart

A tiny shared rendering helper used by every Finance page that shows a flat, date-sorted
transaction list (the account detail page, category detail page, and subscription detail page):
it turns a `List<Transaction>` into a `ListView` with sticky-looking `yyyy-MM-dd` date-header rows
inserted wherever the date changes. See [Finance](../../../../features/finance.md) for the
`Transaction` model this operates on.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`buildGroupedTransactionList`](#buildgroupedtransactionlist) | top-level function | A | Build a `ListView` that groups a sorted transaction list under date-header rows. |

`grep -c 'Purpose:' lib/features/finance/widgets/grouped_transaction_list.dart` reports 1,
matching the single real declaration in this file. No misattachment or undocumented declarations
found.

## Documentation

### `Widget buildGroupedTransactionList(BuildContext context, List<Transaction> sorted, Widget Function(Transaction) tileBuilder)` <a id="buildgroupedtransactionlist"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/widgets/grouped_transaction_list.dart` (line 12)
- **Purpose:** Render a date-sorted list of transactions as a scrollable list with a date-header row
  inserted every time the calendar date changes.
- **Inputs:** `context` — used only to read the current `Theme`; `sorted` — the transactions,
  which the caller must already have sorted so that all transactions sharing a date are
  contiguous (this function does not sort); `tileBuilder` — callback that renders a single
  transaction row, called once per transaction.
- **Returns:** `Widget` — a `ListView.builder` covering both header rows and transaction rows.
- **Side effects:** None beyond building widgets (no state, no I/O).
- **Algorithm:**
  1. Walk `sorted` once, formatting each transaction's `date` as `yyyy-MM-dd` via
     `DateFormat('yyyy-MM-dd')`.
  2. Whenever the formatted date differs from the last date seen, append a header item
     (`isHeader: true, label: dateKey`) to a flat `items` list before appending the transaction
     item itself.
  3. Build a single `ListView.builder` over `items`: header items render as a
     `surfaceContainerLow`-colored padded `Text` in `labelMedium`/`onSurfaceVariant` styling;
     transaction items delegate entirely to `tileBuilder(item.tx!)`.
  4. Because grouping is a single forward pass keyed only on the last-seen date string, a caller
     that passes an unsorted (or multi-date-interleaved) list will get one header per date
     *transition*, not one header per unique date — dates that recur later in the list produce a
     second header.
- **Usage:**
  ```dart
  : buildGroupedTransactionList(context, filtered, (tx) {
      final isExpense = tx.type == TransactionType.expense;
      final isTransfer = tx.type == TransactionType.transfer;
      final sign = isExpense ? '-' : (isTransfer ? '' : '+');
      final color = isExpense ? theme.colorScheme.error : Colors.green;
      final dateStr = DateFormat('MM-dd HH:mm').format(tx.date);
      // ...builds the transaction ListTile...
    })
  ```
  (`lib/features/finance/views/accounts_page.dart`, account detail transaction list; the same
  pattern is repeated in `category_detail_page.dart`, `subscription_detail_page.dart`, and
  `finance_page.dart`.)
- **Notes:** Relies on the caller for sort order — this function has no knowledge of ascending vs.
  descending date order and simply groups whatever contiguous run of same-day transactions it is
  given.

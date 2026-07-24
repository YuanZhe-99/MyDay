# lib/features/finance/views/analysis_page.dart

The Finance feature's analysis/charts view: `AnalysisPage` (the page shell, taking the current
transaction/category/account snapshot and an `onTransactionsChanged` callback so edits made from a
drill-down page propagate back up) and its `_AnalysisPageState`, which owns the year/month/day/custom
time-range selector, a two-tab layout (category pie chart, expense/income/assets trend charts), and
three small private value classes (`_TrendScale`, `_TrendData`, `_ChartSeries`) that carry chart
axis/series data between the trend-computation methods and the chart-rendering methods. Currency
conversion is delegated to [`convertCurrency`/`currencySymbol`](../services/balance_util.md), account
balance reconstruction to
[`accountBalanceBefore`](../services/balance_util.md#accountbalancebefore), and historical/current
rate lookup to [`ExchangeRateData.ratesAt`/`currentRates`](../services/exchange_rate_storage.md) —
none of that logic is reimplemented here. Tapping a category in the pie-chart legend opens
`CategoryDetailPage` for drill-down. See [Finance](../../../../features/finance.md#views-and-analysis-page)
for the concept-level summary of this page's category-breakdown, trend, and total-assets-trend
features.

Despite being a view file, most of the non-widget-returning helpers here carry real computation and
are classified Tier A, per the tiering rule and per this file being called out for "real chart/
breakdown computation logic" — the time-range filtering, the pie-chart category aggregation, the
trend-scale/trend-data construction (including the total-assets-trend reconstruction), and the
`_TrendScale` bucketing helpers. Pure widget-composition methods (`build`, the `_build*` methods that
mainly assemble already-computed values into a widget tree) remain Tier B.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AnalysisPage` (constructor) | constructor (`AnalysisPage`) | B | Create an analysis page instance. |
| `AnalysisPage.createState` | method (`AnalysisPage`) | B | Create the `_AnalysisPageState`. |
| `_AnalysisPageState.initState` | method (`_AnalysisPageState`) | B | Copy the initial transaction list and create the tab controller. |
| [`didUpdateWidget`](#didupdatewidget) | method (`_AnalysisPageState`) | A | Resync local transactions when the parent supplies a new transaction list instance. |
| `_AnalysisPageState.dispose` | method (`_AnalysisPageState`) | B | Dispose the tab controller. |
| [`_filteredTransactions`](#_filteredtransactions) | getter (`_AnalysisPageState`) | A | Filter transactions to the currently selected year/month/day/custom range. |
| [`_filteredCategoryFlowTransactions`](#_filteredcategoryflowtransactions) | getter (`_AnalysisPageState`) | A | Narrow the range-filtered transactions to the selected income/expense flow type. |
| [`_rangeLabel`](#_rangelabel) | method (`_AnalysisPageState`) | A | Format the currently selected time range as a header label. |
| [`_prev`](#_prev) | method (`_AnalysisPageState`) | A | Step the selected year/month/day back by one unit. |
| [`_next`](#_next) | method (`_AnalysisPageState`) | A | Step the selected year/month/day forward by one unit. |
| [`_pickCustomRange`](#_pickcustomrange) | method (`_AnalysisPageState`) | A | Open the date-range picker and store the chosen custom range. |
| `_buildCustomRangeSegmentLabel` | method (widget helper) | B | Render the "Custom range" segment label, tappable for re-editing when already selected. |
| `_buildCategoryTypeSelector` | method (widget helper) | B | Render the expense/income segmented selector for the category tab. |
| [`_openCategoryTransactions`](#_opencategorytransactions) | method (`_AnalysisPageState`) | A | Push the category drill-down page and merge back any transaction edits. |
| `build` | method (`_AnalysisPageState`) | B | Build the scaffold: app bar with tabs, range selector, date navigator, tab view. |
| [`_buildPieChart`](#_buildpiechart) | method (`_AnalysisPageState`) | A | Aggregate filtered transactions into per-category totals and render the pie chart + legend. |
| `_buildTrendChart` | method (widget helper) | B | Render the expense/income trend panel and, if any account exists, the assets-trend panel. |
| [`_buildTrendScale`](#_buildtrendscale) | method (`_AnalysisPageState`) | A | Build the bucket grid (start/step/point count/label format) for the selected time range. |
| [`_buildTrendData`](#_buildtrenddata) | method (`_AnalysisPageState`) | A | Bucket and cumulative-sum all transactions into expense/income/assets chart series. |
| [`_totalAssetsBefore`](#_totalassetsbefore) | method (`_AnalysisPageState`) | A | Reconstruct total assets (in default currency) as of a given instant. |
| `_buildLineChartPanel` | method (widget helper) | B | Render one titled `LineChart` panel (legend + axes + tooltips) for a set of chart series. |
| [`_chartBounds`](#_chartbounds) | method (`_AnalysisPageState`) | A | Compute padded y-axis min/max for a line chart panel. |
| [`_pointCount`](#_pointcount) | method (`_AnalysisPageState`) | A | Compute how many buckets a time span divides into for a given step size. |
| [`_labelInterval`](#_labelinterval) | method (`_AnalysisPageState`) | A | Pick a bucket-index interval that yields roughly 6 x-axis labels. |
| [`_formatAxisValue`](#_formataxisvalue) | method (`_AnalysisPageState`) | A | Format a y-axis value with k/m suffixes for large magnitudes. |
| `_legendDot` | method (widget helper) | B | Render one colored-dot-plus-label chart legend entry. |
| `_TrendScale` (constructor) | constructor (`_TrendScale`) | B | Bundle a chart's bucket grid and label/tooltip formatters. |
| [`bucketIndex`](#bucketindex) | method (`_TrendScale`) | A | Map a date to its bucket index within this scale, or `null` if out of range. |
| [`sampleEnd`](#sampleend) | method (`_TrendScale`) | A | Return the end instant of a given bucket, clipped to the scale's range. |
| `xLabel` | method (`_TrendScale`) | B | Format the x-axis label for a bucket index. |
| `tooltipLabel` | method (`_TrendScale`) | B | Format the tooltip label for a bucket index. |
| `_offset` | method (`_TrendScale`) | B | Compute the instant `steps` buckets after `start`. |
| `_TrendData` (constructor) | constructor (`_TrendData`) | B | Bundle computed expense/income/assets spot lists and y-axis bounds. |
| `_ChartSeries` (constructor) | constructor (`_ChartSeries`) | B | Bundle one chart line's label, color, spots, and fill flag. |

`grep -c 'Purpose:' lib/features/finance/views/analysis_page.dart` reports 33, but the table above
has 34 rows. The discrepancy is one **undocumented real declaration**: `_chartBounds`
(`_AnalysisPageState`, line 1020) has no `/// Purpose:` block at all — the doc comment block ending
just above it (lines 1041-1045, `_pointCount`'s block) sits above the *next* declaration, not this
one, and there is no comment of any kind directly above `_chartBounds` itself. It is a real method
(computes padded axis bounds, called from `_buildLineChartPanel` at line 893) so it is counted as a
declaration here despite being undocumented in source. Every other `/// Purpose:` block was verified
to sit directly above the real declaration it documents — no misattached blocks (a block documenting
a call site rather than a declaration) were found. The `enum _TimeRange` (line 12) and the static
`_chartColors` color palette (lines 1099-1112) are plain data declarations with no behavior and, per
the same convention used for other files in this doc set, are not given table rows.

## Documentation

### `void didUpdateWidget(covariant AnalysisPage oldWidget)` <a id="didupdatewidget"></a>
- **Kind:** method override of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 75)
- **Purpose:** Resync the locally-held `_transactions` copy when the parent widget passes a genuinely
  new transaction list instance, while preserving in-page edits otherwise.
- **Inputs:** `oldWidget` — the previous `AnalysisPage` configuration.
- **Returns:** None.
- **Side effects:** May reassign `_transactions` (not wrapped in `setState`, since this runs during
  the same build pass that already triggered a rebuild).
- **Algorithm:** If `widget.transactions` is not `identical()` to `oldWidget.transactions`, replace
  `_transactions` with a fresh copy (`List.of(widget.transactions)`); otherwise leave `_transactions`
  untouched.
- **Usage:** Invoked automatically by the Flutter framework when `FinancePage` rebuilds `AnalysisPage`
  with new `transactions`/`categories`/`accounts` data (e.g. after a sync or an edit elsewhere) — not
  called directly by any code in this file.
- **Notes:** Because `_openCategoryTransactions`'s callback reassigns `_transactions` locally via
  `setState` (line 302) without also replacing `widget.transactions`, that in-page edit does not
  change the identity of `widget.transactions`, so a subsequent `didUpdateWidget` call triggered by
  an unrelated parent rebuild will not clobber it — only a genuinely new list instance from the
  parent does.

### `List<Transaction> get _filteredTransactions` <a id="_filteredtransactions"></a>
- **Kind:** getter of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 99)
- **Purpose:** Filter `_transactions` down to whichever year/month/day/custom range is currently
  selected.
- **Inputs:** None (reads `_timeRange`, `_selectedMonth`, `_customRange`, `_transactions`).
- **Returns:** `List<Transaction>`.
- **Side effects:** None.
- **Algorithm:** `switch (_timeRange)`: `year` → transactions whose `date.year` matches
  `_selectedMonth.year`; `month` → year and month both match; `day` → year/month/day all match;
  `custom` → `[]` if `_customRange` is unset, otherwise transactions with `date` on/after
  `_customRange.start` and strictly before `_customRange.end + 1 day` (an inclusive end-date bound).
- **Usage:** `_filteredCategoryFlowTransactions` (line 143) is the only reader in this file:
  ```dart
  List<Transaction> get _filteredCategoryFlowTransactions =>
      _filteredTransactions.where((t) => t.type == _categoryFlowType).toList();
  ```
- **Notes:** Only the pie-chart tab (via `_filteredCategoryFlowTransactions`) reads this getter — the
  trend tab's `_buildTrendData` deliberately iterates the *unfiltered* `_transactions` list instead
  and relies on `_TrendScale.bucketIndex` (derived from the same `_timeRange`) to select the relevant
  window, so the two tabs implement range-filtering via two different mechanisms that happen to be
  kept in sync by both reading `_timeRange`/`_selectedMonth`/`_customRange`.

### `List<Transaction> get _filteredCategoryFlowTransactions` <a id="_filteredcategoryflowtransactions"></a>
- **Kind:** getter of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 142)
- **Purpose:** Narrow the range-filtered transactions further to only the selected flow type
  (expense or income) for the category pie-chart tab.
- **Inputs:** None (reads `_filteredTransactions`, `_categoryFlowType`).
- **Returns:** `List<Transaction>`.
- **Side effects:** None.
- **Algorithm:** `_filteredTransactions.where((t) => t.type == _categoryFlowType).toList()`.
- **Usage:** `final categoryTransactions = _filteredCategoryFlowTransactions;` (`_buildPieChart`, line
  424).
- **Notes:** Transfer-type transactions are excluded by construction, since `_categoryFlowType` only
  ever holds `TransactionType.expense` or `TransactionType.income` (set from
  `_buildCategoryTypeSelector`'s two segments).

### `String _rangeLabel(AppLocalizations l10n)` <a id="_rangelabel"></a>
- **Kind:** method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 150)
- **Purpose:** Format the currently selected time range as the header label between the prev/next
  navigator arrows.
- **Inputs:** `l10n`.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** `switch (_timeRange)`: `year` → the bare year number; `month` → `yyyy-MM`; `day` →
  `yyyy-MM-dd`; `custom` → `l10n.financeSelectDateRange` if no range chosen yet, otherwise
  `'MM-dd ~ MM-dd'` built from `_customRange.start`/`.end`.
- **Usage:** `_rangeLabel(l10n)` (`build`, line 383, the tappable label between the chevron/edit
  buttons).
- **Notes:** None.

### `void _prev()` <a id="_prev"></a>
- **Kind:** method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 169)
- **Purpose:** Step the selected year/month/day back by one unit (no-op in custom-range mode).
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** `setState` reassigning `_selectedMonth`.
- **Algorithm:** `switch (_timeRange)`: `year` → `_selectedMonth.year - 1` (same month);
  `month` → `_selectedMonth.month - 1` (`DateTime` normalizes month underflow into the prior year);
  `day` → subtract one calendar day; `custom` → `break` (no-op, since custom mode navigates via the
  date-range picker instead of prev/next).
- **Usage:** `onPressed: _prev` (`build`, line 374, the left chevron `IconButton`, only shown when
  `_timeRange != _TimeRange.custom`).
- **Notes:** None.

### `void _next()` <a id="_next"></a>
- **Kind:** method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 195)
- **Purpose:** Step the selected year/month/day forward by one unit (no-op in custom-range mode).
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** `setState` reassigning `_selectedMonth`.
- **Algorithm:** Mirror image of `_prev`: adds instead of subtracts one year/month/day per
  `_timeRange`; `custom` → no-op.
- **Usage:** `onPressed: _next` (`build`, line 392, the right chevron `IconButton`).
- **Notes:** None.

### `Future<void> _pickCustomRange()` <a id="_pickcustomrange"></a>
- **Kind:** async method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 221)
- **Purpose:** Open the shared app date-range picker and, if the user confirms a selection, store it
  as the custom range.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Shows a date-range picker dialog; on confirmation, `setState` sets `_customRange`.
- **Algorithm:** `await showAppDateRangePicker(...)` seeded with the existing `_customRange` or,
  failing that, "last 30 days through today"; if the result is non-null, `setState(() => _customRange
  = picked)`.
- **Usage:**
  ```dart
  onSelectionChanged: (s) {
    setState(() => _timeRange = s.first);
    if (s.first == _TimeRange.custom && _customRange == null) {
      _pickCustomRange();
    }
  }
  ```
  (`build`, lines 357-361 — auto-opens the picker the first time the user switches into custom mode;
  also wired directly to the label tap and the edit-calendar `IconButton` for re-editing an existing
  custom range, lines 379-381 and 395-398.)
- **Notes:** A cancelled picker (`picked == null`) leaves `_customRange` unchanged, including the case
  where the user switched into custom mode with no prior range — the tab then keeps showing the
  "select a date range" placeholder text until a range is actually chosen.

### `void _openCategoryTransactions(String? categoryId)` <a id="_opencategorytransactions"></a>
- **Kind:** method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 284)
- **Purpose:** Push `CategoryDetailPage` for the tapped pie-chart legend entry (or the uncategorized
  bucket, for a `null` id), and merge back any transaction edits made there.
- **Inputs:** `categoryId` — `null` means the uncategorized-transactions bucket.
- **Returns:** None.
- **Side effects:** Pushes a `MaterialPageRoute`; the pushed page's `onTransactionsChanged` callback
  does `setState` to replace `_transactions` and calls `widget.onTransactionsChanged` to propagate the
  edit back up to `FinancePage`.
- **Algorithm:**
  1. Resolve `category` by looking up `categoryId` in `widget.categories` (`firstOrNull`; stays `null`
     if `categoryId` is `null` or no longer exists).
  2. Push `CategoryDetailPage` with the resolved category, the *current* `_transactions`/
     `widget.categories`/`widget.accounts`/`widget.rateData`/`widget.defaultCurrency`/
     `widget.accountPickerSettings`, and `transactionType: category?.type ?? _categoryFlowType` (falls
     back to the selected tab's flow type when the category can't be resolved, e.g. the uncategorized
     bucket).
  3. On `onTransactionsChanged` from the pushed page: `setState(() => _transactions =
     List.of(transactions))`, then forward the same list to `widget.onTransactionsChanged`.
- **Usage:** `onTap: () => _openCategoryTransactions(e.categoryId)` (`_buildPieChart`, line 587, one
  per legend `ListTile`).
- **Notes:** Because a stale `categoryId` (a category deleted elsewhere) still resolves to `category
  == null` rather than throwing, the drill-down page can still be opened for a since-deleted
  category's leftover transactions — it just can't be pre-populated with that category's own type,
  hence the `_categoryFlowType` fallback.

### `Widget _buildPieChart(BuildContext context)` <a id="_buildpiechart"></a>
- **Kind:** method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 421)
- **Purpose:** Aggregate the selected range's expense or income transactions into per-category
  totals and render the category pie chart plus a tappable legend, including an uncategorized bucket.
- **Inputs:** `context`.
- **Returns:** `Widget`.
- **Side effects:** None directly; the rendered legend rows call `_openCategoryTransactions` on tap.
- **Algorithm:**
  1. If `_filteredCategoryFlowTransactions` is empty, render the type selector plus an empty-state
     message (worded differently for expense vs. other types) and return early.
  2. Group transactions into `catTotals` keyed by `tx.categoryId` (`null` key = uncategorized),
     converting each transaction's `amount` via
     [`convertCurrency`](../services/balance_util.md#convertcurrency) using that transaction's own
     historical rates (`widget.rateData.ratesAt(tx.rateSnapshotId)`) into `widget.defaultCurrency`,
     and summing into the matching bucket.
  3. `total` = sum of all bucket totals.
  4. Assign each bucket a color from the fixed 12-entry `_chartColors` palette by
     `entry.key % colors.length` (colors repeat once there are more than 12 categories); build
     `PieChartSectionData` per bucket with a whole-percent label.
  5. Build parallel `legendEntries` records `(categoryId, name, color, amount, emoji)`, resolving
     `name`/`emoji` from `widget.categories` when the category still exists, else falling back to
     `l10n.financeUncategorized` for the `null`-id bucket (a since-deleted category's raw id is shown
     verbatim rather than resolved, since there is no fallback lookup in that branch).
  6. Render the `PieChart`, a total row (colored green for income, `theme.colorScheme.error` for
     expense), and a scrollable legend list; each legend row's `onTap` calls
     `_openCategoryTransactions(e.categoryId)`.
- **Usage:** `_buildPieChart(context)` (`build`, line 406, as one of the two `TabBarView` children).
- **Notes:** Bucket iteration order (and thus color assignment) follows `Map` insertion order, i.e.
  the order categories were first encountered while looping `categoryTransactions` — not a fixed
  category order, so which color a given category gets can vary across renders if the underlying
  transaction order changes. See
  [Finance](../../../../features/finance.md#views-and-analysis-page) for how this fits the
  "clickable expense/income category breakdowns including uncategorized flows" feature.

### `_TrendScale _buildTrendScale()` <a id="_buildtrendscale"></a>
- **Kind:** method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 686)
- **Purpose:** Build the bucket grid (start instant, bucket step, bucket count, label interval, and
  date-label/tooltip formatters) that both trend charts sample against, sized appropriately for the
  currently selected time range.
- **Inputs:** None (reads `_timeRange`, `_selectedMonth`, `_customRange`).
- **Returns:** `_TrendScale`.
- **Side effects:** None.
- **Algorithm:** `switch (_timeRange)`:
  1. `year` — one bucket per day (`Duration(days: 1)`) across the calendar year; labels/tooltips as
     `M/d` / `yyyy-MM-dd`.
  2. `month` — one bucket per hour across the calendar month; labels as `M/d`, tooltips as
     `yyyy-MM-dd HH:00`.
  3. `day` — one bucket per hour across the single day; labels as `"${hour}h"` (a bespoke closure, not
     `DateFormat`), fixed `labelInterval: 4`; tooltips as `yyyy-MM-dd HH:00`.
  4. `custom` — bucket step depends on the range's total length: `<= 48h` → hourly; `<= 45 days` →
     6-hourly; otherwise daily. Tooltip format switches to the day-only format once the step reaches a
     full day (`step.inHours >= 24`).
  5. In every branch, `pointCount` comes from [`_pointCount`](#_pointcount) and (except the `day`
     branch's fixed value) `labelInterval` from [`_labelInterval`](#_labelinterval).
- **Usage:** `final scale = _buildTrendScale();` (`_buildTrendChart`, line 618, then passed into
  `_buildTrendData` and both `_buildLineChartPanel` calls so the flow and assets panels share one
  bucket grid).
- **Notes:** The `day` range's `labelForDate` closure bypasses `DateFormat` entirely
  (`'${date.hour}h'`), unlike every other range, which is why its `labelInterval` is hardcoded to `4`
  rather than computed — an hourly `DateFormat` pattern would need locale handling that the closure
  form doesn't.

### `_TrendData _buildTrendData(_TrendScale scale)` <a id="_buildtrenddata"></a>
- **Kind:** method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 776)
- **Purpose:** Bucket every transaction into the given scale's grid, run cumulative sums to build
  expense/income trend lines, and separately sample total assets at each bucket boundary to build the
  assets-trend line.
- **Inputs:** `scale` — from [`_buildTrendScale`](#_buildtrendscale).
- **Returns:** `_TrendData` bundling `expenseSpots`/`incomeSpots`/`assetSpots` (`List<FlSpot>`) and
  `flowMaxY`/`assetMinY`/`assetMaxY` axis bounds.
- **Side effects:** None.
- **Algorithm:**
  1. Allocate `expense`/`income` arrays of length `scale.pointCount`, zero-filled.
  2. For every transaction in `_transactions` (the **unfiltered** full list, not
     [`_filteredTransactions`](#_filteredtransactions)): find its bucket via
     `scale.bucketIndex(tx.date)`; skip if `null` (outside the scale's window). Convert `tx.amount` via
     `convertCurrency` using that transaction's own historical rate snapshot into
     `widget.defaultCurrency`, then add it into `expense[idx]` or `income[idx]` depending on
     `tx.type` (transfers contribute to neither).
  3. Turn per-bucket deltas into running totals: for `i` from `1` to `pointCount - 1`,
     `expense[i] += expense[i-1]` (and same for `income`) — so each array becomes a cumulative
     expense/income trend across the period rather than a per-bucket amount.
  4. Build `assets` by sampling [`_totalAssetsBefore`](#_totalassetsbefore) at `scale.sampleEnd(i)` for
     every bucket index `i` — this is the total-assets-trend reconstruction described in
     [Finance](../../../../features/finance.md#views-and-analysis-page).
  5. `flowMaxY` = the max value across the combined cumulative expense+income arrays (used to anchor
     the flow chart's y-axis at zero). `assetMinY`/`assetMaxY` = min/max across `assets` (not anchored
     to zero).
  6. Wrap each array into `FlSpot(i, value)` lists and return a `_TrendData`.
- **Usage:** `final trendData = _buildTrendData(scale);` (`_buildTrendChart`, line 619; `flowMaxY`/
  `assetMinY`/`assetMaxY` are then used to decide whether each panel has data worth showing at all).
- **Notes:** Iterating the unfiltered `_transactions` (rather than the range-filtered getter) is
  intentional: `scale.bucketIndex` already restricts which transactions land in a visible bucket, so
  filtering separately would be redundant — but it does mean a transaction whose date sits outside
  `[start, endExclusive)` for a reason other than the current time-range selection (e.g. a transaction
  dated far in the future) is silently skipped rather than erroring.

### `double _totalAssetsBefore(DateTime before)` <a id="_totalassetsbefore"></a>
- **Kind:** method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 836)
- **Purpose:** Compute total assets, converted into `widget.defaultCurrency`, as of a given instant —
  the sample function behind the assets-trend line.
- **Inputs:** `before` — the instant to reconstruct assets as of (exclusive: only transactions
  strictly before it count).
- **Returns:** `double`.
- **Side effects:** None.
- **Algorithm:** Two paths depending on whether any accounts exist:
  1. **No accounts** (`widget.accounts.isEmpty`): fold over every transaction dated before `before`,
     converting each via `convertCurrency` with that transaction's own historical rate snapshot into
     `widget.defaultCurrency`; expense subtracts, income adds, transfer is skipped (transfers move
     money between accounts without changing total net worth). This mirrors the transaction-only
     total used before an account list exists.
  2. **With accounts:** for each account, call
     [`accountBalanceBefore(account, _transactions, widget.rateData, before)`](../services/balance_util.md#accountbalancebefore)
     (which itself reconstructs the account's balance from transactions, honoring any legacy
     forced-balance anchor — see [Finance](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)),
     then convert that balance into `widget.defaultCurrency` using **`widget.rateData.currentRates`**
     (today's rates, not a historical snapshot), and sum across accounts.
- **Usage:** `(i) => _totalAssetsBefore(scale.sampleEnd(i))` (`_buildTrendData`, line 805, once per
  bucket).
- **Notes:** The two paths use different rate sources: the no-accounts fallback uses each
  transaction's own historical rate snapshot, while the with-accounts path converts the reconstructed
  balance using **current** rates rather than a rate snapshot from `before`. This means the
  with-accounts assets-trend line reflects what each historical balance would be worth in today's
  exchange rates, not what it was worth on that date — a real (if subtle) distortion for
  multi-currency accounts whose exchange rate has since moved.

### `({double minY, double maxY}) _chartBounds(double minY, double maxY, {required bool anchorZero})` <a id="_chartbounds"></a>
- **Kind:** method of `_AnalysisPageState` (undocumented in source — no `/// Purpose:` block; see the
  reconciliation note above the Declarations table)
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 1020)
- **Purpose:** Compute a padded y-axis range for a line chart panel, either anchored at zero (the flow
  chart) or floating around the data (the assets chart).
- **Inputs:** `minY`/`maxY` — the raw data bounds; `anchorZero` — whether the low bound must be `0`.
- **Returns:** A `(minY, maxY)` record — the padded axis bounds.
- **Side effects:** None.
- **Algorithm:**
  1. If `minY == maxY` (flat data): `padding = minY.abs() * 0.1`, falling back to `1.0` if that
     computes to `0` (so an all-zero series still gets a visible band); return `(0, maxY + padding)`
     if `anchorZero`, else `(minY - padding, maxY + padding)`.
  2. Otherwise: `padding = (maxY - minY).abs() * 0.1`; same anchor-zero branch as above.
- **Usage:** `final bounds = _chartBounds(minY, maxY, anchorZero: anchorZero);` (`_buildLineChartPanel`,
  line 893 — called with `anchorZero: true` for the expense/income flow panel and `anchorZero: false`
  for the assets panel, per the two `_buildLineChartPanel` call sites in `_buildTrendChart`).
- **Notes:** `anchorZero: false` (the assets panel) is what lets the total-assets-trend line show
  relative movement clearly even when the absolute balance never approaches zero — pinning it to zero
  the way the flow panel is pinned would compress small fluctuations into a flat-looking line.

### `int _pointCount(DateTime start, DateTime end, Duration step)` <a id="_pointcount"></a>
- **Kind:** method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 1046)
- **Purpose:** Compute how many buckets of size `step` are needed to cover `[start, end)`.
- **Inputs:** `start`, `end`, `step`.
- **Returns:** `int` — at least `1`.
- **Side effects:** None.
- **Algorithm:** Ceiling-divide the total microsecond span by `step`'s microsecond length:
  `(total + stepMicros - 1) ~/ stepMicros`; clamp up to `1` if the result would be `0` (or negative).
- **Usage:** `final pointCount = _pointCount(start, end, step);` (`_buildTrendScale`, called once per
  `_timeRange` branch, e.g. line 696).
- **Notes:** None.

### `double _labelInterval(int pointCount)` <a id="_labelinterval"></a>
- **Kind:** method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 1058)
- **Purpose:** Pick a bucket-index interval between x-axis labels that yields roughly 6 visible
  labels regardless of how many buckets there are.
- **Inputs:** `pointCount`.
- **Returns:** `double` — at least `1`.
- **Side effects:** None.
- **Algorithm:** `interval = (pointCount / 6).ceil()`, floored to `1` if smaller.
- **Usage:** `labelInterval: _labelInterval(pointCount)` (`_buildTrendScale`, e.g. line 702; the `day`
  range branch uses a hardcoded `4` instead, see notes on
  [`_buildTrendScale`](#_buildtrendscale)).
- **Notes:** None.

### `String _formatAxisValue(double value)` <a id="_formataxisvalue"></a>
- **Kind:** method of `_AnalysisPageState`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 1068)
- **Purpose:** Format a y-axis label compactly, using `k`/`m` suffixes for large magnitudes.
- **Inputs:** `value`.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** `abs = value.abs()`; if `abs >= 1_000_000` → `"${sign}${(abs/1e6).toStringAsFixed(1)}m"`;
  else if `abs >= 1000` → `"${sign}${(abs/1000).toStringAsFixed(1)}k"`; else the value rounded to a
  whole number via `toStringAsFixed(0)`. `sign` is `'-'` for negative values (applied to the already
  `abs`-computed magnitude), otherwise empty.
- **Usage:** `_formatAxisValue(value)` (`_buildLineChartPanel`, line 968, the left-axis tick label
  builder).
- **Notes:** None.

### `int? bucketIndex(DateTime date)` <a id="bucketindex"></a>
- **Kind:** method of `_TrendScale`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 1144)
- **Purpose:** Map a date to its bucket index within this scale's grid, or `null` if it falls outside
  `[start, endExclusive)` or would round to an out-of-range index.
- **Inputs:** `date`.
- **Returns:** `int?`.
- **Side effects:** None.
- **Algorithm:** Guard `date.isBefore(start) || !date.isBefore(endExclusive)` → `null`; else
  `idx = date.difference(start).inMicroseconds ~/ step.inMicroseconds`; guard `idx < 0 || idx >=
  pointCount` → `null`; else return `idx`.
- **Usage:** `final idx = scale.bucketIndex(tx.date);` (`_buildTrendData`, line 781, the per-transaction
  bucketing step).
- **Notes:** The second bounds check (`idx >= pointCount`) is a defensive guard against integer
  rounding pushing an in-range date's index just past the last bucket; combined with the first guard
  it should not normally trigger, but protects `_buildTrendData`'s fixed-length arrays from an
  out-of-bounds write.

### `DateTime sampleEnd(int index)` <a id="sampleend"></a>
- **Kind:** method of `_TrendScale`
- **Source:** `lib/features/finance/views/analysis_page.dart` (line 1156)
- **Purpose:** Return the end instant of bucket `index` (i.e. the point in time up to which that
  bucket's cumulative data should be reconstructed), clipped to the scale's overall end.
- **Inputs:** `index`.
- **Returns:** `DateTime`.
- **Side effects:** None.
- **Algorithm:** `end = _offset(index + 1)` (the start of the *next* bucket); return `endExclusive` if
  `end` would overshoot it, else `end`.
- **Usage:** `(i) => _totalAssetsBefore(scale.sampleEnd(i))` (`_buildTrendData`, line 805) — each
  asset-trend sample point is taken at the end of its bucket, not the start.
- **Notes:** The clip to `endExclusive` matters for the very last bucket, whose nominal end
  (`_offset(pointCount)`) could otherwise land exactly on or past the scale's boundary depending on
  rounding in `_pointCount`.

## Related pages

- [Finance](../../../../features/finance.md#views-and-analysis-page) — concept-level description of
  the category breakdowns, trends, and total-assets-trend reconstruction this page implements.
- [`convertCurrency`/`currencySymbol`/`accountBalanceBefore`](../services/balance_util.md) — currency
  conversion and account-balance reconstruction used throughout `_buildPieChart`, `_buildTrendData`,
  and `_totalAssetsBefore`.
- [`ExchangeRateData.ratesAt`/`currentRates`](../services/exchange_rate_storage.md) — historical vs.
  current rate lookup, whose distinction underlies the Notes on `_totalAssetsBefore`.
- [`Transaction`/`Category`/`Account`/`AccountPickerSettings`](../models/finance.md) — the model types
  this page reads but does not mutate directly (mutations flow back through
  `onTransactionsChanged`/`_openCategoryTransactions`).

# lib/features/finance/views/finance_page.dart

The Finance tab's home page: a month-selectable summary (expense/income/total assets, with a
currency-conversion-fallback warning), an upcoming-renewals strip, and the grouped list of the
selected month's transactions, with swipe-to-edit/delete and a floating add button. The app bar's
overflow actions are the entry points into every other Finance sub-page (accounts, analysis,
subscriptions, categories, exchange rates, default currency). See
[Finance](../../../../features/finance.md#views-and-analysis-page) for how this page fits into the
selectable-month home summaries and grouped monthly transactions described there.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `FinancePage({super.key})` | constructor (`FinancePage`) | B | Create a finance page instance. |
| `createState` | method (`FinancePage`) | B | Create the mutable state object for this widget. |
| `initState` | method (`_FinancePageState`) | B | Register renewal/auto-sync listeners, seed the selected month to the current month, and trigger the first load. |
| `dispose` | method (`_FinancePageState`) | B | Unregister the renewal and auto-sync listeners. |
| [`_loadData`](#_loaddata) | method (`_FinancePageState`) | A | Load finance and exchange-rate data from disk into state, or record a load error. |
| [`_processSubscriptions`](#_processsubscriptions) | method (`_FinancePageState`) | A | Auto-generate transactions for subscriptions with overdue billing dates. |
| [`_getUpcomingSubs`](#_getupcomingsubs) | method (`_FinancePageState`) | A | List subscriptions billing within N days, sorted by billing date. |
| [`_saveData`](#_savedata) | method (`_FinancePageState`) | A | Persist finance state to disk, refusing to save while the loaded file is unreadable. |
| `_updateReminderService` | method (`_FinancePageState`) | B | Push current subscription/reminder-time state to `ReminderService`. |
| `_addTransaction` | method (`_FinancePageState`) | B | Open the add-transaction dialog and insert the result at the front of the list. |
| `_deleteTransaction` | method (`_FinancePageState`) | B | Remove a transaction from state and save. |
| `_editTransaction` | method (`_FinancePageState`) | B | Open the edit dialog and replace the transaction in state. |
| [`_pickFlowMonth`](#_pickflowmonth) | method (`_FinancePageState`) | A | Show the year/month picker dialog that selects the home flow's filter month. |
| [`build`](#build) | method (`_FinancePageState`) | A | Compute the selected month's expense/income/total-assets summary (with missing-rate tracking) and render the home page. |
| `_pickDefaultCurrency` | method (`_FinancePageState`) | B | Show a currency picker and update the app's default currency. |
| `_openAccounts` | method (`_FinancePageState`) | B | Push the accounts page, wiring its change/sort callbacks back into state. |
| `_openAnalysis` | method (`_FinancePageState`) | B | Push the analysis page. |
| `_openSubscriptions` | method (`_FinancePageState`) | B | Push the subscriptions page, wiring its change/reminder/sort callbacks back into state. |
| `_showFinanceMenu` | method (`_FinancePageState`) | B | Show the bottom-sheet menu for categories, exchange rates, and default currency. |
| `_FinanceDataError({...})` | constructor (`_FinanceDataError`) | B | Create a finance-data-error view instance. |
| `build` | method (`_FinanceDataError`) | B | Render the blocking "finance data unreadable" error view with a retry button. |
| `_SummaryHeader({...})` | constructor (`_SummaryHeader`) | B | Create a summary header instance. |
| `build` | method (`_SummaryHeader`) | B | Render the month-navigation row, expense/income cards, total-assets card, and missing-rate warning. |
| `_SummaryCard({...})` | constructor (`_SummaryCard`) | B | Create a summary card instance. |
| `build` | method (`_SummaryCard`) | B | Render one labeled icon/value stat card. |
| `_TransactionTile({...})` | constructor (`_TransactionTile`) | B | Create a transaction tile instance. |
| `build` | method (`_TransactionTile`) | B | Render one transaction's list tile (category/account labels, signed amount). |
| `_buildLeading` | method (`_TransactionTile`, widget helper) | B | Build the tile's leading avatar (resolved account image, or a fallback icon). |
| `defaultAvatar` (nested in `_buildLeading`) | local function (widget helper) | B | Build the fallback finance transaction avatar. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/views/finance_page.dart` returns 29,
matching the 29 rows above exactly — every block sits immediately above its real declaration (a
constructor, `createState`, a lifecycle method, a private method, a `build` override, or the nested
local function inside `_buildLeading`); none were found misattached above a call-site statement,
and no undocumented real declaration was found. The four classes' plain widget fields (e.g.
`_FinancePageState`'s `_accounts`/`_categories`/`_transactions`/... state fields, and the
`StatelessWidget` subclasses' constructor parameters) carry no `/// Purpose:` block, consistent with
this codebase's convention of documenting callable members rather than data fields.

## Documentation

### `Future<void> _loadData()` <a id="_loaddata"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 96-137)
- **Purpose:** Load finance data and exchange-rate data from disk into state, or record a load
  error so existing-but-unreadable data is surfaced instead of silently treated as empty.
- **Inputs:** None (reads `FinanceStorage.load()` and `ExchangeRateStorage.load()`).
- **Returns:** `Future<void>`.
- **Side effects:** Sets nearly every state field on success (`_accounts`, `_categories`,
  `_transactions`, `_subscriptions`, `_defaultCurrency`, subscription reminder hour/minute/sort
  mode/custom order, account sort modes/custom orders, `_accountPickerSettings`,
  `_settingsModifiedAt`, `_rateData`, `_loaded`); on a read failure sets `_loadError` and returns
  early instead. Always calls `_updateReminderService()` afterward, and `_processSubscriptions()`
  if any subscriptions exist.
- **Algorithm:**
  1. Call `FinanceStorage.load()`
     ([`finance_storage.md#load`](../services/finance_storage.md#load)) inside a `try`/`catch`. If
     it throws, and the widget is still `mounted`, set `_loadError = e.toString()` and
     `_loaded = true`, then return — no other field is touched, so a load failure never clobbers
     previously-displayed data.
  2. Otherwise call `ExchangeRateStorage.load()`
     ([`exchange_rate_storage.md#load`](../services/exchange_rate_storage.md#load)).
  3. Inside `setState`, clear `_loadError`. If `data` is non-null, copy every field off it into the
     corresponding state field — `_accountSortModes` and `_accountCustomOrders` are deep-copied via
     `Map.of`/`List<String>.of` rather than aliased. Always assign `_rateData = rateData` and
     `_loaded = true`.
  4. Call `_updateReminderService()` unconditionally.
  5. If `_subscriptions.isNotEmpty`, call [`_processSubscriptions`](#_processsubscriptions) to
     generate any overdue billing transactions.
- **Usage:**
  ```dart
  ReminderService.instance.onRenewalsProcessed = _loadData;
  _loadData();
  AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  ```
  Also used as `_FinanceDataError(message: _loadError!, onRetry: _loadData)`'s retry callback.
- **Notes:** Because a caught read error returns before resetting `_accounts`/`_transactions`/etc.,
  a transient read failure after a successful earlier load still shows the last-good in-memory
  data underneath the blocking `_FinanceDataError` view rather than blanking it — though the error
  view is what actually renders in that state (see `build`).

### `void _processSubscriptions()` <a id="_processsubscriptions"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 145-154)
- **Purpose:** For each active subscription, generate transactions for any billing dates that have
  passed since the app last processed renewals.
- **Inputs:** None (reads `_subscriptions`, `_transactions`).
- **Returns:** None.
- **Side effects:** If billing generated changes, updates `_subscriptions` and appends the new
  transactions to `_transactions` via `setState`, then calls [`_saveData`](#_savedata) to persist.
- **Algorithm:** Delegates entirely to
  `SubscriptionProcessor.process(_subscriptions, _transactions)`
  ([`subscription_processor.md#process`](../services/subscription_processor.md#process)) — see
  [Subscription Billing](../../../../algorithms/subscription-billing.md) for the month-end
  clamping and idempotent billing-day generation this performs. If `result.changed`, replace
  `_subscriptions` with `result.subs` and append `result.txs` to `_transactions`.
- **Usage:**
  ```dart
  if (_subscriptions.isNotEmpty) {
    _processSubscriptions();
  }
  ```
  Also called from the subscriptions page's `onSubscriptionsChanged` callback (wired up in
  `_openSubscriptions`, after any subscription edit) so a changed billing cycle is caught up
  immediately rather than waiting for the next load.
- **Notes:** Safe to call repeatedly — `SubscriptionProcessor.process` recognizes both random-id
  (legacy) and stable-id (current) billing transactions, so re-running it never double-bills a day.

### `List<(Subscription, DateTime)> _getUpcomingSubs(int days)` <a id="_getupcomingsubs"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 162-180)
- **Purpose:** Return subscriptions whose next billing date falls within `days` days from today,
  oldest first, for the home page's "upcoming renewals" strip.
- **Inputs:** `days` — the look-ahead window size.
- **Returns:** `List<(Subscription, DateTime)>` — each tuple pairs a subscription with its
  `nextBillingDate`.
- **Side effects:** None.
- **Algorithm:**
  1. Compute `today` (date-only, from `DateTime.now()`) and `limit = today + Duration(days: days)`.
  2. For each subscription: skip it if `cancelType == CancelType.atExpiry` (at-expiry cancellations
     keep appearing in subscription lists but are excluded from renewal reminders); also skip it if
     `!isActive && cancelType == CancelType.immediate`.
  3. If the subscription's `nextBillingDate` is non-null and its date-only form is not after
     `limit`, add `(sub, next)` to the result.
  4. Sort the result ascending by billing date and return it.
- **Usage:**
  ```dart
  // Upcoming renewals (within 3 days)
  final upcomingSubs = _getUpcomingSubs(3);
  ```
  (called inside `build`, feeding the horizontal `Chip` strip shown above the transaction list).
- **Notes:** An identically-named, independently implemented `_getUpcomingSubs` exists in
  `subscriptions_page.dart` with the same exclusion rules but a longer look-ahead window used for
  that page's own upcoming-renewals section — the two are not shared code.

### `Future<void> _saveData()` <a id="_savedata"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 188-220)
- **Purpose:** Persist the current in-memory finance state to disk, refusing to write while the
  loaded file is known to be unreadable.
- **Inputs:** None (reads every persisted state field).
- **Returns:** `Future<void>`.
- **Side effects:** Either shows a `financeDataWriteBlocked` snack bar and returns (no write), or
  calls `FinanceStorage.save(...)`
  ([`finance_storage.md#save`](../services/finance_storage.md#save)), then
  `AutoSyncService.instance.notifySaved()` and `_updateReminderService()`.
- **Algorithm:**
  1. If `_loadError != null`, and the widget is `mounted`, show a `SnackBar` with
     `l10n.financeDataWriteBlocked` and return — this stops a corrupted-on-disk finance file from
     being overwritten by whatever (empty or stale) in-memory state resulted from the failed load.
  2. Otherwise, build a `FinanceData` from every current state field and call
     `FinanceStorage.save(...)`.
  3. Call `AutoSyncService.instance.notifySaved()` so the auto-sync scheduler knows local data
     changed.
  4. Call `_updateReminderService` to keep `ReminderService` in sync with whatever was just saved.
- **Usage:**
  ```dart
  void _deleteTransaction(Transaction tx) {
    setState(() {
      _transactions.removeWhere((t) => t.id == tx.id);
    });
    _saveData();
  }
  ```
  Called after essentially every mutation in this file (`_addTransaction`, `_deleteTransaction`,
  `_editTransaction`, `_processSubscriptions`, `_pickDefaultCurrency`, and the `onChanged`/
  `onSortChanged`/`onReminderChanged`/`onAccountPickerSettingsChanged` callbacks passed to the
  accounts/analysis/subscriptions/categories sub-pages).
- **Notes:** The write-block guard means a genuinely broken finance file can only be fixed outside
  the app (or by whatever recovery `FinanceStorage`/`_FinanceDataError`'s retry offers) — the UI
  will never silently replace it with empty data.

### `Future<void> _pickFlowMonth()` <a id="_pickflowmonth"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 300-369)
- **Purpose:** Let the user pick the year and month that filters the home page's transaction flow
  and summary cards.
- **Inputs:** None (reads `context`, `_selectedFlowMonth`).
- **Returns:** `Future<void>`.
- **Side effects:** Opens a dialog; on confirmation, updates `_selectedFlowMonth` via `setState`.
- **Algorithm:**
  1. Show an `AlertDialog` built with a `StatefulBuilder` holding a dialog-local `year` variable
     seeded from `_selectedFlowMonth.year`.
  2. Render chevron buttons that increment/decrement the dialog-local `year` (via
     `setDialogState`, not the page's own `setState`).
  3. Render a `Wrap` of 12 `ChoiceChip`s, one per month, labeled with `DateFormat.MMM(l10n.localeName)`
     and marked selected when both `year` and `month` match `_selectedFlowMonth`.
  4. Tapping a chip pops the dialog with `DateTime(year, month)`.
  5. If the dialog returned non-null, set `_selectedFlowMonth = DateTime(picked.year, picked.month)`
     — the day is always normalized to the 1st.
- **Usage:**
  ```dart
  _SummaryHeader(
    ...
    onPickMonth: _pickFlowMonth,
  ),
  ```
  (`_SummaryHeader.build` wires this to the month label's `TextButton.icon`.)
- **Notes:** The dialog only ever stores a year/month pair — there is no day-level filtering
  anywhere in this flow; `_selectedFlowMonth`'s day component is always `1` (the constructor
  argument list omits `day`, which defaults to `1`).

### `Widget build(BuildContext context)` <a id="build"></a>
- **Kind:** method of `_FinancePageState` (`@override` of `State.build`)
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 377-659)
- **Purpose:** Compute the selected month's expense/income/total-assets summary — tracking any
  currency pairs that fell back to a 1:1 conversion — and render the Finance home page: app bar,
  summary header, upcoming-renewals strip, and the grouped, swipeable transaction list.
- **Inputs:** `context`.
- **Returns:** The widget tree for the current state (loading spinner, blocking error view, or the
  full home page).
- **Side effects:** None directly (a pure render given current state), though it wires callbacks
  (month navigation, dismiss-to-edit/delete, menu actions) that mutate state when later invoked.
- **Algorithm:**
  1. Compute `monthLabel` (`'yyyy-MM'` of `_selectedFlowMonth`) and `currentRates` (today's rates,
     via `_rateData.currentRates` —
     [`exchange_rate_storage.md#currentrates`](../services/exchange_rate_storage.md#currentrates)).
  2. Derive `startOfMonth`/`startOfNextMonth` from `_selectedFlowMonth` and filter `_transactions`
     into `monthTransactions`: `date >= startOfMonth && date < startOfNextMonth`.
  3. Declare a `missingRatePairs` set and a `trackMissingRate(from, to)` closure that records
     `'$from→$to'`; this is passed as `onMissingRate` to every `convertCurrency` call below, so any
     silent 1:1 fallback is surfaced instead of distorting totals unnoticed.
  4. `monthExpense`: fold `monthTransactions` where `type == expense`, converting each transaction
     via `convertCurrency(_rateData.ratesAt(t.rateSnapshotId), t.amount, t.currency,
     _defaultCurrency, onMissingRate: trackMissingRate)`
     ([`balance_util.md#convertcurrency`](../services/balance_util.md#convertcurrency)) — i.e. at
     the exchange-rate snapshot in effect on that transaction's own date.
  5. `monthIncome`: the same fold, filtered to `type == income`.
  6. `totalAssets`: if `_accounts` is empty, fall back to `monthIncome - monthExpense`; otherwise
     fold over `_accounts`, computing each account's balance via `accountBalance(a, _transactions,
     _rateData)` ([`balance_util.md#accountbalance`](../services/balance_util.md#accountbalance))
     and converting it to `_defaultCurrency` using **today's** `currentRates` — unlike the
     per-transaction snapshot rates used for `monthExpense`/`monthIncome`.
  7. Compute `upcomingSubs = _getUpcomingSubs(3)`.
  8. Build a `Scaffold` with an `AppBar` (accounts/analysis/subscriptions/overflow-menu actions,
     all disabled when `_loadError != null`) and a body that is: a spinner while `!_loaded`; the
     `_FinanceDataError` view while `_loadError != null`; otherwise a `Column` of
     `_SummaryHeader` (fed the computed totals, `missingRatePairs.toList()..sort()`, and
     prev/next-month callbacks that shift `_selectedFlowMonth` by one month), an optional upcoming
     renewals `Chip` strip, a "Transactions" section label, and either an empty-state message or
     `buildGroupedTransactionList`
     ([`grouped_transaction_list.md#buildgroupedtransactionlist`](../widgets/grouped_transaction_list.md#buildgroupedtransactionlist))
     fed `monthTransactions` sorted newest-first, each row wrapped in a `Dismissible` (swipe
     start-to-end opens edit; swipe end-to-start asks for delete confirmation via
     `confirmDelete`).
  9. A `FloatingActionButton` triggers `_addTransaction`, disabled when `_loadError != null`.
- **Usage:** Invoked by the Flutter framework whenever `_FinancePageState` rebuilds; not called
  directly. `FinancePage` itself is mounted from the router:
  ```dart
  builder: (context, state) => const FinancePage(),
  ```
  (`lib/app/router.dart`).
- **Notes:** The month-boundary filter (`monthTransactions`) uses per-transaction historical rates
  for the flow totals but current rates for the total-assets card — this is intentional: expense/
  income for a past month should reflect what things cost in that month's terms, while total assets
  is "what are they worth right now."

## Related pages

- [Finance](../../../../features/finance.md) — model field reference and how this page's
  selectable-month summary and grouped transaction list fit the wider Finance feature.
- [Subscription Billing](../../../../algorithms/subscription-billing.md) — the catch-up algorithm
  [`_processSubscriptions`](#_processsubscriptions) delegates to via `SubscriptionProcessor.process`.
- [`balance_util.dart`](../services/balance_util.md) — `convertCurrency`, `accountBalance`, used by
  [`build`](#build) for the summary totals.
- [`finance_storage.md`](../services/finance_storage.md) — `load`/`save`, used by
  [`_loadData`](#_loaddata) and [`_saveData`](#_savedata).
- [`exchange_rate_storage.md`](../services/exchange_rate_storage.md) — `load`, `currentRates`,
  `ratesAt`, used by [`_loadData`](#_loaddata) and [`build`](#build).
- [`grouped_transaction_list.dart`](../widgets/grouped_transaction_list.md) —
  `buildGroupedTransactionList`, used to render the date-grouped transaction list in
  [`build`](#build).
- [`add_transaction_dialog.dart`](../widgets/add_transaction_dialog.md) — the dialog shown by
  `_addTransaction` and `_editTransaction`.
- [`reminder_service.md`](../../../shared/services/reminder_service.md) — `updateSubscriptionData`,
  kept in sync by `_updateReminderService`.
- [`auto_sync_service.md`](../../../shared/services/auto_sync_service.md) —
  `addOnLocalDataChanged`/`notifySaved`, used by `initState`/[`_saveData`](#_savedata).

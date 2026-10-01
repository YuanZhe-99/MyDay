# lib/features/finance/views/finance_page.dart

The Finance tab's home page: a month-selectable summary (expense/income/total assets, with a
currency-conversion-fallback warning), an upcoming-renewals strip, and the grouped list of the
selected month's transactions, with swipe-to-edit/delete and a floating add button. Since v1.4.3
the two-pane arrangement also fills the summary pane with a subscription overview — the three
subscription statistics and the active list — drawn from
[`subscription_summary.dart`](../services/subscription_summary.md). Since v1.5.0
the summary also carries the on-device AI insight card
([`AiInsightCard`](../../ai/widgets/ai_insight_card.md), see
[On-device AI](../../../../on-device-ai.md#insight-cards)), in both arrangements. The app bar's
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
| [`_io`](#_io) | method (`_FinancePageState`) | A | Run one finance load, save, or sub-page commit after the previous one (the page's serial I/O queue, v1.5.2). |
| `_applyFinanceData` | method (`_FinancePageState`) | B | Copy a loaded or merged `FinanceData` into the page's state fields (callers wrap it in `setState`). |
| `_currentFinanceData` | method (`_FinancePageState`) | B | Snapshot the page's current finance state as a `FinanceData`. |
| [`_loadData`](#_loaddata) | method (`_FinancePageState`) | A | Enqueue a reload of finance data and exchange rates on the I/O queue. |
| [`_loadDataNow`](#_loaddatanow) | method (`_FinancePageState`) | A | Body of `_loadData`: load finance and exchange-rate data into state, or record a load error. |
| [`_processSubscriptions`](#_processsubscriptions) | method (`_FinancePageState`) | A | Auto-generate transactions for subscriptions with overdue billing dates. |
| `_showWriteBlocked` | method (`_FinancePageState`) | B | Show the `financeDataWriteBlocked` snack bar when mounted. |
| [`_saveData`](#_savedata) | method (`_FinancePageState`) | A | Enqueue a save of the page's in-memory finance state on the I/O queue. |
| [`_saveDataNow`](#_savedatanow) | method (`_FinancePageState`) | A | Body of `_saveData`: persist finance state, refusing while the loaded file is unreadable. |
| [`_commitSubPage`](#_commitsubpage) | method (`_FinancePageState`) | A | Merge one sub-page callback's list edits by id into the freshly re-read file and save (v1.5.2). |
| `_updateReminderService` | method (`_FinancePageState`) | B | Push current subscription/reminder-time state to `ReminderService`. |
| `_addTransaction` | method (`_FinancePageState`) | B | Open the add-transaction dialog and insert the result at the front of the list. |
| `_deleteTransaction` | method (`_FinancePageState`) | B | Remove a transaction from state and save. |
| `_editTransaction` | method (`_FinancePageState`) | B | Open the edit dialog and replace the transaction in state. |
| [`_pickFlowMonth`](#_pickflowmonth) | method (`_FinancePageState`) | A | Show the year/month picker dialog that selects the home flow's filter month. |
| [`build`](#build) | method (`_FinancePageState`) | A | Compute the selected month's expense/income/total-assets summary (with missing-rate tracking) and render the home page. |
| `_pickDefaultCurrency` | method (`_FinancePageState`) | B | Show a currency picker and update the app's default currency. |
| `_openAccounts` | method (`_FinancePageState`) | B | Push the accounts page; account and transaction edits commit merge-by-id through `_commitSubPage`, sort and picker settings through `_saveData`. |
| `_openAnalysis` | method (`_FinancePageState`) | B | Push the analysis page; transaction edits commit merge-by-id through `_commitSubPage`. |
| `_openSubscriptions` | method (`_FinancePageState`) | B | Push the subscriptions page; subscription edits (then `_processSubscriptions`) and transaction edits commit merge-by-id, reminder time and sort through `_saveData`. |
| `_openSubscriptionDetail` | method (`_FinancePageState`) | B | Push one subscription's detail page from the home overview, exactly as the subscriptions page does; transaction edits commit merge-by-id. |
| `_showFinanceMenu` | method (`_FinancePageState`) | B | Show the bottom-sheet menu for categories (whose category and transaction edits commit merge-by-id), exchange rates, and default currency. |
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
| `_FinanceBody({...})` | constructor (`_FinanceBody`) | B | Create the finance body arranger. |
| [`build`](#financebody-build) | method (`_FinanceBody`) | A | Stack the summary above the transactions, or put it in a pane beside them. |
| `_SubscriptionOverview({...})` | constructor (`_SubscriptionOverview`) | B | Create the summary pane's subscription overview. |
| [`build`](#subscriptionoverview-build) | method (`_SubscriptionOverview`) | A | Render the three subscription statistics and the active list inside the summary pane. |
| `_SubscriptionOverviewTile({...})` | constructor (`_SubscriptionOverviewTile`) | B | Create one read-only row of the subscription overview. |
| `build` | method (`_SubscriptionOverviewTile`) | B | Render a dense subscription row: avatar, name, cycle and next billing, amount. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/views/finance_page.dart` returns 42,
matching the 42 rows above exactly — every block sits immediately above its real declaration (a
constructor, `createState`, a lifecycle method, a private method, a `build` override, or the nested
local function inside `_buildLeading`); none were found misattached above a call-site statement,
and no undocumented real declaration was found. The six classes' plain widget fields (e.g.
`_FinancePageState`'s `_accounts`/`_categories`/`_transactions`/... state fields and its `_ioQueue` future, and the
`StatelessWidget` subclasses' constructor parameters) carry no `/// Purpose:` block, consistent with
this codebase's convention of documenting callable members rather than data fields.

## Documentation

### `Future<void> _io(Future<void> Function() op)` <a id="_io"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 113-117)
- **Purpose:** Run one finance load, save, or sub-page commit only after the previous one has
  finished, so the page never reads and writes `finance_data.json` concurrently (v1.5.2).
- **Inputs:** `op` — the queued work.
- **Returns:** `Future<void>` that completes (or fails) with `op`.
- **Side effects:** Advances the `_ioQueue` field.
- **Algorithm:**
  1. `next = _ioQueue.then((_) => op(), onError: (_) => op())` — `op` runs after the previous
     operation whether that one succeeded or failed.
  2. Store `next.catchError((_) {})` as the new `_ioQueue`, so one failed operation does not
     poison the queue for later ones.
  3. Return `next` itself, so the caller still sees `op`'s own error.
- **Usage:**
  ```dart
  Future<void> _loadData() => _io(_loadDataNow);
  ```
  [`_saveData`](#_savedata) and [`_commitSubPage`](#_commitsubpage) enqueue the same way.
- **Notes:** An `op` must never *await* `_loadData`, `_saveData` or `_commitSubPage` — each of
  them enqueues behind the running `op`, which would then wait on itself and deadlock the queue.
  Firing one without awaiting it is fine: that is how [`_loadDataNow`](#_loaddatanow) calls
  [`_processSubscriptions`](#_processsubscriptions), which enqueues a save that runs after the load.

### `Future<void> _loadData()` <a id="_loaddata"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (line 169)
- **Purpose:** Reload finance data and exchange rates from disk, serialized with saves and
  sub-page commits through the I/O queue.
- **Inputs:** None.
- **Returns:** `Future<void>` completing when the queued load has run.
- **Side effects:** Enqueues [`_loadDataNow`](#_loaddatanow) on [`_io`](#_io).
- **Algorithm:** `_io(_loadDataNow)`.
- **Usage:**
  ```dart
  ReminderService.instance.onRenewalsProcessed = _loadData;
  _loadData();
  AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  ```
  Also used as `_FinanceDataError(message: _loadError!, onRetry: _loadData)`'s retry callback.
- **Notes:** Since v1.5.2 a reload triggered by a renewal or a sync while a save is in flight waits
  for that save instead of racing it.

### `Future<void> _loadDataNow()` <a id="_loaddatanow"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 176-203)
- **Purpose:** Body of `_loadData`, run inside the I/O queue: load finance data and exchange-rate
  data into state, or record a load error so existing-but-unreadable data is surfaced instead of
  silently treated as empty.
- **Inputs:** None (reads `FinanceStorage.load()` and `ExchangeRateStorage.load()`).
- **Returns:** `Future<void>`.
- **Side effects:** Sets nearly every state field on success (through `_applyFinanceData`:
  `_accounts`, `_categories`, `_transactions`, `_subscriptions`, `_defaultCurrency`, subscription
  reminder hour/minute/sort mode/custom order, account sort modes/custom orders,
  `_accountPickerSettings`, `_settingsModifiedAt`; plus `_rateData`, `_loaded`); on a read failure
  sets `_loadError` and returns early instead. After a successful load calls
  `_updateReminderService()`, and `_processSubscriptions()` if any subscriptions exist.
- **Algorithm:**
  1. Inside one `try`/`catch`, call `FinanceStorage.load()`
     ([`finance_storage.md#load`](../services/finance_storage.md#load)) and then
     `ExchangeRateStorage.load()`
     ([`exchange_rate_storage.md#load`](../services/exchange_rate_storage.md#load)). If either
     throws, and the widget is still `mounted`, set `_loadError = e.toString()` and
     `_loaded = true`, then return — no other field is touched, so a load failure never clobbers
     previously-displayed data.
  2. Return if the widget is no longer `mounted`.
  3. Inside `setState`, clear `_loadError`. If `data` is non-null, pass it to `_applyFinanceData`,
     which copies every field into the corresponding state field — `_accountSortModes` and
     `_accountCustomOrders` are deep-copied via `Map.of`/`List<String>.of` rather than aliased.
     Always assign `_rateData = rateData` and `_loaded = true`.
  4. Call `_updateReminderService()`.
  5. If `_subscriptions.isNotEmpty`, call [`_processSubscriptions`](#_processsubscriptions) to
     generate any overdue billing transactions; its save is enqueued, not awaited.
- **Usage:** Only through [`_loadData`](#_loaddata).
- **Notes:** Since v1.5.2 the exchange rates load inside the same `try`, so an unreadable rates
  file (an `ExchangeRateStorageException`) shows the blocking `_FinanceDataError` view and blocks
  writes instead of escaping as an unhandled error; before, the rates were loaded after the `try`.
  Because a caught read error returns before resetting `_accounts`/`_transactions`/etc., a
  transient read failure after a successful earlier load still keeps the last-good in-memory data
  underneath the blocking `_FinanceDataError` view rather than blanking it — though the error view
  is what actually renders in that state (see `build`).

### `void _processSubscriptions()` <a id="_processsubscriptions"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 212-221)
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
  Also passed as the `after` callback of the subscriptions page's `onSubscriptionsChanged` commit
  (wired up in `_openSubscriptions`), so a changed billing cycle is caught up as soon as the
  merged subscriptions are in state rather than waiting for the next load.
- **Notes:** Safe to call repeatedly — `SubscriptionProcessor.process` recognizes both random-id
  (legacy) and stable-id (current) billing transactions, so re-running it never double-bills a day.
  It fires `_saveData()` without awaiting it, so it is safe to call from inside the I/O queue
  (see [`_io`](#_io)).

### `Future<void> _saveData()` <a id="_savedata"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (line 243)
- **Purpose:** Save the page's in-memory finance state, serialized with loads and sub-page commits
  through the I/O queue.
- **Inputs:** None.
- **Returns:** `Future<void>` completing when the queued save has run.
- **Side effects:** Enqueues [`_saveDataNow`](#_savedatanow) on [`_io`](#_io).
- **Algorithm:** `_io(_saveDataNow)`.
- **Usage:**
  ```dart
  void _deleteTransaction(Transaction tx) {
    setState(() {
      _transactions.removeWhere((t) => t.id == tx.id);
    });
    _saveData();
  }
  ```
  Called after the home page's own mutations (`_addTransaction`, `_deleteTransaction`,
  `_editTransaction`, `_processSubscriptions`, `_pickDefaultCurrency`) and by the sub-pages'
  settings callbacks — accounts `onSortChanged`/`onAccountPickerSettingsChanged`, subscriptions
  `onReminderChanged`/`onSortChanged`. Since v1.5.2 the sub-pages' list callbacks no longer call it;
  they go through [`_commitSubPage`](#_commitsubpage).
- **Notes:** Writes the page's whole in-memory state, so it is only right for edits made on this
  page or to settings fields; a list edited on a sub-page is merged by id instead.

### `Future<void> _saveDataNow()` <a id="_savedatanow"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 250-258)
- **Purpose:** Body of `_saveData`, run inside the I/O queue: persist the current in-memory finance
  state to disk, refusing to write while the loaded file is known to be unreadable.
- **Inputs:** None (reads every persisted state field).
- **Returns:** `Future<void>`.
- **Side effects:** Either shows a `financeDataWriteBlocked` snack bar and returns (no write), or
  calls `FinanceStorage.save(...)`
  ([`finance_storage.md#save`](../services/finance_storage.md#save)), then
  `AutoSyncService.instance.notifySaved()` and `_updateReminderService()`.
- **Algorithm:**
  1. If `_loadError != null`, call `_showWriteBlocked()` (a `SnackBar` with
     `l10n.financeDataWriteBlocked`, only when `mounted`) and return — this stops a
     corrupted-on-disk finance file from being overwritten by whatever (empty or stale) in-memory
     state resulted from the failed load.
  2. Otherwise call `FinanceStorage.save(_currentFinanceData())`, which snapshots every current
     state field.
  3. Call `AutoSyncService.instance.notifySaved()` so the auto-sync scheduler knows local data
     changed.
  4. Call `_updateReminderService` to keep `ReminderService` in sync with whatever was just saved.
- **Usage:** Only through [`_saveData`](#_savedata).
- **Notes:** The write-block guard means a genuinely broken finance file can only be fixed outside
  the app (or by whatever recovery `FinanceStorage`/`_FinanceDataError`'s retry offers) — the UI
  will never silently replace it with empty data.

### `Future<void> _commitSubPage({IdListDelta<Account>? accounts, IdListDelta<Category>? categories, IdListDelta<Transaction>? transactions, IdListDelta<Subscription>? subscriptions, VoidCallback? after})` <a id="_commitsubpage"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 269-306)
- **Purpose:** Merge one sub-page callback's list edits into the current file by record id and
  save, instead of writing the sub-page's whole list back (v1.5.2).
- **Inputs:** optional per-list deltas `accounts`, `categories`, `transactions`, `subscriptions`
  (each an `IdListDelta` from [`id_list_delta.dart`](../../../shared/utils/id_list_delta.md));
  `after` — runs once the commit has finished.
- **Returns:** `Future<void>`.
- **Side effects:** Reads and writes `finance_data.json`, replaces the page's finance state with the
  merged data, calls `AutoSyncService.instance.notifySaved()` and `_updateReminderService()`; may
  set `_loadError` and show the write-blocked snack bar.
- **Algorithm:** Inside one [`_io`](#_io) operation:
  1. If `_loadError != null`, call `_showWriteBlocked()` and return.
  2. Re-read the file with `FinanceStorage.load()`. If it throws, set `_loadError` (when mounted,
     which switches the page to the blocking error view), call `_showWriteBlocked()`, and return
     without writing.
  3. `base` = the freshly loaded data, or `_currentFinanceData()` when the file does not exist.
  4. `merged = base.copyWith(...)` ([`finance_storage.md`](../services/finance_storage.md)), where
     each list that has a delta becomes `delta.applyTo(base.<list>)` and every other list, and every
     settings field, stays as it is in `base`.
  5. `FinanceStorage.save(merged)`, then `_applyFinanceData(merged)` (inside `setState` when
     mounted), `notifySaved()` and `_updateReminderService()`.

  After the queued operation, call `after` if the widget is still mounted — outside the queue, so
  `after` may itself enqueue a save.
- **Usage:** Each sub-page opener takes an `IdListBaseline` per list when it pushes the sub-page,
  and every list callback turns the reported list into a delta with `take`:
  ```dart
  final subBase = IdListBaseline<Subscription>(_subscriptions, (s) => s.id);
  ...
  onSubscriptionsChanged: (s) {
    _commitSubPage(
      subscriptions: subBase.take(s),
      after: _processSubscriptions,
    );
  },
  ```
  Wired for accounts and transactions (`_openAccounts`), transactions (`_openAnalysis`,
  `_openSubscriptionDetail`), subscriptions and transactions (`_openSubscriptions`), and categories
  and transactions (the categories entry of `_showFinanceMenu`).
- **Notes:** Fixes a lost update: a sub-page holds the list it was opened with, so a subscription
  renewal, a local-API write or a sync made while it was open used to be overwritten when the
  sub-page handed its stale whole list back through `_saveData`. Now only the records the sub-page
  changed are replayed onto what is on disk, and records it did not touch keep their fresh value.
  `take` must run synchronously in the callback so each callback yields only its own changes; the
  merge rules (upsert by id, removed ids dropped, a pure reorder not captured) are documented on
  [`id_list_delta.md`](../../../shared/utils/id_list_delta.md).

### `Future<void> _pickFlowMonth()` <a id="_pickflowmonth"></a>
- **Kind:** method of `_FinancePageState`
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 386-455)
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
- **Source:** `lib/features/finance/views/finance_page.dart` (lines 463-848)
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
     compute every account's balance in one pass with `accountBalances(_accounts, _transactions,
     _rateData)` ([`balance_util.md`](../services/balance_util.md); v1.5.2, previously one
     `accountBalance` pass per account), then fold over `_accounts`, reading `balances[a.id] ?? 0.0`
     and converting it to `_defaultCurrency` using **today's** `currentRates` — unlike the
     per-transaction snapshot rates used for `monthExpense`/`monthIncome`.
  7. Compute `upcomingSubs = upcomingSubscriptions(_subscriptions, days: 3)`, then `activeSubs`
     through `sortSubscriptions` with the stored sort mode and custom order, and
     `subscriptionSummary` through `summarizeSubscriptions` — all from
     [`subscription_summary.md`](../services/subscription_summary.md). When `twoPane` and
     `activeSubs` is non-empty, a `_SubscriptionOverview` is appended to `summaryBlocks`, after the
     AI card below.
  8. Between the upcoming-renewals strip (and its `Divider`) and the subscription overview,
     `summaryBlocks` always holds an
     [`AiInsightCard`](../../ai/widgets/ai_insight_card.md#aiinsightcard-new) (v1.5.0) with
     `module: InsightModule.finance`, `compact: !twoPane` (collapsed to one preview line when
     stacked), and two `AiInsightSection`s: `l10n.aiFinanceFlow` over the slots `flowSummary` and
     `flowAdvice`, and `l10n.aiFinanceSubscriptions` over `subSummary` and `subAdvice`. Its
     `buildRequest: (language, now)` calls
     [`buildFinanceInsightFacts`](../services/finance_insight_facts.md#buildfinanceinsightfacts)
     with `now`, `_accounts`, `_categories`, `_transactions`, `_subscriptions`, `_rateData` and
     `_defaultCurrency`, and returns `null` when that returns `null`, otherwise
     `AiInsightRequest(facts: facts, language: language, now: now)`. The card renders nothing while
     on-device AI is off or the platform cannot have a model.
  9. Build a `Scaffold` with an `AppBar` (accounts/analysis/subscriptions/overflow-menu actions,
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
  10. A `FloatingActionButton` triggers `_addTransaction`, disabled when `_loadError != null`.
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
- [`balance_util.dart`](../services/balance_util.md) — `convertCurrency`, `accountBalances`, used by
  [`build`](#build) for the summary totals.
- [`finance_storage.md`](../services/finance_storage.md) — `load`/`save` and `FinanceData.copyWith`,
  used by [`_loadDataNow`](#_loaddatanow), [`_saveDataNow`](#_savedatanow) and
  [`_commitSubPage`](#_commitsubpage).
- [`exchange_rate_storage.md`](../services/exchange_rate_storage.md) — `load`, `currentRates`,
  `ratesAt`, used by [`_loadDataNow`](#_loaddatanow) and [`build`](#build).
- [`id_list_delta.dart`](../../../shared/utils/id_list_delta.md) — `IdListBaseline`/`IdListDelta`,
  the merge-by-id deltas [`_commitSubPage`](#_commitsubpage) replays onto the re-read file (v1.5.2).
- [`grouped_transaction_list.dart`](../widgets/grouped_transaction_list.md) —
  `buildGroupedTransactionList`, used to render the date-grouped transaction list in
  [`build`](#build).
- [`add_transaction_dialog.dart`](../widgets/add_transaction_dialog.md) — the dialog shown by
  `_addTransaction` and `_editTransaction`.
- [`ai_insight_card.dart`](../../ai/widgets/ai_insight_card.md) and
  [`finance_insight_facts.dart`](../services/finance_insight_facts.md) — the on-device AI card in
  `summaryBlocks` and the facts it is given (v1.5.0).
- [`subscription_summary.dart`](../services/subscription_summary.md) — `upcomingSubscriptions`,
  `sortSubscriptions`, `summarizeSubscriptions`, used by [`build`](#build) for the renewal strip
  and the subscription overview.
- [`subscription_avatar.dart`](../widgets/subscription_avatar.md) — the avatar in
  `_SubscriptionOverviewTile`.
- [`subscription_detail_page.dart`](subscription_detail_page.md) — pushed by
  `_openSubscriptionDetail`.
- [`reminder_service.md`](../../../shared/services/reminder_service.md) — `updateSubscriptionData`,
  kept in sync by `_updateReminderService`.
- [`auto_sync_service.md`](../../../shared/services/auto_sync_service.md) —
  `addOnLocalDataChanged`/`notifySaved`, used by `initState`/[`_saveDataNow`](#_savedatanow)/
  [`_commitSubPage`](#_commitsubpage).

### `Widget build(BuildContext context)` (`_FinanceBody`) <a id="financebody-build"></a>
- **Kind:** method of `_FinanceBody`
- **Source:** `lib/features/finance/views/finance_page.dart` (line 1163)
- **Purpose:** Arrange the month summary and the transaction list either stacked or in two panes.
- **Inputs:** `context`; the widget's own `twoPane`, `leftPaneWidth`, `summaryBlocks`,
  `transactionHeader` and `transactionList` fields.
- **Returns:** A `Column` when stacked, a `Row` when split.
- **Side effects:** None beyond building widgets.
- **Algorithm:**
  1. `!twoPane` → `Column(children: [...summaryBlocks, transactionHeader,
     Expanded(transactionList)])`, which is exactly the body the page had before v1.4.1.
  2. Otherwise `Row` of `SizedBox(width: leftPaneWidth, child: ListView(summaryBlocks))`, a
     `VerticalDivider(width: 1)`, and an `Expanded` right pane holding the header above the list.
- **Usage:** Built by `_FinancePageState.build` once the split decision and the pane width are
  resolved.
- **Notes:** The three content slots are built once by the page and arranged two ways here, so the
  two layouts can never show different content — with one deliberate exception the page itself
  makes: since v1.4.3 the subscription overview is added to `summaryBlocks` only in the two-pane
  arrangement, because it fills a pane that would otherwise sit empty, while stacked it would push
  the first transaction further down a phone. The on-device AI card (v1.5.0) is in both
  arrangements, but `compact` (collapsed to one preview line) when stacked. Stacked, the month summary already spends up to a
  third of a phone's height before the first transaction appears; split, the transaction list —
  the thing the user actually reads — takes everything the summary does not. The left pane is a
  `ListView` in its own right because a long renewal strip plus the summary can outgrow a compact
  height, which the split rule still admits at 480. See
  [../../../../adaptive-layout.md](../../../../adaptive-layout.md).

### `Widget build(BuildContext context)` (`_SubscriptionOverview`) <a id="subscriptionoverview-build"></a>
- **Kind:** method of `_SubscriptionOverview`
- **Source:** `lib/features/finance/views/finance_page.dart` (line 1491)
- **Purpose:** Render the subscriptions page's three statistics and its active list inside the
  finance summary pane.
- **Inputs:** `context`; the widget's `paneWidth`, `summary`, `active`, `categories`, `accounts`,
  `currencyCode`, `onOpenAll` and `onOpenDetail` fields.
- **Returns:** A `Column`.
- **Side effects:** None beyond building widgets; the two callbacks push pages when tapped.
- **Algorithm:**
  1. A header row styled like the upcoming-renewals header (`Icons.repeat`, `financeSubscriptions`)
     with a trailing chevron `IconButton` that calls `onOpenAll`.
  2. `statColumns = columnCapacity(paneWidth - 32, minItemWidth: subscriptionStatMinWidth, gap:
     summaryCardGap, maxColumns: 3)`; the three `_SummaryCard`s (monthly due, monthly average,
     yearly average) are packed into rows with `adaptiveTileRows` — two-up across the pane's whole
     clamp range, three-up once the pane passes about 378.
  3. A `financeActiveSubscriptions` sub-header, then one `_SubscriptionOverviewTile` per active
     subscription with the resolved category and account, tapping through to `onOpenDetail`.
- **Usage:** Appended to `summaryBlocks` by `_FinancePageState.build` when `twoPane` and there is
  at least one active subscription — whenever a block can render to nothing, it belongs in the
  gate.
- **Notes:** Deliberately not the subscriptions page's reminder controls, its historical list, or
  its own upcoming strip — the home page shows an upcoming strip directly above this block. The
  tiles are read-only: editing, cancelling and restoring stay on the subscriptions page so the
  home page does not grow a second copy of those flows.

## Navigation-bar padding (1.6.1)

With the Expressive bottom bar floating over the page (see [../../../../adaptive-layout.md](../../../../adaptive-layout.md)), the data-error view's `SingleChildScrollView` passes its explicit padding through `navBarAwarePadding(context, ...)` so the last content can scroll above the bar. The page's main lists have no explicit padding, so Flutter applies the bar's inset to them itself.

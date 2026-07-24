# lib/features/finance/views/exchange_rates_page.dart

The exchange-rates list/edit page: shows every configured `'FROM_TO'` currency pair and its rate,
lets the user add/edit/delete pairs by hand, and auto-refreshes from the live API at most once a
day. This is the UI half of exchange-rate history — the persistence and snapshot-history model live
in [`ExchangeRateStorage`](../services/exchange_rate_storage.md), and the live-fetch client in
[`ExchangeRateApi`](../services/exchange_rate_api.md). See
[Finance](../../../../features/finance.md#exchange-rates) for the feature-level overview, including
the fallback/1:1-conversion behavior this page's rates feed into everywhere else in Finance.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ExchangeRatesPage({super.key})` | constructor (`ExchangeRatesPage`) | B | Create an exchange rates page instance. |
| `createState` | method (`ExchangeRatesPage`) | B | Create the mutable state object for this widget. |
| `initState` | method (`_ExchangeRatesPageState`) | B | Kick off `_loadRates`. |
| [`_loadRates`](#loadrates) | method (`_ExchangeRatesPageState`) | A | Load persisted rates, then auto-fetch if not fetched today. |
| [`_fetchOnline`](#fetchonline) | method (`_ExchangeRatesPageState`) | A | Fetch live rates and persist the merged result. |
| [`_saveRates`](#saverates) | method (`_ExchangeRatesPageState`) | A | Persist the current in-memory rate map as a new snapshot. |
| [`_addRate`](#addrate) | method (`_ExchangeRatesPageState`) | A | Add a new currency-pair rate via dialog. |
| [`_editRate`](#editrate) | method (`_ExchangeRatesPageState`) | A | Edit an existing pair's currencies/rate via dialog. |
| [`_deleteRate`](#deleterate) | method (`_ExchangeRatesPageState`) | A | Remove a currency-pair rate and persist the change. |
| `build` | method (`_ExchangeRatesPageState`) | B | Build the app bar (with refresh action), rate list, and add button. |
| `_RateDialog({...})` | constructor (`_RateDialog`) | B | Create a rate dialog instance. |
| `createState` | method (`_RateDialog`) | B | Create the mutable state object for this widget. |
| `initState` | method (`_RateDialogState`) | B | Pre-fill from/to currency and rate controller from the widget, capture the initial signature. |
| `dispose` | method (`_RateDialogState`) | B | Dispose the rate text controller. |
| `build` | method (`_RateDialogState`) | B | Build the from/to currency dropdowns, rate field, and actions. |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | method (`_RateDialogState`) | A | Report whether the form differs from its initial state. |
| [`_signature`](#signature) | method (`_RateDialogState`) | A | Build a comparable string snapshot of the dialog's fields. |
| [`_submit`](#submit) | method (`_RateDialogState`) | A | Validate the rate/currencies and pop with a `'FROM_TO'` entry. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/views/exchange_rates_page.dart`
returns 18, matching the 18 rows above exactly — every block sits immediately above its real
declaration (a constructor, `createState`, `initState`, `dispose`, or a method); none were found
misattached above a call-site statement, and no undocumented real declaration was found. The class
declarations themselves (`ExchangeRatesPage`, `_ExchangeRatesPageState`, `_RateDialog`,
`_RateDialogState`) and the `static const _currencies` list carry no `/// Purpose:` block,
consistent with this codebase's convention of documenting callable members rather than classes or
plain data.

## Documentation

### `Future<void> _loadRates()` <a id="loadrates"></a>
- **Kind:** method of `_ExchangeRatesPageState`
- **Source:** `lib/features/finance/views/exchange_rates_page.dart` (lines 49-60)
- **Purpose:** Load persisted exchange-rate data, display it immediately, then trigger an online
  refresh if one hasn't happened yet today.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads `exchange_rates.json` via
  [`ExchangeRateStorage.load`](../services/exchange_rate_storage.md#load); may trigger a network
  fetch via [`_fetchOnline`](#fetchonline).
- **Algorithm:**
  1. Load `ExchangeRateData` from storage.
  2. Populate `_data`/`_rates`/`_loaded` from it immediately, so the page shows the last-saved rates
     without waiting on the network.
  3. Check [`ExchangeRateApi.shouldFetchToday`](../services/exchange_rate_api.md#shouldfetchtoday)
     against `data.lastFetchedAt`; if a fetch is due, `await` [`_fetchOnline()`](#fetchonline).
- **Usage:**
  ```dart
  @override
  void initState() {
    super.initState();
    _loadRates();
  }
  ```
- **Notes:** Because step 2 always shows the previously saved rates before the network check in
  step 3, a slow or failed background fetch never blocks the page from displaying data.

### `Future<void> _fetchOnline()` <a id="fetchonline"></a>
- **Kind:** method of `_ExchangeRatesPageState`
- **Source:** `lib/features/finance/views/exchange_rates_page.dart` (lines 67-85)
- **Purpose:** Fetch live exchange rates for the user's configured currency pairs and persist the
  merged result, guarding against concurrent or duplicate fetches.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Performs HTTP GETs via
  [`ExchangeRateApi.fetchAndMerge`](../services/exchange_rate_api.md#fetchandmerge); may write
  `exchange_rates.json` and call `AutoSyncService.instance.notifySaved()`; toggles `_fetching` to
  drive the refresh spinner.
- **Algorithm:**
  1. Bail out immediately if there's no loaded data yet (`_data == null`) or a fetch is already in
     flight (`_fetching`).
  2. Set `_fetching = true` to show the app-bar spinner.
  3. Call `ExchangeRateApi.fetchAndMerge(_data!)` — only currency pairs already configured locally
     are updated.
  4. If it returned non-null data and the widget is still mounted: stamp a fresh
     `lastFetchedAt: DateTime.now()` onto the result, persist it via
     [`ExchangeRateStorage.save`](../services/exchange_rate_storage.md#save), notify
     `AutoSyncService`, and update local `_data`/`_rates`.
  5. Clear `_fetching` if still mounted, regardless of outcome.
- **Usage:**
  ```dart
  IconButton(
    onPressed: _fetching ? null : _fetchOnline,
    icon: _fetching
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.refresh),
  ),
  ```
- **Notes:** If `fetchAndMerge` returns `null` (no configured pairs, or every HTTP request failed),
  this method silently does nothing beyond clearing `_fetching` — no error is surfaced to the user
  for a failed manual or automatic refresh.

### `Future<void> _saveRates()` <a id="saverates"></a>
- **Kind:** method of `_ExchangeRatesPageState`
- **Source:** `lib/features/finance/views/exchange_rates_page.dart` (lines 92-98)
- **Purpose:** Persist the current in-memory `_rates` map as a new exchange-rate snapshot (created
  only if it actually differs from the current one) and flag the sync layer as having a pending
  local change.
- **Inputs:** None (reads `_data`, `_rates`).
- **Returns:** `Future<void>`.
- **Side effects:** Writes `exchange_rates.json` via
  [`ExchangeRateStorage.save`](../services/exchange_rate_storage.md#save) (only if rates changed,
  per [`updateRates`](../services/exchange_rate_storage.md#updaterates)); calls
  `AutoSyncService.instance.notifySaved()`.
- **Algorithm:**
  1. No-op if `_data` hasn't loaded yet.
  2. Delegate to
     [`ExchangeRateStorage.updateRates`](../services/exchange_rate_storage.md#updaterates), which
     only creates a new snapshot if `_rates` differs from the current snapshot's rates.
  3. Store the (possibly unchanged) result back in `_data` and write it via `save`.
  4. Notify `AutoSyncService`.
- **Usage:** Called after every rate mutation: [`_addRate`](#addrate), [`_editRate`](#editrate),
  [`_deleteRate`](#deleterate).
- **Notes:** Always calls `ExchangeRateStorage.save`, even when `updateRates` made no change, so a
  manual edit that exactly matches the existing rate still results in a (no-op) write and a sync
  notification.

### `Future<void> _addRate()` <a id="addrate"></a>
- **Kind:** method of `_ExchangeRatesPageState`
- **Source:** `lib/features/finance/views/exchange_rates_page.dart` (lines 105-114)
- **Purpose:** Open the blank rate dialog and, if confirmed, add the new currency-pair rate.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Shows [`_RateDialog`](#submit); on confirmation, mutates `_rates` and persists
  via [`_saveRates`](#saverates).
- **Algorithm:**
  1. Show `_RateDialog` with no pre-filled currencies/rate.
  2. If the user submits a result (a `MapEntry` whose key is the `'FROM_TO'` pair string built by
     [`_RateDialogState._submit`](#submit)), store it in `_rates` and await `_saveRates()`.
- **Usage:**
  ```dart
  floatingActionButton: FloatingActionButton(
    onPressed: _addRate,
    child: const Icon(Icons.add),
  ),
  ```
- **Notes:** `_rates` is a plain `Map<String, double>`, so adding a pair that already exists (same
  `from`/`to`) silently overwrites the old rate — there's no existing-entry check.

### `Future<void> _editRate(String key, double value)` <a id="editrate"></a>
- **Kind:** method of `_ExchangeRatesPageState`
- **Source:** `lib/features/finance/views/exchange_rates_page.dart` (lines 121-139)
- **Purpose:** Open the rate dialog pre-filled with an existing pair's currencies and value, then
  apply the (possibly renamed) result.
- **Inputs:** `key` — the current `'FROM_TO'` pair key; `value` — its current rate.
- **Returns:** `Future<void>`.
- **Side effects:** Shows `_RateDialog`; on confirmation, removes the old key from `_rates` and
  stores the new key/value; persists via [`_saveRates`](#saverates).
- **Algorithm:**
  1. Split `key` on `_` into `[from, to]`; return immediately if it's not exactly two parts
     (defensive against a malformed stored key).
  2. Show `_RateDialog` pre-filled with the parsed currencies and current rate.
  3. On confirmation, remove the *old* key from `_rates`, insert the dialog's result under its
     (possibly different) key, then `await _saveRates()`.
- **Usage:**
  ```dart
  onTap: () => _editRate(entry.key, entry.value),
  ```
- **Notes:** Because the dialog lets the user change either currency, editing can effectively
  rename a pair (e.g. `USD_CNY` -> `USD_EUR`); the explicit `_rates.remove(key)` before inserting the
  new key is what prevents a stale entry surviving under the old key.

### `void _deleteRate(String key)` <a id="deleterate"></a>
- **Kind:** method of `_ExchangeRatesPageState`
- **Source:** `lib/features/finance/views/exchange_rates_page.dart` (lines 146-149)
- **Purpose:** Remove a currency-pair rate and persist the change.
- **Inputs:** `key`.
- **Returns:** None.
- **Side effects:** Mutates `_rates`; persists via [`_saveRates`](#saverates) (called without
  `await`).
- **Algorithm:** Remove `key` from `_rates` inside `setState`, then call `_saveRates()`.
- **Usage:**
  ```dart
  onDismissed: (_) => _deleteRate(entry.key),
  ```
- **Notes:** Unlike [`_addRate`](#addrate)/[`_editRate`](#editrate), the call to `_saveRates()` here
  isn't awaited — a delete followed immediately by another rate action could in principle race,
  though doing so requires another dialog round-trip first.

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **Kind:** method of `_RateDialogState`
- **Source:** `lib/features/finance/views/exchange_rates_page.dart` (line 424)
- **Purpose:** Tell `UnsavedChangesGuard`
  ([`../../../shared/widgets/unsaved_changes_guard.md`](../../../shared/widgets/unsaved_changes_guard.md))
  whether the form has diverged from its initial state.
- **Inputs:** None (reads instance state only).
- **Returns:** `bool` — `true` if the current signature differs from `_initialSignature`.
- **Side effects:** None.
- **Algorithm:** Compare [`_signature()`](#signature) against `_initialSignature`, captured once at
  the end of `initState`.
- **Usage:**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **Notes:** Passed as a tear-off, so it is re-evaluated on every pop attempt rather than cached.

### `String _signature()` <a id="signature"></a>
- **Kind:** method of `_RateDialogState`
- **Source:** `lib/features/finance/views/exchange_rates_page.dart` (lines 431-432)
- **Purpose:** Produce a single string that changes if and only if the from/to currency or rate
  text has changed, for use as the dirty-check baseline/comparison.
- **Inputs:** None (reads instance state only).
- **Returns:** `String` — the joined signature from `formSignature`
  (`../../../shared/widgets/unsaved_changes_guard.md`).
- **Side effects:** None.
- **Algorithm:** Delegate to `formSignature([_from, _to, _rateController.text.trim()])`.
- **Usage:**
  ```dart
  _initialSignature = _signature();
  // ...
  bool _hasUnsavedChanges() => _signature() != _initialSignature;
  ```
- **Notes:** None.

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **Kind:** method of `_RateDialogState`
- **Source:** `lib/features/finance/views/exchange_rates_page.dart` (lines 439-444)
- **Purpose:** Validate the entered rate and currency pair, then pop the dialog with a
  `'FROM_TO'` -> rate entry.
- **Inputs:** `guard` — the `UnsavedChangesController` supplied by `UnsavedChangesGuard.builder`.
- **Returns:** None.
- **Side effects:** Pops the route (via `guard.pop`) with a result, only when the form is valid.
- **Algorithm:**
  1. Parse the rate text as a `double`; return silently if unparsable or `<= 0`.
  2. Return silently if `_from == _to` (a currency can't convert to itself).
  3. Otherwise pop with `MapEntry('${_from}_$_to', rate)` — this underscore-joined string is the
     canonical pair-key format used throughout `_rates`, `ExchangeRateStorage`, and
     `balance_util.dart`'s conversion lookups.
- **Usage:**
  ```dart
  onSubmitted: (_) => _submit(guard),
  ...
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(isEditing ? l10n.commonSave : l10n.commonAdd),
  ),
  ```
- **Notes:** Validation failures are silent — no error text is shown for an invalid rate, a
  same-currency pair, or empty input; the dialog simply doesn't close.

## Related pages

- [Finance](../../../../features/finance.md) — the exchange-rate feature overview, including the
  direct/reverse/intermediate/1:1-fallback conversion order that consumes these rates.
- [`ExchangeRateStorage`](../services/exchange_rate_storage.md) — the snapshot-history persistence
  layer (`load`, `save`, `updateRates`) this page is a thin UI over.
- [`ExchangeRateApi`](../services/exchange_rate_api.md) — `fetchAndMerge`/`shouldFetchToday`, the
  live-fetch client used by [`_loadRates`](#loadrates)/[`_fetchOnline`](#fetchonline).
- [`unsaved_changes_guard.dart`](../../../shared/widgets/unsaved_changes_guard.md) — the shared
  dirty-check/discard-confirmation pattern used by `_RateDialog`.

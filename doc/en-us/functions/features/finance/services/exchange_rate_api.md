# lib/features/finance/services/exchange_rate_api.dart

A thin HTTP client over the free [open.er-api.com](https://open.er-api.com) exchange-rate API (no
API key, 1,500 requests/month free). It only ever updates currency pairs the user already has
configured in [`ExchangeRateData`](exchange_rate_storage.md) — it never introduces a new pair on its
own — and the exchange rates page gates calls to at most once per day via
[`shouldFetchToday`](#shouldfetchtoday). See
[Finance](../../../../features/finance.md#exchange-rates) for how this fits with
[`ExchangeRateStorage`](exchange_rate_storage.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`fetchAndMerge`](#fetchandmerge) | static method (`ExchangeRateApi`) | A | Fetch live rates and merge them into existing exchange-rate data. |
| [`_fetchRates`](#fetchrates) | static method (`ExchangeRateApi`) | A | Raw fetch of one base currency's rate table. |
| [`shouldFetchToday`](#shouldfetchtoday) | static method (`ExchangeRateApi`) | A | Decide whether an auto-fetch is due today. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/services/exchange_rate_api.dart`
returns 3, matching the 3 rows above exactly — each block sits immediately above its real static
method declaration; none were found misattached above a call-site statement. The only other
declaration in the file is the private `static const _baseUrl` field, which (consistent with this
codebase's convention) carries no `/// Purpose:` block since it is plain data, not a callable. All
three methods are classified Tier A: they perform real network IO and/or branching logic, matching
the tiering rule's explicit services/IO bucket.

## Documentation

### `static Future<ExchangeRateData?> fetchAndMerge(ExchangeRateData data)` <a id="fetchandmerge"></a>
- **Kind:** static method of `ExchangeRateApi`
- **Source:** `lib/features/finance/services/exchange_rate_api.dart` (line 22)
- **Purpose:** Fetch live rates for every base currency implied by the user's currently-configured
  pairs, then merge the fetched values into a new `ExchangeRateData` snapshot — updating only pairs
  that already exist locally.
- **Inputs:** `data` — the current `ExchangeRateData`, whose `currentRates` keys (`'FROM_TO'`
  strings) determine which pairs and base currencies to query.
- **Returns:** `Future<ExchangeRateData?>` — `null` if there are no configured pairs or every fetch
  failed; otherwise the result of [`ExchangeRateStorage.updateRates`](exchange_rate_storage.md#updaterates).
- **Side effects:** Performs one HTTP GET per unique base currency among the configured pairs.
- **Algorithm:**
  1. Read `data.currentRates.keys` as the pair list; return `null` immediately if empty.
  2. Collect the unique set of base currencies (the part before `_` in each `'FROM_TO'` pair key).
  3. Call [`_fetchRates`](#fetchrates) once per base currency, skipping any that return `null`;
     return `null` if none succeeded.
  4. For each configured pair, look up the fetched base's rate table and overwrite that pair's entry
     in a copy of `data.currentRates` if present.
  5. Delegate to `ExchangeRateStorage.updateRates(data, newRates)`, which only creates a new
     `RateSnapshot` if the merged rates actually differ from the current ones.
- **Usage:**
  ```dart
  final updated = await ExchangeRateApi.fetchAndMerge(_data!);
  if (updated != null && mounted) {
    final withTimestamp = ExchangeRateData(
      currentSnapshotId: updated.currentSnapshotId,
      snapshots: updated.snapshots,
      lastFetchedAt: DateTime.now(),
    );
    await ExchangeRateStorage.save(withTimestamp);
  }
  ```
  (`lib/features/finance/views/exchange_rates_page.dart:70-77`, `_fetchOnline`, which stamps
  `lastFetchedAt` after a successful merge so [`shouldFetchToday`](#shouldfetchtoday) won't re-fetch
  again the same day.)
- **Notes:** A pair whose base currency's fetch failed (or whose target currency isn't in the
  fetched table) is left unchanged in `newRates` rather than removed — a partial network failure
  never drops a previously-configured pair.

### `static Future<Map<String, double>?> _fetchRates(String base)` <a id="fetchrates"></a>
- **Kind:** static method of `ExchangeRateApi`
- **Source:** `lib/features/finance/services/exchange_rate_api.dart` (line 64)
- **Purpose:** Perform the raw HTTP GET against `open.er-api.com` for one base currency and parse its
  rate table.
- **Inputs:** `base` — an ISO currency code, e.g. `'CNY'`.
- **Returns:** `Future<Map<String, double>?>` — e.g. `{'CNY': 7.25, 'EUR': 0.92, ...}`, or `null` on
  any failure.
- **Side effects:** One HTTP GET to `https://open.er-api.com/v6/latest/<base>` with a 10-second
  timeout.
- **Algorithm:**
  1. GET the URL; return `null` if the status code isn't 200.
  2. Decode the JSON body; return `null` unless `json['result'] == 'success'`.
  3. Map `json['rates']` (`Map<String, dynamic>`) to `Map<String, double>`.
  4. Any exception (network error, timeout, malformed JSON) is caught and mapped to `null`.
- **Usage:** Called once per unique base currency inside
  [`fetchAndMerge`](#fetchandmerge): `final result = await _fetchRates(base);`.
- **Notes:** Internal helper used within this file only; never throws to its caller.

### `static bool shouldFetchToday(DateTime? lastFetch)` <a id="shouldfetchtoday"></a>
- **Kind:** static method of `ExchangeRateApi`
- **Source:** `lib/features/finance/services/exchange_rate_api.dart` (line 85)
- **Purpose:** Decide whether an automatic rate refresh is due, gating the free API to at most one
  fetch per calendar day.
- **Inputs:** `lastFetch` — the previously recorded `ExchangeRateData.lastFetchedAt`, or `null` if
  never fetched.
- **Returns:** `bool` — `true` if `lastFetch` is `null` or falls on a different calendar day than
  now.
- **Side effects:** None.
- **Algorithm:** Compare `now.year`/`now.month`/`now.day` against `lastFetch`'s corresponding
  fields; any mismatch (or a `null` `lastFetch`) means fetching is due.
- **Usage:**
  ```dart
  if (ExchangeRateApi.shouldFetchToday(data.lastFetchedAt)) {
    await _fetchOnline();
  }
  ```
  (`lib/features/finance/views/exchange_rates_page.dart:57-59`, run once right after the exchange
  rates page loads its data.)
- **Notes:** Uses local calendar-day comparison, not a rolling 24-hour window — a fetch just before
  midnight and another just after midnight both count as "different days" even if less than a
  minute apart.

# lib/features/finance/services/exchange_rate_storage.dart

Persistence layer for `exchange_rates.json`, storing exchange rates as a deduplicated history of
immutable `RateSnapshot`s plus a `currentSnapshotId` pointer, rather than a single flat
currency-pair map — this is what lets `Transaction.rateSnapshotId` reconstruct the exact rate that
was in effect when a historical transaction was recorded (see
[`ratesAt`](#ratesat) and [`balance_util.dart`](balance_util.md)'s `_accountTransactionDelta`).
`load()` transparently migrates an older flat-map file format into the first snapshot. See
[Finance](../../../../features/finance.md#exchange-rates) for the feature-level overview and
[`ExchangeRateApi`](exchange_rate_api.md) for the live-fetch client that calls
[`updateRates`](#updaterates).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`RateSnapshot()`](#ratesnapshot-new) | constructor (`RateSnapshot`) | A | Create a rate snapshot with a generated id/timestamp. |
| [`toJson`](#ratesnapshot-tojson) | method (`RateSnapshot`) | A | Serialize a rate snapshot to JSON. |
| [`RateSnapshot.fromJson`](#ratesnapshot-fromjson) | factory constructor (`RateSnapshot`) | A | Parse a rate snapshot from JSON. |
| [`ExchangeRateData()`](#exchangeratedata-new) | constructor (`ExchangeRateData`) | A | Bundle all snapshots plus the current-snapshot pointer. |
| [`currentRates`](#currentrates) | getter (`ExchangeRateData`) | A | The active snapshot's rate map. |
| [`ratesAt`](#ratesat) | method (`ExchangeRateData`) | A | Rates for a specific historical snapshot, falling back to current. |
| [`toJson`](#exchangeratedata-tojson) | method (`ExchangeRateData`) | A | Serialize exchange-rate data to JSON. |
| [`ExchangeRateData.fromJson`](#exchangeratedata-fromjson) | factory constructor (`ExchangeRateData`) | A | Parse exchange-rate data from JSON. |
| [`_getFile`](#getfile) | static method (`ExchangeRateStorage`) | A | Resolve the on-disk path of `exchange_rates.json`. |
| [`load`](#load) | static method (`ExchangeRateStorage`) | A | Load, parse, and migrate `exchange_rates.json`. |
| [`save`](#save) | static method (`ExchangeRateStorage`) | A | Queue a write of exchange-rate data, serialized against concurrent saves. |
| [`_saveNow`](#savenow) | static method (`ExchangeRateStorage`) | A | Perform one preserved, validated, atomic write. |
| [`updateRates`](#updaterates) | static method (`ExchangeRateStorage`) | A | Create a new snapshot only if rates actually changed. |
| [`_ratesEqual`](#ratesequal) | static method (`ExchangeRateStorage`) | A | Compare two rate maps for exact equality. |
| [`_defaultData`](#defaultdata) | static method (`ExchangeRateStorage`) | A | Build the built-in default exchange-rate data. |
| [`_createInitialData`](#createinitialdata) | static method (`ExchangeRateStorage`) | A | Wrap a flat rate map as the first snapshot. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/services/exchange_rate_storage.dart`
returns 16, matching the 16 rows above exactly — each block sits immediately above its real
declaration (constructor, factory constructor, getter, or static method); none were found
misattached above a call-site statement. The remaining plain fields in the file (`_fileName`,
`_writeQueue`, `_defaultRates`) carry no `/// Purpose:` block, consistent with this codebase's
convention of documenting callable members rather than plain data, and none of them constitute an
undocumented callable declaration. All 16 documented declarations are classified Tier A: the model
constructors/serialization pairs match the tiering rule's explicit Tier A bucket, and every
`ExchangeRateStorage` static method performs real IO, branching, or loop logic (including
`currentRates`/`ratesAt`, whose one-line map lookups feed every currency conversion in the feature
via `balance_util.dart`, and `_defaultData`, whose default rates are the fallback every fresh
install starts from).

## Documentation

### `RateSnapshot({String? id, required Map<String, double> rates, DateTime? createdAt})` <a id="ratesnapshot-new"></a>
- **Kind:** constructor of `RateSnapshot`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 22)
- **Purpose:** Hold one immutable point-in-time snapshot of every configured currency pair's rate.
- **Inputs:** `rates` required; `id`/`createdAt` optional.
- **Returns:** A new `RateSnapshot`.
- **Side effects:** None.
- **Algorithm:** Field-assigning constructor; `id` defaults to a new UUID v4, `createdAt` to
  `DateTime.now()`.
- **Usage:**
  ```dart
  final snapshot = RateSnapshot(rates: Map.unmodifiable(newRates));
  ```
  (`lib/features/finance/services/exchange_rate_storage.dart:215`, inside
  [`updateRates`](#updaterates); also used by [`_createInitialData`](#createinitialdata) to wrap a
  flat rate map as the first snapshot.)
- **Notes:** `updateRates` always passes an unmodifiable rate map, guarding against accidental
  in-place mutation of a snapshot that's supposed to be immutable history.

### `Map<String, dynamic> toJson()` <a id="ratesnapshot-tojson"></a>
- **Kind:** method of `RateSnapshot`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 31)
- **Purpose:** Serialize one snapshot into the JSON nested under `ExchangeRateData.snapshots`.
- **Inputs:** None.
- **Returns:** `{id, rates, createdAt}`.
- **Side effects:** None.
- **Algorithm:** Direct map literal; `createdAt` as `toIso8601String()`.
- **Usage:** Called from `ExchangeRateData.toJson()`: `snapshots.map((k, v) => MapEntry(k,
  v.toJson()))` (`lib/features/finance/services/exchange_rate_storage.dart:93`).
- **Notes:** None.

### `factory RateSnapshot.fromJson(Map<String, dynamic> json)` <a id="ratesnapshot-fromjson"></a>
- **Kind:** factory constructor of `RateSnapshot`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 42)
- **Purpose:** Parse one snapshot back out of its persisted JSON form.
- **Inputs:** `json` — decoded map, one entry of `ExchangeRateData.snapshots`.
- **Returns:** A new `RateSnapshot`.
- **Side effects:** None.
- **Algorithm:** Cast `id`; map `rates` (`Map<String, dynamic>`) to `Map<String, double>`; parse
  `createdAt` via `DateTime.parse`.
- **Usage:** Called from `ExchangeRateData.fromJson`: `MapEntry(k, RateSnapshot.fromJson(v as
  Map<String, dynamic>))` (`lib/features/finance/services/exchange_rate_storage.dart:105`).
- **Notes:** Unlike most `fromJson` factories in the Finance feature, this one has no defensive
  fallback for a missing `createdAt` — a malformed snapshot throws, which propagates up through
  `ExchangeRateData.fromJson` to `load()`'s catch-all (falling back to `_defaultData()`).

### `ExchangeRateData({required String currentSnapshotId, required Map<String, RateSnapshot> snapshots, DateTime? lastFetchedAt})` <a id="exchangeratedata-new"></a>
- **Kind:** constructor of `ExchangeRateData`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 62)
- **Purpose:** Hold every retained rate snapshot plus a pointer to the currently-active one and the
  last time rates were auto-fetched.
- **Inputs:** `currentSnapshotId`, `snapshots` required; `lastFetchedAt` optional (drives
  [`ExchangeRateApi.shouldFetchToday`](exchange_rate_api.md#shouldfetchtoday)).
- **Returns:** A new `ExchangeRateData`.
- **Side effects:** None.
- **Algorithm:** Plain field-assigning constructor (no generated defaults, unlike most other models
  in this feature).
- **Usage:**
  ```dart
  final withTimestamp = ExchangeRateData(
    currentSnapshotId: updated.currentSnapshotId,
    snapshots: updated.snapshots,
    lastFetchedAt: DateTime.now(),
  );
  await ExchangeRateStorage.save(withTimestamp);
  ```
  (`lib/features/finance/views/exchange_rates_page.dart:72-77`, stamping `lastFetchedAt` after a
  successful online fetch.)
- **Notes:** None.

### `Map<String, double> get currentRates` <a id="currentrates"></a>
- **Kind:** getter of `ExchangeRateData`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 74)
- **Purpose:** Return the rate map from whichever snapshot `currentSnapshotId` points to.
- **Inputs:** None.
- **Returns:** `Map<String, double>` — `const {}` if `currentSnapshotId` doesn't resolve to a known
  snapshot.
- **Side effects:** None.
- **Algorithm:** `snapshots[currentSnapshotId]?.rates ?? const {}`.
- **Usage:**
  ```dart
  final currentRates = widget.rateData.currentRates;
  ```
  (`lib/features/finance/views/analysis_page.dart:860`, used wherever "today's" rates rather than a
  transaction's historical snapshot are needed, e.g. converting a reconstructed account balance.)
- **Notes:** None.

### `Map<String, double> ratesAt(String? snapshotId)` <a id="ratesat"></a>
- **Kind:** method of `ExchangeRateData`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 83)
- **Purpose:** Return the rates in effect at a specific historical snapshot, falling back to the
  current rates when the id is missing or unknown.
- **Inputs:** `snapshotId` — typically a `Transaction.rateSnapshotId`.
- **Returns:** `Map<String, double>`.
- **Side effects:** None.
- **Algorithm:** `snapshots[snapshotId]?.rates ?? currentRates`.
- **Usage:**
  ```dart
  final rates = rateData.ratesAt(tx.rateSnapshotId);
  ```
  (`lib/features/finance/services/balance_util.dart:316`, inside `_accountTransactionDelta` — the
  central place a transaction's amount is converted using the rate that was in effect when it was
  recorded.)
- **Notes:** A transaction recorded before exchange-rate snapshotting existed (`rateSnapshotId ==
  null`) transparently falls back to today's rates.

### `Map<String, dynamic> toJson()` <a id="exchangeratedata-tojson"></a>
- **Kind:** method of `ExchangeRateData`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 91)
- **Purpose:** Serialize the full snapshot history into the JSON persisted as `exchange_rates.json`.
- **Inputs:** None.
- **Returns:** `{currentSnapshotId, snapshots: {...}, lastFetchedAt?}`.
- **Side effects:** None.
- **Algorithm:** Map literal; `snapshots` mapped through `RateSnapshot.toJson()` per entry;
  `lastFetchedAt` included only when non-null.
- **Usage:** Called from [`_saveNow`](#savenow): `jsonEncode(data.toJson())` (non-migration path)
  or as the `next` payload passed to `JsonPreservation.encodeForFile`.
- **Notes:** None.

### `factory ExchangeRateData.fromJson(Map<String, dynamic> json)` <a id="exchangeratedata-fromjson"></a>
- **Kind:** factory constructor of `ExchangeRateData`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 103)
- **Purpose:** Parse the full snapshot history back out of `exchange_rates.json`'s current-format
  JSON (i.e. one that already has a `snapshots` key).
- **Inputs:** `json` — decoded map.
- **Returns:** A new `ExchangeRateData`.
- **Side effects:** None.
- **Algorithm:** Map `json['snapshots']` entries through
  [`RateSnapshot.fromJson`](#ratesnapshot-fromjson); read `currentSnapshotId`; parse `lastFetchedAt`
  if present.
- **Usage:** Called from [`load`](#load): `return ExchangeRateData.fromJson(json);` once the
  migration check confirms the file already has a `snapshots` key.
- **Notes:** Assumes `json['snapshots']` exists — callers must check for the older flat-map format
  first (see [`load`](#load)'s migration branch) or this throws.

### `static Future<File> _getFile()` <a id="getfile"></a>
- **Kind:** static method of `ExchangeRateStorage`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 127)
- **Purpose:** Resolve the `File` handle for `exchange_rates.json` inside the app's data directory.
- **Inputs:** None.
- **Returns:** `Future<File>`.
- **Side effects:** None directly (only builds a path).
- **Algorithm:** `appDir = await TodoStorage.getAppDir()`, then `File('${appDir.path}/$_fileName')`
  — reusing Todo's app-directory resolution, the same pattern as every other storage class in this
  app.
- **Usage:** Called at the top of [`load`](#load) and [`_saveNow`](#savenow).
- **Notes:** None.

### `static Future<ExchangeRateData> load()` <a id="load"></a>
- **Kind:** static method of `ExchangeRateStorage`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 137)
- **Purpose:** Load `exchange_rates.json`, transparently migrating the older flat currency-pair map
  format into a single-snapshot history, and falling back to built-in defaults on any failure.
- **Inputs:** None.
- **Returns:** `Future<ExchangeRateData>` — never `null`; a missing or corrupt file resolves to
  [`_defaultData()`](#defaultdata).
- **Side effects:** Reads `exchange_rates.json` from disk.
- **Algorithm:**
  1. If the file doesn't exist, return `_defaultData()`.
  2. Decode its JSON.
  3. **Migration:** if the decoded map has no `snapshots` key (the old flat-map format), treat every
     entry as a `Map<String, double>` and wrap it via
     [`_createInitialData`](#createinitialdata) as the very first snapshot.
  4. Otherwise parse it directly via
     [`ExchangeRateData.fromJson`](#exchangeratedata-fromjson).
  5. Any exception anywhere in this path (missing file race, bad JSON, malformed snapshot) is caught
     and mapped to `_defaultData()`.
- **Usage:**
  ```dart
  final data = await ExchangeRateStorage.load();
  ```
  (`lib/features/finance/views/exchange_rates_page.dart:50`; also used by
  `finance_storage.dart`'s `load()` to run the forced-balance migration, and by
  `webdav_service.dart`'s `_migrateFinanceForcedBalances` for the same reason during sync.)
- **Notes:** Unlike `FinanceStorage.load()` and `WeightStorage.load()`, this never throws to the
  caller — every failure path silently degrades to the built-in default rates instead of surfacing
  an error, since exchange rates are less critical user data than accounts/transactions.

### `static Future<void> save(ExchangeRateData data)` <a id="save"></a>
- **Kind:** static method of `ExchangeRateStorage`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 163)
- **Purpose:** Queue a write of `data`, ensuring overlapping `save` calls never interleave their
  writes to `exchange_rates.json`.
- **Inputs:** `data`.
- **Returns:** `Future<void>` that completes when this specific write finishes.
- **Side effects:** Eventually writes `exchange_rates.json` (via `_saveNow`); mutates the static
  `_writeQueue` field.
- **Algorithm:** Chain onto `_writeQueue` so `_saveNow(data)` runs regardless of whether the previous
  queued write succeeded (`next = _writeQueue.then((_) => _saveNow(data), onError: (_) =>
  _saveNow(data))`), replace `_writeQueue` with an error-swallowing version of `next`, and return the
  un-swallowed `next` to this caller. This is the identical write-serialization pattern used by
  `WeightStorage.save` and `FinanceStorage.save`.
- **Usage:**
  ```dart
  await ExchangeRateStorage.save(withTimestamp);
  AutoSyncService.instance.notifySaved();
  ```
  (`lib/features/finance/views/exchange_rates_page.dart:77-78`.)
- **Notes:** Concurrent `save()` calls are strictly serialized in call order — the same overlapping-
  writer protection documented for `WeightStorage.save`.

### `static Future<void> _saveNow(ExchangeRateData data)` <a id="savenow"></a>
- **Kind:** static method of `ExchangeRateStorage`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 177)
- **Purpose:** Perform one actual write of `data` to `exchange_rates.json`, after the caller has
  already taken its turn in the write queue — including a one-time detection of whether the
  on-disk file is still in the legacy flat-map format.
- **Inputs:** `data`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `exchange_rates.json` through `DataFileSafety.writeValidatedDataJson`
  (a validated, atomic replace).
- **Algorithm:**
  1. Resolve the file; if it exists, decode it and check whether it has a `snapshots` key
     (`preserveUnknown`). Any decode failure here is swallowed and treated as `preserveUnknown =
     true`.
  2. If the on-disk file is still the legacy flat-map format (`preserveUnknown == false`), write
     `jsonEncode(data.toJson())` directly — there is no unknown-field schema to preserve against an
     old format.
  3. Otherwise run `JsonPreservation.encodeForFile` against the schema registered for
     `'exchange_rates.json'` before writing, so fields a newer app version wrote that this version's
     model doesn't know about survive the round-trip.
- **Usage:** Only called from [`save`](#save)'s write-queue chain.
- **Notes:** This is the one storage class in the Finance feature whose save path branches on the
  *current on-disk format* rather than always running unknown-field preservation — a direct
  consequence of supporting the flat-map -> snapshot-history migration.

### `static ExchangeRateData updateRates(ExchangeRateData data, Map<String, double> newRates)` <a id="updaterates"></a>
- **Kind:** static method of `ExchangeRateStorage`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 208)
- **Purpose:** Apply a new set of rates, creating a fresh `RateSnapshot` (and advancing
  `currentSnapshotId`) only if the rates actually differ from the current snapshot — so identical
  fetches or saves never grow the snapshot history pointlessly.
- **Inputs:** `data` — current state; `newRates` — the candidate new rate map.
- **Returns:** `ExchangeRateData` — `data` unchanged (same object) if [`_ratesEqual`](#ratesequal)
  says nothing changed, otherwise a new value with one additional snapshot.
- **Side effects:** None (returns a new value; does not write to disk itself).
- **Algorithm:**
  1. Compare `data.currentRates` against `newRates` via [`_ratesEqual`](#ratesequal); return `data`
     unchanged if equal.
  2. Otherwise build a new `RateSnapshot(rates: Map.unmodifiable(newRates))`, add it to a copy of
     `data.snapshots`, and return a new `ExchangeRateData` pointing `currentSnapshotId` at it
     (dropping `lastFetchedAt` — callers that need to preserve it, like
     [`ExchangeRateApi.fetchAndMerge`](exchange_rate_api.md#fetchandmerge)'s caller, re-stamp it
     afterward).
- **Usage:**
  ```dart
  return ExchangeRateStorage.updateRates(data, newRates);
  ```
  (`lib/features/finance/services/exchange_rate_api.dart:54`, the last step of
  [`ExchangeRateApi.fetchAndMerge`](exchange_rate_api.md#fetchandmerge); also called directly from
  `exchange_rates_page.dart:94` when the user manually edits rates.)
- **Notes:** Old snapshots are never removed — the history only grows, which is what lets
  `ratesAt(oldSnapshotId)` keep resolving historical transactions correctly indefinitely.

### `static bool _ratesEqual(Map<String, double> a, Map<String, double> b)` <a id="ratesequal"></a>
- **Kind:** static method of `ExchangeRateStorage`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 229)
- **Purpose:** Decide whether two rate maps are exactly equal, gating whether
  [`updateRates`](#updaterates) needs to create a new snapshot.
- **Inputs:** `a`, `b`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `false` if lengths differ; otherwise `false` on the first key whose value in `a`
  doesn't equal its value in `b`; `true` if every key matches.
- **Usage:** Called once inside [`updateRates`](#updaterates): `if (_ratesEqual(current, newRates))
  return data;`.
- **Notes:** Compares by iterating `a`'s keys only — this is correct here because the caller only
  ever passes same-shape rate maps (both derived from the same configured-pairs set), so a length
  check plus one-directional key iteration is sufficient.

### `static ExchangeRateData _defaultData()` <a id="defaultdata"></a>
- **Kind:** static method of `ExchangeRateStorage`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 242)
- **Purpose:** Build the built-in default exchange-rate data used when no file exists yet or loading
  fails.
- **Inputs:** None.
- **Returns:** `ExchangeRateData`.
- **Side effects:** None.
- **Algorithm:** `_createInitialData(_defaultRates)` — a one-line forward to
  [`_createInitialData`](#createinitialdata) using the hard-coded `_defaultRates` map (USD/EUR/GBP/
  JPY/CAD/AUD to CNY, plus EUR_USD/GBP_USD).
- **Usage:** Called from [`load`](#load)'s two failure paths (missing file, any exception).
- **Notes:** The hard-coded defaults are approximate reference values only — they exist so the app
  has *something* to convert with before the user's first successful online fetch or manual edit.

### `static ExchangeRateData _createInitialData(Map<String, double> rates)` <a id="createinitialdata"></a>
- **Kind:** static method of `ExchangeRateStorage`
- **Source:** `lib/features/finance/services/exchange_rate_storage.dart` (line 249)
- **Purpose:** Wrap a flat currency-pair rate map as the first (and only) snapshot of a fresh
  `ExchangeRateData` history.
- **Inputs:** `rates`.
- **Returns:** `ExchangeRateData` with exactly one snapshot.
- **Side effects:** None.
- **Algorithm:** Build a single `RateSnapshot(rates: rates)`, then an `ExchangeRateData` whose
  `snapshots` map has that one entry and whose `currentSnapshotId` points at it.
- **Usage:** Called both from [`_defaultData`](#defaultdata) (fresh install) and from
  [`load`](#load)'s legacy-format migration branch (an existing flat-map file's rates become the
  first snapshot).
- **Notes:** This is the one place a pre-snapshot-history flat rate map is converted into the
  snapshot format — both the "no file yet" and "old file format" cases funnel through it.

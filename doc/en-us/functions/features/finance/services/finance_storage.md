# lib/features/finance/services/finance_storage.dart

Persistence layer for `finance_data.json`: the `FinanceData` model (accounts, categories,
transactions, subscriptions, plus persisted UI settings like subscription reminder time and account
picker preferences) and `FinanceStorage`, which loads/saves it through a single serialized write
queue — the same pattern as
[`WeightStorage`](../../weight/services/weight_storage.md) and
[`ExchangeRateStorage`](exchange_rate_storage.md). `load()` additionally runs the one-time
forced-balance-to-adjustment-transaction migration
([`migrateForcedBalances`](balance_util.md#migrateforcedbalances)) whenever an account still carries
a legacy forced balance, re-saving the migrated result; since v1.5.2 it reads `exchange_rates.json`
only in that case. See
[Finance](../../../../features/finance.md) for the feature overview and
[Data Formats](../../../../data-formats.md#finance--finance_datajson) for the full `finance_data.json`
field list.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`FinanceData()`](#financedata-new) | constructor (`FinanceData`) | A | Bundle every Finance record list plus persisted settings. |
| [`copyWith`](#financedata-copywith) | method (`FinanceData`) | A | Return a copy with the given record lists replaced (v1.5.2). |
| [`toJson`](#financedata-tojson) | method (`FinanceData`) | A | Serialize finance data to JSON. |
| [`FinanceData.fromJson`](#financedata-fromjson) | factory constructor (`FinanceData`) | A | Parse finance data from JSON. |
| [`FinanceStorageException()`](#financestorageexception-new) | const constructor (`FinanceStorageException`) | A | Create a finance storage exception with a user-visible message. |
| `toString` | method (`FinanceStorageException`) | B | Return the exception's message as its string representation. |
| [`_getFile`](#getfile) | static method (`FinanceStorage`) | A | Resolve the on-disk path of `finance_data.json`. |
| [`load`](#load) | static method (`FinanceStorage`) | A | Load, parse, and forced-balance-migrate `finance_data.json`, reading rates only when needed. |
| [`_migrateForcedBalances`](#migrateforcedbalances) | static method (`FinanceStorage`) | A | Rebuild `FinanceData` with migrated accounts/transactions if the migration changed anything. |
| [`save`](#save) | static method (`FinanceStorage`) | A | Queue a write of finance data, serialized against concurrent saves. |
| [`_saveNow`](#savenow) | static method (`FinanceStorage`) | A | Persist finance data after entering the write queue. |
| [`_atomicWriteJson`](#atomicwritejson) | static method (`FinanceStorage`) | A | Replace a JSON file only after the replacement content validates (atomic write). |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/services/finance_storage.dart` returns
12, matching the 12 rows above exactly — each block sits immediately above its real declaration
(constructor, factory constructor, method, or static method); none were found misattached above a
call-site statement. The remaining plain fields in the file (`FinanceData`'s own fields,
`FinanceStorageException.message`, `FinanceStorage._fileName`/`_writeQueue`) carry no
`/// Purpose:` block, consistent with this codebase's convention of documenting callable members
rather than plain data, and none of them constitute an undocumented callable declaration.
`toString()` is classified Tier B as a trivial one-line accessor with no logic of its own (the same
classification given to the identical pattern in `weight_storage.md`'s
`WeightStorageException.toString`); every other declaration is classified Tier A — model
constructors/serialization, or real IO/branching logic in `FinanceStorage`'s static methods.

## Documentation

### `FinanceData({required List<Account> accounts, required List<Category> categories, required List<Transaction> transactions, List<Subscription> subscriptions = const [], String defaultCurrency = 'CNY', DateTime? settingsModifiedAt, int? subscriptionReminderHour, int? subscriptionReminderMinute, String? subscriptionSortMode, List<String>? subscriptionCustomOrder, Map<String, String> accountSortModes = const {}, Map<String, List<String>> accountCustomOrders = const {}, AccountPickerSettings accountPickerSettings = const AccountPickerSettings()})` <a id="financedata-new"></a>
- **Kind:** constructor of `FinanceData`
- **Source:** `lib/features/finance/services/finance_storage.dart` (line 31)
- **Purpose:** Bundle every Finance record list (accounts, categories, transactions, subscriptions)
  together with the persisted feature-wide settings — default currency, subscription reminder
  time/sort, per-account sort mode/custom order maps, and the transaction account-picker settings.
- **Inputs:** `accounts`, `categories`, `transactions` required; `subscriptions` defaults empty;
  `defaultCurrency` defaults `'CNY'`; every settings field is optional/defaulted.
- **Returns:** A new `FinanceData`.
- **Side effects:** None.
- **Algorithm:** Field-assigning constructor; `settingsModifiedAt` defaults to the Unix epoch
  (`DateTime.fromMillisecondsSinceEpoch(0)`) when not supplied, unlike most other models in this
  feature which default to "now."
- **Usage:**
  ```dart
  FinanceData _currentFinanceData() => FinanceData(
    accounts: _accounts,
    categories: _categories,
    transactions: _transactions,
    subscriptions: _subscriptions,
    defaultCurrency: _defaultCurrency,
    settingsModifiedAt: _settingsModifiedAt,
    subscriptionReminderHour: _subscriptionReminderHour,
    subscriptionReminderMinute: _subscriptionReminderMinute,
    subscriptionSortMode: _subscriptionSortMode,
    subscriptionCustomOrder: _subscriptionCustomOrder,
    accountSortModes: _accountSortModes,
    accountCustomOrders: _accountCustomOrders,
    accountPickerSettings: _accountPickerSettings,
  );
  ```
  (`lib/features/finance/views/finance_page.dart:147-161`, the Finance home page's snapshot of its
  state, saved whole by its settings flows.)
- **Notes:** Defaulting `settingsModifiedAt` to the epoch (rather than "now") means a freshly
  constructed `FinanceData` whose settings were never explicitly touched compares as "older" than
  any synced settings update — relevant to the settings side of three-way merge (see
  [Three-Way Merge](../../../../algorithms/three-way-merge.md)).

### `FinanceData copyWith({List<Account>? accounts, List<Category>? categories, List<Transaction>? transactions, List<Subscription>? subscriptions})` <a id="financedata-copywith"></a>
- **Kind:** method of `FinanceData`
- **Source:** `lib/features/finance/services/finance_storage.dart` (line 54)
- **Purpose:** Return a copy with the given record lists replaced (v1.5.2).
- **Inputs:** optional `accounts`, `categories`, `transactions`, `subscriptions`.
- **Returns:** A new `FinanceData` sharing every other field with this one.
- **Side effects:** None.
- **Algorithm:** Build a new `FinanceData` with each record list taken from the argument when it is
  non-null and from `this` otherwise; `defaultCurrency`, `settingsModifiedAt` and all the settings
  fields are copied unchanged.
- **Usage:**
  ```dart
  final merged = base.copyWith(
    accounts: accounts?.applyTo(base.accounts),
    categories: categories?.applyTo(base.categories),
    transactions: transactions?.applyTo(base.transactions),
    subscriptions: subscriptions?.applyTo(base.subscriptions),
  );
  ```
  (`lib/features/finance/views/finance_page.dart:290-295`, inside `_commitSubPage`.)
- **Notes:** Used by the finance page's merge-by-id sub-page saves: only the lists a sub-page
  changed are replayed onto the freshly re-read file, and settings fields are carried over
  unchanged.

### `Map<String, dynamic> toJson()` <a id="financedata-tojson"></a>
- **Kind:** method of `FinanceData`
- **Source:** `lib/features/finance/services/finance_storage.dart` (line 82)
- **Purpose:** Serialize the full Finance dataset into the JSON persisted as `finance_data.json`.
- **Inputs:** None.
- **Returns:** A map with `accounts`/`categories`/`transactions`/`subscriptions`/`defaultCurrency`/
  `settingsModifiedAt`/`accountPickerSettings` always present, and the reminder/sort-mode/
  custom-order settings fields included only when non-null/non-empty.
- **Side effects:** None.
- **Algorithm:** Map literal; each record list mapped through its own `toJson()`;
  `accountPickerSettings` nested via [`AccountPickerSettings.toJson`](../models/finance.md#accountpickersettings-tojson).
- **Usage:** Called from [`_saveNow`](#savenow), as the `next` payload passed to
  `JsonPreservation.encodeForFile`.
- **Notes:** None.

### `factory FinanceData.fromJson(Map<String, dynamic> json)` <a id="financedata-fromjson"></a>
- **Kind:** factory constructor of `FinanceData`
- **Source:** `lib/features/finance/services/finance_storage.dart` (line 108)
- **Purpose:** Parse the full Finance dataset back out of `finance_data.json`.
- **Inputs:** `json` — decoded map.
- **Returns:** A new `FinanceData`.
- **Side effects:** None.
- **Algorithm:** Map each record-list key through its model's `fromJson`, defaulting to `[]` when
  the key is absent; `defaultCurrency` defaults `'CNY'`; `settingsModifiedAt` falls back to the Unix
  epoch when absent; `accountSortModes`/`accountCustomOrders` are parsed from nested
  `Map<String, dynamic>`s with an explicit per-value cast; `accountPickerSettings` via
  [`AccountPickerSettings.fromJson`](../models/finance.md#accountpickersettings-fromjson).
- **Usage:**
  ```dart
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final data = FinanceData.fromJson(json);
  ```
  (`lib/features/finance/services/finance_storage.dart:205-206`, inside [`load`](#load).)
- **Notes:** Every list field defaults to `[]` (not `null`) when absent, so a partially-populated or
  very old `finance_data.json` still produces a fully-usable `FinanceData` rather than requiring
  null checks downstream.

### `const FinanceStorageException(String message)` <a id="financestorageexception-new"></a>
- **Kind:** const constructor of `FinanceStorageException`
- **Source:** `lib/features/finance/services/finance_storage.dart` (line 165)
- **Purpose:** Create an exception carrying a user-visible message, thrown when `finance_data.json`
  exists but cannot be safely read or written.
- **Inputs:** `message`.
- **Returns:** A new `FinanceStorageException`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:**
  ```dart
  throw FinanceStorageException('$_fileName is not valid JSON: $e');
  ```
  (`lib/features/finance/services/finance_storage.dart:220`, inside [`load`](#load); the analogous
  `'Failed to load $_fileName: $e'` case covers any other read failure, and
  [`_atomicWriteJson`](#atomicwritejson) throws the same type for write-side validation failures.)
- **Notes:** Implements `Exception`, not `Error` — intended to be caught and shown to the user (e.g.
  via the Finance home page's `_loadError` state) rather than treated as a programming bug.

### `static Future<File> _getFile()` <a id="getfile"></a>
- **Kind:** static method of `FinanceStorage`
- **Source:** `lib/features/finance/services/finance_storage.dart` (line 185)
- **Purpose:** Resolve the `File` handle for `finance_data.json` inside the app's data directory.
- **Inputs:** None.
- **Returns:** `Future<File>`.
- **Side effects:** None directly (only builds a path).
- **Algorithm:** `appDir = await TodoStorage.getAppDir()`, then `File('${appDir.path}/$_fileName')`.
- **Usage:** Called at the top of [`load`](#load) and [`_saveNow`](#savenow).
- **Notes:** None.

### `static Future<FinanceData?> load()` <a id="load"></a>
- **Kind:** static method of `FinanceStorage`
- **Source:** `lib/features/finance/services/finance_storage.dart` (line 198)
- **Purpose:** Load and parse `finance_data.json`, running the forced-balance migration and
  persisting the result if it changed anything, so callers always see already-migrated data.
- **Inputs:** None.
- **Returns:** `Future<FinanceData?>` — `null` only if the file doesn't exist; a missing file is
  never confused with a corrupted one, since a corrupted file throws instead.
- **Side effects:** Reads `finance_data.json`; only when a legacy forced balance must be migrated,
  reads exchange-rate data via [`ExchangeRateStorage.load()`](exchange_rate_storage.md#load) and may
  write `finance_data.json` again (via [`save`](#save)).
- **Algorithm:**
  1. Return `null` immediately if the file doesn't exist.
  2. Decode its JSON and parse via [`FinanceData.fromJson`](#financedata-fromjson).
  3. If [`needsForcedBalanceMigration`](balance_util.md#needsforcedbalancemigration) is false for
     `data.accounts`, return `data` at once without reading `exchange_rates.json` (v1.5.2).
  4. Otherwise load current exchange-rate data and run
     [`_migrateForcedBalances`](#migrateforcedbalances).
  5. If migration made no change (`identical(migrated, data)`), return `data` as loaded.
  6. Otherwise attempt `await save(migrated)` (swallowing any save failure) and return `migrated`
     regardless of whether the re-save succeeded.
  7. An [`ExchangeRateStorageException`](exchange_rate_storage.md#exchangeratestorageexception-new)
     from the rates read is rethrown unchanged (v1.5.2). A `FormatException` (invalid JSON) is
     caught and rethrown as `FinanceStorageException('$_fileName is not valid JSON: $e')`; any other
     exception is rethrown as `FinanceStorageException('Failed to load $_fileName: $e')`.
- **Usage:**
  ```dart
  data = await FinanceStorage.load();
  ```
  (`lib/features/finance/views/finance_page.dart:180`, the Finance home page's load path; also used
  by `lib/shared/services/local_api_server.dart`'s HTTP handlers and
  `lib/shared/services/reminder_service.dart`'s hourly subscription check.)
- **Notes:** A missing file and a corrupt file are deliberately distinguished, the same pattern as
  `WeightStorage.load` — missing means "no data yet" (`null`), corrupt/unreadable is an error state
  the UI must surface, never silently mistaken for an empty dataset. Because the rates file is
  read only for a pending migration, an unreadable `exchange_rates.json` blocks loading only in that
  case, and then surfaces as `ExchangeRateStorageException` rather than a finance-file error.

### `static FinanceData _migrateForcedBalances(FinanceData data, ExchangeRateData rateData)` <a id="migrateforcedbalances"></a>
- **Kind:** static method of `FinanceStorage`
- **Source:** `lib/features/finance/services/finance_storage.dart` (line 231)
- **Purpose:** Run [`migrateForcedBalances`](balance_util.md#migrateforcedbalances) over one
  `FinanceData` value and, if it changed anything, rebuild a new `FinanceData` with the migrated
  accounts/transactions and every other field carried over unchanged.
- **Inputs:** `data`; `rateData`.
- **Returns:** `FinanceData` — `data` itself (same object, so `identical()` succeeds in
  [`load`](#load)) if the migration reported no change, otherwise a new value.
- **Side effects:** None directly (no IO of its own).
- **Algorithm:**
  1. Call `migrateForcedBalances(accounts: data.accounts, transactions: data.transactions,
     rateData: rateData)`.
  2. If `!migration.changed`, return `data` as-is (preserving reference identity).
  3. Otherwise construct a new `FinanceData` with `migration.accounts`/`migration.transactions` and
     every other field (`categories`, `subscriptions`, `defaultCurrency`, `settingsModifiedAt`, all
     the settings fields) copied from `data`.
- **Usage:** Called once inside [`load`](#load): `final migrated = _migrateForcedBalances(data,
  rateData);`.
- **Notes:** Returning the exact same `data` object (not just an equal one) when nothing changed is
  what lets `load()` use `identical(migrated, data)` as a cheap "did anything change" check instead
  of a deep comparison.

### `static Future<void> save(FinanceData data)` <a id="save"></a>
- **Kind:** static method of `FinanceStorage`
- **Source:** `lib/features/finance/services/finance_storage.dart` (line 264)
- **Purpose:** Queue a write of `data`, ensuring overlapping `save` calls never interleave their
  writes to `finance_data.json`.
- **Inputs:** `data`.
- **Returns:** `Future<void>` that completes when this specific write finishes.
- **Side effects:** Eventually writes `finance_data.json` (via `_saveNow`); mutates the static
  `_writeQueue` field.
- **Algorithm:** Identical write-serialization pattern to
  [`ExchangeRateStorage.save`](exchange_rate_storage.md#save) and `WeightStorage.save`: chain
  `_saveNow(data)` onto `_writeQueue` regardless of the previous write's outcome, replace
  `_writeQueue` with an error-swallowing version, return the un-swallowed future to this caller.
- **Usage:**
  ```dart
  await FinanceStorage.save(next);
  _notifyWritten();
  return _json({'success': true, ...});
  ```
  (`lib/shared/services/local_api_server.dart:802-804`, the local HTTP API's "create transaction"
  handler; the same call shape saves from `finance_page.dart`'s settings/edit flows and
  `reminder_service.dart`'s subscription catch-up.)
- **Notes:** Concurrent `save()` calls are strictly serialized in call order, same guarantee as
  `WeightStorage.save`.

### `static Future<void> _saveNow(FinanceData data)` <a id="savenow"></a>
- **Kind:** static method of `FinanceStorage`
- **Source:** `lib/features/finance/services/finance_storage.dart` (line 278)
- **Purpose:** Perform one actual write of `data` to `finance_data.json`, after the caller has
  already taken its turn in the write queue.
- **Inputs:** `data`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `finance_data.json` through [`_atomicWriteJson`](#atomicwritejson).
- **Algorithm:**
  1. Resolve the file via `_getFile()`.
  2. Run `JsonPreservation.encodeForFile` against the schema registered for `'finance_data.json'`,
     re-injecting any unknown fields a newer app version wrote.
  3. Write the result via [`_atomicWriteJson`](#atomicwritejson).
- **Usage:** Only called from [`save`](#save)'s write-queue chain.
- **Notes:** Unlike `ExchangeRateStorage._saveNow`, this always runs unknown-field preservation
  unconditionally — `finance_data.json` has no legacy pre-schema format to special-case around.

### `static Future<void> _atomicWriteJson(File file, String jsonStr)` <a id="atomicwritejson"></a>
- **Kind:** static method of `FinanceStorage`
- **Source:** `lib/features/finance/services/finance_storage.dart` (line 293)
- **Purpose:** Replace `finance_data.json` with new content (atomic write) only after confirming the
  new content decodes as a JSON object, refusing to write anything that would corrupt the file.
- **Inputs:** `file`; `jsonStr` — the candidate new content.
- **Returns:** `Future<void>`.
- **Side effects:** Creates the parent directory if missing; writes and renames a `.tmp-<timestamp>`
  temp file over `file`; deletes the temp file on failure.
- **Algorithm:**
  1. `jsonDecode(jsonStr)` up front — throw `FinanceStorageException('Refusing to write invalid
     $_fileName: $e')` immediately if it doesn't parse, before touching disk at all.
  2. Ensure the parent directory exists.
  3. Write `jsonStr` to a uniquely-named temp file (`'${file.path}.tmp-<microsecondsSinceEpoch>'`),
     flushing to disk.
  4. `rename` the temp file onto `file.path` (atomic on the underlying filesystem). Since v1.5.2
     the flushed temp file is no longer re-read and re-decoded first: the content was already
     validated in step 1.
  5. If the rename fails, delete the temp file (best-effort) and rethrow — either
     propagating an existing `FinanceStorageException` or wrapping any other error as
     `FinanceStorageException('Failed to write $_fileName safely: $e')`.
- **Usage:** Called once inside [`_saveNow`](#savenow): `await _atomicWriteJson(file, jsonStr);`.
- **Notes:** The up-front validation guards against a bad in-memory payload, and the
  temp-file-then-rename sequence means an interrupted write never leaves a half-written
  `finance_data.json`: the last-known-good file stays until the rename replaces it.

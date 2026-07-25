# lib/app/data_modules.dart

**The seam between this app and the shared `myapps_data` package**, and the single source of truth
for MyDay's five data files. It replaced four of the five separate hardcoded file lists this app used
to carry (`webdav_service`, `data_file_safety`, `import_export_service`, `backup_service`; the fifth
is `TodoStorage`'s storage-migration list, which is in a storage hub and stayed).

This is also where MyDay's three special cases live, as declarative hooks rather than branches in a
sync loop.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`TodoStorageAdapter`](#todostorageadapter) | class | A | Implements the package's `StorageAdapter` over `TodoStorage`. |
| [`todoDefaultRemotePath`](#constants) | constant | A | `'/MyDay'`. |
| [`todoArchiveNamePrefix`](#constants) | constant | A | `'myday_backup_'`. |
| [`todoDataFileName`](#constants) … `weightDataFileName` | constants | A | The five data file names. |
| [`migrateFinanceForcedBalances(data)`](#financemigration) | function | A | Convert legacy forced balances into real transactions. |
| [`buildTodoModule()`](#structured) | function | A | The todo `DataModule`. |
| [`buildFinanceModule()`](#financemigration) | function | A | The finance `DataModule`, with the migration hook. |
| [`buildExchangeRatesModule()`](#exchangerates) | function | A | The exchange-rates `DataModule`. |
| [`buildIntimacyModule()`](#structured) | function | A | The intimacy `DataModule`. |
| [`buildWeightModule()`](#structured) | function | A | The weight `DataModule`. |
| [`todoModuleRegistry`](#registry) | field | A | The app's ordered `ModuleRegistry`. |

## Documentation

### `class TodoStorageAdapter` <a id="todostorageadapter"></a>
- **Purpose:** Give the shared engines a storage root and `storage_config.json` access without the
  package knowing anything about `TodoStorage`.
- **Constructor:** `const TodoStorageAdapter({Future<Directory> Function()? appDir})`.
- **Methods:** `getAppDir()`, `readConfig()`, `writeConfig(config)`, all delegating to the hub.
- **Notes:** The optional `appDir` resolver exists so `BackupService` can keep honoring its
  `@visibleForTesting appDirProvider`. It is consulted on every call.

### Constants <a id="constants"></a>
- **Notes:** File names and module ids are persisted compatibility contracts — an older build and a
  newer one must interoperate against the same WebDAV server and the same backup bundles. Never
  change them. Note `exchangeRates` is the module id for `exchange_rates.json`.

### Structured modules: todo, intimacy, weight <a id="structured"></a>
- **Notes:** All three go through one private builder. They encode with **compact `jsonEncode`**,
  matching the old `_uploadMergedJson` path, and set `indexMergedUploadProgress: false` because
  MyDay reports an indeterminate upload phase for structured files. Each supplies its conflict
  containers flattened into one list; resolutions are keyed by plain record ID, exactly as the
  conflict dialog already did.
- **Preservation:** every structured module sets a `preUploadTransform` that re-injects unknown JSON
  fields from the base/local/remote snapshots using the app-owned schemas. MyDay's merge output is
  not self-preserving, so skipping this would silently drop a newer build's fields.

### Finance: `migrateFinanceForcedBalances(data)` and `buildFinanceModule()` <a id="financemigration"></a>
- **Purpose:** Convert legacy forced account balances into real transactions, using current exchange
  rates.
- **Notes:** Moved here verbatim from `WebDAVService._migrateFinanceForcedBalances`. It is wired as
  the module's `postMergeTransform` because that is exactly where it ran before: **after** the merge
  and **after** conflict resolution, on both the normal-sync and finalize paths. It is not a
  pre-merge remote migration. Finance also contributes referenced images from its `accounts` and
  `subscriptions` sections.

### Exchange rates <a id="exchangerates"></a>
- **Notes:** Built directly rather than through the structured builder. `mergeExchangeRateJson` is a
  whole-file union merge that can never produce a record conflict, so the outcome is always complete
  and there is no resolution builder. It is the one module that reports indexed upload progress.

### `todoModuleRegistry` <a id="registry"></a>
- **Notes:** Order is todo, finance, exchange rates, intimacy, weight — matching the previous
  `_dataFileNames` list. Order is behaviorally significant for sync order, progress reporting, and
  backup key order.

## Where the contract documentation lives

`packages/myapps_data/doc/en-us/functions/src/modules/data_module.md` and
`packages/myapps_data/doc/en-us/functions/src/storage/storage_adapter.md`.

# lib/shared/services/sync_merge.dart

**Split file.** The generic three-way record merge — `mergeRecords<T>`, `RecordConflict<T>`, and
`RecordMergeResult<T>` — moved to the `myapps_data` package (`lib/src/merge/sync_merge.dart`) and is
re-exported here. MyDay's per-module merge wrappers stay.

The package signature is MyDevice's superset: it adds one optional `mergeUnknownFields` callback.
MyDay does not pass it — unknown fields are re-applied at write time from the schemas in
[`../utils/json_preservation.md`](../utils/json_preservation.md) — so behavior is identical to before
the extraction.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SyncConflictInfo` | class | A | Aggregate conflict info for display. |
| `TodoMergeResult` / `mergeTodoData(...)` | class + function | A | Daily and once tasks (two conflict containers). |
| `FinanceMergeResult` / `mergeFinanceData(...)` | class + function | A | Accounts, categories, transactions, subscriptions. |
| [`mergeExchangeRateJson(local, remote)`](#exchangerates) | function | A | Whole-file union merge; never conflicts. |
| `IntimacyMergeResult` / `mergeIntimacyData(...)` | class + function | A | Partners, toys, positions, records, cycle records; three independent LWW clocks, with sort settings and `chartSettings` on the `settingsModifiedAt` one. |
| `WeightMergeResult` / `mergeWeightData(...)` | class + function | A | Weight records. |
| `RecordConflict<T>` / `RecordMergeResult<T>` / `mergeRecords<T>` | re-export | A | The generic engine, from the package. |

**Reconciliation:** this is a **grouped** page — 7 rows above cover the file's 23 `/// Purpose:`
declarations, because each module's `…MergeResult` class (its constructor, `hasConflicts`,
`buildResolved`, and the shared `_resolveList`) is documented on one row together with its
`merge…Data` function. [INDEX.md](../../INDEX.md) counts rows, not underlying declarations, so it
lists 7.

## Documentation

### `mergeExchangeRateJson(localJson, remoteJson)` <a id="exchangerates"></a>
- **Returns:** Merged JSON string.
- **Notes:** The odd one out — a whole-file string merge rather than a per-record merge, which is why
  its registry entry produces a complete `ModuleMergeOutcome` with no conflict path at all. It is
  also the only module that reports indexed upload progress.

### Per-module merge wrappers
- **Notes:** Each returns an app-typed result carrying its merged lists, its conflict containers, and
  the data needed to rebuild the final model. The sync engine carries these through as opaque
  `state`, which is how the conflict dialogs still receive real model objects. `buildResolved` takes
  a flat `Map<String, dynamic>` keyed by record ID and disambiguates by runtime type, which is why
  one flat resolution map can serve every module at finalize time.
- **Finance:** the forced-balance migration is **not** in this file. It runs after the merge and
  after conflict resolution, and is wired as the module's `postMergeTransform` in
  [`../../app/data_modules.md`](../../app/data_modules.md).

## Where the generic engine documentation lives

`packages/myapps_data/doc/en-us/functions/src/merge/sync_merge.md`.

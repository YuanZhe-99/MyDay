# lib/shared/services/sync_merge.dart

Pure-data merge layer used by `WebDAVService` (`webdav_service.dart`) during step 4-7 of the
[10-step sync flow](../../../sync.md#the-10-step-sync-flow): given a local JSON string, a remote
JSON string, and an optional last-synced base JSON string for one of MyDay's five data files, each
`merge<Module>Data` function here parses all three, runs the generic three-way engine
(`mergeRecords<T>`) once per record collection, resolves the file's non-record settings by
last-writer-wins, and returns a `*MergeResult` bundling the merged data plus any unresolved
`RecordConflict<T>` lists. This file has no I/O of its own — `WebDAVService` handles
download/upload, `.lock`, retries, and unknown-field preservation; this file only computes merges
from strings already in memory. See [Three-Way Merge](../../../algorithms/three-way-merge.md) for
the full field-level semantics of the generic engine and each per-file strategy, and
[WebDAV Sync](../../../sync.md#the-cross-module-mixed-resolutions-map-safety-rule) for how
`finalizePendingSync` hands the same cross-module resolutions map to each module's `buildResolved`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`RecordConflict` (constructor)](#recordconflict-new) | constructor (`RecordConflict<T>`) | A | Create a single record-level conflict pairing local/remote versions of the same id. |
| [`RecordMergeResult` (constructor)](#recordmergeresult-new) | constructor (`RecordMergeResult<T>`) | A | Create a merge result bundling merged records and unresolved conflicts. |
| [`mergeRecords`](#mergerecords) | top-level function | A | Generic three-way merge engine for a list of records keyed by id. |
| [`SyncConflictInfo` (constructor)](#syncconflictinfo-new) | constructor (`SyncConflictInfo`) | A | Create a per-file aggregate of a file's record conflicts for UI display. |
| [`MergeResult` (constructor)](#mergeresult-new) | constructor (`MergeResult`) | A | Create the top-level result of a multi-file merge pass. |
| [`MergeResult.hasConflicts`](#mergeresult-hasconflicts) | getter (`MergeResult`) | A | Report whether any per-file conflict list is non-empty. |
| [`mergeTodoData`](#mergetododata) | top-level function | A | Merge `todo_data.json`'s daily/one-time tasks, logs, scores, and settings. |
| [`TodoMergeResult` (constructor)](#todomergeresult-new) | constructor (`TodoMergeResult`) | A | Create a todo merge result bundling merged lists, logs, settings source, and conflicts. |
| [`TodoMergeResult.hasConflicts`](#todomergeresult-hasconflicts) | getter (`TodoMergeResult`) | A | Report whether the daily or one-time conflict lists are non-empty. |
| [`TodoMergeResult.buildResolved`](#todomergeresult-buildresolved) | method (`TodoMergeResult`) | A | Apply a resolutions map to pending conflicts and rebuild `TodoData`. |
| [`TodoMergeResult._resolveList`](#todomergeresult-resolvelist) | static method (`TodoMergeResult`) | A | Append conflict resolutions (or local fallback) onto the auto-merged list. |
| [`mergeFinanceData`](#mergefinancedata) | top-level function | A | Merge `finance_data.json`'s accounts/categories/transactions/subscriptions and settings. |
| [`FinanceMergeResult` (constructor)](#financemergeresult-new) | constructor (`FinanceMergeResult`) | A | Create a finance merge result bundling four merged lists, settings source, and conflicts. |
| [`FinanceMergeResult.hasConflicts`](#financemergeresult-hasconflicts) | getter (`FinanceMergeResult`) | A | Report whether any of the four record-type conflict lists is non-empty. |
| [`FinanceMergeResult.buildResolved`](#financemergeresult-buildresolved) | method (`FinanceMergeResult`) | A | Apply a resolutions map to pending conflicts and rebuild `FinanceData`. |
| [`FinanceMergeResult._resolveList`](#financemergeresult-resolvelist) | static method (`FinanceMergeResult`) | A | Same resolve-list pattern as `TodoMergeResult`, scoped to `FinanceMergeResult`. |
| [`mergeIntimacyData`](#mergeintimacydata) | top-level function | A | Merge `intimacy_data.json`'s five record collections, timer state, `userBody`, and settings. |
| [`IntimacyMergeResult` (constructor)](#intimacymergeresult-new) | constructor (`IntimacyMergeResult`) | A | Create an intimacy merge result bundling five merged lists, timer/body state, and conflicts. |
| [`IntimacyMergeResult.hasConflicts`](#intimacymergeresult-hasconflicts) | getter (`IntimacyMergeResult`) | A | Report whether any of the five record-type conflict lists is non-empty. |
| [`IntimacyMergeResult.buildResolved`](#intimacymergeresult-buildresolved) | method (`IntimacyMergeResult`) | A | Apply a resolutions map to pending conflicts and rebuild `IntimacyData`. |
| [`IntimacyMergeResult._resolveList`](#intimacymergeresult-resolvelist) | static method (`IntimacyMergeResult`) | A | Same resolve-list pattern, scoped to `IntimacyMergeResult`. |
| [`mergeExchangeRateJson`](#mergeexchangeratejson) | top-level function | A | Whole-file exchange-rate merge: union snapshots, pick the newer current snapshot and `lastFetchedAt`. |
| [`mergeWeightData`](#mergeweightdata) | top-level function | A | Merge `weight_data.json`'s records, height-via-settings, and reminder/settings. |
| [`WeightMergeResult` (constructor)](#weightmergeresult-new) | constructor (`WeightMergeResult`) | A | Create a weight merge result with default reminder mode/grace minutes. |
| `WeightMergeResult.hasConflicts` | getter (`WeightMergeResult`) | B | Report whether the record conflict list is non-empty. |
| [`WeightMergeResult.buildResolved`](#weightmergeresult-buildresolved) | method (`WeightMergeResult`) | A | Resolve pending conflicts inline and rebuild `WeightData`. |

`grep -c 'Purpose:' lib/shared/services/sync_merge.dart` reports **27**, but this file has only
**26** real declarations. The discrepancy is a single declaration documented twice: `mergeRecords<T>`
(line 72) has two stacked `/// Purpose:` blocks directly above it (lines 46-50 "Merge records into a
single result" and lines 65-71 "Merge records from the relevant sources", with plain `///` prose
in between at lines 51-64 describing the three-way algorithm) — both blocks describe the same
function, not two different declarations. No other misattachment was found: every remaining block
sits directly above the real declaration it names, and no undocumented real declaration (class body
scanned field-by-field) was found. The eight model classes in this file (`RecordConflict`,
`RecordMergeResult`, `SyncConflictInfo`, `MergeResult`, `TodoMergeResult`, `FinanceMergeResult`,
`IntimacyMergeResult`, `WeightMergeResult`) are not themselves counted as declarations — only their
constructors, getters, and methods are, consistent with the rest of this doc set.

## Documentation

### `const RecordConflict({required this.id, required this.localRecord, required this.remoteRecord, required this.displayName})` <a id="recordconflict-new"></a>
- **Kind:** const constructor of `RecordConflict<T>`
- **Source:** `lib/shared/services/sync_merge.dart` (line 25)
- **Purpose:** Carry both versions of a record that changed on both local and remote since the last
  sync, for user-facing conflict resolution.
- **Inputs:** `id`, `localRecord`, `remoteRecord`, `displayName` (a human-readable label used by the
  conflict UI).
- **Returns:** A new `RecordConflict<T>`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** Constructed by `mergeRecords<T>` (below) whenever both sides changed a record and the
  conflict cannot be auto-resolved or silently merged.
- **Notes:** None.

### `const RecordMergeResult({required this.merged, this.conflicts = const []})` <a id="recordmergeresult-new"></a>
- **Kind:** const constructor of `RecordMergeResult<T>`
- **Source:** `lib/shared/services/sync_merge.dart` (line 43)
- **Purpose:** Bundle a `mergeRecords<T>` call's merged list and any unresolved conflicts.
- **Inputs:** `merged` (required); `conflicts` (defaults to an empty list).
- **Returns:** A new `RecordMergeResult<T>`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** Returned by `mergeRecords<T>`; each `merge<Module>Data` function calls it once per
  record collection (e.g. `dailyResult = mergeRecords<Task>(...)` in `mergeTodoData`).
- **Notes:** None.

### `RecordMergeResult<T> mergeRecords<T>({required List<T> local, required List<T> remote, required List<T>? base, required String Function(T) getId, required DateTime Function(T) getModifiedAt, required String Function(T) getDisplayName, bool autoResolve = false, String Function(T)? serialize})` <a id="mergerecords"></a>
- **Kind:** top-level generic function
- **Source:** `lib/shared/services/sync_merge.dart` (line 72)
- **Purpose:** The generic three-way merge engine shared by every record collection in every data
  file — the implementation behind [Three-Way Merge](../../../algorithms/three-way-merge.md).
- **Inputs:** `local`/`remote`/`base` (the last-synced snapshot, `null` on first sync); `getId`,
  `getModifiedAt`, `getDisplayName` accessor callbacks so the engine stays type-agnostic;
  `autoResolve` (background auto-sync's conflict-avoidance mode); `serialize` (optional — when
  provided, enables byte-identical-content detection so a stale base doesn't manufacture a false
  conflict).
- **Returns:** `RecordMergeResult<T>` with `merged: List<T>` and `conflicts: List<RecordConflict<T>>`.
- **Side effects:** None (pure function over its arguments).
- **Algorithm:** See [Three-Way Merge](../../../algorithms/three-way-merge.md#the-generic-mergerecordst-engine)
  for the full per-id decision table. Summary of the actual control flow:
  1. Build id-keyed maps for `local`, `remote`, and `base` (`base` maps to an empty map when `null`).
  2. Take the union of ids across all three maps and iterate each once.
  3. **Both sides have the id, and a base entry exists:** compute `localChanged`/`remoteChanged`
     against `base.modifiedAt`. Both changed → identical `serialize` output merges silently, else
     `autoResolve` picks the newer `modifiedAt`, else a `RecordConflict` is recorded. Only one side
     changed → use that side. Neither changed → use local (arbitrary but deterministic).
  4. **Both sides have the id, no base:** last-writer-wins by `modifiedAt` (first sync, or both
     sides independently created the same id).
  5. **Only local has the id:** if it was in `base`, remote deleted it — keep local only if
     `localChanged` (an edit beats a deletion it didn't know about), otherwise exclude it; if it was
     never in `base`, it's new locally and is always included.
  6. **Only remote has the id:** the mirror image of step 5.
  7. **Neither side has the id** (both deleted, base had it): excluded — the loop body simply adds
     nothing for that id.
  8. Return `RecordMergeResult(merged: merged, conflicts: conflicts)`.
- **Usage:**
  ```dart
  final dailyResult = mergeRecords<Task>(
    local: local.dailyTemplates,
    remote: remote.dailyTemplates,
    base: base?.dailyTemplates,
    getId: (t) => t.id,
    getModifiedAt: (t) => t.modifiedAt,
    getDisplayName: (t) => '${t.emoji ?? ''} ${t.title}'.trim(),
    autoResolve: autoResolve,
    serialize: (x) => jsonEncode(x.toJson()),
  );
  ```
  (`mergeTodoData`, below — the same call shape, with different accessors, appears once per record
  collection in `mergeFinanceData`, `mergeIntimacyData`, and `mergeWeightData`.)
- **Notes:** Every one of the five module merge functions passes `serialize: (x) =>
  jsonEncode(x.toJson())` for every record type, so the "identical content, no conflict" path is
  always active in practice, not just theoretically available.

### `const SyncConflictInfo({required this.fileName, required this.displayName, required this.recordConflicts})` <a id="syncconflictinfo-new"></a>
- **Kind:** const constructor of `SyncConflictInfo`
- **Source:** `lib/shared/services/sync_merge.dart` (line 176)
- **Purpose:** Aggregate one file's record conflicts under a display name, for a generic
  multi-file conflict summary.
- **Inputs:** `fileName`, `displayName`, `recordConflicts`.
- **Returns:** A new `SyncConflictInfo`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** No call site under `lib/` — see Notes.
- **Notes:** Neither `SyncConflictInfo` nor `MergeResult` (below) is constructed anywhere in
  `webdav_service.dart` or `webdav_config_page.dart`. The actual pending-conflict bookkeeping in
  `WebDAVService` uses its own `PendingSync` class with four typed nullable fields
  (`TodoMergeResult? todoMerge`, `FinanceMergeResult? financeMerge`, `IntimacyMergeResult?
  intimacyMerge`, `WeightMergeResult? weightMerge`) rather than this generic wrapper. These two
  declarations appear to be an unused generic aggregate left over from an earlier design.

### `const MergeResult({required this.mergedJsons, this.conflicts = const []})` <a id="mergeresult-new"></a>
- **Kind:** const constructor of `MergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 196)
- **Purpose:** Bundle merged JSON strings for every file alongside any file-level conflict summaries.
- **Inputs:** `mergedJsons` (map of file name to merged JSON string, required); `conflicts` (defaults
  to empty).
- **Returns:** A new `MergeResult`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** No call site under `lib/` — see the Notes on `SyncConflictInfo` above; the same
  unused-generic-wrapper observation applies here.
- **Notes:** Unused elsewhere in the repo (see `SyncConflictInfo` notes above).

### `bool get hasConflicts` (on `MergeResult`) <a id="mergeresult-hasconflicts"></a>
- **Kind:** getter of `MergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 203)
- **Purpose:** Report whether any per-file `SyncConflictInfo` in `conflicts` actually carries record
  conflicts.
- **Inputs:** None (reads `conflicts`).
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `conflicts.any((c) => c.recordConflicts.isNotEmpty)` — true if at least one file's
  conflict list is non-empty (a `SyncConflictInfo` entry with an empty `recordConflicts` list does
  not count).
- **Usage:** Not called elsewhere in `lib/` (see `MergeResult` notes above — this class is unused).
- **Notes:** Same unused-declaration caveat as the constructor above.

### `TodoMergeResult mergeTodoData(String localJson, String remoteJson, String? baseJson, {bool autoResolve = false})` <a id="mergetododata"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/services/sync_merge.dart` (line 214)
- **Purpose:** Merge `todo_data.json` per the [Sync Data Reference](../../../sync.md#sync-data-reference)
  row: daily/one-time tasks by id + `modifiedAt`, daily log union, daily score LWW per date, settings
  LWW.
- **Inputs:** `localJson`/`remoteJson` (required, current file contents); `baseJson` (last-synced
  snapshot, `null` on first sync); `autoResolve` (background auto-sync mode).
- **Returns:** `TodoMergeResult`.
- **Side effects:** None (pure function over its string arguments; no I/O).
- **Algorithm:**
  1. `TodoData.fromJson(jsonDecode(...))` each of `localJson`/`remoteJson`, and `baseJson` if
     non-null.
  2. `mergeRecords<Task>` for `dailyTemplates`, then again for `oneTimeTasks` — both keyed by `id`
     and `modifiedAt`, display name `'${emoji ?? ''} ${title}'.trim()`, content-`serialize`
     deduplication enabled.
  3. `DailyCompletionLog.merge(local.dailyLog, remote.dailyLog)` — union of completed task/subtask
     ids per date (see [Three-Way Merge](../../../algorithms/three-way-merge.md#deletionunion-semantics-for-specific-containers)).
  4. `DailyScoreLog.merge(local.dailyScores, remote.dailyScores)` — per-date LWW by
     `DailyScoreEntry.modifiedAt`, ties favor local.
  5. Settings LWW: `useLocalSettings = local.settingsModifiedAt.isAfter(remote.settingsModifiedAt) ||
     local.settingsModifiedAt == remote.settingsModifiedAt` — local wins strict-newer or exact ties.
  6. Return a `TodoMergeResult` bundling both merged task lists, the merged log/scores, the winning
     settings source, and both collections' unresolved conflicts.
- **Usage:**
  ```dart
  var result = mergeTodoData(currentLocalJson, currentRemoteJson, baseJson, autoResolve: autoResolve);
  // ... re-read local file in case it changed during network I/O ...
  if (freshLocalJson != currentLocalJson) {
    currentLocalJson = freshLocalJson;
    result = mergeTodoData(currentLocalJson, currentRemoteJson, baseJson, autoResolve: autoResolve);
  }
  ```
  (`lib/shared/services/webdav_service.dart`, the `todo_data.json` case of the per-file sync loop,
  around line 1676 — the re-merge-on-fresh-read pattern is the "local files are re-read before
  write" rule from [WebDAV Sync](../../../sync.md#retry-heartbeat-and-wake-lock).)
- **Notes:** None beyond what's linked above.

### `const TodoMergeResult({required this.dailyMerged, required this.onceMerged, required this.mergedLog, required this.mergedScores, required this.settingsSource, required this.dailyConflicts, required this.onceConflicts})` <a id="todomergeresult-new"></a>
- **Kind:** const constructor of `TodoMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 288)
- **Purpose:** Bundle `mergeTodoData`'s output: two merged task lists, the merged log/scores, the
  winning settings source, and both lists' unresolved conflicts.
- **Inputs:** All seven fields, all required.
- **Returns:** A new `TodoMergeResult`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** Constructed by `mergeTodoData`'s final `return` statement.
- **Notes:** None.

### `bool get hasConflicts` (on `TodoMergeResult`) <a id="todomergeresult-hasconflicts"></a>
- **Kind:** getter of `TodoMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 303)
- **Purpose:** Report whether either the daily-template or one-time-task merge left an unresolved
  conflict.
- **Inputs:** None.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `dailyConflicts.isNotEmpty || onceConflicts.isNotEmpty`.
- **Usage:**
  ```dart
  if (result.hasConflicts) {
    pendingTodo = result;
  } else {
    final mergedData = result.buildResolved(const {});
    ...
  }
  ```
  (`webdav_service.dart`, `todo_data.json` case — gates whether the file uploads immediately or
  waits for the user via `finalizePendingSync`.)
- **Notes:** None.

### `TodoData buildResolved(Map<String, dynamic> resolutions)` (on `TodoMergeResult`) <a id="todomergeresult-buildresolved"></a>
- **Kind:** method of `TodoMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 312)
- **Purpose:** Apply the shared cross-module resolutions map to this file's pending conflicts and
  rebuild a complete `TodoData`.
- **Inputs:** `resolutions` — the same mixed-type map passed to every module's `buildResolved` in
  the same `finalizePendingSync` call (see
  [the cross-module mixed-resolutions-map rule](../../../sync.md#the-cross-module-mixed-resolutions-map-safety-rule)).
- **Returns:** `TodoData`.
- **Side effects:** None (pure; the caller is responsible for persisting/uploading the result).
- **Algorithm:**
  1. `_resolveList(dailyMerged, dailyConflicts, resolutions)` and `_resolveList(onceMerged,
     onceConflicts, resolutions)` (see `_resolveList` below).
  2. Construct `TodoData` from the resolved lists, the already-merged log/scores, and every settings
     field copied from `settingsSource`.
- **Usage:**
  ```dart
  final mergedData = result.buildResolved(const {});
  ```
  (`webdav_service.dart`, no-conflict path — an empty map, since `_resolveList` only touches ids that
  actually appear in `conflicts`.) Also:
  ```dart
  final mergedData = pending.todoMerge!.buildResolved(resolutions);
  ```
  (`webdav_service.dart`, `finalizePendingSync`, around line 1930 — the user-resolved path.)
- **Notes:** Only entries in `resolutions` whose value `is Task` are applied, via `_resolveList`'s
  type check — a Finance or Intimacy resolution in the same shared map is silently skipped here, not
  an error.

### `static List<T> _resolveList<T>(List<T> merged, List<RecordConflict<T>> conflicts, Map<String, dynamic> resolutions)` (on `TodoMergeResult`) <a id="todomergeresult-resolvelist"></a>
- **Kind:** private static generic method of `TodoMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 337)
- **Purpose:** Append each conflict's resolution (or the local record, as a safe default) onto the
  already-auto-merged list.
- **Inputs:** `merged` (records mergeRecords already resolved without conflict); `conflicts`
  (unresolved `RecordConflict<T>` entries); `resolutions` (the shared cross-module map).
- **Returns:** `List<T>` — `merged` plus one entry per conflict.
- **Side effects:** None.
- **Algorithm:** Copy `merged` into a new list; for each `c` in `conflicts`, look up
  `resolutions[c.id]` and append it if `resolved is T`, else append `c.localRecord`.
- **Usage:** Called twice by `buildResolved` above, once for `dailyMerged`/`dailyConflicts` and once
  for `onceMerged`/`onceConflicts`.
- **Notes:** Unresolved or mistyped entries default to the local record so a conflicting record is
  never silently dropped — this is the mechanism underpinning the safety rule described in
  [WebDAV Sync](../../../sync.md#the-cross-module-mixed-resolutions-map-safety-rule). This exact
  method body (module-appropriate type parameter aside) is repeated verbatim in `FinanceMergeResult`
  and `IntimacyMergeResult` rather than shared — each module owns its own private copy.

### `FinanceMergeResult mergeFinanceData(String localJson, String remoteJson, String? baseJson, {bool autoResolve = false})` <a id="mergefinancedata"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/services/sync_merge.dart` (line 358)
- **Purpose:** Merge `finance_data.json` per the [Sync Data Reference](../../../sync.md#sync-data-reference)
  row: accounts/categories/transactions/subscriptions by id + `modifiedAt`, settings LWW.
- **Inputs:** Same shape as `mergeTodoData`.
- **Returns:** `FinanceMergeResult`.
- **Side effects:** None.
- **Algorithm:**
  1. Parse `local`/`remote`/`base` `FinanceData`.
  2. Four independent `mergeRecords` calls, one each for `Account`, `Category`, `Transaction`,
     `Subscription` — each keyed by `id`/`modifiedAt` with a module-specific `getDisplayName` (e.g.
     transactions use `'${note.isNotEmpty ? note : type.name} (${amount})'`) and content-`serialize`
     dedup.
  3. Settings LWW identical in shape to `mergeTodoData`'s (local wins strict-newer or exact ties).
  4. Return `FinanceMergeResult` bundling all four merged lists, the settings source, and all four
     conflict lists.
- **Usage:**
  ```dart
  var result = mergeFinanceData(currentLocalJson, currentRemoteJson, baseJson, autoResolve: autoResolve);
  ```
  (`webdav_service.dart`, `finance_data.json` case, around line 1717 — same re-merge-on-fresh-read
  pattern as `mergeTodoData`.)
- **Notes:** None beyond what's linked above.

### `const FinanceMergeResult({...})` <a id="financemergeresult-new"></a>
- **Kind:** const constructor of `FinanceMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 453)
- **Purpose:** Bundle `mergeFinanceData`'s output: four merged lists, the settings source, and four
  conflict lists.
- **Inputs:** Nine required fields (four merged lists, settings source, four conflict lists).
- **Returns:** A new `FinanceMergeResult`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** Constructed by `mergeFinanceData`'s final `return` statement.
- **Notes:** None.

### `bool get hasConflicts` (on `FinanceMergeResult`) <a id="financemergeresult-hasconflicts"></a>
- **Kind:** getter of `FinanceMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 470)
- **Purpose:** Report whether any of the four record-type conflict lists is non-empty.
- **Inputs:** None.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `accountConflicts.isNotEmpty || categoryConflicts.isNotEmpty ||
  transactionConflicts.isNotEmpty || subscriptionConflicts.isNotEmpty`.
- **Usage:** Same gating pattern as `TodoMergeResult.hasConflicts`, in the `finance_data.json` case
  of `webdav_service.dart`'s sync loop.
- **Notes:** None.

### `FinanceData buildResolved(Map<String, dynamic> resolutions)` (on `FinanceMergeResult`) <a id="financemergeresult-buildresolved"></a>
- **Kind:** method of `FinanceMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 481)
- **Purpose:** Apply the shared resolutions map to all four of this file's conflict lists and rebuild
  a complete `FinanceData`.
- **Inputs:** `resolutions`.
- **Returns:** `FinanceData`.
- **Side effects:** None.
- **Algorithm:** `_resolveList` once per record type (accounts/categories/transactions/
  subscriptions), then construct `FinanceData` from the four resolved lists plus every settings
  field copied from `settingsSource` (currency, subscription reminder hour/minute, sort modes/custom
  orders, account picker settings).
- **Usage:**
  ```dart
  final mergedData = await _migrateFinanceForcedBalances(result.buildResolved(const {}));
  ```
  (`webdav_service.dart`, `finance_data.json` no-conflict path — the result is piped through a
  balance-migration step before upload, unlike the other three modules.) Also
  `pending.financeMerge!.buildResolved(resolutions)` in `finalizePendingSync`.
- **Notes:** Only entries whose value `is Account`/`is Category`/`is Transaction`/`is Subscription`
  (matched per list by `_resolveList`'s own type parameter) are applied — a Todo or Intimacy
  resolution in the same map is skipped for each individual list, not just for the file as a whole.

### `static List<T> _resolveList<T>(...)` (on `FinanceMergeResult`) <a id="financemergeresult-resolvelist"></a>
- **Kind:** private static generic method of `FinanceMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 516)
- **Purpose:** Same resolve-list pattern as `TodoMergeResult._resolveList`, scoped to
  `FinanceMergeResult`.
- **Inputs:** `merged`, `conflicts`, `resolutions`.
- **Returns:** `List<T>`.
- **Side effects:** None.
- **Algorithm:** Identical to `TodoMergeResult._resolveList` (see above) — copy `merged`, then append
  `resolutions[c.id]` per conflict if type-matched, else `c.localRecord`.
- **Usage:** Called four times by `FinanceMergeResult.buildResolved`, once per record type.
- **Notes:** Same "default to local, never drop" guarantee as `TodoMergeResult._resolveList`.

### `IntimacyMergeResult mergeIntimacyData(String localJson, String remoteJson, String? baseJson, {bool autoResolve = false})` <a id="mergeintimacydata"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/services/sync_merge.dart` (line 539)
- **Purpose:** Merge `intimacy_data.json` per the [Sync Data Reference](../../../sync.md#sync-data-reference)
  row — the widest merge function in this file: five id-keyed record collections plus three
  independently-timestamped LWW fields.
- **Inputs:** Same shape as `mergeTodoData`.
- **Returns:** `IntimacyMergeResult`.
- **Side effects:** None.
- **Algorithm:**
  1. Parse `local`/`remote`/`base` `IntimacyData`.
  2. Five `mergeRecords` calls: `Partner`, `Toy`, `Position`, `IntimacyRecord` (display name
     `'${type} (${datetime...substring(0,10)})'`), and `CycleRecord` (display name is just `date`).
     `CycleRecord` is add/delete-only in the UI, so the generic engine's "deleted on one side,
     unchanged on other → exclude" rule *is* cycle-record deletion propagation — see
     [Three-Way Merge](../../../algorithms/three-way-merge.md#deletionunion-semantics-for-specific-containers).
     Note that `partner.body` is not merged separately: it rides inside each `Partner` record through
     the ordinary `Partner` merge above.
  3. Timer history: union by start time — `mergedTimerHistory = [...local.timerHistory,
     ...remote.timerHistory.where((e) => !localStarts.contains(e.start.toIso8601String()))]`, where
     `localStarts` is the set of local entries' `start.toIso8601String()`. Simple dedup by exact ISO
     string equality, no conflict tracking (timer history entries are never edited, only appended).
  4. Three independent LWW picks, each using the "isAfter || ==" (local-wins-on-tie) pattern:
     `timerSession`/`timerSessionModifiedAt` by `timerSessionModifiedAt`; `userBody`/
     `userBodyModifiedAt` by `userBodyModifiedAt`; every settings field (`timerHistoryRetentionDays`,
     `partnerSortModes`/`partnerCustomOrders`, `toySortModes`/`toyCustomOrders`) by
     `settingsModifiedAt`.
  5. Return `IntimacyMergeResult` bundling all five merged lists, the three LWW picks, and all five
     conflict lists.
- **Usage:**
  ```dart
  var result = mergeIntimacyData(currentLocalJson, currentRemoteJson, baseJson, autoResolve: autoResolve);
  ```
  (`webdav_service.dart`, `intimacy_data.json` case, around line 1764.)
- **Notes:** This is the only one of the four `mergeRecords`-based module functions with three
  separate non-record LWW fields (timer session, user body, settings) rather than one; each is keyed
  by its own `*ModifiedAt` field, so touching one (e.g. ending a timer session) does not affect which
  side wins for `userBody` or settings.

### `const IntimacyMergeResult({...})` <a id="intimacymergeresult-new"></a>
- **Kind:** const constructor of `IntimacyMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 706)
- **Purpose:** Bundle `mergeIntimacyData`'s output: five merged lists, timer/body/settings state, and
  five conflict lists.
- **Inputs:** 20 required fields.
- **Returns:** A new `IntimacyMergeResult`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** Constructed by `mergeIntimacyData`'s final `return` statement.
- **Notes:** None.

### `bool get hasConflicts` (on `IntimacyMergeResult`) <a id="intimacymergeresult-hasconflicts"></a>
- **Kind:** getter of `IntimacyMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 735)
- **Purpose:** Report whether any of the five record-type conflict lists (partner/toy/position/
  record/cycleRecord) is non-empty.
- **Inputs:** None.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** Five-way `||` chain of `.isNotEmpty` checks across `partnerConflicts`,
  `toyConflicts`, `positionConflicts`, `recordConflicts`, `cycleRecordConflicts`.
- **Usage:** Same gating pattern as the other modules' `hasConflicts`, in the `intimacy_data.json`
  case of `webdav_service.dart`'s sync loop.
- **Notes:** None.

### `IntimacyData buildResolved(Map<String, dynamic> resolutions)` (on `IntimacyMergeResult`) <a id="intimacymergeresult-buildresolved"></a>
- **Kind:** method of `IntimacyMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 747)
- **Purpose:** Apply the shared resolutions map to all five conflict lists and rebuild a complete
  `IntimacyData`.
- **Inputs:** `resolutions`.
- **Returns:** `IntimacyData`.
- **Side effects:** None.
- **Algorithm:** `_resolveList` once per record type (partners/toys/positions/records/cycleRecords),
  then construct `IntimacyData` passing through the already-merged `timerHistory`, `timerSession`,
  `userBody`, and settings fields untouched (only the five record lists go through conflict
  resolution; the LWW-picked fields were already finalized in `mergeIntimacyData`).
- **Usage:** `pending.intimacyMerge!.buildResolved(resolutions)` in `finalizePendingSync`; also
  `result.buildResolved(const {})` in the no-conflict path of `webdav_service.dart`'s
  `intimacy_data.json` case.
- **Notes:** Same cross-module type-check safety as `TodoMergeResult.buildResolved` — a Finance
  resolution in the same map cannot be mistakenly applied to an Intimacy record because
  `_resolveList<T>`'s `is T` check rejects it.

### `static List<T> _resolveList<T>(...)` (on `IntimacyMergeResult`) <a id="intimacymergeresult-resolvelist"></a>
- **Kind:** private static generic method of `IntimacyMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 777)
- **Purpose:** Same resolve-list pattern as `TodoMergeResult._resolveList`, scoped to
  `IntimacyMergeResult`.
- **Inputs:** `merged`, `conflicts`, `resolutions`.
- **Returns:** `List<T>`.
- **Side effects:** None.
- **Algorithm:** Identical to the other two `_resolveList` copies.
- **Usage:** Called five times by `IntimacyMergeResult.buildResolved`, once per record type.
- **Notes:** Same "default to local, never drop" guarantee.

### `String mergeExchangeRateJson(String localJson, String remoteJson)` <a id="mergeexchangeratejson"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/services/sync_merge.dart` (line 801)
- **Purpose:** The one merge function in this file that does not use `mergeRecords` at all — rate
  snapshots never conflict, so `exchange_rates.json` is merged as a whole-file union rather than
  per-record, per the [Sync Data Reference](../../../sync.md#sync-data-reference) row.
- **Inputs:** `localJson`, `remoteJson` (no `baseJson`/`autoResolve` — this function has no base
  three-way comparison and never returns conflicts).
- **Returns:** `String` — the merged `ExchangeRateData` re-encoded as JSON (unlike every other
  `merge*Data` function, which returns a typed `*MergeResult`).
- **Side effects:** None.
- **Algorithm:**
  1. Parse `local`/`remote` `ExchangeRateData`.
  2. `mergedSnapshots = {...local.snapshots, ...remote.snapshots}` — a plain map spread union; if
     both sides happen to hold a snapshot under the same id, the remote copy silently wins since it
     is spread second (not observed as reachable in practice, since snapshot ids are freshly
     generated per fetch).
  3. Resolve each side's own current snapshot via `local.snapshots[local.currentSnapshotId]` /
     `remote.snapshots[remote.currentSnapshotId]` against *that side's own* map (not the merged map).
  4. Pick the merged `currentSnapshotId`: if both sides' current ids resolve, take whichever has the
     later `createdAt`; else if only remote's resolves, take remote's id; else take local's id.
  5. Pick `lastFetchedAt` as whichever of the two non-null values is later (`??` fallback if only one
     side is non-null).
  6. Re-encode `ExchangeRateData(currentSnapshotId: currentId, snapshots: mergedSnapshots,
     lastFetchedAt: mergedLastFetched)` to a JSON string and return it.
- **Usage:**
  ```dart
  final mergedJson = _preserveUnknownJson(
    name,
    mergeExchangeRateJson(localJson, remoteJson),
    baseJson: baseJson,
    localJson: localJson,
    remoteJson: remoteJson,
  );
  ```
  (`webdav_service.dart`, around line 1649 — the exchange-rate case of the per-file sync loop; it is
  the only case that skips the `hasConflicts` branch entirely, since this function cannot produce
  conflicts.)
- **Notes:** The doc comment above this function (and the header comment above it) frame a dangling
  `currentSnapshotId` as always "ignored", but by source inspection this holds only when the *other*
  side's current id resolves: if **both** sides' current ids fail to resolve against their own
  snapshots (`localCurrent == null && remoteCurrent == null`), the code falls to the final `else`
  branch and still assigns `currentId = local.currentSnapshotId` — propagating local's
  non-resolving id rather than falling back to some other value. This branch requires both sides to
  independently hold an already-dangling current id, which the app's own write paths are not
  expected to produce, but it is a real gap between the comment's stated guarantee and the literal
  code.

### `WeightMergeResult mergeWeightData(String localJson, String remoteJson, String? baseJson, {bool autoResolve = false})` <a id="mergeweightdata"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/services/sync_merge.dart` (line 855)
- **Purpose:** Merge `weight_data.json` per the [Sync Data Reference](../../../sync.md#sync-data-reference)
  row: records by id + `modifiedAt`; height follows settings LWW; reminder/settings LWW.
- **Inputs:** Same shape as `mergeTodoData`.
- **Returns:** `WeightMergeResult`.
- **Side effects:** None.
- **Algorithm:**
  1. Parse `local`/`remote`/`base` `WeightData`.
  2. `mergeRecords<WeightRecord>` keyed by `id`/`modifiedAt`, display name `'${weight} kg
     (${datetime...substring(0,10)})'`, content-`serialize` dedup.
  3. `settingsSrc = local.settingsModifiedAt.isAfter(remote.settingsModifiedAt) ? local : remote` —
     **note the missing `|| isAtSameMomentAs`/`==` tie-break** that every other module's settings LWW
     in this file has. On an exact `settingsModifiedAt` tie, `mergeTodoData`/`mergeFinanceData`/
     `mergeIntimacyData` all favor **local**, while `mergeWeightData` favors **remote** (`isAfter`
     alone is `false` on a tie, so the ternary's `false` branch — `remote` — is taken). See Notes.
  4. `height = settingsSrc.height` — height is not its own record or its own timestamp; it rides
     whichever side wins the settings LWW. The source comment explains why: saving weight data bumps
     `settingsModifiedAt` on that side, so clearing height on one device still propagates instead of
     being resurrected by a stale height value from the losing side.
  5. Return `WeightMergeResult` with `height`, the merged records/conflicts, and the settings-source's
     `reminderMode`/morning-evening hour-minute fields/`reminderGraceMinutes`/`settingsModifiedAt`.
- **Usage:**
  ```dart
  var result = mergeWeightData(currentLocalJson, currentRemoteJson, baseJson, autoResolve: autoResolve);
  ```
  (`webdav_service.dart`, `weight_data.json` case, around line 1809.)
- **Notes:** The tie-break asymmetry described in step 3 is a real, source-verified difference from
  the other three modules' settings-merge functions in this same file — it is not documented in
  `AGENTS.md`'s Sync Data Reference table or in `sync.md`/`three-way-merge.md`, both of which describe
  Weight's settings strategy simply as "reminder/settings LWW" without calling out the tie
  direction. Practically, an exact-timestamp tie on `settingsModifiedAt` from two independent devices
  is rare, but it is a genuine behavioral inconsistency worth knowing before relying on
  local-wins-on-tie for this file specifically.

### `WeightMergeResult({required this.height, required this.recordsMerged, required this.recordConflicts, this.reminderMode = 'none', this.morningHour, this.morningMinute, this.eveningHour, this.eveningMinute, this.reminderGraceMinutes = 180, DateTime? settingsModifiedAt})` <a id="weightmergeresult-new"></a>
- **Kind:** (non-const) constructor of `WeightMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 925)
- **Purpose:** Bundle `mergeWeightData`'s output, applying defaults for reminder fields that a
  caller might omit.
- **Inputs:** `height`, `recordsMerged`, `recordConflicts` required; `reminderMode` defaults to
  `'none'`; `morningHour`/`morningMinute`/`eveningHour`/`eveningMinute` default to `null`;
  `reminderGraceMinutes` defaults to `180`; `settingsModifiedAt` is nullable in the parameter list.
- **Returns:** A new `WeightMergeResult`.
- **Side effects:** None.
- **Algorithm:** Field-initializing constructor, except `settingsModifiedAt` is computed in the
  initializer list as `settingsModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0)` — a `null` input
  becomes the Unix epoch rather than staying `null`, since the field itself is non-nullable
  `DateTime`.
- **Usage:** Constructed by `mergeWeightData`'s final `return` statement, which always supplies a
  non-null `settingsModifiedAt` in practice (`settingsSrc.settingsModifiedAt`).
- **Notes:** This is not a `const` constructor (unlike `TodoMergeResult`/`FinanceMergeResult`/
  `IntimacyMergeResult`), because the initializer-list `??` computation is not a constant expression.
  The `180`-minute default for `reminderGraceMinutes` and `'none'` default for `reminderMode` are the
  exact fallback values a caller gets if those named parameters are omitted entirely (distinct from
  what `mergeWeightData` itself actually passes, which always comes from `settingsSrc`).

### `bool get hasConflicts` (on `WeightMergeResult`) — Tier B
Index row only. `recordConflicts.isNotEmpty` — a single-field passthrough with no combination logic,
unlike the other four modules' `hasConflicts` getters, which OR together multiple conflict lists.

### `WeightData buildResolved(Map<String, dynamic> resolutions)` (on `WeightMergeResult`) <a id="weightmergeresult-buildresolved"></a>
- **Kind:** method of `WeightMergeResult`
- **Source:** `lib/shared/services/sync_merge.dart` (line 951)
- **Purpose:** Apply the shared resolutions map to the record conflicts and rebuild a complete
  `WeightData`.
- **Inputs:** `resolutions`.
- **Returns:** `WeightData`.
- **Side effects:** None.
- **Algorithm:** Unlike the other three modules, this method does **not** delegate to a private
  `_resolveList` helper — it inlines the same loop directly: copy `recordsMerged` into `result`, then
  for each `c` in `recordConflicts`, append `resolutions[c.id]` if `resolved is WeightRecord`, else
  `c.localRecord`. Then construct `WeightData` from the resolved records plus `height`,
  `reminderMode`, the four hour/minute fields, `reminderGraceMinutes`, and `settingsModifiedAt`
  carried straight through from `this`.
- **Usage:** `pending.weightMerge!.buildResolved(resolutions)` in `finalizePendingSync`; also
  `result.buildResolved(const {})` in the no-conflict path of `webdav_service.dart`'s
  `weight_data.json` case.
- **Notes:** Functionally identical to the `_resolveList` pattern used by the other three modules
  (same "default to local on unresolved/mistyped" guarantee), just inlined rather than factored into
  a named private method — `WeightMergeResult` has only one record collection to resolve, so a
  reusable helper would save nothing here.

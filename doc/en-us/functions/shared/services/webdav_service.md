# lib/shared/services/webdav_service.dart

`WebDAVService` is the WebDAV transport and sync-orchestration engine for MyDay: a single static
utility class (no instance state beyond a few private flags) that owns HTTP PUT/GET/DELETE/PROPFIND
calls, the remote `.lock` upload-mutex protocol, retry/backoff, the lock heartbeat, and the 10-step
sync flow that drives per-record three-way merge across all five app data files (`todo_data.json`,
`finance_data.json`, `exchange_rates.json`, `intimacy_data.json`, `weight_data.json`) plus referenced
images. It delegates the actual field-level merge logic to `mergeTodoData`/`mergeFinanceData`/
`mergeIntimacyData`/`mergeWeightData`/`mergeExchangeRateJson` in `lib/shared/services/sync_merge.dart`
(documented separately), and delegates *when* auto-sync runs to
`lib/shared/services/auto_sync_service.dart` (also documented separately) — this file only decides
*how* one sync/force-upload/force-download cycle behaves once triggered. See
[WebDAV Sync](../../../sync.md) for the full 10-step flow, retry policy, lock TTL/heartbeat, and
image-sync rules already written up at the concept level, and
[Three-Way Merge](../../../algorithms/three-way-merge.md) for the generic merge engine this file
calls into. This is the largest service file in the app (2291 lines); the walkthrough at
[Sync Walkthrough](../../../examples/sync-walkthrough.md) traces a concrete cross-module conflict
through `_syncLocked` and `finalizePendingSync`.

The file also defines the small immutable model types the service operates on: `WebDAVConfig`
(persisted connection settings), `SyncResult`/`PendingSync` (sync outcome and pending conflicts),
`WebDAVUploadLock` (the `.lock` file contents), the internal `_UploadSession` marker, and
`RemoteFile`/`RemoteFileStatus` (a discriminated download outcome that is the load-bearing
found/notFound/error distinction described in `sync.md` step 2).

## Declarations

Anchor note: two method names are reused across two different model classes in this file
(`toJson` and `fromJson`, on both `WebDAVConfig` and `WebDAVUploadLock`). To keep anchors unique on
this single page, those four rows use a class-qualified anchor (`webdavconfig-tojson`,
`webdavuploadlock-tojson`, etc.) instead of the bare-name anchor the general rule would otherwise
produce; every other row uses the plain bare-name anchor.

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`WebDAVConfig()`](#webdavconfig-new) | constructor (`WebDAVConfig`) | A | Create a persisted WebDAV connection config. |
| `isConfigured` | getter (`WebDAVConfig`) | B | Whether server URL, username, and password are all non-empty. |
| [`copyWith`](#copywith) | method (`WebDAVConfig`) | A | Copy with `autoSync` optionally replaced. |
| [`toJson`](#webdavconfig-tojson) | method (`WebDAVConfig`) | A | Serialize to the persisted/synced JSON format. |
| [`WebDAVConfig.fromJson`](#webdavconfig-fromjson) | factory constructor (`WebDAVConfig`) | A | Parse a config from JSON, defaulting missing fields. |
| [`WebDAVConfig.nextcloud`](#webdavconfig-nextcloud) | factory constructor (`WebDAVConfig`) | A | Build a config preset with the Nextcloud DAV URL pattern. |
| [`SyncResult()`](#syncresult-new) | constructor (`SyncResult`) | A | Create a sync outcome value (success/error/pending/warnings). |
| `hasConflicts` | getter (`SyncResult`) | B | Whether `pending` is non-null. |
| [`PendingSync()`](#pendingsync-new) | constructor (`PendingSync`) | A | Bundle the four possible per-module merge results with conflicts. |
| [`allConflicts`](#allconflicts) | getter (`PendingSync`) | A | Flatten every module's record conflicts into one list. |
| [`WebDAVUploadLock()`](#webdavuploadlock-new) | constructor (`WebDAVUploadLock`) | A | Create a `.lock` file value (client id, token, times, TTL). |
| [`WebDAVUploadLock.fromJson`](#webdavuploadlock-fromjson) | factory constructor (`WebDAVUploadLock`) | A | Parse a lock from the remote `.lock` JSON. |
| [`toJson`](#webdavuploadlock-tojson) | method (`WebDAVUploadLock`) | A | Serialize to the remote `.lock` JSON format. |
| [`isExpired`](#isexpired) | method (`WebDAVUploadLock`) | A | Whether the lock's TTL has elapsed as of `now`. |
| `matches` | method (`WebDAVUploadLock`) | B | Whether `clientId`/`token` match this lock's owner. |
| [`refreshed`](#refreshed) | method (`WebDAVUploadLock`) | A | Return a copy with `updatedAt` bumped, same owner/token. |
| `_UploadSession()` | constructor (`_UploadSession`) | B | Trivial forwarding constructor for the in-memory lock-ownership marker. |
| `RemoteFileStatus` (enum) | enum | B | `found` / `notFound` / `error` — no Purpose block (see Reconciliation). |
| `RemoteFile.found` | constructor (`RemoteFile`) | B | Tag a download result as found, with content/etag. |
| `RemoteFile.notFound` | constructor (`RemoteFile`) | B | Tag a download result as HTTP 404. |
| `RemoteFile.failure` | constructor (`RemoteFile`) | B | Tag a download result as any other failure. |
| [`consumeLocalDataChanged`](#consumelocaldatachanged) | static method (`WebDAVService`) | A | Read-and-reset the "local files changed" flag. |
| [`_reportProgress`](#reportprogress) | static method (`WebDAVService`) | A | Publish a `SyncProgress` snapshot to the `progress` notifier. |
| [`_withRetry`](#withretry) | static method (`WebDAVService`) | A | Generic retry/backoff wrapper for transient network failures. |
| [`_migrateFinanceForcedBalances`](#migratefinanceforcedbalances) | static method (`WebDAVService`) | A | Run legacy forced-balance migration on merged finance data. |
| [`loadConfig`](#loadconfig) | static method (`WebDAVService`) | A | Load the persisted `WebDAVConfig`, or null. |
| [`saveConfig`](#saveconfig) | static method (`WebDAVService`) | A | Persist a `WebDAVConfig` to local storage. |
| [`deleteConfig`](#deleteconfig) | static method (`WebDAVService`) | A | Delete the persisted config file. |
| [`_getBaseDir`](#getbasedir) | static method (`WebDAVService`) | A | Get (creating if needed) the `.sync_base/` directory. |
| [`_readBase`](#readbase) | static method (`WebDAVService`) | A | Read a last-synced base snapshot file. |
| [`_saveBase`](#savebase) | static method (`WebDAVService`) | A | Atomically write a base snapshot file. |
| [`_loadClientId`](#loadclientid) | static method (`WebDAVService`) | A | Load or create the stable local client id. |
| [`_readLocalUploadLock`](#readlocaluploadlock) | static method (`WebDAVService`) | A | Read the local `upload_lock.json` marker. |
| [`_saveLocalUploadLock`](#savelocaluploadlock) | static method (`WebDAVService`) | A | Write the local upload-lock marker before uploading. |
| [`_clearLocalUploadLock`](#clearlocaluploadlock) | static method (`WebDAVService`) | A | Delete the local upload-lock marker. |
| [`_atomicWrite`](#atomicwrite) | static method (`WebDAVService`) | A | Write-to-temp-then-rename helper used by every local file write. |
| [`_preserveUnknownJson`](#preserveunknownjson) | static method (`WebDAVService`) | A | Re-inject unknown JSON fields dropped by the merge round-trip. |
| [`_finalizeFile`](#finalizefile) | static method (`WebDAVService`) | A | Write+upload+rebase one file's user-resolved conflict result. |
| [`_uploadMergedJson`](#uploadmergedjson) | static method (`WebDAVService`) | A | Write+upload+rebase one file's auto-merged (no-conflict) result. |
| [`_authHeaders`](#authheaders) | static method (`WebDAVService`) | A | Build the HTTP Basic auth header from config credentials. |
| [`_remoteFileUrl`](#remotefileurl) | static method (`WebDAVService`) | A | Join server URL + remote path + file name into a request URL. |
| [`testConnection`](#testconnection) | static method (`WebDAVService`) | A | PROPFIND the remote root to verify credentials/reachability. |
| [`_ensureRemoteDir`](#ensureremotedir) | static method (`WebDAVService`) | A | MKCOL the remote sync root directory (best-effort). |
| [`_upload`](#upload) | static method (`WebDAVService`) | A | Low-level conditional PUT with retry, used for data and `.lock`. |
| [`_strongEtag`](#strongetag) | static method (`WebDAVService`) | A | Return an ETag only if it is strong (not `W/...`). |
| [`_uploadBytes`](#uploadbytes) | static method (`WebDAVService`) | A | Low-level binary PUT with retry, used for images. |
| [`_download`](#download) | static method (`WebDAVService`) | A | GET a remote file with a found/notFound/error discriminated result. |
| [`_readRemoteUploadLock`](#readremoteuploadlock) | static method (`WebDAVService`) | A | Download and parse the remote `.lock` file. |
| [`_writeRemoteUploadLock`](#writeremoteuploadlock) | static method (`WebDAVService`) | A | PUT a lock value to the remote `.lock` path. |
| [`_deleteRemoteUploadLock`](#deleteremoteuploadlock) | static method (`WebDAVService`) | A | DELETE the remote `.lock` file (best-effort). |
| [`_prepareInterruptedUpload`](#prepareinterruptedupload) | static method (`WebDAVService`) | A | Detect and resume/clear a lock left by a crashed previous upload. |
| [`_acquireUploadSession`](#acquireuploadsession) | static method (`WebDAVService`) | A | Acquire the remote upload lock, blocking on an active foreign lock. |
| [`_refreshUploadLock`](#refreshuploadlock) | static method (`WebDAVService`) | A | Re-write the lock's `updatedAt` before/during a PUT. |
| [`_withLockHeartbeat`](#withlockheartbeat) | static method (`WebDAVService`) | A | Run an operation while heartbeat-refreshing the lock every 20s. |
| [`_uploadWithSession`](#uploadwithsession) | static method (`WebDAVService`) | A | Refresh the lock then PUT data JSON under heartbeat. |
| [`_uploadBytesWithSession`](#uploadbyteswithsession) | static method (`WebDAVService`) | A | Refresh the lock then PUT image bytes under heartbeat. |
| [`_releaseUploadSession`](#releaseuploadsession) | static method (`WebDAVService`) | A | Delete the remote/local lock if we still own it. |
| [`_ensureRemoteSubDir`](#ensureremotesubdir) | static method (`WebDAVService`) | A | MKCOL a remote sub-directory such as `images/` (best-effort). |
| [`_listRemoteDir`](#listremotedir) | static method (`WebDAVService`) | A | PROPFIND-list file names in a remote sub-directory. |
| [`_downloadBytes`](#downloadbytes) | static method (`WebDAVService`) | A | GET binary content with retry, used for images. |
| [`_getReferencedImageNames`](#getreferencedimagenames) | static method (`WebDAVService`) | A | Extract image basenames referenced by finance/intimacy records. |
| [`_syncImages`](#syncimages) | static method (`WebDAVService`) | A | Reference-gated additive bidirectional image sync. |
| [`sync`](#sync) | static method (`WebDAVService`) | A | Public entry point: guarded merge-based sync of all 5 files + images. |
| [`_syncLocked`](#synclocked) | static method (`WebDAVService`) | A | The 10-step sync body run while `_syncing` is held. |
| [`ensureUploadSession`](#ensureuploadsession) | local function (inside `_syncLocked`) | A | Return the upload session already acquired for this sync attempt. |
| [`uploadJson`](#uploadjson) | local function (inside `_syncLocked`) | A | Force-upload one file's JSON using the held session. |
| [`finalizePendingSync`](#finalizependingsync) | static method (`WebDAVService`) | A | Apply user conflict resolutions and upload each resolved file. |
| [`forceUpload`](#forceupload) | static method (`WebDAVService`) | A | Public entry point: guarded overwrite-remote-from-local. |
| [`_forceUploadLocked`](#forceuploadlocked) | static method (`WebDAVService`) | A | The force-upload body run while `_syncing` is held. |
| [`_forceUploadImages`](#forceuploadimages) | static method (`WebDAVService`) | A | Upload all referenced local images during a force upload. |
| [`forceDownload`](#forcedownload) | static method (`WebDAVService`) | A | Public entry point: guarded overwrite-local-from-remote. |
| [`_forceDownloadLocked`](#forcedownloadlocked) | static method (`WebDAVService`) | A | The force-download body run while `_syncing` is held. |
| [`_forceDownloadImages`](#forcedownloadimages) | static method (`WebDAVService`) | A | Download all referenced remote images during a force download. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/services/webdav_service.dart` returns 72, matching
the 72 rows above that carry a `/// Purpose:` block exactly (13 Tier A + 7 Tier B in the model
section, plus 52 Tier A in `WebDAVService`, all cross-checked one-by-one against the grep pass).
Every one of those 72 blocks sits immediately above a real declaration (constructor, factory
constructor, getter, or static/local method) — none were found misattached above a call-site
statement. Cross-checking independently against every getter (`grep -E '\bget\s+\w+\s*(=>|\{)'`),
every `const`/`factory` constructor, and every `static ... (` method signature in the file turned up
no undocumented callable declaration. The table has one additional row beyond the 72 documented
ones: the plain `enum RemoteFileStatus { found, notFound, error }` at line 271, which has only a
one-line summary comment, no `/// Purpose:` block. This matches the file's own convention — none of
its plain `static const`/`static final`/`static bool` field declarations (`_configFileName`,
`_dataFileNames`, `_lockTtlSeconds`, `_lockHeartbeatInterval`, `_syncing`, `_localDataChanged`,
`progress`, etc.) carry Purpose blocks either, since the convention in this codebase is to document
callable members, not plain data/type declarations. Those fields are described in prose in this page
(algorithm sections below) rather than given their own table rows, consistent with sibling pages in
this doc set (e.g. `auto_sync_service.md`).

## Documentation

### `const WebDAVConfig({required String serverUrl, required String username, required String password, String remotePath = '/MyDay', bool autoSync = false})` <a id="webdavconfig-new"></a>
- **Kind:** constructor of `WebDAVConfig`
- **Source:** `lib/shared/services/webdav_service.dart` (line 32)
- **Purpose:** Hold the four connection fields plus the `autoSync` flag that make up the persisted
  WebDAV configuration.
- **Inputs:** `serverUrl`, `username`, `password` (all required); `remotePath` defaults to
  `/MyDay`; `autoSync` defaults to `false`.
- **Returns:** A new `WebDAVConfig`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor, no logic.
- **Usage:**
  ```dart
  WebDAVConfig get _currentConfig => WebDAVConfig(
    serverUrl: _urlController.text.trim(),
    username: _userController.text.trim(),
    password: _passController.text.trim(),
    remotePath: _pathController.text.trim(),
    autoSync: _autoSync,
  );
  ```
  (`lib/shared/views/webdav_config_page.dart:97-103`, building the config from the settings form.)
- **Notes:** None.

### `WebDAVConfig copyWith({bool? autoSync})` <a id="copywith"></a>
- **Kind:** method of `WebDAVConfig`
- **Source:** `lib/shared/services/webdav_service.dart` (line 53)
- **Purpose:** Return a copy of this config with only `autoSync` optionally replaced; every other
  field is carried over unchanged.
- **Inputs:** `autoSync` — optional new value; falls back to `this.autoSync` when null.
- **Returns:** A new `WebDAVConfig`.
- **Side effects:** None.
- **Algorithm:** Construct a new `WebDAVConfig` copying `serverUrl`/`username`/`password`/
  `remotePath` verbatim and `autoSync: autoSync ?? this.autoSync`.
- **Usage:**
  ```dart
  await WebDAVService.saveConfig(config.copyWith(autoSync: false));
  ```
  (`lib/shared/views/backup_page.dart:196`, disabling auto-sync before a backup restore writes any
  file.)
- **Notes:** Only `autoSync` is toggleable through `copyWith`; other fields require constructing a
  new `WebDAVConfig` directly.

### `Map<String, dynamic> toJson()` <a id="webdavconfig-tojson"></a>
- **Kind:** method of `WebDAVConfig`
- **Source:** `lib/shared/services/webdav_service.dart` (line 66)
- **Purpose:** Serialize the config to the JSON map persisted in `webdav_config.json`.
- **Inputs:** None.
- **Returns:** `{serverUrl, username, password, remotePath, autoSync}`.
- **Side effects:** None.
- **Algorithm:** Direct map literal of the five fields.
- **Usage:**
  ```dart
  await file.writeAsString(jsonEncode(config.toJson()));
  ```
  (`lib/shared/services/webdav_service.dart:480`, inside [`saveConfig`](#saveconfig).)
- **Notes:** The password is stored in plain JSON in this file — there is no separate secure-storage
  path for the WebDAV password in this codebase.

### `factory WebDAVConfig.fromJson(Map<String, dynamic> json)` <a id="webdavconfig-fromjson"></a>
- **Kind:** factory constructor of `WebDAVConfig`
- **Source:** `lib/shared/services/webdav_service.dart` (line 79)
- **Purpose:** Parse a `WebDAVConfig` back out of its persisted/synced JSON form.
- **Inputs:** `json` — decoded map, normally read from `webdav_config.json`.
- **Returns:** A new `WebDAVConfig`.
- **Side effects:** None.
- **Algorithm:** Read each field with `as String?`/`as bool?` and fall back to a default
  (`''` for strings, `/MyDay` for `remotePath`, `false` for `autoSync`) when absent — never throws
  on missing keys.
- **Usage:**
  ```dart
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  return WebDAVConfig.fromJson(json);
  ```
  (`lib/shared/services/webdav_service.dart:465-466`, inside [`loadConfig`](#loadconfig).)
- **Notes:** Unlike `WebDAVUploadLock.fromJson`, this never throws — a corrupt or partial config
  file degrades to defaults field-by-field rather than failing the whole load.

### `factory WebDAVConfig.nextcloud(String host, String username, String password)` <a id="webdavconfig-nextcloud"></a>
- **Kind:** factory constructor of `WebDAVConfig`
- **Source:** `lib/shared/services/webdav_service.dart` (line 93)
- **Purpose:** Build a config preset with the standard Nextcloud WebDAV URL pattern
  (`https://<host>/remote.php/dav/files/<username>`) so the user doesn't have to type it.
- **Inputs:** `host`, `username`, `password`.
- **Returns:** A new `WebDAVConfig` with `remotePath` left at its default (`/MyDay`).
- **Side effects:** None.
- **Algorithm:** String-interpolate the fixed Nextcloud DAV path template, then delegate to the main
  `WebDAVConfig(...)` constructor.
- **Usage:** No call site exists anywhere in `lib/` or `test/` in this repo — this preset factory is
  currently unused; the settings UI (`webdav_config_page.dart`) only builds `WebDAVConfig` through
  its own `_currentConfig` getter from free-form form fields.
- **Notes:** Effectively dead code today; kept as a convenience constructor for a Nextcloud "quick
  setup" that the UI does not yet expose.

### `const SyncResult({required bool success, String? error, PendingSync? pending, List<String> warnings = const []})` <a id="syncresult-new"></a>
- **Kind:** constructor of `SyncResult`
- **Source:** `lib/shared/services/webdav_service.dart` (line 122)
- **Purpose:** Hold the outcome of one sync/force-upload/force-download attempt: overall success,
  an optional error message, optional pending per-record conflicts, and non-fatal warnings.
- **Inputs:** `success` (required); `error`, `pending`, `warnings` all optional.
- **Returns:** A new `SyncResult`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor.
- **Usage:**
  ```dart
  return SyncResult(success: false, error: interrupted.error);
  ```
  (`lib/shared/services/webdav_service.dart:1513`, one of many construction sites inside
  [`_syncLocked`](#synclocked) and the other `*Locked` bodies.)
- **Notes:** `warnings` defaults to `const []`, so `result.warnings.isEmpty` is safe to call without
  a null check.

### `PendingSync({TodoMergeResult? todoMerge, FinanceMergeResult? financeMerge, IntimacyMergeResult? intimacyMerge, WeightMergeResult? weightMerge})` <a id="pendingsync-new"></a>
- **Kind:** constructor of `PendingSync`
- **Source:** `lib/shared/services/webdav_service.dart` (line 149)
- **Purpose:** Bundle whichever per-module merge results came back with unresolved record
  conflicts, so the UI can present them together and `finalizePendingSync` can later re-derive which
  files need a resolved re-upload.
- **Inputs:** All four fields optional — only the modules that actually had conflicts are non-null.
- **Returns:** A new `PendingSync`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor.
- **Usage:**
  ```dart
  pending: PendingSync(
    todoMerge: pendingTodo,
    financeMerge: pendingFinance,
    intimacyMerge: pendingIntimacy,
    weightMerge: pendingWeight,
  ),
  ```
  (`lib/shared/services/webdav_service.dart:1879-1884`, inside [`_syncLocked`](#synclocked) once the
  per-file loop finishes.)
- **Notes:** None.

### `List<RecordConflict> get allConflicts` <a id="allconflicts"></a>
- **Kind:** getter of `PendingSync`
- **Source:** `lib/shared/services/webdav_service.dart` (line 161)
- **Purpose:** Flatten every module's record-level conflicts (todo daily/once, finance
  accounts/categories/transactions/subscriptions, intimacy partners/toys/positions/records/cycle
  records, weight records) into a single list the conflict-resolution UI can iterate uniformly.
- **Inputs:** None.
- **Returns:** `List<RecordConflict>` — concatenation across all present merges, in a fixed
  module/field order; empty when no module has conflicts.
- **Side effects:** None.
- **Algorithm:** A single list literal using twelve null-aware spreads (`...?todoMerge?.dailyConflicts`,
  `...?financeMerge?.transactionConflicts`, etc.) — any module whose merge result is `null` (no
  conflicts) contributes nothing.
- **Usage:**
  ```dart
  builder: (_) => SyncConflictDialog(conflicts: result.pending!.allConflicts),
  ```
  (`lib/shared/views/webdav_config_page.dart:180`, feeding the conflict dialog from a sync result
  with `hasConflicts == true`.)
- **Notes:** Classified Tier A despite being a getter because it aggregates across all five data
  modules and is the single feed into the cross-module conflict-resolution UI referenced by
  `sync.md`'s mixed-resolutions-map rule.

### `const WebDAVUploadLock({required String clientId, required String token, required DateTime startedAt, required DateTime updatedAt, required int ttlSeconds})` <a id="webdavuploadlock-new"></a>
- **Kind:** constructor of `WebDAVUploadLock`
- **Source:** `lib/shared/services/webdav_service.dart` (line 190)
- **Purpose:** Hold the contents of the remote `.lock` file: which client holds it, its resumable
  upload token, when it started/was last refreshed, and its TTL.
- **Inputs:** All five fields required.
- **Returns:** A new `WebDAVUploadLock`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor.
- **Usage:**
  ```dart
  final lock = WebDAVUploadLock(
    clientId: clientId,
    token: resumeToken ?? const Uuid().v4(),
    startedAt: now,
    updatedAt: now,
    ttlSeconds: _lockTtlSeconds,
  );
  ```
  (`lib/shared/services/webdav_service.dart:1032-1038`, inside [`_acquireUploadSession`](#acquireuploadsession).)
- **Notes:** Times are documented as UTC and must be compared with `ttlSeconds` accordingly (see
  [`isExpired`](#isexpired)).

### `factory WebDAVUploadLock.fromJson(Map<String, dynamic> json)` <a id="webdavuploadlock-fromjson"></a>
- **Kind:** factory constructor of `WebDAVUploadLock`
- **Source:** `lib/shared/services/webdav_service.dart` (line 203)
- **Purpose:** Parse a lock value out of the remote `.lock` file's JSON.
- **Inputs:** `json` — decoded remote `.lock` content.
- **Returns:** A parsed `WebDAVUploadLock`.
- **Side effects:** None.
- **Algorithm:** Cast `clientId`/`token` as required `String`s, parse `startedAt`/`updatedAt` with
  `DateTime.parse(...).toUtc()`, and default `ttlSeconds` to `WebDAVService._lockTtlSeconds` (60)
  when absent from an older lock format.
- **Usage:**
  ```dart
  final json = jsonDecode(remote.content!) as Map<String, dynamic>;
  return (
    lock: WebDAVUploadLock.fromJson(json),
    etag: _strongEtag(remote.etag),
    error: null,
  );
  ```
  (`lib/shared/services/webdav_service.dart:921-926`, inside [`_readRemoteUploadLock`](#readremoteuploadlock).)
- **Notes:** Throws (propagated, caught by the caller) when `clientId`/`token`/`startedAt`/
  `updatedAt` are missing or malformed — [`_readRemoteUploadLock`](#readremoteuploadlock) treats a
  parse failure as "no usable lock" rather than a hard error.

### `Map<String, dynamic> toJson()` <a id="webdavuploadlock-tojson"></a>
- **Kind:** method of `WebDAVUploadLock`
- **Source:** `lib/shared/services/webdav_service.dart` (line 219)
- **Purpose:** Serialize this lock back to the JSON written to the remote `.lock` file.
- **Inputs:** None.
- **Returns:** `{clientId, token, startedAt, updatedAt, ttlSeconds}` with both timestamps as UTC ISO
  8601 strings.
- **Side effects:** None.
- **Algorithm:** Direct map literal; both `DateTime` fields go through `.toUtc().toIso8601String()`.
- **Usage:**
  ```dart
  return _upload(config, _lockFileName, jsonEncode(lock.toJson()), ...);
  ```
  (`lib/shared/services/webdav_service.dart:946`, inside [`_writeRemoteUploadLock`](#writeremoteuploadlock).)
- **Notes:** None.

### `bool isExpired(DateTime now)` <a id="isexpired"></a>
- **Kind:** method of `WebDAVUploadLock`
- **Source:** `lib/shared/services/webdav_service.dart` (line 232)
- **Purpose:** Decide whether this lock has passed its TTL and may be treated as abandoned/
  replaceable.
- **Inputs:** `now` — the caller's current time (any timezone; normalized internally).
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `now.toUtc().difference(updatedAt.toUtc()).inSeconds >= ttlSeconds`.
- **Usage:**
  ```dart
  if (remoteLock.clientId != clientId && !remoteLock.isExpired(now)) {
    return (resumeToken: null, error: 'Another device is uploading; ...');
  }
  ```
  (`lib/shared/services/webdav_service.dart:996`, inside [`_prepareInterruptedUpload`](#prepareinterruptedupload); the same pattern gates
  [`_acquireUploadSession`](#acquireuploadsession) and [`_refreshUploadLock`](#refreshuploadlock).)
- **Notes:** Classified Tier A because this single comparison implements the 60-second lock-TTL
  invariant documented in `sync.md` — every lock-contention decision in the file funnels through it.

### `WebDAVUploadLock refreshed(DateTime updatedAt)` <a id="refreshed"></a>
- **Kind:** method of `WebDAVUploadLock`
- **Source:** `lib/shared/services/webdav_service.dart` (line 248)
- **Purpose:** Produce a copy of this lock with `updatedAt` bumped, keeping the same owner and
  resumable token — the "heartbeat" or "re-acquire by the same client" case.
- **Inputs:** `updatedAt` — the new timestamp (normalized to UTC).
- **Returns:** A new `WebDAVUploadLock`.
- **Side effects:** None.
- **Algorithm:** Construct a new lock copying `clientId`/`token`/`startedAt`/`ttlSeconds` and setting
  `updatedAt: updatedAt.toUtc()`.
- **Usage:**
  ```dart
  final lock = (remoteLock != null && remoteLock.matches(session.clientId, session.token))
      ? remoteLock.refreshed(now)
      : WebDAVUploadLock(clientId: session.clientId, token: session.token, ...);
  ```
  (`lib/shared/services/webdav_service.dart:1080-1090`, inside [`_refreshUploadLock`](#refreshuploadlock).)
- **Notes:** A copy-with-style helper, same category as `copyWith` per the tiering rules, even
  though it has a distinct name.

### `static bool consumeLocalDataChanged()` <a id="consumelocaldatachanged"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 350)
- **Purpose:** Report whether the most recent sync/force operation wrote local data or image files,
  then reset that flag so the next caller sees a fresh answer.
- **Inputs:** None.
- **Returns:** `bool`.
- **Side effects:** Resets the private static `_localDataChanged` flag to `false`.
- **Algorithm:** Snapshot `_localDataChanged` into `v`, set the field back to `false`, return `v`.
- **Usage:**
  ```dart
  if (WebDAVService.consumeLocalDataChanged()) {
    for (final cb in List.of(_onLocalDataChanged)) {
      cb();
    }
  }
  ```
  (`lib/shared/services/auto_sync_service.dart:253-256`, right after `WebDAVService.sync(config)`
  inside `AutoSyncService._trySync`.)
- **Notes:** A read of this flag is destructive (one-shot) — callers that need to know "did this
  particular sync write files" must call it exactly once right after that sync/force call.

### `static void _reportProgress(SyncPhase phase, {String? detail, int current = 0, int total = 0})` <a id="reportprogress"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 369)
- **Purpose:** Publish one progress snapshot to the public `WebDAVService.progress`
  `ValueNotifier<SyncProgress>` that the WebDAV page's `ValueListenableBuilder` renders.
- **Inputs:** `phase` (one of the `SyncPhase` values: `connecting`, `downloadingData`, `merging`,
  `uploadingData`, `uploadingImages`, `downloadingImages`, `done`, `error`); optional `detail` (a
  file/image name), `current`/`total` (progress counters).
- **Returns:** None.
- **Side effects:** Assigns `progress.value`, which fires every registered `ValueListenableBuilder`.
- **Algorithm:** Construct a `SyncProgress(phase, detail: ..., current: ..., total: ...)` and assign
  it to `progress.value`.
- **Usage:**
  ```dart
  _reportProgress(SyncPhase.downloadingData, detail: name, current: fileIndex, total: _dataFileNames.length);
  ```
  (`lib/shared/services/webdav_service.dart:1568-1573`, called once per file inside the
  [`_syncLocked`](#synclocked) download loop; called at every phase transition throughout `sync`,
  `_syncLocked`, `_syncImages`, and the force-upload/download paths.)
- **Notes:** The service emits raw phase/detail/count data only; localizing the phase into
  user-facing text is the WebDAV page's job (per `sync.md`).

### `static Future<T> _withRetry<T>(Future<T> Function() attempt, {bool Function(T value)? shouldRetry, int retries = 2})` <a id="withretry"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 391)
- **Purpose:** Generic retry/backoff wrapper shared by every network call in this file (data GET/PUT,
  byte GET/PUT, PROPFIND listings).
- **Inputs:** `attempt` — the operation to run; `shouldRetry` — predicate on a *successful* return
  value that should still trigger a retry (used to retry HTTP 5xx responses that don't throw);
  `retries` — extra attempts after the first (default 2, i.e. up to 3 total attempts).
- **Returns:** `Future<T>` — the value from whichever attempt finally succeeds/is accepted, or
  rethrows the last exception once retries are exhausted.
- **Side effects:** `await`s a `Duration(seconds: attemptIndex)` delay between attempts (1s, then
  2s).
- **Algorithm:**
  1. Loop: run `attempt()`.
  2. If the result satisfies `shouldRetry` and attempts remain, increment the attempt index,
     `await` a delay of that many seconds, and loop again.
  3. Otherwise return the value.
  4. On a thrown `SocketException`/`TimeoutException`/`http.ClientException`/`HttpException`
     ("transient"), retry the same way if attempts remain; any other exception, or a transient one
     with no attempts left, rethrows immediately.
- **Usage:**
  ```dart
  final response = await _withRetry(
    () => http.put(url, headers: {...}, body: utf8.encode(content)).timeout(const Duration(seconds: 30)),
    shouldRetry: (r) => r.statusCode >= 500,
    retries: retries,
  );
  ```
  (`lib/shared/services/webdav_service.dart:806-821`, inside [`_upload`](#upload); the same pattern
  wraps [`_uploadBytes`](#uploadbytes), [`_download`](#download), [`_downloadBytes`](#downloadbytes),
  and [`_listRemoteDir`](#listremotedir).)
- **Notes:** `.lock` writes pass `retries: 0` (see [`_writeRemoteUploadLock`](#writeremoteuploadlock)) so a
  retried create-only PUT can never misreport lock contention as a fresh conflict; 4xx responses are
  never retried by any caller's `shouldRetry`.

### `static Future<FinanceData> _migrateFinanceForcedBalances(FinanceData data)` <a id="migratefinanceforcedbalances"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 424)
- **Purpose:** Run the legacy forced-balance migration (`migrateForcedBalances` from
  `balance_util.dart`) over freshly merged finance data before it is written/uploaded, so synced
  data always reflects the current balance model.
- **Inputs:** `data` — merged `FinanceData`.
- **Returns:** `Future<FinanceData>` — `data` unchanged if the migration reports no change, otherwise
  a new `FinanceData` with migrated `accounts`/`transactions` and every other field carried over.
- **Side effects:** Loads exchange-rate data (`ExchangeRateStorage.load()`) needed to convert legacy
  forced-balance transactions.
- **Algorithm:**
  1. Load current exchange-rate data.
  2. Call `migrateForcedBalances(accounts:, transactions:, rateData:)`.
  3. If `!migration.changed`, return `data` as-is.
  4. Otherwise rebuild a `FinanceData` with the migrated `accounts`/`transactions` and all other
     fields copied from the input.
- **Usage:**
  ```dart
  final mergedData = await _migrateFinanceForcedBalances(result.buildResolved(const {}));
  ```
  (`lib/shared/services/webdav_service.dart:1740-1742`, applied to the finance merge result inside
  [`_syncLocked`](#synclocked); also applied inside [`finalizePendingSync`](#finalizependingsync) to the resolved finance
  conflict result.)
- **Notes:** Only the `finance_data.json` path runs this migration; the other four data files skip
  it entirely.

### `static Future<WebDAVConfig?> loadConfig()` <a id="loadconfig"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 459)
- **Purpose:** Load the persisted `webdav_config.json` from the app directory, if present.
- **Inputs:** None.
- **Returns:** `Future<WebDAVConfig?>` — `null` if the file is missing or unreadable/malformed.
- **Side effects:** Reads `<appDir>/webdav_config.json`.
- **Algorithm:**
  1. Resolve the app directory via `TodoStorage.getAppDir()`.
  2. If the config file doesn't exist, return `null`.
  3. Decode its JSON and return `WebDAVConfig.fromJson(json)`.
  4. Any exception (missing file race, bad JSON) is caught and also returns `null`.
- **Usage:**
  ```dart
  final config = await WebDAVService.loadConfig();
  if (config == null || !config.isConfigured || !config.autoSync) return;
  ```
  (`lib/shared/services/auto_sync_service.dart:237-238`, the first step of `AutoSyncService._trySync`;
  also used by `settings_page.dart:168`, `backup_page.dart:192`, and `webdav_config_page.dart:65`.)
- **Notes:** Never throws to the caller — every failure path degrades to `null`, which callers treat
  as "WebDAV not configured."

### `static Future<void> saveConfig(WebDAVConfig config)` <a id="saveconfig"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 477)
- **Purpose:** Persist a `WebDAVConfig` to `webdav_config.json` in the app directory.
- **Inputs:** `config`.
- **Returns:** `Future<void>`.
- **Side effects:** Overwrites `<appDir>/webdav_config.json` (non-atomic plain write, unlike the
  base/data-file writes which go through [`_atomicWrite`](#atomicwrite)).
- **Algorithm:** Resolve the app directory, then `file.writeAsString(jsonEncode(config.toJson()))`.
- **Usage:**
  ```dart
  await WebDAVService.saveConfig(config);
  setState(() => _isConfigured = config.isConfigured);
  if (config.isConfigured && config.autoSync) {
    AutoSyncService.instance.requestSyncNow();
  }
  ```
  (`lib/shared/views/webdav_config_page.dart:112-118`, saving the settings form and immediately
  triggering a sync when a fully configured auto-sync setup was just saved.)
- **Notes:** Unlike `_atomicWrite`-backed files, a crash mid-write here can in principle corrupt
  `webdav_config.json`; `loadConfig` tolerates that by returning `null` on a decode failure.

### `static Future<void> deleteConfig()` <a id="deleteconfig"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 488)
- **Purpose:** Remove the persisted WebDAV config (the "disconnect" action).
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Deletes `<appDir>/webdav_config.json` if present.
- **Algorithm:** Resolve the app directory; delete the file only if `await file.exists()`.
- **Usage:**
  ```dart
  await WebDAVService.deleteConfig();
  _urlController.clear();
  ```
  (`lib/shared/views/webdav_config_page.dart:423-424`, the "disconnect" handler.)
- **Notes:** Does not touch `.sync_base/` base snapshots or local data files — only the config
  pointing at the WebDAV server is removed.

### `static Future<Directory> _getBaseDir()` <a id="getbasedir"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 501)
- **Purpose:** Resolve (creating if needed) the `.sync_base/` directory that holds last-synced base
  snapshots, the local client id, and the local upload-lock marker.
- **Inputs:** None.
- **Returns:** `Future<Directory>`.
- **Side effects:** Creates `<appDir>/.sync_base/` if it does not already exist.
- **Algorithm:** Resolve the app directory, build the `.sync_base` sub-directory `Directory`, create
  it if missing, return it.
- **Usage:** Called internally by every base/lock/client-id helper in this file, e.g.
  ```dart
  final dir = await _getBaseDir();
  final file = File('${dir.path}/$fileName');
  ```
  (`lib/shared/services/webdav_service.dart:515-516`, inside [`_readBase`](#readbase).)
- **Notes:** None.

### `static Future<String?> _readBase(String fileName)` <a id="readbase"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 513)
- **Purpose:** Read the last-synced base snapshot for one data file, used as the "base" side of the
  three-way merge.
- **Inputs:** `fileName` — e.g. `todo_data.json`.
- **Returns:** `Future<String?>` — file content, or `null` if missing/unreadable.
- **Side effects:** None (read-only; any exception is swallowed and mapped to `null`).
- **Algorithm:** Resolve `.sync_base/`, return `null` if the file doesn't exist, otherwise read and
  return its content; catch-all returns `null`.
- **Usage:**
  ```dart
  final baseJson = await _readBase(name);
  ```
  (`lib/shared/services/webdav_service.dart:1627`, inside [`_syncLocked`](#synclocked)'s per-file
  merge loop, right before dispatching to the per-file `merge*Data`/`mergeExchangeRateJson`
  functions.)
- **Notes:** A missing/corrupt base is treated the same as "no prior sync" — the merge functions
  handle a `null` base themselves (see [Three-Way Merge](../../../algorithms/three-way-merge.md)).

### `static Future<void> _saveBase(String fileName, String jsonContent)` <a id="savebase"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 529)
- **Purpose:** Persist the new base snapshot for one data file after a successful merge/upload, so
  the next sync's three-way diff starts from this state.
- **Inputs:** `fileName`, `jsonContent` — the content now known to match both local and remote.
- **Returns:** `Future<void>`.
- **Side effects:** Atomically writes `.sync_base/<fileName>`.
- **Algorithm:** Resolve `.sync_base/`, delegate the actual write to
  [`_atomicWrite`](#atomicwrite).
- **Usage:**
  ```dart
  await _saveBase(fileName, preservedJson);
  ```
  (`lib/shared/services/webdav_service.dart:668`, inside [`_finalizeFile`](#finalizefile), right
  after a successful upload; the same call shape recurs after every successful upload path in
  `_syncLocked`/`_forceUploadLocked`/`_forceDownloadLocked`.)
- **Notes:** Always called only *after* the corresponding upload/download succeeded — a failed
  upload leaves the previous base untouched so the next sync retries the same diff.

### `static Future<String> _loadClientId()` <a id="loadclientid"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 540)
- **Purpose:** Return this installation's stable local client id, creating it on first use.
- **Inputs:** None.
- **Returns:** `Future<String>` — a UUID v4 string.
- **Side effects:** May create and write `.sync_base/client_id.txt`.
- **Algorithm:**
  1. If `client_id.txt` exists and its trimmed content is non-empty, return it.
  2. Otherwise generate `const Uuid().v4()`, write it to the file, and return it.
- **Usage:**
  ```dart
  final clientId = await _loadClientId();
  final interrupted = await _prepareInterruptedUpload(config, clientId);
  ```
  (`lib/shared/services/webdav_service.dart:1510-1511`, the first thing [`_syncLocked`](#synclocked)
  does after ensuring the remote directory exists; also used identically in
  [`_forceUploadLocked`](#forceuploadlocked) and [`finalizePendingSync`](#finalizependingsync).)
- **Notes:** The client id is local-only — it is never synced or exported, only used to attribute
  and recognize this device's own `.lock` ownership.

### `static Future<WebDAVUploadLock?> _readLocalUploadLock()` <a id="readlocaluploadlock"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 557)
- **Purpose:** Read the local marker (`.sync_base/upload_lock.json`) left behind before this device
  started its last remote upload, used to detect an interrupted upload on the next launch.
- **Inputs:** None.
- **Returns:** `Future<WebDAVUploadLock?>` — `null` if absent or unparseable.
- **Side effects:** None (read-only).
- **Algorithm:** Resolve `.sync_base/`, return `null` if the file is missing, otherwise decode and
  parse via `WebDAVUploadLock.fromJson`; any exception (missing/malformed) maps to `null`.
- **Usage:**
  ```dart
  final localLock = await _readLocalUploadLock();
  if (localLock == null) return (resumeToken: null, error: null);
  ```
  (`lib/shared/services/webdav_service.dart:979-980`, the first check inside
  [`_prepareInterruptedUpload`](#prepareinterruptedupload).)
- **Notes:** Invalid local locks are silently treated as absent and get overwritten on the next
  upload attempt.

### `static Future<void> _saveLocalUploadLock(WebDAVUploadLock lock)` <a id="savelocaluploadlock"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 575)
- **Purpose:** Write the local upload-lock marker just before this device starts an upload, so a
  crash mid-upload can be detected and resumed on next launch.
- **Inputs:** `lock`.
- **Returns:** `Future<void>`.
- **Side effects:** Atomically writes `.sync_base/upload_lock.json`.
- **Algorithm:** Resolve `.sync_base/`, delegate to [`_atomicWrite`](#atomicwrite) with
  `jsonEncode(lock.toJson())`.
- **Usage:**
  ```dart
  await _saveLocalUploadLock(lock);
  return (session: _UploadSession(clientId: clientId, token: lock.token), error: null);
  ```
  (`lib/shared/services/webdav_service.dart:1053-1057`, the last step of a successful
  [`_acquireUploadSession`](#acquireuploadsession).)
- **Notes:** None.

### `static Future<void> _clearLocalUploadLock()` <a id="clearlocaluploadlock"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 586)
- **Purpose:** Remove the local upload-lock marker once an upload session completes or is
  determined to be stale/foreign.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Deletes `.sync_base/upload_lock.json` if present.
- **Algorithm:** Resolve `.sync_base/`, delete the file only if it exists.
- **Usage:**
  ```dart
  await _clearLocalUploadLock();
  ```
  (`lib/shared/services/webdav_service.dart:1199`, the last step of
  [`_releaseUploadSession`](#releaseuploadsession); also called from
  [`_prepareInterruptedUpload`](#prepareinterruptedupload) when the remote lock has vanished or
  belongs to nobody resumable.)
- **Notes:** Missing files are silently ignored — this is safe to call unconditionally.

### `static Future<void> _atomicWrite(File file, String content)` <a id="atomicwrite"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 601)
- **Purpose:** Write file content in a way that cannot leave a half-written/corrupt file behind if
  the app is killed mid-write.
- **Inputs:** `file` — target `File`; `content`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `<file>.tmp`, then renames it over `file`.
- **Algorithm:** Write `content` to a sibling `.tmp` file, then `rename` it onto the target path
  (an atomic operation on the underlying filesystem).
- **Usage:**
  ```dart
  await _atomicWrite(localFile, preservedJson);
  ```
  (`lib/shared/services/webdav_service.dart:696`, inside [`_uploadMergedJson`](#uploadmergedjson);
  this is the single write path used by every local data-file/base-snapshot/lock-marker write in the
  file.)
- **Notes:** This is the one and only local-write primitive in the file — every other method that
  writes a local file goes through it rather than calling `File.writeAsString` directly (the one
  exception is [`saveConfig`](#saveconfig), which writes `webdav_config.json` directly).

### `static String _preserveUnknownJson(String fileName, String mergedJson, {String? baseJson, String? localJson, String? remoteJson})` <a id="preserveunknownjson"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 614)
- **Purpose:** Re-inject JSON fields that a newer app version wrote but this version's merge
  functions don't know about, so an unattended merge on an older client never silently drops them.
- **Inputs:** `fileName` — selects the `JsonPreservationSchema` (from
  `dataFilePreservationSchemas`); `mergedJson` — the merge output about to be written; `baseJson`/
  `localJson`/`remoteJson` — the three source JSONs to recover unknown fields from.
- **Returns:** `String` — `mergedJson` unchanged if no schema is registered for `fileName`, otherwise
  the schema-processed JSON.
- **Side effects:** None (pure string transform).
- **Algorithm:**
  1. Look up `dataFilePreservationSchemas[fileName]`; if there is no schema, return `mergedJson`
     as-is.
  2. Otherwise call `JsonPreservation.preserveJsonString(nextJson: mergedJson, sourceJsons:
     [baseJson, localJson, remoteJson], schema: schema)`.
- **Usage:**
  ```dart
  final preservedJson = _preserveUnknownJson(fileName, mergedJson, localJson: localJson, remoteJson: remote.content);
  ```
  (`lib/shared/services/webdav_service.dart:653-658`, inside [`_finalizeFile`](#finalizefile);
  called on every write path that produces a merged/resolved/exchange-rate JSON before it touches
  disk.)
- **Notes:** The actual field-preservation algorithm lives in `lib/shared/utils/json_preservation.dart`
  and is out of scope for this page; this method is just the call site that wires `fileName` to a
  schema and the three source JSONs.

### `static Future<bool> _finalizeFile(WebDAVConfig config, String fileName, String mergedJson, _UploadSession uploadSession)` <a id="finalizefile"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 638)
- **Purpose:** Write, upload, and rebase a single file's user-resolved conflict result — the
  per-file unit of work inside [`finalizePendingSync`](#finalizependingsync).
- **Inputs:** `config`; `fileName`; `mergedJson` — the fully resolved data serialized to JSON;
  `uploadSession` — the already-acquired lock session.
- **Returns:** `Future<bool>` — `false` when the remote download (for unknown-field context) or the
  upload fails; `true` on success.
- **Side effects:** Downloads the current remote file, writes the local file, uploads it, and saves
  the base snapshot; sets the local-data-changed flag.
- **Algorithm:**
  1. Read the current local file content if present (for unknown-field preservation context).
  2. Download the current remote file; if the download errors (not merely 404), return `false`
     without writing anything.
  3. Run [`_preserveUnknownJson`](#preserveunknownjson) with the local/remote JSON as sources.
  4. Atomically write the preserved JSON locally and set `_localDataChanged = true`.
  5. Upload via [`_uploadWithSession`](#uploadwithsession); if it errors, return `false` (the base
     snapshot is *not* updated, so the next sync will re-merge).
  6. Otherwise save the new base snapshot and return `true`.
- **Usage:**
  ```dart
  final mergedData = pending.todoMerge!.buildResolved(resolutions);
  final ok = await _finalizeFile(config, 'todo_data.json', jsonEncode(mergedData.toJson()), uploadSession);
  allOk = allOk && ok;
  ```
  (`lib/shared/services/webdav_service.dart:1930-1937`, inside [`finalizePendingSync`](#finalizependingsync), repeated
  once per module that had a pending conflict.)
- **Notes:** A remote read failure here aborts only this file — [`finalizePendingSync`](#finalizependingsync) still
  attempts the other modules' files and returns `false` overall if any one of them failed.

### `static Future<String?> _uploadMergedJson(WebDAVConfig config, String fileName, String mergedJson, {required Future<_UploadSession?> Function() ensureUploadSession, required File localFile, String? baseJson, String? sourceLocalJson, String? remoteJson})` <a id="uploadmergedjson"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 679)
- **Purpose:** Write, upload, and rebase one file's *auto-merged* (no user conflict) result during a
  normal sync — the counterpart to [`_finalizeFile`](#finalizefile) for the non-conflict path.
- **Inputs:** `config`; `fileName`; `mergedJson`; `ensureUploadSession` — closure returning the
  already-held session (never re-acquires); `localFile`; `baseJson`/`sourceLocalJson`/`remoteJson`
  — unknown-field preservation sources.
- **Returns:** `Future<String?>` — `null` on success, otherwise an error message.
- **Side effects:** Writes the local file, reports upload progress, uploads to remote, saves the
  base snapshot on success.
- **Algorithm:**
  1. Run [`_preserveUnknownJson`](#preserveunknownjson) over `mergedJson`.
  2. Atomically write it locally and set `_localDataChanged = true`.
  3. Report `SyncPhase.uploadingData` progress.
  4. Call `ensureUploadSession()`; if it returns `null`, return the error string `'upload lock was
     not acquired'` without attempting a network call.
  5. Upload via [`_uploadWithSession`](#uploadwithsession); on success, save the base snapshot and
     return `null`; on failure, return the upload's error message.
- **Usage:**
  ```dart
  final uploadError = await _uploadMergedJson(
    config, name, mergedJson,
    ensureUploadSession: ensureUploadSession,
    localFile: localFile, baseJson: baseJson,
    sourceLocalJson: currentLocalJson, remoteJson: currentRemoteJson,
  );
  if (uploadError != null) perFileErrors.add('$name: force-upload failed: $uploadError');
  ```
  (`lib/shared/services/webdav_service.dart:1699-1711`, the no-conflict branch for `todo_data.json`
  inside [`_syncLocked`](#synclocked); the same call shape repeats for finance/intimacy/weight.)
- **Notes:** Unlike [`_finalizeFile`](#finalizefile), this does not itself download the remote file —
  the caller already has `remoteJson` from the earlier download in the sync loop.

### `static Map<String, String> _authHeaders(WebDAVConfig config)` <a id="authheaders"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 721)
- **Purpose:** Build the HTTP Basic auth header sent with every WebDAV request.
- **Inputs:** `config` — provides `username`/`password`.
- **Returns:** `{'Authorization': 'Basic <base64>'}`.
- **Side effects:** None.
- **Algorithm:** Base64-encode the UTF-8 bytes of `'<username>:<password>'`, wrap in the standard
  `Basic` auth header.
- **Usage:**
  ```dart
  headers: {..._authHeaders(config), 'Content-Type': 'application/octet-stream', ...}
  ```
  (`lib/shared/services/webdav_service.dart:810-814`, inside [`_upload`](#upload); used identically
  in every HTTP call in this file — GET/PUT/DELETE/PROPFIND/MKCOL.)
- **Notes:** Credentials travel as HTTP Basic auth, so the WebDAV connection should be over HTTPS —
  this file does not enforce that itself.

### `static String _remoteFileUrl(WebDAVConfig config, String fileName)` <a id="remotefileurl"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 733)
- **Purpose:** Build the full request URL for a file under the configured remote path.
- **Inputs:** `config`; `fileName`.
- **Returns:** `String` — `<serverUrl><remotePath>/<fileName>` with duplicate/missing slashes
  normalized.
- **Side effects:** None.
- **Algorithm:** Strip a trailing slash from `serverUrl` if present; ensure `remotePath` ends with
  exactly one slash; concatenate `base + path + fileName`.
- **Usage:**
  ```dart
  final url = Uri.parse(_remoteFileUrl(config, fileName));
  ```
  (`lib/shared/services/webdav_service.dart:805`, inside [`_upload`](#upload); the same helper
  builds the URL for [`_download`](#download), [`_uploadBytes`](#uploadbytes),
  [`_downloadBytes`](#downloadbytes), and the `.lock` read/write/delete calls.)
- **Notes:** None.

### `static Future<bool> testConnection(WebDAVConfig config)` <a id="testconnection"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 748)
- **Purpose:** Verify that the given config's credentials and server are reachable, for the
  settings page's "Test Connection" button.
- **Inputs:** `config`.
- **Returns:** `Future<bool>`.
- **Side effects:** Sends one PROPFIND request (10s timeout); no retries.
- **Algorithm:**
  1. Build the remote-path root URL (trailing-slash normalized).
  2. Send a depth-0 `PROPFIND` request with auth headers and a minimal `<d:resourcetype/>` body.
  3. Treat HTTP 207 (Multi-Status, directory exists) or 404 (reachable server, path just not created
     yet) as success; any other status or exception returns `false`.
- **Usage:**
  ```dart
  final ok = await WebDAVService.testConnection(_currentConfig);
  ```
  (`lib/shared/views/webdav_config_page.dart:137`, the "Test Connection" button handler.)
- **Notes:** A 404 counts as success because it means the server accepted the credentials and
  responded — the remote sync directory itself is created lazily by
  [`_ensureRemoteDir`](#ensureremotedir) on the first real sync, not by this check.

### `static Future<void> _ensureRemoteDir(WebDAVConfig config)` <a id="ensureremotedir"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 775)
- **Purpose:** Best-effort create the remote sync root directory (`config.remotePath`) before the
  first upload.
- **Inputs:** `config`.
- **Returns:** `Future<void>`.
- **Side effects:** Sends one `MKCOL` request (10s timeout); failures are silently swallowed.
- **Algorithm:** Build the root URL, send `MKCOL` with auth headers, ignore any error (the directory
  may already exist, which most servers report as an error status this method doesn't even inspect).
- **Usage:**
  ```dart
  await _ensureRemoteDir(config);
  ```
  (`lib/shared/services/webdav_service.dart:1508`, the first action inside
  [`_syncLocked`](#synclocked); also called at the start of [`_forceUploadLocked`](#forceuploadlocked).)
- **Notes:** No retry wrapper — a transient MKCOL failure is simply ignored, since a missing
  directory will just cause the subsequent PUTs to fail loudly instead.

### `static Future<({bool is412, String? error})> _upload(WebDAVConfig config, String fileName, String content, {String? ifMatchEtag, bool ifNoneMatchAll = false, int retries = 2})` <a id="upload"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 796)
- **Purpose:** Low-level conditional PUT of text content, used for both data-file uploads (via
  [`_uploadWithSession`](#uploadwithsession), no preconditions) and `.lock` writes (with ETag
  preconditions).
- **Inputs:** `config`; `fileName`; `content`; `ifMatchEtag`/`ifNoneMatchAll` — optional conditional
  headers; `retries` (0 for `.lock` writes, default 2 otherwise).
- **Returns:** `({bool is412, String? error})` — `error == null` on 2xx; `is412: true` when the
  conditional check failed (HTTP 412).
- **Side effects:** One PUT request (30s timeout), retried per [`_withRetry`](#withretry) on
  transient failures/5xx.
- **Algorithm:**
  1. Build the URL, PUT `utf8.encode(content)` with `If-Match`/`If-None-Match: *` set only when the
     corresponding parameter is provided, retrying on 5xx.
  2. 412 → `(is412: true, error: '...')`; 2xx → `(is412: false, error: null)`; anything else →
     `(is412: false, error: 'HTTP <code>')`; any thrown exception → `(is412: false, error: '$e')`.
- **Usage:**
  ```dart
  return _upload(config, _lockFileName, jsonEncode(lock.toJson()), ifMatchEtag: ifMatchEtag, ifNoneMatchAll: ifNoneMatchAll, retries: 0);
  ```
  (`lib/shared/services/webdav_service.dart:943-950`, inside
  [`_writeRemoteUploadLock`](#writeremoteuploadlock).)
- **Notes:** Data JSON writes never pass `ifMatchEtag`/`ifNoneMatchAll` — the held `.lock` is the
  sole concurrency guard for data files (per `sync.md`).

### `static String? _strongEtag(String? etag)` <a id="strongetag"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 840)
- **Purpose:** Filter out weak ETags (`W/...`) so they never get used as `.lock` `If-Match`
  preconditions, which require strong comparison per RFC 9110.
- **Inputs:** `etag` — possibly `null` or weak.
- **Returns:** `String?` — the ETag unchanged if present and not weak, otherwise `null`.
- **Side effects:** None.
- **Algorithm:** `if (etag == null || etag.startsWith('W/')) return null; return etag;`
- **Usage:**
  ```dart
  etag: _strongEtag(remote.etag),
  ```
  (`lib/shared/services/webdav_service.dart:924`, inside
  [`_readRemoteUploadLock`](#readremoteuploadlock); its result feeds every `ifMatchEtag` argument
  passed to [`_writeRemoteUploadLock`](#writeremoteuploadlock).)
- **Notes:** None.

### `static Future<void> _uploadBytes(WebDAVConfig config, String fileName, Uint8List bytes)` <a id="uploadbytes"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 851)
- **Purpose:** Low-level binary PUT used for image uploads.
- **Inputs:** `config`; `fileName` (e.g. `images/<uuid>`); `bytes`.
- **Returns:** `Future<void>`.
- **Side effects:** One PUT request (120s timeout), retried on transient/5xx failures; throws on
  any non-2xx final status.
- **Algorithm:** PUT `bytes` with `application/octet-stream` content type through
  [`_withRetry`](#withretry); throw `Exception('HTTP <code>')` if the final status is outside
  200–299.
- **Usage:**
  ```dart
  await _uploadBytesWithSession(config, 'images/$name', bytes, uploadSession);
  ```
  (`lib/shared/services/webdav_service.dart:1407-1412`, inside [`_syncImages`](#syncimages), which
  calls this indirectly through [`_uploadBytesWithSession`](#uploadbyteswithsession).)
- **Notes:** Unlike [`_upload`](#upload), this throws instead of returning an error tuple — callers
  wrap it in `try`/`catch` per-image so one failed image doesn't abort the whole image-sync pass.

### `static Future<RemoteFile> _download(WebDAVConfig config, String fileName)` <a id="download"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 884)
- **Purpose:** GET a remote file and classify the outcome into found/notFound/error — the
  load-bearing distinction described in `sync.md` step 2 that prevents an unreadable remote file
  from being treated as "missing" and overwritten.
- **Inputs:** `config`; `fileName`.
- **Returns:** `Future<RemoteFile>`.
- **Side effects:** One GET request (30s timeout), retried on transient/5xx failures.
- **Algorithm:**
  1. GET the file through [`_withRetry`](#withretry) (retry on 5xx).
  2. HTTP 200 → `RemoteFile.found(body, etag: ...)`.
  3. HTTP 404 → `const RemoteFile.notFound()`.
  4. Any other status → `RemoteFile.failure('HTTP <code>')`.
  5. Any thrown exception → `RemoteFile.failure('$e')`.
- **Usage:**
  ```dart
  final remote = await _download(config, name);
  if (remote.status == RemoteFileStatus.error) {
    perFileErrors.add('$name: download failed: ${remote.error}');
    continue;
  }
  ```
  (`lib/shared/services/webdav_service.dart:1576-1585`, inside [`_syncLocked`](#synclocked)'s
  per-file loop.)
- **Notes:** Callers must never treat `RemoteFileStatus.error` as "missing on remote" — only
  `notFound` (a true HTTP 404) may trigger the upload-local-as-new path; conflating the two can
  overwrite remote data and cascade into cross-device record deletion.

### `static Future<({WebDAVUploadLock? lock, String? etag, String? error})> _readRemoteUploadLock(WebDAVConfig config)` <a id="readremoteuploadlock"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 911, name at line 912)
- **Purpose:** Download and parse the remote `.lock` file, distinguishing "no lock" from "lock
  present" from "read failed."
- **Inputs:** `config`.
- **Returns:** `({WebDAVUploadLock? lock, String? etag, String? error})`.
- **Side effects:** One [`_download`](#download) call (network I/O).
- **Algorithm:**
  1. Download `.lock` via [`_download`](#download).
  2. `RemoteFileStatus.error` → return with `error` set, `lock: null`.
  3. `notFound` or empty content → return all-`null` (no lock exists).
  4. Otherwise decode JSON and parse via `WebDAVUploadLock.fromJson`; on a parse exception, return
     `lock: null` but still surface the strong ETag (a malformed lock is treated as replaceable).
- **Usage:**
  ```dart
  final remote = await _readRemoteUploadLock(config);
  if (remote.error != null) return (resumeToken: null, error: remote.error);
  ```
  (`lib/shared/services/webdav_service.dart:982-983`, inside
  [`_prepareInterruptedUpload`](#prepareinterruptedupload); also called from
  [`_acquireUploadSession`](#acquireuploadsession), [`_refreshUploadLock`](#refreshuploadlock), and
  [`_releaseUploadSession`](#releaseuploadsession).)
- **Notes:** Missing or malformed remote locks are both treated as "replaceable stale lock," not as
  hard errors — only a genuine download error (`RemoteFileStatus.error`) blocks the caller.

### `static Future<({bool is412, String? error})> _writeRemoteUploadLock(WebDAVConfig config, WebDAVUploadLock lock, {String? ifMatchEtag, bool ifNoneMatchAll = false})` <a id="writeremoteuploadlock"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 937)
- **Purpose:** PUT a lock value to the remote `.lock` path with optional optimistic-concurrency
  preconditions.
- **Inputs:** `config`; `lock`; `ifMatchEtag`/`ifNoneMatchAll` — conditional headers.
- **Returns:** `({bool is412, String? error})`.
- **Side effects:** One [`_upload`](#upload) call with `retries: 0`.
- **Algorithm:** Delegate straight to [`_upload`](#upload) with `_lockFileName`,
  `jsonEncode(lock.toJson())`, the given preconditions, and `retries: 0`.
- **Usage:**
  ```dart
  final write = await _writeRemoteUploadLock(config, lock, ifMatchEtag: remote.etag, ifNoneMatchAll: remoteLock == null && remote.etag == null);
  ```
  (`lib/shared/services/webdav_service.dart:1039-1044`, inside
  [`_acquireUploadSession`](#acquireuploadsession); the same call shape appears in
  [`_refreshUploadLock`](#refreshuploadlock).)
- **Notes:** `retries: 0` is intentional (inherited from [`_upload`](#upload)/[`_withRetry`](#withretry)'s
  design) — a retried create-only PUT could otherwise misreport lock contention as a fresh 412.

### `static Future<void> _deleteRemoteUploadLock(WebDAVConfig config, {String? etag})` <a id="deleteremoteuploadlock"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 958)
- **Purpose:** Remove the remote `.lock` file once this device is done with it.
- **Inputs:** `config`; `etag` — optional `If-Match` precondition.
- **Returns:** `Future<void>`.
- **Side effects:** One DELETE request (10s timeout); errors are swallowed.
- **Algorithm:** `http.delete` the `.lock` URL with auth headers and `If-Match: ?etag`; any
  exception is caught and ignored.
- **Usage:**
  ```dart
  if (remote.lock?.matches(session.clientId, session.token) ?? false) {
    await _deleteRemoteUploadLock(config, etag: remote.etag);
  }
  ```
  (`lib/shared/services/webdav_service.dart:1196-1198`, inside
  [`_releaseUploadSession`](#releaseuploadsession).)
- **Notes:** Errors are ignored deliberately — a lock that fails to delete simply expires on its own
  after the 60-second TTL.

### `static Future<({String? resumeToken, String? error})> _prepareInterruptedUpload(WebDAVConfig config, String clientId)` <a id="prepareinterruptedupload"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 977, name at line 978)
- **Purpose:** Inspect a local upload-lock marker left by a previous run that crashed or was killed
  mid-upload, and decide whether to resume that upload's token, block (another device is active), or
  clear the stale marker.
- **Inputs:** `config`; `clientId`.
- **Returns:** `({String? resumeToken, String? error})`.
- **Side effects:** May call [`_clearLocalUploadLock`](#clearlocaluploadlock).
- **Algorithm:**
  1. If there's no local lock marker, return no-op (`resumeToken: null, error: null`).
  2. Read the remote lock; a read error is returned as `error` immediately.
  3. If the remote lock is now gone, clear the local marker and return no-op.
  4. If the remote lock matches this local marker's clientId/token *and* the local marker's
     clientId matches the current `clientId`, return that token as `resumeToken` (this device owns
     an in-flight, still-valid lock — resume it rather than acquiring a new one).
  5. If the remote lock belongs to a different, non-expired client, return a blocking error.
  6. Otherwise (expired or ownerless) clear the local marker and return no-op.
- **Usage:**
  ```dart
  final interrupted = await _prepareInterruptedUpload(config, clientId);
  if (interrupted.error != null) return SyncResult(success: false, error: interrupted.error);
  ```
  (`lib/shared/services/webdav_service.dart:1511-1514`, right after loading the client id inside
  [`_syncLocked`](#synclocked); the same call shape runs in
  [`_forceUploadLocked`](#forceuploadlocked) and [`finalizePendingSync`](#finalizependingsync).)
- **Notes:** This is what lets a crashed upload resume with the *same* lock token instead of
  contending with itself for a new lock on the next launch.

### `static Future<({_UploadSession? session, String? error})> _acquireUploadSession(WebDAVConfig config, String clientId, {String? resumeToken})` <a id="acquireuploadsession"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1012, name at line 1013)
- **Purpose:** Acquire the remote `.lock` before any upload can proceed, blocking only when another
  client's lock is still within its TTL.
- **Inputs:** `config`; `clientId`; `resumeToken` — an existing token to reuse (from
  [`_prepareInterruptedUpload`](#prepareinterruptedupload)) instead of generating a fresh UUID.
- **Returns:** `({_UploadSession? session, String? error})`.
- **Side effects:** Writes the remote `.lock` (conditional PUT) and, on success, the local lock
  marker.
- **Algorithm:**
  1. Read the remote lock; propagate a read error immediately.
  2. If a remote lock exists, belongs to a different client, and is not expired, return a blocking
     error ("Another device is uploading...").
  3. Build a new `WebDAVUploadLock` for `clientId`, reusing `resumeToken` if given (else a fresh
     UUID v4), `startedAt`/`updatedAt = now`, `ttlSeconds = 60`.
  4. Write it with `ifMatchEtag: remote.etag` (overwrite a known lock) and `ifNoneMatchAll` set only
     when no remote lock/etag exists (create-only, prevents a race creating two locks).
  5. A 412 here means another device just won the race — return a blocking error.
  6. On success, save the local marker and return the new `_UploadSession`.
- **Usage:**
  ```dart
  final acquired = await _acquireUploadSession(config, clientId, resumeToken: interrupted.resumeToken);
  uploadSession = acquired.session;
  if (uploadSession == null) return SyncResult(success: false, error: acquired.error ?? 'Upload lock was not acquired');
  ```
  (`lib/shared/services/webdav_service.dart:1515-1526`, inside [`_syncLocked`](#synclocked).)
- **Notes:** This is the acquisition half of the 60-second-TTL lock protocol described in
  `sync.md`; see [`_withLockHeartbeat`](#withlockheartbeat) for how the lock survives a slow
  transfer once acquired.

### `static Future<String?> _refreshUploadLock(WebDAVConfig config, _UploadSession session)` <a id="refreshuploadlock"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1065)
- **Purpose:** Re-write the lock's `updatedAt` immediately before (and, via the heartbeat, during) a
  PUT, so a slow transfer keeps the lock alive.
- **Inputs:** `config`; `session` — the currently held session.
- **Returns:** `Future<String?>` — `null` on success, otherwise a blocking error message.
- **Side effects:** Updates the remote and local lock files.
- **Algorithm:**
  1. Read the remote lock; propagate a read error.
  2. If it exists, doesn't match our session, belongs to a different client, and isn't expired,
     return a blocking error.
  3. If it matches our session, build `remoteLock.refreshed(now)`; otherwise build a brand-new lock
     for this session (the remote lock vanished since acquisition).
  4. Write it with the same ETag-precondition logic as
     [`_acquireUploadSession`](#acquireuploadsession).
  5. On success, save the local marker; return `null`.
- **Usage:**
  ```dart
  final lockError = await _refreshUploadLock(config, session);
  if (lockError != null) return (is412: false, error: lockError);
  ```
  (`lib/shared/services/webdav_service.dart:1154-1155`, inside
  [`_uploadWithSession`](#uploadwithsession), run once right before the PUT; also invoked
  periodically by [`_withLockHeartbeat`](#withlockheartbeat) while the PUT is in flight.)
- **Notes:** If another active client now owns the lock, the in-flight upload is blocked — this can
  surface mid-transfer via the heartbeat, though heartbeat failures themselves are swallowed (see
  [`_withLockHeartbeat`](#withlockheartbeat)).

### `static Future<T> _withLockHeartbeat<T>(WebDAVConfig config, _UploadSession session, Future<T> Function() operation)` <a id="withlockheartbeat"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1116)
- **Purpose:** Run a network operation while periodically refreshing the held lock, so a transfer
  slower than the 60-second TTL can never let another client treat the lock as expired mid-transfer.
- **Inputs:** `config`; `session`; `operation` — the in-flight transfer to run.
- **Returns:** `Future<T>` — `operation()`'s result.
- **Side effects:** Starts a `Timer.periodic(_lockHeartbeatInterval, ...)` (20 seconds) that calls
  [`_refreshUploadLock`](#refreshuploadlock) on each tick until `operation()` completes.
- **Algorithm:**
  1. Start a periodic timer at the 20-second heartbeat interval; each tick, if a refresh isn't
     already in flight (`refreshing` guard), call `_refreshUploadLock` and swallow any exception.
  2. `await operation()`.
  3. In `finally`, cancel the timer regardless of success/failure.
- **Usage:**
  ```dart
  return _withLockHeartbeat(config, session, () => _upload(config, fileName, content));
  ```
  (`lib/shared/services/webdav_service.dart:1156-1160`, inside
  [`_uploadWithSession`](#uploadwithsession); also wraps [`_uploadBytes`](#uploadbytes) inside
  [`_uploadBytesWithSession`](#uploadbyteswithsession).)
- **Notes:** Heartbeat refresh failures are swallowed and never abort the in-flight transfer —
  without this, a single failed heartbeat tick (e.g. one dropped packet) could needlessly fail an
  otherwise-successful upload.

### `static Future<({bool is412, String? error})> _uploadWithSession(WebDAVConfig config, String fileName, String content, _UploadSession session)` <a id="uploadwithsession"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1148)
- **Purpose:** The standard "upload one data file under the held lock" path: refresh the lock, then
  PUT under heartbeat protection.
- **Inputs:** `config`; `fileName`; `content`; `session`.
- **Returns:** `({bool is412, String? error})`.
- **Side effects:** Network I/O (lock refresh + data PUT).
- **Algorithm:**
  1. [`_refreshUploadLock`](#refreshuploadlock); if it errors, return that error immediately (no PUT
     attempted).
  2. Otherwise run [`_upload`](#upload) for `fileName`/`content` inside
     [`_withLockHeartbeat`](#withlockheartbeat).
- **Usage:**
  ```dart
  final result = await _uploadWithSession(config, fileName, preservedJson, uploadSession);
  if (result.error != null) return false;
  ```
  (`lib/shared/services/webdav_service.dart:661-667`, inside [`_finalizeFile`](#finalizefile); also
  used by [`_uploadMergedJson`](#uploadmergedjson) and the "only on local" force-upload branch of
  [`_syncLocked`](#synclocked)'s per-file loop.)
- **Notes:** Data JSON writes intentionally never pass `.lock`-style `If-Match`/`If-None-Match`
  preconditions — the held remote `.lock` is the sole concurrency guard for data writes.

### `static Future<void> _uploadBytesWithSession(WebDAVConfig config, String fileName, Uint8List bytes, _UploadSession session)` <a id="uploadbyteswithsession"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1170)
- **Purpose:** The standard "upload one image under the held lock" path, mirroring
  [`_uploadWithSession`](#uploadwithsession) for binary content.
- **Inputs:** `config`; `fileName` (e.g. `images/<uuid>`); `bytes`; `session`.
- **Returns:** `Future<void>` (throws on failure).
- **Side effects:** Network I/O (lock refresh + image PUT).
- **Algorithm:**
  1. [`_refreshUploadLock`](#refreshuploadlock); if it errors, `throw Exception(lockError)`.
  2. Otherwise run [`_uploadBytes`](#uploadbytes) inside
     [`_withLockHeartbeat`](#withlockheartbeat).
- **Usage:**
  ```dart
  await _uploadBytesWithSession(config, 'images/$name', bytes, uploadSession);
  ```
  (`lib/shared/services/webdav_service.dart:1407-1412`, inside [`_syncImages`](#syncimages), inside
  a per-image `try`/`catch` so one image's failure doesn't abort the batch.)
- **Notes:** None.

### `static Future<void> _releaseUploadSession(WebDAVConfig config, _UploadSession? session)` <a id="releaseuploadsession"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1190)
- **Purpose:** Release the held upload lock once a sync/force attempt finishes (success or failure).
- **Inputs:** `config`; `session` — may be `null` if a session was never acquired.
- **Returns:** `Future<void>`.
- **Side effects:** Deletes the remote and local lock files, but only the remote one if it still
  belongs to this session.
- **Algorithm:**
  1. If `session` is `null`, return immediately (nothing to release).
  2. Read the remote lock; if it still `matches(session.clientId, session.token)`, delete it
     remotely.
  3. Always clear the local lock marker.
- **Usage:**
  ```dart
  } finally {
    await _releaseUploadSession(config, uploadSession);
  }
  ```
  (`lib/shared/services/webdav_service.dart:1896-1898`, the `finally` block of
  [`_syncLocked`](#synclocked); the identical pattern guards
  [`finalizePendingSync`](#finalizependingsync) and [`_forceUploadLocked`](#forceuploadlocked).)
- **Notes:** The remote delete is skipped if the lock no longer matches our session — this avoids
  deleting a lock that another device has since acquired (e.g. after our lock expired and was
  replaced).

### `static Future<void> _ensureRemoteSubDir(WebDAVConfig config, String subPath)` <a id="ensureremotesubdir"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1209)
- **Purpose:** Best-effort create a remote sub-directory (currently only `images/`) before listing
  or uploading into it.
- **Inputs:** `config`; `subPath` (e.g. `'images'`).
- **Returns:** `Future<void>`.
- **Side effects:** One `MKCOL` request (10s timeout); failures silently ignored.
- **Algorithm:** Build `<base><remotePath>/<subPath>/`, send `MKCOL`, swallow any error.
- **Usage:**
  ```dart
  await _ensureRemoteSubDir(config, 'images');
  ```
  (`lib/shared/services/webdav_service.dart:1367`, the first step of
  [`_syncImages`](#syncimages); also called from [`_forceUploadImages`](#forceuploadimages).)
- **Notes:** Same best-effort shape as [`_ensureRemoteDir`](#ensureremotedir), scoped to a
  sub-directory.

### `static Future<Set<String>?> _listRemoteDir(WebDAVConfig config, String subPath)` <a id="listremotedir"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1236)
- **Purpose:** List file names present in a remote sub-directory via PROPFIND, used to avoid
  re-uploading images that are already present remotely (and vice versa).
- **Inputs:** `config`; `subPath`.
- **Returns:** `Future<Set<String>?>` — `null` specifically means "listing failed," distinct from an
  empty (but successfully listed) directory.
- **Side effects:** One depth-1 PROPFIND request, retried on transient/5xx failures.
- **Algorithm:**
  1. Send a depth-1 `PROPFIND` for `<subPath>/`; if the response status isn't 207, return `null`.
  2. Regex-extract every `<d:href>`/`<D:href>` value from the XML body.
  3. URL-decode each href; skip the directory's own href and any href ending in `/` (sub-collections);
     take the last non-empty path segment as the file's basename and add it to the result set.
  4. Any exception anywhere returns `null`.
- **Usage:**
  ```dart
  final remoteNames = await _listRemoteDir(config, 'images');
  if (remoteNames == null) {
    errors.add('Image sync skipped: could not list the remote images directory');
    return errors;
  }
  ```
  (`lib/shared/services/webdav_service.dart:1381-1387`, inside [`_syncImages`](#syncimages).)
- **Notes:** Callers must never treat a `null` result as "empty directory" — doing so previously
  caused every referenced image to be re-uploaded after a transient PROPFIND failure (documented in
  `sync.md`).

### `static Future<Uint8List> _downloadBytes(WebDAVConfig config, String fileName)` <a id="downloadbytes"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1288)
- **Purpose:** Download binary content (images) with retry.
- **Inputs:** `config`; `fileName` (e.g. `images/<uuid>`).
- **Returns:** `Future<Uint8List>` (throws on failure).
- **Side effects:** One GET request (120s timeout), retried on transient/5xx failures.
- **Algorithm:** GET through [`_withRetry`](#withretry); return `response.bodyBytes` on 200,
  otherwise `throw Exception('HTTP <code>')`.
- **Usage:**
  ```dart
  final bytes = await _downloadBytes(config, 'images/$name');
  await File(p.join(imgDir.path, name)).writeAsBytes(bytes);
  ```
  (`lib/shared/services/webdav_service.dart:1434-1435`, inside [`_syncImages`](#syncimages), inside a
  per-image `try`/`catch`.)
- **Notes:** None.

### `static Set<String> _getReferencedImageNames(String? json, String dataFile)` <a id="getreferencedimagenames"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1313)
- **Purpose:** Extract the basenames of images actually referenced by finance or intimacy records,
  so image sync only ever transfers referenced images, never orphans.
- **Inputs:** `json` — decoded data-file content (or `null`); `dataFile` — `finance_data.json` or
  `intimacy_data.json` (any other value yields an empty set).
- **Returns:** `Set<String>`.
- **Side effects:** None (any decode exception is caught and returns `{}`).
- **Algorithm:**
  1. Return `{}` immediately if `json` is `null`.
  2. Decode JSON; pick the relevant top-level sections by `dataFile`: `['accounts',
     'subscriptions']` for finance, `['partners', 'toys']` for intimacy.
  3. For each item in each section that is a `Map` with a non-empty `imagePath` string, add
     `p.basename(imagePath)` to the result set.
  4. Any exception (bad JSON, unexpected shape) returns `{}`.
- **Usage:**
  ```dart
  final referencedImages = {
    ..._getReferencedImageNames(localFinanceJson, 'finance_data.json'),
    ..._getReferencedImageNames(remoteFinanceJson, 'finance_data.json'),
    ..._getReferencedImageNames(localIntimacyJson, 'intimacy_data.json'),
    ..._getReferencedImageNames(remoteIntimacyJson, 'intimacy_data.json'),
  };
  ```
  (`lib/shared/services/webdav_service.dart:1856-1861`, inside [`_syncLocked`](#synclocked), unioning
  local and remote references before calling [`_syncImages`](#syncimages).)
- **Notes:** Only finance and intimacy data reference images in this app; todo/exchange-rates/weight
  never contribute to the referenced set.

### `static Future<List<String>> _syncImages(WebDAVConfig config, Directory appDir, Set<String> referencedImages, Future<_UploadSession?> Function() ensureUploadSession)` <a id="syncimages"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1355)
- **Purpose:** Additive bidirectional sync of only the images referenced by actual records —
  uploads local-only referenced images, downloads remote-only referenced images, and skips orphans
  entirely.
- **Inputs:** `config`; `appDir`; `referencedImages` — the local ∪ remote referenced-name union;
  `ensureUploadSession` — closure returning the already-held session.
- **Returns:** `Future<List<String>>` — non-fatal per-image warning/error strings.
- **Side effects:** Creates the local `images/` directory if missing, ensures the remote `images/`
  directory, uploads/downloads image bytes, sets `_localDataChanged` on any download, reports
  per-image progress.
- **Algorithm:**
  1. Return early if `referencedImages` is empty.
  2. Ensure the local `images/` dir exists and the remote `images/` collection exists.
  3. Collect local file basenames that are in `referencedImages` (skip orphans).
  4. List remote `images/` via [`_listRemoteDir`](#listremotedir); if that returns `null` (listing
     failed), add one warning and return immediately — the whole image phase is skipped rather than
     risk re-uploading everything.
  5. Upload every local referenced image missing remotely, one at a time, via
     [`_uploadBytesWithSession`](#uploadbyteswithsession) (acquiring the session per-image through
     `ensureUploadSession`); per-image timeout/other failures are appended as warnings and the loop
     continues.
  6. Download every referenced image present remotely but missing locally via
     [`_downloadBytes`](#downloadbytes), setting `_localDataChanged = true` on each; per-image
     failures are appended as warnings.
- **Usage:**
  ```dart
  final imageErrors = await _syncImages(config, appDir, referencedImages, ensureUploadSession);
  ```
  (`lib/shared/services/webdav_service.dart:1862-1867`, inside [`_syncLocked`](#synclocked), after
  the per-file data loop finishes.)
- **Notes:** See [`_listRemoteDir`](#listremotedir)'s notes for why a failed listing must not be
  treated as an empty directory.

### `static Future<SyncResult> sync(WebDAVConfig config, {bool autoResolve = false})` <a id="sync"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1471)
- **Purpose:** The public entry point for a full merge-based sync of all five data files plus
  referenced images — guards against concurrent syncs and delegates the actual work to
  [`_syncLocked`](#synclocked).
- **Inputs:** `config`; `autoResolve` — when `true`, two-sided conflicts fall back to
  last-writer-wins instead of being surfaced; every production caller leaves it `false`.
- **Returns:** `Future<SyncResult>`.
- **Side effects:** Reads/writes local data files, base snapshots, and remote WebDAV files;
  publishes progress; sets and clears the static `_syncing` guard.
- **Algorithm:**
  1. If `_syncing` is already `true`, return immediately with `SyncResult(success: false, error:
     'Sync already in progress')` — no lock or network activity happens.
  2. Set `_syncing = true`.
  3. Report `SyncPhase.connecting`, call [`_syncLocked`](#synclocked), report `done`/`error` based on
     the result.
  4. In `finally`, clear `_syncing = false`.
- **Usage:**
  ```dart
  final result = await WebDAVService.sync(config);
  ```
  (`lib/shared/services/auto_sync_service.dart:241`, inside `AutoSyncService._trySync`; also called
  from `lib/shared/views/webdav_config_page.dart:166` for manual sync.)
- **Notes:** `_syncing` is a process-wide static guard, so auto-sync and manual sync can never run
  concurrently with each other, not just with themselves.

### `static Future<SyncResult> _syncLocked(WebDAVConfig config, {bool autoResolve = false})` <a id="synclocked"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1502)
- **Purpose:** The full 10-step sync body (see [WebDAV Sync](../../../sync.md)) run while `_syncing`
  is already held: acquire the lock, download/merge/upload each of the five data files per-record,
  sync referenced images, and return either a success/error result or a `PendingSync` of conflicts.
- **Inputs:** `config`; `autoResolve`.
- **Returns:** `Future<SyncResult>`.
- **Side effects:** The full read/write surface described in the class-level overview: local data
  files, `.sync_base/` snapshots, remote data files, remote/local `.lock` files, and progress
  reporting.
- **Algorithm:**
  1. Ensure the remote directory exists; load the app dir and client id.
  2. Run [`_prepareInterruptedUpload`](#prepareinterruptedupload); abort with its error if blocked.
  3. Run [`_acquireUploadSession`](#acquireuploadsession); abort if no session was obtained.
  4. Define two local closures scoped to this attempt: [`ensureUploadSession`](#ensureuploadsession)
     (returns the already-acquired session) and [`uploadJson`](#uploadjson) (force-upload one file
     using that session).
  5. For each of the five data file names in order:
     - Download the remote copy; a non-404 error appends a per-file error and `continue`s to the
       next file (this file's sync is skipped for this cycle, not the whole run).
     - Neither local nor remote exists → skip.
     - Remote-only → download, save as base, mark `_localDataChanged`, continue.
     - Local-only → force-upload the local content as new via `uploadJson`, save the base on
       success, else record a per-file error.
     - Both exist and are byte-identical → save local as the new base (already in sync), continue.
     - Otherwise dispatch per file: `exchange_rates.json` runs `mergeExchangeRateJson` (union, no
       conflicts) and force-uploads the result; the other four run their respective `merge*Data`
       function with `autoResolve`, re-reading the local file and re-merging once if it changed
       during the network round-trip (to catch saves that happened during I/O), and either stash a
       `pending*` merge result (conflicts) or upload the auto-resolved result via
       [`_uploadMergedJson`](#uploadmergedjson). Each file's merge/upload runs in its own
       `try`/`catch` so one file's exception does not stop the others.
  6. Union local and remote referenced image names from the finance/intimacy JSON snapshots seen
     during the loop, then call [`_syncImages`](#syncimages).
  7. If any of the four structured files produced a pending merge result, return a `SyncResult`
     wrapping a `PendingSync` of them (plus any accumulated per-file errors and image warnings).
  8. Otherwise return a plain success/failure `SyncResult` (success iff no per-file errors) with
     image warnings attached.
  9. Any uncaught exception anywhere in the body is caught at the top level and returned as a
     failed `SyncResult`.
  10. In `finally`, release the upload session regardless of outcome.
- **Usage:** Called only from [`sync`](#sync) (`lib/shared/services/webdav_service.dart:1484`), never
  directly by UI code.
- **Notes:** This is the method the 10-step flow in [WebDAV Sync](../../../sync.md) refers to
  directly; see [Three-Way Merge](../../../algorithms/three-way-merge.md) for what each `merge*Data`
  call actually does, and [Sync Walkthrough](../../../examples/sync-walkthrough.md) for a worked
  cross-module conflict example continuing into `finalizePendingSync`.

### `Future<_UploadSession?> ensureUploadSession()` <a id="ensureuploadsession"></a>
- **Kind:** local function, declared inside `_syncLocked`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1533)
- **Purpose:** Give the rest of `_syncLocked` (and the helpers it calls, like
  [`_uploadMergedJson`](#uploadmergedjson) and [`_syncImages`](#syncimages)) a uniform way to obtain
  the upload session already acquired for this sync attempt, without re-running acquisition logic.
- **Inputs:** None.
- **Returns:** `Future<_UploadSession?>` — the enclosing `uploadSession` local variable (never
  re-acquires; only returns what step 3 of `_syncLocked` already obtained).
- **Side effects:** None directly (a pure closure over `uploadSession`).
- **Algorithm:** `return uploadSession;` — the closure captures the outer variable by reference, so
  it always reflects the current (single) session for this attempt.
- **Usage:**
  ```dart
  final imageErrors = await _syncImages(config, appDir, referencedImages, ensureUploadSession);
  ```
  (`lib/shared/services/webdav_service.dart:1862-1867`, passed as the `ensureUploadSession` callback
  parameter; also passed to [`_uploadMergedJson`](#uploadmergedjson) calls throughout the per-file
  loop.)
- **Notes:** Despite the name symmetry with [`_acquireUploadSession`](#acquireuploadsession), this
  local function never contacts the network — it is purely a getter closure so callers deep in the
  call graph don't need `_syncLocked`'s local variables passed through every parameter list.

### `Future<({bool is412, String? error})> uploadJson(String fileName, String content)` <a id="uploadjson"></a>
- **Kind:** local function, declared inside `_syncLocked`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1542)
- **Purpose:** Force-upload one file's JSON content using the session already held for this sync
  attempt — used for the "only on local" (upload-as-new) branch of the per-file loop.
- **Inputs:** `fileName`; `content`.
- **Returns:** `({bool is412, String? error})`.
- **Side effects:** Network I/O via [`_uploadWithSession`](#uploadwithsession).
- **Algorithm:**
  1. Call `ensureUploadSession()`; if `null`, return `(is412: false, error: 'Upload lock was not
     acquired')` without a network call.
  2. Otherwise delegate to [`_uploadWithSession`](#uploadwithsession)`(config, fileName, content,
     session)`.
- **Usage:**
  ```dart
  final result = await uploadJson(name, localRaw);
  if (result.error == null) {
    await _saveBase(name, localRaw);
    continue;
  }
  perFileErrors.add('$name: force-upload failed: ${result.error}');
  ```
  (`lib/shared/services/webdav_service.dart:1612-1618`, the "only on local" branch of
  `_syncLocked`'s per-file loop; also used for the exchange-rates union-merge upload.)
- **Notes:** Scoped to a single `_syncLocked` call — a fresh `uploadJson` closure is created on
  every sync attempt, closing over that attempt's `uploadSession`/`config`.

### `static Future<bool> finalizePendingSync(WebDAVConfig config, PendingSync pending, Map<String, dynamic> resolutions)` <a id="finalizependingsync"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1909)
- **Purpose:** Apply the user's chosen resolution for every pending conflict and upload each
  affected file — the step 9 continuation of a sync that returned `hasConflicts == true`.
- **Inputs:** `config`; `pending` — the `PendingSync` from the earlier `sync()` call; `resolutions`
  — a map from conflict/record ID to the user's chosen record, mixed across module types.
- **Returns:** `Future<bool>` — `false` if acquiring the lock fails or if any file's finalize step
  fails; `true` only if every present module's file finalized successfully.
- **Side effects:** Writes resolved data to local files, uploads them, and saves base snapshots (via
  [`_finalizeFile`](#finalizefile), once per module that had a pending merge).
- **Algorithm:**
  1. Load the client id, run [`_prepareInterruptedUpload`](#prepareinterruptedupload), then
     [`_acquireUploadSession`](#acquireuploadsession); return `false` immediately on any failure to
     get a session.
  2. For each of `pending.todoMerge`/`financeMerge`/`intimacyMerge`/`weightMerge` that is non-null:
     call that merge result's own `buildResolved(resolutions)` (finance additionally runs
     [`_migrateFinanceForcedBalances`](#migratefinanceforcedbalances) on the result), then
     [`_finalizeFile`](#finalizefile) for that module's data file; AND the per-file `bool` into
     `allOk`.
  3. Return `allOk` (or `false` if any exception was thrown anywhere in the body).
  4. In `finally`, release the upload session.
- **Usage:**
  ```dart
  ok = await WebDAVService.finalizePendingSync(_currentConfig, result.pending!, resolutions);
  ```
  (`lib/shared/views/webdav_config_page.dart:187-191`, called after the user resolves conflicts in
  `SyncConflictDialog`.)
- **Notes:** The mixed-type `resolutions` map is passed as-is to every module's `buildResolved` —
  each module's own `_resolveList<T>` helper (in `sync_merge.dart`) type-checks each entry against
  its own record type via `is T`, so one shared map can safely carry resolutions for, say, a Finance
  conflict and an Intimacy conflict in the same pass. Bulk-casting the whole map to one record type
  previously crashed on cross-module conflicts — see the [cross-module safety
  rule](../../../sync.md#the-cross-module-mixed-resolutions-map-safety-rule) and the worked example
  in [Sync Walkthrough](../../../examples/sync-walkthrough.md). Failed files keep their previous
  base snapshot untouched, so the next sync re-merges them rather than silently treating them as
  resolved.

### `static Future<SyncResult> forceUpload(WebDAVConfig config)` <a id="forceupload"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 1993)
- **Purpose:** Public entry point for overwriting the remote with local data and images, with no
  merge or conflict check — the "local wins" destructive action.
- **Inputs:** `config`.
- **Returns:** `Future<SyncResult>`.
- **Side effects:** Same `_syncing`-guarded shell as [`sync`](#sync); delegates the actual work to
  [`_forceUploadLocked`](#forceuploadlocked).
- **Algorithm:** Identical guard/progress/`finally` shape to [`sync`](#sync), but calling
  [`_forceUploadLocked`](#forceuploadlocked) instead of `_syncLocked`.
- **Usage:**
  ```dart
  result = await WebDAVService.forceUpload(_currentConfig);
  ```
  (`lib/shared/views/webdav_config_page.dart:270`, after the user confirms the destructive force-upload
  dialog; also called from `lib/shared/views/backup_page.dart:282` when offering a post-restore
  force upload.)
- **Notes:** Remote changes made since the last sync are lost — the WebDAV page requires a
  destructive-action confirmation dialog before calling this (see `sync.md`).

### `static Future<SyncResult> _forceUploadLocked(WebDAVConfig config)` <a id="forceuploadlocked"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 2019)
- **Purpose:** The force-upload body run while `_syncing` is held: upload every present local data
  file verbatim (no merge), then referenced images.
- **Inputs:** `config`.
- **Returns:** `Future<SyncResult>`.
- **Side effects:** Overwrites remote data files, uploads images, saves base snapshots.
- **Algorithm:**
  1. Ensure the remote directory exists, load the client id, run
     [`_prepareInterruptedUpload`](#prepareinterruptedupload) then
     [`_acquireUploadSession`](#acquireuploadsession) (abort on failure of either).
  2. For each of the five data files that exists locally: read it, upload it verbatim via
     [`_uploadWithSession`](#uploadwithsession) (abort the whole operation with an error result if any
     single file's upload fails — unlike `_syncLocked`, this is not per-file-tolerant), then save it
     as the new base.
  3. Union referenced image names from the local finance/intimacy JSON and call
     [`_forceUploadImages`](#forceuploadimages).
  4. Return `SyncResult(success: true, warnings: ...)`, or a failure result on any exception.
  5. In `finally`, release the upload session.
- **Usage:** Called only from [`forceUpload`](#forceupload)
  (`lib/shared/services/webdav_service.dart:2003`).
- **Notes:** Unlike the normal sync loop, a single file's upload failure here aborts the entire
  force-upload (returns immediately with an error `SyncResult`) rather than being recorded as one
  per-file error among others — force upload is meant to guarantee remote completeness, not partial
  progress.

### `static Future<List<String>> _forceUploadImages(WebDAVConfig config, Directory appDir, Set<String> referencedImages, _UploadSession session)` <a id="forceuploadimages"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 2100)
- **Purpose:** Upload every referenced local image during a force upload, guaranteeing the remote
  ends up with a complete copy.
- **Inputs:** `config`; `appDir`; `referencedImages`; `session` — already-held session (no
  per-image re-acquisition, unlike [`_syncImages`](#syncimages)).
- **Returns:** `Future<List<String>>` — non-fatal per-image warnings.
- **Side effects:** Uploads image bytes, reports progress.
- **Algorithm:**
  1. Return early if `referencedImages` is empty or the local `images/` dir doesn't exist.
  2. Ensure the remote `images/` collection exists.
  3. Collect local referenced basenames.
  4. List remote `images/`; if the listing failed (`null`), upload *everything* referenced (force
     upload must guarantee remote completeness, so it cannot skip images just because it doesn't
     know what's already there) — otherwise upload only names missing remotely.
  5. Upload each selected image via [`_uploadBytesWithSession`](#uploadbyteswithsession), collecting
     per-image timeout/error warnings without stopping the loop.
- **Usage:**
  ```dart
  final warnings = await _forceUploadImages(config, appDir, referencedImages, uploadSession);
  ```
  (`lib/shared/services/webdav_service.dart:2078-2083`, inside
  [`_forceUploadLocked`](#forceuploadlocked).)
- **Notes:** Image names are immutable UUIDs, so an image already present remotely never needs
  re-uploading — the "upload everything on failed listing" fallback trades bandwidth for the
  guarantee that force upload never silently leaves an image missing remotely.

### `static Future<SyncResult> forceDownload(WebDAVConfig config)` <a id="forcedownload"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 2156)
- **Purpose:** Public entry point for overwriting local data and images with the remote copies, with
  no merge or conflict check — the "remote wins" destructive action.
- **Inputs:** `config`.
- **Returns:** `Future<SyncResult>`.
- **Side effects:** Same `_syncing`-guarded shell as [`sync`](#sync); delegates to
  [`_forceDownloadLocked`](#forcedownloadlocked).
- **Algorithm:** Identical guard/progress/`finally` shape to [`sync`](#sync)/[`forceUpload`](#forceupload).
- **Usage:**
  ```dart
  result = await WebDAVService.forceDownload(_currentConfig);
  ```
  (`lib/shared/views/webdav_config_page.dart:301`, after the user confirms the destructive
  force-download dialog.)
- **Notes:** Local changes made since the last sync are lost. Unlike `sync`/`forceUpload`, this
  takes no remote `.lock` at all — it is download-only, so there is nothing to protect against
  concurrent writers on the remote side; the `_syncing` guard still prevents it from overlapping
  another sync/force operation on this device.

### `static Future<SyncResult> _forceDownloadLocked(WebDAVConfig config)` <a id="forcedownloadlocked"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 2184)
- **Purpose:** The force-download body run while `_syncing` is held: replace every local data file
  with its remote copy (JSON-validated first) and download referenced images.
- **Inputs:** `config`.
- **Returns:** `Future<SyncResult>`.
- **Side effects:** Overwrites local data files, saves base snapshots, sets
  `_localDataChanged`, downloads images.
- **Algorithm:**
  1. For each of the five data files: download the remote copy; a genuine download error aborts the
     whole operation with a failure result (not per-file-tolerant, like force upload).
  2. A `notFound`/empty remote file adds a warning ("not found on remote; local file kept") and
     keeps the existing local file untouched — it does not delete local data.
  3. Otherwise, `jsonDecode` the remote content to validate it's well-formed JSON before writing;
     invalid JSON aborts the whole operation with a failure result rather than corrupting the local
     file.
  4. Atomically write the validated remote content locally, save it as the new base, set
     `_localDataChanged = true`.
  5. Union referenced image names from the downloaded finance/intimacy JSON and call
     [`_forceDownloadImages`](#forcedownloadimages), appending its warnings.
  6. Return a success `SyncResult` with accumulated warnings, or a failure result on any exception.
- **Usage:** Called only from [`forceDownload`](#forcedownload)
  (`lib/shared/services/webdav_service.dart:2166`); note this method takes no upload session
  parameter at all, since force download never touches the remote `.lock`.
- **Notes:** The JSON-validation-before-write step is what stops a corrupt or truncated remote
  response from ever reaching a local data file, even though force download otherwise trusts the
  remote completely.

### `static Future<List<String>> _forceDownloadImages(WebDAVConfig config, Directory appDir, Set<String> referencedImages)` <a id="forcedownloadimages"></a>
- **Kind:** static method of `WebDAVService`
- **Source:** `lib/shared/services/webdav_service.dart` (line 2247)
- **Purpose:** Download every referenced remote image during a force download that is not already
  present locally.
- **Inputs:** `config`; `appDir`; `referencedImages`.
- **Returns:** `Future<List<String>>` — non-fatal per-image warnings.
- **Side effects:** Creates the local `images/` dir if missing, writes downloaded image bytes, sets
  `_localDataChanged`, reports progress.
- **Algorithm:**
  1. Return early if `referencedImages` is empty; otherwise ensure the local `images/` dir exists.
  2. List remote `images/`; if the listing fails (`null`), add one warning and skip the whole image
     phase (does not attempt to guess remote contents, unlike the force-upload fallback).
  3. Download every referenced name that is present remotely and not already present locally
     (checked via `existsSync`), via [`_downloadBytes`](#downloadbytes), setting
     `_localDataChanged = true` per image and collecting per-image timeout/error warnings.
- **Usage:**
  ```dart
  warnings.addAll(await _forceDownloadImages(config, appDir, referencedImages));
  ```
  (`lib/shared/services/webdav_service.dart:2232-2234`, inside
  [`_forceDownloadLocked`](#forcedownloadlocked).)
- **Notes:** Image names are immutable UUIDs, so an image already present locally is always kept
  as-is (never re-downloaded/overwritten) — this asymmetric behavior (skip a failed listing rather
  than falling back to "download everything," unlike [`_forceUploadImages`](#forceuploadimages))
  is safe because a download that isn't attempted just leaves the local file as a harmless warning,
  whereas force upload skipping images could leave the remote permanently incomplete.

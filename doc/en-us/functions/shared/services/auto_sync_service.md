# lib/shared/services/auto_sync_service.dart

`AutoSyncService` is the singleton that decides *when* WebDAV sync runs automatically, as opposed
to `WebDavService` (documented separately) which decides *how* a sync cycle merges data. It mixes
in `WidgetsBindingObserver` so it can react to app lifecycle changes, holds an in-memory sync
health status (last success/failure time, last error, pending-conflict flag) consumed by the
Settings and WebDAV pages, and fans out two kinds of listener callbacks: "local data changed"
(pages reload their in-memory state after a sync writes files) and "status changed" (UI refreshes
sync health banners). See [WebDAV Sync](../../../sync.md) for the full trigger list and the
`_syncing`/re-entrancy contract this service is part of, and
[Backup & Restore](../../../backup-restore.md) for how backup restore interacts with the
local-data-changed notification path.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AutoSyncService._` | constructor (`AutoSyncService`) | B | Private constructor backing the singleton. |
| [`lastSuccessAt`](#lastsuccessat) | getter (`AutoSyncService`) | B | Last successful sync time. |
| [`lastFailureAt`](#lastfailureat) | getter (`AutoSyncService`) | B | Last failed sync time. |
| [`lastError`](#lasterror) | getter (`AutoSyncService`) | B | Most recent sync failure message. |
| [`hasPendingConflicts`](#haspendingconflicts) | getter (`AutoSyncService`) | B | Whether auto-sync found unresolved conflicts. |
| `addOnLocalDataChanged` | method (`AutoSyncService`) | B | Register a local-data-changed listener. |
| `removeOnLocalDataChanged` | method (`AutoSyncService`) | B | Unregister a local-data-changed listener. |
| `addOnStatusChanged` | method (`AutoSyncService`) | B | Register a sync-status listener. |
| `removeOnStatusChanged` | method (`AutoSyncService`) | B | Unregister a sync-status listener. |
| [`recordSyncResult`](#recordsyncresult) | method (`AutoSyncService`) | A | Record a sync result triggered outside the auto-sync loop. |
| [`notifyLocalDataChangedIfNeeded`](#notifylocaldatachangedifneeded) | method (`AutoSyncService`) | A | Notify reload listeners if sync wrote local files. |
| [`notifyLocalDataChangedNow`](#notifylocaldatachangednow) | method (`AutoSyncService`) | A | Unconditionally notify reload listeners. |
| [`recordFinalizeResult`](#recordfinalizeresult) | method (`AutoSyncService`) | A | Record a finalize-pending-sync (conflict resolution upload) result. |
| [`start`](#start) | method (`AutoSyncService`) | A | Start the lifecycle observer, periodic timer, and an immediate sync. |
| [`stop`](#stop) | method (`AutoSyncService`) | A | Tear down timers and the lifecycle observer. |
| [`notifySaved`](#notifysaved) | method (`AutoSyncService`) | A | Schedule a debounced sync after a local save. |
| [`requestSyncNow`](#requestsyncnow) | method (`AutoSyncService`) | A | Trigger an immediate sync, bypassing the debounce. |
| [`didChangeAppLifecycleState`](#didchangeapplifecyclestate) | method (`AutoSyncService`, override) | A | React to app resume: sync and refresh mobile reminder schedules. |
| [`_trySync`](#_trysync) | method (`AutoSyncService`) | A | Core guarded sync attempt used by every trigger. |
| [`_recordSuccess`](#_recordsuccess) | method (`AutoSyncService`) | A | Record success state and notify status listeners. |
| [`_recordFailure`](#_recordfailure) | method (`AutoSyncService`) | A | Record failure/conflict state and notify status listeners. |
| [`_notifyStatusChanged`](#_notifystatuschanged) | method (`AutoSyncService`) | A | Invoke all registered status-changed callbacks. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/services/auto_sync_service.dart` returns 22,
matching the 22 rows above exactly. Every block documents a real declaration immediately below it
(constructor, getter, or method) — no misattached blocks and no undocumented declarations were
found in this file.

## Documentation

### `void recordSyncResult(SyncResult result)` <a id="recordsyncresult"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 103)
- **Purpose:** Update the in-memory sync status from a `SyncResult` produced by a sync run that
  happened outside `_trySync` (i.e. a manual sync triggered from the WebDAV page).
- **Inputs:** `result` — the `SyncResult` returned by `WebDAVService.sync(...)`.
- **Returns:** None.
- **Side effects:** Updates `_lastSuccessAt`/`_lastFailureAt`/`_lastError`/`_hasPendingConflicts`
  and notifies status-changed listeners.
- **Algorithm:**
  1. If `result.hasConflicts`, call `_recordFailure` with a "Sync conflicts require manual
     resolution" message (appending `result.error` if present) and `conflicts: true`.
  2. Else if `!result.success`, call `_recordFailure` with `result.error` or a generic
     "Unknown sync failure" message.
  3. Else call `_recordSuccess()`.
- **Usage:**
  ```dart
  AutoSyncService.instance.recordSyncResult(result);
  AutoSyncService.instance.notifyLocalDataChangedIfNeeded();
  ```
  (`lib/shared/views/webdav_config_page.dart:172-173`, after a manual sync completes.)
- **Notes:** None.

### `void notifyLocalDataChangedIfNeeded()` <a id="notifylocaldatachangedifneeded"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 124)
- **Purpose:** Reload open pages after a manual sync or force operation wrote local data files.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Consumes `WebDAVService`'s local-data-changed flag (resets it) and, if it was
  set, invokes every registered `_onLocalDataChanged` callback.
- **Algorithm:**
  1. Call `WebDAVService.consumeLocalDataChanged()`.
  2. If it returned `true`, iterate a snapshot copy (`List.of(_onLocalDataChanged)`) and invoke
     each callback.
- **Usage:**
  ```dart
  AutoSyncService.instance.recordSyncResult(result);
  AutoSyncService.instance.notifyLocalDataChangedIfNeeded();
  ```
  (`lib/shared/views/webdav_config_page.dart:172-173`.)
- **Notes:** Iterating a copy rather than `_onLocalDataChanged` directly means a callback that adds
  or removes a listener during the loop cannot trigger a concurrent-modification error.

### `void notifyLocalDataChangedNow()` <a id="notifylocaldatachangednow"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 139)
- **Purpose:** Reload open pages unconditionally after local data files were replaced outside the
  sync flow (backup restore, ZIP import), where `WebDAVService`'s local-data-changed flag was never
  set because no sync ran.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Invokes every registered `_onLocalDataChanged` callback.
- **Algorithm:** Iterate a snapshot copy of `_onLocalDataChanged` and invoke each callback — no
  flag check, unlike [`notifyLocalDataChangedIfNeeded`](#notifylocaldatachangedifneeded).
- **Usage:**
  ```dart
  AutoSyncService.instance.notifyLocalDataChangedNow();
  ```
  (`lib/shared/views/backup_page.dart:217`, called after a successful backup restore.)
- **Notes:** None.

### `void recordFinalizeResult(bool ok)` <a id="recordfinalizeresult"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 150)
- **Purpose:** Record the outcome of uploading resolved sync conflicts (`finalizePendingSync`).
- **Inputs:** `ok` — whether the finalize upload succeeded.
- **Returns:** None.
- **Side effects:** Updates in-memory sync status and notifies status listeners.
- **Algorithm:** If `ok`, call `_recordSuccess()`; otherwise call `_recordFailure('Failed to
  upload resolved sync conflicts')`.
- **Usage:**
  ```dart
  AutoSyncService.instance.recordFinalizeResult(ok);
  ```
  (`lib/shared/views/webdav_config_page.dart:196`, after the user resolves conflicts manually.)
- **Notes:** None.

### `void start()` <a id="start"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 164)
- **Purpose:** Start the auto-sync lifecycle: register the app-lifecycle observer, start the
  15-minute periodic timer, and sync immediately (the "app start" trigger).
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Registers `this` with `WidgetsBinding.instance.addObserver`, starts
  `_periodic`, and kicks off an async `_trySync()`.
- **Algorithm:**
  1. Return immediately if already `_started` (idempotent).
  2. Set `_started = true` and register as a `WidgetsBindingObserver`.
  3. Cancel any stale `_periodic` timer and start a new `Timer.periodic(_periodicInterval, ...)`
     (`_periodicInterval` = 15 minutes) that calls `_trySync()` on each tick.
  4. Call `_trySync()` once immediately.
- **Usage:**
  ```dart
  AutoSyncService.instance.start();
  ```
  (`lib/main.dart:54`, called once at app startup, right after `ReminderService.instance.start()`.)
- **Notes:** None.

### `void stop()` <a id="stop"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 181)
- **Purpose:** Cancel the debounce and periodic timers and unregister the lifecycle observer,
  reversing everything `start()` set up.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Cancels `_debounce`/`_periodic`, calls
  `WidgetsBinding.instance.removeObserver(this)`, and resets `_started = false`.
- **Algorithm:** Cancel and null both timers, remove the observer, clear `_started`.
- **Usage:** No call site exists in `lib/` or `test/` in this repo — `start()` is called exactly
  once at app startup (`lib/main.dart:54`) and the service is expected to run for the process
  lifetime. `stop()` is provided as the symmetric teardown API to `start()`.
- **Notes:** Because nothing currently calls this, it is effectively dead code in production, kept
  for symmetry/testability.

### `void notifySaved()` <a id="notifysaved"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 197)
- **Purpose:** Schedule a sync 30 seconds after the last local save, debouncing rapid successive
  saves into a single sync.
- **Inputs:** None (called by storage save paths after they finish writing).
- **Returns:** None.
- **Side effects:** Cancels any pending `_debounce` timer and starts a new one.
- **Algorithm:**
  1. Return immediately if the service has not been `start()`-ed yet.
  2. Cancel any existing `_debounce` timer.
  3. Start a new `Timer(_debounceDuration, _trySync)` (`_debounceDuration` = 30 seconds).
- **Usage:**
  ```dart
  AutoSyncService.instance.notifySaved();
  ```
  (`lib/features/todo/views/todo_page.dart:179`, and similarly in the weight, finance, intimacy,
  and exchange-rates pages after a local save.)
- **Notes:** The early return before `start()` means storage writes that happen during app
  bootstrap (before `AutoSyncService.instance.start()` runs) cannot schedule a premature sync.

### `void requestSyncNow()` <a id="requestsyncnow"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 208)
- **Purpose:** Trigger a sync as soon as possible, skipping the 30-second debounce window.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Cancels any pending debounce timer and starts an unawaited `_trySync()`.
- **Algorithm:** Cancel and null `_debounce`, then call `unawaited(_trySync())`.
- **Usage:**
  ```dart
  AutoSyncService.instance.requestSyncNow();
  ```
  (`lib/shared/views/webdav_config_page.dart:117`, right after saving/enabling a fully configured
  auto-sync WebDAV setup.)
- **Notes:** None.

### `void didChangeAppLifecycleState(AppLifecycleState state)` <a id="didchangeapplifecyclestate"></a>
- **Kind:** method of `AutoSyncService` (override of `WidgetsBindingObserver`)
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 221)
- **Purpose:** Sync and refresh mobile reminder schedules when the app resumes from background.
- **Inputs:** `state` — the new `AppLifecycleState`.
- **Returns:** None.
- **Side effects:** May trigger `_trySync()` and `ReminderService.instance.refreshMobileSchedules()`.
- **Algorithm:** If `state == AppLifecycleState.resumed`, call `_trySync()` then
  `ReminderService.instance.refreshMobileSchedules()`.
- **Usage:** Not called directly by app code — invoked by the Flutter framework via
  `WidgetsBinding` because `start()` registers `this` with
  `WidgetsBinding.instance.addObserver(this)`.
- **Notes:** Only `resumed` is handled; other lifecycle states (`inactive`, `paused`, `detached`,
  `hidden`) are ignored.

### `Future<void> _trySync()` <a id="_trysync"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 235)
- **Purpose:** The single guarded entry point every trigger (start, timer, debounce, resume,
  requestSyncNow) funnels through to actually run a sync.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** May call `WebDAVService.sync`, update sync status, and invoke
  `_onLocalDataChanged` callbacks.
- **Algorithm:**
  1. Return immediately if `_syncing` is already `true` (overlapping triggers are silently
     skipped, not surfaced as a failure).
  2. Load the WebDAV config; return silently if it is missing, not configured
     (`!config.isConfigured`), or auto-sync is disabled (`!config.autoSync`).
  3. Set `_syncing = true`.
  4. Call `WebDAVService.sync(config)`.
  5. Classify the result the same way as [`recordSyncResult`](#recordsyncresult): conflicts →
     `_recordFailure(..., conflicts: true)`; failure → `_recordFailure(result.error ?? '...')`;
     success → `_recordSuccess()`.
  6. If `WebDAVService.consumeLocalDataChanged()` is `true`, invoke every `_onLocalDataChanged`
     callback.
  7. Catch any exception and record it via `_recordFailure(e.toString())`.
  8. Always clear `_syncing = false` in `finally`.
- **Usage:** Called only internally — from `start()` (periodic timer tick and the immediate
  app-start call), from the `Timer` scheduled by `notifySaved()`, from `requestSyncNow()`, and from
  `didChangeAppLifecycleState()` on resume. Never called directly by UI code.
- **Notes:** The `_syncing` guard is why overlapping triggers never produce a spurious "Sync
  already in progress" failure banner — they are dropped silently instead of recorded as an error.

### `void _recordSuccess()` <a id="_recordsuccess"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 270)
- **Purpose:** Record a successful sync and clear any prior failure/conflict state.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Sets `_lastSuccessAt = DateTime.now()`, clears `_lastError` and
  `_hasPendingConflicts`, then calls `_notifyStatusChanged()`.
- **Algorithm:** Straight-line field assignment followed by `_notifyStatusChanged()`.
- **Usage:** Called internally from [`recordSyncResult`](#recordsyncresult), [`_trySync`](#_trysync),
  and [`recordFinalizeResult`](#recordfinalizeresult) on the success path.
- **Notes:** None.

### `void _recordFailure(String error, {bool conflicts = false})` <a id="_recordfailure"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 282)
- **Purpose:** Record a failed (or conflicted) sync status.
- **Inputs:** `error` — the message to surface; `conflicts` — whether this failure represents
  unresolved record conflicts rather than a hard error.
- **Returns:** None.
- **Side effects:** Sets `_lastFailureAt`, `_lastError`, and `_hasPendingConflicts`, then calls
  `_notifyStatusChanged()`.
- **Algorithm:** Straight-line field assignment followed by `_notifyStatusChanged()`.
- **Usage:** Called internally from [`recordSyncResult`](#recordsyncresult), [`_trySync`](#_trysync),
  and [`recordFinalizeResult`](#recordfinalizeresult) on the failure path.
- **Notes:** None.

### `void _notifyStatusChanged()` <a id="_notifystatuschanged"></a>
- **Kind:** method of `AutoSyncService`
- **Source:** `lib/shared/services/auto_sync_service.dart` (line 294)
- **Purpose:** Fan out a status change to every registered UI listener.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Invokes every callback in `_onStatusChanged`.
- **Algorithm:** Iterate a snapshot copy (`List.of(_onStatusChanged)`) and invoke each callback.
- **Usage:** Called internally from `_recordSuccess()` and `_recordFailure()`. Listeners are
  registered with `addOnStatusChanged`, e.g.
  ```dart
  AutoSyncService.instance.addOnStatusChanged(_refreshSyncStatus);
  ```
  (`lib/shared/views/webdav_config_page.dart:46`, and similarly in `settings_page.dart:79`.)
- **Notes:** Iterating a copy avoids concurrent-modification issues if a listener
  adds/removes another listener while being notified.

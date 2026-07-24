# lib/shared/views/webdav_config_page.dart

The WebDAV Sync screen: server/credentials/remote-path fields, test-connection, manual sync-now
(with conflict resolution), force-upload/force-download (with destructive-action confirmation),
auto-sync toggle, disconnect, and a live sync-progress/status display. This is the page-level
counterpart to [`WebDAVService`](../services/webdav_service.md) — nearly every button here is a thin
wrapper around a `WebDAVService` call, except that this file itself owns the wake-lock
acquire/release around each network operation, the conflict-dialog hand-off into
`finalizePendingSync`, and the mapping from raw sync state to what the user sees. See
[WebDAV Sync](../../../sync.md) for the full 10-step sync flow, the force-operation and wake-lock
rules this page implements, and [Sync Walkthrough](../../../examples/sync-walkthrough.md) for a
worked cross-module conflict example that ends up back at this page's `SyncConflictDialog`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `WebDAVConfigPage({super.key})` | constructor (`WebDAVConfigPage`) | B | Create a WebDAV config page instance. |
| `createState` | method (`WebDAVConfigPage`) | B | Create the mutable state object for this widget. |
| `initState` | method (`_WebDAVConfigPageState`) | B | Register the sync-status listener and load the saved config. |
| `_refreshSyncStatus` | method (`_WebDAVConfigPageState`) | B | Trigger a rebuild when background sync status changes. |
| `_loadConfig` | method (`_WebDAVConfigPageState`) | B | Load the saved WebDAV config into the text controllers. |
| `dispose` | method (`_WebDAVConfigPageState`) | B | Unregister the listener and dispose the text controllers. |
| `_currentConfig` | getter (`_WebDAVConfigPageState`) | B | Build a `WebDAVConfig` from the current form fields. |
| [`_saveConfig`](#saveconfig) | method (`_WebDAVConfigPageState`) | A | Save the form as the WebDAV config, triggering an immediate sync if newly fully configured. |
| `_testConnection` | method (`_WebDAVConfigPageState`) | B | Test connectivity with the current form values. |
| [`_syncNow`](#syncnow) | method (`_WebDAVConfigPageState`) | A | Run a manual sync, routing conflicts through `SyncConflictDialog` and `finalizePendingSync`. |
| [`_showSyncResult`](#showsyncresult) | method (`_WebDAVConfigPageState`) | A | Present a non-conflict sync/force result as a dialog or snackbar depending on outcome. |
| [`_forceUpload`](#forceupload) | method (`_WebDAVConfigPageState`) | A | Confirm and run a destructive force upload (local overwrites remote). |
| [`_forceDownload`](#forcedownload) | method (`_WebDAVConfigPageState`) | A | Confirm and run a destructive force download (remote overwrites local). |
| `_confirmForceAction` | method (`_WebDAVConfigPageState`) | B | Show the shared destructive-confirmation dialog for force upload/download. |
| `_progressText` | method (`_WebDAVConfigPageState`) | B | Map a `SyncProgress` phase to a localized status line. |
| `_showSyncDialog` | method (`_WebDAVConfigPageState`) | B | Show a scrollable dialog for a long sync message. |
| [`_syncStatusText`](#syncstatustext) | method (`_WebDAVConfigPageState`) | A | Build the auto-sync health summary line (failure/conflict/last-success/none). |
| `_disconnect` | method (`_WebDAVConfigPageState`) | B | Clear the saved WebDAV config and reset the form. |
| `_fillNextcloud` | method (`_WebDAVConfigPageState`) | B | Fill the server URL/path fields with a Nextcloud WebDAV preset. |
| `build` | method (`_WebDAVConfigPageState`) | B | Build the WebDAV config page's widget subtree for the current state. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/views/webdav_config_page.dart` returns 20. All 20
blocks document real declarations — no misattached blocks and no undocumented real declarations were
found. The `_urlController`/`_userController`/`_passController`/`_pathController` and boolean state
fields have no `Purpose:` block, consistent with them being state, not functions.

## Documentation

### `Future<void> _saveConfig()` <a id="saveconfig"></a>
- **Kind:** method of `_WebDAVConfigPageState`
- **Source:** `lib/shared/views/webdav_config_page.dart` (line 112)
- **Purpose:** Persist the current form as the WebDAV config, and if the freshly saved config is
  both fully configured and has auto-sync on, immediately kick off a background sync rather than
  waiting for the next auto-sync trigger.
- **Inputs:** None (reads `_currentConfig`, built from the form controllers and `_autoSync`).
- **Returns:** `Future<void>`.
- **Side effects:** Writes `webdav_config.json` via `WebDAVService.saveConfig`; updates
  `_isConfigured`; may call `AutoSyncService.instance.requestSyncNow()`; shows a confirmation
  snackbar.
- **Algorithm:**
  1. Build `config` from `_currentConfig` and save it via `WebDAVService.saveConfig(config)`.
  2. Update `_isConfigured` from `config.isConfigured`.
  3. If `config.isConfigured && config.autoSync`, call
     `AutoSyncService.instance.requestSyncNow()` to trigger sync immediately instead of waiting for
     the next periodic/resume/debounce trigger.
  4. If still mounted, show a "config saved" snackbar.
- **Usage:**
  ```dart
  Expanded(
    child: FilledButton(
      onPressed: _saveConfig,
      child: Text(AppLocalizations.of(context)!.commonSave),
    ),
  ),
  ```
- **Notes:** Step 3 is the concrete implementation of the "saving/enabling a fully configured
  auto-sync WebDAV setup" trigger listed in
  [WebDAV Sync](../../../sync.md#auto-sync-triggers) — without it, the first sync after initial
  setup would have to wait for app start/resume/the 15-minute timer/a 30-second save-debounce
  instead of running right away.

### `Future<void> _syncNow()` <a id="syncnow"></a>
- **Kind:** method of `_WebDAVConfigPageState`
- **Source:** `lib/shared/views/webdav_config_page.dart` (line 161)
- **Purpose:** Run a manual WebDAV sync under the screen wake lock, and if it surfaces record
  conflicts, hand them to `SyncConflictDialog` and finalize the user's resolutions.
- **Inputs:** None (reads `_currentConfig`).
- **Returns:** `Future<void>`.
- **Side effects:** Acquires/releases the sync wake lock (twice, if conflicts are resolved); calls
  `WebDAVService.sync` and possibly `WebDAVService.finalizePendingSync`; records results on
  `AutoSyncService`; notifies local-data-changed listeners; shows a conflict dialog and/or
  snackbars.
- **Algorithm:**
  1. Set `_syncing = true`, acquire the wake lock, and call `WebDAVService.sync(_currentConfig)`
     inside a `try/finally` that always releases the wake lock and clears `_syncing`.
  2. Record the result and call `AutoSyncService.instance.notifyLocalDataChangedIfNeeded()`
     regardless of outcome.
  3. If `result.hasConflicts`: show `SyncConflictDialog(conflicts: result.pending!.allConflicts)`
     (non-dismissible). If the user produces resolutions and is still mounted: set `_syncing = true`
     again, re-acquire the wake lock, call
     `WebDAVService.finalizePendingSync(_currentConfig, result.pending!, resolutions)` inside another
     `try/finally`, record the finalize outcome via `recordFinalizeResult(ok)`, and show a
     success/failure snackbar. If the user dismissed the dialog without resolving, instead record the
     original (still-conflicted) result again and show a failure snackbar.
  4. If there were no conflicts, call [`_showSyncResult`](#showsyncresult) to present the plain
     success/warning/failure outcome.
- **Usage:**
  ```dart
  FilledButton.icon(
    onPressed: _syncing ? null : _syncNow,
    icon: _syncing ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.sync),
    label: Text(_syncing
        ? AppLocalizations.of(context)!.settingsWebDAVSyncing
        : AppLocalizations.of(context)!.settingsWebDAVSyncNow),
  ),
  ```
- **Notes:** The wake lock is acquired and released around each of the two network phases
  separately (initial sync, then finalize-after-resolution) rather than held across the conflict
  dialog itself — the user could otherwise sit on the resolution dialog indefinitely while the
  screen wake lock stays on. This mirrors the manual-sync path described in
  [WebDAV Sync](../../../sync.md#the-10-step-sync-flow) (steps 8-9), and the same finalize call is
  what the [Sync Walkthrough](../../../examples/sync-walkthrough.md) example ends with.

### `Future<void> _showSyncResult(SyncResult result)` <a id="showsyncresult"></a>
- **Kind:** method of `_WebDAVConfigPageState`
- **Source:** `lib/shared/views/webdav_config_page.dart` (line 230)
- **Purpose:** Present a non-conflict sync or force-operation result to the user, choosing between a
  scrollable error/warning dialog and a plain success snackbar depending on what happened.
- **Inputs:** `result` — a `SyncResult` with no pending conflicts.
- **Returns:** `Future<void>`.
- **Side effects:** Shows either an `AlertDialog` (failure or warnings) or a `SnackBar` (plain
  success).
- **Algorithm:**
  1. If unmounted, return immediately.
  2. If `!result.success`, show a dialog with the failure title and `result.error` (or `'-'`), and
     return.
  3. Else if `result.warnings` is non-empty, show a dialog with the success title and a message
     combining the warning count and the joined warning list, and return — warnings (e.g. individual
     image transfer failures) are shown even though the overall sync succeeded.
  4. Otherwise show a plain success snackbar.
- **Usage:**
  ```dart
  } else {
    await _showSyncResult(result);
  }
  ```
  (called from [`_syncNow`](#syncnow) for the no-conflicts case, and from `_forceUpload`/
  `_forceDownload` for every outcome.)
- **Notes:** Warnings never get silently dropped in favor of the "success" snackbar — per
  [WebDAV Sync](../../../sync.md#retry-heartbeat-and-wake-lock), individual image transfer failures
  are non-fatal but are still surfaced through `SyncResult.warnings`, and this method is what
  actually shows them to the user instead of just reporting overall success.

### `Future<void> _forceUpload()` <a id="forceupload"></a>
- **Kind:** method of `_WebDAVConfigPageState`
- **Source:** `lib/shared/views/webdav_config_page.dart` (line 258)
- **Purpose:** After explicit destructive-action confirmation, overwrite the remote data with local
  data, holding the screen wake lock for the duration.
- **Inputs:** None (reads `_currentConfig`).
- **Returns:** `Future<void>`.
- **Side effects:** Overwrites remote data files/images via `WebDAVService.forceUpload`; acquires and
  releases the wake lock; records the result and notifies local-data-changed listeners; shows a
  result dialog/snackbar via `_showSyncResult`.
- **Algorithm:**
  1. Show the shared force-action confirmation dialog via `_confirmForceAction` with upload-specific
     copy; return if declined or unmounted.
  2. Set `_syncing = true`, acquire the wake lock, call `WebDAVService.forceUpload(_currentConfig)`
     inside a `try/finally` that releases the lock and clears `_syncing`.
  3. Record the result, call `notifyLocalDataChangedIfNeeded()`, and present it via
     [`_showSyncResult`](#showsyncresult).
- **Usage:**
  ```dart
  Expanded(
    child: OutlinedButton.icon(
      onPressed: _syncing ? null : _forceUpload,
      icon: const Icon(Icons.upload, size: 18),
      label: Text(AppLocalizations.of(context)!.settingsWebDAVForceUpload),
    ),
  ),
  ```
- **Notes:** The wake lock is acquired only *after* confirmation, never speculatively before the user
  decides — matching the rule in
  [WebDAV Sync](../../../sync.md#retry-heartbeat-and-wake-lock) that force operations "require a
  destructive-action confirmation dialog" and only hold the lock across the actual transfer.

### `Future<void> _forceDownload()` <a id="forcedownload"></a>
- **Kind:** method of `_WebDAVConfigPageState`
- **Source:** `lib/shared/views/webdav_config_page.dart` (line 289)
- **Purpose:** After explicit destructive-action confirmation, overwrite local data with remote
  data, holding the screen wake lock for the duration.
- **Inputs:** None (reads `_currentConfig`).
- **Returns:** `Future<void>`.
- **Side effects:** Overwrites local data files/images via `WebDAVService.forceDownload`; acquires
  and releases the wake lock; records the result and notifies local-data-changed listeners; shows a
  result dialog/snackbar via `_showSyncResult`.
- **Algorithm:** Identical shape to [`_forceUpload`](#forceupload): confirm with
  download-specific copy, guard on decline/unmounted, run `WebDAVService.forceDownload` under the
  wake lock with `_syncing` tracked around it, then record and present the result.
- **Usage:**
  ```dart
  Expanded(
    child: OutlinedButton.icon(
      onPressed: _syncing ? null : _forceDownload,
      icon: const Icon(Icons.download, size: 18),
      label: Text(AppLocalizations.of(context)!.settingsWebDAVForceDownload),
    ),
  ),
  ```
- **Notes:** Unlike `WebDAVService.forceUpload`, `forceDownload` takes no remote lock (it's
  download-only) — see [WebDAV Sync](../../../sync.md#retry-heartbeat-and-wake-lock) — but this
  page still holds the local screen wake lock and the `_syncing` busy flag identically for both
  operations, since both are long-running foreground transfers from the user's point of view.

### `String? _syncStatusText()` <a id="syncstatustext"></a>
- **Kind:** method of `_WebDAVConfigPageState`
- **Source:** `lib/shared/views/webdav_config_page.dart` (line 404)
- **Purpose:** Build the one-line auto-sync health summary shown above the sync controls,
  distinguishing a genuine two-sided conflict from an ordinary failure, and falling back to the last
  success time when there's no error at all.
- **Inputs:** None (reads `AutoSyncService.instance.lastError`/`hasPendingConflicts`/
  `lastSuccessAt`).
- **Returns:** `String?` — `null` when there is nothing to show (no error and no recorded success
  yet).
- **Side effects:** None.
- **Algorithm:**
  1. If `lastError != null`: return a conflict-labeled string if `hasPendingConflicts`, otherwise a
     failure-labeled string — both include the raw error text.
  2. Else if `lastSuccessAt != null`: return a "last success at `<local time>`" string.
  3. Else return `null`.
- **Usage:**
  ```dart
  if (_isConfigured) ...[
    if (_syncStatusText() != null) ...[
      Card(
        color: AutoSyncService.instance.lastError == null
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_syncStatusText()!, ...),
        ),
      ),
  ```
- **Notes:** Checking `hasPendingConflicts` before falling back to a generic failure message is what
  keeps a genuine two-sided conflict from being reported as an indistinguishable "sync failed" —
  per [WebDAV Sync](../../../sync.md#auto-sync-triggers), "failures are never silently swallowed;
  conflicts are never auto-resolved by LWW in the background," and this is the method that surfaces
  that distinction in the UI. `build` calls this getter-like method twice (once to check for `null`,
  once to render), so it is not cached between those two calls.

## Related pages

- [WebDAV Sync](../../../sync.md) — the full 10-step sync flow, auto-sync triggers, retry/heartbeat/
  wake-lock rules, and force-operation semantics this page wraps.
- [Sync Walkthrough](../../../examples/sync-walkthrough.md) — a worked cross-module conflict that
  resolves through this page's `SyncConflictDialog` and `_syncNow`'s finalize path.
- [`WebDAVService`](../services/webdav_service.md) — the service behind every network call this page
  makes.
- [`sync_conflict_dialog.md`](../widgets/sync_conflict_dialog.md) — the conflict-resolution dialog
  shown by `_syncNow`.

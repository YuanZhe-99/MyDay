# lib/shared/views/backup_page.dart

The Backup screen: auto-backup toggle/retention settings, a manual "back up now" action, and a
history list supporting per-backup delete and module-selective restore. Almost all of the actual
backup/retention/blob-GC mechanics live in
[`BackupService`](../services/backup_service.md#createbackup) — this file is mostly thin UI wiring
around it, except for `_restoreBackup` and `_handlePostRestoreSync`, which implement the
auto-sync-disable-before-restore safety rule and the post-restore force-upload offer directly in the
view (they own the `WebDAVService` calls that surround `BackupService.restoreBackup`, not just the
restore call itself). See [Backup & Restore](../../../backup-restore.md) for the full safety-rule
description and [WebDAV Sync](../../../sync.md) for why disabling auto-sync before restore matters.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `BackupPage({super.key})` | constructor (`BackupPage`) | B | Create a backup page instance. |
| `createState` | method (`BackupPage`) | B | Create the mutable state object for this widget. |
| `initState` | method (`_BackupPageState`) | B | Kick off the initial settings/backup-list load. |
| `_load` | method (`_BackupPageState`) | B | Load auto-backup settings and the backup list into state. |
| `_createBackup` | method (`_BackupPageState`) | B | Create a manual backup and reload the list. |
| `_toggleAutoBackup` | method (`_BackupPageState`) | B | Toggle and persist the auto-backup setting. |
| `_setRetention` | method (`_BackupPageState`) | B | Set and persist the retention window in days. |
| `_deleteBackup` | method (`_BackupPageState`) | B | Confirm and delete one backup. |
| [`_restoreBackup`](#restorebackup) | method (`_BackupPageState`) | A | Confirm, disable auto-sync, and restore a backup's selected modules/images. |
| [`_handlePostRestoreSync`](#handlepostrestoresync) | method (`_BackupPageState`) | A | Offer a force-upload of the restored data after a successful restore. |
| `build` | method (`_BackupPageState`) | B | Build the Backup page's widget subtree for the current state. |
| `_buildSection` | method (widget helper) | B | Render one titled settings section. |
| `_RestoreModuleDialog({required this.availableModules})` | constructor (`_RestoreModuleDialog`) | B | Create a restore-module-selection dialog instance. |
| `createState` | method (`_RestoreModuleDialog`) | B | Create the mutable state object for this dialog. |
| `initState` | method (`_RestoreModuleDialogState`) | B | Pre-select every available module. |
| `build` | method (`_RestoreModuleDialogState`) | B | Build the module-selection checkbox list. |
| `_localizedModuleName` | method (`_RestoreModuleDialogState`) | B | Map a module id to its localized display name. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/views/backup_page.dart` returns 17. All 17 blocks
document real declarations — no misattached blocks and no undocumented real declarations were found.
The `_retentionOptions` and `_moduleLabels` static const fields have no `Purpose:` block, consistent
with them being data, not functions.

## Documentation

### `Future<void> _restoreBackup(BackupInfo info)` <a id="restorebackup"></a>
- **Kind:** method of `_BackupPageState`
- **Source:** `lib/shared/views/backup_page.dart` (line 149)
- **Purpose:** Let the user pick which modules to restore from a backup, confirm the destructive
  action, disable WebDAV auto-sync *before* any data file is written if it was enabled, run the
  restore, and then hand off to the post-restore sync offer.
- **Inputs:** `info` — the `BackupInfo` entry being restored.
- **Returns:** `Future<void>`.
- **Side effects:** May disable (and, on a no-op failure, re-enable) WebDAV auto-sync in
  `webdav_config.json`; overwrites local data files and images via `BackupService.restoreBackup`;
  reloads open pages and mobile reminder schedules; shows dialogs/snackbars; may chain into
  `_handlePostRestoreSync`.
- **Algorithm:**
  1. Fetch `availableModules` for the backup via `BackupService.getBackupModules(info.file)`; bail
     out with a failure snackbar if it comes back empty (bundle unreadable).
  2. Show `_RestoreModuleDialog` to let the user pick a subset of modules; bail out if the user
     picked none.
  3. Show a destructive-confirmation `AlertDialog`; bail out unless confirmed.
  4. Load the current WebDAV config; compute `hadAutoSync = webDavConfigured && config.autoSync`.
     If `hadAutoSync`, immediately save the config with `autoSync: false` — **before** calling
     `restoreBackup`, and with no `mounted` check, so a crash or page disposal between this line and
     the first file write can never leave auto-sync on with stale restored data pending upload.
  5. Call `BackupService.restoreBackup(info.file, moduleKeys: selected)`.
  6. If the restore failed (`!result.ok`): re-enable auto-sync only if `hadAutoSync &&
     !result.wroteAnything` (i.e. local data is guaranteed untouched); show a failure snackbar; return
     without touching reminders or offering a force upload.
  7. On success: call `AutoSyncService.instance.notifyLocalDataChangedNow()` and
     `ReminderService.instance.refreshMobileSchedules()` so open pages and reminder timers reflect the
     restored data; if `missingImages > 0`, show a warning snackbar naming the count.
  8. Call `_handlePostRestoreSync(webDavConfigured ? config : null)` to offer the force-upload step.
- **Usage:**
  ```dart
  IconButton(
    icon: const Icon(Icons.restore),
    tooltip: l10n.backupRestore,
    onPressed: b.corrupt ? null : () => _restoreBackup(b),
  ),
  ```
- **Notes:** Step 4's "disable before write, no `mounted` gate" ordering is the concrete
  implementation of the safety rule described in
  [Backup & Restore](../../../backup-restore.md#restore-validation-and-the-auto-sync-disable-before-restore-safety-rule)
  — reversing steps 4 and 5 (restoring first, then disabling sync) would leave a window where a
  background sync could run against already-restored-but-not-yet-protected local data.

### `Future<void> _handlePostRestoreSync(WebDAVConfig? config)` <a id="handlepostrestoresync"></a>
- **Kind:** method of `_BackupPageState`
- **Source:** `lib/shared/views/backup_page.dart` (line 246)
- **Purpose:** After a successful restore, ask the user whether to force-upload the restored data to
  the WebDAV remote (when WebDAV is configured) so an ordinary background sync doesn't instead treat
  the restored-old data as a fresh edit and propagate it — including deletions — to other devices.
- **Inputs:** `config` — the `WebDAVConfig` loaded by `_restoreBackup` before the restore, or `null`
  if WebDAV sync isn't configured.
- **Returns:** `Future<void>`.
- **Side effects:** If confirmed, acquires the sync wake lock, calls `WebDAVService.forceUpload`,
  releases the wake lock, and records the result with `AutoSyncService.instance.recordSyncResult`;
  shows dialogs/snackbars either way.
- **Algorithm:**
  1. If `config` is `null` (WebDAV not configured), just show a plain restore-success snackbar and
     return — there's nothing to offer.
  2. Otherwise show a non-dismissible `AlertDialog` explaining that sync was disabled and offering to
     force-upload now; bail out (leaving auto-sync off) if the user declines or the widget was
     unmounted.
  3. If confirmed: acquire `SyncWakeLock`, call `WebDAVService.forceUpload(config)` inside a
     `try/finally` that always releases the wake lock regardless of success/failure/exception.
  4. If still mounted, record the result via `AutoSyncService.instance.recordSyncResult(result)` and
     show a success/failure snackbar based on `result.success`.
- **Usage:**
  ```dart
  if (!mounted) return;
  await _handlePostRestoreSync(webDavConfigured ? config : null);
  ```
  (called at the end of [`_restoreBackup`](#restorebackup), only after a successful restore.)
- **Notes:** This method never re-enables auto-sync itself, on either the accept or skip path — the
  user is left to explicitly re-enable it later from the WebDAV page, since forcing a decision here
  (rather than silently turning sync back on) is what prevents restored-old data from being merged
  and propagated automatically. See the wake-lock reference-counting and force-operation rules in
  [WebDAV Sync](../../../sync.md#retry-heartbeat-and-wake-lock).

## Related pages

- [Backup & Restore](../../../backup-restore.md) — the backup format, blob GC, retention, and
  restore-safety rules this page's actions trigger.
- [WebDAV Sync](../../../sync.md) — force-upload/wake-lock mechanics used by
  `_handlePostRestoreSync`, and why restoring disables auto-sync first.
- [`BackupService`](../services/backup_service.md) — the service backing every backup/restore/list
  call this page makes.

# Backup, Restore, and Import/Export

Primary source: the "Backup, Import, Export, and Images" section of `AGENTS.md`, cross-checked
against `lib/shared/services/backup_service.dart` (skimmed for the blob GC mechanism).

## Backup format v2

`BackupService` manages manual backups, a daily auto-backup, retention, and module-selective
restore. Each `backups/backup_*.json` bundle stores data-module JSON strings plus an `_imageRefs`
map pointing at content-addressed image blobs under `backups/blobs/<sha256><ext>`
(`lib/shared/services/backup_service.dart`, `_blobSubDir = 'blobs'`). Identical images across
backups are stored once and shared: when a backup is created, referenced image files are hashed and
deduplicated into the shared blob store, and the bundle records only `refs['images/<name>'] =
'<hash><ext>'` (`bundle['_imageRefs'] = refs`) rather than embedding the image bytes again.

Legacy v1 bundles that instead embed inline base64 `_images` remain restorable — restore checks
`_imageRefs` (v2 blob references) first, then falls back to the legacy inline base64 path.

## Blob garbage collection

- A blob is physically deleted only when **no remaining backup** references it.
- GC runs after create/delete/retention operations.
- GC **aborts entirely** if any remaining bundle is unparseable — the reference set would be
  unknown, so nothing is deleted under uncertainty:

  > Unknown reference set: never delete blobs under uncertainty.

- GC never deletes blobs younger than a **10-minute grace window**
  (`static const _blobGcGrace = Duration(minutes: 10);`), so a blob written by a backup that is
  concurrently being created cannot be raced and deleted before that backup's bundle file finishes
  referencing it.

## Retention and corrupt-bundle handling

- Bundle writes are atomic via `DataFileSafety`.
- Corrupt (unparseable) bundles are flagged in the backup history with restore disabled, and they
  do **not** count as "already backed up today" — so an interrupted auto-backup is retried on the
  next opportunity instead of being silently considered done.
- `runAutoBackupIfNeeded()` is re-entrancy guarded and runs from the 30-second `ReminderService`
  loop on every platform.
- `BackupService` config I/O goes through `TodoStorage.readConfig()`/`writeConfig()`, consistent
  with the rest of the app's config-preservation rule (see [Architecture](architecture.md)).
- Retention includes a 3-day option alongside the longer retention periods.

## Restore validation and the auto-sync-disable-before-restore safety rule

- **Validation before writing anything:** restore validates every selected module payload via
  `DataFileSafety.validateDataJson` (the same typed-exception validation path used for normal
  loads — see [Architecture](architecture.md)) before writing any file, then writes atomically.
- **Image name sanitization:** restored image names are sanitized to flat `images/<name>` only;
  path-traversal or absolute paths are rejected.
- **Auto-sync disabled before the first write:** when WebDAV auto-sync is enabled, restoring a
  backup disables auto-sync in `webdav_config.json` *before* the first data file is written — with
  no `mounted` gate — so a crash or page disposal mid-restore can never leave restored-old data with
  auto-sync still switched on (which would otherwise let the next background sync propagate
  restored-old data, including deletions, to the remote and to other devices).
- **`RestoreResult`:** `BackupService.restoreBackup` returns a `RestoreResult` with `ok`,
  `wroteAnything`, and `missingImages`. Auto-sync is re-enabled only when the restore failed **and**
  `wroteAnything == false` (i.e. local data is guaranteed untouched) — any restore that wrote at
  least one file keeps auto-sync off until the user explicitly deals with it.
- **After a successful restore**, the backup page:
  1. reloads open pages (`AutoSyncService.notifyLocalDataChangedNow()`),
  2. refreshes mobile reminder schedules,
  3. warns when v2 image blobs were missing from the blob store
     (`backupRestoreMissingImages`), and
  4. — only when WebDAV sync is configured — asks whether to force-upload the restored data (wake
     lock held for the duration, result recorded in sync status).

  Without step 4, the next ordinary sync would treat restored-old data as if it were a fresh local
  edit/deletion and propagate it outward to the remote and other devices.

## Import/Export — ZIP-only, no more CSV/JSON

`ImportExportService` handles Settings import/export, and it is **ZIP-only** for all five data JSON
files plus images (the older CSV/JSON-file import flows were removed in v1.1.1).

- ZIP import extracts **only allowlisted entries**: the five data JSON files, plus flat files under
  `images/`.
- The resolved output path is confined to the app directory, so a crafted ZIP cannot escape it to
  overwrite configuration files such as `webdav_config.json` or `storage_config.json` — this is the
  same **path-traversal protection** principle used for restored image names above.
- Imported data JSON files are strictly UTF-8 decoded (so Chinese and other non-ASCII text survives
  import correctly), validated before anything is replaced (again via `DataFileSafety`), and written
  through tmp-then-rename.

`ImageService` picks local images, downloads logos/photos, stores them under `images/` with UUID
filenames, resolves relative paths, and rejects tiny placeholder downloads (a defense against
broken/blank image URLs being saved as real images).

## Related pages

- [Architecture](architecture.md) — `DataFileSafety` validation and atomic-write mechanics reused
  here.
- [WebDAV Sync](sync.md) — why disabling auto-sync before restore matters, and the force-upload
  offer after a successful restore.
- [Data Formats](data-formats.md) — the five data JSON files these backup/import flows cover.

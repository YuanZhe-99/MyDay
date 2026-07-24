# lib/shared/services/backup_service.dart

`BackupService` implements MyDay's local backup/restore feature: manual "back up now", the daily
auto-backup driven by `ReminderService`'s 30-second loop, retention cleanup, and module-selective
restore. It owns the backup-format-v2 content-addressed image blob store
(`backups/blobs/<sha256><ext>`) and its garbage collector, and cooperates with `WebDAVService`
and `AutoSyncService` around the auto-sync-disable-before-restore safety rule. See
[Backup & Restore](../../../backup-restore.md) for the full format description, the blob GC rules,
and the restore/force-upload interaction with sync, and [Architecture](../../../architecture.md)
for `DataFileSafety`'s validation/atomic-write contract that this file relies on.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `appDirProvider` | static field | B | Test-only hook to redirect backup I/O to a temp directory. |
| [`_getAppDir`](#_getappdir) | method (static, `BackupService`) | A | Resolve the app data directory, honoring the test override. |
| [`_getBackupDir`](#_getbackupdir) | method (static, `BackupService`) | A | Resolve (and create) the `backups/` directory. |
| [`_getBlobDir`](#_getblobdir) | method (static, `BackupService`) | A | Resolve (and create) the `backups/blobs/` directory. |
| [`loadSettings`](#loadsettings) | method (static, `BackupService`) | A | Load auto-backup settings from `storage_config.json`. |
| [`saveSettings`](#savesettings) | method (static, `BackupService`) | A | Save auto-backup settings to `storage_config.json`. |
| [`createBackup`](#createbackup) | method (static, `BackupService`) | A | Create a v2 backup bundle, dedup images into blobs, run retention + GC. |
| [`runAutoBackupIfNeeded`](#runautobackupifneeded) | method (static, `BackupService`) | A | Run the daily auto-backup if enabled and not already done today. |
| [`listBackups`](#listbackups) | method (static, `BackupService`) | A | List all backups newest-first, detecting corruption and blob sizes. |
| [`getBackupModules`](#getbackupmodules) | method (static, `BackupService`) | A | Return which data modules a backup bundle contains. |
| [`_safeImageRelativePath`](#_safeimagerelativepath) | method (static, `BackupService`) | A | Sanitize a backup image key into a safe `images/<name>` path. |
| [`restoreBackup`](#restorebackup) | method (static, `BackupService`) | A | Validate and restore selected modules/images from a backup bundle. |
| [`deleteBackup`](#deletebackup) | method (static, `BackupService`) | A | Delete a backup bundle and GC now-unreferenced blobs. |
| [`_cleanOldBackups`](#_cleanoldbackups) | method (static, `BackupService`) | A | Delete backups older than the retention window. |
| [`_collectUnreferencedBlobs`](#_collectunreferencedblobs) | method (static, `BackupService`) | A | Garbage-collect image blobs no remaining backup references. |
| [`RestoreResult.new`](#restoreresult-new) | constructor (`RestoreResult`) | A | Create a restore-outcome result (model constructor). |
| [`BackupInfo.new`](#backupinfo-new) | constructor (`BackupInfo`) | A | Create a backup-listing entry (model constructor). |
| [`displaySize`](#displaysize) | getter (`BackupInfo`) | A | Human-readable size string (B/KB/MB). |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/services/backup_service.dart` returns 18. 17 of
those blocks document real methods, constructors, or a getter (the 17 Tier A rows above). The
18th (`appDirProvider`, line 47) documents a **static field**, not a function/method/constructor/
getter/setter — per the tiering instructions it does not count as a Tier A "declaration with real
logic," so it is listed above as a Tier B field row (it gets no full Tier A entry below) rather
than silently folded into the 17. No misattached blocks (a block documenting a call-site statement
instead of a declaration) and no undocumented real declarations were found in this file; the
`modules` static const map (line 51) and other private fields have plain `///` comments but no
`Purpose:` block, consistent with them being data, not functions.

## Documentation

### `static Future<Directory> _getAppDir()` <a id="_getappdir"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 63)
- **Purpose:** Resolve the app data directory, honoring the `appDirProvider` test override.
- **Inputs:** None.
- **Returns:** `Future<Directory>` — the app directory (real or test-provided).
- **Side effects:** None.
- **Algorithm:** If the static `appDirProvider` field is non-null, call and return it; otherwise
  return `TodoStorage.getAppDir()`.
- **Usage:** Called internally throughout this file, e.g. inside `createBackup()`:
  `final appDir = await _getAppDir();`. Tests set the override directly:
  `BackupService.appDirProvider = () async => tempDir;` (`test/backup_service_test.dart:20`).
- **Notes:** None.

### `static Future<Directory> _getBackupDir()` <a id="_getbackupdir"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 74)
- **Purpose:** Resolve the `backups/` directory, creating it if missing.
- **Inputs:** None.
- **Returns:** `Future<Directory>`.
- **Side effects:** May create `<appDir>/backups` on disk.
- **Algorithm:** Resolve the app dir via `_getAppDir()`, join with `_backupDir` ("backups"), create
  it recursively if it doesn't exist, and return it.
- **Usage:** Called internally, e.g. `createBackup()`: `final backupDir = await _getBackupDir();`
- **Notes:** None.

### `static Future<Directory> _getBlobDir()` <a id="_getblobdir"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 88)
- **Purpose:** Resolve the shared content-addressed image blob directory (`backups/blobs/`),
  creating it if missing.
- **Inputs:** None.
- **Returns:** `Future<Directory>`.
- **Side effects:** May create `backups/blobs/` on disk.
- **Algorithm:** Resolve the backups dir via `_getBackupDir()`, join with `_blobSubDir` ("blobs"),
  create it recursively if missing, and return it.
- **Usage:** Called internally from `createBackup()`, `listBackups()`, `restoreBackup()`, and
  `_collectUnreferencedBlobs()`.
- **Notes:** None.

### `static Future<void> loadSettings()` <a id="loadsettings"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 104)
- **Purpose:** Load `autoBackupEnabled` and `backupRetentionDays` from `storage_config.json` into
  the class's static settings fields.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads `storage_config.json` via `TodoStorage.readConfig()` and mutates the
  static `autoBackupEnabled`/`retentionDays` fields.
- **Algorithm:** Read config; set `autoBackupEnabled = config['autoBackupEnabled'] as bool? ??
  false`; set `retentionDays = config['backupRetentionDays'] as int? ?? 0`.
- **Usage:**
  ```dart
  await BackupService.loadSettings();
  final backups = await BackupService.listBackups();
  ```
  (`lib/shared/views/backup_page.dart:53-54`.)
- **Notes:** Uses `TodoStorage.readConfig()`/`writeConfig()` so config access stays in one place
  and keys written by other modules (tray settings, API settings, etc.) are preserved.

### `static Future<void> saveSettings()` <a id="savesettings"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 116)
- **Purpose:** Persist `autoBackupEnabled`/`retentionDays` back to `storage_config.json`.
- **Inputs:** None (reads current static field values).
- **Returns:** `Future<void>`.
- **Side effects:** Writes `storage_config.json` via `TodoStorage.writeConfig()`.
- **Algorithm:** Call `TodoStorage.writeConfig({'autoBackupEnabled': ..., 'backupRetentionDays':
  ...})`.
- **Usage:**
  ```dart
  await BackupService.saveSettings();
  ```
  (`lib/shared/views/backup_page.dart:94`, after the user changes auto-backup settings.)
- **Notes:** `TodoStorage.writeConfig()` is a merge-write, so unrelated config keys are preserved.

### `static Future<File?> createBackup()` <a id="createbackup"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 131)
- **Purpose:** Create a new v2 backup bundle containing all present data-module JSON files plus
  deduplicated image references, then run retention cleanup and blob GC.
- **Inputs:** None.
- **Returns:** `Future<File?>` — the written bundle file, or `null` if any step threw.
- **Side effects:** Reads the 5 data-module files and the `images/` directory; writes new blob
  files under `backups/blobs/`; writes a new `backups/backup_<timestamp>.json` bundle atomically;
  may delete old backups and unreferenced blobs.
- **Algorithm:**
  1. Resolve the app dir and backups dir.
  2. Start `bundle = {'_backupFormat': 2}`.
  3. For each of the 5 module files (`modules.keys`), if it exists on disk, read its full string
     content into `bundle[name]`.
  4. If `images/` exists: for every file in it, compute `sha256` of its bytes, derive
     `blobName = '<hash><ext>'`; write the bytes to `backups/blobs/<blobName>` via
     `DataFileSafety.atomicWriteBytes` only if that blob doesn't already exist (content
     deduplication); record `refs['images/<basename>'] = blobName`. If any refs were collected,
     set `bundle['_imageRefs'] = refs`.
  5. `jsonEncode` the bundle and write it atomically to
     `backups/backup_<yyyyMMdd_HHmmss>.json` via `DataFileSafety.atomicWriteString`.
  6. Call `_cleanOldBackups()` then `_collectUnreferencedBlobs()`.
  7. Return the file. Any exception anywhere in the above is caught and returns `null`.
- **Usage:**
  ```dart
  final file = await BackupService.createBackup();
  ```
  (`lib/shared/views/backup_page.dart:72`, for a manual "back up now" action.)
- **Notes:** Because identical image bytes hash to the same blob name, backing up the same images
  repeatedly never duplicates blob storage — only the small JSON bundle grows per backup.

### `static Future<void> runAutoBackupIfNeeded()` <a id="runautobackupifneeded"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 188)
- **Purpose:** Run the daily auto-backup exactly once per day, if enabled, tolerating process
  restarts and interrupted (corrupt) prior attempts.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** May call `createBackup()` (which writes files); mutates `_lastAutoBackup`.
- **Algorithm:**
  1. Return immediately if `_autoBackupRunning` (re-entrancy guard); otherwise set it `true`.
  2. Call `loadSettings()`; return if `!autoBackupEnabled`.
  3. If `_lastAutoBackup` is set and its calendar day is not before today, return (already backed
     up today per the in-memory marker).
  4. Otherwise call `listBackups()` and check whether any **non-corrupt** backup's date matches
     today; if so, just set `_lastAutoBackup = now` and return (handles the case where the
     in-memory marker was lost, e.g. process restart, but a valid file already exists).
  5. Otherwise call `createBackup()` and set `_lastAutoBackup = now`.
  6. Always clear `_autoBackupRunning` in `finally`.
- **Usage:**
  ```dart
  await BackupService.runAutoBackupIfNeeded();
  ```
  (`lib/shared/services/reminder_service.dart:608`, inside `_check()`, run on every platform as
  part of the 30-second reminder loop.)
- **Notes:** Step 4's `if (b.corrupt) return false;` filter is why a corrupt/interrupted bundle
  from earlier today does **not** count as "already backed up" — the next opportunity retries it
  instead of silently treating today as done.

### `static Future<List<BackupInfo>> listBackups()` <a id="listbackups"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 236)
- **Purpose:** Enumerate all backup bundles, newest first, flagging corrupt ones and including
  referenced blob sizes in the displayed size.
- **Inputs:** None.
- **Returns:** `Future<List<BackupInfo>>`, sorted by date descending.
- **Side effects:** None (read-only).
- **Algorithm:**
  1. Return `[]` if the backups directory doesn't exist.
  2. For each `backup_*.json` file: parse its date from the filename
     (`backup_yyyyMMdd_HHmmss`), falling back to the file's mtime if the filename doesn't parse.
  3. If the file's size is `<= _probeMaxBytes` (4 MiB), parse its JSON; on success, add the size of
     every blob referenced via `_imageRefs` (that exists on disk) to `sizeBytes`; on parse failure,
     mark `corrupt = true`. Larger (legacy inline-image) bundles skip parsing and are listed by raw
     file size alone.
  4. Sort the resulting list by `date` descending.
- **Usage:**
  ```dart
  final backups = await BackupService.listBackups();
  ```
  (`lib/shared/views/backup_page.dart:54`, populating the backup list UI.)
- **Notes:** The `_probeMaxBytes` cap avoids fully parsing very large legacy v1 bundles (which
  embed inline base64 images) just to list them.

### `static Future<List<String>> getBackupModules(File file)` <a id="getbackupmodules"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 300)
- **Purpose:** Report which data modules (by module id, e.g. `'todo'`, `'finance'`) a given backup
  bundle actually contains, for the module-selective restore UI.
- **Inputs:** `file` — the backup bundle file.
- **Returns:** `Future<List<String>>` of module ids; `[]` if the file can't be parsed.
- **Side effects:** None (read-only).
- **Algorithm:** Parse the bundle JSON; filter `modules.entries` to those whose filename key
  (`e.key`) is present in the bundle; map to module ids (`e.value`). Any exception yields `[]`.
- **Usage:**
  ```dart
  final availableModules = await BackupService.getBackupModules(info.file);
  ```
  (`lib/shared/views/backup_page.dart:152`, before showing per-module restore checkboxes.)
- **Notes:** None.

### `static String? _safeImageRelativePath(String rawKey)` <a id="_safeimagerelativepath"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 319)
- **Purpose:** Sanitize an image key from a backup bundle into a safe, flat `images/<name>`
  relative path, rejecting anything that could escape the `images/` directory.
- **Inputs:** `rawKey` — the raw key string from `_imageRefs` or legacy `_images`.
- **Returns:** The normalized `images/<name>` path, or `null` if rejected.
- **Side effects:** None.
- **Algorithm:**
  1. Normalize `rawKey` via `p.normalize` and convert `\` to `/`.
  2. Reject (return `null`) unless the normalized path starts with `images/`, has exactly two
     `/`-separated segments, contains no `..`, and is not itself absolute.
  3. Otherwise return the normalized path.
- **Usage:** Called internally from `restoreBackup()` for every `_imageRefs`/`_images` entry:
  `final relPath = _safeImageRelativePath(e.key);`
- **Notes:** This is the path-traversal defense described in
  [Backup & Restore](../../../backup-restore.md) — a crafted bundle key like `../../evil` or
  `images/sub/x.png` is rejected rather than written outside `images/`.

### `static Future<RestoreResult> restoreBackup(File file, {Set<String>? moduleKeys})` <a id="restorebackup"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (lines 343-346)
- **Purpose:** Restore selected data modules (or all, if `moduleKeys` is null) and their images
  from a backup bundle, validating every payload before writing anything.
- **Inputs:** `file` — the bundle to restore; `moduleKeys` — optional set of module ids (e.g.
  `{'todo', 'finance'}`) to restrict the restore to.
- **Returns:** `Future<RestoreResult>` with `ok`, `wroteAnything`, and `missingImages`.
- **Side effects:** May overwrite app data files (`todo_data.json`, etc.) and write image files
  under `images/`, sourced from v2 blob references or the legacy inline-base64 `_images` map.
- **Algorithm:**
  1. Parse the bundle JSON.
  2. For each module file present in the bundle and selected by `moduleKeys` (or all, if `null`),
     validate its content with `DataFileSafety.validateDataJson(fileName, content)` and stage it in
     a local `writes` map — **nothing is written to disk in this step**.
  3. Once every selected module has validated, write each staged file atomically via
     `DataFileSafety.writeValidatedDataJson`, setting `wrote = true` per file actually written.
  4. Restore images: if `bundle['_imageRefs']` is present (v2), for each entry sanitize the key via
     [`_safeImageRelativePath`](#_safeimagerelativepath), look up the blob under
     `backups/blobs/<basename(blobName)>`; if the blob file is missing, increment `missingImages`
     and skip it; otherwise write its bytes to the sanitized path and set `wrote = true`. Else if
     `bundle['_images']` is present (legacy v1), sanitize each key the same way, base64-decode the
     value, and write it directly.
  5. Return `RestoreResult(ok: true, wroteAnything: wrote, missingImages: missingImages)`.
  6. On any exception, return `RestoreResult(ok: false, wroteAnything: wrote, missingImages:
     missingImages)` — `wrote` reflects whatever was actually written before the exception, so the
     caller can tell whether local data was touched at all.
- **Usage:**
  ```dart
  final result = await BackupService.restoreBackup(
    info.file,
    moduleKeys: selected,
  );
  ```
  (`lib/shared/views/backup_page.dart:199-202`. Note the caller disables WebDAV auto-sync via
  `WebDAVService.saveConfig(config.copyWith(autoSync: false))` at `backup_page.dart:196`, **before**
  calling `restoreBackup`, and only re-enables it if `!result.ok && !result.wroteAnything` —
  matching the safety rule in [Backup & Restore](../../../backup-restore.md).)
- **Notes:** Validation happening entirely before any write (step 2 vs. step 3) is what guarantees
  a bad module in a multi-module restore can't leave some files replaced and others not based on
  validation order.

### `static Future<void> deleteBackup(File file)` <a id="deletebackup"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 429)
- **Purpose:** Delete one backup bundle and then garbage-collect any image blobs it was the last
  reference to.
- **Inputs:** `file` — the bundle to delete.
- **Returns:** `Future<void>`.
- **Side effects:** Deletes `file` if it exists; may delete now-unreferenced blob files.
- **Algorithm:** If `file` exists, delete it; then call `_collectUnreferencedBlobs()`.
- **Usage:**
  ```dart
  await BackupService.deleteBackup(info.file);
  ```
  (`lib/shared/views/backup_page.dart:133`, when the user deletes a backup from the list.)
- **Notes:** None.

### `static Future<void> _cleanOldBackups()` <a id="_cleanoldbackups"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 442)
- **Purpose:** Delete backup bundles older than the configured retention window.
- **Inputs:** None (reads the static `retentionDays` field).
- **Returns:** `Future<void>`.
- **Side effects:** Deletes bundle files older than the cutoff.
- **Algorithm:**
  1. Return immediately if `retentionDays <= 0` (0 means keep forever).
  2. Compute `cutoff = DateTime.now().subtract(Duration(days: retentionDays))`.
  3. List all backups and delete every one whose `date.isBefore(cutoff)`.
- **Usage:** Called internally from `createBackup()`, immediately after writing the new bundle.
- **Notes:** Retention supports a 3-day option alongside longer periods (see
  [Backup & Restore](../../../backup-restore.md)); this method itself just compares against
  whatever `retentionDays` currently holds.

### `static Future<void> _collectUnreferencedBlobs()` <a id="_collectunreferencedblobs"></a>
- **Kind:** static method of `BackupService`
- **Source:** `lib/shared/services/backup_service.dart` (line 460)
- **Purpose:** Delete image blobs that no remaining backup bundle references, without ever
  deleting under uncertainty or racing a backup that's being written concurrently.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Deletes files under `backups/blobs/`.
- **Algorithm:**
  1. List all files in the blob directory; return immediately if there are none.
  2. Walk every `backup_*.json` bundle in the backups directory, trying to parse each as JSON.
  3. If **any** bundle fails to parse, abort the entire pass immediately (`return`) — the
     reference set can't be trusted, so nothing is deleted.
  4. Otherwise, collect every blob name referenced by any bundle's `_imageRefs` values into a
     `referenced` set.
  5. For each blob not in `referenced`: skip it if `now.difference(stat.modified) <
     _blobGcGrace` (10 minutes); otherwise delete it, swallowing any delete error.
  6. The whole method is wrapped in a try/catch that swallows any error.
- **Usage:** Called internally from `createBackup()` and `deleteBackup()` after the backup set
  changes.
- **Notes:** Step 3's "abort on any unparseable bundle" and step 5's 10-minute grace window are
  both documented safety invariants in [Backup & Restore](../../../backup-restore.md) — the grace
  window specifically protects a blob written by a backup that is still being created concurrently
  with this GC pass.

### `const RestoreResult({required bool ok, required bool wroteAnything, int missingImages = 0})` <a id="restoreresult-new"></a>
- **Kind:** constructor of `RestoreResult` (model class)
- **Source:** `lib/shared/services/backup_service.dart` (line 518)
- **Purpose:** Construct the outcome of a `restoreBackup()` call.
- **Inputs:** `ok`, `wroteAnything`, `missingImages` (default `0`).
- **Returns:** A new `RestoreResult`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor; no logic.
- **Usage:** Constructed inside [`restoreBackup`](#restorebackup), e.g.
  `return RestoreResult(ok: true, wroteAnything: wrote, missingImages: missingImages);`
- **Notes:** `wroteAnything == false` is the caller's signal that local data is guaranteed untouched
  (used to decide whether re-enabling auto-sync after a failed restore is safe).

### `const BackupInfo({required File file, required DateTime date, required int sizeBytes, bool corrupt = false})` <a id="backupinfo-new"></a>
- **Kind:** constructor of `BackupInfo` (model class)
- **Source:** `lib/shared/services/backup_service.dart` (line 537)
- **Purpose:** Construct one entry of a `listBackups()` result.
- **Inputs:** `file`, `date`, `sizeBytes`, `corrupt` (default `false`).
- **Returns:** A new `BackupInfo`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor; no logic.
- **Usage:** Constructed inside [`listBackups`](#listbackups):
  `files.add(BackupInfo(file: entity, date: date, sizeBytes: sizeBytes, corrupt: corrupt));`
- **Notes:** `sizeBytes` includes referenced blob sizes for v2 bundles (see `listBackups`);
  `corrupt` marks bundles whose JSON could not be parsed.

### `String get displaySize` <a id="displaysize"></a>
- **Kind:** getter of `BackupInfo`
- **Source:** `lib/shared/services/backup_service.dart` (line 549)
- **Purpose:** Format `sizeBytes` as a human-readable string for the backup list UI.
- **Inputs:** None.
- **Returns:** `String` — e.g. `"512 B"`, `"3.4 KB"`, `"1.2 MB"`.
- **Side effects:** None.
- **Algorithm:** If `sizeBytes < 1024`, return `'$sizeBytes B'`. Else if `< 1024*1024`, return
  `sizeBytes/1024` formatted to 1 decimal + `' KB'`. Else return `sizeBytes/(1024*1024)` formatted
  to 1 decimal + `' MB'`.
- **Usage:**
  ```dart
  b.corrupt ? '${b.displaySize} · ${l10n.backupCorrupt}' : b.displaySize,
  ```
  (`lib/shared/views/backup_page.dart:409-410`, in the backup list row.)
- **Notes:** None.

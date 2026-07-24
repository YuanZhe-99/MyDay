# lib/shared/services/import_export_service.dart

Implements the Settings page's ZIP-only export/import of all five app data JSON files plus
`images/`. Import validates every data file through `DataFileSafety` before writing anything and
guards against path traversal from a crafted ZIP. See
[../../../backup-restore.md#import-export--zip-only-no-more-csv-json](../../../backup-restore.md#import-export--zip-only-no-more-csv-json).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`exportZIP`](#exportzip) | static method (`ImportExportService`) | A | Export all app data as a ZIP file. |
| [`importZIP`](#importzip) | static method (`ImportExportService`) | A | Import app data from a ZIP file. |
| [`_isInside`](#_isinside) | static method (`ImportExportService`) | A | Return whether a resolved path stays inside the app directory. |

`grep -c 'Purpose:' lib/shared/services/import_export_service.dart` reports 3, matching all three
real declarations (the `_dataFileNames` static const list is a plain data field, not a
function/method, and is not counted separately). No misattachment found.

## Documentation

### `static Future<String?> exportZIP(String destDir)` <a id="exportzip"></a>
- **Kind:** static method of `ImportExportService`
- **Source:** `lib/shared/services/import_export_service.dart` (line 25)
- **Purpose:** Bundle every existing data JSON file and every image under `images/` into a single
  timestamped ZIP written to `destDir`.
- **Inputs:** `destDir` — destination directory chosen by the caller (typically via a directory
  picker).
- **Returns:** `Future<String?>` — the written ZIP's absolute path, or `null` on any failure.
- **Side effects:** Reads the five data JSON files (only the ones that exist) and every file under
  `<appDir>/images/`; writes one new `myday_backup_<yyyyMMdd_HHmmss>.zip` file into `destDir`.
- **Algorithm:**
  1. Build an in-memory `Archive`.
  2. For each of the five fixed data file names, add it to the archive only if the file exists.
  3. If `<appDir>/images/` exists, list it and add every regular file under `images/<basename>`.
  4. `ZipEncoder().encode(archive)`, then write the bytes to
     `<destDir>/myday_backup_<timestamp>.zip` with `flush: true`.
  5. Return the output path; any exception anywhere in the process is caught and converted to a
     `null` return.
- **Usage:**
  ```dart
  final dir = await FilePicker.platform.getDirectoryPath();
  if (dir == null || !mounted) return;
  final path = await ImportExportService.exportZIP(dir);
  ```
  (`lib/features/settings/views/settings_page.dart`, `_exportData`.)
- **Notes:** Unlike `BackupService`, this export is a flat one-shot ZIP with no content-addressed
  blob deduplication and no retention policy — it is meant for manual, one-off portability, not the
  recurring local backup system.

### `static Future<bool> importZIP(String filePath)` <a id="importzip"></a>
- **Kind:** static method of `ImportExportService`
- **Source:** `lib/shared/services/import_export_service.dart` (line 64)
- **Purpose:** Restore app data from a previously exported ZIP, validating every data file and
  rejecting path traversal before writing anything to disk.
- **Inputs:** `filePath` — path to a `.zip` file (typically chosen via a file picker restricted to
  the `zip` extension).
- **Returns:** `Future<bool>` — `true` only when the ZIP was fully validated and imported.
- **Side effects:** Replaces the allowlisted data JSON files and adds/overwrites files under
  `<appDir>/images/` — but only after every entry has been validated (see Algorithm).
- **Algorithm:**
  1. Return `false` if the ZIP file does not exist; otherwise decode it with `ZipDecoder`.
  2. For every archive entry, normalize its name with `p.url.normalize(...).replaceAll('\\', '/')`
     and reject the whole import (`return false`) if the normalized name starts with `../` or
     contains `/../` (path-traversal guard).
  3. If the normalized name is one of the five known data file names, UTF-8 decode its content,
     call `DataFileSafety.validateDataJson(normalized, content)` (throws
     `DataFileValidationException` on any schema mismatch, which propagates and aborts the whole
     import via the outer `try`/`catch`), and stage it in `dataWrites`.
  4. If the name starts with `images/`, require it to be a flat `images/<basename>` entry (reject
     otherwise) and stage the raw bytes in `imageWrites`.
  5. Any entry that is neither a known data file nor a flat `images/` entry aborts the import
     (`return false`) — this is the ZIP-import allowlist.
  6. Only after every entry has passed steps 2-5: for each staged data write, re-check
     `_isInside(appRoot, target.absolute.path)` and call
     `DataFileSafety.writeValidatedDataJson(target, content)` (atomic tmp-then-rename, re-validating
     just before the write).
  7. For each staged image write, re-check `_isInside` and call
     `DataFileSafety.atomicWriteBytes(target, bytes)`.
  8. Return `true`; any exception anywhere (including a validation throw from step 3) is caught and
     converted to a `false` return, leaving already-written files from earlier iterations in place
     only if a *later* entry fails — validation happens up front for all data files during the
     parsing pass, so a bad data JSON aborts before any file is written, but a failure between step
     6 and 7 mid-loop could leave a partial write. See Notes.
- **Usage:**
  ```dart
  final success = await ImportExportService.importZIP(result.files.single.path!);
  ```
  (`lib/features/settings/views/settings_page.dart`, `_importData`, after a user confirmation
  dialog.)
- **Notes:** Import validates all five data-file entries during the parsing pass (step 3) before
  any file is written, so a corrupt/incompatible data JSON blocks the entire import. The
  path-confinement check (`_isInside`) is a second, redundant safety net on top of the traversal
  rejection already done during normalization (step 2) — both must pass for a write to happen.

### `static bool _isInside(String rootPath, String childPath)` <a id="_isinside"></a>
- **Kind:** private static method of `ImportExportService`
- **Source:** `lib/shared/services/import_export_service.dart` (line 124)
- **Purpose:** Confirm a resolved destination path stays inside the app root directory.
- **Inputs:** `rootPath` (the app directory); `childPath` (the resolved absolute write target).
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** Normalize both paths with `p.normalize`; return `true` if they are equal or if
  `child` starts with `'$root${p.separator}'`.
- **Usage:** Called before every data/image write in `importZIP`, immediately before the actual
  `DataFileSafety` write call.
- **Notes:** Protects ZIP import from path traversal writes as a second layer beyond the
  entry-name normalization check already performed in `importZIP`.

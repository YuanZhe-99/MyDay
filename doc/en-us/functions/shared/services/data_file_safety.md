# lib/shared/services/data_file_safety.dart

MyDay's shared atomic-write-plus-validation module for the five app data JSON files
(`todo_data.json`, `finance_data.json`, `exchange_rates.json`, `intimacy_data.json`,
`weight_data.json`). Unlike a plain atomic-write helper, `DataFileSafety` also dispatches each file
name to its corresponding model's `fromJson` parser (`TodoData`, `FinanceData`,
`ExchangeRateData`, `IntimacyData`, `WeightData`) so import/restore paths reject invalid or
incompatible JSON *before* anything is written to disk. It backs `ImportExportService`'s ZIP
import (see [import_export_service.md](import_export_service.md)) and `BackupService`'s restore
path (see
[../../../backup-restore.md#restore-validation-and-the-auto-sync-disable-before-restore-safety-rule](../../../backup-restore.md#restore-validation-and-the-auto-sync-disable-before-restore-safety-rule)).
Every module's own storage class (`FinanceStorage`, `IntimacyStorage`, `WeightStorage`,
`TodoStorage`, `ExchangeRateStorage`) also calls `writeValidatedDataJson` for its own saves, per
[../../../architecture.md#core-architecture-rules](../../../architecture.md#core-architecture-rules).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`DataFileValidationException` (constructor)](#datafilevalidationexception-new) | constructor (`DataFileValidationException`) | A | Create a typed validation-failure exception carrying the offending file name. |
| `toString` | method (`DataFileValidationException`) | B | Format the exception as `"<fileName>: <message>"`. |
| `DataFileSafety._()` | constructor (`DataFileSafety`) | B | Prevent instantiation of the static-only utility. |
| [`validateDataJson`](#validatedatajson) | static method (`DataFileSafety`) | A | Validate a known data JSON string against its model's parser. |
| [`writeValidatedDataJson`](#writevalidateddatajson) | static method (`DataFileSafety`) | A | Validate then atomically write a known data JSON file. |
| [`atomicWriteString`](#atomicwritestring) | static method (`DataFileSafety`) | A | Atomically write text through a same-directory temp file. |
| [`atomicWriteBytes`](#atomicwritebytes) | static method (`DataFileSafety`) | A | Atomically write bytes through a same-directory temp file. |

`grep -c 'Purpose:' lib/shared/services/data_file_safety.dart` reports 7, matching all seven real
declarations in this file (the `dataFileNames` static const set is a plain data field, not counted
separately). No misattachment found.

## Documentation

### `const DataFileValidationException(this.fileName, this.message)` <a id="datafilevalidationexception-new"></a>
- **Kind:** const constructor of `DataFileValidationException` (implements `Exception`)
- **Source:** `lib/shared/services/data_file_safety.dart` (line 21)
- **Purpose:** Carry a validation failure's file name and message without overwriting any data.
- **Inputs:** `fileName`, `message`.
- **Returns:** A new `DataFileValidationException`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** Thrown by `validateDataJson` (see below) and caught upstream by
  `ImportExportService.importZIP` / `BackupService.restoreBackup` to report a per-file failure.
- **Notes:** Used to report import/restore failures without overwriting data — every call site
  that can trigger this exception validates before writing.

### `static void validateDataJson(String fileName, String jsonContent)` <a id="validatedatajson"></a>
- **Kind:** static method of `DataFileSafety`
- **Source:** `lib/shared/services/data_file_safety.dart` (line 53)
- **Purpose:** Validate a JSON string against the model parser for its target file name, throwing
  before any caller can write invalid or incompatible data.
- **Inputs:** `fileName` — must be one of the five known data file names; `jsonContent` — raw JSON
  text.
- **Returns:** None (throws on failure).
- **Side effects:** None (pure validation; parses into throwaway model instances).
- **Algorithm:**
  1. Throw `DataFileValidationException(fileName, 'unsupported data file')` if `fileName` is not in
     `dataFileNames`.
  2. `jsonDecode` the content as a `Map<String, dynamic>`.
  3. Dispatch on `fileName` via a `switch` statement, calling the matching model's `fromJson`:
     `todo_data.json` → `TodoData.fromJson`, `finance_data.json` → `FinanceData.fromJson`,
     `exchange_rates.json` → `ExchangeRateData.fromJson`, `intimacy_data.json` →
     `IntimacyData.fromJson`, `weight_data.json` → `WeightData.fromJson`. The parsed result is
     discarded — only successful parsing (no thrown error) matters.
  4. Any exception during decode/parse is caught; a `DataFileValidationException` is rethrown as-is,
     and any other exception is wrapped into a new `DataFileValidationException(fileName,
     e.toString())`.
- **Usage:**
  ```dart
  DataFileSafety.validateDataJson(normalized, content);
  ```
  (`lib/shared/services/import_export_service.dart`, `importZIP`, validating each data file entry
  before staging it for write.)
- **Notes:** This is the per-app validation dispatch: it is the one place that knows the mapping
  from file name to model parser, so adding a sixth data file requires updating both
  `dataFileNames` and this `switch`.

### `static Future<void> writeValidatedDataJson(File file, String jsonContent)` <a id="writevalidateddatajson"></a>
- **Kind:** static method of `DataFileSafety`
- **Source:** `lib/shared/services/data_file_safety.dart` (line 83)
- **Purpose:** Validate JSON content against the destination file's model parser, then atomically
  write it only if validation passes.
- **Inputs:** `file` — the destination `File` (its basename decides which model parser is used);
  `jsonContent`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes a temp file and renames it over `file` (via `atomicWriteString`), but
  only after `validateDataJson` succeeds.
- **Algorithm:** `validateDataJson(p.basename(file.path), jsonContent)` then
  `await atomicWriteString(file, jsonContent)`.
- **Usage:**
  ```dart
  await DataFileSafety.writeValidatedDataJson(target, item.value);
  ```
  (`lib/shared/services/import_export_service.dart`, `importZIP`, writing each validated data file;
  also called directly by `TodoStorage`, `FinanceStorage` (via `exchange_rate_storage.dart`),
  `IntimacyStorage`, and `WeightStorage` for their normal save paths.)
- **Notes:** This is the single entry point every module's storage class uses for its own regular
  saves, not just import/restore — see `../../../architecture.md#core-architecture-rules`.

### `static Future<void> atomicWriteString(File file, String content)` <a id="atomicwritestring"></a>
- **Kind:** static method of `DataFileSafety`
- **Source:** `lib/shared/services/data_file_safety.dart` (line 96)
- **Purpose:** Write text to `file` without ever leaving a partially-written file in place, by
  writing to a same-directory temp file and renaming it over the destination.
- **Inputs:** `file`, `content`.
- **Returns:** `Future<void>`.
- **Side effects:** Creates `file.parent` if missing; creates a `<file>.tmp-<microsecondsEpoch>`
  file; renames it over `file`; on rename failure, best-effort deletes the temp file and throws a
  `FileSystemException`.
- **Algorithm:**
  1. Ensure the parent directory exists.
  2. Write `content` to a uniquely-named temp file in the same directory (`flush: true`).
  3. Attempt `tmp.rename(file.path)` (an atomic replace on the same filesystem/directory).
  4. If the rename throws, best-effort delete the temp file (swallowing any delete error) and
     rethrow as `FileSystemException('Failed to replace file safely: $e', file.path)`.
- **Usage:** Called by `writeValidatedDataJson` and directly by `BackupService` for bundle writes.
- **Notes:** The temp file lives in the *same directory* as the destination specifically so the
  rename is atomic on the same filesystem — a cross-directory or cross-volume temp file would not
  have this guarantee.

### `static Future<void> atomicWriteBytes(File file, List<int> bytes)` <a id="atomicwritebytes"></a>
- **Kind:** static method of `DataFileSafety`
- **Source:** `lib/shared/services/data_file_safety.dart` (line 120)
- **Purpose:** Byte-oriented twin of `atomicWriteString`, used for images and backup blobs.
- **Inputs:** `file`, `bytes`.
- **Returns:** `Future<void>`.
- **Side effects:** Same as `atomicWriteString` but via `writeAsBytes`.
- **Algorithm:** Identical tmp-then-rename sequence as `atomicWriteString`, writing bytes instead
  of a string.
- **Usage:**
  ```dart
  await DataFileSafety.atomicWriteBytes(target, item.value);
  ```
  (`lib/shared/services/import_export_service.dart`, `importZIP`, writing each restored image;
  also used by `BackupService` for blob writes.)
- **Notes:** Used for ZIP image restore after data JSON validation succeeds — images have no
  schema to validate, only the path-confinement check performed by the caller.

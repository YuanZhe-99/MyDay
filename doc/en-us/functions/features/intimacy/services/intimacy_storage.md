# lib/features/intimacy/services/intimacy_storage.dart

Persistence layer for `intimacy_data.json`: loads/saves [`IntimacyData`](../models/intimacy_record.md#intimacydata-new)
through a single serialized write queue, throwing a typed exception when an existing file exists but
cannot be safely read, and delegating the "don't clobber unknown fields" and atomic-write-plus-
validation work to [`JsonPreservation`](../../../shared/utils/json_preservation.md#encodeforfile) and
`DataFileSafety.writeValidatedDataJson` (`lib/shared/services/data_file_safety.dart`) respectively.
It also owns a one-time migration that folds a legacy standalone `timer_history.json` file into
`IntimacyData.timerHistory` on first load. This file has the same shape as every other feature's
storage service in this codebase (compare
[`weight_storage.dart`](../../weight/services/weight_storage.md)). See
[Intimacy](../../../../features/intimacy.md) for the feature this backs and
[Data Formats](../../../../data-formats.md#intimacy--intimacy_datajson) for the exact JSON shape.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`IntimacyStorageException()`](#intimacystorageexception-new) | const constructor (`IntimacyStorageException`) | A | Create an intimacy storage exception with a user-visible message. |
| `IntimacyStorageException.toString` | method (`IntimacyStorageException`) | B | Return the exception's message as its string representation. |
| [`_getFile`](#_getfile) | static method (`IntimacyStorage`) | A | Resolve the on-disk path of `intimacy_data.json`. |
| [`load`](#load) | static method (`IntimacyStorage`) | A | Load and parse `intimacy_data.json`, migrating legacy timer history, or `null` if it doesn't exist. |
| [`save`](#save) | static method (`IntimacyStorage`) | A | Queue a write of `IntimacyData`, serialized against concurrent saves. |
| [`_saveNow`](#_savenow) | static method (`IntimacyStorage`) | A | Perform one preserved, validated, atomic write of `IntimacyData`. |
| [`_migrateLegacyTimerHistory`](#_migratelegacytimerhistory) | static method (`IntimacyStorage`) | A | Fold legacy `timer_history.json` entries into `IntimacyData.timerHistory`, then delete the old file. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/intimacy/services/intimacy_storage.dart` reports
7, matching all 7 real declarations in this file exactly. No misattached doc comments were found and
no undocumented real declaration exists. The class's private static fields (`_fileName`,
`_legacyTimerFileName`, `_writeQueue`) are plain internal plumbing, not counted as declarations, the
same way `weight_storage.dart`'s `fileName`/`_writeQueue` are excluded from its own page. Six of the
seven declarations are Tier A: `IntimacyStorageException`'s constructor is a real (if simple)
model-style constructor, and `_getFile`/`load`/`save`/`_saveNow`/`_migrateLegacyTimerHistory` all
perform real IO or branching per the explicit services/IO Tier A rule. `toString()` is the one Tier B
declaration — a trivial accessor returning a stored field with no logic of its own.

## Documentation

### `const IntimacyStorageException(this.message)` <a id="intimacystorageexception-new"></a>
- **Kind:** const constructor of `IntimacyStorageException`
- **Source:** `lib/features/intimacy/services/intimacy_storage.dart` (line 18)
- **Purpose:** Create an intimacy storage exception carrying a user-visible message, thrown when
  `intimacy_data.json` exists but cannot be safely read or written.
- **Inputs:** `message`.
- **Returns:** A new `IntimacyStorageException`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:**
  ```dart
  throw IntimacyStorageException('$_fileName is not valid JSON: $e');
  ```
  (`load`, line 65; the analogous `'Failed to load $_fileName: $e'` case at line 67 covers any other
  read failure.)
- **Notes:** Implements `Exception` (not `Error`), so it is intended to be caught and shown to the
  user (e.g. as `intimacy_page.dart`'s `_loadError` state, which also blocks `_saveData()` from
  running while the file is unreadable) rather than treated as a programming bug.

### `static Future<File> _getFile()` <a id="_getfile"></a>
- **Kind:** private static method of `IntimacyStorage`
- **Source:** `lib/features/intimacy/services/intimacy_storage.dart` (line 39)
- **Purpose:** Resolve the `File` handle for `intimacy_data.json` inside the app's data directory.
- **Inputs:** None.
- **Returns:** `Future<File>`.
- **Side effects:** None directly (only builds a path; does not touch disk itself).
- **Algorithm:** `appDir = await TodoStorage.getAppDir()`, then `File('${appDir.path}/$_fileName')` —
  the intimacy feature reuses Todo's app-directory resolution rather than defining its own.
- **Usage:** Called at the top of `load()` (line 51), `_saveNow()` (line 91), and
  `_migrateLegacyTimerHistory()` (line 110, to locate the legacy file's sibling directory).
- **Notes:** Depending on `TodoStorage.getAppDir()` means intimacy storage has no independent
  directory-resolution logic to keep in sync if that ever changes.

### `static Future<IntimacyData?> load()` <a id="load"></a>
- **Kind:** static method of `IntimacyStorage`
- **Source:** `lib/features/intimacy/services/intimacy_storage.dart` (line 50)
- **Purpose:** Load and parse `intimacy_data.json`, then migrate any legacy standalone timer-history
  file into it.
- **Inputs:** None.
- **Returns:** `Future<IntimacyData?>` — `null` if the file does not exist.
- **Side effects:** Reads `intimacy_data.json`; may also read, merge, and delete a legacy
  `timer_history.json`, and write the merged result back out.
- **Algorithm:**
  1. Resolve the file via `_getFile()`; if it doesn't exist, return `null` immediately.
  2. Otherwise read it as a string, `jsonDecode` it into a `Map<String, dynamic>`, and build
     `IntimacyData.fromJson(json)`.
  3. Pass the result through [`_migrateLegacyTimerHistory`](#_migratelegacytimerhistory) before
     returning it.
  4. A `FormatException` (invalid JSON) is caught and rethrown as `IntimacyStorageException('$_fileName
     is not valid JSON: $e')`; any other exception (e.g. a `fromJson` cast failure) is rethrown as
     `IntimacyStorageException('Failed to load $_fileName: $e')`.
- **Usage:**
  ```dart
  try {
    data = await IntimacyStorage.load();
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _loadError = e.toString();
      _loaded = true;
    });
    return;
  }
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:176-184`, `_loadData()`.)
- **Notes:** A missing file and a corrupt file are deliberately distinguished: missing -> `null`
  ("no data yet"), corrupt/unreadable -> thrown exception (an error state the UI must surface), so a
  corrupted file is never silently mistaken for an empty dataset.

### `static Future<void> save(IntimacyData data)` <a id="save"></a>
- **Kind:** static method of `IntimacyStorage`
- **Source:** `lib/features/intimacy/services/intimacy_storage.dart` (line 76)
- **Purpose:** Queue a write of `data`, ensuring overlapping `save` calls never interleave their
  writes to `intimacy_data.json`.
- **Inputs:** `data`.
- **Returns:** `Future<void>` that completes when this specific write (including its position in the
  queue) finishes.
- **Side effects:** Eventually writes `intimacy_data.json` (via `_saveNow`); mutates the static
  `_writeQueue` field.
- **Algorithm:**
  1. Chain onto the current `_writeQueue`: `next = _writeQueue.then((_) => _saveNow(data), onError:
     (_) => _saveNow(data))`, so `_saveNow(data)` runs whether the previous queued write succeeded or
     failed.
  2. Replace `_writeQueue` with `next.catchError((_) {})` (an error-swallowing version of `next`) so
     one failed save never permanently poisons the queue for later callers.
  3. Return `next` (the un-swallowed future) so *this* caller still observes any error from its own
     `_saveNow` call.
- **Usage:**
  ```dart
  await IntimacyStorage.save(
    IntimacyData(
      partners: _partners,
      toys: _toys,
      positions: _positions,
      records: _records,
      // ...
    ),
  );
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:234-253`, `_saveData()`.)
- **Notes:** Because `_writeQueue` is a single static field shared by every call, concurrent `save()`
  calls are strictly serialized in call order — the same overlapping-writer protection used by
  `weight_storage.dart`'s `save()`.

### `static Future<void> _saveNow(IntimacyData data)` <a id="_savenow"></a>
- **Kind:** private static method of `IntimacyStorage`
- **Source:** `lib/features/intimacy/services/intimacy_storage.dart` (line 90)
- **Purpose:** Perform one actual write of `data` to `intimacy_data.json`, after the caller has
  already taken its turn in the write queue.
- **Inputs:** `data`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `intimacy_data.json` through a validated temporary file (via
  `DataFileSafety.writeValidatedDataJson`).
- **Algorithm:**
  1. Resolve the file via `_getFile()`.
  2. `JsonPreservation.encodeForFile(file: file, next: data.toJson(), schema:
     dataFilePreservationSchemas[_fileName]!)` — reads whatever is currently on disk and preserves any
     of its unknown fields into `data`'s own serialized JSON.
  3. `DataFileSafety.writeValidatedDataJson(file, jsonStr)` — validates the encoded JSON, then
     atomically replaces the file through a same-directory temp file.
- **Usage:** Only called from `save()`, via the write-queue chain described above.
- **Notes:** `dataFilePreservationSchemas[_fileName]!` asserts a schema exists for
  `'intimacy_data.json'` — it does, so this would only throw if that shared schema map were edited to
  drop the entry.

### `static Future<IntimacyData> _migrateLegacyTimerHistory(IntimacyData data)` <a id="_migratelegacytimerhistory"></a>
- **Kind:** private static method of `IntimacyStorage`
- **Source:** `lib/features/intimacy/services/intimacy_storage.dart` (line 106)
- **Purpose:** Fold entries from an old standalone `timer_history.json` file into
  `IntimacyData.timerHistory`, persist the merge, then delete the legacy file.
- **Inputs:** `data` — the just-loaded `IntimacyData`.
- **Returns:** `Future<IntimacyData>` — `data` unchanged if there is nothing to migrate or if
  anything in the process throws.
- **Side effects:** May read a legacy `timer_history.json`, write the merged `intimacy_data.json` (via
  `save`), and delete `timer_history.json`.
- **Algorithm:**
  1. Resolve the legacy file path; if it doesn't exist, return `data` unchanged.
  2. Read and `jsonDecode` it as a `List`, parsing each entry via
     [`TimerHistoryEntry.fromJson`](../models/intimacy_record.md#timerhistoryentry-fromjson).
  3. Dedupe by start time: build a set of existing `data.timerHistory` start timestamps, keep only
     legacy entries whose start isn't already present.
  4. If any new entries remain, rebuild a new `IntimacyData` with `timerHistory` extended by them
     (explicitly copying every other field across) and `await save(data)` the result.
  5. Delete the legacy file unconditionally (whether or not new entries were merged) and return the
     (possibly updated) `data`.
  6. The whole method is wrapped in a `try`/`catch` that swallows any error and returns the original
     `data` unchanged — a migration failure never blocks a normal load.
- **Usage:** Called unconditionally at the end of `load()` (line 61): `data =
  await _migrateLegacyTimerHistory(data);`.
- **Notes:** Runs on every successful `load()`, not just once — after the first successful migration
  the legacy file no longer exists, so step 1's existence check makes every subsequent call a cheap
  no-op.

## Related pages

- [Intimacy](../../../../features/intimacy.md) — the feature this storage layer backs, including the
  timer/stopwatch session persistence this file's `IntimacyData.timerHistory` migration feeds into.
- [`intimacy_record.dart`](../models/intimacy_record.md) — `IntimacyData`, `TimerHistoryEntry`, and
  every other model serialized/parsed here.
- [Data Formats](../../../../data-formats.md#intimacy--intimacy_datajson) — the exact JSON shape of
  `intimacy_data.json`.
- [`weight_storage.dart`](../../weight/services/weight_storage.md) — the near-identical sibling
  storage service this file's write-queue/exception/atomic-write pattern mirrors.

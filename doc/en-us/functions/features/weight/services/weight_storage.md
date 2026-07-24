# lib/features/weight/services/weight_storage.dart

Persistence layer for `weight_data.json`: loads/saves [`WeightData`](../models/weight_record.md)
via a single serialized write queue, throwing a typed exception when an existing file exists but
can't be safely read, and delegating the actual "don't clobber unknown fields" and
atomic-write-plus-validation work to
[`JsonPreservation`](../../../shared/utils/json_preservation.md#encodeforfile) and
`DataFileSafety.writeValidatedDataJson` (`lib/shared/services/data_file_safety.dart`) respectively.
See [Weight](../../../../features/weight.md) for the feature this backs.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`WeightStorageException` (constructor)](#weightstorageexception-new) | const constructor (`WeightStorageException`) | A | Create a weight storage exception with a user-visible message. |
| `WeightStorageException.toString` | method (`WeightStorageException`) | B | Return the exception's message as its string representation. |
| [`_getFile`](#_getfile) | static method (`WeightStorage`) | A | Resolve the on-disk path of `weight_data.json`. |
| [`load`](#load) | static method (`WeightStorage`) | A | Load and parse `weight_data.json`, or `null` if it doesn't exist. |
| [`save`](#save) | static method (`WeightStorage`) | A | Queue a write of `WeightData`, serialized against concurrent saves. |
| [`_saveNow`](#_savenow) | static method (`WeightStorage`) | A | Perform one preserved, validated, atomic write of `WeightData`. |

`grep -c 'Purpose:' lib/features/weight/services/weight_storage.dart` reports 6, matching all six
real declarations in this file exactly. No misattached doc comments were found and no undocumented
real declaration exists. Five of the six declarations are Tier A: `WeightStorageException`'s
constructor is a real (if simple) model-style constructor, and `_getFile`/`load`/`save`/`_saveNow`
all perform real IO or branching per the explicit services/IO Tier A rule. `toString()` is the one
Tier B declaration — a trivial accessor returning a stored field with no logic of its own, matching
the "trivial getters/setters" Tier B bucket.

## Documentation

### `const WeightStorageException(this.message)` <a id="weightstorageexception-new"></a>
- **Kind:** const constructor of `WeightStorageException`
- **Source:** `lib/features/weight/services/weight_storage.dart` (line 18)
- **Purpose:** Create a weight storage exception carrying a user-visible message, thrown when
  `weight_data.json` exists but cannot be safely read or written.
- **Inputs:** `message`.
- **Returns:** A new `WeightStorageException`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:**
  ```dart
  throw WeightStorageException('$fileName is not valid JSON: $e');
  ```
  (`load`, line 59; the analogous "Failed to load $fileName: $e" case at line 61 covers any other
  read failure).
- **Notes:** Implements `Exception` (not `Error`), so it is intended to be caught and shown to the
  user (e.g. via the weight page's `_loadError` state) rather than treated as a programming bug.

### `static Future<File> _getFile()` <a id="_getfile"></a>
- **Kind:** private static method of `WeightStorage`
- **Source:** `lib/features/weight/services/weight_storage.dart` (line 38)
- **Purpose:** Resolve the `File` handle for `weight_data.json` inside the app's data directory.
- **Inputs:** None.
- **Returns:** `Future<File>`.
- **Side effects:** None directly (does not touch disk itself; only builds a path).
- **Algorithm:** `appDir = await TodoStorage.getAppDir()`, then
  `File('${appDir.path}/$fileName')` — the weight feature reuses Todo's app-directory resolution
  rather than defining its own.
- **Usage:** Called at the top of both `load()` (line 50) and `_saveNow()` (line 85).
- **Notes:** Depending on `TodoStorage.getAppDir()` for the app directory means weight storage has
  no independent directory-resolution logic to keep in sync if that changes.

### `static Future<WeightData?> load()` <a id="load"></a>
- **Kind:** static method of `WeightStorage`
- **Source:** `lib/features/weight/services/weight_storage.dart` (line 49)
- **Purpose:** Load and parse `weight_data.json`.
- **Inputs:** None.
- **Returns:** `Future<WeightData?>` — `null` if the file does not exist.
- **Side effects:** Reads `weight_data.json` from disk.
- **Algorithm:**
  1. Resolve the file via `_getFile()`; if it doesn't exist, return `null` immediately.
  2. Otherwise read it as a string and `jsonDecode` it into a `Map<String, dynamic>`, then
     `WeightData.fromJson(json)`.
  3. A `FormatException` (invalid JSON) is caught and rethrown as
     `WeightStorageException('$fileName is not valid JSON: $e')`.
  4. Any other exception (e.g. a `fromJson` cast failure) is caught and rethrown as
     `WeightStorageException('Failed to load $fileName: $e')`.
- **Usage:**
  ```dart
  try {
    data = await WeightStorage.load();
  } catch (e) {
    ReminderService.instance.updateWeightData(records: const []);
    if (!mounted) return;
    setState(() {
      _loadError = e.toString();
      _loaded = true;
    });
    return;
  }
  ```
  (`lib/features/weight/views/weight_page.dart`, lines 100-113, `_loadData()`).
- **Notes:** A missing file and a corrupt file are deliberately distinguished: missing → `null`
  (treated as "no data yet"), corrupt/unreadable → thrown exception (treated as an error state the
  UI must surface), so a corrupted file is never silently mistaken for an empty dataset.

### `static Future<void> save(WeightData data)` <a id="save"></a>
- **Kind:** static method of `WeightStorage`
- **Source:** `lib/features/weight/services/weight_storage.dart` (line 70)
- **Purpose:** Queue a write of `data`, ensuring overlapping `save` calls never interleave their
  writes to `weight_data.json`.
- **Inputs:** `data`.
- **Returns:** `Future<void>` that completes when this specific write (including its position in
  the queue) finishes.
- **Side effects:** Eventually writes `weight_data.json` (via `_saveNow`); mutates the static
  `_writeQueue` field.
- **Algorithm:**
  1. Chain this call onto the current `_writeQueue`: `next = _writeQueue.then((_) =>
     _saveNow(data), onError: (_) => _saveNow(data))` — so `_saveNow(data)` runs whether the
     previous queued write succeeded or failed.
  2. Replace `_writeQueue` with `next.catchError((_) {})` (a version of `next` that swallows its own
     error) so a failed save never permanently poisons the queue for subsequent callers.
  3. Return `next` (the un-swallowed future) to the caller, so *this* caller still observes any
     error from its own `_saveNow` call.
- **Usage:**
  ```dart
  await WeightStorage.save(
    WeightData(height: _height, records: _records, /* ... */),
  );
  ```
  (`lib/features/weight/views/weight_page.dart`, lines 161-172).
- **Notes:** Because `_writeQueue` is a single static field shared by every call, concurrent
  `save()` calls are strictly serialized in call order — a second `save()` started before the first
  completes will always run its `_saveNow` after the first's, never interleaved with it. This is
  the same overlapping-writer protection covered by `test/storage_hardening_test.dart`'s
  concurrent-save regression case.

### `static Future<void> _saveNow(WeightData data)` <a id="_savenow"></a>
- **Kind:** private static method of `WeightStorage`
- **Source:** `lib/features/weight/services/weight_storage.dart` (line 84)
- **Purpose:** Perform one actual write of `data` to `weight_data.json`, after the caller has
  already taken its turn in the write queue.
- **Inputs:** `data`.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `weight_data.json` through a validated temporary file (via
  `DataFileSafety.writeValidatedDataJson`).
- **Algorithm:**
  1. Resolve the file via `_getFile()`.
  2. `JsonPreservation.encodeForFile(file: file, next: data.toJson(), schema:
     dataFilePreservationSchemas[fileName]!)` — reads whatever is currently on disk and preserves
     any of its unknown fields into `data`'s own serialized JSON (see
     [`json_preservation.dart`](../../../shared/utils/json_preservation.md#encodeforfile)).
  3. `DataFileSafety.writeValidatedDataJson(file, jsonStr)` — validates the encoded JSON, then
     atomically replaces the file through a same-directory temp file.
- **Usage:** Only called from `save()`, via the write-queue chain described above.
- **Notes:** `dataFilePreservationSchemas[fileName]!` asserts a schema exists for `'weight_data.json'`
  — it does, defined as `_weightDataSchema` in `json_preservation.dart` — so this would only throw
  if that shared map were ever edited to drop the entry.

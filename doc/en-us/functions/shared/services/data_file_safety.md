# lib/shared/services/data_file_safety.dart

**Split file.** The generic atomic tmp-then-rename writers moved to the `myapps_data` package
(`lib/src/storage/atomic_io.dart`) and are re-exported through thin wrappers here. The validation
dispatch stayed, but now reads the module registry instead of its own hardcoded file list and
`switch` over model parsers.

`DataFileValidationException` also moved to the package with the same shape — `fileName`, `message`,
and the `'$fileName: $message'` `toString()` — and is re-exported, so existing catch sites and the
messages they surface are unchanged.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`DataFileSafety.dataFileNames`](#datafilenames) | static field | A | Known data file names, derived from the registry. |
| [`validateDataJson(fileName, jsonContent)`](#validatedatajson) | static method | A | Throw unless the payload parses for that file. |
| [`writeValidatedDataJson(file, jsonContent)`](#writevalidateddatajson) | static method | A | Validate, then atomically replace. |
| [`atomicWriteString(file, content)`](#atomicwrites) | static method | A | Atomic text replacement. |
| [`atomicWriteBytes(file, bytes)`](#atomicwrites) | static method | A | Atomic byte replacement. |
| `DataFileValidationException` | re-export | A | Typed validation failure, from the package. |

## Documentation

### `dataFileNames` <a id="datafilenames"></a>
- **Kind:** static field, `Set<String>`
- **Notes:** Derived from `todoModuleRegistry`. This used to be one of five separate hardcoded copies
  of the same list; four of those five are now gone.

### `validateDataJson(fileName, jsonContent)` <a id="validatedatajson"></a>
- **Throws:** `DataFileValidationException(fileName, 'unsupported data file')` for a name that is not
  in the registry; otherwise wraps whatever the module's parser throws.
- **Notes:** Behavior and messages are unchanged; only the dispatch mechanism moved from a `switch`
  over file names to a registry lookup, so adding a module no longer means editing this file.

### `writeValidatedDataJson(file, jsonContent)` <a id="writevalidateddatajson"></a>
- **Side effects:** Validates by the destination's basename, then atomically replaces the file.
- **Notes:** Used by backup restore and ZIP import so an invalid payload can never land on disk.

### `atomicWriteString` / `atomicWriteBytes` <a id="atomicwrites"></a>
- **Side effects:** Create parent directories as needed, stage to a same-directory temp file, flush,
  then rename over the destination; temp files are cleaned up best-effort on failure.
- **Notes:** Now one-line delegations to the package implementation.

## Where the engine documentation lives

`packages/myapps_data/doc/en-us/functions/src/storage/atomic_io.md` and
`packages/myapps_data/doc/en-us/functions/src/modules/data_module.md`.

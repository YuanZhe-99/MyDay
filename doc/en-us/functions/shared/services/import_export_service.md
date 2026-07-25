# lib/shared/services/import_export_service.dart

**Facade over the shared engine.** The whole file now delegates to the `myapps_data` package
(`lib/src/data/zip_transfer.dart`). MyDay has no Markdown export, so nothing else remains.

MyDay was already the strictest of the three apps on import, and the engine's **defaults are exactly
its behavior** — reject unknown entries, strict UTF-8 decoding, validate every payload before writing
any, write atomically. No leniency knobs are set here. The other two apps had to adopt the engine's
fixed traversal rejection; MyDay already had it.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`exportZIP(destDir)`](#exportzip) | static method | A | Write `myday_backup_<stamp>.zip`. |
| [`importZIP(filePath)`](#importzip) | static method | A | Restore data and images from an export. |

## Documentation

### `exportZIP(destDir)` <a id="exportzip"></a>
- **Returns:** `Future<String?>` — the written path, or null on failure.
- **Side effects:** Writes `myday_backup_<yyyyMMdd_HHmmss>.zip`.
- **Notes:** Bundles the registry's five data files in registry order plus flat `images/<basename>`
  entries. Config, `.sync_base/`, and `backups/` are never included. Settings import/export supports
  ZIP only.

### `importZIP(filePath)` <a id="importzip"></a>
- **Returns:** `Future<bool>` — true when the ZIP was validated and imported.
- **Side effects:** Replaces allowlisted data files and images atomically.
- **Notes:** Only allowlisted entries are extracted, every entry must resolve inside the app dir, and
  the whole archive is classified and validated before anything is written — so a rejected archive
  leaves app data untouched rather than half-imported. The validator is each module's own parser,
  taken from the registry, which is the behavior `DataFileSafety.writeValidatedDataJson` used to
  provide inline.

## Where the engine documentation lives

`packages/myapps_data/doc/en-us/functions/src/data/zip_transfer.md`.

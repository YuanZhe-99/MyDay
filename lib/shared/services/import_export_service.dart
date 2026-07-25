/// Purpose: MyDay's ZIP export/import API, now a facade over the shared
/// `ZipTransfer` engine from the `myapps_data` package.
/// Inputs: Destination directories and ZIP file paths from the settings pages.
/// Returns: Written file paths, or import success flags.
/// Side effects: Reads and writes the app data directory.
/// Notes: `exportZIP`/`importZIP` keep their names, signatures,
/// and archive naming (`myday_backup_<stamp>.zip`) (I7). MyDay has no Markdown
/// export. MyDay was already the strictest of the three apps on import, and the
/// shared engine's defaults are exactly its behavior: reject unknown entries,
/// strict UTF-8 decoding, validate every payload before writing any, and write
/// atomically. The engine's fixed traversal rejection is also MyDay's existing
/// rule — the other two apps moved to it.
library;

import 'package:myapps_data/myapps_data.dart' as shared;

import '../../app/data_modules.dart';

class ImportExportService {
  /// Shared ZIP engine configured with MyDay's strict semantics.
  ///
  /// The validator is each module's own parser, taken from the registry, so an
  /// archive carrying a payload that a model cannot parse is refused before a
  /// single file is replaced — the behavior `DataFileSafety` used to provide.
  static final shared.ZipTransfer _zip = shared.ZipTransfer(
    storage: const TodoStorageAdapter(),
    modules: todoModuleRegistry,
    archiveNamePrefix: todoArchiveNamePrefix,
  );

  /// Purpose: Export all app data as a ZIP file.
  /// Inputs: `destDir`.
  /// Returns: Exported file path, or null on failure.
  /// Side effects: Reads app data files/images and writes a ZIP file.
  /// Notes: Bundles the registry's data files in registry order plus flat
  /// `images/<name>` entries. Config, `.sync_base/`, and `backups/` are never
  /// included. Settings import/export supports ZIP only.
  static Future<String?> exportZIP(String destDir) => _zip.exportZip(destDir);

  /// Purpose: Import app data from a ZIP file.
  /// Inputs: `filePath`.
  /// Returns: `true` when the ZIP was validated and imported.
  /// Side effects: Replaces allowlisted app data files and images.
  /// Notes: Rejects path traversal and validates data JSON before writing
  /// anything, so a rejected archive leaves app data untouched rather than
  /// half-imported.
  static Future<bool> importZIP(String filePath) => _zip.importZip(filePath);
}

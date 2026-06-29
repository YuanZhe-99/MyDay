import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../features/todo/services/todo_storage.dart';
import 'data_file_safety.dart';

class ImportExportService {
  static const _dataFileNames = [
    'todo_data.json',
    'finance_data.json',
    'exchange_rates.json',
    'intimacy_data.json',
    'weight_data.json',
  ];

  /// Purpose: Export all app data as a ZIP file.
  /// Inputs: `destDir`.
  /// Returns: Exported file path, or null on failure.
  /// Side effects: Reads app data files/images and writes a ZIP file.
  /// Notes: Settings import/export supports ZIP only.
  static Future<String?> exportZIP(String destDir) async {
    try {
      final appDir = await TodoStorage.getAppDir();
      final archive = Archive();

      for (final name in _dataFileNames) {
        final file = File(p.join(appDir.path, name));
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(name, bytes.length, bytes));
        }
      }

      final imgDir = Directory(p.join(appDir.path, 'images'));
      if (await imgDir.exists()) {
        await for (final entity in imgDir.list()) {
          if (entity is File) {
            final bytes = await entity.readAsBytes();
            final name = 'images/${p.basename(entity.path)}';
            archive.addFile(ArchiveFile(name, bytes.length, bytes));
          }
        }
      }

      final zipData = ZipEncoder().encode(archive);
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final outFile = File(p.join(destDir, 'myday_backup_$stamp.zip'));
      await outFile.writeAsBytes(zipData, flush: true);
      return outFile.path;
    } catch (_) {
      return null;
    }
  }

  /// Purpose: Import app data from a ZIP file.
  /// Inputs: `filePath`.
  /// Returns: `true` when the ZIP was validated and imported.
  /// Side effects: Replaces allowlisted app data files and images.
  /// Notes: Rejects path traversal and validates data JSON before writing anything.
  static Future<bool> importZIP(String filePath) async {
    try {
      final zipFile = File(filePath);
      if (!await zipFile.exists()) return false;

      final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
      final appDir = await TodoStorage.getAppDir();
      final appRoot = p.normalize(appDir.absolute.path);
      final dataWrites = <String, String>{};
      final imageWrites = <String, List<int>>{};

      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        final normalized = p.url.normalize(entry.name).replaceAll('\\', '/');
        if (normalized.startsWith('../') || normalized.contains('/../')) {
          return false;
        }

        if (_dataFileNames.contains(normalized)) {
          final content = String.fromCharCodes(entry.content as List<int>);
          DataFileSafety.validateDataJson(normalized, content);
          dataWrites[normalized] = content;
          continue;
        }

        if (normalized.startsWith('images/')) {
          final basename = p.basename(normalized);
          if (basename.isEmpty || normalized != 'images/$basename') {
            return false;
          }
          imageWrites[basename] = List<int>.from(entry.content as List<int>);
          continue;
        }

        return false;
      }

      for (final item in dataWrites.entries) {
        final target = File(p.join(appDir.path, item.key));
        if (!_isInside(appRoot, target.absolute.path)) return false;
        await DataFileSafety.writeValidatedDataJson(target, item.value);
      }

      for (final item in imageWrites.entries) {
        final target = File(p.join(appDir.path, 'images', item.key));
        if (!_isInside(appRoot, target.absolute.path)) return false;
        await DataFileSafety.atomicWriteBytes(target, item.value);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Purpose: Return whether [childPath] stays inside [rootPath].
  /// Inputs: `rootPath`, `childPath`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Protects ZIP import from path traversal writes.
  static bool _isInside(String rootPath, String childPath) {
    final root = p.normalize(rootPath);
    final child = p.normalize(childPath);
    return child == root || child.startsWith('$root${p.separator}');
  }
}

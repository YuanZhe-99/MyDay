import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/todo/services/todo_storage.dart';

/// Manages local backups with manual/auto creation and retention policies.
class BackupService {
  static const _backupDir = 'backups';

  /// Config keys stored in storage_config.json
  static bool autoBackupEnabled = false;
  static int retentionDays = 0; // 0 = keep forever

  static DateTime? _lastAutoBackup;

  /// Data module identifiers used for per-module restore.
  static const modules = <String, String>{
    'todo_data.json': 'todo',
    'finance_data.json': 'finance',
    'exchange_rates.json': 'exchangeRates',
    'intimacy_data.json': 'intimacy',
    'weight_data.json': 'weight',
  };

  static Future<Directory> _getBackupDir() async {
    final appDir = await TodoStorage.getAppDir();
    final dir = Directory(p.join(appDir.path, _backupDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Load backup settings from config.
  static Future<void> loadSettings() async {
    final config = await _readConfig();
    autoBackupEnabled = config['autoBackupEnabled'] as bool? ?? false;
    retentionDays = config['backupRetentionDays'] as int? ?? 0;
  }

  /// Save backup settings to config.
  static Future<void> saveSettings() async {
    await _updateConfig({
      'autoBackupEnabled': autoBackupEnabled,
      'backupRetentionDays': retentionDays,
    });
  }

  /// Create a backup now. Returns the backup file, or null on failure.
  static Future<File?> createBackup() async {
    try {
      final appDir = await TodoStorage.getAppDir();
      final backupDir = await _getBackupDir();
      final bundle = <String, dynamic>{};

      for (final name in modules.keys) {
        final file = File(p.join(appDir.path, name));
        if (await file.exists()) {
          bundle[name] = await file.readAsString();
        }
      }

      // Include images
      final imgDir = Directory(p.join(appDir.path, 'images'));
      if (await imgDir.exists()) {
        final images = <String, String>{};
        await for (final entity in imgDir.list()) {
          if (entity is File) {
            final bytes = await entity.readAsBytes();
            images['images/${p.basename(entity.path)}'] = base64Encode(bytes);
          }
        }
        if (images.isNotEmpty) bundle['_images'] = images;
      }

      final content = jsonEncode(bundle);

      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File(p.join(backupDir.path, 'backup_$stamp.json'));
      await file.writeAsString(content);

      // Clean old backups
      await _cleanOldBackups();

      return file;
    } catch (_) {
      return null;
    }
  }

  /// Run auto-backup if enabled and not yet done today.
  static Future<void> runAutoBackupIfNeeded() async {
    await loadSettings();
    if (!autoBackupEnabled) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastAutoBackup != null) {
      final lastDay = DateTime(
        _lastAutoBackup!.year,
        _lastAutoBackup!.month,
        _lastAutoBackup!.day,
      );
      if (!lastDay.isBefore(today)) return; // Already backed up today
    }

    // Check if there's already a backup from today
    final existing = await listBackups();
    final alreadyToday = existing.any((b) {
      final d = b.date;
      return d.year == today.year && d.month == today.month && d.day == today.day;
    });
    if (alreadyToday) {
      _lastAutoBackup = now;
      return;
    }

    await createBackup();
    _lastAutoBackup = now;
  }

  /// List all backups sorted by date descending (newest first).
  static Future<List<BackupInfo>> listBackups() async {
    final backupDir = await _getBackupDir();
    if (!await backupDir.exists()) return [];

    final files = <BackupInfo>[];
    await for (final entity in backupDir.list()) {
      if (entity is File && p.basename(entity.path).startsWith('backup_') &&
          entity.path.endsWith('.json')) {
        final stat = await entity.stat();
        final name = p.basenameWithoutExtension(entity.path);
        // Parse date from filename: backup_yyyyMMdd_HHmmss
        DateTime? date;
        try {
          final parts = name.replaceFirst('backup_', '');
          date = DateFormat('yyyyMMdd_HHmmss').parse(parts);
        } catch (_) {
          date = stat.modified;
        }
        files.add(BackupInfo(
          file: entity,
          date: date,
          sizeBytes: stat.size,
        ));
      }
    }
    files.sort((a, b) => b.date.compareTo(a.date));
    return files;
  }

  /// Read a backup's content and return module names it contains.
  static Future<List<String>> getBackupModules(File file) async {
    try {
      final raw = await file.readAsString();
      final bundle = jsonDecode(raw) as Map<String, dynamic>;
      return modules.entries
          .where((e) => bundle.containsKey(e.key))
          .map((e) => e.value)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Restore from a backup file, optionally only specific modules.
  /// [moduleKeys] is a set of module identifiers (e.g. 'todo', 'finance').
  /// If null, all modules are restored.
  static Future<bool> restoreBackup(
    File file, {
    Set<String>? moduleKeys,
  }) async {
    try {
      final raw = await file.readAsString();
      final bundle = jsonDecode(raw) as Map<String, dynamic>;
      final appDir = await TodoStorage.getAppDir();

      for (final entry in modules.entries) {
        final fileName = entry.key;
        final moduleId = entry.value;
        if (moduleKeys != null && !moduleKeys.contains(moduleId)) continue;
        if (!bundle.containsKey(fileName)) continue;
        final outFile = File(p.join(appDir.path, fileName));
        await outFile.writeAsString(bundle[fileName] as String);
      }

      // Restore images (always, if present and any module is selected)
      if (bundle.containsKey('_images')) {
        final imagesMap = bundle['_images'] as Map<String, dynamic>;
        final imgDir = Directory(p.join(appDir.path, 'images'));
        if (!await imgDir.exists()) {
          await imgDir.create(recursive: true);
        }
        for (final e in imagesMap.entries) {
          final f = File(p.join(appDir.path, e.key));
          await f.writeAsBytes(base64Decode(e.value as String));
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete a specific backup.
  static Future<void> deleteBackup(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Remove backups older than retention policy.
  static Future<void> _cleanOldBackups() async {
    if (retentionDays <= 0) return; // Keep forever
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final backups = await listBackups();
    for (final b in backups) {
      if (b.date.isBefore(cutoff)) {
        await b.file.delete();
      }
    }
  }

  /// Read the storage config file.
  static Future<Map<String, dynamic>> _readConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'MyDay', 'storage_config.json'));
      if (await file.exists()) {
        return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  /// Merge new values into the storage config file.
  static Future<void> _updateConfig(Map<String, dynamic> updates) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'MyDay', 'storage_config.json'));
      Map<String, dynamic> config = {};
      if (await file.exists()) {
        config = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
      config.addAll(updates);
      await file.writeAsString(jsonEncode(config));
    } catch (_) {}
  }
}

class BackupInfo {
  final File file;
  final DateTime date;
  final int sizeBytes;

  const BackupInfo({
    required this.file,
    required this.date,
    required this.sizeBytes,
  });

  String get displaySize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/task.dart';

class TodoData {
  final List<Task> dailyTemplates;
  final List<Task> oneTimeTasks;
  final DailyCompletionLog dailyLog;
  /// Morning reminder — nudge to plan today's list
  final int? morningReminderHour;
  final int? morningReminderMinute;
  /// Completion reminder — alert if tasks remain undone
  final int? completionReminderHour;
  final int? completionReminderMinute;
  final DateTime settingsModifiedAt;

  TodoData({
    required this.dailyTemplates,
    required this.oneTimeTasks,
    required this.dailyLog,
    this.morningReminderHour,
    this.morningReminderMinute,
    this.completionReminderHour,
    this.completionReminderMinute,
    DateTime? settingsModifiedAt,
  }) : settingsModifiedAt = settingsModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  Map<String, dynamic> toJson() => {
        'dailyTemplates': dailyTemplates.map((t) => t.toJson()).toList(),
        'oneTimeTasks': oneTimeTasks.map((t) => t.toJson()).toList(),
        'dailyLog': dailyLog.toJson(),
        if (morningReminderHour != null)
          'morningReminderHour': morningReminderHour,
        if (morningReminderMinute != null)
          'morningReminderMinute': morningReminderMinute,
        if (completionReminderHour != null)
          'completionReminderHour': completionReminderHour,
        if (completionReminderMinute != null)
          'completionReminderMinute': completionReminderMinute,
        'settingsModifiedAt': settingsModifiedAt.toIso8601String(),
      };

  factory TodoData.fromJson(Map<String, dynamic> json) {
    // Migrate old single-reminder format
    final oldH = json['dailyReminderHour'] as int?;
    final oldM = json['dailyReminderMinute'] as int?;
    return TodoData(
      dailyTemplates: (json['dailyTemplates'] as List<dynamic>)
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList(),
      oneTimeTasks: (json['oneTimeTasks'] as List<dynamic>)
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList(),
      dailyLog: json['dailyLog'] != null
          ? DailyCompletionLog.fromJson(
              json['dailyLog'] as Map<String, dynamic>)
          : DailyCompletionLog(),
      morningReminderHour:
          json['morningReminderHour'] as int? ?? oldH,
      morningReminderMinute:
          json['morningReminderMinute'] as int? ?? oldM,
      completionReminderHour:
          json['completionReminderHour'] as int?,
      completionReminderMinute:
          json['completionReminderMinute'] as int?,
      settingsModifiedAt: json['settingsModifiedAt'] != null
          ? DateTime.parse(json['settingsModifiedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class TodoStorage {
  static const _fileName = 'todo_data.json';
  static const _configFileName = 'storage_config.json';

  /// Custom storage directory path override.
  static String? _customPath;
  /// Whether config has been loaded.
  static bool _configLoaded = false;
  /// Cached intimacy visible state.
  static bool _intimacyVisible = false;
  /// Cached theme mode string.
  static String? _themeMode;
  /// Cached locale tag string.
  static String? _localeTag;
  /// Cached tray settings.
  static bool _minimizeToTray = false;
  static bool _closeToTray = false;

  static Future<Directory> _getDefaultAppDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/MyDay');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  /// Config file always lives in default location.
  static Future<File> _getConfigFile() async {
    final dir = await _getDefaultAppDir();
    return File('${dir.path}/$_configFileName');
  }

  /// Load the config from config file.
  static Future<void> _loadConfig() async {
    if (_configLoaded) return;
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _customPath = json['storagePath'] as String?;
        _intimacyVisible = (json['intimacyVisible'] as bool? ?? false) ||
            (json['intimacyEverUnlocked'] as bool? ?? false);
        _themeMode = json['themeMode'] as String?;
        _localeTag = json['localeTag'] as String?;
        _minimizeToTray = json['minimizeToTray'] as bool? ?? false;
        _closeToTray = json['closeToTray'] as bool? ?? false;
      }
    } catch (_) {
      // ignore
    }
    _configLoaded = true;
  }

  /// Save config to config file.
  /// Uses read-merge-write to preserve keys written by other modules
  /// (e.g. BackupService's autoBackupEnabled / backupRetentionDays).
  static Future<void> _saveConfig() async {
    final file = await _getConfigFile();
    Map<String, dynamic> json = {};
    try {
      if (await file.exists()) {
        json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {}
    if (_customPath != null) {
      json['storagePath'] = _customPath;
    } else {
      json.remove('storagePath');
    }
    if (_intimacyVisible) {
      json['intimacyVisible'] = true;
    } else {
      json.remove('intimacyVisible');
    }
    json.remove('intimacyEverUnlocked');
    if (_themeMode != null) {
      json['themeMode'] = _themeMode;
    } else {
      json.remove('themeMode');
    }
    if (_localeTag != null) {
      json['localeTag'] = _localeTag;
    } else {
      json.remove('localeTag');
    }
    if (_minimizeToTray) {
      json['minimizeToTray'] = true;
    } else {
      json.remove('minimizeToTray');
    }
    if (_closeToTray) {
      json['closeToTray'] = true;
    } else {
      json.remove('closeToTray');
    }
    await file.writeAsString(jsonEncode(json));
  }

  /// Get persisted intimacy visible state.
  static Future<bool> getIntimacyVisible() async {
    await _loadConfig();
    return _intimacyVisible;
  }

  /// Set and persist intimacy visible state.
  static Future<void> setIntimacyVisible(bool value) async {
    await _loadConfig();
    if (_intimacyVisible == value) return;
    _intimacyVisible = value;
    await _saveConfig();
  }

  /// Get persisted theme mode.
  static Future<String?> getThemeMode() async {
    await _loadConfig();
    return _themeMode;
  }

  /// Set and persist theme mode.
  static Future<void> setThemeMode(String? mode) async {
    await _loadConfig();
    _themeMode = mode;
    await _saveConfig();
  }

  /// Get persisted locale tag.
  static Future<String?> getLocaleTag() async {
    await _loadConfig();
    return _localeTag;
  }

  /// Set and persist locale tag (e.g. 'en', 'zh', 'zh_TW', 'ja', or null for system).
  static Future<void> setLocaleTag(String? tag) async {
    await _loadConfig();
    _localeTag = tag;
    await _saveConfig();
  }

  static Future<Directory> getAppDir() async {
    await _loadConfig();
    if (_customPath != null && _customPath!.isNotEmpty) {
      final dir = Directory(_customPath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    return _getDefaultAppDir();
  }

  static Future<File> _getFile() async {
    final appDir = await getAppDir();
    return File('${appDir.path}/$_fileName');
  }

  /// Check if the file exists at all.
  static Future<bool> fileExists() async {
    final file = await _getFile();
    return file.exists();
  }

  /// Load data. Returns null if file does not exist or on error.
  static Future<TodoData?> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TodoData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Save data.
  static Future<void> save(TodoData data) async {
    final file = await _getFile();
    final jsonStr = jsonEncode(data.toJson());
    await file.writeAsString(jsonStr);
  }

  /// Get the storage directory path for display.
  static Future<String> getStoragePath() async {
    final appDir = await getAppDir();
    return appDir.path;
  }

  /// Known data file names managed by the app.
  static const _dataFileNames = [
    _fileName,
    'finance_data.json',
    'exchange_rates.json',
    'intimacy_data.json',
    'weight_data.json',
    'webdav_config.json',
  ];

  /// Set a custom storage directory path.
  /// Pass null to reset to default.
  /// If the new path already has data files, uses those;
  /// otherwise moves existing data files to the new location.
  static Future<bool> setStoragePath(String? newPath) async {
    try {
      final oldDir = await getAppDir();

      _customPath = newPath;
      await _saveConfig();

      final newDir = await getAppDir();
      if (oldDir.path == newDir.path) return true;

      for (final name in _dataFileNames) {
        final oldFile = File('${oldDir.path}/$name');
        final newFile = File('${newDir.path}/$name');
        if (await newFile.exists()) {
          // New location already has this file — use it as-is
          continue;
        }
        if (await oldFile.exists()) {
          await oldFile.copy(newFile.path);
          await oldFile.delete();
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Tray settings ─────────────────────────────────────────────

  static Future<bool> getMinimizeToTray() async {
    await _loadConfig();
    return _minimizeToTray;
  }

  static Future<void> setMinimizeToTray(bool value) async {
    await _loadConfig();
    _minimizeToTray = value;
    await _saveConfig();
  }

  static Future<bool> getCloseToTray() async {
    await _loadConfig();
    return _closeToTray;
  }

  static Future<void> setCloseToTray(bool value) async {
    await _loadConfig();
    _closeToTray = value;
    await _saveConfig();
  }
}

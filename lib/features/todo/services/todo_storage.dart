import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../shared/services/data_file_safety.dart';
import '../../../shared/utils/json_preservation.dart';
import '../models/task.dart';

class TodoData {
  final List<Task> dailyTemplates;
  final List<Task> oneTimeTasks;
  final DailyCompletionLog dailyLog;
  final DailyScoreLog dailyScores;

  /// Morning reminder — nudge to plan today's list
  final int? morningReminderHour;
  final int? morningReminderMinute;

  /// Completion reminder — alert if tasks remain undone
  final int? completionReminderHour;
  final int? completionReminderMinute;
  final Map<String, String> taskSortModes;
  final Map<String, List<String>> taskCustomOrders;
  final DateTime settingsModifiedAt;

  /// Purpose: Create a todo data instance.
  /// Inputs: task lists, `dailyLog`, `dailyScores`, reminders, and sort settings.
  /// Returns: A new `TodoData` instance.
  /// Side effects: None.
  /// Notes: None.
  TodoData({
    required this.dailyTemplates,
    required this.oneTimeTasks,
    required this.dailyLog,
    DailyScoreLog? dailyScores,
    this.morningReminderHour,
    this.morningReminderMinute,
    this.completionReminderHour,
    this.completionReminderMinute,
    this.taskSortModes = const {},
    this.taskCustomOrders = const {},
    DateTime? settingsModifiedAt,
  }) : dailyScores = dailyScores ?? DailyScoreLog(),
       settingsModifiedAt =
           settingsModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'dailyTemplates': dailyTemplates.map((t) => t.toJson()).toList(),
    'oneTimeTasks': oneTimeTasks.map((t) => t.toJson()).toList(),
    'dailyLog': dailyLog.toJson(),
    if (!dailyScores.isEmpty) 'dailyScores': dailyScores.toJson(),
    if (morningReminderHour != null) 'morningReminderHour': morningReminderHour,
    if (morningReminderMinute != null)
      'morningReminderMinute': morningReminderMinute,
    if (completionReminderHour != null)
      'completionReminderHour': completionReminderHour,
    if (completionReminderMinute != null)
      'completionReminderMinute': completionReminderMinute,
    if (taskSortModes.isNotEmpty) 'taskSortModes': taskSortModes,
    if (taskCustomOrders.isNotEmpty) 'taskCustomOrders': taskCustomOrders,
    'settingsModifiedAt': settingsModifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `TodoData.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
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
              json['dailyLog'] as Map<String, dynamic>,
            )
          : DailyCompletionLog(),
      dailyScores: json['dailyScores'] != null
          ? DailyScoreLog.fromJson(json['dailyScores'] as Map<String, dynamic>)
          : DailyScoreLog(),
      morningReminderHour: json['morningReminderHour'] as int? ?? oldH,
      morningReminderMinute: json['morningReminderMinute'] as int? ?? oldM,
      completionReminderHour: json['completionReminderHour'] as int?,
      completionReminderMinute: json['completionReminderMinute'] as int?,
      taskSortModes:
          (json['taskSortModes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
          ) ??
          const {},
      taskCustomOrders:
          (json['taskCustomOrders'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List<dynamic>).map((e) => e as String).toList(),
            ),
          ) ??
          const {},
      settingsModifiedAt: json['settingsModifiedAt'] != null
          ? DateTime.parse(json['settingsModifiedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class TodoStorageException implements Exception {
  final String message;

  /// Purpose: Create a todo storage exception with a user-visible message.
  /// Inputs: `message`.
  /// Returns: A new `TodoStorageException` instance.
  /// Side effects: None.
  /// Notes: Thrown when todo data exists but cannot be safely read or written.
  const TodoStorageException(this.message);

  /// Purpose: Return a readable exception message.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Used by UI and sync/import error reporting.
  @override
  String toString() => message;
}

class TodoStorage {
  static const _fileName = 'todo_data.json';
  static const _configFileName = 'storage_config.json';
  static Future<void> _writeQueue = Future<void>.value();

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

  /// Cached week start day using Dart weekday numbering.
  static int _weekStartDay = DateTime.monday;

  /// Cached tray settings.
  static bool _minimizeToTray = false;
  static bool _closeToTray = false;

  /// Purpose: Provide the internal get default app dir helper for this file.
  /// Inputs: None.
  /// Returns: `Future<Directory>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<Directory> _getDefaultAppDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/MyDay');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  /// Config file always lives in default location.
  /// Purpose: Provide the internal get config file helper for this file.
  /// Inputs: None.
  /// Returns: `Future<File>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<File> _getConfigFile() async {
    final dir = await _getDefaultAppDir();
    return File('${dir.path}/$_configFileName');
  }

  /// Public access to the config file for other services (e.g. LocalApiServer).
  /// Purpose: Implement the get config file behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<File>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<File> getConfigFile() => _getConfigFile();

  /// Read the raw config JSON (for modules that store their own keys).
  /// Purpose: Implement the read config behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<Map<String, dynamic>>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<Map<String, dynamic>> readConfig() async {
    final file = await _getConfigFile();
    try {
      if (await file.exists()) {
        return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  /// Write config JSON (merge-write to preserve other modules' keys).
  /// Purpose: Implement the write config behavior for this file.
  /// Inputs: `config`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<void> writeConfig(Map<String, dynamic> config) async {
    final file = await _getConfigFile();
    Map<String, dynamic> existing = {};
    try {
      if (await file.exists()) {
        existing =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {}
    existing.addAll(config);
    // Remove null-valued keys
    existing.removeWhere((_, v) => v == null);
    await file.writeAsString(jsonEncode(existing));
    // Invalidate cached config so next _loadConfig() re-reads
    _configLoaded = false;
  }

  /// Load the config from config file.
  /// Purpose: Provide the internal load config helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<void> _loadConfig() async {
    if (_configLoaded) return;
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _customPath = json['storagePath'] as String?;
        _intimacyVisible =
            (json['intimacyVisible'] as bool? ?? false) ||
            (json['intimacyEverUnlocked'] as bool? ?? false);
        _themeMode = json['themeMode'] as String?;
        _localeTag = json['localeTag'] as String?;
        _weekStartDay = _normalizeWeekStartDay(json['weekStartDay'] as int?);
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
  /// Purpose: Provide the internal save config helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
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
    if (_weekStartDay != DateTime.monday) {
      json['weekStartDay'] = _weekStartDay;
    } else {
      json.remove('weekStartDay');
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
  /// Purpose: Implement the get intimacy visible behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<bool> getIntimacyVisible() async {
    await _loadConfig();
    return _intimacyVisible;
  }

  /// Set and persist intimacy visible state.
  /// Purpose: Implement the set intimacy visible behavior for this file.
  /// Inputs: `value`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<void> setIntimacyVisible(bool value) async {
    await _loadConfig();
    if (_intimacyVisible == value) return;
    _intimacyVisible = value;
    await _saveConfig();
  }

  /// Get persisted theme mode.
  /// Purpose: Implement the get theme mode behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<String?>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<String?> getThemeMode() async {
    await _loadConfig();
    return _themeMode;
  }

  /// Set and persist theme mode.
  /// Purpose: Implement the set theme mode behavior for this file.
  /// Inputs: `mode`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<void> setThemeMode(String? mode) async {
    await _loadConfig();
    _themeMode = mode;
    await _saveConfig();
  }

  /// Get persisted locale tag.
  /// Purpose: Implement the get locale tag behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<String?>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<String?> getLocaleTag() async {
    await _loadConfig();
    return _localeTag;
  }

  /// Set and persist locale tag (e.g. 'en', 'zh', 'zh_TW', 'ja', or null for system).
  /// Purpose: Implement the set locale tag behavior for this file.
  /// Inputs: `tag`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<void> setLocaleTag(String? tag) async {
    await _loadConfig();
    _localeTag = tag;
    await _saveConfig();
  }

  /// Get persisted week start day.
  /// Purpose: Return the global calendar week start day.
  /// Inputs: None.
  /// Returns: `Future<int>`.
  /// Side effects: May load the storage config cache.
  /// Notes: Values use Dart's Monday=1 through Sunday=7 numbering.
  static Future<int> getWeekStartDay() async {
    await _loadConfig();
    return _weekStartDay;
  }

  /// Set and persist week start day.
  /// Purpose: Update the global calendar week start day.
  /// Inputs: `weekday`.
  /// Returns: `Future<void>`.
  /// Side effects: Writes `storage_config.json` when the value changes.
  /// Notes: Invalid values are normalized back to Monday.
  static Future<void> setWeekStartDay(int weekday) async {
    await _loadConfig();
    final normalized = _normalizeWeekStartDay(weekday);
    if (_weekStartDay == normalized) return;
    _weekStartDay = normalized;
    await _saveConfig();
  }

  /// Purpose: Implement the get app dir behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<Directory>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
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

  /// Purpose: Provide the internal get file helper for this file.
  /// Inputs: None.
  /// Returns: `Future<File>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<File> _getFile() async {
    final appDir = await getAppDir();
    return File('${appDir.path}/$_fileName');
  }

  /// Check if the file exists at all.
  /// Purpose: Implement the file exists behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<bool> fileExists() async {
    final file = await _getFile();
    return file.exists();
  }

  /// Load data. Returns null only when the file does not exist.
  /// Purpose: Implement the load behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<TodoData?>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: An unreadable existing file throws so callers never treat
  /// corrupted todo data as an empty dataset.
  static Future<TodoData?> load() async {
    final file = await _getFile();
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TodoData.fromJson(json);
    } on FormatException catch (e) {
      throw TodoStorageException('$_fileName is not valid JSON: $e');
    } catch (e) {
      throw TodoStorageException('Failed to load $_fileName: $e');
    }
  }

  /// Save data.
  /// Purpose: Implement the save behavior for this file.
  /// Inputs: `data`.
  /// Returns: `Future<void>`.
  /// Side effects: Serializes todo writes, validates generated JSON, and atomically replaces the data file.
  /// Notes: Prevents overlapping writers from interleaving and corrupting JSON.
  static Future<void> save(TodoData data) async {
    final next = _writeQueue.then(
      (_) => _saveNow(data),
      onError: (_) => _saveNow(data),
    );
    _writeQueue = next.catchError((_) {});
    return next;
  }

  /// Purpose: Persist todo data after the caller has entered the write queue.
  /// Inputs: `data`.
  /// Returns: `Future<void>`.
  /// Side effects: Writes `todo_data.json` through a validated temporary file.
  /// Notes: Internal helper used within this file only.
  static Future<void> _saveNow(TodoData data) async {
    final file = await _getFile();
    final jsonStr = await JsonPreservation.encodeForFile(
      file: file,
      next: data.toJson(),
      schema: dataFilePreservationSchemas[_fileName]!,
    );
    await DataFileSafety.writeValidatedDataJson(file, jsonStr);
  }

  /// Get the storage directory path for display.
  /// Purpose: Implement the get storage path behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<String>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
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
  /// Purpose: Implement the set storage path behavior for this file.
  /// Inputs: `newPath`.
  /// Returns: `Future<bool>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
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

  /// Purpose: Implement the get minimize to tray behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<bool> getMinimizeToTray() async {
    await _loadConfig();
    return _minimizeToTray;
  }

  /// Purpose: Implement the set minimize to tray behavior for this file.
  /// Inputs: `value`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<void> setMinimizeToTray(bool value) async {
    await _loadConfig();
    _minimizeToTray = value;
    await _saveConfig();
  }

  /// Purpose: Implement the get close to tray behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<bool>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<bool> getCloseToTray() async {
    await _loadConfig();
    return _closeToTray;
  }

  /// Purpose: Implement the set close to tray behavior for this file.
  /// Inputs: `value`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<void> setCloseToTray(bool value) async {
    await _loadConfig();
    _closeToTray = value;
    await _saveConfig();
  }

  /// Purpose: Return a valid persisted week start day.
  /// Inputs: `weekday`.
  /// Returns: `int`.
  /// Side effects: None.
  /// Notes: Defaults invalid and missing config values to Monday.
  static int _normalizeWeekStartDay(int? weekday) {
    if (weekday == null ||
        weekday < DateTime.monday ||
        weekday > DateTime.sunday) {
      return DateTime.monday;
    }
    return weekday;
  }
}

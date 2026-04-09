import 'dart:convert';
import 'dart:io';

import '../../todo/services/todo_storage.dart';
import '../models/intimacy_record.dart';

class IntimacyStorage {
  static const _fileName = 'intimacy_data.json';
  static const _legacyTimerFileName = 'timer_history.json';

  static Future<File> _getFile() async {
    final appDir = await TodoStorage.getAppDir();
    return File('${appDir.path}/$_fileName');
  }

  static Future<IntimacyData?> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();

      final json = jsonDecode(raw) as Map<String, dynamic>;
      var data = IntimacyData.fromJson(json);

      // Migrate legacy timer_history.json into IntimacyData
      data = await _migrateLegacyTimerHistory(data);

      return data;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(IntimacyData data) async {
    final file = await _getFile();
    final jsonStr = jsonEncode(data.toJson());
    await file.writeAsString(jsonStr);
  }

  /// Migrate old timer_history.json entries into IntimacyData, then delete old file.
  static Future<IntimacyData> _migrateLegacyTimerHistory(
      IntimacyData data) async {
    try {
      final appDir = await TodoStorage.getAppDir();
      final legacyFile = File('${appDir.path}/$_legacyTimerFileName');
      if (!await legacyFile.exists()) return data;

      final raw = await legacyFile.readAsString();
      final list = jsonDecode(raw) as List;
      final legacyEntries = list
          .map((e) =>
              TimerHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      if (legacyEntries.isNotEmpty) {
        // Merge: keep existing + legacy, dedup by start time
        final existingStarts =
            data.timerHistory.map((e) => e.start.toIso8601String()).toSet();
        final newEntries = legacyEntries
            .where(
                (e) => !existingStarts.contains(e.start.toIso8601String()))
            .toList();
        if (newEntries.isNotEmpty) {
          data = IntimacyData(
            partners: data.partners,
            toys: data.toys,
            records: data.records,
            timerHistory: [...data.timerHistory, ...newEntries],
            timerHistoryRetentionDays: data.timerHistoryRetentionDays,
            settingsModifiedAt: data.settingsModifiedAt,
          );
          await save(data);
        }
      }

      await legacyFile.delete();
      return data;
    } catch (_) {
      return data;
    }
  }
}

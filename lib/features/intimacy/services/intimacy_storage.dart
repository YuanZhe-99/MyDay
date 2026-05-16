import 'dart:convert';
import 'dart:io';

import '../../../shared/utils/json_preservation.dart';
import '../../todo/services/todo_storage.dart';
import '../models/intimacy_record.dart';

class IntimacyStorage {
  static const _fileName = 'intimacy_data.json';
  static const _legacyTimerFileName = 'timer_history.json';

  /// Purpose: Provide the internal get file helper for this file.
  /// Inputs: None.
  /// Returns: `Future<File>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<File> _getFile() async {
    final appDir = await TodoStorage.getAppDir();
    return File('${appDir.path}/$_fileName');
  }

  /// Purpose: Implement the load behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<IntimacyData?>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
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

  /// Purpose: Implement the save behavior for this file.
  /// Inputs: `data`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<void> save(IntimacyData data) async {
    final file = await _getFile();
    final jsonStr = await JsonPreservation.encodeForFile(
      file: file,
      next: data.toJson(),
      schema: dataFilePreservationSchemas[_fileName]!,
    );
    await file.writeAsString(jsonStr);
  }

  /// Migrate old timer_history.json entries into IntimacyData, then delete old file.
  /// Purpose: Provide the internal migrate legacy timer history helper for this file.
  /// Inputs: `data`.
  /// Returns: `Future<IntimacyData>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<IntimacyData> _migrateLegacyTimerHistory(
    IntimacyData data,
  ) async {
    try {
      final appDir = await TodoStorage.getAppDir();
      final legacyFile = File('${appDir.path}/$_legacyTimerFileName');
      if (!await legacyFile.exists()) return data;

      final raw = await legacyFile.readAsString();
      final list = jsonDecode(raw) as List;
      final legacyEntries = list
          .map((e) => TimerHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      if (legacyEntries.isNotEmpty) {
        // Merge: keep existing + legacy, dedup by start time
        final existingStarts = data.timerHistory
            .map((e) => e.start.toIso8601String())
            .toSet();
        final newEntries = legacyEntries
            .where((e) => !existingStarts.contains(e.start.toIso8601String()))
            .toList();
        if (newEntries.isNotEmpty) {
          data = IntimacyData(
            partners: data.partners,
            toys: data.toys,
            positions: data.positions,
            records: data.records,
            timerHistory: [...data.timerHistory, ...newEntries],
            timerHistoryRetentionDays: data.timerHistoryRetentionDays,
            partnerSortModes: data.partnerSortModes,
            partnerCustomOrders: data.partnerCustomOrders,
            toySortModes: data.toySortModes,
            toyCustomOrders: data.toyCustomOrders,
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

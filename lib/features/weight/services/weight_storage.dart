import 'dart:convert';
import 'dart:io';

import '../../../shared/utils/json_preservation.dart';
import '../../todo/services/todo_storage.dart';
import '../models/weight_record.dart';

class WeightStorage {
  static const fileName = 'weight_data.json';

  /// Purpose: Provide the internal get file helper for this file.
  /// Inputs: None.
  /// Returns: `Future<File>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<File> _getFile() async {
    final appDir = await TodoStorage.getAppDir();
    return File('${appDir.path}/$fileName');
  }

  /// Purpose: Implement the load behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<WeightData?>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<WeightData?> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();

      final json = jsonDecode(raw) as Map<String, dynamic>;
      return WeightData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Purpose: Implement the save behavior for this file.
  /// Inputs: `data`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<void> save(WeightData data) async {
    final file = await _getFile();
    final jsonStr = await JsonPreservation.encodeForFile(
      file: file,
      next: data.toJson(),
      schema: dataFilePreservationSchemas[fileName]!,
    );
    await file.writeAsString(jsonStr);
  }
}

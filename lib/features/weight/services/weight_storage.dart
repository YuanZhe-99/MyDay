import 'dart:convert';
import 'dart:io';

import '../../../shared/utils/json_preservation.dart';
import '../../todo/services/todo_storage.dart';
import '../models/weight_record.dart';

class WeightStorage {
  static const fileName = 'weight_data.json';

  static Future<File> _getFile() async {
    final appDir = await TodoStorage.getAppDir();
    return File('${appDir.path}/$fileName');
  }

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

import 'dart:convert';
import 'dart:io';

import '../../todo/services/todo_storage.dart';
import '../models/intimacy_record.dart';

class IntimacyStorage {
  static const _fileName = 'intimacy_data.json';

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
      return IntimacyData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(IntimacyData data) async {
    final file = await _getFile();
    final jsonStr = jsonEncode(data.toJson());
    await file.writeAsString(jsonStr);
  }
}

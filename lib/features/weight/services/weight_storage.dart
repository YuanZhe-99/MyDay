import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../shared/services/data_file_safety.dart';
import '../../../shared/utils/json_preservation.dart';
import '../../todo/services/todo_storage.dart';
import '../models/weight_record.dart';

class WeightStorageException implements Exception {
  final String message;

  /// Purpose: Create a weight storage exception with a user-visible message.
  /// Inputs: `message`.
  /// Returns: A new `WeightStorageException` instance.
  /// Side effects: None.
  /// Notes: Thrown when weight data exists but cannot be safely read or written.
  const WeightStorageException(this.message);

  /// Purpose: Return a readable exception message.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Used by UI and sync/import error reporting.
  @override
  String toString() => message;
}

class WeightStorage {
  static const fileName = 'weight_data.json';
  static Future<void> _writeQueue = Future<void>.value();

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
  /// Notes: A missing file returns null, but an unreadable existing file throws
  /// so callers never treat corrupted weight data as an empty dataset.
  static Future<WeightData?> load() async {
    final file = await _getFile();
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();

      final json = jsonDecode(raw) as Map<String, dynamic>;
      return WeightData.fromJson(json);
    } on FormatException catch (e) {
      throw WeightStorageException('$fileName is not valid JSON: $e');
    } catch (e) {
      throw WeightStorageException('Failed to load $fileName: $e');
    }
  }

  /// Purpose: Implement the save behavior for this file.
  /// Inputs: `data`.
  /// Returns: `Future<void>`.
  /// Side effects: Serializes weight writes, validates generated JSON, and atomically replaces the data file.
  /// Notes: Prevents overlapping writers from interleaving and corrupting JSON.
  static Future<void> save(WeightData data) async {
    final next = _writeQueue.then(
      (_) => _saveNow(data),
      onError: (_) => _saveNow(data),
    );
    _writeQueue = next.catchError((_) {});
    return next;
  }

  /// Purpose: Persist weight data after the caller has entered the write queue.
  /// Inputs: `data`.
  /// Returns: `Future<void>`.
  /// Side effects: Writes `weight_data.json` through a validated temporary file.
  /// Notes: Internal helper used within this file only.
  static Future<void> _saveNow(WeightData data) async {
    final file = await _getFile();
    final jsonStr = await JsonPreservation.encodeForFile(
      file: file,
      next: data.toJson(),
      schema: dataFilePreservationSchemas[fileName]!,
    );
    await DataFileSafety.writeValidatedDataJson(file, jsonStr);
  }
}

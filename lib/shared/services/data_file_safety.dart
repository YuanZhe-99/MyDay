import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../features/finance/services/exchange_rate_storage.dart';
import '../../features/finance/services/finance_storage.dart';
import '../../features/intimacy/models/intimacy_record.dart';
import '../../features/todo/services/todo_storage.dart';
import '../../features/weight/models/weight_record.dart';

class DataFileValidationException implements Exception {
  final String fileName;
  final String message;

  /// Purpose: Create a data file validation exception.
  /// Inputs: `fileName`, `message`.
  /// Returns: A new `DataFileValidationException` instance.
  /// Side effects: None.
  /// Notes: Used to report import/restore failures without overwriting data.
  const DataFileValidationException(this.fileName, this.message);

  /// Purpose: Return a readable validation message.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Includes the file name so UI can point at the failing module.
  @override
  String toString() => '$fileName: $message';
}

class DataFileSafety {
  /// Purpose: Prevent direct instantiation of the data file safety utility.
  /// Inputs: None.
  /// Returns: A new `DataFileSafety` instance.
  /// Side effects: None.
  /// Notes: Use static helpers instead.
  const DataFileSafety._();

  static const dataFileNames = {
    'todo_data.json',
    'finance_data.json',
    'exchange_rates.json',
    'intimacy_data.json',
    'weight_data.json',
  };

  /// Purpose: Validate a known app data JSON string against its model parser.
  /// Inputs: `fileName`, `jsonContent`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: Throws before import/restore writes any invalid or incompatible data file.
  static void validateDataJson(String fileName, String jsonContent) {
    if (!dataFileNames.contains(fileName)) {
      throw DataFileValidationException(fileName, 'unsupported data file');
    }

    try {
      final json = jsonDecode(jsonContent) as Map<String, dynamic>;
      switch (fileName) {
        case 'todo_data.json':
          TodoData.fromJson(json);
        case 'finance_data.json':
          FinanceData.fromJson(json);
        case 'exchange_rates.json':
          ExchangeRateData.fromJson(json);
        case 'intimacy_data.json':
          IntimacyData.fromJson(json);
        case 'weight_data.json':
          WeightData.fromJson(json);
      }
    } catch (e) {
      if (e is DataFileValidationException) rethrow;
      throw DataFileValidationException(fileName, e.toString());
    }
  }

  /// Purpose: Validate and atomically write a known app data JSON file.
  /// Inputs: `file`, `jsonContent`.
  /// Returns: `Future<void>`.
  /// Side effects: Writes a temporary file and renames it over the destination.
  /// Notes: The destination file name decides which model parser is used.
  static Future<void> writeValidatedDataJson(
    File file,
    String jsonContent,
  ) async {
    validateDataJson(p.basename(file.path), jsonContent);
    await atomicWriteString(file, jsonContent);
  }

  /// Purpose: Atomically write text to a file through a same-directory temp file.
  /// Inputs: `file`, `content`.
  /// Returns: `Future<void>`.
  /// Side effects: Creates parent directories as needed and replaces the target.
  /// Notes: Used by import and restore paths to avoid partial writes.
  static Future<void> atomicWriteString(File file, String content) async {
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    final tmp = File(
      '${file.path}.tmp-${DateTime.now().microsecondsSinceEpoch}',
    );
    await tmp.writeAsString(content, flush: true);
    try {
      await tmp.rename(file.path);
    } catch (e) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      throw FileSystemException('Failed to replace file safely: $e', file.path);
    }
  }

  /// Purpose: Atomically write bytes to a file through a same-directory temp file.
  /// Inputs: `file`, `bytes`.
  /// Returns: `Future<void>`.
  /// Side effects: Creates parent directories as needed and replaces the target.
  /// Notes: Used for ZIP image restore after data JSON validation succeeds.
  static Future<void> atomicWriteBytes(File file, List<int> bytes) async {
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    final tmp = File(
      '${file.path}.tmp-${DateTime.now().microsecondsSinceEpoch}',
    );
    await tmp.writeAsBytes(bytes, flush: true);
    try {
      await tmp.rename(file.path);
    } catch (e) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      throw FileSystemException('Failed to replace file safely: $e', file.path);
    }
  }
}

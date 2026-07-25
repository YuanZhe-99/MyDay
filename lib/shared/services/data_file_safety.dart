/// Purpose: Validate-then-write helpers for MyDay's known data files.
/// Inputs: Data file paths and JSON payloads from import/restore paths.
/// Returns: Nothing; throws `DataFileValidationException` on invalid payloads.
/// Side effects: Atomically replaces files on disk.
/// Notes: This file was split in two by the shared-package extraction. The
/// generic atomic tmp-then-rename writers moved to the `myapps_data` package
/// and are re-exported here; the validation dispatch now reads the module
/// registry instead of a sixth hardcoded file list. Every public member kept
/// its name and signature (I7).
library;

import 'dart:io';

import 'package:myapps_data/myapps_data.dart' as shared;
import 'package:path/path.dart' as p;

import '../../app/data_modules.dart';

// The exception type moved to the package (feature-matrix K8) with the same
// shape — `fileName`, `message`, and the `'$fileName: $message'` toString — so
// existing catch sites and messages are unchanged (I8).
export 'package:myapps_data/myapps_data.dart' show DataFileValidationException;

class DataFileSafety {
  /// Purpose: Prevent direct instantiation of the data file safety utility.
  /// Inputs: None.
  /// Returns: A new `DataFileSafety` instance.
  /// Side effects: None.
  /// Notes: Use static helpers instead.
  const DataFileSafety._();

  /// Known app data file names.
  ///
  /// Derived from the module registry — this used to be one of five separate
  /// hardcoded copies of the same list.
  static final Set<String> dataFileNames = {
    for (final module in todoModuleRegistry.modules) module.fileName,
  };

  /// Purpose: Validate a known app data JSON string against its model parser.
  /// Inputs: `fileName`, `jsonContent`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: Throws before import/restore writes any invalid or incompatible
  /// data file. The parser comes from the registry entry for `fileName`.
  static void validateDataJson(String fileName, String jsonContent) {
    final module = todoModuleRegistry.byFileName[fileName];
    if (module == null) {
      throw shared.DataFileValidationException(
        fileName,
        'unsupported data file',
      );
    }

    try {
      module.validate(jsonContent);
    } catch (e) {
      if (e is shared.DataFileValidationException) rethrow;
      throw shared.DataFileValidationException(fileName, e.toString());
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
  static Future<void> atomicWriteString(File file, String content) =>
      shared.atomicWriteString(file, content);

  /// Purpose: Atomically write bytes to a file through a same-directory temp file.
  /// Inputs: `file`, `bytes`.
  /// Returns: `Future<void>`.
  /// Side effects: Creates parent directories as needed and replaces the target.
  /// Notes: Used for images restored from backups and ZIP imports.
  static Future<void> atomicWriteBytes(File file, List<int> bytes) =>
      shared.atomicWriteBytes(file, bytes);
}

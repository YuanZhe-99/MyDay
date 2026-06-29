import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:my_day/features/finance/services/finance_storage.dart';
import 'package:my_day/features/todo/services/todo_storage.dart';
import 'package:my_day/shared/services/data_file_safety.dart';

/// Purpose: Run data file safety regression tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: Path provider is faked so app storage stays inside the test sandbox.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('my_day_data_safety_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('corrupt finance data throws instead of loading empty data', () async {
    final appDir = await TodoStorage.getAppDir();
    final file = File(p.join(appDir.path, 'finance_data.json'));
    await file.writeAsString('{bad json');

    await expectLater(
      FinanceStorage.load(),
      throwsA(isA<FinanceStorageException>()),
    );
    expect(await file.readAsString(), '{bad json');
  });

  test(
    'validated write refuses invalid JSON and keeps existing data',
    () async {
      final appDir = await TodoStorage.getAppDir();
      final file = File(p.join(appDir.path, 'finance_data.json'));
      final valid = jsonEncode(
        FinanceData(accounts: [], categories: [], transactions: []).toJson(),
      );
      await DataFileSafety.writeValidatedDataJson(file, valid);

      await expectLater(
        DataFileSafety.writeValidatedDataJson(file, '{bad json'),
        throwsA(isA<DataFileValidationException>()),
      );
      expect(await file.readAsString(), valid);
    },
  );
}

class _FakePathProvider extends PathProviderPlatform {
  final String documentsPath;

  /// Purpose: Create a fake path provider for tests.
  /// Inputs: `documentsPath`.
  /// Returns: A new `_FakePathProvider` instance.
  /// Side effects: None.
  /// Notes: Only application documents path is needed by these tests.
  _FakePathProvider(this.documentsPath);

  /// Purpose: Return the fake application documents directory.
  /// Inputs: None.
  /// Returns: `Future<String?>`.
  /// Side effects: None.
  /// Notes: None.
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

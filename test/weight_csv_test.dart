import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:my_day/features/weight/services/weight_storage.dart';
import 'package:my_day/shared/services/import_export_service.dart';

/// Purpose: Run weight CSV import compatibility tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: Path provider is faked so app storage stays inside the test sandbox.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('my_day_weight_csv_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('imports old weight CSV without measurements', () async {
    final csv = File('${tempDir.path}/old_weight.csv');
    await csv.writeAsString(
      'Date, Time, Weight (kg)\n'
      '1/1/2025, 09:00, 65.50\n',
    );

    final result = await ImportExportService.importWeightCSV(csv.path);
    final data = await WeightStorage.load();

    expect(result, (true, 1));
    expect(data?.records.single.weight, 65.5);
    expect(data?.records.single.bustCm, isNull);
    expect(data?.records.single.waistCm, isNull);
    expect(data?.records.single.hipCm, isNull);
  });

  test('imports new weight CSV with optional measurements', () async {
    final csv = File('${tempDir.path}/new_weight.csv');
    await csv.writeAsString(
      'Date, Time, Weight (kg), Bust (cm), Waist (cm), Hip (cm)\n'
      '1/2/2025, 08:30, 65.30, 88.0, 69.5, 92.0\n'
      '1/3/2025, 08:30, 65.10, 0, , -1\n',
    );

    final result = await ImportExportService.importWeightCSV(csv.path);
    final data = await WeightStorage.load();
    final records = data!.records
      ..sort((a, b) => a.datetime.compareTo(b.datetime));

    expect(result, (true, 2));
    expect(records.first.bustCm, 88.0);
    expect(records.first.waistCm, 69.5);
    expect(records.first.hipCm, 92.0);
    expect(records.last.bustCm, isNull);
    expect(records.last.waistCm, isNull);
    expect(records.last.hipCm, isNull);
  });
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

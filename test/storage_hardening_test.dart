import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:my_day/features/finance/services/exchange_rate_storage.dart';
import 'package:my_day/features/finance/services/finance_storage.dart';
import 'package:my_day/features/intimacy/models/intimacy_record.dart';
import 'package:my_day/features/intimacy/services/intimacy_storage.dart';
import 'package:my_day/features/todo/models/task.dart';
import 'package:my_day/features/todo/services/todo_storage.dart';
import 'package:my_day/features/weight/models/weight_record.dart';
import 'package:my_day/features/weight/services/weight_storage.dart';
import 'package:my_day/shared/utils/adaptive_layout.dart';

/// Purpose: Run storage hardening regression tests for intimacy, weight, and todo data files.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: Path provider is faked so app storage stays inside the test sandbox.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'my_day_storage_hardening_test_',
    );
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// Purpose: Return a named data file inside the fake app directory.
  /// Inputs: `name`.
  /// Returns: `Future<File>`.
  /// Side effects: Creates the fake app directory when needed.
  /// Notes: None.
  Future<File> dataFile(String name) async {
    final appDir = await TodoStorage.getAppDir();
    return File(p.join(appDir.path, name));
  }

  /// Purpose: List temporary atomic-write files left in the fake app directory.
  /// Inputs: None.
  /// Returns: `Future<List<File>>`.
  /// Side effects: Reads the fake app directory.
  /// Notes: A successful save should always return an empty list.
  Future<List<File>> tmpLeftovers() async {
    final appDir = await TodoStorage.getAppDir();
    return appDir
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).contains('.tmp-'))
        .toList();
  }

  group('IntimacyStorage', () {
    const fileName = 'intimacy_data.json';

    /// Purpose: Create minimal valid intimacy data for save tests.
    /// Inputs: None.
    /// Returns: `IntimacyData`.
    /// Side effects: None.
    /// Notes: None.
    IntimacyData emptyData() =>
        IntimacyData(partners: [], toys: [], records: []);

    test('missing file loads null', () async {
      expect(await IntimacyStorage.load(), isNull);
    });

    test('corrupt file throws and keeps file bytes unchanged', () async {
      final file = await dataFile(fileName);
      await file.writeAsString('{"partners": [broken');

      await expectLater(
        IntimacyStorage.load(),
        throwsA(isA<IntimacyStorageException>()),
      );
      expect(await file.readAsString(), '{"partners": [broken');
    });

    test('save writes valid JSON and leaves no tmp files', () async {
      await IntimacyStorage.save(emptyData());

      final file = await dataFile(fileName);
      final decoded = jsonDecode(await file.readAsString());
      expect(decoded, isA<Map<String, dynamic>>());
      expect(await tmpLeftovers(), isEmpty);
    });

    test('concurrent saves leave a valid JSON file', () async {
      await Future.wait([
        for (var i = 0; i < 8; i++)
          IntimacyStorage.save(
            IntimacyData(
              partners: [Partner(id: 'p$i', name: 'Partner $i')],
              toys: [],
              records: [],
            ),
          ),
      ]);

      final file = await dataFile(fileName);
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final partners = decoded['partners'] as List<dynamic>;
      expect((partners.single as Map<String, dynamic>)['id'], 'p7');
      expect(await tmpLeftovers(), isEmpty);
    });
  });

  group('WeightStorage', () {
    const fileName = 'weight_data.json';

    test('missing file loads null', () async {
      expect(await WeightStorage.load(), isNull);
    });

    test('corrupt file throws and keeps file bytes unchanged', () async {
      final file = await dataFile(fileName);
      await file.writeAsString('{"records": [');

      await expectLater(
        WeightStorage.load(),
        throwsA(isA<WeightStorageException>()),
      );
      expect(await file.readAsString(), '{"records": [');
    });

    test('save writes valid JSON and leaves no tmp files', () async {
      await WeightStorage.save(WeightData(records: []));

      final file = await dataFile(fileName);
      final decoded = jsonDecode(await file.readAsString());
      expect(decoded, isA<Map<String, dynamic>>());
      expect(await tmpLeftovers(), isEmpty);
    });

    test('concurrent saves leave a valid JSON file', () async {
      await Future.wait([
        for (var i = 0; i < 8; i++)
          WeightStorage.save(
            WeightData(
              records: [WeightRecord(id: 'w$i', weight: 60 + i.toDouble())],
            ),
          ),
      ]);

      final file = await dataFile(fileName);
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final records = decoded['records'] as List<dynamic>;
      expect((records.single as Map<String, dynamic>)['id'], 'w7');
      expect(await tmpLeftovers(), isEmpty);
    });
  });

  group('TodoStorage', () {
    const fileName = 'todo_data.json';

    /// Purpose: Create minimal valid todo data for save tests.
    /// Inputs: None.
    /// Returns: `TodoData`.
    /// Side effects: None.
    /// Notes: None.
    TodoData emptyData() => TodoData(
      dailyTemplates: [],
      oneTimeTasks: [],
      dailyLog: DailyCompletionLog(),
    );

    test('missing file loads null', () async {
      expect(await TodoStorage.load(), isNull);
    });

    test('corrupt file throws and keeps file bytes unchanged', () async {
      final file = await dataFile(fileName);
      await file.writeAsString('{"dailyTemplates":');

      await expectLater(
        TodoStorage.load(),
        throwsA(isA<TodoStorageException>()),
      );
      expect(await file.readAsString(), '{"dailyTemplates":');
    });

    test('save writes valid JSON and leaves no tmp files', () async {
      await TodoStorage.save(emptyData());

      final file = await dataFile(fileName);
      final decoded = jsonDecode(await file.readAsString());
      expect(decoded, isA<Map<String, dynamic>>());
      expect(await tmpLeftovers(), isEmpty);
    });

    test('concurrent saves leave a valid JSON file', () async {
      await Future.wait([
        for (var i = 0; i < 8; i++)
          TodoStorage.save(
            TodoData(
              dailyTemplates: [],
              oneTimeTasks: [
                Task(id: 't$i', title: 'Task $i', type: TaskType.workOnce),
              ],
              dailyLog: DailyCompletionLog(),
            ),
          ),
      ]);

      final file = await dataFile(fileName);
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final tasks = decoded['oneTimeTasks'] as List<dynamic>;
      expect((tasks.single as Map<String, dynamic>)['id'], 't7');
      expect(await tmpLeftovers(), isEmpty);
    });
  });

  group('ExchangeRateStorage', () {
    test('concurrent saves leave a valid JSON file', () async {
      await Future.wait([
        for (var i = 0; i < 8; i++)
          ExchangeRateStorage.save(
            ExchangeRateData(
              currentSnapshotId: 'snapshot-$i',
              snapshots: {
                'snapshot-$i': RateSnapshot(
                  id: 'snapshot-$i',
                  rates: {'USD_CNY': 7 + i / 100},
                  createdAt: DateTime.utc(2026, 7, i + 1),
                ),
              },
            ),
          ),
      ]);

      final file = await dataFile('exchange_rates.json');
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final data = ExchangeRateData.fromJson(decoded);
      expect(data.currentSnapshotId, 'snapshot-7');
      expect(data.snapshots[data.currentSnapshotId], isNotNull);
      expect(await tmpLeftovers(), isEmpty);
    });

    test('corrupt file throws on load and save and keeps its bytes', () async {
      final file = await dataFile('exchange_rates.json');
      const corrupt = '{"currentSnapshotId": "a", "snapshots": {';
      await file.writeAsString(corrupt);

      await expectLater(
        ExchangeRateStorage.load(),
        throwsA(isA<ExchangeRateStorageException>()),
      );
      await expectLater(
        ExchangeRateStorage.save(
          ExchangeRateData(currentSnapshotId: '', snapshots: {}),
        ),
        throwsA(isA<ExchangeRateStorageException>()),
      );
      expect(await file.readAsString(), corrupt);
    });

    test('missing file yields defaults; a legacy flat map migrates', () async {
      final defaults = await ExchangeRateStorage.load();
      expect(defaults.currentRates, isNotEmpty);

      final file = await dataFile('exchange_rates.json');
      await file.writeAsString('{"USD_CNY": 7.1}');
      final migrated = await ExchangeRateStorage.load();
      expect(migrated.currentRates, {'USD_CNY': 7.1});
    });

    test(
      'finance loads without reading rates when nothing to migrate',
      () async {
        await FinanceStorage.save(
          FinanceData(accounts: [], categories: [], transactions: []),
        );
        final file = await dataFile('exchange_rates.json');
        await file.writeAsString('not json');

        final data = await FinanceStorage.load();
        expect(data, isNotNull);
        expect(await file.readAsString(), 'not json');
      },
    );
  });

  group('storage_config.json', () {
    test('concurrent single-key writes all survive', () async {
      await Future.wait([
        for (var i = 0; i < 12; i++) TodoStorage.writeConfig({'key$i': i}),
      ]);
      final config = await TodoStorage.readConfig();
      for (var i = 0; i < 12; i++) {
        expect(config['key$i'], i);
      }
      expect(await tmpLeftovers(), isEmpty);
    });

    test('writes refuse an unreadable file and keep its bytes', () async {
      final file = await dataFile('storage_config.json');
      const corrupt = '{"storagePath": "D:/MyDay", ';
      await file.writeAsString(corrupt);

      expect(await TodoStorage.readConfig(), isEmpty);
      await expectLater(
        TodoStorage.writeConfig({'apiEnabled': true}),
        throwsA(isA<TodoStorageException>()),
      );
      await expectLater(
        TodoStorage.setMinimizeToTray(true),
        throwsA(isA<TodoStorageException>()),
      );
      expect(await file.readAsString(), corrupt);

      // The queue keeps working once the file is readable again.
      await file.writeAsString('{"storagePath": "D:/MyDay"}');
      await TodoStorage.writeConfig({'apiEnabled': true});
      expect(await TodoStorage.readConfig(), {
        'storagePath': 'D:/MyDay',
        'apiEnabled': true,
      });
    });

    test('the auto column preference removes its key', () async {
      await TodoStorage.setTodoSectionColumns(2);
      expect((await TodoStorage.readConfig())['todoSectionColumns'], 2);
      await TodoStorage.setTodoSectionColumns(listColumnsAuto);
      expect(
        (await TodoStorage.readConfig()).containsKey('todoSectionColumns'),
        isFalse,
      );
    });
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

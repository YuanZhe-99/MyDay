// Golden (characterization) harness for MyDay.
//
// Drives the REAL, unmodified `WebDAVService` / `BackupService` /
// `ImportExportService` against an in-memory fake WebDAV server, recording the
// exact request sequence and on-disk formats into golden files. This is PLAN
// task P0.2: post-extraction (Phase 3), the new shared engine must reproduce
// these identical sequences (invariants I1-I3). Re-run / re-record with:
//   flutter test test/golden/webdav_golden_test.dart            (verify)
//   flutter test --dart-define=GOLDEN_RECORD=true test/golden/webdav_golden_test.dart  (record)
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/src/client.dart' show runWithClient;
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:my_day/shared/services/backup_service.dart';
import 'package:my_day/shared/services/import_export_service.dart';
import 'package:my_day/shared/services/webdav_service.dart';

import 'fake_webdav_server.dart';
import 'request_recorder.dart';

/// Whether to rewrite goldens instead of verifying them.
const bool _record =
    bool.fromEnvironment('GOLDEN_RECORD', defaultValue: false);

/// Fake application-documents provider (pattern from existing app tests).
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);
  final String documentsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

/// The five synced data files, in `_dataFileNames` order.
const List<String> _dataFiles = [
  'todo_data.json',
  'finance_data.json',
  'exchange_rates.json',
  'intimacy_data.json',
  'weight_data.json',
];

/// Fixed WebDAV config pointing at the fake server.
WebDAVConfig _config() => const WebDAVConfig(
      serverUrl: 'https://golden.test/dav/files/u',
      username: 'u',
      password: 'p',
      remotePath: '/MyDay',
    );

/// A full set of valid per-module data payloads. [overrides] replaces a module.
Map<String, String> _dataSet({Map<String, String>? overrides}) {
  const ts = '2026-01-02T00:00:00.000Z';
  final data = <String, String>{
    'todo_data.json': const JsonEncoder.withIndent('  ').convert({
      'dailyTemplates': [],
      'oneTimeTasks': [
        {
          'id': 'task-1',
          'title': 'Task One',
          'type': 'routineOnce',
          'createdDate': '2026-01-01T00:00:00.000Z',
          'modifiedAt': ts,
        }
      ],
      'settingsModifiedAt': ts,
    }),
    'finance_data.json': const JsonEncoder.withIndent('  ').convert({
      'accounts': [
        {
          'id': 'acct-1',
          'type': 'fund',
          'bankOrApp': 'Bank',
          'name': 'Checking',
          'currency': 'CNY',
          'modifiedAt': ts,
        }
      ],
      'categories': [],
      'transactions': [],
      'subscriptions': [],
      'defaultCurrency': 'CNY',
      'settingsModifiedAt': ts,
    }),
    'exchange_rates.json': const JsonEncoder.withIndent('  ').convert({
      'currentSnapshotId': '',
      'snapshots': {},
      'lastFetchedAt': ts,
    }),
    'intimacy_data.json': const JsonEncoder.withIndent('  ').convert({
      'partners': [
        {'id': 'partner-1', 'name': 'Partner', 'modifiedAt': ts}
      ],
      'toys': [],
      'positions': [],
      'records': [],
      'timerHistory': [],
      'settingsModifiedAt': ts,
    }),
    'weight_data.json': const JsonEncoder.withIndent('  ').convert({
      'records': [
        {
          'id': 'w-1',
          'weight': 70.5,
          'datetime': '2026-01-01T08:00:00.000Z',
          'modifiedAt': ts,
        }
      ],
      'reminderMode': 'none',
      'settingsModifiedAt': ts,
    }),
  };
  data.addAll(overrides ?? const {});
  return data;
}

/// One scenario sandbox: a fresh temp dir + fresh fake server + recorder.
class _Sandbox {
  _Sandbox(this.dir, this.server, this.recorder);
  final Directory dir;
  final FakeWebDAVServer server;
  final RequestRecorder recorder;

  String get appDir => p.join(dir.path, 'MyDay');

  /// Remote path for a data file (server keys on full request path).
  String remote(String name) => '/dav/files/u/MyDay/$name';

  Future<File> dataFile(String name) async => File(p.join(appDir, name));

  /// Write all local module files from [data].
  Future<void> writeLocalData(Map<String, String> data) async {
    await Directory(appDir).create(recursive: true);
    for (final entry in data.entries) {
      await (await dataFile(entry.key)).writeAsString(entry.value);
    }
  }

  /// Seed the remote store from [data].
  void seedRemote(Map<String, String> data) {
    for (final entry in data.entries) {
      server.seed(remote(entry.key), entry.value);
    }
  }

  /// Write base snapshots from [data].
  Future<void> writeBase(Map<String, String> data) async {
    final baseDir = Directory(p.join(appDir, '.sync_base'));
    await baseDir.create(recursive: true);
    for (final entry in data.entries) {
      await File(p.join(baseDir.path, entry.key)).writeAsString(entry.value);
    }
  }

  String transcript() => GoldenTranscript(recorder.exchanges).render();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final goldensDir = Directory(p.join('test', 'golden', 'goldens', 'myday'));

  Future<_Sandbox> newSandbox() async {
    final dir = await Directory.systemTemp.createTemp('myday_golden_');
    PathProviderPlatform.instance = _FakePathProvider(dir.path);
    final server = FakeWebDAVServer();
    final recorder = RequestRecorder(server);
    return _Sandbox(dir, server, recorder);
  }

  Future<void> expectGolden(_Sandbox sb, String name) async {
    final file = File(p.join(goldensDir.path, '$name.txt'));
    final mismatch =
        await GoldenMatcher(file, record: _record).check(sb.transcript());
    expect(mismatch, isNull, reason: 'golden "$name" mismatch:\n$mismatch');
  }

  Future<T> zone<T>(_Sandbox sb, Future<T> Function() body) =>
      runWithClient(body, () => sb.recorder);

  group('webdav sync request-sequence goldens', () {
    test('first sync (local data, empty remote)', () async {
      final sb = await newSandbox();
      await sb.writeLocalData(_dataSet());
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'sync_first');
      expect(sb.server.readText(sb.remote('todo_data.json')),
          contains('Task One'));
      await sb.dir.delete(recursive: true);
    });

    test('no-change sync (local == remote == base)', () async {
      final sb = await newSandbox();
      final data = _dataSet();
      await sb.writeLocalData(data);
      sb.seedRemote(data);
      await sb.writeBase(data);
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'sync_no_change');
      await sb.dir.delete(recursive: true);
    });

    test('local-only change (upload merged)', () async {
      final sb = await newSandbox();
      final base = _dataSet();
      final local = _dataSet(overrides: {
        'weight_data.json': const JsonEncoder.withIndent('  ').convert({
          'records': [
            {
              'id': 'w-1',
              'weight': 71.0,
              'datetime': '2026-01-01T08:00:00.000Z',
              'modifiedAt': '2026-01-03T00:00:00.000Z',
            },
            {
              'id': 'w-2',
              'weight': 72.0,
              'datetime': '2026-01-02T08:00:00.000Z',
              'modifiedAt': '2026-01-03T00:00:00.000Z',
            },
          ],
          'reminderMode': 'none',
          'settingsModifiedAt': '2026-01-02T00:00:00.000Z',
        }),
      });
      await sb.writeLocalData(local);
      sb.seedRemote(base);
      await sb.writeBase(base);
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'sync_local_change');
      expect(sb.server.readText(sb.remote('weight_data.json')),
          contains('w-2'));
      await sb.dir.delete(recursive: true);
    });

    test('remote-only change (download)', () async {
      final sb = await newSandbox();
      final base = _dataSet();
      final remote = _dataSet(overrides: {
        'todo_data.json': const JsonEncoder.withIndent('  ').convert({
          'dailyTemplates': [],
          'oneTimeTasks': [
            {
              'id': 'task-1',
              'title': 'Task One',
              'type': 'routineOnce',
              'createdDate': '2026-01-01T00:00:00.000Z',
              'modifiedAt': '2026-01-02T00:00:00.000Z',
            },
            {
              'id': 'task-remote',
              'title': 'Remote Task',
              'type': 'routineOnce',
              'createdDate': '2026-01-01T00:00:00.000Z',
              'modifiedAt': '2026-01-03T00:00:00.000Z',
            },
          ],
          'settingsModifiedAt': '2026-01-02T00:00:00.000Z',
        }),
      });
      await sb.writeLocalData(base);
      sb.seedRemote(remote);
      await sb.writeBase(base);
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'sync_remote_change');
      expect((await sb.dataFile('todo_data.json')).readAsStringSync(),
          contains('Remote Task'));
      await sb.dir.delete(recursive: true);
    });

    test('both-changed-identical (no conflict)', () async {
      final sb = await newSandbox();
      final base = _dataSet();
      // Both sides changed task-1 to the SAME content after base.
      final both = _dataSet(overrides: {
        'todo_data.json': const JsonEncoder.withIndent('  ').convert({
          'dailyTemplates': [],
          'oneTimeTasks': [
            {
              'id': 'task-1',
              'title': 'Task One Renamed',
              'type': 'routineOnce',
              'createdDate': '2026-01-01T00:00:00.000Z',
              'modifiedAt': '2026-01-05T00:00:00.000Z',
            }
          ],
          'settingsModifiedAt': '2026-01-02T00:00:00.000Z',
        }),
      });
      await sb.writeLocalData(both);
      sb.seedRemote(both);
      await sb.writeBase(base);
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      expect(result.pending, isNull,
          reason: 'identical content must not conflict');
      await expectGolden(sb, 'sync_both_identical');
      await sb.dir.delete(recursive: true);
    });

    test('true conflict then finalize', () async {
      final sb = await newSandbox();
      final base = _dataSet();
      final local = _dataSet(overrides: {
        'weight_data.json': const JsonEncoder.withIndent('  ').convert({
          'records': [
            {
              'id': 'w-1',
              'weight': 71.0,
              'datetime': '2026-01-01T08:00:00.000Z',
              'modifiedAt': '2026-01-05T00:00:00.000Z',
            }
          ],
          'reminderMode': 'none',
          'settingsModifiedAt': '2026-01-02T00:00:00.000Z',
        }),
      });
      final remote = _dataSet(overrides: {
        'weight_data.json': const JsonEncoder.withIndent('  ').convert({
          'records': [
            {
              'id': 'w-1',
              'weight': 72.0,
              'datetime': '2026-01-01T08:00:00.000Z',
              'modifiedAt': '2026-01-06T00:00:00.000Z',
            }
          ],
          'reminderMode': 'none',
          'settingsModifiedAt': '2026-01-02T00:00:00.000Z',
        }),
      });
      await sb.writeLocalData(local);
      sb.seedRemote(remote);
      await sb.writeBase(base);

      final syncResult = await zone(sb, () => WebDAVService.sync(_config()));
      expect(syncResult.pending, isNotNull,
          reason: 'both-changed-different must conflict');

      // Resolve: choose the remote record for each conflict id.
      final resolutions = <String, dynamic>{
        for (final c in syncResult.pending!.allConflicts) c.id: c.remoteRecord,
      };
      final fin = await zone(
          sb,
          () => WebDAVService.finalizePendingSync(
              _config(), syncResult.pending!, resolutions));
      expect(fin, isTrue);
      await expectGolden(sb, 'sync_conflict_finalize');
      expect(sb.server.readText(sb.remote('weight_data.json')),
          contains('72.0'));
      await sb.dir.delete(recursive: true);
    });

    test('force upload', () async {
      final sb = await newSandbox();
      await sb.writeLocalData(_dataSet());
      // Remote holds stale content that force upload must overwrite.
      sb.seedRemote(_dataSet(overrides: {
        'weight_data.json': '{"records":[],"reminderMode":"none"}',
      }));
      final result = await zone(sb, () => WebDAVService.forceUpload(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'force_upload');
      expect(
          sb.server.readText(sb.remote('weight_data.json')), contains('w-1'));
      await sb.dir.delete(recursive: true);
    });

    test('force download', () async {
      final sb = await newSandbox();
      await sb.writeLocalData(_dataSet());
      sb.seedRemote(_dataSet(overrides: {
        'todo_data.json': const JsonEncoder.withIndent('  ').convert({
          'dailyTemplates': [],
          'oneTimeTasks': [
            {
              'id': 'task-remote',
              'title': 'Remote Task',
              'type': 'routineOnce',
              'createdDate': '2026-01-01T00:00:00.000Z',
              'modifiedAt': '2026-01-03T00:00:00.000Z',
            }
          ],
          'settingsModifiedAt': '2026-01-02T00:00:00.000Z',
        }),
      }));
      final result =
          await zone(sb, () => WebDAVService.forceDownload(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'force_download');
      expect((await sb.dataFile('todo_data.json')).readAsStringSync(),
          contains('Remote Task'));
      await sb.dir.delete(recursive: true);
    });

    test('interrupted upload recovery (leftover local lock)', () async {
      final sb = await newSandbox();
      final data = _dataSet();
      await sb.writeLocalData(data);
      sb.seedRemote(data);
      await sb.writeBase(data);
      // Simulate an interrupted prior upload: dead local lock, remote lock gone.
      final baseDir = Directory(p.join(sb.appDir, '.sync_base'));
      await File(p.join(baseDir.path, 'upload_lock.json')).writeAsString(
          jsonEncode({
            'clientId': 'dead-client',
            'token': 'dead-token',
            'startedAt': '2026-01-01T00:00:00.000Z',
            'updatedAt': '2026-01-01T00:00:00.000Z',
            'ttlSeconds': 60,
          }));
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'sync_interrupted_recovery');
      await sb.dir.delete(recursive: true);
    });

    test('image add on each side (additive image sync)', () async {
      final sb = await newSandbox();
      // Local finance account references cover_local.jpg; remote intimacy
      // partner references cover_remote.jpg.
      final local = _dataSet(overrides: {
        'finance_data.json': const JsonEncoder.withIndent('  ').convert({
          'accounts': [
            {
              'id': 'acct-1',
              'type': 'fund',
              'bankOrApp': 'Bank',
              'name': 'Checking',
              'currency': 'CNY',
              'imagePath': 'cover_local.jpg',
              'modifiedAt': '2026-01-02T00:00:00.000Z',
            }
          ],
          'categories': [],
          'transactions': [],
          'subscriptions': [],
          'defaultCurrency': 'CNY',
          'settingsModifiedAt': '2026-01-02T00:00:00.000Z',
        }),
      });
      final remote = _dataSet(overrides: {
        'intimacy_data.json': const JsonEncoder.withIndent('  ').convert({
          'partners': [
            {
              'id': 'partner-1',
              'name': 'Partner',
              'imagePath': 'cover_remote.jpg',
              'modifiedAt': '2026-01-02T00:00:00.000Z',
            }
          ],
          'toys': [],
          'positions': [],
          'records': [],
          'timerHistory': [],
          'settingsModifiedAt': '2026-01-02T00:00:00.000Z',
        }),
      });
      await sb.writeLocalData(local);
      final imgDir = Directory(p.join(sb.appDir, 'images'));
      await imgDir.create(recursive: true);
      await File(p.join(imgDir.path, 'cover_local.jpg')).writeAsBytes([1, 2, 3]);
      sb.seedRemote(remote);
      sb.server.seed(sb.remote('images/cover_remote.jpg'), [9, 9, 9]);
      await sb.writeBase(local);
      final result = await zone(sb, () => WebDAVService.sync(_config()));
      expect(result.success, isTrue, reason: result.error);
      await expectGolden(sb, 'sync_image_add_both_sides');
      expect(sb.server.exists(sb.remote('images/cover_local.jpg')), isTrue);
      expect(await File(p.join(imgDir.path, 'cover_remote.jpg')).exists(),
          isTrue);
      await sb.dir.delete(recursive: true);
    });
  });

  group('backup goldens (on-disk format)', () {
    test('v2 create bundle layout', () async {
      final sb = await newSandbox();
      BackupService.appDirProvider = () async => Directory(sb.appDir);
      BackupService.autoBackupEnabled = false;
      await sb.writeLocalData(_dataSet());
      final imgDir = Directory(p.join(sb.appDir, 'images'));
      await imgDir.create(recursive: true);
      await File(p.join(imgDir.path, 'cover1.jpg')).writeAsBytes([1, 2, 3]);

      final backup = await BackupService.createBackup();
      expect(backup, isNotNull);
      expect(await backup!.exists(), isTrue);

      final bundle =
          jsonDecode(await backup.readAsString()) as Map<String, dynamic>;
      final blobDir = Directory(p.join(sb.appDir, 'backups', 'blobs'));
      final blobs = await blobDir
          .list()
          .where((e) => e is File)
          .map((e) => p.basename(e.path))
          .toList();
      blobs.sort();
      final golden = StringBuffer()
        ..writeln('backupFormat: ${bundle['_backupFormat']}')
        ..writeln(
            'topLevelKeys: ${(bundle.keys.toList()..sort()).join(',')}')
        ..writeln('hasImageRefs: ${bundle.containsKey('_imageRefs')}')
        ..writeln('imageRefKeys: '
            '${((bundle['_imageRefs'] as Map?)?.keys.toList() ?? [])}')
        ..writeln('dataIsString: '
            '${_dataFiles.map((f) => '$f=${bundle[f] is String}').join(',')}')
        ..writeln(
            'blobs: ${blobs.map((b) => b.replaceAll(RegExp('[0-9a-f]{64}'), '<sha256>')).join(',')}');
      final file = File(p.join(goldensDir.path, 'backup_v2_create.txt'));
      final mismatch =
          await GoldenMatcher(file, record: _record).check(golden.toString());
      expect(mismatch, isNull, reason: mismatch);
      BackupService.appDirProvider = null;
      await sb.dir.delete(recursive: true);
    });

    test('corrupt bundle flagged in listBackups', () async {
      final sb = await newSandbox();
      BackupService.appDirProvider = () async => Directory(sb.appDir);
      final backupDir = Directory(p.join(sb.appDir, 'backups'));
      await backupDir.create(recursive: true);
      await File(p.join(backupDir.path, 'backup_20260101_000000.json'))
          .writeAsString('{corrupt not json');
      final list = await BackupService.listBackups();
      expect(list.single.corrupt, isTrue);
      BackupService.appDirProvider = null;
      await sb.dir.delete(recursive: true);
    });
  });

  group('zip goldens', () {
    test('export entry list', () async {
      final sb = await newSandbox();
      await sb.writeLocalData(_dataSet());
      final imgDir = Directory(p.join(sb.appDir, 'images'));
      await imgDir.create(recursive: true);
      await File(p.join(imgDir.path, 'cover1.jpg')).writeAsBytes([1, 2, 3]);
      final outDir = await Directory.systemTemp.createTemp('myday_zip_');
      final zipPath = await ImportExportService.exportZIP(outDir.path);
      expect(zipPath, isNotNull);
      final entries = _zipEntries(File(zipPath!));
      final file = File(p.join(goldensDir.path, 'zip_export_entries.txt'));
      final mismatch = await GoldenMatcher(file, record: _record).check(
          '${entries.join('\n')}\narchiveName: ${p.basename(zipPath).replaceAll(RegExp(r'\d{8}_\d{6}'), '<stamp>')}\n');
      expect(mismatch, isNull, reason: mismatch);
      await sb.dir.delete(recursive: true);
      await outDir.delete(recursive: true);
    });

    test('import rejects path traversal', () async {
      final sb = await newSandbox();
      final zip = _buildZip({
        '../evil.json': utf8.encode('{"dailyTemplates":[],"oneTimeTasks":[]}'),
        'todo_data.json': utf8.encode(
            '{"dailyTemplates":[],"oneTimeTasks":[]}'),
      });
      final zipFile = File(p.join(sb.dir.path, 'evil.zip'));
      await zipFile.writeAsBytes(zip);
      // MyDay strictly rejects unknown/traversal entries with a false result.
      final ok = await ImportExportService.importZIP(zipFile.path);
      expect(ok, isFalse, reason: 'MyDay must reject traversal entries');
      await sb.dir.delete(recursive: true);
    });
  });
}

/// Read entry names from a ZIP file.
List<String> _zipEntries(File zipFile) {
  final bytes = zipFile.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final names = archive.map((f) => f.name).toList()..sort();
  return names;
}

/// Build a ZIP in-memory from a name->bytes map.
List<int> _buildZip(Map<String, List<int>> files) {
  final archive = Archive();
  files.forEach((name, bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return ZipEncoder().encode(archive);
}

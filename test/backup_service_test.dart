import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/shared/services/backup_service.dart';
import 'package:path/path.dart' as p;

/// Purpose: Test backup format v2 blob deduplication, reference-counted blob
/// garbage collection, legacy inline-image restore, image-name sanitization,
/// and corrupt-bundle detection.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates and deletes files in a temporary directory.
/// Notes: Uses `BackupService.appDirProvider` to isolate all I/O.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_test_');
    BackupService.appDirProvider = () async => tempDir;
    BackupService.autoBackupEnabled = false;
    BackupService.retentionDays = 0;
  });

  tearDown(() async {
    BackupService.appDirProvider = null;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> writeData(String name, String json) async {
    await File(p.join(tempDir.path, name)).writeAsString(json);
  }

  Future<void> writeImage(String name, List<int> bytes) async {
    final dir = Directory(p.join(tempDir.path, 'images'));
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(p.join(dir.path, name)).writeAsBytes(bytes);
  }

  Directory blobDir() => Directory(p.join(tempDir.path, 'backups', 'blobs'));

  Future<List<File>> listBlobs() async {
    if (!await blobDir().exists()) return [];
    return blobDir().list().where((e) => e is File).cast<File>().toList();
  }

  Future<void> ageBlobs() async {
    final old = DateTime.now().subtract(const Duration(hours: 1));
    for (final blob in await listBlobs()) {
      await blob.setLastModified(old);
    }
  }

  // Backup filenames have second granularity; space out consecutive
  // createBackup calls so each test backup gets a distinct file.
  Future<void> nextSecond() =>
      Future<void>.delayed(const Duration(milliseconds: 1100));

  group('backup format v2', () {
    test('identical images across backups share one blob', () async {
      await writeData('todo_data.json', '{"dailyTemplates": [], "oneTimeTasks": []}');
      await writeImage('logo1.png', [1, 2, 3, 4]);

      final b1 = await BackupService.createBackup();
      await nextSecond();
      final b2 = await BackupService.createBackup();
      expect(b1, isNotNull);
      expect(b2, isNotNull);
      expect(b2!.path, isNot(b1!.path));

      final blobs = await listBlobs();
      expect(blobs.length, 1);

      final bundle =
          jsonDecode(await b2.readAsString()) as Map<String, dynamic>;
      expect(bundle['_backupFormat'], 2);
      final refs = bundle['_imageRefs'] as Map<String, dynamic>;
      expect(refs.keys.single, 'images/logo1.png');
      expect(bundle.containsKey('_images'), isFalse);
    });

    test('blob is deleted only when no backup references it', () async {
      await writeData('todo_data.json', '{"dailyTemplates": [], "oneTimeTasks": []}');
      await writeImage('logo1.png', [1, 2, 3, 4]);
      final b1 = await BackupService.createBackup();
      await nextSecond();
      final b2 = await BackupService.createBackup();
      await ageBlobs();

      await BackupService.deleteBackup(b1!);
      expect((await listBlobs()).length, 1);

      await BackupService.deleteBackup(b2!);
      expect((await listBlobs()).length, 0);
    });

    test('restore copies blob-referenced images back', () async {
      await writeData('todo_data.json', '{"dailyTemplates": [], "oneTimeTasks": []}');
      await writeImage('logo1.png', [1, 2, 3, 4]);
      final b1 = await BackupService.createBackup();

      await File(p.join(tempDir.path, 'images', 'logo1.png')).delete();

      final result = await BackupService.restoreBackup(b1!);
      expect(result.ok, isTrue);
      expect(result.wroteAnything, isTrue);
      expect(result.missingImages, 0);
      expect(
        await File(p.join(tempDir.path, 'images', 'logo1.png')).readAsBytes(),
        [1, 2, 3, 4],
      );
    });

    test('restore reports missing blobs instead of dropping them silently',
        () async {
      await writeData(
          'todo_data.json', '{"dailyTemplates": [], "oneTimeTasks": []}');
      await writeImage('logo1.png', [1, 2, 3, 4]);
      final b1 = await BackupService.createBackup();

      // Simulate an incomplete blob store, e.g. a bundle copied to another
      // machine without backups/blobs/.
      for (final blob in await listBlobs()) {
        await blob.delete();
      }
      await File(p.join(tempDir.path, 'images', 'logo1.png')).delete();

      final result = await BackupService.restoreBackup(b1!);
      expect(result.ok, isTrue);
      expect(result.missingImages, 1);
      expect(
        await File(p.join(tempDir.path, 'images', 'logo1.png')).exists(),
        isFalse,
      );
    });
  });

  group('legacy v1 bundles', () {
    test('inline base64 images restore and traversal keys are rejected',
        () async {
      final legacy = {
        'todo_data.json': '{"dailyTemplates": [], "oneTimeTasks": []}',
        '_images': {
          'images/legacy.png': base64Encode([7, 7, 7]),
          'images/../escape.txt': base64Encode([1]),
        },
      };
      final backupDirPath = Directory(p.join(tempDir.path, 'backups'));
      await backupDirPath.create(recursive: true);
      final file = File(
        p.join(backupDirPath.path, 'backup_20240101_120000.json'),
      );
      await file.writeAsString(jsonEncode(legacy));

      final result = await BackupService.restoreBackup(file);
      expect(result.ok, isTrue);
      expect(
        await File(p.join(tempDir.path, 'images', 'legacy.png')).exists(),
        isTrue,
      );
      expect(
        await File(p.join(tempDir.path, 'escape.txt')).exists(),
        isFalse,
      );
    });

    test('invalid module JSON aborts restore without writing', () async {
      await writeData('todo_data.json', '{"dailyTemplates": [], "oneTimeTasks": []}');
      final backupDirPath = Directory(p.join(tempDir.path, 'backups'));
      await backupDirPath.create(recursive: true);
      final file = File(
        p.join(backupDirPath.path, 'backup_20240101_120001.json'),
      );
      await file.writeAsString(
        jsonEncode({'todo_data.json': 'not valid json'}),
      );

      final result = await BackupService.restoreBackup(file);
      expect(result.ok, isFalse);
      expect(result.wroteAnything, isFalse);
      expect(
        await File(p.join(tempDir.path, 'todo_data.json')).readAsString(),
        '{"dailyTemplates": [], "oneTimeTasks": []}',
      );
    });
  });

  group('listBackups', () {
    test('marks unparseable bundles as corrupt', () async {
      await writeData('todo_data.json', '{"dailyTemplates": [], "oneTimeTasks": []}');
      await BackupService.createBackup();
      final corrupt = File(
        p.join(tempDir.path, 'backups', 'backup_20200101_000000.json'),
      );
      await corrupt.writeAsString('{truncated');

      final backups = await BackupService.listBackups();
      expect(backups.length, 2);
      expect(
        backups.singleWhere((b) => b.file.path == corrupt.path).corrupt,
        isTrue,
      );
    });
  });
}

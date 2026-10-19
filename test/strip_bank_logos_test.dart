import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../tool/bank_logo_manifest_writer.dart';
import '../tool/strip_bank_logos.dart';

/// Purpose: Build a minimal project skeleton with bundled logos in a temp directory.
/// Inputs: None.
/// Returns: `Directory` root of the skeleton.
/// Side effects: Creates files under the system temp directory.
/// Notes: Mirrors the three artifacts the strip step removes.
Directory _skeleton() {
  final root = Directory.systemTemp.createTempSync('strip_logos_');
  File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample
flutter:
  assets:
    - assets/banks.json
    - assets/bank_logos/
    - assets/template_finance.csv
''');
  final logos = Directory(p.join(root.path, bankLogoAssetDir))..createSync(recursive: true);
  File(p.join(logos.path, 'us_chase.svg')).writeAsStringSync('<svg/>');
  File(p.join(logos.path, 'cn_icbc.png')).writeAsBytesSync(List.filled(100, 1));
  File(p.join(root.path, bankLogoManifestPath))
    ..createSync(recursive: true)
    ..writeAsStringSync(renderBankLogoManifest({
      'us/chase': 'assets/bank_logos/us_chase.svg',
      'cn/icbc': 'assets/bank_logos/cn_icbc.png',
    }));
  return root;
}

/// Purpose: Run the Store-build logo strip tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates and deletes temp directories.
/// Notes: Never touches the real working tree.
void main() {
  late Directory root;
  setUp(() => root = _skeleton());
  tearDown(() => root.deleteSync(recursive: true));

  test('strips files, the pubspec entry and the manifest entries', () {
    expect(bankLogoLeftovers(root), hasLength(3));
    final r = stripBankLogos(root);
    expect(r.filesDeleted, 2);
    expect(r.bytesFreed, 106);
    expect(r.pubspecLineRemoved, isTrue);
    expect(r.manifestEmptied, isTrue);

    expect(Directory(p.join(root.path, bankLogoAssetDir)).existsSync(), isFalse);
    final pubspec = File(p.join(root.path, 'pubspec.yaml')).readAsStringSync();
    expect(pubspec, isNot(contains('bank_logos')));
    expect(pubspec, contains('assets/banks.json'));
    expect(pubspec, contains('assets/template_finance.csv'));
    final manifest = File(p.join(root.path, bankLogoManifestPath)).readAsStringSync();
    expect(manifest, contains('bankLogoAssets = <String, String>{};'));
    expect(bankLogoLeftovers(root), isEmpty);
  });

  test('dry run changes nothing', () {
    final r = stripBankLogos(root, dryRun: true);
    expect(r.didWork, isTrue);
    expect(r.filesDeleted, 2);
    expect(bankLogoLeftovers(root), hasLength(3));
  });

  test('a second run is a no-op', () {
    stripBankLogos(root);
    final again = stripBankLogos(root);
    expect(again.didWork, isFalse);
    expect(again.filesDeleted, 0);
  });

  test('the empty manifest renders as valid, stable Dart', () {
    final source = renderBankLogoManifest(const {}, stripped: true);
    expect(source, contains('const Map<String, String> bankLogoAssets = <String, String>{};'));
    expect(renderBankLogoManifest(const {}, stripped: true), source);
  });
}

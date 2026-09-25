import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'package:my_day/features/finance/services/bank_logo_manifest.g.dart';
import 'package:my_day/features/finance/services/bank_preset_service.dart';

import '../tool/gen_bank_logo_manifest.dart';

/// Purpose: Run the bundled bank logo manifest consistency tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: Reads assets from disk and the test asset bundle.
/// Notes: Guards the three ways the bundle can drift: a manifest entry without a file, a file
/// without a manifest entry, and a file flutter_svg / the image decoder cannot draw.
void main() {
  final presets = (jsonDecode(File('assets/banks.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final presetKeys = {for (final b in presets) '${b['country']}/${b['id']}'};

  test('the committed manifest matches the logo directory exactly', () {
    expect(bankLogoAssets, collectBankLogos(Directory.current));
  });

  test('every manifest key is a preset and every value a file', () {
    for (final e in bankLogoAssets.entries) {
      expect(presetKeys, contains(e.key));
      expect(File(e.value).existsSync(), isTrue, reason: e.value);
      expect(p.basenameWithoutExtension(e.value), e.key.replaceFirst('/', '_'));
    }
  });

  test('the pubspec bundles the logo directory', () {
    final lines = File('pubspec.yaml').readAsLinesSync().map((l) => l.trim());
    expect(lines, contains('- assets/bank_logos/'));
  });

  test('PNG logos are square and at least 128 px', () {
    for (final a in bankLogoAssets.values.where((a) => a.endsWith('.png'))) {
      final image = img.decodePng(File(a).readAsBytesSync());
      expect(image, isNotNull, reason: a);
      expect(image!.width, image.height, reason: a);
      expect(image.width, greaterThanOrEqualTo(128), reason: a);
    }
  });

  testWidgets('every SVG logo parses and renders with flutter_svg', (tester) async {
    final failures = <String>[];
    for (final a in bankLogoAssets.values.where((a) => a.endsWith('.svg'))) {
      final source = File(a).readAsStringSync();
      try {
        await tester.runAsync(() => vg.loadPicture(SvgStringLoader(source), null));
      } catch (e) {
        failures.add('$a: $e');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));

    // One real widget render through the asset bundle.
    final first = bankLogoAssets.values.firstWhere((a) => a.endsWith('.svg'),
        orElse: () => '');
    if (first.isNotEmpty) {
      await tester.pumpWidget(MaterialApp(home: SvgPicture.asset(first, width: 40)));
      await tester.runAsync(() => rootBundle.load(first));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  test('BankPreset exposes bundled logos by country-qualified key', () {
    if (bankLogoAssets.isEmpty) return;
    final key = bankLogoAssets.keys.first;
    final parts = key.split('/');
    final preset = BankPreset(
      id: parts[1],
      country: parts[0],
      localTitle: 'x',
      engTitle: 'x',
      color: '#000000',
      domain: '',
    );
    expect(preset.key, key);
    expect(preset.bundledLogoAsset, bankLogoAssets[key]);
    const other = BankPreset(
      id: 'no-such-bank',
      country: 'zz',
      localTitle: 'x',
      engTitle: 'x',
      color: '#000000',
      domain: '',
    );
    expect(other.bundledLogoAsset, isNull);
  });
}

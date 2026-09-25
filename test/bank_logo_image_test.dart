import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/finance/services/bank_logo_manifest.g.dart';
import 'package:my_day/features/finance/services/bank_preset_service.dart';
import 'package:my_day/features/finance/widgets/bank_logo_image.dart';

/// Purpose: Build a preset for a manifest key (or an unknown one).
/// Inputs: `key` — `<country>/<id>`; `domain`.
/// Returns: `BankPreset`.
/// Side effects: None.
/// Notes: None.
BankPreset _preset(String key, {String domain = ''}) {
  final parts = key.split('/');
  return BankPreset(
    id: parts[1],
    country: parts[0],
    localTitle: 'Bank',
    engTitle: 'Bank',
    color: '#123456',
    domain: domain,
  );
}

/// Purpose: Pump a `BankLogoImage` and let its asset load settle.
/// Inputs: `tester`, `bank`.
/// Returns: `Future<void>`.
/// Side effects: Pumps widgets; loads from the test asset bundle.
/// Notes: The asset read is real I/O, so it runs inside `runAsync`.
Future<void> _pump(WidgetTester tester, BankPreset bank) async {
  await tester.pumpWidget(MaterialApp(
    home: BankLogoImage(bank: bank, fallback: const Text('fallback')),
  ));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump();
}

/// Purpose: Run the bank preset picker logo widget tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: `flutter test` is a Full build, so bundled logos are enabled.
void main() {
  testWidgets('a bundled SVG logo renders without the network', (tester) async {
    final key = bankLogoAssets.entries.firstWhere((e) => e.value.endsWith('.svg')).key;
    await _pump(tester, _preset(key, domain: 'example.com'));
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('fallback'), findsNothing);
  });

  testWidgets('a bundled PNG logo renders as an image', (tester) async {
    final key = bankLogoAssets.entries.firstWhere((e) => e.value.endsWith('.png')).key;
    await _pump(tester, _preset(key));
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('no bundled logo and no domain shows the fallback', (tester) async {
    await _pump(tester, _preset('zz/no-such-bank'));
    expect(find.text('fallback'), findsOneWidget);
  });
}

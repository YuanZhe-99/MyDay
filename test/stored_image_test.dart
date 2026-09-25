import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'package:my_day/app/build_flavor.dart';
import 'package:my_day/shared/widgets/stored_image.dart';

/// Purpose: Run the SVG-aware stored image and flavor default tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates and deletes a temp directory.
/// Notes: None.
void main() {
  late Directory dir;
  late File svg;
  late File png;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('stored_image_');
    svg = File(p.join(dir.path, 'logo.svg'))
      ..writeAsStringSync('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">'
          '<rect width="10" height="10" fill="#c00"/></svg>');
    png = File(p.join(dir.path, 'logo.PNG'))
      ..writeAsBytesSync(img.encodePng(img.Image(width: 4, height: 4)));
  });
  tearDownAll(() => dir.deleteSync(recursive: true));

  test('isSvgFile goes by extension, case-insensitively', () {
    expect(isSvgFile(svg), isTrue);
    expect(isSvgFile(File('a/B.SVG')), isTrue);
    expect(isSvgFile(png), isFalse);
  });

  testWidgets('StoredImage picks the SVG or raster decoder', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Column(children: [
        StoredImage(svg, width: 20, height: 20),
        StoredImage(png, width: 20, height: 20),
      ]),
    ));
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('StoredImageAvatar builds for both kinds', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Row(children: [
        StoredImageAvatar(svg, radius: 12),
        StoredImageAvatar(png, backgroundColor: Colors.red),
      ]),
    ));
    await tester.pump();
    expect(find.byType(CircleAvatar), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('plain test runs are Full builds', () {
    expect(isStoreBuild, isFalse);
    expect(bundledBankLogosEnabled, isTrue);
  });
}

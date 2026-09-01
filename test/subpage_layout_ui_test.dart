import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/finance/models/finance.dart';
import 'package:my_day/features/finance/views/categories_page.dart';
import 'package:my_day/features/settings/views/license_page.dart'
    as app_license;
import 'package:my_day/shared/utils/adaptive_layout.dart';

import 'layout_test_helpers.dart';

/// Purpose: Test the pages reached with `Navigator.push` — the ones that sit on
/// top of the shell and therefore measure their own width, rail included.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: See `layout_test_helpers.dart` for why the locale is Chinese and why
/// every viewport is pinned. These pages take their data as constructor
/// arguments rather than loading it, so most need no seeded storage at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Purpose: Build `count` throwaway expense categories.
  /// Inputs: `count`.
  /// Returns: `List<Category>`.
  /// Side effects: None.
  /// Notes: Chinese names, so the tiles are measured with square glyphs.
  List<Category> categories(int count) => [
    for (var i = 0; i < count; i++)
      Category(
        id: 'c$i',
        name: '分类$i',
        icon: const IconRef(codePoint: 0xe25b),
        type: TransactionType.expense,
      ),
  ];

  /// Purpose: Distinct x offsets of the rendered category tiles.
  /// Inputs: `tester`.
  /// Returns: `Set<double>`.
  /// Side effects: None.
  /// Notes: Relative positions rather than absolute pixels.
  Set<double> tileColumns(WidgetTester tester) => find
      .byType(ListTile)
      .evaluate()
      .map((e) => tester.getTopLeft(find.byWidget(e.widget)).dx)
      .toSet();

  group('CategoriesPage', () {
    testWidgets('a phone keeps one category column', (tester) async {
      final dir = await seedAppDir(tester, const {});
      addTearDown(() => deleteQuietly(dir));

      await pumpAdaptivePage(
        tester,
        CategoriesPage(categories: categories(6), onChanged: (_) {}),
        const Size(412, 915),
      );

      expect(tileColumns(tester).length, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a desktop window spreads categories across columns', (
      tester,
    ) async {
      final dir = await seedAppDir(tester, const {});
      addTearDown(() => deleteQuietly(dir));

      await pumpAdaptivePage(
        tester,
        CategoriesPage(categories: categories(6), onChanged: (_) {}),
        const Size(1440, 900),
      );

      expect(tileColumns(tester).length, greaterThan(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a Fold 8 in portrait stays single column', (tester) async {
      final dir = await seedAppDir(tester, const {});
      addTearDown(() => deleteQuietly(dir));

      // 3:4, so the aspect test refuses even though 704 dp would fit two
      // columns of the category tile's own minimum.
      expect(
        columnCapacity(704, minItemWidth: categoryTileMinWidth),
        greaterThan(1),
      );
      await pumpAdaptivePage(
        tester,
        CategoriesPage(categories: categories(6), onChanged: (_) {}),
        const Size(704, 932),
      );

      expect(tileColumns(tester).length, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('prose pages', () {
    testWidgets('a phone lets the licence text use the whole width', (
      tester,
    ) async {
      final dir = await seedAppDir(tester, const {});
      addTearDown(() => deleteQuietly(dir));

      await pumpAdaptivePage(
        tester,
        const app_license.LicensePage(),
        const Size(412, 915),
      );

      // Unaffected: the whole 412 less the page's own 16 dp of padding on
      // each side. The cap is width-only and cannot change a phone.
      final box = tester.getSize(find.byType(SelectableText));
      expect(box.width, 412 - 32);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'a desktop window caps the licence text at the reading measure',
      (tester) async {
        final dir = await seedAppDir(tester, const {});
        addTearDown(() => deleteQuietly(dir));

        await pumpAdaptivePage(
          tester,
          const app_license.LicensePage(),
          const Size(1440, 900),
        );

        // 840 less the page's own 16 dp of padding on each side.
        final box = tester.getSize(find.byType(SelectableText));
        expect(box.width, readingMaxContentWidth - 32);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/weight/views/weight_page.dart';

import 'layout_test_helpers.dart';

/// Purpose: Test the Weight page's double gate — the summary card sits beside
/// the trend chart only when the window has the shape, the body has room for
/// both blocks, and there is a chart to sit beside.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: See `layout_test_helpers.dart` for why this is its own file, why the
/// locale is Chinese, and why every viewport is pinned. Positions are compared
/// rather than marker widgets, so the assertions survive the page swapping one
/// wrapper for another.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Purpose: Return a weight data file with `count` records.
  /// Inputs: `count`.
  /// Returns: `Map<String, Object>`.
  /// Side effects: None.
  /// Notes: Two records is the threshold below which the chart renders nothing,
  /// which is the third condition in the page's double gate.
  Map<String, Object> weightData(int count) => {
    'weight_data.json': {
      'records': [
        for (var i = 0; i < count; i++)
          {
            'id': 'r$i',
            'datetime':
                '2026-08-${(i + 1).toString().padLeft(2, '0')}T08:00:00.000Z',
            'weight': 60.0 + i,
          },
      ],
      'height': 170.0,
    },
  };

  /// Purpose: Report whether the summary card sits beside the chart.
  /// Inputs: `tester`.
  /// Returns: `bool` — true when the blocks share a top edge and differ in x.
  /// Side effects: None.
  /// Notes: Relative positions rather than absolute pixels.
  bool summaryBesideChart(WidgetTester tester) {
    final summary = tester.getTopLeft(find.byKey(weightSummaryKey));
    final chart = tester.getTopLeft(find.byKey(weightChartKey));
    return summary.dy == chart.dy && summary.dx != chart.dx;
  }

  testWidgets('a phone stacks the summary card above the chart', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, weightData(4));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const WeightPage(), const Size(412, 915));

    expect(summaryBesideChart(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unfolded Fold 8 in landscape puts them side by side', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, weightData(4));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const WeightPage(), const Size(932, 704));

    expect(summaryBesideChart(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a Z Fold 5 in portrait passes the shape rule but stays stacked',
    (tester) async {
      // The second gate at work: 675 x 810 splits, but the body would leave the
      // chart about 300 logical pixels, so the blocks stay stacked. This is the
      // case a shape rule alone would get wrong.
      final dir = await seedAppDir(tester, weightData(4));
      addTearDown(() => deleteQuietly(dir));

      await pumpAdaptivePage(tester, const WeightPage(), const Size(675, 810));

      expect(summaryBesideChart(tester), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('one record keeps the stacked layout however wide the window', (
    tester,
  ) async {
    // The third gate at work: below two records the chart renders nothing, and
    // a summary card alone in a 280 pane beside a blank half is worse than the
    // stacked layout it would replace.
    final dir = await seedAppDir(tester, weightData(1));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const WeightPage(), const Size(1440, 900));

    expect(summaryBesideChart(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the column control follows the same capacity as the records', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, weightData(4));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const WeightPage(), const Size(412, 915));
    expect(find.byIcon(Icons.view_column_outlined), findsNothing);
  });

  testWidgets('the column control appears on a desktop window', (tester) async {
    final dir = await seedAppDir(tester, weightData(4));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const WeightPage(), const Size(1440, 900));
    expect(find.byIcon(Icons.view_column_outlined), findsOneWidget);
  });
}

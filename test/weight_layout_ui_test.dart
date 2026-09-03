import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/weight/views/weight_page.dart';

import 'layout_test_helpers.dart';

/// Purpose: Test the Weight page's triple gate — the summary card flattens into
/// a strip and the two trend charts sit side by side only when the window has
/// the shape, the body has room for two charts, and there are charts to place.
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
  /// Notes: Two records is the threshold below which the charts render nothing,
  /// which is the third condition in the page's triple gate.
  Map<String, Object> weightData(int count) => {
    'weight_data.json': {
      'records': [
        for (var i = 0; i < count; i++)
          {
            'id': 'r$i',
            'datetime':
                '2026-08-${(i + 1).toString().padLeft(2, '0')}T08:00:00.000Z',
            'weight': 60.0 + i,
            'bustCm': 83.0,
            'waistCm': 64.5,
            'hipCm': 92.0,
          },
      ],
      'height': 170.0,
    },
  };

  /// Purpose: Report whether the two trend charts share a row.
  /// Inputs: `tester`.
  /// Returns: `bool` — true when they share a top edge and differ in x.
  /// Side effects: None.
  /// Notes: They sit in one `Table` row, so the shared `dy` is exact rather
  /// than approximate.
  bool chartsSideBySide(WidgetTester tester) {
    final weight = tester.getTopLeft(find.byKey(weightTrendChartKey));
    final measurement = tester.getTopLeft(
      find.byKey(weightMeasurementChartKey),
    );
    return weight.dy == measurement.dy && weight.dx != measurement.dx;
  }

  /// Purpose: Report whether the summary stats sit beside the figure block.
  /// Inputs: `tester`.
  /// Returns: `bool` — true when the stats start to the right of the figures.
  /// Side effects: None.
  /// Notes: Relative positions rather than absolute pixels.
  bool statsBesideFigure(WidgetTester tester) {
    final figure = tester.getRect(find.byKey(weightSummaryFigureKey));
    final stats = tester.getRect(find.byKey(weightSummaryStatsKey));
    return stats.left >= figure.right;
  }

  /// Purpose: Report whether the summary block sits above the chart block.
  /// Inputs: `tester`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: True in both arrangements — only what happens *inside* the two
  /// blocks changes, which is what makes this a useful invariant to pin.
  bool summaryAboveCharts(WidgetTester tester) {
    final summary = tester.getRect(find.byKey(weightSummaryKey));
    final charts = tester.getRect(find.byKey(weightChartKey));
    return summary.bottom <= charts.top;
  }

  testWidgets('a phone stacks the charts and the summary stats', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, weightData(4));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const WeightPage(), const Size(412, 915));

    expect(chartsSideBySide(tester), isFalse);
    expect(statsBesideFigure(tester), isFalse);
    expect(summaryAboveCharts(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unfolded Fold 8 in landscape pairs the charts', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, weightData(4));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const WeightPage(), const Size(932, 704));

    expect(chartsSideBySide(tester), isTrue);
    expect(statsBesideFigure(tester), isTrue);
    expect(summaryAboveCharts(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the summary strip spans both chart columns', (tester) async {
    // The strip is what the charts gain their width from: it is one full-width
    // block above them, not a pane beside them, which is the v1.4.3 layout
    // this replaced.
    final dir = await seedAppDir(tester, weightData(4));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const WeightPage(), const Size(932, 704));

    final summary = tester.getRect(find.byKey(weightSummaryKey));
    final measurement = tester.getRect(find.byKey(weightMeasurementChartKey));
    expect(summary.right, greaterThan(measurement.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a Z Fold 5 in portrait passes the shape rule but stays stacked',
    (tester) async {
      // The second gate at work: 675 x 810 splits, but the body would leave
      // each chart under 290 logical pixels. This is the case a shape rule
      // alone would get wrong.
      final dir = await seedAppDir(tester, weightData(4));
      addTearDown(() => deleteQuietly(dir));

      await pumpAdaptivePage(tester, const WeightPage(), const Size(675, 810));

      expect(chartsSideBySide(tester), isFalse);
      expect(statsBesideFigure(tester), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('one record keeps the stacked layout however wide the window', (
    tester,
  ) async {
    // The third gate at work: below two records the charts render nothing, and
    // a summary strip above two blank halves is worse than the stacked layout
    // it would replace.
    final dir = await seedAppDir(tester, weightData(1));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const WeightPage(), const Size(1440, 900));

    expect(chartsSideBySide(tester), isFalse);
    expect(statsBesideFigure(tester), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the width gate flips one logical pixel wide of its floor', (
    tester,
  ) async {
    // n - 1 and n at the rendered page rather than in the rule: 784 gives the
    // body 671 and 785 gives it 672. Both pass `canSplitLayout`, so only the
    // width gate moves. The page subtracts a navigation rail these tests do
    // not render, so the columns here are wider than the 330 floor itself —
    // this pins where the gate flips, not the floor's own comfort.
    final dir = await seedAppDir(tester, weightData(4));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const WeightPage(), const Size(784, 704));
    expect(chartsSideBySide(tester), isFalse);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(785, 704);
    await settleAdaptivePage(tester);
    expect(chartsSideBySide(tester), isTrue);
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

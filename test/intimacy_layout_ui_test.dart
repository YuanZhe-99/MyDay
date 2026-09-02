import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/intimacy/views/intimacy_page.dart';

import 'layout_test_helpers.dart';

/// Purpose: Test that the Intimacy page keeps its month calendar in a pane of
/// its own when the window has the shape for two panes.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: See `layout_test_helpers.dart` for why this is its own file, why the
/// locale is Chinese, and why every viewport is pinned. No intimacy data is
/// seeded: the calendar and the record area render either way, and where they
/// land is what is under test. The `VerticalDivider` between the panes is the
/// marker, because it exists only in the two-pane arrangement.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Purpose: Return an intimacy data file with `count` records.
  /// Inputs: `count`.
  /// Returns: `Map<String, Object>`.
  /// Side effects: None.
  /// Notes: Two records is the threshold below which the trend chart renders
  /// nothing. The records are dated within the chart's default one-month
  /// range as of any plausible test date, by being recent relative to now.
  Map<String, Object> intimacyData(int count) {
    final now = DateTime.now();
    return {
      'intimacy_data.json': {
        'records': [
          for (var i = 0; i < count; i++)
            {
              'id': 'r$i',
              'type': 'Solo',
              'isSolo': true,
              'pleasureLevel': 3 + (i % 3),
              'duration': 600 + 60 * i,
              'datetime': now
                  .subtract(Duration(days: 2 * (count - i)))
                  .toIso8601String(),
            },
        ],
      },
    };
  }

  testWidgets('an unfolded Fold 8 keeps the chart in the calendar pane', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, intimacyData(4));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const IntimacyPage(), const Size(932, 704));

    final divider = tester.getTopLeft(find.byType(VerticalDivider)).dx;
    expect(find.text('趋势'), findsOneWidget);
    expect(tester.getTopLeft(find.text('趋势')).dx, lessThan(divider));
    expect(tester.getTopLeft(find.text('所有记录')).dx, greaterThan(divider));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Z Fold 5 in portrait renders the chart at the pane floor', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, intimacyData(4));
    addTearDown(() => deleteQuietly(dir));

    // 675 x 810 passes the split rule but leaves the pane its 320 floor, so
    // the chart gets 288: the range chips must wrap rather than overflow.
    await pumpAdaptivePage(tester, const IntimacyPage(), const Size(675, 810));

    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(find.text('趋势'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone keeps calendar, chart, records in that order', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, intimacyData(4));
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const IntimacyPage(), const Size(412, 915));

    final chart = tester.getTopLeft(find.text('趋势')).dy;
    final records = tester.getTopLeft(find.text('所有记录')).dy;
    // The month header sits above the chart, the chart above the records.
    expect(chart, greaterThan(0));
    expect(records, greaterThan(chart));
    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone stacks the calendar above the records', (tester) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const IntimacyPage(), const Size(412, 915));

    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone in landscape also stays stacked', (tester) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const IntimacyPage(), const Size(915, 412));

    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unfolded Fold 8 in landscape splits into two panes', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const IntimacyPage(), const Size(932, 704));

    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Fold 8 in portrait stays on one pane', (tester) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    // The same device as the test above, held the other way: 3:4, so the
    // aspect test refuses. This is the pair the whole rule exists for.
    await pumpAdaptivePage(tester, const IntimacyPage(), const Size(704, 932));

    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a desktop window splits and offers the column control', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const IntimacyPage(), const Size(1440, 900));

    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(find.byIcon(Icons.view_column_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

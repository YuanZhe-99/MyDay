import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/finance/views/finance_page.dart';

import 'layout_test_helpers.dart';

/// Purpose: Test that the Finance page splits its month summary away from the
/// transaction list when the window has the shape for two panes.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: See `layout_test_helpers.dart` for why this is its own file, why the
/// locale is Chinese, and why every viewport is pinned. No finance data is
/// seeded: the page draws its summary header and an empty-state transaction
/// area either way, and where those two land is what is under test. The
/// `VerticalDivider` between the panes is the marker, because it exists only in
/// the two-pane arrangement.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Purpose: Return a finance data file with one active subscription.
  /// Inputs: None.
  /// Returns: `Map<String, Object>`.
  /// Side effects: None.
  /// Notes: The subscription starts and next bills in 2099, so the processor
  /// that runs on load finds nothing overdue to write, and the upcoming-renewal
  /// strip — which looks three days ahead — stays empty. What is left is the
  /// subscription overview alone, which is what these tests look for.
  Map<String, Object> financeData() => {
    'finance_data.json': {
      'accounts': <Object>[],
      'categories': <Object>[],
      'transactions': <Object>[],
      'subscriptions': [
        {
          'id': 'sub1',
          'name': '视频会员',
          'startDate': '2099-01-01T00:00:00.000',
          'billingCycleType': 'monthly',
          'billingInterval': 1,
          'amount': 15.0,
          'currency': 'CNY',
          'accountId': 'acc1',
          'isActive': true,
          'nextBillingDate': '2099-01-01T00:00:00.000',
        },
      ],
      'defaultCurrency': 'CNY',
    },
  };

  testWidgets('a phone keeps the subscription overview off the home page', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, financeData());
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const FinancePage(), const Size(412, 915));

    // Stacked, the block would push the first transaction further down.
    expect(find.text('月应付'), findsNothing);
    expect(find.text('视频会员'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unfolded Fold 8 shows the overview in the summary pane', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, financeData());
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const FinancePage(), const Size(932, 704));

    final divider = tester.getTopLeft(find.byType(VerticalDivider)).dx;
    final due = find.text('月应付');
    final yearly = find.text('年均花费');
    expect(due, findsOneWidget);
    expect(find.text('视频会员'), findsOneWidget);
    expect(tester.getTopLeft(due).dx, lessThan(divider));
    expect(tester.getTopLeft(find.text('视频会员')).dx, lessThan(divider));
    // The pane is about 306 wide here, so the cards go two-up and the third
    // wraps to a second row.
    expect(
      tester.getTopLeft(yearly).dy,
      greaterThan(tester.getTopLeft(due).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a desktop window fits the three stat cards on one row', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, financeData());
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const FinancePage(), const Size(1440, 900));

    final due = tester.getTopLeft(find.text('月应付'));
    final avg = tester.getTopLeft(find.text('月均花费'));
    final yearly = tester.getTopLeft(find.text('年均花费'));
    expect(avg.dy, due.dy);
    expect(yearly.dy, due.dy);
    expect(avg.dx, greaterThan(due.dx));
    expect(yearly.dx, greaterThan(avg.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone stacks the summary above the transaction list', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const FinancePage(), const Size(412, 915));

    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone in landscape also stays stacked', (tester) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    // Wide but compact: the split rule refuses, even though the shell gives
    // this viewport a navigation rail on width alone.
    await pumpAdaptivePage(tester, const FinancePage(), const Size(915, 412));

    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unfolded Fold 8 in landscape splits into two panes', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const FinancePage(), const Size(932, 704));

    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Fold 8 in portrait stays on one pane', (tester) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    // The same device as the test above, held the other way: 3:4, so the
    // aspect test refuses. This is the pair the whole rule exists for.
    await pumpAdaptivePage(tester, const FinancePage(), const Size(704, 932));

    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a desktop window splits and offers the column control', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const FinancePage(), const Size(1440, 900));

    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(find.byIcon(Icons.view_column_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

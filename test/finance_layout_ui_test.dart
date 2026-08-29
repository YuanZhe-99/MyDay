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

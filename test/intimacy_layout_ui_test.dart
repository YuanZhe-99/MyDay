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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/settings/views/settings_page.dart';
import 'package:my_day/shared/views/backup_page.dart';

import 'layout_test_helpers.dart';

/// Purpose: Test that the Settings page keeps its section list on screen and
/// hosts second-level pages beside it when the window has the shape for it.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: See `layout_test_helpers.dart` for why this is its own file, why the
/// locale is Chinese, and why every viewport is pinned. The `VerticalDivider`
/// between the panes is the marker, because it exists only in the two-pane
/// arrangement.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a phone shows only the section list', (tester) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const SettingsPage(), const Size(412, 915));

    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone in landscape also shows only the list', (tester) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const SettingsPage(), const Size(915, 412));

    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unfolded Fold 8 in landscape shows a placeholder pane', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const SettingsPage(), const Size(932, 704));

    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(find.text('从左侧列表中选择一项'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Fold 8 in portrait stays on one pane', (tester) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const SettingsPage(), const Size(704, 932));

    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a row fills the detail pane and keeps the list', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const SettingsPage(), const Size(1440, 900));

    // The Data section sits below the fold in the left pane. ensureVisible
    // scrolls the row's own ancestor scrollable, rather than whichever one
    // happens to come first in the tree.
    final backupRow = find.ancestor(
      of: find.byIcon(Icons.backup),
      matching: find.byType(ListTile),
    );
    await tester.scrollUntilVisible(
      backupRow,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    // scrollUntilVisible stops as soon as the row is *built*, which can be
    // inside the cache extent and still off screen; ensureVisible then brings
    // it into the viewport so the tap actually lands on it.
    await tester.ensureVisible(backupRow);
    await tester.pump();
    await tester.tap(backupRow);
    await settleAdaptivePage(tester);

    // The hosted page renders, and the settings list is still beside it —
    // which is the whole point of the two-pane layout.
    expect(find.byType(BackupPage), findsOneWidget);
    // The row that was tapped is still on screen beside the page it opened;
    // on a phone the same tap replaces the whole screen instead.
    expect(backupRow, findsOneWidget);
  });

  testWidgets('a hosted page grows no back arrow of its own', (tester) async {
    // A nested Navigator holding one route reports canPop == false, which is
    // what lets the same page be pushed full-screen on a phone and embedded
    // here without a change.
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const SettingsPage(), const Size(1440, 900));
    final backupRow = find.ancestor(
      of: find.byIcon(Icons.backup),
      matching: find.byType(ListTile),
    );
    await tester.scrollUntilVisible(
      backupRow,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    // scrollUntilVisible stops as soon as the row is *built*, which can be
    // inside the cache extent and still off screen; ensureVisible then brings
    // it into the viewport so the tap actually lands on it.
    await tester.ensureVisible(backupRow);
    await tester.pump();
    await tester.tap(backupRow);
    await settleAdaptivePage(tester);

    expect(find.byType(BackButton), findsNothing);
  });
}

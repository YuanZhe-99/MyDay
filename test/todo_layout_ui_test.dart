import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/todo/models/task.dart';
import 'package:my_day/features/todo/views/todo_page.dart';
import 'package:my_day/features/todo/widgets/task_section.dart';

import 'layout_test_helpers.dart';

/// Purpose: Test that the Todo page's three sections go side by side when the
/// window has the shape for it.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: See `layout_test_helpers.dart` for why this is its own file, why the
/// locale is Chinese, and why every viewport is pinned. The page needs no
/// seeded tasks: it renders all three section headers either way, and where
/// those sections land is what is under test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Purpose: Distinct x offsets of the rendered task sections.
  /// Inputs: `tester`.
  /// Returns: `Set<double>`.
  /// Side effects: None.
  /// Notes: Relative positions rather than absolute pixels, so the assertion
  /// survives a padding change.
  Set<double> sectionColumns(WidgetTester tester) => find
      .byType(TaskSectionWidget)
      .evaluate()
      .map((e) => tester.getTopLeft(find.byWidget(e.widget)).dx)
      .toSet();

  testWidgets('a phone keeps the three sections in one column', (tester) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    // Pixel-class phone in portrait.
    await pumpAdaptivePage(tester, const TodoPage(), const Size(412, 915));

    expect(find.byType(TaskSectionWidget), findsNWidgets(3));
    expect(sectionColumns(tester).length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone in landscape also keeps one column', (tester) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    // 915 dp of width, but only 412 of height: the split rule refuses on
    // purpose, even though the shell gives this viewport a navigation rail.
    await pumpAdaptivePage(tester, const TodoPage(), const Size(915, 412));

    expect(sectionColumns(tester).length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unfolded Fold 8 in landscape spreads them across columns', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const TodoPage(), const Size(932, 704));

    expect(sectionColumns(tester).length, greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Fold 8 in portrait stays single column', (tester) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    // The same device as the test above, held the other way: 3:4, so the
    // aspect test refuses. This is the pair the whole rule exists for.
    await pumpAdaptivePage(tester, const TodoPage(), const Size(704, 932));

    expect(sectionColumns(tester).length, 1);
    expect(tester.takeException(), isNull);
  });

  /// Purpose: The x offset of the section holding one task type.
  /// Inputs: `tester`, `type`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Found by type rather than by title text, so a label change cannot
  /// break a layout assertion.
  double sectionX(WidgetTester tester, TaskType type) => tester
      .getTopLeft(
        find.byWidgetPredicate(
          (w) => w is TaskSectionWidget && w.taskType == type,
        ),
      )
      .dx;

  /// Purpose: The x offset of the daily score card.
  /// Inputs: `tester`.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Simplified Chinese label, per the locale the harness pins.
  double scoreCardX(WidgetTester tester) =>
      tester.getTopLeft(find.text('本日评分')).dx;

  testWidgets('two columns read Daily + Routine, then Work + score', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    // Fold 8 landscape: two section columns. Column-major fill puts the first
    // two sections in the left column and the last one — with the score card
    // under it — in the right, rather than dealing them round-robin.
    await pumpAdaptivePage(tester, const TodoPage(), const Size(932, 704));

    expect(sectionColumns(tester).length, 2);
    final daily = sectionX(tester, TaskType.daily);
    final routine = sectionX(tester, TaskType.routineOnce);
    final work = sectionX(tester, TaskType.workOnce);
    expect(routine, daily);
    expect(work, greaterThan(daily));
    expect(scoreCardX(tester), greaterThanOrEqualTo(work));
    expect(scoreCardX(tester), lessThan(work + 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('three columns keep one section each and the score under Work', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const TodoPage(), const Size(1440, 900));

    expect(sectionColumns(tester).length, 3);
    final daily = sectionX(tester, TaskType.daily);
    final routine = sectionX(tester, TaskType.routineOnce);
    final work = sectionX(tester, TaskType.workOnce);
    expect(daily, lessThan(routine));
    expect(routine, lessThan(work));
    expect(scoreCardX(tester), greaterThanOrEqualTo(work));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the column control is hidden until more than one column fits', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const TodoPage(), const Size(412, 915));
    expect(find.byIcon(Icons.view_column_outlined), findsNothing);
  });

  testWidgets('the column control appears on a splittable window', (
    tester,
  ) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => deleteQuietly(dir));

    await pumpAdaptivePage(tester, const TodoPage(), const Size(932, 704));
    expect(find.byIcon(Icons.view_column_outlined), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/shared/utils/adaptive_layout.dart';

/// Purpose: Test the app-wide adaptive layout rules as pure functions.
/// Inputs: None.
/// Returns: None.
/// Side effects: None — nothing here pumps a widget tree.
/// Notes: `lib/shared/utils/adaptive_layout.dart` imports nothing from Flutter
/// on purpose, so every layout decision can be checked at dozens of viewports
/// in milliseconds. Each viewport below names the real device it stands for, so
/// a regression reports the device it would break rather than a bare number.
/// The prose derivation is `doc/en-us/adaptive-layout.md`.
void main() {
  group('canSplitLayout', () {
    test('rejects anything under the width floor', () {
      // Galaxy Z Fold 7 / 8 Ultra cover screen, and an ordinary phone.
      expect(canSplitLayout(360, 882), isFalse);
      expect(canSplitLayout(412, 915), isFalse);
      // Galaxy Z Fold 8 cover screen, at both ends of its density range.
      expect(canSplitLayout(356, 819), isFalse);
      expect(canSplitLayout(416, 958), isFalse);
      // Exactly at and just below the floor, at an aspect that would pass.
      expect(canSplitLayout(splitMinWidth - 1, 600), isFalse);
      expect(canSplitLayout(splitMinWidth, 600), isTrue);
    });

    test('rejects anything under the height floor', () {
      // Galaxy Z Fold 8 cover screen held in landscape.
      expect(canSplitLayout(657, 416), isFalse);
      // An ordinary phone held in landscape: wide, but compact in height.
      expect(canSplitLayout(915, 412), isFalse);
      expect(canSplitLayout(900, splitMinHeight - 1), isFalse);
      expect(canSplitLayout(900, splitMinHeight), isTrue);
    });

    test('the aspect test gives the Fold 8 two answers at one width', () {
      // Galaxy Z Fold 8 unfolded: a 4:3 landscape panel, so held in portrait it
      // is 3:4 and stays single column, while in landscape it splits. No width
      // threshold can produce that; this is the whole reason the rule is not a
      // plain breakpoint.
      expect(canSplitLayout(704, 932), isFalse); // portrait, 0.755
      expect(canSplitLayout(932, 704), isTrue); // landscape, 1.32
    });

    test('near-square foldables split in both orientations', () {
      expect(canSplitLayout(675, 810), isTrue); // Z Fold 5 portrait, 0.83
      expect(canSplitLayout(690, 802), isTrue); // Z Fold 6 portrait, 0.86
      expect(canSplitLayout(733, 814), isTrue); // Z Fold 7 portrait, 0.90
      expect(canSplitLayout(839, 932), isTrue); // Z Fold 8 Ultra portrait, 0.90
      expect(canSplitLayout(773, 805), isTrue); // Pixel 10 Pro Fold, 0.96
    });

    test(
      'a tablet in portrait stays single column, which is the rule working',
      () {
        expect(canSplitLayout(768, 1024), isFalse); // 4:3 tablet portrait, 0.75
        expect(canSplitLayout(1024, 768), isTrue); // the same tablet, landscape
        expect(canSplitLayout(800, 1280), isFalse); // 16:10 tablet portrait
        expect(canSplitLayout(1280, 800), isTrue);
      },
    );

    test('the aspect threshold holds at n - 1 and n', () {
      const height = 1000.0;
      expect(canSplitLayout(splitMinAspect * height - 1, height), isFalse);
      expect(canSplitLayout(splitMinAspect * height, height), isTrue);
    });

    test('degenerate sizes never split', () {
      expect(canSplitLayout(0, 0), isFalse);
      expect(canSplitLayout(1200, 0), isFalse);
      expect(canSplitLayout(1200, -1), isFalse);
    });

    test('desktop windows split', () {
      expect(canSplitLayout(1440, 900), isTrue);
      expect(canSplitLayout(1920, 1080), isTrue);
    });
  });

  group('useNavigationRail', () {
    test('is width only, so a phone in landscape gets a rail', () {
      // The case the split rule rejects on purpose, and the case the rail helps
      // most: a bottom bar would spend 19% of 412 dp on navigation.
      expect(canSplitLayout(915, 412), isFalse);
      expect(useNavigationRail(915), isTrue);
    });

    test('holds at n - 1 and n', () {
      expect(useNavigationRail(navRailMinWidth - 1), isFalse);
      expect(useNavigationRail(navRailMinWidth), isTrue);
    });

    test('no folded cover screen earns a rail', () {
      expect(useNavigationRail(360), isFalse); // Fold 7 / 8 Ultra cover
      expect(useNavigationRail(416), isFalse); // Fold 8 cover, low density
      expect(useNavigationRail(411), isFalse); // Pixel 10 Pro Fold cover
    });

    test('every unfolded panel earns one', () {
      for (final width in [659.0, 675.0, 672.0, 716.0, 755.0, 820.0]) {
        expect(useNavigationRail(width), isTrue, reason: 'width $width');
      }
    });
  });

  group('shellContentWidth', () {
    test('subtracts the rail exactly when the rail is showing', () {
      expect(shellContentWidth(412), 412); // phone portrait, bottom bar
      expect(shellContentWidth(599), 599);
      expect(shellContentWidth(600), 600 - navRailWidth);
      expect(shellContentWidth(704), 704 - navRailWidth); // Fold 8 portrait
      expect(shellContentWidth(1440), 1440 - navRailWidth);
    });

    test('never goes negative', () {
      expect(shellContentWidth(0), 0);
      expect(shellContentWidth(-100), 0);
    });
  });

  group('columnCapacity', () {
    test('pays for the gaps between columns, not one after every column', () {
      // Two 320 columns and one 12 gap need 652, not 664.
      expect(columnCapacity(651, minItemWidth: 320), 1);
      expect(columnCapacity(652, minItemWidth: 320), 2);
      expect(columnCapacity(983, minItemWidth: 320), 2);
      expect(columnCapacity(984, minItemWidth: 320), 3);
    });

    test('respects the ceiling', () {
      expect(columnCapacity(4000, minItemWidth: 320), listMaxColumns);
      expect(columnCapacity(4000, minItemWidth: 320, maxColumns: 2), 2);
      expect(columnCapacity(4000, minItemWidth: 320, maxColumns: 0), 1);
    });

    test('degenerate inputs return something usable', () {
      expect(columnCapacity(0, minItemWidth: 320), 1);
      expect(columnCapacity(-1, minItemWidth: 320), 1);
      expect(columnCapacity(800, minItemWidth: 0), listMaxColumns);
    });

    test(
      'a folded cover screen never fits two columns of any real minimum',
      () {
        for (final minWidth in [300.0, 320.0, 340.0]) {
          expect(columnCapacity(360, minItemWidth: minWidth), 1);
          expect(columnCapacity(416, minItemWidth: minWidth), 1);
        }
      },
    );
  });

  group('listRowCount', () {
    test('rounds up, and an empty list needs no rows', () {
      expect(listRowCount(0, 3), 0);
      expect(listRowCount(1, 3), 1);
      expect(listRowCount(3, 3), 1);
      expect(listRowCount(4, 3), 2);
      expect(listRowCount(7, 2), 4);
    });

    test('treats a nonsense column count as one column', () {
      expect(listRowCount(5, 0), 5);
      expect(listRowCount(5, -2), 5);
    });
  });

  group('listColumnCount', () {
    /// Purpose: Call the rule the way a shell page does.
    /// Inputs: `width`, `height` — the whole screen; `preference`.
    /// Returns: `int`.
    /// Side effects: None.
    /// Notes: Content width comes from `shellContentWidth`, so the navigation
    /// rail is accounted for exactly as it is on screen.
    int columns(double width, double height, int preference) => listColumnCount(
      screenWidth: width,
      screenHeight: height,
      contentWidth: shellContentWidth(width),
      minItemWidth: 320,
      preference: preference,
      maxColumns: 3,
    );

    test('the gate wins over the capacity', () {
      // A tablet in portrait is wide enough for two columns but fails the shape
      // rule, so it stays on one — same as the Fold 8 in portrait.
      expect(columnCapacity(shellContentWidth(768), minItemWidth: 320), 2);
      expect(columns(768, 1024, listColumnsAuto), 1);
      expect(columns(1024, 768, listColumnsAuto), 2);
    });

    test('auto returns whatever the content box fits', () {
      expect(columns(412, 915, listColumnsAuto), 1); // phone portrait
      expect(columns(704, 932, listColumnsAuto), 1); // Fold 8 portrait: gated
      expect(columns(932, 704, listColumnsAuto), 2); // Fold 8 landscape
      expect(columns(1440, 900, listColumnsAuto), 3); // desktop, at the ceiling
    });

    test('a pinned preference is clamped, never lost', () {
      // Pinned to 3 on a desktop, then carried onto a folded phone and back.
      expect(columns(1440, 900, 3), 3);
      expect(columns(412, 915, 3), 1);
      expect(columns(932, 704, 3), 2);
      expect(columns(1440, 900, 3), 3);
    });

    test('a preference below one still renders a column', () {
      expect(columns(1440, 900, -5), 1);
    });
  });

  group('pane widths', () {
    test('the finance left pane is proportional between its clamps', () {
      // Below the floor's crossover the clamp binds; above it, proportional.
      expect(financeLeftPaneWidth(672), 280); // 0.36 x 672 = 242, floored
      expect(financeLeftPaneWidth(1000), closeTo(360, 0.01));
      expect(financeLeftPaneWidth(2000), 420); // ceiling
    });

    test('the intimacy left pane never drops below seven calendar columns', () {
      // Every splittable width leaves the calendar its 320 floor, and the
      // chart it has carried since v1.4.3 never takes the pane past 480.
      for (var width = 600.0; width <= 2000; width += 1) {
        expect(intimacyLeftPaneWidth(width), greaterThanOrEqualTo(320));
        expect(intimacyLeftPaneWidth(width), lessThanOrEqualTo(480));
      }
    });

    test('the intimacy pane widened only where there was room to widen', () {
      // The narrowest splittable foldables sit on the unchanged floor, so a
      // Z Fold 5 or 7 in portrait renders exactly as it did before v1.4.3.
      expect(intimacyLeftPaneWidth(578), 320); // Z Fold 5 portrait, content
      expect(intimacyLeftPaneWidth(672), 320); // 0.42 x 672 = 282, floored
      // The proportion clears the floor from 762 of content.
      expect(intimacyLeftPaneWidth(761), 320);
      expect(intimacyLeftPaneWidth(762), closeTo(320.04, 0.01));
      // An unfolded Fold 8 in landscape is the device that gains.
      expect(intimacyLeftPaneWidth(851), closeTo(357.42, 0.01));
      expect(intimacyLeftPaneWidth(2000), 480); // ceiling
    });

    test('the widened intimacy pane costs the record list no columns', () {
      // At a 1440 desktop the right pane still carries two record columns,
      // as it did with the 440 ceiling.
      final content = shellContentWidth(1440);
      final right = content - intimacyLeftPaneWidth(content) - 1;
      expect(
        columnCapacity(
          right,
          minItemWidth: intimacyRecordMinWidth,
          maxColumns: intimacyRecordMaxColumns,
        ),
        2,
      );
    });

    test('subscription stat cards go two-up then three-up in the pane', () {
      // Three cards need 3 x 110 plus two 8 dp gaps: 346 inside the padding.
      int cards(double inner) => columnCapacity(
        inner,
        minItemWidth: subscriptionStatMinWidth,
        gap: summaryCardGap,
        maxColumns: 3,
      );
      expect(cards(345), 2);
      expect(cards(346), 3);
      // The finance pane's whole clamp range, less its 16 dp padding each side.
      expect(cards(financeLeftPaneWidth(672) - 32), 2); // floor: 280
      expect(cards(financeLeftPaneWidth(851) - 32), 2); // Fold 8: ~306
      expect(cards(financeLeftPaneWidth(2000) - 32), 3); // ceiling: 420
    });
  });

  group('columnMajorFill', () {
    test('fills each column before starting the next', () {
      expect(columnMajorFill(3, 1), [
        [0, 1, 2],
      ]);
      // The Todo page at two columns: Daily + Routine, then Work.
      expect(columnMajorFill(3, 2), [
        [0, 1],
        [2],
      ]);
      expect(columnMajorFill(3, 3), [
        [0],
        [1],
        [2],
      ]);
    });

    test('always returns exactly the requested number of columns', () {
      expect(columnMajorFill(4, 3), [
        [0, 1],
        [2, 3],
        <int>[],
      ]);
      expect(columnMajorFill(0, 2), [<int>[], <int>[]]);
      expect(columnMajorFill(2, 0).length, 1);
      expect(columnMajorFill(2, -1), [
        [0, 1],
      ]);
    });

    test('every index appears exactly once, in order', () {
      for (var items = 0; items <= 12; items++) {
        for (var columns = 1; columns <= 5; columns++) {
          final flat = columnMajorFill(items, columns).expand((c) => c);
          expect(flat, List.generate(items, (i) => i), reason: '$items/$columns');
        }
      }
    });

    test('the settings detail pane always clears its floor', () {
      // The cap is what makes this true at the narrow end, where 0.44 of the
      // width would otherwise leave the detail pane under 280.
      for (var width = 600.0; width <= 2000; width += 1) {
        final left = settingsLeftPaneWidth(width);
        expect(
          width - left,
          greaterThanOrEqualTo(settingsRightPaneMinWidth),
          reason: 'content width $width',
        );
      }
    });

    test('the settings left pane still honours its own clamps', () {
      expect(settingsLeftPaneWidth(600), 300); // 0.44 x 600 = 264, floored
      expect(settingsLeftPaneWidth(672), 300); // 0.44 x 672 = 295.68, floored
      expect(settingsLeftPaneWidth(800), closeTo(352, 0.01)); // proportional
      expect(settingsLeftPaneWidth(2000), 440); // ceiling
    });

    test('the detail-pane cap never actually binds above the split floor', () {
      // Worth stating rather than assuming: at every width the split rule
      // admits, the proportional value already leaves the detail pane its
      // floor, so the cap is a guard for a pane narrower than any real window
      // rather than a second breakpoint that fires in practice.
      for (var width = 600.0; width <= 2000; width += 1) {
        final preferred = (width * 0.44).clamp(300.0, 440.0);
        expect(settingsLeftPaneWidth(width), preferred, reason: 'width ');
      }
      // It does bind below the split floor, which is what it is there for.
      expect(settingsLeftPaneWidth(560), lessThan(300));
    });
  });

  group('useWeightSummaryBesideChart', () {
    test('holds at n - 1 and n', () {
      const gate =
          weightSummaryPaneMinWidth + weightChartMinWidth + listTileGap; // 672
      expect(useWeightSummaryBesideChart(gate - 1), isFalse);
      expect(useWeightSummaryBesideChart(gate), isTrue);
    });

    test('a Z Fold 5 in portrait passes the split rule but not this one', () {
      // The split rule alone would leave the chart about 300 logical pixels.
      // This is why the page tests both, rather than the shape rule alone.
      expect(canSplitLayout(675, 810), isTrue);
      expect(useWeightSummaryBesideChart(shellContentWidth(675) - 32), isFalse);
    });

    test('an unfolded Fold 8 in landscape passes both', () {
      expect(canSplitLayout(932, 704), isTrue);
      expect(useWeightSummaryBesideChart(shellContentWidth(932) - 32), isTrue);
    });

    test('the chart always clears its floor from the gate up', () {
      // The invariant that makes a right-hand cap on the summary pane
      // unnecessary: the pane grows at 0.34 while the chart grows at 0.66.
      for (var width = 672.0; width <= 2000; width += 1) {
        final pane = weightSummaryPaneWidth(width);
        expect(
          width - pane - listTileGap,
          greaterThanOrEqualTo(weightChartMinWidth),
          reason: 'content width $width',
        );
      }
    });

    test('the summary pane honours both its clamps', () {
      expect(weightSummaryPaneWidth(672), 280); // 0.34 x 672 = 228, floored
      expect(weightSummaryPaneWidth(1000), closeTo(340, 0.01));
      expect(weightSummaryPaneWidth(2000), 380); // ceiling
    });
  });

  group('per-content minimums', () {
    /// Purpose: Resolve a shell page's column count the way its build does.
    /// Inputs: `width`, `height` — the whole screen; `minItemWidth`, `max`.
    /// Returns: `int`.
    /// Side effects: None.
    /// Notes: No page padding is subtracted here; the pages that have some
    /// subtract it themselves before calling.
    int columnsFor(double width, double height, double minItemWidth, int max) =>
        listColumnCount(
          screenWidth: width,
          screenHeight: height,
          contentWidth: shellContentWidth(width),
          minItemWidth: minItemWidth,
          preference: listColumnsAuto,
          maxColumns: max,
        );

    test('a phone stays on one column for every surface', () {
      for (final min in [
        taskSectionMinWidth,
        transactionTileMinWidth,
        weightRecordMinWidth,
        intimacyRecordMinWidth,
      ]) {
        expect(columnsFor(412, 915, min, 4), 1); // portrait
        expect(columnsFor(915, 412, min, 4), 1); // landscape: gated on height
      }
    });

    test(
      'a Fold 8 in portrait stays on one column, in landscape it does not',
      () {
        expect(columnsFor(704, 932, taskSectionMinWidth, 3), 1);
        expect(columnsFor(932, 704, taskSectionMinWidth, 3), 2);
      },
    );

    test('Todo never offers a fourth section column', () {
      // There are only three sections, so a fourth could never be filled.
      expect(
        columnsFor(4000, 2000, taskSectionMinWidth, taskSectionMaxColumns),
        taskSectionMaxColumns,
      );
      expect(taskSectionMaxColumns, 3);
    });

    test('a desktop window fills every surface to its own ceiling', () {
      expect(
        columnsFor(1920, 1080, transactionTileMinWidth, transactionMaxColumns),
        transactionMaxColumns,
      );
      expect(
        columnsFor(1920, 1080, weightRecordMinWidth, weightRecordMaxColumns),
        weightRecordMaxColumns,
      );
      expect(
        columnsFor(
          1920,
          1080,
          intimacyRecordMinWidth,
          intimacyRecordMaxColumns,
        ),
        intimacyRecordMaxColumns,
      );
    });
  });

  group('cappedContentWidth', () {
    test('leaves a narrow page exactly as it was', () {
      // Width only and no gate, so this can never change what a phone renders.
      expect(cappedContentWidth(412, formMaxContentWidth), 412);
      expect(cappedContentWidth(704, formMaxContentWidth), 704);
      expect(cappedContentWidth(720, formMaxContentWidth), 720);
    });

    test('caps a desktop window at the reading measure', () {
      expect(cappedContentWidth(721, formMaxContentWidth), formMaxContentWidth);
      expect(cappedContentWidth(1440, formMaxContentWidth), 720);
      expect(cappedContentWidth(1440, readingMaxContentWidth), 840);
    });

    test('prose is allowed more width than a form', () {
      // A form's controls have to stay within one glance of their labels;
      // prose has no controls whose separation matters.
      expect(readingMaxContentWidth, greaterThan(formMaxContentWidth));
    });
  });

  group('usePieChartSideBySide', () {
    test('holds at n - 1 and n', () {
      const gate = pieChartMinWidth + pieLegendMinWidth + listTileGap; // 612
      expect(usePieChartSideBySide(gate - 1), isFalse);
      expect(usePieChartSideBySide(gate), isTrue);
    });

    test('a phone keeps the legend under the chart', () {
      expect(usePieChartSideBySide(412), isFalse);
      // And the shape rule refuses anyway, which is the other half of the gate.
      expect(canSplitLayout(412, 915), isFalse);
    });

    test('an unfolded foldable passes both halves of the gate', () {
      expect(canSplitLayout(932, 704), isTrue);
      expect(usePieChartSideBySide(932), isTrue);
    });
  });

  group('useTodoCalendarSideBySide', () {
    test('holds at n - 1 and n', () {
      const gate =
          calendarCardMinWidth + scoreTrendMinWidth + listTileGap; // 712
      expect(useTodoCalendarSideBySide(gate - 1), isFalse);
      expect(useTodoCalendarSideBySide(gate), isTrue);
    });

    test('a Z Fold 5 in portrait splits but has no room for both blocks', () {
      // The shape rule alone would put a 340 calendar beside a 323 chart.
      expect(canSplitLayout(675, 810), isTrue);
      expect(useTodoCalendarSideBySide(675), isFalse);
    });

    test('the chart always clears its floor from the gate up', () {
      for (var width = 712.0; width <= 2000; width += 1) {
        final pane = todoCalendarPaneWidth(width);
        expect(
          width - pane - listTileGap,
          greaterThanOrEqualTo(scoreTrendMinWidth),
          reason: 'content width $width',
        );
      }
    });

    test('the calendar pane honours both its clamps', () {
      expect(todoCalendarPaneWidth(712), calendarCardMinWidth); // 0.4 x 712
      expect(todoCalendarPaneWidth(1000), closeTo(400, 0.01));
      expect(todoCalendarPaneWidth(2000), 480); // ceiling
    });
  });

  group('dialogHorizontalInset', () {
    test('a phone dialog keeps Flutter own default inset', () {
      expect(dialogHorizontalInset(412), dialogMinHorizontalInset);
      expect(dialogHorizontalInset(704), dialogMinHorizontalInset);
      // 640 content plus 40 on each side is where the default stops binding.
      expect(dialogHorizontalInset(720), dialogMinHorizontalInset);
    });

    test('a wide window centres the dialog instead of stretching it', () {
      expect(dialogHorizontalInset(1440), (1440 - 640) / 2);
      expect(1440 - 2 * dialogHorizontalInset(1440), dialogMaxContentWidth);
    });

    test('the content never grows past its cap on any window', () {
      for (var width = 300.0; width <= 3000; width += 1) {
        final content = width - 2 * dialogHorizontalInset(width);
        expect(
          content,
          lessThanOrEqualTo(dialogMaxContentWidth),
          reason: 'screen width $width',
        );
      }
    });
  });

  group('picker cells', () {
    test(
      'a narrow phone gets fewer, larger cells than the old fixed eight',
      () {
        // A 320 dp dialog body at eight columns gave each cell about 36 dp,
        // under Material's 44 dp minimum touch target.
        final columns = columnCapacity(
          320,
          minItemWidth: pickerCellMinWidth,
          gap: 4,
          maxColumns: pickerMaxColumns,
        );
        expect(columns, lessThan(8));
        expect((320 - (columns - 1) * 4) / columns, greaterThanOrEqualTo(44));
      },
    );

    test('a capped dialog fills out to the ceiling', () {
      expect(
        columnCapacity(
          dialogMaxContentWidth,
          minItemWidth: pickerCellMinWidth,
          gap: 4,
          maxColumns: pickerMaxColumns,
        ),
        pickerMaxColumns,
      );
    });

    test('every cell clears the touch target at every width', () {
      for (var width = 200.0; width <= dialogMaxContentWidth; width += 1) {
        final columns = columnCapacity(
          width,
          minItemWidth: pickerCellMinWidth,
          gap: 4,
          maxColumns: pickerMaxColumns,
        );
        expect(
          (width - (columns - 1) * 4) / columns,
          greaterThanOrEqualTo(pickerCellMinWidth),
          reason: 'width $width',
        );
      }
    });
  });

  group('sub-page minimums', () {
    /// Purpose: Resolve a pushed page's column count the way its build does.
    /// Inputs: `width`, `height` — the whole screen; `minItemWidth`, `max`.
    /// Returns: `int`.
    /// Side effects: None.
    /// Notes: No `shellContentWidth` here, deliberately — a page reached with
    /// `Navigator.push` has no navigation rail to subtract.
    int pushedColumns(
      double width,
      double height,
      double minItemWidth,
      int max,
    ) => listColumnCount(
      screenWidth: width,
      screenHeight: height,
      contentWidth: width,
      minItemWidth: minItemWidth,
      preference: listColumnsAuto,
      maxColumns: max,
    );

    test('a phone stays on one column for every sub-page surface', () {
      for (final min in [
        accountCardMinWidth,
        categoryTileMinWidth,
        exchangeRateTileMinWidth,
      ]) {
        expect(pushedColumns(412, 915, min, 4), 1);
        expect(pushedColumns(915, 412, min, 4), 1); // gated on height
      }
    });

    test('a pushed page measures the whole width, rail included', () {
      // The rail belongs to the shell underneath; this page covers it. Taking
      // shellContentWidth here would silently lose 81 dp.
      expect(
        pushedColumns(932, 704, accountCardMinWidth, accountMaxColumns),
        2,
      );
      expect(shellContentWidth(932), lessThan(932));
    });

    test('a desktop window fills each surface to its own ceiling', () {
      expect(
        pushedColumns(1920, 1080, accountCardMinWidth, accountMaxColumns),
        accountMaxColumns,
      );
      expect(
        pushedColumns(1920, 1080, categoryTileMinWidth, listMaxColumns),
        listMaxColumns,
      );
      expect(
        pushedColumns(1920, 1080, metricCardMinWidth, metricMaxColumns),
        metricMaxColumns,
      );
    });

    test('a metric grid packs more per row than a tile list, as intended', () {
      // A stat label above a value needs far less width than a list tile.
      expect(metricCardMinWidth, lessThan(categoryTileMinWidth));
      expect(
        pushedColumns(1000, 800, metricCardMinWidth, metricMaxColumns),
        greaterThan(pushedColumns(1000, 800, accountCardMinWidth, 4)),
      );
    });
  });
}

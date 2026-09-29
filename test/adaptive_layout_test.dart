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
  test('canSplitLayout across real devices and its floors', () {
    // (width, height, splits, device). The aspect rule, not a plain width
    // breakpoint, is what gives the Fold 8 two answers at one width.
    const cases = <(double, double, bool, String)>[
      (360, 882, false, 'Z Fold 7 / 8 Ultra cover'),
      (412, 915, false, 'ordinary phone'),
      (356, 819, false, 'Z Fold 8 cover, high density'),
      (416, 958, false, 'Z Fold 8 cover, low density'),
      (splitMinWidth - 1, 600, false, 'just under the width floor'),
      (splitMinWidth, 600, true, 'at the width floor'),
      (657, 416, false, 'Z Fold 8 cover in landscape'),
      (915, 412, false, 'phone in landscape: compact height'),
      (900, splitMinHeight - 1, false, 'just under the height floor'),
      (900, splitMinHeight, true, 'at the height floor'),
      (704, 932, false, 'Z Fold 8 unfolded portrait, 0.755'),
      (932, 704, true, 'Z Fold 8 unfolded landscape, 1.32'),
      (675, 810, true, 'Z Fold 5 portrait, 0.83'),
      (690, 802, true, 'Z Fold 6 portrait, 0.86'),
      (733, 814, true, 'Z Fold 7 portrait, 0.90'),
      (839, 932, true, 'Z Fold 8 Ultra portrait, 0.90'),
      (773, 805, true, 'Pixel 10 Pro Fold, 0.96'),
      (768, 1024, false, '4:3 tablet portrait: the rule working'),
      (1024, 768, true, '4:3 tablet landscape'),
      (800, 1280, false, '16:10 tablet portrait'),
      (1280, 800, true, '16:10 tablet landscape'),
      (0, 0, false, 'degenerate'),
      (1200, 0, false, 'degenerate height'),
      (1200, -1, false, 'negative height'),
      (1440, 900, true, 'desktop'),
      (1920, 1080, true, 'desktop'),
    ];
    for (final (width, height, splits, device) in cases) {
      expect(canSplitLayout(width, height), splits, reason: device);
    }
  });

  test('thresholds hold at n - 1 and n', () {
    const aspectHeight = 1000.0;
    const weightGate = 2 * weightPairedChartMinWidth + listTileGap; // 672
    const pieGate = pieChartMinWidth + pieLegendMinWidth + listTileGap; // 612
    const todoGate =
        calendarCardMinWidth + scoreTrendMinWidth + listTileGap; // 712
    final gates = <String, (bool Function(double), double)>{
      'split aspect': (
        (w) => canSplitLayout(w, aspectHeight),
        splitMinAspect * aspectHeight,
      ),
      'navigation rail': (useNavigationRail, navRailMinWidth),
      'weight charts side by side': (useWeightChartsSideBySide, weightGate),
      'pie chart side by side': (usePieChartSideBySide, pieGate),
      'todo calendar side by side': (useTodoCalendarSideBySide, todoGate),
    };
    gates.forEach((name, gate) {
      final (passes, n) = gate;
      expect(passes(n - 1), isFalse, reason: '$name at n - 1');
      expect(passes(n), isTrue, reason: '$name at n');
    });
  });

  test('useNavigationRail is width only', () {
    // A phone in landscape fails the split rule yet gets a rail: a bottom bar
    // would spend 19% of 412 dp on navigation.
    expect(canSplitLayout(915, 412), isFalse);
    const cases = <(double, bool, String)>[
      (915, true, 'phone landscape'),
      (360, false, 'Fold 7 / 8 Ultra cover'),
      (416, false, 'Fold 8 cover, low density'),
      (411, false, 'Pixel 10 Pro Fold cover'),
      (659, true, 'unfolded panel'),
      (675, true, 'unfolded panel'),
      (672, true, 'unfolded panel'),
      (716, true, 'unfolded panel'),
      (755, true, 'unfolded panel'),
      (820, true, 'unfolded panel'),
    ];
    for (final (width, rail, device) in cases) {
      expect(useNavigationRail(width), rail, reason: '$device $width');
    }
  });

  test(
    'shellContentWidth subtracts the rail only when shown, never below 0',
    () {
      const cases = <(double, double)>[
        (412, 412), // phone portrait, bottom bar
        (599, 599),
        (600, 600 - navRailWidth),
        (704, 704 - navRailWidth), // Fold 8 portrait
        (1440, 1440 - navRailWidth),
        (0, 0),
        (-100, 0),
      ];
      for (final (width, expected) in cases) {
        expect(shellContentWidth(width), expected, reason: 'width $width');
      }
    },
  );

  test('columnCapacity pays for gaps, respects the ceiling, and degrades', () {
    // (width, minItemWidth, maxColumns, expected). Two 320 columns and one 12
    // gap need 652, not 664.
    const cases = <(double, double, int?, int)>[
      (651, 320, null, 1),
      (652, 320, null, 2),
      (983, 320, null, 2),
      (984, 320, null, 3),
      (4000, 320, null, listMaxColumns),
      (4000, 320, 2, 2),
      (4000, 320, 0, 1),
      (0, 320, null, 1),
      (-1, 320, null, 1),
      (800, 0, null, listMaxColumns),
      // A folded cover screen never fits two columns of any real minimum.
      (360, 300, null, 1),
      (416, 300, null, 1),
      (360, 340, null, 1),
      (416, 340, null, 1),
    ];
    for (final (width, min, max, expected) in cases) {
      final actual = max == null
          ? columnCapacity(width, minItemWidth: min)
          : columnCapacity(width, minItemWidth: min, maxColumns: max);
      expect(actual, expected, reason: '$width / $min / $max');
    }
  });

  test('listRowCount rounds up and treats nonsense columns as one', () {
    const cases = <(int, int, int)>[
      (0, 3, 0),
      (1, 3, 1),
      (3, 3, 1),
      (4, 3, 2),
      (7, 2, 4),
      (5, 0, 5),
      (5, -2, 5),
    ];
    for (final (items, columns, rows) in cases) {
      expect(listRowCount(items, columns), rows, reason: '$items/$columns');
    }
  });

  test('listColumnCount: gate beats capacity, preferences are clamped', () {
    int columns(double width, double height, int preference) => listColumnCount(
      screenWidth: width,
      screenHeight: height,
      contentWidth: shellContentWidth(width),
      minItemWidth: 320,
      preference: preference,
      maxColumns: 3,
    );
    // A tablet in portrait is wide enough for two columns but fails the shape
    // rule, so it stays on one — same as the Fold 8 in portrait.
    expect(columnCapacity(shellContentWidth(768), minItemWidth: 320), 2);
    const cases = <(double, double, int, int, String)>[
      (768, 1024, listColumnsAuto, 1, 'tablet portrait: gated'),
      (1024, 768, listColumnsAuto, 2, 'tablet landscape'),
      (412, 915, listColumnsAuto, 1, 'phone portrait'),
      (704, 932, listColumnsAuto, 1, 'Fold 8 portrait: gated'),
      (932, 704, listColumnsAuto, 2, 'Fold 8 landscape'),
      (1440, 900, listColumnsAuto, 3, 'desktop, at the ceiling'),
      (1440, 900, 3, 3, 'pinned 3 on desktop'),
      (412, 915, 3, 1, 'pinned 3 carried onto a phone'),
      (932, 704, 3, 2, 'pinned 3 on a Fold 8 landscape'),
      (1440, 900, -5, 1, 'a preference below one'),
    ];
    for (final (width, height, preference, expected, label) in cases) {
      expect(columns(width, height, preference), expected, reason: label);
    }
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
          expect(
            flat,
            List.generate(items, (i) => i),
            reason: '$items/$columns',
          );
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
  });

  group('useWeightChartsSideBySide', () {
    test('a Z Fold 5 in portrait passes the split rule but not this one', () {
      // The split rule alone would leave each chart under 290 logical pixels.
      // This is why the page tests both, rather than the shape rule alone.
      expect(canSplitLayout(675, 810), isTrue);
      expect(useWeightChartsSideBySide(shellContentWidth(675) - 32), isFalse);
    });

    test('an unfolded Fold 8 in landscape passes both', () {
      expect(canSplitLayout(932, 704), isTrue);
      expect(useWeightChartsSideBySide(shellContentWidth(932) - 32), isTrue);
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
    test('leaves a narrow page as it was and caps a wide one', () {
      // Width only and no gate, so this can never change what a phone renders.
      expect(cappedContentWidth(412, formMaxContentWidth), 412);
      expect(cappedContentWidth(704, formMaxContentWidth), 704);
      expect(cappedContentWidth(720, formMaxContentWidth), 720);
      expect(cappedContentWidth(721, formMaxContentWidth), formMaxContentWidth);
      expect(cappedContentWidth(1440, formMaxContentWidth), 720);
      expect(cappedContentWidth(1440, readingMaxContentWidth), 840);
    });
  });

  group('usePieChartSideBySide', () {
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
    test('a phone keeps the default inset; a wide window centres it', () {
      expect(dialogHorizontalInset(412), dialogMinHorizontalInset);
      expect(dialogHorizontalInset(704), dialogMinHorizontalInset);
      // 640 content plus 40 on each side is where the default stops binding.
      expect(dialogHorizontalInset(720), dialogMinHorizontalInset);
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

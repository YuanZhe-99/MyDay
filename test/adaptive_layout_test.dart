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
}

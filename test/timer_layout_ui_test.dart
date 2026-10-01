import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/intimacy/models/intimacy_record.dart';
import 'package:my_day/features/intimacy/widgets/timer_page.dart';

import 'layout_test_helpers.dart';

/// Purpose: Build `count` timer history entries a minute apart.
/// Inputs: `count`.
/// Returns: `List<TimerHistoryEntry>`.
/// Side effects: None.
/// Notes: Dated in the future relative to retention so none are pruned.
List<TimerHistoryEntry> _history(int count) => [
  for (var i = 0; i < count; i++)
    TimerHistoryEntry(
      start: DateTime.now().subtract(Duration(minutes: i + 1)),
      duration: Duration(minutes: 5, seconds: i + 1),
      thrustCount: 3,
    ),
];

/// Purpose: Run the timer page layout and counter tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates and deletes temp app directories.
/// Notes: Own file per `layout_test_helpers.dart`; Chinese locale so the
/// test font measures like production.
void main() {
  IntimacyTimerSession? lastSession;

  /// Purpose: Pump the timer page at `size` with `history`.
  /// Inputs: `tester`, `size`, `history`, optional `session`.
  /// Returns: `Future<void>`.
  /// Side effects: Seeds a temp app dir; renders the page.
  /// Notes: Records the latest persisted session in `lastSession`.
  Future<void> pumpTimer(
    WidgetTester tester,
    Size size,
    List<TimerHistoryEntry> history, {
    IntimacyTimerSession? session,
  }) async {
    final dir = await seedAppDir(tester, const {});
    addTearDown(() => tester.runAsync(() => deleteQuietly(dir)));
    lastSession = null;
    await pumpAdaptivePage(
      tester,
      TimerPage(
        partners: const [],
        toys: const [],
        timerHistory: history,
        timerSession: session,
        onStateChanged:
            ({
              required history,
              required session,
              required historyChanged,
              required timerSessionChanged,
              required retentionDays,
              required retentionChanged,
            }) async {
              if (timerSessionChanged) lastSession = session;
            },
      ),
      size,
    );
  }

  /// Purpose: Assert a finder's centre lies inside the viewport.
  /// Inputs: `tester`, `finder`, `size`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: None.
  void expectOnScreen(WidgetTester tester, Finder finder, Size size) {
    final centre = tester.getCenter(finder);
    expect(centre.dx, inInclusiveRange(0, size.width));
    expect(centre.dy, inInclusiveRange(0, size.height));
  }

  group('stacked layout', () {
    for (final size in const [Size(360, 748), Size(412, 915)]) {
      testWidgets('a long history never squeezes the controls at $size', (
        tester,
      ) async {
        await pumpTimer(tester, size, _history(30));

        expect(tester.takeException(), isNull);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(VerticalDivider), findsNothing);
        expectOnScreen(tester, find.text('00:00:00'), size);
        expectOnScreen(tester, find.text('开始'), size);

        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -3000),
        );
        await tester.pump();
        expect(find.byIcon(Icons.restore), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a narrow screen uses the compact digits', (tester) async {
      await pumpTimer(tester, const Size(360, 748), const []);
      final context = tester.element(find.text('00:00:00'));
      final style = tester.widget<Text>(find.text('00:00:00')).style!;
      expect(
        style.fontSize,
        Theme.of(context).textTheme.displayMedium!.fontSize,
      );
    });

    testWidgets('a regular phone keeps the large digits', (tester) async {
      await pumpTimer(tester, const Size(412, 915), const []);
      final context = tester.element(find.text('00:00:00'));
      final style = tester.widget<Text>(find.text('00:00:00')).style!;
      expect(
        style.fontSize,
        Theme.of(context).textTheme.displayLarge!.fontSize,
      );
    });
  });

  testWidgets('a desktop window keeps the history in its own pane', (
    tester,
  ) async {
    await pumpTimer(tester, const Size(1440, 900), _history(30));
    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('thrust counter', () {
    /// Purpose: Pump a paused session so the counter buttons are shown.
    /// Inputs: `tester`.
    /// Returns: `Future<void>`.
    /// Side effects: Renders the page.
    /// Notes: Paused, so no ticker keeps the test from settling.
    Future<void> pumpPaused(WidgetTester tester) => pumpTimer(
      tester,
      const Size(412, 915),
      const [],
      session: IntimacyTimerSession(
        firstStartedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        accumulated: const Duration(minutes: 5),
        running: false,
      ),
    );

    /// Purpose: Tap a counter button by its label.
    /// Inputs: `tester`, `label`.
    /// Returns: `Future<void>`.
    /// Side effects: Changes the count.
    /// Notes: None.
    Future<void> tapCount(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    testWidgets('-100 undoes presses and splits the last one it reaches', (
      tester,
    ) async {
      await pumpPaused(tester);
      await tapCount(tester, '+50');
      await tapCount(tester, '+10');
      await tapCount(tester, '+50');
      expect(find.text('抽插: 110 x1'), findsOneWidget);
      await tapCount(tester, '-100');
      expect(find.text('抽插: 10 x1'), findsOneWidget);
      final timeline = lastSession!.thrustTimeline!;
      expect(timeline.total, 10);
      expect(timeline.events, hasLength(1));
      expect(lastSession!.thrustCount, 10);
      expect(lastSession!.thrustCountUnit, 1);
    });

    testWidgets('-100 after two +100 leaves one hundred', (tester) async {
      await pumpPaused(tester);
      await tapCount(tester, '+100');
      await tapCount(tester, '+100');
      await tapCount(tester, '-100');
      expect(find.text('抽插: 1 x100'), findsOneWidget);
      expect(lastSession!.thrustTimeline!.events, hasLength(1));
    });

    testWidgets('presses are stamped with the stopwatch time', (tester) async {
      await pumpPaused(tester);
      await tapCount(tester, '+10');
      final event = lastSession!.thrustTimeline!.events.single;
      expect(event.elapsedMs, const Duration(minutes: 5).inMilliseconds);
    });

    testWidgets('a session saved before v1.5.5 restores its count', (
      tester,
    ) async {
      await pumpTimer(
        tester,
        const Size(412, 915),
        const [],
        session: IntimacyTimerSession(
          firstStartedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          accumulated: const Duration(minutes: 5),
          running: false,
          thrustCount: 3,
          thrustCountUnit: 100,
        ),
      );
      expect(find.text('抽插: 3 x100'), findsOneWidget);
      await tapCount(tester, '-100');
      expect(find.text('抽插: 2 x100'), findsOneWidget);
    });
  });
}

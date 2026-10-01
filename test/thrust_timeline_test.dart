import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/intimacy/utils/thrust_timeline.dart';

/// Purpose: Build a timeline from `(elapsedMs, delta)` pairs.
/// Inputs: `pairs`.
/// Returns: `ThrustTimeline`.
/// Side effects: None.
/// Notes: Test helper only.
ThrustTimeline _tl(List<List<int>> pairs) =>
    ThrustTimeline([for (final p in pairs) ThrustEvent(p[0], p[1])]);

/// Purpose: Run the thrust timeline unit tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Covers press recording, the exact-100 undo with splitting, JSON
/// tolerance, and the non-decreasing guarantee of both chart series.
void main() {
  group('add', () {
    test('appends presses and totals them', () {
      final t = ThrustTimeline.empty().add(1000, 100).add(2000, 50);
      expect(t.events, [
        const ThrustEvent(1000, 100),
        const ThrustEvent(2000, 50),
      ]);
      expect(t.total, 150);
    });

    test('keeps time order when the stopwatch reads earlier', () {
      final t = ThrustTimeline.empty().add(5000, 10).add(3000, 10);
      expect(t.events.last.elapsedMs, 5000);
    });

    test('ignores non-positive deltas and presses past the maximum', () {
      final t = ThrustTimeline.empty().add(0, 0);
      expect(t.isEmpty, isTrue);
      final full = ThrustTimeline.seed(0, ThrustTimeline.maxTotal);
      expect(identical(full.add(1, 10), full), isTrue);
    });
  });

  group('undo', () {
    test('removes one exact +100', () {
      expect(
        _tl([
          [1, 100],
        ]).undo(100).isEmpty,
        isTrue,
      );
    });

    test('splits the last press it reaches to remove exactly 100', () {
      final t = _tl([
        [1, 50],
        [2, 10],
        [3, 50],
      ]).undo(100);
      expect(t.events, [const ThrustEvent(1, 10)]);
      expect(t.total, 10);
    });

    test('pops several small presses', () {
      final t = _tl([
        [1, 100],
        [2, 50],
        [3, 50],
      ]).undo(100);
      expect(t.events, [const ThrustEvent(1, 100)]);
    });

    test('trims a large press without touching earlier ones', () {
      final t = _tl([
        [1, 10],
        [2, 150],
      ]).undo(100);
      expect(t.events, [const ThrustEvent(1, 10), const ThrustEvent(2, 50)]);
    });

    test('clears everything when the total is below the amount', () {
      expect(
        _tl([
          [1, 50],
          [2, 10],
        ]).undo(100).total,
        0,
      );
    });

    test('is a no-op on an empty timeline', () {
      final empty = ThrustTimeline.empty();
      expect(identical(empty.undo(100), empty), isTrue);
    });

    test('matches a clamped counter over random sequences', () {
      final random = Random(7);
      for (var run = 0; run < 200; run++) {
        var t = ThrustTimeline.empty();
        var counter = 0;
        var clock = 0;
        for (var step = 0; step < 40; step++) {
          clock += random.nextInt(5000);
          final choice = random.nextInt(4);
          if (choice == 0) {
            t = t.undo(100);
            counter = max(0, counter - 100);
          } else {
            final delta = const [100, 50, 10][choice - 1];
            t = t.add(clock, delta);
            counter += delta;
          }
          expect(t.total, counter);
          expect(t.events.every((e) => e.delta > 0), isTrue);
          for (var i = 1; i < t.events.length; i++) {
            expect(
              t.events[i].elapsedMs,
              greaterThanOrEqualTo(t.events[i - 1].elapsedMs),
            );
          }
        }
      }
    });
  });

  group('json', () {
    test('round-trips', () {
      final t = _tl([
        [61200, 100],
        [184900, 100],
        [301000, 50],
      ]);
      expect(t.toJson(), [
        [61200, 100],
        [184900, 100],
        [301000, 50],
      ]);
      expect(ThrustTimeline.fromJson(t.toJson())!.events, t.events);
    });

    test('returns null for absent, malformed or empty input', () {
      expect(ThrustTimeline.fromJson(null), isNull);
      expect(ThrustTimeline.fromJson('x'), isNull);
      expect(ThrustTimeline.fromJson(<Object>[]), isNull);
      expect(
        ThrustTimeline.fromJson([
          [1],
        ]),
        isNull,
      );
    });

    test('skips bad pairs and sorts the rest', () {
      final t = ThrustTimeline.fromJson([
        [3000, 10],
        [-1, 10],
        [2000, 0],
        ['a', 10],
        [1000, 50.0],
      ])!;
      expect(t.events, [
        const ThrustEvent(1000, 50),
        const ThrustEvent(3000, 10),
      ]);
    });

    test('seed builds one event, or nothing for zero', () {
      expect(ThrustTimeline.seed(5000, 300).events, [
        const ThrustEvent(5000, 300),
      ]);
      expect(ThrustTimeline.seed(5000, 0).isEmpty, isTrue);
    });
  });

  group('chart series', () {
    test('cumulative spots start at zero and end at the duration', () {
      final spots = _tl([
        [60000, 100],
        [120000, 50],
      ]).cumulativeSpots(durationMs: 180000);
      expect(spots.first.x, 0);
      expect(spots.first.y, 0);
      expect(spots[1].x, 1.0);
      expect(spots[1].y, 100);
      expect(spots.last.x, 3.0);
      expect(spots.last.y, 150);
    });

    test('smoothed spots are empty with fewer than two presses', () {
      expect(
        _tl([
          [1000, 100],
        ]).smoothedSpots(durationMs: 60000),
        isEmpty,
      );
    });

    test('smoothed spots are pinned and never decrease', () {
      final random = Random(1);
      for (var run = 0; run < 200; run++) {
        var t = ThrustTimeline.empty();
        var clock = 0;
        final presses = 2 + random.nextInt(30);
        for (var i = 0; i < presses; i++) {
          clock += random.nextInt(60000);
          t = t.add(clock, const [100, 50, 10][random.nextInt(3)]);
        }
        final duration = clock + random.nextInt(120000);
        final spots = t.smoothedSpots(durationMs: duration);
        expect(spots, hasLength(60));
        expect(spots.first.y, 0);
        expect(spots.last.y, t.total.toDouble());
        for (var i = 1; i < spots.length; i++) {
          expect(spots[i].y, greaterThanOrEqualTo(spots[i - 1].y - 1e-9));
          expect(spots[i].x, greaterThan(spots[i - 1].x));
        }
      }
    });
  });
}

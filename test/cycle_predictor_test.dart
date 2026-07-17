import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/intimacy/services/cycle_predictor.dart';

void main() {
  final windowStart = DateTime(2026, 1, 1);
  final windowEnd = DateTime(2026, 12, 31);

  CyclePrediction predict(Iterable<DateTime> starts) => predictCycle(
    actualStarts: starts,
    windowStart: windowStart,
    windowEnd: windowEnd,
  );

  group('cycle length estimation', () {
    test('no records yields the empty prediction', () {
      final result = predict(const []);
      expect(result.predictedStarts, isEmpty);
      expect(result.days, isEmpty);
    });

    test('single record uses the 28-day default', () {
      final result = predict([DateTime(2026, 3, 1)]);
      expect(result.cycleLengthDays, defaultCycleLengthDays);
      expect(result.predictedStarts.first, DateTime(2026, 3, 29));
    });

    test('median resists a single abnormal cycle', () {
      // Cycles: 28, 28, 60 (abnormal but valid) -> median 28.
      final result = predict([
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 29),
        DateTime(2026, 2, 26),
        DateTime(2026, 4, 27), // 60-day cycle
      ]);
      expect(result.cycleLengthDays, 28);
      expect(result.predictedStarts.first, DateTime(2026, 5, 25));
    });

    test('cycles outside 15-90 days are ignored', () {
      // 10-day and 200-day diffs are invalid; only the 30-day cycle counts.
      final starts = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 11), // 10 days: invalid
        DateTime(2025, 2, 10), // 30 days: valid
        DateTime(2025, 8, 29), // 200 days: invalid
      ];
      expect(estimateCycleLength(starts), 30);
    });

    test('only the most recent six valid cycles feed the median', () {
      // Eight 30-day cycles followed by six 26-day cycles: the window
      // holds only 26-day cycles, so the median must be 26.
      final starts = <DateTime>[DateTime(2024, 1, 1)];
      for (var i = 0; i < 8; i++) {
        starts.add(starts.last.add(const Duration(days: 30)));
      }
      for (var i = 0; i < 6; i++) {
        starts.add(starts.last.add(const Duration(days: 26)));
      }
      expect(estimateCycleLength(starts), 26);
    });

    test('even count averages the middle pair', () {
      expect(
        estimateCycleLength([
          DateTime(2026, 1, 1),
          DateTime(2026, 1, 29), // 28
          DateTime(2026, 2, 28), // 30
        ]),
        29,
      );
    });
  });

  group('anchoring', () {
    test('adding a new actual start re-anchors predictions', () {
      final before = predict([DateTime(2026, 2, 1), DateTime(2026, 3, 1)]);
      // 28-day cycle predicted from Mar 1.
      expect(before.predictedStarts.first, DateTime(2026, 3, 29));

      // Actual period arrived late on Apr 2: predictions must restart from
      // Apr 2, not shift the old chain by the offset.
      final after = predict([
        DateTime(2026, 2, 1),
        DateTime(2026, 3, 1),
        DateTime(2026, 4, 2), // 32-day cycle
      ]);
      final expectedLength = after.cycleLengthDays;
      expect(
        after.predictedStarts.first,
        DateTime(2026, 4, 2).add(Duration(days: expectedLength)),
      );
    });

    test('deleting the anchor recomputes from the remaining records', () {
      final result = predict([DateTime(2026, 2, 1), DateTime(2026, 3, 1)]);
      final afterDelete = predict([DateTime(2026, 2, 1)]);
      expect(result.predictedStarts.first, DateTime(2026, 3, 29));
      expect(afterDelete.predictedStarts.first, DateTime(2026, 3, 1));
    });

    test('duplicate dates are deduplicated', () {
      final result = predict([
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 29),
      ]);
      expect(result.cycleLengthDays, 28);
    });
  });

  group('phase derivation', () {
    test('menstrual phase covers five days from the start', () {
      final result = predict([DateTime(2026, 3, 1), DateTime(2026, 3, 29)]);
      for (var day = 1; day <= 5; day++) {
        expect(
          result.days[DateTime(2026, 3, day)]!.phase,
          CyclePhase.menstrual,
        );
      }
      expect(
        result.days[DateTime(2026, 3, 6)]!.phase,
        isNot(CyclePhase.menstrual),
      );
    });

    test('ovulation is 14 days before the next start', () {
      final result = predict([DateTime(2026, 3, 1), DateTime(2026, 3, 29)]);
      final ovulationDay = DateTime(2026, 3, 15); // Mar 29 - 14
      expect(result.days[ovulationDay]!.isOvulationDay, isTrue);
      expect(result.days[ovulationDay]!.phase, CyclePhase.follicular);
    });

    test('fertile window spans ovulation-5 through ovulation+1', () {
      final result = predict([DateTime(2026, 3, 1), DateTime(2026, 3, 29)]);
      expect(result.days[DateTime(2026, 3, 9)]!.inFertileWindow, isFalse);
      for (var day = 10; day <= 16; day++) {
        expect(
          result.days[DateTime(2026, 3, day)]!.inFertileWindow,
          isTrue,
          reason: 'Mar $day should be fertile',
        );
      }
      expect(result.days[DateTime(2026, 3, 17)]!.inFertileWindow, isFalse);
    });

    test('luteal phase runs after ovulation until the next start', () {
      final result = predict([DateTime(2026, 3, 1), DateTime(2026, 3, 29)]);
      expect(result.days[DateTime(2026, 3, 16)]!.phase, CyclePhase.luteal);
      expect(result.days[DateTime(2026, 3, 28)]!.phase, CyclePhase.luteal);
      // The next start day begins the next segment.
      expect(result.days[DateTime(2026, 3, 29)]!.phase, CyclePhase.menstrual);
    });

    test('actual and predicted starts are flagged distinctly', () {
      final result = predict([DateTime(2026, 3, 1)]);
      final actual = result.days[DateTime(2026, 3, 1)]!;
      expect(actual.isActualStart, isTrue);
      expect(actual.isPredictedStart, isFalse);
      expect(actual.isEstimated, isFalse);
      final predicted = result.days[DateTime(2026, 3, 29)]!;
      expect(predicted.isActualStart, isFalse);
      expect(predicted.isPredictedStart, isTrue);
      expect(predicted.isEstimated, isTrue);
    });

    test('gaps longer than a valid cycle only classify menses', () {
      final result = predict([DateTime(2026, 1, 1), DateTime(2026, 6, 1)]);
      // Jan 1-5 menstrual, then nothing until the June segment.
      expect(result.days[DateTime(2026, 1, 5)]!.phase, CyclePhase.menstrual);
      expect(result.days.containsKey(DateTime(2026, 2, 15)), isFalse);
      expect(result.days[DateTime(2026, 6, 1)]!.isActualStart, isTrue);
    });

    test('historical segments between actual starts are classified', () {
      final result = predict([
        DateTime(2026, 2, 1),
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 29),
      ]);
      // Feb 15 = Mar 1 - 14 -> ovulation of the historical segment.
      expect(result.days[DateTime(2026, 2, 15)]!.isOvulationDay, isTrue);
    });
  });
}

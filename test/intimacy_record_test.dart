import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/intimacy/models/intimacy_record.dart';
import 'package:my_day/features/intimacy/utils/thrust_timeline.dart';

/// Purpose: Verify intimacy record serialization behavior.
/// Inputs: None.
/// Returns: None.
/// Side effects: Runs test assertions.
/// Notes: Keeps intimacy record and timer persistence covered.
void main() {
  test('round-trips optional thrust count and unit', () {
    final record = IntimacyRecord(
      type: 'Regular',
      pleasureLevel: 4,
      duration: const Duration(minutes: 30),
      thrustCount: 250,
      thrustCountUnit: 1,
      datetime: DateTime(2026, 5, 23, 20),
    );

    final json = record.toJson();
    final restored = IntimacyRecord.fromJson(json);

    expect(json['thrustCount'], 250);
    expect(json['thrustCountUnit'], 1);
    expect(restored.thrustCount, 250);
    expect(restored.thrustCountUnit, 1);
  });

  test('omits missing thrust count and defaults unit to x100', () {
    final record = IntimacyRecord(
      type: 'Solo',
      isSolo: true,
      pleasureLevel: 3,
      duration: const Duration(minutes: 15),
      datetime: DateTime(2026, 5, 23, 21),
    );

    final json = record.toJson();
    final restored = IntimacyRecord.fromJson(json);

    expect(json.containsKey('thrustCount'), isFalse);
    expect(json.containsKey('thrustCountUnit'), isFalse);
    expect(restored.thrustCount, isNull);
    expect(restored.thrustCountUnit, 100);
    expect(restored.usedCondom, isFalse);
  });

  test('round-trips condom flag', () {
    final record = IntimacyRecord(
      type: 'Regular',
      pleasureLevel: 4,
      duration: const Duration(minutes: 30),
      datetime: DateTime(2026, 5, 23, 22),
      usedCondom: true,
    );

    final json = record.toJson();
    final restored = IntimacyRecord.fromJson(json);

    expect(json['usedCondom'], isTrue);
    expect(restored.usedCondom, isTrue);
  });

  test('computes toy total cost and average daily cost', () {
    final toy = Toy(
      name: 'Test toy',
      price: 100,
      purchaseDate: DateTime.utc(2026, 1),
      retiredDate: DateTime.utc(2026, 1, 10),
    );

    expect(toy.hasCostData, isTrue);
    expect(toy.totalCost(), 100);
    expect(toy.serviceDays(asOf: DateTime.utc(2026, 1, 5)), 5);
    expect(toy.averageDailyCost(asOf: DateTime.utc(2026, 1, 5)), 20);
    expect(toy.serviceDays(asOf: DateTime.utc(2026, 1, 20)), 10);
    expect(toy.averageDailyCost(asOf: DateTime.utc(2026, 1, 20)), 10);
  });

  test('omits toy average daily cost without purchase date', () {
    final toy = Toy(name: 'Undated toy', price: 12);

    expect(toy.hasCostData, isTrue);
    expect(toy.totalCost(), 12);
    expect(toy.serviceDays(asOf: DateTime.utc(2026, 1)), isNull);
    expect(toy.averageDailyCost(asOf: DateTime.utc(2026, 1)), isNull);
  });

  test('round-trips running timer session', () {
    final session = IntimacyTimerSession(
      firstStartedAt: DateTime.utc(2026, 5, 23, 20),
      startedAt: DateTime.utc(2026, 5, 23, 20, 10),
      accumulated: const Duration(minutes: 5),
      running: true,
      thrustCount: 4,
      thrustCountUnit: 100,
    );

    final json = session.toJson();
    final restored = IntimacyTimerSession.fromJson(json);

    expect(restored.firstStartedAt, DateTime.utc(2026, 5, 23, 20));
    expect(restored.startedAt, DateTime.utc(2026, 5, 23, 20, 10));
    expect(restored.accumulated, const Duration(minutes: 5));
    expect(restored.running, isTrue);
    expect(restored.thrustCount, 4);
    expect(restored.thrustCountUnit, 100);
  });

  test('round-trips timer history thrust count and clamps negatives', () {
    final start = DateTime.utc(2026, 5, 23, 20);
    final entry = TimerHistoryEntry(
      start: start,
      duration: const Duration(minutes: 12),
      thrustCount: 3,
      thrustCountUnit: 100,
    );
    final negativeEntry = TimerHistoryEntry(
      start: start,
      duration: const Duration(minutes: 12),
      thrustCount: -1,
    );
    final restoredNegativeSession = IntimacyTimerSession.fromJson({
      'firstStartedAt': start.toIso8601String(),
      'accumulatedMs': 0,
      'running': false,
      'thrustCount': -1,
    });

    final json = entry.toJson();
    final restored = TimerHistoryEntry.fromJson(json);

    expect(json['thrustCount'], 3);
    expect(json['thrustCountUnit'], 100);
    expect(restored.thrustCount, 3);
    expect(restored.thrustCountUnit, 100);
    expect(negativeEntry.thrustCount, 0);
    expect(negativeEntry.toJson().containsKey('thrustCount'), isFalse);
    expect(restoredNegativeSession.thrustCount, 0);
  });

  test('round-trips intimacy data timer session metadata', () {
    final session = IntimacyTimerSession(
      firstStartedAt: DateTime.utc(2026, 5, 23, 20),
      accumulated: const Duration(minutes: 15),
      running: false,
    );
    final modifiedAt = DateTime.utc(2026, 5, 23, 21);
    final data = IntimacyData(
      partners: const [],
      toys: const [],
      records: const [],
      timerSession: session,
      timerSessionModifiedAt: modifiedAt,
    );

    final json = data.toJson();
    final restored = IntimacyData.fromJson(json);

    expect(json['timerSession'], isA<Map<String, dynamic>>());
    expect(json['timerSessionModifiedAt'], modifiedAt.toIso8601String());
    expect(restored.timerSession?.firstStartedAt, session.firstStartedAt);
    expect(restored.timerSession?.accumulated, session.accumulated);
    expect(restored.timerSession?.running, isFalse);
    expect(restored.timerSessionModifiedAt, modifiedAt);
  });

  group('thrust rate', () {
    /// Purpose: Build a record with the given duration and thrust inputs.
    /// Inputs: `duration`, `thrustCount`, `thrustCountUnit`.
    /// Returns: `IntimacyRecord`.
    /// Side effects: None.
    /// Notes: Keeps the rate cases readable by hiding unrelated fields.
    IntimacyRecord record({
      required Duration duration,
      int? thrustCount,
      int? thrustCountUnit,
    }) => IntimacyRecord(
      type: 'Regular',
      pleasureLevel: 4,
      duration: duration,
      thrustCount: thrustCount,
      thrustCountUnit: thrustCountUnit,
      datetime: DateTime(2026, 5, 23, 20),
    );

    test('resolves the thrust count through the selected unit', () {
      expect(
        record(
          duration: const Duration(minutes: 15),
          thrustCount: 5,
          thrustCountUnit: 100,
        ).resolvedThrustCount,
        500,
      );
      expect(
        record(
          duration: const Duration(minutes: 15),
          thrustCount: 480,
          thrustCountUnit: 1,
        ).resolvedThrustCount,
        480,
      );
    });

    test('has no resolved count without a positive thrust count', () {
      expect(
        record(duration: const Duration(minutes: 15)).resolvedThrustCount,
        isNull,
      );
      expect(
        record(
          duration: const Duration(minutes: 15),
          thrustCount: 0,
          thrustCountUnit: 1,
        ).resolvedThrustCount,
        isNull,
      );
    });

    test('computes thrusts per minute from duration and thrust count', () {
      expect(
        record(
          duration: const Duration(minutes: 15),
          thrustCount: 480,
          thrustCountUnit: 1,
        ).thrustsPerMinute,
        480 / 15,
      );
      expect(
        record(
          duration: const Duration(minutes: 20),
          thrustCount: 5,
          thrustCountUnit: 100,
        ).thrustsPerMinute,
        25,
      );
      expect(
        record(
          duration: const Duration(seconds: 30),
          thrustCount: 60,
          thrustCountUnit: 1,
        ).thrustsPerMinute,
        120,
      );
    });

    test('has no thrust rate when either input is missing', () {
      expect(
        record(duration: const Duration(minutes: 15)).thrustsPerMinute,
        isNull,
      );
      expect(
        record(
          duration: Duration.zero,
          thrustCount: 480,
          thrustCountUnit: 1,
        ).thrustsPerMinute,
        isNull,
      );
    });
  });

  group('chart settings', () {
    test('omits chart settings until the user changes them', () {
      final json = IntimacyData(
        partners: const [],
        toys: const [],
        records: const [],
      ).toJson();

      expect(json.containsKey('chartSettings'), isFalse);
      expect(IntimacyData.fromJson(json).chartSettings, isNull);
    });

    test('round-trips the metric selection and range', () {
      final data = IntimacyData(
        partners: const [],
        toys: const [],
        records: const [],
        chartSettings: const IntimacyChartSettings(
          metrics: ['pleasure', 'frequency'],
          range: '1y',
        ),
      );

      final restored = IntimacyData.fromJson(data.toJson());

      expect(restored.chartSettings?.metrics, ['pleasure', 'frequency']);
      expect(restored.chartSettings?.range, '1y');
    });

    test('preserves metric ids it does not recognize', () {
      final data = IntimacyData(
        partners: const [],
        toys: const [],
        records: const [],
        chartSettings: const IntimacyChartSettings(
          metrics: ['pleasure', 'somethingFromANewerBuild'],
          range: 'someFutureRange',
        ),
      );

      final restored = IntimacyData.fromJson(data.toJson());

      expect(restored.chartSettings?.metrics, [
        'pleasure',
        'somethingFromANewerBuild',
      ]);
      expect(restored.chartSettings?.range, 'someFutureRange');
    });

    test('falls back to the defaults for missing or empty values', () {
      expect(
        IntimacyChartSettings.fromJson(null).metrics,
        IntimacyChartSettings.defaultMetrics,
      );
      expect(
        IntimacyChartSettings.fromJson(const {'metrics': <String>[]}).metrics,
        IntimacyChartSettings.defaultMetrics,
      );
      expect(
        IntimacyChartSettings.fromJson(const {}).range,
        IntimacyChartSettings.defaultRange,
      );
    });
  });

  group('thrust timeline', () {
    final timeline = ThrustTimeline([
      const ThrustEvent(60000, 100),
      const ThrustEvent(120000, 50),
    ]);

    test('round-trips on a record and gates the chart at two presses', () {
      final record = IntimacyRecord(
        id: 'r1',
        type: 'Regular',
        pleasureLevel: 4,
        duration: const Duration(minutes: 3, seconds: 10),
        thrustCount: 150,
        thrustCountUnit: 1,
        thrustTimeline: timeline,
        datetime: DateTime(2026, 9, 1, 22),
      );
      final json = record.toJson();
      expect(json['thrustTimeline'], [
        [60000, 100],
        [120000, 50],
      ]);
      final restored = IntimacyRecord.fromJson(json);
      expect(restored.thrustTimeline!.events, timeline.events);
      expect(restored.duration.inSeconds, 190);
      expect(restored.hasThrustTimeline, isTrue);
      final single = IntimacyRecord(
        type: 'Regular',
        pleasureLevel: 3,
        duration: const Duration(minutes: 1),
        thrustTimeline: ThrustTimeline.seed(1000, 100),
      );
      expect(single.hasThrustTimeline, isFalse);
    });

    test('a timeline whose total disagrees with the count draws no chart', () {
      // What a pre-1.5.5 build leaves when it edits the count but carries the
      // unknown timeline key forward.
      final stale = IntimacyRecord.fromJson({
        ...IntimacyRecord(
          type: 'Regular',
          pleasureLevel: 3,
          duration: const Duration(minutes: 3),
          thrustCount: 150,
          thrustCountUnit: 1,
          thrustTimeline: timeline,
        ).toJson(),
        'thrustCount': 3,
        'thrustCountUnit': 100,
      });
      expect(stale.thrustTimeline, isNotNull);
      expect(stale.hasThrustTimeline, isFalse);
    });

    test('omits the key when empty or absent, and reads old JSON', () {
      final record = IntimacyRecord(
        type: 'Solo',
        pleasureLevel: 3,
        duration: const Duration(minutes: 5),
        thrustTimeline: ThrustTimeline.empty(),
      );
      expect(record.thrustTimeline, isNull);
      expect(record.toJson().containsKey('thrustTimeline'), isFalse);
      final legacy = record.toJson()..remove('thrustTimeline');
      expect(IntimacyRecord.fromJson(legacy).thrustTimeline, isNull);
    });

    test('a malformed timeline does not make the record unreadable', () {
      final json = IntimacyRecord(
        type: 'Solo',
        pleasureLevel: 3,
        duration: const Duration(minutes: 5),
      ).toJson()..['thrustTimeline'] = 'garbage';
      expect(IntimacyRecord.fromJson(json).thrustTimeline, isNull);
    });

    test('round-trips on timer history entries and sessions', () {
      final entry = TimerHistoryEntry(
        start: DateTime(2026, 9, 1, 22),
        duration: const Duration(minutes: 3),
        thrustCount: 150,
        thrustCountUnit: 1,
        thrustTimeline: timeline,
      );
      expect(
        TimerHistoryEntry.fromJson(entry.toJson()).thrustTimeline!.events,
        timeline.events,
      );
      final legacyEnd = {
        'start': '2026-09-01T22:00:00.000',
        'end': '2026-09-01T22:03:00.000',
        'thrustTimeline': timeline.toJson(),
      };
      expect(TimerHistoryEntry.fromJson(legacyEnd).thrustTimeline!.total, 150);

      final session = IntimacyTimerSession(
        firstStartedAt: DateTime(2026, 9, 1, 22),
        accumulated: const Duration(minutes: 3),
        running: false,
        thrustCount: 150,
        thrustCountUnit: 1,
        thrustTimeline: timeline,
      );
      expect(
        IntimacyTimerSession.fromJson(session.toJson()).thrustTimeline!.events,
        timeline.events,
      );
      expect(
        IntimacyTimerSession(
          firstStartedAt: DateTime(2026, 9, 1, 22),
          accumulated: Duration.zero,
          running: false,
        ).toJson().containsKey('thrustTimeline'),
        isFalse,
      );
    });
  });
}

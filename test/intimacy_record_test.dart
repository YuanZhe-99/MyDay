import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/intimacy/models/intimacy_record.dart';

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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/weight/models/weight_record.dart';
import 'package:my_day/shared/services/reminder_service.dart';

/// Purpose: Build a weight record logged at [datetime] for grace-window tests.
/// Inputs: `datetime`.
/// Returns: `WeightRecord`.
/// Side effects: None.
/// Notes: Only the `datetime` field matters for the suppression decision.
WeightRecord recordAt(DateTime datetime) =>
    WeightRecord(weight: 60.0, datetime: datetime);

void main() {
  group('weight reminder grace window (anchored on actual fire time)', () {
    // Scenario from the bug report: reminder scheduled 08:00, user logs a
    // record at 08:30, desktop app is opened at 11:00. The check fires at
    // 11:00 with a 180-minute grace window, so the 08:30 record must
    // suppress the reminder.
    test('record logged after the scheduled minute suppresses a late check',
        () {
      final firesAt = DateTime(2026, 7, 15, 11, 0);
      final records = [recordAt(DateTime(2026, 7, 15, 8, 30))];
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: firesAt,
          records: records,
          graceMinutes: 180,
        ),
        isTrue,
      );
    });

    test('record inside the grace window before the fire time suppresses',
        () {
      final firesAt = DateTime(2026, 7, 15, 8, 0);
      final records = [recordAt(DateTime(2026, 7, 15, 6, 30))];
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: firesAt,
          records: records,
          graceMinutes: 180,
        ),
        isTrue,
      );
    });

    test('record at exactly fire time suppresses (window end is +1 minute)',
        () {
      final firesAt = DateTime(2026, 7, 15, 8, 0);
      final records = [recordAt(DateTime(2026, 7, 15, 8, 0))];
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: firesAt,
          records: records,
          graceMinutes: 180,
        ),
        isTrue,
      );
    });

    test('record older than the grace window does not suppress', () {
      final firesAt = DateTime(2026, 7, 15, 11, 0);
      final records = [recordAt(DateTime(2026, 7, 15, 7, 59))];
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: firesAt,
          records: records,
          graceMinutes: 180,
        ),
        isFalse,
      );
    });

    test('record after the fire minute does not suppress', () {
      final firesAt = DateTime(2026, 7, 15, 8, 0);
      final records = [recordAt(DateTime(2026, 7, 15, 9, 30))];
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: firesAt,
          records: records,
          graceMinutes: 180,
        ),
        isFalse,
      );
    });

    test('zero or negative grace disables suppression entirely', () {
      final firesAt = DateTime(2026, 7, 15, 8, 0);
      final records = [recordAt(DateTime(2026, 7, 15, 8, 0))];
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: firesAt,
          records: records,
          graceMinutes: 0,
        ),
        isFalse,
      );
    });

    test('no records never suppresses', () {
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: DateTime(2026, 7, 15, 8, 0),
          records: const [],
          graceMinutes: 180,
        ),
        isFalse,
      );
    });

    // Mobile pre-scheduling passes a future candidate fire time; a record
    // that already exists inside the candidate's grace window shifts the
    // repeat to start the next day.
    test('future candidate fire time counts records inside its window', () {
      final candidate = DateTime(2026, 7, 15, 20, 0);
      final records = [recordAt(DateTime(2026, 7, 15, 18, 45))];
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: candidate,
          records: records,
          graceMinutes: 180,
        ),
        isTrue,
      );
    });
  });
}

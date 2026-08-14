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
  group('weight reminder grace window (no scheduled anchor)', () {
    // Scenario from the bug report: reminder scheduled 08:00, user logs a
    // record at 08:30, desktop app is opened at 11:00. The check fires at
    // 11:00 with a 180-minute grace window, so the 08:30 record must
    // suppress the reminder.
    test(
      'record logged after the scheduled minute suppresses a late check',
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
      },
    );

    test('record inside the grace window before the fire time suppresses', () {
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

    test(
      'record at exactly fire time suppresses (window end is +1 minute)',
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
      },
    );

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

  // Desktop passes both ends: `scheduledAt` is the configured reminder minute
  // and `firesAt` the moment the 30-second loop actually evaluated it, so the
  // window is `[scheduledAt − grace, firesAt + 1 min)`.
  group('weight reminder grace window (anchored on the scheduled time)', () {
    // The reported bug: grace 3 h, reminder 08:00, weight logged at 06:00 —
    // two hours *before* the scheduled reminder — and the desktop app is not
    // opened until 13:00. Anchoring only on the check moment gave the window
    // [10:00, 13:01), which excluded the 06:00 record and fired anyway.
    test('record logged before the scheduled time suppresses a late check', () {
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: DateTime(2026, 7, 15, 13, 0),
          scheduledAt: DateTime(2026, 7, 15, 8, 0),
          records: [recordAt(DateTime(2026, 7, 15, 6, 0))],
          graceMinutes: 180,
        ),
        isTrue,
      );
    });

    test('record older than the grace window still does not suppress', () {
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: DateTime(2026, 7, 15, 13, 0),
          scheduledAt: DateTime(2026, 7, 15, 8, 0),
          records: [recordAt(DateTime(2026, 7, 15, 4, 30))],
          graceMinutes: 180,
        ),
        isFalse,
      );
    });

    test('window start is inclusive at scheduled minus grace', () {
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: DateTime(2026, 7, 15, 13, 0),
          scheduledAt: DateTime(2026, 7, 15, 8, 0),
          records: [recordAt(DateTime(2026, 7, 15, 5, 0))],
          graceMinutes: 180,
        ),
        isTrue,
      );
    });

    // v1.2.0 regression guard: the scheduled anchor must not lose the case it
    // was introduced for — a record logged after the reminder minute.
    test('record logged after the scheduled minute still suppresses', () {
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: DateTime(2026, 7, 15, 11, 0),
          scheduledAt: DateTime(2026, 7, 15, 8, 0),
          records: [recordAt(DateTime(2026, 7, 15, 8, 30))],
          graceMinutes: 180,
        ),
        isTrue,
      );
    });

    test('window runs all the way to the check moment', () {
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: DateTime(2026, 7, 15, 13, 0),
          scheduledAt: DateTime(2026, 7, 15, 8, 0),
          records: [recordAt(DateTime(2026, 7, 15, 12, 30))],
          graceMinutes: 180,
        ),
        isTrue,
      );
    });

    test('a scheduled time after the fire moment never widens the window', () {
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: DateTime(2026, 7, 15, 8, 0),
          scheduledAt: DateTime(2026, 7, 15, 20, 0),
          records: [recordAt(DateTime(2026, 7, 15, 19, 0))],
          graceMinutes: 180,
        ),
        isFalse,
      );
    });

    test('zero grace disables suppression even with a scheduled anchor', () {
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: DateTime(2026, 7, 15, 13, 0),
          scheduledAt: DateTime(2026, 7, 15, 8, 0),
          records: [recordAt(DateTime(2026, 7, 15, 8, 0))],
          graceMinutes: 0,
        ),
        isFalse,
      );
    });

    // The evening reminder must not inherit a morning weigh-in.
    test('a morning record does not suppress an evening reminder', () {
      expect(
        ReminderService.shouldSkipWeightReminderAt(
          firesAt: DateTime(2026, 7, 15, 21, 30),
          scheduledAt: DateTime(2026, 7, 15, 21, 0),
          records: [recordAt(DateTime(2026, 7, 15, 8, 0))],
          graceMinutes: 180,
        ),
        isFalse,
      );
    });
  });
}

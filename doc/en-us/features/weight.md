# Weight

Model source: `lib/features/weight/models/weight_record.dart`. Storage:
`lib/features/weight/services/weight_storage.dart`. Reminder grace logic:
`lib/shared/services/reminder_service.dart`. See
[Data Formats](../data-formats.md#weight--weight_datajson) for the full field list.

## Model

- **`WeightRecord`**: id, weight (kg), optional body fat percentage, optional bust/waist/hip
  circumference in cm, datetime, notes, `modifiedAt`.
- **`WeightData`**: optional height (cm), records, reminder mode (`'none'`, `'once'`, `'twice'`),
  morning/evening reminder times, `reminderGraceMinutes` (default **180**), and
  `settingsModifiedAt`.

## BMI and waist-hip ratio

`WeightData.calculateBMI(heightCm, weightKg)` returns `null` when height is missing or `<= 0`;
otherwise `weightKg / (heightM * heightM)` with `heightM = heightCm / 100`.
`WeightData.calculateWaistHipRatio(waistCm, hipCm)` returns `null` unless **both** waist and hip are
positive.

## Bust/waist/hip inheritance from the latest positive value

For summary cards and measurement trend charts, a record with a missing/blank bust, waist, or hip
field independently **inherits the previous positive value** for that specific field — without
writing that inherited value back into the record. Concretely,
`WeightData.effectiveMeasurementsUpTo(records, at)` and `effectiveMeasurementTimeline(records)`
sort records chronologically (ties broken by `modifiedAt` then `id`) and, walking forward, keep the
most recent value greater than zero seen so far for each of bust/waist/hip separately — so, e.g., a
new record that only updates weight and waist still displays the last-known bust and hip from
earlier records, while the stored record itself remains exactly what the user entered (possibly with
those fields absent).

## Reminder grace window

A reminder is skipped when a weight record already exists inside a configured grace window. The
window **opens `graceMinutes` before the scheduled reminder minute and closes at the moment the
check actually runs**, because either end on its own misses a real case: anchoring only on the
scheduled minute ignores a record logged after it (reminder 08:00, record 08:30, desktop app not
opened again until 11:00), while anchoring only on the check moment forgets a record logged before
it (reminder 08:00, record 06:00, desktop app not opened until 13:00 — the user weighed in two
hours before the reminder was due and must not be nagged for it).

The pure decision lives in `ReminderService.shouldSkipWeightReminderAt`
(`lib/shared/services/reminder_service.dart`), covered by `test/weight_reminder_grace_test.dart`:

```dart
static bool shouldSkipWeightReminderAt({
  required DateTime firesAt,
  required List<WeightRecord> records,
  required int graceMinutes,
  DateTime? scheduledAt,
}) {
  if (graceMinutes <= 0) return false;
  final anchor = scheduledAt != null && scheduledAt.isBefore(firesAt)
      ? scheduledAt
      : firesAt;
  final windowStart = anchor.subtract(Duration(minutes: graceMinutes));
  final windowEnd = firesAt.add(const Duration(minutes: 1));
  return records.any((record) {
    return !record.datetime.isBefore(windowStart) &&
        record.datetime.isBefore(windowEnd);
  });
}
```

The window is `[(scheduledAt ?? firesAt) − graceMinutes, firesAt + 1 minute)`. `scheduledAt` is
ignored unless it precedes `firesAt`, so the window can never widen forward past the fire moment.
The two callers pass different ends, and this difference is deliberate:

- **Desktop** passes both ends: `firesAt` is `current`, the actual wall-clock time at which the
  30-second reminder loop evaluated the check, and `scheduledAt` is that day's configured reminder
  minute (`!_shouldSkipWeightReminder(current, scheduledAt: reminderAt)` in the morning/evening
  reminder blocks of `lib/shared/services/reminder_service.dart`). A desktop check can run
  arbitrarily late — the app may have been closed, or the process suspended — so a record on either
  side of the scheduled minute has to count.
- **Mobile** passes only the scheduled **candidate fire time** it is pre-computing a notification
  for (`if (_shouldSkipWeightReminder(candidate))` when building the OS schedule), because mobile
  notifications are scheduled ahead of time by the OS rather than evaluated live — there is no
  "actual moment it fires" available to the app at scheduling time, only the candidate time being
  scheduled. Every path that writes a weight record rebuilds the schedule, including the intimacy
  body section and the local HTTP API, so a stale schedule cannot outlive a new record.

Mobile weight reminders that land inside the grace window keep their **daily repeat** — the repeat
is shifted to start the next day, never replaced by a one-shot (see
[Platform Notes](../platform-notes.md#notifications-reminders-tray-and-startup)).

## UI

The Weight page includes add/edit records, optional bust/waist/hip measurement entry, chart range
selection, raw and EWMA weight trend display, a separate raw/EWMA bust-waist-hip trend chart,
BMI/measurement/waist-hip-ratio summary cards with compact color bars, weekly grouped history that
follows the global week-start-day setting, a "show all" history view, and reminder settings.

## Related pages

- [Data Formats](../data-formats.md) — exact JSON shape of `WeightRecord`/`WeightData`.
- [Intimacy](intimacy.md) — the Body layer mirrors the user's bust/waist/hip from these same Weight
  records via `effectiveMeasurementsUpTo`.
- [Platform Notes](../platform-notes.md) — mobile vs. desktop reminder delivery mechanics.

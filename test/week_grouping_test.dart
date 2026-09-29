import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/shared/utils/week_grouping.dart';

void main() {
  group('week grouping', () {
    test('startOfWeek respects configured start day', () {
      final wednesday = DateTime(2024, 1, 10);

      expect(
        startOfWeek(wednesday, weekStartDay: DateTime.monday),
        DateTime(2024, 1, 8),
      );
      expect(
        startOfWeek(wednesday, weekStartDay: DateTime.sunday),
        DateTime(2024, 1, 7),
      );
      expect(
        startOfWeek(wednesday, weekStartDay: DateTime.wednesday),
        DateTime(2024, 1, 10),
      );
    });

    test('week number follows the configured start day', () {
      expect(weekYear(DateTime(2021, 1, 1)), 2020);
      expect(weekNumber(DateTime(2021, 1, 1)), 53);

      expect(
        weekYear(DateTime(2022, 1, 1), weekStartDay: DateTime.sunday),
        2021,
      );
      expect(
        weekNumber(DateTime(2022, 1, 1), weekStartDay: DateTime.sunday),
        52,
      );
      expect(
        weekYear(DateTime(2022, 1, 2), weekStartDay: DateTime.sunday),
        2022,
      );
      expect(
        weekNumber(DateTime(2022, 1, 2), weekStartDay: DateTime.sunday),
        1,
      );
    });

    test('groupByWeek changes group boundaries with week start day', () {
      final dates = [DateTime(2024, 1, 7), DateTime(2024, 1, 8)];

      final mondayGroups = groupByWeek<DateTime>(
        dates,
        (date) => date,
        descending: false,
        weekStartDay: DateTime.monday,
      );
      final sundayGroups = groupByWeek<DateTime>(
        dates,
        (date) => date,
        descending: false,
        weekStartDay: DateTime.sunday,
      );

      expect(mondayGroups, hasLength(2));
      expect(mondayGroups[0].start, DateTime(2024, 1, 1));
      expect(mondayGroups[1].start, DateTime(2024, 1, 8));

      expect(sundayGroups, hasLength(1));
      expect(sundayGroups.single.start, DateTime(2024, 1, 7));
      expect(sundayGroups.single.items, dates);
    });

    test('weekdaySequence normalizes invalid values to Monday', () {
      expect(weekdaySequence(0), [
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      ]);
      expect(weekdaySequence(DateTime.saturday).take(3), [
        DateTime.saturday,
        DateTime.sunday,
        DateTime.monday,
      ]);
    });
  });

  // These only prove themselves in a DST time zone (CI: TZ=America/New_York);
  // elsewhere they still pass and pin the calendar-day contract.
  group('calendar-day arithmetic across DST (v1.5.2)', () {
    test('addCalendarDays keeps the wall-clock time every day of a year', () {
      for (
        var d = DateTime(2026, 1, 1, 9, 30);
        d.year == 2026;
        d = addCalendarDays(d, 1)
      ) {
        final next = addCalendarDays(d, 1);
        expect((next.hour, next.minute), (9, 30), reason: '$d');
        expect(calendarDaysBetween(d, next), 1, reason: '$d');
        expect(addCalendarDays(next, -1), d, reason: '$d');
      }
      final utc = DateTime.utc(2026, 3, 8, 12);
      expect(addCalendarDays(utc, 1), DateTime.utc(2026, 3, 9, 12));
    });

    test('startOfWeek and week ends stay on local midnight all year', () {
      for (
        var d = DateTime(2026, 1, 1);
        d.year == 2026;
        d = addCalendarDays(d, 1)
      ) {
        final start = startOfWeek(d, weekStartDay: DateTime.sunday);
        expect(start.hour, 0, reason: '$d');
        expect(start.weekday, DateTime.sunday, reason: '$d');
        expect(calendarDaysBetween(start, d), inInclusiveRange(0, 6));
      }
      final groups = groupByWeek([
        DateTime(2026, 3, 9),
        DateTime(2026, 11, 2),
      ], (d) => d);
      for (final g in groups) {
        expect(g.end.hour, 0);
        expect(calendarDaysBetween(g.start, g.end), 6);
      }
    });
  });
}

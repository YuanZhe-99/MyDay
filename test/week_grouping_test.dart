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
}

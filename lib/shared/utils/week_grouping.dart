import 'package:intl/intl.dart';

enum WeekdayLabelWidth { short, long }

class WeekGroup<T> {
  final int year;
  final int week;
  final DateTime start;
  final DateTime end;
  final List<T> items;

  /// Purpose: Create a week group instance.
  /// Inputs: None.
  /// Returns: A new `WeekGroup` instance.
  /// Side effects: None.
  /// Notes: None.
  const WeekGroup({
    required this.year,
    required this.week,
    required this.start,
    required this.end,
    required this.items,
  });
}

/// Purpose: Group items by calendar week using a configurable week start day.
/// Inputs: `items`, `getDate`, `descending`, and `weekStartDay`.
/// Returns: `List<WeekGroup<T>>`.
/// Side effects: Mutates each returned group's internal item list while building groups.
/// Notes: Week numbering uses the four-day week rule anchored to the configured start day.
List<WeekGroup<T>> groupByWeek<T>(
  List<T> items,
  DateTime Function(T item) getDate, {
  bool descending = true,
  int weekStartDay = DateTime.monday,
}) {
  final normalizedStart = normalizeWeekStartDay(weekStartDay);
  final groups = <String, WeekGroup<T>>{};
  for (final item in items) {
    final date = _dateOnly(getDate(item));
    final start = startOfWeek(date, weekStartDay: normalizedStart);
    final year = weekYear(date, weekStartDay: normalizedStart);
    final week = weekNumber(date, weekStartDay: normalizedStart);
    final key = '$year-$week';
    final existing = groups[key];
    if (existing == null) {
      groups[key] = WeekGroup<T>(
        year: year,
        week: week,
        start: start,
        end: start.add(const Duration(days: 6)),
        items: [item],
      );
    } else {
      existing.items.add(item);
    }
  }

  final result = groups.values.toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  if (descending) {
    return result.reversed.toList();
  }
  return result;
}

/// Purpose: Group items by ISO week with Monday as the week start.
/// Inputs: `items`, `getDate`, `descending`.
/// Returns: `List<WeekGroup<T>>`.
/// Side effects: Mutates each returned group's internal item list while building groups.
/// Notes: Kept as a compatibility wrapper for callers that still need ISO weeks.
List<WeekGroup<T>> groupByIsoWeek<T>(
  List<T> items,
  DateTime Function(T item) getDate, {
  bool descending = true,
}) {
  return groupByWeek(
    items,
    getDate,
    descending: descending,
    weekStartDay: DateTime.monday,
  );
}

/// Purpose: Return a valid Dart weekday to use as week start.
/// Inputs: `weekday`.
/// Returns: `int`.
/// Side effects: None.
/// Notes: Defaults invalid persisted values back to Monday.
int normalizeWeekStartDay(int? weekday) {
  if (weekday == null ||
      weekday < DateTime.monday ||
      weekday > DateTime.sunday) {
    return DateTime.monday;
  }
  return weekday;
}

/// Purpose: Return weekdays ordered from the configured week start.
/// Inputs: `weekStartDay`.
/// Returns: `List<int>`.
/// Side effects: None.
/// Notes: Weekday values use Dart's Monday=1 through Sunday=7 numbering.
List<int> weekdaySequence(int weekStartDay) {
  final start = normalizeWeekStartDay(weekStartDay);
  return [
    for (var offset = 0; offset < 7; offset++) ((start - 1 + offset) % 7) + 1,
  ];
}

/// Purpose: Return a localized weekday label for a Dart weekday value.
/// Inputs: `weekday`, `localeName`, and `width`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: Uses Intl so all modules share the same weekday translations.
String localizedWeekdayLabel(
  int weekday,
  String localeName, {
  WeekdayLabelWidth width = WeekdayLabelWidth.short,
}) {
  final normalized = normalizeWeekStartDay(weekday);
  final date = DateTime.utc(2024, 1, normalized); // 2024-01-01 is Monday.
  final format = width == WeekdayLabelWidth.long
      ? DateFormat.EEEE(localeName)
      : DateFormat.E(localeName);
  return format.format(date);
}

/// Purpose: Return the first calendar date of the configured week.
/// Inputs: `date` and `weekStartDay`.
/// Returns: `DateTime`.
/// Side effects: None.
/// Notes: The returned value preserves local date semantics and strips the time component.
DateTime startOfWeek(DateTime date, {int weekStartDay = DateTime.monday}) {
  final day = _dateOnly(date);
  final start = normalizeWeekStartDay(weekStartDay);
  return day.subtract(Duration(days: (day.weekday - start + 7) % 7));
}

/// Purpose: Return the Monday that starts the ISO week containing `date`.
/// Inputs: `date`.
/// Returns: `DateTime`.
/// Side effects: None.
/// Notes: Kept for ISO-specific callers and tests.
DateTime startOfIsoWeek(DateTime date) {
  return startOfWeek(date, weekStartDay: DateTime.monday);
}

/// Purpose: Return the week-numbering year for a configurable-start week.
/// Inputs: `date` and `weekStartDay`.
/// Returns: `int`.
/// Side effects: None.
/// Notes: Uses the same four-day week rule as ISO, shifted to the configured start day.
int weekYear(DateTime date, {int weekStartDay = DateTime.monday}) {
  return startOfWeek(
    date,
    weekStartDay: weekStartDay,
  ).add(const Duration(days: 3)).year;
}

/// Purpose: Return the ISO week-numbering year for `date`.
/// Inputs: `date`.
/// Returns: `int`.
/// Side effects: None.
/// Notes: Kept for ISO-specific callers and tests.
int isoWeekYear(DateTime date) {
  return weekYear(date, weekStartDay: DateTime.monday);
}

/// Purpose: Return the week number within the configurable week-numbering year.
/// Inputs: `date` and `weekStartDay`.
/// Returns: `int`.
/// Side effects: None.
/// Notes: Uses January 4 as the first-week anchor, matching ISO's four-day rule.
int weekNumber(DateTime date, {int weekStartDay = DateTime.monday}) {
  final start = startOfWeek(date, weekStartDay: weekStartDay);
  final anchor = start.add(const Duration(days: 3));
  final firstWeekStart = startOfWeek(
    DateTime(anchor.year, 1, 4),
    weekStartDay: weekStartDay,
  );
  return _differenceInCalendarDays(firstWeekStart, start) ~/ 7 + 1;
}

/// Purpose: Return the ISO week number for `date`.
/// Inputs: `date`.
/// Returns: `int`.
/// Side effects: None.
/// Notes: Kept for ISO-specific callers and tests.
int isoWeekNumber(DateTime date) {
  return weekNumber(date, weekStartDay: DateTime.monday);
}

/// Purpose: Implement the format month day range behavior for this file.
/// Inputs: `start`, `end`, and optional `localeName`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: Uses Intl when a locale is provided so month/day order follows the app language.
String formatMonthDayRange(DateTime start, DateTime end, {String? localeName}) {
  final format = DateFormat.Md(localeName);
  return '${format.format(start)}-${format.format(end)}';
}

/// Purpose: Return the number of blank cells before a month starts in a calendar grid.
/// Inputs: `date` and `weekStartDay`.
/// Returns: `int`.
/// Side effects: None.
/// Notes: The result is always between 0 and 6.
int leadingBlankDaysForMonth(
  DateTime date, {
  int weekStartDay = DateTime.monday,
}) {
  final first = DateTime(date.year, date.month, 1);
  final start = normalizeWeekStartDay(weekStartDay);
  return (first.weekday - start + 7) % 7;
}

/// Purpose: Provide the internal date only helper for this file.
/// Inputs: `date`.
/// Returns: `DateTime`.
/// Side effects: May create, transform, or mutate data used by callers.
/// Notes: Internal helper used within this file only.
DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Purpose: Return whole calendar days between two date-only values.
/// Inputs: `start`, `end`.
/// Returns: `int`.
/// Side effects: None.
/// Notes: Uses UTC dates to avoid daylight-saving gaps changing week numbers.
int _differenceInCalendarDays(DateTime start, DateTime end) {
  return DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
}

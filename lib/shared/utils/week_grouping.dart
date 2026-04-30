class WeekGroup<T> {
  final int year;
  final int week;
  final DateTime start;
  final DateTime end;
  final List<T> items;

  const WeekGroup({
    required this.year,
    required this.week,
    required this.start,
    required this.end,
    required this.items,
  });
}

List<WeekGroup<T>> groupByIsoWeek<T>(
  List<T> items,
  DateTime Function(T item) getDate, {
  bool descending = true,
}) {
  final groups = <String, WeekGroup<T>>{};
  for (final item in items) {
    final date = _dateOnly(getDate(item));
    final start = startOfIsoWeek(date);
    final year = isoWeekYear(date);
    final week = isoWeekNumber(date);
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

DateTime startOfIsoWeek(DateTime date) {
  final day = _dateOnly(date);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

int isoWeekYear(DateTime date) {
  final day = _dateOnly(date);
  return day.add(Duration(days: DateTime.thursday - day.weekday)).year;
}

int isoWeekNumber(DateTime date) {
  final day = _dateOnly(date);
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final firstThursday = DateTime(thursday.year, 1, 4);
  final firstWeekStart = startOfIsoWeek(firstThursday);
  return thursday.difference(firstWeekStart).inDays ~/ 7 + 1;
}

String formatMonthDayRange(DateTime start, DateTime end) {
  return '${start.month}/${start.day}-${end.month}/${end.day}';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

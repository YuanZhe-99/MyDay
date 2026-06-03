import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/todo/services/todo_storage.dart';
import '../../l10n/app_localizations.dart';
import '../utils/week_grouping.dart';

/// Purpose: Show the app-standard date picker using the global week-start setting.
/// Inputs: `context`, `initialDate`, `firstDate`, `lastDate`, and optional `title`.
/// Returns: The selected date, or null when cancelled.
/// Side effects: Reads persisted settings and opens a dialog.
/// Notes: Use this instead of Flutter's `showDatePicker` so all modules share calendar behavior.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? title,
}) async {
  final weekStartDay = await TodoStorage.getWeekStartDay();
  if (!context.mounted) return null;
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => _AppDatePickerDialog(
      initialDate: _clampDate(_dateOnly(initialDate), firstDate, lastDate),
      firstDate: _dateOnly(firstDate),
      lastDate: _dateOnly(lastDate),
      weekStartDay: weekStartDay,
      title: title,
    ),
  );
}

/// Purpose: Show the app-standard date-range picker using the global week-start setting.
/// Inputs: `context`, `firstDate`, `lastDate`, optional initial range, and optional `title`.
/// Returns: The selected date range, or null when cancelled.
/// Side effects: Reads persisted settings and opens a dialog.
/// Notes: The user taps a start date and then an end date before confirming.
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
  String? title,
}) async {
  final weekStartDay = await TodoStorage.getWeekStartDay();
  if (!context.mounted) return null;
  return showDialog<DateTimeRange>(
    context: context,
    builder: (dialogContext) => _AppDateRangePickerDialog(
      firstDate: _dateOnly(firstDate),
      lastDate: _dateOnly(lastDate),
      initialDateRange: initialDateRange == null
          ? null
          : DateTimeRange(
              start: _clampDate(
                _dateOnly(initialDateRange.start),
                firstDate,
                lastDate,
              ),
              end: _clampDate(
                _dateOnly(initialDateRange.end),
                firstDate,
                lastDate,
              ),
            ),
      weekStartDay: weekStartDay,
      title: title,
    ),
  );
}

class _AppDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final int weekStartDay;
  final String? title;

  /// Purpose: Create a single-date picker dialog.
  /// Inputs: Initial date, allowed range, configured week start, and optional title.
  /// Returns: A new `_AppDatePickerDialog` instance.
  /// Side effects: None.
  /// Notes: Internal widget used by `showAppDatePicker` only.
  const _AppDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.weekStartDay,
    this.title,
  });

  /// Purpose: Create the mutable state object for this dialog.
  /// Inputs: None.
  /// Returns: A new `_AppDatePickerDialogState`.
  /// Side effects: None.
  /// Notes: None.
  @override
  State<_AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

class _AppDatePickerDialogState extends State<_AppDatePickerDialog> {
  late DateTime _viewMonth;

  /// Purpose: Initialize the visible month from the initial date.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Initializes dialog state.
  /// Notes: None.
  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  /// Purpose: Move the visible calendar month by `delta` months.
  /// Inputs: `delta`.
  /// Returns: None.
  /// Side effects: Updates dialog state.
  /// Notes: Navigation buttons disable before this method is called at range boundaries.
  void _changeMonth(int delta) {
    setState(
      () => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta),
    );
  }

  /// Purpose: Build this date picker dialog.
  /// Inputs: `context`.
  /// Returns: The dialog widget tree.
  /// Side effects: Creates UI widgets and date-selection callbacks.
  /// Notes: Tapping an enabled date closes the dialog with that date.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title ?? l10n.commonDate),
      content: SizedBox(
        width: 330,
        child: _CalendarMonthPicker(
          viewMonth: _viewMonth,
          selectedDate: widget.initialDate,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          weekStartDay: widget.weekStartDay,
          onMonthChanged: _changeMonth,
          onDateSelected: (date) => Navigator.pop(context, date),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(material.cancelButtonLabel),
        ),
      ],
    );
  }
}

class _AppDateRangePickerDialog extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initialDateRange;
  final int weekStartDay;
  final String? title;

  /// Purpose: Create a date-range picker dialog.
  /// Inputs: Allowed date range, optional initial range, configured week start, and optional title.
  /// Returns: A new `_AppDateRangePickerDialog` instance.
  /// Side effects: None.
  /// Notes: Internal widget used by `showAppDateRangePicker` only.
  const _AppDateRangePickerDialog({
    required this.firstDate,
    required this.lastDate,
    required this.weekStartDay,
    this.initialDateRange,
    this.title,
  });

  /// Purpose: Create the mutable state object for this dialog.
  /// Inputs: None.
  /// Returns: A new `_AppDateRangePickerDialogState`.
  /// Side effects: None.
  /// Notes: None.
  @override
  State<_AppDateRangePickerDialog> createState() =>
      _AppDateRangePickerDialogState();
}

class _AppDateRangePickerDialogState extends State<_AppDateRangePickerDialog> {
  late DateTime _viewMonth;
  DateTime? _start;
  DateTime? _end;

  /// Purpose: Initialize the visible month and selected range.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Initializes dialog state.
  /// Notes: None.
  @override
  void initState() {
    super.initState();
    _start = widget.initialDateRange?.start;
    _end = widget.initialDateRange?.end;
    final initial = _start ?? DateTime.now();
    final clamped = _clampDate(
      _dateOnly(initial),
      widget.firstDate,
      widget.lastDate,
    );
    _viewMonth = DateTime(clamped.year, clamped.month);
  }

  /// Purpose: Move the visible calendar month by `delta` months.
  /// Inputs: `delta`.
  /// Returns: None.
  /// Side effects: Updates dialog state.
  /// Notes: Navigation buttons disable before this method is called at range boundaries.
  void _changeMonth(int delta) {
    setState(
      () => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta),
    );
  }

  /// Purpose: Apply a tapped date to the in-progress range selection.
  /// Inputs: `date`.
  /// Returns: None.
  /// Side effects: Updates dialog state.
  /// Notes: A third tap starts a new range from that date.
  void _selectDate(DateTime date) {
    setState(() {
      if (_start == null || _end != null) {
        _start = date;
        _end = null;
      } else if (date.isBefore(_start!)) {
        _end = _start;
        _start = date;
      } else {
        _end = date;
      }
    });
  }

  /// Purpose: Build this date-range picker dialog.
  /// Inputs: `context`.
  /// Returns: The dialog widget tree.
  /// Side effects: Creates UI widgets and date-selection callbacks.
  /// Notes: Confirmation is enabled only after both range ends are selected.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final localeName = l10n.localeName;
    final rangeLabel = _start == null
        ? l10n.financeSelectDateRange
        : _end == null
        ? DateFormat.yMMMd(localeName).format(_start!)
        : '${DateFormat.yMMMd(localeName).format(_start!)} - ${DateFormat.yMMMd(localeName).format(_end!)}';
    return AlertDialog(
      title: Text(widget.title ?? l10n.financeSelectDateRange),
      content: SizedBox(
        width: 330,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rangeLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            _CalendarMonthPicker(
              viewMonth: _viewMonth,
              selectedDate: _start,
              rangeEndDate: _end,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              weekStartDay: widget.weekStartDay,
              onMonthChanged: _changeMonth,
              onDateSelected: _selectDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _start != null && _end != null
              ? () => Navigator.pop(
                  context,
                  DateTimeRange(start: _start!, end: _end!),
                )
              : null,
          child: Text(material.okButtonLabel),
        ),
      ],
    );
  }
}

class _CalendarMonthPicker extends StatelessWidget {
  final DateTime viewMonth;
  final DateTime? selectedDate;
  final DateTime? rangeEndDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final int weekStartDay;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  /// Purpose: Render a localized month grid for app date picker dialogs.
  /// Inputs: Visible month, optional selected range, allowed date range, and callbacks.
  /// Returns: A new `_CalendarMonthPicker` instance.
  /// Side effects: None.
  /// Notes: The caller owns the visible month and selected-date state.
  const _CalendarMonthPicker({
    required this.viewMonth,
    required this.selectedDate,
    this.rangeEndDate,
    required this.firstDate,
    required this.lastDate,
    required this.weekStartDay,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  /// Purpose: Return whether moving to the previous month is allowed.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: The previous month must overlap the allowed date range.
  bool get _canGoPrevious {
    final previousEnd = DateTime(viewMonth.year, viewMonth.month, 0);
    return !previousEnd.isBefore(firstDate);
  }

  /// Purpose: Return whether moving to the next month is allowed.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: The next month must overlap the allowed date range.
  bool get _canGoNext {
    final nextStart = DateTime(viewMonth.year, viewMonth.month + 1, 1);
    return !nextStart.isAfter(lastDate);
  }

  /// Purpose: Build the localized calendar month picker.
  /// Inputs: `context`.
  /// Returns: The month picker widget tree.
  /// Side effects: Creates UI widgets and callbacks.
  /// Notes: Weekday order follows `weekStartDay`.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final localeName = l10n.localeName;
    final daysInMonth = DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
    final leadingBlanks = leadingBlankDaysForMonth(
      viewMonth,
      weekStartDay: weekStartDay,
    );
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;
    final today = _dateOnly(DateTime.now());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _canGoPrevious ? () => onMonthChanged(-1) : null,
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat.yMMMM(localeName).format(viewMonth),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _canGoNext ? () => onMonthChanged(1) : null,
            ),
          ],
        ),
        Row(
          children: [
            for (final weekday in weekdaySequence(weekStartDay))
              Expanded(
                child: Center(
                  child: Text(
                    localizedWeekdayLabel(weekday, localeName),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayOffset = index - leadingBlanks;
            if (dayOffset < 0 || dayOffset >= daysInMonth) {
              return const SizedBox(height: 38);
            }
            final date = DateTime(
              viewMonth.year,
              viewMonth.month,
              dayOffset + 1,
            );
            final enabled =
                !date.isBefore(firstDate) && !date.isAfter(lastDate);
            return _CalendarDateCell(
              date: date,
              isToday: _isSameDay(date, today),
              isSelected:
                  selectedDate != null && _isSameDay(date, selectedDate!),
              isRangeEnd:
                  rangeEndDate != null && _isSameDay(date, rangeEndDate!),
              isInRange: _isInRange(date, selectedDate, rangeEndDate),
              enabled: enabled,
              onTap: enabled ? () => onDateSelected(date) : null,
            );
          },
        ),
      ],
    );
  }
}

class _CalendarDateCell extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool isRangeEnd;
  final bool isInRange;
  final bool enabled;
  final VoidCallback? onTap;

  /// Purpose: Render one selectable date cell in the app date picker.
  /// Inputs: Date state flags and tap callback.
  /// Returns: A new `_CalendarDateCell` instance.
  /// Side effects: None.
  /// Notes: Range endpoints use the primary color; in-range dates use a light primary fill.
  const _CalendarDateCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.isRangeEnd,
    required this.isInRange,
    required this.enabled,
    this.onTap,
  });

  /// Purpose: Build one calendar date cell.
  /// Inputs: `context`.
  /// Returns: The date cell widget.
  /// Side effects: Creates the optional tap callback.
  /// Notes: Disabled dates remain visible but cannot be selected.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = isSelected || isRangeEnd;
    final textColor = !enabled
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
        : selected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final background = selected
        ? colorScheme.primary
        : isInRange
        ? colorScheme.primaryContainer.withValues(alpha: 0.65)
        : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: background,
        shape: CircleBorder(
          side: isToday && !selected
              ? BorderSide(color: colorScheme.primary, width: 1.4)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Text(
              '${date.day}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: selected || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Purpose: Return whether `date` is inside the selected date range.
/// Inputs: `date`, nullable `start`, and nullable `end`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Endpoints are not considered interior range dates.
bool _isInRange(DateTime date, DateTime? start, DateTime? end) {
  if (start == null || end == null) return false;
  return date.isAfter(start) && date.isBefore(end);
}

/// Purpose: Strip the time component from a date.
/// Inputs: `date`.
/// Returns: `DateTime`.
/// Side effects: None.
/// Notes: Internal helper used for date-only comparisons.
DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Purpose: Return whether two date values represent the same calendar day.
/// Inputs: `a`, `b`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Time components are ignored.
bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Purpose: Clamp `date` to an inclusive date-only range.
/// Inputs: `date`, `firstDate`, and `lastDate`.
/// Returns: `DateTime`.
/// Side effects: None.
/// Notes: Uses date-only comparisons so caller time components are ignored.
DateTime _clampDate(DateTime date, DateTime firstDate, DateTime lastDate) {
  final day = _dateOnly(date);
  final first = _dateOnly(firstDate);
  final last = _dateOnly(lastDate);
  if (day.isBefore(first)) return first;
  if (day.isAfter(last)) return last;
  return day;
}

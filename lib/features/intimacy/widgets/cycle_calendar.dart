import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_settings.dart';
import '../../../shared/utils/week_grouping.dart';
import '../services/cycle_predictor.dart';

/// Stable palette for cycle overlays; the user always takes slot 0 and
/// enabled partners take following slots sorted by partner id.
const List<Color> cyclePersonPalette = [
  Color(0xFFD81B60), // pink
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFF4511E), // deep orange
  Color(0xFF8E24AA), // purple
  Color(0xFF00897B), // teal
  Color(0xFF6D4C41), // brown
  Color(0xFF3949AB), // indigo
];

/// One person's cycle overlay for a calendar.
class PersonCycleOverlay {
  /// 'user' for the user, otherwise the partner id.
  final String personKey;
  final String displayName;
  final Color color;
  final CyclePrediction prediction;

  /// Purpose: Create a person cycle overlay value.
  /// Inputs: `personKey`, `displayName`, `color`, `prediction`.
  /// Returns: A new `PersonCycleOverlay` instance.
  /// Side effects: None.
  /// Notes: The color is the person's stable base identifier on calendars.
  const PersonCycleOverlay({
    required this.personKey,
    required this.displayName,
    required this.color,
    required this.prediction,
  });
}

/// Purpose: Build the small per-day indicator for one person's cycle info.
/// Inputs: `color` person color, `info` day classification, `height`.
/// Returns: `Widget`.
/// Side effects: None.
/// Notes: Menstrual days render solid, the fertile window semi-opaque,
/// follicular/luteal faint; ovulation is a centered dot; actual starts show
/// a filled leading dot and predicted starts a hollow one.
Widget buildCycleDayIndicator(Color color, CycleDayInfo? info,
    {double height = 4}) {
  if (info == null) return SizedBox(height: height);
  final double opacity;
  switch (info.phase) {
    case CyclePhase.menstrual:
      opacity = 1.0;
    case CyclePhase.follicular:
      opacity = info.inFertileWindow ? 0.55 : 0.18;
    case CyclePhase.luteal:
      opacity = info.inFertileWindow ? 0.55 : 0.32;
  }
  final bar = Container(
    height: height,
    decoration: BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );
  final children = <Widget>[Positioned.fill(child: bar)];
  if (info.isOvulationDay) {
    children.add(
      Center(
        child: Container(
          width: height + 2,
          height: height + 2,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
  if (info.isActualStart || info.isPredictedStart) {
    children.add(
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: height + 2,
          height: height + 2,
          decoration: BoxDecoration(
            color: info.isActualStart ? color : null,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.2),
          ),
        ),
      ),
    );
  }
  return SizedBox(
    height: height + 2,
    child: Stack(clipBehavior: Clip.none, children: children),
  );
}

/// Legend explaining cycle colors and marker styles.
class CycleLegend extends StatelessWidget {
  /// Person chips; hidden when there is only one implicit person.
  final List<PersonCycleOverlay> people;
  final bool showPeople;

  /// Purpose: Create a cycle legend instance.
  /// Inputs: `people`, `showPeople`.
  /// Returns: A new `CycleLegend` instance.
  /// Side effects: None.
  /// Notes: Also carries the mandatory estimation disclaimer.
  const CycleLegend({
    super.key,
    required this.people,
    this.showPeople = true,
  });

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sampleColor = people.isNotEmpty
        ? people.first.color
        : cyclePersonPalette.first;

    Widget item(Widget marker, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        marker,
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );

    Widget bar(double opacity) => Container(
      width: 16,
      height: 4,
      decoration: BoxDecoration(
        color: sampleColor.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );

    Widget dot({required bool filled}) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: filled ? sampleColor : null,
        shape: BoxShape.circle,
        border: Border.all(color: sampleColor, width: 1.2),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPeople && people.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final person in people)
                  item(
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: person.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    person.displayName,
                  ),
              ],
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            item(bar(1.0), l10n.intimacyCyclePhaseMenstrual),
            item(bar(0.18), l10n.intimacyCyclePhaseFollicular),
            item(bar(0.55), l10n.intimacyCycleFertileWindow),
            item(bar(0.32), l10n.intimacyCyclePhaseLuteal),
            item(
              dot(filled: true),
              '${l10n.intimacyCycleOvulation} ${l10n.intimacyCycleEstimatedSuffix}',
            ),
            item(dot(filled: true), l10n.intimacyCycleActualStart),
            item(
              dot(filled: false),
              '${l10n.intimacyCyclePredictedStart} ${l10n.intimacyCycleEstimatedSuffix}',
            ),
          ],
        ),
      ],
    );
  }
}

/// A single-person month calendar showing cycle phases and start markers.
class CycleCalendar extends ConsumerStatefulWidget {
  final Color personColor;
  final CyclePrediction prediction;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  /// Purpose: Create a cycle calendar instance.
  /// Inputs: Person color, prediction, selection state, and tap callback.
  /// Returns: A new `CycleCalendar` instance.
  /// Side effects: None.
  /// Notes: Manages its own focused month; follows the global week start day.
  const CycleCalendar({
    super.key,
    required this.personColor,
    required this.prediction,
    required this.selectedDate,
    required this.onDateSelected,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  ConsumerState<CycleCalendar> createState() => _CycleCalendarState();
}

class _CycleCalendarState extends ConsumerState<CycleCalendar> {
  DateTime _focusedMonth = DateTime.now();

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final weekStartDay = ref.watch(appSettingsProvider).weekStartDay;
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingBlanks = leadingBlankDaysForMonth(
      firstDay,
      weekStartDay: weekStartDay,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () =>
                  setState(() => _focusedMonth = DateTime(year, month - 1, 1)),
            ),
            Text(
              DateFormat('yyyy MMMM', l10n.localeName).format(_focusedMonth),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () =>
                  setState(() => _focusedMonth = DateTime(year, month + 1, 1)),
            ),
          ],
        ),
        Row(
          children: [
            for (final weekday in weekdaySequence(weekStartDay))
              Expanded(
                child: Center(
                  child: Text(
                    localizedWeekdayLabel(weekday, l10n.localeName),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        _buildDayGrid(context, leadingBlanks, daysInMonth, year, month),
      ],
    );
  }

  /// Purpose: Provide the internal build day grid helper for this file.
  /// Inputs: `context`, `leadingBlanks`, `daysInMonth`, `year`, `month`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildDayGrid(
    BuildContext context,
    int leadingBlanks,
    int daysInMonth,
    int year,
    int month,
  ) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final rows = <Widget>[];
    var day = 1 - leadingBlanks;

    while (day <= daysInMonth) {
      final cells = <Widget>[];
      for (var i = 0; i < 7; i++) {
        if (day < 1 || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 46)));
        } else {
          final date = DateTime(year, month, day);
          final info = widget.prediction.days[date];
          final isSelected =
              widget.selectedDate != null &&
              widget.selectedDate!.year == date.year &&
              widget.selectedDate!.month == date.month &&
              widget.selectedDate!.day == date.day;
          final isToday =
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          cells.add(
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onDateSelected(date),
                child: Container(
                  height: 46,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : null,
                    border: isToday
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 3,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        day.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : null,
                          fontWeight: isSelected || isToday || info != null
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                      buildCycleDayIndicator(widget.personColor, info),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        day++;
      }
      rows.add(Row(children: cells));
    }
    return Column(children: rows);
  }
}

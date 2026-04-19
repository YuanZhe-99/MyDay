import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/task.dart';

/// Bottom-sheet widget for picking a [TaskRecurrence].
///
/// Call via:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (ctx) => RecurrencePicker(
///     initial: _recurrence,
///     onSelected: (r) { setState(() => _recurrence = r); Navigator.pop(ctx); },
///   ),
/// );
/// ```
class RecurrencePicker extends StatefulWidget {
  final TaskRecurrence? initial;
  final ValueChanged<TaskRecurrence?> onSelected;
  const RecurrencePicker({super.key, required this.initial, required this.onSelected});

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  late RecurrenceType? _type;
  int _intervalDays = 7;
  int _dayOfMonth = 1;
  int _monthOfYear = 1;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    if (r == null) {
      _type = null;
    } else {
      _type = r.type;
      switch (r.type) {
        case RecurrenceType.everyNDays:
          _intervalDays = r.intervalDays > 0 ? r.intervalDays : 7;
        case RecurrenceType.monthlyOnDay:
          _dayOfMonth = r.dayOfMonth > 0 ? r.dayOfMonth : 1;
        case RecurrenceType.yearlyOnMonthDay:
          _monthOfYear = r.monthOfYear > 0 ? r.monthOfYear : 1;
          _dayOfMonth = r.dayOfMonth > 0 ? r.dayOfMonth : 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.todoRecurrence, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          // None
          RadioListTile<RecurrenceType?>(
            contentPadding: EdgeInsets.zero,
            value: null,
            groupValue: _type,
            title: Text(l10n.todoRecurrenceNone),
            onChanged: (_) => widget.onSelected(null),
          ),

          // Every N days
          RadioListTile<RecurrenceType?>(
            contentPadding: EdgeInsets.zero,
            value: RecurrenceType.everyNDays,
            groupValue: _type,
            title: Text(l10n.todoRecurrenceEveryNDays(_intervalDays)),
            onChanged: (v) => setState(() => _type = v),
          ),
          if (_type == RecurrenceType.everyNDays)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _intervalDays.toDouble(),
                      min: 1,
                      max: 90,
                      divisions: 89,
                      label: '$_intervalDays',
                      onChanged: (v) => setState(() => _intervalDays = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text('$_intervalDays d', textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),

          // Monthly on day N
          RadioListTile<RecurrenceType?>(
            contentPadding: EdgeInsets.zero,
            value: RecurrenceType.monthlyOnDay,
            groupValue: _type,
            title: Text(l10n.todoRecurrenceMonthlyOnDay(_dayOfMonth)),
            onChanged: (v) => setState(() => _type = v),
          ),
          if (_type == RecurrenceType.monthlyOnDay)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _dayOfMonth.toDouble(),
                      min: 1,
                      max: 31,
                      divisions: 30,
                      label: '$_dayOfMonth',
                      onChanged: (v) => setState(() => _dayOfMonth = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      l10n.todoRecurrenceMonthlyOnDay(_dayOfMonth),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

          // Yearly on month/day
          RadioListTile<RecurrenceType?>(
            contentPadding: EdgeInsets.zero,
            value: RecurrenceType.yearlyOnMonthDay,
            groupValue: _type,
            title: Text(l10n.todoRecurrenceYearlyOnDate(_monthOfYear, _dayOfMonth)),
            onChanged: (v) => setState(() => _type = v),
          ),
          if (_type == RecurrenceType.yearlyOnMonthDay)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(children: [
                    const SizedBox(width: 40, child: Text('M')),
                    Expanded(
                      child: Slider(
                        value: _monthOfYear.toDouble(),
                        min: 1,
                        max: 12,
                        divisions: 11,
                        label: '$_monthOfYear',
                        onChanged: (v) => setState(() => _monthOfYear = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text('$_monthOfYear', textAlign: TextAlign.center),
                    ),
                  ]),
                  Row(children: [
                    const SizedBox(width: 40, child: Text('D')),
                    Expanded(
                      child: Slider(
                        value: _dayOfMonth.toDouble(),
                        min: 1,
                        max: 31,
                        divisions: 30,
                        label: '$_dayOfMonth',
                        onChanged: (v) => setState(() => _dayOfMonth = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text('$_dayOfMonth', textAlign: TextAlign.center),
                    ),
                  ]),
                ],
              ),
            ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.commonCancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (_type == null) {
                    widget.onSelected(null);
                    return;
                  }
                  final recurrence = switch (_type!) {
                    RecurrenceType.everyNDays =>
                      TaskRecurrence.everyNDays(_intervalDays),
                    RecurrenceType.monthlyOnDay =>
                      TaskRecurrence.monthlyOnDay(_dayOfMonth),
                    RecurrenceType.yearlyOnMonthDay =>
                      TaskRecurrence.yearlyOnMonthDay(_monthOfYear, _dayOfMonth),
                  };
                  widget.onSelected(recurrence);
                },
                child: Text(l10n.commonSave),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

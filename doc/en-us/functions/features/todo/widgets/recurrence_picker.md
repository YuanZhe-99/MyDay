# lib/features/todo/widgets/recurrence_picker.dart

A bottom-sheet widget that lets the user pick a [`TaskRecurrence`](../../../../features/todo.md#model)
for a one-time task, or clear it back to "no recurrence". It is opened from both
[`AddTaskDialog`](add_task_dialog.md) and [`EditTaskDialog`](edit_task_dialog.md) via
`showModalBottomSheet`, and reports the chosen recurrence back through the `onSelected` callback
rather than returning a value from the sheet route. See [Todo](../../../../features/todo.md#model)
for the `TaskRecurrence` model (interval-days / monthly-on-day / yearly-on-month-day) this widget
edits.

All logic in this file is UI state wiring — picking a `RecurrenceType`, sliding interval/day/month
values, and translating the current selection into a `TaskRecurrence` on save. There is no separate
computed "preview" method: the preview text shown next to each radio option and slider is produced
inline in `build()` by calling the relevant `AppLocalizations` getter (e.g.
`l10n.todoRecurrenceEveryNDays(_intervalDays)`) directly against local state, so it is documented as
part of the `build()` row rather than as its own Tier A entry.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `RecurrencePicker` (constructor) | constructor (`RecurrencePicker`) | B | Create a recurrence picker instance. |
| `createState` | method (`RecurrencePicker`) | B | Create the mutable `_RecurrencePickerState`. |
| `initState` | method (`_RecurrencePickerState`) | B | Seed `_type`/`_intervalDays`/`_dayOfMonth`/`_monthOfYear` from `widget.initial`. |
| `build` | method (`_RecurrencePickerState`) | B | Render the radio options, sliders, and Save/Cancel row; compute the on-save `TaskRecurrence`. |

## Documentation

No Tier A declarations in this file.


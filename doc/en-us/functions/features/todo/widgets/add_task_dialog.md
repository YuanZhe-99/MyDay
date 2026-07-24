# lib/features/todo/widgets/add_task_dialog.dart

Modal dialog for creating a new [`Task`](../../../../features/todo.md#model) (or, when
`initialTask` is supplied, for prompting the user to create the *next occurrence* of a completed
recurring one-time task — see [Todo](../../../../features/todo.md#model) on
`TaskRecurrence`/`nextDate`). Wraps its form in `UnsavedChangesGuard`
(`lib/shared/widgets/unsaved_changes_guard.dart`) so navigating away with unsaved edits prompts a
discard confirmation; the guard's dirty-check is driven by a form "signature" string computed from
every editable field. Recurrence editing is delegated to
[`RecurrencePicker`](recurrence_picker.md), shown as a nested bottom sheet.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AddTaskDialog` (constructor) | constructor (`AddTaskDialog`) | B | Create an add-task dialog instance. |
| `createState` | method (`AddTaskDialog`) | B | Create the mutable `_AddTaskDialogState`. |
| `initState` | method (`_AddTaskDialogState`) | B | Pre-fill controllers/fields from `initialTask` (if editing a next-occurrence prompt) and capture the initial form signature. |
| `dispose` | method (`_AddTaskDialogState`) | B | Dispose the title/note/subtask text controllers. |
| `build` | method (`_AddTaskDialogState`) | B | Render the title/note fields, type selector, reminder/scheduled/due-date/recurrence pickers, subtask list, and Cancel/Add actions. |
| `_addSubtask` | method (`_AddTaskDialogState`) | B | Append the pending subtask-input text to `_subtaskTitles` and clear the field. |
| `_showEmojiPicker` | method (widget helper, `_AddTaskDialogState`) | B | Show the emoji-grid bottom sheet for picking `_selectedEmoji`. |
| `_showCustomEmojiInput` | method (widget helper, `_AddTaskDialogState`) | B | Show a dialog for typing a custom emoji/character. |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | method (`_AddTaskDialogState`) | A | Report whether the form differs from its initial state. |
| [`_signature`](#signature) | method (`_AddTaskDialogState`) | A | Build a comparable string snapshot of every editable field. |
| [`_recurrenceSignature`](#recurrencesignature) | method (`_AddTaskDialogState`) | A | Build a comparable string snapshot of a `TaskRecurrence?`. |
| [`_submit`](#submit) | method (`_AddTaskDialogState`) | A | Validate the title and construct/pop the new `Task`. |
| `_fmtDate` | method (`_AddTaskDialogState`) | B | Format a `DateTime` as `yyyy-MM-dd`. |
| [`_recurrenceLabel`](#recurrencelabel) | method (`_AddTaskDialogState`) | A | Map a `TaskRecurrence` to its localized display string. |
| `_showRecurrencePicker` | method (widget helper, `_AddTaskDialogState`) | B | Show `RecurrencePicker` as a bottom sheet and store the result in `_recurrence`. |

## Documentation

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **Kind:** method of `_AddTaskDialogState`
- **Source:** `lib/features/todo/widgets/add_task_dialog.dart` (line 550)
- **Purpose:** Tell `UnsavedChangesGuard` whether the form has diverged from its initial state, so
  it knows whether to prompt for confirmation before the dialog is dismissed.
- **Inputs:** None (reads instance state only).
- **Returns:** `bool` — `true` if the current form signature differs from `_initialSignature`.
- **Side effects:** None.
- **Algorithm:**
  1. Recompute the current signature via [`_signature()`](#signature).
  2. Compare it to `_initialSignature` (captured once in `initState` right after pre-filling from
     `initialTask`, or immediately as the empty-form baseline when creating a fresh task).
  3. Return whether they differ.
- **Usage:**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **Notes:** This is passed as a tear-off (`bool Function()`), not called directly, so
  `UnsavedChangesGuard` re-evaluates it on every pop attempt rather than caching a value.

### `String _signature()` <a id="signature"></a>
- **Kind:** method of `_AddTaskDialogState`
- **Source:** `lib/features/todo/widgets/add_task_dialog.dart` (lines 557-568)
- **Purpose:** Produce a single string that changes if and only if any editable field's value has
  changed, for use as the dirty-check baseline/comparison.
- **Inputs:** None (reads instance state only).
- **Returns:** `String` — the joined signature from `formSignature`
  (`lib/shared/widgets/unsaved_changes_guard.dart`).
- **Side effects:** None.
- **Algorithm:**
  1. Collect the trimmed title, trimmed note, trimmed pending-subtask text, selected `TaskType`
     name, reminder time, selected emoji, scheduled date, due date, the
     [recurrence signature](#recurrencesignature), and the full `_subtaskTitles` list into one
     ordered list of values.
  2. Delegate to the shared `formSignature(Iterable<Object?>)` helper, which maps each value to a
     canonical string and joins them with a `` (unit separator) delimiter so unrelated fields
     can never collide into an identical signature.
- **Usage:**
  ```dart
  _initialSignature = _signature();
  // ...
  bool _hasUnsavedChanges() => _signature() != _initialSignature;
  ```
- **Notes:** Because the pending (not-yet-added) subtask text is included, typing into the "add
  subtask" field without pressing enter still counts as an unsaved change.

### `String _recurrenceSignature(TaskRecurrence? recurrence)` <a id="recurrencesignature"></a>
- **Kind:** method of `_AddTaskDialogState`
- **Source:** `lib/features/todo/widgets/add_task_dialog.dart` (lines 575-583)
- **Purpose:** Normalize a `TaskRecurrence?` into a comparable string for embedding inside
  [`_signature()`](#signature).
- **Inputs:** `recurrence` — the current `TaskRecurrence?` selection, may be `null`.
- **Returns:** `String` — `''` when `recurrence` is `null`, otherwise a `formSignature` over the
  recurrence's `type.name`, `intervalDays`, `dayOfMonth`, and `monthOfYear`.
- **Side effects:** None.
- **Algorithm:**
  1. If `recurrence` is `null`, return the empty string immediately (distinct from any real
     recurrence's signature, which always contains at least the type name).
  2. Otherwise build a `formSignature` from the four fields declared on `TaskRecurrence`
     (`lib/features/todo/models/task.dart`) regardless of which ones that recurrence type actually
     uses, so switching recurrence *type* alone (even with unchanged numeric fields) still changes
     the signature.
- **Usage:**
  ```dart
  String _signature() => formSignature([
    // ...
    _recurrenceSignature(_recurrence),
    _subtaskTitles,
  ]);
  ```
- **Notes:** None.

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **Kind:** method of `_AddTaskDialogState`
- **Source:** `lib/features/todo/widgets/add_task_dialog.dart` (lines 590-629)
- **Purpose:** Validate the form and, if valid, construct the new `Task` and pop the dialog with it.
- **Inputs:** `guard` — the `UnsavedChangesController` supplied by `UnsavedChangesGuard.builder`,
  used to pop the route with a result.
- **Returns:** `None`.
- **Side effects:** Pops the dialog route via `guard.pop(task)` when the title is non-empty;
  otherwise does nothing (dialog stays open).
- **Algorithm:**
  1. Trim the title; if empty, return without popping — this is the form's only hard validation
     rule (an empty title silently blocks submission).
  2. Trim the note and the pending subtask-input text; append the pending subtask (if non-empty) to
     the already-added `_subtaskTitles` list so text typed but not explicitly "added" is not lost.
  3. If a reminder time was picked, combine it with *today's* date (`DateTime.now()`'s
     year/month/day) into a `DateTime` — the date component is a placeholder; only the
     hour/minute matter, since Todo reminders re-fire daily (see
     [Todo Reminders](../../../../features/todo.md#reminders)).
  4. Construct the `Task`: `note`/`recurrence`/`dueDate` collapse to `null` when not applicable
     (empty note, or `_selectedType == TaskType.daily`); `scheduledDate` defaults to
     `widget.defaultDate ?? DateTime.now()` for one-time tasks; `startDate` is set (from
     `widget.defaultDate ?? DateTime.now()`) only for daily-template tasks.
  5. Call `guard.pop(task)`, which pops the dialog's route with the new `Task` as the result (see
     `UnsavedChangesController.pop` in `lib/shared/widgets/unsaved_changes_guard.dart`).
- **Usage:**
  ```dart
  Future<void> _addTask() async {
    final task = await showDialog<Task>(
      context: context,
      builder: (_) => AddTaskDialog(defaultDate: _selectedDate),
    );
    if (task != null) {
      setState(() {
        if (task.type == TaskType.daily) {
          _dailyTemplates.add(task);
        } else {
          _oneTimeTasks.add(task);
        }
        _appendTaskToCustomOrderIfNeeded(task);
      });
      _saveData();
    }
  }
  ```
  (caller: `lib/features/todo/views/todo_page.dart`, `_addTask`)
- **Notes:** All persistence (adding the returned `Task` to the daily-template/one-time list and
  calling `_saveData()`) happens in the caller, not in this dialog — `_submit` only ever produces a
  `Task` value and pops.

### `String _recurrenceLabel(TaskRecurrence r, AppLocalizations l10n)` <a id="recurrencelabel"></a>
- **Kind:** method of `_AddTaskDialogState`
- **Source:** `lib/features/todo/widgets/add_task_dialog.dart` (lines 644-653)
- **Purpose:** Produce the localized one-line summary of a `TaskRecurrence` shown in the recurrence
  `ListTile`'s title when a recurrence is set.
- **Inputs:** `r` — the `TaskRecurrence` to describe; `l10n` — the current `AppLocalizations`.
- **Returns:** `String` — a localized phrase such as "Every N days", "Monthly on day N", or "Yearly
  on M/D", depending on `r.type`.
- **Side effects:** None.
- **Algorithm:** Exhaustive `switch` on `r.type` (`RecurrenceType.everyNDays` /
  `.monthlyOnDay` / `.yearlyOnMonthDay`), delegating formatting to the matching
  `AppLocalizations` getter (`todoRecurrenceEveryNDays`, `todoRecurrenceMonthlyOnDay`,
  `todoRecurrenceYearlyOnDate`) with the recurrence's `intervalDays`/`dayOfMonth`/`monthOfYear`
  fields.
- **Usage:**
  ```dart
  title: Text(
    _recurrence != null
        ? _recurrenceLabel(_recurrence!, l10n)
        : l10n.todoRecurrence,
  ),
  ```
- **Notes:** Duplicated verbatim (same switch, same three cases) in
  [`edit_task_dialog.dart`](edit_task_dialog.md#recurrencelabel) — the two dialogs do not currently
  share this helper.


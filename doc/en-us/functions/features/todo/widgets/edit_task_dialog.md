# lib/features/todo/widgets/edit_task_dialog.dart

Modal dialog for editing an existing [`Task`](../../../../features/todo.md#model) — title, note,
emoji, type, reminder, scheduled/due/completed/start dates, recurrence, and subtasks (with
drag-reorder and inline rename), plus a "permanently delete" action for already soft-deleted daily
templates (see `deletedDate` in [Todo](../../../../features/todo.md#model)). Like
[`AddTaskDialog`](add_task_dialog.md), it wraps its form in `UnsavedChangesGuard`
(`lib/shared/widgets/unsaved_changes_guard.dart`) driven by a form-signature dirty-check, and
delegates recurrence editing to [`RecurrencePicker`](recurrence_picker.md). This file duplicates
most of `add_task_dialog.dart`'s field-editing and signature/submit logic against the richer
edit-time field set (it also exposes `completedDate`/`startDate`/`deletedDate`, which
`AddTaskDialog` does not).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `EditTaskDialog` (constructor) | constructor (`EditTaskDialog`) | B | Create an edit-task dialog instance. |
| `createState` | method (`EditTaskDialog`) | B | Create the mutable `_EditTaskDialogState`. |
| `initState` | method (`_EditTaskDialogState`) | B | Copy every editable field from `widget.task` into local state and capture the initial form signature. |
| `dispose` | method (`_EditTaskDialogState`) | B | Dispose the title/note/subtask text controllers. |
| `build` | method (`_EditTaskDialogState`) | B | Render all editable fields, the completed/start/created/deleted date rows, the permanent-delete button, the reorderable subtask list, and Cancel/Save actions. |
| `_addSubtask` | method (`_EditTaskDialogState`) | B | Append the pending subtask-input text as a new `SubTask` and clear the field. |
| `_reorderSubtask` | method (`_EditTaskDialogState`) | B | Move a subtask from `oldIndex` to `newIndex` in `_subtasks`. |
| `_editSubtask` | method (`_EditTaskDialogState`) | B | Show a guarded dialog to rename one subtask's title in place. |
| `_showEmojiPicker` | method (widget helper, `_EditTaskDialogState`) | B | Show the emoji-grid bottom sheet for picking `_selectedEmoji`. |
| `_showCustomEmojiInput` | method (widget helper, `_EditTaskDialogState`) | B | Show a dialog for typing a custom emoji/character. |
| [`_recurrenceLabel`](#recurrencelabel) | method (`_EditTaskDialogState`) | A | Map a `TaskRecurrence` to its localized display string. |
| `_showRecurrencePicker` | method (widget helper, `_EditTaskDialogState`) | B | Show `RecurrencePicker` as a bottom sheet and store the result in `_recurrence`. |
| [`_hasUnsavedChanges`](#hasunsavedchanges-1) | method (`_EditTaskDialogState`) | A | Report whether the form differs from the task's original state. |
| [`_signature`](#signature-1) | method (`_EditTaskDialogState`) | A | Build a comparable string snapshot of every editable field, including subtasks. |
| [`_recurrenceSignature`](#recurrencesignature-1) | method (`_EditTaskDialogState`) | A | Build a comparable string snapshot of a `TaskRecurrence?`. |
| [`_submit`](#submit-1) | method (`_EditTaskDialogState`) | A | Validate the title and construct/pop the updated `Task`, preserving identity fields from the original. |

## Documentation

### `String _recurrenceLabel(TaskRecurrence r, AppLocalizations l10n)` <a id="recurrencelabel"></a>
- **Kind:** method of `_EditTaskDialogState`
- **Source:** `lib/features/todo/widgets/edit_task_dialog.dart` (lines 762-771)
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
- **Notes:** Byte-for-byte the same switch as
  [`add_task_dialog.dart`'s `_recurrenceLabel`](add_task_dialog.md#recurrencelabel) — the two
  dialogs do not currently share this helper.

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges-1"></a>
- **Kind:** method of `_EditTaskDialogState`
- **Source:** `lib/features/todo/widgets/edit_task_dialog.dart` (line 797)
- **Purpose:** Tell `UnsavedChangesGuard` whether the form has diverged from the task's original
  state, so it knows whether to prompt for confirmation before the dialog is dismissed.
- **Inputs:** None (reads instance state only).
- **Returns:** `bool` — `true` if the current form signature differs from `_initialSignature`.
- **Side effects:** None.
- **Algorithm:**
  1. Recompute the current signature via [`_signature()`](#signature-1).
  2. Compare it to `_initialSignature` (captured once in `initState`, immediately after copying
     every field from `widget.task`).
  3. Return whether they differ.
- **Usage:**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **Notes:** Identical structure to
  [`AddTaskDialog`'s `_hasUnsavedChanges`](add_task_dialog.md#hasunsavedchanges); the difference is
  entirely in what `_signature()` covers.

### `String _signature()` <a id="signature-1"></a>
- **Kind:** method of `_EditTaskDialogState`
- **Source:** `lib/features/todo/widgets/edit_task_dialog.dart` (lines 804-817)
- **Purpose:** Produce a single string that changes if and only if any editable field's value has
  changed from what was loaded, for use as the dirty-check baseline/comparison.
- **Inputs:** None (reads instance state only).
- **Returns:** `String` — the joined signature from `formSignature`
  (`lib/shared/widgets/unsaved_changes_guard.dart`).
- **Side effects:** None.
- **Algorithm:**
  1. Collect the trimmed title, trimmed note, trimmed pending-subtask text, selected `TaskType`
     name, reminder time, selected emoji, scheduled/completed/start/due dates, the
     [recurrence signature](#recurrencesignature-1), into one ordered list of values.
  2. Additionally map `_subtasks` to `[id, title, isCompleted]` triples per subtask, so a subtask
     rename, completion toggle, or reorder (which changes the position in the mapped iterable) is
     also detected as a change — unlike `AddTaskDialog`, which only tracks subtask *titles* because
     new subtasks there have no `id`/`isCompleted` yet.
  3. Delegate to the shared `formSignature(Iterable<Object?>)` helper, which maps each value to a
     canonical string and joins them with a unit-separator delimiter.
- **Usage:**
  ```dart
  _initialSignature = _signature();
  // ...
  bool _hasUnsavedChanges() => _signature() != _initialSignature;
  ```
- **Notes:** Reordering subtasks changes their position in the `_subtasks.map(...)` iterable and
  therefore changes the signature, even though no individual subtask's own fields changed — this is
  intentional, since `_reorderSubtask` mutates persisted order.

### `String _recurrenceSignature(TaskRecurrence? recurrence)` <a id="recurrencesignature-1"></a>
- **Kind:** method of `_EditTaskDialogState`
- **Source:** `lib/features/todo/widgets/edit_task_dialog.dart` (lines 824-832)
- **Purpose:** Normalize a `TaskRecurrence?` into a comparable string for embedding inside
  [`_signature()`](#signature-1).
- **Inputs:** `recurrence` — the current `TaskRecurrence?` selection, may be `null`.
- **Returns:** `String` — `''` when `recurrence` is `null`, otherwise a `formSignature` over the
  recurrence's `type.name`, `intervalDays`, `dayOfMonth`, and `monthOfYear`.
- **Side effects:** None.
- **Algorithm:** Same as
  [`AddTaskDialog`'s `_recurrenceSignature`](add_task_dialog.md#recurrencesignature): return `''`
  for `null`, otherwise `formSignature` all four `TaskRecurrence` fields regardless of which ones
  the current `type` actually uses.
- **Usage:**
  ```dart
  String _signature() => formSignature([
    // ...
    _recurrenceSignature(_recurrence),
    _subtasks.map((s) => [s.id, s.title, s.isCompleted]),
  ]);
  ```
- **Notes:** None.

### `void _submit(UnsavedChangesController guard)` <a id="submit-1"></a>
- **Kind:** method of `_EditTaskDialogState`
- **Source:** `lib/features/todo/widgets/edit_task_dialog.dart` (lines 839-880)
- **Purpose:** Validate the form and, if valid, construct the updated `Task` (preserving identity
  and fields not editable in this dialog) and pop the dialog with it.
- **Inputs:** `guard` — the `UnsavedChangesController` supplied by `UnsavedChangesGuard.builder`,
  used to pop the route with a result.
- **Returns:** `None`.
- **Side effects:** Pops the dialog route via `guard.pop(updated)` when the title is non-empty;
  otherwise does nothing (dialog stays open).
- **Algorithm:**
  1. Trim the title; if empty, return without popping — the form's only hard validation rule.
  2. Trim the note and the pending subtask-input text; append the pending subtask (if non-empty) as
     a new `SubTask` to the already-edited `_subtasks` list.
  3. If a reminder time is set, combine it with *today's* date into a `DateTime` (only the
     hour/minute are meaningful — see the reminder scheduling notes in
     [Todo Reminders](../../../../features/todo.md#reminders)).
  4. Construct the updated `Task`, copying `id`, `isCompleted`, `createdDate`, and `deletedDate`
     verbatim from `widget.task` (these are not editable via this form's fields);
     `note`/`recurrence`/`dueDate`/`startDate` collapse to `null` per the same
     daily-vs-one-time rule as `AddTaskDialog`; `scheduledDate` defaults to `DateTime.now()` only if
     unset for a one-time task.
  5. Call `guard.pop(updated)` to pop the dialog's route with the updated `Task` as the result.
- **Usage:**
  ```dart
  final updated = await showDialog<Task>(
    context: context,
    builder: (_) => EditTaskDialog(
      task: originalTask,
      onPermanentDelete: originalTask.deletedDate != null
          ? () {
              permanentlyDeleted = true;
              setState(() {
                _dailyTemplates.removeWhere((t) => t.id == originalTask.id);
              });
              _saveData();
            }
          : null,
    ),
  );
  ```
  (caller: `lib/features/todo/views/todo_page.dart`, `_editTask`)
- **Notes:** Unlike `AddTaskDialog._submit`, this preserves `isCompleted`/`createdDate`/
  `deletedDate` from the original task rather than defaulting them, since editing must not silently
  reset completion state, creation date, or soft-delete status.


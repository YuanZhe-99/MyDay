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
`AddTaskDialog` does not). Since v1.4.5 it shares the title-driven emoji suggestions of
`AddTaskDialog`: an [`EmojiSuggestionRow`](emoji_suggestion_row.md) under the title, auto-fill of
the icon from the best suggestion via [`_onTitleChanged`](#ontitlechanged), and a picker grid read
from the shared [`commonTaskEmojis`](../constants/task_emojis.md) instead of the private
`_commonEmojis` list this file used to carry. Editing a task that already has an emoji never
auto-fills (see [Todo — Emoji suggestions](../../../../features/todo.md#emoji-suggestions)).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `EditTaskDialog` (constructor) | constructor (`EditTaskDialog`) | B | Create an edit-task dialog instance. |
| `createState` | method (`EditTaskDialog`) | B | Create the mutable `_EditTaskDialogState`. |
| `initState` | method (`_EditTaskDialogState`) | B | Copy every editable field from `widget.task` into local state, set `_emojiPickedManually` when the task has an emoji, record the initial title in `_lastTitleText`, seed `_suggestedEmojis`, register the `_onTitleChanged` title listener, then capture the initial form signature. |
| `dispose` | method (`_EditTaskDialogState`) | B | Remove the `_onTitleChanged` listener, then dispose the title/note/subtask text controllers. |
| `build` | method (`_EditTaskDialogState`) | B | Render all editable fields (with the `EmojiSuggestionRow` under the title while there are suggestions), the completed/start/created/deleted date rows, the permanent-delete button, the reorderable subtask list, and Cancel/Save actions. |
| `_addSubtask` | method (`_EditTaskDialogState`) | B | Append the pending subtask-input text as a new `SubTask` and clear the field. |
| `_reorderSubtask` | method (`_EditTaskDialogState`) | B | Move a subtask from `oldIndex` to `newIndex` in `_subtasks`. |
| `_editSubtask` | method (`_EditTaskDialogState`) | B | Show a guarded dialog to rename one subtask's title in place. |
| [`_onTitleChanged`](#ontitlechanged) | method (`_EditTaskDialogState`) | A | Recompute emoji suggestions when the title changes and auto-fill the icon. |
| `_pickEmoji` | method (`_EditTaskDialogState`) | B | Apply a user-chosen emoji (grid, chip, custom input, or `null` for removal) and set `_emojiPickedManually`, stopping auto-fill. |
| `_showEmojiPicker` | method (widget helper, `_EditTaskDialogState`) | B | Show the bottom sheet with a `commonTaskEmojis` grid (wrapped in `Flexible` so it scrolls), a custom-emoji cell, and Remove; every choice goes through `_pickEmoji`. |
| `_showCustomEmojiInput` | method (widget helper, `_EditTaskDialogState`) | B | Show a dialog for typing a custom emoji/character; its first grapheme goes through `_pickEmoji`. |
| [`_recurrenceLabel`](#recurrencelabel) | method (`_EditTaskDialogState`) | A | Map a `TaskRecurrence` to its localized display string. |
| `_showRecurrencePicker` | method (widget helper, `_EditTaskDialogState`) | B | Show `RecurrencePicker` as a bottom sheet and store the result in `_recurrence`. |
| [`_hasUnsavedChanges`](#hasunsavedchanges-1) | method (`_EditTaskDialogState`) | A | Report whether the form differs from the task's original state. |
| [`_signature`](#signature-1) | method (`_EditTaskDialogState`) | A | Build a comparable string snapshot of every editable field, including subtasks. |
| [`_recurrenceSignature`](#recurrencesignature-1) | method (`_EditTaskDialogState`) | A | Build a comparable string snapshot of a `TaskRecurrence?`. |
| [`_submit`](#submit-1) | method (`_EditTaskDialogState`) | A | Validate the title and construct/pop the updated `Task`, preserving identity fields from the original. |

## Documentation

### `void _onTitleChanged()` <a id="ontitlechanged"></a>
- **Kind:** method of `_EditTaskDialogState` (title-controller listener)
- **Source:** `lib/features/todo/widgets/edit_task_dialog.dart` (lines 638-648)
- **Purpose:** Keep the suggestion chips in step with the title and, until the user makes a
  choice, keep the icon on the best suggestion.
- **Inputs:** None (reads `_titleController.text`, `_lastTitleText`, `_emojiPickedManually`,
  `_selectedEmoji`, and `_suggestedEmojis`).
- **Returns:** `None`.
- **Side effects:** Updates `_lastTitleText` on every real text change; calls `setState` to replace
  `_suggestedEmojis` and, while `_emojiPickedManually` is `false`, `_selectedEmoji`.
- **Algorithm:** Identical to
  [`AddTaskDialog`'s `_onTitleChanged`](add_task_dialog.md#ontitlechanged): ignore the
  notification when the text equals `_lastTitleText` (selection-only), otherwise record it;
  compute `suggestEmojis(title)`; target the current emoji if picked manually, otherwise the best
  suggestion (or `null`); skip `setState` when neither the list nor the emoji changed.
- **Usage:**
  ```dart
  _emojiPickedManually = t.emoji != null;
  _lastTitleText = _titleController.text;
  _suggestedEmojis = suggestEmojis(_titleController.text);
  _titleController.addListener(_onTitleChanged);
  _initialSignature = _signature();
  ```
  (registration in `initState`; `dispose` removes the listener before disposing the controller)
- **Notes:** `_emojiPickedManually` starts `true` when `widget.task.emoji` is set, so editing a
  task that already has an icon never replaces it — the chips still appear and can be tapped. For
  a task without an emoji, auto-fill starts with the first real edit of the title text. Opening
  the dialog, including the cursor placed when the autofocused title gains focus, never auto-fills
  or marks the form dirty; `test/task_emoji_suggestion_dialog_test.dart` covers this ("opening an
  untouched task never auto-fills or dirties it"). After a real edit, an auto-filled icon counts as
  an unsaved change because `_signature()` includes `_selectedEmoji`.

### `String _recurrenceLabel(TaskRecurrence r, AppLocalizations l10n)` <a id="recurrencelabel"></a>
- **Kind:** method of `_EditTaskDialogState`
- **Source:** `lib/features/todo/widgets/edit_task_dialog.dart` (lines 809-818)
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
- **Source:** `lib/features/todo/widgets/edit_task_dialog.dart` (line 844)
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
- **Source:** `lib/features/todo/widgets/edit_task_dialog.dart` (lines 851-864)
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
- **Source:** `lib/features/todo/widgets/edit_task_dialog.dart` (lines 871-879)
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
- **Source:** `lib/features/todo/widgets/edit_task_dialog.dart` (lines 886-927)
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


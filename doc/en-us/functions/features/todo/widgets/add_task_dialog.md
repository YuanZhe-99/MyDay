# lib/features/todo/widgets/add_task_dialog.dart

Modal dialog for creating a new [`Task`](../../../../features/todo.md#model) (or, when
`initialTask` is supplied, for prompting the user to create the *next occurrence* of a completed
recurring one-time task — see [Todo](../../../../features/todo.md#model) on
`TaskRecurrence`/`nextDate`). Wraps its form in `UnsavedChangesGuard`
(`lib/shared/widgets/unsaved_changes_guard.dart`) so navigating away with unsaved edits prompts a
discard confirmation; the guard's dirty-check is driven by a form "signature" string computed from
every editable field. Recurrence editing is delegated to
[`RecurrencePicker`](recurrence_picker.md), shown as a nested bottom sheet. Since v1.4.5 the
title field drives emoji suggestions: an [`EmojiSuggestionRow`](emoji_suggestion_row.md) under the
title shows chips from [`suggestEmojis`](../utils/emoji_suggester.md#suggestemojis), and the icon
auto-fills from the best suggestion until the user picks one (see
[`_onTitleChanged`](#ontitlechanged) and
[Todo — Emoji suggestions](../../../../features/todo.md#emoji-suggestions)). The picker grid reads
the shared [`commonTaskEmojis`](../constants/task_emojis.md); the private `_commonEmojis` list this
file used to carry was removed.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AddTaskDialog` (constructor) | constructor (`AddTaskDialog`) | B | Create an add-task dialog instance. |
| `createState` | method (`AddTaskDialog`) | B | Create the mutable `_AddTaskDialogState`. |
| `initState` | method (`_AddTaskDialogState`) | B | Pre-fill controllers/fields from `initialTask` (if editing a next-occurrence prompt), set `_emojiPickedManually` when a prefilled emoji exists, record the initial title in `_lastTitleText`, seed `_suggestedEmojis`, register the `_onTitleChanged` title listener, then capture the initial form signature. |
| `dispose` | method (`_AddTaskDialogState`) | B | Remove the `_onTitleChanged` listener, then dispose the title/note/subtask text controllers. |
| `build` | method (`_AddTaskDialogState`) | B | Render the emoji box and title field, the `EmojiSuggestionRow` under them (only while there are suggestions), the note field, type selector, reminder/scheduled/due-date/recurrence pickers, subtask list, and Cancel/Add actions. |
| `_addSubtask` | method (`_AddTaskDialogState`) | B | Append the pending subtask-input text to `_subtaskTitles` and clear the field. |
| [`_onTitleChanged`](#ontitlechanged) | method (`_AddTaskDialogState`) | A | Recompute emoji suggestions when the title changes and auto-fill the icon. |
| `_pickEmoji` | method (`_AddTaskDialogState`) | B | Apply a user-chosen emoji (grid, chip, custom input, or `null` for removal) and set `_emojiPickedManually`, stopping auto-fill. |
| `_showEmojiPicker` | method (widget helper, `_AddTaskDialogState`) | B | Show the bottom sheet with a `commonTaskEmojis` grid (wrapped in `Flexible` so it scrolls), a custom-emoji cell, and Remove; every choice goes through `_pickEmoji`. |
| `_showCustomEmojiInput` | method (widget helper, `_AddTaskDialogState`) | B | Show a dialog for typing a custom emoji/character; its first grapheme goes through `_pickEmoji`. |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | method (`_AddTaskDialogState`) | A | Report whether the form differs from its initial state. |
| [`_signature`](#signature) | method (`_AddTaskDialogState`) | A | Build a comparable string snapshot of every editable field. |
| [`_recurrenceSignature`](#recurrencesignature) | method (`_AddTaskDialogState`) | A | Build a comparable string snapshot of a `TaskRecurrence?`. |
| [`_submit`](#submit) | method (`_AddTaskDialogState`) | A | Validate the title and construct/pop the new `Task`. |
| `_fmtDate` | method (`_AddTaskDialogState`) | B | Format a `DateTime` as `yyyy-MM-dd`. |
| [`_recurrenceLabel`](#recurrencelabel) | method (`_AddTaskDialogState`) | A | Map a `TaskRecurrence` to its localized display string. |
| `_showRecurrencePicker` | method (widget helper, `_AddTaskDialogState`) | B | Show `RecurrencePicker` as a bottom sheet and store the result in `_recurrence`. |

## Documentation

### `void _onTitleChanged()` <a id="ontitlechanged"></a>
- **Kind:** method of `_AddTaskDialogState` (title-controller listener)
- **Source:** `lib/features/todo/widgets/add_task_dialog.dart` (lines 426-436)
- **Purpose:** Keep the suggestion chips in step with the title and, until the user makes a
  choice, keep the icon on the best suggestion.
- **Inputs:** None (reads `_titleController.text`, `_lastTitleText`, `_emojiPickedManually`,
  `_selectedEmoji`, and `_suggestedEmojis`).
- **Returns:** `None`.
- **Side effects:** Updates `_lastTitleText` on every real text change; calls `setState` to replace
  `_suggestedEmojis` and, while `_emojiPickedManually` is `false`, `_selectedEmoji`.
- **Algorithm:**
  1. If the title text equals `_lastTitleText`, return: the notification was selection-only (a
     cursor move, or the cursor placed when the autofocused field gains focus). Otherwise record the
     new text in `_lastTitleText`.
  2. `next = suggestEmojis(_titleController.text)`.
  3. The target emoji is the current `_selectedEmoji` if the user already picked one (or the dialog
     opened with an emoji); otherwise it is `next.firstOrNull` — the best suggestion, or `null`
     when nothing matches.
  4. If `next` equals the current suggestions (`listEquals`) and the target equals
     `_selectedEmoji`, return without calling `setState`.
  5. Otherwise store both in one `setState`.
- **Usage:**
  ```dart
  _emojiPickedManually = _selectedEmoji != null;
  _lastTitleText = _titleController.text;
  _suggestedEmojis = suggestEmojis(_titleController.text);
  _titleController.addListener(_onTitleChanged);
  _initialSignature = _signature();
  ```
  (registration in `initState`; `dispose` removes the listener before disposing the controller)
- **Notes:**
  - Auto-fill *clears* the icon when suggestions vanish, so an auto-filled emoji never outlives
    the text that produced it. A manual choice, including Remove, is never overwritten: every
    manual path calls `_pickEmoji`, which sets `_emojiPickedManually`.
  - A dialog opened with an emoji already set (an `initialTask` that has one) starts with
    `_emojiPickedManually = true` and never auto-fills. `initState` seeds the chips but does not
    auto-fill; auto-fill starts with the first real edit of the title text.
  - `TextEditingController` also notifies on selection-only changes. Step 1 ignores them, so
    opening an untouched dialog never auto-fills the icon or marks the form dirty (`_signature()`
    includes `_selectedEmoji`, so an auto-fill *after* a real edit does count as an unsaved change).
    `test/task_emoji_suggestion_dialog_test.dart` covers this ("opening an untouched task never
    auto-fills or dirties it").

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **Kind:** method of `_AddTaskDialogState`
- **Source:** `lib/features/todo/widgets/add_task_dialog.dart` (line 597)
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
- **Source:** `lib/features/todo/widgets/add_task_dialog.dart` (lines 604-615)
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
- **Source:** `lib/features/todo/widgets/add_task_dialog.dart` (lines 622-630)
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
- **Source:** `lib/features/todo/widgets/add_task_dialog.dart` (lines 637-676)
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
- **Source:** `lib/features/todo/widgets/add_task_dialog.dart` (lines 691-700)
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


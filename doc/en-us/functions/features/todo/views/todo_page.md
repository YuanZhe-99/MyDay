# lib/features/todo/views/todo_page.dart

The main Todo screen and its secondary full-month calendar page. `TodoPage`/`_TodoPageState`
render the daily/routine/work task sections, the inline week calendar, the bottom-of-list daily
score editor, and own all task/score mutation and persistence (via `TodoStorage`). Nested inside
the same file, `_TodoCalendarPage`/`_TodoCalendarPageState` is a pushed route showing a full month
grid with year/month jump controls, a monthly score trend chart (via `fl_chart`), and joyful/
suffering day lists derived from the score log; it returns a picked date to the parent page rather
than owning any data itself. See [Todo](../../../../features/todo.md) for the model/storage
concepts (`Task`, `DailyCompletionLog`, `DailyScoreLog`, sort modes/custom orders) and
[Three-Way Merge](../../../../algorithms/three-way-merge.md) for how the underlying logs merge
across devices.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `TodoPage({super.key})` | constructor (`TodoPage`) | B | Create a todo page instance. |
| `createState` | method (`TodoPage`) | B | Create the mutable state object for this widget. |
| `initState` | method (`_TodoPageState`) | B | Kick off `_loadData` and register the auto-sync listener. |
| `dispose` | method (`_TodoPageState`) | B | Unregister the auto-sync listener. |
| [`_loadData`](#loaddata) | method (`_TodoPageState`) | A | Load todo data from storage into state, or surface a read error. |
| [`_saveData`](#savedata) | method (`_TodoPageState`) | A | Persist the current in-memory todo state to storage. |
| `_syncReminders` | method (`_TodoPageState`) | B | Push current tasks/logs/reminder times to `ReminderService`. |
| `_showDailyReminderSettings` | method (`_TodoPageState`) | B | Show the morning/completion reminder time-picker bottom sheet. |
| `_isSameDay` | method (`_TodoPageState`) | B | Compare two dates ignoring time-of-day. |
| `_isToday` | getter (`_TodoPageState`) | B | Whether the selected date is today. |
| [`_selectedWeekStart`](#selectedweekstart) | method (`_TodoPageState`) | A | Return the configured first day of the selected date's week. |
| [`_selectedWeekDates`](#selectedweekdates) | method (`_TodoPageState`) | A | Return the seven dates shown in the inline week calendar. |
| [`_dailyForDate`](#dailyfordate) | getter (`_TodoPageState`) | A | Return daily templates visible on the selected date, with per-date completion overlaid. |
| `_dateOnly` | method (`_TodoPageState`) | B | Strip the time-of-day from a `DateTime`. |
| `_taskTypeKey` | method (`_TodoPageState`) | B | Map a `TaskType` to its settings-map key string. |
| `_taskSortMode` | method (`_TodoPageState`) | B | Look up the configured sort mode for a task type. |
| `_touchSettings` | method (`_TodoPageState`) | B | Stamp `_settingsModifiedAt` with the current UTC time. |
| `_tasksForType` | method (`_TodoPageState`) | B | Return all tasks (templates or one-time) of a given type. |
| `_compareText` | method (`_TodoPageState`) | B | Case-insensitive string comparator. |
| [`_compareNullableDates`](#comparenullabledates) | method (`_TodoPageState`) | A | Comparator for nullable dates, sorting nulls last. |
| [`_compareTaskFallback`](#comparetaskfallback) | method (`_TodoPageState`) | A | Deterministic tie-break comparator: created date, then title. |
| `_taskDueSortDate` | method (`_TodoPageState`) | B | Pick the best available date for due-date sorting. |
| [`_normalizedTaskOrder`](#normalizedtaskorder) | method (`_TodoPageState`) | A | Reconcile the saved custom order with the task type's current live ID set. |
| [`_sortTasksForMode`](#sorttasksformode) | method (`_TodoPageState`) | A | Sort a task list according to a sort mode (due/name/custom/created). |
| `_sortTasks` | method (`_TodoPageState`) | B | Sort a task list using the type's currently configured mode. |
| [`_appendTaskToCustomOrderIfNeeded`](#appendtasktocustomorderifneeded) | method (`_TodoPageState`) | A | Add a newly created task's ID to its type's custom order, if custom sort is active. |
| [`_removeTaskFromCustomOrders`](#removetaskfromcustomorders) | method (`_TodoPageState`) | A | Remove a deleted task's ID from every type's custom order list. |
| [`_onTaskSortModeChanged`](#ontasksortmodechanged) | method (`_TodoPageState`) | A | Handle the user switching a section's sort mode, seeding custom order if needed. |
| [`_onTaskReorder`](#ontaskreorder) | method (`_TodoPageState`) | A | Apply a drag-and-drop reorder from the visible list back onto the full custom order. |
| [`_oneTimeVisibleOnDate`](#onetimevisibleondate) | method (`_TodoPageState`) | A | Decide whether a one-time task should show on the selected date (carry-forward rule). |
| `_routineForDate` | getter (`_TodoPageState`) | B | Routine one-time tasks visible on the selected date, sorted. |
| `_workForDate` | getter (`_TodoPageState`) | B | Work one-time tasks visible on the selected date, sorted. |
| [`_dailyTemplatesForDate`](#dailytemplatesfordate) | method (`_TodoPageState`) | A | Daily templates active on an arbitrary date (startDate/deletedDate window). |
| [`_allDailyCompletedOn`](#alldailycompletedon) | method (`_TodoPageState`) | A | Whether every active daily template is completed on a date. |
| [`_allTasksCompletedOn`](#alltaskscompletedon) | method (`_TodoPageState`) | A | Whether every daily template and every visible one-time task is completed on a date. |
| [`_someDailyCompletedOn`](#somedailycompletedon) | method (`_TodoPageState`) | A | Whether a date has partial (not all, not none) daily completion. |
| [`_hasFutureScheduledOneTimeTask`](#hasfuturescheduledonetimetask) | method (`_TodoPageState`) | A | Whether a future date has a one-time task scheduled exactly on it. |
| `_showCalendar` | method (`_TodoPageState`) | B | Push `_TodoCalendarPage` and apply the date it returns. |
| `_changeDate` | method (`_TodoPageState`) | B | Shift the selected date by a number of days. |
| `_setDailyScore` | method (`_TodoPageState`) | B | Set the selected day's score and optionally save. |
| [`_toggleTask`](#toggletask) | method (`_TodoPageState`) | A | Toggle a task's completion, syncing subtasks and offering the next recurrence. |
| [`_offerNextOccurrence`](#offernextoccurrence) | method (`_TodoPageState`) | A | Prompt the user to schedule the next occurrence of a completed recurring task. |
| [`_deleteTask`](#deletetask) | method (`_TodoPageState`) | A | Delete a task, soft-deleting daily templates that aren't brand new. |
| [`_toggleSubtask`](#togglesubtask) | method (`_TodoPageState`) | A | Toggle one subtask's completion, per-date for daily tasks or directly for one-time tasks. |
| `_addTask` | method (`_TodoPageState`) | B | Show the add-task dialog and insert the created task. |
| [`_editTask`](#edittask) | method (`_TodoPageState`) | A | Show the edit-task dialog against the original (un-mapped) task and apply the result. |
| `_buildWeekCalendar` | method (widget helper) | B | Build the inline calendar for the selected date's week. |
| `_buildWeekDayCell` | method (widget helper) | B | Build one selectable day in the inline week calendar. |
| `_buildDailyScoreCard` | method (widget helper) | B | Build the score editor shown at the bottom of the todo list. |
| `build` | method (`_TodoPageState`) | B | Build the Todo page's widget subtree for the current load/error state. |
| `_TodoDataError({required this.message, required this.onRetry})` | constructor (`_TodoDataError`) | B | Show a blocking todo data read error. |
| `build` | method (`_TodoDataError`) | B | Build the blocking error view with a retry button. |
| `_TodoCalendarPage({...})` | constructor (`_TodoCalendarPage`) | B | Create the secondary Todo calendar page. |
| `createState` | method (`_TodoCalendarPage`) | B | Create the mutable state object for this widget. |
| `initState` | method (`_TodoCalendarPageState`) | B | Initialize the visible month from the selected date. |
| [`_prevMonth`](#prevmonth) | method (`_TodoCalendarPageState`) | A | Move the visible calendar to the previous month. |
| [`_nextMonth`](#nextmonth) | method (`_TodoCalendarPageState`) | A | Move the visible calendar to the next month. |
| [`_changeYear`](#changeyear) | method (`_TodoCalendarPageState`) | A | Move the visible calendar by whole years, preserving the month. |
| [`_jumpToMonth`](#jumptomonth) | method (`_TodoCalendarPageState`) | A | Jump the visible calendar to a specific month in the same year. |
| [`_monthScoreEntries`](#monthscoreentries) | getter (`_TodoCalendarPageState`) | A | Return every day and score in the visible month, missing entries as zero. |
| `_isSameDay` | method (`_TodoCalendarPageState`) | B | Compare two dates ignoring time-of-day. |
| `_pickDate` | method (`_TodoCalendarPageState`) | B | Pop the calendar route, returning the picked date. |
| `_buildMonthNavigator` | method (widget helper) | B | Build the year/month jump controls. |
| `_buildCalendarCard` | method (widget helper) | B | Build the month calendar grid and legend. |
| `_buildCalendarDayCell` | method (widget helper) | B | Build one date cell inside the month calendar. |
| [`_buildScoreTrendCard`](#buildscoretrendcard) | method (widget helper) | A | Build the monthly daily-score line chart, including its plotted-point data. |
| [`_buildScoreListsCard`](#buildscorelistscard) | method (widget helper) | A | Filter the visible month's entries into joyful/suffering day lists and render them. |
| `_buildScoreDaySection` | method (widget helper) | B | Render one already-filtered extreme-score date list section. |
| `build` | method (`_TodoCalendarPageState`) | B | Build the calendar page's widget subtree. |
| `_CalendarLegendItem({...})` | constructor (`_CalendarLegendItem`) | B | Create a compact calendar legend item. |
| `build` | method (`_CalendarLegendItem`) | B | Build the legend item's icon-plus-label row. |

## Documentation

### `Future<void> _loadData()` <a id="loaddata"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 92)
- **Purpose:** Load todo data from `TodoStorage` into state, or record a read error without losing any prior in-memory data.
- **Inputs:** None (reads from `TodoStorage.load()`).
- **Returns:** `Future<void>`.
- **Side effects:** Toggles `_loaded` to show a loading state; on failure, resets `ReminderService` to empty data and sets `_loadError`; on success, replaces every piece of todo state (`_dailyTemplates`, `_oneTimeTasks`, `_dailyLog`, `_dailyScores`, sort modes/custom orders, reminder times, `_settingsModifiedAt`) and calls `_syncReminders()`.
- **Algorithm:**
  1. If already loaded, flip `_loaded` to `false` via `setState` to show the loading UI.
  2. Call `TodoStorage.load()` inside a `try/catch`.
  3. On exception: reset `ReminderService` to empty daily templates/one-time tasks/log, bail out if unmounted, otherwise store `e.toString()` in `_loadError`, set `_loaded = true`, and return — existing (previously loaded) in-memory data is left untouched, so an unreadable file is never silently treated as "no tasks."
  4. On success: bail out if unmounted, otherwise clear `_loadError` and, if `data` is non-null, copy every field of `TodoData` into local state (deep-copying the sort-mode/custom-order maps), converting the stored reminder hour/minute pair back into a `TimeOfDay` when both are present.
  5. Set `_loaded = true` and call `_syncReminders()` to push the freshly loaded data to `ReminderService`.
- **Usage:**
  ```dart
  @override
  void initState() {
    super.initState();
    _loadData();
    AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  }
  ```
- **Notes:** Because `_loadError` is only cleared on a successful load, `_saveData` refuses to write while a previous load failed — this is what keeps a broken file from being overwritten with incomplete state.

### `Future<void> _saveData()` <a id="savedata"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 151)
- **Purpose:** Persist the current in-memory todo state to `TodoStorage`, unless loading hasn't finished or the last load failed.
- **Inputs:** None (reads current state fields).
- **Returns:** `Future<void>`.
- **Side effects:** Writes `todo_data.json` via `TodoStorage.save`; may show a `SnackBar`; calls `_syncReminders()` and `AutoSyncService.instance.notifySaved()` on success.
- **Algorithm:**
  1. If `_loaded` is still `false`, return immediately (nothing to save yet).
  2. If `_loadError` is non-null, show a `todoDataWriteBlocked` snackbar (if mounted) and return without writing — this is the guard that prevents clobbering a file that failed to parse.
  3. Otherwise build a `TodoData` from every current in-memory field and await `TodoStorage.save(...)`.
  4. Call `_syncReminders()` and `AutoSyncService.instance.notifySaved()` to propagate the change to the reminder scheduler and the sync subsystem.
- **Usage:**
  ```dart
  void _changeDate(int delta) { ... } // sibling caller pattern
  // Typical call site, e.g. after toggling a task:
  _toggleTask(task); // internally ends with: _saveData();
  ```
- **Notes:** None beyond the load-error guard described above; every mutating action in this file (`_toggleTask`, `_deleteTask`, `_toggleSubtask`, `_addTask`, `_editTask`, `_onTaskSortModeChanged`, `_onTaskReorder`, `_setDailyScore`) calls this after updating state.

### `DateTime _selectedWeekStart(int weekStartDay)` <a id="selectedweekstart"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 338)
- **Purpose:** Return the first day of the week that contains `_selectedDate`, honoring the app's configurable week-start day.
- **Inputs:** `weekStartDay` — the globally configured first weekday, using Dart's Monday=1..Sunday=7 numbering.
- **Returns:** The `DateTime` (time stripped) of the first day of that week.
- **Side effects:** None.
- **Algorithm:** Delegates entirely to the shared `startOfWeek(_selectedDate, weekStartDay: weekStartDay)` helper in `lib/shared/utils/week_grouping.dart`, which strips time-of-day and subtracts `(date.weekday - weekStartDay + 7) % 7` days.
- **Usage:**
  ```dart
  List<DateTime> _selectedWeekDates(int weekStartDay) {
    final weekStart = _selectedWeekStart(weekStartDay);
    return [for (var i = 0; i < 7; i++) weekStart.add(Duration(days: i))];
  }
  ```
- **Notes:** Because the modulo arithmetic is in the shared helper, this file never special-cases which day is configured as first — the same code path handles any `weekStartDay` value 1-7.

### `List<DateTime> _selectedWeekDates(int weekStartDay)` <a id="selectedweekdates"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 346)
- **Purpose:** Return the seven dates shown as day cells in the inline week calendar.
- **Inputs:** `weekStartDay` — the configured first weekday, forwarded to `_selectedWeekStart`.
- **Returns:** `List<DateTime>` of exactly seven consecutive dates starting at `_selectedWeekStart(weekStartDay)`.
- **Side effects:** None.
- **Algorithm:** Computes the week start via `_selectedWeekStart`, then builds a 7-element list by adding `Duration(days: i)` for `i` in `0..6`.
- **Usage:**
  ```dart
  for (final date in _selectedWeekDates(weekStartDay))
    _buildWeekDayCell(date, theme, l10n),
  ```
- **Notes:** The list always reflects the selected date's own week — changing `_selectedDate` recomputes it on next build, it is not cached.

### `List<Task> get _dailyForDate` <a id="dailyfordate"></a>
- **Kind:** getter of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 358)
- **Purpose:** Return the daily task templates visible on the selected date, with each template's completion and subtask-completion state overlaid from the per-date log.
- **Inputs:** None (reads `_dailyTemplates`, `_dailyLog`, `_selectedDate`).
- **Returns:** `List<Task>`, sorted per the daily section's current sort mode.
- **Side effects:** None (pure read; the returned `Task` copies are display-only).
- **Algorithm:**
  1. Filter `_dailyTemplates` to those where `startDate ?? createdDate` is not after the selected date, and `deletedDate` is either null or strictly after the selected date (soft-deleted templates keep showing up to and including their deletion date).
  2. For each surviving template, look up whether it's completed on the selected date via `_dailyLog.isCompleted`, and map each subtask's completion from `_dailyLog.isSubtaskCompleted`.
  3. Only allocate a new `Task` copy (`copyWith`) when the mapped completion/subtask state actually differs from the template's own fields, to avoid needless object churn.
  4. Sort the resulting list with `_sortTasks(list, TaskType.daily)`.
- **Usage:**
  ```dart
  TaskSection(
    tasks: _dailyForDate,
    ...
  )
  ```
- **Notes:** This is the daily-task analogue of `_dailyTemplatesForDate` (used by the calendar helpers) but additionally overlays per-date completion state, which the calendar helpers don't need.

### `int _compareNullableDates(DateTime? a, DateTime? b)` <a id="comparenullabledates"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 440)
- **Purpose:** Comparator for two optional dates, treating a missing date as "latest" so tasks without a due-relevant date sort after those with one.
- **Inputs:** `a`, `b` — nullable `DateTime`s.
- **Returns:** `int` — negative/zero/positive per `Comparable` conventions.
- **Side effects:** None.
- **Algorithm:** Returns `0` if both are null, `1` if only `a` is null (so `a` sorts after `b`), `-1` if only `b` is null, otherwise `a.compareTo(b)`.
- **Usage:**
  ```dart
  final byDate = _compareNullableDates(_taskDueSortDate(a), _taskDueSortDate(b));
  return byDate != 0 ? byDate : _compareTaskFallback(a, b);
  ```
- **Notes:** Used only by the due-date sort mode inside `_sortTasksForMode`.

### `int _compareTaskFallback(Task a, Task b)` <a id="comparetaskfallback"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 452)
- **Purpose:** Provide a deterministic tie-breaking order for tasks that compare equal on the active sort key.
- **Inputs:** `a`, `b` — `Task`s.
- **Returns:** `int` comparator result.
- **Side effects:** None.
- **Algorithm:** Compares `createdDate` first; if equal, falls back to case-insensitive title comparison via `_compareText`.
- **Usage:**
  ```dart
  case _taskSortCreated:
  default:
    list.sort(_compareTaskFallback);
  ```
- **Notes:** Every branch of `_sortTasksForMode` (due, name, custom) uses this as its final tie-breaker, so sort order is always fully deterministic even when many tasks share a due date, name, or custom-order position.

### `List<String> _normalizedTaskOrder(TaskType type)` <a id="normalizedtaskorder"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 471)
- **Purpose:** Reconcile the saved custom-order ID list for a task type against that type's current live task IDs — dropping IDs for deleted tasks and appending IDs for tasks not yet in the saved order.
- **Inputs:** `type` — the `TaskType` whose order to normalize.
- **Returns:** `List<String>` of task IDs, each appearing exactly once.
- **Side effects:** None (does not mutate `_taskCustomOrders`; callers decide whether to store the result back).
- **Algorithm:**
  1. Collect all current task IDs for `type` via `_tasksForType` into a set (`allIdSet`).
  2. Walk the saved custom order (`_taskCustomOrders[key]`, or empty), keeping only IDs that are still live (`allIdSet.contains(id)`) and not already emitted (`seen.add(id)` dedupes).
  3. Append any remaining live IDs not already seen, in their natural (created-date) order, so newly created tasks land at the end.
- **Usage:**
  ```dart
  final order = _normalizedTaskOrder(type);
  final fallbackIndex = order.length;
  list.sort((a, b) {
    final ai = order.indexOf(a.id);
    final bi = order.indexOf(b.id);
    ...
  });
  ```
- **Notes:** This is what makes custom order resilient to task deletion (stale IDs silently drop out) and task creation (new IDs silently append) without ever needing an explicit migration step.

### `List<Task> _sortTasksForMode(List<Task> tasks, TaskType type, String mode)` <a id="sorttasksformode"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 491)
- **Purpose:** Sort a list of tasks according to an explicit sort mode, independent of what mode is currently configured for the type.
- **Inputs:** `tasks` — the list to sort (copied, not mutated in place); `type` — used only for the custom-order branch; `mode` — one of `_taskSortDue`, `_taskSortName`, `_taskSortCustom`, `_taskSortCreated`.
- **Returns:** A new sorted `List<Task>`.
- **Side effects:** None.
- **Algorithm:** Copies the input list, then switches on `mode`:
  1. **Due** (`_taskSortDue`): sort by `_compareNullableDates(_taskDueSortDate(a), _taskDueSortDate(b))`, falling back to `_compareTaskFallback`.
  2. **Name** (`_taskSortName`): sort by `_compareText(a.title, b.title)`, falling back to `_compareTaskFallback`.
  3. **Custom** (`_taskSortCustom`): compute `_normalizedTaskOrder(type)`; for each task, its sort key is its index in that order (or `order.length` — sorts last — if absent), falling back to `_compareTaskFallback` on ties.
  4. **Created** (`_taskSortCreated`) or any other value: sort directly by `_compareTaskFallback`.
- **Usage:**
  ```dart
  List<Task> _sortTasks(List<Task> tasks, TaskType type) =>
      _sortTasksForMode(tasks, type, _taskSortMode(type));
  ```
- **Notes:** Called both by `_sortTasks` (using the type's live configured mode) and directly by `_onTaskSortModeChanged` (using an explicit `currentMode` to seed the custom order before switching to it).

### `void _appendTaskToCustomOrderIfNeeded(Task task)` <a id="appendtasktocustomorderifneeded"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 538)
- **Purpose:** Keep a task type's saved custom order in sync when a task is created while custom sort is active for that type.
- **Inputs:** `task` — the newly created `Task`.
- **Returns:** None.
- **Side effects:** Mutates `_taskCustomOrders[key]` and calls `_touchSettings()` when the task's type is currently sorted by `_taskSortCustom`; no-op otherwise.
- **Algorithm:** If `_taskSortMode(task.type) != _taskSortCustom`, do nothing. Otherwise recompute and store `_normalizedTaskOrder(task.type)` (which will now include the new task's ID because it exists in the live task set) and call `_touchSettings()`.
- **Usage:**
  ```dart
  setState(() {
    if (task.type == TaskType.daily) {
      _dailyTemplates.add(task);
    } else {
      _oneTimeTasks.add(task);
    }
    _appendTaskToCustomOrderIfNeeded(task);
  });
  _saveData();
  ```
- **Notes:** Called from `_addTask` and `_offerNextOccurrence` (recurrence follow-up task creation) — both places that add a task outside of `_editTask`.

### `void _removeTaskFromCustomOrders(String taskId)` <a id="removetaskfromcustomorders"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 551)
- **Purpose:** Remove a deleted task's ID from every task type's saved custom order, not just its own type's.
- **Inputs:** `taskId` — the ID being removed.
- **Returns:** None.
- **Side effects:** May mutate every list in `_taskCustomOrders`; calls `_touchSettings()` if anything actually changed.
- **Algorithm:** Iterates all entries of `_taskCustomOrders`, calling `.remove(taskId)` on each list and OR-ing the boolean results into `changed`; calls `_touchSettings()` only if at least one list actually contained the ID.
- **Usage:**
  ```dart
  } else {
    _removeTaskFromCustomOrders(task.id);
    _oneTimeTasks.removeWhere((t) => t.id == task.id);
  }
  ```
- **Notes:** Iterating every type's order list (rather than only the deleted task's own type) is defensive — it guarantees no stale ID can survive under any type key.

### `void _onTaskSortModeChanged(TaskType type, String mode)` <a id="ontasksortmodechanged"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 564)
- **Purpose:** Handle the user picking a new sort mode for one section, seeding a stable custom order the first time custom sort is selected.
- **Inputs:** `type` — the section's `TaskType`; `mode` — the newly selected sort mode string.
- **Returns:** None.
- **Side effects:** Updates `_taskSortModes[key]`, may populate/refresh `_taskCustomOrders[key]`, calls `_touchSettings()` and `_saveData()`.
- **Algorithm:**
  1. Read the type's current mode before switching.
  2. If the new mode is custom and there is no saved order yet for this type, seed `_taskCustomOrders[key]` by sorting the type's current live tasks under the *old* mode (via `_sortTasksForMode`) and taking their IDs in that order — so switching to custom order for the first time preserves whatever order was already visible.
  3. Store the new mode in `_taskSortModes[key]`.
  4. If the new mode is custom (including when an order already existed), refresh it through `_normalizedTaskOrder(type)` to reconcile against live tasks.
  5. Call `_touchSettings()` inside `setState`, then `_saveData()` after.
- **Usage:**
  ```dart
  onSortModeChanged: (mode) =>
      _onTaskSortModeChanged(TaskType.daily, mode),
  ```
- **Notes:** Step 2 is what makes the first switch to custom order feel like "freezing" the current view instead of resetting to creation order.

### `void _onTaskReorder(TaskType type, List<Task> visibleTasks, int oldIndex, int newIndex)` <a id="ontaskreorder"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 589)
- **Purpose:** Apply a drag-and-drop reorder performed on the currently visible (filtered) task list back onto the type's full saved custom order, which may contain more IDs than are currently visible.
- **Inputs:** `type`; `visibleTasks` — the list actually shown (and dragged) in the UI; `oldIndex`/`newIndex` — Flutter `ReorderableListView` indices.
- **Returns:** None.
- **Side effects:** Mutates `_taskCustomOrders[key]`, forces sort mode to `_taskSortCustom` for `type`, calls `_touchSettings()` and `_saveData()`.
- **Algorithm:**
  1. Adjust `newIndex` per Flutter's `ReorderableListView` convention (decrement if it moved past the removed item).
  2. Bounds-check `oldIndex`/`newIndex` against `visibleIds.length`; return if out of range.
  3. Build `reorderedVisible`: remove the dragged ID from `oldIndex` and reinsert it at `newIndex`, on a copy of just the visible IDs.
  4. Recompute the full normalized order, then rebuild it by walking the full order and, for each ID that's part of the visible set, substituting the next ID from `reorderedVisible` in sequence (via `replacementIndex`); IDs not in the visible set (e.g. hidden by a filter) keep their existing relative position untouched.
  5. Force `_taskSortModes[key] = _taskSortCustom` (dragging always switches the section to custom sort) and call `_touchSettings()`.
- **Usage:**
  ```dart
  onReorder: (oldIndex, newIndex) =>
      _onTaskReorder(TaskType.daily, _dailyForDate, oldIndex, newIndex),
  ```
- **Notes:** The interleaving in step 4 is the key trick that lets a drag performed on a filtered/visible subset update the right positions in the full order without disturbing IDs the user couldn't see or drag.

### `bool _oneTimeVisibleOnDate(Task t)` <a id="onetimevisibleondate"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 634)
- **Purpose:** Decide whether a one-time (routine/work) task should be shown on the currently selected date.
- **Inputs:** `t` — the one-time `Task` to test.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:**
  1. If `t.scheduledDate` is null, it's never visible (return `false`).
  2. If the task is completed and has a `completedDate`: visible only if the selected date equals `scheduledDate` OR equals `completedDate` — i.e. it disappears from the days strictly between being scheduled and being completed.
  3. If not completed: visible if the selected date equals `scheduledDate` (even if in the future), or if `scheduledDate` is on/before the selected date AND the selected date is on/before today — this is the "carry forward" rule that keeps overdue incomplete tasks showing every day until done or until they're in the future.
- **Usage:**
  ```dart
  List<Task> get _routineForDate {
    final list = _oneTimeTasks
        .where((t) => t.type == TaskType.routineOnce && _oneTimeVisibleOnDate(t))
        .toList();
    return _sortTasks(list, TaskType.routineOnce);
  }
  ```
- **Notes:** This exact same completed/carry-forward logic is re-implemented inline (not by calling this method) inside `_allTasksCompletedOn`, since that method needs the same visibility rule plus a completion check in one pass.

### `List<Task> _dailyTemplatesForDate(DateTime date)` <a id="dailytemplatesfordate"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 685)
- **Purpose:** Return the daily templates active on an arbitrary date (not necessarily the selected date), respecting `startDate`/`deletedDate`.
- **Inputs:** `date` — any `DateTime`.
- **Returns:** `List<Task>` of daily templates (without completion state overlaid).
- **Side effects:** None.
- **Algorithm:** Filters `_dailyTemplates` to those where `startDate ?? createdDate` is not after `date`, and `deletedDate` is null or strictly after `date` — the same window rule as `_dailyForDate`'s filter step, but reusable for any date (used by the calendar's completion-marker helpers).
- **Usage:**
  ```dart
  bool _allDailyCompletedOn(DateTime date) {
    final templates = _dailyTemplatesForDate(date);
    if (templates.isEmpty) return false;
    ...
  ```
- **Notes:** Unlike `_dailyForDate`, this never overlays per-date completion — it's purely "which templates existed and weren't deleted yet on this date," used as an input to the `_...CompletedOn` family.

### `bool _allDailyCompletedOn(DateTime date)` <a id="alldailycompletedon"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 699)
- **Purpose:** Report whether every daily template active on `date` is marked completed for that date.
- **Inputs:** `date`.
- **Returns:** `bool` — `false` if there are no active templates that day.
- **Side effects:** None.
- **Algorithm:** Gets active templates via `_dailyTemplatesForDate(date)`; returns `false` immediately if empty; otherwise loops the templates and returns `false` on the first one not completed in `_dailyLog`, else `true`.
- **Usage:**
  ```dart
  _TodoCalendarPage(
    ...
    allDailyCompleted: _allDailyCompletedOn,
    ...
  )
  ```
- **Notes:** Passed by reference into `_TodoCalendarPage` so the calendar grid can compute completion markers per day without the calendar page holding any task data itself.

### `bool _allTasksCompletedOn(DateTime date)` <a id="alltaskscompletedon"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 713)
- **Purpose:** Report whether every daily template and every one-time task visible on `date` is completed — the strongest "fully done day" signal used for the calendar's checkmark.
- **Inputs:** `date`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:**
  1. Short-circuit `false` if `_allDailyCompletedOn(date)` is `false`.
  2. For every one-time task with a `scheduledDate`, recompute its visibility on `date` inline (same completed/carry-forward rule as `_oneTimeVisibleOnDate`, reimplemented against an explicit `date` parameter rather than `_selectedDate`).
  3. If a task is visible on `date` and not completed, return `false` immediately.
  4. Return `true` if nothing failed the check.
- **Usage:**
  ```dart
  allTasksCompleted: _allTasksCompletedOn,
  ```
- **Notes:** Duplicates `_oneTimeVisibleOnDate`'s logic against an arbitrary `date` instead of `_selectedDate` because that getter is hard-coded to the selected date; see that entry's Notes.

### `bool _someDailyCompletedOn(DateTime date)` <a id="somedailycompletedon"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 737)
- **Purpose:** Detect a "partially done" day — at least one but not all active daily templates completed — for the calendar's partial-progress marker.
- **Inputs:** `date`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** Gets active templates via `_dailyTemplatesForDate(date)`, returns `false` if none; otherwise loops setting `anyDone`/`allDone` flags per template's completion, and returns `anyDone && !allDone` (a day where all are done is reported by `_allDailyCompletedOn`, not this method).
- **Usage:**
  ```dart
  someDailyCompleted: _someDailyCompletedOn,
  ```
- **Notes:** None.

### `bool _hasFutureScheduledOneTimeTask(DateTime date)` <a id="hasfuturescheduledonetimetask"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 757)
- **Purpose:** Check whether a future calendar date has a one-time (routine/work) task scheduled exactly on it, to show a small "upcoming" marker.
- **Inputs:** `date`.
- **Returns:** `bool` — always `false` for dates that are today or in the past.
- **Side effects:** None.
- **Algorithm:** Returns `false` immediately if `date` is not after today. Otherwise checks whether any one-time task (excluding `TaskType.daily` and tasks without a `scheduledDate`) has `scheduledDate` exactly equal (day-only) to `date`.
- **Usage:**
  ```dart
  hasFutureScheduledOneTimeTask: _hasFutureScheduledOneTimeTask,
  ```
- **Notes:** Deliberately ignores daily templates and carried-forward overdue one-time tasks — it only flags tasks *newly* scheduled to start on that exact future date.

### `void _toggleTask(Task task)` <a id="toggletask"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 826)
- **Purpose:** Toggle a task's completion state, keeping its subtasks in sync and, for a completing recurring one-time task, offering to schedule the next occurrence.
- **Inputs:** `task` — the `Task` being toggled (as currently displayed, which for daily tasks is the per-date-mapped copy, not the raw template).
- **Returns:** None.
- **Side effects:** Mutates `_dailyLog` or `_oneTimeTasks`; calls `_saveData()`; may schedule a post-frame callback into `_offerNextOccurrence`.
- **Algorithm:**
  1. **Daily task:** toggle per-date completion in `_dailyLog.toggle(_selectedDate, task.id)`, look up the live template (falling back to `task` if not found) and, if it has subtasks, bulk-set every subtask's per-date completion to match the template's new completion state via `_dailyLog.setSubtasksCompleted`.
  2. **One-time task:** find its index in `_oneTimeTasks`; flip `isCompleted`; map every subtask's `isCompleted` to the same new value; reconstruct the `Task` via its full constructor (not `copyWith`) specifically so `completedDate` can be set to `null` when un-completing (`copyWith` can't clear a field back to null); if the task is newly completing and has a `recurrence`, stash the updated task in `completedWithRecurrence`.
  3. After `setState`, call `_saveData()`.
  4. If a recurring task was just completed, schedule `_offerNextOccurrence` on the next frame (`addPostFrameCallback`) so the dialog opens after the current build settles, guarded by `mounted`.
- **Usage:**
  ```dart
  TaskSection(
    ...
    onToggle: _toggleTask,
    ...
  )
  ```
- **Notes:** The full-constructor rebuild in step 2 is a deliberate workaround — `Task.copyWith` (per the model) cannot set a nullable field back to `null`, which this code needs when un-completing a task clears its `completedDate`.

### `Future<void> _offerNextOccurrence(Task completedTask)` <a id="offernextoccurrence"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 893)
- **Purpose:** After a recurring one-time task is completed, compute its next occurrence date and let the user confirm/edit and create that follow-up task.
- **Inputs:** `completedTask` — the just-completed `Task`, which must have a non-null `recurrence`.
- **Returns:** `Future<void>`.
- **Side effects:** May add a new `Task` to `_oneTimeTasks`, call `_appendTaskToCustomOrderIfNeeded`, and `_saveData()`; shows the `AddTaskDialog`.
- **Algorithm:**
  1. Compute `nextDate` via `completedTask.recurrence!.nextDate(completedTask.scheduledDate ?? completedTask.createdDate)`.
  2. Build a prefilled `nextTask` (same title/note/emoji/type/reminder/recurrence, subtasks reset to uncompleted, `scheduledDate: nextDate`).
  3. Show `AddTaskDialog` pre-populated with `nextTask` and titled via `l10n.todoNextOccurrence`, awaiting the user's (possibly edited) result.
  4. If the user confirmed (returned a non-null task) and the widget is still mounted, add it to `_oneTimeTasks`, run `_appendTaskToCustomOrderIfNeeded`, and save.
- **Usage:**
  ```dart
  if (completedWithRecurrence != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _offerNextOccurrence(completedWithRecurrence!);
    });
  }
  ```
- **Notes:** The exact recurrence-interval math (`nextDate`) lives on `TaskRecurrence` in the model, not here — see [Todo](../../../../features/todo.md#model).

### `void _deleteTask(Task task)` <a id="deletetask"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 932)
- **Purpose:** Delete a task, using a hard delete for one-time tasks and for daily templates created on the currently selected date, but a soft delete (stamping `deletedDate`) for older daily templates so historical completion logs stay meaningful.
- **Inputs:** `task` — the `Task` to delete.
- **Returns:** None.
- **Side effects:** Mutates `_dailyTemplates` or `_oneTimeTasks`; may call `_removeTaskFromCustomOrders`; calls `_saveData()`.
- **Algorithm:**
  1. **Daily task:** find its index in `_dailyTemplates`. Compare `start = startDate ?? createdDate` against the selected date (day-only). If they're the same day, the template was created today and never had any history, so remove it entirely and clean up its custom-order entries. Otherwise, soft-delete by setting `deletedDate: _selectedDate` via `copyWith`, leaving the template in the list (so past completion logs referencing it still resolve).
  2. **One-time task:** remove its custom-order entries and remove it outright from `_oneTimeTasks` by ID.
  3. Call `_saveData()`.
- **Usage:**
  ```dart
  TaskSection(
    ...
    onDelete: _deleteTask,
    ...
  )
  ```
- **Notes:** This is the concrete implementation of the "daily templates are never hard-deleted [after their start day]" rule described in [Todo](../../../../features/todo.md#model).

### `void _toggleSubtask(Task task, SubTask subtask)` <a id="togglesubtask"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 962)
- **Purpose:** Toggle one subtask's completion, using per-date logging for daily tasks and direct mutation for one-time tasks.
- **Inputs:** `task` — the parent `Task`; `subtask` — the `SubTask` being toggled.
- **Returns:** None.
- **Side effects:** Mutates `_dailyLog` or the matching entry in `_oneTimeTasks`; calls `_saveData()`.
- **Algorithm:**
  1. **Daily task:** call `_dailyLog.toggleSubtask(_selectedDate, subtask.id)` — completion is tracked per date, not on the template itself.
  2. **One-time task:** find the task's index in `_oneTimeTasks` (return early if not found); map its subtasks, flipping `isCompleted` only on the matching subtask ID; write the updated subtask list back via `copyWith`.
  3. Call `_saveData()`.
- **Usage:**
  ```dart
  onSubtaskToggle: _toggleSubtask,
  ```
- **Notes:** Unlike `_toggleTask`, this does not attempt to auto-complete the parent task when all subtasks are done — subtask and parent completion are tracked independently.

### `Future<void> _editTask(Task task)` <a id="edittask"></a>
- **Kind:** method of `_TodoPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 1013)
- **Purpose:** Open the edit-task dialog against the real (un-mapped) underlying task, offering a permanent-delete option for soft-deleted daily templates, and apply whatever the dialog returns.
- **Inputs:** `task` — the displayed `Task` (for daily tasks, this may be the per-date-mapped copy from `_dailyForDate`, not the stored template).
- **Returns:** `Future<void>`.
- **Side effects:** May remove from `_dailyTemplates` (permanent delete) or replace an entry in `_dailyTemplates`/`_oneTimeTasks` (normal edit); calls `_saveData()` in either case.
- **Algorithm:**
  1. Resolve `originalTask`: for daily tasks, look up the real template in `_dailyTemplates` by ID (falling back to `task` if not found) so the dialog edits the un-mapped source of truth rather than a per-date display copy.
  2. Build an `onPermanentDelete` callback only if `originalTask.deletedDate != null` (i.e. it's a soft-deleted daily template) — invoking it sets `permanentlyDeleted = true`, removes the template from `_dailyTemplates`, and saves.
  3. Show `EditTaskDialog` with `originalTask` and that optional callback; await its result.
  4. If the dialog returned an updated task and it wasn't permanently deleted via the callback, replace the matching entry in `_dailyTemplates` or `_oneTimeTasks` (by ID) and save.
- **Usage:**
  ```dart
  onEdit: _editTask,
  ```
- **Notes:** Steps 2-4 are mutually exclusive outcomes of a single dialog invocation — either the user permanently deletes (via the dialog's own delete option) or edits and saves normally, never both.

### `void _prevMonth()` <a id="prevmonth"></a>
- **Kind:** method of `_TodoCalendarPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 1583)
- **Purpose:** Move the visible calendar month back by one.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Updates `_viewMonth` via `setState`.
- **Algorithm:** Sets `_viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1)`. Dart's `DateTime` constructor normalizes an out-of-range month, so stepping back from January (`month - 1 == 0`) automatically rolls to December of the previous year with no explicit year arithmetic needed.
- **Usage:**
  ```dart
  IconButton(
    icon: const Icon(Icons.chevron_left),
    onPressed: _prevMonth,
  ),
  ```
- **Notes:** Relies on the same automatic month/year normalization as `_nextMonth`; there is no manual `if (month == 0)` branch anywhere in this file.

### `void _nextMonth()` <a id="nextmonth"></a>
- **Kind:** method of `_TodoCalendarPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 1594)
- **Purpose:** Move the visible calendar month forward by one.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Updates `_viewMonth` via `setState`.
- **Algorithm:** Sets `_viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1)`, relying on `DateTime`'s automatic rollover (`month == 13` becomes January of the next year).
- **Usage:**
  ```dart
  IconButton(
    icon: const Icon(Icons.chevron_right),
    onPressed: _nextMonth,
  ),
  ```
- **Notes:** See `_prevMonth`; both directions depend on the same constructor normalization rather than explicit branching.

### `void _changeYear(int delta)` <a id="changeyear"></a>
- **Kind:** method of `_TodoCalendarPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 1605)
- **Purpose:** Move the visible calendar by whole years while keeping the same visible month.
- **Inputs:** `delta` — signed year offset (the UI only ever passes `-1`/`1`).
- **Returns:** None.
- **Side effects:** Updates `_viewMonth` via `setState`.
- **Algorithm:** Sets `_viewMonth = DateTime(_viewMonth.year + delta, _viewMonth.month)`, preserving the month component exactly.
- **Usage:**
  ```dart
  onPressed: () => _changeYear(-1),
  ...
  onPressed: () => _changeYear(1),
  ```
- **Notes:** None.

### `void _jumpToMonth(int month)` <a id="jumptomonth"></a>
- **Kind:** method of `_TodoCalendarPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 1616)
- **Purpose:** Jump the visible calendar directly to a specific month within the currently visible year.
- **Inputs:** `month` — 1-12 (Dart month numbering).
- **Returns:** None.
- **Side effects:** Updates `_viewMonth` via `setState`.
- **Algorithm:** Sets `_viewMonth = DateTime(_viewMonth.year, month)` — the year is left as-is, only the month changes.
- **Usage:**
  ```dart
  onSelected: (_) => _jumpToMonth(month),
  ```
- **Notes:** Used by the inline month-picker menu built in `_buildMonthNavigator`; unlike `_prevMonth`/`_nextMonth` there is no rollover concern since `month` is always a valid 1-12 value coming from that menu.

### `List<MapEntry<DateTime, int>> get _monthScoreEntries` <a id="monthscoreentries"></a>
- **Kind:** getter of `_TodoCalendarPageState`
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 1627)
- **Purpose:** Return every calendar day in the visible month paired with its score, treating any day with no saved score entry as zero — the single data source feeding both the score trend chart and the joyful/suffering day lists.
- **Inputs:** None (reads `_viewMonth`, `widget.dailyScores`).
- **Returns:** `List<MapEntry<DateTime, int>>`, one entry per day of `_viewMonth`, in day-of-month order.
- **Side effects:** None.
- **Algorithm:** Computes the month's day count via `DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day` (day 0 of next month = last day of this month), then builds one `MapEntry` per day from 1 to that count, looking up each day's score via `widget.dailyScores.scoreFor(...)` (which returns 0 for missing entries).
- **Usage:**
  ```dart
  Widget _buildScoreTrendCard(ThemeData theme, AppLocalizations l10n) {
    final entries = _monthScoreEntries;
    final spots = entries.map(
      (entry) => FlSpot(entry.key.day.toDouble(), entry.value.toDouble()),
    ).toList();
    ...
  ```
- **Notes:** Because every day is always included (missing entries as zero rather than omitted), both consuming widgets never need to special-case gaps in the score log.

### `Widget _buildScoreTrendCard(ThemeData theme, AppLocalizations l10n)` <a id="buildscoretrendcard"></a>
- **Kind:** method of `_TodoCalendarPageState` (widget helper)
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 1913)
- **Purpose:** Build the monthly daily-score trend line chart, including converting the month's score entries into chart-plottable data.
- **Inputs:** `theme`, `l10n`.
- **Returns:** A `Card` containing an `fl_chart` `LineChart`.
- **Side effects:** Creates chart UI widgets; wires a tooltip formatter closure over `entries`.
- **Algorithm:**
  1. Pull `_monthScoreEntries` and map each entry to an `FlSpot(day, score)` (X axis is day-of-month as a double, Y axis is the score).
  2. Configure axis bounds directly from `DailyScoreLog.minScore`/`maxScore` (Y) and `1`..`entries.length` (X).
  3. Configure bottom-axis tick titles to only render on exact integer days that fall within range (`interval: 7`), and left-axis ticks every 5 score points.
  4. Color each data point by sign: `onSurfaceVariant` for zero, `primary` for positive, `error` for negative (via `getDotPainter`).
  5. Wire `LineTouchTooltipData.getTooltipItems` to map a touched spot's X position back to the corresponding `entries` index (clamped to valid range) and render its formatted date and score.
- **Usage:**
  ```dart
  _buildScoreTrendCard(theme, l10n),
  _buildScoreListsCard(theme, l10n),
  ```
- **Notes:** "Every day is plotted" (per the source comment) means a month with many zero/no-entry days still shows a continuous line at y=0 for those days, rather than gaps — this is a direct consequence of `_monthScoreEntries` always including every day.

### `Widget _buildScoreListsCard(ThemeData theme, AppLocalizations l10n)` <a id="buildscorelistscard"></a>
- **Kind:** method of `_TodoCalendarPageState` (widget helper)
- **Source:** `lib/features/todo/views/todo_page.dart` (approx. line 2089)
- **Purpose:** Filter the visible month's score entries into "joyful" and "suffering" day lists and render them as two sections.
- **Inputs:** `theme`, `l10n`.
- **Returns:** A `Card` containing two `_buildScoreDaySection` outputs separated by a `Divider`.
- **Side effects:** Creates UI widgets; each rendered date chip wires an `onPressed: () => _pickDate(entry.key)` callback.
- **Algorithm:** Filters `_monthScoreEntries` into `joyfulDays` (`entry.value >= 4`) and `sufferingDays` (`entry.value <= -4`), then passes each filtered list to `_buildScoreDaySection` along with its icon/color/label set (sun icon + primary color for joyful, thunderstorm icon + error color for suffering).
- **Usage:**
  ```dart
  Widget build(BuildContext context) {
    ...
    _buildScoreTrendCard(theme, l10n),
    _buildScoreListsCard(theme, l10n),
  ```
- **Notes:** The `>= 4` / `<= -4` thresholds are the actual filtering rule for "joyful"/"suffering," against a score range of -5 to 5 (see [Todo](../../../../features/todo.md#model)); `_buildScoreDaySection` itself does no filtering, only rendering.

## Related pages

- [Todo](../../../../features/todo.md) — `Task`, `TaskRecurrence`, `DailyCompletionLog`, `DailyScoreLog` model concepts and the storage/reminder rules this file implements.
- [Three-Way Merge](../../../../algorithms/three-way-merge.md) — how `_dailyLog`/`_dailyScores` merge across devices (not implemented in this file, but the state this file edits).

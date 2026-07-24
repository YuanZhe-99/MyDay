# lib/features/todo/models/task.dart

Data models for the Todo feature: `TaskType`/`RecurrenceType` enums, `TaskRecurrence` (how a
one-time task repeats after completion), `SubTask`, `Task` (daily templates and one-time tasks
share this one class), and the two per-date logs — `DailyCompletionLog` (task/subtask completion,
merged by union) and `DailyScoreLog`/`DailyScoreEntry` (a -5..5 whole-day score, merged by
last-writer-wins). See [Todo](../../../../features/todo.md) for the concept-level description of
these types and [Data Formats](../../../../data-formats.md#todo--todo_datajson) for their exact
persisted JSON shape. Persisted and loaded by [`TodoStorage`](../services/todo_storage.md) inside
`todo_data.json`, and merged across devices by `mergeTodoData` in `sync_merge.dart` — see
[Three-Way Merge](../../../../algorithms/three-way-merge.md) for the union/LWW rules referenced
throughout this page.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`TaskRecurrence._`](#taskrecurrence-_) | private const constructor (`TaskRecurrence`) | A | Base constructor backing the three named recurrence factories. |
| [`TaskRecurrence.everyNDays`](#taskrecurrence-everyndays) | const constructor (`TaskRecurrence`) | A | Create a recurrence that repeats every N days. |
| [`TaskRecurrence.monthlyOnDay`](#taskrecurrence-monthlyonday) | const constructor (`TaskRecurrence`) | A | Create a recurrence that repeats monthly on a given day. |
| [`TaskRecurrence.yearlyOnMonthDay`](#taskrecurrence-yearlyonmonthday) | const constructor (`TaskRecurrence`) | A | Create a recurrence that repeats yearly on a given month+day. |
| [`nextDate`](#nextdate) | method (`TaskRecurrence`) | A | Compute the next occurrence date after a given date. |
| [`TaskRecurrence.toJson`](#taskrecurrence-tojson) | method (`TaskRecurrence`) | A | Serialize this recurrence to a JSON-compatible map. |
| [`TaskRecurrence.fromJson`](#taskrecurrence-fromjson) | factory constructor (`TaskRecurrence`) | A | Parse a recurrence from its persisted/synced JSON shape. |
| [`SubTask` (constructor)](#subtask-new) | constructor (`SubTask`) | A | Create a subtask, defaulting `id`/`modifiedAt`. |
| [`SubTask.copyWith`](#subtask-copywith) | method (`SubTask`) | A | Copy this subtask with selected fields replaced. |
| [`SubTask.toJson`](#subtask-tojson) | method (`SubTask`) | A | Serialize this subtask to a JSON-compatible map. |
| [`SubTask.fromJson`](#subtask-fromjson) | factory constructor (`SubTask`) | A | Parse a subtask from its persisted/synced JSON shape. |
| [`Task` (constructor)](#task-new) | constructor (`Task`) | A | Create a task, defaulting `id`/`createdDate`/`modifiedAt`. |
| [`Task.copyWith`](#task-copywith) | method (`Task`) | A | Copy this task with selected fields replaced or cleared. |
| [`Task.toJson`](#task-tojson) | method (`Task`) | A | Serialize this task to a JSON-compatible map. |
| [`Task.fromJson`](#task-fromjson) | factory constructor (`Task`) | A | Parse a task from its persisted/synced JSON shape. |
| [`DailyCompletionLog` (constructor)](#dailycompletionlog-new) | constructor (`DailyCompletionLog`) | A | Create an empty completion log. |
| [`dateKey`](#datekey) | static method (`DailyCompletionLog`) | A | Format a date as the `yyyy-MM-dd` key used by both logs. |
| [`isCompleted`](#iscompleted) | method (`DailyCompletionLog`) | A | Check whether a daily task is completed on a date. |
| [`toggle`](#toggle) | method (`DailyCompletionLog`) | A | Flip a daily task's completion state for a date. |
| [`completedIds`](#completedids) | method (`DailyCompletionLog`) | A | Return all completed task IDs for a date. |
| [`isSubtaskCompleted`](#issubtaskcompleted) | method (`DailyCompletionLog`) | A | Check whether a subtask is completed on a date. |
| [`toggleSubtask`](#togglesubtask) | method (`DailyCompletionLog`) | A | Flip a subtask's completion state for a date. |
| [`setSubtasksCompleted`](#setsubtaskscompleted) | method (`DailyCompletionLog`) | A | Bulk-set many subtask IDs completed/not for a date. |
| [`completedSubtaskIds`](#completedsubtaskids) | method (`DailyCompletionLog`) | A | Return all completed subtask IDs for a date. |
| [`DailyCompletionLog.toJson`](#dailycompletionlog-tojson) | method (`DailyCompletionLog`) | A | Serialize both maps to their persisted shape. |
| [`DailyCompletionLog.fromJson`](#dailycompletionlog-fromjson) | factory constructor (`DailyCompletionLog`) | A | Parse a completion log, supporting the legacy flat format. |
| [`DailyCompletionLog.merge`](#dailycompletionlog-merge) | factory constructor (`DailyCompletionLog`) | A | Union-merge two completion logs across all dates. |
| [`DailyScoreEntry` (constructor)](#dailyscoreentry-new) | constructor (`DailyScoreEntry`) | A | Create a score entry, clamping the score. |
| [`DailyScoreEntry.toJson`](#dailyscoreentry-tojson) | method (`DailyScoreEntry`) | A | Serialize this score entry to a JSON-compatible map. |
| [`DailyScoreEntry.fromJson`](#dailyscoreentry-fromjson) | factory constructor (`DailyScoreEntry`) | A | Parse a score entry from its persisted/synced JSON shape. |
| [`DailyScoreLog` (constructor)](#dailyscorelog-new) | constructor (`DailyScoreLog`) | A | Create an empty daily score log. |
| [`normalizeScore`](#normalizescore) | static method (`DailyScoreLog`) | A | Clamp a raw score into the supported -5..5 range. |
| `DailyScoreLog.isEmpty` | getter (`DailyScoreLog`) | B | Whether this log has no explicit score entries. |
| [`scoreFor`](#scorefor) | method (`DailyScoreLog`) | A | Read the score for a day, defaulting to 0. |
| [`setScore`](#setscore) | method (`DailyScoreLog`) | A | Store the score for a day. |
| [`DailyScoreLog.toJson`](#dailyscorelog-tojson) | method (`DailyScoreLog`) | A | Serialize the score map, sorted by date key. |
| [`DailyScoreLog.fromJson`](#dailyscorelog-fromjson) | factory constructor (`DailyScoreLog`) | A | Parse a score log, supporting the legacy numeric format. |
| [`DailyScoreLog.merge`](#dailyscorelog-merge) | factory constructor (`DailyScoreLog`) | A | Last-writer-wins merge of two score logs, per date. |

`grep -c 'Purpose:' lib/features/todo/models/task.dart` reports 38, matching all thirty-eight real
declarations listed above exactly. No misattached doc comments were found — every `/// Purpose:`
block sits directly above the real constructor/method/factory it documents. No undocumented real
declaration exists either; the `TaskType` and `RecurrenceType` enum declarations at the top of the
file carry no `Purpose:` block and are correctly excluded from the table above, since they declare a
fixed set of values rather than behavior (the same treatment plain type declarations get elsewhere
in this doc set). Tier split: 37 Tier A / 1 Tier B. The single Tier B row is
`DailyScoreLog.isEmpty`, a trivial one-line getter (`_scores.isEmpty`) with no branching or
parameters. Every other declaration is Tier A: all constructors/`toJson`/`fromJson`/`copyWith`/
`merge` factories fall under the explicit models Tier A rule, and the remaining query/mutation
methods on `DailyCompletionLog`/`DailyScoreLog` (`dateKey`, `isCompleted`, `toggle`, `completedIds`,
`isSubtaskCompleted`, `toggleSubtask`, `setSubtasksCompleted`, `completedSubtaskIds`,
`normalizeScore`, `scoreFor`, `setScore`) encode real per-date map lookup/mutation logic central to
these two data models (not plain field forwarding), so they were classed Tier A rather than as
trivial accessors.

## Documentation

### `const TaskRecurrence._({required this.type, this.intervalDays = 0, this.dayOfMonth = 0, this.monthOfYear = 0})` <a id="taskrecurrence-_"></a>
- **Kind:** private const constructor of `TaskRecurrence`
- **Source:** `lib/features/todo/models/task.dart` (line 25)
- **Purpose:** Base constructor building a `TaskRecurrence` with an explicit `type` plus all three
  possible parameter fields; internal only.
- **Inputs:** `type` (required); `intervalDays`/`dayOfMonth`/`monthOfYear` (each default 0).
- **Returns:** A new `TaskRecurrence`.
- **Side effects:** None.
- **Algorithm:** Plain const field-initializing constructor. The three named constructors below
  (and `fromJson`) are its only callers, each supplying a fixed `type` and only the field(s)
  relevant to that recurrence kind.
- **Usage:** `TaskRecurrence._(type: RecurrenceType.everyNDays, intervalDays: days)` — called only
  from within this file, by `everyNDays`/`monthlyOnDay`/`yearlyOnMonthDay` (lines 38, 46, 54-58) and
  `fromJson` (lines 107-112).
- **Notes:** Because it is private, a `TaskRecurrence` can only be built through one of the three
  named factories or `fromJson` — there is no way from outside this file to construct one with a
  `type` mismatched to its populated fields.

### `const TaskRecurrence.everyNDays(int days)` <a id="taskrecurrence-everyndays"></a>
- **Kind:** const constructor of `TaskRecurrence`
- **Source:** `lib/features/todo/models/task.dart` (line 37)
- **Purpose:** Create a recurrence that repeats every `days` days after completion.
- **Inputs:** `days` — interval in days.
- **Returns:** A new `TaskRecurrence` with `type = RecurrenceType.everyNDays`.
- **Side effects:** None.
- **Algorithm:** Forwards to `TaskRecurrence._(type: RecurrenceType.everyNDays, intervalDays: days)`.
- **Usage:**
  ```dart
  RecurrenceType.everyNDays => TaskRecurrence.everyNDays(_intervalDays),
  ```
  (`lib/features/todo/widgets/recurrence_picker.dart`, lines 276-278, the recurrence picker's save
  handler).
- **Notes:** `dayOfMonth`/`monthOfYear` stay at their 0 default for this variant; `nextDate` simply
  never reads them for `everyNDays`.

### `const TaskRecurrence.monthlyOnDay(int day)` <a id="taskrecurrence-monthlyonday"></a>
- **Kind:** const constructor of `TaskRecurrence`
- **Source:** `lib/features/todo/models/task.dart` (line 45)
- **Purpose:** Create a recurrence that repeats monthly on day `day`.
- **Inputs:** `day` — day of month (1-31).
- **Returns:** A new `TaskRecurrence` with `type = RecurrenceType.monthlyOnDay`.
- **Side effects:** None.
- **Algorithm:** Forwards to `TaskRecurrence._(type: RecurrenceType.monthlyOnDay, dayOfMonth: day)`.
- **Usage:**
  ```dart
  RecurrenceType.monthlyOnDay => TaskRecurrence.monthlyOnDay(
    _dayOfMonth,
  ),
  ```
  (`recurrence_picker.dart`, lines 279-281).
- **Notes:** An out-of-range `day` is not validated here; clamping only happens later, inside
  `nextDate`, against the target month's actual length.

### `const TaskRecurrence.yearlyOnMonthDay(int month, int day)` <a id="taskrecurrence-yearlyonmonthday"></a>
- **Kind:** const constructor of `TaskRecurrence`
- **Source:** `lib/features/todo/models/task.dart` (line 53)
- **Purpose:** Create a recurrence that repeats yearly on `month`/`day`.
- **Inputs:** `month` (1-12), `day` (1-31).
- **Returns:** A new `TaskRecurrence` with `type = RecurrenceType.yearlyOnMonthDay`.
- **Side effects:** None.
- **Algorithm:** Forwards to `TaskRecurrence._(type: RecurrenceType.yearlyOnMonthDay, monthOfYear:
  month, dayOfMonth: day)`.
- **Usage:**
  ```dart
  RecurrenceType.yearlyOnMonthDay =>
    TaskRecurrence.yearlyOnMonthDay(
      _monthOfYear,
      _dayOfMonth,
    ),
  ```
  (`recurrence_picker.dart`, lines 282-286).
- **Notes:** Same as `monthlyOnDay` — day/month clamping happens in `nextDate`, not here.

### `DateTime nextDate(DateTime from)` <a id="nextdate"></a>
- **Kind:** method of `TaskRecurrence`
- **Source:** `lib/features/todo/models/task.dart` (line 66)
- **Purpose:** Compute the next occurrence date after `from`, according to this recurrence's type.
- **Inputs:** `from` — the date the just-completed occurrence was scheduled/created on.
- **Returns:** `DateTime` — the next occurrence date.
- **Side effects:** None.
- **Algorithm:**
  1. `everyNDays`: `from.add(Duration(days: intervalDays))`.
  2. `monthlyOnDay`: advance to the following month (rolling the year over past month 12), compute
     that month's last day via `DateTime(year, month + 1, 0).day`, then clamp `dayOfMonth` into
     `[1, lastDay]`.
  3. `yearlyOnMonthDay`: advance to `from.year + 1`, compute `monthOfYear`'s last day in that year
     the same way, and clamp `dayOfMonth` the same way (handles Feb 29 -> Feb 28 in a non-leap
     target year).
- **Usage:**
  ```dart
  final nextDate = completedTask.recurrence!.nextDate(
    completedTask.scheduledDate ?? completedTask.createdDate,
  );
  ```
  (`lib/features/todo/views/todo_page.dart`, lines 895-897, `_offerNextOccurrence`).
- **Notes:** `monthlyOnDay` always advances by exactly one month and `yearlyOnMonthDay` by exactly
  one year from `from` — there is no "next occurrence after today" search. The caller is expected to
  pass the date the just-completed task was scheduled on, not an arbitrary reference date.

### `Map<String, dynamic> toJson()` <a id="taskrecurrence-tojson"></a>
- **Kind:** method of `TaskRecurrence`
- **Source:** `lib/features/todo/models/task.dart` (line 94)
- **Purpose:** Serialize this recurrence into its persisted/synced JSON shape.
- **Inputs:** None.
- **Returns:** `Map<String, dynamic>` with `type` (enum name), `intervalDays`, `dayOfMonth`,
  `monthOfYear`.
- **Side effects:** None.
- **Algorithm:** Plain map literal — always writes all three numeric fields regardless of `type`.
- **Usage:** `'recurrence': recurrence?.toJson()` inside `Task.toJson` (line 297).
- **Notes:** Unlike `Task.toJson`, this never omits fields conditionally — a serialized `everyNDays`
  recurrence still carries `dayOfMonth: 0, monthOfYear: 0` in the JSON.

### `factory TaskRecurrence.fromJson(Map<String, dynamic> json)` <a id="taskrecurrence-fromjson"></a>
- **Kind:** factory constructor of `TaskRecurrence`
- **Source:** `lib/features/todo/models/task.dart` (line 106)
- **Purpose:** Reconstruct a `TaskRecurrence` from its persisted/synced JSON shape.
- **Inputs:** `json`.
- **Returns:** A new `TaskRecurrence`.
- **Side effects:** None.
- **Algorithm:** `RecurrenceType.values.byName(json['type'] as String)`, then each numeric field
  defaults to 0 via `as int? ?? 0`, all passed into the private `_` constructor.
- **Usage:** `TaskRecurrence.fromJson(json['recurrence'] as Map<String, dynamic>)` inside
  `Task.fromJson` (lines 337-339).
- **Notes:** `byName` throws if `type` doesn't match one of the three enum names — a corrupt/foreign
  `type` string is not tolerated silently (it propagates up and surfaces as a load error, per
  `Task.fromJson`'s notes below).

### `SubTask({String? id, required this.title, this.isCompleted = false, DateTime? modifiedAt})` <a id="subtask-new"></a>
- **Kind:** constructor of `SubTask`
- **Source:** `lib/features/todo/models/task.dart` (line 126)
- **Purpose:** Create a subtask, generating `id`/`modifiedAt` when omitted.
- **Inputs:** `title` (required); `isCompleted` (default false); optional `id`, `modifiedAt`.
- **Returns:** A new `SubTask`.
- **Side effects:** None directly (`Uuid().v4()`/`DateTime.now()` each produce a fresh value).
- **Algorithm:** `id ??= Uuid().v4()`; `modifiedAt ??= DateTime.now().toUtc()`.
- **Usage:** `subtasks: subtaskTitles.map((t) => SubTask(title: t)).toList()`
  (`lib/features/todo/widgets/add_task_dialog.dart`, line 618); also `SubTask(title: s.title)` when
  building the next-occurrence task (`todo_page.dart`, line 904).
- **Notes:** Unlike `Task`, `SubTask` has no `createdDate` field — only `id`/`modifiedAt` get
  auto-generated defaults.

### `SubTask copyWith({String? title, bool? isCompleted, DateTime? modifiedAt})` <a id="subtask-copywith"></a>
- **Kind:** method of `SubTask`
- **Source:** `lib/features/todo/models/task.dart` (line 139)
- **Purpose:** Produce a modified copy of this subtask, keeping the same `id`.
- **Inputs:** Replacement `title`/`isCompleted`/`modifiedAt`.
- **Returns:** A new `SubTask` with the same `id` as `this`.
- **Side effects:** None (`modifiedAt` is always regenerated on the new instance unless explicitly
  passed).
- **Algorithm:** `title`/`isCompleted` fall back to `this.x` when omitted; `modifiedAt` always
  regenerates via `?? DateTime.now().toUtc()` — never inherited from `this`, so every `copyWith`
  call bumps modification time (same convention as `Task.copyWith`).
- **Usage:**
  ```dart
  _subtasks[index] = _subtasks[index].copyWith(title: newTitle);
  ```
  (`lib/features/todo/widgets/edit_task_dialog.dart`, line 593); also
  `s.copyWith(isCompleted: nowCompleting)` (`todo_page.dart`, line 854) and
  `s.copyWith(isCompleted: subDone)` (`todo_page.dart`, line 373, mapping per-date subtask
  completion onto a daily template's display copy).
- **Notes:** Unlike `Task.copyWith`, there is no `clearX` pattern here — none of `SubTask`'s fields
  besides the auto-generated ones are nullable in a way that needs explicit clearing.

### `Map<String, dynamic> toJson()` <a id="subtask-tojson"></a>
- **Kind:** method of `SubTask`
- **Source:** `lib/features/todo/models/task.dart` (line 153)
- **Purpose:** Serialize this subtask into its persisted/synced JSON shape.
- **Inputs:** None.
- **Returns:** `Map<String, dynamic>` with `id`, `title`, `isCompleted`, `modifiedAt` (ISO 8601).
- **Side effects:** None.
- **Algorithm:** Plain map literal, no conditional omission.
- **Usage:** `subtasks.map((s) => s.toJson()).toList()` inside `Task.toJson` (line 290).
- **Notes:** None.

### `factory SubTask.fromJson(Map<String, dynamic> json)` <a id="subtask-fromjson"></a>
- **Kind:** factory constructor of `SubTask`
- **Source:** `lib/features/todo/models/task.dart` (line 165)
- **Purpose:** Reconstruct a `SubTask` from its persisted/synced JSON shape.
- **Inputs:** `json` — expected to contain at least `id`, `title`.
- **Returns:** A new `SubTask`.
- **Side effects:** None.
- **Algorithm:** `id`/`title` cast directly (throw if missing/wrong type); `isCompleted` defaults
  `false`; `modifiedAt` parsed via `DateTime.parse` if present, else falls back to the Unix epoch
  (`DateTime.fromMillisecondsSinceEpoch(0)`) rather than "now".
- **Usage:**
  ```dart
  subtasks:
      (json['subtasks'] as List<dynamic>?)
          ?.map((s) => SubTask.fromJson(s as Map<String, dynamic>))
          .toList() ??
      const [],
  ```
  (`Task.fromJson`, lines 316-320).
- **Notes:** A missing/null `modifiedAt` reads as the Unix epoch (oldest possible), not "now" — so a
  subtask record persisted before `modifiedAt` was tracked will always lose a last-writer-wins
  comparison against a peer that has a real timestamp.

### `Task({String? id, required this.title, this.note, this.emoji, required this.type, this.isCompleted = false, this.reminderTime, this.subtasks = const [], DateTime? createdDate, this.completedDate, this.scheduledDate, this.deletedDate, this.startDate, this.dueDate, this.recurrence, DateTime? modifiedAt})` <a id="task-new"></a>
- **Kind:** constructor of `Task`
- **Source:** `lib/features/todo/models/task.dart` (line 211)
- **Purpose:** Create a task (daily template or one-time), generating `id`/`createdDate`/
  `modifiedAt` when omitted.
- **Inputs:** `title`, `type` (required); many optional fields covering both daily-template use
  (`startDate`, `deletedDate`) and one-time-task use (`scheduledDate`, `dueDate`, `recurrence`).
- **Returns:** A new `Task`.
- **Side effects:** None directly.
- **Algorithm:** `id ??= Uuid().v4()`; `createdDate ??= DateTime.now()` (local time); `modifiedAt ??=
  DateTime.now().toUtc()`.
- **Usage:**
  ```dart
  final task = Task(
    title: title,
    note: note.isEmpty ? null : note,
    emoji: _selectedEmoji,
    type: _selectedType,
    reminderTime: reminder,
    subtasks: subtaskTitles.map((t) => SubTask(title: t)).toList(),
    scheduledDate: _selectedType != TaskType.daily
        ? _scheduledDate ?? widget.defaultDate ?? DateTime.now()
        : null,
    startDate: _selectedType == TaskType.daily
        ? widget.defaultDate ?? DateTime.now()
        : null,
    dueDate: _selectedType != TaskType.daily ? _dueDate : null,
    recurrence: _selectedType != TaskType.daily ? _recurrence : null,
  );
  ```
  (`add_task_dialog.dart`, lines 612-627, the create-task save handler).
- **Notes:** `createdDate` defaults to local time while `modifiedAt` always defaults to UTC — the
  same local/UTC asymmetry as this repo's other model constructors; sync-relevant comparisons must
  use `modifiedAt`, never `createdDate`.

### `Task copyWith({String? title, String? note, bool clearNote = false, String? emoji, TaskType? type, bool? isCompleted, DateTime? reminderTime, List<SubTask>? subtasks, DateTime? completedDate, DateTime? scheduledDate, DateTime? deletedDate, bool clearDeletedDate = false, DateTime? startDate, DateTime? dueDate, bool clearDueDate = false, TaskRecurrence? recurrence, bool clearRecurrence = false, DateTime? modifiedAt})` <a id="task-copywith"></a>
- **Kind:** method of `Task`
- **Source:** `lib/features/todo/models/task.dart` (line 237)
- **Purpose:** Produce a modified copy of this task, clearing nullable fields via explicit `clearXxx`
  flags rather than by passing `null`.
- **Inputs:** Replacement values for most fields; `clearNote`/`clearDeletedDate`/`clearDueDate`/
  `clearRecurrence` booleans.
- **Returns:** A new `Task` with the same `id` and `createdDate` as `this`.
- **Side effects:** None (`modifiedAt` is always regenerated unless explicitly passed).
- **Algorithm:** For `note`/`deletedDate`/`dueDate`/`recurrence`: `clearX ? null : (x ?? this.x)`.
  For `scheduledDate`/`startDate`/`completedDate`: plain `x ?? this.x` with **no** clear flag —
  there is no way to null these three out through `copyWith` alone. `id` and `createdDate` are not
  parameters at all; the body's `id: id` / `createdDate: createdDate` resolve to `this.id`/
  `this.createdDate` implicitly (unqualified field access inside an instance method), so neither can
  ever be changed via `copyWith`.
- **Usage:**
  ```dart
  _dailyTemplates[index] = t.copyWith(deletedDate: _selectedDate);
  ```
  (`todo_page.dart`, line 946, soft-deleting a daily template) and
  ```dart
  return needsCopy
      ? t.copyWith(isCompleted: done, subtasks: mappedSubs)
      : t;
  ```
  (`todo_page.dart`, line 378, `_dailyForDate` mapping per-date completion onto the template's
  display copy).
- **Notes:** Because `completedDate` has no `clearX` flag, `_toggleTask`'s one-time-task
  un-completion path (`todo_page.dart`, lines 857-873) constructs a raw `Task(...)` directly instead
  of calling `copyWith`, specifically so it can set `completedDate: null`.

### `Map<String, dynamic> toJson()` <a id="task-tojson"></a>
- **Kind:** method of `Task`
- **Source:** `lib/features/todo/models/task.dart` (line 282)
- **Purpose:** Serialize this task into its persisted/synced JSON shape.
- **Inputs:** None.
- **Returns:** `Map<String, dynamic>` with every field always present as a key (nullable fields
  written as JSON `null` rather than omitted).
- **Side effects:** None.
- **Algorithm:** Plain map literal; `subtasks.map((s) => s.toJson())`, ISO 8601 for every `DateTime`
  field, `recurrence?.toJson()`.
- **Usage:** `dailyTemplates.map((t) => t.toJson()).toList()` inside `TodoData.toJson`
  (`lib/features/todo/services/todo_storage.dart`, line 55); also `serialize: (x) =>
  jsonEncode(x.toJson())` passed to `mergeRecords<Task>` (`lib/shared/services/sync_merge.dart`,
  lines 238, 249) for conflict-diff display.
- **Notes:** Unlike `WeightRecord.toJson`, nullable fields here are never omitted — the serialized
  shape always has a stable, complete key set, with `null` values where a field is absent.

### `factory Task.fromJson(Map<String, dynamic> json)` <a id="task-fromjson"></a>
- **Kind:** factory constructor of `Task`
- **Source:** `lib/features/todo/models/task.dart` (line 306)
- **Purpose:** Reconstruct a `Task` from its persisted/synced JSON shape.
- **Inputs:** `json`.
- **Returns:** A new `Task`.
- **Side effects:** None.
- **Algorithm:** `id`/`title` cast directly (throw if missing); `type` via
  `TaskType.values.byName`; every `DateTime?` field parsed via `DateTime.parse` if present else
  `null`; `subtasks` mapped via `SubTask.fromJson`, defaulting to `const []` if absent; `recurrence`
  via `TaskRecurrence.fromJson` if present; `modifiedAt` parsed if present else the Unix epoch.
- **Usage:**
  ```dart
  dailyTemplates: (json['dailyTemplates'] as List<dynamic>)
      .map((t) => Task.fromJson(t as Map<String, dynamic>))
      .toList(),
  ```
  (`TodoData.fromJson`, `todo_storage.dart`, lines 81-83; `oneTimeTasks` follows the same pattern at
  lines 84-86).
- **Notes:** `type` uses `byName`, which throws on an unrecognized string — combined with
  `TodoStorage.load()`'s try/catch, a task with a corrupt `type` value turns the whole file load
  into a thrown `TodoStorageException` rather than silently dropping that one record.

### `DailyCompletionLog()` <a id="dailycompletionlog-new"></a>
- **Kind:** constructor of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 359)
- **Purpose:** Create an empty completion log.
- **Inputs:** None.
- **Returns:** A new `DailyCompletionLog` with both internal maps empty.
- **Side effects:** None.
- **Algorithm:** Trivial — relies on the field initializers `_log = {}` / `_subLog = {}`.
- **Usage:** `DailyCompletionLog()` as the loader's fallback when `json['dailyLog']` is absent
  (`TodoData.fromJson`, `todo_storage.dart`, line 91), and
  `ReminderService.instance.updateData(..., dailyLog: DailyCompletionLog())` on a load failure
  (`todo_page.dart`, line 101).
- **Notes:** None.

### `static String dateKey(DateTime date)` <a id="datekey"></a>
- **Kind:** static method of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 366)
- **Purpose:** Format a `DateTime` into the `yyyy-MM-dd` string key used by both the completion log
  and the score log.
- **Inputs:** `date`.
- **Returns:** `String`, zero-padded month/day, unpadded year.
- **Side effects:** None.
- **Algorithm:** `'${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString()
  .padLeft(2,'0')}'` — uses `date`'s own year/month/day components directly with no timezone
  conversion, so the key reflects whatever timezone `date` is already expressed in.
- **Usage:** Used internally throughout this file (`isCompleted`, `toggle`, `DailyScoreLog.scoreFor`/
  `setScore`, etc.) and externally by `lib/shared/services/local_api_server.dart` (lines 220, 430,
  442, 453, 1013-1042) to key its REST responses by the same date format.
- **Notes:** Not zero-padded on the year, so this is not a strictly sortable ISO date outside
  four-digit years — irrelevant in practice, but `local_api_server.dart:1021`'s string comparison
  (`dateKey.compareTo(...)`) only works correctly because every year in practice is 4 digits.

### `bool isCompleted(DateTime date, String taskId)` <a id="iscompleted"></a>
- **Kind:** method of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 374)
- **Purpose:** Check whether a specific daily task is marked done on a given date.
- **Inputs:** `date`, `taskId`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `_log[dateKey(date)]?.contains(taskId) ?? false` — an absent date entry reads as
  "not completed" rather than throwing.
- **Usage:**
  ```dart
  final done = _dailyLog.isCompleted(_selectedDate, t.id);
  ```
  (`todo_page.dart`, line 368, `_dailyForDate`; also lines 703, 743, 833).
- **Notes:** None.

### `void toggle(DateTime date, String taskId)` <a id="toggle"></a>
- **Kind:** method of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 383)
- **Purpose:** Flip a daily task's completion state for a given date.
- **Inputs:** `date`, `taskId`.
- **Returns:** None.
- **Side effects:** Mutates `_log` in place — creates the date's entry if absent, then adds/removes
  `taskId`.
- **Algorithm:** `_log.putIfAbsent(key, () => {})`; if the set already contains `taskId`, remove it,
  else add it.
- **Usage:** `_dailyLog.toggle(_selectedDate, task.id);` (`todo_page.dart`, line 831, `_toggleTask`'s
  daily-task branch).
- **Notes:** Toggling records no per-entry timestamp of its own — completion state for a date+task
  pair has no `modifiedAt`; only the union-merge in `DailyCompletionLog.merge` reconciles two logs
  (see [Three-Way Merge](../../../../algorithms/three-way-merge.md)).

### `Set<String> completedIds(DateTime date)` <a id="completedids"></a>
- **Kind:** method of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 398)
- **Purpose:** Return the full set of completed task IDs for a date.
- **Inputs:** `date`.
- **Returns:** `Set<String>`, empty if the date has no entry.
- **Side effects:** None.
- **Algorithm:** `_log[dateKey(date)] ?? {}`.
- **Usage:** No call sites found elsewhere in the repo — the UI and REST API both query per-task via
  `isCompleted` instead of bulk-reading via this method.
- **Notes:** When a date entry exists, this returns a live reference to the internal `Set` (not a
  copy) — a caller that mutates the returned set would corrupt the log's internal state.

### `bool isSubtaskCompleted(DateTime date, String subtaskId)` <a id="issubtaskcompleted"></a>
- **Kind:** method of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 407)
- **Purpose:** Check whether a specific subtask is marked done on a given date.
- **Inputs:** `date`, `subtaskId`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** Same pattern as `isCompleted`, against `_subLog` instead of `_log`.
- **Usage:** `final subDone = _dailyLog.isSubtaskCompleted(_selectedDate, s.id);` (`todo_page.dart`,
  line 371).
- **Notes:** Same absent-entry-reads-as-false behavior as `isCompleted`.

### `void toggleSubtask(DateTime date, String subtaskId)` <a id="togglesubtask"></a>
- **Kind:** method of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 416)
- **Purpose:** Flip a subtask's completion state for a given date.
- **Inputs:** `date`, `subtaskId`.
- **Returns:** None.
- **Side effects:** Mutates `_subLog` in place.
- **Algorithm:** Same pattern as `toggle`, against `_subLog` instead of `_log`.
- **Usage:** `_dailyLog.toggleSubtask(_selectedDate, subtask.id);` (`todo_page.dart`, line 966).
- **Notes:** None beyond `toggle`'s.

### `void setSubtasksCompleted(DateTime date, Iterable<String> subtaskIds, bool completed)` <a id="setsubtaskscompleted"></a>
- **Kind:** method of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 431)
- **Purpose:** Bulk-set many subtask IDs to completed or not-completed for one date, in a single
  call.
- **Inputs:** `date`, `subtaskIds`, `completed`.
- **Returns:** None.
- **Side effects:** Mutates `_subLog[dateKey(date)]`.
- **Algorithm:** `putIfAbsent` the date's set, then `addAll(subtaskIds)` if `completed` else
  `removeAll(subtaskIds)`.
- **Usage:**
  ```dart
  _dailyLog.setSubtasksCompleted(
    _selectedDate,
    tpl.subtasks.map((s) => s.id),
    nowCompleted,
  );
  ```
  (`todo_page.dart`, lines 840-844 — auto-completing/uncompleting all of a daily template's
  subtasks when its parent task is toggled).
- **Notes:** Unlike `toggle` (single-ID flip), this is a direct set, not a flip — it never touches
  IDs outside `subtaskIds`, and re-applying the same `completed` value is a no-op.

### `Set<String> completedSubtaskIds(DateTime date)` <a id="completedsubtaskids"></a>
- **Kind:** method of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 450)
- **Purpose:** Return the full set of completed subtask IDs for a date.
- **Inputs:** `date`.
- **Returns:** `Set<String>`, empty if the date has no entry.
- **Side effects:** None.
- **Algorithm:** `_subLog[dateKey(date)] ?? {}`.
- **Usage:** No call sites found elsewhere in the repo (mirrors `completedIds`).
- **Notes:** Same live-reference caveat as `completedIds`.

### `Map<String, dynamic> toJson()` <a id="dailycompletionlog-tojson"></a>
- **Kind:** method of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 458)
- **Purpose:** Serialize both internal maps into the `{"tasks": {...}, "subtasks": {...}}` persisted
  shape.
- **Inputs:** None.
- **Returns:** `Map<String, dynamic>`.
- **Side effects:** None.
- **Algorithm:** `_log.map((k, v) => MapEntry(k, v.toList()))`, and the same for `_subLog`, wrapped
  under the `'tasks'`/`'subtasks'` keys.
- **Usage:** `'dailyLog': dailyLog.toJson()` inside `TodoData.toJson`
  (`todo_storage.dart`, line 57).
- **Notes:** The `Set` -> `List` conversion means the persisted ID order within a date reflects
  `Set`'s iteration order (insertion order, in practice), not a sorted order.

### `factory DailyCompletionLog.fromJson(Map<String, dynamic> json)` <a id="dailycompletionlog-fromjson"></a>
- **Kind:** factory constructor of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 468)
- **Purpose:** Parse a completion log, supporting both the current `{tasks, subtasks}` format and a
  legacy flat-map format.
- **Inputs:** `json`.
- **Returns:** A new `DailyCompletionLog`.
- **Side effects:** None.
- **Algorithm:** If `json` has a `'tasks'` key, parse `_log` from `json['tasks']` and `_subLog` from
  `json['subtasks']` (if present, else left empty); otherwise treat the whole `json` map itself as
  the legacy flat date→taskIds map (task log only, no subtask log).
- **Usage:** `json['dailyLog'] != null ? DailyCompletionLog.fromJson(json['dailyLog'] as
  Map<String, dynamic>) : DailyCompletionLog()` (`TodoData.fromJson`, `todo_storage.dart`, lines
  87-91).
- **Notes:** The legacy-format branch means a `todo_data.json` written before per-date subtask
  tracking existed still loads correctly, with `_subLog` simply empty.

### `factory DailyCompletionLog.merge(DailyCompletionLog a, DailyCompletionLog b)` <a id="dailycompletionlog-merge"></a>
- **Kind:** factory constructor of `DailyCompletionLog`
- **Source:** `lib/features/todo/models/task.dart` (line 501)
- **Purpose:** Union-merge two completion logs across all dates, for both task and subtask
  completion independently.
- **Inputs:** `a`, `b`.
- **Returns:** A new `DailyCompletionLog`.
- **Side effects:** None (pure).
- **Algorithm:**
  1. Union the date keys from both `_log`s; for each date, union the two sides' completed-ID sets
     (`{...(a._log[date] ?? {}), ...(b._log[date] ?? {})}`).
  2. Repeat the same union independently for `_subLog`.
- **Usage:**
  ```dart
  final mergedLog = DailyCompletionLog.merge(local.dailyLog, remote.dailyLog);
  ```
  (`lib/shared/services/sync_merge.dart`, line 252). See
  [Three-Way Merge](../../../../algorithms/three-way-merge.md) for why completion state merges by
  union rather than last-writer-wins.
- **Notes:** A task/subtask completed on either side is completed after merge — sync can never
  "un-complete" something; the only way to mark it not-done again is a fresh local `toggle` after
  merging.

### `DailyScoreEntry({required int score, DateTime? modifiedAt})` <a id="dailyscoreentry-new"></a>
- **Kind:** constructor of `DailyScoreEntry`
- **Source:** `lib/features/todo/models/task.dart` (line 527)
- **Purpose:** Create a score entry, clamping `score` into range and defaulting `modifiedAt`.
- **Inputs:** `score` (required); `modifiedAt` (optional).
- **Returns:** A new `DailyScoreEntry`.
- **Side effects:** None.
- **Algorithm:** `score = DailyScoreLog.normalizeScore(score)` (clamped to -5..5); `modifiedAt ??=
  DateTime.now().toUtc()`.
- **Usage:** Only constructed internally in this file, by `DailyScoreLog.setScore` (line 602) and
  `DailyScoreEntry.fromJson`/`DailyScoreLog.fromJson`'s numeric branch (lines 548, 633) — there are
  no external callers.
- **Notes:** None.

### `Map<String, dynamic> toJson()` <a id="dailyscoreentry-tojson"></a>
- **Kind:** method of `DailyScoreEntry`
- **Source:** `lib/features/todo/models/task.dart` (line 536)
- **Purpose:** Serialize this score entry into its persisted/synced JSON shape.
- **Inputs:** None.
- **Returns:** `Map<String, dynamic>` with `score`, `modifiedAt` (ISO 8601).
- **Side effects:** None.
- **Algorithm:** Plain map literal.
- **Usage:** `_scores[key]!.toJson()` inside `DailyScoreLog.toJson` (line 615).
- **Notes:** None.

### `factory DailyScoreEntry.fromJson(Map<String, dynamic> json)` <a id="dailyscoreentry-fromjson"></a>
- **Kind:** factory constructor of `DailyScoreEntry`
- **Source:** `lib/features/todo/models/task.dart` (line 541)
- **Purpose:** Reconstruct a score entry from its persisted/synced JSON shape.
- **Inputs:** `json`.
- **Returns:** A new `DailyScoreEntry`.
- **Side effects:** None.
- **Algorithm:** `score = rawScore is num ? rawScore.round() : 0` (accepts int or double, defaults 0
  otherwise); `modifiedAt` parsed via `DateTime.parse` if present, else the Unix epoch.
- **Usage:** Called from `DailyScoreLog.fromJson`'s `Map`-valued branch (lines 627-629).
- **Notes:** Routes through the main constructor, so an out-of-range stored `score` is still
  re-clamped via `normalizeScore` on load.

### `DailyScoreLog()` <a id="dailyscorelog-new"></a>
- **Kind:** constructor of `DailyScoreLog`
- **Source:** `lib/features/todo/models/task.dart` (line 570)
- **Purpose:** Create an empty daily score log.
- **Inputs:** None.
- **Returns:** A new `DailyScoreLog` with `_scores` empty.
- **Side effects:** None.
- **Algorithm:** Trivial — relies on the `_scores = {}` field initializer.
- **Usage:** `dailyScores ?? DailyScoreLog()` — `TodoData`'s own constructor default
  (`todo_storage.dart`, line 45); also the starting point inside `DailyScoreLog.fromJson`/`merge`.
- **Notes:** Missing dates read as score 0 through `scoreFor`, even though `_scores` starts (and can
  stay) completely empty.

### `static int normalizeScore(int score)` <a id="normalizescore"></a>
- **Kind:** static method of `DailyScoreLog`
- **Source:** `lib/features/todo/models/task.dart` (line 577)
- **Purpose:** Clamp a raw score into the supported -5..5 range.
- **Inputs:** `score`.
- **Returns:** `int` between `minScore` (-5) and `maxScore` (5).
- **Side effects:** None.
- **Algorithm:** `score.clamp(minScore, maxScore).toInt()`.
- **Usage:** `DailyScoreLog.normalizeScore(score)` inside `DailyScoreEntry`'s own constructor (line
  528) — every score entry is clamped through this on construction, so callers outside this file
  never need to call it directly.
- **Notes:** The explicit `.toInt()` guards against `clamp`'s statically-typed `num` return value.

### `int scoreFor(DateTime date)` <a id="scorefor"></a>
- **Kind:** method of `DailyScoreLog`
- **Source:** `lib/features/todo/models/task.dart` (line 592)
- **Purpose:** Read the score for a day, defaulting to 0 when no explicit entry exists.
- **Inputs:** `date`.
- **Returns:** `int`.
- **Side effects:** None.
- **Algorithm:** `_scores[DailyCompletionLog.dateKey(date)]?.score ?? 0`.
- **Usage:** `final score = _dailyScores.scoreFor(_selectedDate);` (`todo_page.dart`, line 1249);
  also `widget.dailyScores.scoreFor(...)` feeding the monthly trend chart (line 1633).
- **Notes:** The `?? 0` default is why "no entry" and "an explicit score of 0" are indistinguishable
  through this method alone — that distinction only matters internally, for `setScore`'s always-
  create-a-new-entry behavior below.

### `void setScore(DateTime date, int score, {DateTime? modifiedAt})` <a id="setscore"></a>
- **Kind:** method of `DailyScoreLog`
- **Source:** `lib/features/todo/models/task.dart` (line 596)
- **Purpose:** Store (or overwrite) the score for a day.
- **Inputs:** `date`, `score`, optional `modifiedAt`.
- **Returns:** None.
- **Side effects:** Mutates `_scores[dateKey(date)]`.
- **Algorithm:** `_scores[dateKey(date)] = DailyScoreEntry(score: score, modifiedAt: modifiedAt)` —
  always replaces with a brand-new entry (never mutates one in place); `DailyScoreEntry`'s
  constructor clamps `score`.
- **Usage:**
  ```dart
  _dailyScores.setScore(
    _selectedDate,
    score,
    modifiedAt: DateTime.now().toUtc(),
  );
  ```
  (`todo_page.dart`, `_setDailyScore`, lines 812-816).
- **Notes:** Because an explicit zero is stored as a real, timestamped entry rather than being
  treated as "clear", a deliberate reset to zero still propagates through sync — see
  [Three-Way Merge](../../../../algorithms/three-way-merge.md).

### `Map<String, dynamic> toJson()` <a id="dailyscorelog-tojson"></a>
- **Kind:** method of `DailyScoreLog`
- **Source:** `lib/features/todo/models/task.dart` (line 608)
- **Purpose:** Serialize the score map into its persisted shape, sorted by date key.
- **Inputs:** None.
- **Returns:** `Map<String, dynamic>` keyed by `yyyy-MM-dd`.
- **Side effects:** None.
- **Algorithm:** Sort `_scores.keys`, then build `{key: _scores[key]!.toJson()}` in that sorted
  order.
- **Usage:** `if (!dailyScores.isEmpty) 'dailyScores': dailyScores.toJson()` inside
  `TodoData.toJson` (`todo_storage.dart`, line 58).
- **Notes:** Sorting is purely cosmetic for the persisted file's readability/diff stability —
  `fromJson` does not depend on key order.

### `factory DailyScoreLog.fromJson(Map<String, dynamic> json)` <a id="dailyscorelog-fromjson"></a>
- **Kind:** factory constructor of `DailyScoreLog`
- **Source:** `lib/features/todo/models/task.dart` (line 618)
- **Purpose:** Parse a score log, accepting both the current per-entry-object format and a legacy
  bare-number format.
- **Inputs:** `json`.
- **Returns:** A new `DailyScoreLog`.
- **Side effects:** None.
- **Algorithm:** For each key/value: if `value` is a `Map`, parse via `DailyScoreEntry.fromJson`; if
  `value` is a `num` (legacy bare score), build a `DailyScoreEntry` directly with that rounded value
  and an epoch `modifiedAt`; any other value type is silently skipped.
- **Usage:** `json['dailyScores'] != null ? DailyScoreLog.fromJson(json['dailyScores'] as
  Map<String, dynamic>) : DailyScoreLog()` (`TodoData.fromJson`, `todo_storage.dart`, lines 92-94).
- **Notes:** Legacy numeric entries get an epoch `modifiedAt`, so on the first merge against a peer
  that has ever explicitly set that day's score with a real timestamp, the legacy value always
  loses the last-writer-wins comparison in `merge`.

### `factory DailyScoreLog.merge(DailyScoreLog local, DailyScoreLog remote)` <a id="dailyscorelog-merge"></a>
- **Kind:** factory constructor of `DailyScoreLog`
- **Source:** `lib/features/todo/models/task.dart` (line 647)
- **Purpose:** Last-writer-wins merge of two score logs, resolved independently per date.
- **Inputs:** `local`, `remote`.
- **Returns:** A new `DailyScoreLog`.
- **Side effects:** None (pure).
- **Algorithm:**
  1. Union all date keys from both sides.
  2. Per date: if only `remote` has an entry, take remote's; else if `local` has no counterpart, or
     `local`'s `modifiedAt` is after or equal to `remote`'s, take local's; otherwise take remote's.
- **Usage:**
  ```dart
  final mergedScores = DailyScoreLog.merge(
    local.dailyScores,
    remote.dailyScores,
  );
  ```
  (`lib/shared/services/sync_merge.dart`, lines 253-256).
- **Notes:** Ties (`localEntry.modifiedAt == remoteEntry.modifiedAt`) favor local — see
  [Three-Way Merge](../../../../algorithms/three-way-merge.md) for this convention applied
  elsewhere in the merge.

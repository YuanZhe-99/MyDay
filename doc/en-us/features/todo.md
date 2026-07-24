# Todo

Model source: `lib/features/todo/models/task.dart`. Storage/config: `lib/features/todo/services/
todo_storage.dart`. See [Data Formats](../data-formats.md#todo--todo_datajson) for the full field
list and [Three-Way Merge](../algorithms/three-way-merge.md) for sync semantics.

## Model

- **`TaskType`**: `daily`, `routineOnce`, `workOnce`.
- **`TaskRecurrence`**: describes how a *one-time* task recurs after completion —
  `RecurrenceType.everyNDays` (interval in days), `RecurrenceType.monthlyOnDay` (day-of-month,
  clamped to the target month's length), or `RecurrenceType.yearlyOnMonthDay` (month + day,
  clamped for short Februaries). `nextDate(from)` computes the next occurrence date directly on the
  recurrence object. One-time tasks with a `recurrence` prompt the user to create the next
  occurrence after they complete the task.
- **`Task`**: `id`, `title`, optional `note`, optional `emoji`, `type`, `isCompleted`, optional
  `reminderTime`, `subtasks`, `createdDate`, optional `completedDate`. For one-time tasks:
  `scheduledDate` (the date it's scheduled on), `dueDate` (reminder purposes), `recurrence`. For
  daily templates: `startDate` (the date the template becomes active — defaults to the selected date
  at creation) and `deletedDate` (soft-delete date; `null` means still active — daily templates are
  never hard-deleted so historical completion logs referencing them stay meaningful).
- **`DailyCompletionLog`**: per-date completion tracking for daily tasks and daily subtasks, keyed by
  `yyyy-MM-dd`. Sync merges by **union** — completing a task on either device leaves it completed
  after merge, on the theory that "done" should never be un-done by a sync.
- **`DailyScoreLog`**: a per-date whole-day score from **-5 to 5**, default **0**. Explicit zero
  entries are retained (not treated as "no entry") so a deliberate reset to zero still propagates
  through sync; each date merges independently by that entry's `modifiedAt`.

## Storage

`TodoStorage` is the central storage/config hub for the whole app, not just Todo:
`storage_config.json` always stays in the default app directory and stores the custom storage path,
intimacy visibility, theme, locale, week start day, tray settings, backup settings, local API
settings, and the local-only intimacy timer keep-screen-awake preference. `todo_data.json` stores
daily templates, one-time tasks, daily logs, daily scores, morning/completion reminder settings,
task sort modes/custom orders, and `settingsModifiedAt`.

## UI

The Todo UI includes an inline week calendar for the selected date's week, a secondary full-month
calendar page with inline year/month jumps, a globally configurable week start day, a monthly
daily-score trend chart, joyful-day and suffering-day lists (derived from the score log), daily/
routine/work sections, calendar completion indicators, future scheduled one-time task markers, an
editable whole-day score at the bottom of the Todo list, independent sort/custom drag order per
section, notes, subtasks, task reminders, a recurrence picker, unsaved-change protection, and
`AutoSyncService.instance.notifySaved()` after saves.

## Reminders

One-time Todo reminders **start on the task's scheduled date** and then repeat **daily at the saved
time until the task is completed** — i.e. a reminder for a future one-time task does not fire before
its scheduled date arrives, but once active it keeps firing every day (not just once) until the
task is marked done. On mobile this is implemented as: future one-time tasks first get a one-shot
start-date OS schedule, then switch to a daily repeating OS schedule once active; daily templates
always use daily OS schedules (shifted to start tomorrow if already completed today). See
[Platform Notes](../platform-notes.md#notifications-reminders-tray-and-startup) for the desktop vs.
mobile reminder delivery split and fire-time semantics.

## Related pages

- [Data Formats](../data-formats.md) — exact JSON shape of every model above.
- [Three-Way Merge](../algorithms/three-way-merge.md) — the union/LWW merge rules for the
  completion and score logs.
- [Platform Notes](../platform-notes.md) — reminder scheduling mechanics on desktop vs. mobile.

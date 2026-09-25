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
section, notes, subtasks, task icons with title-driven emoji suggestions (see
[Emoji suggestions](#emoji-suggestions)), task reminders, a recurrence picker, unsaved-change
protection, and `AutoSyncService.instance.notifySaved()` after saves.

<a id="emoji-suggestions"></a>
## Emoji suggestions

A task's optional `emoji` is its icon. The add and edit dialogs offer it three ways, all built on
two shared constants and one pure function:

| Piece | Source | Role |
|---|---|---|
| [`commonTaskEmojis`](../functions/features/todo/constants/task_emojis.md) | `lib/features/todo/constants/task_emojis.dart` | The picker grid's 98 candidates: the original 32 first, then everyday groups. One list for both dialogs. |
| [`emojiKeywordTable`](../functions/features/todo/constants/emoji_keywords.md) | `lib/features/todo/constants/emoji_keywords.dart` | 188 curated entries, each an emoji with English, Simplified Chinese, Traditional Chinese, and Japanese keywords. |
| [`suggestEmojis`](../functions/features/todo/utils/emoji_suggester.md#suggestemojis) | `lib/features/todo/utils/emoji_suggester.dart` | Ranks the table against a title and returns up to 8 distinct emojis. |
| [`EmojiSuggestionRow`](../functions/features/todo/widgets/emoji_suggestion_row.md) | `lib/features/todo/widgets/emoji_suggestion_row.dart` | The wrapping row of chips under the title field. |

**Matching.** Suggestions work like an IME emoji search: every language's keywords are matched
regardless of the UI locale, so a Chinese title suggests emojis in an English UI. The title is
lowercased, full-width ASCII is folded to half-width, and whitespace is collapsed. CJK keywords
match as substrings; Latin keywords match whole words or phrases, plain English inflections
(`emails`, `cooking`), and — for the last word only, while it is still being typed — a prefix of at
least 3 letters. Longer matches score higher, and ties keep table order. There is no bonus for
position, because titles tend to start with a verb and the object that follows is the better icon.
The full rules are in the [`_scoreKeyword`](../functions/features/todo/utils/emoji_suggester.md#scorekeyword)
entry.

**Auto-fill and manual choice.** While the user has not chosen an icon, the icon follows the best
suggestion as the title changes and clears when no suggestion is left. Choosing an icon any other
way — tapping a chip, picking from the grid, entering a custom emoji, or Remove — is a manual
choice and stops auto-fill for the rest of that dialog. A dialog that opens with an emoji already
set (editing a task that has one, or a next-occurrence prompt prefilled with one) never
auto-fills; its chips still appear and can be tapped. Only real edits of the title text trigger
auto-fill — cursor moves and the autofocused field gaining focus do not — so opening a task and
closing it untouched never changes its icon or triggers the unsaved-changes prompt. Suggestions are computed on the fly and
nothing about them is stored: only the chosen `emoji` is saved on the `Task`.

**Extending the table.** Add keywords to an existing `EmojiKeywordEntry`, or add a new entry to the
matching themed group in `emoji_keywords.dart`. To offer the emoji in the picker grid as well,
also append it to a group in `commonTaskEmojis`. Keep in mind:

- Keywords are lowercase, trimmed, and non-empty, and every entry has keywords in all four
  languages.
- Each emoji appears once in the table; every picker emoji must have an entry; picker entries are
  distinct single graphemes, and the original 32 stay first.
- Put the more common reading of a shared keyword in the earlier entry — table order breaks ties.
- Leave out filler that opens many titles without naming an object ("don't forget", 别忘了,
  忘れずに); it would outrank the object that follows.

`test/emoji_suggester_test.dart` enforces the first two rules and pins expected suggestions for
sample titles in every language; `test/task_emoji_suggestion_dialog_test.dart` covers the dialog
behavior. Run both after changing the table.

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

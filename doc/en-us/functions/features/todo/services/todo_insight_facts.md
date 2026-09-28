# lib/features/todo/services/todo_insight_facts.dart

The pure fact builder behind the Todo page's on-device AI insight card. `buildTodoInsightFacts`
turns the page's loaded [`Task`](../models/task.md) lists, completion log and score log into
[`InsightFacts`](../../ai/services/insight_prompts.md) for the current
[time bucket](../../ai/services/insight_prompts.md): a plan in the morning, progress in the
afternoon, a review and tomorrow's suggestion in the evening. Two visibility helpers repeat the
[Todo page](../views/todo_page.md)'s own rules for which daily templates and one-off tasks show on a
date. Task titles are sent (trimmed and capped, each with at most one qualifier); task notes and
subtask titles never are. Since v1.5.1 the same builder also produces a counts-only variant
(`includeTitles: false`) that the Todo page hands to the store as `fallbackFacts`. The card itself
is [`AiInsightCard`](../../ai/widgets/ai_insight_card.md), and the facts are fingerprinted by
[`AiInsightStore`](../../ai/services/insight_service.md). See
[On-device AI — What each card is given](../../../../on-device-ai.md#what-each-card-is-given).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `_day` | top-level function (private) | B | Drop the time of day. |
| [`dailyTemplatesOn`](#dailytemplateson) | top-level function | A | List the daily templates shown on a date. |
| [`oneTimeVisibleOn`](#onetimevisibleon) | top-level function | A | Decide whether a one-time task is shown on a date. |
| `_hm` | top-level function (private) | B | Format a time of day as `HH:mm`. |
| [`_list`](#_list) | top-level function (private) | A | Join task titles for one fact line, capped. |
| `_overdue` | top-level function (private) | B | Count the tasks whose due day is before a date. |
| [`buildTodoInsightFacts`](#buildtodoinsightfacts) | top-level function | A | Build the Todo card's facts for the current time of day, with or without titles. |

`grep -c 'Purpose:' lib/features/todo/services/todo_insight_facts.dart` reports 7, matching the seven
declarations above exactly; there are no undocumented declarations. `_day`, `_hm` and `_overdue`
(v1.5.1) are one-line helpers (Tier B) — `_overdue` is a single `where(...).length` over
`dueDate`, so it gets a row but no entry, like the two formatters; the other four carry real rules.

## Documentation

### `List<Task> dailyTemplatesOn(List<Task> templates, DateTime date)` <a id="dailytemplateson"></a>
- **Kind:** top-level function
- **Source:** `lib/features/todo/services/todo_insight_facts.dart` (line 17)
- **Purpose:** List the daily templates shown on a date.
- **Inputs:** `templates` — the daily templates; `date`.
- **Returns:** `List<Task>`.
- **Side effects:** None.
- **Algorithm:** Keep a template when the day of `startDate ?? createdDate` is not after `date`'s
  day, and either `deletedDate` is null or its day is after `date`'s day.
- **Usage:** `buildTodoInsightFacts` calls it for today and for tomorrow (lines 106 and 146).
- **Notes:** The same rule as the Todo page: visible from `startDate ?? createdDate` until the day
  before `deletedDate`. Completion is not considered here.

### `bool oneTimeVisibleOn(Task t, DateTime date, DateTime today)` <a id="onetimevisibleon"></a>
- **Kind:** top-level function
- **Source:** `lib/features/todo/services/todo_insight_facts.dart` (line 33)
- **Purpose:** Decide whether a one-time task is shown on a date.
- **Inputs:** `t`, `date` — the date being viewed, `today`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:**
  1. No `scheduledDate` → `false`.
  2. Completed with a `completedDate` → shown on its scheduled day and its completed day.
  3. Otherwise → shown on its scheduled day, and carried forward on every day from the scheduled
     day through `today`.
- **Usage:** `oneTimeTasks.where((t) => oneTimeVisibleOn(t, today, today))` in
  `buildTodoInsightFacts` (line 112).
- **Notes:** The same rule as the Todo page's `_oneTimeVisibleOnDate`. A completed task without a
  `completedDate` is treated as open.

### `String _list(List<String> titles, int max)` <a id="_list"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/todo/services/todo_insight_facts.dart` (line 58)
- **Purpose:** Join task titles for one fact line, capped.
- **Inputs:** `titles`, `max`.
- **Returns:** `String` — `none` when empty; the first `max` entries joined with `; `, plus
  `; +k more` when capped.
- **Side effects:** None.
- **Algorithm:** As in Returns.
- **Usage:** Every list-valued fact line in `buildTodoInsightFacts`, with `maxTasks` (default 8
  since v1.5.1); only the titled variant and the afternoon reminder line use it.
- **Notes:** None.

### `InsightFacts? buildTodoInsightFacts({required DateTime now, required List<Task> dailyTemplates, required List<Task> oneTimeTasks, required DailyCompletionLog dailyLog, required DailyScoreLog dailyScores, int maxTasks = 8, int maxTitleRunes = 24, bool includeTitles = true})` <a id="buildtodoinsightfacts"></a>
- **Kind:** top-level function
- **Source:** `lib/features/todo/services/todo_insight_facts.dart` (line 90)
- **Purpose:** Build the Todo card's facts for the current time of day.
- **Inputs:** `now` — local time; the page's `dailyTemplates`, `oneTimeTasks`, `dailyLog`,
  `dailyScores`; `maxTasks` — items per line (default 8; 12 before v1.5.1); `maxTitleRunes` — per
  title via `clipTitle` (default 24; 40 before v1.5.1); `includeTitles` — `false` builds the
  counts-only variant the store falls back to when the model declines or returns nothing for the
  titled one (v1.5.1).
- **Returns:** `InsightFacts?` with `module: todo`, the bucket, the lines, three slots, and the
  quoted terms — or null when there is nothing on today and (outside the evening, or with nothing on
  tomorrow either) nothing to talk about.
- **Side effects:** None.
- **Algorithm:**
  1. Bucket = `todoBucketFor(now)`. Today's daily templates split into done and open by
     `dailyLog.completedIds(today)`; today's visible one-off tasks split by `isCompleted`.
  2. Two local helpers: `describeOpen(t)` is the clipped title plus at most one qualifier in
     parentheses — `overdue` when the due day is before today, else `due yyyy-MM-dd` when there is
     a due date, else the `HH:mm` reminder time, else nothing; `openCounts(habits, tasks)` is
     `none` or `N daily habits, M one-off tasks (k overdue)` with the empty parts and a zero
     overdue count left out (`_overdue`).
  3. Tomorrow: the daily templates visible tomorrow (only their count is sent), and open one-off
     tasks scheduled exactly for tomorrow.
  4. Return null when today has no daily and no one-off tasks, unless it is evening and tomorrow has
     some.
  5. Quoted terms: with titles, the clipped titles of today's daily, today's one-off and tomorrow's
     one-off tasks (deduplicated); without titles, an empty list.
  6. First line `- Today: <date> (<weekday>)`, then by bucket:
     - **Morning** (and `none`): with titles, `- Daily habits today (N): <titles>` and
       `- One-off tasks today (M open): <describeOpen…>`; without, `- Daily habits today: N` and
       `- One-off tasks today: <openCounts>` for the open one-offs. Then
       `- Yesterday's self-rating: S on a -5 to 5 scale` when non-zero. Slots `plan`
       ("Today's plan, in one sentence."), `first` ("Which task to start with, and why."), `tip`
       ("One practical tip for today.").
     - **Afternoon:** `- Done so far: a of N daily habits, b of M one-off tasks`; then
       `- Still open:` with the open habit titles and `describeOpen` one-offs, or `openCounts`
       without titles; then `- Reminders still ahead today: …` only when at least one open task's
       reminder time of day is later than `now` (`<title> at HH:mm`, or just `HH:mm` without
       titles). Slots `progress` ("How today is going so far."), `remaining` ("What to focus on
       for the rest of the day."), `tip` ("One practical tip for the afternoon.").
     - **Evening:** `- Done today: …` counts; with titles `- Completed: <titles>` and
       `- Left undone: <titles>`, without only `- Left undone: <openCounts>`; then
       `- Today's self-rating: S on a -5 to 5 scale` when non-zero; `- Daily habits tomorrow: N`;
       and `- One-off tasks scheduled for tomorrow:` with titles or a bare count. Slots `summary`
       ("How today went."), `tomorrow` ("What to do first tomorrow, counting anything left
       undone."), `encouragement` ("One short, sincere encouragement.").
- **Usage:**
  ```dart
  final facts = buildTodoInsightFacts(
    now: now,
    dailyTemplates: _dailyTemplates,
    oneTimeTasks: _oneTimeTasks,
    dailyLog: _dailyLog,
    dailyScores: _dailyScores,
  );
  ```
  (`lib/features/todo/views/todo_page.dart`, `_buildAiCard`, line 1438; the same call with
  `includeTitles: false` follows at line 1448 and becomes the request's `fallbackFacts`. Covered by
  `test/insight_facts_test.dart`.)
- **Notes:** Task notes and subtask titles are never read. Both variants use the same bucket and
  the same slot ids in the same order, which `AiInsightRequest.fallbackFacts` requires. A
  self-rating of `0` is indistinguishable from "not rated" and is left out. The "reminders still
  ahead" comparison uses only the reminder's time of day. The bucket is part of the fingerprint,
  so crossing 12:00 or 18:00 regenerates the card. Kept deliberately plain since v1.5.1 — the
  `work`/`routine` marker, *carried over since* and *reminder* wording of v1.5.0 are gone — because
  the on-device model answered the other modules but not the longer, more decorated Todo prompt.

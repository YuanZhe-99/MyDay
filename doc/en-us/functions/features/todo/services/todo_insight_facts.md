# lib/features/todo/services/todo_insight_facts.dart

The pure fact builder behind the Todo page's on-device AI insight card. `buildTodoInsightFacts`
turns the page's loaded [`Task`](../models/task.md) lists, completion log and score log into
[`InsightFacts`](../../ai/services/insight_prompts.md) for the current
[time bucket](../../ai/services/insight_prompts.md): a plan in the morning, progress in the
afternoon, a review and tomorrow's suggestion in the evening. Two visibility helpers repeat the
[Todo page](../views/todo_page.md)'s own rules for which daily templates and one-off tasks show on a
date. Task titles are sent (trimmed and capped); task notes and subtask titles never are. The card
itself is [`AiInsightCard`](../../ai/widgets/ai_insight_card.md), and the facts are fingerprinted by
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
| [`buildTodoInsightFacts`](#buildtodoinsightfacts) | top-level function | A | Build the Todo card's facts for the current time of day. |

`grep -c 'Purpose:' lib/features/todo/services/todo_insight_facts.dart` reports 6, matching the six
declarations above exactly; there are no undocumented declarations. `_day` and `_hm` are one-line
formatting helpers (Tier B); the other four carry real rules.

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
- **Usage:** `buildTodoInsightFacts` calls it for today and for tomorrow (lines 90 and 120).
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
  `buildTodoInsightFacts` (line 96).
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
- **Usage:** Every list-valued fact line in `buildTodoInsightFacts`, with `maxTasks`.
- **Notes:** None.

### `InsightFacts? buildTodoInsightFacts({required DateTime now, required List<Task> dailyTemplates, required List<Task> oneTimeTasks, required DailyCompletionLog dailyLog, required DailyScoreLog dailyScores, int maxTasks = 12, int maxTitleRunes = 40})` <a id="buildtodoinsightfacts"></a>
- **Kind:** top-level function
- **Source:** `lib/features/todo/services/todo_insight_facts.dart` (line 75)
- **Purpose:** Build the Todo card's facts for the current time of day.
- **Inputs:** `now` — local time; the page's `dailyTemplates`, `oneTimeTasks`, `dailyLog`,
  `dailyScores`; `maxTasks` — items per line; `maxTitleRunes` — per title (via `clipTitle`).
- **Returns:** `InsightFacts?` with `module: todo`, the bucket, the lines, three slots, and the
  quoted terms — or null when there is nothing on today and (outside the evening, or with nothing on
  tomorrow either) nothing to talk about.
- **Side effects:** None.
- **Algorithm:**
  1. Bucket = `todoBucketFor(now)`. Today's daily templates split into done and open by
     `dailyLog.completedIds(today)`; today's visible one-off tasks split by `isCompleted`.
  2. Tomorrow: the daily templates visible tomorrow (only their count is sent), and open one-off
     tasks scheduled exactly for tomorrow.
  3. Return null when today has no daily and no one-off tasks, unless it is evening and tomorrow has
     some.
  4. Quoted terms: the clipped titles of today's daily, today's one-off and tomorrow's one-off tasks
     (deduplicated).
  5. First line `- Today: <date> (<weekday>)`, then by bucket:
     - **Morning** (and `none`): today's daily habits; open one-off tasks, each described as
       `work`/`routine` with *carried over since*, *overdue since* / *due*, and *reminder HH:mm*;
       yesterday's self-rating when non-zero. Slots `plan`, `first`, `tip`.
     - **Afternoon:** done counts for daily and one-off; what is still open; reminders still ahead
       today (reminder time of day later than now). Slots `progress`, `remaining`, `tip`.
     - **Evening:** done counts; completed titles; titles left undone; today's self-rating when
       non-zero; the number of daily habits tomorrow; one-off tasks scheduled for tomorrow. Slots
       `summary`, `tomorrow`, `encouragement`.
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
  (`lib/features/todo/views/todo_page.dart`, `_buildAiCard`, line 1454; covered by
  `test/insight_facts_test.dart`.)
- **Notes:** Task notes and subtask titles are never read. A self-rating of `0` is indistinguishable
  from "not rated" and is left out. The "reminders still ahead" comparison uses only the reminder's
  time of day. The bucket is part of the fingerprint, so crossing 12:00 or 18:00 regenerates the
  card.

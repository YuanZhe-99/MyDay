# lib/features/todo/services/todo_insight_facts.dart

Todo 页端侧 AI 洞察卡片背后的纯事实构建器。`buildTodoInsightFacts` 把页面已加载的 [`Task`](../models/task.md) 列表、完成日志和评分日志按当前[时段](../../ai/services/insight_prompts.md)转成 [`InsightFacts`](../../ai/services/insight_prompts.md)：上午是计划，下午是进度，晚上是回顾和明天的建议。两个可见性辅助函数复述 [Todo 页](../views/todo_page.md)自己关于某日期显示哪些每日模板和一次性任务的规则。任务标题会被发送（经裁剪和限量，每个至多带一个限定语）；任务备注和子任务标题绝不发送。自 v1.5.1 起，同一构建器还产出一个只含计数的变体（`includeTitles: false`），Todo 页把它作为 `fallbackFacts` 交给存储。卡片本身是 [`AiInsightCard`](../../ai/widgets/ai_insight_card.md)，事实由 [`AiInsightStore`](../../ai/services/insight_service.md) 计算指纹。见 [端侧 AI — 每张卡片得到什么](../../../../on-device-ai.md#what-each-card-is-given)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `_day` | 顶层函数（私有） | B | 去掉日内时间。 |
| [`dailyTemplatesOn`](#dailytemplateson) | 顶层函数 | A | 列出某日期显示的每日模板。 |
| [`oneTimeVisibleOn`](#onetimevisibleon) | 顶层函数 | A | 判断一次性任务是否在某日期显示。 |
| `_hm` | 顶层函数（私有） | B | 把日内时间格式化为 `HH:mm`。 |
| [`_list`](#_list) | 顶层函数（私有） | A | 为一条事实行连接任务标题，有上限。 |
| `_overdue` | 顶层函数（私有） | B | 统计截止日早于某日期的任务数。 |
| [`buildTodoInsightFacts`](#buildtodoinsightfacts) | 顶层函数 | A | 为当前时段构建 Todo 卡片的事实，带或不带标题。 |

`grep -c 'Purpose:' lib/features/todo/services/todo_insight_facts.dart` 报告 7，与上面七个声明精确匹配；不存在未文档化声明。`_day`、`_hm` 和 `_overdue`（v1.5.1）是一行辅助函数（Tier B）——`_overdue` 只是对 `dueDate` 的一个 `where(...).length`，因此像两个格式化函数一样只有行而没有条目；其余四个承载真实规则。

## 文档

### `List<Task> dailyTemplatesOn(List<Task> templates, DateTime date)` <a id="dailytemplateson"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/todo/services/todo_insight_facts.dart`（第 17 行）
- **用途：** 列出某日期显示的每日模板。
- **输入：** `templates` — 每日模板；`date`。
- **返回：** `List<Task>`。
- **副作用：** 无。
- **算法：** 当 `startDate ?? createdDate` 的日期不晚于 `date` 的日期，且 `deletedDate` 为 null 或其日期晚于 `date` 的日期时保留模板。
- **用法：** `buildTodoInsightFacts` 分别为今天和明天调用它（第 106 和 146 行）。
- **备注：** 与 Todo 页规则相同：从 `startDate ?? createdDate` 起可见，直到 `deletedDate` 的前一天。这里不考虑完成状态。

### `bool oneTimeVisibleOn(Task t, DateTime date, DateTime today)` <a id="onetimevisibleon"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/todo/services/todo_insight_facts.dart`（第 33 行）
- **用途：** 判断一次性任务是否在某日期显示。
- **输入：** `t`、`date` — 被查看的日期、`today`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：**
  1. 无 `scheduledDate` → `false`。
  2. 已完成且有 `completedDate` → 在其计划日和完成日显示。
  3. 否则 → 在其计划日显示，并从计划日起到 `today` 的每一天顺延显示。
- **用法：** `buildTodoInsightFacts` 中的 `oneTimeTasks.where((t) => oneTimeVisibleOn(t, today, today))`（第 112 行）。
- **备注：** 与 Todo 页的 `_oneTimeVisibleOnDate` 规则相同。已完成但没有 `completedDate` 的任务按未完成处理。

### `String _list(List<String> titles, int max)` <a id="_list"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/todo/services/todo_insight_facts.dart`（第 58 行）
- **用途：** 为一条事实行连接任务标题，有上限。
- **输入：** `titles`、`max`。
- **返回：** `String` — 为空时 `none`；前 `max` 项以 `; ` 连接，超出上限时加 `; +k more`。
- **副作用：** 无。
- **算法：** 如「返回」所述。
- **用法：** `buildTodoInsightFacts` 中每条列表型事实行，使用 `maxTasks`（自 v1.5.1 起默认 8）；只有带标题的变体和下午的提醒行使用它。
- **备注：** 无。

### `InsightFacts? buildTodoInsightFacts({required DateTime now, required List<Task> dailyTemplates, required List<Task> oneTimeTasks, required DailyCompletionLog dailyLog, required DailyScoreLog dailyScores, int maxTasks = 8, int maxTitleRunes = 24, bool includeTitles = true})` <a id="buildtodoinsightfacts"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/todo/services/todo_insight_facts.dart`（第 90 行）
- **用途：** 为当前时段构建 Todo 卡片的事实。
- **输入：** `now` — 本地时间；页面的 `dailyTemplates`、`oneTimeTasks`、`dailyLog`、`dailyScores`；`maxTasks` — 每行项数（默认 8；v1.5.1 之前为 12）；`maxTitleRunes` — 每个标题（经 `clipTitle`；默认 24；v1.5.1 之前为 40）；`includeTitles` — `false` 构建只含计数的变体，当模型拒绝带标题的变体或对其一无所答时存储回退到它（v1.5.1）。
- **返回：** `InsightFacts?`，含 `module: todo`、时段、各行、三个槽位和引用词——今天什么都没有且（不在晚上，或明天也什么都没有）无可谈内容时为 null。
- **副作用：** 无。
- **算法：**
  1. 时段 = `todoBucketFor(now)`。今天的每日模板按 `dailyLog.completedIds(today)` 分为已完成和未完成；今天可见的一次性任务按 `isCompleted` 划分。
  2. 两个局部辅助函数：`describeOpen(t)` 是裁剪后的标题加上括号内至多一个限定语——截止日早于今天时为 `overdue`，否则有截止日时为 `due yyyy-MM-dd`，否则为 `HH:mm` 提醒时间，否则没有；`openCounts(habits, tasks)` 为 `none` 或 `N daily habits, M one-off tasks (k overdue)`，其中空的部分和为零的逾期计数省略（`_overdue`）。
  3. 明天：明天可见的每日模板（只发送数量），以及计划日恰为明天的未完成一次性任务。
  4. 今天既无每日任务也无一次性任务时返回 null，除非是晚上且明天有任务。
  5. 引用词：带标题时为今天的每日任务、今天的一次性任务和明天的一次性任务的裁剪后标题（去重）；不带标题时为空列表。
  6. 首行 `- Today: <date> (<weekday>)`，然后按时段：
     - **上午**（及 `none`）：带标题时为 `- Daily habits today (N): <titles>` 和 `- One-off tasks today (M open): <describeOpen…>`；不带标题时为 `- Daily habits today: N` 和针对未完成一次性任务的 `- One-off tasks today: <openCounts>`。然后非零时为 `- Yesterday's self-rating: S on a -5 to 5 scale`。槽位 `plan`（"Today's plan, in one sentence."）、`first`（"Which task to start with, and why."）、`tip`（"One practical tip for today."）。
     - **下午：** `- Done so far: a of N daily habits, b of M one-off tasks`；然后 `- Still open:` 带未完成的习惯标题和 `describeOpen` 一次性任务，不带标题时为 `openCounts`；然后仅当至少一个未完成任务的提醒日内时间晚于 `now` 时为 `- Reminders still ahead today: …`（`<title> at HH:mm`，不带标题时只有 `HH:mm`）。槽位 `progress`（"How today is going so far."）、`remaining`（"What to focus on for the rest of the day."）、`tip`（"One practical tip for the afternoon."）。
     - **晚上：** `- Done today: …` 计数；带标题时为 `- Completed: <titles>` 和 `- Left undone: <titles>`，不带标题时只有 `- Left undone: <openCounts>`；然后非零时为 `- Today's self-rating: S on a -5 to 5 scale`；`- Daily habits tomorrow: N`；以及带标题或只有计数的 `- One-off tasks scheduled for tomorrow:`。槽位 `summary`（"How today went."）、`tomorrow`（"What to do first tomorrow, counting anything left undone."）、`encouragement`（"One short, sincere encouragement."）。
- **用法：**
  ```dart
  final facts = buildTodoInsightFacts(
    now: now,
    dailyTemplates: _dailyTemplates,
    oneTimeTasks: _oneTimeTasks,
    dailyLog: _dailyLog,
    dailyScores: _dailyScores,
  );
  ```
  （`lib/features/todo/views/todo_page.dart`，`_buildAiCard`，第 1438 行；带 `includeTitles: false` 的同一调用紧随其后位于第 1448 行，成为请求的 `fallbackFacts`。由 `test/insight_facts_test.dart` 覆盖。）
- **备注：** 绝不读取任务备注和子任务标题。两个变体使用相同的时段和顺序相同的相同槽位 id，这是 `AiInsightRequest.fallbackFacts` 所要求的。自评为 `0` 与「未评分」无法区分，因而不发送。「之后仍有的提醒」比较只用提醒的日内时间。时段是指纹的一部分，因此跨过 12:00 或 18:00 会重新生成卡片。自 v1.5.1 起刻意保持朴素——v1.5.0 的 `work`/`routine` 标记、*carried over since* 和 *reminder* 措辞已去掉——因为端侧模型回答了其他模块，却没有回答更长、修饰更多的 Todo 提示。

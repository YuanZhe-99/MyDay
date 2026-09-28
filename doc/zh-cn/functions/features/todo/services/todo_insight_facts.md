# lib/features/todo/services/todo_insight_facts.dart

Todo 页端侧 AI 洞察卡片背后的纯事实构建器。`buildTodoInsightFacts` 把页面已加载的 [`Task`](../models/task.md) 列表、完成日志和评分日志按当前[时段](../../ai/services/insight_prompts.md)转成 [`InsightFacts`](../../ai/services/insight_prompts.md)：上午是计划，下午是进度，晚上是回顾和明天的建议。两个可见性辅助函数复述 [Todo 页](../views/todo_page.md)自己关于某日期显示哪些每日模板和一次性任务的规则。任务标题会被发送（经裁剪和限量）；任务备注和子任务标题绝不发送。卡片本身是 [`AiInsightCard`](../../ai/widgets/ai_insight_card.md)，事实由 [`AiInsightStore`](../../ai/services/insight_service.md) 计算指纹。见 [端侧 AI — 每张卡片得到什么](../../../../on-device-ai.md#what-each-card-is-given)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `_day` | 顶层函数（私有） | B | 去掉日内时间。 |
| [`dailyTemplatesOn`](#dailytemplateson) | 顶层函数 | A | 列出某日期显示的每日模板。 |
| [`oneTimeVisibleOn`](#onetimevisibleon) | 顶层函数 | A | 判断一次性任务是否在某日期显示。 |
| `_hm` | 顶层函数（私有） | B | 把日内时间格式化为 `HH:mm`。 |
| [`_list`](#_list) | 顶层函数（私有） | A | 为一条事实行连接任务标题，有上限。 |
| [`buildTodoInsightFacts`](#buildtodoinsightfacts) | 顶层函数 | A | 为当前时段构建 Todo 卡片的事实。 |

`grep -c 'Purpose:' lib/features/todo/services/todo_insight_facts.dart` 报告 6，与上面六个声明精确匹配；不存在未文档化声明。`_day` 和 `_hm` 是一行格式化辅助函数（Tier B）；其余四个承载真实规则。

## 文档

### `List<Task> dailyTemplatesOn(List<Task> templates, DateTime date)` <a id="dailytemplateson"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/todo/services/todo_insight_facts.dart`（第 17 行）
- **用途：** 列出某日期显示的每日模板。
- **输入：** `templates` — 每日模板；`date`。
- **返回：** `List<Task>`。
- **副作用：** 无。
- **算法：** 当 `startDate ?? createdDate` 的日期不晚于 `date` 的日期，且 `deletedDate` 为 null 或其日期晚于 `date` 的日期时保留模板。
- **用法：** `buildTodoInsightFacts` 分别为今天和明天调用它（第 90 和 120 行）。
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
- **用法：** `buildTodoInsightFacts` 中的 `oneTimeTasks.where((t) => oneTimeVisibleOn(t, today, today))`（第 96 行）。
- **备注：** 与 Todo 页的 `_oneTimeVisibleOnDate` 规则相同。已完成但没有 `completedDate` 的任务按未完成处理。

### `String _list(List<String> titles, int max)` <a id="_list"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/todo/services/todo_insight_facts.dart`（第 58 行）
- **用途：** 为一条事实行连接任务标题，有上限。
- **输入：** `titles`、`max`。
- **返回：** `String` — 为空时 `none`；前 `max` 项以 `; ` 连接，超出上限时加 `; +k more`。
- **副作用：** 无。
- **算法：** 如「返回」所述。
- **用法：** `buildTodoInsightFacts` 中每条列表型事实行，使用 `maxTasks`。
- **备注：** 无。

### `InsightFacts? buildTodoInsightFacts({required DateTime now, required List<Task> dailyTemplates, required List<Task> oneTimeTasks, required DailyCompletionLog dailyLog, required DailyScoreLog dailyScores, int maxTasks = 12, int maxTitleRunes = 40})` <a id="buildtodoinsightfacts"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/todo/services/todo_insight_facts.dart`（第 75 行）
- **用途：** 为当前时段构建 Todo 卡片的事实。
- **输入：** `now` — 本地时间；页面的 `dailyTemplates`、`oneTimeTasks`、`dailyLog`、`dailyScores`；`maxTasks` — 每行项数；`maxTitleRunes` — 每个标题（经 `clipTitle`）。
- **返回：** `InsightFacts?`，含 `module: todo`、时段、各行、三个槽位和引用词——今天什么都没有且（不在晚上，或明天也什么都没有）无可谈内容时为 null。
- **副作用：** 无。
- **算法：**
  1. 时段 = `todoBucketFor(now)`。今天的每日模板按 `dailyLog.completedIds(today)` 分为已完成和未完成；今天可见的一次性任务按 `isCompleted` 划分。
  2. 明天：明天可见的每日模板（只发送数量），以及计划日恰为明天的未完成一次性任务。
  3. 今天既无每日任务也无一次性任务时返回 null，除非是晚上且明天有任务。
  4. 引用词：今天的每日任务、今天的一次性任务和明天的一次性任务的裁剪后标题（去重）。
  5. 首行 `- Today: <date> (<weekday>)`，然后按时段：
     - **上午**（及 `none`）：今天的每日习惯；未完成的一次性任务，每项描述为 `work`/`routine`，并带 *carried over since*、*overdue since* / *due* 和 *reminder HH:mm*；昨天的自评（非零时）。槽位 `plan`、`first`、`tip`。
     - **下午：** 每日和一次性的完成计数；仍未完成的内容；今天之后仍有的提醒（提醒的日内时间晚于现在）。槽位 `progress`、`remaining`、`tip`。
     - **晚上：** 完成计数；已完成标题；未完成标题；今天的自评（非零时）；明天的每日习惯数；明天计划的一次性任务。槽位 `summary`、`tomorrow`、`encouragement`。
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
  （`lib/features/todo/views/todo_page.dart`，`_buildAiCard`，第 1454 行；由 `test/insight_facts_test.dart` 覆盖。）
- **备注：** 绝不读取任务备注和子任务标题。自评为 `0` 与「未评分」无法区分，因而不发送。「之后仍有的提醒」比较只用提醒的日内时间。时段是指纹的一部分，因此跨过 12:00 或 18:00 会重新生成卡片。

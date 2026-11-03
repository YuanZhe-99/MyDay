# lib/shared/services/home_widget_actions.dart

交互式桌面小组件控件所排队动作的纯应用器（1.8.3）：待办复选框（`setDone`）和计时器按钮（`start`、`pause`、`add`）。原生端只把点击排队并绘制乐观覆盖层；之后 [`HomeWidgetService._drain`](home_widget_service.md#_drain) 加载数据文件，运行对应的应用器并写入结果。语义与 [交互控件](../../../features/home-screen-widgets.md#interactive-controls) 中描述的原生覆盖层一致。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `HomeWidgetActionResult`（构造函数） | const 构造函数（`HomeWidgetActionResult<T>`） | B | 保存一轮应用的结果：数据、已处理 id、是否有变化。 |
| [`applyTodo`](#applytodo) | 静态方法（`HomeWidgetActions`） | A | 把排队的 `myday.todo` 动作应用到待办数据。 |
| [`applyTimer`](#applytimer) | 静态方法（`HomeWidgetActions`） | A | 把排队的 `myday.timer` 动作应用到计时器会话。 |
| [`_timelineOf`](#_timelineof) | 静态方法（`HomeWidgetActions`） | A | 返回会话的抽插时间线，必要时由其计数播种一条。 |

**对账：** `grep -c 'Purpose:' lib/shared/services/home_widget_actions.dart` 报告 4，与上面 4 行匹配。`HomeWidgetActionResult` 的字段只带普通 `///` 注释，不列出。

## 文档

### `static HomeWidgetActionResult<TodoData> applyTodo(TodoData data, List<WidgetAction> actions, {DateTime? now})` <a id="applytodo"></a>
- **种类：** `HomeWidgetActions` 的静态方法
- **来源：** `lib/shared/services/home_widget_actions.dart`（第 45 行）
- **用途：** 把排队的 `myday.todo` 动作应用到待办数据。
- **输入：** `data`；`actions`——最早的在前；`now`——用于 `modifiedAt`（默认取当前时钟）。
- **返回：** 更新后的数据、每个已处理的 id，以及是否有变化。
- **副作用：** 每日任务变化时原地修改 `data.dailyLog`。
- **算法：**
  1. 每个动作 id 都记为已处理。跳过 `setDone` 以外的动作，以及 `id`、`done` 或 `date` 参数缺失或格式错误的动作。
  2. 每日模板：若它当天的完成状态与 `done` 不同，则在 `dailyLog` 中切换，并把其子任务设为相同状态。
  3. 一次性任务：已处于该状态或要完成一个重复任务时跳过；否则替换为一个副本，其完成状态、子任务和 `completedDate` 跟随 `done`，并盖上 UTC `modifiedAt`。
  4. 没有变化时原样返回输入，否则返回带新一次性任务列表的新 `TodoData`。
- **用法：** `HomeWidgetService._drain`。
- **备注：** `setDone` 设置状态而不是切换，因此重复投递的动作无害。完成重复的一次性任务会被跳过，因为它的复选框改为打开应用，以便显示下一次发生的提示。未知 id 被跳过。

### `static HomeWidgetActionResult<IntimacyTimerSession?> applyTimer(IntimacyTimerSession? session, List<WidgetAction> actions)` <a id="applytimer"></a>
- **种类：** `HomeWidgetActions` 的静态方法
- **来源：** `lib/shared/services/home_widget_actions.dart`（第 136 行）
- **用途：** 把排队的 `myday.timer` 动作应用到计时器会话。
- **输入：** `session`——当前会话或 null；`actions`——最早的在前。
- **返回：** 新会话、每个已处理的 id，以及是否有变化。
- **副作用：** 无。
- **算法：**
  1. 从会话的首次开始时间、运行中的开始时间、累计时间和时间线（由 `_timelineOf` 播种）出发，或从空状态出发。
  2. `start`（未运行时）在缺失时设置首次开始时间，并在点击时刻开始一段；`pause`（运行时）把该段并入累计时间，绝不为负；`add`（已开始后）在点击时的已用时间记录 `n`（默认 `timerStep`）。
  3. 没有变化时返回输入会话。否则按计时器页面的方式存储计数：总数是 100 的倍数时单位为 100，否则单位为 1。
- **用法：** 计时器页面关闭时由 `HomeWidgetService._drain` 调用。
- **备注：** `TimerPage._applyWidgetActions` 对已打开页面的内存状态应用相同语义。

### `static ThrustTimeline _timelineOf(IntimacyTimerSession session)` <a id="_timelineof"></a>
- **种类：** `HomeWidgetActions` 的私有静态方法
- **来源：** `lib/shared/services/home_widget_actions.dart`（第 209 行）
- **用途：** 返回会话的抽插时间线，必要时由其计数播种一条。
- **输入：** `session`。
- **返回：** `ThrustTimeline`。
- **副作用：** 无。
- **算法：** 存储的时间线总数等于 `HomeWidgetPayloads.sessionCount` 时保留它；否则 `ThrustTimeline.seed(accumulatedMs, count)`。
- **用法：** `applyTimer`。
- **备注：** 与 `TimerPage._restoreTimeline` 一致，把 1.5.5 之前的计数播种在会话的累计时间处。

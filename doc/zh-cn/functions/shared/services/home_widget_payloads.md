# lib/shared/services/home_widget_payloads.dart

`HomeWidgetPayloads` 包含桌面小组件 payload 的纯构建器（1.8.3）。每个构建器把一个模块的数据转换为一个 MyApps-Widget 信封中由应用拥有的 `payload` 对象；[`HomeWidgetService`](home_widget_service.md) 把它包进信封并发布，设置页预览也从同样的映射绘制。这里不读取文件，也没有副作用，单元测试正依赖这一点。逐字段格式见 [快照格式](../../../features/home-screen-widgets.md#snapshot-format-envelope-1-payload-version-1)。每个 payload 都带有 `mask` 标志和一个含 `{n}`/`{m}` 占位符的本地化字符串 `labels` 映射，因此原生渲染器不需要自己的翻译。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| 上限与步长常量 | 静态常量（`HomeWidgetPayloads`） | B | `maxTodoItems`（30）、`maxAppliedActions`（50）、`maxWeightPoints`（30）、`timerStep`（100）。 |
| `dayKey` | 静态方法（`HomeWidgetPayloads`） | B | 把本地日历日期格式化为 `yyyy-MM-dd`（与 `DailyCompletionLog.dateKey` 相同的键）。 |
| `hhmm` | 静态方法（`HomeWidgetPayloads`） | B | 把时刻格式化为 `HH:mm`；null 为空。 |
| [`todo`](#todo) | 静态方法（`HomeWidgetPayloads`） | A | 构建含今天和明天的 `myday.todo` payload。 |
| [`todoItems`](#todoitems) | 静态方法（`HomeWidgetPayloads`） | A | 按显示顺序列出某一天的待办行。 |
| `_todoItem` | 静态方法（`HomeWidgetPayloads`） | B | 用短键序列化一行待办。 |
| [`weight`](#weight) | 静态方法（`HomeWidgetPayloads`） | A | 构建 `myday.weight` payload。 |
| [`finance`](#finance) | 静态方法（`HomeWidgetPayloads`） | A | 构建含格式化金额的 `myday.finance` payload。 |
| [`intimacy`](#intimacy) | 静态方法（`HomeWidgetPayloads`） | A | 构建 `myday.intimacy` payload。 |
| [`timer`](#timer) | 静态方法（`HomeWidgetPayloads`） | A | 构建 `myday.timer` payload。 |
| [`sessionCount`](#sessioncount) | 静态方法（`HomeWidgetPayloads`） | A | 返回计时器会话的实际次数。 |
| `_tail` | 静态方法（`HomeWidgetPayloads`） | B | 保留最新的 `maxAppliedActions` 个已应用动作 id。 |
| `_round1` | 静态方法（`HomeWidgetPayloads`） | B | 四舍五入到一位小数。 |

**对账：** `grep -c 'Purpose:' lib/shared/services/home_widget_payloads.dart` 报告 12，对应上面 13 行。多出的一行把四个 `static const` 上限分为一组，它们是带普通 `///` 注释、没有 `Purpose:` 块的真实声明。

## 文档

### `static Map<String, dynamic> todo(TodoData? data, {required DateTime now, required AppLocalizations l10n, required String localeTag, List<String> appliedActions = const [], bool mask = false})` <a id="todo"></a>
- **种类：** `HomeWidgetPayloads` 的静态方法
- **来源：** `lib/shared/services/home_widget_payloads.dart`（第 56 行）
- **用途：** 构建 `myday.todo` payload。
- **输入：** `data`（文件不存在时为 null）；`now`——本地时间；`l10n`；用于日期标签的 `localeTag`；`appliedActions`；`mask`。
- **返回：** 含 `days`（今天和明天，各含 `date`、`label`、`score` 和 `items`）、`appliedActions`、`mask` 和 `labels` 的映射。
- **副作用：** 无。
- **算法：** 对今天和 `addCalendarDays(today, 1)`，输出日期键、`DateFormat.MMMEd` 标签、当天评分和 `todoItems(...)`；通过 `_tail` 附上最新的已应用 id。
- **用法：** `HomeWidgetService.payloadBuilders`。
- **备注：** 每一天列出待办页在该日期会显示的内容。有了明天，小组件无需应用运行即可在午夜翻页。

### `static List<Map<String, dynamic>> todoItems(TodoData data, {required DateTime day, required DateTime today})` <a id="todoitems"></a>
- **种类：** `HomeWidgetPayloads` 的静态方法
- **来源：** `lib/shared/services/home_widget_payloads.dart`（第 102 行）
- **用途：** 按显示顺序列出某一天的待办行。
- **输入：** `data`；`day`——显示的日期；`today`——真实的当前日期。
- **返回：** 至多 `maxTodoItems` 个条目映射。
- **副作用：** 无。
- **算法：**
  1. 到 `day` 已开始且未在该日之前删除的每日模板，完成状态取自 `dailyLog.isCompleted`。
  2. 有计划日期的日常和工作一次性任务（依此顺序）：已完成任务显示在计划日或完成日；未完成任务显示在计划日，或顺延到直至明天的任何一天。`late` 标记计划日或截止日早于 `day` 的未完成任务。
  3. 排序：逾期在前，然后未完成任务按提醒时间（无时间者在后，分区顺序作为平局决胜），然后已完成任务；取前 `maxTodoItems` 个。
- **用法：** `todo`。
- **备注：** 可见性与 `TodoPage._dailyForDate` 和 `_oneTimeVisibleOnDate` 一致。

### `static Map<String, dynamic> weight(WeightData? data, {required DateTime now, required AppLocalizations l10n, bool mask = false})` <a id="weight"></a>
- **种类：** `HomeWidgetPayloads` 的静态方法
- **来源：** `lib/shared/services/home_widget_payloads.dart`（第 194 行）
- **用途：** 构建 `myday.weight` payload。
- **输入：** `data`（无文件时为 null）；`now`；`l10n`；`mask`。
- **返回：** 含 `latest`（`kg`、以毫秒计的 UTC `at`）、`previousKg`、`change30`、`bmi`、`points`、`remindAt`、`mask` 和 `labels` 的映射。
- **副作用：** 无。
- **算法：** 按时间排序记录。`change30` 把最新记录与 30 天前或更早的最新一条比较，没有时回退到最近 30 天内最早的一条（若那就是最新记录本身则为 null）。`points` 是该窗口内最后 `maxWeightPoints` 个体重，保留一位小数。除非提醒关闭，`remindAt` 为早间提醒时间。
- **用法：** `HomeWidgetService.payloadBuilders`。
- **备注：** 单位始终为 `kg`。

### `static Map<String, dynamic> finance(FinanceData? data, {required ExchangeRateData rates, required DateTime now, required AppLocalizations l10n, required String localeTag, bool mask = false})` <a id="finance"></a>
- **种类：** `HomeWidgetPayloads` 的静态方法
- **来源：** `lib/shared/services/home_widget_payloads.dart`（第 269 行）
- **用途：** 构建 `myday.finance` payload。
- **输入：** `data`（无文件时为 null）；`rates`；`now`；`l10n`；`localeTag`；`mask`。
- **返回：** 含 `month`、`monthLabel`、格式化的 `expense`、`income` 和 `net`、`netNegative`、`top`（支出最多的分类及其占比）、`bills`（至多三条）、`mask` 和 `labels` 的映射。
- **副作用：** 无。
- **算法：** 汇总本日历月的每笔支出和收入交易（不含转账），每笔按其自身的汇率快照换算为默认货币；按分类汇总支出得到 `top`；列出 7 天内前三个 `upcomingSubscriptions` 作为 `bills`。
- **用法：** `HomeWidgetService.payloadBuilders`。
- **备注：** 合计与财务首页摘要一致。金额是预先格式化的字符串，因此原生端不需要货币逻辑。

### `static Map<String, dynamic> intimacy(IntimacyData? data, {required DateTime now, required AppLocalizations l10n, bool mask = false})` <a id="intimacy"></a>
- **种类：** `HomeWidgetPayloads` 的静态方法
- **来源：** `lib/shared/services/home_widget_payloads.dart`（第 367 行）
- **用途：** 构建 `myday.intimacy` payload。
- **输入：** `data`（无文件时为 null）；`now`；`l10n`；`mask`。
- **返回：** 含 `lastAt`、`month`、`monthCount`、`avgMinutes`、`cycleNext`、`mask` 和 `labels` 的映射。
- **副作用：** 无。
- **算法：** 找出最新记录，统计本月记录数，并以分钟计算有时长记录的平均值。用户启用了周期跟踪时，对用户自己的周期开始日运行 `predictCycle`，保留从今天起的第一个预测开始日。
- **用法：** `HomeWidgetService.payloadBuilders`，仅在亲密模块可见时。
- **备注：** 周期行只使用用户自己的记录（`personId` 为 null）。标签使用中性的「私密」措辞。

### `static Map<String, dynamic> timer(IntimacyData? data, {required AppLocalizations l10n, List<String> appliedActions = const [], bool mask = false})` <a id="timer"></a>
- **种类：** `HomeWidgetPayloads` 的静态方法
- **来源：** `lib/shared/services/home_widget_payloads.dart`（第 436 行）
- **用途：** 构建 `myday.timer` payload。
- **输入：** `data`（无文件时为 null）；`l10n`；`appliedActions`；`mask`。
- **返回：** 含 `session`（`running`、`startedAt`、`accumulatedMs`、`count`）或 null、`last`（`at`、`durationMs`）或 null、`step`、`appliedActions`、`mask` 和 `labels` 的映射。
- **副作用：** 无。
- **算法：** `last` 是记录和计时器历史条目中最新的一条；`session.count` 来自 `sessionCount`；`startedAt` 只在运行时设置。
- **用法：** `HomeWidgetService.payloadBuilders`，仅在亲密模块可见时。
- **备注：** 运行时，原生小组件自己从 `startedAt` 开始计时。

### `static int sessionCount(IntimacyTimerSession session)` <a id="sessioncount"></a>
- **种类：** `HomeWidgetPayloads` 的静态方法
- **来源：** `lib/shared/services/home_widget_payloads.dart`（第 497 行）
- **用途：** 返回计时器会话的实际次数。
- **输入：** `session`。
- **返回：** `int`。
- **副作用：** 无。
- **算法：** 有时间线时取时间线总数；否则计数非正时为 0，其余为 `thrustCount` 乘以 `thrustCountUnit`（单位 1 保持不变）。
- **用法：** `timer` 和 `HomeWidgetActions._timelineOf`。
- **备注：** 无。

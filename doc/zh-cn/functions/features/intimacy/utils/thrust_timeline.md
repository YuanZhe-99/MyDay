# lib/features/intimacy/utils/thrust_timeline.dart

抽插时间线（v1.5.5）：一次秒表会话中抽插计数按钮各次按下的时间顺序列表，见 [亲密 — 计时器/秒表会话持久化](../../../../features/intimacy.md#timerstopwatch-session-persistence)。`ThrustEvent` 是一次按下（`elapsedMs`、`delta`）；`ThrustTimeline` 是由它们组成的不可变、按时间排序的列表，其 `total` 就是该会话的实际次数。计时器页（[`timer_page.dart`](../widgets/timer_page.md)）从时间线派生活计数器，用 [`add`](#add) 记录按下、用 [`undo`](#undo) 处理 `-100` 按钮；[`intimacy_record.dart`](../models/intimacy_record.md) 中的三个模型经 [`toJson`](#tojson)/[`fromJson`](#fromjson) 把它持久化在 `thrustTimeline` 键下；[`ThrustTimelineChart`](../widgets/thrust_timeline_chart.md) 用 [`cumulativeSpots`](#cumulativespots) 和 [`smoothedSpots`](#smoothedspots) 绘制它。本文件只导入 `fl_chart`（为了 `FlSpot`），没有其他 Flutter 依赖，因此每条规则都在 `test/thrust_timeline_test.dart` 中做单元测试。

不变量，由每个构建新时间线的方法维持：事件按 `elapsedMs` 排序，每个 `delta` 都为正，因此累计计数随时间**绝不下降**。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `ThrustEvent(elapsedMs, delta)` | 构造函数（`ThrustEvent`） | B | 创建一个抽插计数事件。 |
| `operator ==` | 运算符（`ThrustEvent`） | B | 按值比较两个事件（两个字段）。 |
| `hashCode` | getter（`ThrustEvent`） | B | 以与 `==` 一致的方式对事件求哈希。 |
| `toString` | 方法（`ThrustEvent`） | B | 把事件描述为 `+<delta>@<elapsedMs>ms`，供调试和测试失败信息使用。 |
| `ThrustTimeline(events)` | 构造函数（`ThrustTimeline`） | B | 把已有效的事件包进不可修改列表，不做校验。 |
| `ThrustTimeline.empty` | 工厂构造函数（`ThrustTimeline`） | B | 返回没有按下的时间线。 |
| [`ThrustTimeline.seed`](#seed) | 工厂构造函数（`ThrustTimeline`） | A | 从没有按下时间的计数构建单事件时间线。 |
| [`total`](#total) | getter（`ThrustTimeline`） | A | 返回记录的总次数（各 delta 之和）。 |
| `isEmpty` | getter（`ThrustTimeline`） | B | 报告是否没有记录任何按下。 |
| `lastElapsedMs` | getter（`ThrustTimeline`） | B | 返回最近一次按下的秒表时间，为空时为 0。 |
| [`add`](#add) | 方法（`ThrustTimeline`） | A | 记录一次增加次数的按下。 |
| [`undo`](#undo) | 方法（`ThrustTimeline`） | A | 撤销最近的按下，直到恰好移除 `amount`。 |
| [`toJson`](#tojson) | 方法（`ThrustTimeline`） | A | 把时间线序列化为 `[[elapsedMs, delta], ...]`。 |
| [`fromJson`](#fromjson) | 静态方法（`ThrustTimeline`） | A | 从 JSON 读取时间线，绝不抛出。 |
| [`cumulativeSpots`](#cumulativespots) | 方法（`ThrustTimeline`） | A | 为记录图表构建累计阶梯序列。 |
| [`smoothedSpots`](#smoothedspots) | 方法（`ThrustTimeline`） | A | 为记录图表构建平滑（移动平均）拟合线。 |
| `_sortByTime` | 顶层函数（私有） | B | 按时间对事件做原地稳定插入排序。 |

`grep -c 'Purpose:' lib/features/intimacy/utils/thrust_timeline.dart` 报告 17，与上面 17 行精确匹配（8 个 Tier A、9 个 Tier B）。两个静态常量 `ThrustTimeline.jsonKey`（`'thrustTimeline'`，记录、计时器历史条目和计时器会话使用的 JSON 键）和 `ThrustTimeline.maxTotal`（`999999`，计时器计数器先前的钳制上限）带普通 `///` 注释而不是 `Purpose:` 块，不占行，与其他亲密页面对待类级常量的方式一致；它们在使用它们的条目中说明。`ThrustEvent` 的字段 `elapsedMs`、`delta` 和 `events` 列表是普通数据持有者。

## 文档

### `factory ThrustTimeline.seed(int elapsedMs, int count)` <a id="seed"></a>
- **种类：** `ThrustTimeline` 的工厂构造函数
- **来源：** `lib/features/intimacy/utils/thrust_timeline.dart`（第 83 行）
- **用途：** 把一个裸总数——从未有过按下时间的数据——变成时间线。
- **输入：** `elapsedMs` — 事件放置的位置；`count` — 实际次数。
- **返回：** `ThrustTimeline` — `count <= 0` 时为空，否则恰好一个事件。
- **副作用：** 无。
- **算法：** `count <= 0` 返回 `ThrustTimeline.empty()`；否则一个 `ThrustEvent(max(elapsedMs, 0), count.clamp(1, maxTotal))`。
- **用法：**
  ```dart
  // timer_page.dart, _restoreTimeline, line 150:
  return ThrustTimeline.seed(elapsed.inMilliseconds, actual);
  ```
- **备注：** 用于 v1.5.5 之前保存、只存了总数的计时器会话和历史条目，以及存储的时间线总数与存储计数不符的情况。单个事件绝不绘制图表（图表和 `IntimacyRecord.hasThrustTimeline` 至少需要两个），因此植入的数据显示与以前相同的计数且没有曲线。

### `int get total` <a id="total"></a>
- **种类：** `ThrustTimeline` 的 getter
- **来源：** `lib/features/intimacy/utils/thrust_timeline.dart`（第 95 行）
- **用途：** 返回会话的实际次数。
- **输入：** 无。
- **返回：** `int` — 每个事件 `delta` 之和。
- **副作用：** 无。
- **算法：** `events.fold(0, (sum, e) => sum + e.delta)`。
- **用法：**
  ```dart
  // timer_page.dart, line 131 — the live counter is derived, never stored separately:
  int get _thrustCount => _timeline.total;

  // add_record_dialog.dart, _submit, line 546 — keep the timeline only if it still matches:
  final timeline = _timeline != null && _timeline.total == resolvedCount ? _timeline : null;
  ```
- **备注：** 因为计时器的计数器就是这个 getter，显示的计数与从同一时间线绘制的曲线绝不会不一致。

### `ThrustTimeline add(int elapsedMs, int delta)` <a id="add"></a>
- **种类：** `ThrustTimeline` 的方法
- **来源：** `lib/features/intimacy/utils/thrust_timeline.dart`（第 118 行）
- **用途：** 在当前秒表时间记录一次 `+100`/`+50`/`+10` 按下。
- **输入：** `elapsedMs` — 按下时的秒表时间；`delta` — 要增加的次数。
- **返回：** `ThrustTimeline` — 新时间线，无变化时为 `this`（同一对象）。
- **副作用：** 无。
- **算法：**
  1. `delta <= 0`，或 `total + delta > maxTotal`，返回 `this`——忽略这次按下。
  2. `at = max(elapsedMs, lastElapsedMs)`（且绝不低于 0），使秒表以少于最近一次按下的已流逝时间恢复时，列表也保持有序。
  3. 返回追加了 `ThrustEvent(at, delta)` 的新时间线。
- **用法：**
  ```dart
  // timer_page.dart, _changeThrustCount, lines 327-329:
  final next = delta < 0
      ? _timeline.undo(-delta)
      : _timeline.add(_elapsed.inMilliseconds, delta);
  if (identical(next, _timeline)) return;
  ```
- **备注：** 无操作时返回 `this`，使计时器页能用 `identical` 检查跳过 `setState` 和持久化写入。会超过 `maxTotal` 的按下被整体丢弃；v1.5.5 之前的计数器则是钳制总和。

### `ThrustTimeline undo(int amount)` <a id="undo"></a>
- **种类：** `ThrustTimeline` 的方法
- **来源：** `lib/features/intimacy/utils/thrust_timeline.dart`（第 134 行）
- **用途：** 把计时器的 `-100` 按钮实现为对最近按下的撤销。
- **输入：** `amount` — 要移除的次数（计时器传 100）。
- **返回：** `ThrustTimeline` — 新时间线；`amount <= 0` 或时间线为空时为 `this`。
- **副作用：** 无。
- **算法：** 复制事件；`remaining = amount`；当 `remaining > 0` 且仍有事件时，移除最后一个事件：若其 `delta <= remaining`，减去它并继续；否则放回 `ThrustEvent(last.elapsedMs, last.delta - remaining)` 并停止。
- **用法：** 由 `_changeThrustCount` 调用 `_timeline.undo(-delta)`（见 [`add`](#add)）。
- **备注：** 只要总数允许，就恰好移除 `amount`。能整体放下的按下从末尾整体移除；放不下的那次按下被**修剪（拆分）**而不是移除，保留其原时间。例子：`+50, +10, +50` 减 100 先移除最后的 `+50` 和 `+10`（共 60），再把第一个 `+50` 修剪掉剩余的 40，留下位于**第一次**按下时间的单个 `+10`；`+100, +50, +50` 减 100 留下 `+100`；`+10, +150` 减 100 留下 `+10, +50`。总数低于 `amount` 时全部移除。各 delta 保持为正，因此累计曲线保持不下降。`test/thrust_timeline_test.dart` 检查这些情形，并在随机按下序列上把总数与普通钳制计数器对比。

### `List<List<int>> toJson()` <a id="tojson"></a>
- **种类：** `ThrustTimeline` 的方法
- **来源：** `lib/features/intimacy/utils/thrust_timeline.dart`（第 155 行）
- **用途：** 为 `intimacy_data.json` 序列化时间线。
- **输入：** 无。
- **返回：** `List<List<int>>` — `[[elapsedMs, delta], ...]`，最早的在前。
- **副作用：** 无。
- **算法：** 每个事件一个二元列表。
- **用法：**
  ```dart
  // intimacy_record.dart, IntimacyRecord.toJson, lines 565-566 (same shape in the other two models):
  if (thrustTimeline != null)
    ThrustTimeline.jsonKey: thrustTimeline!.toJson(),
  ```
- **备注：** 没有时间线时调用方完全省略该键；模型把空时间线规范化为 `null`，因此绝不写入 `[]`。格式见 [数据格式](../../../../data-formats.md#intimacy--intimacy_datajson)。

### `static ThrustTimeline? fromJson(Object? raw)` <a id="fromjson"></a>
- **种类：** `ThrustTimeline` 的静态方法
- **来源：** `lib/features/intimacy/utils/thrust_timeline.dart`（第 166 行）
- **用途：** 从 JSON 读取 `thrustTimeline` 的值，容忍损坏。
- **输入：** `raw` — 该键解码后的值，或 `null`。
- **返回：** `ThrustTimeline?` — 缺失、不是列表或没有剩下任何有效对时为 `null`。
- **副作用：** 无。
- **算法：**
  1. `raw is! List` 返回 `null`。
  2. 对每一项：跳过任何不是至少含两个数字的列表；两者都用 `toInt()` 截断；跳过负时间或非正 delta。
  3. 没有幸存者时返回 `null`；否则 `_sortByTime`（稳定插入排序，因此同一时间的按下保持记录顺序）并包装。
- **用法：**
  ```dart
  // intimacy_record.dart, IntimacyRecord.fromJson, line 603:
  thrustTimeline: ThrustTimeline.fromJson(json[ThrustTimeline.jsonKey]),
  ```
- **备注：** 绝不抛出：损坏的时间线绝不能让整个数据文件不可读。它不对照记录计数检查总数——`AddRecordDialog._submit` 在写入时强制这一点，计时器页在两者不符时于恢复时重新植入。

### `List<FlSpot> cumulativeSpots({required int durationMs})` <a id="cumulativespots"></a>
- **种类：** `ThrustTimeline` 的方法
- **来源：** `lib/features/intimacy/utils/thrust_timeline.dart`（第 190 行）
- **用途：** 构建图表作为阶梯线绘制的原始累计计数序列。
- **输入：** `durationMs` — 记录时长，用于延长最后一级。
- **返回：** `List<FlSpot>` — x 以分钟计，y 为累计次数。
- **副作用：** 无。
- **算法：** 从 `(0, 0)` 开始；每个事件在 `(elapsedMs / 60000, 累计总数)` 添加一个点；若 `durationMs > lastElapsedMs`，添加最终的 `(durationMs / 60000, total)`，使最后一段平台延伸到会话结束。
- **用法：**
  ```dart
  // thrust_timeline_chart.dart, build, line 76:
  final raw = timeline.cumulativeSpots(durationMs: durationMs);
  ```
- **备注：** 供 `LineChartBarData(isStepLineChart: true)` 使用：每个点保持其值直到下一个点，因此线条在两次按下之间平坦、在每次按下处跳升。

### `List<FlSpot> smoothedSpots({required int durationMs, int samples = 60, double windowFraction = 0.10})` <a id="smoothedspots"></a>
- **种类：** `ThrustTimeline` 的方法
- **来源：** `lib/features/intimacy/utils/thrust_timeline.dart`（第 214 行）
- **用途：** 构建以虚线画在阶梯线上的平滑拟合线。
- **输入：** `durationMs` — 记录时长；`samples` — 重采样点数（60）；`windowFraction` — 移动平均窗口占时间跨度的比例（0.10）。
- **返回：** `List<FlSpot>` — x 以分钟计；事件少于两个、采样少于两个或跨度为零时为空。
- **副作用：** 无。
- **算法：**
  1. `span = max(durationMs, lastElapsedMs)`；`times[i] = span * i / (samples - 1)`。
  2. 对累计阶梯函数重采样：`values[i]` 是所有 `elapsedMs <= times[i]` 的 delta 之和。
  3. 边缘截断窗口的居中移动平均：`half = round(samples * windowFraction / 2)` 钳制到 `[1, samples]`——默认值下为 3 个采样、7 个采样宽的窗口——`smoothed[i]` 是 `values[max(0, i-half) .. min(samples-1, i+half)]` 的均值。
  4. 固定两端：`smoothed[0] = 0`，`smoothed[last] = total`。
- **用法：**
  ```dart
  // thrust_timeline_chart.dart, build, line 77:
  final smooth = timeline.smoothedSpots(durationMs: durationMs);
  ```
- **备注：** 结果可证明**不下降**：重采样序列不下降，而窗口每滑动一步，要么把最旧的值换成一个更晚、不更小的值，要么（在边缘，窗口变大或变小时）加入一个不小于窗口均值的值或丢掉其最小值。把第一个点固定为 0、最后一个点固定为 `total` 不破坏这一点，因为每个均值都介于 0 和 `total` 之间。所以拟合线绝不下降——用其他方式拟合的曲线（穿过各次按下的样条、多项式）无法保证这一点。

## 相关页面

- [亲密 — 计时器/秒表会话持久化](../../../../features/intimacy.md#timerstopwatch-session-persistence) — 面向用户的规则：按下时间戳、撤销并拆分的 `-100`、v1.5.5 之前数据的植入，以及图表。
- [`timer_page.dart`](../widgets/timer_page.md) — 时间线的唯一写入方：`_changeThrustCount`、`_restoreTimeline`、`_saveRecord`。
- [`intimacy_record.dart`](../models/intimacy_record.md) — 携带 `thrustTimeline` 的三个模型，以及 `IntimacyRecord.hasThrustTimeline`。
- [`add_record_dialog.dart`](../widgets/add_record_dialog.md) — 只在时间线总数等于输入计数时于保存时保留它。
- [`thrust_timeline_chart.dart`](../widgets/thrust_timeline_chart.md) — 绘制这两个序列。
- [数据格式](../../../../data-formats.md#intimacy--intimacy_datajson) — JSON 形状。

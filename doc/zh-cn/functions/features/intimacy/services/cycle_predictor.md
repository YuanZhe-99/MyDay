# lib/features/intimacy/services/cycle_predictor.dart

纯 Dart、无 Flutter 导入：基于中位数的月经周期长度估算，以及仅从记录的周期开始日期做完整阶段/生育窗口/排卵预测。`widgets/body_section.dart` 和 `views/intimacy_page.dart` 是两个调用方——身体标签周期日历中每人一个，主页多人员叠一个。所有预测都是统计估计；它们绝不被呈现为避孕或医疗指导，UI 附加强制免责声明（见 [亲密](../../../../features/intimacy.md#the-body-layer-v124)）。本文件实现的算法完整走查见 [身体指标 — 周期预测](../../../../algorithms/body-metrics.md#cycle-prediction)。

## 声明

锚点说明：本文件每个名字都唯一，因此所有 Tier A 行使用普通裸名锚点、无类限定。

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `minValidCycleDays` | 顶层常量 | B | `15` — 比这短的间隔是数据错误，不是周期。 |
| `maxValidCycleDays` | 顶层常量 | B | `90` — 比这长的间隔是未跟踪缺口，不是周期。 |
| `medianCycleWindow` | 顶层常量 | B | `6` — 只有最近 6 个有效周期长度进入中位数。 |
| `defaultCycleLengthDays` | 顶层常量 | B | `28` — 少于两个有效记录时使用。 |
| `assumedMenstrualDays` | 顶层常量 | B | `5` — 从每个开始日期假定的出血天数。 |
| `ovulationOffsetDays` | 顶层常量 | B | `14` — 排卵估计在下一次开始前的天数。 |
| `predictionHorizonDays` | 顶层常量 | B | `366` — 预测生成到锚点前方多远。 |
| `CyclePhase`（枚举） | 枚举 | B | `menstrual` / `follicular` / `luteal`——无 Purpose 块（见对账）。 |
| [`CycleDayInfo()`](#cycledayinfo-new) | 构造函数（`CycleDayInfo`） | A | 创建逐日周期分类值（阶段和标记标志）。 |
| [`CyclePrediction()`](#cycleprediction-new) | 构造函数（`CyclePrediction`） | A | 创建预测输出值（周期长度、预测开始、逐日映射）。 |
| `CyclePrediction.empty` | 静态常量（`CyclePrediction`） | B | 零记录回退预测（默认周期长度、无开始、无天）。 |
| [`dateOnly`](#dateonly) | 顶层函数 | A | 把 `DateTime` 规范化为纯日期本地值。 |
| [`_addDays`](#_adddays) | 私有顶层函数 | A | 向纯日期值加日历天。 |
| [`_daysBetween`](#_daysbetween) | 私有顶层函数 | A | 统计两个纯日期值之间的整日历天。 |
| [`estimateCycleLength`](#estimatecyclelength) | 顶层函数 | A | 把前向周期长度估计为最近有效周期的中位数。 |
| [`predictCycle`](#predictcycle) | 顶层函数 | A | 为一个人预测周期阶段、生育窗口和未来开始日期。 |

**对账：** `grep -c 'Purpose:' lib/features/intimacy/services/cycle_predictor.dart` 报告 7，与上面带链接/锚点的 7 行精确匹配：`CycleDayInfo` 和 `CyclePrediction` 的构造函数加五个顶层函数（`dateOnly`、`_addDays`、`_daysBetween`、`estimateCycleLength`、`predictCycle`）。那 7 个 `/// Purpose:` 块每个都恰好位于其文档化的真实声明正上方——未发现错附块。表格在那 7 行之外还有 9 行：七个公共顶层调优常量、`CyclePhase` 枚举和 `CyclePrediction.empty`，它们都不带 `/// Purpose:` 块但都是真实、有意义公共声明（七个常量正是 [身体指标](../../../../algorithms/body-metrics.md#constants) 按名文档化的可调值；`CyclePhase` 被两个 UI 调用方切换；`CyclePrediction.empty` 是本文件和 `body_section.dart` 都返回的显式零数据哨兵）——为完整性包含，方式与 `widgets/cycle_calendar.md` 包含 `cyclePersonPalette` 相同。总计：16 行、7 个 Tier A、9 个 Tier B。全部 7 个文档化声明为 Tier A：两个构造函数是本文件两个结果类型的真实（虽简单）值对象构造函数，五个函数都携带预测算法核心的真实分支/日期算术逻辑。

## 文档

### `const CycleDayInfo({required CyclePhase phase, bool inFertileWindow = false, bool isOvulationDay = false, bool isActualStart = false, bool isPredictedStart = false, bool isEstimated = true})` <a id="cycledayinfo-new"></a>
- **种类：** `CycleDayInfo` 的 const 构造函数
- **来源：** `lib/features/intimacy/services/cycle_predictor.dart`（第 49 行）
- **用途：** 保存一个日历日的阶段分类加其生育窗口/排卵/实际开始/预测开始/估计标记标志。
- **输入：** `phase` 必填；除 `isEstimated` 默认 `true` 外每个标记标志默认 `false`。
- **返回：** 新的 `CycleDayInfo`。
- **副作用：** 无。
- **算法：** 平凡 `const` 字段赋值构造函数。
- **用法：** 在 [`predictCycle`](#predictcycle) 内每个分类天构造一次（第 232 行）：`days[day] = CycleDayInfo(phase: phase, inFertileWindow: inFertileWindow, isOvulationDay: isOvulationDay, isActualStart: isActual, isPredictedStart: isPredicted, isEstimated: !isActual);`。
- **备注：** `isEstimated` 默认 `true` 意味着除非调用方显式标为 `false`，否则每天都被当作派生——实践中只有实际记录的开始日才非估计（上面 `isEstimated: !isActual`）。

### `const CyclePrediction({required int cycleLengthDays, required List<DateTime> predictedStarts, required Map<DateTime, CycleDayInfo> days})` <a id="cycleprediction-new"></a>
- **种类：** `CyclePrediction` 的 const 构造函数
- **来源：** `lib/features/intimacy/services/cycle_predictor.dart`（第 75 行）
- **用途：** 保存一个人跨查询窗口的完整预测输出：使用的周期长度、窗口内的预测未来开始日期和每个分类天。
- **输入：** 三个字段都必填。
- **返回：** 新的 `CyclePrediction`。
- **副作用：** 无。
- **算法：** 平凡 `const` 字段赋值构造函数。
- **用法：** 在 [`predictCycle`](#predictcycle) 末尾（第 243 行）带完全计算的 `cycleLength`、过滤的 `predictedStarts` 和 `days` 映射构造一次。
- **备注：** 每个调用方对零记录开始情形实际使用的是单独的 `CyclePrediction.empty` 静态常量，不是此构造函数。

### `DateTime dateOnly(DateTime value)` <a id="dateonly"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/services/cycle_predictor.dart`（第 93 行）
- **用途：** 把 `DateTime` 规范化为纯日期本地值（年/月/日、午夜）。
- **输入：** `value`。
- **返回：** `DateTime` — 总是本地午夜，无时间分量。
- **副作用：** 无。
- **算法：** `DateTime(value.year, value.month, value.day)`。
- **用法：** 在 `predictCycle` 顶部应用于每个记录开始日期（第 156 行）：`final starts = actualStarts.map(dateOnly).toSet().toList()..sort();`。
- **备注：** 此库产生的每个 `DateTime` 键（`CyclePrediction.days` 和 `predictedStarts` 中）都以这种方式规范化，因此调用方可以安全地仅按日期比较/索引。

### `DateTime _addDays(DateTime day, int count)` <a id="_adddays"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/cycle_predictor.dart`（第 102 行）
- **用途：** 用纯日历算术向纯日期值加日历天。
- **输入：** `day` — 纯日期值；`count` — 要加的天数（可为负）。
- **返回：** `DateTime`。
- **副作用：** 无。
- **算法：** `DateTime(day.year, day.month, day.day + count)`——让 `DateTime` 构造函数自己把越界日规范化为正确的后/前月。
- **用法：** 贯穿 `predictCycle` 用于构建前向预测链（第 165 行：`var next = _addDays(anchor, cycleLength);`）和计算排卵估计（第 195 行：`_addDays(segNext, -ovulationOffsetDays)`）。
- **备注：** 用日历字段算术而不是 `Duration` 加法意味着夏令时转换绝不会把结果移离本地午夜。

### `int _daysBetween(DateTime from, DateTime to)` <a id="_daysbetween"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/cycle_predictor.dart`（第 111 行）
- **用途：** 统计两个纯日期值之间的整日历天。
- **输入：** `from`、`to`。
- **返回：** `int`（`to` 早于 `from` 时可为负）。
- **副作用：** 无。
- **算法：** 取 `.difference(...).inDays` 前把两个日期都转换为 UTC 午夜（`DateTime.utc(y, m, d)`），而不是直接对本地 `DateTime` 求差。
- **用法：** [`estimateCycleLength`](#estimatecyclelength)（第 127 行，连续开始之间的间隔长度）和 `predictCycle` 贯穿（段长度、距排卵天数）都使用。
- **备注：** 先经 UTC 规范化正是防止本地夏令时转换产生差一天天数计数的东西。

### `int estimateCycleLength(List<DateTime> sortedStarts)` <a id="estimatecyclelength"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/services/cycle_predictor.dart`（第 124 行）
- **用途：** 把前向周期长度估计为最近有效记录周期的中位数。
- **输入：** `sortedStarts` — 升序、纯日期、记录的周期开始日期。
- **返回：** `int` 天 — 无有效间隔存在时为 `defaultCycleLengthDays`（28）。
- **副作用：** 无。
- **算法：**
  1. 对 `sortedStarts` 每个相邻对，经 `_daysBetween` 计算间隔。
  2. 丢弃（不钳制）`[minValidCycleDays, maxValidCycleDays]`（15-90）外的任何间隔，当作数据错误或跟踪缺口。
  3. 没有有效间隔剩下时返回 `defaultCycleLengthDays`。
  4. 否则取最近最多 `medianCycleWindow`（6）个有效间隔，排序该子集，返回中位数（计数为偶数时两个中间值的平均）。
- **用法：** 每次预测调用一次，在 `predictCycle` 顶部（第 159 行）：`final cycleLength = estimateCycleLength(starts);`。
- **备注：** 中位数而非均值意味着单个离群周期（一个异常长或短的月份）不能像平均那样使预测偏移；见 [身体指标](../../../../algorithms/body-metrics.md#estimatecyclelength--median-of-the-last-6-valid-cycles)。

### `CyclePrediction predictCycle({required Iterable<DateTime> actualStarts, required DateTime windowStart, required DateTime windowEnd})` <a id="predictcycle"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/services/cycle_predictor.dart`（第 151 行）
- **用途：** 为一个人预测周期阶段、生育窗口、排卵和未来开始日期，分类查询窗口内的每天。
- **输入：** `actualStarts` — 任意顺序的记录开始日期，容忍重复；`windowStart`/`windowEnd` — 分类天数的闭区间查询范围。
- **返回：** `CyclePrediction` — `actualStarts` 为空时 `CyclePrediction.empty`。
- **副作用：** 无。
- **算法：** 完整走查见 [身体指标 — predictCycle](../../../../algorithms/body-metrics.md#predictcycle--anchoring-phases-and-fertile-window)。简言之：
  1. 去重/排序 `actualStarts`；为空时返回 `CyclePrediction.empty`。
  2. 经 [`estimateCycleLength`](#estimatecyclelength) 估计 `cycleLength`；锚定最新记录开始（`starts.last`）。
  3. 从锚点构建到 366 天视界的前向预测链。
  4. 把每个记录开始加每个预测开始当作段边界；长于 `maxValidCycleDays` 的缺口被截为只有其假定月经前缀，而不是分类为完整周期。
  5. 逐段：把前 `min(segmentLength, assumedMenstrualDays)` 天分类为月经；把排卵估计为 `segmentEnd - ovulationOffsetDays`（太靠近月经阶段则跳过）；把排卵周围 5 天前/1 天后的窗口分类为生育；把剩余天分为卵泡期（排卵前）和黄体期（排卵后）。
  6. 只为 `[windowStart, windowEnd]` 内的天发出 `CycleDayInfo` 条目。
- **用法：**
  ```dart
  CyclePrediction predictionFor(String? personId) => predictCycle(
    actualStarts: _cycleRecords
        .where((c) => c.personId == personId)
        .map((c) => c.day),
    windowStart: windowStart,
    windowEnd: windowEnd,
  );
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:313-319`，主页日历的逐人员叠加。）
- **备注：** 预测在每次调用时总是从头重新生成——添加或删除周期记录会重新派生一切，而不是增量平移旧预测。

## 相关页面

- [身体指标 — 周期预测](../../../../algorithms/body-metrics.md#cycle-prediction) — 本文件实现的完整算法走查，含实例演练。
- [亲密](../../../../features/intimacy.md#the-body-layer-v124) — 渲染这些预测的身体层 UI（`widgets/cycle_calendar.dart`、`widgets/body_section.dart`），以及强制的不避孕/非医疗免责声明。
- [数据格式](../../../../data-formats.md) — 本文件调用方读取的 `CycleRecord` 字段。

# lib/features/weight/services/weight_insight_facts.dart

体重页端侧 AI 洞察卡片背后的纯事实构建器。`buildWeightInsightFacts` 把 [体重页](../views/weight_page.md)已加载的 [`WeightRecord`](../models/weight_record.md) 和身高转成 [`InsightFacts`](../../ai/services/insight_prompts.md)：最新体重、身高、BMI 及其区间，7、30 和 90 天的变化，近期范围，称重次数，开始记录的日期，体脂及其 90 天变化，向前沿用的胸围/腰围/臀围及其 90 天变化，以及腰臀比。自 v1.5.3 起，卡片还会就这些身体事实请求一个 `body` 回答，建议也会参考它们。数字经 `factNumber` 处理，使指纹不随浮点噪声变化。绝不发送记录备注。卡片本身是 [`AiInsightCard`](../../ai/widgets/ai_insight_card.md)，事实由 [`AiInsightStore`](../../ai/services/insight_service.md) 计算指纹。见 [端侧 AI — 每张卡片得到什么](../../../../on-device-ai.md#what-each-card-is-given)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`_change`](#_change) | 顶层函数（私有） | A | 描述一个窗口内的体重变化。 |
| [`_signed`](#_signed) | 顶层函数（私有） | A | 为事实行格式化一个带符号的差值。 |
| [`_bmiBand`](#_bmiband) | 顶层函数（私有） | A | 给出体重页彩色条所显示的 BMI 区间名称。 |
| [`_fieldChange`](#_fieldchange) | 顶层函数（私有） | A | 描述一个可选字段在窗口内的变化。 |
| [`buildWeightInsightFacts`](#buildweightinsightfacts) | 顶层函数 | A | 构建体重卡片的事实。 |
| [`buildWeightFallbackInsightFacts`](#buildweightfallbackinsightfacts) | 顶层函数 | A | 构建体重卡片的后备事实：v1.5.2 的提示词。 |
| [`_weightFacts`](#_weightfacts) | 顶层函数（私有） | A | 构建两种版本之一的体重卡片事实。 |

`grep -c 'Purpose:' lib/features/weight/services/weight_insight_facts.dart` 报告 7，与上面七个声明精确匹配；不存在未文档化声明。

## 文档

### `String? _change(List<WeightRecord> sorted, DateTime now, int days)` <a id="_change"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/weight/services/weight_insight_facts.dart`（第 9 行）
- **用途：** 描述一个窗口内的体重变化。
- **输入：** `sorted` — 从旧到新的记录；`now`；`days` — 窗口长度。
- **返回：** `String?`，如 `+1.2 kg over 30 days (5 weigh-ins)`；落在窗口内的记录少于两条时为 null。
- **副作用：** 无。
- **算法：** 保留 `now - days ≤ datetime ≤ now` 的记录；至少两条时，变化为最后一条减第一条，用 `_signed` 格式化。
- **用法：** `buildWeightInsightFacts` 为 7、30 和 90 天调用它。
- **备注：** 窗口从 `now` 精确计算，而非从本地午夜。

### `String _signed(double delta, [int digits = 1])` <a id="_signed"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/weight/services/weight_insight_facts.dart`（第 25 行）
- **用途：** 为事实行格式化一个带符号的差值。
- **输入：** `delta`；`digits` — 小数位数，默认 1。
- **返回：** `String` — `+1.2`、`-0.5` 或 `0`。
- **副作用：** 无。
- **算法：** `factNumber(delta, digits)`；当 `delta` 为正且舍入后的文本不是 `0` 时加前缀 `+`。
- **用法：** `_change` 以及体脂和围度变化行。
- **备注：** 舍入为零的变化写作 `0`，绝不写作 `+0`。

### `String _bmiBand(double bmi)` <a id="_bmiband"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/weight/services/weight_insight_facts.dart`（第 37 行）
- **用途：** 给出体重页彩色条所显示的 BMI 区间名称。
- **输入：** `bmi`。
- **返回：** `String` — 低于 18.5 为 `underweight range`，低于 25 为 `normal range`，低于 30 为 `overweight range`，否则为 `obese range`。
- **副作用：** 无。
- **算法：** 三次比较。
- **用法：** `- BMI:` 行，如 `- BMI: 23.7 (normal range)`。
- **备注：** 分界点与 [`weight_page.md`](../views/weight_page.md) 中的 `_buildBMIBar` 一致，因此卡片和彩色条保持一致。这是区间，不是诊断。

### `({double first, double last, DateTime firstAt})? _fieldChange(List<WeightRecord> sorted, DateTime from, DateTime now, double? Function(WeightRecord r) value)` <a id="_fieldchange"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/weight/services/weight_insight_facts.dart`（第 52 行）
- **用途：** 描述一个可选字段在窗口内的变化。
- **输入：** `sorted` — 从旧到新的记录；`from`、`now` — 窗口；`value` — 字段读取器（体脂、胸围、腰围或臀围）。
- **返回：** 窗口内第一个和最后一个正值以及第一个值的日期；窗口内测量过该字段的记录少于两条时为 null。
- **副作用：** 无。
- **算法：** 过滤出 `from ≤ datetime ≤ now` 且值为正的记录；取第一条和最后一条。
- **用法：** `- Body fat change over 90 days:` 和 `- Measurement change over 90 days:` 行。
- **备注：** 只计入测量过该字段的记录。这里刻意不使用向前沿用的值，因此只测过一次的字段不显示变化。

### `InsightFacts? buildWeightInsightFacts({required DateTime now, required double? heightCm, required List<WeightRecord> records})` <a id="buildweightinsightfacts"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/weight/services/weight_insight_facts.dart`（第 83 行）
- **用途：** 构建体重卡片的事实。
- **输入：** `now` — 本地时间；`heightCm` — 用户身高，或 null；`records`。
- **返回：** `InsightFacts?`，`module: weight`、分桶 `none`，槽位为 `trend`、`body`（仅当发送了 BMI、体脂或围度行时）和 `advice`——没有日期在 `now` 或之前的记录时为 null。
- **副作用：** 无。
- **算法：** `_weightFacts(now, heightCm, records, detailed: true)`，其步骤为：
  1. 丢弃 `now` 之后的记录；从旧到新排序；最新的是最后一条。
  2. `- Today:`；最新体重、其日期以及距今多少个日历日。
  3. 当 `heightCm > 0` 时：身高，以及在有定义时来自 `WeightData.calculateBMI` 的 BMI 及其 `_bmiBand`。
  4. 对 7、30 和 90 天中 `_change` 能描述的每一个，各一条 `- Change:` 行。
  5. 最近七条记录的最小–最大范围（至少两条时）、最近 30 天的称重次数，以及 `- Tracking since:` 第一条记录的日期和总条数。
  6. 最近一次为正的体脂及其日期，以及来自 `_fieldChange` 的 90 天变化。
  7. 来自 `WeightData.effectiveMeasurementsUpTo` 的胸围、腰围和臀围（每个字段各自向前沿用，与页面显示一致）、保留两位小数的腰臀比，以及来自 `_fieldChange` 的各字段 90 天变化。
  8. 槽位：`trend`（"Describe the weight trend."）；当第 3、6 或 7 步发送了值时加入 `body`（"Sum up the body condition neutrally: BMI, body fat and measurements, and how they have moved."）；以及 `advice`（"One gentle, practical suggestion based on the trend and the body facts."）。
- **用法：**
  ```dart
  final facts = buildWeightInsightFacts(
    now: now,
    heightCm: _height,
    records: _records,
  );
  ```
  （`lib/features/weight/views/weight_page.dart`，第 485 行，其卡片把 `trend`/`advice` 归入 `aiWeightTrend`，把 `body` 归入 `aiWeightBody`；由 `test/insight_facts_test.dart` 覆盖。）
- **备注：** 绝不读取记录备注。忽略日期在未来的记录。`body` 槽位于 v1.5.3 新增；此前模型只被问及趋势，因而忽略身体事实。页面把 [`buildWeightFallbackInsightFacts`](#buildweightfallbackinsightfacts) 作为 `fallbackFacts` 与它一起发送（v1.5.4）。

### `InsightFacts? buildWeightFallbackInsightFacts({required DateTime now, required double? heightCm, required List<WeightRecord> records})` <a id="buildweightfallbackinsightfacts"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/weight/services/weight_insight_facts.dart`（第 97 行）
- **用途：** 构建体重卡片的后备事实：v1.5.2 的提示词。
- **输入：** 与 [`buildWeightInsightFacts`](#buildweightinsightfacts) 相同。
- **返回：** `InsightFacts?`，槽位为 `trend` 和 `advice`，后者请求 "One gentle, practical suggestion based on the trend."；没有日期在 `now` 或之前的记录时为 null。
- **副作用：** 无。
- **算法：** `_weightFacts(now, heightCm, records, detailed: false)`：相同的步骤，但没有 BMI 区间、开始记录日期、90 天体脂和围度变化，也没有 `body` 槽位。
- **用法：**
  ```dart
  final plain = buildWeightFallbackInsightFacts(
    now: now,
    heightCm: _height,
    records: _records,
  );
  ```
  （`lib/features/weight/views/weight_page.dart`，作为 `AiInsightRequest.fallbackFacts` 传入。）
- **备注：** v1.5.4 新增。当模型拒绝详细事实或没有给出可用回答时，[`AiInsightStore`](../../ai/services/insight_service.md) 在同一次运行中发送一次这些事实；只有它们也被拒绝时才缓存为*已拒绝*。其输出与 v1.5.2 发送的内容逐字节相同。

### `InsightFacts? _weightFacts(DateTime now, double? heightCm, List<WeightRecord> records, {required bool detailed})` <a id="_weightfacts"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/weight/services/weight_insight_facts.dart`（第 110 行）
- **用途：** 构建两种版本之一的体重卡片事实。
- **输入：** `now`；`heightCm`；`records`；`detailed` — true 为 v1.5.3 的事实，false 为 v1.5.2 的事实。
- **返回：** `InsightFacts?` — 没有记录时为 null。
- **副作用：** 无。
- **算法：** [`buildWeightInsightFacts`](#buildweightinsightfacts) 下列出的步骤；区间、开始记录日期、90 天变化和 `body` 槽位只在 `detailed` 时出现，建议问题的措辞随版本而定。
- **用法：** 上面两个公开构建器。
- **备注：** 共用一个函数体，使两个提示词共有的行不会彼此偏离。

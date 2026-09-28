# lib/features/weight/services/weight_insight_facts.dart

体重页端侧 AI 洞察卡片背后的纯事实构建器。`buildWeightInsightFacts` 把 [体重页](../views/weight_page.md)已加载的 [`WeightRecord`](../models/weight_record.md) 和身高转成 [`InsightFacts`](../../ai/services/insight_prompts.md)：最新体重、身高和 BMI，7、30 和 90 天的变化，近期范围，称重次数，体脂，向前沿用的胸围/腰围/臀围，以及腰臀比。数字经 `factNumber` 处理，使指纹不随浮点噪声变化。绝不发送记录备注。卡片本身是 [`AiInsightCard`](../../ai/widgets/ai_insight_card.md)，事实由 [`AiInsightStore`](../../ai/services/insight_service.md) 计算指纹。见 [端侧 AI — 每张卡片得到什么](../../../../on-device-ai.md#what-each-card-is-given)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`_change`](#_change) | 顶层函数（私有） | A | 描述一个窗口内的体重变化。 |
| [`buildWeightInsightFacts`](#buildweightinsightfacts) | 顶层函数 | A | 构建体重卡片的事实。 |

`grep -c 'Purpose:' lib/features/weight/services/weight_insight_facts.dart` 报告 2，与上面两个声明精确匹配；不存在未文档化声明。

## 文档

### `String? _change(List<WeightRecord> sorted, DateTime now, int days)` <a id="_change"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/weight/services/weight_insight_facts.dart`（第 9 行）
- **用途：** 描述一个窗口内的体重变化。
- **输入：** `sorted` — 从旧到新的记录；`now`；`days` — 窗口长度。
- **返回：** `String?`，如 `+1.2 kg over 30 days (5 weigh-ins)`；落在窗口内的记录少于两条时为 null。
- **副作用：** 无。
- **算法：** 保留 `now - days ≤ datetime ≤ now` 的记录；至少两条时，变化为最后一条减第一条，为正时加 `+` 号，并用 `factNumber` 格式化。
- **用法：** `buildWeightInsightFacts` 为 7、30 和 90 天调用它（第 49 行）。
- **备注：** 窗口从 `now` 精确计算，而非从本地午夜。

### `InsightFacts? buildWeightInsightFacts({required DateTime now, required double? heightCm, required List<WeightRecord> records})` <a id="buildweightinsightfacts"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/weight/services/weight_insight_facts.dart`（第 27 行）
- **用途：** 构建体重卡片的事实。
- **输入：** `now` — 本地时间；`heightCm` — 用户身高，或 null；`records`。
- **返回：** `InsightFacts?`，含 `module: weight`、时段 `none` 和槽位 `trend`、`advice`——没有日期不晚于 `now` 的记录时为 null。
- **副作用：** 无。
- **算法：**
  1. 丢弃晚于 `now` 的记录；从旧到新排序；最新的是最后一条。
  2. `- Today:`；最新体重、其日期以及距今多少个日历日。
  3. `heightCm > 0` 时：身高，以及 `WeightData.calculateBMI` 有定义时的 BMI。
  4. `_change` 能描述的 7、30、90 天各一条 `- Change:` 行。
  5. 最近七条记录的最小–最大范围（至少两条时），以及最近 30 天的称重次数。
  6. 最近一次为正的体脂及其日期。
  7. 来自 `WeightData.effectiveMeasurementsUpTo` 的胸围、腰围和臀围（每个字段各自向前沿用，与页面显示一致），以及保留两位小数的腰臀比。
- **用法：**
  ```dart
  final facts = buildWeightInsightFacts(
    now: now,
    heightCm: _height,
    records: _records,
  );
  ```
  （`lib/features/weight/views/weight_page.dart`，第 470 行；由 `test/insight_facts_test.dart` 覆盖。）
- **备注：** 绝不读取记录备注。忽略未来日期的记录。

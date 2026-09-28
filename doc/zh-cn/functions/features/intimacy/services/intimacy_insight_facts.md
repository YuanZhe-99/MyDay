# lib/features/intimacy/services/intimacy_insight_facts.dart

亲密页端侧 AI 洞察卡片背后的纯事实构建器。`buildIntimacyInsightFacts` 把 [亲密页](../views/intimacy_page.md)已加载的[记录](../models/intimacy_record.md)、用户身体档案、周期记录和体重模块的[记录](../../weight/models/weight_record.md)转成 [`InsightFacts`](../../ai/services/insight_prompts.md)：最近 30 天和之前 30 天的统计、90 天次数、距上次记录的天数、带估算罩杯尺码的用户身体尺寸（[`body_metrics.dart`](body_metrics.md)），以及——仅当用户记录自己的周期时——来自 [`cycle_predictor.dart`](cycle_predictor.md) 的估算周期阶段。只发送统计数据；备注、地点、伴侣、玩具和体位名称、抽插次数、色情标志、生殖器尺寸以及伴侣的周期绝不发送，这既为隐私，也为留在端侧模型的可接受使用规则之内。卡片本身是 [`AiInsightCard`](../../ai/widgets/ai_insight_card.md)，事实由 [`AiInsightStore`](../../ai/services/insight_service.md) 计算指纹。见 [端侧 AI — 每张卡片得到什么](../../../../on-device-ai.md#what-each-card-is-given)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`_window`](#_window) | 顶层函数（私有） | A | 汇总一个窗口内的记录。 |
| [`buildIntimacyInsightFacts`](#buildintimacyinsightfacts) | 顶层函数 | A | 构建亲密卡片的事实，包括身体状况。 |

`grep -c 'Purpose:' lib/features/intimacy/services/intimacy_insight_facts.dart` 报告 2，与上面两个声明精确匹配；不存在未文档化声明。

## 文档

### `String _window(List<IntimacyRecord> records, DateTime from, DateTime to)` <a id="_window"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/intimacy_insight_facts.dart`（第 13 行）
- **用途：** 汇总一个窗口内的记录。
- **输入：** `records`；`from`（含）；`to`（不含）。
- **返回：** `String` — `0 entries`，或分为有伴侣和独自的条目数、平均 `pleasureLevel`（"of 5"）、以分钟计的平均计时时长、高潮率，以及有伴侣条目中的防护率。
- **副作用：** 无。
- **算法：** 过滤到 `from ≤ datetime < to`；在窗口上计算每项统计。平均时长只用 `duration` 为正的条目，没有时省略；没有有伴侣条目时省略防护率（`usedCondom`）。比率四舍五入为整数百分比。
- **用法：** `buildIntimacyInsightFacts` 为最近 30 天和之前 30 天调用它（第 69–70 行）。
- **备注：** 时长为零（未计时）的条目不计入平均值，而不是按零计。

### `InsightFacts? buildIntimacyInsightFacts({required DateTime now, required List<IntimacyRecord> records, required BodyProfile? userBody, required List<CycleRecord> cycleRecords, required List<WeightRecord> weightRecords})` <a id="buildintimacyinsightfacts"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/services/intimacy_insight_facts.dart`（第 52 行）
- **用途：** 构建亲密卡片的事实，包括身体状况。
- **输入：** `now` — 本地时间；`records`；`userBody` — 用户身体档案，或 null；`cycleRecords`；`weightRecords` — 用于用户自己的胸围/腰围/臀围。
- **返回：** `InsightFacts?`，含 `module: intimacy` 和时段 `none`——没有过去的记录、没有身体事实也没有周期事实时为 null。槽位：有过去记录时为 `trend` 和 `advice`；有身体或周期事实时为 `body`，发送了周期事实时还要求提及周期阶段并说明「是估算」。
- **副作用：** 无。
- **算法：**
  1. 保留不晚于 `now` 的记录，从旧到新排序。`- Today:` 为本地日期。
  2. 有过去记录时：对截至今天的 30 天（今天 − 29 到今天）和之前 30 天调用 `_window`；最近 90 天的次数；距上次记录的天数。
  3. 身体：来自 `WeightData.effectiveMeasurementsUpTo(weightRecords, now)` 的胸围/腰围/臀围；档案中为正的下胸围，且有胸围时按档案罩杯标准得到的 `estimateBraSize` 结果；保留两位小数的腰臀比。
  4. 周期，仅当 `userBody.cycleEnabled` 时：用户自己的开始日（`personId == null`）；存在时，`predictCycle` 在昨天到 60 天后的范围内给出典型周期长度、最近记录的开始日、今天的估算阶段和易孕期，以及距下次估算开始的天数。
- **用法：**
  ```dart
  final facts = buildIntimacyInsightFacts(
    now: now,
    records: _records,
    userBody: _userBody,
    cycleRecords: _cycleRecords,
    weightRecords: _weightRecordsForInsight,
  );
  ```
  （`lib/features/intimacy/views/intimacy_page.dart`，第 677 行，仅在模块可见时；由 `test/insight_facts_test.dart` 覆盖。）
- **备注：** 绝不读取伴侣的周期记录。用户记录周期时页面显示 `aiEstimateDisclaimer` 脚注。`guardrail` 拒绝会被存储缓存为 *skipped*，因此被拒绝的事实集在变化前不会重试。

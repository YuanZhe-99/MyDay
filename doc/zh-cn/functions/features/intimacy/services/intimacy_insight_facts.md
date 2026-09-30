# lib/features/intimacy/services/intimacy_insight_facts.dart

亲密页端侧 AI 洞察卡片背后的纯事实构建器。`buildIntimacyInsightFacts` 把 [亲密页](../views/intimacy_page.md)已加载的[记录、伴侣、玩具和姿势](../models/intimacy_record.md)、趋势图持久化的 `IntimacyChartSettings`、用户身体档案、周期记录和体重模块的[记录](../../weight/models/weight_record.md)转成 [`InsightFacts`](../../ai/services/insight_prompts.md)：最近 30 天和之前 30 天的统计、90 天次数、距上次记录的天数、按用户当前设置的趋势图摘要、匿名的伴侣、玩具和姿势统计、带估算罩杯尺码的用户身体尺寸（[`body_metrics.dart`](body_metrics.md)），以及——仅当用户记录自己的周期时——来自 [`cycle_predictor.dart`](cycle_predictor.md) 的估算周期阶段。

只发送统计数据。伴侣、玩具和姿势只以 `partner A`、`toy 1`、`position 1` 的形式出现，按使用次数排序。备注、地点、名称、表情符号、图片、价格、链接、生殖器尺寸以及伴侣的周期绝不发送，这既为隐私，也为留在端侧模型的可接受使用规则之内。自 v1.5.3 起发送抽插次数与抽插速率以及观看色情内容的比例。图表摘要读取 [`intimacy_trend_chart.dart`](../widgets/intimacy_trend_chart.md) 中公开的 `IntimacyChartMetric` 和 `IntimacyChartRange` 枚举，并回退到相同的默认值，因此它描述的总是屏幕上的那张图。卡片本身是 [`AiInsightCard`](../../ai/widgets/ai_insight_card.md)，事实由 [`AiInsightStore`](../../ai/services/insight_service.md) 计算指纹。见 [端侧 AI — 每张卡片得到什么](../../../../on-device-ai.md#what-each-card-is-given)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `_pct` | 顶层函数（私有） | B | 把部分占总数的比例格式化为整数百分比。 |
| `_avg` | 顶层函数（私有） | B | 求读取器返回的非 null 值的平均；没有值时为 null。 |
| `_minutes` | 顶层函数（私有） | B | 记录的计时时长（分钟）；未计时为 null。 |
| `_rating` | 顶层函数（私有） | B | 用于图表愉悦度指标的记录评分；不为正时为 null。 |
| [`_window`](#_window) | 顶层函数（私有） | A | 汇总一个窗口内的记录。 |
| [`_chartMetric`](#_chartmetric) | 顶层函数（私有） | A | 描述趋势图的一个指标在可见区间内的情况。 |
| `perWeek` | 局部函数（在 `_chartMetric` 中） | B | 一个区间内每周的记录数；不足一天的区间按一天计。 |
| `fmt` | 局部函数（在 `_chartMetric` 中） | B | 用指标单位格式化一个平均值，或 `no data`。 |
| [`_chartSummary`](#_chartsummary) | 顶层函数（私有） | A | 按用户当前设置汇总趋势图。 |
| [`_ranked`](#_ranked) | 顶层函数（私有） | A | 按出现次数给 id 排序，最多的在前。 |
| [`_usage`](#_usage) | 顶层函数（私有） | A | 描述带标签条目的使用频率。 |
| `_maxListed` | 私有顶层常量（`int`） | B | `5`：一条事实行最多列出的伴侣、玩具或姿势数。 |
| [`_companions`](#_companions) | 顶层函数（私有） | A | 用匿名标签描述伴侣、玩具和姿势。 |
| [`buildIntimacyInsightFacts`](#buildintimacyinsightfacts) | 顶层函数 | A | 构建亲密卡片的事实。 |
| [`buildIntimacyFallbackInsightFacts`](#buildintimacyfallbackinsightfacts) | 顶层函数 | A | 构建亲密卡片的后备事实：v1.5.2 的提示词。 |
| [`_intimacyFacts`](#_intimacyfacts) | 顶层函数（私有） | A | 构建两种版本之一的亲密卡片事实。 |

**对账：** `grep -c 'Purpose:' lib/features/intimacy/services/intimacy_insight_facts.dart` 报告 15，对应 16 行。多出的一行是 `_maxListed`，一个只带普通文档注释、没有 `Purpose:` 块的常量。两个局部函数 `perWeek` 和 `fmt` 各自带有 `Purpose:` 块，并各占一行。

## 文档

### `String _window(List<IntimacyRecord> records, DateTime from, DateTime to, {required bool detailed})` <a id="_window"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/intimacy_insight_facts.dart`（第 61 行）
- **用途：** 汇总一个窗口内的记录。
- **输入：** `records`；`from`（含）；`to`（不含）；`detailed` — false 为 v1.5.2 的措辞。
- **返回：** `String` — `0 entries`，或分为有伴侣与独自的记录数、平均 `pleasureLevel`（"of 5"）、平均计时时长（分钟）、高潮率，`detailed` 时再加上观看色情内容的比例和有记录时的平均抽插次数与抽插速率，最后是有伴侣记录中的保护措施使用率。
- **副作用：** 无。
- **算法：** 过滤出 `from ≤ datetime < to`；在窗口上计算各项统计。平均时长只用 `duration` 为正的记录；抽插平均值使用非 null 的 `resolvedThrustCount` 和 `thrustsPerMinute`；没有任何记录具备某项时省略该项。没有有伴侣记录时省略保护措施使用率（`usedCondom`）。比率四舍五入为整数百分比。
- **用法：** `_intimacyFacts` 为最近 30 天和之前 30 天调用它。
- **备注：** 零时长（未计时）被排除在平均之外，而非按零计入。抽插数据和观看色情内容的比例于 v1.5.3 新增。

### `String _chartMetric(IntimacyChartMetric metric, List<IntimacyRecord> visible, DateTime start, DateTime mid, DateTime end)` <a id="_chartmetric"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/intimacy_insight_facts.dart`（第 108 行）
- **用途：** 描述趋势图的一个指标在可见区间内的情况。
- **输入：** `metric`；`visible` — 区间内从旧到新的记录；`start`、`mid`、`end` — 区间及其二等分点。
- **返回：** `String`，如 `rating average 3 of 5 (first half 2 of 5, second half 4 of 5)`、`frequency 1.5/week (first half 1, second half 2)` 或 `thrust rate no data`。
- **副作用：** 无。
- **算法：** 在 `mid` 处切分 `visible`。频率为整个区间及每一半的记录数 ÷ 周数（`perWeek`）。其他指标对图表自身的逐条记录值——评分（为正的 `pleasureLevel`）、时长分钟数（为正的 `duration`）、`resolvedThrustCount`、`thrustsPerMinute`——在整个区间和每一半上求平均；没有值的一半为 `no data`。
- **用法：** `_chartSummary`，每个选中指标一次。
- **备注：** 用的是平均值而非图表的 EWMA 曲线：模型需要可比较的数字，前后两半能体现曲线走向。

### `String? _chartSummary(List<IntimacyRecord> sorted, IntimacyChartSettings settings, DateTime now)` <a id="_chartsummary"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/intimacy_insight_facts.dart`（第 177 行）
- **用途：** 按用户当前设置汇总趋势图。
- **输入：** `sorted` — 过去的记录，从旧到新；`settings` — 持久化的图表选择；`now`。
- **返回：** `String?` — `- Chart being viewed (<range>, <n> entries): <metric>; <metric>…`；范围内的记录少于两条时为 null。
- **副作用：** 无。
- **算法：**
  1. 用 `IntimacyChartRange.fromId` 解析范围，回退到 `IntimacyChartSettings.defaultRange`；按枚举的规范顺序解析指标，一个都不认识时回退到 `defaultMetrics`。
  2. 保留在 `range.cutoffFrom(now)` 或之后的记录；少于两条时返回 null。
  3. 区间从截止点开始，`all` 时从第一条记录开始；`mid` 为到 `now` 的中点。
  4. 给范围加标签（`last week` … `last year`、`all time since <date>`），每个选中指标一个 `_chartMetric`，以 `; ` 连接。
- **用法：** `buildIntimacyInsightFacts`，有过去记录时。
- **备注：** 回退规则与组件的 `_range` 和 `_selectedMetrics` getter 一致，null 与图表的空状态一致，因此卡片绝不会描述用户看不到的图表。

### `List<String> _ranked(Map<String, int> counts, Map<String, DateTime> firstSeen)` <a id="_ranked"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/intimacy_insight_facts.dart`（第 225 行）
- **用途：** 按出现次数给 id 排序，最多的在前。
- **输入：** `counts` — id 到次数；`firstSeen` — id 到最早一次使用。
- **返回：** `List<String>` — 按次数降序，再按最早使用，再按 id 排序。
- **副作用：** 无。
- **用法：** `_companions` 用于伴侣，`_usage` 用于玩具和姿势。
- **备注：** 排名决定匿名标签，因此对相同数据必须是确定的。

### `String? _usage(List<IntimacyRecord> recent, String noun, List<String> Function(IntimacyRecord r) ids, Set<String> validIds)` <a id="_usage"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/intimacy_insight_facts.dart`（第 241 行）
- **用途：** 描述带标签条目的使用频率。
- **输入：** `recent` — 从旧到新的记录；`noun` — `toy` 或 `position`；`ids` — 读取记录条目 id 的函数；`validIds` — 仍存在的 id。
- **返回：** `String?` — `used in 50% of entries in the last 90 days: toy 1 6 times, toy 2 2 times`；没有使用任何有效条目时为 null。
- **副作用：** 无。
- **算法：** 逐条记录统计它使用的不同有效 id，以及使用了任意条目的记录数；用 `_ranked` 排序；前 `_maxListed` 个标为 `<noun> 1`、`<noun> 2`……
- **用法：** `_companions`。
- **备注：** 忽略已删除条目的 id。

### `List<String> _companions(List<IntimacyRecord> recent, DateTime today, DateTime now, List<Partner> partners, List<Toy> toys, List<Position> positions)` <a id="_companions"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/intimacy_insight_facts.dart`（第 281 行）
- **用途：** 用匿名标签描述伴侣、玩具和姿势。
- **输入：** `recent` — 最近 90 天的过去记录，从旧到新；`today`；`now`；`partners`；`toys`；`positions`。
- **返回：** `List<String>` — 零到四条事实行。
- **副作用：** 无。
- **算法：**
  1. 有伴侣时：`- Partners: <n> on record, <m> active`（没有 `endDate`，或其晚于 `now`）。
  2. 按伴侣分组有伴侣的记录，未设置或未知的 `partnerId` 归入 `unspecified partner`；用 `_ranked` 排序；对前 `_maxListed` 个写出 `partner A <n> entries, average rating <r>, climax <c>%, protection <p>%, last <d> days ago`。
  3. 有玩具时：`- Toys: <n> on record, <m> in use; ` 加上玩具的 `_usage`，或 `none used in the last 90 days`。
  4. 有姿势被使用时：`- Positions: ` 加上姿势的 `_usage`。
- **用法：** `buildIntimacyInsightFacts`，有过去记录时。
- **备注：** 绝不读取名称、表情符号、图片、价格和链接。字母跟随排名，因此同一个伴侣某天是 `partner A`，另一天可能是 `partner B`。

### `InsightFacts? buildIntimacyInsightFacts({required DateTime now, required List<IntimacyRecord> records, required BodyProfile? userBody, required List<CycleRecord> cycleRecords, required List<WeightRecord> weightRecords, required List<Partner> partners, required List<Toy> toys, required List<Position> positions, required IntimacyChartSettings chartSettings})` <a id="buildintimacyinsightfacts"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/services/intimacy_insight_facts.dart`（第 362 行）
- **用途：** 构建亲密卡片的事实：趋势、正在查看的图表、伴侣、玩具和姿势，以及身体状况。
- **输入：** `now` — 本地时间；`records`；`userBody` — 用户身体档案，或 null；`cycleRecords`；`weightRecords` — 用于用户自己的胸围/腰围/臀围；`partners`、`toys`、`positions` — 用于匿名统计；`chartSettings` — 趋势图的选择。
- **返回：** `InsightFacts?`，`module: intimacy`、分桶 `none`——没有过去记录、没有身体事实也没有周期事实时为 null。槽位按顺序排列，各自仅在有对应事实时出现：`trend` 和 `advice`（有过去记录），其间的 `chart`（有图表行），`partners`（有任何伴侣、玩具或姿势行），以及 `body`（有身体或周期事实；发送了周期事实时，还要求提及周期阶段并附"这是估算"的说明）。
- **副作用：** 无。
- **算法：**
  `_intimacyFacts(..., detailed: true)`，其步骤为：
  1. 保留在 `now` 或之前的记录，从旧到新排序。`- Today:` 为本地日期。
  2. 有过去记录时：以今天结束的 30 天（今天 − 29 到今天）和之前 30 天各一个 `_window`；最近 90 天的次数；距上次记录的天数；`_chartSummary` 行；最近 90 天的 `_companions` 行。
  3. 身体：来自 `WeightData.effectiveMeasurementsUpTo(weightRecords, now)` 的胸围/腰围/臀围；档案中为正的下胸围，有胸围时再加上按档案罩杯标准计算的 `estimateBraSize` 结果；保留两位小数的腰臀比。
  4. 周期，仅当 `userBody.cycleEnabled`：用户自己的开始日（`personId == null`）；有任何开始日时，`predictCycle` 覆盖昨天到 60 天后，给出典型周期长度、最近记录的开始日、今天的估算阶段和易孕窗口，以及距下一次估算开始的天数。
- **用法：**
  ```dart
  final facts = buildIntimacyInsightFacts(
    now: now,
    records: _records,
    userBody: _userBody,
    cycleRecords: _cycleRecords,
    weightRecords: _weightRecordsForInsight,
    partners: _partners,
    toys: _toys,
    positions: _positions,
    chartSettings: _chartSettings,
  );
  ```
  （`lib/features/intimacy/views/intimacy_page.dart`，第 781 行，仅在模块可见时；由 `test/insight_facts_test.dart` 覆盖。）
- **备注：** 绝不读取伴侣的周期记录。`quotedTerms` 保持为空，因为不发送任何用户输入的文字。由于 `chartSettings` 属于事实，切换图表的筛选片会改变指纹并重新生成卡片。用户记录周期时，页面显示 `aiEstimateDisclaimer` 脚注。存储把 `guardrail` 拒绝缓存为*已跳过*，因此被拒绝的一组事实在变化前不会重试。图表、伴侣、玩具、姿势、抽插和色情相关事实于 v1.5.3 新增。自 v1.5.4 起，页面还把 [`buildIntimacyFallbackInsightFacts`](#buildintimacyfallbackinsightfacts) 作为 `fallbackFacts` 发送，因此这些事实被拒绝时会先用 v1.5.2 的提示词重试，只有第二次被拒绝才缓存为*已拒绝*。

### `InsightFacts? buildIntimacyFallbackInsightFacts({required DateTime now, required List<IntimacyRecord> records, required BodyProfile? userBody, required List<CycleRecord> cycleRecords, required List<WeightRecord> weightRecords})` <a id="buildintimacyfallbackinsightfacts"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/services/intimacy_insight_facts.dart`（第 397 行）
- **用途：** 构建亲密卡片的后备事实：v1.5.2 的提示词。
- **输入：** `now` — 本地时间；`records`；`userBody`；`cycleRecords`；`weightRecords`。
- **返回：** `InsightFacts?` — 没有记录也没有身体事实时为 null。槽位为 `trend`、`advice` 和 `body`，各自仅在有对应事实时出现。
- **副作用：** 无。
- **算法：** `_intimacyFacts(..., detailed: false)`，传入空的伴侣、玩具和姿势列表以及默认图表设置（均被忽略）：相同的步骤，但没有图表行、伴侣、玩具和姿势行、抽插数据和观看色情内容的比例。
- **用法：**
  ```dart
  final plain = buildIntimacyFallbackInsightFacts(
    now: now,
    records: _records,
    userBody: _userBody,
    cycleRecords: _cycleRecords,
    weightRecords: _weightRecordsForInsight,
  );
  ```
  （`lib/features/intimacy/views/intimacy_page.dart`，作为 `AiInsightRequest.fallbackFacts` 传入。）
- **备注：** v1.5.4 新增。当模型拒绝详细事实或没有给出可用回答时，[`AiInsightStore`](../../ai/services/insight_service.md) 在同一次运行中发送一次这些事实；只有它们也被拒绝时才缓存为*已拒绝*。其输出与 v1.5.2 发送的内容逐字节相同。其槽位 id 是详细事实槽位 id 的子集且顺序相同，因此卡片的各小节仍然适用。

### `InsightFacts? _intimacyFacts({required DateTime now, required List<IntimacyRecord> records, required BodyProfile? userBody, required List<CycleRecord> cycleRecords, required List<WeightRecord> weightRecords, required List<Partner> partners, required List<Toy> toys, required List<Position> positions, required IntimacyChartSettings chartSettings, required bool detailed})` <a id="_intimacyfacts"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/intimacy_insight_facts.dart`（第 423 行）
- **用途：** 构建两种版本之一的亲密卡片事实。
- **输入：** 与 [`buildIntimacyInsightFacts`](#buildintimacyinsightfacts) 相同，另加 `detailed` — true 为 v1.5.3 的事实，false 为 v1.5.2 的事实。
- **返回：** `InsightFacts?`。
- **副作用：** 无。
- **算法：** [`buildIntimacyInsightFacts`](#buildintimacyinsightfacts) 下列出的步骤；`detailed` 为 false 时，`_window` 去掉 v1.5.3 新增的部分，并跳过图表行和伴侣行，因此不会请求它们的槽位。
- **用法：** 上面两个公开构建器。
- **备注：** `detailed` 为 false 时忽略 `partners`、`toys`、`positions` 和 `chartSettings`。

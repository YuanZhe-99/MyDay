# lib/features/intimacy/widgets/intimacy_trend_chart.dart

亲密模块唯一的记录指标趋势图，v1.3.2 引入。它用两个表面都嵌入的一个组件取代了四个独立 `fl_chart` 折线图——亲密主页的愉悦度+频率和时长+抽插次数，外加伴侣/玩具详情页旧 `_FilteredRecordsTrendSection` 内两者的近乎逐字副本。五个指标可选，含派生的抽插速率；选择和时间范围被持久化和同步。功能描述见 [整合趋势图](../../../../features/intimacy.md#the-consolidated-trend-chart-v132)，持久化 `chartSettings` 形态见 [数据格式](../../../../data-formats.md#intimacy--intimacy_datajson)。

组件刻意是 `StatelessWidget`：选择住在调用方，使一个持久化 `IntimacyChartSettings` 值能驱动图表出现的每个地方。写入经 `onSettingsChanged` 上报，落入 [`_saveChartSettings`](../views/intimacy_page.md#savechartsettings)。

玩具每日成本趋势图**不**属于此组件，留在 [`intimacy_page.dart`](../views/intimacy_page.md)——它在对数刻度上把金额绘制在投影日期时间线上，带自己的全部/激活/退役范围选择器。不过该页确实复用这里声明的公共 `IntimacyChartRange` 枚举。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `IntimacyChartMetric.new` | 构造函数（`IntimacyChartMetric`） | B | 把指标枚举值绑定到其持久化字符串 id。 |
| [`IntimacyChartMetric.fromId`](#metricfromid) | 静态方法（`IntimacyChartMetric`） | A | 解析持久化指标 id，不识别时为 null。 |
| `IntimacyChartRange.new` | 构造函数（`IntimacyChartRange`） | B | 把范围枚举值绑定到其持久化字符串 id。 |
| [`IntimacyChartRange.fromId`](#rangefromid) | 静态方法（`IntimacyChartRange`） | A | 解析持久化范围 id，不识别时为 null。 |
| [`IntimacyChartRange.cutoffFrom`](#cutofffrom) | 方法（`IntimacyChartRange`） | A | 返回此范围包含的最早 datetime。 |
| `_MetricSpec.new` | 构造函数（`_MetricSpec`） | B | 平凡转发构造函数。 |
| [`_MetricSpec.ceilingFor`](#ceilingfor) | 方法（`_MetricSpec`） | A | 把观测最大值吸附到干净的轴天花板。 |
| [`_metricSpecs`](#metricspecs) | 顶层函数 | A | 为当前主题构建逐指标规格表。 |
| [`buildRawSpots`](#buildrawspots) | 顶层函数 | A | 为逐记录指标构建未平滑点。 |
| [`buildEwmaSpots`](#buildewmaspots) | 顶层函数 | A | 为逐记录指标构建 EWMA 平滑曲线。 |
| [`buildRawFrequencySpots`](#buildrawfrequencyspots) | 顶层函数 | A | 用 7 天滚动窗口构建原始每周记录数点。 |
| [`buildEwmaFrequencySpots`](#buildewmafrequencyspots) | 顶层函数 | A | 构建 EWMA 平滑的每周记录数曲线。 |
| `_MetricSeries.new` | 构造函数（`_MetricSeries`） | B | 平凡转发构造函数。 |
| `_MetricSeries.hasData` | getter（`_MetricSeries`） | B | 系列是否至少有两个点可绘制。 |
| `IntimacyTrendChart.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_range` | getter（`IntimacyTrendChart`） | B | 解析为枚举的持久化范围 id，回退默认。 |
| [`_selectedMetrics`](#selectedmetrics) | getter（`IntimacyTrendChart`） | A | 解析为指标、按规范顺序的持久化指标 id。 |
| [`_toggleMetric`](#togglemetric) | 方法（`IntimacyTrendChart`） | A | 切换一个指标并上报新选择。 |
| [`_dateInterval`](#dateinterval) | 方法（`IntimacyTrendChart`） | A | 为绘制跨度返回底部轴日期标签间隔。 |
| [`IntimacyTrendChart.build`](#build) | 方法（组件） | A | 准备每个所选指标的系列并布局卡片。 |
| `_rangeChips` | 方法（组件辅助） | B | 构建六个紧凑时间范围选择 chip。 |
| [`_buildMetricSelector`](#buildmetricselector) | 方法（组件辅助） | A | 构建指标过滤 chip，兼作图例。 |
| [`_buildChart`](#buildchart) | 方法（组件辅助） | A | 构建多指标 `LineChart` 本身。 |
| `_axisTitles` | 方法（组件辅助） | B | 构建以真实单位重新标注 0-1 绘图空间的侧标题。 |
| [`_normalize`](#normalize) | 静态方法（`IntimacyTrendChart`） | A | 把指标的真实值缩放进共享 0-1 绘图空间。 |

**对账：** `grep -c 'Purpose:' lib/features/intimacy/widgets/intimacy_trend_chart.dart` 报告 25，与上面 25 行精确匹配（16 个 Tier A、9 个 Tier B）。枚举值本身（`pleasure`、`frequency`……）在此意义下不是声明，不带文档块；其含义在 [整合趋势图](../../../../features/intimacy.md#the-consolidated-trend-chart-v132) 中列表化。

## 渲染契约

五个指标单位不兼容，因此图表不使用真实 y 轴。绘图空间是无单位 `minY: 0, maxY: 1`，每个所选指标对照来自 `_MetricSpec.ceilingFor` 的自己吸附天花板归一化进它。真实值通过乘回那个天花板为轴和工具提示恢复。

- **第一个**规范顺序的可绘制指标拥有标注的**左**轴；**第二个**拥有**右**轴。两者都以系列自己的颜色绘制。
- 更多指标完全无轴绘制，从工具提示读取。
- 每个指标绘制**两次**：原始逐记录值的细实线（alpha 0.45、宽 1.5），然后虚线 `[6, 4]` 线（宽 2）的 EWMA 曲线。只有主指标的 EWMA 线获得 `belowBarData` 填充。
- 因此 `lineBarsData` 顺序是 `[raw₀, ewma₀, raw₁, ewma₁, …]`，工具提示回调依赖它：忽略偶条索引并把奇索引 `i` 映射到 `drawable[i ~/ 2]`。
- 空状态（`intimacyChartNoData`）同时覆盖"范围内少于两条记录"和"没有所选指标在范围内有两个或更多点"。

颜色和天花板步进表从此组件取代的四个图表逐字带过，因此既有图表看起来不变；`thrustRate` 是唯一新条目。

## 文档

### `static IntimacyChartMetric? fromId(String id)` <a id="metricfromid"></a>
- **种类：** `IntimacyChartMetric` 的静态方法
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 36 行）
- **用途：** 把持久化标识符解析回指标。
- **输入：** `id`。
- **返回：** `IntimacyChartMetric?` — id 不识别时为 null。
- **副作用：** 无。
- **备注：** 返回 null 而不是抛出的向前兼容契约：新版构建写入的 id 被跳过绘制，但留在持久化列表中。

### `static IntimacyChartRange? fromId(String id)` <a id="rangefromid"></a>
- **种类：** `IntimacyChartRange` 的静态方法
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 68 行）
- **用途：** 把持久化标识符解析回范围。
- **输入：** `id`。
- **返回：** `IntimacyChartRange?` — id 不识别时为 null。
- **副作用：** 无。
- **备注：** `_range` getter 把它与回退 `defaultRange` 配对，因此未知范围渲染为 3M 而不丢失存储字符串。

### `DateTime cutoffFrom(DateTime now)` <a id="cutofffrom"></a>
- **种类：** `IntimacyChartRange` 的方法
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 80 行）
- **用途：** 返回此范围包含的最早 datetime。
- **输入：** `now`，参考点（通常是当前本地时间）。
- **返回：** `DateTime`。
- **副作用：** 无。
- **算法：** `oneWeek` 减七天；`oneMonth`/`threeMonths`/`sixMonths` 和 `oneYear` 回退日历月或年并保持 day-of-month；`all` 返回 `DateTime(2000)` 哨兵。
- **备注：** 这是 v1.3.2 前存在于三处的截止 `switch` 的单一副本。`_ToyCostOverviewPageState._historyStart` 仍保留自己的变体，因为其 `all` case 解析为最早玩具购买日期。

### `double ceilingFor(double maxObserved)` <a id="ceilingfor"></a>
- **种类：** `_MetricSpec` 的方法
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 151 行）
- **用途：** 把观测最大值吸附到干净的轴天花板。
- **输入：** `maxObserved`。
- **返回：** `double`。
- **副作用：** 无。
- **算法：**
  1. 应用指标的 `headroom` 乘数并钳制到其 `minCeiling`。
  2. 返回 `ceilSteps` 中至少那么大的第一个条目。
  3. 超过最后一步后，向上舍入到下一个 `ceilFallbackStep` 倍数。
- **备注：** 泛化旧图表各自内联定义的四个手写 `freqCeil`/`minCeil`/`thrustCeil`/`minuteCeil` 本地函数，带相同步进表。

### `Map<IntimacyChartMetric, _MetricSpec> _metricSpecs(ThemeData theme)` <a id="metricspecs"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 166 行）
- **用途：** 返回当前主题的指标规格表。
- **输入：** `theme` — 用于愉悦度系列的主题色。
- **返回：** 每个枚举值都有一个条目的 `Map<IntimacyChartMetric, _MetricSpec>`。
- **副作用：** 无。
- **备注：** 取 `theme` 而不是 `const` 表，因为只有愉悦度用 `colorScheme.primary`；其他四个用固定高对比度颜色，使它们在浅深主题中都保持可区分。`frequency` 是唯一带 null `value` 提取器的条目——它从记录之间的间隔派生，不是从任何单条记录，因此构建方法把它路由到专用频率点构建器。

### `List<FlSpot> buildRawSpots(List<IntimacyRecord> visible, double? Function(IntimacyRecord) value)` <a id="buildrawspots"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 239 行）
- **用途：** 为逐记录指标构建原始（未平滑）点。
- **输入：** `visible` 记录已限制到所选范围，和 `value` 提取器。
- **返回：** `List<FlSpot>`，`x` 为自纪元起的毫秒。
- **副作用：** 无。
- **备注：** 提取器拒绝的记录被跳过而不是绘为零，因此无抽插次数的会话不会把抽插速率线拖到轴上。

### `List<FlSpot> buildEwmaSpots(List<IntimacyRecord> allData, DateTime visibleFrom, double? Function(IntimacyRecord) value, {double halfLifeDays = 7})` <a id="buildewmaspots"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 259 行）
- **用途：** 为逐记录指标构建 EWMA 平滑曲线。
- **输入：** `allData` 升序排序、`visibleFrom`、`value` 提取器、`halfLifeDays`。
- **返回：** `List<FlSpot>`。
- **副作用：** 无。
- **算法：**
  1. 收集提取器接受的记录及其值。
  2. 用第一个值播种平均并向前走。
  3. 每步计算 `alpha = 1 - exp(-dt / tau)`，其中 `tau = halfLifeDays` 毫秒，使平滑因子适配记录之间的真实间隔，而不是假设均匀间隔。
  4. 只在记录在 `visibleFrom` 或之后时发出点。
- **备注：** 在可见范围外的记录上预热是刻意的——意味着更改时间范围平移窗口而不改变曲线形状。此单函数取代了五个近乎相同的逐指标副本（愉悦度、时长、抽插次数，以及过滤页上前两者的重复）。

### `List<FlSpot> buildRawFrequencySpots(List<IntimacyRecord> allData, DateTime visibleFrom)` <a id="buildrawfrequencyspots"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 298 行）
- **用途：** 构建原始频率点——滚动窗口上的每周记录数。
- **输入：** `allData` 升序排序、`visibleFrom`。
- **返回：** `List<FlSpot>`。
- **副作用：** 无。
- **算法：** 对每条记录，向后走计数时间戳在前七天内、在第一条不是的记录处停止。
- **备注：** 与 pre-v1.3.2 实现不变。

### `List<FlSpot> buildEwmaFrequencySpots(List<IntimacyRecord> allData, DateTime visibleFrom, {double halfLifeDays = 14})` <a id="buildewmafrequencyspots"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 329 行）
- **用途：** 构建每周记录数的 EWMA 平滑频率曲线。
- **输入：** `allData` 升序排序、`visibleFrom`、`halfLifeDays`。
- **返回：** `List<FlSpot>`。
- **副作用：** 无。
- **算法：** 每个间隔贡献 `7 days / gap` 的瞬时速率，用与 `buildEwmaSpots` 相同的自适应 alpha 平滑。从每周一个的估计开始。
- **备注：** 频率用 14 天半衰期而不是 7 天默认，因为间隔派生的瞬时速率远比直接记录值嘈杂。与 pre-v1.3.2 实现不变。

### `List<IntimacyChartMetric> get _selectedMetrics` <a id="selectedmetrics"></a>
- **种类：** `IntimacyTrendChart` 的 getter
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 427 行）
- **用途：** 把持久化指标 id 按规范顺序解析为指标。
- **输入：** 无。
- **返回：** `List<IntimacyChartMetric>`。
- **副作用：** 无。
- **算法：** 用持久化 id 集合过滤 `IntimacyChartMetric.values`——这也无论存储列表顺序如何施加规范顺序——无可识别残留时回退默认指标。
- **备注：** 不可识别 id 在这里被跳过但留在 `settings` 中原样，使它们能往返回写入它们的任何构建。

### `void _toggleMetric(IntimacyChartMetric metric)` <a id="togglemetric"></a>
- **种类：** `IntimacyTrendChart` 的方法
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 447 行）
- **用途：** 切换一个指标并上报新选择。
- **输入：** `metric`。
- **返回：** 无。
- **副作用：** 调用 `onSettingsChanged`。
- **算法：** 复制持久化 id 列表、添加或移除此指标的 id 并上报。移除会留下无可识别指标时不上报地返回。
- **备注：** 拒绝最后一次移除正是保证图表绝不必渲染空绘图的东西；点击静默空操作而不是显示错误。在原始 id 列表的副本上操作使不可识别 id 保持在原位。

### `double _dateInterval(List<IntimacyRecord> visible)` <a id="dateinterval"></a>
- **种类：** `IntimacyTrendChart` 的方法
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 463 行）
- **用途：** 为绘制跨度返回底部轴标签间隔。
- **输入：** `visible`。
- **返回：** `double` — 毫秒间隔。
- **副作用：** 无。
- **算法：** 天数阈值 7/30/90/180/365/730 映射到 2/7/21/45/90/180 天间隔，落入年度。
- **备注：** 在任何范围保持约五到八个标签。曾是主图表和过滤图表间重复内容的单一副本。

### `Widget build(BuildContext context)` <a id="build"></a>
- **种类：** `IntimacyTrendChart` 的方法
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 483 行）
- **用途：** 为活动 UI 状态构建当前组件子树。
- **输入：** `context`。
- **返回：** 组件树：标题 + 范围 chip 行、指标选择器和 220px 图表区。
- **副作用：** 从当前状态创建 UI 组件。
- **算法：**
  1. 排序 `records` 副本升序并计算范围截止。
  2. 对每个所选指标，构建其原始和 EWMA 系列——把 `frequency` 路由到专用间隔基础构建器——并从观测最大值吸附天花板。
  3. 只保留至少两个点的系列作为 `drawable`。
  4. 范围内少于两条记录或无 drawable 时渲染空状态；否则调用 `_buildChart`。
- **备注：** 系列每次构建重新计算，匹配 pre-v1.3.2 行为；涉及记录数足够小，记忆化一直不必要。

### `Widget _buildMetricSelector(...)` <a id="buildmetricselector"></a>
- **种类：** `IntimacyTrendChart` 的方法（组件辅助）
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 612 行）
- **用途：** 构建兼作图例的指标选择器。
- **输入：** `theme`、`l10n`、`specs` 表和 `selected` 指标。
- **返回：** `Widget` — 每指标一个 `FilterChip` 的 `Wrap`。
- **副作用：** 无。
- **备注：** 每个 chip 的头像是旧 `_legendItem` 绘制的相同 10x2 彩色线色块，因此选中 chip 读作图例、未选中 chip 读作可用指标。这正是整合图表显示比其取代的两个图表更多系列却无需单独图例行原因。chip 密度匹配旁边范围 chip。

### `Widget _buildChart(...)` <a id="buildchart"></a>
- **种类：** `IntimacyTrendChart` 的方法（组件辅助）
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 653 行）
- **用途：** 构建多指标折线图本身。
- **输入：** `theme`、`l10n`、`drawable` 系列和 `visible` 记录。
- **返回：** `Widget` — `LineChart`。
- **副作用：** 无。
- **算法：** 每个系列发出原始条再 EWMA 条，把左右轴分配给前两个系列，只对奇条索引构建工具提示行，日期打印一次。
- **备注：** 见上面 [渲染契约](#the-rendering-contract)。条顺序承载负载——工具提示算术地把条索引映射回指标，而不是查找。

### `static List<FlSpot> _normalize(List<FlSpot> spots, double ceiling)` <a id="normalize"></a>
- **种类：** `IntimacyTrendChart` 的静态方法
- **来源：** `lib/features/intimacy/widgets/intimacy_trend_chart.dart`（第 822 行）
- **用途：** 把指标的真实值缩放进共享 0-1 绘图空间。
- **输入：** `spots`、`ceiling`。
- **返回：** `List<FlSpot>`。
- **副作用：** 无。
- **备注：** 钳制到 `0..1`，使单个离群值不能逃出绘图区，非正天花板返回空而不是除零。

## 相关页面

- [亲密](../../../../features/intimacy.md) — 此图表所属的功能。
- [`intimacy_page.dart`](../views/intimacy_page.md) — 此组件的两个宿主，以及留在那里的玩具每日成本图。
- [`intimacy_record.dart`](../models/intimacy_record.md) — `IntimacyRecord.thrustsPerMinute` 和持久化 `IntimacyChartSettings`。
- [数据格式](../../../../data-formats.md#intimacy--intimacy_datajson) — `chartSettings` JSON 形态。
- [同步](../../../../sync.md) — 选择如何在设置最后写入者胜出下合并。

# lib/features/finance/views/analysis_page.dart

财务功能的分析/图表视图：`AnalysisPage`（页面外壳，取当前交易/分类/账户快照和一个 `onTransactionsChanged` 回调，使下钻页做出的编辑能向上传播）及其 `_AnalysisPageState`，它拥有年/月/日/自定义时间范围选择器、两标签布局（分类饼图、支出/收入/资产趋势图）和三个在趋势计算方法与图表渲染方法之间携带图表轴/系列数据的小型私有值类（`_TrendScale`、`_TrendData`、`_ChartSeries`）。币种转换委托给 [`convertCurrency`/`currencySymbol`](../services/balance_util.md)，账户余额重建委托给 [`accountBalanceBefore`](../services/balance_util.md#accountbalancebefore)，历史/当前汇率查找委托给 [`ExchangeRateData.ratesAt`/`currentRates`](../services/exchange_rate_storage.md)——这些逻辑都不在这里重新实现。点击饼图图例中的分类会打开 `CategoryDetailPage` 供下钻。本页分类明细、趋势和总资产趋势功能的概念级摘要见 [财务](../../../../features/finance.md#views-and-analysis-page)。

尽管是视图文件，这里大多数非组件返回辅助都携带真实计算并被分类为 Tier A，按定级规则和本文件被点名"真实图表/明细计算逻辑"——时间范围过滤、饼图分类聚合、趋势刻度/趋势数据构建（含总资产趋势重建）和 `_TrendScale` 分桶辅助。纯组件组合方法（`build`、主要把已计算值组装进组件树的 `_build*` 方法）保持 Tier B。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `AnalysisPage`（构造函数） | 构造函数（`AnalysisPage`） | B | 创建分析页实例。 |
| `AnalysisPage.createState` | 方法（`AnalysisPage`） | B | 创建 `_AnalysisPageState`。 |
| `_AnalysisPageState.initState` | 方法（`_AnalysisPageState`） | B | 复制初始交易列表并创建标签控制器。 |
| [`didUpdateWidget`](#didupdatewidget) | 方法（`_AnalysisPageState`） | A | 父级提供新交易列表实例时重新同步本地交易。 |
| `_AnalysisPageState.dispose` | 方法（`_AnalysisPageState`） | B | 释放标签控制器。 |
| [`_filteredTransactions`](#_filteredtransactions) | getter（`_AnalysisPageState`） | A | 把交易过滤到当前选中的年/月/日/自定义范围。 |
| [`_filteredCategoryFlowTransactions`](#_filteredcategoryflowtransactions) | getter（`_AnalysisPageState`） | A | 把范围过滤交易进一步缩小到选中的收入/支出流类型。 |
| [`_rangeLabel`](#_rangelabel) | 方法（`_AnalysisPageState`） | A | 把当前选中的时间范围格式化为页头标签。 |
| [`_prev`](#_prev) | 方法（`_AnalysisPageState`） | A | 把选中的年/月/日回退一个单位。 |
| [`_next`](#_next) | 方法（`_AnalysisPageState`） | A | 把选中的年/月/日前进一步单位。 |
| [`_pickCustomRange`](#_pickcustomrange) | 方法（`_AnalysisPageState`） | A | 打开日期范围选择器并存储选中的自定义范围。 |
| `_buildCustomRangeSegmentLabel` | 方法（组件辅助） | B | 渲染"自定义范围"段标签，已选中时可点击重新编辑。 |
| `_buildCategoryTypeSelector` | 方法（组件辅助） | B | 为分类标签渲染支出/收入分段选择器。 |
| [`_openCategoryTransactions`](#_opencategorytransactions) | 方法（`_AnalysisPageState`） | A | 压入分类下钻页并合并回任何交易编辑。 |
| `build` | 方法（`_AnalysisPageState`） | B | 构建脚手架：带标签的应用栏、范围选择器、日期导航器、标签视图。 |
| [`_buildPieChart`](#_buildpiechart) | 方法（`_AnalysisPageState`） | A | 把过滤交易聚合成逐分类总计并渲染饼图 + 图例。 |
| `_buildTrendChart` | 方法（组件辅助） | B | 渲染支出/收入趋势面板，存在任何账户时渲染资产趋势面板。 |
| [`_buildTrendScale`](#_buildtrendscale) | 方法（`_AnalysisPageState`） | A | 为选中时间范围构建桶网格（起始/步进/点数/标签格式）。 |
| [`_buildTrendData`](#_buildtrenddata) | 方法（`_AnalysisPageState`） | A | 把所有交易分桶并累计求和为支出/收入/资产图表系列。 |
| [`_totalAssetsBefore`](#_totalassetsbefore) | 方法（`_AnalysisPageState`） | A | 重建给定时刻的总资产（默认币种）。 |
| `_buildLineChartPanel` | 方法（组件辅助） | B | 为一组图表系列渲染一个带标题的 `LineChart` 面板（图例 + 轴 + 工具提示）。 |
| [`_chartBounds`](#_chartbounds) | 方法（`_AnalysisPageState`） | A | 为折线图面板计算带内边距的 y 轴 min/max。 |
| [`_pointCount`](#_pointcount) | 方法（`_AnalysisPageState`） | A | 计算给定步进大小下时间跨度分成多少桶。 |
| [`_labelInterval`](#_labelinterval) | 方法（`_AnalysisPageState`） | A | 选产生约 6 个 x 轴标签的桶索引间隔。 |
| [`_formatAxisValue`](#_formataxisvalue) | 方法（`_AnalysisPageState`） | A | 大数值带 k/m 后缀格式化 y 轴值。 |
| `_legendDot` | 方法（组件辅助） | B | 渲染一个彩色点加标签的图表图例条目。 |
| `_TrendScale`（构造函数） | 构造函数（`_TrendScale`） | B | 打包图表的桶网格和标签/工具提示格式化器。 |
| [`bucketIndex`](#bucketindex) | 方法（`_TrendScale`） | A | 把日期映射到此刻度内的桶索引，越界为 `null`。 |
| [`sampleEnd`](#sampleend) | 方法（`_TrendScale`） | A | 返回给定桶的结束时刻，裁剪到刻度的范围。 |
| `xLabel` | 方法（`_TrendScale`） | B | 格式化桶索引的 x 轴标签。 |
| `tooltipLabel` | 方法（`_TrendScale`） | B | 格式化桶索引的工具提示标签。 |
| `_offset` | 方法（`_TrendScale`） | B | 计算 `start` 之后 `steps` 个桶的时刻。 |
| `_TrendData`（构造函数） | 构造函数（`_TrendData`） | B | 打包计算的支出/收入/资产点列表和 y 轴边界。 |
| `_ChartSeries`（构造函数） | 构造函数（`_ChartSeries`） | B | 打包一条图表线的标签、颜色、点和填充标志。 |

`grep -c 'Purpose:' lib/features/finance/views/analysis_page.dart` 报告 33，但上面表格有 34 行。差异是一个**未文档化的真实声明**：`_chartBounds`（`_AnalysisPageState`，第 1020 行）完全没有 `/// Purpose:` 块——恰好结束在它上方（第 1041-1045 行，`_pointCount` 的块）的文档注释块位于*下一*个声明上方，不是这个，`_chartBounds` 正上方没有任何注释。它是真实方法（计算带内边距的轴边界，第 893 行从 `_buildLineChartPanel` 调用），因此尽管源码中未文档化仍在这里计为声明。其他每个 `/// Purpose:` 块经验证都恰好位于其文档化的真实声明正上方——未发现错附块（记录调用点而非声明的块）。`enum _TimeRange`（第 12 行）和静态 `_chartColors` 调色板（第 1099-1112 行）是无行为的普通数据声明，按本文档集其他文件使用的相同约定，不给表格行。

## 文档

### `void didUpdateWidget(covariant AnalysisPage oldWidget)` <a id="didupdatewidget"></a>
- **种类：** `_AnalysisPageState` 的方法覆盖
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 75 行）
- **用途：** 父组件传入真正的新交易列表实例时重新同步本地持有的 `_transactions` 副本，否则保留页内编辑。
- **输入：** `oldWidget` — 先前的 `AnalysisPage` 配置。
- **返回：** 无。
- **副作用：** 可能重新赋值 `_transactions`（不包在 `setState` 中，因为这在已触发重建的同一构建趟期间运行）。
- **算法：** `widget.transactions` 与 `oldWidget.transactions` 不 `identical()` 时，用新鲜副本（`List.of(widget.transactions)`）替换 `_transactions`；否则不动 `_transactions`。
- **用法：** `FinancePage` 带新 `transactions`/`categories`/`accounts` 数据重建 `AnalysisPage` 时（如同步或别处编辑后）由 Flutter 框架自动调用——本文件任何代码不直接调用。
- **备注：** 因为 `_openCategoryTransactions` 的回调经 `setState`（第 302 行）本地重新赋值 `_transactions` 而不替换 `widget.transactions`，那个页内编辑不改变 `widget.transactions` 的同一性，因此由无关父重建触发的后续 `didUpdateWidget` 调用不会覆盖它——只有父级真正的新列表实例才会。

### `List<Transaction> get _filteredTransactions` <a id="_filteredtransactions"></a>
- **种类：** `_AnalysisPageState` 的 getter
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 99 行）
- **用途：** 把 `_transactions` 过滤到当前选中的年/月/日/自定义范围。
- **输入：** 无（读取 `_timeRange`、`_selectedMonth`、`_customRange`、`_transactions`）。
- **返回：** `List<Transaction>`。
- **副作用：** 无。
- **算法：** `switch (_timeRange)`：`year` → `date.year` 匹配 `_selectedMonth.year` 的交易；`month` → 年和月都匹配；`day` → 年/月/日都匹配；`custom` → `_customRange` 未设置时 `[]`，否则 `date` 在/晚于 `_customRange.start` 且严格早于 `_customRange.end + 1 day` 的交易（闭区间结束日期边界）。
- **用法：** 本文件唯一读者是 `_filteredCategoryFlowTransactions`（第 143 行）：
  ```dart
  List<Transaction> get _filteredCategoryFlowTransactions =>
      _filteredTransactions.where((t) => t.type == _categoryFlowType).toList();
  ```
- **备注：** 只有饼图标签（经 `_filteredCategoryFlowTransactions`）读此 getter——趋势标签的 `_buildTrendData` 刻意遍历*未过滤*的 `_transactions` 列表，依赖 `_TrendScale.bucketIndex`（从同一 `_timeRange` 派生）选择相关窗口，因此两个标签通过两个恰好都读 `_timeRange`/`_selectedMonth`/`_customRange` 而保持同步的不同机制实现范围过滤。

### `List<Transaction> get _filteredCategoryFlowTransactions` <a id="_filteredcategoryflowtransactions"></a>
- **种类：** `_AnalysisPageState` 的 getter
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 142 行）
- **用途：** 把范围过滤交易进一步缩小到只选中的流类型（支出或收入），供分类饼图标签。
- **输入：** 无（读取 `_filteredTransactions`、`_categoryFlowType`）。
- **返回：** `List<Transaction>`。
- **副作用：** 无。
- **算法：** `_filteredTransactions.where((t) => t.type == _categoryFlowType).toList()`。
- **用法：** `final categoryTransactions = _filteredCategoryFlowTransactions;`（`_buildPieChart`，第 424 行）。
- **备注：** 转账类型交易按构造被排除，因为 `_categoryFlowType` 只持有 `TransactionType.expense` 或 `TransactionType.income`（从 `_buildCategoryTypeSelector` 的两个段设置）。

### `String _rangeLabel(AppLocalizations l10n)` <a id="_rangelabel"></a>
- **种类：** `_AnalysisPageState` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 150 行）
- **用途：** 把当前选中的时间范围格式化为 prev/next 导航箭头之间的页头标签。
- **输入：** `l10n`。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** `switch (_timeRange)`：`year` → 裸年份数字；`month` → `yyyy-MM`；`day` → `yyyy-MM-dd`；`custom` → 尚未选范围时 `l10n.financeSelectDateRange`，否则从 `_customRange.start`/`.end` 构建 `'MM-dd ~ MM-dd'`。
- **用法：** `_rangeLabel(l10n)`（`build`，第 383 行，chevron/编辑按钮之间可点击的标签）。
- **备注：** 无。

### `void _prev()` <a id="_prev"></a>
- **种类：** `_AnalysisPageState` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 169 行）
- **用途：** 把选中的年/月/日回退一个单位（自定义范围模式空操作）。
- **输入：** 无。
- **返回：** 无。
- **副作用：** `setState` 重新赋值 `_selectedMonth`。
- **算法：** `switch (_timeRange)`：`year` → `_selectedMonth.year - 1`（同月）；`month` → `_selectedMonth.month - 1`（`DateTime` 把月下溢规范化为前一年）；`day` → 减一个日历日；`custom` → `break`（空操作，自定义模式经日期范围选择器而非 prev/next 导航）。
- **用法：** `onPressed: _prev`（`build`，第 374 行，左 chevron `IconButton`，只在 `_timeRange != _TimeRange.custom` 时显示）。
- **备注：** 无。

### `void _next()` <a id="_next"></a>
- **种类：** `_AnalysisPageState` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 195 行）
- **用途：** 把选中的年/月/日前进一步单位（自定义范围模式空操作）。
- **输入：** 无。
- **返回：** 无。
- **副作用：** `setState` 重新赋值 `_selectedMonth`。
- **算法：** `_prev` 的镜像：按 `_timeRange` 加而不是减一年/月/日；`custom` → 空操作。
- **用法：** `onPressed: _next`（`build`，第 392 行，右 chevron `IconButton`）。
- **备注：** 无。

### `Future<void> _pickCustomRange()` <a id="_pickcustomrange"></a>
- **种类：** `_AnalysisPageState` 的异步方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 221 行）
- **用途：** 打开共享应用日期范围选择器，用户确认选择时把它存为自定义范围。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 显示日期范围选择器对话框；确认后 `setState` 设置 `_customRange`。
- **算法：** `await showAppDateRangePicker(...)` 以既有 `_customRange` 播种，没有则"今天往前 30 天"；结果非 null 时 `setState(() => _customRange = picked)`。
- **用法：**
  ```dart
  onSelectionChanged: (s) {
    setState(() => _timeRange = s.first);
    if (s.first == _TimeRange.custom && _customRange == null) {
      _pickCustomRange();
    }
  }
  ```
  （`build`，第 357-361 行——用户首次切入自定义模式时自动打开选择器；也直接接到标签点击和编辑日历 `IconButton` 上，用于重新编辑既有自定义范围，第 379-381 和 395-398 行。）
- **备注：** 取消的选择器（`picked == null`）让 `_customRange` 不变，包括用户带着先前无范围切入自定义模式的情况——标签随后保持显示"选择日期范围"占位文本，直到实际选了一个范围。

### `void _openCategoryTransactions(String? categoryId)` <a id="_opencategorytransactions"></a>
- **种类：** `_AnalysisPageState` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 284 行）
- **用途：** 为点击的饼图图例条目（或未分类桶，`null` id 时）压入 `CategoryDetailPage`，并合并回在那里做出的任何交易编辑。
- **输入：** `categoryId` — `null` 表示未分类交易桶。
- **返回：** 无。
- **副作用：** 压入 `MaterialPageRoute`；被压入页的 `onTransactionsChanged` 回调做 `setState` 替换 `_transactions` 并调用 `widget.onTransactionsChanged` 把编辑向上传播给 `FinancePage`。
- **算法：**
  1. 在 `widget.categories` 中查找 `categoryId` 解析 `category`（`firstOrNull`；`categoryId` 为 `null` 或不再存在时保持 `null`）。
  2. 带解析的分类、*当前* `_transactions`/`widget.categories`/`widget.accounts`/`widget.rateData`/`widget.defaultCurrency`/`widget.accountPickerSettings` 和 `transactionType: category?.type ?? _categoryFlowType`（分类无法解析时回退所选标签的流类型，如未分类桶）压入 `CategoryDetailPage`。
  3. `onTransactionsChanged` 从被压入页返回时：`setState(() => _transactions = List.of(transactions))`，然后把同一列表转发给 `widget.onTransactionsChanged`。
- **用法：** `onTap: () => _openCategoryTransactions(e.categoryId)`（`_buildPieChart`，第 587 行，每个图例 `ListTile` 一个）。
- **备注：** 因为过期 `categoryId`（别处已删除的分类）仍解析为 `category == null` 而不是抛出，下钻页仍可为已删除分类的遗留交易打开——只是无法预填该分类自己的类型，因此有 `_categoryFlowType` 回退。

### `Widget _buildPieChart(BuildContext context)` <a id="_buildpiechart"></a>
- **种类：** `_AnalysisPageState` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 421 行）
- **用途：** 把所选范围的支出或收入交易聚合成逐分类总计，并渲染分类饼图加可点击图例，含未分类桶。
- **输入：** `context`。
- **返回：** `Widget`。
- **副作用：** 无直接；渲染的图例行点击时调用 `_openCategoryTransactions`。
- **算法：**
  1. `_filteredCategoryFlowTransactions` 为空时，渲染类型选择器加空状态消息（支出与其他类型的措辞不同）并提前返回。
  2. 把交易分组进以 `tx.categoryId` 为键的 `catTotals`（`null` 键 = 未分类），经 [`convertCurrency`](../services/balance_util.md#convertcurrency) 用该交易自己的历史汇率（`widget.rateData.ratesAt(tx.rateSnapshotId)`）把每笔交易的 `amount` 转换为 `widget.defaultCurrency`，求和进匹配桶。
  3. `total` = 所有桶总计之和。
  4. 按 `entry.key % colors.length` 从固定 12 条目 `_chartColors` 调色板为每个桶分配颜色（超过 12 个分类时颜色重复）；为每个桶构建带整百分比标签的 `PieChartSectionData`。
  5. 构建平行 `legendEntries` 记录 `(categoryId, name, color, amount, emoji)`，分类仍存在时从 `widget.categories` 解析 `name`/`emoji`，否则 `null`-id 桶回退 `l10n.financeUncategorized`（已删除分类的原始 id 逐字显示而不解析，因为那个分支没有回退查找）。
  6. 渲染 `PieChart`、总计行（收入绿色、支出 `theme.colorScheme.error`）和可滚动图例列表；每个图例行 `onTap` 调用 `_openCategoryTransactions(e.categoryId)`。
- **用法：** `_buildPieChart(context)`（`build`，第 406 行，两个 `TabBarView` 子组件之一）。
- **备注：** 桶迭代顺序（因此颜色分配）跟随 `Map` 插入顺序，即循环 `categoryTransactions` 时分类首次遇到的顺序——不是固定分类顺序，因此底层交易顺序变化时给定分类获得哪种颜色可跨渲染变化。它如何契合"可点击支出/收入分类明细含未分类流"功能见 [财务](../../../../features/finance.md#views-and-analysis-page)。

### `_TrendScale _buildTrendScale()` <a id="_buildtrendscale"></a>
- **种类：** `_AnalysisPageState` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 686 行）
- **用途：** 构建两个趋势图都对照采样的桶网格（起始时刻、桶步进、桶数、标签间隔和日期标签/工具提示格式化器），按当前选中时间范围适配大小。
- **输入：** 无（读取 `_timeRange`、`_selectedMonth`、`_customRange`）。
- **返回：** `_TrendScale`。
- **副作用：** 无。
- **算法：** `switch (_timeRange)`：
  1. `year` — 跨日历年的每桶一天（`Duration(days: 1)`）；标签/工具提示为 `M/d` / `yyyy-MM-dd`。
  2. `month` — 跨日历月的每桶一小时；标签为 `M/d`、工具提示为 `yyyy-MM-dd HH:00`。
  3. `day` — 跨单日的每桶一小时；标签为 `"${hour}h"`（定制闭包，不是 `DateFormat`）、固定 `labelInterval: 4`；工具提示为 `yyyy-MM-dd HH:00`。
  4. `custom` — 桶步进取决于范围总长度：`<= 48h` → 每小时；`<= 45 days` → 每 6 小时；否则每天。步进达到整天（`step.inHours >= 24`）后工具提示格式切到仅日期格式。
  5. 每个分支中 `pointCount` 来自 [`_pointCount`](#_pointcount)，`labelInterval`（除 `day` 分支的固定值外）来自 [`_labelInterval`](#_labelinterval)。
- **用法：** `final scale = _buildTrendScale();`（`_buildTrendChart`，第 618 行，然后传入 `_buildTrendData` 和两次 `_buildLineChartPanel` 调用，使流和资产面板共享一个桶网格）。
- **备注：** `day` 范围的 `labelForDate` 闭包完全绕过 `DateFormat`（`'${date.hour}h'`），不同于其他每个范围，这正是其 `labelInterval` 硬编码为 `4` 而非计算的原因——每小时的 `DateFormat` 模式需要闭包形式不需要的语言区域处理。

### `_TrendData _buildTrendData(_TrendScale scale)` <a id="_buildtrenddata"></a>
- **种类：** `_AnalysisPageState` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 776 行）
- **用途：** 把每笔交易分桶进给定刻度的网格，运行累计求和构建支出/收入趋势线，并在每个桶边界单独采样总资产构建资产趋势线。
- **输入：** `scale` — 来自 [`_buildTrendScale`](#_buildtrendscale)。
- **返回：** 打包 `expenseSpots`/`incomeSpots`/`assetSpots`（`List<FlSpot>`）和 `flowMaxY`/`assetMinY`/`assetMaxY` 轴边界的 `_TrendData`。
- **副作用：** 无。
- **算法：**
  1. 分配长度 `scale.pointCount`、零填充的 `expense`/`income` 数组。
  2. 对 `_transactions`（**未过滤**完整列表，不是 [`_filteredTransactions`](#_filteredtransactions)）中的每笔交易：经 `scale.bucketIndex(tx.date)` 找其桶；`null` 则跳过（在刻度窗口外）。经 `convertCurrency` 用该交易自己的历史汇率快照把 `tx.amount` 转换为 `widget.defaultCurrency`，然后按 `tx.type` 加进 `expense[idx]` 或 `income[idx]`（转账两者都不贡献）。
  3. 把逐桶增量变成运行总计：对 `i` 从 `1` 到 `pointCount - 1`，`expense[i] += expense[i-1]`（`income` 同理）——因此每个数组变成跨周期的累计支出/收入趋势，而不是逐桶金额。
  4. 对每个桶索引 `i` 在 `scale.sampleEnd(i)` 采样 [`_totalAssetsBefore`](#_totalassetsbefore) 构建 `assets`——这是 [财务](../../../../features/finance.md#views-and-analysis-page) 描述的总资产趋势重建。
  5. `flowMaxY` = 组合累计支出+收入数组的最大值（用于把流图 y 轴锚定在零）。`assetMinY`/`assetMaxY` = `assets` 的 min/max（不锚定到零）。
  6. 把每个数组包装为 `FlSpot(i, value)` 列表并返回 `_TrendData`。
- **用法：** `final trendData = _buildTrendData(scale);`（`_buildTrendChart`，第 619 行；`flowMaxY`/`assetMinY`/`assetMaxY` 随后用于决定每个面板是否有值得显示的数据）。
- **备注：** 遍历未过滤 `_transactions`（而不是范围过滤 getter）是刻意的：`scale.bucketIndex` 已限制哪些交易落入可见桶，因此单独过滤会多余——但这也意味着日期因当前时间范围选择之外的原因（如 dated 很远的未来交易）落在 `[start, endExclusive)` 外的交易被静默跳过而不是报错。

### `double _totalAssetsBefore(DateTime before)` <a id="_totalassetsbefore"></a>
- **种类：** `_AnalysisPageState` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 836 行）
- **用途：** 计算给定时刻、转换为 `widget.defaultCurrency` 的总资产——资产趋势线背后的采样函数。
- **输入：** `before` — 要重建资产的时刻（排他：只有严格早于它的交易计入）。
- **返回：** `double`。
- **副作用：** 无。
- **算法：** 按是否存在任何账户分两条路径：
  1. **无账户**（`widget.accounts.isEmpty`）：折叠每笔 dated 早于 `before` 的交易，经 `convertCurrency` 用该交易自己的历史汇率快照转换为 `widget.defaultCurrency`；支出减、收入加、转账跳过（转账在账户间移动资金而不改变总净值）。这镜像账户列表存在前使用的仅交易总计。
  2. **有账户：** 对每个账户调用 [`accountBalanceBefore(account, _transactions, widget.rateData, before)`](../services/balance_util.md#accountbalancebefore)（它自己从交易重建账户余额，尊重任何旧强制余额锚点——见 [财务](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)），然后用 **`widget.rateData.currentRates`**（今天的汇率，不是历史快照）把那个余额转换为 `widget.defaultCurrency`，并跨账户求和。
- **用法：** `(i) => _totalAssetsBefore(scale.sampleEnd(i))`（`_buildTrendData`，第 805 行，每桶一次）。
- **备注：** 两条路径用不同汇率来源：无账户回退用每笔交易自己的历史汇率快照，而有账户路径用**当前**汇率转换重建余额，而不是 `before` 时刻的汇率快照。这意味着有账户的资产趋势线反映每个历史余额以今天汇率值多少，而不是它在那个日期值多少——对汇率此后已变动的多币种账户是真实（虽微妙）的失真。

### `({double minY, double maxY}) _chartBounds(double minY, double maxY, {required bool anchorZero})` <a id="_chartbounds"></a>
- **种类：** `_AnalysisPageState` 的方法（源码中未文档化——无 `/// Purpose:` 块；见声明表上方的对账说明）
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 1020 行）
- **用途：** 为折线图面板计算带内边距的 y 轴范围，要么锚定在零（流图）要么在数据周围浮动（资产图）。
- **输入：** `minY`/`maxY` — 原始数据边界；`anchorZero` — 低边界是否必须是 `0`。
- **返回：** `(minY, maxY)` 记录 — 带内边距的轴边界。
- **副作用：** 无。
- **算法：**
  1. `minY == maxY`（平坦数据）时：`padding = minY.abs() * 0.1`，计算出 `0` 时回退 `1.0`（使全零系列仍得到可见带）；`anchorZero` 时返回 `(0, maxY + padding)`，否则 `(minY - padding, maxY + padding)`。
  2. 否则：`padding = (maxY - minY).abs() * 0.1`；与上面相同的锚零分支。
- **用法：** `final bounds = _chartBounds(minY, maxY, anchorZero: anchorZero);`（`_buildLineChartPanel`，第 893 行——按 `_buildTrendChart` 中两次 `_buildLineChartPanel` 调用点，支出/收入流面板以 `anchorZero: true` 调用、资产面板以 `anchorZero: false` 调用）。
- **备注：** `anchorZero: false`（资产面板）正是让总资产趋势线在绝对余额从未接近零时也能清楚显示相对变动的东西——像流面板那样把它钉在零会把小波动压缩成看起来平的线。

### `int _pointCount(DateTime start, DateTime end, Duration step)` <a id="_pointcount"></a>
- **种类：** `_AnalysisPageState` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 1046 行）
- **用途：** 计算覆盖 `[start, end)` 需要多少个 `step` 大小的桶。
- **输入：** `start`、`end`、`step`。
- **返回：** `int` — 至少 `1`。
- **副作用：** 无。
- **算法：** 向上整除总微秒跨度除以 `step` 的微秒长度：`(total + stepMicros - 1) ~/ stepMicros`；结果会 `0`（或负）时钳制到 `1`。
- **用法：** `final pointCount = _pointCount(start, end, step);`（`_buildTrendScale`，每个 `_timeRange` 分支调用一次，如第 696 行）。
- **备注：** 无。

### `double _labelInterval(int pointCount)` <a id="_labelinterval"></a>
- **种类：** `_AnalysisPageState` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 1058 行）
- **用途：** 选产生约 6 个可见标签、无论有多少桶的 x 轴标签之间的桶索引间隔。
- **输入：** `pointCount`。
- **返回：** `double` — 至少 `1`。
- **副作用：** 无。
- **算法：** `interval = (pointCount / 6).ceil()`，更小时下限为 `1`。
- **用法：** `labelInterval: _labelInterval(pointCount)`（`_buildTrendScale`，如第 702 行；`day` 范围分支改用硬编码 `4`，见 [`_buildTrendScale`](#_buildtrendscale) 的备注）。
- **备注：** 无。

### `String _formatAxisValue(double value)` <a id="_formataxisvalue"></a>
- **种类：** `_AnalysisPageState` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 1068 行）
- **用途：** 紧凑格式化 y 轴标签，大数值用 `k`/`m` 后缀。
- **输入：** `value`。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** `abs = value.abs()`；`abs >= 1_000_000` → `"${sign}${(abs/1e6).toStringAsFixed(1)}m"`；否则 `abs >= 1000` → `"${sign}${(abs/1000).toStringAsFixed(1)}k"`；否则经 `toStringAsFixed(0)` 把值四舍五入为整数。`sign` 负值时为 `'-'`（应用于已 `abs` 计算的量级），否则空。
- **用法：** `_formatAxisValue(value)`（`_buildLineChartPanel`，第 968 行，左轴刻度标签构建器）。
- **备注：** 无。

### `int? bucketIndex(DateTime date)` <a id="bucketindex"></a>
- **种类：** `_TrendScale` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 1144 行）
- **用途：** 把日期映射到此刻度网格内的桶索引，落在 `[start, endExclusive)` 外或会舍入到越界索引时为 `null`。
- **输入：** `date`。
- **返回：** `int?`。
- **副作用：** 无。
- **算法：** 守卫 `date.isBefore(start) || !date.isBefore(endExclusive)` → `null`；否则 `idx = date.difference(start).inMicroseconds ~/ step.inMicroseconds`；守卫 `idx < 0 || idx >= pointCount` → `null`；否则返回 `idx`。
- **用法：** `final idx = scale.bucketIndex(tx.date);`（`_buildTrendData`，第 781 行，逐交易分桶步骤）。
- **备注：** 第二道边界检查（`idx >= pointCount`）是防整数舍入把范围内日期的索引推过最后一个桶的防御守卫；与第一道守卫结合通常不应触发，但保护 `_buildTrendData` 的定长数组免受越界写入。

### `DateTime sampleEnd(int index)` <a id="sampleend"></a>
- **种类：** `_TrendScale` 的方法
- **来源：** `lib/features/finance/views/analysis_page.dart`（第 1156 行）
- **用途：** 返回桶 `index` 的结束时刻（即该桶累计数据应重建到的时间点），裁剪到刻度的整体结束。
- **输入：** `index`。
- **返回：** `DateTime`。
- **副作用：** 无。
- **算法：** `end = _offset(index + 1)`（*下一*桶的开始）；`end` 会越过 `endExclusive` 时返回 `endExclusive`，否则 `end`。
- **用法：** `(i) => _totalAssetsBefore(scale.sampleEnd(i))`（`_buildTrendData`，第 805 行）——每个资产趋势采样点取其桶的结束，不是开始。
- **备注：** 对最后桶裁剪到 `endExclusive` 重要，其名义结束（`_offset(pointCount)`）否则取决于 `_pointCount` 的舍入可能恰好落在或越过刻度边界。

## 相关页面

- [财务](../../../../features/finance.md#views-and-analysis-page) — 本页实现分类明细、趋势和总资产趋势重建的概念级描述。
- [`convertCurrency`/`currencySymbol`/`accountBalanceBefore`](../services/balance_util.md) — `_buildPieChart`、`_buildTrendData` 和 `_totalAssetsBefore` 贯穿使用的币种转换和账户余额重建。
- [`ExchangeRateData.ratesAt`/`currentRates`](../services/exchange_rate_storage.md) — 历史 vs 当前汇率查找，其区别支撑 `_totalAssetsBefore` 的备注。
- [`Transaction`/`Category`/`Account`/`AccountPickerSettings`](../models/finance.md) — 本页读取但不直接修改的模型类型（修改经 `onTransactionsChanged`/`_openCategoryTransactions` 流回）。

# lib/features/weight/views/weight_page.dart

体重功能的单一视图文件：`WeightPage`（页面壳）、其 `_WeightPageState`（数据加载/保存、摘要卡片、两个趋势图、分组历史、提醒设置）、`_WeightRecordDialog`/`_WeightRecordDialogState` 增/改表单，以及 `weight_data.json` 解析失败时显示的 `_WeightDataError` 阻塞错误视图。模型逻辑（`calculateBMI`/`calculateWaistHipRatio`/`effectiveMeasurementsUpTo`/`effectiveMeasurementTimeline`）住在 [`WeightRecord`/`WeightData`](../models/weight_record.md) 中，只从这里调用，不重新实现。持久化经 [`WeightStorage`](../services/weight_storage.md)。提醒调度/宽限期逻辑住在 [`ReminderService`](../../../shared/services/reminder_service.md)；本文件只编辑那个服务读取的设置。历史列表的周分组来自 [`groupByWeek`/`formatMonthDayRange`](../../../shared/utils/week_grouping.md)。增/改对话框的脏检查使用共享 [`UnsavedChangesGuard`/`formSignature`](../../../shared/widgets/unsaved_changes_guard.md) 模式。测量继承、提醒宽限期和 BMI/腰臀比的概念级解释见 [体重](../../../../features/weight.md)。

尽管是视图文件，其声明的很大一部分被归为 Tier A：摘要统计（BMI、体重变化、跟踪天数、近期范围）、两个 EWMA 平滑函数、图表轴/间隔数学和增/改对话框的验证/签名逻辑都包含超出组件组合的真实分支或计算，按分层规则。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`_decimalInputFormatter`](#_decimalinputformatter) | 顶层函数 | A | 创建带固定精度限制的十进制文本输入格式化器。 |
| `WeightPage`（构造函数） | 构造函数（`WeightPage`） | B | 创建体重页实例。 |
| `WeightPage.createState` | 方法（`WeightPage`） | B | 创建 `_WeightPageState`。 |
| `_WeightPageState.initState` | 方法（`_WeightPageState`） | B | 启动 `_loadData` 并订阅本地数据变更通知。 |
| `_WeightPageState.dispose` | 方法（`_WeightPageState`） | B | 退订本地数据变更通知。 |
| [`_loadData`](#_loaddata) | 方法（`_WeightPageState`） | A | 把 `weight_data.json` 加载进状态，或浮出阻塞读取错误。 |
| [`_saveData`](#_savedata) | 方法（`_WeightPageState`） | A | 把当前状态持久化为 `WeightData` 并通知同步/提醒服务。 |
| [`_latestRecord`](#_latestrecord) | getter（`_WeightPageState`） | A | 返回日期最近的记录。 |
| [`_currentBMI`](#_currentbmi) | getter（`_WeightPageState`） | A | 从最新记录体重和存储身高计算 BMI。 |
| [`_weightChange`](#_weightchange) | getter（`_WeightPageState`） | A | 计算所选图表范围上的体重变化。 |
| [`_trackingDays`](#_trackingdays) | getter（`_WeightPageState`） | A | 计算所选图表范围覆盖的天跨度。 |
| [`_recentRange`](#_recentrange) | getter（`_WeightPageState`） | A | 计算最近 7 条记录上的最小/最大体重。 |
| `build` | 方法（`_WeightPageState`） | B | 构建脚手架：应用栏、加载/错误/空/内容主体、添加 FAB。 |
| `_buildEmptyState` | 方法（组件辅助） | B | 渲染带设身高捷径的"尚无记录"占位。 |
| `_buildContent` | 方法（组件辅助） | B | 组合摘要卡片、图表小节和记录列表。 |
| `_buildSummaryCard` | 方法（组件辅助） | B | 渲染体重/BMI/测量/腰臀比摘要卡片。 |
| [`_latestMeasurementStats`](#_latestmeasurementstats) | 方法（`_WeightPageState`） | A | 把有效胸/腰/臀值变成显示标签/值对。 |
| `_buildStatLabel` | 方法（组件辅助） | B | 渲染一个标签在上值在下的统计格，带可选尾部组件。 |
| [`_buildBMIBar`](#_buildbmibar) | 方法（`_WeightPageState`） | A | 构建 BMI 类别条（偏瘦/正常/超重/肥胖）。 |
| [`_buildWaistHipRatioBar`](#_buildwaisthipratiobar) | 方法（`_WeightPageState`） | A | 构建腰臀比类别条。 |
| `_buildSegmentedScaleBar` | 方法（组件辅助） | B | 渲染带位置标记的通用彩色分段条。 |
| `_buildChartSection` | 方法（组件辅助） | B | 渲染范围选择 chip、图例和两个趋势图。 |
| `_buildChartLegendItem` | 方法（组件辅助） | B | 渲染一个实线/虚线线色图例条目。 |
| [`_chartRecords`](#_chartrecords) | getter（`_WeightPageState`） | A | 过滤并排序记录到所选图表范围内。 |
| `_buildChart` | 方法（组件辅助） | B | 渲染原始 + EWMA 体重 `LineChart`。 |
| `_buildMeasurementChart` | 方法（组件辅助） | B | 渲染原始 + EWMA 胸/腰/臀 `LineChart`。 |
| `_buildDateTitle` | 方法（组件辅助） | B | 渲染一个底部轴日期标签，格式按范围密度选择。 |
| [`_buildMeasurementSpots`](#_buildmeasurementspots) | 方法（`_WeightPageState`） | A | 为一个有效测量字段构建图表点。 |
| [`_measurementAxisRange`](#_measurementaxisrange) | 方法（`_WeightPageState`） | A | 为测量点计算填充厘米 y 轴范围。 |
| `_buildMeasurementChartLine` | 方法（组件辅助） | B | 为测量系列构建一个实线或虚线 `LineChartBarData`。 |
| [`_buildWeightEwmaSpots`](#_buildweightewmaspots) | 方法（`_WeightPageState`） | A | 计算 EWMA 平滑体重点（7 天半衰期）。 |
| [`_buildMeasurementEwmaSpots`](#_buildmeasurementewmaspots) | 方法（`_WeightPageState`） | A | 为一个有效测量字段计算 EWMA 平滑点。 |
| [`_weightInterval`](#_weightinterval) | 方法（`_WeightPageState`） | A | 为体重图挑选可读 y 轴间隔。 |
| [`_measurementInterval`](#_measurementinterval) | 方法（`_WeightPageState`） | A | 为测量图挑选可读 y 轴间隔。 |
| [`_dateInterval`](#_dateinterval) | 方法（`_WeightPageState`） | A | 基于数据时间跨度挑选可读 x 轴（日期）间隔。 |
| `_buildRecordsList` | 方法（组件辅助） | B | 渲染历史页头、最多 20 个分组块和"显示全部"链接。 |
| `_buildGroupedRecordTiles` | 方法（组件辅助） | B | 按周分组记录并渲染每条记录的页头 + 块。 |
| `_buildWeekHeader` | 方法（组件辅助） | B | 渲染一个周组页头行。 |
| `_buildRecordTile` | 方法（组件辅助） | B | 渲染一个可关闭（滑动删除）历史行。 |
| [`_formatMeasurements`](#_formatmeasurements) | 方法（`_WeightPageState`） | A | 把记录自己的胸/腰/臀格式化为一个历史行字符串。 |
| `_showAllRecords` | 方法（`_WeightPageState`） | B | 打开列出按周分组的每条记录的可拖拽底部面板。 |
| [`_showReminderSettings`](#_showremindersettings) | 方法（`_WeightPageState`） | A | 打开提醒设置面板；拥有模式切换默认时间逻辑。 |
| [`_formatReminderGraceHours`](#_formatremindergracehours) | 方法（`_WeightPageState`） | A | 把存储宽限分钟格式化为修剪小时字符串。 |
| `_editReminderGrace` | 方法（组件辅助） | B | 打开宽限窗口编辑对话框。 |
| [`_saveReminderGrace`](#_saveremindergrace) | 方法（`_WeightPageState`） | A | 验证并持久化新提醒宽限窗口（0-24h）。 |
| [`_addRecord`](#_addrecord) | 方法（`_WeightPageState`） | A | 打开添加记录对话框，成功时追加并持久化。 |
| [`_editRecord`](#_editrecord) | 方法（`_WeightPageState`） | A | 打开编辑记录对话框，成功时替换并持久化。 |
| `_setHeight` | 方法（组件辅助） | B | 打开设身高对话框（验证委托给嵌套 `saveHeight`）。 |
| [`saveHeight`](#saveheight) | 本地函数（嵌套在 `_setHeight` 内） | A | 验证并持久化输入身高，然后关闭对话框。 |
| [`_timeSinceLastRecord`](#_timesincelastrecord) | 方法（`_WeightPageState`） | A | 把距记录 `datetime` 的已流逝时间格式化为相对文本。 |
| `_WeightRecordDialog`（构造函数） | 构造函数（`_WeightRecordDialog`） | B | 创建体重记录对话框实例（增或改）。 |
| `_WeightRecordDialog.createState` | 方法（`_WeightRecordDialog`） | B | 创建 `_WeightRecordDialogState`。 |
| `_isEditing` | getter（`_WeightRecordDialogState`） | B | 返回此对话框是否编辑既有记录。 |
| `_WeightRecordDialogState.initState` | 方法（`_WeightRecordDialogState`） | B | 从 `initialRecord`/`lastWeight` 初始化控制器并捕获 `_initialSignature`。 |
| `_WeightRecordDialogState.dispose` | 方法（`_WeightRecordDialogState`） | B | 释放所有文本控制器。 |
| `_WeightRecordDialogState.build` | 方法（`_WeightRecordDialogState`） | B | 构建增/改表单（体重、测量、备注、日期、操作）。 |
| `_hasUnsavedChanges` | 方法（`_WeightRecordDialogState`） | B | 比较当前签名与初始签名。 |
| `_signature` | 方法（`_WeightRecordDialogState`） | B | 构建表单当前字段值的 `formSignature` 快照。 |
| `_buildMeasurementField` | 方法（组件辅助） | B | 渲染一个可选胸/腰/臀输入字段。 |
| [`_previewBMI`](#_previewbmi) | getter（`_WeightRecordDialogState`） | A | 从进行中的体重输入计算实时 BMI 预览。 |
| [`_formatInitialMeasurement`](#_formatinitialmeasurement) | 方法（`_WeightRecordDialogState`） | A | 为初始控制器文本格式化持久化测量。 |
| [`_optionalMeasurement`](#_optionalmeasurement) | 方法（`_WeightRecordDialogState`） | A | 从文本控制器解析正可选测量。 |
| [`_submit`](#_submit) | 方法（`_WeightRecordDialogState`） | A | 验证输入、构建结果 `WeightRecord` 并带它弹出。 |
| `_WeightDataError`（构造函数） | 构造函数（`_WeightDataError`） | B | 创建阻塞体重数据读取错误视图。 |
| `_WeightDataError.build` | 方法（`_WeightDataError`） | B | 渲染错误消息和重试按钮。 |

`grep -c 'Purpose:' lib/features/weight/views/weight_page.dart` 报告 65，与上面计数的全部 65 个真实声明精确匹配（31 个 Tier A、34 个 Tier B）。每个 `/// Purpose:` 块都恰好位于其文档化的真实声明正上方——未发现错附块（记录调用点而非声明的块）——也不存在未文档化真实声明：五个顶层 `const Color ...` 图表颜色常量（第 20-24 行）和 `_ChartRange` 枚举（第 56 行）是无行为的普通数据/类型声明，因此与 [`weight_record.md`](../models/weight_record.md) 处理普通类型别名的方式一致，刻意不给表格行。唯一嵌套本地函数 `_setHeight` 内的 `saveHeight`（第 1817 行）确实带自己的 `/// Purpose:` 块并被计为真实声明。

## 文档

### `TextInputFormatter _decimalInputFormatter(int decimalPlaces)` <a id="_decimalinputformatter"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/weight/views/weight_page.dart`（第 31 行）
- **用途：** 构建只允许匹配小数点后最多 `decimalPlaces` 位的十进制数的 `TextInputFormatter`，同时编辑期间仍允许临时空/悬空点输入。
- **输入：** `decimalPlaces` — 小数点后允许的最大位数。
- **返回：** `TextInputFormatter`。
- **副作用：** 无。
- **算法：**
  1. 新文本为空时无条件接受（让用户清除字段）。
  2. 否则把新文本对照 `^\d*\.?\d{0,decimalPlaces}$` 测试。
  3. 匹配则返回新值，否则拒绝编辑并保留旧值。
- **用法：**
  ```dart
  TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [_decimalInputFormatter(1)],
    decoration: InputDecoration(labelText: l10n.weightHeightCm, suffixText: 'cm'),
  )
  ```
  （`_setHeight`，第 1835-1840 行；带 1 位小数的相同格式化器被 `_editReminderGrace`、`_buildMeasurementField` 和对话框体重字段复用。）
- **备注：** 正则允许编辑中途尾部/悬空 `.`（如 `"12."`），因为 `\.?` 与 `\d{0,decimalPlaces}` 结合允许零尾随位数——别处的最终解析（`double.tryParse`）容忍它。

### `Future<void> _loadData()` <a id="_loaddata"></a>
- **种类：** `_WeightPageState` 的 async 方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 100 行）
- **用途：** 经 `WeightStorage.load()` 把 `weight_data.json` 加载进状态，或——文件存在但无法解析时——浮出阻塞读取错误而非静默当作空数据集。
- **输入：** 无（读取 `WeightStorage.load()`）。
- **返回：** `Future<void>`。
- **副作用：** 调用 `setState`（切换 `_loaded`、填充 `_height`/`_records`/提醒字段，或设 `_loadError`）；两种情况下都调用 `ReminderService.instance.updateWeightData`（错误时带空记录列表）。
- **算法：**
  1. 已加载且 mounted 时把 `_loaded` 翻回 `false`（`AutoSyncService` 的本地数据变更通知触发的重载在途时显示加载转圈）。
  2. `await WeightStorage.load()`。异常时：告诉 `ReminderService` 无记录、`mounted` 守卫、`setState` 记录 `_loadError = e.toString()` 和 `_loaded = true`，然后返回——错误视图接管而非显示空状态。
  3. 成功时（`mounted` 守卫）：清除 `_loadError`；`data != null` 时把 `height`/`records`/`reminderMode` 复制进状态，存储小时和分钟都非 null 时才把 `_weightMorningReminder`/`_weightEveningReminder` 重建为 `TimeOfDay`；设 `_loaded = true`。
  4. 把新加载提醒字段推给 `ReminderService.instance.updateWeightData`。
- **用法：**
  ```dart
  @override
  void initState() {
    super.initState();
    _loadData();
    AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  }
  ```
  （第 77-81 行；也作为 `onRetry: _loadData` 传给 `_WeightDataError`，第 283 行。）
- **备注：** 抛出的加载绝不回退到 UI 中的"无记录"——`build` 主体 switch 中 `_loadError` 优先于 `_records.isEmpty`（第 280-286 行），因此写入保持禁用直到文件再次可读（见 `_saveData`）。

### `Future<void> _saveData()` <a id="_savedata"></a>
- **种类：** `_WeightPageState` 的 async 方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 149 行）
- **用途：** 把内存状态持久化为 `WeightData` 文档，加载在途或已知加载文件不可读时拒绝。
- **输入：** 无（读取当前状态字段）。
- **返回：** `Future<void>`。
- **副作用：** 可能显示 `SnackBar`（写阻塞消息）；调用 `WeightStorage.save`；调用 `ReminderService.instance.updateWeightData`；调用 `AutoSyncService.instance.notifySaved()`。
- **算法：**
  1. `!_loaded` 时立即返回（首次加载完成前空操作）。
  2. `_loadError != null` 时显示 `weightDataWriteBlocked` snackbar 并写入前返回——这正是防止不完整内存状态覆盖无法解析文件的东西。
  3. 否则从当前字段构建 `WeightData`，盖章 `settingsModifiedAt = DateTime.now().toUtc()`，并 `await WeightStorage.save(...)`。
  4. 把相同提醒字段推给 `ReminderService.instance.updateWeightData`。
  5. 调用 `AutoSyncService.instance.notifySaved()` 触发应用自动同步周期。
- **用法：** 每个修改操作后 `await _saveData();`——`_addRecord`、`_editRecord`、`saveHeight`、`_saveReminderGrace`、`_showReminderSettings` 中的提醒模式/时间选择器回调，以及 `_buildRecordTile` 的滑动删除处理器。
- **备注：** 因为步骤 1/2 静默返回（除 snackbar 外），总是 await `_saveData()` 的调用方不能假设写入实际发生——守卫刻意默认静默，使不可读时只读浏览不每次尝试写入都刷 snackbar。

### `WeightRecord? get _latestRecord` <a id="_latestrecord"></a>
- **种类：** `_WeightPageState` 的 getter
- **来源：** `lib/features/weight/views/weight_page.dart`（第 190 行）
- **用途：** 返回 `datetime` 最近的记录。
- **输入：** 无。
- **返回：** `WeightRecord?` — `_records` 为空时 `null`。
- **副作用：** 无。
- **算法：** 复制 `_records`、按 `datetime` 降序排序、返回第一个元素（列表为空时 `null`）。
- **用法：** `final latest = _latestRecord!;`（`_buildContent`，第 337 行——`build` 中 `_records.isEmpty` 已被检查为 false 后才会到达）。
- **备注：** 每次访问重新排序完整列表而非缓存结果；鉴于典型体重历史规模可接受。

### `double? get _currentBMI` <a id="_currentbmi"></a>
- **种类：** `_WeightPageState` 的 getter
- **来源：** `lib/features/weight/views/weight_page.dart`（第 202 行）
- **用途：** 从最新记录体重和存储身高计算 BMI，供摘要卡片。
- **输入：** 无。
- **返回：** `double?` — 无记录时 `null`，否则 `WeightData.calculateBMI(_height, latest.weight)`（`_height` 未设/`<= 0` 时其本身 `null`；见 [`WeightData.calculateBMI`](../models/weight_record.md#calculatebmi)）。
- **副作用：** 无。
- **算法：** 对 `_latestRecord == null` 守卫，然后委托 `WeightData.calculateBMI`。
- **用法：** `final bmi = _currentBMI;`（`_buildContent`，第 338 行，喂进 `_buildSummaryCard` 并从那里进 `_buildBMIBar`）。
- **备注：** 无。

### `double? get _weightChange` <a id="_weightchange"></a>
- **种类：** `_WeightPageState` 的 getter
- **来源：** `lib/features/weight/views/weight_page.dart`（第 214 行）
- **用途：** 计算当前所选图表范围（如 1M、3M、全部）上的体重变化。
- **输入：** 无（读取 `_chartRecords`）。
- **返回：** `double?` — 所选范围内少于 2 条记录时 `null`，否则 `data.last.weight - data.first.weight`（按时间顺序最后减最先，正即增重）。
- **副作用：** 无。
- **算法：** 对 `_chartRecords.length < 2` 守卫，然后对按时间排序范围简单减法。
- **用法：** `final change = _weightChange;`（`_buildContent`，第 339 行，摘要卡片中显示按符号红/蓝着色的上下箭头）。
- **备注：** 依赖与图表相同的所选 `_chartRange`，不是固定窗口——切换范围选择器也会改变摘要卡片上"体重变化"的含义。

### `int? get _trackingDays` <a id="_trackingdays"></a>
- **种类：** `_WeightPageState` 的 getter
- **来源：** `lib/features/weight/views/weight_page.dart`（第 225 行）
- **用途：** 计算所选图表范围记录跨多少天。
- **输入：** 无（读取 `_chartRecords`）。
- **返回：** `int?` — 所选范围内少于 2 条记录时 `null`，否则 `data.last.datetime.difference(data.first.datetime).inDays`。
- **副作用：** 无。
- **算法：** 对长度 `< 2` 守卫，然后普通 `DateTime` 整数天差值。
- **用法：** `final days = _trackingDays;`（`_buildContent`，第 340 行；显示在体重变化箭头旁为 `"$days ${l10n.weightDays}"`）。
- **备注：** 无。

### `(double, double)? get _recentRange` <a id="_recentrange"></a>
- **种类：** `_WeightPageState` 的 getter
- **来源：** `lib/features/weight/views/weight_page.dart`（第 237 行）
- **用途：** 计算最近 7 条按日期排序记录上的最小/最大体重，独立于图表范围选择器。
- **输入：** 无（读取 `_records`）。
- **返回：** `(double, double)?` — 无记录时 `null`；否则最多 7 条最新记录 `weight` 的 `(min, max)`。
- **副作用：** 无。
- **算法：** 复制并按 `datetime` 降序排序 `_records`、`take(7)`、然后对 `.weight` 用 `math.min`/`math.max` 归约。
- **用法：** `final range = _recentRange;`（`_buildContent`，第 341 行，渲染为显示 `"min–max"` 的"近期"统计）。
- **备注：** 与 `_weightChange`/`_trackingDays` 不同，这总是看最新 7 条*记录*（不是所选图表范围），因此无论选哪个范围 chip 都保持稳定。

### `List<(String, String)> _latestMeasurementStats(EffectiveWeightMeasurements measurements, AppLocalizations l10n)` <a id="_latestmeasurementstats"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 520 行）
- **用途：** 把有效（继承）胸/腰/臀值变成摘要卡片的本地化 `(label, value)` 对，省略无当前继承值的任何字段。
- **输入：** `measurements` — 来自 [`WeightData.effectiveMeasurementsUpTo`](../models/weight_record.md#effectivemeasurementsupto) 的 `EffectiveWeightMeasurements` 记录；`l10n`。
- **返回：** `List<(String, String)>` — 零到三个对，各为 `"${value.toStringAsFixed(1)} cm"`。
- **副作用：** 无。
- **算法：** 每个胸/腰/臀字段一个 `if (field != null)` 条目的列表字面量，按该顺序。
- **用法：** `final measurements = _latestMeasurementStats(effectiveMeasurements, l10n);`（`_buildSummaryCard`，第 388 行，经 `for` 循环为每对喂一个 `_buildStatLabel`）。
- **备注：** 这只省略已继承 `measurements` 值中缺席的字段——继承本身（回退较早记录的最近正值）由 `effectiveMeasurementsUpTo` 完成，不在这里。见 [体重](../../../../features/weight.md#bustwaisthip-inheritance-from-the-latest-positive-value)。

### `Widget _buildBMIBar(ThemeData theme, double bmi)` <a id="_buildbmibar"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 586 行）
- **用途：** 渲染带给定 BMI 位置标记的紧凑 4 段彩色条（偏瘦/正常/超重/肥胖）。
- **输入：** `theme`；`bmi`。
- **返回：** `Widget`。
- **副作用：** 无。
- **算法：**
  1. 经 `((bmi - 15) / 25).clamp(0.0, 1.0)` 把 `bmi` 映射到规范化 `0.0-1.0` 位置——可见刻度跨 BMI 15 到 40。
  2. 委托 `_buildSegmentedScaleBar`，四个段按 25 总 flex 单位的 `7:6:5:7`（蓝/绿/橙/红）——即段边界大致落在 BMI 22（蓝→绿；偏瘦/正常边界 ~18.5 *不*单独标记；flex 比例是视觉近似，不是精确 18.5/25/30 映射）和标记位置。
- **用法：**
  ```dart
  if (bmi != null)
    _buildStatLabel(theme, 'BMI', bmi.toStringAsFixed(1), trailing: _buildBMIBar(theme, bmi)),
  ```
  （`_buildSummaryCard`，第 400-406 行。）
- **备注：** 第 587 行注释陈述预期临床边界（`<18.5 偏瘦、18.5-25 正常、25-30 超重、30+ 肥胖`），但实际段 `flex` 值（`(bmi-15)/25` 刻度上的 `7, 6, 5, 7`）是固定视觉近似而非那些精确阈值到 15-40 刻度的计算映射。

### `Widget _buildWaistHipRatioBar(ThemeData theme, double ratio)` <a id="_buildwaisthipratiobar"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 602 行）
- **用途：** 为腰臀比风险类别渲染带给定比例位置标记的紧凑 4 段彩色条。
- **输入：** `theme`；`ratio`。
- **返回：** `Widget`。
- **副作用：** 无。
- **算法：**
  1. 经 `((ratio - 0.65) / 0.45).clamp(0.0, 1.0)` 把 `ratio` 映射到规范化位置——可见刻度跨比例 0.65 到 1.10。
  2. 委托 `_buildSegmentedScaleBar`，四个段按 45 总 flex 单位的 `15:10:10:10`（绿/橙/深橙/红），类别边界放在 0.65-1.10 刻度上约 0.80、0.90 和 1.00——匹配源码注释说明的"通用视觉阈值"。
- **用法：**
  ```dart
  if (waistHipRatio != null)
    _buildStatLabel(theme, l10n.weightWaistHipRatio, waistHipRatio.toStringAsFixed(2),
        trailing: _buildWaistHipRatioBar(theme, waistHipRatio)),
  ```
  （`_buildSummaryCard`，第 409-415 行；`waistHipRatio` 本身来自喂*有效*（继承）腰/臀值而非原始记录字段的 [`WeightData.calculateWaistHipRatio`](../models/weight_record.md#calculatewaisthipratio)。）
- **备注：** 与 `_buildBMIBar` 一样，段 flex 值是 0.80/0.90/1.00 边界的固定视觉近似，不是计算放置。

### `List<WeightRecord> get _chartRecords` <a id="_chartrecords"></a>
- **种类：** `_WeightPageState` 的 getter
- **来源：** `lib/features/weight/views/weight_page.dart`（第 796 行）
- **用途：** 把 `_records` 过滤到当前所选图表范围（`_chartRange`）并按时间排序供图表渲染。
- **输入：** 无（读取 `_records`、`_chartRange`）。
- **返回：** `List<WeightRecord>`，按 `datetime` 升序。
- **副作用：** 无。
- **算法：**
  1. 经对 `_chartRange` 的 `switch` 计算 `cutoff` `DateTime`：`oneWeek` → 现在减 7 天；`oneMonth`/`threeMonths`/`sixMonths`/`oneYear` → 对 `now` 做日历月/年算术（`DateTime(now.year, now.month - N, now.day)`，`DateTime` 为负月规范化）；`all` → 2000 年（对本应用数据实际无截止）。
  2. 过滤到 `r.datetime.isAfter(cutoff)`，然后按 `datetime` 升序排序。
- **用法：** `final data = _chartRecords;`（`_buildChart` 第 817 行、`_buildMeasurementChart` 第 956 行，并间接经 `_weightChange`/`_trackingDays`）。
- **备注：** 用 `isAfter(cutoff)`（严格在之后），因此恰在截止时刻的记录被排除——实践中无关紧要，因为截止在渲染时从 `DateTime.now()` 计算，不是从存储边界值。

### `List<FlSpot> _buildMeasurementSpots(List<EffectiveWeightMeasurementPoint> data, double? Function(EffectiveWeightMeasurementPoint point) selectValue)` <a id="_buildmeasurementspots"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1168 行）
- **用途：** 把一个有效测量时间线转换为单个字段（胸、腰或臀）的原始（未平滑）图表点，跳过该字段尚无继承值的点。
- **输入：** `data` — 有效测量时间线（已继承解析，见 [`WeightData.effectiveMeasurementTimeline`](../models/weight_record.md#effectivemeasurementtimeline)）；`selectValue` — 字段选择器回调（如 `(point) => point.bustCm`）。
- **返回：** `List<FlSpot>` — `selectValue(point)` 非 null 的每个点一个，`x` 为纪元毫秒。
- **副作用：** 无。
- **算法：** `data.map(...)` 按 `selectValue(point)` 为每个点构建 `FlSpot` 或 `null`，然后 `.whereType<FlSpot>()` 丢弃 null。
- **用法：**
  ```dart
  final bustSpots = _buildMeasurementSpots(visibleTimeline, (point) => point.bustCm);
  ```
  （`_buildMeasurementChart`，第 971-982 行，对已过滤到可见截止的时间线每字段调用一次。）
- **备注：** 因为输入时间线已携带继承值（来自 `effectiveMeasurementTimeline`），这里只有在字段到那个点*从未*有过显式正值时才跳过点——不只是因为当前记录省略它。

### `(double, double) _measurementAxisRange(List<FlSpot> spots)` <a id="_measurementaxisrange"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1190 行）
- **用途：** 跨所有胸/腰/臀（原始 + EWMA）点计算填充 y 轴范围（cm），使近乎相同测量保持视觉可区分。
- **输入：** `spots` — 所有测量图表点（原始和 EWMA、全部三个字段）的组合列表。
- **返回：** `(double, double)` — `spots` 为空时 `(0, 1)`；否则 `(low, maxCm + pad)`。
- **副作用：** 无。
- **算法：**
  1. 对所有点 `y` 值经 `reduce(math.min)`/`reduce(math.max)` 得 `minCm`/`maxCm`。
  2. `pad = max((maxCm - minCm) * 0.15, 2.0)`——即使范围近乎平坦也至少 2 cm 填充。
  3. `low = max(0, minCm - pad)`（绝不为负）；高界为 `maxCm + pad`。
- **用法：** `final (minY, maxY) = _measurementAxisRange(allSpots);`（`_buildMeasurementChart`，第 1020 行，`allSpots` 连接全部三字段原始和 EWMA 点，使共享轴适合每条线）。
- **备注：** 最小 2 cm 填充正是让胸/腰/臀在可见范围几乎不变时图表可用性的东西——没有它，近乎零的 `(maxCm - minCm)` 会产生极薄（或退化）的轴带。

### `List<FlSpot> _buildWeightEwmaSpots(List<WeightRecord> allData, DateTime visibleFrom, {double halfLifeDays = 7})` <a id="_buildweightewmaspots"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1228 行）
- **用途：** 计算带可配置半衰期的体重指数加权移动平均（EWMA），在*完整*记录历史上预热但只从 `visibleFrom` 起发出点。
- **输入：** `allData` — **所有**按最旧→最新排序的记录（不只是可见范围：预热准确性需要）；`visibleFrom` — 实际发出点的第一个 datetime；`halfLifeDays` — 默认 7。
- **返回：** `List<FlSpot>`，`visibleFrom` 或之后的每条记录一个，`x` 为纪元毫秒、`y` 为运行 EWMA 值。
- **副作用：** 无。
- **算法：**
  1. `allData` 为空返回 `[]`。
  2. `tau = halfLifeDays * 86400 * 1000`（毫秒半衰期）。
  3. 播种 `ewma = allData.first.weight`、`prevTime = allData.first.datetime`。
  4. 按时间顺序对每条记录 `r`：计算距 `prevTime` 的已流逝时间 `dtMs`；`alpha = 1 - exp(-dtMs / tau)`（时间自适应平滑因子——记录间更大间隔把 `alpha` 推近 1，更重加权新值）；更新 `ewma = alpha * r.weight + (1 - alpha) * ewma`；`r.datetime` 在 `visibleFrom` 或之后时在更新 `ewma` 处发出点；推进 `prevTime = r.datetime`。
- **用法：**
  ```dart
  final allSorted = List<WeightRecord>.from(_records)
    ..sort((a, b) => a.datetime.compareTo(b.datetime));
  final ewmaSpots = _buildWeightEwmaSpots(allSorted, data.first.datetime);
  ```
  （`_buildChart`，第 834-836 行——`allSorted` 是*整个*记录历史，而 `data.first.datetime` 只是当前所选图表范围起点，因此切换图表范围改变可见窗口而不重启平滑。）
- **备注：** 因为 `alpha` 依赖自上一条记录的实际间隔而非固定每滴答速率，不规则记录间隔（如一周每天、然后两周间隔）被正确处理——长间隔让新值几乎完全支配（`alpha → 1`）而非被稀释得仿佛又一个均匀间隔样本。相同 EWMA 模式（时间自适应 `alpha = 1 - exp(-dt/tau)`）也独立出现在 `lib/features/intimacy/views/intimacy_page.dart`。

### `List<FlSpot> _buildMeasurementEwmaSpots(List<EffectiveWeightMeasurementPoint> allData, DateTime visibleFrom, double? Function(EffectiveWeightMeasurementPoint point) selectValue, {double halfLifeDays = 7})` <a id="_buildmeasurementewmaspots"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1255 行）
- **用途：** 与 `_buildWeightEwmaSpots` 相同的 EWMA 平滑，应用于一个有效测量字段（胸、腰或臀）而非体重，跳过该字段首次继承值前的点。
- **输入：** `allData` — 完整有效测量时间线；`visibleFrom`；`selectValue` — 字段选择器；`halfLifeDays` — 默认 7。
- **返回：** `List<FlSpot>`。
- **副作用：** 无。
- **算法：** 与 `_buildWeightEwmaSpots` 相同的时间自适应 EWMA 递推（`alpha = 1 - exp(-dtMs/tau)`），两个差异：(1) `ewma`/`prevTime` 以 `null` 开始并在 `selectValue(point)` 非 null 的*第一个*点播种（那之前的点经 `continue` 跳过，既不更新也不重置运行平均）；(2) 播种后，null 值点在这里不可能再到达，因为 `effectiveMeasurementTimeline` 已把每个字段出现一次后向前填充——见 [`WeightData.effectiveMeasurementTimeline`](../models/weight_record.md#effectivemeasurementtimeline)。
- **用法：**
  ```dart
  final bustEwmaSpots = _buildMeasurementEwmaSpots(timeline, cutoff, (point) => point.bustCm);
  ```
  （`_buildMeasurementChart`，第 983-997 行，对*完整* `timeline` 每字段调用一次，与 `_buildWeightEwmaSpots` 被喂完整记录历史而非只可见范围的方式平行。）
- **备注：** 除 `_buildWeightEwmaSpots` 备注所述外无。

### `double _weightInterval(double range)` <a id="_weightinterval"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1294 行）
- **用途：** 基于可见体重跨度为体重图挑选可读 y 轴网格/标签间隔（kg）。
- **输入：** `range` — 可见数据上的 `maxWeight - minWeight`。
- **返回：** `double` — `range <= 2` 时 `0.5`；`<= 5` 时 `1`；`<= 10` 时 `2`；否则 `5`。
- **副作用：** 无。
- **算法：** 顺序阈值检查，先匹配胜出。
- **用法：** `horizontalInterval: _weightInterval(maxW - minW)` 和 `interval: _weightInterval(maxW - minW)`（`_buildChart`，第 849 和 882 行，分别供网格线和左轴标签）。
- **备注：** 无。

### `double _measurementInterval(double range)` <a id="_measurementinterval"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1306 行）
- **用途：** 为测量图挑选可读 y 轴间隔（cm），比体重图更稀疏，因为胸/腰/臀跨度通常更大。
- **输入：** `range` — 来自 `_measurementAxisRange` 的 y 轴跨度。
- **返回：** `double` — `range <= 5` 时 `1`；`<= 10` 时 `2`；`<= 25` 时 `5`；否则 `10`。
- **副作用：** 无。
- **算法：** 顺序阈值检查，先匹配胜出。
- **用法：** `horizontalInterval: _measurementInterval(maxY - minY)`（`_buildMeasurementChart`，第 1027 和 1054 行）。
- **备注：** 无。

### `double _dateInterval(List<WeightRecord> data)` <a id="_dateinterval"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1318 行）
- **用途：** 基于可见数据总时间跨度挑选可读 x 轴（日期）标签间隔（毫秒）——从一周跨度的每 3 天到多年跨度的 2 年标签。
- **输入：** `data` — 可见（已范围过滤）记录列表。
- **返回：** `double` — 轴标签间毫秒；少于 2 条记录时 `1`（毫秒，实际"总是标签"）。
- **副作用：** 无。
- **算法：** 从 `data.first`/`data.last` datetime 计算 `spanDays`，然后以天为单位的顺序阈值梯子 → 以天为间隔的毫秒：`≤7→3d, ≤30→10d, ≤90→30d, ≤180→60d, ≤365→120d, ≤730→240d, ≤1825→365d (annual), else→730d (2-year)`。
- **用法：** `interval: _dateInterval(data)`（`_buildChart` 第 865 行、`_buildMeasurementChart` 第 1043 行）——两个图表共享相同日期间隔逻辑，因为它们共享相同 `_chartRecords` 范围。
- **备注：** 无。

### `String? _formatMeasurements(WeightRecord record, AppLocalizations l10n)` <a id="_formatmeasurements"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1503 行）
- **用途：** 把单个历史记录*自己*的（非继承）胸/腰/臀字段格式化为历史行副标题的一个斜杠分隔字符串。
- **输入：** `record`；`l10n`。
- **返回：** `String?` — 三个字段都缺席或非正时 `null`。
- **副作用：** 无。
- **算法：** 构建 `"${label} ${value.toStringAsFixed(1)} cm"` 条目列表，各由 `field != null && field! > 0` 守卫；为空返回 `null`，否则 `parts.join(' / ')`。
- **用法：** `final measurements = _formatMeasurements(record, l10n);`（`_buildRecordTile`，第 1447 行，经 null 感知展开 `?measurements` 拼进副标题行）。
- **备注：** 与 `_latestMeasurementStats`（摘要卡片显示*继承*值）不同，这直接读取记录自己的字段——未记录腰围的记录的历史行简单省略腰围，不显示较早记录的继承值。

### `Future<void> _showReminderSettings()` <a id="_showremindersettings"></a>
- **种类：** `_WeightPageState` 的 async 方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1549 行）
- **用途：** 打开提醒设置底部面板，并拥有决定提醒模式变化时早间/晚间提醒时间发生什么 的模式切换逻辑。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 显示模态底部面板；模式/时间变化时：`setState`，然后 `setSheetState(() {})` 原地重建面板，然后 `_saveData()`。
- **算法：** 面板在 `'none'`/`'once'`/`'twice'` 上渲染 `RadioGroup<String>`。其 `onChanged` 回调是真实逻辑：
  1. `setState(() => _reminderMode = value)`，然后对 `value` 做 `switch`：
     - `'none'` → 清除 `_weightMorningReminder` 和 `_weightEveningReminder` 两者。
     - `'once'` → 设 `_weightMorningReminder ??= 08:00`（只在未设时）并清除 `_weightEveningReminder`。
     - `'twice'` → 设 `_weightMorningReminder ??= 08:00` 和 `_weightEveningReminder ??= 21:00`（都只在未设时）。
  2. `setSheetState({})` 重建面板（使早间/晚间 `ListTile` 立即出现/消失），然后 `_saveData()`。
  3. 早间/晚间 `ListTile.onTap` 处理器分别调用 `showTimePicker`，选了结果后以相同方式 `setState`/`setSheetState`/`_saveData()`。
- **用法：**
  ```dart
  IconButton(
    icon: Icon(_reminderMode != 'none' ? Icons.notifications_active : Icons.notifications_none),
    tooltip: l10n.weightReminder,
    onPressed: _loaded && _loadError == null ? _showReminderSettings : null,
  )
  ```
  （`build`，第 262-272 行，应用栏的提醒铃铛操作。）
- **备注：** 切入 `'once'`/`'twice'` 时用 `??=` 意味着既有早间/晚间时间跨模式切换保留（关掉提醒再打开不把先前选的时间重置回 08:00/21:00 默认）——只有无先前值的字段获得默认。

### `String _formatReminderGraceHours()` <a id="_formatremindergracehours"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1691 行）
- **用途：** 把存储 `_reminderGraceMinutes` 格式化为修剪小时字符串供显示/编辑（精确整数时、否则一位小数）。
- **输入：** 无（读取 `_reminderGraceMinutes`）。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** `hours = _reminderGraceMinutes / 60`；`hours` 已是整数时格式化为整数（`hours.toInt().toString()`）；否则 `hours.toStringAsFixed(1)`。
- **用法：** `TextEditingController(text: _formatReminderGraceHours())`（`_editReminderGrace`，第 1708 行，播种编辑字段）和 `l10n.weightReminderSkipWindowValue(_formatReminderGraceHours())`（`_showReminderSettings`，第 1670 行，设置面板副标题）。
- **备注：** 默认 `_reminderGraceMinutes` 是 180（3 小时），因此这开箱格式化为 `"3"` 而非 `"3.0"`。宽限窗口本身做什么见 [体重](../../../../features/weight.md#reminder-grace-window)。

### `void _saveReminderGrace(BuildContext dialogContext, TextEditingController controller, StateSetter setSheetState)` <a id="_saveremindergrace"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1748 行）
- **用途：** 验证输入小时值，有效时持久化为新 `_reminderGraceMinutes`。
- **输入：** `dialogContext`；`controller` — 持有输入小时文本；`setSheetState` — 父提醒设置面板的重建回调。
- **返回：** 无。
- **副作用：** 弹出 `dialogContext`；`setState`；调用 `setSheetState(() {})`；调用 `_saveData()`。
- **算法：**
  1. 经 `double.tryParse` 解析 `controller.text.trim()`。
  2. 解析失败，或值 `< 0` 或 `> 24` 时，不做任何事地返回（对话框保持打开，不保存任何东西）——这是外层 `_editReminderGrace` 对话框本身不执行的验证。
  3. 否则弹出对话框、`setState(() => _reminderGraceMinutes = (hours * 60).round())`、重建面板并经 `_saveData()` 持久化。
- **用法：**
  ```dart
  FilledButton(
    onPressed: () => _saveReminderGrace(dialogContext, controller, setSheetState),
    child: Text(l10n.commonSave),
  )
  ```
  （`_editReminderGrace`，第 1731-1736 行；也接到字段 `onSubmitted`，第 1723 行。）
- **备注：** 有效范围是硬 `[0, 24]` 小时——输入 `25` 或负数静默让对话框保持打开，除值不被接受外无反馈。

### `Future<void> _addRecord()` <a id="_addrecord"></a>
- **种类：** `_WeightPageState` 的 async 方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1766 行）
- **用途：** 打开添加记录对话框，用户保存新记录时追加进状态并持久化。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 显示 `_WeightRecordDialog`；非 null 结果时 `setState` 追加进 `_records` 并调用 `_saveData()`。
- **算法：** `await showDialog<WeightRecord>`，带 `_WeightRecordDialog(height: _height, lastWeight: _latestRecord?.weight)`（无 `initialRecord`，因此对话框处于添加模式）；对话框返回记录（即未取消/丢弃）时 `setState(() => _records.add(result))` 然后 `await _saveData()`。
- **用法：**
  ```dart
  floatingActionButton: FloatingActionButton(
    onPressed: _loaded && _loadError == null ? _addRecord : null,
    child: const Icon(Icons.add),
  )
  ```
  （`build`，第 287-290 行。）
- **备注：** 把 `_latestRecord?.weight` 作为 `lastWeight` 传入，使对话框能用先前条目预填体重字段（见 `_WeightRecordDialogState.initState`）。

### `Future<void> _editRecord(WeightRecord record)` <a id="_editrecord"></a>
- **种类：** `_WeightPageState` 的 async 方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1785 行）
- **用途：** 为既有记录打开编辑对话框，保存时原地替换并保持其原始 `id`。
- **输入：** `record` — 被编辑的记录。
- **返回：** `Future<void>`。
- **副作用：** 显示 `_WeightRecordDialog`；非 null 结果时 `setState` 替换匹配记录并调用 `_saveData()`。
- **算法：** `await showDialog<WeightRecord>`，带 `_WeightRecordDialog(height: _height, initialRecord: record)`；有结果返回时找 `_records.indexWhere((item) => item.id == record.id)`，找到（`index >= 0`）时覆盖 `_records[index] = result`；然后 `await _saveData()`。
- **用法：** `onTap: () => _editRecord(record)`（`_buildRecordTile`，第 1493 行）。
- **备注：** 对话框自己的 `_submit` 用 `initialRecord?.copyWith(...)`，保留原始 `id` 并重新生成 `modifiedAt`——此方法对 `id` 的 `indexWhere` 匹配依赖它不变。

### `void saveHeight(UnsavedChangesController guard)` <a id="saveheight"></a>
- **种类：** 嵌套在 `_WeightPageState._setHeight` 内的本地函数
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1817 行）
- **用途：** 验证输入身高，有效时持久化并关闭设身高对话框。
- **输入：** `guard` — 外层 `UnsavedChangesGuard` 的 `UnsavedChangesController`。
- **返回：** 无。
- **副作用：** 经 `guard.pop()` 弹出对话框；`setState(() => _height = val)`；调用 `_saveData()`。
- **算法：** 经 `double.tryParse` 解析 `controller.text.trim()`；结果非 null 且 `> 0` 时弹出对话框、更新 `_height` 并保存；否则什么都不做（对话框保持打开）。
- **用法：**
  ```dart
  FilledButton(
    onPressed: () => saveHeight(guard),
    child: Text(l10n.commonSave),
  )
  ```
  （`_setHeight`，第 1850-1853 行；也接到身高字段 `onSubmitted`，第 1842 行。）
- **备注：** 定义在 `_setHeight` 内正为闭包 `controller` 和外层 `context`/`l10n`，而非需要传入它们的 `_WeightPageState` 方法。

### `String _timeSinceLastRecord(DateTime dt, AppLocalizations l10n)` <a id="_timesincelastrecord"></a>
- **种类：** `_WeightPageState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 1865 行）
- **用途：** 把距记录 `datetime` 的已流逝时间格式化为简短相对文本（"今天"、"昨天"、"N 天前"、"N 周前"）。
- **输入：** `dt`；`l10n`。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** `diff = DateTime.now().difference(dt)`；顺序检查：`inDays == 0` → `weightToday`；`== 1` → `weightYesterday`；`< 7` → `"${diff.inDays} ${weightDaysAgo}"`；否则整数除以 7 返回 `"$weeks ${weightWeeksAgo}"`。
- **用法：** `final timeSince = _timeSinceLastRecord(latest.datetime, l10n);`（`_buildContent`，第 342 行，显示在摘要卡片顶部）。
- **备注：** 周总是向下舍入（`~/7`），无"N 个月前"档——10 周前的记录读作 `"10 weeks ago"` 而非切换到基于月的措辞。

### `double? get _previewBMI` <a id="_previewbmi"></a>
- **种类：** `_WeightRecordDialogState` 的 getter
- **来源：** `lib/features/weight/views/weight_page.dart`（第 2151 行）
- **用途：** 从增/改对话框当前正在输入的体重文本计算实时 BMI 预览，用从页面传入的身高。
- **输入：** 无（读取 `_weightController.text` 和 `widget.height`）。
- **返回：** `double?` — 当前体重文本解析不为正数时 `null`，或 `WeightData.calculateBMI` 本身返回 `null`（无身高）。
- **副作用：** 无。
- **算法：** `double.tryParse(_weightController.text.trim())`；对 `null`/`<= 0` 守卫；委托 `WeightData.calculateBMI(widget.height, w)`。
- **用法：**
  ```dart
  final bmi = _previewBMI;
  // ...
  decoration: InputDecoration(
    labelText: l10n.weightKg,
    suffixText: l10n.weightUnitKg,
    helperText: bmi != null ? 'BMI: ${bmi.toStringAsFixed(1)}' : null,
  ),
  ```
  （`build`，第 1967 和 1992-1998 行——显示为体重字段辅助文本，经字段 `onChanged: (_) => setState(() {})` 实时更新。）
- **备注：** 镜像页面状态的 `_currentBMI`，但从进行中文本控制器读取而非最后保存记录，因此每次击键更新而非只在保存后。

### `String _formatInitialMeasurement(double? value)` <a id="_formatinitialmeasurement"></a>
- **种类：** `_WeightRecordDialogState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 2162 行）
- **用途：** 为对话框打开时播种文本控制器格式化持久化测量值，非正值当作缺席。
- **输入：** `value` — 持久化 `bustCm`/`waistCm`/`hipCm`，或 `null`。
- **返回：** `String` — `value` 为 `null` 或 `<= 0` 时 `''`，否则 `value.toStringAsFixed(1)`。
- **副作用：** 无。
- **算法：** 单个守卫子句，然后固定精度格式化。
- **用法：**
  ```dart
  _bustController = TextEditingController(text: _formatInitialMeasurement(record?.bustCm));
  ```
  （`initState`，第 1929-1937 行，胸/腰/臀各一次。）
- **备注：** 与 `_optionalMeasurement`（反向，文本 → 值）对称——两者都把非正当作"未测量"。

### `double? _optionalMeasurement(TextEditingController controller)` <a id="_optionalmeasurement"></a>
- **种类：** `_WeightRecordDialogState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 2172 行）
- **用途：** 解析可选测量字段当前文本，把空、零、负或格式错误输入当作缺席而非错误。
- **输入：** `controller`。
- **返回：** `double?` — 除非解析值 `> 0` 否则 `null`。
- **副作用：** 无。
- **算法：** `double.tryParse(controller.text.trim())`；失败或结果 `<= 0` 返回 `null`；否则返回值。
- **用法：**
  ```dart
  final bustCm = _optionalMeasurement(_bustController);
  final waistCm = _optionalMeasurement(_waistController);
  final hipCm = _optionalMeasurement(_hipController);
  ```
  （`_submit`，第 2187-2189 行。）
- **备注：** 因为零/负/不可解析条目静默变成 `null`（缺席）而非阻塞提交，测量字段没有自己的验证错误状态——无效条目被当作与留空字段相同。

### `void _submit(UnsavedChangesController guard)` <a id="_submit"></a>
- **种类：** `_WeightRecordDialogState` 的方法
- **来源：** `lib/features/weight/views/weight_page.dart`（第 2183 行）
- **用途：** 验证必填体重字段、收集可选测量/备注/日期字段、构建结果 `WeightRecord`（编辑时更新 `initialRecord`，添加时构造新的）并带它弹出对话框。
- **输入：** `guard`。
- **返回：** 无。
- **副作用：** 验证通过时调用 `guard.pop(record)`；否则无。
- **算法：**
  1. 从 `_weightController` 解析 `weight`；`null` 或 `<= 0` 时不弹出地返回（阻塞提交——这是对话框唯一硬验证门）。
  2. 经 `_optionalMeasurement` 解析 `bustCm`/`waistCm`/`hipCm`，`notes` 为修剪备注文本或空时 `null`。
  3. `widget.initialRecord` 非 null（编辑模式）时经 `initialRecord.copyWith(...)` 构建结果，带每个值一起传 `clearBustCm: bustCm == null`（腰/臀/备注类似）——字段要实际被置 null 为何需要显式清除标志见 [`WeightRecord.copyWith`](../models/weight_record.md#copywith)。否则（添加模式）用相同字段直接构造新 `WeightRecord(...)`。
  4. `guard.pop(record)`——弹出对话框并把 `record` 作为 `showDialog` 结果返回。
- **用法：**
  ```dart
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(_isEditing ? l10n.commonSave : l10n.commonAdd),
  )
  ```
  （`build`，第 2094-2097 行；也接到体重字段和备注字段两者的 `onSubmitted`，第 2000 和 2047 行。）
- **备注：** 只有体重字段实际被验证（必须解析为 `> 0`）；测量字段绝不可能阻塞提交，因为 `_optionalMeasurement` 把任何无效条目映射为 `null` 而非浮出错误。

## 相关页面

- [体重](../../../../features/weight.md) — 测量继承、提醒宽限期和 BMI/腰臀比的概念级解释。
- [`WeightRecord`/`WeightData`](../models/weight_record.md) — 本文件调用但不重新实现的模型方法（`calculateBMI`、`calculateWaistHipRatio`、`effectiveMeasurementsUpTo`、`effectiveMeasurementTimeline`、`copyWith`）。
- [`WeightStorage`](../services/weight_storage.md) — `_loadData`/`_saveData` 使用的 `load()`/`save()`。
- [`ReminderService`](../../../shared/services/reminder_service.md) — 读取本文件写入的提醒字段/宽限窗口。
- [`UnsavedChangesGuard`/`formSignature`](../../../shared/widgets/unsaved_changes_guard.md) — `_setHeight` 和 `_WeightRecordDialogState` 使用的脏检查模式。
- [`groupByWeek`/`formatMonthDayRange`](../../../shared/utils/week_grouping.md) — `_buildGroupedRecordTiles`/`_buildWeekHeader` 使用的历史分组。

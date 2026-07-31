# lib/features/intimacy/views/intimacy_page.dart

亲密功能的主视图文件——整个应用迄今为止最大的源文件（5642 行）。它托管主页 `IntimacyPage`（日历、记录列表、趋势图、管理菜单）以及从它到达的每个管理/详情子页：伴侣管理、玩具管理、姿势管理、过滤的逐伴侣/逐玩具详情页（带记录/身体标签）、聚合玩具成本总览，以及跨它们使用的小型共享组件（`_CalendarWidget`、`_RecordTile`、`_DatePickerTile`）。模型来自 `../models/intimacy_record.dart`；存储是 `../services/intimacy_storage.dart`；周期数学是 `../services/cycle_predictor.dart`。完整功能描述见 [亲密](../../../../features/intimacy.md)，磁盘 JSON 形态见 [数据格式](../../../../data-formats.md#intimacy--intimacy_datajson)，这里经 `_buildCycleOverlays` 消费的周期预测细节见 [身体指标](../../../../algorithms/body-metrics.md)。

结构上文件是一个主页（`IntimacyPage` / `_IntimacyPageState`）加十个支撑类，按源码顺序：`_IntimacyDataError`、`_CalendarWidget`、`_RecordTile`、`_PartnerManagementPage`（+ 状态）、`_ToyManagementPage`（+ 状态）、`_PositionManagementPage`（+ 状态）、`_FilteredRecordsPage`（+ 状态）、`_ToyCostOverviewPage`（+ 状态）、`_ToyCostTrendData` 和 `_DatePickerTile`。伴侣和玩具管理状态是近乎镜像的实现（自定义排序/重排、激活/非激活或激活/退役分组）。

截至 v1.3.2，记录指标趋势图不再住在这里。主页的两个图表和 `_FilteredRecordsTrendSection` 的两个近乎逐字副本被单个 [`IntimacyTrendChart`](../widgets/intimacy_trend_chart.md) 组件取代，两个表面现在都嵌入它；27 个声明（点构建器、吸附辅助、图例项、日期间隔辅助和整个 `_FilteredRecordsTrendSection` 对）被删除，`_saveChartSettings` 被添加以持久化图表的共享选择。`_ToyCostOverviewPage` 上的玩具每日成本趋势图留在这里——它在对数刻度上把金额绘制在投影日期时间线上——并且现在共享图表组件导出的公共 `IntimacyChartRange` 枚举，而不是私有重复。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `IntimacyPage.new` | 构造函数 | B | 平凡转发构造函数。 |
| `IntimacyPage.createState` | 方法（`IntimacyPage`） | B | 创建 `_IntimacyPageState`。 |
| `_IntimacyPageState.initState` | 方法（生命周期） | B | 加载数据并注册自动同步监听器。 |
| `_IntimacyPageState.dispose` | 方法（生命周期） | B | 注销自动同步监听器。 |
| [`_loadData`](#loaddata) | 方法（`_IntimacyPageState`） | A | 把 `intimacy_data.json` 加载进状态，或浮出阻塞读取错误。 |
| [`_saveData`](#savedata) | 方法（`_IntimacyPageState`） | A | 把当前状态持久化到存储并通知自动同步，除非加载中或不可读。 |
| [`_saveTimerState`](#savetimerstate) | 方法（`_IntimacyPageState`） | A | 持久化从打开 `TimerPage` 流回的计时器历史/会话变更。 |
| [`_saveChartSettings`](#savechartsettings) | 方法（`_IntimacyPageState`） | A | 持久化任何 `IntimacyTrendChart` 上报的新趋势图指标和范围选择。 |
| `_markedDates` | getter（`_IntimacyPageState`） | B | 至少有一条记录的日历日集合。 |
| [`_buildCycleOverlays`](#buildcycleoverlays) | 方法（`_IntimacyPageState`） | A | 构建主页日历显示的逐人周期叠加列表。 |
| `_buildCycleCalendarExtras` | 方法（组件辅助） | B | 渲染日历下方的周期图例和所选日周期条。 |
| [`_filteredRecords`](#filteredrecords-main) | getter（`_IntimacyPageState`） | A | 对记录列表应用所选日期、类型和排序过滤器。 |
| [`_addRecord`](#addrecord-main) | 方法（`_IntimacyPageState`） | A | 打开添加记录对话框（仅激活伴侣/玩具）并持久化结果。 |
| [`_deleteRecord`](#deleterecord-main) | 方法（`_IntimacyPageState`） | A | 按 id 移除记录并持久化。 |
| [`_editRecord`](#editrecord-main) | 方法（`_IntimacyPageState`） | A | 打开编辑记录对话框并持久化更新记录。 |
| `_IntimacyPageState.build` | 方法（组件） | B | 构建主页：日历、图表小节和记录列表/摘要。 |
| `_showAllRecords` | 方法（组件辅助） | B | 在模态底部面板显示完整过滤记录列表。 |
| `_buildRecordListWidgets` | 方法（组件辅助） | B | 构建周分组记录列表组件（主页）。 |
| `_buildWeekHeader` | 方法（组件辅助） | B | 构建 ISO 周组页头行（主页）。 |
| `_buildRecordDismissible` | 方法（组件辅助） | B | 构建滑动删除记录行（主页）。 |
| `_buildSortChip` | 方法（组件辅助） | B | 构建排序模式 chip/菜单。 |
| `_buildFilterChip` | 方法（组件辅助） | B | 构建过滤模式 chip/菜单。 |
| `_showManageMenu` | 方法（组件辅助） | B | 显示底部面板管理菜单（身体/伴侣/玩具/姿势）。 |
| `_openBodySettings` | 方法（组件辅助） | B | 压入 `BodySettingsPage` 并在返回时持久化任何用户身体变更。 |
| `_openPartnerManagement` | 方法（组件辅助） | B | 压入 `_PartnerManagementPage` 并在返回时持久化变更。 |
| `_openToyManagement` | 方法（组件辅助） | B | 压入 `_ToyManagementPage` 并在返回时持久化变更。 |
| `_openPositionManagement` | 方法（组件辅助） | B | 压入 `_PositionManagementPage` 并在返回时持久化变更。 |
| `_IntimacyDataError.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_IntimacyDataError.build` | 方法（组件） | B | 渲染阻塞"数据不可读"恢复视图。 |
| `_CalendarWidget.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_CalendarWidget.build` | 方法（组件） | B | 渲染月网格、页头和星期标签。 |
| `_buildDayGrid` | 方法（组件辅助） | B | 构建日历的日数字网格。 |
| `_isSameDay` | 方法（`_CalendarWidget`） | B | 忽略日内时间比较两个日期。 |
| `_RecordTile.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_RecordTile.build` | 方法（组件） | B | 渲染一条记录的摘要块（伴侣/玩具/姿势/标志）。 |
| `_PartnerManagementPage.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_PartnerManagementPage.createState` | 方法（`_PartnerManagementPage`） | B | 创建 `_PartnerManagementPageState`。 |
| `_PartnerManagementPageState.initState` | 方法（生命周期） | B | 把传入伴侣/排序状态复制进本地可变字段。 |
| `_notifySort` | 方法（`_PartnerManagementPageState`） | B | 把当前排序模式/自定义顺序转发给父回调。 |
| `_statusKey` | 方法（`_PartnerManagementPageState`） | B | 把激活/非激活标志映射到其排序状态映射键。 |
| `_sortMode` | 方法（`_PartnerManagementPageState`） | B | 查找状态组的活动排序模式。 |
| `_compareText` | 方法（`_PartnerManagementPageState`） | B | 不区分大小写字符串比较器。 |
| [`_compareNullableDates`](#comparenullabledates-partner) | 方法（`_PartnerManagementPageState`） | A | 可空容忍日期比较器（null 排最后）。 |
| `_partnerRecordCount` | 方法（`_PartnerManagementPageState`） | B | 统计引用伴侣 id 的记录。 |
| [`_normalizedOrder`](#normalizedorder-partner) | 方法（`_PartnerManagementPageState`） | A | 调和存储自定义顺序与当前伴侣 id 集合。 |
| [`_sortPartners`](#sortpartners) | 方法（`_PartnerManagementPageState`） | A | 按日期、记录数、名称或自定义顺序排序伴侣列表。 |
| [`_setSortMode`](#setsortmode-partner) | 方法（`_PartnerManagementPageState`） | A | 切换状态组的排序模式，首次使用时播种自定义顺序。 |
| [`_appendPartnerToCustomOrderIfNeeded`](#appendpartnertocustomorderifneeded) | 方法（`_PartnerManagementPageState`） | A | 该组使用自定义排序时把伴侣加进其组自定义顺序。 |
| [`_removePartnerFromCustomOrders`](#removepartnerfromcustomorders) | 方法（`_PartnerManagementPageState`） | A | 从每个存储自定义顺序列表移除伴侣 id。 |
| [`_reorderPartners`](#reorderpartners) | 方法（`_PartnerManagementPageState`） | A | 对状态组的自定义顺序应用拖拽重排手势。 |
| `_addPartner` | 方法（`_PartnerManagementPageState`） | B | 转发给 `_showEditDialog(null)`。 |
| `_editPartner` | 方法（`_PartnerManagementPageState`） | B | 转发给 `_showEditDialog(p)`。 |
| [`_deletePartner`](#deletepartner) | 方法（`_PartnerManagementPageState`） | A | 删除伴侣及其周期记录；活动记录保留其悬空 id。 |
| [`_breakUpPartner`](#breakuppartner) | 方法（`_PartnerManagementPageState`） | A | 标记伴侣分手：设置 `endDate`、禁用其日历周期叠加、重新排序进非激活。 |
| `_showPartnerRecords` | 方法（组件辅助） | B | 压入限定一个伴侣的 `_FilteredRecordsPage`。 |
| `_showEditDialog`（伴侣） | 方法（组件辅助 / 对话框） | B | 构建并驱动增/改伴侣对话框（名称、emoji、图像、日期、身体）。 |
| `signature`（伴侣对话框） | 本地函数（`_showEditDialog` 内） | B | 为伴侣表单计算变更检测签名。 |
| `_buildImageRow`（伴侣） | 方法（组件辅助） | B | 构建 emoji/图像选择器行（伴侣对话框）。 |
| `_partnerSubtitle` | 方法（`_PartnerManagementPageState`） | B | 组合伴侣块副标题（记录数 + 日期范围）。 |
| `fmt`（伴侣副标题） | 本地函数（`_partnerSubtitle` 内） | B | 把日期格式化为 `yyyy-MM-dd`。 |
| `_activePartners` | getter（`_PartnerManagementPageState`） | B | 无结束日期的排序伴侣列表。 |
| `_inactivePartners` | getter（`_PartnerManagementPageState`） | B | 有结束日期的排序伴侣列表。 |
| `_PartnerManagementPageState.build` | 方法（组件） | B | 渲染伴侣管理页（激活/非激活小节）。 |
| `_buildPartnerSection` | 方法（组件辅助） | B | 构建一个状态小节（页头 + 块列表或重排列表）。 |
| `_buildManagedSectionHeader`（伴侣） | 方法（组件辅助） | B | 构建带计数和排序模式菜单按钮的小节页头。 |
| `_managedSortItem`（伴侣） | 方法（组件辅助） | B | 构建一个排序模式弹出菜单条目。 |
| `_buildPartnerReorderList` | 方法（组件辅助） | B | 构建自定义排序模式使用的 `ReorderableListView`。 |
| `_buildPartnerTile` | 方法（组件辅助） | B | 构建一个伴侣的列表块（头像、副标题、操作）。 |
| `_buildPartnerAvatar` | 方法（组件辅助） | B | 构建伴侣头像（图像、emoji 或首字母）。 |
| `_ToyManagementPage.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_ToyManagementPage.createState` | 方法（`_ToyManagementPage`） | B | 创建 `_ToyManagementPageState`。 |
| `_ToyManagementPageState.initState` | 方法（生命周期） | B | 把传入玩具/排序状态复制进本地可变字段。 |
| `_notifySort`（玩具） | 方法（`_ToyManagementPageState`） | B | 把当前排序模式/自定义顺序转发给父回调。 |
| `_statusKey`（玩具） | 方法（`_ToyManagementPageState`） | B | 把退役标志映射到其排序状态映射键。 |
| `_sortMode`（玩具） | 方法（`_ToyManagementPageState`） | B | 查找状态组的活动排序模式。 |
| `_compareText`（玩具） | 方法（`_ToyManagementPageState`） | B | 不区分大小写字符串比较器。 |
| [`_compareNullableDates`](#comparenullabledates-toy) | 方法（`_ToyManagementPageState`） | A | 可空容忍日期比较器（null 排最后）。 |
| `_toyRecordCount` | 方法（`_ToyManagementPageState`） | B | 统计引用玩具 id 的记录。 |
| `_formatMoney`（玩具管理） | 方法（`_ToyManagementPageState`） | B | 格式化普通美元金额。 |
| [`_totalToyCost`](#totaltoycost) | 方法（`_ToyManagementPageState`） | A | 对玩具列表求和 `Toy.totalCost()`。 |
| [`_totalDailyToyCost`](#totaldailytoycost) | 方法（`_ToyManagementPageState`） | A | 对玩具列表求和 `Toy.averageDailyCost()`，无成本可算则为 null。 |
| [`_normalizedOrder`](#normalizedorder-toy) | 方法（`_ToyManagementPageState`） | A | 调和存储自定义顺序与当前玩具 id 集合。 |
| [`_sortToys`](#sorttoys) | 方法（`_ToyManagementPageState`） | A | 按日期、记录数、名称或自定义顺序排序玩具列表。 |
| [`_setSortMode`](#setsortmode-toy) | 方法（`_ToyManagementPageState`） | A | 切换状态组的排序模式，首次使用时播种自定义顺序。 |
| [`_appendToyToCustomOrderIfNeeded`](#appendtoytocustomorderifneeded) | 方法（`_ToyManagementPageState`） | A | 该组使用自定义排序时把玩具加进其组自定义顺序。 |
| [`_removeToyFromCustomOrders`](#removetoyfromcustomorders) | 方法（`_ToyManagementPageState`） | A | 从每个存储自定义顺序列表移除玩具 id。 |
| [`_reorderToys`](#reordertoys) | 方法（`_ToyManagementPageState`） | A | 对状态组的自定义顺序应用拖拽重排手势。 |
| `_addToy` | 方法（`_ToyManagementPageState`） | B | 转发给 `_showEditDialog(null)`。 |
| `_editToy` | 方法（`_ToyManagementPageState`） | B | 转发给 `_showEditDialog(t)`。 |
| [`_deleteToy`](#deletetoy) | 方法（`_ToyManagementPageState`） | A | 删除玩具、清理其自定义顺序条目并通知父级。 |
| [`_retireToy`](#retiretoy) | 方法（`_ToyManagementPageState`） | A | 标记玩具退役（设置 `retiredDate`，重新排序进退役组）。 |
| `_showToyRecords` | 方法（组件辅助） | B | 压入限定一个玩具的 `_FilteredRecordsPage`。 |
| `_showToyCostOverview` | 方法（组件辅助） | B | 压入 `_ToyCostOverviewPage`。 |
| `_showEditDialog`（玩具） | 方法（组件辅助 / 对话框） | B | 构建并驱动增/改玩具对话框（名称、链接、价格、日期、图像）。 |
| `signature`（玩具对话框） | 本地函数（`_showEditDialog` 内） | B | 为玩具表单计算变更检测签名。 |
| `_buildImageRow`（玩具） | 方法（组件辅助） | B | 构建 emoji/图像选择器行（玩具对话框）。 |
| `_toySubtitle` | 方法（`_ToyManagementPageState`） | B | 组合玩具块副标题（记录数 + 购买/退役日期）。 |
| `fmt`（玩具副标题，购买） | 本地函数（`_toySubtitle` 内） | B | 把购买日期格式化为 `yyyy-MM-dd`。 |
| `fmt`（玩具副标题，退役） | 本地函数（`_toySubtitle` 内） | B | 把退役日期格式化为 `yyyy-MM-dd`。 |
| `_activeToys` | getter（`_ToyManagementPageState`） | B | 无退役日期的排序玩具列表。 |
| `_retiredToys` | getter（`_ToyManagementPageState`） | B | 有退役日期的排序玩具列表。 |
| `_ToyManagementPageState.build` | 方法（组件） | B | 渲染玩具管理页（激活/退役小节 + 成本摘要）。 |
| `_buildActiveCostSummary` | 方法（组件辅助） | B | 渲染激活玩具总/每日成本摘要条目。 |
| `_buildCostMetric`（玩具管理） | 方法（组件辅助） | B | 构建紧凑带标签成本指标列。 |
| `_buildToySection` | 方法（组件辅助） | B | 构建一个状态小节（页头 + 块列表或重排列表）。 |
| `_buildManagedSectionHeader`（玩具） | 方法（组件辅助） | B | 构建带计数和排序模式菜单按钮的小节页头。 |
| `_managedSortItem`（玩具） | 方法（组件辅助） | B | 构建一个排序模式弹出菜单条目。 |
| `_buildToyReorderList` | 方法（组件辅助） | B | 构建自定义排序模式使用的 `ReorderableListView`。 |
| `_buildToyTile` | 方法（组件辅助） | B | 构建一个玩具的列表块（头像、副标题、操作）。 |
| `_buildToyAvatar` | 方法（组件辅助） | B | 构建玩具头像（图像、emoji 或首字母）。 |
| `_PositionManagementPage.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_PositionManagementPage.createState` | 方法（`_PositionManagementPage`） | B | 创建 `_PositionManagementPageState`。 |
| `_PositionManagementPageState.initState` | 方法（生命周期） | B | 把传入姿势复制进本地可变字段。 |
| `_addPosition` | 方法（`_PositionManagementPageState`） | B | 转发给 `_showEditDialog(null)`。 |
| `_editPosition` | 方法（`_PositionManagementPageState`） | B | 转发给 `_showEditDialog(p)`。 |
| `_deletePosition` | 方法（`_PositionManagementPageState`） | B | 按 id 移除姿势并通知父级。 |
| [`_importDefaults`](#importdefaults) | 方法（`_PositionManagementPageState`） | A | 添加按名称尚不存在的内置默认姿势预设。 |
| `_showEditDialog`（姿势） | 方法（组件辅助 / 对话框） | B | 构建并驱动增/改姿势对话框（名称、emoji）。 |
| `signature`（姿势对话框） | 本地函数（`_showEditDialog` 内） | B | 为姿势表单计算变更检测签名。 |
| `_PositionManagementPageState.build` | 方法（组件） | B | 渲染姿势管理页和导入默认值菜单操作。 |
| `_FilteredRecordsPage.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_FilteredRecordsPage.createState` | 方法（`_FilteredRecordsPage`） | B | 创建 `_FilteredRecordsPageState`。 |
| `_FilteredRecordsPageState.initState` | 方法（生命周期） | B | 把传入记录复制进本地可变字段。 |
| `_FilteredRecordsPageState.didUpdateWidget` | 方法（生命周期） | B | 父级提供替换列表时刷新本地记录副本。 |
| `_hasBodyTab` | getter（`_FilteredRecordsPageState`） | B | 此详情页是否应显示伴侣记录/身体标签。 |
| [`_filteredRecords`](#filteredrecords-filtered) | getter（`_FilteredRecordsPageState`） | A | 匹配本页伴侣或玩具过滤的记录，最新优先。 |
| `_selectedToy` | getter（`_FilteredRecordsPageState`） | B | 此详情页限定到的 `Toy`（如有）。 |
| [`_dialogPartners`](#dialogpartners) | 方法（`_FilteredRecordsPageState`） | A | 为增/改记录对话框构建伴侣选择器列表。 |
| [`_dialogToys`](#dialogtoys) | 方法（`_FilteredRecordsPageState`） | A | 为增/改记录对话框构建玩具选择器列表。 |
| `_notifyRecordsChanged` | 方法（`_FilteredRecordsPageState`） | B | 把本地记录列表副本转发给父回调。 |
| [`_addRecord`](#addrecord-filtered) | 方法（`_FilteredRecordsPageState`） | A | 打开预选当前伴侣/玩具的添加记录对话框。 |
| [`_editRecord`](#editrecord-filtered) | 方法（`_FilteredRecordsPageState`） | A | 为一条记录打开编辑记录对话框并更新本地状态。 |
| [`_deleteRecord`](#deleterecord-filtered) | 方法（`_FilteredRecordsPageState`） | A | 按 id 从本地状态移除记录并通知父级。 |
| [`_formatDuration`](#formatduration) | 方法（`_FilteredRecordsPageState`） | A | 把时长格式化为 `Xh Ym` 或 `Ym`。 |
| `_formatMoney`（过滤页） | 方法（`_FilteredRecordsPageState`） | B | 格式化普通美元金额。 |
| `_buildSummaryCard`（过滤页） | 方法（组件辅助） | B | 构建顶部摘要卡片（平均值，玩具加成本指标）。 |
| `_buildSummaryMetric` | 方法（组件辅助） | B | 在摘要卡片内构建一个带标签指标列。 |
| `_buildRecordDismissible`（过滤页） | 方法（组件辅助） | B | 构建滑动删除记录行（过滤页）。 |
| `_buildRecordListWidgets`（过滤页） | 方法（组件辅助） | B | 构建周分组记录列表组件（过滤页）。 |
| `_buildWeekHeader`（过滤页） | 方法（组件辅助） | B | 构建 ISO 周组页头行（过滤页）。 |
| `_FilteredRecordsPageState.build` | 方法（组件） | B | 渲染普通布局或伴侣记录/身体标签布局。 |
| `_buildRecordsListView` | 方法（组件辅助） | B | 构建共享摘要/趋势/记录列表滚动视图。 |
| `_buildBodyTab` | 方法（组件辅助） | B | 渲染托管共享 `BodySectionView` 的伴侣身体标签。 |
| `_ToyCostOverviewPage.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_ToyCostOverviewPage.createState` | 方法（`_ToyCostOverviewPage`） | B | 创建 `_ToyCostOverviewPageState`。 |
| `_selectedToys` | getter（`_ToyCostOverviewPageState`） | B | 当前全部/激活/退役范围内包含的玩具。 |
| `_ToyCostOverviewPageState.build` | 方法（组件） | B | 渲染范围选择器、摘要卡片和趋势/最终成本卡片。 |
| `_buildScopeSelector` | 方法（组件辅助） | B | 构建全部/激活/退役 `SegmentedButton`。 |
| `_buildSummaryCard`（成本总览） | 方法（组件辅助） | B | 构建当前范围的聚合成本摘要卡片。 |
| `_buildCostMetric`（成本总览） | 方法（组件辅助） | B | 构建紧凑带标签聚合成本指标列。 |
| `_buildFinalizedCostNote` | 方法（组件辅助） | B | 构建"退役成本已最终确定"说明卡片。 |
| `_buildTrendCard` | 方法（组件辅助） | B | 构建聚合每日成本趋势卡片（激活/全部范围）。 |
| `_buildCostChart` | 方法（组件辅助） | B | 构建对数刻度聚合每日成本折线图。 |
| `_legendLine`（成本总览） | 方法（组件辅助） | B | 构建实线/虚线图例标记。 |
| [`_buildTrendData`](#buildtrenddata) | 方法（`_ToyCostOverviewPageState`） | A | 为采样时间线构建历史/未来每日成本点和 y 边界。 |
| [`_dailyCostAt`](#dailycostat) | 方法（`_ToyCostOverviewPageState`） | A | 在某一天求和每个包含玩具的每日成本。 |
| [`_toyDailyCostAt`](#toydailycostat) | 方法（`_ToyCostOverviewPageState`） | A | 计算一个玩具截至某一天的平均每日成本。 |
| [`_historyStart`](#historystart) | 方法（`_ToyCostOverviewPageState`） | A | 返回所选图表范围显示的第一个日期。 |
| [`_futureEnd`](#futureend) | 方法（`_ToyCostOverviewPageState`） | A | 返回所选图表范围的投影结束日期。 |
| [`_earliestPurchaseDate`](#earliestpurchasedate) | 方法（`_ToyCostOverviewPageState`） | A | 返回玩具列表中最晚购买日期。 |
| [`_timeline`](#timeline) | 方法（`_ToyCostOverviewPageState`） | A | 构建成本趋势图上绘制的采样日期列表。 |
| [`_dateOnly`](#dateonly) | 方法（`_ToyCostOverviewPageState`） | A | 从 `DateTime` 剥离日内时间分量。 |
| [`_chartBounds`](#chartbounds) | 方法（`_ToyCostOverviewPageState`） | A | 填充 y 轴边界，使平坦/零成本图表保持可见。 |
| [`_logTransform`](#logtransform) | 方法（`_ToyCostOverviewPageState`） | A | 把成本值映射到带符号 log10 刻度供图表化。 |
| [`_logInverse`](#loginverse) | 方法（`_ToyCostOverviewPageState`） | A | 为轴标签和工具提示反转 `_logTransform`。 |
| [`_dateInterval`](#dateinterval) | 方法（`_ToyCostOverviewPageState`） | A | 为给定 x 范围返回底部轴日期标签间隔。 |
| [`_dateLabel`](#datelabel) | 方法（`_ToyCostOverviewPageState`） | A | 格式化图表日期轴标签，精度缩放到 x 范围跨度。 |
| `_moneyText` | 方法（`_ToyCostOverviewPageState`） | B | 为工具提示格式化普通美元金额。 |
| [`_axisText`](#axistext) | 方法（`_ToyCostOverviewPageState`） | A | 紧凑格式化 y 轴值（`k`/`m` 后缀）。 |
| [`_totalCost`](#totalcost) | 方法（`_ToyCostOverviewPageState`） | A | 对玩具列表求和 `Toy.totalCost()`。 |
| [`_totalDailyCost`](#totaldailycost) | 方法（`_ToyCostOverviewPageState`） | A | 对玩具列表求和 `Toy.averageDailyCost()`，无成本可算则为 null。 |
| `_scopeLabel` | 方法（`_ToyCostOverviewPageState`） | B | 返回全部/激活/退役范围的本地化标签。 |
| `_ToyCostTrendData.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_DatePickerTile.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_DatePickerTile.build` | 方法（组件） | B | 渲染带标签可点击日期字段。 |

**行数对账：** 上面 175 行，与 `grep -c '/// Purpose:'` = 175 精确匹配（53 个 Tier A、122 个 Tier B）。v1.3.2 在记录指标图移入 [`intimacy_trend_chart.dart`](../widgets/intimacy_trend_chart.md) 时移除了 27 行（17 个 Tier A、10 个 Tier B），并添加了一个（`_saveChartSettings`，Tier A）。重名声明（同一辅助名在多个类中重新实现，如 `_IntimacyPageState` 和 `_FilteredRecordsPageState` 中都有 `_filteredRecords`）如何在锚点中消歧见本页末尾说明。

## 文档

### `Future<void> _loadData()` <a id="loaddata"></a>
- **种类：** `_IntimacyPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 172 行）
- **用途：** 把 `intimacy_data.json` 加载进页面状态，或记录阻塞读取错误。
- **输入：** 无（读取 `IntimacyStorage.load()`）。
- **返回：** `Future<void>`。
- **副作用：** 重载期间设 `_loaded = false`（已加载且 mounted 时），然后经 `setState` 填充每个亲密字段（`_partners`、`_toys`、`_positions`、`_records`、计时器历史/会话、用户身体、周期记录、保留、排序模式/自定义顺序、`_settingsModifiedAt`）。
- **算法：**
  1. 已加载且仍 mounted 时，先把 `_loaded` 翻转为 `false`，使 UI 能在重载期间显示加载/过期状态。
  2. 调用 `IntimacyStorage.load()`；异常时把 `e.toString()` 存进 `_loadError`、设 `_loaded = true` 并返回——不可读文件浮出为错误，绝不静默当作空数据。
  3. 成功时清除 `_loadError` 并把加载的 `IntimacyData` 的每个字段复制出来（周期记录和自定义顺序的防御性列表/映射复制，使页面自有集合可变）。
  4. 在 `setState` 块末尾无条件设 `_loaded = true`。
- **用法：**
  ```dart
  @override
  void initState() {
    super.initState();
    _loadData();
    AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  }
  ```
- **备注：** 注册为自动同步"本地数据变更"回调，因此后台同步拉取自动重载此页面的内存状态。

### `Future<void> _saveData()` <a id="savedata"></a>
- **种类：** `_IntimacyPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 220 行）
- **用途：** 把当前内存亲密状态持久化到磁盘并通知自动同步。
- **输入：** 无（读取所有 `_IntimacyPageState` 字段）。
- **返回：** `Future<void>`。
- **副作用：** 经 `IntimacyStorage.save` 写 `intimacy_data.json`；调用 `AutoSyncService.instance.notifySaved()`；可能显示 snackbar。
- **算法：**
  1. `!_loaded` 时立即返回（绝不用部分加载状态覆盖存储）。
  2. `_loadError != null` 时显示 `intimacyDataWriteBlocked` snackbar 并返回——文件已知不可读时拒绝写入，使损坏文件绝不被不完整内存重建静默替换。
  3. 否则从每个字段构建新鲜 `IntimacyData` 并调用 `IntimacyStorage.save`。
  4. 调用 `AutoSyncService.instance.notifySaved()` 安排同步推送。
- **用法：**
  ```dart
  void _deleteRecord(IntimacyRecord record) {
    setState(() => _records.removeWhere((r) => r.id == record.id));
    _saveData();
  }
  ```
- **备注：** 主页上每个变更操作（`_addRecord`、`_editRecord`、`_deleteRecord`、`_openPartnerManagement`/`_openToyManagement`/`_openPositionManagement` 返回、身体/计时器设置）都汇入这一条保存路径。

### `Future<void> _saveTimerState({required List<TimerHistoryEntry> history, required IntimacyTimerSession? session, required bool historyChanged, required bool timerSessionChanged, required int? retentionDays, required bool retentionChanged})` <a id="savetimerstate"></a>
- **种类：** `_IntimacyPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 262 行）
- **用途：** 持久化从仍打开的 `TimerPage` 流回的计时器历史/会话/保留变更。
- **输入：** `history`、`session`、`retentionDays`，加三个告诉哪些实际变化的 `bool` 标志。
- **返回：** `Future<void>`。
- **副作用：** 经 `setState` 更新 `_timerHistory`、`_timerSession`、`_timerHistoryRetentionDays`（并有条件地 `_timerSessionModifiedAt`/`_settingsModifiedAt`）；有变化时调用 `_saveData()`。
- **算法：**
  1. 无条件 `setState` 三个原始值。
  2. `timerSessionChanged` 时才把 `_timerSessionModifiedAt` bump 到 `DateTime.now().toUtc()`——计时器会话有自己独立于通用设置的最后写入者胜出时间戳。
  3. `retentionChanged` 时才 bump `_settingsModifiedAt`。
  4. 历史、会话或保留变化时才调用 `_saveData()`——无实际变化的回调不执行写入。
- **用法：** 作为 `onStateChanged` 风格回调从 `_showManageMenu`/`build()` 别处的计时器入口传给 `TimerPage`；`TimerPage` 在每次计时器滴答/暂停/保存时调用它，使父页面存储在计时器 UI 打开时保持同步。
- **备注：** 让计时器会话自己的修改时间戳独立于 `_settingsModifiedAt` 对三方合并重要——见 [计时器/秒表会话持久化](../../../../features/intimacy.md#timerstopwatch-session-persistence)。

### `Future<void> _saveChartSettings(IntimacyChartSettings settings)` <a id="savechartsettings"></a>
- **种类：** `_IntimacyPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 257 行）
- **用途：** 持久化新趋势图指标和范围选择。
- **输入：** `settings` — `IntimacyTrendChart` 上报的完整新选择。
- **返回：** `Future<void>`。
- **副作用：** 经 `setState` 更新 `_chartSettings` 和 `_settingsModifiedAt`，然后调用写 `intimacy_data.json` 并通知自动同步的 `_saveData()`。
- **算法：**
  1. `setState` 新设置并用 `DateTime.now().toUtc()` 盖章 `_settingsModifiedAt`。
  2. `await _saveData()`。
- **用法：** 作为 `onSettingsChanged` 传给主页 `IntimacyTrendChart`，并作为 `onChartSettingsChanged` 经 `_PartnerManagementPage`/`_ToyManagementPage` 穿到 `_FilteredRecordsPage`，使图表的每个副本都经这一个方法写入。
- **备注：** 选择加入模块的 `settingsModifiedAt` 最后写入者胜出组，这正是时间戳在这里而不是 `_saveData()` 内被 bump 的原因。把每个表面的写入都经主页状态路由避免了 `intimacy_data.json` 的第二个写入者——见 [整合趋势图](../../../../features/intimacy.md#the-consolidated-trend-chart-v132)。

### `List<PersonCycleOverlay> _buildCycleOverlays(AppLocalizations l10n)` <a id="buildcycleoverlays"></a>
- **种类：** `_IntimacyPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 303 行）
- **用途：** 构建主页日历显示的逐人周期叠加列表。
- **输入：** `l10n`（用于用户自己的显示标签）。
- **返回：** `List<PersonCycleOverlay>` — 每个合格人一个条目（用户先，然后伴侣），各携带 `_focusedMonth` 周围两个月窗口的 `CyclePrediction`。
- **副作用：** 无（从 `_userBody`、`_partners`、`_cycleRecords` 纯派生）。
- **算法：**
  1. 计算跨 `_focusedMonth` 前一个月到后一个月的 `windowStart`/`windowEnd`。
  2. 定义在该人窗口内周期记录开始日上调用 `predictCycle` 的本地 `predictionFor(personId)`。
  3. `_userBody != null && cycleEnabled && showCycleOnCalendar` 时才包含用户。
  4. 对每个伴侣，`partner.body` 非 null 且 `cycleEnabled` 和 `showCycleOnCalendar` 都为 true 时才包含；其他完全跳过（即使有周期数据也绝不出现于共享日历）。
  5. 经 `cyclePersonColor` 为每个包含的人分配稳定调色板颜色（用户 = 槽 0，伴侣按其在完整排序伴侣 id 列表中的 id 位置键控，使无关伴侣被添加时颜色不移动）。
- **用法：**
  ```dart
  cycleOverlays: _buildCycleOverlays(l10n),
  ..._buildCycleCalendarExtras(theme, l10n),
  ```
- **备注：** 周期预测本身（月经/生育窗口/排卵/阶段）是 `services/cycle_predictor.dart` 的 `predictCycle`，在 [身体指标 § 周期预测](../../../../algorithms/body-metrics.md#cycle-prediction) 中记录；此方法只决定*谁*出现和*什么颜色*。

### `List<IntimacyRecord> get _filteredRecords`（`_IntimacyPageState` 中） <a id="filteredrecords-main"></a>
- **种类：** `_IntimacyPageState` 的 getter
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 421 行）
- **用途：** 对完整记录列表应用所选日历日期、类型过滤器和排序模式供主页显示。
- **输入：** 无（读取 `_records`、`_selectedDate`、`_filterMode`、`_sortMode`）。
- **返回：** `List<IntimacyRecord>` — 新的过滤/排序列表；`_records` 本身不动。
- **副作用：** 无。
- **算法：**
  1. 从 `_records` 副本开始。
  2. 选了日历日期时，只保留 `datetime` 落在那个确切年/月/日的记录。
  3. 把 `_filterMode`（`solo`/`partnered`/`orgasm`/`noOrgasm`/`all`）作为对 `isSolo`/`hadOrgasm` 的 `where` 谓词应用。
  4. 把 `_sortMode`（`dateDesc`/`dateAsc`/`pleasureDesc`/`durationDesc`）作为原地 `sort` 应用。
  5. 返回结果。
- **用法：**
  ```dart
  final filteredRecords = _filteredRecords;
  // ... and separately:
  final records = _filteredRecords; // used by _showAllRecords
  ```
- **备注：** 日期过滤和类型过滤组合（两者一起应用）；排序总是最后运行，使它应用于过滤后存活的任何子集。

### `Future<void> _addRecord()`（`_IntimacyPageState` 中） <a id="addrecord-main"></a>
- **种类：** `_IntimacyPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 468 行）
- **用途：** 打开只提供激活伴侣/玩具的添加记录对话框，并持久化结果。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 显示 `AddRecordDialog`；非 null 结果时经 `setState` 插入 `_records` 并调用 `_saveData()`。
- **算法：**
  1. 计算 `activePartners`（无 `endDate`）和 `activeToys`（无 `retiredDate`），使分手伴侣和退役玩具不被提供给*新*记录。
  2. Await 带 `AddRecordDialog` 的 `showDialog<IntimacyRecord>`。
  3. 对话框返回记录时 `setState` 添加它，然后 `_saveData()`。
- **用法：** 接到 `build()` 中主页的浮动添加按钮。
- **备注：** 与 `_editRecord` 对照，后者必须仍让*既有*记录保留对非激活伴侣/玩具的引用——见 [`_editRecord`](#editrecord-main) 下的已删除伴侣容忍说明。

### `void _deleteRecord(IntimacyRecord record)`（`_IntimacyPageState` 中） <a id="deleterecord-main"></a>
- **种类：** `_IntimacyPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 490 行）
- **用途：** 按 id 移除一条记录并持久化。
- **输入：** `record` — 要删除的记录（按 id 匹配）。
- **返回：** 无。
- **副作用：** `setState` 从 `_records` 移除匹配记录；调用 `_saveData()`。
- **算法：** `setState` 内单个 `removeWhere((r) => r.id == record.id)`，然后保存。
- **用法：**
  ```dart
  onDismissed: (_) => _deleteRecord(record),
  ```
  （来自 `_buildRecordDismissible`，共享删除确认对话框后）。
- **备注：** 这里没有确认逻辑——`Dismissible` 调用方负责在运行前确认。

### `Future<void> _editRecord(IntimacyRecord record)`（`_IntimacyPageState` 中） <a id="editrecord-main"></a>
- **种类：** `_IntimacyPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 500 行）
- **用途：** 为既有记录打开编辑记录对话框并持久化更新。
- **输入：** `record` — 被编辑的记录。
- **返回：** `Future<void>`。
- **副作用：** 显示预填的 `AddRecordDialog`；非 null 结果时经 `setState` 替换 `_records` 中的记录并调用 `_saveData()`。
- **算法：** 与 `_addRecord` 相同的激活伴侣/激活玩具计算，但对话框被给既有 `record` 预填；返回时按 id 找记录并覆盖。
- **用法：**
  ```dart
  _editRecord(record);
  ```
  （来自记录块的点击处理器 / 可关闭菜单，在 `_buildRecordDismissible` 中）。
- **备注：** 因为对话框的伴侣/玩具选择器从*仅激活*列表构建，编辑引用已删除或分手伴侣/玩具的记录仍正确显示和保存，只因选择器构建（在姊妹 `_FilteredRecordsPageState` 变体中——见 [`_dialogPartners`](#dialogpartners)/[`_dialogToys`](#dialogtoys)）即使非激活也显式包含记录的*当前*引用。此主页 `_editRecord` 自己不对悬空 id 特判，只是保留任何已存储的 id——它绝不重新分配或清除，按 [亲密 § 已删除伴侣处理](../../../../features/intimacy.md#deleted-partner-handling) 描述的已删除伴侣容忍策略。

### `int _compareNullableDates(DateTime? a, DateTime? b)`（`_PartnerManagementPageState` 中） <a id="comparenullabledates-partner"></a>
- **种类：** `_PartnerManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 2609 行）
- **用途：** 比较两个可选日期，`null` 当作排在任何真实日期之后。
- **输入：** `a`、`b`。
- **返回：** `int` — 标准比较器契约。
- **副作用：** 无。
- **算法：** 两者都 null → `0`；只有 `a` null → `1`（a 排后）；只有 `b` null → `-1`；否则 `a.compareTo(b)`。
- **用法：**
  ```dart
  final byDate = _compareNullableDates(a.startDate, b.startDate);
  return byDate != 0 ? byDate : _compareText(a.name, b.name);
  ```
  （`_sortPartners` 的日期排序分支内，名称作打破平局）。
- **备注：** 在 `_ToyManagementPageState` 中为购买日期排序逐字节重复——见 [`_compareNullableDates`（玩具）](#comparenullabledates-toy)。

### `List<String> _normalizedOrder(String statusKey)`（`_PartnerManagementPageState` 中） <a id="normalizedorder-partner"></a>
- **种类：** `_PartnerManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 2629 行）
- **用途：** 调和状态组存储的自定义顺序 id 列表与当前存在于该组的伴侣。
- **输入：** `statusKey`（`_statusActive` 或 `_statusInactive`）。
- **返回：** `List<String>` — 该组每个当前伴侣 id，按稳定顺序。
- **副作用：** 无。
- **算法：**
  1. 计算 `allIds`：激活/非激活状态匹配 `statusKey` 的伴侣的 id。
  2. 遍历存储自定义顺序（如有）并只保留 (a) 仍在 `allIds` 中且 (b) 未 `seen` 的 id——丢弃过期 id（已删除伴侣，或移到另一状态组的伴侣）并去重。
  3. 按自然列表顺序在末尾追加任何剩余未 `seen` 的 `allIds`（新添加伴侣）。
- **用法：**
  ```dart
  _customOrders[statusKey] = _normalizedOrder(statusKey);
  ```
  （需要播种或重新同步自定义顺序时调用：切入自定义排序模式、追加分手伴侣等）。
- **备注：** 这正是让手动拖拽顺序在伴侣被添加、删除或在激活/非激活组间移动时不静默损坏的东西。为玩具重复——见 [`_normalizedOrder`（玩具）](#normalizedorder-toy)。

### `List<Partner> _sortPartners(String statusKey, List<Partner> partners)` <a id="sortpartners"></a>
- **种类：** `_PartnerManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 2652 行）
- **用途：** 按状态组当前排序模式排序伴侣列表。
- **输入：** `statusKey`、`partners`（要排序的列表——做副本，输入不被修改）。
- **返回：** `List<Partner>`。
- **副作用：** 无（读取 `_customOrders` 但不写它）。
- **算法：** 对 `_sortMode(statusKey)` 做 `switch`：
  - `_sortDate`：按 `startDate`（null 排最后），名称打破平局。
  - `_sortCount`：按 `_partnerRecordCount` 降序，名称打破平局。
  - `_sortName`：只按名称。
  - `_sortCustom`/默认：按在 `_normalizedOrder(statusKey)` 中的位置，未知 id（索引 `-1`）推到 `fallbackIndex`（末尾），名称打破平局。
- **用法：**
  ```dart
  List<Partner> get _activePartners => _sortPartners(
    _statusActive,
    _partners.where((p) => p.endDate == null).toList(),
  );
  ```
- **备注：** 每个分支经 `_compareText` 用不区分大小写名称打破平局，因此平局绝不产生视觉不稳定的排序。

### `void _setSortMode(String statusKey, String mode)`（`_PartnerManagementPageState` 中） <a id="setsortmode-partner"></a>
- **种类：** `_PartnerManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 2690 行）
- **用途：** 切换状态组的活动排序模式，首次选择自定义排序时播种其自定义顺序。
- **输入：** `statusKey`、`mode`（`_sortDate`/`_sortCount`/`_sortName`/`_sortCustom` 之一）。
- **返回：** 无。
- **副作用：** `setState` 更新 `_sortModes[statusKey]` 和可能 `_customOrders`/`_reordering`；调用 `_notifySort()`。
- **算法：**
  1. 切换*进*自定义模式且该组尚无可自定义顺序时，从该组在其*先前*排序模式下的当前视觉顺序播种一个（使切换到自定义排序不视觉重排任何东西）。
  2. 存储新模式。
  3. 新模式是自定义时也经 `_normalizedOrder` 刷新（覆盖调和）；否则清除该组的 `_reordering` 标志（自定义排序的拖拽重排 UI 只在自定义模式适用）。
  4. 经 `_notifySort()` 通知父级。
- **用法：**
  ```dart
  onSelected: (mode) => _setSortMode(statusKey, mode),
  ```
  （来自 `_managedSortItem` 构建的排序模式弹出菜单）。
- **备注：** 为玩具重复——见 [`_setSortMode`（玩具）](#setsortmode-toy)。

### `void _appendPartnerToCustomOrderIfNeeded(Partner partner)` <a id="appendpartnertocustomorderifneeded"></a>
- **种类：** `_PartnerManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 2717 行）
- **用途：** 只在组实际使用自定义排序时把伴侣插入其状态组自定义顺序。
- **输入：** `partner` — 用其 id 和当前激活/非激活状态。
- **返回：** 无。
- **副作用：** 原地修改 `_customOrders[statusKey]`（无 `setState`/通知——调用方作为更大操作的一部分自己做）。
- **算法：** 从 `partner.endDate` 计算 `statusKey`；该组排序模式不是自定义时什么都不做；否则经 `_normalizedOrder` 重新计算（它自然包含新伴侣，因为它现在属于 `allIds`）。
- **用法：**
  ```dart
  _removePartnerFromCustomOrders(p.id);
  _appendPartnerToCustomOrderIfNeeded(
    _partners.firstWhere((x) => x.id == p.id),
  );
  ```
  （来自 `_breakUpPartner`，把伴侣从激活移到非激活后）。
- **备注：** 先移除-再-追加模式正是伴侣状态变化时在激活和非激活自定义顺序列表间"移动"的方式。

### `void _removePartnerFromCustomOrders(String partnerId)` <a id="removepartnerfromcustomorders"></a>
- **种类：** `_PartnerManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 2728 行）
- **用途：** 从每个存储自定义顺序（激活和非激活组都）移除伴侣 id。
- **输入：** `partnerId`。
- **返回：** 无。
- **副作用：** 修改 `_customOrders` 中的每个列表。
- **算法：** 循环 `_customOrders.entries` 并对每个值列表调用 `.remove(partnerId)`。
- **用法：** 从 `_deletePartner` 和 `_breakUpPartner` 在重新把 id 加回正确组前调用。
- **备注：** 无条件遍历两个状态组，而不是查找当前包含该 id 的组——对涉及的小列表大小便宜。

### `void _reorderPartners(String statusKey, List<Partner> partners, int oldIndex, int newIndex)` <a id="reorderpartners"></a>
- **种类：** `_PartnerManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 2739 行）
- **用途：** 对状态组自定义顺序应用 `ReorderableListView` 拖拽手势。
- **输入：** `statusKey`、`partners`（当前显示、已排序列表）、拖拽回调报告的 `oldIndex`/`newIndex`。
- **返回：** 无。
- **副作用：** `setState` 重写 `_customOrders[statusKey]` 并强制 `_sortModes[statusKey] = _sortCustom`；调用 `_notifySort()`。
- **算法：**
  1. `newIndex` 在 `oldIndex` 之后时按 Flutter `ReorderableListView` 约定减一（组件报告*移除前*的目标索引）。
  2. 对照 id 列表边界检查两个索引；越界静默返回（对过期拖拽回调防御）。
  3. 移除 `oldIndex` 处的 id 并在 `newIndex` 重新插入。
  4. 存储重排后 id 列表并强制排序模式为自定义（拖拽总是把你切入自定义排序模式，即使你当时在看另一个排序）。
- **用法：**
  ```dart
  _reorderPartners(statusKey, partners, oldIndex, oldStyleNewIndex);
  ```
  （来自 `_buildPartnerReorderList` 的 `ReorderableListView.builder` 的 `onReorder`）。
- **备注：** 为玩具重复——见 `_reorderToys`。

### `void _deletePartner(Partner p)` <a id="deletepartner"></a>
- **种类：** `_PartnerManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 2784 行）
- **用途：** 永久删除伴侣及其周期记录，同时刻意保留历史活动记录不动。
- **输入：** `p` — 要删除的伴侣。
- **返回：** 无。
- **副作用：** `setState` 从 `_partners` 移除 `p` 并移除每个 `personId == p.id` 的 `CycleRecord`；清理自定义顺序条目；调用 `widget.onChanged(_partners)`、`widget.onCycleRecordsChanged(_cycleRecords)` 和 `_notifySort()`。
- **算法：**
  1. 从 `_partners` 移除伴侣。
  2. 也移除该伴侣的周期记录（使它们的 `personId` 不会在无缺失人显示容忍的记录类型中悬空）。
  3. 从所有自定义顺序列表清理伴侣 id。
  4. 经回调把两个变更集合推给父级，然后重新通知排序状态。
- **用法：**
  ```dart
  onDismissed: (_) => _deletePartner(p),
  ```
  （来自 `_buildPartnerTile` 中伴侣块的 `Dismissible`，共享删除确认后）。
- **备注：** 与活动记录刻意**不对称**：`IntimacyRecord.partnerId` 在这里*不*被清理，记录块/编辑对话框被构建为容忍悬空 id 并渲染空白伴侣标签——见 [亲密 § 已删除伴侣处理](../../../../features/intimacy.md#deleted-partner-handling)。这镜像应用别处使用的"不为瞬态 UI 便利销毁历史"原则（如财务的强制余额交易）。

### `void _breakUpPartner(Partner p)` <a id="breakuppartner"></a>
- **种类：** `_PartnerManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 2801 行）
- **用途：** 标记伴侣分手而不删除：设置结束日期并禁用其日历周期叠加。
- **输入：** `p` — 要分手的伴侣。
- **返回：** 无。
- **副作用：** `setState` 用带 `endDate = now` 和 `body.showCycleOnCalendar = false` 的副本替换 `_partners` 中的 `p`；重新同步自定义顺序成员；调用 `widget.onChanged(_partners)` 和 `_notifySort()`。
- **算法：**
  1. 捕获 `now`。
  2. 移除旧伴侣条目并重新添加带相同 id/名称/emoji/图像/开始日期、`endDate: now` 和 `body: p.body?.copyWith(showCycleOnCalendar: false)` 的重建 `Partner`——即除变化的两者外每个字段都保留。
  3. 从它所在的任何自定义顺序移除 id，然后重新追加它（现在状态从激活翻到非激活，如果非激活组用自定义排序需要移入其自定义顺序）经 [`_appendPartnerToCustomOrderIfNeeded`](#appendpartnertocustomorderifneeded)。
  4. 通知父级并重新通知排序。
- **用法：**
  ```dart
  _breakUpPartner(p);
  ```
  （来自 `_buildPartnerTile` 中伴侣块的溢出菜单）。
- **备注：** 在这里关闭 `showCycleOnCalendar` 正是支撑 [亲密 § 身体层](../../../../features/intimacy.md#the-body-layer-v124) 文档化的"分手自动停止在主页日历显示此伴侣周期"行为；用户之后可以从伴侣身体标签手动重新启用。

### `int _compareNullableDates(DateTime? a, DateTime? b)`（`_ToyManagementPageState` 中） <a id="comparenullabledates-toy"></a>
- **种类：** `_ToyManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 3622 行）
- **用途：** 比较两个可选日期，`null` 当作排在任何真实日期之后。
- **输入：** `a`、`b`。
- **返回：** `int`。
- **副作用：** 无。
- **算法：** 与 [`_compareNullableDates`（伴侣）](#comparenullabledates-partner) 相同：两者都 null → 0；只有 `a` null → 1；只有 `b` null → -1；否则 `a.compareTo(b)`。
- **用法：** `_sortToys` 的日期排序分支在 `purchaseDate` 上使用。
- **备注：** 除上面交叉引用外无。

### `double _totalToyCost(List<Toy> toys)`（`_ToyManagementPageState` 中） <a id="totaltoycost"></a>
- **种类：** `_ToyManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 3649 行）
- **用途：** 对玩具列表求和总记录成本。
- **输入：** `toys`。
- **返回：** `double` — 都没有价格时 `0.0`。
- **副作用：** 无。
- **算法：** `toys.fold(0.0, (sum, toy) => sum + toy.totalCost())` — 无价格玩具经 `Toy.totalCost()` 自己的 null 处理贡献 `0`。
- **用法：**
  ```dart
  _formatMoney(_totalToyCost(activeToys)),
  ```
  （在 `_buildActiveCostSummary` 中）。
- **备注：** `_ToyCostOverviewPageState` 中以不同名称（`_totalCost`）重新实现的相同计算——见 [`_totalCost`](#totalcost)。

### `double? _totalDailyToyCost(List<Toy> toys)` <a id="totaldailytoycost"></a>
- **种类：** `_ToyManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 3657 行）
- **用途：** 至少一个玩具有足够数据计算时对玩具列表求和平均每日成本。
- **输入：** `toys`。
- **返回：** `double?` — 列表中没有玩具同时有价格和购买日期时为 `null`。
- **副作用：** 无。
- **算法：** 循环，跳过 `toy.averageDailyCost()` 为 null 的玩具，累积其余，并经 `hasDailyCost` 标志跟踪是否有*任何*玩具贡献；标志从未翻转时返回 `null` 而不是 `0`（区分"无成本可算玩具"与"玩具零成本"）。
- **用法：**
  ```dart
  final dailyCost = _totalDailyToyCost(activeToys);
  ```
  （在 `_buildActiveCostSummary` 中）。
- **备注：** `_ToyCostOverviewPageState` 中以不同名称（`_totalDailyCost`）重新实现——见 [`_totalDailyCost`](#totaldailycost)。

### `List<String> _normalizedOrder(String statusKey)`（`_ToyManagementPageState` 中） <a id="normalizedorder-toy"></a>
- **种类：** `_ToyManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 3674 行）
- **用途：** 调和状态组存储的自定义顺序 id 列表与当前存在于该组的玩具。
- **输入：** `statusKey`（`_statusActive` 或 `_statusInactive`，后者在此类中意为"退役"）。
- **返回：** `List<String>`。
- **副作用：** 无。
- **算法：** 与 [`_normalizedOrder`（伴侣）](#normalizedorder-partner) 形态相同：按退役状态匹配过滤 `allIds`，只保留存储顺序中仍有效/未见的 id，然后追加新添加玩具 id。
- **用法：** 与伴侣版本相同模式，如在 `_setSortMode` 播种自定义顺序。
- **备注：** 除上面交叉引用外无。

### `List<Toy> _sortToys(String statusKey, List<Toy> toys)` <a id="sorttoys"></a>
- **种类：** `_ToyManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 3697 行）
- **用途：** 按状态组当前排序模式排序玩具列表。
- **输入：** `statusKey`、`toys`。
- **返回：** `List<Toy>`。
- **副作用：** 无。
- **算法：** 与 [`_sortPartners`](#sortpartners) 相同形态：`_sortDate` 按 `purchaseDate`（null 排最后）；`_sortCount` 按 `_toyRecordCount` 降序；`_sortName` 按名称；`_sortCustom`/默认按在 `_normalizedOrder` 中的位置。所有分支名称打破平局。
- **用法：**
  ```dart
  List<Toy> get _activeToys => _sortToys(
    _statusActive,
    _toys.where((t) => t.retiredDate == null).toList(),
  );
  ```
- **备注：** 除对 `_sortPartners` 的交叉引用外无。

### `void _setSortMode(String statusKey, String mode)`（`_ToyManagementPageState` 中） <a id="setsortmode-toy"></a>
- **种类：** `_ToyManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 3733 行）
- **用途：** 切换状态组的活动排序模式，首次使用播种其自定义顺序。
- **输入：** `statusKey`、`mode`。
- **返回：** 无。
- **副作用：** `setState` 更新 `_sortModes`/`_customOrders`/`_reordering`；调用 `_notifySort()`。
- **算法：** 与 [`_setSortMode`（伴侣）](#setsortmode-partner) 相同，操作 `_toys`/退役状态而非 `_partners`/结束日期。
- **用法：**
  ```dart
  onSelected: (mode) => _setSortMode(statusKey, mode),
  ```
- **备注：** 除上面交叉引用外无。

### `void _appendToyToCustomOrderIfNeeded(Toy toy)` <a id="appendtoytocustomorderifneeded"></a>
- **种类：** `_ToyManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 3760 行）
- **用途：** 只在组使用自定义排序时把玩具插入其状态组自定义顺序。
- **输入：** `toy`。
- **返回：** 无。
- **副作用：** 原地修改 `_customOrders[statusKey]`。
- **算法：** 与 [`_appendPartnerToCustomOrderIfNeeded`](#appendpartnertocustomorderifneeded) 相同，按退役状态而非结束日期键控。
- **用法：**
  ```dart
  _appendToyToCustomOrderIfNeeded(_toys.firstWhere((x) => x.id == t.id));
  ```
  （来自 `_retireToy`）。
- **备注：** 除上面交叉引用外无。

### `void _removeToyFromCustomOrders(String toyId)` <a id="removetoyfromcustomorders"></a>
- **种类：** `_ToyManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 3771 行）
- **用途：** 从每个存储自定义顺序移除玩具 id。
- **输入：** `toyId`。
- **返回：** 无。
- **副作用：** 修改 `_customOrders` 中的每个列表。
- **算法：** 与 [`_removePartnerFromCustomOrders`](#removepartnerfromcustomorders) 相同：循环并从每个值列表 `.remove(toyId)`。
- **用法：** 从 `_deleteToy` 和 `_retireToy` 调用。
- **备注：** 除上面交叉引用外无。

### `void _reorderToys(String statusKey, List<Toy> toys, int oldIndex, int newIndex)` <a id="reordertoys"></a>
- **种类：** `_ToyManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 3782 行）
- **用途：** 对状态组自定义玩具顺序应用拖拽重排手势。
- **输入：** `statusKey`、`toys`、`oldIndex`、`newIndex`。
- **返回：** 无。
- **副作用：** `setState` 重写 `_customOrders[statusKey]`、强制 `_sortModes[statusKey] = _sortCustom`；调用 `_notifySort()`。
- **算法：** 与 [`_reorderPartners`](#reorderpartners) 相同：调整 `newIndex`、边界检查、移除-再-插入 id、强制自定义排序模式。
- **用法：**
  ```dart
  _reorderToys(statusKey, toys, oldIndex, oldStyleNewIndex);
  ```
- **备注：** 除上面交叉引用外无。

### `void _deleteToy(Toy t)` <a id="deletetoy"></a>
- **种类：** `_ToyManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 3825 行）
- **用途：** 永久删除玩具。
- **输入：** `t`。
- **返回：** 无。
- **副作用：** `setState` 从 `_toys` 移除 `t`；清理自定义顺序条目；调用 `widget.onChanged(_toys)` 和 `_notifySort()`。
- **算法：** `setState` 内单个 `removeWhere`，然后 [`_removeToyFromCustomOrders`](#removetoyfromcustomorders)、通知父级、重新通知排序。
- **用法：**
  ```dart
  onDismissed: (_) => _deleteToy(t),
  ```
  （来自 `_buildToyTile` 的 `Dismissible`）。
- **备注：** 与 `_deletePartner` 不同，没有要清理的次级集合（玩具没有周期记录）；引用此玩具的 `IntimacyRecord.toyIds` 保持原样，与伴侣相同的已删除引用容忍理念。

### `void _retireToy(Toy t)` <a id="retiretoy"></a>
- **种类：** `_ToyManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 3837 行）
- **用途：** 标记玩具退役而不删除。
- **输入：** `t`。
- **返回：** 无。
- **副作用：** `setState` 用带 `retiredDate = now` 的副本替换 `t`；重新同步自定义顺序成员；调用 `widget.onChanged(_toys)` 和 `_notifySort()`。
- **算法：**
  1. 移除旧 `t` 并重新添加带相同 id/名称/emoji/图像/购买日期/购买链接/价格加 `retiredDate: now` 的重建 `Toy`。
  2. 经 [`_removeToyFromCustomOrders`](#removetoyfromcustomorders) 然后 [`_appendToyToCustomOrderIfNeeded`](#appendtoytocustomorderifneeded) 把其自定义顺序成员从激活移到退役。
  3. 通知父级并重新通知排序。
- **用法：**
  ```dart
  _retireToy(t);
  ```
  （来自 `_buildToyTile` 的溢出菜单）。
- **备注：** 这是 [亲密 § UI](../../../../features/intimacy.md#ui) 中"玩具退役状态"背后的机制——退役玩具的成本此后被成本总览图当作**最终确定**（见 [`_toyDailyCostAt`](#toydailycostat) 的全部范围分支）。

### `void _importDefaults()` <a id="importdefaults"></a>
- **种类：** `_PositionManagementPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 4746 行）
- **用途：** 添加应用内置默认姿势预设，跳过按名称已存在的。
- **输入：** 无（用 `l10n` 的本地化预设名/emoji）。
- **返回：** 无。
- **副作用：** 追加进 `_positions`；至少实际添加一个预设时才 `setState` + `widget.onChanged(_positions)`。
- **算法：**
  1. 构建 9 个默认预设的固定列表（传教士、女上、后入、反向女上、侧卧、站立、69、莲花、俯卧），各为本地化名称 + emoji。
  2. 构建 `existingNames`，用户当前姿势名的小写集合。
  3. 对每个小写名尚未在 `existingNames` 中的预设，追加新 `Position(name:, emoji:)` 并递增 `added` 计数器。
  4. 只在 `added > 0` 时调用 `setState({})` 和 `widget.onChanged(_positions)`——一切已存在时导入是空操作，无重建/通知。
- **用法：**
  ```dart
  if (v == 'import') _importDefaults();
  ```
  （来自姿势管理页的溢出菜单）。
- **备注：** 去重纯粹按不区分大小写名称匹配——用户重命名的默认姿势（如把"传教士"改成别的）会在下次导入时以其原名重新导入。

### `List<IntimacyRecord> get _filteredRecords`（`_FilteredRecordsPageState` 中） <a id="filteredrecords-filtered"></a>
- **种类：** `_FilteredRecordsPageState` 的 getter
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 5099 行）
- **用途：** 返回此详情页的记录——引用限定伴侣或玩具的——最新优先。
- **输入：** 无（读取 `_records`、`widget.partnerId`、`widget.toyId`）。
- **返回：** `List<IntimacyRecord>`。
- **副作用：** 无。
- **算法：** 页面伴侣限定则按 `partnerId` 匹配过滤，玩具限定则按 `toyIds` 包含过滤，否则全部通过；然后按 `datetime` 降序排序。
- **用法：**
  ```dart
  final records = _filteredRecords;
  ```
  （在 `_buildRecordsListView` 中）。
- **备注：** 与主页的 [`_filteredRecords`](#filteredrecords-main) 不同，这没有日期/类型/排序模式过滤——它纯粹为把共享记录列表限定到一个伴侣或玩具存在，总是最新优先，"匹配账户交易详情"按其源码注释。

### `List<Partner> _dialogPartners({String? includePartnerId})` <a id="dialogpartners"></a>
- **种类：** `_FilteredRecordsPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 5125 行）
- **用途：** 构建此详情页增/改记录对话框提供的伴侣选择器列表。
- **输入：** `includePartnerId` — 即使非激活也必须出现的 id（通常是被编辑记录）。
- **返回：** `List<Partner>`。
- **副作用：** 无。
- **算法：**
  1. 从 `widget.partnerId`（本页自己的范围，若伴侣限定）和可选 `includePartnerId` 参数构建 `includeIds`。
  2. 遍历 `widget.partners`，伴侣激活（`endDate == null`）**或**其 id 在 `includeIds` 中时保留，经 `seen` 集合去重。
- **用法：**
  ```dart
  partners: _dialogPartners(includePartnerId: widget.partnerId),
  // and, when editing:
  partners: _dialogPartners(includePartnerId: record.partnerId),
  ```
- **备注：** 这是让*非激活*（分手）伴侣的详情页仍让用户针对那个伴侣增/改记录的机制——选择器总是包含页面自己的限定 id，即使它否则被排除在"激活"池外。直接实现 [亲密 § 已删除伴侣处理](../../../../features/intimacy.md#deleted-partner-handling) 点出的"姿势/玩具/伴侣选择器"容忍。

### `List<Toy> _dialogToys({Iterable<String> includeToyIds = const []})` <a id="dialogtoys"></a>
- **种类：** `_FilteredRecordsPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 5141 行）
- **用途：** 构建此详情页增/改记录对话框提供的玩具选择器列表。
- **输入：** `includeToyIds` — 即使退役也必须出现的 id（通常来自被编辑记录）。
- **返回：** `List<Toy>`。
- **副作用：** 无。
- **算法：** 镜像 [`_dialogPartners`](#dialogpartners)：玩具激活（无 `retiredDate`）或其 id 在组合的 `widget.toyId` + `includeToyIds` 集合中则包含，去重。
- **用法：**
  ```dart
  toys: _dialogToys(includeToyIds: widget.toyId != null ? [widget.toyId!] : const []),
  // and, when editing:
  toys: _dialogToys(includeToyIds: record.toyIds),
  ```
- **备注：** 与 `_dialogPartners` 相同的退役玩具容忍理由。

### `Future<void> _addRecord()`（`_FilteredRecordsPageState` 中） <a id="addrecord-filtered"></a>
- **种类：** `_FilteredRecordsPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 5164 行）
- **用途：** 从伴侣/玩具详情页打开添加记录对话框，预选当前范围。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 显示 `AddRecordDialog`；成功时经 `setState` 插入 `_records` 前部并调用 `_notifyRecordsChanged()`。
- **算法：**
  1. 显示带 `_dialogPartners`/`_dialogToys`（范围包含）选择器、`initialPartnerId`/`initialToyIds` 预选本页范围 的对话框。
  2. 非 null 结果时 `_records.insert(0, record)`（新记录到顶部，匹配最新优先显示顺序）并通知父级。
- **用法：** 接到 `build()`/`_buildRecordsListView` 中此详情页的添加按钮。
- **备注：** 与主页的 `_addRecord` 不同，这操作页面本地 `_records` 副本并经 `onRecordsChanged` 把变更推上去，而不是直接调用存储——实际持久化在被通知的父 `_IntimacyPageState` 中发生。

### `Future<void> _editRecord(IntimacyRecord record)`（`_FilteredRecordsPageState` 中） <a id="editrecord-filtered"></a>
- **种类：** `_FilteredRecordsPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 5187 行）
- **用途：** 从详情页为一条记录打开编辑记录对话框并更新本地状态。
- **输入：** `record`。
- **返回：** `Future<void>`。
- **副作用：** 显示预填 `AddRecordDialog`；成功时经 `setState` 按 id 替换 `_records` 中的记录；调用 `_notifyRecordsChanged()`。
- **算法：** 显示带 `record:` 设置和范围包含选择器的对话框；非 null 结果时按 id 找索引并原地覆盖（id 不知何故未找到则空操作）。
- **用法：**
  ```dart
  _editRecord(record);
  ```
  （来自 `_buildRecordDismissible` 的点击/菜单处理器）。
- **备注：** 编辑把记录的伴侣/玩具改离本页范围时，记录下次重建时简单从 `_filteredRecords` 消失——没有特判处理，它直接落出过滤器。

### `void _deleteRecord(IntimacyRecord record)`（`_FilteredRecordsPageState` 中） <a id="deleterecord-filtered"></a>
- **种类：** `_FilteredRecordsPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 5210 行）
- **用途：** 从本地状态移除记录并通知父级。
- **输入：** `record`。
- **返回：** 无。
- **副作用：** `setState` 从 `_records` 移除匹配记录；调用 `_notifyRecordsChanged()`。
- **算法：** 按 id 单个 `removeWhere`，然后通知。
- **用法：**
  ```dart
  onDismissed: (_) => _deleteRecord(record),
  ```
- **备注：** 与主页的 `_editRecord`/`_deleteRecord` 一样，`Dismissible` 调用方在运行前处理删除确认。

### `String _formatDuration(Duration duration)` <a id="formatduration"></a>
- **种类：** `_FilteredRecordsPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 5220 行）
- **用途：** 为详情页摘要指标格式化时长。
- **输入：** `duration`。
- **返回：** `String` — 至少一小时时 `"Xh Ym"`，否则 `"Ym"`。
- **副作用：** 无。
- **算法：** `hours = duration.inHours`；`minutes = duration.inMinutes.remainder(60)`；`hours > 0` 时返回 `"${hours}h ${minutes}m"`，否则返回 `"${duration.inMinutes}m"`（避免短记录的冗余 "0h" 前缀）。
- **用法：** 从 `_buildSummaryCard` 调用格式化平均时长指标。
- **备注：** 无。

### `_ToyCostTrendData _buildTrendData(List<DateTime> dates, DateTime today, List<Toy> toys)` <a id="buildtrenddata"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6072 行）
- **用途：** 计算聚合成本趋势图上绘制的历史/未来每日成本点列表和 y 轴边界。
- **输入：** `dates`（来自 [`_timeline`](#timeline) 的采样时间线）、`today`、`toys`（当前范围内玩具）。
- **返回：** `_ToyCostTrendData`（历史点、未来点、`minY`、`maxY`）。
- **副作用：** 无。
- **算法：**
  1. 对每个采样日期计算 `_dailyCostAt(date, toys)`；跳过无值日期。
  2. 把每个有效值加入运行 `values` 列表（供边界）和 `historySpots`（日期 `<= today` 时）和/或 `futureSpots`（日期 `>= today` 时）——**今天的点同时包含在两条线中**，使它们视觉相连。
  3. 完全没计算到值时返回归零 `_ToyCostTrendData`。
  4. 否则从 `values.reduce(math.min)`/`reduce(math.max)` 设置 `minY`/`maxY`。
- **用法：**
  ```dart
  final trendData = _buildTrendData(dates, today, toys);
  ```
  （在 `_buildTrendCard` 中，供给 `_buildCostChart`）。
- **备注：** 除上面今天包含在两条线中的行为外无。

### `double? _dailyCostAt(DateTime date, List<Toy> toys)` <a id="dailycostat"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6112 行）
- **用途：** 在某一天对玩具列表求和聚合平均每日成本。
- **输入：** `date`、`toys`。
- **返回：** `double?` — 直到至少一个包含玩具能在那天计费前为 `null`。
- **副作用：** 无。
- **算法：** 对 `toys` 求和 [`_toyDailyCostAt`](#toydailycostat)，跳过 null，与 [`_totalDailyToyCost`](#totaldailytoycost)/[`_totalDailyCost`](#totaldailycost) 相同方式跟踪 `hasValue` 标志。
- **用法：**
  ```dart
  final value = _dailyCostAt(date, toys);
  ```
  （`_buildTrendData` 的逐日期循环内）。
- **备注：** 无。

### `double? _toyDailyCostAt(Toy toy, DateTime date)` <a id="toydailycostat"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6129 行）
- **用途：** 计算一个玩具截至特定日期的平均每日成本，考虑退役。
- **输入：** `toy`、`date`。
- **返回：** `double?` — 玩具无成本数据、无购买日期或日期早于其购买时为 `null`。
- **副作用：** 无。
- **算法：**
  1. `!toy.hasCostData || purchaseDate == null`，或 `date` 早于（纯日期）购买日期时立即返回 `null`。
  2. **全部范围捷径：** 当前范围为 `all` 且玩具退役时，直接返回玩具已最终确定的 `averageDailyCost()`（退役玩具的每日成本固定在其退役点，不按服务继续重新计算）。
  3. 否则计算 `serviceEnd`：正常为 `date`，但退役且退役日期早于 `date` 时钳制到玩具退役日期。
  4. `serviceEnd` 早于 `purchaseDate`（同日退役或边界情形可能发生）时返回 `null`。
  5. 否则 `totalCost() / max(1, days in service)`，即成本摊销到截至 `serviceEnd` 拥有的天数。
- **用法：**
  ```dart
  final value = _toyDailyCostAt(toy, date);
  ```
  （`_dailyCostAt` 的逐玩具循环内）。
- **备注：** 第 2 步的捷径正是让退役玩具成本在全部范围趋势中读作"最终确定"的东西——见 [亲密 § UI](../../../../features/intimacy.md#ui)（"最终退役玩具成本"）。

### `DateTime _historyStart(DateTime today, List<Toy> toys)` <a id="historystart"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6151 行）
- **用途：** 返回所选范围成本趋势图显示的第一个日期。
- **输入：** `today`、`toys`。
- **返回：** `DateTime`。
- **副作用：** 无。
- **算法：** 与 [`IntimacyChartRange.cutoffFrom`](../widgets/intimacy_trend_chart.md#cutofffrom) 相同的范围到截止 `switch`（从 `today` 回退一周/月/3 月/6 月/年），唯独 `all` case 解析为 [`_earliestPurchaseDate`](#earliestpurchasedate)（无玩具有购买日期时回退一年前）；最后钳制结果使它绝不在 `today` 之后。
- **用法：**
  ```dart
  final historyStart = _historyStart(today, toys);
  ```
  （在 `_buildTrendCard` 中）。
- **备注：** 源码注释说明这"镜像 MyDevice"——MyDevice 应用的成本/电池风格趋势图使用相同的范围选择模式。

### `DateTime _futureEnd(DateTime today, DateTime historyStart, List<Toy> toys)` <a id="futureend"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6186 行）
- **用途：** 返回成本趋势图未来/投影半边的投影结束日期。
- **输入：** `today`、`historyStart`、`toys`。
- **返回：** `DateTime`。
- **副作用：** 无。
- **算法：**
  1. 从 `today` 前向投影 `max(days since historyStart, 30)`——投影窗口至少与历史窗口一样长（或 30 天，取较大者）。
  2. 任何玩具的购买日期（尚未到达）落在那个投影结束之后时，把 `futureEnd` 延长到该玩具购买日期后 30 天，使未来日期的玩具购买绝不被图表裁掉。
- **用法：**
  ```dart
  final futureEnd = _futureEnd(today, historyStart, toys);
  ```
- **备注：** 除上面未来购买容纳外无。

### `DateTime? _earliestPurchaseDate(List<Toy> toys)` <a id="earliestpurchasedate"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6205 行）
- **用途：** 返回玩具列表中最晚购买日期。
- **输入：** `toys`。
- **返回：** `DateTime?` — 无玩具有购买日期时为 `null`。
- **副作用：** 无。
- **算法：** 线性扫描跟踪至今见过的最小纯日期购买日期。
- **用法：** `_historyStart` 的 `all` 范围分支用于把图表锚定在最早玩具购买处。
- **备注：** 无。

### `List<DateTime> _timeline(DateTime historyStart, DateTime today, DateTime futureEnd, List<Toy> toys)` <a id="timeline"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6221 行）
- **用途：** 构建沿成本趋势图 x 轴绘制的采样、去重日期列表。
- **输入：** `historyStart`、`today`、`futureEnd`、`toys`。
- **返回：** `List<DateTime>` — 升序排序、无连续重复。
- **副作用：** 无。
- **算法：**
  1. 基于总跨度选择采样 `step`：`<= 240` 天按天、`<= 1800` 天按周、否则按月——使非常长范围的样本数有界。
  2. 从 `historyStart` 到 `futureEnd`（闭区间）生成均匀步进日期。
  3. 总是显式添加 `today` 和 `futureEnd`（使投影边界和"现在"标记总是作为精确点存在，不只是被步进网格近似）。
  4. 添加每个玩具的购买和退役日期（使成本不连续点总是精确采样，而不只是被步进网格近似）。
  5. 排序一切，然后去重连续相等日期。
- **用法：**
  ```dart
  final dates = _timeline(historyStart, today, futureEnd, toys);
  ```
- **备注：** 显式采样购买/退役/今天/结束日期（第 3-4 步）正是让尖锐成本跳变（买新玩具、旧玩具退役）即使在月度采样分辨率下也在图上清晰的东西。

### `DateTime _dateOnly(DateTime date)` <a id="dateonly"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6261 行）
- **用途：** 从 `DateTime` 剥离日内时间分量，使基于天的成本数学不依赖原始时间戳的时间分量。
- **输入：** `date`。
- **返回：** `DateTime` — `DateTime(date.year, date.month, date.day)`。
- **副作用：** 无。
- **算法：** 单个构造函数调用丢弃时/分/秒/毫秒。
- **用法：** 贯穿此类使用——`_toyDailyCostAt`、`_earliestPurchaseDate`、`_timeline`——任何需要按日历日而非精确时刻比较或分桶日期的地方。
- **备注：** 这里归组为 Tier A，因为它是上面成本趋势算法组中每个日期比较背后的承载负载原语，尽管实现本身是一行。

### `({double minY, double maxY}) _chartBounds(double minY, double maxY)` <a id="chartbounds"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6269 行）
- **用途：** 填充原始 min/max y 范围，使平坦或全零成本图表仍渲染可见垂直空间。
- **输入：** `minY`、`maxY`。
- **返回：** Dart 记录 `({double minY, double maxY})`。
- **副作用：** 无。
- **算法：**
  1. `minY == maxY`（平坦数据）时按 `minY` 量级的 10% 填充，那本身为零（全零数据）时回退固定 `1.0` 填充。
  2. 否则两端各按范围 10% 填充。
  3. 无论哪种方式，把下界钳制为绝不超 `0`（`math.min(0, minY - padding)`），使仅正值成本系列仍显示零基线。
- **用法：** 在 `_buildCostChart` 中对数刻度图变换边界前调用。
- **备注：** 无。

### `double _logTransform(double value)` <a id="logtransform"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6285 行）
- **用途：** 把成本值映射到带符号 log10 刻度供图表化，使少数高早期成本点不视觉压平后来的小值。
- **输入：** `value`。
- **返回：** `double`。
- **副作用：** 无。
- **算法：** `0` 映射到 `0`；否则 `sign(value) * log10(|value| + 1)`——`+1` 让变换在零处定义且连续（避免 `log(0)`）。
- **用法：**
  ```dart
  final transformedMinY = _logTransform(bounds.minY);
  FlSpot(spot.x, _logTransform(spot.y)),
  ```
  （在 `_buildCostChart` 中，应用于轴边界和每个绘制点）。
- **备注：** log1p 变换的带符号变体——支持负值（成本不应出现，但变换不假设非负）。

### `double _logInverse(double value)` <a id="loginverse"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6296 行）
- **用途：** 反转 `_logTransform`，把对数刻度图表坐标转换回真实成本值。
- **输入：** `value`。
- **返回：** `double`。
- **副作用：** 无。
- **算法：** `0` 映射到 `0`；否则 `sign(value) * (10^|value| - 1)`——`sign * log10(|value| + 1)` 的精确逆。
- **用法：**
  ```dart
  _axisText(_logInverse(value)),
  '${item.label}: ${_moneyText(_logInverse(spot.y))}',
  ```
  （`_buildCostChart` 中的轴标签和工具提示）。
- **备注：** 必须与 `_logTransform` 保持精确代数同步——源码注释显式标记（"Mirrors `_logTransform`"）。

### `double _dateInterval(double minX, double maxX)` <a id="dateinterval"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6307 行）
- **用途：** 返回缩放到可见 x 范围的底部轴日期标签间隔（毫秒），使标签绝不拥挤。
- **输入：** `minX`、`maxX`（图表 x 坐标，即纪元毫秒）。
- **返回：** `double` 毫秒。
- **副作用：** 无。
- **算法：** 把跨度转换为天数，然后步进升序天数阈值（`<=7` → 2 天标签、`<=30` → 每周、`<=90` → 21 天、`<=180` → 45 天、`<=365` → 90 天、`<=730` → 180 天、否则每年）。
- **用法：** 作为 `_buildCostChart` 中图表底部轴 `interval` 传入。
- **备注：** 与 [`IntimacyTrendChart._dateInterval`](../widgets/intimacy_trend_chart.md#dateinterval) 相同的宽阈值设计意图，但以天数阈值而非毫秒跨度公式表达。

### `String _dateLabel(DateTime date, double minX, double maxX, String localeName)` <a id="datelabel"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6324 行）
- **用途：** 格式化图表日期轴标签，基于可见范围宽度选择精度。
- **输入：** `date`、`minX`、`maxX`、`localeName`。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** 计算 `spanDays`；`> 730` 天用 `yyyy`-only 格式、`> 365` 天用 `M/yy`、否则 `M/d`——全部经语言区域感知 `intl` `DateFormat` 格式化。
- **用法：**
  ```dart
  _dateLabel(date, minX, maxX, l10n.localeName),
  ```
  （`_buildCostChart` 中底部轴刻度标签）。
- **备注：** 无。

### `String _axisText(double value)` <a id="axistext"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6351 行）
- **用途：** 紧凑格式化 y 轴成本值，使大数字仍适合窄左轴。
- **输入：** `value`。
- **返回：** `String` — 百万为 `"1.2m"` 风格、千为 `"3.4k"`、否则普通整数；负值保留前导 `-`。
- **副作用：** 无。
- **算法：** 按 `abs(value)` 阈值分支（`>= 1_000_000` → 除以 1e6 并加 `m` 后缀；`>= 1_000` → 除以 1e3 并加 `k` 后缀；否则普通 `toStringAsFixed(0)`）。
- **用法：**
  ```dart
  _axisText(_logInverse(value)),
  ```
  （`_buildCostChart` 中左轴刻度标签，撤销对数变换后应用）。
- **备注：** 无。

### `double _totalCost(List<Toy> toys)` <a id="totalcost"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6364 行）
- **用途：** 对玩具列表求和总记录成本。
- **输入：** `toys`。
- **返回：** `double`。
- **副作用：** 无。
- **算法：** 与 [`_totalToyCost`](#totaltoycost) 相同的折叠求和。
- **用法：**
  ```dart
  _moneyText(_totalCost(toys)),
  ```
  （成本总览页的 `_buildSummaryCard` 中）。
- **备注：** 与 `_totalToyCost` 不同类中不同名称的相同计算——无功能差异。

### `double? _totalDailyCost(List<Toy> toys)` <a id="totaldailycost"></a>
- **种类：** `_ToyCostOverviewPageState` 的方法
- **来源：** `lib/features/intimacy/views/intimacy_page.dart`（第 6372 行）
- **用途：** 可计算时对玩具列表求和平均每日成本。
- **输入：** `toys`。
- **返回：** `double?` — 无玩具同时有价格和购买日期时为 `null`。
- **副作用：** 无。
- **算法：** 与 [`_totalDailyToyCost`](#totaldailytoycost) 相同：非 null 处累积 `toy.averageDailyCost()`，经 `hasDailyCost` 标志跟踪，使全 null 结果返回 `null` 而非 `0`。
- **用法：**
  ```dart
  final dailyCost = _totalDailyCost(toys);
  ```
  （成本总览页的 `_buildSummaryCard` 中）。
- **备注：** 除上面交叉引用外无。

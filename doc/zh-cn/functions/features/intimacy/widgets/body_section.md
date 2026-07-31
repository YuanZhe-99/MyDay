# lib/features/intimacy/widgets/body_section.dart

`BodySectionView` 是 [亲密 — 身体层](../../../../features/intimacy.md#the-body-layer-v124) 描述的两个身体表面背后唯一的共享组件：用户自己的 `views/body_page.dart`（`BodySettingsPage`）和伴侣详情页的**身体**标签。它渲染四个卡片——测量+腰臀比、罩杯估算、周期跟踪和 PSI——由 `services/body_metrics.dart`（`estimateBraSize`、`calculatePsi`）和 `services/cycle_predictor.dart`（`predictCycle`）驱动，两者都在 [身体指标](../../../../algorithms/body-metrics.md) 中算法性覆盖。它从 `cycle_calendar.dart` 嵌入 `CycleCalendar`/`CycleLegend` 供逐人日历，本文件正是 `cyclePersonColor` 稳定调色板函数实际所在之处（`cycle_calendar.dart` 只拥有它读取的 `cyclePersonPalette` 常量）。文件两大最具特色的真实逻辑——除普通卡片组件构建外——是**体重同步警告 + 防抖**，让用户自己的胸/腰/臀字段兼作体重模块编辑器（`_confirmWeightSync`/`_onMeasurementChanged`/`_commitWeightRecord`），以及每个测量卡片使用的共享 `_NumberField` 自动提交输入。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`cyclePersonColor`](#cyclepersoncolor) | 顶层函数 | A | 为一个人挑选稳定周期指示器颜色（用户 = 槽 0，伴侣按排序 id）。 |
| `BodySectionView`（构造函数） | 构造函数（`BodySectionView`） | B | 为给定模式/档案/人创建身体小节视图实例。 |
| `BodySectionView.createState` | 方法（`BodySectionView`） | B | 创建可变 `_BodySectionViewState`。 |
| `_profile` | getter（`_BodySectionViewState`） | B | 返回 `widget.profile`，默认为空 `BodyProfile()`。 |
| [`initState`](#initstate) | 方法（`_BodySectionViewState`） | A | 用户模式加载体重测量，或伴侣模式直接从伴侣档案播种本地字段。 |
| [`dispose`](#dispose) | 方法（`_BodySectionViewState`） | A | 状态被拆除前冲刷任何挂起的防抖体重记录提交。 |
| [`_loadUserMeasurements`](#loadusermeasurements) | 方法（`_BodySectionViewState`） | A | 从体重记录加载用户最新胸/腰/臀和同步警告退出标志。 |
| [`_latestRecord`](#latestrecord) | 方法（`_BodySectionViewState`） | A | 按 datetime 返回最新 `WeightRecord`。 |
| [`_setSyncWarningDisabled`](#setsyncwarningdisabled) | 方法（`_BodySectionViewState`） | A | 把体重同步警告退出标志持久化到 `storage_config.json`。 |
| [`_confirmWeightSync`](#confirmweightsync) | 方法（`_BodySectionViewState`） | A | 把用户模式首次测量编辑门控在体重同步警告对话框之后。 |
| [`_onMeasurementChanged`](#onmeasurementchanged) | 方法（`_BodySectionViewState`） | A | 应用测量变更并安排防抖体重提交（用户模式）或立即推档案（伴侣模式）。 |
| [`_commitWeightRecord`](#commitweightrecord) | 方法（`_BodySectionViewState`） | A | 从当前显示测量追加一条新 `WeightRecord`。 |
| `_myCycleDays` | getter（`_BodySectionViewState`） | B | 返回此人的记录周期开始日作为去重 `Set<DateTime>`。 |
| [`_prediction`](#prediction) | getter（`_BodySectionViewState`） | A | 在历史到 13 个月后的窗口上计算此人的 `CyclePrediction`。 |
| [`_addCycleStart`](#addcyclestart) | 方法（`_BodySectionViewState`） | A | 为所选日历日期添加周期开始 `CycleRecord`，拒绝重复。 |
| [`_deleteCycleStart`](#deletecyclestart) | 方法（`_BodySectionViewState`） | A | 确认后删除所选日期的周期开始记录。 |
| `_updateProfile` | 方法（`_BodySectionViewState`） | B | 把 `BodyProfile` 变更转发给 `widget.onProfileChanged`。 |
| `build` | 方法（`_BodySectionViewState`） | B | 把测量/罩杯/周期/PSI 卡片加底部警告设置卡片组合进 `Column`。 |
| `_buildMeasurementsCard` | 方法（组件辅助） | B | 构建带只读腰臀比行的胸/腰/臀测量卡片。 |
| `_buildBraCard` | 方法（组件辅助） | B | 构建下胸围输入、罩杯标准选择器和估算尺寸显示。 |
| `_showBraHelp` | 方法（`_BodySectionViewState`） | B | 打开解释每个受支持罩杯标准加估算免责声明的对话框。 |
| `_buildCycleCard` | 方法（组件辅助） | B | 构建周期跟踪开关、日历、图例和添加/删除开始操作行。 |
| [`_selectedCycleDateSummary`](#selectedcycledatesummary) | 方法（`_BodySectionViewState`） | A | 把所选日历日期的阶段/排卵/生育窗口/预测开始状态总结为一行。 |
| `_buildPsiCard` | 方法（组件辅助） | B | 构建勃起长度/周长输入和计算的 PSI 显示。 |
| `_buildWarningSettingCard` | 方法（组件辅助） | B | 构建底部"不再提醒我"设置卡片（仅用户模式）。 |
| `_NumberField`（构造函数） | 构造函数（`_NumberField`） | B | 创建自动提交可选十进制输入字段实例。 |
| `_NumberField.createState` | 方法（`_NumberField`） | B | 创建可变 `_NumberFieldState`。 |
| `_NumberFieldState.initState` | 方法（`_NumberFieldState`） | B | 从初始值播种文本控制器并注册焦点监听器。 |
| [`didUpdateWidget`](#didupdatewidget) | 方法（`_NumberFieldState`） | A | 外部值在字段未激活聚焦时变化则刷新显示文本。 |
| `_NumberFieldState.dispose` | 方法（`_NumberFieldState`） | B | 取消防抖计时器、冲刷最终提交并释放控制器/焦点节点。 |
| [`_format`](#format) | 方法（`_NumberFieldState`） | A | 格式化 `double?` 供显示，去掉尾部 `.0`。 |
| [`_onFocusChanged`](#onfocuschanged) | 方法（`_NumberFieldState`） | A | 焦点一离开就提交字段文本。 |
| [`_commit`](#commit) | 方法（`_NumberFieldState`） | A | 解析当前文本，只在解析值实际变化时调用 `onCommitted`。 |
| [`_handleTap`](#handletap) | 方法（`_NumberFieldState`） | A | 让字段聚焦前运行可选一次性编辑门（体重同步警告）。 |
| `_NumberFieldState.build` | 方法（组件辅助） | B | 渲染 `TextField`，可选包在点击门控 `GestureDetector`/`AbsorbPointer` 中。 |

`grep -c 'Purpose:' lib/features/intimacy/widgets/body_section.dart` 报告 34。本页列出 35 个声明：全部 34 个 `/// Purpose:` 块都恰好位于其文档化的真实声明正上方（未发现错附块），加一个未文档化的真实声明——`_profile`（第 101 行），一个完全没有文档注释的普通 getter（`BodyProfile get _profile => widget.profile ?? const BodyProfile();`）。Tier 划分：18 个 Tier A、17 个 Tier B。

**对账：** `grep -c 'Purpose:' lib/features/intimacy/widgets/body_section.dart` 报告 34，与上面 35 行中的 34 行精确匹配。额外行是 `bodyWeightSyncWarningDisabledKey`，一个持有仅本地 `storage_config.json` 键的顶层 `const String`：无 `Purpose:` 块，但被两处读取的真实声明，因此被列出。

## 文档

### `Color cyclePersonColor({required String? personId, required List<String> allPartnerIdsSorted})` <a id="cyclepersoncolor"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 33 行）
- **用途：** 为一个人在应用处处（身体标签日历、主页日历叠加）的周期指示器挑选稳定调色板颜色。
- **输入：** `personId` — 用户为 `null`，否则是伴侣 id；`allPartnerIdsSorted` — 每个伴侣 id，预排序，用于为 `personId` 派生稳定槽位。
- **返回：** `Color` — 来自 `cyclePersonPalette`（定义在 `cycle_calendar.dart`）的值。
- **副作用：** 无。
- **算法：**
  1. `personId == null`（用户）时返回 `cyclePersonPalette.first`（槽 0）。
  2. 否则在 `allPartnerIdsSorted` 中找 `personId` 的位置（`indexOf`，缺席为 `-1`）。
  3. 取 `slots = cyclePersonPalette.length - 1`（除用户外的所有槽位）。
  4. 返回 `cyclePersonPalette[1 + ((index < 0 ? 0 : index) % slots)]`——缺席 id 回退槽 1 而不是抛出，超出调色板长度的 id 经取模回绕。
- **用法：**
  ```dart
  // views/body_page.dart, line 70 (the user's own Body page):
  personColor: cyclePersonColor(personId: null, allPartnerIdsSorted: const []),

  // views/intimacy_page.dart, line 5570 (a partner's Body tab):
  personColor: cyclePersonColor(personId: partner.id, allPartnerIdsSorted: allPartnerIds),
  ```
- **备注：** 因为槽位基于排序 id 位置而非列表顺序，即使伴侣被添加/移除或可见伴侣列表被过滤（如按 `showCycleOnCalendar`），一个人的颜色也保持稳定。

### `void initState()` <a id="initstate"></a>
- **种类：** `_BodySectionViewState` 的方法（`State.initState` 的覆盖）
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 109 行）
- **用途：** 初始化显示的测量——用户模式来自体重模块，伴侣模式直接从 `widget.profile`。
- **输入：** 无（读取 `widget.mode`、`widget.profile`）。
- **返回：** 无。
- **副作用：** 用户模式启动异步 `_loadUserMeasurements()`。伴侣模式同步设置 `_bust`/`_waist`/`_hip` 并标记加载完成。
- **算法：**
  1. `super.initState()`。
  2. `widget.mode == BodySectionMode.user` 时调用 `_loadUserMeasurements()`（即发即忘异步）。
  3. 否则把 `_profile.bustCm`/`waistCm`/`hipCm` 直接复制进本地状态并立即设 `_weightLoaded = true`（伴侣档案无需异步加载）。
- **用法：**
  ```dart
  // views/body_page.dart, line 66 (constructing the widget triggers initState via the framework):
  BodySectionView(
    mode: BodySectionMode.user,
    profile: _userBody,
    personId: null,
    personColor: cyclePersonColor(personId: null, allPartnerIdsSorted: const []),
    ...
  ),
  ```
- **备注：** 伴侣模式绝不碰 `WeightStorage`——这是让用户自己的测量（住在体重模块）和伴侣的测量（住在 `Partner.body`）绝不交叉的划分点。

### `void dispose()` <a id="dispose"></a>
- **种类：** `_BodySectionViewState` 的方法（`State.dispose` 的覆盖）
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 127 行）
- **用途：** 确保页面关闭前刚做的测量编辑仍产生其体重记录，而不是被防抖计时器静默丢弃。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 取消 `_weightCommitTimer`；提交仍挂起时即发即忘调用 `_commitWeightRecord()`（组件已在卸载）。
- **算法：**
  1. 取消 `_weightCommitTimer`，使它不能在被释放后触发。
  2. `_weightCommitPending` 时不做 await 地调用 `_commitWeightRecord()`——源码注释说明这是刻意的："页面要走了，但爆发必须仍产生其体重记录"。
  3. `super.dispose()`。
- **用法：** `BodySectionView` 从树中移除时由 Flutter 框架自动调用（如编辑测量后立即从 `BodySettingsPage` 返回）。
- **备注：** 这是 `_onMeasurementChanged` 实现的防抖的另一半：没有此冲刷，用户在 2 秒防抖窗口内输入新腰围并立即退出页面会完全丢失那次编辑。

### `Future<void> _loadUserMeasurements()` <a id="loadusermeasurements"></a>
- **种类：** `_BodySectionViewState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 145 行）
- **用途：** 从体重记录加载用户最近胸/腰/臀值（逐字段独立），加同步警告退出标志。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 经 `WeightStorage.load()` 读取 `weight_data.json`、经 `TodoStorage.readConfig()` 读取 `storage_config.json`；更新 `_bust`/`_waist`/`_hip`、其 `_persisted*` 镜像、`_weightLoadFailed`、`_syncWarningDisabled` 和 `_weightLoaded`。
- **算法：**
  1. `WeightStorage.load()`；任何异常时设 `_weightLoadFailed = true`、`_weightLoaded = true` 并提前返回——测量字段渲染为禁用而不是误导性的空。
  2. 否则读取 `TodoStorage.readConfig()` 取同步警告标志。
  3. 经 `_latestRecord` 找最新记录，然后调用 `WeightData.effectiveMeasurementsUpTo(records, latest.datetime)` 让胸/腰/臀各自独立作为截至该 datetime 的最近*正*值（缺失某字段的较新记录回退到有它的较早记录——这是 `WeightData` 自己的合并逻辑，不在这里重新实现）。
  4. 把结果存储进 `_bust`/`_waist`/`_hip` 并镜像进 `_persistedBust`/`Waist`/`Hip`（`_commitWeightRecord` 失败时恢复到的基线）。
  5. 从 `config[bodyWeightSyncWarningDisabledKey] == true` 设置 `_syncWarningDisabled` 并标记 `_weightLoaded = true`。
- **用法：**
  ```dart
  // initState, line 112 (user mode only):
  _loadUserMeasurements();
  ```
- **备注：** 每个 `await` 后所有 `setState` 调用都由 `if (!mounted) return;` 守卫，因为组件可能在加载完成前被释放。

### `WeightRecord? _latestRecord(List<WeightRecord> records)` <a id="latestrecord"></a>
- **种类：** `_BodySectionViewState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 183 行）
- **用途：** 按 datetime 返回最新体重记录，没有则 `null`。
- **输入：** `records` — 完整体重记录列表。
- **返回：** `WeightRecord?`。
- **副作用：** 无。
- **算法：**
  1. `records` 为空时立即返回 `null`。
  2. 复制列表，按 `datetime` 降序排序（`b.datetime.compareTo(a.datetime)`），返回第一个元素。
- **用法：**
  ```dart
  // _loadUserMeasurements, line 162:
  final latest = _latestRecord(records);

  // _commitWeightRecord, line 303:
  final latest = _latestRecord(data.records);
  ```
- **备注：** 匹配体重页别处使用的排序，因此"最新"在两处含义相同。

### `Future<void> _setSyncWarningDisabled(bool disabled)` <a id="setsyncwarningdisabled"></a>
- **种类：** `_BodySectionViewState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 195 行）
- **用途：** 持久化体重同步警告的"不再提醒我"退出。
- **输入：** `disabled` — 新退出状态。
- **返回：** `Future<void>`。
- **副作用：** 更新状态中的 `_syncWarningDisabled`/`_syncWarningAcknowledged`；把 `bodyWeightSyncWarningDisabledKey` 写入 `storage_config.json`（仅本地，绝不同步）。
- **算法：**
  1. `setState` 更新 `_syncWarningDisabled`；重新启用（`!disabled`）时也清除 `_syncWarningAcknowledged`，使警告在下一次编辑时重新出现。
  2. 读取配置、设置键、写回。
- **用法：**
  ```dart
  // _buildWarningSettingCard, line 1012 (the bottom switch):
  SwitchListTile(
    value: _syncWarningDisabled,
    onChanged: _setSyncWarningDisabled,
    ...
  ),
  ```
- **备注：** 用户在警告对话框本身勾选"不再提醒我"时也从 `_confirmWeightSync` 内部调用。

### `Future<bool> _confirmWeightSync()` <a id="confirmweightsync"></a>
- **种类：** `_BodySectionViewState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 210 行）
- **用途：** 把一次访问中的首次胸/腰/臀编辑门控在警告这些字段编辑会创建新体重模块记录的警告之后。
- **输入：** 无。
- **返回：** `Future<bool>` — 编辑可以进行时 `true`。
- **副作用：** 可能显示带"不再提醒我"复选框的 `AlertDialog`；可能调用 `_setSyncWarningDisabled(true)`。
- **算法：**
  1. `_syncWarningDisabled` 或 `_syncWarningAcknowledged` 已为 true 时立即返回 `true`（本次访问的门已过，或已永久退出）。
  2. 否则显示带警告文本和绑定本地 `dontRemind` 标志复选框的对话框。
  3. 用户确认时：设 `_syncWarningAcknowledged = true`（使门在本次访问剩余时间不重新显示，即使未永久退出）；勾选 `dontRemind` 时也经 `_setSyncWarningDisabled(true)` 持久化永久退出。返回 `true`。
  4. 用户取消时返回 `false`。
- **用法：**
  ```dart
  // _buildMeasurementsCard, line 491 (passed as the field's edit gate, user mode only):
  _NumberField(
    label: l10n.weightBust,
    value: _bust,
    enabled: !_weightLoadFailed,
    beforeEdit: isUser ? _confirmWeightSync : null,
    onCommitted: (v) => _onMeasurementChanged(() => _bust = v),
  ),
  ```
- **备注：** 只为用户模式的胸/腰/臀接线——伴侣模式字段和用户模式其他每个字段（下胸围、PSI 测量）传 `beforeEdit: null`。

### `void _onMeasurementChanged(void Function() apply)` <a id="onmeasurementchanged"></a>
- **种类：** `_BodySectionViewState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 262 行）
- **用途：** 应用胸/腰/臀变更，用户模式防抖成单条新体重记录而不是每次击键都写。
- **输入：** `apply` — 修改挂起 `_bust`/`_waist`/`_hip` 字段的闭包。
- **返回：** 无。
- **副作用：** 用户模式武装/重置最终调用 `_commitWeightRecord()` 的 2 秒 `Timer`；伴侣模式立即调用 `widget.onProfileChanged`。
- **算法：**
  1. `mounted` 时在 `setState` 内运行 `apply()`；否则（提交在路由拆除期间到达，如来自字段自己的 `dispose`）不做 `setState` 直接运行 `apply()`。
  2. `widget.mode == BodySectionMode.user` 时：设 `_weightCommitPending = true`、取消任何既有 `_weightCommitTimer`、启动调用 `_commitWeightRecord()` 的 `Duration(seconds: 2)` 新计时器——该窗口内每次额外变更都把提交再推后 2 秒，因此编辑爆发坍缩为恰好一条体重记录。
  3. 否则（伴侣模式）：立即为三个字段推 `_profile.copyWith(...)`，带 `clearXxxCm: v == null`，使清空字段实际移除它，而不是在过期值上存储 `null`。
- **用法：**
  ```dart
  // _buildMeasurementsCard, line 492:
  onCommitted: (v) => _onMeasurementChanged(() => _bust = v),
  ```
- **备注：** 这是 [亲密 — 身体层](../../../../features/intimacy.md#the-body-layer-v124) 描述的防抖："确认的编辑爆发防抖为恰好一条新 `WeightRecord`"。历史体重记录绝不被此路径修改——只有新记录被 `_commitWeightRecord` 追加。

### `Future<void> _commitWeightRecord()` <a id="commitweightrecord"></a>
- **种类：** `_BodySectionViewState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 298 行）
- **用途：** 追加一条携带当前显示胸/腰/臀值的新 `WeightRecord`。
- **输入：** 无（读取 `_bust`/`_waist`/`_hip`）。
- **返回：** `Future<void>`。
- **副作用：** 经 `WeightStorage.save` 向 `weight_data.json` 追加记录；成功时调用 `AutoSyncService.instance.notifySaved()`；既有记录和体重设置（`height`、提醒配置等）原样复制通过。
- **算法：**
  1. `!_weightCommitPending` 时立即返回（已提交，或被更晚调用取代）。
  2. 先清除挂起标志，然后 `WeightStorage.load() ?? WeightData(records: [])`。
  3. 构建复用 `latest?.weight ?? 0`（记录的体重字段不被此功能触碰；只有胸/腰/臀来自身体页）加当前 `_bust`/`_waist`/`_hip` 的新 `WeightRecord`。
  4. 构造复制加载数据其他每个字段并追加新记录的 `WeightData`，然后 `WeightStorage.save(next)`。
  5. 任何异常时：仍 `mounted` 则 `setState` 把 `_bust`/`_waist`/`_hip` 回滚到 `_persisted*` 值并设 `_weightLoadFailed = true`；未挂载则不做 `setState` 做同样的事。不更新 `_persisted*` 或通知同步地返回。
  6. 成功时：把 `_persistedBust`/`Waist`/`Hip` 更新为刚提交的值并调用 `AutoSyncService.instance.notifySaved()`。
- **用法：**
  ```dart
  // _onMeasurementChanged, line 273-275 (the debounce timer body):
  _weightCommitTimer = Timer(const Duration(seconds: 2), () {
    _commitWeightRecord();
  });
  ```
- **备注：** 失败保存经 `_weightLoadFailed` 禁用字段并恢复最后已知良好显示值，"使部分内存状态绝不显得已保存"（源码注释）——UI 绝不把未保存编辑显示为已持久化。

### `CyclePrediction get _prediction` <a id="prediction"></a>
- **种类：** `_BodySectionViewState` 的 getter
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 360 行）
- **用途：** 为此人计算周期预测供日历/图例/摘要渲染。
- **输入：** 无（读取 `_myCycleDays`）。
- **返回：** `CyclePrediction` — 无记录历史时 `CyclePrediction.empty`。
- **副作用：** 无（预测每次访问重新计算，绝不缓存）。
- **算法：**
  1. `_myCycleDays` 为空时返回 `CyclePrediction.empty`。
  2. 否则找最早记录日（`days.reduce((a, b) => a.isBefore(b) ? a : b)`）。
  3. 调用 `predictCycle(actualStarts: days, windowStart: DateTime(earliest.year, earliest.month - 1, 1), windowEnd: DateTime.now().add(const Duration(days: 400)))`——完整锚定/阶段/生育窗口算法见 [身体指标 — 周期预测](../../../../algorithms/body-metrics.md#cycle-prediction)。
- **用法：**
  ```dart
  // _buildCycleCard, line 752:
  final prediction = enabled ? _prediction : CyclePrediction.empty;
  ```
- **备注：** 窗口从最早记录前一个月开始、延伸到现在之后约 13 个月，因此单人日历（不同于主页日历）无需逐月重算就能同时深入浏览过去和未来。

### `void _addCycleStart()` <a id="addcyclestart"></a>
- **种类：** `_BodySectionViewState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 376 行）
- **用途：** 为日历当前选中的记录周期开始日。
- **输入：** 无（读取 `_selectedCycleDate`）。
- **返回：** 无。
- **副作用：** 用追加的 `CycleRecord` 调用 `widget.onCycleRecordsChanged`。
- **算法：**
  1. 未选日期，或 `_myCycleDays` 已包含它时，什么都不做地返回（静默拒绝同一人/日期的重复开始）。
  2. 否则向 `widget.cycleRecords` 追加新 `CycleRecord(personId: widget.personId, date: CycleRecord.formatDate(date))` 并把新列表推上去。
- **用法：**
  ```dart
  // _buildCycleCard, line 822-826:
  FilledButton.tonalIcon(
    onPressed: _addCycleStart,
    icon: const Icon(Icons.add, size: 18),
    label: Text(l10n.intimacyCycleAddStart),
  ),
  ```
- **备注：** 新记录在 `CycleRecord` 构造函数内获得自己生成的 id/`modifiedAt`；此方法只追加，绝不修改既有记录。

### `Future<void> _deleteCycleStart()` <a id="deletecyclestart"></a>
- **种类：** `_BodySectionViewState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 393 行）
- **用途：** 确认后删除当前所选日期的周期开始记录。
- **输入：** 无（读取 `_selectedCycleDate`）。
- **返回：** `Future<void>`。
- **副作用：** 显示共享 `confirmDelete` 对话框；用过滤掉该记录的列表调用 `widget.onCycleRecordsChanged`。
- **算法：**
  1. 未选任何东西时提前返回。
  2. 把日期格式化为本地化标签并 await `confirmDelete(context, label)`；拒绝则返回。
  3. 把日期格式化为规范 `CycleRecord.formatDate` 字符串，重建 `widget.cycleRecords`，排除同时匹配 `personId` 和该日期字符串的记录。
- **用法：**
  ```dart
  // _buildCycleCard, line 815-820:
  TextButton.icon(
    onPressed: _deleteCycleStart,
    icon: const Icon(Icons.delete_outline, size: 18),
    label: Text(l10n.commonDelete),
  ),
  ```
- **备注：** 删除（而不是"撤销添加"）也是周期记录从同步消失的方式——见 [三方合并 — 删除/并集语义](../../../../algorithms/three-way-merge.md#deletionunion-semantics)。

### `String _selectedCycleDateSummary(AppLocalizations l10n, DateTime date, CycleDayInfo? info, bool hasRecord)` <a id="selectedcycledatesummary"></a>
- **种类：** `_BodySectionViewState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 871 行）
- **用途：** 为日历上选中的任何日期产生添加/删除开始操作按钮旁显示的一行摘要。
- **输入：** `l10n`；`date` — 所选日期；`info` — 该日期的 `CycleDayInfo` 或 `null`；`hasRecord` — 此人是否有那天实际记录的开始。
- **返回：** `String`。
- **副作用：** 无。
- **算法：**
  1. 把 `date` 格式化为本地化短日期（`DateFormat.yMMMd`）。
  2. `hasRecord` 时立即返回 `"<date> · <实际开始标签>"`——实际记录总是胜过任何预测分类。
  3. `info == null`（那天完全没有周期数据）时只返回日期标签。
  4. 否则构建部分列表：`info.isPredictedStart` 时预测开始标签；阶段标签（对 `menstrual`/`follicular`/`luteal` 的 `switch`）；`info.isOvulationDay` 时排卵标签；`info.inFertileWindow` 时生育窗口标签。
  5. 用 `" · "` 连接并追加"估计"后缀标签。
- **用法：**
  ```dart
  // _buildCycleCard, line 806-811:
  Text(
    _selectedCycleDateSummary(l10n, selected, selectedInfo, selectedHasRecord),
    style: theme.textTheme.bodyMedium,
  ),
  ```
- **备注：** 除实际开始情形外每个分支都以"估计"后缀结束，匹配概念文档"预测是统计估计"且绝不能读作确定的说明。

### `void didUpdateWidget(covariant _NumberField oldWidget)` <a id="didupdatewidget"></a>
- **种类：** `_NumberFieldState` 的方法（`State.didUpdateWidget` 的覆盖）
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 1080 行）
- **用途：** 父级从外部提供新 `value`（如成功提交把新值往返传回）时保持显示文本同步，不覆盖进行中的编辑。
- **输入：** `oldWidget` — 先前组件配置（除覆盖签名外未使用）。
- **返回：** 无。
- **副作用：** 可能重置 `_controller.text` 和 `_lastCommitted`。
- **算法：**
  1. `super.didUpdateWidget(oldWidget)`。
  2. `widget.value != _lastCommitted` **且**（`!_focusNode.hasFocus || !widget.enabled`）时，更新 `_lastCommitted` 并从新值重新格式化 `_controller.text`。
  3. 否则不动控制器——活跃聚焦、启用字段的进行中文本绝不被从用户脚下覆盖。
- **用法：** 既有 `_NumberField` 的 `value` 参数跨重建变化时由 Flutter 框架自动调用，如 `_buildMeasurementsCard` 带刚加载的 `_bust` 重建时。
- **备注：** 确实覆盖聚焦字段的唯一情形是 `!widget.enabled`——即刚在持久化尝试失败（`_weightLoadFailed`）后被禁用的字段仍会在聚焦时把文本重置为回滚值，因为它反正已不可编辑。

### `String _format(double? value)` <a id="format"></a>
- **种类：** `_NumberFieldState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 1108 行）
- **用途：** 格式化测量值供显示，不带不必要的尾部 `.0`。
- **输入：** `value` — 要格式化的值，或 `null`。
- **返回：** `String` — `null` 为空。
- **副作用：** 无。
- **算法：**
  1. `value == null` 时返回 `''`。
  2. `value == value.roundToDouble()`（整数）时返回 `value.toInt().toString()`；否则 `value.toString()`。
- **用法：**
  ```dart
  // _NumberFieldState.initState, line 1069:
  _controller = TextEditingController(text: _format(widget.value));
  ```
- **备注：** `null` 渲染为空字段而不是字面 `"null"`，使每个测量真正可选。

### `void _onFocusChanged()` <a id="onfocuschanged"></a>
- **种类：** `_NumberFieldState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 1120 行）
- **用途：** 字段一失焦就提交其当前文本，而不是等输入暂停防抖。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 可能取消挂起防抖并调用 `_commit()`。
- **算法：** `!_focusNode.hasFocus` 时取消 `_debounce` 并调用 `_commit()`。
- **用法：**
  ```dart
  // _NumberFieldState.initState, line 1070:
  _focusNode.addListener(_onFocusChanged);
  ```
- **备注：** 失焦提交意味着从字段 tab 走（而不是等完 1.5 秒输入暂停计时器）仍及时保存值。

### `void _commit()` <a id="commit"></a>
- **种类：** `_NumberFieldState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 1132 行）
- **用途：** 解析字段当前文本，只在解析值实际变化时调用字段的 `onCommitted` 回调。
- **输入：** 无（读取 `_controller.text`）。
- **返回：** 无。
- **副作用：** 可能调用 `widget.onCommitted(parsed)`；更新 `_lastCommitted`。
- **算法：**
  1. 修剪文本；空文本解析为 `null`。
  2. 否则 `double.tryParse`；不可解析或为负时什么都不提交地返回（过期无效文本保持原地，直到它变有效）。
  3. 解析的 `0` 规范化为 `null`（`parsed = value > 0 ? value : null`）——零和空同样当作"未记录"。
  4. `parsed == _lastCommitted` 时返回（无冗余提交）。
  5. 否则更新 `_lastCommitted` 并调用 `widget.onCommitted(parsed)`。
- **用法：**
  ```dart
  // build, line 1191-1194 (the typing-pause debounce):
  onChanged: (_) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _commit);
  },
  ```
- **备注：** 这是 `_onMeasurementChanged` 的 2 秒体重记录防抖的字段级对应物——这个是决定提交*是否*触发的 1.5 秒逐字段文本防抖；`_onMeasurementChanged` 随后决定用户模式提交*如何*被批处理进体重记录。

### `Future<void> _handleTap()` <a id="handletap"></a>
- **种类：** `_NumberFieldState` 的方法
- **来源：** `lib/features/intimacy/widgets/body_section.dart`（第 1152 行）
- **用途：** 让字段取得焦点前运行字段可选的一次性编辑门（体重同步警告）。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 可能显示门对话框（经 `widget.beforeEdit`）；请求字段焦点。
- **算法：**
  1. 门已在本访问通过（`_gatePassed`）或无门（`widget.beforeEdit == null`）时立即请求焦点并返回。
  2. 否则 `await widget.beforeEdit!()`；组件已卸载或门返回 `false` 时不聚焦地停止。
  3. 否则设 `_gatePassed = true` 并请求焦点。
- **用法：**
  ```dart
  // build, line 1198 (only when beforeEdit != null and the field isn't gated-through yet):
  return GestureDetector(
    onTap: _handleTap,
    child: AbsorbPointer(child: field),
  );
  ```
- **备注：** `_gatePassed` 是逐 `_NumberFieldState` 实例的，因此胸/腰/臀各自在访问中首次被点击时独立运行警告——与概念文档"父级按访问去重"措辞一致，意思是确认（`_BodySectionViewState` 上的 `_syncWarningAcknowledged`）是三个字段间实际共享的东西，不是逐字段门。

## 相关页面

- [亲密 — 身体层](../../../../features/intimacy.md#the-body-layer-v124) — 本文件实现的 UI 契约（处处自动保存、体重同步警告、腰臀比显示、周期默认）。
- [身体指标](../../../../algorithms/body-metrics.md) — 本文件卡片调用的罩杯、PSI 和周期预测算法（`estimateBraSize`、`calculatePsi`、`predictCycle`）。
- [`cycle_calendar.dart`](cycle_calendar.md) — `CycleCalendar`/`CycleLegend`，嵌入这里供逐人日历；本文件经 `cyclePersonColor` 提供它和主页日历都使用的颜色。
- [`body_page.dart`](../views/body_page.md) — 用户模式托管此组件。
- [三方合并](../../../../algorithms/three-way-merge.md) — `_deleteCycleStart` 引用的周期记录并集/删除语义。

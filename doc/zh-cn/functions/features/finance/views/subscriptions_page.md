# lib/features/finance/views/subscriptions_page.dart

财务功能的订阅列表视图：`SubscriptionsPage`（页面外壳）及其 `_SubscriptionsPageState`，它拥有激活/历史订阅列表、三种排序模式（下次续费、名称、拖拽重排自定义顺序）、摘要统计（月度应付、月度平均、年度平均）、续费提醒时间设置、即将续费 chip 行，以及完整的增/改/取消/恢复/删除订阅生命周期。三个小型 `StatelessWidget`（`_SectionHeader`、`_SummaryCard`、`_SubscriptionTile`）渲染列表。计费日期计算本身（`calculateNextBillingDate`、`billingDatesBefore`、月末钳制）位于 [`Subscription`](../models/finance.md#subscription-new)，只从这里调用、不重新实现；实际生成当日交易的小时追赶/幂等计费趟是 [`SubscriptionProcessor`](../services/subscription_processor.md)，导入历史时本文件复用其 `billingDateKey`/`transactionIdForBilling`。本页在模块中的位置见 [财务](../../../../features/finance.md#views-and-analysis-page)，本页下次计费日期计算依赖的月末钳制和幂等计费日算法见 [订阅计费](../../../../algorithms/subscription-billing.md)。

本文件是 [财务](../../../../features/finance.md#views-and-analysis-page) 描述的取消/恢复状态机的具体实现：订阅可以立即或到期时取消；待定的到期时取消可以在原地撤销；完全历史（非激活）订阅通过把其设置复制进**新**激活订阅来恢复，而不是修改旧的。实现那个状态机的大多数方法（`_restoreSubscription`、`_undoAtExpiryCancellation`、`_copyRestoreSubscription`、`_doCancelSubscription`、`_insertNewSubscription`、`_editSubscription`）分类为 Tier A，连同计费统计计算（`_monthlyDue`、`_monthlyAvg`）、排序/重排逻辑、即将续费过滤器、历史交易导入器和 `_SubscriptionTile` 的状态标签计算（它直接反映订阅当前取消状态）。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `SubscriptionsPage`（构造函数） | 构造函数（`SubscriptionsPage`） | B | 创建订阅页实例。 |
| `SubscriptionsPage.createState` | 方法（`SubscriptionsPage`） | B | 创建 `_SubscriptionsPageState`。 |
| `_SubscriptionsPageState.initState` | 方法（`_SubscriptionsPageState`） | B | 从组件复制初始订阅/交易/提醒/排序状态。 |
| [`_active`](#_active) | getter（`_SubscriptionsPageState`） | A | 按当前排序模式排序返回激活订阅。 |
| [`_historical`](#_historical) | getter（`_SubscriptionsPageState`） | A | 返回非激活（取消/过期）订阅。 |
| [`_sortList`](#_sortlist) | 方法（`_SubscriptionsPageState`） | A | 按名称、自定义顺序或下次续费日期原地排序订阅列表。 |
| [`_onSortModeChanged`](#_onsortmodechanged) | 方法（`_SubscriptionsPageState`） | A | 切换排序模式，首次进入自定义模式时从激活列表播种自定义顺序。 |
| [`_monthlyDue`](#_monthlydue) | 方法（`_SubscriptionsPageState`） | A | 求和每个激活订阅的金额，规范化为默认币种的月度成本。 |
| [`_monthlyAvg`](#_monthlyavg) | 方法（`_SubscriptionsPageState`） | A | 从实际计费交易计算平均月度订阅花费，回退投影应付金额。 |
| `_yearlyAvg` | 方法（`_SubscriptionsPageState`） | B | 返回 `_monthlyDue() * 12`。 |
| `_addSubscription` | 方法（`_SubscriptionsPageState`） | B | 打开添加订阅对话框并插入结果。 |
| [`_insertNewSubscription`](#_insertnewsubscription) | 方法（`_SubscriptionsPageState`） | A | 添加新订阅，计算其初始 `nextBillingDate` 并可选导入计费历史。 |
| [`_editSubscription`](#_editsubscription) | 方法（`_SubscriptionsPageState`） | A | 打开编辑对话框，保存时计费参数变化则重新计算 `nextBillingDate`。 |
| [`_restoreSubscription`](#_restoresubscription) | 方法（`_SubscriptionsPageState`） | A | 分派到原地撤销（待定到期时取消）或复制恢复（历史订阅）。 |
| [`_undoAtExpiryCancellation`](#_undoatexpirycancellation) | 方法（`_SubscriptionsPageState`） | A | 重新激活带待定到期时取消的订阅，清除取消。 |
| [`_copyRestoreSubscription`](#_copyrestoresubscription) | 方法（`_SubscriptionsPageState`） | A | 打开从历史订阅预填的编辑对话框并把结果作为全新激活订阅插入。 |
| [`_nextBillingDateFromToday`](#_nextbillingdatefromtoday) | 方法（`_SubscriptionsPageState`） | A | 计算今天或之后的第一个计费日期，作为缺失持久化 `nextBillingDate` 的订阅的回退。 |
| [`_deleteSubscription`](#_deletesubscription) | 方法（`_SubscriptionsPageState`） | A | 移除订阅及其自定义顺序条目，通知两个回调。 |
| `_cancelSubscription` | 方法（组件辅助） | B | 显示立即-vs-到期时取消选择面板。 |
| [`_doCancelSubscription`](#_docancelsubscription) | 方法（`_SubscriptionsPageState`） | A | 应用所选取消类型，计算 `isActive` 并盖章 `cancelledAt`。 |
| [`_importHistoricalTransactions`](#_importhistoricaltransactions) | 方法（`_SubscriptionsPageState`） | A | 为新添加订阅生成历史计费交易，跳过已计费天。 |
| `_openDetail` | 方法（`_SubscriptionsPageState`） | B | 压入 `SubscriptionDetailPage` 并同步回任何交易编辑。 |
| [`_getUpcomingSubs`](#_getupcomingsubs) | 方法（`_SubscriptionsPageState`） | A | 收集 N 天内到期的订阅，排除到期时取消和立即取消非激活的。 |
| [`_buildReorderBody`](#_buildreorderbody) | 方法（组件辅助） | A | 渲染拖拽重排列表并在放下时持久化新自定义顺序。 |
| `build` | 方法（`_SubscriptionsPageState`） | B | 构建脚手架：带排序菜单的应用栏、摘要卡片、即将续费、提醒设置、激活/历史列表、添加 FAB。 |
| `_SectionHeader`（构造函数） | 构造函数（`_SectionHeader`） | B | 创建小节页头实例。 |
| `_SectionHeader.build` | 方法（`_SectionHeader`） | B | 渲染带标签的小节分隔行。 |
| `_SummaryCard`（构造函数） | 构造函数（`_SummaryCard`） | B | 创建摘要卡片实例。 |
| `_SummaryCard.build` | 方法（`_SummaryCard`） | B | 渲染一个图标/标签/数值统计卡片。 |
| `_SubscriptionTile`（构造函数） | 构造函数（`_SubscriptionTile`） | B | 创建订阅块实例。 |
| [`_SubscriptionTile.build`](#build) | 方法（`_SubscriptionTile`） | A | 渲染订阅行，从当前状态计算分类/账户/周期/下次计费/取消标签。 |
| `_showActions` | 方法（`_SubscriptionTile`） | B | 为长按显示编辑/取消/恢复/删除操作面板。 |
| [`_buildLeading`](#_buildleading) | 方法（`_SubscriptionTile`） | A | 经订阅图像 / emoji / 账户图像 / 分类 emoji 回退链解析块的前导头像。 |
| `emojiAvatar` | 本地函数（嵌套于 `_buildLeading`） | B | 构建圆形 emoji 头像。 |
| `defaultIcon` | 本地函数（嵌套于 `_buildLeading`） | B | 构建默认重复图标头像。 |

`grep -c 'Purpose:' lib/features/finance/views/subscriptions_page.dart` 报告 35，与上面计数的全部 35 个真实声明精确匹配（19 个 Tier A、16 个 Tier B）。每个 `/// Purpose:` 块都恰好位于其文档化的真实声明正上方——未发现错附块（记录调用点而非声明的块），也不存在未文档化的真实声明。与 `analysis_page.dart`（与本文件并列文档化，有一个未文档化方法）不同，本文件的文档注释与其声明完全同步，包括 `_buildLeading` 内两个嵌套本地函数（`emojiAvatar`、`defaultIcon`），它们各自带自己的 `/// Purpose:` 块。

## 文档

### `List<Subscription> get _active` <a id="_active"></a>
- **种类：** `_SubscriptionsPageState` 的 getter
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 96 行）
- **用途：** 返回当前激活订阅，按所选排序模式排序。
- **输入：** 无（读取 `_subscriptions`、经 `_sortList` 的 `_sortMode`/`_customOrder`）。
- **返回：** `List<Subscription>`。
- **副作用：** 无（传给 `_sortList` 的列表是 `.toList()` 的新副本，因此排序它不修改 `_subscriptions`）。
- **算法：** `_subscriptions.where((s) => s.isActive).toList()`，然后 `_sortList(list)` 按当前 `_sortMode` 原地排序再返回。
- **用法：** `final active = _active;`（`build`，第 678 行，`_monthlyDue` 的 `for (final s in _active)` 循环第 174 行也直接读取）。
- **备注：** 每次读 `_active` 都从头重新过滤和排序 `_subscriptions`；没有缓存，因此每次 `build` 多次调用它（`build`、`_monthlyDue` 和 `_monthlyAvg` 间接都做）会重复工作。

### `List<Subscription> get _historical` <a id="_historical"></a>
- **种类：** `_SubscriptionsPageState` 的 getter
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 107 行）
- **用途：** 返回不再激活（完全取消或过期）的订阅，供"历史"列表小节。
- **输入：** 无（读取 `_subscriptions`）。
- **返回：** `List<Subscription>`。
- **副作用：** 无。
- **算法：** `_subscriptions.where((s) => !s.isActive).toList()`——与 `_active` 不同，不应用排序模式；历史订阅保持 `_subscriptions` 自己的顺序。
- **用法：** `final historical = _historical;`（`build`，第 679 行）。
- **备注：** 这是决定哪些订阅在块的滑动/长按菜单中显示"恢复"而非"取消"操作的 getter（见 `build`，第 983-1045 行）——这里的 `isActive` 划分与 `_restoreSubscription` 分派的边界相同。

### `void _sortList(List<Subscription> list)` <a id="_sortlist"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 115 行）
- **用途：** 按 `_sortMode` 原地排序订阅列表。
- **输入：** `list` — 原地修改。
- **返回：** 无。
- **副作用：** 原地排序 `list`（从 `_active` 调用时是副本）。
- **算法：** `switch (_sortMode)`：`'name'` → 不区分大小写字母序；`'custom'` → 按每个条目在 `_customOrder` 中的索引排序（不在 `_customOrder` 中的条目经 `_customOrder.length` 哨兵索引排末尾）；默认（`'nextRenewal'`）→ 按 `nextBillingDate` 升序排序，`null` 日期排在所有非 null 日期之后（两者都 `null` 比较相等）。
- **用法：** `_sortList(list);`（`_active` getter，第 98 行——唯一调用点）。
- **备注：** `'custom'` 分支在 `_customOrder` 为空时是空操作（让 `list` 保持 `.where(...).toList()` 产生的任何顺序）——实际播种 `_customOrder` 的是 `_onSortModeChanged`，在用户首次切入自定义模式时。

### `void _onSortModeChanged(String mode)` <a id="_onsortmodechanged"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 149 行）
- **用途：** 切换活动排序模式，用户首次在无既有自定义顺序时进入自定义模式，从当前激活列表播种一个。
- **输入：** `mode` — `'nextRenewal'`、`'name'`、`'custom'` 之一。
- **返回：** 无。
- **副作用：** `setState` 更新 `_sortMode`/`_reordering`/`_customOrder`；调用 `widget.onSortChanged`。
- **算法：**
  1. `setState`：设 `_sortMode = mode`、`_reordering = false`（活动时退出重排模式）；`mode == 'custom'` 且 `_customOrder` 为空时，从当前激活订阅的 id（按当前显示顺序）初始化它。
  2. 调用 `widget.onSortChanged(_sortMode, _sortMode == 'custom' ? _customOrder : null)` 持久化选择。
- **用法：** `onSelected: _onSortModeChanged`（`build`，第 699 行，排序 `PopupMenuButton`）。
- **备注：** 已有 `_customOrder` 后重新进入自定义模式*不*重新播种——既有顺序（含此后添加/移除的任何订阅）被保留，因此来回切换排序模式不会丢失先前排好的自定义顺序。

### `double _monthlyDue()` <a id="_monthlydue"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 172 行）
- **用途：** 计算所有激活订阅的投影月度成本，规范化为每月数字并转换为默认币种。
- **输入：** 无（读取 `_active`、`widget.rateData.currentRates`、`widget.defaultCurrency`）。
- **返回：** `double`。
- **副作用：** 无。
- **算法：** 对每个激活订阅：`billingCycleType == BillingCycleType.monthly` 时 `monthly = amount / billingInterval`（每 N 个月订阅的每月份额）；否则（年）`monthly = amount / (billingInterval * 12)`。经 [`convertCurrency`](../services/balance_util.md#convertcurrency) 用**当前**汇率（不是历史快照——没有逐订阅汇率快照）把每个 `monthly` 值转换为 `widget.defaultCurrency`，并求和。
- **用法：** `'$sym${numberFormat.format(_monthlyDue())}'`（`build`，第 762 行，"月度应付"摘要卡片）；也是 `_monthlyAvg` 内的回退返回值，以及 `_yearlyAvg` 的基础。
- **备注：** 这是从每个订阅计费参数的*投影*，不是实际过去交易的和——与优先在历史足够时用真实交易历史的 `_monthlyAvg` 对照。

### `double _monthlyAvg()` <a id="_monthlyavg"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 197 行）
- **用途：** 从实际计费交易计算平均月度订阅花费，交易历史还不够时回退投影的 `_monthlyDue()` 数字。
- **输入：** 无（读取 `_transactions`、`widget.rateData.ratesAt`、`widget.defaultCurrency`）。
- **返回：** `double`。
- **副作用：** 无。
- **算法：**
  1. 把 `_transactions` 过滤到 `subscriptionId` 非 null 的。都不存在时返回 `_monthlyDue()`。
  2. 找最早此类交易的 `date`。
  3. 计算 `months = (now.year - earliest.year) * 12 + now.month - earliest.month`（整日历月跨度）。`months < 2` 时返回 `_monthlyDue()`（历史不足以有意义地平均）。
  4. 否则求和每笔订阅交易经 `convertCurrency` 用**该交易自己的历史汇率快照**（`widget.rateData.ratesAt(t.rateSnapshotId)`）转换为 `widget.defaultCurrency` 的金额，并除以 `months`。
- **用法：** `'$sym${numberFormat.format(_monthlyAvg())}'`（`build`，第 771 行，"月度平均"摘要卡片）。
- **备注：** 与 `_monthlyDue`（因为没有历史快照可投影，总是用当前汇率）不同，`_monthlyAvg` 的基于交易路径用每笔交易自己的历史汇率——两张摘要卡片不仅方法不同（投影 vs 实际平均），使用的汇率年代也可能不同。

### `void _insertNewSubscription(({Subscription sub, bool importHistory}) result)` <a id="_insertnewsubscription"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 254 行）
- **用途：** 插入新创建（或复制恢复）的订阅，计算其初始 `nextBillingDate` 使下一次处理器运行正确计费，并可选把其计费历史作为交易导入。
- **输入：** `result` — 来自 `AddSubscriptionDialog` 的、含草稿 `sub` 和 `importHistory` 标志的记录。
- **返回：** 无。
- **副作用：** `setState` 追加进 `_subscriptions`（自定义排序模式时也 `_customOrder`）；调用 `widget.onSubscriptionsChanged` 并有条件地 `widget.onSortChanged`；可能调用 `_importHistoricalTransactions`。
- **算法：**
  1. 构建 `result.sub` 的 `tempSub` 副本（丢弃任何预设的 `nextBillingDate`/激活状态字段，因为这里总是创建全新激活订阅）。
  2. 经 [`tempSub.calculateNextBillingDate`](../models/finance.md#calculatenextbillingdate) 计算 `initialNBD`：`result.importHistory` 为 true 时 `after: today`（严格晚于今天的第一个计费日期，因为今天——及所有更早——的计费日将作为交易单独回填）；不导入历史时 `after: today - 1 day`（今天或之后的第一个计费日期，因为处理器自己会在下次运行追赶今天的计费，而不是此方法回填它）。
  3. 构建带那个 `nextBillingDate` 内建的最终 `sub`，`setState` 追加进 `_subscriptions`（`_sortMode == 'custom'` 时也 `_customOrder`），然后通知 `widget.onSubscriptionsChanged`（适用时也 `widget.onSortChanged`）。
  4. `result.importHistory` 时调用 `_importHistoricalTransactions(sub)`。
- **用法：** `_insertNewSubscription(result);`（`_addSubscription`，第 245 行，和 `_copyRestoreSubscription`，第 440 行——两个对话框流程都汇入这一条插入路径）。
- **备注：** 第 2 步的 `after: today` vs `after: today - 1 day` 区别正是防止历史导入添加在今天重复计费的东西：导入已经为今天的计费日生成交易（如到期），因此 `nextBillingDate` 必须跳过它；非导入添加把今天的计费留给常规 `SubscriptionProcessor` 追赶生成——见 [订阅计费](../../../../algorithms/subscription-billing.md#hourly-renewal-catch-up-and-multi-cycle-catch-up)。

### `Future<void> _editSubscription(Subscription sub)` <a id="_editsubscription"></a>
- **种类：** `_SubscriptionsPageState` 的异步方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 315 行）
- **用途：** 为既有订阅打开编辑对话框，保存时只在计费相关参数实际变化时重新计算 `nextBillingDate`，否则保留它。
- **输入：** `sub` — 被编辑的订阅。
- **返回：** `Future<void>`。
- **副作用：** 显示 `AddSubscriptionDialog`；非 null 结果时 `setState` 替换匹配订阅并调用 `widget.onSubscriptionsChanged`。
- **算法：**
  1. `await showDialog` 带 `AddSubscriptionDialog(subscription: sub, ...)`（编辑模式）。
  2. 返回结果时，确定 `billingChanged`——`startDate`、`trialDays`、`billingCycleType` 或 `billingInterval` 与原始 `sub` 不同时为 `true`。
  3. `billingChanged` 时：从*新*计费参数构建 `tempSub` 并经 `calculateNextBillingDate(after: today - 1 day)` 重新计算 `nbd`（与全新添加相同的"今天或之后"锚点）。否则：保持 `nbd = sub.nextBillingDate` 不变。
  4. 构建保留对话框结果中 `isActive`/`cancelledAt`/`cancelType`（使别处设置的取消状态不被编辑覆盖）加解析的 `nbd` 的 `edited` 订阅；`setState` 按匹配 `id` 在 `_subscriptions` 中替换；通知 `widget.onSubscriptionsChanged`。
- **用法：** `onEdit: () => _editSubscription(sub)`（`build`，第 963 和 1029 行，接到激活和历史块的编辑操作）。
- **备注：** 只在计费参数变化时重新计算 `nextBillingDate`（而不是每次编辑），避免只因用户编辑了名称或 emoji 之类的无关字段就静默重置订阅的计费游标。

### `Future<void> _restoreSubscription(Subscription sub)` <a id="_restoresubscription"></a>
- **种类：** `_SubscriptionsPageState` 的异步方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 384 行）
- **用途：** 恢复订阅，按当前取消状态分派到正确的恢复路径——这是激活（待定到期时）和历史（完全取消/过期）订阅上"恢复"操作的入口。
- **输入：** `sub`。
- **返回：** `Future<void>`。
- **副作用：** 完全委托给 `_undoAtExpiryCancellation` 或 `_copyRestoreSubscription`。
- **算法：**
  1. `sub.isActive && sub.cancelType == CancelType.atExpiry`（尚未生效的待定到期时取消）时：调用 `_undoAtExpiryCancellation(sub)` 并返回。
  2. 否则 `!sub.isActive`（处理器已停用的订阅，或立即取消的）时：`await _copyRestoreSubscription(sub)`。
  3. （隐式第三种情形：无待定取消的激活订阅在 `build` 中本来就没有接恢复操作——`onRestore` 只在激活块的 `cancelType == CancelType.atExpiry` 时传，或历史块无条件传。）
- **用法：** `onRestore: sub.cancelType == CancelType.atExpiry ? () { _restoreSubscription(sub); } : null`（`build`，第 965-969 行，激活块）和 `onRestore: () { _restoreSubscription(sub); }`（`build`，第 1030 行，历史块）。
- **备注：** 此方法是 [财务](../../../../features/finance.md#views-and-analysis-page) 描述的恰好两种恢复行为的分派器："待定的到期时取消可以在原地恢复，而已过期或完全取消的订阅通过把其设置复制进新激活订阅来恢复。"

### `void _undoAtExpiryCancellation(Subscription sub)` <a id="_undoatexpirycancellation"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 399 行）
- **用途：** 原地撤销待定的到期时取消，不改变订阅身份（相同 `id`），把它重新激活为普通计费订阅。
- **输入：** `sub` — 当前必须是 `isActive == true` 且 `cancelType == CancelType.atExpiry`（由唯一调用方 `_restoreSubscription` 强制）。
- **返回：** 无。
- **副作用：** `setState` 替换 `_subscriptions` 中的匹配订阅；调用 `widget.onSubscriptionsChanged`。
- **算法：** 构建 `sub` 的 `restored` 副本，带 `isActive: true`（隐式丢弃 `cancelledAt`/`cancelType`，因为新 `Subscription(...)` 调用省略它们且它们默认未设置）和 `nextBillingDate: sub.nextBillingDate ?? _nextBillingDateFromToday(sub)`（字段不知何故未设置时回退新计算的日期）；`setState` 按 `id` 覆盖匹配条目；通知 `widget.onSubscriptionsChanged`。
- **用法：** `_undoAtExpiryCancellation(sub);`（`_restoreSubscription`，第 386 行——唯一调用点）。
- **备注：** 这等价于简单移除排定的取消标记——订阅保持其原始 `id`/`startDate`/历史，这是与 `_copyRestoreSubscription` 的新身份恢复路径的关键区别。

### `Future<void> _copyRestoreSubscription(Subscription sub)` <a id="_copyrestoresubscription"></a>
- **种类：** `_SubscriptionsPageState` 的异步方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 429 行）
- **用途：** 通过打开从其设置预填的编辑对话框、确认后把结果作为**全新**激活订阅插入来恢复完全历史（非激活）订阅——源订阅本身保持不动。
- **输入：** `sub` — 被恢复的历史订阅。
- **返回：** `Future<void>`。
- **副作用：** 显示 `AddSubscriptionDialog`；非 null 结果时委托给 `_insertNewSubscription`（它追加新条目并通知回调）。
- **算法：** `await showDialog` 带 `AddSubscriptionDialog(subscription: sub, restoreAsCopy: true, ...)`；对话框返回结果时调用 `_insertNewSubscription(result)`。
- **用法：** `await _copyRestoreSubscription(sub);`（`_restoreSubscription`，第 390 行——唯一调用点）。
- **备注：** `restoreAsCopy: true` 是传给 `AddSubscriptionDialog`（本文件不显示）的标志，大概用 `sub` 的值预填表单，同时让 `AddSubscriptionDialog` 为返回草稿生成*新* id/`startDate`——此方法自己不剥离 `sub.id`；它信任对话框交回新鲜订阅，这正是结果插入走与普通新添加相同的 `_insertNewSubscription` 路径的原因。

### `DateTime? _nextBillingDateFromToday(Subscription sub)` <a id="_nextbillingdatefromtoday"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 449 行）
- **用途：** 计算今天或之后的第一个计费日期，作为被重新激活的订阅缺少持久化 `nextBillingDate` 时的回退。
- **输入：** `sub`。
- **返回：** `DateTime?` — 只在 [`calculateNextBillingDate`](../models/finance.md#calculatenextbillingdate) 自己返回 `null` 时为 `null`（如已过截止的 `atExpiry` 取消订阅——这里预期不适用，因为调用方只在清除取消后到达）。
- **副作用：** 无。
- **算法：** `sub.calculateNextBillingDate(after: today - 1 day)`——本文件计费日期重算调用点一致使用的"今天或之后"锚点模式。
- **用法：** `nextBillingDate: sub.nextBillingDate ?? _nextBillingDateFromToday(sub)`（`_undoAtExpiryCancellation`，第 415 行——唯一调用点）。
- **备注：** 这镜像 [`SubscriptionProcessor.process`](../../../../algorithms/subscription-billing.md#hourly-renewal-catch-up-and-multi-cycle-catch-up) 中的"迁移情形"（为早于该字段被持久化的订阅计算一次 `nextBillingDate`），但这里专门应用于到期时撤销路径，而不是通用处理器追赶。

### `void _deleteSubscription(Subscription sub)` <a id="_deletesubscription"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 462 行）
- **用途：** 永久移除订阅（激活或历史）并通过也从自定义排序顺序移除其 id 保持其一致。
- **输入：** `sub`。
- **返回：** 无。
- **副作用：** `setState` 从 `_subscriptions` 和 `_customOrder` 移除；调用 `widget.onSubscriptionsChanged`，自定义排序模式时也 `widget.onSortChanged`。
- **算法：** `setState`：`_subscriptions.removeWhere((s) => s.id == sub.id)` 和 `_customOrder.remove(sub.id)`；然后通知 `widget.onSubscriptionsChanged(_subscriptions)`，`_sortMode == 'custom'` 时也 `widget.onSortChanged(_sortMode, _customOrder)`。
- **用法：** 调用点总是门控在 `confirmDelete(context, l10n.financeThisSubscription)` 之后，如 `if (confirmed == true) { _deleteSubscription(sub); }`（`build`，第 975-977 和 998-1001 行，激活和历史 `Dismissible.confirmDismiss`/`onDelete`）。
- **备注：** 此订阅先前生成的交易不被删除或取消链接——只移除订阅记录和其自定义顺序条目；已删除订阅的过去计费交易留在 `_transactions` 中不受影响，仍携带现在悬空的 `subscriptionId`。

### `void _doCancelSubscription(Subscription sub, CancelType type)` <a id="_docancelsubscription"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 511 行）
- **用途：** 对订阅应用所选取消类型——"立即取消"和"到期时取消"两个选择背后的实际状态转换。
- **输入：** `sub`；`type` — `CancelType.immediate` 或 `CancelType.atExpiry`。
- **返回：** 无。
- **副作用：** `setState` 替换 `_subscriptions` 中的匹配订阅；调用 `widget.onSubscriptionsChanged`。
- **算法：** 构建 `sub` 的 `cancelled` 副本，带 `isActive: type == CancelType.atExpiry`（到期时取消保持激活——应用继续计费它——直到处理器自己的到期检查把它关掉，按 [订阅计费](../../../../algorithms/subscription-billing.md#hourly-renewal-catch-up-and-multi-cycle-catch-up)；立即取消立即停用）、`cancelledAt: DateTime.now()`、`cancelType: type` 和*不变*的 `nextBillingDate`；`setState` 按 `id` 覆盖匹配条目；通知 `widget.onSubscriptionsChanged`。
- **用法：**
  ```dart
  ListTile(
    leading: const Icon(Icons.cancel),
    title: Text(l10n.financeCancelImmediate),
    onTap: () {
      Navigator.pop(ctx);
      _doCancelSubscription(sub, CancelType.immediate);
    },
  ),
  ```
  （`_cancelSubscription`，第 484-491 行，旁边有相同的 `atExpiry` `ListTile`，第 492-499 行。）
- **备注：** `isActive: type == CancelType.atExpiry` 是整个取消/恢复状态机的关键：到期时取消刻意保持"激活"（使它继续出现并继续计费），直到 `SubscriptionProcessor` 稍后在截止处把它翻转为非激活，而 `immediate` 在用户确认的瞬间进入非激活——这正是 `_restoreSubscription` 必须特别检查 `sub.isActive && sub.cancelType == CancelType.atExpiry` 以区分"仍激活但排定停止"与"已停止"的原因。

### `void _importHistoricalTransactions(Subscription sub)` <a id="_importhistoricaltransactions"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 543 行）
- **用途：** 为新添加订阅从 `startDate`/锚点起到今天的每个计费日生成交易，不重复任何已有匹配交易的计费日。
- **输入：** `sub` — 刚插入的订阅。
- **返回：** 无。
- **副作用：** `setState` 追加进 `_transactions`（只有有新东西可加时）；调用 `widget.onTransactionsChanged`。
- **算法：**
  1. `dates = sub.billingDatesBefore(now)`——从订阅锚点到现在的每个历史计费日期，经 [`Subscription.billingDatesBefore`](../models/finance.md#billingdatesbefore)。
  2. 构建 `existingKeys`，为每个带 `subscriptionId` 的既有交易构建 [`SubscriptionProcessor.billingDateKey`](../services/subscription_processor.md#billingdatekey) 值的集合——与 `SubscriptionProcessor` 自己使用的相同幂等键方案。
  3. 对每个历史 `date`：计算其 `billingDateKey(sub.id, date)`；把它加入 `existingKeys` 报告它*已经*存在（`!existingKeys.add(key)`）时跳过它——那天已计费；否则经 [`SubscriptionProcessor.transactionIdForBilling`](../services/subscription_processor.md#transactionidforbilling) 构建带稳定 id 的新支出 `Transaction`。
  4. 构建了任何新交易时，`setState(() => _transactions.addAll(newTxs))` 并通知 `widget.onTransactionsChanged`。
- **用法：** `_importHistoricalTransactions(sub);`（`_insertNewSubscription`，第 306 行，只在 `result.importHistory` 为 true 时）。
- **备注：** 通过复用 `SubscriptionProcessor` 的精确键/id 方案（见 [订阅计费](../../../../algorithms/subscription-billing.md#idempotent-billing-day-generation)），这里的历史导入和之后的处理器追赶趟即使两者碰巧对重叠日期范围运行也绝不可能给同一天计两次费——去重以 `'$subscriptionId|yyyy-MM-dd'` 为键，不以交易 id 来源为键。

### `List<(Subscription, DateTime)> _getUpcomingSubs(int days)` <a id="_getupcomingsubs"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 605 行）
- **用途：** 收集下一次计费日落在未来 `days` 天内的订阅，供"即将续费"chip 行——刻意排除下一次收费实际上不会发生的订阅。
- **输入：** `days` — 前瞻窗口。
- **返回：** `List<(Subscription, DateTime)>`，按计费日期升序排序。
- **副作用：** 无。
- **算法：**
  1. `limit = today + days`。
  2. 对 `_subscriptions` 中每个订阅：`cancelType == CancelType.atExpiry` 时跳过（无论 `isActive`——待定到期时订阅即使在名义上仍激活并计费也被排除在续费提醒外）；`!isActive && cancelType == CancelType.immediate` 时跳过（已取消订阅显然不会续费）。
  3. 订阅有 `nextBillingDate` 且其日历日在 `limit` 或之前时，把 `(sub, next)` 加入结果。
  4. 按计费日期升序排序结果。
- **用法：** `final upcomingSubs = _getUpcomingSubs(3);`（`build`，第 680 行——chip 行固定 3 天前瞻窗口）。
- **备注：** 文档注释自己的说明抓住了关键微妙点："到期时取消继续显示在订阅列表中，但从续费提醒排除"——即此过滤器比 `_active`/`_historical` 划分（只看 `isActive`）更严格，因为到期时订阅仍是 `isActive == true`，却不该为从用户视角即将停止的收费生成续费提醒。

### `Widget _buildReorderBody(ThemeData theme, AppLocalizations l10n, List<Subscription> active)` <a id="_buildreorderbody"></a>
- **种类：** `_SubscriptionsPageState` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 630 行）
- **用途：** 渲染 `_reordering` 为 true 时显示的拖拽重排列表，并在条目被放下时立即持久化新自定义顺序。
- **输入：** `theme`；`l10n`；`active` — 按当前自定义顺序的激活订阅。
- **返回：** `Widget`（一个 `ReorderableListView.builder`）。
- **副作用：** `setState` 修改 `_customOrder`；每次重排调用 `widget.onSortChanged`。
- **算法：**
  1. 把 `active` 复制进可变 `items` 列表（组件只从它读；真实修改发生在 `_customOrder` 上）。
  2. `onReorderItem: (oldIndex, newIndex)`：`setState` 做 `_customOrder.removeAt(oldIndex)` 然后 `.insert(newIndex, item)`——在持久化顺序内移动 id——然后立即调用 `widget.onSortChanged(_sortMode, _customOrder)` 持久化它。
  3. 每个条目块显示订阅名称、格式化金额和 emoji（如有）；前置拖拽手柄图标。
- **用法：** `body: _reordering ? _buildReorderBody(theme, l10n, active) : Column(...)`（`build`，第 751 行——`_reordering` 为 true 时把整个正文换成重排列表）。
- **备注：** 重排只操作 `active` 订阅（历史订阅不可重排），持久化 `_customOrder` 列表正是激活订阅 id 的序列——`_sortList` 的 `'custom'` 分支正是把那个持久化顺序在下次非重排渲染时变回排序后的 `_active` 列表的东西。

### `Widget build(BuildContext context)` <a id="build"></a>
- **种类：** `_SubscriptionTile`（一个 `StatelessWidget`）的方法覆盖
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 1197 行）
- **用途：** 渲染一个订阅的列表行，在布局 `ListTile` 前从订阅*当前*状态计算每个状态标签（分类、账户、计费周期、下次计费/到期日、取消日期）。
- **输入：** `context`。
- **返回：** `Widget`。
- **副作用：** 无直接；`onLongPress` 打开 `_showActions`。
- **算法：**
  1. 在 `categories`/`accounts` 中按 id 查找解析 `cat`/`account`（`firstOrNull`）；把 `catLabel`/`accountLabel` 构建为 `"emoji name"` 或无 emoji 时的裸 `name`。
  2. `cycleLabel` — 按 `billingCycleType` 的 `l10n.financeEveryXMonths`/`financeEveryXYears`，以 `billingInterval` 参数化。
  3. `nextLabel` — 按取消状态分支：`cancelType == CancelType.atExpiry` 且 `nextBillingDate` 已设置时，把它标注为**到期日**（无论订阅是否仍 `isActive`）；否则 `isActive` 且 `nextBillingDate` 已设置时，把它标注为**下次计费日期**；否则 `null`（不显示日期，如立即取消的订阅）。
  4. `cancelLabel` — 只在 `cancelledAt != null` *且* `cancelType != CancelType.atExpiry` 时设置（即只为立即取消——到期时取消的日期已经经 `nextLabel` 显示为到期日，因此这里不重复）。
  5. 从非 null 标签加 `cycleLabel`（总是出现）组装 `subtitleParts`，`!isActive` 时也加 `cancelLabel`；用 `"  •  "` 连接。
  6. 渲染 `ListTile`，`_buildLeading` 作前导头像、名称/占位标题、金额作尾部文本（主题错误色样式）、`onTap`/`onLongPress` 接到传入回调 / `_showActions`。
- **用法：**
  ```dart
  _SubscriptionTile(
    subscription: sub,
    categories: widget.categories,
    accounts: widget.accounts,
    defaultCurrency: widget.defaultCurrency,
    onTap: () => _openDetail(sub),
    onEdit: () => _editSubscription(sub),
    onCancel: () => _cancelSubscription(sub),
    onRestore: sub.cancelType == CancelType.atExpiry ? () { _restoreSubscription(sub); } : null,
    onDelete: () async { /* confirmDelete then _deleteSubscription(sub) */ },
  )
  ```
  （`_SubscriptionsPageState.build`，第 957-979 行，包在 `Dismissible` 中供滑动操作。）
- **备注：** 第 3-4 步是取消/恢复状态机变得用户可见的地方：技术上仍 `isActive` 的到期时取消订阅显示"到期日"标签（不是"下次计费"），这是在用户打开长按菜单看到恢复操作之前把它与普通激活订阅区分开的块级信号。

### `Widget _buildLeading(Subscription sub, Account? account, Category? cat, ThemeData theme)` <a id="_buildleading"></a>
- **种类：** `_SubscriptionTile` 的方法
- **来源：** `lib/features/finance/views/subscriptions_page.dart`（第 1335 行）
- **用途：** 经四层回退链解析块的前导头像：订阅自己的图像、然后自己的 emoji、然后链接账户的图像、然后链接分类的 emoji、最后通用重复图标。
- **输入：** `sub`；`account`；`cat`；`theme`（只用 `theme.colorScheme.error` 作为头像背景/前景着色）。
- **返回：** `Widget`。
- **副作用：** 无（`FutureBuilder` 分支经 `ImageService.resolve` 从磁盘读取，但那封装在返回组件自己的构建内，不是此调用本身的副作用）。
- **算法：**
  1. 两个嵌套本地辅助：`emojiAvatar(String emoji)`（带 emoji 作文本的着色 `CircleAvatar`）和 `defaultIcon()`（带 `Icons.repeat` 的着色 `CircleAvatar`）。
  2. `sub.imagePath != null` 时：返回解析 `ImageService.resolve(sub.imagePath!)` 的 `FutureBuilder<File>`；解析文件存在时把它显示为 `CircleAvatar.backgroundImage`；否则回退 `sub.emoji`（经 `emojiAvatar`）或 `defaultIcon()`。
  3. 否则 `sub.emoji != null` 时：直接返回 `emojiAvatar(sub.emoji!)`（没有要解析的图像）。
  4. 否则 `account?.imagePath != null` 时：与第 2 步相同的 `FutureBuilder` 模式，但（图像不解析时）回退到经 `emojiAvatar` 的 `cat?.emoji` 或 `defaultIcon()`。
  5. 否则 `cat?.emoji != null` 时：返回 `emojiAvatar(cat!.emoji!)`。
  6. 否则：`defaultIcon()`。
- **用法：** `leading: _buildLeading(sub, account, cat, theme)`（`_SubscriptionTile.build`，第 1251 行）。
- **备注：** 回退顺序严格优先订阅自己的品牌（图像、然后 emoji）而非链接账户或分类的——只在订阅自己既无图像也无 emoji 时才查询账户图像，分类 emoji 是通用图标前的最后手段。

## 相关页面

- [财务](../../../../features/finance.md#views-and-analysis-page) — 本页实现的订阅取消/恢复行为的概念级描述。
- [订阅计费](../../../../algorithms/subscription-billing.md) — `calculateNextBillingDate`/`billingDatesBefore` 和本页 `_importHistoricalTransactions` 背后的月末钳制和幂等计费日生成算法。
- [`Subscription`/`CancelType`/`BillingCycleType`](../models/finance.md) — 本页在取消/恢复/编辑流程中读取并以 copyWith 风格逐字段 `Subscription(...)` 调用重建的模型。
- [`SubscriptionProcessor.billingDateKey`/`transactionIdForBilling`](../services/subscription_processor.md) — `_importHistoricalTransactions` 复用的幂等键/id 方案。
- [`convertCurrency`/`currencySymbol`](../services/balance_util.md) — `_monthlyDue`/`_monthlyAvg` 使用的币种转换。
- [`ExchangeRateData.ratesAt`/`currentRates`](../services/exchange_rate_storage.md) — 历史 vs 当前汇率查找，其区别支撑 `_monthlyDue`/`_monthlyAvg` 的备注。

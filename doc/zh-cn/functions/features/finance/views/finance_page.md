# lib/features/finance/views/finance_page.dart

财务标签的主页：可选月摘要（支出/收入/总资产，带币种转换回退警告）、即将续费条，以及所选月份交易的分组列表，带滑动编辑/删除和浮动添加按钮。应用栏的溢出操作是进入其他每个财务子页（账户、分析、订阅、分类、汇率、默认币种）的入口。本页如何融入那里描述的可选月主页摘要和分组月度交易见 [财务](../../../../features/finance.md#views-and-analysis-page)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `FinancePage({super.key})` | 构造函数（`FinancePage`） | B | 创建财务页实例。 |
| `createState` | 方法（`FinancePage`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_FinancePageState`） | B | 注册续费/自动同步监听器，把所选月播种为当前月，并触发首次加载。 |
| `dispose` | 方法（`_FinancePageState`） | B | 注销续费和自动同步监听器。 |
| [`_loadData`](#_loaddata) | 方法（`_FinancePageState`） | A | 从磁盘加载财务和汇率数据进状态，或记录加载错误。 |
| [`_processSubscriptions`](#_processsubscriptions) | 方法（`_FinancePageState`） | A | 为计费日期过期的订阅自动生成交易。 |
| [`_getUpcomingSubs`](#_getupcomingsubs) | 方法（`_FinancePageState`） | A | 列出 N 天内计费的订阅，按计费日期排序。 |
| [`_saveData`](#_savedata) | 方法（`_FinancePageState`） | A | 把财务状态持久化到磁盘，加载的文件不可读时拒绝保存。 |
| `_updateReminderService` | 方法（`_FinancePageState`） | B | 把当前订阅/提醒时间状态推给 `ReminderService`。 |
| `_addTransaction` | 方法（`_FinancePageState`） | B | 打开添加交易对话框并把结果插入列表前部。 |
| `_deleteTransaction` | 方法（`_FinancePageState`） | B | 从状态移除交易并保存。 |
| `_editTransaction` | 方法（`_FinancePageState`） | B | 打开编辑对话框并在状态中替换交易。 |
| [`_pickFlowMonth`](#_pickflowmonth) | 方法（`_FinancePageState`） | A | 显示选择主页流过滤月份的年/月选择器对话框。 |
| [`build`](#build) | 方法（`_FinancePageState`） | A | 计算所选月的支出/收入/总资产摘要（带缺失汇率跟踪）并渲染主页。 |
| `_pickDefaultCurrency` | 方法（`_FinancePageState`） | B | 显示币种选择器并更新应用默认币种。 |
| `_openAccounts` | 方法（`_FinancePageState`） | B | 压入账户页，把其变更/排序回调接回状态。 |
| `_openAnalysis` | 方法（`_FinancePageState`） | B | 压入分析页。 |
| `_openSubscriptions` | 方法（`_FinancePageState`） | B | 压入订阅页，把其变更/提醒/排序回调接回状态。 |
| `_showFinanceMenu` | 方法（`_FinancePageState`） | B | 显示分类、汇率和默认币种的底部面板菜单。 |
| `_FinanceDataError({...})` | 构造函数（`_FinanceDataError`） | B | 创建财务数据错误视图实例。 |
| `build` | 方法（`_FinanceDataError`） | B | 渲染带重试按钮的阻塞"财务数据不可读"错误视图。 |
| `_SummaryHeader({...})` | 构造函数（`_SummaryHeader`） | B | 创建摘要页头实例。 |
| `build` | 方法（`_SummaryHeader`） | B | 渲染月导航行、支出/收入卡片、总资产卡片和缺失汇率警告。 |
| `_SummaryCard({...})` | 构造函数（`_SummaryCard`） | B | 创建摘要卡片实例。 |
| `build` | 方法（`_SummaryCard`） | B | 渲染一个带标签的图标/数值统计卡片。 |
| `_TransactionTile({...})` | 构造函数（`_TransactionTile`） | B | 创建交易块实例。 |
| `build` | 方法（`_TransactionTile`） | B | 渲染一笔交易的列表块（分类/账户标签、带符号金额）。 |
| `_buildLeading` | 方法（`_TransactionTile`，组件辅助） | B | 构建块的前导头像（解析的账户图像，或回退图标）。 |
| `defaultAvatar`（嵌套于 `_buildLeading`） | 本地函数（组件辅助） | B | 构建回退财务交易头像。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/views/finance_page.dart` 返回 29，与上面 29 行精确匹配——每个块都恰好位于其真实声明（构造函数、`createState`、生命周期方法、私有方法、`build` 覆盖或 `_buildLeading` 内的嵌套本地函数）正上方；未发现错附在调用点语句上方，也未发现未文档化的真实声明。四个类的普通组件字段（如 `_FinancePageState` 的 `_accounts`/`_categories`/`_transactions`/... 状态字段，以及 `StatelessWidget` 子类的构造函数参数）不带 `/// Purpose:` 块，与本代码库记录可调用成员而非数据字段的约定一致。

## 文档

### `Future<void> _loadData()` <a id="_loaddata"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 96-137 行）
- **用途：** 从磁盘加载财务数据和汇率数据进状态，或记录加载错误，使存在但不可读的数据被浮出而不是静默当作空。
- **输入：** 无（读取 `FinanceStorage.load()` 和 `ExchangeRateStorage.load()`）。
- **返回：** `Future<void>`。
- **副作用：** 成功时设置几乎每个状态字段（`_accounts`、`_categories`、`_transactions`、`_subscriptions`、`_defaultCurrency`、订阅提醒小时/分钟/排序模式/自定义顺序、账户排序模式/自定义顺序、`_accountPickerSettings`、`_settingsModifiedAt`、`_rateData`、`_loaded`）；读取失败时设置 `_loadError` 并提前返回。之后总是调用 `_updateReminderService()`，存在任何订阅时调用 `_processSubscriptions()`。
- **算法：**
  1. 在 `try`/`catch` 内调用 `FinanceStorage.load()`（[`finance_storage.md#load`](../services/finance_storage.md#load)）。它抛出且组件仍 `mounted` 时，设 `_loadError = e.toString()` 和 `_loaded = true`，然后返回——不碰其他任何字段，因此加载失败绝不覆盖先前显示的数据。
  2. 否则调用 `ExchangeRateStorage.load()`（[`exchange_rate_storage.md#load`](../services/exchange_rate_storage.md#load)）。
  3. 在 `setState` 内清除 `_loadError`。`data` 非 null 时把每个字段复制进对应状态字段——`_accountSortModes` 和 `_accountCustomOrders` 经 `Map.of`/`List<String>.of` 深复制而不是别名。总是赋值 `_rateData = rateData` 和 `_loaded = true`。
  4. 无条件调用 `_updateReminderService()`。
  5. `_subscriptions.isNotEmpty` 时调用 [`_processSubscriptions`](#_processsubscriptions) 生成任何逾期计费交易。
- **用法：**
  ```dart
  ReminderService.instance.onRenewalsProcessed = _loadData;
  _loadData();
  AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  ```
  也用作 `_FinanceDataError(message: _loadError!, onRetry: _loadData)` 的重试回调。
- **备注：** 因为捕获的读取错误在重置 `_accounts`/`_transactions`/等之前返回，成功较早加载后的瞬态读取失败仍会在阻塞 `_FinanceDataError` 视图下方显示最后良好的内存数据而不是清空它——虽然那种状态下实际渲染的是错误视图（见 `build`）。

### `void _processSubscriptions()` <a id="_processsubscriptions"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 145-154 行）
- **用途：** 对每个激活订阅，为应用上次处理续费以来已过的任何计费日期生成交易。
- **输入：** 无（读取 `_subscriptions`、`_transactions`）。
- **返回：** 无。
- **副作用：** 计费生成有变化时，经 `setState` 更新 `_subscriptions` 并把新交易追加进 `_transactions`，然后调用 [`_saveData`](#_savedata) 持久化。
- **算法：** 完全委托给 `SubscriptionProcessor.process(_subscriptions, _transactions)`（[`subscription_processor.md#process`](../services/subscription_processor.md#process)）——它执行的月末钳制和幂等计费日生成见 [订阅计费](../../../../algorithms/subscription-billing.md)。`result.changed` 时用 `result.subs` 替换 `_subscriptions` 并把 `result.txs` 追加进 `_transactions`。
- **用法：**
  ```dart
  if (_subscriptions.isNotEmpty) {
    _processSubscriptions();
  }
  ```
  也从订阅页的 `onSubscriptionsChanged` 回调调用（在 `_openSubscriptions` 中接线，任何订阅编辑后），使变更的计费周期立即被追赶，而不是等下一次加载。
- **备注：** 重复调用安全——`SubscriptionProcessor.process` 同时识别随机 id（旧）和稳定 id（当前）计费交易，因此重新运行绝不给一天计两次费。

### `List<(Subscription, DateTime)> _getUpcomingSubs(int days)` <a id="_getupcomingsubs"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 162-180 行）
- **用途：** 返回下一次计费日期落在从今天起 `days` 天内的订阅，最早优先，供主页的"即将续费"条。
- **输入：** `days` — 前瞻窗口大小。
- **返回：** `List<(Subscription, DateTime)>` — 每个元组把订阅与其 `nextBillingDate` 配对。
- **副作用：** 无。
- **算法：**
  1. 计算 `today`（纯日期，从 `DateTime.now()`）和 `limit = today + Duration(days: days)`。
  2. 对每个订阅：`cancelType == CancelType.atExpiry` 时跳过（到期时取消继续出现在订阅列表中，但从续费提醒排除）；`!isActive && cancelType == CancelType.immediate` 时也跳过。
  3. 订阅的 `nextBillingDate` 非 null 且其纯日期形式不晚于 `limit` 时，把 `(sub, next)` 加入结果。
  4. 按计费日期升序排序结果并返回。
- **用法：**
  ```dart
  // Upcoming renewals (within 3 days)
  final upcomingSubs = _getUpcomingSubs(3);
  ```
  （在 `build` 内调用，供给交易列表上方显示的水平 `Chip` 条。）
- **备注：** `subscriptions_page.dart` 中存在同名、独立实现的 `_getUpcomingSubs`，带相同排除规则但用于该页自己即将续费小节的更长前瞻窗口——两者不是共享代码。

### `Future<void> _saveData()` <a id="_savedata"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 188-220 行）
- **用途：** 把当前内存财务状态持久化到磁盘，已知加载的文件不可读时拒绝写入。
- **输入：** 无（读取每个持久化状态字段）。
- **返回：** `Future<void>`。
- **副作用：** 要么显示 `financeDataWriteBlocked` snack bar 并返回（不写），要么调用 `FinanceStorage.save(...)`（[`finance_storage.md#save`](../services/finance_storage.md#save)），然后 `AutoSyncService.instance.notifySaved()` 和 `_updateReminderService()`。
- **算法：**
  1. `_loadError != null` 且组件 `mounted` 时，显示带 `l10n.financeDataWriteBlocked` 的 `SnackBar` 并返回——这阻止磁盘上损坏的财务文件被失败加载产生的任何（空或过期）内存状态覆盖。
  2. 否则从每个当前状态字段构建 `FinanceData` 并调用 `FinanceStorage.save(...)`。
  3. 调用 `AutoSyncService.instance.notifySaved()`，使自动同步调度器知道本地数据已变。
  4. 调用 `_updateReminderService` 让 `ReminderService` 与刚保存的内容保持同步。
- **用法：**
  ```dart
  void _deleteTransaction(Transaction tx) {
    setState(() {
      _transactions.removeWhere((t) => t.id == tx.id);
    });
    _saveData();
  }
  ```
  本文件几乎每次变更后调用（`_addTransaction`、`_deleteTransaction`、`_editTransaction`、`_processSubscriptions`、`_pickDefaultCurrency`，以及传给账户/分析/订阅/分类子页的 `onChanged`/`onSortChanged`/`onReminderChanged`/`onAccountPickerSettingsChanged` 回调）。
- **备注：** 写阻塞守卫意味着真正损坏的财务文件只能在应用外修复（或经 `FinanceStorage`/`_FinanceDataError` 的重试提供的任何恢复）——UI 绝不会静默用空数据替换它。

### `Future<void> _pickFlowMonth()` <a id="_pickflowmonth"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 300-369 行）
- **用途：** 让用户选择过滤主页交易流和摘要卡片的年和月。
- **输入：** 无（读取 `context`、`_selectedFlowMonth`）。
- **返回：** `Future<void>`。
- **副作用：** 打开对话框；确认后经 `setState` 更新 `_selectedFlowMonth`。
- **算法：**
  1. 显示由持对话框本地 `year` 变量（从 `_selectedFlowMonth.year` 播种）的 `StatefulBuilder` 构建的 `AlertDialog`。
  2. 渲染递增/递减对话框本地 `year` 的 chevron 按钮（经 `setDialogState`，不是页面自己的 `setState`）。
  3. 渲染 12 个 `ChoiceChip` 的 `Wrap`，每月一个，用 `DateFormat.MMM(l10n.localeName)` 标注，`year` 和 `month` 都匹配 `_selectedFlowMonth` 时标记选中。
  4. 点击芯片带 `DateTime(year, month)` 弹出对话框。
  5. 对话框返回非 null 时，设 `_selectedFlowMonth = DateTime(picked.year, picked.month)`——日总是规范化为 1 号。
- **用法：**
  ```dart
  _SummaryHeader(
    ...
    onPickMonth: _pickFlowMonth,
  ),
  ```
  （`_SummaryHeader.build` 把它接到月标签的 `TextButton.icon`。）
- **备注：** 对话框只存储年/月对——此流程中任何地方都没有日级过滤；`_selectedFlowMonth` 的日分量总是 `1`（构造函数参数列表省略 `day`，它默认 `1`）。

### `Widget build(BuildContext context)` <a id="build"></a>
- **种类：** `_FinancePageState` 的方法（`State.build` 的 `@override`）
- **来源：** `lib/features/finance/views/finance_page.dart`（第 377-659 行）
- **用途：** 计算所选月的支出/收入/总资产摘要——跟踪任何回退到 1:1 转换的币种对——并渲染财务主页：应用栏、摘要页头、即将续费条和分组、可滑动交易列表。
- **输入：** `context`。
- **返回：** 当前状态的组件树（加载转圈、阻塞错误视图或完整主页）。
- **副作用：** 无直接（给定当前状态的纯渲染），尽管它接线的回调（月导航、滑动编辑/删除、菜单操作）在之后被调用时修改状态。
- **算法：**
  1. 计算 `monthLabel`（`_selectedFlowMonth` 的 `'yyyy-MM'`）和 `currentRates`（今天的汇率，经 `_rateData.currentRates`——[`exchange_rate_storage.md#currentrates`](../services/exchange_rate_storage.md#currentrates)）。
  2. 从 `_selectedFlowMonth` 派生 `startOfMonth`/`startOfNextMonth` 并把 `_transactions` 过滤进 `monthTransactions`：`date >= startOfMonth && date < startOfNextMonth`。
  3. 声明 `missingRatePairs` 集和记录 `'$from→$to'` 的 `trackMissingRate(from, to)` 闭包；它作为 `onMissingRate` 传给下方每个 `convertCurrency` 调用，使任何静默 1:1 回退被浮出而不是 unnoticed 地扭曲总计。
  4. `monthExpense`：折叠 `monthTransactions` 中 `type == expense` 的，经 `convertCurrency(_rateData.ratesAt(t.rateSnapshotId), t.amount, t.currency, _defaultCurrency, onMissingRate: trackMissingRate)`（[`balance_util.md#convertcurrency`](../services/balance_util.md#convertcurrency)）转换每笔交易——即按该交易自己日期生效的汇率快照。
  5. `monthIncome`：相同折叠，过滤 `type == income`。
  6. `totalAssets`：`_accounts` 为空时回退 `monthIncome - monthExpense`；否则折叠 `_accounts`，经 `accountBalance(a, _transactions, _rateData)`（[`balance_util.md#accountbalance`](../services/balance_util.md#accountbalance)）计算每个账户余额并用**今天**的 `currentRates` 转换为 `_defaultCurrency`——不同于 `monthExpense`/`monthIncome` 使用的逐交易快照汇率。
  7. 计算 `upcomingSubs = _getUpcomingSubs(3)`。
  8. 构建带 `AppBar`（账户/分析/订阅/溢出菜单操作，`_loadError != null` 时全部禁用）的 `Scaffold`，正文为：`!_loaded` 时转圈；`_loadError != null` 时 `_FinanceDataError` 视图；否则是 `_SummaryHeader`（喂计算的总计、`missingRatePairs.toList()..sort()` 和把 `_selectedFlowMonth` 按月移位的 prev/next 月回调）的 `Column`、可选即将续费 `Chip` 条、"交易"小节标签，以及空状态消息或喂按最新优先排序的 `monthTransactions`、每行包在 `Dismissible`（从左往右滑动打开编辑；从右往左滑动经 `confirmDelete` 请求删除确认）中的 `buildGroupedTransactionList`（[`grouped_transaction_list.md#buildgroupedtransactionlist`](../widgets/grouped_transaction_list.md#buildgroupedtransactionlist)）。
  9. `FloatingActionButton` 触发 `_addTransaction`，`_loadError != null` 时禁用。
- **用法：** `_FinancePageState` 重建时由 Flutter 框架调用；不直接调用。`FinancePage` 本身从路由器挂载：
  ```dart
  builder: (context, state) => const FinancePage(),
  ```
  （`lib/app/router.dart`）。
- **备注：** 月边界过滤（`monthTransactions`）对流总计用逐交易历史汇率，但对总资产卡片用当前汇率——这是刻意的：过去某月的支出/收入应反映那个月术语下的成本，而总资产是"它们现在值多少"。

## 相关页面

- [财务](../../../../features/finance.md) — 模型字段参考以及本页可选月摘要和分组交易列表如何契合更广的财务功能。
- [订阅计费](../../../../algorithms/subscription-billing.md) — [`_processSubscriptions`](#_processsubscriptions) 经 `SubscriptionProcessor.process` 委托的追赶算法。
- [`balance_util.dart`](../services/balance_util.md) — `convertCurrency`、`accountBalance`，由 [`build`](#build) 用于摘要总计。
- [`finance_storage.md`](../services/finance_storage.md) — `load`/`save`，由 [`_loadData`](#_loaddata) 和 [`_saveData`](#_savedata) 使用。
- [`exchange_rate_storage.md`](../services/exchange_rate_storage.md) — `load`、`currentRates`、`ratesAt`，由 [`_loadData`](#_loaddata) 和 [`build`](#build) 使用。
- [`grouped_transaction_list.dart`](../widgets/grouped_transaction_list.md) — `buildGroupedTransactionList`，用于在 [`build`](#build) 中渲染按日期分组的交易列表。
- [`add_transaction_dialog.dart`](../widgets/add_transaction_dialog.md) — `_addTransaction` 和 `_editTransaction` 显示的对话框。
- [`reminder_service.md`](../../../shared/services/reminder_service.md) — `updateSubscriptionData`，由 `_updateReminderService` 保持同步。
- [`auto_sync_service.md`](../../../shared/services/auto_sync_service.md) — `addOnLocalDataChanged`/`notifySaved`，由 `initState`/[`_saveData`](#_savedata) 使用。

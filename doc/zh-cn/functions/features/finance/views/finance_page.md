# lib/features/finance/views/finance_page.dart

财务标签的主页：可选月摘要（支出/收入/总资产，带币种转换回退警告）、即将续费条，以及所选月份交易的分组列表，带滑动编辑/删除和浮动添加按钮。自 v1.4.3 起，双栏排布还会用一个订阅概览——三项订阅统计和进行中列表，取自 [`subscription_summary.dart`](../services/subscription_summary.md)——填满摘要窗格。自 v1.5.0 起，摘要在两种排布中还都带有端侧 AI 洞察卡片（[`AiInsightCard`](../../ai/widgets/ai_insight_card.md)，见[端侧 AI](../../../../on-device-ai.md#insight-cards)）。应用栏的溢出操作是进入其他每个财务子页（账户、分析、订阅、分类、汇率、默认币种）的入口。本页如何融入那里描述的可选月主页摘要和分组月度交易见 [财务](../../../../features/finance.md#views-and-analysis-page)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `FinancePage({super.key})` | 构造函数（`FinancePage`） | B | 创建财务页实例。 |
| `createState` | 方法（`FinancePage`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_FinancePageState`） | B | 注册续费/自动同步监听器，把所选月播种为当前月，并触发首次加载。 |
| `dispose` | 方法（`_FinancePageState`） | B | 注销续费和自动同步监听器。 |
| [`_io`](#_io) | 方法（`_FinancePageState`） | A | 在上一个操作完成后再运行一次财务加载、保存或子页面提交（本页的串行 I/O 队列，v1.5.2）。 |
| `_applyFinanceData` | 方法（`_FinancePageState`） | B | 把加载或合并得到的 `FinanceData` 复制进页面状态字段（调用方把它包在 `setState` 中）。 |
| `_currentFinanceData` | 方法（`_FinancePageState`） | B | 把页面当前财务状态快照为一个 `FinanceData`。 |
| [`_loadData`](#_loaddata) | 方法（`_FinancePageState`） | A | 在 I/O 队列上排入一次财务数据和汇率的重新加载。 |
| [`_loadDataNow`](#_loaddatanow) | 方法（`_FinancePageState`） | A | `_loadData` 的主体：把财务和汇率数据加载进状态，或记录加载错误。 |
| [`_processSubscriptions`](#_processsubscriptions) | 方法（`_FinancePageState`） | A | 为计费日期过期的订阅自动生成交易。 |
| `_showWriteBlocked` | 方法（`_FinancePageState`） | B | 组件仍 mounted 时显示 `financeDataWriteBlocked` snack bar。 |
| [`_saveData`](#_savedata) | 方法（`_FinancePageState`） | A | 在 I/O 队列上排入一次页面内存财务状态的保存。 |
| [`_saveDataNow`](#_savedatanow) | 方法（`_FinancePageState`） | A | `_saveData` 的主体：持久化财务状态，加载的文件不可读时拒绝保存。 |
| [`_commitSubPage`](#_commitsubpage) | 方法（`_FinancePageState`） | A | 把一次子页面回调的列表编辑按 id 合并进重新读取的文件并保存（v1.5.2）。 |
| `_updateReminderService` | 方法（`_FinancePageState`） | B | 把当前订阅/提醒时间状态推给 `ReminderService`。 |
| `_addTransaction` | 方法（`_FinancePageState`） | B | 打开添加交易对话框并把结果插入列表前部。 |
| `_deleteTransaction` | 方法（`_FinancePageState`） | B | 从状态移除交易并保存。 |
| `_editTransaction` | 方法（`_FinancePageState`） | B | 打开编辑对话框并在状态中替换交易。 |
| [`_pickFlowMonth`](#_pickflowmonth) | 方法（`_FinancePageState`） | A | 显示选择主页流过滤月份的年/月选择器对话框。 |
| [`build`](#build) | 方法（`_FinancePageState`） | A | 计算所选月的支出/收入/总资产摘要（带缺失汇率跟踪）并渲染主页。 |
| `_pickDefaultCurrency` | 方法（`_FinancePageState`） | B | 显示币种选择器并更新应用默认币种。 |
| `_openAccounts` | 方法（`_FinancePageState`） | B | 压入账户页；账户和交易编辑经 `_commitSubPage` 按 id 合并提交，排序和选择器设置经 `_saveData` 保存。 |
| `_openAnalysis` | 方法（`_FinancePageState`） | B | 压入分析页；交易编辑经 `_commitSubPage` 按 id 合并提交。 |
| `_openSubscriptions` | 方法（`_FinancePageState`） | B | 压入订阅页；订阅编辑（随后 `_processSubscriptions`）和交易编辑按 id 合并提交，提醒时间和排序经 `_saveData` 保存。 |
| `_openSubscriptionDetail` | 方法（`_FinancePageState`） | B | 从主页概览压入某一订阅的详情页，与订阅页的做法完全一致；交易编辑按 id 合并提交。 |
| `_showFinanceMenu` | 方法（`_FinancePageState`） | B | 显示分类（其分类和交易编辑按 id 合并提交）、汇率和默认币种的底部面板菜单。 |
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
| `_FinanceBody({...})` | 构造函数（`_FinanceBody`） | B | 创建财务主体排布器。 |
| [`build`](#financebody-build) | 方法（`_FinanceBody`） | A | 把摘要堆叠在交易之上，或放进它们旁边的窗格里。 |
| `_SubscriptionOverview({...})` | 构造函数（`_SubscriptionOverview`） | B | 创建摘要窗格的订阅概览。 |
| [`build`](#subscriptionoverview-build) | 方法（`_SubscriptionOverview`） | A | 在摘要窗格内渲染三项订阅统计和进行中列表。 |
| `_SubscriptionOverviewTile({...})` | 构造函数（`_SubscriptionOverviewTile`） | B | 创建订阅概览的一行只读行。 |
| `build` | 方法（`_SubscriptionOverviewTile`） | B | 渲染紧凑的订阅行：头像、名称、周期与下次扣费、金额。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/views/finance_page.dart` 返回 42，与上面 42 行精确匹配——每个块都恰好位于其真实声明（构造函数、`createState`、生命周期方法、私有方法、`build` 覆盖或 `_buildLeading` 内的嵌套本地函数）正上方；未发现错附在调用点语句上方，也未发现未文档化的真实声明。六个类的普通组件字段（如 `_FinancePageState` 的 `_accounts`/`_categories`/`_transactions`/... 状态字段及其 `_ioQueue` future，以及 `StatelessWidget` 子类的构造函数参数）不带 `/// Purpose:` 块，与本代码库记录可调用成员而非数据字段的约定一致。

## 文档

### `Future<void> _io(Future<void> Function() op)` <a id="_io"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 113-117 行）
- **用途：** 只在上一个操作完成后才运行一次财务加载、保存或子页面提交，使本页绝不并发读写 `finance_data.json`（v1.5.2）。
- **输入：** `op`——排队的工作。
- **返回：** 随 `op` 完成（或失败）的 `Future<void>`。
- **副作用：** 推进 `_ioQueue` 字段。
- **算法：**
  1. `next = _ioQueue.then((_) => op(), onError: (_) => op())`——无论上一个操作成功还是失败，`op` 都在它之后运行。
  2. 把 `next.catchError((_) {})` 存为新的 `_ioQueue`，使一次失败的操作不会毒化后续操作的队列。
  3. 返回 `next` 本身，使调用方仍能看到 `op` 自己的错误。
- **用法：**
  ```dart
  Future<void> _loadData() => _io(_loadDataNow);
  ```
  [`_saveData`](#_savedata) 和 [`_commitSubPage`](#_commitsubpage) 以同样方式入队。
- **备注：** `op` 绝不能 *await* `_loadData`、`_saveData` 或 `_commitSubPage`——它们都会排在正在运行的 `op` 之后，于是 `op` 等待它自己，队列死锁。不 await 地触发一个则没问题：[`_loadDataNow`](#_loaddatanow) 正是这样调用 [`_processSubscriptions`](#_processsubscriptions)，后者排入的保存在加载之后运行。

### `Future<void> _loadData()` <a id="_loaddata"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 169 行）
- **用途：** 从磁盘重新加载财务数据和汇率，经 I/O 队列与保存和子页面提交串行化。
- **输入：** 无。
- **返回：** 排队的加载运行完后完成的 `Future<void>`。
- **副作用：** 在 [`_io`](#_io) 上排入 [`_loadDataNow`](#_loaddatanow)。
- **算法：** `_io(_loadDataNow)`。
- **用法：**
  ```dart
  ReminderService.instance.onRenewalsProcessed = _loadData;
  _loadData();
  AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  ```
  也用作 `_FinanceDataError(message: _loadError!, onRetry: _loadData)` 的重试回调。
- **备注：** 自 v1.5.2 起，保存进行中时由续费或同步触发的重新加载会等待那次保存，而不是与之竞争。

### `Future<void> _loadDataNow()` <a id="_loaddatanow"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 176-203 行）
- **用途：** `_loadData` 的主体，在 I/O 队列内运行：把财务数据和汇率数据加载进状态，或记录加载错误，使存在但不可读的数据被浮出而不是静默当作空。
- **输入：** 无（读取 `FinanceStorage.load()` 和 `ExchangeRateStorage.load()`）。
- **返回：** `Future<void>`。
- **副作用：** 成功时设置几乎每个状态字段（经 `_applyFinanceData`：`_accounts`、`_categories`、`_transactions`、`_subscriptions`、`_defaultCurrency`、订阅提醒小时/分钟/排序模式/自定义顺序、账户排序模式/自定义顺序、`_accountPickerSettings`、`_settingsModifiedAt`；另加 `_rateData`、`_loaded`）；读取失败时设置 `_loadError` 并提前返回。成功加载后调用 `_updateReminderService()`，存在任何订阅时调用 `_processSubscriptions()`。
- **算法：**
  1. 在同一个 `try`/`catch` 内先调用 `FinanceStorage.load()`（[`finance_storage.md#load`](../services/finance_storage.md#load)），再调用 `ExchangeRateStorage.load()`（[`exchange_rate_storage.md#load`](../services/exchange_rate_storage.md#load)）。任一抛出且组件仍 `mounted` 时，设 `_loadError = e.toString()` 和 `_loaded = true`，然后返回——不碰其他任何字段，因此加载失败绝不覆盖先前显示的数据。
  2. 组件已不再 `mounted` 时返回。
  3. 在 `setState` 内清除 `_loadError`。`data` 非 null 时把它交给 `_applyFinanceData`，后者把每个字段复制进对应状态字段——`_accountSortModes` 和 `_accountCustomOrders` 经 `Map.of`/`List<String>.of` 深复制而不是别名。总是赋值 `_rateData = rateData` 和 `_loaded = true`。
  4. 调用 `_updateReminderService()`。
  5. `_subscriptions.isNotEmpty` 时调用 [`_processSubscriptions`](#_processsubscriptions) 生成任何逾期计费交易；它的保存被排入队列而不被 await。
- **用法：** 只经 [`_loadData`](#_loaddata) 调用。
- **备注：** 自 v1.5.2 起，汇率在同一个 `try` 内加载，因此不可读的汇率文件（`ExchangeRateStorageException`）会显示阻塞的 `_FinanceDataError` 视图并阻止写入，而不是作为未处理错误逸出；此前汇率是在 `try` 之后加载的。因为捕获的读取错误在重置 `_accounts`/`_transactions`/等之前返回，成功较早加载后的瞬态读取失败仍会在阻塞 `_FinanceDataError` 视图下方保留最后良好的内存数据而不是清空它——虽然那种状态下实际渲染的是错误视图（见 `build`）。

### `void _processSubscriptions()` <a id="_processsubscriptions"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 212-221 行）
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
  也作为订阅页 `onSubscriptionsChanged` 提交的 `after` 回调传入（在 `_openSubscriptions` 中接线），使变更的计费周期在合并后的订阅进入状态后立即被追赶，而不是等下一次加载。
- **备注：** 重复调用安全——`SubscriptionProcessor.process` 同时识别随机 id（旧）和稳定 id（当前）计费交易，因此重新运行绝不给一天计两次费。它不 await 地触发 `_saveData()`，因此可以在 I/O 队列内部安全调用（见 [`_io`](#_io)）。

### `Future<void> _saveData()` <a id="_savedata"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 243 行）
- **用途：** 保存页面的内存财务状态，经 I/O 队列与加载和子页面提交串行化。
- **输入：** 无。
- **返回：** 排队的保存运行完后完成的 `Future<void>`。
- **副作用：** 在 [`_io`](#_io) 上排入 [`_saveDataNow`](#_savedatanow)。
- **算法：** `_io(_saveDataNow)`。
- **用法：**
  ```dart
  void _deleteTransaction(Transaction tx) {
    setState(() {
      _transactions.removeWhere((t) => t.id == tx.id);
    });
    _saveData();
  }
  ```
  在主页自身的变更（`_addTransaction`、`_deleteTransaction`、`_editTransaction`、`_processSubscriptions`、`_pickDefaultCurrency`）之后调用，也由子页面的设置回调调用——账户页 `onSortChanged`/`onAccountPickerSettingsChanged`，订阅页 `onReminderChanged`/`onSortChanged`。自 v1.5.2 起，子页面的列表回调不再调用它，而是经 [`_commitSubPage`](#_commitsubpage)。
- **备注：** 它写入页面的整个内存状态，因此只适用于在本页做的编辑或设置字段；在子页面编辑的列表改为按 id 合并。

### `Future<void> _saveDataNow()` <a id="_savedatanow"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 250-258 行）
- **用途：** `_saveData` 的主体，在 I/O 队列内运行：把当前内存财务状态持久化到磁盘，已知加载的文件不可读时拒绝写入。
- **输入：** 无（读取每个持久化状态字段）。
- **返回：** `Future<void>`。
- **副作用：** 要么显示 `financeDataWriteBlocked` snack bar 并返回（不写），要么调用 `FinanceStorage.save(...)`（[`finance_storage.md#save`](../services/finance_storage.md#save)），然后 `AutoSyncService.instance.notifySaved()` 和 `_updateReminderService()`。
- **算法：**
  1. `_loadError != null` 时调用 `_showWriteBlocked()`（带 `l10n.financeDataWriteBlocked` 的 `SnackBar`，仅在 `mounted` 时）并返回——这阻止磁盘上损坏的财务文件被失败加载产生的任何（空或过期）内存状态覆盖。
  2. 否则调用 `FinanceStorage.save(_currentFinanceData())`，它快照每个当前状态字段。
  3. 调用 `AutoSyncService.instance.notifySaved()`，使自动同步调度器知道本地数据已变。
  4. 调用 `_updateReminderService` 让 `ReminderService` 与刚保存的内容保持同步。
- **用法：** 只经 [`_saveData`](#_savedata) 调用。
- **备注：** 写阻塞守卫意味着真正损坏的财务文件只能在应用外修复（或经 `FinanceStorage`/`_FinanceDataError` 的重试提供的任何恢复）——UI 绝不会静默用空数据替换它。

### `Future<void> _commitSubPage({IdListDelta<Account>? accounts, IdListDelta<Category>? categories, IdListDelta<Transaction>? transactions, IdListDelta<Subscription>? subscriptions, VoidCallback? after})` <a id="_commitsubpage"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 269-306 行）
- **用途：** 把一次子页面回调的列表编辑按记录 id 合并进当前文件并保存，而不是把子页面的整个列表写回（v1.5.2）。
- **输入：** 可选的逐列表增量 `accounts`、`categories`、`transactions`、`subscriptions`（均为来自 [`id_list_delta.dart`](../../../shared/utils/id_list_delta.md) 的 `IdListDelta`）；`after`——提交完成后运行。
- **返回：** `Future<void>`。
- **副作用：** 读写 `finance_data.json`，用合并后的数据替换页面财务状态，调用 `AutoSyncService.instance.notifySaved()` 和 `_updateReminderService()`；可能设置 `_loadError` 并显示写阻塞 snack bar。
- **算法：** 在一次 [`_io`](#_io) 操作内：
  1. `_loadError != null` 时调用 `_showWriteBlocked()` 并返回。
  2. 用 `FinanceStorage.load()` 重新读取文件。它抛出时设置 `_loadError`（mounted 时，这会把页面切到阻塞错误视图），调用 `_showWriteBlocked()`，不写入即返回。
  3. `base` = 新加载的数据；文件不存在时为 `_currentFinanceData()`。
  4. `merged = base.copyWith(...)`（[`finance_storage.md`](../services/finance_storage.md)），其中有增量的每个列表变为 `delta.applyTo(base.<list>)`，其他每个列表以及每个设置字段都保持 `base` 中的值。
  5. `FinanceStorage.save(merged)`，然后 `_applyFinanceData(merged)`（mounted 时在 `setState` 内）、`notifySaved()` 和 `_updateReminderService()`。

  排队的操作结束后，组件仍 mounted 时调用 `after`——在队列之外，因此 `after` 自己可以排入一次保存。
- **用法：** 每个子页面打开方法在压入子页面时为每个列表取一个 `IdListBaseline`，每个列表回调用 `take` 把上报的列表转成增量：
  ```dart
  final subBase = IdListBaseline<Subscription>(_subscriptions, (s) => s.id);
  ...
  onSubscriptionsChanged: (s) {
    _commitSubPage(
      subscriptions: subBase.take(s),
      after: _processSubscriptions,
    );
  },
  ```
  接线于账户和交易（`_openAccounts`）、交易（`_openAnalysis`、`_openSubscriptionDetail`）、订阅和交易（`_openSubscriptions`），以及分类和交易（`_showFinanceMenu` 的分类入口）。
- **备注：** 修复一个丢失更新：子页面持有它打开时的列表，因此它打开期间发生的订阅续费、本地 API 写入或同步，过去会在子页面经 `_saveData` 交回过期的整个列表时被覆盖。现在只有子页面改动过的记录被重放到磁盘上的内容上，它没碰过的记录保留新值。`take` 必须在回调内同步运行，使每次回调只产出它自己的改动；合并规则（按 id upsert、丢弃被移除的 id、不捕获纯重排）记录在 [`id_list_delta.md`](../../../shared/utils/id_list_delta.md)。

### `Future<void> _pickFlowMonth()` <a id="_pickflowmonth"></a>
- **种类：** `_FinancePageState` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 386-455 行）
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
- **来源：** `lib/features/finance/views/finance_page.dart`（第 463-848 行）
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
  6. `totalAssets`：`_accounts` 为空时回退 `monthIncome - monthExpense`；否则用 `accountBalances(_accounts, _transactions, _rateData)`（[`balance_util.md`](../services/balance_util.md)；v1.5.2，此前每个账户各做一遍 `accountBalance`）一遍算出每个账户余额，然后折叠 `_accounts`，读取 `balances[a.id] ?? 0.0` 并用**今天**的 `currentRates` 转换为 `_defaultCurrency`——不同于 `monthExpense`/`monthIncome` 使用的逐交易快照汇率。
  7. 计算 `upcomingSubs = upcomingSubscriptions(_subscriptions, days: 3)`，然后用存储的排序模式和自定义顺序经 `sortSubscriptions` 得到 `activeSubs`，再经 `summarizeSubscriptions` 得到 `subscriptionSummary`——全部来自 [`subscription_summary.md`](../services/subscription_summary.md)。当 `twoPane` 且 `activeSubs` 非空时，把一个 `_SubscriptionOverview` 追加到 `summaryBlocks`，位于下面的 AI 卡片之后。
  8. 在即将续费条（及其 `Divider`）与订阅概览之间，`summaryBlocks` 总是包含一个 [`AiInsightCard`](../../ai/widgets/ai_insight_card.md#aiinsightcard-new)（v1.5.0），`module: InsightModule.finance`、`compact: !twoPane`（堆叠时折叠为一行预览），以及两个 `AiInsightSection`：`l10n.aiFinanceFlow` 涵盖槽位 `flowSummary` 和 `flowAdvice`，`l10n.aiFinanceSubscriptions` 涵盖 `subSummary` 和 `subAdvice`。其 `buildRequest: (language, now)` 用 `now`、`_accounts`、`_categories`、`_transactions`、`_subscriptions`、`_rateData` 和 `_defaultCurrency` 调用 [`buildFinanceInsightFacts`](../services/finance_insight_facts.md#buildfinanceinsightfacts)，后者返回 `null` 时返回 `null`，否则返回 `AiInsightRequest(facts: facts, language: language, now: now)`。端侧 AI 关闭或平台不可能有模型时，卡片什么都不渲染。
  9. 构建带 `AppBar`（账户/分析/订阅/溢出菜单操作，`_loadError != null` 时全部禁用）的 `Scaffold`，正文为：`!_loaded` 时转圈；`_loadError != null` 时 `_FinanceDataError` 视图；否则是 `_SummaryHeader`（喂计算的总计、`missingRatePairs.toList()..sort()` 和把 `_selectedFlowMonth` 按月移位的 prev/next 月回调）的 `Column`、可选即将续费 `Chip` 条、"交易"小节标签，以及空状态消息或喂按最新优先排序的 `monthTransactions`、每行包在 `Dismissible`（从左往右滑动打开编辑；从右往左滑动经 `confirmDelete` 请求删除确认）中的 `buildGroupedTransactionList`（[`grouped_transaction_list.md#buildgroupedtransactionlist`](../widgets/grouped_transaction_list.md#buildgroupedtransactionlist)）。
  10. `FloatingActionButton` 触发 `_addTransaction`，`_loadError != null` 时禁用。
- **用法：** `_FinancePageState` 重建时由 Flutter 框架调用；不直接调用。`FinancePage` 本身从路由器挂载：
  ```dart
  builder: (context, state) => const FinancePage(),
  ```
  （`lib/app/router.dart`）。
- **备注：** 月边界过滤（`monthTransactions`）对流总计用逐交易历史汇率，但对总资产卡片用当前汇率——这是刻意的：过去某月的支出/收入应反映那个月术语下的成本，而总资产是"它们现在值多少"。

## 相关页面

- [财务](../../../../features/finance.md) — 模型字段参考以及本页可选月摘要和分组交易列表如何契合更广的财务功能。
- [订阅计费](../../../../algorithms/subscription-billing.md) — [`_processSubscriptions`](#_processsubscriptions) 经 `SubscriptionProcessor.process` 委托的追赶算法。
- [`balance_util.dart`](../services/balance_util.md) — `convertCurrency`、`accountBalances`，由 [`build`](#build) 用于摘要总计。
- [`finance_storage.md`](../services/finance_storage.md) — `load`/`save` 和 `FinanceData.copyWith`，由 [`_loadDataNow`](#_loaddatanow)、[`_saveDataNow`](#_savedatanow) 和 [`_commitSubPage`](#_commitsubpage) 使用。
- [`exchange_rate_storage.md`](../services/exchange_rate_storage.md) — `load`、`currentRates`、`ratesAt`，由 [`_loadDataNow`](#_loaddatanow) 和 [`build`](#build) 使用。
- [`id_list_delta.dart`](../../../shared/utils/id_list_delta.md) — `IdListBaseline`/`IdListDelta`，即 [`_commitSubPage`](#_commitsubpage) 重放到重新读取的文件上的按 id 合并增量（v1.5.2）。
- [`grouped_transaction_list.dart`](../widgets/grouped_transaction_list.md) — `buildGroupedTransactionList`，用于在 [`build`](#build) 中渲染按日期分组的交易列表。
- [`add_transaction_dialog.dart`](../widgets/add_transaction_dialog.md) — `_addTransaction` 和 `_editTransaction` 显示的对话框。
- [`ai_insight_card.dart`](../../ai/widgets/ai_insight_card.md) 和 [`finance_insight_facts.dart`](../services/finance_insight_facts.md) — `summaryBlocks` 中的端侧 AI 卡片及其得到的事实（v1.5.0）。
- [`subscription_summary.dart`](../services/subscription_summary.md) — `upcomingSubscriptions`、`sortSubscriptions`、`summarizeSubscriptions`，由 [`build`](#build) 用于续费条和订阅概览。
- [`subscription_avatar.dart`](../widgets/subscription_avatar.md) — `_SubscriptionOverviewTile` 中的头像。
- [`subscription_detail_page.dart`](subscription_detail_page.md) — 由 `_openSubscriptionDetail` 压入。
- [`reminder_service.md`](../../../shared/services/reminder_service.md) — `updateSubscriptionData`，由 `_updateReminderService` 保持同步。
- [`auto_sync_service.md`](../../../shared/services/auto_sync_service.md) — `addOnLocalDataChanged`/`notifySaved`，由 `initState`/[`_saveDataNow`](#_savedatanow)/[`_commitSubPage`](#_commitsubpage) 使用。

### `Widget build(BuildContext context)`（`_FinanceBody`） <a id="financebody-build"></a>
- **种类：** `_FinanceBody` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 1163 行）
- **用途：** 把月度摘要和交易列表排成堆叠布局或双栏布局。
- **输入：** `context`；以及组件自己的 `twoPane`、`leftPaneWidth`、`summaryBlocks`、`transactionHeader` 和 `transactionList` 字段。
- **返回：** 堆叠时为 `Column`，分栏时为 `Row`。
- **副作用：** 除构建组件外无。
- **算法：**
  1. `!twoPane` → `Column(children: [...summaryBlocks, transactionHeader, Expanded(transactionList)])`，与 v1.4.1 之前页面的主体完全相同。
  2. 否则是由 `SizedBox(width: leftPaneWidth, child: ListView(summaryBlocks))`、`VerticalDivider(width: 1)` 和承载标题及列表的 `Expanded` 右窗格组成的 `Row`。
- **用法：** 在分栏决策和窗格宽度解析完成后由 `_FinancePageState.build` 构建。
- **备注：** 三个内容槽由页面构建一次、在这里以两种方式排布，因此两种布局不可能显示不同的内容——页面自己刻意做的一个例外除外：自 v1.4.3 起，订阅概览只在双栏排布中被加入 `summaryBlocks`，因为它填的是原本会空着的窗格，而堆叠时它会把手机上的第一笔交易推得更靠下。端侧 AI 卡片（v1.5.0）在两种排布中都有，但堆叠时为 `compact`（折叠为一行预览）。堆叠时，月度摘要本就在第一笔交易出现之前要花掉手机高度的三分之一；分栏时，交易列表——用户真正在读的东西——拿走摘要之外的一切。左窗格本身是 `ListView`，因为很长的续订条加上摘要可能超出紧凑高度，而分栏规则在 480 处仍然放行这种高度。见 [../../../../adaptive-layout.md](../../../../adaptive-layout.md)。

### `Widget build(BuildContext context)`（`_SubscriptionOverview`） <a id="subscriptionoverview-build"></a>
- **种类：** `_SubscriptionOverview` 的方法
- **来源：** `lib/features/finance/views/finance_page.dart`（第 1491 行）
- **用途：** 在财务摘要窗格内渲染订阅页的三项统计和它的进行中列表。
- **输入：** `context`；组件的 `paneWidth`、`summary`、`active`、`categories`、`accounts`、`currencyCode`、`onOpenAll` 和 `onOpenDetail` 字段。
- **返回：** 一个 `Column`。
- **副作用：** 除构建组件外无；两个回调在点击时压入页面。
- **算法：**
  1. 与即将续费页头同样式的页头行（`Icons.repeat`、`financeSubscriptions`），尾部一个调用 `onOpenAll` 的 chevron `IconButton`。
  2. `statColumns = columnCapacity(paneWidth - 32, minItemWidth: subscriptionStatMinWidth, gap: summaryCardGap, maxColumns: 3)`；三张 `_SummaryCard`（月应付、月均、年均）用 `adaptiveTileRows` 打包成行——在窗格整个钳制范围内两张一行，窗格超过约 378 时三张一行。
  3. 一个 `financeActiveSubscriptions` 小标题，然后每个激活订阅一行 `_SubscriptionOverviewTile`，带解析出的分类和账户，点击进入 `onOpenDetail`。
- **用法：** 当 `twoPane` 且至少有一个激活订阅时，由 `_FinancePageState.build` 追加到 `summaryBlocks`——凡是可能渲染为空的块，都属于闸门。
- **备注：** 刻意不含订阅页的提醒控件、历史列表和它自己的即将续费段——主页就在这个块正上方显示一条即将续费条。各行是只读的：编辑、取消和恢复留在订阅页，使主页不长出这些流程的第二份副本。

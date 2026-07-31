# lib/features/finance/views/subscription_detail_page.dart

一个 [`Subscription`](../../../../features/finance.md#model) 的详情页：显示摘要卡片（计费周期标签、至今总花费、下次计费/到期日、取消日期），后跟计到它名下的交易分组列表，带滑动编辑/删除。`nextBillingDate` 和 `cancelType` 如何由 `SubscriptionProcessor` 产生见 [财务](../../../../features/finance.md#subscription-processing)，它们背后的月末钳制见 [订阅计费](../../../../algorithms/subscription-billing.md)。本页本身不做计费/取消逻辑——它只显示和编辑订阅已生成的交易。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `SubscriptionDetailPage({...})` | 构造函数（`SubscriptionDetailPage`） | B | 创建订阅详情页实例。 |
| `createState` | 方法（`SubscriptionDetailPage`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_SubscriptionDetailPageState`） | B | 把 `widget.transactions` 复制进本地可变状态。 |
| [`_filtered`](#filtered) | getter（`_SubscriptionDetailPageState`） | A | 返回此订阅的交易，最新优先。 |
| [`_totalSpent`](#totalspent) | getter（`_SubscriptionDetailPageState`） | A | 求和此订阅的交易，转换为默认币种。 |
| `_deleteTransaction` | 方法（`_SubscriptionDetailPageState`） | B | 从本地状态移除交易并通知父级。 |
| [`_editTransaction`](#edittransaction) | 方法（`_SubscriptionDetailPageState`） | A | 编辑计费交易，同时保留其 `subscriptionId`。 |
| `build` | 方法（`_SubscriptionDetailPageState`） | B | 构建摘要卡片和交易列表。 |
| `_TxTile({...})` | 构造函数（`_TxTile`） | B | 创建交易块实例。 |
| `build` | 方法（`_TxTile`） | B | 构建一笔交易的列表块。 |
| `_buildLeading` | 方法（`_TxTile`，组件辅助） | B | 构建块的前导头像（订阅/账户图像或回退图标）。 |
| `defaultAvatar`（嵌套于 `_buildLeading`） | 本地函数（组件辅助） | B | 构建回退订阅头像。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/views/subscription_detail_page.dart` 返回 12，与上面 12 行精确匹配——每个块都恰好位于其真实声明（构造函数、`createState`、`initState`、getter、方法或 `_buildLeading` 内的嵌套本地函数）正上方；未发现错附在调用点语句上方，也未发现未文档化的真实声明。类声明本身（`SubscriptionDetailPage`、`_SubscriptionDetailPageState`、`_TxTile`）和它们的普通组件字段不带 `/// Purpose:` 块，与本代码库记录可调用成员而非类或数据字段的约定一致。

## 文档

### `List<Transaction> get _filtered` <a id="filtered"></a>
- **种类：** `_SubscriptionDetailPageState` 的 getter
- **来源：** `lib/features/finance/views/subscription_detail_page.dart`（第 70 行）
- **用途：** 返回计到本订阅的每笔交易，最近优先。
- **输入：** 无（读取 `_transactions`、`widget.subscription.id`）。
- **返回：** `List<Transaction>`。
- **副作用：** 无。
- **算法：**
  1. 把 `_transactions` 过滤到 `subscriptionId` 等于 `widget.subscription.id` 的。
  2. 按 `date` 降序排序结果（最近优先）。
- **用法：**
  ```dart
  final filtered = _filtered;
  ...
  child: filtered.isEmpty ? Center(...) : buildGroupedTransactionList(context, filtered, ...),
  ```
- **备注：** 纯粹按 `subscriptionId` 过滤——如果一笔交易曾被重新指向不同订阅（此 UI 任何地方都不暴露），下次重建时它会静默从本列表消失。

### `double get _totalSpent` <a id="totalspent"></a>
- **种类：** `_SubscriptionDetailPageState` 的 getter
- **来源：** `lib/features/finance/views/subscription_detail_page.dart`（第 81 行）
- **用途：** 求和计到本订阅的每笔交易，用每笔交易记录时生效的汇率转换为应用默认币种。
- **输入：** 无（读取 [`_filtered`](#filtered)、`widget.rateData`、`widget.defaultCurrency`）。
- **返回：** `double`，以 `widget.defaultCurrency`。
- **副作用：** 无。
- **算法：**
  1. 从 [`_filtered`](#filtered)（本订阅的交易）开始。
  2. 对每笔交易，经 `widget.rateData.ratesAt(t.rateSnapshotId)`（[`ExchangeRateData.ratesAt`](../services/exchange_rate_storage.md#ratesat)）解析生效的汇率快照，并经 [`convertCurrency`](../services/balance_util.md#convertcurrency) 把 `t.amount` 从 `t.currency` 转换为 `widget.defaultCurrency`。
  3. 从 `0.0` 开始折叠（求和）转换后的金额。
- **用法：**
  ```dart
  Text(
    '${l10n.financeTotalSpent}: $sym${numberFormat.format(_totalSpent)}',
    ...
  )
  ```
- **备注：** 按每笔交易自己的历史汇率快照转换，不是按今天的汇率，因此总计反映实际支付了什么，而不是按当前汇率的重新转换。

### `Future<void> _editTransaction(Transaction tx)` <a id="edittransaction"></a>
- **种类：** `_SubscriptionDetailPageState` 的方法
- **来源：** `lib/features/finance/views/subscription_detail_page.dart`（第 110-144 行）
- **用途：** 为既有订阅计费交易打开增/改交易对话框，然后把此交易的 `subscriptionId` 重新应用到 `AddTransactionDialog` 返回的任何东西上，因为那个对话框没有订阅概念。
- **输入：** `tx` — 被编辑的 `Transaction`。
- **返回：** `Future<void>`。
- **副作用：** 显示 `AddTransactionDialog`（[`../widgets/add_transaction_dialog.md`](../widgets/add_transaction_dialog.md)）；确认后替换 `_transactions` 中的匹配条目并调用 `widget.onTransactionsChanged`。
- **算法：**
  1. 显示预填 `tx` 的 `AddTransactionDialog`。
  2. 用户确认（对话框返回非 null）时，重建全新 `Transaction`，复制对话框结果的每个字段*唯独* `subscriptionId`，后者改为取自原始 `tx.subscriptionId`——否则对话框结果会完全没有 `subscriptionId`。
  3. 在 `setState` 内按 `id` 替换 `_transactions` 中的匹配交易。
  4. 经 `widget.onTransactionsChanged` 通知父级。
- **用法：**
  ```dart
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.startToEnd) {
      _editTransaction(tx);
      return false;
    }
    return confirmDelete(context, l10n.financeThisTransaction);
  },
  ```
- **备注：** 这是文件中唯一经完整构造函数而非 `copyWith` 重建 `Transaction` 的地方——专门为保证 `subscriptionId` 经一个不了解订阅的对话框往返后存活。与 `category_detail_page.dart` 的 `_editTransaction` 对照，后者没有要保留的此类字段，只是原样存储对话框结果。

## 相关页面

- [财务](../../../../features/finance.md) — `Subscription`/`Transaction` 模型字段，以及别处（`subscriptions_page.dart`）实现的取消/恢复语义。
- [`ExchangeRateStorage`](../services/exchange_rate_storage.md) — `ratesAt`，[`_totalSpent`](#totalspent) 使用的历史快照查找。
- [`balance_util.dart`](../services/balance_util.md) — `convertCurrency`，[`_totalSpent`](#totalspent) 使用的跨币种转换。
- [`add_transaction_dialog.dart`](../widgets/add_transaction_dialog.md) — [`_editTransaction`](#edittransaction) 显示的对话框。
- [`grouped_transaction_list.dart`](../widgets/grouped_transaction_list.md) — `buildGroupedTransactionList`，用于在 `build` 中渲染按日期分组的交易列表。

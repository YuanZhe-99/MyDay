# lib/features/finance/views/category_detail_page.dart

一个 [`Category`](../../../../features/finance.md#model) 的下钻页（或 `categoryId` 为 `null` 时，一个交易类型的"未分类"桶）：月度摘要卡片后跟匹配交易的分组列表，带滑动编辑/删除和浮动添加按钮。这是 `categories_page.dart` 和财务分析页可点击分类明细在点击分类时都压入的页面。它如何融入分类下钻功能见 [财务](../../../../features/finance.md#views-and-analysis-page)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `CategoryDetailPage({...})` | 构造函数（`CategoryDetailPage`） | B | 创建分类详情页实例。 |
| `createState` | 方法（`CategoryDetailPage`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_CategoryDetailPageState`） | B | 把 `widget.transactions` 复制进本地可变状态。 |
| [`_filtered`](#filtered) | getter（`_CategoryDetailPageState`） | A | 返回匹配本页类型和分类的交易，最新优先。 |
| [`_monthFiltered`](#monthfiltered) | getter（`_CategoryDetailPageState`） | A | 把 `_filtered` 限制到当前日历月。 |
| [`_monthTotal`](#monthtotal) | getter（`_CategoryDetailPageState`） | A | 求和本月匹配交易，转换为默认币种。 |
| [`_addTransaction`](#addtransaction) | 方法（`_CategoryDetailPageState`） | A | 添加预播种本页分类和类型的交易。 |
| `_deleteTransaction` | 方法（`_CategoryDetailPageState`） | B | 从本地状态移除交易并通知父级。 |
| `_editTransaction` | 方法（`_CategoryDetailPageState`） | B | 编辑交易并在本地状态中替换它。 |
| `build` | 方法（`_CategoryDetailPageState`） | B | 构建月度摘要卡片和交易列表。 |
| `_TxTile({...})` | 构造函数（`_TxTile`） | B | 创建交易块实例。 |
| `build` | 方法（`_TxTile`） | B | 构建一笔交易的列表块。 |
| `_buildLeading` | 方法（`_TxTile`，组件辅助） | B | 构建块的前导头像（账户图像或回退图标）。 |
| `defaultAvatar`（嵌套于 `_buildLeading`） | 本地函数（组件辅助） | B | 构建回退分类交易头像。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/views/category_detail_page.dart` 返回 14，与上面 14 行精确匹配——每个块都恰好位于其真实声明（构造函数、`createState`、`initState`、getter、方法或 `_buildLeading` 内的嵌套本地函数）正上方；未发现错附在调用点语句上方，也未发现未文档化的真实声明。类声明本身（`CategoryDetailPage`、`_CategoryDetailPageState`、`_TxTile`）和它们的普通组件字段不带 `/// Purpose:` 块，与本代码库记录可调用成员而非类或数据字段的约定一致。

## 文档

### `List<Transaction> get _filtered` <a id="filtered"></a>
- **种类：** `_CategoryDetailPageState` 的 getter
- **来源：** `lib/features/finance/views/category_detail_page.dart`（第 74 行）
- **用途：** 返回匹配本页交易类型和分类的每笔交易——包括 `widget.categoryId` 为 `null` 的"未分类"情形——最近优先。
- **输入：** 无（读取 `_transactions`、`widget.transactionType`、`widget.categoryId`）。
- **返回：** `List<Transaction>`。
- **副作用：** 无。
- **算法：**
  1. 把 `_transactions` 过滤到 `type` 等于 `widget.transactionType` **且** `categoryId` 等于 `widget.categoryId` 的。
  2. 按 `date` 降序排序结果。
- **用法：**
  ```dart
  final filtered = _filtered;
  ...
  child: filtered.isEmpty ? Center(...) : buildGroupedTransactionList(context, filtered, ...),
  ```
- **备注：** `categoryId` 上的 `null == null` 匹配正是让本页兼作"未分类"视图的东西：以 `categoryId: null` 构造它选择给定类型下未分配分类的每笔交易，而不是匹配不到任何东西。

### `List<Transaction> get _monthFiltered` <a id="monthfiltered"></a>
- **种类：** `_CategoryDetailPageState` 的 getter
- **来源：** `lib/features/finance/views/category_detail_page.dart`（第 89-94 行）
- **用途：** 把 [`_filtered`](#filtered) 进一步限制到当前日历月内的交易，供月度摘要卡片。
- **输入：** 无（读取 [`_filtered`](#filtered) 和设备当前日期）。
- **返回：** `List<Transaction>`。
- **副作用：** 无。
- **算法：** 捕获 `DateTime.now()`，然后把 [`_filtered`](#filtered) 过滤到 `date.year`/`date.month` 都匹配当前年/月的条目。
- **用法：**
  ```dart
  double get _monthTotal {
    return _monthFiltered.fold(0.0, (sum, t) => sum + convertCurrency(...));
  }
  ```
- **备注：** 每次访问重新计算（不缓存），因此页面跨月边界保持打开并重建时摘要保持正确。

### `double get _monthTotal` <a id="monthtotal"></a>
- **种类：** `_CategoryDetailPageState` 的 getter
- **来源：** `lib/features/finance/views/category_detail_page.dart`（第 101-113 行）
- **用途：** 求和本月匹配交易，用每笔交易记录时生效的汇率转换为应用默认币种。
- **输入：** 无（读取 [`_monthFiltered`](#monthfiltered)、`widget.rateData`、`widget.defaultCurrency`）。
- **返回：** `double`，以 `widget.defaultCurrency`。
- **副作用：** 无。
- **算法：** 对 [`_monthFiltered`](#monthfiltered) 中每笔交易，解析 `widget.rateData.ratesAt(t.rateSnapshotId)`（[`ExchangeRateData.ratesAt`](../services/exchange_rate_storage.md#ratesat)）并经 [`convertCurrency`](../services/balance_util.md#convertcurrency) 把 `t.amount` 从 `t.currency` 转换为 `widget.defaultCurrency`；折叠（求和）结果。
- **用法：**
  ```dart
  Text(
    '$sym${numberFormat.format(_monthTotal)}',
    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: totalColor),
  )
  ```
- **备注：** 与 `subscription_detail_page.dart` 的 `_totalSpent` 一样，按每笔交易自己的历史汇率快照转换，而不是按今天的汇率。

### `Future<void> _addTransaction()` <a id="addtransaction"></a>
- **种类：** `_CategoryDetailPageState` 的方法
- **来源：** `lib/features/finance/views/category_detail_page.dart`（第 120-137 行）
- **用途：** 打开预播种本页分类和交易类型的添加交易对话框，使从分类详情页添加的交易默认落入该分类。
- **输入：** 无（读取 `widget.category`、`widget.transactionType`、`widget.rateData`、`widget.defaultCurrency`、`widget.accountPickerSettings`）。
- **返回：** `Future<void>`。
- **副作用：** 显示 `AddTransactionDialog`（[`../widgets/add_transaction_dialog.md`](../widgets/add_transaction_dialog.md)）；确认后把新交易插入 `_transactions` 并调用 `widget.onTransactionsChanged`。
- **算法：**
  1. 带 `initialCategoryId: widget.category?.id`（未分类视图为 `null`）和 `initialType: widget.transactionType` 预填显示 `AddTransactionDialog`。
  2. 用户确认时，把结果交易插入 `_transactions` 的索引 `0` 并经 `widget.onTransactionsChanged` 通知父级。
- **用法：**
  ```dart
  floatingActionButton: FloatingActionButton(
    onPressed: _addTransaction,
    child: const Icon(Icons.add),
  ),
  ```
- **备注：** 插入位置（索引 `0`）实际上不决定显示顺序——`build` 中显示的列表总是从 [`_filtered`](#filtered) 重新派生，其自己的日期排序无论插入顺序如何都接管。与 `subscription_detail_page.dart`（没有添加按钮——订阅交易由 `SubscriptionProcessor` 生成）不同，本页让用户直接添加。

## 相关页面

- [财务](../../../../features/finance.md) — `Category` 模型字段，以及本页实现"详情"半边的分类下钻/明细功能（明细本身在 `analysis_page.dart` 中计算）。
- [`ExchangeRateStorage`](../services/exchange_rate_storage.md) — `ratesAt`，由 [`_monthTotal`](#monthtotal) 使用。
- [`balance_util.dart`](../services/balance_util.md) — `convertCurrency`，由 [`_monthTotal`](#monthtotal) 使用。
- [`add_transaction_dialog.dart`](../widgets/add_transaction_dialog.md) — [`_addTransaction`](#addtransaction) 和 `_editTransaction` 显示的对话框。
- [`grouped_transaction_list.dart`](../widgets/grouped_transaction_list.md) — `buildGroupedTransactionList`，用于在 `build` 中渲染按日期分组的交易列表。

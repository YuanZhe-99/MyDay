# lib/features/finance/widgets/grouped_transaction_list.dart

一个被每个显示平铺、按日期排序交易列表的财务页面（账户详情页、分类详情页和订阅详情页）使用的小型共享渲染辅助：它把 `List<Transaction>` 变成 `ListView`，在日期变化处插入外观粘性的 `yyyy-MM-dd` 日期页头行。它操作的 `Transaction` 模型见 [财务](../../../../features/finance.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`buildGroupedTransactionList`](#buildgroupedtransactionlist) | 顶层函数 | A | 构建把排序交易列表分组到日期页头行下的 `ListView`。 |

`grep -c 'Purpose:' lib/features/finance/widgets/grouped_transaction_list.dart` 报告 1，与本文件唯一的真实声明匹配。未发现错附或未文档化声明。

## 文档

### `Widget buildGroupedTransactionList(BuildContext context, List<Transaction> sorted, Widget Function(Transaction) tileBuilder)` <a id="buildgroupedtransactionlist"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/widgets/grouped_transaction_list.dart`（第 12 行）
- **用途：** 把按日期排序的交易列表渲染为可滚动列表，日历日期每次变化时插入日期页头行。
- **输入：** `context` — 只用于读取当前 `Theme`；`sorted` — 交易，调用方必须已排序，使共享日期的所有交易连续（此函数不排序）；`tileBuilder` — 渲染单个交易行的回调，每笔交易调用一次。
- **返回：** `Widget` — 覆盖页头行和交易行的 `ListView.builder`。
- **副作用：** 除构建组件外无（无状态、无 I/O）。
- **算法：**
  1. 单趟遍历 `sorted`，经 `DateFormat('yyyy-MM-dd')` 把每笔交易的 `date` 格式化为 `yyyy-MM-dd`。
  2. 格式化日期与上次见到的日期不同时，在追加交易项本身之前向平铺 `items` 列表追加页头项（`isHeader: true, label: dateKey`）。
  3. 在 `items` 上构建单个 `ListView.builder`：页头项渲染为 `surfaceContainerLow` 色、带内边距、`labelMedium`/`onSurfaceVariant` 样式的 `Text`；交易项完全委托给 `tileBuilder(item.tx!)`。
  4. 因为分组是只以最后见到的日期字符串为键的单个前向趟，传入未排序（或多日期交错）列表的调用方会为每个日期*转换*得到一个页头，而不是每个唯一日期一个——列表中后来重现的日期会产生第二个页头。
- **用法：**
  ```dart
  : buildGroupedTransactionList(context, filtered, (tx) {
      final isExpense = tx.type == TransactionType.expense;
      final isTransfer = tx.type == TransactionType.transfer;
      final sign = isExpense ? '-' : (isTransfer ? '' : '+');
      final color = isExpense ? theme.colorScheme.error : Colors.green;
      final dateStr = DateFormat('MM-dd HH:mm').format(tx.date);
      // ...builds the transaction ListTile...
    })
  ```
  （`lib/features/finance/views/accounts_page.dart`，账户详情交易列表；`category_detail_page.dart`、`subscription_detail_page.dart` 和 `finance_page.dart` 中重复相同模式。）
- **备注：** 依赖调用方保证排序——此函数不知道升序还是降序日期顺序，只是对它得到的任意连续同日交易段分组。

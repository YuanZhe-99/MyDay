# lib/shared/utils/id_list_delta.dart

子页面保存的按 id 合并支持（v1.5.2）。子页面（账户、订阅、分类、伴侣、玩具、体位、身体设置等）接收一个记录列表，编辑它，再经回调交回整个列表。原样写入该列表会覆盖子页面打开期间其他写入方（订阅续费循环、本地 API 服务器、WebDAV 同步）所做的任何更改。`IdListDelta` 只记录子页面相对其起始列表所做的更改，按记录 id 键控；`applyTo` 把这些更改重放到刚加载的磁盘列表上。`IdListBaseline` 保存子页面上次报告的列表，使每次回调只产生它自己的更改。本文件由 Finance 页面（见 [finance_page.dart](../../features/finance/views/finance_page.md)）和 Intimacy 页面（见 [intimacy_page.dart](../../features/intimacy/views/intimacy_page.md)）的 `_commitSubPage` 使用。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`IdListDelta`（构造函数）](#idlistdelta-new) | 构造函数（`IdListDelta<T>`） | A | 从已算好的部分创建差量。 |
| [`IdListDelta.diff`](#idlistdelta-diff) | 工厂构造函数（`IdListDelta<T>`） | A | 计算基线列表与编辑后列表之间的更改。 |
| [`isEmpty`](#isempty) | getter（`IdListDelta<T>`） | A | 报告子页面是否什么都没改。 |
| [`applyTo`](#applyto) | 方法（`IdListDelta<T>`） | A | 把差量重放到刚加载的列表上。 |
| [`IdListBaseline`（构造函数）](#idlistbaseline-new) | 构造函数（`IdListBaseline<T>`） | A | 从交给子页面的列表开始跟踪。 |
| [`take`](#take) | 方法（`IdListBaseline<T>`） | A | 把回调的列表与上一次的比较，然后推进基线。 |

`grep -c 'Purpose:' lib/shared/utils/id_list_delta.dart` 报告 6，与本文件全部六个真实声明精确匹配。未发现错附或未文档化声明。按 `shared/` 的一揽子规则，每个声明都是 Tier A。公开字段 `upserts`、`upsertIndexes`、`removedIds` 和私有字段 `_idOf`、`_baseline` 带字段文档注释而非 `Purpose:` 块，不单独计数。

## 文档

### `IdListDelta({required List<T> upserts, required List<int> upsertIndexes, required Set<String> removedIds, required String Function(T item) idOf})` <a id="idlistdelta-new"></a>
- **种类：** `IdListDelta<T>` 的构造函数
- **来源：** `lib/shared/utils/id_list_delta.dart`（第 26 行）
- **用途：** 从已算好的部分创建差量。
- **输入：** `upserts` — 子页面新增或替换的项，按编辑后列表的顺序；`upsertIndexes` — 每个 upsert 在编辑后列表中的索引；`removedIds` — 在基线中存在但编辑后列表中缺失的 id；`idOf` — 记录 id 访问器。
- **返回：** 新 `IdListDelta<T>`。
- **副作用：** 无。
- **算法：** 字段初始化构造函数；断言 `upserts.length == upsertIndexes.length`，并把 `idOf` 存为私有 `_idOf`。
- **用法：** 由 `IdListDelta.diff`（见下）调用。生产代码不直接调用它。
- **备注：** 优先用 `IdListDelta.diff`；按自己的文档注释，此构造函数为该工厂和测试而存在。

### `factory IdListDelta.diff(List<T> baseline, List<T> edited, String Function(T item) idOf)` <a id="idlistdelta-diff"></a>
- **种类：** `IdListDelta<T>` 的工厂构造函数
- **来源：** `lib/shared/utils/id_list_delta.dart`（第 42 行）
- **用途：** 计算 `baseline`（子页面起始列表的副本）与 `edited`（它交回的列表）之间的更改。
- **输入：** `baseline`；`edited`；`idOf` — 记录 id 访问器。
- **返回：** `IdListDelta<T>`。
- **副作用：** 无。
- **算法：**
  1. 按 id 索引 `baseline`（`putIfAbsent`，因此重复 id 以首次出现者为准）。
  2. 按顺序遍历 `edited`，收集见到的每个 id。id 不在基线中、或其基线对象与它不 `identical` 的项成为 upsert，其在 `edited` 中的索引记入 `upsertIndexes`。
  3. `removedIds` = 未出现在 `edited` 中的每个基线 id。
- **用法：**
  ```dart
  final delta = IdListDelta.diff(baseline, t.edited, id);
  ```
  （`test/id_list_delta_test.dart`。）生产代码经 `IdListBaseline.take` 到达它。
- **备注：** 更改检测按对象同一性而非相等性：模型不可变，因此编辑总会产生新对象，而未触碰的记录就是同一个对象。`baseline` 必须是副本（`List.of`），因为子页面会修改并交回它们收到的那个列表本身——未复制的基线会已经包含编辑。

### `bool get isEmpty` <a id="isempty"></a>
- **种类：** `IdListDelta<T>` 的 getter
- **来源：** `lib/shared/utils/id_list_delta.dart`（第 81 行）
- **用途：** 报告子页面是否什么都没改。
- **输入：** 无。
- **返回：** `bool` — 没有 upsert 也没有移除 id 时为 `true`。
- **副作用：** 无。
- **算法：** `upserts.isEmpty && removedIds.isEmpty`。
- **用法：** 由 `applyTo` 首先检查，此时它返回 `fresh` 的普通副本。
- **备注：** 未更改项的纯重排按设计不被捕获：每个项保持其同一性，因此差量为空，磁盘上的顺序生效。自定义顺序另行持久化（排序模式/自定义顺序设置），不经记录列表。

### `List<T> applyTo(List<T> fresh)` <a id="applyto"></a>
- **种类：** `IdListDelta<T>` 的方法
- **来源：** `lib/shared/utils/id_list_delta.dart`（第 91 行）
- **用途：** 把此差量重放到刚加载的列表上。
- **输入：** `fresh` — 来自磁盘的当前列表。
- **返回：** 新 `List<T>`；`fresh` 本身不被修改。
- **副作用：** 无。
- **算法：**
  1. 若 `isEmpty`，返回 `List<T>.of(fresh)`。
  2. 复制 `fresh`，丢弃 id 在 `removedIds` 中的每个项。
  3. 按顺序处理每个 upsert：若结果中有同 id 项，原位替换；否则把 upsert 插入到 `min(其编辑后索引, result.length)`。
- **用法：**
  ```dart
  final merged = base.copyWith(
    accounts: accounts?.applyTo(base.accounts),
    categories: categories?.applyTo(base.categories),
    transactions: transactions?.applyTo(base.transactions),
    subscriptions: subscriptions?.applyTo(base.subscriptions),
  );
  ```
  （`lib/features/finance/views/finance_page.dart`，`_commitSubPage`，在页面的 I/O 队列内重新读取 `finance_data.json` 之后；`intimacy_page.dart` 的 `_commitSubPage` 对伴侣、玩具、体位、记录和周期记录做同样的事。）
- **备注：**
  - id 已被并发删除（不在 `fresh` 中）的 upsert 会在其编辑后索引处被重新加入：用户的编辑胜过并发删除。
  - 子页面未触碰的记录保持其新值，包括其他写入方期间新增、更改或删除的记录（在别处被删除的未触碰记录保持删除）。
  - 插入位置被钳制到当前长度，因此 `fresh` 变短时新项也不会抛出。

### `IdListBaseline(List<T> initial, String Function(T item) idOf)` <a id="idlistbaseline-new"></a>
- **种类：** `IdListBaseline<T>` 的构造函数
- **来源：** `lib/shared/utils/id_list_delta.dart`（第 122 行）
- **用途：** 从交给子页面的列表开始跟踪。
- **输入：** `initial` — 子页面打开时的列表；`idOf` — 记录 id 访问器。
- **返回：** 新 `IdListBaseline<T>`。
- **副作用：** 无。
- **算法：** 把 `List<T>.of(initial)` 存为私有 `_baseline`，把 `idOf` 存为 `_idOf`。
- **用法：**
  ```dart
  final accountBase = IdListBaseline<Account>(_accounts, (a) => a.id);
  final txBase = IdListBaseline<Transaction>(_transactions, (t) => t.id);
  ```
  （`lib/features/finance/views/finance_page.dart`，`_openAccounts`，在推入 `AccountsPage` 之前创建；`_openAnalysis`、`_openSubscriptions`、`_openSubscriptionDetail` 和 `_showFinanceMenu` 的分类入口遵循相同模式；`intimacy_page.dart` 的 `_openPartnerManagement`、`_openToyManagement`、`_openPositionManagement` 和 `_openBodySettings` 为子页面可能报告的每个列表各创建一个基线。）
- **备注：** 复制 `initial` 是因为子页面会修改它们收到的列表；没有副本，基线会悄悄跟随子页面的编辑，每次差量都为空。

### `IdListDelta<T> take(List<T> edited)` <a id="take"></a>
- **种类：** `IdListBaseline<T>` 的方法
- **来源：** `lib/shared/utils/id_list_delta.dart`（第 131 行）
- **用途：** 把子页面回调的列表与上次报告的列表比较，然后推进基线。
- **输入：** `edited` — 子页面刚报告的列表。
- **返回：** 只含本次回调更改的 `IdListDelta<T>`。
- **副作用：** 用 `List<T>.of(edited)` 替换存储的基线。
- **算法：** `delta = IdListDelta<T>.diff(_baseline, edited, _idOf)`；`_baseline = List<T>.of(edited)`；返回 `delta`。
- **用法：**
  ```dart
  onChanged: (updated) {
    _commitSubPage(partners: partnerBase.take(updated));
  },
  ```
  （`lib/features/intimacy/views/intimacy_page.dart`，`_openPartnerManagement`；Finance 页面的 `_openAccounts` 用 `accountBase.take(a)` 做同样的事。）
- **备注：** 每次回调恰好调用一次，同步地、在任何 `await` 之前——基线必须按回调顺序推进，使第二次回调不会重新发送第一次的更改。由 `test/id_list_delta_test.dart`（"IdListBaseline yields only each callback's own changes"）覆盖；端到端行为（账户页面打开期间写入的续费得以保留；伴侣改名时别处新增的记录得以保留）由 `test/subpage_merge_test.dart` 覆盖。

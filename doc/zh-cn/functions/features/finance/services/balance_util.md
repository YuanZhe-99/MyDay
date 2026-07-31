# lib/features/finance/services/balance_util.dart

财务的核心余额/币种转换逻辑，外加一次性强制余额到调整交易迁移。账户余额纯粹通过折叠 [`Transaction`](../models/finance.md#transaction-new) 计算（`accountBalance`/`accountBalanceBefore`）——没有存储的"当前余额"字段——每个跨币种金额都经 [`convertCurrency`](#convertcurrency)，它先试直接汇率、再试反向汇率、然后试经中间币种的路径，最后才回退到失真的 1:1 转换。本文件实现的迁移见 [财务](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)，转换逻辑在功能中的角色见 [财务](../../../../features/finance.md#exchange-rates)；[`ExchangeRateStorage`](exchange_rate_storage.md) 是 `convertCurrency` 和 `accountBalance` 读取汇率的快照历史。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`ForcedBalanceMigrationResult()`](#forcedbalancemigrationresult-new) | const 构造函数（`ForcedBalanceMigrationResult`） | A | 打包迁移后的账户/交易以及是否有任何变化。 |
| [`currencySymbol`](#currencysymbol) | 顶层函数 | A | 返回币种代码的显示符号。 |
| [`_findRate`](#findrate) | 顶层函数 | A | 找两个币种之间的直接或反向汇率。 |
| [`convertCurrency`](#convertcurrency) | 顶层函数 | A | 经直接/反向/中间汇率在币种间转换金额。 |
| [`accountBalance`](#accountbalance) | 顶层函数 | A | 以账户自己的币种计算账户余额。 |
| [`accountBalanceBefore`](#accountbalancebefore) | 顶层函数 | A | 计算账户在给定日期之前瞬间的余额。 |
| [`isForcedBalanceSentinelDate`](#isforcedbalancesentineldate) | 顶层函数 | A | 日期是否为强制余额迁移哨兵。 |
| [`hasForcedBalanceSentinel`](#hasforcedbalancesentinel) | 顶层函数 | A | 账户是否已使用强制余额哨兵。 |
| [`accountWithForcedBalanceSentinel`](#accountwithforcedbalancesentinel) | 顶层函数 | A | 返回强制余额字段被设为哨兵的账户副本。 |
| [`migrateForcedBalances`](#migrateforcedbalances) | 顶层函数 | A | 把旧强制余额迁移为普通调整交易。 |
| [`_forcedBalanceMigrationDelta`](#forcedbalancemigrationdelta) | 顶层函数 | A | 计算一个账户迁移所需的调整金额。 |
| [`_forcedBalanceMigrationTransactionId`](#forcedbalancemigrationtransactionid) | 顶层函数 | A | 构建迁移调整交易的确定性 id。 |
| [`_forcedBalanceAdjustmentDate`](#forcedbalanceadjustmentdate) | 顶层函数 | A | 选择记录迁移调整交易的日期。 |
| [`_accountTransactionDelta`](#accounttransactiondelta) | 顶层函数 | A | 计算一笔交易对账户余额的带符号贡献。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/services/balance_util.dart` 返回 14，与上面 14 行精确匹配——每个块都恰好位于其真实声明（构造函数或顶层函数）正上方；未发现错附在调用点语句上方。文件中唯一的其他声明，顶层 `final DateTime forcedBalanceSentinelDate = ...` 变量，不带 `/// Purpose:` 块，与本代码库记录可调用成员而非普通数据的约定一致，不构成未文档化的可调用声明。全部 14 个文档化声明分类为 Tier A：本文件是财务功能的核心余额/转换/迁移逻辑，每个函数都含真实分支、循环，或（对短 id/日期辅助）实现 [财务](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions) 描述的强制余额迁移算法核心的不变量——没有纯透传访问器。

## 文档

### `const ForcedBalanceMigrationResult({required List<Account> accounts, required List<Transaction> transactions, required bool changed})` <a id="forcedbalancemigrationresult-new"></a>
- **种类：** `ForcedBalanceMigrationResult` 的 const 构造函数
- **来源：** `lib/features/finance/services/balance_util.dart`（第 19 行）
- **用途：** 保存 [`migrateForcedBalances`](#migrateforcedbalances) 一次运行产生的规范化财务负载——（可能未变的）账户/交易加是否有任何实际变化。
- **输入：** 三个字段都必填。
- **返回：** 新的 `ForcedBalanceMigrationResult`。
- **副作用：** 无。
- **算法：** 平凡 `const` 字段赋值构造函数。
- **用法：**
  ```dart
  return ForcedBalanceMigrationResult(
    accounts: migratedAccounts,
    transactions: migratedTransactions,
    changed: changed,
  );
  ```
  （`lib/features/finance/services/balance_util.dart:250-254`，[`migrateForcedBalances`](#migrateforcedbalances) 的返回值。）
- **备注：** `changed` 让 `FinanceStorage.load()` 和 `WebDAVService._migrateFinanceForcedBalances` 之类的调用方跳过重新保存无需迁移的数据。

### `String currencySymbol(String code)` <a id="currencysymbol"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/balance_util.dart`（第 32 行）
- **用途：** 为受支持币种代码返回短显示符号，供整个财务 UI 的金额格式化。
- **输入：** `code` — ISO 币种代码，如 `'CNY'`、`'USD'`。
- **返回：** `String` — 符号（如 `'¥'`、`'\$'`、`'€'`、`'C\$'`），不是显式列出的 14 个币种之一时原样返回 `code`。
- **副作用：** 无。
- **算法：** 对 `code` 的 `switch` 表达式，14 个显式 case（`CNY`/`JPY` 都映射到 `'¥'`）加 `_ => code` 回退。
- **用法：**
  ```dart
  prefixText: '${currencySymbol(_currency)} ',
  ```
  （`lib/features/finance/widgets/add_transaction_dialog.dart:290`；`accounts_page.dart`、`subscriptions_page.dart`、`analysis_page.dart`、`category_detail_page.dart`、`subscription_detail_page.dart` 和 `finance_page.dart` 中显示币种金额的任何地方都普遍使用。）
- **备注：** 不可识别的币种代码优雅退化为显示原始代码而不是符号，而不是抛出。

### `double? _findRate(Map<String, double> rates, String from, String to)` <a id="findrate"></a>
- **种类：** 顶层函数（本文件私有）
- **来源：** `lib/features/finance/services/balance_util.dart`（第 56 行）
- **用途：** 查找两个币种之间的汇率，先试直接对键，再试反向（取倒数）对键。
- **输入：** `rates` — `'FROM_TO' -> rate` 映射；`from`、`to`。
- **返回：** `double?` — `from == to` 时为 `1.0`；直接汇率存在则它；只有反向对存在（且非零）时 `1.0 / reverse`；两者都不存在时 `null`。
- **副作用：** 无。
- **算法：** 相同币种短路为 `1.0`；查 `rates['${from}_$to']`；缺席时查 `rates['${to}_$from']` 并取倒数（防除零）。
- **用法：** 在 [`convertCurrency`](#convertcurrency) 内调用两次——一次做 `from`/`to` 之间的直接/反向查找，一次对每个候选中间币种做两跳转换的每条腿。
- **备注：** 仅本文件内部使用的辅助。

### `double convertCurrency(Map<String, double> rates, double amount, String from, String to, {void Function(String from, String to)? onMissingRate})` <a id="convertcurrency"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/balance_util.dart`（第 74 行）
- **用途：** 用可用的直接、反向或中间币种汇率路径在两个币种间转换金额，完全无路径时回退 1:1 转换（并报告它）。
- **输入：** `rates` — 要搜索的汇率映射；`amount`、`from`、`to`；`onMissingRate` — 只在 1:1 回退被使用时以 `(from, to)` 调用的可选回调，使调用方能向用户浮出静默失真。
- **返回：** `double` — 转换后的金额。
- **副作用：** 无汇率路径存在时调用 `onMissingRate(from, to)`；否则无。
- **算法：** 摘要见 [财务](../../../../features/finance.md#exchange-rates)。按顺序：
  1. 相同币种：原样返回 `amount`。
  2. 直接/反向：[`_findRate`](#findrate) 找到时返回 `amount * rate`。
  3. 中间：对 `['CNY', 'USD', 'EUR']` 每个（跳过等于 `from`/`to` 的），经 `_findRate` 试两条腿；两条腿都解析时返回 `amount * leg1 * leg2`。
  4. 无路径：调用 `onMissingRate?.call(from, to)` 并原样返回 `amount`（1:1 回退）。
- **用法：**
  ```dart
  convertCurrency(
    _rateData.ratesAt(t.rateSnapshotId),
    t.amount,
    t.currency,
    _defaultCurrency,
    onMissingRate: trackMissingRate,
  ),
  ```
  （`lib/features/finance/views/finance_page.dart:413-419`，把每月的交易转换为默认币种，同时跟踪任何回退到 1:1 的对，使财务主页摘要能警告它们。）
- **备注：** 中间币种搜索顺序固定（`CNY` 先，然后 `USD`、`EUR`）——从不尝试经此列表之外的币种的汇率路径，即使它本可解析。

### `double accountBalance(Account account, List<Transaction> transactions, ExchangeRateData rateData)` <a id="accountbalance"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/balance_util.dart`（第 102 行）
- **用途：** 以账户自己的币种、纯粹通过折叠每笔交易的贡献计算账户当前余额——没有存储的余额字段。
- **输入：** `account`；`transactions` — 完整交易列表（未预过滤）；`rateData`。
- **返回：** `double`。
- **副作用：** 无。
- **算法：** 经 [`_accountTransactionDelta`](#accounttransactiondelta) 折叠 `transactions`，求和每笔交易对 `account` 的带符号贡献。
- **用法：**
  ```dart
  final currentBalance = accountBalance(
    savedAccount,
    _transactions,
    widget.rateData,
  );
  ```
  （`lib/features/finance/views/accounts_page.dart:401-405`，账户编辑后立即计算余额，用于派生 [财务](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions) 描述的调整交易金额。）
- **备注：** 每次调用都遍历*整个*交易列表——显示多个账户余额的调用方（如账户列表页）每次重建对每个账户调用一次，而不是单趟计算所有余额。

### `double accountBalanceBefore(Account account, List<Transaction> transactions, ExchangeRateData rateData, DateTime before)` <a id="accountbalancebefore"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/balance_util.dart`（第 121 行）
- **用途：** 计算账户在给定日期之前瞬间本会有的余额，供分析页的总资产趋势重建。
- **输入：** `account`；`transactions`；`rateData`；`before` — 排他截止。
- **返回：** `double`。
- **副作用：** 无。
- **算法：** 与 [`accountBalance`](#accountbalance) 相同的折叠，但跳过 `date` 不严格早于 `before` 的任何交易。
- **用法：**
  ```dart
  final balance = accountBalanceBefore(
    account,
    _transactions,
    widget.rateData,
    before,
  );
  ```
  （`lib/features/finance/views/analysis_page.dart:862-867`，沿总资产趋势图在采样点重建每个账户的余额。）
- **备注：** `before` 是排他的——恰好 dated `before` 的交易不计入，这正是分析页的采样点迭代把*下一*期的开始作为 `before` 传入、以包含当前期结束前所有内容的原因。

### `bool isForcedBalanceSentinelDate(DateTime date)` <a id="isforcedbalancesentineldate"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/balance_util.dart`（第 142 行）
- **用途：** 检测日期是否为强制余额迁移哨兵（`1970-01-01T00:00:00`），无论它编码为 UTC 纪元零还是匹配那些日历字段的本地时间午夜。
- **输入：** `date`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** `date.toUtc().millisecondsSinceEpoch == 0` 时为 `true`；否则只在 `date` 的年/月/日/时/分/秒/毫秒/微秒字段每个都恰好匹配 1970-01-01 00:00:00.000000 时为 `true`。
- **用法：** 从 [`hasForcedBalanceSentinel`](#hasforcedbalancesentinel) 和 [`_forcedBalanceAdjustmentDate`](#forcedbalanceadjustmentdate) 调用——两者都是本文件内部。
- **备注：** 双重检查（UTC-纪元零 OR 本地午夜-1970）存在是因为作为 `forcedBalanceSentinelDate`（总是 UTC）构建的 `DateTime` 与从省略 UTC 标记的旧磁盘记录解析的 `DateTime` 可能都表示"哨兵"但彼此不 `==` 相等。

### `bool hasForcedBalanceSentinel(Account account)` <a id="hasforcedbalancesentinel"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/balance_util.dart`（第 159 行）
- **用途：** 决定账户的强制余额字段是否已被哨兵替换——即旧强制余额状态是否已被丢弃，迁移对该账户是空操作。
- **输入：** `account`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** `(account.forcedBalance ?? 0) == 0 && account.forcedBalanceDate != null && isForcedBalanceSentinelDate(account.forcedBalanceDate!)`。
- **用法：**
  ```dart
  } else if (a.forcedBalance != null && !hasForcedBalanceSentinel(a)) {
    _balanceController.text = a.forcedBalance!.toStringAsFixed(2);
    _forcedBalanceDate = a.forcedBalanceDate ?? DateTime.now();
  }
  ```
  （`lib/features/finance/views/accounts_page.dart:1563-1565`，决定是否在编辑账户对话框中显示旧强制余额值；也门控 [`migrateForcedBalances`](#migrateforcedbalances) 内的逐账户分支。）
- **备注：** 这是决定账户是否仍携带迁移前强制余额状态的唯一门——UI 和迁移循环内部都用它。

### `Account accountWithForcedBalanceSentinel(Account account, {DateTime? modifiedAt})` <a id="accountwithforcedbalancesentinel"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/balance_util.dart`（第 169 行）
- **用途：** 返回强制余额字段被哨兵（`forcedBalance: 0`、`forcedBalanceDate: 1970-01-01T00:00:00.000Z`）替换、其他每个字段保留的账户副本。
- **输入：** `account`；`modifiedAt` — 可选覆盖，否则保留 `account.modifiedAt`。
- **返回：** 新的 `Account`。
- **副作用：** 无。
- **算法：** 逐字复制每个非余额字段重建 `Account`，`forcedBalance: 0`、`forcedBalanceDate: forcedBalanceSentinelDate`。
- **用法：**
  ```dart
  final account = accountWithForcedBalanceSentinel(submittedAccount);
  final adjTx = _balanceAdjustmentTransaction(account: account, ...);
  ```
  （`lib/features/finance/views/accounts_page.dart:360-363`，新版"设置当前余额"流程：UI 为输入余额计算调整交易并把哨兵已就位的账户保存，按 [财务](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)。）
- **备注：** 在新版余额调整流程保存账户前使用它；它也是 [`migrateForcedBalances`](#migrateforcedbalances) 逐账户循环的终点步骤。

### `ForcedBalanceMigrationResult migrateForcedBalances({required List<Account> accounts, required List<Transaction> transactions, required ExchangeRateData rateData, String adjustmentNote = 'Balance Adjustment'})` <a id="migrateforcedbalances"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/balance_util.dart`（第 197 行）
- **用途：** 一次性迁移，把每个账户的旧非哨兵强制余额转换为确定性调整交易，然后用强制余额哨兵盖章账户，使它绝不被重新迁移。
- **输入：** `accounts`、`transactions`、`rateData`；`adjustmentNote` — 生成调整交易上的备注文本（默认 `'Balance Adjustment'`）。
- **返回：** `ForcedBalanceMigrationResult` — 没有账户需要迁移时（`changed: false`）`accounts`/`transactions` 内容不变，否则是迁移后的列表。
- **副作用：** 无（返回新列表的纯函数；调用方决定是否/如何持久化它们）。
- **算法：**
  1. 对每个账户：既未设 `forcedBalance` 也未设 `forcedBalanceDate`，或 [`hasForcedBalanceSentinel`](#hasforcedbalancesentinel) 已为 `true` 时跳过（原样保留）。
  2. 否则，`forcedBalance != 0` 时经 [`_forcedBalanceMigrationDelta`](#forcedbalancemigrationdelta) 计算调整增量，非平凡（`> 0.000001`）且同确定性 id 的交易不存在时，追加一笔新的收入/支出 `Transaction`（符号取增量的符号），日期经 [`_forcedBalanceAdjustmentDate`](#forcedbalanceadjustmentdate)、id 来自 [`_forcedBalanceMigrationTransactionId`](#forcedbalancemigrationtransactionid)。
  3. 用 [`accountWithForcedBalanceSentinel`](#accountwithforcedbalancesentinel) 替换账户（把 `modifiedAt` 盖章为现在）并标记 `changed = true`。
- **用法：**
  ```dart
  final migration = migrateForcedBalances(
    accounts: data.accounts,
    transactions: data.transactions,
    rateData: rateData,
  );
  ```
  （`lib/shared/services/webdav_service.dart:428-431`，`_migrateFinanceForcedBalances` 内，同步期间对每个合并财务负载运行；相同调用形态从 [`FinanceStorage`](finance_storage.md#migrateforcedbalances) 的私有 `_migrateForcedBalances` 包装器在每次本地加载时运行。）
- **备注：** 确定性交易 id（来自 [`_forcedBalanceMigrationTransactionId`](#forcedbalancemigrationtransactionid)）意味着对已迁移数据重新运行此迁移——如同步合并重新引入同一账户状态后——绝不创建重复调整交易。

### `double _forcedBalanceMigrationDelta(Account account, List<Transaction> transactions, ExchangeRateData rateData)` <a id="forcedbalancemigrationdelta"></a>
- **种类：** 顶层函数（本文件私有）
- **来源：** `lib/features/finance/services/balance_util.dart`（第 262 行）
- **用途：** 计算所需的调整金额，使在把它作为 dated 在强制余额截止的交易添加后，账户的交易派生余额匹配旧强制余额值。
- **输入：** `account`；`transactions`；`rateData`。
- **返回：** `double` — 带符号增量（正 = 收入调整，负 = 支出调整）。
- **副作用：** 无。
- **算法：** 以 `delta = account.forcedBalance ?? 0.0` 开始；`forcedBalanceDate` 为 `null` 时原样返回；否则对每笔 dated 在截止或之前（[`_accountTransactionDelta`](#accounttransactiondelta)）的交易减去其贡献——即 `delta` 最终是"在截止前已记录的交易之上仍需要多少才能达到旧强制余额"。
- **用法：** 在 [`migrateForcedBalances`](#migrateforcedbalances) 内调用一次：`_forcedBalanceMigrationDelta(account, transactions, rateData)`。
- **备注：** 仅本文件内部使用的辅助。

### `String _forcedBalanceMigrationTransactionId(Account account)` <a id="forcedbalancemigrationtransactionid"></a>
- **种类：** 顶层函数（本文件私有）
- **来源：** `lib/features/finance/services/balance_util.dart`（第 284 行）
- **用途：** 为一个账户的迁移调整交易构建确定性交易 id，使重新运行迁移绝不创建重复。
- **输入：** `account`。
- **返回：** `String` — `'forced-balance-migration:<id>:<forcedBalance>:<forcedBalanceDate or "none">:<modifiedAt>'`。
- **副作用：** 无。
- **算法：** 对账户的 id、其旧 `forcedBalance`/`forcedBalanceDate`（缺席时 `'none'`）和 `modifiedAt` 做字符串插值，适用处为 ISO 字符串。
- **用法：** 在 [`migrateForcedBalances`](#migrateforcedbalances) 内调用一次：`final txId = _forcedBalanceMigrationTransactionId(account);`，然后追加前对照 `existingTransactionIds` 检查。
- **备注：** 在 id 中包含 `modifiedAt` 意味着同一账户跨不同同步状态（每个带不同 `modifiedAt`）被迁移多次时，每次产生不同的迁移交易，而不是对过期的那笔静默去重——去重保证只对*完全相同*账户状态的重复迁移成立。

### `DateTime _forcedBalanceAdjustmentDate(Account account)` <a id="forcedbalanceadjustmentdate"></a>
- **种类：** 顶层函数（本文件私有）
- **来源：** `lib/features/finance/services/balance_util.dart`（第 295 行）
- **用途：** 选择记录迁移调整交易的日期，账户原始强制余额截止有意义时优先用它。
- **输入：** `account`。
- **返回：** `DateTime`。
- **副作用：** 无。
- **算法：**
  1. `forcedBalanceDate` 已设置且本身不是哨兵时直接用它。
  2. 否则 `account.modifiedAt` 晚于哨兵日期时用 `modifiedAt`。
  3. 否则回退 `DateTime.now()`。
- **用法：** 在 [`migrateForcedBalances`](#migrateforcedbalances) 内调用一次，作为生成的调整 `Transaction` 的 `date:`。
- **备注：** 回退链确保即使账户的旧强制余额元数据本身退化（缺失或已是哨兵），迁移账户也总能得到合理的调整日期。

### `double _accountTransactionDelta(Account account, Transaction tx, ExchangeRateData rateData)` <a id="accounttransactiondelta"></a>
- **种类：** 顶层函数（本文件私有）
- **来源：** `lib/features/finance/services/balance_util.dart`（第 311 行）
- **用途：** 以账户自己的币种计算一笔交易对一个账户余额的带符号贡献——[`accountBalance`](#accountbalance) 和 [`accountBalanceBefore`](#accountbalancebefore) 都折叠的基本单元。
- **输入：** `account`；`tx`；`rateData` — 经 `ratesAt(tx.rateSnapshotId)` 提供历史汇率。
- **返回：** `double` — 对同账户转账，可能来自下面两个分支任一个或两者，非零。
- **副作用：** 无。
- **算法：**
  1. `tx.accountId == account.id` 时（本账户是交易的主账户）：经 [`convertCurrency`](#convertcurrency) 把 `tx.amount` 从 `tx.currency` 转换为 `account.currency`；支出减、收入加、转账减（钱离开源账户）。
  2. `tx.toAccountId == account.id` 且 `tx.type == transfer` 时（本账户是转账的目标）：加转换后的金额——`toAmount`/`toCurrency` 都设置时用它们（显式跨币种转账金额），否则把 `tx.amount`/`tx.currency` 作为同金额转账转换。
  3. 返回适用分支的和（一笔交易只在退化情形 `accountId == toAccountId` 下经两个分支影响同一账户，实践中预期不会发生）。
- **用法：** 从 [`accountBalance`](#accountbalance) 和 [`accountBalanceBefore`](#accountbalancebefore) 作为折叠体调用，并在 [`_forcedBalanceMigrationDelta`](#forcedbalancemigrationdelta) 内再调用一次。
- **备注：** 仅本文件内部使用的辅助；这里是定义余额计算的支出/收入/转账符号约定的地方——代码库其他地方不再实现它。

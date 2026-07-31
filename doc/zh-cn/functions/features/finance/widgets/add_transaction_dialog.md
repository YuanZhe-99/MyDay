# lib/features/finance/widgets/add_transaction_dialog.dart

财务 [`Transaction`](../../../../features/finance.md#model) 记录的增/改对话框——财务功能中最大的组件文件，组合两块大致独立真实逻辑：(1) **账户选择器**，按调用方的 `AccountPickerSettings`（见 [财务](../../../../features/finance.md)——"交易账户选择器排序/分组/'更多'设置"）排序/分组渲染账户，带可折叠"更多"小节，和 (2) 一个私有**计算器键盘**（`_CalcKeyboard`/`_ExprParser`），在金额录入时替代系统键盘打开，把输入的算术表达式（`+ - × ÷`）解析为正 `double`。与其他增/改对话框一样，它用 `_signature()` 基脏检查把表单包在 `UnsavedChangesGuard`（`lib/shared/widgets/unsaved_changes_guard.dart`）中。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `AddTransactionDialog`（构造函数） | 构造函数（`AddTransactionDialog`） | B | 创建增/改交易对话框实例。 |
| `createState` | 方法（`AddTransactionDialog`） | B | 创建可变 `_AddTransactionDialogState`。 |
| `_isEditing` | getter（`_AddTransactionDialogState`） | B | 返回此对话框是否编辑既有交易。 |
| `_isCrossCurrency` | getter（`_AddTransactionDialogState`） | B | 返回所选转账账户是否使用不同币种。 |
| `_currencyItems` | getter（`_AddTransactionDialogState`） | B | 构建币种下拉项，确保当前币种总是被包含。 |
| `initState` | 方法（`_AddTransactionDialogState`） | B | 从被编辑交易或调用方提供的初始选择预填控制器/字段，然后捕获初始表单签名。 |
| `dispose` | 方法（`_AddTransactionDialogState`） | B | 释放金额/转入金额/备注文本控制器。 |
| `_openCalcKeyboard` | 方法（`_AddTransactionDialogState`） | B | 打开计算器键盘底部面板并把其结果写入控制器。 |
| [`_setType`](#settype) | 方法（`_AddTransactionDialogState`） | A | 更改交易流类型并防止不匹配的分类选择残留。 |
| `build` | 方法（`_AddTransactionDialogState`） | B | 渲染类型选择器、金额/币种、账户选择器、跨币种金额、备注、分类、日期/时间和操作。 |
| `_buildAccountLabel` | 方法（组件辅助，`_AddTransactionDialogState`） | B | 渲染一个账户的标签及其 emoji/图像和银行/应用名。 |
| `_sortedAccountsForPicker` | getter（`_AddTransactionDialogState`） | B | 按当前 `AccountPickerSettings` 排序返回账户。 |
| `_isMoreAccount` | 方法（`_AddTransactionDialogState`） | B | 返回账户是否配置在"更多"小节下。 |
| [`_firstSelectableAccount`](#firstselectableaccount) | 方法（`_AddTransactionDialogState`） | A | 为新交易挑选默认账户。 |
| [`_accountTypeLabel`](#accounttypelabel) | 方法（`_AddTransactionDialogState`） | A | 返回账户类型的本地化标签。 |
| [`_accountDropdownItems`](#accountdropdownitems) | 方法（`_AddTransactionDialogState`） | A | 构建账户下拉项，带可选类型页头和可折叠"更多"小节。 |
| `addHeader` | 本地函数（嵌套于 `_accountDropdownItems`） | B | 向下拉项列表添加禁用的小节页头项。 |
| [`addAccounts`](#addaccounts) | 本地函数（嵌套于 `_accountDropdownItems`） | A | 向下拉项列表添加一组可选账户，请求时插入类型页头。 |
| [`_selectAccount`](#selectaccount) | 方法（`_AddTransactionDialogState`） | A | 应用账户下拉选择，包括"更多"哨兵和跨币种含义。 |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | 方法（`_AddTransactionDialogState`） | A | 报告表单是否与其初始状态不同。 |
| [`_signature`](#signature) | 方法（`_AddTransactionDialogState`） | A | 构建每个可编辑字段的可比较字符串快照。 |
| [`_submit`](#submit) | 方法（`_AddTransactionDialogState`） | A | 校验表单、解决跨币种金额，并构造/弹出 `Transaction`。 |
| `_filteredCategories` | getter（`_AddTransactionDialogState`） | B | 返回匹配当前所选交易类型的分类。 |
| `_buildCategoryPicker` | 方法（组件辅助，`_AddTransactionDialogState`） | B | 为当前交易类型渲染分类下拉框。 |
| `_buildAccountPicker` | 方法（组件辅助，`_AddTransactionDialogState`） | B | 渲染转出账户（转账时也转入账户）下拉选择器。 |
| `_CalcKeyboard`（构造函数） | 构造函数（`_CalcKeyboard`） | B | 创建计算器键盘实例。 |
| `createState` | 方法（`_CalcKeyboard`） | B | 创建可变 `_CalcKeyboardState`。 |
| `initState` | 方法（`_CalcKeyboardState`） | B | 从 `widget.initial` 播种表达式缓冲区。 |
| `_append` | 方法（`_CalcKeyboardState`） | B | 向表达式缓冲区追加一个字符。 |
| `_backspace` | 方法（`_CalcKeyboardState`） | B | 从表达式缓冲区移除最后一个字符。 |
| `_clear` | 方法（`_CalcKeyboardState`） | B | 清除表达式缓冲区。 |
| [`_confirm`](#confirm) | 方法（`_CalcKeyboardState`） | A | 求值表达式缓冲区并带正结果弹出（如有）。 |
| `build` | 方法（`_CalcKeyboardState`） | B | 渲染显示、实时求值预览、数字/运算符网格和清除/确认行。 |
| [`_evalExpr`](#evalexpr) | 顶层函数 | A | 规范化运算符符号并把表达式字符串解析为 `double`，失败为 `null`。 |
| `_ExprParser`（构造函数） | 构造函数（`_ExprParser`） | B | 创建对源字符串的表达式解析器。 |
| [`parse`](#parse) | 方法（`_ExprParser`） | A | 把完整源字符串解析为一个算术表达式。 |
| [`_parseAddSub`](#parseaddsub) | 方法（`_ExprParser`） | A | 解析左结合 `+`/`-` 项链。 |
| [`_parseMulDiv`](#parsemuldiv) | 方法（`_ExprParser`） | A | 解析左结合 `*`/`/` 因子链，拒绝除零。 |
| [`_parseNumber`](#parsenumber) | 方法（`_ExprParser`） | A | 扫描并解析一个数字字面量（带可选前置一元负号）。 |

`grep -c 'Purpose:' lib/features/finance/widgets/add_transaction_dialog.dart` 报告 39，与本文件全部三十九个真实声明匹配（包括 `_accountDropdownItems` 内嵌套的两个本地函数 `addHeader`/`addAccounts`，每个都带自己的 `Purpose:` 块）。未发现错附或未文档化声明。

## 文档

### `void _setType(TransactionType type)` <a id="settype"></a>
- **种类：** `_AddTransactionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 224-229 行）
- **用途：** 在支出/收入/转账间切换对话框并丢弃现在无效的分类选择。
- **输入：** `type` — 新选的 `TransactionType`。
- **返回：** 无。
- **副作用：** 经 `setState` 更新 `_type` 并有条件地 `_selectedCategory`。
- **算法：**
  1. 把 `_type` 设为新值。
  2. 当前所选分类的 `type` 不再等于新 `_type` 时，把 `_selectedCategory` 清为 `null`——分类按类型限定范围（支出分类不能赋给收入交易），因此前一个类型的过期选择不得在切换后静默存活。
- **用法：**
  ```dart
  SegmentedButton<TransactionType>(
    segments: [...],
    selected: {_type},
    onSelectionChanged: (set) => _setType(set.first),
  ),
  ```
  （`build`，同一文件/类。）
- **备注：** `_buildCategoryPicker` 还额外用 `ValueKey(_type)` 键控其 `DropdownButtonFormField`，使字段在类型变化时全新重建，而不只依赖这次清除。

### `Account? _firstSelectableAccount()` <a id="firstselectableaccount"></a>
- **种类：** `_AddTransactionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 476-480 行）
- **用途：** 调用方未提供 `initialAccountId` 时，选择全新交易应默认的账户。
- **输入：** 无（读取 `_sortedAccountsForPicker` 和 `widget.accountPickerSettings`）。
- **返回：** `Account?` — 只在 `widget.accounts` 为空时为 `null`。
- **副作用：** 无。
- **算法：**
  1. 经 [`_sortedAccountsForPicker`](../../../../features/finance.md) 排序账户。
  2. 取**不在**"更多"小节中的第一个账户（`!_isMoreAccount(account)`）。
  3. 每个账户都在"更多"下（第 2 步一无所获）时，回退整体第一个排序账户。
- **用法：**
  ```dart
  _selectedAccount ??= widget.initialAccountId != null
      ? widget.accounts.where((a) => a.id == widget.initialAccountId).firstOrNull
      : null;
  _selectedAccount ??= _firstSelectableAccount();
  ```
  （`initState`，同一文件/类。）
- **备注：** 这镜像 `_accountDropdownItems` 的"更多"折叠行为——藏在"显示更多"后面的账户在选择器首次渲染时也不应静默成为默认选择。

### `String _accountTypeLabel(AccountType type, AppLocalizations l10n)` <a id="accounttypelabel"></a>
- **种类：** `_AddTransactionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 487-494 行）
- **用途：** 把 `AccountType` 映射为其本地化小节页头标签，供分组账户下拉框。
- **输入：** `type` — 要标注的 `AccountType`；`l10n` — 当前 `AppLocalizations`。
- **返回：** `String` — `financeAccountTypeFund` / `financeAccountTypeCredit` / `financeAccountTypeRecharge` / `financeAccountTypeFinancial` 之一。
- **副作用：** 无。
- **算法：** 对四个 `AccountType` 值的穷尽 `switch`，每个 1:1 映射到匹配的 `AppLocalizations` getter。
- **用法：**
  ```dart
  addHeader(
    '__finance_account_header_${sectionKey}_${account.type.name}',
    _accountTypeLabel(account.type, l10n),
  );
  ```
  （`addAccounts`，嵌套于 [`_accountDropdownItems`](#accountdropdownitems)。）
- **备注：** 无。

### `List<DropdownMenuItem<String>> _accountDropdownItems(ThemeData theme, AppLocalizations l10n)` <a id="accountdropdownitems"></a>
- **种类：** `_AddTransactionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 501-582 行）
- **用途：** 构建账户选择器下拉框的项列表，尊重调用方 `AccountPickerSettings` 的类型分组和可折叠"更多"小节。
- **输入：** `theme`、`l10n` — 用于页头样式和本地化类型/"更多"标签。
- **返回：** `List<DropdownMenuItem<String>>` — 可选账户项与禁用页头项交错；存在"更多"账户且尚未展开时有合成的"显示 N 个更多"项。
- **副作用：** 对状态无直接（纯列表构造）；结果项只由调用方的 `onChanged` 接到状态变更。
- **算法：**
  1. 基于 `widget.accountPickerSettings.moreAccountIds` 把 `_sortedAccountsForPicker` 分为 `primary` 和 `more` 列表。
  2. 总是经嵌套 [`addAccounts`](#addaccounts) 辅助渲染 `primary`。
  3. 存在任何 `more` 账户时：`_showMoreAccounts` 已为 `true`（用户先前展开过）时，渲染 `"More"` 页头后跟 `addAccounts(more, 'more')`；否则追加单个合成项（`value: _moreAccountsValue`）读作"显示 N 个更多"而不是各账户。
  4. 返回组合 `items` 列表。
- **用法：**
  ```dart
  DropdownButtonFormField<String>(
    key: ValueKey('from-account-more-$_showMoreAccounts'),
    initialValue: _selectedAccount?.id,
    isExpanded: true,
    items: _accountDropdownItems(theme, l10n),
    onChanged: (id) => _selectAccount(id, isTarget: false),
  ),
  ```
  （`_buildAccountPicker`，同一文件/类——调用两次，一次转出账户，`_type == TransactionType.transfer` 时一次转入账户。）
- **备注：** 页头项用合成非账户 `value`s（`'__finance_account_header_...'`）和 `enabled: false`，因此它们绝不可能被选中；它们纯粹存在以满足 `DropdownButtonFormField` 的单个平铺 `items` 列表。

### `void addAccounts(List<Account> accounts, String sectionKey)`（嵌套于 `_accountDropdownItems`） <a id="addaccounts"></a>
- **种类：** 在 `_accountDropdownItems` 内声明的本地函数
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 545-562 行）
- **用途：** 把一组账户（主组或"更多"组）追加进外层 `items` 列表，调用方设置请求类型分组时在账户 `type` 每次变化处插入类型小节页头。
- **输入：** `accounts` — 要追加的组（已排序）；`sectionKey` — `'primary'` 或 `'more'`，只用于命名空间页头项值，使同一 `AccountType` 的主和"更多"页头不碰撞。
- **返回：** 无。
- **副作用：** 修改外层 `items` 列表（`_accountDropdownItems` 的闭包变量）。
- **算法：**
  1. 循环中跟踪 `currentType`，从 `null` 开始。
  2. 对每个账户，`settings.groupByType` 为 true 且账户 `type` 与 `currentType` 不同时，更新 `currentType` 并以 `sectionKey` 和 `type.name` 命名空间的键、经 [`_accountTypeLabel`](#accounttypelabel) 标注调用 `addHeader`。
  3. 无论是否刚加了页头，都追加账户的普通可选 `DropdownMenuItem`（经 `_buildAccountLabel` 标注）。
- **用法：**
  ```dart
  addAccounts(primary, 'primary');
  if (more.isNotEmpty) {
    if (_showMoreAccounts) {
      addHeader('__finance_account_header_more', l10n.financeAccountPickerMore);
      addAccounts(more, 'more');
    } else {
      // ...synthetic "Show more" item...
    }
  }
  ```
  （`_accountDropdownItems`，同一文件/类。）
- **备注：** 因为 `accounts` 预期已排序且类型连续分组（经 `sortAccountsForPicker`，`lib/features/finance/services/account_picker_util.dart`），此函数只需在单趟中检测类型*变化*——它自己不按类型分组或重排。

### `void _selectAccount(String? id, {required bool isTarget})` <a id="selectaccount"></a>
- **种类：** `_AddTransactionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 589-606 行）
- **用途：** 应用用户从账户下拉框的选择——真实账户，或展开隐藏小节而非选择任何东西的"更多"哨兵。
- **输入：** `id` — 下拉框的所选值（账户 id、`_moreAccountsValue` 或无变更的 `null`）；`isTarget` — 转账*转入*账户下拉框为 `true`，*转出*账户下拉框为 `false`。
- **返回：** 无。
- **副作用：** 经 `setState` 更新 `_showMoreAccounts`、`_selectedAccount`/`_selectedToAccount` 和（转出账户的）`_currency`。
- **算法：**
  1. `id` 为 `null` 时立即返回（未选择任何东西）。
  2. `id` 等于 `_moreAccountsValue` 哨兵时，设 `_showMoreAccounts = true` 并返回——这在*下一次*重建时展开"更多"小节，而不是选择账户。
  3. 否则按 id 查找匹配 `Account`；找不到（过期 id）时返回。
  4. `isTarget` 时设 `_selectedToAccount`；否则设 `_selectedAccount` **并**把 `_currency` 更新为那个账户的币种（转出账户驱动交易币种）。
  5. 新选账户本身是"更多"账户（先前展开后可达）时，也设 `_showMoreAccounts = true`，使它不会在重建时消失回"显示更多"后面。
- **用法：**
  ```dart
  items: _accountDropdownItems(theme, l10n),
  onChanged: (id) => _selectAccount(id, isTarget: false),
  ```
  （`_buildAccountPicker`，同一文件/类；转账转入账户下拉框以 `isTarget: true` 调用。）
- **备注：** 选择转出账户总是覆盖 `_currency`，即使编辑既有交易时——没有守卫在用户重新选同一账户或带不同币种的不同账户时保留交易原始币种。

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **种类：** `_AddTransactionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 613 行）
- **用途：** 告诉 `UnsavedChangesGuard` 表单是否已偏离其初始状态。
- **输入：** 无。
- **返回：** `bool` — 当前签名与 `_initialSignature` 不同时为 `true`。
- **副作用：** 无。
- **算法：** 完全委托给把 [`_signature()`](#signature) 与 `initState` 末尾捕获的 `_initialSignature` 比较。
- **用法：**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **备注：** 无。

### `String _signature()` <a id="signature"></a>
- **种类：** `_AddTransactionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 620-630 行）
- **用途：** 产生一个当且仅当任何可编辑字段值变化时变化的单字符串。
- **输入：** 无。
- **返回：** `String` — 来自 `formSignature`（`lib/shared/widgets/unsaved_changes_guard.dart`）。
- **副作用：** 无。
- **算法：** 把修剪后的金额/转入金额/备注文本、`_type.name`、`_date`、`_currency` 和所选分类/账户/转入账户 id 收集进一个有序列表并经 `formSignature` 连接。
- **用法：**
  ```dart
  _initialSignature = _signature();
  ```
  （`initState`，同一文件/类。）
- **备注：** `_showMoreAccounts` 刻意**不**属于签名——展开"更多"小节是选择器显示关切，不是对交易本身的编辑，因此它不把表单标记为脏。

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **种类：** `_AddTransactionDialogState` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 637-669 行）
- **用途：** 校验表单，有效时构造 `Transaction`（含跨币种转账字段）并带它弹出对话框。
- **输入：** `guard` — 用于带结果弹出路由。
- **返回：** 无。
- **副作用：** 金额有效时经 `guard.pop(tx)` 弹出对话框路由；否则保持对话框打开。
- **算法：**
  1. 解析金额；不是有效正数时返回不弹出——唯一硬校验规则。
  2. 解析 `accountId`，当前未选中时回退被编辑交易的既有 `accountId`（防御：正常 `_selectedAccount` 总是由 `initState`/`_selectAccount` 设置）。
  3. 解析 `toAccountId`——只在 `_type == TransactionType.transfer` 时填充。
  4. [`_isCrossCurrency`](../../../../features/finance.md) 为 true 时，把转入金额控制器解析为 `toAmount` 并从 `_selectedToAccount!.currency` 读取 `toCurrency`；否则两者保持 `null`。
  5. 以 `id: widget.transaction?.id`（使编辑保留原始 id；添加获得新 id）、`rateSnapshotId: widget.currentSnapshotId` 和上面解析的字段构造 `Transaction`。
  6. 调用 `guard.pop(tx)`。
- **用法：**
  ```dart
  final tx = await showDialog<Transaction>(
    context: context,
    builder: (_) => AddTransactionDialog(
      categories: widget.categories,
      accounts: widget.accounts,
      initialAccountId: widget.account.id,
      currentSnapshotId: widget.rateData.currentSnapshotId,
      accountPickerSettings: widget.accountPickerSettings,
    ),
  );
  if (tx != null) {
    setState(() => _transactions.insert(0, tx));
    widget.onAdd(tx);
  }
  ```
  （`lib/features/finance/views/accounts_page.dart`，`_handleAdd`；`category_detail_page.dart`、`subscription_detail_page.dart` 和 `finance_page.dart` 也打开同一对话框编辑。）
- **备注：** 持久化返回的 `Transaction`（及任何下游余额/汇率影响）完全是调用方的责任——此方法只产生 `Transaction` 值并弹出。

### `void _confirm()` <a id="confirm"></a>
- **种类：** `_CalcKeyboardState` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 829-839 行）
- **用途：** 求值当前表达式缓冲区，产生有效正金额时以格式化字符串弹出计算器键盘面板。
- **输入：** 无（读取 `_expr`）。
- **返回：** 无。
- **副作用：** 找到正值时带 `String` 结果弹出外层路由（`Navigator.pop(context, ...)`）；否则什么都不做，面板保持打开。
- **算法：**
  1. 尝试经 [`_evalExpr`](#evalexpr) 把 `_expr` 作为算术表达式求值。
  2. 成功且 `> 0` 时，带 `result.toStringAsFixed(2)` 弹出。
  3. 否则，回退普通 `double.tryParse(_expr)`（覆盖用户输入裸数字但因某种原因未作为"表达式"解析的常见情形——实践中 `_evalExpr` 也处理裸数字，因此这是防御性第二次尝试）；`> 0` 时带 `direct.toStringAsFixed(2)` 弹出。
  4. 两者都不产生正值（空、零、负或格式错误表达式）时静默什么都不做——面板保持打开、无反馈。
- **用法：**
  ```dart
  FilledButton(
    onPressed: _confirm,
    child: const Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
  ),
  ```
  （`build`，同一文件/类——键盘的"="按钮。）
- **备注：** 无效或非正表达式没有用户可见错误消息；唯一反馈是按"="什么都不做。零和负结果与解析失败同样对待（都静默拒绝），因为交易金额必须严格为正。

### `double? _evalExpr(String expr)` <a id="evalexpr"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 1013-1021 行）
- **用途：** 把计算器键盘的 `×`/`÷` 符号规范化为 `*`/`/` 并把结果解析为 `double`，任何空或格式错误输入返回 `null` 而不是抛出。
- **输入：** `expr` — 经计算器键盘输入的原始表达式缓冲区（数字、`.`、`+`、`-`、`×`、`÷`）。
- **返回：** `double?` — 求值后的值，`expr` 为空或解析失败时为 `null`。
- **副作用：** 无。
- **算法：**
  1. 修剪 `expr` 并把每个 `×` 替换为 `*`、`÷` 替换为 `/`。
  2. 结果为空时立即返回 `null`。
  3. 否则在其上构造 [`_ExprParser`](#parse) 并调用 `.parse()`，返回其结果。
  4. 捕获解析期间抛出的任何异常（意外字符、除零等）并返回 `null`。
- **用法：**
  ```dart
  final preview = _evalExpr(_expr);
  final showPreview = preview != null && _expr.isNotEmpty && double.tryParse(_expr) == null;
  ```
  （`_CalcKeyboardState.build`，同一文件——只在缓冲区是真正的表达式、不是已作为主文本显示的裸数字时显示实时 `"= 12.34"` 预览。）
- **备注：** [`_confirm`](#confirm) 也作为其 `double.tryParse` 回退前的第一次求值尝试调用它。

### `double parse()` <a id="parse"></a>
- **种类：** `_ExprParser` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 1039-1043 行）
- **用途：** 把整个源字符串解析为一个算术表达式，拒绝任何未消费的尾部字符。
- **输入：** 无（操作 `this.src`/`this._pos`）。
- **返回：** `double` — 表达式的值。
- **副作用：** 把 `_pos` 推进到 `src` 末尾（或在此之前抛出）。
- **算法：**
  1. 经 [`_parseAddSub()`](#parseaddsub) 解析加/减链。
  2. 之后 `_pos` 未到达 `src.length`（即语法无法消费的遗留字符——如两个连续运算符，或多余的字符）时，抛 `FormatException('unexpected char')`。
  3. 否则返回解析值。
- **用法：**
  ```dart
  return _ExprParser(expr).parse();
  ```
  （`_evalExpr`，同一文件。）
- **备注：** 这是带标准三级优先级链的小型手写递归下降解析器：`parse` → [`_parseAddSub`](#parseaddsub) → [`_parseMulDiv`](#parsemuldiv) → [`_parseNumber`](#parsenumber)。没有括号支持——计算器键盘的按钮网格（`_CalcKeyboardState.build`）不提供 `(`/`)` 键。

### `double _parseAddSub()` <a id="parseaddsub"></a>
- **种类：** `_ExprParser` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 1050-1058 行）
- **用途：** 解析左结合 `+`/`-` 项链，每项本身是 `*`/`/` 链。
- **输入：** 无。
- **返回：** `double` — 累积值。
- **副作用：** 把 `_pos` 推进过每个消费的记号。
- **算法：**
  1. 经 [`_parseMulDiv()`](#parsemuldiv) 解析一项。
  2. 下一个字符是 `+` 或 `-` 时，消费它，解析下一个 `_parseMulDiv()` 项，并把它折叠进运行总计（相应加或减）。
  3. 不再有 `+`/`-` 时返回累积值。
- **用法：** 只从 [`parse()`](#parse) 作为优先级链顶部调用。
- **备注：** 按构造左结合（每次迭代立即折叠进 `v`，而不是构建右递归树）。

### `double _parseMulDiv()` <a id="parsemuldiv"></a>
- **种类：** `_ExprParser` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 1065-1074 行）
- **用途：** 解析左结合 `*`/`/` 因子链，给乘/除高于加/减的优先级，并拒绝除零。
- **输入：** 无。
- **返回：** `double` — 累积值。
- **副作用：** 把 `_pos` 推进过每个消费的记号。
- **算法：**
  1. 经 [`_parseNumber()`](#parsenumber) 解析一个数字。
  2. 下一个字符是 `*` 或 `/` 时，消费它并解析下一个数字。
  3. `/` 时，右侧操作数恰好为 `0` 则抛 `FormatException('div by zero')`，而不是产生 `double.infinity`/`NaN`。
  4. 否则把操作（乘或除）折叠进运行值。
- **用法：** 只从 [`_parseAddSub()`](#parseaddsub) 调用。
- **备注：** 零检查是对解析 `double` 的精确 `== 0` 比较，因此除以只在显示精度下舍入为零（但字面不是 `0`）的值**不**在这里被捕获，会产生非常大（但有限）的结果而不是抛出。

### `double _parseNumber()` <a id="parsenumber"></a>
- **种类：** `_ExprParser` 的方法
- **来源：** `lib/features/finance/widgets/add_transaction_dialog.dart`（第 1081-1095 行）
- **用途：** 扫描一个数字字面量（数字和最多一个小数点，带只在整个表达式最开头可用的可选前置一元负号）并解析为 `double`。
- **输入：** 无。
- **返回：** `double` — 解析的字面量。
- **副作用：** 把 `_pos` 推进过消费的数字。
- **算法：**
  1. 记录 `start = _pos`。
  2. 当前字符是 `-` **且** `start == 0`（即这是整个源字符串的第一个字符）时，把它作为一元负号消费。
  3. 消费字符直到它们是 ASCII 数字（`'0'`–`'9'`）或 `.`，不校验至多一个 `.` 出现。
  4. 没有消费任何字符（`_pos == start`）时抛 `FormatException('expected number')`。
  5. 返回 `double.parse(src.substring(start, _pos))`。
- **用法：** 从 [`_parseMulDiv()`](#parsemuldiv)（每个操作数）调用，并间接支撑整个解析链。
- **备注：** `start == 0` 条件检查解析器在*整个*源字符串中的绝对位置，不是当前子表达式的开始——因此一元负号只在作为键入的第一个字符被识别（如 `"-5+3"`），绝不在运算符后（如 `"5+-3"` 或 `"5*-3"` 抛 `FormatException('expected number')`，而不是被解释为 `5 + (-3)`）。按键盘 `-` 键作为第一个输入是可能的且确实解析（如 `"-5"` 求值为 `-5.0`），但 [`_confirm`](#confirm) 只接受严格为正的结果，因此前置负号表达式总是被静默丢弃，而不是产生负交易金额。

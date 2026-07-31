# lib/features/finance/views/accounts_page.dart

`AccountsPage` 是财务模块的账户列表：按 [`AccountType`](../../../../features/finance.md#model) 小节分组的账户，每个小节独立可排序（名称 / 银行 / 手动拖拽重排的自定义顺序）、带可选月费豁免标准和旧强制余额覆盖的增/改账户对话框、带直接添加交易支持的逐账户交易子页，以及编辑*交易账户选择器*自己的排序/分组/自定义顺序/更多账户设置（`AddTransactionDialog` 账户下拉框使用的 `AccountPickerSettings`）的"更多设置"子页。本页在财务视图中的位置见 [财务](../../../../features/finance.md#views-and-analysis-page)，这里实现的余额到调整交易行为见 [财务 — 强制余额迁移](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)，本文件构建于其上的共享辅助见 [`balance_util.dart`](../services/balance_util.md) / [`account_picker_util.dart`](../services/account_picker_util.md)。

本文件实际包含**两个独立、形态相似、容易混淆的排序/自定义顺序系统**：(1) `_AccountsPageState` 自己的逐类型排序模式（`name`/`bank`/`custom`，存储在按 `AccountType.name` 键控的 `_sortModes`/`_customOrders` 映射中），控制账户在*本页*上如何分组排序；和 (2) 由 `_AccountPickerSettingsPage` 编辑的 `AccountPickerSettings` 模型（`sortMode`/`groupByType`/`customOrder`/`moreAccountIds`），控制别处 `AddTransactionDialog` 显示的*账户选择器下拉框*中的排序。两者恰好为两个模式复用字符串值 `'name'`/`'custom'`，但它们是无关字段、无关持久化，只有账户选择器那个有 `groupByType` 开关和 `moreAccountIds`"更多账户"列表；只有本页自己的排序有第三个 `'bank'` 模式。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `_formatAccountConditionAmount` | 顶层函数 | B | 用账户的币种符号格式化账户免手续费条件金额。 |
| [`_accountFeeWaiverSummary`](#accountfeewaiversummary) | 顶层函数 | A | 为账户构建本地化免手续费摘要行（如有任何豁免标准）。 |
| `AccountsPage({...})` | 构造函数（`AccountsPage`） | B | 带初始账户/交易/排序/选择器状态和变更回调创建账户页。 |
| `AccountsPage.createState` | 方法（`AccountsPage`） | B | 创建 `_AccountsPageState`。 |
| `_AccountsPageState.initState` | 方法（`_AccountsPageState`） | B | 把传入的账户/交易/排序映射/选择器设置复制进本地可变状态。 |
| `_notifyAccounts` | 方法（`_AccountsPageState`） | B | 把当前账户列表推给 `widget.onChanged`。 |
| `_notifyTransactions` | 方法（`_AccountsPageState`） | B | 把当前交易列表推给 `widget.onTransactionsChanged`。 |
| `_notifySort` | 方法（`_AccountsPageState`） | B | 把排序模式/自定义顺序推给 `widget.onSortChanged`。 |
| `_notifyAccountPickerSettings` | 方法（`_AccountsPageState`） | B | 把当前账户选择器设置推给 `widget.onAccountPickerSettingsChanged`。 |
| `_typeKey` | 方法（`_AccountsPageState`） | B | 返回用于按账户类型索引排序/顺序映射的映射键（`type.name`）。 |
| `_sortMode`（`_AccountsPageState`） | 方法（`_AccountsPageState`） | B | 返回账户类型的活动排序模式，默认自定义。 |
| `_compareText` | 方法（`_AccountsPageState`） | B | 不区分大小写字符串比较器，`a.toLowerCase().compareTo(b.toLowerCase())`。 |
| [`_normalizedOrder`](#normalizedorder) | 方法（`_AccountsPageState`） | A | 为一个账户类型构建去重自定义顺序，先保留有效保存的 id。 |
| [`_sortEntries`](#sortentries) | 方法（`_AccountsPageState`） | A | 按名称、银行或自定义顺序排序一个账户类型的条目。 |
| [`_setSortMode`](#setsortmode) | 方法（`_AccountsPageState`） | A | 切换账户类型的排序模式，首次进入自定义模式时播种自定义顺序。 |
| [`_appendAccountToCustomOrderIfNeeded`](#appendaccounttocustomorderifneeded) | 方法（`_AccountsPageState`） | A | 自定义排序激活时把新账户追加进其类型的自定义顺序。 |
| [`_removeAccountFromCustomOrders`](#removeaccountfromcustomorders) | 方法（`_AccountsPageState`） | A | 从每个类型的自定义顺序列表中移除一个账户 id。 |
| `_normalizeAccountPickerSettings` | 方法（`_AccountsPageState`） | B | 对照当前账户列表重新校验 `_accountPickerSettings`。 |
| `_normalizeAndNotifyAccountPickerSettings` | 方法（`_AccountsPageState`） | B | 规范化选择器设置，然后通知父级。 |
| [`_reorderAccounts`](#reorderaccounts) | 方法（`_AccountsPageState`） | A | 拖拽重排后在其类型的自定义顺序内移动一个账户。 |
| [`_addAccount`](#addaccount) | 方法（`_AccountsPageState`） | A | 显示新增账户对话框，确认后插入账户和任何产生的余额调整交易。 |
| [`_editAccount`](#editaccount) | 方法（`_AccountsPageState`） | A | 显示预填当前计算余额的编辑账户对话框，然后应用编辑和任何产生的调整交易。 |
| [`_balanceAdjustmentTransaction`](#balanceadjustmenttransaction) | 方法（`_AccountsPageState`） | A | 构建把账户余额移动到手动输入目标所需的收入/支出交易。 |
| [`_deleteAccount`](#deleteaccount) | 方法（`_AccountsPageState`） | A | 移除账户、清理其自定义顺序条目并重新规范化选择器设置。 |
| `_deleteTransaction`（`_AccountsPageState`） | 方法（`_AccountsPageState`） | B | 按 id 移除交易并通知父级。 |
| [`_openAccountPickerSettings`](#openaccountpickersettings) | 方法（`_AccountsPageState`） | A | 压入账户选择器设置页并应用/规范化返回的结果。 |
| `_AccountsPageState.build` | 方法（`_AccountsPageState`） | B | 构建分组、逐类型排序的账户列表脚手架。 |
| `_buildSectionHeader` | 方法（`_AccountsPageState`，组件辅助） | B | 渲染一个账户类型的页头行（标签、计数、重排开关、排序菜单）。 |
| `_sortMenuItem` | 方法（`_AccountsPageState`，组件辅助） | B | 为排序菜单构建一个弹出菜单行。 |
| [`_buildReorderList`](#buildreorderlist) | 方法（`_AccountsPageState`，组件辅助） | A | 为一个账户类型渲染拖拽重排列表并在放下时持久化新顺序。 |
| `_accountTypeLabel`（`_AccountsPageState`） | 方法（`_AccountsPageState`） | B | 返回账户类型的本地化标签。 |
| `_accountTypeIcon` | 方法（`_AccountsPageState`） | B | 返回账户类型的图标。 |
| `_accountTypeColor` | 方法（`_AccountsPageState`） | B | 返回账户类型的强调色。 |
| [`_buildAccountSubtitle`](#buildaccountsubtitle) | 方法（`_AccountsPageState`，组件辅助） | A | 渲染银行/币种行加免手续费摘要行（如有）。 |
| [`_buildAccountAvatar`](#buildaccountavatar) | 方法（`_AccountsPageState`，组件辅助） | A | 经图像/emoji/类型图标回退链渲染账户头像。 |
| `_AccountPickerSettingsPage({...})` | 构造函数（`_AccountPickerSettingsPage`） | B | 创建账户选择器设置页实例。 |
| `_AccountPickerSettingsPage.createState` | 方法（`_AccountPickerSettingsPage`） | B | 创建 `_AccountPickerSettingsPageState`。 |
| `_AccountPickerSettingsPageState.initState` | 方法（`_AccountPickerSettingsPageState`） | B | 把规范化初始设置复制进本地可编辑状态。 |
| [`_orderedAccounts`](#orderedaccounts) | getter（`_AccountPickerSettingsPageState`） | A | 按自定义顺序编辑器当前顺序返回账户，丢弃无匹配账户的 id。 |
| `_displayAccounts` | getter（`_AccountPickerSettingsPageState`） | B | 按进行中的设置排序/分组返回账户，供更多账户复选框列表。 |
| `_accountTypeLabel`（`_AccountPickerSettingsPageState`） | 方法（`_AccountPickerSettingsPageState`） | B | 返回账户类型的本地化标签。 |
| `_save` | 方法（`_AccountPickerSettingsPageState`） | B | 带规范化、编辑后的选择器设置弹出路由。 |
| [`_reorderCustomOrder`](#reordercustomorder) | 方法（`_AccountPickerSettingsPageState`） | A | 拖拽重排后在自定义顺序编辑器内移动一个账户。 |
| `_AccountPickerSettingsPageState.build` | 方法（`_AccountPickerSettingsPageState`） | B | 构建排序/分组/自定义顺序/更多账户设置编辑器。 |
| `_AccountTransactionsPage({...})` | 构造函数（`_AccountTransactionsPage`） | B | 创建账户交易页实例。 |
| `_AccountTransactionsPage.createState` | 方法（`_AccountTransactionsPage`） | B | 创建 `_AccountTransactionsPageState`。 |
| `_AccountTransactionsPageState.initState` | 方法（`_AccountTransactionsPageState`） | B | 把传入交易复制进本地可变状态。 |
| `_handleAdd` | 方法（`_AccountTransactionsPageState`） | B | 打开预选聚焦账户的添加交易对话框，然后插入结果。 |
| `_handleDelete` | 方法（`_AccountTransactionsPageState`） | B | 移除交易并通知父页面。 |
| `_handleEdit` | 方法（`_AccountTransactionsPageState`） | B | 打开编辑交易对话框并应用结果。 |
| `_AccountTransactionsPageState.build` | 方法（`_AccountTransactionsPageState`） | B | 构建余额/免手续费摘要卡片加此账户的分组交易列表。 |
| `_AccountDialog({...})` | 构造函数（`_AccountDialog`） | B | 创建账户对话框，可选预填供编辑。 |
| `_AccountDialog.createState` | 方法（`_AccountDialog`） | B | 创建 `_AccountDialogState`。 |
| `_currencies` | getter（`_AccountDialogState`） | B | 返回币种列表，确保账户当前币种被包含。 |
| [`_AccountDialogState.initState`](#initstate) | 方法（`_AccountDialogState`） | A | 从既有账户预填表单，在刚计算当前余额与旧强制余额之间选择。 |
| `dispose` | 方法（`_AccountDialogState`） | B | 释放每个文本控制器。 |
| `_AccountDialogState.build` | 方法（`_AccountDialogState`） | B | 构建增/改账户表单（类型、名称、银行、币种、卡、免手续费字段、图标、强制余额）。 |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | 方法（`_AccountDialogState`） | A | 报告表单是否与其初始状态不同。 |
| [`_signature`](#signature) | 方法（`_AccountDialogState`） | A | 构建每个可编辑字段（含可选免手续费字段）的可比较字符串快照。 |
| `_buildImagePreview` | 方法（`_AccountDialogState`，组件辅助） | B | 渲染所选图像（带移除按钮）加银行预设/获取图标/选择图像操作行。 |
| [`_pickBankPreset`](#pickbankpreset) | 方法（`_AccountDialogState`） | A | 打开银行预设选择器，应用所选银行的名称/币种，并自动获取其 logo。 |
| [`_fetchBankIcon`](#fetchbankicon) | 方法（`_AccountDialogState`） | A | 按顺序尝试所选银行的候选 logo URL，直到一个下载成功。 |
| `_parseOptionalMoney` | 方法（`_AccountDialogState`） | B | 解析可选金额字段，空白/无效文本当作缺席。 |
| [`_submit`](#submit) | 方法（`_AccountDialogState`） | A | 校验必填字段、解析可选余额/免手续费金额，并弹出构建的 `Account`。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/views/accounts_page.dart` 返回 64，与上面 64 行精确匹配。每个块都恰好位于其真实声明（顶层函数、构造函数、`createState`、`initState`/`dispose`、getter 或方法）正上方；未发现错附在普通调用点语句上方。文件的八个类（`AccountsPage`、`_AccountsPageState`、`_AccountPickerSettingsPage`、`_AccountPickerSettingsPageState`、`_AccountTransactionsPage`、`_AccountTransactionsPageState`、`_AccountDialog`、`_AccountDialogState`）和它们的普通组件字段不带 `/// Purpose:` 块，与本代码库记录可调用成员而非类或数据字段的约定一致；对未直接前置 `/// Purpose:` 块的成员声明（正则扫描方法/getter/构造函数签名）的交叉检查，除那八个类外没有发现。几个声明名在文件的四个 `State` 类中重复（`initState`、`build`、`createState`、`_accountTypeLabel`）或跨组件/状态类对重复（`createState`）；上面表格在裸名会歧义处用其所属类限定每个，只有那个 Tier A `initState`（`_AccountDialogState`）获得锚点/页面小节——其他三个 `initState`/`build`/`createState` 行是 Tier B，无链接目标。

## 文档

### `String? _accountFeeWaiverSummary(Account account, AppLocalizations l10n)` <a id="accountfeewaiversummary"></a>
- **种类：** 顶层函数（本文件私有）
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 33-49 行）
- **用途：** 构建账户可选月费豁免标准的本地化、人类可读摘要，供账户名下显示。
- **输入：** `account`；`l10n`。
- **返回：** `String?` — 账户两个豁免字段都未设置时为 `null`。
- **副作用：** 无。
- **算法：**
  1. 以空 `parts` 列表开始。
  2. `account.feeWaiverMinimumBalance` 已设置时，加一行组合 `l10n.financeFeeWaiverMinimumBalance` 与经 `_formatAccountConditionAmount` 格式化的金额（用账户自己的币种符号）。
  3. `account.feeWaiverMonthlyDeposit` 已设置时，加等价的月存入行。
  4. `parts` 为空时返回 `null`——没有可显示的豁免标准。
  5. 否则用 `l10n.financeFeeWaiverSeparator` 连接 `parts`，前缀 `l10n.financeFeeWaiverConditions`。
- **用法：**
  ```dart
  final feeWaiverSummary = _accountFeeWaiverSummary(account, l10n);
  if (feeWaiverSummary == null) {
    return Text('${account.bankOrApp}  •  ${account.currency}');
  }
  ```
  （`lib/features/finance/views/accounts_page.dart:833`，[`_buildAccountSubtitle`](#buildaccountsubtitle) 内；`_AccountTransactionsPageState.build` 第 1287 行也调用，在逐账户交易页的余额卡片上显示相同摘要。）
- **备注：** 按 [财务](../../../../features/finance.md#model)，`feeWaiverMinimumBalance` 和 `feeWaiverMonthlyDeposit` 是**替代**标准（满足任一即免手续费）——此函数只*列出*配置了哪些；它不对照账户实际当前余额或存入历史评估任一条件（本文件没有任何东西做）。

### `List<String> _normalizedOrder(AccountType type)` <a id="normalizedorder"></a>
- **种类：** `_AccountsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 187-203 行）
- **用途：** 为一个账户类型产生去重的 id 排序，从 `_customOrders[key]` 中仍然有效的 id 开始，然后追加该类型任何未覆盖的账户。
- **输入：** `type` — 要重建自定义顺序的 `AccountType`。
- **返回：** `List<String>` — 账户 id，恰好覆盖 `type` 的每个当前账户一次。
- **副作用：** 无（读取 `_accounts`/`_customOrders`；不修改它们）。
- **算法：**
  1. 从过滤到 `type` 的 `_accounts` 构建 `allIds`/`allIdSet`。
  2. 遍历保存的顺序 `_customOrders[key] ?? []`，保留既在 `allIdSet` 中又未 `seen` 的 id（去重）。
  3. 按账户列表自己的顺序追加 `allIds` 中尚未 `seen` 的每个 id。
- **用法：**
  ```dart
  _customOrders[key] = _normalizedOrder(type);
  ```
  （`lib/features/finance/views/accounts_page.dart:266`，[`_setSortMode`](#setsortmode) 切换到自定义模式时；相同调用形态在 [`_appendAccountToCustomOrderIfNeeded`](#appendaccounttocustomorderifneeded) 和 [`_sortEntries`](#sortentries) 的自定义模式分支中重现。）
- **备注：** 这是 `account_picker_util.dart` 中 [`normalizedAccountPickerOrder`](../services/account_picker_util.md#normalizedaccountpickerorder) 的逐类型对应物——相同的去重-再-追加形态，但限定一个 `AccountType` 并从本页自己的 `_customOrders` 映射读取，而不是 `AccountPickerSettings.customOrder`。

### `List<MapEntry<int, Account>> _sortEntries(AccountType type, List<MapEntry<int, Account>> entries)` <a id="sortentries"></a>
- **种类：** `_AccountsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 210-244 行）
- **用途：** 按该类型当前排序模式排序一个账户类型的 `(originalIndex, Account)` 条目。
- **输入：** `type`；`entries` — 该类型的索引/账户对，按原始列表顺序。
- **返回：** `List<MapEntry<int, Account>>` — 新的排序列表。
- **副作用：** 无。
- **算法：** 按 `_sortMode(type)` 切换：
  1. `name`：按 `_compareText(a.value.name, b.value.name)` 排序，`bankOrApp` 打破平局。
  2. `bank`：按 `_compareText(a.value.bankOrApp, b.value.bankOrApp)` 排序，`name` 打破平局。
  3. `custom`（和默认/回退）：经 [`_normalizedOrder`](#normalizedorder) 构建 `order`，按每个条目在 `order` 中的位置排序（`order` 中缺失的 id 经 `order.length` 作为回退索引排在所有已知之后），条目的原始索引（`a.key`）打破平局。
- **用法：**
  ```dart
  final sortedGrouped = {
    for (final entry in grouped.entries)
      entry.key: _sortEntries(entry.key, entry.value),
  };
  ```
  （`lib/features/finance/views/accounts_page.dart:517-520`，`build` 中，渲染前分组+排序每个账户类型。）
- **备注：** 镜像 [`sortAccountsForPicker`](../services/account_picker_util.md#sortaccountsforpicker) 的比较器形态，但本页版本有交易账户选择器不支持的第三个 `bank` 模式，并操作 `(index, Account)` 对而不是裸 `Account`，使原始列表位置作为最终打破平局存活。

### `void _setSortMode(AccountType type, String mode)` <a id="setsortmode"></a>
- **种类：** `_AccountsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 251-272 行）
- **用途：** 切换一个账户类型的排序模式，首次进入自定义模式时播种合理的自定义顺序，使账户不会乱跳。
- **输入：** `type`；`mode` — `_sortName`/`_sortBank`/`_sortCustom` 之一。
- **返回：** 无。
- **副作用：** 在 `setState` 内更新 `_sortModes`/`_customOrders`/`_reordering`；调用 `_notifySort`。
- **算法：**
  1. 切换到*自定义*模式且该类型尚无保存的自定义顺序时，播种一个：收集该类型的 `(index, Account)` 条目并在*离开的*模式下经 [`_sortEntries`](#sortentries) 排序，然后把它们的 id 存为新自定义顺序——因此首次自定义顺序视图从屏幕已有的任何顺序开始。
  2. 把 `mode` 存储进 `_sortModes[key]`。
  3. 新模式是自定义时经 [`_normalizedOrder`](#normalizedorder) 刷新 `_customOrders[key]`；否则清除该类型的 `_reordering` 标志（活动时离开重排模式）。
  4. 通知排序已变。
- **用法：**
  ```dart
  PopupMenuButton<String>(
    ...
    onSelected: (mode) => _setSortMode(type, mode),
    ...
  )
  ```
  （`lib/features/finance/views/accounts_page.dart:693`，接到 `_buildSectionHeader` 的排序菜单。）
- **备注：** 播种步骤只在类型*首次*进入自定义模式时运行（由 `!_customOrders.containsKey(key)` 守卫）——之后切走再切回只复用上次保存的自定义顺序。

### `void _appendAccountToCustomOrderIfNeeded(Account account)` <a id="appendaccounttocustomorderifneeded"></a>
- **种类：** `_AccountsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 279-282 行）
- **用途：** 该类型的新账户被添加时保持类型的自定义顺序同步。
- **输入：** `account` — 新添加（或新改类型）的账户。
- **返回：** 无。
- **副作用：** 可能更新 `_customOrders`。
- **算法：** 除非 `account.type` 的当前排序模式是自定义，否则空操作；是自定义时经 [`_normalizedOrder`](#normalizedorder) 重新计算 `_customOrders[_typeKey(account.type)]`，它把 `account.id` 追加在末尾（它尚不在保存的顺序中）。
- **用法：**
  ```dart
  _accounts.add(account);
  ...
  _appendAccountToCustomOrderIfNeeded(account);
  ```
  （`lib/features/finance/views/accounts_page.dart:369-372`，[`_addAccount`](#addaccount) 内；账户类型变化后 [`_editAccount`](#editaccount) 也调用。）
- **备注：** 类型不在自定义模式时静默什么都不做——账户在名称/银行排序下仍正确显示，无需自定义顺序条目。

### `void _removeAccountFromCustomOrders(String accountId)` <a id="removeaccountfromcustomorders"></a>
- **种类：** `_AccountsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 289-293 行）
- **用途：** 从每个类型的自定义顺序列表移除一个账户 id。
- **输入：** `accountId`。
- **返回：** 无。
- **副作用：** 修改 `_customOrders` 中的每个列表。
- **算法：** 循环 `_customOrders.entries` 并对每个值列表调用 `.remove(accountId)`——对从未包含它的类型列表是无害空操作。
- **用法：**
  ```dart
  setState(() => _accounts.removeAt(index));
  _removeAccountFromCustomOrders(accountId);
  ```
  （`lib/features/finance/views/accounts_page.dart:461-462`，[`_deleteAccount`](#deleteaccount) 内；账户类型变化时 [`_editAccount`](#editaccount) 也调用，在按新类型重新追加前把其 id 从*旧*类型顺序中丢弃。）
- **备注：** 无条件遍历所有类型，而不是查找哪个单一类型列表包含该 id——简单，代价是其他类型上几次浪费的空操作 `remove` 调用。

### `void _reorderAccounts(AccountType type, List<MapEntry<int, Account>> entries, int oldIndex, int newIndex)` <a id="reorderaccounts"></a>
- **种类：** `_AccountsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 322-345 行）
- **用途：** 在一个账户类型的自定义顺序内应用拖拽重排。
- **输入：** `type`；`entries` — 该类型当前显示的条目；`oldIndex`/`newIndex` — 拖拽源/目标。
- **返回：** 无。
- **副作用：** 在 `setState` 内更新 `_customOrders`/`_sortModes`；调用 `_notifySort`。
- **算法：**
  1. `newIndex > oldIndex` 时减一（标准 `ReorderableListView.onReorder` 索引移位约定）。
  2. 校验两个索引都在 `ids.length` 内；不在则静默返回。
  3. 移除 `oldIndex` 处的 id 并在 `newIndex` 重新插入。
  4. 把结果存为该类型的自定义顺序并强制 `_sortModes[key]` 为自定义（重排总是暗示自定义模式）。
  5. 通知排序已变。
- **用法：**
  ```dart
  onReorderItem: (oldIndex, newIndex) {
    final oldStyleNewIndex = newIndex > oldIndex ? newIndex + 1 : newIndex;
    _reorderAccounts(type, entries, oldIndex, oldStyleNewIndex);
  },
  ```
  （`lib/features/finance/views/accounts_page.dart:759-761`，[`_buildReorderList`](#buildreorderlist) 内。）
- **备注：** 期望调用方传*`onReorder`-减一之前*约定的 `newIndex`（见 [`_buildReorderList`](#buildreorderlist) 的备注）——此方法内部执行自己的减一，因此传已减一的索引会双重调整、落偏一个槽位。

### `Future<void> _addAccount()` <a id="addaccount"></a>
- **种类：** `_AccountsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 352-378 行）
- **用途：** 显示新增账户对话框，确认后插入新账户及其输入起始余额所需的任何调整交易。
- **输入：** 无（读取 `context`）。
- **返回：** `Future<void>`。
- **副作用：** 显示 `_AccountDialog`；确认后更新 `_accounts`/`_transactions`、类型的自定义顺序和选择器设置，然后通知每个相关父回调。
- **算法：**
  1. 显示 `_AccountDialog()`（空白）并 await 提交的 `Account?`。
  2. 确认后：经 [`accountWithForcedBalanceSentinel`](../services/balance_util.md#accountwithforcedbalancesentinel) 给账户盖章哨兵（新版账户绝不保留原始强制余额）。
  3. 经 [`_balanceAdjustmentTransaction`](#balanceadjustmenttransaction) 构建调整交易，`targetBalance` = 对话框的原始 `forcedBalance`、`currentBalance` = `0`（全新账户从零开始）。
  4. 在 `setState` 内插入账户（和产生的调整交易在索引 0，如有）。
  5. 需要时把账户追加进其类型的自定义顺序（[`_appendAccountToCustomOrderIfNeeded`](#appendaccounttocustomorderifneeded)）、重新规范化并通知选择器设置、通知交易（只在新加了时）、通知账户、通知排序。
- **用法：**
  ```dart
  floatingActionButton: FloatingActionButton(
    onPressed: _addAccount,
    child: const Icon(Icons.add),
  ),
  ```
  （`lib/features/finance/views/accounts_page.dart:640-643`，账户页的 FAB。）
- **备注：** 这是[财务的强制余额迁移](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)的具体 UI 入口：账户总是以已应用的哨兵保存，用户输入的任何起始余额变成交易，绝不成为存储的原始余额。

### `Future<void> _editAccount(int index)` <a id="editaccount"></a>
- **种类：** `_AccountsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 385-426 行）
- **用途：** 显示预填账户当前计算余额的编辑账户对话框，然后应用编辑字段和用户余额变更所需的任何调整交易。
- **输入：** `index` — 被编辑账户在 `_accounts` 中的位置。
- **返回：** `Future<void>`。
- **副作用：** 显示 `_AccountDialog`；确认后更新 `_accounts`/`_transactions` 和（类型变化时）自定义顺序映射，然后通知账户/排序/交易。
- **算法：**
  1. 经 [`accountBalance`](../services/balance_util.md#accountbalance) 计算账户实时余额，并带 `account: oldAccount, currentBalance: <那个余额>` 显示 `_AccountDialog`。
  2. 确认后：经 `accountWithForcedBalanceSentinel` 盖章哨兵，从*已盖章*账户再次重新计算 `currentBalance`（实践中不变，因为盖章不碰交易），并针对对话框请求的 `forcedBalance` 与该当前余额之间的增量经 [`_balanceAdjustmentTransaction`](#balanceadjustmenttransaction) 构建调整交易。
  3. 在索引 0 插入任何调整交易；在 `index` 替换账户。
  4. 账户 `type` 变化时，从旧类型自定义顺序移除其 id 并追加到新类型的（经 [`_removeAccountFromCustomOrders`](#removeaccountfromcustomorders) + [`_appendAccountToCustomOrderIfNeeded`](#appendaccounttocustomorderifneeded)）。
  5. 通知交易（如有新增）、账户、排序。
- **用法：**
  ```dart
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.startToEnd) {
      _editAccount(entry.key);
      return false;
    }
    return confirmDelete(context, AppLocalizations.of(context)!.financeThisAccount);
  },
  ```
  （`lib/features/finance/views/accounts_page.dart:585-594`，账户列表块的滑动编辑/删除 `Dismissible`。）
- **备注：** 把刚计算的 `currentBalance` 传进 `_AccountDialog` 正是让 [`_AccountDialogState.initState`](#initstate) 区分"用户看到今天的真实余额"与"账户仍携带未迁移旧强制余额"的东西。

### `Transaction? _balanceAdjustmentTransaction({required Account account, required double? targetBalance, required double currentBalance, required DateTime? date, required String note})` <a id="balanceadjustmenttransaction"></a>
- **种类：** `_AccountsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 433-452 行）
- **用途：** 计算把账户余额从 `currentBalance` 移动到手动输入 `targetBalance` 的单笔收入/支出交易——[财务的强制余额迁移](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)背后的核心机制。
- **输入：** `account`；`targetBalance` — 用户输入余额，未输入为 `null`；`currentBalance` — 要调整自的余额；`date` — 生效日期，默认现在；`note`。
- **返回：** `Transaction?` — 无需或未请求调整为 `null`。
- **副作用：** 无。
- **算法：**
  1. `targetBalance` 为 `null` 时返回 `null`（未请求余额覆盖）。
  2. 计算 `delta = targetBalance - currentBalance`。
  3. `delta.abs() <= 0.000001` 时把差异当作浮点噪声并返回 `null`。
  4. 否则返回新 `Transaction`：`type` 为 `delta > 0` 时收入否则支出、`amount: delta.abs()`、`currency: account.currency`、`rateSnapshotId: widget.rateData.currentSnapshotId`、`accountId: account.id`、`note`、`date: date ?? DateTime.now()`。
- **用法：**
  ```dart
  final adjTx = _balanceAdjustmentTransaction(
    account: account,
    targetBalance: submittedAccount.forcedBalance,
    currentBalance: 0,
    date: submittedAccount.forcedBalanceDate,
    note: l10n.financeBalanceAdjustment,
  );
  ```
  （`lib/features/finance/views/accounts_page.dart:361-367`，[`_addAccount`](#addaccount) 内；[`_editAccount`](#editaccount) 用非零 `currentBalance` 再次调用。）
- **备注：** `0.000001` 阈值与 `balance_util.dart` 中 [`migrateForcedBalances`](../services/balance_util.md#migrateforcedbalances) 的一次性迁移对应物使用的容差相同——两者都把亚分增量当作"无实际变化"，而不是发出近零调整交易。

### `void _deleteAccount(int index)` <a id="deleteaccount"></a>
- **种类：** `_AccountsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 459-466 行）
- **用途：** 移除账户并让每个派生的状态片（自定义顺序、交易账户选择器设置）与其移除保持一致。
- **输入：** `index` — 账户在 `_accounts` 中的位置。
- **返回：** 无。
- **副作用：** 在 `setState` 内从 `_accounts` 移除账户；从每个类型的自定义顺序移除其 id；重新规范化并通知选择器设置；通知账户/排序。
- **算法：**
  1. 移除前捕获账户的 id。
  2. 在 `setState` 内从 `_accounts` 移除它。
  3. 从每个类型的自定义顺序移除其 id（[`_removeAccountFromCustomOrders`](#removeaccountfromcustomorders)）。
  4. 重新规范化并通知选择器设置（也把 id 从 `AccountPickerSettings.customOrder`/`moreAccountIds` 丢弃，经 `_normalizeAndNotifyAccountPickerSettings`）。
  5. 通知账户、通知排序。
- **用法：**
  ```dart
  onDismissed: (_) => _deleteAccount(entry.key),
  ```
  （`lib/features/finance/views/accounts_page.dart:595`，账户块的滑动删除 `Dismissible`。）
- **备注：** 删除本身在这里不由确认对话框门控——确认发生在上层，在决定 `onDismissed`（因此此方法）是否运行的 `Dismissible.confirmDismiss` 回调中。

### `Future<void> _openAccountPickerSettings()` <a id="openaccountpickersettings"></a>
- **种类：** `_AccountsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 483-501 行）
- **用途：** 打开交易账户选择器的"更多设置"子页并应用它返回的任何设置。
- **输入：** 无（读取 `context`、`_accounts`、`_accountPickerSettings`）。
- **返回：** `Future<void>`。
- **副作用：** 压入 `_AccountPickerSettingsPage`；非 null 结果时在 `setState` 内更新 `_accountPickerSettings` 并通知父级。
- **算法：**
  1. 压入 `_AccountPickerSettingsPage(accounts: _accounts, initialSettings: _accountPickerSettings)` 并 await 其弹出的 `AccountPickerSettings?` 结果。
  2. `null`（用户未保存退回）时什么都不做。
  3. 否则经 [`normalizedAccountPickerSettings`](../services/account_picker_util.md#normalizedaccountpickersettings) 对照当前 `_accounts` 规范化结果并在 `setState` 内存储。
  4. 经 `_notifyAccountPickerSettings` 通知父级。
- **用法：**
  ```dart
  IconButton(
    icon: const Icon(Icons.tune),
    tooltip: AppLocalizations.of(context)!.financeAccountPickerSettings,
    onPressed: _openAccountPickerSettings,
  ),
  ```
  （`lib/features/finance/views/accounts_page.dart:527-531`，账户页应用栏的设置图标。）
- **备注：** 这里再次规范化（除 `_AccountPickerSettingsPage._save` 弹出前已规范化的）是对 `_accounts` 在设置页压入与返回之间变化的防御——在这个同步流程中不太可能，但便宜保险。

### `Widget _buildReorderList(AccountType type, List<MapEntry<int, Account>> entries)` <a id="buildreorderlist"></a>
- **种类：** `_AccountsPageState` 的方法（组件辅助）
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 749-785 行）
- **用途：** 在该类型的重排开关激活且排序模式为自定义时，渲染一个账户类型显示的拖拽重排列表。
- **输入：** `type`；`entries` — 该类型当前排序的条目。
- **返回：** `Widget` — 一个 `ReorderableListView.builder`。
- **副作用：** 无直接（它接线的 `onReorderItem` 回调调用 [`_reorderAccounts`](#reorderaccounts)，后者有副作用）。
- **算法：**
  1. 构建带 `buildDefaultDragHandles: false`（拖拽手柄逐块显式渲染）和带 `Material` 抬升 `proxyDecorator` 的拖拽项的 `ReorderableListView.builder`。
  2. 其 `onReorderItem` 回调接收 `(oldIndex, newIndex)` 并把 `newIndex` 转换为 `_reorderAccounts` 期望的"旧风格"约定：`newIndex > oldIndex ? newIndex + 1 : newIndex`。
  3. 每个块显示拖拽手柄、账户名、[`_buildAccountSubtitle`](#buildaccountsubtitle) 和经 [`accountBalance`](../services/balance_util.md#accountbalance) 的实时余额。
- **用法：**
  ```dart
  if (_reordering[_typeKey(type)] == true && _sortMode(type) == _sortCustom)
    _buildReorderList(type, sortedGrouped[type]!)
  ```
  （`lib/features/finance/views/accounts_page.dart:559-561`，`build` 中，重排模式开启时替换普通可关闭块列表。）
- **备注：** 第 2 步的索引转换存在是因为 [`_reorderAccounts`](#reorderaccounts) 自己执行标准 `ReorderableListView.onReorder` 减一（`if (newIndex > oldIndex) newIndex--`）——但 `onReorderItem` 的索引*已经*是减一后的形式，因此此回调在调用前重新加一，两次调整抵消为预期最终位置。弄错（如直接用 `onReorderItem` 的原始 `newIndex` 调用 `_reorderAccounts`）会在向下拖拽时把条目放偏一个槽位。

### `Widget _buildAccountSubtitle(Account account, ThemeData theme)` <a id="buildaccountsubtitle"></a>
- **种类：** `_AccountsPageState` 的方法（组件辅助）
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 831-851 行）
- **用途：** 渲染账户列表块的副标题：银行/币种行，加账户有豁免标准时带豁免摘要的第二条更暗行。
- **输入：** `account`；`theme`。
- **返回：** `Widget`。
- **副作用：** 无（纯组件构造）。
- **算法：**
  1. 为 `account` 计算 [`_accountFeeWaiverSummary`](#accountfeewaiversummary)。
  2. `null` 时返回单个 `Text('${account.bankOrApp}  •  ${account.currency}')`。
  3. 否则返回 `Column`，同一行后跟 `bodySmall`/`onSurfaceVariant` 样式的豁免摘要。
- **用法：**
  ```dart
  subtitle: _buildAccountSubtitle(entry.value, theme),
  ```
  （`lib/features/finance/views/accounts_page.dart:599`，账户列表块的 `ListTile.subtitle`；第 775 行 [`_buildReorderList`](#buildreorderlist) 内也使用。）
- **备注：** 刻意把豁免摘要留在块的标题和尾部余额列之外（按其文档注释），使它不与账户名或余额视觉竞争。

### `Widget _buildAccountAvatar(Account account, ThemeData theme)` <a id="buildaccountavatar"></a>
- **种类：** `_AccountsPageState` 的方法（组件辅助）
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 858-885 行）
- **用途：** 经图像 → emoji → 类型图标回退链渲染账户头像。
- **输入：** `account`；`theme`。
- **返回：** `Widget` — 一个 `CircleAvatar`，可能包在 `FutureBuilder` 中。
- **副作用：** 无直接；存在时经 [`ImageService.resolve`](../../../shared/services/image_service.md) 异步解析 `account.imagePath`。
- **算法：**
  1. 经 `_accountTypeColor(account.type)` 解析 `color`。
  2. `account.imagePath != null` 时，在 `ImageService.resolve(account.imagePath!)` 周围包 `FutureBuilder<File>`：文件解析*且*在磁盘上存在时把它显示为 `CircleAvatar` 的 `backgroundImage`；否则落入下方 emoji/图标分支。
  3. 无图像（或图像分支落入）时，`account.emoji` 已设置则作为文本显示，否则 `Icon(_accountTypeIcon(account.type), color: color)`。
- **用法：**
  ```dart
  leading: _buildAccountAvatar(entry.value, theme),
  ```
  （`lib/features/finance/views/accounts_page.dart:597`，账户列表块的 `ListTile.leading`。）
- **备注：** `snap.data!.existsSync()` 检查防护指向自那以后已从应用存储删除的文件的过期 `imagePath`——那种情况头像静默回退 emoji/图标，而不是显示破图或抛出。

### `List<Account> get _orderedAccounts` <a id="orderedaccounts"></a>
- **种类：** `_AccountPickerSettingsPageState` 的 getter
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 942-951 行）
- **用途：** 按自定义顺序编辑器当前顺序返回账户，供"更多设置"页的拖拽重排列表。
- **输入：** 无（读取 `widget.accounts`、`_customOrder`）。
- **返回：** `List<Account>`。
- **副作用：** 无。
- **算法：**
  1. 从 `widget.accounts` 构建 id → `Account` 查找（`byId`）。
  2. 遍历 [`normalizedAccountPickerOrder(widget.accounts, _customOrder)`](../services/account_picker_util.md#normalizedaccountpickerorder) 并为每个 id 收集 `byId[id]`，跳过无实时匹配的 id（`byId[id] == null`）。
- **用法：**
  ```dart
  itemCount: _orderedAccounts.length,
  ...
  itemBuilder: (context, index) {
    final account = _orderedAccounts[index];
    ...
  ```
  （`lib/features/finance/views/accounts_page.dart:1089-1097`，驱动 `build` 中自定义顺序 `ReorderableListView.builder`；[`_reorderCustomOrder`](#reordercustomorder) 也读取。）
- **备注：** `byId[id] != null` 过滤正是让此 getter 对 `normalizedAccountPickerOrder` 万一返回不再有匹配账户的 id 有韧性（正常不应发生，因为那个函数已对照当前 `accounts` 列表过滤，但此 getter 不假设它）。

### `void _reorderCustomOrder(int oldIndex, int newIndex)` <a id="reordercustomorder"></a>
- **种类：** `_AccountPickerSettingsPageState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 1007-1016 行）
- **用途：** 在"更多设置"自定义顺序编辑器内应用拖拽重排。
- **输入：** `oldIndex`/`newIndex` — 拖拽源/目标。
- **返回：** 无。
- **副作用：** 在 `setState` 内更新 `_customOrder`。
- **算法：**
  1. `newIndex > oldIndex` 时减一（`ReorderableListView.onReorder` 约定）。
  2. 读取 `_orderedAccounts` 并对照其长度校验两个索引；越界则静默返回。
  3. 把 `oldIndex` 处的账户 id 移到 `newIndex` 并把结果的 id 列表存为 `_customOrder`。
- **用法：**
  ```dart
  onReorderItem: (oldIndex, newIndex) {
    final oldStyleNewIndex = newIndex > oldIndex ? newIndex + 1 : newIndex;
    _reorderCustomOrder(oldIndex, oldStyleNewIndex);
  },
  ```
  （`lib/features/finance/views/accounts_page.dart:1090-1094`，`build` 的自定义顺序 `ReorderableListView` 中。）
- **备注：** 与 [`_buildReorderList`](#buildreorderlist)/[`_reorderAccounts`](#reorderaccounts) 相同的索引约定双重调整——调用方在调用此方法前给 `newIndex` 重新加一，此方法再内部减一。

### `void initState()` <a id="initstate"></a>
- **种类：** `_AccountDialogState` 的方法（生命周期覆盖）
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 1541-1569 行）
- **用途：** 预填增/改账户表单，在刚计算的实时余额（经 `_editAccount` 编辑时总是提供）与旧、未迁移强制余额（调用方和账户都没有更新的可显示时）之间选择。
- **输入：** 无（读取 `widget.account`、`widget.currentBalance`）。
- **返回：** 无。
- **副作用：** 编辑时从 `widget.account` 填充每个 `TextEditingController` 和 `_type`/`_currency`/`_selectedEmoji`/`_imagePath`/`_forcedBalanceDate`；捕获 `_initialSignature`。
- **算法：**
  1. `widget.account`（`a`）非 null（编辑）时：填充名称/银行/卡控制器；只在对应字段非 null 时填充两个免手续费控制器（`toStringAsFixed(2)` 格式化）；复制 `type`/`currency`/`emoji`/`imagePath`。
  2. 余额字段，按优先级：
     - `widget.currentBalance != null` 时（从 [`_editAccount`](#editaccount) 打开时总是 true）：显示那个计算余额并设 `_forcedBalanceDate = DateTime.now()`——字段开始表示"今天的真实余额、未变"，而不是过期覆盖。
     - 否则 `a.forcedBalance != null && !`[`hasForcedBalanceSentinel(a)`](../services/balance_util.md#hasforcedbalancesentinel)（旧、未迁移强制余额）时：显示那个原始值和 `a.forcedBalanceDate ?? DateTime.now()`。
     - 否则让余额字段空白（新账户，或已盖章哨兵、无内容可显示的账户）。
  3. 捕获 `_initialSignature = _signature()` 供未保存变更检测。
- **用法：** `_AccountDialogState` 被插入树时由 Flutter 框架自动调用——本文件其他代码不直接调用。
- **备注：** 这是文件中在 UI 层区分"新版余额"（普通计算数字、无存储覆盖）与"旧强制余额"（带自己日期的未迁移原始值）的唯一地方；两者为何能跨应用版本共存见 [财务 — 强制余额迁移](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)。

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **种类：** `_AccountDialogState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 1858 行）
- **用途：** 报告账户表单是否与打开时的状态不同。
- **输入：** 无。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** `_signature() != _initialSignature`。
- **用法：**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
  （`lib/features/finance/views/accounts_page.dart:1598-1600`，把对话框接入 [`UnsavedChangesGuard`](../../../shared/widgets/unsaved_changes_guard.md)。）
- **备注：** 无。

### `String _signature()` <a id="signature"></a>
- **种类：** `_AccountDialogState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 1865-1877 行）
- **用途：** 构建账户表单可编辑的每个字段的可比较字符串快照，使 [`_hasUnsavedChanges`](#hasunsavedchanges) 能检测任何变更，包括可选免手续费字段的。
- **输入：** 无（读取每个控制器/字段）。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** 在有序列表上委托给共享 [`formSignature`](../../../shared/widgets/unsaved_changes_guard.md#formsignature)：修剪后的名称/银行/卡/免手续费最低/免手续费存入/余额文本、`_type.name`、`_currency`、`_selectedEmoji`、`_imagePath`、`_forcedBalanceDate`。
- **用法：**
  ```dart
  _initialSignature = _signature();
  ```
  （`lib/features/finance/views/accounts_page.dart:1568`，[`initState`](#initstate) 中；每次比较从 [`_hasUnsavedChanges`](#hasunsavedchanges) 重新调用。）
- **备注：** 在这里包含免手续费控制器正是让只编辑免手续费金额（其他每个字段不变）正确触发未保存变更守卫的东西。

### `Future<void> _pickBankPreset()` <a id="pickbankpreset"></a>
- **种类：** `_AccountDialogState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 1977-1991 行）
- **用途：** 让用户选择银行/应用预设，应用其名称和默认币种，并启动自动 logo 下载。
- **输入：** 无（读取 `context`）。
- **返回：** `Future<void>`。
- **副作用：** 显示银行预设选择器；更新 `_bankController`、`_selectedBank`、可能 `_currency`；触发 [`_fetchBankIcon`](#fetchbankicon)。
- **算法：**
  1. Await [`showBankPresetPicker(context)`](../widgets/bank_preset_picker.md#showbankpresetpicker)。
  2. 结果 `null` 或组件不再 mounted 时返回。
  3. 否则 `setState`：设 `_bankController.text = bank.localTitle`、`_selectedBank = bank`，`bank.defaultCurrency` 非 null 时把 `_currency` 切换到它。
  4. 调用 `_fetchBankIcon()`（不 await）自动下载银行 logo；下载失败时"获取图标"按钮只是保持可见供手动重试。
- **用法：**
  ```dart
  OutlinedButton.icon(
    icon: const Icon(Icons.account_balance, size: 16),
    label: Text(l10n.financeBankPresets),
    onPressed: _pickBankPreset,
  ),
  ```
  （`lib/features/finance/views/accounts_page.dart:1935-1939`，`_buildImagePreview` 中。）
- **备注：** logo 获取从这里故意即发即忘——下载在途时对话框保持可用（可提交）；`_downloadingLogo` 驱动 `build` 别处的进度指示器。

### `Future<void> _fetchBankIcon()` <a id="fetchbankicon"></a>
- **种类：** `_AccountDialogState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 1998-2017 行）
- **用途：** 下载所选银行的 logo，按优先级顺序尝试其每个候选 URL 直到一个成功。
- **输入：** 无（读取 `_selectedBank`）。
- **返回：** `Future<void>`。
- **副作用：** 设 `_downloadingLogo` true 再 false；成功时设 `_imagePath` 并清除 `_selectedEmoji`。
- **算法：**
  1. 没有 `_selectedBank` 或其 [`logoUrls`](../services/bank_preset_service.md#logourls) 列表为空时退出。
  2. `setState(() => _downloadingLogo = true)`。
  3. 按顺序遍历 `bank.logoUrls`，对每个调用 [`ImageService.downloadAndSave(url)`](../../../shared/services/image_service.md#downloadandsave)，在第一个非 null 路径停止。
  4. 仍 `mounted` 时 `setState`：清除 `_downloadingLogo`，得到 `path` 时设 `_imagePath = path` 和 `_selectedEmoji = null`。
- **用法：**
  ```dart
  if (bank == null || bank.logoUrls.isEmpty) return;
  ...
  for (final url in bank.logoUrls) {
    path = await ImageService.downloadAndSave(url);
    if (path != null) break;
  }
  ```
  （`lib/features/finance/views/accounts_page.dart:2000-2007`；[`_pickBankPreset`](#pickbankpreset) 选择银行后立即调用，`_buildImagePreview` 中手动"获取图标"按钮也调用。）
- **备注：** 这是 [财务 — BankPresetService](../../../../features/finance.md#bankpresetservice) 描述、[`BankPreset.logoUrls`](../services/bank_preset_service.md#logourls) 详细记录的多来源 logo 回退链的具体实现（Clearbit、logo.dev、Brandfetch、icon.horse、Favicone、两个 Google favicon 端点、DuckDuckGo）——每个来源都失败时 `_imagePath` 只是不被设置，手动"获取图标"按钮保持可用。

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **种类：** `_AccountDialogState` 的方法
- **来源：** `lib/features/finance/views/accounts_page.dart`（第 2034-2069 行）
- **用途：** 校验账户表单、解析其可选数字字段、构建结果 `Account`，并带它弹出对话框。
- **输入：** `guard` — `UnsavedChangesGuard` 的 builder 提供的 `UnsavedChangesController`。
- **返回：** 无。
- **副作用：** 带构建的 `Account` 弹出路由（经 `guard.pop`），必填字段空白时什么都不做。
- **算法：**
  1. 要求非空修剪 `name` 和 `bank`；任一空白时无错误消息、无弹出地返回（静默校验失败）。
  2. 把可选强制余额文本解析为 `double?`（`forcedBalance`）。
  3. 经 [`_parseOptionalMoney`](#parseoptionalmoney) 解析两个可选免手续费金额。
  4. 构造新 `Account`（id 来自 `widget.account?.id`，使编辑保持同一 id）带所有表单字段；`cardNumber` 空白时为 `null`；`forcedBalanceDate` 只在 `forcedBalance != null` 时设置（用户从未选日期时回退 `DateTime.now()`）。
  5. `guard.pop(account)`——经未保存变更守卫自己的弹出路径而不是直接调用 `Navigator.pop`，使守卫的脏状态记账保持一致。
- **用法：**
  ```dart
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(isEditing ? l10n.commonSave : l10n.commonAdd),
  ),
  ```
  （`lib/features/finance/views/accounts_page.dart:1840-1843`，对话框的保存/添加按钮。）
- **备注：** 这里的校验最少且静默——空白名称/银行没有内联错误文本，按钮只是什么都不做直到两者都填好。这里设置的 `forcedBalance`/`forcedBalanceDate` 是原始值，之后被 [`_addAccount`](#addaccount)/[`_editAccount`](#editaccount) 经 `accountWithForcedBalanceSentinel` 盖章覆盖——`_submit` 自己绝不应用哨兵。

## 相关页面

- [财务](../../../../features/finance.md) — `Account`/`Transaction`/`AccountPickerSettings` 模型字段、本页对话框实现的强制余额迁移，以及本页在其他财务视图中的位置。
- [`balance_util.dart`](../services/balance_util.md) — `accountBalance`、`currencySymbol`、`hasForcedBalanceSentinel`、`accountWithForcedBalanceSentinel` 和 `migrateForcedBalances`（本文件逐编辑 [`_balanceAdjustmentTransaction`](#balanceadjustmenttransaction) 的一次性批量对应物）。
- [`account_picker_util.dart`](../services/account_picker_util.md) — `normalizedAccountPickerOrder`、`normalizedAccountPickerSettings`、`sortAccountsForPicker`，贯穿 `_AccountPickerSettingsPage`"更多设置"子页使用。
- [`bank_preset_service.dart`](../services/bank_preset_service.md) — `BankPreset.logoUrls`，[`_fetchBankIcon`](#fetchbankicon) 走的回退链。
- [`bank_preset_picker.dart`](../widgets/bank_preset_picker.md) — `showBankPresetPicker`，由 [`_pickBankPreset`](#pickbankpreset) 打开。
- [`add_transaction_dialog.dart`](../widgets/add_transaction_dialog.md) — `_AccountTransactionsPageState._handleAdd`/`_handleEdit` 打开的对话框，经 `initialAccountId` 预选聚焦账户，并消费本文件"更多设置"页编辑的同一 `AccountPickerSettings`。
- [`grouped_transaction_list.dart`](../widgets/grouped_transaction_list.md) — `buildGroupedTransactionList`，由 `_AccountTransactionsPageState.build` 使用。
- [`image_service.dart`](../../../shared/services/image_service.md) — `resolve`、`pickAndSaveImage`、`downloadAndSave`，用于账户头像和银行 logo。
- [`unsaved_changes_guard.dart`](../../../shared/widgets/unsaved_changes_guard.md) — `UnsavedChangesGuard`、`UnsavedChangesController`、`formSignature`，由 `_AccountDialog` 使用。

# lib/features/finance/services/account_picker_util.dart

交易账户选择器排序/分组/自定义顺序行为背后的纯辅助函数。全部四个顶层函数只操作普通 [`Account`](../models/finance.md#account-new)/[`AccountPickerSettings`](../models/finance.md#accountpickersettings-new) 值、无 I/O——这里的账户顺序规范化正是让 `AccountPickerSettings.customOrder`/`moreAccountIds` 在账户被添加或移除时保持一致的东西。账户选择器在财务视图中的位置见 [财务](../../../../features/finance.md#views-and-analysis-page)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`_compareAccountText`](#compareaccounttext) | 顶层函数 | A | 账户名/银行文本的不区分大小写比较器。 |
| [`normalizedAccountPickerOrder`](#normalizedaccountpickerorder) | 顶层函数 | A | 为当前账户列表返回有效的自定义选择器顺序。 |
| [`normalizedAccountPickerSettings`](#normalizedaccountpickersettings) | 顶层函数 | A | 移除过期 id 并校验账户选择器设置。 |
| [`sortAccountsForPicker`](#sortaccountsforpicker) | 顶层函数 | A | 为交易账户选择器显示排序账户。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/services/account_picker_util.dart` 返回 4，与上面 4 行精确匹配——每个块都恰好位于其真实顶层函数声明正上方；未发现错附在调用点语句上方，文件中也不存在未文档化声明（除这四个函数外它没有定义任何东西）。全部四个分类为 Tier A：每个都含真实分支/循环逻辑（`_compareAccountText` 实现本文件每个排序和 `sortAccountsForPicker` 依赖的比较器；其他三个构建或校验带去重逻辑的有序列表），匹配定级规则的服务/真实逻辑桶。

## 文档

### `int _compareAccountText(String a, String b)` <a id="compareaccounttext"></a>
- **种类：** 顶层函数（本文件私有）
- **来源：** `lib/features/finance/services/account_picker_util.dart`（第 8 行）
- **用途：** 不区分大小写地比较两个面向用户的账户文本值（名称或银行/应用）。
- **输入：** `a`、`b`。
- **返回：** `int` — 标准 `compareTo` 排序。
- **副作用：** 无。
- **算法：** `a.toLowerCase().compareTo(b.toLowerCase())`。
- **用法：** 在 [`sortAccountsForPicker`](#sortaccountsforpicker) 内调用两次——一次在 `a.name`/`b.name` 上，一次（作为打破平局）在 `a.bankOrApp`/`b.bankOrApp` 上。
- **备注：** 仅本文件内部使用的辅助。

### `List<String> normalizedAccountPickerOrder(List<Account> accounts, List<String> customOrder)` <a id="normalizedaccountpickerorder"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/account_picker_util.dart`（第 16 行）
- **用途：** 产生当前账户的去重排序，以 `customOrder` 中仍然有效的 id 开头，然后追加任何未覆盖的账户。
- **输入：** `accounts` — 当前活动账户列表；`customOrder` — 先前保存的手动顺序，可能引用已删除账户或缺失新添加的。
- **返回：** `List<String>` — 账户 id，完全覆盖 `accounts` 且每个恰好一次。
- **副作用：** 无。
- **算法：**
  1. 从当前 `accounts` 构建 `allIdSet`。
  2. 遍历 `customOrder`，只保留既在 `allIdSet` 中又未 `seen` 的 id（去重）。
  3. 追加 `accounts` 中尚未 `seen` 的每个账户 id，按账户列表自己的顺序——这正是新添加账户落在自定义顺序末尾而不是被丢弃的方式。
- **用法：** 从 [`sortAccountsForPicker`](#sortaccountsforpicker) 调用以构建 `orderIndex`，从 [`normalizedAccountPickerSettings`](#normalizedaccountpickersettings) 调用以在保存前规范化 `customOrder` 本身。
- **备注：** 缺失的当前账户（`customOrder` 中已不存在的 id）被静默丢弃，而不是保留为悬空条目。

### `AccountPickerSettings normalizedAccountPickerSettings(AccountPickerSettings settings, List<Account> accounts)` <a id="normalizedaccountpickersettings"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/account_picker_util.dart`（第 38 行）
- **用途：** 对照当前账户列表校验并修复设置值——重置无效 `sortMode`、规范化 `customOrder`、丢弃过期/重复的 `moreAccountIds`。
- **输入：** `settings` — 按加载/编辑的状态；`accounts` — 当前活动账户列表。
- **返回：** 新的 `AccountPickerSettings`。
- **副作用：** 无。
- **算法：**
  1. 构建当前账户 id 集合。
  2. `copyWith` 设置：`sortMode` 除非已是两个已知常量之一，否则回退 `sortCustom`；`customOrder` 经 [`normalizedAccountPickerOrder`](#normalizedaccountpickerorder) 重建；`moreAccountIds` 过滤到仍存在的 id 并原地去重。
- **用法：**
  ```dart
  _accountPickerSettings = normalizedAccountPickerSettings(
    widget.accountPickerSettings,
    _accounts,
  );
  ```
  （`lib/features/finance/views/accounts_page.dart:124-127`，在 `initState` 中运行一次；账户变化或设置被编辑时 `_normalizeAccountPickerSettings` 和 `_openAccountPickerSettings` 中出现相同调用形态。）
- **备注：** 在保存账户选择器设置页编辑的设置前使用它——它是保证 `customOrder`/`moreAccountIds` 绝不引用已删除账户的唯一地方。

### `List<Account> sortAccountsForPicker(List<Account> accounts, AccountPickerSettings settings)` <a id="sortaccountsforpicker"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/finance/services/account_picker_util.dart`（第 63 行）
- **用途：** 产生交易账户选择器的显示顺序，尊重类型分组、所选排序模式，并回退原始列表顺序作为最终打破平局。
- **输入：** `accounts`；`settings` — `groupByType` 和 `sortMode`（规范化后的 `sortName` 或 `sortCustom`）驱动比较器。
- **返回：** `List<Account>` — 新的排序列表；`accounts` 本身不被修改。
- **副作用：** 无。
- **算法：**
  1. 把 `accounts` 复制进 `sorted`；构建 `originalIndex`（id -> 原始位置），并经 [`normalizedAccountPickerOrder`](#normalizedaccountpickerorder) 构建 `orderIndex`（id -> 自定义顺序位置）。
  2. 用复合比较器排序：
     - `groupByType` 时，先比较 `a.type.index` vs `b.type.index`；非零结果胜出。
     - `sortMode == sortName` 时，在 `name` 上按 [`_compareAccountText`](#compareaccounttext) 比较，然后 `bankOrApp` 作打破平局。
     - 否则（自定义顺序），按每个账户在 `orderIndex` 中的位置比较（未匹配 id 经 `?? order.length` 排在所有已知之后）。
     - 每个分支的最终打破平局：原始列表位置（`originalIndex`）。
- **用法：**
  ```dart
  List<Account> get _displayAccounts => sortAccountsForPicker(
    widget.accounts,
    AccountPickerSettings(
      sortMode: _sortMode,
      groupByType: _groupByType,
      ...
    ),
  );
  ```
  （`lib/features/finance/views/accounts_page.dart:958-963`，账户选择器的实时显示列表 getter。）
- **备注：** 类型分组只改变主比较键——在每个类型组内，所选 `sortMode` 的排序仍然适用。

# lib/features/finance/models/finance.dart

整个财务功能的数据模型：`AccountPickerSettings`（交易账户选择器排序/分组/"更多"偏好）、`Account`、`Transaction`、`Category`、`Subscription` 和轻量 `IconRef` 图标引用，外加它们使用的 `AccountType`/`TransactionType`/`BillingCycleType`/`CancelType` 枚举。每个模型都遵循相同形态：一个字段赋值构造函数，未提供时生成 `id`（经 `uuid`）和 `modifiedAt`（UTC"现在"），一对用于持久化/同步 `finance_data.json` 格式的 `toJson`/`fromJson`，没有其他行为——唯独 `Subscription` 例外，它还拥有月末钳制计费日期算术（`nextBillingCursor`、`calculateNextBillingDate`、`billingDatesBefore`），由 [`SubscriptionProcessor`](../services/subscription_processor.md) 驱动。这些模型如何融入功能见 [财务](../../../../features/finance.md)，`nextBillingCursor` 实现的完整月末钳制算法见 [订阅计费](../../../../algorithms/subscription-billing.md)。每个模型的精确 JSON 字段列表在 [数据格式](../../../../data-formats.md#finance--finance_datajson)。

## 声明

锚点说明：`toJson` 在本文件的六个不同类上定义（`AccountPickerSettings`、`Account`、`Transaction`、`Category`、`Subscription`、`IconRef`）。为保持本页锚点唯一，那六行使用类限定的锚点（`accountpickersettings-tojson`、`account-tojson` 等），而不是通用规则本会产生的裸名锚点；其他每行使用普通裸名锚点。`fromJson` 工厂构造函数已按 `<类名>-<命名构造函数小写>` 锚点规则各自唯一。

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `AccountType`（枚举） | 枚举 | B | `fund` / `credit` / `recharge` / `financial`——无 Purpose 块（见对账）。 |
| [`AccountPickerSettings()`](#accountpickersettings-new) | 构造函数（`AccountPickerSettings`） | A | 为交易对话框创建账户选择器设置。 |
| [`toJson`](#accountpickersettings-tojson) | 方法（`AccountPickerSettings`） | A | 把选择器设置序列化为 JSON。 |
| [`AccountPickerSettings.fromJson`](#accountpickersettings-fromjson) | 工厂构造函数（`AccountPickerSettings`） | A | 从 JSON 解析选择器设置，无效/缺失值默认化。 |
| [`copyWith`](#copywith) | 方法（`AccountPickerSettings`） | A | 复制选择器设置，字段可选替换。 |
| [`Account()`](#account-new) | 构造函数（`Account`） | A | 创建账户，省略时生成 `id`/`modifiedAt`。 |
| [`toJson`](#account-tojson) | 方法（`Account`） | A | 把账户序列化为 JSON。 |
| [`Account.fromJson`](#account-fromjson) | 工厂构造函数（`Account`） | A | 从 JSON 解析账户。 |
| `TransactionType`（枚举） | 枚举 | B | `expense` / `income` / `transfer`——无 Purpose 块（见对账）。 |
| [`Transaction()`](#transaction-new) | 构造函数（`Transaction`） | A | 创建交易，省略时生成 `id`/`date`/`modifiedAt`。 |
| [`toJson`](#transaction-tojson) | 方法（`Transaction`） | A | 把交易序列化为 JSON。 |
| [`Transaction.fromJson`](#transaction-fromjson) | 工厂构造函数（`Transaction`） | A | 从 JSON 解析交易。 |
| [`Category()`](#category-new) | 构造函数（`Category`） | A | 创建分类，省略时生成 `id`/`modifiedAt`。 |
| [`toJson`](#category-tojson) | 方法（`Category`） | A | 把分类序列化为 JSON。 |
| [`Category.fromJson`](#category-fromjson) | 工厂构造函数（`Category`） | A | 从 JSON 解析分类。 |
| `BillingCycleType`（枚举） | 枚举 | B | `monthly` / `yearly`——无 Purpose 块（见对账）。 |
| `CancelType`（枚举） | 枚举 | B | `immediate` / `atExpiry`——无 Purpose 块（见对账）。 |
| [`Subscription()`](#subscription-new) | 构造函数（`Subscription`） | A | 创建订阅，省略时生成 `id`/`modifiedAt`。 |
| [`firstBillingDate`](#firstbillingdate) | getter（`Subscription`） | A | 返回锚点计费日期（`startDate + trialDays`）。 |
| [`nextBillingCursor`](#nextbillingcursor) | 静态方法（`Subscription`） | A | 带月末钳制把计费游标推进一个周期。 |
| [`calculateNextBillingDate`](#calculatenextbillingdate) | 方法（`Subscription`） | A | 计算严格晚于给定日期的下一个计费日期。 |
| [`billingDatesBefore`](#billingdatesbefore) | 方法（`Subscription`） | A | 生成从锚点到截止的所有计费日期。 |
| [`toJson`](#subscription-tojson) | 方法（`Subscription`） | A | 把订阅序列化为 JSON。 |
| [`Subscription.fromJson`](#subscription-fromjson) | 工厂构造函数（`Subscription`） | A | 从 JSON 解析订阅。 |
| [`IconRef()`](#iconref-new) | const 构造函数（`IconRef`） | A | 创建图标引用（码点 + 字体族）。 |
| [`toJson`](#iconref-tojson) | 方法（`IconRef`） | A | 把图标引用序列化为 JSON。 |
| [`IconRef.fromJson`](#iconref-fromjson) | 工厂构造函数（`IconRef`） | A | 从 JSON 解析图标引用。 |
| [`toIconData`](#toicondata) | 方法（`IconRef`） | A | 从存储的码点/字体重建 Flutter `IconData`。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/models/finance.dart` 返回 24，与上面恰好带 `/// Purpose:` 块的 24 行匹配——24 个每个都恰好位于真实声明（构造函数、工厂构造函数、getter 或静态/实例方法）正上方；未发现错附在调用点语句上方。表格在那 24 行之外还有四行：普通枚举 `AccountType`、`TransactionType`、`BillingCycleType` 和 `CancelType`，它们都不带 `/// Purpose:` 块，与本代码库记录可调用成员而非普通类型/字段声明的约定一致（`shared/services/webdav_service.md` 的 `RemoteFileStatus` 枚举也见同样模式）。对照此列表交叉核对文件中的每个 `class`、`enum`、`factory`、`get` 和 `static` 声明，没有发现未文档化的可调用声明。全部 24 个文档化声明分类为 Tier A：每个要么是模型构造函数/`toJson`/`fromJson`/`copyWith`（定级规则显式的 Tier A 桶），要么是带真实分支/循环逻辑的四个 `Subscription` 计费日期方法之一。

## 文档

### `const AccountPickerSettings({String sortMode = sortCustom, bool groupByType = false, List<String> customOrder = const [], List<String> moreAccountIds = const []})` <a id="accountpickersettings-new"></a>
- **种类：** `AccountPickerSettings` 的 const 构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 20 行）
- **用途：** 保存交易账户选择器的排序模式、类型分组标志、自定义手动顺序和"更多"溢出列表。
- **输入：** `sortMode` 默认 `AccountPickerSettings.sortCustom`；`groupByType` 默认 `false`；`customOrder`/`moreAccountIds` 默认为空列表。
- **返回：** 新的 `AccountPickerSettings`。
- **副作用：** 无。
- **算法：** 平凡 `const` 字段赋值构造函数。
- **用法：**
  ```dart
  this.accountPickerSettings = const AccountPickerSettings(),
  ```
  （`lib/features/finance/widgets/add_transaction_dialog.dart:39`，每个渲染账户选择器的视图使用的默认值——`accounts_page.dart`、`analysis_page.dart`、`category_detail_page.dart`、`subscription_detail_page.dart`、`categories_page.dart`、`subscriptions_page.dart`、`finance_storage.dart` 的 `FinanceData` 都共享这一默认。）
- **备注：** `sortName`/`sortCustom` 是仅有的两个有效 `sortMode` 字符串常量；任何其他值被 [`fromJson`](#accountpickersettings-fromjson) 和 [`account_picker_util.dart`](../services/account_picker_util.md#normalizedaccountpickersettings) 中的 `normalizedAccountPickerSettings` 规范化回 `sortCustom`。

### `Map<String, dynamic> toJson()` <a id="accountpickersettings-tojson"></a>
- **种类：** `AccountPickerSettings` 的方法
- **来源：** `lib/features/finance/models/finance.dart`（第 32 行）
- **用途：** 把选择器设置序列化为嵌入 `finance_data.json` 的 `accountPickerSettings` 键下的 JSON。
- **输入：** 无。
- **返回：** `{sortMode, groupByType, customOrder?, moreAccountIds?}`——两个列表字段为空时完全省略。
- **副作用：** 无。
- **算法：** 带 `if (...isNotEmpty)` 守卫的映射字面量，用于 `customOrder`/`moreAccountIds`。
- **用法：** 从 `FinanceData.toJson()`（`finance_storage.dart:71`）调用：`'accountPickerSettings': accountPickerSettings.toJson()`。
- **备注：** 省略空列表让新建设置值的 JSON 保持精简，但 `fromJson` 把缺失键与显式空列表同样对待。

### `factory AccountPickerSettings.fromJson(Map<String, dynamic>? json)` <a id="accountpickersettings-fromjson"></a>
- **种类：** `AccountPickerSettings` 的工厂构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 44 行）
- **用途：** 从 JSON 解析回选择器设置，任何无效或缺失值默认 `sortCustom`/未设置而不是抛出。
- **输入：** `json` — 可空解码映射（旧数据中缺席的 `accountPickerSettings` 键传 `null`）。
- **返回：** 新的 `AccountPickerSettings`；`json` 为 `null` 时 `const AccountPickerSettings()`。
- **副作用：** 无。
- **算法：**
  1. `json == null` 时立即返回默认设置。
  2. 读取 `sortMode`，缺失或不是两个已知常量之一时回退 `sortCustom`。
  3. 读取 `groupByType`（默认 `false`）、`customOrder`/`moreAccountIds`（默认 `const []`，从 `List<dynamic>` 转换）。
- **用法：**
  ```dart
  accountPickerSettings: AccountPickerSettings.fromJson(
    json['accountPickerSettings'] as Map<String, dynamic>?,
  ),
  ```
  （`lib/features/finance/services/finance_storage.dart:122-124`，`FinanceData.fromJson` 内。）
- **备注：** 对格式错误的输入绝不抛出——每个字段单独退化到其默认值，与本文件其他每个 `fromJson` 使用的相同防御模式。

### `AccountPickerSettings copyWith({String? sortMode, bool? groupByType, List<String>? customOrder, List<String>? moreAccountIds})` <a id="copywith"></a>
- **种类：** `AccountPickerSettings` 的方法
- **来源：** `lib/features/finance/models/finance.dart`（第 65 行）
- **用途：** 返回只替换给定字段的副本。
- **输入：** 全部四个参数可选；未设置的回退 `this` 当前值。
- **返回：** 新的 `AccountPickerSettings`。
- **副作用：** 无。
- **算法：** 对四个字段各用 `field ?? this.field` 构造新 `AccountPickerSettings`。
- **用法：** 从 [`account_picker_util.dart`](../services/account_picker_util.md#normalizedaccountpickersettings) 的 `normalizedAccountPickerSettings` 调用：`settings.copyWith(sortMode: ..., customOrder: ..., moreAccountIds: ...)`。
- **备注：** 无。

### `Account({String? id, required AccountType type, required String bankOrApp, required String name, String currency = 'CNY', String? cardNumber, String? expiryDate, String? securityCode, String? emoji, String? imagePath, double? feeWaiverMinimumBalance, double? feeWaiverMonthlyDeposit, double? forcedBalance, DateTime? forcedBalanceDate, DateTime? modifiedAt})` <a id="account-new"></a>
- **种类：** `Account` 的构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 102 行）
- **用途：** 创建银行/应用账户记录，可选带卡元数据、emoji/图像和 [财务](../../../../features/finance.md#model) 描述的两个替代免手续费标准。
- **输入：** `type`、`bankOrApp`、`name` 必填；`currency` 默认 `'CNY'`；`feeWaiverMinimumBalance`/`feeWaiverMonthlyDeposit` 是独立可选的替代（满足任一即免手续费）；`forcedBalance`/`forcedBalanceDate` 是旧迁移哨兵字段（见 [`accountWithForcedBalanceSentinel`](../services/balance_util.md#accountwithforcedbalancesentinel)）。
- **返回：** 新的 `Account`。
- **副作用：** 无。
- **算法：** 字段赋值构造函数；未提供时 `id` 默认 `const Uuid().v4()`、`modifiedAt` 默认 `DateTime.now().toUtc()`。
- **用法：**
  ```dart
  final account = Account(
    id: widget.account?.id,
    type: _type,
    bankOrApp: bank,
    name: name,
    currency: _currency,
    cardNumber: _cardController.text.trim().isEmpty ? null : _cardController.text.trim(),
    feeWaiverMinimumBalance: feeWaiverMinimumBalance,
    feeWaiverMonthlyDeposit: feeWaiverMonthlyDeposit,
    emoji: _selectedEmoji,
    imagePath: _imagePath,
    forcedBalance: forcedBalance,
    forcedBalanceDate: forcedBalance != null ? ... : null,
    ...
  );
  ```
  （`lib/features/finance/views/accounts_page.dart:2050`，账户增/改对话框的提交处理器——传既有 `widget.account?.id` 在编辑时复用 id，`null` 在创建时生成新的。）
- **备注：** 新版余额纯粹从交易计算（[`accountBalance`](../services/balance_util.md#accountbalance)）；`forcedBalance`/`forcedBalanceDate` 只为旧版兼容存在，按 [财务](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)。

### `Map<String, dynamic> toJson()` <a id="account-tojson"></a>
- **种类：** `Account` 的方法
- **来源：** `lib/features/finance/models/finance.dart`（第 126 行）
- **用途：** 把账户序列化为存储在 `finance_data.json` 的 `accounts` 数组中的 JSON。
- **输入：** 无。
- **返回：** `id`/`type`/`bankOrApp`/`name`/`currency`/`modifiedAt` 总是存在、每个可选字段（`cardNumber`、`expiryDate`、`securityCode`、`emoji`、`imagePath`、两个免手续费字段、`forcedBalance`、`forcedBalanceDate`）只在非 null 时包含的映射。
- **副作用：** 无。
- **算法：** 每个可选字段带 `if (field != null)` 守卫的映射字面量；`forcedBalanceDate` 和 `modifiedAt` 以 `toIso8601String()` 写入。
- **用法：** 从 `FinanceData.toJson()` 调用：`accounts.map((a) => a.toJson()).toList()`（`lib/features/finance/services/finance_storage.dart:54`）。
- **备注：** 无。

### `factory Account.fromJson(Map<String, dynamic> json)` <a id="account-fromjson"></a>
- **种类：** `Account` 的工厂构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 152 行）
- **用途：** 从持久化/同步 JSON 形态解析回账户。
- **输入：** `json` — 解码映射，通常是 `finance_data.json` 的 `accounts` 数组的一个条目。
- **返回：** 新的 `Account`。
- **副作用：** 无。
- **算法：** 转换必填字段（`id`、`bankOrApp`、`name`）；`type` 经 `AccountType.values.byName`；每个可选数字/日期字段用 null 安全转换/`DateTime.parse` 解析；`modifiedAt` 缺失时回退 Unix 纪元（较旧的 pre-`modifiedAt` 记录）。
- **用法：** 从 `FinanceData.fromJson` 调用：`(json['accounts'] as List<dynamic>?)?.map((a) => Account.fromJson(a as Map<String, dynamic>))`（`lib/features/finance/services/finance_storage.dart:80-83`）。
- **备注：** `type` 是不可识别字符串时 `AccountType.values.byName` 抛出——与本文件大多数 `fromJson` 方法不同，这个不会在坏枚举值上防御性回退。

### `Transaction({String? id, required TransactionType type, required double amount, String currency = 'CNY', String? rateSnapshotId, required String accountId, String? toAccountId, double? toAmount, String? toCurrency, String? categoryId, String? subscriptionId, String note = '', DateTime? date, DateTime? modifiedAt})` <a id="transaction-new"></a>
- **种类：** `Transaction` 的构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 201 行）
- **用途：** 创建支出/收入/转账记录，可选携带历史汇率快照 id 和（转账时）目标账户/金额/币种。
- **输入：** `type`、`amount`、`accountId` 必填；`currency` 默认 `'CNY'`；`toAccountId`/`toAmount`/`toCurrency` 是仅转账字段；`categoryId`/`subscriptionId` 链接回分类或生成此交易的订阅。
- **返回：** 新的 `Transaction`。
- **副作用：** 无。
- **算法：** 字段赋值构造函数；`id` 默认新 UUID v4、`date` 默认 `DateTime.now()`（本地时间，不同于 `modifiedAt`）、`modifiedAt` 默认 `DateTime.now().toUtc()`。
- **用法：**
  ```dart
  final tx = Transaction(
    id: widget.transaction?.id,
    type: _type,
    amount: amount,
    currency: _currency,
    rateSnapshotId: widget.currentSnapshotId,
    accountId: accountId,
    toAccountId: toAccountId,
    toAmount: toAmount,
    toCurrency: toCurrency,
    categoryId: _selectedCategory?.id,
    note: _noteController.text.trim(),
    date: _date,
  );
  ```
  （`lib/features/finance/widgets/add_transaction_dialog.dart:654-667`，增/改交易对话框的提交处理器。）
- **备注：** `rateSnapshotId` 正是让 [`balance_util.dart`](../services/balance_util.md) 用记录时生效的汇率而不是今天的汇率转换历史交易的东西——见 `ExchangeRateData.ratesAt`。

### `Map<String, dynamic> toJson()` <a id="transaction-tojson"></a>
- **种类：** `Transaction` 的方法
- **来源：** `lib/features/finance/models/finance.dart`（第 225 行）
- **用途：** 把交易序列化为存储在 `finance_data.json` 的 `transactions` 数组中的 JSON。
- **输入：** 无。
- **返回：** `id`/`type`/`amount`/`currency`/`accountId`/`note`/`date`/`modifiedAt` 总是存在、`rateSnapshotId`/`toAccountId`/`toAmount`/`toCurrency`/`categoryId`/`subscriptionId` 只在非 null 时包含的映射。
- **副作用：** 无。
- **算法：** 带 `if (field != null)` 守卫的映射字面量；`date`/`modifiedAt` 为 `toIso8601String()`。
- **用法：** 从 `FinanceData.toJson()` 调用：`transactions.map((t) => t.toJson()).toList()`（`lib/features/finance/services/finance_storage.dart:56`）。
- **备注：** 无。

### `factory Transaction.fromJson(Map<String, dynamic> json)` <a id="transaction-fromjson"></a>
- **种类：** `Transaction` 的工厂构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 247 行）
- **用途：** 从持久化/同步 JSON 形态解析回交易。
- **输入：** `json` — 解码映射，通常是 `finance_data.json` 的 `transactions` 数组的一个条目。
- **返回：** 新的 `Transaction`。
- **副作用：** 无。
- **算法：** 转换必填字段（`id`、`accountId`、经 `DateTime.parse` 的 `date`）；`type` 经 `TransactionType.values.byName`；每个可选字段用 null 安全转换解析；`modifiedAt` 缺失时回退 Unix 纪元。
- **用法：** 从 `FinanceData.fromJson` 调用：`(json['transactions'] as List<dynamic>?)?.map((t) => Transaction.fromJson(t as Map<String, dynamic>))`（`lib/features/finance/services/finance_storage.dart:90-93`）。
- **备注：** `date` 是必填并无条件解析（`DateTime.parse(json['date'] as String)`），不同于本文件其他每个日期字段——缺失 `date` 的交易抛出而不是默认化。

### `Category({String? id, required String name, required IconRef icon, String? emoji, required TransactionType type, DateTime? modifiedAt})` <a id="category-new"></a>
- **种类：** `Category` 的构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 280 行）
- **用途：** 创建交易分类（支出、收入或转账），带 Material 图标引用和可选 emoji。
- **输入：** `name`、`icon`、`type` 必填；`emoji` 可选。
- **返回：** 新的 `Category`。
- **副作用：** 无。
- **算法：** 字段赋值构造函数；`id`/`modifiedAt` 与 `Account` 相同方式默认。
- **用法：**
  ```dart
  final category = Category(
    id: widget.category?.id,
    name: name,
    icon: IconRef(codePoint: _selectedIcon.codePoint, fontFamily: _selectedIcon.fontFamily ?? 'MaterialIcons'),
    ...
  );
  ```
  （`lib/features/finance/views/categories_page.dart:723-728`，增/改分类对话框的提交处理器。）
- **备注：** `type` 除支出/收入外还支持 `TransactionType.transfer`——按 [财务](../../../../features/finance.md#model)，转账分类是受支持的情形，不只是支出/收入二分。

### `Map<String, dynamic> toJson()` <a id="category-tojson"></a>
- **种类：** `Category` 的方法
- **来源：** `lib/features/finance/models/finance.dart`（第 295 行）
- **用途：** 把分类序列化为存储在 `finance_data.json` 的 `categories` 数组中的 JSON。
- **输入：** 无。
- **返回：** `{id, name, icon: icon.toJson(), emoji?, type, modifiedAt}`。
- **副作用：** 无。
- **算法：** 映射字面量；`icon` 经 `IconRef.toJson()` 嵌套。
- **用法：** 从 `FinanceData.toJson()` 调用：`categories.map((c) => c.toJson()).toList()`（`lib/features/finance/services/finance_storage.dart:55`）。
- **备注：** 无。

### `factory Category.fromJson(Map<String, dynamic> json)` <a id="category-fromjson"></a>
- **种类：** `Category` 的工厂构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 309 行）
- **用途：** 从持久化/同步 JSON 形态解析回分类。
- **输入：** `json` — 解码映射，通常是 `finance_data.json` 的 `categories` 数组的一个条目。
- **返回：** 新的 `Category`。
- **副作用：** 无。
- **算法：** 转换 `id`/`name`；`icon` 经 `IconRef.fromJson`；`type` 经 `TransactionType.values.byName`；`modifiedAt` 缺失时回退 Unix 纪元。
- **用法：** 从 `FinanceData.fromJson` 调用：`(json['categories'] as List<dynamic>?)?.map((c) => Category.fromJson(c as Map<String, dynamic>))`（`lib/features/finance/services/finance_storage.dart:86-89`）。
- **备注：** 无。

### `Subscription({String? id, required String name, String? emoji, String? imagePath, required DateTime startDate, int trialDays = 0, required BillingCycleType billingCycleType, int billingInterval = 1, required double amount, String currency = 'CNY', required String accountId, String? categoryId, String note = '', bool isActive = true, DateTime? cancelledAt, CancelType? cancelType, DateTime? nextBillingDate, DateTime? modifiedAt})` <a id="subscription-new"></a>
- **种类：** `Subscription` 的构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 350 行）
- **用途：** 创建周期订阅：试用期、计费周期/间隔、金额、目标账户/分类、取消状态和持久化的 `nextBillingDate` 游标。
- **输入：** `name`、`startDate`、`billingCycleType`、`amount`、`accountId` 必填；`trialDays` 默认 `0`；`billingInterval` 默认 `1`（"每 X 个月/年"）；`isActive` 默认 `true`。
- **返回：** 新的 `Subscription`。
- **副作用：** 无。
- **算法：** 字段赋值构造函数；`id`/`modifiedAt` 与 `Account` 相同方式默认。与其他模型不同，此构造函数**不**默认 `nextBillingDate`——它保持 `null`，直到 [`SubscriptionProcessor`](../services/subscription_processor.md) 计算并持久化它，这正是该处理器算法处理的"迁移情形"。
- **用法：**
  ```dart
  final sub = Subscription(
    id: _isRestoringCopy ? null : widget.subscription?.id,
    name: name,
    ...
  );
  ```
  （`lib/features/finance/widgets/add_subscription_dialog.dart:541-542`；恢复/复制订阅时传 `id: null` 正是 [财务](../../../../features/finance.md#views-and-analysis-page) 描述的恢复为新订阅行为。）
- **备注：** 除 [订阅计费](../../../../algorithms/subscription-billing.md) 已覆盖的外无其他。

### `DateTime get firstBillingDate` <a id="firstbillingdate"></a>
- **种类：** `Subscription` 的 getter
- **来源：** `lib/features/finance/models/finance.dart`（第 378 行）
- **用途：** 返回锚点计费日期——`startDate + trialDays`——之后每个计费周期的 day-of-month 都对照它测量。
- **输入：** 无。
- **返回：** `DateTime`。
- **副作用：** 无。
- **算法：** `startDate.add(Duration(days: trialDays))`。
- **用法：**
  ```dart
  cursor = Subscription.nextBillingCursor(
    cursor: cursor,
    cycleType: sub.billingCycleType,
    interval: sub.billingInterval,
    anchor: sub.firstBillingDate,
  );
  ```
  （`lib/features/finance/services/subscription_processor.dart:116-121`，处理器追赶循环中每次 `nextBillingCursor` 调用的 `anchor` 参数。）
- **备注：** 分类为 Tier A（尽管是单行 getter），因为这是 [订阅计费](../../../../algorithms/subscription-billing.md) 中整个月末钳制算法围绕构建的锚点值。

### `static DateTime nextBillingCursor({required DateTime cursor, required BillingCycleType cycleType, required int interval, required DateTime anchor})` <a id="nextbillingcursor"></a>
- **种类：** `Subscription` 的静态方法
- **来源：** `lib/features/finance/models/finance.dart`（第 389 行）
- **用途：** 把计费游标精确推进一个周期，把锚点的 day-of-month 钳制到目标月的实际长度，而不是让 `DateTime` 日溢出滚入下个月。
- **输入：** `cursor` — 当前计费日期；`cycleType` — `monthly` 或 `yearly`；`interval` — 周期乘数（每 N 个月/年）；`anchor` — `firstBillingDate`，其 day-of-month 在可能时被保留。
- **返回：** `DateTime` — 下一个计费日期。
- **副作用：** 无。
- **算法：** 完整走查见 [订阅计费](../../../../algorithms/subscription-billing.md#month-end-clamping-subscriptionnextbillingcursor)。简言之：月周期在同一 `year` 内把 `month` 推进 `interval`（让 `DateTime` 把 `month > 12` 规范化为下一年）；年周期把 `year` 推进 `interval` 并把 `month` 固定为锚点的月份。无论哪种方式，`lastDay = DateTime(year, month + 1, 0).day` 计算目标月的实际最后一天（下个月的第 `0` 天），返回的天是 `anchor.day < lastDay ? anchor.day : lastDay`。
- **用法：**
  ```dart
  cursor = nextBillingCursor(
    cursor: cursor,
    cycleType: billingCycleType,
    interval: billingInterval,
    anchor: first,
  );
  ```
  （`lib/features/finance/models/finance.dart:421-426`，本类自己的 [`calculateNextBillingDate`](#calculatenextbillingdate) 内；[`billingDatesBefore`](#billingdatesbefore) 和 [`SubscriptionProcessor.process`](../services/subscription_processor.md#process) 也相同调用——这是应用中每个计费日期推进都经过的唯一函数。）
- **备注：** 1 月 31 日的月锚点计费 2 月 28/29 日、3 月 31 日、4 月 30 日……——具体日期见 [订阅计费演练](../../../../examples/subscription-billing-walkthrough.md)。

### `DateTime? calculateNextBillingDate({DateTime? after})` <a id="calculatenextbillingdate"></a>
- **种类：** `Subscription` 的方法
- **来源：** `lib/features/finance/models/finance.dart`（第 416 行）
- **用途：** 计算严格晚于给定日期（或现在）的第一个计费日期，尊重 `atExpiry` 取消截止。
- **输入：** `after` — 省略时默认 `DateTime.now()`。
- **返回：** `DateTime?` — 订阅被 `atExpiry` 取消且计算出的游标会落在 `cancelledAt` 之后时为 `null`。
- **副作用：** 无。
- **算法：**
  1. 把 `cursor` 从 `firstBillingDate` 开始。
  2. 在 `!cursor.isAfter(after)` 时循环 `cursor = nextBillingCursor(...)`。
  3. `cancelType == atExpiry` 且 `cursor.isAfter(cancelledAt!)` 时返回 `null`。
  4. 否则返回 `cursor`。
- **用法：**
  ```dart
  nbd = sub.calculateNextBillingDate(
    after: today.subtract(const Duration(days: 1)),
  );
  ```
  （`lib/features/finance/services/subscription_processor.dart:70-72`，为早于该字段的订阅首次计算 `nextBillingDate` 的迁移路径；`lib/features/finance/views/subscriptions_page.dart` 的仅显示"下个计费日期"预览也使用。）
- **备注：** 月末锚点经 [`nextBillingCursor`](#nextbillingcursor) 逐周期钳制——见 [订阅计费](../../../../algorithms/subscription-billing.md)。

### `List<DateTime> billingDatesBefore(DateTime until)` <a id="billingdatesbefore"></a>
- **种类：** `Subscription` 的方法
- **来源：** `lib/features/finance/models/finance.dart`（第 442 行）
- **用途：** 生成从订阅锚点起到（含）截止日期的每个计费日期。
- **输入：** `until` — 闭区间截止。
- **返回：** `List<DateTime>`，按时间顺序。
- **副作用：** 无。
- **算法：**
  1. 把 `cursor` 从 `firstBillingDate` 开始。
  2. `!cursor.isAfter(until)` 时：把 `cursor` 追加进 `dates`，然后经 `nextBillingCursor(...)` 推进。
  3. 返回 `dates`。
- **用法：**
  ```dart
  final dates = sub.billingDatesBefore(now);
  ```
  （`lib/features/finance/views/subscriptions_page.dart:545`，用于计数/显示订阅至今已计费多少次。）
- **备注：** 与 `calculateNextBillingDate` 不同，这忽略 `atExpiry` 取消——它列出直到 `until` 的每个周期日期，无论订阅是否真会生成那么远的交易（需要时由调用方负责交叉引用取消）。

### `Map<String, dynamic> toJson()` <a id="subscription-tojson"></a>
- **种类：** `Subscription` 的方法
- **来源：** `lib/features/finance/models/finance.dart`（第 463 行）
- **用途：** 把订阅序列化为存储在 `finance_data.json` 的 `subscriptions` 数组中的 JSON。
- **输入：** 无。
- **返回：** `id`/`name`/`startDate`/`trialDays`/`billingCycleType`/`billingInterval`/`amount`/`currency`/`accountId`/`note`/`isActive`/`modifiedAt` 总是存在、`emoji`/`imagePath`/`categoryId`/`cancelledAt`/`cancelType`/`nextBillingDate` 只在非 null 时包含的映射。
- **副作用：** 无。
- **算法：** 带 `if (field != null)` 守卫的映射字面量；日期字段为 `toIso8601String()`，枚举为 `.name`。
- **用法：** 从 `FinanceData.toJson()` 调用：`subscriptions.map((s) => s.toJson()).toList()`（`lib/features/finance/services/finance_storage.dart:57`）。
- **备注：** 无。

### `factory Subscription.fromJson(Map<String, dynamic> json)` <a id="subscription-fromjson"></a>
- **种类：** `Subscription` 的工厂构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 490 行）
- **用途：** 从持久化/同步 JSON 形态解析回订阅。
- **输入：** `json` — 解码映射，通常是 `finance_data.json` 的 `subscriptions` 数组的一个条目。
- **返回：** 新的 `Subscription`。
- **副作用：** 无。
- **算法：** 转换必填字段；`billingCycleType` 缺失时默认 `'monthly'`（早于该字段的旧数据）；`trialDays` 默认 `0`、`billingInterval` 默认 `1`、`isActive` 默认 `true`；`cancelledAt`/`cancelType`/`nextBillingDate` 全部 null 安全；`modifiedAt` 缺失时回退 Unix 纪元。
- **用法：** 从 `FinanceData.fromJson` 调用：`(json['subscriptions'] as List<dynamic>?)?.map((s) => Subscription.fromJson(s as Map<String, dynamic>))`（`lib/features/finance/services/finance_storage.dart:96-99`）。
- **备注：** 经此工厂加载、没有 `nextBillingDate` 键的订阅正是 `SubscriptionProcessor.process` 在首次遍历时检测并处理的"迁移情形"。

### `const IconRef({required int codePoint, String fontFamily = 'MaterialIcons'})` <a id="iconref-new"></a>
- **种类：** `IconRef` 的 const 构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 532 行）
- **用途：** 保存 Material 图标的数字码点和字体族，使它能被持久化并在不存储完整 `IconData` 的情况下重建。
- **输入：** `codePoint` 必填；`fontFamily` 默认 `'MaterialIcons'`。
- **返回：** 新的 `IconRef`。
- **副作用：** 无。
- **算法：** 平凡 `const` 字段赋值构造函数。
- **用法：**
  ```dart
  icon: IconRef(codePoint: (d['icon'] as IconData).codePoint),
  ```
  （`lib/features/finance/views/categories_page.dart:226`，从 Material `IconData` 常量构建默认分类的图标引用。）
- **备注：** 因为图标数据从这两个字段动态重建而不是编译期常量，发布构建需要 `--no-tree-shake-icons`（按 [财务](../../../../features/finance.md#model)）。

### `Map<String, dynamic> toJson()` <a id="iconref-tojson"></a>
- **种类：** `IconRef` 的方法
- **来源：** `lib/features/finance/models/finance.dart`（第 539 行）
- **用途：** 把图标引用序列化为嵌套在分类 `icon` 键下的 JSON。
- **输入：** 无。
- **返回：** `{codePoint, fontFamily}`。
- **副作用：** 无。
- **算法：** 直接映射字面量。
- **用法：** 从 `Category.toJson()` 调用：`'icon': icon.toJson()`（`lib/features/finance/models/finance.dart:298`）。
- **备注：** 无。

### `factory IconRef.fromJson(Map<String, dynamic> json)` <a id="iconref-fromjson"></a>
- **种类：** `IconRef` 的工厂构造函数
- **来源：** `lib/features/finance/models/finance.dart`（第 549 行）
- **用途：** 从分类的嵌套 `icon` JSON 解析回图标引用。
- **输入：** `json` — 解码映射。
- **返回：** 新的 `IconRef`。
- **副作用：** 无。
- **算法：** 把 `codePoint` 作为必填 `int` 转换；`fontFamily` 缺失时默认 `'MaterialIcons'`。
- **用法：** 从 `Category.fromJson` 调用：`icon: IconRef.fromJson(json['icon'] as Map<String, dynamic>)`（`lib/features/finance/models/finance.dart:312`）。
- **备注：** 无。

### `IconData toIconData()` <a id="toicondata"></a>
- **种类：** `IconRef` 的方法
- **来源：** `lib/features/finance/models/finance.dart`（第 560 行）
- **用途：** 从存储的码点和字体族重建可用的 Flutter `IconData`，用于渲染分类图标。
- **输入：** 无。
- **返回：** `IconData`。
- **副作用：** 无。
- **算法：** `IconData(codePoint, fontFamily: fontFamily)`，带 `// ignore: non_const_argument_for_const_parameter` 注释，因为 `codePoint`/`fontFamily` 是运行时值，不是编译期常量。
- **用法：**
  ```dart
  cat.icon.toIconData(),
  ```
  （`lib/features/finance/views/categories_page.dart:398`，在列表中渲染分类图标；`categories_page.dart:522` 编辑时播种图标选择器也使用。）
- **备注：** 动态持久化图标引用刻意不能是 `const`——这正是发布构建需要 `--no-tree-shake-icons` 的原因（见 [`IconRef()`](#iconref-new)）。

# lib/features/finance/models/finance.dart

The data models for the entire Finance feature: `AccountPickerSettings` (transaction account-picker
sort/group/"More" preferences), `Account`, `Transaction`, `Category`, `Subscription`, and the
lightweight `IconRef` icon reference, plus the `AccountType`/`TransactionType`/`BillingCycleType`/
`CancelType` enums they use. Every model follows the same shape: a field-assigning constructor with
a generated `id` (via `uuid`) and `modifiedAt` (UTC "now") when not supplied, a `toJson`/`fromJson`
pair for the persisted/synced `finance_data.json` format, and no other behavior — except
`Subscription`, which additionally owns the month-end-clamped billing-date arithmetic
(`nextBillingCursor`, `calculateNextBillingDate`, `billingDatesBefore`) that
[`SubscriptionProcessor`](../services/subscription_processor.md) drives. See
[Finance](../../../../features/finance.md) for how these models fit into the feature and
[Subscription Billing](../../../../algorithms/subscription-billing.md) for the full month-end
clamping algorithm that `nextBillingCursor` implements. The exact JSON field list for every model is
in [Data Formats](../../../../data-formats.md#finance--finance_datajson).

## Declarations

Anchor note: `toJson` is defined on six different classes in this file (`AccountPickerSettings`,
`Account`, `Transaction`, `Category`, `Subscription`, `IconRef`). To keep anchors unique on this
page, those six rows use a class-qualified anchor (`accountpickersettings-tojson`,
`account-tojson`, etc.) instead of the bare-name anchor the general rule would otherwise produce;
every other row uses the plain bare-name anchor. The `fromJson` factory constructors are already
unique per the `<classname>-<namedConstructorLowercased>` anchor rule.

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AccountType` (enum) | enum | B | `fund` / `credit` / `recharge` / `financial` — no Purpose block (see Reconciliation). |
| [`AccountPickerSettings()`](#accountpickersettings-new) | constructor (`AccountPickerSettings`) | A | Create account picker settings for transaction dialogs. |
| [`toJson`](#accountpickersettings-tojson) | method (`AccountPickerSettings`) | A | Serialize picker settings to JSON. |
| [`AccountPickerSettings.fromJson`](#accountpickersettings-fromjson) | factory constructor (`AccountPickerSettings`) | A | Parse picker settings from JSON, defaulting invalid/missing values. |
| [`copyWith`](#copywith) | method (`AccountPickerSettings`) | A | Copy picker settings with fields optionally replaced. |
| [`Account()`](#account-new) | constructor (`Account`) | A | Create an account, generating `id`/`modifiedAt` if omitted. |
| [`toJson`](#account-tojson) | method (`Account`) | A | Serialize an account to JSON. |
| [`Account.fromJson`](#account-fromjson) | factory constructor (`Account`) | A | Parse an account from JSON. |
| `TransactionType` (enum) | enum | B | `expense` / `income` / `transfer` — no Purpose block (see Reconciliation). |
| [`Transaction()`](#transaction-new) | constructor (`Transaction`) | A | Create a transaction, generating `id`/`date`/`modifiedAt` if omitted. |
| [`toJson`](#transaction-tojson) | method (`Transaction`) | A | Serialize a transaction to JSON. |
| [`Transaction.fromJson`](#transaction-fromjson) | factory constructor (`Transaction`) | A | Parse a transaction from JSON. |
| [`Category()`](#category-new) | constructor (`Category`) | A | Create a category, generating `id`/`modifiedAt` if omitted. |
| [`toJson`](#category-tojson) | method (`Category`) | A | Serialize a category to JSON. |
| [`Category.fromJson`](#category-fromjson) | factory constructor (`Category`) | A | Parse a category from JSON. |
| `BillingCycleType` (enum) | enum | B | `monthly` / `yearly` — no Purpose block (see Reconciliation). |
| `CancelType` (enum) | enum | B | `immediate` / `atExpiry` — no Purpose block (see Reconciliation). |
| [`Subscription()`](#subscription-new) | constructor (`Subscription`) | A | Create a subscription, generating `id`/`modifiedAt` if omitted. |
| [`firstBillingDate`](#firstbillingdate) | getter (`Subscription`) | A | Return the anchor billing date (`startDate + trialDays`). |
| [`nextBillingCursor`](#nextbillingcursor) | static method (`Subscription`) | A | Advance a billing cursor by one cycle with month-end clamping. |
| [`calculateNextBillingDate`](#calculatenextbillingdate) | method (`Subscription`) | A | Compute the next billing date strictly after a given date. |
| [`billingDatesBefore`](#billingdatesbefore) | method (`Subscription`) | A | Generate all billing dates from the anchor up to a cutoff. |
| [`toJson`](#subscription-tojson) | method (`Subscription`) | A | Serialize a subscription to JSON. |
| [`Subscription.fromJson`](#subscription-fromjson) | factory constructor (`Subscription`) | A | Parse a subscription from JSON. |
| [`IconRef()`](#iconref-new) | const constructor (`IconRef`) | A | Create an icon reference (code point + font family). |
| [`toJson`](#iconref-tojson) | method (`IconRef`) | A | Serialize an icon reference to JSON. |
| [`IconRef.fromJson`](#iconref-fromjson) | factory constructor (`IconRef`) | A | Parse an icon reference from JSON. |
| [`toIconData`](#toicondata) | method (`IconRef`) | A | Reconstruct a Flutter `IconData` from the stored code point/font. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/models/finance.dart` returns 24,
matching the 24 rows above that carry a `/// Purpose:` block exactly — every one of the 24 sits
immediately above a real declaration (constructor, factory constructor, getter, or static/instance
method); none were found misattached above a call-site statement. The table has four additional
rows beyond those 24: the plain enums `AccountType`, `TransactionType`, `BillingCycleType`, and
`CancelType`, none of which carry a `/// Purpose:` block, consistent with this codebase's
convention of documenting callable members rather than plain type/field declarations (the same
pattern seen in `shared/services/webdav_service.md`'s `RemoteFileStatus` enum). Cross-checking
every `class`, `enum`, `factory`, `get`, and `static` declaration in the file against this list
turned up no undocumented callable declaration. All 24 documented declarations are classified Tier
A: every one is either a model constructor/`toJson`/`fromJson`/`copyWith` (the tiering rule's
explicit Tier A bucket) or one of the four `Subscription` billing-date methods that carry real
branching/loop logic.

## Documentation

### `const AccountPickerSettings({String sortMode = sortCustom, bool groupByType = false, List<String> customOrder = const [], List<String> moreAccountIds = const []})` <a id="accountpickersettings-new"></a>
- **Kind:** const constructor of `AccountPickerSettings`
- **Source:** `lib/features/finance/models/finance.dart` (line 20)
- **Purpose:** Hold the transaction account-picker's sort mode, type-grouping flag, custom manual
  order, and "More" overflow list.
- **Inputs:** `sortMode` defaults to `AccountPickerSettings.sortCustom`; `groupByType` defaults to
  `false`; `customOrder`/`moreAccountIds` default to empty lists.
- **Returns:** A new `AccountPickerSettings`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor.
- **Usage:**
  ```dart
  this.accountPickerSettings = const AccountPickerSettings(),
  ```
  (`lib/features/finance/widgets/add_transaction_dialog.dart:39`, the default value used by every
  view that renders the account picker — `accounts_page.dart`, `analysis_page.dart`,
  `category_detail_page.dart`, `subscription_detail_page.dart`, `categories_page.dart`,
  `subscriptions_page.dart`, `finance_storage.dart`'s `FinanceData` all share this same default.)
- **Notes:** `sortName`/`sortCustom` are the only two valid `sortMode` string constants; anything
  else is normalized back to `sortCustom` by [`fromJson`](#accountpickersettings-fromjson) and by
  `normalizedAccountPickerSettings` in
  [`account_picker_util.dart`](../services/account_picker_util.md#normalizedaccountpickersettings).

### `Map<String, dynamic> toJson()` <a id="accountpickersettings-tojson"></a>
- **Kind:** method of `AccountPickerSettings`
- **Source:** `lib/features/finance/models/finance.dart` (line 32)
- **Purpose:** Serialize picker settings into the JSON embedded under `finance_data.json`'s
  `accountPickerSettings` key.
- **Inputs:** None.
- **Returns:** `{sortMode, groupByType, customOrder?, moreAccountIds?}` — the two list fields are
  omitted entirely when empty.
- **Side effects:** None.
- **Algorithm:** Map literal with `if (...isNotEmpty)` guards on `customOrder`/`moreAccountIds`.
- **Usage:** Called from `FinanceData.toJson()` (`finance_storage.dart:71`):
  `'accountPickerSettings': accountPickerSettings.toJson()`.
- **Notes:** Omitting empty lists keeps a freshly-created settings value's JSON minimal, but
  `fromJson` treats a missing key identically to an explicit empty list either way.

### `factory AccountPickerSettings.fromJson(Map<String, dynamic>? json)` <a id="accountpickersettings-fromjson"></a>
- **Kind:** factory constructor of `AccountPickerSettings`
- **Source:** `lib/features/finance/models/finance.dart` (line 44)
- **Purpose:** Parse picker settings back out of JSON, defaulting to `sortCustom`/unset for any
  invalid or missing value rather than throwing.
- **Inputs:** `json` — nullable decoded map (an absent `accountPickerSettings` key in older data
  passes `null` through).
- **Returns:** A new `AccountPickerSettings`; `const AccountPickerSettings()` if `json` is `null`.
- **Side effects:** None.
- **Algorithm:**
  1. If `json == null`, return the default settings immediately.
  2. Read `sortMode`, falling back to `sortCustom` if missing or not one of the two known constants.
  3. Read `groupByType` (default `false`), `customOrder`/`moreAccountIds` (default `const []`,
     cast from `List<dynamic>`).
- **Usage:**
  ```dart
  accountPickerSettings: AccountPickerSettings.fromJson(
    json['accountPickerSettings'] as Map<String, dynamic>?,
  ),
  ```
  (`lib/features/finance/services/finance_storage.dart:122-124`, inside `FinanceData.fromJson`.)
- **Notes:** Never throws on malformed input — every field degrades to its default individually,
  the same defensive pattern used by every other `fromJson` in this file.

### `AccountPickerSettings copyWith({String? sortMode, bool? groupByType, List<String>? customOrder, List<String>? moreAccountIds})` <a id="copywith"></a>
- **Kind:** method of `AccountPickerSettings`
- **Source:** `lib/features/finance/models/finance.dart` (line 65)
- **Purpose:** Return a copy of these settings with only the given fields replaced.
- **Inputs:** All four parameters optional; unset ones fall back to `this`'s current value.
- **Returns:** A new `AccountPickerSettings`.
- **Side effects:** None.
- **Algorithm:** Construct a new `AccountPickerSettings` with `field ?? this.field` for each of the
  four fields.
- **Usage:** Called from `normalizedAccountPickerSettings` in
  [`account_picker_util.dart`](../services/account_picker_util.md#normalizedaccountpickersettings):
  `settings.copyWith(sortMode: ..., customOrder: ..., moreAccountIds: ...)`.
- **Notes:** None.

### `Account({String? id, required AccountType type, required String bankOrApp, required String name, String currency = 'CNY', String? cardNumber, String? expiryDate, String? securityCode, String? emoji, String? imagePath, double? feeWaiverMinimumBalance, double? feeWaiverMonthlyDeposit, double? forcedBalance, DateTime? forcedBalanceDate, DateTime? modifiedAt})` <a id="account-new"></a>
- **Kind:** constructor of `Account`
- **Source:** `lib/features/finance/models/finance.dart` (line 102)
- **Purpose:** Create a bank/app account record, optionally with card metadata, an emoji/image, and
  the two alternative fee-waiver criteria described in
  [Finance](../../../../features/finance.md#model).
- **Inputs:** `type`, `bankOrApp`, `name` required; `currency` defaults to `'CNY'`;
  `feeWaiverMinimumBalance`/`feeWaiverMonthlyDeposit` are independent optional alternatives (meeting
  either waives the fee); `forcedBalance`/`forcedBalanceDate` are the legacy migration sentinel
  fields (see [`accountWithForcedBalanceSentinel`](../services/balance_util.md#accountwithforcedbalancesentinel)).
- **Returns:** A new `Account`.
- **Side effects:** None.
- **Algorithm:** Field-assigning constructor; `id` defaults to `const Uuid().v4()` and `modifiedAt`
  to `DateTime.now().toUtc()` when not supplied.
- **Usage:**
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
  (`lib/features/finance/views/accounts_page.dart:2050`, the account add/edit dialog's submit
  handler — passing the existing `widget.account?.id` reuses the id on edit, `null` generates a new
  one on create.)
- **Notes:** New-version balances are computed purely from transactions
  ([`accountBalance`](../services/balance_util.md#accountbalance)); `forcedBalance`/
  `forcedBalanceDate` only exist for old-version compatibility per
  [Finance](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions).

### `Map<String, dynamic> toJson()` <a id="account-tojson"></a>
- **Kind:** method of `Account`
- **Source:** `lib/features/finance/models/finance.dart` (line 126)
- **Purpose:** Serialize an account into the JSON stored in `finance_data.json`'s `accounts` array.
- **Inputs:** None.
- **Returns:** A map with `id`/`type`/`bankOrApp`/`name`/`currency`/`modifiedAt` always present, and
  every optional field (`cardNumber`, `expiryDate`, `securityCode`, `emoji`, `imagePath`, both fee
  waiver fields, `forcedBalance`, `forcedBalanceDate`) included only when non-null.
- **Side effects:** None.
- **Algorithm:** Map literal with `if (field != null)` guards per optional field;
  `forcedBalanceDate` and `modifiedAt` are written as `toIso8601String()`.
- **Usage:** Called from `FinanceData.toJson()`: `accounts.map((a) => a.toJson()).toList()`
  (`lib/features/finance/services/finance_storage.dart:54`).
- **Notes:** None.

### `factory Account.fromJson(Map<String, dynamic> json)` <a id="account-fromjson"></a>
- **Kind:** factory constructor of `Account`
- **Source:** `lib/features/finance/models/finance.dart` (line 152)
- **Purpose:** Parse an account back out of its persisted/synced JSON form.
- **Inputs:** `json` — decoded map, normally one entry of `finance_data.json`'s `accounts` array.
- **Returns:** A new `Account`.
- **Side effects:** None.
- **Algorithm:** Cast required fields (`id`, `bankOrApp`, `name`); `type` via
  `AccountType.values.byName`; every optional numeric/date field parsed with a null-safe cast/
  `DateTime.parse`; `modifiedAt` falls back to the Unix epoch when absent (an older/pre-`modifiedAt`
  record).
- **Usage:** Called from `FinanceData.fromJson`:
  `(json['accounts'] as List<dynamic>?)?.map((a) => Account.fromJson(a as Map<String, dynamic>))`
  (`lib/features/finance/services/finance_storage.dart:80-83`).
- **Notes:** `AccountType.values.byName` throws if `type` is an unrecognized string — unlike most of
  this file's `fromJson` methods, this one does not defensively fall back on a bad enum value.

### `Transaction({String? id, required TransactionType type, required double amount, String currency = 'CNY', String? rateSnapshotId, required String accountId, String? toAccountId, double? toAmount, String? toCurrency, String? categoryId, String? subscriptionId, String note = '', DateTime? date, DateTime? modifiedAt})` <a id="transaction-new"></a>
- **Kind:** constructor of `Transaction`
- **Source:** `lib/features/finance/models/finance.dart` (line 201)
- **Purpose:** Create an expense/income/transfer record, optionally carrying a historical
  rate-snapshot id and (for transfers) a target account/amount/currency.
- **Inputs:** `type`, `amount`, `accountId` required; `currency` defaults `'CNY'`; `toAccountId`/
  `toAmount`/`toCurrency` are transfer-only fields; `categoryId`/`subscriptionId` link back to a
  category or the subscription that generated this transaction.
- **Returns:** A new `Transaction`.
- **Side effects:** None.
- **Algorithm:** Field-assigning constructor; `id` defaults to a new UUID v4, `date` to
  `DateTime.now()` (local time, unlike `modifiedAt`), `modifiedAt` to `DateTime.now().toUtc()`.
- **Usage:**
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
  (`lib/features/finance/widgets/add_transaction_dialog.dart:654-667`, the add/edit transaction
  dialog's submit handler.)
- **Notes:** `rateSnapshotId` is what lets [`balance_util.dart`](../services/balance_util.md) convert
  a historical transaction using the exchange rates in effect when it was recorded, rather than
  today's rates — see `ExchangeRateData.ratesAt`.

### `Map<String, dynamic> toJson()` <a id="transaction-tojson"></a>
- **Kind:** method of `Transaction`
- **Source:** `lib/features/finance/models/finance.dart` (line 225)
- **Purpose:** Serialize a transaction into the JSON stored in `finance_data.json`'s `transactions`
  array.
- **Inputs:** None.
- **Returns:** A map with `id`/`type`/`amount`/`currency`/`accountId`/`note`/`date`/`modifiedAt`
  always present, and `rateSnapshotId`/`toAccountId`/`toAmount`/`toCurrency`/`categoryId`/
  `subscriptionId` included only when non-null.
- **Side effects:** None.
- **Algorithm:** Map literal with `if (field != null)` guards; `date`/`modifiedAt` as
  `toIso8601String()`.
- **Usage:** Called from `FinanceData.toJson()`: `transactions.map((t) => t.toJson()).toList()`
  (`lib/features/finance/services/finance_storage.dart:56`).
- **Notes:** None.

### `factory Transaction.fromJson(Map<String, dynamic> json)` <a id="transaction-fromjson"></a>
- **Kind:** factory constructor of `Transaction`
- **Source:** `lib/features/finance/models/finance.dart` (line 247)
- **Purpose:** Parse a transaction back out of its persisted/synced JSON form.
- **Inputs:** `json` — decoded map, normally one entry of `finance_data.json`'s `transactions`
  array.
- **Returns:** A new `Transaction`.
- **Side effects:** None.
- **Algorithm:** Cast required fields (`id`, `accountId`, `date` via `DateTime.parse`); `type` via
  `TransactionType.values.byName`; every optional field parsed with a null-safe cast; `modifiedAt`
  falls back to the Unix epoch when absent.
- **Usage:** Called from `FinanceData.fromJson`:
  `(json['transactions'] as List<dynamic>?)?.map((t) => Transaction.fromJson(t as Map<String, dynamic>))`
  (`lib/features/finance/services/finance_storage.dart:90-93`).
- **Notes:** `date` is required and parsed unconditionally (`DateTime.parse(json['date'] as
  String)`), unlike every other date field in this file — a transaction with a missing `date` throws
  rather than defaulting.

### `Category({String? id, required String name, required IconRef icon, String? emoji, required TransactionType type, DateTime? modifiedAt})` <a id="category-new"></a>
- **Kind:** constructor of `Category`
- **Source:** `lib/features/finance/models/finance.dart` (line 280)
- **Purpose:** Create a transaction category (expense, income, or transfer) with a Material icon
  reference and optional emoji.
- **Inputs:** `name`, `icon`, `type` required; `emoji` optional.
- **Returns:** A new `Category`.
- **Side effects:** None.
- **Algorithm:** Field-assigning constructor; `id`/`modifiedAt` default the same way as `Account`.
- **Usage:**
  ```dart
  final category = Category(
    id: widget.category?.id,
    name: name,
    icon: IconRef(codePoint: _selectedIcon.codePoint, fontFamily: _selectedIcon.fontFamily ?? 'MaterialIcons'),
    ...
  );
  ```
  (`lib/features/finance/views/categories_page.dart:723-728`, the add/edit category dialog's submit
  handler.)
- **Notes:** `type` supports `TransactionType.transfer` as well as expense/income — per
  [Finance](../../../../features/finance.md#model), transfer categories are a supported case, not
  just an expense/income split.

### `Map<String, dynamic> toJson()` <a id="category-tojson"></a>
- **Kind:** method of `Category`
- **Source:** `lib/features/finance/models/finance.dart` (line 295)
- **Purpose:** Serialize a category into the JSON stored in `finance_data.json`'s `categories`
  array.
- **Inputs:** None.
- **Returns:** `{id, name, icon: icon.toJson(), emoji?, type, modifiedAt}`.
- **Side effects:** None.
- **Algorithm:** Map literal; `icon` is nested via `IconRef.toJson()`.
- **Usage:** Called from `FinanceData.toJson()`: `categories.map((c) => c.toJson()).toList()`
  (`lib/features/finance/services/finance_storage.dart:55`).
- **Notes:** None.

### `factory Category.fromJson(Map<String, dynamic> json)` <a id="category-fromjson"></a>
- **Kind:** factory constructor of `Category`
- **Source:** `lib/features/finance/models/finance.dart` (line 309)
- **Purpose:** Parse a category back out of its persisted/synced JSON form.
- **Inputs:** `json` — decoded map, normally one entry of `finance_data.json`'s `categories` array.
- **Returns:** A new `Category`.
- **Side effects:** None.
- **Algorithm:** Cast `id`/`name`; `icon` via `IconRef.fromJson`; `type` via
  `TransactionType.values.byName`; `modifiedAt` falls back to the Unix epoch when absent.
- **Usage:** Called from `FinanceData.fromJson`:
  `(json['categories'] as List<dynamic>?)?.map((c) => Category.fromJson(c as Map<String, dynamic>))`
  (`lib/features/finance/services/finance_storage.dart:86-89`).
- **Notes:** None.

### `Subscription({String? id, required String name, String? emoji, String? imagePath, required DateTime startDate, int trialDays = 0, required BillingCycleType billingCycleType, int billingInterval = 1, required double amount, String currency = 'CNY', required String accountId, String? categoryId, String note = '', bool isActive = true, DateTime? cancelledAt, CancelType? cancelType, DateTime? nextBillingDate, DateTime? modifiedAt})` <a id="subscription-new"></a>
- **Kind:** constructor of `Subscription`
- **Source:** `lib/features/finance/models/finance.dart` (line 350)
- **Purpose:** Create a recurring subscription: trial period, billing cycle/interval, amount, target
  account/category, cancellation state, and the persisted `nextBillingDate` cursor.
- **Inputs:** `name`, `startDate`, `billingCycleType`, `amount`, `accountId` required; `trialDays`
  defaults `0`; `billingInterval` defaults `1` ("every X months/years"); `isActive` defaults `true`.
- **Returns:** A new `Subscription`.
- **Side effects:** None.
- **Algorithm:** Field-assigning constructor; `id`/`modifiedAt` default the same way as `Account`.
  Unlike other models, this constructor does **not** default `nextBillingDate` — it stays `null`
  until [`SubscriptionProcessor`](../services/subscription_processor.md) computes and persists it,
  which is exactly the "migration case" that processor's algorithm handles.
- **Usage:**
  ```dart
  final sub = Subscription(
    id: _isRestoringCopy ? null : widget.subscription?.id,
    name: name,
    ...
  );
  ```
  (`lib/features/finance/widgets/add_subscription_dialog.dart:541-542`; passing `id: null` for a
  restored/copied subscription is what gives the restore-as-new-subscription behavior described in
  [Finance](../../../../features/finance.md#views-and-analysis-page).)
- **Notes:** None beyond what's covered in [Subscription Billing](../../../../algorithms/subscription-billing.md).

### `DateTime get firstBillingDate` <a id="firstbillingdate"></a>
- **Kind:** getter of `Subscription`
- **Source:** `lib/features/finance/models/finance.dart` (line 378)
- **Purpose:** Return the anchor billing date — `startDate + trialDays` — that every subsequent
  billing cycle's day-of-month is measured against.
- **Inputs:** None.
- **Returns:** `DateTime`.
- **Side effects:** None.
- **Algorithm:** `startDate.add(Duration(days: trialDays))`.
- **Usage:**
  ```dart
  cursor = Subscription.nextBillingCursor(
    cursor: cursor,
    cycleType: sub.billingCycleType,
    interval: sub.billingInterval,
    anchor: sub.firstBillingDate,
  );
  ```
  (`lib/features/finance/services/subscription_processor.dart:116-121`, the `anchor` argument to
  every `nextBillingCursor` call in the processor's catch-up loop.)
- **Notes:** Classified Tier A (despite being a one-line getter) because this is the anchor value
  the entire month-end clamping algorithm in
  [Subscription Billing](../../../../algorithms/subscription-billing.md) is built around.

### `static DateTime nextBillingCursor({required DateTime cursor, required BillingCycleType cycleType, required int interval, required DateTime anchor})` <a id="nextbillingcursor"></a>
- **Kind:** static method of `Subscription`
- **Source:** `lib/features/finance/models/finance.dart` (line 389)
- **Purpose:** Advance a billing cursor by exactly one cycle, clamping the anchor's day-of-month to
  the target month's actual length instead of letting `DateTime` day overflow roll into the
  following month.
- **Inputs:** `cursor` — the current billing date; `cycleType` — `monthly` or `yearly`; `interval`
  — cycle multiplier (every N months/years); `anchor` — `firstBillingDate`, whose day-of-month is
  preserved when possible.
- **Returns:** `DateTime` — the next billing date.
- **Side effects:** None.
- **Algorithm:** See [Subscription Billing](../../../../algorithms/subscription-billing.md#month-end-clamping-subscriptionnextbillingcursor)
  for the full walkthrough. In brief: monthly cycles advance `month` by `interval` within the same
  `year` (letting `DateTime` normalize `month > 12` into the next year); yearly cycles advance
  `year` by `interval` and pin `month` to the anchor's month. Either way, `lastDay =
  DateTime(year, month + 1, 0).day` computes the target month's actual last day (day `0` of next
  month), and the returned day is `anchor.day < lastDay ? anchor.day : lastDay`.
- **Usage:**
  ```dart
  cursor = nextBillingCursor(
    cursor: cursor,
    cycleType: billingCycleType,
    interval: billingInterval,
    anchor: first,
  );
  ```
  (`lib/features/finance/models/finance.dart:421-426`, inside this class's own
  [`calculateNextBillingDate`](#calculatenextbillingdate); also called identically from
  [`billingDatesBefore`](#billingdatesbefore) and from
  [`SubscriptionProcessor.process`](../services/subscription_processor.md#process) — this is the
  single function every billing-date advance in the app goes through.)
- **Notes:** A Jan 31 monthly anchor bills Feb 28/29, Mar 31, Apr 30, … — see
  [Subscription Billing Walkthrough](../../../../examples/subscription-billing-walkthrough.md) for
  concrete dates.

### `DateTime? calculateNextBillingDate({DateTime? after})` <a id="calculatenextbillingdate"></a>
- **Kind:** method of `Subscription`
- **Source:** `lib/features/finance/models/finance.dart` (line 416)
- **Purpose:** Compute the first billing date strictly after a given date (or now), respecting an
  `atExpiry` cancellation cutoff.
- **Inputs:** `after` — defaults to `DateTime.now()` when omitted.
- **Returns:** `DateTime?` — `null` if the subscription is `atExpiry`-cancelled and the computed
  cursor would land after `cancelledAt`.
- **Side effects:** None.
- **Algorithm:**
  1. Start `cursor` at `firstBillingDate`.
  2. Loop `cursor = nextBillingCursor(...)` while `!cursor.isAfter(after)`.
  3. If `cancelType == atExpiry` and `cursor.isAfter(cancelledAt!)`, return `null`.
  4. Otherwise return `cursor`.
- **Usage:**
  ```dart
  nbd = sub.calculateNextBillingDate(
    after: today.subtract(const Duration(days: 1)),
  );
  ```
  (`lib/features/finance/services/subscription_processor.dart:70-72`, the migration path that
  computes `nextBillingDate` for the first time on a subscription that predates the field; also used
  by `lib/features/finance/views/subscriptions_page.dart` for display-only "next billing date"
  previews.)
- **Notes:** Month-end anchors are clamped per cycle via [`nextBillingCursor`](#nextbillingcursor) —
  see [Subscription Billing](../../../../algorithms/subscription-billing.md).

### `List<DateTime> billingDatesBefore(DateTime until)` <a id="billingdatesbefore"></a>
- **Kind:** method of `Subscription`
- **Source:** `lib/features/finance/models/finance.dart` (line 442)
- **Purpose:** Generate every billing date from the subscription's anchor up to (and including) a
  cutoff date.
- **Inputs:** `until` — the inclusive cutoff.
- **Returns:** `List<DateTime>`, in chronological order.
- **Side effects:** None.
- **Algorithm:**
  1. Start `cursor` at `firstBillingDate`.
  2. While `!cursor.isAfter(until)`: append `cursor` to `dates`, then advance via
     `nextBillingCursor(...)`.
  3. Return `dates`.
- **Usage:**
  ```dart
  final dates = sub.billingDatesBefore(now);
  ```
  (`lib/features/finance/views/subscriptions_page.dart:545`, used to count/display how many times a
  subscription has billed to date.)
- **Notes:** Unlike `calculateNextBillingDate`, this ignores `atExpiry` cancellation — it lists every
  cycle date up to `until` regardless of whether the subscription would actually have generated a
  transaction that far (the caller is responsible for cross-referencing cancellation if needed).

### `Map<String, dynamic> toJson()` <a id="subscription-tojson"></a>
- **Kind:** method of `Subscription`
- **Source:** `lib/features/finance/models/finance.dart` (line 463)
- **Purpose:** Serialize a subscription into the JSON stored in `finance_data.json`'s
  `subscriptions` array.
- **Inputs:** None.
- **Returns:** A map with `id`/`name`/`startDate`/`trialDays`/`billingCycleType`/`billingInterval`/
  `amount`/`currency`/`accountId`/`note`/`isActive`/`modifiedAt` always present, and `emoji`/
  `imagePath`/`categoryId`/`cancelledAt`/`cancelType`/`nextBillingDate` only when non-null.
- **Side effects:** None.
- **Algorithm:** Map literal with `if (field != null)` guards; date fields as
  `toIso8601String()`, enums as `.name`.
- **Usage:** Called from `FinanceData.toJson()`: `subscriptions.map((s) => s.toJson()).toList()`
  (`lib/features/finance/services/finance_storage.dart:57`).
- **Notes:** None.

### `factory Subscription.fromJson(Map<String, dynamic> json)` <a id="subscription-fromjson"></a>
- **Kind:** factory constructor of `Subscription`
- **Source:** `lib/features/finance/models/finance.dart` (line 490)
- **Purpose:** Parse a subscription back out of its persisted/synced JSON form.
- **Inputs:** `json` — decoded map, normally one entry of `finance_data.json`'s `subscriptions`
  array.
- **Returns:** A new `Subscription`.
- **Side effects:** None.
- **Algorithm:** Cast required fields; `billingCycleType` defaults to `'monthly'` when absent (older
  data predating the field); `trialDays` defaults `0`, `billingInterval` defaults `1`, `isActive`
  defaults `true`; `cancelledAt`/`cancelType`/`nextBillingDate` all null-safe; `modifiedAt` falls
  back to the Unix epoch when absent.
- **Usage:** Called from `FinanceData.fromJson`:
  `(json['subscriptions'] as List<dynamic>?)?.map((s) => Subscription.fromJson(s as Map<String, dynamic>))`
  (`lib/features/finance/services/finance_storage.dart:96-99`).
- **Notes:** A subscription loaded via this factory with no `nextBillingDate` key is exactly the
  "migration case" `SubscriptionProcessor.process` detects and handles on its first pass.

### `const IconRef({required int codePoint, String fontFamily = 'MaterialIcons'})` <a id="iconref-new"></a>
- **Kind:** const constructor of `IconRef`
- **Source:** `lib/features/finance/models/finance.dart` (line 532)
- **Purpose:** Hold a Material icon's numeric code point and font family so it can be persisted and
  reconstructed without storing a full `IconData`.
- **Inputs:** `codePoint` required; `fontFamily` defaults `'MaterialIcons'`.
- **Returns:** A new `IconRef`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor.
- **Usage:**
  ```dart
  icon: IconRef(codePoint: (d['icon'] as IconData).codePoint),
  ```
  (`lib/features/finance/views/categories_page.dart:226`, building a default category's icon
  reference from a Material `IconData` constant.)
- **Notes:** Because icon data is reconstructed dynamically from these two fields rather than a
  compile-time constant, release builds need `--no-tree-shake-icons` (per
  [Finance](../../../../features/finance.md#model)).

### `Map<String, dynamic> toJson()` <a id="iconref-tojson"></a>
- **Kind:** method of `IconRef`
- **Source:** `lib/features/finance/models/finance.dart` (line 539)
- **Purpose:** Serialize an icon reference into the JSON nested under a category's `icon` key.
- **Inputs:** None.
- **Returns:** `{codePoint, fontFamily}`.
- **Side effects:** None.
- **Algorithm:** Direct map literal.
- **Usage:** Called from `Category.toJson()`: `'icon': icon.toJson()`
  (`lib/features/finance/models/finance.dart:298`).
- **Notes:** None.

### `factory IconRef.fromJson(Map<String, dynamic> json)` <a id="iconref-fromjson"></a>
- **Kind:** factory constructor of `IconRef`
- **Source:** `lib/features/finance/models/finance.dart` (line 549)
- **Purpose:** Parse an icon reference back out of a category's nested `icon` JSON.
- **Inputs:** `json` — decoded map.
- **Returns:** A new `IconRef`.
- **Side effects:** None.
- **Algorithm:** Cast `codePoint` as required `int`; `fontFamily` defaults `'MaterialIcons'` when
  absent.
- **Usage:** Called from `Category.fromJson`:
  `icon: IconRef.fromJson(json['icon'] as Map<String, dynamic>)`
  (`lib/features/finance/models/finance.dart:312`).
- **Notes:** None.

### `IconData toIconData()` <a id="toicondata"></a>
- **Kind:** method of `IconRef`
- **Source:** `lib/features/finance/models/finance.dart` (line 560)
- **Purpose:** Reconstruct a usable Flutter `IconData` from the stored code point and font family,
  for rendering a category's icon.
- **Inputs:** None.
- **Returns:** `IconData`.
- **Side effects:** None.
- **Algorithm:** `IconData(codePoint, fontFamily: fontFamily)`, with a
  `// ignore: non_const_argument_for_const_parameter` comment since `codePoint`/`fontFamily` are
  runtime values, not compile-time constants.
- **Usage:**
  ```dart
  cat.icon.toIconData(),
  ```
  (`lib/features/finance/views/categories_page.dart:398`, rendering a category's icon in the list;
  also used at `categories_page.dart:522` to seed the icon picker when editing.)
- **Notes:** Dynamic persisted icon references intentionally cannot be `const` — this is the reason
  release builds need `--no-tree-shake-icons` (see [`IconRef()`](#iconref-new)).

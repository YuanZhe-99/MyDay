import 'package:flutter/widgets.dart' show IconData;
import 'package:uuid/uuid.dart';

enum AccountType { fund, credit, recharge, financial }

class AccountPickerSettings {
  static const sortName = 'name';
  static const sortCustom = 'custom';

  final String sortMode;
  final bool groupByType;
  final List<String> customOrder;
  final List<String> moreAccountIds;

  /// Purpose: Create account picker settings for transaction dialogs.
  /// Inputs: Optional sort, grouping, custom order, and more-list account ids.
  /// Returns: A new `AccountPickerSettings` instance.
  /// Side effects: None.
  /// Notes: The default preserves the incoming account order without type grouping.
  const AccountPickerSettings({
    this.sortMode = sortCustom,
    this.groupByType = false,
    this.customOrder = const [],
    this.moreAccountIds = const [],
  });

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with finance settings persistence and sync.
  Map<String, dynamic> toJson() => {
    'sortMode': sortMode,
    'groupByType': groupByType,
    if (customOrder.isNotEmpty) 'customOrder': customOrder,
    if (moreAccountIds.isNotEmpty) 'moreAccountIds': moreAccountIds,
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `AccountPickerSettings` instance.
  /// Side effects: None.
  /// Notes: Invalid or missing values fall back to the default settings.
  factory AccountPickerSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AccountPickerSettings();
    final sortMode = json['sortMode'] as String? ?? sortCustom;
    return AccountPickerSettings(
      sortMode: sortMode == sortName || sortMode == sortCustom
          ? sortMode
          : sortCustom,
      groupByType: json['groupByType'] as bool? ?? false,
      customOrder:
          (json['customOrder'] as List<dynamic>?)?.cast<String>() ?? const [],
      moreAccountIds:
          (json['moreAccountIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
    );
  }

  /// Purpose: Create a modified copy of this settings value.
  /// Inputs: Optional replacement fields.
  /// Returns: A new `AccountPickerSettings` instance.
  /// Side effects: None.
  /// Notes: Use this for immutable state updates in UI settings pages.
  AccountPickerSettings copyWith({
    String? sortMode,
    bool? groupByType,
    List<String>? customOrder,
    List<String>? moreAccountIds,
  }) {
    return AccountPickerSettings(
      sortMode: sortMode ?? this.sortMode,
      groupByType: groupByType ?? this.groupByType,
      customOrder: customOrder ?? this.customOrder,
      moreAccountIds: moreAccountIds ?? this.moreAccountIds,
    );
  }
}

class Account {
  final String id;
  final AccountType type;
  final String bankOrApp;
  final String name;
  final String currency;
  final String? cardNumber;
  final String? expiryDate;
  final String? securityCode;
  final String? emoji;
  final String? imagePath;
  final double? feeWaiverMinimumBalance;
  final double? feeWaiverMonthlyDeposit;
  final double? forcedBalance;
  final DateTime? forcedBalanceDate;
  final DateTime modifiedAt;

  /// Purpose: Create a account instance.
  /// Inputs: `currency`, optional fee waiver amounts.
  /// Returns: A new `Account` instance.
  /// Side effects: None.
  /// Notes: None.
  Account({
    String? id,
    required this.type,
    required this.bankOrApp,
    required this.name,
    this.currency = 'CNY',
    this.cardNumber,
    this.expiryDate,
    this.securityCode,
    this.emoji,
    this.imagePath,
    this.feeWaiverMinimumBalance,
    this.feeWaiverMonthlyDeposit,
    this.forcedBalance,
    this.forcedBalanceDate,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'bankOrApp': bankOrApp,
    'name': name,
    'currency': currency,
    if (cardNumber != null) 'cardNumber': cardNumber,
    if (expiryDate != null) 'expiryDate': expiryDate,
    if (securityCode != null) 'securityCode': securityCode,
    if (emoji != null) 'emoji': emoji,
    if (imagePath != null) 'imagePath': imagePath,
    if (feeWaiverMinimumBalance != null)
      'feeWaiverMinimumBalance': feeWaiverMinimumBalance,
    if (feeWaiverMonthlyDeposit != null)
      'feeWaiverMonthlyDeposit': feeWaiverMonthlyDeposit,
    if (forcedBalance != null) 'forcedBalance': forcedBalance,
    if (forcedBalanceDate != null)
      'forcedBalanceDate': forcedBalanceDate!.toIso8601String(),
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `Account.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    type: AccountType.values.byName(json['type'] as String),
    bankOrApp: json['bankOrApp'] as String,
    name: json['name'] as String,
    currency: json['currency'] as String? ?? 'CNY',
    cardNumber: json['cardNumber'] as String?,
    expiryDate: json['expiryDate'] as String?,
    securityCode: json['securityCode'] as String?,
    emoji: json['emoji'] as String?,
    imagePath: json['imagePath'] as String?,
    feeWaiverMinimumBalance: (json['feeWaiverMinimumBalance'] as num?)
        ?.toDouble(),
    feeWaiverMonthlyDeposit: (json['feeWaiverMonthlyDeposit'] as num?)
        ?.toDouble(),
    forcedBalance: (json['forcedBalance'] as num?)?.toDouble(),
    forcedBalanceDate: json['forcedBalanceDate'] != null
        ? DateTime.parse(json['forcedBalanceDate'] as String)
        : null,
    modifiedAt: json['modifiedAt'] != null
        ? DateTime.parse(json['modifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

enum TransactionType { expense, income, transfer }

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String currency;
  final String?
  rateSnapshotId; // references RateSnapshot with all rates at recording time
  final String accountId;
  final String? toAccountId; // for transfers
  final double? toAmount; // amount received in target currency (cross-currency)
  final String? toCurrency; // target currency for cross-currency transfers
  final String? categoryId;
  final String? subscriptionId;
  final String note;
  final DateTime date;
  final DateTime modifiedAt;

  /// Purpose: Create a transaction instance.
  /// Inputs: `currency`.
  /// Returns: A new `Transaction` instance.
  /// Side effects: None.
  /// Notes: None.
  Transaction({
    String? id,
    required this.type,
    required this.amount,
    this.currency = 'CNY',
    this.rateSnapshotId,
    required this.accountId,
    this.toAccountId,
    this.toAmount,
    this.toCurrency,
    this.categoryId,
    this.subscriptionId,
    this.note = '',
    DateTime? date,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now(),
       modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'currency': currency,
    if (rateSnapshotId != null) 'rateSnapshotId': rateSnapshotId,
    'accountId': accountId,
    if (toAccountId != null) 'toAccountId': toAccountId,
    if (toAmount != null) 'toAmount': toAmount,
    if (toCurrency != null) 'toCurrency': toCurrency,
    if (categoryId != null) 'categoryId': categoryId,
    if (subscriptionId != null) 'subscriptionId': subscriptionId,
    'note': note,
    'date': date.toIso8601String(),
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `Transaction.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    type: TransactionType.values.byName(json['type'] as String),
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] as String? ?? 'CNY',
    rateSnapshotId: json['rateSnapshotId'] as String?,
    accountId: json['accountId'] as String,
    toAccountId: json['toAccountId'] as String?,
    toAmount: (json['toAmount'] as num?)?.toDouble(),
    toCurrency: json['toCurrency'] as String?,
    categoryId: json['categoryId'] as String?,
    subscriptionId: json['subscriptionId'] as String?,
    note: json['note'] as String? ?? '',
    date: DateTime.parse(json['date'] as String),
    modifiedAt: json['modifiedAt'] != null
        ? DateTime.parse(json['modifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class Category {
  final String id;
  final String name;
  final IconRef icon;
  final String? emoji;
  final TransactionType type; // expense or income
  final DateTime modifiedAt;

  /// Purpose: Create a category instance.
  /// Inputs: None.
  /// Returns: A new `Category` instance.
  /// Side effects: None.
  /// Notes: None.
  Category({
    String? id,
    required this.name,
    required this.icon,
    this.emoji,
    required this.type,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.toJson(),
    if (emoji != null) 'emoji': emoji,
    'type': type.name,
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `Category.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: IconRef.fromJson(json['icon'] as Map<String, dynamic>),
    emoji: json['emoji'] as String?,
    type: TransactionType.values.byName(json['type'] as String),
    modifiedAt: json['modifiedAt'] != null
        ? DateTime.parse(json['modifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

enum BillingCycleType { monthly, yearly }

enum CancelType { immediate, atExpiry }

class Subscription {
  final String id;
  final String name;
  final String? emoji;
  final String? imagePath;
  final DateTime startDate;
  final int trialDays;
  final BillingCycleType billingCycleType;
  final int billingInterval; // every X months or X years
  final double amount;
  final String currency;
  final String accountId;
  final String? categoryId;
  final String note;
  final bool isActive;
  final DateTime? cancelledAt;
  final CancelType? cancelType;
  final DateTime? nextBillingDate;
  final DateTime modifiedAt;

  /// Purpose: Create a subscription instance.
  /// Inputs: `trialDays`.
  /// Returns: A new `Subscription` instance.
  /// Side effects: None.
  /// Notes: None.
  Subscription({
    String? id,
    required this.name,
    this.emoji,
    this.imagePath,
    required this.startDate,
    this.trialDays = 0,
    required this.billingCycleType,
    this.billingInterval = 1,
    required this.amount,
    this.currency = 'CNY',
    required this.accountId,
    this.categoryId,
    this.note = '',
    this.isActive = true,
    this.cancelledAt,
    this.cancelType,
    this.nextBillingDate,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// The first billing date (start + trial days).
  /// Purpose: Return first billing date.
  /// Inputs: None.
  /// Returns: `DateTime`.
  /// Side effects: None.
  /// Notes: None.
  DateTime get firstBillingDate => startDate.add(Duration(days: trialDays));

  /// Purpose: Advance a billing cursor by one cycle with month-length clamping.
  /// Inputs: `cursor` current billing date, `cycleType`, `interval`, `anchor` first billing date.
  /// Returns: `DateTime` — the next billing date.
  /// Side effects: None.
  /// Notes: Monthly cycles keep the anchor day-of-month clamped to the target
  /// month's last day (a Jan 31 anchor bills Feb 28/29, Mar 31, Apr 30, ...)
  /// instead of letting `DateTime` day overflow skip and drift months. Yearly
  /// cycles clamp Feb 29 anchors in non-leap years. All billing-date advances
  /// (model and `SubscriptionProcessor`) must go through this helper.
  static DateTime nextBillingCursor({
    required DateTime cursor,
    required BillingCycleType cycleType,
    required int interval,
    required DateTime anchor,
  }) {
    final int year;
    final int month;
    if (cycleType == BillingCycleType.monthly) {
      year = cursor.year;
      month = cursor.month + interval;
    } else {
      year = cursor.year + interval;
      month = anchor.month;
    }
    // Day 0 of the following month is the last day of the target month.
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = anchor.day < lastDay ? anchor.day : lastDay;
    return DateTime(year, month, day);
  }

  /// Compute next billing date after [after] date.
  /// Purpose: Calculate next billing date from the available inputs.
  /// Inputs: `after`.
  /// Returns: `DateTime?`.
  /// Side effects: None.
  /// Notes: Month-end anchors are clamped per cycle via [nextBillingCursor].
  DateTime? calculateNextBillingDate({DateTime? after}) {
    after ??= DateTime.now();
    final first = firstBillingDate;
    var cursor = first;
    while (!cursor.isAfter(after)) {
      cursor = nextBillingCursor(
        cursor: cursor,
        cycleType: billingCycleType,
        interval: billingInterval,
        anchor: first,
      );
    }
    if (cancelType == CancelType.atExpiry &&
        cancelledAt != null &&
        cursor.isAfter(cancelledAt!)) {
      return null;
    }
    return cursor;
  }

  /// Generate all billing dates from start up to [until].
  /// Purpose: Implement the billing dates before behavior for this file.
  /// Inputs: `until`.
  /// Returns: `List<DateTime>`.
  /// Side effects: None.
  /// Notes: Month-end anchors are clamped per cycle via [nextBillingCursor].
  List<DateTime> billingDatesBefore(DateTime until) {
    final dates = <DateTime>[];
    final first = firstBillingDate;
    var cursor = first;
    while (!cursor.isAfter(until)) {
      dates.add(cursor);
      cursor = nextBillingCursor(
        cursor: cursor,
        cycleType: billingCycleType,
        interval: billingInterval,
        anchor: first,
      );
    }
    return dates;
  }

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (emoji != null) 'emoji': emoji,
    if (imagePath != null) 'imagePath': imagePath,
    'startDate': startDate.toIso8601String(),
    'trialDays': trialDays,
    'billingCycleType': billingCycleType.name,
    'billingInterval': billingInterval,
    'amount': amount,
    'currency': currency,
    'accountId': accountId,
    if (categoryId != null) 'categoryId': categoryId,
    'note': note,
    'isActive': isActive,
    if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
    if (cancelType != null) 'cancelType': cancelType!.name,
    if (nextBillingDate != null)
      'nextBillingDate': nextBillingDate!.toIso8601String(),
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `Subscription.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String?,
    imagePath: json['imagePath'] as String?,
    startDate: DateTime.parse(json['startDate'] as String),
    trialDays: json['trialDays'] as int? ?? 0,
    billingCycleType: BillingCycleType.values.byName(
      json['billingCycleType'] as String? ?? 'monthly',
    ),
    billingInterval: json['billingInterval'] as int? ?? 1,
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] as String? ?? 'CNY',
    accountId: json['accountId'] as String,
    categoryId: json['categoryId'] as String?,
    note: json['note'] as String? ?? '',
    isActive: json['isActive'] as bool? ?? true,
    cancelledAt: json['cancelledAt'] != null
        ? DateTime.parse(json['cancelledAt'] as String)
        : null,
    cancelType: json['cancelType'] != null
        ? CancelType.values.byName(json['cancelType'] as String)
        : null,
    nextBillingDate: json['nextBillingDate'] != null
        ? DateTime.parse(json['nextBillingDate'] as String)
        : null,
    modifiedAt: json['modifiedAt'] != null
        ? DateTime.parse(json['modifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

// Lightweight icon reference (icon code point + font family)
class IconRef {
  final int codePoint;
  final String fontFamily;

  /// Purpose: Create a icon ref instance.
  /// Inputs: `fontFamily`.
  /// Returns: A new `IconRef` instance.
  /// Side effects: None.
  /// Notes: None.
  const IconRef({required this.codePoint, this.fontFamily = 'MaterialIcons'});

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'codePoint': codePoint,
    'fontFamily': fontFamily,
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `IconRef.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory IconRef.fromJson(Map<String, dynamic> json) => IconRef(
    codePoint: json['codePoint'] as int,
    fontFamily: json['fontFamily'] as String? ?? 'MaterialIcons',
  );

  /// Purpose: Implement the to icon data behavior for this file.
  /// Inputs: None.
  /// Returns: `IconData`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: None.
  IconData toIconData() => IconData(codePoint, fontFamily: fontFamily);
}

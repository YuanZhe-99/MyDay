import 'dart:convert';
import 'dart:io';

import '../../../shared/utils/json_preservation.dart';
import '../../todo/services/todo_storage.dart';
import '../models/finance.dart';

class FinanceData {
  final List<Account> accounts;
  final List<Category> categories;
  final List<Transaction> transactions;
  final List<Subscription> subscriptions;
  final String defaultCurrency;
  final DateTime settingsModifiedAt;
  final int? subscriptionReminderHour;
  final int? subscriptionReminderMinute;
  final String? subscriptionSortMode;
  final List<String>? subscriptionCustomOrder;
  final Map<String, String> accountSortModes;
  final Map<String, List<String>> accountCustomOrders;

  /// Purpose: Create a finance data instance.
  /// Inputs: `subscriptions`.
  /// Returns: A new `FinanceData` instance.
  /// Side effects: None.
  /// Notes: None.
  FinanceData({
    required this.accounts,
    required this.categories,
    required this.transactions,
    this.subscriptions = const [],
    this.defaultCurrency = 'CNY',
    DateTime? settingsModifiedAt,
    this.subscriptionReminderHour,
    this.subscriptionReminderMinute,
    this.subscriptionSortMode,
    this.subscriptionCustomOrder,
    this.accountSortModes = const {},
    this.accountCustomOrders = const {},
  }) : settingsModifiedAt =
           settingsModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'accounts': accounts.map((a) => a.toJson()).toList(),
    'categories': categories.map((c) => c.toJson()).toList(),
    'transactions': transactions.map((t) => t.toJson()).toList(),
    'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
    'defaultCurrency': defaultCurrency,
    'settingsModifiedAt': settingsModifiedAt.toIso8601String(),
    if (subscriptionReminderHour != null)
      'subscriptionReminderHour': subscriptionReminderHour,
    if (subscriptionReminderMinute != null)
      'subscriptionReminderMinute': subscriptionReminderMinute,
    if (subscriptionSortMode != null)
      'subscriptionSortMode': subscriptionSortMode,
    if (subscriptionCustomOrder != null)
      'subscriptionCustomOrder': subscriptionCustomOrder,
    if (accountSortModes.isNotEmpty) 'accountSortModes': accountSortModes,
    if (accountCustomOrders.isNotEmpty)
      'accountCustomOrders': accountCustomOrders,
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `FinanceData.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory FinanceData.fromJson(Map<String, dynamic> json) => FinanceData(
    accounts:
        (json['accounts'] as List<dynamic>?)
            ?.map((a) => Account.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [],
    categories:
        (json['categories'] as List<dynamic>?)
            ?.map((c) => Category.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [],
    transactions:
        (json['transactions'] as List<dynamic>?)
            ?.map((t) => Transaction.fromJson(t as Map<String, dynamic>))
            .toList() ??
        [],
    subscriptions:
        (json['subscriptions'] as List<dynamic>?)
            ?.map((s) => Subscription.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [],
    defaultCurrency: json['defaultCurrency'] as String? ?? 'CNY',
    settingsModifiedAt: json['settingsModifiedAt'] != null
        ? DateTime.parse(json['settingsModifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
    subscriptionReminderHour: json['subscriptionReminderHour'] as int?,
    subscriptionReminderMinute: json['subscriptionReminderMinute'] as int?,
    subscriptionSortMode: json['subscriptionSortMode'] as String?,
    subscriptionCustomOrder: (json['subscriptionCustomOrder'] as List<dynamic>?)
        ?.cast<String>(),
    accountSortModes:
        (json['accountSortModes'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as String),
        ) ??
        const {},
    accountCustomOrders:
        (json['accountCustomOrders'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>).map((e) => e as String).toList(),
          ),
        ) ??
        const {},
  );
}

class FinanceStorage {
  static const _fileName = 'finance_data.json';

  /// Purpose: Provide the internal get file helper for this file.
  /// Inputs: None.
  /// Returns: `Future<File>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static Future<File> _getFile() async {
    final appDir = await TodoStorage.getAppDir();
    return File('${appDir.path}/$_fileName');
  }

  /// Purpose: Implement the load behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<FinanceData?>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<FinanceData?> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();

      final json = jsonDecode(raw) as Map<String, dynamic>;
      return FinanceData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Purpose: Implement the save behavior for this file.
  /// Inputs: `data`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<void> save(FinanceData data) async {
    final file = await _getFile();
    final jsonStr = await JsonPreservation.encodeForFile(
      file: file,
      next: data.toJson(),
      schema: dataFilePreservationSchemas[_fileName]!,
    );
    await file.writeAsString(jsonStr);
  }
}

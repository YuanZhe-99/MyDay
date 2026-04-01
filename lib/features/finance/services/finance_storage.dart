import 'dart:convert';
import 'dart:io';

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
  }) : settingsModifiedAt = settingsModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  Map<String, dynamic> toJson() => {
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
        'defaultCurrency': defaultCurrency,
        'settingsModifiedAt': settingsModifiedAt.toIso8601String(),
        if (subscriptionReminderHour != null) 'subscriptionReminderHour': subscriptionReminderHour,
        if (subscriptionReminderMinute != null) 'subscriptionReminderMinute': subscriptionReminderMinute,
        if (subscriptionSortMode != null) 'subscriptionSortMode': subscriptionSortMode,
        if (subscriptionCustomOrder != null) 'subscriptionCustomOrder': subscriptionCustomOrder,
      };

  factory FinanceData.fromJson(Map<String, dynamic> json) => FinanceData(
        accounts: (json['accounts'] as List<dynamic>?)
                ?.map((a) => Account.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        categories: (json['categories'] as List<dynamic>?)
                ?.map((c) => Category.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        transactions: (json['transactions'] as List<dynamic>?)
                ?.map((t) => Transaction.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        subscriptions: (json['subscriptions'] as List<dynamic>?)
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
        subscriptionCustomOrder: (json['subscriptionCustomOrder'] as List<dynamic>?)?.cast<String>(),
      );
}

class FinanceStorage {
  static const _fileName = 'finance_data.json';

  static Future<File> _getFile() async {
    final appDir = await TodoStorage.getAppDir();
    return File('${appDir.path}/$_fileName');
  }

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

  static Future<void> save(FinanceData data) async {
    final file = await _getFile();
    final jsonStr = jsonEncode(data.toJson());
    await file.writeAsString(jsonStr);
  }
}

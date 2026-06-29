import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../shared/utils/json_preservation.dart';
import '../../todo/services/todo_storage.dart';
import '../models/finance.dart';
import 'balance_util.dart';
import 'exchange_rate_storage.dart';

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
  final AccountPickerSettings accountPickerSettings;

  /// Purpose: Create a finance data instance.
  /// Inputs: Finance records and persisted finance settings.
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
    this.accountPickerSettings = const AccountPickerSettings(),
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
    'accountPickerSettings': accountPickerSettings.toJson(),
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
    accountPickerSettings: AccountPickerSettings.fromJson(
      json['accountPickerSettings'] as Map<String, dynamic>?,
    ),
  );
}

class FinanceStorageException implements Exception {
  final String message;

  /// Purpose: Create a finance storage exception with a user-visible message.
  /// Inputs: `message`.
  /// Returns: A new `FinanceStorageException` instance.
  /// Side effects: None.
  /// Notes: Thrown when finance data exists but cannot be safely read or written.
  const FinanceStorageException(this.message);

  /// Purpose: Return a readable exception message.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Used by UI and sync/import error reporting.
  @override
  String toString() => message;
}

class FinanceStorage {
  static const _fileName = 'finance_data.json';
  static Future<void> _writeQueue = Future<void>.value();

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
  /// Notes: A missing file returns null, but an unreadable existing file throws
  /// so callers never treat corrupted finance data as an empty dataset.
  static Future<FinanceData?> load() async {
    final file = await _getFile();
    if (!await file.exists()) return null;

    try {
      final raw = await file.readAsString();

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final data = FinanceData.fromJson(json);
      final rateData = await ExchangeRateStorage.load();
      final migrated = _migrateForcedBalances(data, rateData);
      if (identical(migrated, data)) return data;

      try {
        await save(migrated);
      } catch (_) {}
      return migrated;
    } on FormatException catch (e) {
      throw FinanceStorageException('$_fileName is not valid JSON: $e');
    } catch (e) {
      throw FinanceStorageException('Failed to load $_fileName: $e');
    }
  }

  /// Purpose: Provide the internal migrate forced balances helper for this file.
  /// Inputs: `data`, `rateData`.
  /// Returns: `FinanceData`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: Internal helper used within this file only.
  static FinanceData _migrateForcedBalances(
    FinanceData data,
    ExchangeRateData rateData,
  ) {
    final migration = migrateForcedBalances(
      accounts: data.accounts,
      transactions: data.transactions,
      rateData: rateData,
    );
    if (!migration.changed) return data;

    return FinanceData(
      accounts: migration.accounts,
      categories: data.categories,
      transactions: migration.transactions,
      subscriptions: data.subscriptions,
      defaultCurrency: data.defaultCurrency,
      settingsModifiedAt: data.settingsModifiedAt,
      subscriptionReminderHour: data.subscriptionReminderHour,
      subscriptionReminderMinute: data.subscriptionReminderMinute,
      subscriptionSortMode: data.subscriptionSortMode,
      subscriptionCustomOrder: data.subscriptionCustomOrder,
      accountSortModes: data.accountSortModes,
      accountCustomOrders: data.accountCustomOrders,
      accountPickerSettings: data.accountPickerSettings,
    );
  }

  /// Purpose: Implement the save behavior for this file.
  /// Inputs: `data`.
  /// Returns: `Future<void>`.
  /// Side effects: Serializes finance writes, validates generated JSON, and atomically replaces the data file.
  /// Notes: Prevents overlapping writers from interleaving and corrupting JSON.
  static Future<void> save(FinanceData data) async {
    final next = _writeQueue.then(
      (_) => _saveNow(data),
      onError: (_) => _saveNow(data),
    );
    _writeQueue = next.catchError((_) {});
    return next;
  }

  /// Purpose: Persist finance data after the caller has entered the write queue.
  /// Inputs: `data`.
  /// Returns: `Future<void>`.
  /// Side effects: Writes `finance_data.json` through a validated temporary file.
  /// Notes: Internal helper used within this file only.
  static Future<void> _saveNow(FinanceData data) async {
    final file = await _getFile();
    final jsonStr = await JsonPreservation.encodeForFile(
      file: file,
      next: data.toJson(),
      schema: dataFilePreservationSchemas[_fileName]!,
    );
    await _atomicWriteJson(file, jsonStr);
  }

  /// Purpose: Replace a JSON file only after the replacement content validates.
  /// Inputs: `file`, `jsonStr`.
  /// Returns: `Future<void>`.
  /// Side effects: Creates and renames a temporary file in the same directory.
  /// Notes: Internal helper used within this file only.
  static Future<void> _atomicWriteJson(File file, String jsonStr) async {
    try {
      jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw FinanceStorageException('Refusing to write invalid $_fileName: $e');
    }

    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    final tmp = File(
      '${file.path}.tmp-${DateTime.now().microsecondsSinceEpoch}',
    );
    await tmp.writeAsString(jsonStr, flush: true);
    try {
      jsonDecode(await tmp.readAsString()) as Map<String, dynamic>;
      await tmp.rename(file.path);
    } catch (e) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      if (e is FinanceStorageException) rethrow;
      throw FinanceStorageException('Failed to write $_fileName safely: $e');
    }
  }
}

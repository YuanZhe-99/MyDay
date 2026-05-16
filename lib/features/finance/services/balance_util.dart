import '../models/finance.dart';
import 'exchange_rate_storage.dart';

final DateTime forcedBalanceSentinelDate = DateTime.fromMillisecondsSinceEpoch(
  0,
  isUtc: true,
);

class ForcedBalanceMigrationResult {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final bool changed;

  /// Purpose: Create a forced balance migration result instance.
  /// Inputs: `accounts`, `transactions`, `changed`.
  /// Returns: A new `ForcedBalanceMigrationResult` instance.
  /// Side effects: None.
  /// Notes: Use this as the normalized finance payload after one-time migration.
  const ForcedBalanceMigrationResult({
    required this.accounts,
    required this.transactions,
    required this.changed,
  });
}

/// Currency symbols for display.
/// Purpose: Implement the currency symbol behavior for this file.
/// Inputs: `code`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: None.
String currencySymbol(String code) => switch (code) {
  'CNY' => '¥',
  'USD' => '\$',
  'EUR' => '€',
  'GBP' => '£',
  'JPY' => '¥',
  'CAD' => 'C\$',
  'AUD' => 'A\$',
  'TWD' => 'NT\$',
  'HKD' => 'HK\$',
  'SGD' => 'S\$',
  'KRW' => '₩',
  'CHF' => 'Fr',
  'NZD' => 'NZ\$',
  'INR' => '₹',
  _ => code,
};

/// Find a direct or reverse rate between two currencies.
/// Purpose: Provide the internal find rate helper for this file.
/// Inputs: `rates`, `from`, `to`.
/// Returns: `double?`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
double? _findRate(Map<String, double> rates, String from, String to) {
  if (from == to) return 1.0;
  final direct = rates['${from}_$to'];
  if (direct != null) return direct;
  final reverse = rates['${to}_$from'];
  if (reverse != null && reverse != 0) return 1.0 / reverse;
  return null;
}

/// Convert [amount] from [from] currency to [to] currency using [rates].
/// Tries direct, reverse, then via intermediate currencies (CNY, USD, EUR).
/// Purpose: Implement the convert currency behavior for this file.
/// Inputs: `rates`, `amount`, `from`, `to`.
/// Returns: `double`.
/// Side effects: None.
/// Notes: None.
double convertCurrency(
  Map<String, double> rates,
  double amount,
  String from,
  String to,
) {
  if (from == to) return amount;
  // Direct or reverse
  final rate = _findRate(rates, from, to);
  if (rate != null) return amount * rate;
  // Via intermediate
  for (final via in ['CNY', 'USD', 'EUR']) {
    if (via == from || via == to) continue;
    final leg1 = _findRate(rates, from, via);
    final leg2 = _findRate(rates, via, to);
    if (leg1 != null && leg2 != null) return amount * leg1 * leg2;
  }
  return amount; // fallback
}

/// Calculate account balance in the account's own currency.
/// Purpose: Implement the account balance behavior for this file.
/// Inputs: `account`, `transactions`, `rateData`.
/// Returns: `double`.
/// Side effects: None.
/// Notes: Forced-balance fields are migration sentinels only and never affect live balances.
double accountBalance(
  Account account,
  List<Transaction> transactions,
  ExchangeRateData rateData,
) {
  var net = 0.0;
  for (final tx in transactions) {
    net += _accountTransactionDelta(account, tx, rateData);
  }

  return net;
}

/// Calculate account balance immediately before [before].
/// Purpose: Implement the account balance before behavior for this file.
/// Inputs: `account`, `transactions`, `rateData`, `before`.
/// Returns: `double`.
/// Side effects: None.
/// Notes: Forced-balance fields are migration sentinels only and never affect live balances.
double accountBalanceBefore(
  Account account,
  List<Transaction> transactions,
  ExchangeRateData rateData,
  DateTime before,
) {
  var net = 0.0;
  for (final tx in transactions) {
    if (tx.date.isBefore(before)) {
      net += _accountTransactionDelta(account, tx, rateData);
    }
  }

  return net;
}

/// Purpose: Return whether a date is the forced-balance migration sentinel.
/// Inputs: `date`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Accepts both UTC epoch and local 1970-01-01 midnight encodings.
bool isForcedBalanceSentinelDate(DateTime date) {
  if (date.toUtc().millisecondsSinceEpoch == 0) return true;
  return date.year == 1970 &&
      date.month == 1 &&
      date.day == 1 &&
      date.hour == 0 &&
      date.minute == 0 &&
      date.second == 0 &&
      date.millisecond == 0 &&
      date.microsecond == 0;
}

/// Purpose: Return whether an account already uses the forced-balance sentinel.
/// Inputs: `account`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: This means old forced-balance state has already been discarded.
bool hasForcedBalanceSentinel(Account account) =>
    (account.forcedBalance ?? 0) == 0 &&
    account.forcedBalanceDate != null &&
    isForcedBalanceSentinelDate(account.forcedBalanceDate!);

/// Purpose: Return an account with forced-balance fields replaced by the sentinel.
/// Inputs: `account`, `modifiedAt`.
/// Returns: `Account`.
/// Side effects: None.
/// Notes: Use before saving accounts from new-version balance adjustment flows; non-balance metadata is preserved.
Account accountWithForcedBalanceSentinel(
  Account account, {
  DateTime? modifiedAt,
}) {
  return Account(
    id: account.id,
    type: account.type,
    bankOrApp: account.bankOrApp,
    name: account.name,
    currency: account.currency,
    cardNumber: account.cardNumber,
    expiryDate: account.expiryDate,
    securityCode: account.securityCode,
    emoji: account.emoji,
    imagePath: account.imagePath,
    feeWaiverMinimumBalance: account.feeWaiverMinimumBalance,
    feeWaiverMonthlyDeposit: account.feeWaiverMonthlyDeposit,
    forcedBalance: 0,
    forcedBalanceDate: forcedBalanceSentinelDate,
    modifiedAt: modifiedAt ?? account.modifiedAt,
  );
}

/// Purpose: Migrate old forced balances into ordinary adjustment transactions.
/// Inputs: `accounts`, `transactions`, `rateData`, `adjustmentNote`.
/// Returns: `ForcedBalanceMigrationResult`.
/// Side effects: None.
/// Notes: Non-zero forced balances become deterministic income/expense transactions, then accounts are set to the 0 + 1970 sentinel.
ForcedBalanceMigrationResult migrateForcedBalances({
  required List<Account> accounts,
  required List<Transaction> transactions,
  required ExchangeRateData rateData,
  String adjustmentNote = 'Balance Adjustment',
}) {
  final migratedAccounts = <Account>[];
  final migratedTransactions = List<Transaction>.of(transactions);
  final existingTransactionIds = transactions.map((tx) => tx.id).toSet();
  var changed = false;

  for (final account in accounts) {
    final hasForcedBalanceMarker =
        account.forcedBalance != null || account.forcedBalanceDate != null;
    if (!hasForcedBalanceMarker || hasForcedBalanceSentinel(account)) {
      migratedAccounts.add(account);
      continue;
    }

    final forcedBalance = account.forcedBalance ?? 0.0;
    if (forcedBalance != 0) {
      final delta = _forcedBalanceMigrationDelta(
        account,
        transactions,
        rateData,
      );
      final txId = _forcedBalanceMigrationTransactionId(account);
      if (delta.abs() > 0.000001 && !existingTransactionIds.contains(txId)) {
        migratedTransactions.add(
          Transaction(
            id: txId,
            type: delta > 0 ? TransactionType.income : TransactionType.expense,
            amount: delta.abs(),
            currency: account.currency,
            rateSnapshotId: rateData.currentSnapshotId,
            accountId: account.id,
            note: adjustmentNote,
            date: _forcedBalanceAdjustmentDate(account),
          ),
        );
        existingTransactionIds.add(txId);
      }
    }

    migratedAccounts.add(
      accountWithForcedBalanceSentinel(account, modifiedAt: DateTime.now()),
    );
    changed = true;
  }

  return ForcedBalanceMigrationResult(
    accounts: migratedAccounts,
    transactions: migratedTransactions,
    changed: changed,
  );
}

/// Purpose: Provide the internal forced balance migration delta helper for this file.
/// Inputs: `account`, `transactions`, `rateData`.
/// Returns: `double`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
double _forcedBalanceMigrationDelta(
  Account account,
  List<Transaction> transactions,
  ExchangeRateData rateData,
) {
  var delta = account.forcedBalance ?? 0.0;
  final cutoff = account.forcedBalanceDate;
  if (cutoff == null) return delta;

  for (final tx in transactions) {
    if (!tx.date.isAfter(cutoff)) {
      delta -= _accountTransactionDelta(account, tx, rateData);
    }
  }
  return delta;
}

/// Purpose: Provide the internal forced balance migration transaction id helper for this file.
/// Inputs: `account`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
String _forcedBalanceMigrationTransactionId(Account account) {
  final date = account.forcedBalanceDate?.toIso8601String() ?? 'none';
  final modifiedAt = account.modifiedAt.toIso8601String();
  return 'forced-balance-migration:${account.id}:${account.forcedBalance}:$date:$modifiedAt';
}

/// Purpose: Provide the internal forced balance adjustment date helper for this file.
/// Inputs: `account`.
/// Returns: `DateTime`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
DateTime _forcedBalanceAdjustmentDate(Account account) {
  final cutoff = account.forcedBalanceDate;
  if (cutoff != null && !isForcedBalanceSentinelDate(cutoff)) {
    return cutoff;
  }
  if (account.modifiedAt.isAfter(forcedBalanceSentinelDate)) {
    return account.modifiedAt;
  }
  return DateTime.now();
}

/// Purpose: Provide the internal account transaction delta helper for this file.
/// Inputs: `account`, `tx`, `rateData`.
/// Returns: `double`.
/// Side effects: May read or mutate application state, storage, or service resources.
/// Notes: Internal helper used within this file only.
double _accountTransactionDelta(
  Account account,
  Transaction tx,
  ExchangeRateData rateData,
) {
  final rates = rateData.ratesAt(tx.rateSnapshotId);
  final target = account.currency;
  var delta = 0.0;

  if (tx.accountId == account.id) {
    final converted = convertCurrency(rates, tx.amount, tx.currency, target);
    switch (tx.type) {
      case TransactionType.expense:
        delta -= converted;
      case TransactionType.income:
        delta += converted;
      case TransactionType.transfer:
        delta -= converted;
    }
  }

  if (tx.toAccountId == account.id && tx.type == TransactionType.transfer) {
    if (tx.toAmount != null && tx.toCurrency != null) {
      delta += convertCurrency(rates, tx.toAmount!, tx.toCurrency!, target);
    } else {
      delta += convertCurrency(rates, tx.amount, tx.currency, target);
    }
  }

  return delta;
}

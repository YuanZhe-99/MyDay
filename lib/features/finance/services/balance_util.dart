import '../models/finance.dart';
import 'exchange_rate_storage.dart';

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
/// Notes: None.
double accountBalance(
  Account account,
  List<Transaction> transactions,
  ExchangeRateData rateData,
) {
  final base = account.forcedBalance ?? 0.0;
  final cutoff = account.forcedBalanceDate;

  var net = 0.0;
  for (final tx in transactions) {
    if (cutoff != null && !tx.date.isAfter(cutoff)) continue;
    net += _accountTransactionDelta(account, tx, rateData);
  }

  return base + net;
}

/// Calculate account balance immediately before [before].
///
/// If an account has a forced balance, that balance is treated as an anchor at
/// [Account.forcedBalanceDate]. Samples after the anchor walk forward from it;
/// samples before the anchor walk backward by reversing known transactions.
/// Purpose: Implement the account balance before behavior for this file.
/// Inputs: `account`, `transactions`, `rateData`, `before`.
/// Returns: `double`.
/// Side effects: None.
/// Notes: None.
double accountBalanceBefore(
  Account account,
  List<Transaction> transactions,
  ExchangeRateData rateData,
  DateTime before,
) {
  final base = account.forcedBalance ?? 0.0;
  final cutoff = account.forcedBalanceDate;

  var net = 0.0;
  for (final tx in transactions) {
    final delta = _accountTransactionDelta(account, tx, rateData);
    if (delta == 0) continue;

    if (cutoff == null) {
      if (tx.date.isBefore(before)) net += delta;
      continue;
    }

    if (before.isAfter(cutoff)) {
      if (tx.date.isAfter(cutoff) && tx.date.isBefore(before)) {
        net += delta;
      }
    } else {
      if (!tx.date.isBefore(before) && !tx.date.isAfter(cutoff)) {
        net -= delta;
      }
    }
  }

  return base + net;
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

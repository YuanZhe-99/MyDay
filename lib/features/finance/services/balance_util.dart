import '../models/finance.dart';
import 'exchange_rate_storage.dart';

/// Currency symbols for display.
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
double accountBalance(
  Account account,
  List<Transaction> transactions,
  ExchangeRateData rateData,
) {
  final base = account.forcedBalance ?? 0.0;
  final cutoff = account.forcedBalanceDate;
  final target = account.currency;

  var net = 0.0;
  for (final tx in transactions) {
    if (cutoff != null && !tx.date.isAfter(cutoff)) continue;
    final rates = rateData.ratesAt(tx.rateSnapshotId);

    if (tx.accountId == account.id) {
      final converted =
          convertCurrency(rates, tx.amount, tx.currency, target);
      switch (tx.type) {
        case TransactionType.expense:
          net -= converted;
        case TransactionType.income:
          net += converted;
        case TransactionType.transfer:
          net -= converted;
      }
    }
    if (tx.toAccountId == account.id &&
        tx.type == TransactionType.transfer) {
      if (tx.toAmount != null && tx.toCurrency != null) {
        final converted =
            convertCurrency(rates, tx.toAmount!, tx.toCurrency!, target);
        net += converted;
      } else {
        final converted =
            convertCurrency(rates, tx.amount, tx.currency, target);
        net += converted;
      }
    }
  }

  return base + net;
}

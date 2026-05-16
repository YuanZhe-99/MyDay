import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/finance/models/finance.dart';
import 'package:my_day/features/finance/services/balance_util.dart';
import 'package:my_day/features/finance/services/exchange_rate_storage.dart';

/// Purpose: Initialize startup services and launch the app entry point.
/// Inputs: None.
/// Returns: None.
/// Side effects: May create, transform, or mutate data used by callers.
/// Notes: None.
void main() {
  test('accountBalanceBefore walks around forced balance anchor', () {
    final rateData = ExchangeRateData(currentSnapshotId: '', snapshots: {});
    final account = Account(
      type: AccountType.fund,
      bankOrApp: 'Bank',
      name: 'Cash',
      forcedBalance: 1000,
      forcedBalanceDate: DateTime(2026, 1, 10),
    );
    final transactions = [
      Transaction(
        type: TransactionType.income,
        amount: 100,
        accountId: account.id,
        date: DateTime(2026, 1, 8),
      ),
      Transaction(
        type: TransactionType.expense,
        amount: 25,
        accountId: account.id,
        date: DateTime(2026, 1, 12),
      ),
    ];

    expect(
      accountBalanceBefore(
        account,
        transactions,
        rateData,
        DateTime(2026, 1, 7),
      ),
      900,
    );
    expect(
      accountBalanceBefore(
        account,
        transactions,
        rateData,
        DateTime(2026, 1, 9),
      ),
      1000,
    );
    expect(
      accountBalanceBefore(
        account,
        transactions,
        rateData,
        DateTime(2026, 1, 13),
      ),
      975,
    );
  });
}

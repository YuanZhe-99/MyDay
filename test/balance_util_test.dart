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
  test('account balances ignore forced-balance fields', () {
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

    expect(accountBalance(account, transactions, rateData), 75);
    expect(
      accountBalanceBefore(
        account,
        transactions,
        rateData,
        DateTime(2026, 1, 7),
      ),
      0,
    );
    expect(
      accountBalanceBefore(
        account,
        transactions,
        rateData,
        DateTime(2026, 1, 9),
      ),
      100,
    );
    expect(
      accountBalanceBefore(
        account,
        transactions,
        rateData,
        DateTime(2026, 1, 13),
      ),
      75,
    );
  });

  test('migrateForcedBalances creates adjustment and sentinel account', () {
    final rateData = ExchangeRateData(currentSnapshotId: '', snapshots: {});
    final account = Account(
      type: AccountType.fund,
      bankOrApp: 'Bank',
      name: 'Cash',
      forcedBalance: 1000,
      forcedBalanceDate: DateTime(2026, 1, 10),
      modifiedAt: DateTime(2026, 1, 10, 12),
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

    final migrated = migrateForcedBalances(
      accounts: [account],
      transactions: transactions,
      rateData: rateData,
    );

    expect(migrated.changed, isTrue);
    expect(migrated.accounts.single.forcedBalance, 0);
    expect(
      isForcedBalanceSentinelDate(migrated.accounts.single.forcedBalanceDate!),
      isTrue,
    );
    expect(migrated.transactions.length, 3);
    final adjustment = migrated.transactions.last;
    expect(adjustment.type, TransactionType.income);
    expect(adjustment.amount, 900);
    expect(adjustment.date, DateTime(2026, 1, 10));
    expect(
      accountBalance(migrated.accounts.single, migrated.transactions, rateData),
      975,
    );

    final repeated = migrateForcedBalances(
      accounts: migrated.accounts,
      transactions: migrated.transactions,
      rateData: rateData,
    );
    expect(repeated.changed, isFalse);
    expect(repeated.transactions.length, 3);
  });

  test('zero forced balance is normalized without an adjustment', () {
    final rateData = ExchangeRateData(currentSnapshotId: '', snapshots: {});
    final account = Account(
      type: AccountType.fund,
      bankOrApp: 'Bank',
      name: 'Cash',
      forcedBalance: 0,
      forcedBalanceDate: DateTime(2026, 1, 10),
    );

    final migrated = migrateForcedBalances(
      accounts: [account],
      transactions: const [],
      rateData: rateData,
    );

    expect(migrated.changed, isTrue);
    expect(migrated.transactions, isEmpty);
    expect(
      isForcedBalanceSentinelDate(migrated.accounts.single.forcedBalanceDate!),
      isTrue,
    );
  });
}

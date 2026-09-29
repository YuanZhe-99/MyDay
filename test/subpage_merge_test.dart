import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:my_day/features/finance/models/finance.dart';
import 'package:my_day/features/finance/services/finance_storage.dart';
import 'package:my_day/features/intimacy/models/intimacy_record.dart';
import 'package:my_day/features/intimacy/services/intimacy_storage.dart';
import 'package:my_day/shared/utils/id_list_delta.dart';

/// Purpose: Pin the v1.5.2 merge-by-id sub-page save against real data files.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: Mirrors `_commitSubPage` on the finance and intimacy pages: baseline at
/// open, another writer changes the file, the sub-page reports its stale list, and
/// the delta is replayed onto a fresh load.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('my_day_subpage_merge_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('a renewal written while the accounts page is open survives', () async {
    final account = Account(
      id: 'acc',
      type: AccountType.fund,
      bankOrApp: 'Bank',
      name: 'Wallet',
    );
    final tx = Transaction(
      id: 'tx-1',
      type: TransactionType.expense,
      amount: 5,
      accountId: 'acc',
    );
    await FinanceStorage.save(
      FinanceData(accounts: [account], categories: [], transactions: [tx]),
    );

    // Sub-page opens with the page's lists.
    final opened = (await FinanceStorage.load())!;
    final accounts = IdListBaseline<Account>(opened.accounts, (a) => a.id);
    final transactions = IdListBaseline<Transaction>(
      opened.transactions,
      (t) => t.id,
    );
    final subPageTx = List.of(opened.transactions);

    // ReminderService renews a subscription meanwhile.
    final renewal = Transaction(
      id: 'renewal-R',
      type: TransactionType.expense,
      amount: 9,
      accountId: 'acc',
      subscriptionId: 'sub',
    );
    final onDisk = (await FinanceStorage.load())!;
    await FinanceStorage.save(
      onDisk.copyWith(transactions: [...onDisk.transactions, renewal]),
    );

    // The sub-page adds a balance adjustment and renames the account.
    subPageTx.insert(
      0,
      Transaction(
        id: 'adjust',
        type: TransactionType.income,
        amount: 1,
        accountId: 'acc',
      ),
    );
    final renamed = [
      Account(
        id: 'acc',
        type: AccountType.fund,
        bankOrApp: 'Bank',
        name: 'Renamed',
      ),
    ];
    for (final commit in [
      (FinanceData f) => f.copyWith(
        transactions: transactions.take(subPageTx).applyTo(f.transactions),
      ),
      (FinanceData f) =>
          f.copyWith(accounts: accounts.take(renamed).applyTo(f.accounts)),
    ]) {
      final fresh = (await FinanceStorage.load())!;
      await FinanceStorage.save(commit(fresh));
    }

    final result = (await FinanceStorage.load())!;
    expect(result.transactions.map((t) => t.id), [
      'adjust',
      'tx-1',
      'renewal-R',
    ]);
    expect(result.accounts.single.name, 'Renamed');
  });

  test('records added elsewhere survive a partner rename', () async {
    final partner = Partner(id: 'p1', name: 'Alex');
    await IntimacyStorage.save(
      IntimacyData(partners: [partner], toys: [], records: []),
    );

    final opened = (await IntimacyStorage.load())!;
    final partners = IdListBaseline<Partner>(opened.partners, (p) => p.id);

    // A record is added (timer page, sync) while the partner page is open.
    final onDisk = (await IntimacyStorage.load())!;
    final record = IntimacyRecord(
      id: 'r1',
      type: 'Regular',
      partnerId: 'p1',
      pleasureLevel: 4,
      duration: const Duration(minutes: 10),
    );
    await IntimacyStorage.save(onDisk.copyWith(records: [record]));

    final edited = [opened.partners.single.copyWith(name: 'Sam')];
    final fresh = (await IntimacyStorage.load())!;
    await IntimacyStorage.save(
      fresh.copyWith(partners: partners.take(edited).applyTo(fresh.partners)),
    );

    final result = (await IntimacyStorage.load())!;
    expect(result.partners.single.name, 'Sam');
    expect(result.records.map((r) => r.id), ['r1']);
    expect(result.settingsModifiedAt, opened.settingsModifiedAt);
  });
}

class _FakePathProvider extends PathProviderPlatform {
  final String documentsPath;

  /// Purpose: Create a fake path provider for tests.
  /// Inputs: `documentsPath`.
  /// Returns: A new `_FakePathProvider` instance.
  /// Side effects: None.
  /// Notes: Only the application documents path is needed here.
  _FakePathProvider(this.documentsPath);

  /// Purpose: Return the fake application documents directory.
  /// Inputs: None.
  /// Returns: `Future<String?>`.
  /// Side effects: None.
  /// Notes: None.
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

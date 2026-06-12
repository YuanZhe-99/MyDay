import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/finance/models/finance.dart';
import 'package:my_day/features/finance/services/exchange_rate_storage.dart';
import 'package:my_day/features/finance/services/finance_storage.dart';
import 'package:my_day/features/todo/models/task.dart';
import 'package:my_day/features/todo/services/todo_storage.dart';
import 'package:my_day/features/weight/models/weight_record.dart';
import 'package:my_day/shared/services/sync_merge.dart';

/// Purpose: Register regression tests for the 2026-06-12 pre-release audit fixes.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: This serves as the test entry point for the file.
void main() {
  group('subscription billing dates (month-end clamping)', () {
    test('monthly day-31 anchor clamps and never skips months', () {
      final sub = Subscription(
        id: 's1',
        name: 'Cloud',
        startDate: DateTime(2026, 1, 31),
        billingCycleType: BillingCycleType.monthly,
        amount: 10,
        accountId: 'a1',
        modifiedAt: DateTime.utc(2026, 1, 1),
      );

      final dates = sub.billingDatesBefore(DateTime(2026, 6, 30));
      expect(dates, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
        DateTime(2026, 5, 31),
        DateTime(2026, 6, 30),
      ]);

      expect(
        sub.calculateNextBillingDate(after: DateTime(2026, 2, 1)),
        DateTime(2026, 2, 28),
      );
    });

    test('yearly Feb-29 anchor clamps in non-leap years', () {
      final sub = Subscription(
        id: 's2',
        name: 'Annual',
        startDate: DateTime(2024, 2, 29),
        billingCycleType: BillingCycleType.yearly,
        amount: 100,
        accountId: 'a1',
        modifiedAt: DateTime.utc(2024, 1, 1),
      );

      expect(
        sub.calculateNextBillingDate(after: DateTime(2024, 3, 1)),
        DateTime(2025, 2, 28),
      );
    });
  });

  group('cross-module conflict resolution', () {
    String todoJson(String title, DateTime modifiedAt) => jsonEncode(
      TodoData(
        dailyTemplates: const [],
        oneTimeTasks: [
          Task(
            id: 't1',
            title: title,
            type: TaskType.workOnce,
            modifiedAt: modifiedAt,
          ),
        ],
        dailyLog: DailyCompletionLog(),
      ).toJson(),
    );

    String financeJson(String name, DateTime modifiedAt) => jsonEncode(
      FinanceData(
        accounts: [
          Account(
            id: 'a1',
            type: AccountType.fund,
            bankOrApp: 'Bank',
            name: name,
            modifiedAt: modifiedAt,
          ),
        ],
        categories: const [],
        transactions: const [],
      ).toJson(),
    );

    final t0 = DateTime.utc(2026, 6, 1);
    final t1 = DateTime.utc(2026, 6, 2);
    final t2 = DateTime.utc(2026, 6, 3);

    test('mixed-type resolutions map applies per type without crashing', () {
      final todoResult = mergeTodoData(
        todoJson('Local title', t1),
        todoJson('Remote title', t2),
        todoJson('Base title', t0),
      );
      expect(todoResult.hasConflicts, isTrue);

      final financeResult = mergeFinanceData(
        financeJson('Local name', t1),
        financeJson('Remote name', t2),
        financeJson('Base name', t0),
      );
      expect(financeResult.hasConflicts, isTrue);

      // One shared map holding both a Task and an Account, exactly as
      // finalizePendingSync passes it. This used to throw a cast error.
      final resolutions = <String, dynamic>{
        't1': todoResult.onceConflicts.single.remoteRecord,
        'a1': financeResult.accountConflicts.single.remoteRecord,
      };

      final todoData = todoResult.buildResolved(resolutions);
      expect(todoData.oneTimeTasks.single.title, 'Remote title');

      final financeData = financeResult.buildResolved(resolutions);
      expect(financeData.accounts.single.name, 'Remote name');
    });

    test('unresolved conflicts default to the local record', () {
      final todoResult = mergeTodoData(
        todoJson('Local title', t1),
        todoJson('Remote title', t2),
        todoJson('Base title', t0),
      );
      expect(todoResult.hasConflicts, isTrue);

      final todoData = todoResult.buildResolved(const {});
      expect(todoData.oneTimeTasks.single.title, 'Local title');
    });

    test('identical concurrent edits merge without a conflict', () {
      final result = mergeFinanceData(
        financeJson('Same new name', t1),
        financeJson('Same new name', t1),
        financeJson('Base name', t0),
      );
      expect(result.hasConflicts, isFalse);
      expect(result.accountsMerged.single.name, 'Same new name');
    });
  });

  test('exchange-rate merge never keeps a dangling current snapshot id', () {
    final remoteSnapshot = RateSnapshot(
      id: 'r1',
      rates: const {'USD_JPY': 150.0},
      createdAt: DateTime.utc(2026, 6, 1),
    );
    final local = ExchangeRateData(
      currentSnapshotId: 'missing',
      snapshots: const {},
    );
    final remote = ExchangeRateData(
      currentSnapshotId: 'r1',
      snapshots: {'r1': remoteSnapshot},
    );

    final merged = ExchangeRateData.fromJson(
      jsonDecode(
            mergeExchangeRateJson(
              jsonEncode(local.toJson()),
              jsonEncode(remote.toJson()),
            ),
          )
          as Map<String, dynamic>,
    );

    expect(merged.currentSnapshotId, 'r1');
    expect(merged.snapshots.containsKey('r1'), isTrue);
  });

  test('weight height follows settings LWW so clearing height syncs', () {
    String weightJson(double? height, DateTime settingsModifiedAt) =>
        jsonEncode(
          WeightData(
            height: height,
            records: const [],
            settingsModifiedAt: settingsModifiedAt,
          ).toJson(),
        );

    // Local cleared the height more recently than remote set it.
    final result = mergeWeightData(
      weightJson(null, DateTime.utc(2026, 6, 3)),
      weightJson(170, DateTime.utc(2026, 6, 1)),
      null,
    );
    expect(result.height, isNull);

    // And the newer non-null side wins symmetrically.
    final result2 = mergeWeightData(
      weightJson(165, DateTime.utc(2026, 6, 1)),
      weightJson(171, DateTime.utc(2026, 6, 3)),
      null,
    );
    expect(result2.height, 171);
  });

  test('new record timestamps default to UTC for cross-timezone LWW', () {
    expect(Task(title: 'x', type: TaskType.workOnce).modifiedAt.isUtc, isTrue);
    expect(
      Account(
        type: AccountType.fund,
        bankOrApp: 'Bank',
        name: 'A',
      ).modifiedAt.isUtc,
      isTrue,
    );
    expect(WeightRecord(weight: 60).modifiedAt.isUtc, isTrue);
    expect(
      Subscription(
        name: 'S',
        startDate: DateTime(2026, 1, 1),
        billingCycleType: BillingCycleType.monthly,
        amount: 1,
        accountId: 'a',
      ).modifiedAt.isUtc,
      isTrue,
    );
  });
}

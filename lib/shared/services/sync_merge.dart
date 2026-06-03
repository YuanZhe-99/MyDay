import 'dart:convert';

import '../../features/finance/models/finance.dart';
import '../../features/finance/services/exchange_rate_storage.dart';
import '../../features/finance/services/finance_storage.dart';
import '../../features/intimacy/models/intimacy_record.dart';
import '../../features/weight/models/weight_record.dart';
import '../../features/todo/models/task.dart';
import '../../features/todo/services/todo_storage.dart';

// ─── Generic record merge ───────────────────────────────────────────

/// A single record-level conflict: same ID, both sides changed.
class RecordConflict<T> {
  final String id;
  final T localRecord;
  final T remoteRecord;
  final String displayName;

  /// Purpose: Create a record conflict instance.
  /// Inputs: `id`, `localRecord`, `remoteRecord`, `displayName`.
  /// Returns: A new `RecordConflict` instance.
  /// Side effects: None.
  /// Notes: None.
  const RecordConflict({
    required this.id,
    required this.localRecord,
    required this.remoteRecord,
    required this.displayName,
  });
}

/// Result of merging a list of records.
class RecordMergeResult<T> {
  final List<T> merged;
  final List<RecordConflict<T>> conflicts;

  /// Purpose: Create a record merge result instance.
  /// Inputs: `conflicts`.
  /// Returns: A new `RecordMergeResult` instance.
  /// Side effects: None.
  /// Notes: None.
  const RecordMergeResult({required this.merged, this.conflicts = const []});
}

/// Purpose: Merge records into a single result.
/// Inputs: `autoResolve`.
/// Returns: `RecordMergeResult<T>`.
/// Side effects: May read or mutate application state, storage, or service resources.
/// Notes: None.
/// Three-way merge for a list of records by ID.
///
/// Uses [base] (last synced version) to detect which side changed:
/// - Only local changed → use local
/// - Only remote changed → use remote
/// - Both changed → conflict (or LWW when [autoResolve] is true)
/// - Neither changed → use either
/// - New record on one side only → include it
/// - Record deleted on one side, unchanged on other → exclude
/// - Record deleted on one side, modified on other → keep the modification
///
/// When [autoResolve] is true, conflicts are resolved automatically using
/// last-writer-wins (newer `modifiedAt`). This is used by auto-sync to
/// prevent one conflict from blocking all other records in the same file.
/// Purpose: Merge records from the relevant sources.
/// Inputs: `local`, `remote`, `base`, `getId`, `getModifiedAt`, `getDisplayName`, `autoResolve`.
/// Returns: `RecordMergeResult<T>`.
/// Side effects: May create, transform, or mutate data used by callers.
/// Notes: None.
RecordMergeResult<T> mergeRecords<T>({
  required List<T> local,
  required List<T> remote,
  required List<T>? base,
  required String Function(T) getId,
  required DateTime Function(T) getModifiedAt,
  required String Function(T) getDisplayName,
  bool autoResolve = false,
}) {
  final localMap = {for (final r in local) getId(r): r};
  final remoteMap = {for (final r in remote) getId(r): r};
  final baseMap = base != null
      ? {for (final r in base) getId(r): r}
      : <String, T>{};

  final allIds = {...localMap.keys, ...remoteMap.keys, ...baseMap.keys};
  final merged = <T>[];
  final conflicts = <RecordConflict<T>>[];

  for (final id in allIds) {
    final l = localMap[id];
    final r = remoteMap[id];
    final b = baseMap[id];

    if (l != null && r != null) {
      // Both sides have the record
      if (b != null) {
        // Three-way: check who changed from base
        final localChanged = getModifiedAt(l).isAfter(getModifiedAt(b));
        final remoteChanged = getModifiedAt(r).isAfter(getModifiedAt(b));

        if (localChanged && remoteChanged) {
          if (autoResolve) {
            // LWW: pick the record with the newer modifiedAt
            merged.add(getModifiedAt(l).isAfter(getModifiedAt(r)) ? l : r);
          } else {
            // Both changed → conflict for user resolution
            conflicts.add(
              RecordConflict(
                id: id,
                localRecord: l,
                remoteRecord: r,
                displayName: getDisplayName(l),
              ),
            );
          }
        } else if (localChanged) {
          merged.add(l);
        } else if (remoteChanged) {
          merged.add(r);
        } else {
          merged.add(l); // neither changed, use local
        }
      } else {
        // No base — first sync or both added same ID
        // Use newer modifiedAt (LWW)
        merged.add(getModifiedAt(l).isAfter(getModifiedAt(r)) ? l : r);
      }
    } else if (l != null && r == null) {
      if (b != null) {
        // Was in base, now missing from remote → deleted remotely
        final localChanged = getModifiedAt(l).isAfter(getModifiedAt(b));
        if (localChanged) {
          merged.add(l); // Modified locally after remote deleted → keep
        }
        // else: not modified locally, remote deleted → exclude
      } else {
        merged.add(l); // New locally → include
      }
    } else if (l == null && r != null) {
      if (b != null) {
        // Was in base, now missing from local → deleted locally
        final remoteChanged = getModifiedAt(r).isAfter(getModifiedAt(b));
        if (remoteChanged) {
          merged.add(r); // Modified remotely after local deleted → keep
        }
        // else: not modified remotely, local deleted → exclude
      } else {
        merged.add(r); // New remotely → include
      }
    }
    // else: l == null && r == null && b != null → deleted both sides → exclude
  }

  return RecordMergeResult(merged: merged, conflicts: conflicts);
}

// ─── Data-level merge functions ─────────────────────────────────────

/// Aggregate conflict info for display.
class SyncConflictInfo {
  final String fileName;
  final String displayName;
  final List<RecordConflict> recordConflicts;

  /// Purpose: Create a sync conflict info instance.
  /// Inputs: None.
  /// Returns: A new `SyncConflictInfo` instance.
  /// Side effects: None.
  /// Notes: None.
  const SyncConflictInfo({
    required this.fileName,
    required this.displayName,
    required this.recordConflicts,
  });
}

/// Result from the merge of all data files.
class MergeResult {
  /// Merged JSON strings, ready to save. Key = file name.
  final Map<String, String> mergedJsons;

  /// Per-file conflict lists. Empty if no conflicts.
  final List<SyncConflictInfo> conflicts;

  /// Purpose: Create a merge result instance.
  /// Inputs: `conflicts`.
  /// Returns: A new `MergeResult` instance.
  /// Side effects: None.
  /// Notes: None.
  const MergeResult({required this.mergedJsons, this.conflicts = const []});

  /// Purpose: Return whether conflicts is available.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get hasConflicts => conflicts.any((c) => c.recordConflicts.isNotEmpty);
}

// ─── TodoData merge ─────────────────────────────────────────────────

/// Purpose: Merge todo json into a single result.
/// Inputs: `localJson`, `remoteJson`, `baseJson`.
/// Returns: `String?`.
/// Side effects: May read or mutate application state, storage, or service resources.
/// Notes: None.
String? mergeTodoJson(String localJson, String remoteJson, String? baseJson) {
  try {
    final local = TodoData.fromJson(
      jsonDecode(localJson) as Map<String, dynamic>,
    );
    final remote = TodoData.fromJson(
      jsonDecode(remoteJson) as Map<String, dynamic>,
    );
    final base = baseJson != null
        ? TodoData.fromJson(jsonDecode(baseJson) as Map<String, dynamic>)
        : null;

    final dailyResult = mergeRecords<Task>(
      local: local.dailyTemplates,
      remote: remote.dailyTemplates,
      base: base?.dailyTemplates,
      getId: (t) => t.id,
      getModifiedAt: (t) => t.modifiedAt,
      getDisplayName: (t) => '${t.emoji ?? ''} ${t.title}'.trim(),
    );

    final onceResult = mergeRecords<Task>(
      local: local.oneTimeTasks,
      remote: remote.oneTimeTasks,
      base: base?.oneTimeTasks,
      getId: (t) => t.id,
      getModifiedAt: (t) => t.modifiedAt,
      getDisplayName: (t) => '${t.emoji ?? ''} ${t.title}'.trim(),
    );

    final mergedLog = DailyCompletionLog.merge(local.dailyLog, remote.dailyLog);
    final mergedScores = DailyScoreLog.merge(
      local.dailyScores,
      remote.dailyScores,
    );

    // Settings: use more recently modified side
    final useLocalSettings =
        local.settingsModifiedAt.isAfter(remote.settingsModifiedAt) ||
        local.settingsModifiedAt == remote.settingsModifiedAt;

    final settingsSource = useLocalSettings ? local : remote;

    // If there are conflicts, return null (caller handles)
    if (dailyResult.conflicts.isNotEmpty || onceResult.conflicts.isNotEmpty) {
      return null; // Conflicts detected — handled by caller
    }

    final merged = TodoData(
      dailyTemplates: dailyResult.merged,
      oneTimeTasks: onceResult.merged,
      dailyLog: mergedLog,
      dailyScores: mergedScores,
      morningReminderHour: settingsSource.morningReminderHour,
      morningReminderMinute: settingsSource.morningReminderMinute,
      completionReminderHour: settingsSource.completionReminderHour,
      completionReminderMinute: settingsSource.completionReminderMinute,
      taskSortModes: settingsSource.taskSortModes,
      taskCustomOrders: settingsSource.taskCustomOrders,
      settingsModifiedAt: settingsSource.settingsModifiedAt,
    );

    return jsonEncode(merged.toJson());
  } catch (_) {
    return null;
  }
}

/// Full merge returning conflicts for UI resolution.
/// Purpose: Merge todo data into a single result.
/// Inputs: `localJson`, `remoteJson`, `baseJson`, `autoResolve`.
/// Returns: `TodoMergeResult`.
/// Side effects: May create, transform, or mutate data used by callers.
/// Notes: None.
TodoMergeResult mergeTodoData(
  String localJson,
  String remoteJson,
  String? baseJson, {
  bool autoResolve = false,
}) {
  final local = TodoData.fromJson(
    jsonDecode(localJson) as Map<String, dynamic>,
  );
  final remote = TodoData.fromJson(
    jsonDecode(remoteJson) as Map<String, dynamic>,
  );
  final base = baseJson != null
      ? TodoData.fromJson(jsonDecode(baseJson) as Map<String, dynamic>)
      : null;

  final dailyResult = mergeRecords<Task>(
    local: local.dailyTemplates,
    remote: remote.dailyTemplates,
    base: base?.dailyTemplates,
    getId: (t) => t.id,
    getModifiedAt: (t) => t.modifiedAt,
    getDisplayName: (t) => '${t.emoji ?? ''} ${t.title}'.trim(),
    autoResolve: autoResolve,
  );

  final onceResult = mergeRecords<Task>(
    local: local.oneTimeTasks,
    remote: remote.oneTimeTasks,
    base: base?.oneTimeTasks,
    getId: (t) => t.id,
    getModifiedAt: (t) => t.modifiedAt,
    getDisplayName: (t) => '${t.emoji ?? ''} ${t.title}'.trim(),
    autoResolve: autoResolve,
  );

  final mergedLog = DailyCompletionLog.merge(local.dailyLog, remote.dailyLog);
  final mergedScores = DailyScoreLog.merge(
    local.dailyScores,
    remote.dailyScores,
  );

  final useLocalSettings =
      local.settingsModifiedAt.isAfter(remote.settingsModifiedAt) ||
      local.settingsModifiedAt == remote.settingsModifiedAt;
  final settingsSource = useLocalSettings ? local : remote;

  return TodoMergeResult(
    dailyMerged: dailyResult.merged,
    onceMerged: onceResult.merged,
    mergedLog: mergedLog,
    mergedScores: mergedScores,
    settingsSource: settingsSource,
    dailyConflicts: dailyResult.conflicts,
    onceConflicts: onceResult.conflicts,
  );
}

class TodoMergeResult {
  final List<Task> dailyMerged;
  final List<Task> onceMerged;
  final DailyCompletionLog mergedLog;
  final DailyScoreLog mergedScores;
  final TodoData settingsSource;
  final List<RecordConflict<Task>> dailyConflicts;
  final List<RecordConflict<Task>> onceConflicts;

  /// Purpose: Create a todo merge result instance.
  /// Inputs: merged records, logs, settings source, and unresolved conflicts.
  /// Returns: A new `TodoMergeResult` instance.
  /// Side effects: None.
  /// Notes: None.
  const TodoMergeResult({
    required this.dailyMerged,
    required this.onceMerged,
    required this.mergedLog,
    required this.mergedScores,
    required this.settingsSource,
    required this.dailyConflicts,
    required this.onceConflicts,
  });

  /// Purpose: Return whether conflicts is available.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get hasConflicts =>
      dailyConflicts.isNotEmpty || onceConflicts.isNotEmpty;

  /// Purpose: Implement the build resolved behavior for this file.
  /// Inputs: `resolutions`.
  /// Returns: `TodoData`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  TodoData buildResolved(Map<String, Task> resolutions) {
    final daily = _resolveList(dailyMerged, dailyConflicts, resolutions);
    final once = _resolveList(onceMerged, onceConflicts, resolutions);
    return TodoData(
      dailyTemplates: daily,
      oneTimeTasks: once,
      dailyLog: mergedLog,
      dailyScores: mergedScores,
      morningReminderHour: settingsSource.morningReminderHour,
      morningReminderMinute: settingsSource.morningReminderMinute,
      completionReminderHour: settingsSource.completionReminderHour,
      completionReminderMinute: settingsSource.completionReminderMinute,
      taskSortModes: settingsSource.taskSortModes,
      taskCustomOrders: settingsSource.taskCustomOrders,
      settingsModifiedAt: settingsSource.settingsModifiedAt,
    );
  }

  /// Purpose: Provide the internal resolve list helper for this file.
  /// Inputs: `merged`, `conflicts`, `resolutions`.
  /// Returns: `List<T>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static List<T> _resolveList<T>(
    List<T> merged,
    List<RecordConflict<T>> conflicts,
    Map<String, T> resolutions,
  ) {
    final result = [...merged];
    for (final c in conflicts) {
      final resolved = resolutions[c.id];
      if (resolved != null) result.add(resolved);
    }
    return result;
  }
}

// ─── FinanceData merge ──────────────────────────────────────────────

/// Purpose: Merge finance data into a single result.
/// Inputs: `localJson`, `remoteJson`, `baseJson`, `autoResolve`.
/// Returns: `FinanceMergeResult`.
/// Side effects: May read or mutate application state, storage, or service resources.
/// Notes: None.
FinanceMergeResult mergeFinanceData(
  String localJson,
  String remoteJson,
  String? baseJson, {
  bool autoResolve = false,
}) {
  final local = FinanceData.fromJson(
    jsonDecode(localJson) as Map<String, dynamic>,
  );
  final remote = FinanceData.fromJson(
    jsonDecode(remoteJson) as Map<String, dynamic>,
  );
  final base = baseJson != null
      ? FinanceData.fromJson(jsonDecode(baseJson) as Map<String, dynamic>)
      : null;

  final accountResult = mergeRecords<Account>(
    local: local.accounts,
    remote: remote.accounts,
    base: base?.accounts,
    getId: (a) => a.id,
    getModifiedAt: (a) => a.modifiedAt,
    getDisplayName: (a) => '${a.emoji ?? ''} ${a.name}'.trim(),
    autoResolve: autoResolve,
  );

  final categoryResult = mergeRecords<Category>(
    local: local.categories,
    remote: remote.categories,
    base: base?.categories,
    getId: (c) => c.id,
    getModifiedAt: (c) => c.modifiedAt,
    getDisplayName: (c) => '${c.emoji ?? ''} ${c.name}'.trim(),
    autoResolve: autoResolve,
  );

  final txResult = mergeRecords<Transaction>(
    local: local.transactions,
    remote: remote.transactions,
    base: base?.transactions,
    getId: (t) => t.id,
    getModifiedAt: (t) => t.modifiedAt,
    getDisplayName: (t) =>
        '${t.note.isNotEmpty ? t.note : t.type.name} (${t.amount})',
    autoResolve: autoResolve,
  );

  final subResult = mergeRecords<Subscription>(
    local: local.subscriptions,
    remote: remote.subscriptions,
    base: base?.subscriptions,
    getId: (s) => s.id,
    getModifiedAt: (s) => s.modifiedAt,
    getDisplayName: (s) => '${s.emoji ?? ''} ${s.name}'.trim(),
    autoResolve: autoResolve,
  );

  final useLocalSettings =
      local.settingsModifiedAt.isAfter(remote.settingsModifiedAt) ||
      local.settingsModifiedAt == remote.settingsModifiedAt;
  final settingsSource = useLocalSettings ? local : remote;

  return FinanceMergeResult(
    accountsMerged: accountResult.merged,
    categoriesMerged: categoryResult.merged,
    transactionsMerged: txResult.merged,
    subscriptionsMerged: subResult.merged,
    settingsSource: settingsSource,
    accountConflicts: accountResult.conflicts,
    categoryConflicts: categoryResult.conflicts,
    transactionConflicts: txResult.conflicts,
    subscriptionConflicts: subResult.conflicts,
  );
}

class FinanceMergeResult {
  final List<Account> accountsMerged;
  final List<Category> categoriesMerged;
  final List<Transaction> transactionsMerged;
  final List<Subscription> subscriptionsMerged;
  final FinanceData settingsSource;
  final List<RecordConflict<Account>> accountConflicts;
  final List<RecordConflict<Category>> categoryConflicts;
  final List<RecordConflict<Transaction>> transactionConflicts;
  final List<RecordConflict<Subscription>> subscriptionConflicts;

  /// Purpose: Create a finance merge result instance.
  /// Inputs: None.
  /// Returns: A new `FinanceMergeResult` instance.
  /// Side effects: None.
  /// Notes: None.
  const FinanceMergeResult({
    required this.accountsMerged,
    required this.categoriesMerged,
    required this.transactionsMerged,
    required this.subscriptionsMerged,
    required this.settingsSource,
    required this.accountConflicts,
    required this.categoryConflicts,
    required this.transactionConflicts,
    required this.subscriptionConflicts,
  });

  /// Purpose: Return whether conflicts is available.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get hasConflicts =>
      accountConflicts.isNotEmpty ||
      categoryConflicts.isNotEmpty ||
      transactionConflicts.isNotEmpty ||
      subscriptionConflicts.isNotEmpty;

  /// Purpose: Implement the build resolved behavior for this file.
  /// Inputs: `resolutions`.
  /// Returns: `FinanceData`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  FinanceData buildResolved(Map<String, dynamic> resolutions) {
    return FinanceData(
      accounts: _resolveList(accountsMerged, accountConflicts, resolutions),
      categories: _resolveList(
        categoriesMerged,
        categoryConflicts,
        resolutions,
      ),
      transactions: _resolveList(
        transactionsMerged,
        transactionConflicts,
        resolutions,
      ),
      subscriptions: _resolveList(
        subscriptionsMerged,
        subscriptionConflicts,
        resolutions,
      ),
      defaultCurrency: settingsSource.defaultCurrency,
      settingsModifiedAt: settingsSource.settingsModifiedAt,
      subscriptionReminderHour: settingsSource.subscriptionReminderHour,
      subscriptionReminderMinute: settingsSource.subscriptionReminderMinute,
      subscriptionSortMode: settingsSource.subscriptionSortMode,
      subscriptionCustomOrder: settingsSource.subscriptionCustomOrder,
      accountSortModes: settingsSource.accountSortModes,
      accountCustomOrders: settingsSource.accountCustomOrders,
      accountPickerSettings: settingsSource.accountPickerSettings,
    );
  }

  /// Purpose: Provide the internal resolve list helper for this file.
  /// Inputs: `merged`, `conflicts`, `resolutions`.
  /// Returns: `List<T>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static List<T> _resolveList<T>(
    List<T> merged,
    List<RecordConflict<T>> conflicts,
    Map<String, dynamic> resolutions,
  ) {
    final result = [...merged];
    for (final c in conflicts) {
      final resolved = resolutions[c.id];
      if (resolved != null) result.add(resolved as T);
    }
    return result;
  }
}

// ─── IntimacyData merge ─────────────────────────────────────────────

/// Purpose: Merge intimacy data into a single result.
/// Inputs: `localJson`, `remoteJson`, `baseJson`, `autoResolve`.
/// Returns: `IntimacyMergeResult`.
/// Side effects: May read or mutate application state, storage, or service resources.
/// Notes: None.
IntimacyMergeResult mergeIntimacyData(
  String localJson,
  String remoteJson,
  String? baseJson, {
  bool autoResolve = false,
}) {
  final local = IntimacyData.fromJson(
    jsonDecode(localJson) as Map<String, dynamic>,
  );
  final remote = IntimacyData.fromJson(
    jsonDecode(remoteJson) as Map<String, dynamic>,
  );
  final base = baseJson != null
      ? IntimacyData.fromJson(jsonDecode(baseJson) as Map<String, dynamic>)
      : null;

  final partnerResult = mergeRecords<Partner>(
    local: local.partners,
    remote: remote.partners,
    base: base?.partners,
    getId: (p) => p.id,
    getModifiedAt: (p) => p.modifiedAt,
    getDisplayName: (p) => '${p.emoji ?? ''} ${p.name}'.trim(),
    autoResolve: autoResolve,
  );

  final toyResult = mergeRecords<Toy>(
    local: local.toys,
    remote: remote.toys,
    base: base?.toys,
    getId: (t) => t.id,
    getModifiedAt: (t) => t.modifiedAt,
    getDisplayName: (t) => '${t.emoji ?? ''} ${t.name}'.trim(),
    autoResolve: autoResolve,
  );

  final positionResult = mergeRecords<Position>(
    local: local.positions,
    remote: remote.positions,
    base: base?.positions,
    getId: (p) => p.id,
    getModifiedAt: (p) => p.modifiedAt,
    getDisplayName: (p) => '${p.emoji ?? ''} ${p.name}'.trim(),
    autoResolve: autoResolve,
  );

  final recordResult = mergeRecords<IntimacyRecord>(
    local: local.records,
    remote: remote.records,
    base: base?.records,
    getId: (r) => r.id,
    getModifiedAt: (r) => r.modifiedAt,
    getDisplayName: (r) =>
        '${r.type} (${r.datetime.toIso8601String().substring(0, 10)})',
    autoResolve: autoResolve,
  );

  // Timer history: union by start time (simple dedup, no conflicts)
  final localStarts = local.timerHistory
      .map((e) => e.start.toIso8601String())
      .toSet();
  final mergedTimerHistory = [
    ...local.timerHistory,
    ...remote.timerHistory.where(
      (e) => !localStarts.contains(e.start.toIso8601String()),
    ),
  ];

  // Timer session: use the side with the newer session timestamp.
  final useLocalTimerSession =
      local.timerSessionModifiedAt.isAfter(remote.timerSessionModifiedAt) ||
      local.timerSessionModifiedAt == remote.timerSessionModifiedAt;

  // Settings: use the side with newer settingsModifiedAt
  final useLocalSettings =
      local.settingsModifiedAt.isAfter(remote.settingsModifiedAt) ||
      local.settingsModifiedAt == remote.settingsModifiedAt;

  return IntimacyMergeResult(
    partnersMerged: partnerResult.merged,
    toysMerged: toyResult.merged,
    positionsMerged: positionResult.merged,
    recordsMerged: recordResult.merged,
    timerHistoryMerged: mergedTimerHistory,
    timerHistoryRetentionDays: useLocalSettings
        ? local.timerHistoryRetentionDays
        : remote.timerHistoryRetentionDays,
    partnerSortModes: useLocalSettings
        ? local.partnerSortModes
        : remote.partnerSortModes,
    partnerCustomOrders: useLocalSettings
        ? local.partnerCustomOrders
        : remote.partnerCustomOrders,
    toySortModes: useLocalSettings ? local.toySortModes : remote.toySortModes,
    toyCustomOrders: useLocalSettings
        ? local.toyCustomOrders
        : remote.toyCustomOrders,
    settingsModifiedAt: useLocalSettings
        ? local.settingsModifiedAt
        : remote.settingsModifiedAt,
    partnerConflicts: partnerResult.conflicts,
    toyConflicts: toyResult.conflicts,
    positionConflicts: positionResult.conflicts,
    recordConflicts: recordResult.conflicts,
    timerSession: useLocalTimerSession
        ? local.timerSession
        : remote.timerSession,
    timerSessionModifiedAt: useLocalTimerSession
        ? local.timerSessionModifiedAt
        : remote.timerSessionModifiedAt,
  );
}

class IntimacyMergeResult {
  final List<Partner> partnersMerged;
  final List<Toy> toysMerged;
  final List<Position> positionsMerged;
  final List<IntimacyRecord> recordsMerged;
  final List<TimerHistoryEntry> timerHistoryMerged;
  final IntimacyTimerSession? timerSession;
  final DateTime timerSessionModifiedAt;
  final int? timerHistoryRetentionDays;
  final Map<String, String> partnerSortModes;
  final Map<String, List<String>> partnerCustomOrders;
  final Map<String, String> toySortModes;
  final Map<String, List<String>> toyCustomOrders;
  final DateTime settingsModifiedAt;
  final List<RecordConflict<Partner>> partnerConflicts;
  final List<RecordConflict<Toy>> toyConflicts;
  final List<RecordConflict<Position>> positionConflicts;
  final List<RecordConflict<IntimacyRecord>> recordConflicts;

  /// Purpose: Create a intimacy merge result instance.
  /// Inputs: None.
  /// Returns: A new `IntimacyMergeResult` instance.
  /// Side effects: None.
  /// Notes: None.
  const IntimacyMergeResult({
    required this.partnersMerged,
    required this.toysMerged,
    required this.positionsMerged,
    required this.recordsMerged,
    required this.timerHistoryMerged,
    required this.timerSession,
    required this.timerSessionModifiedAt,
    required this.timerHistoryRetentionDays,
    required this.partnerSortModes,
    required this.partnerCustomOrders,
    required this.toySortModes,
    required this.toyCustomOrders,
    required this.settingsModifiedAt,
    required this.partnerConflicts,
    required this.toyConflicts,
    required this.positionConflicts,
    required this.recordConflicts,
  });

  /// Purpose: Return whether conflicts is available.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get hasConflicts =>
      partnerConflicts.isNotEmpty ||
      toyConflicts.isNotEmpty ||
      positionConflicts.isNotEmpty ||
      recordConflicts.isNotEmpty;

  /// Purpose: Implement the build resolved behavior for this file.
  /// Inputs: `resolutions`.
  /// Returns: `IntimacyData`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  IntimacyData buildResolved(Map<String, dynamic> resolutions) {
    return IntimacyData(
      partners: _resolveList(partnersMerged, partnerConflicts, resolutions),
      toys: _resolveList(toysMerged, toyConflicts, resolutions),
      positions: _resolveList(positionsMerged, positionConflicts, resolutions),
      records: _resolveList(recordsMerged, recordConflicts, resolutions),
      timerHistory: timerHistoryMerged,
      timerSession: timerSession,
      timerSessionModifiedAt: timerSessionModifiedAt,
      timerHistoryRetentionDays: timerHistoryRetentionDays,
      partnerSortModes: partnerSortModes,
      partnerCustomOrders: partnerCustomOrders,
      toySortModes: toySortModes,
      toyCustomOrders: toyCustomOrders,
      settingsModifiedAt: settingsModifiedAt,
    );
  }

  /// Purpose: Provide the internal resolve list helper for this file.
  /// Inputs: `merged`, `conflicts`, `resolutions`.
  /// Returns: `List<T>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static List<T> _resolveList<T>(
    List<T> merged,
    List<RecordConflict<T>> conflicts,
    Map<String, dynamic> resolutions,
  ) {
    final result = [...merged];
    for (final c in conflicts) {
      final resolved = resolutions[c.id];
      if (resolved != null) result.add(resolved as T);
    }
    return result;
  }
}

// ─── ExchangeRateData merge ─────────────────────────────────────────

/// Exchange rates: union of all snapshots, newest snapshot becomes current.
/// Purpose: Merge exchange rate json into a single result.
/// Inputs: `localJson`, `remoteJson`.
/// Returns: `String`.
/// Side effects: May create, transform, or mutate data used by callers.
/// Notes: None.
String mergeExchangeRateJson(String localJson, String remoteJson) {
  final local = ExchangeRateData.fromJson(
    jsonDecode(localJson) as Map<String, dynamic>,
  );
  final remote = ExchangeRateData.fromJson(
    jsonDecode(remoteJson) as Map<String, dynamic>,
  );

  // Union of all snapshots
  final mergedSnapshots = {...local.snapshots, ...remote.snapshots};

  // Current = whichever current snapshot was created later
  final localCurrent = local.snapshots[local.currentSnapshotId];
  final remoteCurrent = remote.snapshots[remote.currentSnapshotId];

  String currentId;
  if (localCurrent != null && remoteCurrent != null) {
    currentId = localCurrent.createdAt.isAfter(remoteCurrent.createdAt)
        ? local.currentSnapshotId
        : remote.currentSnapshotId;
  } else {
    currentId = local.currentSnapshotId;
  }

  // lastFetchedAt: use the more recent value
  final DateTime? mergedLastFetched;
  if (local.lastFetchedAt != null && remote.lastFetchedAt != null) {
    mergedLastFetched = local.lastFetchedAt!.isAfter(remote.lastFetchedAt!)
        ? local.lastFetchedAt
        : remote.lastFetchedAt;
  } else {
    mergedLastFetched = local.lastFetchedAt ?? remote.lastFetchedAt;
  }

  final merged = ExchangeRateData(
    currentSnapshotId: currentId,
    snapshots: mergedSnapshots,
    lastFetchedAt: mergedLastFetched,
  );

  return jsonEncode(merged.toJson());
}

// ─── WeightData merge ───────────────────────────────────────────────

/// Purpose: Merge weight data into a single result.
/// Inputs: `localJson`, `remoteJson`, `baseJson`, `autoResolve`.
/// Returns: `WeightMergeResult`.
/// Side effects: May read or mutate application state, storage, or service resources.
/// Notes: None.
WeightMergeResult mergeWeightData(
  String localJson,
  String remoteJson,
  String? baseJson, {
  bool autoResolve = false,
}) {
  final local = WeightData.fromJson(
    jsonDecode(localJson) as Map<String, dynamic>,
  );
  final remote = WeightData.fromJson(
    jsonDecode(remoteJson) as Map<String, dynamic>,
  );
  final base = baseJson != null
      ? WeightData.fromJson(jsonDecode(baseJson) as Map<String, dynamic>)
      : null;

  final recordResult = mergeRecords<WeightRecord>(
    local: local.records,
    remote: remote.records,
    base: base?.records,
    getId: (r) => r.id,
    getModifiedAt: (r) => r.modifiedAt,
    getDisplayName: (r) =>
        '${r.weight} kg (${r.datetime.toIso8601String().substring(0, 10)})',
    autoResolve: autoResolve,
  );

  // Height: prefer the non-null / most recently changed value
  final height = local.height ?? remote.height;

  // Settings: LWW via settingsModifiedAt
  final WeightData settingsSrc =
      local.settingsModifiedAt.isAfter(remote.settingsModifiedAt)
      ? local
      : remote;

  return WeightMergeResult(
    height: height,
    recordsMerged: recordResult.merged,
    recordConflicts: recordResult.conflicts,
    reminderMode: settingsSrc.reminderMode,
    morningHour: settingsSrc.morningHour,
    morningMinute: settingsSrc.morningMinute,
    eveningHour: settingsSrc.eveningHour,
    eveningMinute: settingsSrc.eveningMinute,
    reminderGraceMinutes: settingsSrc.reminderGraceMinutes,
    settingsModifiedAt: settingsSrc.settingsModifiedAt,
  );
}

class WeightMergeResult {
  final double? height;
  final List<WeightRecord> recordsMerged;
  final List<RecordConflict<WeightRecord>> recordConflicts;
  final String reminderMode;
  final int? morningHour;
  final int? morningMinute;
  final int? eveningHour;
  final int? eveningMinute;
  final int reminderGraceMinutes;
  final DateTime settingsModifiedAt;

  /// Purpose: Create a weight merge result instance.
  /// Inputs: `reminderMode`.
  /// Returns: A new `WeightMergeResult` instance.
  /// Side effects: None.
  /// Notes: None.
  WeightMergeResult({
    required this.height,
    required this.recordsMerged,
    required this.recordConflicts,
    this.reminderMode = 'none',
    this.morningHour,
    this.morningMinute,
    this.eveningHour,
    this.eveningMinute,
    this.reminderGraceMinutes = 180,
    DateTime? settingsModifiedAt,
  }) : settingsModifiedAt =
           settingsModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Purpose: Return whether conflicts is available.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get hasConflicts => recordConflicts.isNotEmpty;

  /// Purpose: Implement the build resolved behavior for this file.
  /// Inputs: `resolutions`.
  /// Returns: `WeightData`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  WeightData buildResolved(Map<String, dynamic> resolutions) {
    final result = [...recordsMerged];
    for (final c in recordConflicts) {
      final resolved = resolutions[c.id];
      if (resolved != null) result.add(resolved as WeightRecord);
    }
    return WeightData(
      height: height,
      records: result,
      reminderMode: reminderMode,
      morningHour: morningHour,
      morningMinute: morningMinute,
      eveningHour: eveningHour,
      eveningMinute: eveningMinute,
      reminderGraceMinutes: reminderGraceMinutes,
      settingsModifiedAt: settingsModifiedAt,
    );
  }
}

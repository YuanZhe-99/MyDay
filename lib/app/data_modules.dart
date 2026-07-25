/// Purpose: Single source of truth describing MyDay's syncable data files to
/// the shared `myapps_data` engines.
/// Inputs: `TodoStorage` for storage paths/settings, the per-module merge
/// wrappers in `sync_merge.dart`, the preservation schemas in
/// `utils/json_preservation.dart`, and the finance forced-balance migration.
/// Returns: A `StorageAdapter` implementation and the app's `ModuleRegistry`.
/// Side effects: None at import time; callbacks parse, migrate, and read files.
/// Notes: PLAN.md P3.2.2. This replaces the five separate hardcoded file lists
/// the app used to carry (`webdav_service`, `data_file_safety`,
/// `import_export_service`, `backup_service`, `todo_storage`). Registry order is
/// the sync/backup/progress order. File names and module IDs are persisted
/// compatibility contracts (I1/I2) and must never change.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:myapps_data/myapps_data.dart';
import 'package:path/path.dart' as p;

import '../features/finance/services/balance_util.dart';
import '../features/finance/services/finance_storage.dart';
import '../features/finance/services/exchange_rate_storage.dart';

import '../features/intimacy/models/intimacy_record.dart';

import '../features/todo/services/todo_storage.dart';
import '../features/weight/models/weight_record.dart';
import '../shared/services/sync_merge.dart';
import '../shared/utils/json_preservation.dart';

/// Purpose: Bridge the shared engines to MyDay's storage hub.
/// Inputs: Optional [appDir] resolver overriding the hub lookup.
/// Returns: Storage root and `storage_config.json` access.
/// Side effects: Delegates to `TodoStorage`, which performs file I/O.
/// Notes: [appDir] exists so `BackupService` can keep honoring its
/// `@visibleForTesting appDirProvider` seam (I7); it is read on every call, so
/// tests that swap the provider between cases still work.
class TodoStorageAdapter implements StorageAdapter {
  /// Purpose: Create an adapter over `TodoStorage`.
  /// Inputs: Optional [appDir] resolver.
  /// Returns: A new adapter.
  /// Side effects: None.
  /// Notes: Pass [appDir] only to preserve an existing test seam.
  const TodoStorageAdapter({Future<Directory> Function()? appDir})
    : _appDir = appDir;

  final Future<Directory> Function()? _appDir;

  /// Purpose: Resolve the active app data directory.
  /// Inputs: None.
  /// Returns: The custom storage path when configured, else the platform dir.
  /// Side effects: May create the directory via the hub.
  /// Notes: Honors the injected resolver first so `appDirProvider` still wins.
  @override
  Future<Directory> getAppDir() => (_appDir ?? TodoStorage.getAppDir)();

  /// Purpose: Read `storage_config.json`.
  /// Inputs: None.
  /// Returns: The parsed settings map.
  /// Side effects: Reads local storage.
  /// Notes: Delegates so app-owned keys stay owned by the hub.
  @override
  Future<Map<String, dynamic>> readConfig() => TodoStorage.readConfig();

  /// Purpose: Persist `storage_config.json`.
  /// Inputs: [config] complete settings map.
  /// Returns: A future completing after the write.
  /// Side effects: Writes local storage.
  /// Notes: The engines read-modify-write, so unknown keys survive.
  @override
  Future<void> writeConfig(Map<String, dynamic> config) =>
      TodoStorage.writeConfig(config);
}

/// Default remote WebDAV directory for MyDay.
const todoDefaultRemotePath = '/MyDay';

/// Archive name prefix for ZIP exports.
const todoArchiveNamePrefix = 'myday_backup_';

/// Data file names, kept as named constants for the few call sites that need
/// one specific file rather than the whole registry.
const todoDataFileName = 'todo_data.json';
const financeDataFileName = 'finance_data.json';
const exchangeRatesFileName = 'exchange_rates.json';
const intimacyDataFileName = 'intimacy_data.json';
const weightDataFileName = 'weight_data.json';

/// Purpose: Re-inject unknown JSON fields immediately before a file is written.
/// Inputs: [fileName] and the engine-supplied [context] snapshots.
/// Returns: The payload with unknown fields restored.
/// Side effects: None.
/// Notes: MyDay's merge output is *not* self-preserving — unknown fields are
/// re-applied at write time from the base/local/remote snapshots, in that
/// order, using the app-owned schemas. Files without a schema pass through.
String _preserveUnknownJson(String fileName, ModuleUploadContext context) {
  final schema = dataFilePreservationSchemas[fileName];
  if (schema == null) return context.nextJson;
  return JsonPreservation.preserveJsonString(
    nextJson: context.nextJson,
    sourceJsons: [context.baseJson, context.localJson, context.remoteJson],
    schema: schema,
  );
}

/// Purpose: Extract image basenames from the named sections of a data file.
/// Inputs: [json] raw module JSON, [sections] top-level list keys to scan.
/// Returns: Referenced image basenames; empty for malformed input.
/// Side effects: None.
/// Notes: Reproduces the previous `_getReferencedImageNames` exactly, including
/// ignoring empty paths and returning empty on any parse failure.
Set<String> _imageNamesFromSections(String json, List<String> sections) {
  try {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final names = <String>{};
    for (final section in sections) {
      final items = decoded[section];
      if (items is List) {
        for (final item in items) {
          if (item is Map) {
            final path = item['imagePath'] as String?;
            if (path != null && path.isNotEmpty) {
              names.add(p.basename(path));
            }
          }
        }
      }
    }
    return names;
  } catch (_) {
    return {};
  }
}

/// Purpose: Convert legacy forced account balances into real transactions.
/// Inputs: [data] merged or resolved finance data.
/// Returns: The migrated data, or [data] unchanged when nothing needed fixing.
/// Side effects: Reads exchange-rate data needed to convert legacy transactions.
/// Notes: Moved verbatim from `WebDAVService._migrateFinanceForcedBalances`
/// (PLAN.md P3.2.2). It runs after merge and after conflict resolution on both
/// the normal-sync and finalize paths, which is exactly where the shared
/// engine invokes `postMergeTransform`.
Future<FinanceData> migrateFinanceForcedBalances(FinanceData data) async {
  final rateData = await ExchangeRateStorage.load();
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

/// Purpose: Build one structured (per-record) MyDay data module.
/// Inputs: File/module identity, validator, merge wrapper adapters, and
/// optional [postMergeTransform]/[referencedImages].
/// Returns: A configured [DataModule].
/// Side effects: None.
/// Notes: Structured modules encode compactly with `jsonEncode` (matching the
/// previous `_uploadMergedJson` path) and report an indeterminate upload phase,
/// which is why [DataModule.indexMergedUploadProgress] is false here.
DataModule _structuredModule<R>({
  required String fileName,
  required String moduleId,
  required ModuleValidator validate,
  required R Function(String local, String remote, String? base, bool auto) run,
  required bool Function(R result) hasConflicts,
  required List<RecordConflict> Function(R result) conflicts,
  required Map<String, dynamic> Function(R result, Map<String, dynamic> choices)
  buildResolved,
  ModulePostMergeTransform? postMergeTransform,
  ModuleImageReferences? referencedImages,
}) {
  return DataModule(
    fileName: fileName,
    moduleId: moduleId,
    validate: validate,
    indexMergedUploadProgress: false,
    postMergeTransform: postMergeTransform,
    preUploadTransform: (context) => _preserveUnknownJson(fileName, context),
    referencedImages: referencedImages,
    merge:
        ({
          required String localJson,
          required String remoteJson,
          required String? baseJson,
          required bool autoResolve,
        }) {
          final result = run(localJson, remoteJson, baseJson, autoResolve);
          if (!hasConflicts(result)) {
            return ModuleMergeOutcome(
              mergedJson: jsonEncode(buildResolved(result, const {})),
              state: result,
            );
          }
          return ModuleMergeOutcome(
            state: result,
            conflicts: [
              for (final conflict in conflicts(result))
                ModuleConflict(
                  id: conflict.id,
                  localRecord: conflict.localRecord as Object,
                  remoteRecord: conflict.remoteRecord as Object,
                  displayName: conflict.displayName,
                ),
            ],
            buildResolvedJson: (resolutions) => jsonEncode(
              buildResolved(result, Map<String, dynamic>.from(resolutions)),
            ),
          );
        },
  );
}

/// Purpose: Describe `todo_data.json` to the shared engines.
/// Inputs: None.
/// Returns: The todo [DataModule].
/// Side effects: None.
/// Notes: Daily and once tasks are separate conflict containers; both key
/// resolutions by record ID, exactly as the conflict dialog already does.
DataModule buildTodoModule() => _structuredModule<TodoMergeResult>(
  fileName: todoDataFileName,
  moduleId: 'todo',
  validate: (json) =>
      TodoData.fromJson(jsonDecode(json) as Map<String, dynamic>),
  run: (local, remote, base, auto) =>
      mergeTodoData(local, remote, base, autoResolve: auto),
  hasConflicts: (r) => r.hasConflicts,
  conflicts: (r) => [...r.dailyConflicts, ...r.onceConflicts],
  buildResolved: (r, choices) => r.buildResolved(choices).toJson(),
);

/// Purpose: Describe `finance_data.json` to the shared engines.
/// Inputs: None.
/// Returns: The finance [DataModule].
/// Side effects: None.
/// Notes: The forced-balance migration is a `postMergeTransform` because it runs
/// *after* the merge and after conflict resolution, on both paths, and needs the
/// current exchange rates — it is not a pre-merge remote migration.
DataModule buildFinanceModule() => _structuredModule<FinanceMergeResult>(
  fileName: financeDataFileName,
  moduleId: 'finance',
  validate: (json) =>
      FinanceData.fromJson(jsonDecode(json) as Map<String, dynamic>),
  run: (local, remote, base, auto) =>
      mergeFinanceData(local, remote, base, autoResolve: auto),
  hasConflicts: (r) => r.hasConflicts,
  conflicts: (r) => [
    ...r.accountConflicts,
    ...r.categoryConflicts,
    ...r.transactionConflicts,
    ...r.subscriptionConflicts,
  ],
  buildResolved: (r, choices) => r.buildResolved(choices).toJson(),
  postMergeTransform: (json) async {
    final data = FinanceData.fromJson(jsonDecode(json) as Map<String, dynamic>);
    return jsonEncode((await migrateFinanceForcedBalances(data)).toJson());
  },
  referencedImages: (json) =>
      _imageNamesFromSections(json, const ['accounts', 'subscriptions']),
);

/// Purpose: Describe `intimacy_data.json` to the shared engines.
/// Inputs: None.
/// Returns: The intimacy [DataModule].
/// Side effects: None.
/// Notes: Five conflict containers, all keyed by record ID.
DataModule buildIntimacyModule() => _structuredModule<IntimacyMergeResult>(
  fileName: intimacyDataFileName,
  moduleId: 'intimacy',
  validate: (json) =>
      IntimacyData.fromJson(jsonDecode(json) as Map<String, dynamic>),
  run: (local, remote, base, auto) =>
      mergeIntimacyData(local, remote, base, autoResolve: auto),
  hasConflicts: (r) => r.hasConflicts,
  conflicts: (r) => [
    ...r.partnerConflicts,
    ...r.toyConflicts,
    ...r.positionConflicts,
    ...r.recordConflicts,
    ...r.cycleRecordConflicts,
  ],
  buildResolved: (r, choices) => r.buildResolved(choices).toJson(),
  referencedImages: (json) =>
      _imageNamesFromSections(json, const ['partners', 'toys']),
);

/// Purpose: Describe `weight_data.json` to the shared engines.
/// Inputs: None.
/// Returns: The weight [DataModule].
/// Side effects: None.
/// Notes: None.
DataModule buildWeightModule() => _structuredModule<WeightMergeResult>(
  fileName: weightDataFileName,
  moduleId: 'weight',
  validate: (json) =>
      WeightData.fromJson(jsonDecode(json) as Map<String, dynamic>),
  run: (local, remote, base, auto) =>
      mergeWeightData(local, remote, base, autoResolve: auto),
  hasConflicts: (r) => r.hasConflicts,
  conflicts: (r) => r.recordConflicts,
  buildResolved: (r, choices) => r.buildResolved(choices).toJson(),
);

/// Purpose: Describe `exchange_rates.json` to the shared engines.
/// Inputs: None.
/// Returns: The exchange-rates [DataModule].
/// Side effects: None.
/// Notes: The odd one out — a whole-file union merge that can never produce a
/// record conflict, so the outcome is always complete. It is also the only
/// module that reports indexed upload progress, matching the previous code.
DataModule buildExchangeRatesModule() => DataModule(
  fileName: exchangeRatesFileName,
  moduleId: 'exchangeRates',
  validate: (json) =>
      ExchangeRateData.fromJson(jsonDecode(json) as Map<String, dynamic>),
  preUploadTransform: (context) =>
      _preserveUnknownJson(exchangeRatesFileName, context),
  merge:
      ({
        required String localJson,
        required String remoteJson,
        required String? baseJson,
        required bool autoResolve,
      }) => ModuleMergeOutcome(
        mergedJson: mergeExchangeRateJson(localJson, remoteJson),
      ),
);

/// Purpose: Provide MyDay's ordered module registry.
/// Inputs: None.
/// Returns: A registry holding all five data modules.
/// Side effects: None.
/// Notes: Order matches the previous hardcoded `_dataFileNames` list and is
/// behaviorally significant for sync order, progress, and backup key order.
final ModuleRegistry todoModuleRegistry = ModuleRegistry([
  buildTodoModule(),
  buildFinanceModule(),
  buildExchangeRatesModule(),
  buildIntimacyModule(),
  buildWeightModule(),
]);

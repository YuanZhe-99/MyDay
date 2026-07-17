import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../../shared/services/data_file_safety.dart';
import '../../../shared/utils/json_preservation.dart';
import '../../todo/services/todo_storage.dart';

/// A snapshot of all exchange rates at a point in time.
class RateSnapshot {
  final String id;
  final Map<String, double> rates;
  final DateTime createdAt;

  /// Purpose: Create a rate snapshot instance.
  /// Inputs: `createdAt`.
  /// Returns: A new `RateSnapshot` instance.
  /// Side effects: None.
  /// Notes: None.
  RateSnapshot({String? id, required this.rates, DateTime? createdAt})
    : id = id ?? const Uuid().v4(),
      createdAt = createdAt ?? DateTime.now();

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'rates': rates,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `RateSnapshot.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory RateSnapshot.fromJson(Map<String, dynamic> json) => RateSnapshot(
    id: json['id'] as String,
    rates: (json['rates'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Holds all rate snapshots and a pointer to the current one.
class ExchangeRateData {
  final String currentSnapshotId;
  final Map<String, RateSnapshot> snapshots;
  final DateTime? lastFetchedAt;

  /// Purpose: Create a exchange rate data instance.
  /// Inputs: None.
  /// Returns: A new `ExchangeRateData` instance.
  /// Side effects: None.
  /// Notes: None.
  ExchangeRateData({
    required this.currentSnapshotId,
    required this.snapshots,
    this.lastFetchedAt,
  });

  /// The current active rates.
  /// Purpose: Return current rates.
  /// Inputs: None.
  /// Returns: `Map<String, double>`.
  /// Side effects: None.
  /// Notes: None.
  Map<String, double> get currentRates =>
      snapshots[currentSnapshotId]?.rates ?? const {};

  /// Get rates for a specific snapshot. Falls back to current rates.
  /// Purpose: Implement the rates at behavior for this file.
  /// Inputs: `snapshotId`.
  /// Returns: `Map<String, double>`.
  /// Side effects: None.
  /// Notes: None.
  Map<String, double> ratesAt(String? snapshotId) =>
      snapshots[snapshotId]?.rates ?? currentRates;

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'currentSnapshotId': currentSnapshotId,
    'snapshots': snapshots.map((k, v) => MapEntry(k, v.toJson())),
    if (lastFetchedAt != null)
      'lastFetchedAt': lastFetchedAt!.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `ExchangeRateData.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory ExchangeRateData.fromJson(Map<String, dynamic> json) {
    final snapshotsMap = (json['snapshots'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, RateSnapshot.fromJson(v as Map<String, dynamic>)),
    );
    return ExchangeRateData(
      currentSnapshotId: json['currentSnapshotId'] as String,
      snapshots: snapshotsMap,
      lastFetchedAt: json['lastFetchedAt'] != null
          ? DateTime.parse(json['lastFetchedAt'] as String)
          : null,
    );
  }
}

/// Persists exchange rate snapshots with history.
class ExchangeRateStorage {
  static const _fileName = 'exchange_rates.json';
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
  /// Returns: `Future<ExchangeRateData>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  static Future<ExchangeRateData> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return _defaultData();
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;

      // Migration: old format is a flat map without "snapshots" key
      if (!json.containsKey('snapshots')) {
        final flatRates = json.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
        return _createInitialData(flatRates);
      }

      return ExchangeRateData.fromJson(json);
    } catch (_) {
      return _defaultData();
    }
  }

  /// Purpose: Implement the save behavior for this file.
  /// Inputs: `data`.
  /// Returns: `Future<void>`.
  /// Side effects: Serializes exchange-rate writes, validates generated JSON, and atomically replaces the data file.
  /// Notes: Prevents overlapping writers from interleaving and corrupting JSON.
  static Future<void> save(ExchangeRateData data) async {
    final next = _writeQueue.then(
      (_) => _saveNow(data),
      onError: (_) => _saveNow(data),
    );
    _writeQueue = next.catchError((_) {});
    return next;
  }

  /// Purpose: Persist exchange-rate data after the caller has entered the write queue.
  /// Inputs: `data`.
  /// Returns: `Future<void>`.
  /// Side effects: Writes `exchange_rates.json` through a validated temporary file.
  /// Notes: Internal helper used within this file only.
  static Future<void> _saveNow(ExchangeRateData data) async {
    final file = await _getFile();
    var preserveUnknown = true;
    try {
      if (await file.exists()) {
        final existing =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        preserveUnknown = existing.containsKey('snapshots');
      }
    } catch (_) {}
    if (!preserveUnknown) {
      await DataFileSafety.writeValidatedDataJson(
        file,
        jsonEncode(data.toJson()),
      );
      return;
    }
    final jsonStr = await JsonPreservation.encodeForFile(
      file: file,
      next: data.toJson(),
      schema: dataFilePreservationSchemas[_fileName]!,
    );
    await DataFileSafety.writeValidatedDataJson(file, jsonStr);
  }

  /// Update rates. Creates a new snapshot only if rates differ from current.
  /// Purpose: Update rates through the current flow.
  /// Inputs: `data`, `newRates`.
  /// Returns: `ExchangeRateData`.
  /// Side effects: May create, transform, or mutate data used by callers.
  /// Notes: None.
  static ExchangeRateData updateRates(
    ExchangeRateData data,
    Map<String, double> newRates,
  ) {
    final current = data.currentRates;
    if (_ratesEqual(current, newRates)) return data;

    final snapshot = RateSnapshot(rates: Map.unmodifiable(newRates));
    final newSnapshots = Map.of(data.snapshots);
    newSnapshots[snapshot.id] = snapshot;
    return ExchangeRateData(
      currentSnapshotId: snapshot.id,
      snapshots: newSnapshots,
    );
  }

  /// Purpose: Provide the internal rates equal helper for this file.
  /// Inputs: `a`, `b`.
  /// Returns: `bool`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static bool _ratesEqual(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  /// Purpose: Provide the internal default data helper for this file.
  /// Inputs: None.
  /// Returns: `ExchangeRateData`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static ExchangeRateData _defaultData() => _createInitialData(_defaultRates);

  /// Purpose: Provide the internal create initial data helper for this file.
  /// Inputs: `rates`.
  /// Returns: `ExchangeRateData`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  static ExchangeRateData _createInitialData(Map<String, double> rates) {
    final snapshot = RateSnapshot(rates: rates);
    return ExchangeRateData(
      currentSnapshotId: snapshot.id,
      snapshots: {snapshot.id: snapshot},
    );
  }

  static final Map<String, double> _defaultRates = {
    'USD_CNY': 7.25,
    'EUR_CNY': 7.90,
    'GBP_CNY': 9.20,
    'JPY_CNY': 0.048,
    'CAD_CNY': 5.30,
    'AUD_CNY': 4.75,
    'EUR_USD': 1.09,
    'GBP_USD': 1.27,
  };
}

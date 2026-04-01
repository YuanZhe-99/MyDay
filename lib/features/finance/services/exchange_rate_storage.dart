import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../todo/services/todo_storage.dart';

/// A snapshot of all exchange rates at a point in time.
class RateSnapshot {
  final String id;
  final Map<String, double> rates;
  final DateTime createdAt;

  RateSnapshot({
    String? id,
    required this.rates,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'rates': rates,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RateSnapshot.fromJson(Map<String, dynamic> json) => RateSnapshot(
        id: json['id'] as String,
        rates: (json['rates'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Holds all rate snapshots and a pointer to the current one.
class ExchangeRateData {
  final String currentSnapshotId;
  final Map<String, RateSnapshot> snapshots;
  final DateTime? lastFetchedAt;

  ExchangeRateData({
    required this.currentSnapshotId,
    required this.snapshots,
    this.lastFetchedAt,
  });

  /// The current active rates.
  Map<String, double> get currentRates =>
      snapshots[currentSnapshotId]?.rates ?? const {};

  /// Get rates for a specific snapshot. Falls back to current rates.
  Map<String, double> ratesAt(String? snapshotId) =>
      snapshots[snapshotId]?.rates ?? currentRates;

  Map<String, dynamic> toJson() => {
        'currentSnapshotId': currentSnapshotId,
        'snapshots':
            snapshots.map((k, v) => MapEntry(k, v.toJson())),
        if (lastFetchedAt != null)
          'lastFetchedAt': lastFetchedAt!.toIso8601String(),
      };

  factory ExchangeRateData.fromJson(Map<String, dynamic> json) {
    final snapshotsMap = (json['snapshots'] as Map<String, dynamic>).map(
      (k, v) =>
          MapEntry(k, RateSnapshot.fromJson(v as Map<String, dynamic>)),
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

  static Future<File> _getFile() async {
    final appDir = await TodoStorage.getAppDir();
    return File('${appDir.path}/$_fileName');
  }

  static Future<ExchangeRateData> load() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return _defaultData();
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;

      // Migration: old format is a flat map without "snapshots" key
      if (!json.containsKey('snapshots')) {
        final flatRates =
            json.map((k, v) => MapEntry(k, (v as num).toDouble()));
        return _createInitialData(flatRates);
      }

      return ExchangeRateData.fromJson(json);
    } catch (_) {
      return _defaultData();
    }
  }

  static Future<void> save(ExchangeRateData data) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(data.toJson()));
  }

  /// Update rates. Creates a new snapshot only if rates differ from current.
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

  static bool _ratesEqual(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  static ExchangeRateData _defaultData() =>
      _createInitialData(_defaultRates);

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

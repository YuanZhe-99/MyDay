import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exchange_rate_storage.dart';

/// Fetches latest exchange rates from the free Open Exchange Rates API.
///
/// Uses https://open.er-api.com — no API key required, 1 500 req/month free.
class ExchangeRateApi {
  static const _baseUrl = 'https://open.er-api.com/v6/latest';

  /// Fetch live rates and merge them into existing [ExchangeRateData].
  ///
  /// Only updates pairs that already exist in the local data (preserves user's
  /// configured pairs). Returns `null` on network / parse failure.
  static Future<ExchangeRateData?> fetchAndMerge(ExchangeRateData data) async {
    final pairs = data.currentRates.keys.toList();
    if (pairs.isEmpty) return null;

    // Collect unique base currencies we need to query
    final bases = <String>{};
    for (final pair in pairs) {
      final parts = pair.split('_');
      if (parts.length == 2) bases.add(parts[0]);
    }

    // Fetch rates for each base currency
    final fetched = <String, Map<String, double>>{};
    for (final base in bases) {
      final result = await _fetchRates(base);
      if (result != null) fetched[base] = result;
    }
    if (fetched.isEmpty) return null;

    // Merge fetched rates into existing pairs
    final newRates = Map<String, double>.from(data.currentRates);
    for (final pair in pairs) {
      final parts = pair.split('_');
      if (parts.length != 2) continue;
      final from = parts[0];
      final to = parts[1];
      final baseRates = fetched[from];
      if (baseRates != null && baseRates.containsKey(to)) {
        newRates[pair] = baseRates[to]!;
      }
    }

    return ExchangeRateStorage.updateRates(data, newRates);
  }

  /// Raw fetch: returns `{ "CNY": 7.25, "EUR": 0.92, ... }` for the given
  /// base currency, or `null` on failure.
  static Future<Map<String, double>?> _fetchRates(String base) async {
    try {
      final uri = Uri.parse('$_baseUrl/$base');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['result'] != 'success') return null;
      final rates = json['rates'] as Map<String, dynamic>;
      return rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return null;
    }
  }

  /// Check whether we should auto-fetch today.
  /// Returns `true` if [lastFetch] is null or on a different day than now.
  static bool shouldFetchToday(DateTime? lastFetch) {
    if (lastFetch == null) return true;
    final now = DateTime.now();
    return now.year != lastFetch.year ||
        now.month != lastFetch.month ||
        now.day != lastFetch.day;
  }
}

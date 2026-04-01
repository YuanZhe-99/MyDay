import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A single bank / fintech preset entry.
class BankPreset {
  final String id;
  final String country;
  final String localTitle;
  final String engTitle;
  final String color;
  final String domain;

  const BankPreset({
    required this.id,
    required this.country,
    required this.localTitle,
    required this.engTitle,
    required this.color,
    required this.domain,
  });

  factory BankPreset.fromJson(Map<String, dynamic> json) => BankPreset(
        id: json['id'] as String,
        country: json['country'] as String,
        localTitle: json['localTitle'] as String? ?? json['engTitle'] as String,
        engTitle: json['engTitle'] as String,
        color: json['color'] as String? ?? '#888888',
        domain: json['domain'] as String? ?? '',
      );

  /// Logo URLs to try in priority order — higher quality sources first.
  List<String> get logoUrls => domain.isNotEmpty
      ? [
          // Best quality – dedicated logo APIs returning clean PNG/SVG
          'https://logo.clearbit.com/$domain?size=128',
          'https://img.logo.dev/$domain?token=pk_anonymous&size=128&format=png',
          'https://api.brandfetch.io/v2/logo/$domain',
          // Good fallbacks – multi-source favicon aggregators
          'https://icon.horse/icon/$domain?size=128',
          'https://favicone.com/$domain?s=128',
          'https://www.google.com/s2/favicons?domain=$domain&sz=128',
          'https://icons.duckduckgo.com/ip3/$domain.ico',
          // Last resort — t3.gstatic (Google's alternative favicon CDN)
          'https://t3.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://$domain&size=128',
        ]
      : [];

  /// Primary logo URL for preview.
  String get logoUrl =>
      domain.isNotEmpty ? 'https://logo.clearbit.com/$domain?size=128' : '';

  /// Map country code to default currency.
  static const countryCurrency = <String, String>{
    'cn': 'CNY', 'us': 'USD', 'gb': 'GBP', 'jp': 'JPY',
    'tw': 'TWD', 'au': 'AUD', 'ca': 'CAD', 'de': 'EUR',
    'fr': 'EUR', 'nl': 'EUR', 'be': 'EUR', 'ie': 'EUR',
    'fi': 'EUR', 'pt': 'EUR', 'cy': 'EUR', 'nz': 'NZD',
    'in': 'INR', 'ru': 'RUB', 'tr': 'TRY', 'ir': 'IRR',
    'pl': 'PLN', 'dk': 'DKK', 'cz': 'CZK', 'za': 'ZAR',
    'ar': 'ARS', 'uy': 'UYU', 'rs': 'RSD', 'ua': 'UAH',
    'by': 'BYN', 'kz': 'KZT', 'kg': 'KGS',
  };

  /// Returns the default currency for this bank's country, or null.
  String? get defaultCurrency => countryCurrency[country];
}

/// Loads and caches the bundled bank preset list.
class BankPresetService {
  BankPresetService._();
  static final BankPresetService instance = BankPresetService._();

  List<BankPreset>? _cache;

  Future<List<BankPreset>> getAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/banks.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _cache = list.map(BankPreset.fromJson).toList();
    return _cache!;
  }

  /// Returns banks grouped by country code, sorted by localTitle.
  Future<Map<String, List<BankPreset>>> groupedByCountry() async {
    final all = await getAll();
    final map = <String, List<BankPreset>>{};
    for (final b in all) {
      (map[b.country] ??= []).add(b);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.localTitle.compareTo(b.localTitle));
    }
    return map;
  }

  /// Search by name (local or English), case-insensitive.
  Future<List<BankPreset>> search(String query) async {
    if (query.isEmpty) return getAll();
    final q = query.toLowerCase();
    final all = await getAll();
    return all
        .where((b) =>
            b.localTitle.toLowerCase().contains(q) ||
            b.engTitle.toLowerCase().contains(q))
        .toList();
  }
}

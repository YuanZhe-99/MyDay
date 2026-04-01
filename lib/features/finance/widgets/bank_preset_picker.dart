import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../services/bank_preset_service.dart';

/// Country code → display label.
const _countryLabels = {
  'cn': '🇨🇳 CN',
  'us': '🇺🇸 US',
  'gb': '🇬🇧 GB',
  'jp': '🇯🇵 JP',
  'tw': '🇹🇼 TW',
  'au': '🇦🇺 AU',
  'ca': '🇨🇦 CA',
  'de': '🇩🇪 DE',
  'fr': '🇫🇷 FR',
  'ru': '🇷🇺 RU',
  'ir': '🇮🇷 IR',
  'tr': '🇹🇷 TR',
  'in': '🇮🇳 IN',
  'by': '🇧🇾 BY',
  'ua': '🇺🇦 UA',
  'nl': '🇳🇱 NL',
  'nz': '🇳🇿 NZ',
  'pl': '🇵🇱 PL',
  'pt': '🇵🇹 PT',
  'za': '🇿🇦 ZA',
  'ar': '🇦🇷 AR',
  'be': '🇧🇪 BE',
  'cz': '🇨🇿 CZ',
  'dk': '🇩🇰 DK',
  'fi': '🇫🇮 FI',
  'ie': '🇮🇪 IE',
  'kg': '🇰🇬 KG',
  'kz': '🇰🇿 KZ',
  'rs': '🇷🇸 RS',
  'uy': '🇺🇾 UY',
  'cy': '🇨🇾 CY',
};

/// Priority order for tabs — most relevant countries first.
const _countryOrder = [
  'cn', 'jp', 'tw', 'us', 'gb', 'au', 'ca', 'de', 'fr',
  'ru', 'in', 'tr', 'ir', 'by', 'ua', 'nl', 'nz', 'pl',
  'pt', 'za', 'ar', 'be', 'cz', 'dk', 'fi', 'ie', 'kg',
  'kz', 'rs', 'uy', 'cy',
];

/// Shows a bottom sheet for picking a bank / fintech preset.
/// Returns the selected [BankPreset] or null.
Future<BankPreset?> showBankPresetPicker(BuildContext context) {
  return showModalBottomSheet<BankPreset>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _BankPickerSheet(),
  );
}

class _BankPickerSheet extends StatefulWidget {
  const _BankPickerSheet();

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final _searchController = TextEditingController();
  Map<String, List<BankPreset>> _grouped = {};
  List<BankPreset> _searchResults = [];
  bool _isSearching = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final grouped = await BankPresetService.instance.groupedByCountry();
    if (mounted) setState(() { _grouped = grouped; _loading = false; });
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }
    final results = await BankPresetService.instance.search(query);
    if (mounted) {
      setState(() {
        _isSearching = true;
        _searchResults = results;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Determine which country tabs to show (only those with data).
    final availableCountries =
        _countryOrder.where((c) => _grouped.containsKey(c)).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.financeBankPresets,
                style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.financeBankSearch,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: _onSearch,
            ),
          ),
          const SizedBox(height: 8),
          // Content
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_isSearching)
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(child: Text(l10n.financeBankNoResults))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) =>
                          _BankTile(bank: _searchResults[i]),
                    ),
            )
          else
            Expanded(
              child: DefaultTabController(
                length: availableCountries.length,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabs: availableCountries
                          .map((c) => Tab(
                              text: _countryLabels[c] ?? c.toUpperCase()))
                          .toList(),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: availableCountries.map((c) {
                          final banks = _grouped[c]!;
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: banks.length,
                            itemBuilder: (_, i) =>
                                _BankTile(bank: banks[i]),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BankTile extends StatelessWidget {
  final BankPreset bank;
  const _BankTile({required this.bank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseColor(bank.color);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: bank.logoUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  bank.logoUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, st) => Text(
                    bank.engTitle.isNotEmpty
                        ? bank.engTitle[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              )
            : Text(
                bank.engTitle.isNotEmpty
                    ? bank.engTitle[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
      title: Text(bank.localTitle),
      subtitle: bank.localTitle != bank.engTitle
          ? Text(bank.engTitle, style: theme.textTheme.bodySmall)
          : null,
      trailing: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      onTap: () => Navigator.pop(context, bank),
    );
  }

  static Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}

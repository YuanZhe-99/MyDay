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
/// Purpose: Show bank preset picker through the current flow.
/// Inputs: `context`.
/// Returns: `Future<BankPreset?>`.
/// Side effects: May update UI state or trigger user-facing flows.
/// Notes: None.
Future<BankPreset?> showBankPresetPicker(BuildContext context) {
  return showModalBottomSheet<BankPreset>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _BankPickerSheet(),
  );
}

class _BankPickerSheet extends StatefulWidget {
  /// Purpose: Create a bank picker sheet instance.
  /// Inputs: None.
  /// Returns: A new `_BankPickerSheet` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _BankPickerSheet();

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final _searchController = TextEditingController();
  Map<String, List<BankPreset>> _grouped = {};
  List<BankPreset> _searchResults = [];
  bool _isSearching = false;
  bool _loading = true;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Purpose: Provide the internal load helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _load() async {
    final grouped = await BankPresetService.instance.groupedByCountry();
    if (mounted) setState(() { _grouped = grouped; _loading = false; });
  }

  /// Purpose: Provide the internal on search helper for this file.
  /// Inputs: `query`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Releases owned resources and unregisters listeners.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
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
  /// Purpose: Create a bank tile instance.
  /// Inputs: `bank`.
  /// Returns: A new `_BankTile` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _BankTile({required this.bank});

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
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

  /// Purpose: Provide the internal parse color helper for this file.
  /// Inputs: `hex`.
  /// Returns: `Color`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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

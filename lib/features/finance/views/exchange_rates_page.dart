import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/auto_sync_service.dart';
import '../services/exchange_rate_api.dart';
import '../services/exchange_rate_storage.dart';

class ExchangeRatesPage extends StatefulWidget {
  const ExchangeRatesPage({super.key});

  @override
  State<ExchangeRatesPage> createState() => _ExchangeRatesPageState();
}

class _ExchangeRatesPageState extends State<ExchangeRatesPage> {
  ExchangeRateData? _data;
  Map<String, double> _rates = {};
  bool _loaded = false;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    final data = await ExchangeRateStorage.load();
    setState(() {
      _data = data;
      _rates = Map.of(data.currentRates);
      _loaded = true;
    });
    // Auto-fetch if not fetched today
    if (ExchangeRateApi.shouldFetchToday(data.lastFetchedAt)) {
      await _fetchOnline();
    }
  }

  Future<void> _fetchOnline() async {
    if (_data == null || _fetching) return;
    setState(() => _fetching = true);
    final updated = await ExchangeRateApi.fetchAndMerge(_data!);
    if (updated != null && mounted) {
      final withTimestamp = ExchangeRateData(
        currentSnapshotId: updated.currentSnapshotId,
        snapshots: updated.snapshots,
        lastFetchedAt: DateTime.now(),
      );
      await ExchangeRateStorage.save(withTimestamp);
      AutoSyncService.instance.notifySaved();
      setState(() {
        _data = withTimestamp;
        _rates = Map.of(withTimestamp.currentRates);
      });
    }
    if (mounted) setState(() => _fetching = false);
  }

  Future<void> _saveRates() async {
    if (_data == null) return;
    final updated = ExchangeRateStorage.updateRates(_data!, _rates);
    _data = updated;
    await ExchangeRateStorage.save(updated);
    AutoSyncService.instance.notifySaved();
  }

  Future<void> _addRate() async {
    final result = await showDialog<MapEntry<String, double>>(
      context: context,
      builder: (_) => const _RateDialog(),
    );
    if (result != null) {
      setState(() => _rates[result.key] = result.value);
      await _saveRates();
    }
  }

  Future<void> _editRate(String key, double value) async {
    final parts = key.split('_');
    if (parts.length != 2) return;
    final result = await showDialog<MapEntry<String, double>>(
      context: context,
      builder: (_) => _RateDialog(fromCurrency: parts[0], toCurrency: parts[1], rate: value),
    );
    if (result != null) {
      setState(() {
        _rates.remove(key);
        _rates[result.key] = result.value;
      });
      await _saveRates();
    }
  }

  void _deleteRate(String key) {
    setState(() => _rates.remove(key));
    _saveRates();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _rates.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.financeExchangeRates),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetching ? null : _fetchOnline,
            icon: _fetching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context)!.financeRefreshRates,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.financeNoRates,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final parts = entry.key.split('_');
                    final from = parts.isNotEmpty ? parts[0] : '?';
                    final to = parts.length > 1 ? parts[1] : '?';

                    return Dismissible(
                      key: ValueKey(entry.key),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        color: theme.colorScheme.primary,
                        child: Icon(Icons.edit_outlined,
                            color: theme.colorScheme.onPrimary),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: theme.colorScheme.error,
                        child: Icon(Icons.delete_outline,
                            color: theme.colorScheme.onError),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _editRate(entry.key, entry.value);
                          return false;
                        }
                        return true;
                      },
                      onDismissed: (_) => _deleteRate(entry.key),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          child: Icon(Icons.currency_exchange,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20),
                        ),
                        title: Text('1 $from = ${entry.value.toStringAsFixed(4)} $to'),
                        subtitle: Text('$from → $to'),
                        onTap: () => _editRate(entry.key, entry.value),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRate,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --------------- Rate Dialog ---------------

class _RateDialog extends StatefulWidget {
  final String? fromCurrency;
  final String? toCurrency;
  final double? rate;

  const _RateDialog({this.fromCurrency, this.toCurrency, this.rate});

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  static const _currencies = ['CNY', 'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];
  late String _from;
  late String _to;
  late final TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    _from = widget.fromCurrency ?? 'USD';
    _to = widget.toCurrency ?? 'CNY';
    _rateController = TextEditingController(
      text: widget.rate?.toStringAsFixed(4) ?? '',
    );
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.rate != null;

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? l10n.financeEditRate : l10n.financeNewRate,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _from,
                    decoration: InputDecoration(
                      labelText: l10n.financeFrom,
                      isDense: true,
                    ),
                    items: _currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _from = v);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _to,
                    decoration: InputDecoration(
                      labelText: l10n.financeTo,
                      isDense: true,
                    ),
                    items: _currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _to = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _rateController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
              ],
              decoration: InputDecoration(
                labelText: l10n.financeRate,
                hintText: l10n.financeRateHint(_from, _to),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.commonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  child: Text(isEditing ? l10n.commonSave : l10n.commonAdd),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final rate = double.tryParse(_rateController.text.trim());
    if (rate == null || rate <= 0) return;
    if (_from == _to) return;
    Navigator.pop(context, MapEntry('${_from}_$_to', rate));
  }
}

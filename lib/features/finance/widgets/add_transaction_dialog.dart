import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/image_service.dart';
import '../models/finance.dart';
import '../services/balance_util.dart';

class AddTransactionDialog extends StatefulWidget {
  final List<Category> categories;
  final List<Account> accounts;
  final Transaction? transaction;
  final String? currentSnapshotId;
  final String defaultCurrency;

  const AddTransactionDialog({
    super.key,
    this.categories = const [],
    this.accounts = const [],
    this.transaction,
    this.currentSnapshotId,
    this.defaultCurrency = 'CNY',
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _toAmountController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  late DateTime _date;
  late String _currency;
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _selectedToAccount;

  bool get _isEditing => widget.transaction != null;
  bool get _isCrossCurrency =>
      _type == TransactionType.transfer &&
      _selectedAccount != null &&
      _selectedToAccount != null &&
      _selectedAccount!.currency != _selectedToAccount!.currency;

  static const _symbols = <String, String>{
    'CNY': '¥', 'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥',
    'CAD': 'C\$', 'AUD': 'A\$', 'TWD': 'NT\$', 'HKD': 'HK\$',
    'SGD': 'S\$', 'KRW': '₩', 'CHF': 'Fr', 'NZD': 'NZ\$', 'INR': '₹',
  };

  List<DropdownMenuItem<String>> get _currencyItems {
    final codes = ['CNY', 'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'TWD', 'HKD', 'SGD', 'KRW', 'CHF', 'NZD', 'INR'];
    if (!codes.contains(_currency)) codes.insert(0, _currency);
    return codes
        .map((c) => DropdownMenuItem(value: c, child: Text('$c ${_symbols[c] ?? ''}')))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController = TextEditingController(
      text: tx != null ? tx.amount.toStringAsFixed(2) : '',
    );
    _toAmountController = TextEditingController(
      text: tx?.toAmount != null ? tx!.toAmount!.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: tx?.note ?? '');
    _type = tx?.type ?? TransactionType.expense;
    _date = tx?.date ?? DateTime.now();
    _currency = tx?.currency ?? widget.accounts.firstOrNull?.currency ?? widget.defaultCurrency;
    if (tx?.categoryId != null) {
      _selectedCategory = widget.categories
          .where((c) => c.id == tx!.categoryId)
          .firstOrNull;
    }
    if (tx?.accountId != null) {
      _selectedAccount = widget.accounts
          .where((a) => a.id == tx!.accountId)
          .firstOrNull;
    }
    if (tx?.toAccountId != null) {
      _selectedToAccount = widget.accounts
          .where((a) => a.id == tx!.toAccountId)
          .firstOrNull;
    }
    _selectedAccount ??= widget.accounts.firstOrNull;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _toAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEditing ? l10n.financeEditTransaction : l10n.financeAddTransaction,
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            // Type selector
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(l10n.financeExpense),
                  icon: const Icon(Icons.remove, size: 16),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text(l10n.financeIncome),
                  icon: const Icon(Icons.add, size: 16),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text(l10n.financeTransfer),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                setState(() => _type = set.first);
              },
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: l10n.financeAmount,
                prefixText: '${currencySymbol(_currency)} ',
                prefixStyle: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),

            // Currency picker
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: InputDecoration(
                labelText: l10n.financeCurrency,
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _currencyItems,
              onChanged: (v) {
                if (v != null) setState(() => _currency = v);
              },
            ),
            const SizedBox(height: 12),

            // Account picker
            if (widget.accounts.isNotEmpty) ...[
              _buildAccountPicker(theme, l10n),
              const SizedBox(height: 12),
            ],

            // Cross-currency received amount
            if (_isCrossCurrency) ...[
              TextField(
                controller: _toAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.financeReceivedAmount(_selectedToAccount!.currency),
                  prefixText: '${currencySymbol(_selectedToAccount!.currency)} ',
                  prefixStyle: TextStyle(color: theme.colorScheme.onSurface),
                  helperText: l10n.financeReceivedAmountHelper,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.financeNote,
                hintText: l10n.financeNoteHint,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),

            // Category picker
            _buildCategoryPicker(theme, l10n),
            const SizedBox(height: 12),

            // Date & time picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}  ${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
              ),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null && mounted) {
                  final pickedTime = await showTimePicker(
                    // ignore: use_build_context_synchronously
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_date),
                  );
                  setState(() {
                    final time = pickedTime ?? TimeOfDay.fromDateTime(_date);
                    _date = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Actions
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
                  child: Text(_isEditing ? l10n.commonSave : l10n.commonAdd),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountLabel(Account a) {
    final label = a.emoji != null
        ? '${a.emoji} ${a.name} (${a.bankOrApp})'
        : '${a.name} (${a.bankOrApp})';
    if (a.imagePath != null) {
      return FutureBuilder<File>(
        future: ImageService.resolve(a.imagePath!),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.existsSync()) {
            return Row(
              children: [
                CircleAvatar(backgroundImage: FileImage(snap.data!), radius: 12),
                const SizedBox(width: 8),
                Expanded(child: Text('${a.name} (${a.bankOrApp})', overflow: TextOverflow.ellipsis)),
              ],
            );
          }
          return Text(label, overflow: TextOverflow.ellipsis);
        },
      );
    }
    return Text(label, overflow: TextOverflow.ellipsis);
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final accountId = _selectedAccount?.id ??
        widget.transaction?.accountId ??
        '';
    final toAccountId = _type == TransactionType.transfer
        ? _selectedToAccount?.id
        : null;

    double? toAmount;
    String? toCurrency;
    if (_isCrossCurrency) {
      toAmount = double.tryParse(_toAmountController.text.trim());
      toCurrency = _selectedToAccount?.currency;
    }

    final tx = Transaction(
      id: widget.transaction?.id,
      type: _type,
      amount: amount,
      currency: _currency,
      rateSnapshotId: widget.currentSnapshotId,
      accountId: accountId,
      toAccountId: toAccountId,
      toAmount: toAmount,
      toCurrency: toCurrency,
      categoryId: _selectedCategory?.id,
      note: _noteController.text.trim(),
      date: _date,
    );
    Navigator.pop(context, tx);
  }

  List<Category> get _filteredCategories => widget.categories
      .where((c) => c.type == _type)
      .toList();

  Widget _buildCategoryPicker(ThemeData theme, AppLocalizations l10n) {
    final cats = _filteredCategories;
    if (cats.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory?.id,
      decoration: InputDecoration(
        labelText: l10n.financeCategory,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: cats.map((cat) {
        final label = cat.emoji != null ? '${cat.emoji} ${cat.name}' : cat.name;
        return DropdownMenuItem(value: cat.id, child: Text(label));
      }).toList(),
      onChanged: (id) {
        setState(() {
          _selectedCategory = cats.where((c) => c.id == id).firstOrNull;
        });
      },
    );
  }

  Widget _buildAccountPicker(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _type == TransactionType.transfer ? l10n.financeFromAccount : l10n.financeAccount,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedAccount?.id,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: widget.accounts
              .map((a) => DropdownMenuItem(
                    value: a.id,
                    child: _buildAccountLabel(a),
                  ))
              .toList(),
          onChanged: (id) {
            setState(() {
              _selectedAccount =
                  widget.accounts.where((a) => a.id == id).firstOrNull;
              if (_selectedAccount != null) {
                _currency = _selectedAccount!.currency;
              }
            });
          },
        ),
        if (_type == TransactionType.transfer) ...[
          const SizedBox(height: 12),
          Text(l10n.financeToAccount, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedToAccount?.id,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: widget.accounts
                .map((a) => DropdownMenuItem(
                      value: a.id,
                      child: _buildAccountLabel(a),
                    ))
                .toList(),
            onChanged: (id) {
              setState(() {
                _selectedToAccount =
                    widget.accounts.where((a) => a.id == id).firstOrNull;
              });
            },
          ),
        ],
      ],
    );
  }
}

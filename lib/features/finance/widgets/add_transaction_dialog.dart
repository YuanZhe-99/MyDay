import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/image_service.dart';
import '../../../shared/widgets/unsaved_changes_guard.dart';
import '../models/finance.dart';
import '../services/balance_util.dart';

class AddTransactionDialog extends StatefulWidget {
  final List<Category> categories;
  final List<Account> accounts;
  final Transaction? transaction;
  final String? currentSnapshotId;
  final String defaultCurrency;

  /// Purpose: Create a add transaction dialog instance.
  /// Inputs: `categories`.
  /// Returns: A new `AddTransactionDialog` instance.
  /// Side effects: None.
  /// Notes: None.
  const AddTransactionDialog({
    super.key,
    this.categories = const [],
    this.accounts = const [],
    this.transaction,
    this.currentSnapshotId,
    this.defaultCurrency = 'CNY',
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
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
  late final String _initialSignature;

  /// Purpose: Return is editing.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  bool get _isEditing => widget.transaction != null;
  /// Purpose: Return is cross currency.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  bool get _isCrossCurrency =>
      _type == TransactionType.transfer &&
      _selectedAccount != null &&
      _selectedToAccount != null &&
      _selectedAccount!.currency != _selectedToAccount!.currency;

  static const _symbols = <String, String>{
    'CNY': '¥',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'TWD': 'NT\$',
    'HKD': 'HK\$',
    'SGD': 'S\$',
    'KRW': '₩',
    'CHF': 'Fr',
    'NZD': 'NZ\$',
    'INR': '₹',
  };

  /// Purpose: Return currency items.
  /// Inputs: None.
  /// Returns: `List<DropdownMenuItem<String>>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<DropdownMenuItem<String>> get _currencyItems {
    final codes = [
      'CNY',
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'CAD',
      'AUD',
      'TWD',
      'HKD',
      'SGD',
      'KRW',
      'CHF',
      'NZD',
      'INR',
    ];
    if (!codes.contains(_currency)) codes.insert(0, _currency);
    return codes
        .map(
          (c) => DropdownMenuItem(
            value: c,
            child: Text('$c ${_symbols[c] ?? ''}'),
          ),
        )
        .toList();
  }

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
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
    _currency =
        tx?.currency ??
        widget.accounts.firstOrNull?.currency ??
        widget.defaultCurrency;
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
    _initialSignature = _signature();
  }

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Releases owned resources and unregisters listeners.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    _amountController.dispose();
    _toAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Purpose: Provide the internal open calc keyboard helper for this file.
  /// Inputs: `controller`, `label`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _openCalcKeyboard(
    TextEditingController controller,
    String label,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CalcKeyboard(initial: controller.text, label: label),
    );
    if (result != null) setState(() => controller.text = result);
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

    return UnsavedChangesGuard(
      hasUnsavedChanges: _hasUnsavedChanges,
      builder: (context, guard) => Dialog(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing
                    ? l10n.financeEditTransaction
                    : l10n.financeAddTransaction,
                style: theme.textTheme.titleLarge,
              ),
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
                readOnly: true,
                onTap: () =>
                    _openCalcKeyboard(_amountController, l10n.financeAmount),
                decoration: InputDecoration(
                  labelText: l10n.financeAmount,
                  prefixText: '${currencySymbol(_currency)} ',
                  prefixStyle: TextStyle(color: theme.colorScheme.onSurface),
                  suffixIcon: const Icon(Icons.calculate_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 12),

              // Currency picker
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: InputDecoration(
                  labelText: l10n.financeCurrency,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
                  readOnly: true,
                  onTap: () => _openCalcKeyboard(
                    _toAmountController,
                    l10n.financeReceivedAmount(_selectedToAccount!.currency),
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.financeReceivedAmount(
                      _selectedToAccount!.currency,
                    ),
                    prefixText:
                        '${currencySymbol(_selectedToAccount!.currency)} ',
                    prefixStyle: TextStyle(color: theme.colorScheme.onSurface),
                    helperText: l10n.financeReceivedAmountHelper,
                    suffixIcon: const Icon(Icons.calculate_outlined, size: 18),
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
                onSubmitted: (_) => _submit(guard),
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
                    onPressed: () => guard.maybeDiscardAndPop(),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _submit(guard),
                    child: Text(_isEditing ? l10n.commonSave : l10n.commonAdd),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Purpose: Provide the internal build account label helper for this file.
  /// Inputs: `a`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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
                CircleAvatar(
                  backgroundImage: FileImage(snap.data!),
                  radius: 12,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${a.name} (${a.bankOrApp})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }
          return Text(label, overflow: TextOverflow.ellipsis);
        },
      );
    }
    return Text(label, overflow: TextOverflow.ellipsis);
  }

  /// Purpose: Provide the internal has unsaved changes helper for this file.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  bool _hasUnsavedChanges() => _signature() != _initialSignature;

  /// Purpose: Provide the internal signature helper for this file.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _signature() => formSignature([
    _amountController.text.trim(),
    _toAmountController.text.trim(),
    _noteController.text.trim(),
    _type.name,
    _date,
    _currency,
    _selectedCategory?.id,
    _selectedAccount?.id,
    _selectedToAccount?.id,
  ]);

  /// Purpose: Provide the internal submit helper for this file.
  /// Inputs: `guard`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _submit(UnsavedChangesController guard) {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final accountId =
        _selectedAccount?.id ?? widget.transaction?.accountId ?? '';
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
    guard.pop(tx);
  }

  /// Purpose: Return filtered categories.
  /// Inputs: None.
  /// Returns: `List<Category>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Category> get _filteredCategories =>
      widget.categories.where((c) => c.type == _type).toList();

  /// Purpose: Provide the internal build category picker helper for this file.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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

  /// Purpose: Provide the internal build account picker helper for this file.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildAccountPicker(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _type == TransactionType.transfer
              ? l10n.financeFromAccount
              : l10n.financeAccount,
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
              .map(
                (a) =>
                    DropdownMenuItem(value: a.id, child: _buildAccountLabel(a)),
              )
              .toList(),
          onChanged: (id) {
            setState(() {
              _selectedAccount = widget.accounts
                  .where((a) => a.id == id)
                  .firstOrNull;
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: widget.accounts
                .map(
                  (a) => DropdownMenuItem(
                    value: a.id,
                    child: _buildAccountLabel(a),
                  ),
                )
                .toList(),
            onChanged: (id) {
              setState(() {
                _selectedToAccount = widget.accounts
                    .where((a) => a.id == id)
                    .firstOrNull;
              });
            },
          ),
        ],
      ],
    );
  }
}

// ── Calculator keyboard ──────────────────────────────────────────────────────

class _CalcKeyboard extends StatefulWidget {
  final String initial;
  final String label;

  /// Purpose: Create a calc keyboard instance.
  /// Inputs: `initial`.
  /// Returns: A new `_CalcKeyboard` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _CalcKeyboard({this.initial = '', required this.label});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<_CalcKeyboard> createState() => _CalcKeyboardState();
}

class _CalcKeyboardState extends State<_CalcKeyboard> {
  late String _expr;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    _expr = widget.initial;
  }

  /// Purpose: Provide the internal append helper for this file.
  /// Inputs: `s`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _append(String s) => setState(() => _expr += s);

  /// Purpose: Provide the internal backspace helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _backspace() => setState(() {
    if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
  });

  /// Purpose: Provide the internal clear helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _clear() => setState(() => _expr = '');

  /// Purpose: Provide the internal confirm helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _confirm() {
    final result = _evalExpr(_expr);
    if (result != null && result > 0) {
      Navigator.pop(context, result.toStringAsFixed(2));
    } else {
      final direct = double.tryParse(_expr);
      if (direct != null && direct > 0) {
        Navigator.pop(context, direct.toStringAsFixed(2));
      }
    }
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _evalExpr(_expr);
    final showPreview =
        preview != null &&
        _expr.isNotEmpty &&
        double.tryParse(_expr) == null; // only when it's an expression

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _expr.isEmpty ? '0' : _expr,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
                if (showPreview)
                  Text(
                    '= ${preview.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Button grid
          ...[
            ['7', '8', '9', '÷'],
            ['4', '5', '6', '×'],
            ['1', '2', '3', '-'],
            ['.', '0', '⌫', '+'],
          ].map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: row.asMap().entries.map((e) {
                  final label = e.value;
                  final isOp = '÷×-+'.contains(label);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: e.key == 0 ? 0 : 8),
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isOp
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            side: BorderSide(
                              color: isOp
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    )
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          onPressed: () {
                            if (label == '⌫') {
                              _backspace();
                            } else {
                              _append(label);
                            }
                          },
                          child: Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isOp
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Bottom row: clear + confirm
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.4),
                      ),
                    ),
                    onPressed: _clear,
                    child: const Text(
                      'C',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _confirm,
                    child: const Text(
                      '=',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Expression evaluator ─────────────────────────────────────────────────────

/// Purpose: Provide the internal eval expr helper for this file.
/// Inputs: `expr`.
/// Returns: `double?`.
/// Side effects: May update UI state or trigger user-facing flows.
/// Notes: Internal helper used within this file only.
double? _evalExpr(String expr) {
  expr = expr.trim().replaceAll('×', '*').replaceAll('÷', '/');
  if (expr.isEmpty) return null;
  try {
    return _ExprParser(expr).parse();
  } catch (_) {
    return null;
  }
}

class _ExprParser {
  final String src;
  int _pos = 0;

  /// Purpose: Create a expr parser instance.
  /// Inputs: `src`.
  /// Returns: A new `_ExprParser` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  _ExprParser(this.src);

  /// Purpose: Implement the parse behavior for this file.
  /// Inputs: None.
  /// Returns: `double`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  double parse() {
    final v = _parseAddSub();
    if (_pos != src.length) throw const FormatException('unexpected char');
    return v;
  }

  /// Purpose: Provide the internal parse add sub helper for this file.
  /// Inputs: None.
  /// Returns: `double`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  double _parseAddSub() {
    var v = _parseMulDiv();
    while (_pos < src.length && (src[_pos] == '+' || src[_pos] == '-')) {
      final op = src[_pos++];
      final r = _parseMulDiv();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  /// Purpose: Provide the internal parse mul div helper for this file.
  /// Inputs: None.
  /// Returns: `double`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  double _parseMulDiv() {
    var v = _parseNumber();
    while (_pos < src.length && (src[_pos] == '*' || src[_pos] == '/')) {
      final op = src[_pos++];
      final r = _parseNumber();
      if (op == '/' && r == 0) throw const FormatException('div by zero');
      v = op == '*' ? v * r : v / r;
    }
    return v;
  }

  /// Purpose: Provide the internal parse number helper for this file.
  /// Inputs: None.
  /// Returns: `double`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  double _parseNumber() {
    final start = _pos;
    // Allow leading minus for unary negation only at start of expression
    if (_pos < src.length && src[_pos] == '-' && start == 0) _pos++;
    while (_pos < src.length) {
      final c = src[_pos];
      if ((c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) || c == '.') {
        _pos++;
      } else {
        break;
      }
    }
    if (_pos == start) throw const FormatException('expected number');
    return double.parse(src.substring(start, _pos));
  }
}

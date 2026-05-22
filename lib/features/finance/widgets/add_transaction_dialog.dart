import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/image_service.dart';
import '../../../shared/widgets/unsaved_changes_guard.dart';
import '../models/finance.dart';
import '../services/account_picker_util.dart';
import '../services/balance_util.dart';

class AddTransactionDialog extends StatefulWidget {
  final List<Category> categories;
  final List<Account> accounts;
  final Transaction? transaction;
  final String? currentSnapshotId;
  final String defaultCurrency;
  final String? initialAccountId;
  final String? initialCategoryId;
  final TransactionType? initialType;
  final AccountPickerSettings accountPickerSettings;

  /// Purpose: Create a add transaction dialog instance.
  /// Inputs: `categories`, optional initial values, and account picker settings.
  /// Returns: A new `AddTransactionDialog` instance.
  /// Side effects: None.
  /// Notes: Initial values are used only when adding a new transaction.
  const AddTransactionDialog({
    super.key,
    this.categories = const [],
    this.accounts = const [],
    this.transaction,
    this.currentSnapshotId,
    this.defaultCurrency = 'CNY',
    this.initialAccountId,
    this.initialCategoryId,
    this.initialType,
    this.accountPickerSettings = const AccountPickerSettings(),
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
  bool _showMoreAccounts = false;
  late final String _initialSignature;

  static const _moreAccountsValue = '__finance_account_picker_more__';

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
  /// Notes: Prefers edited values, then caller-provided initial selections, then normal defaults.
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
    _date = tx?.date ?? DateTime.now();
    final initialCategoryId =
        tx?.categoryId ?? (tx == null ? widget.initialCategoryId : null);
    if (initialCategoryId != null) {
      _selectedCategory = widget.categories
          .where((c) => c.id == initialCategoryId)
          .firstOrNull;
    }
    _type =
        tx?.type ??
        _selectedCategory?.type ??
        widget.initialType ??
        TransactionType.expense;
    if (_selectedCategory?.type != _type) _selectedCategory = null;
    if (tx?.accountId != null) {
      _selectedAccount = widget.accounts
          .where((a) => a.id == tx!.accountId)
          .firstOrNull;
    }
    _selectedAccount ??= widget.initialAccountId != null
        ? widget.accounts
              .where((a) => a.id == widget.initialAccountId)
              .firstOrNull
        : null;
    _selectedAccount ??= _firstSelectableAccount();
    _currency =
        tx?.currency ?? _selectedAccount?.currency ?? widget.defaultCurrency;
    if (tx?.toAccountId != null) {
      _selectedToAccount = widget.accounts
          .where((a) => a.id == tx!.toAccountId)
          .firstOrNull;
    }
    _showMoreAccounts =
        (_selectedAccount != null && _isMoreAccount(_selectedAccount!)) ||
        (_selectedToAccount != null && _isMoreAccount(_selectedToAccount!));
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

  /// Purpose: Change the transaction flow type and keep dependent selections valid.
  /// Inputs: `type`.
  /// Returns: None.
  /// Side effects: Updates dialog state.
  /// Notes: Clears a selected category when it belongs to a different transaction type.
  void _setType(TransactionType type) {
    setState(() {
      _type = type;
      if (_selectedCategory?.type != type) _selectedCategory = null;
    });
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
                onSelectionChanged: (set) => _setType(set.first),
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

  /// Purpose: Return accounts sorted for the current transaction picker settings.
  /// Inputs: None.
  /// Returns: `List<Account>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Account> get _sortedAccountsForPicker =>
      sortAccountsForPicker(widget.accounts, widget.accountPickerSettings);

  /// Purpose: Return whether an account is configured under the More section.
  /// Inputs: `account`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  bool _isMoreAccount(Account account) =>
      widget.accountPickerSettings.moreAccountIds.contains(account.id);

  /// Purpose: Pick the default account for a new transaction.
  /// Inputs: None.
  /// Returns: `Account?`.
  /// Side effects: None.
  /// Notes: Prefers accounts outside More, then falls back to the first sorted account.
  Account? _firstSelectableAccount() {
    final sorted = _sortedAccountsForPicker;
    return sorted.where((account) => !_isMoreAccount(account)).firstOrNull ??
        sorted.firstOrNull;
  }

  /// Purpose: Return the localized label for an account type.
  /// Inputs: `type`, `l10n`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  String _accountTypeLabel(AccountType type, AppLocalizations l10n) {
    return switch (type) {
      AccountType.fund => l10n.financeAccountTypeFund,
      AccountType.credit => l10n.financeAccountTypeCredit,
      AccountType.recharge => l10n.financeAccountTypeRecharge,
      AccountType.financial => l10n.financeAccountTypeFinancial,
    };
  }

  /// Purpose: Build account dropdown items with optional type and More sections.
  /// Inputs: `theme`, `l10n`.
  /// Returns: `List<DropdownMenuItem<String>>`.
  /// Side effects: Creates UI widgets from current picker state.
  /// Notes: Hidden More accounts are omitted until the More item is selected.
  List<DropdownMenuItem<String>> _accountDropdownItems(
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final settings = widget.accountPickerSettings;
    final moreIds = settings.moreAccountIds.toSet();
    final primary = <Account>[];
    final more = <Account>[];
    for (final account in _sortedAccountsForPicker) {
      if (moreIds.contains(account.id)) {
        more.add(account);
      } else {
        primary.add(account);
      }
    }

    final items = <DropdownMenuItem<String>>[];

    /// Purpose: Add a disabled section header to the dropdown item list.
    /// Inputs: `value`, `label`.
    /// Returns: None.
    /// Side effects: Mutates the local `items` list.
    /// Notes: Internal helper used within this function only.
    void addHeader(String value, String label) {
      items.add(
        DropdownMenuItem(
          value: value,
          enabled: false,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    /// Purpose: Add selectable accounts to the dropdown item list.
    /// Inputs: `accounts`, `sectionKey`.
    /// Returns: None.
    /// Side effects: Mutates the local `items` list.
    /// Notes: Adds type headers when the settings request type grouping.
    void addAccounts(List<Account> accounts, String sectionKey) {
      AccountType? currentType;
      for (final account in accounts) {
        if (settings.groupByType && currentType != account.type) {
          currentType = account.type;
          addHeader(
            '__finance_account_header_${sectionKey}_${account.type.name}',
            _accountTypeLabel(account.type, l10n),
          );
        }
        items.add(
          DropdownMenuItem(
            value: account.id,
            child: _buildAccountLabel(account),
          ),
        );
      }
    }

    addAccounts(primary, 'primary');
    if (more.isNotEmpty) {
      if (_showMoreAccounts) {
        addHeader(
          '__finance_account_header_more',
          l10n.financeAccountPickerMore,
        );
        addAccounts(more, 'more');
      } else {
        items.add(
          DropdownMenuItem(
            value: _moreAccountsValue,
            child: Text(l10n.financeAccountPickerShowMore(more.length)),
          ),
        );
      }
    }
    return items;
  }

  /// Purpose: Apply account dropdown selection changes.
  /// Inputs: `id`, `isTarget`.
  /// Returns: None.
  /// Side effects: Updates selected accounts, currency, and More expansion state.
  /// Notes: The More sentinel expands the list without selecting an account.
  void _selectAccount(String? id, {required bool isTarget}) {
    if (id == null) return;
    if (id == _moreAccountsValue) {
      setState(() => _showMoreAccounts = true);
      return;
    }
    final account = widget.accounts.where((a) => a.id == id).firstOrNull;
    if (account == null) return;
    setState(() {
      if (isTarget) {
        _selectedToAccount = account;
      } else {
        _selectedAccount = account;
        _currency = account.currency;
      }
      if (_isMoreAccount(account)) _showMoreAccounts = true;
    });
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
    final selectedCategoryId =
        cats.any((cat) => cat.id == _selectedCategory?.id)
        ? _selectedCategory?.id
        : null;

    return DropdownButtonFormField<String>(
      key: ValueKey(_type),
      initialValue: selectedCategoryId,
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
          key: ValueKey('from-account-more-$_showMoreAccounts'),
          initialValue: _selectedAccount?.id,
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _accountDropdownItems(theme, l10n),
          onChanged: (id) => _selectAccount(id, isTarget: false),
        ),
        if (_type == TransactionType.transfer) ...[
          const SizedBox(height: 12),
          Text(l10n.financeToAccount, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('to-account-more-$_showMoreAccounts'),
            initialValue: _selectedToAccount?.id,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: _accountDropdownItems(theme, l10n),
            onChanged: (id) => _selectAccount(id, isTarget: true),
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/image_service.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../models/finance.dart';
import '../services/balance_util.dart';
import '../services/bank_preset_service.dart';
import '../services/exchange_rate_storage.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/bank_preset_picker.dart';
import '../widgets/grouped_transaction_list.dart';

class AccountsPage extends StatefulWidget {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Category> categories;
  final ExchangeRateData rateData;
  final Map<String, String> sortModes;
  final Map<String, List<String>> customOrders;
  final void Function(List<Account>) onChanged;
  final void Function(List<Transaction>) onTransactionsChanged;
  final void Function(
    Map<String, String> sortModes,
    Map<String, List<String>> customOrders,
  )?
  onSortChanged;

  const AccountsPage({
    super.key,
    required this.accounts,
    required this.transactions,
    required this.categories,
    required this.rateData,
    this.sortModes = const {},
    this.customOrders = const {},
    required this.onChanged,
    required this.onTransactionsChanged,
    this.onSortChanged,
  });

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  late List<Account> _accounts;
  late List<Transaction> _transactions;
  late Map<String, String> _sortModes;
  late Map<String, List<String>> _customOrders;
  final Map<String, bool> _reordering = {};

  static const _sortName = 'name';
  static const _sortBank = 'bank';
  static const _sortCustom = 'custom';

  @override
  void initState() {
    super.initState();
    _accounts = List.of(widget.accounts);
    _transactions = List.of(widget.transactions);
    _sortModes = Map.of(widget.sortModes);
    _customOrders = widget.customOrders.map(
      (key, value) => MapEntry(key, List<String>.of(value)),
    );
  }

  void _notifyAccounts() => widget.onChanged(_accounts);
  void _notifyTransactions() => widget.onTransactionsChanged(_transactions);
  void _notifySort() => widget.onSortChanged?.call(_sortModes, _customOrders);

  String _typeKey(AccountType type) => type.name;

  String _sortMode(AccountType type) =>
      _sortModes[_typeKey(type)] ?? _sortCustom;

  int _compareText(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  List<String> _normalizedOrder(AccountType type) {
    final key = _typeKey(type);
    final allIds = _accounts
        .where((account) => account.type == type)
        .map((account) => account.id)
        .toList();
    final allIdSet = allIds.toSet();
    final seen = <String>{};
    final normalized = <String>[
      for (final id in _customOrders[key] ?? const <String>[])
        if (allIdSet.contains(id) && seen.add(id)) id,
    ];
    for (final id in allIds) {
      if (seen.add(id)) normalized.add(id);
    }
    return normalized;
  }

  List<MapEntry<int, Account>> _sortEntries(
    AccountType type,
    List<MapEntry<int, Account>> entries,
  ) {
    final list = List<MapEntry<int, Account>>.of(entries);
    switch (_sortMode(type)) {
      case _sortName:
        list.sort((a, b) {
          final byName = _compareText(a.value.name, b.value.name);
          return byName != 0
              ? byName
              : _compareText(a.value.bankOrApp, b.value.bankOrApp);
        });
      case _sortBank:
        list.sort((a, b) {
          final byBank = _compareText(a.value.bankOrApp, b.value.bankOrApp);
          return byBank != 0
              ? byBank
              : _compareText(a.value.name, b.value.name);
        });
      case _sortCustom:
      default:
        final order = _normalizedOrder(type);
        final fallbackIndex = order.length;
        list.sort((a, b) {
          final ai = order.indexOf(a.value.id);
          final bi = order.indexOf(b.value.id);
          final byOrder = (ai == -1 ? fallbackIndex : ai).compareTo(
            bi == -1 ? fallbackIndex : bi,
          );
          return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
        });
    }
    return list;
  }

  void _setSortMode(AccountType type, String mode) {
    final key = _typeKey(type);
    setState(() {
      if (mode == _sortCustom && !_customOrders.containsKey(key)) {
        final entries = <MapEntry<int, Account>>[];
        for (var i = 0; i < _accounts.length; i++) {
          if (_accounts[i].type == type) entries.add(MapEntry(i, _accounts[i]));
        }
        _customOrders[key] = _sortEntries(
          type,
          entries,
        ).map((entry) => entry.value.id).toList();
      }
      _sortModes[key] = mode;
      if (mode == _sortCustom) {
        _customOrders[key] = _normalizedOrder(type);
      } else {
        _reordering[key] = false;
      }
    });
    _notifySort();
  }

  void _appendAccountToCustomOrderIfNeeded(Account account) {
    if (_sortMode(account.type) != _sortCustom) return;
    _customOrders[_typeKey(account.type)] = _normalizedOrder(account.type);
  }

  void _removeAccountFromCustomOrders(String accountId) {
    for (final entry in _customOrders.entries) {
      entry.value.remove(accountId);
    }
  }

  void _reorderAccounts(
    AccountType type,
    List<MapEntry<int, Account>> entries,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex--;
    final key = _typeKey(type);
    final ids = entries.map((entry) => entry.value.id).toList();
    if (oldIndex < 0 ||
        oldIndex >= ids.length ||
        newIndex < 0 ||
        newIndex > ids.length) {
      return;
    }
    final reordered = List<String>.of(ids);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    setState(() {
      _customOrders[key] = reordered;
      _sortModes[key] = _sortCustom;
    });
    _notifySort();
  }

  Future<void> _addAccount() async {
    final account = await showDialog<Account>(
      context: context,
      builder: (_) => const _AccountDialog(),
    );
    if (account != null) {
      setState(() => _accounts.add(account));
      _appendAccountToCustomOrderIfNeeded(account);
      _notifyAccounts();
      _notifySort();
    }
  }

  Future<void> _editAccount(int index) async {
    final oldAccount = _accounts[index];
    final l10n = AppLocalizations.of(context)!;
    final account = await showDialog<Account>(
      context: context,
      builder: (_) => _AccountDialog(account: oldAccount),
    );
    if (!mounted) return;
    if (account != null) {
      // If forced balance changed, create an adjustment transaction
      if (account.forcedBalance != null &&
          account.forcedBalance != oldAccount.forcedBalance) {
        final oldBalance = accountBalance(
          oldAccount,
          _transactions,
          widget.rateData,
        );
        final delta = account.forcedBalance! - oldBalance;
        if (delta != 0) {
          final adjTx = Transaction(
            type: delta > 0 ? TransactionType.income : TransactionType.expense,
            amount: delta.abs(),
            currency: account.currency,
            rateSnapshotId: widget.rateData.currentSnapshotId,
            accountId: account.id,
            note: l10n.financeBalanceAdjustment,
            date: account.forcedBalanceDate ?? DateTime.now(),
          );
          setState(() {
            _transactions.insert(0, adjTx);
          });
          _notifyTransactions();
        }
      }
      setState(() => _accounts[index] = account);
      if (oldAccount.type != account.type) {
        _removeAccountFromCustomOrders(account.id);
        _appendAccountToCustomOrderIfNeeded(account);
      }
      _notifyAccounts();
      _notifySort();
    }
  }

  void _deleteAccount(int index) {
    final accountId = _accounts[index].id;
    setState(() => _accounts.removeAt(index));
    _removeAccountFromCustomOrders(accountId);
    _notifyAccounts();
    _notifySort();
  }

  void _deleteTransaction(Transaction tx) {
    setState(() => _transactions.removeWhere((t) => t.id == tx.id));
    _notifyTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final grouped = <AccountType, List<MapEntry<int, Account>>>{};
    for (var i = 0; i < _accounts.length; i++) {
      grouped.putIfAbsent(_accounts[i].type, () => []);
      grouped[_accounts[i].type]!.add(MapEntry(i, _accounts[i]));
    }
    final sortedGrouped = {
      for (final entry in grouped.entries)
        entry.key: _sortEntries(entry.key, entry.value),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.financeAccounts),
        centerTitle: true,
      ),
      body: _accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.financeNoAccounts,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                for (final type in AccountType.values)
                  if (grouped.containsKey(type)) ...[
                    _buildSectionHeader(type, sortedGrouped[type]!),
                    if (_reordering[_typeKey(type)] == true &&
                        _sortMode(type) == _sortCustom)
                      _buildReorderList(type, sortedGrouped[type]!)
                    else
                      ...sortedGrouped[type]!.map(
                        (entry) => Dismissible(
                          key: ValueKey(entry.value.id),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            color: theme.colorScheme.primary,
                            child: Icon(
                              Icons.edit_outlined,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: theme.colorScheme.error,
                            child: Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.onError,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              _editAccount(entry.key);
                              return false;
                            }
                            return confirmDelete(
                              context,
                              AppLocalizations.of(context)!.financeThisAccount,
                            );
                          },
                          onDismissed: (_) => _deleteAccount(entry.key),
                          child: ListTile(
                            leading: _buildAccountAvatar(entry.value, theme),
                            title: Text(entry.value.name),
                            subtitle: Text(
                              '${entry.value.bankOrApp}  •  ${entry.value.currency}',
                            ),
                            trailing: Text(
                              '${currencySymbol(entry.value.currency)}${NumberFormat('#,##0.00').format(accountBalance(entry.value, _transactions, widget.rateData))}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _AccountTransactionsPage(
                                  account: entry.value,
                                  transactions: _transactions,
                                  categories: widget.categories,
                                  rateData: widget.rateData,
                                  onEdit: (updated) {
                                    setState(() {
                                      final i = _transactions.indexWhere(
                                        (t) => t.id == updated.id,
                                      );
                                      if (i != -1) _transactions[i] = updated;
                                    });
                                    _notifyTransactions();
                                  },
                                  onDelete: _deleteTransaction,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(
    AccountType type,
    List<MapEntry<int, Account>> entries,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final key = _typeKey(type);
    final isCustom = _sortMode(type) == _sortCustom;
    final isReordering = _reordering[key] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Text(
            _accountTypeLabel(type),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entries.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (isCustom && entries.length > 1)
            IconButton(
              icon: Icon(isReordering ? Icons.check : Icons.reorder),
              tooltip: isReordering
                  ? l10n.financeSortDone
                  : l10n.financeSortReorder,
              onPressed: () => setState(() {
                _reordering[key] = !isReordering;
              }),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.financeSortBy,
            onSelected: (mode) => _setSortMode(type, mode),
            itemBuilder: (_) => [
              _sortMenuItem(
                type: type,
                value: _sortName,
                label: l10n.financeSortByName,
              ),
              _sortMenuItem(
                type: type,
                value: _sortBank,
                label: l10n.financeSortByBank,
              ),
              _sortMenuItem(
                type: type,
                value: _sortCustom,
                label: l10n.financeSortCustom,
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuEntry<String> _sortMenuItem({
    required AccountType type,
    required String value,
    required String label,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            _sortMode(type) == value
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildReorderList(
    AccountType type,
    List<MapEntry<int, Account>> entries,
  ) {
    final theme = Theme.of(context);
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: entries.length,
      onReorder: (oldIndex, newIndex) {
        _reorderAccounts(type, entries, oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return Material(elevation: 4, child: child);
      },
      itemBuilder: (context, index) {
        final account = entries[index].value;
        return ListTile(
          key: ValueKey('account-reorder-${account.id}'),
          leading: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle),
          ),
          title: Text(account.name),
          subtitle: Text('${account.bankOrApp}  â€¢  ${account.currency}'),
          trailing: Text(
            '${currencySymbol(account.currency)}${NumberFormat('#,##0.00').format(accountBalance(account, _transactions, widget.rateData))}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  String _accountTypeLabel(AccountType type) {
    final l10n = AppLocalizations.of(context)!;
    return switch (type) {
      AccountType.fund => l10n.financeAccountTypeFund,
      AccountType.credit => l10n.financeAccountTypeCredit,
      AccountType.recharge => l10n.financeAccountTypeRecharge,
      AccountType.financial => l10n.financeAccountTypeFinancial,
    };
  }

  IconData _accountTypeIcon(AccountType type) => switch (type) {
    AccountType.fund => Icons.savings,
    AccountType.credit => Icons.credit_card,
    AccountType.recharge => Icons.phone_android,
    AccountType.financial => Icons.trending_up,
  };

  Color _accountTypeColor(AccountType type) => switch (type) {
    AccountType.fund => Colors.blue,
    AccountType.credit => Colors.orange,
    AccountType.recharge => Colors.green,
    AccountType.financial => Colors.purple,
  };

  Widget _buildAccountAvatar(Account account, ThemeData theme) {
    final color = _accountTypeColor(account.type);
    if (account.imagePath != null) {
      return FutureBuilder<File>(
        future: ImageService.resolve(account.imagePath!),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.existsSync()) {
            return CircleAvatar(
              backgroundImage: FileImage(snap.data!),
              backgroundColor: color.withValues(alpha: 0.15),
            );
          }
          return CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: account.emoji != null
                ? Text(account.emoji!, style: const TextStyle(fontSize: 18))
                : Icon(_accountTypeIcon(account.type), color: color, size: 20),
          );
        },
      );
    }
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: account.emoji != null
          ? Text(account.emoji!, style: const TextStyle(fontSize: 18))
          : Icon(_accountTypeIcon(account.type), color: color, size: 20),
    );
  }
}

// --------------- Account Transactions Page ---------------

class _AccountTransactionsPage extends StatefulWidget {
  final Account account;
  final List<Transaction> transactions;
  final List<Category> categories;
  final ExchangeRateData rateData;
  final void Function(Transaction) onEdit;
  final void Function(Transaction) onDelete;

  const _AccountTransactionsPage({
    required this.account,
    required this.transactions,
    required this.categories,
    required this.rateData,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_AccountTransactionsPage> createState() =>
      _AccountTransactionsPageState();
}

class _AccountTransactionsPageState extends State<_AccountTransactionsPage> {
  late List<Transaction> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = List.of(widget.transactions);
  }

  void _handleDelete(Transaction tx) {
    setState(() => _transactions.removeWhere((t) => t.id == tx.id));
    widget.onDelete(tx);
  }

  Future<void> _handleEdit(Transaction tx) async {
    final updated = await showDialog<Transaction>(
      context: context,
      builder: (_) => AddTransactionDialog(
        categories: widget.categories,
        accounts: [widget.account],
        transaction: tx,
        currentSnapshotId: widget.rateData.currentSnapshotId,
      ),
    );
    if (updated != null) {
      setState(() {
        final i = _transactions.indexWhere((t) => t.id == updated.id);
        if (i != -1) _transactions[i] = updated;
      });
      widget.onEdit(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final filtered =
        _transactions
            .where(
              (tx) =>
                  tx.accountId == widget.account.id ||
                  tx.toAccountId == widget.account.id,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final balance = accountBalance(
      widget.account,
      _transactions,
      widget.rateData,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.account.name), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.financeBalance,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '${currencySymbol(widget.account.currency)}${NumberFormat('#,##0.00').format(balance)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: balance >= 0
                            ? Colors.green
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      l10n.financeNoTransactions,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : buildGroupedTransactionList(context, filtered, (tx) {
                    final isExpense = tx.type == TransactionType.expense;
                    final isTransfer = tx.type == TransactionType.transfer;
                    final sign = isExpense ? '-' : (isTransfer ? '' : '+');
                    final color = isExpense
                        ? theme.colorScheme.error
                        : Colors.green;
                    final dateStr = DateFormat('MM-dd HH:mm').format(tx.date);

                    final cat = tx.categoryId != null
                        ? widget.categories
                              .where((c) => c.id == tx.categoryId)
                              .firstOrNull
                        : null;
                    final catLabel = cat != null
                        ? (cat.emoji != null
                              ? '${cat.emoji} ${cat.name}'
                              : cat.name)
                        : null;

                    final typeLabel = switch (tx.type) {
                      TransactionType.expense => l10n.financeExpense,
                      TransactionType.income => l10n.financeIncome,
                      TransactionType.transfer => l10n.financeTransfer,
                    };

                    return Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        color: theme.colorScheme.primary,
                        child: Icon(
                          Icons.edit_outlined,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: theme.colorScheme.error,
                        child: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.onError,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _handleEdit(tx);
                          return false;
                        }
                        return confirmDelete(
                          context,
                          l10n.financeThisTransaction,
                        );
                      },
                      onDismissed: (_) => _handleDelete(tx),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.1),
                          child: cat?.emoji != null
                              ? Text(
                                  cat!.emoji!,
                                  style: const TextStyle(fontSize: 18),
                                )
                              : Icon(
                                  isExpense
                                      ? Icons.remove
                                      : isTransfer
                                      ? Icons.swap_horiz
                                      : Icons.add,
                                  color: color,
                                  size: 20,
                                ),
                        ),
                        title: Text(catLabel ?? typeLabel),
                        subtitle: Text(
                          tx.note.isNotEmpty
                              ? '${tx.note}  •  $dateStr'
                              : dateStr,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Text(
                          '$sign${currencySymbol(tx.currency)}${tx.amount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
          ),
        ],
      ),
    );
  }
}

// --------------- Account Dialog ---------------

class _AccountDialog extends StatefulWidget {
  final Account? account;
  const _AccountDialog({this.account});

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final _nameController = TextEditingController();
  final _bankController = TextEditingController();
  final _cardController = TextEditingController();
  final _balanceController = TextEditingController();
  AccountType _type = AccountType.fund;
  String _currency = 'CNY';
  String? _selectedEmoji;
  String? _imagePath;
  DateTime? _forcedBalanceDate;
  BankPreset? _selectedBank;

  static const _baseCurrencies = [
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

  List<String> get _currencies {
    final list = List<String>.from(_baseCurrencies);
    if (!list.contains(_currency)) list.insert(0, _currency);
    return list;
  }

  static const _commonEmojis = [
    '🏦',
    '💳',
    '💰',
    '🏧',
    '📱',
    '💵',
    '💴',
    '💶',
    '💷',
    '🪙',
    '🏠',
    '🚗',
    '✈️',
    '🛍️',
    '🎮',
    '📈',
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _nameController.text = a.name;
      _bankController.text = a.bankOrApp;
      _cardController.text = a.cardNumber ?? '';
      _type = a.type;
      _currency = a.currency;
      _selectedEmoji = a.emoji;
      _imagePath = a.imagePath;
      if (a.forcedBalance != null) {
        _balanceController.text = a.forcedBalance!.toStringAsFixed(2);
        _forcedBalanceDate = a.forcedBalanceDate ?? DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _cardController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.account != null;

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? l10n.financeEditAccount : l10n.financeNewAccount,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Type selector
            SegmentedButton<AccountType>(
              segments: [
                ButtonSegment(
                  value: AccountType.fund,
                  label: Text(l10n.financeAccountTypeFund),
                  icon: const Icon(Icons.savings, size: 16),
                ),
                ButtonSegment(
                  value: AccountType.credit,
                  label: Text(l10n.financeAccountTypeCredit),
                  icon: const Icon(Icons.credit_card, size: 16),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 4),
            SegmentedButton<AccountType>(
              segments: [
                ButtonSegment(
                  value: AccountType.recharge,
                  label: Text(l10n.financeAccountTypeRecharge),
                  icon: const Icon(Icons.phone_android, size: 16),
                ),
                ButtonSegment(
                  value: AccountType.financial,
                  label: Text(l10n.financeAccountTypeFinancial),
                  icon: const Icon(Icons.trending_up, size: 16),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.financeAccountName),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _bankController,
              decoration: InputDecoration(
                labelText: l10n.financeBankApp,
                hintText: l10n.financeBankAppHint,
              ),
            ),
            const SizedBox(height: 12),

            // Currency dropdown
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: InputDecoration(labelText: l10n.financeCurrency),
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _currency = v);
              },
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _cardController,
              decoration: InputDecoration(
                labelText: l10n.financeCardNumber,
                hintText: l10n.financeCardNumberHint,
              ),
            ),
            const SizedBox(height: 16),

            // Emoji picker
            Text(l10n.financeIcon, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            _buildImagePreview(theme, l10n),
            if (_downloadingLogo)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _commonEmojis.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() {
                    _selectedEmoji = isSelected ? null : emoji;
                    if (!isSelected) _imagePath = null;
                  }),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : null,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Forced balance override
            Text(
              l10n.financeForceBalance,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.financeCurrentBalance,
                hintText: l10n.financeCurrentBalanceHint,
                prefixText: '$_currency ',
                prefixStyle: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onChanged: (_) {
                if (_balanceController.text.trim().isNotEmpty &&
                    _forcedBalanceDate == null) {
                  setState(() => _forcedBalanceDate = DateTime.now());
                }
              },
            ),
            if (_balanceController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.calendar_today, size: 18),
                title: Text(
                  _forcedBalanceDate != null
                      ? '${_forcedBalanceDate!.year}-${_forcedBalanceDate!.month.toString().padLeft(2, '0')}-${_forcedBalanceDate!.day.toString().padLeft(2, '0')}'
                      : l10n.financeAsOfToday,
                  style: theme.textTheme.bodySmall,
                ),
                subtitle: Text(l10n.financeBalanceEffectiveDate),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _forcedBalanceDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _forcedBalanceDate = picked);
                  }
                },
              ),
            ],
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

  Widget _buildImagePreview(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imagePath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FutureBuilder<File>(
              future: ImageService.resolve(_imagePath!),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        snap.data!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => setState(() => _imagePath = null),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: theme.colorScheme.onError,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.account_balance, size: 16),
              label: Text(l10n.financeBankPresets),
              onPressed: _pickBankPreset,
            ),
            if (_selectedBank != null &&
                _selectedBank!.domain.isNotEmpty &&
                _imagePath == null &&
                !_downloadingLogo)
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(l10n.financeFetchIcon),
                onPressed: _fetchBankIcon,
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.image_outlined, size: 16),
              label: Text(
                _imagePath != null ? l10n.commonChange : l10n.commonPickImage,
              ),
              onPressed: () async {
                final path = await ImageService.pickAndSaveImage();
                if (path != null) {
                  setState(() {
                    _imagePath = path;
                    _selectedEmoji = null;
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  bool _downloadingLogo = false;

  Future<void> _pickBankPreset() async {
    final bank = await showBankPresetPicker(context);
    if (bank == null || !mounted) return;

    setState(() {
      _bankController.text = bank.localTitle;
      _selectedBank = bank;
      // Auto-set currency from bank country
      final cur = bank.defaultCurrency;
      if (cur != null) _currency = cur;
    });

    // Auto-download logo; if it fails the "Fetch Icon" button will appear
    _fetchBankIcon();
  }

  Future<void> _fetchBankIcon() async {
    final bank = _selectedBank;
    if (bank == null || bank.logoUrls.isEmpty) return;

    setState(() => _downloadingLogo = true);
    String? path;
    for (final url in bank.logoUrls) {
      path = await ImageService.downloadAndSave(url);
      if (path != null) break;
    }
    if (mounted) {
      setState(() {
        _downloadingLogo = false;
        if (path != null) {
          _imagePath = path;
          _selectedEmoji = null;
        }
      });
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    final bank = _bankController.text.trim();
    if (name.isEmpty || bank.isEmpty) return;

    final balanceText = _balanceController.text.trim();
    final forcedBalance = balanceText.isNotEmpty
        ? double.tryParse(balanceText)
        : null;

    final account = Account(
      id: widget.account?.id,
      type: _type,
      bankOrApp: bank,
      name: name,
      currency: _currency,
      cardNumber: _cardController.text.trim().isEmpty
          ? null
          : _cardController.text.trim(),
      emoji: _selectedEmoji,
      imagePath: _imagePath,
      forcedBalance: forcedBalance,
      forcedBalanceDate: forcedBalance != null
          ? (_forcedBalanceDate ?? DateTime.now())
          : null,
    );
    Navigator.pop(context, account);
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/image_service.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../models/finance.dart';
import '../services/balance_util.dart';
import '../services/exchange_rate_storage.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/grouped_transaction_list.dart';

class CategoryDetailPage extends StatefulWidget {
  final String? categoryId;
  final Category? category;
  final TransactionType transactionType;
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<Account> accounts;
  final ExchangeRateData rateData;
  final String defaultCurrency;
  final AccountPickerSettings accountPickerSettings;
  final void Function(List<Transaction>) onTransactionsChanged;

  /// Purpose: Create a category detail page instance.
  /// Inputs: `categoryId`, optional `category`, `transactionType`, picker settings, and callbacks.
  /// Returns: A new `CategoryDetailPage` instance.
  /// Side effects: None.
  /// Notes: A null `categoryId` represents uncategorized transactions for the given type.
  const CategoryDetailPage({
    super.key,
    required this.categoryId,
    this.category,
    required this.transactionType,
    required this.transactions,
    required this.categories,
    required this.accounts,
    required this.rateData,
    required this.defaultCurrency,
    this.accountPickerSettings = const AccountPickerSettings(),
    required this.onTransactionsChanged,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  late List<Transaction> _transactions;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    _transactions = List.of(widget.transactions);
  }

  /// Purpose: Return filtered.
  /// Inputs: None.
  /// Returns: `List<Transaction>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Transaction> get _filtered =>
      _transactions
          .where(
            (t) =>
                t.type == widget.transactionType &&
                t.categoryId == widget.categoryId,
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Purpose: Return month filtered.
  /// Inputs: None.
  /// Returns: `List<Transaction>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Transaction> get _monthFiltered {
    final now = DateTime.now();
    return _filtered
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
  }

  /// Purpose: Return month total.
  /// Inputs: None.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  double get _monthTotal {
    return _monthFiltered.fold(
      0.0,
      (sum, t) =>
          sum +
          convertCurrency(
            widget.rateData.ratesAt(t.rateSnapshotId),
            t.amount,
            t.currency,
            widget.defaultCurrency,
          ),
    );
  }

  /// Purpose: Add a transaction from the category detail view.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Opens a dialog, updates local transaction state, and notifies the parent page.
  /// Notes: Real categories are preselected; uncategorized entries stay uncategorized by default.
  Future<void> _addTransaction() async {
    final tx = await showDialog<Transaction>(
      context: context,
      builder: (_) => AddTransactionDialog(
        categories: widget.categories,
        accounts: widget.accounts,
        initialCategoryId: widget.category?.id,
        initialType: widget.transactionType,
        currentSnapshotId: widget.rateData.currentSnapshotId,
        defaultCurrency: widget.defaultCurrency,
        accountPickerSettings: widget.accountPickerSettings,
      ),
    );
    if (tx != null) {
      setState(() => _transactions.insert(0, tx));
      widget.onTransactionsChanged(_transactions);
    }
  }

  /// Purpose: Provide the internal delete transaction helper for this file.
  /// Inputs: `tx`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _deleteTransaction(Transaction tx) {
    setState(() => _transactions.removeWhere((t) => t.id == tx.id));
    widget.onTransactionsChanged(_transactions);
  }

  /// Purpose: Provide the internal edit transaction helper for this file.
  /// Inputs: `tx`.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _editTransaction(Transaction tx) async {
    final updated = await showDialog<Transaction>(
      context: context,
      builder: (_) => AddTransactionDialog(
        categories: widget.categories,
        accounts: widget.accounts,
        transaction: tx,
        currentSnapshotId: widget.rateData.currentSnapshotId,
        defaultCurrency: widget.defaultCurrency,
        accountPickerSettings: widget.accountPickerSettings,
      ),
    );
    if (updated != null) {
      setState(() {
        final index = _transactions.indexWhere((t) => t.id == updated.id);
        if (index != -1) _transactions[index] = updated;
      });
      widget.onTransactionsChanged(_transactions);
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
    final l10n = AppLocalizations.of(context)!;
    final cat = widget.category;
    final sym = currencySymbol(widget.defaultCurrency);
    final numberFormat = NumberFormat('#,##0.00');
    final isExpense = widget.transactionType == TransactionType.expense;
    final isTransfer = widget.transactionType == TransactionType.transfer;
    final monthLabel = DateFormat('yyyy-MM').format(DateTime.now());
    final typeLabel = switch (widget.transactionType) {
      TransactionType.expense => l10n.financeExpense,
      TransactionType.income => l10n.financeIncome,
      TransactionType.transfer => l10n.financeTransfer,
    };
    final title = cat == null
        ? widget.categoryId ?? l10n.financeUncategorized
        : cat.emoji != null
        ? '${cat.emoji} ${cat.name}'
        : cat.name;
    final totalColor = isExpense
        ? theme.colorScheme.error
        : isTransfer
        ? theme.colorScheme.primary
        : Colors.green;

    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Column(
        children: [
          // Monthly summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Text(
                      monthLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(typeLabel, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      '$sym${numberFormat.format(_monthTotal)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: totalColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // Transaction list
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
                : buildGroupedTransactionList(
                    context,
                    filtered,
                    (tx) => Dismissible(
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
                          _editTransaction(tx);
                          return false;
                        }
                        return confirmDelete(
                          context,
                          l10n.financeThisTransaction,
                        );
                      },
                      onDismissed: (_) => _deleteTransaction(tx),
                      child: _TxTile(
                        transaction: tx,
                        accounts: widget.accounts,
                        defaultCurrency: widget.defaultCurrency,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final Transaction transaction;
  final List<Account> accounts;
  final String defaultCurrency;

  /// Purpose: Create a tx tile instance.
  /// Inputs: None.
  /// Returns: A new `_TxTile` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _TxTile({
    required this.transaction,
    required this.accounts,
    required this.defaultCurrency,
  });

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;
    final dateStr = DateFormat('MM-dd HH:mm').format(transaction.date);
    final sign = isExpense
        ? '-'
        : isTransfer
        ? ''
        : '+';
    final color = isExpense
        ? theme.colorScheme.error
        : isTransfer
        ? theme.colorScheme.primary
        : Colors.green;

    final account = accounts.isNotEmpty
        ? accounts.where((a) => a.id == transaction.accountId).firstOrNull
        : null;

    String? accountLabel;
    if (account != null) {
      accountLabel = account.emoji != null
          ? '${account.emoji} ${account.name}'
          : account.name;
    }

    final subtitleParts = <String>[
      if (transaction.note.isNotEmpty) transaction.note,
      ?accountLabel,
      dateStr,
    ];

    return ListTile(
      leading: _buildLeading(account, color, theme),
      title: Text(transaction.note.isNotEmpty ? transaction.note : dateStr),
      subtitle: Text(
        subtitleParts.join('  •  '),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        '$sign${currencySymbol(transaction.currency)}${transaction.amount.toStringAsFixed(2)}',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Purpose: Provide the internal build leading helper for this file.
  /// Inputs: `account`, `color`, `theme`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildLeading(Account? account, Color color, ThemeData theme) {
    /// Purpose: Build the fallback category transaction avatar.
    /// Inputs: None.
    /// Returns: `Widget`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    Widget defaultAvatar() => CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(
        transaction.type == TransactionType.expense
            ? Icons.remove
            : transaction.type == TransactionType.transfer
            ? Icons.swap_horiz
            : Icons.add,
        color: color,
        size: 20,
      ),
    );

    if (account?.imagePath != null) {
      return FutureBuilder<File>(
        future: ImageService.resolve(account!.imagePath!),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.existsSync()) {
            return CircleAvatar(
              backgroundImage: FileImage(snap.data!),
              backgroundColor: color.withValues(alpha: 0.1),
            );
          }
          return defaultAvatar();
        },
      );
    }
    return defaultAvatar();
  }
}

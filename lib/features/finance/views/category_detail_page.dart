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
  final Category category;
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<Account> accounts;
  final ExchangeRateData rateData;
  final String defaultCurrency;
  final void Function(List<Transaction>) onTransactionsChanged;

  const CategoryDetailPage({
    super.key,
    required this.category,
    required this.transactions,
    required this.categories,
    required this.accounts,
    required this.rateData,
    required this.defaultCurrency,
    required this.onTransactionsChanged,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  late List<Transaction> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = List.of(widget.transactions);
  }

  List<Transaction> get _filtered =>
      _transactions.where((t) => t.categoryId == widget.category.id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<Transaction> get _monthFiltered {
    final now = DateTime.now();
    return _filtered
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
  }

  double get _monthTotal {
    return _monthFiltered.fold(0.0, (sum, t) => sum + convertCurrency(
        widget.rateData.ratesAt(t.rateSnapshotId),
        t.amount,
        t.currency,
        widget.defaultCurrency));
  }

  void _deleteTransaction(Transaction tx) {
    setState(() => _transactions.removeWhere((t) => t.id == tx.id));
    widget.onTransactionsChanged(_transactions);
  }

  Future<void> _editTransaction(Transaction tx) async {
    final updated = await showDialog<Transaction>(
      context: context,
      builder: (_) => AddTransactionDialog(
        categories: widget.categories,
        accounts: widget.accounts,
        transaction: tx,
        currentSnapshotId: widget.rateData.currentSnapshotId,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cat = widget.category;
    final sym = currencySymbol(widget.defaultCurrency);
    final numberFormat = NumberFormat('#,##0.00');
    final isExpense = cat.type == TransactionType.expense;
    final monthLabel = DateFormat('yyyy-MM').format(DateTime.now());
    final typeLabel = isExpense ? l10n.financeExpense : l10n.financeIncome;

    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text(cat.emoji != null ? '${cat.emoji} ${cat.name}' : cat.name),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Monthly summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Text(
                      monthLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      typeLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$sym${numberFormat.format(_monthTotal)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isExpense ? theme.colorScheme.error : Colors.green,
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
                          _editTransaction(tx);
                          return false;
                        }
                        return confirmDelete(context, l10n.financeThisTransaction);
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
    );
  }
}

class _TxTile extends StatelessWidget {
  final Transaction transaction;
  final List<Account> accounts;
  final String defaultCurrency;

  const _TxTile({
    required this.transaction,
    required this.accounts,
    required this.defaultCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.type == TransactionType.expense;
    final dateStr = DateFormat('MM-dd HH:mm').format(transaction.date);
    final sign = isExpense ? '-' : '+';
    final color = isExpense ? theme.colorScheme.error : Colors.green;

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
      title: Text(
        transaction.note.isNotEmpty ? transaction.note : dateStr,
      ),
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

  Widget _buildLeading(Account? account, Color color, ThemeData theme) {
    Widget defaultAvatar() => CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            transaction.type == TransactionType.expense
                ? Icons.remove
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

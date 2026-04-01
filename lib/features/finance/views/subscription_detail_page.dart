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

class SubscriptionDetailPage extends StatefulWidget {
  final Subscription subscription;
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<Account> accounts;
  final ExchangeRateData rateData;
  final String defaultCurrency;
  final void Function(List<Transaction>) onTransactionsChanged;

  const SubscriptionDetailPage({
    super.key,
    required this.subscription,
    required this.transactions,
    required this.categories,
    required this.accounts,
    required this.rateData,
    required this.defaultCurrency,
    required this.onTransactionsChanged,
  });

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  late List<Transaction> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = List.of(widget.transactions);
  }

  List<Transaction> get _filtered =>
      _transactions.where((t) => t.subscriptionId == widget.subscription.id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  double get _totalSpent {
    return _filtered.fold(0.0, (sum, t) => sum + convertCurrency(
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
      // Preserve subscriptionId when editing
      final withSubId = Transaction(
        id: updated.id,
        type: updated.type,
        amount: updated.amount,
        currency: updated.currency,
        rateSnapshotId: updated.rateSnapshotId,
        accountId: updated.accountId,
        toAccountId: updated.toAccountId,
        toAmount: updated.toAmount,
        toCurrency: updated.toCurrency,
        categoryId: updated.categoryId,
        subscriptionId: tx.subscriptionId,
        note: updated.note,
        date: updated.date,
      );
      setState(() {
        final index = _transactions.indexWhere((t) => t.id == withSubId.id);
        if (index != -1) _transactions[index] = withSubId;
      });
      widget.onTransactionsChanged(_transactions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sub = widget.subscription;
    final sym = currencySymbol(widget.defaultCurrency);
    final numberFormat = NumberFormat('#,##0.00');
    final filtered = _filtered;

    // Cycle description
    final cycleLabel = sub.billingCycleType == BillingCycleType.monthly
        ? l10n.financeEveryXMonths(sub.billingInterval)
        : l10n.financeEveryXYears(sub.billingInterval);

    // Next billing / expiry date
    final bool isAtExpiry = sub.cancelType == CancelType.atExpiry;
    final nextDate = isAtExpiry ? sub.nextBillingDate : (sub.isActive ? sub.nextBillingDate : null);
    final nextDateLabel = isAtExpiry ? l10n.financeExpiryDate : l10n.financeNextBilling;

    return Scaffold(
      appBar: AppBar(
        title: Text(sub.emoji != null ? '${sub.emoji} ${sub.name}' : sub.name),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Text(
                      '${currencySymbol(sub.currency)}${sub.amount.toStringAsFixed(2)} / $cycleLabel',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.financeTotalSpent}: $sym${numberFormat.format(_totalSpent)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    if (nextDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$nextDateLabel: ${DateFormat('yyyy-MM-dd').format(nextDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (!sub.isActive && sub.cancelledAt != null && !isAtExpiry) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.financeCancelledOn(DateFormat('yyyy-MM-dd').format(sub.cancelledAt!)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
                        subscription: widget.subscription,
                        categories: widget.categories,
                        accounts: widget.accounts,
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
  final Subscription subscription;
  final List<Category> categories;
  final List<Account> accounts;

  const _TxTile({
    required this.transaction,
    required this.subscription,
    required this.categories,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MM-dd HH:mm').format(transaction.date);
    final color = theme.colorScheme.error;

    final cat = transaction.categoryId != null
        ? categories.where((c) => c.id == transaction.categoryId).firstOrNull
        : null;
    final catLabel = cat != null
        ? (cat.emoji != null ? '${cat.emoji} ${cat.name}' : cat.name)
        : null;

    final account = accounts.where((a) => a.id == transaction.accountId).firstOrNull;
    final accountLabel = account != null
        ? (account.emoji != null ? '${account.emoji} ${account.name}' : account.name)
        : null;

    final subtitleParts = <String>[
      ?catLabel,
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
        '-${currencySymbol(transaction.currency)}${transaction.amount.toStringAsFixed(2)}',
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
          child: subscription.emoji != null
              ? Text(subscription.emoji!, style: const TextStyle(fontSize: 18))
              : Icon(Icons.repeat, color: color, size: 20),
        );

    final imgPath = subscription.imagePath ?? account?.imagePath;
    if (imgPath != null) {
      return FutureBuilder<File>(
        future: ImageService.resolve(imgPath),
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

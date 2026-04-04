import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/image_service.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../models/finance.dart';
import '../services/balance_util.dart';
import '../services/exchange_rate_storage.dart';
import '../widgets/add_subscription_dialog.dart';
import 'subscription_detail_page.dart';

class SubscriptionsPage extends StatefulWidget {
  final List<Subscription> subscriptions;
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<Account> accounts;
  final ExchangeRateData rateData;
  final String defaultCurrency;
  final int? reminderHour;
  final int? reminderMinute;
  final String? sortMode;
  final List<String>? customOrder;
  final void Function(List<Subscription>) onSubscriptionsChanged;
  final void Function(List<Transaction>) onTransactionsChanged;
  final void Function(int? hour, int? minute) onReminderChanged;
  final void Function(String mode, List<String>? customOrder) onSortChanged;

  const SubscriptionsPage({
    super.key,
    required this.subscriptions,
    required this.transactions,
    required this.categories,
    required this.accounts,
    required this.rateData,
    required this.defaultCurrency,
    this.reminderHour,
    this.reminderMinute,
    this.sortMode,
    this.customOrder,
    required this.onSubscriptionsChanged,
    required this.onTransactionsChanged,
    required this.onReminderChanged,
    required this.onSortChanged,
  });

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  late List<Subscription> _subscriptions;
  late List<Transaction> _transactions;
  late int? _reminderHour;
  late int? _reminderMinute;
  late String _sortMode;
  late List<String> _customOrder;
  bool _reordering = false;

  @override
  void initState() {
    super.initState();
    _subscriptions = List.of(widget.subscriptions);
    _transactions = List.of(widget.transactions);
    _reminderHour = widget.reminderHour;
    _reminderMinute = widget.reminderMinute;
    _sortMode = widget.sortMode ?? 'nextRenewal';
    _customOrder = List.of(widget.customOrder ?? []);
  }

  List<Subscription> get _active {
    final list = _subscriptions.where((s) => s.isActive).toList();
    _sortList(list);
    return list;
  }

  List<Subscription> get _historical =>
      _subscriptions.where((s) => !s.isActive).toList();

  void _sortList(List<Subscription> list) {
    switch (_sortMode) {
      case 'name':
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case 'custom':
        if (_customOrder.isNotEmpty) {
          list.sort((a, b) {
            final ai = _customOrder.indexOf(a.id);
            final bi = _customOrder.indexOf(b.id);
            // Items not in customOrder go to the end
            final aIdx = ai == -1 ? _customOrder.length : ai;
            final bIdx = bi == -1 ? _customOrder.length : bi;
            return aIdx.compareTo(bIdx);
          });
        }
      default: // 'nextRenewal'
        list.sort((a, b) {
          final aNext = a.nextBillingDate;
          final bNext = b.nextBillingDate;
          if (aNext == null && bNext == null) return 0;
          if (aNext == null) return 1;
          if (bNext == null) return -1;
          return aNext.compareTo(bNext);
        });
    }
  }

  void _onSortModeChanged(String mode) {
    setState(() {
      _sortMode = mode;
      _reordering = false;
      if (mode == 'custom' && _customOrder.isEmpty) {
        // Initialize custom order from current active list
        _customOrder = _subscriptions.where((s) => s.isActive).map((s) => s.id).toList();
      }
    });
    widget.onSortChanged(_sortMode, _sortMode == 'custom' ? _customOrder : null);
  }

  double _monthlyDue() {
    double total = 0;
    for (final s in _active) {
      final rates = widget.rateData.currentRates;
      double monthly;
      if (s.billingCycleType == BillingCycleType.monthly) {
        monthly = s.amount / s.billingInterval;
      } else {
        monthly = s.amount / (s.billingInterval * 12);
      }
      total += convertCurrency(rates, monthly, s.currency, widget.defaultCurrency);
    }
    return total;
  }

  double _monthlyAvg() {
    // Average monthly cost based on actual transactions; fall back to projected
    // cost when there isn't at least 2 full months of history.
    final subTxs = _transactions.where((t) => t.subscriptionId != null).toList();
    if (subTxs.isEmpty) return _monthlyDue();
    final earliest = subTxs.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final now = DateTime.now();
    final months = (now.year - earliest.year) * 12 + now.month - earliest.month;
    if (months < 2) return _monthlyDue();
    final total = subTxs.fold(0.0, (sum, t) => sum + convertCurrency(
        widget.rateData.ratesAt(t.rateSnapshotId), t.amount, t.currency, widget.defaultCurrency));
    return total / months;
  }

  double _yearlyAvg() => _monthlyDue() * 12;

  Future<void> _addSubscription() async {
    final result = await showDialog<({Subscription sub, bool importHistory})>(
      context: context,
      builder: (_) => AddSubscriptionDialog(
        categories: widget.categories,
        accounts: widget.accounts,
      ),
    );
    if (result != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // Compute initial nextBillingDate.
      // If importing history: next billing is the first date after today.
      // If NOT importing: next billing is the first date >= today (today's
      // billing will be caught by the processor).
      final tempSub = Subscription(
        id: result.sub.id,
        name: result.sub.name,
        emoji: result.sub.emoji,
        imagePath: result.sub.imagePath,
        startDate: result.sub.startDate,
        trialDays: result.sub.trialDays,
        billingCycleType: result.sub.billingCycleType,
        billingInterval: result.sub.billingInterval,
        amount: result.sub.amount,
        currency: result.sub.currency,
        accountId: result.sub.accountId,
        categoryId: result.sub.categoryId,
        note: result.sub.note,
      );
      final initialNBD = result.importHistory
          ? tempSub.calculateNextBillingDate(after: today)
          : tempSub.calculateNextBillingDate(
              after: today.subtract(const Duration(days: 1)));
      final sub = Subscription(
        id: result.sub.id,
        name: result.sub.name,
        emoji: result.sub.emoji,
        imagePath: result.sub.imagePath,
        startDate: result.sub.startDate,
        trialDays: result.sub.trialDays,
        billingCycleType: result.sub.billingCycleType,
        billingInterval: result.sub.billingInterval,
        amount: result.sub.amount,
        currency: result.sub.currency,
        accountId: result.sub.accountId,
        categoryId: result.sub.categoryId,
        note: result.sub.note,
        nextBillingDate: initialNBD,
      );
      setState(() {
        _subscriptions.add(sub);
        if (_sortMode == 'custom') _customOrder.add(sub.id);
      });
      widget.onSubscriptionsChanged(_subscriptions);
      if (_sortMode == 'custom') {
        widget.onSortChanged(_sortMode, _customOrder);
      }
      if (result.importHistory) {
        _importHistoricalTransactions(sub);
      }
    }
  }

  Future<void> _editSubscription(Subscription sub) async {
    final result = await showDialog<({Subscription sub, bool importHistory})>(
      context: context,
      builder: (_) => AddSubscriptionDialog(
        categories: widget.categories,
        accounts: widget.accounts,
        subscription: sub,
      ),
    );
    if (result != null) {
      final wasRestored = !sub.isActive && result.sub.isActive;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Recalculate nextBillingDate when restoring OR when billing parameters changed
      DateTime? nbd;
      final billingChanged = sub.startDate != result.sub.startDate ||
          sub.trialDays != result.sub.trialDays ||
          sub.billingCycleType != result.sub.billingCycleType ||
          sub.billingInterval != result.sub.billingInterval;
      if (wasRestored || billingChanged) {
        final tempSub = Subscription(
          startDate: result.sub.startDate,
          trialDays: result.sub.trialDays,
          billingCycleType: result.sub.billingCycleType,
          billingInterval: result.sub.billingInterval,
          amount: result.sub.amount,
          name: result.sub.name,
          accountId: result.sub.accountId,
        );
        nbd = (wasRestored && result.importHistory)
            ? tempSub.calculateNextBillingDate(after: today)
            : tempSub.calculateNextBillingDate(
                after: today.subtract(const Duration(days: 1)));
      } else {
        nbd = sub.nextBillingDate;
      }

      final edited = Subscription(
        id: result.sub.id,
        name: result.sub.name,
        emoji: result.sub.emoji,
        imagePath: result.sub.imagePath,
        startDate: result.sub.startDate,
        trialDays: result.sub.trialDays,
        billingCycleType: result.sub.billingCycleType,
        billingInterval: result.sub.billingInterval,
        amount: result.sub.amount,
        currency: result.sub.currency,
        accountId: result.sub.accountId,
        categoryId: result.sub.categoryId,
        note: result.sub.note,
        isActive: result.sub.isActive,
        cancelledAt: result.sub.cancelledAt,
        cancelType: result.sub.cancelType,
        nextBillingDate: nbd,
      );
      setState(() {
        final idx = _subscriptions.indexWhere((s) => s.id == edited.id);
        if (idx != -1) _subscriptions[idx] = edited;
      });
      widget.onSubscriptionsChanged(_subscriptions);
      if (wasRestored && result.importHistory) {
        _importHistoricalTransactions(edited);
      }
    }
  }

  void _deleteSubscription(Subscription sub) {
    setState(() {
      _subscriptions.removeWhere((s) => s.id == sub.id);
      _customOrder.remove(sub.id);
    });
    widget.onSubscriptionsChanged(_subscriptions);
    if (_sortMode == 'custom') widget.onSortChanged(_sortMode, _customOrder);
  }

  void _cancelSubscription(Subscription sub) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cancel),
              title: Text(l10n.financeCancelImmediate),
              onTap: () {
                Navigator.pop(ctx);
                _doCancelSubscription(sub, CancelType.immediate);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l10n.financeCancelAtExpiry),
              onTap: () {
                Navigator.pop(ctx);
                _doCancelSubscription(sub, CancelType.atExpiry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _doCancelSubscription(Subscription sub, CancelType type) {
    final cancelled = Subscription(
      id: sub.id,
      name: sub.name,
      emoji: sub.emoji,
      imagePath: sub.imagePath,
      startDate: sub.startDate,
      trialDays: sub.trialDays,
      billingCycleType: sub.billingCycleType,
      billingInterval: sub.billingInterval,
      amount: sub.amount,
      currency: sub.currency,
      accountId: sub.accountId,
      categoryId: sub.categoryId,
      note: sub.note,
      isActive: type == CancelType.atExpiry,
      cancelledAt: DateTime.now(),
      cancelType: type,
      nextBillingDate: sub.nextBillingDate,
    );
    setState(() {
      final idx = _subscriptions.indexWhere((s) => s.id == sub.id);
      if (idx != -1) _subscriptions[idx] = cancelled;
    });
    widget.onSubscriptionsChanged(_subscriptions);
  }

  void _importHistoricalTransactions(Subscription sub) {
    final now = DateTime.now();
    final dates = sub.billingDatesBefore(now);
    final newTxs = dates.map((d) => Transaction(
      type: TransactionType.expense,
      amount: sub.amount,
      currency: sub.currency,
      accountId: sub.accountId,
      categoryId: sub.categoryId,
      subscriptionId: sub.id,
      note: sub.name,
      date: d,
    )).toList();
    setState(() => _transactions.addAll(newTxs));
    widget.onTransactionsChanged(_transactions);
  }

  void _openDetail(Subscription sub) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionDetailPage(
          subscription: sub,
          transactions: _transactions,
          categories: widget.categories,
          accounts: widget.accounts,
          rateData: widget.rateData,
          defaultCurrency: widget.defaultCurrency,
          onTransactionsChanged: (t) {
            setState(() => _transactions = t);
            widget.onTransactionsChanged(_transactions);
          },
        ),
      ),
    );
  }

  List<(Subscription, DateTime)> _getUpcomingSubs(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(Duration(days: days));
    final result = <(Subscription, DateTime)>[];
    for (final sub in _subscriptions) {
      if (!sub.isActive && sub.cancelType == CancelType.immediate) continue;
      final next = sub.nextBillingDate;
      if (next != null) {
        final nextDay = DateTime(next.year, next.month, next.day);
        if (!nextDay.isAfter(limit)) {
          result.add((sub, next));
        }
      }
    }
    result.sort((a, b) => a.$2.compareTo(b.$2));
    return result;
  }

  Widget _buildReorderBody(ThemeData theme, AppLocalizations l10n, List<Subscription> active) {
    // Mutable copy for reorder
    final items = List.of(active);
    return ReorderableListView.builder(
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        setState(() {
          final item = _customOrder.removeAt(oldIndex);
          _customOrder.insert(newIndex, item);
        });
        widget.onSortChanged(_sortMode, _customOrder);
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 4,
          child: child,
        );
      },
      itemBuilder: (context, i) {
        final sub = items[i];
        return ListTile(
          key: ValueKey('reorder-${sub.id}'),
          leading: const Icon(Icons.drag_handle),
          title: Text(sub.name),
          subtitle: Text(
            '${currencySymbol(sub.currency)}${sub.amount.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall,
          ),
          trailing: sub.emoji != null
              ? Text(sub.emoji!, style: const TextStyle(fontSize: 20))
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sym = currencySymbol(widget.defaultCurrency);
    final numberFormat = NumberFormat('#,##0.00');
    final active = _active;
    final historical = _historical;
    final upcomingSubs = _getUpcomingSubs(3);
    final reminderEnabled = _reminderHour != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financeSubscriptions),
        centerTitle: true,
        actions: [
          if (_sortMode == 'custom')
            IconButton(
              icon: Icon(_reordering ? Icons.check : Icons.reorder),
              tooltip: _reordering ? l10n.financeSortDone : l10n.financeSortReorder,
              onPressed: () => setState(() => _reordering = !_reordering),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.financeSortBy,
            onSelected: _onSortModeChanged,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'nextRenewal',
                child: Row(
                  children: [
                    Icon(_sortMode == 'nextRenewal' ? Icons.radio_button_checked : Icons.radio_button_off, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.financeSortByRenewal),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(_sortMode == 'name' ? Icons.radio_button_checked : Icons.radio_button_off, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.financeSortByName),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'custom',
                child: Row(
                  children: [
                    Icon(_sortMode == 'custom' ? Icons.radio_button_checked : Icons.radio_button_off, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.financeSortCustom),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _reordering ? _buildReorderBody(theme, l10n, active) : Column(
        children: [
          // Summary cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: l10n.financeMonthlyDue,
                    value: '$sym${numberFormat.format(_monthlyDue())}',
                    color: theme.colorScheme.error,
                    icon: Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    label: l10n.financeMonthlyAvg,
                    value: '$sym${numberFormat.format(_monthlyAvg())}',
                    color: theme.colorScheme.primary,
                    icon: Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    label: l10n.financeYearlyAvg,
                    value: '$sym${numberFormat.format(_yearlyAvg())}',
                    color: Colors.orange,
                    icon: Icons.date_range,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Active subscriptions
          if (active.isNotEmpty || historical.isNotEmpty)
            Expanded(
              child: ListView(
                children: [
                  // Upcoming renewals
                  if (upcomingSubs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                      child: Row(
                        children: [
                          Icon(Icons.notifications_active, size: 16, color: theme.colorScheme.error),
                          const SizedBox(width: 6),
                          Text(
                            l10n.financeUpcomingRenewals,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: upcomingSubs.map((entry) {
                          final (sub, _) = entry;
                          final cat = sub.categoryId != null
                              ? widget.categories.where((c) => c.id == sub.categoryId).firstOrNull
                              : null;
                          final icon = sub.emoji ?? cat?.emoji;
                          return Chip(
                            avatar: icon != null
                                ? Text(icon, style: const TextStyle(fontSize: 14))
                                : const Icon(Icons.repeat, size: 14),
                            label: Text(sub.name, style: theme.textTheme.bodySmall),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  // Reminder setting
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: Text(l10n.financeReminderEnabled, style: theme.textTheme.bodyMedium),
                    subtitle: reminderEnabled
                        ? Text(
                            '${l10n.financeReminderTime}: '
                            '${_reminderHour!.toString().padLeft(2, '0')}:'
                            '${_reminderMinute!.toString().padLeft(2, '0')}',
                            style: theme.textTheme.bodySmall,
                          )
                        : null,
                    value: reminderEnabled,
                    onChanged: (enabled) async {
                      if (enabled) {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (picked != null) {
                          setState(() {
                            _reminderHour = picked.hour;
                            _reminderMinute = picked.minute;
                          });
                          widget.onReminderChanged(picked.hour, picked.minute);
                        }
                      } else {
                        setState(() {
                          _reminderHour = null;
                          _reminderMinute = null;
                        });
                        widget.onReminderChanged(null, null);
                      }
                    },
                  ),
                  if (reminderEnabled)
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(l10n.financeReminderTime),
                      trailing: Text(
                        '${_reminderHour!.toString().padLeft(2, '0')}:'
                        '${_reminderMinute!.toString().padLeft(2, '0')}',
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: _reminderHour!,
                            minute: _reminderMinute!,
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            _reminderHour = picked.hour;
                            _reminderMinute = picked.minute;
                          });
                          widget.onReminderChanged(picked.hour, picked.minute);
                        }
                      },
                    ),
                  const Divider(height: 1),
                  if (active.isNotEmpty) ...[
                    _SectionHeader(title: l10n.financeActiveSubscriptions),
                    ...active.map((sub) => Dismissible(
                      key: ValueKey('active-${sub.id}'),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _editSubscription(sub);
                          return false;
                        } else {
                          _cancelSubscription(sub);
                          return false;
                        }
                      },
                      background: Container(
                        color: theme.colorScheme.primaryContainer,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: Icon(Icons.edit, color: theme.colorScheme.onPrimaryContainer),
                      ),
                      secondaryBackground: Container(
                        color: theme.colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: Icon(Icons.cancel_outlined, color: theme.colorScheme.onErrorContainer),
                      ),
                      child: _SubscriptionTile(
                        subscription: sub,
                        categories: widget.categories,
                        accounts: widget.accounts,
                        defaultCurrency: widget.defaultCurrency,
                        onTap: () => _openDetail(sub),
                        onEdit: () => _editSubscription(sub),
                        onCancel: () => _cancelSubscription(sub),
                        onDelete: () async {
                          final confirmed = await confirmDelete(context, l10n.financeThisSubscription);
                          if (confirmed == true) _deleteSubscription(sub);
                        },
                      ),
                    )),
                  ],
                  if (historical.isNotEmpty) ...[
                    _SectionHeader(title: l10n.financeHistoricalSubscriptions),
                    ...historical.map((sub) => Dismissible(
                      key: ValueKey('hist-${sub.id}'),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _editSubscription(sub);
                          return false;
                        } else {
                          final confirmed = await confirmDelete(context, l10n.financeThisSubscription);
                          if (confirmed == true) _deleteSubscription(sub);
                          return false;
                        }
                      },
                      background: Container(
                        color: theme.colorScheme.primaryContainer,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: Icon(Icons.edit, color: theme.colorScheme.onPrimaryContainer),
                      ),
                      secondaryBackground: Container(
                        color: theme.colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
                      ),
                      child: _SubscriptionTile(
                        subscription: sub,
                        categories: widget.categories,
                        accounts: widget.accounts,
                        defaultCurrency: widget.defaultCurrency,
                        onTap: () => _openDetail(sub),
                        onEdit: () => _editSubscription(sub),
                        onDelete: () async {
                          final confirmed = await confirmDelete(context, l10n.financeThisSubscription);
                          if (confirmed == true) _deleteSubscription(sub);
                        },
                      ),
                    )),
                  ],
                ],
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  l10n.financeNoSubscriptions,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubscription,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: theme.colorScheme.surfaceContainerLow,
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final Subscription subscription;
  final List<Category> categories;
  final List<Account> accounts;
  final String defaultCurrency;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onCancel;
  final VoidCallback onDelete;

  const _SubscriptionTile({
    required this.subscription,
    required this.categories,
    required this.accounts,
    required this.defaultCurrency,
    required this.onTap,
    required this.onEdit,
    this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sub = subscription;

    // Category
    final cat = sub.categoryId != null
        ? categories.where((c) => c.id == sub.categoryId).firstOrNull
        : null;
    final catLabel = cat != null
        ? (cat.emoji != null ? '${cat.emoji} ${cat.name}' : cat.name)
        : null;

    // Account
    final account = accounts.where((a) => a.id == sub.accountId).firstOrNull;
    final accountLabel = account != null
        ? (account.emoji != null ? '${account.emoji} ${account.name}' : account.name)
        : null;

    // Cycle label
    final cycleLabel = sub.billingCycleType == BillingCycleType.monthly
        ? l10n.financeEveryXMonths(sub.billingInterval)
        : l10n.financeEveryXYears(sub.billingInterval);

    // Next billing / expiry date
    String? nextLabel;
    if (sub.cancelType == CancelType.atExpiry && sub.nextBillingDate != null) {
      // atExpiry: show expiry date (regardless of active or not)
      nextLabel = '${l10n.financeExpiryDate}: ${DateFormat('yyyy-MM-dd').format(sub.nextBillingDate!)}';
    } else if (sub.isActive && sub.nextBillingDate != null) {
      nextLabel = '${l10n.financeNextBilling}: ${DateFormat('yyyy-MM-dd').format(sub.nextBillingDate!)}';
    }

    // Cancelled label (for immediate cancellation)
    final cancelLabel = sub.cancelledAt != null && sub.cancelType != CancelType.atExpiry
        ? l10n.financeCancelledOn(DateFormat('yyyy-MM-dd').format(sub.cancelledAt!))
        : null;

    final subtitleParts = <String>[
      ?catLabel,
      ?accountLabel,
      cycleLabel,
      ?nextLabel,
      if (!sub.isActive && cancelLabel != null) cancelLabel,
    ];

    return ListTile(
      leading: _buildLeading(sub, account, cat, theme),
      title: Text(sub.name.isNotEmpty ? sub.name : l10n.financeSubscription),
      subtitle: Text(
        subtitleParts.join('  •  '),
        style: theme.textTheme.bodySmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${currencySymbol(sub.currency)}${sub.amount.toStringAsFixed(2)}',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.error,
        ),
      ),
      onTap: onTap,
      onLongPress: () => _showActions(context),
    );
  }

  void _showActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.commonEdit),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            if (subscription.isActive && onCancel != null)
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: Text(l10n.financeCancelSubscription),
                onTap: () {
                  Navigator.pop(ctx);
                  onCancel!();
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text(l10n.commonDelete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(
      Subscription sub, Account? account, Category? cat, ThemeData theme) {
    final color = theme.colorScheme.error;

    Widget emojiAvatar(String emoji) => CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Text(emoji, style: const TextStyle(fontSize: 18)),
    );

    Widget defaultIcon() => CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(Icons.repeat, color: color, size: 20),
    );

    // 1. Subscription has its own image → use it
    if (sub.imagePath != null) {
      return FutureBuilder<File>(
        future: ImageService.resolve(sub.imagePath!),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.existsSync()) {
            return CircleAvatar(
              backgroundImage: FileImage(snap.data!),
              backgroundColor: color.withValues(alpha: 0.1),
            );
          }
          return sub.emoji != null ? emojiAvatar(sub.emoji!) : defaultIcon();
        },
      );
    }

    // 2. Subscription has an emoji → use it
    if (sub.emoji != null) return emojiAvatar(sub.emoji!);

    // 3. Fall back to account image
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
          return cat?.emoji != null ? emojiAvatar(cat!.emoji!) : defaultIcon();
        },
      );
    }

    // 4. Category emoji → default icon
    if (cat?.emoji != null) return emojiAvatar(cat!.emoji!);
    return defaultIcon();
  }
}

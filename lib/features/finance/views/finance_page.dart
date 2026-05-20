import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/auto_sync_service.dart';
import '../../../shared/services/image_service.dart';
import '../../../shared/services/reminder_service.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../models/finance.dart';
import '../services/balance_util.dart';
import '../services/exchange_rate_storage.dart';
import '../services/finance_storage.dart';
import '../services/subscription_processor.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/grouped_transaction_list.dart';
import 'accounts_page.dart';
import 'analysis_page.dart';
import 'categories_page.dart';
import 'exchange_rates_page.dart';
import 'subscriptions_page.dart';

class FinancePage extends StatefulWidget {
  /// Purpose: Create a finance page instance.
  /// Inputs: None.
  /// Returns: A new `FinancePage` instance.
  /// Side effects: None.
  /// Notes: None.
  const FinancePage({super.key});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  List<Account> _accounts = [];
  List<Category> _categories = [];
  List<Transaction> _transactions = [];
  List<Subscription> _subscriptions = [];
  String _defaultCurrency = 'CNY';
  ExchangeRateData _rateData = ExchangeRateData(
    currentSnapshotId: '',
    snapshots: {},
  );
  int? _subscriptionReminderHour;
  int? _subscriptionReminderMinute;
  String? _subscriptionSortMode;
  List<String>? _subscriptionCustomOrder;
  Map<String, String> _accountSortModes = {};
  Map<String, List<String>> _accountCustomOrders = {};
  DateTime _settingsModifiedAt = DateTime.fromMillisecondsSinceEpoch(0);
  late DateTime _selectedFlowMonth;
  bool _loaded = false;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Initializes the transaction flow filter to the current month.
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedFlowMonth = DateTime(now.year, now.month);
    ReminderService.instance.onRenewalsProcessed = _loadData;
    _loadData();
    AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  }

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Releases owned resources and unregisters listeners.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    ReminderService.instance.onRenewalsProcessed = null;
    AutoSyncService.instance.removeOnLocalDataChanged(_loadData);
    super.dispose();
  }

  /// Purpose: Provide the internal load data helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadData() async {
    final data = await FinanceStorage.load();
    final rateData = await ExchangeRateStorage.load();
    setState(() {
      if (data != null) {
        _accounts = data.accounts;
        _categories = data.categories;
        _transactions = data.transactions;
        _subscriptions = data.subscriptions;
        _defaultCurrency = data.defaultCurrency;
        _subscriptionReminderHour = data.subscriptionReminderHour;
        _subscriptionReminderMinute = data.subscriptionReminderMinute;
        _subscriptionSortMode = data.subscriptionSortMode;
        _subscriptionCustomOrder = data.subscriptionCustomOrder;
        _accountSortModes = Map.of(data.accountSortModes);
        _accountCustomOrders = data.accountCustomOrders.map(
          (key, value) => MapEntry(key, List<String>.of(value)),
        );
        _settingsModifiedAt = data.settingsModifiedAt;
      }
      _rateData = rateData;
      _loaded = true;
    });
    // Update subscription reminder data
    _updateReminderService();
    // Auto-generate subscription transactions for billing dates that have passed
    if (_subscriptions.isNotEmpty) {
      _processSubscriptions();
    }
  }

  /// For each active subscription, generate transactions for overdue billing dates.
  /// Purpose: Provide the internal process subscriptions helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _processSubscriptions() {
    final result = SubscriptionProcessor.process(_subscriptions, _transactions);
    if (result.changed) {
      setState(() {
        _subscriptions = result.subs;
        _transactions = [..._transactions, ...result.txs];
      });
      _saveData();
    }
  }

  /// Subscriptions whose next billing date is within [days] days from now.
  /// Purpose: Provide the internal get upcoming subs helper for this file.
  /// Inputs: `days`.
  /// Returns: `List<(Subscription, DateTime)>`.
  /// Side effects: None.
  /// Notes: At-expiry cancellations keep showing in subscription lists but are excluded from renewal reminders.
  List<(Subscription, DateTime)> _getUpcomingSubs(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(Duration(days: days));
    final result = <(Subscription, DateTime)>[];
    for (final sub in _subscriptions) {
      if (sub.cancelType == CancelType.atExpiry) continue;
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

  /// Purpose: Provide the internal save data helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _saveData() async {
    await FinanceStorage.save(
      FinanceData(
        accounts: _accounts,
        categories: _categories,
        transactions: _transactions,
        subscriptions: _subscriptions,
        defaultCurrency: _defaultCurrency,
        settingsModifiedAt: _settingsModifiedAt,
        subscriptionReminderHour: _subscriptionReminderHour,
        subscriptionReminderMinute: _subscriptionReminderMinute,
        subscriptionSortMode: _subscriptionSortMode,
        subscriptionCustomOrder: _subscriptionCustomOrder,
        accountSortModes: _accountSortModes,
        accountCustomOrders: _accountCustomOrders,
      ),
    );
    AutoSyncService.instance.notifySaved();
    _updateReminderService();
  }

  /// Purpose: Provide the internal update reminder service helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _updateReminderService() {
    ReminderService.instance.updateSubscriptionData(
      subscriptions: _subscriptions,
      reminderHour: _subscriptionReminderHour,
      reminderMinute: _subscriptionReminderMinute,
    );
  }

  /// Purpose: Provide the internal add transaction helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _addTransaction() async {
    final tx = await showDialog<Transaction>(
      context: context,
      builder: (_) => AddTransactionDialog(
        categories: _categories,
        accounts: _accounts,
        currentSnapshotId: _rateData.currentSnapshotId,
        defaultCurrency: _defaultCurrency,
      ),
    );
    if (tx != null) {
      setState(() => _transactions.insert(0, tx));
      await _saveData();
    }
  }

  /// Purpose: Provide the internal delete transaction helper for this file.
  /// Inputs: `tx`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _deleteTransaction(Transaction tx) {
    setState(() {
      _transactions.removeWhere((t) => t.id == tx.id);
    });
    _saveData();
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
        categories: _categories,
        accounts: _accounts,
        transaction: tx,
        currentSnapshotId: _rateData.currentSnapshotId,
        defaultCurrency: _defaultCurrency,
      ),
    );
    if (updated != null) {
      setState(() {
        final index = _transactions.indexWhere((t) => t.id == updated.id);
        if (index != -1) _transactions[index] = updated;
      });
      await _saveData();
    }
  }

  /// Purpose: Let the user select the month shown on the finance home flow.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Opens a month picker dialog and updates the selected month.
  /// Notes: The dialog stores only a year/month pair; no day-level filtering is involved.
  Future<void> _pickFlowMonth() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        var year = _selectedFlowMonth.year;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(l10n.financeByMonth),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setDialogState(() => year--),
                      ),
                      Text(
                        '$year',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setDialogState(() => year++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (index) {
                      final month = index + 1;
                      final selected =
                          year == _selectedFlowMonth.year &&
                          month == _selectedFlowMonth.month;
                      return ChoiceChip(
                        label: Text(
                          DateFormat.MMM().format(DateTime(year, month)),
                        ),
                        selected: selected,
                        onSelected: (_) {
                          Navigator.pop(context, DateTime(year, month));
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.commonCancel),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedFlowMonth = DateTime(picked.year, picked.month));
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
    final monthLabel = DateFormat('yyyy-MM').format(_selectedFlowMonth);
    final l10n = AppLocalizations.of(context)!;

    // Calculate summaries with currency conversion
    final currentRates = _rateData.currentRates;
    final startOfMonth = DateTime(
      _selectedFlowMonth.year,
      _selectedFlowMonth.month,
    );
    final startOfNextMonth = DateTime(
      _selectedFlowMonth.year,
      _selectedFlowMonth.month + 1,
    );
    final monthTransactions = _transactions
        .where(
          (t) =>
              !t.date.isBefore(startOfMonth) &&
              t.date.isBefore(startOfNextMonth),
        )
        .toList();

    final monthExpense = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(
          0.0,
          (sum, t) =>
              sum +
              convertCurrency(
                _rateData.ratesAt(t.rateSnapshotId),
                t.amount,
                t.currency,
                _defaultCurrency,
              ),
        );
    final monthIncome = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(
          0.0,
          (sum, t) =>
              sum +
              convertCurrency(
                _rateData.ratesAt(t.rateSnapshotId),
                t.amount,
                t.currency,
                _defaultCurrency,
              ),
        );
    // Total assets = sum of all account balances converted to default currency
    final totalAssets = _accounts.isEmpty
        ? monthIncome - monthExpense
        : _accounts.fold(0.0, (sum, a) {
            final bal = accountBalance(a, _transactions, _rateData);
            return sum +
                convertCurrency(
                  currentRates,
                  bal,
                  a.currency,
                  _defaultCurrency,
                );
          });

    // Upcoming renewals (within 3 days)
    final upcomingSubs = _getUpcomingSubs(3);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance),
            tooltip: l10n.financeAccounts,
            onPressed: () => _openAccounts(context),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: l10n.financeAnalysis,
            onPressed: () => _openAnalysis(context),
          ),
          IconButton(
            icon: const Icon(Icons.repeat),
            tooltip: l10n.financeSubscriptions,
            onPressed: () => _openSubscriptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.financeAccountsCategories,
            onPressed: () {
              _showFinanceMenu(context);
            },
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // L1: Summary cards
                _SummaryHeader(
                  monthLabel: monthLabel,
                  monthExpense: monthExpense,
                  monthIncome: monthIncome,
                  totalAssets: totalAssets,
                  currencyCode: _defaultCurrency,
                  onPreviousMonth: () => setState(() {
                    _selectedFlowMonth = DateTime(
                      _selectedFlowMonth.year,
                      _selectedFlowMonth.month - 1,
                    );
                  }),
                  onNextMonth: () => setState(() {
                    _selectedFlowMonth = DateTime(
                      _selectedFlowMonth.year,
                      _selectedFlowMonth.month + 1,
                    );
                  }),
                  onPickMonth: _pickFlowMonth,
                ),
                const Divider(height: 1),

                // Upcoming renewals
                if (upcomingSubs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
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
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: upcomingSubs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final (sub, _) = upcomingSubs[index];
                              final cat = sub.categoryId != null
                                  ? _categories
                                        .where((c) => c.id == sub.categoryId)
                                        .firstOrNull
                                  : null;
                              final icon = sub.emoji ?? cat?.emoji;
                              return Chip(
                                avatar: icon != null
                                    ? Text(
                                        icon,
                                        style: const TextStyle(fontSize: 14),
                                      )
                                    : const Icon(Icons.repeat, size: 14),
                                label: Text(
                                  sub.name,
                                  style: theme.textTheme.bodySmall,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                if (upcomingSubs.isNotEmpty) const Divider(height: 1),

                // L1: Transaction flow
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.financeTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: monthTransactions.isEmpty
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
                          List.of(monthTransactions)
                            ..sort((a, b) => b.date.compareTo(a.date)),
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
                            child: _TransactionTile(
                              transaction: tx,
                              categories: _categories,
                              accounts: _accounts,
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

  /// Purpose: Provide the internal pick default currency helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _pickDefaultCurrency() {
    final l10n = AppLocalizations.of(context)!;
    const currencies = [
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
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.financeCurrency),
        children: currencies
            .map(
              (c) => SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _defaultCurrency = c);
                  _saveData();
                },
                child: Text(
                  '${currencySymbol(c)}  $c${c == _defaultCurrency ? '  ✓' : ''}',
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// Purpose: Provide the internal open accounts helper for this file.
  /// Inputs: `context`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _openAccounts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountsPage(
          accounts: _accounts,
          transactions: _transactions,
          categories: _categories,
          rateData: _rateData,
          sortModes: _accountSortModes,
          customOrders: _accountCustomOrders,
          onChanged: (a) {
            setState(() => _accounts = a);
            _saveData();
          },
          onTransactionsChanged: (t) {
            setState(() => _transactions = t);
            _saveData();
          },
          onSortChanged: (modes, orders) {
            setState(() {
              _accountSortModes = Map.of(modes);
              _accountCustomOrders = orders.map(
                (key, value) => MapEntry(key, List<String>.of(value)),
              );
              _settingsModifiedAt = DateTime.now().toUtc();
            });
            _saveData();
          },
        ),
      ),
    );
  }

  /// Purpose: Provide the internal open analysis helper for this file.
  /// Inputs: `context`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _openAnalysis(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisPage(
          transactions: _transactions,
          categories: _categories,
          accounts: _accounts,
          rateData: _rateData,
          defaultCurrency: _defaultCurrency,
        ),
      ),
    );
  }

  /// Purpose: Provide the internal open subscriptions helper for this file.
  /// Inputs: `context`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _openSubscriptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionsPage(
          subscriptions: _subscriptions,
          transactions: _transactions,
          categories: _categories,
          accounts: _accounts,
          rateData: _rateData,
          defaultCurrency: _defaultCurrency,
          reminderHour: _subscriptionReminderHour,
          reminderMinute: _subscriptionReminderMinute,
          sortMode: _subscriptionSortMode,
          customOrder: _subscriptionCustomOrder,
          onSubscriptionsChanged: (s) {
            setState(() => _subscriptions = s);
            _saveData();
            _processSubscriptions();
          },
          onTransactionsChanged: (t) {
            setState(() => _transactions = t);
            _saveData();
          },
          onReminderChanged: (hour, minute) {
            setState(() {
              _subscriptionReminderHour = hour;
              _subscriptionReminderMinute = minute;
            });
            _saveData();
          },
          onSortChanged: (mode, order) {
            setState(() {
              _subscriptionSortMode = mode;
              _subscriptionCustomOrder = order;
              _settingsModifiedAt = DateTime.now().toUtc();
            });
            _saveData();
          },
        ),
      ),
    );
  }

  /// Purpose: Provide the internal show finance menu helper for this file.
  /// Inputs: `context`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _showFinanceMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.category),
              title: Text(l10n.financeCategories),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoriesPage(
                      categories: _categories,
                      transactions: _transactions,
                      accounts: _accounts,
                      rateData: _rateData,
                      defaultCurrency: _defaultCurrency,
                      onChanged: (c) {
                        setState(() => _categories = c);
                        _saveData();
                      },
                      onTransactionsChanged: (t) {
                        setState(() => _transactions = t);
                        _saveData();
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: Text(l10n.financeExchangeRates),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExchangeRatesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.money),
              title: Text(l10n.financeCurrency),
              trailing: Text(_defaultCurrency),
              onTap: () {
                Navigator.pop(context);
                _pickDefaultCurrency();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final String monthLabel;
  final double monthExpense;
  final double monthIncome;
  final double totalAssets;
  final String currencyCode;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onPickMonth;

  /// Purpose: Create a summary header instance.
  /// Inputs: Monthly totals and month navigation callbacks.
  /// Returns: A new `_SummaryHeader` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _SummaryHeader({
    required this.monthLabel,
    required this.monthExpense,
    required this.monthIncome,
    required this.totalAssets,
    required this.currencyCode,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onPickMonth,
  });

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,##0.00');
    final sym = currencySymbol(currencyCode);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: onPreviousMonth,
              ),
              TextButton.icon(
                onPressed: onPickMonth,
                icon: const Icon(Icons.calendar_month, size: 16),
                label: Text(monthLabel),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: l10n.financeExpense,
                  value: '$sym${numberFormat.format(monthExpense)}',
                  color: theme.colorScheme.error,
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: l10n.financeIncome,
                  value: '$sym${numberFormat.format(monthIncome)}',
                  color: Colors.green,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.financeTotalAssets,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    '$sym${numberFormat.format(totalAssets)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: totalAssets >= 0
                          ? Colors.green
                          : theme.colorScheme.error,
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  /// Purpose: Create a summary card instance.
  /// Inputs: None.
  /// Returns: A new `_SummaryCard` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final List<Category> categories;
  final List<Account> accounts;

  /// Purpose: Create a transaction tile instance.
  /// Inputs: `accounts`.
  /// Returns: A new `_TransactionTile` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _TransactionTile({
    required this.transaction,
    required this.categories,
    this.accounts = const [],
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
    final sign = isExpense ? '-' : (isTransfer ? '' : '+');
    final color = isExpense ? theme.colorScheme.error : Colors.green;

    // Resolve category
    final cat = transaction.categoryId != null
        ? categories.where((c) => c.id == transaction.categoryId).firstOrNull
        : null;
    final catLabel = cat != null
        ? (cat.emoji != null ? '${cat.emoji} ${cat.name}' : cat.name)
        : null;

    // Resolve account name
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

    final l10n = AppLocalizations.of(context)!;
    final typeLabel = switch (transaction.type) {
      TransactionType.expense => l10n.financeExpense,
      TransactionType.income => l10n.financeIncome,
      TransactionType.transfer => l10n.financeTransfer,
    };

    return ListTile(
      leading: _buildLeading(account, cat, isExpense, isTransfer, color, theme),
      title: Text(catLabel ?? typeLabel),
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
  /// Inputs: Key parameters such as `account`, `cat`, `isExpense`, `isTransfer`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildLeading(
    Account? account,
    Category? cat,
    bool isExpense,
    bool isTransfer,
    Color color,
    ThemeData theme,
  ) {
    /// Purpose: Build the fallback finance transaction avatar.
    /// Inputs: None.
    /// Returns: `Widget`.
    /// Side effects: None.
    /// Notes: Internal helper used within this function only.
    Widget defaultAvatar() => CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: cat?.emoji != null
          ? Text(cat!.emoji!, style: const TextStyle(fontSize: 18))
          : Icon(
              isExpense
                  ? Icons.remove
                  : isTransfer
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

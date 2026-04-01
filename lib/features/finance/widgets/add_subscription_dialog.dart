import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/image_service.dart';
import '../models/finance.dart';
import '../services/balance_util.dart';

class AddSubscriptionDialog extends StatefulWidget {
  final List<Category> categories;
  final List<Account> accounts;
  final Subscription? subscription;

  const AddSubscriptionDialog({
    super.key,
    this.categories = const [],
    this.accounts = const [],
    this.subscription,
  });

  @override
  State<AddSubscriptionDialog> createState() => _AddSubscriptionDialogState();
}

class _AddSubscriptionDialogState extends State<AddSubscriptionDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _trialDaysController;
  late DateTime _startDate;
  late BillingCycleType _cycleType;
  late int _billingInterval;
  late String _currency;
  String? _selectedEmoji;
  String? _imagePath;
  Category? _selectedCategory;
  Account? _selectedAccount;

  static const _commonEmojis = [
    '🎵', '🎬', '📺', '🎮', '☁️', '📱', '💻', '🏋️',
    '📚', '🎧', '🔒', '📦', '🚗', '🏠', '💊', '🍔',
  ];

  bool get _isEditing => widget.subscription != null;
  bool get _isCancelled => widget.subscription != null && !widget.subscription!.isActive;

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    _nameController = TextEditingController(text: sub?.name ?? '');
    _amountController = TextEditingController(
      text: sub != null ? sub.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: sub?.note ?? '');
    _trialDaysController = TextEditingController(
      text: sub != null && sub.trialDays > 0 ? sub.trialDays.toString() : '',
    );
    _startDate = sub?.startDate ?? DateTime.now();
    _cycleType = sub?.billingCycleType ?? BillingCycleType.monthly;
    _billingInterval = sub?.billingInterval ?? 1;
    _selectedEmoji = sub?.emoji;
    _imagePath = sub?.imagePath;
    _currency = sub?.currency ?? widget.accounts.firstOrNull?.currency ?? 'CNY';

    if (sub?.categoryId != null) {
      _selectedCategory =
          widget.categories.where((c) => c.id == sub!.categoryId).firstOrNull;
    }
    if (sub?.accountId != null) {
      _selectedAccount =
          widget.accounts.where((a) => a.id == sub!.accountId).firstOrNull;
    }
    _selectedAccount ??= widget.accounts.firstOrNull;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _trialDaysController.dispose();
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
            Text(
              _isEditing ? l10n.financeEditSubscription : l10n.financeAddSubscription,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.financeName),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Emoji
            Text(l10n.financeEmoji, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            _buildImagePreview(theme),
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
                              color: theme.colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Amount + Currency
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.financeAmount,
                      prefixText: '${currencySymbol(_currency)} ',
                      prefixStyle: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: InputDecoration(
                      labelText: l10n.financeCurrency,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CNY', child: Text('CNY')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                      DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                      DropdownMenuItem(value: 'CAD', child: Text('CAD')),
                      DropdownMenuItem(value: 'AUD', child: Text('AUD')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _currency = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Account picker
            if (widget.accounts.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedAccount?.id,
                decoration: InputDecoration(
                  labelText: l10n.financeAccount,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: widget.accounts.map((a) {
                  final label = a.emoji != null
                      ? '${a.emoji} ${a.name}'
                      : a.name;
                  return DropdownMenuItem(value: a.id, child: Text(label));
                }).toList(),
                onChanged: (id) {
                  setState(() {
                    _selectedAccount =
                        widget.accounts.where((a) => a.id == id).firstOrNull;
                  });
                },
              ),
            const SizedBox(height: 12),

            // Category picker
            if (widget.categories.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory?.id,
                decoration: InputDecoration(
                  labelText: l10n.financeCategory,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ...widget.categories
                      .where((c) => c.type == TransactionType.expense)
                      .map((cat) {
                    final label = cat.emoji != null ? '${cat.emoji} ${cat.name}' : cat.name;
                    return DropdownMenuItem(value: cat.id, child: Text(label));
                  }),
                ],
                onChanged: (id) {
                  setState(() {
                    _selectedCategory = id != null
                        ? widget.categories.where((c) => c.id == id).firstOrNull
                        : null;
                  });
                },
              ),
            const SizedBox(height: 12),

            // Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.financeStartDate),
              trailing: Text(
                '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
            ),

            // Trial days
            TextField(
              controller: _trialDaysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.financeTrialDays,
                hintText: '0',
              ),
            ),
            const SizedBox(height: 12),

            // Billing cycle type
            SegmentedButton<BillingCycleType>(
              segments: [
                ButtonSegment(
                  value: BillingCycleType.monthly,
                  label: Text(l10n.financeBillingCycleMonthly),
                ),
                ButtonSegment(
                  value: BillingCycleType.yearly,
                  label: Text(l10n.financeBillingCycleYearly),
                ),
              ],
              selected: {_cycleType},
              onSelectionChanged: (set) => setState(() => _cycleType = set.first),
            ),
            const SizedBox(height: 12),

            // Interval
            DropdownButtonFormField<int>(
              initialValue: _billingInterval,
              decoration: InputDecoration(
                labelText: l10n.financeInterval,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: List.generate(12, (i) => i + 1)
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _billingInterval = v);
              },
            ),
            const SizedBox(height: 12),

            // Note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.financeNote,
              ),
              textInputAction: TextInputAction.done,
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
                  child: Text(_isCancelled
                      ? l10n.financeRestoreSubscription
                      : (_isEditing ? l10n.commonSave : l10n.commonAdd)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final trialDays = int.tryParse(_trialDaysController.text.trim()) ?? 0;

    final sub = Subscription(
      id: widget.subscription?.id,
      name: name,
      emoji: _selectedEmoji,
      imagePath: _imagePath,
      startDate: _startDate,
      trialDays: trialDays,
      billingCycleType: _cycleType,
      billingInterval: _billingInterval,
      amount: amount,
      currency: _currency,
      accountId: _selectedAccount?.id ?? '',
      categoryId: _selectedCategory?.id,
      note: _noteController.text.trim(),
      // When restoring a cancelled sub, re-activate it
      isActive: _isCancelled ? true : (widget.subscription?.isActive ?? true),
      cancelledAt: _isCancelled ? null : widget.subscription?.cancelledAt,
      cancelType: _isCancelled ? null : widget.subscription?.cancelType,
    );

    // Restoring a cancelled subscription: ask about adding first transaction
    if (_isCancelled && sub.firstBillingDate.isBefore(DateTime.now().add(const Duration(days: 1)))) {
      _askImportHistory(sub);
      return;
    }

    // Check if we should ask about historical import
    // Only ask if first billing date (start + trial) is in the past
    final shouldAskImport = !_isEditing && sub.firstBillingDate.isBefore(DateTime.now());

    if (shouldAskImport) {
      _askImportHistory(sub);
    } else {
      Navigator.pop(context, (sub: sub, importHistory: false));
    }
  }

  Widget _buildImagePreview(ThemeData theme) {
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
                      child: Image.file(snap.data!, width: 48, height: 48, fit: BoxFit.cover),
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
                          child: Icon(Icons.close, size: 12, color: theme.colorScheme.onError),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.image_outlined, size: 16),
          label: Text(_imagePath != null
              ? AppLocalizations.of(context)!.financeChangeImage
              : AppLocalizations.of(context)!.financePickImage),
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
    );
  }

  void _askImportHistory(Subscription sub) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.financeImportHistory),
        content: Text(l10n.financeImportHistoryDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonYes),
          ),
        ],
      ),
    ).then((doImport) {
      if (mounted) {
        Navigator.pop(context, (sub: sub, importHistory: doImport ?? false));
      }
    });
  }
}

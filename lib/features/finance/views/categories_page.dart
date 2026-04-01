import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../models/finance.dart';
import '../services/exchange_rate_storage.dart';
import 'category_detail_page.dart';

final _defaultExpenseCategories = <Map<String, dynamic>>[
  {'key': 'financeCatFood', 'emoji': '🍜', 'icon': Icons.restaurant},
  {'key': 'financeCatTransport', 'emoji': '🚌', 'icon': Icons.directions_bus},
  {'key': 'financeCatShopping', 'emoji': '🛒️', 'icon': Icons.shopping_cart},
  {'key': 'financeCatRent', 'emoji': '🏠', 'icon': Icons.home},
  {'key': 'financeCatDigital', 'emoji': '📱', 'icon': Icons.phone_android},
  {'key': 'financeCatEntertainment', 'emoji': '🎬', 'icon': Icons.movie},
  {'key': 'financeCatHealthcare', 'emoji': '💊', 'icon': Icons.local_hospital},
  {'key': 'financeCatEducation', 'emoji': '📚', 'icon': Icons.school},
];

final _defaultIncomeCategories = <Map<String, dynamic>>[
  {'key': 'financeCatSalary', 'emoji': '💰', 'icon': Icons.account_balance},
  {'key': 'financeCatBonus', 'emoji': '🎁', 'icon': Icons.card_giftcard},
  {'key': 'financeCatInvestment', 'emoji': '📈', 'icon': Icons.trending_up},
  {'key': 'financeCatFreelance', 'emoji': '💻', 'icon': Icons.computer},
];

class CategoriesPage extends StatefulWidget {
  final List<Category> categories;
  final void Function(List<Category>) onChanged;
  final List<Transaction> transactions;
  final List<Account> accounts;
  final ExchangeRateData? rateData;
  final String defaultCurrency;
  final void Function(List<Transaction>)? onTransactionsChanged;

  const CategoriesPage({
    super.key,
    required this.categories,
    required this.onChanged,
    this.transactions = const [],
    this.accounts = const [],
    this.rateData,
    this.defaultCurrency = 'CNY',
    this.onTransactionsChanged,
  });

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late List<Category> _categories;
  late List<Transaction> _transactions;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _categories = List.of(widget.categories);
    _transactions = List.of(widget.transactions);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(_categories);

  List<Category> _ofType(TransactionType type) =>
      _categories.where((c) => c.type == type).toList();

  Future<void> _addCategory(TransactionType type) async {
    final category = await showDialog<Category>(
      context: context,
      builder: (_) => _CategoryDialog(type: type),
    );
    if (category != null) {
      setState(() => _categories.add(category));
      _notify();
    }
  }

  Future<void> _editCategory(Category cat) async {
    final edited = await showDialog<Category>(
      context: context,
      builder: (_) => _CategoryDialog(category: cat, type: cat.type),
    );
    if (edited != null) {
      setState(() {
        final i = _categories.indexWhere((c) => c.id == cat.id);
        if (i != -1) _categories[i] = edited;
      });
      _notify();
    }
  }

  void _deleteCategory(Category cat) {
    setState(() => _categories.removeWhere((c) => c.id == cat.id));
    _notify();
  }

  void _openCategoryDetail(Category cat) {
    final rateData = widget.rateData;
    if (rateData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailPage(
          category: cat,
          transactions: _transactions,
          categories: _categories,
          accounts: widget.accounts,
          rateData: rateData,
          defaultCurrency: widget.defaultCurrency,
          onTransactionsChanged: (t) {
            setState(() => _transactions = t);
            widget.onTransactionsChanged?.call(t);
          },
        ),
      ),
    );
  }

  void _importDefaults(TransactionType type) {
    final l10n = AppLocalizations.of(context)!;
    final defaults = type == TransactionType.expense
        ? _defaultExpenseCategories
        : _defaultIncomeCategories;
    final toAdd = defaults.map((d) => Category(
          name: _resolveKey(l10n, d['key'] as String),
          type: type,
          emoji: d['emoji'] as String,
          icon: IconRef(codePoint: (d['icon'] as IconData).codePoint),
        ));
    setState(() => _categories.addAll(toAdd));
    _notify();
  }

  String _resolveKey(AppLocalizations l10n, String key) => switch (key) {
        'financeCatFood' => l10n.financeCatFood,
        'financeCatTransport' => l10n.financeCatTransport,
        'financeCatShopping' => l10n.financeCatShopping,
        'financeCatRent' => l10n.financeCatRent,
        'financeCatDigital' => l10n.financeCatDigital,
        'financeCatEntertainment' => l10n.financeCatEntertainment,
        'financeCatHealthcare' => l10n.financeCatHealthcare,
        'financeCatEducation' => l10n.financeCatEducation,
        'financeCatSalary' => l10n.financeCatSalary,
        'financeCatBonus' => l10n.financeCatBonus,
        'financeCatInvestment' => l10n.financeCatInvestment,
        'financeCatFreelance' => l10n.financeCatFreelance,
        _ => key,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.financeCategories),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.financeExpense),
            Tab(text: AppLocalizations.of(context)!.financeIncome),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(
              context, _ofType(TransactionType.expense), TransactionType.expense),
          _buildCategoryList(
              context, _ofType(TransactionType.income), TransactionType.income),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type = _tabController.index == 0
              ? TransactionType.expense
              : TransactionType.income;
          _addCategory(type);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(
      BuildContext context, List<Category> cats, TransactionType type) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (cats.isEmpty) {
      final typeLabel = type == TransactionType.expense
          ? l10n.financeExpense
          : l10n.financeIncome;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              l10n.financeNoCategoriesOfType(typeLabel),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => _importDefaults(type),
              child: Text(l10n.financeImportDefaults),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: cats.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final cat = cats[index];
        return Dismissible(
          key: ValueKey(cat.id),
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
            child:
                Icon(Icons.delete_outline, color: theme.colorScheme.onError),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              _editCategory(cat);
              return false;
            }
            return confirmDelete(context, AppLocalizations.of(context)!.financeThisCategory);
          },
          onDismissed: (_) => _deleteCategory(cat),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: cat.emoji != null
                  ? Text(cat.emoji!, style: const TextStyle(fontSize: 18))
                  : Icon(
                      cat.icon.toIconData(),
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
            ),
            title: Text(cat.name),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _openCategoryDetail(cat),
          ),
        );
      },
    );
  }
}

// --------------- Category Dialog with Icon Picker ---------------

// Common category icons
const _categoryIcons = <IconData>[
  Icons.restaurant,
  Icons.shopping_cart,
  Icons.directions_bus,
  Icons.local_hospital,
  Icons.school,
  Icons.home,
  Icons.sports_esports,
  Icons.movie,
  Icons.flight,
  Icons.coffee,
  Icons.local_grocery_store,
  Icons.checkroom,
  Icons.pets,
  Icons.child_care,
  Icons.fitness_center,
  Icons.spa,
  Icons.phone_android,
  Icons.computer,
  Icons.book,
  Icons.music_note,
  Icons.local_gas_station,
  Icons.local_parking,
  Icons.water_drop,
  Icons.bolt,
  Icons.attach_money,
  Icons.work,
  Icons.card_giftcard,
  Icons.savings,
  Icons.account_balance,
  Icons.trending_up,
  Icons.volunteer_activism,
  Icons.handshake,
];

class _CategoryDialog extends StatefulWidget {
  final Category? category;
  final TransactionType type;

  const _CategoryDialog({this.category, required this.type});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _nameController = TextEditingController();
  late IconData _selectedIcon;
  String? _selectedEmoji;

  static const _commonEmojis = [
    '🍜', '🍔', '☕', '🍺', '🚌', '🚗', '⛽', '💰',
    '🛍️', '👕', '🏠', '💡', '📱', '💻', '🎬', '🎵',
    '🎮', '🏃', '💊', '🐶', '👶', '🎓', '✈️', '🏥',
    '💇', '📚', '🔧', '🎁', '💳', '📊', '🤝', '❤️',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedIcon = widget.category!.icon.toIconData();
      _selectedEmoji = widget.category!.emoji;
    } else {
      _selectedIcon = widget.type == TransactionType.expense
          ? Icons.shopping_cart
          : Icons.attach_money;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.category != null;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? l10n.financeEditCategory : l10n.financeAddCategory,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.financeName,
                hintText: widget.type == TransactionType.expense
                    ? l10n.financeCategoryHintExpense
                    : l10n.financeCategoryHintIncome,
              ),
            ),
            const SizedBox(height: 16),

            // Emoji picker
            Text(l10n.financeEmoji, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: _commonEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _commonEmojis[index];
                  final isSelected = emoji == _selectedEmoji;
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() {
                      _selectedEmoji = isSelected ? null : emoji;
                    }),
                    child: Container(
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
                        child: Text(emoji, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Text(l10n.financeIcon, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),

            // Icon grid
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: _categoryIcons.length,
                itemBuilder: (context, index) {
                  final icon = _categoryIcons[index];
                  final isSelected = icon.codePoint == _selectedIcon.codePoint;
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
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
                      child: Icon(
                        icon,
                        size: 22,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

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

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final category = Category(
      id: widget.category?.id,
      name: name,
      icon: IconRef(
        codePoint: _selectedIcon.codePoint,
        fontFamily: _selectedIcon.fontFamily ?? 'MaterialIcons',
      ),
      emoji: _selectedEmoji,
      type: widget.type,
    );
    Navigator.pop(context, category);
  }
}

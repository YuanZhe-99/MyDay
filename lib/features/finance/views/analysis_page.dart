import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../models/finance.dart';
import '../services/balance_util.dart';
import '../services/exchange_rate_storage.dart';

enum _TimeRange { year, month, day, custom }

class AnalysisPage extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final ExchangeRateData rateData;
  final String defaultCurrency;

  const AnalysisPage({
    super.key,
    required this.transactions,
    required this.categories,
    required this.rateData,
    this.defaultCurrency = 'CNY',
  });

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  _TimeRange _timeRange = _TimeRange.month;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Filter transactions based on the current time range selection.
  List<Transaction> get _filteredTransactions {
    switch (_timeRange) {
      case _TimeRange.year:
        return widget.transactions
            .where((t) => t.date.year == _selectedMonth.year)
            .toList();
      case _TimeRange.month:
        return widget.transactions
            .where((t) =>
                t.date.year == _selectedMonth.year &&
                t.date.month == _selectedMonth.month)
            .toList();
      case _TimeRange.day:
        final d = _selectedMonth;
        return widget.transactions
            .where((t) =>
                t.date.year == d.year &&
                t.date.month == d.month &&
                t.date.day == d.day)
            .toList();
      case _TimeRange.custom:
        if (_customRange == null) return [];
        return widget.transactions
            .where((t) =>
                !t.date.isBefore(_customRange!.start) &&
                t.date.isBefore(
                    _customRange!.end.add(const Duration(days: 1))))
            .toList();
    }
  }

  List<Transaction> get _filteredExpenses =>
      _filteredTransactions.where((t) => t.type == TransactionType.expense).toList();

  String get _rangeLabel {
    switch (_timeRange) {
      case _TimeRange.year:
        return '${_selectedMonth.year}';
      case _TimeRange.month:
        return DateFormat('yyyy-MM').format(_selectedMonth);
      case _TimeRange.day:
        return DateFormat('yyyy-MM-dd').format(_selectedMonth);
      case _TimeRange.custom:
        if (_customRange == null) return 'Select range';
        return '${DateFormat('MM-dd').format(_customRange!.start)} ~ ${DateFormat('MM-dd').format(_customRange!.end)}';
    }
  }

  void _prev() {
    setState(() {
      switch (_timeRange) {
        case _TimeRange.year:
          _selectedMonth = DateTime(_selectedMonth.year - 1, _selectedMonth.month);
        case _TimeRange.month:
          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
        case _TimeRange.day:
          _selectedMonth = _selectedMonth.subtract(const Duration(days: 1));
        case _TimeRange.custom:
          break;
      }
    });
  }

  void _next() {
    setState(() {
      switch (_timeRange) {
        case _TimeRange.year:
          _selectedMonth = DateTime(_selectedMonth.year + 1, _selectedMonth.month);
        case _TimeRange.month:
          _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
        case _TimeRange.day:
          _selectedMonth = _selectedMonth.add(const Duration(days: 1));
        case _TimeRange.custom:
          break;
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() => _customRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.financeAnalysis),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Time range mode selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SegmentedButton<_TimeRange>(
              segments: [
                ButtonSegment(value: _TimeRange.year, label: Text(AppLocalizations.of(context)!.financeByYear)),
                ButtonSegment(value: _TimeRange.month, label: Text(AppLocalizations.of(context)!.financeByMonth)),
                ButtonSegment(value: _TimeRange.day, label: Text(AppLocalizations.of(context)!.financeByDay)),
                ButtonSegment(value: _TimeRange.custom, label: Text(AppLocalizations.of(context)!.financeCustomRange)),
              ],
              selected: {_timeRange},
              onSelectionChanged: (s) {
                setState(() => _timeRange = s.first);
                if (s.first == _TimeRange.custom && _customRange == null) {
                  _pickCustomRange();
                }
              },
            ),
          ),
          // Date navigator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_timeRange != _TimeRange.custom)
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prev,
                  )
                else
                  const SizedBox(width: 48),
                GestureDetector(
                  onTap: _timeRange == _TimeRange.custom ? _pickCustomRange : null,
                  child: Text(
                    _rangeLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_timeRange != _TimeRange.custom)
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _next,
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPieChart(context),
                _buildTrendChart(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------- Pie Chart Tab ---------------

  Widget _buildPieChart(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = _filteredExpenses;

    if (expenses.isEmpty) {
      return Center(
        child: Text('No expense data for this period',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
      );
    }

    // Group by categoryId
    final Map<String, double> catTotals = {};
    for (final tx in expenses) {
      final key = tx.categoryId ?? 'Uncategorized';
      final rates = widget.rateData.ratesAt(tx.rateSnapshotId);
      catTotals[key] = (catTotals[key] ?? 0) +
          convertCurrency(rates, tx.amount, tx.currency, widget.defaultCurrency);
    }

    final total = catTotals.values.fold(0.0, (a, b) => a + b);
    final colors = _chartColors;

    final sections = catTotals.entries.toList().asMap().entries.map((entry) {
      final amount = entry.value.value;
      final pct = total > 0 ? (amount / total * 100) : 0.0;
      final color = colors[entry.key % colors.length];

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 70,
        badgeWidget: null,
      );
    }).toList();

    // Legend entries
    final legendEntries = catTotals.entries.toList().asMap().entries.map((entry) {
      final catId = entry.value.key;
      final amount = entry.value.value;
      final color = colors[entry.key % colors.length];

      String catName = catId;
      String? catEmoji;
      if (catId != 'Uncategorized') {
        final cat = widget.categories.where((c) => c.id == catId).firstOrNull;
        if (cat != null) {
          catName = cat.name;
          catEmoji = cat.emoji;
        }
      }

      return MapEntry(catName, (color: color, amount: amount, emoji: catEmoji));
    }).toList();

    final nf = NumberFormat('#,##0.00');
    final sym = currencySymbol(widget.defaultCurrency);

    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 36,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: theme.textTheme.titleSmall),
              Text(
                '$sym${nf.format(total)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        const Divider(indent: 24, endIndent: 24),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: legendEntries.map((e) {
              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: e.value.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (e.value.emoji != null) ...[
                      const SizedBox(width: 8),
                      Text(e.value.emoji!, style: const TextStyle(fontSize: 18)),
                    ],
                  ],
                ),
                title: Text(e.key),
                trailing: Text(
                  '$sym${nf.format(e.value.amount)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                dense: true,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --------------- Trend Line Chart Tab ---------------

  Widget _buildTrendChart(BuildContext context) {
    final theme = Theme.of(context);
    final txs = _filteredTransactions;

    // Determine the x-axis points depending on time range
    int numPoints;
    String Function(int) xLabel;

    switch (_timeRange) {
      case _TimeRange.year:
        numPoints = 12;
        xLabel = (i) => '${i + 1}';
      case _TimeRange.month:
        final daysInMonth = DateTime(
                _selectedMonth.year, _selectedMonth.month + 1, 0)
            .day;
        numPoints = daysInMonth;
        xLabel = (i) => '${i + 1}';
      case _TimeRange.day:
        numPoints = 24;
        xLabel = (i) => '${i}h';
      case _TimeRange.custom:
        if (_customRange == null) {
          return Center(
            child: Text('Select a date range',
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          );
        }
        numPoints =
            _customRange!.end.difference(_customRange!.start).inDays + 1;
        xLabel = (i) {
          final d = _customRange!.start.add(Duration(days: i));
          return '${d.month}/${d.day}';
        };
    }

    final dailyExpense = List.filled(numPoints, 0.0);
    final dailyIncome = List.filled(numPoints, 0.0);

    for (final tx in txs) {
      int idx;
      switch (_timeRange) {
        case _TimeRange.year:
          idx = tx.date.month - 1;
        case _TimeRange.month:
          idx = tx.date.day - 1;
        case _TimeRange.day:
          idx = tx.date.hour;
        case _TimeRange.custom:
          idx = tx.date.difference(_customRange!.start).inDays;
      }
      if (idx < 0 || idx >= numPoints) continue;
      final rates = widget.rateData.ratesAt(tx.rateSnapshotId);
      if (tx.type == TransactionType.expense) {
        dailyExpense[idx] += convertCurrency(rates, tx.amount, tx.currency, widget.defaultCurrency);
      } else if (tx.type == TransactionType.income) {
        dailyIncome[idx] += convertCurrency(rates, tx.amount, tx.currency, widget.defaultCurrency);
      }
    }

    // Cumulative
    for (var i = 1; i < numPoints; i++) {
      dailyExpense[i] += dailyExpense[i - 1];
      dailyIncome[i] += dailyIncome[i - 1];
    }

    final maxY = [
      ...dailyExpense,
      ...dailyIncome,
    ].fold(0.0, (a, b) => a > b ? a : b);

    if (maxY == 0) {
      return Center(
        child: Text('No transaction data for this period',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
      );
    }

    FlSpot spot(int i, double v) => FlSpot(i.toDouble(), v);

    final expenseSpots =
        List.generate(numPoints, (i) => spot(i, dailyExpense[i]));
    final incomeSpots =
        List.generate(numPoints, (i) => spot(i, dailyIncome[i]));

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.redAccent, 'Expense'),
              const SizedBox(width: 24),
              _legendDot(Colors.green, 'Income'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (numPoints - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (numPoints / 6).ceilToDouble(),
                      getTitlesWidget: (value, _) {
                        return Text(xLabel(value.toInt()),
                            style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, _) {
                        if (value == 0) return const SizedBox.shrink();
                        final label = value >= 1000
                            ? '${(value / 1000).toStringAsFixed(1)}k'
                            : value.toStringAsFixed(0);
                        return Text(label,
                            style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.redAccent.withValues(alpha: 0.08),
                    ),
                  ),
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((s) {
                      final label =
                          s.barIndex == 0 ? 'Expense' : 'Income';
                      return LineTooltipItem(
                        '$label: ${currencySymbol(widget.defaultCurrency)}${s.y.toStringAsFixed(0)}',
                        TextStyle(
                          color: s.barIndex == 0
                              ? Colors.redAccent
                              : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  static const _chartColors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.cyan,
    Colors.indigo,
    Colors.lime,
    Colors.brown,
  ];
}

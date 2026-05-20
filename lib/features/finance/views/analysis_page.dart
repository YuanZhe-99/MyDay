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
  final List<Account> accounts;
  final ExchangeRateData rateData;
  final String defaultCurrency;

  /// Purpose: Create a analysis page instance.
  /// Inputs: `accounts`.
  /// Returns: A new `AnalysisPage` instance.
  /// Side effects: None.
  /// Notes: None.
  const AnalysisPage({
    super.key,
    required this.transactions,
    required this.categories,
    this.accounts = const [],
    required this.rateData,
    this.defaultCurrency = 'CNY',
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  _TimeRange _timeRange = _TimeRange.month;
  DateTimeRange? _customRange;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Releases owned resources and unregisters listeners.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Filter transactions based on the current time range selection.
  /// Purpose: Return filtered transactions.
  /// Inputs: None.
  /// Returns: `List<Transaction>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Transaction> get _filteredTransactions {
    switch (_timeRange) {
      case _TimeRange.year:
        return widget.transactions
            .where((t) => t.date.year == _selectedMonth.year)
            .toList();
      case _TimeRange.month:
        return widget.transactions
            .where(
              (t) =>
                  t.date.year == _selectedMonth.year &&
                  t.date.month == _selectedMonth.month,
            )
            .toList();
      case _TimeRange.day:
        final d = _selectedMonth;
        return widget.transactions
            .where(
              (t) =>
                  t.date.year == d.year &&
                  t.date.month == d.month &&
                  t.date.day == d.day,
            )
            .toList();
      case _TimeRange.custom:
        if (_customRange == null) return [];
        return widget.transactions
            .where(
              (t) =>
                  !t.date.isBefore(_customRange!.start) &&
                  t.date.isBefore(
                    _customRange!.end.add(const Duration(days: 1)),
                  ),
            )
            .toList();
    }
  }

  /// Purpose: Return filtered expenses.
  /// Inputs: None.
  /// Returns: `List<Transaction>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  List<Transaction> get _filteredExpenses => _filteredTransactions
      .where((t) => t.type == TransactionType.expense)
      .toList();

  /// Purpose: Return range label.
  /// Inputs: `l10n`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  String _rangeLabel(AppLocalizations l10n) {
    switch (_timeRange) {
      case _TimeRange.year:
        return '${_selectedMonth.year}';
      case _TimeRange.month:
        return DateFormat('yyyy-MM').format(_selectedMonth);
      case _TimeRange.day:
        return DateFormat('yyyy-MM-dd').format(_selectedMonth);
      case _TimeRange.custom:
        if (_customRange == null) return l10n.financeSelectDateRange;
        return '${DateFormat('MM-dd').format(_customRange!.start)} ~ ${DateFormat('MM-dd').format(_customRange!.end)}';
    }
  }

  /// Purpose: Provide the internal prev helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _prev() {
    setState(() {
      switch (_timeRange) {
        case _TimeRange.year:
          _selectedMonth = DateTime(
            _selectedMonth.year - 1,
            _selectedMonth.month,
          );
        case _TimeRange.month:
          _selectedMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month - 1,
          );
        case _TimeRange.day:
          _selectedMonth = _selectedMonth.subtract(const Duration(days: 1));
        case _TimeRange.custom:
          break;
      }
    });
  }

  /// Purpose: Provide the internal next helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _next() {
    setState(() {
      switch (_timeRange) {
        case _TimeRange.year:
          _selectedMonth = DateTime(
            _selectedMonth.year + 1,
            _selectedMonth.month,
          );
        case _TimeRange.month:
          _selectedMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month + 1,
          );
        case _TimeRange.day:
          _selectedMonth = _selectedMonth.add(const Duration(days: 1));
        case _TimeRange.custom:
          break;
      }
    });
  }

  /// Purpose: Provide the internal pick custom range helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() => _customRange = picked);
    }
  }

  /// Purpose: Build the custom range segment label with re-edit support.
  /// Inputs: `l10n`.
  /// Returns: `Widget`.
  /// Side effects: May open the custom date range picker when already selected.
  /// Notes: The tap handler is enabled only while already in custom mode so switching modes still uses `SegmentedButton` normally.
  Widget _buildCustomRangeSegmentLabel(AppLocalizations l10n) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _timeRange == _TimeRange.custom ? _pickCustomRange : null,
      child: Text(l10n.financeCustomRange),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financeAnalysis),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.financeCategories),
            Tab(text: l10n.financeTrends),
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
                ButtonSegment(
                  value: _TimeRange.year,
                  label: Text(l10n.financeByYear),
                ),
                ButtonSegment(
                  value: _TimeRange.month,
                  label: Text(l10n.financeByMonth),
                ),
                ButtonSegment(
                  value: _TimeRange.day,
                  label: Text(l10n.financeByDay),
                ),
                ButtonSegment(
                  value: _TimeRange.custom,
                  label: _buildCustomRangeSegmentLabel(l10n),
                ),
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
                  onTap: _timeRange == _TimeRange.custom
                      ? _pickCustomRange
                      : null,
                  child: Text(
                    _rangeLabel(l10n),
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
                  IconButton(
                    icon: const Icon(Icons.edit_calendar_outlined),
                    tooltip: l10n.financeSelectDateRange,
                    onPressed: _pickCustomRange,
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPieChart(context), _buildTrendChart(context)],
            ),
          ),
        ],
      ),
    );
  }

  // --------------- Pie Chart Tab ---------------

  /// Purpose: Provide the internal build pie chart helper for this file.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildPieChart(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = _filteredExpenses;

    if (expenses.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.financeNoExpenseData,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Group by categoryId
    final Map<String, double> catTotals = {};
    for (final tx in expenses) {
      final key = tx.categoryId ?? 'Uncategorized';
      final rates = widget.rateData.ratesAt(tx.rateSnapshotId);
      catTotals[key] =
          (catTotals[key] ?? 0) +
          convertCurrency(
            rates,
            tx.amount,
            tx.currency,
            widget.defaultCurrency,
          );
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
    final legendEntries = catTotals.entries.toList().asMap().entries.map((
      entry,
    ) {
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
      } else {
        catName = AppLocalizations.of(context)!.financeUncategorized;
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
              Text(
                AppLocalizations.of(context)!.financeTotal,
                style: theme.textTheme.titleSmall,
              ),
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
                      Text(
                        e.value.emoji!,
                        style: const TextStyle(fontSize: 18),
                      ),
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

  /// Purpose: Provide the internal build trend chart helper for this file.
  /// Inputs: `context`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildTrendChart(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_timeRange == _TimeRange.custom && _customRange == null) {
      return Center(
        child: Text(
          l10n.financeSelectDateRange,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final scale = _buildTrendScale();
    final trendData = _buildTrendData(scale);
    final hasFlowData = trendData.flowMaxY > 0;
    final hasAssetsData = trendData.assetMinY != 0 || trendData.assetMaxY != 0;

    if (!hasFlowData && !hasAssetsData) {
      return Center(
        child: Text(
          l10n.financeNoTransactionData,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      children: [
        if (hasFlowData)
          _buildLineChartPanel(
            context: context,
            title: l10n.financeTrends,
            scale: scale,
            minY: 0,
            maxY: trendData.flowMaxY,
            anchorZero: true,
            series: [
              _ChartSeries(
                label: l10n.financeExpenseTrend,
                color: Colors.redAccent,
                spots: trendData.expenseSpots,
                fill: true,
              ),
              _ChartSeries(
                label: l10n.financeIncomeTrend,
                color: Colors.green,
                spots: trendData.incomeSpots,
                fill: true,
              ),
            ],
          ),
        if (hasFlowData && hasAssetsData) const SizedBox(height: 24),
        if (hasAssetsData)
          _buildLineChartPanel(
            context: context,
            title: l10n.financeAssetsTrend,
            scale: scale,
            minY: trendData.assetMinY,
            maxY: trendData.assetMaxY,
            anchorZero: false,
            series: [
              _ChartSeries(
                label: l10n.financeAssetsTrend,
                color: theme.colorScheme.primary,
                spots: trendData.assetSpots,
              ),
            ],
          ),
      ],
    );
  }

  /// Purpose: Provide the internal build trend scale helper for this file.
  /// Inputs: None.
  /// Returns: `_TrendScale`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  _TrendScale _buildTrendScale() {
    final dateLabel = DateFormat('M/d');
    final dayTooltip = DateFormat('yyyy-MM-dd');
    final hourTooltip = DateFormat('yyyy-MM-dd HH:00');

    switch (_timeRange) {
      case _TimeRange.year:
        final start = DateTime(_selectedMonth.year);
        final end = DateTime(_selectedMonth.year + 1);
        const step = Duration(days: 1);
        final pointCount = _pointCount(start, end, step);
        return _TrendScale(
          start: start,
          endExclusive: end,
          step: step,
          pointCount: pointCount,
          labelInterval: _labelInterval(pointCount),
          labelForDate: dateLabel.format,
          tooltipForDate: dayTooltip.format,
        );
      case _TimeRange.month:
        final start = DateTime(_selectedMonth.year, _selectedMonth.month);
        final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
        const step = Duration(hours: 1);
        final pointCount = _pointCount(start, end, step);
        return _TrendScale(
          start: start,
          endExclusive: end,
          step: step,
          pointCount: pointCount,
          labelInterval: _labelInterval(pointCount),
          labelForDate: dateLabel.format,
          tooltipForDate: hourTooltip.format,
        );
      case _TimeRange.day:
        final start = DateTime(
          _selectedMonth.year,
          _selectedMonth.month,
          _selectedMonth.day,
        );
        final end = start.add(const Duration(days: 1));
        const step = Duration(hours: 1);
        final pointCount = _pointCount(start, end, step);
        return _TrendScale(
          start: start,
          endExclusive: end,
          step: step,
          pointCount: pointCount,
          labelInterval: 4,
          labelForDate: (date) => '${date.hour}h',
          tooltipForDate: hourTooltip.format,
        );
      case _TimeRange.custom:
        final range = _customRange!;
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final end = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
        ).add(const Duration(days: 1));
        final hours = end.difference(start).inHours;
        final step = hours <= 48
            ? const Duration(hours: 1)
            : hours <= 45 * 24
            ? const Duration(hours: 6)
            : const Duration(days: 1);
        final pointCount = _pointCount(start, end, step);
        return _TrendScale(
          start: start,
          endExclusive: end,
          step: step,
          pointCount: pointCount,
          labelInterval: _labelInterval(pointCount),
          labelForDate: dateLabel.format,
          tooltipForDate: step.inHours < 24
              ? hourTooltip.format
              : dayTooltip.format,
        );
    }
  }

  /// Purpose: Provide the internal build trend data helper for this file.
  /// Inputs: `scale`.
  /// Returns: `_TrendData`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  _TrendData _buildTrendData(_TrendScale scale) {
    final expense = List.filled(scale.pointCount, 0.0);
    final income = List.filled(scale.pointCount, 0.0);

    for (final tx in widget.transactions) {
      final idx = scale.bucketIndex(tx.date);
      if (idx == null) continue;

      final rates = widget.rateData.ratesAt(tx.rateSnapshotId);
      final amount = convertCurrency(
        rates,
        tx.amount,
        tx.currency,
        widget.defaultCurrency,
      );
      if (tx.type == TransactionType.expense) {
        expense[idx] += amount;
      } else if (tx.type == TransactionType.income) {
        income[idx] += amount;
      }
    }

    for (var i = 1; i < scale.pointCount; i++) {
      expense[i] += expense[i - 1];
      income[i] += income[i - 1];
    }

    final assets = List.generate(
      scale.pointCount,
      (i) => _totalAssetsBefore(scale.sampleEnd(i)),
    );

    final flowMaxY = [...expense, ...income].fold(0.0, (a, b) => a > b ? a : b);
    final assetMinY = assets.fold(assets.first, (a, b) => a < b ? a : b);
    final assetMaxY = assets.fold(assets.first, (a, b) => a > b ? a : b);

    return _TrendData(
      expenseSpots: List.generate(
        scale.pointCount,
        (i) => FlSpot(i.toDouble(), expense[i]),
      ),
      incomeSpots: List.generate(
        scale.pointCount,
        (i) => FlSpot(i.toDouble(), income[i]),
      ),
      assetSpots: List.generate(
        scale.pointCount,
        (i) => FlSpot(i.toDouble(), assets[i]),
      ),
      flowMaxY: flowMaxY,
      assetMinY: assetMinY,
      assetMaxY: assetMaxY,
    );
  }

  /// Purpose: Provide the internal total assets before helper for this file.
  /// Inputs: `before`.
  /// Returns: `double`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  double _totalAssetsBefore(DateTime before) {
    if (widget.accounts.isEmpty) {
      var total = 0.0;
      for (final tx in widget.transactions) {
        if (!tx.date.isBefore(before)) continue;
        final rates = widget.rateData.ratesAt(tx.rateSnapshotId);
        final amount = convertCurrency(
          rates,
          tx.amount,
          tx.currency,
          widget.defaultCurrency,
        );
        switch (tx.type) {
          case TransactionType.expense:
            total -= amount;
          case TransactionType.income:
            total += amount;
          case TransactionType.transfer:
            break;
        }
      }
      return total;
    }

    final currentRates = widget.rateData.currentRates;
    return widget.accounts.fold(0.0, (sum, account) {
      final balance = accountBalanceBefore(
        account,
        widget.transactions,
        widget.rateData,
        before,
      );
      return sum +
          convertCurrency(
            currentRates,
            balance,
            account.currency,
            widget.defaultCurrency,
          );
    });
  }

  /// Purpose: Provide the internal build line chart panel helper for this file.
  /// Inputs: None.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  Widget _buildLineChartPanel({
    required BuildContext context,
    required String title,
    required _TrendScale scale,
    required List<_ChartSeries> series,
    required double minY,
    required double maxY,
    required bool anchorZero,
  }) {
    final theme = Theme.of(context);
    final bounds = _chartBounds(minY, maxY, anchorZero: anchorZero);
    final yRange = bounds.maxY - bounds.minY;
    final horizontalInterval = yRange > 0 ? yRange / 4 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 8,
          children: series.map((s) => _legendDot(s.color, s.label)).toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (scale.pointCount - 1).toDouble(),
              minY: bounds.minY,
              maxY: bounds.maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: horizontalInterval,
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: scale.labelInterval,
                    getTitlesWidget: (value, _) {
                      final idx = value.round();
                      if ((value - idx).abs() > 0.01 ||
                          idx < 0 ||
                          idx >= scale.pointCount) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          scale.xLabel(idx),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: horizontalInterval,
                    getTitlesWidget: (value, _) {
                      if (value == bounds.minY || value == bounds.maxY) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        _formatAxisValue(value),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: series
                  .map(
                    (s) => LineChartBarData(
                      spots: s.spots,
                      isCurved: s.spots.length > 2,
                      curveSmoothness: 0.16,
                      preventCurveOverShooting: true,
                      color: s.color,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: s.fill,
                        color: s.color.withValues(alpha: 0.08),
                      ),
                    ),
                  )
                  .toList(),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((spot) {
                    var idx = spot.x.round();
                    if (idx < 0) idx = 0;
                    if (idx >= scale.pointCount) idx = scale.pointCount - 1;
                    final s = series[spot.barIndex];
                    return LineTooltipItem(
                      '${scale.tooltipLabel(idx)}\n'
                      '${s.label}: ${currencySymbol(widget.defaultCurrency)}'
                      '${spot.y.toStringAsFixed(0)}',
                      TextStyle(
                        color: s.color,
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
    );
  }

  ({double minY, double maxY}) _chartBounds(
    double minY,
    double maxY, {
    required bool anchorZero,
  }) {
    if (minY == maxY) {
      final padding = minY.abs() * 0.1;
      final safePadding = padding == 0 ? 1.0 : padding;
      if (anchorZero) {
        return (minY: 0, maxY: maxY + safePadding);
      }
      return (minY: minY - safePadding, maxY: maxY + safePadding);
    }

    final padding = (maxY - minY).abs() * 0.1;
    if (anchorZero) {
      return (minY: 0, maxY: maxY + padding);
    }
    return (minY: minY - padding, maxY: maxY + padding);
  }

  /// Purpose: Provide the internal point count helper for this file.
  /// Inputs: `start`, `end`, `step`.
  /// Returns: `int`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  int _pointCount(DateTime start, DateTime end, Duration step) {
    final total = end.difference(start).inMicroseconds;
    final stepMicros = step.inMicroseconds;
    final count = (total + stepMicros - 1) ~/ stepMicros;
    return count < 1 ? 1 : count;
  }

  /// Purpose: Provide the internal label interval helper for this file.
  /// Inputs: `pointCount`.
  /// Returns: `double`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  double _labelInterval(int pointCount) {
    final interval = (pointCount / 6).ceil();
    return (interval < 1 ? 1 : interval).toDouble();
  }

  /// Purpose: Provide the internal format axis value helper for this file.
  /// Inputs: `value`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  String _formatAxisValue(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 1000000) {
      return '$sign${(abs / 1000000).toStringAsFixed(1)}m';
    }
    if (abs >= 1000) {
      return '$sign${(abs / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  /// Purpose: Provide the internal legend dot helper for this file.
  /// Inputs: `color`, `label`.
  /// Returns: `Widget`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
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

class _TrendScale {
  final DateTime start;
  final DateTime endExclusive;
  final Duration step;
  final int pointCount;
  final double labelInterval;
  final String Function(DateTime date) labelForDate;
  final String Function(DateTime date) tooltipForDate;

  /// Purpose: Create a trend scale instance.
  /// Inputs: None.
  /// Returns: A new `_TrendScale` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _TrendScale({
    required this.start,
    required this.endExclusive,
    required this.step,
    required this.pointCount,
    required this.labelInterval,
    required this.labelForDate,
    required this.tooltipForDate,
  });

  /// Purpose: Implement the bucket index behavior for this file.
  /// Inputs: `date`.
  /// Returns: `int?`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  int? bucketIndex(DateTime date) {
    if (date.isBefore(start) || !date.isBefore(endExclusive)) return null;
    final idx = date.difference(start).inMicroseconds ~/ step.inMicroseconds;
    if (idx < 0 || idx >= pointCount) return null;
    return idx;
  }

  /// Purpose: Implement the sample end behavior for this file.
  /// Inputs: `index`.
  /// Returns: `DateTime`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  DateTime sampleEnd(int index) {
    final end = _offset(index + 1);
    return end.isAfter(endExclusive) ? endExclusive : end;
  }

  /// Purpose: Implement the x label behavior for this file.
  /// Inputs: `index`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  String xLabel(int index) => labelForDate(_offset(index));

  /// Purpose: Implement the tooltip label behavior for this file.
  /// Inputs: `index`.
  /// Returns: `String`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  String tooltipLabel(int index) => tooltipForDate(_offset(index));

  /// Purpose: Provide the internal offset helper for this file.
  /// Inputs: `steps`.
  /// Returns: `DateTime`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  DateTime _offset(int steps) {
    return start.add(Duration(microseconds: step.inMicroseconds * steps));
  }
}

class _TrendData {
  final List<FlSpot> expenseSpots;
  final List<FlSpot> incomeSpots;
  final List<FlSpot> assetSpots;
  final double flowMaxY;
  final double assetMinY;
  final double assetMaxY;

  /// Purpose: Create a trend data instance.
  /// Inputs: None.
  /// Returns: A new `_TrendData` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _TrendData({
    required this.expenseSpots,
    required this.incomeSpots,
    required this.assetSpots,
    required this.flowMaxY,
    required this.assetMinY,
    required this.assetMaxY,
  });
}

class _ChartSeries {
  final String label;
  final Color color;
  final List<FlSpot> spots;
  final bool fill;

  /// Purpose: Create a chart series instance.
  /// Inputs: `fill`.
  /// Returns: A new `_ChartSeries` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _ChartSeries({
    required this.label,
    required this.color,
    required this.spots,
    this.fill = false,
  });
}

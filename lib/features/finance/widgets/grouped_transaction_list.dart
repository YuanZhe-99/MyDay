import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/adaptive_tile_grid.dart';
import '../models/finance.dart';

/// Day-key formatter shared by every build; creating one per transaction was measurable
/// on long histories. The pattern is locale-independent.
final DateFormat _dayKeyFormat = DateFormat('yyyy-MM-dd');

/// Builds a date-grouped transaction list with date headers.
/// Purpose: Implement the build grouped transaction list behavior for this file.
/// Inputs: `context`, `sorted`, `tileBuilder`, `columns`, `sliver`.
/// Returns: `Widget`.
/// Side effects: Creates UI widgets from grouped transaction data.
/// Notes: `columns` defaults to 1, which builds exactly the flat header/tile
/// list this has always built. Above 1, the tiles **within each date group**
/// are packed into rows while the headers stay full width, so a wide window
/// never shows one date's header stranded beside another date's transactions.
/// The rows come from `adaptiveTileRows`, which returns tiles untouched at one
/// column, so the `Dismissible` wrappers callers pass in are unaffected. The
/// outer widget stays a `ListView.builder` at every column count, so the
/// virtualization a long transaction history depends on is preserved.
/// `sliver: true` (v1.8.2) returns the same rows as a lazily built
/// `SliverList` instead, for a page that scrolls its header blocks and the
/// list together in one `CustomScrollView`.
Widget buildGroupedTransactionList(
  BuildContext context,
  List<Transaction> sorted,
  Widget Function(Transaction) tileBuilder, {
  int columns = 1,
  bool sliver = false,
}) {
  final perRow = columns < 1 ? 1 : columns;
  final items = <({bool isHeader, String? label, List<Transaction> group})>[];
  String? lastDate;
  final current = <Transaction>[];

  /// Purpose: Flush the transactions collected for the current date.
  /// Inputs: None — reads `current` and `perRow` from the enclosing scope.
  /// Returns: None.
  /// Side effects: Appends row entries to `items` and clears `current`.
  /// Notes: Internal helper used within this function only.
  void flush() {
    for (var start = 0; start < current.length; start += perRow) {
      items.add((
        isHeader: false,
        label: null,
        group: current.sublist(
          start,
          start + perRow > current.length ? current.length : start + perRow,
        ),
      ));
    }
    current.clear();
  }

  for (final tx in sorted) {
    final dateKey = _dayKeyFormat.format(tx.date);
    if (dateKey != lastDate) {
      flush();
      items.add((isHeader: true, label: dateKey, group: const []));
      lastDate = dateKey;
    }
    current.add(tx);
  }
  flush();

  final theme = Theme.of(context);

  /// Purpose: Build one header or tile row of the grouped list.
  /// Inputs: `context`, `index` — the row's position in `items`.
  /// Returns: `Widget` — a date header or a row of transaction tiles.
  /// Side effects: None.
  /// Notes: Shared by the `ListView` and `SliverList` forms so both build
  /// identical rows.
  Widget itemBuilder(BuildContext context, int index) {
    final item = items[index];
    if (item.isHeader) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        color: theme.colorScheme.surfaceContainerLow,
        child: Text(
          item.label!,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    final row = adaptiveTileRows(
      columns: perRow,
      itemCount: item.group.length,
      itemBuilder: (i) => tileBuilder(item.group[i]),
    );
    if (perRow <= 1) return row.single;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: row.single,
    );
  }

  return sliver
      ? SliverList.builder(itemCount: items.length, itemBuilder: itemBuilder)
      : ListView.builder(itemCount: items.length, itemBuilder: itemBuilder);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/adaptive_tile_grid.dart';
import '../models/finance.dart';

/// Builds a date-grouped transaction list with date headers.
/// Purpose: Implement the build grouped transaction list behavior for this file.
/// Inputs: `context`, `sorted`, `tileBuilder`, `columns`.
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
Widget buildGroupedTransactionList(
  BuildContext context,
  List<Transaction> sorted,
  Widget Function(Transaction) tileBuilder, {
  int columns = 1,
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
    final dateKey = DateFormat('yyyy-MM-dd').format(tx.date);
    if (dateKey != lastDate) {
      flush();
      items.add((isHeader: true, label: dateKey, group: const []));
      lastDate = dateKey;
    }
    current.add(tx);
  }
  flush();

  final theme = Theme.of(context);

  return ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
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
    },
  );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/finance.dart';

/// Builds a date-grouped transaction list with date headers.
Widget buildGroupedTransactionList(
  BuildContext context,
  List<Transaction> sorted,
  Widget Function(Transaction) tileBuilder,
) {
  final items = <({bool isHeader, String? label, Transaction? tx})>[];
  String? lastDate;
  for (final tx in sorted) {
    final dateKey = DateFormat('yyyy-MM-dd').format(tx.date);
    if (dateKey != lastDate) {
      items.add((isHeader: true, label: dateKey, tx: null));
      lastDate = dateKey;
    }
    items.add((isHeader: false, label: null, tx: tx));
  }

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
      return tileBuilder(item.tx!);
    },
  );
}

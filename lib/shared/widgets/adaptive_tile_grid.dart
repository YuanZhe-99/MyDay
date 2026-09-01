import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/adaptive_layout.dart';

/// Purpose: Build one row of a multi-column list, filled left to right.
/// Inputs: `rowIndex` — the zero-based row; `columns` — tiles per row;
/// `itemCount` — total tiles in the list; `itemBuilder` — builds one tile by
/// its index in the flat list; `gap` — spacing between columns.
/// Returns: A `Row` of equally wide tiles.
/// Side effects: None.
/// Notes: Deliberately a `Row` of `Expanded` children rather than a `GridView`.
/// MyDay's list surfaces build their tiles as children of an outer scroll view
/// — often grouped under week headers — where a nested scrollable would need
/// `shrinkWrap`, and the finance list relies on `ListView.builder`
/// virtualization that a pre-built grid would throw away. Feeding this from a
/// builder over [listRowCount] rows keeps both properties and yields
/// left-to-right, top-to-bottom order. Short final rows are padded with empty
/// cells so the remaining tiles keep their width instead of stretching.
Widget adaptiveTileRow({
  required int rowIndex,
  required int columns,
  required int itemCount,
  required Widget Function(int index) itemBuilder,
  double gap = listTileGap,
}) {
  final children = <Widget>[];
  for (var column = 0; column < columns; column++) {
    if (column > 0) children.add(SizedBox(width: gap));
    final index = rowIndex * columns + column;
    children.add(
      Expanded(
        child: index < itemCount ? itemBuilder(index) : const SizedBox.shrink(),
      ),
    );
  }
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
}

/// Purpose: Build a list's children as rows, single column or multi-column.
/// Inputs: `columns`, `itemCount`, `itemBuilder`, `gap`.
/// Returns: A list of widgets ready to spread into a `ListView` or `Column`.
/// Side effects: None.
/// Notes: At one column this returns the tiles untouched, so callers that wrap
/// their single-column tile in something else — the finance list's
/// `Dismissible`, for instance — keep their existing widget tree exactly.
List<Widget> adaptiveTileRows({
  required int columns,
  required int itemCount,
  required Widget Function(int index) itemBuilder,
  double gap = listTileGap,
}) {
  if (columns <= 1) {
    return List.generate(itemCount, itemBuilder);
  }
  return List.generate(
    listRowCount(itemCount, columns),
    (rowIndex) => adaptiveTileRow(
      rowIndex: rowIndex,
      columns: columns,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      gap: gap,
    ),
  );
}

/// Purpose: Build the app-bar control that picks a list's column count.
/// Inputs: `context`; `preference` — the stored choice; `capacity` — the most
/// columns the current width can carry; `maxColumns` — the ceiling this list
/// offers; `onChanged` — receives the new preference.
/// Returns: A `PopupMenuButton`, or an empty widget when the window cannot
/// carry more than one column.
/// Side effects: None beyond invoking `onChanged` when the user picks.
/// Notes: Hidden rather than disabled when `capacity` is 1, so a phone and a
/// folded cover screen never show a control that could not do anything. The
/// menu always offers every count up to `maxColumns` so a preference can be set
/// while folded and take effect on unfolding; the check mark tracks the stored
/// preference, while what renders is that preference clamped to what fits.
Widget listColumnsButton(
  BuildContext context, {
  required int preference,
  required int capacity,
  required ValueChanged<int> onChanged,
  int maxColumns = listMaxColumns,
}) {
  if (capacity <= 1) return const SizedBox.shrink();
  final l10n = AppLocalizations.of(context)!;
  return PopupMenuButton<int>(
    icon: const Icon(Icons.view_column_outlined),
    tooltip: l10n.listColumns,
    initialValue: preference,
    onSelected: onChanged,
    itemBuilder: (context) => [
      PopupMenuItem(value: listColumnsAuto, child: Text(l10n.listColumnsAuto)),
      for (var n = 1; n <= maxColumns; n++)
        PopupMenuItem(value: n, child: Text(l10n.listColumnsCount(n))),
    ],
  );
}

/// Purpose: Centre a page's content once the window is wider than it needs.
/// Inputs: `maxWidth` — the widest the content should ever grow; `child`.
/// Returns: A widget that centres and caps `child`, or `child`'s layout
/// unchanged on any window narrower than `maxWidth`.
/// Side effects: None beyond building widgets.
/// Notes: This is what a form or a prose page does with a desktop window
/// instead of splitting: a `ListTile` stretched across 1400 logical pixels puts
/// its title and its trailing control at opposite ends of the screen. Width
/// only and no gate, so it can never change what a phone renders — see
/// `doc/en-us/adaptive-layout.md`. Wrap the **scrollable**, not its children,
/// so the scrollbar and the scroll gesture still span the whole window.
class AdaptiveContentWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  /// Purpose: Create an adaptive content width wrapper.
  /// Inputs: `key`, `maxWidth`, `child`.
  /// Returns: A new `AdaptiveContentWidth` instance.
  /// Side effects: None.
  /// Notes: None.
  const AdaptiveContentWidth({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: `Align` rather than `Center` so the child keeps its own vertical
  /// sizing; a `Center` would try to shrink-wrap a `ListView`'s height.
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Purpose: Return the inset padding that keeps a dialog at a readable width.
/// Inputs: `context`.
/// Returns: `EdgeInsets` — Flutter's own default on a narrow window, more
/// horizontal inset on a wide one.
/// Side effects: None.
/// Notes: The vertical 24 is Flutter's default and is kept as-is; only the
/// horizontal inset varies. Pass it to `Dialog.insetPadding`, which needs no
/// other change to the dialog's own tree.
EdgeInsets adaptiveDialogInset(BuildContext context) {
  return EdgeInsets.symmetric(
    horizontal: dialogHorizontalInset(MediaQuery.sizeOf(context).width),
    vertical: 24,
  );
}

# lib/shared/widgets/adaptive_tile_grid.dart

The pieces of shared UI that turn `lib/shared/utils/adaptive_layout.dart`'s arithmetic
into widgets: a helper that lays a flat list of tiles out as rows of equal columns, the app-bar
control that lets the user pin a column count, a wrapper that caps and centres a page too wide for
its content, and the inset that keeps a dialog readable. All of them are deliberately thin —
every threshold and
every clamp lives in the policy module (see
[../utils/adaptive_layout.md](../utils/adaptive_layout.md)), and the reasoning behind the numbers
lives in [../../../adaptive-layout.md](../../../adaptive-layout.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`adaptiveTileRow`](#adaptivetilerow) | top-level function | A | Build one row of a multi-column list, filled left to right. |
| [`adaptiveTileRows`](#adaptivetilerows) | top-level function | A | Build a list's children as rows, single column or multi-column. |
| [`listColumnsButton`](#listcolumnsbutton) | top-level function | A | Build the app-bar control that picks a list's column count. |
| [`AdaptiveContentWidth`](#adaptivecontentwidth) | class (`StatelessWidget`) | A | Centre a page's content once the window is wider than it needs. |
| `AdaptiveContentWidth({...})` | constructor (`AdaptiveContentWidth`) | B | Create an adaptive content width wrapper. |
| [`build`](#adaptivecontentwidth-build) | method (`AdaptiveContentWidth`) | A | Align and cap the wrapped child. |
| [`adaptiveDialogInset`](#adaptivedialoginset) | top-level function | A | Return the inset padding that keeps a dialog at a readable width. |

`grep -c 'Purpose:' lib/shared/widgets/adaptive_tile_grid.dart` reports 7, matching all seven real
declarations in this file exactly. No misattachment or undocumented declarations found. The six
top-level functions, plus the `AdaptiveContentWidth` class and its `build`, are Tier A per the blanket rule for `shared/`; only the widget's field-initialising constructor is Tier B.

## Documentation

### `Widget adaptiveTileRow({required int rowIndex, required int columns, required int itemCount, required Widget Function(int index) itemBuilder, double gap = listTileGap})` <a id="adaptivetilerow"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/widgets/adaptive_tile_grid.dart` (line 20)
- **Purpose:** Build the `Row` for one row of a multi-column list, filled left to right from a flat
  item index.
- **Inputs:** `rowIndex` — the zero-based row; `columns` — tiles per row; `itemCount` — total tiles
  in the flat list; `itemBuilder` — builds one tile by its flat index; `gap` — spacing between
  columns.
- **Returns:** A `Row` with `crossAxisAlignment: CrossAxisAlignment.start`.
- **Side effects:** None beyond building widgets.
- **Algorithm:**
  1. For each `column` in `0 ..< columns`: insert a `SizedBox(width: gap)` before every column
     after the first.
  2. Compute the flat index as `rowIndex * columns + column`.
  3. Wrap in `Expanded`: the built tile when the index is in range, `SizedBox.shrink()` otherwise.
- **Usage:** Called only by `adaptiveTileRows`.
- **Notes:** Deliberately a `Row` of `Expanded` children rather than a `GridView`. MyDay's list
  surfaces build their tiles as children of an outer scroll view — often grouped under week headers
  — where a nested scrollable would need `shrinkWrap`, and the finance transaction list relies on
  `ListView.builder` virtualization that a pre-built grid would throw away. Padding the short final
  row with empty `Expanded` cells is what keeps the remaining tiles at their column width instead
  of letting them stretch across the row.

### `List<Widget> adaptiveTileRows({required int columns, required int itemCount, required Widget Function(int index) itemBuilder, double gap = listTileGap})` <a id="adaptivetilerows"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/widgets/adaptive_tile_grid.dart` (line 47)
- **Purpose:** Turn a flat tile list into the children a `ListView` or `Column` should render, at
  whatever column count the caller resolved.
- **Inputs:** `columns`, `itemCount`, `itemBuilder`, `gap`.
- **Returns:** `List<Widget>` — either the tiles themselves or one widget per row.
- **Side effects:** None beyond building widgets.
- **Algorithm:** `columns <= 1` → `List.generate(itemCount, itemBuilder)`; otherwise
  `List.generate(listRowCount(itemCount, columns), (rowIndex) => adaptiveTileRow(...))`.
- **Usage:**
  ```dart
  ...adaptiveTileRows(
    columns: columns,
    itemCount: records.length,
    itemBuilder: (i) => _buildTile(records[i]),
  ),
  ```
- **Notes:** The single-column branch returns the tiles **untouched**, which is the property that
  makes this safe to drop into an existing page: a caller whose one-column tile is wrapped in a
  `Dismissible` keeps exactly the widget tree it had before at every viewport that does not split.
  Row count comes from
  [../utils/adaptive_layout.md#listrowcount](../utils/adaptive_layout.md#listrowcount), so the
  ordering is left-to-right, top-to-bottom.

### `Widget listColumnsButton(BuildContext context, {required int preference, required int capacity, required ValueChanged<int> onChanged, int maxColumns = listMaxColumns})` <a id="listcolumnsbutton"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/widgets/adaptive_tile_grid.dart` (line 80)
- **Purpose:** Build the app-bar popup menu that lets the user pin a list's column count, or
  nothing at all when the window cannot carry more than one column.
- **Inputs:** `context`; `preference` — the stored choice; `capacity` — the most columns the
  current width can carry; `onChanged` — receives the new preference; `maxColumns` — the ceiling
  this list offers.
- **Returns:** A `PopupMenuButton<int>`, or `SizedBox.shrink()` when `capacity <= 1`.
- **Side effects:** None beyond invoking `onChanged` when the user picks.
- **Algorithm:**
  1. `capacity <= 1` → return `SizedBox.shrink()`.
  2. Build a `PopupMenuButton` with `Icons.view_column_outlined`, tooltip `l10n.listColumns`, and
     `initialValue: preference`.
  3. Items: `listColumnsAuto` labelled `l10n.listColumnsAuto`, then `1 .. maxColumns` labelled
     `l10n.listColumnsCount(n)`.
- **Usage:**
  ```dart
  appBar: AppBar(actions: [
    listColumnsButton(
      context,
      preference: settings.someListColumns,
      capacity: capacity,
      onChanged: (value) => notifier.setSomeListColumns(value),
    ),
  ]),
  ```
- **Notes:** **Hidden rather than disabled** when `capacity` is 1, so a phone and a folded cover
  screen never show a control that could not do anything. The menu still offers every count up to
  `maxColumns` whenever it is visible, so a preference can be set on a narrow-but-splittable window
  and take effect on unfolding; the check mark tracks the **stored** preference while what actually
  renders is that preference clamped to what fits (see
  [../utils/adaptive_layout.md#listcolumncount](../utils/adaptive_layout.md#listcolumncount)).

### `class AdaptiveContentWidth extends StatelessWidget` <a id="adaptivecontentwidth"></a>
- **Kind:** top-level class (`StatelessWidget`)
- **Source:** `lib/shared/widgets/adaptive_tile_grid.dart` (line 113)
- **Purpose:** Centre a page's content once the window is wider than the content needs.
- **Inputs:** `maxWidth` — the widest the content should ever grow; `child`.
- **Returns:** A widget.
- **Side effects:** None beyond building widgets.
- **Algorithm:** See `build` below.
- **Usage:**
  ```dart
  body: AdaptiveContentWidth(
    maxWidth: formMaxContentWidth,
    child: ListView(children: [...]),
  ),
  ```
- **Notes:** This is Rule D in widget form: what a form or a prose page does with a desktop window
  instead of splitting. A `ListTile` stretched across 1400 logical pixels puts its title and its
  trailing control at opposite ends of the screen. Width only and no gate, so it can never change
  what a phone renders. Wrap the **scrollable**, not its children, so the scrollbar and the scroll
  gesture still span the whole window.

### `Widget build(BuildContext context)` (`AdaptiveContentWidth`) <a id="adaptivecontentwidth-build"></a>
- **Kind:** method of `AdaptiveContentWidth`
- **Source:** `lib/shared/widgets/adaptive_tile_grid.dart` (line 135)
- **Purpose:** Align the child to the top centre and cap its width.
- **Inputs:** `context`; the widget's own `maxWidth` and `child`.
- **Returns:** An `Align` wrapping a `ConstrainedBox`.
- **Side effects:** None beyond building widgets.
- **Algorithm:** `Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints:
  BoxConstraints(maxWidth: maxWidth), child: child))`.
- **Usage:** Invoked by Flutter.
- **Notes:** `Align` rather than `Center` on purpose: a `Center` tries to shrink-wrap its child's
  height, which a `ListView` cannot give it.

### `EdgeInsets adaptiveDialogInset(BuildContext context)` <a id="adaptivedialoginset"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/widgets/adaptive_tile_grid.dart` (line 154)
- **Purpose:** Return the inset padding that keeps a dialog at a readable width.
- **Inputs:** `context`.
- **Returns:** `EdgeInsets` — Flutter's own default on a narrow window, more horizontal inset on a
  wide one.
- **Side effects:** None.
- **Algorithm:** `EdgeInsets.symmetric(horizontal:
  dialogHorizontalInset(MediaQuery.sizeOf(context).width), vertical: 24)`.
- **Usage:** `Dialog(insetPadding: adaptiveDialogInset(context), child: ...)` — every form dialog
  in the app passes it, and needs no other change to its own tree.
- **Notes:** The vertical 24 is Flutter's default and is kept as-is; only the horizontal inset
  varies. The numeric rule lives in the policy module — see
  [../utils/adaptive_layout.md#dialoghorizontalinset](../utils/adaptive_layout.md#dialoghorizontalinset).

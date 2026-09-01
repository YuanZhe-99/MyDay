# lib/shared/widgets/adaptive_tile_grid.dart

把 `lib/shared/utils/adaptive_layout.dart` 的算术变成组件的几件共享 UI：一个把扁平图块列表铺成等宽列行的辅助函数、让用户固定列数的 app bar 控件、一个为内容过宽的页面设上限并居中的包装器，以及让对话框保持可读的内缩值。它们都刻意做得很薄——所有阈值和所有钳制都住在策略模块里（见 [../utils/adaptive_layout.md](../utils/adaptive_layout.md)），而数字背后的推理住在 [../../../adaptive-layout.md](../../../adaptive-layout.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`adaptiveTileRow`](#adaptivetilerow) | 顶层函数 | A | 构建多列列表的一行，从左到右填充。 |
| [`adaptiveTileRows`](#adaptivetilerows) | 顶层函数 | A | 把列表的子组件构建为行，单列或多列。 |
| [`listColumnsButton`](#listcolumnsbutton) | 顶层函数 | A | 构建挑选列表列数的 app bar 控件。 |
| [`AdaptiveContentWidth`](#adaptivecontentwidth) | 类（`StatelessWidget`） | A | 在窗口宽于页面所需时把内容居中。 |
| `AdaptiveContentWidth({...})` | 构造函数（`AdaptiveContentWidth`） | B | 创建自适应内容宽度包装器。 |
| [`build`](#adaptivecontentwidth-build) | 方法（`AdaptiveContentWidth`） | A | 对齐并限定被包裹的子组件。 |
| [`adaptiveDialogInset`](#adaptivedialoginset) | 顶层函数 | A | 返回让对话框保持在可读宽度的内缩内边距。 |

`grep -c 'Purpose:' lib/shared/widgets/adaptive_tile_grid.dart` 报告 7，与本文件中全部七个真实声明完全一致。未发现错挂或未文档化的声明。六个顶层函数外加 `AdaptiveContentWidth` 类及其 `build` 均按 `shared/` 的通用规则为 Tier A；只有该组件仅初始化字段的构造函数是 Tier B。

## 文档

### `Widget adaptiveTileRow({required int rowIndex, required int columns, required int itemCount, required Widget Function(int index) itemBuilder, double gap = listTileGap})` <a id="adaptivetilerow"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/widgets/adaptive_tile_grid.dart`（第 20 行）
- **用途：** 构建多列列表某一行的 `Row`，按扁平条目索引从左到右填充。
- **输入：** `rowIndex`——从零开始的行号；`columns`——每行图块数；`itemCount`——扁平列表中的图块总数；`itemBuilder`——按扁平索引构建一个图块；`gap`——列间距。
- **返回：** 一个 `crossAxisAlignment: CrossAxisAlignment.start` 的 `Row`。
- **副作用：** 除构建组件外无。
- **算法：**
  1. 对 `0 ..< columns` 中的每个 `column`：在第一列之后的每一列前插入一个 `SizedBox(width: gap)`。
  2. 计算扁平索引为 `rowIndex * columns + column`。
  3. 用 `Expanded` 包裹：索引在范围内时是构建出的图块，否则是 `SizedBox.shrink()`。
- **用法：** 仅由 `adaptiveTileRows` 调用。
- **说明：** 刻意用 `Expanded` 子组件的 `Row` 而不是 `GridView`。MyDay 的列表界面把图块构建为外层滚动视图的子组件——常常分组在周标题之下——那里嵌套的可滚动组件会需要 `shrinkWrap`，而财务交易列表依赖 `ListView.builder` 的虚拟化，预先构建的网格会把它丢掉。用空的 `Expanded` 单元格补齐不满的最后一行，正是让剩余图块保持其列宽而不是横跨整行拉伸的原因。

### `List<Widget> adaptiveTileRows({required int columns, required int itemCount, required Widget Function(int index) itemBuilder, double gap = listTileGap})` <a id="adaptivetilerows"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/widgets/adaptive_tile_grid.dart`（第 47 行）
- **用途：** 在调用方解析出的列数下，把扁平图块列表变成 `ListView` 或 `Column` 应渲染的子组件。
- **输入：** `columns`、`itemCount`、`itemBuilder`、`gap`。
- **返回：** `List<Widget>`——要么是图块本身，要么是每行一个组件。
- **副作用：** 除构建组件外无。
- **算法：** `columns <= 1` → `List.generate(itemCount, itemBuilder)`；否则 `List.generate(listRowCount(itemCount, columns), (rowIndex) => adaptiveTileRow(...))`。
- **用法：**
  ```dart
  ...adaptiveTileRows(
    columns: columns,
    itemCount: records.length,
    itemBuilder: (i) => _buildTile(records[i]),
  ),
  ```
- **说明：** 单列分支**原样**返回图块，正是这个性质让它可以安全地放进既有页面：单列图块被 `Dismissible` 包裹的调用方，在每个不分栏的视口上都保持它原本的组件树。行数来自 [../utils/adaptive_layout.md#listrowcount](../utils/adaptive_layout.md#listrowcount)，因此顺序是从左到右、从上到下。

### `Widget listColumnsButton(BuildContext context, {required int preference, required int capacity, required ValueChanged<int> onChanged, int maxColumns = listMaxColumns})` <a id="listcolumnsbutton"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/widgets/adaptive_tile_grid.dart`（第 80 行）
- **用途：** 构建让用户固定列表列数的 app bar 弹出菜单，或在窗口放不下多于一列时什么都不构建。
- **输入：** `context`；`preference`——存储的选择；`capacity`——当前宽度能承载的最多列数；`onChanged`——接收新偏好；`maxColumns`——本列表提供的上限。
- **返回：** 一个 `PopupMenuButton<int>`，或在 `capacity <= 1` 时返回 `SizedBox.shrink()`。
- **副作用：** 除用户选择时调用 `onChanged` 外无。
- **算法：**
  1. `capacity <= 1` → 返回 `SizedBox.shrink()`。
  2. 构建带 `Icons.view_column_outlined`、提示 `l10n.listColumns` 和 `initialValue: preference` 的 `PopupMenuButton`。
  3. 菜单项：标签为 `l10n.listColumnsAuto` 的 `listColumnsAuto`，然后是标签为 `l10n.listColumnsCount(n)` 的 `1 .. maxColumns`。
- **用法：**
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
- **说明：** 在 `capacity` 为 1 时是**隐藏而不是禁用**，因此手机和折叠状态的外屏永远不会显示一个什么都做不了的控件。只要它可见，菜单仍然提供直到 `maxColumns` 的每个数字，因此偏好可以在一个窄但可分栏的窗口上设定并在展开时生效；对勾跟踪的是**存储的**偏好，而实际渲染的是该偏好钳制到放得下的结果（见 [../utils/adaptive_layout.md#listcolumncount](../utils/adaptive_layout.md#listcolumncount)）。

### `class AdaptiveContentWidth extends StatelessWidget` <a id="adaptivecontentwidth"></a>
- **种类：** 顶层类（`StatelessWidget`）
- **源：** `lib/shared/widgets/adaptive_tile_grid.dart`（第 113 行）
- **用途：** 在窗口宽于内容所需时把页面内容居中。
- **输入：** `maxWidth`——内容应当增长到的最大宽度；`child`。
- **返回：** 一个组件。
- **副作用：** 除构建组件外无。
- **算法：** 见下面的 `build`。
- **用法：**
  ```dart
  body: AdaptiveContentWidth(
    maxWidth: formMaxContentWidth,
    child: ListView(children: [...]),
  ),
  ```
- **说明：** 这是组件形式的规则 D：表单页或散文页拿桌面窗口做什么，而不是分栏。横跨 1400 逻辑像素的 `ListTile` 把标题和尾部控件放在屏幕两端。仅看宽度且没有闸门，因此它不可能改变手机渲染的东西。包裹**可滚动组件**而不是它的子组件，这样滚动条和滚动手势仍然横跨整个窗口。

### `Widget build(BuildContext context)`（`AdaptiveContentWidth`） <a id="adaptivecontentwidth-build"></a>
- **种类：** `AdaptiveContentWidth` 的方法
- **源：** `lib/shared/widgets/adaptive_tile_grid.dart`（第 135 行）
- **用途：** 把子组件对齐到顶部居中并限定其宽度。
- **输入：** `context`；以及组件自己的 `maxWidth` 和 `child`。
- **返回：** 包着 `ConstrainedBox` 的 `Align`。
- **副作用：** 除构建组件外无。
- **算法：** `Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child))`。
- **用法：** 由 Flutter 调用。
- **说明：** 刻意用 `Align` 而不是 `Center`：`Center` 会试图对子组件的高度做 shrink-wrap，而 `ListView` 给不了它这个。

### `EdgeInsets adaptiveDialogInset(BuildContext context)` <a id="adaptivedialoginset"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/widgets/adaptive_tile_grid.dart`（第 154 行）
- **用途：** 返回让对话框保持在可读宽度的内缩内边距。
- **输入：** `context`。
- **返回：** `EdgeInsets`——窄窗口上是 Flutter 自己的默认值，宽窗口上是更大的水平内缩。
- **副作用：** 无。
- **算法：** `EdgeInsets.symmetric(horizontal: dialogHorizontalInset(MediaQuery.sizeOf(context).width), vertical: 24)`。
- **用法：** `Dialog(insetPadding: adaptiveDialogInset(context), child: ...)`——应用中每个表单对话框都传它，而各自的组件树无需其他改动。
- **说明：** 垂直方向的 24 是 Flutter 的默认值并原样保留；只有水平内缩会变。数值规则住在策略模块里——见 [../utils/adaptive_layout.md#dialoghorizontalinset](../utils/adaptive_layout.md#dialoghorizontalinset)。

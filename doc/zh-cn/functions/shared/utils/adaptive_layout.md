# lib/shared/utils/adaptive_layout.dart

全应用的布局策略模块：所有阈值、所有钳制、以及决定 MyDay 如何使用平板、桌面窗口或展开的折叠屏设备所给出的空间的每一条规则。**它不引入任何东西**——不引入 `package:flutter/*`，甚至不引入 `dart:math`——因此每个决策都是无需 pump 组件树即可测试的纯函数，并且同一台设备在应用各处得到同样的答案。

每个数字的散文推导位于 [../../../adaptive-layout.md](../../../adaptive-layout.md)；本页是逐声明的参考。消费方是 [../widgets/shell_scaffold.md](../widgets/shell_scaffold.md)（导航栏）和 [../widgets/adaptive_tile_grid.md](../widgets/adaptive_tile_grid.md)（多列列表行和列数控件）。

本模块存在所要守护的不变量：**widget 文件内部出现数值宽度比较就是 bug。** 数字属于这里，并附带说明它从何而来的文档注释，页面调用具名谓词。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `splitMinWidth` | 顶层 `const double` | B | 布局可以分栏前的最小视口宽度（600）。 |
| `splitMinHeight` | 顶层 `const double` | B | 布局可以分栏前的最小视口高度（480）。 |
| `splitMinAspect` | 顶层 `const double` | B | 布局可以分栏前的最小宽高比（0.82）。 |
| `listTileGap` | 顶层 `const double` | B | 多列列表各列之间的水平间隙（12）。 |
| `listMaxColumns` | 顶层 `const int` | B | 无论窗口多宽，列表列数的上限（4）。 |
| `listColumnsAuto` | 顶层 `const int` | B | 表示「用放得下的列数」的列数偏好值（0）。 |
| `navRailMinWidth` | 顶层 `const double` | B | 外壳显示导航栏前的最小屏幕宽度（600）。 |
| `navRailWidth` | 顶层 `const double` | B | 导航栏显示时从内容中占去的逻辑像素（81）。 |
| [`canSplitLayout`](#cansplitlayout) | 顶层函数 | A | 报告布局是否可以分成窗格或列。 |
| [`useNavigationRail`](#usenavigationrail) | 顶层函数 | A | 报告外壳是否应显示导航栏。 |
| [`shellContentWidth`](#shellcontentwidth) | 顶层函数 | A | 返回外壳页面内容实际获得的宽度。 |
| [`columnCapacity`](#columncapacity) | 顶层函数 | A | 返回给定最小宽度的列在内容框里能放下几个。 |
| [`listRowCount`](#listrowcount) | 顶层函数 | A | 返回给定列数下一组条目需要几行。 |
| [`listColumnCount`](#listcolumncount) | 顶层函数 | A | 返回列表实际应渲染的列数。 |

**对账：** `grep -c 'Purpose:' lib/shared/utils/adaptive_layout.dart` 报告 6，对应 14 行。八个顶层 `const` 声明带的是说明其取值来源的散文文档注释而不是 `Purpose:` 块，与索引在别处处理顶层常量的方式一致；它们是文件表面的一部分，因此有对应行。六个函数全部按 `shared/` 下顶层函数的通用规则为 Tier A。常量为 Tier B：它们的全部内容就是取值及其理由，而这两者上表和 [../../../adaptive-layout.md](../../../adaptive-layout.md) 已经承载。

## 常量

三个分栏阈值、两个导航栏数值和三个列表数值构成 MyDay 布局策略的全部数值表面。它们的取值与兄弟应用共享，未先阅读 [../../../adaptive-layout.md](../../../adaptive-layout.md) 不得更改——尤其 `splitMinAspect` 是全应用范围的行为变更。

| 常量 | 取值 | 数字从何而来 |
|---|---|---|
| `splitMinWidth` | `600.0` | Material 的 *medium* 宽度类别和 Android 的 `sw600dp` 平板阈值。每块展开的折叠屏面板都高出它约 59 dp；每块折叠状态的外屏都远低于它。 |
| `splitMinHeight` | `480.0` | Android compact 与 medium 高度类别之间的边界。没有它，宽高比测试会放行又宽又矮的视口——折叠状态的外屏或横持的手机——并把它们分成两个逼仄的窗格。 |
| `splitMinAspect` | `0.82` | 位于 Galaxy Z Fold 8 的 0.755（4:3 面板竖持）与 Fold 7 / Fold 8 Ultra 的 0.90 之间空隙的中部附近，两侧各约 9% 余量。 |
| `listTileGap` | `12.0` | 各列之间的间距；同时也是 `columnCapacity` 算式中的间隙项。 |
| `listMaxColumns` | `4` | 一个上限，使非常宽的桌面窗口不会把列表撕成读不下去的窄列。 |
| `listColumnsAuto` | `0` | 表示「由宽度推导」的哨兵偏好值；与任何真实列数都不同，后者从 1 开始。 |
| `navRailMinWidth` | `600.0` | Material 的 *medium* 宽度类别，Google 的指南在此把导航移到侧边。与 `splitMinWidth` 相等是同一个 Material 断点的巧合，而非依赖——两条规则刻意彼此独立。 |
| `navRailWidth` | `81.0` | 80 dp 的 `NavigationRail` 加上旁边 1 dp 的 `VerticalDivider`。 |

## 文档

### `bool canSplitLayout(double width, double height)` <a id="cansplitlayout"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 51 行）
- **用途：** 从整个屏幕的形状回答全应用性的问题「这个布局可以分成窗格或列吗？」。
- **输入：** `width`、`height`——以逻辑像素表示的视口尺寸，通常是 `MediaQuery.sizeOf(context)`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：**
  1. `width < splitMinWidth` → `false`。
  2. `height < splitMinHeight` → `false`。
  3. `height <= 0` → `false`（保护下面的除法免于退化视口）。
  4. 返回 `width / height >= splitMinAspect`。
- **用法：**
  ```dart
  final screen = MediaQuery.sizeOf(context);
  if (!canSplitLayout(screen.width, screen.height)) return singleColumnBody;
  ```
- **说明：** 三个独立条件，因为任何一个单独都不够。宽高比测试是承重的那一条：正是它让 Galaxy Z Fold 8 横持时分栏（4:3）而竖持时不分栏（3:4）——同一台设备在同一个宽度上需要两个不同的答案，这是任何宽度阈值都做不到的。需要接受的代价是：这是一条关于**形状而非设备类别**的规则——4:3 平板竖持（0.75）保持单栏，和 Fold 8 完全一样。传入**屏幕**尺寸，绝不要传 `Scaffold` body 的尺寸——从高度里扣掉 app bar 会抬高比值，把竖持的 Fold 8 读成 0.80 而不是 0.755。

### `bool useNavigationRail(double screenWidth)` <a id="usenavigationrail"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 68 行）
- **用途：** 决定外壳把目的地渲染成侧边 `NavigationRail` 还是底部 `NavigationBar`。
- **输入：** `screenWidth`——以逻辑像素表示的整个屏幕宽度。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** `screenWidth >= navRailMinWidth`。
- **用法：**
  ```dart
  if (!useNavigationRail(MediaQuery.sizeOf(context).width)) {
    return Scaffold(body: widget.child, bottomNavigationBar: NavigationBar(...));
  }
  ```
  （`lib/shared/widgets/shell_scaffold.dart`——见 [../widgets/shell_scaffold.md#build](../widgets/shell_scaffold.md#build)。）
- **说明：** **刻意只看宽度，且不得经由 `canSplitLayout` 转发。** 导航栏不是分栏：它拿宽度——在此函数返回 true 时是充裕的——去换高度，而高度并不充裕。它帮助最大的恰恰是 `canSplitLayout` 刻意拒绝的那种情况——手机横持在 915 x 412，底部导航栏花掉 19% 的高度，而 915 逻辑像素的宽度闲置。

### `double shellContentWidth(double screenWidth)` <a id="shellcontentwidth"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 80 行）
- **用途：** 返回**外壳内**页面实际获得的宽度，在导航栏显示时扣除导航栏宽度。
- **输入：** `screenWidth`——以逻辑像素表示的整个屏幕宽度。
- **返回：** `double`，绝不为负。
- **副作用：** 无。
- **算法：** `useNavigationRail(screenWidth) ? screenWidth - navRailWidth : screenWidth`，下限为 0。
- **用法：**
  ```dart
  final contentWidth = shellContentWidth(MediaQuery.sizeOf(context).width);
  final columns = columnCapacity(contentWidth - 32, minItemWidth: 320);
  ```
- **说明：** 在计算**容量**的任何地方传入其结果，而把未经处理的屏幕尺寸继续传给 `canSplitLayout`，后者问的是窗口的形状而不是里面剩下的空间。**压在外壳之上的页面**——所有用 `Navigator.push` 到达的页面——没有导航栏可扣，它们的 `LayoutBuilder` 约束本身就是整个宽度；在那里调用本函数会悄悄丢掉 81 dp。

### `int columnCapacity(double contentWidth, {required double minItemWidth, double gap = listTileGap, int maxColumns = listMaxColumns})` <a id="columncapacity"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 97 行）
- **用途：** 回答「这个框里能放下几个该内容自己最小宽度的列？」，而不是为每个断点写死一个列数。
- **输入：** `contentWidth`——可用宽度，以逻辑像素计；`minItemWidth`——一列可以有的最窄宽度；`gap`——列间距；`maxColumns`——无论框有多宽的上限。
- **返回：** `int`，至少 1，至多 `maxColumns`。
- **副作用：** 无。
- **算法：**
  1. `ceiling = maxColumns < 1 ? 1 : maxColumns`。
  2. `contentWidth <= 0` → 返回 1。
  3. `minItemWidth <= 0` → 返回 `ceiling`。
  4. 返回 `((contentWidth + gap) / (minItemWidth + gap)).floor().clamp(1, ceiling)`。
- **用法：**
  ```dart
  final columns = columnCapacity(contentWidth, minItemWidth: 320, maxColumns: 3);
  ```
- **说明：** 分子里的 `+ gap` 是全部诀窍：它让算式支付列**之间**的间隙而不是每列之后各一个，因此两个 320 宽的列需要 652 而不是 664。每个调用方带来自己的 `minItemWidth`，承载那个数字的常量在其文档注释中说明该数字所度量的内容。两个退化保护意味着调用方可以传入尚未完成布局的宽度而无需特殊处理。

### `int listRowCount(int itemCount, int columns)` <a id="listrowcount"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 116 行）
- **用途：** 返回一组扁平条目在给定列数下占多少行。
- **输入：** `itemCount`、`columns`。
- **返回：** `int`——空列表为 0，否则为向上取整的除法结果。
- **副作用：** 无。
- **算法：** `itemCount <= 0` → 0；`perRow = columns < 1 ? 1 : columns`；返回 `(itemCount + perRow - 1) ~/ perRow`。
- **用法：** 由 `adaptiveTileRows` 调用以驱动其行构建器——见 [../widgets/adaptive_tile_grid.md#adaptivetilerows](../widgets/adaptive_tile_grid.md#adaptivetilerows)。
- **说明：** 最后一行可能不满；调用方用空单元格补齐，使剩余的图块保持自己的宽度而不是横跨整行拉伸。

### `int listColumnCount({required double screenWidth, required double screenHeight, required double contentWidth, required double minItemWidth, required int preference, int maxColumns = listMaxColumns})` <a id="listcolumncount"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 136 行）
- **用途：** 把分栏闸门、容量和存储的用户偏好合并成列表应渲染的唯一列数。
- **输入：** `screenWidth`、`screenHeight`——整个屏幕，决定是否允许分栏；`contentWidth`——列表自身获得的宽度；`minItemWidth`——一列可以有的最窄宽度；`preference`——`listColumnsAuto` 或固定的列数；`maxColumns`。
- **返回：** `int`，至少 1。
- **副作用：** 无。
- **算法：**
  1. `!canSplitLayout(screenWidth, screenHeight)` → 返回 1。
  2. `capacity = columnCapacity(contentWidth, minItemWidth: minItemWidth, maxColumns: maxColumns)`。
  3. `preference == listColumnsAuto` → 返回 `capacity`。
  4. 返回 `preference.clamp(1, capacity)`。
- **用法：**
  ```dart
  final columns = listColumnCount(
    screenWidth: screen.width,
    screenHeight: screen.height,
    contentWidth: shellContentWidth(screen.width),
    minItemWidth: 320,
    preference: settings.someListColumns,
    maxColumns: 3,
  );
  ```
- **说明：** 闸门读**屏幕**而容量读**列表自身的宽度**，这是刻意的——为什么量 body 会破坏 Fold 8 的情形见 `canSplitLayout` 的说明。固定的偏好是被**钳制而不是拒绝**：正是这一点让桌面上做出的选择能在被带到折叠状态的手机上后幸存，并在展开时回来，而不是被覆写成 1。设置该偏好的控件在容量为 1 时被完全隐藏，因此它永远不会出现在手机或外屏上。

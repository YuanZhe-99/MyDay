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
| `taskSectionMinWidth` | 顶层 `const double` | B | 一个待办任务分区可占的最小宽度（340）。 |
| `taskSectionMaxColumns` | 顶层 `const int` | B | 待办分区列数的上限（3）。 |
| `transactionTileMinWidth` | 顶层 `const double` | B | 一条交易图块可占的最小宽度（320）。 |
| `transactionMaxColumns` | 顶层 `const int` | B | 交易列数的上限（4）。 |
| `weightRecordMinWidth` | 顶层 `const double` | B | 一条体重记录图块可占的最小宽度（300）。 |
| `weightRecordMaxColumns` | 顶层 `const int` | B | 体重记录列数的上限（3）。 |
| `intimacyRecordMinWidth` | 顶层 `const double` | B | 一条亲密记录图块可占的最小宽度（340）。 |
| `intimacyRecordMaxColumns` | 顶层 `const int` | B | 亲密记录列数的上限（3）。 |
| `settingsRightPaneMinWidth` | 顶层 `const double` | B | 设置详情窗格可获得的最小宽度（280）。 |
| `weightPairedChartMinWidth` | 顶层 `const double` | B | 两图并排时一张体重趋势图可获得的最小宽度（330）。 |
| `weightSummaryFigureWidth` | 顶层 `const double` | B | 体重摘要横幅中数字块的宽度（280）。 |
| `subscriptionStatMinWidth` | 顶层 `const double` | B | 财务摘要窗格上一张订阅统计卡片可占的最小宽度（110）。 |
| `summaryCardGap` | 顶层 `const double` | B | 财务摘要卡片之间的水平间距（8）。 |
| `metricCardMinWidth` | 顶层 `const double` | B | 一张指标卡片可占的最小宽度（160）。 |
| `metricMaxColumns` | 顶层 `const int` | B | 摘要卡片中指标列数的上限（4）。 |
| `accountCardMinWidth` | 顶层 `const double` | B | 一张账户卡片可占的最小宽度（340）。 |
| `accountMaxColumns` | 顶层 `const int` | B | 账户列数的上限（3）。 |
| `categoryTileMinWidth` | 顶层 `const double` | B | 一个分类图块可占的最小宽度（300）。 |
| `exchangeRateTileMinWidth` | 顶层 `const double` | B | 一行汇率可占的最小宽度（280）。 |
| `formFieldMinWidth` | 顶层 `const double` | B | 成对排列时一个表单字段可占的最小宽度（260）。 |
| `formMaxContentWidth` | 顶层 `const double` | B | 表单页允许其内容增长到的最大宽度（720）。 |
| `readingMaxContentWidth` | 顶层 `const double` | B | 散文页允许其文本增长到的最大宽度（840）。 |
| `pieChartMinWidth` | 顶层 `const double` | B | 分析饼图可获得的最小宽度（280）。 |
| `pieLegendMinWidth` | 顶层 `const double` | B | 并排时分类图例可获得的最小宽度（320）。 |
| `calendarCardMinWidth` | 顶层 `const double` | B | 待办月历并排于趋势图时可占的最小宽度（340）。 |
| `scoreTrendMinWidth` | 顶层 `const double` | B | 待办评分趋势图可获得的最小宽度（360）。 |
| `timerHistoryPaneWidth` | 顶层 `const double` | B | 计时器页会话历史窗格的宽度（320）。 |
| `dialogMaxContentWidth` | 顶层 `const double` | B | 对话框内容改为居中之前能增长到的最大宽度（640）。 |
| `dialogMinHorizontalInset` | 顶层 `const double` | B | Flutter 自带的对话框水平内缩默认值（40）。 |
| `pickerCellMinWidth` | 顶层 `const double` | B | 一个 emoji 或图标选择器单元格可占的最小宽度（44）。 |
| `pickerMaxColumns` | 顶层 `const int` | B | 选择器列数的上限（12）。 |
| [`canSplitLayout`](#cansplitlayout) | 顶层函数 | A | 报告布局是否可以分成窗格或列。 |
| [`useNavigationRail`](#usenavigationrail) | 顶层函数 | A | 报告外壳是否应显示导航栏。 |
| [`shellContentWidth`](#shellcontentwidth) | 顶层函数 | A | 返回外壳页面内容实际获得的宽度。 |
| [`columnCapacity`](#columncapacity) | 顶层函数 | A | 返回给定最小宽度的列在内容框里能放下几个。 |
| [`listRowCount`](#listrowcount) | 顶层函数 | A | 返回给定列数下一组条目需要几行。 |
| [`columnMajorFill`](#columnmajorfill) | 顶层函数 | A | 把有序的一组块发到各列，先填满一列再填下一列。 |
| [`listColumnCount`](#listcolumncount) | 顶层函数 | A | 返回列表实际应渲染的列数。 |
| [`financeLeftPaneWidth`](#financeleftpanewidth) | 顶层函数 | A | 返回财务页固定左窗格的宽度。 |
| [`intimacyLeftPaneWidth`](#intimacyleftpanewidth) | 顶层函数 | A | 返回亲密页固定左窗格的宽度。 |
| [`settingsLeftPaneWidth`](#settingsleftpanewidth) | 顶层函数 | A | 返回设置页固定左窗格的宽度。 |
| [`useWeightChartsSideBySide`](#useweightchartssidebyside) | 顶层函数 | A | 报告两张体重趋势图是否放得下并排。 |
| [`cappedContentWidth`](#cappedcontentwidth) | 顶层函数 | A | 返回页面把内容居中所用的宽度（若有）。 |
| [`usePieChartSideBySide`](#usepiechartsidebyside) | 顶层函数 | A | 报告分析图例是否放得下在饼图旁边。 |
| [`useTodoCalendarSideBySide`](#usetodocalendarsidebyside) | 顶层函数 | A | 报告待办评分趋势是否放得下在月历旁边。 |
| [`todoCalendarPaneWidth`](#todocalendarpanewidth) | 顶层函数 | A | 返回待办日历页月历窗格的宽度。 |
| [`dialogHorizontalInset`](#dialoghorizontalinset) | 顶层函数 | A | 返回限定对话框内容宽度的水平内缩值。 |

**对账：** `grep -c 'Purpose:' lib/shared/utils/adaptive_layout.dart` 报告 17，对应 56 行。三十九个顶层 `const` 声明带的是说明其取值来源的散文文档注释而不是 `Purpose:` 块，与索引在别处处理顶层常量的方式一致；它们是文件表面的一部分，因此有对应行。十七个函数全部按 `shared/` 下顶层函数的通用规则为 Tier A。常量为 Tier B：它们的全部内容就是取值及其理由，而这两者下面的表格和 [../../../adaptive-layout.md](../../../adaptive-layout.md) 已经承载。

## 常量

这三十九个数字构成 MyDay 布局策略的全部数值表面。前八个与兄弟应用共享，未先阅读 [../../../adaptive-layout.md](../../../adaptive-layout.md) 不得更改——尤其 `splitMinAspect` 是全应用范围的行为变更。其余是 MyDay 自己的逐内容最小值，每一个都说明它所度量的内容，因为一个没有说明内容的最小值是日后没人能安全更改的数字。

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
| `taskSectionMinWidth` | `340.0` | 一个待办分区在任务图块之上带有自己的标题、计数和排序控件，而任务图块带复选框、标题、子任务行和尾部菜单按钮；低于此值标题会在尾部控件之前被截断。 |
| `taskSectionMaxColumns` | `3` | 一共只有三个分区，第四列永远填不满。 |
| `transactionTileMinWidth` | `320.0` | 分类 emoji 或图标、备注、账户/分类副标题，以及带货币符号的右对齐金额。 |
| `transactionMaxColumns` | `4` | 全应用的列表上限；交易是 MyDay 中最矮的图块，因此它是唯一能用满这个上限的界面。 |
| `weightRecordMinWidth` | `300.0` | 日期、体重、其 BMI 以及一行内最多三个测量值。 |
| `weightRecordMaxColumns` | `3` | 超过三列，体重行的日期和数值就不再读作一对。 |
| `intimacyRecordMinWidth` | `340.0` | 日期、伴侣与玩具芯片、时长和派生的抽插速率——应用中最宽的图块，因为芯片是换行而不是截断。 |
| `intimacyRecordMaxColumns` | `3` | 同上；芯片对宽度的需求超过列表对再加一列的需求。 |
| `settingsRightPaneMinWidth` | `280.0` | 被托管的二级页面仍然可用的最窄宽度——一个表单字段加它的标签。 |
| `weightPairedChartMinWidth` | `330.0` | 每张图为左轴保留约 42，每个日期标签需要约 48，因此这个宽度可以不拥挤地显示约六个带标签的点。 |
| `weightSummaryFigureWidth` | `280.0` | 数字块是两个弹性的半边——`displaySmall` 的最新体重，以及变化量和天数——因此各得约 140，放三位数体重很宽裕。旧的摘要窗格 280 是*含*卡片内边距的，每半只剩 108。 |
| `subscriptionStatMinWidth` | `110.0` | 一个 12 dp 图标和「月應付」这样的短本地化标签，下方是 `titleMedium` 的 $1,234.56 这样的金额。在财务窗格钳制范围内的任何宽度下都能并排两张卡片；窗格超过约 378 时第三张加入同一行（3 x 110 加两个间隙，位于两侧各 16 dp 的内边距之内）。 |
| `summaryCardGap` | `8.0` | 比 `listTileGap` 窄，因为这些卡片本就位于带内边距的窗格之内，并且与上方支出卡和收入卡之间的间距一致。 |
| `metricCardMinWidth` | `160.0` | 一个统计标签在其数值之上；低于此值「平均抽插速率」这样的本地化标签会折成三行。 |
| `metricMaxColumns` | `4` | 一张摘要卡片最多承载四个指标，四个并排仍然一眼可扫。 |
| `accountCardMinWidth` | `340.0` | 账户名称、其银行预设芯片，以及一行内同时以本币和默认货币显示的余额。 |
| `accountMaxColumns` | `3` | 账户行承载两种货币；第四列会开始截断其中之一。 |
| `categoryTileMinWidth` | `300.0` | 一个 emoji、一个图标、名称和尾部 chevron；低于此值最长的本地化分类名会被截断。 |
| `exchangeRateTileMinWidth` | `280.0` | 一个货币对、其六位有效数字的汇率，以及产生它的那次抓取的时间戳。 |
| `formFieldMinWidth` | `260.0` | 一个 `OutlineInputBorder` 字段，其最长的本地化标签是日语；更窄的话标签会在字段自己的后缀之前被截断。 |
| `formMaxContentWidth` | `720.0` | 横跨 1400 dp 桌面窗口的 `ListTile` 把标题和尾部控件放在屏幕两端；这个上限让它们保持在一眼之内。 |
| `readingMaxContentWidth` | `840.0` | 在应用正文字号下约 90 个字符，是舒适阅读行宽的上端。散文比表单获得更多，因为它没有需要靠近彼此的控件。 |
| `pieChartMinWidth` | `280.0` | 一个 200 dp 的饼图，加上其百分比标签和卡片自己的内边距所需的空间。 |
| `pieLegendMinWidth` | `320.0` | 一个色块、一个 emoji、分类名称，以及带 chevron 的右对齐金额。 |
| `calendarCardMinWidth` | `340.0` | 七个日期列加上卡片自己的内边距；低于此值日期数字会糊成一团。 |
| `scoreTrendMinWidth` | `360.0` | 图表为左轴保留约 24，在 31 天的月份中每个日期标签约需 11。 |
| `timerHistoryPaneWidth` | `320.0` | 一个时长、一个开始时间戳及其下方的抽插次数，以及尾部的恢复按钮。固定而不是按比例：超出此值的每一个像素都属于秒表，而秒表正是这个页面存在的理由。 |
| `dialogMaxContentWidth` | `640.0` | 每个表单对话框都是全宽字段的滚动 `Column`；1300 逻辑像素宽的文本框比 600 的更难读，而不是更好读。 |
| `dialogMinHorizontalInset` | `40.0` | Flutter 自带 `Dialog` 的默认值，保留它使手机上的对话框与一贯的布局逐字节相同。 |
| `pickerCellMinWidth` | `44.0` | Material 的最小触摸目标尺寸。选择器单元格是一个只装着一个字形的方形点击目标，因此点击目标*就是*最小值。 |
| `pickerMaxColumns` | `12` | 超过这个数，眼睛就不再把选择器当作网格来扫，而是当作噪声；它也让单元格不会长得远超一根拇指。 |

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

### `List<List<int>> columnMajorFill(int itemCount, int columns)` <a id="columnmajorfill"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 133 行）
- **用途：** 把有序的一组块发到各列，先填满一列再开始下一列。
- **输入：** `itemCount`、`columns`。
- **返回：** `List<List<int>>`——恰好 `columns` 个列表（至少一个），每个按顺序持有该列中各块的索引。只有当 `itemCount` 小于 `columns` 时才会有空列表。
- **副作用：** 无。
- **算法：** `count = max(columns, 1)`；`perColumn = listRowCount(itemCount, count)`；第 `c` 列持有 `[c * perColumn, min((c + 1) * perColumn, itemCount))`。
- **用法：** 待办页 `_buildTaskArea` 中的 `columnMajorFill(sections.length, columns)`——三个分区在两列时给出 `[[0, 1], [2]]`，三列时 `[[0], [1], [2]]`。
- **说明：** 阅读顺序——先从上到下，再从左到右——这正是人对几个具名分区的期望。待办页在 v1.4.3 之前使用的轮流发牌把第二个分区放在第一个旁边、第三个放在下面，于是用户一起阅读的两个一次性清单落在不同的列里。数量不能整除时，靠前的列是更满的那些。

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

### `double financeLeftPaneWidth(double contentWidth)` <a id="financeleftpanewidth"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 218 行）
- **用途：** 返回财务页固定左窗格的宽度，该窗格容纳月度摘要和即将续订条。
- **输入：** `contentWidth`——两个窗格共享的宽度，以逻辑像素计。
- **返回：** 介于 280 与 420 之间的 `double`。
- **副作用：** 无。
- **算法：** `(contentWidth * 0.36).clamp(280.0, 420.0)`。
- **用法：** `SizedBox(width: financeLeftPaneWidth(contentWidth), child: summaryPane)`。
- **说明：** 按比例而不是固定，因为同一代折叠屏展开后大致跨越 672 到 954 逻辑像素。下限让三个摘要数字各占一行而不被截断；上限阻止窗格在桌面窗口上蔓延，把其余空间留给用户真正在读的交易列表。

### `double intimacyLeftPaneWidth(double contentWidth)` <a id="intimacyleftpanewidth"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 228 行）
- **用途：** 返回亲密页固定左窗格的宽度，该窗格容纳月历、其周期条，以及自 v1.4.3 起的趋势图。
- **输入：** `contentWidth`——两个窗格共享的宽度，以逻辑像素计。
- **返回：** 介于 320 与 480 之间的 `double`。
- **副作用：** 无。
- **算法：** `(contentWidth * 0.42).clamp(320.0, 480.0)`。
- **用法：** `SizedBox(width: intimacyLeftPaneWidth(contentWidth), child: calendarPane)`。
- **说明：** 比例和上限都高于财务页的 0.36 / 420，因为这个窗格承载一张图表，而图表不像日历，宽度越大越受益。下限是日历的下限，并刻意保持 v1.4.1 时的值不变：七个日期列加上卡片自己的内边距在约 320 以下放不下，而最窄的可分栏折叠屏——竖持的 Z Fold 5 或 7，内容宽度约 580–670——没有余量可让，因此它们的渲染与之前完全一样。比例从内容宽度 762（约 843 屏幕宽度）起超过下限；横持展开的 Fold 8 约 851，得到约 357 而不是 320。`test/adaptive_layout_test.dart` 钉住了这些点，并断言 1440 的桌面仍给记录列表两列。

### `double settingsLeftPaneWidth(double contentWidth)` <a id="settingsleftpanewidth"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 240 行）
- **用途：** 返回详情窗格并排显示时设置页分区列表的宽度。
- **输入：** `contentWidth`——两个窗格共享的宽度，以逻辑像素计，取自页面自己的 `LayoutBuilder` 而不是屏幕。
- **返回：** `double`。
- **副作用：** 无。
- **算法：**
  1. `preferred = (contentWidth * 0.44).clamp(300.0, 440.0)`。
  2. `capped = contentWidth - settingsRightPaneMinWidth`。
  3. `preferred` 放得进 `capped` 时返回它，否则返回 `capped.clamp(240.0, 440.0)`。
- **用法：** `SizedBox(width: settingsLeftPaneWidth(constraints.maxWidth), child: sectionList)`。
- **说明：** 比另外两个窗格更大的比例，因为这个列表承载的是带两行副标题和尾部 chevron 的完整 `ListTile`，而不是一个摘要块。在分栏规则允许的任何宽度上这个上限都不会真正生效——`test/adaptive_layout_test.dart` 在整个区间上正是这样断言的——因此它是给比任何真实窗口都更窄的窗格准备的保护，而不是第二个断点。保留而不删除，是因为本函数接受的是**窗格**宽度，未来的调用方可能真的交给它一个。

### `bool useWeightChartsSideBySide(double contentWidth)` <a id="useweightchartssidebyside"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/adaptive_layout.dart`（第 295 行）
- **用途：** 报告体重页的两张趋势图是否都放得下在同一行上。
- **输入：** `contentWidth`——体重主体获得的宽度，单位为逻辑像素。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** `contentWidth >= 2 * weightPairedChartMinWidth + listTileGap`（330 + 330 + 12 = 672）。
- **用法：**
  ```dart
  final chartsSideBySide = canSplitLayout(screen.width, screen.height) &&
      useWeightChartsSideBySide(contentWidth) &&
      _records.length >= 2;
  ```
- **说明：** 这是**叠加在** `canSplitLayout` 之上的宽度下限，而不是取代它——双重闸门。单靠分栏规则会放进 Z Fold 5 竖持那样大小的视口，那里每张图会只剩不到 290 逻辑像素、只显示四个日期标签。调用方必须同时检查两者，**并且**必须检查究竟有没有图表：低于两条记录时两张图都不渲染，而一条摘要横幅压在两片空白之上，比它所要取代的堆叠布局更糟。凡是可能渲染为空的块，都属于闸门。

  这个下限**刻意与** `useWeightSummaryBesideChart` 在 v1.4.3 之前使用的 672 相同，那时的分栏是把摘要卡片放进 280 的窗格、旁边是 380 的图表。v1.4.4 改的是可分栏窗口*内部*的排布，而不是哪些窗口可分栏，因此每个视口都保持它原有的结论——这条性质由 `test/adaptive_layout_test.dart` 直接钉住，而不是留给巧合。窗格宽度函数已不复存在：两列是等分 flex，因此各得间隙之外的一半。

### `double cappedContentWidth(double contentWidth, double maxWidth)` <a id="cappedcontentwidth"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 352 行）
- **用途：** 返回页面应把内容居中所用的宽度（若有）。
- **输入：** `contentWidth`——页面实际拥有的宽度；`maxWidth`——内容应当增长到的最大宽度。
- **返回：** `double`——页面更宽时为 `maxWidth`，否则为 `contentWidth`。
- **副作用：** 无。
- **算法：** `contentWidth > maxWidth ? maxWidth : contentWidth`。
- **用法：** 这是 `AdaptiveContentWidth` 以组件形式所做之事的数值那一半——见 [../widgets/adaptive_tile_grid.md#adaptivecontentwidth](../widgets/adaptive_tile_grid.md#adaptivecontentwidth)。
- **说明：** 仅看宽度且没有闸门，因此比上限更窄的页面在任何视口上都不受影响，这也就不可能改变手机渲染的东西。这就是规则 D：表单页或散文页拿桌面窗口做什么，而不是分栏。

### `bool usePieChartSideBySide(double contentWidth)` <a id="usepiechartsidebyside"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 362 行）
- **用途：** 报告分析图例是否放得下在饼图旁边。
- **输入：** `contentWidth`——分析标签页获得的宽度，以逻辑像素计。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** `contentWidth >= pieChartMinWidth + pieLegendMinWidth + listTileGap`（612）。
- **用法：** 在 `_buildPieChart` 中与 `canSplitLayout` 一同检查。
- **说明：** 这是**叠加在**形状规则之上的宽度下限，与体重页使用的双重闸门相同。低于它时图例保持在图表下方，那是 v1.4.2 之前每个视口的布局。

### `bool useTodoCalendarSideBySide(double contentWidth)` <a id="usetodocalendarsidebyside"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 372 行）
- **用途：** 报告待办评分趋势是否放得下在月历旁边。
- **输入：** `contentWidth`——日历页获得的宽度，以逻辑像素计。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** `contentWidth >= calendarCardMinWidth + scoreTrendMinWidth + listTileGap`（712）。
- **用法：** 在 `_TodoCalendarPageState.build` 中与 `canSplitLayout` 一同检查。
- **说明：** 月历和趋势图堆叠在手机上是整整两屏；并排在平板上就是一屏。Z Fold 5 竖持通过形状规则却通不过这一条，而那正是第二重闸门存在的理由。

### `double todoCalendarPaneWidth(double contentWidth)` <a id="todocalendarpanewidth"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 386 行）
- **用途：** 返回待办日历页月历窗格的宽度。
- **输入：** `contentWidth`——两个块共享的宽度，以逻辑像素计。
- **返回：** 介于 `calendarCardMinWidth` 与 480 之间的 `double`。
- **副作用：** 无。
- **算法：** `(contentWidth * 0.4).clamp(calendarCardMinWidth, 480.0)`。
- **用法：** `SizedBox(width: todoCalendarPaneWidth(screen.width), child: calendarCard)`。
- **说明：** 按比例，使桌面窗口给日期单元格更大的点击目标，而不是让日历停在最低限度旁边配一张很宽的图表；上限的存在是因为月历的单元格一旦舒适，再多宽度也无益。不需要右侧上限——在闸门之上，窗格以 0.4 增长而图表以 0.6 增长，因此图表在边界处恰好满足其下限，往上只会更宽裕，这一点在 `test/adaptive_layout_test.dart` 中跨整个区间断言。

### `double dialogHorizontalInset(double screenWidth)` <a id="dialoghorizontalinset"></a>
- **种类：** 顶层函数
- **源：** `lib/shared/utils/adaptive_layout.dart`（第 417 行）
- **用途：** 返回限定对话框内容宽度的水平内缩值。
- **输入：** `screenWidth`——以逻辑像素表示的整个屏幕宽度。
- **返回：** `double`，绝不低于 `dialogMinHorizontalInset`。
- **副作用：** 无。
- **算法：** `(screenWidth - dialogMaxContentWidth) / 2`，下限为 `dialogMinHorizontalInset`。
- **用法：** 经由 `adaptiveDialogInset`——见 [../widgets/adaptive_tile_grid.md#adaptivedialoginset](../widgets/adaptive_tile_grid.md#adaptivedialoginset)。
- **说明：** 仅看宽度且没有闸门。在约 720 以下结果就是 Flutter 自己的默认值，因此手机上的对话框不受影响；在其之上，多出的宽度变成两侧的内缩，于是对话框被居中而不是被拉伸。对话框绘制在根 overlay 上，因此测量的是**屏幕**而不是它背后的页面——导航栏的宽度也在对话框覆盖的范围之内。

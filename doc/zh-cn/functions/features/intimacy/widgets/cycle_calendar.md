# lib/features/intimacy/widgets/cycle_calendar.dart

周期跟踪的渲染层：稳定人色调色板、单日指示器组件、图例和单人月历。它消费 `services/cycle_predictor.dart` 的 `CyclePrediction`/`CycleDayInfo`（阶段/生育窗口/排卵/预测开始如何计算见 [身体指标 — 周期预测](../../../../algorithms/body-metrics.md#cycle-prediction)），并渲染 [亲密](../../../../features/intimacy.md#the-body-layer-v124) 文档化的精确视觉语言：实心月经、半透明生育窗口、淡色卵泡/黄体、居中排卵点，以及实际-vs-预测周期开始的实心-vs-空心前置点。`widgets/body_section.dart` 为单个人嵌入 `CycleCalendar`/`CycleLegend`（身体标签中），`views/intimacy_page.dart` 的主页日历对每个可见人直接调用 `buildCycleDayIndicator` 一次，绘制同一概念文档小节描述的多人员叠加行。`cyclePersonColor`（两个消费者实际调用的调色板查找函数）住在 `widgets/body_section.dart`，不在本文件——本文件只拥有它读取的 `cyclePersonPalette` 常量。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `cyclePersonPalette` | 顶层常量 | B | 8 色稳定调色板；槽 0 总是用户，槽 1+ 是按排序 id 的伴侣。 |
| `PersonCycleOverlay`（构造函数） | 构造函数（`PersonCycleOverlay`） | B | 创建人周期叠加值（键、显示名、颜色、预测）。 |
| [`buildCycleDayIndicator`](#buildcycledayindicator) | 顶层函数 | A | 为一个人构建一天的颜色条加排卵/开始标记点。 |
| `CycleLegend`（构造函数） | 构造函数（`CycleLegend`） | B | 创建周期图例实例。 |
| `CycleLegend.build` | 方法（`CycleLegend`） | B | 渲染可选逐人 chip 行加阶段/排卵/开始标记图例。 |
| `CycleCalendar`（构造函数） | 构造函数（`CycleCalendar`） | B | 创建单人周期日历实例。 |
| `CycleCalendar.createState` | 方法（`CycleCalendar`） | B | 创建可变 `_CycleCalendarState`。 |
| `_CycleCalendarState.build` | 方法（`_CycleCalendarState`） | B | 渲染月页头（上一/下一）、星期行和日网格。 |
| `_CycleCalendarState._buildDayGrid` | 方法（组件辅助） | B | 把月份的天布局进按星期对齐的行，每格显示其指示器。 |

`grep -c 'Purpose:' lib/features/intimacy/widgets/cycle_calendar.dart` 报告 8，比上面 9 行少一个。差异是 `cyclePersonPalette`（第 12 行）：它是只带普通 `///` 文档注释（无 `Purpose:` 块）的普通顶层 `const List<Color>`，因此不出现在 grep 计数中但仍是真实顶层声明并因完整性被包含在表格中，与本文档集处理普通数据常量的方式一致。8 个 `/// Purpose:` 块每个都恰好位于其文档化的真实声明正上方——未发现错附块（记录调用点而非声明的），文件中也不存在其他未文档化的真实声明（方法、getter、setter）。Tier 划分：1 个 Tier A、8 个 Tier B（计 `cyclePersonPalette`）。

**对账：** `grep -c 'Purpose:' lib/features/intimacy/widgets/cycle_calendar.dart` 报告 8，与上面 9 行中的 8 行精确匹配。额外行是 `cyclePersonPalette`，一个无 `Purpose:` 块但被 `cyclePersonColor` 使用的真实声明的顶层常量颜色列表。

## 文档

### `Widget buildCycleDayIndicator(Color color, CycleDayInfo? info, {double height = 4})` <a id="buildcycledayindicator"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/widgets/cycle_calendar.dart`（第 51 行）
- **用途：** 为一个人在某一天构建小逐日周期指示器：实心/半透明/淡色不透明度的阶段色条、可选居中排卵点、可选前置实心或空心开始日点。
- **输入：** `color` — 人的稳定调色板颜色；`info` — 来自 `CyclePrediction.days` 的那天 `CycleDayInfo`，当天无周期分类时为 `null`；`height` — 逻辑像素的条厚度，默认 `4`。
- **返回：** `Widget` — `info` 为 `null` 时空 `SizedBox(height: height)`；否则是包着带条和任何标记点的 `Stack` 的 `SizedBox(height: height + 2)`。
- **副作用：** 无。
- **算法：**
  1. `info == null` 时立即返回空 `SizedBox(height: height)`（这天无周期数据）。
  2. 用对 `info.phase` 的 `switch` 计算 `opacity`：`menstrual` → `1.0`（实心）；`follicular` → `info.inFertileWindow` 时 `0.55` 否则 `0.18`；`luteal` → 在生育窗口内时 `0.55` 否则 `0.32`。
  3. 构建给定 `height`、着 `color.withValues(alpha: opacity)` 色的圆角 `Container` 条。
  4. `info.isOvulationDay` 时在条顶添加 `color` 的居中实心圆（直径 `height + 2`）。
  5. `info.isActualStart || info.isPredictedStart` 时添加前置圆（直径 `height + 2`，`centerLeft` 对齐）：`info.isActualStart` 时用 `color` 填充，否则只带 `color` 边框（`width: 1.2`）不填充——实心标记实际记录开始，空心标记预测的，匹配文档化指示器图例。
  6. 把一切包进 `Stack(clipBehavior: Clip.none)`，使点（比条高 2px）能溢出条自己的高度而不被裁剪。
- **用法：**
  ```dart
  // Single-person month calendar (this file, _buildDayGrid, line 383):
  buildCycleDayIndicator(widget.personColor, info),

  // Multi-person home-calendar overlay row (views/intimacy_page.dart, line 2191):
  child: buildCycleDayIndicator(
    cycleOverlays[o].color,
    cycleOverlays[o].prediction.days[date],
    height: 3,
  ),
  ```
- **备注：** 四个不透明度常量（`1.0`、`0.55`、`0.18`、`0.32`）在 `CycleLegend.build` 的 `bar(...)` 调用内独立重新声明，使图例色块视觉匹配此函数的输出——两者之间没有共享常量，因此只改一个会让图例对日历实际显示撒谎。

## 相关页面

- [身体指标 — 周期预测](../../../../algorithms/body-metrics.md#cycle-prediction) — `CyclePrediction`/`CycleDayInfo`（阶段、生育窗口、排卵、实际/预测开始）如何计算；本文件只渲染那个数据，绝不派生它。
- [亲密](../../../../features/intimacy.md#the-body-layer-v124) — 本文件实现的指示器渲染契约（实心/半透明/淡色、排卵点、实心/空心开始标记），以及也直接调用 `buildCycleDayIndicator` 的主页日历多人员叠加。
- [`body_page.dart`](../views/body_page.md) — 托管 `BodySectionView`，后者反过来从本文件为用户自己的周期跟踪嵌入 `CycleCalendar`/`CycleLegend`。

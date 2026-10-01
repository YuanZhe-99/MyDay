# lib/features/intimacy/widgets/thrust_timeline_chart.dart

`ThrustTimelineChart`（v1.5.5）绘制一次计时会话的累计抽插次数随秒表时间的变化，见 [亲密 — 抽插时间线图表](../../../../features/intimacy.md#thrust-timeline-chart)。它是一个无状态的 `fl_chart` `LineChart`，有两个由 [`ThrustTimeline`](../utils/thrust_timeline.md) 构建的序列：作为淡色**阶梯线**的原始累计计数（[`cumulativeSpots`](../utils/thrust_timeline.md#cumulativespots)），以及一条虚线、曲线的**移动平均**拟合线（[`smoothedSpots`](../utils/thrust_timeline.md#smoothedspots)），外加两项图例。它唯一的调用方是记录详情页（[`record_detail_page.dart`](../views/record_detail_page.md)），后者只在 `IntimacyRecord.hasThrustTimeline` 为 true 时显示它。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `ThrustTimelineChart({timeline, duration, height = 220})` | 构造函数（`ThrustTimelineChart`） | B | 创建抽插时间线图表。 |
| [`niceStep`](#nicestep) | 静态方法（`ThrustTimelineChart`） | A | 选出约产生 `targetTicks` 个刻度的整齐坐标轴步长（1、2 或 5 乘以 10 的幂）。 |
| [`formatMinutes`](#formatminutes) | 静态方法（`ThrustTimelineChart`） | A | 把分钟值格式化为 x 轴标签（一小时以下为 `m`，一小时起为 `h:mm`）。 |
| [`build`](#build) | 方法（`ThrustTimelineChart`） | A | 构建图表及其图例；按下少于两次时什么也不画。 |
| `_LegendItem({color, dashed, label})` | 构造函数（`_LegendItem`） | B | 创建一个图例项。 |
| `_LegendItem.build` | 方法（`_LegendItem`） | B | 构建一个短的实线或两段虚线色样，后跟其标签。 |

`grep -c 'Purpose:' lib/features/intimacy/widgets/thrust_timeline_chart.dart` 报告 6，与上面 6 行精确匹配（3 个 Tier A、3 个 Tier B）。组件字段（`timeline`、`duration`、`height`；`color`、`dashed`、`label`）是普通数据持有者。

## 文档

### `static double niceStep(double range, int targetTicks, {double minStep = 1})` <a id="nicestep"></a>
- **种类：** `ThrustTimelineChart` 的静态方法
- **来源：** `lib/features/intimacy/widgets/thrust_timeline_chart.dart`（第 33 行）
- **用途：** 选出落在整齐数字上的网格和标签间隔。
- **输入：** `range` — 坐标轴跨度；`targetTicks` — 期望刻度数；`minStep` — 下限。
- **返回：** `double` — `1`、`2`、`5` 或 `10` 乘以 10 的幂，至少为 `minStep`。
- **副作用：** 无。
- **算法：** `range` 或 `targetTicks` 非正时返回 `minStep`。否则 `raw = range / targetTicks`，`magnitude = 10^floor(log10(raw))`，`normalized = raw / magnitude`；把 `normalized` 向上取到 1、2、5、10 中第一个不小于它的值，乘回 `magnitude`，再与 `minStep` 取较大者。
- **用法：**
  ```dart
  // build, lines 80 and 83:
  final yStep = niceStep(total, 4);
  final xStep = niceStep(maxX, 5);
  ```
- **备注：** 为测试而公开（`test/record_detail_page_test.dart`：`niceStep(160, 4) == 50`、`niceStep(1000, 4) == 500`、`niceStep(7, 5) == 2`、`niceStep(0, 5) == 1`）。默认 `minStep` 为 1，使 y 网格落在整数次数上、x 网格落在整分钟上。

### `static String formatMinutes(double minutes)` <a id="formatminutes"></a>
- **种类：** `ThrustTimelineChart` 的静态方法
- **来源：** `lib/features/intimacy/widgets/thrust_timeline_chart.dart`（第 55 行）
- **用途：** 紧凑地标注时间轴和提示框。
- **输入：** `minutes`。
- **返回：** `String` — 低于 60 时为四舍五入后的分钟数（`'12'`），否则为 `h:mm`（`'1:15'`）。
- **副作用：** 无。
- **算法：** `total = minutes.round()`；低于 60 原样返回；否则为 `total ~/ 60`、一个冒号，以及补齐两位的 `total % 60`。
- **用法：** `build` 中底部坐标轴的 `getTitlesWidget` 和提示框文本。
- **备注：** 为测试而公开。坐标轴名称（`intimacyThrustTimelineMinutes`）说明单位是分钟，所以一小时以下的标签是裸数字。

### `Widget build(BuildContext context)` <a id="build"></a>
- **种类：** `ThrustTimelineChart` 的方法（`StatelessWidget.build` 的覆盖）
- **来源：** `lib/features/intimacy/widgets/thrust_timeline_chart.dart`（第 70 行）
- **用途：** 绘制阶梯线、拟合线、坐标轴和图例。
- **输入：** `context`；组件的 `timeline`、`duration` 和 `height`。
- **返回：** 由图表（`SizedBox(height: height)`）和居中图例 `Wrap` 组成的 `Column`；时间线少于两个事件时为 `SizedBox.shrink()`。
- **副作用：** 无。
- **算法：**
  1. 以 `durationMs = duration.inMilliseconds` 从时间线构建 `raw` 和 `smooth`；`maxX` 取两个序列最后 x 中较晚者（非正时回退为 1）。
  2. `yStep = niceStep(total, 4)`；`maxY = ceil(total * 1.05 / yStep) * yStep`——约 5% 的余量，向上取到一条网格线，使最后的平台不贴着边框。`xStep = niceStep(maxX, 5)`。
  3. 网格：每 `yStep` 一条水平线（`outlineVariant`，alpha 0.3），每 `xStep` 一条虚线竖线（alpha 0.2）；左轴标签为整数计数，底轴标签为 `formatMinutes`，轴名为 `intimacyThrustTimelineMinutes`；不显示顶部和右侧标题。
  4. 序列 0，原始计数：`isStepLineChart: true`，不弯曲，主色 alpha 0.45，宽 1.5，无圆点。
  5. 序列 1，仅当 `smooth` 非空：弯曲，`curveSmoothness: 0.3` 且 `preventCurveOverShooting: true`，完整主色，宽 2，`dashArray: [6, 4]`，无圆点，下方有一片淡色区域（alpha 0.08）。
  6. 提示框：只有序列 0 产生条目，为 `'<count> · <formatMinutes(x)>'`，底色为 `inverseSurface`。
  7. 图例：标注为 `intimacyThrustCount` 的实线色样，以及标注为 `intimacyThrustTimelineSmoothed` 的虚线色样。
- **用法：**
  ```dart
  // record_detail_page.dart, build, lines 195-198:
  ThrustTimelineChart(
    timeline: record.thrustTimeline!,
    duration: record.duration,
  ),
  ```
- **备注：** 两个序列都不会肉眼可见地下凹：原始序列是正 delta 的阶梯函数，平滑值按构造不下降，而防过冲阻止曲线插值在两者之间的平坦段下方鼓出。提示框刻意只报告原始计数——移动平均是视觉辅助，不是供读取的数字。

## 相关页面

- [`thrust_timeline.dart`](../utils/thrust_timeline.md) — 数据模型和两个序列。
- [`record_detail_page.dart`](../views/record_detail_page.md) — 唯一显示此图表的页面。
- [`intimacy_trend_chart.dart`](intimacy_trend_chart.md) — 模块跨记录的趋势图，使用相同的原始实线 / 平滑虚线约定，平滑方式为 EWMA。
- [亲密 — 抽插时间线图表](../../../../features/intimacy.md#thrust-timeline-chart)。

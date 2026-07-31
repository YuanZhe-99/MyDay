# 身体指标

来源：`lib/features/intimacy/services/body_metrics.dart`（完整阅读——罩杯估算和 PSI）和 `lib/features/intimacy/services/cycle_predictor.dart`（完整阅读——周期预测）。两个文件都是无 Flutter 导入的纯 Dart，因此这里的一切都可直接单元测试（`test/body_metrics_test.dart`、`test/cycle_predictor_test.dart`）。它如何融入身体层 UI 见 [亲密](../features/intimacy.md#the-body-layer-v124)。

## 罩杯估算

`estimateBraSize({required double bustCm, required double underbustCm, required BraStandard standard})` 返回 `BraSizeEstimate? { band, cup, display }`，输入非正、`bustCm - underbustCm <= 0` 或测量落在支持表之外时为 `null`。只有原始测量被持久化——估算本身总是按需重新计算，绝不存储。

### 下胸围带号推导（所有标准共享）

`_roundedBand(underbustCm)` 把下胸围四舍五入到最近的 5 cm，并拒绝 **50–130 cm** 之外的任何值（`(underbustCm / 5).round() * 5`，然后边界检查）。这个 EU 带号是下方每个标准的公共起点。

`_ukBandFromEu(euBand)` 把 EU 带号转换为 UK/US 带号系统：`28 + (euBand - 60) ~/ 5 * 2`，拒绝 **24–56** 之外的结果。因此 EU 60 → UK/US 28，EU 每 5 cm 一步给 UK/US 带号加 2（EU 80 → UK/US 36）。

### 六种标准

| 标准 | 带号 | 罩杯推导 |
| --- | --- | --- |
| **EU**（`BraStandard.eu`） | 四舍五入的 EU 带号 | 差值（胸 − 下胸围）必须在 `[10, 28)` cm；罩杯 = 来自 `['AA','A','B','C','D','E','F','G','H']` 的 `_euCups[((diff - 10) / 2).floor()]`——即从 10 cm = AA 开始每 2 cm 差值一个罩杯档。 |
| **FR/ES**（`BraStandard.frEs`） | EU 带号 **+ 15** | 与 EU 相同的罩杯表和差值范围；只有带号数字偏移。 |
| **JP/JIS**（`BraStandard.jp`） | 四舍五入的 EU 带号 | JIS 罩杯位于从 5.0 cm（AAA）开始的 2.5 cm 中心上，每个 ±1.25 cm，给出半开区间 `[center-1.25, center+1.25)`。有效差值范围是 `[3.75, 28.75)`；`index = ((diff - 3.75) / 2.5).floor()` 进 `['AAA','AA','A','B','C','D','E','F','G','H']`。**显示罩杯优先**，如 `C75`（`'$cup$euBand'`），与其他每个标准带号优先的显示不同。 |
| **UK**（`BraStandard.uk`） | 来自 EU 带号的 UK/US 带号 | 差值转换为整英寸（`(diff / 2.54).round()`），有效范围 **1–11** 英寸；罩杯 = 来自 `['A','B','C','D','DD','E','F','FF','G','GG','H']` 的 `_ukCups[inches - 1]`。 |
| **US**（`BraStandard.us`） | 来自 EU 带号的 UK/US 带号 | 与 UK 相同的英寸转换；罩杯 = 来自 `['A','B','C','D','DD/E','DDD/F','G','H','I','J','K']` 的 `_usCups[inches - 1]`——源码注明实践中存在品牌间差异。 |
| **AU/NZ**（`BraStandard.auNz`） | UK 带号 **− 22**（服装尺码带号，`< 4` 时拒绝） | 与 UK 相同的英寸转换和 `_ukCups` 表，但带号本身是服装尺码数字（UK 30 → AU/NZ 8，即 UK 每 2 的带号步进也映射为 AU/NZ 2 的步进，因为两者都减去恒定偏移）。 |

全部六条路径在其各自有效范围外返回 `null`，而不是钳制到最近尺寸——函数明确表示超出范围的测量应在 UI 中浮出提示，而不是一个误导性的精确尺寸。

## PSI 参考指数

`calculatePsi({double? lengthCm, double? baseCircumferenceCm, double? frontCircumferenceCm})`：

1. `lengthCm` 缺失或 `<= 0` 时返回 `null`。
2. 规范化每个周长：`<= 0` 的值当作缺席（`null`）。
3. **两个**周长都缺席时返回 `null`。
4. 只有一个周长存在时，它被用于**两者**——`base ??= front; front ??= base;`——这正是"把公式化简为 `3hC²`"的具体含义（见第 6 步）。
5. 把三个输入都从 **cm 转换为 dm**（除以 10）：`h = lengthCm / 10`、`c1 = base / 10`、`c2 = front / 10`。
6. 计算 `PSI = h * (c1*c1 + c2*c2 + c1*c2)`。`c1 == c2 == C` 时（第 4 步的单周长情形），这代数上坍缩为 `h * (C² + C² + C²) = 3hC²`——即"单周长化简为 `3hC²`"行为。

该公式是**基于 dm 的截锥体积近似**，纯粹用作个人参考数字（绝不是定性评级），源码注释明确说明引用的统计参考（Wang Cuntong 等人 2020）是人群统计的来源，**不是**公式本身的来源。

## 周期预测

来源：`lib/features/intimacy/services/cycle_predictor.dart`。所有预测都只是从记录的开始日期派生的统计估计，绝不能作为避孕或医疗指导呈现——UI 附加强制免责声明（见 [亲密](../features/intimacy.md)）。

### 常量

- `minValidCycleDays = 15`、`maxValidCycleDays = 90`——此范围外的间隔是数据错误或跟踪缺口，不是真实周期长度。
- `medianCycleWindow = 6`——只有最近 6 个有效周期长度进入中位数。
- `defaultCycleLengthDays = 28`——少于两个有效记录时使用。
- `assumedMenstrualDays = 5`、`ovulationOffsetDays = 14`、`predictionHorizonDays = 366`。

### `estimateCycleLength(sortedStarts)` — 最近 ≤6 个有效周期的中位数

对排序记录开始的每个相邻对，计算天数间隔；`[15, 90]` 之外的间隔被完全丢弃（不只是封顶），当作数据错误/跟踪缺口。没有有效间隔剩下时，函数返回 28 天默认值。否则取**最近**最多 6 个有效间隔（超过 6 个时 `lengths.sublist(lengths.length - medianCycleWindow)`），排序该子集，返回**中位数**（计数为偶数时两个中间值的平均）。用中位数而不是均值意味着单个离群周期（如一个异常长或短的月份）不能像平均那样使预测偏移。

### `predictCycle(...)` — 锚定、阶段和生育窗口

所有前向预测的**锚点**总是最新的单条实际记录开始日期（排序后的 `starts.last`）——不是今天，也不是平均值。预测在每次调用时从头重新生成（添加或删除记录会重新派生一切；旧预测绝不被增量平移）。

- **前向链：** 从锚点开始，反复加 `cycleLength` 天直到超过 366 天视界，产生 `predictedStarts` 列表。
- **段：** 每个记录开始加每个预测开始形成一个段边界。长于 `maxValidCycleDays`（90 天）的段被当作未跟踪缺口——只分类其开始处的假定月经天，不做完整阶段周期，因此长跟踪缺口不会把数月画成误导性的阶段颜色。
- **月经阶段：** 每段的前 `min(segmentLength, assumedMenstrualDays)` 天。
- **排卵估计：** `segmentEnd - ovulationOffsetDays`（*下一*段开始前 14 天），但只在估计落在月经阶段结束或之后时——否则段太短，估计无意义，跳过。
- **生育窗口：** 排卵前 5 天到排卵后 1 天（`untilOvulation <= 5 && untilOvulation >= -1`）。
- **卵泡期 vs 黄体期：** 月经结束与排卵之间的天是卵泡期；排卵之后（段内）的天是黄体期；段没有有效排卵估计时，所有非月经天默认卵泡期。
- 每个分类天携带 `isEstimated = true`，唯独实际记录的开始日本身（`isActualStart`）除外，`isPredictedStart` 标记来自前向链而非真实记录的开始日。

## 相关页面

- [亲密](../features/intimacy.md) — 这些算法供给的身体层 UI。
- [数据格式](../data-formats.md) — 这些函数读取的 `BodyProfile` 和 `CycleRecord` 字段。

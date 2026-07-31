# lib/features/intimacy/services/body_metrics.dart

纯 Dart、无 Flutter 导入：六种地区标准的罩杯估算和 PSI 参考指数。`widgets/body_section.dart` 是唯一调用方，只用本文件做计算——原始测量是持久化的事实来源，估算总是实时重新计算、绝不存储。完整标准表和 PSI 公式推导见 [身体指标](../../../../algorithms/body-metrics.md)，身体层 UI 如何使用这些结果见 [亲密](../../../../features/intimacy.md#the-body-layer-v124)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `BraStandard`（枚举） | 枚举 | B | `eu` / `frEs` / `jp` / `uk` / `us` / `auNz`——无 Purpose 块（见对账）。 |
| [`braStandardFromCode`](#brastandardfromcode) | 顶层函数 | A | 把持久化标准代码字符串映射为其 `BraStandard` 枚举值。 |
| [`braStandardCode`](#brastandardcode) | 顶层函数 | A | 把 `BraStandard` 枚举值映射回其持久化代码字符串。 |
| [`BraSizeEstimate()`](#brasizeestimate-new) | const 构造函数（`BraSizeEstimate`） | A | 创建罩杯尺寸估算值（带号、罩杯、显示字符串）。 |
| [`_roundedBand`](#_roundedband) | 私有顶层函数 | A | 把下胸围测量四舍五入到最近 5 cm EU 带号值。 |
| [`_ukBandFromEu`](#_ukbandfromeu) | 私有顶层函数 | A | 把 EU 带号转换为 UK/US 带号。 |
| [`estimateBraSize`](#estimatebrasize) | 顶层函数 | A | 从胸/下胸围测量为所选地区标准估算罩杯尺寸。 |
| [`calculatePsi`](#calculatepsi) | 顶层函数 | A | 从长度/周长测量计算 PSI 尺寸参考指数。 |

**对账：** `grep -c 'Purpose:' lib/features/intimacy/services/body_metrics.dart` 报告 7，与上面 8 行中的 7 行精确匹配——那 7 个 `/// Purpose:` 块每个都恰好位于其文档化的真实声明正上方（未发现错附块）。额外一行是 `BraStandard` 枚举：它只带普通 `///` 摘要注释（"Supported regional bra sizing standards."），无 `Purpose:` 块，但仍是真实顶层声明并为完整性包含，与本文档集处理普通枚举的方式一致（如 `finance/models/finance.md` 的 `AccountType`）。四个私有罩杯标签查找表（`_euCups`、`_ukCups`、`_usCups`、`_jpCups`）是普通内部数据，不计为声明，与 `weight_storage.dart` 的私有 `fileName`/`_writeQueue` 字段被排除的方式相同。全部 7 个文档化声明为 Tier A：`braStandardFromCode`/`braStandardCode` 是本文件公共标准/代码映射的两个方向，`BraSizeEstimate` 的构造函数是真实（虽简单）模型风格值构造函数，`_roundedBand`/`_ukBandFromEu`/`estimateBraSize`/`calculatePsi` 都携带本文件唯一工作的核心真实分支逻辑。

## 文档

### `BraStandard braStandardFromCode(String? code)` <a id="brastandardfromcode"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/services/body_metrics.dart`（第 14 行）
- **用途：** 把持久化标准代码（存储在 `BodyProfile.braStandard`）映射为其 `BraStandard` 枚举值。
- **输入：** `code` — 原始可空字符串（`'fr_es'`、`'jp'`、`'uk'`、`'us'`、`'au_nz'` 或任何其他含 `null`）。
- **返回：** `BraStandard`。
- **副作用：** 无。
- **算法：**
  1. switch 表达式把 `code` 匹配五个非 EU 代码。
  2. 任何其他值——含 `null`、空字符串或损坏/不可识别代码——落入 `_` case 到 `BraStandard.eu`。
- **用法：**
  ```dart
  final standard = braStandardFromCode(_profile.braStandard);
  ```
  （`lib/features/intimacy/widgets/body_section.dart:550`，调用 `estimateBraSize` 前。）
- **备注：** 这是保证即使存储代码缺失或来自未来/未知版本也总是有效标准的唯一回退点。

### `String braStandardCode(BraStandard standard)` <a id="brastandardcode"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/services/body_metrics.dart`（第 28 行）
- **用途：** 把 `BraStandard` 枚举值映射回持久化在 `BodyProfile.braStandard` 的代码字符串。
- **输入：** `standard`。
- **返回：** `String`（`'eu'`、`'fr_es'`、`'jp'`、`'uk'`、`'us'` 或 `'au_nz'`）。
- **副作用：** 无。
- **算法：** 穷尽 switch 表达式，每个枚举值一个 case，无 `default`——是 [`braStandardFromCode`](#brastandardfromcode) 的精确逆。
- **用法：**
  ```dart
  onSelected: (s) => onProfileChanged(
    _profile.copyWith(braStandard: braStandardCode(s)),
  ),
  ```
  （`lib/features/intimacy/widgets/body_section.dart:623`，标准选择器 chip 行。）
- **备注：** 无 `default` 的穷尽意味着添加新 `BraStandard` 值而不扩展此 switch 是编译期错误，不是静默运行时回退。

### `const BraSizeEstimate({required int band, required String cup, required String display})` <a id="brasizeestimate-new"></a>
- **种类：** `BraSizeEstimate` 的 const 构造函数
- **来源：** `lib/features/intimacy/services/body_metrics.dart`（第 53 行）
- **用途：** 保存一个计算的罩杯尺寸估算的带号、罩杯标签和可立即显示字符串。
- **输入：** `band`、`cup`、`display`，都必填。
- **返回：** 新的 `BraSizeEstimate`。
- **副作用：** 无。
- **算法：** 平凡 `const` 字段赋值构造函数。
- **用法：** 只在 [`estimateBraSize`](#estimatebrasize) 内构造（如 `return BraSizeEstimate(band: band, cup: cup, display: '$band$cup');`，第 125 行）。
- **备注：** 绝不持久化——估算是从原始胸/下胸围测量每次读取重新计算的派生显示值。

### `int? _roundedBand(double underbustCm)` <a id="_roundedband"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/body_metrics.dart`（第 82 行）
- **用途：** 把下胸围测量四舍五入到最近 5 cm EU 带号值，这是下方每个地区标准构建的公共起点。
- **输入：** `underbustCm`。
- **返回：** `int?` — 四舍五入带号落在 50-130 cm 外时为 `null`。
- **副作用：** 无。
- **算法：**
  1. `band = (underbustCm / 5).round() * 5`。
  2. `band < 50 || band > 130` 时拒绝（`return null`）。
- **用法：** 在 [`estimateBraSize`](#estimatebrasize) 顶部调用一次（第 115 行）：`final euBand = _roundedBand(underbustCm);`。
- **备注：** 作为私有，只能经 `estimateBraSize` 到达；每个标准的带号粒度固定在 5 cm 步进。

### `int? _ukBandFromEu(int euBand)` <a id="_ukbandfromeu"></a>
- **种类：** 私有顶层函数
- **来源：** `lib/features/intimacy/services/body_metrics.dart`（第 94 行）
- **用途：** 把 EU 带号转换为 UK/US 带号系统。
- **输入：** `euBand`。
- **返回：** `int?` — 转换带号落在 24-56 外时为 `null`。
- **副作用：** 无。
- **算法：** `band = 28 + (euBand - 60) ~/ 5 * 2`，然后边界检查。EU 60 映射到 UK/US 28；EU 每 5 cm 一步给 UK/US 带号加 2（EU 80 -> UK/US 36）。
- **用法：** 从 `estimateBraSize` 的 `uk`/`us` case（第 137 行）和 `auNz` case（第 145 行）调用。
- **备注：** EU 带号在这里只以 5 cm 步进到达（来自 `_roundedBand`），因此整数除法 `~/` 绝不截断分数带号。

### `BraSizeEstimate? estimateBraSize({required double bustCm, required double underbustCm, required BraStandard standard})` <a id="estimatebrasize"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/services/body_metrics.dart`（第 107 行）
- **用途：** 从全胸围和下胸围测量为六种地区尺寸标准之一估算罩杯尺寸。
- **输入：** `bustCm` — 全胸围；`underbustCm`；`standard` — 应用六种地区表之一。
- **返回：** `BraSizeEstimate?` — 输入非正、`bustCm - underbustCm <= 0` 或测量落在该标准支持的转换范围外时为 `null`。
- **副作用：** 无。
- **算法：** 完整逐标准带号/罩杯推导表见 [身体指标 — 六种标准](../../../../algorithms/body-metrics.md#the-six-standards)。简言之：拒绝非正或不重叠输入，经 `_roundedBand` 派生 EU 带号，然后按 `standard` 切换选带号转换（EU/FR-ES 共享按标准偏移的 EU 带号；JP 用 2.5 cm 罩杯中心且显示罩杯优先；UK/US/AU-NZ 经 `_ukBandFromEu` 转换为 UK 带号并从整英寸差派生罩杯）——每个分支在自己的有效范围被超出的瞬间返回 `null`，而不是钳制到最近尺寸。
- **用法：**
  ```dart
  final estimate = (bust != null && underbust != null)
      ? estimateBraSize(
          bustCm: bust,
          underbustCm: underbust,
          standard: standard,
        )
      : null;
  ```
  （`lib/features/intimacy/widgets/body_section.dart:553-559`，`_buildBraCard`。）
- **备注：** 全部六个分支在越界时都刻意返回 `null` 而不是近似尺寸，使 UI 能显示显式越界提示，而不是误导性的精确结果。

### `double? calculatePsi({double? lengthCm, double? baseCircumferenceCm, double? frontCircumferenceCm})` <a id="calculatepsi"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/intimacy/services/body_metrics.dart`（第 167 行）
- **用途：** 从勃起长度和一个或两个周长测量计算 PSI 尺寸参考指数。
- **输入：** `lengthCm` — 勃起长度（h）；`baseCircumferenceCm`/`frontCircumferenceCm` — 两个可选周长（C 和 c）。
- **返回：** `double?` — `lengthCm` 缺失/`<= 0`，或两个周长都缺席/非正时为 `null`。
- **副作用：** 无。
- **算法：** 完整推导见 [身体指标 — PSI 参考指数](../../../../algorithms/body-metrics.md#the-psi-reference-index)。简言之：把每个 `<= 0` 周长规范化为缺席，要求至少一个；只有一个存在时它被两者复用（`base ??= front; front ??= base;`）；把三个 cm 输入都转换为 dm；返回 `h * (c1*c1 + c2*c2 + c1*c2)`，单周长情形坍缩为 `3hC^2`。
- **用法：**
  ```dart
  final psi = calculatePsi(
    lengthCm: _profile.erectLengthCm,
    baseCircumferenceCm: _profile.baseCircumferenceCm,
    frontCircumferenceCm: _profile.frontCircumferenceCm,
  );
  ```
  （`lib/features/intimacy/widgets/body_section.dart:902-906`，`_buildPsiCard`。）
- **备注：** 基于 dm 的截锥体积近似，纯粹作为个人参考数字显示、绝不是定性评级——源码注释明确说明其引用的统计参考是人群统计的来源，不是公式本身。

## 相关页面

- [身体指标](../../../../algorithms/body-metrics.md) — 每个标准带号/罩杯规则和 PSI 公式的完整推导。
- [亲密](../../../../features/intimacy.md#the-body-layer-v124) — 本文件唯一调用方的身体层 UI（`widgets/body_section.dart`）。
- [数据格式](../../../../data-formats.md) — 这些函数读取的 `BodyProfile` 字段。

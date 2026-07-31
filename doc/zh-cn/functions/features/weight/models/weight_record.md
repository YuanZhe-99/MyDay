# lib/features/weight/models/weight_record.dart

体重功能的数据模型：`WeightRecord`（一条记录的体重/身体成分条目）和 `WeightData`（整个 `weight_data.json` 文档——身高、记录和提醒设置），加 [体重](../../../../features/weight.md) 描述的 BMI/腰臀比公式和"继承最近正值测量"显示逻辑。由 [`WeightStorage`](../services/weight_storage.md) 持久化和加载，由 [`json_preservation.dart`](../../../shared/utils/json_preservation.md) 的硬编码 `_weightRecordSchema`/`_weightDataSchema` 跨保存/同步逐字段保留，由 `mergeWeightData` 跨设备合并（见 [三方合并](../../../../algorithms/three-way-merge.md)）。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`WeightRecord`（构造函数）](#weightrecord-new) | 构造函数（`WeightRecord`） | A | 创建体重记录，默认 `id`/`datetime`/`modifiedAt`。 |
| [`WeightRecord.toJson`](#weightrecord-tojson) | 方法（`WeightRecord`） | A | 把此记录序列化为 JSON 兼容映射。 |
| [`WeightRecord.fromJson`](#weightrecord-fromjson) | 工厂构造函数（`WeightRecord`） | A | 从其持久化/同步 JSON 形态解析记录。 |
| [`WeightRecord.copyWith`](#copywith) | 方法（`WeightRecord`） | A | 复制此记录并替换或清除所选字段。 |
| [`WeightData`（构造函数）](#weightdata-new) | 构造函数（`WeightData`） | A | 创建体重数据文档，默认 `reminderGraceMinutes`/`settingsModifiedAt`。 |
| [`WeightData.toJson`](#weightdata-tojson) | 方法（`WeightData`） | A | 把整个体重文档序列化为 JSON 兼容映射。 |
| [`WeightData.fromJson`](#weightdata-fromjson) | 工厂构造函数（`WeightData`） | A | 从其持久化/同步 JSON 形态解析整个体重文档。 |
| [`WeightData.calculateBMI`](#calculatebmi) | 静态方法（`WeightData`） | A | 从身高和体重计算 BMI。 |
| [`WeightData.calculateWaistHipRatio`](#calculatewaisthipratio) | 静态方法（`WeightData`） | A | 从两个周长计算腰臀比。 |
| [`WeightData.effectiveMeasurementsUpTo`](#effectivemeasurementsupto) | 静态方法（`WeightData`） | A | 返回截至给定时间的最近已知胸/腰/臀。 |
| [`WeightData.effectiveMeasurementTimeline`](#effectivemeasurementtimeline) | 静态方法（`WeightData`） | A | 构建逐记录最近已知胸/腰/臀时间线。 |
| [`WeightData._positiveMeasurement`](#_positivemeasurement) | 私有静态方法（`WeightData`） | A | 除非严格为正，把测量规范化为 `null`。 |
| [`WeightData._compareRecordsChronologically`](#_comparerecordschronologically) | 私有静态方法（`WeightData`） | A | 按 datetime、然后 `modifiedAt`、然后 `id` 排序记录。 |

`grep -c 'Purpose:' lib/features/weight/models/weight_record.dart` 报告 13，与本文件全部十三个真实声明精确匹配。未发现错附文档注释（每个块都恰好位于其文档化的真实构造函数/方法正上方），也不存在未文档化真实声明——两个记录 typedef（`EffectiveWeightMeasurements`、`EffectiveWeightMeasurementPoint`）是无 `Purpose:` 块的普通类型别名，因为声明形态而非行为，符合预期。每个声明都是 Tier A：两个公共构造函数和两对 `toJson`/`fromJson`/`copyWith` 属于显式构造函数/`fromJson`/`toJson`/`copyWith` Tier A 规则，每个剩余静态方法（`calculateBMI`、`calculateWaistHipRatio`、`effectiveMeasurementsUpTo`、`effectiveMeasurementTimeline` 和两个私有辅助）包含真实分支、排序或循环——本文件没有普通 getter/setter 或组件构建代码。

## 文档

### `WeightRecord({String? id, required this.weight, this.bodyFat, this.bustCm, this.waistCm, this.hipCm, DateTime? datetime, this.notes, DateTime? modifiedAt})` <a id="weightrecord-new"></a>
- **种类：** `WeightRecord` 的构造函数
- **来源：** `lib/features/weight/models/weight_record.dart`（第 31 行）
- **用途：** 创建体重记录，省略时生成新鲜 `id`/`datetime`/`modifiedAt`。
- **输入：** `weight`（kg，必填）；可选 `bodyFat`（%）、`bustCm`/`waistCm`/`hipCm`（cm）、`notes`；可选 `id`、`datetime`、`modifiedAt` 覆盖。
- **返回：** 新 `WeightRecord`。
- **副作用：** 无（`Uuid().v4()`/`DateTime.now()` 相对对象本身是纯的，虽然每次调用产生新鲜值）。
- **算法：** `id ??= Uuid().v4()`；`datetime ??= DateTime.now()`（本地时间）；`modifiedAt ??= DateTime.now().toUtc()`——注意 `datetime` 默认本地时间而 `modifiedAt` 总是默认 UTC。
- **用法：**
  ```dart
  WeightRecord(
    weight: weight,
    bustCm: bustCm,
    waistCm: waistCm,
    hipCm: hipCm,
    datetime: _date,
    notes: notes,
  );
  ```
  （`lib/features/weight/views/weight_page.dart`，第 2206-2213 行，增/改对话框保存处理器的"无可复制既有记录"分支）。
- **备注：** 周长字段以厘米存储；三者各自独立可选。

### `Map<String, dynamic> toJson()` <a id="weightrecord-tojson"></a>
- **种类：** `WeightRecord` 的方法
- **来源：** `lib/features/weight/models/weight_record.dart`（第 50 行）
- **用途：** 把此记录序列化为 `weight_data.json` 中持久化并经同步发送的 JSON 形态。
- **输入：** 无。
- **返回：** 带 `id`、`weight`、`datetime`（ISO 8601）、`modifiedAt`（ISO 8601）的 `Map<String, dynamic>`，`bodyFat`/`bustCm`/`waistCm`/`hipCm`/`notes` 只在非 null 时出现。
- **副作用：** 无。
- **算法：** 每个可选字段带 `if (x != null) 'key': x` 条件条目的映射字面量，使 null 字段完全从映射省略而非写为 JSON `null`。
- **用法：** `data.toJson()` 作为 `next` 传给 [`WeightStorage._saveNow`](../services/weight_storage.md#_savenow) 的 `JsonPreservation.encodeForFile`。
- **备注：** 因为缺席时可选字段被省略（而非置 null），`json_preservation.dart` 的 `_weightRecordSchema` 从不需要区分"显式 null"与"不存在"——两者都产生缺失键。

### `factory WeightRecord.fromJson(Map<String, dynamic> json)` <a id="weightrecord-fromjson"></a>
- **种类：** `WeightRecord` 的工厂构造函数
- **来源：** `lib/features/weight/models/weight_record.dart`（第 67 行）
- **用途：** 从其持久化或同步 JSON 形态重建 `WeightRecord`。
- **输入：** `json` — 预期至少包含 `id`、`weight`、`datetime`。
- **返回：** 新 `WeightRecord`。
- **副作用：** 无。
- **算法：** 经 `(num?).toDouble()` 转换 `weight`/`bodyFat`/`bustCm`/`waistCm`/`hipCm`（接受 JSON int 或 double），经 `DateTime.parse` 解析 `datetime`；`modifiedAt` 缺席时默认 `DateTime.now()`（本地时间，**非** UTC——不同于构造函数自己的默认）而非抛错。
- **用法：**
  ```dart
  records: (json['records'] as List? ?? [])
      .map((e) => WeightRecord.fromJson(e as Map<String, dynamic>))
      .toList(),
  ```
  （`WeightData.fromJson`，第 167-169 行）。
- **备注：** 存储 `datetime`/`weight` 格式错误或缺失的记录抛错（经非 null 转换 / `DateTime.parse`），匹配 `WeightStorage.load()` 让损坏文件浮出为错误而非静默变成空数据集的意图。

### `WeightRecord copyWith({double? weight, double? bodyFat, bool clearBodyFat = false, double? bustCm, bool clearBustCm = false, double? waistCm, bool clearWaistCm = false, double? hipCm, bool clearHipCm = false, DateTime? datetime, String? notes, bool clearNotes = false})` <a id="copywith"></a>
- **种类：** `WeightRecord` 的方法
- **来源：** `lib/features/weight/models/weight_record.dart`（第 86 行）
- **用途：** 产生此记录的修改副本，保持相同 `id`、替换给定字段，并经显式 `clearXxx` 标志而非传 `null` 清除可空字段。
- **输入：** `weight`/`bodyFat`/`bustCm`/`waistCm`/`hipCm`/`datetime`/`notes` 的替换值；`clearBodyFat`/`clearBustCm`/`clearWaistCm`/`clearHipCm`/`clearNotes` 布尔。
- **返回：** 与 `this` 相同 `id` 的新 `WeightRecord`。
- **副作用：** 无（`modifiedAt` 在新实例上盖章 `DateTime.now().toUtc()`）。
- **算法：** 对每个可空字段，`clearX ? null : (x ?? this.x)`——清除标志优先于与它一起传入的任何替换值。`weight`/`datetime`（非可空字段）省略时简单回退 `this.weight`/`this.datetime`。`modifiedAt` 总是重新生成（绝不从 `this` 继承），因此每次 `copyWith` 调用都 bump 记录修改时间。
- **用法：**
  ```dart
  widget.initialRecord?.copyWith(
    weight: weight,
    bustCm: bustCm,
    clearBustCm: bustCm == null,
    waistCm: waistCm,
    clearWaistCm: waistCm == null,
    hipCm: hipCm,
    clearHipCm: hipCm == null,
    datetime: _date,
    notes: notes,
    clearNotes: notes == null,
  ) ?? WeightRecord(/* ... */);
  ```
  （`lib/features/weight/views/weight_page.dart`，第 2194-2213 行——编辑对话框总是带 `x` 一起传 `clearX: x == null`，使 UI 中清除字段可靠置 null 而非被 `x ?? this.x` 回退忽略）。
- **备注：** 非 null 替换值与设为 `true` 的清除标志一起传入仍清除字段——`clearBodyFat ? null : (...)` 先检查标志。

### `WeightData({this.height, required this.records, this.reminderMode = 'none', this.morningHour, this.morningMinute, this.eveningHour, this.eveningMinute, this.reminderGraceMinutes = 180, DateTime? settingsModifiedAt})` <a id="weightdata-new"></a>
- **种类：** `WeightData` 的构造函数
- **来源：** `lib/features/weight/models/weight_record.dart`（第 130 行）
- **用途：** 创建整个体重文档：身高、记录列表和提醒设置，未提供时 `reminderGraceMinutes` 默认 **180**、`settingsModifiedAt` 默认 Unix 纪元。
- **输入：** `records`（必填）；可选 `height`、`reminderMode`（`'none'`/`'once'`/`'twice'`）、`morningHour`/`morningMinute`、`eveningHour`/`eveningMinute`、`reminderGraceMinutes`、`settingsModifiedAt`。
- **返回：** 新 `WeightData`。
- **副作用：** 无。
- **算法：** `settingsModifiedAt ??= DateTime.fromMillisecondsSinceEpoch(0)`——每个其他字段直接赋值或字面量默认。
- **用法：**
  ```dart
  await WeightStorage.save(
    WeightData(
      height: _height,
      records: _records,
      reminderMode: _reminderMode,
      morningHour: _weightMorningReminder?.hour,
      morningMinute: _weightMorningReminder?.minute,
      eveningHour: _weightEveningReminder?.hour,
      eveningMinute: _weightEveningReminder?.minute,
      /* ... */
    ),
  );
  ```
  （`lib/features/weight/views/weight_page.dart`，第 161-169 行）。
- **备注：** 把 `settingsModifiedAt` 默认纪元（而非"现在"）意味着新创建 `WeightData` 与任何曾保存过设置的同伴进行最后写入者胜出设置合并时总是输——这是刻意的，使未保存设置设备在同步期间绝不覆盖真实先前设置值。

### `Map<String, dynamic> toJson()` <a id="weightdata-tojson"></a>
- **种类：** `WeightData` 的方法
- **来源：** `lib/features/weight/models/weight_record.dart`（第 148 行）
- **用途：** 把整个体重文档序列化进 `weight_data.json` 形态。
- **输入：** 无。
- **返回：** 带 `records`（总是存在，作为列表）、`reminderMode`、`reminderGraceMinutes`、`settingsModifiedAt`（总是存在）的 `Map<String, dynamic>`，`height`/`morningHour`/`morningMinute`/`eveningHour`/`eveningMinute` 只在非 null 时出现。
- **副作用：** 无。
- **算法：** 映射字面量；记录列表 `records.map((r) => r.toJson()).toList()`，加可空设置字段的条件条目。
- **用法：** `data.toJson()` 作为 `next` 传给 [`WeightStorage._saveNow`](../services/weight_storage.md#_savenow) 的 `JsonPreservation.encodeForFile`。
- **备注：** 无。

### `factory WeightData.fromJson(Map<String, dynamic> json)` <a id="weightdata-fromjson"></a>
- **种类：** `WeightData` 的工厂构造函数
- **来源：** `lib/features/weight/models/weight_record.dart`（第 165 行）
- **用途：** 从其持久化/同步 JSON 形态重建整个体重文档。
- **输入：** `json`。
- **返回：** 新 `WeightData`。
- **副作用：** 无。
- **算法：** `records` 缺席/null 时默认 `[]`（而非抛错），然后每个条目经 `WeightRecord.fromJson` 解析；`reminderMode` 默认 `'none'`；`reminderGraceMinutes` 默认 **180**；`settingsModifiedAt` 缺席时默认 Unix 纪元——与构造函数相同的默认，这里为 JSON 解析路径显式应用。
- **用法：** `WeightStorage.load()` 中的 `WeightData.fromJson(json)`（见 [`WeightStorage.load`](../services/weight_storage.md#load)）。
- **备注：** 缺失/null `records` 键解析为空列表而非抛错，因此从未记录过记录的合法体重文件仍成功加载。

### `static double? calculateBMI(double? heightCm, double weightKg)` <a id="calculatebmi"></a>
- **种类：** `WeightData` 的静态方法
- **来源：** `lib/features/weight/models/weight_record.dart`（第 187 行）
- **用途：** 从身高和体重计算 BMI。
- **输入：** `heightCm`（可空）、`weightKg`。
- **返回：** `double?` — `heightCm` 为 `null` 或 `<= 0` 时 `null`；否则 `weightKg / (heightM * heightM)`，`heightM = heightCm / 100`。
- **副作用：** 无。
- **算法：** `heightCm` 守卫子句，然后米制标准 BMI 公式。
- **用法：** `WeightData.calculateBMI(_height, latest.weight)`（`weight_page.dart`，第 205 行，第 1446 和 2154 行再次用于历史行和对话框预览 BMI 显示）。
- **备注：** 不验证 `weightKg`（零或负体重不在这里守卫；UI 自己的条目验证是保持 `weight` 为正的东西）。

### `static double? calculateWaistHipRatio(double? waistCm, double? hipCm)` <a id="calculatewaisthipratio"></a>
- **种类：** `WeightData` 的静态方法
- **来源：** `lib/features/weight/models/weight_record.dart`（第 198 行）
- **用途：** 从周长测量计算腰臀比。
- **输入：** `waistCm`、`hipCm`（都可空）。
- **返回：** `double?` — 除非**两者**都非 null 且 `> 0` 否则 `null`；否则 `waistCm / hipCm`。
- **副作用：** 无。
- **算法：** 两个顺序守卫子句（腰，然后臀），然后普通除法。
- **用法：**
  ```dart
  final waistHipRatio = WeightData.calculateWaistHipRatio(
    effectiveMeasurements.waistCm,
    effectiveMeasurements.hipCm,
  );
  ```
  （`weight_page.dart`，第 389-391 行——从 `effectiveMeasurementsUpTo` 的继承值而非原始记录字段供给）。
- **备注：** 无。

### `static EffectiveWeightMeasurements effectiveMeasurementsUpTo(List<WeightRecord> records, DateTime at)` <a id="effectivemeasurementsupto"></a>
- **种类：** `WeightData` 的静态方法
- **来源：** `lib/features/weight/models/weight_record.dart`（第 209 行）
- **用途：** 返回截至给定时刻应*显示*的胸/腰/臀值，从较早记录独立继承每个字段最近正值，不修改任何存储记录。概念级解释见 [体重](../../../../features/weight.md#bustwaisthip-inheritance-from-the-latest-positive-value)。
- **输入：** `records`、`at`（截止时刻——通常是最新记录的 `datetime`）。
- **返回：** `EffectiveWeightMeasurements` — `({double? bustCm, double? waistCm, double? hipCm})` 记录类型。
- **副作用：** 无。
- **算法：**
  1. 过滤到 `datetime <= at` 的记录，经 `_compareRecordsChronologically` 排序。
  2. 向前遍历排序列表；对胸/腰/臀各自独立，保留通过 `_positiveMeasurement`（即非 null 且 `> 0`）的最近值，当前记录值缺席/非正时回退已累积的任何东西（`_positiveMeasurement(record.bustCm) ?? bustCm`）。
  3. 把三个累积值作为单个记录返回。
- **用法：**
  ```dart
  final effectiveMeasurements = WeightData.effectiveMeasurementsUpTo(
    _records,
    latest.datetime,
  );
  ```
  （`weight_page.dart`，第 384-386 行，供给摘要卡片；亲密功能的身体层调用同一函数镜像用户测量——见 [体重](../../../../features/weight.md#related-pages)）。
- **备注：** 只更新 `weight`（胸/腰/臀留空）的记录仍显示较早记录的最近已知胸/腰/臀——继承仅显示且绝不写回存储记录。

### `static List<EffectiveWeightMeasurementPoint> effectiveMeasurementTimeline(List<WeightRecord> records)` <a id="effectivemeasurementtimeline"></a>
- **种类：** `WeightData` 的静态方法
- **来源：** `lib/features/weight/models/weight_record.dart`（第 232 行）
- **用途：** 构建与 `effectiveMeasurementsUpTo` 相同的最近正值继承，但作为供图表渲染的完整逐记录时间线而非单个截止快照。
- **输入：** `records`。
- **返回：** `List<EffectiveWeightMeasurementPoint>` — 每条记录一个点，按时间顺序，各携带 `datetime` 加累积 `bustCm`/`waistCm`/`hipCm`。
- **副作用：** 无。
- **算法：** 与 `effectiveMeasurementsUpTo` 相同的向前遍历，对*所有*记录（无 `at` 截止/过滤），随累积每个字段最近正值给每条记录追加一个 `EffectiveWeightMeasurementPoint`。
- **用法：**
  ```dart
  final timeline = WeightData.effectiveMeasurementTimeline(_records);
  final visibleTimeline = timeline
      .where((point) => !point.datetime.isBefore(cutoff))
  ```
  （`weight_page.dart`，第 967-969 行，供给胸-腰-臀趋势图）。
- **备注：** 与 `effectiveMeasurementsUpTo` 不同，这总是处理完整记录列表；范围过滤（如 `cutoff`）由调用方之后在返回时间线上应用，不是此函数。

### `static double? _positiveMeasurement(double? value)` <a id="_positivemeasurement"></a>
- **种类：** `WeightData` 的私有静态方法
- **来源：** `lib/features/weight/models/weight_record.dart`（第 260 行）
- **用途：** 为继承遍历规范化存储测量值：把 null、零和负当作"未测量"。
- **输入：** `value`。
- **返回：** `double?` — `value` 为 `null` 或 `<= 0` 时 `null`；否则 `value` 不变。
- **副作用：** 无。
- **算法：** 单个守卫子句。
- **用法：** `bustCm = _positiveMeasurement(record.bustCm) ?? bustCm;`（在 `effectiveMeasurementsUpTo` 和 `effectiveMeasurementTimeline` 内部，第 220/242 行等）。
- **备注：** 无。

### `static int _compareRecordsChronologically(WeightRecord a, WeightRecord b)` <a id="_comparerecordschronologically"></a>
- **种类：** `WeightData` 的私有静态方法
- **来源：** `lib/features/weight/models/weight_record.dart`（第 270 行）
- **用途：** 为共享相同 `datetime` 的记录提供确定性全序。
- **输入：** `a`、`b`。
- **返回：** `int` — 标准 `Comparable` 风格排序结果。
- **副作用：** 无。
- **算法：** 先比较 `datetime`；相等时比较 `modifiedAt`；仍相等时比较 `id`（`String.compareTo`）——三级打破平局保证即使同一瞬间记录的两条记录也有稳定顺序。
- **用法：** `effectiveMeasurementsUpTo`（第 215 行）和 `effectiveMeasurementTimeline`（第 236 行）中的 `..sort(_compareRecordsChronologically)`。
- **备注：** 无。

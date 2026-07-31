# lib/features/intimacy/models/intimacy_record.dart

整个亲密功能的数据模型：`BodyProfile`、`CycleRecord`、`Partner`、`Toy`、`Position`、`IntimacyRecord`、`TimerHistoryEntry`、`IntimacyTimerSession` 和顶层 `IntimacyData` 容器。每个模型都遵循本代码库其余功能模型相同的形态：字段赋值构造函数，未提供时生成 `id`（经 `uuid`）和 `modifiedAt`（UTC"现在"），加一对用于持久化/同步 `intimacy_data.json` 格式的 `toJson`/`fromJson`——`BodyProfile` 和 `Partner` 额外有 `copyWith`。`services/intimacy_storage.dart` 加载/保存整个 `IntimacyData` 树；`services/body_metrics.dart` 和 `services/cycle_predictor.dart` 是读取 `BodyProfile`/`CycleRecord` 字段但绝不存储自己结果的纯计算器。这些模型如何融入功能见 [亲密](../../../../features/intimacy.md)，精确 JSON 字段列表见 [数据格式](../../../../data-formats.md#intimacy--intimacy_datajson)，`CycleRecord` 的仅增/删同步语义见 [三方合并](../../../../algorithms/three-way-merge.md#deletionunion-semantics)。

## 声明

锚点说明：`toJson` 在本文件九个不同类上定义（`BodyProfile`、`CycleRecord`、`Partner`、`Toy`、`Position`、`IntimacyRecord`、`TimerHistoryEntry`、`IntimacyTimerSession`、`IntimacyData`），`copyWith` 在两个上定义（`BodyProfile`、`Partner`）。为保持本页锚点唯一，那些行使用类限定锚点（`bodyprofile-tojson`、`partner-copywith` 等），而不是通用规则本会产生的裸名锚点；其他每行使用普通裸名锚点。`fromJson` 工厂构造函数和默认构造函数已按 `<类名>-<命名构造函数小写>`/`<类名>-new` 锚点规则各自唯一。

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`BodyProfile()`](#bodyprofile-new) | 构造函数（`BodyProfile`） | A | 从可选测量和周期显示偏好创建身体档案实例。 |
| [`isEmpty`](#isempty) | getter（`BodyProfile`） | A | 报告此档案是否完全无数据。 |
| [`toJson`](#bodyprofile-tojson) | 方法（`BodyProfile`） | A | 把身体档案序列化为 JSON，缺席字段完全省略。 |
| [`BodyProfile.fromJson`](#bodyprofile-fromjson) | 工厂构造函数（`BodyProfile`） | A | 从 JSON 解析身体档案。 |
| [`copyWith`](#bodyprofile-copywith) | 方法（`BodyProfile`） | A | 复制身体档案，所选字段替换或清除。 |
| [`CycleRecord()`](#cyclerecord-new) | 构造函数（`CycleRecord`） | A | 为一条记录的月经周期开始日期创建周期记录。 |
| [`day`](#day) | getter（`CycleRecord`） | A | 把记录的日历日作为纯日期本地 `DateTime` 返回。 |
| [`formatDate`](#formatdate) | 静态方法（`CycleRecord`） | A | 把日历日期格式化为存储的 `yyyy-MM-dd` 字符串。 |
| [`toJson`](#cyclerecord-tojson) | 方法（`CycleRecord`） | A | 把周期记录序列化为 JSON。 |
| [`CycleRecord.fromJson`](#cyclerecord-fromjson) | 工厂构造函数（`CycleRecord`） | A | 从 JSON 解析周期记录。 |
| [`Partner()`](#partner-new) | 构造函数（`Partner`） | A | 创建伴侣实例，省略时生成 `id`/`modifiedAt`。 |
| [`toJson`](#partner-tojson) | 方法（`Partner`） | A | 把伴侣（及其可选 `BodyProfile`）序列化为 JSON。 |
| [`Partner.fromJson`](#partner-fromjson) | 工厂构造函数（`Partner`） | A | 从 JSON 解析伴侣。 |
| [`copyWith`](#partner-copywith) | 方法（`Partner`） | A | 复制伴侣，所选字段替换或清除，总是盖章新鲜 `modifiedAt`。 |
| [`Toy()`](#toy-new) | 构造函数（`Toy`） | A | 创建玩具实例，省略时生成 `id`/`modifiedAt`。 |
| [`hasCostData`](#hascostdata) | getter（`Toy`） | A | 报告此玩具是否有可汇总的成本数据（非 null 价格）。 |
| [`serviceDays`](#servicedays) | 方法（`Toy`） | A | 计算玩具的服务天数（购买到退役/现在）供成本平均。 |
| [`totalCost`](#totalcost) | 方法（`Toy`） | A | 返回玩具的已记录总成本。 |
| [`averageDailyCost`](#averagedailycost) | 方法（`Toy`） | A | 计算玩具的平均每日成本。 |
| [`toJson`](#toy-tojson) | 方法（`Toy`） | A | 把玩具序列化为 JSON。 |
| [`Toy.fromJson`](#toy-fromjson) | 工厂构造函数（`Toy`） | A | 从 JSON 解析玩具。 |
| [`Position()`](#position-new) | 构造函数（`Position`） | A | 创建姿势实例，省略时生成 `id`/`modifiedAt`。 |
| [`toJson`](#position-tojson) | 方法（`Position`） | A | 把姿势序列化为 JSON。 |
| [`Position.fromJson`](#position-fromjson) | 工厂构造函数（`Position`） | A | 从 JSON 解析姿势。 |
| [`IntimacyRecord()`](#intimacyrecord-new) | 构造函数（`IntimacyRecord`） | A | 创建亲密记录，规范化抽插次数单位并省略时生成 `id`/`datetime`/`modifiedAt`。 |
| [`resolvedThrustCount`](#resolvedthrustcount) | getter（`IntimacyRecord`） | A | 记录的实际次数抽插计数，解析 x1/x100 单位。 |
| [`thrustsPerMinute`](#thrustsperminute) | getter（`IntimacyRecord`） | A | 记录的平均抽插速率，从时长和抽插次数派生。 |
| [`toJson`](#intimacyrecord-tojson) | 方法（`IntimacyRecord`） | A | 把亲密记录序列化为 JSON。 |
| [`IntimacyRecord.fromJson`](#intimacyrecord-fromjson) | 工厂构造函数（`IntimacyRecord`） | A | 从 JSON 解析亲密记录，容忍旧字段。 |
| [`TimerHistoryEntry()`](#timerhistoryentry-new) | 构造函数（`TimerHistoryEntry`） | A | 创建计时器历史条目，钳制抽插次数并规范化其单位。 |
| [`toJson`](#timerhistoryentry-tojson) | 方法（`TimerHistoryEntry`） | A | 把计时器历史条目序列化为 JSON。 |
| [`TimerHistoryEntry.fromJson`](#timerhistoryentry-fromjson) | 工厂构造函数（`TimerHistoryEntry`） | A | 从 JSON 解析计时器历史条目，迁移旧 `end` 时间戳格式。 |
| [`IntimacyTimerSession()`](#intimacytimersession-new) | 构造函数（`IntimacyTimerSession`） | A | 创建亲密计时器会话快照，钳制抽插次数并规范化其单位。 |
| [`elapsedAt`](#elapsedat) | 方法（`IntimacyTimerSession`） | A | 计算给定挂钟时刻的计时器已流逝时长。 |
| [`toJson`](#intimacytimersession-tojson) | 方法（`IntimacyTimerSession`） | A | 把计时器会话序列化为 JSON。 |
| [`IntimacyTimerSession.fromJson`](#intimacytimersession-fromjson) | 工厂构造函数（`IntimacyTimerSession`） | A | 从 JSON 解析计时器会话。 |
| [`IntimacyChartSettings()`](#intimacychartsettings-new) | 构造函数（`IntimacyChartSettings`） | A | 创建趋势图视图偏好，默认指标选择和范围。 |
| [`toJson`](#intimacychartsettings-tojson) | 方法（`IntimacyChartSettings`） | A | 把图表视图偏好序列化为 JSON。 |
| [`IntimacyChartSettings.fromJson`](#intimacychartsettings-fromjson) | 工厂构造函数（`IntimacyChartSettings`） | A | 从 JSON 解析图表视图偏好，容忍 null 和空值。 |
| [`copyWith`](#intimacychartsettings-copywith) | 方法（`IntimacyChartSettings`） | A | 返回所选字段替换后的图表视图偏好副本。 |
| [`IntimacyData()`](#intimacydata-new) | 构造函数（`IntimacyData`） | A | 创建顶层亲密数据容器，默认三个独立 LWW 时间戳。 |
| [`toJson`](#intimacydata-tojson) | 方法（`IntimacyData`） | A | 把整个亲密数据树序列化为 JSON。 |
| [`IntimacyData.fromJson`](#intimacydata-fromjson) | 工厂构造函数（`IntimacyData`） | A | 从 JSON 解析整个亲密数据树。 |

**对账：** `grep -c 'Purpose:' lib/features/intimacy/models/intimacy_record.dart` 报告 43，与上面 43 行精确匹配——每个 `/// Purpose:` 块都恰好位于其文档化的真实声明正上方（未发现错附块），文件中也不存在任何未文档化的真实声明。v1.3.2 添加了六个：两个派生抽插 getter 和四个 `IntimacyChartSettings` 成员。全部 43 个分类为 Tier A：每个都是模型构造函数/`toJson`/`fromJson`/`copyWith`（定级规则显式的 Tier A 桶）或携带别处使用的真实逻辑的 getter/方法（`isEmpty`、`day`、`formatDate`、四个 `Toy` 成本辅助、`elapsedAt`、`resolvedThrustCount`、`thrustsPerMinute`），与应用于 `finance/models/finance.md` 的 `firstBillingDate` getter 相同的标准。每个类的普通数据字段（如 `BodyProfile.bustCm`、`Partner.name`、`IntimacyRecord.pleasureLevel`）不计为单独声明，与本文档集其他每个模型页对待构造函数支撑字段的方式一致。

## 文档

### `const BodyProfile({double? bustCm, double? waistCm, double? hipCm, double? underbustCm, String? braStandard, bool cycleEnabled = false, bool showCycleOnCalendar = false, double? erectLengthCm, double? baseCircumferenceCm, double? frontCircumferenceCm})` <a id="bodyprofile-new"></a>
- **种类：** `BodyProfile` 的 const 构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 24 行）
- **用途：** 创建性别中立、全部可选的身体档案：胸/腰/臀/下胸围测量、罩杯标准代码、两个周期显示标志（都默认关）和三个 PSI 参考测量。
- **输入：** 除两个默认 `false` 的 `bool` 标志外每个字段可选。
- **返回：** 新的 `BodyProfile`。
- **副作用：** 无。
- **算法：** 平凡 `const` 字段赋值构造函数；不像这里大多数其他模型那样生成 `id`/`modifiedAt`，因为 `BodyProfile` 是内联嵌入、不独立跟踪——其所有者（`Partner.modifiedAt` 或 `IntimacyData.userBodyModifiedAt`）携带 LWW 时间戳。
- **用法：**
  ```dart
  BodyProfile get _profile => widget.profile ?? const BodyProfile();
  ```
  （`lib/features/intimacy/widgets/body_section.dart:101`，尚未设置档案时使用的默认空档案。）
- **备注：** 用户自己的胸/腰/臀刻意在这里保持 `null`——它们住在体重模块（`WeightData.effectiveMeasurementsUpTo`），按 [亲密](../../../../features/intimacy.md#the-body-layer-v124)。

### `bool get isEmpty` <a id="isempty"></a>
- **种类：** `BodyProfile` 的 getter
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 42 行）
- **用途：** 报告此档案是否完全无数据（每个字段在默认/null）。
- **输入：** 无。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 单个 `&&` 链检查全部 10 个字段都是 `null`/`false`。
- **用法：**
  ```dart
  if (body != null && !body!.isEmpty) 'body': body!.toJson(),
  ```
  （本文件，`Partner.toJson`，第 247 行——空档案完全从 JSON 省略，而不是序列化为 `{}`。）`lib/features/intimacy/views/intimacy_page.dart:5577` 也使用：`body: profile.isEmpty ? null : profile, clearBody: profile.isEmpty`。
- **备注：** 空档案存储为缺席/`null`（不是 `{}`），使未触碰的档案绝不扰动同步合并。

### `Map<String, dynamic> toJson()` <a id="bodyprofile-tojson"></a>
- **种类：** `BodyProfile` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 59 行）
- **用途：** 把身体档案序列化为嵌套在伴侣 `body` 键或 `IntimacyData` 的 `userBody` 键下的 JSON。
- **输入：** 无。
- **返回：** 每个字段带 `if (field != null)`（两个布尔为 `if (flag)`）守卫的映射——空档案序列化为 `{}`。
- **副作用：** 无。
- **算法：** 映射字面量，每字段一个 `if` 守卫条目。
- **用法：** 从 `Partner.toJson`（第 247 行：`'body': body!.toJson()`）和 `IntimacyData.toJson`（第 866 行：`'userBody': userBody!.toJson()`）调用，两者都只在 `!isEmpty` 时。
- **备注：** 调用方负责 `isEmpty` 检查——直接调用时 `toJson()` 自己仍会为空档案产生 `{}`。

### `factory BodyProfile.fromJson(Map<String, dynamic> json)` <a id="bodyprofile-fromjson"></a>
- **种类：** `BodyProfile` 的工厂构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 79 行）
- **用途：** 从持久化/同步 JSON 形态解析回身体档案。
- **输入：** `json` — 解码映射。
- **返回：** 新的 `BodyProfile`。
- **副作用：** 无。
- **算法：** 每个数字字段经 `(json[k] as num?)?.toDouble()` 转换；两个布尔读为 `json[k] == true`（因此缺失/非 `true` 值默认 `false`）；`braStandard` 直接作为 `String?` 转换。
- **用法：** 从 `Partner.fromJson`（第 268 行：`BodyProfile.fromJson(json['body'] as Map<String, dynamic>)`）和 `IntimacyData.fromJson`（第 922 行，`userBody`）调用，两者都由 `json['body'] is Map<String, dynamic>` 守卫。
- **备注：** 除上面已覆盖的外无——每个字段独立退化，因此部分格式错误的档案绝不会使整个解析失败。

### `BodyProfile copyWith({double? bustCm, bool clearBustCm = false, double? waistCm, bool clearWaistCm = false, double? hipCm, bool clearHipCm = false, double? underbustCm, bool clearUnderbustCm = false, String? braStandard, bool clearBraStandard = false, bool? cycleEnabled, bool? showCycleOnCalendar, double? erectLengthCm, bool clearErectLengthCm = false, double? baseCircumferenceCm, bool clearBaseCircumferenceCm = false, double? frontCircumferenceCm, bool clearFrontCircumferenceCm = false})` <a id="bodyprofile-copywith"></a>
- **种类：** `BodyProfile` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 97 行）
- **用途：** 返回所选字段替换的档案副本，每个可空字段带独立 `clearX` 标志，使字段能被显式清除（而非保持不变）。
- **输入：** 每个可空字段一个可选替换值加一个可选 `clearX` 布尔；`cycleEnabled`/`showCycleOnCalendar` 是普通可空覆盖（它们是非可空带默认 `bool`，无需 clear 标志）。
- **返回：** 新的 `BodyProfile`。
- **副作用：** 无。
- **算法：** 每个可空字段：`clearX ? null : (x ?? this.x)`——clear 标志优先于替换值。两个布尔用普通 `?? this.field`。
- **用法：**
  ```dart
  _updateProfile(_profile.copyWith(cycleEnabled: v)),
  ```
  （`lib/features/intimacy/widgets/body_section.dart:769`，周期跟踪开关。）
- **备注：** 与 `Partner.copyWith` 不同，此方法自己不盖章任何时间戳——`BodyProfile` 没有 `modifiedAt`；拥有它的 `Partner` 或 `IntimacyData.userBodyModifiedAt` 负责。

### `CycleRecord({String? id, String? personId, required String date, DateTime? modifiedAt})` <a id="cyclerecord-new"></a>
- **种类：** `CycleRecord` 的构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 152 行）
- **用途：** 为一条记录的月经周期开始日期创建周期记录，属于用户（`personId: null`）或特定伴侣。
- **输入：** `date` 必填，`yyyy-MM-dd` 本地日历日期字符串；`personId` 可选（`null` = 用户）；`id`/`modifiedAt` 省略时生成。
- **返回：** 新的 `CycleRecord`。
- **副作用：** 无。
- **算法：** `id = id ?? const Uuid().v4()`、`modifiedAt = modifiedAt ?? DateTime.now().toUtc()`。
- **用法：**
  ```dart
  widget.onCycleRecordsChanged([
    ...widget.cycleRecords,
    CycleRecord(
      personId: widget.personId,
      date: CycleRecord.formatDate(date),
    ),
  ]);
  ```
  （`lib/features/intimacy/widgets/body_section.dart:379-385`，`_addCycleStart`。）
- **备注：** 记录只有增/删；没有编辑流程——更改周期开始意味着删除旧记录并添加新记录。尽管这是简单按 id 合并，删除仍如何正确同步见 [三方合并](../../../../algorithms/three-way-merge.md#deletionunion-semantics)。

### `DateTime get day` <a id="day"></a>
- **种类：** `CycleRecord` 的 getter
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 165 行）
- **用途：** 把记录的日历日作为纯日期本地 `DateTime` 返回。
- **输入：** 无。
- **返回：** `DateTime`，总是本地午夜。
- **副作用：** 无。
- **算法：** `DateTime.parse(date)` 然后重建为 `DateTime(parsed.year, parsed.month, parsed.day)` 剥离任何时间分量。
- **用法：**
  ```dart
  actualStarts: _cycleRecords
      .where((c) => c.personId == personId)
      .map((c) => c.day),
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:314-316`，供给 [`predictCycle`](../services/cycle_predictor.md#predictcycle)。）
- **备注：** 时间分量总是本地时间午夜，匹配 `cycle_predictor.dart` 处理的每个其他纯日期值（见 [`dateOnly`](../services/cycle_predictor.md#dateonly)）。

### `static String formatDate(DateTime day)` <a id="formatdate"></a>
- **种类：** `CycleRecord` 的静态方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 175 行）
- **用途：** 把日历日期格式化为存储的 `yyyy-MM-dd` 字符串。
- **输入：** `day`。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** 把 `month`/`day` 零填充到 2 位并连接为 `'${day.year}-$month-$dayOfMonth'`。
- **用法：**
  ```dart
  date: CycleRecord.formatDate(date),
  ```
  （`lib/features/intimacy/widgets/body_section.dart:383`，添加周期开始时；第 399 行检查那天是否已有记录时也使用。）
- **备注：** 忽略输入上的任何时间分量，是 [`day`](#day) 的逆。

### `Map<String, dynamic> toJson()` <a id="cyclerecord-tojson"></a>
- **种类：** `CycleRecord` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 186 行）
- **用途：** 把周期记录序列化为存储在 `intimacy_data.json` 的 `cycleRecords` 数组中的 JSON。
- **输入：** 无。
- **返回：** `{id, personId?, date, modifiedAt}`。
- **副作用：** 无。
- **算法：** 映射字面量；`personId` 为 `null` 时省略（用户自己的记录）。
- **用法：** 从 `IntimacyData.toJson`（第 870 行）调用：`cycleRecords.map((c) => c.toJson()).toList()`，只在 `cycleRecords.isNotEmpty` 时。
- **备注：** 无。

### `factory CycleRecord.fromJson(Map<String, dynamic> json)` <a id="cyclerecord-fromjson"></a>
- **种类：** `CycleRecord` 的工厂构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 198 行）
- **用途：** 从持久化/同步 JSON 形态解析回周期记录。
- **输入：** `json` — 解码映射。
- **返回：** 新的 `CycleRecord`。
- **副作用：** 无。
- **算法：** 把 `id`/`date` 作为必填 `String` 转换；`personId` 可空；`modifiedAt` 缺失时回退 Unix 纪元。
- **用法：** 从 `IntimacyData.fromJson`（第 929 行）调用：`(json['cycleRecords'] as List<dynamic>?)?.map((c) => CycleRecord.fromJson(c as Map<String, dynamic>))`。
- **备注：** 无。

### `Partner({String? id, required String name, String? emoji, String? imagePath, DateTime? startDate, DateTime? endDate, BodyProfile? body, DateTime? modifiedAt})` <a id="partner-new"></a>
- **种类：** `Partner` 的构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 223 行）
- **用途：** 创建伴侣记录：名称、可选 emoji/图像、关系开始/结束日期和可选嵌入 `BodyProfile`。
- **输入：** `name` 必填；其他每个字段可选；`id`/`modifiedAt` 省略时生成。
- **返回：** 新的 `Partner`。
- **副作用：** 无。
- **算法：** 字段赋值构造函数；`id = id ?? const Uuid().v4()`、`modifiedAt = modifiedAt ?? DateTime.now().toUtc()`。
- **用法：**
  ```dart
  _partners.add(
    Partner(
      id: p.id,
      name: p.name,
      emoji: p.emoji,
      imagePath: p.imagePath,
      startDate: p.startDate,
      endDate: now,
      body: p.body?.copyWith(showCycleOnCalendar: false),
    ),
  );
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:2807-2815`，`_breakUpPartner`——带设置 `endDate` 且关闭周期日历可见性重建伴侣。）
- **备注：** `BodyProfile` 在同步中与伴侣记录原子同行——身体编辑走 [`Partner.copyWith`](#partner-copywith)，它 bump 伴侣自己的 `modifiedAt`，按 [亲密](../../../../features/intimacy.md#models)。

### `Map<String, dynamic> toJson()` <a id="partner-tojson"></a>
- **种类：** `Partner` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 240 行）
- **用途：** 把伴侣（及其可选非空 `BodyProfile`）序列化为存储在 `intimacy_data.json` 的 `partners` 数组中的 JSON。
- **输入：** 无。
- **返回：** `id`/`name`/`modifiedAt` 总是存在；`emoji`/`imagePath`/`startDate`/`endDate`/`body` 只在设置时包含（`body` 只在非 null **且** `!body!.isEmpty` 时）。
- **副作用：** 无。
- **算法：** 每个可选字段带 `if` 守卫的映射字面量；存在时嵌套 `body!.toJson()`。
- **用法：** 从 `IntimacyData.toJson`（第 859 行）调用：`partners.map((p) => p.toJson()).toList()`。
- **备注：** 空（全 null）身体档案绝不嵌套进输出，匹配 [`BodyProfile.isEmpty`](#isempty) 的"存储为缺席"规则。

### `factory Partner.fromJson(Map<String, dynamic> json)` <a id="partner-fromjson"></a>
- **种类：** `Partner` 的工厂构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 256 行）
- **用途：** 从持久化/同步 JSON 形态解析回伴侣。
- **输入：** `json` — 解码映射。
- **返回：** 新的 `Partner`。
- **副作用：** 无。
- **算法：** 把 `id`/`name` 作为必填转换；`emoji`/`imagePath` 可空字符串；`startDate`/`endDate` 存在时经 `DateTime.parse` 解析；`body` 在 `json['body'] is Map<String, dynamic>` 时经 [`BodyProfile.fromJson`](#bodyprofile-fromjson) 解析；`modifiedAt` 缺失时回退 Unix 纪元。
- **用法：** 从 `IntimacyData.fromJson`（第 890 行）调用：`(json['partners'] as List<dynamic>?)?.map((p) => Partner.fromJson(p as Map<String, dynamic>))`。
- **备注：** 无。

### `Partner copyWith({String? name, String? emoji, bool clearEmoji = false, String? imagePath, bool clearImagePath = false, DateTime? startDate, bool clearStartDate = false, DateTime? endDate, bool clearEndDate = false, BodyProfile? body, bool clearBody = false})` <a id="partner-copywith"></a>
- **种类：** `Partner` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 280 行）
- **用途：** 返回所选字段替换或清除的伴侣副本，总是盖章新鲜 `modifiedAt`，使编辑在之后的 LWW 合并中胜出。
- **输入：** 每个可空字段一个可选替换值加 `clearX` 标志（`id` 永不可改——总是从 `this.id` 带过）。
- **返回：** 新的 `Partner`。
- **副作用：** 无。
- **算法：** 每个可空字段：`clearX ? null : (x ?? this.x)`；`modifiedAt` 无条件设为 `DateTime.now().toUtc()`（不同于盖章任何东西的 `BodyProfile.copyWith`）。
- **用法：**
  ```dart
  final updated = partner.copyWith(
    body: profile.isEmpty ? null : profile,
    clearBody: profile.isEmpty,
  );
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:5576-5579`，伴侣模式身体标签的 `onProfileChanged` 回调。）
- **备注：** 总是 bump `modifiedAt`——即使仅身体编辑——正是让身体档案在同步中与伴侣记录原子同行的东西，按 [亲密](../../../../features/intimacy.md#models)。

### `Toy({String? id, required String name, String? emoji, String? imagePath, DateTime? purchaseDate, DateTime? retiredDate, String? purchaseLink, double? price, DateTime? modifiedAt})` <a id="toy-new"></a>
- **种类：** `Toy` 的构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 320 行）
- **用途：** 创建玩具记录：名称、可选 emoji/图像、购买/退役日期、购买链接和价格。
- **输入：** `name` 必填；其他每个字段可选；`id`/`modifiedAt` 省略时生成。
- **返回：** 新的 `Toy`。
- **副作用：** 无。
- **算法：** 字段赋值构造函数；`id`/`modifiedAt` 与 `Partner` 相同方式默认。
- **用法：**
  ```dart
  _toys.add(
    Toy(
      id: t.id,
      name: t.name,
      emoji: t.emoji,
      imagePath: t.imagePath,
      purchaseDate: t.purchaseDate,
      retiredDate: now,
      purchaseLink: t.purchaseLink,
      price: t.price,
    ),
  );
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:3842-3851`，`_retireToy`。）
- **备注：** 无。

### `bool get hasCostData` <a id="hascostdata"></a>
- **种类：** `Toy` 的 getter
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 338 行）
- **用途：** 报告此玩具是否有可汇总的成本数据（已记录价格）。
- **输入：** 无。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** `price != null`。
- **用法：**
  ```dart
  value: toy.hasCostData ? _formatMoney(toy.totalCost()) : '-',
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:5274`，玩具成本摘要卡片。）
- **备注：** 零价格仍被当作显式成本数据（只有 `null` 算"无成本数据"）。

### `int? serviceDays({DateTime? asOf})` <a id="servicedays"></a>
- **种类：** `Toy` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 345 行）
- **用途：** 计算玩具的服务天数（购买日到退役或 `asOf`），用于平均其成本。
- **输入：** `asOf` — 可选参考日期，默认 `DateTime.now()`。
- **返回：** `int?` — `purchaseDate` 未设置时为 `null`；否则至少 `1`。
- **副作用：** 无。
- **算法：**
  1. `purchaseDate == null` 时返回 `null`。
  2. `end = asOf ?? DateTime.now()`；`retiredDate` 已设置且早于 `end` 时改用 `retiredDate`（退役玩具的服务期停在退役，不在 `asOf`）。
  3. `days = end.difference(purchaseDate!).inDays + 1`，钳制到最小 `1`。
- **用法：** 由 [`averageDailyCost`](#averagedailycost)（第 370 行）内部调用：`final days = serviceDays(asOf: asOf);`。
- **备注：** `+ 1` 和最小 `1` 钳制意味着同天购买和退役的玩具仍算一天完整服务，绝不除零。

### `double totalCost({DateTime? asOf})` <a id="totalcost"></a>
- **种类：** `Toy` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 361 行）
- **用途：** 返回玩具的已记录总成本。
- **输入：** `asOf` — 为与 `averageDailyCost`/`serviceDays` 的 API 对称而接受，但未使用。
- **返回：** `double` — `price ?? 0`。
- **副作用：** 无。
- **算法：** `price ?? 0`。
- **用法：**
  ```dart
  toys.fold(0.0, (sum, toy) => sum + toy.totalCost());
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:3650`，聚合玩具成本总览。）
- **备注：** 当前模型只有一次性购买成本，因此 `asOf` 目前被忽略；它存在是为了未来重复成本模型能在不改调用点的情况下添加真实逻辑。

### `double? averageDailyCost({DateTime? asOf})` <a id="averagedailycost"></a>
- **种类：** `Toy` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 368 行）
- **用途：** 计算玩具的平均每日成本。
- **输入：** `asOf` — 可选参考日期，转发给 `serviceDays`/`totalCost`。
- **返回：** `double?` — 直到 `price` 和 `purchaseDate` 都可用前为 `null`。
- **副作用：** 无。
- **算法：** `!hasCostData` 时返回 `null`；`serviceDays(asOf: asOf)` 为 `null` 时返回 `null`；否则 `totalCost(asOf: asOf) / days`。
- **用法：**
  ```dart
  final dailyCost = toy.averageDailyCost();
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:3661`，激活/全部每日成本趋势图；详情页/摘要显示的第 4225、5279-5281、6134、6376 行逐玩具也使用。）
- **备注：** 无。

### `Map<String, dynamic> toJson()` <a id="toy-tojson"></a>
- **种类：** `Toy` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 380 行）
- **用途：** 把玩具序列化为存储在 `intimacy_data.json` 的 `toys` 数组中的 JSON。
- **输入：** 无。
- **返回：** `id`/`name`/`modifiedAt` 总是存在；其他每个字段只在非 null 时。
- **副作用：** 无。
- **算法：** 带 `if (field != null)` 守卫的映射字面量；日期为 `toIso8601String()`。
- **用法：** 从 `IntimacyData.toJson`（第 860 行）调用：`toys.map((t) => t.toJson()).toList()`。
- **备注：** 无。

### `factory Toy.fromJson(Map<String, dynamic> json)` <a id="toy-fromjson"></a>
- **种类：** `Toy` 的工厂构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 397 行）
- **用途：** 从持久化/同步 JSON 形态解析回玩具。
- **输入：** `json` — 解码映射。
- **返回：** 新的 `Toy`。
- **副作用：** 无。
- **算法：** 把 `id`/`name` 作为必填转换；每个可选字段 null 安全；`price` 经 `(json['price'] as num?)?.toDouble()`；`modifiedAt` 缺失时回退 Unix 纪元。
- **用法：** 从 `IntimacyData.fromJson`（第 895 行）调用：`(json['toys'] as List<dynamic>?)?.map((t) => Toy.fromJson(t as Map<String, dynamic>))`。
- **备注：** 无。

### `Position({String? id, required String name, String? emoji, DateTime? modifiedAt})` <a id="position-new"></a>
- **种类：** `Position` 的构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 427 行）
- **用途：** 创建姿势记录：名称和可选 emoji。
- **输入：** `name` 必填；`emoji` 可选；`id`/`modifiedAt` 省略时生成。
- **返回：** 新的 `Position`。
- **副作用：** 无。
- **算法：** 字段赋值构造函数；`id`/`modifiedAt` 与 `Partner` 相同方式默认。
- **用法：**
  ```dart
  _positions.add(
    Position(name: nameCtrl.text.trim(), emoji: selectedEmoji),
  );
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:4893-4895`，添加新姿势；第 4886-4890 行编辑既有姿势时改为传既有 `id`。）
- **备注：** 无。

### `Map<String, dynamic> toJson()` <a id="position-tojson"></a>
- **种类：** `Position` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 436 行）
- **用途：** 把姿势序列化为存储在 `intimacy_data.json` 的 `positions` 数组中的 JSON。
- **输入：** 无。
- **返回：** `{id, name, emoji?, modifiedAt}`。
- **副作用：** 无。
- **算法：** 映射字面量；`emoji` 为 `null` 时省略。
- **用法：** 从 `IntimacyData.toJson`（第 861 行）调用：`positions.map((p) => p.toJson()).toList()`。
- **备注：** 无。

### `factory Position.fromJson(Map<String, dynamic> json)` <a id="position-fromjson"></a>
- **种类：** `Position` 的工厂构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 448 行）
- **用途：** 从持久化/同步 JSON 形态解析回姿势。
- **输入：** `json` — 解码映射。
- **返回：** 新的 `Position`。
- **副作用：** 无。
- **算法：** 把 `id`/`name` 作为必填转换；`emoji` 可空；`modifiedAt` 缺失时回退 Unix 纪元。
- **用法：** 从 `IntimacyData.fromJson`（第 900 行）调用：`(json['positions'] as List<dynamic>?)?.map((p) => Position.fromJson(p as Map<String, dynamic>))`。
- **备注：** 无。

### `IntimacyRecord({String? id, required String type, String? location, bool isSolo = false, String? partnerId, List<String> toyIds = const [], List<String> positionIds = const [], required int pleasureLevel, required Duration duration, int? thrustCount, int? thrustCountUnit, DateTime? datetime, String? notes, bool hadOrgasm = false, bool watchedPorn = false, bool usedCondom = false, DateTime? modifiedAt})` <a id="intimacyrecord-new"></a>
- **种类：** `IntimacyRecord` 的构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 482 行）
- **用途：** 创建亲密活动记录：独自/伴侣类型、地点、伴侣/玩具/姿势链接、愉悦度、时长、可选抽插次数和性高潮/色情/安全套标志。
- **输入：** `type`、`pleasureLevel`、`duration` 必填；`isSolo` 默认 `false`；`toyIds`/`positionIds` 默认为空列表；`thrustCountUnit` 规范化（见算法）；`id`/`datetime`/`modifiedAt` 省略时生成。
- **返回：** 新的 `IntimacyRecord`。
- **副作用：** 无。
- **算法：** 字段赋值构造函数；`id = id ?? const Uuid().v4()`、`thrustCountUnit = thrustCountUnit == 1 ? 1 : 100`（总是规范化为恰好 `1` 或 `100`）、`datetime = datetime ?? DateTime.now()`（本地时间，不同于 `modifiedAt`）、`modifiedAt = modifiedAt ?? DateTime.now().toUtc()`。
- **用法：**
  ```dart
  final record = IntimacyRecord(
    id: widget.record?.id,
    type: _isSolo ? 'Solo' : 'Regular',
    partnerId: _isSolo ? null : _selectedPartnerId,
    isSolo: _isSolo,
    pleasureLevel: _pleasureLevel,
    duration: Duration(minutes: totalMinutes),
    thrustCount: normalizedThrustCount,
    thrustCountUnit: _thrustCountUnit,
    datetime: _datetime,
    toyIds: _selectedToyIds.toList(),
    positionIds: _selectedPositionIds.toList(),
    hadOrgasm: _hadOrgasm,
    watchedPorn: _watchedPorn,
    usedCondom: _usedCondom,
    // ...
  );
  ```
  （`lib/features/intimacy/widgets/add_record_dialog.dart:520-538`，增/改记录对话框的提交处理器。）
- **备注：** `thrustCountUnit` 规范化意味着任何其他存储/传入值（如损坏数据）被静默强转为 `100`，匹配 [亲密](../../../../features/intimacy.md#timerstopwatch-session-persistence) 描述的 `x100`/`x1` 估计-vs-精确约定。此模型没有 `copyWith`——编辑走对话框重建完整 `IntimacyRecord`。

### `double? get resolvedThrustCount` <a id="resolvedthrustcount"></a>
- **种类：** `IntimacyRecord` 的 getter
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 510 行）
- **用途：** 返回此记录的实际次数抽插计数。
- **输入：** 无。
- **返回：** `double?` — 未记录可用抽插计数时为 null。
- **副作用：** 无。
- **算法：** `thrustCount` 为 null 或非正时返回 null；否则把它乘 `thrustCountUnit`（总是恰好 `1` 或 `100`）。
- **用法：** [`thrustsPerMinute`](#thrustsperminute) 的分子，以及趋势图 `thrustCount` 指标的值提取器（[`intimacy_trend_chart.dart`](../widgets/intimacy_trend_chart.md#metricspecs)）。
- **备注：** 派生，绝不持久化。v1.3.2 中从 `intimacy_page.dart` 的私有辅助提升到模型上，使 x1/x100 算术可单元测试和可复用。

### `double? get thrustsPerMinute` <a id="thrustsperminute"></a>
- **种类：** `IntimacyRecord` 的 getter
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 523 行）
- **用途：** 返回此记录每分钟抽插次数的平均速率。
- **输入：** 无。
- **返回：** `double?` — 除非记录**同时**有正时长和可用抽插计数，否则为 null。
- **副作用：** 无。
- **算法：** 把 [`resolvedThrustCount`](#resolvedthrustcount) 除以分钟表示的时长（`duration.inSeconds / 60`），任一输入缺失或时长为零时返回 null。
- **用法：** 整合趋势图上的 `thrustRate` 指标，以及伴侣/玩具详情摘要卡片上的"平均抽插速率"块（`_FilteredRecordsPageState._buildSummaryCard`）。
- **备注：** 派生，绝不持久化。时长以秒存储而条目对话框只接受整分钟，因此计时器派生的亚分钟条目可能产生大速率——那是算术，不是 bug。零时长守卫正是让除法安全的东西。

### `Map<String, dynamic> toJson()` <a id="intimacyrecord-tojson"></a>
- **种类：** `IntimacyRecord` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 510 行）
- **用途：** 把亲密记录序列化为存储在 `intimacy_data.json` 的 `records` 数组中的 JSON。
- **输入：** 无。
- **返回：** `id`/`type`/`isSolo`/`pleasureLevel`/`duration`/`datetime`/`hadOrgasm`/`watchedPorn`/`usedCondom`/`modifiedAt` 总是存在；`location`/`partnerId`/`toyIds`/`positionIds`/`thrustCount`（+`thrustCountUnit`）/`notes` 只在设置/非空时。
- **副作用：** 无。
- **算法：** 带 `if` 守卫的映射字面量；`duration` 为 `.inSeconds`；`thrustCountUnit` 只在非 null `thrustCount` 旁写入。
- **用法：** 从 `IntimacyData.toJson`（第 862 行）调用：`records.map((r) => r.toJson()).toList()`。
- **备注：** 无。

### `factory IntimacyRecord.fromJson(Map<String, dynamic> json)` <a id="intimacyrecord-fromjson"></a>
- **种类：** `IntimacyRecord` 的工厂构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 535 行）
- **用途：** 从持久化/同步 JSON 形态解析回亲密记录，容忍旧模式。
- **输入：** `json` — 解码映射。
- **返回：** 新的 `IntimacyRecord`。
- **副作用：** 无。
- **算法：** 转换必填字段（`type`、`pleasureLevel`、经 `DateTime.parse` 的 `datetime`）；`duration` 来自 `Duration(seconds: json['duration'] as int)`；`thrustCountUnit` 重新规范化为 `1` 或 `100`；`isSolo` 缺席时默认 `false`（注释说明旧记录改为有 `'partner'` 字符串字段，不再读取）；`modifiedAt` 缺失时回退 Unix 纪元。
- **用法：** 从 `IntimacyData.fromJson`（第 905 行）调用：`(json['records'] as List<dynamic>?)?.map((r) => IntimacyRecord.fromJson(r as Map<String, dynamic>))`。
- **备注：** `partnerId` 不再匹配任何既有伴侣（伴侣已被删除）的记录仍解析正常——已删除伴侣引用按设计被容忍，按 [亲密](../../../../features/intimacy.md#deleted-partner-handling)。

### `TimerHistoryEntry({required DateTime start, required Duration duration, int thrustCount = 0, int? thrustCountUnit})` <a id="timerhistoryentry-new"></a>
- **种类：** `TimerHistoryEntry` 的构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 582 行）
- **用途：** 创建单条计时器历史条目（独立于任何 `IntimacyRecord`）：开始时间、时长和可选抽插次数。
- **输入：** `start`、`duration` 必填；`thrustCount` 默认 `0`；`thrustCountUnit` 规范化。
- **返回：** 新的 `TimerHistoryEntry`。
- **副作用：** 无。
- **算法：** `thrustCount = thrustCount < 0 ? 0 : thrustCount`（钳制非负）；`thrustCountUnit = thrustCountUnit == 1 ? 1 : 100`。
- **用法：**
  ```dart
  final entry = TimerHistoryEntry(
    start: sessionStart,
    duration: elapsed,
    thrustCount: _storedThrustCount,
    thrustCountUnit: _storedThrustCountUnit,
  );
  ```
  （`lib/features/intimacy/widgets/timer_page.dart:458-463`，停止/保存秒表。）
- **备注：** [`TimerHistoryEntry.fromJson`](#timerhistoryentry-fromjson) 的旧 `end` 时间戳迁移路径也构造它。

### `Map<String, dynamic> toJson()` <a id="timerhistoryentry-tojson"></a>
- **种类：** `TimerHistoryEntry` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 595 行）
- **用途：** 把计时器历史条目序列化为存储在 `intimacy_data.json` 的 `timerHistory` 数组中的 JSON。
- **输入：** 无。
- **返回：** `{start, durationMs, thrustCount?, thrustCountUnit?}` — `thrustCount` 为 `0` 时抽插字段完全省略。
- **副作用：** 无。
- **算法：** 映射字面量；`duration` 在 `durationMs` 键下为 `.inMilliseconds`（不是 `duration`，以区别于旧 `end` 基础格式）。
- **用法：** 从 `IntimacyData.toJson`（第 863 行）调用：`timerHistory.map((e) => e.toJson()).toList()`。
- **备注：** 无。

### `factory TimerHistoryEntry.fromJson(Map<String, dynamic> json)` <a id="timerhistoryentry-fromjson"></a>
- **种类：** `TimerHistoryEntry` 的工厂构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 607 行）
- **用途：** 从 JSON 解析计时器历史条目，迁移存储 `end` 时间戳而非时长的旧条目。
- **输入：** `json` — 解码映射。
- **返回：** 新的 `TimerHistoryEntry`。
- **副作用：** 无。
- **算法：**
  1. 读取 `thrustCount`（默认 `0`，重新钳制非负）和 `thrustCountUnit`（规范化为 `1`/`100`）。
  2. `json` 含 `durationMs` 时，直接从 `start`/`Duration(milliseconds: durationMs)` 构建。
  3. 否则（旧格式），解析 `start` 和 `end` 两者，计算 `duration: end.difference(start)`。
- **用法：**
  ```dart
  final legacyEntries = list
      .map((e) => TimerHistoryEntry.fromJson(e as Map<String, dynamic>))
      .toList();
  ```
  （`lib/features/intimacy/services/intimacy_storage.dart:117`，在 [`_migrateLegacyTimerHistory`](../services/intimacy_storage.md#_migratelegacytimerhistory) 期间解析独立旧 `timer_history.json` 文件。）`IntimacyData.fromJson`（第 910 行）也调用它解析正常 `timerHistory` 数组。
- **备注：** 旧 `end` 基础分支正是让 `IntimacyStorage` 透明迁移 pre-时长 `timer_history.json` 文件、无需条目格式本身的单独迁移代码路径的东西。

### `IntimacyTimerSession({required DateTime firstStartedAt, DateTime? startedAt, required Duration accumulated, required bool running, int thrustCount = 0, int? thrustCountUnit})` <a id="intimacytimersession-new"></a>
- **种类：** `IntimacyTimerSession` 的构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 644 行）
- **用途：** 创建持久化激活/暂停秒表会话快照：原始开始时间、上次恢复时间、累积已流逝时间、运行标志和可选抽插次数。
- **输入：** `firstStartedAt`、`accumulated`、`running` 必填；`startedAt` 可选（最近恢复时间，暂停时为 `null`）；`thrustCount` 默认 `0`；`thrustCountUnit` 规范化。
- **返回：** 新的 `IntimacyTimerSession`。
- **副作用：** 无。
- **算法：** `thrustCount` 钳制非负；`thrustCountUnit` 规范化为 `1`/`100`，与 `TimerHistoryEntry` 相同。
- **用法：**
  ```dart
  return IntimacyTimerSession(
    firstStartedAt: firstStartedAt,
    startedAt: _running ? _startedAt : null,
    accumulated: _accumulated,
    running: _running,
    thrustCount: _storedThrustCount,
    thrustCountUnit: _storedThrustCountUnit,
  );
  ```
  （`lib/features/intimacy/widgets/timer_page.dart:380-387`，`_timerSession` getter 快照实时计时器供持久化。）
- **备注：** `accumulated` 存储最新运行段之前的已流逝时间——两者如何组合见 [`elapsedAt`](#elapsedat)。

### `Duration elapsedAt(DateTime now)` <a id="elapsedat"></a>
- **种类：** `IntimacyTimerSession` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 659 行）
- **用途：** 计算给定挂钟时刻的计时器已流逝时长。
- **输入：** `now`。
- **返回：** `Duration`。
- **副作用：** 无。
- **算法：** 未 `running` 或 `startedAt == null` 时原样返回 `accumulated`；否则返回 `accumulated + now.difference(startedAt!)`。
- **用法：** 目前本仓库其他文件不调用（今天只有 `toJson`/`fromJson` 和计时器组件自己单独维护的 `_accumulated`/`_startedAt` 字段被用到）；按 [亲密](../../../../features/intimacy.md#timerstopwatch-session-persistence) 的预期调用形态是 `session.elapsedAt(DateTime.now())`，从恢复的会话重新计算实时已流逝时间。
- **备注：** 这正是让运行中会话在应用重启后从真实挂钟时间恢复、而不是过期内存计数器的东西——运行时 `accumulated + (now - startedAt)`。

### `Map<String, dynamic> toJson()` <a id="intimacytimersession-tojson"></a>
- **种类：** `IntimacyTimerSession` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 669 行）
- **用途：** 把计时器会话序列化为存储在 `intimacy_data.json` 的 `timerSession` 键下的 JSON。
- **输入：** 无。
- **返回：** `{firstStartedAt, startedAt?, accumulatedMs, running, thrustCount?, thrustCountUnit?}` — `startedAt` 和抽插字段缺席/为零时省略。
- **副作用：** 无。
- **算法：** 映射字面量；`accumulated` 在 `accumulatedMs` 下为 `.inMilliseconds`。
- **用法：** 从 `IntimacyData.toJson`（第 864 行）调用：`timerSession!.toJson()`，只在 `timerSession != null` 时。
- **备注：** 无。

### `factory IntimacyTimerSession.fromJson(Map<String, dynamic> json)` <a id="intimacytimersession-fromjson"></a>
- **种类：** `IntimacyTimerSession` 的工厂构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 683 行）
- **用途：** 从持久化 JSON 形态解析回计时器会话，恢复被中断的激活/暂停秒表。
- **输入：** `json` — 解码映射。
- **返回：** 新的 `IntimacyTimerSession`。
- **副作用：** 无。
- **算法：**
  1. 解析 `firstStartedAt`（必填）和 `startedAt`（可空）。
  2. `running = json['running'] as bool? ?? startedAt != null` — `running` 键本身缺席（旧数据）时从 `startedAt` 的存在推断运行。
  3. 结果中的 `startedAt` 是 `running ? (startedAt ?? firstStartedAt) : null` — 无自己 `startedAt` 的运行中会话回退 `firstStartedAt`。
  4. `thrustCount` 重新钳制非负；`thrustCountUnit` 重新规范化。
- **用法：** 从 `IntimacyData.fromJson`（第 914-916 行）调用，由 `json['timerSession'] is Map<String, dynamic>` 守卫。
- **备注：** 第 2 步的推断正是让在显式 `running` 键存在前持久化的会话仍正确恢复的东西，按 [亲密](../../../../features/intimacy.md#timerstopwatch-session-persistence) 的恢复规则（停止但未保存和暂停的会话恢复为暂停；运行中会话实时恢复）。

### `const IntimacyChartSettings({List<String> metrics = defaultMetrics, String range = defaultRange})` <a id="intimacychartsettings-new"></a>
- **种类：** `IntimacyChartSettings` 的构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 752 行）
- **用途：** 创建亲密图表设置实例。
- **输入：** `metrics` 和 `range`，都默认为内置选择（`['pleasure', 'duration', 'thrustRate']` 和 `'3m'`）。
- **返回：** 新的 `IntimacyChartSettings` 实例。
- **副作用：** 无。
- **备注：** 标识符在这里刻意**不**校验：未知值必须经往返存活，使新构建的选择不被旧构建销毁。图表组件在渲染时过滤它们。`const` 使默认值能是编译期常量。

### `Map<String, dynamic> toJson()` <a id="intimacychartsettings-tojson"></a>
- **种类：** `IntimacyChartSettings` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 762 行）
- **用途：** 把这个值序列化为 JSON 兼容映射。
- **输入：** 无。
- **返回：** `{'metrics': [...], 'range': '...'}` — 两个键总是写入。
- **副作用：** 无。
- **备注：** 这里无条件，但 `IntimacyData.toJson` 只在对象非 null 时发出整个 `chartSettings` 对象，这正是让 WebDAV golden 转录跨 v1.3.2 保持逐字节相同的东西。

### `factory IntimacyChartSettings.fromJson(Map<String, dynamic>? json)` <a id="intimacychartsettings-fromjson"></a>
- **种类：** `IntimacyChartSettings` 的工厂构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 770 行）
- **用途：** 从 JSON 兼容映射创建实例。
- **输入：** `json`，可能为 null。
- **返回：** 新的 `IntimacyChartSettings` 实例。
- **副作用：** 无。
- **算法：** null 映射产生默认值。否则取 `metrics` 列表过滤为字符串，缺失或为空时回退默认，`range` 缺席时回退默认。
- **备注：** 对格式错误输入绝不抛出，匹配财务模块的 `AccountPickerSettings.fromJson`。`metrics` 中的非字符串条目被丢弃而不是使加载崩溃——亲密数据在解析问题时绝不被当作空，因此这里的容忍很重要。

### `IntimacyChartSettings copyWith({List<String>? metrics, String? range})` <a id="intimacychartsettings-copywith"></a>
- **种类：** `IntimacyChartSettings` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 786 行）
- **用途：** 返回所选字段替换后的设置副本。
- **输入：** `metrics`、`range`。
- **返回：** 新的 `IntimacyChartSettings` 实例。
- **副作用：** 无。
- **用法：** `IntimacyTrendChart._toggleMetric` 和它的范围芯片都这样构建上报值。
- **备注：** 无。

### `IntimacyData({required List<Partner> partners, required List<Toy> toys, List<Position> positions = const [], required List<IntimacyRecord> records, List<TimerHistoryEntry> timerHistory = const [], IntimacyTimerSession? timerSession, DateTime? timerSessionModifiedAt, BodyProfile? userBody, DateTime? userBodyModifiedAt, List<CycleRecord> cycleRecords = const [], int? timerHistoryRetentionDays, Map<String, String> partnerSortModes = const {}, Map<String, List<String>> partnerCustomOrders = const {}, Map<String, String> toySortModes = const {}, Map<String, List<String>> toyCustomOrders = const {}, IntimacyChartSettings? chartSettings, DateTime? settingsModifiedAt})` <a id="intimacydata-new"></a>
- **种类：** `IntimacyData` 的构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 828 行）
- **用途：** 创建顶层亲密数据容器：伴侣、玩具、姿势、记录、计时器历史/会话、用户自己的身体档案、周期记录和伴侣/玩具排序设置。
- **输入：** `partners`、`toys`、`records` 必填；其他都可选，带空集合或 `null` 默认。
- **返回：** 新的 `IntimacyData`。
- **副作用：** 无。
- **算法：** 字段赋值构造函数；三个独立 LWW 时间戳未提供时各默认 UTC Unix 纪元（`timerSessionModifiedAt`、`userBodyModifiedAt`），唯独 `settingsModifiedAt` 默认 `DateTime.now().toUtc()`（"现在"默认，不同于其他两个的纪元零"从未触碰"哨兵）。
- **用法：**
  ```dart
  await IntimacyStorage.save(
    IntimacyData(
      partners: _partners,
      toys: _toys,
      positions: _positions,
      records: _records,
      timerHistory: _timerHistory,
      timerSession: _timerSession,
      timerSessionModifiedAt: _timerSessionModifiedAt,
      userBody: _userBody,
      userBodyModifiedAt: _userBodyModifiedAt,
      cycleRecords: _cycleRecords,
      timerHistoryRetentionDays: _timerHistoryRetentionDays,
      partnerSortModes: _partnerSortModes,
      partnerCustomOrders: _partnerCustomOrders,
      toySortModes: _toySortModes,
      toyCustomOrders: _toyCustomOrders,
      settingsModifiedAt: _settingsModifiedAt,
    ),
  );
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:234-253`，`_saveData()`。）
- **备注：** `timerSessionModifiedAt`/`userBodyModifiedAt` 各自独立于 `settingsModifiedAt` 只跟踪自己的字段，因此对其中一个的 LWW 同步合并绝不覆盖其他——[亲密](../../../../features/intimacy.md#models) 文档化的相同独立时间戳模式。此模型没有 `copyWith`；[`IntimacyStorage._migrateLegacyTimerHistory`](../services/intimacy_storage.md#_migratelegacytimerhistory) 逐字段重建完整新实例。

### `Map<String, dynamic> toJson()` <a id="intimacydata-tojson"></a>
- **种类：** `IntimacyData` 的方法
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 858 行）
- **用途：** 把整个亲密数据树序列化为写入 `intimacy_data.json` 的顶层 JSON。
- **输入：** 无。
- **返回：** `partners`/`toys`/`positions`/`records`/`timerHistory`/`timerSessionModifiedAt`/`settingsModifiedAt` 总是存在（作为每个元素自己的 `toJson()` 的列表）；`timerSession`/`userBody`（只在 `!isEmpty`）/`userBodyModifiedAt`（只在非纪元零）/`cycleRecords`/`timerHistoryRetentionDays`/四个排序模式/自定义顺序映射只在非 null/非空时包含。
- **副作用：** 无。
- **算法：** 映射字面量；每个列表字段经其元素类型自己的 `toJson()` 映射。
- **用法：** 从 [`IntimacyStorage._saveNow`](../services/intimacy_storage.md#_savenow)（第 94 行）调用：`next: data.toJson()`。
- **备注：** 无。

### `factory IntimacyData.fromJson(Map<String, dynamic> json)` <a id="intimacydata-fromjson"></a>
- **种类：** `IntimacyData` 的工厂构造函数
- **来源：** `lib/features/intimacy/models/intimacy_record.dart`（第 886 行）
- **用途：** 从 `intimacy_data.json` 解析回整个亲密数据树。
- **输入：** `json` — 解码顶层映射。
- **返回：** 新的 `IntimacyData`。
- **副作用：** 无。
- **算法：** 每个列表字段经 `(json[k] as List<dynamic>?)?.map(...).toList() ?? []` 通过对应模型自己的 `fromJson` 解析；`timerSession`/`userBody` 由 `is Map<String, dynamic>` 类型检查守卫；`timerSessionModifiedAt` 和 `userBodyModifiedAt` 都缺失时回退 UTC Unix 纪元；两个排序模式映射和两个自定义顺序映射各以 null 安全 `.map(...)` 解析或默认 `const {}`。
- **用法：** 从 [`IntimacyStorage.load`](../services/intimacy_storage.md#load)（第 58 行）调用：`var data = IntimacyData.fromJson(json);`。
- **备注：** 除上面已覆盖的外无——每个集合/时间戳字段独立退化到空/纪元零默认，因此部分格式错误的文件仍尽可能解析。

## 相关页面

- [亲密](../../../../features/intimacy.md) — 这些模型支撑的功能，包括默认隐藏可见性开关、身体层和已删除伴侣处理。
- [数据格式](../../../../data-formats.md#intimacy--intimacy_datajson) — 上面每个模型的精确 JSON 字段列表。
- [三方合并](../../../../algorithms/three-way-merge.md#deletionunion-semantics) — `CycleRecord` 的仅增/删、按 id 合并语义。
- [身体指标](../../../../algorithms/body-metrics.md) — 读取 `BodyProfile`/`CycleRecord` 字段的罩杯/PSI/周期预测计算（`services/body_metrics.md`、`services/cycle_predictor.md`）。
- [`intimacy_storage.dart`](../services/intimacy_storage.md) — 加载/保存这里定义的 `IntimacyData` 树。

# lib/features/finance/services/exchange_rate_storage.dart

`exchange_rates.json` 的持久化层，把汇率存储为不可变 `RateSnapshot` 的去重历史加 `currentSnapshotId` 指针，而不是单个平铺币种对映射——这正是让 `Transaction.rateSnapshotId` 重建历史交易记录时生效的确切汇率的东西（见 [`ratesAt`](#ratesat) 和 [`balance_util.dart`](balance_util.md) 的 `_accountTransactionDelta`）。`load()` 透明地把旧平铺映射文件格式迁移进第一个快照。功能级概览见 [财务](../../../../features/finance.md#exchange-rates)，调用 [`updateRates`](#updaterates) 的实时获取客户端见 [`ExchangeRateApi`](exchange_rate_api.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`RateSnapshot()`](#ratesnapshot-new) | 构造函数（`RateSnapshot`） | A | 创建带生成 id/时间戳的汇率快照。 |
| [`toJson`](#ratesnapshot-tojson) | 方法（`RateSnapshot`） | A | 把汇率快照序列化为 JSON。 |
| [`RateSnapshot.fromJson`](#ratesnapshot-fromjson) | 工厂构造函数（`RateSnapshot`） | A | 从 JSON 解析汇率快照。 |
| [`ExchangeRateData()`](#exchangeratedata-new) | 构造函数（`ExchangeRateData`） | A | 打包所有快照加当前快照指针。 |
| [`currentRates`](#currentrates) | getter（`ExchangeRateData`） | A | 激活快照的汇率映射。 |
| [`ratesAt`](#ratesat) | 方法（`ExchangeRateData`） | A | 特定历史快照的汇率，回退当前。 |
| [`toJson`](#exchangeratedata-tojson) | 方法（`ExchangeRateData`） | A | 把汇率数据序列化为 JSON。 |
| [`ExchangeRateData.fromJson`](#exchangeratedata-fromjson) | 工厂构造函数（`ExchangeRateData`） | A | 从 JSON 解析汇率数据。 |
| [`_getFile`](#getfile) | 静态方法（`ExchangeRateStorage`） | A | 解析 `exchange_rates.json` 的磁盘路径。 |
| [`load`](#load) | 静态方法（`ExchangeRateStorage`） | A | 加载、解析并迁移 `exchange_rates.json`。 |
| [`save`](#save) | 静态方法（`ExchangeRateStorage`） | A | 排队汇率数据写入，对照并发保存串行化。 |
| [`_saveNow`](#savenow) | 静态方法（`ExchangeRateStorage`） | A | 执行一次保留、校验、原子写入。 |
| [`updateRates`](#updaterates) | 静态方法（`ExchangeRateStorage`） | A | 只在汇率实际变化时创建新快照。 |
| [`_ratesEqual`](#ratesequal) | 静态方法（`ExchangeRateStorage`） | A | 精确相等地比较两个汇率映射。 |
| [`_defaultData`](#defaultdata) | 静态方法（`ExchangeRateStorage`） | A | 构建内置默认汇率数据。 |
| [`_createInitialData`](#createinitialdata) | 静态方法（`ExchangeRateStorage`） | A | 把平铺汇率映射包装为第一个快照。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/services/exchange_rate_storage.dart` 返回 16，与上面 16 行精确匹配——每个块都恰好位于其真实声明（构造函数、工厂构造函数、getter 或静态方法）正上方；未发现错附在调用点语句上方。文件中的剩余普通字段（`_fileName`、`_writeQueue`、`_defaultRates`）不带 `/// Purpose:` 块，与本代码库记录可调用成员而非普通数据的约定一致，它们都不构成未文档化的可调用声明。全部 16 个文档化声明分类为 Tier A：模型构造函数/序列化对匹配定级规则显式的 Tier A 桶，每个 `ExchangeRateStorage` 静态方法都执行真实 IO、分支或循环逻辑（包括 `currentRates`/`ratesAt`，其单行映射查找经 `balance_util.dart` 喂入功能中的每次币种转换；以及 `_defaultData`，其默认汇率是每个全新安装开始的回退）。

## 文档

### `RateSnapshot({String? id, required Map<String, double> rates, DateTime? createdAt})` <a id="ratesnapshot-new"></a>
- **种类：** `RateSnapshot` 的构造函数
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 22 行）
- **用途：** 保存每个配置币种对汇率的一个不可变时点快照。
- **输入：** `rates` 必填；`id`/`createdAt` 可选。
- **返回：** 新的 `RateSnapshot`。
- **副作用：** 无。
- **算法：** 字段赋值构造函数；`id` 默认新 UUID v4、`createdAt` 默认 `DateTime.now()`。
- **用法：**
  ```dart
  final snapshot = RateSnapshot(rates: Map.unmodifiable(newRates));
  ```
  （`lib/features/finance/services/exchange_rate_storage.dart:215`，[`updateRates`](#updaterates) 内；[`_createInitialData`](#createinitialdata) 也用它把平铺汇率映射包装为第一个快照。）
- **备注：** `updateRates` 总是传不可修改汇率映射，防止意外原地修改本应不可变历史的快照。

### `Map<String, dynamic> toJson()` <a id="ratesnapshot-tojson"></a>
- **种类：** `RateSnapshot` 的方法
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 31 行）
- **用途：** 把一个快照序列化为嵌套在 `ExchangeRateData.snapshots` 下的 JSON。
- **输入：** 无。
- **返回：** `{id, rates, createdAt}`。
- **副作用：** 无。
- **算法：** 直接映射字面量；`createdAt` 为 `toIso8601String()`。
- **用法：** 从 `ExchangeRateData.toJson()` 调用：`snapshots.map((k, v) => MapEntry(k, v.toJson()))`（`lib/features/finance/services/exchange_rate_storage.dart:93`）。
- **备注：** 无。

### `factory RateSnapshot.fromJson(Map<String, dynamic> json)` <a id="ratesnapshot-fromjson"></a>
- **种类：** `RateSnapshot` 的工厂构造函数
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 42 行）
- **用途：** 从持久化 JSON 形态解析回一个快照。
- **输入：** `json` — 解码映射，`ExchangeRateData.snapshots` 的一个条目。
- **返回：** 新的 `RateSnapshot`。
- **副作用：** 无。
- **算法：** 转换 `id`；把 `rates`（`Map<String, dynamic>`）映射为 `Map<String, double>`；经 `DateTime.parse` 解析 `createdAt`。
- **用法：** 从 `ExchangeRateData.fromJson` 调用：`MapEntry(k, RateSnapshot.fromJson(v as Map<String, dynamic>))`（`lib/features/finance/services/exchange_rate_storage.dart:105`）。
- **备注：** 与财务功能大多数 `fromJson` 工厂不同，这个对缺失 `createdAt` 没有防御回退——格式错误的快照抛出，向上传播经 `ExchangeRateData.fromJson` 到 `load()` 的兜底（回退 `_defaultData()`）。

### `ExchangeRateData({required String currentSnapshotId, required Map<String, RateSnapshot> snapshots, DateTime? lastFetchedAt})` <a id="exchangeratedata-new"></a>
- **种类：** `ExchangeRateData` 的构造函数
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 62 行）
- **用途：** 保存每个保留的汇率快照加指向当前激活的一个的指针，以及上次自动获取汇率的时间。
- **输入：** `currentSnapshotId`、`snapshots` 必填；`lastFetchedAt` 可选（驱动 [`ExchangeRateApi.shouldFetchToday`](exchange_rate_api.md#shouldfetchtoday)）。
- **返回：** 新的 `ExchangeRateData`。
- **副作用：** 无。
- **算法：** 平凡字段赋值构造函数（不像本功能大多数其他模型那样生成默认值）。
- **用法：**
  ```dart
  final withTimestamp = ExchangeRateData(
    currentSnapshotId: updated.currentSnapshotId,
    snapshots: updated.snapshots,
    lastFetchedAt: DateTime.now(),
  );
  await ExchangeRateStorage.save(withTimestamp);
  ```
  （`lib/features/finance/views/exchange_rates_page.dart:72-77`，成功在线获取后盖章 `lastFetchedAt`。）
- **备注：** 无。

### `Map<String, double> get currentRates` <a id="currentrates"></a>
- **种类：** `ExchangeRateData` 的 getter
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 74 行）
- **用途：** 返回 `currentSnapshotId` 指向的快照的汇率映射。
- **输入：** 无。
- **返回：** `Map<String, double>` — `currentSnapshotId` 解析不到已知快照时为 `const {}`。
- **副作用：** 无。
- **算法：** `snapshots[currentSnapshotId]?.rates ?? const {}`。
- **用法：**
  ```dart
  final currentRates = widget.rateData.currentRates;
  ```
  （`lib/features/finance/views/analysis_page.dart:860`，在需要"今天"的汇率而不是交易历史快照的任何地方使用，如转换重建的账户余额。）
- **备注：** 无。

### `Map<String, double> ratesAt(String? snapshotId)` <a id="ratesat"></a>
- **种类：** `ExchangeRateData` 的方法
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 83 行）
- **用途：** 返回特定历史快照时生效的汇率，id 缺失或未知时回退当前汇率。
- **输入：** `snapshotId` — 通常是 `Transaction.rateSnapshotId`。
- **返回：** `Map<String, double>`。
- **副作用：** 无。
- **算法：** `snapshots[snapshotId]?.rates ?? currentRates`。
- **用法：**
  ```dart
  final rates = rateData.ratesAt(tx.rateSnapshotId);
  ```
  （`lib/features/finance/services/balance_util.dart:316`，`_accountTransactionDelta` 内——用记录时生效的汇率转换交易金额的中心位置。）
- **备注：** 在汇率快照存在之前记录的交易（`rateSnapshotId == null`）透明回退今天的汇率。

### `Map<String, dynamic> toJson()` <a id="exchangeratedata-tojson"></a>
- **种类：** `ExchangeRateData` 的方法
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 91 行）
- **用途：** 把完整快照历史序列化为持久化为 `exchange_rates.json` 的 JSON。
- **输入：** 无。
- **返回：** `{currentSnapshotId, snapshots: {...}, lastFetchedAt?}`。
- **副作用：** 无。
- **算法：** 映射字面量；`snapshots` 逐条目经 `RateSnapshot.toJson()` 映射；`lastFetchedAt` 只在非 null 时包含。
- **用法：** 从 [`_saveNow`](#savenow) 调用：`jsonEncode(data.toJson())`（非迁移路径）或作为传给 `JsonPreservation.encodeForFile` 的 `next` 负载。
- **备注：** 无。

### `factory ExchangeRateData.fromJson(Map<String, dynamic> json)` <a id="exchangeratedata-fromjson"></a>
- **种类：** `ExchangeRateData` 的工厂构造函数
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 103 行）
- **用途：** 从 `exchange_rates.json` 当前格式 JSON（即已有 `snapshots` 键的）解析回完整快照历史。
- **输入：** `json` — 解码映射。
- **返回：** 新的 `ExchangeRateData`。
- **副作用：** 无。
- **算法：** 把 `json['snapshots']` 条目逐个经 [`RateSnapshot.fromJson`](#ratesnapshot-fromjson) 映射；读取 `currentSnapshotId`；存在时解析 `lastFetchedAt`。
- **用法：** 从 [`load`](#load) 调用：`return ExchangeRateData.fromJson(json);`，迁移检查确认文件已有 `snapshots` 键之后。
- **备注：** 假设 `json['snapshots']` 存在——调用方必须首先检查旧平铺映射格式（见 [`load`](#load) 的迁移分支），否则这抛出。

### `static Future<File> _getFile()` <a id="getfile"></a>
- **种类：** `ExchangeRateStorage` 的静态方法
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 127 行）
- **用途：** 解析应用数据目录内 `exchange_rates.json` 的 `File` 句柄。
- **输入：** 无。
- **返回：** `Future<File>`。
- **副作用：** 无直接（只构建路径）。
- **算法：** `appDir = await TodoStorage.getAppDir()`，然后 `File('${appDir.path}/$_fileName')`——复用 Todo 的应用目录解析，与本应用其他每个存储类相同的模式。
- **用法：** 在 [`load`](#load) 和 [`_saveNow`](#savenow) 顶部调用。
- **备注：** 无。

### `static Future<ExchangeRateData> load()` <a id="load"></a>
- **种类：** `ExchangeRateStorage` 的静态方法
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 137 行）
- **用途：** 加载 `exchange_rates.json`，透明地把旧平铺币种对映射格式迁移进单快照历史，任何失败回退内置默认值。
- **输入：** 无。
- **返回：** `Future<ExchangeRateData>` — 绝不 `null`；缺失或损坏文件解析为 [`_defaultData()`](#defaultdata)。
- **副作用：** 从磁盘读取 `exchange_rates.json`。
- **算法：**
  1. 文件不存在时返回 `_defaultData()`。
  2. 解码其 JSON。
  3. **迁移：** 解码映射没有 `snapshots` 键（旧平铺映射格式）时，把每个条目当作 `Map<String, double>` 并经 [`_createInitialData`](#createinitialdata) 包装为第一个快照。
  4. 否则经 [`ExchangeRateData.fromJson`](#exchangeratedata-fromjson) 直接解析。
  5. 此路径中的任何异常（缺失文件竞争、坏 JSON、格式错误快照）被捕获并映射为 `_defaultData()`。
- **用法：**
  ```dart
  final data = await ExchangeRateStorage.load();
  ```
  （`lib/features/finance/views/exchange_rates_page.dart:50`；`finance_storage.dart` 的 `load()` 也用它运行强制余额迁移，`webdav_service.dart` 的 `_migrateFinanceForcedBalances` 同步期间也出于同样原因使用。）
- **备注：** 与 `FinanceStorage.load()` 和 `WeightStorage.load()` 不同，这绝不向调用方抛出——每个失败路径静默退化到内置默认汇率而不是浮出错误，因为汇率不如账户/交易那样是关键的用户数据。

### `static Future<void> save(ExchangeRateData data)` <a id="save"></a>
- **种类：** `ExchangeRateStorage` 的静态方法
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 163 行）
- **用途：** 排队 `data` 的写入，确保重叠 `save` 调用绝不交错它们对 `exchange_rates.json` 的写入。
- **输入：** `data`。
- **返回：** 在此特定写入完成时完成的 `Future<void>`。
- **副作用：** 最终写 `exchange_rates.json`（经 `_saveNow`）；修改静态 `_writeQueue` 字段。
- **算法：** 链到 `_writeQueue` 上，使 `_saveNow(data)` 无论先前排队写入是否成功都运行（`next = _writeQueue.then((_) => _saveNow(data), onError: (_) => _saveNow(data))`），用吞错误的 `next` 版本替换 `_writeQueue`，并把未吞的 `next` 返回给此调用方。这是 `WeightStorage.save` 和 `FinanceStorage.save` 使用的相同写入串行化模式。
- **用法：**
  ```dart
  await ExchangeRateStorage.save(withTimestamp);
  AutoSyncService.instance.notifySaved();
  ```
  （`lib/features/finance/views/exchange_rates_page.dart:77-78`。）
- **备注：** 并发 `save()` 调用严格按调用顺序串行化——与 `WeightStorage.save` 文档化的相同重叠写入者保护。

### `static Future<void> _saveNow(ExchangeRateData data)` <a id="savenow"></a>
- **种类：** `ExchangeRateStorage` 的静态方法
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 177 行）
- **用途：** 在调用方已在写队列中轮到它之后，执行一次 `data` 对 `exchange_rates.json` 的实际写入——包括一次性检测磁盘文件是否仍是旧平铺映射格式。
- **输入：** `data`。
- **返回：** `Future<void>`。
- **副作用：** 经 `DataFileSafety.writeValidatedDataJson`（校验、原子替换）写 `exchange_rates.json`。
- **算法：**
  1. 解析文件；存在时解码并检查是否有 `snapshots` 键（`preserveUnknown`）。此处的任何解码失败被吞掉并当作 `preserveUnknown = true`。
  2. 磁盘文件仍是旧平铺映射格式（`preserveUnknown == false`）时，直接写 `jsonEncode(data.toJson())`——没有要对旧格式保留的未知字段模式。
  3. 否则在写入前对 `'exchange_rates.json'` 注册的模式运行 `JsonPreservation.encodeForFile`，使新版应用写入而本版模型不知道的字段在往返中存活。
- **用法：** 只从 [`save`](#save) 的写队列链调用。
- **备注：** 这是财务功能中保存路径按*当前磁盘格式*分支而不是总是运行未知字段保留的唯一存储类——直接源于支持平铺映射 -> 快照历史迁移。

### `static ExchangeRateData updateRates(ExchangeRateData data, Map<String, double> newRates)` <a id="updaterates"></a>
- **种类：** `ExchangeRateStorage` 的静态方法
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 208 行）
- **用途：** 应用一组新汇率，只在汇率与当前快照实际不同时创建新 `RateSnapshot`（并推进 `currentSnapshotId`）——因此相同的获取或保存绝不无意义地增长快照历史。
- **输入：** `data` — 当前状态；`newRates` — 候选新汇率映射。
- **返回：** `ExchangeRateData` — [`_ratesEqual`](#ratesequal) 说没有变化时 `data` 不变（同一对象），否则是带一个额外快照的新值。
- **副作用：** 无（返回新值；自己不写磁盘）。
- **算法：**
  1. 经 [`_ratesEqual`](#ratesequal) 比较 `data.currentRates` 与 `newRates`；相等则原样返回 `data`。
  2. 否则构建新 `RateSnapshot(rates: Map.unmodifiable(newRates))`，加入 `data.snapshots` 的副本，并返回指向它的 `currentSnapshotId` 的新 `ExchangeRateData`（丢弃 `lastFetchedAt`——需要保留它的调用方，如 [`ExchangeRateApi.fetchAndMerge`](exchange_rate_api.md#fetchandmerge) 的调用方，之后重新盖章）。
- **用法：**
  ```dart
  return ExchangeRateStorage.updateRates(data, newRates);
  ```
  （`lib/features/finance/services/exchange_rate_api.dart:54`，[`ExchangeRateApi.fetchAndMerge`](exchange_rate_api.md#fetchandmerge) 的最后一步；用户手动编辑汇率时 `exchange_rates_page.dart:94` 也直接调用。）
- **备注：** 旧快照绝不移除——历史只增不减，这正是让 `ratesAt(oldSnapshotId)` 无限期正确解析历史交易的东西。

### `static bool _ratesEqual(Map<String, double> a, Map<String, double> b)` <a id="ratesequal"></a>
- **种类：** `ExchangeRateStorage` 的静态方法
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 229 行）
- **用途：** 决定两个汇率映射是否精确相等，门控 [`updateRates`](#updaterates) 是否需要创建新快照。
- **输入：** `a`、`b`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 长度不同为 `false`；否则在 `a` 中值不等于 `b` 中值的第一个键为 `false`；每个键匹配为 `true`。
- **用法：** 在 [`updateRates`](#updaterates) 内调用一次：`if (_ratesEqual(current, newRates)) return data;`。
- **备注：** 只遍历 `a` 的键比较——这里正确，因为调用方只传同形态的汇率映射（两者都从同一配置对集合派生），因此长度检查加单向键迭代就足够了。

### `static ExchangeRateData _defaultData()` <a id="defaultdata"></a>
- **种类：** `ExchangeRateStorage` 的静态方法
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 242 行）
- **用途：** 构建尚不存在文件或加载失败时使用的内置默认汇率数据。
- **输入：** 无。
- **返回：** `ExchangeRateData`。
- **副作用：** 无。
- **算法：** `_createInitialData(_defaultRates)`——用硬编码 `_defaultRates` 映射（USD/EUR/GBP/JPY/CAD/AUD 对 CNY，加 EUR_USD/GBP_USD）对 [`_createInitialData`](#createinitialdata) 的一行转发。
- **用法：** 从 [`load`](#load) 的两个失败路径（缺失文件、任何异常）调用。
- **备注：** 硬编码默认值只是近似参考值——它们存在是为了让应用在用户首次成功在线获取或手动编辑之前有*东西*可转换。

### `static ExchangeRateData _createInitialData(Map<String, double> rates)` <a id="createinitialdata"></a>
- **种类：** `ExchangeRateStorage` 的静态方法
- **来源：** `lib/features/finance/services/exchange_rate_storage.dart`（第 249 行）
- **用途：** 把平铺币种对汇率映射包装为新 `ExchangeRateData` 历史的第一个（也是唯一）快照。
- **输入：** `rates`。
- **返回：** 恰好一个快照的 `ExchangeRateData`。
- **副作用：** 无。
- **算法：** 构建单个 `RateSnapshot(rates: rates)`，然后 `snapshots` 映射有那一个条目、`currentSnapshotId` 指向它的 `ExchangeRateData`。
- **用法：** 从 [`_defaultData`](#defaultdata)（全新安装）和 [`load`](#load) 的旧格式迁移分支（既有平铺映射文件的汇率成为第一个快照）都调用。
- **备注：** 这是快照历史之前的平铺汇率映射被转换为快照格式的唯一地方——"尚无文件"和"旧文件格式"两种情形都经它汇集。

# lib/features/intimacy/services/intimacy_storage.dart

`intimacy_data.json` 的持久化层：经单个串行化写队列加载/保存 [`IntimacyData`](../models/intimacy_record.md#intimacydata-new)，既有文件存在但无法安全读取时抛类型化异常，并把"不覆盖未知字段"和原子写入加校验工作分别委托给 [`JsonPreservation`](../../../shared/utils/json_preservation.md#encodeforfile) 和 `DataFileSafety.writeValidatedDataJson`（`lib/shared/services/data_file_safety.dart`）。它还在首次加载时拥有把旧独立 `timer_history.json` 文件折叠进 `IntimacyData.timerHistory` 的一次性迁移。本文件与本代码库其他每个功能的存储服务形态相同（对照 [`weight_storage.dart`](../../weight/services/weight_storage.md)）。它支撑的功能见 [亲密](../../../../features/intimacy.md)，精确 JSON 形态见 [数据格式](../../../../data-formats.md#intimacy--intimacy_datajson)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`IntimacyStorageException()`](#intimacystorageexception-new) | const 构造函数（`IntimacyStorageException`） | A | 创建带用户可见消息的亲密存储异常。 |
| `IntimacyStorageException.toString` | 方法（`IntimacyStorageException`） | B | 返回异常消息作为其字符串表示。 |
| [`_getFile`](#_getfile) | 静态方法（`IntimacyStorage`） | A | 解析 `intimacy_data.json` 的磁盘路径。 |
| [`load`](#load) | 静态方法（`IntimacyStorage`） | A | 加载并解析 `intimacy_data.json`，迁移旧计时器历史，不存在时为 `null`。 |
| [`save`](#save) | 静态方法（`IntimacyStorage`） | A | 排队 `IntimacyData` 写入，对照并发保存串行化。 |
| [`_saveNow`](#_savenow) | 静态方法（`IntimacyStorage`） | A | 执行一次 `IntimacyData` 的保留、校验、原子写入。 |
| [`_migrateLegacyTimerHistory`](#_migratelegacytimerhistory) | 静态方法（`IntimacyStorage`） | A | 把旧 `timer_history.json` 条目折叠进 `IntimacyData.timerHistory`，然后删除旧文件。 |

**对账：** `grep -c 'Purpose:' lib/features/intimacy/services/intimacy_storage.dart` 报告 7，与本文件全部 7 个真实声明精确匹配。未发现错附文档注释，也不存在未文档化的真实声明。类的私有静态字段（`_fileName`、`_legacyTimerFileName`、`_writeQueue`）是普通内部管道，不计为声明，与 `weight_storage.dart` 的 `fileName`/`_writeQueue` 被排除出自己页面的方式相同。七个声明中六个是 Tier A：`IntimacyStorageException` 的构造函数是真实（虽简单）模型风格构造函数，`_getFile`/`load`/`save`/`_saveNow`/`_migrateLegacyTimerHistory` 都按显式 services/IO Tier A 规则执行真实 IO 或分支。`toString()` 是唯一的 Tier B 声明——无自身逻辑、返回存储字段的平凡访问器。

## 文档

### `const IntimacyStorageException(this.message)` <a id="intimacystorageexception-new"></a>
- **种类：** `IntimacyStorageException` 的 const 构造函数
- **来源：** `lib/features/intimacy/services/intimacy_storage.dart`（第 18 行）
- **用途：** 创建携带用户可见消息、在 `intimacy_data.json` 存在但无法安全读取或写入时抛出的亲密存储异常。
- **输入：** `message`。
- **返回：** 新的 `IntimacyStorageException`。
- **副作用：** 无。
- **算法：** 平凡字段初始化 const 构造函数。
- **用法：**
  ```dart
  throw IntimacyStorageException('$_fileName is not valid JSON: $e');
  ```
  （`load`，第 65 行；第 67 行类似的 `'Failed to load $_fileName: $e'` 情形覆盖任何其他读取失败。）
- **备注：** 实现 `Exception`（不是 `Error`），因此意在捕获并显示给用户（如 `intimacy_page.dart` 的 `_loadError` 状态，它在文件不可读时也阻止 `_saveData()` 运行），而不是当作编程错误。

### `static Future<File> _getFile()` <a id="_getfile"></a>
- **种类：** `IntimacyStorage` 的私有静态方法
- **来源：** `lib/features/intimacy/services/intimacy_storage.dart`（第 39 行）
- **用途：** 解析应用数据目录内 `intimacy_data.json` 的 `File` 句柄。
- **输入：** 无。
- **返回：** `Future<File>`。
- **副作用：** 无直接（只构建路径；自己不碰磁盘）。
- **算法：** `appDir = await TodoStorage.getAppDir()`，然后 `File('${appDir.path}/$_fileName')`——亲密功能复用 Todo 的应用目录解析，而不是定义自己的。
- **用法：** 在 `load()`（第 51 行）、`_saveNow()`（第 91 行）和 `_migrateLegacyTimerHistory()`（第 110 行，定位旧文件的同级目录）顶部调用。
- **备注：** 依赖 `TodoStorage.getAppDir()` 意味着亲密存储没有需要在那改变时保持同步的独立目录解析逻辑。

### `static Future<IntimacyData?> load()` <a id="load"></a>
- **种类：** `IntimacyStorage` 的静态方法
- **来源：** `lib/features/intimacy/services/intimacy_storage.dart`（第 50 行）
- **用途：** 加载并解析 `intimacy_data.json`，然后迁移任何旧独立计时器历史文件进它。
- **输入：** 无。
- **返回：** `Future<IntimacyData?>` — 文件不存在时为 `null`。
- **副作用：** 读取 `intimacy_data.json`；可能也读取、合并并删除旧 `timer_history.json`，并把合并结果写回。
- **算法：**
  1. 经 `_getFile()` 解析文件；不存在时立即返回 `null`。
  2. 否则把它读为字符串，`jsonDecode` 为 `Map<String, dynamic>`，并构建 `IntimacyData.fromJson(json)`。
  3. 返回前把结果经 [`_migrateLegacyTimerHistory`](#_migratelegacytimerhistory)。
  4. `FormatException`（无效 JSON）被捕获并重新抛出为 `IntimacyStorageException('$_fileName is not valid JSON: $e')`；任何其他异常（如 `fromJson` 转换失败）重新抛出为 `IntimacyStorageException('Failed to load $_fileName: $e')`。
- **用法：**
  ```dart
  try {
    data = await IntimacyStorage.load();
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _loadError = e.toString();
      _loaded = true;
    });
    return;
  }
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:176-184`，`_loadData()`。）
- **备注：** 缺失文件和损坏文件刻意区分：缺失 -> `null`（"尚无数据"），损坏/不可读 -> 抛出的异常（UI 必须浮出的错误状态），因此损坏文件绝不静默当作空数据集。

### `static Future<void> save(IntimacyData data)` <a id="save"></a>
- **种类：** `IntimacyStorage` 的静态方法
- **来源：** `lib/features/intimacy/services/intimacy_storage.dart`（第 76 行）
- **用途：** 排队 `data` 的写入，确保重叠 `save` 调用绝不交错它们对 `intimacy_data.json` 的写入。
- **输入：** `data`。
- **返回：** 在此特定写入（含其在队列中的位置）完成时完成的 `Future<void>`。
- **副作用：** 最终写 `intimacy_data.json`（经 `_saveNow`）；修改静态 `_writeQueue` 字段。
- **算法：**
  1. 链到当前 `_writeQueue`：`next = _writeQueue.then((_) => _saveNow(data), onError: (_) => _saveNow(data))`，使 `_saveNow(data)` 无论先前排队写入成功还是失败都运行。
  2. 用 `next.catchError((_) {})`（吞错误的 `next` 版本）替换 `_writeQueue`，使一次失败保存绝不给后来的调用方永久污染队列。
  3. 返回 `next`（未吞的 future），使*此*调用方仍观察到自己 `_saveNow` 调用的任何错误。
- **用法：**
  ```dart
  await IntimacyStorage.save(
    IntimacyData(
      partners: _partners,
      toys: _toys,
      positions: _positions,
      records: _records,
      // ...
    ),
  );
  ```
  （`lib/features/intimacy/views/intimacy_page.dart:234-253`，`_saveData()`。）
- **备注：** 因为 `_writeQueue` 是每个调用共享的单个静态字段，并发 `save()` 调用严格按调用顺序串行化——`weight_storage.dart` 的 `save()` 使用的相同重叠写入者保护。

### `static Future<void> _saveNow(IntimacyData data)` <a id="_savenow"></a>
- **种类：** `IntimacyStorage` 的私有静态方法
- **来源：** `lib/features/intimacy/services/intimacy_storage.dart`（第 90 行）
- **用途：** 在调用方已在写队列中轮到它之后，执行一次 `data` 对 `intimacy_data.json` 的实际写入。
- **输入：** `data`。
- **返回：** `Future<void>`。
- **副作用：** 经 `DataFileSafety.writeValidatedDataJson` 通过校验临时文件写 `intimacy_data.json`。
- **算法：**
  1. 经 `_getFile()` 解析文件。
  2. `JsonPreservation.encodeForFile(file: file, next: data.toJson(), schema: dataFilePreservationSchemas[_fileName]!)`——读取当前磁盘内容并把其任何未知字段保留进 `data` 自己的序列化 JSON。
  3. `DataFileSafety.writeValidatedDataJson(file, jsonStr)`——校验编码 JSON，然后经同目录临时文件原子替换文件。
- **用法：** 只从 `save()` 经上面描述的写队列链调用。
- **备注：** `dataFilePreservationSchemas[_fileName]!` 断言 `'intimacy_data.json'` 存在模式——它确实存在，因此只有该共享模式映射被编辑丢弃条目时才会抛出。

### `static Future<IntimacyData> _migrateLegacyTimerHistory(IntimacyData data)` <a id="_migratelegacytimerhistory"></a>
- **种类：** `IntimacyStorage` 的私有静态方法
- **来源：** `lib/features/intimacy/services/intimacy_storage.dart`（第 106 行）
- **用途：** 把旧独立 `timer_history.json` 文件的条目折叠进 `IntimacyData.timerHistory`、持久化合并，然后删除旧文件。
- **输入：** `data` — 刚加载的 `IntimacyData`。
- **返回：** `Future<IntimacyData>` — 没有可迁移的东西或过程中任何东西抛出时 `data` 不变。
- **副作用：** 可能读取旧 `timer_history.json`、写合并后的 `intimacy_data.json`（经 `save`）并删除 `timer_history.json`。
- **算法：**
  1. 解析旧文件路径；不存在时原样返回 `data`。
  2. 把它作为 `List` 读取并 `jsonDecode`，经 [`TimerHistoryEntry.fromJson`](../models/intimacy_record.md#timerhistoryentry-fromjson) 解析每个条目。
  3. 按开始时间去重：构建既有 `data.timerHistory` 开始时间戳集合，只保留开始尚未存在的旧条目。
  4. 有剩余新条目时，重建 `timerHistory` 被它们扩展（显式复制其他每个字段）的新 `IntimacyData` 并 `await save(data)` 结果。
  5. 无条件删除旧文件（无论是否合并了新条目）并返回（可能更新的）`data`。
  6. 整个方法包在吞掉任何错误并原样返回原始 `data` 的 `try`/`catch` 中——迁移失败绝不阻塞正常加载。
- **用法：** 在 `load()` 末尾无条件调用（第 61 行）：`data = await _migrateLegacyTimerHistory(data);`。
- **备注：** 每次成功 `load()` 都运行，不只是一次——首次成功迁移后旧文件不再存在，因此第 1 步的存在性检查让之后每次调用都是廉价空操作。

## 相关页面

- [亲密](../../../../features/intimacy.md) — 此存储层支撑的功能，包括本文件 `IntimacyData.timerHistory` 迁移喂入的计时器/秒表会话持久化。
- [`intimacy_record.dart`](../models/intimacy_record.md) — `IntimacyData`、`TimerHistoryEntry` 和这里序列化/解析的其他每个模型。
- [数据格式](../../../../data-formats.md#intimacy--intimacy_datajson) — `intimacy_data.json` 的精确 JSON 形态。
- [`weight_storage.dart`](../../weight/services/weight_storage.md) — 本文件写队列/异常/原子写入模式镜像的近乎相同姊妹存储服务。

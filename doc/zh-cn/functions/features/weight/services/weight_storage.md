# lib/features/weight/services/weight_storage.dart

`weight_data.json` 的持久化层：经单个序列化写队列加载/保存 [`WeightData`](../models/weight_record.md)，既有文件存在但无法安全读取时抛出类型化异常，把实际"不破坏未知字段"和原子写加验证工作分别委托给 [`JsonPreservation`](../../../shared/utils/json_preservation.md#encodeforfile) 和 `DataFileSafety.writeValidatedDataJson`（`lib/shared/services/data_file_safety.dart`）。支撑的功能见 [体重](../../../../features/weight.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`WeightStorageException`（构造函数）](#weightstorageexception-new) | const 构造函数（`WeightStorageException`） | A | 创建带用户可见消息的体重存储异常。 |
| `WeightStorageException.toString` | 方法（`WeightStorageException`） | B | 把异常的消息作为其字符串表示返回。 |
| [`_getFile`](#_getfile) | 静态方法（`WeightStorage`） | A | 解析 `weight_data.json` 的磁盘路径。 |
| [`load`](#load) | 静态方法（`WeightStorage`） | A | 加载并解析 `weight_data.json`，不存在时为 `null`。 |
| [`save`](#save) | 静态方法（`WeightStorage`） | A | 排队一次 `WeightData` 写入，对并发保存序列化。 |
| [`_saveNow`](#_savenow) | 静态方法（`WeightStorage`） | A | 执行一次保留、验证、原子的 `WeightData` 写入。 |

`grep -c 'Purpose:' lib/features/weight/services/weight_storage.dart` 报告 6，与本文件全部六个真实声明精确匹配。未发现错附文档注释，也不存在未文档化真实声明。六个声明中五个是 Tier A：`WeightStorageException` 的构造函数是真实（虽然简单）模型风格构造函数，`_getFile`/`load`/`save`/`_saveNow` 按显式服务/IO Tier A 规则都执行真实 IO 或分支。`toString()` 是唯一 Tier B 声明——返回存储字段、自身无逻辑的平凡访问器，匹配"平凡 getter/setter"Tier B 桶。

## 文档

### `const WeightStorageException(this.message)` <a id="weightstorageexception-new"></a>
- **种类：** `WeightStorageException` 的 const 构造函数
- **来源：** `lib/features/weight/services/weight_storage.dart`（第 18 行）
- **用途：** 创建携带用户可见消息的体重存储异常，在 `weight_data.json` 存在但无法安全读或写时抛出。
- **输入：** `message`。
- **返回：** 新 `WeightStorageException`。
- **副作用：** 无。
- **算法：** 普通字段初始化 const 构造函数。
- **用法：**
  ```dart
  throw WeightStorageException('$fileName is not valid JSON: $e');
  ```
  （`load`，第 59 行；第 61 行类似 "Failed to load $fileName: $e" case 覆盖任何其他读取失败）。
- **备注：** 实现 `Exception`（而非 `Error`），因此意在捕获并显示给用户（如经体重页 `_loadError` 状态）而非当作编程错误。

### `static Future<File> _getFile()` <a id="_getfile"></a>
- **种类：** `WeightStorage` 的私有静态方法
- **来源：** `lib/features/weight/services/weight_storage.dart`（第 38 行）
- **用途：** 解析应用数据目录内 `weight_data.json` 的 `File` 句柄。
- **输入：** 无。
- **返回：** `Future<File>`。
- **副作用：** 无直接（自己不碰磁盘；只构建路径）。
- **算法：** `appDir = await TodoStorage.getAppDir()`，然后 `File('${appDir.path}/$fileName')`——体重功能复用 Todo 的应用目录解析而非定义自己的。
- **用法：** 在 `load()`（第 50 行）和 `_saveNow()`（第 85 行）两者顶部调用。
- **备注：** 依赖 `TodoStorage.getAppDir()` 获取应用目录意味着体重存储没有需在该变化时保持同步的独立目录解析逻辑。

### `static Future<WeightData?> load()` <a id="load"></a>
- **种类：** `WeightStorage` 的静态方法
- **来源：** `lib/features/weight/services/weight_storage.dart`（第 49 行）
- **用途：** 加载并解析 `weight_data.json`。
- **输入：** 无。
- **返回：** `Future<WeightData?>` — 文件不存在时 `null`。
- **副作用：** 从磁盘读取 `weight_data.json`。
- **算法：**
  1. 经 `_getFile()` 解析文件；不存在时立即返回 `null`。
  2. 否则作为字符串读取并 `jsonDecode` 为 `Map<String, dynamic>`，然后 `WeightData.fromJson(json)`。
  3. `FormatException`（无效 JSON）被捕获并作为 `WeightStorageException('$fileName is not valid JSON: $e')` 重新抛出。
  4. 任何其他异常（如 `fromJson` 转换失败）被捕获并作为 `WeightStorageException('Failed to load $fileName: $e')` 重新抛出。
- **用法：**
  ```dart
  try {
    data = await WeightStorage.load();
  } catch (e) {
    ReminderService.instance.updateWeightData(records: const []);
    if (!mounted) return;
    setState(() {
      _loadError = e.toString();
      _loaded = true;
    });
    return;
  }
  ```
  （`lib/features/weight/views/weight_page.dart`，第 100-113 行，`_loadData()`）。
- **备注：** 缺失文件和损坏文件刻意区分：缺失 → `null`（当作"尚无数据"），损坏/不可读 → 抛出异常（当作 UI 必须浮出的错误状态），因此损坏文件绝不被静默误当作空数据集。

### `static Future<void> save(WeightData data)` <a id="save"></a>
- **种类：** `WeightStorage` 的静态方法
- **来源：** `lib/features/weight/services/weight_storage.dart`（第 70 行）
- **用途：** 排队一次 `data` 写入，确保重叠 `save` 调用绝不交错写 `weight_data.json`。
- **输入：** `data`。
- **返回：** 此特定写入（含其在队列中的位置）完成时完成的 `Future<void>`。
- **副作用：** 最终写 `weight_data.json`（经 `_saveNow`）；修改静态 `_writeQueue` 字段。
- **算法：**
  1. 把此调用链接到当前 `_writeQueue`：`next = _writeQueue.then((_) => _saveNow(data), onError: (_) => _saveNow(data))`——使无论先前排队写入成功或失败 `_saveNow(data)` 都运行。
  2. 用 `next.catchError((_) {})`（吞掉自己错误的 `next` 版本）替换 `_writeQueue`，使失败保存绝不永久毒化后续调用者的队列。
  3. 把 `next`（未吞掉 future）返回给调用方，使*此*调用方仍观察到自己 `_saveNow` 调用的任何错误。
- **用法：**
  ```dart
  await WeightStorage.save(
    WeightData(height: _height, records: _records, /* ... */),
  );
  ```
  （`lib/features/weight/views/weight_page.dart`，第 161-172 行）。
- **备注：** 因为 `_writeQueue` 是每个调用共享的单个静态字段，并发 `save()` 调用严格按调用顺序序列化——第一个完成前开始的第二个 `save()` 总是在第一个的 `_saveNow` 之后运行自己的 `_saveNow`，绝不与它交错。这是 `test/storage_hardening_test.dart` 并发保存回归 case 覆盖的相同重叠写者保护。

### `static Future<void> _saveNow(WeightData data)` <a id="_savenow"></a>
- **种类：** `WeightStorage` 的私有静态方法
- **来源：** `lib/features/weight/services/weight_storage.dart`（第 84 行）
- **用途：** 在调用方已在写队列中轮到自己后，执行一次 `data` 到 `weight_data.json` 的实际写入。
- **输入：** `data`。
- **返回：** `Future<void>`。
- **副作用：** 经验证临时文件（经 `DataFileSafety.writeValidatedDataJson`）写 `weight_data.json`。
- **算法：**
  1. 经 `_getFile()` 解析文件。
  2. `JsonPreservation.encodeForFile(file: file, next: data.toJson(), schema: dataFilePreservationSchemas[fileName]!)`——读取当前磁盘内容并把其任何未知字段保留进 `data` 自己的序列化 JSON（见 [`json_preservation.dart`](../../../shared/utils/json_preservation.md#encodeforfile)）。
  3. `DataFileSafety.writeValidatedDataJson(file, jsonStr)`——验证编码 JSON，然后经同目录临时文件原子替换文件。
- **用法：** 只从 `save()` 经上面描述的写队列链调用。
- **备注：** `dataFilePreservationSchemas[fileName]!` 断言 `'weight_data.json'` 存在模式——它确实存在，定义为 `json_preservation.dart` 的 `_weightDataSchema`——因此只有那个共享映射曾被编辑丢条时才抛。

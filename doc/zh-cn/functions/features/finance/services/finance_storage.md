# lib/features/finance/services/finance_storage.dart

`finance_data.json` 的持久化层：`FinanceData` 模型（账户、分类、交易、订阅，加持久化的 UI 设置如订阅提醒时间和账户选择器偏好）和 `FinanceStorage`，它经单个串行化写队列加载/保存它——与 [`WeightStorage`](../../weight/services/weight_storage.md) 和 [`ExchangeRateStorage`](exchange_rate_storage.md) 相同的模式。`load()` 还在每次读取时运行一次性强制余额到调整交易迁移（[`migrateForcedBalances`](balance_util.md#migrateforcedbalances)），迁移改变任何东西时重新保存迁移结果。功能概览见 [财务](../../../../features/finance.md)，完整 `finance_data.json` 字段列表见 [数据格式](../../../../data-formats.md#finance--finance_datajson)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`FinanceData()`](#financedata-new) | 构造函数（`FinanceData`） | A | 打包每个财务记录列表加持久化设置。 |
| [`toJson`](#financedata-tojson) | 方法（`FinanceData`） | A | 把财务数据序列化为 JSON。 |
| [`FinanceData.fromJson`](#financedata-fromjson) | 工厂构造函数（`FinanceData`） | A | 从 JSON 解析财务数据。 |
| [`FinanceStorageException()`](#financestorageexception-new) | const 构造函数（`FinanceStorageException`） | A | 创建带用户可见消息的财务存储异常。 |
| `toString` | 方法（`FinanceStorageException`） | B | 返回异常消息作为其字符串表示。 |
| [`_getFile`](#getfile) | 静态方法（`FinanceStorage`） | A | 解析 `finance_data.json` 的磁盘路径。 |
| [`load`](#load) | 静态方法（`FinanceStorage`） | A | 加载、解析并强制余额迁移 `finance_data.json`。 |
| [`_migrateForcedBalances`](#migrateforcedbalances) | 静态方法（`FinanceStorage`） | A | 迁移改变任何东西时用迁移后的账户/交易重建 `FinanceData`。 |
| [`save`](#save) | 静态方法（`FinanceStorage`） | A | 排队财务数据写入，对照并发保存串行化。 |
| [`_saveNow`](#savenow) | 静态方法（`FinanceStorage`） | A | 进入写队列后持久化财务数据。 |
| [`_atomicWriteJson`](#atomicwritejson) | 静态方法（`FinanceStorage`） | A | 只在替换内容校验通过后替换 JSON 文件。 |

**对账：** `grep -c 'Purpose:' lib/features/finance/services/finance_storage.dart` 返回 11，与上面 11 行精确匹配——每个块都恰好位于其真实声明（构造函数、工厂构造函数、方法或静态方法）正上方；未发现错附在调用点语句上方。文件中的剩余普通字段（`FinanceData` 自己的字段、`FinanceStorageException.message`、`FinanceStorage._fileName`/`_writeQueue`）不带 `/// Purpose:` 块，与本代码库记录可调用成员而非普通数据的约定一致，它们都不构成未文档化的可调用声明。`toString()` 分类为 Tier B，作为无自身逻辑的平凡单行访问器（与 `weight_storage.md` 的 `WeightStorageException.toString` 中相同模式给出的分类相同）；其他每个声明分类为 Tier A——模型构造函数/序列化，或 `FinanceStorage` 静态方法中的真实 IO/分支逻辑。

## 文档

### `FinanceData({required List<Account> accounts, required List<Category> categories, required List<Transaction> transactions, List<Subscription> subscriptions = const [], String defaultCurrency = 'CNY', DateTime? settingsModifiedAt, int? subscriptionReminderHour, int? subscriptionReminderMinute, String? subscriptionSortMode, List<String>? subscriptionCustomOrder, Map<String, String> accountSortModes = const {}, Map<String, List<String>> accountCustomOrders = const {}, AccountPickerSettings accountPickerSettings = const AccountPickerSettings()})` <a id="financedata-new"></a>
- **种类：** `FinanceData` 的构造函数
- **来源：** `lib/features/finance/services/finance_storage.dart`（第 31 行）
- **用途：** 把每个财务记录列表（账户、分类、交易、订阅）与持久化的功能级设置打包——默认币种、订阅提醒时间/排序、逐账户排序模式/自定义顺序映射和交易账户选择器设置。
- **输入：** `accounts`、`categories`、`transactions` 必填；`subscriptions` 默认空；`defaultCurrency` 默认 `'CNY'`；每个设置字段可选/默认化。
- **返回：** 新的 `FinanceData`。
- **副作用：** 无。
- **算法：** 字段赋值构造函数；`settingsModifiedAt` 未提供时默认 Unix 纪元（`DateTime.fromMillisecondsSinceEpoch(0)`），不同于本功能大多数其他模型默认"现在"。
- **用法：**
  ```dart
  await FinanceStorage.save(
    FinanceData(
      accounts: _accounts,
      categories: _categories,
      transactions: _transactions,
      subscriptions: _subscriptions,
      defaultCurrency: _defaultCurrency,
      settingsModifiedAt: _settingsModifiedAt,
      subscriptionReminderHour: _subscriptionReminderHour,
      subscriptionReminderMinute: _subscriptionReminderMinute,
      subscriptionSortMode: _subscriptionSortMode,
      subscriptionCustomOrder: _subscriptionCustomOrder,
      accountSortModes: _accountSortModes,
      accountCustomOrders: _accountCustomOrders,
      accountPickerSettings: _accountPickerSettings,
    ),
  );
  ```
  （`lib/features/finance/views/finance_page.dart:201-217`，财务主页的保存全部处理器。）
- **备注：** 把 `settingsModifiedAt` 默认为纪元（而不是"现在"）意味着设置从未被显式触碰的新构造 `FinanceData` 与任何同步设置更新相比算作"更旧"——与三方合并的设置侧相关（见 [三方合并](../../../../algorithms/three-way-merge.md)）。

### `Map<String, dynamic> toJson()` <a id="financedata-tojson"></a>
- **种类：** `FinanceData` 的方法
- **来源：** `lib/features/finance/services/finance_storage.dart`（第 53 行）
- **用途：** 把完整财务数据集序列化为持久化为 `finance_data.json` 的 JSON。
- **输入：** 无。
- **返回：** `accounts`/`categories`/`transactions`/`subscriptions`/`defaultCurrency`/`settingsModifiedAt`/`accountPickerSettings` 总是存在、提醒/排序模式/自定义顺序设置字段只在非 null/非空时包含的映射。
- **副作用：** 无。
- **算法：** 映射字面量；每个记录列表经自己的 `toJson()` 映射；`accountPickerSettings` 经 [`AccountPickerSettings.toJson`](../models/finance.md#accountpickersettings-tojson) 嵌套。
- **用法：** 从 [`_saveNow`](#savenow) 调用，作为传给 `JsonPreservation.encodeForFile` 的 `next` 负载。
- **备注：** 无。

### `factory FinanceData.fromJson(Map<String, dynamic> json)` <a id="financedata-fromjson"></a>
- **种类：** `FinanceData` 的工厂构造函数
- **来源：** `lib/features/finance/services/finance_storage.dart`（第 79 行）
- **用途：** 从 `finance_data.json` 解析回完整财务数据集。
- **输入：** `json` — 解码映射。
- **返回：** 新的 `FinanceData`。
- **副作用：** 无。
- **算法：** 把每个记录列表键经其模型的 `fromJson` 映射，键缺席时默认 `[]`；`defaultCurrency` 默认 `'CNY'`；`settingsModifiedAt` 缺席时回退 Unix 纪元；`accountSortModes`/`accountCustomOrders` 从嵌套 `Map<String, dynamic>` 解析，带显式逐值转换；`accountPickerSettings` 经 [`AccountPickerSettings.fromJson`](../models/finance.md#accountpickersettings-fromjson)。
- **用法：**
  ```dart
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final data = FinanceData.fromJson(json);
  ```
  （`lib/features/finance/services/finance_storage.dart:174-175`，[`load`](#load) 内。）
- **备注：** 每个列表字段缺席时默认 `[]`（不是 `null`），因此部分填充或很旧的 `finance_data.json` 仍产出完全可用的 `FinanceData`，而不是需要下游 null 检查。

### `const FinanceStorageException(String message)` <a id="financestorageexception-new"></a>
- **种类：** `FinanceStorageException` 的 const 构造函数
- **来源：** `lib/features/finance/services/finance_storage.dart`（第 136 行）
- **用途：** 创建携带用户可见消息、在 `finance_data.json` 存在但无法安全读取或写入时抛出的异常。
- **输入：** `message`。
- **返回：** 新的 `FinanceStorageException`。
- **副作用：** 无。
- **算法：** 平凡字段初始化 const 构造函数。
- **用法：**
  ```dart
  throw FinanceStorageException('$_fileName is not valid JSON: $e');
  ```
  （`lib/features/finance/services/finance_storage.dart:185`，[`load`](#load) 内；类似的 `'Failed to load $_fileName: $e'` 情形覆盖任何其他读取失败，[`_atomicWriteJson`](#atomicwritejson) 为写侧校验失败抛出同类型。）
- **备注：** 实现 `Exception`，不是 `Error`——意在捕获并显示给用户（如经财务主页的 `_loadError` 状态），而不是当作编程错误。

### `static Future<File> _getFile()` <a id="getfile"></a>
- **种类：** `FinanceStorage` 的静态方法
- **来源：** `lib/features/finance/services/finance_storage.dart`（第 156 行）
- **用途：** 解析应用数据目录内 `finance_data.json` 的 `File` 句柄。
- **输入：** 无。
- **返回：** `Future<File>`。
- **副作用：** 无直接（只构建路径）。
- **算法：** `appDir = await TodoStorage.getAppDir()`，然后 `File('${appDir.path}/$_fileName')`。
- **用法：** 在 [`load`](#load) 和 [`_saveNow`](#savenow) 顶部调用。
- **备注：** 无。

### `static Future<FinanceData?> load()` <a id="load"></a>
- **种类：** `FinanceStorage` 的静态方法
- **来源：** `lib/features/finance/services/finance_storage.dart`（第 167 行）
- **用途：** 加载并解析 `finance_data.json`，运行强制余额迁移并在改变任何东西时持久化结果，使调用方总是看到已迁移的数据。
- **输入：** 无。
- **返回：** `Future<FinanceData?>` — 只在文件不存在时为 `null`；缺失文件绝不被混淆为损坏的，因为损坏文件会抛出。
- **副作用：** 读取 `finance_data.json`；经 [`ExchangeRateStorage.load()`](exchange_rate_storage.md#load) 读取汇率数据；迁移改变任何东西时可能再次写 `finance_data.json`（经 [`save`](#save)）。
- **算法：**
  1. 文件不存在时立即返回 `null`。
  2. 解码其 JSON 并经 [`FinanceData.fromJson`](#financedata-fromjson) 解析。
  3. 加载当前汇率数据并运行 [`_migrateForcedBalances`](#migrateforcedbalances)。
  4. 迁移没有变化（`identical(migrated, data)`）时返回按加载的 `data`。
  5. 否则尝试 `await save(migrated)`（吞掉任何保存失败）并无论重新保存是否成功都返回 `migrated`。
  6. `FormatException`（无效 JSON）被捕获并重新抛出为 `FinanceStorageException('$_fileName is not valid JSON: $e')`；任何其他异常重新抛出为 `FinanceStorageException('Failed to load $_fileName: $e')`。
- **用法：**
  ```dart
  data = await FinanceStorage.load();
  ```
  （`lib/features/finance/views/finance_page.dart:99`，财务主页的加载路径；`lib/shared/services/local_api_server.dart` 的 HTTP 处理器和 `lib/shared/services/reminder_service.dart` 的每小时订阅检查也使用。）
- **备注：** 缺失文件和损坏文件刻意区分，与 `WeightStorage.load` 相同模式——缺失意味着"尚无数据"（`null`），损坏/不可读是 UI 必须浮出的错误状态，绝不静默当作空数据集。

### `static FinanceData _migrateForcedBalances(FinanceData data, ExchangeRateData rateData)` <a id="migrateforcedbalances"></a>
- **种类：** `FinanceStorage` 的静态方法
- **来源：** `lib/features/finance/services/finance_storage.dart`（第 196 行）
- **用途：** 对一个 `FinanceData` 值运行 [`migrateForcedBalances`](balance_util.md#migrateforcedbalances)，改变任何东西时用迁移后的账户/交易和其他每个字段原样带过重建新 `FinanceData`。
- **输入：** `data`；`rateData`。
- **返回：** `FinanceData` — 迁移报告无变化时是 `data` 本身（同一对象，使 `identical()` 在 [`load`](#load) 中成功），否则是新值。
- **副作用：** 无直接（无自己的 IO）。
- **算法：**
  1. 调用 `migrateForcedBalances(accounts: data.accounts, transactions: data.transactions, rateData: rateData)`。
  2. `!migration.changed` 时原样返回 `data`（保留引用同一性）。
  3. 否则用 `migration.accounts`/`migration.transactions` 和其他每个字段（`categories`、`subscriptions`、`defaultCurrency`、`settingsModifiedAt`、全部设置字段）从 `data` 复制构造新 `FinanceData`。
- **用法：** 在 [`load`](#load) 内调用一次：`final migrated = _migrateForcedBalances(data, rateData);`。
- **备注：** 没有变化时返回完全相同的 `data` 对象（不只是相等的一个）正是让 `load()` 能用 `identical(migrated, data)` 做廉价"是否有变化"检查而不是深比较的东西。

### `static Future<void> save(FinanceData data)` <a id="save"></a>
- **种类：** `FinanceStorage` 的静态方法
- **来源：** `lib/features/finance/services/finance_storage.dart`（第 229 行）
- **用途：** 排队 `data` 的写入，确保重叠 `save` 调用绝不交错它们对 `finance_data.json` 的写入。
- **输入：** `data`。
- **返回：** 在此特定写入完成时完成的 `Future<void>`。
- **副作用：** 最终写 `finance_data.json`（经 `_saveNow`）；修改静态 `_writeQueue` 字段。
- **算法：** 与 [`ExchangeRateStorage.save`](exchange_rate_storage.md#save) 和 `WeightStorage.save` 相同的写入串行化模式：把 `_saveNow(data)` 链到 `_writeQueue` 上，无论先前写入结果如何，用吞错误的版本替换 `_writeQueue`，把未吞的 future 返回给此调用方。
- **用法：**
  ```dart
  await FinanceStorage.save(next);
  return _json({'success': true, ...});
  ```
  （`lib/shared/services/local_api_server.dart:794-796`，本地 HTTP API 的"创建交易"处理器；相同调用形态从 `finance_page.dart` 的设置/编辑流程和 `reminder_service.dart` 的订阅追赶保存。）
- **备注：** 并发 `save()` 调用严格按调用顺序串行化，与 `WeightStorage.save` 相同的保证。

### `static Future<void> _saveNow(FinanceData data)` <a id="savenow"></a>
- **种类：** `FinanceStorage` 的静态方法
- **来源：** `lib/features/finance/services/finance_storage.dart`（第 243 行）
- **用途：** 在调用方已在写队列中轮到它之后，执行一次 `data` 对 `finance_data.json` 的实际写入。
- **输入：** `data`。
- **返回：** `Future<void>`。
- **副作用：** 经 [`_atomicWriteJson`](#atomicwritejson) 写 `finance_data.json`。
- **算法：**
  1. 经 `_getFile()` 解析文件。
  2. 对 `'finance_data.json'` 注册的模式运行 `JsonPreservation.encodeForFile`，重新注入新版应用写入的任何未知字段。
  3. 经 [`_atomicWriteJson`](#atomicwritejson) 写入结果。
- **用法：** 只从 [`save`](#save) 的写队列链调用。
- **备注：** 与 `ExchangeRateStorage._saveNow` 不同，这无条件地总是运行未知字段保留——`finance_data.json` 没有需要特判的旧 pre-模式格式。

### `static Future<void> _atomicWriteJson(File file, String jsonStr)` <a id="atomicwritejson"></a>
- **种类：** `FinanceStorage` 的静态方法
- **来源：** `lib/features/finance/services/finance_storage.dart`（第 258 行）
- **用途：** 只在确认新内容和刚写的临时文件都能实际解码为有效 JSON 后替换 `finance_data.json`，拒绝写入任何会损坏文件的东西。
- **输入：** `file`；`jsonStr` — 候选新内容。
- **返回：** `Future<void>`。
- **副作用：** 缺失时创建父目录；写 `.tmp-<timestamp>` 临时文件并重命名覆盖 `file`；失败时删除临时文件。
- **算法：**
  1. 预先 `jsonDecode(jsonStr)`——解析失败时立即抛 `FinanceStorageException('Refusing to write invalid $_fileName: $e')`，完全不碰磁盘。
  2. 确保父目录存在。
  3. 把 `jsonStr` 写入唯一命名临时文件（`'${file.path}.tmp-<microsecondsSinceEpoch>'`），刷到磁盘。
  4. 重新读取并重新解码临时文件自己的内容作为第二遍校验；成功时 `rename` 到 `file.path`（底层文件系统上原子）。
  5. 重新读取/解码失败时，删除临时文件（尽力而为）并重新抛出——要么传播既有 `FinanceStorageException`，要么把任何其他错误包装为 `FinanceStorageException('Failed to write $_fileName safely: $e')`。
- **用法：** 在 [`_saveNow`](#savenow) 内调用一次：`await _atomicWriteJson(file, jsonStr);`。
- **备注：** 双重校验——写入前对字符串一次、写入后对临时文件一次——同时防护坏内存负载和文件系统级写入损坏，两者都绝不允许覆盖最后已知良好的 `finance_data.json`。

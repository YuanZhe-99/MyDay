# lib/features/todo/services/todo_storage.dart

`TodoStorage` 是**整个应用的中心存储/配置枢纽**，不只是 Todo——几乎所有其他功能存储服务都经 [`TodoStorage.getAppDir()`](#getappdir) 解析其应用目录，每个模块的配置风格设置（不只是 Todo 的）都经 [`readConfig()`](#readconfig)/[`writeConfig()`](#writeconfig) 读写。本文件定义两个持久化表面：`storage_config.json`，**总是**留在默认应用目录（无论任何自定义存储路径；自定义路径本身、亲密可见性、主题、语言区域、周起始日、托盘设置、备份设置、本地 API 设置、列表列数偏好、端侧 AI 开关——见 [端侧 AI](../../../../on-device-ai.md)），以及 `todo_data.json`（由 `TodoData` 包裹：每日模板、一次性任务、完成日志、评分日志、早间/完成提醒设置、任务排序模式/自定义顺序、`settingsModifiedAt`）。字段级概念描述见 [Todo](../../../../features/todo.md#storage) 和 [数据格式](../../../../data-formats.md#todo--todo_datajson)，本文件实现的全局写队列/原子写约定见 [架构](../../../../architecture.md)。`Task`/`DailyCompletionLog`/`DailyScoreLog` 来自 [`../models/task.dart`](../models/task.md)；保存经 [`JsonPreservation.encodeForFile`](../../../shared/utils/json_preservation.md#encodeforfile) 和 [`DataFileSafety.writeValidatedDataJson`](../../../shared/services/data_file_safety.md#writevalidateddatajson) 保留/验证。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`TodoData`（构造函数）](#tododata-new) | 构造函数（`TodoData`） | A | 创建 todo 数据实例，默认 `dailyScores`/`settingsModifiedAt`。 |
| [`TodoData.toJson`](#tojson) | 方法（`TodoData`） | A | 把整个 todo 文档序列化为 JSON 兼容映射。 |
| [`TodoData.fromJson`](#fromjson) | 工厂构造函数（`TodoData`） | A | 解析整个 todo 文档，迁移旧单提醒格式。 |
| [`TodoStorageException`（构造函数）](#todostorageexception-new) | const 构造函数（`TodoStorageException`） | A | 创建带用户可见消息的 todo 存储异常。 |
| `TodoStorageException.toString` | 方法（`TodoStorageException`） | B | 把异常的消息作为其字符串表示返回。 |
| [`_getDefaultAppDir`](#_getdefaultappdir) | 静态方法（`TodoStorage`） | A | 解析（需要时创建）默认 `Documents/MyDay` 应用目录。 |
| [`_getConfigFile`](#_getconfigfile) | 静态方法（`TodoStorage`） | A | 解析 `storage_config.json` 的 `File` 句柄。 |
| [`getConfigFile`](#getconfigfile) | 静态方法（`TodoStorage`） | A | 为其他服务公共访问配置文件。 |
| [`readConfig`](#readconfig) | 静态方法（`TodoStorage`） | A | 从磁盘读取原始配置 JSON。 |
| [`writeConfig`](#writeconfig) | 静态方法（`TodoStorage`） | A | 只把更改的键合并写入配置 JSON，串行化且原子；`null` 移除键；拒绝不可读文件。 |
| [`_enqueueConfig`](#_enqueueconfig) | 静态方法（`TodoStorage`） | A | 在每个更早的配置读-合并-写完成后运行一次配置读-合并-写。 |
| [`_readConfigForWrite`](#_readconfigforwrite) | 静态方法（`TodoStorage`） | A | 读取配置作为合并写入的基础，内容不可解析时抛出异常。 |
| [`_writeConfigFile`](#_writeconfigfile) | 静态方法（`TodoStorage`） | A | 用映射原子替换 `storage_config.json`。 |
| [`_loadConfig`](#_loadconfig) | 静态方法（`TodoStorage`） | A | 惰性加载并缓存来自磁盘的配置字段。 |
| [`_saveConfig`](#_saveconfig) | 静态方法（`TodoStorage`） | A | 把缓存配置字段的合并写入入队到配置队列。 |
| [`_saveConfigNow`](#_saveconfignow) | 静态方法（`TodoStorage`） | A | `_saveConfig` 的队列主体：把缓存字段合并进配置文件并原子写入。 |
| [`getIntimacyVisible`](#getintimacyvisible) | 静态方法（`TodoStorage`） | A | 获取持久化亲密可见状态。 |
| [`setIntimacyVisible`](#setintimacyvisible) | 静态方法（`TodoStorage`） | A | 设置并持久化亲密可见状态。 |
| [`getOnDeviceAiEnabled`](#getondeviceaienabled) | 静态方法（`TodoStorage`） | A | 读取用户是否开启了端侧 AI。 |
| [`setOnDeviceAiEnabled`](#setondeviceaienabled) | 静态方法（`TodoStorage`） | A | 持久化端侧 AI 开关。 |
| [`getOnDeviceAiPreferFast`](#getondeviceaipreferfast) | 静态方法（`TodoStorage`） | A | 读取是否偏好更快的端侧模型。 |
| [`setOnDeviceAiPreferFast`](#setondeviceaipreferfast) | 静态方法（`TodoStorage`） | A | 持久化更快模型偏好。 |
| [`getUiStyle`](#getuistyle) | 静态方法（`TodoStorage`） | A | 读取已存储的界面风格名称（1.6.0）。 |
| [`setUiStyle`](#setuistyle) | 静态方法（`TodoStorage`） | A | 持久化界面风格（1.6.0）。 |
| [`getNavPlacement`](#getnavplacement) | 静态方法（`TodoStorage`） | A | 读取已存储的导航栏位置（1.6.1）。 |
| [`setNavPlacement`](#setnavplacement) | 静态方法（`TodoStorage`） | A | 持久化导航栏位置（1.6.1）。 |
| [`getNavRailRight`](#getnavrailright) | 静态方法（`TodoStorage`） | A | 读取侧边导航栏是否位于右侧（1.6.1）。 |
| [`setNavRailRight`](#setnavrailright) | 静态方法（`TodoStorage`） | A | 持久化导航栏所在侧（1.6.1）。 |
| [`getThemeMode`](#getthememode) | 静态方法（`TodoStorage`） | A | 获取持久化主题模式。 |
| [`setThemeMode`](#setthememode) | 静态方法（`TodoStorage`） | A | 设置并持久化主题模式。 |
| [`getLocaleTag`](#getlocaletag) | 静态方法（`TodoStorage`） | A | 获取持久化语言区域标签。 |
| [`setLocaleTag`](#setlocaletag) | 静态方法（`TodoStorage`） | A | 设置并持久化语言区域标签。 |
| [`getWeekStartDay`](#getweekstartday) | 静态方法（`TodoStorage`） | A | 获取全局日历周起始日。 |
| [`setWeekStartDay`](#setweekstartday) | 静态方法（`TodoStorage`） | A | 更新全局日历周起始日。 |
| [`getAppDir`](#getappdir) | 静态方法（`TodoStorage`） | A | 解析活动应用数据目录（默认或自定义）。 |
| [`_getFile`](#_getfile) | 静态方法（`TodoStorage`） | A | 解析 `todo_data.json` 的 `File` 句柄。 |
| [`fileExists`](#fileexists) | 静态方法（`TodoStorage`） | A | 检查 `todo_data.json` 是否存在。 |
| [`load`](#load) | 静态方法（`TodoStorage`） | A | 加载并解析 `todo_data.json`。 |
| [`save`](#save) | 静态方法（`TodoStorage`） | A | 排队一次 `TodoData` 写入，对并发保存序列化。 |
| [`_saveNow`](#_savenow) | 静态方法（`TodoStorage`） | A | 执行一次保留、验证、原子的 `TodoData` 写入。 |
| [`getStoragePath`](#getstoragepath) | 静态方法（`TodoStorage`） | A | 获取活动存储目录路径供显示。 |
| [`setStoragePath`](#setstoragepath) | 静态方法（`TodoStorage`） | A | 更改自定义存储目录，需要时移动数据文件。 |
| [`getMinimizeToTray`](#getminimizetotray) | 静态方法（`TodoStorage`） | A | 获取持久化最小化到托盘设置。 |
| [`setMinimizeToTray`](#setminimizetotray) | 静态方法（`TodoStorage`） | A | 设置并持久化最小化到托盘设置。 |
| [`getCloseToTray`](#getclosetotray) | 静态方法（`TodoStorage`） | A | 获取持久化关闭到托盘设置。 |
| [`setCloseToTray`](#setclosetotray) | 静态方法（`TodoStorage`） | A | 设置并持久化关闭到托盘设置。 |
| [`_normalizeWeekStartDay`](#_normalizeweekstartday) | 静态方法（`TodoStorage`） | A | 返回有效持久化周起始日，无效值默认周一。 |
| `_getListColumns` | 静态方法（`TodoStorage`） | A | 读取某个列表界面持久化的列数偏好。 |
| `_setListColumns` | 静态方法（`TodoStorage`） | A | 经单键 `writeConfig` 补丁存储某个列表界面的列数偏好（越界值以 `null` 清除该键）。 |
| `getTodoSectionColumns` | 静态方法（`TodoStorage`） | A | 读取待办页的分区列数偏好。 |
| `setTodoSectionColumns` | 静态方法（`TodoStorage`） | A | 持久化待办页的分区列数偏好。 |
| `getFinanceListColumns` | 静态方法（`TodoStorage`） | A | 读取财务页的交易列数偏好。 |
| `setFinanceListColumns` | 静态方法（`TodoStorage`） | A | 持久化财务页的交易列数偏好。 |
| `getWeightListColumns` | 静态方法（`TodoStorage`） | A | 读取体重页的记录列数偏好。 |
| `setWeightListColumns` | 静态方法（`TodoStorage`） | A | 持久化体重页的记录列数偏好。 |
| `getIntimacyListColumns` | 静态方法（`TodoStorage`） | A | 读取亲密页的记录列数偏好。 |
| `setIntimacyListColumns` | 静态方法（`TodoStorage`） | A | 持久化亲密页的记录列数偏好。 |

`grep -c 'Purpose:' lib/features/todo/services/todo_storage.dart` 报告 57，与上面列出的全部五十七个真实声明精确匹配（v1.5.0 之前的 43 个，加四个端侧 AI 访问器，再加 v1.5.2 的四个配置队列辅助函数：`_enqueueConfig`、`_readConfigForWrite`、`_writeConfigFile`、`_saveConfigNow`，再加 v1.6.0 的 `getUiStyle`/`setUiStyle`，再加 v1.6.1 的四个导航访问器 `getNavPlacement`、`setNavPlacement`、`getNavRailRight`、`setNavRailRight`）。未发现错附文档注释——每个 `/// Purpose:` 块都恰好位于其文档化的真实构造函数/方法正上方——也不存在未文档化真实声明；唯一非 `Purpose:` 文档化的成员是普通字段（`_fileName`、`_customPath`、`_configLoaded`、`_intimacyVisible`、`_themeMode`、`_localeTag`、`_weekStartDay`、`_minimizeToTray`、`_closeToTray`、`_writeQueue`、`_configQueue`、`_dataFileNames`），它们是数据而非行为声明，正确排除在表格外。Tier 划分：56 个 Tier A / 1 个 Tier B。唯一 Tier B 行是 `TodoStorageException.toString`，返回存储 `message` 字段的平凡访问器，无逻辑（与 [`weight_storage.dart`](../../weight/services/weight_storage.md#weightstorageexception-new) 的 `WeightStorageException.toString` 相同模式）。每个其他声明都是 Tier A：`TodoData` 的构造函数/`toJson`/`fromJson` 和 `TodoStorageException` 的构造函数属于显式模型 Tier A 规则，每个 `TodoStorage` 静态方法执行真实配置缓存、文件路径解析或文件 IO——显式服务/IO Tier A 规则——即使个别方法体只有一两行（如 `_getConfigFile`、`getConfigFile`），与本仓库其他存储服务（如 `WeightStorage._getFile`）把简短 IO 邻近辅助归为 Tier A 而非平凡转发的方式一致。

## 文档

### `TodoData({required this.dailyTemplates, required this.oneTimeTasks, required this.dailyLog, DailyScoreLog? dailyScores, this.morningReminderHour, this.morningReminderMinute, this.completionReminderHour, this.completionReminderMinute, this.taskSortModes = const {}, this.taskCustomOrders = const {}, DateTime? settingsModifiedAt})` <a id="tododata-new"></a>
- **种类：** `TodoData` 的构造函数
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 35 行）
- **用途：** 创建整个 todo 文档——任务列表、日志、提醒设置、排序状态——把 `dailyScores` 默认空 `DailyScoreLog`、`settingsModifiedAt` 默认 Unix 纪元。
- **输入：** `dailyTemplates`、`oneTimeTasks`、`dailyLog`（必填）；可选 `dailyScores`、提醒时/分对、`taskSortModes`、`taskCustomOrders`、`settingsModifiedAt`。
- **返回：** 新 `TodoData`。
- **副作用：** 无。
- **算法：** `dailyScores ??= DailyScoreLog()`；`settingsModifiedAt ??= DateTime.fromMillisecondsSinceEpoch(0)`；每个其他字段直接赋值或字面量默认。
- **用法：**
  ```dart
  await TodoStorage.save(
    TodoData(
      dailyTemplates: _dailyTemplates,
      oneTimeTasks: _oneTimeTasks,
      dailyLog: _dailyLog,
      dailyScores: _dailyScores,
      morningReminderHour: _morningReminderTime?.hour,
      /* ... */
    ),
  );
  ```
  （`lib/features/todo/views/todo_page.dart`，`_saveData`，第 169-175 行）。
- **备注：** 把 `settingsModifiedAt` 默认纪元（非"现在"）意味着新创建 `TodoData` 与任何曾保存过设置的同伴进行最后写入者胜出设置合并时总是输——与 `WeightData` 等价字段相同的刻意"绝不覆盖真实先前值"约定。

### `Map<String, dynamic> toJson()` <a id="tojson"></a>
- **种类：** `TodoData` 的方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 56 行）
- **用途：** 把整个 todo 文档序列化进 `todo_data.json` 形态。
- **输入：** 无。
- **返回：** `dailyTemplates`/`oneTimeTasks`/`dailyLog`/`settingsModifiedAt` 总是存在的 `Map<String, dynamic>`，`dailyScores`/提醒时+分/`taskSortModes`/`taskCustomOrders` 只在非空/非 null 时出现。
- **副作用：** 无。
- **算法：** 映射字面量，两个任务列表上映射 `t.toJson()`、`dailyLog.toJson()`，每个可选字段的条件 `if (...)` 条目（`!dailyScores.isEmpty`、`!= null`、`.isNotEmpty`），使缺席设置被省略而非写为 `null`。
- **用法：** `data.toJson()` 作为 `next` 传给 [`_saveNow`](#_savenow) 中 `JsonPreservation.encodeForFile`。
- **备注：** 与 `Task.toJson`（总是写每个键）不同，这在可选字段为空/缺席时完全省略——从未设置早间提醒的应用从不写 `morningReminderHour`/`morningReminderMinute` 键。

### `factory TodoData.fromJson(Map<String, dynamic> json)` <a id="fromjson"></a>
- **种类：** `TodoData` 的工厂构造函数
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 78 行）
- **用途：** 从其持久化/同步 JSON 形态重建整个 todo 文档，把旧单提醒格式迁移到当前早间/完成拆分。
- **输入：** `json`。
- **返回：** 新 `TodoData`。
- **副作用：** 无。
- **算法：**
  1. 把 `json['dailyReminderHour']`/`['dailyReminderMinute']` 读作 `oldH`/`oldM`（迁移前单提醒键）。
  2. 经 `Task.fromJson` 解析 `dailyTemplates`/`oneTimeTasks`；存在时经 `DailyCompletionLog.fromJson` 否则新鲜 `DailyCompletionLog()` 解析 `dailyLog`；存在时经 `DailyScoreLog.fromJson` 否则新鲜 `DailyScoreLog()` 解析 `dailyScores`。
  3. `morningReminderHour`/`Minute` 从当前键读取，缺席回退 `oldH`/`oldM`——因此提醒拆分前保存的文件仍作为早间提醒浮出。
  4. `completionReminderHour`/`Minute` 无遗留回退（该功能晚于迁移需求）。
  5. `taskSortModes`/`taskCustomOrders` 存在时从其映射解析，否则 `const {}`。
  6. `settingsModifiedAt` 存在时解析否则 Unix 纪元。
- **用法：**
  ```dart
  data = await TodoStorage.load();
  ```
  它在 [`load`](#load) 内 `jsonDecode` 后内部做 `TodoData.fromJson(json)`。
- **备注：** 单提醒到早间提醒迁移是只读/隐式的——每次解析旧文件都发生，但没有任何东西把 `dailyReminderHour`/`Minute` 重写出文件；下次 `save()` 只是停止写那些遗留键（因为 `toJson` 不发出它们）。

### `const TodoStorageException(this.message)` <a id="todostorageexception-new"></a>
- **种类：** `TodoStorageException` 的 const 构造函数
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 129 行）
- **用途：** 创建携带用户可见消息的 todo 存储异常，在 `todo_data.json` 存在但无法安全读或写时抛出。
- **输入：** `message`。
- **返回：** 新 `TodoStorageException`。
- **副作用：** 无。
- **算法：** 普通字段初始化 const 构造函数。
- **用法：**
  ```dart
  throw TodoStorageException('$_fileName is not valid JSON: $e');
  ```
  （`load`，第 659 行；第 661 行类似 `'Failed to load $_fileName: $e'` case 覆盖任何其他读取失败）。
- **备注：** 实现 `Exception`（而非 `Error`），因此意在捕获并显示给用户——`todo_page.dart` 的 `_loadData()` 捕获它并把 `e.toString()` 存为 `_loadError`，它随后阻塞 `_saveData()` 直到下次成功重载（见 [`load`](#load) 的备注）。

### `String toString()`（Tier B — 仅表格行，无完整条目）

### `static Future<Directory> _getDefaultAppDir()` <a id="_getdefaultappdir"></a>
- **种类：** `TodoStorage` 的私有静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 175 行）
- **用途：** 解析（需要时创建）默认 `<平台应用文档目录>/MyDay` 目录。
- **输入：** 无。
- **返回：** `Future<Directory>`。
- **副作用：** 磁盘上尚不存在时创建 `MyDay` 目录。
- **算法：** `dir = await getApplicationDocumentsDirectory()`（来自 `path_provider`）；构建 `Directory('${dir.path}/MyDay')`；不存在时 `create(recursive: true)`。
- **用法：** 从 [`_getConfigFile`](#_getconfigfile)（总是）和 [`getAppDir`](#getappdir)（只在未设自定义路径时）调用。
- **备注：** 这是 `storage_config.json` 总是经它解析的唯一路径——它从不依赖 `_customPath`，正是让配置文件即使用户为数据文件选自定义存储路径也钉在默认位置的东西。

### `static Future<File> _getConfigFile()` <a id="_getconfigfile"></a>
- **种类：** `TodoStorage` 的私有静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 190 行）
- **用途：** 解析 `storage_config.json` 的 `File` 句柄，总是位于默认应用目录内。
- **输入：** 无。
- **返回：** `Future<File>`。
- **副作用：** 无直接（目录创建委托给 `_getDefaultAppDir`）。
- **算法：** `dir = await _getDefaultAppDir()`；`File('${dir.path}/$_configFileName')`。
- **用法：** 在本文件每个配置访问器顶部调用：[`getConfigFile`](#getconfigfile)、[`readConfig`](#readconfig)、[`writeConfig`](#writeconfig)、[`_loadConfig`](#_loadconfig)、[`_saveConfig`](#_saveconfig)。
- **备注：** 无。

### `static Future<File> getConfigFile()` <a id="getconfigfile"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 201 行）
- **用途：** 按其文档注释，公共暴露 `_getConfigFile()`，"供其他服务（如 `LocalApiServer`）"使用。
- **输入：** 无。
- **返回：** `Future<File>` — `getConfigFile() => _getConfigFile();` 转发的相同文件。
- **副作用：** 无。
- **算法：** 对 `_getConfigFile()` 的单行转发。
- **用法：** `lib/` 或 `test/` 中未找到任何调用点——包括 `local_api_server.dart`，其自身文档注释点名为预期消费者的模块。`LocalApiServer` 事实上经 `TodoStorage.readConfig()` 读取配置（如 `local_api_server.dart` 第 70 行）。
- **备注：** 相对其声明用途当前未使用/死代码；未来直接文件访问消费者会用这个而不是重复 `_getConfigFile` 的路径逻辑。

### `static Future<Map<String, dynamic>> readConfig()` <a id="readconfig"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 210 行）
- **用途：** 读取原始配置 JSON，供直接存储自己键的模块使用，而非经本文件缓存字段。
- **输入：** 无。
- **返回：** `Future<Map<String, dynamic>>` — 解析的配置，文件缺失或不可读时 `{}`。
- **副作用：** 从磁盘读取 `storage_config.json`。
- **算法：** 解析文件；存在时 `jsonDecode` 其内容并作为映射返回；任何异常（缺失文件、坏 JSON）被吞掉并改返回 `{}`。
- **用法：**
  ```dart
  final config = await TodoStorage.readConfig();
  _apiEnabled = config['apiEnabled'] as bool? ?? false;
  ```
  （`lib/features/settings/views/settings_page.dart`，`_loadApiSettings`，第 219-222 行）；也用于 `BackupService.loadSettings()`、`TrayService`、`ReminderService` 和 `local_api_server.dart` 各自的模块特定键。
- **备注：** 与 [`_loadConfig`](#_loadconfig) 不同，这从不缓存其结果——每次调用都从磁盘重新读取并重新解析文件。刻意宽松：不可读文件得到 `{}`，使读取方继续工作。写入方不得以那个空映射为基础；它们走 [`_readConfigForWrite`](#_readconfigforwrite)，文件存在但无法解析时它拒绝继续。

### `static Future<void> writeConfig(Map<String, dynamic> config)` <a id="writeconfig"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 229 行）
- **用途：** 把 `config` 的键合并写入 `storage_config.json` 而不破坏其他模块写的键；与所有其他配置写入串行化，并以原子方式写入。
- **输入：** `config` — **只含要更改的键**的部分映射（单键补丁）；键下的 `null` 值移除该键。调用方绝不能读出整份配置、修改后再传回：这种读-改-写周期正是 v1.5.2 队列所消除的丢失更新竞态。
- **返回：** `Future<void>`；既有文件不可读时以 `TodoStorageException` 失败。
- **副作用：** 读取然后原子重写 `storage_config.json`；使 `_loadConfig` 缓存失效（`_configLoaded = false`），使下次缓存字段读取重读文件。
- **算法：**
  1. 把 `config` 复制进局部 `patch`（使调用方之后的修改不会泄漏进已排队的工作）。
  2. 经 [`_enqueueConfig`](#_enqueueconfig) 入队，使其只在每个更早的配置写入完成后才运行。
  3. 在队列内，`existing = await _readConfigForWrite()` — 文件缺失或空白时 `{}`，存在但不是有效 JSON 对象时抛出 `TodoStorageException`。
  4. `existing.addAll(patch)`，然后 `existing.removeWhere((_, v) => v == null)` — 新值为 `null` 的任何键被完全删除，不写为 JSON `null`。
  5. [`_writeConfigFile`](#_writeconfigfile)`(existing)`（原子），然后设 `_configLoaded = false`。
- **用法：**
  ```dart
  await TodoStorage.writeConfig({
    'apiPort': newPort,
    'apiListenAddress': newAddr,
    'apiUsername': newUser.isEmpty ? null : newUser,
    'apiPassword': newPass.isEmpty ? null : newPass,
  });
  ```
  （`settings_page.dart`，第 380-385 行，保存本地 API 设置——注意依赖 `writeConfig` 的 null-移除-键行为的内联 `x.isEmpty ? null : x` 模式）。自 v1.5.2 起的单键调用方：`BodySectionView`（`bodyWeightSyncWarningDisabledKey`）和 `TimerPage`（`_keepScreenAwakeConfigKey`）传 `{key: value}`，取代此前"读整个映射、设一个键、写整个映射"的序列；`_setListColumns` 传 `{key: null}` 以清除默认值。
- **备注：** 因为这是读-合并-写（不是盲覆盖），它正是让 `BackupService` 的 `autoBackupEnabled`/`backupRetentionDays` 键和 Todo 自己的缓存字段（主题、语言区域等，经 `_saveConfig` 写）共存于同一文件、任一边无需预先知道对方键集的方式。拒绝不可解析的文件很重要，因为该文件持有 `storagePath` 和本地 API 凭据：静默从 `{}` 开始会用近乎空的映射替换它们。不得在 `_enqueueConfig` 的工作内部 await 它（会使队列死锁）；排队的工作改用私有辅助函数。

### `static Future<void> _enqueueConfig(Future<void> Function() op)` <a id="_enqueueconfig"></a>
- **种类：** `TodoStorage` 的私有静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 248 行）
- **用途：** 在每个更早的配置读-合并-写完成后，运行一次配置读-合并-写。
- **输入：** `op` — 要在队列内运行的工作。
- **返回：** 随 `op` 完成（或失败）的 `Future<void>`。
- **副作用：** 推进静态 `_configQueue` future。
- **算法：** `next = _configQueue.then((_) => op(), onError: (_) => op())` — 前一次失败不会阻止后续工作 — 然后 `_configQueue = next.catchError((_) {})`，使链本身从不持有错误，并把仍携带 `op` 结果或错误的 `next` 返回给调用方。
- **用法：** 只有 `writeConfig` 和 `_saveConfig` 调用它。
- **备注：** 形态与 `save` 为 `todo_data.json` 使用的 `_writeQueue` 相同，但是独立的队列，因此配置写入与 Todo 数据写入互不阻塞。`op` 必须调用私有辅助函数（`_readConfigForWrite`、`_writeConfigFile`、`_saveConfigNow`），绝不能调用 `writeConfig` 或 `_saveConfig`，否则队列死锁。

### `static Future<Map<String, dynamic>> _readConfigForWrite()` <a id="_readconfigforwrite"></a>
- **种类：** `TodoStorage` 的私有静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 260 行）
- **用途：** 读取当前配置，作为合并写入的基础。
- **输入：** 无。
- **返回：** `Future<Map<String, dynamic>>` — 文件缺失或空白时 `{}`。
- **副作用：** 读取 `storage_config.json`。
- **算法：** 文件缺失 → `{}`。读取失败 → `TodoStorageException('Failed to read ...')`。空白（仅空白字符）内容 → `{}`。`jsonDecode` 失败 → `TodoStorageException('... is not valid JSON; refusing to overwrite it ...')`。解码值不是 `Map<String, dynamic>` → `TodoStorageException('... is not a JSON object; refusing to overwrite it')`。否则返回解码出的映射。
- **用法：** `writeConfig` 和 `_saveConfigNow`，总是在配置队列内调用。
- **备注：** 宽松的公共 [`readConfig`](#readconfig) 的严格对应物：读取方对坏文件得到 `{}`，但写入方绝不能把"不可读"当作"为空"。

### `static Future<void> _writeConfigFile(Map<String, dynamic> config)` <a id="_writeconfigfile"></a>
- **种类：** `TodoStorage` 的私有静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 291 行）
- **用途：** 用 `config` 原子替换 `storage_config.json`。
- **输入：** `config` — 要持久化的完整映射。
- **返回：** `Future<void>`。
- **副作用：** 经临时文件写入 `storage_config.json`。
- **算法：** `DataFileSafety.atomicWriteString(file, jsonEncode(config))`。
- **用法：** `writeConfig` 和 `_saveConfigNow`，在配置队列内调用。
- **备注：** 写入中途崩溃不再可能留下被截断的配置文件（旧的盲 `file.writeAsString` 可能）。

### `static Future<void> _loadConfig()` <a id="_loadconfig"></a>
- **种类：** `TodoStorage` 的私有静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 302 行）
- **用途：** 惰性从 `storage_config.json` 填充此类的静态缓存字段（`_customPath`、`_intimacyVisible`、`_themeMode`、`_localeTag`、`_weekStartDay`、`_minimizeToTray`、`_closeToTray`），至多一次直到失效。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 首次调用（或 `_configLoaded` 被 `writeConfig` 失效后）读取 `storage_config.json`；修改静态缓存字段。
- **算法：** `_configLoaded` 已为 `true` 时立即返回。否则读取并 `jsonDecode` 配置文件（任何异常被吞掉忽略，保留默认值），填充每个缓存字段——`_intimacyVisible` 在 `intimacyVisible` 或遗留 `intimacyEverUnlocked` 键任一为 `true` 时为 `true`——经 [`_normalizeWeekStartDay`](#_normalizeweekstartday) 规范化 `_weekStartDay`，然后无条件设 `_configLoaded = true`（即使吞掉读取错误后）。
- **用法：** 在本文件每个缓存字段 getter/setter 顶部调用（`getIntimacyVisible`、`setIntimacyVisible`、`getThemeMode`、……、`getAppDir`、`getMinimizeToTray`、`getCloseToTray` 等），保证在读取或修改前缓存已填充。
- **备注：** 捕获的读取错误（损坏/缺失文件）仍设 `_configLoaded = true`，因此损坏配置文件被当作"加载一次，保留已在内存的默认值"而非每次调用重试。

### `static Future<void> _saveConfig()` <a id="_saveconfig"></a>
- **种类：** `TodoStorage` 的私有静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 335 行）
- **用途：** 把此类的缓存字段的写入入队到 `storage_config.json`，保留其他模块写的键（如 `BackupService` 的 `autoBackupEnabled`/`backupRetentionDays`）。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 读取然后原子重写 `storage_config.json`（在 [`_saveConfigNow`](#_saveconfignow) 中）。
- **算法：** `_enqueueConfig(_saveConfigNow)` — 整个读-合并-写在配置队列内运行，因此不会与 `writeConfig` 补丁交错。
- **用法：** 由本文件每个缓存字段 setter（`setIntimacyVisible`、`setThemeMode`、`setLocaleTag`、`setWeekStartDay`、`setMinimizeToTray`、`setCloseToTray`）和 [`setStoragePath`](#setstoragepath) 调用。
- **备注：** 宁可抛出 `TodoStorageException` 也不覆盖不可读的文件（经 `_readConfigForWrite`）。与 `writeConfig`（公共、任意键合并写）不同，`_saveConfig` 只写此类自己的已知键集。

### `static Future<void> _saveConfigNow()` <a id="_saveconfignow"></a>
- **种类：** `TodoStorage` 的私有静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 342 行）
- **用途：** 把缓存设置合并进 `storage_config.json`（`_saveConfig` 的队列主体）。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 读取并原子重写 `storage_config.json`。
- **算法：** `json = await _readConfigForWrite()`；对每个缓存字段，设其键（`_customPath`/`_themeMode`/`_localeTag`）或字段处于"默认"/`null` 值时完全移除键（如 `_weekStartDay == DateTime.monday` 移除 `weekStartDay` 键而非写 `1`）；总是无条件移除遗留 `intimacyEverUnlocked` 键（完全迁移进 `intimacyVisible`）；然后 `_writeConfigFile(json)`。
- **用法：** 只有 `_saveConfig` 在队列内调用它。
- **备注：** 它经文件往返（读然后写）纯粹为避免破坏其他模块的键，不是为合并调用方提供的数据。

### `static Future<bool> getIntimacyVisible()` <a id="getintimacyvisible"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 389 行）
- **用途：** 获取持久化亲密功能可见性。
- **输入：** 无。
- **返回：** `Future<bool>`。
- **副作用：** 可能触发首次 `_loadConfig()` 读取。
- **算法：** `await _loadConfig(); return _intimacyVisible;`。
- **用法：**
  ```dart
  final visible = await TodoStorage.getIntimacyVisible();
  state = IntimacyVisibility(visible: visible);
  ```
  （`lib/shared/providers/intimacy_visibility.dart`，`_loadPersistedState`，第 46-47 行）。
- **备注：** 无。

### `static Future<void> setIntimacyVisible(bool value)` <a id="setintimacyvisible"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 400 行）
- **用途：** 设置并持久化亲密功能可见性。
- **输入：** `value`。
- **返回：** `Future<void>`。
- **副作用：** 值实际变化时写 `storage_config.json`。
- **算法：** `await _loadConfig()`；`value == _intimacyVisible` 时提前返回（不写）；否则更新缓存并调用 `_saveConfig()`。
- **用法：**
  ```dart
  void setVisible(bool visible) {
    state = state.copyWith(visible: visible);
    TodoStorage.setIntimacyVisible(visible);
  }
  ```
  （`intimacy_visibility.dart`，第 56-59 行）。
- **备注：** 无变化的提前返回避免每次无操作切换不必要的磁盘写，但注意上面调用未被其调用方 `await`——从提供者角度看写入即发即忘发生。

### `static Future<bool> getOnDeviceAiEnabled()` <a id="getondeviceaienabled"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 412 行）
- **用途：** 读取用户是否开启了端侧 AI。
- **输入：** 无。
- **返回：** `Future<bool>`——仅当 `onDeviceAiEnabled` 键为 JSON `true` 时为 `true`；键缺失或为其他值时为 `false`。
- **副作用：** 读取 `storage_config.json`（经 [`readConfig`](#readconfig)）。
- **算法：** `(await readConfig())['onDeviceAiEnabled'] == true`。
- **用法：** `final onDeviceAiEnabled = await TodoStorage.getOnDeviceAiEnabled();`（`lib/shared/providers/app_settings.dart`，`_loadPersisted`，第 44 行）。
- **备注：** 设备本地、从不同步；默认关闭（v1.5.0）。与上面的缓存字段不同，它走不缓存的 `readConfig`，因此从不触碰 `_loadConfig` 缓存。见 [端侧 AI](../../../../on-device-ai.md) 和 [`app_settings.dart`](../../../shared/providers/app_settings.md#_loadpersisted)。

### `static Future<void> setOnDeviceAiEnabled(bool enabled)` <a id="setondeviceaienabled"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 420 行）
- **用途：** 持久化端侧 AI 开关。
- **输入：** `enabled`。
- **返回：** `Future<void>`。
- **副作用：** 经 [`writeConfig`](#writeconfig) 合并写入 `storage_config.json`，这也会使 `_loadConfig` 缓存失效。
- **算法：** `writeConfig({'onDeviceAiEnabled': enabled ? true : null})`——`false` 映射为 `null`，`writeConfig` 会把它变成移除该键。
- **用法：** `TodoStorage.setOnDeviceAiEnabled(enabled);`（`app_settings.dart`，[`setOnDeviceAiEnabled`](../../../shared/providers/app_settings.md#setondeviceaienabled)，第 173 行）。
- **备注：** 仅在为 `true` 时存储，因此从未选择开启的设备根本没有该键。

### `static Future<bool> getOnDeviceAiPreferFast()` <a id="getondeviceaipreferfast"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 428 行）
- **用途：** 读取是否偏好更快的端侧模型。
- **输入：** 无。
- **返回：** `Future<bool>`——`onDeviceAiPreferFast` 键缺失时为 `false`。
- **副作用：** 读取 `storage_config.json`（经 [`readConfig`](#readconfig)）。
- **算法：** `(await readConfig())['onDeviceAiPreferFast'] == true`。
- **用法：** `final onDeviceAiPreferFast = await TodoStorage.getOnDeviceAiPreferFast();`（`app_settings.dart`，`_loadPersisted`，第 45 行）。
- **备注：** 只在 Android 上有效果，那里 AICore 可以提供完整模型和快速模型；设备本地。

### `static Future<void> setOnDeviceAiPreferFast(bool enabled)` <a id="setondeviceaipreferfast"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 436 行）
- **用途：** 持久化更快模型偏好。
- **输入：** `enabled`。
- **返回：** `Future<void>`。
- **副作用：** 经 [`writeConfig`](#writeconfig) 合并写入 `storage_config.json`。
- **算法：** `writeConfig({'onDeviceAiPreferFast': enabled ? true : null})`。
- **用法：** `TodoStorage.setOnDeviceAiPreferFast(enabled);`（`app_settings.dart`，[`setOnDeviceAiPreferFast`](../../../shared/providers/app_settings.md#setondeviceaipreferfast)，第 184 行）。
- **备注：** 仅在为 `true` 时存储；`false` 移除该键。

### `static Future<String?> getUiStyle()` <a id="getuistyle"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`
- **用途：** 返回已存储的界面风格名称（1.6.0）。
- **输入：** 无。
- **返回：** `Future<String?>`——`'material3'`，或 null 表示默认的 Expressive 风格。
- **副作用：** 通过 [`readConfig`](#readconfig) 读取 `storage_config.json`。
- **备注：** 与所有配置读取器一样宽容。MyAnime 已被取代的 1.7.0 键 `classicNavBar` 从未在 MyDay 发布过，因此只读取 `uiStyle`。

### `static Future<void> setUiStyle(String? name)` <a id="setuistyle"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`
- **用途：** 持久化界面风格（1.6.0）。
- **输入：** `name`——`'material3'`，或 null 表示默认的 Expressive 风格。
- **返回：** `Future<void>`。
- **副作用：** 通过 [`writeConfig`](#writeconfig) 合并写入 `storage_config.json`。
- **算法：** `writeConfig({'uiStyle': name == 'material3' ? 'material3' : null})`。
- **备注：** 只存储非默认的 Material 3 风格，即 `uiStyle: "material3"`；null 会移除该键。

### `static Future<String?> getNavPlacement()` <a id="getnavplacement"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`
- **用途：** 返回已存储的导航栏位置（1.6.1）。
- **输入：** 无。
- **返回：** `Future<String?>`——`'sideOnWide'`、`'side'`，或 null 表示默认（任何窗口都用底栏）。
- **副作用：** 通过 [`readConfig`](#readconfig) 读取 `storage_config.json`。
- **备注：** 仅限本设备，不同步；两种界面风格都适用。未知值按默认读取。

### `static Future<void> setNavPlacement(String? name)` <a id="setnavplacement"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`
- **用途：** 持久化导航栏位置（1.6.1）。
- **输入：** `name`——`'sideOnWide'`、`'side'`，或 null 表示底部。
- **返回：** `Future<void>`。
- **副作用：** 通过 [`writeConfig`](#writeconfig) 合并写入 `storage_config.json`。
- **算法：** `writeConfig({'navPlacement': name 为 'sideOnWide' 或 'side' 时取 name，否则 null})`。
- **备注：** 只存储两个非默认值，即 `navPlacement: "sideOnWide"` 或 `"side"`；默认（底部）会移除该键。

### `static Future<bool> getNavRailRight()` <a id="getnavrailright"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`
- **用途：** 返回侧边导航栏是否位于窗口右侧（1.6.1）。
- **输入：** 无。
- **返回：** `Future<bool>`——默认 false（左侧）。
- **副作用：** 通过 [`readConfig`](#readconfig) 读取 `storage_config.json`。
- **备注：** 仅限本设备，不同步。只要显示侧边导航栏，两种界面风格都适用。

### `static Future<void> setNavRailRight(bool right)` <a id="setnavrailright"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`
- **用途：** 持久化侧边导航栏所在的一侧（1.6.1）。
- **输入：** `right`。
- **返回：** `Future<void>`。
- **副作用：** 通过 [`writeConfig`](#writeconfig) 合并写入 `storage_config.json`。
- **算法：** `writeConfig({'navRailRight': right ? true : null})`。
- **备注：** 只存储右侧，即 `navRailRight: true`；左侧会移除该键。

### `static Future<String?> getThemeMode()` <a id="getthememode"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 445 行）
- **用途：** 获取持久化主题模式字符串。
- **输入：** 无。
- **返回：** `Future<String?>` — `null` 意为"跟随系统"。
- **副作用：** 可能触发首次 `_loadConfig()` 读取。
- **算法：** `await _loadConfig(); return _themeMode;`。
- **用法：** `final modeStr = await TodoStorage.getThemeMode();`（`lib/shared/providers/app_settings.dart`，`_loadPersisted`，第 37 行）。
- **备注：** 无。

### `static Future<void> setThemeMode(String? mode)` <a id="setthememode"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 456 行）
- **用途：** 设置并持久化主题模式字符串。
- **输入：** `mode` — `'light'`/`'dark'`/`null`（系统）。
- **返回：** `Future<void>`。
- **副作用：** 无条件写 `storage_config.json`（不像 `setIntimacyVisible` 那样无变化提前返回）。
- **算法：** `await _loadConfig(); _themeMode = mode; await _saveConfig();`。
- **用法：**
  ```dart
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => null,
    };
    TodoStorage.setThemeMode(str);
  }
  ```
  （`app_settings.dart`，第 83-91 行）。
- **备注：** 即使 `mode` 与缓存值相同也总是写——不像 `setIntimacyVisible` 的受保护写。

### `static Future<String?> getLocaleTag()` <a id="getlocaletag"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 468 行）
- **用途：** 获取持久化语言区域标签。
- **输入：** 无。
- **返回：** `Future<String?>` — 如 `'en'`、`'zh'`、`'zh_TW'`、`'ja'`，或系统的 `null`。
- **副作用：** 可能触发首次 `_loadConfig()` 读取。
- **算法：** `await _loadConfig(); return _localeTag;`。
- **用法：** `final localeTag = await TodoStorage.getLocaleTag();`（`app_settings.dart`，第 38 行）。
- **备注：** 无。

### `static Future<void> setLocaleTag(String? tag)` <a id="setlocaletag"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 479 行）
- **用途：** 设置并持久化语言区域标签。
- **输入：** `tag`。
- **返回：** `Future<void>`。
- **副作用：** 无条件写 `storage_config.json`。
- **算法：** `await _loadConfig(); _localeTag = tag; await _saveConfig();`。
- **用法：**
  ```dart
  if (locale == null) {
    TodoStorage.setLocaleTag(null);
  } else {
    final tag = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    TodoStorage.setLocaleTag(tag);
  }
  ```
  （`app_settings.dart`，`setLocale`，第 103-110 行）。
- **备注：** 无。

### `static Future<int> getWeekStartDay()` <a id="getweekstartday"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 491 行）
- **用途：** 获取应用每个日历共享的全局日历周起始日。
- **输入：** 无。
- **返回：** `Future<int>` — Dart 的周一=1 到周日=7 编号。
- **副作用：** 可能触发首次 `_loadConfig()` 读取。
- **算法：** `await _loadConfig(); return _weekStartDay;`。
- **用法：** `final weekStartDay = await TodoStorage.getWeekStartDay();`（`lib/shared/widgets/app_date_picker.dart`，第 20 和 46 行；也 `app_settings.dart` 第 39 行）。
- **备注：** `_loadConfig` 从磁盘读取时已经 `_normalizeWeekStartDay` 规范化此值，因此此 getter 从不需要重新验证。

### `static Future<void> setWeekStartDay(int weekday)` <a id="setweekstartday"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 502 行）
- **用途：** 更新全局日历周起始日。
- **输入：** `weekday`。
- **返回：** `Future<void>`。
- **副作用：** 规范化值实际变化时才写 `storage_config.json`。
- **算法：** `await _loadConfig()`；经 `_normalizeWeekStartDay` 规范化 `weekday`；等于当前缓存值则提前返回（不写）；否则更新缓存并调用 `_saveConfig()`。
- **用法：**
  ```dart
  void setWeekStartDay(int weekday) {
    final normalized = normalizeWeekStartDay(weekday);
    state = state.copyWith(weekStartDay: normalized);
    TodoStorage.setWeekStartDay(normalized);
  }
  ```
  （`app_settings.dart`，第 118-122 行）。
- **备注：** 无效值（周一..周日外）静默规范化为周一而非拒绝——见 [`_normalizeWeekStartDay`](#_normalizeweekstartday)。

### `static Future<Directory> getAppDir()` <a id="getappdir"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 610 行）
- **用途：** 解析数据文件实际存储的目录——设置了自定义路径则自定义路径，否则默认 `Documents/MyDay` 目录。
- **输入：** 无。
- **返回：** `Future<Directory>`。
- **副作用：** 磁盘上尚不存在时创建自定义目录（否则落入 `_getDefaultAppDir` 自己的创建）。
- **算法：** `await _loadConfig()`；`_customPath` 已设且非空时构建/创建那个 `Directory` 并返回；否则返回 `_getDefaultAppDir()`。
- **用法：** 这是本文件使用最广的入口点——几乎所有其他存储服务都经它解析目录，如 `final appDir = await TodoStorage.getAppDir();` 在 `lib/features/weight/services/weight_storage.dart`（第 39 行）、`lib/features/intimacy/services/intimacy_storage.dart`（第 40、110 行）、`lib/features/finance/services/finance_storage.dart`（第 186 行）、`lib/features/finance/services/exchange_rate_storage.dart`（第 149 行）、`lib/shared/services/image_service.dart`、`import_export_service.dart` 和 `webdav_service.dart`（各多个调用点），加它自己的 [`_getFile`](#_getfile)。
- **备注：** 这正是 `TodoStorage` 是"整个应用的中心存储/配置枢纽"而非只是 Todo 功能自己的存储类的架构原因——每个其他功能的数据文件都住在此方法解析的任何目录下。

### `static Future<File> _getFile()` <a id="_getfile"></a>
- **种类：** `TodoStorage` 的私有静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 627 行）
- **用途：** 在活动应用目录内解析 `todo_data.json` 的 `File` 句柄。
- **输入：** 无。
- **返回：** `Future<File>`。
- **副作用：** 无直接（目录解析/创建委托给 `getAppDir`）。
- **算法：** `appDir = await getAppDir()`；`File('${appDir.path}/$_fileName')`。
- **用法：** 从 [`fileExists`](#fileexists)、[`load`](#load) 和 [`_saveNow`](#_savenow) 调用。
- **备注：** 无。

### `static Future<bool> fileExists()` <a id="fileexists"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 638 行）
- **用途：** 检查 `todo_data.json` 是否完全存在，不尝试解析。
- **输入：** 无。
- **返回：** `Future<bool>`。
- **副作用：** 无（文件系统存在性检查）。
- **算法：** `file = await _getFile(); return file.exists();`。
- **用法：** `lib/` 或 `test/` 中未找到任何调用点——需要区分"无文件"与"损坏文件"的调用方改为直接调用 [`load`](#load) 并依赖其 `null` 返回/抛出异常区分。
- **备注：** 当前未使用；保留为不需要解析的轻量存在性检查。

### `static Future<TodoData?> load()` <a id="load"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 650 行）
- **用途：** 加载并解析 `todo_data.json`，只在文件不存在时返回 `null`。
- **输入：** 无。
- **返回：** `Future<TodoData?>` — 缺失时 `null`；否则解析 `TodoData` 或抛出 `TodoStorageException`。
- **副作用：** 从磁盘读取 `todo_data.json`。
- **算法：**
  1. 经 `_getFile()` 解析文件；不存在时立即返回 `null`。
  2. 否则作为字符串读取、`jsonDecode` 它并 `TodoData.fromJson(json)`。
  3. `FormatException`（无效 JSON）被捕获并作为 `TodoStorageException('$_fileName is not valid JSON: $e')` 重新抛出。
  4. 任何其他异常（如 `fromJson` 转换失败）被捕获并作为 `TodoStorageException('Failed to load $_fileName: $e')` 重新抛出。
- **用法：**
  ```dart
  try {
    data = await TodoStorage.load();
  } catch (e) {
    ReminderService.instance.updateData(
      dailyTemplates: const [],
      oneTimeTasks: const [],
      dailyLog: DailyCompletionLog(),
    );
    if (!mounted) return;
    setState(() {
      _loadError = e.toString();
      _loaded = true;
    });
    return;
  }
  ```
  （`todo_page.dart`，`_loadData`，第 101-115 行）；也从 `local_api_server.dart`（许多读/改/存处理器）和 `reminder_service.dart` 调用。
- **备注：** 缺失与损坏刻意区分——缺失返回 `null`（"尚无数据"），损坏/不可读抛出（UI 必须浮出的错误状态）——因此损坏文件绝不被静默当作空数据集。`todo_page.dart` 额外用抛出的 `_loadError` 经自己的 `_saveData()` 守卫阻塞 [`save`](#save) 调用直到下次成功重载。

### `static Future<void> save(TodoData data)` <a id="save"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 671 行）
- **用途：** 排队一次 `data` 写入，确保重叠 `save` 调用绝不交错写 `todo_data.json`。
- **输入：** `data`。
- **返回：** 此特定写入（含其在队列中的位置）完成时完成的 `Future<void>`。
- **副作用：** 最终写 `todo_data.json`（经 `_saveNow`）；修改静态 `_writeQueue` 字段。
- **算法：**
  1. 链接到当前 `_writeQueue`：`next = _writeQueue.then((_) => _saveNow(data), onError: (_) => _saveNow(data))`——使无论先前排队写入成功或失败 `_saveNow(data)` 都运行。
  2. 用 `next.catchError((_) {})`（`next` 的错误吞掉视图）替换 `_writeQueue`，使一次失败保存绝不永久毒化后续调用者的队列。
  3. 返回 `next`（未吞掉 future），使*此*调用方仍观察到自己 `_saveNow` 调用的任何错误。
- **用法：**
  ```dart
  await TodoStorage.save(
    TodoData(dailyTemplates: _dailyTemplates, oneTimeTasks: _oneTimeTasks, /* ... */),
  );
  ```
  （`todo_page.dart`，`_saveData`，第 169-183 行）；也在任何 REST 驱动修改后的 `local_api_server.dart` 中调用。
- **备注：** 因为 `_writeQueue` 是单个静态字段，应用中任何地方的并发 `save()` 调用（UI 和本地 REST API 都一样）严格按调用顺序序列化——AGENTS.md 为每个模块数据文件存储文档化的相同重叠写者保护。

### `static Future<void> _saveNow(TodoData data)` <a id="_savenow"></a>
- **种类：** `TodoStorage` 的私有静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 685 行）
- **用途：** 在调用方已在写队列中轮到自己后，执行一次 `data` 到 `todo_data.json` 的实际写入。
- **输入：** `data`。
- **返回：** `Future<void>`。
- **副作用：** 经验证临时文件写 `todo_data.json`。
- **算法：**
  1. 经 `_getFile()` 解析文件。
  2. `JsonPreservation.encodeForFile(file: file, next: data.toJson(), schema: dataFilePreservationSchemas[_fileName]!)`——读取当前磁盘内容并把任何未知字段保留进 `data` 的序列化 JSON（见 [`json_preservation.dart`](../../../shared/utils/json_preservation.md#encodeforfile)）。
  3. `DataFileSafety.writeValidatedDataJson(file, jsonStr)`——验证编码 JSON，然后经同目录临时文件原子替换文件（见 [`data_file_safety.dart`](../../../shared/services/data_file_safety.md#writevalidateddatajson)）。
- **用法：** 只从 `save()` 经上面描述的写队列链调用。
- **备注：** `dataFilePreservationSchemas[_fileName]!` 断言 `'todo_data.json'` 存在模式——它确实存在，定义为 `json_preservation.dart` 的 `_todoDataSchema`——因此只有那个共享映射曾被编辑丢条时才抛。

### `static Future<String> getStoragePath()` <a id="getstoragepath"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 701 行）
- **用途：** 获取活动存储目录路径，供设置显示。
- **输入：** 无。
- **返回：** `Future<String>`。
- **副作用：** 无直接（委托给可能创建目录的 `getAppDir`）。
- **算法：** `appDir = await getAppDir(); return appDir.path;`。
- **用法：** `final path = await TodoStorage.getStoragePath();`（`lib/features/settings/views/settings_page.dart`，`_loadStoragePath`，第 142 行）。
- **备注：** 无。

### `static Future<bool> setStoragePath(String? newPath)` <a id="setstoragepath"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 723 行）
- **用途：** 更改自定义存储目录，把应用已知数据文件移入（或采用已在其中的），使既有数据不丢失或不重复。
- **输入：** `newPath` — `null` 重置回默认位置。
- **返回：** `Future<bool>` — 成功 `true`，任何东西抛出 `false`。
- **副作用：** 经 `_saveConfig()` 持久化 `_customPath`；可能创建新目录；可能把 `_dataFileNames` 每个（`todo_data.json`、`finance_data.json`、`exchange_rates.json`、`intimacy_data.json`、`weight_data.json`、`webdav_config.json`）从旧目录复制-然后-删除到新目录。
- **算法：**
  1. 经 `getAppDir()` 解析 `oldDir`（改任何东西前）。
  2. 设 `_customPath = newPath` 并经 `_saveConfig()` 持久化。
  3. 再次经 `getAppDir()` 解析 `newDir`；与 `oldDir` 相同路径时立即返回 `true`（无需文件移动）。
  4. 对 `_dataFileNames` 每个名称：文件已在新位置存在时保持原样（采用那里的）；否则存在于旧位置时 `copy` 然后 `delete` 它（移动语义）。
  5. 过程中任何地方任何异常被捕获并转为 `false` 返回。
- **用法：**
  ```dart
  final ok = await TodoStorage.setStoragePath(pathToSet);
  if (ok) {
    await _loadStoragePath();
    /* show settingsResetDefaultLocation or settingsStoragePathUpdated snackbar */
  }
  ```
  （`settings_page.dart`，第 928-943 行）。
- **备注：** `storage_config.json` 本身从不在 `_dataFileNames` 中、绝不被移动——它总是留在默认应用目录（按 `_getConfigFile`/`_getDefaultAppDir`），即使为其他一切设置了自定义存储路径。`images/`、`backups/` 和 `.sync_base/` 等目录也不由此文件列表移动（按 AGENTS.md）。

### `static Future<bool> getMinimizeToTray()` <a id="getminimizetotray"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 750 行）
- **用途：** 获取持久化"最小化到托盘"设置。
- **输入：** 无。
- **返回：** `Future<bool>`。
- **副作用：** 可能触发首次 `_loadConfig()` 读取。
- **算法：** `await _loadConfig(); return _minimizeToTray;`。
- **用法：**
  ```dart
  _minimizeToTray = await TodoStorage.getMinimizeToTray();
  _closeToTray = await TodoStorage.getCloseToTray();
  ```
  （`lib/shared/services/tray_service.dart`，`init`，第 51-52 行）。
- **备注：** 无。

### `static Future<void> setMinimizeToTray(bool value)` <a id="setminimizetotray"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 760 行）
- **用途：** 设置并持久化"最小化到托盘"设置。
- **输入：** `value`。
- **返回：** `Future<void>`。
- **副作用：** 无条件写 `storage_config.json`。
- **算法：** `await _loadConfig(); _minimizeToTray = value; await _saveConfig();`。
- **用法：**
  ```dart
  Future<void> setMinimizeToTray(bool value) async {
    _minimizeToTray = value;
    await TodoStorage.setMinimizeToTray(value);
  }
  ```
  （`tray_service.dart`，第 99-102 行）。
- **备注：** 无。

### `static Future<bool> getCloseToTray()` <a id="getclosetotray"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 771 行）
- **用途：** 获取持久化"关闭到托盘"设置。
- **输入：** 无。
- **返回：** `Future<bool>`。
- **副作用：** 可能触发首次 `_loadConfig()` 读取。
- **算法：** `await _loadConfig(); return _closeToTray;`。
- **用法：** `tray_service.dart`，`init`，第 52 行（上面 `getMinimizeToTray` 下已引用）。
- **备注：** 无。

### `static Future<void> setCloseToTray(bool value)` <a id="setclosetotray"></a>
- **种类：** `TodoStorage` 的静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 781 行）
- **用途：** 设置并持久化"关闭到托盘"设置。
- **输入：** `value`。
- **返回：** `Future<void>`。
- **副作用：** 无条件写 `storage_config.json`。
- **算法：** `await _loadConfig(); _closeToTray = value; await _saveConfig();`。
- **用法：**
  ```dart
  Future<void> setCloseToTray(bool value) async {
    _closeToTray = value;
    await TodoStorage.setCloseToTray(value);
    await windowManager.setPreventClose(value);
  }
  ```
  （`tray_service.dart`，第 109-113 行）。
- **备注：** `TodoStorage.setCloseToTray` 自己对 `windowManager` 一无所知——`TrayService` 负责在持久化设置后应用操作系统级效果。

### `static int _normalizeWeekStartDay(int? weekday)` <a id="_normalizeweekstartday"></a>
- **种类：** `TodoStorage` 的私有静态方法
- **来源：** `lib/features/todo/services/todo_storage.dart`（第 792 行）
- **用途：** 返回有效持久化周起始日，无效或缺失值默认周一。
- **输入：** `weekday` — 可空，预期 `DateTime.monday`..`DateTime.sunday`（1-7）。
- **返回：** `int` — 总在 `[DateTime.monday, DateTime.sunday]`。
- **副作用：** 无。
- **算法：** `weekday` 为 `null` 或在 `[DateTime.monday, DateTime.sunday]` 外时返回 `DateTime.monday`；否则原样返回。
- **用法：** 从 [`_loadConfig`](#_loadconfig)（规范化从磁盘读到的任何值）和 [`setWeekStartDay`](#setweekstartday)（比较/存储前规范化调用方提供值）调用。
- **备注：** 这是 `setWeekStartDay` 执行的唯一验证——无效输入静默变成周一而非抛出或被拒绝。

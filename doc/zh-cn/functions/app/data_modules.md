# lib/app/data_modules.dart

**本应用与共享 `myapps_data` 包之间的接缝**，也是 MyDay 五个数据文件的唯一真实来源。它取代了本应用以前携带的五个独立硬编码文件清单中的四个（`webdav_service`、`data_file_safety`、`import_export_service`、`backup_service`；第五个是 `TodoStorage` 的存储迁移清单，它在存储中枢里，保留）。

这也是 MyDay 三个特例所在之处，以声明式钩子而不是同步循环中的分支形式。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`TodoStorageAdapter`](#todostorageadapter) | 类 | A | 基于 `TodoStorage` 实现包的 `StorageAdapter`。 |
| [`todoDefaultRemotePath`](#constants) | 常量 | A | `'/MyDay'`。 |
| [`todoArchiveNamePrefix`](#constants) | 常量 | A | `'myday_backup_'`。 |
| [`todoDataFileName`](#constants) … `weightDataFileName` | 常量 | A | 五个数据文件名。 |
| [`migrateFinanceForcedBalances(data)`](#financemigration) | 函数 | A | 把旧强制余额转换为真实交易。 |
| [`buildTodoModule()`](#structured) | 函数 | A | 待办 `DataModule`。 |
| [`buildFinanceModule()`](#financemigration) | 函数 | A | 财务 `DataModule`，带迁移钩子。 |
| [`buildExchangeRatesModule()`](#exchangerates) | 函数 | A | 汇率 `DataModule`。 |
| [`buildIntimacyModule()`](#structured) | 函数 | A | 亲密 `DataModule`。 |
| [`buildWeightModule()`](#structured) | 函数 | A | 体重 `DataModule`。 |
| [`todoModuleRegistry`](#registry) | 字段 | A | 应用的有序 `ModuleRegistry`。 |

**对账：** 这是**分组**页面——上面 11 行覆盖文件的 16 个 `/// Purpose:` 声明，因为五个数据文件名常量共享一行，私有辅助（`_preserveUnknownJson`、`_imageNamesFromSections`、`_structuredModule`）在 [结构化模块](#structured) 条目内描述而不是各自成行。[INDEX.md](../INDEX.md) 数行而不是底层声明，因此列出 11。

## 文档

### `class TodoStorageAdapter` <a id="todostorageadapter"></a>
- **用途：** 在包完全不了解 `TodoStorage` 的情况下，给共享引擎提供存储根和 `storage_config.json` 访问。
- **构造函数：** `const TodoStorageAdapter({Future<Directory> Function()? appDir})`。
- **方法：** `getAppDir()`、`readConfig()`、`writeConfig(config)`，全部委托给中枢。
- **备注：** 可选的 `appDir` 解析器存在，使 `BackupService` 能继续尊重它的 `@visibleForTesting appDirProvider`。它每次调用都被查询。

### 常量 <a id="constants"></a>
- **备注：** 文件名和模块 id 是持久化的兼容契约——旧构建和新构建必须能对同一个 WebDAV 服务器和同样的备份捆绑互通。绝不更改。注意 `exchangeRates` 是 `exchange_rates.json` 的模块 id。

### 结构化模块：todo、intimacy、weight <a id="structured"></a>
- **备注：** 三个都经一个私有构建器。它们用**紧凑 `jsonEncode`** 编码，匹配旧的 `_uploadMergedJson` 路径，并设 `indexMergedUploadProgress: false`，因为 MyDay 对结构化文件报告不确定的上传阶段。每个都提供扁平化为一个列表的冲突容器；解决方案以普通记录 ID 为键，与冲突对话框先前所做完全一致。
- **保留：** 每个结构化模块设置一个 `preUploadTransform`，用应用自有的模式从基线/本地/远程快照重新注入未知 JSON 字段。MyDay 的合并输出不是自我保留的，因此跳过这会静默丢弃新版构建的字段。

### 财务：`migrateFinanceForcedBalances(data)` 和 `buildFinanceModule()` <a id="financemigration"></a>
- **用途：** 用当前汇率把旧强制账户余额转换为真实交易。
- **备注：** 从 `WebDAVService._migrateFinanceForcedBalances` 逐字移来。它作为模块的 `postMergeTransform` 接线，因为那正是它先前运行的位置：**在**合并**之后**和**在**冲突解决**之后**，在常规同步和最终化两条路径上。它不是合并前的远程迁移。财务也从其 `accounts` 和 `subscriptions` 小节贡献引用图像。

### 汇率 <a id="exchangerates"></a>
- **备注：** 直接构建而不是经结构化构建器。`mergeExchangeRateJson` 是永远不可能产生记录冲突的整文件并集合并，因此结果总是完整的，没有解决构建器。它是唯一报告索引上传进度的模块。

### `todoModuleRegistry` <a id="registry"></a>
- **备注：** 顺序是待办、财务、汇率、亲密、体重——与先前的 `_dataFileNames` 列表匹配。顺序对同步顺序、进度报告和备份键顺序在行为上意义重大。

## 契约文档的位置

`packages/myapps_data/doc/en-us/functions/src/modules/data_module.md` 和 `packages/myapps_data/doc/en-us/functions/src/storage/storage_adapter.md`。

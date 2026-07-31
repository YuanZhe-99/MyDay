# lib/shared/services/webdav_service.dart

**共享引擎的门面。** WebDAV 传输、上传锁生命周期、合并管线、`.sync_base` 快照和引用图像同步移到 `myapps_data` 包（`lib/src/webdav/sync_engine.dart` 等）。本文件从 2291 行缩到约 240 行并保留每个公共名称和签名，因此调用点、冲突对话框和既有测试不变。

五个数据文件——和 MyDay 的三个特例——在 [`../../app/data_modules.md`](../../app/data_modules.md) 描述一次；硬编码 `_dataFileNames` 列表已消失。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`SyncResult`](#syncresult) | 类 | A | 成功标志、错误文本、挂起冲突、非致命警告。 |
| [`PendingSync`](#pendingsync) | 类 | A | 逐模块未解决冲突加要终定的引擎状态。 |
| [`WebDAVService.progress`](#progress) | 静态 getter | A | 进度条的活 `ValueNotifier<SyncProgress>`。 |
| [`consumeLocalDataChanged()`](#consumelocaldatachanged) | 静态方法 | A | 读取并清除"同步写了本地数据"信号。 |
| [`loadConfig()`](#loadconfig) | 静态方法 | A | 读取 `webdav_config.json`。 |
| [`saveConfig(config)`](#saveconfig) | 静态方法 | A | 原子写 `webdav_config.json`。 |
| [`deleteConfig()`](#deleteconfig) | 静态方法 | A | 移除 `webdav_config.json`。 |
| [`testConnection(config)`](#testconnection) | 静态方法 | A | 一次 PROPFIND；207 或 404 意为可达。 |
| [`sync(config, {autoResolve})`](#sync) | 静态方法 | A | 远程 `.lock` 下完整双向同步。 |
| [`finalizePendingSync(...)`](#finalizependingsync) | 静态方法 | A | 上传用户的冲突解决。 |
| [`forceUpload(config)`](#forceupload) | 静态方法 | A | 用本地覆盖远程，无合并。 |
| [`forceDownload(config)`](#forcedownload) | 静态方法 | A | 用远程覆盖本地，无合并。 |

从包以原名重新导出：`WebDAVConfig`、`WebDAVUploadLock`、`RemoteFile`、`RemoteFileStatus`。

**对账：** `grep -c 'Purpose:' lib/shared/services/webdav_service.dart` 报告 15 对 12 行。一个是第 1 行**文件级**库注释。剩余 14 个中，`SyncResult` 和 `PendingSync` 行各覆盖自己的构造函数加一个 getter，私有 `_toSyncResult` 转换器在 [`sync`](#sync) 条目内描述而非有自己的行。

## 文档

### `class SyncResult` <a id="syncresult"></a>
- **字段：** `success`、`error`、`pending`、`warnings`（非致命图像传输失败）。
- **getter：** `hasConflicts`。

### `class PendingSync` <a id="pendingsync"></a>
- **字段：** `todoMerge`、`financeMerge`、`intimacyMerge`、`weightMerge`（应用类型化合并结果），加 `enginePending`（`finalizePendingSync` 使用的不透明引擎状态）。
- **getter：** `allConflicts` — 跨四个模块展平全部十二个冲突容器。
- **备注：** 汇率整文件合并且绝不冲突，因此从不出现在这里。引擎把每个类型化合并结果作为不透明 `state` 携带，这正是冲突对话框仍收到真实模型对象的原因。

### `progress` <a id="progress"></a>
- **种类：** 静态 getter → `ValueNotifier<SyncProgress>`。
- **备注：** 结构化模块报告不确定上传阶段；汇率报告索引进度。那个不对称由注册表中的逐模块标志保留。

### `consumeLocalDataChanged()` <a id="consumelocaldatachanged"></a>
- **返回：** `bool` — 自上次调用以来同步是否写了本地数据或下载了图像。
- **副作用：** 重置标志。

### `loadConfig()` <a id="loadconfig"></a>
- **返回：** `Future<WebDAVConfig?>`；缺席、格式错误或不可读时 null。
- **备注：** 缺失或 null `remotePath` 仍默认 `/MyDay`。

### `saveConfig(config)` <a id="saveconfig"></a>
- **副作用：** `webdav_config.json` 原子写，紧凑 JSON。凭据保持明文。

### `deleteConfig()` <a id="deleteconfig"></a>
- **副作用：** 存在时删除配置；基础快照和客户端 ID 保持原样。

### `testConnection(config)` <a id="testconnection"></a>
- **返回：** `Future<bool>` — HTTP 207 或 404 为 true。

### `sync(config, {autoResolve = false})` <a id="sync"></a>
- **副作用：** 获取远程 `.lock`，然后按注册表顺序逐模块下载、合并、应用模块变换、上传并保存基础；然后同步引用的财务和亲密图像；更新 `progress`。
- **备注：** 逐文件失败被收集，剩余模块仍同步。`autoResolve` 在每个生产调用点为 false。

### `finalizePendingSync(config, pending, resolutions)` <a id="finalizependingsync"></a>
- **输入：** 跨每个模块、记录 ID 到所选记录的单个扁平 `Map<String, dynamic>`。
- **返回：** `Future<bool>` — 任何模块失败时 false。
- **备注：** 每个模块的 `buildResolved` 按运行时类型挑出它识别的记录。财务强制余额迁移仍在解决后运行，未知字段保留仍在写入前立即应用。

### `forceUpload(config)` <a id="forceupload"></a>
- **副作用：** 覆盖远程数据并在 `.lock` 下上传缺失引用图像。

### `forceDownload(config)` <a id="forcedownload"></a>
- **副作用：** 替换本地数据文件和基础快照；下载缺失图像。无锁、仅语法验证。

## 引擎文档在哪里

`packages/myapps_data/doc/en-us/functions/src/webdav/` — `sync_engine.md`、`webdav_client.md`、`webdav_config.md`、`upload_lock.md`。

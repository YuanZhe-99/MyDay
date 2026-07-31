# lib/shared/services/backup_service.dart

**共享引擎的门面。** 捆绑创建、内容寻址 blob 存储、引用计数 GC、保留和 v1/v2 恢复移到 `myapps_data` 包（`lib/src/backup/backup_engine.dart`）。本文件保留每个公共名称和签名，因此既有测试不加修改运行。

备份格式不变：`backups/backup_<yyyyMMdd_HHmmss>.json` 捆绑持有 `_backupFormat`、每个模块一个原始 JSON 字符串和指向 `backups/blobs/<sha256><ext>` 的 `_imageRefs`。带内联 base64 `_images` 的遗留 v1 捆绑仍可恢复。

**MyDay 特有：** 每日自动备份由 `ReminderService` 的 30 秒循环驱动，**不**由自动同步调度器驱动。见 [`auto_sync_service.md`](auto_sync_service.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`appDirProvider`](#appdirprovider) | 静态字段 | A | 重定向所有备份 IO 的测试缝。 |
| [`modules`](#modules) | 静态字段 | A | 文件名到备份模块键，从注册表派生。 |
| [`autoBackupEnabled`](#settings) | 静态 getter/setter | A | 每日自动备份是否运行。 |
| [`retentionDays`](#settings) | 静态 getter/setter | A | 备份保留天数；0 永久保留。 |
| [`loadSettings()`](#settings) | 静态方法 | A | 从 `storage_config.json` 读取两个设置。 |
| [`saveSettings()`](#settings) | 静态方法 | A | 持久化两个设置。 |
| [`createBackup()`](#createbackup) | 静态方法 | A | 写 v2 捆绑加任何新 blob。 |
| [`runAutoBackupIfNeeded()`](#runautobackupifneeded) | 静态方法 | A | 到期时执行每日一次备份。 |
| [`listBackups()`](#listbackups) | 静态方法 | A | 最新优先列出捆绑，标记损坏的。 |
| [`getBackupModules(file)`](#getbackupmodules) | 静态方法 | A | 捆绑包含的模块 id。 |
| [`restoreBackup(file, {moduleKeys})`](#restorebackup) | 静态方法 | A | 先验证再恢复捆绑。 |
| [`deleteBackup(file)`](#deletebackup) | 静态方法 | A | 删除捆绑，然后 GC 孤儿 blob。 |

以不变形态重新导出：`BackupInfo{file, date, sizeBytes, corrupt}` 和 `RestoreResult{ok, wroteAnything, missingImages}`。

**对账：** `grep -c 'Purpose:' lib/shared/services/backup_service.dart` 报告 11。其中一个是第 1 行的**文件级**库注释，不是声明，留下 10 个文档化声明；表格有 12 行，因为 `autoBackupEnabled` 和 `retentionDays` 被列为 getter/setter 对。净：12 行对 10 个带 `Purpose:` 的声明加两个配对访问器。

## 文档

### `appDirProvider` <a id="appdirprovider"></a>
- **种类：** 静态字段，`@visibleForTesting`
- **备注：** 作为撕下引用传给存储适配器并在**每次**调用时读取，因此在用例间换掉提供者的测试对已构建引擎仍生效。

### `modules` <a id="modules"></a>
- **用途：** 为五个模块把数据文件名映射到备份模块键。
- **备注：** 从模块注册表派生——抽取移除的五个文件列表硬编码副本之一。

### 设置：`autoBackupEnabled`、`retentionDays`、`loadSettings()`、`saveSettings()` <a id="settings"></a>
- **副作用：** `storage_config.json`，不变键 `autoBackupEnabled` 和 `backupRetentionDays` 下。无关键保留。

### `createBackup()` <a id="createbackup"></a>
- **返回：** `Future<File?>` — 捆绑，失败时 null。
- **副作用：** 写捆绑、按 sha256 去重图像 blob、然后运行保留清理和 blob GC。

### `runAutoBackupIfNeeded()` <a id="runautobackupifneeded"></a>
- **备注：** `autoBackupEnabled` 为 false 时空操作。重入受守卫。"今天已备份"由扫描捆绑文件名决定，因此损坏捆绑不算数、当天重试。从 `ReminderService` 的 30 秒循环调用。

### `listBackups()` <a id="listbackups"></a>
- **备注：** 4 MiB 或以下的捆绑被解析以计算有效性和引用 blob 大小；更大的只按文件大小列出。不可解析捆绑被标记 `corrupt`，绝不隐藏。

### `getBackupModules(file)` <a id="getbackupmodules"></a>
- **返回：** 按注册表顺序的模块 id；不可解析捆绑为空。

### `restoreBackup(file, {moduleKeys})` <a id="restorebackup"></a>
- **备注：** 每个所选负载在首次写入前都经注册表解析器验证。WebDAV 自动同步在首次写入前被禁用，只在恢复未写任何东西地失败时重新启用，因此恢复的旧数据不能把删除传播给其他设备。

### `deleteBackup(file)` <a id="deletebackup"></a>
- **备注：** 10 分钟宽限窗口内更年轻的 blob 绝不收集。不可解析捆绑中止整个 GC 遍而非冒险删除它可能引用的 blob。

## 引擎文档在哪里

`packages/myapps_data/doc/en-us/functions/src/backup/backup_engine.md`。

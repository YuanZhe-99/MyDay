# lib/shared/views/backup_page.dart

备份屏：自动备份切换/保留设置、手动"立即备份"操作和支持逐备份删除和模块选择恢复的历史列表。实际备份/保留/blob-GC 机制几乎全部住在 [`BackupService`](../services/backup_service.md#createbackup)——本文件大部分是围绕它的薄 UI 接线，除 `_restoreBackup` 和 `_handlePostRestoreSync` 直接在视图中实现恢复前禁用自动同步安全规则和恢复后强制上传提议（它们拥有包围 `BackupService.restoreBackup` 的 `WebDAVService` 调用，不只是恢复调用本身）。完整安全规则描述见 [备份与恢复](../../../backup-restore.md)，恢复前为何禁用自动同步见 [WebDAV 同步](../../../sync.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `BackupPage({super.key})` | 构造函数（`BackupPage`） | B | 创建备份页实例。 |
| `createState` | 方法（`BackupPage`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_BackupPageState`） | B | 启动初始设置/备份列表加载。 |
| `_load` | 方法（`_BackupPageState`） | B | 把自动备份设置和备份列表加载进状态。 |
| `_createBackup` | 方法（`_BackupPageState`） | B | 创建手动备份并重新加载列表。 |
| `_toggleAutoBackup` | 方法（`_BackupPageState`） | B | 切换并持久化自动备份设置。 |
| `_setRetention` | 方法（`_BackupPageState`） | B | 设置并持久化保留窗口（天）。 |
| `_deleteBackup` | 方法（`_BackupPageState`） | B | 确认并删除一个备份。 |
| [`_restoreBackup`](#restorebackup) | 方法（`_BackupPageState`） | A | 确认、禁用自动同步并恢复备份的所选模块/图像。 |
| [`_handlePostRestoreSync`](#handlepostrestoresync) | 方法（`_BackupPageState`） | A | 成功恢复后提供恢复数据的强制上传。 |
| `build` | 方法（`_BackupPageState`） | B | 为当前状态构建备份页组件子树。 |
| `_buildSection` | 方法（组件辅助） | B | 渲染一个带标题的设置小节。 |
| `_RestoreModuleDialog({required this.availableModules})` | 构造函数（`_RestoreModuleDialog`） | B | 创建恢复模块选择对话框实例。 |
| `createState` | 方法（`_RestoreModuleDialog`） | B | 为此对话框创建可变状态对象。 |
| `initState` | 方法（`_RestoreModuleDialogState`） | B | 预选每个可用模块。 |
| `build` | 方法（`_RestoreModuleDialogState`） | B | 构建模块选择复选框列表。 |
| `_localizedModuleName` | 方法（`_RestoreModuleDialogState`） | B | 把模块 id 映射到其本地化显示名。 |

**对账：** `grep -c 'Purpose:' lib/shared/views/backup_page.dart` 返回 17。17 个块都文档化真实声明——未发现错附块和未文档化真实声明。`_retentionOptions` 和 `_moduleLabels` 静态 const 字段无 `Purpose:` 块，与它们是数据而非函数一致。

## 文档

### `Future<void> _restoreBackup(BackupInfo info)` <a id="restorebackup"></a>
- **种类：** `_BackupPageState` 的方法
- **来源：** `lib/shared/views/backup_page.dart`（第 149 行）
- **用途：** 让用户挑选要从备份恢复哪些模块、确认破坏性操作、*任何*数据文件被写入前（若启用）禁用 WebDAV 自动同步、运行恢复，然后交接到恢复后同步提议。
- **输入：** `info` — 被恢复的 `BackupInfo` 条目。
- **返回：** `Future<void>`。
- **副作用：** 可能禁用（并在空操作失败时重新启用）`webdav_config.json` 中的 WebDAV 自动同步；经 `BackupService.restoreBackup` 覆盖本地数据文件和图像；重载打开页面和移动提醒调度；显示对话框/snackbar；可能链入 `_handlePostRestoreSync`。
- **算法：**
  1. 经 `BackupService.getBackupModules(info.file)` 为备份获取 `availableModules`；为空（捆绑不可读）时带失败 snackbar 退出。
  2. 显示 `_RestoreModuleDialog` 让用户挑选模块子集；用户没挑任何时退出。
  3. 显示破坏性确认 `AlertDialog`；未确认退出。
  4. 加载当前 WebDAV 配置；计算 `hadAutoSync = webDavConfigured && config.autoSync`。`hadAutoSync` 时立即用 `autoSync: false` 保存配置——**在**调用 `restoreBackup` **前**、无 `mounted` 检查，使此行与首次文件写入之间崩溃或页面释放绝不能让自动同步保持开启、过期恢复数据待上传。
  5. 调用 `BackupService.restoreBackup(info.file, moduleKeys: selected)`。
  6. 恢复失败（`!result.ok`）时：只在 `hadAutoSync && !result.wroteAnything`（即本地数据保证未碰）时重新启用自动同步；显示失败 snackbar；不碰提醒或不提供强制上传地返回。
  7. 成功时：调用 `AutoSyncService.instance.notifyLocalDataChangedNow()` 和 `ReminderService.instance.refreshMobileSchedules()`，使打开页面和提醒计时器反映恢复数据；`missingImages > 0` 时显示报计数的警告 snackbar。
  8. 调用 `_handlePostRestoreSync(webDavConfigured ? config : null)` 提供强制上传步骤。
- **用法：**
  ```dart
  IconButton(
    icon: const Icon(Icons.restore),
    tooltip: l10n.backupRestore,
    onPressed: b.corrupt ? null : () => _restoreBackup(b),
  ),
  ```
- **备注：** 步骤 4 的"写入前禁用、无 `mounted` 门"顺序是 [备份与恢复 — 恢复验证与恢复前禁用自动同步安全规则](../../../backup-restore.md#restore-validation-and-the-auto-sync-disable-before-restore-safety-rule) 描述安全规则的具体实现——颠倒步骤 4 和 5（先恢复再禁用同步）会留下后台同步可针对已恢复但尚未受保护本地数据运行的窗口。

### `Future<void> _handlePostRestoreSync(WebDAVConfig? config)` <a id="handlepostrestoresync"></a>
- **种类：** `_BackupPageState` 的方法
- **来源：** `lib/shared/views/backup_page.dart`（第 246 行）
- **用途：** 成功恢复后（配置 WebDAV 时）询问用户是否把恢复数据强制上传到 WebDAV 远程，使普通后台同步不把恢复的旧数据当作新鲜编辑并传播它——含删除——给其他设备。
- **输入：** `config` — `_restoreBackup` 恢复前加载的 `WebDAVConfig`，WebDAV 同步未配置时 `null`。
- **返回：** `Future<void>`。
- **副作用：** 确认时获取同步唤醒锁、调用 `WebDAVService.forceUpload`、释放唤醒锁并用 `AutoSyncService.instance.recordSyncResult` 记录结果；两种方式都显示对话框/snackbar。
- **算法：**
  1. `config` 为 `null`（WebDAV 未配置）时只显示普通恢复成功 snackbar 并返回——无可提供。
  2. 否则显示解释同步已被禁用、提供立即强制上传的不可关闭 `AlertDialog`；用户拒绝或组件已卸载时退出（自动同步保持关闭）。
  3. 确认时：获取 `SyncWakeLock`，在总是释放唤醒锁（无论成功/失败/异常）的 `try/finally` 内调用 `WebDAVService.forceUpload(config)`。
  4. 仍 mounted 时经 `AutoSyncService.instance.recordSyncResult(result)` 记录结果并基于 `result.success` 显示成功/失败 snackbar。
- **用法：**
  ```dart
  if (!mounted) return;
  await _handlePostRestoreSync(webDavConfigured ? config : null);
  ```
  （[`_restoreBackup`](#restorebackup) 末尾调用，只在成功恢复后。）
- **备注：** 此方法自己在接受或跳过路径都绝不重新启用自动同步——用户留待稍后从 WebDAV 页显式重新启用，因为在这里强制决定（而非静默把同步重新打开）正是防止恢复的旧数据被自动合并和传播的东西。见 [WebDAV 同步 — 重试心跳与唤醒锁](../../../sync.md#retry-heartbeat-and-wake-lock) 的唤醒锁引用计数和强制操作规则。

## 相关页面

- [备份与恢复](../../../backup-restore.md) — 本页操作触发的备份格式、blob GC、保留和恢复安全规则。
- [WebDAV 同步](../../../sync.md) — `_handlePostRestoreSync` 使用的强制上传/唤醒锁机制，以及恢复为何先禁用自动同步。
- [`BackupService`](../services/backup_service.md) — 支撑本页每个备份/恢复/列表调用的服务。

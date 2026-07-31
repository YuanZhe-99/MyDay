# lib/shared/views/webdav_config_page.dart

WebDAV 同步屏：服务器/凭据/远程路径字段、测试连接、手动立即同步（带冲突解决）、强制上传/强制下载（带破坏性操作确认）、自动同步切换、断开和实时同步进度/状态显示。这是 [`WebDAVService`](../services/webdav_service.md) 的页面级对应物——这里几乎每个按钮都是 `WebDAVService` 调用的薄包装，除本文件自己拥有每个网络操作周围的唤醒锁获取/释放、进入 `finalizePendingSync` 的冲突对话框交接，以及从原始同步状态到用户所见内容的映射。完整 10 步同步流程、本页实现的强制操作和唤醒锁规则见 [WebDAV 同步](../../../sync.md)，最终回到本页 `SyncConflictDialog` 的完整跨模块冲突示例见 [同步演练](../../../examples/sync-walkthrough.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `WebDAVConfigPage({super.key})` | 构造函数（`WebDAVConfigPage`） | B | 创建 WebDAV 配置页实例。 |
| `createState` | 方法（`WebDAVConfigPage`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_WebDAVConfigPageState`） | B | 注册同步状态监听器并加载保存配置。 |
| `_refreshSyncStatus` | 方法（`_WebDAVConfigPageState`） | B | 后台同步状态变化时触发重建。 |
| `_loadConfig` | 方法（`_WebDAVConfigPageState`） | B | 把保存 WebDAV 配置加载进文本控制器。 |
| `dispose` | 方法（`_WebDAVConfigPageState`） | B | 注销监听器并释放文本控制器。 |
| `_currentConfig` | getter（`_WebDAVConfigPageState`） | B | 从当前表单字段构建 `WebDAVConfig`。 |
| [`_saveConfig`](#saveconfig) | 方法（`_WebDAVConfigPageState`） | A | 把表单保存为 WebDAV 配置，新完整配置时触发立即同步。 |
| `_testConnection` | 方法（`_WebDAVConfigPageState`） | B | 用当前表单值测试连通性。 |
| [`_syncNow`](#syncnow) | 方法（`_WebDAVConfigPageState`） | A | 运行手动同步，把冲突经 `SyncConflictDialog` 和 `finalizePendingSync` 路由。 |
| [`_showSyncResult`](#showsyncresult) | 方法（`_WebDAVConfigPageState`） | A | 按结果把非冲突同步/强制结果呈现为对话框或 snackbar。 |
| [`_forceUpload`](#forceupload) | 方法（`_WebDAVConfigPageState`） | A | 确认并运行破坏性强制上传（本地覆盖远程）。 |
| [`_forceDownload`](#forcedownload) | 方法（`_WebDAVConfigPageState`） | A | 确认并运行破坏性强制下载（远程覆盖本地）。 |
| `_confirmForceAction` | 方法（`_WebDAVConfigPageState`） | B | 为强制上传/下载显示共享破坏性确认对话框。 |
| `_progressText` | 方法（`_WebDAVConfigPageState`） | B | 把 `SyncProgress` 阶段映射为本地化状态行。 |
| `_showSyncDialog` | 方法（`_WebDAVConfigPageState`） | B | 为长同步消息显示可滚动对话框。 |
| [`_syncStatusText`](#syncstatustext) | 方法（`_WebDAVConfigPageState`） | A | 构建自动同步健康摘要行（失败/冲突/上次成功/无）。 |
| `_disconnect` | 方法（`_WebDAVConfigPageState`） | B | 清除保存 WebDAV 配置并重置表单。 |
| `_fillNextcloud` | 方法（`_WebDAVConfigPageState`） | B | 用 Nextcloud WebDAV 预设填充服务器 URL/路径字段。 |
| `build` | 方法（`_WebDAVConfigPageState`） | B | 为当前状态构建 WebDAV 配置页组件子树。 |

**对账：** `grep -c 'Purpose:' lib/shared/views/webdav_config_page.dart` 返回 20。20 个块都文档化真实声明——未发现错附块和未文档化真实声明。`_urlController`/`_userController`/`_passController`/`_pathController` 和布尔状态字段无 `Purpose:` 块，与它们是状态而非函数一致。

## 文档

### `Future<void> _saveConfig()` <a id="saveconfig"></a>
- **种类：** `_WebDAVConfigPageState` 的方法
- **来源：** `lib/shared/views/webdav_config_page.dart`（第 112 行）
- **用途：** 把当前表单持久化为 WebDAV 配置，新保存配置完整配置且自动同步开启时立即启动后台同步，而非等待下次自动同步触发。
- **输入：** 无（读取从表单控制器和 `_autoSync` 构建的 `_currentConfig`）。
- **返回：** `Future<void>`。
- **副作用：** 经 `WebDAVService.saveConfig` 写 `webdav_config.json`；更新 `_isConfigured`；可能调用 `AutoSyncService.instance.requestSyncNow()`；显示确认 snackbar。
- **算法：**
  1. 从 `_currentConfig` 构建 `config` 并经 `WebDAVService.saveConfig(config)` 保存。
  2. 从 `config.isConfigured` 更新 `_isConfigured`。
  3. `config.isConfigured && config.autoSync` 时调用 `AutoSyncService.instance.requestSyncNow()` 立即触发同步，而非等待下次周期/恢复/防抖触发。
  4. 仍 mounted 时显示"配置已保存"snackbar。
- **用法：**
  ```dart
  Expanded(
    child: FilledButton(
      onPressed: _saveConfig,
      child: Text(AppLocalizations.of(context)!.commonSave),
    ),
  ),
  ```
- **备注：** 步骤 3 是 [WebDAV 同步 — 自动同步触发器](../../../sync.md#auto-sync-triggers) 列出"保存/启用完整配置的自动同步 WebDAV 设置"触发器的具体实现——没有它，初始设置后首次同步得等待应用启动/恢复/15 分钟计时器/30 秒保存防抖，而非立即运行。

### `Future<void> _syncNow()` <a id="syncnow"></a>
- **种类：** `_WebDAVConfigPageState` 的方法
- **来源：** `lib/shared/views/webdav_config_page.dart`（第 161 行）
- **用途：** 在屏幕唤醒锁下运行手动 WebDAV 同步，浮出记录冲突时把它们交给 `SyncConflictDialog` 并终定用户的解决。
- **输入：** 无（读取 `_currentConfig`）。
- **返回：** `Future<void>`。
- **副作用：** 获取/释放同步唤醒锁（解决冲突时两次）；调用 `WebDAVService.sync` 和可能 `WebDAVService.finalizePendingSync`；在 `AutoSyncService` 上记录结果；通知本地数据变更监听器；显示冲突对话框和/或 snackbar。
- **算法：**
  1. 设 `_syncing = true`、获取唤醒锁并在总是释放唤醒锁并清除 `_syncing` 的 `try/finally` 内调用 `WebDAVService.sync(_currentConfig)`。
  2. 无论结果都记录结果并调用 `AutoSyncService.instance.notifyLocalDataChangedIfNeeded()`。
  3. `result.hasConflicts` 时：显示 `SyncConflictDialog(conflicts: result.pending!.allConflicts)`（不可关闭）。用户产生解决且仍 mounted 时：再次设 `_syncing = true`、重新获取唤醒锁、在另一个 `try/finally` 内调用 `WebDAVService.finalizePendingSync(_currentConfig, result.pending!, resolutions)`、经 `recordFinalizeResult(ok)` 记录终定结果并显示成功/失败 snackbar。用户未解决地关闭对话框时，改为再次记录原始（仍冲突）结果并显示失败 snackbar。
  4. 无冲突时调用 [`_showSyncResult`](#showsyncresult) 呈现普通成功/警告/失败结果。
- **用法：**
  ```dart
  FilledButton.icon(
    onPressed: _syncing ? null : _syncNow,
    icon: _syncing ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.sync),
    label: Text(_syncing
        ? AppLocalizations.of(context)!.settingsWebDAVSyncing
        : AppLocalizations.of(context)!.settingsWebDAVSyncNow),
  ),
  ```
- **备注：** 唤醒锁在两个网络阶段（初始同步、然后解决后终定）各自获取和释放，而非跨冲突对话框本身持有——否则用户可能无限坐在解决对话框上而屏幕唤醒锁保持开启。这镜像 [WebDAV 同步 — 10 步同步流程](../../../sync.md#the-10-step-sync-flow)（步骤 8-9）描述的手动同步路径，[同步演练](../../../examples/sync-walkthrough.md) 示例也以相同终定调用结束。

### `Future<void> _showSyncResult(SyncResult result)` <a id="showsyncresult"></a>
- **种类：** `_WebDAVConfigPageState` 的方法
- **来源：** `lib/shared/views/webdav_config_page.dart`（第 230 行）
- **用途：** 向用户呈现非冲突同步或强制操作结果，按发生什么在可滚动错误/警告对话框和普通成功 snackbar 间选择。
- **输入：** `result` — 无挂起冲突的 `SyncResult`。
- **返回：** `Future<void>`。
- **副作用：** 显示 `AlertDialog`（失败或警告）或 `SnackBar`（普通成功）。
- **算法：**
  1. 未挂载时立即返回。
  2. `!result.success` 时显示带失败标题和 `result.error`（或 `'-'`）的对话框并返回。
  3. 否则 `result.warnings` 非空时显示带成功标题和组合警告计数与连接警告列表的消息的对话框并返回——即使整体同步成功也显示警告（如单个图像传输失败）。
  4. 否则显示普通成功 snackbar。
- **用法：**
  ```dart
  } else {
    await _showSyncResult(result);
  }
  ```
  （无冲突 case 从 [`_syncNow`](#syncnow) 调用，`_forceUpload`/`_forceDownload` 每个结果调用。）
- **备注：** 警告绝不被静默丢弃以换"成功"snackbar——按 [WebDAV 同步 — 重试心跳与唤醒锁](../../../sync.md#retry-heartbeat-and-wake-lock)，单个图像传输失败非致命但仍经 `SyncResult.warnings` 浮出，此方法正是实际把它们显示给用户而非只报告整体成功的东西。

### `Future<void> _forceUpload()` <a id="forceupload"></a>
- **种类：** `_WebDAVConfigPageState` 的方法
- **来源：** `lib/shared/views/webdav_config_page.dart`（第 258 行）
- **用途：** 显式破坏性操作确认后，用本地数据覆盖远程数据，期间持有屏幕唤醒锁。
- **输入：** 无（读取 `_currentConfig`）。
- **返回：** `Future<void>`。
- **副作用：** 经 `WebDAVService.forceUpload` 覆盖远程数据文件/图像；获取并释放唤醒锁；记录结果并通知本地数据变更监听器；经 `_showSyncResult` 显示结果对话框/snackbar。
- **算法：**
  1. 经 `_confirmForceAction` 用上传特定文案显示共享强制操作确认对话框；拒绝或未挂载返回。
  2. 设 `_syncing = true`、获取唤醒锁并在释放锁并清除 `_syncing` 的 `try/finally` 内调用 `WebDAVService.forceUpload(_currentConfig)`。
  3. 记录结果、调用 `notifyLocalDataChangedIfNeeded()` 并经 [`_showSyncResult`](#showsyncresult) 呈现。
- **用法：**
  ```dart
  Expanded(
    child: OutlinedButton.icon(
      onPressed: _syncing ? null : _forceUpload,
      icon: const Icon(Icons.upload, size: 18),
      label: Text(AppLocalizations.of(context)!.settingsWebDAVForceUpload),
    ),
  ),
  ```
- **备注：** 唤醒锁只在*确认后*获取，绝不在用户决定前投机获取——匹配 [WebDAV 同步 — 重试心跳与唤醒锁](../../../sync.md#retry-heartbeat-and-wake-lock) 中强制操作"需要破坏性操作确认对话框"且只在实际传输期间持锁的规则。

### `Future<void> _forceDownload()` <a id="forcedownload"></a>
- **种类：** `_WebDAVConfigPageState` 的方法
- **来源：** `lib/shared/views/webdav_config_page.dart`（第 289 行）
- **用途：** 显式破坏性操作确认后，用远程数据覆盖本地数据，期间持有屏幕唤醒锁。
- **输入：** 无（读取 `_currentConfig`）。
- **返回：** `Future<void>`。
- **副作用：** 经 `WebDAVService.forceDownload` 覆盖本地数据文件/图像；获取并释放唤醒锁；记录结果并通知本地数据变更监听器；经 `_showSyncResult` 显示结果对话框/snackbar。
- **算法：** 与 [`_forceUpload`](#forceupload) 相同形态：用下载特定文案确认、拒绝/未挂载守卫、在带 `_syncing` 跟踪的唤醒锁下运行 `WebDAVService.forceDownload`，然后记录并呈现结果。
- **用法：**
  ```dart
  Expanded(
    child: OutlinedButton.icon(
      onPressed: _syncing ? null : _forceDownload,
      icon: const Icon(Icons.download, size: 18),
      label: Text(AppLocalizations.of(context)!.settingsWebDAVForceDownload),
    ),
  ),
  ```
- **备注：** 与 `WebDAVService.forceUpload` 不同，`forceDownload` 不取远程锁（它只下载）——见 [WebDAV 同步 — 重试心跳与唤醒锁](../../../sync.md#retry-heartbeat-and-wake-lock)——但本页对两个操作仍以相同方式持有本地屏幕唤醒锁和 `_syncing` 忙标志，因为从用户角度看两者都是长时间前台传输。

### `String? _syncStatusText()` <a id="syncstatustext"></a>
- **种类：** `_WebDAVConfigPageState` 的方法
- **来源：** `lib/shared/views/webdav_config_page.dart`（第 404 行）
- **用途：** 构建同步控件上方显示的单行自动同步健康摘要，区分真实双向冲突与普通失败，完全无错误时回退上次成功时间。
- **输入：** 无（读取 `AutoSyncService.instance.lastError`/`hasPendingConflicts`/`lastSuccessAt`）。
- **返回：** `String?` — 无可显示（无错误且尚无记录成功）时 `null`。
- **副作用：** 无。
- **算法：**
  1. `lastError != null` 时：`hasPendingConflicts` 则返回冲突标签字符串，否则失败标签字符串——都包含原始错误文本。
  2. 否则 `lastSuccessAt != null` 时返回"上次成功于 `<本地时间>`"字符串。
  3. 否则返回 `null`。
- **用法：**
  ```dart
  if (_isConfigured) ...[
    if (_syncStatusText() != null) ...[
      Card(
        color: AutoSyncService.instance.lastError == null
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_syncStatusText()!, ...),
        ),
      ),
  ```
- **备注：** 回退通用失败消息前检查 `hasPendingConflicts` 正是让真实双向冲突不被报告成无法区分的"同步失败"的东西——按 [WebDAV 同步 — 自动同步触发器](../../../sync.md#auto-sync-triggers)，"失败绝不被静默吞掉；冲突绝不在后台被 LWW 自动解决"，此方法正是 UI 中浮出那个区分的东西。`build` 两次调用这个 getter 式方法（一次检查 `null`、一次渲染），因此它不在这两次调用间缓存。

## 相关页面

- [WebDAV 同步](../../../sync.md) — 本页包裹的完整 10 步同步流程、自动同步触发器、重试/心跳/唤醒锁规则和强制操作语义。
- [同步演练](../../../examples/sync-walkthrough.md) — 经本页 `SyncConflictDialog` 和 `_syncNow` 终定路径解决的完整跨模块冲突。
- [`WebDAVService`](../services/webdav_service.md) — 本页每个网络调用背后的服务。
- [`sync_conflict_dialog.md`](../widgets/sync_conflict_dialog.md) — `_syncNow` 显示的冲突解决对话框。

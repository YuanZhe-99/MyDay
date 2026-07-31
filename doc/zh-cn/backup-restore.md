# 备份、恢复和导入/导出

主要来源：`AGENTS.md` 的"备份、导入、导出和图像"一节，对照 `lib/shared/services/backup_service.dart`（为 blob GC 机制略读）交叉核对。

## 备份格式 v2

`BackupService` 管理手动备份、每日自动备份、保留和模块选择性恢复。每个 `backups/backup_*.json` 捆绑存储数据模块 JSON 字符串，外加指向 `backups/blobs/<sha256><ext>` 下内容寻址图像 blob 的 `_imageRefs` 映射（`lib/shared/services/backup_service.dart`，`_blobSubDir = 'blobs'`）。跨备份的相同图像只存储一次并共享：创建备份时，被引用的图像文件被哈希并去重进共享 blob 存储，捆绑只记录 `refs['images/<name>'] = '<hash><ext>'`（`bundle['_imageRefs'] = refs`），而不是再次嵌入图像字节。

嵌入内联 base64 `_images` 的旧 v1 捆绑仍可恢复——恢复先检查 `_imageRefs`（v2 blob 引用），再回退到旧内联 base64 路径。

## Blob 垃圾回收

- 一个 blob 只在**没有剩余备份**引用它时被物理删除。
- GC 在创建/删除/保留操作后运行。
- 任何剩余捆绑不可解析时 GC **整体中止**——引用集将未知，因此绝不在不确定下删除任何东西：

  > 未知引用集：绝不在不确定下删除 blob。

- GC 绝不删除比 **10 分钟宽限窗口**（`static const _blobGcGrace = Duration(minutes: 10);`）更年轻的 blob，因此由并发创建中的备份写入的 blob 不可能在备份的捆绑文件完成引用它之前被竞态删除。

## 保留与损坏捆绑处理

- 捆绑写入经 `DataFileSafety` 原子化。
- 损坏（不可解析）捆绑在备份历史中标记且禁用恢复，并且**不计入**"今天已备份"——因此被中断的自动备份在下一次机会重试，而不是被静默当作已完成。
- `runAutoBackupIfNeeded()` 可重入守卫，并在每个平台上从 30 秒 `ReminderService` 循环运行。
- `BackupService` 配置 I/O 走 `TodoStorage.readConfig()`/`writeConfig()`，与应用其余配置保留规则一致（见 [架构](architecture.md)）。
- 保留包括与较长保留期并列的 3 天选项。

## 恢复校验与恢复前禁用自动同步安全规则

- **写入任何东西前校验：** 恢复在写入任何文件前通过 `DataFileSafety.validateDataJson`（与正常加载使用的相同类型化异常校验路径——见 [架构](architecture.md)）校验每个所选模块负载，然后原子写入。
- **图像名净化：** 恢复的图像名被净化为平铺 `images/<name>`；路径穿越或绝对路径被拒绝。
- **首次写入前禁用自动同步：** WebDAV 自动同步启用时，恢复备份会在第一个数据文件写入*之前*禁用 `webdav_config.json` 中的自动同步——不带 `mounted` 门——因此恢复中途崩溃或页面销毁绝不会留下恢复出的旧数据而自动同步仍然开着（否则会让下一次后台同步把恢复出的旧数据——包括删除——传播到远程和其他设备）。
- **`RestoreResult`：** `BackupService.restoreBackup` 返回带 `ok`、`wroteAnything` 和 `missingImages` 的 `RestoreResult`。自动同步只在恢复失败**且** `wroteAnything == false`（即本地数据保证未被触碰）时重新启用——任何至少写了一个文件的恢复都让自动同步保持关闭，直到用户显式处理。
- **成功恢复后**，备份页：
  1. 重载打开的页面（`AutoSyncService.notifyLocalDataChangedNow()`），
  2. 刷新移动提醒日程，
  3. v2 图像 blob 从 blob 存储缺失时警告（`backupRestoreMissingImages`），并且
  4. ——只在 WebDAV 同步已配置时——询问是否强制上传恢复的数据（期间持有唤醒锁，结果记录到同步状态）。

  没有第 4 步，下一次普通同步会把恢复出的旧数据当作新的本地编辑/删除，并向外传播到远程和其他设备。

## 导入/导出——仅 ZIP，不再有 CSV/JSON

`ImportExportService` 处理设置导入/导出，它对全部五个数据 JSON 文件加图像是**仅 ZIP** 的（旧的 CSV/JSON 文件导入流程在 v1.1.1 移除）。

- ZIP 导入只解压**允许列表中的条目**：五个数据 JSON 文件，加 `images/` 下的平铺文件。
- 解析后的输出路径被限制在应用目录内，因此构造的 ZIP 无法逃出它去覆盖 `webdav_config.json` 或 `storage_config.json` 之类的配置文件——这与上面恢复图像名使用的**路径穿越保护**原理相同。
- 导入的数据 JSON 文件被严格 UTF-8 解码（使中文和其他非 ASCII 文本正确存活导入）、在替换任何东西前校验（再次经 `DataFileSafety`），并经 tmp-重命名写入。

`ImageService` 选择本地图像、下载 logo/照片、以 UUID 文件名存储在 `images/` 下、解析相对路径，并拒绝微型占位下载（防御损坏/空图像 URL 被保存为真实图像）。

## 相关页面

- [架构](architecture.md) — 这里复用的 `DataFileSafety` 校验和原子写入机制。
- [WebDAV 同步](sync.md) — 为什么恢复前禁用自动同步重要，以及成功恢复后的强制上传提议。
- [数据格式](data-formats.md) — 这些备份/导入流程覆盖的五个数据 JSON 文件。

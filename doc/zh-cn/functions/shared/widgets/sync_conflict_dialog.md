# lib/shared/widgets/sync_conflict_dialog.dart

手动同步冲突解决对话框：对上次同步以来两侧都变化的每条记录，用户逐记录选"保留本地"或"保留远程"，每个冲突都有选择前对话框不启用其应用按钮。结果的所选记录 `Map<String, dynamic>` 之后如何消费见 [同步 — 跨模块混合解决映射安全规则](../../../sync.md#the-cross-module-mixed-resolutions-map-safety-rule)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `SyncConflictDialog`（构造函数） | 构造函数（`SyncConflictDialog`） | B | 创建同步冲突对话框实例。 |
| `createState` | 方法（`SyncConflictDialog`） | B | 为此组件创建可变状态对象。 |
| `_allResolved` | getter（`_SyncConflictDialogState`） | B | 返回每个冲突是否都有所选侧。 |
| `build` | 方法（`_SyncConflictDialogState`） | B | 构建冲突列表和应用/取消操作。 |
| `_ChoiceButton`（构造函数） | 构造函数（`_ChoiceButton`） | B | 创建选择按钮实例。 |
| `build` | 方法（`_ChoiceButton`） | B | 构建本地/远程选择 chip。 |

`grep -c 'Purpose:' lib/shared/widgets/sync_conflict_dialog.dart` 报告 6，与本文件全部六个真实声明匹配。未发现错附或未文档化声明。这里每个声明都是 Tier B：两个构造函数是简单转发构造函数、两个 `build()` 方法属于显式构建方法规则、`_allResolved` 是无分支/循环/IO 的单行长度比较。

## 文档

本文件所有声明都是 Tier B，因此按模板只有索引行、无完整条目。供上下文：`SyncConflictDialog` 取 `List<RecordConflict>`（来自 `shared/services/sync_merge.dart`）并经 `Navigator.pop` 返回 `null`（取消）或把每个冲突 `id` 映射到所选 `localRecord`/`remoteRecord` 对象的 `Map<String, dynamic>`。它这样显示：

```dart
final resolutions = await showDialog<Map<String, dynamic>>(
  context: context,
  barrierDismissible: false,
  builder: (_) => SyncConflictDialog(conflicts: result.pending!.allConflicts),
);
```

（`lib/shared/views/webdav_config_page.dart`，`_syncNow`，手动同步报告 `result.hasConflicts` 后。）结果映射传给 `WebDAVService.finalizePendingSync`，期间在 `SyncWakeLock.acquire()`/`release()` 下持有——见 [sync_wake_lock.md](../services/sync_wake_lock.md)。

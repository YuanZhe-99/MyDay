# lib/shared/services/sync_progress.dart

**重新导出垫片。** `SyncPhase`、`SyncProgress` 和 `SyncProgressListenable` 逐字移到共享 `myapps_data` 包（那里的 `lib/src/webdav/sync_progress.dart`）。三个应用的副本逐字节相同（经 SHA-256 验证），因此移动不改变任何行为。

本文件保留只为让既有导入继续工作：

```dart
export 'package:myapps_data/myapps_data.dart'
    show SyncPhase, SyncProgress, SyncProgressListenable;
```

## 声明

没有自己的。

**对账：** `grep -c 'Purpose:' lib/shared/services/sync_progress.dart` 报告 1 且表格为空——正确。那个单块是描述重新导出的**文件级**库注释；文件自己不声明任何东西，这正是垫片的全部意义。

## 真实文档在哪里

`packages/myapps_data/doc/en-us/functions/src/webdav/sync_progress.md`。

也见暴露 UI 监听的 `ValueNotifier<SyncProgress>` 的 [`webdav_service.md`](webdav_service.md)。

# lib/shared/services/sync_wake_lock.dart

**重新导出垫片。** `SyncWakeLock` 逐字移到共享 `myapps_data` 包（那里的 `lib/src/sync/sync_wake_lock.dart`）。三个应用的副本逐字节相同（经 SHA-256 验证）。

```dart
export 'package:myapps_data/myapps_data.dart' show SyncWakeLock;
```

锁仍引用计数、所有权跟踪并吞掉所有插件错误。它由运行前台操作（手动同步、冲突终定、强制上传/下载）的**页面**获取和释放，不由同步引擎——后台自动同步绝不能用它。

## 声明

没有自己的。

**对账：** `grep -c 'Purpose:' lib/shared/services/sync_wake_lock.dart` 报告 1 且表格为空——正确。那个单块是描述重新导出的**文件级**库注释；文件自己不声明任何东西，这正是垫片的全部意义。

## 真实文档在哪里

`packages/myapps_data/doc/en-us/functions/src/sync/sync_wake_lock.md`。

# lib/shared/services/auto_sync_service.dart

**共享调度器的门面。** 生命周期观察者、30 秒保存防抖、15 分钟周期计时器、在途守卫和状态记账移到 `myapps_data` 包（`lib/src/sync/auto_sync_scheduler.dart`）。MyDay 的差异留在这里作为钩子。

## 本应用提供的钩子

| 钩子 | 值 |
|---|---|
| `isAutoSyncActive` | 配置存在、已配置且启用 `autoSync`。 |
| `runSync` | `WebDAVService.sync(config)`——绝不带 `autoResolve`。 |
| `consumeLocalDataChanged` | `WebDAVService.consumeLocalDataChanged`。 |
| `onPeriodicTick` | **`null`——刻意。** |
| `onResume` | `ReminderService.instance.refreshMobileSchedules()`。 |

**null 周期钩子承载负载。** MyDay 的每日备份由 `ReminderService` 的 30 秒循环驱动，不由此调度器——不同于在周期滴答上运行 `BackupService.runAutoBackupIfNeeded` 的 MyAnime 和 MyDevice。不要"统一"它：在这里接备份会双重驱动它。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `instance` | 静态字段 | A | 单例。 |
| `lastSuccessAt` / `lastFailureAt` / `lastError` / `hasPendingConflicts` | getter | A | 设置 UI 的内存同步状态。 |
| `addOnLocalDataChanged` / `removeOnLocalDataChanged` | 方法 | A | 注册和移除 UI 重载回调。 |
| `addOnStatusChanged` / `removeOnStatusChanged` | 方法 | A | 注册和移除状态变更回调。 |
| `recordSyncResult(result)` | 方法 | A | 把手动触发同步记录进相同状态路径。 |
| `recordFinalizeResult(ok)` | 方法 | A | 记录冲突终定。 |
| `notifyLocalDataChangedIfNeeded()` | 方法 | A | **若**引擎标志已设则触发重载回调。 |
| `notifyLocalDataChangedNow()` | 方法 | A | 无条件触发重载回调（恢复、ZIP 导入）。 |
| `start()` / `stop()` | 方法 | A | 开始和结束观察生命周期并运行计时器。 |
| `notifySaved()` | 方法 | A | 存储钩子：重启 30 秒防抖。 |
| `requestSyncNow()` | 方法 | A | 取消任何挂起防抖并立即同步。 |

**对账：** 这是**分组**页——上面 11 行覆盖文件的 18 个 `/// Purpose:` 声明，因为四个状态 getter 共享一行，每个 `add…`/`remove…` 回调对和 `start()`/`stop()` 对共享一行。[INDEX.md](../../INDEX.md) 数行而非底层声明，因此列出 11。本页按设计无 `## 文档` 小节：门面的行为在其包裹的调度器处文档化（见下面）。

## 备注

- 状态仅内存且从不持久化。
- 自动同步保持 `autoResolve` 禁用：真实双向冲突被记录为可见挂起状态而非静默应用最后写入者胜出。
- 重叠触发被在途守卫静默跳过。
- `notifySaved()` 在 `start()` 前被忽略。
- 恢复时刷新移动提醒调度，使逐日通知正文在挂起后从当前数据重新计算。

## 调度器文档在哪里

`packages/myapps_data/doc/en-us/functions/src/sync/auto_sync_scheduler.md`。

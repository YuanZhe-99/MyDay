# WebDAV 同步

WebDAV 同步是逐记录三方合并，不是整文件替换。合并步骤背后的引擎单独文档化于 [三方合并](algorithms/three-way-merge.md)；本页覆盖端到端流程、重试/心跳/唤醒锁行为、逐文件错误处理和自动同步触发。主要来源：`AGENTS.md` 的"WebDAV 同步"一节，对照 `lib/shared/services/webdav_service.dart` 和 `lib/shared/services/sync_merge.dart` 交叉核对。

## 十步同步流程

1. **在任何数据下载前获取远程 `.lock`**，使用稳定的本地客户端 id、一个上传令牌、UTC 时间戳和 60 秒 TTL。另一客户端的活动锁阻止上传；过期锁被当作失败上传处理，可以被替换。本地 `.sync_base/upload_lock.json` 文件让下一次启动检测到被中断的上传，并在再次上传前重新下载/重新合并。
2. **下载远程 JSON**，使用判别式结果：只有 HTTP 404 算作"远程缺失"；任何其他失败（认证/服务器/网络）记录逐文件错误并跳过那个文件，因此本地数据绝不会被上传覆盖一个不可读的远程文件。（这是"逐文件错误，不中止整个同步"的行为——与 MyDevice 使用的规则相同；MyAnime 这里略有不同。）
3. **加载本地 JSON** 和 `.sync_base/` 基线快照（用于三方差异比较的上次同步版本）。
4. **在可用处使用 `modifiedAt` 逐记录合并**。两侧序列化内容相同的记录合并时不会产生冲突，即使两侧都提升了 `modifiedAt`（如早前失败上传留下过期基线之后）。
5. **只有一侧变化时自动解决**——那种情况不产生冲突。
6. **同一条记录自上次同步以来两侧都变化时检测冲突**。
7. **保留来自基线/本地/远程的未知 JSON 字段**，使新版应用的字段经旧版或无人值守合并往返时存活。
8. **没有记录冲突时：** 保存合并后的本地数据，在 `.lock` 仍有效时强制上传完整合并 JSON，并更新基线快照。数据 JSON 的 PUT 不使用数据文件 `If-Match`/`If-None-Match`——`.lock` 是数据写入唯一的并发守卫。
9. **有记录冲突时：** 把它们返回给用户。用户解决后，`finalizePendingSync` 重新获取 `.lock` 并强制上传每个完整的已解决 JSON。
10. **上传完成后清除匹配的远程/本地上传锁**。

手动同步用 `autoResolve: false` 并显示 `SyncConflictDialog`。自动同步同样保持 `autoResolve` 禁用：它把失败和真正的双向冲突记录为设置/WebDAV 中可见的状态，而不是静默应用最后写入者胜出。用户必须打开 WebDAV 页面手动解决冲突——同步绝不为真正的冲突悄悄选胜者。

## 逐文件错误处理（不中止整个同步）

单个格式错误或不可达的远程数据文件不阻塞其他文件的同步：逐文件错误在整个运行中累积，只有那一个文件的同步在该周期被跳过。这与 MyDevice 的行为一致（MyAnime 中止方式不同）——见 `AGENTS.md` WebDAV 一节的来源说明。

## 跨模块混合解决映射安全规则

`finalizePendingSync` 原样接收混合的跨模块解决映射——它绝不对整个映射做批量类型转换。每个合并结果（`lib/shared/services/sync_merge.dart` 中的 `TodoMergeResult`、`FinanceMergeResult`、`IntimacyMergeResult`、`WeightMergeResult`）实现自己的 `buildResolved(Map<String, dynamic> resolutions)`，后者再对每种记录类型调用私有 `_resolveList<T>`。该辅助按 id 查找每个冲突的解决方案并单独类型检查，如 `WeightMergeResult.buildResolved` 中：

```dart
for (final c in recordConflicts) {
  final resolved = resolutions[c.id];
  // Default to the local record when unresolved or mistyped so
  // conflicting records are never silently dropped.
  result.add(resolved is WeightRecord ? resolved : c.localRecord);
}
```

因为每个模块都对*同一个*共享 `resolutions` 映射做自己的 `is T` 检查，而不是把整个映射转换为 `Map<String, T>`，一次解决（比如说）财务冲突和亲密冲突的冲突解决 UI 可以填充一个映射并把它交给两个模块的 `buildResolved`——每个模块只触碰值匹配自己类型的条目。此规则存在之前，批量转换混合映射会在跨模块冲突时崩溃。未解决或类型错误的条目默认本地记录，因此冲突记录绝不丢失。同一次同步跨越财务和亲密冲突的实例演练见 [同步演练](examples/sync-walkthrough.md)。

## 同步数据参考

从 `AGENTS.md` 复制：

| 文件 | 合并函数 | 合并策略 |
| --- | --- | --- |
| `todo_data.json` | `mergeTodoData()` | 每日/一次性记录按 id + `modifiedAt`；每日日志并集；每日评分按天 LWW；设置 LWW |
| `finance_data.json` | `mergeFinanceData()` | 账户/分类/交易/订阅按 id + `modifiedAt`；设置 LWW |
| `exchange_rates.json` | `mergeExchangeRateJson()` | 快照并集；更新的有效当前快照胜出（解析不到快照的当前 id 被忽略）；更新的 `lastFetchedAt` 胜出 |
| `intimacy_data.json` | `mergeIntimacyData()` | 伴侣/玩具/姿势/记录/周期记录按 id + `modifiedAt`（伴侣 `body` 搭其伴侣记录同行）；计时器历史按开始并集；计时器会话按 `timerSessionModifiedAt` LWW；`userBody` 按 `userBodyModifiedAt` LWW；设置 LWW（排序设置和 `chartSettings`） |
| `weight_data.json` | `mergeWeightData()` | 记录按 id + `modifiedAt`；身高跟随设置 LWW（保存体重数据会 bump `settingsModifiedAt`，因此清空身高会同步）；提醒/设置 LWW |
| `images/*` | `_syncImages()` | 添加式双向，但只针对引用的图像 |

由 `TodoStorage.setStoragePath()` 移动的文件是 `todo_data.json`、`finance_data.json`、`exchange_rates.json`、`intimacy_data.json`、`weight_data.json` 和 `webdav_config.json`。`storage_config.json` 总是留在默认应用目录。`images/`、`backups/` 和 `.sync_base/` 等目录不被那个文件列表移动。

完整字段级合并语义（包括泛型 `mergeRecords` 三方引擎和 `CycleRecord`/`DailyCompletionLog` 的删除-vs-并集规则）在 [三方合并](algorithms/three-way-merge.md) 中。

## 重试、心跳和唤醒锁

- **`_syncing`** 是防止并发同步运行的静态守卫。
- **写入前重新读取本地文件**，检测网络 I/O 期间发生的保存。
- **逐文件错误被累积**，使一个格式错误的数据文件不阻塞所有文件。
- **数据 JSON 上传是 `.lock` 下的完整文件强制 PUT**；只有 `.lock` 写入/删除用 ETag 前置条件，弱 ETag 绝不用作那些锁前置条件。
- **`WebDAVService.consumeLocalDataChanged()`** 告诉 `AutoSyncService` 在同步写入本地文件后通知 UI 页面重载。
- **图像同步是引用门控的**：只同步 `finance_data.json` 或 `intimacy_data.json` 中引用的图像；孤儿图像被忽略。单个图像传输失败是非致命警告，经 `SyncResult.warnings` 浮出。
- 远程图像目录列表在任何失败时返回 `null`；`_syncImages` 随后跳过图像阶段并给出可见警告，而不是把未知的远程状态当作空（这以前曾在瞬态 PROPFIND 失败后导致每个被引用图像都被重新上传）。下载的图像设置本地数据变更标志，使 UI 页面即使数据 JSON 本身没变也会重载。
- **重试：** 瞬态网络失败（socket/超时/客户端错误和 HTTP 5xx）在数据 GET/PUT、字节 GET/PUT 和 PROPFIND 列表上最多重试 2 次额外尝试，带 1s/2s 退避。`.lock` 写入绝不重试，使重试的 create-only PUT 不可能误报锁争用；4xx 响应绝不重试。
- **心跳：** 数据或图像 PUT 在途时，持有的 `.lock` 每 20 秒心跳刷新（`_withLockHeartbeat`），使比 60 秒锁 TTL 更慢的传输不可能让另一客户端把锁当作过期并并发上传。心跳失败被吞掉，绝不中止在途传输。
- **进度：** `WebDAVService.progress` 是发布 connecting/downloading/merging/uploading 阶段（带逐文件和逐图像计数）的 `ValueNotifier<SyncProgress>`（`sync_progress.dart`）。服务只发出原始阶段和文件名；WebDAV 页面把阶段映射为本地化文本并渲染 `LinearProgressIndicator`。
- **强制操作：** `WebDAVService.forceUpload()` 在远程 `.lock` 之下、不做任何合并或冲突检查地覆盖远程数据文件并上传被引用图像，然后保存基线快照。`WebDAVService.forceDownload()` 替换本地数据文件（先 JSON 校验、原子写入）并下载被引用图像，不合并，保存基线快照，并设置本地数据变更标志；它只下载、不取远程锁。两者共享 `_syncing` 守卫，并需要在 WebDAV 页面确认破坏性操作对话框。手动同步或强制操作后，WebDAV 页面调用 `AutoSyncService.notifyLocalDataChangedIfNeeded()`，使打开的页面无需等待下一个后台同步就重载。
- **唤醒锁：** WebDAV 页面上的前台同步操作（手动同步、冲突最终化上传、强制上传、强制下载）通过 `shared/services/sync_wake_lock.dart`（`wakelock_plus`）持有屏幕唤醒锁。锁是引用计数的、只在没有其他功能已持有时启用（因此它绝不停掉亲密计时器页面持有的锁）、只在强制操作确认后获取、在完成/失败/取消/异常时的 `finally` 中释放，并且后台自动同步绝不用它。

## 自动同步触发

`AutoSyncService` 是与 MyAnime 和 MyDevice 对齐触发的单例 `WidgetsBindingObserver`：

- **应用启动：** 立即同步。
- **应用恢复：** 立即同步（也刷新移动提醒日程）。
- **数据保存：** `notifySaved()` 后 30 秒防抖。
- **周期计时器：** 进程存活期间每 15 分钟。
- **保存/启用完全配置的自动同步 WebDAV 设置：** 经 `requestSyncNow()` 立即同步。

自动同步在内存中记录最近的成功、失败或待定冲突状态，并在设置和 WebDAV 页面浮出。失败绝不静默吞掉；冲突绝不在后台被 LWW 自动解决。`_trySync` 持有实例级 `_syncing` 守卫，使重叠触发（计时器/恢复/防抖）被静默跳过，而不是浮出虚假的"同步已在进行中"失败横幅。`notifySaved()` 在 `start()` 之前被忽略，使早期存储写入不可能在服务观察应用生命周期前安排同步。

## 相关页面

- [三方合并](algorithms/three-way-merge.md) — 泛型合并引擎和逐文件策略的完整细节。
- [同步演练](examples/sync-walkthrough.md) — 混合解决映射规则跨两个冲突模块的实例演练。
- [备份与恢复](backup-restore.md) — 恢复备份如何与自动同步交互（首次文件写入前禁用、之后提议强制上传）。

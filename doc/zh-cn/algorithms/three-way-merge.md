# 三方合并

来源：`lib/shared/services/sync_merge.dart`。本页记录泛型 `mergeRecords` 引擎以及五个数据文件各自如何使用它。它在整体同步流程中的位置和跨模块混合解决映射安全规则见 [WebDAV 同步](../sync.md)。

## 泛型 `mergeRecords<T>` 引擎

```dart
RecordMergeResult<T> mergeRecords<T>({
  required List<T> local,
  required List<T> remote,
  required List<T>? base,
  required String Function(T) getId,
  required DateTime Function(T) getModifiedAt,
  required String Function(T) getDisplayName,
  bool autoResolve = false,
  String Function(T)? serialize,
})
```

对出现在 `local`、`remote` 或 `base`（上次同步快照）中的每个记录 id，比较三侧：

- **两侧都有记录，且存在基线（真正的三方）：**
  - `localChanged = local.modifiedAt.isAfter(base.modifiedAt)`，`remoteChanged = remote.modifiedAt.isAfter(base.modifiedAt)`。
  - **只有本地变化** → 用本地。**只有远程变化** → 用远程。**都没变化** → 用本地（任意但确定，因为等价）。
  - **两侧都变化：**
    - 提供了 `serialize` 且 `serialize(local) == serialize(remote)`——即两侧虽然都提升了 `modifiedAt` 但最终逐字节相同（这可能发生在早前失败上传留下过期基线之后）——静默合并、无冲突。
    - 否则 `autoResolve` 为 true（后台自动同步的避免冲突模式）——按 `modifiedAt` 最后写入者胜出。
    - 否则——真正的双向冲突，作为 `RecordConflict<T>` 返回给调用方供用户手动解决。
  - **不存在基线**（首次同步，或两侧独立创建了同 id）→ 按 `modifiedAt` 最后写入者胜出。
- **只有本地有记录：**
  - 它也曾在 `base` 中 → 远程侧删除了它。本地在基线时间戳之后被修改则保留本地修改（对同一条记录的编辑总是胜过编辑不知道的删除）；否则排除它（真正的、无竞争的删除）。
  - 它从未在 `base` 中 → 本地新增；包含它。
- **只有远程有记录：** 前一情形的镜像（基线后远程编辑胜过本地删除；全新远程记录被包含）。
- **两侧都没有，但基线有：** 两侧都删除 → 排除，无冲突。

这产生带 `merged: List<T>` 和 `conflicts: List<RecordConflict<T>>` 的 `RecordMergeResult<T>`。

## 逐文件合并函数（同步数据参考）

每个数据文件合并函数（`mergeTodoData`、`mergeFinanceData`、`mergeIntimacyData`、`mergeWeightData`）对该文件中的每个记录集合调用一次 `mergeRecords<T>`，然后按 `settingsModifiedAt` 最后写入者胜出单独合并文件的非记录设置。从 `AGENTS.md` 复制：

| 文件 | 合并函数 | 合并策略 |
| --- | --- | --- |
| `todo_data.json` | `mergeTodoData()` | 每日/一次性记录按 id + `modifiedAt`；每日日志并集；每日评分按天 LWW；设置 LWW |
| `finance_data.json` | `mergeFinanceData()` | 账户/分类/交易/订阅按 id + `modifiedAt`；设置 LWW |
| `exchange_rates.json` | `mergeExchangeRateJson()` | 快照并集；更新的有效当前快照胜出（解析不到快照的当前 id 被忽略）；更新的 `lastFetchedAt` 胜出 |
| `intimacy_data.json` | `mergeIntimacyData()` | 伴侣/玩具/姿势/记录/周期记录按 id + `modifiedAt`（伴侣 `body` 搭其伴侣记录同行）；计时器历史按开始并集；计时器会话按 `timerSessionModifiedAt` LWW；`userBody` 按 `userBodyModifiedAt` LWW；设置 LWW |
| `weight_data.json` | `mergeWeightData()` | 记录按 id + `modifiedAt`；身高跟随设置 LWW（保存体重数据会 bump `settingsModifiedAt`，因此清空身高会同步）；提醒/设置 LWW |
| `images/*` | `_syncImages()` | 添加式双向，但只针对引用的图像 |

`mergeExchangeRateJson`（`lib/shared/services/sync_merge.dart`）是特例：它完全不经过 `mergeRecords`，因为汇率快照永远不会冲突——它把 `local.snapshots` 和 `remote.snapshots` 并集为一个映射（`{...local.snapshots, ...remote.snapshots}`），然后取 `createdAt` 更晚的那侧*当前*快照作为合并的 `currentSnapshotId`（在自己的侧解析不到任何快照的当前 id 被忽略而不是传播），并取两个 `lastFetchedAt` 中较晚者。

## 特定容器的删除/并集语义

- **`DailyCompletionLog`**（待办）：`DailyCompletionLog.merge(a, b)`——对任一日志中存在的每个日期，合并后的已完成任务 id 集（以及单独地、已完成子任务 id 集）是两侧该日期集合的**并集**。任一台设备上标记完成的任务在合并后保持完成；此路径没有"未完成"传播——只有显式切换改变完成状态，而切换会 bump 那条记录自己的 `modifiedAt`，因此它改走普通逐记录 `Task` 合并。
- **`DailyScoreLog`**（待办）：按天独立合并，取 `DailyScoreEntry.modifiedAt` 更新的那一侧（平局偏向本地）。显式零分条目是真实条目，不是"缺席"，因此一台设备上刻意的重置为零与任何其他值一样，胜过另一侧更早的非零分数。
- **`CycleRecord`**（亲密）：走以 `id` 为键的普通 `mergeRecords<CycleRecord>` 路径，带 `serialize: (x) => jsonEncode(x.toJson())`，使相同内容记录绝不产生虚假冲突。因为周期记录**只有增/删**（没有编辑流程——UI 只创建或移除开始日期记录），泛型"一侧删除、另一侧未变 → 排除"规则正是周期删除传播：只要另一台设备没有独立触碰同一条记录 id，在一台设备上删除周期开始记录就会在合并后移除它。

## 相关页面

- [WebDAV 同步](../sync.md) — 这些合并函数如何融入完整十步同步流程，以及一次跨多个文件解决冲突的跨模块混合解决映射安全规则。
- [同步演练](../examples/sync-walkthrough.md) — 一次在两个不同文件中出现真正双向冲突的实例演练。
- [数据格式](../data-formats.md) — 每个合并函数读取的精确字段。

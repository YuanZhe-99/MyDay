# 同步演练：一次跨模块冲突

[十步 WebDAV 同步流程](../sync.md)在**两个不同数据文件中同时**命中真正双向冲突的实例演练，以及[混合解决映射安全规则](../sync.md#the-cross-module-mixed-resolutions-map-safety-rule)如何防止它崩溃或静默丢弃数据。这是说明性的，根据 `lib/shared/services/sync_merge.dart` 和 `webdav_service.dart` 的 `finalizePendingSync` 中记录的合并行为构建——不是真实运行的逐字转录。

## 设置

两台设备，**手机**和**笔记本**，都在 `T0` 最后同步。两者的 `.sync_base/` 快照都匹配 `T0` 时的远程状态。

- **财务：** 两台设备都有相同的 `Account` "Checking"（id `acc-1`），`modifiedAt: T0`。
- **亲密：** 两台设备都有相同的 `Partner` "Alex"（id `partner-1`），`modifiedAt: T0`。

## 分歧（离线，之间无同步）

- **手机**，在 `T1`（`T0` 之后）：用户编辑 Checking 账户的币种。`Account(id: 'acc-1', ..., modifiedAt: T1)`。
- **笔记本**，在 `T2`（`T0` 之后，独立于手机）：用户编辑同一账户的 `bankOrApp` 字段。`Account(id: 'acc-1', ..., modifiedAt: T2)`。
- **手机**，也在 `T1`：用户编辑 Alex 的关系 `endDate`（标记分手）。`Partner(id: 'partner-1', ..., modifiedAt: T1)`。
- **笔记本**，也在 `T2`：用户编辑 Alex 的 `emoji`。`Partner(id: 'partner-1', ..., modifiedAt: T2)`。

自 `T0` 以来两台设备都没有与对方同步，因此谁都不知道对方的编辑。

## 同步尝试（笔记本先同步，然后手机）

**笔记本在 `T3` 同步。** 它获取 `.lock`，下载远程 `finance_data.json` 和 `intimacy_data.json`（都还在 `T0` 状态，因为手机还没同步），并对照自己的 `.sync_base/`（也是 `T0`）合并。因为每条记录相对基线和远程只有笔记本变化，`Account acc-1` 和 `Partner partner-1` 都**无冲突**合并——笔记本的 `T2` 版本胜出。笔记本在仍有效的锁下强制上传两个合并文件，把基线快照更新到新 `T2` 状态，并释放锁。

**手机在 `T4` 同步。** 它下载现在是 `T2` 的远程文件。自己的 `.sync_base/` 仍在 `T0`（它之后没同步过）。运行 `mergeRecords`：

- 对 `acc-1`：`local.modifiedAt (T1) > base.modifiedAt (T0)` → `localChanged = true`。`remote.modifiedAt (T2) > base.modifiedAt (T0)` → `remoteChanged = true`。**两侧都变化** → 因为两侧碰了不同字段但都提升了 `modifiedAt`，`serialize(local) != serialize(remote)`（JSON 不同——币种 vs bankOrApp），所以这是**真正的冲突**，不是可自动合并的相同内容情形。
- 对 `partner-1`：同样推理——**两侧都变化**、不同字段、真正冲突。

因为手机的同步是 `autoResolve: false` 的手动/自动同步运行，两个冲突都被收集，而不是被最后写入者胜出静默解决。`mergeFinanceData` 返回 `accountConflicts` 中有一条（id `acc-1`）的 `FinanceMergeResult`；`mergeIntimacyData` 返回 `partnerConflicts` 中有一条（id `partner-1`）的 `IntimacyMergeResult`。两次合并发生在*同一*同步运行中，因为财务和亲密是独立合并但在一个 `PendingSync` 中一起解决的独立文件。

## 一趟解决两个冲突

WebDAV 页面在一个屏幕中向用户显示列出**两个**冲突——财务账户和亲密伴侣——的 `SyncConflictDialog`。用户选择，比如说，财务账户"保留本地"、亲密伴侣"保留远程"。UI 构建一个以冲突 id 为键的单一组合解决映射：

```dart
final resolutions = <String, dynamic>{
  'acc-1': phoneLocalAccount,       // Account — user chose local
  'partner-1': laptopRemotePartner, // Partner — user chose remote
};
```

注意这一个 `Map<String, dynamic>` 在不同键下混着 `Account` 值和 `Partner` 值——没有办法给它一个单一具体值类型。

## 为什么映射不能批量转换

`WebDAVService.finalizePendingSync(config, pending, resolutions)` 调用（除其他外）：

```dart
pending.financeMerge!.buildResolved(resolutions)
pending.intimacyMerge!.buildResolved(resolutions)
```

每个 `buildResolved` 内部调用自己的 `_resolveList<T>(merged, conflicts, resolutions)`，它只读取**那个文件自己**产生的冲突 id 的 `resolutions[c.id]`，并在使用前类型检查每个值——如（以 Weight 为例，与财务和亲密同形）：

```dart
for (final c in recordConflicts) {
  final resolved = resolutions[c.id];
  result.add(resolved is WeightRecord ? resolved : c.localRecord);
}
```

因此 `FinanceMergeResult.buildResolved` 只查看 `resolutions['acc-1']` 并检查 `resolved is Account`；它绝不碰 `resolutions['partner-1']`，即使碰了，`is Account` 检查也会直接失败并回退本地记录，而不是抛类型转换异常。`IntimacyMergeResult.buildResolved` 对 `'partner-1'` 做镜像查找，带 `is Partner` 检查。

如果代码改为在交给财务合并前做类似 `resolutions.cast<String, Account>()` 或 `resolutions as Map<String, Account>` 的事，那个转换会在碰到键 `'partner-1'` 的 `Partner` 值的那一刻抛出——这正是 `AGENTS.md` 注明此规则是为了防止的崩溃（"那会在跨模块冲突时崩溃"）。通过让每个模块对每个 id 做自己的窄 `is T` 检查，两个冲突在同一 `finalizePendingSync` 调用中正确解决，对给定文件缺失或类型错误的条目默认该文件的本地记录，而不是被丢弃。

## 相关页面

- [WebDAV 同步](../sync.md) — 完整十步流程和散文形式的安全规则。
- [三方合并](../algorithms/three-way-merge.md) — 上面 `Account` 和 `Partner` 都使用的 `mergeRecords` 引擎。
- [数据格式](../data-formats.md) — `Account` 和 `Partner` 字段定义。

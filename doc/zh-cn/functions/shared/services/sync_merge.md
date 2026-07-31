# lib/shared/services/sync_merge.dart

**拆分文件。** 通用三方记录合并——`mergeRecords<T>`、`RecordConflict<T>` 和 `RecordMergeResult<T>`——移到 `myapps_data` 包（`lib/src/merge/sync_merge.dart`）并在此重新导出。MyDay 的逐模块合并包装留下。

包签名是 MyDevice 的超集：它添加一个可选 `mergeUnknownFields` 回调。MyDay 不传它——未知字段在写入时从 [`../utils/json_preservation.md`](../utils/json_preservation.md) 的模式重新应用——因此行为与抽取前相同。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `SyncConflictInfo` | 类 | A | 供显示的聚合冲突信息。 |
| `TodoMergeResult` / `mergeTodoData(...)` | 类 + 函数 | A | 每日和一次性任务（两个冲突容器）。 |
| `FinanceMergeResult` / `mergeFinanceData(...)` | 类 + 函数 | A | 账户、类别、交易、订阅。 |
| [`mergeExchangeRateJson(local, remote)`](#exchangerates) | 函数 | A | 整文件并集合并；绝不冲突。 |
| `IntimacyMergeResult` / `mergeIntimacyData(...)` | 类 + 函数 | A | 伴侣、玩具、姿势、记录、周期记录；三个独立 LWW 时钟，排序设置和 `chartSettings` 在 `settingsModifiedAt` 那个上。 |
| `WeightMergeResult` / `mergeWeightData(...)` | 类 + 函数 | A | 体重记录。 |
| `RecordConflict<T>` / `RecordMergeResult<T>` / `mergeRecords<T>` | 重新导出 | A | 通用引擎，来自包。 |

**对账：** 这是**分组**页——上面 7 行覆盖文件的 23 个 `/// Purpose:` 声明，因为每个模块的 `…MergeResult` 类（其构造函数、`hasConflicts`、`buildResolved` 和共享 `_resolveList`）与其 `merge…Data` 函数在同一行文档化。[INDEX.md](../../INDEX.md) 数行而非底层声明，因此列出 7。

## 文档

### `mergeExchangeRateJson(localJson, remoteJson)` <a id="exchangerates"></a>
- **返回：** 合并 JSON 字符串。
- **备注：** 异类——整文件字符串合并而非逐记录合并，这正是其注册表条目产生完全无冲突路径 `ModuleMergeOutcome` 的原因。它也是唯一报告索引上传进度的模块。

### 逐模块合并包装
- **备注：** 各返回携带其合并列表、冲突容器和重建最终模型所需数据的应用类型化结果。同步引擎把它们作为不透明 `state` 携带，这正是冲突对话框仍收到真实模型对象的方式。`buildResolved` 取以记录 ID 键控的扁平 `Map<String, dynamic>` 并按运行时类型消歧，这正是终定时一个扁平解析映射能服务每个模块的原因。
- **财务：** 强制余额迁移**不**在此文件。它在合并后和冲突解决后运行，作为模块 `postMergeTransform` 接在 [`../../app/data_modules.md`](../../app/data_modules.md)。

## 通用引擎文档在哪里

`packages/myapps_data/doc/en-us/functions/src/merge/sync_merge.md`。

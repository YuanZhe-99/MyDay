# lib/shared/services/import_export_service.dart

**共享引擎的门面。** 整个文件现在委托给 `myapps_data` 包（`lib/src/data/zip_transfer.dart`）。MyDay 无 Markdown 导出，因此无其他东西留下。

MyDay 已经是三个应用中对导入最严格的，引擎的**默认正是它的行为**——拒绝未知条目、严格 UTF-8 解码、写任何东西前验证每个负载、原子写。这里不设任何宽松旋钮。其他两个应用必须采用引擎的固定遍历拒绝；MyDay 已经有了。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`exportZIP(destDir)`](#exportzip) | 静态方法 | A | 写 `myday_backup_<stamp>.zip`。 |
| [`importZIP(filePath)`](#importzip) | 静态方法 | A | 从导出恢复数据和图像。 |

**对账：** `grep -c 'Purpose:' lib/shared/services/import_export_service.dart` 报告 3，比上面 2 行多一个。第三个是第 1 行整体描述门面的**文件级**库注释；它位于 `import` 块上方而非声明上方，因此无行。

## 文档

### `exportZIP(destDir)` <a id="exportzip"></a>
- **返回：** `Future<String?>` — 写入路径，失败时 null。
- **副作用：** 写 `myday_backup_<yyyyMMdd_HHmmss>.zip`。
- **备注：** 按注册表顺序捆绑注册表的五个数据文件加扁平 `images/<basename>` 条目。配置、`.sync_base/` 和 `backups/` 绝不包含。设置导入/导出只支持 ZIP。

### `importZIP(filePath)` <a id="importzip"></a>
- **返回：** `Future<bool>` — ZIP 被验证并导入时 true。
- **副作用：** 原子替换允许列表数据文件和图像。
- **备注：** 只提取允许列表条目、每个条目必须解析到应用目录内，整个存档在任何东西写入前被分类和验证——因此被拒存档让应用数据不受影响而非半导入。验证器是取自注册表的每个模块自己的解析器，这是 `DataFileSafety.writeValidatedDataJson` 曾内联提供的行为。

## 引擎文档在哪里

`packages/myapps_data/doc/en-us/functions/src/data/zip_transfer.md`。

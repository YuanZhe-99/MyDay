# lib/shared/services/data_file_safety.dart

**拆分文件。** 通用原子 tmp-然后-重命名写入器移到 `myapps_data` 包（`lib/src/storage/atomic_io.dart`）并经此处薄包装重新导出。验证分发留下，但现在读取模块注册表而非自己的硬编码文件列表和对模型解析器的 `switch`。

`DataFileValidationException` 也以相同形态移到包——`fileName`、`message` 和 `'$fileName: $message'` `toString()`——并重新导出，因此既有捕获点和它们浮出的消息不变。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`DataFileSafety.dataFileNames`](#datafilenames) | 静态字段 | A | 已知数据文件名，从注册表派生。 |
| [`validateDataJson(fileName, jsonContent)`](#validatedatajson) | 静态方法 | A | 除非负载为该文件解析，否则抛出。 |
| [`writeValidatedDataJson(file, jsonContent)`](#writevalidateddatajson) | 静态方法 | A | 验证，然后原子替换。 |
| [`atomicWriteString(file, content)`](#atomicwrites) | 静态方法 | A | 原子文本替换。 |
| [`atomicWriteBytes(file, bytes)`](#atomicwrites) | 静态方法 | A | 原子字节替换。 |
| `DataFileValidationException` | 重新导出 | A | 类型化验证失败，来自包。 |

## 文档

### `dataFileNames` <a id="datafilenames"></a>
- **种类：** 静态字段，`Set<String>`
- **备注：** 从 `todoModuleRegistry` 派生。这曾是同一列表的五个独立硬编码副本之一；五分之四现已消失。

### `validateDataJson(fileName, jsonContent)` <a id="validatedatajson"></a>
- **抛出：** 名称不在注册表时 `DataFileValidationException(fileName, 'unsupported data file')`；否则包装模块解析器抛出的任何东西。
- **备注：** 行为和消息不变；只有分发机制从对文件名的 `switch` 移到注册表查找，因此添加模块不再意味编辑此文件。

### `writeValidatedDataJson(file, jsonContent)` <a id="writevalidateddatajson"></a>
- **副作用：** 按目标基名验证，然后原子替换文件。
- **备注：** 被备份恢复和 ZIP 导入使用，使无效负载绝不可能落到磁盘。

### `atomicWriteString` / `atomicWriteBytes` <a id="atomicwrites"></a>
- **副作用：** 需要时创建父目录、暂存到同目录临时文件、flush、然后重命名覆盖目标；失败时临时文件尽力清理。
- **备注：** 现在是对包实现的一行委托。

## 引擎文档在哪里

`packages/myapps_data/doc/en-us/functions/src/storage/atomic_io.md` 和 `packages/myapps_data/doc/en-us/functions/src/modules/data_module.md`。

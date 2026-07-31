# lib/shared/utils/json_preservation.dart

**拆分文件。** 通用引擎——`JsonPreservation`、`JsonPreservationSchema` 和 `JsonListPreservation`——移到 `myapps_data` 包（`lib/src/json/json_preservation.dart`）并在此重新导出，使每个既有导入继续编译。

**字段模式留下了。** 它们命名 MyDay 自己的数据字段，共享包绝不能知道。它们经 [`../../app/data_modules.md`](../../app/data_modules.md) 交给同步引擎，后者把它们接入每个模块的预上传变换。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `JsonPreservation` / `JsonPreservationSchema` / `JsonListPreservation` | 重新导出 | A | 通用引擎，来自包。 |
| [`dataFilePreservationSchemas`](#schemas) | 常量 | A | 文件名到模式，覆盖全部五个数据文件。 |
| `_todoDataSchema`、`_financeDataSchema`、`_exchangeRateDataSchema`、`_intimacyDataSchema`、`_weightDataSchema` 及其嵌套项模式（含 `_accountPickerSettingsSchema` 和 `_intimacyChartSettingsSchema`） | 常量 | B | 逐模型已知键声明。 |

**对账：** 这是**分组**页——文件只有 1 个 `/// Purpose:` 块，但上面 3 行，因为重新导出引擎类型和私有 `const` 模式是不带 `Purpose:` 块的真实声明，各归一行。[INDEX.md](../../INDEX.md) 数行而非 `Purpose:` 块，因此列出 3（2 个 Tier A）。

## 文档

### `dataFilePreservationSchemas` <a id="schemas"></a>
- **种类：** 常量映射，文件名到 `JsonPreservationSchema`
- **用途：** 告诉保留引擎每个数据文件合法知道哪些键，使其他一切被当作要向前携带的未知字段。
- **备注：** MyDay 的合并输出**不**自我保留——不同于把 `extraJson` 烘焙进模型的 MyAnime 和 MyDevice。未知字段在写入时按 基础/本地/远程快照顺序 重新应用。这正是注册表每个结构化模块设 `preUploadTransform` 的原因。给模型加字段意味着在这里给匹配模式加字段，否则它会被当作未知。

## 引擎文档在哪里

`packages/myapps_data/doc/en-us/functions/src/json/json_preservation.md`。

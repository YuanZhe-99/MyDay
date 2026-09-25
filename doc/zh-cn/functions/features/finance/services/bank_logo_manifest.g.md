# lib/features/finance/services/bank_logo_manifest.g.dart

生成文件——不要手工编辑。它保存标志清单：一个常量映射，从银行预设带国家限定的键映射到完整版构建为其附带的内置标志资源。它由 `tool/gen_bank_logo_manifest.dart` 写入（`tool/apply_bank_logo_choices.dart` 调用同一个生成器，也会写入），并在商店版构建之前由 `tool/strip_bank_logos.dart` 重写为空映射。两个写入方共用 `tool/bank_logo_manifest_writer.dart` 中的 `renderBankLogoManifest`，其输出按键排序且确定，因此对未变的标志集合重新生成不会产生差异。标志工作流见 [财务](../../../../features/finance.md#bankpresetservice)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`bankLogoAssets`](#banklogoassets) | 顶层 `const Map<String, String>` | A | 把预设键（`<country>/<id>`）映射到其内置标志资源。 |

**对账：** `grep -c '/// Purpose:' lib/features/finance/services/bank_logo_manifest.g.dart` 返回 1，与上面唯一一行匹配。文件的 `//` 头部行（生成器名称、商店版构建说明、标志数量）是普通注释，不是声明。

## 文档

### `const Map<String, String> bankLogoAssets` <a id="banklogoassets"></a>
- **种类：** 顶层编译期常量（生成）
- **来源：** `lib/features/finance/services/bank_logo_manifest.g.dart`（第 11 行）
- **用途：** 把银行预设键映射到为其附带的内置标志资源。
- **输入：** 无。
- **返回：** `Map<String, String>` — 键是 `BankPreset.key` 值（`<country>/<id>`，如 `us/chase`）；值是资源路径 `assets/bank_logos/<country>_<id>.<svg|png>`。没有审核过标志的预设直接不出现。
- **副作用：** 无。
- **算法：** 运行时无。生成时 `collectBankLogos` 列出 `assets/bank_logos/`，把每个文件主名 `<country>_<id>` 映射回 `assets/banks.json` 中的预设；文件不对应任何预设、扩展名不是 `.svg`/`.png`，或与另一文件的键重复时抛出 `FormatException`——因此多余的文件绝不会在无人察觉时随包发布。
- **用法：**
  ```dart
  String? get bundledLogoAsset =>
      bundledBankLogosEnabled ? bankLogoAssets[key] : null;
  ```
  （`lib/features/finance/services/bank_preset_service.dart:58-59`，唯一的读取方。）
- **备注：** 键带国家限定，因为预设 id 会在不同国家重复（`icbc`、`hsbc`、`vtb`……）。在商店版构建中该映射为空（剥离步骤重写了文件），并且 `bundledLogoAsset` 也会因 `bundledBankLogosEnabled` 返回 null，因此查找由两种独立手段关闭。列出的资源仍可能加载失败，所以每个调用方都会回退到网络链。

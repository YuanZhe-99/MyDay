# lib/app/build_flavor.dart

以三个编译期常量表示本二进制的发行构建风味——完整版或商店版。这是 `lib/` 下唯一读取构建风味的地方：必须在商店版构建中表现不同的代码从这里导入 `isStoreBuild`（或按意图命名的别名，如 `bundledBankLogosEnabled`），不读取任何其他信号。目前构建风味只控制一项行为，即 [`BankPreset.bundledLogoAsset`](../features/finance/services/bank_preset_service.md#bundledlogoasset) 中的内置银行标志查找。该标志只改变查找；把商店版排除的字节挡在包外是 CI 剥离步骤的职责（见 [CI/CD](../../ci-cd.md) 和 [架构](../../architecture.md)）。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `dartDefineFlavor` | 顶层 `const String` | B | `--dart-define=FLAVOR=` 的值（未传时为空）。 |
| [`isStoreBuild`](#isstorebuild) | 顶层 `const bool` | A | 本二进制是否为商店版发行。 |
| `bundledBankLogosEnabled` | 顶层 `const bool` | B | `!isStoreBuild`，为内置银行标志开关命名。 |

**对账：** `grep -c '/// Purpose:' lib/app/build_flavor.dart` 返回 3，与上面 3 行精确匹配。文件开头的 `library;` 文档注释不带 `Purpose:` 块，也不是声明。

## 文档

### `const bool isStoreBuild` <a id="isstorebuild"></a>
- **种类：** 顶层编译期常量
- **来源：** `lib/app/build_flavor.dart`（第 22 行）
- **用途：** 判断本二进制是否为商店版发行。
- **输入：** 无（从构建读取：来自 `package:flutter/services.dart` 的 `appFlavor`，以及 `dartDefineFlavor`）。
- **返回：** `bool` — 当 `appFlavor == 'store'`（Android `--flavor store`）**或** `dartDefineFlavor == 'store'`（`--dart-define=FLAVOR=store`）时为 `true`；否则为 `false`，包括两者都未设置的普通 `flutter run` / `flutter test`。
- **副作用：** 无。
- **算法：** 对两个构建风味通道求值的单个 `const` 布尔表达式。任一通道为 `store` 即可，因此只传 `--flavor store` 的 Android 构建和只传 dart-define 的 Windows 构建（Windows 没有 `--flavor`）都算作商店版构建。
- **用法：**
  ```dart
  const bool bundledBankLogosEnabled = !isStoreBuild;
  ```
  （`lib/app/build_flavor.dart:30`；`bundledBankLogosEnabled` 随后由 `lib/features/finance/services/bank_preset_service.dart:58-59` 中的 `BankPreset.bundledLogoAsset` 读取。）
- **备注：** 默认是完整版：完全不传构建风味的构建按完整版运行。该标志只改变行为，不会从包中移除任何资源——为此 CI 在商店版构建之前运行 `tool/strip_bank_logos.dart`。

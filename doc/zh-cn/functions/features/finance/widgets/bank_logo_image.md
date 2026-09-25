# lib/features/finance/widgets/bank_logo_image.dart

`BankLogoImage` 在银行预设选择器中通过三层链显示银行预设的标志：内置标志资源（仅限完整版构建），然后网络预览（`BankPreset.logoUrl`，即 v1.4.5 之前选择器使用的 Clearbit URL），然后调用方提供的回退组件（选择器传入银行首字母）。它是只用于选择器的组件：用户真正保留的标志由 `_fetchBankIcon` 复制进 `images/`，并从那里经 [`StoredImage`](../../../shared/widgets/stored_image.md) 渲染。见 [财务](../../../../features/finance.md#bankpresetservice)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `BankLogoImage({...})` | const 构造函数（`BankLogoImage`） | B | 创建银行标志视图（`bank`、`fallback`、`size` 默认 32）。 |
| `createState` | 方法（`BankLogoImage`） | B | 创建只加载一次内置资源的 `_BankLogoImageState`。 |
| `initState` | 方法（`_BankLogoImageState`） | B | 若本构建列出了内置资源，开始加载它。 |
| `didUpdateWidget` | 方法（`_BankLogoImageState`） | B | 回收的列表块被复用于另一个预设时重新加载。 |
| [`_load`](#load) | 静态方法（`_BankLogoImageState`） | A | 加载资源字节，把任何失败映射为 null。 |
| `_network` | 方法（`_BankLogoImageState`，组件辅助） | B | 构建网络预览，没有域名时构建回退组件。 |
| [`build`](#build) | 方法（`_BankLogoImageState`） | A | 构建内置标志、网络预览或回退组件。 |

**对账：** `grep -c '/// Purpose:' lib/features/finance/widgets/bank_logo_image.dart` 返回 7，与上面 7 行精确匹配（2 个 Tier A，5 个 Tier B）。

## 文档

### `static Future<ByteData?>? _load(String? key)` <a id="load"></a>
- **种类：** `_BankLogoImageState` 的私有静态方法
- **来源：** `lib/features/finance/widgets/bank_logo_image.dart`（第 69 行）
- **用途：** 加载内置资源的字节，把任何失败变为 null 结果。
- **输入：** `key` — 预设的 `bundledLogoAsset`；本构建没有它的内置标志时为 null（商店版构建中总为 null）。
- **返回：** `Future<ByteData?>?` — `key` 为 null 时返回 null *future*（无需加载）；否则返回一个以字节完成的 future，资源包抛出异常时以 null 完成。
- **副作用：** 经 `rootBundle.load` 读取资源包。
- **算法：** `key` 为 null 时返回 null；否则 `rootBundle.load(key).then<ByteData?>((d) => d, onError: (_) => null)`。
- **用法：**
  ```dart
  _asset = _load(widget.bank.bundledLogoAsset);
  ```
  （`lib/features/finance/widgets/bank_logo_image.dart:48`，在 `initState` 中；以及第 60 行，在 `didUpdateWidget` 中 `oldWidget.bank.key != widget.bank.key` 时。）
- **备注：** 刻意加载原始字节（而不是 `SvgPicture.asset`）：文件缺失的清单条目会变成 null 结果，因此列表块安静地降级为网络预览，而不是抛出异常。

### `Widget build(BuildContext context)` <a id="build"></a>
- **种类：** `_BankLogoImageState` 的方法
- **来源：** `lib/features/finance/widgets/bank_logo_image.dart`（第 97 行）
- **用途：** 内置标志加载成功时渲染它，否则渲染网络预览，再否则渲染回退组件。
- **输入：** `context`；组件的 `bank`、`size`、`fallback`。
- **返回：** `Widget`。
- **副作用：** 除 `initState` 中开始的资源加载和 `_network` 内的 `Image.network` 请求外无。
- **算法：**
  1. 没有待决的资源 future（没有内置标志）→ `_network()`：以 `size` × `size`、`BoxFit.cover` 显示 `Image.network(bank.logoUrl)`，其 `errorBuilder` 显示 `fallback`；`logoUrl` 为空时直接显示 `fallback`。
  2. 否则使用 `FutureBuilder<ByteData?>`：加载中显示一个 `size` × `size` 的空盒子。
  3. 字节为 null（加载失败）→ `_network()`。
  4. 有字节 → 一个白色 `size` × `size` 容器，内边距 12%，内含 `SvgPicture.memory`（资源键以 `.svg` 结尾，不区分大小写）或 `Image.memory`，两者都用 `BoxFit.contain`；任一解码器的 `errorBuilder` 都回退到 `_network()`。
- **用法：**
  ```dart
  child: ClipOval(
    child: BankLogoImage(bank: bank, size: 40, fallback: initial),
  ),
  ```
  （`lib/features/finance/widgets/bank_preset_picker.dart:276-278`，`_BankTile.build` 的前导头像；`initial` 是以品牌色显示的银行首字母。）
- **备注：** 内置标志总是以 `contain` 放在白底上：许多 SVG 标志是为浅色背景绘制的文字标志，这样在深色模式下也能保持完整、清晰。网络层保留 v1.4.5 之前的外观（`cover`，无白底）。

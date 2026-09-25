# lib/shared/widgets/stored_image.dart

用正确的解码器渲染应用存储（`images/`）中的图像文件：`.svg` 文件用 `SvgPicture.file`，其他一律用 `Image.file`。`StoredImage` 是矩形视图；`StoredImageAvatar` 是圆形头像，取代以前的 `CircleAvatar(backgroundImage: FileImage(...))` 写法——那种写法无法显示 SVG，因为 SVG 无法提供 `ImageProvider`。v1.4.5 加入，因为复制进 `images/` 的内置银行标志可能是 SVG（见 [`ImageService.copyAssetImage`](../services/image_service.md#copyassetimage)）。财务模块中显示存储的账户或订阅图像的每个位置都使用这些组件；亲密模块仍直接使用 `FileImage`/`Image.file`，因为它的图像只来自文件选择器。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `isSvgFile` | 顶层函数 | B | 存储的图像文件是否为 SVG（`.svg` 扩展名，不区分大小写）。 |
| `StoredImage(...)` | const 构造函数（`StoredImage`） | B | 创建存储图像视图（`file`、`width`、`height`、`fit` 默认 `cover`）。 |
| [`StoredImage.build`](#storedimage-build) | 方法（`StoredImage`） | A | 为 `file` 构建 SVG 或位图图像。 |
| `StoredImageAvatar(...)` | const 构造函数（`StoredImageAvatar`） | B | 创建圆形头像（`file`、`radius` 默认 20、`backgroundColor`）。 |
| [`StoredImageAvatar.build`](#storedimageavatar-build) | 方法（`StoredImageAvatar`） | A | 构建裁剪后的圆形头像。 |

**对账：** `grep -c '/// Purpose:' lib/shared/widgets/stored_image.dart` 返回 5，与上面 5 行精确匹配（2 个 Tier A，3 个 Tier B）。

## 文档

### `Widget build(BuildContext context)`（`StoredImage`） <a id="storedimage-build"></a>
- **种类：** `StoredImage` 的方法
- **来源：** `lib/shared/widgets/stored_image.dart`（第 41 行）
- **用途：** 按扩展名为存储的图像文件选择解码器。
- **输入：** `context`；组件的 `file`、`width`、`height`、`fit`。
- **返回：** `.svg` 文件返回 `SvgPicture.file`，否则返回 `Image.file`，两者都按给定尺寸和适配方式。
- **副作用：** 绘制时读取文件。
- **算法：**
  1. `isSvgFile(file)` → `SvgPicture.file`，其 `placeholderBuilder` 和 `errorBuilder` 都返回请求尺寸的空盒子，因此无法解析的 SVG 渲染为空白，而不是抛出异常。
  2. 否则 `Image.file(file, width:, height:, fit:)`。
- **用法：**
  ```dart
  child: StoredImage(
    snap.data!,
    width: 48,
    height: 48,
    fit: BoxFit.cover,
  ),
  ```
  （`lib/features/finance/views/accounts_page.dart:1939`，账户对话框的图像预览；另见 `lib/features/finance/widgets/add_subscription_dialog.dart:610`。）
- **备注：** 扩展名是权威的，因为 `ImageService` 总会设置它——下载时取自内容类型，`copyAssetImage` 时取自资源键，`pickAndSaveImage` 时取自所选文件。调用方保留各自的 `existsSync()` 防护；此组件只选择解码器。

### `Widget build(BuildContext context)`（`StoredImageAvatar`） <a id="storedimageavatar-build"></a>
- **种类：** `StoredImageAvatar` 的方法
- **来源：** `lib/shared/widgets/stored_image.dart`（第 83 行）
- **用途：** 把存储图像渲染为同时适用于位图和 SVG 文件的圆形头像。
- **输入：** `context`；组件的 `file`、`radius`、`backgroundColor`。
- **返回：** 一个 `CircleAvatar`，图像作为经 `ClipOval` 裁剪的子组件。
- **副作用：** 除 `StoredImage` 外无。
- **算法：**
  1. SVG → `CircleAvatar(backgroundColor: Colors.white)`，内含 `ClipOval`，以 `radius * 0.18` 的内边距包住一个 `2 * radius` 见方、`BoxFit.contain` 的 `StoredImage`。
  2. 位图 → `CircleAvatar(backgroundColor: backgroundColor)`，内含 `ClipOval`，包住一个 `2 * radius` 见方、`BoxFit.cover` 的 `StoredImage`——与旧的 `backgroundImage: FileImage(...)` 填充方式相同。
- **用法：**
  ```dart
  return StoredImageAvatar(
    snap.data!,
    backgroundColor: color.withValues(alpha: 0.15),
  );
  ```
  （`lib/features/finance/views/accounts_page.dart:893`，`_buildAccountAvatar`。其他调用点：`subscription_avatar.dart:69` 和 `:86`、带 `radius: 12` 的 `add_transaction_dialog.dart:437`、`subscription_detail_page.dart:396`、`finance_page.dart:1628`、`category_detail_page.dart:425`。）
- **备注：** SVG 标志常常是文字标志而非图形符号，且为浅色背景绘制，因此总是放在白色圆底上、以 `contain` 加内边距显示——在深色模式下完整、清晰——并忽略 `backgroundColor`。图像作为子组件而不是 `backgroundImage`，因为 `CircleAvatar.backgroundImage` 需要 `ImageProvider`，而 SVG 无法提供。

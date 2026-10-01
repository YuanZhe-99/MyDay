# lib/features/profile/services/avatar_image.dart

头像编辑器背后的纯图像操作（1.6.1）。每个函数都是同步且只做内存分配的，因此调用方在另一个 isolate（`Isolate.run`）中运行它，以保持界面流畅。编辑器（[`../views/avatar_editor.md`](../views/avatar_editor.md)）调用 `prepareAvatarSource` 和 `cropAvatarJpeg`；[`profile_store.md`](profile_store.md) 存储得到的 JPEG。见 [`../../../../features/profile.md`](../../../../features/profile.md#avatar-processing)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `AvatarSource` | 类与构造函数 | B | 所选图像的直立、限制尺寸的 PNG 副本（`bytes`、`width`、`height`），供编辑器使用。 |
| `avatarSourceMaxEdge` | 顶层 `const int` | B | 编辑器处理的最长边像素数（2048）。 |
| `_decode` | 顶层函数（私有） | B | 解码任意图像，不让解码器异常逸出。 |
| [`prepareAvatarSource`](#prepareavatarsource) | 顶层函数 | A | 为编辑器规范化所选图像。 |
| [`cropAvatarJpeg`](#cropavatarjpeg) | 顶层函数 | A | 裁出用户取景的正方形并编码为头像。 |
| [`squareAvatarJpeg`](#squareavatarjpeg) | 顶层函数 | A | 把任意可解码图像变成居中的正方形 JPEG（从 `profile_store.dart` 移来）。 |
| [`prepareAvatarSourceInBackground`](#background-variants) | 顶层函数 | A | 在另一个 isolate 中运行 `prepareAvatarSource`（1.6.1）。 |
| [`cropAvatarJpegInBackground`](#background-variants) | 顶层函数 | A | 在另一个 isolate 中运行 `cropAvatarJpeg`（1.6.1）。 |

`grep -c 'Purpose:'` 报告 7；`avatarSourceMaxEdge` 和 `AvatarSource` 的字段带的是普通 `///` 注释。

## _decode

- **说明：** 截断或外来数据可能让格式探测抛出异常（例如 `RangeError`）而不是返回 null；两种结果都变成 `FormatException('Not a supported image')`。

## prepareAvatarSource

- **输入：** `bytes`——所选文件；`quarterTurns`——额外的顺时针 90 度旋转次数（编辑器的旋转按钮）。
- **返回：** `AvatarSource`——已摆正（应用 EXIF）、最长边不超过 `avatarSourceMaxEdge`、编码为 PNG。
- **算法：** `bakeOrientation`，然后 `copyRotate(angle: 90 * (quarterTurns % 4))`，较大时再把长边 `copyResize` 到 2048，最后 `encodePng`。
- **说明：** 在这里烘焙方向，意味着编辑器显示的像素与 `cropAvatarJpeg` 裁剪的像素是同一批，不受平台自身 EXIF 处理影响。非图像抛出 `FormatException`。

## cropAvatarJpeg

- **输入：** `source`——来自 `prepareAvatarSource` 的字节；`x`、`y`、`side`——源图像素中的正方形；`size`——输出边长。
- **返回：** `Uint8List`——`size` x `size` 的 JPEG（质量 88）。
- **说明：** 正方形会被钳制在图像内（`side` 不超过短边，`x`/`y` 保证不越界），因此边缘处的舍入不会失败。非图像抛出 `FormatException`。

## squareAvatarJpeg

- **输入：** `bytes`、`size`。
- **返回：** `Uint8List`——JPEG 字节。
- **说明：** 非交互路径（无编辑器）：应用 EXIF 方向，并用 `copyResizeCropSquare` 取居中正方形。非图像抛出 `FormatException`。保留给想要居中裁剪的调用方和测试。

## Background variants

`prepareAvatarSourceInBackground(bytes, {quarterTurns})` 和 `cropAvatarJpegInBackground(source, {x, y, side, size})` 把这两个函数包在 `Isolate.run` 中并返回 `Future`。它们**刻意是顶层函数**：写在组件 `State` 方法里的 `Isolate.run(() => ...)` 闭包会把 `State` 及其控制器一起捕获，而这些无法发送到另一个 isolate，导致编辑器显示“无法使用此图片”。这里的闭包只捕获它的参数。编辑器只调用这两个函数；`test/profile_test.dart` 会实际运行它们。

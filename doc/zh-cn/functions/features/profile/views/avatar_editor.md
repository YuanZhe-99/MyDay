# lib/features/profile/views/avatar_editor.dart

全屏头像编辑器（1.6.1）：所选图像（或当前头像）在圆形取景框内取景——拖动移动，双指或滚轮缩放，按 90 度旋转，重置，保存。取景的正方形就是被存储的内容，因此头像始终与所见一致。由 [`profile_header.md`](profile_header.md) 打开；图像处理在 [`../services/avatar_image.md`](../services/avatar_image.md)。见 [`../../../../features/profile.md`](../../../../features/profile.md#editing)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`showAvatarEditor`](#showavatareditor) | 顶层函数 | A | 让用户给头像取景并返回结果。 |
| `AvatarEditorPage` | 组件（公开）与构造函数 | B | 编辑器页面。 |
| `AvatarEditorPage.createState` | 方法（组件生命周期） | B | 创建编辑器状态。 |
| `_AvatarEditorPageState.initState` | 方法（组件生命周期） | B | 开始准备图像。 |
| `_AvatarEditorPageState.dispose` | 方法（组件生命周期） | B | 释放变换控制器。 |
| [`_prepare`](#_prepare) | 方法（`_AvatarEditorPageState`） | A | 按当前旋转解码、摆正并限制源图尺寸。 |
| `_rotate` | 方法（`_AvatarEditorPageState`） | B | 顺时针旋转 90 度。 |
| `_reset` | 方法（`_AvatarEditorPageState`） | B | 回到初始取景。 |
| [`_save`](#_save) | 方法（`_AvatarEditorPageState`） | A | 裁出圆内所示内容并返回。 |
| [`build`](#build) | 方法（`_AvatarEditorPageState`） | A | 构建编辑器。 |
| `_CircleMaskPainter` | 类、构造函数、`paint`、`shouldRepaint` | B | 绘制带圆形镂空与轮廓线的遮罩。 |

## showAvatarEditor

- **输入：** `context`；`source`——所选图像或当前头像的字节。
- **返回：** `Future<Uint8List?>`——512 像素正方形 JPEG；用户退出时为 null。
- **副作用：** 推入一个全屏对话框路由。

## _prepare

- **副作用：** 在 `Isolate.run` 中运行 `prepareAvatarSource(bytes, quarterTurns: _turns)`，重置取景并更新忙碌与失败标志。无法解码的图像显示错误状态而不是抛出异常。

## _save

- **算法：** 读取 `InteractiveViewer` 的变换矩阵。视口的左上角和边长经矩阵（`平移 / 缩放`）和“基准尺寸到像素”的比例映射回源图像素，然后在 `Isolate.run` 中运行 `cropAvatarJpeg(... size: 512)`，路由带着 JPEG 弹出。

## build

- **返回：** 一个 `Scaffold`，标题为*调整头像*，应用栏有旋转与重置按钮和*保存*操作；主体是方形视口，内含 `InteractiveViewer`（`minScale: 1`、`maxScale: 8`、`boundaryMargin: EdgeInsets.zero`，使图像始终铺满圆），上面绘制圆形遮罩，并显示提示*拖动以移动，双指缩放或滚动鼠标滚轮以缩放。*
- **说明：** 图像在缩放 1 时铺满方形视口。视口边长和基准尺寸会记录下来供 `_save` 使用。刚准备好的图像会居中，且变换**必须在 `postFrameCallback` 中重置**——不能在 `build` 中修改控制器。

# lib/shared/services/image_service.dart

纯静态本地图像存储服务：从操作系统选择器挑选文件、下载远程图像（如银行标志）、复制内置资源图像（内置银行标志，仅限完整版构建）、把存储的相对路径解析回绝对 `File`、删除存储图像。所有图像住在 `<appDir>/images/` 下，带基于 UUID 的文件名，扩展名记录图像格式；自 v1.4.5 起其中包括 `.svg`，财务界面通过 [`StoredImage`](../widgets/stored_image.md) 渲染它（`.svg` 原本就是 `downloadAndSave` 可能产生的扩展名，只是此前无法显示）。被财务（账户/订阅图像）、亲密（伴侣/玩具照片）使用，并被 [同步 — 逐文件错误处理而非整体同步中止](../../../sync.md#per-file-error-handling-not-whole-sync-abort) 描述的同步图像传输逻辑引用。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`_getImageDir`](#_getimagedir) | 静态方法（`ImageService`） | A | 返回（需要时创建）应用的 `images/` 目录。 |
| [`pickAndSaveImage`](#pickandsaveimage) | 静态方法（`ImageService`） | A | 让用户挑选图像文件并复制进应用存储。 |
| [`resolve`](#resolve) | 静态方法（`ImageService`） | A | 把相对 `images/...` 路径解析为绝对 `File`。 |
| [`delete`](#delete) | 静态方法（`ImageService`） | A | 存在时删除先前保存的图像。 |
| [`copyAssetImage`](#copyassetimage) | 静态方法（`ImageService`） | A | 把内置资源图像复制进应用存储。 |
| [`downloadAndSave`](#downloadandsave) | 静态方法（`ImageService`） | A | 从 URL 下载图像并保存进应用存储。 |

`grep -c 'Purpose:' lib/shared/services/image_service.dart` 报告 6，与本文件全部六个真实声明匹配（`ImageService` 类无其他方法、无书写构造函数，未发现未文档化声明）。

## 文档

### `static Future<Directory> _getImageDir()` <a id="_getimagedir"></a>
- **种类：** `ImageService` 的私有静态方法
- **来源：** `lib/shared/services/image_service.dart`（第 17 行）
- **用途：** 返回应用的 `images/` 目录，首次使用时创建。
- **输入：** 无。
- **返回：** `<appDir>/images` 的 `Future<Directory>`。
- **副作用：** 目录尚不存在时创建（`recursive: true`）。
- **算法：** 读取 `TodoStorage.getAppDir()`、连接 `'images'`、缺失时递归创建、返回 `Directory`。
- **用法：** `pickAndSaveImage`、`copyAssetImage` 和 `downloadAndSave` 调用的内部辅助。
- **备注：** 依赖 `TodoStorage.getAppDir()`，使自定义存储路径（从设置设置）被自动尊重。

### `static Future<String?> pickAndSaveImage()` <a id="pickandsaveimage"></a>
- **种类：** `ImageService` 的静态方法
- **来源：：** `lib/shared/services/image_service.dart`（第 34 行）
- **用途：** 打开限制为图像的操作系统文件选择器，把所选文件以新 UUID 名复制进应用存储，并返回其应用相对路径。
- **输入：** 无（交互；从 `FilePicker.platform` 读取）。
- **返回：** `Future<String?>` — 相对 `appDir` 的 `"images/<uuid><ext>"`，用户取消或选择器返回无可用路径时 `null`。
- **副作用：** 把所选文件复制进 `<appDir>/images/`。
- **算法：**
  1. 调用 `FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false)`。
  2. 结果或其文件列表为空、或所选路径为 `null` 时返回 `null`。
  3. 确保图像目录存在（`_getImageDir`）。
  4. 复用原始文件的扩展名构建新名 `'${Uuid().v4()}$ext'`。
  5. 把源文件复制到新目标路径。
  6. 返回 `'images/$newName'`。
- **用法：**
  ```dart
  final path = await ImageService.pickAndSaveImage();
  ```
  （`lib/features/finance/views/accounts_page.dart`，账户图像选择器；也用于 `intimacy_page.dart` 和 `add_subscription_dialog.dart`。）
- **备注：** 返回路径总是相对 `appDir`（如 `images/xxxx.png`），绝无绝对——调用方必须经 `ImageService.resolve()` 获取 `File`。

### `static Future<File> resolve(String relativePath)` <a id="resolve"></a>
- **种类：** `ImageService` 的静态方法
- **来源：** `lib/shared/services/image_service.dart`（第 57 行）
- **用途：** 把存储的相对图像路径变回绝对 `File`。
- **输入：** `relativePath` — 如 `"images/xxxx.png"`。
- **返回：** `Future<File>` — 自己不检查文件是否存在。
- **副作用：** 无（纯路径连接；读取 `TodoStorage.getAppDir()`）。
- **算法：** `File(p.join((await TodoStorage.getAppDir()).path, relativePath))`。
- **用法：**
  ```dart
  FutureBuilder<File>(
    future: ImageService.resolve(account.imagePath!),
    ...
  )
  ```
  （`lib/features/finance/views/accounts_page.dart`，渲染存储账户图像。）
- **备注：** 调用方负责在调用前检查 `imagePath != null`（仓库每个调用点在 null 检查后用 `!`），并处理缺失文件（如经 `FutureBuilder`/`File.exists()`），因为 `resolve` 不验证存在性。

### `static Future<void> delete(String relativePath)` <a id="delete"></a>
- **种类：** `ImageService` 的静态方法
- **来源：** `lib/shared/services/image_service.dart`（第 68 行）
- **用途：** 存在时从应用存储删除先前保存的图像。
- **输入：** `relativePath`。
- **返回：** `Future<void>`。
- **副作用：** 存在时删除磁盘上的解析文件。
- **算法：** 解析路径、检查 `await file.exists()`、只在那为真时删除。
- **用法：** 带附图像的合作方/玩具/账户/订阅被移除时调用，使磁盘图像不成为孤儿。
- **备注：** 文件已缺失时静默空操作（不抛异常）。

### `static Future<String?> copyAssetImage(String assetKey)` <a id="copyassetimage"></a>
- **种类：** `ImageService` 的静态方法
- **来源：** `lib/shared/services/image_service.dart`（第 83 行）
- **用途：** 把内置资源图像复制进应用存储，使它的行为与用户挑选或下载的图像完全一样。
- **输入：** `assetKey` — 资源路径，如 `assets/bank_logos/us_chase.svg`。
- **返回：** `Future<String?>` — `"images/<uuid><ext>"`，扩展名取自 `assetKey`（转为小写）；资源缺失、不可读或为空时返回 `null`。
- **副作用：** 读取资源包（`rootBundle.load`）；向 `<appDir>/images/` 写入一个新文件（`writeAsBytes(..., flush: true)`）。
- **算法：**
  1. 加载资源字节；为空则返回 `null`。
  2. 确保图像目录存在（`_getImageDir`）。
  3. 把字节写入 `'${Uuid().v4()}${extension(assetKey).toLowerCase()}'`。
  4. 返回 `'images/$newName'`；任何抛出的错误都被捕获并变为 `null`。
- **用法：**
  ```dart
  if (asset != null) path = await ImageService.copyAssetImage(asset);
  ```
  （`lib/features/finance/views/accounts_page.dart:2048`，`_fetchBankIcon`，在尝试网络链之前复制预设的内置标志。）
- **备注：** 刻意捕获所有错误：文件已被剥离或从未随包发布的清单条目会让资源包抛出异常，而调用方必须能回退到网络链。复制结果是普通的 `images/` 文件——内置 `.svg` 标志落地为 `images/<uuid>.svg`，与下载的标志一样同步和备份，没有格式变化。

### `static Future<String?> downloadAndSave(String url, {int minBytes = 500})` <a id="downloadandsave"></a>
- **种类：** `ImageService` 的静态方法
- **来源：** `lib/shared/services/image_service.dart`（第 106 行）
- **用途：** 从 URL 下载图像（如银行标志）并本地保存，拒绝太小不成真实图像的响应。
- **输入：** `url`；`minBytes`（默认 `500`）——比这小的响应被当作占位/默认 favicon 并拒绝。
- **返回：** `Future<String?>` — `"images/<uuid><ext>"`，或任何失败（非 200 状态、体太小、或抛出异常）时 `null`。
- **副作用：** 执行 HTTP GET；把下载字节写入 `<appDir>/images/`。
- **算法：**
  1. `http.get(Uri.parse(url))`；`statusCode != 200` 时返回 `null`。
  2. `response.bodyBytes.length < minBytes` 时返回 `null`。
  3. 从 `content-type` 页头挑文件扩展名：`jpeg`/`jpg` → `.jpg`、`ico` → `.ico`、`svg` → `.svg`、否则默认 `.png`。
  4. 确保图像目录存在、构建新 UUID 文件名、写字节。
  5. 返回相对路径；try 块中任何地方抛出的任何异常被捕获并转为 `null` 返回。
- **用法：**
  ```dart
  path = await ImageService.downloadAndSave(url);
  ```
  （`lib/features/finance/views/accounts_page.dart`，从 `BankPresetService` 提供 URL 下载银行标志。）
- **备注：** `minBytes` 过滤器存在正为拒绝一些银行标志 URL 返回的微型占位/默认 favicon 响应，而非真实 404。

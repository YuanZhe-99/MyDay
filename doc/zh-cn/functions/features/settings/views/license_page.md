# lib/features/settings/views/license_page.dart

MyApps-AI 授权声明包含 myapps_ai_ui。

声明列出 MyApps-UI、使用的三个包、源码和 GPL v3 链接。

显示 MyDay 的 GPLv3 许可证声明为可选中文本的单个静态页。它没有状态、没有服务，除本地化外没有外部协作者——它纯粹存在，使 [设置](../../../../features/settings.md) 的关于小节有一个专用 GPL 许可证屏，区别于自动生成的开源许可证页（`showLicensePage`，从 `settings_page.dart` 接线）和 [`privacy_policy_page.dart`](privacy_policy_page.md)。 自 1.5.0 起，文本末尾附有「Third-party components」声明，说明端侧 AI 卡片使用的中文转换表（`lib/shared/utils/chinese_convert_data.dart`，Apache-2.0）源自 OpenCC。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `LicensePage({super.key})` | 构造函数（`LicensePage`） | B | 创建许可证页实例。 |
| `build` | 方法（`LicensePage`） | B | 构建可滚动、可选择的许可证文本视图。 |

**对账：** `grep -c 'Purpose:' lib/features/settings/views/license_page.dart` 返回 2。两个块都文档化真实声明（构造函数和 `build`）——无错附块、无未文档化声明。`_licenseText` 静态字符串字段无 `Purpose:` 块，与它是数据而非函数一致。

## 文档

两个声明都是 Tier B（简单转发构造函数和只布局标题栏加一块可选择静态文本的 `build` 方法）——单行用途见上面表格；本文件无 Tier A 条目。

## 相关页面

- [设置](../../../../features/settings.md) — 链接到本页的关于小节。

## 导航栏内边距（1.6.1）

Expressive 底栏悬浮在页面之上（见 [adaptive-layout.md](../../../../adaptive-layout.md)），`SingleChildScrollView` 把它显式的内边距经过 `navBarAwarePadding(context, ...)`，使最后的内容能滚动到栏的上方。

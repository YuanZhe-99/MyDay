# lib/features/settings/views/home_widget_settings_page.dart

设置 › 桌面小组件（1.8.3），在 Android 和 iOS 上从 [`SettingsPage`](settings_page.md) 的小组件行进入。每种小组件类型一个分区，包含该类型的文字大小（来自 `myapps_widget_ui` 的 `WidgetTextScaleControl`）、隐私选项（*显示*、*隐藏数值*、*只显示图标*），以及基于真实数据绘制的实时 [`HomeWidgetPreview`](../widgets/home_widget_preview.md)。私密和计时器分区只在亲密模块可见时出现。设置通过 [`HomeWidgetService.saveSettings`](../../../shared/services/home_widget_service.md#savesettings) 存储。见 [桌面小组件](../../../../features/home-screen-widgets.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `HomeWidgetSettingsPage`（构造函数） | const 构造函数（`HomeWidgetSettingsPage`） | B | 创建小组件设置页。 |
| `createState` | 方法（`HomeWidgetSettingsPage`） | B | 创建可变状态对象。 |
| `initState` | 方法（`_HomeWidgetSettingsPageState`） | B | 开始加载设置和预览 payload。 |
| [`_load`](#_load) | 方法（`_HomeWidgetSettingsPageState`） | A | 读取设置，并为每种类型构建一个未遮罩的 payload。 |
| [`_update`](#_update) | 方法（`_HomeWidgetSettingsPageState`） | A | 更改一种类型的设置。 |
| [`build`](#build) | 方法（`_HomeWidgetSettingsPageState`） | A | 构建页面，每种可见类型一个分区。 |

**对账：** `grep -c 'Purpose:' lib/features/settings/views/home_widget_settings_page.dart` 报告 6，与上面 6 行匹配。

## 文档

### `Future<void> _load()` <a id="_load"></a>
- **种类：** `_HomeWidgetSettingsPageState` 的私有方法
- **来源：** `lib/features/settings/views/home_widget_settings_page.dart`（第 54 行）
- **用途：** 读取设置，并为每种类型构建一个未遮罩的 payload。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 读取 `storage_config.json` 和数据文件；更新 `_settings` 和 `_payloads`。
- **算法：** `HomeWidgetService.loadSettings()` 和 `payloadBuilders(DateTime.now())`，然后以 `mask: false` 调用每个构建器，构建器抛出时存为 null。
- **用法：** `initState`。
- **备注：** 数据无法读取的类型预览为占位图。

### `void _update(String kind, HomeWidgetKindSettings next)` <a id="_update"></a>
- **种类：** `_HomeWidgetSettingsPageState` 的私有方法
- **来源：** `lib/features/settings/views/home_widget_settings_page.dart`（第 79 行）
- **用途：** 更改一种类型的设置。
- **输入：** `kind`、`next`。
- **返回：** 无。
- **副作用：** 更新状态；`HomeWidgetService.saveSettings` 持久化该值并安排一次小组件刷新。
- **算法：** 先 `setState`，让预览立即跟随，然后保存（不 await）。
- **用法：** `build` 中的文字大小控件和隐私分段行。
- **备注：** 无。

### `Widget build(BuildContext context)` <a id="build"></a>
- **种类：** `_HomeWidgetSettingsPageState` 的方法
- **来源：** `lib/features/settings/views/home_widget_settings_page.dart`（第 91 行）
- **用途：** 构建页面。
- **输入：** `context`。
- **返回：** 一个 `Scaffold`，包含一条提示和每种可见类型一个 `MyAppsSettingsSection`。
- **副作用：** 无。
- **算法：** 设置加载完成前显示进度指示器。每个分区包含文字大小控件、隐私行（除待办外每种类型都带锁屏说明）和预览。`intimacyVisibilityProvider` 报告模块隐藏时跳过亲密相关类型。
- **用法：** 窄窗口上全屏推入，宽窗口上承载于设置的详情面板中。
- **备注：** 页面监听可见性 provider，因此隐藏模块会立即移除这两个分区。

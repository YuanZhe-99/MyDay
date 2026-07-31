# lib/app/app.dart

定义 `MyDayApp`，`main()` 的 `runApp` 调用返回的唯一根组件。它把 `MaterialApp.router` 接到应用主题（`app/theme.dart`）、路由器（`app/router.dart`）、本地化委托和 `appSettingsProvider` Riverpod 状态。见 [../../architecture.md#startup-sequence](../../architecture.md#startup-sequence) 和 [../../architecture.md#state-management](../../architecture.md#state-management)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `MyDayApp`（构造函数） | 构造函数（`MyDayApp`） | B | 创建 `MyDayApp` 实例。 |
| `build` | 方法（`MyDayApp`，`ConsumerWidget`） | B | 从当前设置构建 `MaterialApp.router` 组件树。 |

`grep -c 'Purpose:' lib/app/app.dart` 报告 2，与本文件两个真实声明都匹配（构造函数和 `build`）——未发现错附或未文档化声明。

## 文档

本文件两个声明都是 Tier B（平凡的 `const` 组件构造函数和一个 `build()` 方法），因此按模板它们是仅索引行、无完整条目。供上下文参考的值得注意行为：`build()` 读取 `ref.watch(appSettingsProvider)` 并把 `settings.themeMode` 和 `settings.locale` 喂进 `MaterialApp.router`，因此来自设置的更改主题或语言区域会触发整个应用外壳的重建。`theme`/`darkTheme` 来自 `AppTheme.light`/`AppTheme.dark`（见 [theme.md](theme.md)），`routerConfig` 来自 `appRouter`（见 [router.md](router.md)）。`builder: DevicePreview.appBuilder` 为调试构建中使用的 `device_preview` 包包装应用。

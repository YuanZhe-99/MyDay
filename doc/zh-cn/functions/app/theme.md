# lib/app/theme.dart

定义 `AppTheme`，一个经 `flex_color_scheme` 包产生应用浅色和深色 `ThemeData` 的纯静态命名空间。被 `MyDayApp`（`app/app.dart`）直接消费。见 [../../architecture.md#theming](../../architecture.md#theming)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `AppTheme._()` | 构造函数（`AppTheme`） | B | 阻止直接实例化主题命名空间。 |
| [`light`](#light) | getter（`AppTheme`） | A | 构建应用的浅色 `ThemeData`。 |
| [`dark`](#dark) | getter（`AppTheme`） | A | 构建应用的深色 `ThemeData`。 |

`grep -c 'Purpose:' lib/app/theme.dart` 报告 3，与本文件全部三个真实声明匹配（私有构造函数和两个静态 getter）——未发现错附或未文档化声明。

## 文档

### `static ThemeData get light` <a id="light"></a>
- **种类：** `AppTheme` 的静态 getter
- **来源：** `lib/app/theme.dart`（第 17 行）
- **用途：** 产生整个应用使用的 Material 3 浅色主题。
- **输入：** 无。
- **返回：** 由 `FlexThemeData.light` 构建的 `ThemeData`。
- **副作用：** 无——不可变 `ThemeData` 的纯构造。
- **算法：** 以 `scheme: FlexScheme.indigo`、`surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold`、`blendLevel: 7` 和一个配置 `blendOnLevel: 10`、`useMaterial3Typography: true`、`useM2StyleDividerInM3: true`、outline 风格输入装饰器和只为所选目的地显示导航栏标签的 `FlexSubThemesData` 调用 `FlexThemeData.light`；`useMaterial3: true`。
- **用法：**
  ```dart
  theme: AppTheme.light,
  ```
  （`lib/app/app.dart`，`MyDayApp.build`。）
- **备注：** `blendLevel`（7）低于深色变体的 `blendLevel`（13），`blendOnLevel`（10 vs 20）——这是浅色主题刻意更小的表面着染。两个主题共享同一个 `FlexScheme.indigo` 种子，使浅/深保持视觉一致。

### `static ThemeData get dark` <a id="dark"></a>
- **种类：** `AppTheme` 的静态 getter
- **来源：** `lib/app/theme.dart`（第 37 行）
- **用途：** 产生整个应用使用的 Material 3 深色主题。
- **输入：** 无。
- **返回：** 由 `FlexThemeData.dark` 构建的 `ThemeData`。
- **副作用：** 无——不可变 `ThemeData` 的纯构造。
- **算法：** 以 `scheme: FlexScheme.indigo`、`surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold`、`blendLevel: 13` 和一个配置 `blendOnLevel: 20`、`useMaterial3Typography: true`、`useM2StyleDividerInM3: true`、outline 风格输入装饰器和只为所选目的地显示导航栏标签的 `FlexSubThemesData` 调用 `FlexThemeData.dark`；`useMaterial3: true`。
- **用法：**
  ```dart
  darkTheme: AppTheme.dark,
  ```
  （`lib/app/app.dart`，`MyDayApp.build`。）
- **备注：** 两个变体之间的混合层级对比见上方 `light`。

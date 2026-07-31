# lib/shared/services/tray_service.dart

仅桌面（Windows/macOS/Linux）单例管理系统托盘图标/菜单和窗口隐藏/显示行为，混入来自 `tray_manager` / `window_manager` 的 `TrayListener` 和 `WindowListener`。从 `main()` 初始化（见 [架构 — 启动序列](../../../architecture.md#startup-sequence)）并从设置页桌面小节配置（最小化到托盘、关闭到托盘）。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `TrayService._()` | 构造函数（`TrayService`） | B | 阻止托盘单例直接实例化。 |
| `minimizeToTray` | getter（`TrayService`） | B | 返回当前最小化到托盘设置。 |
| `closeToTray` | getter（`TrayService`） | B | 返回当前关闭到托盘设置。 |
| [`init`](#init) | 方法（`TrayService`） | A | 初始化托盘图标和窗口管理器钩子（仅桌面）。 |
| [`_setupTray`](#_setuptray) | 方法（`TrayService`） | A | 设置托盘图标/工具提示并构建初始菜单。 |
| [`_rebuildMenu`](#_rebuildmenu) | 方法（`TrayService`） | A | 用当前语言区域重建托盘上下文菜单。 |
| [`setMinimizeToTray`](#setminimizetotray) | 方法（`TrayService`） | A | 持久化最小化到托盘设置。 |
| [`setCloseToTray`](#setclosetotray) | 方法（`TrayService`） | A | 持久化关闭到托盘设置并更新 window-manager 的 prevent-close 标志。 |
| [`updateLocale`](#updatelocale) | 方法（`TrayService`） | A | 更新托盘语言区域并重建菜单标签。 |
| [`onTrayIconMouseDown`](#ontrayiconmousedown) | 方法（`TrayService`，`TrayListener`） | A | 托盘图标左键点击时显示窗口。 |
| [`onTrayIconRightMouseDown`](#ontrayiconrightmousedown) | 方法（`TrayService`，`TrayListener`） | A | 右键点击时弹出托盘上下文菜单。 |
| [`onTrayMenuItemClick`](#ontraymenuitemclick) | 方法（`TrayService`，`TrayListener`） | A | 处理显示/退出托盘菜单选择。 |
| [`onWindowClose`](#onwindowclose) | 方法（`TrayService`，`WindowListener`） | A | 关闭时按设置隐藏到托盘或销毁窗口。 |
| [`onWindowMinimize`](#onwindowminimize) | 方法（`TrayService`，`WindowListener`） | A | 最小化时按设置隐藏到托盘。 |
| [`_showWindow`](#_showwindow) | 方法（`TrayService`） | A | 恢复 Dock 图标并把窗口带到前台。 |
| [`_setDockIconVisible`](#_setdockiconvisible) | 静态方法（`TrayService`） | A | 经平台通道切换 macOS Dock 图标可见性。 |

`grep -c 'Purpose:' lib/shared/services/tray_service.dart` 报告 16，与本文件全部十六个真实声明匹配。未发现错附或未文档化声明。所有非平凡方法按一揽子"服务"规则归为 Tier A（整个类是 `shared/services/tray_service.dart`），包括短单行 `TrayListener`/`WindowListener` 事件处理器，因为各执行真实 IO（窗口/托盘管理器调用或平台通道调用）而非纯组件组合。

## 文档

### `Future<void> init()` <a id="init"></a>
- **种类：** `TrayService` 的方法
- **来源：** `lib/shared/services/tray_service.dart`（第 47 行）
- **用途：** 初始化托盘图标和窗口管理器钩子；非桌面或首次成功调用后为空操作。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 从 `TodoStorage` 读取持久化 `minimizeToTray`/`closeToTray`；初始化 `window_manager`、把 `this` 注册为 `WindowListener`、设 `preventClose`；构建托盘图标/菜单（`_setupTray`）；把 `this` 注册为 `TrayListener`；设 `_initialized = true`。
- **算法：**
  1. `_initialized` 或非 Windows/macOS/Linux 时立即返回。
  2. 从 `TodoStorage` 加载 `minimizeToTray`/`closeToTray`。
  3. `windowManager.ensureInitialized()`、添加 `this` 为监听器、`setPreventClose(_closeToTray)`。
  4. `_setupTray()`，然后添加 `this` 为 `trayManager` 监听器。
  5. 标记 `_initialized = true`。
- **用法：**
  ```dart
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await TrayService.instance.init();
  }
  ```
  （`lib/main.dart`，启动序列。）
- **备注：** 经 `_initialized` 守卫幂等——可安全多次调用。

### `Future<void> _setupTray()` <a id="_setuptray"></a>
- **种类：** `TrayService` 的私有方法
- **来源：** `lib/shared/services/tray_service.dart`（第 69 行）
- **用途：** 设置平台适当托盘图标和工具提示，然后构建初始菜单。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 调用 `trayManager.setIcon`、`setToolTip('MyDay!!!!!')`；调用 `_rebuildMenu()`。
- **算法：** Windows 挑 `assets/app_icon.ico` 或其他地方 `assets/icon/app_icon.png`；设置图标和工具提示；构建菜单。
- **用法：** 从 `init()` 调用一次。
- **备注：** 无。

### `Future<void> _rebuildMenu()` <a id="_rebuildmenu"></a>
- **种类：** `TrayService` 的私有方法
- **来源：** `lib/shared/services/tray_service.dart`（第 82 行）
- **用途：** 用当前语言区域本地化标签重建托盘上下文菜单（显示 / 分隔符 / 退出）。
- **输入：** 无（读取 `_locale`）。
- **返回：** `Future<void>`。
- **副作用：** 调用 `trayManager.setContextMenu(menu)`。
- **算法：** `lookupAppLocalizations(_locale)`；构建带 `'show'` 项（`trayShow`）、分隔符和 `'quit'` 项（`trayQuit`）的 `Menu`；应用它。
- **用法：** 从 `_setupTray()` 和 `updateLocale()` 调用。
- **备注：** 无。

### `Future<void> setMinimizeToTray(bool value)` <a id="setminimizetotray"></a>
- **种类：** `TrayService` 的方法
- **来源：** `lib/shared/services/tray_service.dart`（第 99 行）
- **用途：** 更新并持久化最小化窗口是否隐藏到托盘。
- **输入：** `value`。
- **返回：** `Future<void>`。
- **副作用：** 更新 `_minimizeToTray`；调用 `TodoStorage.setMinimizeToTray(value)`。
- **算法：** `_minimizeToTray = value; await TodoStorage.setMinimizeToTray(value);`
- **用法：**
  ```dart
  await TrayService.instance.setMinimizeToTray(value);
  ```
  （`lib/features/settings/views/settings_page.dart`，桌面设置切换。）
- **备注：** 无。

### `Future<void> setCloseToTray(bool value)` <a id="setclosetotray"></a>
- **种类：** `TrayService` 的方法
- **来源：** `lib/shared/services/tray_service.dart`（第 109 行）
- **用途：** 更新并持久化关闭窗口是隐藏到托盘而非退出，并保持 `window_manager` 的 prevent-close 标志同步。
- **输入：** `value`。
- **返回：** `Future<void>`。
- **副作用：** 更新 `_closeToTray`；调用 `TodoStorage.setCloseToTray(value)`；调用 `windowManager.setPreventClose(value)`。
- **算法：** `_closeToTray = value; await TodoStorage.setCloseToTray(value); await windowManager.setPreventClose(value);`
- **用法：**
  ```dart
  await TrayService.instance.setCloseToTray(value);
  ```
  （`lib/features/settings/views/settings_page.dart`，桌面设置切换。）
- **备注：** `setPreventClose` 正是让 `onWindowClose` 触发而非操作系统立即关闭窗口的东西，因此此调用必须与 `_closeToTray` 保持同步，`onWindowClose` 的分支才正确表现。

### `Future<void> updateLocale(Locale locale)` <a id="updatelocale"></a>
- **种类：** `TrayService` 的方法
- **来源：** `lib/shared/services/tray_service.dart`（第 121 行）
- **用途：** 更新托盘菜单标签使用的语言区域，托盘已初始化时重建菜单。
- **输入：** `locale`。
- **返回：** `Future<void>`。
- **副作用：** 更新 `_locale`；条件调用 `_rebuildMenu()`。
- **算法：** `_locale = locale; if (_initialized) await _rebuildMenu();`
- **用法：**
  ```dart
  TrayService.instance.updateLocale(resolvedLocale);
  ```
  （`lib/shared/providers/app_settings.dart`，`_loadPersisted`/`setLocale`，让托盘标签与应用语言区域同步——见 [app_settings.dart](../providers/app_settings.md)。）
- **备注：** 未初始化（如移动端，或 `init()` 运行前）时跳过重建，语言区域简单缓存供稍后。

### `void onTrayIconMouseDown()` <a id="ontrayiconmousedown"></a>
- **种类：** `TrayService` 的方法（`TrayListener` 覆盖）
- **来源：** `lib/shared/services/tray_service.dart`（第 134 行）
- **用途：** 用户左键点击托盘图标时恢复窗口。
- **输入：** 无（`tray_manager` 回调）。
- **返回：** 无。
- **副作用：** 调用 `_showWindow()`。
- **算法：** 直接转发 `_showWindow()`。
- **用法：** 由 `tray_manager` 自己调用，非应用代码。
- **备注：** 无。

### `void onTrayIconRightMouseDown()` <a id="ontrayiconrightmousedown"></a>
- **种类：** `TrayService` 的方法（`TrayListener` 覆盖）
- **来源：** `lib/shared/services/tray_service.dart`（第 143 行）
- **用途：** 右键点击时打开托盘上下文菜单。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 调用 `trayManager.popUpContextMenu()`。
- **算法：** 直接转发 `trayManager.popUpContextMenu()`。
- **用法：** 由 `tray_manager` 自己调用。
- **备注：** 无。

### `void onTrayMenuItemClick(MenuItem menuItem)` <a id="ontraymenuitemclick"></a>
- **种类：** `TrayService` 的方法（`TrayListener` 覆盖）
- **来源：** `lib/shared/services/tray_service.dart`（第 153 行）
- **用途：** 处理显示/退出托盘菜单项。
- **输入：** `menuItem`（其 `key` 区分选择）。
- **返回：** 无。
- **副作用：** `'show'` 调用 `_showWindow()`；`'quit'` 调用 `windowManager.setPreventClose(false)` 然后 `windowManager.close()`。
- **算法：** 对 `'show'`/`'quit'` 做 `switch (menuItem.key)`。
- **用法：** 菜单项被选中时由 `tray_manager` 调用。
- **备注：** 退出显式先禁用 prevent-close，使应用实际退出而非被 `onWindowClose` 的关闭到托盘分支拦截。

### `void onWindowClose()` <a id="onwindowclose"></a>
- **种类：** `TrayService` 的方法（`WindowListener` 覆盖）
- **来源：** `lib/shared/services/tray_service.dart`（第 175 行）
- **用途：** `closeToTray` 启用时隐藏到托盘而非退出；否则实际销毁窗口。
- **输入：** 无。
- **返回：** 无。
- **副作用：** `windowManager.hide()` + `_setDockIconVisible(false)`，或 `windowManager.destroy()`。
- **算法：** `if (_closeToTray) { hide + hide dock icon } else { destroy }`。
- **用法：** 按下关闭按钮时由 `window_manager` 调用（只因 `init()`/`setCloseToTray` 设了 `setPreventClose(_closeToTray)` 才触发）。
- **备注：** 依赖 `windowManager.setPreventClose` 已被 `setCloseToTray`/`init()` 保持同步——否则此监听器关闭时绝不触发。

### `void onWindowMinimize()` <a id="onwindowminimize"></a>
- **种类：** `TrayService` 的方法（`WindowListener` 覆盖）
- **来源：** `lib/shared/services/tray_service.dart`（第 189 行）
- **用途：** `minimizeToTray` 启用时最小化隐藏到托盘。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 启用时 `windowManager.hide()` + `_setDockIconVisible(false)`。
- **算法：** `if (_minimizeToTray) { hide + hide dock icon }`。
- **用法：** 最小化时由 `window_manager` 调用。
- **备注：** 无。

### `void _showWindow()` <a id="_showwindow"></a>
- **种类：** `TrayService` 的私有方法
- **来源：** `lib/shared/services/tray_service.dart`（第 204 行）
- **用途：** 把应用窗口带回前台并恢复 macOS Dock 图标。
- **输入：** 无。
- **返回：** 无。
- **副作用：** `_setDockIconVisible(true)`；`windowManager.show()`；`windowManager.focus()`。
- **算法：** 顺序调用，无分支。
- **用法：** 从 `onTrayIconMouseDown` 和托盘菜单 `'show'` case 调用。
- **备注：** 无。

### `static void _setDockIconVisible(bool visible)` <a id="_setdockiconvisible"></a>
- **种类：** `TrayService` 的私有静态方法
- **来源：** `lib/shared/services/tray_service.dart`（第 215 行）
- **用途：** 经原生平台通道显示或隐藏 macOS Dock 图标。
- **输入：** `visible`。
- **返回：** 无。
- **副作用：** 只在 macOS 上调用 `MethodChannel('com.yuanzhe.my_day/dock').invokeMethod('setDockIconVisible', {'visible': visible})`。
- **算法：** 非 `Platform.isMacOS` 时立即返回；否则调用平台通道方法。
- **用法：** 从 `_showWindow()`（`true`）和 `onWindowClose`/`onWindowMinimize`（`false`）调用。
- **备注：** Windows/Linux 上空操作——平台通道是 macOS 特有的（原生 Dock 图标切换在其他桌面平台无对应物）。

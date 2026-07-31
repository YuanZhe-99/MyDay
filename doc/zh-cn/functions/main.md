# lib/main.dart

应用入口点。本文件在 Flutter 组件树存在之前接好每个进程级单例服务，然后交给 `MyDayApp`（`app/app.dart`）。完整有序启动序列及其如何映射到 `AutoSyncService`、`ReminderService`、`TrayService` 和 `LocalApiServer` 见 [../architecture.md#startup-sequence](../architecture.md#startup-sequence)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`main`](#main) | 顶层函数 | A | 初始化启动服务并启动应用入口点。 |

`grep -c 'Purpose:' lib/main.dart` 报告 1，与本文件唯一的真实声明匹配（恰好一个函数 `main()`，其文档块正确直接附加在它上方——未发现错附或未文档化声明）。

## 文档

### `void main() async` <a id="main"></a>
- **种类：** 顶层函数（入口点）
- **来源：** `lib/main.dart`（第 23 行）
- **用途：** 执行平台特定启动接线（通知、开机自启、本地 API 服务器、提醒循环、自动同步、托盘图标），然后运行组件树。
- **输入：** 无（隐式 `Platform`/`kIsWeb` 检查读取当前运行时环境）。
- **返回：** 无——这是进程入口点。
- **副作用：** 调用 `WidgetsFlutterBinding.ensureInitialized()`；Android/iOS 上初始化 `MobileNotificationService`；桌面上调用 `localNotifier.setup(...)`、配置 `launch_at_startup` 并启动 `LocalApiServer`；启动 `ReminderService.instance` 和 `AutoSyncService.instance`；Windows/macOS/Linux 上初始化 `TrayService.instance`；最后调用 `runApp(...)`。
- **算法：**
  1. 在任何插件调用前确保 Flutter bindings 已初始化。
  2. 按平台分支：移动端获得 `MobileNotificationService.instance.init()`；其他一切（包括 web，`else` 只在非 web 桌面目标上运行而隐式跳过）落入 `localNotifier.setup(appName: 'MyDay!!!!!', shortcutPolicy: ShortcutPolicy.ignore)`。
  3. 非 web 的 Windows/macOS/Linux 上，读取 `PackageInfo.fromPlatform()` 并调用 `launchAtStartup.setup(appName: ..., appPath: Platform.resolvedExecutable)`。
  4. 同一桌面平台集上，await `LocalApiServer.start()`（除非用户在设置中启用了本地 API，否则空操作）。
  5. 无条件启动 `ReminderService.instance`（它内部决定桌面 vs 移动通知行为）。
  6. 无条件启动 `AutoSyncService.instance`（它只在 WebDAV 已配置并启用后真正同步）。
  7. 桌面上，await `TrayService.instance.init()`。
  8. 调用 `runApp`，把 `MyDayApp` 包在 `DevicePreview`（仅 `kDebugMode` 启用）和 Riverpod `ProviderScope` 中。
- **用法：** 应用代码不调用——由 Flutter/Dart 启动器调用一次。
- **备注：** 两个桌面平台检查重复（`Platform.isWindows || Platform.isMacOS || Platform.isLinux`，其中一个还排除 `kIsWeb`），而不是提取成共享辅助；添加新桌面平台时保持两者同步。顺序重要：`TrayService.init()` 在 `ReminderService`/`AutoSyncService` 启动后、组件树构建前运行。

# lib/features/settings/views/settings_page.dart

主设置屏：通用（语言/周起始/主题）、隐私（亲密模块隐藏/显示）、桌面（托盘、启动时启动、本地 API 服务器、自定义存储位置）、数据（WebDAV 同步、ZIP 导入/导出、备份）、关于（版本、许可证、隐私政策）和仅调试的订阅日期覆盖小节。`SettingsPage`/`_SettingsPageState` 直接拥有其中大多数设置的读写管道（经 `TodoStorage.readConfig`/`writeConfig`、`TrayService`、`launchAtStartup` 和 `LocalApiServer`），而 WebDAV 同步和备份委托给 [`webdav_config_page.dart`](../../../shared/views/webdav_config_page.md) 和 [`backup_page.dart`](../../../shared/views/backup_page.md)，关于小节链接到 [`license_page.dart`](license_page.md) 和 [`privacy_policy_page.dart`](privacy_policy_page.md)。逐小节完整功能描述见 [设置](../../../../features/settings.md)，本页暴露开关的仅桌面托盘/启动/本地 API 机制见 [平台说明](../../../../platform-notes.md)，本页 WebDAV 状态块响应的自动同步触发器见 [WebDAV 同步](../../../../sync.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `SettingsPage({super.key})` | 构造函数（`SettingsPage`） | B | 创建设置页实例。 |
| `createState` | 方法（`SettingsPage`） | B | 为此组件创建可变状态对象。 |
| `_isDesktop` | getter（`_SettingsPageState`） | B | 当前平台是否为 Windows/macOS/Linux。 |
| `initState` | 方法（`_SettingsPageState`） | B | 启动所有设置加载调用并注册同步状态监听器。 |
| `dispose` | 方法（`_SettingsPageState`） | B | 注销同步状态监听器。 |
| `_refreshSyncStatus` | 方法（`_SettingsPageState`） | B | 后台同步状态变化时触发重建。 |
| `_loadTraySettings` | 方法（`_SettingsPageState`） | B | 从 `TrayService` 加载最小化/关闭到托盘标志。 |
| `_loadStoragePath` | 方法（`_SettingsPageState`） | B | 加载当前数据存储路径。 |
| [`_openDataFolder`](#opendatafolder) | 方法（`_SettingsPageState`） | A | 在操作系统文件管理器中打开应用数据文件夹。 |
| `_loadVersion` | 方法（`_SettingsPageState`） | B | 加载并格式化应用版本字符串。 |
| `_loadWebDAVStatus` | 方法（`_SettingsPageState`） | B | 加载 WebDAV 同步是否已配置。 |
| `_loadAutoStartStatus` | 方法（`_SettingsPageState`） | B | 加载启动时启动是否启用。 |
| `_loadApiSettings` | 方法（`_SettingsPageState`） | B | 从配置加载本地 API 服务器设置。 |
| `_exportData` | 方法（`_SettingsPageState`） | B | 把所有应用数据作为 ZIP 导出到用户选择目录。 |
| `_importData` | 方法（`_SettingsPageState`） | B | 确认后从用户选择 ZIP 导入应用数据。 |
| [`_showApiSettingsDialog`](#showapisettingsdialog) | 方法（`_SettingsPageState`） | A | 编辑并保存本地 API 服务器设置，然后重启服务器。 |
| `signature`（本地函数） | 函数（本地，`_showApiSettingsDialog` 内） | B | 为 API 设置表单计算变更检测签名。 |
| `build` | 方法（`_SettingsPageState`） | B | 为当前状态构建设置页的小节列表。 |
| `_buildSection` | 方法（组件辅助） | B | 渲染一个带标题的设置小节。 |
| [`_showStoragePathDialog`](#showstoragepathdialog) | 方法（`_SettingsPageState`） | A | 编辑自定义存储路径，含重置回默认。 |
| `_showThemePicker` | 方法（`_SettingsPageState`） | B | 显示主题模式选择器底部面板。 |
| `_showWeekStartPicker` | 方法（`_SettingsPageState`） | B | 显示全局周起始日选择器底部面板。 |
| [`_showLanguagePicker`](#showlanguagepicker) | 方法（`_SettingsPageState`） | A | 显示应用语言选择器，把选择解析为 `Locale`。 |

**对账：** `grep -c 'Purpose:' lib/features/settings/views/settings_page.dart` 返回 23。23 个块都文档化真实声明（22 个方法/构造函数/getter，加在 `_showApiSettingsDialog` 内声明的嵌套本地函数 `signature()`，它自己有 `Purpose:` 块）——无错附块、未发现未文档化真实声明。`_SettingsPageState` 顶部的实例字段（`_storagePath`、`_apiPort` 等）无 `Purpose:` 块，与它们是状态而非函数一致。

## 文档

### `Future<void> _openDataFolder()` <a id="opendatafolder"></a>
- **种类：** `_SettingsPageState` 的方法
- **来源：** `lib/features/settings/views/settings_page.dart`（第 137 行）
- **用途：** 在宿主操作系统文件管理器中打开应用数据目录，按桌面平台使用正确原生命令。
- **输入：** 无（读取 `TodoStorage.getAppDir()`）。
- **返回：** `Future<void>`。
- **副作用：** 启动外部操作系统进程（`explorer`、`open` 或 `xdg-open`）。
- **算法：**
  1. 经 `TodoStorage.getAppDir()` 解析应用数据目录。
  2. Windows 上运行 `explorer <path>`。
  3. macOS 上运行 `open <path>`。
  4. Linux 上经 `Uri.directory(...).toFilePath()` 把目录转换为 `file://` 风格路径并运行 `xdg-open <path>`。
  5. 其他平台（移动）不运行任何分支，因此调用此的块只在 `_isDesktop` 为 true 时显示。
- **用法：**
  ```dart
  ListTile(
    leading: const Icon(Icons.folder_open_outlined),
    title: Text(l10n.settingsOpenDataFolder),
    subtitle: Text(l10n.settingsOpenDataFolderDesc),
    onTap: _openDataFolder,
  ),
  ```
- **备注：** 每个平台需要不同原生命令，Linux 还需要不同路径编码（`Uri.directory` 而非原始路径字符串）——本应用使用的包中没有跨平台"在文件管理器显示"API。

### `Future<void> _showApiSettingsDialog()` <a id="showapisettingsdialog"></a>
- **种类：** `_SettingsPageState` 的方法
- **来源：** `lib/features/settings/views/settings_page.dart`（第 272 行）
- **用途：** 让用户编辑本地 API 服务器的监听地址、端口、用户名和密码，然后持久化变更并重启服务器使其拾取新设置。
- **输入：** 无（读取当前 `_apiPort`/`_apiListenAddress`/`_apiUsername`/`_apiPassword` 播种对话框文本控制器）。
- **返回：** `Future<void>`。
- **副作用：** 经 `TodoStorage.writeConfig` 把 `apiPort`/`apiListenAddress`/`apiUsername`/`apiPassword` 写入 `storage_config.json`；调用 `LocalApiServer.restart()`；显示确认 snackbar；更新 `_apiPort`/`_apiListenAddress`/`_apiUsername`/`_apiPassword` 状态。
- **算法：**
  1. 从当前设置播种四个 `TextEditingController` 并捕获初始 `signature()`（经共享 `formSignature` 辅助的所有四字段连接字符串指纹）供未保存变更检测。
  2. 显示包在 `UnsavedChangesGuard` 中的 `AlertDialog`，比较实时 `signature()` 与 `initialSignature` 决定 Cancel 是否应在丢弃前警告。
  3. 用户保存（`saved == true`）且组件仍 mounted 时：用 `int.tryParse(...) ?? 7790` 解析端口字段（无效输入回退默认）；把空地址规范化为 `'localhost'`；把空用户名/密码规范化为 `null`（而非空字符串），使清除凭据实际从配置移除它，不只是空白。
  4. 经 `TodoStorage.writeConfig` 写四个值、更新本地状态，然后调用 `LocalApiServer.restart()` 使运行中服务器拾取新绑定地址/端口/凭据。
  5. 仍 mounted 时再次 `setState` 并经 `LocalApiServer.port` 显示报告服务器（可能新的）端口的 snackbar。
- **用法：**
  ```dart
  ListTile(
    leading: const Icon(Icons.settings_outlined),
    title: Text(l10n.settingsApiServer),
    trailing: const Icon(Icons.chevron_right),
    enabled: _apiEnabled,
    onTap: _apiEnabled ? _showApiSettingsDialog : null,
  ),
  ```
- **备注：** 用户名/密码的空字符串到 `null` 规范化正是让用户把存储 API 凭据清除回"无认证"的东西——写 `''` 会在配置中留下 falsy-但-非-null 的凭据。此对话框字段喂入的本地 API 非回环绑定需凭据规则见 [平台说明](../../../../platform-notes.md)。

### `Future<void> _showStoragePathDialog(BuildContext context)` <a id="showstoragepathdialog"></a>
- **种类：** `_SettingsPageState` 的方法
- **来源：** `lib/features/settings/views/settings_page.dart`（第 721 行）
- **用途：** 让用户查看和更改自定义数据存储路径，或重置回应用默认位置。
- **输入：** `context` — 用于对话框和保存后 snackbar。
- **返回：** `Future<void>`。
- **副作用：** 可能调用移动应用数据文件的 `TodoStorage.setStoragePath(...)`；重新加载 `_storagePath`；显示结果 snackbar。
- **算法：**
  1. 用当前 `_storagePath` 播种 `TextEditingController` 并显示带三个操作、包在 `UnsavedChangesGuard` 中的 `AlertDialog`：取消（丢弃，受保护）、"重置默认"（带空字符串弹出）和保存（带修剪字段文本弹出）。
  2. 对话框被 `null`（取消）关闭时不做任何事地返回。
  3. 否则在调用 `TodoStorage.setStoragePath(pathToSet)` 前把空字符串当作"重置默认"转换为 `null`；非空字符串作为新路径通过。
  4. `setStoragePath` 报告成功时经 `_loadStoragePath()` 重新加载 `_storagePath`，仍 mounted 时显示文本取决于路径是被重置（`pathToSet == null`）还是设为新自定义位置的 snackbar。
- **用法：**
  ```dart
  ListTile(
    leading: const Icon(Icons.folder_outlined),
    title: Text(l10n.settingsStorageLocation),
    subtitle: Text(_storagePath, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => _showStoragePathDialog(context),
  ),
  ```
- **备注：** 空字符串-意味着-重置的约定镜像 `_showApiSettingsDialog` 凭据的空-意味着-清除约定——两者都用空字段而非单独控件信号"回到默认/未设置状态"。

### `void _showLanguagePicker(BuildContext context, AppSettings settings)` <a id="showlanguagepicker"></a>
- **种类：** `_SettingsPageState` 的方法
- **来源：** `lib/features/settings/views/settings_page.dart`（第 875 行）
- **用途：** 显示让用户选"跟随系统"或四种受支持应用语言之一的底部面板，把选择转换为应用设置提供者期望的 `Locale`。
- **输入：** `context`；`settings` — 当前 `AppSettings`，用于计算预选单选值。
- **返回：** `None`。
- **副作用：** 调用 `ref.read(appSettingsProvider.notifier).setLocale(locale)`；弹出面板。
- **算法：**
  1. 从 `settings.locale` 计算 `currentTag`（`languageCode` 加存在的 `_countryCode` 后缀），`settings.locale` 为 null 时为 `'system'`。
  2. 显示带五个固定选项的 `RadioGroup<String>` 模态面板：system、`en`、`zh`、`zh_TW`、`ja`。
  3. 选择时：代码恰好是 `'zh_TW'` 时显式构造 `Locale('zh', 'TW')`（Dart 的 `Locale(code)` 构造函数无法解析下划线连接的区域标签）；否则代码非 null 且不是 `'system'` 时构造 `Locale(code)`；否则把 `locale` 留为 `null`（跟随系统）。
  4. 调用 `setLocale(locale)` 并弹出面板。
- **用法：**
  ```dart
  ListTile(
    leading: const Icon(Icons.language),
    title: Text(l10n.settingsLanguage),
    subtitle: Text(localeLabel),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => _showLanguagePicker(context, settings),
  ),
  ```
- **备注：** `zh_TW` 特判是这里不是泛型单参数 `Locale(code)` 调用的唯一分支——省略它要么抛错要么静默为繁体中文产生错误语言区域，因为 `Locale('zh_TW')` 不等于 `Locale('zh', 'TW')`。

## 相关页面

- [设置](../../../../features/settings.md) — 本页实现的逐小节功能描述。
- [平台说明](../../../../platform-notes.md) — `_showApiSettingsDialog` 编辑的本地 API 服务器配置键，以及桌面小节其他开关背后的托盘/启动机制。
- [WebDAV 同步](../../../../sync.md) 和 [备份与恢复](../../../../backup-restore.md) — 数据小节底层行为，在 [`webdav_config_page.dart`](../../../shared/views/webdav_config_page.md) 和 [`backup_page.dart`](../../../shared/views/backup_page.md) 中实现。

# 架构

本页覆盖应用外壳（启动、导航、主题）、状态管理、本地化、仓库布局，以及每个功能模块遵循的核心存储/并发规则。

## 启动序列

`lib/main.dart` 是入口点。`main()` 是 `async` 的，在 `runApp` 之前按顺序运行：

1. `WidgetsFlutterBinding.ensureInitialized()`。
2. 平台特定通知设置：Android/iOS 上 `MobileNotificationService.instance.init()`，或桌面上 `localNotifier.setup(appName: 'MyDay!!!!!', shortcutPolicy: ShortcutPolicy.ignore)`。
3. 桌面上（Windows/macOS/Linux，非 web）：用 `PackageInfo.fromPlatform()` 配置 `launch_at_startup` 的应用名、用 `Platform.resolvedExecutable` 配置路径。
4. 桌面上：`LocalApiServer.start()`——本地 HTTP API 服务器（仅桌面）。
5. `ReminderService.instance.start()`——全局 30 秒提醒循环，与哪个标签激活无关。
6. `AutoSyncService.instance.start()`——自动同步生命周期观察者（只在用户配置并启用 WebDAV 后同步）。
7. 桌面上：`TrayService.instance.init()`——系统托盘图标/菜单。
8. `runApp(DevicePreview(enabled: kDebugMode, builder: (_) => const ProviderScope(child: MyDayApp())))`。

因此组件树是 `DevicePreview` → `ProviderScope`（Riverpod 根）→ `MyDayApp`（`lib/app/app.dart`，一个 `ConsumerWidget`）。

## 导航

`lib/app/router.dart` 构建一个带单个 `ShellRoute` 的 `go_router` `GoRouter`，包住 `ShellScaffold`（`lib/shared/widgets/shell_scaffold.dart`）。外壳的路由是底部导航目的地：

- `/todo` → `TodoPage`
- `/finance` → `FinancePage`
- `/weight` → `WeightPage`
- `/intimacy` → `IntimacyPage`（即使模块被用户隐藏也存在于路由表；可见性是 UI 层面的事，不是路由层面的事）
- `/settings` → `SettingsPage`

`initialLocation` 是 `/todo`。

## 主题

`lib/app/theme.dart` 经 `flex_color_scheme` 的 `FlexThemeData` 构建浅色和深色 `ThemeData`，两者都用 `scheme: FlexScheme.indigo`、`useMaterial3Typography: true` 和 `useMaterial3: true`。这给出共享同一靛蓝种子方案、跨越浅/深色的 Material 3 视觉体系。

## 状态管理

状态管理全程使用 `flutter_riverpod`（根部 `ProviderScope`，`MyDayApp` 用 `ConsumerWidget`）。值得关注的 provider 包括 `lib/shared/providers/app_settings.dart` 和 `lib/shared/providers/intimacy_visibility.dart`。新代码应留在 Riverpod 上，而不是引入 Provider 或 Bloc。

## 本地化

`lib/l10n/app_*.arb` 保存四个 ARB 来源——`app_en.arb`、`app_ja.arb`、`app_zh.arb`（简体中文）和 `app_zh_TW.arb`（繁体中文）——覆盖英语、日语、简体中文和繁体中文。生成的本地化 Dart 文件（`flutter gen-l10n`）与它们一起位于 `lib/l10n/` 下。

## 仓库结构

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
  features/
    todo/
      models/task.dart
      services/todo_storage.dart
      views/todo_page.dart
      widgets/add_task_dialog.dart
      widgets/edit_task_dialog.dart
      widgets/recurrence_picker.dart
      widgets/task_section.dart
    finance/
      models/finance.dart
      services/balance_util.dart
      services/bank_preset_service.dart
      services/exchange_rate_api.dart
      services/exchange_rate_storage.dart
      services/finance_storage.dart
      services/subscription_processor.dart
      views/
      widgets/
    intimacy/
      models/intimacy_record.dart
      services/body_metrics.dart
      services/cycle_predictor.dart
      services/intimacy_storage.dart
      views/body_page.dart
      views/intimacy_page.dart
      widgets/add_record_dialog.dart
      widgets/body_section.dart
      widgets/cycle_calendar.dart
      widgets/timer_page.dart
    weight/
      models/weight_record.dart
      services/weight_storage.dart
      views/weight_page.dart
    settings/views/
  shared/
    providers/app_settings.dart
    providers/intimacy_visibility.dart
    services/
      auto_sync_service.dart
      backup_service.dart
      image_service.dart
      import_export_service.dart
      local_api_server.dart
      mobile_notification_service.dart
      reminder_service.dart
      sync_merge.dart
      sync_progress.dart
      sync_wake_lock.dart
      tray_service.dart
      webdav_service.dart
    utils/json_preservation.dart
    utils/week_grouping.dart
    views/
    widgets/
  l10n/
```

每个功能模块（`todo`、`finance`、`intimacy`、`weight`）遵循相同的 `models/ + services/ + views/ + widgets/` 形态；`settings` 只有视图（它读写其他模块的存储，而不是拥有数据文件）。`shared/` 保存一切跨领域内容：同步、备份、通知/提醒、本地 API 服务器、托盘/启动胶水和小的纯工具。

## 共享包（`myapps_data`）

WebDAV 同步引擎、备份引擎、ZIP 传输引擎、原子写入器和自动同步调度器**不在此仓库**。它们位于共享的 `myapps_data` 包中，作为 git 子模块嵌入在 `packages/myapps_data`，并作为 pub 路径依赖被消费。MyAnime、MyDay 和 MyDevice 都使用它，这正是它们的线上格式、备份格式和锁语义保持互通的原因。

- **留在这里的内容：** 所有模型、逐功能存储中枢、逐模块合并包装器，以及未知字段保留**模式**（它们命名 MyDay 自己的字段）。
- **移走的内容：** 传输、锁生命周期、合并流水线、`.sync_base` 快照、图像同步、备份捆绑与 blob 存储、ZIP 允许列表、原子写入器和同步调度。
- **接缝：** [`functions/app/data_modules.md`](functions/app/data_modules.md) 声明了基于 `TodoStorage` 的 `StorageAdapter`，外加每个数据文件一个 `DataModule`。它取代了本应用以前携带的五个硬编码数据文件清单副本中的四个，也是 MyDay 三个特例现在所在的地方：财务强制余额迁移（`postMergeTransform`）、整文件汇率合并和模式驱动保留（`preUploadTransform`）。
- **门面：** `WebDAVService`、`BackupService`、`ImportExportService`、`AutoSyncService` 和 `DataFileSafety` 保留它们此前的公共 API 并委托给该包。它们的形态被刻意冻结，使调用点和测试继续工作；行为变更属于该包。
- **未统一：** MyDay 的每日备份保持由 `ReminderService` 的 30 秒循环驱动，这正是 `AutoSyncService` 传 `onPeriodicTick: null` 的原因。

`.gitmodules` 使用相对 URL `../MyApps-DATA.git`，因此它按克隆所跟踪的远程解析——Gitea 克隆从 Gitea 拉取，GitHub 克隆从 GitHub 拉取，而且任何主机名都不会被提交。全新克隆需要 `git clone --recurse-submodules` 或 `git submodule update --init`。

## 核心架构规则

- **文件 I/O 走 `TodoStorage`。** `TodoStorage.getAppDir()` 解析实际存储目录，使用户配置的自定义存储路径在处处被尊重。配置读写专门走 `TodoStorage.readConfig()` / `writeConfig()`，使一个模块的配置写入不可能覆盖另一个模块先前写入 `storage_config.json` 的键。
- **写入时保留已知 JSON。** 保存已知数据文件时使用 `JsonPreservation`（`lib/shared/utils/json_preservation.dart`），使未知的顶层和逐记录字段在本地保存和 WebDAV 合并写入中都存活——这正是让新版应用的字段能经旧版往返而不被丢弃的东西。
- **串行、原子写入（写队列 + tmp-重命名）。** 每个模块数据文件（`FinanceStorage`、`IntimacyStorage`、`WeightStorage`、`TodoStorage` 的 `todo_data.json` 路径和 `ExchangeRateStorage`）都通过静态写队列串行化并发保存——如 `TodoStorage` 保留 `static Future<void> _writeQueue = Future<void>.value();` 并把每次保存链到它上（`lib/features/todo/services/todo_storage.dart`）——并经由带校验的 tmp-重命名辅助 `DataFileSafety.writeValidatedDataJson`（`lib/shared/services/data_file_safety.dart`）原子写入；财务保留自己等价的 `_atomicWriteJson`。这防止重叠的未 await 保存（如伴侣删除后多个主页回调触发）交错截断写入并弄乱 JSON 文件。
- **类型化存储异常和阻塞加载错误 UI 模式。** `load()` 只在数据文件不存在时返回 `null`。存在但不可读的文件抛出类型化异常——`FinanceStorageException` / `IntimacyStorageException` / `WeightStorageException` / `TodoStorageException`（底层是来自 `data_file_safety.dart` 的 `DataFileValidationException`）——因此损坏数据绝不静默当作空数据集。`DataFileSafety.validateDataJson` 对那个已知文件名用真实模型解析器解析 JSON，并把任何失败包装进 `DataFileValidationException`。每个主页都镜像 `finance_page.dart`：它显示阻塞加载错误视图、文件不可读时用 `<module>DataWriteBlocked` SnackBar 拒绝 `_saveData`，并在文件重新可读时自动恢复（`AutoSyncService` 重载监听器重新运行 `_loadData`）。只读的 Todo/Weight 提醒调用方捕获该异常并只跳过那一趟，而不是让提醒循环崩溃。
- **UTC `modifiedAt` + `settingsModifiedAt` 供最后写入者胜出。** 记录模型用 `DateTime.now().toUtc()` 作为 `modifiedAt`。设置级合并用显式 `settingsModifiedAt` 字段（也是 UTC）做 LWW 设置解决。本地时间 `modifiedAt` 值会破坏跨时区的同步冲突检测；以本地时间写入的旧数据保持可解析兼容，但所有新写入必须是 UTC。这些时间戳如何驱动合并见 [数据格式](data-formats.md) 和 [WebDAV 同步](sync.md)。
- **可选字段省略，不写 null。** 可选/空字段通常通过条件映射条目（`if (x != null) 'x': x`）完全留在 JSON 映射之外，而不是序列化为显式 `null`。
- **无应用侧风味门。** CI 传 `--dart-define=FLAVOR=full` 或 `store`，但目前 `lib/` 内没有基于风味的运行时行为门——除非被添加并文档化，否则不要假设 store/full 行为在运行时不同。

## 相关页面

- [数据格式](data-formats.md) 了解每个数据文件背后的精确字段。
- [WebDAV 同步](sync.md) 了解写队列/原子写入/UTC 时间戳规则如何喂入合并和上传流程。
- [备份与恢复](backup-restore.md) 了解 `DataFileSafety` 校验如何在恢复时复用。

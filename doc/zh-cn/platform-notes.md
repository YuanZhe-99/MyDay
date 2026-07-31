# 平台说明

主要来源：`AGENTS.md` 的"本地 HTTP API"、"通知、提醒、托盘和启动"和"平台注意事项"几节，对照 `lib/shared/services/local_api_server.dart`（CORS/Basic Auth/`data_unreadable` 行为经源码检查确认）交叉核对。

## 本地 HTTP API

`local_api_server.dart` 是**仅桌面**的，经 `TodoStorage.readConfig()` 从 `storage_config.json` 读取其配置。

- **配置键：** `apiPort`（默认 `7790`）、`apiListenAddress`（默认 `localhost`）、`apiEnabled`、`apiUsername`、`apiPassword`。
- **未带凭据的非回环绑定被拒绝**，报 `credentials_required`。
- **中间件：** 宽松 CORS（已确认：`_corsMiddleware()` 给每个响应添加 `_corsHeaders` 并以 `Response.ok('', headers: _corsHeaders)` 应答 `OPTIONS` 预检）、配置了凭据时的 Basic Auth（401 时带 `WWW-Authenticate: Basic realm="MyDay API"`）和 JSON 错误处理。
- **`data_unreadable`（HTTP 500）：** 既有数据文件无法解析时，待办、财务和体重处理器返回 `{"error":"data_unreadable"}` 且状态 500（与 [架构](architecture.md) 描述的相同类型化异常条件）。缺失文件仍使用端点文档化的空数据行为，写端点会在底层文件不可读时*在保存之前*中止。
- **认证范围：** 配置了 API 用户名和密码时，每个非 `OPTIONS` 请求都需要 Basic Auth，包括 localhost 请求。未配置凭据时，允许回环请求、拒绝非回环请求。
- **端点：**
  - `GET /ping`
  - `GET /todo/list?date=YYYY-MM-DD`
  - `GET /todo/day?date=YYYY-MM-DD` — 含日评分、总数和富化任务
  - `POST /todo/add` — 接受备注、提醒时间、子任务和一次性任务的重复
  - `POST /todo/complete` — 接受可选 `subtaskId` 和 `createNextRecurrence`
  - `POST /todo/score` — 接受 -5..5 的日评分
  - `GET /todo/stats`
  - `GET /finance/summary` — 默认币种转换的收入、支出、余额、总资产、账户余额和分类总计
  - `GET /finance/accounts` — 省略敏感卡字段
  - `GET /finance/categories?type=expense|income|transfer`
  - `GET /finance/transactions` — 分页、类型、月/日期范围、账户、分类的过滤器
  - `POST /finance/add_transaction` — 校验账户/分类 id、存储当前汇率快照、支持转账目标金额/币种
  - `GET /finance/subscriptions` — 可选 `includeInactive=true`
  - `GET /weight/list` — 含体脂、可选胸/腰/臀字段、有效继承测量、备注、日期时间和修改时间
  - `POST /weight/add` — 接受可选 `bodyFat`、`bustCm`、`waistCm`、`hipCm`、`notes` 和显式日期
  - `GET /weight/stats` — 保留旧键，同时添加 BMI、腰臀比、身高、体脂、最新记录和有效测量

绝不提交真实 API 凭据。端点或负载变化时，`AGENTS.md` 必须在同一变更中更新（按项目的维护规则）。

## 通知、提醒、托盘和启动

- **`ReminderService`** 在进程存活期间每 30 秒运行。订阅续费交易生成（每小时）和每日自动备份在每个平台运行；这个循环的用户可见提醒*通知*仅桌面，因为移动端经操作系统级调度通知投递提醒（因此用户绝不会被双重通知）。
- **桌面触发语义：** `now >= 提醒时间`且该提醒今天尚未触发时提醒触发——因此忙碌或被挂起的进程不可能完全跳过它的那一分钟；它只会晚触发。已触发键在 `_notifiedIds` 中按日期限定范围并持久化到 `storage_config.json`（`reminderNotifiedKeys`），使桌面重启不会重新触发已触发的提醒。
- 桌面循环跳过软删除的每日模板和今天已完成的每日模板。
- **通知后端：** 桌面用 `local_notifier`；移动端用带时区调度的 `flutter_local_notifications`。时区位置来自经 `flutter_timezone` 的操作系统 IANA zone id，绝不用 `DateTime.now().timeZoneName`。
- **移动端逐任务调度：** 每日模板用每日操作系统日程（今天已完成时移到明天开始）；未来一次性任务先使用一次性开始日期日程，激活后切到每日重复日程——见 [待办](features/todo.md)。
- **移动端订阅提醒**是未来 7 天的按日一次性通知（id `9100+offset`）；每天的提醒正文列出该日起 3 天内到期的续费，空天跳过——因此进入窗口的续费被通告，过期文本绝不重复。日程在数据变更、每小时续费处理（它也从存储加载订阅，因此财务页无需打开）和应用恢复时经 `refreshMobileSchedules()` 刷新。
- **移动端体重提醒**在记录落入宽限窗口时保持每日重复——重复被移到下一天开始，绝不被一次性通知替换。宽限窗口算法本身见 [体重](features/weight.md)。
- `SCHEDULE_EXACT_ALARM` 刻意**不**请求；调度使用 `inexactAllowWhileIdle`。
- **`TrayService`** 处理托盘图标/菜单、显示/退出、最小化到托盘、关闭到托盘，以及经 `TodoStorage` 持久化的设置。
- **`launch_at_startup`** 在应用启动时从 `PackageInfo.fromPlatform()` 和 `Platform.resolvedExecutable` 配置（见 [架构](architecture.md) 启动序列）。

## Android

- `android/app/build.gradle.kts` 使用 `import java.util.Properties`。
- 命名空间/应用 id：`com.yuanzhe.my_day`。
- 启用 Java 17 source/target 兼容性和核心库脱糖。
- **Kotlin 迁移状态（应用侧已迁移）：** Gradle wrapper `9.3.1`、AGP `9.1.1`；应用不再应用 `kotlin-android`。Kotlin `jvmTarget` 经顶层 `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }` 块设置（不用 `jvmToolchain`，它需要真实安装 JDK 17；不用已移除的 `kotlinOptions`）。`android/gradle.properties` 保留 Flutter 迁移器兼容标志 `android.builtInKotlin=false` 和 `android.newDsl=false`，因为多个插件仍应用 KGP——把 `builtInKotlin` 设为 `true` 会破坏每个应用 KGP 的插件（已验证）。`org.jetbrains.kotlin.android` 在 `settings.gradle.kts` 中保持声明（`apply false`），使应用 KGP 的插件能解析它。
- **`file_picker` 精确固定为 `10.3.7`**：既自己应用 KGP（`builtInKotlin=false` 时需要）*又*能对照 `flutter.compileSdkVersion` 编译（AGP 9 AAR 元数据检查需要）的最后一个版本。`10.3.9`+ 和 `11.x` 依赖 AGP 内置 Kotlin，在兼容模式下无法编译；`10.3.2` 及更早固定 `compileSdk 34`，无法通过元数据检查。不要用 caret 约束。其 Dart API 是 `FilePicker.platform.*`。
- 签名读取 `android/key.properties`（如存在）并在本地回退调试签名；发布签名秘密在 CI 中注入。
- 清单权限包括调度通知需要的 internet、notification 和 boot 相关条目。`SCHEDULE_EXACT_ALARM` 刻意不声明，因为所有调度使用非精确模式。
- CI 仍为 `flutter_timezone`、`package_info_plus`、`shared_preferences_android`、`wakelock_plus`、`flutter_local_notifications` 和 `file_picker` 打印 Flutter 的"应用 KGP 的插件"警告——仅插件侧，截至 2026-07 即使它们的最新版本仍应用 KGP。彻底消除需要在每个插件都提供 Built-in Kotlin 支持后翻转为 `android.builtInKotlin=true`。

## iOS

- `CFBundleDisplayName` 和 `CFBundleName` 是 `MyDay!!!!!`。
- iPhone 支持竖屏和横屏左/右；iPad 还支持倒置竖屏。
- 启动器图标从 `assets/icon/app_icon_ios.png`、`assets/icon/app_icon_ios_dark.png` 和 `assets/icon/app_icon_ios_tinted.png` 生成；默认是不透明白背景来源，深色/着色来源保持透明背景，iOS 从这些来源回退，无需原生 Icon Composer / Liquid Glass Clear 资源。
- CI 构建不带签名的侧载 IPA；App Store IPA 需要当前工作流之外的签名/预置描述文件。

## macOS

- `macos/Runner/Configs/AppInfo.xcconfig` 中的产品名是 `MyDay!!!!!`。
- Bundle id 是 `com.yuanzhe.myDay`。
- 部署目标是 `13.0`，LaunchAtLogin-Modern 需要。
- `DebugProfile.entitlements` 包括应用沙盒、allow-jit、network client 和 network server。`Release.entitlements` 包括应用沙盒、network client 和 network server。WebDAV 和汇率 API 需要 network client；本地 API 服务器需要 network server。
- `MainFlutterWindow.swift` 包含启动插件的 LaunchAtLogin 集成。

## Windows

- Inno Setup 安装包在 `installer.iss` 中定义。
- `AppName` 是 `MyDay!!!!!`；`AppVersion` 是应用语义版本。
- x64 输出：`build\installer\MyDay_X.Y.Z_Setup.exe`。ARM64 输出：`build\installer\MyDay_X.Y.Z_arm64_Setup.exe`。`#ifdef ARM64` 选择架构和源路径。
- `PrivilegesRequired=lowest`；没有明确理由不要引入管理员要求。
- 应用图标：`windows/runner/resources/app_icon.ico`。
- `pubspec.yaml` 中的 MSIX 配置使用 `internetClient` 和 `install_certificate: false`。

## 相关页面

- [架构](architecture.md) — 接线通知、开机自启、本地 API 服务器、`ReminderService`、`AutoSyncService` 和托盘的启动序列。
- [设置](features/settings.md) — 暴露托盘、启动和本地 API 控件的桌面设置小节。

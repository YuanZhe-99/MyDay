# lib/shared/services/mobile_notification_service.dart

`MobileNotificationService` 包装 `flutter_local_notifications` 在 Android/iOS 上调度操作系统级通知，这是 MyDay 在应用进程被杀时仍在移动端送达提醒的方式（区别于桌面端 `ReminderService` 的 30 秒循环在进程存活时自己触发提醒）。它经 `flutter_timezone` 解析设备真实 IANA 时区，使调度正确经受 DST，然后暴露 `ReminderService` 组合成实际逐任务/逐日提醒逻辑的一次性、每日重复和范围取消调度原语。桌面/移动通知拆分、`inexactAllowWhileIdle` 调度模式以及为何刻意不请求 `SCHEDULE_EXACT_ALARM` 见 [平台说明](../../../platform-notes.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `MobileNotificationService._` | 构造函数（`MobileNotificationService`） | B | 支撑单例的私有构造函数。 |
| [`isMobile`](#ismobile) | getter（静态） | B | 当前平台是否为 Android 或 iOS。 |
| [`init`](#init) | 方法（`MobileNotificationService`） | A | 初始化插件、时区和 Android 13+ 权限。 |
| [`showNow`](#shownow) | 方法（`MobileNotificationService`） | A | 显示即时通知。 |
| [`scheduleDaily`](#scheduledaily) | 方法（`MobileNotificationService`） | A | 调度今天/明天开始的每日重复通知。 |
| [`scheduleDailyStarting`](#scheduledailystarting) | 方法（`MobileNotificationService`） | A | 调度不早于给定日期/时间的每日重复通知。 |
| [`scheduleAt`](#scheduleat) | 方法（`MobileNotificationService`） | A | 在特定日期/时间调度一次性通知。 |
| [`cancel`](#cancel) | 方法（`MobileNotificationService`） | A | 按 id 取消已调度通知。 |
| [`cancelPendingInIdRange`](#cancelpendinginidrange) | 方法（`MobileNotificationService`） | A | 取消 id 落在范围内的每个挂起通知。 |

**对账：** `grep -c 'Purpose:' lib/shared/services/mobile_notification_service.dart` 返回 9，与上面 9 行精确匹配。每个块都文档化其正下方的真实声明（构造函数、getter 或方法）——未发现错附块和未文档化声明。

## 文档

### `Future<void> init()` <a id="init"></a>
- **种类：** `MobileNotificationService` 的方法
- **来源：** `lib/shared/services/mobile_notification_service.dart`（第 36 行）
- **用途：** 一次性设置：用设备真实时区初始化 tz 数据库、接上 `flutter_local_notifications` 插件并请求 Android 13+ 运行时通知权限。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 设置全局 `tz.local` 位置、调用 `_plugin.initialize(...)`、可能提示用户 Android 通知权限并设 `_initialized = true`。
- **算法：**
  1. 非移动（`Platform.isAndroid || Platform.isIOS`）或已初始化时立即返回。
  2. 调用 `tz.initializeTimeZones()`。
  3. 尝试 `FlutterTimezone.getLocalTimezone()` 和 `tz.setLocalLocation(tz.getLocation(info.identifier))`，用操作系统报告 IANA 区域 id。
  4. 失败时回退：计算当前 UTC 偏移（`DateTime.now().timeZoneOffset`）并搜索 `tz.timeZoneDatabase.locations` 找任何 `currentTimeZone.offset`（毫秒）匹配的位置；找到则用第一个匹配。
  5. 构建 Android（`@mipmap/ic_launcher`）和 iOS（alert/badge/sound 权限请求）初始化设置并调用 `_plugin.initialize(...)`。
  6. Android 上调用 `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission()`。
  7. 设 `_initialized = true`。
- **用法：**
  ```dart
  if (Platform.isAndroid || Platform.isIOS) {
    await MobileNotificationService.instance.init();
  }
  ```
  （`lib/main.dart:27-28`，应用启动时。）
- **备注：** 用操作系统 IANA 区域 id 而非 `DateTime.now().timeZoneName` 重要，因为后者是 tz 数据库无法直接查找的缩写（如 "JST"/"CST"），仅偏移回退可能选到与设备实际区域 DST 规则不同的区域。

### `Future<void> showNow({required int id, required String title, required String body})` <a id="shownow"></a>
- **种类：** `MobileNotificationService` 的方法
- **来源：** `lib/shared/services/mobile_notification_service.dart`（第 89 行）
- **用途：** 触发即时（非调度）通知，用作 `ReminderService` 想立刻通知用户时的移动回退路径。
- **输入：** `id` — 唯一通知 id；`title`、`body` — 显示文本。
- **返回：** `Future<void>`。
- **副作用：** 调用 `_plugin.show(...)`，立即发布操作系统通知。
- **算法：**
  1. 尚未 `_initialized` 时立即返回。
  2. 构建 `NotificationDetails`（Android 频道 `myday_reminders`、`Importance.high` / `Priority.high`；iOS 默认 `DarwinNotificationDetails`）。
  3. 调用 `_plugin.show(id, title, body, details)`。
- **用法：**
  ```dart
  MobileNotificationService.instance.showNow(
    id: _notifyCounter++,
    title: 'MyDay!!!!!',
    body: message,
  );
  ```
  （`lib/shared/services/reminder_service.dart:1004-1008`，`_notify()` 的移动分支内。）
- **备注：** 无。

### `Future<void> scheduleDaily({required int id, required String title, required String body, required TimeOfDay time})` <a id="scheduledaily"></a>
- **种类：** `MobileNotificationService` 的方法
- **来源：** `lib/shared/services/mobile_notification_service.dart`（第 115 行）
- **用途：** 便利包装，调度锚定到今天日期、给定时刻 的每日重复通知。
- **输入：** `time` — 每日触发时间（日期分量被忽略并替换为今天）。
- **返回：** `Future<void>`。
- **副作用：** 委托给 [`scheduleDailyStarting`](#scheduledailystarting)。
- **算法：**
  1. 计算 `now = DateTime.now()`。
  2. 用今天年/月/日加 `time.hour`/`time.minute` 构建 `startDateTime` 调用 `scheduleDailyStarting`。
- **用法：**
  ```dart
  mns.scheduleDaily(
    id: id,
    title: 'MyDay!!!!!',
    body: _l10n.notifWeightReminder,
    time: time,
  );
  ```
  （`lib/shared/services/reminder_service.dart:452-457`，宽限窗口外调度体重提醒。）
- **备注：** 无。

### `Future<void> scheduleDailyStarting({required int id, required String title, required String body, required DateTime startDateTime})` <a id="scheduledailystarting"></a>
- **种类：** `MobileNotificationService` 的方法
- **来源：** `lib/shared/services/mobile_notification_service.dart`（第 142 行）
- **用途：** 调度首次触发不早于 `startDateTime` 的每日重复通知，让调用方能推迟首次重复（如到明天）同时之后仍每日重复。
- **输入：** `startDateTime` — 最早允许的首次触发；调度生效后只有其时刻重要，因为重复用 `matchDateTimeComponents: DateTimeComponents.time`。
- **返回：** `Future<void>`。
- **副作用：** 取消任何带 `id` 的既有通知，然后调用 `_plugin.zonedSchedule` 安装重复操作系统调度。
- **算法：**
  1. 尚未 `_initialized` 时立即返回。
  2. 取消任何带 `id` 的既有通知。
  3. 构建 `NotificationDetails`（与 `showNow` 相同频道）。
  4. 计算 `now = tz.TZDateTime.now(tz.local)` 和 `scheduledDate = tz.TZDateTime.from(startDateTime, tz.local)`。
  5. `scheduledDate` 不晚于 `now` 时把它重新计算为 `startDateTime` 时/分的*今天*；该重算时间仍不晚于 `now` 时加一天（推到明天）。
  6. 调用 `_plugin.zonedSchedule(id, title, body, scheduledDate, details, androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, matchDateTimeComponents: DateTimeComponents.time)`——`matchDateTimeComponents` 参数正是让操作系统每天在那一刻重复此通知的东西。
- **用法：**
  ```dart
  mns.scheduleDailyStarting(
    id: id,
    title: 'MyDay!!!!!',
    body: _l10n.notifWeightReminder,
    startDateTime: candidate.add(const Duration(days: 1)),
  );
  ```
  （`lib/shared/services/reminder_service.dart:444-449`，今天的记录落在宽限窗口内时把体重提醒每日重复移到明天开始。）
- **备注：** 步骤 5 的两阶段重算正是让调用方传已过去 `startDateTime`（如已过 8 点仍传"今天 8 点"）仍获得有效次日调度而非错误或立即触发通知的东西。

### `Future<void> scheduleAt({required int id, required String title, required String body, required DateTime dateTime})` <a id="scheduleat"></a>
- **种类：** `MobileNotificationService` 的方法
- **来源：** `lib/shared/services/mobile_notification_service.dart`（第 196 行）
- **用途：** 在精确日期/时间调度一次性（非重复）通知。
- **输入：** `dateTime` — 精确触发时刻。
- **返回：** `Future<void>`。
- **副作用：** 取消任何带 `id` 的既有通知，然后可能调用 `_plugin.zonedSchedule`。
- **算法：**
  1. 尚未 `_initialized` 时立即返回。
  2. 取消任何带 `id` 的既有通知。
  3. 构建 `NotificationDetails`。
  4. 计算 `scheduledDate = tz.TZDateTime.from(dateTime, tz.local)`；早于当前 `tz.TZDateTime.now(tz.local)` 时不调度地返回（静默跳过过期的单发）。
  5. 用 `androidScheduleMode: inexactAllowWhileIdle` 且无 `matchDateTimeComponents`（因此只触发一次，非每日）调用 `_plugin.zonedSchedule(...)`。
- **用法：**
  ```dart
  await mns.scheduleAt(
    id: _mobileSubReminderDayBaseId + offset,
    title: 'MyDay!!!!!',
    body: _l10n.notifUpcomingRenewals(upcoming.join(', ')),
    dateTime: fireAt,
  );
  ```
  （`lib/shared/services/reminder_service.dart:386-391`，调度未来 7 天的逐日订阅续费单发。）
- **备注：** 缺失 `matchDateTimeComponents` 参数（[`scheduleDailyStarting`](#scheduledailystarting) 有但这里没有）正是区分单发与每日重复的实际机制——两者否则调用相同插件方法。

### `Future<void> cancel(int id)` <a id="cancel"></a>
- **种类：** `MobileNotificationService` 的方法
- **来源：** `lib/shared/services/mobile_notification_service.dart`（第 236 行）
- **用途：** 按 id 取消单个已调度通知。
- **输入：** `id`。
- **返回：** `Future<void>`。
- **副作用：** 调用 `_plugin.cancel(id)`。
- **算法：** 未 `_initialized` 时立即返回；否则调用 `_plugin.cancel(id)`。
- **用法：**
  ```dart
  mns.cancel(_mobileWeightMorningId);
  ```
  （`lib/shared/services/reminder_service.dart:410`，用户禁用早间体重提醒时清除它。）
- **备注：** 无。

### `Future<void> cancelPendingInIdRange({required int minId, required int maxId})` <a id="cancelpendinginidrange"></a>
- **种类：** `MobileNotificationService` 的方法
- **来源：** `lib/shared/services/mobile_notification_service.dart`（第 247 行）
- **用途：** 批量取消 id 落在 `[minId, maxId]` 内的每个挂起通知，一次清空整个 ID 命名空间（如所有逐任务提醒 id），无论实际调度了哪些特定 id。
- **输入：** `minId`、`maxId` — 要清除 id 范围的包含边界。
- **返回：** `Future<void>`。
- **副作用：** 读取 `_plugin.pendingNotificationRequests()` 并对每个匹配调用 `_plugin.cancel(...)`。
- **算法：**
  1. 未 `_initialized` 时立即返回。
  2. 经 `_plugin.pendingNotificationRequests()` 获取所有挂起请求。
  3. 对每个 `id` 满足 `id >= minId && id <= maxId` 的请求调用 `_plugin.cancel(request.id)`。
- **用法：**
  ```dart
  await mns.cancelPendingInIdRange(
    minId: _mobileTaskReminderMinId,
    maxId: _mobileTaskReminderMaxId,
  );
  ```
  （`lib/shared/services/reminder_service.dart:515-518`，重新调度当前任务前清除所有先前调度逐任务通知——包括旧应用版本或先前启动留下的。）
- **备注：** 与要求知道精确 id 的 [`cancel`](#cancel) 不同，这是清理当前应用状态可能不再跟踪的 id（如应用版本间 ID 算法变化后）的机制。

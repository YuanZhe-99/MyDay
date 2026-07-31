# lib/shared/services/reminder_service.dart

`ReminderService` 是全局单例提醒引擎，从 `main()` 启动一次（见 [架构](../../../architecture.md) 启动序列）并独立于当前打开哪个标签或页面存活。其 30 秒 `Timer.periodic` 循环（`_check`）在**每个**平台驱动三件事——每小时订阅续费交易生成、经 `BackupService.runAutoBackupIfNeeded()` 的每日自动备份、刷新缓存提醒数据——但只在**桌面**自己触发用户可见提醒*通知*，因为移动端改经 `MobileNotificationService`（`mobile_notification_service.md`）获得逐任务/逐日操作系统级调度通知，使用户绝不被通知两次。桌面/移动拆分见 [平台说明 — 通知、提醒、托盘和启动](../../../platform-notes.md#notifications-reminders-tray-and-startup)，本文件为体重提醒实现的宽限窗口算法见 [体重 — 提醒宽限窗口](../../../features/weight.md#reminder-grace-window)。功能页（`todo_page.dart`、`weight_page.dart`、`finance_page.dart`）在数据变化时经 `updateData`/`updateWeightData`/`updateSubscriptionData` 把缓存数据推进此服务，`app_settings.dart`/`shell_scaffold.dart` 接语言区域更新和应用内 snackbar 回调。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `ReminderService._()` | 构造函数（`ReminderService`） | B | 阻止提醒单例直接实例化。 |
| `_l10n` | getter（`ReminderService`） | B | 为当前语言区域解析本地化字符串。 |
| `updateLocale` | 方法（`ReminderService`） | B | 更新通知文本使用的缓存语言区域。 |
| [`start`](#start) | 方法（`ReminderService`） | A | 启动 30 秒周期提醒循环。 |
| [`stop`](#stop) | 方法（`ReminderService`） | A | 停止周期提醒循环。 |
| [`refreshMobileSchedules`](#refreshmobileschedules) | 方法（`ReminderService`） | A | 重新调度所有操作系统级移动提醒通知。 |
| [`updateData`](#updatedata) | 方法（`ReminderService`） | A | 把新鲜 Todo 数据/设置推进缓存并重新调度移动 todo 提醒。 |
| [`updateSubscriptionData`](#updatesubscriptiondata) | 方法（`ReminderService`） | A | 把新鲜订阅数据/设置推进缓存并重新调度移动续费提醒。 |
| [`updateWeightData`](#updateweightdata) | 方法（`ReminderService`） | A | 把新鲜体重数据/设置推进缓存并重新调度移动体重提醒。 |
| [`_stableHash`](#_stablehash) | 方法（静态，`ReminderService`） | A | 计算字符串的稳定 FNV-1a 哈希。 |
| [`_taskNotificationId`](#_tasknotificationid) | 方法（静态，`ReminderService`） | A | 从任务的字符串 id 派生稳定操作系统通知 id。 |
| [`firstOneTimeReminderDateTime`](#firstonetimereminderdatetime) | 方法（静态，`ReminderService`） | A | 返回一次性任务的首次提醒日期/时间。 |
| [`nextOneTimeReminderDateTime`](#nextonetimereminderdatetime) | 方法（静态，`ReminderService`） | A | 从参考点返回一次性任务的下次提醒日期/时间。 |
| [`shouldUseDailyMobileOneTimeReminder`](#shouldusedailymobileonetimereminder) | 方法（静态，`ReminderService`） | A | 决定移动端能否为一次性任务用每日重复调度。 |
| [`shouldNotifyOneTimeTask`](#shouldnotifyonetimetask) | 方法（静态，`ReminderService`） | A | 决定一次性任务的提醒在给定时刻是否到期（桌面循环）。 |
| [`_isActiveOneTimeTask`](#_isactiveonetimetask) | 方法（静态，`ReminderService`） | A | 决定未完成一次性任务今天是否算挂起。 |
| [`_scheduleMobileSubscriptionReminder`](#_schedulemobilesubscriptionreminder) | 方法（`ReminderService`） | A | 启动（即发即忘）移动订阅提醒重建。 |
| [`_scheduleMobileSubscriptionReminderAsync`](#_schedulemobilesubscriptionreminderasync) | 方法（`ReminderService`） | A | 重建逐日移动订阅续费单发。 |
| [`_scheduleMobileWeightReminders`](#_schedulemobileweightreminders) | 方法（`ReminderService`） | A | 调度或取消移动早间/晚间体重提醒。 |
| [`_scheduleMobileWeightReminder`](#_schedulemobileweightreminder) | 方法（`ReminderService`） | A | 调度一个移动体重提醒，尊重宽限窗口。 |
| [`_scheduleMobileTodoReminders`](#_schedulemobiletodoreminders) | 方法（`ReminderService`） | A | 调度或取消移动早间/完成 todo 提醒和逐任务提醒。 |
| [`_scheduleMobilePerTaskReminders`](#_schedulemobilepertaskreminders) | 方法（`ReminderService`） | A | 启动（即发即忘）带生成跟踪的逐任务移动提醒重建。 |
| [`_scheduleMobilePerTaskRemindersAsync`](#_schedulemobilepertaskremindersasync) | 方法（`ReminderService`） | A | 取消过期逐任务调度并重新调度当前每日/一次性任务提醒。 |
| [`_check`](#_check) | 方法（`ReminderService`） | A | 30 秒滴答：续费、自动备份和（仅桌面）提醒触发。 |
| [`_upcomingRenewalLines`](#_upcomingrenewallines) | 方法（`ReminderService`） | A | 为某天 3 天内到期的订阅构建本地化续费行。 |
| [`_loadNotifiedKeys`](#_loadnotifiedkeys) | 方法（`ReminderService`） | A | 从存储配置加载今天已触发提醒键。 |
| [`_persistNotifiedKeys`](#_persistnotifiedkeys) | 方法（`ReminderService`） | A | 把今天已触发提醒键持久化进存储配置。 |
| [`_todayAt`](#_todayat) | 方法（`ReminderService`） | A | 把今天日期与 `TimeOfDay` 组合成 `DateTime`。 |
| [`_shouldSkipWeightReminder`](#_shouldskipweightreminder) | 方法（`ReminderService`） | A | 把宽限窗口检查锚定在给定触发时刻的实例包装。 |
| [`shouldSkipWeightReminderAt`](#shouldskipweightreminderat) | 方法（静态，`ReminderService`） | A | 体重提醒抑制的纯宽限窗口决策。 |
| [`_refreshWeightDataFromStorage`](#_refreshweightdatafromstorage) | 方法（`ReminderService`） | A | 从 `WeightStorage` 重新加载体重记录和提醒设置。 |
| [`_processRenewals`](#_processrenewals) | 方法（`ReminderService`） | A | 生成过期订阅续费交易，至多每小时一次。 |
| [`_notify`](#_notify) | 方法（`ReminderService`） | A | 触发单个提醒通知（桌面 `local_notifier` / 移动即时）加应用内 snackbar。 |

**对账：** `grep -c 'Purpose:' lib/shared/services/reminder_service.dart` 返回 33，与上面 33 行精确匹配——每个块都文档化紧贴其下方的真实声明（构造函数、`_l10n` getter 或方法）。未发现错附块（`Purpose:` 块记录调用点语句而非真实声明的）和未文档化真实声明。只有私有构造函数、平凡 `_l10n` getter 和 `updateLocale`（除那之外无分支或副作用的单个字段赋值）归为 Tier B；每个其他方法带真实分支、循环或有副作用调用（存储 IO、操作系统通知调度或触发另一个此类调用），与一揽子"服务"Tier A 规则一致。`_check` 函数体内声明的嵌套本地函数 `shouldFire` 不作为自己的声明列出——它无文档注释，纯粹是 `_check` 实现的一部分，在该方法下面的 Algorithm 中描述。字段（`_timer`、`_notifiedIds`、缓存数据字段、通知 id 常量、`onShowSnackbar`、`onRenewalsProcessed` 等）只带普通 `///` 注释而非 `Purpose:` 块，不列为单独声明，与本目录姊妹页（如 `backup_service.md`）把普通注释字段当作数据而非函数的方式一致。

## 文档

### `void start()` <a id="start"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 83 行）
- **用途：** 启动（或重启）30 秒周期提醒循环并立即运行一次检查。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 取消任何既有 `_timer`、创建新 `Timer.periodic(30s, _check)` 并同步调用一次 `_check()`（即发即忘，因为 `_check` 是 `async`）。
- **算法：** `_timer?.cancel(); _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check()); _check();`——无分支。
- **用法：**
  ```dart
  // Start global reminder timer — runs regardless of which tab is active
  ReminderService.instance.start();
  ```
  （`lib/main.dart:51`，应用启动时一次，与 `AutoSyncService.instance.start()` 一起。）
- **备注：** 再次调用 `start()`（当前不会）会因 `_timer?.cancel()` 守卫安全替换既有计时器而非堆叠第二个。

### `void stop()` <a id="stop"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 94 行）
- **用途：** 停止周期提醒循环。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 取消 `_timer` 并把它设为 `null`。
- **算法：** `_timer?.cancel(); _timer = null;`
- **用法：** 当前 `lib/` 中无任何调用点——`main()` 调用 `start()` 后服务运行整个进程生命周期；作为 `start()` 的生命周期对应物提供。
- **备注：** 即使从未启动也可安全调用（`_timer` 可空且 `?.cancel()` 空操作）。

### `void refreshMobileSchedules()` <a id="refreshmobileschedules"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 105 行）
- **用途：** 从当前缓存数据重新调度所有操作系统级移动提醒通知（todo、订阅、体重）。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 移动端顺序调用 `_scheduleMobileTodoReminders()`、`_scheduleMobileSubscriptionReminder()` 和 `_scheduleMobileWeightReminders()`；桌面端空操作。
- **算法：** `if (!MobileNotificationService.isMobile) return;` 然后调用三个 `_scheduleMobile*` 方法。
- **用法：**
  ```dart
  if (state == AppLifecycleState.resumed) {
    _trySync();
    ReminderService.instance.refreshMobileSchedules();
  }
  ```
  （`lib/shared/services/auto_sync_service.dart:221-225`，`didChangeAppLifecycleState`，使设备挂起后从当前数据重新计算逐日调度。也从 `lib/shared/views/backup_page.dart:218` 恢复后调用，因为恢复数据可改变提醒设置。）
- **备注：** 这是三个移动调度族一起刷新的唯一地方；单个 `update*Data` 调用只刷新自己的族。

### `void updateData({required List<Task> dailyTemplates, required List<Task> oneTimeTasks, required DailyCompletionLog dailyLog, TimeOfDay? morningReminderTime, TimeOfDay? completionReminderTime})` <a id="updatedata"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 118 行）
- **用途：** 缓存当前 Todo 数据（每日模板、一次性任务、完成日志）和提醒时间设置，然后从中重新调度移动 todo 提醒。
- **输入：** `dailyTemplates`、`oneTimeTasks`、`dailyLog`、`morningReminderTime`、`completionReminderTime`（后两个可选——`null` 禁用该提醒）。
- **返回：** 无。
- **副作用：** 覆盖 `_dailyTemplates`/`_oneTimeTasks`/`_dailyLog`/`_morningReminderTime`/`_completionReminderTime`；调用 `_scheduleMobileTodoReminders()`。
- **算法：** 直线字段赋值，然后委托 [`_scheduleMobileTodoReminders`](#_schedulemobiletodoreminders)。
- **用法：**
  ```dart
  ReminderService.instance.updateData(
    dailyTemplates: const [],
    oneTimeTasks: const [],
    dailyLog: DailyCompletionLog(),
  );
  ```
  （`lib/features/todo/views/todo_page.dart:98-102`，加载失败时，清除缓存提醒数据使损坏 Todo 文件不继续触发过期提醒；也 `todo_page.dart:190` 每次成功加载时调用。）
- **备注：** 这是桌面循环在 `_check()` 自己的 `TodoStorage.load()` 回退外*唯一*的 Todo 数据源——两者保持独立，使即使本会话从未打开 Todo 页提醒循环也继续工作。

### `void updateSubscriptionData({required List<Subscription> subscriptions, int? reminderHour, int? reminderMinute})` <a id="updatesubscriptiondata"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 139 行）
- **用途：** 缓存当前订阅列表和续费提醒时间，然后重新调度移动订阅提醒。
- **输入：** `subscriptions`；`reminderHour`/`reminderMinute`（两者必须一起提供才产生非 null `TimeOfDay`，否则提醒禁用）。
- **返回：** 无。
- **副作用：** 覆盖 `_subscriptions`/`_subscriptionReminderTime`；调用 `_scheduleMobileSubscriptionReminder()`。
- **算法：** `_subscriptions = subscriptions; _subscriptionReminderTime = (reminderHour != null && reminderMinute != null) ? TimeOfDay(...) : null;` 然后委托 [`_scheduleMobileSubscriptionReminder`](#_schedulemobilesubscriptionreminder)。
- **用法：**
  ```dart
  void _updateReminderService() {
    ReminderService.instance.updateSubscriptionData(
      subscriptions: _subscriptions,
      reminderHour: _subscriptionReminderHour,
      reminderMinute: _subscriptionReminderMinute,
    );
  }
  ```
  （`lib/features/finance/views/finance_page.dart:227-233`，财务页打开时订阅或提醒时间变化调用。）
- **备注：** `_processRenewals()` 也独立于存储刷新 `_subscriptions`/`_subscriptionReminderTime`，因此即使本会话从未打开财务页订阅提醒也工作——此方法只是在打开时让循环立即同步。

### `void updateWeightData({List<WeightRecord>? records, int? morningHour, int? morningMinute, int? eveningHour, int? eveningMinute, int? reminderGraceMinutes})` <a id="updateweightdata"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 157 行）
- **用途：** 缓存当前体重记录和提醒设置，然后重新调度移动体重提醒。
- **输入：** `records`（非 null 时只覆盖缓存并标记已加载）；四个时/分对（每对必须一起提供才启用该提醒）；`reminderGraceMinutes`（省略时回退先前值）。
- **返回：** 无。
- **副作用：** 条件覆盖 `_weightRecords`/`_weightDataLoaded`；覆盖 `_weightMorningReminder`/`_weightEveningReminder`/`_weightReminderGraceMinutes`；调用 `_scheduleMobileWeightReminders()`。
- **算法：**
  1. `records != null` 时设 `_weightRecords = records` 和 `_weightDataLoaded = true`。
  2. 经三元构建 `_weightMorningReminder`/`_weightEveningReminder`——该提醒时和分都非 null 否则 `null`。
  3. `_weightReminderGraceMinutes = reminderGraceMinutes ?? _weightReminderGraceMinutes`。
  4. 委托 [`_scheduleMobileWeightReminders`](#_schedulemobileweightreminders)。
- **用法：**
  ```dart
  ReminderService.instance.updateWeightData(
    records: _records,
    morningHour: _weightMorningReminder?.hour,
    morningMinute: _weightMorningReminder?.minute,
    eveningHour: _weightEveningReminder?.hour,
    eveningMinute: _weightEveningReminder?.minute,
    reminderGraceMinutes: _reminderGraceMinutes,
  );
  ```
  （`lib/features/weight/views/weight_page.dart:133-140`，每次加载后；也 `weight_page.dart:106` 加载失败时带 `records: const []` 调用。）
- **备注：** `records` 可空设计让仅设置更新（如从设置对话框改宽限分钟）推新提醒时间而无需同时重新提供完整记录列表。

### `static int _stableHash(String value)` <a id="_stablehash"></a>
- **种类：** `ReminderService` 的静态方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 204 行）
- **用途：** 计算字符串的稳定 31 位 FNV-1a 风格哈希，因为 Dart 内置 `String.hashCode` 不保证跨应用启动稳定。
- **输入：** `value` — 要哈希的字符串（任务 id）。
- **返回：** `int`，掩码为 `& 0x7fffffff`（非负，31 位）。
- **副作用：** 无。
- **算法：** 标准 FNV-1a：从 `hash = 0x811c9dc5` 开始；对每个 UTF-16 码元 XOR 进 `hash`，然后乘 FNV 素数 `0x01000193`，每次迭代掩码到 31 位。
- **用法：** 只从 [`_taskNotificationId`](#_tasknotificationid) 调用：`_stableHash(taskId) % _mobileTaskReminderIdRange`。
- **用途：** 跨启动稳定（不同于 `Object.hashCode`）正是让 `_scheduleMobilePerTaskRemindersAsync` 稍后重算相同 id 取消任务先前操作系统通知、无需在任何地方持久化 id 到任务映射的东西。

### `static int _taskNotificationId(String taskId)` <a id="_tasknotificationid"></a>
- **种类：** `ReminderService` 的静态方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 219 行）
- **用途：** 为任务派生稳定操作系统通知 id，限制在逐任务 id 范围内。
- **输入：** `taskId`。
- **返回：** `[_mobileTaskReminderMinId, _mobileTaskReminderMaxId]`（`[10000, 109999]`）中的 `int`。
- **副作用：** 无。
- **算法：** `_mobileTaskReminderMinId + _stableHash(taskId) % _mobileTaskReminderIdRange`。
- **用法：** 从 `_scheduleMobilePerTaskRemindersAsync` 为每个每日模板和一次性任务调用：`final nid = _taskNotificationId(task.id);`（第 530 / 566 行）。
- **备注：** 两个任务 id 间哈希碰撞会让一个任务静默覆盖另一个的调度通知（最后调度胜出）；100000 宽 id 范围让这在实践中不太可能，但不防碰撞。

### `static DateTime? firstOneTimeReminderDateTime(Task task)` <a id="firstonetimereminderdatetime"></a>
- **种类：** `ReminderService` 的静态方法（`@visibleForTesting`）
- **来源：** `lib/shared/services/reminder_service.dart`（第 229 行）
- **用途：** 返回一次性任务的首次（原始调度）提醒日期/时间。
- **输入：** `task`。
- **返回：** 首次提醒 `DateTime`，任务每日、无 `reminderTime`/`scheduledDate` 或已完成时 `null`。
- **副作用：** 无。
- **算法：** 任何不合格条件返回 `null`；否则把 `task.scheduledDate` 的年/月/日与 `task.reminderTime` 的时/分组合成新 `DateTime`。
- **用法：**
  ```dart
  expect(
    ReminderService.firstOneTimeReminderDateTime(task),
    DateTime(2026, 6, 10, 9),
  );
  ```
  （`test/widget_test.dart:273-275`。也内部从 [`nextOneTimeReminderDateTime`](#nextonetimereminderdatetime)、[`shouldUseDailyMobileOneTimeReminder`](#shouldusedailymobileonetimereminder) 和 `_scheduleMobilePerTaskRemindersAsync` 调用。）
- **备注：** 保留原始调度日期，独立于建在其上的任何较晚每日重复计算。

### `static DateTime? nextOneTimeReminderDateTime(Task task, DateTime now)` <a id="nextonetimereminderdatetime"></a>
- **种类：** `ReminderService` 的静态方法（`@visibleForTesting`）
- **来源：** `lib/shared/services/reminder_service.dart`（第 254 行）
- **用途：** 一旦任务开始每日重复，从参考点返回其下次提醒日期/时间。
- **输入：** `task`；`now` — 参考点。
- **返回：** 下次提醒 `DateTime`，任务根本不该提醒时 `null`。
- **副作用：** 无。
- **算法：**
  1. 取 `start = firstOneTimeReminderDateTime(task)`；为 `null` 则返回 `null`。
  2. `start.isAfter(now)` 时原样返回 `start`（仍在首次触发前）。
  3. 否则从今天日期加 `task.reminderTime` 的时/分构建 `todayReminder`；晚于 `now` 则返回它；否则返回它加一天。
- **用法：**
  ```dart
  expect(
    ReminderService.nextOneTimeReminderDateTime(task, DateTime(2026, 6, 9, 12)),
    DateTime(2026, 6, 10, 9),
  );
  ```
  （`test/widget_test.dart:259-264`。也 [`shouldUseDailyMobileOneTimeReminder`](#shouldusedailymobileonetimereminder) 为 true 时从 `_scheduleMobilePerTaskRemindersAsync` 调用，计算每日调度开始时间。）
- **备注：** 越过首次提醒后，表现像锚定在 `task.reminderTime` 时刻的每日重复，无论已过多少天。

### `static bool shouldUseDailyMobileOneTimeReminder(Task task, DateTime now)` <a id="shouldusedailymobileonetimereminder"></a>
- **种类：** `ReminderService` 的静态方法（`@visibleForTesting`）
- **来源：** `lib/shared/services/reminder_service.dart`（第 277 行）
- **用途：** 决定移动端能否为一次性任务用每日重复操作系统调度，而非单发。
- **输入：** `task`；`now`。
- **返回：** `bool` — 任务安排日期是今天或更早时 `true`。
- **副作用：** 无。
- **算法：** 取 `firstReminder = firstOneTimeReminderDateTime(task)`；为 `null` 返回 `false`；否则返回 `!scheduledDate.isAfter(today)`（仅日期比较，时间丢弃）。
- **用法：**
  ```dart
  expect(
    ReminderService.shouldUseDailyMobileOneTimeReminder(task, DateTime(2026, 6, 9, 12)),
    isFalse,
  );
  expect(
    ReminderService.shouldUseDailyMobileOneTimeReminder(task, DateTime(2026, 6, 10, 8)),
    isTrue,
  );
  ```
  （`test/widget_test.dart:276-289`。驱动 `_scheduleMobilePerTaskRemindersAsync` 内的单发-vs-每日分支。）
- **备注：** 每日重复操作系统调度只匹配时刻，不匹配日期——因此*未来*安排的一次性任务必须先用单发（见 [mobile_notification_service.md](mobile_notification_service.md#scheduleat) 的 `scheduleAt`），日期到达后切换每日调度，按 [Todo](../../../features/todo.md)。

### `static bool shouldNotifyOneTimeTask(Task task, DateTime now)` <a id="shouldnotifyonetimetask"></a>
- **种类：** `ReminderService` 的静态方法（`@visibleForTesting`）
- **来源：** `lib/shared/services/reminder_service.dart`（第 298 行）
- **用途：** 决定一次性任务的提醒在 `now` 是否到期，供桌面进程内循环。
- **输入：** `task`；`now`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 任何不合格条件返回 `false`（每日任务、无提醒时间/安排日期、已完成，或今天早于安排日期）；否则从今天日期加 `task.reminderTime` 的时/分构建 `dueAt` 并返回 `!now.isBefore(dueAt)`。
- **用法：**
  ```dart
  expect(
    ReminderService.shouldNotifyOneTimeTask(task, DateTime(2026, 6, 9, 9)),
    isFalse,
  );
  expect(
    ReminderService.shouldNotifyOneTimeTask(task, DateTime(2026, 6, 10, 9)),
    isTrue,
  );
  ```
  （`test/widget_test.dart:246-253`。从 `_check()` 的一次性任务循环调用：`if (!shouldNotifyOneTimeTask(task, current)) continue;`。）
- **备注：** "到期"意味着现在在或晚于今天提醒时间——逐日去重（使它只触发一次）是调用方经 `shouldFire` 的逐日键的工作，不是此函数。这正是让在精确分钟忙碌或挂起的进程稍后仍迟触发提醒而非跳过它的东西。

### `static bool _isActiveOneTimeTask(Task task, DateTime today)` <a id="_isactiveonetimetask"></a>
- **种类：** `ReminderService` 的静态方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 329 行）
- **用途：** 决定未完成一次性任务是否算进今天完成提醒的挂起。
- **输入：** `task`；`today`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 任务每日、已完成或无 `scheduledDate` 返回 `false`；否则返回 `!scheduledDate.isAfter(todayDate)`（仅日期比较）。
- **用法：** 只从 `_check()` 的完成提醒计数调用：`_oneTimeTasks.where((t) => _isActiveOneTimeTask(t, current)).length`（第 711 行）。
- **备注：** 未来安排的一次性任务被排除，使它们在安排日期到达前不膨胀今天"未完成"计数。

### `void _scheduleMobileSubscriptionReminder()` <a id="_schedulemobilesubscriptionreminder"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 354 行）
- **用途：** 启动（不 await）移动订阅续费单发的异步重建。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 移动端调用 `unawaited(_scheduleMobileSubscriptionReminderAsync())`；桌面端空操作。
- **算法：** `if (!MobileNotificationService.isMobile) return; unawaited(...)`。
- **用法：** 从 [`updateSubscriptionData`](#updatesubscriptiondata) 和 [`_processRenewals`](#_processrenewals)（空订阅提前返回和正常路径都）调用，使移动调度在每个订阅数据变更时刷新。
- **备注：** `unawaited` 即发即忘形态意味着调用方不阻塞操作系统调度调用；实际工作见 [`_scheduleMobileSubscriptionReminderAsync`](#_schedulemobilesubscriptionreminderasync)。

### `Future<void> _scheduleMobileSubscriptionReminderAsync()` <a id="_schedulemobilesubscriptionreminderasync"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 364 行）
- **用途：** 从当前订阅列表和提醒时间重建未来 7 天的逐日移动订阅续费单发通知。
- **输入：** 无（读取 `_subscriptionReminderTime`/`_subscriptions`）。
- **返回：** `Future<void>`。
- **副作用：** 取消遗留单重复 id（`_mobileSubReminderId`）和全部 7 个逐日 id，然后为未来 7 天内续费行列表非空的每个未来日调度新单发（`MobileNotificationService.scheduleAt`）。
- **算法：**
  1. 取消 `_mobileSubReminderId` 和 `i` 在 `0..<_mobileSubReminderDays`（7）内的所有 `_mobileSubReminderDayBaseId + i`。
  2. `_subscriptionReminderTime` 为 `null`（提醒禁用）时提前返回。
  3. 对 `0..<7` 中每个 `offset`，计算 `fireAt` = 今天+offset 在提醒时间；不晚于 `now` 则跳过；计算 `upcoming = _upcomingRenewalLines(fireAt)`；为空跳过；否则用 id `_mobileSubReminderDayBaseId + offset` 和体 `notifUpcomingRenewals(upcoming.join(', '))` 调度单发。
- **用法：** 只经 [`_scheduleMobileSubscriptionReminder`](#_schedulemobilesubscriptionreminder) 调用。
- **备注：** 跳过空天意味着过期续费文本绝不重复，只有实际有续费进入 3 天窗口的天获得通知——见 [平台说明 — 通知、提醒、托盘和启动](../../../platform-notes.md#notifications-reminders-tray-and-startup)。

### `void _scheduleMobileWeightReminders()` <a id="_schedulemobileweightreminders"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 401 行）
- **用途：** 从当前缓存时间调度（或取消）移动早间和晚间体重提醒。
- **输入：** 无（读取 `_weightMorningReminder`/`_weightEveningReminder`）。
- **返回：** 无。
- **副作用：** 对早间/晚间各：该提醒时间已设时调用 [`_scheduleMobileWeightReminder`](#_schedulemobileweightreminder)，否则 `MobileNotificationService.instance.cancel(id)`。
- **算法：** `if (!isMobile) return;` 然后对 `_mobileWeightMorningId`/`_mobileWeightEveningId` 两个独立 if/else 分支。
- **用法：** 从 [`updateWeightData`](#updateweightdata) 和 [`refreshMobileSchedules`](#refreshmobileschedules) 调用。
- **备注：** 无。

### `void _scheduleMobileWeightReminder(int id, TimeOfDay time)` <a id="_schedulemobileweightreminder"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 430 行）
- **用途：** 调度一个移动体重提醒，今天的候选触发时间已在宽限窗口内有记录时保持每日重复但把开始移到明天。
- **输入：** `id` — 操作系统通知 id（`_mobileWeightMorningId`/`_mobileWeightEveningId`）；`time` — 配置提醒时刻。
- **返回：** 无。
- **副作用：** 调用 `MobileNotificationService.scheduleDailyStarting`（宽限抑制 case）或 `scheduleDaily`（正常 case）。
- **算法：**
  1. 计算 `candidate` = 今天在 `time`；已早于 `now` 则推到明天。
  2. [`_shouldSkipWeightReminder(candidate)`](#_shouldskipweightreminder) 为 true 时调用 `scheduleDailyStarting`，`startDateTime: candidate.add(const Duration(days: 1))`——每日重复保留，只把首次触发再推一天。
  3. 否则调用 `scheduleDaily(time: time)`——从 `time` 下次出现开始的正常每日重复。
- **用法：** 只从 [`_scheduleMobileWeightReminders`](#_schedulemobileweightreminders) 调用，早间一次晚间一次。
- **备注：** 这是 [体重 — 提醒宽限窗口](../../../features/weight.md#reminder-grace-window) 描述宽限窗口锚定的移动侧：不同于桌面循环（锚定 `current`，实际触发时刻），移动锚定 `candidate`——预先构建的调度——因为预计算操作系统调度时应用无法获得"实际触发时刻"。直接对照此实现验证：桌面第 733/747 行调用传 `current`，此方法第 443 行调用传 `candidate`，精确匹配 `features/weight.md` 的描述。这里用单发替换每日调度（而非移每日开始）会在它触发一次后静默停止所有未来体重提醒——基于移动的方法正是避免那个的东西。

### `void _scheduleMobileTodoReminders()` <a id="_schedulemobiletodoreminders"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 466 行）
- **用途：** 调度（或取消）移动早间和完成 todo 提醒，然后重新调度逐任务提醒。
- **输入：** 无（读取 `_morningReminderTime`/`_completionReminderTime`）。
- **返回：** 无。
- **副作用：** 对 `_mobileMorningReminderId` 和 `_mobileCompletionReminderId` 做 `scheduleDaily`/`cancel`；调用 `_scheduleMobilePerTaskReminders()`。
- **算法：** `if (!isMobile) return;` 然后早间和完成提醒的独立 if/else 分支，然后委托 [`_scheduleMobilePerTaskReminders`](#_schedulemobilepertaskreminders)。
- **用法：** 从 [`updateData`](#updatedata) 和 [`refreshMobileSchedules`](#refreshmobileschedules) 调用。
- **备注：** 无。

### `void _scheduleMobilePerTaskReminders()` <a id="_schedulemobilepertaskreminders"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 500 行）
- **用途：** 启动（不 await）带代际号标记的新逐任务移动提醒重建，使过期在途重建能检测自己已被取代。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 递增 `_taskReminderScheduleGeneration`；调用 `unawaited(_scheduleMobilePerTaskRemindersAsync(generation))`。
- **算法：** `final generation = ++_taskReminderScheduleGeneration; unawaited(_scheduleMobilePerTaskRemindersAsync(generation));`
- **用法：** 只从 [`_scheduleMobileTodoReminders`](#_schedulemobiletodoreminders) 调用，即每次 Todo 数据变化。
- **备注：** 无代际跟踪时，快速连续两次 `updateData` 调用会交错并让第一次调用的过期逐任务调度生效。

### `Future<void> _scheduleMobilePerTaskRemindersAsync(int generation)` <a id="_schedulemobilepertaskremindersasync"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 510 行）
- **用途：** 取消所有先前调度逐任务操作系统通知并重新调度当前每日模板和一次性任务提醒，此后已开始更新的重建时提前退出。
- **输入：** `generation` — 调用方（[`_scheduleMobilePerTaskReminders`](#_schedulemobilepertaskreminders)）在启动时捕获的代际号。
- **返回：** `Future<void>`。
- **副作用：** 对完整逐任务 id 范围调用 `MobileNotificationService.cancelPendingInIdRange`、取消 `_scheduledTaskNotificationIds` 中每个先前跟踪 id，然后对每个任务调用 `scheduleDailyStarting`/`scheduleDaily`/`scheduleAt` 并重新填充 `_scheduledTaskNotificationIds`。
- **算法：**
  1. `cancelPendingInIdRange(minId: _mobileTaskReminderMinId, maxId: _mobileTaskReminderMaxId)`——连旧应用版本的过期 id 一起清除。
  2. `generation` 现已过期（新调用已开始）时返回。
  3. 取消 `_scheduledTaskNotificationIds` 中仍存的每个 id，然后清除该集合。
  4. 对每个每日模板（跳过无 `reminderTime` 或 `deletedDate` 非 null 的，每次迭代重新检查过期）：任务今天已完成且今天触发时间仍在将来时 `scheduleDailyStarting` 从明天开始；否则在其时间 `scheduleDaily`。跟踪 id。
  5. 对每个一次性任务（相同过期重查）：取 `firstOneTimeReminderDateTime`；为 `null` 跳过。[`shouldUseDailyMobileOneTimeReminder`](#shouldusedailymobileonetimereminder) 时取 `nextOneTimeReminderDateTime` 并 `scheduleDailyStarting` 从它开始；否则把首次提醒作为单发 `scheduleAt`。跟踪 id。
- **用法：** 只经 [`_scheduleMobilePerTaskReminders`](#_schedulemobilepertaskreminders) 调用。
- **备注：** 通篇重复的 `if (generation != _taskReminderScheduleGeneration) return;` 检查意味着被取代的重建尽快停止做操作系统调度调用，而非与新调用赛跑到完成。

### `Future<void> _check()` <a id="_check"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 603 行）
- **用途：** 30 秒计时器滴答：每个平台处理订阅续费和每日自动备份，然后——仅桌面——重新加载 Todo/体重数据并触发任何到期提醒通知，持久化今天已触发哪些提醒。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 无条件调用 `_processRenewals()` 和 `BackupService.runAutoBackupIfNeeded()`；桌面端重新加载 `TodoStorage`/体重数据、可能调用 `_notify(...)` 一次或多次、可能经 `_persistNotifiedKeys` 持久化 `_notifiedIds`。
- **算法：**
  1. `await _processRenewals();` 然后 `await BackupService.runAutoBackupIfNeeded();`——两者每个平台都运行。
  2. `MobileNotificationService.isMobile` 时立即返回——此方法其余部分仅桌面，因为移动端改经操作系统调度获得提醒。
  3. 尝试 `TodoStorage.load()`；异常或 `null` 结果时把 Todo 数据标记不可读并清除缓存模板/任务/日志/时间字段（Todo 跳过只读提醒遍，但其他提醒族仍运行）。
  4. 计算 `current = DateTime.now()` 和 `todayKey`（`yyyy-MM-dd`）；调用 `_loadNotifiedKeys(todayKey)`。
  5. 定义本地 `shouldFire(key, dueAt)` 闭包：`current.isBefore(dueAt)` 或键已在 `_notifiedIds` 时返回 `false`；否则添加键、标记 `notifiedChanged = true` 并返回 `true`。这是下面每个提醒族共享的逐键、逐日去重，使已触发提醒即使进程忙碌或重启也绝不在同一天触发两次，但迟到的滴答追上后仍触发一次。
  6. Todo 数据可读时：对每个每日模板（跳过无 `reminderTime`、已完成、软删除或今天已记录完成的），在今日提醒时间对 `'<taskId>_<todayKey}'` 调用 `shouldFire`，为 true 则 `_notify`。对每个一次性任务，用 [`shouldNotifyOneTimeTask`](#shouldnotifyonetimetask) 门控然后同样 `shouldFire`/`_notify`。然后早间提醒（`shouldFire('morning_$todayKey', ...)`）和完成提醒（`shouldFire('completion_$todayKey', ...)`，其体统计未完成每日模板加 [`_isActiveOneTimeTask`](#_isactiveonetimetask) 激活的一次性任务，且只在那个计数 `> 0` 时通知）。
  7. 惰性加载体重数据（本会话尚未加载时 `_refreshWeightDataFromStorage()`）。对配置的早间/晚间体重提醒各：`current` 在或晚于提醒时间且其键未触发时，再次刷新体重数据（捕获片刻前记录的记录），然后 `shouldFire` **和** [`!_shouldSkipWeightReminder(current)`](#_shouldskipweightreminder) 门控 `_notify`。
  8. 订阅提醒：`shouldFire('sub_reminder_$todayKey', ...)` 然后构建 `_upcomingRenewalLines(current)` 非空则 `_notify`。
  9. 任何键新标记触发时 `await _persistNotifiedKeys(todayKey)`。
- **用法：** 绝不被应用代码直接调用——每 30 秒被 [`start`](#start) 创建的 `Timer.periodic` 调用，并被 `start()` 自己同步调用一次。
- **备注：** 步骤 7 对 `current`（非配置提醒分钟）的重新检查正是 [体重 — 提醒宽限窗口](../../../features/weight.md#reminder-grace-window) 文档化宽限窗口锚定的桌面半边——调度分钟后但迟到滴答前记录的记录仍抑制那个滴答的提醒。此步骤依赖的订阅续费处理（`_processRenewals`）实现 [订阅计费](../../../algorithms/subscription-billing.md) 文档化的计费周期计算。

### `List<String> _upcomingRenewalLines(DateTime fromDay)` <a id="_upcomingrenewallines"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 776 行）
- **用途：** 为下次计费日期落在 `fromDay` 3 天内（含）的每个订阅构建本地化"续费到期"行，被桌面循环和逐日移动调度共享，使两者产生日期准确文本。
- **输入：** `fromDay` — 提醒触发的那天；只用其日期分量。
- **返回：** 本地化行的 `List<String>`（如 "X renews today" / "X renews in N days"），每个匹配订阅一行，可能为空。
- **副作用：** 无。
- **算法：**
  1. `fromDate` = 仅日期 `fromDay`；`limit = fromDate + 3 days`。
  2. 对每个订阅：`cancelType == CancelType.atExpiry` 跳过；非激活且 `cancelType == CancelType.immediate` 跳过；`nextBillingDate` 为 `null` 跳过；其仅日期值早于 `fromDate` 或晚于 `limit` 跳过。
  3. 否则计算 `days = nextDay.difference(fromDate).inDays` 并添加 `days == 0` 时 `notifSubscriptionToday(name)`，否则 `notifSubscriptionDays(name, days)`。
- **用法：** 从 [`_check`](#_check)（订阅提醒，传 `current`）和 [`_scheduleMobileSubscriptionReminderAsync`](#_schedulemobilesubscriptionreminderasync)（传未来 7 天每天的 `fireAt`）调用。
- **备注：** 两个调用方用相同窗口/文本逻辑，因此桌面和移动订阅提醒措辞同日完全一致。

### `Future<void> _loadNotifiedKeys(String todayKey)` <a id="_loadnotifiedkeys"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 806 行）
- **用途：** 确保 `_notifiedIds` 反映今天已触发提醒键，修剪前一天过期键并至多每进程一次从存储配置加载持久化键。
- **输入：** `todayKey` — 当前日 `yyyy-MM-dd`。
- **返回：** `Future<void>`。
- **副作用：** 修改 `_notifiedIds`/`_notifiedKeysDate`/`_notifiedKeysLoaded`；首次调用经 `TodoStorage.readConfig()` 读取 `storage_config.json`。
- **算法：**
  1. `_notifiedKeysDate != todayKey`（日已翻）时丢弃 `_notifiedIds` 中不以 `todayKey` 结尾的每个键，然后更新 `_notifiedKeysDate`。
  2. `_notifiedKeysLoaded` 已为 `true` 时立即返回（每进程只从磁盘加载一次）。
  3. 否则设它为 `true`，然后尝试读取 `config['reminderNotifiedKeys']`；其 `'date'` 匹配 `todayKey` 时把其 `'keys'` 列表加进 `_notifiedIds`。任何异常被吞掉。
- **用法：** 每次滴答从 [`_check`](#_check) 调用一次，在评估任何提醒前。
- **备注：** 每进程只加载一次（步骤 2）意味着启动后经其他方式加入存储的键不会在会话中拾取——这是刻意的，因为此进程是 `reminderNotifiedKeys` 的唯一写者。

### `Future<void> _persistNotifiedKeys(String todayKey)` <a id="_persistnotifiedkeys"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 830 行）
- **用途：** 把今天已触发提醒键持久化进 `storage_config.json`，使桌面重启不重新触发已触发提醒。
- **输入：** `todayKey` — 当前日 `yyyy-MM-dd`。
- **返回：** `Future<void>`。
- **副作用：** 经 `TodoStorage.readConfig()`/`writeConfig()` 写 `storage_config.json`。
- **算法：** 读取配置、设 `config['reminderNotifiedKeys'] = {'date': todayKey, 'keys': _notifiedIds.where((k) => k.endsWith(todayKey)).toList()}`、写回。任何异常被吞掉。
- **用法：** 只在那个滴答 `notifiedChanged` 为 true（至少一个新触发提醒）时从 [`_check`](#_check) 调用。
- **备注：** 写前过滤到以 `todayKey` 结尾的键避免持久化前一天的过期键，即使 `_notifiedIds` 短暂含一个。

### `DateTime _todayAt(TimeOfDay time)` <a id="_todayat"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 846 行）
- **用途：** 把今天日历日期与给定时刻组合成具体 `DateTime`。
- **输入：** `time`。
- **返回：** 今天在 `time.hour`:`time.minute` 的 `DateTime`。
- **副作用：** 无（只为今天日期读 `DateTime.now()`）。
- **算法：** `final today = DateTime.now(); return DateTime(today.year, today.month, today.day, time.hour, time.minute);`
- **用法：** [`_check`](#_check) 通篇调用把早间/完成/体重/订阅提醒时间锚定到今天，如 `_todayAt(_morningReminderTime!)`（第 693 行）。
- **备注：** 无。

### `bool _shouldSkipWeightReminder(DateTime firesAt)` <a id="_shouldskipweightreminder"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 862 行）
- **用途：** 实例级包装，用当前缓存体重记录和宽限分钟设置把宽限窗口抑制检查锚定在调用方提供触发时刻。
- **输入：** `firesAt` — 实际触发时刻（桌面循环的 `current`，或移动预调度的计划 `candidate` 时间）。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 用 `firesAt`、`records: _weightRecords`、`graceMinutes: _weightReminderGraceMinutes` 转发给 [`shouldSkipWeightReminderAt`](#shouldskipweightreminderat)。
- **用法：** 从 [`_check`](#_check) 以 `_shouldSkipWeightReminder(current)`（第 733、747 行）和从 [`_scheduleMobileWeightReminder`](#_schedulemobileweightreminder) 以 `_shouldSkipWeightReminder(candidate)`（第 443 行）调用。
- **备注：** 这是生产入口点；测试改经 [`shouldSkipWeightReminderAt`](#shouldskipweightreminderat) 直接练纯逻辑，因为那不需要实例。

### `static bool shouldSkipWeightReminderAt({required DateTime firesAt, required List<WeightRecord> records, required int graceMinutes})` <a id="shouldskipweightreminderat"></a>
- **种类：** `ReminderService` 的静态方法（`@visibleForTesting`）
- **来源：** `lib/shared/services/reminder_service.dart`（第 877 行）
- **用途：** 记录已存在于 `[firesAt − graceMinutes, firesAt + 1 minute)` 内时是否应抑制体重提醒的纯决策。
- **输入：** `firesAt`；`records`；`graceMinutes`（`<= 0` 时完全禁用抑制）。
- **返回：** `bool` — 任何记录 `datetime` 落在半开窗口时 `true`。
- **副作用：** 无。
- **算法：** `graceMinutes <= 0` 时立即返回 `false`。否则计算 `windowStart = firesAt - graceMinutes` 和 `windowEnd = firesAt + 1 minute`；任何记录 `datetime` 满足 `!isBefore(windowStart) && isBefore(windowEnd)` 时返回 `true`。
- **用法：**
  ```dart
  expect(
    ReminderService.shouldSkipWeightReminderAt(
      firesAt: firesAt,
      records: records,
      graceMinutes: 180,
    ),
    isTrue,
  );
  ```
  （`test/weight_reminder_grace_test.dart`，覆盖：窗口内 `firesAt` 前的记录、恰在 `firesAt` 的记录、刚出窗口的记录（不抑制）、`firesAt` *后*但仍在 `[firesAt, firesAt+1min)` 内的记录（抑制）、零/负宽限禁用抑制、无记录和未来 `candidate` 触发时间。）
- **备注：** 窗口刻意锚定 `firesAt` 而非配置提醒分钟——桌面和移动为何给 `firesAt` 传不同值见 [`_scheduleMobileWeightReminder`](#_schedulemobileweightreminder) 的备注和 [体重 — 提醒宽限窗口](../../../features/weight.md#reminder-grace-window)。`+ 1 minute` 上界（而非开放 `firesAt`）正是让提醒触发的同一分钟记录的记录仍算抑制它的东西。

### `Future<bool> _refreshWeightDataFromStorage()` <a id="_refreshweightdatafromstorage"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 896 行）
- **用途：** 从 `WeightStorage` 重新加载体重记录和提醒设置，报告是否加载了有效数据。
- **输入：** 无。
- **返回：** `Future<bool>` — 数据成功加载 `true`；读取异常或缺失/`null` 数据 `false`。
- **副作用：** 成功时覆盖 `_weightRecords`/`_weightReminderGraceMinutes`/`_weightMorningReminder`/`_weightEveningReminder` 并设 `_weightDataLoaded = true`。捕获异常时设 `_weightDataLoaded = false`（可重试）并在不碰其他字段下返回 `false`。`null` 数据时清除记录/提醒时间、设 `_weightDataLoaded = true` 并返回 `false`。
- **算法：**
  1. 尝试 `WeightStorage.load()`；异常时标记 `_weightDataLoaded = false` 并返回 `false`。
  2. 结果 `null`（尚无体重数据）时清除记录和提醒时间、标记已加载、返回 `false`。
  3. 否则把 `records`/`reminderGraceMinutes` 复制进缓存；构建 `_weightMorningReminder`（只在 `reminderMode != 'none'` 且时/分都设时非 null）和 `_weightEveningReminder`（只在 `reminderMode == 'twice'` 且时/分都设时非 null）；标记已加载；返回 `true`。
- **用法：** 从 [`_check`](#_check) 调用——`!_weightDataLoaded` 时惰性一次，又在每个体重提醒的 `shouldFire`/`_shouldSkipWeightReminder` 检查前一次，捕获同一滴答中片刻前记录的记录。
- **备注：** 不可读文件留下 `_weightDataLoaded == false`，因此下次滴答重试读取而非静默把不可读数据当作"未配置提醒"——匹配 [平台说明](../../../platform-notes.md) 描述的 `data_unreadable` 理念。

### `Future<void> _processRenewals()` <a id="_processrenewals"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 940 行）
- **用途：** 为过期计费日期生成订阅续费交易、从存储刷新缓存订阅列表/提醒时间并重新调度移动订阅提醒——全部至多每小时一次。
- **输入：** 无。
- **返回：** `Future<void>`。
- **副作用：** 读取 `FinanceStorage`；可能经 `FinanceStorage.save` 写回新交易；更新 `_subscriptions`/`_subscriptionReminderTime`；调用 `_scheduleMobileSubscriptionReminder()`；可能调用 `onRenewalsProcessed?.call()`。
- **算法：**
  1. `_lastRenewalCheck` 是 60 分钟前以内时立即返回；否则设 `_lastRenewalCheck = now`。
  2. 加载 `FinanceData`；`null` 返回。
  3. 从加载数据更新 `_subscriptionReminderTime`。
  4. 无订阅时清除 `_subscriptions`、重新调度移动提醒并返回。
  5. 调用 `SubscriptionProcessor.process(subscriptions, transactions)`（该算法见 [订阅计费](../../../algorithms/subscription-billing.md)）；把 `_subscriptions` 更新为结果；重新调度移动提醒。
  6. 无变化返回。否则写回带追加生成交易和更新订阅的新 `FinanceData`，逐字保留每个其他字段；然后调用 `onRenewalsProcessed?.call()` 使打开的财务页重载。
- **用法：** 每次滴答从 [`_check`](#_check) 调用一次——实际限制工作的是其内部小时门，不是调用方。
- **备注：** 因为这直接从 `FinanceStorage` 重新加载订阅，即使本会话从未打开财务页，续费处理和移动订阅提醒也继续工作——`updateSubscriptionData`（页面*打开*时调用）是更快路径补充，不是要求。

### `void _notify(String message)` <a id="_notify"></a>
- **种类：** `ReminderService` 的方法
- **来源：** `lib/shared/services/reminder_service.dart`（第 1001 行）
- **用途：** 经平台适当后端触发一个提醒通知，加已注册时的应用内 snackbar。
- **输入：** `message` — 通知体文本（已被调用方本地化/格式化）。
- **返回：** 无。
- **副作用：** 移动端调用 `MobileNotificationService.instance.showNow(id: _notifyCounter++, ...)`；桌面端构造并显示 `local_notifier` `LocalNotification`；注册回调时总是调用 `onShowSnackbar?.call(message)`。
- **算法：** `if (Platform.isAndroid || Platform.isIOS) { showNow(...) } else { local_notifier show() }`，然后无条件 `onShowSnackbar?.call(message)`。
- **用法：** 从 [`_check`](#_check) 为每个提醒族（逐任务、早间、完成、体重早间/晚间、订阅）调用。
- **备注：** `_notifyCounter` 在完整进程生命周期单调增长，使移动即时通知彼此绝不碰撞，但此路径实践中只在桌面可达，因为 `_check` 在移动端到达任何 `_notify` 调用前提前返回——`_notify` 内部移动分支实际从 `_check` 不可达，只在移动构建上从别处调用 `_notify` 时才有意义。

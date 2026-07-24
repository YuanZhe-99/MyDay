# lib/shared/services/reminder_service.dart

`ReminderService` is the global singleton reminder engine, started once from `main()` (see
[Architecture](../../../architecture.md) startup sequence) and kept alive independent of which tab
or page is currently open. Its 30-second `Timer.periodic` loop (`_check`) drives three things on
**every** platform — hourly subscription-renewal transaction generation, the daily auto-backup via
`BackupService.runAutoBackupIfNeeded()`, and refreshing cached reminder data — but only fires
user-facing reminder *notifications* itself on **desktop**, because mobile instead gets per-task/
per-day OS-level scheduled notifications through `MobileNotificationService`
(`mobile_notification_service.md`) so the user is never notified twice. See
[Platform Notes](../../../platform-notes.md#notifications-reminders-tray-and-startup) for the
desktop/mobile split, and [Weight](../../../features/weight.md#reminder-grace-window) for the
grace-window algorithm this file implements for weight reminders. Feature pages
(`todo_page.dart`, `weight_page.dart`, `finance_page.dart`) push their cached data into this
service via `updateData`/`updateWeightData`/`updateSubscriptionData` whenever it changes, and
`app_settings.dart`/`shell_scaffold.dart` wire locale updates and the in-app snackbar callback.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ReminderService._()` | constructor (`ReminderService`) | B | Prevent direct instantiation of the reminder singleton. |
| `_l10n` | getter (`ReminderService`) | B | Resolve localized strings for the current locale. |
| `updateLocale` | method (`ReminderService`) | B | Update the cached locale used for notification text. |
| [`start`](#start) | method (`ReminderService`) | A | Start the 30-second periodic reminder loop. |
| [`stop`](#stop) | method (`ReminderService`) | A | Stop the periodic reminder loop. |
| [`refreshMobileSchedules`](#refreshmobileschedules) | method (`ReminderService`) | A | Re-schedule all OS-level mobile reminder notifications. |
| [`updateData`](#updatedata) | method (`ReminderService`) | A | Push fresh Todo data/settings into the cache and reschedule mobile todo reminders. |
| [`updateSubscriptionData`](#updatesubscriptiondata) | method (`ReminderService`) | A | Push fresh subscription data/settings into the cache and reschedule the mobile renewal reminder. |
| [`updateWeightData`](#updateweightdata) | method (`ReminderService`) | A | Push fresh weight data/settings into the cache and reschedule mobile weight reminders. |
| [`_stableHash`](#_stablehash) | method (static, `ReminderService`) | A | Compute a stable FNV-1a hash of a string. |
| [`_taskNotificationId`](#_tasknotificationid) | method (static, `ReminderService`) | A | Derive a stable OS notification id from a task's string id. |
| [`firstOneTimeReminderDateTime`](#firstonetimereminderdatetime) | method (static, `ReminderService`) | A | Return a one-time task's first reminder date/time. |
| [`nextOneTimeReminderDateTime`](#nextonetimereminderdatetime) | method (static, `ReminderService`) | A | Return a one-time task's next reminder date/time from a reference point. |
| [`shouldUseDailyMobileOneTimeReminder`](#shouldusedailymobileonetimereminder) | method (static, `ReminderService`) | A | Decide whether mobile can use a daily repeating schedule for a one-time task. |
| [`shouldNotifyOneTimeTask`](#shouldnotifyonetimetask) | method (static, `ReminderService`) | A | Decide whether a one-time task's reminder is due at a given moment (desktop loop). |
| [`_isActiveOneTimeTask`](#_isactiveonetimetask) | method (static, `ReminderService`) | A | Decide whether an unfinished one-time task counts as pending today. |
| [`_scheduleMobileSubscriptionReminder`](#_schedulemobilesubscriptionreminder) | method (`ReminderService`) | A | Kick off (fire-and-forget) the mobile subscription reminder rebuild. |
| [`_scheduleMobileSubscriptionReminderAsync`](#_schedulemobilesubscriptionreminderasync) | method (`ReminderService`) | A | Rebuild the per-day mobile subscription renewal one-shots. |
| [`_scheduleMobileWeightReminders`](#_schedulemobileweightreminders) | method (`ReminderService`) | A | Schedule or cancel the mobile morning/evening weight reminders. |
| [`_scheduleMobileWeightReminder`](#_schedulemobileweightreminder) | method (`ReminderService`) | A | Schedule one mobile weight reminder, honoring the grace window. |
| [`_scheduleMobileTodoReminders`](#_schedulemobiletodoreminders) | method (`ReminderService`) | A | Schedule or cancel the mobile morning/completion todo reminders and per-task reminders. |
| [`_scheduleMobilePerTaskReminders`](#_schedulemobilepertaskreminders) | method (`ReminderService`) | A | Kick off (fire-and-forget) the per-task mobile reminder rebuild with generation tracking. |
| [`_scheduleMobilePerTaskRemindersAsync`](#_schedulemobilepertaskremindersasync) | method (`ReminderService`) | A | Cancel stale per-task schedules and reschedule current daily/one-time task reminders. |
| [`_check`](#_check) | method (`ReminderService`) | A | The 30-second tick: renewals, auto-backup, and (desktop-only) reminder firing. |
| [`_upcomingRenewalLines`](#_upcomingrenewallines) | method (`ReminderService`) | A | Build localized renewal lines for subscriptions due within 3 days of a day. |
| [`_loadNotifiedKeys`](#_loadnotifiedkeys) | method (`ReminderService`) | A | Load today's already-fired reminder keys from storage config. |
| [`_persistNotifiedKeys`](#_persistnotifiedkeys) | method (`ReminderService`) | A | Persist today's fired reminder keys into storage config. |
| [`_todayAt`](#_todayat) | method (`ReminderService`) | A | Combine today's date with a `TimeOfDay` into a `DateTime`. |
| [`_shouldSkipWeightReminder`](#_shouldskipweightreminder) | method (`ReminderService`) | A | Instance wrapper anchoring the grace-window check on a given fire moment. |
| [`shouldSkipWeightReminderAt`](#shouldskipweightreminderat) | method (static, `ReminderService`) | A | Pure grace-window decision for weight reminder suppression. |
| [`_refreshWeightDataFromStorage`](#_refreshweightdatafromstorage) | method (`ReminderService`) | A | Reload weight records and reminder settings from `WeightStorage`. |
| [`_processRenewals`](#_processrenewals) | method (`ReminderService`) | A | Generate overdue subscription-renewal transactions, at most once per hour. |
| [`_notify`](#_notify) | method (`ReminderService`) | A | Fire a single reminder notification (desktop `local_notifier` / mobile immediate) plus in-app snackbar. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/services/reminder_service.dart` returns 33,
matching the 33 rows above exactly — every block documents a real declaration (the constructor, the
`_l10n` getter, or a method) sitting immediately below it. No misattached blocks (a `Purpose:` block
documenting a call-site statement instead of the real declaration) and no undocumented real
declarations were found in this file. Only the private constructor, the trivial `_l10n` getter, and
`updateLocale` (a single field assignment with no branching or side effect beyond that) are
classified Tier B; every other method carries real branching, a loop, or a side-effecting call
(storage IO, OS notification scheduling, or triggering another such call), consistent with the
blanket "services" Tier A rule. The nested local function `shouldFire` declared inside `_check`'s
body is not listed as its own declaration — it has no doc comment and is purely part of `_check`'s
implementation, described under that method's Algorithm below. Fields (`_timer`, `_notifiedIds`,
cached data fields, the notification-id constants, `onShowSnackbar`, `onRenewalsProcessed`, etc.)
carry only plain `///` comments, not `Purpose:` blocks, and are not listed as separate declarations,
consistent with how sibling pages in this directory (e.g. `backup_service.md`) treat plain-commented
fields as data rather than functions.

## Documentation

### `void start()` <a id="start"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 83)
- **Purpose:** Start (or restart) the 30-second periodic reminder loop and run one check
  immediately.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Cancels any existing `_timer`, creates a new `Timer.periodic(30s, _check)`, and
  invokes `_check()` once synchronously (fire-and-forget, since `_check` is `async`).
- **Algorithm:** `_timer?.cancel(); _timer = Timer.periodic(const Duration(seconds: 30), (_) =>
  _check()); _check();` — no branching.
- **Usage:**
  ```dart
  // Start global reminder timer — runs regardless of which tab is active
  ReminderService.instance.start();
  ```
  (`lib/main.dart:51`, once at app startup, alongside `AutoSyncService.instance.start()`.)
- **Notes:** Calling `start()` again (it isn't, currently) would safely replace the existing timer
  rather than stacking a second one, because of the `_timer?.cancel()` guard.

### `void stop()` <a id="stop"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 94)
- **Purpose:** Stop the periodic reminder loop.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Cancels `_timer` and sets it to `null`.
- **Algorithm:** `_timer?.cancel(); _timer = null;`
- **Usage:** Not currently called anywhere in `lib/` — the service runs for the whole process
  lifetime once `start()` is called from `main()`; provided as the lifecycle counterpart to
  `start()`.
- **Notes:** Safe to call even if never started (`_timer` is nullable and `?.cancel()` no-ops).

### `void refreshMobileSchedules()` <a id="refreshmobileschedules"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 105)
- **Purpose:** Re-schedule all OS-level mobile reminder notifications (todo, subscription, weight)
  from the currently cached data.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** On mobile, calls `_scheduleMobileTodoReminders()`,
  `_scheduleMobileSubscriptionReminder()`, and `_scheduleMobileWeightReminders()` in sequence; a
  no-op on desktop.
- **Algorithm:** `if (!MobileNotificationService.isMobile) return;` then call the three
  `_scheduleMobile*` methods.
- **Usage:**
  ```dart
  if (state == AppLifecycleState.resumed) {
    _trySync();
    ReminderService.instance.refreshMobileSchedules();
  }
  ```
  (`lib/shared/services/auto_sync_service.dart:221-225`, `didChangeAppLifecycleState`, so per-day
  schedules are recomputed from current data after the device was suspended. Also called from
  `lib/shared/views/backup_page.dart:218` after a restore, since restored data can change reminder
  settings.)
- **Notes:** This is the only place all three mobile schedule families are refreshed together;
  individual `update*Data` calls only refresh their own family.

### `void updateData({required List<Task> dailyTemplates, required List<Task> oneTimeTasks, required DailyCompletionLog dailyLog, TimeOfDay? morningReminderTime, TimeOfDay? completionReminderTime})` <a id="updatedata"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 118)
- **Purpose:** Cache the current Todo data (daily templates, one-time tasks, completion log) and
  reminder time settings, then reschedule mobile todo reminders from them.
- **Inputs:** `dailyTemplates`, `oneTimeTasks`, `dailyLog`, `morningReminderTime`,
  `completionReminderTime` (the last two optional — `null` disables that reminder).
- **Returns:** None.
- **Side effects:** Overwrites `_dailyTemplates`/`_oneTimeTasks`/`_dailyLog`/
  `_morningReminderTime`/`_completionReminderTime`; calls `_scheduleMobileTodoReminders()`.
- **Algorithm:** Straight-line field assignment, then delegate to
  [`_scheduleMobileTodoReminders`](#_schedulemobiletodoreminders).
- **Usage:**
  ```dart
  ReminderService.instance.updateData(
    dailyTemplates: const [],
    oneTimeTasks: const [],
    dailyLog: DailyCompletionLog(),
  );
  ```
  (`lib/features/todo/views/todo_page.dart:98-102`, on a load failure, clearing cached reminder data
  so a corrupt Todo file doesn't keep firing stale reminders; also called at
  `todo_page.dart:190` on every successful load.)
- **Notes:** This is the desktop loop's *only* source of Todo data outside of `_check()`'s own
  `TodoStorage.load()` fallback — the two stay independent so the reminder loop keeps working even
  if the Todo page was never opened this session.

### `void updateSubscriptionData({required List<Subscription> subscriptions, int? reminderHour, int? reminderMinute})` <a id="updatesubscriptiondata"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 139)
- **Purpose:** Cache the current subscription list and renewal-reminder time, then reschedule the
  mobile subscription reminder.
- **Inputs:** `subscriptions`; `reminderHour`/`reminderMinute` (both required together to produce a
  non-null `TimeOfDay`, otherwise the reminder is disabled).
- **Returns:** None.
- **Side effects:** Overwrites `_subscriptions`/`_subscriptionReminderTime`; calls
  `_scheduleMobileSubscriptionReminder()`.
- **Algorithm:** `_subscriptions = subscriptions; _subscriptionReminderTime = (reminderHour != null
  && reminderMinute != null) ? TimeOfDay(...) : null;` then delegate to
  [`_scheduleMobileSubscriptionReminder`](#_schedulemobilesubscriptionreminder).
- **Usage:**
  ```dart
  void _updateReminderService() {
    ReminderService.instance.updateSubscriptionData(
      subscriptions: _subscriptions,
      reminderHour: _subscriptionReminderHour,
      reminderMinute: _subscriptionReminderMinute,
    );
  }
  ```
  (`lib/features/finance/views/finance_page.dart:227-233`, called whenever subscriptions or the
  reminder time change while the Finance page is open.)
- **Notes:** `_processRenewals()` also refreshes `_subscriptions`/`_subscriptionReminderTime`
  independently from storage, so subscription reminders work even when the Finance page was never
  opened this session — this method just keeps the loop in sync immediately when it is open.

### `void updateWeightData({List<WeightRecord>? records, int? morningHour, int? morningMinute, int? eveningHour, int? eveningMinute, int? reminderGraceMinutes})` <a id="updateweightdata"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 157)
- **Purpose:** Cache the current weight records and reminder settings, then reschedule mobile
  weight reminders.
- **Inputs:** `records` (only overwrites the cache when non-null, and marks it loaded); the four
  hour/minute pairs (each pair required together to enable that reminder); `reminderGraceMinutes`
  (falls back to the previous value when omitted).
- **Returns:** None.
- **Side effects:** Conditionally overwrites `_weightRecords`/`_weightDataLoaded`; overwrites
  `_weightMorningReminder`/`_weightEveningReminder`/`_weightReminderGraceMinutes`; calls
  `_scheduleMobileWeightReminders()`.
- **Algorithm:**
  1. If `records != null`, set `_weightRecords = records` and `_weightDataLoaded = true`.
  2. Build `_weightMorningReminder`/`_weightEveningReminder` via ternaries — `null` unless both
     hour and minute are non-null for that reminder.
  3. `_weightReminderGraceMinutes = reminderGraceMinutes ?? _weightReminderGraceMinutes`.
  4. Delegate to [`_scheduleMobileWeightReminders`](#_schedulemobileweightreminders).
- **Usage:**
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
  (`lib/features/weight/views/weight_page.dart:133-140`, after every load; also called at
  `weight_page.dart:106` with `records: const []` on a load failure.)
- **Notes:** The `records`-nullable design lets settings-only updates (e.g. changing the grace
  minutes from a settings dialog) push new reminder times without needing to also re-supply the
  full record list.

### `static int _stableHash(String value)` <a id="_stablehash"></a>
- **Kind:** static method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 204)
- **Purpose:** Compute a stable 31-bit FNV-1a-style hash of a string, since Dart's built-in
  `String.hashCode` is not guaranteed stable across app launches.
- **Inputs:** `value` — the string to hash (a task id).
- **Returns:** `int`, masked to `& 0x7fffffff` (non-negative, 31-bit).
- **Side effects:** None.
- **Algorithm:** Standard FNV-1a: start `hash = 0x811c9dc5`; for each UTF-16 code unit, XOR it into
  `hash`, then multiply by the FNV prime `0x01000193`, masking to 31 bits each iteration.
- **Usage:** Called only from [`_taskNotificationId`](#_tasknotificationid):
  `_stableHash(taskId) % _mobileTaskReminderIdRange`.
- **Notes:** Stability across launches (unlike `Object.hashCode`) is what lets
  `_scheduleMobilePerTaskRemindersAsync` cancel a task's previous OS notification by recomputing the
  same id later, without persisting an id-to-task mapping anywhere.

### `static int _taskNotificationId(String taskId)` <a id="_tasknotificationid"></a>
- **Kind:** static method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 219)
- **Purpose:** Derive a stable OS notification id for a task, confined to the per-task id range.
- **Inputs:** `taskId`.
- **Returns:** `int` in `[_mobileTaskReminderMinId, _mobileTaskReminderMaxId]` (`[10000, 109999]`).
- **Side effects:** None.
- **Algorithm:** `_mobileTaskReminderMinId + _stableHash(taskId) % _mobileTaskReminderIdRange`.
- **Usage:** Called from `_scheduleMobilePerTaskRemindersAsync` for every daily template and
  one-time task: `final nid = _taskNotificationId(task.id);` (line 530 / line 566).
- **Notes:** A hash collision between two task ids would make one task silently overwrite the
  other's scheduled notification (last-scheduled wins); the 100000-wide id range keeps this
  unlikely in practice but it is not collision-proof.

### `static DateTime? firstOneTimeReminderDateTime(Task task)` <a id="firstonetimereminderdatetime"></a>
- **Kind:** static method of `ReminderService` (`@visibleForTesting`)
- **Source:** `lib/shared/services/reminder_service.dart` (line 229)
- **Purpose:** Return a one-time task's first (originally scheduled) reminder date/time.
- **Inputs:** `task`.
- **Returns:** The first reminder `DateTime`, or `null` if the task is daily, has no
  `reminderTime`/`scheduledDate`, or is already completed.
- **Side effects:** None.
- **Algorithm:** Return `null` on any disqualifying condition; otherwise combine
  `task.scheduledDate`'s year/month/day with `task.reminderTime`'s hour/minute into a new
  `DateTime`.
- **Usage:**
  ```dart
  expect(
    ReminderService.firstOneTimeReminderDateTime(task),
    DateTime(2026, 6, 10, 9),
  );
  ```
  (`test/widget_test.dart:273-275`. Also called internally from
  [`nextOneTimeReminderDateTime`](#nextonetimereminderdatetime),
  [`shouldUseDailyMobileOneTimeReminder`](#shouldusedailymobileonetimereminder), and
  `_scheduleMobilePerTaskRemindersAsync`.)
- **Notes:** Preserves the originally scheduled date, independent of any later daily-repeat
  calculation built on top of it.

### `static DateTime? nextOneTimeReminderDateTime(Task task, DateTime now)` <a id="nextonetimereminderdatetime"></a>
- **Kind:** static method of `ReminderService` (`@visibleForTesting`)
- **Source:** `lib/shared/services/reminder_service.dart` (line 254)
- **Purpose:** Return a one-time task's next reminder date/time from a reference point, once it has
  started repeating daily.
- **Inputs:** `task`; `now` — the reference point.
- **Returns:** The next reminder `DateTime`, or `null` if the task should not remind at all.
- **Side effects:** None.
- **Algorithm:**
  1. Get `start = firstOneTimeReminderDateTime(task)`; return `null` if that's `null`.
  2. If `start.isAfter(now)`, return `start` unchanged (still before its first fire).
  3. Otherwise build `todayReminder` from today's date plus `task.reminderTime`'s hour/minute; if
     that is after `now`, return it; otherwise return it plus one day.
- **Usage:**
  ```dart
  expect(
    ReminderService.nextOneTimeReminderDateTime(task, DateTime(2026, 6, 9, 12)),
    DateTime(2026, 6, 10, 9),
  );
  ```
  (`test/widget_test.dart:259-264`. Also called from `_scheduleMobilePerTaskRemindersAsync` when
  [`shouldUseDailyMobileOneTimeReminder`](#shouldusedailymobileonetimereminder) is true, to compute
  the daily schedule's start time.)
- **Notes:** Once past the first reminder, behaves like a daily repeat anchored on
  `task.reminderTime`'s time-of-day, regardless of how many days have elapsed.

### `static bool shouldUseDailyMobileOneTimeReminder(Task task, DateTime now)` <a id="shouldusedailymobileonetimereminder"></a>
- **Kind:** static method of `ReminderService` (`@visibleForTesting`)
- **Source:** `lib/shared/services/reminder_service.dart` (line 277)
- **Purpose:** Decide whether mobile can use a daily repeating OS schedule for a one-time task, as
  opposed to a one-shot.
- **Inputs:** `task`; `now`.
- **Returns:** `bool` — `true` once the task's scheduled date is today or earlier.
- **Side effects:** None.
- **Algorithm:** Get `firstReminder = firstOneTimeReminderDateTime(task)`; return `false` if `null`;
  otherwise return `!scheduledDate.isAfter(today)` (date-only comparison, time discarded).
- **Usage:**
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
  (`test/widget_test.dart:276-289`. Drives the one-shot-vs-daily branch inside
  `_scheduleMobilePerTaskRemindersAsync`.)
- **Notes:** A daily repeating OS schedule only matches time-of-day, not date — so a *future*
  scheduled one-time task must use a one-shot first (see `scheduleAt` in
  [mobile_notification_service.md](mobile_notification_service.md#scheduleat)), then switch to a
  daily schedule once its date arrives, per [Todo](../../../features/todo.md).

### `static bool shouldNotifyOneTimeTask(Task task, DateTime now)` <a id="shouldnotifyonetimetask"></a>
- **Kind:** static method of `ReminderService` (`@visibleForTesting`)
- **Source:** `lib/shared/services/reminder_service.dart` (line 298)
- **Purpose:** Decide whether a one-time task's reminder is due at `now`, for the desktop in-process
  loop.
- **Inputs:** `task`; `now`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** Return `false` on any disqualifying condition (daily task, no reminder time/
  scheduled date, already completed, or today is before the scheduled date); otherwise build
  `dueAt` from today's date plus `task.reminderTime`'s hour/minute and return `!now.isBefore(dueAt)`.
- **Usage:**
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
  (`test/widget_test.dart:246-253`. Called from `_check()`'s one-time-task loop:
  `if (!shouldNotifyOneTimeTask(task, current)) continue;`.)
- **Notes:** "Due" means now is at or after today's reminder time — per-day dedupe (so it fires only
  once) is the caller's job via `shouldFire`'s per-day key, not this function's. This is what lets a
  process that was busy or suspended through the exact minute still fire the reminder late instead
  of skipping it.

### `static bool _isActiveOneTimeTask(Task task, DateTime today)` <a id="_isactiveonetimetask"></a>
- **Kind:** static method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 329)
- **Purpose:** Decide whether an unfinished one-time task counts as pending for today's completion
  reminder.
- **Inputs:** `task`; `today`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** Return `false` if the task is daily, completed, or has no `scheduledDate`;
  otherwise return `!scheduledDate.isAfter(todayDate)` (date-only comparison).
- **Usage:** Called only from `_check()`'s completion-reminder count:
  `_oneTimeTasks.where((t) => _isActiveOneTimeTask(t, current)).length` (line 711).
- **Notes:** Future-scheduled one-time tasks are excluded so they don't inflate today's
  "uncompleted" count before their scheduled date arrives.

### `void _scheduleMobileSubscriptionReminder()` <a id="_schedulemobilesubscriptionreminder"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 354)
- **Purpose:** Kick off (without awaiting) the async rebuild of the mobile subscription renewal
  one-shots.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** On mobile, calls `unawaited(_scheduleMobileSubscriptionReminderAsync())`; a
  no-op on desktop.
- **Algorithm:** `if (!MobileNotificationService.isMobile) return; unawaited(...)`.
- **Usage:** Called from [`updateSubscriptionData`](#updatesubscriptiondata) and from
  [`_processRenewals`](#_processrenewals) (both the empty-subscriptions early return and the normal
  path) so mobile schedules refresh on every subscription-data change.
- **Notes:** The `unawaited` fire-and-forget shape means callers don't block on OS scheduling calls;
  see [`_scheduleMobileSubscriptionReminderAsync`](#_schedulemobilesubscriptionreminderasync) for the
  actual work.

### `Future<void> _scheduleMobileSubscriptionReminderAsync()` <a id="_schedulemobilesubscriptionreminderasync"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 364)
- **Purpose:** Rebuild the next 7 days of per-day mobile subscription renewal one-shot
  notifications from the current subscription list and reminder time.
- **Inputs:** None (reads `_subscriptionReminderTime`/`_subscriptions`).
- **Returns:** `Future<void>`.
- **Side effects:** Cancels the legacy single repeating id (`_mobileSubReminderId`) and all 7 per-day
  ids, then schedules a new one-shot (`MobileNotificationService.scheduleAt`) for each future day
  within the next 7 whose renewal-lines list is non-empty.
- **Algorithm:**
  1. Cancel `_mobileSubReminderId` and all `_mobileSubReminderDayBaseId + i` for `i` in
     `0..<_mobileSubReminderDays` (7).
  2. Return early if `_subscriptionReminderTime` is `null` (reminder disabled).
  3. For each `offset` in `0..<7`, compute `fireAt` = today+offset at the reminder time; skip if not
     after `now`; compute `upcoming = _upcomingRenewalLines(fireAt)`; skip if empty; otherwise
     `scheduleAt` a one-shot with id `_mobileSubReminderDayBaseId + offset` and body
     `notifUpcomingRenewals(upcoming.join(', '))`.
- **Usage:** Called only via [`_scheduleMobileSubscriptionReminder`](#_schedulemobilesubscriptionreminder).
- **Notes:** Skipping empty days means stale renewal text is never repeated and only days that
  actually have a renewal entering the 3-day window get a notification — see
  [Platform Notes](../../../platform-notes.md#notifications-reminders-tray-and-startup).

### `void _scheduleMobileWeightReminders()` <a id="_schedulemobileweightreminders"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 401)
- **Purpose:** Schedule (or cancel) the mobile morning and evening weight reminders from the
  currently cached times.
- **Inputs:** None (reads `_weightMorningReminder`/`_weightEveningReminder`).
- **Returns:** None.
- **Side effects:** For each of morning/evening: calls
  [`_scheduleMobileWeightReminder`](#_schedulemobileweightreminder) if that reminder time is set,
  else `MobileNotificationService.instance.cancel(id)`.
- **Algorithm:** `if (!isMobile) return;` then two independent if/else branches for
  `_mobileWeightMorningId`/`_mobileWeightEveningId`.
- **Usage:** Called from [`updateWeightData`](#updateweightdata) and from
  [`refreshMobileSchedules`](#refreshmobileschedules).
- **Notes:** None.

### `void _scheduleMobileWeightReminder(int id, TimeOfDay time)` <a id="_schedulemobileweightreminder"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 430)
- **Purpose:** Schedule one mobile weight reminder, keeping its daily repeat but shifting the start
  to tomorrow when a record already exists inside the grace window for today's candidate fire time.
- **Inputs:** `id` — the OS notification id (`_mobileWeightMorningId`/`_mobileWeightEveningId`);
  `time` — the configured reminder time of day.
- **Returns:** None.
- **Side effects:** Calls `MobileNotificationService.scheduleDailyStarting` (grace-suppressed case)
  or `scheduleDaily` (normal case).
- **Algorithm:**
  1. Compute `candidate` = today at `time`; if already before `now`, push to tomorrow.
  2. If [`_shouldSkipWeightReminder(candidate)`](#_shouldskipweightreminder) is true, call
     `scheduleDailyStarting` with `startDateTime: candidate.add(const Duration(days: 1))` — the
     daily repeat is kept, only its first fire is pushed one more day out.
  3. Otherwise call `scheduleDaily(time: time)` — a normal daily repeat starting at the next
     occurrence of `time`.
- **Usage:** Called only from [`_scheduleMobileWeightReminders`](#_schedulemobileweightreminders),
  once for morning and once for evening.
- **Notes:** This is the mobile side of the grace-window anchoring described in
  [Weight](../../../features/weight.md#reminder-grace-window): unlike the desktop loop (which
  anchors on `current`, the actual fire moment), mobile anchors on `candidate` — the schedule being
  built ahead of time — because there is no "actual moment it fires" available to the app when
  pre-computing an OS schedule. Verified directly against this implementation: the desktop calls at
  lines 733/747 pass `current`, this method's call at line 443 passes `candidate`, matching
  `features/weight.md`'s description exactly. Replacing the daily schedule with a one-shot here
  (instead of shifting the daily start) would silently stop all future weight reminders after it
  fired once — the shift-based approach is what avoids that.

### `void _scheduleMobileTodoReminders()` <a id="_schedulemobiletodoreminders"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 466)
- **Purpose:** Schedule (or cancel) the mobile morning and completion todo reminders, then
  reschedule per-task reminders.
- **Inputs:** None (reads `_morningReminderTime`/`_completionReminderTime`).
- **Returns:** None.
- **Side effects:** `scheduleDaily`/`cancel` for `_mobileMorningReminderId` and
  `_mobileCompletionReminderId`; calls `_scheduleMobilePerTaskReminders()`.
- **Algorithm:** `if (!isMobile) return;` then independent if/else branches for the morning and
  completion reminders, then delegate to
  [`_scheduleMobilePerTaskReminders`](#_schedulemobilepertaskreminders).
- **Usage:** Called from [`updateData`](#updatedata) and from
  [`refreshMobileSchedules`](#refreshmobileschedules).
- **Notes:** None.

### `void _scheduleMobilePerTaskReminders()` <a id="_schedulemobilepertaskreminders"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 500)
- **Purpose:** Kick off (without awaiting) a fresh per-task mobile reminder rebuild, tagged with a
  generation number so a stale in-flight rebuild can detect it's been superseded.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Increments `_taskReminderScheduleGeneration`; calls
  `unawaited(_scheduleMobilePerTaskRemindersAsync(generation))`.
- **Algorithm:** `final generation = ++_taskReminderScheduleGeneration;
  unawaited(_scheduleMobilePerTaskRemindersAsync(generation));`
- **Usage:** Called only from [`_scheduleMobileTodoReminders`](#_schedulemobiletodoreminders), i.e.
  every time Todo data changes.
- **Notes:** Without generation tracking, two overlapping calls to `updateData` in quick succession
  could interleave and leave stale per-task schedules from the first call in effect.

### `Future<void> _scheduleMobilePerTaskRemindersAsync(int generation)` <a id="_schedulemobilepertaskremindersasync"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 510)
- **Purpose:** Cancel all previously scheduled per-task OS notifications and reschedule current
  daily-template and one-time-task reminders, bailing out early if a newer rebuild has since
  started.
- **Inputs:** `generation` — the generation number captured by the caller
  ([`_scheduleMobilePerTaskReminders`](#_schedulemobilepertaskreminders)) at kickoff time.
- **Returns:** `Future<void>`.
- **Side effects:** Calls `MobileNotificationService.cancelPendingInIdRange` over the whole per-task
  id range, cancels every previously tracked id in `_scheduledTaskNotificationIds`, then calls
  `scheduleDailyStarting`/`scheduleDaily`/`scheduleAt` per task and repopulates
  `_scheduledTaskNotificationIds`.
- **Algorithm:**
  1. `cancelPendingInIdRange(minId: _mobileTaskReminderMinId, maxId: _mobileTaskReminderMaxId)` —
     clears stale ids even from older app versions.
  2. If `generation` is now stale (a newer call has started), return.
  3. Cancel every id still in `_scheduledTaskNotificationIds`, then clear that set.
  4. For each daily template (skipping those with no `reminderTime` or a non-null `deletedDate`,
     re-checking staleness each iteration): if the task is already completed today and today's fire
     time is still in the future, `scheduleDailyStarting` from tomorrow; otherwise `scheduleDaily` at
     its time. Track the id.
  5. For each one-time task (same staleness re-check): get `firstOneTimeReminderDateTime`; skip if
     `null`. If [`shouldUseDailyMobileOneTimeReminder`](#shouldusedailymobileonetimereminder), get
     `nextOneTimeReminderDateTime` and `scheduleDailyStarting` from it; otherwise `scheduleAt` the
     first reminder as a one-shot. Track the id.
- **Usage:** Called only via [`_scheduleMobilePerTaskReminders`](#_schedulemobilepertaskreminders).
- **Notes:** The repeated `if (generation != _taskReminderScheduleGeneration) return;` checks
  throughout mean a superseded rebuild stops doing OS scheduling calls as soon as possible rather
  than racing the newer one to completion.

### `Future<void> _check()` <a id="_check"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 603)
- **Purpose:** The 30-second timer tick: process subscription renewals and the daily auto-backup on
  every platform, then — desktop only — reload Todo/weight data and fire any due reminder
  notifications, persisting which reminders have already fired today.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Calls `_processRenewals()` and `BackupService.runAutoBackupIfNeeded()`
  unconditionally; on desktop, reloads `TodoStorage`/weight data, may call `_notify(...)` one or
  more times, and may persist `_notifiedIds` via `_persistNotifiedKeys`.
- **Algorithm:**
  1. `await _processRenewals();` then `await BackupService.runAutoBackupIfNeeded();` — both run on
     every platform.
  2. Return immediately if `MobileNotificationService.isMobile` — the rest of this method is
     desktop-only, since mobile gets reminders through OS schedules instead.
  3. Try `TodoStorage.load()`; on exception or `null` result, mark Todo data unreadable and clear
     the cached template/task/log/time fields (a read-only reminder pass is skipped for Todo, but
     other reminder families still run).
  4. Compute `current = DateTime.now()` and `todayKey` (`yyyy-MM-dd`); call
     `_loadNotifiedKeys(todayKey)`.
  5. Define a local `shouldFire(key, dueAt)` closure: returns `false` if `current.isBefore(dueAt)` or
     the key is already in `_notifiedIds`; otherwise adds the key, marks `notifiedChanged = true`,
     and returns `true`. This is the shared per-key, per-day dedupe used by every reminder family
     below, so a fired reminder never fires twice on the same day even if the process is busy or
     restarted, but a late-running tick still fires it once it catches up.
  6. If Todo data is readable: for each daily template (skipping ones with no `reminderTime`,
     already completed, soft-deleted, or already logged complete today), call `shouldFire` on
     `'<taskId>_<todayKey}'` at today's reminder time and `_notify` if true. For each one-time task,
     gate on [`shouldNotifyOneTimeTask`](#shouldnotifyonetimetask) then `shouldFire`/`_notify` the
     same way. Then the morning reminder (`shouldFire('morning_$todayKey', ...)`) and the
     completion reminder (`shouldFire('completion_$todayKey', ...)`, whose body counts uncompleted
     daily templates plus [`_isActiveOneTimeTask`](#_isactiveonetimetask)-active one-time tasks and
     only notifies if that count is `> 0`).
  7. Load weight data lazily (`_refreshWeightDataFromStorage()` only if not already loaded this
     session). For each of morning/evening weight reminders configured: if `current` is at or past
     the reminder time and its key hasn't fired, refresh weight data again (to catch a record logged
     moments ago), then `shouldFire` **and**
     [`!_shouldSkipWeightReminder(current)`](#_shouldskipweightreminder) gate `_notify`.
  8. Subscription reminder: `shouldFire('sub_reminder_$todayKey', ...)` then build
     `_upcomingRenewalLines(current)` and `_notify` if non-empty.
  9. If any key was newly marked fired, `await _persistNotifiedKeys(todayKey)`.
- **Usage:** Never called directly by application code — invoked every 30 seconds by the
  `Timer.periodic` created in [`start`](#start), and once synchronously by `start()` itself.
- **Notes:** Step 7's re-check of `current` (not the configured reminder minute) is exactly the
  desktop half of the grace-window anchoring documented in
  [Weight](../../../features/weight.md#reminder-grace-window) — a record logged after the scheduled
  minute but before a late-running tick still suppresses that tick's reminder. The subscription
  renewal processing this step depends on (`_processRenewals`) implements the billing-cycle
  calculations documented in
  [Subscription Billing](../../../algorithms/subscription-billing.md).

### `List<String> _upcomingRenewalLines(DateTime fromDay)` <a id="_upcomingrenewallines"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 776)
- **Purpose:** Build localized "renewal due" lines for every subscription whose next billing date
  falls within 3 days of `fromDay` (inclusive), shared by both the desktop loop and the per-day
  mobile schedules so both produce day-accurate text.
- **Inputs:** `fromDay` — the day the reminder fires; only its date components are used.
- **Returns:** `List<String>` of localized lines (e.g. "X renews today" / "X renews in N days"), one
  per matching subscription, possibly empty.
- **Side effects:** None.
- **Algorithm:**
  1. `fromDate` = date-only `fromDay`; `limit = fromDate + 3 days`.
  2. For each subscription: skip if `cancelType == CancelType.atExpiry`; skip if inactive and
     `cancelType == CancelType.immediate`; skip if `nextBillingDate` is `null`; skip if its date-only
     value is before `fromDate` or after `limit`.
  3. Otherwise compute `days = nextDay.difference(fromDate).inDays` and add
     `notifSubscriptionToday(name)` if `days == 0`, else `notifSubscriptionDays(name, days)`.
- **Usage:** Called from [`_check`](#_check) (subscription reminder, passing `current`) and from
  [`_scheduleMobileSubscriptionReminderAsync`](#_schedulemobilesubscriptionreminderasync) (passing
  each of the next 7 days' `fireAt`).
- **Notes:** Both callers use the same window/text logic, so desktop and mobile subscription
  reminder wording agree exactly for the same day.

### `Future<void> _loadNotifiedKeys(String todayKey)` <a id="_loadnotifiedkeys"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 806)
- **Purpose:** Ensure `_notifiedIds` reflects today's already-fired reminder keys, pruning stale
  keys from a previous day and loading persisted keys from storage config at most once per process.
- **Inputs:** `todayKey` — `yyyy-MM-dd` of the current day.
- **Returns:** `Future<void>`.
- **Side effects:** Mutates `_notifiedIds`/`_notifiedKeysDate`/`_notifiedKeysLoaded`; reads
  `storage_config.json` via `TodoStorage.readConfig()` on the first call.
- **Algorithm:**
  1. If `_notifiedKeysDate != todayKey` (day rolled over), drop every key in `_notifiedIds` not
     ending in `todayKey`, then update `_notifiedKeysDate`.
  2. Return immediately if `_notifiedKeysLoaded` is already `true` (only load from disk once per
     process).
  3. Otherwise set it `true`, then try reading `config['reminderNotifiedKeys']`; if its `'date'`
     matches `todayKey`, add its `'keys'` list into `_notifiedIds`. Any exception is swallowed.
- **Usage:** Called once per tick from [`_check`](#_check), before evaluating any reminder.
- **Notes:** Loading only once per process (step 2) means a key added to storage by some other means
  after startup would not be picked up mid-session — this is intentional, since this process is the
  sole writer of `reminderNotifiedKeys`.

### `Future<void> _persistNotifiedKeys(String todayKey)` <a id="_persistnotifiedkeys"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 830)
- **Purpose:** Persist today's fired reminder keys into `storage_config.json` so a desktop restart
  does not re-fire an already-fired reminder.
- **Inputs:** `todayKey` — `yyyy-MM-dd` of the current day.
- **Returns:** `Future<void>`.
- **Side effects:** Writes `storage_config.json` via `TodoStorage.readConfig()`/`writeConfig()`.
- **Algorithm:** Read the config, set `config['reminderNotifiedKeys'] = {'date': todayKey, 'keys':
  _notifiedIds.where((k) => k.endsWith(todayKey)).toList()}`, write it back. Any exception is
  swallowed.
- **Usage:** Called from [`_check`](#_check) only when `notifiedChanged` is true for that tick (at
  least one reminder newly fired).
- **Notes:** Filtering to keys ending in `todayKey` before writing avoids ever persisting a stale
  key from a previous day, even if `_notifiedIds` briefly contained one.

### `DateTime _todayAt(TimeOfDay time)` <a id="_todayat"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 846)
- **Purpose:** Combine today's calendar date with a given time-of-day into a concrete `DateTime`.
- **Inputs:** `time`.
- **Returns:** `DateTime` for today at `time.hour`:`time.minute`.
- **Side effects:** None (reads `DateTime.now()` for today's date only).
- **Algorithm:** `final today = DateTime.now(); return DateTime(today.year, today.month, today.day,
  time.hour, time.minute);`
- **Usage:** Called throughout [`_check`](#_check) to anchor the morning/completion/weight/
  subscription reminder times to today, e.g. `_todayAt(_morningReminderTime!)` (line 693).
- **Notes:** None.

### `bool _shouldSkipWeightReminder(DateTime firesAt)` <a id="_shouldskipweightreminder"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 862)
- **Purpose:** Instance-level wrapper that anchors the grace-window suppression check on a caller-
  supplied fire moment, using the currently cached weight records and grace-minutes setting.
- **Inputs:** `firesAt` — the actual fire moment (`current` from the desktop loop, or the scheduled
  `candidate` time from mobile pre-scheduling).
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** Forward to [`shouldSkipWeightReminderAt`](#shouldskipweightreminderat) with
  `firesAt`, `records: _weightRecords`, `graceMinutes: _weightReminderGraceMinutes`.
- **Usage:** Called from [`_check`](#_check) as `_shouldSkipWeightReminder(current)` (lines 733,
  747) and from [`_scheduleMobileWeightReminder`](#_scheduleMobileWeightReminder) as
  `_shouldSkipWeightReminder(candidate)` (line 443).
- **Notes:** This is the production entry point; tests exercise the pure logic directly through
  [`shouldSkipWeightReminderAt`](#shouldskipweightreminderat) instead, since that doesn't require an
  instance.

### `static bool shouldSkipWeightReminderAt({required DateTime firesAt, required List<WeightRecord> records, required int graceMinutes})` <a id="shouldskipweightreminderat"></a>
- **Kind:** static method of `ReminderService` (`@visibleForTesting`)
- **Source:** `lib/shared/services/reminder_service.dart` (line 877)
- **Purpose:** Pure decision of whether a weight reminder should be suppressed because a record
  already exists inside `[firesAt − graceMinutes, firesAt + 1 minute)`.
- **Inputs:** `firesAt`; `records`; `graceMinutes` (suppression is disabled entirely when `<= 0`).
- **Returns:** `bool` — `true` when any record's `datetime` falls in the half-open window.
- **Side effects:** None.
- **Algorithm:** Return `false` immediately if `graceMinutes <= 0`. Otherwise compute `windowStart =
  firesAt - graceMinutes` and `windowEnd = firesAt + 1 minute`; return `true` if any record's
  `datetime` satisfies `!isBefore(windowStart) && isBefore(windowEnd)`.
- **Usage:**
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
  (`test/weight_reminder_grace_test.dart`, covering: a record before `firesAt` inside the window, a
  record exactly at `firesAt`, a record just outside the window (no suppression), a record *after*
  `firesAt` but still inside `[firesAt, firesAt+1min)` (suppression), zero/negative grace disabling
  suppression, no records, and a future `candidate` fire time.)
- **Notes:** The window is intentionally anchored on `firesAt`, not the configured reminder minute
  — see [`_scheduleMobileWeightReminder`](#_schedulemobileweightreminder)'s Notes and
  [Weight](../../../features/weight.md#reminder-grace-window) for why desktop and mobile pass
  different values for `firesAt`. The `+ 1 minute` upper bound (rather than an open `firesAt`) is
  what lets a record logged in the same minute the reminder fires still count as suppressing it.

### `Future<bool> _refreshWeightDataFromStorage()` <a id="_refreshweightdatafromstorage"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 896)
- **Purpose:** Reload weight records and reminder settings from `WeightStorage`, reporting whether
  valid data was loaded.
- **Inputs:** None.
- **Returns:** `Future<bool>` — `true` if data loaded successfully; `false` on read exception or
  missing/`null` data.
- **Side effects:** On success, overwrites `_weightRecords`/`_weightReminderGraceMinutes`/
  `_weightMorningReminder`/`_weightEveningReminder` and sets `_weightDataLoaded = true`. On a
  caught exception, sets `_weightDataLoaded = false` (retryable) and returns `false` without
  touching the other fields. On `null` data, clears records/reminder times, sets
  `_weightDataLoaded = true`, and returns `false`.
- **Algorithm:**
  1. Try `WeightStorage.load()`; on exception, mark `_weightDataLoaded = false` and return `false`.
  2. If the result is `null` (no weight data yet), clear records and reminder times, mark loaded,
     return `false`.
  3. Otherwise copy `records`/`reminderGraceMinutes` into the cache; build
     `_weightMorningReminder` (non-null only if `reminderMode != 'none'` and both hour/minute are
     set) and `_weightEveningReminder` (non-null only if `reminderMode == 'twice'` and both hour/
     minute are set); mark loaded; return `true`.
- **Usage:** Called from [`_check`](#_check) — once lazily if `!_weightDataLoaded`, and again just
  before each weight reminder's `shouldFire`/`_shouldSkipWeightReminder` check to catch a record
  logged moments earlier in the same tick.
- **Notes:** An unreadable file leaves `_weightDataLoaded == false`, so the next tick retries the
  read rather than silently treating unreadable data as "no reminders configured" — matching the
  `data_unreadable` philosophy described in [Platform Notes](../../../platform-notes.md).

### `Future<void> _processRenewals()` <a id="_processrenewals"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 940)
- **Purpose:** Generate subscription-renewal transactions for overdue billing dates, refresh the
  cached subscription list/reminder time from storage, and reschedule the mobile subscription
  reminder — all at most once per hour.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads `FinanceStorage`; may write new transactions back via
  `FinanceStorage.save`; updates `_subscriptions`/`_subscriptionReminderTime`; calls
  `_scheduleMobileSubscriptionReminder()`; may call `onRenewalsProcessed?.call()`.
- **Algorithm:**
  1. Return immediately if `_lastRenewalCheck` was less than 60 minutes ago; otherwise set
     `_lastRenewalCheck = now`.
  2. Load `FinanceData`; return if `null`.
  3. Update `_subscriptionReminderTime` from the loaded data.
  4. If there are no subscriptions, clear `_subscriptions`, reschedule the mobile reminder, and
     return.
  5. Call `SubscriptionProcessor.process(subscriptions, transactions)` (see
     [Subscription Billing](../../../algorithms/subscription-billing.md) for that algorithm); update
     `_subscriptions` to the result; reschedule the mobile reminder.
  6. If nothing changed, return. Otherwise write back a new `FinanceData` with the generated
     transactions appended and the updated subscriptions, preserving every other field unchanged;
     then call `onRenewalsProcessed?.call()` so an open Finance page reloads.
- **Usage:** Called once per tick from [`_check`](#_check) — its internal hourly gate is what
  actually limits the work, not the caller.
- **Notes:** Because this reloads subscriptions from `FinanceStorage` directly, renewal processing
  and mobile subscription reminders keep working even if the Finance page was never opened during
  this session — `updateSubscriptionData` (called when the page *is* open) is a faster-path
  supplement, not a requirement.

### `void _notify(String message)` <a id="_notify"></a>
- **Kind:** method of `ReminderService`
- **Source:** `lib/shared/services/reminder_service.dart` (line 1001)
- **Purpose:** Fire one reminder notification through the platform-appropriate backend, plus an
  in-app snackbar if one is registered.
- **Inputs:** `message` — the notification body text (already localized/formatted by the caller).
- **Returns:** None.
- **Side effects:** On mobile, calls `MobileNotificationService.instance.showNow(id:
  _notifyCounter++, ...)`; on desktop, constructs and shows a `local_notifier` `LocalNotification`;
  always calls `onShowSnackbar?.call(message)` if a callback is registered.
- **Algorithm:** `if (Platform.isAndroid || Platform.isIOS) { showNow(...) } else { local_notifier
  show() }`, then `onShowSnackbar?.call(message)` unconditionally.
- **Usage:** Called from [`_check`](#_check) for every reminder family (per-task, morning,
  completion, weight morning/evening, subscription).
- **Notes:** `_notifyCounter` grows monotonically for the whole process lifetime, so mobile
  immediate notifications never collide with each other, but this path is only reachable on
  desktop in practice since `_check` returns early on mobile before reaching any `_notify` call —
  the mobile branch inside `_notify` itself is effectively unreachable from `_check` and would only
  matter if `_notify` were called from elsewhere on a mobile build.

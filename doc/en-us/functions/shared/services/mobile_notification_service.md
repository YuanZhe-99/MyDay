# lib/shared/services/mobile_notification_service.dart

`MobileNotificationService` wraps `flutter_local_notifications` to schedule OS-level notifications
on Android/iOS, which is how MyDay delivers reminders on mobile even when the app process is
killed (as opposed to desktop, where `ReminderService`'s 30-second loop fires reminders itself
while the process is alive). It resolves the device's real IANA timezone (via `flutter_timezone`)
so schedules survive DST correctly, then exposes one-shot, daily-repeating, and range-cancel
scheduling primitives that `ReminderService` composes into the actual per-task/per-day reminder
logic. See [Platform Notes](../../../platform-notes.md) for the desktop/mobile notification split,
the `inexactAllowWhileIdle` scheduling mode, and why `SCHEDULE_EXACT_ALARM` is intentionally not
requested.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `MobileNotificationService._` | constructor (`MobileNotificationService`) | B | Private constructor backing the singleton. |
| [`isMobile`](#ismobile) | getter (static) | B | Whether the current platform is Android or iOS. |
| [`init`](#init) | method (`MobileNotificationService`) | A | Initialize the plugin, timezone, and Android 13+ permission. |
| [`showNow`](#shownow) | method (`MobileNotificationService`) | A | Show an immediate notification. |
| [`scheduleDaily`](#scheduledaily) | method (`MobileNotificationService`) | A | Schedule a daily-repeating notification starting today/tomorrow. |
| [`scheduleDailyStarting`](#scheduledailystarting) | method (`MobileNotificationService`) | A | Schedule a daily-repeating notification not before a given date/time. |
| [`scheduleAt`](#scheduleat) | method (`MobileNotificationService`) | A | Schedule a one-time notification at a specific date/time. |
| [`cancel`](#cancel) | method (`MobileNotificationService`) | A | Cancel a scheduled notification by id. |
| [`cancelPendingInIdRange`](#cancelpendinginidrange) | method (`MobileNotificationService`) | A | Cancel every pending notification whose id falls in a range. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/services/mobile_notification_service.dart`
returns 9, matching the 9 rows above exactly. Every block documents a real declaration immediately
below it (constructor, getter, or method) — no misattached blocks and no undocumented declarations
were found in this file.

## Documentation

### `Future<void> init()` <a id="init"></a>
- **Kind:** method of `MobileNotificationService`
- **Source:** `lib/shared/services/mobile_notification_service.dart` (line 36)
- **Purpose:** One-time setup: initialize the tz database with the device's real timezone, wire up
  the `flutter_local_notifications` plugin, and request the Android 13+ runtime notification
  permission.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Sets the global `tz.local` location, calls `_plugin.initialize(...)`, may
  prompt the user for the Android notification permission, and sets `_initialized = true`.
- **Algorithm:**
  1. Return immediately if not mobile (`Platform.isAndroid || Platform.isIOS`) or already
     initialized.
  2. Call `tz.initializeTimeZones()`.
  3. Try `FlutterTimezone.getLocalTimezone()` and `tz.setLocalLocation(tz.getLocation(info.identifier))`
     using the OS-reported IANA zone id.
  4. On failure, fall back: compute the current UTC offset
     (`DateTime.now().timeZoneOffset`) and search `tz.timeZoneDatabase.locations` for any location
     whose `currentTimeZone.offset` (in milliseconds) matches; use the first match if found.
  5. Build Android (`@mipmap/ic_launcher`) and iOS (alert/badge/sound permission requests)
     initialization settings and call `_plugin.initialize(...)`.
  6. On Android, call
     `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission()`.
  7. Set `_initialized = true`.
- **Usage:**
  ```dart
  if (Platform.isAndroid || Platform.isIOS) {
    await MobileNotificationService.instance.init();
  }
  ```
  (`lib/main.dart:27-28`, at app startup.)
- **Notes:** Using the OS IANA zone id instead of `DateTime.now().timeZoneName` matters because the
  latter is an abbreviation (e.g. "JST"/"CST") the tz database cannot look up directly, and an
  offset-only fallback could pick a zone with different DST rules than the device's actual zone.

### `Future<void> showNow({required int id, required String title, required String body})` <a id="shownow"></a>
- **Kind:** method of `MobileNotificationService`
- **Source:** `lib/shared/services/mobile_notification_service.dart` (line 89)
- **Purpose:** Fire an immediate (non-scheduled) notification, used as the mobile fallback path
  when `ReminderService` wants to notify the user right away.
- **Inputs:** `id` — unique notification id; `title`, `body` — display text.
- **Returns:** `Future<void>`.
- **Side effects:** Calls `_plugin.show(...)`, immediately posting an OS notification.
- **Algorithm:**
  1. Return immediately if not yet `_initialized`.
  2. Build `NotificationDetails` (Android channel `myday_reminders`, `Importance.high` /
     `Priority.high`; default `DarwinNotificationDetails` for iOS).
  3. Call `_plugin.show(id, title, body, details)`.
- **Usage:**
  ```dart
  MobileNotificationService.instance.showNow(
    id: _notifyCounter++,
    title: 'MyDay!!!!!',
    body: message,
  );
  ```
  (`lib/shared/services/reminder_service.dart:1004-1008`, inside `_notify()`'s mobile branch.)
- **Notes:** None.

### `Future<void> scheduleDaily({required int id, required String title, required String body, required TimeOfDay time})` <a id="scheduledaily"></a>
- **Kind:** method of `MobileNotificationService`
- **Source:** `lib/shared/services/mobile_notification_service.dart` (line 115)
- **Purpose:** Convenience wrapper that schedules a daily-repeating notification anchored to
  today's date at the given time of day.
- **Inputs:** `time` — the daily fire time (date components are ignored and replaced with today).
- **Returns:** `Future<void>`.
- **Side effects:** Delegates to [`scheduleDailyStarting`](#scheduledailystarting).
- **Algorithm:**
  1. Compute `now = DateTime.now()`.
  2. Call `scheduleDailyStarting` with `startDateTime` built from today's year/month/day plus
     `time.hour`/`time.minute`.
- **Usage:**
  ```dart
  mns.scheduleDaily(
    id: id,
    title: 'MyDay!!!!!',
    body: _l10n.notifWeightReminder,
    time: time,
  );
  ```
  (`lib/shared/services/reminder_service.dart:452-457`, scheduling a weight reminder outside the
  grace window.)
- **Notes:** None.

### `Future<void> scheduleDailyStarting({required int id, required String title, required String body, required DateTime startDateTime})` <a id="scheduledailystarting"></a>
- **Kind:** method of `MobileNotificationService`
- **Source:** `lib/shared/services/mobile_notification_service.dart` (line 142)
- **Purpose:** Schedule a daily-repeating notification whose first fire is no earlier than
  `startDateTime`, letting callers delay the first repeat (e.g. to tomorrow) while still repeating
  daily thereafter.
- **Inputs:** `startDateTime` — the earliest allowed first fire; only its time-of-day matters once
  the schedule takes effect, since repeats use `matchDateTimeComponents: DateTimeComponents.time`.
- **Returns:** `Future<void>`.
- **Side effects:** Cancels any existing notification with `id`, then calls `_plugin.zonedSchedule`
  to install a repeating OS schedule.
- **Algorithm:**
  1. Return immediately if not yet `_initialized`.
  2. Cancel any existing notification with `id`.
  3. Build `NotificationDetails` (same channel as `showNow`).
  4. Compute `now = tz.TZDateTime.now(tz.local)` and
     `scheduledDate = tz.TZDateTime.from(startDateTime, tz.local)`.
  5. If `scheduledDate` is not after `now`, recompute it as *today* at `startDateTime`'s
     hour/minute; if that recomputed time is still not after `now`, add one day (push to tomorrow).
  6. Call `_plugin.zonedSchedule(id, title, body, scheduledDate, details,
     androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
     matchDateTimeComponents: DateTimeComponents.time)` — the `matchDateTimeComponents` argument is
     what makes the OS repeat this notification every day at that time.
- **Usage:**
  ```dart
  mns.scheduleDailyStarting(
    id: id,
    title: 'MyDay!!!!!',
    body: _l10n.notifWeightReminder,
    startDateTime: candidate.add(const Duration(days: 1)),
  );
  ```
  (`lib/shared/services/reminder_service.dart:444-449`, shifting a weight reminder's daily repeat
  to start tomorrow when today's record falls inside the grace window.)
- **Notes:** Step 5's two-stage recompute is what lets a caller pass an already-past
  `startDateTime` (e.g. "today at 8am" when it's already past 8am) and still get a valid next-day
  schedule instead of an error or an immediately-firing notification.

### `Future<void> scheduleAt({required int id, required String title, required String body, required DateTime dateTime})` <a id="scheduleat"></a>
- **Kind:** method of `MobileNotificationService`
- **Source:** `lib/shared/services/mobile_notification_service.dart` (line 196)
- **Purpose:** Schedule a one-time (non-repeating) notification at an exact date/time.
- **Inputs:** `dateTime` — the exact fire moment.
- **Returns:** `Future<void>`.
- **Side effects:** Cancels any existing notification with `id`, then may call
  `_plugin.zonedSchedule`.
- **Algorithm:**
  1. Return immediately if not yet `_initialized`.
  2. Cancel any existing notification with `id`.
  3. Build `NotificationDetails`.
  4. Compute `scheduledDate = tz.TZDateTime.from(dateTime, tz.local)`; if it `isBefore` the current
     `tz.TZDateTime.now(tz.local)`, return without scheduling (silently skip past-due one-shots).
  5. Call `_plugin.zonedSchedule(...)` with `androidScheduleMode: inexactAllowWhileIdle` and no
     `matchDateTimeComponents` (so it fires once, not daily).
- **Usage:**
  ```dart
  await mns.scheduleAt(
    id: _mobileSubReminderDayBaseId + offset,
    title: 'MyDay!!!!!',
    body: _l10n.notifUpcomingRenewals(upcoming.join(', ')),
    dateTime: fireAt,
  );
  ```
  (`lib/shared/services/reminder_service.dart:386-391`, scheduling per-day subscription-renewal
  one-shots for the next 7 days.)
- **Notes:** The missing `matchDateTimeComponents` argument (present in
  [`scheduleDailyStarting`](#scheduledailystarting) but not here) is the actual mechanism that
  distinguishes a one-shot from a daily repeat — both otherwise call the same plugin method.

### `Future<void> cancel(int id)` <a id="cancel"></a>
- **Kind:** method of `MobileNotificationService`
- **Source:** `lib/shared/services/mobile_notification_service.dart` (line 236)
- **Purpose:** Cancel a single scheduled notification by id.
- **Inputs:** `id`.
- **Returns:** `Future<void>`.
- **Side effects:** Calls `_plugin.cancel(id)`.
- **Algorithm:** Return immediately if not `_initialized`; otherwise call `_plugin.cancel(id)`.
- **Usage:**
  ```dart
  mns.cancel(_mobileWeightMorningId);
  ```
  (`lib/shared/services/reminder_service.dart:410`, clearing the morning weight reminder when the
  user disables it.)
- **Notes:** None.

### `Future<void> cancelPendingInIdRange({required int minId, required int maxId})` <a id="cancelpendinginidrange"></a>
- **Kind:** method of `MobileNotificationService`
- **Source:** `lib/shared/services/mobile_notification_service.dart` (line 247)
- **Purpose:** Bulk-cancel every pending notification whose id falls within `[minId, maxId]`,
  cleaning out an entire ID namespace at once (e.g. all per-task reminder ids) regardless of which
  specific ids were actually scheduled.
- **Inputs:** `minId`, `maxId` — inclusive bounds of the id range to clear.
- **Returns:** `Future<void>`.
- **Side effects:** Reads `_plugin.pendingNotificationRequests()` and calls `_plugin.cancel(...)`
  for each match.
- **Algorithm:**
  1. Return immediately if not `_initialized`.
  2. Fetch all pending requests via `_plugin.pendingNotificationRequests()`.
  3. For each request whose `id` satisfies `id >= minId && id <= maxId`, call
     `_plugin.cancel(request.id)`.
- **Usage:**
  ```dart
  await mns.cancelPendingInIdRange(
    minId: _mobileTaskReminderMinId,
    maxId: _mobileTaskReminderMaxId,
  );
  ```
  (`lib/shared/services/reminder_service.dart:515-518`, clearing all previously scheduled per-task
  notifications — including ones left behind by older app versions or previous launches — before
  rescheduling current tasks.)
- **Notes:** Unlike [`cancel`](#cancel), which requires knowing the exact id, this is the mechanism
  used to clean up ids that may no longer be tracked in current app state (e.g. after an ID
  algorithm change across app versions).

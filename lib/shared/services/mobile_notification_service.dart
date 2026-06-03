import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for scheduling notifications on Android/iOS.
/// On mobile, the OS delivers notifications even when the app is killed.
class MobileNotificationService {
  /// Purpose: Prevent direct instantiation of the mobile notification singleton.
  /// Inputs: None.
  /// Returns: A new `MobileNotificationService` instance.
  /// Side effects: None.
  /// Notes: Use `MobileNotificationService.instance` instead.
  MobileNotificationService._();
  static final instance = MobileNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Whether we are on a mobile platform that needs scheduled notifications.
  /// Purpose: Return whether mobile is true.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  /// Purpose: Implement the init behavior for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  Future<void> init() async {
    if (!isMobile || _initialized) return;

    tz.initializeTimeZones();
    // Set local location to the device timezone
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // Fallback: use UTC offset to find a matching location
      final offset = DateTime.now().timeZoneOffset;
      final locations = tz.timeZoneDatabase.locations.values.where(
        (l) => l.currentTimeZone.offset == offset.inMilliseconds,
      );
      if (locations.isNotEmpty) {
        tz.setLocalLocation(locations.first);
      }
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Request permissions on Android 13+
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Show an immediate notification (used as fallback for _notify on mobile).
  /// Purpose: Show now through the current flow.
  /// Inputs: `id`, `title`, `body`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'myday_reminders',
        'MyDay Reminders',
        channelDescription: 'Reminders for tasks and subscriptions',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details);
  }

  /// Schedule a daily notification at the given time.
  /// [id] should be a unique integer per scheduled notification type.
  /// Purpose: Implement the schedule daily behavior for this file.
  /// Inputs: `id`, `title`, `body`, `time`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: The first fire time is today or tomorrow at `time`.
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    await scheduleDailyStarting(
      id: id,
      title: title,
      body: body,
      startDateTime: DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      ),
    );
  }

  /// Schedule a daily notification beginning no earlier than a date/time.
  /// Purpose: Implement the schedule daily starting behavior for this file.
  /// Inputs: `id`, `title`, `body`, `startDateTime`.
  /// Returns: `Future<void>`.
  /// Side effects: Cancels any existing notification with `id` and schedules a repeating OS notification.
  /// Notes: Used when the first repeat should wait for a future activation date.
  Future<void> scheduleDailyStarting({
    required int id,
    required String title,
    required String body,
    required DateTime startDateTime,
  }) async {
    if (!_initialized) return;

    await _plugin.cancel(id);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'myday_reminders',
        'MyDay Reminders',
        channelDescription: 'Reminders for tasks and subscriptions',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime.from(startDateTime, tz.local);
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        startDateTime.hour,
        startDateTime.minute,
      );
      if (!scheduledDate.isAfter(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a one-time notification at a specific date/time.
  /// Purpose: Implement the schedule at behavior for this file.
  /// Inputs: `id`, `title`, `body`, `dateTime`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (!_initialized) return;

    await _plugin.cancel(id);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'myday_reminders',
        'MyDay Reminders',
        channelDescription: 'Reminders for tasks and subscriptions',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancel a scheduled notification by id.
  /// Purpose: Implement the cancel behavior for this file.
  /// Inputs: `id`.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }
}

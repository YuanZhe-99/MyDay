import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for scheduling notifications on Android/iOS.
/// On mobile, the OS delivers notifications even when the app is killed.
class MobileNotificationService {
  MobileNotificationService._();
  static final instance = MobileNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Whether we are on a mobile platform that needs scheduled notifications.
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

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

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Request permissions on Android 13+
    if (Platform.isAndroid) {
      await _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Show an immediate notification (used as fallback for _notify on mobile).
  Future<void> showNow({required int id, required String title, required String body}) async {
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
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
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
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
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

  /// Cancel a scheduled notification by id.
  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }
}

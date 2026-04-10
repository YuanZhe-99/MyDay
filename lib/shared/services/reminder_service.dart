import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:intl/intl.dart';

import '../../features/finance/models/finance.dart';
import '../../features/finance/services/finance_storage.dart';
import '../../features/finance/services/subscription_processor.dart';
import '../../features/todo/models/task.dart';
import '../../features/todo/services/todo_storage.dart';
import '../../l10n/app_localizations.dart';
import 'backup_service.dart';
import 'mobile_notification_service.dart';

/// Global reminder service that runs independently of page lifecycle.
/// Initialized once at app startup and keeps running across tab switches.
class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();

  Timer? _timer;
  final Set<String> _notifiedIds = {};
  Locale _locale = const Locale('en');

  AppLocalizations get _l10n => lookupAppLocalizations(_locale);

  // Cached data – refreshed on each tick
  List<Task> _dailyTemplates = [];
  List<Task> _oneTimeTasks = [];
  DailyCompletionLog _dailyLog = DailyCompletionLog();
  TimeOfDay? _morningReminderTime;
  TimeOfDay? _completionReminderTime;

  // Subscription reminder data
  List<Subscription> _subscriptions = [];
  TimeOfDay? _subscriptionReminderTime;

  /// Optional callback to show an in-app snackbar. Set by the shell scaffold.
  void Function(String message)? onShowSnackbar;

  /// Update locale for notification strings.
  void updateLocale(Locale locale) {
    _locale = locale;
  }

  /// Called when background renewal processing generates new transactions.
  /// If set, the finance page is open and should update its in-memory state.
  void Function()? onRenewalsProcessed;

  DateTime? _lastRenewalCheck;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
    _check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Call this whenever todo data changes so reminders stay up-to-date.
  void updateData({
    required List<Task> dailyTemplates,
    required List<Task> oneTimeTasks,
    required DailyCompletionLog dailyLog,
    TimeOfDay? morningReminderTime,
    TimeOfDay? completionReminderTime,
  }) {
    _dailyTemplates = dailyTemplates;
    _oneTimeTasks = oneTimeTasks;
    _dailyLog = dailyLog;
    _morningReminderTime = morningReminderTime;
    _completionReminderTime = completionReminderTime;
    _scheduleMobileTodoReminders();
  }

  /// Call this whenever subscription data or reminder settings change.
  void updateSubscriptionData({
    required List<Subscription> subscriptions,
    int? reminderHour,
    int? reminderMinute,
  }) {
    _subscriptions = subscriptions;
    _subscriptionReminderTime = reminderHour != null && reminderMinute != null
        ? TimeOfDay(hour: reminderHour, minute: reminderMinute)
        : null;
    _scheduleMobileSubscriptionReminder();
  }

  // Notification IDs for scheduled mobile notifications
  static const _mobileSubReminderId = 9000;
  static const _mobileMorningReminderId = 9001;
  static const _mobileCompletionReminderId = 9002;

  // Track per-task scheduled notification IDs so we can cancel stale ones.
  final Set<int> _scheduledTaskNotificationIds = {};

  /// Derive a stable notification ID from a task's string ID.
  static int _taskNotificationId(String taskId) =>
      taskId.hashCode.abs() % 100000 + 10000;

  /// Schedule subscription renewal notification on mobile.
  void _scheduleMobileSubscriptionReminder() {
    if (!MobileNotificationService.isMobile) return;
    final mns = MobileNotificationService.instance;
    if (_subscriptionReminderTime == null) {
      mns.cancel(_mobileSubReminderId);
      return;
    }
    // Build upcoming renewal message
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final limit = todayDate.add(const Duration(days: 3));
    final upcoming = <String>[];
    for (final sub in _subscriptions) {
      if (!sub.isActive && sub.cancelType == CancelType.immediate) continue;
      final next = sub.nextBillingDate;
      if (next != null) {
        final nextDay = DateTime(next.year, next.month, next.day);
        if (!nextDay.isAfter(limit)) {
          final days = nextDay.difference(todayDate).inDays;
          upcoming.add(days == 0 ? _l10n.notifSubscriptionToday(sub.name) : _l10n.notifSubscriptionDays(sub.name, days));
        }
      }
    }
    if (upcoming.isNotEmpty) {
      mns.scheduleDaily(
        id: _mobileSubReminderId,
        title: 'MyDay!!!!!',
        body: _l10n.notifUpcomingRenewals(upcoming.join(', ')),
        time: _subscriptionReminderTime!,
      );
    } else {
      mns.cancel(_mobileSubReminderId);
    }
  }

  /// Schedule todo reminder notifications on mobile.
  void _scheduleMobileTodoReminders() {
    if (!MobileNotificationService.isMobile) return;
    final mns = MobileNotificationService.instance;
    if (_morningReminderTime != null) {
      mns.scheduleDaily(
        id: _mobileMorningReminderId,
        title: 'MyDay!!!!!',
        body: _l10n.notifTodoMorning,
        time: _morningReminderTime!,
      );
    } else {
      mns.cancel(_mobileMorningReminderId);
    }
    if (_completionReminderTime != null) {
      mns.scheduleDaily(
        id: _mobileCompletionReminderId,
        title: 'MyDay!!!!!',
        body: _l10n.notifTodoCompletion,
        time: _completionReminderTime!,
      );
    } else {
      mns.cancel(_mobileCompletionReminderId);
    }
    _scheduleMobilePerTaskReminders();
  }

  /// Schedule individual per-task reminders via OS-level notifications.
  /// Daily templates get repeating daily notifications; one-time tasks
  /// get a single scheduled notification at the exact date/time.
  void _scheduleMobilePerTaskReminders() {
    final mns = MobileNotificationService.instance;

    // Cancel all previously scheduled per-task notifications.
    for (final id in _scheduledTaskNotificationIds) {
      mns.cancel(id);
    }
    _scheduledTaskNotificationIds.clear();

    for (final task in _dailyTemplates) {
      if (task.reminderTime == null || task.deletedDate != null) continue;
      final nid = _taskNotificationId(task.id);
      final label = task.emoji != null ? '${task.emoji} ${task.title}' : task.title;
      mns.scheduleDaily(
        id: nid,
        title: 'MyDay!!!!!',
        body: label,
        time: TimeOfDay.fromDateTime(task.reminderTime!),
      );
      _scheduledTaskNotificationIds.add(nid);
    }

    for (final task in _oneTimeTasks) {
      if (task.reminderTime == null || task.isCompleted) continue;
      final nid = _taskNotificationId(task.id);
      final label = task.emoji != null ? '${task.emoji} ${task.title}' : task.title;
      mns.scheduleAt(
        id: nid,
        title: 'MyDay!!!!!',
        body: label,
        dateTime: task.reminderTime!,
      );
      _scheduledTaskNotificationIds.add(nid);
    }
  }

  Future<void> _check() async {
    // If we have no cached data yet, try loading from storage
    if (_dailyTemplates.isEmpty && _oneTimeTasks.isEmpty) {
      final data = await TodoStorage.load();
      if (data != null) {
        _dailyTemplates = data.dailyTemplates;
        _oneTimeTasks = data.oneTimeTasks;
        _dailyLog = data.dailyLog;
        if (data.morningReminderHour != null &&
            data.morningReminderMinute != null) {
          _morningReminderTime = TimeOfDay(
            hour: data.morningReminderHour!,
            minute: data.morningReminderMinute!,
          );
        }
        if (data.completionReminderHour != null &&
            data.completionReminderMinute != null) {
          _completionReminderTime = TimeOfDay(
            hour: data.completionReminderHour!,
            minute: data.completionReminderMinute!,
          );
        }
      }
    }

    final now = TimeOfDay.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Per-task reminders
    for (final task in [..._dailyTemplates, ..._oneTimeTasks]) {
      if (task.reminderTime == null || task.isCompleted) continue;
      final rt = TimeOfDay.fromDateTime(task.reminderTime!);
      if (rt.hour == now.hour && rt.minute == now.minute) {
        final key = '${task.id}_$todayKey';
        if (!_notifiedIds.contains(key)) {
          _notifiedIds.add(key);
          _notify(
            task.emoji != null
                ? '${task.emoji} ${task.title}'
                : task.title,
          );
        }
      }
    }

    // Morning reminder
    if (_morningReminderTime != null &&
        _morningReminderTime!.hour == now.hour &&
        _morningReminderTime!.minute == now.minute) {
      final key = 'morning_$todayKey';
      if (!_notifiedIds.contains(key)) {
        _notifiedIds.add(key);
        _notify(_l10n.notifTodoMorning);
      }
    }

    // Completion reminder
    if (_completionReminderTime != null &&
        _completionReminderTime!.hour == now.hour &&
        _completionReminderTime!.minute == now.minute) {
      final key = 'completion_$todayKey';
      if (!_notifiedIds.contains(key)) {
        _notifiedIds.add(key);
        final uncompleted = _dailyTemplates
                .where((t) => !_dailyLog.isCompleted(DateTime.now(), t.id))
                .length +
            _oneTimeTasks.where((t) => !t.isCompleted).length;
        if (uncompleted > 0) {
          _notify(_l10n.notifTodoUncompleted(uncompleted));
        }
      }
    }

    // Subscription auto-renewal transaction generation (once per hour)
    await _processRenewals();

    // Auto-backup (once per day)
    await BackupService.runAutoBackupIfNeeded();

    // Subscription renewal reminder
    if (_subscriptionReminderTime != null &&
        _subscriptionReminderTime!.hour == now.hour &&
        _subscriptionReminderTime!.minute == now.minute) {
      final key = 'sub_reminder_$todayKey';
      if (!_notifiedIds.contains(key)) {
        _notifiedIds.add(key);
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final limit = todayDate.add(const Duration(days: 3));
        final upcoming = <String>[];
        for (final sub in _subscriptions) {
          if (!sub.isActive && sub.cancelType == CancelType.immediate) continue;
          final next = sub.nextBillingDate;
          if (next != null) {
            final nextDay = DateTime(next.year, next.month, next.day);
            if (!nextDay.isAfter(limit)) {
              final days = nextDay.difference(todayDate).inDays;
              upcoming.add(days == 0 ? _l10n.notifSubscriptionToday(sub.name) : _l10n.notifSubscriptionDays(sub.name, days));
            }
          }
        }
        if (upcoming.isNotEmpty) {
          _notify(_l10n.notifUpcomingRenewals(upcoming.join(', ')));
        }
      }
    }
  }

  /// Process subscription renewals: generate transactions for overdue billing
  /// dates. Runs at most once per hour from the background timer.
  Future<void> _processRenewals() async {
    final now = DateTime.now();
    if (_lastRenewalCheck != null &&
        now.difference(_lastRenewalCheck!).inMinutes < 60) {
      return;
    }
    _lastRenewalCheck = now;

    final data = await FinanceStorage.load();
    if (data == null || data.subscriptions.isEmpty) return;

    final result = SubscriptionProcessor.process(data.subscriptions, data.transactions);
    if (!result.changed) return;

    await FinanceStorage.save(FinanceData(
      accounts: data.accounts,
      categories: data.categories,
      transactions: [...data.transactions, ...result.txs],
      subscriptions: result.subs,
      defaultCurrency: data.defaultCurrency,
      subscriptionReminderHour: data.subscriptionReminderHour,
      subscriptionReminderMinute: data.subscriptionReminderMinute,
      subscriptionSortMode: data.subscriptionSortMode,
      subscriptionCustomOrder: data.subscriptionCustomOrder,
    ));

    // Notify finance page to reload if it's open
    onRenewalsProcessed?.call();
  }

  int _notifyCounter = 0;

  void _notify(String message) {
    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile: use flutter_local_notifications for immediate display
      MobileNotificationService.instance.showNow(
        id: _notifyCounter++,
        title: 'MyDay!!!!!',
        body: message,
      );
    } else {
      // Desktop: use local_notifier
      final notification = LocalNotification(
        title: 'MyDay!!!!!',
        body: message,
      );
      notification.show();
    }

    // Also try in-app snackbar if a callback is registered
    onShowSnackbar?.call(message);
  }
}

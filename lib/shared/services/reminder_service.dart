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
import '../../features/weight/models/weight_record.dart';
import '../../features/weight/services/weight_storage.dart';
import '../../l10n/app_localizations.dart';
import 'backup_service.dart';
import 'mobile_notification_service.dart';

/// Global reminder service that runs independently of page lifecycle.
/// Initialized once at app startup and keeps running across tab switches.
class ReminderService {
  /// Purpose: Prevent direct instantiation of the reminder singleton.
  /// Inputs: None.
  /// Returns: A new `ReminderService` instance.
  /// Side effects: None.
  /// Notes: Use `ReminderService.instance` instead.
  ReminderService._();
  static final instance = ReminderService._();

  Timer? _timer;
  final Set<String> _notifiedIds = {};
  Locale _locale = const Locale('en');

  /// Purpose: Return l10n.
  /// Inputs: None.
  /// Returns: `AppLocalizations`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
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

  // Weight reminder data
  List<WeightRecord> _weightRecords = [];
  TimeOfDay? _weightMorningReminder;
  TimeOfDay? _weightEveningReminder;
  int _weightReminderGraceMinutes = 180;
  bool _weightDataLoaded = false;

  /// Optional callback to show an in-app snackbar. Set by the shell scaffold.
  void Function(String message)? onShowSnackbar;

  /// Update locale for notification strings.
  /// Purpose: Update locale through the current flow.
  /// Inputs: `locale`.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  void updateLocale(Locale locale) {
    _locale = locale;
  }

  /// Called when background renewal processing generates new transactions.
  /// If set, the finance page is open and should update its in-memory state.
  void Function()? onRenewalsProcessed;

  DateTime? _lastRenewalCheck;

  /// Purpose: Start the current workflow and register any long-lived listeners.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
    _check();
  }

  /// Purpose: Stop the current workflow and clean up any related activity.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Call this whenever todo data changes so reminders stay up-to-date.
  /// Purpose: Update data through the current flow.
  /// Inputs: `dailyTemplates`, `oneTimeTasks`, `dailyLog`, `morningReminderTime`, `completionReminderTime`.
  /// Returns: None.
  /// Side effects: Updates cached todo reminder data and reschedules mobile notifications.
  /// Notes: None.
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
  /// Purpose: Update subscription data through the current flow.
  /// Inputs: `subscriptions`, `reminderHour`, `reminderMinute`.
  /// Returns: None.
  /// Side effects: Updates cached subscription reminder data and reschedules mobile notifications.
  /// Notes: None.
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

  /// Call this whenever weight reminder settings change.
  /// Purpose: Update weight data through the current flow.
  /// Inputs: `records`, `morningHour`, `morningMinute`, `eveningHour`, `eveningMinute`, `reminderGraceMinutes`.
  /// Returns: None.
  /// Side effects: Updates cached weight reminder data and reschedules mobile notifications.
  /// Notes: None.
  void updateWeightData({
    List<WeightRecord>? records,
    int? morningHour,
    int? morningMinute,
    int? eveningHour,
    int? eveningMinute,
    int? reminderGraceMinutes,
  }) {
    if (records != null) {
      _weightRecords = records;
      _weightDataLoaded = true;
    }
    _weightMorningReminder = morningHour != null && morningMinute != null
        ? TimeOfDay(hour: morningHour, minute: morningMinute)
        : null;
    _weightEveningReminder = eveningHour != null && eveningMinute != null
        ? TimeOfDay(hour: eveningHour, minute: eveningMinute)
        : null;
    _weightReminderGraceMinutes =
        reminderGraceMinutes ?? _weightReminderGraceMinutes;
    _scheduleMobileWeightReminders();
  }

  // Notification IDs for scheduled mobile notifications
  static const _mobileSubReminderId = 9000;
  static const _mobileMorningReminderId = 9001;
  static const _mobileCompletionReminderId = 9002;
  static const _mobileWeightMorningId = 9003;
  static const _mobileWeightEveningId = 9004;

  // Track per-task scheduled notification IDs so we can cancel stale ones.
  final Set<int> _scheduledTaskNotificationIds = {};

  /// Derive a stable notification ID from a task's string ID.
  /// Purpose: Provide the internal task notification id helper for this file.
  /// Inputs: `taskId`.
  /// Returns: `int`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static int _taskNotificationId(String taskId) =>
      taskId.hashCode.abs() % 100000 + 10000;

  /// Schedule subscription renewal notification on mobile.
  /// Purpose: Provide the internal schedule mobile subscription reminder helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  void _scheduleMobileSubscriptionReminder() {
    if (!MobileNotificationService.isMobile) return;
    final mns = MobileNotificationService.instance;
    if (_subscriptionReminderTime == null) {
      mns.cancel(_mobileSubReminderId);
      return;
    }
    // Build upcoming renewal message; at-expiry cancellations are expiry dates,
    // not actionable renewal reminders.
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final limit = todayDate.add(const Duration(days: 3));
    final upcoming = <String>[];
    for (final sub in _subscriptions) {
      if (sub.cancelType == CancelType.atExpiry) continue;
      if (!sub.isActive && sub.cancelType == CancelType.immediate) continue;
      final next = sub.nextBillingDate;
      if (next != null) {
        final nextDay = DateTime(next.year, next.month, next.day);
        if (!nextDay.isAfter(limit)) {
          final days = nextDay.difference(todayDate).inDays;
          upcoming.add(
            days == 0
                ? _l10n.notifSubscriptionToday(sub.name)
                : _l10n.notifSubscriptionDays(sub.name, days),
          );
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

  /// Schedule weight reminder notifications on mobile.
  /// Purpose: Provide the internal schedule mobile weight reminders helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  void _scheduleMobileWeightReminders() {
    if (!MobileNotificationService.isMobile) return;
    final mns = MobileNotificationService.instance;
    if (_weightMorningReminder != null) {
      _scheduleMobileWeightReminder(
        _mobileWeightMorningId,
        _weightMorningReminder!,
      );
    } else {
      mns.cancel(_mobileWeightMorningId);
    }
    if (_weightEveningReminder != null) {
      _scheduleMobileWeightReminder(
        _mobileWeightEveningId,
        _weightEveningReminder!,
      );
    } else {
      mns.cancel(_mobileWeightEveningId);
    }
  }

  /// Purpose: Provide the internal schedule mobile weight reminder helper for this file.
  /// Inputs: `id`, `time`.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  void _scheduleMobileWeightReminder(int id, TimeOfDay time) {
    final mns = MobileNotificationService.instance;
    final now = DateTime.now();
    var candidate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    if (_shouldSkipWeightReminder(candidate)) {
      mns.scheduleAt(
        id: id,
        title: 'MyDay!!!!!',
        body: _l10n.notifWeightReminder,
        dateTime: candidate.add(const Duration(days: 1)),
      );
      return;
    }
    mns.scheduleDaily(
      id: id,
      title: 'MyDay!!!!!',
      body: _l10n.notifWeightReminder,
      time: time,
    );
  }

  /// Schedule todo reminder notifications on mobile.
  /// Purpose: Provide the internal schedule mobile todo reminders helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
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
  /// Purpose: Provide the internal schedule mobile per task reminders helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
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
      final label = task.emoji != null
          ? '${task.emoji} ${task.title}'
          : task.title;
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
      final label = task.emoji != null
          ? '${task.emoji} ${task.title}'
          : task.title;
      mns.scheduleAt(
        id: nid,
        title: 'MyDay!!!!!',
        body: label,
        dateTime: task.reminderTime!,
      );
      _scheduledTaskNotificationIds.add(nid);
    }
  }

  /// Purpose: Provide the internal check helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
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
            task.emoji != null ? '${task.emoji} ${task.title}' : task.title,
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
        final uncompleted =
            _dailyTemplates
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

    if (!_weightDataLoaded) {
      await _refreshWeightDataFromStorage();
    }

    // Weight morning reminder
    if (_weightMorningReminder != null &&
        _weightMorningReminder!.hour == now.hour &&
        _weightMorningReminder!.minute == now.minute) {
      await _refreshWeightDataFromStorage();
      final key = 'weight_morning_$todayKey';
      if (!_notifiedIds.contains(key)) {
        _notifiedIds.add(key);
        final reminderAt = _todayAt(_weightMorningReminder!);
        if (!_shouldSkipWeightReminder(reminderAt)) {
          _notify(_l10n.notifWeightReminder);
        }
      }
    }

    // Weight evening reminder
    if (_weightEveningReminder != null &&
        _weightEveningReminder!.hour == now.hour &&
        _weightEveningReminder!.minute == now.minute) {
      await _refreshWeightDataFromStorage();
      final key = 'weight_evening_$todayKey';
      if (!_notifiedIds.contains(key)) {
        _notifiedIds.add(key);
        final reminderAt = _todayAt(_weightEveningReminder!);
        if (!_shouldSkipWeightReminder(reminderAt)) {
          _notify(_l10n.notifWeightReminder);
        }
      }
    }

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
          if (sub.cancelType == CancelType.atExpiry) continue;
          if (!sub.isActive && sub.cancelType == CancelType.immediate) continue;
          final next = sub.nextBillingDate;
          if (next != null) {
            final nextDay = DateTime(next.year, next.month, next.day);
            if (!nextDay.isAfter(limit)) {
              final days = nextDay.difference(todayDate).inDays;
              upcoming.add(
                days == 0
                    ? _l10n.notifSubscriptionToday(sub.name)
                    : _l10n.notifSubscriptionDays(sub.name, days),
              );
            }
          }
        }
        if (upcoming.isNotEmpty) {
          _notify(_l10n.notifUpcomingRenewals(upcoming.join(', ')));
        }
      }
    }
  }

  /// Purpose: Provide the internal today at helper for this file.
  /// Inputs: `time`.
  /// Returns: `DateTime`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  DateTime _todayAt(TimeOfDay time) {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day, time.hour, time.minute);
  }

  /// Purpose: Provide the internal should skip weight reminder helper for this file.
  /// Inputs: `reminderAt`.
  /// Returns: `bool`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  bool _shouldSkipWeightReminder(DateTime reminderAt) {
    if (_weightReminderGraceMinutes <= 0) return false;
    final windowStart = reminderAt.subtract(
      Duration(minutes: _weightReminderGraceMinutes),
    );
    final windowEnd = reminderAt.add(const Duration(minutes: 1));
    return _weightRecords.any((record) {
      return !record.datetime.isBefore(windowStart) &&
          record.datetime.isBefore(windowEnd);
    });
  }

  /// Purpose: Provide the internal refresh weight data from storage helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  Future<void> _refreshWeightDataFromStorage() async {
    final data = await WeightStorage.load();
    if (data == null) {
      _weightDataLoaded = true;
      return;
    }

    _weightRecords = data.records;
    _weightReminderGraceMinutes = data.reminderGraceMinutes;
    _weightMorningReminder =
        data.reminderMode != 'none' &&
            data.morningHour != null &&
            data.morningMinute != null
        ? TimeOfDay(hour: data.morningHour!, minute: data.morningMinute!)
        : null;
    _weightEveningReminder =
        data.reminderMode == 'twice' &&
            data.eveningHour != null &&
            data.eveningMinute != null
        ? TimeOfDay(hour: data.eveningHour!, minute: data.eveningMinute!)
        : null;
    _weightDataLoaded = true;
  }

  /// Process subscription renewals: generate transactions for overdue billing
  /// dates. Runs at most once per hour from the background timer.
  /// Purpose: Provide the internal process renewals helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  Future<void> _processRenewals() async {
    final now = DateTime.now();
    if (_lastRenewalCheck != null &&
        now.difference(_lastRenewalCheck!).inMinutes < 60) {
      return;
    }
    _lastRenewalCheck = now;

    final data = await FinanceStorage.load();
    if (data == null || data.subscriptions.isEmpty) return;

    final result = SubscriptionProcessor.process(
      data.subscriptions,
      data.transactions,
    );
    if (!result.changed) return;

    await FinanceStorage.save(
      FinanceData(
        accounts: data.accounts,
        categories: data.categories,
        transactions: [...data.transactions, ...result.txs],
        subscriptions: result.subs,
        defaultCurrency: data.defaultCurrency,
        settingsModifiedAt: data.settingsModifiedAt,
        subscriptionReminderHour: data.subscriptionReminderHour,
        subscriptionReminderMinute: data.subscriptionReminderMinute,
        subscriptionSortMode: data.subscriptionSortMode,
        subscriptionCustomOrder: data.subscriptionCustomOrder,
        accountSortModes: data.accountSortModes,
        accountCustomOrders: data.accountCustomOrders,
      ),
    );

    // Notify finance page to reload if it's open
    onRenewalsProcessed?.call();
  }

  int _notifyCounter = 0;

  /// Purpose: Provide the internal notify helper for this file.
  /// Inputs: `message`.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
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

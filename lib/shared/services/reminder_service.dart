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

  /// Purpose: Re-schedule all OS-level mobile reminder notifications.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Rebuilds todo, subscription, and weight schedules on mobile.
  /// Notes: Call on app resume so per-day schedules are recomputed from
  /// current data after the device was suspended; no-op on desktop.
  void refreshMobileSchedules() {
    if (!MobileNotificationService.isMobile) return;
    _scheduleMobileTodoReminders();
    _scheduleMobileSubscriptionReminder();
    _scheduleMobileWeightReminders();
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
  static const _mobileSubReminderId = 9000; // legacy single repeating id
  static const _mobileMorningReminderId = 9001;
  static const _mobileCompletionReminderId = 9002;
  static const _mobileWeightMorningId = 9003;
  static const _mobileWeightEveningId = 9004;
  // Per-day subscription reminder one-shots (id = base + day offset).
  static const _mobileSubReminderDayBaseId = 9100;
  static const _mobileSubReminderDays = 7;
  static const _mobileTaskReminderMinId = 10000;
  static const _mobileTaskReminderIdRange = 100000;
  static const _mobileTaskReminderMaxId =
      _mobileTaskReminderMinId + _mobileTaskReminderIdRange - 1;

  // Track per-task scheduled notification IDs so we can cancel stale ones.
  final Set<int> _scheduledTaskNotificationIds = {};
  int _taskReminderScheduleGeneration = 0;

  /// Derive a stable notification ID from a task's string ID.
  /// Purpose: Provide the internal stable hash helper for this file.
  /// Inputs: `value`.
  /// Returns: `int`.
  /// Side effects: None.
  /// Notes: Dart `String.hashCode` is not guaranteed to be stable across app launches.
  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  /// Derive a stable notification ID from a task's string ID.
  /// Purpose: Provide the internal task notification id helper for this file.
  /// Inputs: `taskId`.
  /// Returns: `int`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  static int _taskNotificationId(String taskId) =>
      _mobileTaskReminderMinId +
      _stableHash(taskId) % _mobileTaskReminderIdRange;

  /// Purpose: Return a one-time task's first reminder date/time.
  /// Inputs: `task`.
  /// Returns: The first reminder `DateTime`, or null when the task should not remind.
  /// Side effects: None.
  /// Notes: This preserves the scheduled date before any daily-repeat calculation.
  @visibleForTesting
  static DateTime? firstOneTimeReminderDateTime(Task task) {
    if (task.type == TaskType.daily ||
        task.reminderTime == null ||
        task.scheduledDate == null ||
        task.isCompleted) {
      return null;
    }

    final scheduled = task.scheduledDate!;
    final reminderTime = task.reminderTime!;
    return DateTime(
      scheduled.year,
      scheduled.month,
      scheduled.day,
      reminderTime.hour,
      reminderTime.minute,
    );
  }

  /// Purpose: Return a one-time task's next reminder date/time from a reference point.
  /// Inputs: `task`, `now`.
  /// Returns: The next reminder `DateTime`, or null when the task should not remind.
  /// Side effects: None.
  /// Notes: One-time reminders begin on `scheduledDate` and repeat daily until completed.
  @visibleForTesting
  static DateTime? nextOneTimeReminderDateTime(Task task, DateTime now) {
    final start = firstOneTimeReminderDateTime(task);
    if (start == null) return null;
    if (start.isAfter(now)) return start;

    final reminderTime = task.reminderTime!;
    final todayReminder = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    if (todayReminder.isAfter(now)) return todayReminder;
    return todayReminder.add(const Duration(days: 1));
  }

  /// Purpose: Decide whether mobile can use a daily repeating OS notification for a one-time task.
  /// Inputs: `task`, `now`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Future scheduled dates must use a one-shot notification because mobile daily repeats match time only.
  @visibleForTesting
  static bool shouldUseDailyMobileOneTimeReminder(Task task, DateTime now) {
    final firstReminder = firstOneTimeReminderDateTime(task);
    if (firstReminder == null) return false;

    final scheduledDate = DateTime(
      firstReminder.year,
      firstReminder.month,
      firstReminder.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return !scheduledDate.isAfter(today);
  }

  /// Purpose: Decide whether a one-time task's reminder is due at [now].
  /// Inputs: `task`, `now`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Used by the in-process desktop reminder loop. Due means now is at
  /// or after today's reminder time (per-day dedupe is the caller's job), so a
  /// process that was busy or suspended through the exact minute still fires.
  @visibleForTesting
  static bool shouldNotifyOneTimeTask(Task task, DateTime now) {
    if (task.type == TaskType.daily ||
        task.reminderTime == null ||
        task.scheduledDate == null ||
        task.isCompleted) {
      return false;
    }
    final scheduledDate = DateTime(
      task.scheduledDate!.year,
      task.scheduledDate!.month,
      task.scheduledDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    if (today.isBefore(scheduledDate)) return false;

    final reminderTime = task.reminderTime!;
    final dueAt = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    return !now.isBefore(dueAt);
  }

  /// Purpose: Decide whether an unfinished one-time task is active for today's checks.
  /// Inputs: `task`, `today`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Future scheduled tasks should not count as pending for today's completion reminder.
  static bool _isActiveOneTimeTask(Task task, DateTime today) {
    if (task.type == TaskType.daily ||
        task.isCompleted ||
        task.scheduledDate == null) {
      return false;
    }
    final scheduledDate = DateTime(
      task.scheduledDate!.year,
      task.scheduledDate!.month,
      task.scheduledDate!.day,
    );
    final todayDate = DateTime(today.year, today.month, today.day);
    return !scheduledDate.isAfter(todayDate);
  }

  /// Schedule subscription renewal notifications on mobile.
  /// Purpose: Provide the internal schedule mobile subscription reminder helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Starts asynchronous cancellation and per-day scheduling.
  /// Notes: Internal helper used within this file only. Each of the next
  /// [_mobileSubReminderDays] days gets its own one-shot with the renewals due
  /// within 3 days of that day (empty days are skipped), so renewals entering
  /// the window are announced and stale text never repeats. Schedules refresh
  /// on data change, hourly renewal processing, and app resume.
  void _scheduleMobileSubscriptionReminder() {
    if (!MobileNotificationService.isMobile) return;
    unawaited(_scheduleMobileSubscriptionReminderAsync());
  }

  /// Purpose: Rebuild the per-day mobile subscription renewal one-shots.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Cancels previous schedules and creates new OS notifications.
  /// Notes: Internal helper used within this file only.
  Future<void> _scheduleMobileSubscriptionReminderAsync() async {
    final mns = MobileNotificationService.instance;
    // Clear the legacy repeating id and all per-day ids before rescheduling.
    await mns.cancel(_mobileSubReminderId);
    for (var i = 0; i < _mobileSubReminderDays; i++) {
      await mns.cancel(_mobileSubReminderDayBaseId + i);
    }
    final time = _subscriptionReminderTime;
    if (time == null) return;

    final now = DateTime.now();
    for (var offset = 0; offset < _mobileSubReminderDays; offset++) {
      final fireAt = DateTime(
        now.year,
        now.month,
        now.day + offset,
        time.hour,
        time.minute,
      );
      if (!fireAt.isAfter(now)) continue;
      final upcoming = _upcomingRenewalLines(fireAt);
      if (upcoming.isEmpty) continue;
      await mns.scheduleAt(
        id: _mobileSubReminderDayBaseId + offset,
        title: 'MyDay!!!!!',
        body: _l10n.notifUpcomingRenewals(upcoming.join(', ')),
        dateTime: fireAt,
      );
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
  /// Notes: Internal helper used within this file only. When a recent record
  /// falls inside the grace window the daily repeat is kept and only shifted
  /// to start the next day — never replaced by a one-shot, which would stop
  /// all future weight reminders after firing once.
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
      mns.scheduleDailyStarting(
        id: id,
        title: 'MyDay!!!!!',
        body: _l10n.notifWeightReminder,
        startDateTime: candidate.add(const Duration(days: 1)),
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
  /// Daily templates get repeating daily notifications; one-time tasks repeat
  /// daily only after their scheduled date has arrived.
  /// Purpose: Provide the internal schedule mobile per task reminders helper for this file.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Starts asynchronous mobile notification cancellation and scheduling.
  /// Notes: Future one-time tasks use a one-shot activation reminder because mobile daily repeats ignore dates.
  void _scheduleMobilePerTaskReminders() {
    final generation = ++_taskReminderScheduleGeneration;
    unawaited(_scheduleMobilePerTaskRemindersAsync(generation));
  }

  /// Purpose: Reschedule mobile per-task reminders after todo data changes.
  /// Inputs: `generation`.
  /// Returns: `Future<void>`.
  /// Side effects: Cancels stale task notifications and schedules current task notifications.
  /// Notes: Skips stale async work when a newer reschedule has started.
  Future<void> _scheduleMobilePerTaskRemindersAsync(int generation) async {
    final mns = MobileNotificationService.instance;

    // Cancel all previously scheduled per-task notifications, including those
    // left behind by older app versions or previous app launches.
    await mns.cancelPendingInIdRange(
      minId: _mobileTaskReminderMinId,
      maxId: _mobileTaskReminderMaxId,
    );
    if (generation != _taskReminderScheduleGeneration) return;
    for (final id in _scheduledTaskNotificationIds) {
      await mns.cancel(id);
    }
    if (generation != _taskReminderScheduleGeneration) return;
    _scheduledTaskNotificationIds.clear();

    final now = DateTime.now();
    for (final task in _dailyTemplates) {
      if (generation != _taskReminderScheduleGeneration) return;
      if (task.reminderTime == null || task.deletedDate != null) continue;
      final nid = _taskNotificationId(task.id);
      final label = task.emoji != null
          ? '${task.emoji} ${task.title}'
          : task.title;
      final time = TimeOfDay.fromDateTime(task.reminderTime!);
      final todayAt = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (_dailyLog.isCompleted(now, task.id) && todayAt.isAfter(now)) {
        // Already completed today → skip today's pending fire, repeat from
        // tomorrow onwards.
        await mns.scheduleDailyStarting(
          id: nid,
          title: 'MyDay!!!!!',
          body: label,
          startDateTime: todayAt.add(const Duration(days: 1)),
        );
      } else {
        await mns.scheduleDaily(
          id: nid,
          title: 'MyDay!!!!!',
          body: label,
          time: time,
        );
      }
      _scheduledTaskNotificationIds.add(nid);
    }

    for (final task in _oneTimeTasks) {
      if (generation != _taskReminderScheduleGeneration) return;
      final firstReminder = firstOneTimeReminderDateTime(task);
      if (firstReminder == null) continue;
      final nid = _taskNotificationId(task.id);
      final label = task.emoji != null
          ? '${task.emoji} ${task.title}'
          : task.title;
      if (shouldUseDailyMobileOneTimeReminder(task, now)) {
        final nextReminder = nextOneTimeReminderDateTime(task, now);
        if (nextReminder == null) continue;
        await mns.scheduleDailyStarting(
          id: nid,
          title: 'MyDay!!!!!',
          body: label,
          startDateTime: nextReminder,
        );
      } else {
        await mns.scheduleAt(
          id: nid,
          title: 'MyDay!!!!!',
          body: label,
          dateTime: firstReminder,
        );
      }
      _scheduledTaskNotificationIds.add(nid);
    }
  }

  /// Purpose: Provide the internal check helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only. Background processing
  /// (subscription renewals, auto-backup) runs on every platform; user-facing
  /// reminder notifications are desktop-only here because mobile delivers them
  /// through OS-level scheduled notifications and would otherwise be notified
  /// twice. Unreadable Todo data skips that read-only reminder pass. A reminder
  /// fires when now >= its time and it has not fired today,
  /// so a busy or suspended process cannot skip its minute; fired keys persist
  /// across restarts via storage config.
  Future<void> _check() async {
    // Subscription auto-renewal transaction generation (once per hour).
    await _processRenewals();

    // Auto-backup (once per day).
    await BackupService.runAutoBackupIfNeeded();

    // Mobile reminders are OS-scheduled; the in-process loop must not
    // duplicate them while the app is in the foreground.
    if (MobileNotificationService.isMobile) return;

    var todoDataReadable = true;
    TodoData? todoData;
    try {
      todoData = await TodoStorage.load();
    } catch (_) {
      todoDataReadable = false;
    }
    if (todoData == null) {
      todoDataReadable = false;
      _dailyTemplates = [];
      _oneTimeTasks = [];
      _dailyLog = DailyCompletionLog();
      _morningReminderTime = null;
      _completionReminderTime = null;
    } else {
      _dailyTemplates = todoData.dailyTemplates;
      _oneTimeTasks = todoData.oneTimeTasks;
      _dailyLog = todoData.dailyLog;
      _morningReminderTime =
          todoData.morningReminderHour != null &&
              todoData.morningReminderMinute != null
          ? TimeOfDay(
              hour: todoData.morningReminderHour!,
              minute: todoData.morningReminderMinute!,
            )
          : null;
      _completionReminderTime =
          todoData.completionReminderHour != null &&
              todoData.completionReminderMinute != null
          ? TimeOfDay(
              hour: todoData.completionReminderHour!,
              minute: todoData.completionReminderMinute!,
            )
          : null;
    }

    final current = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(current);
    await _loadNotifiedKeys(todayKey);
    var notifiedChanged = false;

    // Marks [key] as fired and returns true when [dueAt] has been reached
    // today and the key has not fired yet.
    bool shouldFire(String key, DateTime dueAt) {
      if (current.isBefore(dueAt)) return false;
      if (_notifiedIds.contains(key)) return false;
      _notifiedIds.add(key);
      notifiedChanged = true;
      return true;
    }

    if (todoDataReadable) {
      // Per-task reminders. Soft-deleted templates and templates already
      // completed today must not remind.
      for (final task in _dailyTemplates) {
        if (task.reminderTime == null ||
            task.isCompleted ||
            task.deletedDate != null ||
            _dailyLog.isCompleted(current, task.id)) {
          continue;
        }
        final rt = TimeOfDay.fromDateTime(task.reminderTime!);
        if (shouldFire('${task.id}_$todayKey', _todayAt(rt))) {
          _notify(
            task.emoji != null ? '${task.emoji} ${task.title}' : task.title,
          );
        }
      }
      for (final task in _oneTimeTasks) {
        if (!shouldNotifyOneTimeTask(task, current)) continue;
        if (shouldFire('${task.id}_$todayKey', current)) {
          _notify(
            task.emoji != null ? '${task.emoji} ${task.title}' : task.title,
          );
        }
      }

      // Morning reminder
      if (_morningReminderTime != null &&
          shouldFire('morning_$todayKey', _todayAt(_morningReminderTime!))) {
        _notify(_l10n.notifTodoMorning);
      }

      // Completion reminder
      if (_completionReminderTime != null &&
          shouldFire(
            'completion_$todayKey',
            _todayAt(_completionReminderTime!),
          )) {
        final uncompleted =
            _dailyTemplates
                .where(
                  (t) =>
                      t.deletedDate == null &&
                      !_dailyLog.isCompleted(current, t.id),
                )
                .length +
            _oneTimeTasks.where((t) => _isActiveOneTimeTask(t, current)).length;
        if (uncompleted > 0) {
          _notify(_l10n.notifTodoUncompleted(uncompleted));
        }
      }
    }

    var weightDataReadable = true;
    if (!_weightDataLoaded) {
      weightDataReadable = await _refreshWeightDataFromStorage();
    }

    // Weight morning reminder. The grace check is anchored on the actual
    // fire moment (`current`), not the scheduled minute, so a record logged
    // between the scheduled time and a late check still suppresses it.
    if (_weightMorningReminder != null && weightDataReadable) {
      final reminderAt = _todayAt(_weightMorningReminder!);
      final key = 'weight_morning_$todayKey';
      if (!current.isBefore(reminderAt) && !_notifiedIds.contains(key)) {
        weightDataReadable = await _refreshWeightDataFromStorage();
        if (weightDataReadable &&
            shouldFire(key, reminderAt) &&
            !_shouldSkipWeightReminder(current)) {
          _notify(_l10n.notifWeightReminder);
        }
      }
    }

    // Weight evening reminder
    if (_weightEveningReminder != null && weightDataReadable) {
      final reminderAt = _todayAt(_weightEveningReminder!);
      final key = 'weight_evening_$todayKey';
      if (!current.isBefore(reminderAt) && !_notifiedIds.contains(key)) {
        weightDataReadable = await _refreshWeightDataFromStorage();
        if (weightDataReadable &&
            shouldFire(key, reminderAt) &&
            !_shouldSkipWeightReminder(current)) {
          _notify(_l10n.notifWeightReminder);
        }
      }
    }

    // Subscription renewal reminder
    if (_subscriptionReminderTime != null &&
        shouldFire(
          'sub_reminder_$todayKey',
          _todayAt(_subscriptionReminderTime!),
        )) {
      final upcoming = _upcomingRenewalLines(current);
      if (upcoming.isNotEmpty) {
        _notify(_l10n.notifUpcomingRenewals(upcoming.join(', ')));
      }
    }

    if (notifiedChanged) {
      await _persistNotifiedKeys(todayKey);
    }
  }

  /// Purpose: Build renewal reminder lines for subscriptions due within 3 days of [fromDay].
  /// Inputs: `fromDay` — the day the reminder fires (time-of-day ignored).
  /// Returns: `List<String>` of localized per-subscription lines.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Shared by the desktop
  /// loop and the per-day mobile schedules so both produce day-accurate text.
  List<String> _upcomingRenewalLines(DateTime fromDay) {
    final fromDate = DateTime(fromDay.year, fromDay.month, fromDay.day);
    final limit = fromDate.add(const Duration(days: 3));
    final upcoming = <String>[];
    for (final sub in _subscriptions) {
      if (sub.cancelType == CancelType.atExpiry) continue;
      if (!sub.isActive && sub.cancelType == CancelType.immediate) continue;
      final next = sub.nextBillingDate;
      if (next == null) continue;
      final nextDay = DateTime(next.year, next.month, next.day);
      if (nextDay.isBefore(fromDate) || nextDay.isAfter(limit)) continue;
      final days = nextDay.difference(fromDate).inDays;
      upcoming.add(
        days == 0
            ? _l10n.notifSubscriptionToday(sub.name)
            : _l10n.notifSubscriptionDays(sub.name, days),
      );
    }
    return upcoming;
  }

  bool _notifiedKeysLoaded = false;
  String _notifiedKeysDate = '';

  /// Purpose: Load today's already-fired reminder keys from storage config.
  /// Inputs: `todayKey` — yyyy-MM-dd of the current day.
  /// Returns: `Future<void>`.
  /// Side effects: Populates `_notifiedIds`; prunes keys from previous days.
  /// Notes: Internal helper used within this file only. Keeps desktop restarts
  /// from re-firing reminders that already fired earlier today.
  Future<void> _loadNotifiedKeys(String todayKey) async {
    if (_notifiedKeysDate != todayKey) {
      _notifiedIds.removeWhere((k) => !k.endsWith(todayKey));
      _notifiedKeysDate = todayKey;
    }
    if (_notifiedKeysLoaded) return;
    _notifiedKeysLoaded = true;
    try {
      final config = await TodoStorage.readConfig();
      final saved = config['reminderNotifiedKeys'];
      if (saved is Map && saved['date'] == todayKey) {
        final keys = saved['keys'];
        if (keys is List) {
          _notifiedIds.addAll(keys.whereType<String>());
        }
      }
    } catch (_) {}
  }

  /// Purpose: Persist today's fired reminder keys into storage config.
  /// Inputs: `todayKey` — yyyy-MM-dd of the current day.
  /// Returns: `Future<void>`.
  /// Side effects: Writes the device-local storage config.
  /// Notes: Config write failures are ignored so reminder delivery can continue.
  Future<void> _persistNotifiedKeys(String todayKey) async {
    try {
      final config = await TodoStorage.readConfig();
      config['reminderNotifiedKeys'] = {
        'date': todayKey,
        'keys': _notifiedIds.where((k) => k.endsWith(todayKey)).toList(),
      };
      await TodoStorage.writeConfig(config);
    } catch (_) {}
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

  /// Purpose: Decide whether a weight reminder should be suppressed because a
  /// record already exists inside the grace window.
  /// Inputs: `firesAt` — the moment the reminder actually fires (now for the
  /// desktop loop, the scheduled candidate time for mobile pre-scheduling).
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. The window is
  /// `[firesAt − grace, firesAt + 1 min)` and must be anchored on the actual
  /// fire moment, not the configured reminder minute — otherwise a record
  /// logged after the scheduled minute never suppresses a late-firing
  /// desktop reminder (e.g. reminder 08:00, record 08:30, app opened 11:00).
  bool _shouldSkipWeightReminder(DateTime firesAt) {
    return shouldSkipWeightReminderAt(
      firesAt: firesAt,
      records: _weightRecords,
      graceMinutes: _weightReminderGraceMinutes,
    );
  }

  /// Purpose: Pure grace-window decision for weight reminder suppression.
  /// Inputs: `firesAt`, `records`, `graceMinutes`.
  /// Returns: `bool` — true when a record falls in `[firesAt − grace, firesAt + 1 min)`.
  /// Side effects: None.
  /// Notes: Exposed statically so unit tests can cover the window semantics;
  /// production code goes through `_shouldSkipWeightReminder`.
  @visibleForTesting
  static bool shouldSkipWeightReminderAt({
    required DateTime firesAt,
    required List<WeightRecord> records,
    required int graceMinutes,
  }) {
    if (graceMinutes <= 0) return false;
    final windowStart = firesAt.subtract(Duration(minutes: graceMinutes));
    final windowEnd = firesAt.add(const Duration(minutes: 1));
    return records.any((record) {
      return !record.datetime.isBefore(windowStart) &&
          record.datetime.isBefore(windowEnd);
    });
  }

  /// Purpose: Provide the internal refresh weight data from storage helper for this file.
  /// Inputs: None.
  /// Returns: `Future<bool>` indicating whether valid data was loaded.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: An unreadable file leaves the cache retryable and skips reminders.
  Future<bool> _refreshWeightDataFromStorage() async {
    final WeightData? data;
    try {
      data = await WeightStorage.load();
    } catch (_) {
      _weightDataLoaded = false;
      return false;
    }
    if (data == null) {
      _weightRecords = [];
      _weightMorningReminder = null;
      _weightEveningReminder = null;
      _weightDataLoaded = true;
      return false;
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
    return true;
  }

  /// Process subscription renewals: generate transactions for overdue billing
  /// dates. Runs at most once per hour from the background timer.
  /// Purpose: Provide the internal process renewals helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only. Also refreshes the
  /// cached subscriptions and reminder time from storage and reschedules
  /// mobile renewal reminders, so reminders work even when the finance page
  /// was never opened in this session.
  Future<void> _processRenewals() async {
    final now = DateTime.now();
    if (_lastRenewalCheck != null &&
        now.difference(_lastRenewalCheck!).inMinutes < 60) {
      return;
    }
    _lastRenewalCheck = now;

    final data = await FinanceStorage.load();
    if (data == null) return;
    _subscriptionReminderTime =
        data.subscriptionReminderHour != null &&
            data.subscriptionReminderMinute != null
        ? TimeOfDay(
            hour: data.subscriptionReminderHour!,
            minute: data.subscriptionReminderMinute!,
          )
        : null;
    if (data.subscriptions.isEmpty) {
      _subscriptions = const [];
      _scheduleMobileSubscriptionReminder();
      return;
    }

    final result = SubscriptionProcessor.process(
      data.subscriptions,
      data.transactions,
    );
    _subscriptions = result.changed ? result.subs : data.subscriptions;
    _scheduleMobileSubscriptionReminder();
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
        accountPickerSettings: data.accountPickerSettings,
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

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'reminder_service.dart';
import 'webdav_service.dart';

/// Singleton service that triggers WebDAV sync automatically when enabled.
///
/// Four triggers (aligned with MyAnime/MyDevice):
///   1. App started → immediate sync
///   2. App resumed from background → immediate sync
///   3. Data saved locally → debounced sync (30 s after last save)
///   4. Periodic timer → sync every 15 minutes while the process is alive
class AutoSyncService with WidgetsBindingObserver {
  /// Purpose: Prevent direct instantiation of the auto-sync singleton.
  /// Inputs: None.
  /// Returns: A new `AutoSyncService` instance.
  /// Side effects: None.
  /// Notes: Use `AutoSyncService.instance` instead.
  AutoSyncService._();
  static final instance = AutoSyncService._();

  Timer? _debounce;
  Timer? _periodic;
  bool _started = false;

  static const _debounceDuration = Duration(seconds: 30);
  static const _periodicInterval = Duration(minutes: 15);

  /// Callbacks invoked when sync writes merged data to local files.
  /// UI pages should register to reload their data.
  final List<void Function()> _onLocalDataChanged = [];
  /// Purpose: Add on local data changed through the current flow.
  /// Inputs: `cb`.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  void addOnLocalDataChanged(void Function() cb) => _onLocalDataChanged.add(cb);
  /// Purpose: Remove on local data changed through the current flow.
  /// Inputs: `cb`.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  void removeOnLocalDataChanged(void Function() cb) => _onLocalDataChanged.remove(cb);

  /// Call once at app startup.
  /// Purpose: Start the current workflow and register any long-lived listeners.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    // Periodic background sync while the app process is alive. Mobile OS
    // suspension may delay ticks until resume (resume also syncs).
    _periodic?.cancel();
    _periodic = Timer.periodic(_periodicInterval, (_) => _trySync());
    // Sync immediately on app open
    _trySync();
  }

  /// Purpose: Stop the current workflow and clean up any related activity.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  void stop() {
    _debounce?.cancel();
    _debounce = null;
    _periodic?.cancel();
    _periodic = null;
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  /// Called by storage save methods to schedule a debounced sync.
  /// Purpose: Notify dependent code that data was saved locally.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  void notifySaved() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _trySync);
  }

  /// Purpose: Trigger a sync as soon as possible, skipping the debounce timer.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Cancels any pending debounce and starts a sync attempt.
  /// Notes: Used right after enabling/saving WebDAV auto-sync configuration.
  void requestSyncNow() {
    _debounce?.cancel();
    _debounce = null;
    unawaited(_trySync());
  }

  /// Purpose: Implement the did change app lifecycle state behavior for this file.
  /// Inputs: `state`.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: On resume also refreshes mobile reminder schedules so per-day
  /// notification bodies are recomputed from current data after suspension.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _trySync();
      ReminderService.instance.refreshMobileSchedules();
    }
  }

  /// Purpose: Provide the internal try sync helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  Future<void> _trySync() async {
    final config = await WebDAVService.loadConfig();
    if (config == null || !config.isConfigured || !config.autoSync) return;
    try {
      // Auto-resolve conflicts using LWW (newer modifiedAt wins) so that
      // one conflict doesn't block all other records from syncing.
      await WebDAVService.sync(config, autoResolve: true);
      // Notify UI pages if sync wrote merged data to local files
      if (WebDAVService.consumeLocalDataChanged()) {
        for (final cb in List.of(_onLocalDataChanged)) {
          cb();
        }
      }
    } catch (_) {
      // Auto-sync failures are silent — user can always sync manually.
    }
  }
}

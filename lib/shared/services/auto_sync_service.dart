import 'dart:async';

import 'package:flutter/widgets.dart';

import 'webdav_service.dart';

/// Singleton service that triggers WebDAV sync automatically when enabled.
///
/// Three triggers:
///   1. App started → immediate sync
///   2. App resumed from background → immediate sync
///   3. Data saved locally → debounced sync (30 s after last save)
class AutoSyncService with WidgetsBindingObserver {
  AutoSyncService._();
  static final instance = AutoSyncService._();

  Timer? _debounce;
  bool _started = false;

  static const _debounceDuration = Duration(seconds: 30);

  /// Call once at app startup.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    // Sync immediately on app open
    _trySync();
  }

  void stop() {
    _debounce?.cancel();
    _debounce = null;
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  /// Called by storage save methods to schedule a debounced sync.
  void notifySaved() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _trySync);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _trySync();
    }
  }

  Future<void> _trySync() async {
    final config = await WebDAVService.loadConfig();
    if (config == null || !config.isConfigured || !config.autoSync) return;
    try {
      // Auto-resolve conflicts using LWW (newer modifiedAt wins) so that
      // one conflict doesn't block all other records from syncing.
      await WebDAVService.sync(config, autoResolve: true);
    } catch (_) {
      // Auto-sync failures are silent — user can always sync manually.
    }
  }
}

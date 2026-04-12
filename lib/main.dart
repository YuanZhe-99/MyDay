import 'dart:io';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/app.dart';
import 'shared/services/auto_sync_service.dart';
import 'shared/services/local_api_server.dart';
import 'shared/services/mobile_notification_service.dart';
import 'shared/services/reminder_service.dart';
import 'shared/services/tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform-specific notification setup
  if (Platform.isAndroid || Platform.isIOS) {
    await MobileNotificationService.instance.init();
  } else {
    await localNotifier.setup(
      appName: 'MyDay!!!!!',
      shortcutPolicy: ShortcutPolicy.ignore,
    );
  }

  // Setup launch-at-startup on desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    final packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
  }

  // Start local HTTP API server if enabled (desktop only)
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await LocalApiServer.start();
  }

  // Start global reminder timer — runs regardless of which tab is active
  ReminderService.instance.start();

  // Start auto-sync lifecycle observer (syncs only when user opts in)
  AutoSyncService.instance.start();

  // Initialise system tray on desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await TrayService.instance.init();
  }

  runApp(
    DevicePreview(
      enabled: kDebugMode,
      builder: (_) => const ProviderScope(
        child: MyDayApp(),
      ),
    ),
  );
}

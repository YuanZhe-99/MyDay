import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../shared/providers/app_settings.dart';
import 'router.dart';
import 'theme.dart';

class MyDayApp extends ConsumerWidget {
  const MyDayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp.router(
      title: 'MyDay!!!!!',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,

      // Localization – user-chosen locale takes priority
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      // DevicePreview
      builder: DevicePreview.appBuilder,

      // Routing
      routerConfig: appRouter,
    );
  }
}

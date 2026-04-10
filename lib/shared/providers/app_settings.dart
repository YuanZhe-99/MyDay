import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/todo/services/todo_storage.dart';
import '../services/reminder_service.dart';
import '../services/tray_service.dart';

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final modeStr = await TodoStorage.getThemeMode();
    final localeTag = await TodoStorage.getLocaleTag();

    final themeMode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    Locale? locale;
    if (localeTag != null) {
      final parts = localeTag.split('_');
      locale = parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
    }

    state = AppSettings(themeMode: themeMode, locale: locale);
    final resolvedLocale = locale ?? PlatformDispatcher.instance.locale;
    TrayService.instance.updateLocale(resolvedLocale);
    ReminderService.instance.updateLocale(resolvedLocale);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => null,
    };
    TodoStorage.setThemeMode(str);
  }

  void setLocale(Locale? locale) {
    state = state.copyWith(locale: locale, clearLocale: locale == null);
    final resolvedLocale = locale ?? PlatformDispatcher.instance.locale;
    TrayService.instance.updateLocale(resolvedLocale);
    ReminderService.instance.updateLocale(resolvedLocale);
    if (locale == null) {
      TodoStorage.setLocaleTag(null);
    } else {
      final tag = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      TodoStorage.setLocaleTag(tag);
    }
  }
}

class AppSettings {
  final ThemeMode themeMode;
  final Locale? locale; // null = system

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
  });

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale, bool clearLocale = false}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);

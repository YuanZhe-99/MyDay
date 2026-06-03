import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/todo/services/todo_storage.dart';
import '../services/reminder_service.dart';
import '../services/tray_service.dart';
import '../utils/week_grouping.dart';

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  /// Purpose: Create an app settings notifier instance.
  /// Inputs: None.
  /// Returns: A new `AppSettingsNotifier` instance.
  /// Side effects: Starts loading persisted settings into state.
  /// Notes: Initializes with default settings before async persistence loads.
  AppSettingsNotifier() : super(const AppSettings()) {
    _loadPersisted();
  }

  /// Purpose: Provide the internal load persisted helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadPersisted() async {
    final modeStr = await TodoStorage.getThemeMode();
    final localeTag = await TodoStorage.getLocaleTag();
    final weekStartDay = await TodoStorage.getWeekStartDay();

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

    state = AppSettings(
      themeMode: themeMode,
      locale: locale,
      weekStartDay: weekStartDay,
    );
    final resolvedLocale = locale ?? PlatformDispatcher.instance.locale;
    TrayService.instance.updateLocale(resolvedLocale);
    ReminderService.instance.updateLocale(resolvedLocale);
  }

  /// Purpose: Implement the set theme mode behavior for this file.
  /// Inputs: `mode`.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    final str = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => null,
    };
    TodoStorage.setThemeMode(str);
  }

  /// Purpose: Implement the set locale behavior for this file.
  /// Inputs: `locale`.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
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

  /// Purpose: Update the first weekday used by app calendars and week grouping.
  /// Inputs: `weekday`.
  /// Returns: None.
  /// Side effects: Updates provider state and persists `storage_config.json`.
  /// Notes: Weekday uses Dart's Monday=1 through Sunday=7 numbering.
  void setWeekStartDay(int weekday) {
    final normalized = normalizeWeekStartDay(weekday);
    state = state.copyWith(weekStartDay: normalized);
    TodoStorage.setWeekStartDay(normalized);
  }
}

class AppSettings {
  final ThemeMode themeMode;
  final Locale? locale; // null = system
  final int weekStartDay;

  /// Purpose: Create a app settings instance.
  /// Inputs: `themeMode`, `locale`, and `weekStartDay`.
  /// Returns: A new `AppSettings` instance.
  /// Side effects: None.
  /// Notes: `weekStartDay` uses Dart's Monday=1 through Sunday=7 numbering.
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.weekStartDay = DateTime.monday,
  });

  /// Purpose: Create a copy of this value with selected fields replaced.
  /// Inputs: `clearLocale`.
  /// Returns: `AppSettings`.
  /// Side effects: None.
  /// Notes: None.
  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    int? weekStartDay,
    bool clearLocale = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
      weekStartDay: weekStartDay ?? this.weekStartDay,
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
      (ref) => AppSettingsNotifier(),
    );

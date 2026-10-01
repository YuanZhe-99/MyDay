import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../features/ai/services/on_device_ai_service.dart';
import '../../features/todo/services/todo_storage.dart';
import '../services/reminder_service.dart';
import '../services/tray_service.dart';
import '../utils/adaptive_layout.dart';
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

  /// Purpose: Create a notifier that starts from fixed settings.
  /// Inputs: `settings`.
  /// Returns: A new `AppSettingsNotifier` instance.
  /// Side effects: None; nothing is read from disk.
  /// Notes: For tests that override `appSettingsProvider`. Setters still
  /// persist through `TodoStorage`.
  AppSettingsNotifier.fixed(super.settings);

  /// Purpose: Provide the internal load persisted helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadPersisted() async {
    final modeStr = await TodoStorage.getThemeMode();
    final localeTag = await TodoStorage.getLocaleTag();
    final weekStartDay = await TodoStorage.getWeekStartDay();
    final todoSectionColumns = await TodoStorage.getTodoSectionColumns();
    final financeListColumns = await TodoStorage.getFinanceListColumns();
    final weightListColumns = await TodoStorage.getWeightListColumns();
    final intimacyListColumns = await TodoStorage.getIntimacyListColumns();
    final uiStyle = (await TodoStorage.getUiStyle()) == 'material3'
        ? AppUiStyle.material3
        : AppUiStyle.expressive;
    final onDeviceAiEnabled = await TodoStorage.getOnDeviceAiEnabled();
    final onDeviceAiPreferFast = await TodoStorage.getOnDeviceAiPreferFast();

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
      todoSectionColumns: todoSectionColumns,
      financeListColumns: financeListColumns,
      weightListColumns: weightListColumns,
      intimacyListColumns: intimacyListColumns,
      uiStyle: uiStyle,
      onDeviceAiEnabled: onDeviceAiEnabled,
      onDeviceAiPreferFast: onDeviceAiPreferFast,
    );
    final resolvedLocale = locale ?? PlatformDispatcher.instance.locale;
    TrayService.instance.updateLocale(resolvedLocale);
    ReminderService.instance.updateLocale(resolvedLocale);
    final ai = OnDeviceAiService.instance;
    await ai.setPreferFast(onDeviceAiPreferFast);
    await ai.setEnabled(onDeviceAiEnabled);
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

  /// Purpose: Choose the interface style (1.6.0).
  /// Inputs: `style`.
  /// Returns: None.
  /// Side effects: Persists the preference; the app rebuilds its theme and
  /// the shell its bottom bar.
  /// Notes: Expressive by default. Expressive also selects the floating
  /// island bottom bar, Material 3 the classic full-width bar; the
  /// wide-window rail is the same in both.
  void setUiStyle(AppUiStyle style) {
    state = state.copyWith(uiStyle: style);
    TodoStorage.setUiStyle(style == AppUiStyle.material3 ? 'material3' : null);
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

  /// Purpose: Update the remembered Todo section-column preference.
  /// Inputs: `columns` — `listColumnsAuto` or a pinned count.
  /// Returns: None.
  /// Side effects: Updates provider state and persists `storage_config.json`.
  /// Notes: Stored per surface, so the four list surfaces are independent, and
  /// device-locally, because window size is a property of the device.
  void setTodoSectionColumns(int columns) {
    state = state.copyWith(todoSectionColumns: columns);
    TodoStorage.setTodoSectionColumns(columns);
  }

  /// Purpose: Update the remembered Finance transaction-column preference.
  /// Inputs: `columns` — `listColumnsAuto` or a pinned count.
  /// Returns: None.
  /// Side effects: Updates provider state and persists `storage_config.json`.
  /// Notes: None.
  void setFinanceListColumns(int columns) {
    state = state.copyWith(financeListColumns: columns);
    TodoStorage.setFinanceListColumns(columns);
  }

  /// Purpose: Update the remembered Weight record-column preference.
  /// Inputs: `columns` — `listColumnsAuto` or a pinned count.
  /// Returns: None.
  /// Side effects: Updates provider state and persists `storage_config.json`.
  /// Notes: None.
  void setWeightListColumns(int columns) {
    state = state.copyWith(weightListColumns: columns);
    TodoStorage.setWeightListColumns(columns);
  }

  /// Purpose: Update the remembered Intimacy record-column preference.
  /// Inputs: `columns` — `listColumnsAuto` or a pinned count.
  /// Returns: None.
  /// Side effects: Updates provider state and persists `storage_config.json`.
  /// Notes: None.
  void setIntimacyListColumns(int columns) {
    state = state.copyWith(intimacyListColumns: columns);
    TodoStorage.setIntimacyListColumns(columns);
  }

  /// Purpose: Turn on-device AI on or off.
  /// Inputs: `enabled`.
  /// Returns: None.
  /// Side effects: Persists the preference and switches `OnDeviceAiService`.
  /// Notes: Off by default. Switching off cancels anything running; the
  /// insight cards then render nothing.
  void setOnDeviceAiEnabled(bool enabled) {
    state = state.copyWith(onDeviceAiEnabled: enabled);
    TodoStorage.setOnDeviceAiEnabled(enabled);
    OnDeviceAiService.instance.setEnabled(enabled);
  }

  /// Purpose: Prefer the faster on-device model where both sizes are served.
  /// Inputs: `enabled`.
  /// Returns: None.
  /// Side effects: Persists the preference; the service re-probes.
  /// Notes: Android only.
  void setOnDeviceAiPreferFast(bool enabled) {
    state = state.copyWith(onDeviceAiPreferFast: enabled);
    TodoStorage.setOnDeviceAiPreferFast(enabled);
    OnDeviceAiService.instance.setPreferFast(enabled);
  }
}

class AppSettings {
  final ThemeMode themeMode;
  final Locale? locale; // null = system
  final int weekStartDay;

  /// Column preference for the Todo page's sections: `listColumnsAuto` or a
  /// pinned count. Counts sections per row, not tiles per row — see
  /// `doc/en-us/adaptive-layout.md`.
  final int todoSectionColumns;

  /// Column preference for the Finance page's transaction list.
  final int financeListColumns;

  /// Column preference for the Weight page's record list.
  final int weightListColumns;

  /// Column preference for the Intimacy page's record list.
  final int intimacyListColumns;

  /// The interface style (1.6.0): Expressive (default, with the floating
  /// island bottom bar) or stock Material 3 (classic bottom bar).
  final AppUiStyle uiStyle;

  /// Whether on-device AI (the module insight cards) is on. Device-local.
  final bool onDeviceAiEnabled;

  /// Whether the faster on-device model is preferred (Android).
  final bool onDeviceAiPreferFast;

  /// Purpose: Create a app settings instance.
  /// Inputs: `themeMode`, `locale`, `weekStartDay`, the four column
  /// preferences, `uiStyle`, `onDeviceAiEnabled`, `onDeviceAiPreferFast`.
  /// Returns: A new `AppSettings` instance.
  /// Side effects: None.
  /// Notes: `weekStartDay` uses Dart's Monday=1 through Sunday=7 numbering.
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.weekStartDay = DateTime.monday,
    this.todoSectionColumns = listColumnsAuto,
    this.financeListColumns = listColumnsAuto,
    this.weightListColumns = listColumnsAuto,
    this.intimacyListColumns = listColumnsAuto,
    this.uiStyle = AppUiStyle.expressive,
    this.onDeviceAiEnabled = false,
    this.onDeviceAiPreferFast = false,
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
    int? todoSectionColumns,
    int? financeListColumns,
    int? weightListColumns,
    int? intimacyListColumns,
    AppUiStyle? uiStyle,
    bool? onDeviceAiEnabled,
    bool? onDeviceAiPreferFast,
    bool clearLocale = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: clearLocale ? null : (locale ?? this.locale),
      weekStartDay: weekStartDay ?? this.weekStartDay,
      todoSectionColumns: todoSectionColumns ?? this.todoSectionColumns,
      financeListColumns: financeListColumns ?? this.financeListColumns,
      weightListColumns: weightListColumns ?? this.weightListColumns,
      intimacyListColumns: intimacyListColumns ?? this.intimacyListColumns,
      uiStyle: uiStyle ?? this.uiStyle,
      onDeviceAiEnabled: onDeviceAiEnabled ?? this.onDeviceAiEnabled,
      onDeviceAiPreferFast: onDeviceAiPreferFast ?? this.onDeviceAiPreferFast,
    );
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
      (ref) => AppSettingsNotifier(),
    );

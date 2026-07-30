# lib/shared/providers/app_settings.dart

Riverpod state for the app's global theme mode, locale, and week-start-day preference. Feeds
`MyDayApp` (`app/app.dart`) directly and is read wherever a screen needs the configured week start
day (Todo/Weight/Intimacy calendars, `shared/utils/week_grouping.dart`). Also pushes locale
changes into `TrayService` and `ReminderService` so their user-facing text stays in sync. See
[../../../architecture.md#state-management](../../../architecture.md#state-management).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`AppSettingsNotifier` (constructor)](#appsettingsnotifier-new) | constructor (`AppSettingsNotifier`) | A | Start the notifier and load persisted settings. |
| [`_loadPersisted`](#_loadpersisted) | method (`AppSettingsNotifier`) | A | Load theme/locale/week-start-day from storage into state. |
| [`setThemeMode`](#setthememode) | method (`AppSettingsNotifier`) | A | Update and persist the theme mode. |
| [`setLocale`](#setlocale) | method (`AppSettingsNotifier`) | A | Update and persist the locale, propagating it to tray/reminder services. |
| [`setWeekStartDay`](#setweekstartday) | method (`AppSettingsNotifier`) | A | Update and persist the first weekday for calendars/week grouping. |
| [`AppSettings` (constructor)](#appsettings-new) | constructor (`AppSettings`) | A | Create an app settings value. |
| [`copyWith`](#copywith) | method (`AppSettings`) | A | Create a copy of this value with selected fields replaced. |
| `appSettingsProvider` | top-level variable (`StateNotifierProvider`) | B | Expose `AppSettingsNotifier` to the widget tree. |

`grep -c 'Purpose:' lib/shared/providers/app_settings.dart` reports 7, matching the seven
`Purpose:`-documented declarations above. The eighth row, `appSettingsProvider`, is a real
top-level declaration with no doc block at all (undocumented, not misattached) — a one-line
`StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) => AppSettingsNotifier())` factory,
trivial enough for Tier B.

**Reconciliation:** `grep -c 'Purpose:' lib/shared/providers/app_settings.dart` reports 7, matching 7 of the 8 rows above exactly. The extra row is `appSettingsProvider`, the `StateNotifierProvider` top-level variable: no `Purpose:` block, but it is the file's public entry point.

## Documentation

### `AppSettingsNotifier() : super(const AppSettings())` <a id="appsettingsnotifier-new"></a>
- **Kind:** constructor of `AppSettingsNotifier` (extends `StateNotifier<AppSettings>`)
- **Source:** `lib/shared/providers/app_settings.dart` (line 17)
- **Purpose:** Initialize state with default settings, then start loading the persisted settings
  asynchronously.
- **Inputs:** None.
- **Returns:** A new `AppSettingsNotifier`.
- **Side effects:** Calls `_loadPersisted()` (fire-and-forget).
- **Algorithm:** Initialize `state` to `const AppSettings()` (system theme, system locale, Monday
  week start), then invoke `_loadPersisted()` without awaiting it.
- **Usage:** Instantiated only by `appSettingsProvider`'s factory.
- **Notes:** Any read of `appSettingsProvider` before the async load resolves sees the compiled-in
  defaults, not the persisted values.

### `Future<void> _loadPersisted()` <a id="_loadpersisted"></a>
- **Kind:** private method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 26)
- **Purpose:** Read the persisted theme mode, locale tag, and week-start day from `TodoStorage`
  and apply them to state, then propagate the resolved locale to `TrayService`/`ReminderService`.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads `TodoStorage.getThemeMode()`, `getLocaleTag()`, `getWeekStartDay()`;
  overwrites `state`; calls `TrayService.instance.updateLocale(...)` and
  `ReminderService.instance.updateLocale(...)`.
- **Algorithm:**
  1. Read the three persisted values.
  2. Map the theme string to `ThemeMode` via a `switch`: `'light'` → `ThemeMode.light`, `'dark'` →
     `ThemeMode.dark`, anything else (including `null`) → `ThemeMode.system`.
  3. Parse `localeTag` (an underscore-joined tag like `en` or `zh_TW`) into a `Locale`, splitting on
     `'_'` and using a two-part `Locale(language, country)` constructor when a country part exists.
  4. Set `state` to a new `AppSettings` with the resolved `themeMode`/`locale`/`weekStartDay`.
  5. Resolve the effective locale (`locale ?? PlatformDispatcher.instance.locale`) and push it to
     both `TrayService.instance.updateLocale` and `ReminderService.instance.updateLocale`.
- **Usage:** Called once, from the constructor.
- **Notes:** `locale == null` in state means "follow system locale" — the effective locale passed
  to tray/reminder services always falls back to `PlatformDispatcher.instance.locale` in that case.

### `void setThemeMode(ThemeMode mode)` <a id="setthememode"></a>
- **Kind:** method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 58)
- **Purpose:** Update the app's theme mode and persist the choice.
- **Inputs:** `mode`.
- **Returns:** None.
- **Side effects:** Updates `state`; calls `TodoStorage.setThemeMode(str)` (fire-and-forget).
- **Algorithm:** `state = state.copyWith(themeMode: mode)`; map `mode` back to a nullable string
  (`light`/`dark`/`null` for system) via `switch`, then persist it.
- **Usage:**
  ```dart
  ref.read(appSettingsProvider.notifier).setThemeMode(mode);
  ```
  (`lib/features/settings/views/settings_page.dart`, theme radio selection.)
- **Notes:** `ThemeMode.system` is persisted as `null`, matching `_loadPersisted`'s reverse mapping.

### `void setLocale(Locale? locale)` <a id="setlocale"></a>
- **Kind:** method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 68)
- **Purpose:** Update the app's locale (or clear it back to system), persist the choice, and
  propagate the effective locale to `TrayService`/`ReminderService`.
- **Inputs:** `locale` — `null` means "follow system".
- **Returns:** None.
- **Side effects:** Updates `state`; calls `TrayService.instance.updateLocale` and
  `ReminderService.instance.updateLocale`; calls `TodoStorage.setLocaleTag(...)`.
- **Algorithm:**
  1. `state = state.copyWith(locale: locale, clearLocale: locale == null)` — the explicit
     `clearLocale` flag is needed because `copyWith`'s normal `??` pattern cannot distinguish
     "don't change" from "set to null".
  2. Resolve the effective locale the same way as `_loadPersisted` and push it to both services.
  3. If `locale == null`, persist `null` via `setLocaleTag`; otherwise build a tag
     (`'$languageCode_$countryCode'` if a country code exists, else just `languageCode`) and
     persist that.
- **Usage:**
  ```dart
  ref.read(appSettingsProvider.notifier).setLocale(locale);
  ```
  (`lib/features/settings/views/settings_page.dart`, language selection.)
- **Notes:** See `copyWith`'s Notes below for why `clearLocale` exists.

### `void setWeekStartDay(int weekday)` <a id="setweekstartday"></a>
- **Kind:** method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 93)
- **Purpose:** Update the first weekday used by app calendars and week grouping, persisting a
  normalized value.
- **Inputs:** `weekday` — Dart weekday numbering (Monday=1 .. Sunday=7); need not already be valid.
- **Returns:** None.
- **Side effects:** Updates `state`; calls `TodoStorage.setWeekStartDay(normalized)`.
- **Algorithm:** `normalizeWeekStartDay(weekday)` (see
  [../utils/week_grouping.md#normalizeweekstartday](../utils/week_grouping.md#normalizeweekstartday))
  clamps out-of-range input back to Monday; then update `state` and persist the normalized value.
- **Usage:**
  ```dart
  ref.read(appSettingsProvider.notifier).setWeekStartDay(weekday);
  ```
  (`lib/features/settings/views/settings_page.dart`, week-start-day radio selection.)
- **Notes:** Every calendar/week-grouping call site in the repo reads `weekStartDay` from this
  provider's state, so this is the single source of truth for the app-wide week start.

### `const AppSettings({this.themeMode = ThemeMode.system, this.locale, this.weekStartDay = DateTime.monday})` <a id="appsettings-new"></a>
- **Kind:** const constructor of `AppSettings`
- **Source:** `lib/shared/providers/app_settings.dart` (line 110)
- **Purpose:** Create an immutable settings value with system-following defaults.
- **Inputs:** `themeMode` (default `ThemeMode.system`); `locale` (default `null` = system);
  `weekStartDay` (default `DateTime.monday`).
- **Returns:** A new `AppSettings`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** `const AppSettings()` is the initial state passed to `AppSettingsNotifier`'s
  constructor.
- **Notes:** `weekStartDay` uses Dart's Monday=1 through Sunday=7 numbering throughout the app.

### `AppSettings copyWith({ThemeMode? themeMode, Locale? locale, int? weekStartDay, bool clearLocale = false})` <a id="copywith"></a>
- **Kind:** method of `AppSettings`
- **Source:** `lib/shared/providers/app_settings.dart` (line 121)
- **Purpose:** Create a copy of this settings value with selected fields replaced, with an explicit
  escape hatch to clear the locale back to `null`.
- **Inputs:** `themeMode`, `locale`, `weekStartDay` (all optional, fall back to current value);
  `clearLocale` (default `false`) — when `true`, forces the resulting `locale` to `null` regardless
  of the `locale` argument.
- **Returns:** A new `AppSettings`.
- **Side effects:** None.
- **Algorithm:** `locale: clearLocale ? null : (locale ?? this.locale)`; the other two fields use
  the ordinary `?? this.x` pattern.
- **Usage:** `state.copyWith(themeMode: mode)`, `state.copyWith(locale: locale, clearLocale: locale
  == null)`, `state.copyWith(weekStartDay: normalized)` — all three within this file's
  `AppSettingsNotifier` methods above.
- **Notes:** The `clearLocale` parameter exists because a plain `locale ?? this.locale` pattern can
  never represent "explicitly set locale back to null" — without it, `setLocale(null)` would be
  indistinguishable from "don't change the locale".

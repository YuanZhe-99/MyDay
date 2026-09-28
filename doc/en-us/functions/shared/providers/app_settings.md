# lib/shared/providers/app_settings.dart

Riverpod state for the app's global theme mode, locale, week-start-day preference, the four
device-local list-column preferences, and the two on-device AI switches. Feeds `MyDayApp`
(`app/app.dart`) directly and is read wherever a screen needs the configured week start day
(Todo/Weight/Intimacy calendars, `shared/utils/week_grouping.dart`) or needs to know whether
on-device AI is on (the insight cards and the Settings AI tiles). Also pushes locale changes into
`TrayService` and `ReminderService` so their user-facing text stays in sync, and pushes the AI
switches into `OnDeviceAiService`. See
[../../../architecture.md#state-management](../../../architecture.md#state-management) and
[../../../on-device-ai.md](../../../on-device-ai.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`AppSettingsNotifier` (constructor)](#appsettingsnotifier-new) | constructor (`AppSettingsNotifier`) | A | Start the notifier and load persisted settings. |
| [`AppSettingsNotifier.fixed`](#appsettingsnotifier-fixed) | named constructor (`AppSettingsNotifier`) | A | Create a notifier that starts from fixed settings without reading disk. |
| [`_loadPersisted`](#_loadpersisted) | method (`AppSettingsNotifier`) | A | Load every persisted preference into state and push it into the services. |
| [`setThemeMode`](#setthememode) | method (`AppSettingsNotifier`) | A | Update and persist the theme mode. |
| [`setLocale`](#setlocale) | method (`AppSettingsNotifier`) | A | Update and persist the locale, propagating it to tray/reminder services. |
| [`setWeekStartDay`](#setweekstartday) | method (`AppSettingsNotifier`) | A | Update and persist the first weekday for calendars/week grouping. |
| [`setTodoSectionColumns`](#settodosectioncolumns) | method (`AppSettingsNotifier`) | A | Update and persist the Todo section-column preference. |
| [`setFinanceListColumns`](#setfinancelistcolumns) | method (`AppSettingsNotifier`) | A | Update and persist the Finance transaction-column preference. |
| [`setWeightListColumns`](#setweightlistcolumns) | method (`AppSettingsNotifier`) | A | Update and persist the Weight record-column preference. |
| [`setIntimacyListColumns`](#setintimacylistcolumns) | method (`AppSettingsNotifier`) | A | Update and persist the Intimacy record-column preference. |
| [`setOnDeviceAiEnabled`](#setondeviceaienabled) | method (`AppSettingsNotifier`) | A | Turn on-device AI on or off, persisting it and switching `OnDeviceAiService`. |
| [`setOnDeviceAiPreferFast`](#setondeviceaipreferfast) | method (`AppSettingsNotifier`) | A | Prefer the faster on-device model, persisting it and re-probing the service. |
| [`AppSettings` (constructor)](#appsettings-new) | constructor (`AppSettings`) | A | Create an app settings value. |
| [`copyWith`](#copywith) | method (`AppSettings`) | A | Create a copy of this value with selected fields replaced. |
| `appSettingsProvider` | top-level variable (`StateNotifierProvider`) | B | Expose `AppSettingsNotifier` to the widget tree. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/providers/app_settings.dart` reports 14,
matching 14 of the 15 rows above exactly. The extra row is `appSettingsProvider`, the
`StateNotifierProvider` top-level variable: it has no doc block at all (undocumented, not
misattached) — a one-line `StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) =>
AppSettingsNotifier())` factory, trivial enough for Tier B, but it is the file's public entry
point. The `AppSettings` fields (`themeMode`, `locale`, `weekStartDay`, the four column fields,
`onDeviceAiEnabled`, `onDeviceAiPreferFast`) are data, not rows; the newer ones carry plain `///`
field comments without `Purpose:`.

## Documentation

### `AppSettingsNotifier() : super(const AppSettings())` <a id="appsettingsnotifier-new"></a>
- **Kind:** constructor of `AppSettingsNotifier` (extends `StateNotifier<AppSettings>`)
- **Source:** `lib/shared/providers/app_settings.dart` (line 19)
- **Purpose:** Initialize state with default settings, then start loading the persisted settings
  asynchronously.
- **Inputs:** None.
- **Returns:** A new `AppSettingsNotifier`.
- **Side effects:** Calls `_loadPersisted()` (fire-and-forget).
- **Algorithm:** Initialize `state` to `const AppSettings()` (system theme, system locale, Monday
  week start, automatic columns, on-device AI off), then invoke `_loadPersisted()` without awaiting
  it.
- **Usage:** Instantiated only by `appSettingsProvider`'s factory.
- **Notes:** Any read of `appSettingsProvider` before the async load resolves sees the compiled-in
  defaults, not the persisted values.

### `AppSettingsNotifier.fixed(super.settings)` <a id="appsettingsnotifier-fixed"></a>
- **Kind:** named constructor of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 29)
- **Purpose:** Create a notifier whose state starts as the given `AppSettings`, without reading
  anything from disk.
- **Inputs:** `settings` — the initial state, forwarded to `StateNotifier`'s constructor via a
  super parameter.
- **Returns:** A new `AppSettingsNotifier`.
- **Side effects:** None — unlike the default constructor, `_loadPersisted()` is never called, so
  neither `TodoStorage` nor `OnDeviceAiService` is touched at construction.
- **Algorithm:** Super-parameter constructor with no body.
- **Usage:**
  ```dart
  appSettingsProvider.overrideWithValue(
    AppSettingsNotifier.fixed(AppSettings(onDeviceAiEnabled: enabled)),
  ),
  ```
  (`test/ai_insight_card_ui_test.dart`, `test/ai_settings_tiles_ui_test.dart`.)
- **Notes:** Meant for tests that override `appSettingsProvider`. The setters are unchanged, so
  calling one on a fixed notifier still persists through `TodoStorage` (and the AI setters still
  switch `OnDeviceAiService.instance`).

### `Future<void> _loadPersisted()` <a id="_loadpersisted"></a>
- **Kind:** private method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 36)
- **Purpose:** Read every persisted preference from `TodoStorage` and apply it to state, then
  propagate the resolved locale to `TrayService`/`ReminderService` and the AI switches to
  `OnDeviceAiService`.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads `TodoStorage.getThemeMode()`, `getLocaleTag()`, `getWeekStartDay()`, the
  four `get...Columns()` getters, `getOnDeviceAiEnabled()` and `getOnDeviceAiPreferFast()`;
  overwrites `state`; calls `TrayService.instance.updateLocale(...)` and
  `ReminderService.instance.updateLocale(...)`; awaits `OnDeviceAiService.instance.setPreferFast(...)`
  and then `setEnabled(...)`.
- **Algorithm:**
  1. Read the nine persisted values.
  2. Map the theme string to `ThemeMode` via a `switch`: `'light'` → `ThemeMode.light`, `'dark'` →
     `ThemeMode.dark`, anything else (including `null`) → `ThemeMode.system`.
  3. Parse `localeTag` (an underscore-joined tag like `en` or `zh_TW`) into a `Locale`, splitting on
     `'_'` and using a two-part `Locale(language, country)` constructor when a country part exists.
  4. Set `state` to a new `AppSettings` with all resolved values.
  5. Resolve the effective locale (`locale ?? PlatformDispatcher.instance.locale`) and push it to
     both `TrayService.instance.updateLocale` and `ReminderService.instance.updateLocale`.
  6. Push the AI switches into `OnDeviceAiService.instance`: `setPreferFast` first, then
     `setEnabled`, so that switching on probes the platform with the model size already chosen.
- **Usage:** Called once, from the default constructor.
- **Notes:** `locale == null` in state means "follow system locale" — the effective locale passed
  to tray/reminder services always falls back to `PlatformDispatcher.instance.locale` in that case.
  When the persisted switch is off, `setEnabled(false)` is a no-op on the (already disabled)
  service, so the platform model is never queried at startup unless the user opted in.

### `void setThemeMode(ThemeMode mode)` <a id="setthememode"></a>
- **Kind:** method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 83)
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
- **Source:** `lib/shared/providers/app_settings.dart` (line 98)
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
- **Source:** `lib/shared/providers/app_settings.dart` (line 118)
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

### `const AppSettings({this.themeMode = ThemeMode.system, this.locale, this.weekStartDay = DateTime.monday, ..., this.onDeviceAiEnabled = false, this.onDeviceAiPreferFast = false})` <a id="appsettings-new"></a>
- **Kind:** const constructor of `AppSettings`
- **Source:** `lib/shared/providers/app_settings.dart` (line 220)
- **Purpose:** Create an immutable settings value with system-following defaults.
- **Inputs:** `themeMode` (default `ThemeMode.system`); `locale` (default `null` = system);
  `weekStartDay` (default `DateTime.monday`); `todoSectionColumns`, `financeListColumns`,
  `weightListColumns`, `intimacyListColumns` (each default `listColumnsAuto`);
  `onDeviceAiEnabled` and `onDeviceAiPreferFast` (each default `false`).
- **Returns:** A new `AppSettings`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** `const AppSettings()` is the initial state passed to `AppSettingsNotifier`'s
  constructor; tests pass `AppSettings(onDeviceAiEnabled: ...)` to `AppSettingsNotifier.fixed`.
- **Notes:** `weekStartDay` uses Dart's Monday=1 through Sunday=7 numbering throughout the app.
  On-device AI is off by default.

### `AppSettings copyWith({ThemeMode? themeMode, Locale? locale, int? weekStartDay, int? todoSectionColumns, int? financeListColumns, int? weightListColumns, int? intimacyListColumns, bool? onDeviceAiEnabled, bool? onDeviceAiPreferFast, bool clearLocale = false})` <a id="copywith"></a>
- **Kind:** method of `AppSettings`
- **Source:** `lib/shared/providers/app_settings.dart` (line 237)
- **Purpose:** Create a copy of this settings value with selected fields replaced, with an explicit
  escape hatch to clear the locale back to `null`.
- **Inputs:** every field as an optional parameter (each falls back to the current value);
  `clearLocale` (default `false`) — when `true`, forces the resulting `locale` to `null` regardless
  of the `locale` argument.
- **Returns:** A new `AppSettings`.
- **Side effects:** None.
- **Algorithm:** `locale: clearLocale ? null : (locale ?? this.locale)`; every other field uses the
  ordinary `?? this.x` pattern.
- **Usage:** `state.copyWith(themeMode: mode)`, `state.copyWith(locale: locale, clearLocale: locale
  == null)`, `state.copyWith(onDeviceAiEnabled: enabled)`, and the other setters — all within this
  file's `AppSettingsNotifier` methods above.
- **Notes:** The `clearLocale` parameter exists because a plain `locale ?? this.locale` pattern can
  never represent "explicitly set locale back to null" — without it, `setLocale(null)` would be
  indistinguishable from "don't change the locale".

### `void setTodoSectionColumns(int columns)` <a id="settodosectioncolumns"></a>
- **Kind:** method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 130)
- **Purpose:** Update and persist how many task sections the Todo page puts on a row.
- **Inputs:** `columns` — `listColumnsAuto` (0) or a pinned count.
- **Returns:** None.
- **Side effects:** Replaces provider state and writes `storage_config.json`.
- **Algorithm:** `state = state.copyWith(...)`, then `TodoStorage.setTodoSectionColumns(columns)`.
- **Usage:** The Todo page's app-bar `listColumnsButton` calls this from `onChanged`.
- **Notes:** The unit is a **section**, not a tile. Stored device-locally in
  `storage_config.json`, which is never synced, because window size is a property of the device
  rather than of the account — see [../../../adaptive-layout.md](../../../adaptive-layout.md). What
  is stored is the raw preference; what renders is that preference clamped to what the current
  width fits, so a choice made on a desktop survives a fold and comes back on unfolding.

### `void setFinanceListColumns(int columns)` <a id="setfinancelistcolumns"></a>
- **Kind:** method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 140)
- **Purpose:** Update and persist how many transaction tiles the Finance list puts on a row.
- **Inputs:** `columns`.
- **Returns:** None.
- **Side effects:** Replaces provider state and writes `storage_config.json`.
- **Algorithm:** As `setTodoSectionColumns`, against `financeListColumns`.
- **Usage:** The Finance page's app-bar `listColumnsButton`.
- **Notes:** Stored per surface, so the four list surfaces are independent.

### `void setWeightListColumns(int columns)` <a id="setweightlistcolumns"></a>
- **Kind:** method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 150)
- **Purpose:** Update and persist how many weight record tiles go on a row.
- **Inputs:** `columns`.
- **Returns:** None.
- **Side effects:** Replaces provider state and writes `storage_config.json`.
- **Algorithm:** As `setTodoSectionColumns`, against `weightListColumns`.
- **Usage:** The Weight page's app-bar `listColumnsButton`; the same preference also drives the
  show-all bottom sheet, which measures the screen rather than the page because it is drawn on the
  root overlay.
- **Notes:** None.

### `void setIntimacyListColumns(int columns)` <a id="setintimacylistcolumns"></a>
- **Kind:** method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 160)
- **Purpose:** Update and persist how many intimacy record tiles go on a row.
- **Inputs:** `columns`.
- **Returns:** None.
- **Side effects:** Replaces provider state and writes `storage_config.json`.
- **Algorithm:** As `setTodoSectionColumns`, against `intimacyListColumns`.
- **Usage:** The Intimacy page's app-bar `listColumnsButton` and its show-all sheet.
- **Notes:** None.

### `void setOnDeviceAiEnabled(bool enabled)` <a id="setondeviceaienabled"></a>
- **Kind:** method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 171)
- **Purpose:** Turn on-device AI (the module insight cards) on or off.
- **Inputs:** `enabled`.
- **Returns:** None.
- **Side effects:** Replaces provider state; calls `TodoStorage.setOnDeviceAiEnabled(enabled)`
  (writes `storage_config.json`) and `OnDeviceAiService.instance.setEnabled(enabled)` — both
  fire-and-forget.
- **Algorithm:** `state = state.copyWith(onDeviceAiEnabled: enabled)`, then persist, then switch
  the service.
- **Usage:** The "Use on-device AI" switch in
  [`ai_settings_tiles.dart`](../../features/ai/widgets/ai_settings_tiles.md)
  (`onChanged: notifier.setOnDeviceAiEnabled`).
- **Notes:** Off by default and device-local (never synced). Switching on makes the service
  re-probe the platform; switching off cancels the running request, fails everything queued, and
  the insight cards then render nothing. See [../../../on-device-ai.md](../../../on-device-ai.md).

### `void setOnDeviceAiPreferFast(bool enabled)` <a id="setondeviceaipreferfast"></a>
- **Kind:** method of `AppSettingsNotifier`
- **Source:** `lib/shared/providers/app_settings.dart` (line 182)
- **Purpose:** Prefer the faster on-device model where the platform serves both sizes.
- **Inputs:** `enabled`.
- **Returns:** None.
- **Side effects:** Replaces provider state; calls `TodoStorage.setOnDeviceAiPreferFast(enabled)`
  and `OnDeviceAiService.instance.setPreferFast(enabled)` (fire-and-forget), which re-probes the
  status when AI is on.
- **Algorithm:** `state = state.copyWith(onDeviceAiPreferFast: enabled)`, then persist, then
  update the service.
- **Usage:** The "prefer faster model" switch in
  [`ai_settings_tiles.dart`](../../features/ai/widgets/ai_settings_tiles.md)
  (`onChanged: notifier.setOnDeviceAiPreferFast`), shown only while AI is on, on Android, and when
  the status report offers a size choice.
- **Notes:** Only meaningful on Android (AICore serves a full and a fast model); device-local.

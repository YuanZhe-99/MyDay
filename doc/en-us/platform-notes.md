# Platform Notes

Primary source: `AGENTS.md`'s "Local HTTP API", "Notifications, Reminders, Tray, and Startup", and
"Platform Caveats" sections, cross-checked against `lib/shared/services/local_api_server.dart`
(CORS/Basic Auth/`data_unreadable` behavior confirmed by source inspection).

## Local HTTP API

`local_api_server.dart` is **desktop-only** and reads its configuration from `storage_config.json`
through `TodoStorage.readConfig()`.

- **Config keys:** `apiPort` (default `7790`), `apiListenAddress` (default `localhost`),
  `apiEnabled`, `apiUsername`, `apiPassword`.
- **Non-loopback binding without credentials is refused** with `credentials_required`.
- **Middleware:** permissive CORS (confirmed: `_corsMiddleware()` adds `_corsHeaders` to every
  response and answers `OPTIONS` preflight with `Response.ok('', headers: _corsHeaders)`), Basic
  Auth when credentials are configured (`WWW-Authenticate: Basic realm="MyDay API"` on a 401), and
  JSON error handling.
- **`data_unreadable` (HTTP 500):** Todo, Finance, and Weight handlers return
  `{"error":"data_unreadable"}` with status 500 when an existing data file cannot be parsed (the
  same typed-exception condition described in [Architecture](architecture.md)). Missing files still
  use the endpoint's documented empty-data behavior, and write endpoints abort *before* saving when
  the underlying file is unreadable.
- **Auth scope:** when API username and password are configured, Basic Auth is required for every
  non-`OPTIONS` request, including localhost requests. Without credentials configured, loopback
  requests are allowed and non-loopback requests are rejected.
- **Endpoints:**
  - `GET /ping`
  - `GET /todo/list?date=YYYY-MM-DD`
  - `GET /todo/day?date=YYYY-MM-DD` — includes day score, totals, and enriched tasks
  - `POST /todo/add` — accepts notes, reminder time, subtasks, and recurrence for one-time tasks
  - `POST /todo/complete` — accepts optional `subtaskId` and `createNextRecurrence`
  - `POST /todo/score` — accepts a -5..5 day score
  - `GET /todo/stats`
  - `GET /finance/summary` — default-currency converted income, expense, balance, total assets,
    account balances, and category totals
  - `GET /finance/accounts` — omits sensitive card fields
  - `GET /finance/categories?type=expense|income|transfer`
  - `GET /finance/transactions` — filters for pagination, type, month/date range, account, category
  - `POST /finance/add_transaction` — validates account/category ids, stores the current rate
    snapshot, supports transfer target amounts/currencies
  - `GET /finance/subscriptions` — optional `includeInactive=true`
  - `GET /weight/list` — includes body fat, optional bust/waist/hip fields, effective inherited
    measurements, notes, datetime, and modified time
  - `POST /weight/add` — accepts optional `bodyFat`, `bustCm`, `waistCm`, `hipCm`, `notes`, and an
    explicit date
  - `GET /weight/stats` — preserves legacy keys while adding BMI, waist-hip ratio, height, body fat,
    latest record, and effective measurements

Never commit real API credentials. If endpoints or payloads change, `AGENTS.md` must be updated in
the same change (per the project's maintenance rule).

## Notifications, reminders, tray, and startup

- **`ReminderService`** runs every 30 seconds while the process is alive. Subscription renewal
  transaction generation (hourly) and the daily auto-backup run on every platform; user-facing
  reminder *notifications* from this loop are desktop-only, because mobile delivers reminders
  through OS-level scheduled notifications instead (so users are never double-notified).
- **Desktop fire semantics:** a reminder fires when `now >= reminder time` and that reminder has not
  already fired today — so a busy or suspended process cannot skip its minute entirely; it just
  fires late. Fired keys are date-scoped in `_notifiedIds` and persisted to `storage_config.json`
  (`reminderNotifiedKeys`) so a desktop restart does not re-fire an already-fired reminder.
- The desktop loop skips soft-deleted daily templates and daily templates already completed today.
- **Notification backends:** desktop uses `local_notifier`; mobile uses
  `flutter_local_notifications` with timezone scheduling. The timezone location comes from the OS
  IANA zone id via `flutter_timezone`, never `DateTime.now().timeZoneName`.
- **Mobile per-task scheduling:** daily templates use daily OS schedules (shifted to start tomorrow
  when already completed today); future one-time tasks first use a one-shot start-date schedule,
  then switch to daily repeating schedules once active — see [Todo](features/todo.md).
- **Mobile subscription reminders** are per-day one-shots for the next 7 days (ids `9100+offset`);
  each day's notification body lists renewals due within 3 days of that day, and empty days are
  skipped — so renewals entering the window get announced and stale text never repeats. Schedules
  refresh on data change, hourly renewal processing (which also loads subscriptions from storage so
  the Finance page need not be open), and app resume via `refreshMobileSchedules()`.
- **Mobile weight reminders** keep their daily repeat when a record falls inside the grace window —
  the repeat is shifted to start the next day, never replaced by a one-shot. See
  [Weight](features/weight.md) for the grace-window algorithm itself.
- `SCHEDULE_EXACT_ALARM` is intentionally **not** requested; scheduling uses
  `inexactAllowWhileIdle`.
- **`TrayService`** handles the tray icon/menu, Show/Quit, minimize-to-tray, close-to-tray, and
  settings persisted through `TodoStorage`.
- **`launch_at_startup`** is configured on desktop at app start from `PackageInfo.fromPlatform()`
  and `Platform.resolvedExecutable` (see [Architecture](architecture.md) startup sequence).

## Android

- `android/app/build.gradle.kts` uses `import java.util.Properties`.
- Namespace/application id: `com.yuanzhe.my_day`.
- Java 17 source/target compatibility and core library desugaring are enabled.
- **Kotlin migration state (app side migrated):** Gradle wrapper `9.3.1`, AGP `9.1.1`; the app no
  longer applies `kotlin-android`. The Kotlin `jvmTarget` is set via a top-level
  `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }` block (not `jvmToolchain`, which
  required a real JDK 17 install; not `kotlinOptions`, which is removed).
  `android/gradle.properties` keeps the Flutter-migrator compat flags `android.builtInKotlin=false`
  and `android.newDsl=false` because several plugins still apply KGP — setting
  `builtInKotlin=true` breaks every KGP-applying plugin (verified). `org.jetbrains.kotlin.android`
  stays declared (`apply false`) in `settings.gradle.kts` so KGP-applying plugins can resolve it.
- **`file_picker` is pinned to exactly `10.3.7`**: the last release that both applies KGP itself
  (required while `builtInKotlin=false`) and compiles against `flutter.compileSdkVersion` (required
  by AGP 9 AAR metadata checks). `10.3.9`+ and `11.x` rely on AGP built-in Kotlin and fail to
  compile in compat mode; `10.3.2` and older pin `compileSdk 34` and fail the metadata check. Do not
  use a caret constraint. Its Dart API is `FilePicker.platform.*`.
- Signing reads `android/key.properties` if present and falls back to debug signing locally;
  release signing secrets are injected in CI.
- Manifest permissions include internet, notification, and boot-related entries needed by scheduled
  notifications. `SCHEDULE_EXACT_ALARM` is intentionally not declared because all scheduling uses
  inexact modes.
- CI still prints Flutter's "plugins that apply KGP" warning for `flutter_timezone`,
  `package_info_plus`, `shared_preferences_android`, `wakelock_plus`, `flutter_local_notifications`,
  and `file_picker` — plugin-side only, as of 2026-07 even their latest releases still apply KGP.
  Full elimination requires flipping `android.builtInKotlin=true` once every plugin ships Built-in
  Kotlin support.

## iOS

- `CFBundleDisplayName` and `CFBundleName` are `MyDay!!!!!`.
- iPhone supports portrait and landscape left/right; iPad also supports upside-down portrait.
- Launcher icons are generated from `assets/icon/app_icon_ios.png`,
  `assets/icon/app_icon_ios_dark.png`, and `assets/icon/app_icon_ios_tinted.png`; the default is an
  opaque white-background source, dark/tinted sources keep transparent backgrounds, and iOS falls
  back from these sources without native Icon Composer / Liquid Glass Clear assets.
- CI builds a sideload IPA without codesign; an App Store IPA requires signing/provisioning outside
  the current workflow.

## macOS

- Product name is `MyDay!!!!!` in `macos/Runner/Configs/AppInfo.xcconfig`.
- Bundle id is `com.yuanzhe.myDay`.
- Deployment target is `13.0`, required for LaunchAtLogin-Modern.
- `DebugProfile.entitlements` includes app sandbox, allow-jit, network client, and network server.
  `Release.entitlements` includes app sandbox, network client, and network server. Network client is
  required for WebDAV and the exchange-rate API; network server is required for the local API
  server.
- `MainFlutterWindow.swift` includes LaunchAtLogin integration for the startup plugin.

## Windows

- Inno Setup installer is defined in `installer.iss`.
- `AppName` is `MyDay!!!!!`; `AppVersion` is the app semantic version.
- x64 output: `build\installer\MyDay_X.Y.Z_Setup.exe`. ARM64 output:
  `build\installer\MyDay_X.Y.Z_arm64_Setup.exe`. `#ifdef ARM64` selects architecture and source path.
- `PrivilegesRequired=lowest`; do not introduce admin requirements without a clear reason.
- App icon: `windows/runner/resources/app_icon.ico`.
- MSIX config in `pubspec.yaml` uses `internetClient` and `install_certificate: false`.

## Related pages

- [Architecture](architecture.md) — the startup sequence that wires up notifications,
  launch-at-startup, the local API server, `ReminderService`, `AutoSyncService`, and the tray.
- [Settings](features/settings.md) — the Desktop settings section that exposes tray, startup, and
  local API controls.

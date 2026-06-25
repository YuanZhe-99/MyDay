# AGENTS.md

This file is the operating guide for agents working on **MyDay!!!!!**. Read it before editing anything, then read the relevant source files and the user's request carefully. The user's message is the change request: plan the work, execute it in this workspace, verify it, and keep this document current when the project changes.

## Function Explanation Layer

Handwritten source files across the project now use short English function explanations as the first reading layer for future agents. Before reading a full implementation, read the structured explanation immediately above each function, method, significant callback helper, constructor, getter, setter, or similar declaration.

Each explanation should stay concise and use this structure:

- `Purpose: <one short sentence describing what the declaration is responsible for>`
- `Inputs: <important parameters only; omit obvious ones if trivial>`
- `Returns: <what the caller receives, or None>`
- `Side effects: <state changes, file/network/database/UI effects, logging, mutation, or None>`
- `Notes: <important assumptions, edge cases, invariants, or when the declaration should be used; prefer None when there is nothing special to add>`

Maintenance rules:

- When editing an existing function or method, update its explanation in the same change.
- When adding a new function, method, significant callback helper, constructor, getter, or setter, add the explanation immediately above the declaration.
- Prefer the established `///` doc-comment style in Dart and matching line comments/doc comments in other languages when appropriate.
- Keep generated files editable only when the generated output is intentionally tracked and updated in the same change; otherwise update the source generator/input instead of hand-editing generated output.
- Use these explanations as the first-pass orientation layer, but still verify important behavior in the implementation before making changes.

## Project Snapshot

- **Name:** MyDay!!!!!, with five exclamation marks in user-facing app names, installer metadata, macOS bundle names, and notification titles.
- **Description:** A privacy-first Flutter daily life companion for Todo management, personal finance, weight tracking, an optional intimacy module, WebDAV sync, local backup, ZIP/CSV import/export, desktop tray behavior, startup launch, and a local HTTP API.
- **Package id:** Dart package `my_day`; Android namespace/application id `com.yuanzhe.my_day`; MSIX identity `com.yuanzhe.myday`; macOS bundle id `com.yuanzhe.myDay`.
- **Author / publisher:** `yuanzhe`.
- **License:** GPL-3.0.
- **Current version:** `1.0.1+45` in `pubspec.yaml`, `1.0.1.0` in `msix_config.msix_version`, and `1.0.1` in `installer.iss`.
- **Latest tag at the time this guide was written:** `v1.0.1`.
- **Framework:** Flutter with Dart SDK `^3.11.3`; CI uses Flutter `3.44.2`.
- **Primary platforms:** Windows x64/ARM64, Android APK/AAB, iOS sideload IPA, and macOS DMG. Linux project support exists for desktop runtime features but is not a primary release artifact.
- **Repository:** Use the current environment's workspace root / repository path instead of hard-coding an absolute local path.
- **Remotes:**
  - `origin` -> `<local_gitea_address>`
  - `github` -> `git@github.com:YuanZhe-99/MyDay.git`

Do not include secrets, credentials, private personal data, WebDAV credentials, local API usernames/passwords, signing keys, generated local configuration, or personal runtime data in commits or in this file. Public project metadata is OK. The real `origin` host is intentionally hidden here because the remote repository is public.

## Required Agent Workflow

1. Treat the user's message as the modification request.
2. Before making any modification, check whether the relevant remote has new commits by fetching and comparing the current branch with its upstream. If the branch is behind or has diverged, stop and resolve that situation before editing.
3. Read this `AGENTS.md`, then read the function explanations in the relevant source files as the first-pass orientation layer, then inspect the implementation details you need before editing.
4. Make a concise plan when the work is non-trivial, then implement the requested changes directly in the workspace.
5. Keep changes scoped. Do not revert unrelated user work in the tree.
6. Update `AGENTS.md` in the same change set whenever architecture, behavior, data formats, commands, release process, version locations, remotes, caveats, feature descriptions, or project history change. This document replaces the older external summary role and must stay current and complete.
7. Verify with the narrowest meaningful checks for the change. For Dart changes, prefer `flutter analyze` plus relevant `flutter test` targets.
8. When the work is complete, report briefly in both English and Chinese:
   - what changed,
   - what was verified,
   - the current/pre-change version,
   - the configured remotes,
   - whether anything could not be done.
9. For normal code changes, ask whether the user wants to push to all remotes. The user must provide or confirm the release version before a release push.

## Release, Version, Commit, Tag, and Push Flow

For ordinary feature/fix work, do not bump versions or tag until the user confirms the release version and confirms pushing.

When the user confirms the version and wants to push:

1. Update every version location:
   - `pubspec.yaml`: `version: X.Y.Z+N` where `N` is the Flutter build number and increments for releases.
   - `pubspec.yaml`: `msix_config.msix_version: X.Y.Z.0`. This intentionally brings MSIX back to the same app version family; for an app release `0.6.5`, the MSIX value should be `0.6.5.0`.
   - `installer.iss`: `AppVersion=X.Y.Z`.
   - `installer.iss`: output filenames use `{#SetupSetting("AppVersion")}` for both x64 and ARM64; keep them derived from `AppVersion`.
   - Do not manually edit in-app version display; `settings_page.dart` reads `PackageInfo.fromPlatform()`.
2. Re-run appropriate verification.
3. Commit all intended changes.
4. Create an annotated tag named `vX.Y.Z`.
5. Push the commit to both `origin` and `github`.
6. Push the tag to both `origin` and `github`.

GitHub Actions release builds are triggered by tag pushes to `github`. Tags must be pushed explicitly, either with `git push <remote> <tag>` or an intentional `--tags`.

For documentation-only maintenance that the user explicitly says does not require a release, commit and push the documentation change to the requested remotes without changing versions or creating a tag.

## Repository Structure

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
  features/
    todo/
      models/task.dart
      services/todo_storage.dart
      views/todo_page.dart
      widgets/add_task_dialog.dart
      widgets/edit_task_dialog.dart
      widgets/recurrence_picker.dart
      widgets/task_section.dart
    finance/
      models/finance.dart
      services/balance_util.dart
      services/bank_preset_service.dart
      services/exchange_rate_api.dart
      services/exchange_rate_storage.dart
      services/finance_storage.dart
      services/subscription_processor.dart
      views/
      widgets/
    intimacy/
      models/intimacy_record.dart
      services/intimacy_storage.dart
      views/intimacy_page.dart
      widgets/add_record_dialog.dart
      widgets/timer_page.dart
    weight/
      models/weight_record.dart
      services/weight_storage.dart
      views/weight_page.dart
    settings/views/
  shared/
    providers/app_settings.dart
    providers/intimacy_visibility.dart
    services/
      auto_sync_service.dart
      backup_service.dart
      image_service.dart
      import_export_service.dart
      local_api_server.dart
      mobile_notification_service.dart
      reminder_service.dart
      sync_merge.dart
      tray_service.dart
      webdav_service.dart
    utils/json_preservation.dart
    utils/week_grouping.dart
    views/
    widgets/
  l10n/
```

Primary tests currently include:

- `test/audit_fixes_test.dart` (month-end billing clamps, cross-module conflict resolution, exchange-rate/height merge rules, UTC timestamps)
- `test/balance_util_test.dart`
- `test/json_preservation_test.dart`
- `test/local_api_server_test.dart`
- `test/subscription_processor_test.dart`
- `test/widget_test.dart`

The `tool/` directory contains ad hoc generation scripts such as bank/icon generation. `tool/generate_ios_icons.dart` derives iOS default/dark/tinted icon sources and `/tmp` previews from `assets/icon/app_icon.png`; `flutter_launcher_icons.yaml` then regenerates only the iOS AppIcon set; `tool/validate_ios_icons.dart` checks iOS icon dimensions, transparency, grayscale tinted output, and `Contents.json` references. Keep release-critical behavior covered by real tests when possible.

## Core Architecture

- Startup in `lib/main.dart` initializes platform notifications, desktop launch-at-startup, the local API server, `ReminderService`, `AutoSyncService`, and desktop tray service before running `DevicePreview` -> `ProviderScope` -> `MyDayApp`.
- State management uses `flutter_riverpod`; do not introduce Provider or Bloc for normal changes.
- Navigation uses `go_router` with a `ShellRoute` and bottom `NavigationBar` routes: Todo, Finance, Weight, optional Intimacy, Settings.
- The visual system uses Material 3 via `flex_color_scheme` with `FlexScheme.indigo`.
- L10n supports English, Japanese, Simplified Chinese, and Traditional Chinese. ARB sources live in `lib/l10n/app_*.arb`; generated localization files also live under `lib/l10n/`.
- File I/O should go through `TodoStorage.getAppDir()` so custom storage paths work.
- Config I/O should use `TodoStorage.readConfig()` / `writeConfig()` to preserve keys written by other modules.
- JSON saves use `JsonPreservation` for known data files so unknown top-level and per-record fields survive local saves and WebDAV merge writes.
- Record models use `DateTime.now().toUtc()` for `modifiedAt`; settings merge timestamps use explicit `settingsModifiedAt` fields (also UTC) and are compared for LWW settings resolution. Local-time `modifiedAt` values break sync conflict detection across timezones; old data written in local time stays parse-compatible but new writes must be UTC.
- Optional null/empty fields are usually omitted from JSON using conditional map entries.
- CI passes `--dart-define=FLAVOR=full` or `store`, but there is currently no app-side flavor gate in `lib/`; do not assume store/full behavior exists unless you add and document it.

## Feature Areas

### Todo

Main model: `lib/features/todo/models/task.dart`.

- `TaskType`: `daily`, `routineOnce`, `workOnce`.
- `TaskRecurrence`: `everyNDays`, `monthlyOnDay`, `yearlyOnMonthDay`; one-time tasks can prompt for the next occurrence after completion.
- `Task`: `id`, `title`, optional `note`, optional `emoji`, `type`, completion state, optional reminder, subtasks, created/completed/scheduled/due dates, daily-template `startDate` and soft-delete `deletedDate`, optional `recurrence`, and `modifiedAt`.
- `DailyCompletionLog`: per-date completion tracking for daily tasks and daily subtasks; sync merges by union so completion on either device stays completed.
- `DailyScoreLog`: per-date whole-day score from -5 to 5 with default 0; explicit zero entries are retained so score resets sync correctly, and sync merges each date by score `modifiedAt`.

`TodoStorage` is the central storage/config hub. `storage_config.json` always stays in the default app directory and stores custom storage path, intimacy visibility, theme, locale, week start day, tray settings, backup settings, and local API settings. `todo_data.json` stores daily templates, one-time tasks, daily logs, daily scores, morning/completion reminder settings, task sort modes/custom orders, and `settingsModifiedAt`.

The Todo UI includes an inline week calendar for the selected date's week, a secondary full-month calendar page with inline year/month jumps, globally configurable week start day, monthly daily-score trend chart, joyful-day and suffering-day lists, daily/routine/work sections, calendar completion indicators, future scheduled one-time task markers, an editable whole-day score at the bottom of the Todo list, independent sort/custom drag order per section, notes, subtasks, task reminders, recurrence picker, unsaved-change protection, and `AutoSyncService.instance.notifySaved()` after saves. One-time Todo reminders start on the task's scheduled date and then repeat daily at the saved time until the task is completed.

### Finance

Main model: `lib/features/finance/models/finance.dart`.

- `AccountType`: `fund`, `credit`, `recharge`, `financial`.
- `TransactionType`: `expense`, `income`, `transfer`.
- `Account`: bank/app, account name, currency, optional card metadata, emoji/image, optional monthly-fee waiver amounts (`feeWaiverMinimumBalance` and `feeWaiverMonthlyDeposit` treated as alternative criteria when both are present), legacy forced-balance sentinel fields, `modifiedAt`. New-version balances are calculated from transactions only; setting a current balance creates an income/expense adjustment transaction and then stores `forcedBalance: 0` with `forcedBalanceDate: 1970-01-01T00:00:00.000Z` for old-version compatibility.
- `Transaction`: amount/currency, historical rate snapshot id, account ids, transfer target fields, category/subscription ids, note, date, `modifiedAt`.
- `Category`: name, `IconRef`, emoji, transaction type, `modifiedAt`. Transfer categories are supported.
- `Subscription`: trial, billing cycle/interval, amount/currency, account/category, cancellation mode, persisted `nextBillingDate`, `modifiedAt`.
- `IconRef` stores Material icon code point and font family. Because icon data is reconstructed dynamically, release builds need `--no-tree-shake-icons`.

Finance services include:

- `FinanceStorage`: stores accounts including optional monthly-fee waiver criteria, categories, transactions, subscriptions, default currency, subscription reminders/sort order, account sort modes/custom orders, transaction account picker settings, and `settingsModifiedAt`.
- `ExchangeRateStorage`: snapshot-based exchange-rate history with deduped `RateSnapshot`s and migration from old flat maps.
- `ExchangeRateApi`: fetches from `https://open.er-api.com/v6/latest/{base}` with no API key, updates only configured pairs, and fetches at most once per day.
- `balance_util.dart`: currency symbols, direct/reverse/intermediate conversion through CNY/USD/EUR, and account balance reconstruction around forced-balance anchors. `convertCurrency` falls back to 1:1 when no rate path exists and reports it through the optional `onMissingRate` callback; the finance home summary shows a warning with the affected currency pairs when any conversion fell back.
- `BankPresetService`: loads 250+ bank presets from `assets/banks.json`, country currency defaults, search/grouping, and multiple logo URL sources.
- `SubscriptionProcessor`: hourly renewal catch-up, persisted `nextBillingDate`, multi-cycle catch-up, idempotent subscription billing-day generation using existing random-id or stable-id transactions, and at-expiry cancellation handling. All billing-date advances go through `Subscription.nextBillingCursor`, which clamps month-end anchor days to the target month's length (a Jan 31 monthly subscription bills Feb 28/29, Mar 31, Apr 30, ... and never skips or drifts months; yearly Feb 29 anchors clamp in non-leap years).

Finance views cover selectable-month home summaries and grouped monthly transactions, accounts with optional monthly-fee waiver criteria, account transaction pages with direct add-transaction support, transaction account picker sorting/grouping/More settings from the account page, categories, category details, exchange rates, subscriptions, subscription details, and analysis charts. The analysis page includes clickable expense/income category breakdowns including uncategorized flows, category transaction drill-down with add/edit/delete support, expense/income trends, editable custom date ranges, and a total-assets trend that reconstructs account balances at sample points.

### Intimacy

The intimacy module is hidden by default and can be enabled from Settings. Hiding it does not delete data.

Main model: `lib/features/intimacy/models/intimacy_record.dart`.

- `Partner`: optional emoji/image, relationship start/end dates, `modifiedAt`.
- `Toy`: optional emoji/image, purchase/retired dates, purchase link, price, cost summary helpers, `modifiedAt`.
- `Position`: name, optional emoji, `modifiedAt`.
- `IntimacyRecord`: solo/partnered type, location, partner id, toy ids, position ids, pleasure level, duration, optional thrust count with x100/x1 unit, datetime, notes, orgasm/porn/condom flags, `modifiedAt`.
- `TimerHistoryEntry`: timer start, duration, optional x100/x1 thrust count, with legacy `end` migration.
- `IntimacyTimerSession`: persisted active/paused stopwatch session with original start time, last resume time, accumulated elapsed time, running flag, optional x100/x1 thrust count, and independent `timerSessionModifiedAt` for LWW sync.
- `IntimacyData`: partners, toys, positions, records, timer history, active timer session, timer retention setting, partner/toy sort modes/custom orders, and `settingsModifiedAt`.

The UI supports record list sorting/filtering, a limited default recent-history list with a show-all sheet, partner/toy/position management, default position import, partner break-up state, toy retirement state, toy management active-cost summaries, aggregate toy-cost overview for all/active/retired toys, active/all daily-cost trend charts, finalized retired toy costs, single-toy total/daily cost summaries, per-toy daily cost subtitles, exclusion of inactive partners/toys from new record pickers, EWMA/raw trend charts for pleasure/frequency and duration/thrust-count with dual axes, weekly grouping that follows the global week start day, condom tracking, and a stopwatch timer with a non-negative x100 thrust counter whose history and interrupted active/paused session are stored in `intimacy_data.json`. Stopped-and-saved timer sessions are cleared; stopped-but-unsaved and paused sessions restore as paused; running sessions resume from wall-clock time; history rows can be confirmed and restored as running sessions while removing that history row.

### Weight

Main model: `lib/features/weight/models/weight_record.dart`.

- `WeightRecord`: id, weight kg, optional body fat, optional bust/waist/hip circumference in cm, datetime, notes, `modifiedAt`.
- `WeightData`: optional height, records, reminder mode (`none`, `once`, `twice`), morning/evening reminder times, `reminderGraceMinutes` default 180, and `settingsModifiedAt`.
- BMI is computed by `WeightData.calculateBMI()`. Waist-hip ratio is computed by `WeightData.calculateWaistHipRatio()` and returns null unless waist and hip measurements are both positive.

The Weight page includes add/edit records, optional bust/waist/hip measurement entry, chart range selection, raw and EWMA weight trend display, a separate raw/EWMA bust-waist-hip trend chart, BMI/measurement/waist-hip-ratio summary cards with compact color bars, weekly grouped history that follows the global week start day, "show all" history, and reminder settings. For summary cards and measurement trend charts, missing bust/waist/hip fields inherit the previous positive value independently without writing that value back into the record. A reminder is skipped when a record exists inside the configured pre-reminder grace window.

### Settings

`settings_page.dart` provides:

- General: language, global week start day for app calendars and weekly grouping, and theme.
- Privacy: Intimacy module toggle with hide confirmation.
- Desktop: minimize-to-tray, close-to-tray, launch at startup, local API enable/status/settings, custom storage location, open data folder.
- Data: WebDAV sync, import/export, backup.
- About: app title, version from `package_info_plus`, GPL license, open source licenses, privacy policy.
- Debug: subscription processor date override in debug builds.

`privacy_policy_page.dart` contains the in-app privacy policy in all supported languages and should match `PRIVACY_POLICY.md`. `license_page.dart` displays GPLv3 license information.

## Shared Services

### WebDAV Sync

WebDAV sync is per-record three-way merge, not whole-file replacement.

Flow:

1. Download remote JSON with a discriminated result: only HTTP 404 counts as "missing on remote"; any other failure (auth/server/network) records a per-file error and skips that file, so local data is never uploaded over an unreadable remote file.
2. Load local JSON and `.sync_base/` base snapshots.
3. Merge per record using `modifiedAt` where available. Records whose serialized content is identical on both sides merge without a conflict.
4. Auto-resolve when only one side changed.
5. Detect conflicts when the same record changed on both sides after the last sync.
6. Preserve unknown JSON fields from base/local/remote.
7. Save merged local data, upload merged data, and update base snapshots. Uploads send `If-Match` with the strong ETag captured at download (first uploads send `If-None-Match: *`); HTTP 412 and any other upload failure are recorded as per-file errors and the base snapshot is not saved, so the next sync re-merges instead of silently reporting success.

Manual sync uses `autoResolve: false` and shows `SyncConflictDialog`. Auto-sync uses `autoResolve: true` and LWW per record so one conflict does not block all sync.

`finalizePendingSync` takes the mixed cross-module resolutions map as-is; each merge result picks out its own record types per conflict ID (never bulk-cast the map — that crashed on cross-module conflicts). Unresolved or mistyped entries default to the local record so conflicting records are never dropped. It returns false when any file's remote read or upload fails.

Important sync constraints:

- `_syncing` prevents concurrent sync.
- Local files are re-read before write to detect saves that happened during network I/O.
- Per-file errors are accumulated so one malformed data file does not block all files.
- Servers without ETags fall back to unconditional PUTs (previous behavior); weak ETags are never used in `If-Match`.
- `WebDAVService.consumeLocalDataChanged()` tells `AutoSyncService` to notify UI pages to reload after sync writes local files.
- Image sync is reference-gated: only images referenced in `finance_data.json` or `intimacy_data.json` are synced; orphan images are ignored.
- Individual image transfer failures are non-fatal warnings surfaced through `SyncResult.warnings`.
- When adding persisted fields or record containers, update the model, storage save path, `JsonPreservation` schema, merge function, and this guide's data inventory.

### Sync Data Reference

| File | Merge function | Merge strategy |
| --- | --- | --- |
| `todo_data.json` | `mergeTodoData()` | Daily/one-time records by id + `modifiedAt`; daily log union; daily score LWW per date; settings LWW |
| `finance_data.json` | `mergeFinanceData()` | Accounts/categories/transactions/subscriptions by id + `modifiedAt`; settings LWW |
| `exchange_rates.json` | `mergeExchangeRateJson()` | Snapshot union; newer valid current snapshot wins (a current id that does not resolve to a snapshot is ignored); newer `lastFetchedAt` wins |
| `intimacy_data.json` | `mergeIntimacyData()` | Partners/toys/positions/records by id + `modifiedAt`; timer history union by start; timer session LWW by `timerSessionModifiedAt`; settings LWW |
| `weight_data.json` | `mergeWeightData()` | Records by id + `modifiedAt`; height follows settings LWW (saving weight data bumps `settingsModifiedAt`, so clearing height syncs); reminder/settings LWW |
| `images/*` | `_syncImages()` | Additive bidirectional, but only for referenced images |

Files moved by `TodoStorage.setStoragePath()` are `todo_data.json`, `finance_data.json`, `exchange_rates.json`, `intimacy_data.json`, `weight_data.json`, and `webdav_config.json`. `storage_config.json` always stays in the default app directory. Directories such as `images/`, `backups/`, and `.sync_base/` are not moved by that file list.

### Auto-Sync

`AutoSyncService` is a singleton `WidgetsBindingObserver` with triggers aligned with MyAnime/MyDevice:

- app start: immediate sync,
- app resume: immediate sync (also refreshes mobile reminder schedules),
- data save: 30-second debounce after `notifySaved()`,
- periodic timer: every 15 minutes while the process is alive,
- saving/enabling a fully configured auto-sync WebDAV setup: immediate sync via `requestSyncNow()`.

Auto-sync silently ignores failures; users can run manual sync from the WebDAV page.

### Backup, Import, Export, and Images

- `BackupService`: manual backups, daily auto-backup, retention, module-selective restore, JSON bundle with base64 images.
- `ImportExportService`: ZIP export/import for all five data JSON files plus images; ZIP import extracts only allowlisted entries (the five data JSON files and flat files under `images/`) with the resolved output path confined to the app dir, so a crafted ZIP cannot overwrite configuration such as `webdav_config.json` or `storage_config.json`; CSV export/import for finance, intimacy, and weight.
- CSV import merges into existing data. Finance requires matching account name and can create categories; intimacy can create partners/toys and optional thrust count/unit columns; weight accepts `M/d/yyyy` and `yyyy-MM-dd` style dates.
- `ImageService`: picks local images, downloads logos/photos, stores UUID filenames under `images/`, resolves relative paths, and rejects tiny placeholder downloads.

### Local HTTP API

`local_api_server.dart` is desktop-only and reads config from `storage_config.json` through `TodoStorage.readConfig()`.

- Config keys: `apiPort` default `7790`, `apiListenAddress` default `localhost`, `apiEnabled`, `apiUsername`, `apiPassword`.
- Non-loopback binding without credentials is refused with `credentials_required`.
- Middleware: permissive CORS, Basic Auth when credentials are configured, JSON error handling.
- Endpoints:
  - `GET /ping`
  - `GET /todo/list?date=YYYY-MM-DD`
  - `GET /todo/day?date=YYYY-MM-DD` including day score, totals, and enriched tasks
  - `POST /todo/add` accepting notes, reminder time, subtasks, and recurrence for one-time tasks
  - `POST /todo/complete` accepting optional `subtaskId` and `createNextRecurrence`
  - `POST /todo/score` accepting a -5..5 day score
  - `GET /todo/stats`
  - `GET /finance/summary` returning default-currency converted income, expense, balance, total assets, account balances, and category totals
  - `GET /finance/accounts` omitting sensitive card fields
  - `GET /finance/categories?type=expense|income|transfer`
  - `GET /finance/transactions` with filters for pagination, type, month/date range, account, and category
  - `POST /finance/add_transaction` validating account/category ids, storing the current rate snapshot, and supporting transfer target amounts/currencies
  - `GET /finance/subscriptions` with optional `includeInactive=true`
  - `GET /weight/list` including body fat, optional bust/waist/hip fields, effective inherited measurements, notes, datetime, and modified time
  - `POST /weight/add` accepting optional `bodyFat`, `bustCm`, `waistCm`, `hipCm`, `notes`, and explicit date
  - `GET /weight/stats` preserving legacy keys while adding BMI, waist-hip ratio, height, body fat, latest record, and effective measurements

When API username and password are configured, Basic Auth is required for every non-OPTIONS request, including localhost requests. Without credentials, loopback requests are allowed and non-loopback requests are rejected.

Do not commit real API credentials. If endpoints or payloads change, update this guide.

### Notifications, Reminders, Tray, and Startup

- `ReminderService` runs every 30 seconds while the process is alive. Subscription renewal transaction generation (hourly) and daily auto-backup run on every platform; user-facing reminder notifications from this loop are desktop-only because mobile delivers them through OS-level scheduled notifications (no double-notify).
- Desktop reminders fire when now ≥ the reminder time and that reminder has not fired today, so a busy or suspended process cannot skip its minute. Fired keys are date-scoped in `_notifiedIds` and persisted to `storage_config.json` (`reminderNotifiedKeys`) so desktop restarts do not re-fire.
- The desktop loop skips soft-deleted daily templates and daily templates already completed today.
- Desktop notifications use `local_notifier`; mobile uses `flutter_local_notifications` with timezone scheduling. The timezone location comes from the OS IANA zone id via `flutter_timezone`, never `DateTime.now().timeZoneName`.
- Mobile per-task reminders are scheduled through OS-level notifications: daily templates are daily schedules (shifted to start tomorrow when already completed today), future one-time tasks first use a one-shot start-date schedule, and active one-time tasks use daily repeating schedules.
- Mobile subscription renewal reminders are per-day one-shots for the next 7 days (ids 9100+offset); each day's body lists renewals due within 3 days of that day and empty days are skipped, so renewals entering the window are announced and stale text never repeats. Schedules refresh on data change, hourly renewal processing (which also loads subscriptions from storage so the finance page need not be opened), and app resume via `refreshMobileSchedules()`.
- Mobile weight reminders keep their daily repeat when a record falls inside the grace window — the repeat is shifted to start the next day, never replaced by a one-shot.
- `SCHEDULE_EXACT_ALARM` is intentionally not requested; scheduling uses `inexactAllowWhileIdle`.
- `TrayService` handles tray icon/menu, Show/Quit, minimize-to-tray, close-to-tray, and settings persisted through `TodoStorage`.
- `launch_at_startup` is configured on desktop from `PackageInfo.fromPlatform()` and `Platform.resolvedExecutable`.

## Persisted Data Inventory

Default app data directory is `Documents/MyDay/` on desktop or the platform app documents directory on mobile. Desktop users can choose a custom storage path, but `storage_config.json` remains in the default app directory.

| Data | File | Synced | Notes |
| --- | --- | --- | --- |
| Core preferences | `storage_config.json` | No | Custom path, intimacy visibility, theme, locale, week start day, tray, backup, local API settings, today's fired desktop reminder keys (`reminderNotifiedKeys`) |
| Todo | `todo_data.json` | Yes | Tasks, daily templates, completion log, daily score log, reminders, task sort/custom order |
| Finance | `finance_data.json` | Yes | Accounts including optional fee waiver criteria, categories, transactions, subscriptions, finance settings, transaction account picker settings |
| Exchange rates | `exchange_rates.json` | Yes | Rate snapshots and `lastFetchedAt` |
| Intimacy | `intimacy_data.json` | Yes | Partners, toys, positions, records, timer history/session including thrust counts, sort settings |
| Weight | `weight_data.json` | Yes | Height, records including optional bust/waist/hip cm fields, reminders, grace window |
| WebDAV config | `webdav_config.json` | No | User server config and credentials; moved with custom storage path |
| Sync base | `.sync_base/*.json` | No | Last-synced snapshots for three-way merge |
| Images | `images/*` | Yes | Referenced finance/intimacy images sync; backups include images |
| Backups | `backups/backup_*.json` | No | Local recovery bundles |

## Platform Caveats

### Android

- `android/app/build.gradle.kts` uses `import java.util.Properties`.
- Namespace/application id: `com.yuanzhe.my_day`.
- Java 17 source/target compatibility and core library desugaring are enabled.
- Signing reads `android/key.properties` if present and falls back to debug signing locally.
- Release signing secrets are injected in CI.
- Manifest permissions include internet, notification, and boot-related entries needed by scheduled notifications. `SCHEDULE_EXACT_ALARM` is intentionally not declared because all scheduling uses inexact modes.

### iOS

- `CFBundleDisplayName` and `CFBundleName` are `MyDay!!!!!`.
- iPhone supports portrait and landscape left/right; iPad includes upside-down portrait too.
- iOS launcher icons are generated from `assets/icon/app_icon_ios.png`, `assets/icon/app_icon_ios_dark.png`, and `assets/icon/app_icon_ios_tinted.png`; default is an opaque white-background source, dark and tinted sources keep transparent backgrounds, and iOS falls back from these sources without native Icon Composer / Liquid Glass Clear assets.
- CI builds a sideload IPA without codesign; App Store IPA requires signing/provisioning outside the current workflow.

### macOS

- Product name is `MyDay!!!!!` in `macos/Runner/Configs/AppInfo.xcconfig`.
- Bundle id is `com.yuanzhe.myDay`.
- Deployment target is `13.0`, required for LaunchAtLogin-Modern.
- `DebugProfile.entitlements` includes app sandbox, allow-jit, network client, and network server.
- `Release.entitlements` includes app sandbox, network client, and network server.
- Network client entitlement is required for WebDAV and exchange-rate API; network server entitlement is required for the local API server.
- `MainFlutterWindow.swift` includes LaunchAtLogin integration for the startup plugin.

### Windows

- Inno Setup installer is defined in `installer.iss`.
- `AppName` is `MyDay!!!!!`; `AppVersion` is the app semantic version.
- x64 output: `build\installer\MyDay_X.Y.Z_Setup.exe`.
- ARM64 output: `build\installer\MyDay_X.Y.Z_arm64_Setup.exe`.
- `#ifdef ARM64` selects architecture and source path.
- `PrivilegesRequired=lowest`; do not introduce admin requirements without a clear reason.
- App icon: `windows/runner/resources/app_icon.ico`.
- MSIX config in `pubspec.yaml` uses `internetClient` and `install_certificate: false`.

## CI/CD

`.github/workflows/build.yml` runs on `v*` tag pushes and `workflow_dispatch`.

| Job | Runner | Output | Notes |
| --- | --- | --- | --- |
| `android` | `ubuntu-latest` | APK + AAB | Java 17, optional signing secrets, APK `FLAVOR=full`, AAB `FLAVOR=store` |
| `windows-x64` | `windows-latest` | Inno x64 installer | Stable Flutter `3.44.2`, `iscc installer.iss` |
| `windows-arm64` | `windows-11-arm` | Inno ARM64 installer | Flutter master for ARM64 engine, `iscc /DARM64 installer.iss` |
| `ios` | `macos-latest` | Sideload IPA | Release, no codesign |
| `macos` | `macos-latest` | DMG | Uses `create-dmg` |
| `release` | `ubuntu-latest` | GitHub Release | Only on tag push, collects all artifacts |

Important workflow caveats:

- Keep workflow Flutter version aligned with the Dart SDK constraint.
- All release builds use `--no-tree-shake-icons`.
- GitHub `secrets` cannot be used directly in step `if` expressions; route through job-level `env`.
- Windows x64 and ARM64 CI jobs set `CL=/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` as a temporary VS/MSVC 18 compatibility workaround while Windows plugin/WinRT dependencies still include deprecated `<experimental/coroutine>`.
- Windows ARM64 uses Flutter master because stable may not include the needed ARM64 engine.

## Useful Commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter test test/balance_util_test.dart
flutter test test/json_preservation_test.dart
flutter test test/widget_test.dart
flutter gen-l10n
dart run tool/generate_ios_icons.dart
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
dart run tool/validate_ios_icons.dart
flutter build apk --release --no-tree-shake-icons --dart-define=FLAVOR=full
flutter build appbundle --release --no-tree-shake-icons --dart-define=FLAVOR=store
flutter build windows --release --no-tree-shake-icons --dart-define=FLAVOR=full
iscc installer.iss
iscc /DARM64 installer.iss
```

Use the narrowest relevant command set for verification. For sync/model/persistence changes, include targeted tests and consider adding tests for `JsonPreservation`, merge behavior, or balance calculations.

## Version History Reference

- `v0.1.0`: Initial public release after squash; Todo, Finance, Intimacy, Weight, WebDAV sync, backup, ZIP/CSV import/export, four-language localization, GPLv3, privacy policy, CI/CD, macOS support.
- `v0.1.4`: Partner/toy dates, custom Todo emoji input, associated l10n.
- `v0.1.5`: Toy purchase link/price, GPL license page, settings polish.
- `v0.2.0`-`v0.2.3`: Broad l10n cleanup, tray/reminder locale awareness, chart date-label fixes, default solo intimacy and position management.
- `v0.3.0`: Weight chart improvements, intimacy dual-axis trend chart, installer versioning fix, BOM cleanup.
- `v0.3.1`: Weight reminders, intimacy page scroll layout, short-range chart label fixes.
- `v0.3.2`: L10n audit fixes, transfer categories, Finance AppBar restructuring, left-aligned module titles.
- `v0.4.0`: Local HTTP API server, launch at startup, desktop settings expansion, public config API, macOS network server entitlement.
- `v0.5.0`: Referenced-only image sync, sync warnings, intimacy duration trend chart, calculator keyboard for transaction amounts.
- `v0.5.1`: ARM64 installer filename fix, trend chart date overlap fix, raw + EWMA intimacy trend lines.
- `v0.6.0`: Todo recurrence for one-time tasks and frequency chart spike fix using a 7-day rolling window.
- `v0.6.1`: Optional Todo notes in model/UI/API.
- `v0.6.2`: Todo, finance account, and intimacy active/history custom sorting.
- `v0.6.3`: Todo subtask save safety/reordering and unsaved edit protection across major dialogs.
- `v0.6.4`: Weekly history grouping, weight reminder grace window, zero-value chart filtering, unknown JSON field preservation.
- `v0.6.5`: Finance monthly totals, smoother trend sampling, total-assets trend chart, forced-balance historical reconstruction, version `0.6.5+24`.
- `v0.6.6`: Finance forced balances are migrated into ordinary adjustment transactions, live balances now come only from transactions, old-version compatibility uses the `0 + 1970-01-01` forced-balance sentinel, and versions are unified to `0.6.6+25` / MSIX `0.6.6.0` / installer `0.6.6`.
- `v0.6.7`: Finance accounts can store optional monthly-fee waiver criteria for minimum balance and/or monthly incoming transfer, with versions unified to `0.6.7+26` / MSIX `0.6.7.0` / installer `0.6.7`.
- `v0.7.0`: Finance analysis custom date ranges can be re-edited without losing prior selections, at-expiry-cancelled subscriptions are excluded from upcoming-renewal reminders, finance home transactions are month-filtered with month selection, account transaction pages can add transactions with the account preselected, intimacy default history shows a limited recent list with a show-all sheet, and versions are unified to `0.7.0+27` / MSIX `0.7.0.0` / installer `0.7.0`.
- `v0.7.1`: Finance analysis category rows for expenses, income, and uncategorized flows open transaction drill-down pages with add/edit/delete support, category add flows preselect the category/type automatically, and versions are unified to `0.7.1+28` / MSIX `0.7.1.0` / installer `0.7.1`.
- `v0.7.2`: Subscription billing generation is idempotent per subscription billing day, newly generated subscription transactions use stable IDs, historical subscription import skips existing billing days, transaction account picker settings support name/custom sorting, type grouping, and More accounts from the account page, and versions are unified to `0.7.2+29` / MSIX `0.7.2.0` / installer `0.7.2`.
- `v0.7.3`: Intimacy partner and toy record detail pages support adding, editing, and deleting related records, show average pleasure and duration summaries, include filtered pleasure/duration trend charts, and versions are unified to `0.7.3+30` / MSIX `0.7.3.0` / installer `0.7.3`.
- `v0.7.4`: Intimacy records support optional thrust counts with x100/x1 units, duration charts on the main and partner/toy trend pages add a separate thrust-count axis, intimacy CSV import/export includes the new fields, and versions are unified to `0.7.4+31` / MSIX `0.7.4.0` / installer `0.7.4`.
- `v0.7.5`: Intimacy stopwatch sessions persist across accidental page/app exits, timer history entries can be confirmed and restored as running sessions, intimacy records track condom use, CSV import/export includes the condom field, and versions are unified to `0.7.5+32` / MSIX `0.7.5.0` / installer `0.7.5`.
- `v0.7.6`: Intimacy timer adds a non-negative x100 thrust counter with +100/-100 controls, timer sessions/history preserve that count for record prefill and restoration, and versions are unified to `0.7.6+33` / MSIX `0.7.6.0` / installer `0.7.6`.
- `v0.7.7`: Intimacy trend charts use higher-contrast colors for combined data series, condom-protected record tiles show affirmative status text, and versions are unified to `0.7.7+34` / MSIX `0.7.7.0` / installer `0.7.7`.
- `v0.7.8`: Weight records support optional bust/waist/hip measurements in cm, the weight trend chart adds dual-axis measurement lines with kg left and cm right, weight CSV/API flows include the new fields, and versions are unified to `0.7.8+35` / MSIX `0.7.8.0` / installer `0.7.8`.
- `v0.7.9`: Weight summary cards show latest bust/waist/hip values plus waist-hip ratio with a compact color bar, weight and body-measurement trends are split into separate raw/EWMA charts with less crowded axes, and versions are unified to `0.7.9+36` / MSIX `0.7.9.0` / installer `0.7.9`.
- `v0.7.10`: One-time Todo reminders start on the scheduled date and repeat daily until completion, future calendar dates with scheduled non-daily Todo items show a dedicated marker, and versions are unified to `0.7.10+37` / MSIX `0.7.10.0` / installer `0.7.10`.
- `v0.7.11`: Todo home shows an inline week calendar for the selected date while retaining the month picker, Todo days support a -5 to 5 daily score stored and synced per date, and versions are unified to `0.7.11+38` / MSIX `0.7.11.0` / installer `0.7.11`.
- `v0.7.12`: Todo daily-score wording now describes whole-day scoring, the month calendar opens as a secondary page with inline year/month jumps, daily-score trend chart including zero values, joyful-day and suffering-day lists, and versions are unified to `0.7.12+39` / MSIX `0.7.12.0` / installer `0.7.12`.
- `v0.7.13`: Global settings can choose which weekday starts the week, app calendars/date pickers use shared localized weekday/month labels, Todo/Intimacy calendars and Weight/Intimacy weekly grouping follow the selected start day, and versions are unified to `0.7.13+40` / MSIX `0.7.13.0` / installer `0.7.13`.
- `v0.7.14`: Mobile one-time Todo reminders no longer start before their scheduled date; future one-time tasks use one-shot start-date notifications until active, stale task notification IDs are cleared when reminders are rescheduled, and versions are unified to `0.7.14+41` / MSIX `0.7.14.0` / installer `0.7.14`.
- `v0.7.15`: Weight summary cards and body-measurement trend charts inherit missing bust/waist/hip values from the latest previous positive value per field while leaving each record's stored empty fields unchanged; iOS launcher icons add safe-area default, dark, and tinted variants; Windows CI sets a temporary VS/MSVC 18 coroutine deprecation compatibility flag; and versions are unified to `0.7.15+42` / MSIX `0.7.15.0` / installer `0.7.15`.
- `v0.8.0`: Refreshed the local HTTP API for Todo, Finance, and Weight with stricter Basic Auth, enriched task/transaction/weight payloads, day score and finance account/category endpoints, converted finance summaries, transfer-aware transaction creation, body-composition weight writes, and local API regression tests; versions are unified to `0.8.0+43` / MSIX `0.8.0.0` / installer `0.8.0`.
- `v1.0.0`: Pre-release audit hardening — WebDAV downloads distinguish 404 from errors so transient failures can never overwrite the remote or cascade into cross-device deletions, upload failures (including ETag `If-Match` 412 conflicts) surface as per-file sync errors instead of silent success, cross-module conflict resolution no longer crashes and unresolved conflicts default to the local record, all `modifiedAt`/settings timestamps are written in UTC, month-end subscription billing dates clamp instead of skipping months, the exchange-rate merge never keeps a dangling current snapshot id, weight height follows settings LWW, the in-process reminder loop is desktop-only with ≥-time due semantics and persisted per-day dedupe, mobile subscription reminders are per-day one-shots with day-accurate content, weight grace skips keep the daily repeat, deleted/completed daily templates stop reminding, IANA timezone resolution via `flutter_timezone`, 15-minute periodic auto-sync plus sync-on-config-save, allowlist-based ZIP import, missing-exchange-rate warnings on the finance summary, removed unused `SCHEDULE_EXACT_ALARM`, and versions unified to `1.0.0+44` / MSIX `1.0.0.0` / installer `1.0.0`.
- `v1.0.1`: Added intimacy toy management active-cost summaries, an aggregate toy-cost overview for all/active/retired toys with active/all daily-cost trends and finalized retired costs, single-toy total/daily cost summaries, each toy's daily cost in toy management subtitles, updated GitHub Actions stable Flutter to `3.44.2`, configured the GitHub remote locally, and versions unified to `1.0.1+45` / MSIX `1.0.1.0` / installer `1.0.1`.

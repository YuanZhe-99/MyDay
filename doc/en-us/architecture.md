# Architecture

This page covers the app shell (startup, navigation, theming), state management, localization, the
repository layout, and the core storage/concurrency rules that every feature module follows.

## Startup sequence

`lib/main.dart` is the entry point. `main()` is `async` and runs, in order, before `runApp`:

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. Platform-specific notification setup: `MobileNotificationService.instance.init()` on
   Android/iOS, or `localNotifier.setup(appName: 'MyDay!!!!!', shortcutPolicy: ShortcutPolicy.ignore)`
   on desktop.
3. On desktop (Windows/macOS/Linux, not web): `launch_at_startup` is configured using
   `PackageInfo.fromPlatform()` for the app name and `Platform.resolvedExecutable` for the path.
4. On desktop: `LocalApiServer.start()` — the local HTTP API server (desktop-only).
5. `ReminderService.instance.start()` — the global 30-second reminder loop, independent of which
   tab is active.
6. `AutoSyncService.instance.start()` — the auto-sync lifecycle observer (only syncs once the user
   has configured and enabled WebDAV).
7. On desktop: `TrayService.instance.init()` — system tray icon/menu.
8. `runApp(DevicePreview(enabled: kDebugMode, builder: (_) => const ProviderScope(child: MyDayApp())))`.

So the widget tree is `DevicePreview` → `ProviderScope` (Riverpod root) → `MyDayApp`
(`lib/app/app.dart`, a `ConsumerWidget`).

## Navigation

`lib/app/router.dart` builds a single `go_router` `GoRouter` with one `ShellRoute` wrapping a
`ShellScaffold` (`lib/shared/widgets/shell_scaffold.dart`). The shell's routes are the bottom
navigation destinations:

- `/todo` → `TodoPage`
- `/finance` → `FinancePage`
- `/weight` → `WeightPage`
- `/intimacy` → `IntimacyPage` (present in the route table even when the module is hidden by the
  user; visibility is a UI-level concern, not a routing concern)
- `/settings` → `SettingsPage`

`initialLocation` is `/todo`.

## Theming

`lib/app/theme.dart` builds both light and dark `ThemeData` via `flex_color_scheme`'s
`FlexThemeData`, both using `scheme: FlexScheme.indigo`, `useMaterial3Typography: true`, and
`useMaterial3: true`. This gives a Material 3 visual system with a single indigo seed scheme shared
across light/dark.

## State management

State management uses `flutter_riverpod` throughout (`ProviderScope` at the root, `ConsumerWidget`
for `MyDayApp`). Providers of interest include `lib/shared/providers/app_settings.dart` and
`lib/shared/providers/intimacy_visibility.dart`. New code should stay on Riverpod rather than
introducing Provider or Bloc.

## Localization

`lib/l10n/app_*.arb` holds four ARB sources — `app_en.arb`, `app_ja.arb`, `app_zh.arb` (Simplified
Chinese), and `app_zh_TW.arb` (Traditional Chinese) — covering English, Japanese, Simplified
Chinese, and Traditional Chinese. Generated localization Dart files (`flutter gen-l10n`) live
alongside them under `lib/l10n/`.

## Repository structure

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
      services/body_metrics.dart
      services/cycle_predictor.dart
      services/intimacy_storage.dart
      views/body_page.dart
      views/intimacy_page.dart
      widgets/add_record_dialog.dart
      widgets/body_section.dart
      widgets/cycle_calendar.dart
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
      sync_progress.dart
      sync_wake_lock.dart
      tray_service.dart
      webdav_service.dart
    utils/json_preservation.dart
    utils/week_grouping.dart
    views/
    widgets/
  l10n/
```

Each feature module (`todo`, `finance`, `intimacy`, `weight`) follows the same
`models/ + services/ + views/ + widgets/` shape; `settings` is view-only (it reads/writes other
modules' storage rather than owning a data file). `shared/` holds everything cross-cutting: sync,
backup, notifications/reminders, the local API server, tray/startup glue, and small pure utilities.

## Core architecture rules

- **File I/O goes through `TodoStorage`.** `TodoStorage.getAppDir()` resolves the actual storage
  directory so a user-configured custom storage path is respected everywhere. Config reads/writes
  go through `TodoStorage.readConfig()` / `writeConfig()` specifically so one module's config write
  cannot clobber keys another module previously wrote to `storage_config.json`.
- **Known JSON preserved on write.** `JsonPreservation` (`lib/shared/utils/json_preservation.dart`)
  is used when saving the known data files so that unknown top-level and per-record fields survive
  both local saves and WebDAV merge writes — this is what lets a newer app version's fields
  round-trip through an older version without being dropped.
- **Serialized, atomic writes (write-queue + tmp-then-rename).** Every module data file
  (`FinanceStorage`, `IntimacyStorage`, `WeightStorage`, `TodoStorage`'s `todo_data.json` path, and
  `ExchangeRateStorage`) serializes concurrent saves through a static write queue — e.g.
  `TodoStorage` keeps `static Future<void> _writeQueue = Future<void>.value();` and chains each save
  onto it (`lib/features/todo/services/todo_storage.dart`) — and writes atomically via a validated
  tmp-then-rename helper, `DataFileSafety.writeValidatedDataJson` (`lib/shared/services/
  data_file_safety.dart`); Finance keeps its own equivalent `_atomicWriteJson`. This prevents
  overlapping un-awaited saves (e.g. several home-page callbacks firing after a partner deletion)
  from interleaving truncate-writes and garbling the JSON file.
- **Typed storage exceptions and a blocking load-error UI pattern.** `load()` returns `null` only
  when the data file does not exist. An existing-but-unreadable file throws a typed exception —
  `FinanceStorageException` / `IntimacyStorageException` / `WeightStorageException` /
  `TodoStorageException` (`DataFileValidationException` underneath, from `data_file_safety.dart`) —
  so corrupted data is never silently treated as an empty dataset. `DataFileSafety.validateDataJson`
  parses the JSON through the real model parser for that known file name and wraps any failure in
  `DataFileValidationException`. Each home page mirrors `finance_page.dart`: it shows a blocking
  load-error view, refuses `_saveData` with a `<module>DataWriteBlocked` SnackBar while the file is
  unreadable, and recovers automatically once the file becomes readable again (the
  `AutoSyncService` reload listener re-runs `_loadData`). Read-only Todo/Weight reminder callers
  catch the exception and just skip that pass instead of crashing the reminder loop.
- **UTC `modifiedAt` + `settingsModifiedAt` for last-writer-wins.** Record models use
  `DateTime.now().toUtc()` for `modifiedAt`. Settings-level merges use an explicit
  `settingsModifiedAt` field (also UTC) compared for LWW settings resolution. Local-time
  `modifiedAt` values would break sync conflict detection across timezones; old data written in
  local time stays parse-compatible, but all new writes must be UTC. See
  [Data Formats](data-formats.md) and [WebDAV Sync](sync.md) for how these timestamps drive merges.
- **Optional fields omitted, not null-written.** Optional/empty fields are usually left out of the
  JSON map entirely via conditional map entries (`if (x != null) 'x': x`) rather than serialized as
  explicit `null`.
- **No app-side flavor gate.** CI passes `--dart-define=FLAVOR=full` or `store`, but there is
  currently no flavor-based behavior gate inside `lib/` — don't assume store/full behavior differs
  at runtime unless it is added and documented.

## Related pages

- [Data Formats](data-formats.md) for the exact fields behind each data file.
- [WebDAV Sync](sync.md) for how the write-queue/atomic-write/UTC-timestamp rules feed the merge
  and upload flow.
- [Backup & Restore](backup-restore.md) for how `DataFileSafety` validation is reused on restore.

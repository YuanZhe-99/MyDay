# Architecture

P2 uses shared navigation and measured content constraints; see [shared-ui.md](shared-ui.md).

Shared theme and adaptive foundations now come from MyApps-UI; see
[shared-ui.md](shared-ui.md) for ownership, integration and update order.

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
7. `OnDeviceAiService.instance.start()` — registers the on-device AI lifecycle listener (1.5.0). It
   calls nothing on the model; `AppSettingsNotifier` later pushes the persisted switch into the
   service, and while the switch is off the method channel is never touched. See
   [On-device AI](on-device-ai.md).
8. On desktop: `TrayService.instance.init()` — system tray icon/menu.
9. `runApp(DevicePreview(enabled: kDebugMode, builder: (_) => const ProviderScope(child: MyDayApp())))`.

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

The shell renders those destinations as a bottom `NavigationBar` on a narrow window and as a side
`NavigationRail` from 600 logical pixels of width up, built from one destination list so the two
cannot drift apart. Which one appears is a width-only decision — see
[adaptive-layout.md](adaptive-layout.md) for why that rule is deliberately not the app-wide split
rule, and for everything else the app does with a tablet's or a foldable's extra room.

## Theming

Since 1.6.0 the visual system is plain Flutter Material 3 — `flex_color_scheme` is gone. `lib/app/theme.dart` builds light and dark `ThemeData` with `ColorScheme.fromSeed` from one brand seed (`AppTheme.seedColor`, indigo `0xFF303F9F`), unless the platform supplies a dynamic (Material You) scheme: `MyDayApp` wraps `MaterialApp.router` in a `DynamicColorBuilder` and uses the dynamic scheme on **Android only**, because desktop plugins return the system accent color, which would replace the app's own seed. The user picks an **interface style** in Settings, `AppUiStyle.material3` or `AppUiStyle.expressive` (the default), stored device-locally as `uiStyle`. Material 3 is Flutter's stock theme plus outlined text fields; Expressive layers a theme-level approximation of Material 3 Expressive on top (larger corner radii, pill buttons that morph to rounded squares when pressed, bolder titles, the 2024 progress and slider designs, fade-forwards page transitions) and also selects the **compact floating pill navigation bar** (floating over the page content since 1.6.1), while Material 3 keeps the classic full-width bar (on wide windows both use the side rail, on the left or right by setting, unless Expressive opts into the bottom bar; see [adaptive-layout.md](adaptive-layout.md)). Both styles share the same colors. Semantic colors (income green, expense red) come from `StatusColors` ([functions/shared/utils/status_colors.md](functions/shared/utils/status_colors.md)), derived from the active scheme.

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
    ai/
      services/ai_insights_cache.dart
      services/genai_backend.dart
      services/insight_language.dart
      services/insight_prompts.dart
      services/insight_service.dart
      services/on_device_ai_service.dart
      services/output_validation.dart
      widgets/ai_insight_card.dart
      widgets/ai_settings_tiles.dart
    profile/                  # synced display name and avatar (1.6.0)
      models/profile_data.dart
      services/profile_merge.dart
      services/profile_store.dart
      providers/profile_provider.dart
      views/profile_avatar.dart
      views/profile_header.dart
    todo/
      models/task.dart
      services/todo_insight_facts.dart
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
      services/finance_insight_facts.dart
      services/finance_storage.dart
      services/subscription_processor.dart
      views/
      widgets/
    intimacy/
      models/intimacy_record.dart
      services/body_metrics.dart
      services/cycle_predictor.dart
      services/intimacy_insight_facts.dart
      services/intimacy_storage.dart
      utils/thrust_timeline.dart
      views/body_page.dart
      views/intimacy_page.dart
      views/record_detail_page.dart
      widgets/add_record_dialog.dart
      widgets/body_section.dart
      widgets/cycle_calendar.dart
      widgets/thrust_timeline_chart.dart
      widgets/timer_page.dart
    weight/
      models/weight_record.dart
      services/weight_insight_facts.dart
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
    utils/adaptive_layout.dart
    utils/chinese_convert.dart
    utils/chinese_convert_data.dart
    utils/json_preservation.dart
    utils/week_grouping.dart
    views/
    widgets/
  l10n/
packages/
  myapps_data/          # shared engines (git submodule)
  on_device_ai_apple/   # local plugin: Apple Foundation Models bridge (1.5.0)
```

Each feature module (`todo`, `finance`, `intimacy`, `weight`) follows the same
`models/ + services/ + views/ + widgets/` shape; `settings` is view-only (it reads/writes other
modules' storage rather than owning a data file). `ai` owns no data file either: it holds the
on-device model layer and the insight card, and each module contributes a pure
`*_insight_facts.dart` builder (see [On-device AI](on-device-ai.md)). `shared/` holds everything cross-cutting: sync,
backup, notifications/reminders, the local API server, tray/startup glue, and small pure utilities.

## Shared package (`myapps_data`)

The WebDAV sync engine, backup engine, ZIP transfer engine, atomic writers, and auto-sync scheduler
are **not in this repo**. They live in the shared `myapps_data` package, embedded at
`packages/myapps_data` as a git submodule and consumed as a pub path dependency. MyAnime, MyDay, and
MyDevice all use it, which is what keeps their wire format, backup format, and lock semantics
interoperable.

- **What stays here:** all models, the per-feature storage hubs, the per-module merge wrappers, and
  the unknown-field preservation **schemas** (which name MyDay's own fields).
- **What moved:** the transport, lock lifecycle, merge pipeline, `.sync_base` snapshots, image sync,
  backup bundle and blob store, ZIP allowlist, atomic writers, and sync scheduling.
- **The seam:** [`functions/app/data_modules.md`](functions/app/data_modules.md) declares the
  `StorageAdapter` over `TodoStorage` plus one `DataModule` per data file. It replaced four of the
  five hardcoded copies of the data-file list this app used to carry, and it is where MyDay's three
  special cases now live: the finance forced-balance migration (`postMergeTransform`), the whole-file
  exchange-rate merge, and schema-driven preservation (`preUploadTransform`).
- **The facades:** `WebDAVService`, `BackupService`, `ImportExportService`, `AutoSyncService`, and
  `DataFileSafety` keep their previous public APIs and delegate to the package. Their shapes are
  deliberately frozen so call sites and tests keep working; behavior changes belong in the package.
- **Not unified:** MyDay's daily backup stays driven by `ReminderService`'s 30-second loop, which is
  why `AutoSyncService` passes `onPeriodicTick: null`.

`.gitmodules` uses the relative URL `../MyApps-DATA.git`, so it resolves against whichever remote a
clone tracks — Gitea clones fetch from Gitea, GitHub clones from GitHub, and no host name is ever
committed. Fresh clones need `git clone --recurse-submodules` or `git submodule update --init`.

## Core architecture rules

- **File I/O goes through `TodoStorage`.** `TodoStorage.getAppDir()` resolves the actual storage
  directory so a user-configured custom storage path is respected everywhere. Config reads/writes
  go through `TodoStorage.readConfig()` / `writeConfig()` specifically so one module's config write
  cannot clobber keys another module previously wrote to `storage_config.json`. Since v1.5.2
  `writeConfig` takes only the keys being changed, every config read-merge-write runs through one
  serial config queue and is written atomically, and a write refuses to build on an existing file
  that does not parse (throwing `TodoStorageException`) instead of replacing it with a near-empty map.
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
  from interleaving truncate-writes and garbling the JSON file. Since v1.5.2 the Finance and
  Intimacy home pages also run their own loads, saves and sub-page commits through a per-page serial
  I/O queue, and sub-page list edits are merged by id onto a fresh read of the file (see
  [`id_list_delta.dart`](functions/shared/utils/id_list_delta.md)) rather than written as a stale
  whole list over changes made meanwhile by a renewal, the local API, or a sync.
- **Typed storage exceptions and a blocking load-error UI pattern.** `load()` returns `null` only
  when the data file does not exist. An existing-but-unreadable file throws a typed exception —
  `FinanceStorageException` / `IntimacyStorageException` / `WeightStorageException` /
  `TodoStorageException` (`DataFileValidationException` underneath, from `data_file_safety.dart`) —
  so corrupted data is never silently treated as an empty dataset. Since v1.5.2
  `exchange_rates.json` follows the same rule with `ExchangeRateStorageException` instead of
  falling back to default rates. `DataFileSafety.validateDataJson`
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
- **One flavor gate, in one file.** `lib/app/build_flavor.dart` is the only place `lib/` reads the
  distribution flavor: `isStoreBuild` is true when the platform flavor (`appFlavor`, Android
  `--flavor store`) or the dart-define (`--dart-define=FLAVOR=store`) says `store`. It currently
  gates exactly one behavior — bundled bank logos (`bundledBankLogosEnabled`, read by
  `BankPreset.bundledLogoAsset`); Full and Store builds otherwise behave identically. Android builds
  pass `--flavor full|store` (real product flavors in `android/app/build.gradle.kts`); Windows has
  no `--flavor` and relies on the dart-define alone; iOS and macOS pass `FLAVOR=full`. The flag only
  changes lookups — keeping the logo bytes out of the Store package is the CI strip step
  (`tool/strip_bank_logos.dart`, see [CI/CD](ci-cd.md)), not the flag. New Store-only behavior must
  read `isStoreBuild` from that file and be documented here. See
  [`build_flavor.dart`](functions/app/build_flavor.md).
- **On-device AI is a gate, and its cache is device-local (1.5.0).** Nothing calls the model while
  the Settings switch is off, and on platforms without a model the insight cards are never built.
  Generated insights live only in `ai_insights.json`, which is not a registered data module (never
  synced, backed up or exported) and, unlike data files, reads as empty when unreadable because it
  is rebuildable. Only app-computed facts reach the model — never notes. See
  [On-device AI](on-device-ai.md).

## Related pages

- [Data Formats](data-formats.md) for the exact fields behind each data file.
- [WebDAV Sync](sync.md) for how the write-queue/atomic-write/UTC-timestamp rules feed the merge
  and upload flow.
- [Backup & Restore](backup-restore.md) for how `DataFileSafety` validation is reused on restore.

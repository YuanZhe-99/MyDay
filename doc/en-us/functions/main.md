# lib/main.dart

Application entry point. This file wires up every process-wide singleton service before the
Flutter widget tree exists, then hands off to `MyDayApp` (`app/app.dart`). See
[../architecture.md#startup-sequence](../architecture.md#startup-sequence) for the full ordered
boot sequence and how it maps to `AutoSyncService`, `ReminderService`, `TrayService`, and
`LocalApiServer`. The on-device AI lifecycle hook started here is described in
[../on-device-ai.md](../on-device-ai.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`main`](#main) | top-level function | A | Initialize startup services and launch the app entry point. |

`grep -c 'Purpose:' lib/main.dart` reports 1, matching the single real declaration in this file
(there is exactly one function, `main()`, and its doc block is correctly attached directly above
it — no misattachment or undocumented declarations found).

## Documentation

### `void main() async` <a id="main"></a>
- **Kind:** top-level function (entry point)
- **Source:** `lib/main.dart` (line 24)
- **Purpose:** Perform platform-specific startup wiring (notifications, launch-at-startup, local
  API server, reminder loop, auto-sync, on-device AI lifecycle tracking, tray icon) and then run
  the widget tree.
- **Inputs:** None (implicit `Platform`/`kIsWeb` checks read the current runtime environment).
- **Returns:** None — this is the process entry point.
- **Side effects:** Calls `WidgetsFlutterBinding.ensureInitialized()`; on Android/iOS initializes
  `MobileNotificationService`; on desktop calls `localNotifier.setup(...)`, configures
  `launch_at_startup`, and starts `LocalApiServer`; starts `ReminderService.instance`,
  `AutoSyncService.instance`, and `OnDeviceAiService.instance` (which only registers its
  app-lifecycle listener); on Windows/macOS/Linux initializes `TrayService.instance`; finally
  calls `runApp(...)`.
- **Algorithm:**
  1. Ensure Flutter bindings are initialized before any plugin call.
  2. Branch on platform: mobile gets `MobileNotificationService.instance.init()`; everything else
     (including web, implicitly skipped by the `else` only running on non-web desktop targets)
     falls through to `localNotifier.setup(appName: 'MyDay!!!!!', shortcutPolicy: ShortcutPolicy.ignore)`.
  3. On non-web Windows/macOS/Linux, read `PackageInfo.fromPlatform()` and call
     `launchAtStartup.setup(appName: ..., appPath: Platform.resolvedExecutable)`.
  4. On the same desktop platform set, await `LocalApiServer.start()` (a no-op unless the user has
     enabled the local API in settings).
  5. Start `ReminderService.instance` unconditionally (it internally decides desktop vs. mobile
     notification behavior).
  6. Start `AutoSyncService.instance` unconditionally (it only actually syncs once WebDAV is
     configured and enabled).
  7. Start `OnDeviceAiService.instance` unconditionally
     ([`on_device_ai_service.dart`](features/ai/services/on_device_ai_service.md)): this only
     registers an `AppLifecycleListener` that pauses and resumes its request queue; it never
     touches the platform model while the user's "Use on-device AI" switch is off.
  8. On desktop, await `TrayService.instance.init()`.
  9. Call `runApp` wrapping `MyDayApp` in `DevicePreview` (enabled only in `kDebugMode`) and a
     Riverpod `ProviderScope`.
- **Usage:** Not called from application code — invoked once by the Flutter/Dart launcher.
- **Notes:** The two desktop platform checks are duplicated (`Platform.isWindows || Platform.isMacOS
  || Platform.isLinux`, one of them also excluding `kIsWeb`) rather than factored into a shared
  helper; keep both in sync if a new desktop platform is added. Order matters: `TrayService.init()`
  runs after `ReminderService`/`AutoSyncService`/`OnDeviceAiService` start, but before the widget tree is built.

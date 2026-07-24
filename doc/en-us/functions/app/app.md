# lib/app/app.dart

Defines `MyDayApp`, the single root widget returned by `main()`'s `runApp` call. It wires
`MaterialApp.router` to the app's theme (`app/theme.dart`), router (`app/router.dart`),
localization delegates, and the `appSettingsProvider` Riverpod state. See
[../../architecture.md#startup-sequence](../../architecture.md#startup-sequence) and
[../../architecture.md#state-management](../../architecture.md#state-management).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `MyDayApp` (constructor) | constructor (`MyDayApp`) | B | Create a `MyDayApp` instance. |
| `build` | method (`MyDayApp`, `ConsumerWidget`) | B | Build the `MaterialApp.router` widget tree from current settings. |

`grep -c 'Purpose:' lib/app/app.dart` reports 2, matching both real declarations in this file (the
constructor and `build`) — no misattachment or undocumented declarations found.

## Documentation

Both declarations in this file are Tier B (a trivial `const` widget constructor and a `build()`
method), so per the template they are index-only rows with no full entry. Notable behavior for
context: `build()` reads `ref.watch(appSettingsProvider)` and feeds `settings.themeMode` and
`settings.locale` into `MaterialApp.router`, so a theme or locale change from Settings triggers a
rebuild of the whole app shell. `theme`/`darkTheme` come from `AppTheme.light`/`AppTheme.dark`
(see [theme.md](theme.md)), and `routerConfig` comes from `appRouter` (see [router.md](router.md)).
`builder: DevicePreview.appBuilder` wraps the app for the `device_preview` package used in debug
builds.

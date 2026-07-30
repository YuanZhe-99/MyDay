# lib/app/router.dart

Defines the single `go_router` `GoRouter` instance used by `MyDayApp` (`app/app.dart`). See
[../../architecture.md#navigation](../../architecture.md#navigation) for how this maps to the
bottom navigation bar in `ShellScaffold`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`appRouter`](#approuter) | top-level variable (`GoRouter`) | A | Configure the app's shell route and the five bottom-navigation destinations. |

`grep -c 'Purpose:' lib/app/router.dart` reports 0 — this file has no `/// Purpose:` doc comment
at all, but it does contain one real declaration: the top-level `final appRouter = GoRouter(...)`
configuration object. This is an undocumented-but-real declaration per the verification rule, not
a misattachment; it is listed here as Tier A because it encodes the app's actual routing structure
(five real routes plus the shell wrapper), not a trivial one-line forwarder.

**Reconciliation:** `grep -c 'Purpose:' lib/app/router.dart` reports 0, while the table has 1 row. `appRouter` is a top-level `GoRouter` variable initialized from a collection literal and carries no `/// Purpose:` block, but it is a real declaration and the file's entire public surface, so it is listed.

## Documentation

### `final appRouter = GoRouter(...)` <a id="approuter"></a>
- **Kind:** top-level variable (`GoRouter` instance)
- **Source:** `lib/app/router.dart` (line 10)
- **Purpose:** Build the app's single `GoRouter` with a `ShellRoute` that wraps every screen in
  `ShellScaffold` and provides the bottom-navigation destinations.
- **Inputs:** None — the route table is a static literal built at file load time.
- **Returns:** A `GoRouter` value consumed by `MaterialApp.router(routerConfig: appRouter)` in
  `app/app.dart`.
- **Side effects:** None beyond constructing the router object graph.
- **Algorithm:**
  1. Set `initialLocation: '/todo'`.
  2. Declare one `ShellRoute` whose `builder` wraps the routed `child` widget in `ShellScaffold`.
  3. Under that shell, declare five `GoRoute`s with no path parameters: `/todo` → `TodoPage`,
     `/finance` → `FinancePage`, `/weight` → `WeightPage`, `/intimacy` → `IntimacyPage`,
     `/settings` → `SettingsPage`.
- **Usage:**
  ```dart
  return MaterialApp.router(
    // ...
    routerConfig: appRouter,
  );
  ```
  (`lib/app/app.dart`, inside `MyDayApp.build`.)
- **Notes:** `/intimacy` is always present in the route table even when the intimacy module is
  hidden from Settings — visibility is enforced by `ShellScaffold` filtering which destinations it
  shows (see `shared/widgets/shell_scaffold.dart`), not by removing the route. There is no
  redirect/guard logic on this router; any code that can obtain a `BuildContext` can `context.go(
  '/intimacy')` regardless of the visibility toggle.

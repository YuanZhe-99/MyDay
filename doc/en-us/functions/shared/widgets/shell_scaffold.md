# lib/shared/widgets/shell_scaffold.dart

The `ShellRoute` wrapper (`ShellScaffold`) that every routed page renders inside — see
[../../../architecture.md#navigation](../../../architecture.md#navigation). It owns the bottom
`NavigationBar`, filters the Intimacy destination in/out based on
`intimacyVisibilityProvider` (see
[../providers/intimacy_visibility.md](../providers/intimacy_visibility.md)), and wires
`ReminderService`'s snackbar callback to the current `BuildContext` for as long as the shell is
mounted.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ShellScaffold` (constructor) | constructor (`ShellScaffold`) | B | Create a shell scaffold instance. |
| `createState` | method (`ShellScaffold`) | B | Create the mutable state object for this widget. |
| [`_activeRoutes`](#_activeroutes) | method (`_ShellScaffoldState`) | A | Return the bottom-nav route list for the current visibility flag. |
| [`_currentIndex`](#_currentindex) | method (`_ShellScaffoldState`) | A | Find the selected bottom-nav index for the current route. |
| `initState` | method (`_ShellScaffoldState`) | B | Wire the reminder snackbar callback. |
| `dispose` | method (`_ShellScaffoldState`) | B | Unwire the reminder snackbar callback. |
| `_showReminderSnackbar` | method (`_ShellScaffoldState`) | B | Show a reminder notification as an in-app snackbar. |
| `build` | method (`_ShellScaffoldState`) | B | Build the scaffold body and bottom navigation bar. |

`grep -c 'Purpose:' lib/shared/widgets/shell_scaffold.dart` reports 8, matching all eight real
declarations in this file. No misattachment or undocumented declarations found.

## Documentation

### `List<String> _activeRoutes(bool visible)` <a id="_activeroutes"></a>
- **Kind:** private method of `_ShellScaffoldState`
- **Source:** `lib/shared/widgets/shell_scaffold.dart` (line 37)
- **Purpose:** Return the ordered list of bottom-nav routes for the current intimacy-visibility
  flag.
- **Inputs:** `visible` — the current `intimacyVisibilityProvider` value.
- **Returns:** `List<String>` — either the 5-route list (with `/intimacy`) or the 4-route list
  (without it).
- **Side effects:** None.
- **Algorithm:** `visible ? _routes : _routesHidden`, where `_routes = ['/todo', '/finance',
  '/weight', '/intimacy', '/settings']` and `_routesHidden` is the same list without `/intimacy`.
- **Usage:** Called from both `_currentIndex` and `build` so the index computation and the
  rendered destinations always agree on the same route list.
- **Notes:** The route order here must match the order `NavigationDestination` widgets are built
  in `build()` — both are manually kept in sync (there is no single shared source beyond these two
  static lists).

### `int _currentIndex(BuildContext context, bool visible)` <a id="_currentindex"></a>
- **Kind:** private method of `_ShellScaffoldState`
- **Source:** `lib/shared/widgets/shell_scaffold.dart` (line 44)
- **Purpose:** Determine which bottom-nav destination should be highlighted as selected for the
  current router location.
- **Inputs:** `context` (to read `GoRouterState.of(context).uri.path`); `visible`.
- **Returns:** `int` — the matching index into `_activeRoutes(visible)`, or `0` if nothing matches.
- **Side effects:** None.
- **Algorithm:**
  1. Read the current location path from `GoRouterState.of(context).uri.path`.
  2. Get the active route list for `visible`.
  3. Iterate the list; return the index of the first route the location `startsWith`.
  4. Return `0` if no route matched.
- **Usage:** Called from `build()` as `selectedIndex: _currentIndex(context, visible)`.
- **Notes:** Uses `startsWith`, not exact equality, so any sub-route nested under e.g. `/todo/...`
  in the future would still highlight the Todo tab. The fallback to `0` means an unmatched location
  silently highlights Todo rather than showing no selection.

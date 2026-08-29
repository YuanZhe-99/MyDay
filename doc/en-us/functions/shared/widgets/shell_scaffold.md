# lib/shared/widgets/shell_scaffold.dart

The `ShellRoute` wrapper (`ShellScaffold`) that every routed page renders inside — see
[../../../architecture.md#navigation](../../../architecture.md#navigation). It owns the shell's
navigation, rendering one destination list either as a bottom `NavigationBar` or as a side
`NavigationRail` depending on `useNavigationRail` (see
[../utils/adaptive_layout.md#usenavigationrail](../utils/adaptive_layout.md#usenavigationrail)),
filters the Intimacy destination in/out based on `intimacyVisibilityProvider` (see
[../providers/intimacy_visibility.md](../providers/intimacy_visibility.md)), and wires
`ReminderService`'s snackbar callback to the current `BuildContext` for as long as the shell is
mounted.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ShellScaffold` (constructor) | constructor (`ShellScaffold`) | B | Create a shell scaffold instance. |
| `createState` | method (`ShellScaffold`) | B | Create the mutable state object for this widget. |
| [`_activeRoutes`](#_activeroutes) | method (`_ShellScaffoldState`) | A | Return the route list for the current visibility flag. |
| [`_destinations`](#_destinations) | method (`_ShellScaffoldState`) | A | Describe the shell's destinations once, icons and labels included. |
| [`_currentIndex`](#_currentindex) | method (`_ShellScaffoldState`) | A | Find the selected navigation index for the current route. |
| `initState` | method (`_ShellScaffoldState`) | B | Wire the reminder snackbar callback. |
| `dispose` | method (`_ShellScaffoldState`) | B | Unwire the reminder snackbar callback. |
| `_showReminderSnackbar` | method (`_ShellScaffoldState`) | B | Show a reminder notification as an in-app snackbar. |
| [`build`](#build) | method (`_ShellScaffoldState`) | A | Build the scaffold body and either navigation surface. |
| `_ShellDestination` (constructor) | constructor (`_ShellDestination`) | B | Create a shell destination instance. |

`grep -c 'Purpose:' lib/shared/widgets/shell_scaffold.dart` reports 10, matching all ten real
declarations in this file. No misattachment or undocumented declarations found. `build` was
promoted to Tier A in v1.4.0, when it stopped being a single `Scaffold` and became the app's one
navigation-mode decision.

## Documentation

### `List<String> _activeRoutes(bool visible)` <a id="_activeroutes"></a>
- **Kind:** private method of `_ShellScaffoldState`
- **Source:** `lib/shared/widgets/shell_scaffold.dart` (line 44)
- **Purpose:** Return the ordered list of shell routes for the current intimacy-visibility flag.
- **Inputs:** `visible` — the current `intimacyVisibilityProvider` value.
- **Returns:** `List<String>` — either the 5-route list (with `/intimacy`) or the 4-route list
  (without it).
- **Side effects:** None.
- **Algorithm:** `visible ? _routes : _routesHidden`, where `_routes = ['/todo', '/finance',
  '/weight', '/intimacy', '/settings']` and `_routesHidden` is the same list without `/intimacy`.
- **Usage:** Called from both `_currentIndex` and `build` so the index computation and the
  destination selection always agree on the same route list.
- **Notes:** The route order here must match the order `_destinations` builds its entries in — both
  are filtered on the same `visible` flag, and both put `/intimacy` fourth.

### `List<_ShellDestination> _destinations(AppLocalizations l10n, bool visible)` <a id="_destinations"></a>
- **Kind:** private method of `_ShellScaffoldState`
- **Source:** `lib/shared/widgets/shell_scaffold.dart` (line 54)
- **Purpose:** Describe every shell destination once — outline icon, selected icon, localized label
  — in the same order as `_activeRoutes`.
- **Inputs:** `l10n`; `visible`.
- **Returns:** `List<_ShellDestination>` of 5 entries, or 4 when `visible` is false.
- **Side effects:** None.
- **Algorithm:** A list literal of five `_ShellDestination` values — Todo, Finance, Weight,
  Intimacy, Settings — with the Intimacy entry behind a collection `if (visible)`.
- **Usage:** Called once from `build`; the returned list feeds both the `NavigationBar` and the
  `NavigationRail` branch.
- **Notes:** This exists so a destination can never end up in one navigation surface and not the
  other, or in a different order between them. Before v1.4.0 the destinations were written inline
  in the single `NavigationBar`; with two renderings of the same list, a shared source is what
  keeps them from drifting. The visibility filter lives here alone, so the rail inherits it for
  free.

### `int _currentIndex(BuildContext context, bool visible)` <a id="_currentindex"></a>
- **Kind:** private method of `_ShellScaffoldState`
- **Source:** `lib/shared/widgets/shell_scaffold.dart` (line 90)
- **Purpose:** Determine which destination should be highlighted as selected for the current router
  location.
- **Inputs:** `context` (to read `GoRouterState.of(context).uri.path`); `visible`.
- **Returns:** `int` — the matching index into `_activeRoutes(visible)`, or `0` if nothing matches.
- **Side effects:** None.
- **Algorithm:**
  1. Read the current location path from `GoRouterState.of(context).uri.path`.
  2. Get the active route list for `visible`.
  3. Iterate the list; return the index of the first route the location `startsWith`.
  4. Return `0` if no route matched.
- **Usage:** Called once in `build()`; the result is passed as `selectedIndex` to whichever
  navigation surface is rendered.
- **Notes:** Uses `startsWith`, not exact equality, so any sub-route nested under e.g. `/todo/...`
  in the future would still highlight the Todo tab. The fallback to `0` means an unmatched location
  silently highlights Todo rather than showing no selection.

### `Widget build(BuildContext context)` <a id="build"></a>
- **Kind:** method of `_ShellScaffoldState`
- **Source:** `lib/shared/widgets/shell_scaffold.dart` (line 159)
- **Purpose:** Build the shell — the routed child plus either a bottom navigation bar or a side
  navigation rail.
- **Inputs:** `context`.
- **Returns:** A `Scaffold`.
- **Side effects:** Creates UI widgets; `select` calls `context.go` when a destination is tapped.
- **Algorithm:**
  1. Read `l10n`, watch `intimacyVisibilityProvider`, and resolve `routes`, `destinations` and
     `index` from the single `visible` flag.
  2. Define `select(i) => context.go(routes[i])`.
  3. If `!useNavigationRail(MediaQuery.sizeOf(context).width)`: return a `Scaffold` whose body is
     the routed child and whose `bottomNavigationBar` is a `NavigationBar` built from
     `destinations`.
  4. Otherwise return a `Scaffold` whose body is a `Row` of: a `NavigationRail` built from the same
     `destinations`, a `VerticalDivider(width: 1)`, and `Expanded(child: widget.child)`.
- **Usage:** Invoked by Flutter; the shell is built by `ShellRoute` in `lib/app/router.dart` (see
  [../../app/router.md](../../app/router.md)).
- **Notes:** Which surface appears is `useNavigationRail`'s **width-only** decision, deliberately
  not the app-wide split rule — see
  [../../../adaptive-layout.md](../../../adaptive-layout.md) for why a rail is not a split. Nothing
  here is stateful beyond the reminder callback, so folding a device swaps one surface for the
  other on the next frame with no route change and no state loss. Two details in the rail branch
  earn their place: `groupAlignment: 0` centres the destinations, because the default top alignment
  is for rails sitting under a leading menu button or FAB and this one has neither; and the
  `LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox(minHeight:)` + `IntrinsicHeight`
  wrapper lets the rail scroll rather than overflow, because a rail can appear at compact heights
  (a phone in landscape is 915 x 412, and five labelled destinations run to roughly 370 logical
  pixels).

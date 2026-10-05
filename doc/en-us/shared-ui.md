# Shared UI foundations

MyApps-UI `v0.1.1` is embedded at `packages/myapps_ui`, using relative submodule
URL `../MyApps-UI.git`. Initialize submodules recursively after cloning.
The two path dependencies are under that checkout's `packages/` directory.

`lib/app/theme.dart` preserves the public facade and indigo seed, delegating to
`MyAppsTheme`. Shared style and navigation enums retain existing stored names.
Dynamic-color platform policy stays in the application root.

`lib/shared/utils/adaptive_layout.dart` re-exports common split, navigation and
list constants and four pure helpers from `myapps_adaptive`: `canSplitLayout`,
`useNavigationRail`, `columnCapacity`, `listRowCount`. Todo section distribution,
finance, weight and intimacy constraints and navigation padding stay app-owned.


## Updating

Publish the library to both remotes before committing an app pointer update.
Pin a tagged commit and run analysis and the full app tests. Shared implementation
documentation belongs in the library; application docs cover integration and differences.

## P2 navigation and actual space

The application now delegates navigation rendering to `MyAppsNavigationShell`.
App-side shells retain routes, destination filtering, selection persistence and reminder
callbacks. Each page passes `context` to its width and bottom-inset helpers: measured
shell content width is used once, and full-window routes subtract no rail. The legacy
context-free helper remains for callers that explicitly request the old calculation.
The stable content slot preserves page state across resize, style and rail-side changes.
MyVidComp retains classic navigation, extended rails and review badges.

Profile extraction remains P3; data formats are unchanged.

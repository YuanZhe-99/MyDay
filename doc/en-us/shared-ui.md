# Shared UI foundations

MyApps-UI `v0.1.0` is embedded at `packages/myapps_ui`, using relative submodule
URL `../MyApps-UI.git`. Initialize submodules recursively after cloning.
The two path dependencies are under that checkout's `packages/` directory.

`lib/app/theme.dart` preserves the public facade and indigo seed, delegating to
`MyAppsTheme`. Shared style and navigation enums retain existing stored names.
Dynamic-color platform policy stays in the application root.

`lib/shared/utils/adaptive_layout.dart` re-exports common split, navigation and
list constants and four pure helpers from `myapps_adaptive`: `canSplitLayout`,
`useNavigationRail`, `columnCapacity`, `listRowCount`. Todo section distribution,
finance, weight and intimacy constraints and navigation padding stay app-owned.
The original width-only content-width prediction is deliberately unchanged.

No settings, profile, sync or backup format changes. Shared navigation widgets
and actual navigation-space measurement are planned for the next stage.

## Updating

Publish the library to both remotes before committing an app pointer update.
Pin a tagged commit and run analysis and the full app tests. Shared implementation
documentation belongs in the library; application docs cover integration and differences.

# Shared UI foundations

MyApps-UI v0.1.7 keeps navigation choices horizontal in compact settings panes
using centered two-line labels before vertical fallback. Selection checks default off.

DATA v1.0.5 owns WebDAV connection and operation controls; AI v0.4.3 owns common
preference widgets. Application callbacks retain persistence and domain policy.

Appearance settings use MyApps-UI v0.1.6 full-width inline segment rows for theme,
interface style, navigation placement and rail side. Labels and persistence stay
here. MyApps-DATA v1.0.4 owns common data action tiles and backup preferences;
MyApps-AI v0.4.2 owns common AI presentation. Business settings stay app-owned.

## P5 region policies and attribution

MyApps-UI v0.1.5 provides automatic/selected column resolution and designed panes.
List preferences remain app-owned and capacity-clamped. Settings uses MyAppsPaneBody
with its existing gate and width policy. LicensePage explicitly names all three
consumed packages, source URL and GNU GPL v3. Business page designs remain app-owned.

## Settings and common catalogs

The app pins MyApps-UI v0.1.4 and uses shared settings sections with its original
heading spacing. Dialog pickers and provider callbacks remain app-owned. Common
appearance/navigation ARB values are maintained in the library and checked by
shared_l10n_test. App-specific text and runtime delegates stay here. The extraction
is complete; library concept docs replace the completed roadmap.

MyApps-UI `v0.1.2` is embedded at `packages/myapps_ui`, using relative submodule
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

Profile extraction is complete in P3; data formats are unchanged.

## P3 profile and avatar

The five profile-bearing apps consume `myapps_profile`. Profile model, merge,
image processing, repository, avatar rendering, editor and header view are shared.
App ProfileStore supplies active storage root, atomic writer and sync notification;
image-service resolution/deletion remains injected. Existing imports are re-export
shims. App Riverpod providers, data-module registry, picker and localized edit dialog
remain adapters. JSON, module order, image naming and field-merge behavior are unchanged.

## Unified AI settings

The app pins MyApps-UI v0.1.8, MyApps-DATA v1.1.0 and MyApps-AI v0.5.3. AI settings use MyAppsAiSettingsSkeleton, MyAppsAiSourcePicker and shared model management. Existing enabled and fast-model settings keep their serialized keys. Local CPU inference is available beyond the system-AI platform gate. WebDAV operations require this device’s notice acknowledgement.

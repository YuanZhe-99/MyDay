# lib/app/theme.dart

Defines `AppTheme`, a static-only namespace producing the app's light and dark `ThemeData` via the
`flex_color_scheme` package. Consumed directly by `MyDayApp` (`app/app.dart`). See
[../../architecture.md#theming](../../architecture.md#theming).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AppTheme._()` | constructor (`AppTheme`) | B | Prevent direct instantiation of the theme namespace. |
| [`light`](#light) | getter (`AppTheme`) | A | Build the app's light `ThemeData`. |
| [`dark`](#dark) | getter (`AppTheme`) | A | Build the app's dark `ThemeData`. |

`grep -c 'Purpose:' lib/app/theme.dart` reports 3, matching all three real declarations in this
file (the private constructor and the two static getters) — no misattachment or undocumented
declarations found.

## Documentation

### `static ThemeData get light` <a id="light"></a>
- **Kind:** static getter of `AppTheme`
- **Source:** `lib/app/theme.dart` (line 17)
- **Purpose:** Produce the Material 3 light theme used across the whole app.
- **Inputs:** None.
- **Returns:** A `ThemeData` built by `FlexThemeData.light`.
- **Side effects:** None — pure construction of an immutable `ThemeData`.
- **Algorithm:** Calls `FlexThemeData.light` with `scheme: FlexScheme.indigo`,
  `surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold`, `blendLevel: 7`, and a
  `FlexSubThemesData` configuring `blendOnLevel: 10`, `useMaterial3Typography: true`,
  `useM2StyleDividerInM3: true`, outline-style input decorators, and navigation-bar labels shown
  only for the selected destination; `useMaterial3: true`.
- **Usage:**
  ```dart
  theme: AppTheme.light,
  ```
  (`lib/app/app.dart`, `MyDayApp.build`.)
- **Notes:** `blendLevel` (7) is lower than the dark variant's `blendLevel` (13) and
  `blendOnLevel` (10 vs. 20) — this is a deliberate, smaller surface tint for the light theme.
  Both themes share the same `FlexScheme.indigo` seed so light/dark stay visually consistent.

### `static ThemeData get dark` <a id="dark"></a>
- **Kind:** static getter of `AppTheme`
- **Source:** `lib/app/theme.dart` (line 37)
- **Purpose:** Produce the Material 3 dark theme used across the whole app.
- **Inputs:** None.
- **Returns:** A `ThemeData` built by `FlexThemeData.dark`.
- **Side effects:** None — pure construction of an immutable `ThemeData`.
- **Algorithm:** Calls `FlexThemeData.dark` with `scheme: FlexScheme.indigo`,
  `surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold`, `blendLevel: 13`, and a
  `FlexSubThemesData` configuring `blendOnLevel: 20`, `useMaterial3Typography: true`,
  `useM2StyleDividerInM3: true`, outline-style input decorators, and navigation-bar labels shown
  only for the selected destination; `useMaterial3: true`.
- **Usage:**
  ```dart
  darkTheme: AppTheme.dark,
  ```
  (`lib/app/app.dart`, `MyDayApp.build`.)
- **Notes:** See `light` above for the blend-level contrast between the two variants.

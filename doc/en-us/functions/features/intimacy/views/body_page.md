# lib/features/intimacy/views/body_page.dart

`BodySettingsPage` is the full-page wrapper opened from the intimacy manage menu's **Body** entry
(see [Intimacy](../../../../features/intimacy.md#the-body-layer-v124)) that hosts the shared
`BodySectionView` (`lib/features/intimacy/widgets/body_section.dart`) in **user mode**. All of the
actual body-profile/bra-size/cycle logic lives in `BodySectionView` and the services it calls
(`services/body_metrics.dart`, `services/cycle_predictor.dart` — see
[Body Metrics](../../../../algorithms/body-metrics.md)); this file only owns a thin local copy of
`userBody`/`cycleRecords` so the page can rebuild immediately on edit, and forwards every change
back up to its two callbacks so the caller (the intimacy manage view) can persist it. The user's
stable calendar color always comes from `cyclePersonColor(personId: null, ...)`, defined in
`widgets/cycle_calendar.dart` and documented on [that page](../widgets/cycle_calendar.md), which
returns palette slot 0 for `personId: null`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `BodySettingsPage` (constructor) | constructor (`BodySettingsPage`) | B | Create a body settings page instance from the current user body profile, cycle records, and change callbacks. |
| `BodySettingsPage.createState` | method (`BodySettingsPage`) | B | Create the mutable `_BodySettingsPageState`. |
| `_BodySettingsPageState.initState` | method (`_BodySettingsPageState`) | B | Copy `widget.userBody`/`widget.cycleRecords` into local state so edits can rebuild this page directly. |
| `_BodySettingsPageState.build` | method (`_BodySettingsPageState`) | B | Render the scaffold and the single `BodySectionView` in user mode, wiring its two change callbacks. |

`grep -c 'Purpose:' lib/features/intimacy/views/body_page.dart` reports 4, matching all 4 real
declarations counted above exactly (0 Tier A, 4 Tier B). Every `/// Purpose:` block sits directly
above the real declaration it documents — no misattached blocks and no undocumented declarations
were found. The file has no other functions, methods, getters, or setters; the two classes'
fields (`userBody`, `cycleRecords`, the two callbacks on `BodySettingsPage`; `_userBody`,
`_cycleRecords` on `_BodySettingsPageState`) are plain data holders, not counted as declarations.

## Documentation

No Tier A declarations in this file. All four declarations are a simple forwarding constructor,
`createState()`, a trivial `initState()` that copies two constructor values into mutable state, and
a `build()` method that is pure widget composition — delegating both the body-profile logic and the
cycle-calendar rendering to `BodySectionView`/`CycleCalendar` rather than reimplementing anything
here. Notably, `build()`'s two `onProfileChanged`/`onCycleRecordsChanged` callbacks each guard on
`mounted` before calling `setState` (falling back to a bare field assignment when unmounted) before
forwarding the new value to `widget.onUserBodyChanged`/`widget.onCycleRecordsChanged` — this is
routine defensive-`setState` handling, not distinct algorithmic logic worth a separate entry.

## Related pages

- [Intimacy](../../../../features/intimacy.md#the-body-layer-v124) — the Body layer this page opens
  into, including the partner-mode `Records | Body` tabs that reuse the same `BodySectionView`.
- [Body Metrics](../../../../algorithms/body-metrics.md) — bra-size estimation, PSI, and cycle
  prediction, all called from `BodySectionView`, not from this file.
- [`cycle_calendar.dart`](../widgets/cycle_calendar.md) — `cyclePersonColor` (used here for the
  user's slot-0 color) and the calendar/legend widgets `BodySectionView` renders for cycle tracking.

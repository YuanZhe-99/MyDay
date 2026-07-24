# Intimacy

Model source: `lib/features/intimacy/models/intimacy_record.dart`. Services:
`lib/features/intimacy/services/{body_metrics,cycle_predictor,intimacy_storage}.dart`. Views:
`views/body_page.dart`, `views/intimacy_page.dart`. See
[Data Formats](../data-formats.md#intimacy--intimacy_datajson) for the full field list and
[Body Metrics](../algorithms/body-metrics.md) for the bra-size/PSI/cycle-prediction algorithms.

## Hidden by default

The intimacy module is **hidden by default** and can be enabled from Settings → Privacy. Hiding it
does **not** delete data — it is purely a visibility toggle (`lib/shared/providers/
intimacy_visibility.dart`), and the `/intimacy` route still exists in the router regardless of
visibility state (see [Architecture](../architecture.md#navigation)).

## Models

- **`Partner`**: optional emoji/image, relationship start/end dates, optional `body`
  (`BodyProfile`), `modifiedAt`. The body profile travels **atomically** with the partner record in
  sync — body edits go through `Partner.copyWith`, which bumps the partner's own `modifiedAt`.
- **`BodyProfile`**: gender-neutral, all-optional — bust/waist/hip cm (partners only; the user's own
  live in the Weight module), underbust cm, a bra-sizing standard code (`eu`/`fr_es`/`jp`/`uk`/
  `us`/`au_nz`), `cycleEnabled` and `showCycleOnCalendar` flags (both default **off**), and erect
  length / base circumference / front circumference cm for the PSI reference index. Empty profiles
  serialize as entirely absent (no `{}` written).
- **`CycleRecord`**: one menstrual period start date — `id`, optional `personId` (`null` = the user,
  otherwise a partner id), a local calendar `date` (`yyyy-MM-dd`, no time), `modifiedAt`. Add/delete
  only, merged per id so deletions sync (see
  [Three-Way Merge](../algorithms/three-way-merge.md#deletionunion-semantics)).
- **`Toy`**: optional emoji/image, purchase/retired dates, purchase link, price, cost-summary
  helpers, `modifiedAt`.
- **`Position`**: name, optional emoji, `modifiedAt`.
- **`IntimacyRecord`**: solo/partnered type, location, partner id, toy ids, position ids, pleasure
  level, duration, optional thrust count with an x100/x1 unit, datetime, notes, orgasm/porn/condom
  flags, `modifiedAt`.
- **`TimerHistoryEntry`**: timer start, duration, optional x100/x1 thrust count, with legacy `end`
  migration (older entries stored an `end` timestamp instead of a duration).
- **`IntimacyTimerSession`**: a persisted active/paused stopwatch session with the original start
  time, last resume time, accumulated elapsed time, running flag, optional x100/x1 thrust count, and
  its own independent `timerSessionModifiedAt` for LWW sync.
- **`IntimacyData`**: partners, toys, positions, records, timer history, the active timer session,
  the user's `userBody` profile with its own `userBodyModifiedAt` LWW timestamp (same pattern as the
  timer session), `cycleRecords` for the user and partners, the timer retention setting, partner/toy
  sort modes/custom orders, and `settingsModifiedAt`.

## UI

The UI supports record list sorting/filtering, a limited default recent-history list with a
show-all sheet, partner/toy/position management, default position import, partner break-up state,
toy retirement state, toy-management active-cost summaries, an aggregate toy-cost overview for
all/active/retired toys, active/all daily-cost trend charts, finalized retired-toy costs, single-toy
total/daily cost summaries, per-toy daily-cost subtitles, exclusion of inactive partners/toys from
new-record pickers, EWMA/raw trend charts for pleasure/frequency and duration/thrust-count with dual
axes, weekly grouping that follows the global week-start-day setting, condom tracking, and a
stopwatch timer with a non-negative thrust counter whose history and interrupted active/paused
session are stored in `intimacy_data.json`.

## Timer/stopwatch session persistence

Timer controls include **+100, +50, +10, and -100**. Counts divisible by 100 are stored as `x100`
estimates; non-100-multiple counts are stored as exact `x1` values (`thrustCountUnit` on
`IntimacyRecord`/`TimerHistoryEntry`/`IntimacyTimerSession` is always normalized to exactly `1` or
`100` — any other stored value is coerced to `100` on read). The timer has a remembered local-only
keep-screen-awake switch backed by `storage_config.json` and `wakelock_plus`; it is **not** synced.

Session recovery behavior:

- Stopped-and-saved timer sessions are cleared.
- Stopped-but-unsaved and paused sessions restore as **paused**.
- Running sessions **resume from wall-clock time** — `IntimacyTimerSession.elapsedAt(now)` computes
  `accumulated + (now - startedAt)` while running, so the elapsed time reflects real wall-clock time
  even after an app restart, not a stale in-memory counter.
- History rows can be confirmed and restored as running sessions, which removes that history row.

## Deleted-partner handling

Deleting a partner also deletes that partner's **cycle records**, but intentionally **retains**
historical activity (`IntimacyRecord`) rows with their now-dangling `partnerId`. Record tiles and
the edit dialog tolerate that deleted-partner reference, and saving an untouched edit preserves the
stored id rather than dropping or reassigning it. This is the same "don't destroy history for a
transient UI convenience" principle applied elsewhere in the app (e.g. forced-balance transactions
in Finance).

## The Body layer (v1.2.4)

Gender-neutral, fully optional, with auto-save everywhere:

- The manage menu has a fourth **Body** entry opening `views/body_page.dart`
  (`BodySettingsPage`), which hosts the shared `widgets/body_section.dart` (`BodySectionView`) in
  user mode. Partner detail pages render **Records | Body** tabs; the Records tab is the
  pre-existing summary/trend/list content, and the Body tab is the same shared widget in partner
  mode. Toy detail pages never get a body tab. Marking a partner as separated (break-up action, or
  newly setting an end date) automatically turns off that partner's show-cycle-on-home-calendar
  option; the user may manually re-enable it afterward.
- **User bust/waist/hip** each independently show their most recent positive value from Weight
  records (`WeightData.effectiveMeasurementsUpTo`). Editing them first shows a warning that changes
  sync to the Weight module and create a new weight record, with a "do not remind me again"
  checkbox (opt-out key: `intimacyBodyWeightSyncWarningDisabled` in `storage_config.json`, mirrored
  by a switch at the bottom of the Body page). A confirmed editing burst debounces into exactly
  **one** new `WeightRecord` (reusing the latest weight, or 0 when none exists, plus the displayed
  bust/waist/hip); historical weight records are never modified. Partner measurements live on
  `Partner.body` and never touch the Weight module.
- All body interfaces show a read-only waist-to-hip ratio
  (`WeightData.calculateWaistHipRatio`) whenever the displayed waist and hip are both positive.
- **Bra-size estimation** (`services/body_metrics.dart`) and the **PSI reference index** are
  covered in depth in [Body Metrics](../algorithms/body-metrics.md).
- **Cycle tracking** (`services/cycle_predictor.dart`) is **off by default**
  (`BodyProfile.cycleEnabled = false`) and covered in depth in
  [Body Metrics](../algorithms/body-metrics.md#cycle-prediction). `widgets/cycle_calendar.dart`
  renders per-person indicator bars/dots (solid menses, semi-opaque fertile window, faint phases, an
  ovulation dot, filled = actual / hollow = predicted start markers), a legend, and the mandatory
  not-contraception/not-medical disclaimer.
- The **home calendar** overlays cycles for every person whose `showCycleOnCalendar` is enabled
  (user + partners, disabled by default), one thin indicator row per person (capped at 3) under the
  day number with stable palette colors (user = slot 0, partners by sorted id), a legend, and a
  per-person selected-day strip.

## Related pages

- [Data Formats](../data-formats.md) — exact JSON shape of every model above.
- [Body Metrics](../algorithms/body-metrics.md) — bra-size estimation, PSI, and cycle prediction in
  full detail.
- [Three-Way Merge](../algorithms/three-way-merge.md) — cycle-record union/deletion semantics.
- [Weight](weight.md) — where the user's own bust/waist/hip measurements actually live.

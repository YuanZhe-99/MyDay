# Intimacy

Model source: `lib/features/intimacy/models/intimacy_record.dart`. Services:
`lib/features/intimacy/services/{body_metrics,cycle_predictor,intimacy_storage}.dart`. Utilities:
`utils/thrust_timeline.dart`. Views: `views/body_page.dart`, `views/intimacy_page.dart`,
`views/record_detail_page.dart`. See
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
  level, duration, optional thrust count with an x100/x1 unit, optional thrust timeline (v1.5.5),
  datetime, notes, orgasm/porn/condom flags, `modifiedAt`.
- **`TimerHistoryEntry`**: timer start, duration, optional x100/x1 thrust count, optional thrust
  timeline (v1.5.5), with legacy `end` migration (older entries stored an `end` timestamp instead of
  a duration).
- **`IntimacyTimerSession`**: a persisted active/paused stopwatch session with the original start
  time, last resume time, accumulated elapsed time, running flag, optional x100/x1 thrust count,
  optional thrust timeline (v1.5.5), and its own independent `timerSessionModifiedAt` for LWW sync.
- **`ThrustTimeline`** (v1.5.5, `utils/thrust_timeline.dart`): the timer's thrust-counter presses
  in order, each an elapsed time in milliseconds and a positive count; its total is the session's
  repetition count. Not a stored record of its own — it rides inside the three models above.
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
new-record pickers, the consolidated trend chart described below, weekly grouping that follows the
global week-start-day setting, condom tracking, a stopwatch timer with a non-negative thrust
counter whose history and interrupted active/paused session are stored in `intimacy_data.json`,
and (since v1.5.5) a record detail page with a thrust timeline chart, described below.

Partner and toy detail pages show a summary card with average pleasure, average duration, and
average thrust rate; toy pages add total and daily cost.

**Sub-page saves merge by id (v1.5.2).** Partner, toy and position management and the body
settings page report whole edited lists (partners, toys, positions, records, cycle records) back to
the home page. Those reports are no longer written as-is: `_commitSubPage` turns each one into an
`IdListDelta` of only the records the sub-page added, changed or removed (see
[`id_list_delta.dart`](../functions/shared/utils/id_list_delta.md)), re-reads `intimacy_data.json`
inside the page's serial I/O queue, replays the delta onto it through `IntimacyData.copyWith`, and
saves. Records added elsewhere while a management page was open — a sync, the timer page — are
therefore kept, and renaming a partner no longer drops records written in the meantime. Settings
callbacks (sort modes, user body, chart settings) still save the page's state. Loads, saves and
commits run one at a time through that queue, and a commit is refused while the file is unreadable.

## The consolidated trend chart (v1.3.2)

`IntimacyTrendChart` (`lib/features/intimacy/widgets/intimacy_trend_chart.dart`) is the module's
single record-metric chart. It replaced four separate charts — pleasure+frequency and
duration+thrust-count on the home page, plus near-verbatim copies of both on the partner/toy detail
pages — and the same widget now serves every surface. The toy daily-cost trend on the toy-cost
overview page is deliberately *not* part of it: it plots money over a projected date timeline on a
log scale with its own all/active/retired scope selector.

Five selectable metrics:

| Metric | Id | Unit | Notes |
|---|---|---|---|
| Pleasure | `pleasure` | 1-5 | Themed primary color |
| Frequency | `frequency` | records/week | Derived from the gaps between records, not from any one record |
| Duration | `duration` | minutes | |
| Thrust count | `thrustCount` | repetitions | `thrustCount * thrustCountUnit` |
| **Thrust rate** | `thrustRate` | thrusts/minute | The average rate within each entry; only entries with **both** a duration and a thrust count contribute |

Each metric draws twice: a thin solid line for the raw per-record values and a dashed line for an
EWMA-smoothed curve whose smoothing factor adapts to the real gap between records
(`alpha = 1 - exp(-dt/tau)`). Smoothing warms up over *all* records but only emits points inside the
selected range, so changing the range never changes a curve's shape.

Because the metrics have incompatible scales, the plot area is a unitless 0-1 space: every selected
metric is normalized against its own snapped ceiling. The first two selected metrics (in the order
of the table above) own the labelled left and right axes, drawn in real units in the series' own
color; any further metrics are drawn without an axis and read from the tooltip. Selected metric
chips double as the legend, so there is no separate legend row. The chart refuses to clear the last
selected metric, so it never renders empty.

The metric selection and the time range are persisted and synced as `chartSettings` in
`intimacy_data.json` — see [Data Formats](../data-formats.md#intimacy--intimacy_datajson). One
selection is shared by every surface: the home page owns the write (it bumps `settingsModifiedAt`
in UTC and saves), and the detail pages report changes back up through the same callback chain the
record and sort callbacks already use.

## Timer/stopwatch session persistence

Timer controls include **+100, +50, +10, and -100**. Counts divisible by 100 are stored as `x100`
estimates; non-100-multiple counts are stored as exact `x1` values (`thrustCountUnit` on
`IntimacyRecord`/`TimerHistoryEntry`/`IntimacyTimerSession` is always normalized to exactly `1` or
`100` — any other stored value is coerced to `100` on read). The timer has a remembered local-only
keep-screen-awake switch backed by `storage_config.json` and `wakelock_plus`; it is **not** synced.

**Thrust timeline (v1.5.5).** Every `+100`/`+50`/`+10` press is stamped with the stopwatch's
elapsed time and kept, in order, as the session's `thrustTimeline`; the counter shown is the
timeline's total, so the count and the curve can never disagree. **`-100` is an undo**: it removes
the latest presses until exactly 100 is gone, and when the last press it reaches is larger than
what is left to remove, it trims that press instead of removing it (`+50, +10, +50` minus 100
leaves one `+10` at the first press's time). Below 100 it clears the count, as before; the button
is disabled at zero and its tooltip explains the undo. The timeline is persisted with the timer
session on every press, copied into the history entry and into the saved record, and synced with
them. Sessions and history rows saved before v1.5.5 have only a total, which is restored as one
press at the restore point — the count is unchanged and no curve is drawn. If a stored timeline's
total disagrees with the stored count (an older build changed the count), the count wins and the
timeline is re-seeded the same way.

**Exact durations (v1.5.5).** A timer save, and an edit of any record, now keeps the duration to
the second. The record dialog shows hours and minutes; as long as neither field is changed, the
exact prefilled or existing duration is saved. Changing either falls back to whole minutes, as a
typed duration always was. Before v1.5.5 every save truncated to whole minutes. Likewise the
dialog keeps the timeline only while the entered count still equals the timeline's total.

**Layout (v1.5.5).** Stacked (phones, a folded phone's outer screen), the stopwatch and the session
history share one scroll view: the stopwatch keeps its natural height and a long history scrolls
below it. Previously the history took its full height first and squeezed the stopwatch's
controls into whatever was left. Below 400 dp of width the digits drop from `displayLarge` to
`displayMedium`. The two-pane layout is unchanged. See
[Adaptive layout](../adaptive-layout.md#adoption-status).

Session recovery behavior:

- Stopped-and-saved timer sessions are cleared.
- Stopped-but-unsaved and paused sessions restore as **paused**.
- Running sessions **resume from wall-clock time** — `IntimacyTimerSession.elapsedAt(now)` computes
  `accumulated + (now - startedAt)` while running, so the elapsed time reflects real wall-clock time
  even after an app restart, not a stale in-memory counter.
- History rows can be confirmed and restored as running sessions, which removes that history row.
  The restored session keeps the row's press timeline.

## Thrust timeline chart

A record saved from the timer with at least two presses, whose total still matches its count,
shows a chart on its [record detail page](#record-detail-page) (`widgets/thrust_timeline_chart.dart`): minutes of
stopwatch time on the x axis, cumulative repetitions on the y axis.

- **Step line** — the raw cumulative count, faint and solid: flat between presses, a jump at each
  one, extended to the end of the session.
- **Fit line** — dashed and curved, a **moving average** of the step line: the count is resampled
  at 60 evenly spaced times and each sample is averaged with its neighbours over a window of 10% of
  the session (edge windows are truncated), with the ends pinned to 0 and the total. A moving
  average of a non-decreasing series never decreases, so the fit line never dips, and overshoot
  prevention keeps the drawn curve from bulging below it.
- The legend names both lines; the tooltip reads the raw count only.

Records with fewer than two presses — typed-in counts, a single press, pre-1.5.5 timer sessions —
show no chart.

## Record detail page

Tapping a record tile on the home page or on a partner/toy detail page opens a read-only detail
page (v1.5.5, `views/record_detail_page.dart`): the partner (or solo) with the date and pleasure
stars, the duration as `HH:MM:SS`, the thrust count and rate, the thrust timeline chart when there
is one, toys, positions, the orgasm/porn/condom flags, and the location and notes. Edit and delete
are app-bar actions that run the calling page's own edit dialog and delete path; an edit shows in
place, a delete asks for confirmation and closes the page. Swipe-to-edit and swipe-to-delete on the
record list are unchanged. The page is width-capped at the reading width and never splits.

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

## AI insight card (1.5.0)

With on-device AI on (Android, iOS/macOS 26+), an insight card follows the trend chart (in the left
pane of the split layout). It is added to the chart blocks only while AI is on, so the pane's
divider and spacing are unchanged otherwise, and the page itself stays unreachable while the module
is hidden. Its *Trend* section compares the last 30 days with the 30 before, describes the trend
chart exactly as the user has set it up (the selected metrics over the selected range, first half
against second half; since 1.5.3), and gives one gentle suggestion. Its *Partners & toys* section
(since 1.5.3) sums up per-partner statistics over the last 90 days (entries, average rating, climax
and protection rates, days since the last entry), how many partners and toys are on record and
active, and how often toys and positions were used. Its *Body condition* section summarizes the
user's measurements (bust/waist/hip from Weight, underbust, estimated bra size) and, when the user
tracks their own cycle, today's estimated phase and the days to the next estimated start, followed
by the "statistical estimate, not medical advice" disclaimer. The facts are built by
`buildIntimacyInsightFacts` (`services/intimacy_insight_facts.dart`) and are statistics only.
Since 1.5.3 thrust count and rate and the porn-watched share are included. **Partners, toys and
positions are never named: they appear only as `partner A`, `toy 1`, `position 1`, ranked by
use. Notes, locations, names, emoji, images, prices, links, genital measurements and partners'
cycles are never sent.** Because the chart selection is part of the facts, changing a chart chip
regenerates the card. Since 1.5.4, if the model declines these facts or answers nothing usable, the card retries once with the v1.5.2 prompt, which carries no chart, partner, toy, position, thrust or porn facts, before it says *declined*. To read the Weight measurements the page loads `weight_data.json` while AI is on; an
unreadable weight file only leaves those facts out. See [On-device AI](../on-device-ai.md).

## Related pages

- [Data Formats](../data-formats.md) — exact JSON shape of every model above.
- [Body Metrics](../algorithms/body-metrics.md) — bra-size estimation, PSI, and cycle prediction in
  full detail.
- [Three-Way Merge](../algorithms/three-way-merge.md) — cycle-record union/deletion semantics.
- [Weight](weight.md) — where the user's own bust/waist/hip measurements actually live.

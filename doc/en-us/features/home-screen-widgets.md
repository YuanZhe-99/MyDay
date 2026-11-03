# Home-Screen Widgets

MyDay!!!!! has five home-screen widget kinds on Android and iOS (since 1.8.3): **Todo**, **Weight**,
**Finance**, **Private** (the Intimacy module) and **Timer** (the Intimacy stopwatch). The desktop
builds have no widget surface. All of them are built on the shared MyApps-Widget library
(`packages/myapps_widget`, see its `doc/en-us/`), the same one MyAnime uses: the app computes a
small snapshot per kind, the native widget only renders it, and taps on interactive controls are
queued for the app to apply.

| Kind | Android providers | iOS widget (families) | Default privacy |
|---|---|---|---|
| `myday.todo` | `TodoWidgetProvider` (2×2, resizable to 4×4), `TodoStripWidgetProvider` (2×1) | `MyDayTodoWidget` (small, medium, large, `accessoryRectangular`) | `normal` |
| `myday.weight` | `WeightWidgetProvider` (2×2), `WeightStripWidgetProvider` (2×1) | `MyDayWeightWidget` (small) | `sensitive` |
| `myday.finance` | `FinanceWidgetProvider` (2×2, wide layout from 250 dp) | `MyDayFinanceWidget` (small, medium) | `sensitive` |
| `myday.intimacy` | `IntimacyWidgetProvider` (2×2) | `MyDayIntimacyWidget` (small) | `sensitive` |
| `myday.timer` | `TimerWidgetProvider` (2×2), `TimerStripWidgetProvider` (2×1) | `MyDayTimerWidget` (small) | `sensitive` |

Android providers live in `android/app/src/main/kotlin/com/yuanzhe/my_day/widget/`; the iOS
extension is the `MyDayWidgets` target in `ios/MyDayWidgets/`. Only the Todo kind offers a
lock-screen family, because the shared rules forbid lock-screen families for kinds whose default
privacy is not `normal`.

## What they show

**Todo.** The header shows the date and a *New* button. The 2×2 size shows the number of open
tasks, a progress bar and up to three rows; 4×2 shows two columns of rows plus tomorrow's scheduled
tasks and the day score; 4×4 shows up to ten rows. Rows are sorted the way the day reads: overdue
first, then open tasks by reminder time (tasks without a time last; ties keep the daily → routine →
work section order), then completed tasks, which stay visible struck through. Each row has a
checkbox. The 2×1 strip and the iOS lock-screen rectangle show the open count and the next task with
a reminder time.

**Weight.** The latest weight, the change over 30 days, BMI when a height is set, a sparkline of
the last 30 days, and the time of the latest record. When no record exists today and the morning
reminder time has passed (reminder mode not `none`), the footer says *Not logged today*. The strip
shows the latest weight and the change since the previous record.

**Finance.** This month's expense, income and balance in the default currency (the same totals as
the Finance home summary), and up to three subscriptions billing within 7 days. The wide layout adds
the top expense category and its share.

**Private.** Days since the last record, this month's count and average duration, and — when the
user's own cycle tracking is enabled — the days until the next predicted period. The title is the
neutral word *Private* rather than the module name.

**Timer.** The stopwatch state of the Intimacy timer: running (the elapsed time counts up natively,
`Chronometer` on Android and `Text(_:style: .timer)` on iOS), paused, or idle with the last
session. Buttons: *Start* / *Pause* / *Resume*, **+100** (adds 100 to the count, recorded as one
thrust-timeline event at that moment), and *Finish*, which opens the timer page to save a record.

Every kind shows a *New* / *Log* / *Add* button that opens the app on the matching add dialog.
Tapping elsewhere opens the module's tab.

### Platform differences

| Topic | Android | iOS |
|---|---|---|
| Add button | Every size | Medium and large only; `systemSmall` supports no `Link`, so a small widget opens the tab |
| Todo 4×2 / medium | Right column from 250 dp: tomorrow's scheduled tasks and the day score | Right column continues the rows, then tomorrow; counts and score under the header |
| Todo strip / lock screen | Next open task timed at or after now (else the first timed, else the first open), then "time · N left" | Next timed open task, else the first open task |
| Timer strip | Play/pause tile, clock, status and count, **+100**; no *Finish* (a tap opens the timer page) | — (small only); the whole widget opens the timer page, which is how *Finish* works there |
| Finance after the month changes | Last snapshot's totals with its month name; the top category only for the current month | *Open MyDay to update* until the app runs |
| Weight, Finance sizes | Bills show one row, or three from 220 dp tall | Small and medium families |

The timer's *Last* line fills its `{n}` with a short local date of the last session (or uses the
*today* wording). Under *Hide values* the stopwatch is drawn as `••:••` and does not count, and the
weight sparkline and the Todo progress bar are blank.

### Privacy and the module switch

**Settings › Home-screen widgets** (Android and iOS only) has one section per kind with a text
size slider (90%–150%), a privacy choice and a preview:

| Choice | Stored | Envelope `privacy` | Effect |
|---|---|---|---|
| Show | `show` | the kind's default | Values shown; on iOS, `sensitive` kinds are redacted while the device is locked |
| Hide values | `maskValues` | `sensitive` | Numbers and amounts drawn as `••`, titles kept |
| Icon only | `iconOnly` | `hidden` | A neutral placeholder with the app icon |

The defaults are *Show* for every kind except **Private**, which defaults to *Hide values*.

The Private and Timer kinds exist only while the Intimacy module is visible (Settings › Privacy).
Hiding the module clears both envelopes, so a placed widget falls back to the neutral placeholder
and no Intimacy data stays on the home screen; showing it again republishes them. The Intimacy
section of the settings page is hidden together with the module.

## Data flow

The widgets never read MyDay's data files. `HomeWidgetService`
(`lib/shared/services/home_widget_service.dart`) builds one envelope per kind with the pure
builders in `lib/shared/services/home_widget_payloads.dart` and publishes it through
`MyAppsWidgetBridge`:

- Android stores it in the private `myapps_widget` preferences under `envelope.<kind>` and redraws
  that kind's providers.
- iOS stores it in the `group.com.yuanzhe.myDay` App Group under `myapps_widget.envelope.<kind>`
  and reloads that kind's timeline.

`HomeWidgetService.notifyDataChanged()` schedules a refresh of every kind 2 seconds after the last
of:

- a Todo, Weight, Finance or Intimacy save, including local API writes;
- a sync download or a backup restore (the `AutoSyncService` local-data-changed callback);
- the app resuming;
- a change of language, Intimacy visibility, or any widget setting.

The day boundaries use the device's local time, like the Todo page. The Todo snapshot carries both
today and tomorrow, so the widget switches to tomorrow's list at midnight without the app; Android
redraws at least every 30 minutes and iOS schedules a timeline entry at the next midnight and at
each reminder time.

### Interactive controls

The checkboxes and the timer buttons use the MyApps-Widget pending-action queue
(`packages/myapps_widget/doc/en-us/actions.md`): Android on every version, iOS 17 and later. On
iOS 14–16 the same controls open the app instead.

| Kind | Action | `args` | Applied by the app |
|---|---|---|---|
| `myday.todo` | `setDone` | `id`, `date` (`yyyy-MM-dd`), `done` | Daily task: the date's completion log entry and its subtasks. One-time task: `isCompleted`, `completedDate` (that date) and its subtasks |
| `myday.timer` | `start` | — | No session: a new running session from `at`. Paused: resume at `at`. Running: nothing |
| `myday.timer` | `pause` | — | Running: add `at − startedAt` to the elapsed time and pause |
| `myday.timer` | `add` | `n` (100) | Add `n` to the count at the session's elapsed time at `at` |

`HomeWidgetService.drainActions()` runs at start, on resume and whenever the native side reports a
new action. It applies the actions in queue order, writes the data file, publishes the envelope with
the applied ids in `appliedActions`, and only then acknowledges them. A Todo action is idempotent
(it sets a state). While the timer page is open, timer actions go to the open page instead of the
file, so the page never overwrites them with its stale state. Recurring one-time tasks and tasks
not found any more are skipped from the widget: their checkbox opens the app on the task instead,
so the "create next occurrence" prompt still appears.

Until the app runs, a tap exists only in the widget queue: it is not in `todo_data.json` or
`intimacy_data.json` and does not sync. The renderers replay pending actions over the envelope so
the tap shows at once.

## Deep links

Taps that open the app use `myday://widget/<kind>?do=<what>`:

| `do` | Opens |
|---|---|
| absent | The kind's tab (`/todo`, `/weight`, `/finance`, `/intimacy`) |
| `add` | The tab and its add dialog (task, weight record, transaction, intimacy record) |
| `toggle` with `id` | Todo on today, toggling that task (the in-app path, with its recurrence prompt) |
| `timer` | The Intimacy tab and the timer page |

`HomeWidgetLaunch` (in `home_widget_service.dart`) turns the link into a pending request that the
tab page consumes once it has loaded. Intimacy links go to `/todo` while the module is hidden. The
scheme is registered in `ios/Runner/Info.plist` (`CFBundleURLTypes`); Android delivers the link as
the launch intent's data.

## Snapshot format (envelope 1, payload version 1)

Common payload fields: `labels` (the wording, resolved from the ARB files in the app's language;
`{n}` is replaced natively), and `mask` (true for *Hide values*). Times are UTC epoch milliseconds;
dates are local `yyyy-MM-dd`.

### `myday.todo`

```json
{
  "days": [
    {
      "date": "2026-11-02",
      "score": 2,
      "items": [
        {"id": "t1", "t": "Pay the bills", "e": "🧾", "k": "routineOnce", "done": false,
         "time": "", "late": true, "rec": false, "sched": false}
      ]
    },
    {"date": "2026-11-03", "score": null, "items": []}
  ],
  "appliedActions": ["6f1c…"],
  "mask": false,
  "labels": {}
}
```

- `days` — today and tomorrow, each computed exactly as the Todo page would show that date (daily
  templates by `startDate`/`deletedDate`, one-time tasks carried forward while open). At most 30
  items per day, in display order.
- `k` — `daily`, `routineOnce` or `workOnce`; `time` — the reminder time `HH:mm` or empty;
  `late` — an open one-time task whose scheduled or due date is before that day; `rec` — a
  one-time task with a recurrence; `sched` — a one-time task scheduled exactly on that day (used
  for the "tomorrow" preview).
- A day not found (the snapshot is more than a day old) renders the *Open MyDay to update* state.

### `myday.weight`

```json
{"latest": {"kg": 62.4, "at": 1767336120000}, "previousKg": 63.0, "change30": -1.2,
 "bmi": 21.6, "points": [63.6, 63.2, 62.9, 62.4], "remindAt": "07:30", "mask": false, "labels": {}}
```

`latest` is null without records. `change30` is the latest weight minus the latest record at or
before 30 days earlier (or the oldest record of the last 30 days). `points` are the weights of the
last 30 days, oldest first, at most 30. `remindAt` is the morning reminder time, or empty when the
reminder mode is `none`.

### `myday.finance`

```json
{"month": "2026-11", "monthLabel": "November", "expense": "¥3,284", "income": "¥12,000",
 "net": "¥8,716", "netNegative": false,
 "top": {"name": "Dining", "emoji": "🍜", "amount": "¥1,120", "share": 34},
 "bills": [{"name": "Netflix", "emoji": "", "day": "2026-11-05", "date": "11/05", "amount": "¥68"}],
 "mask": false, "labels": {}}
```

Amounts are formatted by the app in the default currency. `bills` are at most three active
subscriptions billing within 7 days (`upcomingSubscriptions`), and the renderer drops a bill whose
`day` has passed.

### `myday.intimacy`

```json
{"lastAt": 1767052800000, "month": "2026-11", "monthCount": 6, "avgMinutes": 24,
 "cycleNext": "2026-11-07", "mask": true, "labels": {}}
```

`lastAt` is null without records; `avgMinutes` is null when no record of the month has a duration;
`cycleNext` is empty unless the user's own cycle tracking is on and a start is predicted. When the
current month differs from `month`, the renderer shows a count of 0.

### `myday.timer`

```json
{"session": {"running": true, "startedAt": 1767337200000, "accumulatedMs": 0, "count": 3400},
 "last": {"at": 1767052800000, "durationMs": 1440000}, "step": 100,
 "appliedActions": [], "mask": false, "labels": {}}
```

`session` is null when no stopwatch is active; `count` is the actual repetition count. `last` is
the latest record or timer-history entry. Renderers replay pending `start`, `pause` and `add`
actions with the semantics in the table above.

The payloads are device-local: never synced, backed up or shared. Changing one means bumping that
kind's `pv` (`HomeWidgetService.formatVersion`) together with both native readers.

## Platform setup

- **Android** — the receivers are declared in `AndroidManifest.xml`; the plugin contributes its
  own `WidgetActionReceiver`. Layouts are `res/layout/widget_*.xml` with Material You colors on
  Android 12+ (`values-v31/widget_colors.xml`) and seed tones before.
- **iOS** — the `MyDayWidgets` app-extension target (deployment target iOS 14, `AppIntents`
  weak-linked) embeds `packages/myapps_widget/apple/MyAppsWidgetKit/MyAppsWidgetKit.swift` by file
  reference. Runner and the extension carry the `group.com.yuanzhe.myDay` App Group entitlement,
  which must be enabled on both App IDs before a signed build. See
  [`../platform-notes.md`](../platform-notes.md).

## Privacy

Widgets put titles, weights, amounts and Intimacy statistics on the home screen, and the Todo
lock-screen rectangle puts task titles on the lock screen. Nothing appears until a widget is added,
removing it stops the display, and the snapshot never leaves the device.

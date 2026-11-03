# lib/shared/services/home_widget_payloads.dart

`HomeWidgetPayloads` holds the pure builders of the home-screen widget payloads (1.8.3). Each
builder turns one module's data into the app-owned `payload` object of one MyApps-Widget envelope;
[`HomeWidgetService`](home_widget_service.md) wraps it in the envelope and publishes it, and the
settings-page previews draw from the same maps. Nothing here reads files or has side effects, which
is what the unit tests rely on. The field-by-field formats are in
[Snapshot format](../../../features/home-screen-widgets.md#snapshot-format-envelope-1-payload-version-1).
Every payload carries a `mask` flag and a `labels` map of localized strings with `{n}`/`{m}`
placeholders, so the native renderers need no translations of their own.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| Limits and step constants | static constants (`HomeWidgetPayloads`) | B | `maxTodoItems` (30), `maxAppliedActions` (50), `maxWeightPoints` (30), `timerStep` (100). |
| `dayKey` | static method (`HomeWidgetPayloads`) | B | Format a local calendar date as `yyyy-MM-dd` (same key as `DailyCompletionLog.dateKey`). |
| `hhmm` | static method (`HomeWidgetPayloads`) | B | Format a time of day as `HH:mm`; empty for null. |
| [`todo`](#todo) | static method (`HomeWidgetPayloads`) | A | Build the `myday.todo` payload with today and tomorrow. |
| [`todoItems`](#todoitems) | static method (`HomeWidgetPayloads`) | A | List one day's Todo rows in display order. |
| `_todoItem` | static method (`HomeWidgetPayloads`) | B | Serialize one Todo row with short keys. |
| [`weight`](#weight) | static method (`HomeWidgetPayloads`) | A | Build the `myday.weight` payload. |
| [`finance`](#finance) | static method (`HomeWidgetPayloads`) | A | Build the `myday.finance` payload with formatted amounts. |
| [`intimacy`](#intimacy) | static method (`HomeWidgetPayloads`) | A | Build the `myday.intimacy` payload. |
| [`timer`](#timer) | static method (`HomeWidgetPayloads`) | A | Build the `myday.timer` payload. |
| [`sessionCount`](#sessioncount) | static method (`HomeWidgetPayloads`) | A | Return a timer session's actual repetition count. |
| `_tail` | static method (`HomeWidgetPayloads`) | B | Keep the newest `maxAppliedActions` applied action ids. |
| `_round1` | static method (`HomeWidgetPayloads`) | B | Round to one decimal. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/services/home_widget_payloads.dart` reports 12,
against 13 rows above. The extra row groups the four `static const` limits, which are real
declarations with plain `///` comments and no `Purpose:` block.

## Documentation

### `static Map<String, dynamic> todo(TodoData? data, {required DateTime now, required AppLocalizations l10n, required String localeTag, List<String> appliedActions = const [], bool mask = false})` <a id="todo"></a>
- **Kind:** static method of `HomeWidgetPayloads`
- **Source:** `lib/shared/services/home_widget_payloads.dart` (line 56)
- **Purpose:** Build the `myday.todo` payload.
- **Inputs:** `data` (null when no file exists); `now` — local time; `l10n`; `localeTag` for date
  labels; `appliedActions`; `mask`.
- **Returns:** A map with `days` (today and tomorrow, each with `date`, `label`, `score` and
  `items`), `appliedActions`, `mask` and `labels`.
- **Side effects:** None.
- **Algorithm:** For today and `addCalendarDays(today, 1)`, emit the day key, a `DateFormat.MMMEd`
  label, the day's score and `todoItems(...)`; append the newest applied ids through `_tail`.
- **Usage:** `HomeWidgetService.payloadBuilders`.
- **Notes:** Each day lists what the Todo page would show for that date. Tomorrow lets the widget
  roll over at midnight without the app running.

### `static List<Map<String, dynamic>> todoItems(TodoData data, {required DateTime day, required DateTime today})` <a id="todoitems"></a>
- **Kind:** static method of `HomeWidgetPayloads`
- **Source:** `lib/shared/services/home_widget_payloads.dart` (line 102)
- **Purpose:** List one day's Todo rows in display order.
- **Inputs:** `data`; `day` — the date shown; `today` — the real current date.
- **Returns:** Up to `maxTodoItems` item maps.
- **Side effects:** None.
- **Algorithm:**
  1. Daily templates that have started by `day` and were not deleted by it, done per
     `dailyLog.isCompleted`.
  2. Routine then work one-time tasks with a scheduled date: a completed task shows on its
     scheduled or completion day; an open one on its scheduled day, or carried forward to any day
     up to tomorrow. `late` marks open tasks scheduled or due before `day`.
  3. Sort overdue first, then open tasks by reminder time (no time last, section order as
     tie-break), then completed tasks; take the first `maxTodoItems`.
- **Usage:** `todo`.
- **Notes:** Visibility mirrors `TodoPage._dailyForDate` and `_oneTimeVisibleOnDate`.

### `static Map<String, dynamic> weight(WeightData? data, {required DateTime now, required AppLocalizations l10n, bool mask = false})` <a id="weight"></a>
- **Kind:** static method of `HomeWidgetPayloads`
- **Source:** `lib/shared/services/home_widget_payloads.dart` (line 194)
- **Purpose:** Build the `myday.weight` payload.
- **Inputs:** `data` (null without a file); `now`; `l10n`; `mask`.
- **Returns:** A map with `latest` (`kg`, UTC `at` in ms), `previousKg`, `change30`, `bmi`,
  `points`, `remindAt`, `mask` and `labels`.
- **Side effects:** None.
- **Algorithm:** Sort the records by time. `change30` compares the latest record with the latest one
  at or before 30 days earlier, falling back to the oldest record of the last 30 days (null when
  that is the latest itself). `points` are the last `maxWeightPoints` weights of that window,
  rounded to one decimal. `remindAt` is the morning reminder time unless reminders are off.
- **Usage:** `HomeWidgetService.payloadBuilders`.
- **Notes:** The unit is always `kg`.

### `static Map<String, dynamic> finance(FinanceData? data, {required ExchangeRateData rates, required DateTime now, required AppLocalizations l10n, required String localeTag, bool mask = false})` <a id="finance"></a>
- **Kind:** static method of `HomeWidgetPayloads`
- **Source:** `lib/shared/services/home_widget_payloads.dart` (line 269)
- **Purpose:** Build the `myday.finance` payload.
- **Inputs:** `data` (null without a file); `rates`; `now`; `l10n`; `localeTag`; `mask`.
- **Returns:** A map with `month`, `monthLabel`, formatted `expense`, `income` and `net`,
  `netNegative`, `top` (largest expense category with its share), `bills` (up to three), `mask` and
  `labels`.
- **Side effects:** None.
- **Algorithm:** Sum every expense and income transaction (transfers excluded) of the calendar
  month, each converted to the default currency at its own rate snapshot; group expenses by
  category for `top`; list the first three `upcomingSubscriptions` within 7 days as `bills`.
- **Usage:** `HomeWidgetService.payloadBuilders`.
- **Notes:** Totals match the Finance home summary. Amounts are pre-formatted strings, so the native
  side needs no currency logic.

### `static Map<String, dynamic> intimacy(IntimacyData? data, {required DateTime now, required AppLocalizations l10n, bool mask = false})` <a id="intimacy"></a>
- **Kind:** static method of `HomeWidgetPayloads`
- **Source:** `lib/shared/services/home_widget_payloads.dart` (line 367)
- **Purpose:** Build the `myday.intimacy` payload.
- **Inputs:** `data` (null without a file); `now`; `l10n`; `mask`.
- **Returns:** A map with `lastAt`, `month`, `monthCount`, `avgMinutes`, `cycleNext`, `mask` and
  `labels`.
- **Side effects:** None.
- **Algorithm:** Find the latest record, count this month's records and average the timed ones in
  minutes. When the user's cycle tracking is enabled, run `predictCycle` over the user's own cycle
  starts and keep the first predicted start from today on.
- **Usage:** `HomeWidgetService.payloadBuilders`, only while the Intimacy module is visible.
- **Notes:** The cycle line uses only the user's own records (`personId` null). The labels use the
  neutral *Private* wording.

### `static Map<String, dynamic> timer(IntimacyData? data, {required AppLocalizations l10n, List<String> appliedActions = const [], bool mask = false})` <a id="timer"></a>
- **Kind:** static method of `HomeWidgetPayloads`
- **Source:** `lib/shared/services/home_widget_payloads.dart` (line 436)
- **Purpose:** Build the `myday.timer` payload.
- **Inputs:** `data` (null without a file); `l10n`; `appliedActions`; `mask`.
- **Returns:** A map with `session` (`running`, `startedAt`, `accumulatedMs`, `count`) or null,
  `last` (`at`, `durationMs`) or null, `step`, `appliedActions`, `mask` and `labels`.
- **Side effects:** None.
- **Algorithm:** `last` is the latest of the records and the timer history entries; `session.count`
  comes from `sessionCount`; `startedAt` is set only while running.
- **Usage:** `HomeWidgetService.payloadBuilders`, only while the Intimacy module is visible.
- **Notes:** The native widget counts up from `startedAt` itself while running.

### `static int sessionCount(IntimacyTimerSession session)` <a id="sessioncount"></a>
- **Kind:** static method of `HomeWidgetPayloads`
- **Source:** `lib/shared/services/home_widget_payloads.dart` (line 497)
- **Purpose:** Return a timer session's actual repetition count.
- **Inputs:** `session`.
- **Returns:** `int`.
- **Side effects:** None.
- **Algorithm:** The timeline total when a timeline exists; otherwise 0 for a non-positive count,
  else `thrustCount` times `thrustCountUnit` (unit 1 stays as is).
- **Usage:** `timer` and `HomeWidgetActions._timelineOf`.
- **Notes:** None.

# lib/shared/services/home_widget_actions.dart

Pure appliers for the actions that interactive home-screen widget controls queue (1.8.3): the Todo
checkbox (`setDone`) and the Timer buttons (`start`, `pause`, `add`). The native side only queues a
tap and draws an optimistic overlay; [`HomeWidgetService._drain`](home_widget_service.md#_drain)
later loads the data file, runs the matching applier and writes the result. The semantics match the
native overlays described in
[Interactive controls](../../../features/home-screen-widgets.md#interactive-controls).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `HomeWidgetActionResult` (constructor) | const constructor (`HomeWidgetActionResult<T>`) | B | Hold the outcome of an apply pass: data, consumed ids, whether it changed. |
| [`applyTodo`](#applytodo) | static method (`HomeWidgetActions`) | A | Apply queued `myday.todo` actions to Todo data. |
| [`applyTimer`](#applytimer) | static method (`HomeWidgetActions`) | A | Apply queued `myday.timer` actions to a timer session. |
| [`_timelineOf`](#_timelineof) | static method (`HomeWidgetActions`) | A | Return a session's thrust timeline, seeding one from its count. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/services/home_widget_actions.dart` reports 4,
matching the 4 rows above. The fields of `HomeWidgetActionResult` carry plain `///` comments and
are not listed.

## Documentation

### `static HomeWidgetActionResult<TodoData> applyTodo(TodoData data, List<WidgetAction> actions, {DateTime? now})` <a id="applytodo"></a>
- **Kind:** static method of `HomeWidgetActions`
- **Source:** `lib/shared/services/home_widget_actions.dart` (line 45)
- **Purpose:** Apply queued `myday.todo` actions to Todo data.
- **Inputs:** `data`; `actions` — oldest first; `now` — for `modifiedAt` (defaults to the clock).
- **Returns:** The updated data, every consumed id and whether anything changed.
- **Side effects:** Mutates `data.dailyLog` in place when a daily task changes.
- **Algorithm:**
  1. Every action id is recorded as consumed. Skip actions other than `setDone`, and those whose
     `id`, `done` or `date` argument is missing or malformed.
  2. A daily template: if its completion on that day differs from `done`, toggle it in
     `dailyLog` and set its subtasks to the same state.
  3. A one-time task: skip when already in that state, or when completing a recurring task;
     otherwise replace it with a copy whose completion, subtasks and `completedDate` follow `done`,
     stamped with the UTC `modifiedAt`.
  4. Return the input unchanged when nothing changed, else a new `TodoData` with the new one-time
     list.
- **Usage:** `HomeWidgetService._drain`.
- **Notes:** `setDone` sets a state rather than toggling, so a re-delivered action is harmless.
  Completing a recurring one-time task is skipped because its checkbox opens the app instead, for
  the next-occurrence prompt. Unknown ids are skipped.

### `static HomeWidgetActionResult<IntimacyTimerSession?> applyTimer(IntimacyTimerSession? session, List<WidgetAction> actions)` <a id="applytimer"></a>
- **Kind:** static method of `HomeWidgetActions`
- **Source:** `lib/shared/services/home_widget_actions.dart` (line 136)
- **Purpose:** Apply queued `myday.timer` actions to a timer session.
- **Inputs:** `session` — the current session or null; `actions` — oldest first.
- **Returns:** The new session, every consumed id and whether anything changed.
- **Side effects:** None.
- **Algorithm:**
  1. Start from the session's first start, running start, accumulated time and timeline (seeded by
     `_timelineOf`), or an empty state.
  2. `start` (when not running) sets the first start if missing and starts a segment at the tap
     instant; `pause` (when running) folds the segment into the accumulated time, never negative;
     `add` (once started) records `n` (default `timerStep`) at the elapsed time of the tap.
  3. If nothing changed, return the input session. Otherwise store the count like the timer page:
     unit 100 when the total is a multiple of 100, otherwise unit 1.
- **Usage:** `HomeWidgetService._drain` when the timer page is closed.
- **Notes:** `TimerPage._applyWidgetActions` applies the same semantics to the open page's
  in-memory state.

### `static ThrustTimeline _timelineOf(IntimacyTimerSession session)` <a id="_timelineof"></a>
- **Kind:** private static method of `HomeWidgetActions`
- **Source:** `lib/shared/services/home_widget_actions.dart` (line 209)
- **Purpose:** Return a session's thrust timeline, seeding one from its count.
- **Inputs:** `session`.
- **Returns:** `ThrustTimeline`.
- **Side effects:** None.
- **Algorithm:** Keep the stored timeline when its total equals `HomeWidgetPayloads.sessionCount`;
  otherwise `ThrustTimeline.seed(accumulatedMs, count)`.
- **Usage:** `applyTimer`.
- **Notes:** Mirrors `TimerPage._restoreTimeline`, seeding pre-1.5.5 counts at the session's
  accumulated time.

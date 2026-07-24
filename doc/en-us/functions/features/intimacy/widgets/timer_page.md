# lib/features/intimacy/widgets/timer_page.dart

`TimerPage` is the intimacy stopwatch screen described in
[Intimacy — Timer/stopwatch session persistence](../../../../features/intimacy.md#timerstopwatch-session-persistence).
It is a wall-clock based timer (immune to screen-off/app-suspend, unlike a naive tick-counter), with
a non-negative thrust counter that stores estimates as `x100` and exact non-round counts as `x1`, a
retained/pruned history list, and a local-only keep-screen-awake switch backed by `wakelock_plus`.
Critically, this widget owns no persistence itself — every state-changing action calls
`widget.onStateChanged` (typed as `TimerStateChanged`), which the caller (`views/intimacy_page.dart`,
via `_saveTimerState`) uses to write `intimacy_data.json` immediately, so an accidental app/page exit
mid-session still keeps the latest running/paused state and thrust count. On save, it opens
[`AddRecordDialog`](add_record_dialog.md) pre-filled with the elapsed duration and thrust count. The
page returns a `TimerPageResult` describing what changed (`record`, history, timer session,
retention) so the caller only re-saves what's actually dirty.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `TimerStateChanged` | typedef | B | Callback signature the caller supplies to persist timer state changes. |
| `TimerPageResult` (constructor) | constructor (`TimerPageResult`) | B | Create a timer page result instance. |
| `TimerPage` (constructor) | constructor (`TimerPage`) | B | Create a timer page instance from positions, current timer state, and the persistence callback. |
| `TimerPage.createState` | method (`TimerPage`) | B | Create the mutable `_TimerPageState`. |
| [`_elapsed`](#elapsed) | getter (`_TimerPageState`) | A | Compute wall-clock elapsed time: accumulated time plus time since the last resume, if running. |
| [`initState`](#initstate) | method (`_TimerPageState`) | A | Restore an interrupted timer session (running/paused) from `widget.timerSession` and load the wakelock preference. |
| `dispose` | method (`_TimerPageState`) | B | Cancel the ticker, remove the lifecycle observer, and release any held wakelock. |
| [`didChangeAppLifecycleState`](#didchangeapplifecyclestate) | method (`_TimerPageState`) | A | Re-arm the ticker and wakelock when the app resumes while the timer is running. |
| [`_loadKeepScreenAwakeSetting`](#loadkeepscreenawakesetting) | method (`_TimerPageState`) | A | Load the local-only keep-screen-awake preference and apply it. |
| [`_setKeepScreenAwake`](#setkeepscreenawake) | method (`_TimerPageState`) | A | Persist and apply a new keep-screen-awake preference. |
| [`_applyWakelock`](#applywakelock) | method (`_TimerPageState`) | A | Enable or disable the platform screen wakelock to match the current preference. |
| [`_releaseWakelock`](#releasewakelock) | method (`_TimerPageState`) | A | Disable the wakelock, but only if this page is the one that enabled it. |
| [`_applyRetention`](#applyretention) | method (`_TimerPageState`) | A | Drop history entries older than the configured retention window. |
| [`_start`](#start) | method (`_TimerPageState`) | A | Start or resume the stopwatch and persist the running session. |
| [`_pause`](#pause) | method (`_TimerPageState`) | A | Pause the stopwatch, folding elapsed time into the accumulated total, and persist the paused session. |
| [`_changeThrustCount`](#changethrustcount) | method (`_TimerPageState`) | A | Adjust the thrust count by a signed delta, clamped at zero, and persist the session. |
| [`_actualThrustCount`](#actualthrustcount) | method (`_TimerPageState`) | A | Convert a stored count/unit pair back into an actual repetition count. |
| [`_storedThrustCountUnit`](#storedthrustcountunit) | getter (`_TimerPageState`) | A | Decide whether the current count must be stored as exact `x1` or estimated `x100`. |
| [`_storedThrustCount`](#storedthrustcount) | getter (`_TimerPageState`) | A | Compute the count value to persist under the current storage unit. |
| `_thrustCountLabel` | getter (`_TimerPageState`) | B | Format the current thrust count as `"<count> x<unit>"` for display. |
| [`_reset`](#reset) | method (`_TimerPageState`) | A | Clear the stopwatch back to zero (time and thrust count) and persist the cleared session. |
| [`_ensureTicker`](#ensureticker) | method (`_TimerPageState`) | A | (Re)start the one-second periodic timer that drives the visible elapsed-time display. |
| `_sessionStartTime` | getter (`_TimerPageState`) | B | Return `_firstStartedAt` (the session's original start time, if any). |
| [`_timerSession`](#timersession) | getter (`_TimerPageState`) | A | Build a persistable `IntimacyTimerSession` snapshot of the current stopwatch state. |
| [`_persistState`](#persiststate) | method (`_TimerPageState`) | A | Forward changed-field flags and a state snapshot to `widget.onStateChanged`, only when something actually changed. |
| [`_popWithHistoryIfChanged`](#popwithhistoryifchanged) | method (`_TimerPageState`) | A | Pop the page, returning a `TimerPageResult` only if history/session/retention actually changed. |
| [`_saveRecord`](#saverecord) | method (`_TimerPageState`) | A | Stop the timer (unless restoring from history), add a history entry, open `AddRecordDialog`, and pop with the result. |
| [`_formatDuration`](#formatduration) | method (`_TimerPageState`) | A | Format a `Duration` as `HH:MM:SS`. |
| `_formatDateTime` | method (`_TimerPageState`) | B | Format a `DateTime` as `MM/dd HH:mm:ss` via `intl`. |
| [`_confirmRestoreHistory`](#confirmrestorehistory) | method (`_TimerPageState`) | A | Confirm, then restore a timer-history entry as a new running stopwatch session, removing it from history. |
| `build` | method (`_TimerPageState`) | B | Render the elapsed-time display, thrust controls, start/pause/save/reset buttons, and the history list. |
| `_buildRetentionChip` | method (widget helper) | B | Render the history-retention popup-menu chip (3d/7d/14d/forever). |

`grep -c 'Purpose:' lib/features/intimacy/widgets/timer_page.dart` reports 32, matching all 32 rows
above exactly (no undocumented real declaration was found, and no `/// Purpose:` block is misattached
above a call site rather than a real declaration). Several blocks use generic auto-generated-looking
phrasing in the source ("Provide the internal ... helper for this file", "Internal helper used within
this file only") — this page's Purpose column and Documentation entries replace that phrasing with
descriptions verified against the actual implementation, per the per-file template's instruction to
refine (not just copy) the source `///` comment. Tier split: 22 Tier A, 10 Tier B.

## Documentation

### `Duration get _elapsed` <a id="elapsed"></a>
- **Kind:** getter of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 117)
- **Purpose:** Compute the stopwatch's current elapsed time from wall-clock timestamps rather than a
  ticking in-memory counter.
- **Inputs:** None (reads `_accumulated`, `_running`, `_startedAt`).
- **Returns:** `Duration`.
- **Side effects:** None.
- **Algorithm:** `_accumulated + (_running && _startedAt != null ? DateTime.now().difference(_startedAt!) : Duration.zero)`
  — accumulated time from prior run segments, plus time since the last resume if currently running.
- **Usage:**
  ```dart
  // build, line 626:
  Text(_formatDuration(_elapsed), ...),

  // build, line 590:
  final hasElapsed = _elapsed > Duration.zero;
  ```
- **Notes:** This is the widget-level equivalent of the model's own
  `IntimacyTimerSession.elapsedAt(now)` described in
  [Intimacy — Timer/stopwatch session persistence](../../../../features/intimacy.md#timerstopwatch-session-persistence):
  because it's derived from `DateTime.now()` every time it's read, the displayed time is correct even
  immediately after an app restart, before the first ticker callback fires.

### `void initState()` <a id="initstate"></a>
- **Kind:** method of `_TimerPageState` (override of `State.initState`)
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 131)
- **Purpose:** Restore whatever timer session the caller passed in — running, paused, or none — and
  begin loading the keep-screen-awake preference.
- **Inputs:** None (reads `widget.timerHistory`, `widget.timerHistoryRetentionDays`,
  `widget.timerSession`).
- **Returns:** None.
- **Side effects:** Registers this state as a `WidgetsBindingObserver`; may mark history as changed;
  starts the ticker if restoring a running session; kicks off `_loadKeepScreenAwakeSetting()`.
- **Algorithm:**
  1. `super.initState()`, then register as a lifecycle observer.
  2. `_retentionDays = widget.timerHistoryRetentionDays`; apply retention to a copy of
     `widget.timerHistory` via `_applyRetention`; if that pruned any entries, set
     `_historyChanged = true` (so the caller re-saves the pruned list even if the user never touches
     the timer).
  3. If `widget.timerSession` is non-null: restore `_firstStartedAt`, and `_startedAt` only if
     `session.running` (a paused session has no live `_startedAt`); restore `_accumulated`, `_running`;
     restore `_thrustCount` via `_actualThrustCount(session.thrustCount, session.thrustCountUnit)`
     (converting the stored x100/x1 form back to an actual repetition count); if `_running`, call
     `_ensureTicker()` so the display starts advancing immediately.
  4. `unawaited(_loadKeepScreenAwakeSetting())`.
- **Usage:**
  ```dart
  // views/intimacy_page.dart, lines 548-560 (opening the page restores whatever session was saved):
  builder: (_) => TimerPage(
    partners: _partners.where((p) => p.endDate == null).toList(),
    toys: _toys.where((t) => t.retiredDate == null).toList(),
    positions: _positions,
    timerHistory: _timerHistory,
    timerSession: _timerSession,
    timerHistoryRetentionDays: _timerHistoryRetentionDays,
    onStateChanged: _saveTimerState,
  ),
  ```
- **Notes:** This is exactly the session-recovery behavior documented in
  [Intimacy](../../../../features/intimacy.md#timerstopwatch-session-persistence): "stopped-but-unsaved
  and paused sessions restore as paused" (here: `session.running == false` so `_startedAt` stays
  `null` while `_accumulated`/`_thrustCount` still restore) and "running sessions resume from
  wall-clock time" (here: `_ensureTicker()` plus the `_elapsed` getter's live computation).

### `void didChangeAppLifecycleState(AppLifecycleState state)` <a id="didchangeapplifecyclestate"></a>
- **Kind:** method of `_TimerPageState` (override of `WidgetsBindingObserver.didChangeAppLifecycleState`)
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 174)
- **Purpose:** Re-arm the ticker and wakelock after the app returns to the foreground.
- **Inputs:** `state` — the new `AppLifecycleState`.
- **Returns:** None.
- **Side effects:** May restart the ticker (`setState`) and re-enable the wakelock.
- **Algorithm:** Only acts on `AppLifecycleState.resumed`: if `_running`, call `_ensureTicker()` and
  `setState(() {})` to force an immediate redraw with the current wall-clock elapsed time; if
  `_keepScreenAwake`, call `_applyWakelock()` (unawaited).
- **Usage:** Invoked automatically by the Flutter framework via the `WidgetsBindingObserver` mixin
  registered in `initState`, whenever the app's lifecycle state changes (e.g. returning from the
  background after the OS may have suspended timers).
- **Notes:** Because `_elapsed` is wall-clock based, the displayed time would already be correct on
  the next periodic tick even without this method — its real job is making the *ticker itself* (which
  a suspended app may have paused) and the wakelock resume promptly instead of waiting.

### `Future<void> _loadKeepScreenAwakeSetting()` <a id="loadkeepscreenawakesetting"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 191)
- **Purpose:** Load the remembered local-only keep-screen-awake preference and apply it immediately.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads `storage_config.json`; updates `_keepScreenAwake`; may enable the platform
  wakelock.
- **Algorithm:** Read `TodoStorage.readConfig()`; `enabled = config[_keepScreenAwakeConfigKey] ==
  true`; if still mounted, `setState` to store it, then `await _applyWakelock()`.
- **Usage:**
  ```dart
  // initState, line 151:
  unawaited(_loadKeepScreenAwakeSetting());
  ```
- **Notes:** Uses key `intimacyTimerKeepScreenAwake` (`_keepScreenAwakeConfigKey`), which is
  intentionally not part of synced `intimacy_data.json` — see
  [Intimacy](../../../../features/intimacy.md#timerstopwatch-session-persistence).

### `Future<void> _setKeepScreenAwake(bool enabled)` <a id="setkeepscreenawake"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 204)
- **Purpose:** Handle the user toggling the keep-screen-awake switch.
- **Inputs:** `enabled` — the new switch value.
- **Returns:** `Future<void>`.
- **Side effects:** Updates `_keepScreenAwake`; toggles the platform wakelock; writes
  `storage_config.json`, preserving any unrelated keys already in the config map.
- **Algorithm:** `setState` the new value; `await _applyWakelock()`; read the config, set
  `config[_keepScreenAwakeConfigKey] = enabled`, write it back.
- **Usage:**
  ```dart
  // build, line 682-684:
  onChanged: (value) {
    unawaited(_setKeepScreenAwake(value));
  },
  ```
- **Notes:** The wakelock is applied before the config write, so the platform state matches the UI
  immediately even if the write is still in flight.

### `Future<void> _applyWakelock()` <a id="applywakelock"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 217)
- **Purpose:** Reconcile the platform screen wakelock with the current `_keepScreenAwake` preference,
  without stepping on a wakelock some other feature may hold.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Calls `WakelockPlus.enable()`/`disable()`; updates `_wakelockEnabledByPage`.
- **Algorithm:**
  1. If `_keepScreenAwake && !_disposed`: enable the wakelock; if the page became disposed or the
     preference flipped off while awaiting (`_disposed || !_keepScreenAwake`), immediately disable it
     again and clear `_wakelockEnabledByPage`; otherwise mark `_wakelockEnabledByPage = true`.
  2. Else if `_wakelockEnabledByPage` (preference is off but this page still holds the lock): disable
     it and clear the flag.
- **Usage:**
  ```dart
  // _loadKeepScreenAwakeSetting, line 196:
  await _applyWakelock();

  // didChangeAppLifecycleState, line 181:
  unawaited(_applyWakelock());
  ```
- **Notes:** `_wakelockEnabledByPage` tracks whether *this page* is the one holding the lock, so
  `_releaseWakelock` never disables a wakelock some other feature (e.g. a foreground sync operation
  via `shared/services/sync_wake_lock.dart`) is independently holding.

### `void _releaseWakelock()` <a id="releasewakelock"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 237)
- **Purpose:** Release the wakelock on page teardown, but only if this page is the one that enabled
  it.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** May call `WakelockPlus.disable()` (fire-and-forget).
- **Algorithm:** Return immediately if `!_wakelockEnabledByPage`; otherwise clear the flag and call
  `WakelockPlus.disable()` without awaiting.
- **Usage:**
  ```dart
  // dispose, line 164:
  _releaseWakelock();
  ```
- **Notes:** The doc comment explicitly notes the unawaited call is intentional: `dispose()` cannot be
  `async`, so the platform-channel call is deliberately fire-and-forget.

### `List<TimerHistoryEntry> _applyRetention(List<TimerHistoryEntry> entries)` <a id="applyretention"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 250)
- **Purpose:** Prune history entries older than the configured retention window.
- **Inputs:** `entries` — the history list to filter.
- **Returns:** `List<TimerHistoryEntry>` — `entries` unchanged if retention is permanent.
- **Side effects:** None (pure filter; callers are responsible for persisting the result).
- **Algorithm:** If `_retentionDays == null`, return `entries` as-is (permanent retention). Otherwise
  compute `cutoff = DateTime.now().subtract(Duration(days: _retentionDays!))` and keep only entries
  where `e.start.isAfter(cutoff)`.
- **Usage:**
  ```dart
  // initState, line 135:
  _history = _applyRetention(List.of(widget.timerHistory));

  // _buildRetentionChip, onSelected, line 859:
  _history = _applyRetention(_history);
  ```
- **Notes:** Retention is applied both at load time (in case the setting changed while the page was
  closed) and immediately whenever the user picks a new retention value.

### `Future<void> _start()` <a id="start"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 263)
- **Purpose:** Start the stopwatch from zero, or resume it from a paused state.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Updates `_firstStartedAt`/`_startedAt`/`_running`; starts the ticker; persists the
  session via `_persistState`.
- **Algorithm:**
  1. `_firstStartedAt ??= DateTime.now()` — set only on the very first start, never on a resume.
  2. `_startedAt = DateTime.now()` (the wall-clock moment this run segment began); `_running = true`.
  3. `_ensureTicker()`; `setState(() {})`; `await _persistState(timerSessionChanged: true)`.
- **Usage:**
  ```dart
  // build, line 696 (fresh start) and line 734 (resume from paused):
  onPressed: () => _start(),
  ```
- **Notes:** `_firstStartedAt` is what survives a pause/resume cycle unchanged — it's the value stored
  as `IntimacyTimerSession.firstStartedAt` and is what `_saveRecord` falls back to as the record's
  start time.

### `Future<void> _pause()` <a id="pause"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 277)
- **Purpose:** Pause the stopwatch, folding the just-elapsed run segment into `_accumulated`.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Updates `_accumulated`/`_startedAt`/`_running`; cancels the ticker; persists the
  session.
- **Algorithm:**
  1. If currently running with a valid `_startedAt`, add `DateTime.now().difference(_startedAt!)` into
     `_accumulated`.
  2. Clear `_startedAt`, set `_running = false`, cancel `_ticker`.
  3. `setState(() {})`; `await _persistState(timerSessionChanged: true)`.
- **Usage:**
  ```dart
  // build, line 708-710:
  OutlinedButton.icon(
    onPressed: () => _pause(),
    icon: const Icon(Icons.pause),
    label: Text(l10n.intimacyPause),
  ),
  ```
- **Notes:** Also called internally by `_saveRecord` (when not restoring from a history prefill) so
  that saving a running timer first stops it cleanly through the same accumulation logic.

### `Future<void> _changeThrustCount(int delta)` <a id="changethrustcount"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 293)
- **Purpose:** Adjust the thrust counter by a signed delta (the `+100`/`+50`/`+10`/`-100` buttons).
- **Inputs:** `delta` — signed change to apply.
- **Returns:** `Future<void>`.
- **Side effects:** Updates `_thrustCount`; persists the session.
- **Algorithm:** `next = (_thrustCount + delta).clamp(0, 999999).toInt()`; if unchanged, return early;
  otherwise `setState` the new count and `await _persistState(timerSessionChanged: true)`.
- **Usage:**
  ```dart
  // build, lines 647-666 (the four buttons):
  OutlinedButton.icon(
    onPressed: _thrustCount > 0 ? () => _changeThrustCount(-100) : null,
    icon: const Icon(Icons.remove),
    label: const Text('-100'),
  ),
  FilledButton.icon(
    onPressed: () => _changeThrustCount(100),
    icon: const Icon(Icons.add),
    label: const Text('+100'),
  ),
  ```
- **Notes:** The `clamp(0, ...)` is what guarantees the "non-negative thrust counter" invariant
  described in [Intimacy](../../../../features/intimacy.md#timerstopwatch-session-persistence); the
  `-100` button itself is additionally disabled in the UI whenever `_thrustCount == 0`.

### `int _actualThrustCount(int count, int unit)` <a id="actualthrustcount"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 305)
- **Purpose:** Convert a stored `(count, unit)` pair — as read from a persisted session or history
  entry — back into an actual repetition count for the live counter.
- **Inputs:** `count`, `unit` — the stored values (`unit` is always normalized to `1` or `100`).
- **Returns:** `int` — the actual repetition count.
- **Side effects:** None.
- **Algorithm:** `count <= 0` returns `0`; otherwise `unit == 1 ? count : count * unit` (an `x100`
  stored count of, say, `3` expands back to `300`).
- **Usage:**
  ```dart
  // initState, line 145-148 (restoring a session):
  _thrustCount = _actualThrustCount(session.thrustCount, session.thrustCountUnit);

  // _confirmRestoreHistory, line 568-571 (restoring from history):
  _thrustCount = _actualThrustCount(entry.thrustCount, entry.thrustCountUnit);
  ```
- **Notes:** This is the exact inverse of `_storedThrustCount`/`_storedThrustCountUnit` — together
  they implement the x100/x1 storage rule from
  [Intimacy](../../../../features/intimacy.md#timerstopwatch-session-persistence).

### `int get _storedThrustCountUnit` <a id="storedthrustcountunit"></a>
- **Kind:** getter of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 315)
- **Purpose:** Decide whether the current live thrust count must be stored as an exact `x1` value or
  a compact `x100` estimate.
- **Inputs:** None (reads `_thrustCount`).
- **Returns:** `int` — `1` or `100` (`_estimatedThrustUnit`).
- **Side effects:** None.
- **Algorithm:** `_thrustCount > 0 && _thrustCount % _estimatedThrustUnit != 0 ? 1 :
  _estimatedThrustUnit` — any positive count that isn't a clean multiple of 100 must be stored exactly
  (unit `1`); zero or an exact multiple of 100 stores as unit `100`.
- **Usage:**
  ```dart
  // _timerSession getter, line 386:
  thrustCountUnit: _storedThrustCountUnit,

  // _saveRecord, line 450:
  prefillEntry?.thrustCountUnit ?? _storedThrustCountUnit,
  ```
- **Notes:** Because the buttons are `+100`/`+50`/`+10`/`-100`, any combination other than repeated
  `+100`/`-100` (e.g. one `+50`) immediately pushes the count off a multiple of 100, switching storage
  to exact `x1` for the rest of that session.

### `int get _storedThrustCount` <a id="storedthrustcount"></a>
- **Kind:** getter of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 325)
- **Purpose:** Compute the count value to actually persist, consistent with `_storedThrustCountUnit`.
- **Inputs:** None (reads `_thrustCount`).
- **Returns:** `int`.
- **Side effects:** None.
- **Algorithm:** If `_storedThrustCountUnit == 1`, store `_thrustCount` verbatim (exact); otherwise
  store `_thrustCount ~/ _estimatedThrustUnit` (the count of hundreds).
- **Usage:**
  ```dart
  // _saveRecord, line 448 and _timerSession, line 385:
  thrustCount: _storedThrustCount,
  ```
- **Notes:** A live count of `250` (not a clean multiple of 100) stores as unit `1`, count `250`
  exactly — it is never rounded down to `2` hundreds, which would silently lose 50 repetitions.

### `Future<void> _reset()` <a id="reset"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 342)
- **Purpose:** Clear the stopwatch entirely — elapsed time and thrust count — back to a fresh, unstarted
  state.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Clears `_accumulated`/`_firstStartedAt`/`_startedAt`/`_running`/`_thrustCount`;
  cancels the ticker; persists the (now-empty) session.
- **Algorithm:** Zero every timer field, cancel `_ticker`, `setState(() {})`, then
  `await _persistState(timerSessionChanged: true)` — which persists a session snapshot of `null`
  since `_timerSession` returns `null` once `_firstStartedAt` is `null`.
- **Usage:**
  ```dart
  // build, line 755-759 (only shown once paused with elapsed time):
  TextButton.icon(
    onPressed: () => _reset(),
    icon: const Icon(Icons.refresh),
    label: Text(l10n.intimacyReset),
  ),
  ```
- **Notes:** This is how a "stopped-and-saved" session is later cleared per
  [Intimacy](../../../../features/intimacy.md#timerstopwatch-session-persistence) — though in practice
  `_saveRecord` already clears the same fields directly on a successful save; `_reset` is the explicit
  discard-without-saving path.

### `void _ensureTicker()` <a id="ensureticker"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 358)
- **Purpose:** (Re)start the one-second periodic timer that keeps the displayed elapsed time advancing
  while the stopwatch is running.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Cancels any existing `_ticker`; starts a new `Timer.periodic` that calls
  `setState(() {})` every second.
- **Algorithm:** `_ticker?.cancel(); _ticker = Timer.periodic(const Duration(seconds: 1), (_) =>
  setState(() {}));` — the callback does no work beyond forcing a rebuild; the actual elapsed value
  always comes from the wall-clock `_elapsed` getter, not from a counter incremented by this timer.
- **Usage:**
  ```dart
  // _start, line 267:
  _ensureTicker();

  // initState, line 149 (restoring a running session):
  if (_running) _ensureTicker();
  ```
- **Notes:** Because the ticker only triggers a redraw and never itself tracks time, missed ticks
  (e.g. while the app was suspended) cause no drift — the next tick simply redraws the correct
  wall-clock-derived elapsed time.

### `IntimacyTimerSession? get _timerSession` <a id="timersession"></a>
- **Kind:** getter of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 377)
- **Purpose:** Build the persistable snapshot of the current stopwatch state for `_persistState`/the
  page's `TimerPageResult`.
- **Inputs:** None (reads the timer fields plus `_storedThrustCount`/`_storedThrustCountUnit`).
- **Returns:** `IntimacyTimerSession?` — `null` when there is no session to restore.
- **Side effects:** None.
- **Algorithm:** If `_firstStartedAt == null`, return `null` (nothing to restore — the "stopped and
  cleared" state). Otherwise construct an `IntimacyTimerSession` with `firstStartedAt`, `startedAt:
  _running ? _startedAt : null`, `accumulated`, `running: _running`, and the current
  `_storedThrustCount`/`_storedThrustCountUnit`.
- **Usage:**
  ```dart
  // _persistState, line 406:
  session: _timerSession,

  // _popWithHistoryIfChanged, line 427:
  updatedTimerSession: _timerSession,
  ```
- **Notes:** A paused session's `startedAt` is explicitly `null` in the snapshot even though
  `_startedAt` may still hold a stale in-memory value from before the pause — the getter always derives
  `startedAt` from the current `_running` flag rather than reusing whatever `_startedAt` happens to
  contain.

### `Future<void> _persistState({bool historyChanged = false, bool timerSessionChanged = false, bool retentionChanged = false})` <a id="persiststate"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 395)
- **Purpose:** Bridge every timer-affecting action to the caller's persistence callback, only when
  something actually changed.
- **Inputs:** Three independent change flags for history, timer session, and retention.
- **Returns:** `Future<void>`.
- **Side effects:** Updates the corresponding `_historyChanged`/`_timerSessionChanged`/
  `_retentionChanged` sticky flags (used later by `_popWithHistoryIfChanged`); calls
  `widget.onStateChanged(...)`.
- **Algorithm:**
  1. OR each passed-in flag into its corresponding sticky field (once set, a flag stays set for the
     rest of the page's lifetime, even across multiple calls).
  2. If none of the three flags are true for *this* call, return without invoking the callback at all
     (avoids a no-op write).
  3. Otherwise `await widget.onStateChanged(history: _history, session: _timerSession, historyChanged:
     historyChanged, timerSessionChanged: timerSessionChanged, retentionDays: _retentionDays,
     retentionChanged: retentionChanged)` — note the callback receives this call's own flags, not the
     sticky accumulated ones.
- **Usage:**
  ```dart
  // _start, line 269:
  await _persistState(timerSessionChanged: true);

  // views/intimacy_page.dart's _saveTimerState (the onStateChanged implementation), consumed via:
  onStateChanged: _saveTimerState,
  ```
- **Notes:** This is what makes "state is written on user actions, not every displayed timer tick"
  true — the once-a-second `_ensureTicker` callback never calls `_persistState`, only the discrete
  actions (`_start`, `_pause`, `_changeThrustCount`, `_reset`, `_saveRecord`,
  `_confirmRestoreHistory`, the retention picker) do.

### `void _popWithHistoryIfChanged()` <a id="popwithhistoryifchanged"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 421)
- **Purpose:** Close the page, returning a `TimerPageResult` only if there's actually something for
  the caller to persist.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** `Navigator.pop`, with or without a `TimerPageResult` argument.
- **Algorithm:** If any of `_historyChanged`/`_timerSessionChanged`/`_retentionChanged` is true, pop
  with a `TimerPageResult` carrying `_history`, `_timerSession`, `_retentionDays`, and the three change
  flags; otherwise pop with no result at all.
- **Usage:**
  ```dart
  // build, line 593-598 (PopScope intercepts the back gesture/button):
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      _popWithHistoryIfChanged();
    },
    ...
  );
  ```
- **Notes:** `canPop: false` plus this handler is what lets the page intercept every pop attempt
  (system back gesture included) and guarantee a dirty session is never silently discarded on the way
  out — this is a second, page-level safety net alongside `_saveRecord`'s explicit save flow.

### `Future<void> _saveRecord({TimerHistoryEntry? prefillEntry})` <a id="saverecord"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 446)
- **Purpose:** Turn the current stopwatch (or a re-opened history entry) into an `IntimacyRecord`,
  via `AddRecordDialog`.
- **Inputs:** `prefillEntry` — when non-null, save from an existing history entry instead of the live
  timer (tapping a history row rather than the Stop/Save button).
- **Returns:** `Future<void>`.
- **Side effects:** May pause the live timer; may insert a new history entry and persist it; opens
  `AddRecordDialog`; on a successful save, may clear the live timer session and persist that; pops the
  page with a `TimerPageResult`.
- **Algorithm:**
  1. Resolve `elapsed`/`prefillThrustCount`/`prefillThrustCountUnit`/`sessionStart` from
     `prefillEntry` if given, otherwise from the live `_elapsed`/`_storedThrustCount`/
     `_storedThrustCountUnit`/`_sessionStartTime` (falling back to `DateTime.now().subtract(elapsed)`
     if there's no recorded start).
  2. If `prefillEntry == null`, `await _pause()` first (stop the live timer cleanly).
  3. If `prefillEntry == null`, build a new `TimerHistoryEntry` from the live session, insert it at
     the front of `_history`, re-apply retention, mark history changed, and `await
     _persistState(historyChanged: true)` — so the history row exists even if the user then cancels
     the record dialog.
  4. `await showDialog<IntimacyRecord>(... AddRecordDialog(prefillDuration: elapsed,
     initialThrustCount: prefillThrustCount > 0 ? prefillThrustCount : null, ...))`.
  5. If a record was returned: if this was a live-timer save (`prefillEntry == null`), clear every
     timer field to its reset state and `await _persistState(timerSessionChanged: true)` — a
     history-prefill save leaves the live timer untouched.
  6. Pop with a `TimerPageResult` carrying the record, updated history, updated (possibly now-null)
     timer session, and the corresponding change flags.
- **Usage:**
  ```dart
  // build, line 719-722 (Stop & Save while running):
  FilledButton.icon(
    onPressed: () => _saveRecord(),
    icon: const Icon(Icons.stop),
    label: Text(l10n.intimacyStopSave),
  ),

  // build, line 823 (tapping a history row to re-save it):
  onTap: () => _saveRecord(prefillEntry: entry),
  ```
- **Notes:** Step 3's early persist of the history entry (before the dialog even opens) means a
  history row for this session exists even if the user backs out of `AddRecordDialog` without
  completing it — only the record itself is lost, not the timer's history trace.

### `String _formatDuration(Duration d)` <a id="formatduration"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 519)
- **Purpose:** Format a duration as a zero-padded `HH:MM:SS` string for the main timer display and
  history rows.
- **Inputs:** `d` — the duration to format.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** `hours = d.inHours` (unbounded, not mod-24), `minutes = d.inMinutes % 60`, `seconds =
  d.inSeconds % 60`, each `padLeft(2, '0')`, joined with `:`.
- **Usage:**
  ```dart
  // build, line 626 (the big display) and line 812 (each history row):
  Text(_formatDuration(_elapsed), ...),
  Text(_formatDuration(entry.duration), ...),
  ```
- **Notes:** `hours` is not wrapped modulo 24, so a session over a day long (however unlikely) would
  display e.g. `26:14:03` rather than wrapping to `02:14:03`.

### `Future<void> _confirmRestoreHistory(TimerHistoryEntry entry)` <a id="confirmrestorehistory"></a>
- **Kind:** method of `_TimerPageState`
- **Source:** `lib/features/intimacy/widgets/timer_page.dart` (line 539)
- **Purpose:** Let the user turn a saved history entry back into a live running stopwatch, after
  confirmation.
- **Inputs:** `entry` — the history entry to restore.
- **Returns:** `Future<void>`.
- **Side effects:** Opens a confirmation `AlertDialog`; removes `entry` from `_history`; overwrites
  every live timer field; restarts the ticker; persists both history and timer-session changes.
- **Algorithm:**
  1. Show a yes/no `AlertDialog`; return if the user didn't confirm, or the widget was unmounted while
     awaiting.
  2. Cancel the current ticker (whatever the live timer's prior state was).
  3. Inside `setState`: remove `entry` from `_history`, mark `_historyChanged`; set `_firstStartedAt =
     entry.start`, `_startedAt = DateTime.now()` (a fresh resume point), `_accumulated =
     entry.duration` (the entry's saved elapsed time becomes the new accumulated base), `_running =
     true`; restore `_thrustCount` via `_actualThrustCount(entry.thrustCount,
     entry.thrustCountUnit)`; mark `_timerSessionChanged`.
  4. `_ensureTicker()`; `await _persistState(historyChanged: true, timerSessionChanged: true)`.
- **Usage:**
  ```dart
  // build, line 824-828 (the restore icon on each history row):
  IconButton(
    tooltip: l10n.intimacyTimerRestore,
    icon: const Icon(Icons.restore, size: 20),
    onPressed: () => _confirmRestoreHistory(entry),
  ),
  ```
- **Notes:** Matches
  [Intimacy](../../../../features/intimacy.md#timerstopwatch-session-persistence): "History rows can
  be confirmed and restored as running sessions, which removes that history row." The source comment
  on the confirmation dialog notes "any current running timer keeps ticking while the confirmation
  dialog is open" — the live timer isn't paused just because a restore is being considered.

## Related pages

- [Intimacy — Timer/stopwatch session persistence](../../../../features/intimacy.md#timerstopwatch-session-persistence) —
  the running/paused/stopped recovery contract, the x100/x1 thrust-count storage rule, and the
  keep-screen-awake preference this file implements in full.
- [`add_record_dialog.dart`](add_record_dialog.md) — `AddRecordDialog`, opened by `_saveRecord` and
  pre-filled from the finished (or re-opened) stopwatch session.
- `shared/services/sync_wake_lock.dart` — the independent, reference-counted wakelock used by
  foreground sync operations; `_applyWakelock`/`_releaseWakelock` here never interferes with it
  because each tracks its own "did I enable this" flag.

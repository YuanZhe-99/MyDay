# lib/features/intimacy/utils/thrust_timeline.dart

The thrust timeline (v1.5.5): the chronological list of thrust-counter presses made during one
stopwatch session, as described in
[Intimacy — Timer/stopwatch session persistence](../../../../features/intimacy.md#timerstopwatch-session-persistence).
`ThrustEvent` is one press (`elapsedMs`, `delta`); `ThrustTimeline` is an immutable, time-ordered
list of them whose `total` is the session's actual repetition count. The timer page
([`timer_page.dart`](../widgets/timer_page.md)) derives its live counter from the timeline, records
presses with [`add`](#add) and the `-100` button with [`undo`](#undo); the three models in
[`intimacy_record.dart`](../models/intimacy_record.md) persist it under the `thrustTimeline` key via
[`toJson`](#tojson)/[`fromJson`](#fromjson); and
[`ThrustTimelineChart`](../widgets/thrust_timeline_chart.md) draws it from
[`cumulativeSpots`](#cumulativespots) and [`smoothedSpots`](#smoothedspots). The file imports only
`fl_chart` (for `FlSpot`) and has no other Flutter dependency, so every rule is unit-tested in
`test/thrust_timeline_test.dart`.

Invariants, held by every method that builds a new timeline: events are ordered by `elapsedMs`,
every `delta` is positive, and so the cumulative count over time is **never decreasing**.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ThrustEvent(elapsedMs, delta)` | constructor (`ThrustEvent`) | B | Create one thrust-count event. |
| `operator ==` | operator (`ThrustEvent`) | B | Compare two events by value (both fields). |
| `hashCode` | getter (`ThrustEvent`) | B | Hash an event consistently with `==`. |
| `toString` | method (`ThrustEvent`) | B | Describe the event as `+<delta>@<elapsedMs>ms` for debugging and test failures. |
| `ThrustTimeline(events)` | constructor (`ThrustTimeline`) | B | Wrap already-valid events in an unmodifiable list, without validation. |
| `ThrustTimeline.empty` | factory constructor (`ThrustTimeline`) | B | Return a timeline with no presses. |
| [`ThrustTimeline.seed`](#seed) | factory constructor (`ThrustTimeline`) | A | Build a one-event timeline from a count that has no press times. |
| [`total`](#total) | getter (`ThrustTimeline`) | A | Return the total repetitions recorded (sum of deltas). |
| `isEmpty` | getter (`ThrustTimeline`) | B | Report whether no presses are recorded. |
| `lastElapsedMs` | getter (`ThrustTimeline`) | B | Return the stopwatch time of the latest press, or 0 when empty. |
| [`add`](#add) | method (`ThrustTimeline`) | A | Record a press that adds repetitions. |
| [`undo`](#undo) | method (`ThrustTimeline`) | A | Undo the most recent presses until exactly `amount` is removed. |
| [`toJson`](#tojson) | method (`ThrustTimeline`) | A | Serialize the timeline as `[[elapsedMs, delta], ...]`. |
| [`fromJson`](#fromjson) | static method (`ThrustTimeline`) | A | Read a timeline from JSON without ever throwing. |
| [`cumulativeSpots`](#cumulativespots) | method (`ThrustTimeline`) | A | Build the cumulative step series for the record chart. |
| [`smoothedSpots`](#smoothedspots) | method (`ThrustTimeline`) | A | Build the smoothed (moving-average) fit line for the record chart. |
| `_sortByTime` | top-level function (private) | B | Stable insertion sort of events by time, in place. |

`grep -c 'Purpose:' lib/features/intimacy/utils/thrust_timeline.dart` reports 17, matching all 17
rows above exactly (8 Tier A, 9 Tier B). The two static constants `ThrustTimeline.jsonKey`
(`'thrustTimeline'`, the JSON key used by the record, the timer history entry and the timer
session) and `ThrustTimeline.maxTotal` (`999999`, the timer counter's previous clamp) carry plain
`///` comments rather than `Purpose:` blocks and get no rows, consistent with how the other
intimacy pages treat class-level constants; they are described in the entries that use them. The
`ThrustEvent` fields `elapsedMs` and `delta` and the `events` list are plain data holders.

## Documentation

### `factory ThrustTimeline.seed(int elapsedMs, int count)` <a id="seed"></a>
- **Kind:** factory constructor of `ThrustTimeline`
- **Source:** `lib/features/intimacy/utils/thrust_timeline.dart` (line 83)
- **Purpose:** Turn a bare total — data that never had press times — into a timeline.
- **Inputs:** `elapsedMs` — where to place the event; `count` — actual repetitions.
- **Returns:** `ThrustTimeline` — empty when `count <= 0`, otherwise exactly one event.
- **Side effects:** None.
- **Algorithm:** `count <= 0` returns `ThrustTimeline.empty()`; otherwise one
  `ThrustEvent(max(elapsedMs, 0), count.clamp(1, maxTotal))`.
- **Usage:**
  ```dart
  // timer_page.dart, _restoreTimeline, line 150:
  return ThrustTimeline.seed(elapsed.inMilliseconds, actual);
  ```
- **Notes:** Used for timer sessions and history entries saved before v1.5.5, which stored only a
  total, and for a stored timeline whose total disagrees with the stored count. A single event
  never draws a chart (the chart and `IntimacyRecord.hasThrustTimeline` need at least two), so
  seeded data shows the same count as before and no curve.

### `int get total` <a id="total"></a>
- **Kind:** getter of `ThrustTimeline`
- **Source:** `lib/features/intimacy/utils/thrust_timeline.dart` (line 95)
- **Purpose:** Return the session's actual repetition count.
- **Inputs:** None.
- **Returns:** `int` — the sum of every event's `delta`.
- **Side effects:** None.
- **Algorithm:** `events.fold(0, (sum, e) => sum + e.delta)`.
- **Usage:**
  ```dart
  // timer_page.dart, line 131 — the live counter is derived, never stored separately:
  int get _thrustCount => _timeline.total;

  // add_record_dialog.dart, _submit, line 546 — keep the timeline only if it still matches:
  final timeline = _timeline != null && _timeline.total == resolvedCount ? _timeline : null;
  ```
- **Notes:** Because the timer's counter is this getter, the count shown and the curve drawn from
  the same timeline can never disagree.

### `ThrustTimeline add(int elapsedMs, int delta)` <a id="add"></a>
- **Kind:** method of `ThrustTimeline`
- **Source:** `lib/features/intimacy/utils/thrust_timeline.dart` (line 118)
- **Purpose:** Record one `+100`/`+50`/`+10` press at the current stopwatch time.
- **Inputs:** `elapsedMs` — stopwatch time of the press; `delta` — repetitions to add.
- **Returns:** `ThrustTimeline` — a new timeline, or `this` (identical) when nothing changes.
- **Side effects:** None.
- **Algorithm:**
  1. `delta <= 0`, or `total + delta > maxTotal`, returns `this` — the press is ignored.
  2. `at = max(elapsedMs, lastElapsedMs)` (and never below 0), so the list stays ordered even if
     the stopwatch was restored with less elapsed time than the latest press.
  3. Return a new timeline with `ThrustEvent(at, delta)` appended.
- **Usage:**
  ```dart
  // timer_page.dart, _changeThrustCount, lines 327-329:
  final next = delta < 0
      ? _timeline.undo(-delta)
      : _timeline.add(_elapsed.inMilliseconds, delta);
  if (identical(next, _timeline)) return;
  ```
- **Notes:** Returning `this` on a no-op is what lets the timer page skip the `setState` and the
  persistence write with an `identical` check. A press that would pass `maxTotal` is dropped whole;
  the pre-1.5.5 counter clamped the sum instead.

### `ThrustTimeline undo(int amount)` <a id="undo"></a>
- **Kind:** method of `ThrustTimeline`
- **Source:** `lib/features/intimacy/utils/thrust_timeline.dart` (line 134)
- **Purpose:** Implement the timer's `-100` button as an undo of the most recent presses.
- **Inputs:** `amount` — repetitions to remove (100 from the timer).
- **Returns:** `ThrustTimeline` — a new timeline, or `this` when `amount <= 0` or the timeline is
  empty.
- **Side effects:** None.
- **Algorithm:** Copy the events; `remaining = amount`; while `remaining > 0` and events remain,
  remove the last event: if its `delta <= remaining`, subtract it and continue; otherwise put back
  `ThrustEvent(last.elapsedMs, last.delta - remaining)` and stop.
- **Usage:** `_timeline.undo(-delta)` from `_changeThrustCount` (see [`add`](#add)).
- **Notes:** Exactly `amount` is removed whenever the total allows it. Whole presses are removed
  from the end while they fit; the press that does not fit is **trimmed (split)** rather than
  removed, keeping its original time. Examples: `+50, +10, +50` minus 100 removes the last `+50`
  and the `+10` (60), then trims the first `+50` by the remaining 40, leaving a single `+10` at the
  **first** press's time; `+100, +50, +50` minus 100 leaves the `+100`; `+10, +150` minus 100
  leaves `+10, +50`. When the total is below `amount`, everything is removed. Deltas stay positive,
  so the cumulative curve stays non-decreasing. `test/thrust_timeline_test.dart` checks these cases,
  and the totals against a plain clamped counter over random press sequences.

### `List<List<int>> toJson()` <a id="tojson"></a>
- **Kind:** method of `ThrustTimeline`
- **Source:** `lib/features/intimacy/utils/thrust_timeline.dart` (line 155)
- **Purpose:** Serialize the timeline for `intimacy_data.json`.
- **Inputs:** None.
- **Returns:** `List<List<int>>` — `[[elapsedMs, delta], ...]`, oldest first.
- **Side effects:** None.
- **Algorithm:** One two-element list per event.
- **Usage:**
  ```dart
  // intimacy_record.dart, IntimacyRecord.toJson, lines 565-566 (same shape in the other two models):
  if (thrustTimeline != null)
    ThrustTimeline.jsonKey: thrustTimeline!.toJson(),
  ```
- **Notes:** Callers omit the key entirely when there is no timeline; the models normalize an empty
  timeline to `null`, so `[]` is never written. Format in
  [Data Formats](../../../../data-formats.md#intimacy--intimacy_datajson).

### `static ThrustTimeline? fromJson(Object? raw)` <a id="fromjson"></a>
- **Kind:** static method of `ThrustTimeline`
- **Source:** `lib/features/intimacy/utils/thrust_timeline.dart` (line 166)
- **Purpose:** Read the `thrustTimeline` value from JSON, tolerating damage.
- **Inputs:** `raw` — the decoded value of the key, or `null`.
- **Returns:** `ThrustTimeline?` — `null` when absent, not a list, or left with no valid pair.
- **Side effects:** None.
- **Algorithm:**
  1. `raw is! List` returns `null`.
  2. For each item: skip anything that is not a list of at least two numbers; truncate both with
     `toInt()`; skip a negative time or a non-positive delta.
  3. No survivors returns `null`; otherwise `_sortByTime` (a stable insertion sort, so equal-time
     presses keep their recorded order) and wrap.
- **Usage:**
  ```dart
  // intimacy_record.dart, IntimacyRecord.fromJson, line 603:
  thrustTimeline: ThrustTimeline.fromJson(json[ThrustTimeline.jsonKey]),
  ```
- **Notes:** Never throws: a damaged timeline must never make the whole data file unreadable. It
  does not check the total against the record's count — `AddRecordDialog._submit` enforces that on
  write, and the timer page re-seeds on restore when they disagree.

### `List<FlSpot> cumulativeSpots({required int durationMs})` <a id="cumulativespots"></a>
- **Kind:** method of `ThrustTimeline`
- **Source:** `lib/features/intimacy/utils/thrust_timeline.dart` (line 190)
- **Purpose:** Build the raw cumulative count series the chart draws as a step line.
- **Inputs:** `durationMs` — the record's duration, used to extend the last step.
- **Returns:** `List<FlSpot>` — x in minutes, y in cumulative repetitions.
- **Side effects:** None.
- **Algorithm:** Start at `(0, 0)`; add one point per event at `(elapsedMs / 60000, running
  total)`; if `durationMs > lastElapsedMs`, add a final `(durationMs / 60000, total)` so the last
  plateau reaches the end of the session.
- **Usage:**
  ```dart
  // thrust_timeline_chart.dart, build, line 76:
  final raw = timeline.cumulativeSpots(durationMs: durationMs);
  ```
- **Notes:** Meant for `LineChartBarData(isStepLineChart: true)`: each point holds its value until
  the next, so the line is flat between presses and jumps at each one.

### `List<FlSpot> smoothedSpots({required int durationMs, int samples = 60, double windowFraction = 0.10})` <a id="smoothedspots"></a>
- **Kind:** method of `ThrustTimeline`
- **Source:** `lib/features/intimacy/utils/thrust_timeline.dart` (line 214)
- **Purpose:** Build the smoothed fit line drawn dashed over the step line.
- **Inputs:** `durationMs` — the record's duration; `samples` — resample points (60);
  `windowFraction` — moving-average window as a share of the time span (0.10).
- **Returns:** `List<FlSpot>` — x in minutes; empty with fewer than two events, fewer than two
  samples, or a zero span.
- **Side effects:** None.
- **Algorithm:**
  1. `span = max(durationMs, lastElapsedMs)`; `times[i] = span * i / (samples - 1)`.
  2. Resample the cumulative step function: `values[i]` is the sum of every delta whose
     `elapsedMs <= times[i]`.
  3. Centred moving average with edge-truncated windows: `half = round(samples * windowFraction /
     2)` clamped to `[1, samples]` — 3 samples at the defaults, a 7-sample window — and
     `smoothed[i]` is the mean of `values[max(0, i-half) .. min(samples-1, i+half)]`.
  4. Pin the ends: `smoothed[0] = 0`, `smoothed[last] = total`.
- **Usage:**
  ```dart
  // thrust_timeline_chart.dart, build, line 77:
  final smooth = timeline.smoothedSpots(durationMs: durationMs);
  ```
- **Notes:** The result is provably **non-decreasing**: the resampled series is non-decreasing, and
  sliding a window one step either swaps its oldest value for a later, not smaller one, or (at an
  edge, where the window grows or shrinks) adds a value at least as large as the window's mean or
  drops its smallest. Pinning the first point to 0 and the last to `total` keeps that, because
  every mean lies between 0 and `total`. So the fit line never falls, which a curve fitted any other
  way (a spline through the presses, a polynomial) could not promise.

## Related pages

- [Intimacy — Timer/stopwatch session persistence](../../../../features/intimacy.md#timerstopwatch-session-persistence) —
  the user-facing rules: press timestamps, the undo-and-split `-100`, pre-1.5.5 seeding, and the
  chart.
- [`timer_page.dart`](../widgets/timer_page.md) — the only writer of timelines: `_changeThrustCount`,
  `_restoreTimeline`, `_saveRecord`.
- [`intimacy_record.dart`](../models/intimacy_record.md) — the three models that carry a
  `thrustTimeline`, and `IntimacyRecord.hasThrustTimeline`.
- [`add_record_dialog.dart`](../widgets/add_record_dialog.md) — keeps a timeline on save only while
  its total equals the entered count.
- [`thrust_timeline_chart.dart`](../widgets/thrust_timeline_chart.md) — draws the two series.
- [Data Formats](../../../../data-formats.md#intimacy--intimacy_datajson) — the JSON shape.

import 'package:fl_chart/fl_chart.dart';

/// One press of a timer thrust-count button.
class ThrustEvent {
  /// Stopwatch elapsed time at the press, in milliseconds.
  final int elapsedMs;

  /// Repetitions added by the press. Always positive.
  final int delta;

  /// Purpose: Create one thrust-count event.
  /// Inputs: `elapsedMs` — stopwatch time of the press; `delta` — repetitions added.
  /// Returns: A new `ThrustEvent` instance.
  /// Side effects: None.
  /// Notes: Callers keep `elapsedMs >= 0` and `delta > 0`; `ThrustTimeline`
  /// enforces both.
  const ThrustEvent(this.elapsedMs, this.delta);

  /// Purpose: Compare two events by value.
  /// Inputs: `other`.
  /// Returns: `bool` — true when both fields match.
  /// Side effects: None.
  /// Notes: Lets tests and the timer page detect no-op changes.
  @override
  bool operator ==(Object other) =>
      other is ThrustEvent &&
      other.elapsedMs == elapsedMs &&
      other.delta == delta;

  /// Purpose: Hash an event consistently with `==`.
  /// Inputs: None.
  /// Returns: `int`.
  /// Side effects: None.
  /// Notes: None.
  @override
  int get hashCode => Object.hash(elapsedMs, delta);

  /// Purpose: Describe the event for debugging and test failures.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: None.
  @override
  String toString() => '+$delta@${elapsedMs}ms';
}

/// The chronological list of thrust-count presses made during one timer session.
///
/// Invariants: events are ordered by `elapsedMs`, every `delta` is positive, and
/// [total] (the sum of deltas) is the session's actual repetition count. The
/// cumulative count over time is therefore never decreasing.
class ThrustTimeline {
  /// JSON key used by the record, timer history entry and timer session.
  static const String jsonKey = 'thrustTimeline';

  /// Largest total the timer counter allows, matching its previous clamp.
  static const int maxTotal = 999999;

  /// The presses, oldest first. Unmodifiable.
  final List<ThrustEvent> events;

  /// Purpose: Create a timeline from already-valid events.
  /// Inputs: `events` — ordered events with positive deltas.
  /// Returns: A new `ThrustTimeline` instance.
  /// Side effects: None.
  /// Notes: Use [fromJson] for untrusted input; this constructor does not
  /// validate.
  ThrustTimeline(List<ThrustEvent> events) : events = List.unmodifiable(events);

  /// Purpose: Return a timeline with no presses.
  /// Inputs: None.
  /// Returns: An empty `ThrustTimeline`.
  /// Side effects: None.
  /// Notes: None.
  factory ThrustTimeline.empty() => ThrustTimeline(const []);

  /// Purpose: Build a one-event timeline from a count that has no press times.
  /// Inputs: `elapsedMs` — when to place the event; `count` — actual repetitions.
  /// Returns: `ThrustTimeline` — empty when `count <= 0`.
  /// Side effects: None.
  /// Notes: Used for timer sessions and history entries saved before v1.5.5,
  /// which only stored a total. One event never draws a chart.
  factory ThrustTimeline.seed(int elapsedMs, int count) {
    if (count <= 0) return ThrustTimeline.empty();
    return ThrustTimeline([
      ThrustEvent(elapsedMs < 0 ? 0 : elapsedMs, count.clamp(1, maxTotal)),
    ]);
  }

  /// Purpose: Return the total repetitions recorded.
  /// Inputs: None.
  /// Returns: `int` — the sum of every event's delta.
  /// Side effects: None.
  /// Notes: The timer page derives its live counter from this.
  int get total => events.fold(0, (sum, e) => sum + e.delta);

  /// Purpose: Report whether no presses are recorded.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  bool get isEmpty => events.isEmpty;

  /// Purpose: Return the stopwatch time of the latest press.
  /// Inputs: None.
  /// Returns: `int` — milliseconds, or 0 when empty.
  /// Side effects: None.
  /// Notes: None.
  int get lastElapsedMs => events.isEmpty ? 0 : events.last.elapsedMs;

  /// Purpose: Record a press that adds repetitions.
  /// Inputs: `elapsedMs` — stopwatch time of the press; `delta` — repetitions to add.
  /// Returns: `ThrustTimeline` — a new timeline, or `this` when nothing changes.
  /// Side effects: None.
  /// Notes: `elapsedMs` is raised to the latest event's time so the list stays
  /// ordered even if the stopwatch was restored with less elapsed time. A press
  /// that would pass [maxTotal] is ignored.
  ThrustTimeline add(int elapsedMs, int delta) {
    if (delta <= 0 || total + delta > maxTotal) return this;
    final at = elapsedMs < lastElapsedMs ? lastElapsedMs : elapsedMs;
    return ThrustTimeline([...events, ThrustEvent(at < 0 ? 0 : at, delta)]);
  }

  /// Purpose: Undo the most recent presses until exactly `amount` is removed.
  /// Inputs: `amount` — repetitions to remove (100 for the timer's −100 button).
  /// Returns: `ThrustTimeline` — a new timeline, or `this` when nothing changes.
  /// Side effects: None.
  /// Notes: Whole events are removed from the end while they fit in what is
  /// left to remove. An event larger than the remainder is trimmed instead, so
  /// `+50, +10, +50` minus 100 removes the last two presses and trims the
  /// first to `+10`, which keeps the first press's time.
  /// When the total is below `amount` everything is removed. Deltas stay
  /// positive, so the cumulative curve stays non-decreasing.
  ThrustTimeline undo(int amount) {
    if (amount <= 0 || events.isEmpty) return this;
    final out = List<ThrustEvent>.of(events);
    var remaining = amount;
    while (remaining > 0 && out.isNotEmpty) {
      final last = out.removeLast();
      if (last.delta <= remaining) {
        remaining -= last.delta;
      } else {
        out.add(ThrustEvent(last.elapsedMs, last.delta - remaining));
        remaining = 0;
      }
    }
    return ThrustTimeline(out);
  }

  /// Purpose: Serialize the timeline for `intimacy_data.json`.
  /// Inputs: None.
  /// Returns: `List<List<int>>` — `[[elapsedMs, delta], ...]`, oldest first.
  /// Side effects: None.
  /// Notes: Callers omit the key entirely when the timeline is empty.
  List<List<int>> toJson() => [
    for (final e in events) [e.elapsedMs, e.delta],
  ];

  /// Purpose: Read a timeline from JSON without ever throwing.
  /// Inputs: `raw` — the decoded value of the `thrustTimeline` key, or null.
  /// Returns: `ThrustTimeline?` — null when absent, malformed or empty.
  /// Side effects: None.
  /// Notes: Pairs that are not two numbers, or that carry a negative time or a
  /// non-positive delta, are skipped. Survivors are sorted by time. A damaged
  /// timeline must never make the whole data file unreadable.
  static ThrustTimeline? fromJson(Object? raw) {
    if (raw is! List) return null;
    final parsed = <ThrustEvent>[];
    for (final item in raw) {
      if (item is! List || item.length < 2) continue;
      final t = item[0];
      final d = item[1];
      if (t is! num || d is! num) continue;
      final elapsedMs = t.toInt();
      final delta = d.toInt();
      if (elapsedMs < 0 || delta <= 0) continue;
      parsed.add(ThrustEvent(elapsedMs, delta));
    }
    if (parsed.isEmpty) return null;
    _sortByTime(parsed);
    return ThrustTimeline(parsed);
  }

  /// Purpose: Build the cumulative step series for the record chart.
  /// Inputs: `durationMs` — the record's duration, used to extend the last step.
  /// Returns: `List<FlSpot>` — x in minutes, y in cumulative repetitions.
  /// Side effects: None.
  /// Notes: Starts at (0, 0), adds one point per press, and ends at the
  /// duration when it is later than the last press. Meant for a step-line bar.
  List<FlSpot> cumulativeSpots({required int durationMs}) {
    final spots = <FlSpot>[const FlSpot(0, 0)];
    var c = 0;
    for (final e in events) {
      c += e.delta;
      spots.add(FlSpot(e.elapsedMs / 60000.0, c.toDouble()));
    }
    if (durationMs > lastElapsedMs) {
      spots.add(FlSpot(durationMs / 60000.0, c.toDouble()));
    }
    return spots;
  }

  /// Purpose: Build the smoothed fit line for the record chart.
  /// Inputs: `durationMs` — the record's duration; `samples` — resample points;
  /// `windowFraction` — moving-average window as a share of the time span.
  /// Returns: `List<FlSpot>` — x in minutes; empty with fewer than two presses.
  /// Side effects: None.
  /// Notes: The cumulative step function is resampled at evenly spaced times,
  /// then a centred moving average with edge-truncated windows is taken, and
  /// the ends are pinned to 0 and [total]. A moving average of a non-decreasing
  /// series is non-decreasing: each slide either swaps an old value for a later
  /// (not smaller) one, or at an edge adds a value at least as large as the
  /// window or drops its smallest. So the fit line never falls.
  List<FlSpot> smoothedSpots({
    required int durationMs,
    int samples = 60,
    double windowFraction = 0.10,
  }) {
    if (events.length < 2 || samples < 2) return const [];
    final span = durationMs > lastElapsedMs ? durationMs : lastElapsedMs;
    if (span <= 0) return const [];

    final times = List<double>.generate(
      samples,
      (i) => span * i / (samples - 1),
    );
    final values = List<double>.filled(samples, 0);
    var index = 0;
    var c = 0;
    for (var i = 0; i < samples; i++) {
      while (index < events.length && events[index].elapsedMs <= times[i]) {
        c += events[index].delta;
        index++;
      }
      values[i] = c.toDouble();
    }

    final half = (samples * windowFraction / 2).round().clamp(1, samples);
    final smoothed = List<double>.filled(samples, 0);
    for (var i = 0; i < samples; i++) {
      final lo = i - half < 0 ? 0 : i - half;
      final hi = i + half > samples - 1 ? samples - 1 : i + half;
      var sum = 0.0;
      for (var j = lo; j <= hi; j++) {
        sum += values[j];
      }
      smoothed[i] = sum / (hi - lo + 1);
    }
    smoothed[0] = 0;
    smoothed[samples - 1] = total.toDouble();

    return [
      for (var i = 0; i < samples; i++) FlSpot(times[i] / 60000.0, smoothed[i]),
    ];
  }
}

/// Purpose: Stable-sort events by time.
/// Inputs: `list` — events to sort in place.
/// Returns: None.
/// Side effects: Reorders `list`.
/// Notes: Insertion sort keeps equal-time presses in their recorded order;
/// timelines are short, so the quadratic worst case does not matter.
void _sortByTime(List<ThrustEvent> list) {
  for (var i = 1; i < list.length; i++) {
    final item = list[i];
    var j = i - 1;
    while (j >= 0 && list[j].elapsedMs > item.elapsedMs) {
      list[j + 1] = list[j];
      j--;
    }
    list[j + 1] = item;
  }
}

/// Pure menstrual-cycle prediction from recorded period start dates.
/// No Flutter imports so everything here is unit-testable.
///
/// All predictions are statistical estimates derived from the recorded
/// start dates. They must never be presented as contraception or medical
/// guidance; the UI attaches the mandatory disclaimer.
library;

/// Cycle length below this many days is treated as a data error, not a cycle.
const int minValidCycleDays = 15;

/// Cycle length above this many days is treated as a gap, not a cycle.
const int maxValidCycleDays = 90;

/// Number of most recent valid cycles considered for the median.
const int medianCycleWindow = 6;

/// Cycle length assumed when fewer than two valid records exist.
const int defaultCycleLengthDays = 28;

/// Days of menstrual bleeding assumed from each start date.
const int assumedMenstrualDays = 5;

/// Days before the next start on which ovulation is estimated.
const int ovulationOffsetDays = 14;

/// How far ahead of the anchor predictions are generated.
const int predictionHorizonDays = 366;

/// Broad phase classification for a single cycle day.
enum CyclePhase { menstrual, follicular, luteal }

/// Per-day classification produced by [predictCycle].
class CycleDayInfo {
  final CyclePhase phase;
  final bool inFertileWindow;
  final bool isOvulationDay;
  final bool isActualStart;
  final bool isPredictedStart;

  /// True for every value that is derived rather than directly recorded.
  final bool isEstimated;

  /// Purpose: Create a cycle day info value.
  /// Inputs: Phase and marker flags for one calendar day.
  /// Returns: A new `CycleDayInfo` instance.
  /// Side effects: None.
  /// Notes: Only a recorded start day itself is non-estimated.
  const CycleDayInfo({
    required this.phase,
    this.inFertileWindow = false,
    this.isOvulationDay = false,
    this.isActualStart = false,
    this.isPredictedStart = false,
    this.isEstimated = true,
  });
}

/// Prediction output for one person over a queried window.
class CyclePrediction {
  /// The cycle length in days used for forward predictions.
  final int cycleLengthDays;

  /// Predicted future start dates inside the queried window.
  final List<DateTime> predictedStarts;

  /// Per-day classification for every classified day in the window.
  final Map<DateTime, CycleDayInfo> days;

  /// Purpose: Create a cycle prediction value.
  /// Inputs: `cycleLengthDays`, `predictedStarts`, `days`.
  /// Returns: A new `CyclePrediction` instance.
  /// Side effects: None.
  /// Notes: Empty when the person has no recorded start dates.
  const CyclePrediction({
    required this.cycleLengthDays,
    required this.predictedStarts,
    required this.days,
  });

  static const empty = CyclePrediction(
    cycleLengthDays: defaultCycleLengthDays,
    predictedStarts: [],
    days: {},
  );
}

/// Purpose: Normalize a DateTime to a date-only local value.
/// Inputs: `value`.
/// Returns: `DateTime`.
/// Side effects: None.
/// Notes: All map keys produced by this library are normalized this way.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Purpose: Add calendar days to a date-only value.
/// Inputs: `day`, `count`.
/// Returns: `DateTime`.
/// Side effects: None.
/// Notes: Uses calendar arithmetic so daylight-saving transitions never
/// shift the result off midnight.
DateTime _addDays(DateTime day, int count) =>
    DateTime(day.year, day.month, day.day + count);

/// Purpose: Count whole calendar days between two date-only values.
/// Inputs: `from`, `to`.
/// Returns: `int`.
/// Side effects: None.
/// Notes: Normalizes through UTC so daylight-saving transitions cannot
/// produce off-by-one day counts.
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Purpose: Estimate the forward cycle length from recorded start dates.
/// Inputs: `sortedStarts` ascending unique date-only start dates.
/// Returns: `int`.
/// Side effects: None.
/// Notes: Median of the most recent [medianCycleWindow] valid cycles so a
/// single abnormal cycle cannot skew predictions; 28 days when no valid
/// cycle exists.
int estimateCycleLength(List<DateTime> sortedStarts) {
  final lengths = <int>[];
  for (var i = 1; i < sortedStarts.length; i++) {
    final days = _daysBetween(sortedStarts[i - 1], sortedStarts[i]);
    if (days >= minValidCycleDays && days <= maxValidCycleDays) {
      lengths.add(days);
    }
  }
  if (lengths.isEmpty) return defaultCycleLengthDays;
  final recent = lengths.length > medianCycleWindow
      ? lengths.sublist(lengths.length - medianCycleWindow)
      : lengths;
  final sorted = List<int>.of(recent)..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return ((sorted[mid - 1] + sorted[mid]) / 2).round();
}

/// Purpose: Predict cycle phases and future starts for one person.
/// Inputs: `actualStarts` recorded start dates (any order, duplicates
/// tolerated), plus the inclusive `windowStart`..`windowEnd` query range.
/// Returns: `CyclePrediction`.
/// Side effects: None.
/// Notes: The latest recorded start is the anchor; adding or deleting a
/// record re-derives everything instead of shifting old predictions.
/// Historical segments between two recorded starts are classified too, so
/// past months render phases.
CyclePrediction predictCycle({
  required Iterable<DateTime> actualStarts,
  required DateTime windowStart,
  required DateTime windowEnd,
}) {
  final starts = actualStarts.map(dateOnly).toSet().toList()..sort();
  if (starts.isEmpty) return CyclePrediction.empty;

  final cycleLength = estimateCycleLength(starts);
  final anchor = starts.last;
  final horizon = _addDays(anchor, predictionHorizonDays);

  // Build the forward prediction chain from the anchor.
  final predictedStarts = <DateTime>[];
  var next = _addDays(anchor, cycleLength);
  while (!next.isAfter(horizon)) {
    predictedStarts.add(next);
    next = _addDays(next, cycleLength);
  }

  // Segment boundaries: every recorded start plus the prediction chain.
  final allStarts = [...starts, ...predictedStarts];
  final actualSet = starts.toSet();
  final predictedSet = predictedStarts.toSet();

  final windowStartDay = dateOnly(windowStart);
  final windowEndDay = dateOnly(windowEnd);
  final days = <DateTime, CycleDayInfo>{};

  for (var i = 0; i < allStarts.length; i++) {
    final segStart = allStarts[i];
    var segNext = i + 1 < allStarts.length ? allStarts[i + 1] : null;
    // Without a following start there is no cycle end to derive phases
    // from, so only the assumed menstrual days are classified. A gap
    // longer than a valid cycle is treated the same way instead of
    // painting months of misleading phases.
    if (segNext != null && _daysBetween(segStart, segNext) > maxValidCycleDays) {
      segNext = null;
    }
    final segLength = segNext != null ? _daysBetween(segStart, segNext) : null;
    final menstrualDays = segLength == null
        ? assumedMenstrualDays
        : (segLength < assumedMenstrualDays ? segLength : assumedMenstrualDays);
    final ovulation = segNext != null
        ? _addDays(segNext, -ovulationOffsetDays)
        : null;
    // Skip the ovulation estimate when the segment is too short for it to
    // land after the menstrual phase.
    final ovulationValid =
        ovulation != null && _daysBetween(segStart, ovulation) >= menstrualDays;

    final segDayCount = segLength ?? menstrualDays;
    for (var offset = 0; offset < segDayCount; offset++) {
      final day = _addDays(segStart, offset);
      if (day.isBefore(windowStartDay) || day.isAfter(windowEndDay)) continue;

      final isStart = offset == 0;
      final isActual = isStart && actualSet.contains(day);
      final isPredicted = isStart && !isActual && predictedSet.contains(day);

      CyclePhase phase;
      var isOvulationDay = false;
      var inFertileWindow = false;
      if (offset < menstrualDays) {
        phase = CyclePhase.menstrual;
      } else if (ovulationValid) {
        final untilOvulation = _daysBetween(day, ovulation);
        if (untilOvulation > 0) {
          phase = CyclePhase.follicular;
        } else if (untilOvulation == 0) {
          phase = CyclePhase.follicular;
          isOvulationDay = true;
        } else {
          phase = CyclePhase.luteal;
        }
        // Fertile window: 5 days before ovulation through 1 day after.
        inFertileWindow = untilOvulation <= 5 && untilOvulation >= -1;
      } else {
        phase = CyclePhase.follicular;
      }

      days[day] = CycleDayInfo(
        phase: phase,
        inFertileWindow: inFertileWindow,
        isOvulationDay: isOvulationDay,
        isActualStart: isActual,
        isPredictedStart: isPredicted,
        isEstimated: !isActual,
      );
    }
  }

  return CyclePrediction(
    cycleLengthDays: cycleLength,
    predictedStarts: predictedStarts
        .where(
          (d) => !d.isBefore(windowStartDay) && !d.isAfter(windowEndDay),
        )
        .toList(),
    days: days,
  );
}

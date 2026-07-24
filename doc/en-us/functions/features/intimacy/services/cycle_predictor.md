# lib/features/intimacy/services/cycle_predictor.dart

Pure Dart, no Flutter imports: median-based menstrual-cycle-length estimation and full phase/
fertile-window/ovulation prediction from recorded period start dates only. `widgets/body_section.dart`
and `views/intimacy_page.dart` are the two callers — one per-person in the Body tab's cycle calendar,
one for the home-page multi-person overlay. All predictions are statistical estimates; they are never
presented as contraception or medical guidance, and the UI attaches the mandatory disclaimer (see
[Intimacy](../../../../features/intimacy.md#the-body-layer-v124)). See
[Body Metrics — Cycle prediction](../../../../algorithms/body-metrics.md#cycle-prediction) for the
full walkthrough of the algorithm this file implements.

## Declarations

Anchor note: every name in this file is unique, so all Tier A rows use the plain bare-name anchor
with no class qualifier.

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `minValidCycleDays` | top-level constant | B | `15` — a gap shorter than this is a data error, not a cycle. |
| `maxValidCycleDays` | top-level constant | B | `90` — a gap longer than this is an untracked gap, not a cycle. |
| `medianCycleWindow` | top-level constant | B | `6` — only the most recent 6 valid cycle lengths feed the median. |
| `defaultCycleLengthDays` | top-level constant | B | `28` — used when fewer than two valid records exist. |
| `assumedMenstrualDays` | top-level constant | B | `5` — days of bleeding assumed from each start date. |
| `ovulationOffsetDays` | top-level constant | B | `14` — days before the next start ovulation is estimated at. |
| `predictionHorizonDays` | top-level constant | B | `366` — how far ahead of the anchor predictions are generated. |
| `CyclePhase` (enum) | enum | B | `menstrual` / `follicular` / `luteal` — no Purpose block (see Reconciliation). |
| [`CycleDayInfo()`](#cycledayinfo-new) | constructor (`CycleDayInfo`) | A | Create a per-day cycle classification value (phase and marker flags). |
| [`CyclePrediction()`](#cycleprediction-new) | constructor (`CyclePrediction`) | A | Create a prediction-output value (cycle length, predicted starts, per-day map). |
| `CyclePrediction.empty` | static constant (`CyclePrediction`) | B | The zero-records fallback prediction (default cycle length, no starts, no days). |
| [`dateOnly`](#dateonly) | top-level function | A | Normalize a `DateTime` to a date-only local value. |
| [`_addDays`](#_adddays) | private top-level function | A | Add calendar days to a date-only value. |
| [`_daysBetween`](#_daysbetween) | private top-level function | A | Count whole calendar days between two date-only values. |
| [`estimateCycleLength`](#estimatecyclelength) | top-level function | A | Estimate the forward cycle length as the median of the most recent valid cycles. |
| [`predictCycle`](#predictcycle) | top-level function | A | Predict cycle phases, fertile windows, and future start dates for one person. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/intimacy/services/cycle_predictor.dart` reports
7, matching the 7 rows above with a link/anchor exactly: `CycleDayInfo`'s and `CyclePrediction`'s
constructors plus the five top-level functions (`dateOnly`, `_addDays`, `_daysBetween`,
`estimateCycleLength`, `predictCycle`). Every one of those 7 `/// Purpose:` blocks sits directly
above the real declaration it documents — no misattached blocks were found. The table has 9
additional rows beyond those 7: the seven public top-level tuning constants, the `CyclePhase` enum,
and `CyclePrediction.empty`, none of which carry a `/// Purpose:` block but are all real, meaningfully
public declarations (the seven constants are exactly the tunable values [Body
Metrics](../../../../algorithms/body-metrics.md#constants) documents by name; `CyclePhase` is
switched on by both UI callers; `CyclePrediction.empty` is the explicit zero-data sentinel returned
by both this file and `body_section.dart`) — included for completeness the same way `cyclePersonPalette`
is included in `widgets/cycle_calendar.md`. Total: 16 rows, 7 Tier A, 9 Tier B. All 7 documented
declarations are Tier A: the two constructors are real (if simple) value-object constructors for this
file's two result types, and the five functions all carry real branching/date-arithmetic logic central
to the prediction algorithm.

## Documentation

### `const CycleDayInfo({required CyclePhase phase, bool inFertileWindow = false, bool isOvulationDay = false, bool isActualStart = false, bool isPredictedStart = false, bool isEstimated = true})` <a id="cycledayinfo-new"></a>
- **Kind:** const constructor of `CycleDayInfo`
- **Source:** `lib/features/intimacy/services/cycle_predictor.dart` (line 49)
- **Purpose:** Hold one calendar day's phase classification plus its fertile-window/ovulation/
  actual-start/predicted-start/estimated marker flags.
- **Inputs:** `phase` required; every marker flag defaults to `false` except `isEstimated`, which
  defaults to `true`.
- **Returns:** A new `CycleDayInfo`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor.
- **Usage:** Constructed once per classified day inside [`predictCycle`](#predictcycle) (line 232):
  `days[day] = CycleDayInfo(phase: phase, inFertileWindow: inFertileWindow, isOvulationDay:
  isOvulationDay, isActualStart: isActual, isPredictedStart: isPredicted, isEstimated: !isActual);`.
- **Notes:** `isEstimated` defaulting to `true` means every day is treated as derived unless the
  caller explicitly marks it `false` — in practice only an actually-recorded start day is ever
  non-estimated (`isEstimated: !isActual` above).

### `const CyclePrediction({required int cycleLengthDays, required List<DateTime> predictedStarts, required Map<DateTime, CycleDayInfo> days})` <a id="cycleprediction-new"></a>
- **Kind:** const constructor of `CyclePrediction`
- **Source:** `lib/features/intimacy/services/cycle_predictor.dart` (line 75)
- **Purpose:** Hold the full prediction output for one person over a queried window: the cycle
  length used, the predicted future start dates inside the window, and every classified day.
- **Inputs:** All three fields required.
- **Returns:** A new `CyclePrediction`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor.
- **Usage:** Constructed once at the end of [`predictCycle`](#predictcycle) (line 243) with the
  fully-computed `cycleLength`, filtered `predictedStarts`, and `days` map.
- **Notes:** The separate `CyclePrediction.empty` static constant, not this constructor, is what
  every caller actually uses for the zero-recorded-starts case.

### `DateTime dateOnly(DateTime value)` <a id="dateonly"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/services/cycle_predictor.dart` (line 93)
- **Purpose:** Normalize a `DateTime` to a date-only local value (year/month/day, midnight).
- **Inputs:** `value`.
- **Returns:** `DateTime` — always local midnight, no time component.
- **Side effects:** None.
- **Algorithm:** `DateTime(value.year, value.month, value.day)`.
- **Usage:** Applied to every recorded start date at the top of `predictCycle` (line 156):
  `final starts = actualStarts.map(dateOnly).toSet().toList()..sort();`.
- **Notes:** Every `DateTime` key this library produces (in `CyclePrediction.days` and
  `predictedStarts`) is normalized this way, so callers can safely compare/index by date alone.

### `DateTime _addDays(DateTime day, int count)` <a id="_adddays"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/cycle_predictor.dart` (line 102)
- **Purpose:** Add calendar days to a date-only value using pure calendar arithmetic.
- **Inputs:** `day` — a date-only value; `count` — days to add (may be negative).
- **Returns:** `DateTime`.
- **Side effects:** None.
- **Algorithm:** `DateTime(day.year, day.month, day.day + count)` — letting the `DateTime`
  constructor itself normalize an out-of-range day into the correct following/preceding month.
- **Usage:** Used throughout `predictCycle` to build the forward prediction chain (line 165: `var
  next = _addDays(anchor, cycleLength);`) and to compute ovulation estimates (line 195: `_addDays(
  segNext, -ovulationOffsetDays)`).
- **Notes:** Using calendar-field arithmetic instead of `Duration` addition means daylight-saving
  transitions never shift the result off local midnight.

### `int _daysBetween(DateTime from, DateTime to)` <a id="_daysbetween"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/cycle_predictor.dart` (line 111)
- **Purpose:** Count whole calendar days between two date-only values.
- **Inputs:** `from`, `to`.
- **Returns:** `int` (may be negative if `to` precedes `from`).
- **Side effects:** None.
- **Algorithm:** Converts both dates to UTC midnight (`DateTime.utc(y, m, d)`) before taking
  `.difference(...).inDays`, rather than differencing the local `DateTime`s directly.
- **Usage:** Used both by [`estimateCycleLength`](#estimatecyclelength) (line 127, gap length between
  consecutive starts) and throughout `predictCycle` (segment lengths, days-until-ovulation).
- **Notes:** Normalizing through UTC first is what prevents a local daylight-saving transition from
  producing an off-by-one day count.

### `int estimateCycleLength(List<DateTime> sortedStarts)` <a id="estimatecyclelength"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/services/cycle_predictor.dart` (line 124)
- **Purpose:** Estimate the forward cycle length as the median of the most recent valid recorded
  cycles.
- **Inputs:** `sortedStarts` — ascending, date-only, recorded period start dates.
- **Returns:** `int` days — `defaultCycleLengthDays` (28) if no valid gap exists.
- **Side effects:** None.
- **Algorithm:**
  1. For each adjacent pair of `sortedStarts`, compute the gap via `_daysBetween`.
  2. Discard (not clamp) any gap outside `[minValidCycleDays, maxValidCycleDays]` (15-90) as a data
     error or tracking gap.
  3. If no valid gap remains, return `defaultCycleLengthDays`.
  4. Otherwise take the most recent up to `medianCycleWindow` (6) valid gaps, sort that subset, and
     return the median (average of the two middle values when the count is even).
- **Usage:** Called once per prediction, at the top of `predictCycle` (line 159):
  `final cycleLength = estimateCycleLength(starts);`.
- **Notes:** Median instead of mean means a single outlier cycle (one unusually long or short month)
  cannot skew the prediction the way an average would; see
  [Body Metrics](../../../../algorithms/body-metrics.md#estimatecyclelength--median-of-the-last-6-valid-cycles).

### `CyclePrediction predictCycle({required Iterable<DateTime> actualStarts, required DateTime windowStart, required DateTime windowEnd})` <a id="predictcycle"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/services/cycle_predictor.dart` (line 151)
- **Purpose:** Predict cycle phases, the fertile window, ovulation, and future start dates for one
  person, classifying every day inside the queried window.
- **Inputs:** `actualStarts` — recorded start dates in any order, duplicates tolerated;
  `windowStart`/`windowEnd` — the inclusive query range to classify days within.
- **Returns:** `CyclePrediction` — `CyclePrediction.empty` if `actualStarts` is empty.
- **Side effects:** None.
- **Algorithm:** See
  [Body Metrics — predictCycle](../../../../algorithms/body-metrics.md#predictcycle--anchoring-phases-and-fertile-window)
  for the full walkthrough. In brief:
  1. Dedupe/sort `actualStarts`; if empty, return `CyclePrediction.empty`.
  2. Estimate `cycleLength` via [`estimateCycleLength`](#estimatecyclelength); anchor on the latest
     recorded start (`starts.last`).
  3. Build the forward prediction chain from the anchor out to a 366-day horizon.
  4. Treat every recorded start plus every predicted start as a segment boundary; a gap longer than
     `maxValidCycleDays` is capped to just its assumed-menstrual prefix rather than classified as a
     full cycle.
  5. Per segment: classify the first `min(segmentLength, assumedMenstrualDays)` days as menstrual;
     estimate ovulation as `segmentEnd - ovulationOffsetDays` (skipped if too close to the menstrual
     phase); classify the 5-days-before/1-day-after window around ovulation as fertile; split the
     remaining days into follicular (before ovulation) and luteal (after).
  6. Only emit `CycleDayInfo` entries for days inside `[windowStart, windowEnd]`.
- **Usage:**
  ```dart
  CyclePrediction predictionFor(String? personId) => predictCycle(
    actualStarts: _cycleRecords
        .where((c) => c.personId == personId)
        .map((c) => c.day),
    windowStart: windowStart,
    windowEnd: windowEnd,
  );
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:313-319`, the home calendar's per-person overlay.)
- **Notes:** Predictions are always regenerated from scratch on every call — adding or deleting a
  cycle record re-derives everything rather than incrementally shifting old predictions.

## Related pages

- [Body Metrics — Cycle prediction](../../../../algorithms/body-metrics.md#cycle-prediction) — the
  full algorithm walkthrough this file implements, including worked examples.
- [Intimacy](../../../../features/intimacy.md#the-body-layer-v124) — the Body layer UI
  (`widgets/cycle_calendar.dart`, `widgets/body_section.dart`) that renders these predictions, and the
  mandatory not-contraception/not-medical disclaimer.
- [Data Formats](../../../../data-formats.md) — the `CycleRecord` fields this file's callers read.

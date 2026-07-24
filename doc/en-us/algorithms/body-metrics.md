# Body Metrics

Source: `lib/features/intimacy/services/body_metrics.dart` (read in full — bra-size estimation and
PSI) and `lib/features/intimacy/services/cycle_predictor.dart` (read in full — cycle prediction).
Both files are pure Dart with no Flutter imports, so everything here is directly unit-testable
(`test/body_metrics_test.dart`, `test/cycle_predictor_test.dart`). See
[Intimacy](../features/intimacy.md#the-body-layer-v124) for how this fits into the Body layer UI.

## Bra-size estimation

`estimateBraSize({required double bustCm, required double underbustCm, required BraStandard
standard})` returns a `BraSizeEstimate? { band, cup, display }`, or `null` when inputs are
non-positive, `bustCm - underbustCm <= 0`, or the measurements fall outside the supported tables.
Only the raw measurements are ever persisted — the estimate itself is always recalculated on demand,
never stored.

### Band derivation (shared across all standards)

`_roundedBand(underbustCm)` rounds underbust to the nearest 5 cm and rejects anything outside
**50–130 cm** (`(underbustCm / 5).round() * 5`, then bounds-checked). This EU band number is the
common starting point for every standard below.

`_ukBandFromEu(euBand)` converts an EU band to the UK/US band system: `28 + (euBand - 60) ~/ 5 * 2`,
rejecting results outside **24–56**. So EU 60 → UK/US 28, and every 5 cm EU step adds 2 to the
UK/US band (EU 80 → UK/US 36).

### The six standards

| Standard | Band | Cup derivation |
| --- | --- | --- |
| **EU** (`BraStandard.eu`) | Rounded EU band | Difference (bust − underbust) must be in `[10, 28)` cm; cup = `_euCups[((diff - 10) / 2).floor()]` from `['AA','A','B','C','D','E','F','G','H']` — i.e. one cup step per 2 cm of difference starting at 10 cm = AA. |
| **FR/ES** (`BraStandard.frEs`) | EU band **+ 15** | Same cup table and diff range as EU; only the band number shifts. |
| **JP/JIS** (`BraStandard.jp`) | Rounded EU band | JIS cups sit on 2.5 cm centers starting at 5.0 cm (AAA), each ±1.25 cm, giving half-open bands `[center-1.25, center+1.25)`. Valid diff range is `[3.75, 28.75)`; `index = ((diff - 3.75) / 2.5).floor()` into `['AAA','AA','A','B','C','D','E','F','G','H']`. **Displayed cup-first**, e.g. `C75` (`'$cup$euBand'`), unlike every other standard which displays band-first. |
| **UK** (`BraStandard.uk`) | UK/US band from EU band | Diff converted to whole inches (`(diff / 2.54).round()`), valid range **1–11** inches; cup = `_ukCups[inches - 1]` from `['A','B','C','D','DD','E','F','FF','G','GG','H']`. |
| **US** (`BraStandard.us`) | UK/US band from EU band | Same inch conversion as UK; cup = `_usCups[inches - 1]` from `['A','B','C','D','DD/E','DDD/F','G','H','I','J','K']` — noted in the source as having brand-to-brand variance in practice. |
| **AU/NZ** (`BraStandard.auNz`) | UK band **− 22** (a dress-size band, rejected if `< 4`) | Same inch conversion and `_ukCups` table as UK, but the band itself is a dress-size number (UK 30 → AU/NZ 8, i.e. each UK band step of 2 maps to an AU/NZ step of 2 as well since both subtract a constant offset). |

All six paths return `null` outside their respective valid ranges rather than clamping to a nearest
size — the function is explicit that out-of-range measurements should surface a hint in the UI, not
a misleadingly precise size.

## The PSI reference index

`calculatePsi({double? lengthCm, double? baseCircumferenceCm, double? frontCircumferenceCm})`:

1. Returns `null` if `lengthCm` is missing or `<= 0`.
2. Normalizes each circumference: a `<= 0` value is treated as absent (`null`).
3. Returns `null` if **both** circumferences are absent.
4. If only one circumference is present, it is used for **both** — `base ??= front; front ??=
   base;` — which is what "reduces the formula to `3hC²`" means concretely (see step 6).
5. Converts all three inputs from **cm to dm** (divide by 10): `h = lengthCm / 10`,
   `c1 = base / 10`, `c2 = front / 10`.
6. Computes `PSI = h * (c1*c1 + c2*c2 + c1*c2)`. When `c1 == c2 == C` (the single-circumference
   case from step 4), this algebraically collapses to `h * (C² + C² + C²) = 3hC²` — hence the "single
   -circumference reduction to `3hC²`" behavior.

The formula is a **dm-based truncated-cone volume approximation** used purely as a personal
reference number (never a qualitative rating), with the source comment explicitly noting the cited
statistical reference (Wang Cuntong et al. 2020) is a source for population statistics, **not** for
the formula itself.

## Cycle prediction

Source: `lib/features/intimacy/services/cycle_predictor.dart`. All predictions are statistical
estimates derived only from recorded start dates and must never be presented as contraception or
medical guidance — the UI attaches the mandatory disclaimer (see
[Intimacy](../features/intimacy.md)).

### Constants

- `minValidCycleDays = 15`, `maxValidCycleDays = 90` — a gap outside this range is a data error or a
  tracking gap, not a real cycle length.
- `medianCycleWindow = 6` — only the most recent 6 valid cycle lengths feed the median.
- `defaultCycleLengthDays = 28` — used when fewer than two valid records exist.
- `assumedMenstrualDays = 5`, `ovulationOffsetDays = 14`, `predictionHorizonDays = 366`.

### `estimateCycleLength(sortedStarts)` — median of the last ≤6 valid cycles

For each adjacent pair of sorted recorded starts, the gap in days is computed; gaps outside
`[15, 90]` are discarded entirely (not just capped) as data errors/tracking gaps. If no valid gap
remains, the function returns the 28-day default. Otherwise it takes the **most recent** up to 6
valid gaps (`lengths.sublist(lengths.length - medianCycleWindow)` when there are more than 6), sorts
that subset, and returns the **median** (average of the two middle values when the count is even).
Using the median instead of the mean means a single outlier cycle (e.g. one unusually long or short
month) cannot skew the prediction the way an average would.

### `predictCycle(...)` — anchoring, phases, and fertile window

The **anchor** for all forward predictions is always the single latest recorded actual start date
(`starts.last` after sorting) — not today's date and not an average. Predictions are regenerated
from scratch on every call (adding or deleting a record re-derives everything; old predictions are
never incrementally shifted).

- **Forward chain:** starting at the anchor, repeatedly add `cycleLength` days until exceeding a
  366-day horizon, producing the list of `predictedStarts`.
- **Segments:** every recorded start plus every predicted start forms a segment boundary. A segment
  longer than `maxValidCycleDays` (90 days) is treated as an untracked gap — only the assumed
  menstrual days at its start are classified, not a full phase cycle, so a long tracking gap doesn't
  paint months of misleading phase colors.
- **Menstrual phase:** the first `min(segmentLength, assumedMenstrualDays)` days of each segment.
- **Ovulation estimate:** `segmentEnd - ovulationOffsetDays` (14 days before the *next* segment's
  start), but only when that estimate falls at or after the end of the menstrual phase — otherwise
  the segment is too short for the estimate to be meaningful and it is skipped.
- **Fertile window:** the 5 days before ovulation through 1 day after
  (`untilOvulation <= 5 && untilOvulation >= -1`).
- **Follicular vs. luteal:** days between the end of menses and ovulation are follicular; days after
  ovulation (within the segment) are luteal; when no valid ovulation estimate exists for a segment,
  all non-menstrual days default to follicular.
- Every classified day carries `isEstimated = true` except an actually-recorded start day itself
  (`isActualStart`), and `isPredictedStart` marks a start day that came from the forward chain
  rather than a real record.

## Related pages

- [Intimacy](../features/intimacy.md) — the Body layer UI these algorithms feed.
- [Data Formats](../data-formats.md) — the `BodyProfile` and `CycleRecord` fields these functions
  read.

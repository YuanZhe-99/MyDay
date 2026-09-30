# lib/features/weight/services/weight_insight_facts.dart

The pure fact builder behind the Weight page's on-device AI insight card.
`buildWeightInsightFacts` turns the [Weight page](../views/weight_page.md)'s loaded
[`WeightRecord`](../models/weight_record.md)s and height into
[`InsightFacts`](../../ai/services/insight_prompts.md): the latest weight, height, BMI and its band,
the change over 7, 30 and 90 days, the recent range, the weigh-in count, the tracking start, body
fat and its 90-day change, the carried-forward bust/waist/hip, their 90-day change and the
waist-to-hip ratio. Since v1.5.3 the card also asks for a `body` answer about those body facts, and
the advice draws on them. Numbers go through `factNumber` so the fingerprint does not move with
float noise. Record notes are never sent. The card itself is
[`AiInsightCard`](../../ai/widgets/ai_insight_card.md), and the facts are fingerprinted by
[`AiInsightStore`](../../ai/services/insight_service.md). See
[On-device AI — What each card is given](../../../../on-device-ai.md#what-each-card-is-given).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`_change`](#_change) | top-level function (private) | A | Describe the weight change over a window. |
| [`_signed`](#_signed) | top-level function (private) | A | Format a signed difference for a fact line. |
| [`_bmiBand`](#_bmiband) | top-level function (private) | A | Name the BMI band the Weight page's colored bar shows. |
| [`_fieldChange`](#_fieldchange) | top-level function (private) | A | Describe how one optional field moved inside a window. |
| [`buildWeightInsightFacts`](#buildweightinsightfacts) | top-level function | A | Build the Weight card's facts. |

`grep -c 'Purpose:' lib/features/weight/services/weight_insight_facts.dart` reports 5, matching the
five declarations above exactly; there are no undocumented declarations.

## Documentation

### `String? _change(List<WeightRecord> sorted, DateTime now, int days)` <a id="_change"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/weight/services/weight_insight_facts.dart` (line 9)
- **Purpose:** Describe the weight change over a window.
- **Inputs:** `sorted` — records oldest first; `now`; `days` — the window length.
- **Returns:** `String?` such as `+1.2 kg over 30 days (5 weigh-ins)`, or null when fewer than two
  records fall in the window.
- **Side effects:** None.
- **Algorithm:** Keep records with `now - days ≤ datetime ≤ now`; with at least two, the change is
  last minus first, formatted with `_signed`.
- **Usage:** `buildWeightInsightFacts` calls it for 7, 30 and 90 days.
- **Notes:** The window is measured from `now` exactly, not from local midnight.

### `String _signed(double delta, [int digits = 1])` <a id="_signed"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/weight/services/weight_insight_facts.dart` (line 25)
- **Purpose:** Format a signed difference for a fact line.
- **Inputs:** `delta`; `digits` — decimal places, default 1.
- **Returns:** `String` — `+1.2`, `-0.5` or `0`.
- **Side effects:** None.
- **Algorithm:** `factNumber(delta, digits)`, prefixed with `+` when `delta` is positive and the
  rounded text is not `0`.
- **Usage:** `_change` and the body-fat and measurement change lines.
- **Notes:** A change that rounds to zero is written `0`, never `+0`.

### `String _bmiBand(double bmi)` <a id="_bmiband"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/weight/services/weight_insight_facts.dart` (line 37)
- **Purpose:** Name the BMI band the Weight page's colored bar shows.
- **Inputs:** `bmi`.
- **Returns:** `String` — `underweight range` below 18.5, `normal range` below 25,
  `overweight range` below 30, otherwise `obese range`.
- **Side effects:** None.
- **Algorithm:** Three comparisons.
- **Usage:** The `- BMI:` line, e.g. `- BMI: 23.7 (normal range)`.
- **Notes:** The cut-offs match `_buildBMIBar` in [`weight_page.md`](../views/weight_page.md), so the
  card and the bar agree. A band, not a diagnosis.

### `({double first, double last, DateTime firstAt})? _fieldChange(List<WeightRecord> sorted, DateTime from, DateTime now, double? Function(WeightRecord r) value)` <a id="_fieldchange"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/weight/services/weight_insight_facts.dart` (line 52)
- **Purpose:** Describe how one optional field moved inside a window.
- **Inputs:** `sorted` — records oldest first; `from`, `now` — the window; `value` — the field
  reader (body fat, bust, waist or hip).
- **Returns:** The first and last positive value in the window and the first one's date, or null
  when fewer than two records in the window measured the field.
- **Side effects:** None.
- **Algorithm:** Filter to `from ≤ datetime ≤ now` with a positive value; take the first and last.
- **Usage:** The `- Body fat change over 90 days:` and `- Measurement change over 90 days:` lines.
- **Notes:** Only records that measured the field count. Carried-forward values are deliberately not
  used here, so a field measured once shows no change.

### `InsightFacts? buildWeightInsightFacts({required DateTime now, required double? heightCm, required List<WeightRecord> records})` <a id="buildweightinsightfacts"></a>
- **Kind:** top-level function
- **Source:** `lib/features/weight/services/weight_insight_facts.dart` (line 82)
- **Purpose:** Build the Weight card's facts.
- **Inputs:** `now` — local time; `heightCm` — the user's height, or null; `records`.
- **Returns:** `InsightFacts?` with `module: weight`, bucket `none` and the slots `trend`, `body`
  (only when a BMI, body-fat or measurement line was sent) and `advice` — or null when no record is
  dated at or before `now`.
- **Side effects:** None.
- **Algorithm:**
  1. Drop records after `now`; sort oldest first; the latest is the last.
  2. `- Today:`; the latest weight, its date and how many calendar days ago.
  3. When `heightCm > 0`: the height, and the BMI from `WeightData.calculateBMI` with its
     `_bmiBand` when it is defined.
  4. A `- Change:` line for each of 7, 30 and 90 days that `_change` can describe.
  5. The min–max range over the last seven records (when at least two), the count of weigh-ins in
     the last 30 days, and `- Tracking since:` the first record's date with the total count.
  6. The most recent positive body fat with its date, and its 90-day change from `_fieldChange`.
  7. Bust, waist and hip from `WeightData.effectiveMeasurementsUpTo` (each field carried forward on
     its own, as the page shows them), the waist-to-hip ratio to two decimals, and each field's
     90-day change from `_fieldChange`.
  8. Slots: `trend` ("Describe the weight trend."), `body` ("Sum up the body condition neutrally:
     BMI, body fat and measurements, and how they have moved.") when step 3, 6 or 7 sent a value,
     and `advice` ("One gentle, practical suggestion based on the trend and the body facts.").
- **Usage:**
  ```dart
  final facts = buildWeightInsightFacts(
    now: now,
    heightCm: _height,
    records: _records,
  );
  ```
  (`lib/features/weight/views/weight_page.dart`, line 485, whose card groups `trend`/`advice` under
  `aiWeightTrend` and `body` under `aiWeightBody`; covered by `test/insight_facts_test.dart`.)
- **Notes:** Record notes are never read. Future-dated records are ignored. The `body` slot was
  added in v1.5.3; before it the model was asked only about the trend and ignored the body facts.

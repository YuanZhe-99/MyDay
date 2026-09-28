# lib/features/weight/services/weight_insight_facts.dart

The pure fact builder behind the Weight page's on-device AI insight card.
`buildWeightInsightFacts` turns the [Weight page](../views/weight_page.md)'s loaded
[`WeightRecord`](../models/weight_record.md)s and height into
[`InsightFacts`](../../ai/services/insight_prompts.md): the latest weight, height and BMI, the change
over 7, 30 and 90 days, the recent range, the weigh-in count, body fat, the carried-forward
bust/waist/hip and the waist-to-hip ratio. Numbers go through `factNumber` so the fingerprint does
not move with float noise. Record notes are never sent. The card itself is
[`AiInsightCard`](../../ai/widgets/ai_insight_card.md), and the facts are fingerprinted by
[`AiInsightStore`](../../ai/services/insight_service.md). See
[On-device AI — What each card is given](../../../../on-device-ai.md#what-each-card-is-given).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`_change`](#_change) | top-level function (private) | A | Describe the weight change over a window. |
| [`buildWeightInsightFacts`](#buildweightinsightfacts) | top-level function | A | Build the Weight card's facts. |

`grep -c 'Purpose:' lib/features/weight/services/weight_insight_facts.dart` reports 2, matching the
two declarations above exactly; there are no undocumented declarations.

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
  last minus first, signed with `+` when positive and formatted with `factNumber`.
- **Usage:** `buildWeightInsightFacts` calls it for 7, 30 and 90 days (line 49).
- **Notes:** The window is measured from `now` exactly, not from local midnight.

### `InsightFacts? buildWeightInsightFacts({required DateTime now, required double? heightCm, required List<WeightRecord> records})` <a id="buildweightinsightfacts"></a>
- **Kind:** top-level function
- **Source:** `lib/features/weight/services/weight_insight_facts.dart` (line 27)
- **Purpose:** Build the Weight card's facts.
- **Inputs:** `now` — local time; `heightCm` — the user's height, or null; `records`.
- **Returns:** `InsightFacts?` with `module: weight`, bucket `none` and the slots `trend` and
  `advice` — or null when no record is dated at or before `now`.
- **Side effects:** None.
- **Algorithm:**
  1. Drop records after `now`; sort oldest first; the latest is the last.
  2. `- Today:`; the latest weight, its date and how many calendar days ago.
  3. When `heightCm > 0`: the height, and the BMI from `WeightData.calculateBMI` when it is defined.
  4. A `- Change:` line for each of 7, 30 and 90 days that `_change` can describe.
  5. The min–max range over the last seven records (when at least two), and the count of weigh-ins
     in the last 30 days.
  6. The most recent positive body fat with its date.
  7. Bust, waist and hip from `WeightData.effectiveMeasurementsUpTo` (each field carried forward on
     its own, as the page shows them) and the waist-to-hip ratio to two decimals.
- **Usage:**
  ```dart
  final facts = buildWeightInsightFacts(
    now: now,
    heightCm: _height,
    records: _records,
  );
  ```
  (`lib/features/weight/views/weight_page.dart`, line 470; covered by
  `test/insight_facts_test.dart`.)
- **Notes:** Record notes are never read. Future-dated records are ignored.

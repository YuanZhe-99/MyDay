# lib/features/intimacy/services/intimacy_insight_facts.dart

The pure fact builder behind the Intimacy page's on-device AI insight card.
`buildIntimacyInsightFacts` turns the [Intimacy page](../views/intimacy_page.md)'s loaded
[records](../models/intimacy_record.md), the user's body profile, cycle records and the Weight
module's [records](../../weight/models/weight_record.md) into
[`InsightFacts`](../../ai/services/insight_prompts.md): statistics for the last 30 days and the 30
before, a 90-day count, days since the last entry, the user's body measurements with an estimated
bra size ([`body_metrics.dart`](body_metrics.md)), and — only when the user tracks their own
cycle — an estimated cycle phase from [`cycle_predictor.dart`](cycle_predictor.md). Only statistics
are sent; notes, locations, partner, toy and position names, thrust counts, the porn flag, genital
measurements and partners' cycles never are, both for privacy and to stay inside the on-device
models' acceptable-use rules. The card itself is
[`AiInsightCard`](../../ai/widgets/ai_insight_card.md), and the facts are fingerprinted by
[`AiInsightStore`](../../ai/services/insight_service.md). See
[On-device AI — What each card is given](../../../../on-device-ai.md#what-each-card-is-given).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`_window`](#_window) | top-level function (private) | A | Summarize the records in one window. |
| [`buildIntimacyInsightFacts`](#buildintimacyinsightfacts) | top-level function | A | Build the Intimacy card's facts, including the body condition. |

`grep -c 'Purpose:' lib/features/intimacy/services/intimacy_insight_facts.dart` reports 2, matching
the two declarations above exactly; there are no undocumented declarations.

## Documentation

### `String _window(List<IntimacyRecord> records, DateTime from, DateTime to)` <a id="_window"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/intimacy_insight_facts.dart` (line 13)
- **Purpose:** Summarize the records in one window.
- **Inputs:** `records`; `from` (inclusive); `to` (exclusive).
- **Returns:** `String` — `0 entries`, or the entry count split into partnered and solo, the average
  `pleasureLevel` "of 5", the average timed length in minutes, the climax rate, and the protection
  rate among partnered entries.
- **Side effects:** None.
- **Algorithm:** Filter to `from ≤ datetime < to`; compute each statistic over the window. The
  average length uses only entries with a positive `duration`, and is left out when there are none;
  the protection rate (`usedCondom`) is left out when there are no partnered entries. Rates are
  rounded to whole percents.
- **Usage:** `buildIntimacyInsightFacts` calls it for the last 30 days and the 30 before
  (lines 69–70).
- **Notes:** Durations of zero (no timer) are excluded from the average rather than counted as zero.

### `InsightFacts? buildIntimacyInsightFacts({required DateTime now, required List<IntimacyRecord> records, required BodyProfile? userBody, required List<CycleRecord> cycleRecords, required List<WeightRecord> weightRecords})` <a id="buildintimacyinsightfacts"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/services/intimacy_insight_facts.dart` (line 52)
- **Purpose:** Build the Intimacy card's facts, including the body condition.
- **Inputs:** `now` — local time; `records`; `userBody` — the user's body profile, or null;
  `cycleRecords`; `weightRecords` — for the user's own bust/waist/hip.
- **Returns:** `InsightFacts?` with `module: intimacy` and bucket `none` — or null when there are no
  past records, no body facts and no cycle facts. Slots: `trend` and `advice` when there are past
  records; `body` when there are body or cycle facts, asking also for the cycle phase and an
  "estimates" caveat when cycle facts were sent.
- **Side effects:** None.
- **Algorithm:**
  1. Keep records at or before `now`, sorted oldest first. `- Today:` is the local date.
  2. With past records: `_window` for the 30 days ending today (today − 29 through today) and for
     the 30 days before; the count in the last 90 days; days since the last entry.
  3. Body: bust/waist/hip from `WeightData.effectiveMeasurementsUpTo(weightRecords, now)`; the
     profile's underbust when positive, and with a bust the `estimateBraSize` result in the
     profile's bra standard; the waist-to-hip ratio to two decimals.
  4. Cycle, only when `userBody.cycleEnabled`: the user's own starts (`personId == null`); when there
     are any, `predictCycle` over yesterday through 60 days ahead gives the typical length, the last
     recorded start, today's estimated phase and fertile window, and the days to the next estimated
     start.
- **Usage:**
  ```dart
  final facts = buildIntimacyInsightFacts(
    now: now,
    records: _records,
    userBody: _userBody,
    cycleRecords: _cycleRecords,
    weightRecords: _weightRecordsForInsight,
  );
  ```
  (`lib/features/intimacy/views/intimacy_page.dart`, line 677, only while the module is visible;
  covered by `test/insight_facts_test.dart`.)
- **Notes:** Partners' cycle records are never read. The page shows the `aiEstimateDisclaimer`
  footnote while the user tracks their cycle. A `guardrail` refusal is cached as *skipped* by the
  store, so a refused set of facts is not retried until it changes.

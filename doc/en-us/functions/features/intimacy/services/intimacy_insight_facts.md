# lib/features/intimacy/services/intimacy_insight_facts.dart

The pure fact builder behind the Intimacy page's on-device AI insight card.
`buildIntimacyInsightFacts` turns the [Intimacy page](../views/intimacy_page.md)'s loaded
[records, partners, toys and positions](../models/intimacy_record.md), the trend chart's persisted
`IntimacyChartSettings`, the user's body profile, cycle records and the Weight module's
[records](../../weight/models/weight_record.md) into
[`InsightFacts`](../../ai/services/insight_prompts.md): statistics for the last 30 days and the 30
before, a 90-day count, days since the last entry, a summary of the trend chart exactly as the user
has set it up, anonymous per-partner, toy and position statistics, the user's body measurements
with an estimated bra size ([`body_metrics.dart`](body_metrics.md)), and — only when the user
tracks their own cycle — an estimated cycle phase from [`cycle_predictor.dart`](cycle_predictor.md).

Only statistics are sent. Partners, toys and positions appear only as `partner A`, `toy 1`,
`position 1`, ranked by use. Notes, locations, names, emoji, images, prices, links, genital
measurements and partners' cycles never are, both for privacy and to stay inside the on-device
models' acceptable-use rules. Thrust count and rate and the porn-watched share are sent since
v1.5.3. The chart summary reads the public `IntimacyChartMetric` and `IntimacyChartRange` enums from
[`intimacy_trend_chart.dart`](../widgets/intimacy_trend_chart.md) and falls back to the same
defaults, so it always describes the chart on screen. The card itself is
[`AiInsightCard`](../../ai/widgets/ai_insight_card.md), and the facts are fingerprinted by
[`AiInsightStore`](../../ai/services/insight_service.md). See
[On-device AI — What each card is given](../../../../on-device-ai.md#what-each-card-is-given).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `_pct` | top-level function (private) | B | Format a share of a total as a whole percent. |
| `_avg` | top-level function (private) | B | Average the non-null values a reader returns; null when there are none. |
| `_minutes` | top-level function (private) | B | A record's timed length in minutes, or null when no timer was used. |
| `_rating` | top-level function (private) | B | A record's rating for the chart's pleasure metric, or null when not positive. |
| [`_window`](#_window) | top-level function (private) | A | Summarize the records in one window. |
| [`_chartMetric`](#_chartmetric) | top-level function (private) | A | Describe one metric of the trend chart over its visible span. |
| `perWeek` | local function (in `_chartMetric`) | B | Entries per week over a span; spans under a day count as one day. |
| `fmt` | local function (in `_chartMetric`) | B | Format one average with the metric's unit, or `no data`. |
| [`_chartSummary`](#_chartsummary) | top-level function (private) | A | Summarize the trend chart exactly as the user has set it up. |
| [`_ranked`](#_ranked) | top-level function (private) | A | Rank ids by how often they occur, most frequent first. |
| [`_usage`](#_usage) | top-level function (private) | A | Describe how often labelled items were used. |
| `_maxListed` | private top-level const (`int`) | B | `5`: the most partners, toys or positions listed on one fact line. |
| [`_companions`](#_companions) | top-level function (private) | A | Describe partners, toys and positions with anonymous labels. |
| [`buildIntimacyInsightFacts`](#buildintimacyinsightfacts) | top-level function | A | Build the Intimacy card's facts. |
| [`buildIntimacyFallbackInsightFacts`](#buildintimacyfallbackinsightfacts) | top-level function | A | Build the Intimacy card's fallback facts: the v1.5.2 prompt. |
| [`_intimacyFacts`](#_intimacyfacts) | top-level function (private) | A | Build either version of the Intimacy card's facts. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/intimacy/services/intimacy_insight_facts.dart`
reports 15 against 16 rows. The extra row is `_maxListed`, a constant with a plain doc comment and
no `Purpose:` block. The two local functions `perWeek` and `fmt` each carry their own `Purpose:`
block and have a row.

## Documentation

### `String _window(List<IntimacyRecord> records, DateTime from, DateTime to, {required bool detailed})` <a id="_window"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/intimacy_insight_facts.dart` (line 61)
- **Purpose:** Summarize the records in one window.
- **Inputs:** `records`; `from` (inclusive); `to` (exclusive); `detailed` — false for the v1.5.2
  wording.
- **Returns:** `String` — `0 entries`, or the entry count split into partnered and solo, the average
  `pleasureLevel` "of 5", the average timed length in minutes, the climax rate, and when `detailed`
  the porn-watched share and the average thrust count and rate when any entry has them, then the
  protection rate among partnered entries.
- **Side effects:** None.
- **Algorithm:** Filter to `from ≤ datetime < to`; compute each statistic over the window. The
  average length uses only entries with a positive `duration`; the thrust averages use
  `resolvedThrustCount` and `thrustsPerMinute` where they are non-null; each is left out when no
  entry has it. The protection rate (`usedCondom`) is left out when there are no partnered entries.
  Rates are rounded to whole percents.
- **Usage:** `_intimacyFacts` calls it for the last 30 days and the 30 before.
- **Notes:** Durations of zero (no timer) are excluded from the average rather than counted as zero.
  Thrust figures and the porn-watched share were added in v1.5.3.

### `String _chartMetric(IntimacyChartMetric metric, List<IntimacyRecord> visible, DateTime start, DateTime mid, DateTime end)` <a id="_chartmetric"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/intimacy_insight_facts.dart` (line 108)
- **Purpose:** Describe one metric of the trend chart over its visible span.
- **Inputs:** `metric`; `visible` — records in the span, oldest first; `start`, `mid`, `end` — the
  span and the point splitting it in halves.
- **Returns:** `String` such as `rating average 3 of 5 (first half 2 of 5, second half 4 of 5)`,
  `frequency 1.5/week (first half 1, second half 2)`, or `thrust rate no data`.
- **Side effects:** None.
- **Algorithm:** Split `visible` at `mid`. Frequency is entries ÷ weeks for the whole span and for
  each half (`perWeek`). Every other metric averages the chart's own per-record value — rating
  (positive `pleasureLevel`), length in minutes (positive `duration`), `resolvedThrustCount`,
  `thrustsPerMinute` — over the span and over each half; a half without values is `no data`.
- **Usage:** `_chartSummary`, once per selected metric.
- **Notes:** Averages, not the chart's EWMA curve: the model needs a figure it can compare, and the
  halves show the direction the curve takes.

### `String? _chartSummary(List<IntimacyRecord> sorted, IntimacyChartSettings settings, DateTime now)` <a id="_chartsummary"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/intimacy_insight_facts.dart` (line 177)
- **Purpose:** Summarize the trend chart exactly as the user has set it up.
- **Inputs:** `sorted` — past records, oldest first; `settings` — the persisted chart selection;
  `now`.
- **Returns:** `String?` — `- Chart being viewed (<range>, <n> entries): <metric>; <metric>…`, or
  null when fewer than two records fall in the range.
- **Side effects:** None.
- **Algorithm:**
  1. Resolve the range with `IntimacyChartRange.fromId`, falling back to
     `IntimacyChartSettings.defaultRange`; resolve the metrics in canonical enum order, falling back
     to `defaultMetrics` when none is recognized.
  2. Keep records at or after `range.cutoffFrom(now)`; return null below two.
  3. The span starts at the cutoff, or at the first record for `all`; `mid` is halfway to `now`.
  4. Label the range (`last week` … `last year`, `all time since <date>`) and join one
     `_chartMetric` per selected metric with `; `.
- **Usage:** `buildIntimacyInsightFacts`, when there are past records.
- **Notes:** The fallbacks match the widget's `_range` and `_selectedMetrics` getters, and null
  matches the chart's empty state, so the card never describes a chart the user cannot see.

### `List<String> _ranked(Map<String, int> counts, Map<String, DateTime> firstSeen)` <a id="_ranked"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/intimacy_insight_facts.dart` (line 225)
- **Purpose:** Rank ids by how often they occur, most frequent first.
- **Inputs:** `counts` — id to count; `firstSeen` — id to its earliest use.
- **Returns:** `List<String>` — ids by count descending, then earliest use, then id.
- **Side effects:** None.
- **Usage:** `_companions` for partners, `_usage` for toys and positions.
- **Notes:** The rank decides the anonymous label, so it must be deterministic for equal data.

### `String? _usage(List<IntimacyRecord> recent, String noun, List<String> Function(IntimacyRecord r) ids, Set<String> validIds)` <a id="_usage"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/intimacy_insight_facts.dart` (line 241)
- **Purpose:** Describe how often labelled items were used.
- **Inputs:** `recent` — records, oldest first; `noun` — `toy` or `position`; `ids` — reader for a
  record's item ids; `validIds` — ids that still exist.
- **Returns:** `String?` — `used in 50% of entries in the last 90 days: toy 1 6 times, toy 2 2 times`,
  or null when no valid item was used.
- **Side effects:** None.
- **Algorithm:** Count, per record, the distinct valid ids it uses and how many records use any;
  rank with `_ranked`; label the first `_maxListed` as `<noun> 1`, `<noun> 2`, ….
- **Usage:** `_companions`.
- **Notes:** Ids of deleted items are ignored.

### `List<String> _companions(List<IntimacyRecord> recent, DateTime today, DateTime now, List<Partner> partners, List<Toy> toys, List<Position> positions)` <a id="_companions"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/intimacy_insight_facts.dart` (line 281)
- **Purpose:** Describe partners, toys and positions with anonymous labels.
- **Inputs:** `recent` — past records of the last 90 days, oldest first; `today`; `now`; `partners`;
  `toys`; `positions`.
- **Returns:** `List<String>` — zero to four fact lines.
- **Side effects:** None.
- **Algorithm:**
  1. When there are partners: `- Partners: <n> on record, <m> active` (no `endDate`, or one after
     `now`).
  2. Group partnered records by partner, putting an unset or unknown `partnerId` under
     `unspecified partner`; rank with `_ranked`; for the first `_maxListed` write
     `partner A <n> entries, average rating <r>, climax <c>%, protection <p>%, last <d> days ago`.
  3. When there are toys: `- Toys: <n> on record, <m> in use; ` and the toy `_usage`, or
     `none used in the last 90 days`.
  4. `- Positions: ` and the position `_usage`, when any was used.
- **Usage:** `buildIntimacyInsightFacts`, when there are past records.
- **Notes:** Names, emoji, images, prices and links are never read. The letters follow the ranking,
  so the same partner can be `partner A` one day and `partner B` another.

### `InsightFacts? buildIntimacyInsightFacts({required DateTime now, required List<IntimacyRecord> records, required BodyProfile? userBody, required List<CycleRecord> cycleRecords, required List<WeightRecord> weightRecords, required List<Partner> partners, required List<Toy> toys, required List<Position> positions, required IntimacyChartSettings chartSettings})` <a id="buildintimacyinsightfacts"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/services/intimacy_insight_facts.dart` (line 362)
- **Purpose:** Build the Intimacy card's facts: trend, the chart being viewed, partners, toys and
  positions, and the body condition.
- **Inputs:** `now` — local time; `records`; `userBody` — the user's body profile, or null;
  `cycleRecords`; `weightRecords` — for the user's own bust/waist/hip; `partners`, `toys`,
  `positions` — for the anonymous statistics; `chartSettings` — the trend chart's selection.
- **Returns:** `InsightFacts?` with `module: intimacy` and bucket `none` — or null when there are no
  past records, no body facts and no cycle facts. Slots, in order and each only when its facts
  exist: `trend` and `advice` (past records), `chart` between them (a chart line), `partners` (any
  partner, toy or position line), and `body` (body or cycle facts, asking also for the cycle phase
  and an "estimates" caveat when cycle facts were sent).
- **Side effects:** None.
- **Algorithm:**
  `_intimacyFacts(..., detailed: true)`, which does:
  1. Keep records at or before `now`, sorted oldest first. `- Today:` is the local date.
  2. With past records: `_window` for the 30 days ending today (today − 29 through today) and for
     the 30 days before; the count in the last 90 days; days since the last entry; the
     `_chartSummary` line; the `_companions` lines over the last 90 days.
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
    partners: _partners,
    toys: _toys,
    positions: _positions,
    chartSettings: _chartSettings,
  );
  ```
  (`lib/features/intimacy/views/intimacy_page.dart`, line 781, only while the module is visible;
  covered by `test/insight_facts_test.dart`.)
- **Notes:** Partners' cycle records are never read. `quotedTerms` stays empty because no user-typed
  word is sent. Because `chartSettings` is in the facts, toggling a chart chip changes the
  fingerprint and regenerates the card. The page shows the `aiEstimateDisclaimer` footnote while
  the user tracks their cycle. A `guardrail` refusal is cached as *skipped* by the store, so a
  refused set of facts is not retried until it changes. The chart, partner, toy, position, thrust
  and porn facts were added in v1.5.3. Since v1.5.4 the page also sends
  [`buildIntimacyFallbackInsightFacts`](#buildintimacyfallbackinsightfacts) as `fallbackFacts`, so a
  refusal of these facts first retries the v1.5.2 prompt and only a second refusal is cached as
  *declined*.

### `InsightFacts? buildIntimacyFallbackInsightFacts({required DateTime now, required List<IntimacyRecord> records, required BodyProfile? userBody, required List<CycleRecord> cycleRecords, required List<WeightRecord> weightRecords})` <a id="buildintimacyfallbackinsightfacts"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/services/intimacy_insight_facts.dart` (line 397)
- **Purpose:** Build the Intimacy card's fallback facts: the v1.5.2 prompt.
- **Inputs:** `now` — local time; `records`; `userBody`; `cycleRecords`; `weightRecords`.
- **Returns:** `InsightFacts?` — null when there are no records and no body facts. Slots `trend`,
  `advice` and `body`, each only when its facts exist.
- **Side effects:** None.
- **Algorithm:** `_intimacyFacts(..., detailed: false)` with empty partner, toy and position lists
  and default chart settings, which are ignored: the same steps without the chart line, the partner,
  toy and position lines, the thrust figures and the porn-watched share.
- **Usage:**
  ```dart
  final plain = buildIntimacyFallbackInsightFacts(
    now: now,
    records: _records,
    userBody: _userBody,
    cycleRecords: _cycleRecords,
    weightRecords: _weightRecordsForInsight,
  );
  ```
  (`lib/features/intimacy/views/intimacy_page.dart`, passed as `AiInsightRequest.fallbackFacts`.)
- **Notes:** Added in v1.5.4. When the model declines the detailed facts or answers nothing usable,
  [`AiInsightStore`](../../ai/services/insight_service.md) sends these once in the same run; only a
  refusal of these too is cached as *declined*. Its output equals what v1.5.2 sent, byte for byte.
  Its slot ids are a subset of the detailed facts' in the same order, so the card's sections apply.

### `InsightFacts? _intimacyFacts({required DateTime now, required List<IntimacyRecord> records, required BodyProfile? userBody, required List<CycleRecord> cycleRecords, required List<WeightRecord> weightRecords, required List<Partner> partners, required List<Toy> toys, required List<Position> positions, required IntimacyChartSettings chartSettings, required bool detailed})` <a id="_intimacyfacts"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/intimacy_insight_facts.dart` (line 423)
- **Purpose:** Build either version of the Intimacy card's facts.
- **Inputs:** As [`buildIntimacyInsightFacts`](#buildintimacyinsightfacts), plus `detailed` — true
  for the v1.5.3 facts, false for the v1.5.2 facts.
- **Returns:** `InsightFacts?`.
- **Side effects:** None.
- **Algorithm:** The steps listed under [`buildIntimacyInsightFacts`](#buildintimacyinsightfacts);
  with `detailed` false, `_window` drops its v1.5.3 parts and the chart and companion lines are
  skipped, so their slots are never asked.
- **Usage:** The two public builders above.
- **Notes:** With `detailed` false, `partners`, `toys`, `positions` and `chartSettings` are ignored.

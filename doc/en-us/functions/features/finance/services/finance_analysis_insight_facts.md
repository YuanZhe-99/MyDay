# lib/features/finance/services/finance_analysis_insight_facts.dart

The pure fact builder behind the Analysis page's on-device AI insight card, added in 1.8.1.
`buildFinanceAnalysisInsightFacts` turns the period the [Analysis page](../views/analysis_page.md)
shows into [`InsightFacts`](../../ai/services/insight_prompts.md) for
`InsightModule.financeAnalysis`: spending and income totals, their change against the previous
period of the same length, the top three spending and income categories with shares, the peak
spending day and week, and the category whose spending moved most. The card asks the model to
explain the concentration and to suggest one budget adjustment. See
[On-device AI — What each card is given](../../../../on-device-ai.md#what-each-card-is-given).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `financeAnalysisMaxCategories` | top-level `const int` | B | How many categories one share line lists at most (3). |
| `financeAnalysisInsightSlots` | top-level `const List<InsightSlot>` | B | The card's two slots: `periodPattern`, `periodAdvice`. |
| `_money` | top-level function (private) | B | Format an amount as whole units with the currency code. |
| `_change` | top-level function (private) | B | A signed whole-percent change, or null against zero. |
| [`buildFinanceAnalysisInsightFacts`](#buildfinanceanalysisinsightfacts) | top-level function | A | Build the analysis card's facts for the selected period. |

## Documentation

### `InsightFacts? buildFinanceAnalysisInsightFacts({required DateTime now, required DateTime start, required DateTime end, required String kind, required List<Transaction> transactions, required List<Category> categories, required ExchangeRateData rateData, required String defaultCurrency})` <a id="buildfinanceanalysisinsightfacts"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/finance_analysis_insight_facts.dart`
- **Purpose:** Build the analysis card's facts for the selected period.
- **Inputs:** `now` — local time; `start` — the period's first day; `end` — the day after its
  last; `kind` — `year`, `month`, `day` or `custom`; the page's transactions and categories; the
  rate table; the default currency.
- **Returns:** `InsightFacts?` — null when nothing was spent or earned in the period.
- **Side effects:** None.
- **Notes:**
  1. A period that contains today counts only the days up to today (`so far`); the previous
     period is the same number of days immediately before `start`.
  2. Lines: `- Today:`, `- Period:`, `- Currency:`, `- Spending: … income: …`, `- Change vs the
     previous N days:` (when the previous period had any), `- Top spending categories:` and
     `- Top income categories:` with whole-percent shares, `- Peak spending day:` (two days or
     more), `- Peak spending week:` (fourteen days or more, 7-day weeks from `start`), and
     `- Largest category shift vs the previous period:`.
  3. Conversions follow the Finance page: each transaction at its rate snapshot. Only amounts
     and category names (clipped to 30 characters, quoted terms with the currency code) are sent.

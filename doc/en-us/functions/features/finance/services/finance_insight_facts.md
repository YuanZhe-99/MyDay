# lib/features/finance/services/finance_insight_facts.dart

The pure fact builder behind the Finance page's on-device AI insight card.
`buildFinanceInsightFacts` turns the [Finance page](../views/finance_page.md)'s loaded accounts,
categories, transactions, subscriptions and exchange-rate data into
[`InsightFacts`](../../ai/services/insight_prompts.md): monthly income and spending for this month
and the three before, the top spending categories, the total across accounts, and a subscription
summary with the costliest names and upcoming renewals. Everything is converted to the default
currency the way the Finance page does it ([`balance_util.dart`](balance_util.md),
[`subscription_summary.dart`](subscription_summary.md)) and rounded to whole units. Only
aggregates, category names and subscription names are sent. The card itself is
[`AiInsightCard`](../../ai/widgets/ai_insight_card.md), and the facts are fingerprinted by
[`AiInsightStore`](../../ai/services/insight_service.md). See
[On-device AI — What each card is given](../../../../on-device-ai.md#what-each-card-is-given).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `financeInsightPastMonths` | top-level `const int` | B | How many past months, besides the current one, the trend covers (3). |
| `_money` | top-level function (private) | B | Format an amount as `<whole units> <currency>`. |
| [`buildFinanceInsightFacts`](#buildfinanceinsightfacts) | top-level function | A | Build the Finance card's facts. |

`grep -c 'Purpose:' lib/features/finance/services/finance_insight_facts.dart` reports 2, matching
`_money` and `buildFinanceInsightFacts`.

**Reconciliation:** 3 rows against 2 `Purpose:` blocks. The extra row is
`financeInsightPastMonths`, a real top-level constant with a plain `///` description but no
`Purpose:` block.

## Documentation

### `InsightFacts? buildFinanceInsightFacts({required DateTime now, required List<Account> accounts, required List<Category> categories, required List<Transaction> transactions, required List<Subscription> subscriptions, required ExchangeRateData rateData, required String defaultCurrency, int maxNames = 5})` <a id="buildfinanceinsightfacts"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/finance_insight_facts.dart` (line 30)
- **Purpose:** Build the Finance card's facts.
- **Inputs:** `now` — local time; the page's `accounts`, `categories`, `transactions`,
  `subscriptions`, `rateData`, `defaultCurrency`; `maxNames` — cap on the subscription name lists.
- **Returns:** `InsightFacts?` with `module: finance`, bucket `none`, four slots (`flowSummary`,
  `flowAdvice`, `subSummary`, `subAdvice`) and the quoted terms — or null when there are no
  transactions and no active subscriptions.
- **Side effects:** None.
- **Algorithm:**
  1. `- Today:` with the day of the month and the month's length; `- Currency:`.
  2. For this month and the `financeInsightPastMonths` before it (oldest first): income, spending
     and entry count, counting only `income` and `expense` transactions, each converted at the rate
     snapshot it was recorded under (`rateData.ratesAt(t.rateSnapshotId)`). The current month is
     labelled `(so far)`.
  3. Top three spending categories this month and last month (unknown categories as
     `uncategorised`), names clipped to 30 runes and added to the quoted terms.
  4. When there are accounts: the total of `accountBalance` over all accounts, converted at current
     rates.
  5. The active subscription count; when non-zero, the projected monthly, observed monthly and
     yearly cost from `summarizeSubscriptions`, the `maxNames` costliest by monthly equivalent at
     current rates (monthly: amount ÷ interval; yearly: amount ÷ (interval × 12)), and renewals in
     the next 7 days from `upcomingSubscriptions`. Those names are quoted terms too.
- **Usage:**
  ```dart
  final facts = buildFinanceInsightFacts(
    now: now,
    accounts: _accounts,
    categories: _categories,
    transactions: _transactions,
    subscriptions: _subscriptions,
    rateData: _rateData,
    defaultCurrency: _defaultCurrency,
  );
  ```
  (`lib/features/finance/views/finance_page.dart`, line 631; covered by
  `test/insight_facts_test.dart`.)
- **Notes:** Reads nothing from an account except its id, currency and balance, and never reads a
  note, so card numbers, expiry dates, security codes, bank names and notes cannot reach the model.
  Transfers are excluded from income and spending. The subscription slots are requested even when
  there are no active subscriptions (the facts then say `0`). Whole-unit rounding keeps the
  fingerprint stable against tiny rate changes.

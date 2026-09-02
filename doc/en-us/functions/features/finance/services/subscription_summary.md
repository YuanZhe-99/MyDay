# lib/features/finance/services/subscription_summary.dart

The subscription figures and orderings that more than one page shows. Until v1.4.3 all of this was
private to the subscriptions page; when the finance home gained a subscription overview in its
summary pane, the three statistics, the sort, and the upcoming-renewal filter moved here so both
surfaces read one implementation and can never disagree on the same data. The module imports
nothing from Flutter. See [Finance](../../../../features/finance.md#views-and-analysis-page) for
where the two surfaces sit, and
[Subscription Billing](../../../../algorithms/subscription-billing.md) for how `nextBillingDate`
is advanced.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SubscriptionSummary` | top-level `typedef` (record) | B | The `monthlyDue` / `monthlyAvg` / `yearlyAvg` triple, in the default currency. |
| `subscriptionSortNextRenewal` | top-level `const String` | B | Sort mode id `'nextRenewal'`: soonest next billing date first, undated last. |
| `subscriptionSortName` | top-level `const String` | B | Sort mode id `'name'`: case-insensitive by name. |
| `subscriptionSortCustom` | top-level `const String` | B | Sort mode id `'custom'`: the user's drag order. |
| [`summarizeSubscriptions`](#summarizesubscriptions) | top-level function | A | Compute monthly due, monthly average and yearly average for the active subscriptions. |
| [`sortSubscriptions`](#sortsubscriptions) | top-level function | A | Return a copy of a subscription list sorted by a sort mode. |
| [`upcomingSubscriptions`](#upcomingsubscriptions) | top-level function | A | List the subscriptions billing within N days, soonest first. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/services/subscription_summary.dart`
reports 3, matching the three functions; the typedef and the three sort-mode constants carry a
one-line prose comment rather than a `Purpose:` block, as top-level constants do elsewhere, and get
rows because they are the file's public surface. 3 Tier A, 4 Tier B.

## Documentation

### `SubscriptionSummary summarizeSubscriptions({required List<Subscription> subscriptions, required List<Transaction> transactions, required ExchangeRateData rateData, required String defaultCurrency, DateTime? now})` <a id="summarizesubscriptions"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/subscription_summary.dart` (line 37)
- **Purpose:** Compute the three headline subscription figures in the default currency.
- **Inputs:** `subscriptions` — inactive ones are ignored; `transactions` — only those with a
  `subscriptionId` count; `rateData`; `defaultCurrency`; `now`, injectable for tests.
- **Returns:** `SubscriptionSummary`.
- **Side effects:** None.
- **Algorithm:**
  1. `monthlyDue`: for each active subscription, `amount / interval` for a monthly cycle or
     `amount / (interval * 12)` for a yearly one, converted at `rateData.currentRates` via
     [`convertCurrency`](balance_util.md#convertcurrency), summed.
  2. `monthlyAvg`: filter the subscription-tagged transactions; if none, use `monthlyDue`. Otherwise
     take the earliest one's date and count whole calendar months to `now`; below two, use
     `monthlyDue`; otherwise sum every tagged transaction converted at **its own** rate snapshot
     (`rateData.ratesAt(t.rateSnapshotId)`) and divide by the months.
  3. `yearlyAvg = monthlyDue * 12`.
- **Usage:** `summarizeSubscriptions(subscriptions: _subscriptions, transactions: _transactions, rateData: _rateData, defaultCurrency: _defaultCurrency)`
  in `_FinancePageState.build` and `_SubscriptionsPageState.build`.
- **Notes:** Monthly due is a projection from billing parameters at today's rates; monthly average
  is observed spend at each transaction's own rate vintage. The two cards can therefore diverge in
  method and in exchange rate, which is intended — the projection says what the subscriptions cost
  now, the average says what they have cost.

### `List<Subscription> sortSubscriptions(List<Subscription> list, {required String mode, required List<String> customOrder})` <a id="sortsubscriptions"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/subscription_summary.dart` (line 100)
- **Purpose:** Return a sorted copy of `list` for a subscription sort mode.
- **Inputs:** `list`; `mode` — one of the three sort-mode constants; `customOrder` — ids in the
  user's drag order, read only in custom mode.
- **Returns:** `List<Subscription>` — a new list; the input is not mutated.
- **Side effects:** None.
- **Algorithm:** `'name'` → case-insensitive alphabetical. `'custom'` → by each id's index in
  `customOrder`, with missing ids at the end (sentinel index `customOrder.length`); an empty
  `customOrder` leaves the order untouched. Anything else → `nextBillingDate` ascending with nulls
  last.
- **Usage:** The subscriptions page's `_active` getter and the finance home's `activeSubs`, both
  passing the stored `subscriptionSortMode` / `subscriptionCustomOrder`.
- **Notes:** The empty-custom-order no-op is relied on by `_onSortModeChanged`, which seeds the
  order only after switching into custom mode.

### `List<(Subscription, DateTime)> upcomingSubscriptions(List<Subscription> subscriptions, {required int days, DateTime? now})` <a id="upcomingsubscriptions"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/subscription_summary.dart` (line 145)
- **Purpose:** Collect the subscriptions whose next billing day falls within `days` days of today,
  for the two "upcoming renewals" chip rows.
- **Inputs:** `subscriptions`, `days`, `now` (injectable for tests).
- **Returns:** `List<(Subscription, DateTime)>`, each paired with its next billing date, sorted
  ascending.
- **Side effects:** None.
- **Algorithm:** `limit = today + days`; skip `cancelType == atExpiry` regardless of `isActive`,
  and skip `!isActive && cancelType == immediate`; include a subscription whose `nextBillingDate`'s
  calendar day is on or before `limit`; sort by date.
- **Usage:** `upcomingSubscriptions(_subscriptions, days: 3)` in both pages' `build`.
- **Notes:** An at-expiry cancellation keeps showing in subscription lists but must not raise a
  renewal reminder for a charge that, from the user's perspective, is about to stop — so this
  filter is stricter than the `isActive` split the lists use. Before v1.4.3 the two pages carried
  two identical private copies of this function.

## Related pages

- [`finance_page.md`](../views/finance_page.md) — the home page's subscription overview, the
  second consumer that motivated this module.
- [`subscriptions_page.md`](../views/subscriptions_page.md) — the original consumer.
- [`balance_util.md`](balance_util.md) — `convertCurrency`.
- [`exchange_rate_storage.md`](exchange_rate_storage.md) — `currentRates` / `ratesAt`.

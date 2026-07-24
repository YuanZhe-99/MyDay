# Finance

Model source: `lib/features/finance/models/finance.dart`. Services:
`lib/features/finance/services/{balance_util,bank_preset_service,exchange_rate_api,
exchange_rate_storage,finance_storage,subscription_processor}.dart`. See
[Data Formats](../data-formats.md#finance--finance_datajson) for the full field list and
[Subscription Billing](../algorithms/subscription-billing.md) for the month-end clamping deep dive.

## Model

- **`AccountType`**: `fund`, `credit`, `recharge`, `financial`.
- **`Account`**: bank/app, account name, currency, optional card metadata, emoji/image, optional
  monthly-fee waiver amounts — `feeWaiverMinimumBalance` and `feeWaiverMonthlyDeposit` are treated
  as **alternative** criteria when both are present (meeting either one waives the fee), legacy
  forced-balance sentinel fields, `modifiedAt`.
- **`Transaction`**: amount/currency, a historical rate-snapshot id, account ids, transfer target
  fields, category/subscription ids, note, date, `modifiedAt`.
- **`Category`**: name, `IconRef`, emoji, transaction type, `modifiedAt`. Transfer categories are
  supported (not just expense/income).
- **`Subscription`**: trial, billing cycle/interval, amount/currency, account/category, cancellation
  mode, persisted `nextBillingDate`, `modifiedAt`.
- **`IconRef`** stores a Material icon code point and font family. Because icon data is
  reconstructed dynamically from these two fields, release builds need `--no-tree-shake-icons`.

## Forced-balance migration to adjustment transactions

New-version account balances are calculated **from transactions only** — there is no stored
"current balance" field that transactions merely adjust. Setting a current balance in the UI
instead:

1. Creates an income or expense **adjustment transaction** for the delta needed to reach the
   entered balance.
2. Stores the legacy sentinel `forcedBalance: 0` and `forcedBalanceDate: 1970-01-01T00:00:00.000Z`
   on the account purely for **old-version compatibility** (so an older app build reading this
   account still sees a forced-balance value it understands, just one that resolves to "no
   override").

`balance_util.dart` still knows how to reconstruct historical balances around forced-balance
anchors for accounts that predate this migration.

## Exchange rates

- **`ExchangeRateStorage`**: snapshot-based history — deduplicated `RateSnapshot`s plus a
  `currentSnapshotId`, migrated forward from an older flat currency→rate map format.
- **`ExchangeRateApi`**: fetches from `https://open.er-api.com/v6/latest/{base}` with no API key,
  updates only configured currency pairs, and fetches **at most once per day**.
- **`balance_util.dart` conversion logic**: currency symbols (`'CNY' => '¥'`, `'USD' => '\$'`,
  `'EUR' => '€'`, …), and `convertCurrency(rates, amount, from, to, {onMissingRate})` tries, in
  order: a **direct** rate, a **reverse** rate, then a path through an **intermediate** currency —
  `for (final via in ['CNY', 'USD', 'EUR'])`. When no direct/reverse/intermediate path exists at
  all, the amount falls back to a **1:1** conversion and the optional `onMissingRate(from, to)`
  callback fires so the silent distortion can be surfaced. The Finance home summary shows a warning
  listing the affected currency pairs whenever any conversion fell back this way during that
  render.

## `BankPresetService`

Loads 250+ bank presets from `assets/banks.json` (`rootBundle.loadString('assets/banks.json')`),
country currency defaults, search/grouping, and multiple logo URL sources.

## Subscription processing

**`SubscriptionProcessor`** (see [Subscription Billing](../algorithms/subscription-billing.md) for
the full algorithm) provides:

- **Hourly renewal catch-up**, driven by the persisted `nextBillingDate` field on each subscription
  rather than recomputing from `startDate` every time.
- **Multi-cycle catch-up**: if the app was not opened for several billing cycles, all of them are
  generated in one pass.
- **Idempotent billing-day generation**: existing random-id (older, historical) or stable-id (newer)
  transactions are both recognized, so re-running the processor never double-bills a day.
- **At-expiry cancellation handling**: an `atExpiry`-cancelled subscription keeps billing up to its
  `cancelledAt` cutoff, then stops and flips `isActive` to `false`.
- **Month-end clamping via `Subscription.nextBillingCursor`**: every billing-date advance (both the
  model's own helpers and `SubscriptionProcessor`) routes through this one cursor function, which
  clamps a month-end anchor day to the target month's actual length instead of letting `DateTime`
  day overflow skip or drift months — e.g. a Jan 31 monthly subscription bills Feb 28/29, Mar 31,
  Apr 30, … and never skips a month. This is the standout algorithm in the Finance module; see
  [Subscription Billing](../algorithms/subscription-billing.md) and the concrete worked dates in
  [Subscription Billing Walkthrough](../examples/subscription-billing-walkthrough.md).

## Views and analysis page

Finance views cover selectable-month home summaries and grouped monthly transactions, accounts with
optional monthly-fee waiver criteria, account transaction pages with direct add-transaction support,
transaction account picker sorting/grouping/"More" settings from the account page, categories,
category details, exchange rates, subscriptions, subscription details, and analysis charts.
Subscriptions can be cancelled immediately or at expiry; a pending at-expiry cancellation can be
restored in place, while an expired or fully-cancelled subscription restores by copying its settings
into a **new** active subscription with today's date and a new id.

The **analysis page** includes: clickable expense/income category breakdowns including
uncategorized flows, category transaction drill-down with add/edit/delete support, expense/income
trends, editable custom date ranges, and a total-assets trend that reconstructs account balances at
sample points.

## Related pages

- [Data Formats](../data-formats.md) — exact JSON shape of every model above.
- [Subscription Billing](../algorithms/subscription-billing.md) — the month-end clamping algorithm
  in full detail.
- [Subscription Billing Walkthrough](../examples/subscription-billing-walkthrough.md) — concrete
  Jan→Apr dates.
- [Three-Way Merge](../algorithms/three-way-merge.md) — how accounts/categories/transactions/
  subscriptions merge across devices.

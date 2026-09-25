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

**Bundled bank logos (v1.4.5).** Full builds ship reviewed logos under `assets/bank_logos/` for 219
of the 267 unique presets (`<country>/<id>` keys; `assets/banks.json` has 269 rows because
`gb/revolut` and `gb/wise` appear twice): 165 SVG and 54 PNG, about 2.7 MB. Picking one of those
presets no longer needs the network; the other 48 use the network chain as before.

- **Lookup order: bundled → network.** When a preset is picked in the account dialog,
  `_fetchBankIcon` first copies the preset's bundled logo into `images/`
  (`ImageService.copyAssetImage`); if there is none, or it fails to load, it walks the
  `BankPreset.logoUrls` network chain as before. The bank preset picker shows the same order per row
  through `BankLogoImage` (bundled logo → Clearbit preview → initial letter).
- **Store builds ship none.** `BankPreset.bundledLogoAsset` returns null when
  `bundledBankLogosEnabled` is false (`lib/app/build_flavor.dart`), and CI strips the logo files,
  the pubspec asset line, and the manifest entries before building the Store AAB. Store builds use
  the network chain only. See [Architecture](../architecture.md) and [CI/CD](../ci-cd.md).
- **Manifest keying.** The generated logo manifest
  `lib/features/finance/services/bank_logo_manifest.g.dart` maps `BankPreset.key` (`<country>/<id>`)
  to `assets/bank_logos/<country>_<id>.<svg|png>`. The key is country-qualified because preset ids
  repeat across countries (`icbc`, `hsbc`, `vtb`, …).
- **SVG rendering.** A bundled logo may be an SVG, so a stored account or subscription image may now
  be `images/<uuid>.svg`. Every Finance display site renders stored images through `StoredImage` /
  `StoredImageAvatar` (`lib/shared/widgets/stored_image.dart`), which choose the SVG or raster
  decoder by extension; SVG logos always sit on a white disc with `contain`, so wordmarks stay whole
  and legible in dark mode. The Intimacy module still uses `FileImage` — its images only come from
  the file picker.
- **Trademarks.** The logos are the institutions' own marks, bundled only so users can recognize
  their own accounts. Store builds ship none. `tool/bank_logo_choices.json` records each review
  decision (`"c0.svg"`, `"s1.png"`, `"c0.svg@png"`, or `"reject"`), so any single logo can be
  removed (set it to `"reject"`) and the set rebuilt. A preset with no entry gets no bundled logo,
  exactly like a rejected one.

To add or replace a logo:

1. **Fetch candidates** into a scratch directory (never into `assets/`):
   `dart run tool/fetch_bank_logos.dart --out <scratch dir> [--only <country_id,...>] [--infobox]`.
   Phase 1 resolves Commons file names from Wikidata — the small logo/icon (P8972/P2910) and logo
   (P154) of the entity whose official website matches the preset's domain, else a per-name entity
   search — and caches them in `<out>/plan.json`. Phase 2 resolves direct file URLs through the
   Commons API in batches of 50 and downloads each file slowly (900 ms spacing, honoring
   `Retry-After` on HTTP 429); it avoids `Special:FilePath` redirects, which are throttled. Both
   phases resume from their caches. `--infobox` reads the logo from the English and local-language
   Wikipedia infoboxes for presets Wikidata has nothing for (many logos are local, non-Commons
   files). `--site --only <country_id,...>` appends candidates `s0`, `s1`, … from the bank's own homepage
   (logo `<img>`, SVG icon, apple-touch-icon, `og:image`). Optional direct URLs per key go in
   `tool/bank_logo_overrides.json`.
2. **Review** with `dart run tool/bank_logo_sheet.dart --dir <scratch dir> [--only <country_id,...>]`: HTML
   contact sheets of 12 presets per page (`sheet_<country>_<n>.html`), each candidate labelled by
   its file name and shown at avatar and large size on light and dark backgrounds.
3. **Record the decision** in `tool/bank_logo_choices.json`: a candidate file name, a file name plus
   `@png` for an SVG that flutter_svg cannot draw, or `"reject"`.
4. **Install** with `dart run tool/apply_bank_logo_choices.dart --dir <scratch dir>`, which rebuilds
   `assets/bank_logos/` from scratch and regenerates the manifest. SVGs get their `<style>` rules
   inlined into `style` attributes (flutter_svg ignores style sheets, so most Illustrator exports
   otherwise render black). `@png` installs Wikimedia's 500 px PNG rendering of the SVG instead
   (Wikimedia serves only standard thumbnail widths; 512 returns HTTP 400) — for files flutter_svg
   cannot draw even after inlining, such as `foreignObject` or some clip/gradient combinations.
   Rasters (PNG, JPEG, WebP, GIF) are centered on a white square with a margin and scaled to exactly
   256 px. `dart run tool/gen_bank_logo_manifest.dart` regenerates only the manifest from what is in
   `assets/bank_logos/`.
5. **Verify in flutter_svg, not the browser.** A browser rendering does not prove flutter_svg can
   draw a file, so the installed SVGs were each rendered through flutter_svg itself
   (`vg.loadPicture`) and compared side by side with the browser rendering
   (`dart run tool/bank_logo_sheet.dart --final` gives the browser side). Then run
   `flutter test test/bank_logo_manifest_test.dart`, which checks that the manifest matches the
   directory exactly, every SVG parses in flutter_svg, and every PNG is square and at least 128 px.

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

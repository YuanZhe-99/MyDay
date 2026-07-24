# lib/features/finance/services/balance_util.dart

The core balance/currency-conversion logic for Finance, plus the one-time forced-balance-to-
adjustment-transaction migration. Account balances are computed purely by folding
[`Transaction`](../models/finance.md#transaction-new)s (`accountBalance`/`accountBalanceBefore`) —
there is no stored "current balance" field — and every cross-currency amount goes through
[`convertCurrency`](#convertcurrency), which tries a direct rate, a reverse rate, then a path through
an intermediate currency before falling back to a distorting 1:1 conversion. See
[Finance](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions) for
the migration this file implements and
[Finance](../../../../features/finance.md#exchange-rates) for the conversion logic's role in the
feature; [`ExchangeRateStorage`](exchange_rate_storage.md) is the snapshot history `convertCurrency`
and `accountBalance` read rates from.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`ForcedBalanceMigrationResult()`](#forcedbalancemigrationresult-new) | const constructor (`ForcedBalanceMigrationResult`) | A | Bundle the migrated accounts/transactions and whether anything changed. |
| [`currencySymbol`](#currencysymbol) | top-level function | A | Return the display symbol for a currency code. |
| [`_findRate`](#findrate) | top-level function | A | Find a direct or reverse rate between two currencies. |
| [`convertCurrency`](#convertcurrency) | top-level function | A | Convert an amount between currencies via direct/reverse/intermediate rates. |
| [`accountBalance`](#accountbalance) | top-level function | A | Calculate an account's balance in its own currency. |
| [`accountBalanceBefore`](#accountbalancebefore) | top-level function | A | Calculate an account's balance immediately before a given date. |
| [`isForcedBalanceSentinelDate`](#isforcedbalancesentineldate) | top-level function | A | Whether a date is the forced-balance migration sentinel. |
| [`hasForcedBalanceSentinel`](#hasforcedbalancesentinel) | top-level function | A | Whether an account already uses the forced-balance sentinel. |
| [`accountWithForcedBalanceSentinel`](#accountwithforcedbalancesentinel) | top-level function | A | Return a copy of an account with forced-balance fields set to the sentinel. |
| [`migrateForcedBalances`](#migrateforcedbalances) | top-level function | A | Migrate old forced balances into ordinary adjustment transactions. |
| [`_forcedBalanceMigrationDelta`](#forcedbalancemigrationdelta) | top-level function | A | Compute the adjustment amount needed for one account's migration. |
| [`_forcedBalanceMigrationTransactionId`](#forcedbalancemigrationtransactionid) | top-level function | A | Build the deterministic id for a migration adjustment transaction. |
| [`_forcedBalanceAdjustmentDate`](#forcedbalanceadjustmentdate) | top-level function | A | Pick the date to record a migration adjustment transaction on. |
| [`_accountTransactionDelta`](#accounttransactiondelta) | top-level function | A | Compute one transaction's signed contribution to an account's balance. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/services/balance_util.dart` returns 14,
matching the 14 rows above exactly — each block sits immediately above its real declaration
(constructor or top-level function); none were found misattached above a call-site statement. The
only other declaration in the file, the top-level `final DateTime forcedBalanceSentinelDate = ...`
variable, carries no `/// Purpose:` block, consistent with this codebase's convention of documenting
callable members rather than plain data, and does not constitute an undocumented callable
declaration. All 14 documented declarations are classified Tier A: this file is the Finance feature's
core balance/conversion/migration logic, and every function contains real branching, looping, or
(for the short id/date helpers) implements an invariant central to the forced-balance migration
algorithm described in [Finance](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)
— none are pure pass-through accessors.

## Documentation

### `const ForcedBalanceMigrationResult({required List<Account> accounts, required List<Transaction> transactions, required bool changed})` <a id="forcedbalancemigrationresult-new"></a>
- **Kind:** const constructor of `ForcedBalanceMigrationResult`
- **Source:** `lib/features/finance/services/balance_util.dart` (line 19)
- **Purpose:** Hold the normalized finance payload produced by one run of
  [`migrateForcedBalances`](#migrateforcedbalances) — the (possibly unchanged) accounts/transactions
  plus whether anything actually changed.
- **Inputs:** All three fields required.
- **Returns:** A new `ForcedBalanceMigrationResult`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor.
- **Usage:**
  ```dart
  return ForcedBalanceMigrationResult(
    accounts: migratedAccounts,
    transactions: migratedTransactions,
    changed: changed,
  );
  ```
  (`lib/features/finance/services/balance_util.dart:250-254`, the return value of
  [`migrateForcedBalances`](#migrateforcedbalances).)
- **Notes:** `changed` lets callers like `FinanceStorage.load()` and
  `WebDAVService._migrateFinanceForcedBalances` skip re-saving data that needed no migration.

### `String currencySymbol(String code)` <a id="currencysymbol"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/balance_util.dart` (line 32)
- **Purpose:** Return the short display symbol for a supported currency code, for amount formatting
  throughout the Finance UI.
- **Inputs:** `code` — an ISO currency code, e.g. `'CNY'`, `'USD'`.
- **Returns:** `String` — the symbol (e.g. `'¥'`, `'\$'`, `'€'`, `'C\$'`), or `code` itself unchanged
  if not one of the 14 explicitly listed currencies.
- **Side effects:** None.
- **Algorithm:** A `switch` expression over `code` with 14 explicit cases (`CNY`/`JPY` both map to
  `'¥'`) and a `_ => code` fallback.
- **Usage:**
  ```dart
  prefixText: '${currencySymbol(_currency)} ',
  ```
  (`lib/features/finance/widgets/add_transaction_dialog.dart:290`; used pervasively across
  `accounts_page.dart`, `subscriptions_page.dart`, `analysis_page.dart`, `category_detail_page.dart`,
  `subscription_detail_page.dart`, and `finance_page.dart` wherever a currency amount is displayed.)
- **Notes:** An unrecognized currency code degrades gracefully to displaying the raw code instead of
  a symbol, rather than throwing.

### `double? _findRate(Map<String, double> rates, String from, String to)` <a id="findrate"></a>
- **Kind:** top-level function (private to this file)
- **Source:** `lib/features/finance/services/balance_util.dart` (line 56)
- **Purpose:** Look up a rate between two currencies, trying the direct pair key first and the
  reverse (inverted) pair key second.
- **Inputs:** `rates` — a `'FROM_TO' -> rate` map; `from`, `to`.
- **Returns:** `double?` — `1.0` if `from == to`; the direct rate if present; `1.0 / reverse` if only
  the reverse pair exists (and is non-zero); `null` if neither exists.
- **Side effects:** None.
- **Algorithm:** Short-circuit equal currencies to `1.0`; look up `rates['${from}_$to']`; if absent,
  look up `rates['${to}_$from']` and invert it (guarding against division by zero).
- **Usage:** Called twice inside [`convertCurrency`](#convertcurrency) — once for a direct/reverse
  lookup between `from`/`to`, and once per candidate intermediate currency for each leg of a
  two-hop conversion.
- **Notes:** Internal helper used within this file only.

### `double convertCurrency(Map<String, double> rates, double amount, String from, String to, {void Function(String from, String to)? onMissingRate})` <a id="convertcurrency"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/balance_util.dart` (line 74)
- **Purpose:** Convert an amount between two currencies using whatever direct, reverse, or
  intermediate-currency rate path is available, falling back to a 1:1 conversion (and reporting it)
  when no path exists at all.
- **Inputs:** `rates` — the rate map to search; `amount`, `from`, `to`; `onMissingRate` — optional
  callback invoked with `(from, to)` only when the 1:1 fallback is used, so the caller can surface
  the silent distortion to the user.
- **Returns:** `double` — the converted amount.
- **Side effects:** Invokes `onMissingRate(from, to)` when no rate path exists; otherwise none.
- **Algorithm:** See [Finance](../../../../features/finance.md#exchange-rates) for the summary. In
  order:
  1. Same currency: return `amount` unchanged.
  2. Direct/reverse: if [`_findRate`](#findrate) finds one, return `amount * rate`.
  3. Intermediate: for each of `['CNY', 'USD', 'EUR']` (skipping one that equals `from`/`to`), try
     both legs via `_findRate`; if both legs resolve, return `amount * leg1 * leg2`.
  4. No path found: call `onMissingRate?.call(from, to)` and return `amount` unchanged (1:1
     fallback).
- **Usage:**
  ```dart
  convertCurrency(
    _rateData.ratesAt(t.rateSnapshotId),
    t.amount,
    t.currency,
    _defaultCurrency,
    onMissingRate: trackMissingRate,
  ),
  ```
  (`lib/features/finance/views/finance_page.dart:413-419`, converting each month's transactions into
  the default currency while tracking any pairs that fell back to 1:1, so the Finance home summary
  can warn about them.)
- **Notes:** The intermediate-currency search order is fixed (`CNY` first, then `USD`, then `EUR`)
  — a rate path through a currency not in this list is never attempted, even if it would otherwise
  resolve.

### `double accountBalance(Account account, List<Transaction> transactions, ExchangeRateData rateData)` <a id="accountbalance"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/balance_util.dart` (line 102)
- **Purpose:** Calculate an account's current balance, in the account's own currency, purely by
  folding every transaction's contribution — there is no stored balance field.
- **Inputs:** `account`; `transactions` — the full transaction list (not pre-filtered); `rateData`.
- **Returns:** `double`.
- **Side effects:** None.
- **Algorithm:** Fold `transactions` through
  [`_accountTransactionDelta`](#accounttransactiondelta), summing each transaction's signed
  contribution to `account`.
- **Usage:**
  ```dart
  final currentBalance = accountBalance(
    savedAccount,
    _transactions,
    widget.rateData,
  );
  ```
  (`lib/features/finance/views/accounts_page.dart:401-405`, computing the balance right after an
  account edit, used to derive the adjustment transaction amount described in
  [Finance](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions).)
- **Notes:** Iterates the *entire* transaction list on every call — callers displaying many
  accounts' balances (e.g. the accounts list page) call this once per account per rebuild rather
  than computing all balances in a single pass.

### `double accountBalanceBefore(Account account, List<Transaction> transactions, ExchangeRateData rateData, DateTime before)` <a id="accountbalancebefore"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/balance_util.dart` (line 121)
- **Purpose:** Calculate what an account's balance would have been immediately before a given date,
  for the analysis page's total-assets trend reconstruction.
- **Inputs:** `account`; `transactions`; `rateData`; `before` — the exclusive cutoff.
- **Returns:** `double`.
- **Side effects:** None.
- **Algorithm:** Same fold as [`accountBalance`](#accountbalance), but skips any transaction whose
  `date` is not strictly before `before`.
- **Usage:**
  ```dart
  final balance = accountBalanceBefore(
    account,
    _transactions,
    widget.rateData,
    before,
  );
  ```
  (`lib/features/finance/views/analysis_page.dart:862-867`, reconstructing each account's balance at
  a sample point along the total-assets trend chart.)
- **Notes:** `before` is exclusive — a transaction dated exactly `before` is not counted, which is
  why the analysis page's sample-point iteration passes the start of the *next* period as `before`
  to include everything up through the end of the current one.

### `bool isForcedBalanceSentinelDate(DateTime date)` <a id="isforcedbalancesentineldate"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/balance_util.dart` (line 142)
- **Purpose:** Detect whether a date is the forced-balance migration sentinel (`1970-01-01T00:00:00`)
  regardless of whether it's encoded as UTC epoch zero or as a local-time midnight matching those
  calendar fields.
- **Inputs:** `date`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `true` if `date.toUtc().millisecondsSinceEpoch == 0`; otherwise `true` only if every
  one of `date`'s year/month/day/hour/minute/second/millisecond/microsecond fields matches
  1970-01-01 00:00:00.000000 exactly.
- **Usage:** Called from [`hasForcedBalanceSentinel`](#hasforcedbalancesentinel) and
  [`_forcedBalanceAdjustmentDate`](#forcedbalanceadjustmentdate) — both internal to this file.
- **Notes:** The dual check (UTC-epoch-zero OR local-midnight-1970) exists because a `DateTime` built
  as `forcedBalanceSentinelDate` (always UTC) and one parsed from an older on-disk record that
  omitted a UTC marker could represent "the sentinel" without being `==`-equal to each other.

### `bool hasForcedBalanceSentinel(Account account)` <a id="hasforcedbalancesentinel"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/balance_util.dart` (line 159)
- **Purpose:** Decide whether an account has already had its forced-balance fields replaced by the
  sentinel — i.e. whether old forced-balance state has already been discarded and the migration is a
  no-op for this account.
- **Inputs:** `account`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `(account.forcedBalance ?? 0) == 0 && account.forcedBalanceDate != null &&
  isForcedBalanceSentinelDate(account.forcedBalanceDate!)`.
- **Usage:**
  ```dart
  } else if (a.forcedBalance != null && !hasForcedBalanceSentinel(a)) {
    _balanceController.text = a.forcedBalance!.toStringAsFixed(2);
    _forcedBalanceDate = a.forcedBalanceDate ?? DateTime.now();
  }
  ```
  (`lib/features/finance/views/accounts_page.dart:1563-1565`, deciding whether to show a legacy
  forced-balance value in the edit-account dialog; also gates the per-account branch inside
  [`migrateForcedBalances`](#migrateforcedbalances).)
- **Notes:** This is the single gate that decides — both in the UI and inside the migration loop —
  whether an account still carries pre-migration forced-balance state.

### `Account accountWithForcedBalanceSentinel(Account account, {DateTime? modifiedAt})` <a id="accountwithforcedbalancesentinel"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/balance_util.dart` (line 169)
- **Purpose:** Return a copy of an account with its forced-balance fields replaced by the sentinel
  (`forcedBalance: 0`, `forcedBalanceDate: 1970-01-01T00:00:00.000Z`), preserving every other field.
- **Inputs:** `account`; `modifiedAt` — optional override, otherwise `account.modifiedAt` is kept.
- **Returns:** A new `Account`.
- **Side effects:** None.
- **Algorithm:** Reconstruct an `Account` copying every non-balance field verbatim, with
  `forcedBalance: 0` and `forcedBalanceDate: forcedBalanceSentinelDate`.
- **Usage:**
  ```dart
  final account = accountWithForcedBalanceSentinel(submittedAccount);
  final adjTx = _balanceAdjustmentTransaction(account: account, ...);
  ```
  (`lib/features/finance/views/accounts_page.dart:360-363`, the new-version "set current balance"
  flow: the UI computes an adjustment transaction for the entered balance and saves the account with
  the sentinel already in place, per
  [Finance](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions).)
- **Notes:** Use this before saving accounts from new-version balance-adjustment flows; it is also
  the terminal step of [`migrateForcedBalances`](#migrateforcedbalances)'s per-account loop.

### `ForcedBalanceMigrationResult migrateForcedBalances({required List<Account> accounts, required List<Transaction> transactions, required ExchangeRateData rateData, String adjustmentNote = 'Balance Adjustment'})` <a id="migrateforcedbalances"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/balance_util.dart` (line 197)
- **Purpose:** One-time migration that converts every account's legacy non-sentinel forced balance
  into a deterministic adjustment transaction, then stamps the account with the forced-balance
  sentinel so it is never re-migrated.
- **Inputs:** `accounts`, `transactions`, `rateData`; `adjustmentNote` — the note text on generated
  adjustment transactions (defaults `'Balance Adjustment'`).
- **Returns:** `ForcedBalanceMigrationResult` — `accounts`/`transactions` unchanged in content if no
  account needed migrating (`changed: false`), otherwise the migrated lists.
- **Side effects:** None (pure function returning new lists; the caller decides whether/how to
  persist them).
- **Algorithm:**
  1. For each account: skip (keep as-is) if it has neither `forcedBalance` nor `forcedBalanceDate`
     set, or if [`hasForcedBalanceSentinel`](#hasforcedbalancesentinel) is already `true`.
  2. Otherwise, if `forcedBalance != 0`, compute the adjustment delta via
     [`_forcedBalanceMigrationDelta`](#forcedbalancemigrationdelta) and, if it's non-trivial
     (`> 0.000001`) and a transaction with the same deterministic id doesn't already exist, append a
     new income/expense `Transaction` (sign from the delta's sign) dated via
     [`_forcedBalanceAdjustmentDate`](#forcedbalanceadjustmentdate) with id from
     [`_forcedBalanceMigrationTransactionId`](#forcedbalancemigrationtransactionid).
  3. Replace the account with [`accountWithForcedBalanceSentinel`](#accountwithforcedbalancesentinel)
     (stamping `modifiedAt` to now) and mark `changed = true`.
- **Usage:**
  ```dart
  final migration = migrateForcedBalances(
    accounts: data.accounts,
    transactions: data.transactions,
    rateData: rateData,
  );
  ```
  (`lib/shared/services/webdav_service.dart:428-431`, inside `_migrateFinanceForcedBalances`, run on
  every merged finance payload during sync; the identical call shape runs from
  [`FinanceStorage`](finance_storage.md#migrateforcedbalances)'s private `_migrateForcedBalances`
  wrapper on every local load.)
- **Notes:** The deterministic transaction id (from
  [`_forcedBalanceMigrationTransactionId`](#forcedbalancemigrationtransactionid)) means re-running
  this migration against already-migrated data — e.g. after a sync merge reintroduces the same
  account state — never creates a duplicate adjustment transaction.

### `double _forcedBalanceMigrationDelta(Account account, List<Transaction> transactions, ExchangeRateData rateData)` <a id="forcedbalancemigrationdelta"></a>
- **Kind:** top-level function (private to this file)
- **Source:** `lib/features/finance/services/balance_util.dart` (line 262)
- **Purpose:** Compute the adjustment amount needed so that, after adding it as a transaction dated
  at the forced-balance cutoff, the account's transaction-derived balance matches the old forced
  balance value.
- **Inputs:** `account`; `transactions`; `rateData`.
- **Returns:** `double` — signed delta (positive = income adjustment, negative = expense adjustment).
- **Side effects:** None.
- **Algorithm:** Start `delta = account.forcedBalance ?? 0.0`; if `forcedBalanceDate` is `null`,
  return that as-is; otherwise subtract every transaction's contribution
  ([`_accountTransactionDelta`](#accounttransactiondelta)) for each transaction dated at or before
  the cutoff — i.e. `delta` ends up as "what's still needed on top of transactions recorded up to the
  cutoff to reach the old forced balance."
- **Usage:** Called once inside [`migrateForcedBalances`](#migrateforcedbalances):
  `_forcedBalanceMigrationDelta(account, transactions, rateData)`.
- **Notes:** Internal helper used within this file only.

### `String _forcedBalanceMigrationTransactionId(Account account)` <a id="forcedbalancemigrationtransactionid"></a>
- **Kind:** top-level function (private to this file)
- **Source:** `lib/features/finance/services/balance_util.dart` (line 284)
- **Purpose:** Build a deterministic transaction id for one account's migration-adjustment
  transaction, so re-running the migration never creates a duplicate.
- **Inputs:** `account`.
- **Returns:** `String` — `'forced-balance-migration:<id>:<forcedBalance>:<forcedBalanceDate or
  "none">:<modifiedAt>'`.
- **Side effects:** None.
- **Algorithm:** String interpolation of the account's id, its old `forcedBalance`/
  `forcedBalanceDate` (or `'none'` if absent), and its `modifiedAt`, all as ISO strings where
  applicable.
- **Usage:** Called once inside [`migrateForcedBalances`](#migrateforcedbalances):
  `final txId = _forcedBalanceMigrationTransactionId(account);`, then checked against
  `existingTransactionIds` before appending.
- **Notes:** Including `modifiedAt` in the id means that if the same account is migrated more than
  once across different sync states (each with a different `modifiedAt`), each produces a distinct
  migration transaction rather than being silently deduplicated against a stale one — the dedup
  guarantee only holds for repeated migrations of the *exact same* account state.

### `DateTime _forcedBalanceAdjustmentDate(Account account)` <a id="forcedbalanceadjustmentdate"></a>
- **Kind:** top-level function (private to this file)
- **Source:** `lib/features/finance/services/balance_util.dart` (line 295)
- **Purpose:** Pick the date to record a migration-adjustment transaction on, preferring the
  account's original forced-balance cutoff when it's meaningful.
- **Inputs:** `account`.
- **Returns:** `DateTime`.
- **Side effects:** None.
- **Algorithm:**
  1. If `forcedBalanceDate` is set and is not itself the sentinel, use it directly.
  2. Otherwise, if `account.modifiedAt` is after the sentinel date, use `modifiedAt`.
  3. Otherwise fall back to `DateTime.now()`.
- **Usage:** Called once inside [`migrateForcedBalances`](#migrateforcedbalances), as the `date:` of
  the generated adjustment `Transaction`.
- **Notes:** The fallback chain ensures a migrated account always gets a plausible adjustment date
  even if its old forced-balance metadata was itself degenerate (missing or already the sentinel).

### `double _accountTransactionDelta(Account account, Transaction tx, ExchangeRateData rateData)` <a id="accounttransactiondelta"></a>
- **Kind:** top-level function (private to this file)
- **Source:** `lib/features/finance/services/balance_util.dart` (line 311)
- **Purpose:** Compute one transaction's signed contribution to one account's balance, in the
  account's own currency — the fundamental unit both
  [`accountBalance`](#accountbalance) and [`accountBalanceBefore`](#accountbalancebefore) fold over.
- **Inputs:** `account`; `tx`; `rateData` — supplies the historical rate via `ratesAt(tx.rateSnapshotId)`.
- **Returns:** `double` — can be nonzero from either or both of the two branches below, for a
  same-account transfer.
- **Side effects:** None.
- **Algorithm:**
  1. If `tx.accountId == account.id` (this account is the transaction's primary account): convert
     `tx.amount` from `tx.currency` to `account.currency` via
     [`convertCurrency`](#convertcurrency); expense subtracts, income adds, transfer subtracts (money
     leaving the source account).
  2. If `tx.toAccountId == account.id` and `tx.type == transfer` (this account is a transfer's
     target): add the converted amount — using `toAmount`/`toCurrency` if both are set (an explicit
     cross-currency transfer amount), otherwise converting `tx.amount`/`tx.currency` as a same-amount
     transfer.
  3. Return the sum of whichever branches applied (a transaction can affect the same account via
     both branches only in the degenerate case `accountId == toAccountId`, which is not expected to
     occur in practice).
- **Usage:** Called from both [`accountBalance`](#accountbalance) and
  [`accountBalanceBefore`](#accountbalancebefore) as the fold body, and once more inside
  [`_forcedBalanceMigrationDelta`](#forcedbalancemigrationdelta).
- **Notes:** Internal helper used within this file only; this is where the expense/income/transfer
  sign convention for balance calculation is defined — nowhere else in the codebase re-implements it.

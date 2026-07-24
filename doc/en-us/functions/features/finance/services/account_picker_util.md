# lib/features/finance/services/account_picker_util.dart

Pure helper functions behind the transaction account picker's sort/group/custom-order behavior. All
four top-level functions operate on plain [`Account`](../models/finance.md#account-new)/
[`AccountPickerSettings`](../models/finance.md#accountpickersettings-new) values with no IO — the
account-order normalization here is what keeps `AccountPickerSettings.customOrder`/`moreAccountIds`
consistent whenever accounts are added or removed. See
[Finance](../../../../features/finance.md#views-and-analysis-page) for where the account picker fits
in the Finance views.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`_compareAccountText`](#compareaccounttext) | top-level function | A | Case-insensitive comparator for account name/bank text. |
| [`normalizedAccountPickerOrder`](#normalizedaccountpickerorder) | top-level function | A | Return a valid custom picker order for the current account list. |
| [`normalizedAccountPickerSettings`](#normalizedaccountpickersettings) | top-level function | A | Remove stale ids and validate account picker settings. |
| [`sortAccountsForPicker`](#sortaccountsforpicker) | top-level function | A | Sort accounts for transaction account picker display. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/services/account_picker_util.dart`
returns 4, matching the 4 rows above exactly — each block sits immediately above its real top-level
function declaration; none were found misattached above a call-site statement, and no undocumented
declaration exists in the file (it defines nothing besides these four functions). All four are
classified Tier A: each contains real branching/loop logic (`_compareAccountText` implements the
comparator every sort in this file and `sortAccountsForPicker` depends on; the other three build or
validate ordered lists with dedup logic), matching the tiering rule's services/real-logic bucket.

## Documentation

### `int _compareAccountText(String a, String b)` <a id="compareaccounttext"></a>
- **Kind:** top-level function (private to this file)
- **Source:** `lib/features/finance/services/account_picker_util.dart` (line 8)
- **Purpose:** Compare two user-facing account text values (name or bank/app) case-insensitively.
- **Inputs:** `a`, `b`.
- **Returns:** `int` — standard `compareTo` ordering.
- **Side effects:** None.
- **Algorithm:** `a.toLowerCase().compareTo(b.toLowerCase())`.
- **Usage:** Called twice inside [`sortAccountsForPicker`](#sortaccountsforpicker) — once on
  `a.name`/`b.name`, once (as a tiebreaker) on `a.bankOrApp`/`b.bankOrApp`.
- **Notes:** Internal helper used within this file only.

### `List<String> normalizedAccountPickerOrder(List<Account> accounts, List<String> customOrder)` <a id="normalizedaccountpickerorder"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/account_picker_util.dart` (line 16)
- **Purpose:** Produce a de-duplicated ordering of the current accounts that starts with whatever
  ids from `customOrder` are still valid, then appends any account not already covered.
- **Inputs:** `accounts` — the current live account list; `customOrder` — the previously saved
  manual order, which may reference deleted accounts or be missing newly-added ones.
- **Returns:** `List<String>` — account ids, fully covering `accounts` exactly once each.
- **Side effects:** None.
- **Algorithm:**
  1. Build `allIdSet` from the current `accounts`.
  2. Walk `customOrder`, keeping only ids that are both in `allIdSet` and not already `seen`
     (dedup).
  3. Append every account id from `accounts` not yet `seen`, in the accounts list's own order — this
     is how a newly-added account lands at the end of the custom order rather than being dropped.
- **Usage:** Called from [`sortAccountsForPicker`](#sortaccountsforpicker) to build `orderIndex`, and
  from [`normalizedAccountPickerSettings`](#normalizedaccountpickersettings) to normalize
  `customOrder` itself before it's saved.
- **Notes:** Missing current accounts (ids in `customOrder` that no longer exist) are silently
  dropped rather than kept as dangling entries.

### `AccountPickerSettings normalizedAccountPickerSettings(AccountPickerSettings settings, List<Account> accounts)` <a id="normalizedaccountpickersettings"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/account_picker_util.dart` (line 38)
- **Purpose:** Validate and repair a settings value against the current account list — resetting an
  invalid `sortMode`, normalizing `customOrder`, and dropping stale/duplicate `moreAccountIds`.
- **Inputs:** `settings` — as loaded/edited; `accounts` — the current live account list.
- **Returns:** A new `AccountPickerSettings`.
- **Side effects:** None.
- **Algorithm:**
  1. Build the set of current account ids.
  2. `copyWith` the settings: `sortMode` falls back to `sortCustom` unless it's already one of the
     two known constants; `customOrder` is rebuilt via
     [`normalizedAccountPickerOrder`](#normalizedaccountpickerorder); `moreAccountIds` is filtered to
     ids that still exist and de-duplicated in place.
- **Usage:**
  ```dart
  _accountPickerSettings = normalizedAccountPickerSettings(
    widget.accountPickerSettings,
    _accounts,
  );
  ```
  (`lib/features/finance/views/accounts_page.dart:124-127`, run once in `initState`; the same call
  shape recurs in `_normalizeAccountPickerSettings` and `_openAccountPickerSettings` whenever
  accounts change or settings are edited.)
- **Notes:** Use this before saving settings edited by the account picker settings page — it is the
  single place that guarantees `customOrder`/`moreAccountIds` never reference a deleted account.

### `List<Account> sortAccountsForPicker(List<Account> accounts, AccountPickerSettings settings)` <a id="sortaccountsforpicker"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/services/account_picker_util.dart` (line 63)
- **Purpose:** Produce the display order for the transaction account picker, honoring type grouping,
  the chosen sort mode, and falling back to original list order as a final tiebreaker.
- **Inputs:** `accounts`; `settings` — `groupByType` and `sortMode` (`sortName` or `sortCustom`
  after normalization) drive the comparator.
- **Returns:** `List<Account>` — a new sorted list; `accounts` itself is not mutated.
- **Side effects:** None.
- **Algorithm:**
  1. Copy `accounts` into `sorted`; build `originalIndex` (id -> original position) and, via
     [`normalizedAccountPickerOrder`](#normalizedaccountpickerorder), `orderIndex` (id -> custom-order
     position).
  2. Sort with a composite comparator:
     - If `groupByType`, compare `a.type.index` vs `b.type.index` first; a non-zero result wins.
     - If `sortMode == sortName`, compare by [`_compareAccountText`](#compareaccounttext) on `name`,
       then on `bankOrApp` as a tiebreaker.
     - Otherwise (custom order), compare by each account's position in `orderIndex` (unmatched ids
       sort after all known ones, via `?? order.length`).
     - Final tiebreaker in every branch: original list position (`originalIndex`).
- **Usage:**
  ```dart
  List<Account> get _displayAccounts => sortAccountsForPicker(
    widget.accounts,
    AccountPickerSettings(
      sortMode: _sortMode,
      groupByType: _groupByType,
      ...
    ),
  );
  ```
  (`lib/features/finance/views/accounts_page.dart:958-963`, the account picker's live display list
  getter.)
- **Notes:** Type grouping changes only the primary comparison key — within each type group, the
  chosen `sortMode`'s ordering still applies.

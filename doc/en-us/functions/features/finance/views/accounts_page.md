# lib/features/finance/views/accounts_page.dart

`AccountsPage` is the Finance module's account list: accounts grouped by
[`AccountType`](../../../../features/finance.md#model) section, each section independently
sortable (name / bank / a manual drag-reorder custom order), an add/edit account dialog with
optional monthly-fee-waiver criteria and a legacy forced-balance override, a per-account
transactions sub-page with direct add-transaction support, and a "More settings" sub-page that
edits the *transaction account picker*'s own sort/group/custom-order/more-accounts settings (the
`AccountPickerSettings` used by `AddTransactionDialog`'s account dropdown). See
[Finance](../../../../features/finance.md#views-and-analysis-page) for how this page fits the
Finance views, [Finance — forced-balance migration](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)
for the balance-to-adjustment-transaction behavior implemented here, and
[`balance_util.dart`](../services/balance_util.md) /
[`account_picker_util.dart`](../services/account_picker_util.md) for the shared helpers this file
builds on.

This file actually contains **two independent, similarly-shaped sort/custom-order systems** that
are easy to conflate: (1) `_AccountsPageState`'s own per-type sort mode (`name`/`bank`/`custom`,
stored in `_sortModes`/`_customOrders` maps keyed by `AccountType.name`) that controls how accounts
are grouped and ordered *on this page*, and (2) the `AccountPickerSettings` model
(`sortMode`/`groupByType`/`customOrder`/`moreAccountIds`) edited by `_AccountPickerSettingsPage`
that controls ordering in the *account-picker dropdown* shown by `AddTransactionDialog` elsewhere.
Both happen to reuse the string values `'name'`/`'custom'` for two of their modes, but they are
unrelated fields with unrelated persistence, and only the account-picker one has a `groupByType`
toggle and a `moreAccountIds` "More accounts" list; only this page's own sort has a third `'bank'`
mode.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `_formatAccountConditionAmount` | top-level function | B | Format an account fee-waiver condition amount using the account's currency symbol. |
| [`_accountFeeWaiverSummary`](#accountfeewaiversummary) | top-level function | A | Build the localized fee-waiver summary line for an account, if it has any waiver criteria. |
| `AccountsPage({...})` | constructor (`AccountsPage`) | B | Create the accounts page with initial accounts/transactions/sort/picker state and change callbacks. |
| `AccountsPage.createState` | method (`AccountsPage`) | B | Create `_AccountsPageState`. |
| `_AccountsPageState.initState` | method (`_AccountsPageState`) | B | Copy incoming accounts/transactions/sort maps/picker settings into local mutable state. |
| `_notifyAccounts` | method (`_AccountsPageState`) | B | Push the current account list to `widget.onChanged`. |
| `_notifyTransactions` | method (`_AccountsPageState`) | B | Push the current transaction list to `widget.onTransactionsChanged`. |
| `_notifySort` | method (`_AccountsPageState`) | B | Push sort modes/custom orders to `widget.onSortChanged`. |
| `_notifyAccountPickerSettings` | method (`_AccountsPageState`) | B | Push the current account picker settings to `widget.onAccountPickerSettingsChanged`. |
| `_typeKey` | method (`_AccountsPageState`) | B | Return the map key (`type.name`) used to index the sort/order maps by account type. |
| `_sortMode` (`_AccountsPageState`) | method (`_AccountsPageState`) | B | Return the active sort mode for an account type, defaulting to custom. |
| `_compareText` | method (`_AccountsPageState`) | B | Case-insensitive string comparator, `a.toLowerCase().compareTo(b.toLowerCase())`. |
| [`_normalizedOrder`](#normalizedorder) | method (`_AccountsPageState`) | A | Build a de-duplicated custom order for one account type, keeping valid saved ids first. |
| [`_sortEntries`](#sortentries) | method (`_AccountsPageState`) | A | Sort one account type's entries by name, bank, or custom order. |
| [`_setSortMode`](#setsortmode) | method (`_AccountsPageState`) | A | Switch an account type's sort mode, seeding custom order the first time custom mode is entered. |
| [`_appendAccountToCustomOrderIfNeeded`](#appendaccounttocustomorderifneeded) | method (`_AccountsPageState`) | A | Append a new account into its type's custom order when custom sort is active. |
| [`_removeAccountFromCustomOrders`](#removeaccountfromcustomorders) | method (`_AccountsPageState`) | A | Remove an account id from every type's custom order list. |
| `_normalizeAccountPickerSettings` | method (`_AccountsPageState`) | B | Re-validate `_accountPickerSettings` against the current account list. |
| `_normalizeAndNotifyAccountPickerSettings` | method (`_AccountsPageState`) | B | Normalize picker settings, then notify the parent. |
| [`_reorderAccounts`](#reorderaccounts) | method (`_AccountsPageState`) | A | Move one account within its type's custom order after a drag-and-drop reorder. |
| [`_addAccount`](#addaccount) | method (`_AccountsPageState`) | A | Show the add-account dialog and, on confirmation, insert the account and any resulting balance-adjustment transaction. |
| [`_editAccount`](#editaccount) | method (`_AccountsPageState`) | A | Show the edit-account dialog pre-filled with the current computed balance, then apply edits and any resulting adjustment transaction. |
| [`_balanceAdjustmentTransaction`](#balanceadjustmenttransaction) | method (`_AccountsPageState`) | A | Build the income/expense transaction needed to move an account's balance to a manually-entered target. |
| [`_deleteAccount`](#deleteaccount) | method (`_AccountsPageState`) | A | Remove an account, clean up its custom-order entries, and renormalize picker settings. |
| `_deleteTransaction` (`_AccountsPageState`) | method (`_AccountsPageState`) | B | Remove a transaction by id and notify the parent. |
| [`_openAccountPickerSettings`](#openaccountpickersettings) | method (`_AccountsPageState`) | A | Push the account picker settings page and apply/normalize the returned result. |
| `_AccountsPageState.build` | method (`_AccountsPageState`) | B | Build the grouped, per-type-sorted account list scaffold. |
| `_buildSectionHeader` | method (`_AccountsPageState`, widget helper) | B | Render one account type's header row (label, count, reorder toggle, sort menu). |
| `_sortMenuItem` | method (`_AccountsPageState`, widget helper) | B | Build one popup-menu row for the sort-by menu. |
| [`_buildReorderList`](#buildreorderlist) | method (`_AccountsPageState`, widget helper) | A | Render the drag-to-reorder list for one account type and persist the new order on drop. |
| `_accountTypeLabel` (`_AccountsPageState`) | method (`_AccountsPageState`) | B | Return the localized label for an account type. |
| `_accountTypeIcon` | method (`_AccountsPageState`) | B | Return the icon for an account type. |
| `_accountTypeColor` | method (`_AccountsPageState`) | B | Return the accent color for an account type. |
| [`_buildAccountSubtitle`](#buildaccountsubtitle) | method (`_AccountsPageState`, widget helper) | A | Render the bank/currency line plus the fee-waiver summary line, if any. |
| [`_buildAccountAvatar`](#buildaccountavatar) | method (`_AccountsPageState`, widget helper) | A | Render an account's avatar through an image/emoji/type-icon fallback chain. |
| `_AccountPickerSettingsPage({...})` | constructor (`_AccountPickerSettingsPage`) | B | Create the account picker settings page instance. |
| `_AccountPickerSettingsPage.createState` | method (`_AccountPickerSettingsPage`) | B | Create `_AccountPickerSettingsPageState`. |
| `_AccountPickerSettingsPageState.initState` | method (`_AccountPickerSettingsPageState`) | B | Copy normalized initial settings into local editable state. |
| [`_orderedAccounts`](#orderedaccounts) | getter (`_AccountPickerSettingsPageState`) | A | Return accounts in the custom-order editor's current order, dropping ids with no matching account. |
| `_displayAccounts` | getter (`_AccountPickerSettingsPageState`) | B | Return accounts sorted/grouped per the in-progress settings, for the More-accounts checkbox list. |
| `_accountTypeLabel` (`_AccountPickerSettingsPageState`) | method (`_AccountPickerSettingsPageState`) | B | Return the localized label for an account type. |
| `_save` | method (`_AccountPickerSettingsPageState`) | B | Pop the route with the normalized, edited picker settings. |
| [`_reorderCustomOrder`](#reordercustomorder) | method (`_AccountPickerSettingsPageState`) | A | Move one account within the custom-order editor after a drag-and-drop reorder. |
| `_AccountPickerSettingsPageState.build` | method (`_AccountPickerSettingsPageState`) | B | Build the sort/group/custom-order/More-accounts settings editor. |
| `_AccountTransactionsPage({...})` | constructor (`_AccountTransactionsPage`) | B | Create the account transactions page instance. |
| `_AccountTransactionsPage.createState` | method (`_AccountTransactionsPage`) | B | Create `_AccountTransactionsPageState`. |
| `_AccountTransactionsPageState.initState` | method (`_AccountTransactionsPageState`) | B | Copy incoming transactions into local mutable state. |
| `_handleAdd` | method (`_AccountTransactionsPageState`) | B | Open the add-transaction dialog preselecting the focused account, then insert the result. |
| `_handleDelete` | method (`_AccountTransactionsPageState`) | B | Remove a transaction and notify the parent page. |
| `_handleEdit` | method (`_AccountTransactionsPageState`) | B | Open the edit-transaction dialog and apply the result. |
| `_AccountTransactionsPageState.build` | method (`_AccountTransactionsPageState`) | B | Build the balance/fee-waiver summary card plus this account's grouped transaction list. |
| `_AccountDialog({...})` | constructor (`_AccountDialog`) | B | Create the account dialog, optionally pre-filled for editing. |
| `_AccountDialog.createState` | method (`_AccountDialog`) | B | Create `_AccountDialogState`. |
| `_currencies` | getter (`_AccountDialogState`) | B | Return the currency list, ensuring the account's current currency is included. |
| [`_AccountDialogState.initState`](#initstate) | method (`_AccountDialogState`) | A | Prefill the form from an existing account, choosing between the freshly-computed current balance and a legacy forced balance. |
| `dispose` | method (`_AccountDialogState`) | B | Dispose every text controller. |
| `_AccountDialogState.build` | method (`_AccountDialogState`) | B | Build the add/edit account form (type, name, bank, currency, card, fee-waiver fields, icon, forced balance). |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | method (`_AccountDialogState`) | A | Report whether the form differs from its initial state. |
| [`_signature`](#signature) | method (`_AccountDialogState`) | A | Build a comparable string snapshot of every editable field, including the optional fee-waiver fields. |
| `_buildImagePreview` | method (`_AccountDialogState`, widget helper) | B | Render the selected image (with a remove button) plus the bank-preset/fetch-icon/pick-image action row. |
| [`_pickBankPreset`](#pickbankpreset) | method (`_AccountDialogState`) | A | Open the bank preset picker, apply the chosen bank's name/currency, and auto-fetch its logo. |
| [`_fetchBankIcon`](#fetchbankicon) | method (`_AccountDialogState`) | A | Try each of the selected bank's candidate logo URLs in order until one downloads successfully. |
| `_parseOptionalMoney` | method (`_AccountDialogState`) | B | Parse an optional money field, treating blank/invalid text as absent. |
| [`_submit`](#submit) | method (`_AccountDialogState`) | A | Validate required fields, parse optional balance/fee-waiver amounts, and pop the built `Account`. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/views/accounts_page.dart` returns 64,
matching the 64 rows above exactly. Every block sits immediately above its real declaration (a
top-level function, a constructor, `createState`, `initState`/`dispose`, a getter, or a method);
none were found misattached above a plain call-site statement. The file's eight classes
(`AccountsPage`, `_AccountsPageState`, `_AccountPickerSettingsPage`,
`_AccountPickerSettingsPageState`, `_AccountTransactionsPage`, `_AccountTransactionsPageState`,
`_AccountDialog`, `_AccountDialogState`) and their plain widget fields carry no `/// Purpose:`
block, consistent with this codebase's convention of documenting callable members rather than
classes or data fields; a cross-check for member declarations not immediately preceded by a
`/// Purpose:` block (regex-scanning for method/getter/constructor signatures) found none beyond
those eight classes. Several declaration names repeat across the file's four `State` classes
(`initState`, `build`, `createState`, `_accountTypeLabel`) or across widget/state class pairs
(`createState`); the table above qualifies each with its owning class where the bare name would be
ambiguous, and only the one Tier A `initState` (`_AccountDialogState`) receives an anchor/page
section — the other three `initState`/`build`/`createState` rows are Tier B with no link target.

## Documentation

### `String? _accountFeeWaiverSummary(Account account, AppLocalizations l10n)` <a id="accountfeewaiversummary"></a>
- **Kind:** top-level function (private to this file)
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 33-49)
- **Purpose:** Build the localized, human-readable summary of an account's optional monthly-fee
  waiver criteria, for display under the account's name.
- **Inputs:** `account`; `l10n`.
- **Returns:** `String?` — `null` if the account has neither waiver field set.
- **Side effects:** None.
- **Algorithm:**
  1. Start with an empty `parts` list.
  2. If `account.feeWaiverMinimumBalance` is set, add a line combining
     `l10n.financeFeeWaiverMinimumBalance` with the amount formatted via
     `_formatAccountConditionAmount` (uses the account's own currency symbol).
  3. If `account.feeWaiverMonthlyDeposit` is set, add the equivalent monthly-deposit line.
  4. If `parts` is empty, return `null` — no waiver criteria to show.
  5. Otherwise join `parts` with `l10n.financeFeeWaiverSeparator`, prefixed by
     `l10n.financeFeeWaiverConditions`.
- **Usage:**
  ```dart
  final feeWaiverSummary = _accountFeeWaiverSummary(account, l10n);
  if (feeWaiverSummary == null) {
    return Text('${account.bankOrApp}  •  ${account.currency}');
  }
  ```
  (`lib/features/finance/views/accounts_page.dart:833`, inside
  [`_buildAccountSubtitle`](#buildaccountsubtitle); also called from
  `_AccountTransactionsPageState.build` at line 1287 to show the same summary on the per-account
  transactions page's balance card.)
- **Notes:** Per [Finance](../../../../features/finance.md#model), `feeWaiverMinimumBalance` and
  `feeWaiverMonthlyDeposit` are **alternative** criteria (meeting either waives the fee) — this
  function only *lists* whichever are configured; it does not evaluate either condition against the
  account's actual current balance or deposit history (nothing in this file does).

### `List<String> _normalizedOrder(AccountType type)` <a id="normalizedorder"></a>
- **Kind:** method of `_AccountsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 187-203)
- **Purpose:** Produce a de-duplicated ordering of ids for one account type, starting from whatever
  ids in `_customOrders[key]` are still valid, then appending any account of that type not already
  covered.
- **Inputs:** `type` — the `AccountType` whose custom order to rebuild.
- **Returns:** `List<String>` — account ids, covering every current account of `type` exactly once.
- **Side effects:** None (reads `_accounts`/`_customOrders`; does not mutate them).
- **Algorithm:**
  1. Build `allIds`/`allIdSet` from `_accounts` filtered to `type`.
  2. Walk the saved order `_customOrders[key] ?? []`, keeping ids that are both in `allIdSet` and
     not already `seen` (dedup).
  3. Append every id from `allIds` not yet `seen`, in the accounts list's own order.
- **Usage:**
  ```dart
  _customOrders[key] = _normalizedOrder(type);
  ```
  (`lib/features/finance/views/accounts_page.dart:266`, inside [`_setSortMode`](#setsortmode) when
  switching to custom mode; the same call shape recurs in
  [`_appendAccountToCustomOrderIfNeeded`](#appendaccounttocustomorderifneeded) and inside
  [`_sortEntries`](#sortentries)'s custom-mode branch.)
- **Notes:** This is the per-type analog of
  [`normalizedAccountPickerOrder`](../services/account_picker_util.md#normalizedaccountpickerorder)
  in `account_picker_util.dart` — same dedup-then-append shape, but scoped to one `AccountType` and
  reading from this page's own `_customOrders` map instead of `AccountPickerSettings.customOrder`.

### `List<MapEntry<int, Account>> _sortEntries(AccountType type, List<MapEntry<int, Account>> entries)` <a id="sortentries"></a>
- **Kind:** method of `_AccountsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 210-244)
- **Purpose:** Sort one account type's `(originalIndex, Account)` entries according to that type's
  current sort mode.
- **Inputs:** `type`; `entries` — index/account pairs for that type, in original list order.
- **Returns:** `List<MapEntry<int, Account>>` — a new sorted list.
- **Side effects:** None.
- **Algorithm:** Switches on `_sortMode(type)`:
  1. `name`: sort by `_compareText(a.value.name, b.value.name)`, tie-broken by `bankOrApp`.
  2. `bank`: sort by `_compareText(a.value.bankOrApp, b.value.bankOrApp)`, tie-broken by `name`.
  3. `custom` (and default/fallback): build `order` via [`_normalizedOrder`](#normalizedorder), sort
     by each entry's position in `order` (an id missing from `order` sorts after all known ones, via
     `order.length` as its fallback index), tie-broken by the entry's original index (`a.key`).
- **Usage:**
  ```dart
  final sortedGrouped = {
    for (final entry in grouped.entries)
      entry.key: _sortEntries(entry.key, entry.value),
  };
  ```
  (`lib/features/finance/views/accounts_page.dart:517-520`, in `build`, grouping+sorting every
  account type before rendering.)
- **Notes:** Mirrors
  [`sortAccountsForPicker`](../services/account_picker_util.md#sortaccountsforpicker)'s comparator
  shape, but this page's version has a third `bank` mode that the transaction account picker does
  not support, and operates on `(index, Account)` pairs rather than bare `Account`s so the original
  list position survives as the final tiebreaker.

### `void _setSortMode(AccountType type, String mode)` <a id="setsortmode"></a>
- **Kind:** method of `_AccountsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 251-272)
- **Purpose:** Switch one account type's sort mode, seeding a sensible custom order the first time
  custom mode is entered so accounts don't jump around.
- **Inputs:** `type`; `mode` — one of `_sortName`/`_sortBank`/`_sortCustom`.
- **Returns:** None.
- **Side effects:** Updates `_sortModes`/`_customOrders`/`_reordering` inside `setState`; calls
  `_notifySort`.
- **Algorithm:**
  1. If switching *to* custom mode and this type has no saved custom order yet, seed one: collect
     this type's `(index, Account)` entries and sort them under the *outgoing* mode via
     [`_sortEntries`](#sortentries), then store their ids as the new custom order — so the first
     custom-order view starts from whatever order was already on screen.
  2. Store `mode` in `_sortModes[key]`.
  3. If the new mode is custom, refresh `_customOrders[key]` via
     [`_normalizedOrder`](#normalizedorder); otherwise clear the `_reordering` flag for this type
     (leaving reorder mode if it was active).
  4. Notify sort changed.
- **Usage:**
  ```dart
  PopupMenuButton<String>(
    ...
    onSelected: (mode) => _setSortMode(type, mode),
    ...
  )
  ```
  (`lib/features/finance/views/accounts_page.dart:693`, wired to `_buildSectionHeader`'s sort menu.)
- **Notes:** The seeding step only runs the *first* time custom mode is entered for a type (guarded
  by `!_customOrders.containsKey(key)`) — switching away and back to custom later just reuses
  whatever custom order was last saved.

### `void _appendAccountToCustomOrderIfNeeded(Account account)` <a id="appendaccounttocustomorderifneeded"></a>
- **Kind:** method of `_AccountsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 279-282)
- **Purpose:** Keep a type's custom order in sync when a new account of that type is added.
- **Inputs:** `account` — the newly added (or newly retyped) account.
- **Returns:** None.
- **Side effects:** May update `_customOrders`.
- **Algorithm:** No-op unless `account.type`'s current sort mode is custom; if it is, recompute
  `_customOrders[_typeKey(account.type)]` via [`_normalizedOrder`](#normalizedorder), which appends
  `account.id` at the end (it isn't in the saved order yet).
- **Usage:**
  ```dart
  _accounts.add(account);
  ...
  _appendAccountToCustomOrderIfNeeded(account);
  ```
  (`lib/features/finance/views/accounts_page.dart:369-372`, in [`_addAccount`](#addaccount); also
  called from [`_editAccount`](#editaccount) after an account's type changes.)
- **Notes:** Silently does nothing when the type isn't in custom mode — the account still displays
  correctly under name/bank sort without a custom-order entry.

### `void _removeAccountFromCustomOrders(String accountId)` <a id="removeaccountfromcustomorders"></a>
- **Kind:** method of `_AccountsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 289-293)
- **Purpose:** Remove one account id from every type's custom-order list.
- **Inputs:** `accountId`.
- **Returns:** None.
- **Side effects:** Mutates every list in `_customOrders`.
- **Algorithm:** Loop `_customOrders.entries` and call `.remove(accountId)` on each value list —
  harmless no-op on the type lists that never contained it.
- **Usage:**
  ```dart
  setState(() => _accounts.removeAt(index));
  _removeAccountFromCustomOrders(accountId);
  ```
  (`lib/features/finance/views/accounts_page.dart:461-462`, in
  [`_deleteAccount`](#deleteaccount); also called from [`_editAccount`](#editaccount) when an
  account's type changes, to drop its id from the *old* type's order before re-appending it under
  the new type.)
- **Notes:** Iterates all types unconditionally rather than looking up which single type list
  contains the id — simple, at the cost of a few wasted no-op `remove` calls on the other types.

### `void _reorderAccounts(AccountType type, List<MapEntry<int, Account>> entries, int oldIndex, int newIndex)` <a id="reorderaccounts"></a>
- **Kind:** method of `_AccountsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 322-345)
- **Purpose:** Apply a drag-and-drop reorder within one account type's custom order.
- **Inputs:** `type`; `entries` — the type's currently displayed entries; `oldIndex`/`newIndex` —
  drag source/destination.
- **Returns:** None.
- **Side effects:** Updates `_customOrders`/`_sortModes` inside `setState`; calls `_notifySort`.
- **Algorithm:**
  1. If `newIndex > oldIndex`, decrement it by one (standard `ReorderableListView.onReorder`
     index-shift convention).
  2. Validate both indices are within `ids.length`; return silently if not.
  3. Remove the id at `oldIndex` and re-insert it at `newIndex`.
  4. Store the result as this type's custom order and force `_sortModes[key]` to custom (a reorder
     always implies custom mode).
  5. Notify sort changed.
- **Usage:**
  ```dart
  onReorderItem: (oldIndex, newIndex) {
    final oldStyleNewIndex = newIndex > oldIndex ? newIndex + 1 : newIndex;
    _reorderAccounts(type, entries, oldIndex, oldStyleNewIndex);
  },
  ```
  (`lib/features/finance/views/accounts_page.dart:759-761`, in
  [`_buildReorderList`](#buildreorderlist).)
- **Notes:** Expects the caller to pass a `newIndex` in the *pre-`onReorder`-decrement* convention
  (see [`_buildReorderList`](#buildreorderlist)'s notes) — this method performs its own decrement
  internally, so passing an already-decremented index would double-adjust and land one slot off.

### `Future<void> _addAccount()` <a id="addaccount"></a>
- **Kind:** method of `_AccountsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 352-378)
- **Purpose:** Show the add-account dialog and, on confirmation, insert the new account together
  with whatever adjustment transaction its entered starting balance requires.
- **Inputs:** None (reads `context`).
- **Returns:** `Future<void>`.
- **Side effects:** Shows `_AccountDialog`; on confirmation, updates `_accounts`/`_transactions`,
  the type's custom order, and picker settings, then notifies every relevant parent callback.
- **Algorithm:**
  1. Show `_AccountDialog()` (blank) and await the submitted `Account?`.
  2. If confirmed: stamp the account with the forced-balance sentinel via
     [`accountWithForcedBalanceSentinel`](../services/balance_util.md#accountwithforcedbalancesentinel)
     (new-version accounts never keep a raw forced balance).
  3. Build an adjustment transaction via
     [`_balanceAdjustmentTransaction`](#balanceadjustmenttransaction), with `targetBalance` = the
     dialog's raw `forcedBalance` and `currentBalance` = `0` (a brand-new account starts at zero).
  4. Insert the account (and the adjustment transaction at index 0, if one was produced) inside
     `setState`.
  5. Append the account into its type's custom order if needed
     ([`_appendAccountToCustomOrderIfNeeded`](#appendaccounttocustomorderifneeded)), renormalize and
     notify picker settings, notify transactions (only if one was added), notify accounts, notify
     sort.
- **Usage:**
  ```dart
  floatingActionButton: FloatingActionButton(
    onPressed: _addAccount,
    child: const Icon(Icons.add),
  ),
  ```
  (`lib/features/finance/views/accounts_page.dart:640-643`, the accounts page's FAB.)
- **Notes:** This is the concrete UI entry point for
  [Finance's forced-balance migration](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions):
  the account is always saved with the sentinel already applied, and any starting balance the user
  typed becomes a transaction, never a stored raw balance.

### `Future<void> _editAccount(int index)` <a id="editaccount"></a>
- **Kind:** method of `_AccountsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 385-426)
- **Purpose:** Show the edit-account dialog pre-filled with the account's current computed balance,
  then apply the edited fields and any adjustment transaction the user's balance change requires.
- **Inputs:** `index` — position of the account being edited in `_accounts`.
- **Returns:** `Future<void>`.
- **Side effects:** Shows `_AccountDialog`; on confirmation, updates `_accounts`/`_transactions` and
  (on a type change) the custom-order maps, then notifies accounts/sort/transactions.
- **Algorithm:**
  1. Compute the account's live balance via
     [`accountBalance`](../services/balance_util.md#accountbalance) and show `_AccountDialog` with
     `account: oldAccount, currentBalance: <that balance>`.
  2. If confirmed: stamp the sentinel via `accountWithForcedBalanceSentinel`, recompute
     `currentBalance` again from the *already-stamped* account (unchanged in practice, since
     stamping doesn't touch transactions), and build an adjustment transaction via
     [`_balanceAdjustmentTransaction`](#balanceadjustmenttransaction) for the delta between the
     dialog's requested `forcedBalance` and that current balance.
  3. Insert any adjustment transaction at index 0; replace the account at `index`.
  4. If the account's `type` changed, remove its id from the old type's custom order and append it
     to the new type's (via
     [`_removeAccountFromCustomOrders`](#removeaccountfromcustomorders) +
     [`_appendAccountToCustomOrderIfNeeded`](#appendaccounttocustomorderifneeded)).
  5. Notify transactions (if any were added), accounts, sort.
- **Usage:**
  ```dart
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.startToEnd) {
      _editAccount(entry.key);
      return false;
    }
    return confirmDelete(context, AppLocalizations.of(context)!.financeThisAccount);
  },
  ```
  (`lib/features/finance/views/accounts_page.dart:585-594`, the account list tile's
  swipe-to-edit/delete `Dismissible`.)
- **Notes:** Passing the freshly-computed `currentBalance` into `_AccountDialog` is what lets
  [`_AccountDialogState.initState`](#initstate) tell "user is looking at today's real balance" apart
  from "account still carries an un-migrated legacy forced balance".

### `Transaction? _balanceAdjustmentTransaction({required Account account, required double? targetBalance, required double currentBalance, required DateTime? date, required String note})` <a id="balanceadjustmenttransaction"></a>
- **Kind:** method of `_AccountsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 433-452)
- **Purpose:** Compute the single income/expense transaction that would move an account's balance
  from `currentBalance` to a manually-entered `targetBalance` — the core mechanism behind
  [Finance's forced-balance migration](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions).
- **Inputs:** `account`; `targetBalance` — the user-entered balance, or `null` if none was entered;
  `currentBalance` — the balance to adjust from; `date` — effective date, defaulting to now; `note`.
- **Returns:** `Transaction?` — `null` if no adjustment is needed or requested.
- **Side effects:** None.
- **Algorithm:**
  1. If `targetBalance` is `null`, return `null` (no balance override requested).
  2. Compute `delta = targetBalance - currentBalance`.
  3. If `delta.abs() <= 0.000001`, treat the difference as floating-point noise and return `null`.
  4. Otherwise return a new `Transaction`: `type` income if `delta > 0` else expense, `amount:
     delta.abs()`, `currency: account.currency`, `rateSnapshotId:
     widget.rateData.currentSnapshotId`, `accountId: account.id`, `note`, `date: date ??
     DateTime.now()`.
- **Usage:**
  ```dart
  final adjTx = _balanceAdjustmentTransaction(
    account: account,
    targetBalance: submittedAccount.forcedBalance,
    currentBalance: 0,
    date: submittedAccount.forcedBalanceDate,
    note: l10n.financeBalanceAdjustment,
  );
  ```
  (`lib/features/finance/views/accounts_page.dart:361-367`, in [`_addAccount`](#addaccount); called
  again with a nonzero `currentBalance` from [`_editAccount`](#editaccount).)
- **Notes:** The `0.000001` epsilon is the same tolerance used by
  [`migrateForcedBalances`](../services/balance_util.md#migrateforcedbalances)'s
  one-time-migration counterpart in `balance_util.dart` — both treat sub-cent deltas as "no real
  change" rather than emitting a near-zero adjustment transaction.

### `void _deleteAccount(int index)` <a id="deleteaccount"></a>
- **Kind:** method of `_AccountsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 459-466)
- **Purpose:** Remove an account and keep every derived piece of state (custom orders, transaction
  account picker settings) consistent with its removal.
- **Inputs:** `index` — position of the account in `_accounts`.
- **Returns:** None.
- **Side effects:** Removes the account from `_accounts` inside `setState`; removes its id from
  every type's custom order; renormalizes and notifies picker settings; notifies accounts/sort.
- **Algorithm:**
  1. Capture the account's id before removing it.
  2. Remove it from `_accounts` inside `setState`.
  3. Remove its id from every type's custom order
     ([`_removeAccountFromCustomOrders`](#removeaccountfromcustomorders)).
  4. Renormalize and notify picker settings (drops the id from `AccountPickerSettings.customOrder`
     / `moreAccountIds` too, via `_normalizeAndNotifyAccountPickerSettings`).
  5. Notify accounts, notify sort.
- **Usage:**
  ```dart
  onDismissed: (_) => _deleteAccount(entry.key),
  ```
  (`lib/features/finance/views/accounts_page.dart:595`, the account tile's swipe-to-delete
  `Dismissible`.)
- **Notes:** Deletion is not itself gated by a confirmation dialog here — the confirmation happens
  one level up, in the `Dismissible.confirmDismiss` callback that decides whether `onDismissed` (and
  therefore this method) runs at all.

### `Future<void> _openAccountPickerSettings()` <a id="openaccountpickersettings"></a>
- **Kind:** method of `_AccountsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 483-501)
- **Purpose:** Open the "More settings" sub-page for the transaction account picker and apply
  whatever settings it returns.
- **Inputs:** None (reads `context`, `_accounts`, `_accountPickerSettings`).
- **Returns:** `Future<void>`.
- **Side effects:** Pushes `_AccountPickerSettingsPage`; on a non-null result, updates
  `_accountPickerSettings` inside `setState` and notifies the parent.
- **Algorithm:**
  1. Push `_AccountPickerSettingsPage(accounts: _accounts, initialSettings:
     _accountPickerSettings)` and await its popped `AccountPickerSettings?` result.
  2. If `null` (user backed out without saving), do nothing.
  3. Otherwise normalize the result against the current `_accounts` via
     [`normalizedAccountPickerSettings`](../services/account_picker_util.md#normalizedaccountpickersettings)
     and store it inside `setState`.
  4. Notify the parent via `_notifyAccountPickerSettings`.
- **Usage:**
  ```dart
  IconButton(
    icon: const Icon(Icons.tune),
    tooltip: AppLocalizations.of(context)!.financeAccountPickerSettings,
    onPressed: _openAccountPickerSettings,
  ),
  ```
  (`lib/features/finance/views/accounts_page.dart:527-531`, the accounts page app bar's settings
  icon.)
- **Notes:** Normalizing again here (in addition to `_AccountPickerSettingsPage._save` already
  normalizing before popping) is defensive against `_accounts` having changed between when the
  settings page was pushed and when it returned — unlikely on this synchronous flow, but cheap
  insurance.

### `Widget _buildReorderList(AccountType type, List<MapEntry<int, Account>> entries)` <a id="buildreorderlist"></a>
- **Kind:** method of `_AccountsPageState` (widget helper)
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 749-785)
- **Purpose:** Render the drag-to-reorder list shown for one account type while that type's reorder
  toggle is active and its sort mode is custom.
- **Inputs:** `type`; `entries` — the type's currently sorted entries.
- **Returns:** `Widget` — a `ReorderableListView.builder`.
- **Side effects:** None directly (the `onReorderItem` callback it wires up calls
  [`_reorderAccounts`](#reorderaccounts), which does have side effects).
- **Algorithm:**
  1. Build a `ReorderableListView.builder` with `buildDefaultDragHandles: false` (drag handles are
     rendered explicitly per tile) and a `Material`-elevated `proxyDecorator` for the dragged item.
  2. Its `onReorderItem` callback receives `(oldIndex, newIndex)` and converts `newIndex` to the
     "old-style" convention `_reorderAccounts` expects: `newIndex > oldIndex ? newIndex + 1 :
     newIndex`.
  3. Each tile shows a drag handle, the account name, [`_buildAccountSubtitle`](#buildaccountsubtitle),
     and its live balance via [`accountBalance`](../services/balance_util.md#accountbalance).
- **Usage:**
  ```dart
  if (_reordering[_typeKey(type)] == true && _sortMode(type) == _sortCustom)
    _buildReorderList(type, sortedGrouped[type]!)
  ```
  (`lib/features/finance/views/accounts_page.dart:559-561`, in `build`, swapped in for the normal
  dismissible tile list while reorder mode is on.)
- **Notes:** The index conversion in step 2 exists because [`_reorderAccounts`](#reorderaccounts)
  itself performs the standard `ReorderableListView.onReorder` decrement
  (`if (newIndex > oldIndex) newIndex--`) — but `onReorderItem`'s index is *already* in the
  post-decrement form, so this callback re-adds one before calling it, and the two adjustments
  cancel out to the intended final position. Getting this wrong (e.g. calling `_reorderAccounts`
  directly with `onReorderItem`'s raw `newIndex`) would drop items one slot short whenever dragging
  downward.

### `Widget _buildAccountSubtitle(Account account, ThemeData theme)` <a id="buildaccountsubtitle"></a>
- **Kind:** method of `_AccountsPageState` (widget helper)
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 831-851)
- **Purpose:** Render an account list tile's subtitle: the bank/currency line, plus a second dimmer
  line with the fee-waiver summary when the account has any waiver criteria.
- **Inputs:** `account`; `theme`.
- **Returns:** `Widget`.
- **Side effects:** None (pure widget construction).
- **Algorithm:**
  1. Compute [`_accountFeeWaiverSummary`](#accountfeewaiversummary) for `account`.
  2. If it's `null`, return a single `Text('${account.bankOrApp}  •  ${account.currency}')`.
  3. Otherwise return a `Column` with that same line followed by the fee-waiver summary in
     `bodySmall`/`onSurfaceVariant` styling.
- **Usage:**
  ```dart
  subtitle: _buildAccountSubtitle(entry.value, theme),
  ```
  (`lib/features/finance/views/accounts_page.dart:599`, the account list tile's `ListTile.subtitle`;
  also used at line 775 inside [`_buildReorderList`](#buildreorderlist).)
- **Notes:** Deliberately keeps the fee-waiver summary out of the tile's title and trailing-balance
  columns (per its doc comment) so it doesn't compete visually with the account name or balance.

### `Widget _buildAccountAvatar(Account account, ThemeData theme)` <a id="buildaccountavatar"></a>
- **Kind:** method of `_AccountsPageState` (widget helper)
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 858-885)
- **Purpose:** Render an account's avatar through an image → emoji → type-icon fallback chain.
- **Inputs:** `account`; `theme`.
- **Returns:** `Widget` — a `CircleAvatar`, possibly wrapped in a `FutureBuilder`.
- **Side effects:** None directly; resolves `account.imagePath` asynchronously via
  [`ImageService.resolve`](../../../shared/services/image_service.md) when present.
- **Algorithm:**
  1. Resolve `color` via `_accountTypeColor(account.type)`.
  2. If `account.imagePath != null`, wrap a `FutureBuilder<File>` around
     `ImageService.resolve(account.imagePath!)`: once the file resolves *and* exists on disk, show
     it as the `CircleAvatar`'s `backgroundImage`; otherwise fall through to the emoji/icon branch
     below.
  3. If no image (or the image branch fell through), show `account.emoji` as text if set, otherwise
     `Icon(_accountTypeIcon(account.type), color: color)`.
- **Usage:**
  ```dart
  leading: _buildAccountAvatar(entry.value, theme),
  ```
  (`lib/features/finance/views/accounts_page.dart:597`, the account list tile's `ListTile.leading`.)
- **Notes:** The `snap.data!.existsSync()` check guards against a stale `imagePath` pointing at a
  file that's since been deleted from app storage — in that case the avatar silently falls back to
  emoji/icon rather than showing a broken image or throwing.

### `List<Account> get _orderedAccounts` <a id="orderedaccounts"></a>
- **Kind:** getter of `_AccountPickerSettingsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 942-951)
- **Purpose:** Return accounts in the custom-order editor's current order, for the "More settings"
  page's drag-to-reorder list.
- **Inputs:** None (reads `widget.accounts`, `_customOrder`).
- **Returns:** `List<Account>`.
- **Side effects:** None.
- **Algorithm:**
  1. Build an id → `Account` lookup (`byId`) from `widget.accounts`.
  2. Iterate
     [`normalizedAccountPickerOrder(widget.accounts, _customOrder)`](../services/account_picker_util.md#normalizedaccountpickerorder)
     and collect `byId[id]` for each id, skipping any id with no live match (`byId[id] == null`).
- **Usage:**
  ```dart
  itemCount: _orderedAccounts.length,
  ...
  itemBuilder: (context, index) {
    final account = _orderedAccounts[index];
    ...
  ```
  (`lib/features/finance/views/accounts_page.dart:1089-1097`, driving the custom-order
  `ReorderableListView.builder` in `build`; also read by
  [`_reorderCustomOrder`](#reordercustomorder).)
- **Notes:** The `byId[id] != null` filter is what makes this getter resilient to
  `normalizedAccountPickerOrder` ever returning an id that no longer has a matching account (should
  not normally happen, since that function already filters against the current `accounts` list, but
  this getter doesn't assume it).

### `void _reorderCustomOrder(int oldIndex, int newIndex)` <a id="reordercustomorder"></a>
- **Kind:** method of `_AccountPickerSettingsPageState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 1007-1016)
- **Purpose:** Apply a drag-and-drop reorder within the "More settings" custom-order editor.
- **Inputs:** `oldIndex`/`newIndex` — drag source/destination.
- **Returns:** None.
- **Side effects:** Updates `_customOrder` inside `setState`.
- **Algorithm:**
  1. If `newIndex > oldIndex`, decrement it by one (`ReorderableListView.onReorder` convention).
  2. Read `_orderedAccounts` and validate both indices against its length; return silently if out of
     range.
  3. Move the account id at `oldIndex` to `newIndex` and store the resulting id list as
     `_customOrder`.
- **Usage:**
  ```dart
  onReorderItem: (oldIndex, newIndex) {
    final oldStyleNewIndex = newIndex > oldIndex ? newIndex + 1 : newIndex;
    _reorderCustomOrder(oldIndex, oldStyleNewIndex);
  },
  ```
  (`lib/features/finance/views/accounts_page.dart:1090-1094`, in `build`'s custom-order
  `ReorderableListView`.)
- **Notes:** Same index-convention double-adjustment as
  [`_buildReorderList`](#buildreorderlist)/[`_reorderAccounts`](#reorderaccounts) — the caller
  re-adds one to `newIndex` before calling this method, which then decrements it again internally.

### `void initState()` <a id="initstate"></a>
- **Kind:** method of `_AccountDialogState` (lifecycle override)
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 1541-1569)
- **Purpose:** Prefill the add/edit account form, choosing between the freshly-computed live
  balance (when editing via `_editAccount`, which always supplies one) and a legacy, not-yet-migrated
  forced balance (when neither the caller nor the account has anything newer to show).
- **Inputs:** None (reads `widget.account`, `widget.currentBalance`).
- **Returns:** None.
- **Side effects:** Populates every `TextEditingController` and `_type`/`_currency`/`_selectedEmoji`/
  `_imagePath`/`_forcedBalanceDate` from `widget.account` when editing; captures `_initialSignature`.
- **Algorithm:**
  1. If `widget.account` (`a`) is non-null (editing): fill name/bank/card controllers; fill the two
     fee-waiver controllers (formatted `toStringAsFixed(2)`) only if the corresponding field is
     non-null; copy `type`/`currency`/`emoji`/`imagePath`.
  2. Balance field, in priority order:
     - If `widget.currentBalance != null` (always true when opened from
       [`_editAccount`](#editaccount)): show that computed balance and set
       `_forcedBalanceDate = DateTime.now()` — the field starts representing "today's real balance,
       unchanged" rather than a stale override.
     - Else if `a.forcedBalance != null && !`
       [`hasForcedBalanceSentinel(a)`](../services/balance_util.md#hasforcedbalancesentinel`) (a
       legacy, not-yet-migrated forced balance): show that raw value and
       `a.forcedBalanceDate ?? DateTime.now()`.
     - Otherwise leave the balance field blank (new account, or an already-sentinel-stamped account
       with nothing to show).
  3. Capture `_initialSignature = _signature()` for unsaved-changes detection.
- **Usage:** Invoked automatically by the Flutter framework when `_AccountDialogState` is inserted
  into the tree — not called directly from other code in this file.
- **Notes:** This is the one place in the file where "new-version balance" (a plain computed number,
  no stored override) and "legacy forced balance" (an un-migrated raw value with its own date) are
  told apart at the UI layer; see
  [Finance — forced-balance migration](../../../../features/finance.md#forced-balance-migration-to-adjustment-transactions)
  for why both can coexist across app versions.

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **Kind:** method of `_AccountDialogState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (line 1858)
- **Purpose:** Report whether the account form differs from its state at open time.
- **Inputs:** None.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `_signature() != _initialSignature`.
- **Usage:**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
  (`lib/features/finance/views/accounts_page.dart:1598-1600`, wiring the dialog into
  [`UnsavedChangesGuard`](../../../shared/widgets/unsaved_changes_guard.md).)
- **Notes:** None.

### `String _signature()` <a id="signature"></a>
- **Kind:** method of `_AccountDialogState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 1865-1877)
- **Purpose:** Build a comparable string snapshot of every field the account form can edit, so
  [`_hasUnsavedChanges`](#hasunsavedchanges) can detect any change, including to the optional
  fee-waiver fields.
- **Inputs:** None (reads every controller/field).
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** Delegates to shared
  [`formSignature`](../../../shared/widgets/unsaved_changes_guard.md#formsignature) over an
  ordered list: trimmed name/bank/card/fee-waiver-minimum/fee-waiver-deposit/balance text, `_type.name`,
  `_currency`, `_selectedEmoji`, `_imagePath`, `_forcedBalanceDate`.
- **Usage:**
  ```dart
  _initialSignature = _signature();
  ```
  (`lib/features/finance/views/accounts_page.dart:1568`, in [`initState`](#initstate); re-invoked
  from [`_hasUnsavedChanges`](#hasunsavedchanges) on every comparison.)
- **Notes:** Including the fee-waiver controllers here is what makes editing only a fee-waiver
  amount (with every other field unchanged) correctly trip the unsaved-changes guard.

### `Future<void> _pickBankPreset()` <a id="pickbankpreset"></a>
- **Kind:** method of `_AccountDialogState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 1977-1991)
- **Purpose:** Let the user choose a bank/app preset, apply its name and default currency, and kick
  off an automatic logo download.
- **Inputs:** None (reads `context`).
- **Returns:** `Future<void>`.
- **Side effects:** Shows the bank preset picker; updates `_bankController`, `_selectedBank`,
  possibly `_currency`; triggers [`_fetchBankIcon`](#fetchbankicon).
- **Algorithm:**
  1. Await
     [`showBankPresetPicker(context)`](../widgets/bank_preset_picker.md#showbankpresetpicker).
  2. If the result is `null` or the widget is no longer mounted, return.
  3. Otherwise `setState`: set `_bankController.text = bank.localTitle`, `_selectedBank = bank`, and
     if `bank.defaultCurrency` is non-null, switch `_currency` to it.
  4. Call `_fetchBankIcon()` (not awaited) to auto-download the bank's logo; if that download fails,
     the "Fetch Icon" button simply remains visible for a manual retry.
- **Usage:**
  ```dart
  OutlinedButton.icon(
    icon: const Icon(Icons.account_balance, size: 16),
    label: Text(l10n.financeBankPresets),
    onPressed: _pickBankPreset,
  ),
  ```
  (`lib/features/finance/views/accounts_page.dart:1935-1939`, in `_buildImagePreview`.)
- **Notes:** The logo fetch is intentionally fire-and-forget from here — the dialog remains usable
  (and submittable) while the download is in flight; `_downloadingLogo` drives a progress indicator
  elsewhere in `build`.

### `Future<void> _fetchBankIcon()` <a id="fetchbankicon"></a>
- **Kind:** method of `_AccountDialogState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 1998-2017)
- **Purpose:** Download the selected bank's logo, trying each of its candidate URLs in priority order
  until one succeeds.
- **Inputs:** None (reads `_selectedBank`).
- **Returns:** `Future<void>`.
- **Side effects:** Sets `_downloadingLogo` true then false; on success, sets `_imagePath` and clears
  `_selectedEmoji`.
- **Algorithm:**
  1. Bail out if there is no `_selectedBank` or its
     [`logoUrls`](../services/bank_preset_service.md#logourls) list is empty.
  2. `setState(() => _downloadingLogo = true)`.
  3. Iterate `bank.logoUrls` in order, calling
     [`ImageService.downloadAndSave(url)`](../../../shared/services/image_service.md#downloadandsave)
     for each and stopping at the first non-null path.
  4. If still `mounted`, `setState`: clear `_downloadingLogo`, and if a `path` was obtained, set
     `_imagePath = path` and `_selectedEmoji = null`.
- **Usage:**
  ```dart
  if (bank == null || bank.logoUrls.isEmpty) return;
  ...
  for (final url in bank.logoUrls) {
    path = await ImageService.downloadAndSave(url);
    if (path != null) break;
  }
  ```
  (`lib/features/finance/views/accounts_page.dart:2000-2007`; also called from
  [`_pickBankPreset`](#pickbankpreset) right after a bank is chosen, and from a manual "Fetch Icon"
  button in `_buildImagePreview`.)
- **Notes:** This is the concrete implementation of the multi-source logo fallback chain described in
  [Finance — BankPresetService](../../../../features/finance.md#bankpresetservice) and documented in
  detail on [`BankPreset.logoUrls`](../services/bank_preset_service.md#logourls) (Clearbit, logo.dev,
  Brandfetch, icon.horse, Favicone, two Google favicon endpoints, DuckDuckGo) — if every source
  fails, `_imagePath` is simply never set and the manual "Fetch Icon" button stays available.

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **Kind:** method of `_AccountDialogState`
- **Source:** `lib/features/finance/views/accounts_page.dart` (lines 2034-2069)
- **Purpose:** Validate the account form, parse its optional numeric fields, build the resulting
  `Account`, and pop the dialog with it.
- **Inputs:** `guard` — the `UnsavedChangesController` supplied by `UnsavedChangesGuard`'s builder.
- **Returns:** None.
- **Side effects:** Pops the route (via `guard.pop`) with the built `Account`, or does nothing if
  required fields are blank.
- **Algorithm:**
  1. Require non-empty trimmed `name` and `bank`; if either is blank, return with no error message
     and no pop (silent validation failure).
  2. Parse the optional forced-balance text to `double?` (`forcedBalance`).
  3. Parse the two optional fee-waiver amounts via
     [`_parseOptionalMoney`](#parseoptionalmoney).
  4. Construct a new `Account` (id from `widget.account?.id`, so editing keeps the same id) with all
     form fields; `cardNumber` becomes `null` when blank; `forcedBalanceDate` is set only when
     `forcedBalance != null` (falling back to `DateTime.now()` if the user never picked a date).
  5. `guard.pop(account)` — pops through the unsaved-changes guard's own pop path rather than calling
     `Navigator.pop` directly, so the guard's dirty-state bookkeeping stays consistent.
- **Usage:**
  ```dart
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(isEditing ? l10n.commonSave : l10n.commonAdd),
  ),
  ```
  (`lib/features/finance/views/accounts_page.dart:1840-1843`, the dialog's save/add button.)
- **Notes:** Validation here is minimal and silent — there's no inline error text for a blank
  name/bank, the button simply does nothing until both are filled in. `forcedBalance`/
  `forcedBalanceDate` set here are the raw values later stamped over with the sentinel by
  [`_addAccount`](#addaccount)/[`_editAccount`](#editaccount) via `accountWithForcedBalanceSentinel`
  — `_submit` itself never applies the sentinel.

## Related pages

- [Finance](../../../../features/finance.md) — `Account`/`Transaction`/`AccountPickerSettings`
  model fields, the forced-balance migration this page's dialog implements, and where this page fits
  among the other Finance views.
- [`balance_util.dart`](../services/balance_util.md) — `accountBalance`, `currencySymbol`,
  `hasForcedBalanceSentinel`, `accountWithForcedBalanceSentinel`, and `migrateForcedBalances` (the
  one-time batch counterpart to this file's per-edit
  [`_balanceAdjustmentTransaction`](#balanceadjustmenttransaction)).
- [`account_picker_util.dart`](../services/account_picker_util.md) — `normalizedAccountPickerOrder`,
  `normalizedAccountPickerSettings`, `sortAccountsForPicker`, used throughout the
  `_AccountPickerSettingsPage` "More settings" sub-page.
- [`bank_preset_service.dart`](../services/bank_preset_service.md) — `BankPreset.logoUrls`, the
  fallback chain [`_fetchBankIcon`](#fetchbankicon) walks.
- [`bank_preset_picker.dart`](../widgets/bank_preset_picker.md) — `showBankPresetPicker`, opened by
  [`_pickBankPreset`](#pickbankpreset).
- [`add_transaction_dialog.dart`](../widgets/add_transaction_dialog.md) — the dialog opened by
  `_AccountTransactionsPageState._handleAdd`/`_handleEdit`, preselecting the focused account via
  `initialAccountId` and consuming the same `AccountPickerSettings` this file's "More settings" page
  edits.
- [`grouped_transaction_list.dart`](../widgets/grouped_transaction_list.md) —
  `buildGroupedTransactionList`, used by `_AccountTransactionsPageState.build`.
- [`image_service.dart`](../../../shared/services/image_service.md) — `resolve`,
  `pickAndSaveImage`, `downloadAndSave`, used for account avatars and bank logos.
- [`unsaved_changes_guard.dart`](../../../shared/widgets/unsaved_changes_guard.md) —
  `UnsavedChangesGuard`, `UnsavedChangesController`, `formSignature`, used by `_AccountDialog`.

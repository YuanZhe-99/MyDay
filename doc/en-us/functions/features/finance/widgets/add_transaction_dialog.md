# lib/features/finance/widgets/add_transaction_dialog.dart

The add/edit dialog for Finance [`Transaction`](../../../../features/finance.md#model) records —
the largest widget file in the Finance feature, combining two largely independent pieces of real
logic: (1) the **account picker**, which renders accounts sorted/grouped per the caller's
`AccountPickerSettings` (see [Finance](../../../../features/finance.md) — "Transaction account
picker sorting/grouping/'More' settings") with a collapsible "More" section, and (2) a private
**calculator keyboard** (`_CalcKeyboard`/`_ExprParser`), opened in place of the system keyboard for
amount entry, that parses a typed arithmetic expression (`+ - × ÷`) into a positive `double`. Like
the other add/edit dialogs it wraps its form in `UnsavedChangesGuard`
(`lib/shared/widgets/unsaved_changes_guard.dart`) using a `_signature()`-based dirty check.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AddTransactionDialog` (constructor) | constructor (`AddTransactionDialog`) | B | Create an add/edit transaction dialog instance. |
| `createState` | method (`AddTransactionDialog`) | B | Create the mutable `_AddTransactionDialogState`. |
| `_isEditing` | getter (`_AddTransactionDialogState`) | B | Return whether this dialog edits an existing transaction. |
| `_isCrossCurrency` | getter (`_AddTransactionDialogState`) | B | Return whether the selected transfer accounts use different currencies. |
| `_currencyItems` | getter (`_AddTransactionDialogState`) | B | Build the currency dropdown items, ensuring the current currency is always included. |
| `initState` | method (`_AddTransactionDialogState`) | B | Pre-fill controllers/fields from the edited transaction or caller-provided initial selections, then capture the initial form signature. |
| `dispose` | method (`_AddTransactionDialogState`) | B | Dispose the amount/to-amount/note text controllers. |
| `_openCalcKeyboard` | method (`_AddTransactionDialogState`) | B | Open the calculator-keyboard bottom sheet and write its result into a controller. |
| [`_setType`](#settype) | method (`_AddTransactionDialogState`) | A | Change the transaction flow type and keep a mismatched category selection from lingering. |
| `build` | method (`_AddTransactionDialogState`) | B | Render the type selector, amount/currency, account picker, cross-currency amount, note, category, date/time, and actions. |
| `_buildAccountLabel` | method (widget helper, `_AddTransactionDialogState`) | B | Render one account's label with its emoji/image and bank/app name. |
| `_sortedAccountsForPicker` | getter (`_AddTransactionDialogState`) | B | Return accounts sorted per the current `AccountPickerSettings`. |
| `_isMoreAccount` | method (`_AddTransactionDialogState`) | B | Return whether an account is configured under the "More" section. |
| [`_firstSelectableAccount`](#firstselectableaccount) | method (`_AddTransactionDialogState`) | A | Pick the default account for a new transaction. |
| [`_accountTypeLabel`](#accounttypelabel) | method (`_AddTransactionDialogState`) | A | Return the localized label for an account type. |
| [`_accountDropdownItems`](#accountdropdownitems) | method (`_AddTransactionDialogState`) | A | Build account dropdown items with optional type headers and a collapsible "More" section. |
| `addHeader` | local function (nested in `_accountDropdownItems`) | B | Add a disabled section-header item to the dropdown item list. |
| [`addAccounts`](#addaccounts) | local function (nested in `_accountDropdownItems`) | A | Add one group of selectable accounts to the dropdown item list, inserting type headers when requested. |
| [`_selectAccount`](#selectaccount) | method (`_AddTransactionDialogState`) | A | Apply an account dropdown selection, including the "More" sentinel and cross-currency implications. |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | method (`_AddTransactionDialogState`) | A | Report whether the form differs from its initial state. |
| [`_signature`](#signature) | method (`_AddTransactionDialogState`) | A | Build a comparable string snapshot of every editable field. |
| [`_submit`](#submit) | method (`_AddTransactionDialogState`) | A | Validate the form, resolve cross-currency amounts, and construct/pop the `Transaction`. |
| `_filteredCategories` | getter (`_AddTransactionDialogState`) | B | Return categories matching the currently selected transaction type. |
| `_buildCategoryPicker` | method (widget helper, `_AddTransactionDialogState`) | B | Render the category dropdown for the current transaction type. |
| `_buildAccountPicker` | method (widget helper, `_AddTransactionDialogState`) | B | Render the from-account (and, for transfers, to-account) dropdown pickers. |
| `_CalcKeyboard` (constructor) | constructor (`_CalcKeyboard`) | B | Create a calculator-keyboard instance. |
| `createState` | method (`_CalcKeyboard`) | B | Create the mutable `_CalcKeyboardState`. |
| `initState` | method (`_CalcKeyboardState`) | B | Seed the expression buffer from `widget.initial`. |
| `_append` | method (`_CalcKeyboardState`) | B | Append a character to the expression buffer. |
| `_backspace` | method (`_CalcKeyboardState`) | B | Remove the last character from the expression buffer. |
| `_clear` | method (`_CalcKeyboardState`) | B | Clear the expression buffer. |
| [`_confirm`](#confirm) | method (`_CalcKeyboardState`) | A | Evaluate the expression buffer and pop with a positive result, if any. |
| `build` | method (`_CalcKeyboardState`) | B | Render the display, live evaluation preview, digit/operator grid, and clear/confirm row. |
| [`_evalExpr`](#evalexpr) | top-level function | A | Normalize operator glyphs and parse an expression string into a `double`, or `null` on failure. |
| `_ExprParser` (constructor) | constructor (`_ExprParser`) | B | Create an expression parser over a source string. |
| [`parse`](#parse) | method (`_ExprParser`) | A | Parse the full source string as one arithmetic expression. |
| [`_parseAddSub`](#parseaddsub) | method (`_ExprParser`) | A | Parse a left-associative chain of `+`/`-` terms. |
| [`_parseMulDiv`](#parsemuldiv) | method (`_ExprParser`) | A | Parse a left-associative chain of `*`/`/` factors, rejecting division by zero. |
| [`_parseNumber`](#parsenumber) | method (`_ExprParser`) | A | Scan and parse one numeric literal (with optional leading unary minus). |

`grep -c 'Purpose:' lib/features/finance/widgets/add_transaction_dialog.dart` reports 39,
matching all thirty-nine real declarations in this file (including the two local functions
`addHeader`/`addAccounts` nested inside `_accountDropdownItems`, each of which carries its own
`Purpose:` block). No misattachment or undocumented declarations found.

## Documentation

### `void _setType(TransactionType type)` <a id="settype"></a>
- **Kind:** method of `_AddTransactionDialogState`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 224-229)
- **Purpose:** Switch the dialog between expense/income/transfer and drop a now-invalid category
  selection.
- **Inputs:** `type` — the newly selected `TransactionType`.
- **Returns:** `None`.
- **Side effects:** Updates `_type` and, conditionally, `_selectedCategory` via `setState`.
- **Algorithm:**
  1. Set `_type` to the new value.
  2. If the currently selected category's `type` no longer equals the new `_type`, clear
     `_selectedCategory` to `null` — categories are type-scoped (expense categories cannot be
     assigned to an income transaction), so a stale selection from the previous type must not
     survive the switch silently.
- **Usage:**
  ```dart
  SegmentedButton<TransactionType>(
    segments: [...],
    selected: {_type},
    onSelectionChanged: (set) => _setType(set.first),
  ),
  ```
  (`build`, same file/class.)
- **Notes:** `_buildCategoryPicker` additionally keys its `DropdownButtonFormField` on
  `ValueKey(_type)`, so the field itself is rebuilt fresh on a type change rather than relying only
  on this clear.

### `Account? _firstSelectableAccount()` <a id="firstselectableaccount"></a>
- **Kind:** method of `_AddTransactionDialogState`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 476-480)
- **Purpose:** Choose the account a brand-new transaction should default to, when the caller did
  not supply an `initialAccountId`.
- **Inputs:** None (reads `_sortedAccountsForPicker` and `widget.accountPickerSettings`).
- **Returns:** `Account?` — `null` only if `widget.accounts` is empty.
- **Side effects:** None.
- **Algorithm:**
  1. Sort accounts via [`_sortedAccountsForPicker`](../../../../features/finance.md).
  2. Take the first account that is **not** in the "More" section
     (`!_isMoreAccount(account)`).
  3. If every account is under "More" (so step 2 finds nothing), fall back to the first sorted
     account overall.
- **Usage:**
  ```dart
  _selectedAccount ??= widget.initialAccountId != null
      ? widget.accounts.where((a) => a.id == widget.initialAccountId).firstOrNull
      : null;
  _selectedAccount ??= _firstSelectableAccount();
  ```
  (`initState`, same file/class.)
- **Notes:** This mirrors the "More" collapsing behavior of `_accountDropdownItems` — an account
  hidden behind "Show more" should also not silently become the default selection when the picker
  first renders.

### `String _accountTypeLabel(AccountType type, AppLocalizations l10n)` <a id="accounttypelabel"></a>
- **Kind:** method of `_AddTransactionDialogState`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 487-494)
- **Purpose:** Map an `AccountType` to its localized section-header label for the grouped account
  dropdown.
- **Inputs:** `type` — the `AccountType` to label; `l10n` — the current `AppLocalizations`.
- **Returns:** `String` — one of `financeAccountTypeFund` / `financeAccountTypeCredit` /
  `financeAccountTypeRecharge` / `financeAccountTypeFinancial`.
- **Side effects:** None.
- **Algorithm:** Exhaustive `switch` over the four `AccountType` values, each mapped 1:1 to its
  matching `AppLocalizations` getter.
- **Usage:**
  ```dart
  addHeader(
    '__finance_account_header_${sectionKey}_${account.type.name}',
    _accountTypeLabel(account.type, l10n),
  );
  ```
  (`addAccounts`, nested inside [`_accountDropdownItems`](#accountdropdownitems).)
- **Notes:** None.

### `List<DropdownMenuItem<String>> _accountDropdownItems(ThemeData theme, AppLocalizations l10n)` <a id="accountdropdownitems"></a>
- **Kind:** method of `_AddTransactionDialogState`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 501-582)
- **Purpose:** Build the item list for an account-picker dropdown, honoring the caller's
  `AccountPickerSettings` for type grouping and the collapsible "More" section.
- **Inputs:** `theme`, `l10n` — used for header styling and localized type/"More" labels.
- **Returns:** `List<DropdownMenuItem<String>>` — selectable account items interleaved with
  disabled header items; a synthetic "Show N more" item when "More" accounts exist and are not yet
  expanded.
- **Side effects:** None on state directly (pure list construction); the resulting items are only
  wired to state changes by the caller's `onChanged`.
- **Algorithm:**
  1. Partition `_sortedAccountsForPicker` into `primary` and `more` lists based on
     `widget.accountPickerSettings.moreAccountIds`.
  2. Always render `primary` via the nested [`addAccounts`](#addaccounts) helper.
  3. If there are any `more` accounts: when `_showMoreAccounts` is already `true` (the user
     previously expanded it), render a `"More"` header followed by `addAccounts(more, 'more')`;
     otherwise append a single synthetic item (`value: _moreAccountsValue`) reading "Show N more"
     instead of the individual accounts.
  4. Return the combined `items` list.
- **Usage:**
  ```dart
  DropdownButtonFormField<String>(
    key: ValueKey('from-account-more-$_showMoreAccounts'),
    initialValue: _selectedAccount?.id,
    isExpanded: true,
    items: _accountDropdownItems(theme, l10n),
    onChanged: (id) => _selectAccount(id, isTarget: false),
  ),
  ```
  (`_buildAccountPicker`, same file/class — called twice, once for the from-account and once,
  when `_type == TransactionType.transfer`, for the to-account.)
- **Notes:** Header items use synthetic non-account `value`s
  (`'__finance_account_header_...'`) and `enabled: false`, so they can never be selected; they
  exist purely to satisfy `DropdownButtonFormField`'s single flat `items` list.

### `void addAccounts(List<Account> accounts, String sectionKey)` (nested in `_accountDropdownItems`) <a id="addaccounts"></a>
- **Kind:** local function, declared inside `_accountDropdownItems`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 545-562)
- **Purpose:** Append one group of accounts (either the primary group or the "More" group) to the
  enclosing `items` list, inserting a type-section header each time the account's `type` changes,
  if the caller's settings request type grouping.
- **Inputs:** `accounts` — the group to append (already sorted); `sectionKey` — `'primary'` or
  `'more'`, used only to namespace header item values so primary and "More" headers for the same
  `AccountType` don't collide.
- **Returns:** `None`.
- **Side effects:** Mutates the enclosing `items` list (a closure variable of
  `_accountDropdownItems`).
- **Algorithm:**
  1. Track `currentType` across the loop, starting `null`.
  2. For each account, if `settings.groupByType` is true and the account's `type` differs from
     `currentType`, update `currentType` and call `addHeader` with a key namespaced by
     `sectionKey` and `type.name`, labeled via [`_accountTypeLabel`](#accounttypelabel).
  3. Append a normal selectable `DropdownMenuItem` for the account (label via
     `_buildAccountLabel`) regardless of whether a header was just added.
- **Usage:**
  ```dart
  addAccounts(primary, 'primary');
  if (more.isNotEmpty) {
    if (_showMoreAccounts) {
      addHeader('__finance_account_header_more', l10n.financeAccountPickerMore);
      addAccounts(more, 'more');
    } else {
      // ...synthetic "Show more" item...
    }
  }
  ```
  (`_accountDropdownItems`, same file/class.)
- **Notes:** Because `accounts` is expected to already be sorted with type grouped consecutively
  (via `sortAccountsForPicker`, `lib/features/finance/services/account_picker_util.dart`), this
  function only needs to detect type *changes* along the single pass — it does not itself group or
  re-sort by type.

### `void _selectAccount(String? id, {required bool isTarget})` <a id="selectaccount"></a>
- **Kind:** method of `_AddTransactionDialogState`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 589-606)
- **Purpose:** Apply the user's choice from an account dropdown — a real account, or the "More"
  sentinel that expands the hidden section instead of selecting anything.
- **Inputs:** `id` — the dropdown's selected value (an account id, `_moreAccountsValue`, or
  `null` for no change); `isTarget` — `true` for the transfer *to*-account dropdown, `false` for
  the *from*-account dropdown.
- **Returns:** `None`.
- **Side effects:** Updates `_showMoreAccounts`, `_selectedAccount`/`_selectedToAccount`, and (for
  the from-account) `_currency`, all via `setState`.
- **Algorithm:**
  1. If `id` is `null`, return immediately (nothing selected).
  2. If `id` equals the `_moreAccountsValue` sentinel, set `_showMoreAccounts = true` and return —
     this expands the "More" section on the *next* rebuild rather than selecting an account.
  3. Otherwise look up the matching `Account` by id; if not found (stale id), return.
  4. If `isTarget`, set `_selectedToAccount`; otherwise set `_selectedAccount` **and** update
     `_currency` to that account's currency (the from-account drives the transaction's currency).
  5. If the newly selected account is itself a "More" account (reachable if it was already visible
     from a prior expansion), also set `_showMoreAccounts = true` so it doesn't disappear back
     behind "Show more" on rebuild.
- **Usage:**
  ```dart
  items: _accountDropdownItems(theme, l10n),
  onChanged: (id) => _selectAccount(id, isTarget: false),
  ```
  (`_buildAccountPicker`, same file/class; called with `isTarget: true` for the transfer
  to-account dropdown.)
- **Notes:** Selecting a from-account always overwrites `_currency`, even when editing an existing
  transaction — there is no guard to preserve a transaction's original currency if the user
  re-picks the same account or a different one with a different currency.

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **Kind:** method of `_AddTransactionDialogState`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (line 613)
- **Purpose:** Tell `UnsavedChangesGuard` whether the form has diverged from its initial state.
- **Inputs:** None.
- **Returns:** `bool` — `true` if the current signature differs from `_initialSignature`.
- **Side effects:** None.
- **Algorithm:** Delegates entirely to comparing [`_signature()`](#signature) against
  `_initialSignature`, captured at the end of `initState`.
- **Usage:**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **Notes:** None.

### `String _signature()` <a id="signature"></a>
- **Kind:** method of `_AddTransactionDialogState`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 620-630)
- **Purpose:** Produce a single string that changes if and only if any editable field's value has
  changed.
- **Inputs:** None.
- **Returns:** `String` — from `formSignature` (`lib/shared/widgets/unsaved_changes_guard.dart`).
- **Side effects:** None.
- **Algorithm:** Collects the trimmed amount/to-amount/note text, `_type.name`, `_date`,
  `_currency`, and the selected category/account/to-account ids into one ordered list and joins
  them via `formSignature`.
- **Usage:**
  ```dart
  _initialSignature = _signature();
  ```
  (`initState`, same file/class.)
- **Notes:** `_showMoreAccounts` is deliberately **not** part of the signature — expanding the
  "More" section is a picker-display concern, not an edit to the transaction itself, so it does
  not mark the form as dirty.

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **Kind:** method of `_AddTransactionDialogState`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 637-669)
- **Purpose:** Validate the form and, if valid, construct the `Transaction` (including
  cross-currency transfer fields) and pop the dialog with it.
- **Inputs:** `guard` — used to pop the route with a result.
- **Returns:** `None`.
- **Side effects:** Pops the dialog route via `guard.pop(tx)` when the amount is valid; otherwise
  leaves the dialog open.
- **Algorithm:**
  1. Parse the amount; if it is not a valid positive number, return without popping — the only
     hard validation rule.
  2. Resolve `accountId`, falling back to the transaction being edited's existing `accountId` if
     none is currently selected (defensive: normally `_selectedAccount` is always set by
     `initState`/`_selectAccount`).
  3. Resolve `toAccountId` — only populated when `_type == TransactionType.transfer`.
  4. If [`_isCrossCurrency`](../../../../features/finance.md) is true, parse the received-amount
     controller into `toAmount` and read `toCurrency` from `_selectedToAccount!.currency`;
     otherwise both stay `null`.
  5. Construct the `Transaction` with `id: widget.transaction?.id` (so editing preserves the
     original id; adding gets a new one), `rateSnapshotId: widget.currentSnapshotId`, and the
     resolved fields above.
  6. Call `guard.pop(tx)`.
- **Usage:**
  ```dart
  final tx = await showDialog<Transaction>(
    context: context,
    builder: (_) => AddTransactionDialog(
      categories: widget.categories,
      accounts: widget.accounts,
      initialAccountId: widget.account.id,
      currentSnapshotId: widget.rateData.currentSnapshotId,
      accountPickerSettings: widget.accountPickerSettings,
    ),
  );
  if (tx != null) {
    setState(() => _transactions.insert(0, tx));
    widget.onAdd(tx);
  }
  ```
  (`lib/features/finance/views/accounts_page.dart`, `_handleAdd`; the same dialog is also opened
  for editing and from `category_detail_page.dart`, `subscription_detail_page.dart`, and
  `finance_page.dart`.)
- **Notes:** Persisting the returned `Transaction` (and any downstream balance/exchange-rate
  effects) is entirely the caller's responsibility — this method only ever produces a `Transaction`
  value and pops.

### `void _confirm()` <a id="confirm"></a>
- **Kind:** method of `_CalcKeyboardState`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 829-839)
- **Purpose:** Evaluate the current expression buffer and, if it produces a valid positive amount,
  pop the calculator-keyboard sheet with that amount as a formatted string.
- **Inputs:** None (reads `_expr`).
- **Returns:** `None`.
- **Side effects:** Pops the enclosing route (`Navigator.pop(context, ...)`) with a
  `String` result when a positive value is found; otherwise does nothing and the sheet stays open.
- **Algorithm:**
  1. Try evaluating `_expr` as an arithmetic expression via [`_evalExpr`](#evalexpr).
  2. If that succeeds and is `> 0`, pop with `result.toStringAsFixed(2)`.
  3. Otherwise, fall back to a plain `double.tryParse(_expr)` (covers the common case where the
     user typed a bare number that for some reason didn't parse as an "expression" — in practice
     `_evalExpr` handles bare numbers too, so this is a defensive second attempt); if that is
     `> 0`, pop with `direct.toStringAsFixed(2)`.
  4. If neither produces a positive value (empty, zero, negative, or malformed expression),
     silently do nothing — the sheet remains open with no feedback.
- **Usage:**
  ```dart
  FilledButton(
    onPressed: _confirm,
    child: const Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
  ),
  ```
  (`build`, same file/class — the keyboard's "=" button.)
- **Notes:** There is no user-visible error message for an invalid or non-positive expression;
  the only feedback is that pressing "=" does nothing. Zero and negative results are treated
  identically to parse failures (both are silently rejected), since a transaction amount must be
  strictly positive.

### `double? _evalExpr(String expr)` <a id="evalexpr"></a>
- **Kind:** top-level function
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 1013-1021)
- **Purpose:** Normalize the calculator keyboard's `×`/`÷` glyphs to `*`/`/` and parse the result
  into a `double`, returning `null` for any empty or malformed input instead of throwing.
- **Inputs:** `expr` — the raw expression buffer typed via the calculator keyboard (digits, `.`,
  `+`, `-`, `×`, `÷`).
- **Returns:** `double?` — the evaluated value, or `null` if `expr` is empty or fails to parse.
- **Side effects:** None.
- **Algorithm:**
  1. Trim `expr` and replace every `×` with `*` and `÷` with `/`.
  2. If the result is empty, return `null` immediately.
  3. Otherwise construct an [`_ExprParser`](#parse) over it and call `.parse()`, returning its
     result.
  4. Catch any exception thrown during parsing (unexpected character, division by zero, etc.) and
     return `null`.
- **Usage:**
  ```dart
  final preview = _evalExpr(_expr);
  final showPreview = preview != null && _expr.isNotEmpty && double.tryParse(_expr) == null;
  ```
  (`_CalcKeyboardState.build`, same file — used to show a live `"= 12.34"` preview only when the
  buffer is a genuine expression, not a bare number already displayed as the primary text.)
- **Notes:** Also called from [`_confirm`](#confirm) as the first evaluation attempt before its
  `double.tryParse` fallback.

### `double parse()` <a id="parse"></a>
- **Kind:** method of `_ExprParser`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 1039-1043)
- **Purpose:** Parse the entire source string as one arithmetic expression, rejecting any
  unconsumed trailing characters.
- **Inputs:** None (operates on `this.src`/`this._pos`).
- **Returns:** `double` — the expression's value.
- **Side effects:** Advances `_pos` to the end of `src` (or throws before doing so).
- **Algorithm:**
  1. Parse an add/sub chain via [`_parseAddSub()`](#parseaddsub).
  2. If `_pos` has not reached `src.length` after that (i.e. there are leftover characters the
     grammar couldn't consume — for example two consecutive operators, or a stray non-numeric
     character), throw a `FormatException('unexpected char')`.
  3. Otherwise return the parsed value.
- **Usage:**
  ```dart
  return _ExprParser(expr).parse();
  ```
  (`_evalExpr`, same file.)
- **Notes:** This is a small hand-written recursive-descent parser with the standard three-level
  precedence chain: `parse` → [`_parseAddSub`](#parseaddsub) → [`_parseMulDiv`](#parsemuldiv) →
  [`_parseNumber`](#parsenumber). There is no parenthesis support — the calculator keyboard's
  button grid (`_CalcKeyboardState.build`) does not offer `(`/`)` keys.

### `double _parseAddSub()` <a id="parseaddsub"></a>
- **Kind:** method of `_ExprParser`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 1050-1058)
- **Purpose:** Parse a left-associative chain of `+`/`-` terms, each of which is itself a
  `*`/`/` chain.
- **Inputs:** None.
- **Returns:** `double` — the accumulated value.
- **Side effects:** Advances `_pos` past every token consumed.
- **Algorithm:**
  1. Parse one term via [`_parseMulDiv()`](#parsemuldiv).
  2. While the next character is `+` or `-`, consume it, parse the next `_parseMulDiv()` term, and
     fold it into the running total (add or subtract accordingly).
  3. Return the accumulated value once no more `+`/`-` remain.
- **Usage:** Called only from [`parse()`](#parse) as the top of the precedence chain.
- **Notes:** Left-associative by construction (each iteration folds immediately into `v` rather
  than building a right-recursive tree).

### `double _parseMulDiv()` <a id="parsemuldiv"></a>
- **Kind:** method of `_ExprParser`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 1065-1074)
- **Purpose:** Parse a left-associative chain of `*`/`/` factors, giving multiplication/division
  higher precedence than addition/subtraction, and reject division by zero.
- **Inputs:** None.
- **Returns:** `double` — the accumulated value.
- **Side effects:** Advances `_pos` past every token consumed.
- **Algorithm:**
  1. Parse one number via [`_parseNumber()`](#parsenumber).
  2. While the next character is `*` or `/`, consume it and parse the next number.
  3. For `/`, if the right-hand operand is exactly `0`, throw
     `FormatException('div by zero')` rather than producing `double.infinity`/`NaN`.
  4. Otherwise fold the operation (multiply or divide) into the running value.
- **Usage:** Called only from [`_parseAddSub()`](#parseaddsub).
- **Notes:** The zero check is an exact `== 0` comparison on the parsed `double`, so a division by
  a value that rounds to zero only at display precision (but is not literally `0`) is **not**
  caught here and would produce a very large (but finite) result instead of throwing.

### `double _parseNumber()` <a id="parsenumber"></a>
- **Kind:** method of `_ExprParser`
- **Source:** `lib/features/finance/widgets/add_transaction_dialog.dart` (lines 1081-1095)
- **Purpose:** Scan one numeric literal (digits and at most one decimal point, with an optional
  leading unary minus only at the very start of the whole expression) and parse it as a `double`.
- **Inputs:** None.
- **Returns:** `double` — the parsed literal.
- **Side effects:** Advances `_pos` past the consumed digits.
- **Algorithm:**
  1. Record `start = _pos`.
  2. If the current character is `-` **and** `start == 0` (i.e. this is the very first character
     of the entire source string), consume it as a unary minus.
  3. Consume characters while they are ASCII digits (`'0'`–`'9'`) or `.`, without validating that
     at most one `.` appears.
  4. If no characters were consumed (`_pos == start`), throw `FormatException('expected
     number')`.
  5. Return `double.parse(src.substring(start, _pos))`.
- **Usage:** Called from both [`_parseMulDiv()`](#parsemuldiv) (for every operand) and indirectly
  underlies the whole parse chain.
- **Notes:** The `start == 0` condition checks the parser's absolute position in the *whole*
  source string, not the start of the current sub-expression — so a unary minus is only
  recognized as the very first character typed (e.g. `"-5+3"`), never after an operator (e.g.
  `"5+-3"` or `"5*-3"` throw `FormatException('expected number')` rather than being interpreted as
  `5 + (-3)`). Pressing the keypad's `-` key as the very first input is possible and does parse
  (e.g. `"-5"` evaluates to `-5.0`), but [`_confirm`](#confirm) only accepts strictly positive
  results, so a leading-minus expression is always silently discarded rather than producing a
  negative transaction amount.

# lib/features/finance/widgets/add_subscription_dialog.dart

The add/edit/restore dialog for Finance [`Subscription`](../../../../features/finance.md#model)
records, wrapped in `UnsavedChangesGuard`
(`lib/shared/widgets/unsaved_changes_guard.dart`) exactly like the transaction and task dialogs.
One widget serves three modes selected by its constructor arguments: plain **add** (no
`subscription`), **edit** (`subscription` set, `restoreAsCopy: false`), and **restore-as-copy**
(`subscription` set as a template, `restoreAsCopy: true`, used to reactivate an expired/cancelled
subscription as a brand-new one starting today). On submit it also decides whether to prompt the
caller to import historical billing transactions, based on
[`Subscription.firstBillingDate`](../../../../features/finance.md#model) and the
month-end-clamping cursor described in
[Subscription Billing](../../../../algorithms/subscription-billing.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AddSubscriptionDialog` (constructor) | constructor (`AddSubscriptionDialog`) | B | Create an add/edit/restore subscription dialog instance. |
| `createState` | method (`AddSubscriptionDialog`) | B | Create the mutable `_AddSubscriptionDialogState`. |
| `_isEditing` | getter (`_AddSubscriptionDialogState`) | B | Return whether this dialog edits the existing subscription in place. |
| `_isRestoringCopy` | getter (`_AddSubscriptionDialogState`) | B | Return whether this dialog creates a new subscription from an old one. |
| `initState` | method (`_AddSubscriptionDialogState`) | B | Pre-fill controllers/fields from `widget.subscription` (or start blank) and capture the initial form signature. |
| `dispose` | method (`_AddSubscriptionDialogState`) | B | Dispose the name/amount/note/trial-days text controllers. |
| `build` | method (`_AddSubscriptionDialogState`) | B | Render the presets row, name/emoji/image picker, amount/currency, account/category pickers, start date, trial days, billing cycle/interval, note, and actions. |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | method (`_AddSubscriptionDialogState`) | A | Report whether the form differs from its initial state. |
| [`_signature`](#signature) | method (`_AddSubscriptionDialogState`) | A | Build a comparable string snapshot of every editable field. |
| [`_submit`](#submit) | method (`_AddSubscriptionDialogState`) | A | Validate the form, construct the `Subscription`, and decide whether to prompt for historical import. |
| [`_firstBillingDayBeforeToday`](#firstbillingdaybeforetoday) | method (`_AddSubscriptionDialogState`) | A | Return whether a subscription's first billing day is strictly before today. |
| `_buildImagePreview` | method (widget helper, `_AddSubscriptionDialogState`) | B | Render the selected custom image (with a remove button) or the image-picker button. |
| `_askImportHistory` | method (`_AddSubscriptionDialogState`) | B | Show a Yes/No dialog asking whether to import historical billing transactions, then pop with the choice. |

`grep -c 'Purpose:' lib/features/finance/widgets/add_subscription_dialog.dart` reports 13,
matching all thirteen real declarations in this file. No misattachment or undocumented
declarations found.

## Documentation

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **Kind:** method of `_AddSubscriptionDialogState`
- **Source:** `lib/features/finance/widgets/add_subscription_dialog.dart` (line 506)
- **Purpose:** Tell `UnsavedChangesGuard` whether the form has diverged from its initial state, so
  it knows whether to prompt for confirmation before the dialog is dismissed.
- **Inputs:** None (reads instance state only).
- **Returns:** `bool` — `true` if the current form signature differs from `_initialSignature`.
- **Side effects:** None.
- **Algorithm:**
  1. Recompute the current signature via [`_signature()`](#signature).
  2. Compare it to `_initialSignature`, captured once at the end of `initState` (right after
     pre-filling from `widget.subscription`, or immediately for a blank new-subscription form).
  3. Return whether they differ.
- **Usage:**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **Notes:** Passed as a tear-off, so it is re-evaluated on every pop attempt rather than cached.

### `String _signature()` <a id="signature"></a>
- **Kind:** method of `_AddSubscriptionDialogState`
- **Source:** `lib/features/finance/widgets/add_subscription_dialog.dart` (lines 513-526)
- **Purpose:** Produce a single string that changes if and only if any editable field's value has
  changed, for use as the dirty-check baseline/comparison.
- **Inputs:** None (reads instance state only).
- **Returns:** `String` — the joined signature from `formSignature`
  (`lib/shared/widgets/unsaved_changes_guard.dart`).
- **Side effects:** None.
- **Algorithm:**
  1. Collect the trimmed name/amount/note/trial-days text, `_startDate`, `_cycleType.name`,
     `_billingInterval`, `_currency`, `_selectedEmoji`, `_imagePath`, and the selected
     category/account ids into one ordered list.
  2. Delegate to `formSignature(Iterable<Object?>)`, which maps each value to a canonical string
     and joins them with a delimiter that cannot appear in any individual field.
- **Usage:**
  ```dart
  _initialSignature = _signature();
  // ...
  bool _hasUnsavedChanges() => _signature() != _initialSignature;
  ```
- **Notes:** None.

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **Kind:** method of `_AddSubscriptionDialogState`
- **Source:** `lib/features/finance/widgets/add_subscription_dialog.dart` (lines 533-571)
- **Purpose:** Validate the form and, if valid, construct the `Subscription` and either pop the
  dialog directly or first ask whether to import historical billing transactions.
- **Inputs:** `guard` — the `UnsavedChangesController` supplied by `UnsavedChangesGuard.builder`,
  used to pop the route with a result.
- **Returns:** `None`.
- **Side effects:** Pops the dialog route (directly, or after `_askImportHistory` resolves) with a
  `({sub: Subscription, importHistory: bool})` record; otherwise leaves the dialog open.
- **Algorithm:**
  1. Parse the amount; if it is not a valid positive number, return without popping.
  2. Trim the name; if empty, return without popping — these are the form's only hard validation
     rules.
  3. Parse trial days (defaulting to `0` on parse failure).
  4. Construct the `Subscription`. Its `id` is `null` when restoring as a copy (so a fresh id is
     generated) or otherwise the existing `widget.subscription?.id`; `isActive`/`cancelledAt`/
     `cancelType` are reset to "freshly active" when restoring as a copy, otherwise carried over
     from the existing subscription.
  5. Compute `shouldAskImport`: only when *adding* (not editing, not restoring) **and**
     [`_firstBillingDayBeforeToday(sub)`](#firstbillingdaybeforetoday) is true — i.e. the new
     subscription's first billing day (start date + trial days) already fell in the past.
  6. If `shouldAskImport`, delegate to `_askImportHistory(sub, guard)` (which pops asynchronously
     once the user answers); otherwise pop immediately with `importHistory: false`.
- **Usage:**
  ```dart
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(
      _isRestoringCopy
          ? l10n.financeRestoreSubscription
          : (_isEditing ? l10n.commonSave : l10n.commonAdd),
    ),
  ),
  ```
  Callers consume the popped record, e.g.:
  ```dart
  final result = await showDialog<({Subscription sub, bool importHistory})>(
    context: context,
    builder: (_) => AddSubscriptionDialog(
      categories: widget.categories,
      accounts: widget.accounts,
    ),
  );
  if (result != null) _insertNewSubscription(result);
  ```
  (`lib/features/finance/views/subscriptions_page.dart`, `_addSubscription`; the same dialog is
  also opened with `subscription: sub` for editing and with `subscription: sub, restoreAsCopy:
  true` for restore-as-copy in `_editSubscription`/`_copyRestoreSubscription` in the same file.)
- **Notes:** All persistence (inserting the subscription, generating catch-up billing
  transactions when `importHistory` is true) happens in the caller, not here — this method only
  ever produces the result record and pops.

### `bool _firstBillingDayBeforeToday(Subscription sub)` <a id="firstbillingdaybeforetoday"></a>
- **Kind:** method of `_AddSubscriptionDialogState`
- **Source:** `lib/features/finance/widgets/add_subscription_dialog.dart` (lines 578-584)
- **Purpose:** Decide whether a candidate subscription's first billing day already lies in the
  past, which gates whether [`_submit`](#submit) offers to import historical billing transactions.
- **Inputs:** `sub` — the `Subscription` draft just constructed by `_submit` (not yet persisted).
- **Returns:** `bool` — `true` if `sub.firstBillingDate`'s calendar day is before today's calendar
  day.
- **Side effects:** None.
- **Algorithm:**
  1. Compute today's date with the time component zeroed out (`DateTime(now.year, now.month,
     now.day)`).
  2. Read `sub.firstBillingDate` (`Subscription.firstBillingDate =>
     startDate.add(Duration(days: trialDays))`, defined in
     `lib/features/finance/models/finance.dart`) and likewise zero out its time component.
  3. Return whether the zeroed first-billing date `isBefore` the zeroed today — a **date-only**
     comparison, so a subscription starting earlier today (or with a trial ending today) is not
     considered "before today".
- **Usage:**
  ```dart
  final shouldAskImport = !_isEditing && _firstBillingDayBeforeToday(sub);
  ```
  (`_submit`, same file/class.)
- **Notes:** Comparing at date granularity (rather than raw `DateTime.isBefore`) is deliberate —
  it prevents a same-day new subscription (created a few seconds/minutes after its `startDate`)
  from spuriously triggering the "import history?" prompt, since `startDate` and "now" would
  otherwise almost never be bit-for-bit equal.

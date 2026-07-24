# lib/features/finance/views/subscriptions_page.dart

The Finance feature's subscriptions list view: `SubscriptionsPage` (page shell) and its
`_SubscriptionsPageState`, which owns the active/historical subscription lists, three sort modes
(next-renewal, name, drag-to-reorder custom order), summary stats (monthly due, monthly average,
yearly average), the renewal reminder time setting, an upcoming-renewals chip row, and the full
add/edit/cancel/restore/delete subscription lifecycle. Three small `StatelessWidget`s
(`_SectionHeader`, `_SummaryCard`, `_SubscriptionTile`) render the list. Billing-date computation
itself (`calculateNextBillingDate`, `billingDatesBefore`, month-end clamping) lives on
[`Subscription`](../models/finance.md#subscription-new) and is only called from here, not
reimplemented; the hourly catch-up/idempotent-billing pass that actually generates day-of transactions
is [`SubscriptionProcessor`](../services/subscription_processor.md), whose `billingDateKey`/
`transactionIdForBilling` this file reuses when importing history. See
[Finance](../../../../features/finance.md#views-and-analysis-page) for where this page sits in the
module and [Subscription Billing](../../../../algorithms/subscription-billing.md) for the month-end
clamping and idempotent billing-day algorithms this page's next-billing-date calculations rely on.

This file is the concrete implementation of the cancel/restore state machine described in
[Finance](../../../../features/finance.md#views-and-analysis-page): a subscription can be cancelled
immediately or at expiry; a pending at-expiry cancellation can be undone in place; and a fully
historical (inactive) subscription restores by copying its settings into a **new** active subscription
rather than mutating the old one. Most of the methods implementing that state machine
(`_restoreSubscription`, `_undoAtExpiryCancellation`, `_copyRestoreSubscription`,
`_doCancelSubscription`, `_insertNewSubscription`, `_editSubscription`) are classified Tier A, along
with the billing-stat computations (`_monthlyDue`, `_monthlyAvg`), the sort/reorder logic, the
upcoming-renewals filter, the historical-transaction importer, and `_SubscriptionTile`'s status-label
computation (which directly reflects the subscription's current cancellation state).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SubscriptionsPage` (constructor) | constructor (`SubscriptionsPage`) | B | Create a subscriptions page instance. |
| `SubscriptionsPage.createState` | method (`SubscriptionsPage`) | B | Create the `_SubscriptionsPageState`. |
| `_SubscriptionsPageState.initState` | method (`_SubscriptionsPageState`) | B | Copy initial subscription/transaction/reminder/sort state from the widget. |
| [`_active`](#_active) | getter (`_SubscriptionsPageState`) | A | Return active subscriptions, sorted by the current sort mode. |
| [`_historical`](#_historical) | getter (`_SubscriptionsPageState`) | A | Return inactive (cancelled/expired) subscriptions. |
| [`_sortList`](#_sortlist) | method (`_SubscriptionsPageState`) | A | Sort a subscription list in place by name, custom order, or next renewal date. |
| [`_onSortModeChanged`](#_onsortmodechanged) | method (`_SubscriptionsPageState`) | A | Switch sort mode, seeding custom order from the active list when first entering custom mode. |
| [`_monthlyDue`](#_monthlydue) | method (`_SubscriptionsPageState`) | A | Sum each active subscription's amount normalized to a monthly cost in the default currency. |
| [`_monthlyAvg`](#_monthlyavg) | method (`_SubscriptionsPageState`) | A | Compute average monthly subscription spend from actual billed transactions, falling back to the projected due amount. |
| `_yearlyAvg` | method (`_SubscriptionsPageState`) | B | Return `_monthlyDue() * 12`. |
| `_addSubscription` | method (`_SubscriptionsPageState`) | B | Open the add-subscription dialog and insert the result. |
| [`_insertNewSubscription`](#_insertnewsubscription) | method (`_SubscriptionsPageState`) | A | Add a new subscription, computing its initial `nextBillingDate` and optionally importing billing history. |
| [`_editSubscription`](#_editsubscription) | method (`_SubscriptionsPageState`) | A | Open the edit dialog and, on save, recompute `nextBillingDate` if billing parameters changed. |
| [`_restoreSubscription`](#_restoresubscription) | method (`_SubscriptionsPageState`) | A | Dispatch to in-place undo (pending at-expiry cancellation) or copy-restore (historical subscription). |
| [`_undoAtExpiryCancellation`](#_undoatexpirycancellation) | method (`_SubscriptionsPageState`) | A | Reactivate a subscription with a pending at-expiry cancellation, clearing the cancellation. |
| [`_copyRestoreSubscription`](#_copyrestoresubscription) | method (`_SubscriptionsPageState`) | A | Open the edit dialog pre-filled from a historical subscription and insert the result as a brand-new active subscription. |
| [`_nextBillingDateFromToday`](#_nextbillingdatefromtoday) | method (`_SubscriptionsPageState`) | A | Compute the first billing date on/after today, as a fallback for subscriptions missing a persisted `nextBillingDate`. |
| [`_deleteSubscription`](#_deletesubscription) | method (`_SubscriptionsPageState`) | A | Remove a subscription and its custom-order entry, notifying both callbacks. |
| `_cancelSubscription` | method (widget helper) | B | Show the immediate-vs-at-expiry cancellation choice sheet. |
| [`_doCancelSubscription`](#_docancelsubscription) | method (`_SubscriptionsPageState`) | A | Apply the chosen cancellation type, computing `isActive` and stamping `cancelledAt`. |
| [`_importHistoricalTransactions`](#_importhistoricaltransactions) | method (`_SubscriptionsPageState`) | A | Generate historical billing transactions for a newly added subscription, skipping already-billed days. |
| `_openDetail` | method (`_SubscriptionsPageState`) | B | Push `SubscriptionDetailPage` and sync back any transaction edits. |
| [`_getUpcomingSubs`](#_getupcomingsubs) | method (`_SubscriptionsPageState`) | A | Collect subscriptions due within N days, excluding at-expiry-cancelled and immediate-cancelled-inactive ones. |
| [`_buildReorderBody`](#_buildreorderbody) | method (widget helper) | A | Render the drag-to-reorder list and persist the new custom order on drop. |
| `build` | method (`_SubscriptionsPageState`) | B | Build the scaffold: app bar with sort menu, summary cards, upcoming renewals, reminder setting, active/historical lists, add FAB. |
| `_SectionHeader` (constructor) | constructor (`_SectionHeader`) | B | Create a section header instance. |
| `_SectionHeader.build` | method (`_SectionHeader`) | B | Render a labeled section divider row. |
| `_SummaryCard` (constructor) | constructor (`_SummaryCard`) | B | Create a summary card instance. |
| `_SummaryCard.build` | method (`_SummaryCard`) | B | Render one icon/label/value stat card. |
| `_SubscriptionTile` (constructor) | constructor (`_SubscriptionTile`) | B | Create a subscription tile instance. |
| [`_SubscriptionTile.build`](#build) | method (`_SubscriptionTile`) | A | Render the subscription row, computing category/account/cycle/next-billing/cancelled labels from current state. |
| `_showActions` | method (`_SubscriptionTile`) | B | Show the edit/cancel/restore/delete action sheet for long-press. |
| [`_buildLeading`](#_buildleading) | method (`_SubscriptionTile`) | A | Resolve the tile's leading avatar through a subscription-image / emoji / account-image / category-emoji fallback chain. |
| `emojiAvatar` | local function (nested in `_buildLeading`) | B | Build a circular emoji avatar. |
| `defaultIcon` | local function (nested in `_buildLeading`) | B | Build the default repeat-icon avatar. |

`grep -c 'Purpose:' lib/features/finance/views/subscriptions_page.dart` reports 35, matching all 35
real declarations counted above exactly (19 Tier A, 16 Tier B). Every `/// Purpose:` block sits
directly above the real declaration it documents — no misattached blocks (blocks documenting a call
site instead of a declaration) were found, and no undocumented real declaration exists either. Unlike
`analysis_page.dart` (documented alongside this file, which has one undocumented method), this file's
doc comments are fully in sync with its declarations, including the two nested local functions
(`emojiAvatar`, `defaultIcon`) inside `_buildLeading`, which each carry their own `/// Purpose:` block.

## Documentation

### `List<Subscription> get _active` <a id="_active"></a>
- **Kind:** getter of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 96)
- **Purpose:** Return the currently active subscriptions, sorted according to the selected sort mode.
- **Inputs:** None (reads `_subscriptions`, `_sortMode`/`_customOrder` via `_sortList`).
- **Returns:** `List<Subscription>`.
- **Side effects:** None (the list passed to `_sortList` is a fresh copy from `.toList()`, so sorting
  it doesn't mutate `_subscriptions`).
- **Algorithm:** `_subscriptions.where((s) => s.isActive).toList()`, then `_sortList(list)` sorts it
  in place per the current `_sortMode` before returning.
- **Usage:** `final active = _active;` (`build`, line 678, also read directly inside `_monthlyDue`'s
  `for (final s in _active)` loop, line 174).
- **Notes:** Every read of `_active` re-filters and re-sorts `_subscriptions` from scratch; there is
  no caching, so calling it multiple times per `build` (as `build`, `_monthlyDue`, and `_monthlyAvg`
  indirectly all do) repeats the work.

### `List<Subscription> get _historical` <a id="_historical"></a>
- **Kind:** getter of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 107)
- **Purpose:** Return the subscriptions that are no longer active (fully cancelled or expired), for
  the "Historical" list section.
- **Inputs:** None (reads `_subscriptions`).
- **Returns:** `List<Subscription>`.
- **Side effects:** None.
- **Algorithm:** `_subscriptions.where((s) => !s.isActive).toList()` — unlike `_active`, no sort mode
  is applied; historical subscriptions keep `_subscriptions`' own order.
- **Usage:** `final historical = _historical;` (`build`, line 679).
- **Notes:** This is the getter that determines which subscriptions show a "Restore" action instead
  of "Cancel" in the tile's swipe/long-press menus (see `build`, lines 983-1045) — the `isActive` split
  here is the same boundary `_restoreSubscription` dispatches on.

### `void _sortList(List<Subscription> list)` <a id="_sortlist"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 115)
- **Purpose:** Sort a subscription list in place according to `_sortMode`.
- **Inputs:** `list` — mutated in place.
- **Returns:** None.
- **Side effects:** Sorts `list` in place (a copy, when called from `_active`).
- **Algorithm:** `switch (_sortMode)`: `'name'` → case-insensitive alphabetical; `'custom'` → sort by
  each item's index in `_customOrder` (items not present in `_customOrder` sort to the end, via a
  sentinel index of `_customOrder.length`); default (`'nextRenewal'`) → sort by `nextBillingDate`
  ascending, with `null` dates sorted after all non-null dates (both-`null` compares equal).
- **Usage:** `_sortList(list);` (`_active` getter, line 98 — the only call site).
- **Notes:** The `'custom'` branch is a no-op if `_customOrder` is empty (leaves `list` in whatever
  order `.where(...).toList()` produced) — `_onSortModeChanged` is what actually seeds `_customOrder`
  the first time the user switches into custom mode.

### `void _onSortModeChanged(String mode)` <a id="_onsortmodechanged"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 149)
- **Purpose:** Switch the active sort mode and, the first time the user enters custom mode with no
  existing custom order, seed one from the current active list.
- **Inputs:** `mode` — one of `'nextRenewal'`, `'name'`, `'custom'`.
- **Returns:** None.
- **Side effects:** `setState` updating `_sortMode`/`_reordering`/`_customOrder`; calls
  `widget.onSortChanged`.
- **Algorithm:**
  1. `setState`: set `_sortMode = mode`, `_reordering = false` (exit reorder mode if it was active);
     if `mode == 'custom'` and `_customOrder` is empty, initialize it from the ids of the currently
     active subscriptions (in their current display order).
  2. Call `widget.onSortChanged(_sortMode, _sortMode == 'custom' ? _customOrder : null)` to persist
     the choice.
- **Usage:** `onSelected: _onSortModeChanged` (`build`, line 699, the sort `PopupMenuButton`).
- **Notes:** Re-entering custom mode after it already has a `_customOrder` does *not* reseed it —
  the existing order (including any subscriptions added/removed since) is kept, so switching sort
  modes back and forth doesn't lose a previously arranged custom order.

### `double _monthlyDue()` <a id="_monthlydue"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 172)
- **Purpose:** Compute the projected monthly cost of all active subscriptions, normalized to a
  per-month figure and converted into the default currency.
- **Inputs:** None (reads `_active`, `widget.rateData.currentRates`, `widget.defaultCurrency`).
- **Returns:** `double`.
- **Side effects:** None.
- **Algorithm:** For each active subscription: if `billingCycleType == BillingCycleType.monthly`,
  `monthly = amount / billingInterval` (an every-N-months subscription's per-month share); otherwise
  (yearly), `monthly = amount / (billingInterval * 12)`. Convert each `monthly` value via
  [`convertCurrency`](../services/balance_util.md#convertcurrency) using **current** rates (not a
  historical snapshot — there is no per-subscription rate snapshot) into `widget.defaultCurrency`, and
  sum.
- **Usage:** `'$sym${numberFormat.format(_monthlyDue())}'` (`build`, line 762, the "Monthly Due"
  summary card); also the fallback return value inside `_monthlyAvg` and the basis for `_yearlyAvg`.
- **Notes:** This is a *projection* from each subscription's billing parameters, not a sum of actual
  past transactions — contrast with `_monthlyAvg`, which prefers real transaction history when enough
  of it exists.

### `double _monthlyAvg()` <a id="_monthlyavg"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 197)
- **Purpose:** Compute the average monthly subscription spend from actual billed transactions,
  falling back to the projected `_monthlyDue()` figure when there isn't enough transaction history
  yet.
- **Inputs:** None (reads `_transactions`, `widget.rateData.ratesAt`, `widget.defaultCurrency`).
- **Returns:** `double`.
- **Side effects:** None.
- **Algorithm:**
  1. Filter `_transactions` to those with a non-null `subscriptionId`. If none exist, return
     `_monthlyDue()`.
  2. Find the earliest such transaction's `date`.
  3. Compute `months = (now.year - earliest.year) * 12 + now.month - earliest.month` (whole
     calendar-month span). If `months < 2`, return `_monthlyDue()` (not enough history to average
     meaningfully).
  4. Otherwise, sum every subscription transaction's amount converted via `convertCurrency` using
     **that transaction's own historical rate snapshot** (`widget.rateData.ratesAt(t.rateSnapshotId)`)
     into `widget.defaultCurrency`, and divide by `months`.
- **Usage:** `'$sym${numberFormat.format(_monthlyAvg())}'` (`build`, line 771, the "Monthly Avg"
  summary card).
- **Notes:** Unlike `_monthlyDue` (which always uses current rates since there's no historical
  snapshot to project from), `_monthlyAvg`'s transaction-based path uses each transaction's own
  historical rate — the two summary cards can diverge not just in method (projection vs. actual
  average) but also in which exchange rate vintage they use.

### `void _insertNewSubscription(({Subscription sub, bool importHistory}) result)` <a id="_insertnewsubscription"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 254)
- **Purpose:** Insert a newly created (or copy-restored) subscription, computing its initial
  `nextBillingDate` so the very next processor run bills correctly, and optionally import its billing
  history as transactions.
- **Inputs:** `result` — a record from `AddSubscriptionDialog` containing the drafted `sub` and an
  `importHistory` flag.
- **Returns:** None.
- **Side effects:** `setState` appending to `_subscriptions` (and `_customOrder` if in custom sort
  mode); calls `widget.onSubscriptionsChanged` and, conditionally, `widget.onSortChanged`; may call
  `_importHistoricalTransactions`.
- **Algorithm:**
  1. Build a `tempSub` copy of `result.sub` (dropping any pre-set `nextBillingDate`/active-state
     fields, since this is always creating a fresh active subscription).
  2. Compute `initialNBD` via
     [`tempSub.calculateNextBillingDate`](../models/finance.md#calculatenextbillingdate): if
     `result.importHistory` is true, `after: today` (first billing date strictly after today, since
     today's — and all earlier — billing days will be backfilled as transactions separately); if not
     importing history, `after: today - 1 day` (first billing date on/after today, since the processor
     itself will catch today's billing on its next run rather than this method backfilling it).
  3. Build the final `sub` with that `nextBillingDate` baked in, `setState` to append it to
     `_subscriptions` (and `_customOrder` if `_sortMode == 'custom'`), then notify
     `widget.onSubscriptionsChanged` (and `widget.onSortChanged` if applicable).
  4. If `result.importHistory`, call `_importHistoricalTransactions(sub)`.
- **Usage:** `_insertNewSubscription(result);` (`_addSubscription`, line 245, and
  `_copyRestoreSubscription`, line 440 — both dialog flows funnel into this one insertion path).
- **Notes:** The `after: today` vs. `after: today - 1 day` distinction in step 2 is what prevents a
  history-importing add from double-billing today: importing already generates a transaction for
  today's billing day (if due), so `nextBillingDate` must skip past it; a non-importing add leaves
  today's billing for the regular `SubscriptionProcessor` catch-up to generate — see
  [Subscription Billing](../../../../algorithms/subscription-billing.md#hourly-renewal-catch-up-and-multi-cycle-catch-up).

### `Future<void> _editSubscription(Subscription sub)` <a id="_editsubscription"></a>
- **Kind:** async method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 315)
- **Purpose:** Open the edit dialog for an existing subscription and, on save, recompute
  `nextBillingDate` only if a billing-relevant parameter actually changed, otherwise preserve it.
- **Inputs:** `sub` — the subscription being edited.
- **Returns:** `Future<void>`.
- **Side effects:** Shows `AddSubscriptionDialog`; on a non-null result, `setState` replaces the
  matching subscription and calls `widget.onSubscriptionsChanged`.
- **Algorithm:**
  1. `await showDialog` with `AddSubscriptionDialog(subscription: sub, ...)` (edit mode).
  2. If a result came back, determine `billingChanged` — `true` if `startDate`, `trialDays`,
     `billingCycleType`, or `billingInterval` differ from the original `sub`.
  3. If `billingChanged`: build a `tempSub` from the *new* billing parameters and recompute `nbd` via
     `calculateNextBillingDate(after: today - 1 day)` (same "on/after today" anchor as a fresh add).
     Otherwise: keep `nbd = sub.nextBillingDate` unchanged.
  4. Build the `edited` subscription preserving `isActive`/`cancelledAt`/`cancelType` from the
     dialog's result (so cancellation state set elsewhere isn't clobbered by an edit) plus the
     resolved `nbd`; `setState` to replace it by matching `id` in `_subscriptions`; notify
     `widget.onSubscriptionsChanged`.
- **Usage:** `onEdit: () => _editSubscription(sub)` (`build`, lines 963 and 1029, wired to both the
  active and historical tile's edit action).
- **Notes:** Recomputing `nextBillingDate` only when billing parameters changed (rather than on every
  edit) avoids silently resetting a subscription's billing cursor just because the user edited an
  unrelated field like its name or emoji.

### `Future<void> _restoreSubscription(Subscription sub)` <a id="_restoresubscription"></a>
- **Kind:** async method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 384)
- **Purpose:** Restore a subscription, dispatching to the correct restore path based on its current
  cancellation state — this is the entry point for the "Restore" action on both active
  (pending-at-expiry) and historical (fully cancelled/expired) subscriptions.
- **Inputs:** `sub`.
- **Returns:** `Future<void>`.
- **Side effects:** Delegates entirely to `_undoAtExpiryCancellation` or `_copyRestoreSubscription`.
- **Algorithm:**
  1. If `sub.isActive && sub.cancelType == CancelType.atExpiry` (a pending at-expiry cancellation that
     hasn't taken effect yet): call `_undoAtExpiryCancellation(sub)` and return.
  2. Else if `!sub.isActive` (a subscription the processor has already deactivated, or one cancelled
     immediately): `await _copyRestoreSubscription(sub)`.
  3. (Implicit third case: an active subscription with no cancellation pending has no restore action
     wired to it in `build` in the first place — `onRestore` is only passed when
     `cancelType == CancelType.atExpiry` for active tiles, or unconditionally for historical tiles.)
- **Usage:** `onRestore: sub.cancelType == CancelType.atExpiry ? () { _restoreSubscription(sub); } :
  null` (`build`, lines 965-969, active tiles) and `onRestore: () { _restoreSubscription(sub); }`
  (`build`, line 1030, historical tiles).
- **Notes:** This method is the dispatcher for exactly the two restore behaviors described in
  [Finance](../../../../features/finance.md#views-and-analysis-page): "a pending at-expiry
  cancellation can be restored in place, while an expired or fully-cancelled subscription restores by
  copying its settings into a new active subscription."

### `void _undoAtExpiryCancellation(Subscription sub)` <a id="_undoatexpirycancellation"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 399)
- **Purpose:** Undo a pending at-expiry cancellation in place, without changing the subscription's
  identity (same `id`), reactivating it as an ordinary billing subscription.
- **Inputs:** `sub` — must currently be `isActive == true` with `cancelType == CancelType.atExpiry`
  (enforced by the only caller, `_restoreSubscription`).
- **Returns:** None.
- **Side effects:** `setState` replacing the matching subscription in `_subscriptions`; calls
  `widget.onSubscriptionsChanged`.
- **Algorithm:** Build a `restored` copy of `sub` with `isActive: true` (implicitly dropping
  `cancelledAt`/`cancelType`, since the new `Subscription(...)` call omits them and they default to
  unset) and `nextBillingDate: sub.nextBillingDate ?? _nextBillingDateFromToday(sub)` (falls back to a
  freshly computed date if the field was somehow unset); `setState` to overwrite the matching entry by
  `id`; notify `widget.onSubscriptionsChanged`.
- **Usage:** `_undoAtExpiryCancellation(sub);` (`_restoreSubscription`, line 386 — the only call
  site).
- **Notes:** This is equivalent to simply removing the scheduled cancellation marker — the
  subscription keeps its original `id`/`startDate`/history, which is the key difference from
  `_copyRestoreSubscription`'s new-identity restore path.

### `Future<void> _copyRestoreSubscription(Subscription sub)` <a id="_copyrestoresubscription"></a>
- **Kind:** async method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 429)
- **Purpose:** Restore a fully historical (inactive) subscription by opening the edit dialog
  pre-filled from its settings and, on confirmation, inserting the result as a **brand-new** active
  subscription — the source subscription itself is left untouched.
- **Inputs:** `sub` — the historical subscription being restored.
- **Returns:** `Future<void>`.
- **Side effects:** Shows `AddSubscriptionDialog`; on a non-null result, delegates to
  `_insertNewSubscription` (which appends a new entry and notifies callbacks).
- **Algorithm:** `await showDialog` with `AddSubscriptionDialog(subscription: sub, restoreAsCopy:
  true, ...)`; if the dialog returns a result, call `_insertNewSubscription(result)`.
- **Usage:** `await _copyRestoreSubscription(sub);` (`_restoreSubscription`, line 390 — the only call
  site).
- **Notes:** `restoreAsCopy: true` is a flag passed to `AddSubscriptionDialog` (not shown in this
  file) that presumably pre-fills the form with `sub`'s values while letting `AddSubscriptionDialog`
  generate a *new* id/`startDate` for the returned draft — this method doesn't itself strip `sub.id`;
  it trusts the dialog to hand back a fresh subscription, which is why the resulting insert goes
  through the same `_insertNewSubscription` path as an ordinary new addition.

### `DateTime? _nextBillingDateFromToday(Subscription sub)` <a id="_nextbillingdatefromtoday"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 449)
- **Purpose:** Compute the first billing date on or after today, used as a fallback when a
  subscription being reactivated lacks a persisted `nextBillingDate`.
- **Inputs:** `sub`.
- **Returns:** `DateTime?` — `null` only if
  [`calculateNextBillingDate`](../models/finance.md#calculatenextbillingdate) itself returns `null`
  (e.g. an `atExpiry`-cancelled subscription past its cutoff — not expected to apply here since the
  caller only reaches this after clearing cancellation).
- **Side effects:** None.
- **Algorithm:** `sub.calculateNextBillingDate(after: today - 1 day)` — the "on/after today" anchor
  pattern used consistently across this file's billing-date recomputation call sites.
- **Usage:** `nextBillingDate: sub.nextBillingDate ?? _nextBillingDateFromToday(sub)`
  (`_undoAtExpiryCancellation`, line 415 — the only call site).
- **Notes:** This mirrors the "migration case" in
  [`SubscriptionProcessor.process`](../../../../algorithms/subscription-billing.md#hourly-renewal-catch-up-and-multi-cycle-catch-up)
  (computing a `nextBillingDate` once for a subscription that predates the field being persisted), but
  applied here specifically to the at-expiry-undo path rather than the general processor catch-up.

### `void _deleteSubscription(Subscription sub)` <a id="_deletesubscription"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 462)
- **Purpose:** Permanently remove a subscription (active or historical) and keep the custom sort
  order consistent by also removing its id from there.
- **Inputs:** `sub`.
- **Returns:** None.
- **Side effects:** `setState` removing from `_subscriptions` and `_customOrder`; calls
  `widget.onSubscriptionsChanged` and, if in custom sort mode, `widget.onSortChanged`.
- **Algorithm:** `setState`: `_subscriptions.removeWhere((s) => s.id == sub.id)` and
  `_customOrder.remove(sub.id)`; then notify `widget.onSubscriptionsChanged(_subscriptions)`, and if
  `_sortMode == 'custom'`, also `widget.onSortChanged(_sortMode, _customOrder)`.
- **Usage:** Always gated behind `confirmDelete(context, l10n.financeThisSubscription)` at the call
  site, e.g. `if (confirmed == true) { _deleteSubscription(sub); }` (`build`, lines 975-977 and
  998-1001, active and historical `Dismissible.confirmDismiss`/`onDelete`).
- **Notes:** No transactions previously generated from this subscription are deleted or
  unlinked — only the subscription record and its custom-order entry are removed; a deleted
  subscription's past billing transactions remain in `_transactions` unaffected, still carrying the
  now-orphaned `subscriptionId`.

### `void _doCancelSubscription(Subscription sub, CancelType type)` <a id="_docancelsubscription"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 511)
- **Purpose:** Apply the chosen cancellation type to a subscription — the actual state transition
  behind both the "Cancel immediately" and "Cancel at expiry" choices.
- **Inputs:** `sub`; `type` — `CancelType.immediate` or `CancelType.atExpiry`.
- **Returns:** None.
- **Side effects:** `setState` replacing the matching subscription in `_subscriptions`; calls
  `widget.onSubscriptionsChanged`.
- **Algorithm:** Build a `cancelled` copy of `sub` with `isActive: type == CancelType.atExpiry`
  (an at-expiry cancellation stays active — the app keeps billing it — until the processor's own
  expiry check flips it off, per
  [Subscription Billing](../../../../algorithms/subscription-billing.md#hourly-renewal-catch-up-and-multi-cycle-catch-up);
  an immediate cancellation is deactivated right away), `cancelledAt: DateTime.now()`, `cancelType:
  type`, and the *unchanged* `nextBillingDate`; `setState` to overwrite the matching entry by `id`;
  notify `widget.onSubscriptionsChanged`.
- **Usage:**
  ```dart
  ListTile(
    leading: const Icon(Icons.cancel),
    title: Text(l10n.financeCancelImmediate),
    onTap: () {
      Navigator.pop(ctx);
      _doCancelSubscription(sub, CancelType.immediate);
    },
  ),
  ```
  (`_cancelSubscription`, lines 484-491, alongside an identical `atExpiry` `ListTile`, lines 492-499.)
- **Notes:** `isActive: type == CancelType.atExpiry` is the crux of the whole cancel/restore state
  machine: an `atExpiry` cancellation is deliberately left "active" (so it keeps appearing and keeps
  billing) until `SubscriptionProcessor` later flips it inactive at the cutoff, whereas `immediate`
  goes inactive the instant the user confirms — this is why `_restoreSubscription` has to check
  `sub.isActive && sub.cancelType == CancelType.atExpiry` specifically to distinguish "still active
  but scheduled to stop" from "already stopped."

### `void _importHistoricalTransactions(Subscription sub)` <a id="_importhistoricaltransactions"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 543)
- **Purpose:** Generate transactions for every billing day a newly added subscription would have
  already incurred (from its `startDate`/anchor up to today), without duplicating any billing day that
  already has a matching transaction.
- **Inputs:** `sub` — the just-inserted subscription.
- **Returns:** None.
- **Side effects:** `setState` appending to `_transactions` (only if there's anything new to add);
  calls `widget.onTransactionsChanged`.
- **Algorithm:**
  1. `dates = sub.billingDatesBefore(now)` — every historical billing date from the subscription's
     anchor up to now, via
     [`Subscription.billingDatesBefore`](../models/finance.md#billingdatesbefore).
  2. Build `existingKeys`, a set of
     [`SubscriptionProcessor.billingDateKey`](../services/subscription_processor.md#billingdatekey)
     values for every existing transaction that has a `subscriptionId` — the same idempotency key
     scheme `SubscriptionProcessor` itself uses.
  3. For each historical `date`: compute its `billingDateKey(sub.id, date)`; if adding it to
     `existingKeys` reports it was *already* present (`!existingKeys.add(key)`), skip it — that day is
     already billed; otherwise build a new expense `Transaction` with a stable id via
     [`SubscriptionProcessor.transactionIdForBilling`](../services/subscription_processor.md#transactionidforbilling).
  4. If any new transactions were built, `setState(() => _transactions.addAll(newTxs))` and notify
     `widget.onTransactionsChanged`.
- **Usage:** `_importHistoricalTransactions(sub);` (`_insertNewSubscription`, line 306, only when
  `result.importHistory` is true).
- **Notes:** By reusing `SubscriptionProcessor`'s exact key/id scheme (see
  [Subscription Billing](../../../../algorithms/subscription-billing.md#idempotent-billing-day-generation)),
  a historical import here and a later processor catch-up pass can never double-bill the same day even
  if both somehow ran against overlapping date ranges — the dedup is keyed on
  `'$subscriptionId|yyyy-MM-dd'`, not on transaction id origin.

### `List<(Subscription, DateTime)> _getUpcomingSubs(int days)` <a id="_getupcomingsubs"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 605)
- **Purpose:** Collect subscriptions whose next billing day falls within the next `days` days, for
  the "Upcoming renewals" chip row — deliberately excluding subscriptions whose next charge won't
  actually happen.
- **Inputs:** `days` — the look-ahead window.
- **Returns:** `List<(Subscription, DateTime)>`, sorted ascending by billing date.
- **Side effects:** None.
- **Algorithm:**
  1. `limit = today + days`.
  2. For each subscription in `_subscriptions`: skip if `cancelType == CancelType.atExpiry`
     (regardless of `isActive` — an at-expiry-pending subscription is excluded from renewal reminders
     even while it's still nominally active and billing); skip if `!isActive &&
     cancelType == CancelType.immediate` (an already-cancelled subscription obviously won't renew).
  3. If the subscription has a `nextBillingDate` and its calendar day is on/before `limit`, add
     `(sub, next)` to the result.
  4. Sort the result ascending by billing date.
- **Usage:** `final upcomingSubs = _getUpcomingSubs(3);` (`build`, line 680 — a fixed 3-day look-ahead
  window for the chip row).
- **Notes:** The doc comment's own note captures the key subtlety: "At-expiry cancellations keep
  showing in subscription lists but are excluded from renewal reminders" — i.e. this filter is
  stricter than the `_active`/`_historical` split (which only looks at `isActive`), because an
  at-expiry subscription is still `isActive == true` yet shouldn't generate a renewal reminder for a
  charge that, from the user's perspective, is about to stop.

### `Widget _buildReorderBody(ThemeData theme, AppLocalizations l10n, List<Subscription> active)` <a id="_buildreorderbody"></a>
- **Kind:** method of `_SubscriptionsPageState`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 630)
- **Purpose:** Render the drag-to-reorder list shown while `_reordering` is true, and persist the
  new custom order as soon as an item is dropped.
- **Inputs:** `theme`; `l10n`; `active` — the active subscriptions in their current custom order.
- **Returns:** `Widget` (a `ReorderableListView.builder`).
- **Side effects:** `setState` mutating `_customOrder`; calls `widget.onSortChanged` on every reorder.
- **Algorithm:**
  1. Copy `active` into a mutable `items` list (the widget itself only reads from it; the real
     mutation happens on `_customOrder`).
  2. `onReorderItem: (oldIndex, newIndex)`: `setState` to `_customOrder.removeAt(oldIndex)` then
     `.insert(newIndex, item)` — move the id within the persisted order — then immediately call
     `widget.onSortChanged(_sortMode, _customOrder)` to persist it.
  3. Each item tile shows the subscription's name, formatted amount, and emoji (if any); a drag handle
     leading icon.
- **Usage:** `body: _reordering ? _buildReorderBody(theme, l10n, active) : Column(...)` (`build`, line
  751 — swaps the entire body for the reorder list while `_reordering` is true).
- **Notes:** Reordering only ever operates on `active` subscriptions (historical ones aren't
  reorderable), and the persisted `_customOrder` list is exactly the sequence of active subscription
  ids — `_sortList`'s `'custom'` branch is what turns that persisted order back into a sorted `_active`
  list on the next non-reorder render.

### `Widget build(BuildContext context)` <a id="build"></a>
- **Kind:** method override of `_SubscriptionTile` (a `StatelessWidget`)
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 1197)
- **Purpose:** Render one subscription's list row, computing every status label (category, account,
  billing cycle, next-billing/expiry date, cancellation date) from the subscription's *current* state
  before laying out the `ListTile`.
- **Inputs:** `context`.
- **Returns:** `Widget`.
- **Side effects:** None directly; `onLongPress` opens `_showActions`.
- **Algorithm:**
  1. Resolve `cat`/`account` by id lookup in `categories`/`accounts` (`firstOrNull`); build
     `catLabel`/`accountLabel` as `"emoji name"` or bare `name` if no emoji.
  2. `cycleLabel` — `l10n.financeEveryXMonths`/`financeEveryXYears` depending on
     `billingCycleType`, parameterized by `billingInterval`.
  3. `nextLabel` — branches on cancellation state: if `cancelType == CancelType.atExpiry` and
     `nextBillingDate` is set, label it as the **expiry date** (regardless of whether the subscription
     is still `isActive`); else if `isActive` and `nextBillingDate` is set, label it as the **next
     billing date**; otherwise `null` (no date shown, e.g. an immediately-cancelled subscription).
  4. `cancelLabel` — only set when `cancelledAt != null` *and* `cancelType != CancelType.atExpiry`
     (i.e. only for immediate cancellations — an at-expiry cancellation's date is already shown via
     `nextLabel` as the expiry date, so it isn't repeated here).
  5. Assemble `subtitleParts` from the non-null labels plus `cycleLabel` (always present), plus
     `cancelLabel` only when `!isActive`; join with `"  •  "`.
  6. Render a `ListTile` with `_buildLeading` as the leading avatar, name/placeholder title, the
     amount as trailing text (styled with the theme's error color), `onTap`/`onLongPress` wired to the
     passed-in callbacks / `_showActions`.
- **Usage:**
  ```dart
  _SubscriptionTile(
    subscription: sub,
    categories: widget.categories,
    accounts: widget.accounts,
    defaultCurrency: widget.defaultCurrency,
    onTap: () => _openDetail(sub),
    onEdit: () => _editSubscription(sub),
    onCancel: () => _cancelSubscription(sub),
    onRestore: sub.cancelType == CancelType.atExpiry ? () { _restoreSubscription(sub); } : null,
    onDelete: () async { /* confirmDelete then _deleteSubscription(sub) */ },
  )
  ```
  (`_SubscriptionsPageState.build`, lines 957-979, wrapped in a `Dismissible` for swipe actions.)
- **Notes:** Steps 3-4 are where the cancel/restore state machine becomes user-visible: an
  at-expiry-cancelled subscription that is still technically `isActive` shows an "Expiry date" label
  (not "Next billing"), which is the tile-level signal that distinguishes it from an ordinary active
  subscription even before the user opens the long-press menu to see the Restore action.

### `Widget _buildLeading(Subscription sub, Account? account, Category? cat, ThemeData theme)` <a id="_buildleading"></a>
- **Kind:** method of `_SubscriptionTile`
- **Source:** `lib/features/finance/views/subscriptions_page.dart` (line 1335)
- **Purpose:** Resolve the tile's leading avatar through a four-tier fallback chain: the
  subscription's own image, then its own emoji, then the linked account's image, then the linked
  category's emoji, finally a generic repeat icon.
- **Inputs:** `sub`; `account`; `cat`; `theme` (only `theme.colorScheme.error` is used, as the avatar
  background/foreground tint).
- **Returns:** `Widget`.
- **Side effects:** None (the `FutureBuilder` branches read from disk via `ImageService.resolve`, but
  that is encapsulated inside the returned widget's own build, not a side effect of this call itself).
- **Algorithm:**
  1. Two nested local helpers: `emojiAvatar(String emoji)` (a tinted `CircleAvatar` with the emoji as
     text) and `defaultIcon()` (a tinted `CircleAvatar` with `Icons.repeat`).
  2. If `sub.imagePath != null`: return a `FutureBuilder<File>` resolving
     `ImageService.resolve(sub.imagePath!)`; if the resolved file exists, show it as a
     `CircleAvatar.backgroundImage`; otherwise fall back to `sub.emoji` (via `emojiAvatar`) or
     `defaultIcon()`.
  3. Else if `sub.emoji != null`: return `emojiAvatar(sub.emoji!)` directly (no image to resolve).
  4. Else if `account?.imagePath != null`: same `FutureBuilder` pattern as step 2, but falling back
     (if the image doesn't resolve) to `cat?.emoji` via `emojiAvatar` or `defaultIcon()`.
  5. Else if `cat?.emoji != null`: return `emojiAvatar(cat!.emoji!)`.
  6. Otherwise: `defaultIcon()`.
- **Usage:** `leading: _buildLeading(sub, account, cat, theme)` (`_SubscriptionTile.build`, line 1251).
- **Notes:** The fallback order strictly prioritizes the subscription's own branding (image, then
  emoji) over the linked account's or category's — an account image is only ever consulted if the
  subscription itself has neither an image nor an emoji, and a category emoji is the last resort
  before the generic icon.

## Related pages

- [Finance](../../../../features/finance.md#views-and-analysis-page) — concept-level description of
  the subscription cancel/restore behavior this page implements.
- [Subscription Billing](../../../../algorithms/subscription-billing.md) — the month-end clamping and
  idempotent billing-day generation algorithms behind `calculateNextBillingDate`/`billingDatesBefore`
  and this page's `_importHistoricalTransactions`.
- [`Subscription`/`CancelType`/`BillingCycleType`](../models/finance.md) — the model this page reads
  and reconstructs (via `copyWith`-style field-by-field `Subscription(...)` calls) throughout the
  cancel/restore/edit flows.
- [`SubscriptionProcessor.billingDateKey`/`transactionIdForBilling`](../services/subscription_processor.md) —
  the idempotency key/id scheme `_importHistoricalTransactions` reuses.
- [`convertCurrency`/`currencySymbol`](../services/balance_util.md) — currency conversion used by
  `_monthlyDue`/`_monthlyAvg`.
- [`ExchangeRateData.ratesAt`/`currentRates`](../services/exchange_rate_storage.md) — historical vs.
  current rate lookup, whose distinction underlies the Notes on `_monthlyDue`/`_monthlyAvg`.

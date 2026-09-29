# lib/shared/utils/id_list_delta.dart

Merge-by-id support for sub-page saves (v1.5.2). A sub-page (accounts, subscriptions, categories,
partners, toys, positions, body settings, ...) receives a record list, edits it, and hands the whole
list back through a callback. Writing that list as-is would overwrite anything another writer (the
subscription renewal loop, the local API server, a WebDAV sync) changed while the sub-page was open.
`IdListDelta` records only what the sub-page changed relative to the list it started from, keyed by
record id, and `applyTo` replays those changes onto the freshly loaded on-disk list.
`IdListBaseline` keeps the last list a sub-page reported so that each callback yields only its own
changes. The file is used by `_commitSubPage` in the Finance page (see
[../../features/finance/views/finance_page.md](../../features/finance/views/finance_page.md)) and
the Intimacy page (see
[../../features/intimacy/views/intimacy_page.md](../../features/intimacy/views/intimacy_page.md)).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`IdListDelta` (constructor)](#idlistdelta-new) | constructor (`IdListDelta<T>`) | A | Create a delta from already computed parts. |
| [`IdListDelta.diff`](#idlistdelta-diff) | factory constructor (`IdListDelta<T>`) | A | Compute what changed between a baseline list and an edited list. |
| [`isEmpty`](#isempty) | getter (`IdListDelta<T>`) | A | Report whether the sub-page changed nothing. |
| [`applyTo`](#applyto) | method (`IdListDelta<T>`) | A | Replay the delta onto a freshly loaded list. |
| [`IdListBaseline` (constructor)](#idlistbaseline-new) | constructor (`IdListBaseline<T>`) | A | Start tracking from the list handed to a sub-page. |
| [`take`](#take) | method (`IdListBaseline<T>`) | A | Diff a callback's list against the previous one, then advance the baseline. |

`grep -c 'Purpose:' lib/shared/utils/id_list_delta.dart` reports 6, matching all six real
declarations in this file exactly. No misattachment or undocumented declarations found. Every
declaration is Tier A per the blanket rule for `shared/`. The public fields `upserts`,
`upsertIndexes`, and `removedIds` and the private fields `_idOf` and `_baseline` carry field doc
comments rather than `Purpose:` blocks and are not counted as separate declarations.

## Documentation

### `IdListDelta({required List<T> upserts, required List<int> upsertIndexes, required Set<String> removedIds, required String Function(T item) idOf})` <a id="idlistdelta-new"></a>
- **Kind:** constructor of `IdListDelta<T>`
- **Source:** `lib/shared/utils/id_list_delta.dart` (line 26)
- **Purpose:** Create a delta from already computed parts.
- **Inputs:** `upserts` — items the sub-page added or replaced, in the edited list's order;
  `upsertIndexes` — each upsert's index in the edited list; `removedIds` — ids present in the
  baseline but absent from the edited list; `idOf` — the record id accessor.
- **Returns:** A new `IdListDelta<T>`.
- **Side effects:** None.
- **Algorithm:** Field-initializing constructor; asserts `upserts.length == upsertIndexes.length`
  and stores `idOf` as the private `_idOf`.
- **Usage:** Called by `IdListDelta.diff` (below). Production code does not call it directly.
- **Notes:** Prefer `IdListDelta.diff`; per its own doc comment this constructor exists for that
  factory and for tests.

### `factory IdListDelta.diff(List<T> baseline, List<T> edited, String Function(T item) idOf)` <a id="idlistdelta-diff"></a>
- **Kind:** factory constructor of `IdListDelta<T>`
- **Source:** `lib/shared/utils/id_list_delta.dart` (line 42)
- **Purpose:** Compute what changed between `baseline` (a copy of the list the sub-page started
  from) and `edited` (the list it handed back).
- **Inputs:** `baseline`; `edited`; `idOf` — the record id accessor.
- **Returns:** `IdListDelta<T>`.
- **Side effects:** None.
- **Algorithm:**
  1. Index `baseline` by id (`putIfAbsent`, so the first occurrence of a duplicate id wins).
  2. Walk `edited` in order, collecting every id seen. An item whose id is not in the baseline, or
     whose baseline object is not `identical` to it, becomes an upsert, and its index in `edited`
     is recorded in `upsertIndexes`.
  3. `removedIds` = every baseline id that does not appear in `edited`.
- **Usage:**
  ```dart
  final delta = IdListDelta.diff(baseline, t.edited, id);
  ```
  (`test/id_list_delta_test.dart`.) Production code reaches it through `IdListBaseline.take`.
- **Notes:** Change detection is by object identity, not equality: models are immutable, so an edit
  always produces a new object, and an untouched record is the very same object. `baseline` must be
  a copy (`List.of`) because sub-pages mutate and return the very list they were given — a
  non-copied baseline would already contain the edits.

### `bool get isEmpty` <a id="isempty"></a>
- **Kind:** getter of `IdListDelta<T>`
- **Source:** `lib/shared/utils/id_list_delta.dart` (line 81)
- **Purpose:** Report whether the sub-page changed nothing.
- **Inputs:** None.
- **Returns:** `bool` — `true` when there are no upserts and no removed ids.
- **Side effects:** None.
- **Algorithm:** `upserts.isEmpty && removedIds.isEmpty`.
- **Usage:** Checked first by `applyTo`, which then returns a plain copy of `fresh`.
- **Notes:** A pure reorder of unchanged items is not captured, by design: every item keeps its
  identity, so the delta is empty and the on-disk order wins. Custom orders are persisted separately
  (sort-mode/custom-order settings), not through the record list.

### `List<T> applyTo(List<T> fresh)` <a id="applyto"></a>
- **Kind:** method of `IdListDelta<T>`
- **Source:** `lib/shared/utils/id_list_delta.dart` (line 91)
- **Purpose:** Replay this delta onto a freshly loaded list.
- **Inputs:** `fresh` — the current list from disk.
- **Returns:** A new `List<T>`; `fresh` itself is not modified.
- **Side effects:** None.
- **Algorithm:**
  1. If `isEmpty`, return `List<T>.of(fresh)`.
  2. Copy `fresh`, dropping every item whose id is in `removedIds`.
  3. For each upsert in order: if an item with the same id is in the result, replace it in place;
     otherwise insert the upsert at `min(its edited index, result.length)`.
- **Usage:**
  ```dart
  final merged = base.copyWith(
    accounts: accounts?.applyTo(base.accounts),
    categories: categories?.applyTo(base.categories),
    transactions: transactions?.applyTo(base.transactions),
    subscriptions: subscriptions?.applyTo(base.subscriptions),
  );
  ```
  (`lib/features/finance/views/finance_page.dart`, `_commitSubPage`, inside the page's I/O queue
  after re-reading `finance_data.json`; `intimacy_page.dart`'s `_commitSubPage` does the same for
  partners, toys, positions, records, and cycle records.)
- **Notes:**
  - An upsert whose id was deleted concurrently (absent from `fresh`) is re-added at its edited
    index: the user's edit wins over a concurrent delete.
  - Records the sub-page did not touch keep their fresh value, including records another writer
    added, changed, or deleted meanwhile (an untouched record deleted elsewhere stays deleted).
  - Insert positions are clamped to the current length, so a new item never throws when `fresh`
    has shrunk.

### `IdListBaseline(List<T> initial, String Function(T item) idOf)` <a id="idlistbaseline-new"></a>
- **Kind:** constructor of `IdListBaseline<T>`
- **Source:** `lib/shared/utils/id_list_delta.dart` (line 122)
- **Purpose:** Start tracking from the list handed to a sub-page.
- **Inputs:** `initial` — the list the sub-page opens with; `idOf` — the record id accessor.
- **Returns:** A new `IdListBaseline<T>`.
- **Side effects:** None.
- **Algorithm:** Stores `List<T>.of(initial)` as the private `_baseline` and `idOf` as `_idOf`.
- **Usage:**
  ```dart
  final accountBase = IdListBaseline<Account>(_accounts, (a) => a.id);
  final txBase = IdListBaseline<Transaction>(_transactions, (t) => t.id);
  ```
  (`lib/features/finance/views/finance_page.dart`, `_openAccounts`, created just before pushing
  `AccountsPage`; `_openAnalysis`, `_openSubscriptions`, `_openSubscriptionDetail`, and the
  categories entry of `_showFinanceMenu` follow the same pattern, and `intimacy_page.dart`'s `_openPartnerManagement`, `_openToyManagement`,
  `_openPositionManagement`, and `_openBodySettings` create one baseline per list the sub-page can
  report.)
- **Notes:** Copies `initial` because sub-pages mutate the list they were given; without the copy
  the baseline would silently follow the sub-page's edits and every diff would be empty.

### `IdListDelta<T> take(List<T> edited)` <a id="take"></a>
- **Kind:** method of `IdListBaseline<T>`
- **Source:** `lib/shared/utils/id_list_delta.dart` (line 131)
- **Purpose:** Diff a sub-page callback's list against the previously reported one, then advance
  the baseline.
- **Inputs:** `edited` — the list the sub-page just reported.
- **Returns:** `IdListDelta<T>` holding only this callback's changes.
- **Side effects:** Replaces the stored baseline with `List<T>.of(edited)`.
- **Algorithm:** `delta = IdListDelta<T>.diff(_baseline, edited, _idOf)`; `_baseline =
  List<T>.of(edited)`; return `delta`.
- **Usage:**
  ```dart
  onChanged: (updated) {
    _commitSubPage(partners: partnerBase.take(updated));
  },
  ```
  (`lib/features/intimacy/views/intimacy_page.dart`, `_openPartnerManagement`; the Finance page's
  `_openAccounts` does the same with `accountBase.take(a)`.)
- **Notes:** Call exactly once per callback, synchronously, before any `await` — the baseline must
  advance in callback order so that a second callback does not re-send the first one's changes.
  Covered by `test/id_list_delta_test.dart` ("IdListBaseline yields only each callback's own
  changes"); the end-to-end behaviour (a renewal written while the accounts page is open survives;
  records added elsewhere survive a partner rename) is covered by `test/subpage_merge_test.dart`.

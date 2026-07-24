# lib/features/finance/views/categories_page.dart

The Categories management page: three tabs (expense/income/transfer) each listing
[`Category`](../../../../features/finance.md#model) records for that
[`TransactionType`](../../../../features/finance.md#model), with add/edit/delete and a
"one-tap import defaults" empty state backed by this file's own hard-coded starter-category tables
(`_defaultExpenseCategories`, `_defaultIncomeCategories`, `_defaultTransferCategories`). Tapping a
category pushes [`CategoryDetailPage`](category_detail_page.md). See
[Finance](../../../../features/finance.md#model) for the `Category`/`IconRef` model fields this page
edits, and [`finance.md`'s model doc](../models/finance.md#category-new) for why release builds need
`--no-tree-shake-icons` (icons are reconstructed from a stored code point + font family).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `CategoriesPage({...})` | constructor (`CategoriesPage`) | B | Create a categories page instance. |
| `createState` | method (`CategoriesPage`) | B | Create the mutable state object for this widget. |
| `initState` | method (`_CategoriesPageState`) | B | Copy categories/transactions into local state and create the 3-tab `TabController`. |
| `dispose` | method (`_CategoriesPageState`) | B | Dispose the `TabController`. |
| `_notify` | method (`_CategoriesPageState`) | B | Forward the current category list to `widget.onChanged`. |
| `_ofType` | method (`_CategoriesPageState`) | B | Filter categories to one transaction type. |
| `_addCategory` | method (`_CategoriesPageState`) | B | Add a category via dialog. |
| `_editCategory` | method (`_CategoriesPageState`) | B | Edit a category via dialog. |
| `_deleteCategory` | method (`_CategoriesPageState`) | B | Remove a category from local state and notify. |
| `_openCategoryDetail` | method (`_CategoriesPageState`) | B | Push `CategoryDetailPage` for a tapped category. |
| [`_importDefaults`](#importdefaults) | method (`_CategoriesPageState`) | A | Bulk-create the hard-coded starter categories for one transaction type. |
| [`_resolveKey`](#resolvekey) | method (`_CategoriesPageState`) | A | Map a default-category key string to its localized name. |
| `build` | method (`_CategoriesPageState`) | B | Build the tab bar, tab views, and add button. |
| `_buildCategoryList` | method (`_CategoriesPageState`, widget helper) | B | Build one tab's category list (or its import-defaults empty state). |
| `_CategoryDialog({...})` | constructor (`_CategoryDialog`) | B | Create a category dialog instance. |
| `createState` | method (`_CategoryDialog`) | B | Create the mutable state object for this widget. |
| `initState` | method (`_CategoryDialogState`) | B | Pre-fill name/icon/emoji from `widget.category` (or defaults), capture the initial signature. |
| `dispose` | method (`_CategoryDialogState`) | B | Dispose the name text controller. |
| `build` | method (`_CategoryDialogState`) | B | Build the name field, emoji grid, icon grid, and actions. |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | method (`_CategoryDialogState`) | A | Report whether the form differs from its initial state. |
| [`_signature`](#signature) | method (`_CategoryDialogState`) | A | Build a comparable string snapshot of the dialog's fields. |
| [`_submit`](#submit) | method (`_CategoryDialogState`) | A | Validate the name and pop with a `Category`. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/views/categories_page.dart` returns 22,
matching the 22 rows above exactly — every block sits immediately above its real declaration (a
constructor, `createState`, `initState`, `dispose`, or a method); none were found misattached above
a call-site statement, and no undocumented real declaration was found. The class declarations
themselves (`CategoriesPage`, `_CategoriesPageState`, `_CategoryDialog`, `_CategoryDialogState`) and
the top-level data literals (`_defaultExpenseCategories`, `_defaultIncomeCategories`,
`_defaultTransferCategories`, `_categoryIcons`, `_commonEmojis`) carry no `/// Purpose:` block,
consistent with this codebase's convention of documenting callable members rather than classes or
plain data tables.

## Documentation

### `void _importDefaults(TransactionType type)` <a id="importdefaults"></a>
- **Kind:** method of `_CategoriesPageState`
- **Source:** `lib/features/finance/views/categories_page.dart` (lines 214-231)
- **Purpose:** Bulk-create a starter set of localized categories for one transaction type, from this
  file's hard-coded default-category tables.
- **Inputs:** `type` — which default set to import (expense/income/transfer).
- **Returns:** None.
- **Side effects:** Appends new `Category` objects to `_categories`; calls `_notify()`.
- **Algorithm:**
  1. Pick the matching hard-coded default list — `_defaultExpenseCategories`,
     `_defaultIncomeCategories`, or `_defaultTransferCategories` — for `type`.
  2. Map each default entry (a `{key, emoji, icon}` map) into a real
     [`Category`](../models/finance.md#category-new): the name is localized via
     [`_resolveKey`](#resolvekey), and the icon's `codePoint` is taken from the entry's `IconData`
     constant (`fontFamily` defaults to `'MaterialIcons'` inside
     [`IconRef`](../models/finance.md#iconref-new)).
  3. Append all of them to `_categories` inside `setState` and call `_notify()`.
- **Usage:**
  ```dart
  FilledButton.tonal(
    onPressed: () => _importDefaults(type),
    child: Text(l10n.financeImportDefaults),
  ),
  ```
  (shown on the empty-state view for a tab with no categories of that type yet.)
- **Notes:** There is no de-duplication check — calling this twice (e.g. after already importing)
  appends a second batch of categories with the same names/icons rather than being a no-op.

### `String _resolveKey(AppLocalizations l10n, String key)` <a id="resolvekey"></a>
- **Kind:** method of `_CategoriesPageState`
- **Source:** `lib/features/finance/views/categories_page.dart` (lines 238-258)
- **Purpose:** Map one of this file's internal default-category key strings (e.g.
  `'financeCatFood'`) to its localized display name.
- **Inputs:** `l10n`; `key` — one of the literal `'financeCatXxx'` strings used in
  `_defaultExpenseCategories`/`_defaultIncomeCategories`/`_defaultTransferCategories`.
- **Returns:** `String` — the localized name, or `key` itself unchanged if it matches no known case.
- **Side effects:** None.
- **Algorithm:** A direct `switch` expression mapping each of the 17 known default-category keys to
  its corresponding `AppLocalizations` getter (`financeCatFood` -> `l10n.financeCatFood`, etc.); an
  unrecognized key falls through to the `_ => key` default branch and is returned verbatim.
- **Usage:**
  ```dart
  name: _resolveKey(l10n, d['key'] as String),
  ```
  (inside [`_importDefaults`](#importdefaults).)
- **Notes:** The verbatim fallback means a typo'd or renamed key in one of the
  `_defaultXxxCategories` tables would silently display as a raw internal key string instead of
  throwing — this can only happen if those tables are hand-edited, since every key currently in them
  has a matching case here.

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **Kind:** method of `_CategoryDialogState`
- **Source:** `lib/features/finance/views/categories_page.dart` (line 700)
- **Purpose:** Tell `UnsavedChangesGuard`
  ([`../../../shared/widgets/unsaved_changes_guard.md`](../../../shared/widgets/unsaved_changes_guard.md))
  whether the form has diverged from its initial state.
- **Inputs:** None (reads instance state only).
- **Returns:** `bool` — `true` if the current signature differs from `_initialSignature`.
- **Side effects:** None.
- **Algorithm:** Compare [`_signature()`](#signature) against `_initialSignature`, captured once at
  the end of `initState`.
- **Usage:**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **Notes:** Passed as a tear-off, so it is re-evaluated on every pop attempt rather than cached.

### `String _signature()` <a id="signature"></a>
- **Kind:** method of `_CategoryDialogState`
- **Source:** `lib/features/finance/views/categories_page.dart` (lines 707-712)
- **Purpose:** Produce a single string that changes if and only if the category's name, icon, or
  emoji has changed, for use as the dirty-check baseline/comparison.
- **Inputs:** None (reads instance state only).
- **Returns:** `String` — the joined signature from `formSignature`
  (`../../../shared/widgets/unsaved_changes_guard.md`).
- **Side effects:** None.
- **Algorithm:** Delegate to
  `formSignature([_nameController.text.trim(), _selectedIcon.codePoint, _selectedIcon.fontFamily, _selectedEmoji])`.
- **Usage:**
  ```dart
  _initialSignature = _signature();
  // ...
  bool _hasUnsavedChanges() => _signature() != _initialSignature;
  ```
- **Notes:** None.

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **Kind:** method of `_CategoryDialogState`
- **Source:** `lib/features/finance/views/categories_page.dart` (lines 719-734)
- **Purpose:** Validate the name field and, if non-empty, construct a
  [`Category`](../models/finance.md#category-new) (preserving the original id when editing) and pop
  the dialog with it.
- **Inputs:** `guard` — the `UnsavedChangesController` supplied by `UnsavedChangesGuard.builder`.
- **Returns:** None.
- **Side effects:** Pops the route (via `guard.pop`) with a result, only when the name is non-empty.
- **Algorithm:**
  1. Trim the name field; return silently if it's empty.
  2. Build a `Category`, passing `id: widget.category?.id` so editing an existing category keeps its
     id (a `null` id when adding lets `Category`'s constructor generate a fresh one); `icon` is a new
     `IconRef` from `_selectedIcon`'s code point and font family (defaulting to `'MaterialIcons'` if
     the icon's own `fontFamily` is null); `emoji` and `type` are copied from `_selectedEmoji`/
     `widget.type`.
  3. Pop with the result via `guard.pop(category)`.
- **Usage:**
  ```dart
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(isEditing ? l10n.commonSave : l10n.commonAdd),
  ),
  ```
- **Notes:** Validation only checks that the name isn't empty — there's no uniqueness check against
  existing category names, so two categories with identical names can coexist.

## Related pages

- [Finance](../../../../features/finance.md) — `Category`/`IconRef` model fields and the
  `--no-tree-shake-icons` release-build requirement these dynamically-reconstructed icons impose.
- [`finance.md` model doc](../models/finance.md) — `Category`, `IconRef`, and their
  `toJson`/`fromJson`/`toIconData` methods.
- [`category_detail_page.dart`](category_detail_page.md) — the drill-down page `_openCategoryDetail`
  pushes.
- [`unsaved_changes_guard.dart`](../../../shared/widgets/unsaved_changes_guard.md) — the shared
  dirty-check/discard-confirmation pattern used by `_CategoryDialog`.

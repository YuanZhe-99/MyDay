# lib/shared/widgets/delete_confirm.dart

A single reusable delete-confirmation flow (`confirmDelete`) with a "don't ask for 5 minutes"
opt-out, used by every feature's delete actions (Todo tasks, Finance accounts/categories,
Intimacy partners/toys, Weight records, etc.).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`confirmDelete`](#confirmdelete) | top-level function | A | Confirm delete via dialog, honoring a temporary "don't ask" suppression. |

`grep -c 'Purpose:' lib/shared/widgets/delete_confirm.dart` reports 1, matching the single real
declaration in this file. The module-level `_suppressUntil` variable is a plain mutable field (not
a function/method/constructor/getter/setter) and is not counted as a separate declaration; it is
documented in prose above its definition (`/// Global "don't ask" state...`) rather than with a
`Purpose:` block.

## Documentation

### `Future<bool> confirmDelete(BuildContext context, String itemLabel)` <a id="confirmdelete"></a>
- **Kind:** top-level async function
- **Source:** `lib/shared/widgets/delete_confirm.dart` (line 16)
- **Purpose:** Show a delete-confirmation dialog (with an optional "don't ask for 5 minutes"
  checkbox) and return whether the caller should proceed with deletion.
- **Inputs:** `context` (for the dialog and localization); `itemLabel` — plain text describing the
  item, interpolated into the confirmation message.
- **Returns:** `Future<bool>` — `true` if deletion should proceed, `false` to cancel.
- **Side effects:** If suppression is not active, shows a modal `AlertDialog`
  (`showDialog<bool>`) with a `StatefulBuilder`-managed checkbox. If the user confirms with the
  checkbox checked, sets the module-level `_suppressUntil` to `DateTime.now() + 5 minutes`.
- **Algorithm:**
  1. If `_suppressUntil` is set and still in the future, return `true` immediately without showing
     any UI.
  2. Otherwise show an `AlertDialog` with a title (`commonDelete` or fallback `'Confirm Delete'`),
     a message built from `commonDeleteConfirm(itemLabel)` (or fallback `'Delete $itemLabel?'`),
     and a checkbox row bound to local `dontAsk` state via `StatefulBuilder`.
  3. "Cancel" pops `false`; the filled "Delete" button (styled with the theme's error color) pops
     `true`.
  4. If the dialog result is `true` and `dontAsk` was checked, set `_suppressUntil` to 5 minutes
     from now.
  5. Return the dialog result, defaulting to `false` if the dialog was dismissed (e.g. back
     button/barrier tap) without an explicit choice.
- **Usage:**
  ```dart
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.startToEnd) {
      widget.onEdit?.call();
      return false;
    }
    return confirmDelete(context, AppLocalizations.of(context)!.todoThisTask);
  },
  ```
  (`lib/features/todo/widgets/task_section.dart`, swipe-to-delete on a task tile.)
- **Notes:** `_suppressUntil` is a single process-wide (not per-item) suppression window — checking
  "don't ask" once suppresses *every* subsequent `confirmDelete` call anywhere in the app for 5
  minutes, not just the same item type. There is no way to re-arm it early short of waiting out the
  window or restarting the app.

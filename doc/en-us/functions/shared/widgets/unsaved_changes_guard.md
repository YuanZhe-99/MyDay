# lib/shared/widgets/unsaved_changes_guard.dart

The shared "discard unsaved changes?" pattern used by every edit dialog/form in the app (Todo
add/edit task, Finance accounts/categories/subscriptions/exchange rates, Intimacy add-record,
Weight edit record). `UnsavedChangesGuard` wraps a `PopScope` and exposes an
`UnsavedChangesController` so the wrapped builder can trigger its own pop through the same
discard-confirmation path. `formSignature`/`_formValueSignature` build a comparable string
snapshot of a form's field values so callers can detect "has anything actually changed" by
comparing an initial signature to the current one.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `maybeDiscardAndPop` (abstract) | method (`UnsavedChangesController`) | B | Confirm whether pending changes can be discarded before popping. |
| `pop` (abstract) | method (`UnsavedChangesController`) | B | Pop the route (contract declaration). |
| `UnsavedChangesGuard` (constructor) | constructor (`UnsavedChangesGuard`) | B | Create an unsaved changes guard instance. |
| `createState` | method (`UnsavedChangesGuard`) | B | Create the mutable state object for this widget. |
| `build` | method (`_UnsavedChangesGuardState`) | B | Build the `PopScope`-wrapped subtree. |
| [`maybeDiscardAndPop`](#maybediscardandpop) | method (`_UnsavedChangesGuardState`) | A | Show a discard-confirmation dialog when needed, then pop. |
| [`pop`](#pop) | method (`_UnsavedChangesGuardState`) | A | Allow the next pop and perform it on the following frame. |
| [`showDiscardChangesDialog`](#showdiscardchangesdialog) | top-level function | A | Show the shared discard-changes confirmation dialog. |
| [`formSignature`](#formsignature) | top-level function | A | Build a comparable signature string from a form's field values. |
| [`_formValueSignature`](#_formvaluesignature) | top-level function | A | Serialize one form field value into a signature fragment. |

`grep -c 'Purpose:' lib/shared/widgets/unsaved_changes_guard.dart` reports 10, matching all ten
real declarations in this file. No misattachment or undocumented declarations found. The two
abstract `UnsavedChangesController` methods are classified Tier B here because they carry no
implementation of their own — the real logic lives in `_UnsavedChangesGuardState`'s concrete
overrides, documented below as Tier A. `showDiscardChangesDialog` and `formSignature` are also
Tier A per the "all top-level functions under `shared/`" rule even though they are short, since
this file lives under `shared/widgets/`.

## Documentation

### `Future<bool> maybeDiscardAndPop<T extends Object?>([T? result])` (concrete override) <a id="maybediscardandpop"></a>
- **Kind:** method of `_UnsavedChangesGuardState` (implements `UnsavedChangesController`)
- **Source:** `lib/shared/widgets/unsaved_changes_guard.dart` (line 75)
- **Purpose:** Decide whether the guarded route can be popped now, showing a discard-confirmation
  dialog only when there are unsaved changes.
- **Inputs:** `result` — the value to pass through to `Navigator.pop` if the pop proceeds.
- **Returns:** `Future<bool>` — `true` if the route was actually popped, `false` otherwise.
- **Side effects:** May show the discard-confirmation dialog (`showDiscardChangesDialog`); may
  call `pop(result)`.
- **Algorithm:**
  1. If already `_closing` or `_confirming`, return `false` immediately (re-entrancy guard).
  2. If `widget.hasUnsavedChanges()` is `false`, call `pop(result)` and return `true` — no dialog
     needed.
  3. Otherwise set `_confirming = true`, await `showDiscardChangesDialog(context)`, then clear
     `_confirming`.
  4. If the widget was unmounted while awaiting, or the dialog result was not exactly `true`,
     return `false` without popping.
  5. Otherwise call `pop(result)` and return `true`.
- **Usage:**
  ```dart
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    maybeDiscardAndPop(result);
  },
  ```
  (same file, `_UnsavedChangesGuardState.build`, wired to `PopScope`.)
- **Notes:** Implementations should return whether the route was actually popped — callers that
  invoke this directly (e.g. a dialog's own "Cancel" button) rely on the boolean to decide whether
  to also run their own follow-up logic.

### `void pop<T extends Object?>([T? result])` (concrete override) <a id="pop"></a>
- **Kind:** method of `_UnsavedChangesGuardState` (implements `UnsavedChangesController`)
- **Source:** `lib/shared/widgets/unsaved_changes_guard.dart` (line 97)
- **Purpose:** Allow the guarded `PopScope` to pop, then perform the actual `Navigator.pop` on the
  next frame.
- **Inputs:** `result`.
- **Returns:** None.
- **Side effects:** Sets `_closing = true`; calls `setState(() => _allowPop = true)`; schedules a
  post-frame callback that calls `Navigator.of(context).pop<T>(result)`.
- **Algorithm:**
  1. If already `_closing` or not `mounted`, return immediately (idempotency guard).
  2. Set `_closing = true` and `setState(() => _allowPop = true)` so `PopScope.canPop` becomes
     `true` on rebuild.
  3. Register `WidgetsBinding.instance.addPostFrameCallback` to call `Navigator.of(context).pop`
     after the frame in which `canPop` became `true` has been laid out, guarded by another
     `mounted` check.
- **Usage:** Called by dialogs' own save buttons via the `guard` parameter passed into
  `UnsavedChangesGuard`'s `builder`, e.g. `guard.pop(savedValue)` after a successful save, and
  internally by `maybeDiscardAndPop` when discarding.
- **Notes:** The one-frame delay (`_allowPop` set now, actual `Navigator.pop` deferred to the next
  frame) exists so `PopScope.canPop` has already flipped to `true` by the time the real pop is
  attempted — popping in the same frame `canPop` changes can otherwise be swallowed by `PopScope`.

### `Future<bool> showDiscardChangesDialog(BuildContext context)` <a id="showdiscardchangesdialog"></a>
- **Kind:** top-level async function
- **Source:** `lib/shared/widgets/unsaved_changes_guard.dart` (line 113)
- **Purpose:** Show the shared "Discard changes?" confirmation dialog.
- **Inputs:** `context`.
- **Returns:** `Future<bool>` — `true` if the user chose Discard, `false` otherwise (Cancel or
  dismissal).
- **Side effects:** Shows a modal `AlertDialog` via `showDialog<bool>`.
- **Algorithm:** Build an `AlertDialog` with localized title/message
  (`commonDiscardChangesTitle`/`commonDiscardChangesMessage`); Cancel pops `false`; a filled,
  error-colored Discard button pops `true`; return the result or `false` if null.
- **Usage:** Called internally by `_UnsavedChangesGuardState.maybeDiscardAndPop`; also usable
  directly by any screen that needs the same confirmation outside the guard widget.
- **Notes:** None.

### `String formSignature(Iterable<Object?> values)` <a id="formsignature"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/widgets/unsaved_changes_guard.dart` (line 145)
- **Purpose:** Build a single comparable string from a form's current field values, so a caller can
  detect edits by comparing an initial signature to a later one.
- **Inputs:** `values` — an ordered iterable of the form's field values (typically controller text,
  dates, enums, and nested lists).
- **Returns:** `String` — each value's signature joined with the `` (unit separator)
  control character.
- **Side effects:** None.
- **Algorithm:** `values.map(_formValueSignature).join('')`.
- **Usage:**
  ```dart
  String _signature() => formSignature([
    _titleController.text.trim(),
    _noteController.text.trim(),
    _subtaskController.text.trim(),
    _selectedType.name,
    _reminderTime,
    _selectedEmoji,
    _scheduledDate,
    _dueDate,
    _recurrenceSignature(_recurrence),
    _subtaskTitles,
  ]);
  ```
  (`lib/features/todo/widgets/add_task_dialog.dart`, `_signature`, feeding
  `hasUnsavedChanges: () => _signature() != _initialSignature` style checks used by
  `UnsavedChangesGuard` call sites across Todo/Finance/Intimacy/Weight dialogs.)
- **Notes:** The choice of control-character separators (here and in `_formValueSignature`) avoids
  ambiguity with ordinary user-entered text that might contain commas, colons, or other
  human-typed punctuation.

### `String _formValueSignature(Object? value)` <a id="_formvaluesignature"></a>
- **Kind:** top-level private function
- **Source:** `lib/shared/widgets/unsaved_changes_guard.dart` (line 153)
- **Purpose:** Serialize one field value into a stable string fragment for `formSignature`.
- **Inputs:** `value` — `null`, `DateTime`, `TimeOfDay`, `Iterable`, `Map`, or anything with a
  usable `toString()`.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:**
  1. `null` → `''`.
  2. `DateTime` → `toIso8601String()`.
  3. `TimeOfDay` → `'$hour:$minute'`.
  4. `Iterable` → recursively map each element through `_formValueSignature` and join with
     `` (record separator).
  5. `Map` → sort entries by key (`toString()` comparison), then join `'key:value'` pairs (value
     recursively serialized) with `` (group separator).
  6. Anything else → `value.toString()`.
- **Usage:** Called only from `formSignature`'s `.map(...)`.
- **Notes:** `Map` entries are sorted by key before joining specifically so signature comparison is
  insertion-order-independent — two maps with the same key/value pairs in different insertion
  orders produce the same signature.

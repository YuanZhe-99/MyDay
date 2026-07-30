# lib/shared/providers/intimacy_visibility.dart

Riverpod state for whether the Intimacy tab/module is visible. The toggle always exists in
Settings; turning it off hides the tab but never deletes `intimacy_data.json`. Consumed by
`ShellScaffold` (`shared/widgets/shell_scaffold.dart`) to decide which bottom-nav destinations to
show, and by the Settings page to render/persist the toggle. See
[../../../architecture.md#state-management](../../../architecture.md#state-management).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`IntimacyVisibility` (constructor)](#intimacyvisibility-new) | constructor (`IntimacyVisibility`) | A | Create an intimacy visibility value. |
| [`copyWith`](#copywith) | method (`IntimacyVisibility`) | A | Create a copy of this value with selected fields replaced. |
| [`IntimacyVisibilityNotifier` (constructor)](#intimacyvisibilitynotifier-new) | constructor (`IntimacyVisibilityNotifier`) | A | Start the notifier and kick off loading persisted visibility. |
| [`_loadPersistedState`](#_loadpersistedstate) | method (`IntimacyVisibilityNotifier`) | A | Load persisted visibility from `TodoStorage` into state. |
| [`setVisible`](#setvisible) | method (`IntimacyVisibilityNotifier`) | A | Toggle visibility from Settings and persist it. |
| `intimacyVisibilityProvider` | top-level variable (`StateNotifierProvider`) | B | Expose `IntimacyVisibilityNotifier` to the widget tree. |

`grep -c 'Purpose:' lib/shared/providers/intimacy_visibility.dart` reports 5, matching the five
`Purpose:`-documented declarations above. The sixth row, `intimacyVisibilityProvider`, is a real
top-level declaration with **no** doc block at all (undocumented, not misattached) — it is a
one-line `StateNotifierProvider<IntimacyVisibilityNotifier, IntimacyVisibility>((ref) =>
IntimacyVisibilityNotifier())` factory, trivial enough to classify Tier B despite being
undocumented.

**Reconciliation:** `grep -c 'Purpose:' lib/shared/providers/intimacy_visibility.dart` reports 5, matching 5 of the 6 rows above exactly. The extra row is `intimacyVisibilityProvider`, the `StateNotifierProvider` top-level variable: no `Purpose:` block, but it is the file's public entry point.

## Documentation

### `const IntimacyVisibility({this.visible = false})` <a id="intimacyvisibility-new"></a>
- **Kind:** const constructor of `IntimacyVisibility`
- **Source:** `lib/shared/providers/intimacy_visibility.dart` (line 18)
- **Purpose:** Create an immutable visibility value, defaulting to hidden.
- **Inputs:** `visible` (optional, default `false`).
- **Returns:** A new `IntimacyVisibility` instance.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** `const IntimacyVisibility()` is the initial state passed to
  `StateNotifier`'s constructor in `IntimacyVisibilityNotifier`.
- **Notes:** Default OFF matches the documented behavior for new installs; existing data causes
  `_loadPersistedState` to override this default to `true` shortly after construction.

### `IntimacyVisibility copyWith({bool? visible})` <a id="copywith"></a>
- **Kind:** method of `IntimacyVisibility`
- **Source:** `lib/shared/providers/intimacy_visibility.dart` (line 25)
- **Purpose:** Create a copy of this value with `visible` optionally replaced.
- **Inputs:** `visible` (optional; falls back to `this.visible` when omitted).
- **Returns:** A new `IntimacyVisibility`.
- **Side effects:** None.
- **Algorithm:** `IntimacyVisibility(visible: visible ?? this.visible)`.
- **Usage:** `state = state.copyWith(visible: visible);` (`setVisible`, same file).
- **Notes:** None.

### `IntimacyVisibilityNotifier() : super(const IntimacyVisibility())` <a id="intimacyvisibilitynotifier-new"></a>
- **Kind:** constructor of `IntimacyVisibilityNotifier` (extends `StateNotifier<IntimacyVisibility>`)
- **Source:** `lib/shared/providers/intimacy_visibility.dart` (line 36)
- **Purpose:** Initialize the notifier with the default hidden state, then start loading the
  persisted value asynchronously.
- **Inputs:** None.
- **Returns:** A new `IntimacyVisibilityNotifier`.
- **Side effects:** Calls `_loadPersistedState()` (fire-and-forget) immediately after `super(...)`.
- **Algorithm:** Initialize `state` to `const IntimacyVisibility()` (hidden), then invoke
  `_loadPersistedState()` without awaiting it.
- **Usage:** Instantiated only by `intimacyVisibilityProvider`'s factory:
  `StateNotifierProvider<IntimacyVisibilityNotifier, IntimacyVisibility>((ref) =>
  IntimacyVisibilityNotifier())`.
- **Notes:** Any `ref.watch(intimacyVisibilityProvider)` read before the async load resolves sees
  the hidden default, not the persisted value.

### `Future<void> _loadPersistedState()` <a id="_loadpersistedstate"></a>
- **Kind:** private method of `IntimacyVisibilityNotifier`
- **Source:** `lib/shared/providers/intimacy_visibility.dart` (line 45)
- **Purpose:** Read the persisted intimacy-visible flag and apply it to state.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads `TodoStorage.getIntimacyVisible()`; overwrites `state` with a new
  `IntimacyVisibility(visible: visible)`.
- **Algorithm:** `await TodoStorage.getIntimacyVisible()`, then set `state`.
- **Usage:** Called once, from the constructor, never directly by feature code.
- **Notes:** Overwrites the whole state object rather than using `copyWith`, but the effect is
  identical since `IntimacyVisibility` has only the one field.

### `void setVisible(bool visible)` <a id="setvisible"></a>
- **Kind:** method of `IntimacyVisibilityNotifier`
- **Source:** `lib/shared/providers/intimacy_visibility.dart` (line 56)
- **Purpose:** Toggle intimacy-module visibility from the Settings page and persist the choice.
- **Inputs:** `visible`.
- **Returns:** None.
- **Side effects:** Updates `state` via `copyWith`; calls `TodoStorage.setIntimacyVisible(visible)`
  (fire-and-forget, not awaited).
- **Algorithm:** `state = state.copyWith(visible: visible); TodoStorage.setIntimacyVisible(visible);`
- **Usage:**
  ```dart
  ref.read(intimacyVisibilityProvider.notifier).setVisible(value);
  ```
  (`lib/features/settings/views/settings_page.dart`, the Intimacy toggle's `onChanged`, after the
  page's own confirm-hide dialog when turning the toggle off.)
- **Notes:** Does not delete `intimacy_data.json` or any intimacy records; it only flips a UI
  visibility flag consumed by `ShellScaffold`.

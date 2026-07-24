# lib/shared/services/sync_progress.dart

Defines the value type `WebDAVService.progress` publishes: `SyncPhase` (an enum of sync stages)
and `SyncProgress` (an immutable snapshot with optional detail/current/total). UI pages bind a
`ValueListenableBuilder<SyncProgress>` to render phase text and a `LinearProgressIndicator`. See
[../../../sync.md#retry-heartbeat-and-wake-lock](../../../sync.md#retry-heartbeat-and-wake-lock)
("Progress" bullet) for how `WebDAVService` emits these values.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`SyncProgress` (constructor)](#syncprogress-new) | constructor (`SyncProgress`) | A | Create an immutable sync progress snapshot. |
| [`fraction`](#fraction) | getter (`SyncProgress`) | A | Return the completed fraction of the current phase. |
| [`isRunning`](#isrunning) | getter (`SyncProgress`) | A | Return whether a sync/force operation is currently running. |
| [`SyncProgressListenable`](#syncprogresslistenable) | typedef | B | Expose a `ValueListenable` type alias for sync progress consumers. |

`grep -c 'Purpose:' lib/shared/services/sync_progress.dart` reports 4, matching all four
`Purpose:`-documented declarations. The `SyncPhase` enum, the `SyncProgress` class itself, and the
`static const idle = SyncProgress(SyncPhase.idle)` field carry plain `///` doc comments (not the
`Purpose:` block format) and are not separately counted — they are data/type declarations, not
functions/methods/constructors/getters/setters in their own right. No misattachment was found: all
four blocks sit directly above the declaration they describe.

## Documentation

### `const SyncProgress(this.phase, {this.detail, this.current = 0, this.total = 0})` <a id="syncprogress-new"></a>
- **Kind:** const constructor of `SyncProgress`
- **Source:** `lib/shared/services/sync_progress.dart` (line 38)
- **Purpose:** Create an immutable snapshot of one sync phase's progress.
- **Inputs:** `phase` (required `SyncPhase`); `detail` (optional raw file/image name or error
  text); `current`/`total` (1-based index and total count, both default `0`).
- **Returns:** A new `SyncProgress` instance.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor; no computation.
- **Usage:**
  ```dart
  static const idle = SyncProgress(SyncPhase.idle);
  ```
  (same file, the `idle` resting-state constant) — `WebDAVService` constructs non-idle instances
  as it moves through `connecting`/`downloadingData`/`merging`/`uploadingData`/`uploadingImages`/
  `downloadingImages`/`done`/`error`.
- **Notes:** `total == 0` is the documented sentinel for "phase has no measurable item count" and
  is read by `fraction` below.

### `double? get fraction` <a id="fraction"></a>
- **Kind:** getter of `SyncProgress`
- **Source:** `lib/shared/services/sync_progress.dart` (line 53)
- **Purpose:** Return the completed fraction of the current phase, for binding to a progress bar.
- **Inputs:** None (reads `current`/`total`).
- **Returns:** `double?` — `current / total` clamped to `0.0..1.0`, or `null` when `total <= 0`.
- **Side effects:** None.
- **Algorithm:** `total > 0 ? (current / total).clamp(0.0, 1.0).toDouble() : null`.
- **Usage:** Intended to bind directly to `LinearProgressIndicator.value` (a `null` value renders
  an indeterminate spinner/bar).
- **Notes:** No divide-by-zero risk since the ternary guards `total > 0` before dividing.

### `bool get isRunning` <a id="isrunning"></a>
- **Kind:** getter of `SyncProgress`
- **Source:** `lib/shared/services/sync_progress.dart` (line 61)
- **Purpose:** Report whether a sync or force upload/download is currently in flight.
- **Inputs:** None (reads `phase`).
- **Returns:** `bool` — `true` unless `phase` is `idle`, `done`, or `error`.
- **Side effects:** None.
- **Algorithm:** `phase != SyncPhase.idle && phase != SyncPhase.done && phase != SyncPhase.error`.
- **Usage:** UI code can gate "sync in progress" spinners/disabled buttons on
  `progress.value.isRunning`.
- **Notes:** `done` and `error` are explicitly terminal states, not "running" — callers must treat
  them like `idle` for enabling/disabling controls.

### `typedef SyncProgressListenable = ValueListenable<SyncProgress>` <a id="syncprogresslistenable"></a>
Tier B — index row only. Gives sync-progress consumers a named alias for
`ValueListenable<SyncProgress>` instead of spelling out the generic every time; UI pages use
`ValueListenableBuilder<SyncProgress>` bound to `WebDAVService.progress`.

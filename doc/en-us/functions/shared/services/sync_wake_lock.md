# lib/shared/services/sync_wake_lock.dart

Reference-counted, ownership-tracked wrapper around `wakelock_plus` that keeps the screen/device
awake while a foreground WebDAV sync or force operation runs. See
[../../../sync.md#retry-heartbeat-and-wake-lock](../../../sync.md#retry-heartbeat-and-wake-lock)
("Wake lock" bullet) for how this fits the sync flow, and note it is intentionally never used by
background auto-sync.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`SyncWakeLock`](#syncwakelock) | class | A | Keep the device/screen awake while a foreground sync operation is running. |
| `SyncWakeLock._()` | constructor (`SyncWakeLock`) | B | Prevent instantiation; this class only has static members. |
| [`acquire`](#acquire) | static method (`SyncWakeLock`) | A | Acquire the sync wake lock for one foreground operation. |
| [`release`](#release) | static method (`SyncWakeLock`) | A | Release the sync wake lock for one foreground operation. |

`grep -c 'Purpose:' lib/shared/services/sync_wake_lock.dart` reports 4, matching all four real
declarations. One of the four blocks (lines 3-13) documents the `SyncWakeLock` class itself rather
than a method — this is a legitimate class-level doc block, not a misattachment (it sits directly
above `class SyncWakeLock {`), so it is listed here as its own Tier A row since it is the only
place the reference-counting/ownership-tracking contract is written down.

## Documentation

### `class SyncWakeLock` <a id="syncwakelock"></a>
- **Kind:** class (static-only namespace)
- **Source:** `lib/shared/services/sync_wake_lock.dart` (line 14)
- **Purpose:** Keep the device/screen awake while a foreground sync operation (manual sync,
  conflict finalize, force upload/download) is running.
- **Inputs:** N/A (namespace class; see `acquire`/`release`).
- **Returns:** N/A.
- **Side effects:** Enables/disables the platform wake lock through `wakelock_plus`, mediated by
  the two static methods below.
- **Algorithm:** N/A at the class level — see `acquire`/`release`.
- **Usage:** N/A — call the static methods directly, e.g. `SyncWakeLock.acquire()`.
- **Notes:** Reference-counted so overlapping foreground operations (e.g. sync immediately followed
  by a conflict finalize) share one lock. Ownership-tracked via `_enabledBySync` so `release()`
  never disables a wake lock some other feature (for example the intimacy timer's page-held lock)
  enabled first. Background auto-sync must never use this class. Every plugin call is wrapped in a
  swallowed `catch` so a wake-lock failure can never break a sync operation.

### `static Future<void> acquire()` <a id="acquire"></a>
- **Kind:** static method of `SyncWakeLock`
- **Source:** `lib/shared/services/sync_wake_lock.dart` (line 33)
- **Purpose:** Acquire the sync wake lock for one foreground operation.
- **Inputs:** None.
- **Returns:** `Future<void>` completing once the wake lock state is applied.
- **Side effects:** On the first concurrent acquire (`_refCount` going 0→1), checks
  `WakelockPlus.enabled` and calls `WakelockPlus.enable()` only if not already enabled by someone
  else, recording `_enabledBySync = true` in that case.
- **Algorithm:**
  1. Increment `_refCount`.
  2. If this was not the first acquire (`_refCount > 1`), return immediately — the lock is already
     held for this or another overlapping operation.
  3. Otherwise, read `WakelockPlus.enabled`; if it is `false`, call `WakelockPlus.enable()` and set
     `_enabledBySync = true` so `release()` knows it is responsible for disabling it later.
  4. Any plugin exception is caught and silently ignored.
- **Usage:**
  ```dart
  setState(() => _syncing = true);
  await SyncWakeLock.acquire();
  SyncResult result;
  try {
    result = await WebDAVService.sync(_currentConfig);
  } finally {
    await SyncWakeLock.release();
    if (mounted) setState(() => _syncing = false);
  }
  ```
  (`lib/shared/views/webdav_config_page.dart`, `_syncNow`.)
- **Notes:** Always pair with `release()` inside a `finally` block so completion, failure,
  cancellation, and exceptions all release the lock — every call site in the repo follows this
  pattern.

### `static Future<void> release()` <a id="release"></a>
- **Kind:** static method of `SyncWakeLock`
- **Source:** `lib/shared/services/sync_wake_lock.dart` (line 53)
- **Purpose:** Release the sync wake lock for one foreground operation.
- **Inputs:** None.
- **Returns:** `Future<void>` completing once the wake lock state is applied.
- **Side effects:** On the last concurrent release (`_refCount` reaching 0), disables the platform
  wake lock via `WakelockPlus.disable()` — but only if `acquire()` was the one that enabled it
  (`_enabledBySync == true`).
- **Algorithm:**
  1. If `_refCount == 0`, return immediately (nothing held; safe no-op).
  2. Decrement `_refCount`.
  3. If other acquires are still outstanding (`_refCount > 0`) or this class never enabled the lock
     itself (`!_enabledBySync`), return without touching the plugin.
  4. Otherwise, clear `_enabledBySync` and call `WakelockPlus.disable()`, swallowing any exception.
- **Usage:** See `acquire()` above — always called in the matching `finally` block.
- **Notes:** Safe to call when nothing is held (guarded by the `_refCount == 0` early return).

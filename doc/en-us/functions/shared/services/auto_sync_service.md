# lib/shared/services/auto_sync_service.dart

**Facade over the shared scheduler.** The lifecycle observer, 30-second save debounce, 15-minute
periodic timer, in-flight guard, and status bookkeeping moved to the `myapps_data` package
(`lib/src/sync/auto_sync_scheduler.dart`). MyDay's differences stay here as hooks.

## Hooks this app supplies

| Hook | Value |
|---|---|
| `isAutoSyncActive` | Config exists, is configured, and has `autoSync` enabled. |
| `runSync` | `WebDAVService.sync(config)` — never with `autoResolve`. |
| `consumeLocalDataChanged` | `WebDAVService.consumeLocalDataChanged`. |
| `onPeriodicTick` | **`null` — deliberately.** |
| `onResume` | `ReminderService.instance.refreshMobileSchedules()`. |

**The null periodic hook is load-bearing.** MyDay's daily backup is driven by `ReminderService`'s
30-second loop, not by this scheduler — unlike MyAnime and MyDevice, which run
`BackupService.runAutoBackupIfNeeded` on the periodic tick. Do not "unify" this: wiring the backup in
here would double-drive it.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `instance` | static field | A | The singleton. |
| `lastSuccessAt` / `lastFailureAt` / `lastError` / `hasPendingConflicts` | getters | A | In-memory sync status for the settings UI. |
| `addOnLocalDataChanged` / `removeOnLocalDataChanged` | methods | A | Register and remove UI reload callbacks. |
| `addOnStatusChanged` / `removeOnStatusChanged` | methods | A | Register and remove status-change callbacks. |
| `recordSyncResult(result)` | method | A | Record a manually triggered sync into the same status path. |
| `recordFinalizeResult(ok)` | method | A | Record a conflict finalization. |
| `notifyLocalDataChangedIfNeeded()` | method | A | Fire reload callbacks **if** the engine flag is set. |
| `notifyLocalDataChangedNow()` | method | A | Fire reload callbacks unconditionally (restore, ZIP import). |
| `start()` / `stop()` | methods | A | Begin and end observing lifecycle and running timers. |
| `notifySaved()` | method | A | Storage hook: restart the 30-second debounce. |
| `requestSyncNow()` | method | A | Cancel any pending debounce and sync immediately. |

**Reconciliation:** this is a **grouped** page — 11 rows above cover the file's 18 `/// Purpose:`
declarations, because the four status getters share one row and each
`add…`/`remove…` callback pair and the `start()`/`stop()` pair share a row.
[INDEX.md](../../INDEX.md) counts rows, not underlying declarations, so it lists 11. This page has
no `## Documentation` section by design: the facade's behavior is documented at the scheduler it
wraps (see below).

## Notes

- Status is in-memory only and is never persisted.
- Auto-sync leaves `autoResolve` disabled: true two-sided conflicts are recorded as visible pending
  status rather than silently applying last-writer-wins.
- Overlapping triggers are silently skipped by the in-flight guard.
- `notifySaved()` is ignored before `start()`.
- On resume, mobile reminder schedules are refreshed so per-day notification bodies are recomputed
  from current data after suspension.

## Where the scheduler documentation lives

`packages/myapps_data/doc/en-us/functions/src/sync/auto_sync_scheduler.md`.

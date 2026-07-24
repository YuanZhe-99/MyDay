# WebDAV Sync

WebDAV sync is per-record three-way merge, not whole-file replacement. The engine behind the merge
step is documented separately in [Three-Way Merge](algorithms/three-way-merge.md); this page covers
the end-to-end flow, retry/heartbeat/wake-lock behavior, per-file error handling, and auto-sync
triggers. Primary source: the "WebDAV Sync" section of `AGENTS.md`, cross-checked against
`lib/shared/services/webdav_service.dart` and `lib/shared/services/sync_merge.dart`.

## The 10-step sync flow

1. **Acquire the remote `.lock`** before any data download, using the stable local client id, one
   upload token, a UTC timestamp, and a 60-second TTL. Active locks from another client block
   uploads; expired locks are treated as failed uploads and may be replaced. A local
   `.sync_base/upload_lock.json` file lets the next launch detect an interrupted upload and
   re-download/re-merge before uploading again.
2. **Download remote JSON** with a discriminated result: only HTTP 404 counts as "missing on
   remote"; any other failure (auth/server/network) records a per-file error and skips that file,
   so local data is never uploaded over an unreadable remote file. (This is the "per-file errors,
   not whole-sync abort" behavior — the same rule MyDevice uses; MyAnime differs slightly here.)
3. **Load local JSON** and the `.sync_base/` base snapshots (the last-synced versions used for
   three-way diffing).
4. **Merge per record** using `modifiedAt` where available. Records whose serialized content is
   identical on both sides merge without raising a conflict, even if both sides bumped
   `modifiedAt` (e.g. after a stale base caused by an earlier failed upload).
5. **Auto-resolve when only one side changed** — no conflict is raised in that case.
6. **Detect conflicts** when the same record changed on both sides since the last sync.
7. **Preserve unknown JSON fields** from base/local/remote so a newer app version's fields survive
   a round-trip through an older version or an unattended merge.
8. **If there are no record conflicts:** save merged local data, force-upload the complete merged
   JSON while `.lock` is still valid, and update the base snapshots. Data JSON PUTs do not use
   data-file `If-Match`/`If-None-Match` — `.lock` is the sole concurrency guard for data writes.
9. **If there are record conflicts:** return them to the user. After the user resolves them,
   `finalizePendingSync` reacquires `.lock` and force-uploads each complete resolved JSON.
10. **Clear the matching remote/local upload lock** after upload completion.

Manual sync uses `autoResolve: false` and shows `SyncConflictDialog`. Auto-sync also leaves
`autoResolve` disabled: it records failures and true two-sided conflicts as visible status in
Settings/WebDAV instead of silently applying last-writer-wins. The user must open the WebDAV page
and resolve conflicts manually — sync never quietly picks a winner for a genuine conflict.

## Per-file error handling (not whole-sync abort)

A single malformed or unreachable remote data file does not block sync of the other files:
per-file errors are accumulated across the run, and only that one file's sync is skipped for the
cycle. This matches MyDevice's behavior (MyAnime aborts differently) — see the sourcing note in
`AGENTS.md`'s WebDAV section.

## The cross-module mixed-resolutions-map safety rule

`finalizePendingSync` takes the mixed cross-module resolutions map **as-is** — it never bulk-casts
it to a single record type. Each merge result (`TodoMergeResult`, `FinanceMergeResult`,
`IntimacyMergeResult`, `WeightMergeResult` in `lib/shared/services/sync_merge.dart`) implements its
own `buildResolved(Map<String, dynamic> resolutions)`, which in turn calls a private
`_resolveList<T>` per record type. That helper looks up each conflict's resolution by id and
type-checks it individually, e.g. in `WeightMergeResult.buildResolved`:

```dart
for (final c in recordConflicts) {
  final resolved = resolutions[c.id];
  // Default to the local record when unresolved or mistyped so
  // conflicting records are never silently dropped.
  result.add(resolved is WeightRecord ? resolved : c.localRecord);
}
```

Because every module does its own `is T` check against the *same* shared `resolutions` map rather
than casting the whole map to `Map<String, T>`, a conflict resolution UI that resolves, say, a
Finance conflict and an Intimacy conflict in the same pass can populate one map and hand it to both
modules' `buildResolved` — each module only touches the entries whose values match its own type.
Before this rule existed, bulk-casting the mixed map crashed on cross-module conflicts. Unresolved
or mistyped entries default to the local record, so a conflicting record is never dropped. See
[Sync Walkthrough](examples/sync-walkthrough.md) for a worked example spanning Finance and
Intimacy conflicts in the same sync.

## Sync Data Reference

Reproduced from `AGENTS.md`:

| File | Merge function | Merge strategy |
| --- | --- | --- |
| `todo_data.json` | `mergeTodoData()` | Daily/one-time records by id + `modifiedAt`; daily log union; daily score LWW per date; settings LWW |
| `finance_data.json` | `mergeFinanceData()` | Accounts/categories/transactions/subscriptions by id + `modifiedAt`; settings LWW |
| `exchange_rates.json` | `mergeExchangeRateJson()` | Snapshot union; newer valid current snapshot wins (a current id that does not resolve to a snapshot is ignored); newer `lastFetchedAt` wins |
| `intimacy_data.json` | `mergeIntimacyData()` | Partners/toys/positions/records/cycleRecords by id + `modifiedAt` (partner `body` rides its partner record); timer history union by start; timer session LWW by `timerSessionModifiedAt`; `userBody` LWW by `userBodyModifiedAt`; settings LWW |
| `weight_data.json` | `mergeWeightData()` | Records by id + `modifiedAt`; height follows settings LWW (saving weight data bumps `settingsModifiedAt`, so clearing height syncs); reminder/settings LWW |
| `images/*` | `_syncImages()` | Additive bidirectional, but only for referenced images |

Files moved by `TodoStorage.setStoragePath()` are `todo_data.json`, `finance_data.json`,
`exchange_rates.json`, `intimacy_data.json`, `weight_data.json`, and `webdav_config.json`.
`storage_config.json` always stays in the default app directory. Directories such as `images/`,
`backups/`, and `.sync_base/` are not moved by that file list.

Full field-level merge semantics (including the generic `mergeRecords` three-way engine and the
`CycleRecord`/`DailyCompletionLog` deletion-vs-union rules) are in
[Three-Way Merge](algorithms/three-way-merge.md).

## Retry, heartbeat, and wake lock

- **`_syncing`** is a static guard that prevents concurrent sync runs.
- **Local files are re-read before write** to detect saves that happened during network I/O.
- **Per-file errors are accumulated** so one malformed data file does not block all files.
- **Data JSON uploads are complete-file force PUTs under `.lock`**; only `.lock` writes/deletes use
  ETag preconditions, and weak ETags are never used for those lock preconditions.
- **`WebDAVService.consumeLocalDataChanged()`** tells `AutoSyncService` to notify UI pages to
  reload after sync writes local files.
- **Image sync is reference-gated**: only images referenced in `finance_data.json` or
  `intimacy_data.json` are synced; orphan images are ignored. Individual image transfer failures
  are non-fatal warnings surfaced through `SyncResult.warnings`.
- Remote image directory listings return `null` on any failure; `_syncImages` then skips the image
  phase with a visible warning instead of treating the unknown remote state as empty (this
  previously caused every referenced image to be re-uploaded after a transient PROPFIND failure).
  Downloaded images set the local-data-changed flag so UI pages reload even when the data JSON
  itself did not change.
- **Retries:** transient network failures (socket/timeout/client errors and HTTP 5xx) are retried
  up to 2 extra times with 1s/2s backoff on data GET/PUT, byte GET/PUT, and PROPFIND listings.
  `.lock` writes are never retried, so a retried create-only PUT cannot misreport lock contention;
  4xx responses are never retried.
- **Heartbeat:** while a data or image PUT is in flight, the held `.lock` is heartbeat-refreshed
  every 20 seconds (`_withLockHeartbeat`), so a transfer slower than the 60-second lock TTL cannot
  let another client treat the lock as expired and upload concurrently. Heartbeat failures are
  swallowed and never abort the in-flight transfer.
- **Progress:** `WebDAVService.progress` is a `ValueNotifier<SyncProgress>` (`sync_progress.dart`)
  publishing connecting/downloading/merging/uploading phases with per-file and per-image counts.
  The service emits raw phases and file names only; the WebDAV page maps phases to localized text
  and renders a `LinearProgressIndicator`.
- **Force operations:** `WebDAVService.forceUpload()` overwrites remote data files and uploads
  referenced images without any merge or conflict check, under the remote `.lock`, then saves base
  snapshots. `WebDAVService.forceDownload()` replaces local data files (JSON-validated first, atomic
  writes) and downloads referenced images without merging, saves base snapshots, and sets the
  local-data-changed flag; it is download-only and takes no remote lock. Both share the `_syncing`
  guard and require a destructive-action confirmation dialog in the WebDAV page. After manual sync
  or force operations the WebDAV page calls `AutoSyncService.notifyLocalDataChangedIfNeeded()` so
  open pages reload without waiting for the next background sync.
- **Wake lock:** foreground sync operations on the WebDAV page (manual sync, conflict finalize
  upload, force upload, force download) hold a screen wake lock through
  `shared/services/sync_wake_lock.dart` (`wakelock_plus`). The lock is reference-counted, only
  enabled if no other feature already holds one (so it never turns off the intimacy timer's
  page-held lock), acquired only after force-action confirmation, released in `finally` on
  completion/failure/cancel/exception, and never used by background auto-sync.

## Auto-sync triggers

`AutoSyncService` is a singleton `WidgetsBindingObserver` with triggers aligned with MyAnime and
MyDevice:

- **App start:** immediate sync.
- **App resume:** immediate sync (also refreshes mobile reminder schedules).
- **Data save:** 30-second debounce after `notifySaved()`.
- **Periodic timer:** every 15 minutes while the process is alive.
- **Saving/enabling a fully configured auto-sync WebDAV setup:** immediate sync via
  `requestSyncNow()`.

Auto-sync records the latest success, failure, or pending-conflict state in memory and surfaces it
in Settings and the WebDAV page. Failures are never silently swallowed; conflicts are never
auto-resolved by LWW in the background. `_trySync` holds an instance-level `_syncing` guard so
overlapping triggers (timer/resume/debounce) are silently skipped instead of surfacing a spurious
"Sync already in progress" failure banner. `notifySaved()` is ignored before `start()` so early
storage writes cannot schedule a sync before the service observes the app lifecycle.

## Related pages

- [Three-Way Merge](algorithms/three-way-merge.md) — the generic merge engine and per-file
  strategies in full detail.
- [Sync Walkthrough](examples/sync-walkthrough.md) — worked example of the mixed-resolutions-map
  rule across two conflicting modules.
- [Backup & Restore](backup-restore.md) — how restoring a backup interacts with auto-sync
  (disabled before the first file write, force-upload offer afterward).

# Three-Way Merge

Source: `lib/shared/services/sync_merge.dart`. This page documents the generic `mergeRecords`
engine and how each of the five data files uses it. See [WebDAV Sync](../sync.md) for where this
fits in the overall sync flow and the cross-module mixed-resolutions-map safety rule.

## The generic `mergeRecords<T>` engine

```dart
RecordMergeResult<T> mergeRecords<T>({
  required List<T> local,
  required List<T> remote,
  required List<T>? base,
  required String Function(T) getId,
  required DateTime Function(T) getModifiedAt,
  required String Function(T) getDisplayName,
  bool autoResolve = false,
  String Function(T)? serialize,
})
```

For every record id appearing in `local`, `remote`, or `base` (the last-synced snapshot), the three
sides are compared:

- **Both sides have the record, and a base exists (true three-way):**
  - `localChanged = local.modifiedAt.isAfter(base.modifiedAt)`,
    `remoteChanged = remote.modifiedAt.isAfter(base.modifiedAt)`.
  - **Only local changed** → use local. **Only remote changed** → use remote. **Neither changed**
    → use local (arbitrary but deterministic, since they're equivalent).
  - **Both changed:**
    - If `serialize` is provided and `serialize(local) == serialize(remote)` — i.e. the two sides
      ended up byte-identical even though both bumped `modifiedAt` (this can happen after a stale
      base left over from an earlier failed upload) — merge silently with no conflict.
    - Else if `autoResolve` is true (background auto-sync's conflict-avoidance mode) — last-writer-
      wins by `modifiedAt`.
    - Else — a genuine two-sided conflict, returned to the caller as a `RecordConflict<T>` for the
      user to resolve manually.
  - **No base exists** (first sync, or both sides independently created the same id) → last-writer-
    wins by `modifiedAt`.
- **Only local has the record:**
  - If it was in `base` too → the remote side deleted it. If local was modified after the base
    timestamp, keep the local modification (a same-record edit always beats a deletion the edit
    didn't know about); otherwise exclude it (a genuine, un-raced deletion).
  - If it was never in `base` → it's new locally; include it.
- **Only remote has the record:** the mirror image of the previous case (remote edit-after-base wins
  over a local deletion; brand-new remote records are included).
- **Neither side has it, but base did:** deleted on both sides → excluded, no conflict.

This produces a `RecordMergeResult<T>` with a `merged: List<T>` and a `conflicts:
List<RecordConflict<T>>`.

## Per-file merge functions (Sync Data Reference)

Each data-file merge function (`mergeTodoData`, `mergeFinanceData`, `mergeIntimacyData`,
`mergeWeightData`) calls `mergeRecords<T>` once per record collection in that file, then merges the
file's non-record settings separately by last-writer-wins on `settingsModifiedAt`. Reproduced from
`AGENTS.md`:

| File | Merge function | Merge strategy |
| --- | --- | --- |
| `todo_data.json` | `mergeTodoData()` | Daily/one-time records by id + `modifiedAt`; daily log union; daily score LWW per date; settings LWW |
| `finance_data.json` | `mergeFinanceData()` | Accounts/categories/transactions/subscriptions by id + `modifiedAt`; settings LWW |
| `exchange_rates.json` | `mergeExchangeRateJson()` | Snapshot union; newer valid current snapshot wins (a current id that does not resolve to a snapshot is ignored); newer `lastFetchedAt` wins |
| `intimacy_data.json` | `mergeIntimacyData()` | Partners/toys/positions/records/cycleRecords by id + `modifiedAt` (partner `body` rides its partner record); timer history union by start; timer session LWW by `timerSessionModifiedAt`; `userBody` LWW by `userBodyModifiedAt`; settings LWW |
| `weight_data.json` | `mergeWeightData()` | Records by id + `modifiedAt`; height follows settings LWW (saving weight data bumps `settingsModifiedAt`, so clearing height syncs); reminder/settings LWW |
| `images/*` | `_syncImages()` | Additive bidirectional, but only for referenced images |

`mergeExchangeRateJson` (`lib/shared/services/sync_merge.dart`) is special: it does not go through
`mergeRecords` at all, since rate snapshots never conflict — it unions `local.snapshots` and
`remote.snapshots` into one map (`{...local.snapshots, ...remote.snapshots}`), then picks whichever
side's *current* snapshot has the later `createdAt` as the merged `currentSnapshotId` (a current id
that fails to resolve to any snapshot on its own side is ignored rather than propagated), and takes
the later of the two `lastFetchedAt` values.

## Deletion/union semantics for specific containers

- **`DailyCompletionLog`** (Todo): `DailyCompletionLog.merge(a, b)` — for every date present in
  either log, the merged set of completed task ids (and, separately, completed subtask ids) is the
  **union** of both sides' sets for that date. A task marked complete on either device stays
  complete after merge; there is no "uncomplete" propagation through this path — only explicit
  toggles change completion, and a toggle bumps that record's own `modifiedAt` so it flows through
  the ordinary per-record `Task` merge instead.
- **`DailyScoreLog`** (Todo): merged per date independently, picking whichever side's
  `DailyScoreEntry.modifiedAt` is newer (ties favor local). Explicit zero-score entries are real
  entries, not "absence", so a deliberate reset to zero on one device wins over an older non-zero
  score on the other side exactly like any other value would.
- **`CycleRecord`** (Intimacy): goes through the ordinary `mergeRecords<CycleRecord>` path keyed by
  `id`, with `serialize: (x) => jsonEncode(x.toJson())` so identical-content records never raise a
  spurious conflict. Because cycle records are **add/delete only** (there is no edit flow — the UI
  only creates or removes a start-date record), the generic "record deleted on one side, unchanged
  on other → exclude" rule is exactly cycle deletion propagation: deleting a period-start record on
  one device removes it after merge as long as the other device didn't independently touch that
  same record id.

## Related pages

- [WebDAV Sync](../sync.md) — how these merge functions fit into the full 10-step sync flow, and the
  cross-module mixed-resolutions-map safety rule for resolving conflicts across multiple files at
  once.
- [Sync Walkthrough](../examples/sync-walkthrough.md) — a worked example with a genuine two-sided
  conflict in two different files at once.
- [Data Formats](../data-formats.md) — the exact fields each merge function reads.

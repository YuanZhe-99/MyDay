# Sync Walkthrough: A Cross-Module Conflict

A worked example of the [10-step WebDAV sync flow](../sync.md) hitting a genuine two-sided conflict
in **two different data files at once**, and how the
[mixed-resolutions-map safety rule](../sync.md#the-cross-module-mixed-resolutions-map-safety-rule)
keeps that from crashing or silently dropping data. This is illustrative, built from the documented
merge behavior in `lib/shared/services/sync_merge.dart` and `webdav_service.dart`'s
`finalizePendingSync` — not a literal transcript of a real run.

## Setup

Two devices, **Phone** and **Laptop**, both last synced at `T0`. The `.sync_base/` snapshots on
both match the remote state as of `T0`.

- **Finance:** both devices have the same `Account` "Checking" (id `acc-1`) with `modifiedAt: T0`.
- **Intimacy:** both devices have the same `Partner` "Alex" (id `partner-1`) with
  `modifiedAt: T0`.

## Divergence (offline, no sync in between)

- **Phone**, at `T1` (after `T0`): user edits the Checking account's currency.
  `Account(id: 'acc-1', ..., modifiedAt: T1)`.
- **Laptop**, at `T2` (after `T0`, independently of the phone): user edits the same account's
  `bankOrApp` field. `Account(id: 'acc-1', ..., modifiedAt: T2)`.
- **Phone**, also at `T1`: user edits Alex's relationship `endDate` (marking a break-up).
  `Partner(id: 'partner-1', ..., modifiedAt: T1)`.
- **Laptop**, also at `T2`: user edits Alex's `emoji`. `Partner(id: 'partner-1', ..., modifiedAt:
  T2)`.

Neither device has synced with the other since `T0`, so neither knows about the other's edit.

## Sync attempt (Laptop syncs first, then Phone)

**Laptop syncs** at `T3`. It acquires `.lock`, downloads the remote `finance_data.json` and
`intimacy_data.json` (both still at the `T0` state, since Phone hasn't synced yet), and merges
against its own `.sync_base/` (also `T0`). Since only Laptop has changed each record relative to
base and remote, both `Account acc-1` and `Partner partner-1` merge with **no conflict** — Laptop's
`T2` versions win. Laptop force-uploads both merged files under the still-valid lock, updates its
base snapshots to the new `T2` state, and releases the lock.

**Phone syncs** at `T4`. It downloads the now-`T2` remote files. Its own `.sync_base/` is still at
`T0` (it hasn't synced since). Running `mergeRecords`:

- For `acc-1`: `local.modifiedAt (T1) > base.modifiedAt (T0)` → `localChanged = true`.
  `remote.modifiedAt (T2) > base.modifiedAt (T0)` → `remoteChanged = true`. **Both changed** → since
  the two sides touched different fields but both bumped `modifiedAt`, `serialize(local) !=
  serialize(remote)` (the JSON differs — currency vs. bankOrApp), so this is a **real conflict**,
  not an auto-mergeable identical-content case.
- For `partner-1`: the same reasoning applies — **both changed**, different fields, real conflict.

Because Phone's sync is a manual/auto-sync run with `autoResolve: false`, both conflicts are
collected rather than silently resolved by last-writer-wins. `mergeFinanceData` returns a
`FinanceMergeResult` with one entry in `accountConflicts` (id `acc-1`); `mergeIntimacyData` returns
an `IntimacyMergeResult` with one entry in `partnerConflicts` (id `partner-1`). Both merges happen in
the *same* sync run because Finance and Intimacy are separate files merged independently but
resolved together in one `PendingSync`.

## Resolving both conflicts in one pass

The WebDAV page shows `SyncConflictDialog` listing **both** conflicts — the Finance account and the
Intimacy partner — to the user in one screen. The user picks, say, "keep local" for the Finance
account and "keep remote" for the Intimacy partner. The UI builds a single combined resolutions map
keyed by conflict id:

```dart
final resolutions = <String, dynamic>{
  'acc-1': phoneLocalAccount,       // Account — user chose local
  'partner-1': laptopRemotePartner, // Partner — user chose remote
};
```

Note that this one `Map<String, dynamic>` mixes an `Account` value and a `Partner` value under
different keys — there is no way to give it a single concrete value type.

## Why the map can't be bulk-cast

`WebDAVService.finalizePendingSync(config, pending, resolutions)` calls, among others:

```dart
pending.financeMerge!.buildResolved(resolutions)
pending.intimacyMerge!.buildResolved(resolutions)
```

Each `buildResolved` internally calls its own `_resolveList<T>(merged, conflicts, resolutions)`,
which only ever reads `resolutions[c.id]` for the conflict ids **that file itself** produced, and
type-checks each value before using it — e.g. (shown for Weight, the same shape as Finance and
Intimacy):

```dart
for (final c in recordConflicts) {
  final resolved = resolutions[c.id];
  result.add(resolved is WeightRecord ? resolved : c.localRecord);
}
```

So `FinanceMergeResult.buildResolved` only ever looks at `resolutions['acc-1']` and checks
`resolved is Account`; it never touches `resolutions['partner-1']`, and even if it did, the `is
Account` check would simply fail and fall back to the local record rather than throwing a cast
exception. `IntimacyMergeResult.buildResolved` does the mirror-image lookup for `'partner-1'` with
an `is Partner` check.

If the code instead did something like `resolutions.cast<String, Account>()` or
`resolutions as Map<String, Account>` before handing it to Finance's merge, that cast would throw
the moment it hit the `Partner` value at key `'partner-1'` — which is exactly the crash `AGENTS.md`
notes this rule was written to prevent ("that crashed on cross-module conflicts"). By having each
module do its own narrow `is T` check per id instead, both conflicts resolve correctly in the same
`finalizePendingSync` call, and an entry that is missing or the wrong type for a given file
defaults to that file's local record rather than being dropped.

## Related pages

- [WebDAV Sync](../sync.md) — the full 10-step flow and the safety rule in prose form.
- [Three-Way Merge](../algorithms/three-way-merge.md) — the `mergeRecords` engine used for both
  `Account` and `Partner` above.
- [Data Formats](../data-formats.md) — `Account` and `Partner` field definitions.

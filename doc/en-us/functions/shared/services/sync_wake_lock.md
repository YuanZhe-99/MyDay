# lib/shared/services/sync_wake_lock.dart

**Re-export shim.** `SyncWakeLock` moved verbatim to the shared `myapps_data` package
(`lib/src/sync/sync_wake_lock.dart` there). The three apps' copies were byte-identical, verified by
SHA-256.

```dart
export 'package:myapps_data/myapps_data.dart' show SyncWakeLock;
```

The lock is still reference-counted, ownership-tracked, and swallows all plugin errors. It is
acquired and released by the **pages** that run foreground operations (manual sync, conflict
finalize, force upload/download), not by the sync engine — background auto-sync must not use it.

## Declarations

None of its own.

**Reconciliation:** `grep -c 'Purpose:' lib/shared/services/sync_wake_lock.dart` reports 1 and the table is empty — correct. That single block is the **file-level** library comment describing the re-export; the file declares nothing of its own, which is the entire point of a shim.

## Where the real documentation lives

`packages/myapps_data/doc/en-us/functions/src/sync/sync_wake_lock.md`.

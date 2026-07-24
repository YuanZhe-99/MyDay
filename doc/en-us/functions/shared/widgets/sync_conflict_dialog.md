# lib/shared/widgets/sync_conflict_dialog.dart

The manual-sync conflict-resolution dialog: for each record that changed on both sides since the
last sync, the user picks "Keep Local" or "Keep Remote" per record, and the dialog does not enable
its Apply button until every conflict has a choice. See
[../../../sync.md#the-cross-module-mixed-resolutions-map-safety-rule](../../../sync.md#the-cross-module-mixed-resolutions-map-safety-rule)
for how the resulting `Map<String, dynamic>` of chosen records is consumed afterward.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SyncConflictDialog` (constructor) | constructor (`SyncConflictDialog`) | B | Create a sync conflict dialog instance. |
| `createState` | method (`SyncConflictDialog`) | B | Create the mutable state object for this widget. |
| `_allResolved` | getter (`_SyncConflictDialogState`) | B | Return whether every conflict has a chosen side. |
| `build` | method (`_SyncConflictDialogState`) | B | Build the conflict list and Apply/Cancel actions. |
| `_ChoiceButton` (constructor) | constructor (`_ChoiceButton`) | B | Create a choice button instance. |
| `build` | method (`_ChoiceButton`) | B | Build the local/remote choice chip. |

`grep -c 'Purpose:' lib/shared/widgets/sync_conflict_dialog.dart` reports 6, matching all six real
declarations in this file. No misattachment or undocumented declarations found. Every declaration
here is Tier B: the two constructors are simple forwarding constructors, both `build()` methods
fall under the explicit build-method rule, and `_allResolved` is a one-line length comparison with
no branching/loops/IO.

## Documentation

All declarations in this file are Tier B, so per the template they have index rows only, no full
entries. For context: `SyncConflictDialog` takes a `List<RecordConflict>` (from
`shared/services/sync_merge.dart`) and returns, via `Navigator.pop`, either `null` (cancelled) or a
`Map<String, dynamic>` mapping each conflict's `id` to the chosen `localRecord`/`remoteRecord`
object. It is shown like this:

```dart
final resolutions = await showDialog<Map<String, dynamic>>(
  context: context,
  barrierDismissible: false,
  builder: (_) => SyncConflictDialog(conflicts: result.pending!.allConflicts),
);
```

(`lib/shared/views/webdav_config_page.dart`, `_syncNow`, after a manual sync reports
`result.hasConflicts`.) The resulting map is passed to `WebDAVService.finalizePendingSync`, which
is held under `SyncWakeLock.acquire()`/`release()` for the duration — see
[sync_wake_lock.md](../services/sync_wake_lock.md).

# lib/features/intimacy/widgets/add_record_dialog.dart

`AddRecordDialog` is the add/edit form for a single `IntimacyRecord` — solo-vs-partnered toggle,
partner/toy/position pickers, 5-star pleasure level, hours+minutes duration, an x100/x1 thrust
counter, orgasm/porn/condom toggles, location/notes text, and a date+time picker — opened both from
the record list (add/edit) and from the timer flow (`widgets/timer_page.dart`, pre-filled from a
finished stopwatch session). It uses the shared
[`UnsavedChangesGuard`/`formSignature`](../../../shared/widgets/unsaved_changes_guard.md)
dirty-checking pattern for its cancel confirmation, the same pattern used by
[`weight_page.dart`'s record dialog](../../../../functions/features/weight/views/weight_page.md).
Despite being a dialog widget, its `initState`/`_submit` pair carries real logic: this is where the
repo's deleted-partner tolerance for intimacy records is actually implemented — see
[Intimacy](../../../../features/intimacy.md#deleted-partner-handling), which documents that "editing
a record whose partner was deleted builds and preserves the untouched partner id."

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AddRecordDialog` (constructor) | constructor (`AddRecordDialog`) | B | Create an add/edit record dialog instance from an optional existing record and initial-selection parameters. |
| `AddRecordDialog.createState` | method (`AddRecordDialog`) | B | Create the mutable `_AddRecordDialogState`. |
| `_isEditing` | getter (`_AddRecordDialogState`) | B | Return whether `widget.record` is non-null (edit mode vs. add mode). |
| [`initState`](#initstate) | method (`_AddRecordDialogState`) | A | Seed every field from the record being edited or from initial-selection parameters, applying solo/thrust-unit/duration defaulting rules. |
| `dispose` | method (`_AddRecordDialogState`) | B | Dispose all five `TextEditingController`s. |
| `build` | method (`_AddRecordDialogState`) | B | Render the full add/edit form inside an `UnsavedChangesGuard`-wrapped `Dialog`. |
| `_hasUnsavedChanges` | method (`_AddRecordDialogState`) | B | Compare the current form signature to the one captured at `initState`. |
| `_signature` | method (`_AddRecordDialogState`) | B | Build a `formSignature` snapshot of every editable field's current value. |
| [`_submit`](#submit) | method (`_AddRecordDialogState`) | A | Parse/normalize duration and thrust count, build the resulting `IntimacyRecord`, and pop the dialog with it. |

`grep -c 'Purpose:' lib/features/intimacy/widgets/add_record_dialog.dart` reports 9, matching all 9
real declarations counted above exactly (2 Tier A, 7 Tier B). Every `/// Purpose:` block sits
directly above the real declaration it documents — no misattached blocks and no undocumented real
declaration were found. The class fields themselves (all the `final`/`late` fields on both
`AddRecordDialog` and `_AddRecordDialogState`) are plain data holders, not counted as declarations.

## Documentation

### `void initState()` <a id="initstate"></a>
- **Kind:** method of `_AddRecordDialogState` (override of `State.initState`)
- **Source:** `lib/features/intimacy/widgets/add_record_dialog.dart` (line 78)
- **Purpose:** Seed every editable field either from the record being edited (`widget.record`) or
  from the dialog's initial-selection constructor parameters, apply the solo/thrust-unit/duration
  defaulting rules, and capture the initial dirty-check signature.
- **Inputs:** None directly — reads `widget.record`, `widget.initialPartnerId`,
  `widget.initialToyIds`, `widget.initialThrustCount`, `widget.initialThrustCountUnit`,
  `widget.prefillDuration`, and `widget.partners`.
- **Returns:** None.
- **Side effects:** Constructs all five `TextEditingController`s; sets every other mutable state
  field; computes and stores `_initialSignature`.
- **Algorithm:**
  1. `_isSolo = r?.isSolo ?? (widget.initialPartnerId == null && widget.partners.isEmpty)` — when
     adding (no record), defaults to solo only if no partner was pre-selected and there are no
     partners to pick from at all.
  2. `_selectedPartnerId = r?.partnerId ?? widget.initialPartnerId` — when editing, this takes the
     record's stored `partnerId` verbatim, regardless of whether that id is still present in
     `widget.partners`.
  3. `_selectedToyIds`/`_selectedPositionIds` seed from the record's ids or the initial-selection
     parameters; `_locationController`/`_notesController` seed from the record's text or empty.
  4. `_pleasureLevel` defaults to `3`; `initMinutes` defaults to `r?.duration.inMinutes ?? 15`.
  5. `initialThrustCount = r?.thrustCount ?? widget.initialThrustCount`; the thrust-count controller
     text is that value's string form only if it is non-null and `> 0`, otherwise empty.
     `_thrustCountUnit` cascades `r?.thrustCountUnit ?? widget.initialThrustCountUnit ?? 100`.
  6. `_datetime` defaults to `r?.datetime ?? DateTime.now()`; the three boolean flags
     (`_hadOrgasm`/`_watchedPorn`/`_usedCondom`) default to `false` when adding.
  7. If `widget.prefillDuration != null && r == null` (a fresh record prefilled from a finished
     timer, never an edit), overwrite `initMinutes` with
     `widget.prefillDuration!.inMinutes.clamp(0, 5999)`.
  8. Build the hours/minutes controllers from `initMinutes ~/ 60` and `initMinutes % 60`.
  9. If not solo, no partner is yet selected, and `widget.partners` is non-empty, default
     `_selectedPartnerId` to `widget.partners.first.id`.
  10. `_initialSignature = _signature()` — captured last, after every field above has its final
      initial value, so the unsaved-changes guard has an accurate baseline.
- **Usage:**
  ```dart
  // Editing an existing record (views/intimacy_page.dart, lines 505-511):
  final activePartners = _partners.where((p) => p.endDate == null).toList();
  final updated = await showDialog<IntimacyRecord>(
    context: context,
    builder: (_) => AddRecordDialog(
      record: record,
      partners: activePartners,
      toys: activeToys,
      positions: _positions,
    ),
  );
  ```
- **Notes:** This is where the "editing a record whose partner was deleted builds and preserves the
  untouched partner id" behavior from
  [Intimacy](../../../../features/intimacy.md#deleted-partner-handling) actually starts: step 2
  copies `r.partnerId` into `_selectedPartnerId` unconditionally, even though the caller's
  `activePartners` list (built with `.where((p) => p.endDate == null)`) may already exclude that
  partner, or the partner may have been deleted outright and be entirely absent from
  `widget.partners`. Nothing in `initState` cross-checks `_selectedPartnerId` against
  `widget.partners` — that check only happens cosmetically in `build()`'s dropdown `initialValue`
  (`widget.partners.any((p) => p.id == _selectedPartnerId) ? _selectedPartnerId : null`), which
  affects only what the dropdown displays, not the underlying `_selectedPartnerId` field itself.

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **Kind:** method of `_AddRecordDialogState`
- **Source:** `lib/features/intimacy/widgets/add_record_dialog.dart` (line 512)
- **Purpose:** Parse the duration and thrust-count text fields, normalize empty/zero/unparsable
  input to absent, build the resulting `IntimacyRecord` — preserving the original id and any
  untouched (possibly dangling) partner id when editing — and pop the dialog with it.
- **Inputs:** `guard` — the `UnsavedChangesController` used to close the dialog with a result.
- **Returns:** None.
- **Side effects:** Calls `guard.pop(record)`.
- **Algorithm:**
  1. Parse `hours`/`minutes` via `int.tryParse` on the two controllers, defaulting each to `0` on
     failure.
  2. `totalMinutes = (hours * 60 + minutes).clamp(0, 5999)` — the same 5999-minute (~99h59m) cap used
     when seeding from `prefillDuration` in `initState`.
  3. Parse `thrustCount` from its controller's trimmed text; normalize to `null` unless the parsed
     value is `> 0` (so `"0"`, blank, or unparsable text all mean "not recorded").
  4. Build the `IntimacyRecord`: `id: widget.record?.id` (preserves the id when editing, lets the
     model assign one when adding); `type` is `'Solo'` or `'Regular'` from `_isSolo`; `partnerId:
     _isSolo ? null : _selectedPartnerId` — reading the state field set up in `initState`/the
     dropdown's `onChanged`, not anything re-derived from `widget.partners`; `duration:
     Duration(minutes: totalMinutes)`; the parsed `thrustCount`/`_thrustCountUnit`; `_datetime`;
     `toyIds`/`positionIds` from the selected sets; the three boolean flags; and
     `location`/`notes` as the trimmed controller text, or `null` when that trim is empty.
  5. `guard.pop(record)` — closes the dialog, returning `record` as the `showDialog` result.
- **Usage:**
  ```dart
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(l10n.commonSave),
  ),
  ```
  (`build`, lines 464-467.)
- **Notes:** `partnerId` is written straight from `_selectedPartnerId` with no re-validation against
  `widget.partners` — if the user never opens the partner dropdown during an edit (so `onChanged`
  never fires), the value set in `initState` from the record's original `partnerId` flows through
  unchanged, even if that partner no longer exists in `widget.partners`. This is the concrete
  mechanism behind the deleted-partner-tolerance behavior; there is no separate "restore" step
  because the id is simply never cleared in the first place.

## Related pages

- [Intimacy](../../../../features/intimacy.md#deleted-partner-handling) — the deleted-partner
  tolerance this dialog's `initState`/`_submit` pair implements, and why `IntimacyRecord` rows keep
  a dangling `partnerId` rather than being reassigned or dropped.
- [`UnsavedChangesGuard`/`formSignature`](../../../shared/widgets/unsaved_changes_guard.md) — the
  shared dirty-checking pattern behind `_hasUnsavedChanges`/`_signature` and the cancel-confirmation
  flow wrapping this dialog's `Dialog` content.
- [`weight_page.dart`](../../../../functions/features/weight/views/weight_page.md) — another
  add/edit dialog (`_WeightRecordDialog`) using the identical
  `initState`/`_signature`/`_hasUnsavedChanges`/`_submit` shape.
- [`timer_page.dart`](timer_page.md) — calls this dialog with `prefillDuration`/
  `initialThrustCount`/`initialThrustCountUnit` after a finished stopwatch session.

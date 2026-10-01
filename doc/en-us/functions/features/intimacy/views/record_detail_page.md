# lib/features/intimacy/views/record_detail_page.dart

`RecordDetailPage` (v1.5.5) is the read-only view of one `IntimacyRecord`, described in
[Intimacy — Record detail page](../../../../features/intimacy.md#record-detail-page). Tapping a
record tile on the intimacy home page or on a partner/toy detail page pushes it (see
[`_openRecordDetail`](intimacy_page.md#openrecorddetail-main)). It shows a header card (partner or
solo, date and time, pleasure stars), three headline figures (duration as `HH:MM:SS`, thrust count,
thrust rate), the [thrust timeline chart](../widgets/thrust_timeline_chart.md) when the record has
at least two timer presses, toys, positions, the orgasm/porn/condom flags, the location and the
notes. Edit and delete live in the app bar and are **delegated to the caller** through two
callbacks, so the page owns no persistence and reuses each caller's own editor, save path and
filter behavior. The body is width-capped at `readingMaxContentWidth` with no split gate
([adaptive layout](../../../../adaptive-layout.md#rule-d--what-a-page-does-with-width-it-cannot-split)).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `RecordEditCallback` | typedef | B | `Future<IntimacyRecord?> Function(IntimacyRecord)`: open the caller's editor and save; return the saved record, or null when cancelled. |
| `RecordDeleteCallback` | typedef | B | `Future<void> Function(IntimacyRecord)`: remove the record and save. |
| `RecordDetailPage({record, partners, toys, positions, onEdit, onDelete})` | constructor (`RecordDetailPage`) | B | Create a record detail page. |
| `RecordDetailPage.createState` | method (`RecordDetailPage`) | B | Create the mutable `_RecordDetailPageState`. |
| `initState` | method (`_RecordDetailPageState`) | B | Copy `widget.record` into `_record`, so an edit can re-render in place. |
| [`_edit`](#edit) | method (`_RecordDetailPageState`) | A | Edit the record through the caller and show the result. |
| [`_delete`](#delete) | method (`_RecordDetailPageState`) | A | Confirm, delete the record through the caller, and close the page. |
| `_formatDuration` | static method (`_RecordDetailPageState`) | B | Format a duration as `HH:MM:SS`, matching the timer page. |
| [`build`](#build) | method (`_RecordDetailPageState`) | A | Build the page for the current record. |
| `_HeaderCard({record, partner})` | constructor (`_HeaderCard`) | B | Create the header card. |
| [`_HeaderCard.build`](#headercard-build) | method (`_HeaderCard`) | A | Show who, when, and the pleasure rating. |
| `_StatTile({icon, label, value})` | constructor (`_StatTile`) | B | Create one headline figure. |
| `_StatTile.build` | method (`_StatTile`) | B | Build a fixed-width (150) card with an icon, a label and a tabular-figure value. |
| `_Section({title, child})` | constructor (`_Section`) | B | Create a titled card section. |
| `_Section.build` | method (`_Section`) | B | Build a card with a small title above its content. |
| `_FlagTile({icon, label, value})` | constructor (`_FlagTile`) | B | Create a yes/no row. |
| `_FlagTile.build` | method (`_FlagTile`) | B | Build a dense `ListTile` with a check or empty-circle mark. |
| `_ToyChip({toy})` | constructor (`_ToyChip`) | B | Create a toy chip. |
| `_ToyChip.build` | method (`_ToyChip`) | B | Build a chip with the toy's image avatar when it resolves, otherwise the emoji label. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/intimacy/views/record_detail_page.dart`
reports 17 against 19 rows. The two typedefs carry plain `///` comments rather than `Purpose:`
blocks; they are part of the file's public surface, so they get rows. Every `/// Purpose:` block
sits directly above the declaration it documents. Tier split: 4 Tier A, 15 Tier B.

## Documentation

### `Future<void> _edit()` <a id="edit"></a>
- **Kind:** method of `_RecordDetailPageState`
- **Source:** `lib/features/intimacy/views/record_detail_page.dart` (line 76)
- **Purpose:** Run the caller's edit flow for the shown record and refresh the page with the result.
- **Inputs:** None (reads `_record`, `widget.onEdit`).
- **Returns:** `Future<void>`.
- **Side effects:** Whatever `onEdit` does (opens `AddRecordDialog`, saves); `setState` replaces
  `_record` when a record comes back and the page is still mounted.
- **Algorithm:** `updated = await widget.onEdit(_record)`; if non-null and mounted, `_record =
  updated`.
- **Usage:** The app bar's edit `IconButton` (`onPressed: _edit`, line 138).
- **Notes:** The page keeps its own `_record` copy for exactly this: the caller's list updates
  through its own save path, and the detail page shows the edit without being re-pushed. A cancelled
  edit returns `null` and leaves the page unchanged. Both callers pass their `_editRecord`, which
  returns `Future<IntimacyRecord?>` since v1.5.5 for this purpose.

### `Future<void> _delete()` <a id="delete"></a>
- **Kind:** method of `_RecordDetailPageState`
- **Source:** `lib/features/intimacy/views/record_detail_page.dart` (line 86)
- **Purpose:** Delete the shown record after confirmation and leave the page.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Shows the shared `confirmDelete` dialog; calls `widget.onDelete`; pops the page.
- **Algorithm:** `confirmDelete(context, l10n.commonThisRecord)`; return if not confirmed or no
  longer mounted; `await widget.onDelete(_record)`; pop if still mounted.
- **Usage:** The app bar's delete `IconButton` (`onPressed: _delete`, line 143).
- **Notes:** The confirmation happens here, before the callback, because the callers'
  `_deleteRecord` methods do no confirming of their own — on the list that is the swipe's
  `confirmDismiss`. Both callers wrap their synchronous `_deleteRecord` as `(r) async =>
  _deleteRecord(r)`.

### `Widget build(BuildContext context)` <a id="build"></a>
- **Kind:** method of `_RecordDetailPageState` (override of `State.build`)
- **Source:** `lib/features/intimacy/views/record_detail_page.dart` (line 113)
- **Purpose:** Lay out everything recorded about one session.
- **Inputs:** `context`; reads `_record` and the widget's `partners`, `toys`, `positions`.
- **Returns:** A `Scaffold`.
- **Side effects:** None.
- **Algorithm:**
  1. Resolve the partner (`firstOrNull` by `partnerId`), the toys and the positions by id from the
     widget's lists; ids that match nothing are skipped.
  2. App bar: title `intimacyRecordDetail`, edit and delete actions (`commonEdit`/`commonDelete`
     tooltips).
  3. Body: `SingleChildScrollView(padding: 16)` › `Center` › `ConstrainedBox(maxWidth:
     readingMaxContentWidth)` › a stretched `Column` of:
     - `_HeaderCard`;
     - a `Wrap` of three `_StatTile`s: duration (`_formatDuration`), thrust count
       (`'<thrustCount> x<thrustCountUnit>'`, or `intimacyNotRecorded` when absent or zero) and
       thrust rate (`'<rate rounded>/min'` from `IntimacyRecord.thrustsPerMinute`, or
       `intimacyNotRecorded`);
     - when `record.hasThrustTimeline`, a card titled `intimacyThrustTimeline` holding
       `ThrustTimelineChart(timeline, duration)`;
     - toys (`_ToyChip`s) and positions (`Chip`s with emoji) in `_Section`s, each only when
       non-empty;
     - a card of three `_FlagTile`s: `intimacyOrgasmStatus`, `intimacyWatchedPornStatus`,
       `intimacyUsedCondomStatus`;
     - location (`intimacyDetailLocation`) and notes (`intimacyDetailNotes`, as `SelectableText`)
       sections, each only when set.
- **Usage:** Built by Flutter after `_openRecordDetail` pushes the page.
- **Notes:** Width cap, no gate: a single column of cards gains nothing from a split, and below 840
  logical pixels the page is untouched. The cap is a plain `Center` › `ConstrainedBox` inside the
  scroll view rather than the shared `AdaptiveContentWidth` widget; the effect is the same, and the
  scroll gesture still spans the whole window. Callers pass **every** partner and toy, including ended
  and retired ones, so an old record still shows its names; a deleted partner falls back to the
  generic `intimacyPartner` title in the header.

### `Widget build(BuildContext context)` (`_HeaderCard`) <a id="headercard-build"></a>
- **Kind:** method of `_HeaderCard`
- **Source:** `lib/features/intimacy/views/record_detail_page.dart` (line 296)
- **Purpose:** Show the session's who, when, and pleasure rating at the top of the page.
- **Inputs:** `context`; `record`, the resolved `partner`.
- **Returns:** A `Card` with a leading avatar, a title and date column, and trailing stars.
- **Side effects:** Resolves the partner image from the blob store through
  `ImageService.resolve` (a `FutureBuilder`).
- **Algorithm:** Title is `intimacySolo` for a solo record, `intimacyPartner` when the partner is
  unknown, otherwise the partner's emoji and name. The avatar is a 20-radius `CircleAvatar` of the
  partner image when it resolves to an existing file, otherwise a person (solo) or heart icon. The
  date line is `DateFormat.yMMMd(localeName).add_Hm()`. The stars are `★` × `pleasureLevel` then
  `☆` up to five, with an `intimacyPleasure` tooltip.
- **Usage:** `_HeaderCard(record: record, partner: partner)` at the top of `build`.
- **Notes:** Mirrors the record list tile's avatar fallback, so the same record looks the same in
  both places.

## Related pages

- [Intimacy — Record detail page](../../../../features/intimacy.md#record-detail-page).
- [`intimacy_page.dart`](intimacy_page.md) — both `_openRecordDetail` callers, and the `_editRecord`
  / `_deleteRecord` methods they pass as `onEdit` / `onDelete`.
- [`thrust_timeline_chart.dart`](../widgets/thrust_timeline_chart.md) — the chart card.
- [`intimacy_record.dart`](../models/intimacy_record.md) — `hasThrustTimeline`, `thrustsPerMinute`.
- [`delete_confirm.dart`](../../../shared/widgets/delete_confirm.md) — the shared confirmation used
  by `_delete`.

# lib/features/intimacy/widgets/body_section.dart

`BodySectionView` is the single shared widget behind both Body surfaces described in
[Intimacy — The Body layer](../../../../features/intimacy.md#the-body-layer-v124): the user's own
`views/body_page.dart` (`BodySettingsPage`) and the partner detail page's **Body** tab. It renders
four cards — measurements+WHR, bra-size estimation, cycle tracking, and PSI — driven by
`services/body_metrics.dart` (`estimateBraSize`, `calculatePsi`) and `services/cycle_predictor.dart`
(`predictCycle`), both covered algorithmically in [Body Metrics](../../../../algorithms/body-metrics.md).
It embeds `CycleCalendar`/`CycleLegend` from `cycle_calendar.dart` for the per-person calendar, and
this file is where the `cyclePersonColor` stable-palette function actually lives (`cycle_calendar.dart`
only owns the `cyclePersonPalette` constant it reads). The file's two most distinctive pieces of real
logic — beyond ordinary card widget-building — are the **weight-sync warning + debounce** that lets
the user's own bust/waist/hip fields double as a Weight-module editor
(`_confirmWeightSync`/`_onMeasurementChanged`/`_commitWeightRecord`), and the shared `_NumberField`
auto-committing input used by every measurement card.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`cyclePersonColor`](#cyclepersoncolor) | top-level function | A | Pick the stable cycle-indicator color for a person (user = slot 0, partners by sorted id). |
| `BodySectionView` (constructor) | constructor (`BodySectionView`) | B | Create a body section view instance for a given mode/profile/person. |
| `BodySectionView.createState` | method (`BodySectionView`) | B | Create the mutable `_BodySectionViewState`. |
| `_profile` | getter (`_BodySectionViewState`) | B | Return `widget.profile`, defaulting to an empty `BodyProfile()`. |
| [`initState`](#initstate) | method (`_BodySectionViewState`) | A | Load weight measurements in user mode, or seed local fields from the partner profile directly. |
| [`dispose`](#dispose) | method (`_BodySectionViewState`) | A | Flush any pending debounced weight-record commit before the state is torn down. |
| [`_loadUserMeasurements`](#loadusermeasurements) | method (`_BodySectionViewState`) | A | Load the user's latest bust/waist/hip from Weight records and the sync-warning opt-out flag. |
| [`_latestRecord`](#latestrecord) | method (`_BodySectionViewState`) | A | Return the newest `WeightRecord` by datetime. |
| [`_setSyncWarningDisabled`](#setsyncwarningdisabled) | method (`_BodySectionViewState`) | A | Persist the weight-sync warning opt-out flag to `storage_config.json`. |
| [`_confirmWeightSync`](#confirmweightsync) | method (`_BodySectionViewState`) | A | Gate the first user-mode measurement edit behind the weight-sync warning dialog. |
| [`_onMeasurementChanged`](#onmeasurementchanged) | method (`_BodySectionViewState`) | A | Apply a measurement change and schedule the debounced weight commit (user mode) or push the profile immediately (partner mode). |
| [`_commitWeightRecord`](#commitweightrecord) | method (`_BodySectionViewState`) | A | Append one new `WeightRecord` from the currently displayed measurements. |
| `_myCycleDays` | getter (`_BodySectionViewState`) | B | Return this person's recorded period-start days as a deduplicated `Set<DateTime>`. |
| [`_prediction`](#prediction) | getter (`_BodySectionViewState`) | A | Compute this person's `CyclePrediction` over a history-to-13-months-ahead window. |
| [`_addCycleStart`](#addcyclestart) | method (`_BodySectionViewState`) | A | Add a period-start `CycleRecord` for the selected calendar date, rejecting duplicates. |
| [`_deleteCycleStart`](#deletecyclestart) | method (`_BodySectionViewState`) | A | Delete the period-start record on the selected date, after confirmation. |
| `_updateProfile` | method (`_BodySectionViewState`) | B | Forward a `BodyProfile` mutation to `widget.onProfileChanged`. |
| `build` | method (`_BodySectionViewState`) | B | Compose the measurements/bra/cycle/PSI cards plus the bottom warning-setting card into a `Column`. |
| `_buildMeasurementsCard` | method (widget helper) | B | Build the bust/waist/hip measurement card with the read-only WHR row. |
| `_buildBraCard` | method (widget helper) | B | Build the underbust input, bra-standard picker, and estimated size display. |
| `_showBraHelp` | method (`_BodySectionViewState`) | B | Open a dialog explaining each supported bra standard plus the estimate disclaimer. |
| `_buildCycleCard` | method (widget helper) | B | Build the cycle-tracking toggle, calendar, legend, and add/delete-start action row. |
| [`_selectedCycleDateSummary`](#selectedcycledatesummary) | method (`_BodySectionViewState`) | A | Summarize the selected calendar date's phase/ovulation/fertile-window/predicted-start status as one line. |
| `_buildPsiCard` | method (widget helper) | B | Build the erect-length/circumference inputs and the computed PSI display. |
| `_buildWarningSettingCard` | method (widget helper) | B | Build the bottom "don't remind me again" setting card (user mode only). |
| `_NumberField` (constructor) | constructor (`_NumberField`) | B | Create an auto-committing optional decimal input field instance. |
| `_NumberField.createState` | method (`_NumberField`) | B | Create the mutable `_NumberFieldState`. |
| `_NumberFieldState.initState` | method (`_NumberFieldState`) | B | Seed the text controller from the initial value and register the focus listener. |
| [`didUpdateWidget`](#didupdatewidget) | method (`_NumberFieldState`) | A | Refresh the displayed text when the external value changes while the field isn't actively focused. |
| `_NumberFieldState.dispose` | method (`_NumberFieldState`) | B | Cancel the debounce timer, flush a final commit, and dispose the controller/focus node. |
| [`_format`](#format) | method (`_NumberFieldState`) | A | Format a `double?` for display, dropping a trailing `.0`. |
| [`_onFocusChanged`](#onfocuschanged) | method (`_NumberFieldState`) | A | Commit the field's text as soon as focus leaves it. |
| [`_commit`](#commit) | method (`_NumberFieldState`) | A | Parse the current text and invoke `onCommitted` only if the parsed value actually changed. |
| [`_handleTap`](#handletap) | method (`_NumberFieldState`) | A | Run the optional one-time edit gate (the weight-sync warning) before letting the field focus. |
| `_NumberFieldState.build` | method (widget helper) | B | Render the `TextField`, optionally wrapped in a tap-gating `GestureDetector`/`AbsorbPointer`. |

`grep -c 'Purpose:' lib/features/intimacy/widgets/body_section.dart` reports 34. This page lists 35
declarations: all 34 `/// Purpose:` blocks sit directly above the real declaration they document (no
misattached blocks found), plus one undocumented real declaration — `_profile` (line 101), a plain
getter (`BodyProfile get _profile => widget.profile ?? const BodyProfile();`) with no doc comment at
all. Tier split: 18 Tier A, 17 Tier B.

**Reconciliation:** `grep -c 'Purpose:' lib/features/intimacy/widgets/body_section.dart` reports 34, matching 34 of the 35 rows above exactly. The extra row is `bodyWeightSyncWarningDisabledKey`, a top-level `const String` holding the local-only `storage_config.json` key: no `Purpose:` block, but a real declaration read from two places, so it is listed.

## Documentation

### `Color cyclePersonColor({required String? personId, required List<String> allPartnerIdsSorted})` <a id="cyclepersoncolor"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 33)
- **Purpose:** Pick the stable palette color used for one person's cycle indicators everywhere in
  the app (Body tab calendar, home-calendar overlay).
- **Inputs:** `personId` — `null` for the user, otherwise a partner id; `allPartnerIdsSorted` — every
  partner id, pre-sorted, used to derive a stable slot for `personId`.
- **Returns:** `Color` — a value from `cyclePersonPalette` (defined in `cycle_calendar.dart`).
- **Side effects:** None.
- **Algorithm:**
  1. If `personId == null` (the user), return `cyclePersonPalette.first` (slot 0).
  2. Otherwise find `personId`'s position in `allPartnerIdsSorted` (`indexOf`, `-1` if absent).
  3. Take `slots = cyclePersonPalette.length - 1` (all slots except the user's).
  4. Return `cyclePersonPalette[1 + ((index < 0 ? 0 : index) % slots)]` — an absent id falls back to
     slot 1 rather than throwing, and ids beyond the palette size wrap around via modulo.
- **Usage:**
  ```dart
  // views/body_page.dart, line 70 (the user's own Body page):
  personColor: cyclePersonColor(personId: null, allPartnerIdsSorted: const []),

  // views/intimacy_page.dart, line 5570 (a partner's Body tab):
  personColor: cyclePersonColor(personId: partner.id, allPartnerIdsSorted: allPartnerIds),
  ```
- **Notes:** Because the slot is based on sorted-id position rather than list order, a person's color
  stays stable even when partners are added/removed or when the visible partner list is filtered
  (e.g. by `showCycleOnCalendar`).

### `void initState()` <a id="initstate"></a>
- **Kind:** method of `_BodySectionViewState` (override of `State.initState`)
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 109)
- **Purpose:** Initialize the displayed measurements — from the Weight module in user mode, or
  directly from `widget.profile` in partner mode.
- **Inputs:** None (reads `widget.mode`, `widget.profile`).
- **Returns:** None.
- **Side effects:** In user mode, kicks off the asynchronous `_loadUserMeasurements()`. In partner
  mode, synchronously sets `_bust`/`_waist`/`_hip` and marks loading complete.
- **Algorithm:**
  1. `super.initState()`.
  2. If `widget.mode == BodySectionMode.user`, call `_loadUserMeasurements()` (fire-and-forget async).
  3. Otherwise copy `_profile.bustCm`/`waistCm`/`hipCm` straight into local state and set
     `_weightLoaded = true` immediately (no async load needed for a partner profile).
- **Usage:**
  ```dart
  // views/body_page.dart, line 66 (constructing the widget triggers initState via the framework):
  BodySectionView(
    mode: BodySectionMode.user,
    profile: _userBody,
    personId: null,
    personColor: cyclePersonColor(personId: null, allPartnerIdsSorted: const []),
    ...
  ),
  ```
- **Notes:** Partner mode never touches `WeightStorage` — this is the split point that keeps the
  user's own measurements (which live in the Weight module) and a partner's measurements (which live
  on `Partner.body`) from ever crossing over.

### `void dispose()` <a id="dispose"></a>
- **Kind:** method of `_BodySectionViewState` (override of `State.dispose`)
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 127)
- **Purpose:** Make sure a measurement edit made just before the page closes still produces its
  weight record instead of being silently dropped by the debounce timer.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Cancels `_weightCommitTimer`; if a commit was still pending, calls
  `_commitWeightRecord()` fire-and-forget (the widget is already unmounting).
- **Algorithm:**
  1. Cancel `_weightCommitTimer` so it can't fire after disposal.
  2. If `_weightCommitPending`, call `_commitWeightRecord()` without awaiting it — the comment in the
     source notes this is intentional: "the page is going away but the burst must still produce its
     weight record".
  3. `super.dispose()`.
- **Usage:** Invoked automatically by the Flutter framework when a `BodySectionView` is removed from
  the tree (e.g. navigating back from `BodySettingsPage` right after editing a measurement).
- **Notes:** This is the other half of the debounce implemented in `_onMeasurementChanged`: without
  this flush, a user typing a new waist value and immediately backing out of the page within the
  2-second debounce window would lose that edit entirely.

### `Future<void> _loadUserMeasurements()` <a id="loadusermeasurements"></a>
- **Kind:** method of `_BodySectionViewState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 145)
- **Purpose:** Load the user's most recent bust/waist/hip values (independently per field) from
  Weight records, plus the sync-warning opt-out flag.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Reads `weight_data.json` via `WeightStorage.load()` and `storage_config.json` via
  `TodoStorage.readConfig()`; updates `_bust`/`_waist`/`_hip`, their `_persisted*` mirrors,
  `_weightLoadFailed`, `_syncWarningDisabled`, and `_weightLoaded`.
- **Algorithm:**
  1. `WeightStorage.load()`; on any exception, set `_weightLoadFailed = true`, `_weightLoaded = true`,
     and return early — the measurement fields render disabled rather than as misleadingly empty.
  2. Otherwise read `TodoStorage.readConfig()` for the sync-warning flag.
  3. Find the latest record via `_latestRecord`, then call
     `WeightData.effectiveMeasurementsUpTo(records, latest.datetime)` to get each of bust/waist/hip
     independently as its most recent *positive* value up to that datetime (a newer record missing a
     field falls back to an earlier one that has it — this is `WeightData`'s own merge logic, not
     reimplemented here).
  4. Store the result into `_bust`/`_waist`/`_hip` and mirror it into `_persistedBust`/`Waist`/`Hip`
     (the baseline `_commitWeightRecord` restores to on failure).
  5. Set `_syncWarningDisabled` from `config[bodyWeightSyncWarningDisabledKey] == true` and mark
     `_weightLoaded = true`.
- **Usage:**
  ```dart
  // initState, line 112 (user mode only):
  _loadUserMeasurements();
  ```
- **Notes:** All `setState` calls are guarded by `if (!mounted) return;` after each `await`, since the
  widget may be disposed before the load completes.

### `WeightRecord? _latestRecord(List<WeightRecord> records)` <a id="latestrecord"></a>
- **Kind:** method of `_BodySectionViewState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 183)
- **Purpose:** Return the newest weight record by datetime, or `null` if there are none.
- **Inputs:** `records` — the full weight-record list.
- **Returns:** `WeightRecord?`.
- **Side effects:** None.
- **Algorithm:**
  1. Return `null` immediately if `records` is empty.
  2. Copy the list, sort descending by `datetime` (`b.datetime.compareTo(a.datetime)`), and return the
     first element.
- **Usage:**
  ```dart
  // _loadUserMeasurements, line 162:
  final latest = _latestRecord(records);

  // _commitWeightRecord, line 303:
  final latest = _latestRecord(data.records);
  ```
- **Notes:** Matches the ordering used elsewhere on the weight page, so "latest" means the same thing
  in both places.

### `Future<void> _setSyncWarningDisabled(bool disabled)` <a id="setsyncwarningdisabled"></a>
- **Kind:** method of `_BodySectionViewState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 195)
- **Purpose:** Persist the "don't remind me again" opt-out for the weight-sync warning.
- **Inputs:** `disabled` — the new opt-out state.
- **Returns:** `Future<void>`.
- **Side effects:** Updates `_syncWarningDisabled`/`_syncWarningAcknowledged` in state; writes
  `bodyWeightSyncWarningDisabledKey` into `storage_config.json` (local-only, never synced).
- **Algorithm:**
  1. `setState` to update `_syncWarningDisabled`; if re-enabling (`!disabled`), also clear
     `_syncWarningAcknowledged` so the warning reappears on the next edit.
  2. Read the config, set the key, write it back.
- **Usage:**
  ```dart
  // _buildWarningSettingCard, line 1012 (the bottom switch):
  SwitchListTile(
    value: _syncWarningDisabled,
    onChanged: _setSyncWarningDisabled,
    ...
  ),
  ```
- **Notes:** Also called from inside `_confirmWeightSync` when the user checks "don't remind me
  again" in the warning dialog itself.

### `Future<bool> _confirmWeightSync()` <a id="confirmweightsync"></a>
- **Kind:** method of `_BodySectionViewState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 210)
- **Purpose:** Gate the first bust/waist/hip edit in a visit behind a warning that editing these
  fields creates a new Weight-module record.
- **Inputs:** None.
- **Returns:** `Future<bool>` — `true` once editing may proceed.
- **Side effects:** May show an `AlertDialog` with a "don't remind me again" checkbox; may call
  `_setSyncWarningDisabled(true)`.
- **Algorithm:**
  1. If `_syncWarningDisabled` or `_syncWarningAcknowledged` is already true, return `true`
     immediately (gate already passed for this visit, or opted out permanently).
  2. Otherwise show a dialog with the warning text and a checkbox bound to a local `dontRemind` flag.
  3. If the user confirms: set `_syncWarningAcknowledged = true` (so the gate doesn't re-show for the
     rest of this visit even without opting out permanently); if `dontRemind` was checked, also persist
     the permanent opt-out via `_setSyncWarningDisabled(true)`. Return `true`.
  4. If the user cancels, return `false`.
- **Usage:**
  ```dart
  // _buildMeasurementsCard, line 491 (passed as the field's edit gate, user mode only):
  _NumberField(
    label: l10n.weightBust,
    value: _bust,
    enabled: !_weightLoadFailed,
    beforeEdit: isUser ? _confirmWeightSync : null,
    onCommitted: (v) => _onMeasurementChanged(() => _bust = v),
  ),
  ```
- **Notes:** Only wired up for bust/waist/hip in user mode — partner-mode fields and every other
  user-mode field (underbust, PSI measurements) pass `beforeEdit: null`.

### `void _onMeasurementChanged(void Function() apply)` <a id="onmeasurementchanged"></a>
- **Kind:** method of `_BodySectionViewState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 262)
- **Purpose:** Apply a bust/waist/hip mutation and, in user mode, debounce it into a single new
  Weight record instead of writing on every keystroke.
- **Inputs:** `apply` — a closure that mutates the pending `_bust`/`_waist`/`_hip` fields.
- **Returns:** None.
- **Side effects:** In user mode, arms/resets a 2-second `Timer` that eventually calls
  `_commitWeightRecord()`; in partner mode, calls `widget.onProfileChanged` immediately.
- **Algorithm:**
  1. If `mounted`, run `apply()` inside `setState`; otherwise (a commit arriving during route
     teardown, e.g. from a field's own `dispose`) run `apply()` directly without `setState`.
  2. If `widget.mode == BodySectionMode.user`: set `_weightCommitPending = true`, cancel any existing
     `_weightCommitTimer`, and start a new one for `Duration(seconds: 2)` that calls
     `_commitWeightRecord()` — every additional change within that window pushes the commit back out
     by another 2 seconds, so a burst of edits collapses into exactly one weight record.
  3. Otherwise (partner mode): push `_profile.copyWith(...)` for the three fields immediately, with
     `clearXxxCm: v == null` so clearing a field actually removes it rather than storing `null` over a
     stale value.
- **Usage:**
  ```dart
  // _buildMeasurementsCard, line 492:
  onCommitted: (v) => _onMeasurementChanged(() => _bust = v),
  ```
- **Notes:** This is the debounce described in
  [Intimacy — The Body layer](../../../../features/intimacy.md#the-body-layer-v124): "a confirmed
  editing burst debounces into exactly one new `WeightRecord`". Historical weight records are never
  modified by this path — only a new record is appended, by `_commitWeightRecord`.

### `Future<void> _commitWeightRecord()` <a id="commitweightrecord"></a>
- **Kind:** method of `_BodySectionViewState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 298)
- **Purpose:** Append one new `WeightRecord` carrying the currently displayed bust/waist/hip values.
- **Inputs:** None (reads `_bust`/`_waist`/`_hip`).
- **Returns:** `Future<void>`.
- **Side effects:** Appends a record to `weight_data.json` via `WeightStorage.save`; calls
  `AutoSyncService.instance.notifySaved()` on success; existing records and weight settings
  (`height`, reminder config, etc.) are copied through untouched.
- **Algorithm:**
  1. If `!_weightCommitPending`, return immediately (already committed, or superseded by a later call).
  2. Clear the pending flag first, then `WeightStorage.load() ?? WeightData(records: [])`.
  3. Build a new `WeightRecord` reusing `latest?.weight ?? 0` (the record's weight field is untouched
     by this feature; only bust/waist/hip come from the Body page) plus the current
     `_bust`/`_waist`/`_hip`.
  4. Construct a new `WeightData` copying every other field from the loaded data and appending the new
     record, then `WeightStorage.save(next)`.
  5. On any exception: if still `mounted`, `setState` to roll `_bust`/`_waist`/`_hip` back to the
     `_persisted*` values and set `_weightLoadFailed = true`; if not mounted, do the same without
     `setState`. Return without updating `_persisted*` or notifying sync.
  6. On success: update `_persistedBust`/`Waist`/`Hip` to the just-committed values and call
     `AutoSyncService.instance.notifySaved()`.
- **Usage:**
  ```dart
  // _onMeasurementChanged, line 273-275 (the debounce timer body):
  _weightCommitTimer = Timer(const Duration(seconds: 2), () {
    _commitWeightRecord();
  });
  ```
- **Notes:** A failed save disables the fields (via `_weightLoadFailed`) and restores the last known
  good display values, "so partial in-memory state never appears saved" (source comment) — the UI
  never shows an unsaved edit as if it had been persisted.

### `CyclePrediction get _prediction` <a id="prediction"></a>
- **Kind:** getter of `_BodySectionViewState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 360)
- **Purpose:** Compute this person's cycle prediction for the calendar/legend/summary to render.
- **Inputs:** None (reads `_myCycleDays`).
- **Returns:** `CyclePrediction` — `CyclePrediction.empty` if there is no recorded history.
- **Side effects:** None (predictions are recomputed on every access, never cached).
- **Algorithm:**
  1. If `_myCycleDays` is empty, return `CyclePrediction.empty`.
  2. Otherwise find the earliest recorded day (`days.reduce((a, b) => a.isBefore(b) ? a : b)`).
  3. Call `predictCycle(actualStarts: days, windowStart: DateTime(earliest.year, earliest.month - 1,
     1), windowEnd: DateTime.now().add(const Duration(days: 400)))` — see
     [Body Metrics — Cycle prediction](../../../../algorithms/body-metrics.md#cycle-prediction) for
     the full anchoring/phase/fertile-window algorithm.
- **Usage:**
  ```dart
  // _buildCycleCard, line 752:
  final prediction = enabled ? _prediction : CyclePrediction.empty;
  ```
- **Notes:** The window starts a month before the earliest record and extends about 13 months ahead
  of "now", so the single-person calendar (unlike the home calendar) can browse both far into the
  past and future without recomputing per month.

### `void _addCycleStart()` <a id="addcyclestart"></a>
- **Kind:** method of `_BodySectionViewState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 376)
- **Purpose:** Record a period-start day for the person currently selected in the calendar.
- **Inputs:** None (reads `_selectedCycleDate`).
- **Returns:** None.
- **Side effects:** Calls `widget.onCycleRecordsChanged` with an appended `CycleRecord`.
- **Algorithm:**
  1. If no date is selected, or `_myCycleDays` already contains it, return without doing anything
     (silently rejects duplicate starts for the same person/date).
  2. Otherwise append a new `CycleRecord(personId: widget.personId, date:
     CycleRecord.formatDate(date))` to `widget.cycleRecords` and push the new list up.
- **Usage:**
  ```dart
  // _buildCycleCard, line 822-826:
  FilledButton.tonalIcon(
    onPressed: _addCycleStart,
    icon: const Icon(Icons.add, size: 18),
    label: Text(l10n.intimacyCycleAddStart),
  ),
  ```
- **Notes:** New records get their own generated id/`modifiedAt` inside the `CycleRecord` constructor;
  this method only appends, it never mutates an existing record.

### `Future<void> _deleteCycleStart()` <a id="deletecyclestart"></a>
- **Kind:** method of `_BodySectionViewState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 393)
- **Purpose:** Delete the period-start record on the currently selected date, after confirmation.
- **Inputs:** None (reads `_selectedCycleDate`).
- **Returns:** `Future<void>`.
- **Side effects:** Shows the shared `confirmDelete` dialog; calls `widget.onCycleRecordsChanged` with
  the record filtered out.
- **Algorithm:**
  1. Return early if nothing is selected.
  2. Format the date as a localized label and await `confirmDelete(context, label)`; return if declined.
  3. Format the date as the canonical `CycleRecord.formatDate` string and rebuild
     `widget.cycleRecords` excluding the record matching both `personId` and that date string.
- **Usage:**
  ```dart
  // _buildCycleCard, line 815-820:
  TextButton.icon(
    onPressed: _deleteCycleStart,
    icon: const Icon(Icons.delete_outline, size: 18),
    label: Text(l10n.commonDelete),
  ),
  ```
- **Notes:** Deletion (rather than an "undo add") is how a cycle record disappears from sync too —
  see [Three-Way Merge — deletion/union semantics](../../../../algorithms/three-way-merge.md#deletionunion-semantics).

### `String _selectedCycleDateSummary(AppLocalizations l10n, DateTime date, CycleDayInfo? info, bool hasRecord)` <a id="selectedcycledatesummary"></a>
- **Kind:** method of `_BodySectionViewState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 871)
- **Purpose:** Produce the one-line summary shown next to the add/delete-start action button for
  whichever date is selected on the calendar.
- **Inputs:** `l10n`; `date` — the selected date; `info` — that date's `CycleDayInfo`, or `null`;
  `hasRecord` — whether the person has an actual recorded start on that date.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:**
  1. Format `date` as a localized short date (`DateFormat.yMMMd`).
  2. If `hasRecord`, return `"<date> · <actual-start label>"` immediately — an actual record always
     wins over any predicted classification.
  3. If `info == null` (no cycle data at all for that day), return just the date label.
  4. Otherwise build a list of parts: predicted-start label if `info.isPredictedStart`; the phase
     label (`switch` on `menstrual`/`follicular`/`luteal`); the ovulation label if
     `info.isOvulationDay`; the fertile-window label if `info.inFertileWindow`.
  5. Join with `" · "` and append the "estimated" suffix label.
- **Usage:**
  ```dart
  // _buildCycleCard, line 806-811:
  Text(
    _selectedCycleDateSummary(l10n, selected, selectedInfo, selectedHasRecord),
    style: theme.textTheme.bodyMedium,
  ),
  ```
- **Notes:** Every branch except the actual-start case ends with the "estimated" suffix, matching the
  concept doc's note that "predictions are statistical estimates" and must never read as certain.

### `void didUpdateWidget(covariant _NumberField oldWidget)` <a id="didupdatewidget"></a>
- **Kind:** method of `_NumberFieldState` (override of `State.didUpdateWidget`)
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 1080)
- **Purpose:** Keep the displayed text in sync when the parent supplies a new `value` from outside
  (e.g. after a successful commit round-trips a fresh value back down), without clobbering an
  in-progress edit.
- **Inputs:** `oldWidget` — the previous widget configuration (unused beyond the override signature).
- **Returns:** None.
- **Side effects:** May reset `_controller.text` and `_lastCommitted`.
- **Algorithm:**
  1. `super.didUpdateWidget(oldWidget)`.
  2. If `widget.value != _lastCommitted` **and** (`!_focusNode.hasFocus || !widget.enabled`), update
     `_lastCommitted` and reformat `_controller.text` from the new value.
  3. Otherwise leave the controller alone — an actively focused, enabled field's in-progress text is
     never overwritten out from under the user.
- **Usage:** Invoked automatically by the Flutter framework whenever an existing `_NumberField`'s
  `value` parameter changes across a rebuild, e.g. when `_buildMeasurementsCard` rebuilds with a
  freshly-loaded `_bust`.
- **Notes:** The one case this *does* overwrite a focused field is `!widget.enabled` — i.e. a field
  that just got disabled after a failed persistence attempt (`_weightLoadFailed`) still gets its text
  reset to the rolled-back value even while focused, since it's no longer editable anyway.

### `String _format(double? value)` <a id="format"></a>
- **Kind:** method of `_NumberFieldState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 1108)
- **Purpose:** Format a measurement value for display without an unnecessary trailing `.0`.
- **Inputs:** `value` — the value to format, or `null`.
- **Returns:** `String` — empty for `null`.
- **Side effects:** None.
- **Algorithm:**
  1. Return `''` if `value == null`.
  2. Return `value.toInt().toString()` if `value == value.roundToDouble()` (a whole number); otherwise
     `value.toString()`.
- **Usage:**
  ```dart
  // _NumberFieldState.initState, line 1069:
  _controller = TextEditingController(text: _format(widget.value));
  ```
- **Notes:** `null` renders as an empty field rather than a literal `"null"`, keeping every
  measurement genuinely optional.

### `void _onFocusChanged()` <a id="onfocuschanged"></a>
- **Kind:** method of `_NumberFieldState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 1120)
- **Purpose:** Commit the field's current text as soon as it loses focus, instead of waiting for the
  typing-pause debounce.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** May cancel the pending debounce and invoke `_commit()`.
- **Algorithm:** If `!_focusNode.hasFocus`, cancel `_debounce` and call `_commit()`.
- **Usage:**
  ```dart
  // _NumberFieldState.initState, line 1070:
  _focusNode.addListener(_onFocusChanged);
  ```
- **Notes:** Committing on blur means tabbing away from a field (rather than waiting out the 1.5s
  typing-pause timer) still saves the value promptly.

### `void _commit()` <a id="commit"></a>
- **Kind:** method of `_NumberFieldState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 1132)
- **Purpose:** Parse the field's current text and, only if the parsed value actually changed, invoke
  the field's `onCommitted` callback.
- **Inputs:** None (reads `_controller.text`).
- **Returns:** None.
- **Side effects:** May call `widget.onCommitted(parsed)`; updates `_lastCommitted`.
- **Algorithm:**
  1. Trim the text; empty text parses to `null`.
  2. Otherwise `double.tryParse`; if unparsable or negative, return without committing anything (the
     stale invalid text is simply left in place until it becomes valid).
  3. A parsed `0` is normalized to `null` (`parsed = value > 0 ? value : null`) — zero and empty are
     treated as "not recorded" identically.
  4. If `parsed == _lastCommitted`, return (no redundant commit).
  5. Otherwise update `_lastCommitted` and call `widget.onCommitted(parsed)`.
- **Usage:**
  ```dart
  // build, line 1191-1194 (the typing-pause debounce):
  onChanged: (_) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _commit);
  },
  ```
- **Notes:** This is the field-level counterpart to `_onMeasurementChanged`'s 2-second weight-record
  debounce — this one is a 1.5-second per-field text debounce that decides *whether* a commit fires at
  all; `_onMeasurementChanged` then decides *how* a user-mode commit gets batched into a weight record.

### `Future<void> _handleTap()` <a id="handletap"></a>
- **Kind:** method of `_NumberFieldState`
- **Source:** `lib/features/intimacy/widgets/body_section.dart` (line 1152)
- **Purpose:** Run the field's optional one-time edit gate (the weight-sync warning) before allowing
  the field to take focus.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** May show the gate dialog (via `widget.beforeEdit`); requests focus on the field.
- **Algorithm:**
  1. If the gate already passed this visit (`_gatePassed`) or there is no gate (`widget.beforeEdit ==
     null`), request focus immediately and return.
  2. Otherwise `await widget.beforeEdit!()`; if the widget is unmounted or the gate returned `false`,
     stop without focusing.
  3. Otherwise set `_gatePassed = true` and request focus.
- **Usage:**
  ```dart
  // build, line 1198 (only when beforeEdit != null and the field isn't gated-through yet):
  return GestureDetector(
    onTap: _handleTap,
    child: AbsorbPointer(child: field),
  );
  ```
- **Notes:** `_gatePassed` is per-`_NumberFieldState` instance, so each of bust/waist/hip runs the
  warning independently the first time it's tapped in a visit — consistent with the concept doc's
  "the parent dedupes per visit" phrasing meaning the acknowledgement (`_syncWarningAcknowledged` on
  `_BodySectionViewState`), not the per-field gate, is what's actually shared across the three fields.

## Related pages

- [Intimacy — The Body layer](../../../../features/intimacy.md#the-body-layer-v124) — the UI contract
  (auto-save everywhere, weight-sync warning, WHR display, cycle defaults) this file implements.
- [Body Metrics](../../../../algorithms/body-metrics.md) — the bra-size, PSI, and cycle-prediction
  algorithms this file's cards call into (`estimateBraSize`, `calculatePsi`, `predictCycle`).
- [`cycle_calendar.dart`](cycle_calendar.md) — `CycleCalendar`/`CycleLegend`, embedded here for the
  per-person calendar; this file supplies the color both it and the home calendar use via
  `cyclePersonColor`.
- [`body_page.dart`](../views/body_page.md) — hosts this widget in user mode.
- [Three-Way Merge](../../../../algorithms/three-way-merge.md) — cycle-record union/deletion semantics
  referenced by `_deleteCycleStart`.

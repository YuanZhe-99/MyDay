# lib/features/weight/views/weight_page.dart

The Weight feature's single view file: `WeightPage` (the page shell), its `_WeightPageState` (data
loading/saving, summary card, both trend charts, grouped history, reminder settings), the
`_WeightRecordDialog`/`_WeightRecordDialogState` add/edit form, and the `_WeightDataError` blocking
error view shown when `weight_data.json` fails to parse. Model logic
(`calculateBMI`/`calculateWaistHipRatio`/`effectiveMeasurementsUpTo`/`effectiveMeasurementTimeline`)
lives in [`WeightRecord`/`WeightData`](../models/weight_record.md) and is only called from here, not
reimplemented. Persistence goes through [`WeightStorage`](../services/weight_storage.md). Reminder
scheduling/grace-window logic lives in
[`ReminderService`](../../../shared/services/reminder_service.md); this file only edits the
settings that service reads. Week grouping for the history list comes from
[`groupByWeek`/`formatMonthDayRange`](../../../shared/utils/week_grouping.md). The add/edit dialog's
dirty-checking uses the shared
[`UnsavedChangesGuard`/`formSignature`](../../../shared/widgets/unsaved_changes_guard.md) pattern.
See [Weight](../../../../features/weight.md) for the concept-level explanation of measurement
inheritance, the reminder grace window, and BMI/waist-hip-ratio.

Despite being a view file, a large fraction of its declarations are classified Tier A: the summary
statistics (BMI, weight change, tracking days, recent range), both EWMA-smoothing functions, the
chart axis/interval math, and the add/edit dialog's validation/signature logic all contain real
branching or computation beyond widget composition, per the tiering rule.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`_decimalInputFormatter`](#_decimalinputformatter) | top-level function | A | Create a decimal text input formatter with a fixed precision limit. |
| `WeightPage` (constructor) | constructor (`WeightPage`) | B | Create a weight page instance. |
| `WeightPage.createState` | method (`WeightPage`) | B | Create the `_WeightPageState`. |
| `_WeightPageState.initState` | method (`_WeightPageState`) | B | Kick off `_loadData` and subscribe to local-data-changed notifications. |
| `_WeightPageState.dispose` | method (`_WeightPageState`) | B | Unsubscribe from local-data-changed notifications. |
| [`_loadData`](#_loaddata) | method (`_WeightPageState`) | A | Load `weight_data.json` into state, or surface a blocking read error. |
| [`_saveData`](#_savedata) | method (`_WeightPageState`) | A | Persist current state as `WeightData` and notify sync/reminder services. |
| [`_latestRecord`](#_latestrecord) | getter (`_WeightPageState`) | A | Return the most recently dated record. |
| [`_currentBMI`](#_currentbmi) | getter (`_WeightPageState`) | A | Compute BMI from the latest record's weight and the stored height. |
| [`_weightChange`](#_weightchange) | getter (`_WeightPageState`) | A | Compute weight change across the selected chart range. |
| [`_trackingDays`](#_trackingdays) | getter (`_WeightPageState`) | A | Compute the day span covered by the selected chart range. |
| [`_recentRange`](#_recentrange) | getter (`_WeightPageState`) | A | Compute the min/max weight over the 7 most recent records. |
| `build` | method (`_WeightPageState`) | B | Build the scaffold: app bar, loading/error/empty/content body, add FAB. |
| `_buildEmptyState` | method (widget helper) | B | Render the "no records yet" placeholder with a set-height shortcut. |
| `_buildContent` | method (widget helper) | B | Compose the summary card, chart section, and records list. |
| `_buildSummaryCard` | method (widget helper) | B | Render the weight/BMI/measurement/waist-hip-ratio summary card. |
| [`_latestMeasurementStats`](#_latestmeasurementstats) | method (`_WeightPageState`) | A | Turn effective bust/waist/hip values into display label/value pairs. |
| `_buildStatLabel` | method (widget helper) | B | Render one label-over-value stat cell, with optional trailing widget. |
| [`_buildBMIBar`](#_buildbmibar) | method (`_WeightPageState`) | A | Build the BMI category bar (underweight/normal/overweight/obese). |
| [`_buildWaistHipRatioBar`](#_buildwaisthipratiobar) | method (`_WeightPageState`) | A | Build the waist-hip-ratio category bar. |
| `_buildSegmentedScaleBar` | method (widget helper) | B | Render a generic colored-segment bar with a position marker. |
| `_buildChartSection` | method (widget helper) | B | Render the range-picker chips, legends, and both trend charts. |
| `_buildChartLegendItem` | method (widget helper) | B | Render one solid/dashed line-color legend entry. |
| [`_chartRecords`](#_chartrecords) | getter (`_WeightPageState`) | A | Filter and sort records to those within the selected chart range. |
| `_buildChart` | method (widget helper) | B | Render the raw + EWMA weight `LineChart`. |
| `_buildMeasurementChart` | method (widget helper) | B | Render the raw + EWMA bust/waist/hip `LineChart`. |
| `_buildDateTitle` | method (widget helper) | B | Render one bottom-axis date label, format chosen by range density. |
| [`_buildMeasurementSpots`](#_buildmeasurementspots) | method (`_WeightPageState`) | A | Build chart spots for one effective measurement field. |
| [`_measurementAxisRange`](#_measurementaxisrange) | method (`_WeightPageState`) | A | Compute a padded centimeter y-axis range for measurement spots. |
| `_buildMeasurementChartLine` | method (widget helper) | B | Build one solid or dashed `LineChartBarData` for a measurement series. |
| [`_buildWeightEwmaSpots`](#_buildweightewmaspots) | method (`_WeightPageState`) | A | Compute EWMA-smoothed weight spots (7-day half-life). |
| [`_buildMeasurementEwmaSpots`](#_buildmeasurementewmaspots) | method (`_WeightPageState`) | A | Compute EWMA-smoothed spots for one effective measurement field. |
| [`_weightInterval`](#_weightinterval) | method (`_WeightPageState`) | A | Pick a readable y-axis interval for the weight chart. |
| [`_measurementInterval`](#_measurementinterval) | method (`_WeightPageState`) | A | Pick a readable y-axis interval for the measurement chart. |
| [`_dateInterval`](#_dateinterval) | method (`_WeightPageState`) | A | Pick a readable x-axis (date) interval based on the data's time span. |
| `_buildRecordsList` | method (widget helper) | B | Render the history header, up to 20 grouped tiles, and a "show all" link. |
| `_buildGroupedRecordTiles` | method (widget helper) | B | Group records by week and render a header + tile per record. |
| `_buildWeekHeader` | method (widget helper) | B | Render one week-group header line. |
| `_buildRecordTile` | method (widget helper) | B | Render one dismissible (swipe-to-delete) history row. |
| [`_formatMeasurements`](#_formatmeasurements) | method (`_WeightPageState`) | A | Format a record's own bust/waist/hip into one history-row string. |
| `_showAllRecords` | method (`_WeightPageState`) | B | Open a draggable bottom sheet listing every record, grouped by week. |
| [`_showReminderSettings`](#_showremindersettings) | method (`_WeightPageState`) | A | Open the reminder settings sheet; owns mode-switch default-time logic. |
| [`_formatReminderGraceHours`](#_formatremindergracehours) | method (`_WeightPageState`) | A | Format the stored grace minutes as a trimmed hours string. |
| `_editReminderGrace` | method (widget helper) | B | Open the grace-window edit dialog. |
| [`_saveReminderGrace`](#_saveremindergrace) | method (`_WeightPageState`) | A | Validate and persist a new reminder grace window (0-24h). |
| [`_addRecord`](#_addrecord) | method (`_WeightPageState`) | A | Open the add-record dialog and, on success, append and persist. |
| [`_editRecord`](#_editrecord) | method (`_WeightPageState`) | A | Open the edit-record dialog and, on success, replace and persist. |
| `_setHeight` | method (widget helper) | B | Open the set-height dialog (delegates validation to nested `saveHeight`). |
| [`saveHeight`](#saveheight) | local function (nested in `_setHeight`) | A | Validate and persist the entered height, then close the dialog. |
| [`_timeSinceLastRecord`](#_timesincelastrecord) | method (`_WeightPageState`) | A | Format the time elapsed since a record's `datetime` as relative text. |
| `_WeightRecordDialog` (constructor) | constructor (`_WeightRecordDialog`) | B | Create a weight record dialog instance (add or edit). |
| `_WeightRecordDialog.createState` | method (`_WeightRecordDialog`) | B | Create the `_WeightRecordDialogState`. |
| `_isEditing` | getter (`_WeightRecordDialogState`) | B | Return whether this dialog is editing an existing record. |
| `_WeightRecordDialogState.initState` | method (`_WeightRecordDialogState`) | B | Initialize controllers from `initialRecord`/`lastWeight` and capture `_initialSignature`. |
| `_WeightRecordDialogState.dispose` | method (`_WeightRecordDialogState`) | B | Dispose all text controllers. |
| `_WeightRecordDialogState.build` | method (`_WeightRecordDialogState`) | B | Build the add/edit form (weight, measurements, note, date, actions). |
| `_hasUnsavedChanges` | method (`_WeightRecordDialogState`) | B | Compare the current signature to the initial one. |
| `_signature` | method (`_WeightRecordDialogState`) | B | Build a `formSignature` snapshot of the form's current field values. |
| `_buildMeasurementField` | method (widget helper) | B | Render one optional bust/waist/hip input field. |
| [`_previewBMI`](#_previewbmi) | getter (`_WeightRecordDialogState`) | A | Compute a live BMI preview from the in-progress weight input. |
| [`_formatInitialMeasurement`](#_formatinitialmeasurement) | method (`_WeightRecordDialogState`) | A | Format a persisted measurement for initial controller text. |
| [`_optionalMeasurement`](#_optionalmeasurement) | method (`_WeightRecordDialogState`) | A | Parse a positive optional measurement from a text controller. |
| [`_submit`](#_submit) | method (`_WeightRecordDialogState`) | A | Validate inputs, build the resulting `WeightRecord`, and pop with it. |
| `_WeightDataError` (constructor) | constructor (`_WeightDataError`) | B | Create a blocking weight-data-read-error view. |
| `_WeightDataError.build` | method (`_WeightDataError`) | B | Render the error message and a retry button. |

`grep -c 'Purpose:' lib/features/weight/views/weight_page.dart` reports 65, matching all 65 real
declarations counted above exactly (31 Tier A, 34 Tier B). Every `/// Purpose:` block sits directly
above the real declaration it documents — no misattached blocks (blocks documenting a call site
instead of a declaration) were found — and no undocumented real declaration exists either: the five
top-level `const Color ...` chart-color constants (lines 20-24) and the `_ChartRange` enum (line 56)
are plain data/type declarations with no behavior, so, consistent with how plain type aliases were
treated in [`weight_record.md`](../models/weight_record.md), they are intentionally not given table
rows. The one nested local function, `saveHeight` inside `_setHeight` (line 1817), does carry its
own `/// Purpose:` block and is counted as a real declaration.

## Documentation

### `TextInputFormatter _decimalInputFormatter(int decimalPlaces)` <a id="_decimalinputformatter"></a>
- **Kind:** top-level function
- **Source:** `lib/features/weight/views/weight_page.dart` (line 31)
- **Purpose:** Build a `TextInputFormatter` that only allows text matching a decimal number with at
  most `decimalPlaces` digits after the point, while still allowing temporary empty/dangling-dot
  input during editing.
- **Inputs:** `decimalPlaces` — maximum digits allowed after the decimal point.
- **Returns:** `TextInputFormatter`.
- **Side effects:** None.
- **Algorithm:**
  1. If the new text is empty, accept it unconditionally (lets the user clear the field).
  2. Otherwise test the new text against `^\d*\.?\d{0,decimalPlaces}$`.
  3. Return the new value if it matches, otherwise reject the edit and keep the old value.
- **Usage:**
  ```dart
  TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [_decimalInputFormatter(1)],
    decoration: InputDecoration(labelText: l10n.weightHeightCm, suffixText: 'cm'),
  )
  ```
  (`_setHeight`, lines 1835-1840; the same formatter with 1 decimal place is reused by
  `_editReminderGrace`, `_buildMeasurementField`, and the dialog's weight field.)
- **Notes:** The regex allows a trailing/dangling `.` (e.g. `"12."`) mid-edit since `\.?` combined
  with `\d{0,decimalPlaces}` permits zero trailing digits — final parsing elsewhere
  (`double.tryParse`) tolerates that.

### `Future<void> _loadData()` <a id="_loaddata"></a>
- **Kind:** async method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 100)
- **Purpose:** Load `weight_data.json` via `WeightStorage.load()` into state, or — if the file exists
  but cannot be parsed — surface a blocking read error instead of silently treating it as an empty
  dataset.
- **Inputs:** None (reads `WeightStorage.load()`).
- **Returns:** `Future<void>`.
- **Side effects:** Calls `setState` (toggles `_loaded`, populates `_height`/`_records`/reminder
  fields, or sets `_loadError`); calls `ReminderService.instance.updateWeightData` either way (with
  an empty record list on error).
- **Algorithm:**
  1. If already loaded and mounted, flip `_loaded` back to `false` (shows the loading spinner while
     a reload from `AutoSyncService`'s local-data-changed notification is in flight).
  2. `await WeightStorage.load()`. On exception: tell `ReminderService` there are no records, guard
     on `mounted`, `setState` to record `_loadError = e.toString()` and `_loaded = true`, then return
     — the error view takes over instead of showing an empty state.
  3. On success (guarded on `mounted`): clear `_loadError`; if `data != null`, copy
     `height`/`records`/`reminderMode` into state and reconstruct `_weightMorningReminder`/
     `_weightEveningReminder` as `TimeOfDay` only when both the stored hour and minute are non-null;
     set `_loaded = true`.
  4. Push the freshly loaded reminder fields into `ReminderService.instance.updateWeightData`.
- **Usage:**
  ```dart
  @override
  void initState() {
    super.initState();
    _loadData();
    AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  }
  ```
  (lines 77-81; also passed as `onRetry: _loadData` to `_WeightDataError`, line 283.)
- **Notes:** A load that throws never falls back to "no records" in the UI — `_loadError` takes
  priority over `_records.isEmpty` in `build`'s body switch (line 280-286), so writes stay disabled
  until the file becomes readable again (see `_saveData`).

### `Future<void> _saveData()` <a id="_savedata"></a>
- **Kind:** async method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 149)
- **Purpose:** Persist the in-memory state as a `WeightData` document, refusing to do so while a
  load is in flight or while the loaded file is known to be unreadable.
- **Inputs:** None (reads current state fields).
- **Returns:** `Future<void>`.
- **Side effects:** May show a `SnackBar` (write-blocked message); calls `WeightStorage.save`;
  calls `ReminderService.instance.updateWeightData`; calls `AutoSyncService.instance.notifySaved()`.
- **Algorithm:**
  1. If `!_loaded`, return immediately (no-op before the first load completes).
  2. If `_loadError != null`, show the `weightDataWriteBlocked` snackbar and return without writing
     — this is what prevents an incomplete in-memory state from overwriting a file that failed to
     parse.
  3. Otherwise build a `WeightData` from current fields, stamping `settingsModifiedAt =
     DateTime.now().toUtc()`, and `await WeightStorage.save(...)`.
  4. Push the same reminder fields to `ReminderService.instance.updateWeightData`.
  5. Call `AutoSyncService.instance.notifySaved()` to trigger the app's auto-sync cycle.
- **Usage:** `await _saveData();` after every mutating action — `_addRecord`, `_editRecord`,
  `saveHeight`, `_saveReminderGrace`, the reminder-mode/time-picker callbacks in
  `_showReminderSettings`, and the swipe-to-delete handler in `_buildRecordTile`.
- **Notes:** Because step 1/2 return silently (aside from the snackbar), a caller that always awaits
  `_saveData()` after a `setState` cannot assume the write actually happened — the guard is
  deliberately silent-by-default so read-only browsing while unreadable doesn't spam the snackbar
  more than once per attempted write.

### `WeightRecord? get _latestRecord` <a id="_latestrecord"></a>
- **Kind:** getter of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 190)
- **Purpose:** Return the record with the most recent `datetime`.
- **Inputs:** None.
- **Returns:** `WeightRecord?` — `null` if `_records` is empty.
- **Side effects:** None.
- **Algorithm:** Copy `_records`, sort descending by `datetime`, return the first element (or
  `null` if the list is empty).
- **Usage:** `final latest = _latestRecord!;` (`_buildContent`, line 337 — only reached once
  `_records.isEmpty` has already been checked false in `build`).
- **Notes:** Re-sorts the full list on every access rather than caching the result; acceptable given
  typical weight-history sizes.

### `double? get _currentBMI` <a id="_currentbmi"></a>
- **Kind:** getter of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 202)
- **Purpose:** Compute BMI from the latest record's weight and the stored height, for the summary
  card.
- **Inputs:** None.
- **Returns:** `double?` — `null` if there is no record, otherwise
  `WeightData.calculateBMI(_height, latest.weight)` (itself `null` if `_height` is unset/`<= 0`; see
  [`WeightData.calculateBMI`](../models/weight_record.md#calculatebmi)).
- **Side effects:** None.
- **Algorithm:** Guard on `_latestRecord == null`, then delegate to `WeightData.calculateBMI`.
- **Usage:** `final bmi = _currentBMI;` (`_buildContent`, line 338, fed into `_buildSummaryCard` and
  from there into `_buildBMIBar`).
- **Notes:** None.

### `double? get _weightChange` <a id="_weightchange"></a>
- **Kind:** getter of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 214)
- **Purpose:** Compute the weight change across the currently selected chart range (e.g. 1M, 3M,
  All).
- **Inputs:** None (reads `_chartRecords`).
- **Returns:** `double?` — `null` if fewer than 2 records fall in the selected range, otherwise
  `data.last.weight - data.first.weight` (chronologically last minus first, so positive means
  gained).
- **Side effects:** None.
- **Algorithm:** Guard on `_chartRecords.length < 2`, then simple subtraction on the
  chronologically-sorted range.
- **Usage:** `final change = _weightChange;` (`_buildContent`, line 339, displayed in the summary
  card with an up/down arrow colored red/blue by sign).
- **Notes:** Depends on the same selected `_chartRange` as the charts, not a fixed window — changing
  the range picker changes what "weight change" means on the summary card too.

### `int? get _trackingDays` <a id="_trackingdays"></a>
- **Kind:** getter of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 225)
- **Purpose:** Compute how many days the selected chart range's records span.
- **Inputs:** None (reads `_chartRecords`).
- **Returns:** `int?` — `null` if fewer than 2 records fall in the selected range, otherwise
  `data.last.datetime.difference(data.first.datetime).inDays`.
- **Side effects:** None.
- **Algorithm:** Guard on length `< 2`, then a plain `DateTime` difference in whole days.
- **Usage:** `final days = _trackingDays;` (`_buildContent`, line 340; shown next to the weight-change
  arrow as `"$days ${l10n.weightDays}"`).
- **Notes:** None.

### `(double, double)? get _recentRange` <a id="_recentrange"></a>
- **Kind:** getter of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 237)
- **Purpose:** Compute the min/max weight over the 7 most recently dated records, independent of the
  chart range picker.
- **Inputs:** None (reads `_records`).
- **Returns:** `(double, double)?` — `null` if there are no records; otherwise `(min, max)` of up to
  the 7 latest records' `weight`.
- **Side effects:** None.
- **Algorithm:** Copy and sort `_records` descending by `datetime`, `take(7)`, then reduce with
  `math.min`/`math.max` over `.weight`.
- **Usage:** `final range = _recentRange;` (`_buildContent`, line 341, rendered as a "Recent" stat
  showing `"min–max"`).
- **Notes:** Unlike `_weightChange`/`_trackingDays`, this always looks at the latest 7 *records*
  (not the selected chart range), so it stays stable regardless of which range chip is selected.

### `List<(String, String)> _latestMeasurementStats(EffectiveWeightMeasurements measurements, AppLocalizations l10n)` <a id="_latestmeasurementstats"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 520)
- **Purpose:** Turn the effective (inherited) bust/waist/hip values into localized `(label, value)`
  pairs for the summary card, omitting any field that has no current inherited value.
- **Inputs:** `measurements` — an `EffectiveWeightMeasurements` record from
  [`WeightData.effectiveMeasurementsUpTo`](../models/weight_record.md#effectivemeasurementsupto);
  `l10n`.
- **Returns:** `List<(String, String)>` — zero to three pairs, each `"${value.toStringAsFixed(1)}
  cm"`.
- **Side effects:** None.
- **Algorithm:** A list literal with one `if (field != null)` entry per bust/waist/hip field, in that
  order.
- **Usage:** `final measurements = _latestMeasurementStats(effectiveMeasurements, l10n);`
  (`_buildSummaryCard`, line 388, feeding a `_buildStatLabel` per pair via a `for` loop).
- **Notes:** This only omits fields absent from the already-inherited `measurements` value — the
  inheritance itself (falling back to the last positive value from an earlier record) is done by
  `effectiveMeasurementsUpTo`, not here. See
  [Weight](../../../../features/weight.md#bustwaisthip-inheritance-from-the-latest-positive-value).

### `Widget _buildBMIBar(ThemeData theme, double bmi)` <a id="_buildbmibar"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 586)
- **Purpose:** Render a compact 4-segment color bar (underweight/normal/overweight/obese) with a
  marker at the given BMI's position.
- **Inputs:** `theme`; `bmi`.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:**
  1. Map `bmi` to a normalized `0.0-1.0` position via `((bmi - 15) / 25).clamp(0.0, 1.0)` — so the
     visible scale spans BMI 15 to 40.
  2. Delegate to `_buildSegmentedScaleBar` with four segments sized `7:6:5:7` (blue/green/orange/red)
     out of 25 total flex units — i.e. the segment boundaries fall at roughly BMI 22 (blue→green,
     the underweight/normal boundary at ~18.5 is *not* separately marked; the flex ratios are a
     visual approximation, not an exact 18.5/25/30 mapping) and the marker position.
- **Usage:**
  ```dart
  if (bmi != null)
    _buildStatLabel(theme, 'BMI', bmi.toStringAsFixed(1), trailing: _buildBMIBar(theme, bmi)),
  ```
  (`_buildSummaryCard`, lines 400-406.)
- **Notes:** The comment at line 587 states the intended clinical boundaries (`<18.5 underweight,
  18.5-25 normal, 25-30 overweight, 30+ obese`), but the actual segment `flex` values (`7, 6, 5, 7`
  out of a `(bmi-15)/25` scale) are a fixed visual approximation rather than a computed mapping of
  those exact thresholds onto the 15-40 scale.

### `Widget _buildWaistHipRatioBar(ThemeData theme, double ratio)` <a id="_buildwaisthipratiobar"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 602)
- **Purpose:** Render a compact 4-segment color bar for waist-hip ratio risk category, with a marker
  at the given ratio's position.
- **Inputs:** `theme`; `ratio`.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:**
  1. Map `ratio` to a normalized position via `((ratio - 0.65) / 0.45).clamp(0.0, 1.0)` — visible
     scale spans ratio 0.65 to 1.10.
  2. Delegate to `_buildSegmentedScaleBar` with four segments sized `15:10:10:10`
     (green/orange/deepOrange/red) out of 45 total flex units, placing category boundaries at
     roughly 0.80, 0.90, and 1.00 on the 0.65-1.10 scale — matching the "universal visual thresholds"
     noted in the source comment.
- **Usage:**
  ```dart
  if (waistHipRatio != null)
    _buildStatLabel(theme, l10n.weightWaistHipRatio, waistHipRatio.toStringAsFixed(2),
        trailing: _buildWaistHipRatioBar(theme, waistHipRatio)),
  ```
  (`_buildSummaryCard`, lines 409-415; `waistHipRatio` itself comes from
  [`WeightData.calculateWaistHipRatio`](../models/weight_record.md#calculatewaisthipratio) fed the
  *effective* (inherited) waist/hip values, not the raw record fields.)
- **Notes:** Like `_buildBMIBar`, the segment flex values are a fixed visual approximation of the
  0.80/0.90/1.00 boundaries, not a computed placement.

### `List<WeightRecord> get _chartRecords` <a id="_chartrecords"></a>
- **Kind:** getter of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 796)
- **Purpose:** Filter `_records` to the currently selected chart range (`_chartRange`) and sort them
  chronologically for chart rendering.
- **Inputs:** None (reads `_records`, `_chartRange`).
- **Returns:** `List<WeightRecord>`, ascending by `datetime`.
- **Side effects:** None.
- **Algorithm:**
  1. Compute a `cutoff` `DateTime` via a `switch` on `_chartRange`: `oneWeek` → now minus 7 days;
     `oneMonth`/`threeMonths`/`sixMonths`/`oneYear` → calendar month/year arithmetic on `now`
     (`DateTime(now.year, now.month - N, now.day)`, which `DateTime` normalizes for negative months);
     `all` → the year 2000 (effectively no cutoff for this app's data).
  2. Filter to `r.datetime.isAfter(cutoff)`, then sort ascending by `datetime`.
- **Usage:** `final data = _chartRecords;` (`_buildChart` line 817, `_buildMeasurementChart` line
  956, and indirectly via `_weightChange`/`_trackingDays`).
- **Notes:** Uses `isAfter(cutoff)` (strictly after), so a record exactly at the cutoff instant would
  be excluded — in practice irrelevant since cutoffs are computed from `DateTime.now()` at render
  time, not from a stored boundary value.

### `List<FlSpot> _buildMeasurementSpots(List<EffectiveWeightMeasurementPoint> data, double? Function(EffectiveWeightMeasurementPoint point) selectValue)` <a id="_buildmeasurementspots"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1168)
- **Purpose:** Convert one effective-measurement timeline into raw (non-smoothed) chart spots for a
  single field (bust, waist, or hip), skipping points where that field has no inherited value yet.
- **Inputs:** `data` — an effective-measurement timeline (already inheritance-resolved, see
  [`WeightData.effectiveMeasurementTimeline`](../models/weight_record.md#effectivemeasurementtimeline));
  `selectValue` — a field-selector callback (e.g. `(point) => point.bustCm`).
- **Returns:** `List<FlSpot>` — one spot per point where `selectValue(point)` is non-null, `x` in
  epoch milliseconds.
- **Side effects:** None.
- **Algorithm:** `data.map(...)` builds an `FlSpot` or `null` per point depending on
  `selectValue(point)`, then `.whereType<FlSpot>()` drops the nulls.
- **Usage:**
  ```dart
  final bustSpots = _buildMeasurementSpots(visibleTimeline, (point) => point.bustCm);
  ```
  (`_buildMeasurementChart`, lines 971-982, called once per field against a timeline already
  filtered to the visible cutoff.)
- **Notes:** Because the input timeline already carries inherited values (from
  `effectiveMeasurementTimeline`), a point is only skipped here if the field has *never* had an
  explicit positive value up to that point — not merely because the current record omitted it.

### `(double, double) _measurementAxisRange(List<FlSpot> spots)` <a id="_measurementaxisrange"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1190)
- **Purpose:** Compute a padded y-axis range (in cm) across all bust/waist/hip (raw + EWMA) spots so
  near-identical measurements remain visually distinguishable.
- **Inputs:** `spots` — the combined list of all measurement-chart spots (raw and EWMA, all three
  fields).
- **Returns:** `(double, double)` — `(0, 1)` if `spots` is empty; otherwise `(low, maxCm + pad)`.
- **Side effects:** None.
- **Algorithm:**
  1. `minCm`/`maxCm` via `reduce(math.min)`/`reduce(math.max)` over all spot `y` values.
  2. `pad = max((maxCm - minCm) * 0.15, 2.0)` — at least 2 cm of padding even when the range is
     nearly flat.
  3. `low = max(0, minCm - pad)` (never goes negative); high bound is `maxCm + pad`.
- **Usage:** `final (minY, maxY) = _measurementAxisRange(allSpots);` (`_buildMeasurementChart`, line
  1020, where `allSpots` concatenates raw and EWMA spots for all three fields so the shared axis
  fits every line).
- **Notes:** The minimum 2 cm padding is what keeps the chart usable when bust/waist/hip barely
  change over the visible range — without it, a near-zero `(maxCm - minCm)` would produce a
  vanishingly thin (or degenerate) axis band.

### `List<FlSpot> _buildWeightEwmaSpots(List<WeightRecord> allData, DateTime visibleFrom, {double halfLifeDays = 7})` <a id="_buildweightewmaspots"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1228)
- **Purpose:** Compute an exponentially-weighted moving average (EWMA) of weight with a configurable
  half-life, warming up over the *full* record history but only emitting spots from `visibleFrom`
  onward.
- **Inputs:** `allData` — **all** records sorted oldest→newest (not just the visible range: this is
  required for warm-up accuracy); `visibleFrom` — the first datetime to actually emit a spot for;
  `halfLifeDays` — defaults to 7.
- **Returns:** `List<FlSpot>`, one per record on or after `visibleFrom`, `x` in epoch milliseconds,
  `y` the running EWMA value.
- **Side effects:** None.
- **Algorithm:**
  1. Return `[]` if `allData` is empty.
  2. `tau = halfLifeDays * 86400 * 1000` (half-life in milliseconds).
  3. Seed `ewma = allData.first.weight`, `prevTime = allData.first.datetime`.
  4. For each record `r` in chronological order: compute the elapsed time `dtMs` since `prevTime`;
     `alpha = 1 - exp(-dtMs / tau)` (a time-adaptive smoothing factor — larger gaps between records
     push `alpha` closer to 1, weighting the new value more heavily); update
     `ewma = alpha * r.weight + (1 - alpha) * ewma`; if `r.datetime` is on/after `visibleFrom`, emit
     a spot at the updated `ewma`; advance `prevTime = r.datetime`.
- **Usage:**
  ```dart
  final allSorted = List<WeightRecord>.from(_records)
    ..sort((a, b) => a.datetime.compareTo(b.datetime));
  final ewmaSpots = _buildWeightEwmaSpots(allSorted, data.first.datetime);
  ```
  (`_buildChart`, lines 834-836 — `allSorted` is the *entire* record history, while
  `data.first.datetime` is only the start of the currently selected chart range, so switching chart
  ranges changes the visible window without restarting the smoothing.)
- **Notes:** Because `alpha` depends on the actual gap since the previous record rather than a fixed
  per-tick rate, irregular logging intervals (e.g. daily for a week, then a two-week gap) are handled
  correctly — a long gap lets the new value dominate almost completely (`alpha → 1`) rather than
  being diluted as if it were one more evenly-spaced sample. The same EWMA pattern (time-adaptive
  `alpha = 1 - exp(-dt/tau)`) also appears independently in
  `lib/features/intimacy/views/intimacy_page.dart`.

### `List<FlSpot> _buildMeasurementEwmaSpots(List<EffectiveWeightMeasurementPoint> allData, DateTime visibleFrom, double? Function(EffectiveWeightMeasurementPoint point) selectValue, {double halfLifeDays = 7})` <a id="_buildmeasurementewmaspots"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1255)
- **Purpose:** The same EWMA smoothing as `_buildWeightEwmaSpots`, applied to one effective
  measurement field (bust, waist, or hip) instead of weight, skipping points before that field's
  first inherited value.
- **Inputs:** `allData` — the full effective-measurement timeline; `visibleFrom`; `selectValue` —
  field selector; `halfLifeDays` — defaults to 7.
- **Returns:** `List<FlSpot>`.
- **Side effects:** None.
- **Algorithm:** Same time-adaptive EWMA recurrence as `_buildWeightEwmaSpots`
  (`alpha = 1 - exp(-dtMs/tau)`), with two differences: (1) `ewma`/`prevTime` start `null` and are
  seeded on the *first* point where `selectValue(point)` is non-null (points before that are
  skipped via `continue`, neither updating nor resetting the running average); (2) once seeded, a
  point with a null value is impossible to reach again here because `effectiveMeasurementTimeline`
  already forward-fills every field once it has appeared once — see
  [`WeightData.effectiveMeasurementTimeline`](../models/weight_record.md#effectivemeasurementtimeline).
- **Usage:**
  ```dart
  final bustEwmaSpots = _buildMeasurementEwmaSpots(timeline, cutoff, (point) => point.bustCm);
  ```
  (`_buildMeasurementChart`, lines 983-997, called once per field against the *full* `timeline`,
  paralleling how `_buildWeightEwmaSpots` is fed the full record history rather than only the
  visible range.)
- **Notes:** None beyond what's stated in `_buildWeightEwmaSpots`'s notes.

### `double _weightInterval(double range)` <a id="_weightinterval"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1294)
- **Purpose:** Pick a readable y-axis grid/label interval (in kg) for the weight chart based on the
  visible weight span.
- **Inputs:** `range` — `maxWeight - minWeight` over the visible data.
- **Returns:** `double` — `0.5` if `range <= 2`; `1` if `<= 5`; `2` if `<= 10`; else `5`.
- **Side effects:** None.
- **Algorithm:** Sequential threshold checks, first match wins.
- **Usage:** `horizontalInterval: _weightInterval(maxW - minW)` and
  `interval: _weightInterval(maxW - minW)` (`_buildChart`, lines 849 and 882, for grid lines and the
  left-axis labels respectively).
- **Notes:** None.

### `double _measurementInterval(double range)` <a id="_measurementinterval"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1306)
- **Purpose:** Pick a readable y-axis interval (in cm) for the measurement chart, sparser than the
  weight chart's since bust/waist/hip spans are typically larger.
- **Inputs:** `range` — the y-axis span from `_measurementAxisRange`.
- **Returns:** `double` — `1` if `range <= 5`; `2` if `<= 10`; `5` if `<= 25`; else `10`.
- **Side effects:** None.
- **Algorithm:** Sequential threshold checks, first match wins.
- **Usage:** `horizontalInterval: _measurementInterval(maxY - minY)` (`_buildMeasurementChart`, lines
  1027 and 1054).
- **Notes:** None.

### `double _dateInterval(List<WeightRecord> data)` <a id="_dateinterval"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1318)
- **Purpose:** Pick a readable x-axis (date) label interval, in milliseconds, based on the total time
  span of the visible data — from every-3-days for a week-long span up to 2-year labels for
  multi-year spans.
- **Inputs:** `data` — the visible (already range-filtered) record list.
- **Returns:** `double` — milliseconds between axis labels; `1` (millisecond, effectively "always
  label") if fewer than 2 records.
- **Side effects:** None.
- **Algorithm:** Compute `spanDays` from `data.first`/`data.last` datetimes, then a sequential
  threshold ladder in days → interval-in-days-as-ms: `≤7→3d, ≤30→10d, ≤90→30d, ≤180→60d, ≤365→120d,
  ≤730→240d, ≤1825→365d (annual), else→730d (2-year)`.
- **Usage:** `interval: _dateInterval(data)` (`_buildChart` line 865, `_buildMeasurementChart` line
  1043) — both charts share the same date-interval logic since they share the same `_chartRecords`
  range.
- **Notes:** None.

### `String? _formatMeasurements(WeightRecord record, AppLocalizations l10n)` <a id="_formatmeasurements"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1503)
- **Purpose:** Format a single history record's *own* (non-inherited) bust/waist/hip fields into one
  slash-separated string for the history-row subtitle.
- **Inputs:** `record`; `l10n`.
- **Returns:** `String?` — `null` if none of the three fields are present and positive.
- **Side effects:** None.
- **Algorithm:** Build a list of `"${label} ${value.toStringAsFixed(1)} cm"` entries, each guarded by
  `field != null && field! > 0`; return `null` if empty, else `parts.join(' / ')`.
- **Usage:** `final measurements = _formatMeasurements(record, l10n);` (`_buildRecordTile`, line
  1447, spliced into the subtitle line via the null-aware spread `?measurements`).
- **Notes:** Unlike `_latestMeasurementStats` (which shows *inherited* values on the summary card),
  this reads the record's own fields directly — a history row for a record that didn't log waist
  simply omits waist, it does not show an inherited value from an earlier record.

### `Future<void> _showReminderSettings()` <a id="_showremindersettings"></a>
- **Kind:** async method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1549)
- **Purpose:** Open the reminder settings bottom sheet, and own the mode-switch logic that decides
  what happens to the morning/evening reminder times when the reminder mode changes.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Shows a modal bottom sheet; on mode/time changes: `setState`, then
  `setSheetState(() {})` to rebuild the sheet in place, then `_saveData()`.
- **Algorithm:** The sheet renders a `RadioGroup<String>` over `'none'`/`'once'`/`'twice'`. Its
  `onChanged` callback is the real logic:
  1. `setState(() => _reminderMode = value)`, then a `switch (value)`:
     - `'none'` → clear both `_weightMorningReminder` and `_weightEveningReminder`.
     - `'once'` → set `_weightMorningReminder ??= 08:00` (only if unset) and clear
       `_weightEveningReminder`.
     - `'twice'` → set `_weightMorningReminder ??= 08:00` and `_weightEveningReminder ??= 21:00`
       (both only if unset).
  2. `setSheetState({})` to rebuild the sheet (so the morning/evening `ListTile`s appear/disappear
     immediately), then `_saveData()`.
  3. The morning/evening `ListTile.onTap` handlers separately call `showTimePicker` and, on a picked
     result, `setState`/`setSheetState`/`_saveData()` the same way.
- **Usage:**
  ```dart
  IconButton(
    icon: Icon(_reminderMode != 'none' ? Icons.notifications_active : Icons.notifications_none),
    tooltip: l10n.weightReminder,
    onPressed: _loaded && _loadError == null ? _showReminderSettings : null,
  )
  ```
  (`build`, lines 262-272, the app bar's reminder-bell action.)
- **Notes:** Using `??=` when switching *into* `'once'`/`'twice'` means an existing morning/evening
  time is preserved across mode toggles (turning reminders off and back on doesn't reset a
  previously chosen time back to the 08:00/21:00 defaults) — only a field with no prior value gets
  the default.

### `String _formatReminderGraceHours()` <a id="_formatremindergracehours"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1691)
- **Purpose:** Format the stored `_reminderGraceMinutes` as a trimmed hours string for display/edit
  (whole number when exact, one decimal place otherwise).
- **Inputs:** None (reads `_reminderGraceMinutes`).
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** `hours = _reminderGraceMinutes / 60`; if `hours` is already a whole number, format
  as an integer (`hours.toInt().toString()`); otherwise `hours.toStringAsFixed(1)`.
- **Usage:** `TextEditingController(text: _formatReminderGraceHours())` (`_editReminderGrace`, line
  1708, seeding the edit field) and
  `l10n.weightReminderSkipWindowValue(_formatReminderGraceHours())` (`_showReminderSettings`, line
  1670, the settings-sheet subtitle).
- **Notes:** The default `_reminderGraceMinutes` is 180 (3 hours), so this formats to `"3"` out of
  the box rather than `"3.0"`. See [Weight](../../../../features/weight.md#reminder-grace-window)
  for what the grace window itself does.

### `void _saveReminderGrace(BuildContext dialogContext, TextEditingController controller, StateSetter setSheetState)` <a id="_saveremindergrace"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1748)
- **Purpose:** Validate the entered hours value and, if valid, persist it as the new
  `_reminderGraceMinutes`.
- **Inputs:** `dialogContext`; `controller` — holds the entered hours text; `setSheetState` — rebuild
  callback for the parent reminder-settings sheet.
- **Returns:** None.
- **Side effects:** Pops `dialogContext`; `setState`; calls `setSheetState(() {})`; calls
  `_saveData()`.
- **Algorithm:**
  1. Parse `controller.text.trim()` via `double.tryParse`.
  2. If parsing failed, or the value is `< 0` or `> 24`, return without doing anything (dialog stays
     open, nothing is saved) — this is the validation the outer `_editReminderGrace` dialog itself
     does not perform.
  3. Otherwise pop the dialog, `setState(() => _reminderGraceMinutes = (hours * 60).round())`,
     rebuild the sheet, and persist via `_saveData()`.
- **Usage:**
  ```dart
  FilledButton(
    onPressed: () => _saveReminderGrace(dialogContext, controller, setSheetState),
    child: Text(l10n.commonSave),
  )
  ```
  (`_editReminderGrace`, lines 1731-1736; also wired to the field's `onSubmitted`, line 1723.)
- **Notes:** The valid range is a hard `[0, 24]` hours — entering `25` or a negative number silently
  leaves the dialog open with no feedback beyond the value simply not being accepted.

### `Future<void> _addRecord()` <a id="_addrecord"></a>
- **Kind:** async method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1766)
- **Purpose:** Open the add-record dialog and, if the user saves a new record, append it to state
  and persist.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Shows `_WeightRecordDialog`; on a non-null result, `setState` appends to
  `_records` and calls `_saveData()`.
- **Algorithm:** `await showDialog<WeightRecord>` with a `_WeightRecordDialog(height: _height,
  lastWeight: _latestRecord?.weight)` (no `initialRecord`, so the dialog is in add mode); if the
  dialog returned a record (i.e. wasn't cancelled/discarded), `setState(() =>
  _records.add(result))` then `await _saveData()`.
- **Usage:**
  ```dart
  floatingActionButton: FloatingActionButton(
    onPressed: _loaded && _loadError == null ? _addRecord : null,
    child: const Icon(Icons.add),
  )
  ```
  (`build`, lines 287-290.)
- **Notes:** Passes `_latestRecord?.weight` as `lastWeight` so the dialog can pre-fill the weight
  field with the previous entry (see `_WeightRecordDialogState.initState`).

### `Future<void> _editRecord(WeightRecord record)` <a id="_editrecord"></a>
- **Kind:** async method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1785)
- **Purpose:** Open the edit dialog for an existing record and, on save, replace it in place while
  keeping its original `id`.
- **Inputs:** `record` — the record being edited.
- **Returns:** `Future<void>`.
- **Side effects:** Shows `_WeightRecordDialog`; on a non-null result, `setState` replaces the
  matching record and calls `_saveData()`.
- **Algorithm:** `await showDialog<WeightRecord>` with `_WeightRecordDialog(height: _height,
  initialRecord: record)`; if a result came back, find `_records.indexWhere((item) => item.id ==
  record.id)` and, if found (`index >= 0`), overwrite `_records[index] = result`; then
  `await _saveData()`.
- **Usage:** `onTap: () => _editRecord(record)` (`_buildRecordTile`, line 1493).
- **Notes:** The dialog's own `_submit` uses `initialRecord?.copyWith(...)`, which preserves the
  original `id` and regenerates `modifiedAt` — this method's `indexWhere` match on `id` relies on
  that being unchanged.

### `void saveHeight(UnsavedChangesController guard)` <a id="saveheight"></a>
- **Kind:** local function nested inside `_WeightPageState._setHeight`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1817)
- **Purpose:** Validate the entered height and, if valid, persist it and close the set-height
  dialog.
- **Inputs:** `guard` — the `UnsavedChangesController` for the enclosing `UnsavedChangesGuard`.
- **Returns:** None.
- **Side effects:** Pops the dialog via `guard.pop()`; `setState(() => _height = val)`; calls
  `_saveData()`.
- **Algorithm:** Parse `controller.text.trim()` via `double.tryParse`; if the result is non-null and
  `> 0`, pop the dialog, update `_height`, and save; otherwise do nothing (dialog stays open).
- **Usage:**
  ```dart
  FilledButton(
    onPressed: () => saveHeight(guard),
    child: Text(l10n.commonSave),
  )
  ```
  (`_setHeight`, lines 1850-1853; also wired to the height field's `onSubmitted`, line 1842.)
- **Notes:** Defined inside `_setHeight` specifically to close over `controller` and the enclosing
  `context`/`l10n`, rather than being a `_WeightPageState` method that would need them passed in.

### `String _timeSinceLastRecord(DateTime dt, AppLocalizations l10n)` <a id="_timesincelastrecord"></a>
- **Kind:** method of `_WeightPageState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 1865)
- **Purpose:** Format the elapsed time since a record's `datetime` as short relative text ("Today",
  "Yesterday", "N days ago", "N weeks ago").
- **Inputs:** `dt`; `l10n`.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** `diff = DateTime.now().difference(dt)`; sequential checks: `inDays == 0` →
  `weightToday`; `== 1` → `weightYesterday`; `< 7` → `"${diff.inDays} ${weightDaysAgo}"`; otherwise
  integer-divide by 7 and return `"$weeks ${weightWeeksAgo}"`.
- **Usage:** `final timeSince = _timeSinceLastRecord(latest.datetime, l10n);` (`_buildContent`, line
  342, shown at the top of the summary card).
- **Notes:** Weeks are always rounded down (`~/  7`) with no "N months ago" tier — a record from 10
  weeks ago reads as `"10 weeks ago"` rather than switching to a months-based phrasing.

### `double? get _previewBMI` <a id="_previewbmi"></a>
- **Kind:** getter of `_WeightRecordDialogState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 2151)
- **Purpose:** Compute a live BMI preview from the weight text currently being typed into the
  add/edit dialog, using the height passed in from the page.
- **Inputs:** None (reads `_weightController.text` and `widget.height`).
- **Returns:** `double?` — `null` if the current weight text doesn't parse to a positive number, or
  if `WeightData.calculateBMI` itself returns `null` (no height).
- **Side effects:** None.
- **Algorithm:** `double.tryParse(_weightController.text.trim())`; guard on `null`/`<= 0`; delegate to
  `WeightData.calculateBMI(widget.height, w)`.
- **Usage:**
  ```dart
  final bmi = _previewBMI;
  // ...
  decoration: InputDecoration(
    labelText: l10n.weightKg,
    suffixText: l10n.weightUnitKg,
    helperText: bmi != null ? 'BMI: ${bmi.toStringAsFixed(1)}' : null,
  ),
  ```
  (`build`, lines 1967 and 1992-1998 — shown as the weight field's helper text, updated live via the
  field's `onChanged: (_) => setState(() {})`.)
- **Notes:** Mirrors `_currentBMI` on the page state, but reads from the in-progress text controller
  instead of the last saved record, so it updates on every keystroke rather than only after saving.

### `String _formatInitialMeasurement(double? value)` <a id="_formatinitialmeasurement"></a>
- **Kind:** method of `_WeightRecordDialogState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 2162)
- **Purpose:** Format a persisted measurement value for seeding a text controller when the dialog
  opens, treating non-positive values as absent.
- **Inputs:** `value` — a persisted `bustCm`/`waistCm`/`hipCm`, or `null`.
- **Returns:** `String` — `''` if `value` is `null` or `<= 0`, otherwise `value.toStringAsFixed(1)`.
- **Side effects:** None.
- **Algorithm:** Single guard clause, then fixed-precision formatting.
- **Usage:**
  ```dart
  _bustController = TextEditingController(text: _formatInitialMeasurement(record?.bustCm));
  ```
  (`initState`, lines 1929-1937, once each for bust/waist/hip.)
- **Notes:** Symmetric with `_optionalMeasurement` (the reverse direction, text → value) — both
  treat non-positive as "not measured."

### `double? _optionalMeasurement(TextEditingController controller)` <a id="_optionalmeasurement"></a>
- **Kind:** method of `_WeightRecordDialogState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 2172)
- **Purpose:** Parse an optional measurement field's current text, treating empty, zero, negative,
  or malformed input as absent rather than as an error.
- **Inputs:** `controller`.
- **Returns:** `double?` — `null` unless the parsed value is `> 0`.
- **Side effects:** None.
- **Algorithm:** `double.tryParse(controller.text.trim())`; return `null` if that failed or the
  result is `<= 0`; otherwise return the value.
- **Usage:**
  ```dart
  final bustCm = _optionalMeasurement(_bustController);
  final waistCm = _optionalMeasurement(_waistController);
  final hipCm = _optionalMeasurement(_hipController);
  ```
  (`_submit`, lines 2187-2189.)
- **Notes:** Because a zero/negative/unparsable entry silently becomes `null` (absent) rather than
  blocking submission, the measurement fields have no validation error state of their own — an
  invalid entry is simply treated the same as leaving the field blank.

### `void _submit(UnsavedChangesController guard)` <a id="_submit"></a>
- **Kind:** method of `_WeightRecordDialogState`
- **Source:** `lib/features/weight/views/weight_page.dart` (line 2183)
- **Purpose:** Validate the required weight field, gather the optional measurement/note/date fields,
  build the resulting `WeightRecord` (updating `initialRecord` if editing, or constructing a new one
  if adding), and pop the dialog with it.
- **Inputs:** `guard`.
- **Returns:** None.
- **Side effects:** Calls `guard.pop(record)` when validation passes; none otherwise.
- **Algorithm:**
  1. Parse `weight` from `_weightController`; if `null` or `<= 0`, return without popping (blocks
     submission — this is the dialog's only hard validation gate).
  2. Resolve `bustCm`/`waistCm`/`hipCm` via `_optionalMeasurement`, and `notes` as the trimmed note
     text or `null` if empty.
  3. If `widget.initialRecord` is non-null (edit mode), build the result via
     `initialRecord.copyWith(...)`, passing `clearBustCm: bustCm == null` (and similarly for
     waist/hip/notes) alongside each value — see
     [`WeightRecord.copyWith`](../models/weight_record.md#copywith) for why the explicit clear flags
     are required for a field to actually be nulled out. Otherwise (add mode), construct a new
     `WeightRecord(...)` directly with the same fields.
  4. `guard.pop(record)` — pops the dialog and returns `record` as the `showDialog` result.
- **Usage:**
  ```dart
  FilledButton(
    onPressed: () => _submit(guard),
    child: Text(_isEditing ? l10n.commonSave : l10n.commonAdd),
  )
  ```
  (`build`, lines 2094-2097; also wired to both the weight field's and the note field's
  `onSubmitted`, lines 2000 and 2047.)
- **Notes:** Only the weight field is actually validated (must parse to `> 0`); measurement fields
  can never block submission since `_optionalMeasurement` maps any invalid entry to `null` rather
  than surfacing an error.

## Related pages

- [Weight](../../../../features/weight.md) — concept-level explanation of measurement inheritance,
  the reminder grace window, and BMI/waist-hip-ratio.
- [`WeightRecord`/`WeightData`](../models/weight_record.md) — the model methods this file calls but
  does not reimplement (`calculateBMI`, `calculateWaistHipRatio`, `effectiveMeasurementsUpTo`,
  `effectiveMeasurementTimeline`, `copyWith`).
- [`WeightStorage`](../services/weight_storage.md) — `load()`/`save()` used by `_loadData`/`_saveData`.
- [`ReminderService`](../../../shared/services/reminder_service.md) — reads the reminder
  fields/grace-window this file writes.
- [`UnsavedChangesGuard`/`formSignature`](../../../shared/widgets/unsaved_changes_guard.md) — the
  dirty-checking pattern used by `_setHeight` and `_WeightRecordDialogState`.
- [`groupByWeek`/`formatMonthDayRange`](../../../shared/utils/week_grouping.md) — history grouping
  used by `_buildGroupedRecordTiles`/`_buildWeekHeader`.

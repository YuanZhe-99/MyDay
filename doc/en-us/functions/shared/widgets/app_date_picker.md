# lib/shared/widgets/app_date_picker.dart

The app's replacement for Flutter's `showDatePicker` / `showDateRangePicker`. Every module picks
dates through `showAppDatePicker` or `showAppDateRangePicker` so that calendar behavior — above all
the **week-start day** — is consistent app-wide instead of following the platform locale. The week
start comes from `TodoStorage.getWeekStartDay()` (the same persisted setting the Todo and Intimacy
calendars read) and the weekday header order is produced by
[`week_grouping.dart`](../utils/week_grouping.md).

The file is two public entry points plus four private widgets (`_AppDatePickerDialog`,
`_AppDateRangePickerDialog`, `_CalendarMonthPicker`, `_CalendarDateCell`) and four pure date
helpers. `_CalendarMonthPicker` renders one month grid and is shared by both dialogs; the
single-date dialog confirms on selection, while the range dialog collects a start then an end
before its confirm button enables.

## Declarations

Anchor note: `_changeMonth` and `build` are each defined in more than one class in this file, so
those rows use class-qualified anchors (`changemonth-single`, `build-range`, …) rather than the
bare-name anchor the general rule would produce.

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`showAppDatePicker`](#showappdatepicker) | top-level function | A | Show the app-standard single-date picker using the global week-start setting. |
| [`showAppDateRangePicker`](#showappdaterangepicker) | top-level function | A | Show the app-standard date-range picker using the global week-start setting. |
| `_AppDatePickerDialog.new` | constructor | B | Trivial forwarding constructor. |
| `_AppDatePickerDialog.createState` | method (`_AppDatePickerDialog`) | B | Create `_AppDatePickerDialogState`. |
| `_AppDatePickerDialogState.initState` | method (lifecycle) | B | Initialize the visible month from the initial date. |
| [`_changeMonth`](#changemonth-single) | method (`_AppDatePickerDialogState`) | A | Move the visible calendar month by a month delta. |
| `_AppDatePickerDialogState.build` | method (widget) | B | Render the single-date dialog. |
| `_AppDateRangePickerDialog.new` | constructor | B | Trivial forwarding constructor. |
| `_AppDateRangePickerDialog.createState` | method (`_AppDateRangePickerDialog`) | B | Create `_AppDateRangePickerDialogState`. |
| `_AppDateRangePickerDialogState.initState` | method (lifecycle) | B | Initialize the visible month and the selected range. |
| [`_changeMonth`](#changemonth-range) | method (`_AppDateRangePickerDialogState`) | A | Move the visible calendar month by a month delta. |
| [`_selectDate`](#selectdate) | method (`_AppDateRangePickerDialogState`) | A | Apply a tapped date to the in-progress range selection. |
| [`_AppDateRangePickerDialogState.build`](#build-range) | method (widget) | A | Render the range dialog, enabling confirm only once both ends are chosen. |
| `_CalendarMonthPicker.new` | constructor | B | Trivial forwarding constructor. |
| [`_canGoPrevious`](#cangoprevious) | getter (`_CalendarMonthPicker`) | A | Whether the previous month overlaps the allowed date range. |
| [`_canGoNext`](#cangonext) | getter (`_CalendarMonthPicker`) | A | Whether the next month overlaps the allowed date range. |
| [`_CalendarMonthPicker.build`](#build-month) | method (widget) | A | Render one localized month grid with `weekStartDay` weekday ordering. |
| `_CalendarDateCell.new` | constructor | B | Trivial forwarding constructor. |
| `_CalendarDateCell.build` | method (widget) | B | Render one selectable date cell. |
| [`_isInRange`](#isinrange) | top-level function | A | Whether a date falls strictly inside the selected range. |
| [`_dateOnly`](#dateonly) | top-level function | A | Strip the time component from a date. |
| [`_isSameDay`](#issameday) | top-level function | A | Whether two values represent the same calendar day. |
| [`_clampDate`](#clampdate) | top-level function | A | Clamp a date into an inclusive date-only range. |

**Reconciliation:** `grep -c 'Purpose:' lib/shared/widgets/app_date_picker.dart` reports 23,
matching all 23 rows above exactly (13 Tier A, 10 Tier B). Every `/// Purpose:` block sits directly
above the real declaration it documents; no misattached blocks were found and no undocumented real
declaration exists in the file. This page was added in v1.3.2 — the file had been missing from
[INDEX.md](../../INDEX.md) since it was created.

## Documentation

### `Future<DateTime?> showAppDatePicker({required BuildContext context, required DateTime initialDate, required DateTime firstDate, required DateTime lastDate, String? title})` <a id="showappdatepicker"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 13)
- **Purpose:** Show the app-standard date picker using the global week-start setting.
- **Inputs:** `context`, `initialDate`, the inclusive `firstDate`/`lastDate` bounds, and an
  optional dialog `title`.
- **Returns:** `Future<DateTime?>` — the selected date, or null when cancelled.
- **Side effects:** Reads the persisted week-start setting and opens a dialog.
- **Algorithm:**
  1. `await TodoStorage.getWeekStartDay()`.
  2. Bail out returning null if the context is no longer mounted after that await.
  3. `showDialog` an `_AppDatePickerDialog`, passing the initial date through
     [`_clampDate`](#clampdate) and every bound through [`_dateOnly`](#dateonly).
- **Usage:** The app-wide replacement for `showDatePicker`; called from the Todo, Finance,
  Intimacy, and Weight date fields.
- **Notes:** The `context.mounted` guard after the storage read matters — the caller's screen can
  be popped while the setting is being loaded. Clamping the initial date means callers may pass an
  out-of-range value without the dialog opening on an unselectable day.

### `Future<DateTimeRange?> showAppDateRangePicker({required BuildContext context, required DateTime firstDate, required DateTime lastDate, DateTimeRange? initialDateRange, String? title})` <a id="showappdaterangepicker"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 39)
- **Purpose:** Show the app-standard date-range picker using the global week-start setting.
- **Inputs:** `context`, the inclusive `firstDate`/`lastDate` bounds, an optional
  `initialDateRange`, and an optional dialog `title`.
- **Returns:** `Future<DateTimeRange?>` — the selected range, or null when cancelled.
- **Side effects:** Reads the persisted week-start setting and opens a dialog.
- **Algorithm:** Same shape as `showAppDatePicker`, additionally clamping both ends of
  `initialDateRange` when one was supplied.
- **Usage:** The custom-range option on the Finance analysis page.
- **Notes:** The user taps a start date and then an end date; confirmation stays disabled until
  both are set.

### `void _changeMonth(int delta)` (in `_AppDatePickerDialogState`) <a id="changemonth-single"></a>
- **Kind:** method of `_AppDatePickerDialogState`
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 121)
- **Purpose:** Move the visible calendar month by `delta` months.
- **Inputs:** `delta` — months to add, negative to go back.
- **Returns:** None.
- **Side effects:** Updates dialog state via `setState`.
- **Notes:** Relies on `DateTime` normalizing a month of 0 or 13 into the neighbouring year. No
  bounds check here: the navigation buttons are already disabled by
  [`_canGoPrevious`](#cangoprevious)/[`_canGoNext`](#cangonext) at the range edges.

### `void _changeMonth(int delta)` (in `_AppDateRangePickerDialogState`) <a id="changemonth-range"></a>
- **Kind:** method of `_AppDateRangePickerDialogState`
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 219)
- **Purpose:** Move the visible calendar month by `delta` months.
- **Inputs:** `delta`.
- **Returns:** None.
- **Side effects:** Updates dialog state via `setState`.
- **Notes:** Identical to the single-date dialog's copy; the two dialogs do not share a state base
  class.

### `void _selectDate(DateTime date)` <a id="selectdate"></a>
- **Kind:** method of `_AppDateRangePickerDialogState`
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 230)
- **Purpose:** Apply a tapped date to the in-progress range selection.
- **Inputs:** `date` — the tapped day.
- **Returns:** None.
- **Side effects:** Updates `_start`/`_end` via `setState`.
- **Algorithm:**
  1. If no start is set, or the range is already complete, begin a new range at `date` and clear
     the end — so a third tap restarts rather than extending.
  2. Otherwise, if `date` precedes the current start, swap: the old start becomes the end and
     `date` becomes the start.
  3. Otherwise set the end to `date`.
- **Notes:** Step 2 is why the user can select the two ends in either order.

### `Widget build(BuildContext context)` (in `_AppDateRangePickerDialogState`) <a id="build-range"></a>
- **Kind:** method of `_AppDateRangePickerDialogState`
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 250)
- **Purpose:** Build this date-range picker dialog.
- **Inputs:** `context`.
- **Returns:** The dialog widget tree.
- **Side effects:** Creates UI widgets and date-selection callbacks.
- **Notes:** The confirm action is null — and therefore the button disabled — until both `_start`
  and `_end` are non-null, so a half-selected range can never be returned.

### `bool get _canGoPrevious` <a id="cangoprevious"></a>
- **Kind:** getter of `_CalendarMonthPicker`
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 337)
- **Purpose:** Return whether moving to the previous month is allowed.
- **Inputs:** None.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** Build the previous month's last day as `DateTime(viewMonth.year,
  viewMonth.month, 0)` and allow navigation unless it falls before `firstDate`.
- **Notes:** Tests the previous month's **end**, not its start, so a partially-selectable month is
  still reachable.

### `bool get _canGoNext` <a id="cangonext"></a>
- **Kind:** getter of `_CalendarMonthPicker`
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 347)
- **Purpose:** Return whether moving to the next month is allowed.
- **Inputs:** None.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** Build the next month's first day and allow navigation unless it falls after
  `lastDate`.
- **Notes:** The mirror of [`_canGoPrevious`](#cangoprevious) — tests the next month's **start**.

### `Widget build(BuildContext context)` (in `_CalendarMonthPicker`) <a id="build-month"></a>
- **Kind:** method of `_CalendarMonthPicker`
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 358)
- **Purpose:** Build the localized calendar month picker.
- **Inputs:** `context`.
- **Returns:** The month grid widget tree, including the month header and navigation buttons.
- **Side effects:** Creates UI widgets and callbacks.
- **Notes:** Weekday column order follows `weekStartDay` via `week_grouping.dart`'s
  `weekdaySequence`/`localizedWeekdayLabel`, and the leading blanks come from
  `leadingBlankDaysForMonth` — this is the whole reason the app does not use Flutter's built-in
  pickers.

### `bool _isInRange(DateTime date, DateTime? start, DateTime? end)` <a id="isinrange"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 527)
- **Purpose:** Return whether `date` is inside the selected date range.
- **Inputs:** `date`, nullable `start`, nullable `end`.
- **Returns:** `bool` — false whenever either endpoint is null.
- **Side effects:** None.
- **Notes:** **Exclusive** of both endpoints (`isAfter` / `isBefore`), because the two ends are
  painted with their own selected styling and should not also get the in-range fill.

### `DateTime _dateOnly(DateTime date)` <a id="dateonly"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 537)
- **Purpose:** Strip the time component from a date.
- **Inputs:** `date`.
- **Returns:** `DateTime` at local midnight.
- **Side effects:** None.
- **Notes:** File-local; `cycle_predictor.dart` has its own public `dateOnly` with the same
  semantics.

### `bool _isSameDay(DateTime a, DateTime b)` <a id="issameday"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 544)
- **Purpose:** Return whether two date values represent the same calendar day.
- **Inputs:** `a`, `b`.
- **Returns:** `bool`.
- **Side effects:** None.
- **Notes:** Compares year/month/day directly rather than normalizing first, so it is safe to call
  on values that still carry a time component.

### `DateTime _clampDate(DateTime date, DateTime firstDate, DateTime lastDate)` <a id="clampdate"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/widgets/app_date_picker.dart` (line 552)
- **Purpose:** Clamp `date` to an inclusive date-only range.
- **Inputs:** `date`, `firstDate`, `lastDate`.
- **Returns:** `DateTime` — `firstDate`, `lastDate`, or the date-only input.
- **Side effects:** None.
- **Notes:** Normalizes all three inputs through [`_dateOnly`](#dateonly) first, so a caller's time
  component cannot push a boundary date outside the range.

## Related pages

- [`week_grouping.dart`](../utils/week_grouping.md) — weekday ordering and month-grid helpers.
- [`todo_storage.dart`](../../features/todo/services/todo_storage.md) — `getWeekStartDay()`, the
  persisted setting these pickers honor.
- [Settings](../../../features/settings.md) — where the user changes the week-start day.

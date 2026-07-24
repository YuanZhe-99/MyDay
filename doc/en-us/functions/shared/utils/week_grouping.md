# lib/shared/utils/week_grouping.dart

Shared calendar-week math for the whole app: grouping records by a configurable week start day,
computing week-numbering year/week (a four-day-rule variant of ISO 8601 anchored to the configured
start day instead of always Monday), weekday label/order helpers for calendar UIs, and blank-cell
counting for month grids. `weekStartDay` is read from `appSettingsProvider` (see
[../providers/app_settings.md](../providers/app_settings.md)) and threaded through Todo, Weight,
and Intimacy history views plus `shared/widgets/app_date_picker.dart` so every calendar in the app
agrees on the same first weekday.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`WeekGroup` (constructor)](#weekgroup-new) | constructor (`WeekGroup<T>`) | A | Create an immutable week-group value. |
| [`groupByWeek`](#groupbyweek) | top-level function | A | Group items by calendar week using a configurable week start day. |
| [`groupByIsoWeek`](#groupbyisoweek) | top-level function | A | Group items by ISO week (Monday start) — compatibility wrapper. |
| [`normalizeWeekStartDay`](#normalizeweekstartday) | top-level function | A | Clamp a persisted weekday value back to a valid Dart weekday. |
| [`weekdaySequence`](#weekdaysequence) | top-level function | A | Return weekdays ordered starting from the configured week start. |
| [`localizedWeekdayLabel`](#localizedweekdaylabel) | top-level function | A | Return a localized short/long weekday label. |
| [`startOfWeek`](#startofweek) | top-level function | A | Return the first calendar date of the configured week. |
| [`startOfIsoWeek`](#startofisoweek) | top-level function | A | Return the Monday starting the ISO week — compatibility wrapper. |
| [`weekYear`](#weekyear) | top-level function | A | Return the week-numbering year for a configurable-start week. |
| [`isoWeekYear`](#isoweekyear) | top-level function | A | Return the ISO week-numbering year — compatibility wrapper. |
| [`weekNumber`](#weeknumber) | top-level function | A | Return the week number within the week-numbering year. |
| [`isoWeekNumber`](#isoweeknumber) | top-level function | A | Return the ISO week number — compatibility wrapper. |
| [`formatMonthDayRange`](#formatmonthdayrange) | top-level function | A | Format a `start`–`end` month/day range string. |
| [`leadingBlankDaysForMonth`](#leadingblankdaysformonth) | top-level function | A | Return the blank leading cells before a month starts in a calendar grid. |
| [`_dateOnly`](#_dateonly) | top-level function | A | Strip the time component from a `DateTime`. |
| [`_differenceInCalendarDays`](#_differenceincalendardays) | top-level function | A | Return whole calendar days between two date-only values. |

`grep -c 'Purpose:' lib/shared/utils/week_grouping.dart` reports 16, matching all sixteen real
declarations in this file exactly. No misattachment or undocumented declarations found. Every
declaration is Tier A: the file's own `WeekGroup` constructor is a model constructor (explicit
Tier A rule), and every other declaration is a top-level function under `shared/`, which is Tier A
per the blanket rule regardless of size — including the two private helpers `_dateOnly` and
`_differenceInCalendarDays`, since that rule draws no distinction for private top-level utility
functions (only "private `_buildXxx` widget-building helpers" are called out as Tier B, and these
are not widget builders). The `WeekdayLabelWidth` enum carries no `Purpose:` block and is not
counted as a separate declaration.

## Documentation

### `const WeekGroup({required this.year, required this.week, required this.start, required this.end, required this.items})` <a id="weekgroup-new"></a>
- **Kind:** const constructor of `WeekGroup<T>`
- **Source:** `lib/shared/utils/week_grouping.dart` (line 17)
- **Purpose:** Create an immutable week-group value carrying the week-numbering year/week, the
  week's start/end dates, and the items that fall in it.
- **Inputs:** `year`, `week`, `start`, `end`, `items` (all required).
- **Returns:** A new `WeekGroup<T>`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** Built only inside `groupByWeek` (see below); consumed by history views that render a
  week header followed by its grouped items (Todo/Weight/Intimacy history lists).
- **Notes:** `items` is a plain mutable `List<T>` even though the constructor is `const` — callers
  of `groupByWeek` should not treat the returned groups' `items` lists as immutable (see
  `groupByWeek`'s Notes).

### `List<WeekGroup<T>> groupByWeek<T>(List<T> items, DateTime Function(T item) getDate, {bool descending = true, int weekStartDay = DateTime.monday})` <a id="groupbyweek"></a>
- **Kind:** top-level generic function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 31)
- **Purpose:** Bucket a flat list of items into per-week groups keyed by the configured week
  start day, sorted by week and optionally reversed.
- **Inputs:** `items`; `getDate` — extracts the date to group by from each item; `descending`
  (default `true`); `weekStartDay` (default Monday; normalized internally).
- **Returns:** `List<WeekGroup<T>>` sorted by `start`, reversed when `descending`.
- **Side effects:** Mutates each returned group's internal `items` list while building groups (each
  group starts as a one-element list and grows via `.add`).
- **Algorithm:**
  1. Normalize `weekStartDay` via `normalizeWeekStartDay`.
  2. For each item: compute its date-only value (`_dateOnly(getDate(item))`), then its week `start`
     (`startOfWeek`), week-numbering `year` (`weekYear`), and `week` number (`weekNumber`), all using
     the normalized start day.
  3. Key each item by `'$year-$week'` into a `Map<String, WeekGroup<T>>`; create a new group
     (`end = start + 6 days`) on first sight of a key, otherwise append to the existing group's
     `items`.
  4. Sort the resulting groups by `start`; reverse the list if `descending`.
- **Usage:**
  ```dart
  final groups = groupByWeek(
    records,
    (record) => record.datetime,
    weekStartDay: weekStartDay,
  );
  ```
  (`lib/features/weight/views/weight_page.dart`, weekly-grouped weight history; the same pattern
  is used in `lib/features/intimacy/views/intimacy_page.dart` for record history, twice, with an
  additional `descending` argument in one call site.)
- **Notes:** The week key `'$year-$week'` uses `weekYear`, not the calendar year of `start` —
  the two differ near year boundaries (see `weekYear`'s Notes), so groups are correctly bucketed
  even when a week's Monday and its numbering-anchor day fall in different calendar years.

### `List<WeekGroup<T>> groupByIsoWeek<T>(List<T> items, DateTime Function(T item) getDate, {bool descending = true})` <a id="groupbyisoweek"></a>
- **Kind:** top-level generic function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 72)
- **Purpose:** Group items by strict ISO week (Monday start), regardless of the app's configured
  week start day.
- **Inputs:** `items`, `getDate`, `descending`.
- **Returns:** `List<WeekGroup<T>>`.
- **Side effects:** Same as `groupByWeek` (delegates to it).
- **Algorithm:** `groupByWeek(items, getDate, descending: descending, weekStartDay:
  DateTime.monday)`.
- **Usage:** No call site was found elsewhere in `lib/` or `test/` in this repo; it exists as a
  compatibility wrapper per its own doc comment ("Kept as a compatibility wrapper for callers that
  still need ISO weeks").
- **Notes:** Dead code from the current call graph's perspective, but intentionally retained per
  the source comment — do not remove without checking external/future callers.

### `int normalizeWeekStartDay(int? weekday)` <a id="normalizeweekstartday"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 90)
- **Purpose:** Clamp a possibly-invalid or missing persisted weekday value back to a valid Dart
  weekday, defaulting to Monday.
- **Inputs:** `weekday` — nullable, expected Dart weekday range 1 (Monday) .. 7 (Sunday).
- **Returns:** `int` — `weekday` itself if valid, otherwise `DateTime.monday`.
- **Side effects:** None.
- **Algorithm:** `weekday == null || weekday < 1 || weekday > 7` → return `DateTime.monday`;
  otherwise return `weekday` unchanged.
- **Usage:**
  ```dart
  final normalized = normalizeWeekStartDay(weekday);
  state = state.copyWith(weekStartDay: normalized);
  TodoStorage.setWeekStartDay(normalized);
  ```
  (`lib/shared/providers/app_settings.dart`, `setWeekStartDay` — see
  [../providers/app_settings.md#setweekstartday](../providers/app_settings.md#setweekstartday).)
  Also called internally by every other function in this file that accepts a `weekStartDay`
  parameter.
- **Notes:** Defaults invalid persisted values back to Monday rather than throwing, so a corrupted
  or pre-migration `storage_config.json` value cannot crash calendar rendering.

### `List<int> weekdaySequence(int weekStartDay)` <a id="weekdaysequence"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 104)
- **Purpose:** Return the seven Dart weekday values in display order starting from the configured
  week start day.
- **Inputs:** `weekStartDay`.
- **Returns:** `List<int>` of 7 Dart weekday values (1..7), starting at `normalizeWeekStartDay(weekStartDay)`.
- **Side effects:** None.
- **Algorithm:** `[for (offset in 0..6) ((start - 1 + offset) % 7) + 1]` where `start` is the
  normalized week start day.
- **Usage:**
  ```dart
  for (final weekday in weekdaySequence(weekStartDay))
    Expanded(
      child: Center(
        child: Text(localizedWeekdayLabel(weekday, l10n.localeName), ...),
      ),
    ),
  ```
  (`lib/features/intimacy/widgets/cycle_calendar.dart`, rendering the calendar's weekday header
  row in the configured order.)
- **Notes:** Returned weekday values still use Dart's Monday=1..Sunday=7 numbering — only their
  *order* in the list changes with `weekStartDay`, not their integer values.

### `String localizedWeekdayLabel(int weekday, String localeName, {WeekdayLabelWidth width = WeekdayLabelWidth.short})` <a id="localizedweekdaylabel"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 116)
- **Purpose:** Return a localized weekday label (short "Mon" or long "Monday" style) for a given
  Dart weekday value, using `Intl` so every module shares the same translations.
- **Inputs:** `weekday`; `localeName` (an `Intl`-compatible locale name, e.g. `l10n.localeName`);
  `width` (default `WeekdayLabelWidth.short`).
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** Normalize `weekday`; construct a fixed reference date
  (`DateTime.utc(2024, 1, normalized)` — 2024-01-01 is a Monday, so day-of-month equals the Dart
  weekday number for `1..7`); format it with `DateFormat.EEEE(localeName)` (long) or
  `DateFormat.E(localeName)` (short).
- **Usage:** See `weekdaySequence` above — the two are always used together for calendar header
  rows.
- **Notes:** Relies on the fact that January 2024 starts on a Monday to map a bare weekday integer
  to a real calendar date `Intl` can format; this trick only works because `DateTime.utc(2024, 1,
  n)` for `n` in `1..7` lands on weekday `n`.

### `DateTime startOfWeek(DateTime date, {int weekStartDay = DateTime.monday})` <a id="startofweek"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 134)
- **Purpose:** Return the first calendar date (time-stripped) of the week containing `date`, per
  the configured week start day.
- **Inputs:** `date`; `weekStartDay` (default Monday; normalized internally).
- **Returns:** `DateTime` — a date-only value (no time component), always `<= date`.
- **Side effects:** None.
- **Algorithm:** `day = _dateOnly(date)`; `start = normalizeWeekStartDay(weekStartDay)`; return
  `day - ((day.weekday - start + 7) % 7)` days.
- **Usage:**
  ```dart
  DateTime _selectedWeekStart(int weekStartDay) =>
      startOfWeek(_selectedDate, weekStartDay: weekStartDay);
  ```
  (`lib/features/todo/views/todo_page.dart`, computing the inline week calendar's first visible
  date.) Also used internally by `groupByWeek`, `weekYear`, and `weekNumber`.
- **Notes:** The modulo arithmetic `(day.weekday - start + 7) % 7` correctly handles every
  `weekStartDay` in `1..7`, including the case where `date`'s weekday equals `start` (returns
  `date` itself, offset `0`).

### `DateTime startOfIsoWeek(DateTime date)` <a id="startofisoweek"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 145)
- **Purpose:** Return the Monday starting the ISO week containing `date`, regardless of the app's
  configured week start day.
- **Inputs:** `date`.
- **Returns:** `DateTime`.
- **Side effects:** None.
- **Algorithm:** `startOfWeek(date, weekStartDay: DateTime.monday)`.
- **Usage:** No call site was found elsewhere in `lib/` or `test/`; kept per its own doc comment
  ("Kept for ISO-specific callers and tests").
- **Notes:** Dead code from the current call graph's perspective, intentionally retained.

### `int weekYear(DateTime date, {int weekStartDay = DateTime.monday})` <a id="weekyear"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 154)
- **Purpose:** Return the week-numbering year for a configurable-start week — the calendar year of
  the day 3 days after the week's start, matching ISO's "the year containing the week's Thursday"
  rule shifted to the configured start day.
- **Inputs:** `date`; `weekStartDay`.
- **Returns:** `int`.
- **Side effects:** None.
- **Algorithm:** `startOfWeek(date, weekStartDay: weekStartDay).add(3 days).year`.
- **Usage:** Called internally by `groupByWeek` (to build the week-group map key) and by
  `isoWeekYear`. No direct external call site was found.
- **Notes:** This can differ from `date.year` for weeks that straddle a year boundary — this is
  the whole point of the four-day-week rule (a week is assigned to whichever year contains most of
  its days).

### `int isoWeekYear(DateTime date)` <a id="isoweekyear"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 166)
- **Purpose:** Return the ISO week-numbering year for `date` (always Monday-start).
- **Inputs:** `date`.
- **Returns:** `int`.
- **Side effects:** None.
- **Algorithm:** `weekYear(date, weekStartDay: DateTime.monday)`.
- **Usage:** No call site was found elsewhere in `lib/` or `test/`; kept per its own doc comment
  ("Kept for ISO-specific callers and tests").
- **Notes:** Dead code from the current call graph's perspective, intentionally retained.

### `int weekNumber(DateTime date, {int weekStartDay = DateTime.monday})` <a id="weeknumber"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 175)
- **Purpose:** Return the 1-based week number within the week-numbering year returned by
  `weekYear`, using January 4 as the first-week anchor (ISO's four-day rule).
- **Inputs:** `date`; `weekStartDay`.
- **Returns:** `int`.
- **Side effects:** None.
- **Algorithm:**
  1. `start = startOfWeek(date, weekStartDay: weekStartDay)`.
  2. `anchor = start + 3 days` (used only to derive the numbering year via the same logic as
     `weekYear`).
  3. `firstWeekStart = startOfWeek(DateTime(anchor.year, 1, 4), weekStartDay: weekStartDay)` — the
     week containing January 4 is always week 1, per the ISO four-day rule.
  4. Return `_differenceInCalendarDays(firstWeekStart, start) ~/ 7 + 1`.
- **Usage:** Called internally by `groupByWeek` (week-group map key) and `isoWeekNumber`. No direct
  external call site was found.
- **Notes:** Uses UTC-normalized day differences (via `_differenceInCalendarDays`) specifically so
  daylight-saving transitions cannot shift the day count by an hour and change the computed week
  number.

### `int isoWeekNumber(DateTime date)` <a id="isoweeknumber"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 190)
- **Purpose:** Return the ISO week number for `date` (always Monday-start).
- **Inputs:** `date`.
- **Returns:** `int`.
- **Side effects:** None.
- **Algorithm:** `weekNumber(date, weekStartDay: DateTime.monday)`.
- **Usage:** No call site was found elsewhere in `lib/` or `test/`; kept per its own doc comment
  ("Kept for ISO-specific callers and tests").
- **Notes:** Dead code from the current call graph's perspective, intentionally retained.

### `String formatMonthDayRange(DateTime start, DateTime end, {String? localeName})` <a id="formatmonthdayrange"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 199)
- **Purpose:** Format a week's `start`–`end` dates as a locale-aware month/day range string (e.g.
  a week header like "1/6-1/12").
- **Inputs:** `start`, `end`; `localeName` (optional; when omitted, `Intl` uses its default
  locale).
- **Returns:** `String` — `'<formatted start>-<formatted end>'`.
- **Side effects:** None.
- **Algorithm:** `DateFormat.Md(localeName)`, applied to both `start` and `end`, joined with `-`.
- **Usage:**
  ```dart
  formatMonthDayRange(group.start, group.end, localeName: l10n.localeName),
  ```
  (`lib/features/weight/views/weight_page.dart`, weekly history group headers; the same pattern is
  used in `intimacy_page.dart`.)
- **Notes:** Uses `DateFormat.Md`, whose month/day order follows the given locale (e.g. `M/d` for
  English vs. locale-specific orders for other languages), so this string is not naively
  concatenable across locales.

### `int leadingBlankDaysForMonth(DateTime date, {int weekStartDay = DateTime.monday})` <a id="leadingblankdaysformonth"></a>
- **Kind:** top-level function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 209)
- **Purpose:** Return how many empty leading cells a month-grid calendar needs before day 1, given
  the configured week start day.
- **Inputs:** `date` (any date within the target month); `weekStartDay`.
- **Returns:** `int` in `0..6`.
- **Side effects:** None.
- **Algorithm:** `first = DateTime(date.year, date.month, 1)`; `start =
  normalizeWeekStartDay(weekStartDay)`; return `(first.weekday - start + 7) % 7`.
- **Usage:**
  ```dart
  final leadingBlanks = leadingBlankDaysForMonth(viewMonth, weekStartDay: weekStartDay);
  ```
  (`lib/shared/widgets/app_date_picker.dart`, month grid layout; the same pattern is used in
  `lib/features/intimacy/widgets/cycle_calendar.dart` and `lib/features/todo/views/todo_page.dart`
  for their own month-grid calendars.)
- **Notes:** Same modulo trick as `startOfWeek`, applied to the month's first day instead of an
  arbitrary date.

### `DateTime _dateOnly(DateTime date)` <a id="_dateonly"></a>
- **Kind:** top-level private function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 223)
- **Purpose:** Strip the time-of-day component from a `DateTime`, keeping local-date semantics.
- **Inputs:** `date`.
- **Returns:** `DateTime` — `DateTime(date.year, date.month, date.day)`.
- **Side effects:** None.
- **Algorithm:** Direct constructor call dropping hour/minute/second/millisecond/microsecond.
- **Usage:** Called by `groupByWeek` and `startOfWeek` to normalize their input dates before doing
  weekday arithmetic.
- **Notes:** Preserves local-date semantics (not UTC) — pairs with `_differenceInCalendarDays`,
  which does its internal comparison in UTC specifically to avoid DST issues while still starting
  from a local date-only value.

### `int _differenceInCalendarDays(DateTime start, DateTime end)` <a id="_differenceincalendardays"></a>
- **Kind:** top-level private function
- **Source:** `lib/shared/utils/week_grouping.dart` (line 230)
- **Purpose:** Return the whole number of calendar days between two date-only values, immune to
  daylight-saving-induced hour shifts.
- **Inputs:** `start`, `end` (expected to already be date-only, e.g. via `_dateOnly`/`startOfWeek`).
- **Returns:** `int` — `end - start` in days.
- **Side effects:** None.
- **Algorithm:** Rebuild both dates as `DateTime.utc(year, month, day)` (dropping any local
  timezone/DST offset), then take `.difference(...).inDays`.
- **Usage:** Called only by `weekNumber` to count days between the first-week anchor and the
  target week's start.
- **Notes:** Using UTC here (rather than the ambient local `DateTime`) is what makes the day count
  robust to daylight-saving transitions that fall between `start` and `end`.

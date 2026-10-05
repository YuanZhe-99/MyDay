import 'package:flutter/widgets.dart';
import 'package:myapps_adaptive/myapps_adaptive.dart';

export 'package:myapps_adaptive/myapps_adaptive.dart';

/// Purpose: Return the width a shell page's content actually receives.
/// Inputs: `screenWidth` — the whole screen width in logical pixels.
/// Returns: `double`, never negative.
/// Side effects: None.
/// Notes: Subtracts the navigation rail when the shell is showing one. Pass the
/// result wherever a capacity is being computed; keep passing the untouched
/// screen size to [canSplitLayout], which asks about the window's shape rather
/// than about the room left over inside it. Pages pushed on top of the shell —
/// everything reached with `Navigator.push` — have no rail to subtract and must
/// measure their own constraints instead of calling this.
double shellContentWidth(double screenWidth) {
  final width = useNavigationRail(screenWidth)
      ? screenWidth - navRailWidth
      : screenWidth;
  return width < 0 ? 0 : width;
}

/// Purpose: Deal an ordered list of blocks into columns, filling each column
/// before starting the next.
/// Inputs: `itemCount`, `columns`.
/// Returns: `List<List<int>>` — exactly `columns` lists (at least one), each
/// holding the indices of the blocks in that column, in order. A list is empty
/// only when `itemCount` is smaller than `columns`.
/// Side effects: None.
/// Notes: Reading order — top to bottom, then left to right — which is what a
/// person expects of a few named sections. Round-robin dealing, which the Todo
/// page used before v1.4.3, put its second section beside the first and its
/// third underneath, so the two sections a user reads together sat in
/// different columns. Each column gets [listRowCount] blocks, so the earlier
/// columns are the fuller ones when the count does not divide evenly.
List<List<int>> columnMajorFill(int itemCount, int columns) {
  final count = columns < 1 ? 1 : columns;
  final perColumn = listRowCount(itemCount, count);
  return List.generate(count, (column) {
    final start = column * perColumn;
    final end = (start + perColumn).clamp(0, itemCount < 0 ? 0 : itemCount);
    return [for (var i = start; i < end; i++) i];
  });
}

/// Purpose: Return the number of columns a list should actually render.
/// Inputs: `screenWidth`, `screenHeight` — the whole screen, which decides
/// whether splitting is allowed at all; `contentWidth` — the width the list
/// itself gets; `minItemWidth` — the narrowest one column may be; `maxColumns`
/// — a ceiling for this caller; `preference` — [listColumnsAuto] or a pinned
/// column count.
/// Returns: `int`, at least 1.
/// Side effects: None.
/// Notes: The gate reads the screen while the capacity reads the list's own
/// width, deliberately. Measuring the split decision against the body would
/// subtract the app bar and read a Fold 8 in portrait as 0.80 rather than
/// 0.755, leaving almost no margin under [splitMinAspect]. A pinned preference
/// is clamped to what fits, so a window that shrinks — or a foldable that
/// closes — falls back to a single column without losing the stored choice.
int listColumnCount({
  required double screenWidth,
  required double screenHeight,
  required double contentWidth,
  required double minItemWidth,
  required int preference,
  int maxColumns = listMaxColumns,
}) {
  if (!canSplitLayout(screenWidth, screenHeight)) return 1;
  final capacity = columnCapacity(
    contentWidth,
    minItemWidth: minItemWidth,
    maxColumns: maxColumns,
  );
  if (preference == listColumnsAuto) return capacity;
  return preference.clamp(1, capacity);
}

/// Minimum width, in logical pixels, one Todo task section may occupy.
///
/// A section carries its own header, count and sort control above task tiles
/// with a checkbox, a title, a subtask line and a trailing menu button; below
/// this the title truncates before the trailing controls.
const taskSectionMinWidth = 340.0;

/// Largest number of Todo section columns, however wide the window is.
///
/// There are only three sections, so a fourth column could never be filled.
const taskSectionMaxColumns = 3;

/// Minimum width, in logical pixels, one transaction tile may occupy.
///
/// A category emoji or icon, the note, an account/category subtitle and a
/// right-aligned amount carrying a currency symbol.
const transactionTileMinWidth = 320.0;

/// Largest number of transaction columns, however wide the window is.
const transactionMaxColumns = 4;

/// Minimum width, in logical pixels, one weight record tile may occupy.
///
/// A date, the weight, its BMI and up to three measurement values on one line.
const weightRecordMinWidth = 300.0;

/// Largest number of weight record columns, however wide the window is.
const weightRecordMaxColumns = 3;

/// Minimum width, in logical pixels, one intimacy record tile may occupy.
///
/// A date, partner and toy chips, duration, and the derived thrust rate; the
/// widest tile in the app, because the chips wrap rather than truncate.
const intimacyRecordMinWidth = 340.0;

/// Largest number of intimacy record columns, however wide the window is.
const intimacyRecordMaxColumns = 3;

/// Smallest width, in logical pixels, the settings detail pane may be given.
const settingsRightPaneMinWidth = 280.0;

/// Smallest width, in logical pixels, one weight trend chart may be given when
/// the two trend charts sit side by side rather than stacked.
///
/// Each chart reserves about 42 for its left axis and needs roughly 48 per date
/// label, so this shows about six labelled points without crowding.
const weightPairedChartMinWidth = 330.0;

/// Width, in logical pixels, of the weight summary strip's figure block.
///
/// The block is a `Row` of two flexible halves — the latest weight at
/// `displaySmall` on the left, the change and day count on the right — so it
/// needs a bounded width before it can sit in another `Row`. At 280 each half
/// gets about 140, comfortable for a three-digit weight; the old summary pane
/// was 280 wide *including* the card's padding, leaving each half only 108. At
/// the side-by-side gate the stats beside it still get 296, two cells per run.
const weightSummaryFigureWidth = 280.0;

/// Purpose: Return the width of the finance page's fixed left pane.
/// Inputs: `contentWidth` — the width both panes share, in logical pixels.
/// Returns: `double`.
/// Side effects: None.
/// Notes: Proportional rather than fixed because one foldable generation spans
/// roughly 672 to 954 logical pixels unfolded. The floor keeps the three
/// summary figures on their own lines rather than truncating; the ceiling stops
/// the pane sprawling on a desktop window while the transaction list, which is
/// what the user actually reads, keeps the rest.
double financeLeftPaneWidth(double contentWidth) =>
    (contentWidth * 0.36).clamp(280.0, 420.0);

/// Minimum width, in logical pixels, one subscription statistic card may
/// occupy on the finance home's summary pane.
///
/// A 12 dp icon and a short localized label such as 月應付 above an amount like
/// $1,234.56 at `titleMedium`. Two cards fit across the finance pane at every
/// width in its clamp range; the third joins the row once the pane passes
/// about 378 (3 x 110 plus two 8 dp gaps, inside 16 dp of padding each side).
const subscriptionStatMinWidth = 110.0;

/// Horizontal gap, in logical pixels, between the finance summary cards.
///
/// Narrower than [listTileGap] because these cards already sit inside a padded
/// pane, and it matches the gap between the expense and income cards above.
const summaryCardGap = 8.0;

/// Purpose: Return the width of the intimacy page's fixed left pane.
/// Inputs: `contentWidth` — the width both panes share, in logical pixels.
/// Returns: `double`.
/// Side effects: None.
/// Notes: The floor is higher than the finance page's because this pane holds a
/// month calendar: seven columns plus the card's own padding do not fit below
/// about 320, and squeezing them turns the day numbers into a smear. Since
/// v1.4.3 the pane also carries the trend chart, which is why the proportion
/// and the ceiling are higher than the finance pane's — a chart, unlike a
/// calendar, keeps gaining from width. The floor is deliberately unchanged: it
/// is the calendar's, and the narrowest splittable foldables (a Z Fold 5 or 7
/// in portrait, roughly 580–670 of content) have nothing to spare, so they
/// render exactly as before. The proportion clears the floor from 762 of
/// content, about 843 of screen; an unfolded Fold 8 in landscape gets ~357.
double intimacyLeftPaneWidth(double contentWidth) =>
    (contentWidth * 0.42).clamp(320.0, 480.0);

/// Purpose: Return the width of the settings page's fixed left pane.
/// Inputs: `contentWidth` — the width both panes share, in logical pixels.
/// Returns: `double`.
/// Side effects: None.
/// Notes: Proportional, then clamped, then capped so the detail pane can never
/// be squeezed below [settingsRightPaneMinWidth]. The left pane needs room for
/// full `ListTile`s with two-line subtitles and a trailing chevron. The cap only
/// binds on a hand-resized desktop window and on the narrowest foldables, where
/// it gives up left-pane width rather than let the detail pane become unusable.
double settingsLeftPaneWidth(double contentWidth) {
  final preferred = (contentWidth * 0.44).clamp(300.0, 440.0);
  final capped = contentWidth - settingsRightPaneMinWidth;
  if (preferred <= capped) return preferred;
  return capped.clamp(240.0, 440.0);
}

/// Purpose: Report whether the two weight trend charts fit side by side.
/// Inputs: `contentWidth` — the width the weight body gets, in logical pixels.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: A width floor **on top of** [canSplitLayout], not instead of it. The
/// split rule alone admits viewports the size of a Z Fold 5 in portrait, where
/// each chart would be left under 290 logical pixels and show four date labels.
/// Callers must test both, and must also test that there is a chart at all —
/// neither renders below two records, and a summary strip above two blank
/// halves is worse than the stacked layout it would replace. The floor is
/// deliberately the same 672 the summary-card split used through v1.4.3, so
/// every viewport keeps the outcome it had: what changed inside that width is
/// the arrangement, not which windows get one.
bool useWeightChartsSideBySide(double contentWidth) =>
    contentWidth >= 2 * weightPairedChartMinWidth + listTileGap;

/// Minimum width, in logical pixels, one metric card may occupy.
///
/// A stat label above its value, both `labelLarge`/`titleMedium`; below this a
/// localized label such as "平均抽插速率" wraps to three lines.
const metricCardMinWidth = 160.0;

/// Largest number of metric columns in a summary card.
const metricMaxColumns = 4;

/// Minimum width, in logical pixels, one account card may occupy.
///
/// An account name, its bank-preset chip, and a balance shown in both its
/// native and the default currency on one line.
const accountCardMinWidth = 340.0;

/// Largest number of account columns, however wide the window is.
const accountMaxColumns = 3;

/// Minimum width, in logical pixels, one category tile may occupy.
///
/// An emoji, an icon, the name and a trailing chevron; below this the longest
/// localized category name truncates.
const categoryTileMinWidth = 300.0;

/// Minimum width, in logical pixels, one exchange-rate row may occupy.
///
/// A currency pair, its rate to six significant figures, and the timestamp of
/// the fetch that produced it.
const exchangeRateTileMinWidth = 280.0;

/// Minimum width, in logical pixels, one form field may occupy when fields are
/// paired onto a row.
///
/// An `OutlineInputBorder` field whose longest localized label is Japanese;
/// narrower and the label truncates before the field's own suffix.
const formFieldMinWidth = 260.0;

/// Widest a form or settings-style page lets its content grow before centring
/// it, in logical pixels.
///
/// A `ListTile` stretched across a 1400 dp desktop window puts its title and
/// its trailing control at opposite ends of the screen; this keeps them within
/// one glance of each other.
const formMaxContentWidth = 720.0;

/// Widest a prose page lets its text grow before centring it, in logical
/// pixels.
///
/// About 90 characters at the app's body size, the upper end of a comfortable
/// reading measure. Prose gets more than a form because it has no controls
/// whose separation matters.
const readingMaxContentWidth = 840.0;

/// Smallest width, in logical pixels, the analysis pie chart may be given
/// before its legend stops sitting beside it.
const pieChartMinWidth = 280.0;

/// Smallest width, in logical pixels, the analysis category legend may be
/// given when it sits beside the pie chart rather than below it.
const pieLegendMinWidth = 320.0;

/// Smallest width, in logical pixels, the Todo month calendar card may occupy
/// when the score-trend chart sits beside it.
const calendarCardMinWidth = 340.0;

/// Smallest width, in logical pixels, the Todo score-trend chart may be given
/// when it sits beside the month calendar.
const scoreTrendMinWidth = 360.0;

/// Purpose: Return the width a page centres its content at, if any.
/// Inputs: `contentWidth` — the width the page actually has, in logical
/// pixels; `maxWidth` — the widest that content should ever grow.
/// Returns: `double` — `maxWidth` when the page is wider, `contentWidth`
/// otherwise.
/// Side effects: None.
/// Notes: Width only, and no gate: a page narrower than the cap is unaffected
/// at every viewport, so this can never change what a phone renders. This is
/// what a form or a prose page does with a desktop window instead of splitting
/// — see `doc/en-us/adaptive-layout.md`.
double cappedContentWidth(double contentWidth, double maxWidth) =>
    contentWidth > maxWidth ? maxWidth : contentWidth;

/// Purpose: Report whether the analysis legend fits beside the pie chart.
/// Inputs: `contentWidth` — the width the analysis tab gets, in logical pixels.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: A width floor **on top of** [canSplitLayout], the same double gate
/// the weight page uses. Below it the legend keeps its place under the chart,
/// which is the layout every viewport had before.
bool usePieChartSideBySide(double contentWidth) =>
    contentWidth >= pieChartMinWidth + pieLegendMinWidth + listTileGap;

/// Purpose: Report whether the Todo score trend fits beside the month calendar.
/// Inputs: `contentWidth` — the width the calendar page gets, in logical
/// pixels.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: The same double gate again. A month grid and a trend chart stacked
/// are two full screens on a phone; side by side they are one on a tablet.
bool useTodoCalendarSideBySide(double contentWidth) =>
    contentWidth >= calendarCardMinWidth + scoreTrendMinWidth + listTileGap;

/// Purpose: Return the width of the Todo calendar page's month-grid pane.
/// Inputs: `contentWidth` — the width both blocks share, in logical pixels.
/// Returns: `double` between [calendarCardMinWidth] and 480.
/// Side effects: None.
/// Notes: Proportional so a desktop window gives the day cells bigger tap
/// targets rather than leaving the calendar at its bare minimum beside a very
/// wide chart. The ceiling exists because a month grid stops gaining anything
/// from extra width once its cells are comfortable. No right-hand cap is
/// needed: under [useTodoCalendarSideBySide] the pane grows at 0.4 while the
/// chart grows at 0.6, so the chart clears its own floor at the gate and only
/// more comfortably above it.
double todoCalendarPaneWidth(double contentWidth) =>
    (contentWidth * 0.4).clamp(calendarCardMinWidth, 480.0);

/// Width, in logical pixels, of the timer page's session-history pane.
///
/// A duration at `bodyMedium`, a start timestamp and a thrust count beneath it,
/// and a trailing restore button. Fixed rather than proportional: the history
/// is a reference column, and every logical pixel beyond this belongs to the
/// stopwatch, which is what the page exists to show.
const timerHistoryPaneWidth = 320.0;

/// Screen width, in logical pixels, below which the timer's stopwatch digits
/// drop from `displayLarge` to `displayMedium`.
///
/// `HH:MM:SS` at `displayLarge` is about 300 logical pixels wide; on a folded
/// phone's outer screen that leaves almost no margin, and the page's controls
/// sit below the digits, so every row the digits wrap onto pushes them down.
const timerCompactDisplayWidth = 400.0;

/// Purpose: Decide whether the timer page should use its compact digits.
/// Inputs: `screenWidth` — the page's own width in logical pixels.
/// Returns: `bool` — true below [timerCompactDisplayWidth].
/// Side effects: None.
/// Notes: The timer page is pushed over the shell, so callers pass the full
/// screen width rather than `shellContentWidth`.
bool useCompactTimerDisplay(double screenWidth) =>
    screenWidth < timerCompactDisplayWidth;

/// Widest a dialog's content grows before the dialog starts centring instead,
/// in logical pixels.
///
/// Every form dialog in the app is a scrolling `Column` of full-width fields;
/// without a cap it takes whatever the window offers, and a text field 1300
/// logical pixels wide is harder to read than one at 600, not easier.
const dialogMaxContentWidth = 640.0;

/// Horizontal inset Flutter's own `Dialog` uses by default, in logical pixels.
const dialogMinHorizontalInset = 40.0;

/// Purpose: Return the horizontal inset that caps a dialog's content width.
/// Inputs: `screenWidth` — the whole screen width in logical pixels.
/// Returns: `double`, never below [dialogMinHorizontalInset].
/// Side effects: None.
/// Notes: Width only and no gate. Below about 720 the result is Flutter's own
/// default, so a phone dialog is untouched; above it the extra width becomes
/// inset on both sides, which centres the dialog rather than stretching it. A
/// dialog is drawn on the root overlay, so measure the **screen**, not the page
/// behind it — the navigation rail's width is part of what the dialog covers.
double dialogHorizontalInset(double screenWidth) {
  final inset = (screenWidth - dialogMaxContentWidth) / 2;
  return inset < dialogMinHorizontalInset ? dialogMinHorizontalInset : inset;
}

/// Minimum width, in logical pixels, one emoji or icon picker cell may occupy.
///
/// Material's minimum touch-target size. A picker cell is a square tap target
/// with nothing but a glyph in it, so the tap target *is* the minimum.
const pickerCellMinWidth = 44.0;

/// Largest number of picker columns, however wide the dialog is.
///
/// Beyond this the eye stops scanning a picker as a grid and starts scanning it
/// as noise; it also keeps the cells from growing far past a thumb.
const pickerMaxColumns = 12;

/// Purpose: Add the floating navigation bar's height to a page's padding.
/// Inputs: `context` — inside a shell page; `padding` — the page's own padding.
/// Returns: `EdgeInsets` — [padding] with the bottom inset reported by the
/// enclosing Scaffold added to its bottom.
/// Side effects: None.
/// Notes: With the Expressive bottom bar the shell uses `extendBody`, so pages
/// draw behind the bar and the Scaffold reports the bar's height as
/// `MediaQuery.padding.bottom`. Scroll views with an explicit padding do not
/// apply that inset themselves; passing their padding through here leaves room
/// to scroll the last content above the bar. Pages pushed with
/// `Navigator.push` (non-root) live inside the same shell navigator, so they
/// sit under the bar too and need this as well; only routes pushed with
/// `rootNavigator: true`, dialogs and root-navigator bottom sheets are above
/// it. `SingleChildScrollView`, `CustomScrollView` and `ReorderableListView`
/// never add the inset themselves, even with a null padding. Elsewhere
/// (classic bar, rail) the inset is just the system's, so this is harmless.
EdgeInsets navBarAwarePadding(BuildContext context, EdgeInsets padding) =>
    padding.copyWith(
      bottom: padding.bottom + MediaQuery.paddingOf(context).bottom,
    );

/// Minimum viewport width, in logical pixels, before a layout may split.
///
/// Material's *medium* width class and Android's `sw600dp` tablet threshold.
const splitMinWidth = 600.0;

/// Minimum viewport height, in logical pixels, before a layout may split.
///
/// Matches the boundary between Android's compact and medium height classes.
/// Google's own guidance is that a window whose height is compact — a phone or
/// an open flippable held in landscape — cannot practically carry two panes.
const splitMinHeight = 480.0;

/// Minimum viewport width-to-height ratio before a layout may split.
const splitMinAspect = 0.82;

/// Horizontal gap, in logical pixels, between columns of a multi-column list.
const listTileGap = 12.0;

/// Largest number of columns a list will use, however wide the window is.
const listMaxColumns = 4;

/// Column preference meaning "use whatever the width can fit".
const listColumnsAuto = 0;

/// Minimum viewport width, in logical pixels, before the shell shows its
/// navigation rail instead of a bottom navigation bar.
///
/// Material's *medium* width class, which is where Google's guidance moves
/// navigation to the side. This is a width-only threshold on purpose; see
/// [useNavigationRail].
const navRailMinWidth = 600.0;

/// Logical pixels the navigation rail takes from the content when it is shown.
///
/// An 80 dp `NavigationRail` plus the 1 dp `VerticalDivider` beside it.
const navRailWidth = 81.0;

/// Purpose: Report whether a layout may split into panes or columns.
/// Inputs: `width`, `height` — the viewport size in logical pixels.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Three independent conditions, because none of them alone is enough.
/// The aspect test is the load-bearing one: it keeps a viewport that is
/// meaningfully taller than it is wide on the original single-column layout, so
/// a Galaxy Z Fold 8 splits in landscape (4:3) but not in portrait (3:4), while
/// the near-square Fold 7 and Fold 8 Ultra split in both orientations. The width
/// floor is the usual `sw600dp` tablet threshold. The height floor exists
/// because the aspect test alone admits wide, short viewports — a folded cover
/// screen or an ordinary phone held in landscape would otherwise split into two
/// cramped panes. See `doc/en-us/adaptive-layout.md` for the full derivation.
bool canSplitLayout(double width, double height) {
  if (width < splitMinWidth) return false;
  if (height < splitMinHeight) return false;
  if (height <= 0) return false;
  return width / height >= splitMinAspect;
}

/// Purpose: Report whether the shell should show a navigation rail.
/// Inputs: `screenWidth` — the whole screen width in logical pixels.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: **Width only, deliberately** — this is not [canSplitLayout] and must
/// not be routed through it. A rail is not a split; it trades width, which is
/// abundant whenever this returns true, for height, which is not. The case it
/// helps most is the one the split rule rejects on purpose: an ordinary phone
/// held in landscape at 915 x 412, where a bottom bar spends 19% of the height
/// on navigation while 915 logical pixels of width sit unused.
bool useNavigationRail(double screenWidth) => screenWidth >= navRailMinWidth;

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

/// Purpose: Return how many columns of a given minimum width fit a content box.
/// Inputs: `contentWidth` — the width available, in logical pixels;
/// `minItemWidth` — the narrowest one column may be; `gap` — spacing between
/// columns; `maxColumns` — a ceiling however wide the box is.
/// Returns: `int`, at least 1 and at most `maxColumns`.
/// Side effects: None.
/// Notes: The adaptive-minimum-width approach Google recommends for feeds and
/// grids, rather than a hardcoded count per breakpoint. One gap is added to the
/// numerator so the arithmetic pays for the gaps *between* columns rather than
/// one after every column. Non-positive widths return 1.
int columnCapacity(
  double contentWidth, {
  required double minItemWidth,
  double gap = listTileGap,
  int maxColumns = listMaxColumns,
}) {
  final ceiling = maxColumns < 1 ? 1 : maxColumns;
  if (contentWidth <= 0) return 1;
  if (minItemWidth <= 0) return ceiling;
  final fit = ((contentWidth + gap) / (minItemWidth + gap)).floor();
  return fit.clamp(1, ceiling);
}

/// Purpose: Return how many rows a list of items needs at a column count.
/// Inputs: `itemCount`, `columns`.
/// Returns: `int`.
/// Side effects: None.
/// Notes: The last row may be short; callers pad it so the remaining tiles keep
/// their width instead of stretching across the row.
int listRowCount(int itemCount, int columns) {
  if (itemCount <= 0) return 0;
  final perRow = columns < 1 ? 1 : columns;
  return (itemCount + perRow - 1) ~/ perRow;
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

/// Smallest width, in logical pixels, the weight summary card may occupy when
/// it sits beside the trend chart rather than above it.
///
/// The card carries the latest weight at `displaySmall` beside a change figure,
/// then a `Wrap` of stat labels each constrained to 88-168.
const weightSummaryPaneMinWidth = 280.0;

/// Smallest width, in logical pixels, the weight trend chart may be given
/// before the summary card stops sitting beside it.
///
/// The chart reserves about 40 for its left axis and needs roughly 48 per date
/// label, so this shows about seven labelled points without crowding.
const weightChartMinWidth = 380.0;

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

/// Purpose: Return the width of the intimacy page's fixed left pane.
/// Inputs: `contentWidth` — the width both panes share, in logical pixels.
/// Returns: `double`.
/// Side effects: None.
/// Notes: The floor is higher than the finance page's because this pane holds a
/// month calendar: seven columns plus the card's own padding do not fit below
/// about 320, and squeezing them turns the day numbers into a smear.
double intimacyLeftPaneWidth(double contentWidth) =>
    (contentWidth * 0.36).clamp(320.0, 440.0);

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

/// Purpose: Report whether the weight summary card fits beside the trend chart.
/// Inputs: `contentWidth` — the width the weight body gets, in logical pixels.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: A width floor **on top of** [canSplitLayout], not instead of it. The
/// split rule alone admits viewports the size of a Z Fold 5 in portrait, where
/// the chart would be left about 300 logical pixels and show four date labels.
/// Callers must test both, and must also test that there is a chart at all —
/// it renders nothing below two records, and a summary card alone in a 280 pane
/// beside a blank half is worse than the stacked layout it replaced.
bool useWeightSummaryBesideChart(double contentWidth) =>
    contentWidth >=
    weightSummaryPaneMinWidth + weightChartMinWidth + listTileGap;

/// Purpose: Return the width of the weight summary card when it sits beside
/// the trend chart.
/// Inputs: `contentWidth` — the width both blocks share, in logical pixels.
/// Returns: `double`.
/// Side effects: None.
/// Notes: No right-hand cap, unlike [settingsLeftPaneWidth], because none can
/// bind: under [useWeightSummaryBesideChart] the card grows at 0.34 of the
/// width while the chart grows at 0.66, so [weightChartMinWidth] is met exactly
/// at the gate and only more comfortably above it.
double weightSummaryPaneWidth(double contentWidth) =>
    (contentWidth * 0.34).clamp(weightSummaryPaneMinWidth, 380.0);

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

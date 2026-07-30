# lib/features/intimacy/views/intimacy_page.dart

The Intimacy feature's main view file — by far the largest source file in the whole app (5642
lines). It hosts the home `IntimacyPage` (calendar, record list, trend chart, manage
menu) and every management/detail sub-page reached from it: partner management, toy management,
position management, the filtered per-partner/per-toy detail page (with its Records/Body tabs),
the aggregate toy-cost overview, and the small shared widgets (`_CalendarWidget`, `_RecordTile`,
`_DatePickerTile`) used across them. Models come from `../models/intimacy_record.dart`; storage
is `../services/intimacy_storage.dart`; cycle math is `../services/cycle_predictor.dart`. See
[Intimacy](../../../../features/intimacy.md) for the full feature description,
[Data Formats](../../../../data-formats.md#intimacy--intimacy_datajson) for the on-disk JSON
shape, and [Body Metrics](../../../../algorithms/body-metrics.md) for cycle prediction details
consumed here via `_buildCycleOverlays`.

Structurally the file is one home page (`IntimacyPage` / `_IntimacyPageState`) plus ten
supporting classes, in source order: `_IntimacyDataError`, `_CalendarWidget`, `_RecordTile`,
`_PartnerManagementPage` (+ state), `_ToyManagementPage` (+ state), `_PositionManagementPage` (+
state), `_FilteredRecordsPage` (+ state), `_ToyCostOverviewPage` (+ state), `_ToyCostTrendData`,
and `_DatePickerTile`. The partner and toy management states are near-mirror implementations
(custom sort/reorder, active/inactive or active/retired grouping).

As of v1.3.2 the record-metric trend charts no longer live here. The home page's two charts and
`_FilteredRecordsTrendSection`'s two near-verbatim copies were replaced by the single
[`IntimacyTrendChart`](../widgets/intimacy_trend_chart.md) widget, which both surfaces now embed;
27 declarations (the spot builders, ceiling helpers, legend items, date-interval helpers, and the
whole `_FilteredRecordsTrendSection` pair) were deleted, and `_saveChartSettings` was added to
persist the chart's shared selection. The toy daily-cost trend chart on `_ToyCostOverviewPage`
stays here — it plots money over a projected date timeline on a log scale — and it now shares the
public `IntimacyChartRange` enum exported by the chart widget instead of a private duplicate.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `IntimacyPage.new` | constructor | B | Trivial forwarding constructor. |
| `IntimacyPage.createState` | method (`IntimacyPage`) | B | Create `_IntimacyPageState`. |
| `_IntimacyPageState.initState` | method (lifecycle) | B | Load data and register the auto-sync listener. |
| `_IntimacyPageState.dispose` | method (lifecycle) | B | Unregister the auto-sync listener. |
| [`_loadData`](#loaddata) | method (`_IntimacyPageState`) | A | Load `intimacy_data.json` into state, or surface a blocking read error. |
| [`_saveData`](#savedata) | method (`_IntimacyPageState`) | A | Persist current state to storage and notify auto-sync, unless loading or unreadable. |
| [`_saveTimerState`](#savetimerstate) | method (`_IntimacyPageState`) | A | Persist timer history/session changes streamed back from the open `TimerPage`. |
| [`_saveChartSettings`](#savechartsettings) | method (`_IntimacyPageState`) | A | Persist a new trend-chart metric and range selection reported by any `IntimacyTrendChart`. |
| `_markedDates` | getter (`_IntimacyPageState`) | B | Set of calendar days that have at least one record. |
| [`_buildCycleOverlays`](#buildcycleoverlays) | method (`_IntimacyPageState`) | A | Build the per-person cycle overlay list shown on the home calendar. |
| `_buildCycleCalendarExtras` | method (widget helper) | B | Render the cycle legend and selected-day cycle strip below the calendar. |
| [`_filteredRecords`](#filteredrecords-main) | getter (`_IntimacyPageState`) | A | Apply the selected-date, type, and sort filters to the record list. |
| [`_addRecord`](#addrecord-main) | method (`_IntimacyPageState`) | A | Open the add-record dialog (active partners/toys only) and persist the result. |
| [`_deleteRecord`](#deleterecord-main) | method (`_IntimacyPageState`) | A | Remove a record by id and persist. |
| [`_editRecord`](#editrecord-main) | method (`_IntimacyPageState`) | A | Open the edit-record dialog and persist the updated record. |
| `_IntimacyPageState.build` | method (widget) | B | Build the home page: calendar, chart section, and record list/summary. |
| `_showAllRecords` | method (widget helper) | B | Show the full filtered record list in a modal bottom sheet. |
| `_buildRecordListWidgets` | method (widget helper) | B | Build the weekly-grouped record list widgets (main page). |
| `_buildWeekHeader` | method (widget helper) | B | Build an ISO-week group header row (main page). |
| `_buildRecordDismissible` | method (widget helper) | B | Build a swipe-to-delete record row (main page). |
| `_buildSortChip` | method (widget helper) | B | Build the sort-mode chip/menu. |
| `_buildFilterChip` | method (widget helper) | B | Build the filter-mode chip/menu. |
| `_showManageMenu` | method (widget helper) | B | Show the bottom-sheet manage menu (Body/Partners/Toys/Positions). |
| `_openBodySettings` | method (widget helper) | B | Push `BodySettingsPage` and persist any user-body change on return. |
| `_openPartnerManagement` | method (widget helper) | B | Push `_PartnerManagementPage` and persist changes on return. |
| `_openToyManagement` | method (widget helper) | B | Push `_ToyManagementPage` and persist changes on return. |
| `_openPositionManagement` | method (widget helper) | B | Push `_PositionManagementPage` and persist changes on return. |
| `_IntimacyDataError.new` | constructor | B | Trivial forwarding constructor. |
| `_IntimacyDataError.build` | method (widget) | B | Render the blocking "data unreadable" recovery view. |
| `_CalendarWidget.new` | constructor | B | Trivial forwarding constructor. |
| `_CalendarWidget.build` | method (widget) | B | Render the month grid, header, and weekday labels. |
| `_buildDayGrid` | method (widget helper) | B | Build the calendar's day-number grid. |
| `_isSameDay` | method (`_CalendarWidget`) | B | Compare two dates ignoring time-of-day. |
| `_RecordTile.new` | constructor | B | Trivial forwarding constructor. |
| `_RecordTile.build` | method (widget) | B | Render one record's summary tile (partner/toys/position/flags). |
| `_PartnerManagementPage.new` | constructor | B | Trivial forwarding constructor. |
| `_PartnerManagementPage.createState` | method (`_PartnerManagementPage`) | B | Create `_PartnerManagementPageState`. |
| `_PartnerManagementPageState.initState` | method (lifecycle) | B | Copy incoming partners/sort state into local mutable fields. |
| `_notifySort` | method (`_PartnerManagementPageState`) | B | Forward the current sort modes/custom orders to the parent callback. |
| `_statusKey` | method (`_PartnerManagementPageState`) | B | Map an active/inactive flag to its sort-state map key. |
| `_sortMode` | method (`_PartnerManagementPageState`) | B | Look up the active sort mode for a status group. |
| `_compareText` | method (`_PartnerManagementPageState`) | B | Case-insensitive string comparator. |
| [`_compareNullableDates`](#comparenullabledates-partner) | method (`_PartnerManagementPageState`) | A | Null-tolerant date comparator (nulls sort last). |
| `_partnerRecordCount` | method (`_PartnerManagementPageState`) | B | Count records referencing a partner id. |
| [`_normalizedOrder`](#normalizedorder-partner) | method (`_PartnerManagementPageState`) | A | Reconcile the stored custom order with the current partner id set. |
| [`_sortPartners`](#sortpartners) | method (`_PartnerManagementPageState`) | A | Sort a partner list by date, record count, name, or custom order. |
| [`_setSortMode`](#setsortmode-partner) | method (`_PartnerManagementPageState`) | A | Switch a status group's sort mode, seeding custom order on first use. |
| [`_appendPartnerToCustomOrderIfNeeded`](#appendpartnertocustomorderifneeded) | method (`_PartnerManagementPageState`) | A | Add a partner into its group's custom order if that group uses custom sort. |
| [`_removePartnerFromCustomOrders`](#removepartnerfromcustomorders) | method (`_PartnerManagementPageState`) | A | Remove a partner id from every stored custom order list. |
| [`_reorderPartners`](#reorderpartners) | method (`_PartnerManagementPageState`) | A | Apply a drag-reorder gesture to a status group's custom order. |
| `_addPartner` | method (`_PartnerManagementPageState`) | B | Forward to `_showEditDialog(null)`. |
| `_editPartner` | method (`_PartnerManagementPageState`) | B | Forward to `_showEditDialog(p)`. |
| [`_deletePartner`](#deletepartner) | method (`_PartnerManagementPageState`) | A | Delete a partner and its cycle records; activity records keep their dangling id. |
| [`_breakUpPartner`](#breakuppartner) | method (`_PartnerManagementPageState`) | A | Mark a partner separated: sets `endDate`, disables their calendar cycle overlay, re-sorts into inactive. |
| `_showPartnerRecords` | method (widget helper) | B | Push `_FilteredRecordsPage` scoped to one partner. |
| `_showEditDialog` (Partner) | method (widget helper / dialog) | B | Build and drive the add/edit partner dialog (name, emoji, image, dates, body). |
| `signature` (Partner dialog) | local function (in `_showEditDialog`) | B | Compute a change-detection signature for the partner form. |
| `_buildImageRow` (Partner) | method (widget helper) | B | Build the emoji/image picker row (partner dialog). |
| `_partnerSubtitle` | method (`_PartnerManagementPageState`) | B | Compose a partner tile's subtitle (record count + date range). |
| `fmt` (partner subtitle) | local function (in `_partnerSubtitle`) | B | Format a date as `yyyy-MM-dd`. |
| `_activePartners` | getter (`_PartnerManagementPageState`) | B | Sorted list of partners without an end date. |
| `_inactivePartners` | getter (`_PartnerManagementPageState`) | B | Sorted list of partners with an end date. |
| `_PartnerManagementPageState.build` | method (widget) | B | Render the partner management page (active/inactive sections). |
| `_buildPartnerSection` | method (widget helper) | B | Build one status section (header + tile list or reorder list). |
| `_buildManagedSectionHeader` (Partner) | method (widget helper) | B | Build a section header with count and sort-mode menu button. |
| `_managedSortItem` (Partner) | method (widget helper) | B | Build one sort-mode popup menu entry. |
| `_buildPartnerReorderList` | method (widget helper) | B | Build the `ReorderableListView` used in custom-sort mode. |
| `_buildPartnerTile` | method (widget helper) | B | Build one partner's list tile (avatar, subtitle, actions). |
| `_buildPartnerAvatar` | method (widget helper) | B | Build a partner's avatar (image, emoji, or initial). |
| `_ToyManagementPage.new` | constructor | B | Trivial forwarding constructor. |
| `_ToyManagementPage.createState` | method (`_ToyManagementPage`) | B | Create `_ToyManagementPageState`. |
| `_ToyManagementPageState.initState` | method (lifecycle) | B | Copy incoming toys/sort state into local mutable fields. |
| `_notifySort` (Toy) | method (`_ToyManagementPageState`) | B | Forward the current sort modes/custom orders to the parent callback. |
| `_statusKey` (Toy) | method (`_ToyManagementPageState`) | B | Map a retired flag to its sort-state map key. |
| `_sortMode` (Toy) | method (`_ToyManagementPageState`) | B | Look up the active sort mode for a status group. |
| `_compareText` (Toy) | method (`_ToyManagementPageState`) | B | Case-insensitive string comparator. |
| [`_compareNullableDates`](#comparenullabledates-toy) | method (`_ToyManagementPageState`) | A | Null-tolerant date comparator (nulls sort last). |
| `_toyRecordCount` | method (`_ToyManagementPageState`) | B | Count records referencing a toy id. |
| `_formatMoney` (Toy mgmt) | method (`_ToyManagementPageState`) | B | Format a plain dollar amount. |
| [`_totalToyCost`](#totaltoycost) | method (`_ToyManagementPageState`) | A | Sum `Toy.totalCost()` across a toy list. |
| [`_totalDailyToyCost`](#totaldailytoycost) | method (`_ToyManagementPageState`) | A | Sum `Toy.averageDailyCost()` across a toy list, or null if none costable. |
| [`_normalizedOrder`](#normalizedorder-toy) | method (`_ToyManagementPageState`) | A | Reconcile the stored custom order with the current toy id set. |
| [`_sortToys`](#sorttoys) | method (`_ToyManagementPageState`) | A | Sort a toy list by date, record count, name, or custom order. |
| [`_setSortMode`](#setsortmode-toy) | method (`_ToyManagementPageState`) | A | Switch a status group's sort mode, seeding custom order on first use. |
| [`_appendToyToCustomOrderIfNeeded`](#appendtoytocustomorderifneeded) | method (`_ToyManagementPageState`) | A | Add a toy into its group's custom order if that group uses custom sort. |
| [`_removeToyFromCustomOrders`](#removetoyfromcustomorders) | method (`_ToyManagementPageState`) | A | Remove a toy id from every stored custom order list. |
| [`_reorderToys`](#reordertoys) | method (`_ToyManagementPageState`) | A | Apply a drag-reorder gesture to a status group's custom order. |
| `_addToy` | method (`_ToyManagementPageState`) | B | Forward to `_showEditDialog(null)`. |
| `_editToy` | method (`_ToyManagementPageState`) | B | Forward to `_showEditDialog(t)`. |
| [`_deleteToy`](#deletetoy) | method (`_ToyManagementPageState`) | A | Delete a toy, clean its custom-order entries, and notify the parent. |
| [`_retireToy`](#retiretoy) | method (`_ToyManagementPageState`) | A | Mark a toy retired (sets `retiredDate`, re-sorts into the retired group). |
| `_showToyRecords` | method (widget helper) | B | Push `_FilteredRecordsPage` scoped to one toy. |
| `_showToyCostOverview` | method (widget helper) | B | Push `_ToyCostOverviewPage`. |
| `_showEditDialog` (Toy) | method (widget helper / dialog) | B | Build and drive the add/edit toy dialog (name, link, price, dates, image). |
| `signature` (Toy dialog) | local function (in `_showEditDialog`) | B | Compute a change-detection signature for the toy form. |
| `_buildImageRow` (Toy) | method (widget helper) | B | Build the emoji/image picker row (toy dialog). |
| `_toySubtitle` | method (`_ToyManagementPageState`) | B | Compose a toy tile's subtitle (record count + purchase/retired dates). |
| `fmt` (toy subtitle, purchase) | local function (in `_toySubtitle`) | B | Format the purchase date as `yyyy-MM-dd`. |
| `fmt` (toy subtitle, retired) | local function (in `_toySubtitle`) | B | Format the retired date as `yyyy-MM-dd`. |
| `_activeToys` | getter (`_ToyManagementPageState`) | B | Sorted list of toys without a retired date. |
| `_retiredToys` | getter (`_ToyManagementPageState`) | B | Sorted list of toys with a retired date. |
| `_ToyManagementPageState.build` | method (widget) | B | Render the toy management page (active/retired sections + cost summary). |
| `_buildActiveCostSummary` | method (widget helper) | B | Render the active-toy total/daily cost summary entry. |
| `_buildCostMetric` (Toy mgmt) | method (widget helper) | B | Build a compact labeled cost metric column. |
| `_buildToySection` | method (widget helper) | B | Build one status section (header + tile list or reorder list). |
| `_buildManagedSectionHeader` (Toy) | method (widget helper) | B | Build a section header with count and sort-mode menu button. |
| `_managedSortItem` (Toy) | method (widget helper) | B | Build one sort-mode popup menu entry. |
| `_buildToyReorderList` | method (widget helper) | B | Build the `ReorderableListView` used in custom-sort mode. |
| `_buildToyTile` | method (widget helper) | B | Build one toy's list tile (avatar, subtitle, actions). |
| `_buildToyAvatar` | method (widget helper) | B | Build a toy's avatar (image, emoji, or initial). |
| `_PositionManagementPage.new` | constructor | B | Trivial forwarding constructor. |
| `_PositionManagementPage.createState` | method (`_PositionManagementPage`) | B | Create `_PositionManagementPageState`. |
| `_PositionManagementPageState.initState` | method (lifecycle) | B | Copy incoming positions into a local mutable field. |
| `_addPosition` | method (`_PositionManagementPageState`) | B | Forward to `_showEditDialog(null)`. |
| `_editPosition` | method (`_PositionManagementPageState`) | B | Forward to `_showEditDialog(p)`. |
| `_deletePosition` | method (`_PositionManagementPageState`) | B | Remove a position by id and notify the parent. |
| [`_importDefaults`](#importdefaults) | method (`_PositionManagementPageState`) | A | Add the built-in default position presets that aren't already present by name. |
| `_showEditDialog` (Position) | method (widget helper / dialog) | B | Build and drive the add/edit position dialog (name, emoji). |
| `signature` (Position dialog) | local function (in `_showEditDialog`) | B | Compute a change-detection signature for the position form. |
| `_PositionManagementPageState.build` | method (widget) | B | Render the position management page and import-defaults menu action. |
| `_FilteredRecordsPage.new` | constructor | B | Trivial forwarding constructor. |
| `_FilteredRecordsPage.createState` | method (`_FilteredRecordsPage`) | B | Create `_FilteredRecordsPageState`. |
| `_FilteredRecordsPageState.initState` | method (lifecycle) | B | Copy incoming records into a local mutable field. |
| `_FilteredRecordsPageState.didUpdateWidget` | method (lifecycle) | B | Refresh the local record copy if the parent supplies a replaced list. |
| `_hasBodyTab` | getter (`_FilteredRecordsPageState`) | B | Whether this detail page should show the partner Records/Body tabs. |
| [`_filteredRecords`](#filteredrecords-filtered) | getter (`_FilteredRecordsPageState`) | A | Records matching this page's partner or toy filter, newest first. |
| `_selectedToy` | getter (`_FilteredRecordsPageState`) | B | The `Toy` this detail page is scoped to, if any. |
| [`_dialogPartners`](#dialogpartners) | method (`_FilteredRecordsPageState`) | A | Build the partner picker list for the add/edit record dialog. |
| [`_dialogToys`](#dialogtoys) | method (`_FilteredRecordsPageState`) | A | Build the toy picker list for the add/edit record dialog. |
| `_notifyRecordsChanged` | method (`_FilteredRecordsPageState`) | B | Forward a copy of the local record list to the parent callback. |
| [`_addRecord`](#addrecord-filtered) | method (`_FilteredRecordsPageState`) | A | Open the add-record dialog preselecting the current partner/toy. |
| [`_editRecord`](#editrecord-filtered) | method (`_FilteredRecordsPageState`) | A | Open the edit-record dialog for one record and update local state. |
| [`_deleteRecord`](#deleterecord-filtered) | method (`_FilteredRecordsPageState`) | A | Remove a record by id from local state and notify the parent. |
| [`_formatDuration`](#formatduration) | method (`_FilteredRecordsPageState`) | A | Format a duration as `Xh Ym` or `Ym`. |
| `_formatMoney` (Filtered page) | method (`_FilteredRecordsPageState`) | B | Format a plain dollar amount. |
| `_buildSummaryCard` (Filtered page) | method (widget helper) | B | Build the top summary card (averages, plus cost metrics for a toy). |
| `_buildSummaryMetric` | method (widget helper) | B | Build one labeled metric column inside the summary card. |
| `_buildRecordDismissible` (Filtered page) | method (widget helper) | B | Build a swipe-to-delete record row (filtered page). |
| `_buildRecordListWidgets` (Filtered page) | method (widget helper) | B | Build the weekly-grouped record list widgets (filtered page). |
| `_buildWeekHeader` (Filtered page) | method (widget helper) | B | Build an ISO-week group header row (filtered page). |
| `_FilteredRecordsPageState.build` | method (widget) | B | Render either the plain layout or the partner Records/Body tab layout. |
| `_buildRecordsListView` | method (widget helper) | B | Build the shared summary/trend/record-list scroll view. |
| `_buildBodyTab` | method (widget helper) | B | Render the partner's Body tab hosting the shared `BodySectionView`. |
| `_ToyCostOverviewPage.new` | constructor | B | Trivial forwarding constructor. |
| `_ToyCostOverviewPage.createState` | method (`_ToyCostOverviewPage`) | B | Create `_ToyCostOverviewPageState`. |
| `_selectedToys` | getter (`_ToyCostOverviewPageState`) | B | Toys included under the current all/active/retired scope. |
| `_ToyCostOverviewPageState.build` | method (widget) | B | Render the scope selector, summary card, and trend/finalized-cost card. |
| `_buildScopeSelector` | method (widget helper) | B | Build the all/active/retired `SegmentedButton`. |
| `_buildSummaryCard` (Cost overview) | method (widget helper) | B | Build the current scope's aggregate cost summary card. |
| `_buildCostMetric` (Cost overview) | method (widget helper) | B | Build a compact labeled aggregate cost metric column. |
| `_buildFinalizedCostNote` | method (widget helper) | B | Build the "retired costs are finalized" note card. |
| `_buildTrendCard` | method (widget helper) | B | Build the aggregate daily-cost trend card (active/all scopes). |
| `_buildCostChart` | method (widget helper) | B | Build the log-scale aggregate daily-cost line chart. |
| `_legendLine` (Cost overview) | method (widget helper) | B | Build a solid/dashed line legend marker. |
| [`_buildTrendData`](#buildtrenddata) | method (`_ToyCostOverviewPageState`) | A | Build history/future daily-cost spots and y-bounds for the sampled timeline. |
| [`_dailyCostAt`](#dailycostat) | method (`_ToyCostOverviewPageState`) | A | Sum every included toy's daily cost on one date. |
| [`_toyDailyCostAt`](#toydailycostat) | method (`_ToyCostOverviewPageState`) | A | Compute one toy's average daily cost as of one date. |
| [`_historyStart`](#historystart) | method (`_ToyCostOverviewPageState`) | A | Return the first date shown for the selected chart range. |
| [`_futureEnd`](#futureend) | method (`_ToyCostOverviewPageState`) | A | Return the projected end date for the selected chart range. |
| [`_earliestPurchaseDate`](#earliestpurchasedate) | method (`_ToyCostOverviewPageState`) | A | Return the earliest purchase date among a toy list. |
| [`_timeline`](#timeline) | method (`_ToyCostOverviewPageState`) | A | Build the sampled date list plotted on the cost trend chart. |
| [`_dateOnly`](#dateonly) | method (`_ToyCostOverviewPageState`) | A | Strip the time-of-day component from a `DateTime`. |
| [`_chartBounds`](#chartbounds) | method (`_ToyCostOverviewPageState`) | A | Pad y-axis bounds so flat/zero-cost charts stay visible. |
| [`_logTransform`](#logtransform) | method (`_ToyCostOverviewPageState`) | A | Map a cost value onto a signed log10 scale for charting. |
| [`_logInverse`](#loginverse) | method (`_ToyCostOverviewPageState`) | A | Invert `_logTransform` for axis labels and tooltips. |
| [`_dateInterval`](#dateinterval) | method (`_ToyCostOverviewPageState`) | A | Return the bottom-axis date-label interval for the given x-range. |
| [`_dateLabel`](#datelabel) | method (`_ToyCostOverviewPageState`) | A | Format a chart date-axis label, scaling precision to the x-range span. |
| `_moneyText` | method (`_ToyCostOverviewPageState`) | B | Format a plain dollar amount for tooltips. |
| [`_axisText`](#axistext) | method (`_ToyCostOverviewPageState`) | A | Format a y-axis value compactly (`k`/`m` suffixes). |
| [`_totalCost`](#totalcost) | method (`_ToyCostOverviewPageState`) | A | Sum `Toy.totalCost()` across a toy list. |
| [`_totalDailyCost`](#totaldailycost) | method (`_ToyCostOverviewPageState`) | A | Sum `Toy.averageDailyCost()` across a toy list, or null if none costable. |
| `_scopeLabel` | method (`_ToyCostOverviewPageState`) | B | Return the localized label for an all/active/retired scope. |
| `_ToyCostTrendData.new` | constructor | B | Trivial forwarding constructor. |
| `_DatePickerTile.new` | constructor | B | Trivial forwarding constructor. |
| `_DatePickerTile.build` | method (widget) | B | Render a labeled tappable date field. |

**Row count reconciliation:** 175 rows above, matching `grep -c '/// Purpose:'` = 175 exactly (53
Tier A, 122 Tier B). v1.3.2 removed 27 rows (17 Tier A, 10 Tier B) when the record-metric charts
moved to [`intimacy_trend_chart.dart`](../widgets/intimacy_trend_chart.md), and added one
(`_saveChartSettings`, Tier A). See the note at the end of this page for how duplicate-named
declarations
(the same helper name reimplemented in more than one class, e.g. `_filteredRecords` in both
`_IntimacyPageState` and `_FilteredRecordsPageState`) are disambiguated in anchors.

## Documentation

### `Future<void> _loadData()` <a id="loaddata"></a>
- **Kind:** method of `_IntimacyPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 172)
- **Purpose:** Load `intimacy_data.json` into page state, or record a blocking read error.
- **Inputs:** None (reads `IntimacyStorage.load()`).
- **Returns:** `Future<void>`.
- **Side effects:** Sets `_loaded = false` while reloading (if already loaded and mounted), then
  populates every intimacy field (`_partners`, `_toys`, `_positions`, `_records`, timer
  history/session, user body, cycle records, retention, sort modes/custom orders,
  `_settingsModifiedAt`) via `setState`.
- **Algorithm:**
  1. If already loaded and still mounted, flip `_loaded` to `false` first so the UI can show a
     loading/stale state during a reload.
  2. Call `IntimacyStorage.load()`; on exception, store `e.toString()` in `_loadError`, set
     `_loaded = true`, and return — an unreadable file is surfaced as an error, never silently
     treated as empty data.
  3. On success, clear `_loadError` and copy every field off the loaded `IntimacyData` (defensive
     list/map copies for cycle records and custom orders so page-owned collections are mutable).
  4. Set `_loaded = true` unconditionally at the end of the `setState` block.
- **Usage:**
  ```dart
  @override
  void initState() {
    super.initState();
    _loadData();
    AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  }
  ```
- **Notes:** Registered as the auto-sync "local data changed" callback, so a background sync pull
  reloads this page's in-memory state automatically.

### `Future<void> _saveData()` <a id="savedata"></a>
- **Kind:** method of `_IntimacyPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 220)
- **Purpose:** Persist the current in-memory intimacy state to disk and notify auto-sync.
- **Inputs:** None (reads all `_IntimacyPageState` fields).
- **Returns:** `Future<void>`.
- **Side effects:** Writes `intimacy_data.json` via `IntimacyStorage.save`; calls
  `AutoSyncService.instance.notifySaved()`; may show a snackbar.
- **Algorithm:**
  1. If `!_loaded`, return immediately (never overwrite storage with a partially-loaded state).
  2. If `_loadError != null`, show the `intimacyDataWriteBlocked` snackbar and return — writes are
     refused while the file is known-unreadable, so a corrupt file is never silently replaced by
     an incomplete in-memory reconstruction.
  3. Otherwise build a fresh `IntimacyData` from every field and call `IntimacyStorage.save`.
  4. Call `AutoSyncService.instance.notifySaved()` to schedule a sync push.
- **Usage:**
  ```dart
  void _deleteRecord(IntimacyRecord record) {
    setState(() => _records.removeWhere((r) => r.id == record.id));
    _saveData();
  }
  ```
- **Notes:** Every mutating action on the home page (`_addRecord`, `_editRecord`, `_deleteRecord`,
  `_openPartnerManagement`/`_openToyManagement`/`_openPositionManagement` returns, body/timer
  settings) funnels through this one save path.

### `Future<void> _saveTimerState({required List<TimerHistoryEntry> history, required IntimacyTimerSession? session, required bool historyChanged, required bool timerSessionChanged, required int? retentionDays, required bool retentionChanged})` <a id="savetimerstate"></a>
- **Kind:** method of `_IntimacyPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 262)
- **Purpose:** Persist timer history/session/retention changes streamed back from the still-open
  `TimerPage`.
- **Inputs:** `history`, `session`, `retentionDays`, plus three `bool` flags telling which of
  those actually changed.
- **Returns:** `Future<void>`.
- **Side effects:** Updates `_timerHistory`, `_timerSession`, `_timerHistoryRetentionDays` (and,
  conditionally, `_timerSessionModifiedAt`/`_settingsModifiedAt`) via `setState`; calls
  `_saveData()` if anything changed.
- **Algorithm:**
  1. `setState` the three raw values unconditionally.
  2. Only bump `_timerSessionModifiedAt` to `DateTime.now().toUtc()` if `timerSessionChanged` —
     the timer session has its own independent last-write-wins timestamp, separate from general
     settings.
  3. Only bump `_settingsModifiedAt` if `retentionChanged`.
  4. Call `_saveData()` only if history, session, or retention changed — a callback fired with no
     actual change performs no write.
- **Usage:** Passed as the `onStateChanged`-style callback to `TimerPage` from
  `_showManageMenu`/timer entry points elsewhere in `build()`; `TimerPage` invokes it on every
  timer tick/pause/save so the parent page's storage stays in sync while the timer UI is open.
- **Notes:** Keeping the timer session's own modified-timestamp separate from
  `_settingsModifiedAt` matters for the three-way merge — see
  [Timer/stopwatch session persistence](../../../../features/intimacy.md#timerstopwatch-session-persistence).

### `Future<void> _saveChartSettings(IntimacyChartSettings settings)` <a id="savechartsettings"></a>
- **Kind:** method of `_IntimacyPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 257)
- **Purpose:** Persist a new trend-chart metric and range selection.
- **Inputs:** `settings` — the complete new selection reported by an `IntimacyTrendChart`.
- **Returns:** `Future<void>`.
- **Side effects:** Updates `_chartSettings` and `_settingsModifiedAt` via `setState`, then calls
  `_saveData()`, which writes `intimacy_data.json` and notifies auto-sync.
- **Algorithm:**
  1. `setState` the new settings and stamp `_settingsModifiedAt` with `DateTime.now().toUtc()`.
  2. `await _saveData()`.
- **Usage:** Passed as `onSettingsChanged` to the home page's `IntimacyTrendChart`, and threaded
  down as `onChartSettingsChanged` through `_PartnerManagementPage`/`_ToyManagementPage` to
  `_FilteredRecordsPage`, so every copy of the chart writes through this one method.
- **Notes:** The selection joins the module's `settingsModifiedAt` last-write-wins group, which is
  why the timestamp is bumped here rather than inside `_saveData()`. Routing every surface's
  writes through the home page's state avoids a second writer for `intimacy_data.json` — see
  [The consolidated trend chart](../../../../features/intimacy.md#the-consolidated-trend-chart-v132).

### `List<PersonCycleOverlay> _buildCycleOverlays(AppLocalizations l10n)` <a id="buildcycleoverlays"></a>
- **Kind:** method of `_IntimacyPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 303)
- **Purpose:** Build the list of per-person cycle overlays shown on the home calendar.
- **Inputs:** `l10n` (for the user's own display label).
- **Returns:** `List<PersonCycleOverlay>` — one entry per eligible person (user first, then
  partners), each carrying a `CyclePrediction` for a two-month window around `_focusedMonth`.
- **Side effects:** None (pure derivation from `_userBody`, `_partners`, `_cycleRecords`).
- **Algorithm:**
  1. Compute a `windowStart`/`windowEnd` spanning one month before to one month after
     `_focusedMonth`.
  2. Define a local `predictionFor(personId)` that calls `predictCycle` over that person's actual
     cycle-record start days within the window.
  3. Include the user only if `_userBody != null && cycleEnabled && showCycleOnCalendar`.
  4. For each partner, include them only if `partner.body` is non-null and both `cycleEnabled` and
     `showCycleOnCalendar` are true; others are skipped entirely (never appear on the shared
     calendar even if they have cycle data).
  5. Assign each included person a stable palette color via `cyclePersonColor` (user = slot 0,
     partners keyed by their id's position in the full sorted partner-id list, so colors don't
     shift when an unrelated partner is added).
- **Usage:**
  ```dart
  cycleOverlays: _buildCycleOverlays(l10n),
  ..._buildCycleCalendarExtras(theme, l10n),
  ```
- **Notes:** Cycle prediction itself (menses/fertile window/ovulation/phase) is
  `services/cycle_predictor.dart`'s `predictCycle`, documented in
  [Body Metrics § Cycle prediction](../../../../algorithms/body-metrics.md#cycle-prediction); this
  method only decides *who* appears and *which color* they get.

### `List<IntimacyRecord> get _filteredRecords` (in `_IntimacyPageState`) <a id="filteredrecords-main"></a>
- **Kind:** getter of `_IntimacyPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 421)
- **Purpose:** Apply the selected calendar date, type filter, and sort mode to the full record
  list for display on the home page.
- **Inputs:** None (reads `_records`, `_selectedDate`, `_filterMode`, `_sortMode`).
- **Returns:** `List<IntimacyRecord>` — a new filtered/sorted list; `_records` itself is untouched.
- **Side effects:** None.
- **Algorithm:**
  1. Start from a copy of `_records`.
  2. If a calendar date is selected, keep only records whose `datetime` falls on that exact
     year/month/day.
  3. Apply `_filterMode` (`solo`/`partnered`/`orgasm`/`noOrgasm`/`all`) as a `where` predicate on
     `isSolo`/`hadOrgasm`.
  4. Apply `_sortMode` (`dateDesc`/`dateAsc`/`pleasureDesc`/`durationDesc`) as an in-place `sort`.
  5. Return the result.
- **Usage:**
  ```dart
  final filteredRecords = _filteredRecords;
  // ... and separately:
  final records = _filteredRecords; // used by _showAllRecords
  ```
- **Notes:** Date filter and type filter compose (both apply together); sort always runs last so
  it applies to whatever subset survived filtering.

### `Future<void> _addRecord()` (in `_IntimacyPageState`) <a id="addrecord-main"></a>
- **Kind:** method of `_IntimacyPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 468)
- **Purpose:** Open the add-record dialog, offering only active partners/toys, and persist the
  result.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Shows `AddRecordDialog`; on a non-null result, inserts into `_records` via
  `setState` and calls `_saveData()`.
- **Algorithm:**
  1. Compute `activePartners` (no `endDate`) and `activeToys` (no `retiredDate`) so broken-up
     partners and retired toys aren't offered for *new* records.
  2. Await `showDialog<IntimacyRecord>` with `AddRecordDialog`.
  3. If the dialog returned a record, `setState` to add it, then `_saveData()`.
- **Usage:** Wired to the home page's floating add button in `build()`.
- **Notes:** Contrast with `_editRecord`, which must still let an *existing* record keep a
  reference to an inactive partner/toy — see the deleted-partner tolerance note under
  [`_editRecord`](#editrecord-main).

### `void _deleteRecord(IntimacyRecord record)` (in `_IntimacyPageState`) <a id="deleterecord-main"></a>
- **Kind:** method of `_IntimacyPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 490)
- **Purpose:** Remove one record by id and persist.
- **Inputs:** `record` — the record to delete (matched by id).
- **Returns:** None.
- **Side effects:** `setState` removes the matching record from `_records`; calls `_saveData()`.
- **Algorithm:** Single `removeWhere((r) => r.id == record.id)` inside `setState`, then save.
- **Usage:**
  ```dart
  onDismissed: (_) => _deleteRecord(record),
  ```
  (from `_buildRecordDismissible`, after the shared delete-confirmation dialog).
- **Notes:** No confirmation logic lives here — the `Dismissible` caller is responsible for
  confirming before this runs.

### `Future<void> _editRecord(IntimacyRecord record)` (in `_IntimacyPageState`) <a id="editrecord-main"></a>
- **Kind:** method of `_IntimacyPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 500)
- **Purpose:** Open the edit-record dialog for an existing record and persist the update.
- **Inputs:** `record` — the record being edited.
- **Returns:** `Future<void>`.
- **Side effects:** Shows `AddRecordDialog` pre-filled; on a non-null result, replaces the record
  in `_records` via `setState` and calls `_saveData()`.
- **Algorithm:** Same active-partner/active-toy computation as `_addRecord`, but the dialog is
  given the existing `record` to prefill; on return, finds the record by id and overwrites it.
- **Usage:**
  ```dart
  _editRecord(record);
  ```
  (from the record tile's tap handler / dismissible menu, in `_buildRecordDismissible`).
- **Notes:** Because the dialog's partner/toy pickers are built from the *active-only* lists,
  editing a record that references a since-deleted or broken-up partner/toy still displays and
  saves correctly only because the picker construction (in the sibling `_FilteredRecordsPageState`
  variant — see [`_dialogPartners`](#dialogpartners)/[`_dialogToys`](#dialogtoys)) explicitly
  includes the record's *current* reference even when inactive. This main-page `_editRecord` does
  not itself special-case a dangling id, but simply leaves whatever id was already stored — it
  never reassigns or clears it, per the deleted-partner tolerance policy described in
  [Intimacy § Deleted-partner handling](../../../../features/intimacy.md#deleted-partner-handling).

### `int _compareNullableDates(DateTime? a, DateTime? b)` (in `_PartnerManagementPageState`) <a id="comparenullabledates-partner"></a>
- **Kind:** method of `_PartnerManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 2609)
- **Purpose:** Compare two optional dates, treating `null` as sorting after any real date.
- **Inputs:** `a`, `b`.
- **Returns:** `int` — standard comparator contract.
- **Side effects:** None.
- **Algorithm:** Both null → `0`; only `a` null → `1` (a sorts after); only `b` null → `-1`;
  otherwise `a.compareTo(b)`.
- **Usage:**
  ```dart
  final byDate = _compareNullableDates(a.startDate, b.startDate);
  return byDate != 0 ? byDate : _compareText(a.name, b.name);
  ```
  (inside `_sortPartners`'s date-sort branch, with name as tiebreaker).
- **Notes:** Byte-for-byte duplicated in `_ToyManagementPageState` for purchase-date sorting — see
  [`_compareNullableDates` (toy)](#comparenullabledates-toy).

### `List<String> _normalizedOrder(String statusKey)` (in `_PartnerManagementPageState`) <a id="normalizedorder-partner"></a>
- **Kind:** method of `_PartnerManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 2629)
- **Purpose:** Reconcile the stored custom-order id list for a status group with the partners
  that currently exist in that group.
- **Inputs:** `statusKey` (`_statusActive` or `_statusInactive`).
- **Returns:** `List<String>` — every current partner id in that group, in a stable order.
- **Side effects:** None.
- **Algorithm:**
  1. Compute `allIds`: ids of partners whose active/inactive state matches `statusKey`.
  2. Walk the stored custom order (if any) and keep only ids that are (a) still in `allIds` and
     (b) not already seen — this drops stale ids (deleted partners, or partners that moved to the
     other status group) and de-duplicates.
  3. Append any remaining `allIds` not yet seen (newly added partners) at the end, in their
     natural list order.
- **Usage:**
  ```dart
  _customOrders[statusKey] = _normalizedOrder(statusKey);
  ```
  (called whenever custom order needs to be seeded or re-synced: switching into custom sort mode,
  appending a broken-up partner, etc.)
- **Notes:** This is what keeps a manually-dragged order from silently breaking when a partner is
  added, deleted, or moves between the active/inactive groups. Duplicated for toys — see
  [`_normalizedOrder` (toy)](#normalizedorder-toy).

### `List<Partner> _sortPartners(String statusKey, List<Partner> partners)` <a id="sortpartners"></a>
- **Kind:** method of `_PartnerManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 2652)
- **Purpose:** Sort a partner list according to the status group's current sort mode.
- **Inputs:** `statusKey`, `partners` (the list to sort — a copy is made, input isn't mutated).
- **Returns:** `List<Partner>`.
- **Side effects:** None (reads `_customOrders` but does not write it).
- **Algorithm:** `switch` on `_sortMode(statusKey)`:
  - `_sortDate`: by `startDate` (nulls last), tiebreak by name.
  - `_sortCount`: by `_partnerRecordCount` descending, tiebreak by name.
  - `_sortName`: by name only.
  - `_sortCustom`/default: by position in `_normalizedOrder(statusKey)`, unknown ids (index `-1`)
    pushed to `fallbackIndex` (the end), tiebreak by name.
- **Usage:**
  ```dart
  List<Partner> get _activePartners => _sortPartners(
    _statusActive,
    _partners.where((p) => p.endDate == null).toList(),
  );
  ```
- **Notes:** Every branch tiebreaks on case-insensitive name via `_compareText`, so ties never
  produce visually unstable ordering.

### `void _setSortMode(String statusKey, String mode)` (in `_PartnerManagementPageState`) <a id="setsortmode-partner"></a>
- **Kind:** method of `_PartnerManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 2690)
- **Purpose:** Switch a status group's active sort mode, seeding its custom order the first time
  custom sort is selected.
- **Inputs:** `statusKey`, `mode` (one of `_sortDate`/`_sortCount`/`_sortName`/`_sortCustom`).
- **Returns:** None.
- **Side effects:** `setState` updates `_sortModes[statusKey]` and possibly `_customOrders`/
  `_reordering`; calls `_notifySort()`.
- **Algorithm:**
  1. If switching *into* custom mode and no custom order exists yet for this group, seed one from
     the group's current visual order under its *previous* sort mode (so switching to custom sort
     doesn't visually reshuffle anything).
  2. Store the new mode.
  3. If the new mode is custom, also refresh via `_normalizedOrder` (covers reconciliation); else
     clear the `_reordering` flag for this group (custom-sort's drag-reorder UI only applies in
     custom mode).
  4. Notify the parent via `_notifySort()`.
- **Usage:**
  ```dart
  onSelected: (mode) => _setSortMode(statusKey, mode),
  ```
  (from the sort-mode popup menu built by `_managedSortItem`).
- **Notes:** Duplicated for toys — see [`_setSortMode` (toy)](#setsortmode-toy).

### `void _appendPartnerToCustomOrderIfNeeded(Partner partner)` <a id="appendpartnertocustomorderifneeded"></a>
- **Kind:** method of `_PartnerManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 2717)
- **Purpose:** Insert a partner into its status group's custom order, only if that group is
  actually using custom sort.
- **Inputs:** `partner` — used for its id and current active/inactive status.
- **Returns:** None.
- **Side effects:** Mutates `_customOrders[statusKey]` in place (no `setState`/notify — callers do
  that themselves as part of a larger operation).
- **Algorithm:** Compute `statusKey` from `partner.endDate`; if that group's sort mode isn't
  custom, do nothing; otherwise recompute via `_normalizedOrder` (which naturally includes the new
  partner since it's now part of `allIds`).
- **Usage:**
  ```dart
  _removePartnerFromCustomOrders(p.id);
  _appendPartnerToCustomOrderIfNeeded(
    _partners.firstWhere((x) => x.id == p.id),
  );
  ```
  (from `_breakUpPartner`, after moving a partner from active to inactive).
- **Notes:** The remove-then-append pattern is how a partner "moves" between the active and
  inactive custom-order lists when their status changes.

### `void _removePartnerFromCustomOrders(String partnerId)` <a id="removepartnerfromcustomorders"></a>
- **Kind:** method of `_PartnerManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 2728)
- **Purpose:** Remove a partner id from every stored custom order (both active and inactive
  groups).
- **Inputs:** `partnerId`.
- **Returns:** None.
- **Side effects:** Mutates every list in `_customOrders`.
- **Algorithm:** Loop over `_customOrders.entries` and call `.remove(partnerId)` on each value
  list.
- **Usage:** Called from `_deletePartner` and `_breakUpPartner` before re-adding the id to the
  correct group.
- **Notes:** Iterates both status groups unconditionally rather than looking up which one
  currently contains the id — cheap given the small list sizes involved.

### `void _reorderPartners(String statusKey, List<Partner> partners, int oldIndex, int newIndex)` <a id="reorderpartners"></a>
- **Kind:** method of `_PartnerManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 2739)
- **Purpose:** Apply a `ReorderableListView` drag gesture to a status group's custom order.
- **Inputs:** `statusKey`, `partners` (the currently-displayed, already-sorted list),
  `oldIndex`/`newIndex` as reported by the drag callback.
- **Returns:** None.
- **Side effects:** `setState` rewrites `_customOrders[statusKey]` and forces `_sortModes
  [statusKey] = _sortCustom`; calls `_notifySort()`.
- **Algorithm:**
  1. Adjust `newIndex` down by one if it's past `oldIndex`, per Flutter's `ReorderableListView`
     convention (the widget reports the target index *before* removal).
  2. Bounds-check both indices against the id list; silently return if out of range (defensive
     against stale drag callbacks).
  3. Remove the id at `oldIndex` and reinsert it at `newIndex`.
  4. Store the reordered id list and force the sort mode to custom (a drag always switches you
     into custom-sort mode, even if you were viewing another sort at the time).
- **Usage:**
  ```dart
  _reorderPartners(statusKey, partners, oldIndex, oldStyleNewIndex);
  ```
  (from the `ReorderableListView.builder`'s `onReorder` in `_buildPartnerReorderList`).
- **Notes:** Duplicated for toys — see `_reorderToys`.

### `void _deletePartner(Partner p)` <a id="deletepartner"></a>
- **Kind:** method of `_PartnerManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 2784)
- **Purpose:** Permanently delete a partner and their cycle records, while intentionally leaving
  historical activity records untouched.
- **Inputs:** `p` — the partner to delete.
- **Returns:** None.
- **Side effects:** `setState` removes `p` from `_partners` and removes every `CycleRecord` whose
  `personId == p.id`; cleans up custom-order entries; calls `widget.onChanged(_partners)`,
  `widget.onCycleRecordsChanged(_cycleRecords)`, and `_notifySort()`.
- **Algorithm:**
  1. Remove the partner from `_partners`.
  2. Remove that partner's cycle records too (so their `personId` doesn't dangle in a record type
     that has no tolerance for missing-person display).
  3. Clean up the partner id from all custom-order lists.
  4. Push both changed collections up to the parent via callbacks, then re-notify sort state.
- **Usage:**
  ```dart
  onDismissed: (_) => _deletePartner(p),
  ```
  (from the partner tile's `Dismissible`, in `_buildPartnerTile`, after the shared delete
  confirmation).
- **Notes:** Deliberately **asymmetric** with activity records: `IntimacyRecord.partnerId` is
  *not* cleaned up here, and record tiles/the edit dialog are built to tolerate a dangling id and
  render a blank partner label — see
  [Intimacy § Deleted-partner handling](../../../../features/intimacy.md#deleted-partner-handling).
  This mirrors the "don't destroy history for a transient UI convenience" principle used elsewhere
  in the app (e.g. Finance's forced-balance transactions).

### `void _breakUpPartner(Partner p)` <a id="breakuppartner"></a>
- **Kind:** method of `_PartnerManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 2801)
- **Purpose:** Mark a partner as separated without deleting them: sets an end date and disables
  their calendar cycle overlay.
- **Inputs:** `p` — the partner to break up with.
- **Returns:** None.
- **Side effects:** `setState` replaces `p` in `_partners` with a copy carrying `endDate = now` and
  `body.showCycleOnCalendar = false`; re-syncs custom-order membership; calls
  `widget.onChanged(_partners)` and `_notifySort()`.
- **Algorithm:**
  1. Capture `now`.
  2. Remove the old partner entry and re-add a reconstructed `Partner` with the same id/name/
     emoji/image/start date, `endDate: now`, and `body: p.body?.copyWith(showCycleOnCalendar:
     false)` — i.e. every field is preserved except the two that change.
  3. Remove the id from whichever custom order it was in, then re-append it (now that its status
     flipped from active to inactive, it needs to move into the inactive group's custom order if
     that group uses custom sort) via
     [`_appendPartnerToCustomOrderIfNeeded`](#appendpartnertocustomorderifneeded).
  4. Notify the parent and re-notify sort.
- **Usage:**
  ```dart
  _breakUpPartner(p);
  ```
  (from the partner tile's overflow menu, in `_buildPartnerTile`).
- **Notes:** Turning off `showCycleOnCalendar` here is what backs the "separation automatically
  stops showing this partner's cycle on the home-page calendar" behavior documented in
  [Intimacy § The Body layer](../../../../features/intimacy.md#the-body-layer-v124); the user can
  manually re-enable it afterward from the partner's Body tab.

### `int _compareNullableDates(DateTime? a, DateTime? b)` (in `_ToyManagementPageState`) <a id="comparenullabledates-toy"></a>
- **Kind:** method of `_ToyManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 3622)
- **Purpose:** Compare two optional dates, treating `null` as sorting after any real date.
- **Inputs:** `a`, `b`.
- **Returns:** `int`.
- **Side effects:** None.
- **Algorithm:** Identical to
  [`_compareNullableDates` (partner)](#comparenullabledates-partner): both null → 0; only `a` null
  → 1; only `b` null → -1; else `a.compareTo(b)`.
- **Usage:** Used by `_sortToys`'s date-sort branch on `purchaseDate`.
- **Notes:** None beyond the cross-reference above.

### `double _totalToyCost(List<Toy> toys)` (in `_ToyManagementPageState`) <a id="totaltoycost"></a>
- **Kind:** method of `_ToyManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 3649)
- **Purpose:** Sum the total recorded cost across a toy list.
- **Inputs:** `toys`.
- **Returns:** `double` — `0.0` if none have a price.
- **Side effects:** None.
- **Algorithm:** `toys.fold(0.0, (sum, toy) => sum + toy.totalCost())` — toys without a price
  contribute `0` via `Toy.totalCost()`'s own null handling.
- **Usage:**
  ```dart
  _formatMoney(_totalToyCost(activeToys)),
  ```
  (in `_buildActiveCostSummary`).
- **Notes:** Same computation reimplemented under a different name (`_totalCost`) in
  `_ToyCostOverviewPageState` — see [`_totalCost`](#totalcost).

### `double? _totalDailyToyCost(List<Toy> toys)` <a id="totaldailytoycost"></a>
- **Kind:** method of `_ToyManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 3657)
- **Purpose:** Sum average daily costs across a toy list, when at least one toy has enough data to
  compute one.
- **Inputs:** `toys`.
- **Returns:** `double?` — `null` if no toy in the list has both a price and a purchase date.
- **Side effects:** None.
- **Algorithm:** Loop, skip toys where `toy.averageDailyCost()` is null, accumulate the rest, and
  track whether *any* toy contributed via a `hasDailyCost` flag; return `null` rather than `0` if
  the flag never flipped (distinguishing "no costable toys" from "toys cost nothing").
- **Usage:**
  ```dart
  final dailyCost = _totalDailyToyCost(activeToys);
  ```
  (in `_buildActiveCostSummary`).
- **Notes:** Reimplemented under a different name (`_totalDailyCost`) in
  `_ToyCostOverviewPageState` — see [`_totalDailyCost`](#totaldailycost).

### `List<String> _normalizedOrder(String statusKey)` (in `_ToyManagementPageState`) <a id="normalizedorder-toy"></a>
- **Kind:** method of `_ToyManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 3674)
- **Purpose:** Reconcile the stored custom-order id list for a status group with the toys that
  currently exist in that group.
- **Inputs:** `statusKey` (`_statusActive` or `_statusInactive`, the latter meaning "retired" in
  this class).
- **Returns:** `List<String>`.
- **Side effects:** None.
- **Algorithm:** Identical shape to
  [`_normalizedOrder` (partner)](#normalizedorder-partner): filter `allIds` by retired-status
  match, keep only still-valid/unseen ids from the stored order, then append newly-added toy ids.
- **Usage:** Same pattern as the partner version, e.g. seeding custom order on `_setSortMode`.
- **Notes:** None beyond the cross-reference above.

### `List<Toy> _sortToys(String statusKey, List<Toy> toys)` <a id="sorttoys"></a>
- **Kind:** method of `_ToyManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 3697)
- **Purpose:** Sort a toy list according to the status group's current sort mode.
- **Inputs:** `statusKey`, `toys`.
- **Returns:** `List<Toy>`.
- **Side effects:** None.
- **Algorithm:** Same shape as [`_sortPartners`](#sortpartners): `_sortDate` by `purchaseDate`
  (nulls last); `_sortCount` by `_toyRecordCount` descending; `_sortName` by name; `_sortCustom`/
  default by position in `_normalizedOrder`. All branches tiebreak on name.
- **Usage:**
  ```dart
  List<Toy> get _activeToys => _sortToys(
    _statusActive,
    _toys.where((t) => t.retiredDate == null).toList(),
  );
  ```
- **Notes:** None beyond the cross-reference to `_sortPartners`.

### `void _setSortMode(String statusKey, String mode)` (in `_ToyManagementPageState`) <a id="setsortmode-toy"></a>
- **Kind:** method of `_ToyManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 3733)
- **Purpose:** Switch a status group's active sort mode, seeding its custom order on first use.
- **Inputs:** `statusKey`, `mode`.
- **Returns:** None.
- **Side effects:** `setState` updates `_sortModes`/`_customOrders`/`_reordering`; calls
  `_notifySort()`.
- **Algorithm:** Identical to
  [`_setSortMode` (partner)](#setsortmode-partner), operating on `_toys`/retired-status instead of
  `_partners`/end-date.
- **Usage:**
  ```dart
  onSelected: (mode) => _setSortMode(statusKey, mode),
  ```
- **Notes:** None beyond the cross-reference above.

### `void _appendToyToCustomOrderIfNeeded(Toy toy)` <a id="appendtoytocustomorderifneeded"></a>
- **Kind:** method of `_ToyManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 3760)
- **Purpose:** Insert a toy into its status group's custom order, only if that group uses custom
  sort.
- **Inputs:** `toy`.
- **Returns:** None.
- **Side effects:** Mutates `_customOrders[statusKey]` in place.
- **Algorithm:** Identical to
  [`_appendPartnerToCustomOrderIfNeeded`](#appendpartnertocustomorderifneeded), keyed by retired
  status instead of end-date.
- **Usage:**
  ```dart
  _appendToyToCustomOrderIfNeeded(_toys.firstWhere((x) => x.id == t.id));
  ```
  (from `_retireToy`).
- **Notes:** None beyond the cross-reference above.

### `void _removeToyFromCustomOrders(String toyId)` <a id="removetoyfromcustomorders"></a>
- **Kind:** method of `_ToyManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 3771)
- **Purpose:** Remove a toy id from every stored custom order.
- **Inputs:** `toyId`.
- **Returns:** None.
- **Side effects:** Mutates every list in `_customOrders`.
- **Algorithm:** Identical to
  [`_removePartnerFromCustomOrders`](#removepartnerfromcustomorders): loop and `.remove(toyId)`
  from every value list.
- **Usage:** Called from `_deleteToy` and `_retireToy`.
- **Notes:** None beyond the cross-reference above.

### `void _reorderToys(String statusKey, List<Toy> toys, int oldIndex, int newIndex)` <a id="reordertoys"></a>
- **Kind:** method of `_ToyManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 3782)
- **Purpose:** Apply a drag-reorder gesture to a status group's custom toy order.
- **Inputs:** `statusKey`, `toys`, `oldIndex`, `newIndex`.
- **Returns:** None.
- **Side effects:** `setState` rewrites `_customOrders[statusKey]`, forces `_sortModes[statusKey] =
  _sortCustom`; calls `_notifySort()`.
- **Algorithm:** Identical to [`_reorderPartners`](#reorderpartners): adjust `newIndex`,
  bounds-check, remove-and-reinsert the id, force custom sort mode.
- **Usage:**
  ```dart
  _reorderToys(statusKey, toys, oldIndex, oldStyleNewIndex);
  ```
- **Notes:** None beyond the cross-reference above.

### `void _deleteToy(Toy t)` <a id="deletetoy"></a>
- **Kind:** method of `_ToyManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 3825)
- **Purpose:** Permanently delete a toy.
- **Inputs:** `t`.
- **Returns:** None.
- **Side effects:** `setState` removes `t` from `_toys`; cleans up custom-order entries; calls
  `widget.onChanged(_toys)` and `_notifySort()`.
- **Algorithm:** Single `removeWhere` inside `setState`, then
  [`_removeToyFromCustomOrders`](#removetoyfromcustomorders), notify parent, re-notify sort.
- **Usage:**
  ```dart
  onDismissed: (_) => _deleteToy(t),
  ```
  (from `_buildToyTile`'s `Dismissible`).
- **Notes:** Unlike `_deletePartner`, there is no secondary collection to clean (toys don't have
  cycle records); `IntimacyRecord.toyIds` referencing this toy are left as-is, same
  deleted-reference tolerance philosophy as partners.

### `void _retireToy(Toy t)` <a id="retiretoy"></a>
- **Kind:** method of `_ToyManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 3837)
- **Purpose:** Mark a toy retired without deleting it.
- **Inputs:** `t`.
- **Returns:** None.
- **Side effects:** `setState` replaces `t` with a copy carrying `retiredDate = now`; re-syncs
  custom-order membership; calls `widget.onChanged(_toys)` and `_notifySort()`.
- **Algorithm:**
  1. Remove the old `t` and re-add a reconstructed `Toy` with the same id/name/emoji/image/
     purchase date/purchase link/price, plus `retiredDate: now`.
  2. Move its custom-order membership from active to retired via
     [`_removeToyFromCustomOrders`](#removetoyfromcustomorders) then
     [`_appendToyToCustomOrderIfNeeded`](#appendtoytocustomorderifneeded).
  3. Notify the parent and re-notify sort.
- **Usage:**
  ```dart
  _retireToy(t);
  ```
  (from `_buildToyTile`'s overflow menu).
- **Notes:** This is the mechanism behind "toy retirement state" in
  [Intimacy § UI](../../../../features/intimacy.md#ui) — a retired toy's cost is thereafter
  treated as **finalized** by the cost-overview charts (see
  [`_toyDailyCostAt`](#toydailycostat)'s all-scope branch).

### `void _importDefaults()` <a id="importdefaults"></a>
- **Kind:** method of `_PositionManagementPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 4746)
- **Purpose:** Add the app's built-in default position presets, skipping any already present by
  name.
- **Inputs:** None (uses localized preset names/emoji from `l10n`).
- **Returns:** None.
- **Side effects:** Appends to `_positions`; `setState` + `widget.onChanged(_positions)` only if at
  least one preset was actually added.
- **Algorithm:**
  1. Build a fixed list of 9 default presets (missionary, cowgirl, doggy style, reverse cowgirl,
     spooning, standing, 69, lotus, prone bone), each a localized name + emoji.
  2. Build `existingNames`, a lowercase set of the user's current position names.
  3. For each preset whose lowercase name isn't already in `existingNames`, append a new
     `Position(name:, emoji:)` and increment an `added` counter.
  4. Only call `setState({})` and `widget.onChanged(_positions)` if `added > 0` — importing when
     everything already exists is a no-op with no rebuild/notify.
- **Usage:**
  ```dart
  if (v == 'import') _importDefaults();
  ```
  (from the position management page's overflow menu).
- **Notes:** Deduplication is purely by case-insensitive name match — a user-renamed default
  position (e.g. renaming "Missionary" to something else) would cause it to be re-imported under
  its original name on the next import.

### `List<IntimacyRecord> get _filteredRecords` (in `_FilteredRecordsPageState`) <a id="filteredrecords-filtered"></a>
- **Kind:** getter of `_FilteredRecordsPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 5099)
- **Purpose:** Return this detail page's records — those referencing the scoped partner or toy —
  newest first.
- **Inputs:** None (reads `_records`, `widget.partnerId`, `widget.toyId`).
- **Returns:** `List<IntimacyRecord>`.
- **Side effects:** None.
- **Algorithm:** Filter by `partnerId` match if the page is partner-scoped, else by `toyIds`
  containment if toy-scoped, else pass everything through; then sort descending by `datetime`.
- **Usage:**
  ```dart
  final records = _filteredRecords;
  ```
  (in `_buildRecordsListView`).
- **Notes:** Unlike the home page's [`_filteredRecords`](#filteredrecords-main), this has no
  date/type/sort-mode filtering — it exists purely to scope the shared record list to one
  partner or toy, always newest-first, "matching account transaction details" per its source
  comment.

### `List<Partner> _dialogPartners({String? includePartnerId})` <a id="dialogpartners"></a>
- **Kind:** method of `_FilteredRecordsPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 5125)
- **Purpose:** Build the partner picker list offered by the add/edit record dialog on this
  detail page.
- **Inputs:** `includePartnerId` — an id (typically the record being edited) that must appear
  even if inactive.
- **Returns:** `List<Partner>`.
- **Side effects:** None.
- **Algorithm:**
  1. Build `includeIds` from `widget.partnerId` (this page's own scope, if partner-scoped) and the
     optional `includePartnerId` parameter.
  2. Walk `widget.partners`, keeping a partner if it's active (`endDate == null`) **or** its id is
     in `includeIds`, de-duplicating via a `seen` set.
- **Usage:**
  ```dart
  partners: _dialogPartners(includePartnerId: widget.partnerId),
  // and, when editing:
  partners: _dialogPartners(includePartnerId: record.partnerId),
  ```
- **Notes:** This is the mechanism that lets a detail page for an *inactive* (broken-up) partner
  still let the user add/edit records against that partner — the picker always includes the page's
  own scoped id even though it's excluded from the "active" pool otherwise. Directly implements
  the "position/toy/partner picker" tolerance called out in
  [Intimacy § Deleted-partner handling](../../../../features/intimacy.md#deleted-partner-handling).

### `List<Toy> _dialogToys({Iterable<String> includeToyIds = const []})` <a id="dialogtoys"></a>
- **Kind:** method of `_FilteredRecordsPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 5141)
- **Purpose:** Build the toy picker list offered by the add/edit record dialog on this detail
  page.
- **Inputs:** `includeToyIds` — ids (typically from the record being edited) that must appear even
  if retired.
- **Returns:** `List<Toy>`.
- **Side effects:** None.
- **Algorithm:** Mirrors [`_dialogPartners`](#dialogpartners): include a toy if active (no
  `retiredDate`) or its id is in the combined `widget.toyId` + `includeToyIds` set, de-duplicated.
- **Usage:**
  ```dart
  toys: _dialogToys(includeToyIds: widget.toyId != null ? [widget.toyId!] : const []),
  // and, when editing:
  toys: _dialogToys(includeToyIds: record.toyIds),
  ```
- **Notes:** Same retired-toy tolerance rationale as `_dialogPartners`.

### `Future<void> _addRecord()` (in `_FilteredRecordsPageState`) <a id="addrecord-filtered"></a>
- **Kind:** method of `_FilteredRecordsPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 5164)
- **Purpose:** Open the add-record dialog from a partner/toy detail page, preselecting the current
  scope.
- **Inputs:** None.
- **Returns:** `Future<void>`.
- **Side effects:** Shows `AddRecordDialog`; on success, inserts at the front of `_records` via
  `setState` and calls `_notifyRecordsChanged()`.
- **Algorithm:**
  1. Show the dialog with pickers from `_dialogPartners`/`_dialogToys` (scoped-inclusive) and
     `initialPartnerId`/`initialToyIds` preselected to this page's scope.
  2. On a non-null result, `_records.insert(0, record)` (new record goes to the top, matching the
     newest-first display order) and notify the parent.
- **Usage:** Wired to this detail page's add button in `build()`/`_buildRecordsListView`.
- **Notes:** Unlike the home page's `_addRecord`, this operates on a page-local `_records` copy and
  pushes changes up via `onRecordsChanged` rather than calling storage directly — the actual
  persistence happens in the parent `_IntimacyPageState` once notified.

### `Future<void> _editRecord(IntimacyRecord record)` (in `_FilteredRecordsPageState`) <a id="editrecord-filtered"></a>
- **Kind:** method of `_FilteredRecordsPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 5187)
- **Purpose:** Open the edit-record dialog for one record from a detail page and update local
  state.
- **Inputs:** `record`.
- **Returns:** `Future<void>`.
- **Side effects:** Shows `AddRecordDialog` prefilled; on success, replaces the record in
  `_records` by id via `setState`; calls `_notifyRecordsChanged()`.
- **Algorithm:** Show the dialog with `record:` set and scope-inclusive pickers; on a non-null
  result, find the index by id and overwrite it in place (a no-op if the id somehow isn't found).
- **Usage:**
  ```dart
  _editRecord(record);
  ```
  (from `_buildRecordDismissible`'s tap/menu handler).
- **Notes:** If the edit changes the record's partner/toy away from this page's scope, the record
  simply disappears from `_filteredRecords` on the next rebuild — there's no special-case
  handling, it falls straight out of the filter.

### `void _deleteRecord(IntimacyRecord record)` (in `_FilteredRecordsPageState`) <a id="deleterecord-filtered"></a>
- **Kind:** method of `_FilteredRecordsPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 5210)
- **Purpose:** Remove a record from local state and notify the parent.
- **Inputs:** `record`.
- **Returns:** None.
- **Side effects:** `setState` removes the matching record from `_records`; calls
  `_notifyRecordsChanged()`.
- **Algorithm:** Single `removeWhere` by id, then notify.
- **Usage:**
  ```dart
  onDismissed: (_) => _deleteRecord(record),
  ```
- **Notes:** As with `_editRecord`/`_deleteRecord` on the home page, the `Dismissible` caller
  handles delete confirmation before this runs.

### `String _formatDuration(Duration duration)` <a id="formatduration"></a>
- **Kind:** method of `_FilteredRecordsPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 5220)
- **Purpose:** Format a duration for the detail page's summary metrics.
- **Inputs:** `duration`.
- **Returns:** `String` — `"Xh Ym"` if at least one hour, else `"Ym"`.
- **Side effects:** None.
- **Algorithm:** `hours = duration.inHours`; `minutes = duration.inMinutes.remainder(60)`; if
  `hours > 0` return `"${hours}h ${minutes}m"`, else return `"${duration.inMinutes}m"` (avoids a
  redundant "0h" prefix for short records).
- **Usage:** Called from `_buildSummaryCard` to format the average-duration metric.
- **Notes:** None.

### `_ToyCostTrendData _buildTrendData(List<DateTime> dates, DateTime today, List<Toy> toys)` <a id="buildtrenddata"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6072)
- **Purpose:** Compute the history/future daily-cost spot lists and y-axis bounds plotted on the
  aggregate cost trend chart.
- **Inputs:** `dates` (the sampled timeline from [`_timeline`](#timeline)), `today`, `toys` (the
  currently in-scope toys).
- **Returns:** `_ToyCostTrendData` (history spots, future spots, `minY`, `maxY`).
- **Side effects:** None.
- **Algorithm:**
  1. For each sampled date, compute `_dailyCostAt(date, toys)`; skip dates with no value.
  2. Add each valid value to a running `values` list (for bounds) and to `historySpots` if the
     date is `<= today`, and/or to `futureSpots` if the date is `>= today` — **today's spot is
     included in both lines** so they visually connect.
  3. If no values were computed at all, return a zeroed `_ToyCostTrendData`.
  4. Otherwise set `minY`/`maxY` from `values.reduce(math.min)`/`reduce(math.max)`.
- **Usage:**
  ```dart
  final trendData = _buildTrendData(dates, today, toys);
  ```
  (in `_buildTrendCard`, feeding `_buildCostChart`).
- **Notes:** None beyond the today-included-in-both-lines behavior above.

### `double? _dailyCostAt(DateTime date, List<Toy> toys)` <a id="dailycostat"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6112)
- **Purpose:** Compute the aggregate average daily cost across a toy list on one date.
- **Inputs:** `date`, `toys`.
- **Returns:** `double?` — `null` until at least one included toy can be costed on that date.
- **Side effects:** None.
- **Algorithm:** Sum [`_toyDailyCostAt`](#toydailycostat) across `toys`, skipping nulls, tracking a
  `hasValue` flag the same way as [`_totalDailyToyCost`](#totaldailytoycost)/
  [`_totalDailyCost`](#totaldailycost).
- **Usage:**
  ```dart
  final value = _dailyCostAt(date, toys);
  ```
  (inside `_buildTrendData`'s per-date loop).
- **Notes:** None.

### `double? _toyDailyCostAt(Toy toy, DateTime date)` <a id="toydailycostat"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6129)
- **Purpose:** Compute one toy's average daily cost as of a specific date, accounting for
  retirement.
- **Inputs:** `toy`, `date`.
- **Returns:** `double?` — `null` if the toy has no cost data, no purchase date, or the date
  precedes its purchase.
- **Side effects:** None.
- **Algorithm:**
  1. Return `null` immediately if `!toy.hasCostData || purchaseDate == null`, or if `date` is
     before the (date-only) purchase date.
  2. **All-scope shortcut:** if the current scope is `all` and the toy is retired, return the
     toy's already-finalized `averageDailyCost()` directly (a retired toy's daily cost is fixed at
     its retirement point, not recomputed as if service continued).
  3. Otherwise compute `serviceEnd`: normally `date`, but clamped to the toy's retirement date if
     retired and that's earlier than `date`.
  4. If `serviceEnd` precedes `purchaseDate` (can happen if retired same-day or edge cases), return
     `null`.
  5. Otherwise `totalCost() / max(1, days in service)`, i.e. cost amortized over days owned up to
     `serviceEnd`.
- **Usage:**
  ```dart
  final value = _toyDailyCostAt(toy, date);
  ```
  (inside `_dailyCostAt`'s per-toy loop).
- **Notes:** Step 2's shortcut is what makes retired-toy costs read as "finalized" in the all-scope
  trend — see [Intimacy § UI](../../../../features/intimacy.md#ui) ("finalized retired-toy
  costs").

### `DateTime _historyStart(DateTime today, List<Toy> toys)` <a id="historystart"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6151)
- **Purpose:** Return the first date shown on the cost trend chart for the selected range.
- **Inputs:** `today`, `toys`.
- **Returns:** `DateTime`.
- **Side effects:** None.
- **Algorithm:** Same range-to-cutoff `switch` as
  [`IntimacyChartRange.cutoffFrom`](../widgets/intimacy_trend_chart.md#cutofffrom) (one
  week/month/3mo/6mo/year back from `today`), except the `all` case resolves to
  [`_earliestPurchaseDate`](#earliestpurchasedate) (falling back to one year back if no toy has a
  purchase date); finally clamps the result so it never lands after `today`.
- **Usage:**
  ```dart
  final historyStart = _historyStart(today, toys);
  ```
  (in `_buildTrendCard`).
- **Notes:** Comment in source notes this "mirrors MyDevice" — the same range-selection pattern is
  used for cost/battery-style trend charts in the MyDevice app.

### `DateTime _futureEnd(DateTime today, DateTime historyStart, List<Toy> toys)` <a id="futureend"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6186)
- **Purpose:** Return the projected end date for the future/projection half of the cost trend
  chart.
- **Inputs:** `today`, `historyStart`, `toys`.
- **Returns:** `DateTime`.
- **Side effects:** None.
- **Algorithm:**
  1. Project forward from `today` by `max(days since historyStart, 30)` — the projection window is
     at least as long as the history window (or 30 days, whichever is larger).
  2. If any toy's purchase date (not yet reached) would fall after that projected end, extend
     `futureEnd` to 30 days past that toy's purchase date instead, so a future-dated toy purchase
     is never clipped off the chart.
- **Usage:**
  ```dart
  final futureEnd = _futureEnd(today, historyStart, toys);
  ```
- **Notes:** None beyond the future-purchase accommodation above.

### `DateTime? _earliestPurchaseDate(List<Toy> toys)` <a id="earliestpurchasedate"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6205)
- **Purpose:** Return the earliest purchase date among a toy list.
- **Inputs:** `toys`.
- **Returns:** `DateTime?` — `null` if no toy has a purchase date.
- **Side effects:** None.
- **Algorithm:** Linear scan tracking the minimum date-only purchase date seen so far.
- **Usage:** Used by `_historyStart`'s `all`-range branch to anchor the chart at the oldest toy
  purchase.
- **Notes:** None.

### `List<DateTime> _timeline(DateTime historyStart, DateTime today, DateTime futureEnd, List<Toy> toys)` <a id="timeline"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6221)
- **Purpose:** Build the sampled, deduplicated date list plotted along the cost trend chart's
  x-axis.
- **Inputs:** `historyStart`, `today`, `futureEnd`, `toys`.
- **Returns:** `List<DateTime>` — sorted ascending, no consecutive duplicates.
- **Side effects:** None.
- **Algorithm:**
  1. Choose a sampling `step` based on total span: daily if `<= 240` days, weekly if `<= 1800`
     days, else monthly — keeping the sample count bounded for very long ranges.
  2. Generate evenly-stepped dates from `historyStart` to `futureEnd` inclusive.
  3. Always add `today` and `futureEnd` explicitly (so the projection boundary and "now" marker are
     always present as exact points, not just approximated by the step grid).
  4. Add every toy's purchase and retirement date (so cost discontinuities are always sampled
     exactly rather than only approximately by the step grid).
  5. Sort everything, then de-duplicate consecutive equal dates.
- **Usage:**
  ```dart
  final dates = _timeline(historyStart, today, futureEnd, toys);
  ```
- **Notes:** Explicitly sampling purchase/retirement/today/end dates (step 3-4) is what keeps sharp
  cost jumps (a new toy purchased, an old one retiring) crisp on the chart even at monthly
  sampling resolution.

### `DateTime _dateOnly(DateTime date)` <a id="dateonly"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6261)
- **Purpose:** Strip the time-of-day component from a `DateTime` so day-based cost math is stable
  regardless of the original timestamp's time component.
- **Inputs:** `date`.
- **Returns:** `DateTime` — `DateTime(date.year, date.month, date.day)`.
- **Side effects:** None.
- **Algorithm:** Single constructor call dropping hour/minute/second/millisecond.
- **Usage:** Used throughout this class — `_toyDailyCostAt`, `_earliestPurchaseDate`, `_timeline`
  — anywhere a date needs to be compared or bucketed by calendar day rather than exact instant.
- **Notes:** Grouped here as Tier A because it's the load-bearing primitive behind every date
  comparison in the cost-trend algorithm group above, even though the implementation itself is a
  one-liner.

### `({double minY, double maxY}) _chartBounds(double minY, double maxY)` <a id="chartbounds"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6269)
- **Purpose:** Pad a raw min/max y-range so flat or all-zero cost charts still render with visible
  vertical space.
- **Inputs:** `minY`, `maxY`.
- **Returns:** A Dart record `({double minY, double maxY})`.
- **Side effects:** None.
- **Algorithm:**
  1. If `minY == maxY` (flat data), pad by 10% of `minY`'s magnitude, falling back to a fixed `1.0`
     pad if that would itself be zero (all-zero data).
  2. Otherwise pad by 10% of the range on both ends.
  3. Either way, clamp the lower bound to never exceed `0` (`math.min(0, minY - padding)`) so a
     positive-only cost series still shows a zero baseline.
- **Usage:** Called before transforming bounds for the log-scale chart in `_buildCostChart`.
- **Notes:** None.

### `double _logTransform(double value)` <a id="logtransform"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6285)
- **Purpose:** Map a cost value onto a signed log10 scale for charting, so a few high early-cost
  points don't visually flatten later small values.
- **Inputs:** `value`.
- **Returns:** `double`.
- **Side effects:** None.
- **Algorithm:** `0` maps to `0`; otherwise `sign(value) * log10(|value| + 1)` — the `+1` keeps the
  transform defined and continuous through zero (avoids `log(0)`).
- **Usage:**
  ```dart
  final transformedMinY = _logTransform(bounds.minY);
  FlSpot(spot.x, _logTransform(spot.y)),
  ```
  (in `_buildCostChart`, applied to both axis bounds and every plotted spot).
- **Notes:** Signed variant of a log1p transform — supports negative values (shouldn't occur for
  costs, but the transform doesn't assume non-negativity).

### `double _logInverse(double value)` <a id="loginverse"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6296)
- **Purpose:** Invert `_logTransform`, converting a log-scale chart coordinate back to a real cost
  value.
- **Inputs:** `value`.
- **Returns:** `double`.
- **Side effects:** None.
- **Algorithm:** `0` maps to `0`; otherwise `sign(value) * (10^|value| - 1)` — the exact inverse of
  `sign * log10(|value| + 1)`.
- **Usage:**
  ```dart
  _axisText(_logInverse(value)),
  '${item.label}: ${_moneyText(_logInverse(spot.y))}',
  ```
  (axis labels and tooltips in `_buildCostChart`).
- **Notes:** Must be kept in exact algebraic sync with `_logTransform` — the source comment flags
  this explicitly ("Mirrors `_logTransform`").

### `double _dateInterval(double minX, double maxX)` <a id="dateinterval"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6307)
- **Purpose:** Return a bottom-axis date-label interval (milliseconds) scaled to the visible
  x-range, so labels never crowd together.
- **Inputs:** `minX`, `maxX` (chart x-coordinates, i.e. epoch milliseconds).
- **Returns:** `double` milliseconds.
- **Side effects:** None.
- **Algorithm:** Convert the span to days, then step through ascending day-count thresholds (`<=7`
  → 2-day labels, `<=30` → weekly, `<=90` → 21-day, `<=180` → 45-day, `<=365` → 90-day, `<=730` →
  180-day, else yearly).
- **Usage:** Passed as the chart's bottom-axis `interval` in `_buildCostChart`.
- **Notes:** Same broad-thresholds design intent as
  [`IntimacyTrendChart._dateInterval`](../widgets/intimacy_trend_chart.md#dateinterval), but
  expressed in day-count thresholds rather than a millisecond-span formula.

### `String _dateLabel(DateTime date, double minX, double maxX, String localeName)` <a id="datelabel"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6324)
- **Purpose:** Format a chart date-axis label, choosing precision based on how wide the visible
  range is.
- **Inputs:** `date`, `minX`, `maxX`, `localeName`.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** Compute `spanDays`; use a `yyyy`-only format if `> 730` days, `M/yy` if `> 365`
  days, else `M/d` — all formatted via locale-aware `intl` `DateFormat`.
- **Usage:**
  ```dart
  _dateLabel(date, minX, maxX, l10n.localeName),
  ```
  (bottom-axis tick labels in `_buildCostChart`).
- **Notes:** None.

### `String _axisText(double value)` <a id="axistext"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6351)
- **Purpose:** Format a y-axis cost value compactly so large numbers still fit on a narrow left
  axis.
- **Inputs:** `value`.
- **Returns:** `String` — `"1.2m"` style for millions, `"3.4k"` for thousands, plain integer
  otherwise; preserves a leading `-` for negative values.
- **Side effects:** None.
- **Algorithm:** Branch on `abs(value)` thresholds (`>= 1_000_000` → divide by 1e6 and suffix `m`;
  `>= 1_000` → divide by 1e3 and suffix `k`; else plain `toStringAsFixed(0)`).
- **Usage:**
  ```dart
  _axisText(_logInverse(value)),
  ```
  (left-axis tick labels in `_buildCostChart`, applied after undoing the log transform).
- **Notes:** None.

### `double _totalCost(List<Toy> toys)` <a id="totalcost"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6364)
- **Purpose:** Sum the total recorded cost across a toy list.
- **Inputs:** `toys`.
- **Returns:** `double`.
- **Side effects:** None.
- **Algorithm:** Identical fold-based sum as [`_totalToyCost`](#totaltoycost).
- **Usage:**
  ```dart
  _moneyText(_totalCost(toys)),
  ```
  (in `_buildSummaryCard` for the cost overview page).
- **Notes:** Same computation as `_totalToyCost` under a different name in a different class —
  no functional difference.

### `double? _totalDailyCost(List<Toy> toys)` <a id="totaldailycost"></a>
- **Kind:** method of `_ToyCostOverviewPageState`
- **Source:** `lib/features/intimacy/views/intimacy_page.dart` (line 6372)
- **Purpose:** Sum average daily costs across a toy list, when computable.
- **Inputs:** `toys`.
- **Returns:** `double?` — `null` if no toy has both a price and a purchase date.
- **Side effects:** None.
- **Algorithm:** Identical to [`_totalDailyToyCost`](#totaldailytoycost): accumulate
  `toy.averageDailyCost()` where non-null, tracked via a `hasDailyCost` flag so an all-null result
  returns `null` rather than `0`.
- **Usage:**
  ```dart
  final dailyCost = _totalDailyCost(toys);
  ```
  (in `_buildSummaryCard` for the cost overview page).
- **Notes:** None beyond the cross-reference above.

# lib/features/todo/views/todo_page.dart

主 Todo 屏和其辅助的全月日历页。`TodoPage`/`_TodoPageState` 渲染每日/日常/工作任务小节、内联周历、列表底部每日评分编辑器，并拥有所有任务/评分修改和持久化（经 `TodoStorage`）。嵌套在同一文件中，`_TodoCalendarPage`/`_TodoCalendarPageState` 是被压入路由、显示带年/月跳转控件的全月网格、月度评分趋势图（经 `fl_chart`）和从评分日志派生的愉悦/煎熬日列表的页面；它把选中的日期返回给父页面，自己没有任何数据。模型/存储概念（`Task`、`DailyCompletionLog`、`DailyScoreLog`、排序模式/自定义顺序）见 [Todo](../../../../features/todo.md)，底层日志如何跨设备合并见 [三方合并](../../../../algorithms/three-way-merge.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `TodoPage({super.key})` | 构造函数（`TodoPage`） | B | 创建 todo 页实例。 |
| `createState` | 方法（`TodoPage`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_TodoPageState`） | B | 启动 `_loadData` 并注册自动同步监听器。 |
| `dispose` | 方法（`_TodoPageState`） | B | 注销自动同步监听器。 |
| [`_loadData`](#loaddata) | 方法（`_TodoPageState`） | A | 把 todo 数据从存储加载进状态，或浮出读取错误。 |
| [`_saveData`](#savedata) | 方法（`_TodoPageState`） | A | 把当前内存 todo 状态持久化到存储。 |
| `_syncReminders` | 方法（`_TodoPageState`） | B | 把当前任务/日志/提醒时间推给 `ReminderService`。 |
| `_showDailyReminderSettings` | 方法（`_TodoPageState`） | B | 显示早间/完成提醒时间选择器底部面板。 |
| `_isSameDay` | 方法（`_TodoPageState`） | B | 忽略日内时间比较两个日期。 |
| `_isToday` | getter（`_TodoPageState`） | B | 所选日期是否今天。 |
| [`_selectedWeekStart`](#selectedweekstart) | 方法（`_TodoPageState`） | A | 返回所选日期周的配置第一天。 |
| [`_selectedWeekDates`](#selectedweekdates) | 方法（`_TodoPageState`） | A | 返回内联周历显示的七天。 |
| [`_dailyForDate`](#dailyfordate) | getter（`_TodoPageState`） | A | 返回所选日期可见的每日模板，叠加逐日期完成状态。 |
| `_dateOnly` | 方法（`_TodoPageState`） | B | 从 `DateTime` 剥离日内时间。 |
| `_taskTypeKey` | 方法（`_TodoPageState`） | B | 把 `TaskType` 映射到其设置映射键字符串。 |
| `_taskSortMode` | 方法（`_TodoPageState`） | B | 查找任务类型配置的排序模式。 |
| `_touchSettings` | 方法（`_TodoPageState`） | B | 用当前 UTC 时间盖章 `_settingsModifiedAt`。 |
| `_tasksForType` | 方法（`_TodoPageState`） | B | 返回给定类型的所有任务（模板或一次性）。 |
| `_compareText` | 方法（`_TodoPageState`） | B | 不区分大小写字符串比较器。 |
| [`_compareNullableDates`](#comparenullabledates) | 方法（`_TodoPageState`） | A | 可空日期比较器，null 排最后。 |
| [`_compareTaskFallback`](#comparetaskfallback) | 方法（`_TodoPageState`） | A | 确定性打破平局比较器：创建日期，然后标题。 |
| `_taskDueSortDate` | 方法（`_TodoPageState`） | B | 为截止排序挑选最佳可用日期。 |
| [`_normalizedTaskOrder`](#normalizedtaskorder) | 方法（`_TodoPageState`） | A | 调和保存的自定义顺序与任务类型当前活 ID 集合。 |
| [`_sortTasksForMode`](#sorttasksformode) | 方法（`_TodoPageState`） | A | 按排序模式（截止/名称/自定义/创建）排序任务列表。 |
| `_sortTasks` | 方法（`_TodoPageState`） | B | 用类型当前配置模式排序任务列表。 |
| [`_appendTaskToCustomOrderIfNeeded`](#appendtasktocustomorderifneeded) | 方法（`_TodoPageState`） | A | 自定义排序活动时把新创建任务 ID 加进其类型自定义顺序。 |
| [`_removeTaskFromCustomOrders`](#removetaskfromcustomorders) | 方法（`_TodoPageState`） | A | 从每个类型的自定义顺序列表移除已删除任务 ID。 |
| [`_onTaskSortModeChanged`](#ontasksortmodechanged) | 方法（`_TodoPageState`） | A | 处理用户切换小节排序模式，需要时播种自定义顺序。 |
| [`_onTaskReorder`](#ontaskreorder) | 方法（`_TodoPageState`） | A | 把可见列表的拖放重排应用回完整自定义顺序。 |
| [`_oneTimeVisibleOnDate`](#onetimevisibleondate) | 方法（`_TodoPageState`） | A | 决定一次性任务是否应显示在所选日期（顺延规则）。 |
| `_routineForDate` | getter（`_TodoPageState`） | B | 所选日期可见的日常一次性任务，已排序。 |
| `_workForDate` | getter（`_TodoPageState`） | B | 所选日期可见的工作一次性任务，已排序。 |
| [`_dailyTemplatesForDate`](#dailytemplatesfordate) | 方法（`_TodoPageState`） | A | 任意日期活跃的每日模板（startDate/deletedDate 窗口）。 |
| [`_allDailyCompletedOn`](#alldailycompletedon) | 方法（`_TodoPageState`） | A | 某日期每个活跃每日模板是否都完成。 |
| [`_allTasksCompletedOn`](#alltaskscompletedon) | 方法（`_TodoPageState`） | A | 某日期每个每日模板和每个可见一次性任务是否都完成。 |
| [`_someDailyCompletedOn`](#somedailycompletedon) | 方法（`_TodoPageState`） | A | 某日期是否有部分（非全部、非无）每日完成。 |
| [`_hasFutureScheduledOneTimeTask`](#hasfuturescheduledonetimetask) | 方法（`_TodoPageState`） | A | 未来日期是否恰有一次性任务安排在其上。 |
| `_showCalendar` | 方法（`_TodoPageState`） | B | 压入 `_TodoCalendarPage` 并应用其返回的日期。 |
| `_changeDate` | 方法（`_TodoPageState`） | B | 按天数移动所选日期。 |
| `_setDailyScore` | 方法（`_TodoPageState`） | B | 设置所选日评分并可选保存。 |
| [`_toggleTask`](#toggletask) | 方法（`_TodoPageState`） | A | 切换任务完成，同步子任务并提供下一次重复。 |
| [`_offerNextOccurrence`](#offernextoccurrence) | 方法（`_TodoPageState`） | A | 提示用户安排已完重复任务的下一次出现。 |
| [`_deleteTask`](#deletetask) | 方法（`_TodoPageState`） | A | 删除任务，非全新的每日模板软删除。 |
| [`_toggleSubtask`](#togglesubtask) | 方法（`_TodoPageState`） | A | 切换一个子任务完成，每日任务逐日期或一次性任务直接。 |
| `_addTask` | 方法（`_TodoPageState`） | B | 显示添加任务对话框并插入创建的任务。 |
| [`_editTask`](#edittask) | 方法（`_TodoPageState`） | A | 针对原始（未映射）任务显示编辑任务对话框并应用结果。 |
| `_buildWeekCalendar` | 方法（组件辅助） | B | 构建所选日期周的内联日历。 |
| `_buildWeekDayCell` | 方法（组件辅助） | B | 构建内联周历中的一个可选日。 |
| `_buildDailyScoreCard` | 方法（组件辅助） | B | 构建 todo 列表底部显示的评分编辑器。 |
| `build` | 方法（`_TodoPageState`） | B | 为当前加载/错误状态构建 Todo 页组件子树。 |
| `_TodoDataError({required this.message, required this.onRetry})` | 构造函数（`_TodoDataError`） | B | 显示阻塞 todo 数据读取错误。 |
| `build` | 方法（`_TodoDataError`） | B | 构建带重试按钮的阻塞错误视图。 |
| `_TodoCalendarPage({...})` | 构造函数（`_TodoCalendarPage`） | B | 创建辅助 Todo 日历页。 |
| `createState` | 方法（`_TodoCalendarPage`） | B | 为此组件创建可变状态对象。 |
| `initState` | 方法（`_TodoCalendarPageState`） | B | 从所选日期初始化可见月。 |
| [`_prevMonth`](#prevmonth) | 方法（`_TodoCalendarPageState`） | A | 把可见日历移到上个月。 |
| [`_nextMonth`](#nextmonth) | 方法（`_TodoCalendarPageState`） | A | 把可见日历移到下个月。 |
| [`_changeYear`](#changeyear) | 方法（`_TodoCalendarPageState`） | A | 按整年移动可见日历，保留月。 |
| [`_jumpToMonth`](#jumptomonth) | 方法（`_TodoCalendarPageState`） | A | 把可见日历跳到同年特定月。 |
| [`_monthScoreEntries`](#monthscoreentries) | getter（`_TodoCalendarPageState`） | A | 返回可见月中每天和评分，缺失条目为零。 |
| `_isSameDay` | 方法（`_TodoCalendarPageState`） | B | 忽略日内时间比较两个日期。 |
| `_pickDate` | 方法（`_TodoCalendarPageState`） | B | 弹出日历路由，返回所选日期。 |
| `_buildMonthNavigator` | 方法（组件辅助） | B | 构建年/月跳转控件。 |
| `_buildCalendarCard` | 方法（组件辅助） | B | 构建月历网格和图例。 |
| `_buildCalendarDayCell` | 方法（组件辅助） | B | 构建月历内的一个日期格。 |
| [`_buildScoreTrendCard`](#buildscoretrendcard) | 方法（组件辅助） | A | 构建月度每日评分折线图，含其绘制点数据。 |
| [`_buildScoreListsCard`](#buildscorelistscard) | 方法（组件辅助） | A | 把可见月条目过滤为愉悦/煎熬日列表并渲染。 |
| `_buildScoreDaySection` | 方法（组件辅助） | B | 渲染一个已过滤极端评分日期列表小节。 |
| `build` | 方法（`_TodoCalendarPageState`） | B | 构建日历页组件子树。 |
| `_CalendarLegendItem({...})` | 构造函数（`_CalendarLegendItem`） | B | 创建紧凑日历图例项。 |
| `build` | 方法（`_CalendarLegendItem`） | B | 构建图例项的图标加标签行。 |

## 文档

### `Future<void> _loadData()` <a id="loaddata"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 92 行）
- **用途：** 从 `TodoStorage` 把 todo 数据加载进状态，或记录读取错误而不丢失任何先前内存数据。
- **输入：** 无（从 `TodoStorage.load()` 读取）。
- **返回：** `Future<void>`。
- **副作用：** 切换 `_loaded` 显示加载状态；失败时把 `ReminderService` 重置为空数据并设 `_loadError`；成功时替换每个 todo 状态（`_dailyTemplates`、`_oneTimeTasks`、`_dailyLog`、`_dailyScores`、排序模式/自定义顺序、提醒时间、`_settingsModifiedAt`）并调用 `_syncReminders()`。
- **算法：**
  1. 已加载时经 `setState` 把 `_loaded` 翻转为 `false` 显示加载 UI。
  2. 在 `try/catch` 内调用 `TodoStorage.load()`。
  3. 异常时：把 `ReminderService` 重置为空每日模板/一次性任务/日志，未挂载则退出，否则把 `e.toString()` 存进 `_loadError`、设 `_loaded = true` 并返回——既有（先前加载的）内存数据保持不动，因此不可读文件绝不被静默当作"无任务"。
  4. 成功时：未挂载则退出，否则清除 `_loadError`，`data` 非 null 时把 `TodoData` 每个字段复制进本地状态（深拷贝排序模式/自定义顺序映射），两者都存在时把存储提醒时/分对转换回 `TimeOfDay`。
  5. 设 `_loaded = true` 并调用 `_syncReminders()` 把新加载数据推给 `ReminderService`。
- **用法：**
  ```dart
  @override
  void initState() {
    super.initState();
    _loadData();
    AutoSyncService.instance.addOnLocalDataChanged(_loadData);
  }
  ```
- **备注：** 因为 `_loadError` 只在成功加载时清除，先前加载失败时 `_saveData` 拒绝写入——这正是让损坏文件不被不完整状态覆盖的东西。

### `Future<void> _saveData()` <a id="savedata"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 151 行）
- **用途：** 把当前内存 todo 状态持久化到 `TodoStorage`，除非加载尚未完成或上次加载失败。
- **输入：** 无（读取当前状态字段）。
- **返回：** `Future<void>`。
- **副作用：** 经 `TodoStorage.save` 写 `todo_data.json`；可能显示 `SnackBar`；成功时调用 `_syncReminders()` 和 `AutoSyncService.instance.notifySaved()`。
- **算法：**
  1. `_loaded` 仍为 `false` 时立即返回（尚无可保存）。
  2. `_loadError` 非 null 时（mounted 时）显示 `todoDataWriteBlocked` snackbar 并写入前返回——这是防止破坏未能解析文件的守卫。
  3. 否则从每个当前内存字段构建 `TodoData` 并 await `TodoStorage.save(...)`。
  4. 调用 `_syncReminders()` 和 `AutoSyncService.instance.notifySaved()` 把变更传播给提醒调度器和同步子系统。
- **用法：**
  ```dart
  void _changeDate(int delta) { ... } // sibling caller pattern
  // Typical call site, e.g. after toggling a task:
  _toggleTask(task); // internally ends with: _saveData();
  ```
- **备注：** 除上面描述的加载错误守卫外无；本文件每个修改操作（`_toggleTask`、`_deleteTask`、`_toggleSubtask`、`_addTask`、`_editTask`、`_onTaskSortModeChanged`、`_onTaskReorder`、`_setDailyScore`）更新状态后都调用它。

### `DateTime _selectedWeekStart(int weekStartDay)` <a id="selectedweekstart"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 338 行）
- **用途：** 返回包含 `_selectedDate` 的周的第一天，遵循应用可配置周起始日。
- **输入：** `weekStartDay` — 全局配置的第一个工作日，用 Dart 的周一=1..周日=7 编号。
- **返回：** 该周第一天的 `DateTime`（已剥离时间）。
- **副作用：** 无。
- **算法：** 完全委托给 `lib/shared/utils/week_grouping.dart` 的共享 `startOfWeek(_selectedDate, weekStartDay: weekStartDay)` 辅助，它剥离日内时间并减去 `(date.weekday - weekStartDay + 7) % 7` 天。
- **用法：**
  ```dart
  List<DateTime> _selectedWeekDates(int weekStartDay) {
    final weekStart = _selectedWeekStart(weekStartDay);
    return [for (var i = 0; i < 7; i++) weekStart.add(Duration(days: i))];
  }
  ```
- **备注：** 因为取模算术在共享辅助中，本文件从不特判哪个日配置为第一天——同一代码路径处理任何 `weekStartDay` 值 1-7。

### `List<DateTime> _selectedWeekDates(int weekStartDay)` <a id="selectedweekdates"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 346 行）
- **用途：** 返回内联周历中作为日格显示的七天。
- **输入：** `weekStartDay` — 配置的第一个工作日，转发给 `_selectedWeekStart`。
- **返回：** 从 `_selectedWeekStart(weekStartDay)` 开始的恰好七个连续日期的 `List<DateTime>`。
- **副作用：** 无。
- **算法：** 经 `_selectedWeekStart` 计算周开始，然后对 `i` 在 `0..6` 加 `Duration(days: i)` 构建 7 元素列表。
- **用法：**
  ```dart
  for (final date in _selectedWeekDates(weekStartDay))
    _buildWeekDayCell(date, theme, l10n),
  ```
- **备注：** 列表总是反映所选日期自己的周——`_selectedDate` 变化时下次构建重新计算，不缓存。

### `List<Task> get _dailyForDate` <a id="dailyfordate"></a>
- **种类：** `_TodoPageState` 的 getter
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 358 行）
- **用途：** 返回所选日期可见的每日任务模板，每个模板的完成和子任务完成状态从逐日期日志叠加。
- **输入：** 无（读取 `_dailyTemplates`、`_dailyLog`、`_selectedDate`）。
- **返回：** `List<Task>`，按每日小节当前排序模式排序。
- **副作用：** 无（纯读取；返回的 `Task` 副本仅供显示）。
- **算法：**
  1. 过滤 `_dailyTemplates` 到 `startDate ?? createdDate` 不晚于所选日期、`deletedDate` 为 null 或严格晚于所选日期的那些（软删除模板在包含其删除日当天及之前继续显示）。
  2. 对每个幸存模板，经 `_dailyLog.isCompleted` 查找其在所选日期是否完成，并从 `_dailyLog.isSubtaskCompleted` 映射每个子任务的完成。
  3. 只在映射的完成/子任务状态实际不同于模板自身字段时分配新 `Task` 副本（`copyWith`），避免不必要对象搅动。
  4. 用 `_sortTasks(list, TaskType.daily)` 排序结果列表。
- **用法：**
  ```dart
  TaskSection(
    tasks: _dailyForDate,
    ...
  )
  ```
- **备注：** 这是 `_dailyTemplatesForDate`（供日历辅助使用）的每日任务对应物，但额外叠加日历辅助不需要的逐日期完成状态。

### `int _compareNullableDates(DateTime? a, DateTime? b)` <a id="comparenullabledates"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 440 行）
- **用途：** 两个可选日期的比较器，把缺失日期当作"最新"，使无截止相关日期的任务排在有日期的之后。
- **输入：** `a`、`b` — 可空 `DateTime`。
- **返回：** `int` — 按 `Comparable` 约定的负/零/正。
- **副作用：** 无。
- **算法：** 两者都 null 返回 `0`，只有 `a` null 返回 `1`（使 `a` 排在 `b` 后），只有 `b` null 返回 `-1`，否则 `a.compareTo(b)`。
- **用法：**
  ```dart
  final byDate = _compareNullableDates(_taskDueSortDate(a), _taskDueSortDate(b));
  return byDate != 0 ? byDate : _compareTaskFallback(a, b);
  ```
- **备注：** 只被 `_sortTasksForMode` 内的截止日期排序模式使用。

### `int _compareTaskFallback(Task a, Task b)` <a id="comparetaskfallback"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 452 行）
- **用途：** 为活动排序键上比较相等的任务提供确定性打破平局顺序。
- **输入：** `a`、`b` — `Task`。
- **返回：** `int` 比较器结果。
- **副作用：** 无。
- **算法：** 先比较 `createdDate`；相等时经 `_compareText` 回退不区分大小写标题比较。
- **用法：**
  ```dart
  case _taskSortCreated:
  default:
    list.sort(_compareTaskFallback);
  ```
- **备注：** `_sortTasksForMode` 的每个分支（截止、名称、自定义）都把它作为最终打破平局者，因此即使许多任务共享截止日期、名称或自定义顺序位置，排序顺序也总是完全确定。

### `List<String> _normalizedTaskOrder(TaskType type)` <a id="normalizedtaskorder"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 471 行）
- **用途：** 调和任务类型保存的自定义顺序 ID 列表与该类型当前活任务 ID——删除任务的 ID 丢弃，尚未在保存顺序中的任务 ID 追加。
- **输入：** `type` — 要规范化的顺序所属 `TaskType`。
- **返回：** 每个恰好出现一次的 `List<String>` 任务 ID。
- **副作用：** 无（不修改 `_taskCustomOrders`；调用方决定是否把结果存回）。
- **算法：**
  1. 经 `_tasksForType` 把 `type` 的所有当前任务 ID 收集进集合（`allIdSet`）。
  2. 遍历保存的自定义顺序（`_taskCustomOrders[key]`，或空），只保留仍活跃（`allIdSet.contains(id)`）且未发出（`seen.add(id)` 去重）的 ID。
  3. 追加任何剩余未见的活跃 ID，按其自然（创建日期）顺序，使新创建任务落在末尾。
- **用法：**
  ```dart
  final order = _normalizedTaskOrder(type);
  final fallbackIndex = order.length;
  list.sort((a, b) {
    final ai = order.indexOf(a.id);
    final bi = order.indexOf(b.id);
    ...
  });
  ```
- **备注：** 这正是让自定义顺序对任务删除（过期 ID 静默掉出）和任务创建（新 ID 静默追加）有弹性、从不需要显式迁移步骤的东西。

### `List<Task> _sortTasksForMode(List<Task> tasks, TaskType type, String mode)` <a id="sorttasksformode"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 491 行）
- **用途：** 按显式排序模式排序任务列表，独立于类型当前配置的模式。
- **输入：** `tasks` — 要排序的列表（复制，不原地修改）；`type` — 只用于自定义顺序分支；`mode` — `_taskSortDue`、`_taskSortName`、`_taskSortCustom`、`_taskSortCreated` 之一。
- **返回：** 新排序 `List<Task>`。
- **副作用：** 无。
- **算法：** 复制输入列表，然后按 `mode` 切换：
  1. **截止**（`_taskSortDue`）：按 `_compareNullableDates(_taskDueSortDate(a), _taskDueSortDate(b))` 排序，回退 `_compareTaskFallback`。
  2. **名称**（`_taskSortName`）：按 `_compareText(a.title, b.title)` 排序，回退 `_compareTaskFallback`。
  3. **自定义**（`_taskSortCustom`）：计算 `_normalizedTaskOrder(type)`；对每个任务，其排序键是该顺序中的索引（缺席为 `order.length`——排最后），平局回退 `_compareTaskFallback`。
  4. **创建**（`_taskSortCreated`）或任何其他值：直接按 `_compareTaskFallback` 排序。
- **用法：**
  ```dart
  List<Task> _sortTasks(List<Task> tasks, TaskType type) =>
      _sortTasksForMode(tasks, type, _taskSortMode(type));
  ```
- **备注：** `_sortTasks`（用类型活配置模式）和 `_onTaskSortModeChanged`（用显式 `currentMode` 在切换到自定义前播种自定义顺序）都调用。
- **备注：** 步骤 2 正是让首次切换到自定义顺序感觉像"冻结"当前视图而非重置为创建顺序的东西。

### `void _appendTaskToCustomOrderIfNeeded(Task task)` <a id="appendtasktocustomorderifneeded"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 538 行）
- **用途：** 该类型自定义排序活动时任务被创建，保持任务类型保存的自定义顺序同步。
- **输入：** `task` — 新创建 `Task`。
- **返回：** 无。
- **副作用：** 任务类型当前按 `_taskSortCustom` 排序时修改 `_taskCustomOrders[key]` 并调用 `_touchSettings()`；否则空操作。
- **算法：** `_taskSortMode(task.type) != _taskSortCustom` 时什么都不做。否则重新计算并存储 `_normalizedTaskOrder(task.type)`（因为新任务 id 存在于活任务集合中，现在会包含它）并调用 `_touchSettings()`。
- **用法：**
  ```dart
  setState(() {
    if (task.type == TaskType.daily) {
      _dailyTemplates.add(task);
    } else {
      _oneTimeTasks.add(task);
    }
    _appendTaskToCustomOrderIfNeeded(task);
  });
  _saveData();
  ```
- **备注：** 从 `_addTask` 和 `_offerNextOccurrence`（重复后续任务创建）调用——两个在 `_editTask` 外添加任务的地方。

### `void _removeTaskFromCustomOrders(String taskId)` <a id="removetaskfromcustomorders"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 551 行）
- **用途：** 从每个任务类型的保存自定义顺序移除已删除任务 ID，不只它自己类型的。
- **输入：** `taskId` — 被移除的 ID。
- **返回：** 无。
- **副作用：** 可能修改 `_taskCustomOrders` 中每个列表；有实际变化时调用 `_touchSettings()`。
- **算法：** 遍历 `_taskCustomOrders` 所有条目，对每个列表调用 `.remove(taskId)` 并把布尔结果 OR 进 `changed`；至少一个列表实际包含该 ID 时才调用 `_touchSettings()`。
- **用法：**
  ```dart
  } else {
    _removeTaskFromCustomOrders(task.id);
    _oneTimeTasks.removeWhere((t) => t.id == task.id);
  }
  ```
- **备注：** 遍历每个类型的顺序列表（而非只被删任务自己类型）是防御性的——它保证任何类型键下不会有过期 ID 存活。

### `void _onTaskSortModeChanged(TaskType type, String mode)` <a id="ontasksortmodechanged"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 564 行）
- **用途：** 处理用户为一个小节选新排序模式，首次选自定义排序时播种稳定自定义顺序。
- **输入：** `type` — 小节的 `TaskType`；`mode` — 新选排序模式字符串。
- **返回：** 无。
- **副作用：** 更新 `_taskSortModes[key]`，可能填充/刷新 `_taskCustomOrders[key]`，调用 `_touchSettings()` 和 `_saveData()`。
- **算法：**
  1. 切换前读取类型当前模式。
  2. 新模式是自定义且此类型尚无保存顺序时，经 `_sortTasksForMode` 按*旧*模式排序类型当前活任务并按其顺序取 ID 播种 `_taskCustomOrders[key]`——使首次切换到自定义顺序保留已可见的任何顺序。
  3. 把新模式存进 `_taskSortModes[key]`。
  4. 新模式是自定义（含顺序已存在时）时经 `_normalizedTaskOrder(type)` 刷新它，对照活任务调和。
  5. 在 `setState` 内调用 `_touchSettings()`，然后 `_saveData()`。
- **用法：**
  ```dart
  onSortModeChanged: (mode) =>
      _onTaskSortModeChanged(TaskType.daily, mode),
  ```
- **备注：** 步骤 2 正是让首次切换到自定义顺序感觉像"冻结"当前视图而非重置为创建顺序的东西。

### `void _onTaskReorder(TaskType type, List<Task> visibleTasks, int oldIndex, int newIndex)` <a id="ontaskreorder"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 589 行）
- **用途：** 把当前可见（过滤）任务列表上执行的拖放重排应用回类型完整保存自定义顺序，它可能包含比当前可见更多的 ID。
- **输入：** `type`；`visibleTasks` — UI 中实际显示（和拖动）的列表；`oldIndex`/`newIndex` — Flutter `ReorderableListView` 索引。
- **返回：** 无。
- **副作用：** 修改 `_taskCustomOrders[key]`、把 `type` 排序模式强制为 `_taskSortCustom`、调用 `_touchSettings()` 和 `_saveData()`。
- **算法：**
  1. 按 Flutter `ReorderableListView` 约定调整 `newIndex`（移过被移除项则减一）。
  2. 对照 `visibleIds.length` 边界检查 `oldIndex`/`newIndex`；越界返回。
  3. 构建 `reorderedVisible`：从 `oldIndex` 移除拖拽 ID 并在 `newIndex` 重新插入，只在可见 ID 副本上。
  4. 重新计算完整规范化顺序，然后遍历完整顺序重建它，对可见集合中每个 ID 按顺序代入 `reorderedVisible` 的下一个 ID（经 `replacementIndex`）；不在可见集合的 ID（如被过滤器隐藏）保持既有相对位置不动。
  5. 强制 `_taskSortModes[key] = _taskSortCustom`（拖动总是把小节切换到自定义排序）并调用 `_touchSettings()`。
- **用法：**
  ```dart
  onReorder: (oldIndex, newIndex) =>
      _onTaskReorder(TaskType.daily, _dailyForDate, oldIndex, newIndex),
  ```
- **备注：** 步骤 4 的交错正是让在过滤/可见子集上执行的拖动更新完整顺序中正确位置、而不打扰用户看不到或拖不动的 ID 的关键技巧。

### `bool _oneTimeVisibleOnDate(Task t)` <a id="onetimevisibleondate"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 634 行）
- **用途：** 决定一次性（日常/工作）任务是否应显示在当前所选日期。
- **输入：** `t` — 要测试的一次性 `Task`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：**
  1. `t.scheduledDate` 为 null 时永远不可见（返回 `false`）。
  2. 任务已完成且有 `completedDate`：只在所选日期等于 `scheduledDate` **或**等于 `completedDate` 时可见——即它从被安排和被完成之间严格的日子消失。
  3. 未完成：所选日期等于 `scheduledDate`（即使在将来）时可见，或 `scheduledDate` 不晚于所选日期且所选日期不晚于今天——这是"顺延"规则，让过期未完成任务每天都显示直到完成或进入将来。
- **用法：**
  ```dart
  List<Task> get _routineForDate {
    final list = _oneTimeTasks
        .where((t) => t.type == TaskType.routineOnce && _oneTimeVisibleOnDate(t))
        .toList();
    return _sortTasks(list, TaskType.routineOnce);
  }
  ```
- **备注：** 这完全相同完成/顺延逻辑在 `_allTasksCompletedOn` 内联重新实现（不调用此方法），因为那个方法需要同一可见性规则加单遍完成检查。

### `List<Task> _dailyTemplatesForDate(DateTime date)` <a id="dailytemplatesfordate"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 685 行）
- **用途：** 返回任意日期（不一定是所选日期）活跃的每日模板，尊重 `startDate`/`deletedDate`。
- **输入：** `date` — 任意 `DateTime`。
- **返回：** 每日模板的 `List<Task>`（无叠加完成状态）。
- **副作用：** 无。
- **算法：** 过滤 `_dailyTemplates` 到 `startDate ?? createdDate` 不晚于 `date`、`deletedDate` 为 null 或严格晚于 `date` 的那些——与 `_dailyForDate` 过滤步骤相同的窗口规则，但可复用于任何日期（供日历完成标记辅助使用）。
- **用法：**
  ```dart
  bool _allDailyCompletedOn(DateTime date) {
    final templates = _dailyTemplatesForDate(date);
    if (templates.isEmpty) return false;
    ...
  ```
- **备注：** 与 `_dailyForDate` 不同，这从不叠加逐日期完成——它纯粹是"此日期存在且尚未删除哪些模板"，作为 `_...CompletedOn` 家族输入使用。

### `bool _allDailyCompletedOn(DateTime date)` <a id="alldailycompletedon"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 699 行）
- **用途：** 报告 `date` 上活跃的每个每日模板是否都标记为那天完成。
- **输入：** `date`。
- **返回：** `bool` — 那天无活跃模板时 `false`。
- **副作用：** 无。
- **算法：** 经 `_dailyTemplatesForDate(date)` 获取活跃模板；为空立即返回 `false`；否则遍历模板并在 `_dailyLog` 中第一个未完成处返回 `false`，否则 `true`。
- **用法：**
  ```dart
  _TodoCalendarPage(
    ...
    allDailyCompleted: _allDailyCompletedOn,
    ...
  )
  ```
- **备注：** 按引用传入 `_TodoCalendarPage`，使日历网格能在日历页自身不持有任何任务数据的情况下逐日计算完成标记。

### `bool _allTasksCompletedOn(DateTime date)` <a id="alltaskscompletedon"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 713 行）
- **用途：** 报告 `date` 上可见的每个每日模板和每个一次性任务是否都完成——日历对勾使用的最强"完全完成日"信号。
- **输入：** `date`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：**
  1. `_allDailyCompletedOn(date)` 为 `false` 时短路 `false`。
  2. 对每个有 `scheduledDate` 的一次性任务，内联重新计算其在 `date` 的可见性（与 `_oneTimeVisibleOnDate` 相同的完成/顺延规则，针对显式 `date` 参数而非 `_selectedDate` 重新实现）。
  3. 任务在 `date` 可见且未完成时立即返回 `false`。
  4. 检查无失败时返回 `true`。
- **用法：**
  ```dart
  allTasksCompleted: _allTasksCompletedOn,
  ```
- **备注：** 针对任意 `date` 而非 `_selectedDate` 重复 `_oneTimeVisibleOnDate` 的逻辑，因为该 getter 硬编码到所选日期；见该条目备注。

### `bool _someDailyCompletedOn(DateTime date)` <a id="somedailycompletedon"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 737 行）
- **用途：** 检测"部分完成"日——至少一个但非所有活跃每日模板完成——供日历部分进度标记。
- **输入：** `date`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 经 `_dailyTemplatesForDate(date)` 获取活跃模板，无则返回 `false`；否则遍历按模板完成设 `anyDone`/`allDone` 标志，返回 `anyDone && !allDone`（全部完成的日子由 `_allDailyCompletedOn` 报告，不是此方法）。
- **用法：**
  ```dart
  someDailyCompleted: _someDailyCompletedOn,
  ```
- **备注：** 无。

### `bool _hasFutureScheduledOneTimeTask(DateTime date)` <a id="hasfuturescheduledonetimetask"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 757 行）
- **用途：** 检查未来日历日期是否恰有一次性（日常/工作）任务安排在其上，以显示小"即将到来"标记。
- **输入：** `date`。
- **返回：** `bool` — 今天或过去的日期总是 `false`。
- **副作用：** 无。
- **算法：** `date` 不晚于今天时立即返回 `false`。否则检查任何一次性任务（排除 `TaskType.daily` 和无 `scheduledDate` 的任务）是否有 `scheduledDate` 恰好（仅日）等于 `date`。
- **用法：**
  ```dart
  hasFutureScheduledOneTimeTask: _hasFutureScheduledOneTimeTask,
  ```
- **备注：** 刻意忽略每日模板和顺延的过期一次性任务——它只标记*新*安排在那个确切未来日期开始的任务。

### `void _toggleTask(Task task)` <a id="toggletask"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 826 行）
- **用途：** 切换任务完成状态，保持其子任务同步，对正在完成的重复一次性任务，提供安排下一次出现。
- **输入：** `task` — 被切换的 `Task`（按当前显示，每日任务是逐日期映射副本而非原始模板）。
- **返回：** 无。
- **副作用：** 修改 `_dailyLog` 或 `_oneTimeTasks`；调用 `_saveData()`；可能把帧后回调安排进 `_offerNextOccurrence`。
- **算法：**
  1. **每日任务：** 在 `_dailyLog.toggle(_selectedDate, task.id)` 切换逐日期完成，查找活模板（未找到回退 `task`），有子任务时经 `_dailyLog.setSubtasksCompleted` 批量把每个子任务的逐日期完成设为与模板新完成状态匹配。
  2. **一次性任务：** 在 `_oneTimeTasks` 找索引；翻转 `isCompleted`；把每个子任务的 `isCompleted` 映射到相同新值；经其完整构造函数（非 `copyWith`）重建 `Task`，正为取消完成时能把 `completedDate` 设为 `null`（`copyWith` 无法把字段清回 null）；任务新完成且有 `recurrence` 时把更新任务暂存进 `completedWithRecurrence`。
  3. `setState` 后调用 `_saveData()`。
  4. 刚完成重复任务时在下一帧（`addPostFrameCallback`）安排 `_offerNextOccurrence`，使对话框在当前构建安定后打开，用 `mounted` 守卫。
- **用法：**
  ```dart
  TaskSection(
    ...
    onToggle: _toggleTask,
    ...
  )
  ```
- **备注：** 步骤 2 的完整构造函数重建是刻意变通——按模型 `Task.copyWith` 无法把可空字段设回 `null`，而取消完成任务清除其 `completedDate` 时需要。

### `Future<void> _offerNextOccurrence(Task completedTask)` <a id="offernextoccurrence"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 893 行）
- **用途：** 重复一次性任务完成后，计算其下一次出现日期并让用户确认/编辑并创建该后续任务。
- **输入：** `completedTask` — 刚完成 `Task`，必须有非 null `recurrence`。
- **返回：** `Future<void>`。
- **副作用：** 可能向 `_oneTimeTasks` 添加新 `Task`、调用 `_appendTaskToCustomOrderIfNeeded` 和 `_saveData()`；显示 `AddTaskDialog`。
- **算法：**
  1. 经 `completedTask.recurrence!.nextDate(completedTask.scheduledDate ?? completedTask.createdDate)` 计算 `nextDate`。
  2. 构建预填 `nextTask`（相同标题/备注/emoji/类型/提醒/重复，子任务重置未完成，`scheduledDate: nextDate`）。
  3. 显示用 `nextTask` 预填充、经 `l10n.todoNextOccurrence` 标题的 `AddTaskDialog`，await 用户（可能编辑的）结果。
  4. 用户确认（返回非 null 任务）且组件仍 mounted 时添加进 `_oneTimeTasks`、运行 `_appendTaskToCustomOrderIfNeeded` 并保存。
- **用法：**
  ```dart
  if (completedWithRecurrence != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _offerNextOccurrence(completedWithRecurrence!);
    });
  }
  ```
- **备注：** 精确重复间隔数学（`nextDate`）住在模型中的 `TaskRecurrence`，不在这里——见 [Todo](../../../../features/todo.md#model)。

### `void _deleteTask(Task task)` <a id="deletetask"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 932 行）
- **用途：** 删除任务，一次性任务和当前所选日期创建的每日模板硬删除，但较旧每日模板软删除（盖章 `deletedDate`），使历史完成日志保持有意义。
- **输入：** `task` — 要删除的 `Task`。
- **返回：** 无。
- **副作用：** 修改 `_dailyTemplates` 或 `_oneTimeTasks`；可能调用 `_removeTaskFromCustomOrders`；调用 `_saveData()`。
- **算法：**
  1. **每日任务：** 在 `_dailyTemplates` 找索引。把 `start = startDate ?? createdDate` 与所选日期（仅日）比较。同一天时模板今天创建且从无历史，完全移除并清理其自定义顺序条目。否则经 `copyWith` 设 `deletedDate: _selectedDate` 软删除，让模板留在列表（使引用它的过去完成日志仍解析）。
  2. **一次性任务：** 移除其自定义顺序条目并按 ID 从 `_oneTimeTasks` 完全移除。
  3. 调用 `_saveData()`。
- **用法：**
  ```dart
  TaskSection(
    ...
    onDelete: _deleteTask,
    ...
  )
  ```
- **备注：** 这是 [Todo](../../../../features/todo.md#model) 描述的"每日模板在其开始日后绝不硬删除"规则的具体实现。

### `void _toggleSubtask(Task task, SubTask subtask)` <a id="togglesubtask"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 962 行）
- **用途：** 切换一个子任务完成，每日任务用逐日期日志、一次性任务直接修改。
- **输入：** `task` — 父 `Task`；`subtask` — 被切换的 `SubTask`。
- **返回：** 无。
- **副作用：** 修改 `_dailyLog` 或 `_oneTimeTasks` 中匹配条目；调用 `_saveData()`。
- **算法：**
  1. **每日任务：** 调用 `_dailyLog.toggleSubtask(_selectedDate, subtask.id)`——完成按日期跟踪，不在模板本身上。
  2. **一次性任务：** 在 `_oneTimeTasks` 找任务索引（未找到提前返回）；映射其子任务，只翻转匹配子任务 ID 的 `isCompleted`；经 `copyWith` 写回更新子任务列表。
  3. 调用 `_saveData()`。
- **用法：**
  ```dart
  onSubtaskToggle: _toggleSubtask,
  ```
- **备注：** 与 `_toggleTask` 不同，这不在所有子任务完成时尝试自动完成父任务——子任务和父完成独立跟踪。

### `Future<void> _editTask(Task task)` <a id="edittask"></a>
- **种类：** `_TodoPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 1013 行）
- **用途：** 针对真实（未映射）底层任务打开编辑任务对话框，为软删除每日模板提供永久删除选项，并应用对话框返回的任何东西。
- **输入：** `task` — 显示的 `Task`（每日任务可能来自 `_dailyForDate` 的逐日期映射副本，不是存储模板）。
- **返回：** `Future<void>`。
- **副作用：** 可能从 `_dailyTemplates` 移除（永久删除）或替换 `_dailyTemplates`/`_oneTimeTasks` 中的条目（正常编辑）；两种情况都调用 `_saveData()`。
- **算法：**
  1. 解析 `originalTask`：每日任务按 ID 在 `_dailyTemplates` 查找真实模板（未找到回退 `task`），使对话框编辑未映射真相源而非逐日期显示副本。
  2. `originalTask.deletedDate != null`（即软删除每日模板）时才构建 `onPermanentDelete` 回调——调用它设 `permanentlyDeleted = true`、从 `_dailyTemplates` 移除模板并保存。
  3. 显示带 `originalTask` 和可选回调的 `EditTaskDialog`；await 其结果。
  4. 对话框返回更新任务且未经回调永久删除时，按 ID 替换 `_dailyTemplates` 或 `_oneTimeTasks` 中匹配条目并保存。
- **用法：**
  ```dart
  onEdit: _editTask,
  ```
- **备注：** 步骤 2-4 是单次对话框调用的互斥结果——用户要么永久删除（经对话框自己的删除选项）要么正常编辑保存，绝不两者。

### `void _prevMonth()` <a id="prevmonth"></a>
- **种类：** `_TodoCalendarPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 1583 行）
- **用途：** 把可见日历月往回移一个月。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 经 `setState` 更新 `_viewMonth`。
- **算法：** 设 `_viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1)`。Dart 的 `DateTime` 构造函数规范化越界月份，因此从一月往回（`month - 1 == 0`）自动滚到上一年十二月，无需显式年份算术。
- **用法：**
  ```dart
  IconButton(
    icon: const Icon(Icons.chevron_left),
    onPressed: _prevMonth,
  ),
  ```
- **备注：** 依赖与 `_nextMonth` 相同的自动月/年规范化；本文件任何地方都没有手动 `if (month == 0)` 分支。

### `void _nextMonth()` <a id="nextmonth"></a>
- **种类：** `_TodoCalendarPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 1594 行）
- **用途：** 把可见日历月往前移一个月。
- **输入：** 无。
- **返回：** 无。
- **副作用：** 经 `setState` 更新 `_viewMonth`。
- **算法：** 设 `_viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1)`，依赖 `DateTime` 自动翻转（`month == 13` 变成下一年一月）。
- **用法：**
  ```dart
  IconButton(
    icon: const Icon(Icons.chevron_right),
    onPressed: _nextMonth,
  ),
  ```
- **备注：** 见 `_prevMonth`；两个方向都依赖相同构造函数规范化而非显式分支。

### `void _changeYear(int delta)` <a id="changeyear"></a>
- **种类：** `_TodoCalendarPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 1605 行）
- **用途：** 按整年移动可见日历，保持相同可见月。
- **输入：** `delta` — 带符号年份偏移（UI 只传 `-1`/`1`）。
- **返回：** 无。
- **副作用：** 经 `setState` 更新 `_viewMonth`。
- **算法：** 设 `_viewMonth = DateTime(_viewMonth.year + delta, _viewMonth.month)`，精确保留月分量。
- **用法：**
  ```dart
  onPressed: () => _changeYear(-1),
  ...
  onPressed: () => _changeYear(1),
  ```
- **备注：** 无。

### `void _jumpToMonth(int month)` <a id="jumptomonth"></a>
- **种类：** `_TodoCalendarPageState` 的方法
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 1616 行）
- **用途：** 把可见日历直接跳到当前可见年内特定月。
- **输入：** `month` — 1-12（Dart 月份编号）。
- **返回：** 无。
- **副作用：** 经 `setState` 更新 `_viewMonth`。
- **算法：** 设 `_viewMonth = DateTime(_viewMonth.year, month)`——年保持原样，只月变化。
- **用法：**
  ```dart
  onSelected: (_) => _jumpToMonth(month),
  ```
- **备注：** 由 `_buildMonthNavigator` 构建的内联月选择器菜单使用；与 `_prevMonth`/`_nextMonth` 不同没有翻转问题，因为 `month` 总是来自那个菜单的有效 1-12 值。

### `List<MapEntry<DateTime, int>> get _monthScoreEntries` <a id="monthscoreentries"></a>
- **种类：** `_TodoCalendarPageState` 的 getter
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 1627 行）
- **用途：** 返回可见月中每个日历日及其评分配对，无保存评分条目的任何日当作零——同时供评分趋势图和愉悦/煎熬日列表的单一数据源。
- **输入：** 无（读取 `_viewMonth`、`widget.dailyScores`）。
- **返回：** `List<MapEntry<DateTime, int>>`，`_viewMonth` 每天一个条目，按月内日顺序。
- **副作用：** 无。
- **算法：** 经 `DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day` 计算月天数（下月 0 日 = 本月最后一天），然后从 1 到该计数为每天构建一个 `MapEntry`，经 `widget.dailyScores.scoreFor(...)` 查找每天评分（缺失条目返回 0）。
- **用法：**
  ```dart
  Widget _buildScoreTrendCard(ThemeData theme, AppLocalizations l10n) {
    final entries = _monthScoreEntries;
    final spots = entries.map(
      (entry) => FlSpot(entry.key.day.toDouble(), entry.value.toDouble()),
    ).toList();
    ...
  ```
- **备注：** 因为每天总是包含（缺失条目为零而非省略），两个消费组件从不需要特判评分日志中的缺口。

### `Widget _buildScoreTrendCard(ThemeData theme, AppLocalizations l10n)` <a id="buildscoretrendcard"></a>
- **种类：** `_TodoCalendarPageState` 的方法（组件辅助）
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 1913 行）
- **用途：** 构建月度每日评分趋势折线图，包括把月的评分条目转换为可绘图数据。
- **输入：** `theme`、`l10n`。
- **返回：** 含 `fl_chart` `LineChart` 的 `Card`。
- **副作用：** 创建图表 UI 组件；在 `entries` 上接工具提示格式化闭包。
- **算法：**
  1. 拉取 `_monthScoreEntries` 并把每个条目映射为 `FlSpot(day, score)`（X 轴是月内日为 double，Y 轴是评分）。
  2. 直接从 `DailyScoreLog.minScore`/`maxScore` 配置轴边界（Y）和 `1`..`entries.length`（X）。
  3. 配置底部轴刻度标题只在范围内的精确整数日渲染（`interval: 7`），左轴每 5 个评分点一个刻度。
  4. 按符号给每个数据点着色：零为 `onSurfaceVariant`、正为 `primary`、负为 `error`（经 `getDotPainter`）。
  5. 接 `LineTouchTooltipData.getTooltipItems` 把触摸点 X 位置映射回对应 `entries` 索引（钳制到有效范围）并渲染其格式化日期和评分。
- **用法：**
  ```dart
  _buildScoreTrendCard(theme, l10n),
  _buildScoreListsCard(theme, l10n),
  ```
- **备注：** "每天都绘制"（按源码注释）意味着许多零/无条目日子的月仍显示那些天 y=0 的连续线而非缺口——这是 `_monthScoreEntries` 总是包含每天的直接结果。

### `Widget _buildScoreListsCard(ThemeData theme, AppLocalizations l10n)` <a id="buildscorelistscard"></a>
- **种类：** `_TodoCalendarPageState` 的方法（组件辅助）
- **来源：** `lib/features/todo/views/todo_page.dart`（约第 2089 行）
- **用途：** 把可见月的评分条目过滤为"愉悦"和"煎熬"日列表并作为两个小节渲染。
- **输入：** `theme`、`l10n`。
- **返回：** 含被 `Divider` 分隔的两个 `_buildScoreDaySection` 输出的 `Card`。
- **副作用：** 创建 UI 组件；每个渲染日期 chip 接 `onPressed: () => _pickDate(entry.key)` 回调。
- **算法：** 把 `_monthScoreEntries` 过滤为 `joyfulDays`（`entry.value >= 4`）和 `sufferingDays`（`entry.value <= -4`），然后把每个过滤列表连同其图标/颜色/标签集合传给 `_buildScoreDaySection`（愉悦为太阳图标 + primary 色，煎熬为雷暴图标 + error 色）。
- **用法：**
  ```dart
  Widget build(BuildContext context) {
    ...
    _buildScoreTrendCard(theme, l10n),
    _buildScoreListsCard(theme, l10n),
  ```
- **备注：** `>= 4` / `<= -4` 阈值是"愉悦"/"煎熬"的实际过滤规则，针对 -5 到 5 的评分范围（见 [Todo](../../../../features/todo.md#model)）；`_buildScoreDaySection` 自己不过滤，只渲染。

## 相关页面

- [Todo](../../../../features/todo.md) — `Task`、`TaskRecurrence`、`DailyCompletionLog`、`DailyScoreLog` 模型概念和本文件实现的存储/提醒规则。
- [三方合并](../../../../algorithms/three-way-merge.md) — `_dailyLog`/`_dailyScores` 如何跨设备合并（不在此文件实现，但本文件编辑该状态）。

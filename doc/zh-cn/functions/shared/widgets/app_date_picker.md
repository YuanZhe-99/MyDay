# lib/shared/widgets/app_date_picker.dart

应用对 Flutter `showDatePicker` / `showDateRangePicker` 的替代。每个模块都经 `showAppDatePicker` 或 `showAppDateRangePicker` 挑选日期，使日历行为——尤其**周起始日**——全应用一致而非跟随平台语言区域。周起始来自 `TodoStorage.getWeekStartDay()`（Todo 和亲密日历读取的相同持久化设置），星期页头顺序由 [`week_grouping.dart`](../utils/week_grouping.md) 产生。

文件是两个公共入口点加四个私有组件（`_AppDatePickerDialog`、`_AppDateRangePickerDialog`、`_CalendarMonthPicker`、`_CalendarDateCell`）和四个纯日期辅助。`_CalendarMonthPicker` 渲染一个月网格并被两个对话框共享；单日期对话框选择即确认，而范围对话框先收集开始再收集结束，然后确认按钮才启用。

## 声明

锚点说明：`_changeMonth` 和 `build` 各自在本文件多个类中定义，因此那些行用类限定锚点（`changemonth-single`、`build-range`……）而非通用规则会产生的裸名锚点。

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`showAppDatePicker`](#showappdatepicker) | 顶层函数 | A | 用全局周起始设置显示应用标准单日期选择器。 |
| [`showAppDateRangePicker`](#showappdaterangepicker) | 顶层函数 | A | 用全局周起始设置显示应用标准日期范围选择器。 |
| `_AppDatePickerDialog.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_AppDatePickerDialog.createState` | 方法（`_AppDatePickerDialog`） | B | 创建 `_AppDatePickerDialogState`。 |
| `_AppDatePickerDialogState.initState` | 方法（生命周期） | B | 从初始日期初始化可见月。 |
| [`_changeMonth`](#changemonth-single) | 方法（`_AppDatePickerDialogState`） | A | 按月增量移动可见日历月。 |
| `_AppDatePickerDialogState.build` | 方法（组件） | B | 渲染单日期对话框。 |
| `_AppDateRangePickerDialog.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_AppDateRangePickerDialog.createState` | 方法（`_AppDateRangePickerDialog`） | B | 创建 `_AppDateRangePickerDialogState`。 |
| `_AppDateRangePickerDialogState.initState` | 方法（生命周期） | B | 初始化可见月和所选范围。 |
| [`_changeMonth`](#changemonth-range) | 方法（`_AppDateRangePickerDialogState`） | A | 按月增量移动可见日历月。 |
| [`_selectDate`](#selectdate) | 方法（`_AppDateRangePickerDialogState`） | A | 把点击日期应用到进行中的范围选择。 |
| [`_AppDateRangePickerDialogState.build`](#build-range) | 方法（组件） | A | 渲染范围对话框，两端都选后才启用确认。 |
| `_CalendarMonthPicker.new` | 构造函数 | B | 平凡转发构造函数。 |
| [`_canGoPrevious`](#cangoprevious) | getter（`_CalendarMonthPicker`） | A | 上个月是否与允许日期范围重叠。 |
| [`_canGoNext`](#cangonext) | getter（`_CalendarMonthPicker`） | A | 下个月是否与允许日期范围重叠。 |
| [`_CalendarMonthPicker.build`](#build-month) | 方法（组件） | A | 用 `weekStartDay` 星期排序渲染一个本地化月网格。 |
| `_CalendarDateCell.new` | 构造函数 | B | 平凡转发构造函数。 |
| `_CalendarDateCell.build` | 方法（组件） | B | 渲染一个可选日期格。 |
| [`_isInRange`](#isinrange) | 顶层函数 | A | 日期是否严格落在所选范围内。 |
| [`_dateOnly`](#dateonly) | 顶层函数 | A | 从日期剥离时间分量。 |
| [`_isSameDay`](#issameday) | 顶层函数 | A | 两个值是否代表相同日历日。 |
| [`_clampDate`](#clampdate) | 顶层函数 | A | 把日期钳制进包含仅日期范围。 |

**对账：** `grep -c 'Purpose:' lib/shared/widgets/app_date_picker.dart` 报告 23，与上面 23 行精确匹配（13 个 Tier A、10 个 Tier B）。每个 `/// Purpose:` 块都恰好位于其文档化的真实声明正上方；未发现错附块，文件也不存在未文档化真实声明。本页 v1.3.2 添加——文件自创建起一直缺失于 [INDEX.md](../../INDEX.md)。

## 文档

### `Future<DateTime?> showAppDatePicker({required BuildContext context, required DateTime initialDate, required DateTime firstDate, required DateTime lastDate, String? title})` <a id="showappdatepicker"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 13 行）
- **用途：** 用全局周起始设置显示应用标准日期选择器。
- **输入：** `context`、`initialDate`、包含 `firstDate`/`lastDate` 边界和可选对话框 `title`。
- **返回：** `Future<DateTime?>` — 所选日期，取消时 null。
- **副作用：** 读取持久化周起始设置并打开对话框。
- **算法：**
  1. `await TodoStorage.getWeekStartDay()`。
  2. 那个 await 后 context 不再 mounted 时返回 null 退出。
  3. `showDialog` 一个 `_AppDatePickerDialog`，初始日期经 [`_clampDate`](#clampdate) 传递、每个边界经 [`_dateOnly`](#dateonly) 传递。
- **用法：** `showDatePicker` 的全应用替代；从 Todo、财务、亲密和体重日期字段调用。
- **备注：** 存储读取后的 `context.mounted` 守卫重要——调用方屏幕可在设置加载时被弹出。钳制初始日期意味着调用方可传越界值而对话框不打开在不可选日上。

### `Future<DateTimeRange?> showAppDateRangePicker({required BuildContext context, required DateTime firstDate, required DateTime lastDate, DateTimeRange? initialDateRange, String? title})` <a id="showappdaterangepicker"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 39 行）
- **用途：** 用全局周起始设置显示应用标准日期范围选择器。
- **输入：** `context`、包含 `firstDate`/`lastDate` 边界、可选 `initialDateRange` 和可选对话框 `title`。
- **返回：** `Future<DateTimeRange?>` — 所选范围，取消时 null。
- **副作用：** 读取持久化周起始设置并打开对话框。
- **算法：** 与 `showAppDatePicker` 相同形态，额外在提供时钳制 `initialDateRange` 两端。
- **用法：** 财务分析页的自定义范围选项。
- **备注：** 用户点击开始日期然后结束日期；两端都设前确认保持禁用。

### `void _changeMonth(int delta)`（`_AppDatePickerDialogState` 中） <a id="changemonth-single"></a>
- **种类：** `_AppDatePickerDialogState` 的方法
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 121 行）
- **用途：** 把可见日历月移动 `delta` 个月。
- **输入：** `delta` — 要加的月数，负为往回。
- **返回：** 无。
- **副作用：** 经 `setState` 更新对话框状态。
- **备注：** 依赖 `DateTime` 把月 0 或 13 规范化进相邻年份。这里无边界检查：导航按钮已被范围边缘的 [`_canGoPrevious`](#cangoprevious)/[`_canGoNext`](#cangonext) 禁用。

### `void _changeMonth(int delta)`（`_AppDateRangePickerDialogState` 中） <a id="changemonth-range"></a>
- **种类：** `_AppDateRangePickerDialogState` 的方法
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 219 行）
- **用途：** 把可见日历月移动 `delta` 个月。
- **输入：** `delta`。
- **返回：** 无。
- **副作用：** 经 `setState` 更新对话框状态。
- **备注：** 与单日期对话框副本相同；两个对话框不共享状态基类。

### `void _selectDate(DateTime date)` <a id="selectdate"></a>
- **种类：** `_AppDateRangePickerDialogState` 的方法
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 230 行）
- **用途：** 把点击日期应用到进行中的范围选择。
- **输入：** `date` — 点击的日。
- **返回：** 无。
- **副作用：** 经 `setState` 更新 `_start`/`_end`。
- **算法：**
  1. 未设开始或范围已完成时，在 `date` 开始新范围并清除结束——第三次点击重启而非延伸。
  2. 否则 `date` 早于当前开始时交换：旧开始成为结束、`date` 成为开始。
  3. 否则把结束设为 `date`。
- **备注：** 步骤 2 正是用户能以任一顺序选择两端的原因。

### `Widget build(BuildContext context)`（`_AppDateRangePickerDialogState` 中） <a id="build-range"></a>
- **种类：** `_AppDateRangePickerDialogState` 的方法
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 250 行）
- **用途：** 构建此日期范围选择器对话框。
- **输入：** `context`。
- **返回：** 对话框组件树。
- **副作用：** 创建 UI 组件和日期选择回调。
- **备注：** 确认操作直到 `_start` 和 `_end` 都非 null 前为 null——因此按钮禁用——使半选范围绝不可能被返回。

### `bool get _canGoPrevious` <a id="cangoprevious"></a>
- **种类：** `_CalendarMonthPicker` 的 getter
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 337 行）
- **用途：** 返回是否允许移到上个月。
- **输入：** 无。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 把上个月最后一天构建为 `DateTime(viewMonth.year, viewMonth.month, 0)`，除非它早于 `firstDate` 否则允许导航。
- **备注：** 测试上个月的**末**而非其开始，使部分可选月仍可达。

### `bool get _canGoNext` <a id="cangonext"></a>
- **种类：** `_CalendarMonthPicker` 的 getter
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 347 行）
- **用途：** 返回是否允许移到下个月。
- **输入：** 无。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 构建下个月第一天，除非它晚于 `lastDate` 否则允许导航。
- **备注：** [`_canGoPrevious`](#cangoprevious) 的镜像——测试下个月的**开始**。

### `Widget build(BuildContext context)`（`_CalendarMonthPicker` 中） <a id="build-month"></a>
- **种类：** `_CalendarMonthPicker` 的方法
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 358 行）
- **用途：** 构建本地化日历月选择器。
- **输入：** `context`。
- **返回：** 月网格组件树，含月页头和导航按钮。
- **副作用：** 创建 UI 组件和回调。
- **备注：** 星期列顺序经 `week_grouping.dart` 的 `weekdaySequence`/`localizedWeekdayLabel` 遵循 `weekStartDay`，前导空白来自 `leadingBlankDaysForMonth`——这正是应用不用 Flutter 内置选择器的全部原因。

### `bool _isInRange(DateTime date, DateTime? start, DateTime? end)` <a id="isinrange"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 527 行）
- **用途：** 返回 `date` 是否在所选日期范围内。
- **输入：** `date`、可空 `start`、可空 `end`。
- **返回：** `bool` — 任一端点为 null 时 false。
- **副作用：** 无。
- **备注：** 对两端**排他**（`isAfter` / `isBefore`），因为两端用自己的选中样式绘制、不应再获得范围内填充。

### `DateTime _dateOnly(DateTime date)` <a id="dateonly"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 537 行）
- **用途：** 从日期剥离时间分量。
- **输入：** `date`。
- **返回：** 本地午夜 `DateTime`。
- **副作用：** 无。
- **备注：** 文件本地；`cycle_predictor.dart` 有自己的公共 `dateOnly`，语义相同。

### `bool _isSameDay(DateTime a, DateTime b)` <a id="issameday"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 544 行）
- **用途：** 返回两个日期值是否代表相同日历日。
- **输入：** `a`、`b`。
- **返回：** `bool`。
- **副作用：** 无。
- **备注：** 直接比较年/月/日而非先规范化，因此对仍带时间分量的值调用安全。

### `DateTime _clampDate(DateTime date, DateTime firstDate, DateTime lastDate)` <a id="clampdate"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/widgets/app_date_picker.dart`（第 552 行）
- **用途：** 把 `date` 钳制进包含仅日期范围。
- **输入：** `date`、`firstDate`、`lastDate`。
- **返回：** `DateTime` — `firstDate`、`lastDate` 或仅日期输入。
- **副作用：** 无。
- **备注：** 先把三个输入都经 [`_dateOnly`](#dateonly) 规范化，使调用方时间分量不能把边界日期推出范围。

## 相关页面

- [`week_grouping.dart`](../utils/week_grouping.md) — 星期排序和月网格辅助。
- [`todo_storage.dart`](../../features/todo/services/todo_storage.md) — `getWeekStartDay()`，这些选择器尊重的持久化设置。
- [设置](../../../features/settings.md) — 用户更改周起始日的地方。

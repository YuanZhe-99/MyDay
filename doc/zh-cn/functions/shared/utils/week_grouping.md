# lib/shared/utils/week_grouping.dart

整个应用的共享日历周数学：按可配置周起始日分组记录、计算周编号年/周（ISO 8601 的四天规则变体，锚定到配置起始日而非总是周一）、日历 UI 的星期标签/顺序辅助，以及月网格的空白格计数。`weekStartDay` 从 `appSettingsProvider` 读取（见 [app_settings.dart](../providers/app_settings.md)）并贯穿 Todo、体重和亲密历史视图加 `shared/widgets/app_date_picker.dart`，使应用每个日历对同一第一工作日达成一致。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`WeekGroup`（构造函数）](#weekgroup-new) | 构造函数（`WeekGroup<T>`） | A | 创建不可变周组值。 |
| [`groupByWeek`](#groupbyweek) | 顶层函数 | A | 用可配置周起始日按日历周分组项。 |
| [`groupByIsoWeek`](#groupbyisoweek) | 顶层函数 | A | 按 ISO 周（周一起始）分组项——兼容包装。 |
| [`normalizeWeekStartDay`](#normalizeweekstartday) | 顶层函数 | A | 把持久化工作日值钳制回有效 Dart 工作日。 |
| [`weekdaySequence`](#weekdaysequence) | 顶层函数 | A | 返回从配置周起始开始的顺序工作日。 |
| [`localizedWeekdayLabel`](#localizedweekdaylabel) | 顶层函数 | A | 返回本地化短/长星期标签。 |
| [`startOfWeek`](#startofweek) | 顶层函数 | A | 返回配置周的第一个日历日期。 |
| [`startOfIsoWeek`](#startofisoweek) | 顶层函数 | A | 返回开始 ISO 周的周一——兼容包装。 |
| [`weekYear`](#weekyear) | 顶层函数 | A | 返回可配置起始周的周编号年。 |
| [`isoWeekYear`](#isoweekyear) | 顶层函数 | A | 返回 ISO 周编号年——兼容包装。 |
| [`weekNumber`](#weeknumber) | 顶层函数 | A | 返回周编号年内的周号。 |
| [`isoWeekNumber`](#isoweeknumber) | 顶层函数 | A | 返回 ISO 周号——兼容包装。 |
| [`formatMonthDayRange`](#formatmonthdayrange) | 顶层函数 | A | 格式化 `start`–`end` 月/日范围字符串。 |
| [`leadingBlankDaysForMonth`](#leadingblankdaysformonth) | 顶层函数 | A | 返回日历网格中月开始的空白前导格。 |
| [`_dateOnly`](#_dateonly) | 顶层函数 | A | 从 `DateTime` 剥离时间分量。 |
| [`_differenceInCalendarDays`](#_differenceincalendardays) | 顶层函数 | A | 返回两个仅日期值之间的整日历天。 |

`grep -c 'Purpose:' lib/shared/utils/week_grouping.dart` 报告 16，与本文件全部十六个真实声明精确匹配。未发现错附或未文档化声明。每个声明都是 Tier A：文件自己的 `WeekGroup` 构造函数是模型构造函数（显式 Tier A 规则），`shared/` 下每个其他声明都是顶层函数，按一揽子规则无论大小都是 Tier A——包括两个私有辅助 `_dateOnly` 和 `_differenceInCalendarDays`，因为那条规则对私有顶层工具函数不加区分（只有"私有 `_buildXxx` 组件构建辅助"被点名为 Tier B，而这些不是组件构建器）。`WeekdayLabelWidth` 枚举不带 `Purpose:` 块，不单独计数。

## 文档

### `const WeekGroup({required this.year, required this.week, required this.start, required this.end, required this.items})` <a id="weekgroup-new"></a>
- **种类：** `WeekGroup<T>` 的 const 构造函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 17 行）
- **用途：** 创建携带周编号年/周、周开始/结束日期和落在其中的项的不可变周组值。
- **输入：** `year`、`week`、`start`、`end`、`items`（都必填）。
- **返回：** 新 `WeekGroup<T>`。
- **副作用：** 无。
- **算法：** 普通字段初始化 const 构造函数。
- **用法：** 只在 `groupByWeek` 内构建（见下面）；被渲染周页头加其分组项的周历史视图消费（Todo/体重/亲密历史列表）。
- **备注：** `items` 是普通可变 `List<T>`，即使构造函数是 `const`——`groupByWeek` 的调用方不应把返回组的 `items` 列表当作不可变（见 `groupByWeek` 的备注）。

### `List<WeekGroup<T>> groupByWeek<T>(List<T> items, DateTime Function(T item) getDate, {bool descending = true, int weekStartDay = DateTime.monday})` <a id="groupbyweek"></a>
- **种类：** 顶层泛型函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 31 行）
- **用途：** 把扁平项列表分桶为以配置周起始日键控的逐周组，按周排序并可选择反转。
- **输入：** `items`；`getDate` — 从每个项提取分组日期；`descending`（默认 `true`）；`weekStartDay`（默认周一；内部规范化）。
- **返回：** 按 `start` 排序、`descending` 时反转的 `List<WeekGroup<T>>`。
- **副作用：** 构建组时修改每个返回组的内部 `items` 列表（每组以单元素列表开始并经 `.add` 增长）。
- **算法：**
  1. 经 `normalizeWeekStartDay` 规范化 `weekStartDay`。
  2. 对每个项：计算其仅日期值（`_dateOnly(getDate(item))`），然后其周 `start`（`startOfWeek`）、周编号 `year`（`weekYear`）和 `week` 号（`weekNumber`），全部用规范化起始日。
  3. 把每个项按 `'$year-$week'` 键控进 `Map<String, WeekGroup<T>>`；首次见键时创建新组（`end = start + 6 days`），否则追加进既有组 `items`。
  4. 按 `start` 排序结果组；`descending` 时反转列表。
- **用法：**
  ```dart
  final groups = groupByWeek(
    records,
    (record) => record.datetime,
    weekStartDay: weekStartDay,
  );
  ```
  （`lib/features/weight/views/weight_page.dart`，周分组体重历史；相同模式用于 `lib/features/intimacy/views/intimacy_page.dart` 记录历史，两次，一个调用点带额外 `descending` 参数。）
- **备注：** 周键 `'$year-$week'` 用 `weekYear`，非 `start` 的日历年——两者在年边界附近不同（见 `weekYear` 的备注），因此即使一周的周一和其编号锚定日落在不同日历年，组也正确分桶。

### `List<WeekGroup<T>> groupByIsoWeek<T>(List<T> items, DateTime Function(T item) getDate, {bool descending = true})` <a id="groupbyisoweek"></a>
- **种类：** 顶层泛型函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 72 行）
- **用途：** 按严格 ISO 周（周一起始）分组项，无论应用配置的周起始日。
- **输入：** `items`、`getDate`、`descending`。
- **返回：** `List<WeekGroup<T>>`。
- **副作用：** 与 `groupByWeek` 相同（委托给它）。
- **算法：** `groupByWeek(items, getDate, descending: descending, weekStartDay: DateTime.monday)`。
- **用法：** 本仓库 `lib/` 或 `test/` 别处未找到调用点；按自己的文档注释作为兼容包装存在（"Kept as a compatibility wrapper for callers that still need ISO weeks"）。
- **备注：** 从当前调用图看是死代码，但按源码注释刻意保留——未检查外部/未来调用方前不要移除。

### `int normalizeWeekStartDay(int? weekday)` <a id="normalizeweekstartday"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 90 行）
- **用途：** 把可能无效或缺失的持久化工作日值钳制回有效 Dart 工作日，默认周一。
- **输入：** `weekday` — 可空，预期 Dart 工作日范围 1（周一）.. 7（周日）。
- **返回：** `int` — 有效时 `weekday` 本身，否则 `DateTime.monday`。
- **副作用：** 无。
- **算法：** `weekday == null || weekday < 1 || weekday > 7` → 返回 `DateTime.monday`；否则原样返回 `weekday`。
- **用法：**
  ```dart
  final normalized = normalizeWeekStartDay(weekday);
  state = state.copyWith(weekStartDay: normalized);
  TodoStorage.setWeekStartDay(normalized);
  ```
  （`lib/shared/providers/app_settings.dart`，`setWeekStartDay`——见 [app_settings.dart — setWeekStartDay](../providers/app_settings.md#setweekstartday)。）也本文件每个接受 `weekStartDay` 参数的函数内部调用。
- **备注：** 无效持久化值默认回周一而非抛出，使损坏或迁移前 `storage_config.json` 值不能崩溃日历渲染。

### `List<int> weekdaySequence(int weekStartDay)` <a id="weekdaysequence"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 104 行）
- **用途：** 按从配置周起始日开始的显示顺序返回七个 Dart 工作日值。
- **输入：** `weekStartDay`。
- **返回：** 从 `normalizeWeekStartDay(weekStartDay)` 开始的 7 个 Dart 工作日值（1..7）的 `List<int>`。
- **副作用：** 无。
- **算法：** `[for (offset in 0..6) ((start - 1 + offset) % 7) + 1]`，`start` 是规范化周起始日。
- **用法：**
  ```dart
  for (final weekday in weekdaySequence(weekStartDay))
    Expanded(
      child: Center(
        child: Text(localizedWeekdayLabel(weekday, l10n.localeName), ...),
      ),
    ),
  ```
  （`lib/features/intimacy/widgets/cycle_calendar.dart`，按配置顺序渲染日历星期页头行。）
- **备注：** 返回工作日值仍用 Dart 的周一=1..周日=7 编号——只有它们在列表中的*顺序*随 `weekStartDay` 变化，不是整数值。

### `String localizedWeekdayLabel(int weekday, String localeName, {WeekdayLabelWidth width = WeekdayLabelWidth.short})` <a id="localizedweekdaylabel"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 116 行）
- **用途：** 为给定 Dart 工作日值返回本地化星期标签（短 "Mon" 或长 "Monday" 风格），用 `Intl` 使每个模块共享相同翻译。
- **输入：** `weekday`；`localeName`（`Intl` 兼容语言区域名，如 `l10n.localeName`）；`width`（默认 `WeekdayLabelWidth.short`）。
- **返回：** `String`。
- **副作用：** 无。
- **算法：** 规范化 `weekday`；构造固定参考日期（`DateTime.utc(2024, 1, normalized)`——2024-01-01 是周一，因此 `1..7` 的 day-of-month 等于 Dart 工作日号）；用 `DateFormat.EEEE(localeName)`（长）或 `DateFormat.E(localeName)`（短）格式化。
- **用法：** 见上面 `weekdaySequence`——两者总是日历页头行一起使用。
- **备注：** 依赖 2024 年 1 月从周一开始的事实把裸工作日整数映射到 `Intl` 能格式化的真实日历日期；此技巧只因 `DateTime.utc(2024, 1, n)` 对 `1..7` 的 `n` 落在工作日 `n` 而工作。

### `DateTime startOfWeek(DateTime date, {int weekStartDay = DateTime.monday})` <a id="startofweek"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 134 行）
- **用途：** 按配置周起始日返回包含 `date` 的周的第一个日历日期（已剥时间）。
- **输入：** `date`；`weekStartDay`（默认周一；内部规范化）。
- **返回：** `DateTime` — 仅日期值（无时间分量），总是 `<= date`。
- **副作用：** 无。
- **算法：** `day = _dateOnly(date)`；`start = normalizeWeekStartDay(weekStartDay)`；返回 `day - ((day.weekday - start + 7) % 7)` 天。
- **用法：**
  ```dart
  DateTime _selectedWeekStart(int weekStartDay) =>
      startOfWeek(_selectedDate, weekStartDay: weekStartDay);
  ```
  （`lib/features/todo/views/todo_page.dart`，计算内联周历第一个可见日期。）也 `groupByWeek`、`weekYear` 和 `weekNumber` 内部使用。
- **备注：** 取模算术 `(day.weekday - start + 7) % 7` 正确处理 `1..7` 中每个 `weekStartDay`，包括 `date` 的工作日等于 `start` 的 case（返回 `date` 本身，偏移 `0`）。

### `DateTime startOfIsoWeek(DateTime date)` <a id="startofisoweek"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 145 行）
- **用途：** 返回开始包含 `date` 的 ISO 周的周一，无论应用配置的周起始日。
- **输入：** `date`。
- **返回：** `DateTime`。
- **副作用：** 无。
- **算法：** `startOfWeek(date, weekStartDay: DateTime.monday)`。
- **用法：** `lib/` 或 `test/` 别处未找到调用点；按自己的文档注释保留（"Kept for ISO-specific callers and tests"）。
- **备注：** 从当前调用图看是死代码，刻意保留。

### `int weekYear(DateTime date, {int weekStartDay = DateTime.monday})` <a id="weekyear"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 154 行）
- **用途：** 返回可配置起始周的周编号年——周开始后第 3 天的日历年，匹配 ISO"周所在年份包含其周四"的规则平移到配置起始日。
- **输入：** `date`；`weekStartDay`。
- **返回：** `int`。
- **副作用：** 无。
- **算法：** `startOfWeek(date, weekStartDay: weekStartDay).add(3 days).year`。
- **用法：** `groupByWeek`（构建周组映射键）和 `isoWeekYear` 内部调用。未找到直接外部调用点。
- **备注：** 对跨越年边界的周，这可以不同于 `date.year`——这正是四天周规则的要点（一周被分配给包含其大部分天的年份）。

### `int isoWeekYear(DateTime date)` <a id="isoweekyear"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 166 行）
- **用途：** 返回 `date` 的 ISO 周编号年（总是周一起始）。
- **输入：** `date`。
- **返回：** `int`。
- **副作用：** 无。
- **算法：** `weekYear(date, weekStartDay: DateTime.monday)`。
- **用法：** `lib/` 或 `test/` 别处未找到调用点；按自己的文档注释保留（"Kept for ISO-specific callers and tests"）。
- **备注：** 从当前调用图看是死代码，刻意保留。

### `int weekNumber(DateTime date, {int weekStartDay = DateTime.monday})` <a id="weeknumber"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 175 行）
- **用途：** 返回 `weekYear` 返回的周编号年内基于 1 的周号，用 1 月 4 日作为第一周锚（ISO 四天规则）。
- **输入：** `date`；`weekStartDay`。
- **返回：** `int`。
- **副作用：** 无。
- **算法：**
  1. `start = startOfWeek(date, weekStartDay: weekStartDay)`。
  2. `anchor = start + 3 days`（只用于经与 `weekYear` 相同逻辑派生编号年）。
  3. `firstWeekStart = startOfWeek(DateTime(anchor.year, 1, 4), weekStartDay: weekStartDay)`——包含 1 月 4 日的周总是第 1 周，按 ISO 四天规则。
  4. 返回 `_differenceInCalendarDays(firstWeekStart, start) ~/ 7 + 1`。
- **用法：** `groupByWeek`（周组映射键）和 `isoWeekNumber` 内部调用。未找到直接外部调用点。
- **备注：** 刻意用 UTC 规范化天差（经 `_differenceInCalendarDays`），使夏令时转换不能把天数偏移一小时并改变计算周号。

### `int isoWeekNumber(DateTime date)` <a id="isoweeknumber"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 190 行）
- **用途：** 返回 `date` 的 ISO 周号（总是周一起始）。
- **输入：** `date`。
- **返回：** `int`。
- **副作用：** 无。
- **算法：** `weekNumber(date, weekStartDay: DateTime.monday)`。
- **用法：** `lib/` 或 `test/` 别处未找到调用点；按自己的文档注释保留（"Kept for ISO-specific callers and tests"）。
- **备注：** 从当前调用图看是死代码，刻意保留。

### `String formatMonthDayRange(DateTime start, DateTime end, {String? localeName})` <a id="formatmonthdayrange"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 199 行）
- **用途：** 把一周的 `start`–`end` 日期格式化为语言区域感知月/日范围字符串（如周页头 "1/6-1/12"）。
- **输入：** `start`、`end`；`localeName`（可选；省略时 `Intl` 用其默认语言区域）。
- **返回：** `String` — `'<formatted start>-<formatted end>'`。
- **副作用：** 无。
- **算法：** `DateFormat.Md(localeName)`，应用于 `start` 和 `end` 两者，用 `-` 连接。
- **用法：**
  ```dart
  formatMonthDayRange(group.start, group.end, localeName: l10n.localeName),
  ```
  （`lib/features/weight/views/weight_page.dart`，周历史组页头；相同模式用于 `intimacy_page.dart`。）
- **备注：** 用 `DateFormat.Md`，其月/日顺序遵循给定语言区域（如英语 `M/d` 对其他语言是语言区域特定顺序），因此此字符串不能跨语言区域朴素拼接。

### `int leadingBlankDaysForMonth(DateTime date, {int weekStartDay = DateTime.monday})` <a id="leadingblankdaysformonth"></a>
- **种类：** 顶层函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 209 行）
- **用途：** 按配置周起始日返回月网格日历在第 1 天前需要多少个空前导格。
- **输入：** `date`（目标月内任何日期）；`weekStartDay`。
- **返回：** `0..6` 中的 `int`。
- **副作用：** 无。
- **算法：** `first = DateTime(date.year, date.month, 1)`；`start = normalizeWeekStartDay(weekStartDay)`；返回 `(first.weekday - start + 7) % 7`。
- **用法：**
  ```dart
  final leadingBlanks = leadingBlankDaysForMonth(viewMonth, weekStartDay: weekStartDay);
  ```
  （`lib/shared/widgets/app_date_picker.dart`，月网格布局；相同模式用于 `lib/features/intimacy/widgets/cycle_calendar.dart` 和 `lib/features/todo/views/todo_page.dart` 自己的月网格日历。）
- **备注：** 与 `startOfWeek` 相同的取模技巧，应用于月第一天而非任意日期。

### `DateTime _dateOnly(DateTime date)` <a id="_dateonly"></a>
- **种类：** 顶层私有函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 223 行）
- **用途：** 从 `DateTime` 剥离日内时间分量，保持本地日期语义。
- **输入：** `date`。
- **返回：** `DateTime` — `DateTime(date.year, date.month, date.day)`。
- **副作用：** 无。
- **算法：** 直接构造函数调用丢弃时/分/秒/毫秒/微秒。
- **用法：** `groupByWeek` 和 `startOfWeek` 调用，在做工作日算术前规范化输入日期。
- **备注：** 保持本地日期语义（非 UTC）——与 `_differenceInCalendarDays` 配对，后者为避开 DST 问题在 UTC 做内部比较，同时仍从本地仅日期值开始。

### `int _differenceInCalendarDays(DateTime start, DateTime end)` <a id="_differenceincalendardays"></a>
- **种类：** 顶层私有函数
- **来源：** `lib/shared/utils/week_grouping.dart`（第 230 行）
- **用途：** 返回两个仅日期值之间的整日历天数，免疫夏令时引起的小时偏移。
- **输入：** `start`、`end`（预期已是仅日期，如经 `_dateOnly`/`startOfWeek`）。
- **返回：** `int` — `end - start` 的天数。
- **副作用：** 无。
- **算法：** 把两个日期重建为 `DateTime.utc(year, month, day)`（丢弃任何本地时区/DST 偏移），然后取 `.difference(...).inDays`。
- **用法：** 只被 `weekNumber` 调用，计数第一周锚与目标周开始之间的天数。
- **备注：** 在这里用 UTC（而非环境本地 `DateTime`）正是让天数对落在 `start` 和 `end` 之间的夏令时转换稳健的东西。

# lib/features/todo/models/task.dart

Todo 功能的数据模型：`TaskType`/`RecurrenceType` 枚举、`TaskRecurrence`（一次性任务完成后如何重复）、`SubTask`、`Task`（每日模板和一次性任务共享这一个类），以及两个逐日期日志——`DailyCompletionLog`（任务/子任务完成，按并集合并）和 `DailyScoreLog`/`DailyScoreEntry`（-5..5 全天评分，按最后写入者胜出合并）。这些类型的概念级描述见 [Todo](../../../../features/todo.md)，其精确持久化 JSON 形态见 [数据格式](../../../../data-formats.md#todo--todo_datajson)。由 [`TodoStorage`](../services/todo_storage.md) 在 `todo_data.json` 中持久化和加载，并由 `sync_merge.dart` 的 `mergeTodoData` 跨设备合并——本页通篇引用的并集/LWW 规则见 [三方合并](../../../../algorithms/three-way-merge.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`TaskRecurrence._`](#taskrecurrence-_) | 私有 const 构造函数（`TaskRecurrence`） | A | 支撑三个命名重复工厂的基础构造函数。 |
| [`TaskRecurrence.everyNDays`](#taskrecurrence-everyndays) | const 构造函数（`TaskRecurrence`） | A | 创建每 N 天重复的重复规则。 |
| [`TaskRecurrence.monthlyOnDay`](#taskrecurrence-monthlyonday) | const 构造函数（`TaskRecurrence`） | A | 创建给定日每月重复的重复规则。 |
| [`TaskRecurrence.yearlyOnMonthDay`](#taskrecurrence-yearlyonmonthday) | const 构造函数（`TaskRecurrence`） | A | 创建给定月+日每年重复的重复规则。 |
| [`nextDate`](#nextdate) | 方法（`TaskRecurrence`） | A | 计算给定日期之后的下一次出现日期。 |
| [`TaskRecurrence.toJson`](#taskrecurrence-tojson) | 方法（`TaskRecurrence`） | A | 把此重复规则序列化为 JSON 兼容映射。 |
| [`TaskRecurrence.fromJson`](#taskrecurrence-fromjson) | 工厂构造函数（`TaskRecurrence`） | A | 从其持久化/同步 JSON 形态解析重复规则。 |
| [`SubTask`（构造函数）](#subtask-new) | 构造函数（`SubTask`） | A | 创建子任务，默认 `id`/`modifiedAt`。 |
| [`SubTask.copyWith`](#subtask-copywith) | 方法（`SubTask`） | A | 复制此子任务并替换所选字段。 |
| [`SubTask.toJson`](#subtask-tojson) | 方法（`SubTask`） | A | 把此子任务序列化为 JSON 兼容映射。 |
| [`SubTask.fromJson`](#subtask-fromjson) | 工厂构造函数（`SubTask`） | A | 从其持久化/同步 JSON 形态解析子任务。 |
| [`Task`（构造函数）](#task-new) | 构造函数（`Task`） | A | 创建任务，默认 `id`/`createdDate`/`modifiedAt`。 |
| [`Task.copyWith`](#task-copywith) | 方法（`Task`） | A | 复制此任务并替换或清除所选字段。 |
| [`Task.toJson`](#task-tojson) | 方法（`Task`） | A | 把此任务序列化为 JSON 兼容映射。 |
| [`Task.fromJson`](#task-fromjson) | 工厂构造函数（`Task`） | A | 从其持久化/同步 JSON 形态解析任务。 |
| [`DailyCompletionLog`（构造函数）](#dailycompletionlog-new) | 构造函数（`DailyCompletionLog`） | A | 创建空完成日志。 |
| [`dateKey`](#datekey) | 静态方法（`DailyCompletionLog`） | A | 把日期格式化为两个日志使用的 `yyyy-MM-dd` 键。 |
| [`isCompleted`](#iscompleted) | 方法（`DailyCompletionLog`） | A | 检查每日任务在某日期是否完成。 |
| [`toggle`](#toggle) | 方法（`DailyCompletionLog`） | A | 翻转每日任务在某日期的完成状态。 |
| [`completedIds`](#completedids) | 方法（`DailyCompletionLog`） | A | 返回某日期所有已完成任务 ID。 |
| [`isSubtaskCompleted`](#issubtaskcompleted) | 方法（`DailyCompletionLog`） | A | 检查子任务在某日期是否完成。 |
| [`toggleSubtask`](#togglesubtask) | 方法（`DailyCompletionLog`） | A | 翻转子任务在某日期的完成状态。 |
| [`setSubtasksCompleted`](#setsubtaskscompleted) | 方法（`DailyCompletionLog`） | A | 批量把多个子任务 ID 在某日期设为完成/未完成。 |
| [`completedSubtaskIds`](#completedsubtaskids) | 方法（`DailyCompletionLog`） | A | 返回某日期所有已完成子任务 ID。 |
| [`DailyCompletionLog.toJson`](#dailycompletionlog-tojson) | 方法（`DailyCompletionLog`） | A | 把两个映射序列化为其持久化形态。 |
| [`DailyCompletionLog.fromJson`](#dailycompletionlog-fromjson) | 工厂构造函数（`DailyCompletionLog`） | A | 解析完成日志，支持遗留扁平格式。 |
| [`DailyCompletionLog.merge`](#dailycompletionlog-merge) | 工厂构造函数（`DailyCompletionLog`） | A | 跨所有日期并集合并两个完成日志。 |
| [`DailyScoreEntry`（构造函数）](#dailyscoreentry-new) | 构造函数（`DailyScoreEntry`） | A | 创建评分条目，钳制评分。 |
| [`DailyScoreEntry.toJson`](#dailyscoreentry-tojson) | 方法（`DailyScoreEntry`） | A | 把此评分条目序列化为 JSON 兼容映射。 |
| [`DailyScoreEntry.fromJson`](#dailyscoreentry-fromjson) | 工厂构造函数（`DailyScoreEntry`） | A | 从其持久化/同步 JSON 形态解析评分条目。 |
| [`DailyScoreLog`（构造函数）](#dailyscorelog-new) | 构造函数（`DailyScoreLog`） | A | 创建空每日评分日志。 |
| [`normalizeScore`](#normalizescore) | 静态方法（`DailyScoreLog`） | A | 把原始评分钳制进受支持的 -5..5 范围。 |
| `DailyScoreLog.isEmpty` | getter（`DailyScoreLog`） | B | 此日志是否无显式评分条目。 |
| [`scoreFor`](#scorefor) | 方法（`DailyScoreLog`） | A | 读取某天的评分，默认 0。 |
| [`setScore`](#setscore) | 方法（`DailyScoreLog`） | A | 存储某天的评分。 |
| [`DailyScoreLog.toJson`](#dailyscorelog-tojson) | 方法（`DailyScoreLog`） | A | 序列化评分映射，按日期键排序。 |
| [`DailyScoreLog.fromJson`](#dailyscorelog-fromjson) | 工厂构造函数（`DailyScoreLog`） | A | 解析评分日志，支持遗留数字格式。 |
| [`DailyScoreLog.merge`](#dailyscorelog-merge) | 工厂构造函数（`DailyScoreLog`） | A | 逐日期最后写入者胜出合并两个评分日志。 |

`grep -c 'Purpose:' lib/features/todo/models/task.dart` 报告 38，与上面列出的全部三十八个真实声明精确匹配。未发现错附文档注释——每个 `/// Purpose:` 块都恰好位于其文档化的真实构造函数/方法/工厂正上方。也不存在未文档化真实声明；文件顶部的 `TaskType` 和 `RecurrenceType` 枚举声明不带 `Purpose:` 块并正确排除在上表之外，因为它们声明固定值集合而非行为（与本文档集别处普通类型声明相同的处理）。Tier 划分：37 个 Tier A / 1 个 Tier B。唯一 Tier B 行是 `DailyScoreLog.isEmpty`，无分支或参数的平凡单行 getter（`_scores.isEmpty`）。每个其他声明都是 Tier A：所有构造函数/`toJson`/`fromJson`/`copyWith`/`merge` 工厂都属于显式模型 Tier A 规则，`DailyCompletionLog`/`DailyScoreLog` 上剩余的查询/修改方法（`dateKey`、`isCompleted`、`toggle`、`completedIds`、`isSubtaskCompleted`、`toggleSubtask`、`setSubtasksCompleted`、`completedSubtaskIds`、`normalizeScore`、`scoreFor`、`setScore`）编码了这两个数据模型核心的真实逐日期映射查找/修改逻辑（不是普通字段转发），因此归为 Tier A 而非平凡访问器。

## 文档

### `const TaskRecurrence._({required this.type, this.intervalDays = 0, this.dayOfMonth = 0, this.monthOfYear = 0})` <a id="taskrecurrence-_"></a>
- **种类：** `TaskRecurrence` 的私有 const 构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 25 行）
- **用途：** 构建带显式 `type` 加全部三个可能参数字段的 `TaskRecurrence` 的基础构造函数；仅内部。
- **输入：** `type`（必填）；`intervalDays`/`dayOfMonth`/`monthOfYear`（各默认 0）。
- **返回：** 新 `TaskRecurrence`。
- **副作用：** 无。
- **算法：** 普通 const 字段初始化构造函数。下面三个命名构造函数（和 `fromJson`）是它唯一调用方，各提供固定 `type` 和只与该重复种类相关的字段。
- **用法：** `TaskRecurrence._(type: RecurrenceType.everyNDays, intervalDays: days)`——只从本文件内调用，被 `everyNDays`/`monthlyOnDay`/`yearlyOnMonthDay`（第 38、46、54-58 行）和 `fromJson`（第 107-112 行）调用。
- **备注：** 因为它是私有的，`TaskRecurrence` 只能经三个命名工厂之一或 `fromJson` 构建——从文件外没有构造 `type` 与其填充字段不匹配的方式。

### `const TaskRecurrence.everyNDays(int days)` <a id="taskrecurrence-everyndays"></a>
- **种类：** `TaskRecurrence` 的 const 构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 37 行）
- **用途：** 创建完成后每 `days` 天重复的重复规则。
- **输入：** `days` — 天间隔。
- **返回：** `type = RecurrenceType.everyNDays` 的新 `TaskRecurrence`。
- **副作用：** 无。
- **算法：** 转发给 `TaskRecurrence._(type: RecurrenceType.everyNDays, intervalDays: days)`。
- **用法：**
  ```dart
  RecurrenceType.everyNDays => TaskRecurrence.everyNDays(_intervalDays),
  ```
  （`lib/features/todo/widgets/recurrence_picker.dart`，第 276-278 行，重复选择器的保存处理器）。
- **备注：** 此变体的 `dayOfMonth`/`monthOfYear` 保持 0 默认；`nextDate` 对 `everyNDays` 根本不读它们。

### `const TaskRecurrence.monthlyOnDay(int day)` <a id="taskrecurrence-monthlyonday"></a>
- **种类：** `TaskRecurrence` 的 const 构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 45 行）
- **用途：** 创建第 `day` 天每月重复的重复规则。
- **输入：** `day` — 月内日（1-31）。
- **返回：** `type = RecurrenceType.monthlyOnDay` 的新 `TaskRecurrence`。
- **副作用：** 无。
- **算法：** 转发给 `TaskRecurrence._(type: RecurrenceType.monthlyOnDay, dayOfMonth: day)`。
- **用法：**
  ```dart
  RecurrenceType.monthlyOnDay => TaskRecurrence.monthlyOnDay(
    _dayOfMonth,
  ),
  ```
  （`recurrence_picker.dart`，第 279-281 行）。
- **备注：** 越界 `day` 不在这里验证；钳制只在稍后的 `nextDate` 内对照目标月实际长度发生。

### `const TaskRecurrence.yearlyOnMonthDay(int month, int day)` <a id="taskrecurrence-yearlyonmonthday"></a>
- **种类：** `TaskRecurrence` 的 const 构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 53 行）
- **用途：** 创建 `month`/`day` 每年重复的重复规则。
- **输入：** `month`（1-12）、`day`（1-31）。
- **返回：** `type = RecurrenceType.yearlyOnMonthDay` 的新 `TaskRecurrence`。
- **副作用：** 无。
- **算法：** 转发给 `TaskRecurrence._(type: RecurrenceType.yearlyOnMonthDay, monthOfYear: month, dayOfMonth: day)`。
- **用法：**
  ```dart
  RecurrenceType.yearlyOnMonthDay =>
    TaskRecurrence.yearlyOnMonthDay(
      _monthOfYear,
      _dayOfMonth,
    ),
  ```
  （`recurrence_picker.dart`，第 282-286 行）。
- **备注：** 与 `monthlyOnDay` 相同——日/月钳制发生在 `nextDate`，不在这里。

### `DateTime nextDate(DateTime from)` <a id="nextdate"></a>
- **种类：** `TaskRecurrence` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 66 行）
- **用途：** 按此重复规则的类型计算 `from` 之后的下一次出现日期。
- **输入：** `from` — 刚完成出现被安排/创建的日期。
- **返回：** `DateTime` — 下一次出现日期。
- **副作用：** 无。
- **算法：**
  1. `everyNDays`：`from.add(Duration(days: intervalDays))`。
  2. `monthlyOnDay`：前进到下个月（跨过月 12 滚动年份），经 `DateTime(year, month + 1, 0).day` 计算该月最后一天，然后把 `dayOfMonth` 钳制进 `[1, lastDay]`。
  3. `yearlyOnMonthDay`：前进到 `from.year + 1`，以同样方式计算该年中 `monthOfYear` 的最后一天，以同样方式钳制 `dayOfMonth`（处理非闰目标年的 2 月 29 日 → 2 月 28 日）。
- **用法：**
  ```dart
  final nextDate = completedTask.recurrence!.nextDate(
    completedTask.scheduledDate ?? completedTask.createdDate,
  );
  ```
  （`lib/features/todo/views/todo_page.dart`，第 895-897 行，`_offerNextOccurrence`）。
- **备注：** `monthlyOnDay` 总是从 `from` 前进恰好一个月、`yearlyOnMonthDay` 恰好一年——没有"今天之后的下一次出现"搜索。调用方应传入刚完成任务被安排的日期，不是任意参考日期。

### `Map<String, dynamic> toJson()` <a id="taskrecurrence-tojson"></a>
- **种类：** `TaskRecurrence` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 94 行）
- **用途：** 把此重复规则序列化进其持久化/同步 JSON 形态。
- **输入：** 无。
- **返回：** 带 `type`（枚举名）、`intervalDays`、`dayOfMonth`、`monthOfYear` 的 `Map<String, dynamic>`。
- **副作用：** 无。
- **算法：** 普通映射字面量——无论 `type` 总是写全部三个数字字段。
- **用法：** `Task.toJson` 内的 `'recurrence': recurrence?.toJson()`（第 297 行）。
- **备注：** 与 `Task.toJson` 不同，这从无条件省略字段——序列化的 `everyNDays` 重复规则仍在 JSON 中携带 `dayOfMonth: 0, monthOfYear: 0`。

### `factory TaskRecurrence.fromJson(Map<String, dynamic> json)` <a id="taskrecurrence-fromjson"></a>
- **种类：** `TaskRecurrence` 的工厂构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 106 行）
- **用途：** 从其持久化/同步 JSON 形态重建 `TaskRecurrence`。
- **输入：** `json`。
- **返回：** 新 `TaskRecurrence`。
- **副作用：** 无。
- **算法：** `RecurrenceType.values.byName(json['type'] as String)`，然后每个数字字段经 `as int? ?? 0` 默认 0，全部传入私有 `_` 构造函数。
- **用法：** `Task.fromJson` 内的 `TaskRecurrence.fromJson(json['recurrence'] as Map<String, dynamic>)`（第 337-339 行）。
- **备注：** `type` 不匹配三个枚举名之一时 `byName` 抛错——损坏/外来 `type` 字符串不被静默容忍（它向上传播并按 `Task.fromJson` 下面备注浮出为加载错误）。

### `SubTask({String? id, required this.title, this.isCompleted = false, DateTime? modifiedAt})` <a id="subtask-new"></a>
- **种类：** `SubTask` 的构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 126 行）
- **用途：** 创建子任务，省略时生成 `id`/`modifiedAt`。
- **输入：** `title`（必填）；`isCompleted`（默认 false）；可选 `id`、`modifiedAt`。
- **返回：** 新 `SubTask`。
- **副作用：** 无直接（`Uuid().v4()`/`DateTime.now()` 各产生新鲜值）。
- **算法：** `id ??= Uuid().v4()`；`modifiedAt ??= DateTime.now().toUtc()`。
- **用法：** `subtasks: subtaskTitles.map((t) => SubTask(title: t)).toList()`（`lib/features/todo/widgets/add_task_dialog.dart`，第 618 行）；构建下一次出现任务时也 `SubTask(title: s.title)`（`todo_page.dart`，第 904 行）。
- **备注：** 与 `Task` 不同，`SubTask` 没有 `createdDate` 字段——只有 `id`/`modifiedAt` 获得自动生成默认。

### `SubTask copyWith({String? title, bool? isCompleted, DateTime? modifiedAt})` <a id="subtask-copywith"></a>
- **种类：** `SubTask` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 139 行）
- **用途：** 产生此子任务的修改副本，保持相同 `id`。
- **输入：** 替换 `title`/`isCompleted`/`modifiedAt`。
- **返回：** 与 `this` 相同 `id` 的新 `SubTask`。
- **副作用：** 无（`modifiedAt` 除非显式传入，总是在新实例上重新生成）。
- **算法：** 省略时 `title`/`isCompleted` 回退 `this.x`；`modifiedAt` 总是经 `?? DateTime.now().toUtc()` 重新生成——绝不从 `this` 继承，因此每次 `copyWith` 调用都 bump 修改时间（与 `Task.copyWith` 相同约定）。
- **用法：**
  ```dart
  _subtasks[index] = _subtasks[index].copyWith(title: newTitle);
  ```
  （`lib/features/todo/widgets/edit_task_dialog.dart`，第 593 行）；也 `s.copyWith(isCompleted: nowCompleting)`（`todo_page.dart`，第 854 行）和 `s.copyWith(isCompleted: subDone)`（`todo_page.dart`，第 373 行，把逐日期子任务完成映射到每日模板的显示副本上）。
- **备注：** 与 `Task.copyWith` 不同，这里没有 `clearX` 模式——除自动生成的字段外 `SubTask` 没有任何字段以需要显式清除的方式可空。

### `Map<String, dynamic> toJson()` <a id="subtask-tojson"></a>
- **种类：** `SubTask` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 153 行）
- **用途：** 把此子任务序列化进其持久化/同步 JSON 形态。
- **输入：** 无。
- **返回：** 带 `id`、`title`、`isCompleted`、`modifiedAt`（ISO 8601）的 `Map<String, dynamic>`。
- **副作用：** 无。
- **算法：** 普通映射字面量，无条件省略。
- **用法：** `Task.toJson` 内的 `subtasks.map((s) => s.toJson()).toList()`（第 290 行）。
- **备注：** 无。

### `factory SubTask.fromJson(Map<String, dynamic> json)` <a id="subtask-fromjson"></a>
- **种类：** `SubTask` 的工厂构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 165 行）
- **用途：** 从其持久化/同步 JSON 形态重建 `SubTask`。
- **输入：** `json` — 预期至少包含 `id`、`title`。
- **返回：** 新 `SubTask`。
- **副作用：** 无。
- **算法：** `id`/`title` 直接转换（缺失/类型错误则抛）；`isCompleted` 默认 `false`；`modifiedAt` 存在时经 `DateTime.parse` 解析，否则回退 Unix 纪元（`DateTime.fromMillisecondsSinceEpoch(0)`）而非"现在"。
- **用法：**
  ```dart
  subtasks:
      (json['subtasks'] as List<dynamic>?)
          ?.map((s) => SubTask.fromJson(s as Map<String, dynamic>))
          .toList() ??
      const [],
  ```
  （`Task.fromJson`，第 316-320 行）。
- **备注：** 缺失/null `modifiedAt` 读作 Unix 纪元（可能的最旧），不是"现在"——因此跟踪 `modifiedAt` 前持久化的子任务记录与有真实时间戳的对等方比较时总是输掉最后写入者胜出。

### `Task({String? id, required this.title, this.note, this.emoji, required this.type, this.isCompleted = false, this.reminderTime, this.subtasks = const [], DateTime? createdDate, this.completedDate, this.scheduledDate, this.deletedDate, this.startDate, this.dueDate, this.recurrence, DateTime? modifiedAt})` <a id="task-new"></a>
- **种类：** `Task` 的构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 211 行）
- **用途：** 创建任务（每日模板或一次性），省略时生成 `id`/`createdDate`/`modifiedAt`。
- **输入：** `title`、`type`（必填）；覆盖每日模板用法（`startDate`、`deletedDate`）和一次性任务用法（`scheduledDate`、`dueDate`、`recurrence`）的许多可选字段。
- **返回：** 新 `Task`。
- **副作用：** 无直接。
- **算法：** `id ??= Uuid().v4()`；`createdDate ??= DateTime.now()`（本地时间）；`modifiedAt ??= DateTime.now().toUtc()`。
- **用法：**
  ```dart
  final task = Task(
    title: title,
    note: note.isEmpty ? null : note,
    emoji: _selectedEmoji,
    type: _selectedType,
    reminderTime: reminder,
    subtasks: subtaskTitles.map((t) => SubTask(title: t)).toList(),
    scheduledDate: _selectedType != TaskType.daily
        ? _scheduledDate ?? widget.defaultDate ?? DateTime.now()
        : null,
    startDate: _selectedType == TaskType.daily
        ? widget.defaultDate ?? DateTime.now()
        : null,
    dueDate: _selectedType != TaskType.daily ? _dueDate : null,
    recurrence: _selectedType != TaskType.daily ? _recurrence : null,
  );
  ```
  （`add_task_dialog.dart`，第 612-627 行，创建任务保存处理器）。
- **备注：** `createdDate` 默认本地时间而 `modifiedAt` 总是默认 UTC——与本仓库其他模型构造函数相同的本地/UTC 不对称；同步相关比较必须用 `modifiedAt`，绝不用 `createdDate`。

### `Task copyWith({String? title, String? note, bool clearNote = false, String? emoji, TaskType? type, bool? isCompleted, DateTime? reminderTime, List<SubTask>? subtasks, DateTime? completedDate, DateTime? scheduledDate, DateTime? deletedDate, bool clearDeletedDate = false, DateTime? startDate, DateTime? dueDate, bool clearDueDate = false, TaskRecurrence? recurrence, bool clearRecurrence = false, DateTime? modifiedAt})` <a id="task-copywith"></a>
- **种类：** `Task` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 237 行）
- **用途：** 产生此任务的修改副本，经显式 `clearXxx` 标志而非传 `null` 清除可空字段。
- **输入：** 大多数字段的替换值；`clearNote`/`clearDeletedDate`/`clearDueDate`/`clearRecurrence` 布尔。
- **返回：** 与 `this` 相同 `id` 和 `createdDate` 的新 `Task`。
- **副作用：** 无（除非显式传入，`modifiedAt` 总是重新生成）。
- **算法：** 对 `note`/`deletedDate`/`dueDate`/`recurrence`：`clearX ? null : (x ?? this.x)`。对 `scheduledDate`/`startDate`/`completedDate`：普通 `x ?? this.x`，**无**清除标志——仅经 `copyWith` 无法把这三个置 null。`id` 和 `createdDate` 根本不是参数；函数体的 `id: id` / `createdDate: createdDate` 隐式解析为 `this.id`/`this.createdDate`（实例方法内的非限定字段访问），因此两者都永远不能经 `copyWith` 改变。
- **用法：**
  ```dart
  _dailyTemplates[index] = t.copyWith(deletedDate: _selectedDate);
  ```
  （`todo_page.dart`，第 946 行，软删除每日模板）和
  ```dart
  return needsCopy
      ? t.copyWith(isCompleted: done, subtasks: mappedSubs)
      : t;
  ```
  （`todo_page.dart`，第 378 行，`_dailyForDate` 把逐日期完成映射到模板显示副本上）。
- **备注：** 因为 `completedDate` 没有 `clearX` 标志，`_toggleTask` 的一次性任务取消完成路径（`todo_page.dart`，第 857-873 行）直接构造原始 `Task(...)` 而非调用 `copyWith`，正为能设 `completedDate: null`。

### `Map<String, dynamic> toJson()` <a id="task-tojson"></a>
- **种类：** `Task` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 282 行）
- **用途：** 把此任务序列化进其持久化/同步 JSON 形态。
- **输入：** 无。
- **返回：** 每个字段总是作为键存在的 `Map<String, dynamic>`（可空字段写为 JSON `null` 而非省略）。
- **副作用：** 无。
- **算法：** 普通映射字面量；`subtasks.map((s) => s.toJson())`、每个 `DateTime` 字段 ISO 8601、`recurrence?.toJson()`。
- **用法：** `TodoData.toJson` 内的 `dailyTemplates.map((t) => t.toJson()).toList()`（`lib/features/todo/services/todo_storage.dart`，第 55 行）；也把 `serialize: (x) => jsonEncode(x.toJson())` 传给冲突差异显示的 `mergeRecords<Task>`（`lib/shared/services/sync_merge.dart`，第 238、249 行）。
- **备注：** 与 `WeightRecord.toJson` 不同，这里的可空字段绝不省略——序列化形态总是有稳定、完整键集，字段缺席处是 `null` 值。

### `factory Task.fromJson(Map<String, dynamic> json)` <a id="task-fromjson"></a>
- **种类：** `Task` 的工厂构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 306 行）
- **用途：** 从其持久化/同步 JSON 形态重建 `Task`。
- **输入：** `json`。
- **返回：** 新 `Task`。
- **副作用：** 无。
- **算法：** `id`/`title` 直接转换（缺失则抛）；`type` 经 `TaskType.values.byName`；每个 `DateTime?` 字段存在时经 `DateTime.parse` 解析否则 `null`；`subtasks` 经 `SubTask.fromJson` 映射，缺席默认 `const []`；`recurrence` 存在时经 `TaskRecurrence.fromJson`；`modifiedAt` 存在时解析否则 Unix 纪元。
- **用法：**
  ```dart
  dailyTemplates: (json['dailyTemplates'] as List<dynamic>)
      .map((t) => Task.fromJson(t as Map<String, dynamic>))
      .toList(),
  ```
  （`TodoData.fromJson`，`todo_storage.dart`，第 81-83 行；`oneTimeTasks` 第 84-86 行遵循相同模式）。
- **备注：** `type` 用 `byName`，在无法识别字符串时抛——与 `TodoStorage.load()` 的 try/catch 结合，带损坏 `type` 值的任务把整个文件加载变成抛出的 `TodoStorageException`，而不是静默丢弃那一条记录。

### `DailyCompletionLog()` <a id="dailycompletionlog-new"></a>
- **种类：** `DailyCompletionLog` 的构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 359 行）
- **用途：** 创建空完成日志。
- **输入：** 无。
- **返回：** 两个内部映射都空的新 `DailyCompletionLog`。
- **副作用：** 无。
- **算法：** 平凡——依赖字段初始化器 `_log = {}` / `_subLog = {}`。
- **用法：** 作为 `json['dailyLog']` 缺席时加载器的回退 `DailyCompletionLog()`（`TodoData.fromJson`，`todo_storage.dart`，第 91 行），加载失败时 `ReminderService.instance.updateData(..., dailyLog: DailyCompletionLog())`（`todo_page.dart`，第 101 行）。
- **备注：** 无。

### `static String dateKey(DateTime date)` <a id="datekey"></a>
- **种类：** `DailyCompletionLog` 的静态方法
- **来源：** `lib/features/todo/models/task.dart`（第 366 行）
- **用途：** 把 `DateTime` 格式化为完成日志和评分日志都使用的 `yyyy-MM-dd` 字符串键。
- **输入：** `date`。
- **返回：** `String`，月/日零填充、年不填充。
- **副作用：** 无。
- **算法：** `'${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}'`——直接使用 `date` 自己的年/月/日分量，无时区转换，因此键反映 `date` 已表达的任何时区。
- **用法：** 本文件内部通篇使用（`isCompleted`、`toggle`、`DailyScoreLog.scoreFor`/`setScore` 等），外部由 `lib/shared/services/local_api_server.dart`（第 220、430、442、453、1013-1042 行）以相同日期格式键控其 REST 响应。
- **备注：** 年不零填充，因此四位数年外不是严格可排序的 ISO 日期——实践中无关紧要，但 `local_api_server.dart:1021` 的字符串比较（`dateKey.compareTo(...)`）只因实践中年都是 4 位才正确工作。

### `bool isCompleted(DateTime date, String taskId)` <a id="iscompleted"></a>
- **种类：** `DailyCompletionLog` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 374 行）
- **用途：** 检查特定每日任务在给定日期是否标记完成。
- **输入：** `date`、`taskId`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** `_log[dateKey(date)]?.contains(taskId) ?? false`——缺席日期条目读作"未完成"而非抛错。
- **用法：**
  ```dart
  final done = _dailyLog.isCompleted(_selectedDate, t.id);
  ```
  （`todo_page.dart`，第 368 行，`_dailyForDate`；也第 703、743、833 行）。
- **备注：** 无。

### `void toggle(DateTime date, String taskId)` <a id="toggle"></a>
- **种类：** `DailyCompletionLog` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 383 行）
- **用途：** 翻转每日任务在给定日期的完成状态。
- **输入：** `date`、`taskId`。
- **返回：** 无。
- **副作用：** 原地修改 `_log`——缺席时创建日期条目，然后添加/移除 `taskId`。
- **算法：** `_log.putIfAbsent(key, () => {})`；集合已含 `taskId` 则移除，否则添加。
- **用法：** `_dailyLog.toggle(_selectedDate, task.id);`（`todo_page.dart`，第 831 行，`_toggleTask` 的每日任务分支）。
- **备注：** 切换不记录自己的逐条目时间戳——日期+任务对的完成状态没有 `modifiedAt`；只有 `DailyCompletionLog.merge` 中的并集合并调和两个日志（见 [三方合并](../../../../algorithms/three-way-merge.md)）。

### `Set<String> completedIds(DateTime date)` <a id="completedids"></a>
- **种类：** `DailyCompletionLog` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 398 行）
- **用途：** 返回某日期完整已完成任务 ID 集合。
- **输入：** `date`。
- **返回：** `Set<String>`，日期无条目时为空。
- **副作用：** 无。
- **算法：** `_log[dateKey(date)] ?? {}`。
- **用法：** 仓库别处未找到调用点——UI 和 REST API 都经 `isCompleted` 逐任务查询，而非经此方法批量读取。
- **备注：** 日期条目存在时，这返回内部 `Set` 的活引用（非副本）——修改返回集合的调用方会损坏日志内部状态。

### `bool isSubtaskCompleted(DateTime date, String subtaskId)` <a id="issubtaskcompleted"></a>
- **种类：** `DailyCompletionLog` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 407 行）
- **用途：** 检查特定子任务在给定日期是否标记完成。
- **输入：** `date`、`subtaskId`。
- **返回：** `bool`。
- **副作用：** 无。
- **算法：** 与 `isCompleted` 相同模式，针对 `_subLog` 而非 `_log`。
- **用法：** `final subDone = _dailyLog.isSubtaskCompleted(_selectedDate, s.id);`（`todo_page.dart`，第 371 行）。
- **备注：** 与 `isCompleted` 相同的缺席条目读作 false 行为。

### `void toggleSubtask(DateTime date, String subtaskId)` <a id="togglesubtask"></a>
- **种类：** `DailyCompletionLog` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 416 行）
- **用途：** 翻转子任务在给定日期的完成状态。
- **输入：** `date`、`subtaskId`。
- **返回：** 无。
- **副作用：** 原地修改 `_subLog`。
- **算法：** 与 `toggle` 相同模式，针对 `_subLog` 而非 `_log`。
- **用法：** `_dailyLog.toggleSubtask(_selectedDate, subtask.id);`（`todo_page.dart`，第 966 行）。
- **备注：** 除 `toggle` 的外无。

### `void setSubtasksCompleted(DateTime date, Iterable<String> subtaskIds, bool completed)` <a id="setsubtaskscompleted"></a>
- **种类：** `DailyCompletionLog` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 431 行）
- **用途：** 单次调用批量把多个子任务 ID 设为某日期完成或未完成。
- **输入：** `date`、`subtaskIds`、`completed`。
- **返回：** 无。
- **副作用：** 修改 `_subLog[dateKey(date)]`。
- **算法：** `putIfAbsent` 日期集合，然后 `completed` 时 `addAll(subtaskIds)` 否则 `removeAll(subtaskIds)`。
- **用法：**
  ```dart
  _dailyLog.setSubtasksCompleted(
    _selectedDate,
    tpl.subtasks.map((s) => s.id),
    nowCompleted,
  );
  ```
  （`todo_page.dart`，第 840-844 行——父任务被切换时自动完成/取消完成每日模板的所有子任务）。
- **备注：** 与 `toggle`（单 ID 翻转）不同，这是直接集合，不是翻转——绝不碰 `subtaskIds` 外的 ID，重新应用相同 `completed` 值是空操作。

### `Set<String> completedSubtaskIds(DateTime date)` <a id="completedsubtaskids"></a>
- **种类：** `DailyCompletionLog` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 450 行）
- **用途：** 返回某日期完整已完子任务 ID 集合。
- **输入：** `date`。
- **返回：** `Set<String>`，日期无条目时为空。
- **副作用：** 无。
- **算法：** `_subLog[dateKey(date)] ?? {}`。
- **用法：** 仓库别处未找到调用点（镜像 `completedIds`）。
- **备注：** 与 `completedIds` 相同的活引用警告。

### `Map<String, dynamic> toJson()` <a id="dailycompletionlog-tojson"></a>
- **种类：** `DailyCompletionLog` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 458 行）
- **用途：** 把两个内部映射序列化进 `{"tasks": {...}, "subtasks": {...}}` 持久化形态。
- **输入：** 无。
- **返回：** `Map<String, dynamic>`。
- **副作用：** 无。
- **算法：** `_log.map((k, v) => MapEntry(k, v.toList()))`，`_subLog` 相同，包在 `'tasks'`/`'subtasks'` 键下。
- **用法：** `TodoData.toJson` 内的 `'dailyLog': dailyLog.toJson()`（`todo_storage.dart`，第 57 行）。
- **备注：** `Set` → `List` 转换意味着日期内持久化 ID 顺序反映 `Set` 的迭代顺序（实践中是插入顺序），不是排序顺序。

### `factory DailyCompletionLog.fromJson(Map<String, dynamic> json)` <a id="dailycompletionlog-fromjson"></a>
- **种类：** `DailyCompletionLog` 的工厂构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 468 行）
- **用途：** 解析完成日志，支持当前 `{tasks, subtasks}` 格式和遗留扁平映射格式。
- **输入：** `json`。
- **返回：** 新 `DailyCompletionLog`。
- **副作用：** 无。
- **算法：** `json` 有 `'tasks'` 键时从 `json['tasks']` 解析 `_log`、从 `json['subtasks']` 解析 `_subLog`（存在时，否则留空）；否则把整个 `json` 映射本身当作遗留扁平日期→taskIds 映射（仅任务日志，无子任务日志）。
- **用法：** `json['dailyLog'] != null ? DailyCompletionLog.fromJson(json['dailyLog'] as Map<String, dynamic>) : DailyCompletionLog()`（`TodoData.fromJson`，`todo_storage.dart`，第 87-91 行）。
- **备注：** 遗留格式分支意味着逐日期子任务跟踪存在前写的 `todo_data.json` 仍正确加载，`_subLog` 简单为空。

### `factory DailyCompletionLog.merge(DailyCompletionLog a, DailyCompletionLog b)` <a id="dailycompletionlog-merge"></a>
- **种类：** `DailyCompletionLog` 的工厂构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 501 行）
- **用途：** 跨所有日期并集合并两个完成日志，任务和子任务完成各自独立。
- **输入：** `a`、`b`。
- **返回：** 新 `DailyCompletionLog`。
- **副作用：** 无（纯）。
- **算法：**
  1. 并集两个 `_log` 的日期键；对每个日期，并集两边的已完成 ID 集合（`{...(a._log[date] ?? {}), ...(b._log[date] ?? {})}`）。
  2. 对 `_subLog` 独立重复相同并集。
- **用法：**
  ```dart
  final mergedLog = DailyCompletionLog.merge(local.dailyLog, remote.dailyLog);
  ```
  （`lib/shared/services/sync_merge.dart`，第 252 行）。完成状态为何按并集而非最后写入者胜出合并见 [三方合并](../../../../algorithms/three-way-merge.md)。
- **备注：** 任一边完成的子任务/任务合并后完成——同步永远不能"取消完成"任何东西；重新标记未完成的唯一方式是合并后新的本地 `toggle`。

### `DailyScoreEntry({required int score, DateTime? modifiedAt})` <a id="dailyscoreentry-new"></a>
- **种类：** `DailyScoreEntry` 的构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 527 行）
- **用途：** 创建评分条目，把 `score` 钳制进范围并默认 `modifiedAt`。
- **输入：** `score`（必填）；`modifiedAt`（可选）。
- **返回：** 新 `DailyScoreEntry`。
- **副作用：** 无。
- **算法：** `score = DailyScoreLog.normalizeScore(score)`（钳制到 -5..5）；`modifiedAt ??= DateTime.now().toUtc()`。
- **用法：** 只在本文件内部构造，被 `DailyScoreLog.setScore`（第 602 行）和 `DailyScoreEntry.fromJson`/`DailyScoreLog.fromJson` 的数字分支（第 548、633 行）——无外部调用方。
- **备注：** 无。

### `Map<String, dynamic> toJson()` <a id="dailyscoreentry-tojson"></a>
- **种类：** `DailyScoreEntry` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 536 行）
- **用途：** 把此评分条目序列化进其持久化/同步 JSON 形态。
- **输入：** 无。
- **返回：** 带 `score`、`modifiedAt`（ISO 8601）的 `Map<String, dynamic>`。
- **副作用：** 无。
- **算法：** 普通映射字面量。
- **用法：** `DailyScoreLog.toJson` 内的 `_scores[key]!.toJson()`（第 615 行）。
- **备注：** 无。

### `factory DailyScoreEntry.fromJson(Map<String, dynamic> json)` <a id="dailyscoreentry-fromjson"></a>
- **种类：** `DailyScoreEntry` 的工厂构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 541 行）
- **用途：** 从其持久化/同步 JSON 形态重建评分条目。
- **输入：** `json`。
- **返回：** 新 `DailyScoreEntry`。
- **副作用：** 无。
- **算法：** `score = rawScore is num ? rawScore.round() : 0`（接受 int 或 double，否则默认 0）；`modifiedAt` 存在时经 `DateTime.parse` 解析，否则 Unix 纪元。
- **用法：** 从 `DailyScoreLog.fromJson` 的 `Map` 值分支调用（第 627-629 行）。
- **备注：** 经主构造函数路由，因此越界存储 `score` 加载时仍经 `normalizeScore` 重新钳制。

### `DailyScoreLog()` <a id="dailyscorelog-new"></a>
- **种类：** `DailyScoreLog` 的构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 570 行）
- **用途：** 创建空每日评分日志。
- **输入：** 无。
- **返回：** `_scores` 空的新 `DailyScoreLog`。
- **副作用：** 无。
- **算法：** 平凡——依赖 `_scores = {}` 字段初始化器。
- **用法：** `dailyScores ?? DailyScoreLog()`——`TodoData` 自己的构造函数默认（`todo_storage.dart`，第 45 行）；也 `DailyScoreLog.fromJson`/`merge` 内的起点。
- **备注：** 经 `scoreFor` 缺失日期读作评分 0，即使 `_scores` 以完全为空开始（且能保持）。

### `static int normalizeScore(int score)` <a id="normalizescore"></a>
- **种类：** `DailyScoreLog` 的静态方法
- **来源：** `lib/features/todo/models/task.dart`（第 577 行）
- **用途：** 把原始评分钳制进受支持的 -5..5 范围。
- **输入：** `score`。
- **返回：** `minScore`（-5）和 `maxScore`（5）之间的 `int`。
- **副作用：** 无。
- **算法：** `score.clamp(minScore, maxScore).toInt()`。
- **用法：** `DailyScoreEntry` 自己构造函数内的 `DailyScoreLog.normalizeScore(score)`（第 528 行）——每个评分条目构造时都经此钳制，因此本文件外调用方从不需要直接调用它。
- **备注：** 显式 `.toInt()` 防 `clamp` 静态类型为 `num` 的返回值。

### `int scoreFor(DateTime date)` <a id="scorefor"></a>
- **种类：** `DailyScoreLog` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 592 行）
- **用途：** 读取某天的评分，无显式条目时默认 0。
- **输入：** `date`。
- **返回：** `int`。
- **副作用：** 无。
- **算法：** `_scores[DailyCompletionLog.dateKey(date)]?.score ?? 0`。
- **用法：** `final score = _dailyScores.scoreFor(_selectedDate);`（`todo_page.dart`，第 1249 行）；也 `widget.dailyScores.scoreFor(...)` 供给月度趋势图（第 1633 行）。
- **备注：** `?? 0` 默认正是让"无条目"和"显式评分 0"经此方法单独无法区分的东西——那个区分只对内部的 `setScore` 下面总是-创建-新条目行为重要。

### `void setScore(DateTime date, int score, {DateTime? modifiedAt})` <a id="setscore"></a>
- **种类：** `DailyScoreLog` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 596 行）
- **用途：** 存储（或覆盖）某天的评分。
- **输入：** `date`、`score`、可选 `modifiedAt`。
- **返回：** 无。
- **副作用：** 修改 `_scores[dateKey(date)]`。
- **算法：** `_scores[dateKey(date)] = DailyScoreEntry(score: score, modifiedAt: modifiedAt)`——总是用全新条目替换（绝不原地修改一个）；`DailyScoreEntry` 的构造函数钳制 `score`。
- **用法：**
  ```dart
  _dailyScores.setScore(
    _selectedDate,
    score,
    modifiedAt: DateTime.now().toUtc(),
  );
  ```
  （`todo_page.dart`，`_setDailyScore`，第 812-816 行）。
- **备注：** 因为显式零作为真实、带时间戳条目存储而非当作"清除"，故意重置为零仍经同步传播——见 [三方合并](../../../../algorithms/three-way-merge.md)。

### `Map<String, dynamic> toJson()` <a id="dailyscorelog-tojson"></a>
- **种类：** `DailyScoreLog` 的方法
- **来源：** `lib/features/todo/models/task.dart`（第 608 行）
- **用途：** 把评分映射序列化进其持久化形态，按日期键排序。
- **输入：** 无。
- **返回：** 以 `yyyy-MM-dd` 键控的 `Map<String, dynamic>`。
- **副作用：** 无。
- **算法：** 排序 `_scores.keys`，然后按该排序顺序构建 `{key: _scores[key]!.toJson()}`。
- **用法：** `TodoData.toJson` 内的 `if (!dailyScores.isEmpty) 'dailyScores': dailyScores.toJson()`（`todo_storage.dart`，第 58 行）。
- **备注：** 排序纯粹为持久化文件可读性/差异稳定的装饰性——`fromJson` 不依赖键顺序。

### `factory DailyScoreLog.fromJson(Map<String, dynamic> json)` <a id="dailyscorelog-fromjson"></a>
- **种类：** `DailyScoreLog` 的工厂构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 618 行）
- **用途：** 解析评分日志，接受当前逐条目对象格式和遗留裸数字格式。
- **输入：** `json`。
- **返回：** 新 `DailyScoreLog`。
- **副作用：** 无。
- **算法：** 对每个键/值：`value` 是 `Map` 时经 `DailyScoreEntry.fromJson` 解析；`value` 是 `num`（遗留裸评分）时直接以该舍入值和纪元 `modifiedAt` 构建 `DailyScoreEntry`；任何其他值类型静默跳过。
- **用法：** `json['dailyScores'] != null ? DailyScoreLog.fromJson(json['dailyScores'] as Map<String, dynamic>) : DailyScoreLog()`（`TodoData.fromJson`，`todo_storage.dart`，第 92-94 行）。
- **备注：** 遗留数字条目获得纪元 `modifiedAt`，因此首次与曾以真实时间戳显式设置那天评分的对等方合并时，遗留值在 `merge` 的最后写入者胜出比较中总是输。

### `factory DailyScoreLog.merge(DailyScoreLog local, DailyScoreLog remote)` <a id="dailyscorelog-merge"></a>
- **种类：** `DailyScoreLog` 的工厂构造函数
- **来源：** `lib/features/todo/models/task.dart`（第 647 行）
- **用途：** 逐日期独立解决的两个评分日志最后写入者胜出合并。
- **输入：** `local`、`remote`。
- **返回：** 新 `DailyScoreLog`。
- **副作用：** 无（纯）。
- **算法：**
  1. 并集两边所有日期键。
  2. 逐日期：只有 `remote` 有条目时取 remote 的；否则 `local` 无对应条目、或 `local` 的 `modifiedAt` 晚于或等于 `remote` 的时取 local 的；否则取 remote 的。
- **用法：**
  ```dart
  final mergedScores = DailyScoreLog.merge(
    local.dailyScores,
    remote.dailyScores,
  );
  ```
  （`lib/shared/services/sync_merge.dart`，第 253-256 行）。
- **备注：** 平局（`localEntry.modifiedAt == remoteEntry.modifiedAt`）偏向 local——此约定在合并中别处的应用见 [三方合并](../../../../algorithms/three-way-merge.md)。

# lib/features/todo/widgets/add_task_dialog.dart

创建新 [`Task`](../../../../features/todo.md#model) 的模态对话框（或提供 `initialTask` 时，提示用户创建已完重复一次性任务的*下一次出现*——见 [Todo](../../../../features/todo.md#model) 的 `TaskRecurrence`/`nextDate`）。把其表单包在 `UnsavedChangesGuard`（`lib/shared/widgets/unsaved_changes_guard.dart`）中，使带未保存编辑导航离开时提示丢弃确认；守卫的脏检查由从每个可编辑字段计算的表单"签名"字符串驱动。重复编辑委托给以嵌套底部面板显示的 [`RecurrencePicker`](recurrence_picker.md)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `AddTaskDialog`（构造函数） | 构造函数（`AddTaskDialog`） | B | 创建添加任务对话框实例。 |
| `createState` | 方法（`AddTaskDialog`） | B | 创建可变 `_AddTaskDialogState`。 |
| `initState` | 方法（`_AddTaskDialogState`） | B | 从 `initialTask` 预填控制器/字段（编辑下一次出现提示时）并捕获初始表单签名。 |
| `dispose` | 方法（`_AddTaskDialogState`） | B | 释放标题/备注/子任务文本控制器。 |
| `build` | 方法（`_AddTaskDialogState`） | B | 渲染标题/备注字段、类型选择器、提醒/安排/截止/重复选择器、子任务列表和取消/添加操作。 |
| `_addSubtask` | 方法（`_AddTaskDialogState`） | B | 把挂起子任务输入文本追加进 `_subtaskTitles` 并清除字段。 |
| `_showEmojiPicker` | 方法（组件辅助，`_AddTaskDialogState`） | B | 显示用于挑选 `_selectedEmoji` 的 emoji 网格底部面板。 |
| `_showCustomEmojiInput` | 方法（组件辅助，`_AddTaskDialogState`） | B | 显示用于输入自定义 emoji/字符的对话框。 |
| [`_hasUnsavedChanges`](#hasunsavedchanges) | 方法（`_AddTaskDialogState`） | A | 报告表单是否不同于其初始状态。 |
| [`_signature`](#signature) | 方法（`_AddTaskDialogState`） | A | 构建每个可编辑字段的可比较字符串快照。 |
| [`_recurrenceSignature`](#recurrencesignature) | 方法（`_AddTaskDialogState`） | A | 构建 `TaskRecurrence?` 的可比较字符串快照。 |
| [`_submit`](#submit) | 方法（`_AddTaskDialogState`） | A | 验证标题并构造/弹出新 `Task`。 |
| `_fmtDate` | 方法（`_AddTaskDialogState`） | B | 把 `DateTime` 格式化为 `yyyy-MM-dd`。 |
| [`_recurrenceLabel`](#recurrencelabel) | 方法（`_AddTaskDialogState`） | A | 把 `TaskRecurrence` 映射到其本地化显示字符串。 |
| `_showRecurrencePicker` | 方法（组件辅助，`_AddTaskDialogState`） | B | 把 `RecurrencePicker` 显示为底部面板并把结果存进 `_recurrence`。 |

## 文档

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges"></a>
- **种类：** `_AddTaskDialogState` 的方法
- **来源：** `lib/features/todo/widgets/add_task_dialog.dart`（第 550 行）
- **用途：** 告诉 `UnsavedChangesGuard` 表单是否已偏离初始状态，使它知道对话框被关闭前是否提示确认。
- **输入：** 无（只读实例状态）。
- **返回：** `bool` — 当前表单签名不同于 `_initialSignature` 时 `true`。
- **副作用：** 无。
- **算法：**
  1. 经 [`_signature()`](#signature) 重新计算当前签名。
  2. 与 `_initialSignature` 比较（`initState` 中从 `initialTask` 预填后立即捕获一次，创建全新任务时则立即作为空表单基线）。
  3. 返回是否不同。
- **用法：**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **备注：** 作为撕下引用（`bool Function()`）传入而非直接调用，使 `UnsavedChangesGuard` 每次弹出尝试时重新求值而非缓存值。

### `String _signature()` <a id="signature"></a>
- **种类：** `_AddTaskDialogState` 的方法
- **来源：** `lib/features/todo/widgets/add_task_dialog.dart`（第 557-568 行）
- **用途：** 产生任何可编辑字段值变化时且仅此时变化的单个字符串，用作脏检查基线/比较。
- **输入：** 无（只读实例状态）。
- **返回：** `String` — 来自 `formSignature`（`lib/shared/widgets/unsaved_changes_guard.dart`）的连接签名。
- **副作用：** 无。
- **算法：**
  1. 把修剪标题、修剪备注、修剪挂起子任务文本、所选 `TaskType` 名、提醒时间、所选 emoji、安排日期、截止日期、[重复签名](#recurrencesignature) 和完整 `_subtaskTitles` 列表收集进一个有序值列表。
  2. 委托给共享 `formSignature(Iterable<Object?>)` 辅助，它把每个值映射为规范字符串并用单元分隔符分隔符连接，使无关字段绝不能碰撞成相同签名。
- **用法：**
  ```dart
  _initialSignature = _signature();
  // ...
  bool _hasUnsavedChanges() => _signature() != _initialSignature;
  ```
- **备注：** 因为包含挂起（尚未添加）子任务文本，在"添加子任务"字段中打字而未按回车仍算未保存变更。

### `String _recurrenceSignature(TaskRecurrence? recurrence)` <a id="recurrencesignature"></a>
- **种类：** `_AddTaskDialogState` 的方法
- **来源：** `lib/features/todo/widgets/add_task_dialog.dart`（第 575-583 行）
- **用途：** 把 `TaskRecurrence?` 规范化为可比较字符串以嵌入 [`_signature()`](#signature) 内。
- **输入：** `recurrence` — 当前 `TaskRecurrence?` 选择，可为 `null`。
- **返回：** `String` — `recurrence` 为 `null` 时 `''`，否则对重复规则的 `type.name`、`intervalDays`、`dayOfMonth` 和 `monthOfYear` 做 `formSignature`。
- **副作用：** 无。
- **算法：**
  1. `recurrence` 为 `null` 时立即返回空字符串（区别于任何真实重复规则的签名，后者总是至少包含类型名）。
  2. 否则从 `TaskRecurrence`（`lib/features/todo/models/task.dart`）声明的四个字段构建 `formSignature`，无论该重复类型实际用哪些，使仅切换重复*类型*（即使数字字段不变）也改变签名。
- **用法：**
  ```dart
  String _signature() => formSignature([
    // ...
    _recurrenceSignature(_recurrence),
    _subtaskTitles,
  ]);
  ```
- **备注：** 无。

### `void _submit(UnsavedChangesController guard)` <a id="submit"></a>
- **种类：** `_AddTaskDialogState` 的方法
- **来源：** `lib/features/todo/widgets/add_task_dialog.dart`（第 590-629 行）
- **用途：** 验证表单，有效时构造新 `Task` 并带它弹出对话框。
- **输入：** `guard` — `UnsavedChangesGuard.builder` 提供的 `UnsavedChangesController`，用于带结果弹出路由。
- **返回：** `None`。
- **副作用：** 标题非空时经 `guard.pop(task)` 弹出对话框路由；否则什么都不做（对话框保持打开）。
- **算法：**
  1. 修剪标题；为空时不弹出地返回——这是表单唯一硬验证规则（空标题静默阻塞提交）。
  2. 修剪备注和挂起子任务输入文本；非空时把挂起子任务追加进已添加 `_subtaskTitles` 列表，使已打字但未显式"添加"的文本不丢失。
  3. 选了提醒时间时把它与*今天*的日期（`DateTime.now()` 的年/月/日）组合成 `DateTime`——日期分量是占位符；只有时/分重要，因为 Todo 提醒每天重新触发（见 [Todo 提醒](../../../../features/todo.md#reminders)）。
  4. 构造 `Task`：不适用时 `note`/`recurrence`/`dueDate` 坍缩为 `null`（空备注，或 `_selectedType == TaskType.daily`）；一次性任务的 `scheduledDate` 默认 `widget.defaultDate ?? DateTime.now()`；只对每日模板任务设 `startDate`（来自 `widget.defaultDate ?? DateTime.now()`）。
  5. 调用 `guard.pop(task)`，带新 `Task` 作为结果弹出对话框路由（见 `lib/shared/widgets/unsaved_changes_guard.dart` 的 `UnsavedChangesController.pop`）。
- **用法：**
  ```dart
  Future<void> _addTask() async {
    final task = await showDialog<Task>(
      context: context,
      builder: (_) => AddTaskDialog(defaultDate: _selectedDate),
    );
    if (task != null) {
      setState(() {
        if (task.type == TaskType.daily) {
          _dailyTemplates.add(task);
        } else {
          _oneTimeTasks.add(task);
        }
        _appendTaskToCustomOrderIfNeeded(task);
      });
      _saveData();
    }
  }
  ```
  （调用方：`lib/features/todo/views/todo_page.dart`，`_addTask`）
- **备注：** 所有持久化（把返回 `Task` 添加进每日模板/一次性列表并调用 `_saveData()`）都发生在调用方而非此对话框——`_submit` 只产生 `Task` 值并弹出。

### `String _recurrenceLabel(TaskRecurrence r, AppLocalizations l10n)` <a id="recurrencelabel"></a>
- **种类：** `_AddTaskDialogState` 的方法
- **来源：** `lib/features/todo/widgets/add_task_dialog.dart`（第 644-653 行）
- **用途：** 产生设置了重复时显示在重复 `ListTile` 标题中的 `TaskRecurrence` 本地化单行摘要。
- **输入：** `r` — 要描述的 `TaskRecurrence`；`l10n` — 当前 `AppLocalizations`。
- **返回：** `String` — 取决于 `r.type` 的本地化短语，如"每 N 天"、"每月 N 日"或"每年 M/D"。
- **副作用：** 无。
- **算法：** 对 `r.type`（`RecurrenceType.everyNDays` / `.monthlyOnDay` / `.yearlyOnMonthDay`）穷举 `switch`，把格式化委托给匹配 `AppLocalizations` getter（`todoRecurrenceEveryNDays`、`todoRecurrenceMonthlyOnDay`、`todoRecurrenceYearlyOnDate`），带重复规则的 `intervalDays`/`dayOfMonth`/`monthOfYear` 字段。
- **用法：**
  ```dart
  title: Text(
    _recurrence != null
        ? _recurrenceLabel(_recurrence!, l10n)
        : l10n.todoRecurrence,
  ),
  ```
- **备注：** 在 [`edit_task_dialog.dart`](edit_task_dialog.md#recurrencelabel) 中逐字重复（相同 switch、相同三个 case）——两个对话框当前不共享此辅助。


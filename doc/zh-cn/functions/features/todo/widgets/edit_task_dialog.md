# lib/features/todo/widgets/edit_task_dialog.dart

编辑既有 [`Task`](../../../../features/todo.md#model) 的模态对话框——标题、备注、emoji、类型、提醒、安排/截止/完成/开始日期、重复和子任务（带拖拽重排和内联重命名），加对已软删除每日模板的"永久删除"操作（见 [Todo](../../../../features/todo.md#model) 的 `deletedDate`）。像 [`AddTaskDialog`](add_task_dialog.md) 一样，它把表单包在由表单签名脏检查驱动的 `UnsavedChangesGuard`（`lib/shared/widgets/unsaved_changes_guard.dart`）中，并把重复编辑委托给 [`RecurrencePicker`](recurrence_picker.md)。本文件针对更丰富的编辑期字段集（它还暴露 `AddTaskDialog` 没有的 `completedDate`/`startDate`/`deletedDate`）重复 `add_task_dialog.dart` 的大部分字段编辑和签名/提交逻辑。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `EditTaskDialog`（构造函数） | 构造函数（`EditTaskDialog`） | B | 创建编辑任务对话框实例。 |
| `createState` | 方法（`EditTaskDialog`） | B | 创建可变 `_EditTaskDialogState`。 |
| `initState` | 方法（`_EditTaskDialogState`） | B | 把 `widget.task` 的每个可编辑字段复制进本地状态并捕获初始表单签名。 |
| `dispose` | 方法（`_EditTaskDialogState`） | B | 释放标题/备注/子任务文本控制器。 |
| `build` | 方法（`_EditTaskDialogState`） | B | 渲染所有可编辑字段、完成/开始/创建/删除日期行、永久删除按钮、可重排子任务列表和取消/保存操作。 |
| `_addSubtask` | 方法（`_EditTaskDialogState`） | B | 把挂起子任务输入文本作为新 `SubTask` 追加并清除字段。 |
| `_reorderSubtask` | 方法（`_EditTaskDialogState`） | B | 把子任务从 `_subtasks` 的 `oldIndex` 移到 `newIndex`。 |
| `_editSubtask` | 方法（`_EditTaskDialogState`） | B | 显示受保护对话框原地重命名一个子任务标题。 |
| `_showEmojiPicker` | 方法（组件辅助，`_EditTaskDialogState`） | B | 显示用于挑选 `_selectedEmoji` 的 emoji 网格底部面板。 |
| `_showCustomEmojiInput` | 方法（组件辅助，`_EditTaskDialogState`） | B | 显示用于输入自定义 emoji/字符的对话框。 |
| [`_recurrenceLabel`](#recurrencelabel) | 方法（`_EditTaskDialogState`） | A | 把 `TaskRecurrence` 映射到其本地化显示字符串。 |
| `_showRecurrencePicker` | 方法（组件辅助，`_EditTaskDialogState`） | B | 把 `RecurrencePicker` 显示为底部面板并把结果存进 `_recurrence`。 |
| [`_hasUnsavedChanges`](#hasunsavedchanges-1) | 方法（`_EditTaskDialogState`） | A | 报告表单是否不同于任务的原始状态。 |
| [`_signature`](#signature-1) | 方法（`_EditTaskDialogState`） | A | 构建每个可编辑字段（含子任务）的可比较字符串快照。 |
| [`_recurrenceSignature`](#recurrencesignature-1) | 方法（`_EditTaskDialogState`） | A | 构建 `TaskRecurrence?` 的可比较字符串快照。 |
| [`_submit`](#submit-1) | 方法（`_EditTaskDialogState`） | A | 验证标题并构造/弹出更新 `Task`，保留原始的身份字段。 |

## 文档

### `String _recurrenceLabel(TaskRecurrence r, AppLocalizations l10n)` <a id="recurrencelabel"></a>
- **种类：** `_EditTaskDialogState` 的方法
- **来源：** `lib/features/todo/widgets/edit_task_dialog.dart`（第 762-771 行）
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
- **备注：** 与 [`add_task_dialog.dart` 的 `_recurrenceLabel`](add_task_dialog.md#recurrencelabel) 逐字节相同 switch——两个对话框当前不共享此辅助。

### `bool _hasUnsavedChanges()` <a id="hasunsavedchanges-1"></a>
- **种类：** `_EditTaskDialogState` 的方法
- **来源：** `lib/features/todo/widgets/edit_task_dialog.dart`（第 797 行）
- **用途：** 告诉 `UnsavedChangesGuard` 表单是否已偏离任务的原始状态，使它知道对话框被关闭前是否提示确认。
- **输入：** 无（只读实例状态）。
- **返回：** `bool` — 当前表单签名不同于 `_initialSignature` 时 `true`。
- **副作用：** 无。
- **算法：**
  1. 经 [`_signature()`](#signature-1) 重新计算当前签名。
  2. 与 `_initialSignature` 比较（`initState` 中把每个字段从 `widget.task` 复制后立即捕获一次）。
  3. 返回是否不同。
- **用法：**
  ```dart
  return UnsavedChangesGuard(
    hasUnsavedChanges: _hasUnsavedChanges,
    builder: (context, guard) => Dialog(...),
  );
  ```
- **备注：** 与 [`AddTaskDialog` 的 `_hasUnsavedChanges`](add_task_dialog.md#hasunsavedchanges) 结构相同；差异全在 `_signature()` 覆盖什么。

### `String _signature()` <a id="signature-1"></a>
- **种类：** `_EditTaskDialogState` 的方法
- **来源：** `lib/features/todo/widgets/edit_task_dialog.dart`（第 804-817 行）
- **用途：** 产生任何可编辑字段值从加载状态变化时且仅此时变化的单个字符串，用作脏检查基线/比较。
- **输入：** 无（只读实例状态）。
- **返回：** `String` — 来自 `formSignature`（`lib/shared/widgets/unsaved_changes_guard.dart`）的连接签名。
- **副作用：** 无。
- **算法：**
  1. 把修剪标题、修剪备注、修剪挂起子任务文本、所选 `TaskType` 名、提醒时间、所选 emoji、安排/完成/开始/截止日期、[重复签名](#recurrencesignature-1) 收集进一个有序值列表。
  2. 额外把 `_subtasks` 映射为每个子任务的 `[id, title, isCompleted]` 三元组，使子任务重命名、完成切换或重排（改变映射可迭代中位置）也被检测为变更——不像 `AddTaskDialog` 只跟踪子任务*标题*，因为那里的新子任务还没有 `id`/`isCompleted`。
  3. 委托给共享 `formSignature(Iterable<Object?>)` 辅助，它把每个值映射为规范字符串并用单元分隔符连接。
- **用法：**
  ```dart
  _initialSignature = _signature();
  // ...
  bool _hasUnsavedChanges() => _signature() != _initialSignature;
  ```
- **备注：** 重排子任务改变它们在 `_subtasks.map(...)` 可迭代中的位置，因此改变签名，即使没有单个子任务自己的字段变化——这是刻意的，因为 `_reorderSubtask` 修改持久化顺序。

### `String _recurrenceSignature(TaskRecurrence? recurrence)` <a id="recurrencesignature-1"></a>
- **种类：** `_EditTaskDialogState` 的方法
- **来源：** `lib/features/todo/widgets/edit_task_dialog.dart`（第 824-832 行）
- **用途：** 把 `TaskRecurrence?` 规范化为可比较字符串以嵌入 [`_signature()`](#signature-1) 内。
- **输入：** `recurrence` — 当前 `TaskRecurrence?` 选择，可为 `null`。
- **返回：** `String` — `recurrence` 为 `null` 时 `''`，否则对重复规则的 `type.name`、`intervalDays`、`dayOfMonth` 和 `monthOfYear` 做 `formSignature`。
- **副作用：** 无。
- **算法：** 与 [`AddTaskDialog` 的 `_recurrenceSignature`](add_task_dialog.md#recurrencesignature) 相同：`null` 返回 `''`，否则无论当前 `type` 实际用哪些都 `formSignature` 全部四个 `TaskRecurrence` 字段。
- **用法：**
  ```dart
  String _signature() => formSignature([
    // ...
    _recurrenceSignature(_recurrence),
    _subtasks.map((s) => [s.id, s.title, s.isCompleted]),
  ]);
  ```
- **备注：** 无。

### `void _submit(UnsavedChangesController guard)` <a id="submit-1"></a>
- **种类：** `_EditTaskDialogState` 的方法
- **来源：** `lib/features/todo/widgets/edit_task_dialog.dart`（第 839-880 行）
- **用途：** 验证表单，有效时构造更新 `Task`（保留身份和此对话框不可编辑的字段）并带它弹出对话框。
- **输入：** `guard` — `UnsavedChangesGuard.builder` 提供的 `UnsavedChangesController`，用于带结果弹出路由。
- **返回：** `None`。
- **副作用：** 标题非空时经 `guard.pop(updated)` 弹出对话框路由；否则什么都不做（对话框保持打开）。
- **算法：**
  1. 修剪标题；为空时不弹出地返回——表单唯一硬验证规则。
  2. 修剪备注和挂起子任务输入文本；非空时把挂起子任务作为新 `SubTask` 追加进已编辑 `_subtasks` 列表。
  3. 设了提醒时间时把它与*今天*的日期组合成 `DateTime`（只有时/分有意义——见 [Todo 提醒](../../../../features/todo.md#reminders) 的提醒调度备注）。
  4. 构造更新 `Task`，逐字从 `widget.task` 复制 `id`、`isCompleted`、`createdDate` 和 `deletedDate`（这些不可经此表单字段编辑）；`note`/`recurrence`/`dueDate`/`startDate` 按与 `AddTaskDialog` 相同的每日-vs-一次性规则坍缩为 `null`；一次性任务的 `scheduledDate` 只在未设时默认 `DateTime.now()`。
  5. 调用 `guard.pop(updated)` 带更新 `Task` 作为结果弹出对话框路由。
- **用法：**
  ```dart
  final updated = await showDialog<Task>(
    context: context,
    builder: (_) => EditTaskDialog(
      task: originalTask,
      onPermanentDelete: originalTask.deletedDate != null
          ? () {
              permanentlyDeleted = true;
              setState(() {
                _dailyTemplates.removeWhere((t) => t.id == originalTask.id);
              });
              _saveData();
            }
          : null,
    ),
  );
  ```
  （调用方：`lib/features/todo/views/todo_page.dart`，`_editTask`）
- **备注：** 与 `AddTaskDialog._submit` 不同，这从原始任务保留 `isCompleted`/`createdDate`/`deletedDate` 而非默认它们，因为编辑绝不能静默重置完成状态、创建日期或软删除状态。


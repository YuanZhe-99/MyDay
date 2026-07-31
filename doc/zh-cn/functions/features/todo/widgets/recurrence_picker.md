# lib/features/todo/widgets/recurrence_picker.dart

让用户为一次性任务挑选 [`TaskRecurrence`](../../../../features/todo.md#model) 或清除回"无重复"的底部面板组件。从 [`AddTaskDialog`](add_task_dialog.md) 和 [`EditTaskDialog`](edit_task_dialog.md) 两者经 `showModalBottomSheet` 打开，并经 `onSelected` 回调报告所选重复规则，而非从面板路由返回值。此组件编辑的 `TaskRecurrence` 模型（间隔天/每月某日/每年某月日）见 [Todo](../../../../features/todo.md#model)。

本文件所有逻辑都是 UI 状态接线——挑选 `RecurrenceType`、滑动间隔/日/月值、保存时把当前选择转换为 `TaskRecurrence`。没有单独计算的"预览"方法：每个单选选项和滑块旁显示的预览文本由 `build()` 内联产生，直接对本地状态调用相关 `AppLocalizations` getter（如 `l10n.todoRecurrenceEveryNDays(_intervalDays)`），因此作为 `build()` 行的一部分文档化而非其自己的 Tier A 条目。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `RecurrencePicker`（构造函数） | 构造函数（`RecurrencePicker`） | B | 创建重复选择器实例。 |
| `createState` | 方法（`RecurrencePicker`） | B | 创建可变 `_RecurrencePickerState`。 |
| `initState` | 方法（`_RecurrencePickerState`） | B | 从 `widget.initial` 播种 `_type`/`_intervalDays`/`_dayOfMonth`/`_monthOfYear`。 |
| `build` | 方法（`_RecurrencePickerState`） | B | 渲染单选选项、滑块和保存/取消行；计算保存时 `TaskRecurrence`。 |

## 文档

本文件无 Tier A 声明。


# 待办

模型来源：`lib/features/todo/models/task.dart`。存储/配置：`lib/features/todo/services/todo_storage.dart`。完整字段列表见 [数据格式](../data-formats.md#todo--todo_datajson)，同步语义见 [三方合并](../algorithms/three-way-merge.md)。

## 模型

- **`TaskType`**：`daily`、`routineOnce`、`workOnce`。
- **`TaskRecurrence`**：描述*一次性*任务完成后如何重复——`RecurrenceType.everyNDays`（以天为间隔）、`RecurrenceType.monthlyOnDay`（day-of-month，钳制到目标月长度）或 `RecurrenceType.yearlyOnMonthDay`（月 + 日，短二月钳制）。`nextDate(from)` 直接在重复对象上计算下一次出现日期。带 `recurrence` 的一次性任务在用户完成任务后提示创建下一次出现。
- **`Task`**：`id`、`title`、可选 `note`、可选 `emoji`、`type`、`isCompleted`、可选 `reminderTime`、`subtasks`、`createdDate`、可选 `completedDate`。一次性任务：`scheduledDate`（排定日期）、`dueDate`（提醒用途）、`recurrence`。每日模板：`startDate`（模板变为激活的日期——默认为创建时选中的日期）和 `deletedDate`（软删除日期；`null` 表示仍激活——每日模板绝不硬删除，使引用它们的完成日志历史保持有意义）。
- **`DailyCompletionLog`**：每日任务和每日子任务的按日期完成跟踪，以 `yyyy-MM-dd` 为键。同步按**并集**合并——在任一台设备上完成的任务在合并后保持完成，理论是"已完成"绝不应被同步撤销。
- **`DailyScoreLog`**：从 **-5 到 5** 的按天全天评分，默认 **0**。显式零条目被保留（不当作"无条目"），使刻意的重置为零仍能经同步传播；每个日期按该条目的 `modifiedAt` 独立合并。

## 存储

`TodoStorage` 是整个应用的中心存储/配置中枢，不只是待办：`storage_config.json` 总是留在默认应用目录，存储自定义存储路径、亲密可见性、主题、语言区域、周起始日、托盘设置、备份设置、本地 API 设置和仅本地的亲密计时器保持屏幕唤醒偏好。`todo_data.json` 存储每日模板、一次性任务、每日日志、每日评分、早晨/完成提醒设置、任务排序模式/自定义顺序和 `settingsModifiedAt`。

## UI

待办 UI 包括所选日期所在周的内联周历、带内联年/月跳转的次级整月日历页、全局可配置的周起始日、月度日评分趋势图、快乐日和痛苦日列表（从评分日志派生）、每日/常规/工作小节、日历完成指示器、未来排定一次性任务标记、待办列表底部可编辑的全天评分、逐小节独立排序/自定义拖动顺序、备注、子任务、任务提醒、重复选择器、未保存变更保护和保存后的 `AutoSyncService.instance.notifySaved()`。

## 提醒

一次性待办提醒**从任务的排定日期开始**，然后**按保存的时间每日重复直到任务完成**——即未来一次性任务的提醒不会在其排定日期到达前触发，但一旦激活就每天持续触发（不只是一次）直到任务被标记完成。移动端实现为：未来一次性任务先获得一次性开始日期 OS 日程，激活后切到每日重复 OS 日程；每日模板总是用每日 OS 日程（今天已完成则移到明天开始）。桌面 vs 移动提醒投递拆分和触发时间语义见 [平台说明](../platform-notes.md#notifications-reminders-tray-and-startup)。

## 相关页面

- [数据格式](../data-formats.md) — 上面每个模型的精确 JSON 形态。
- [三方合并](../algorithms/three-way-merge.md) — 完成和评分日志的并集/LWW 合并规则。
- [平台说明](../platform-notes.md) — 桌面 vs 移动端的提醒调度机制。

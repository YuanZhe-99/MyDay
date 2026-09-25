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

待办 UI 包括所选日期所在周的内联周历、带内联年/月跳转的次级整月日历页、全局可配置的周起始日、月度日评分趋势图、快乐日和痛苦日列表（从评分日志派生）、每日/常规/工作小节、日历完成指示器、未来排定一次性任务标记、待办列表底部可编辑的全天评分、逐小节独立排序/自定义拖动顺序、备注、子任务、带标题驱动表情建议的任务图标（见 [表情建议](#emoji-suggestions)）、任务提醒、重复选择器、未保存变更保护和保存后的 `AutoSyncService.instance.notifySaved()`。

<a id="emoji-suggestions"></a>
## 表情建议

任务的可选 `emoji` 就是它的图标。添加和编辑对话框以三种方式提供它，全部建立在两个共享常量和一个纯函数之上：

| 部件 | 来源 | 作用 |
|---|---|---|
| [`commonTaskEmojis`](../functions/features/todo/constants/task_emojis.md) | `lib/features/todo/constants/task_emojis.dart` | 选择器网格的 98 个候选：原有 32 个在前，其后是日常分组。两个对话框共用一份列表。 |
| [`emojiKeywordTable`](../functions/features/todo/constants/emoji_keywords.md) | `lib/features/todo/constants/emoji_keywords.dart` | 188 个人工整理的条目，每个是一个 emoji 加英语、简体中文、繁体中文和日语关键词。 |
| [`suggestEmojis`](../functions/features/todo/utils/emoji_suggester.md#suggestemojis) | `lib/features/todo/utils/emoji_suggester.dart` | 用标题对关键词表排序，返回最多 8 个不重复 emoji。 |
| [`EmojiSuggestionRow`](../functions/features/todo/widgets/emoji_suggestion_row.md) | `lib/features/todo/widgets/emoji_suggestion_row.dart` | 标题字段下方可换行的标签行。 |

**匹配。** 建议的工作方式类似输入法的 emoji 搜索：无论 UI 语言区域如何，都匹配每种语言的关键词，因此在英文 UI 中输入中文标题也会得到建议。标题会转小写、全角 ASCII 折叠为半角、空白压缩。CJK 关键词按子串匹配；拉丁关键词匹配完整单词或短语、常规英语词形变化（`emails`、`cooking`），以及——仅对仍在输入的最后一个单词——至少 3 个字母的前缀。较长的匹配得分更高，平分时保持表顺序。位置不加分，因为标题往往以动词开头，后面的宾语才是更好的图标。完整规则见 [`_scoreKeyword`](../functions/features/todo/utils/emoji_suggester.md#scorekeyword) 条目。

**自动填充与手动选择。** 用户尚未选择图标时，图标随标题变化跟随最佳建议，没有建议时清除。以其他任何方式选择图标——点按标签、从网格挑选、输入自定义 emoji 或移除——都算手动选择，并在该对话框剩余时间内停止自动填充。打开时已设置 emoji 的对话框（编辑已有 emoji 的任务，或预填了 emoji 的下一次出现提示）永不自动填充；其标签仍会出现并可点按。只有标题文本的真实编辑才会触发自动填充——光标移动和自动聚焦字段获得焦点都不会——因此打开任务后原样关闭永远不会改变其图标，也不会触发未保存变更提示。建议即时计算，不存储任何相关内容：`Task` 上只保存最终选定的 `emoji`。

**扩展关键词表。** 向既有 `EmojiKeywordEntry` 添加关键词，或在 `emoji_keywords.dart` 中对应的主题分组里添加新条目。若还要在选择器网格中提供该 emoji，也把它追加到 `commonTaskEmojis` 的某个分组。注意：

- 关键词小写、已修剪且非空，每个条目在全部四种语言中都有关键词。
- 每个 emoji 在表中只出现一次；每个选择器 emoji 都必须有条目；选择器条目是互不重复的单个字素，原有 32 个保持在最前。
- 共享关键词的更常见含义放在靠前的条目——表顺序决定平分。
- 排除许多标题以此开头却不指明对象的填充语（"don't forget"、别忘了、忘れずに）；它会压过后面的对象。

`test/emoji_suggester_test.dart` 强制前两条规则，并为每种语言的示例标题固定预期建议；`test/task_emoji_suggestion_dialog_test.dart` 覆盖对话框行为。修改关键词表后请运行这两个测试。

## 提醒

一次性待办提醒**从任务的排定日期开始**，然后**按保存的时间每日重复直到任务完成**——即未来一次性任务的提醒不会在其排定日期到达前触发，但一旦激活就每天持续触发（不只是一次）直到任务被标记完成。移动端实现为：未来一次性任务先获得一次性开始日期 OS 日程，激活后切到每日重复 OS 日程；每日模板总是用每日 OS 日程（今天已完成则移到明天开始）。桌面 vs 移动提醒投递拆分和触发时间语义见 [平台说明](../platform-notes.md#notifications-reminders-tray-and-startup)。

## 相关页面

- [数据格式](../data-formats.md) — 上面每个模型的精确 JSON 形态。
- [三方合并](../algorithms/three-way-merge.md) — 完成和评分日志的并集/LWW 合并规则。
- [平台说明](../platform-notes.md) — 桌面 vs 移动端的提醒调度机制。

# lib/features/todo/constants/task_emojis.dart

任务 emoji 选择器的共享候选列表。[`AddTaskDialog`](../widgets/add_task_dialog.md) 和 [`EditTaskDialog`](../widgets/edit_task_dialog.md) 都从这一个常量渲染选择器网格；v1.4.5 之前，两个对话框各自带一份逐字节相同的私有 `_commonEmojis` 列表。每个条目也必须在 [`emojiKeywordTable`](emoji_keywords.md) 中有关键词，这样选择器提供的任何 emoji 也都能从标题建议出来（见 [待办——表情建议](../../../../features/todo.md#emoji-suggestions)）。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`commonTaskEmojis`](#commontaskemojis) | 顶层 `const` | A | 保存任务 emoji 选择器网格中显示的扁平 emoji 候选列表。 |

`grep -c 'Purpose:' lib/features/todo/constants/task_emojis.dart` 报告 1，与唯一的声明匹配。`/// Purpose:` 块直接位于常量上方（文件没有 `library;` 指令），因此它文档化的是 `commonTaskEmojis`，而不是文件。

## 文档

### `const List<String> commonTaskEmojis` <a id="commontaskemojis"></a>
- **种类：** 顶层 `const`
- **来源：** `lib/features/todo/constants/task_emojis.dart`（第 11-46 行）
- **用途：** 选择器网格在末尾"自定义 emoji"格之前显示的有序 emoji 列表。
- **输入：** 无。
- **返回：** 无（常量）。
- **副作用：** 无。
- **算法：** 无——字面量列表，共 98 个条目。原有的 32 个（v0.1.x）按原顺序排在最前，其后是日常分组：箭头、邮件、快递、金钱、礼物与活动、健康与家庭、家务、宠物与植物、工具、交通、休闲、食物、时间与标记、杂项。
- **用法：**
  ```dart
  itemCount: commonTaskEmojis.length + 1,
  itemBuilder: (context, index) {
    if (index < commonTaskEmojis.length) {
      final emoji = commonTaskEmojis[index];
      // ...
  ```
  （调用方：两个任务对话框中的 `_showEmojiPicker`）
- **备注：** `test/emoji_suggester_test.dart` 强制要求：条目互不重复；每个条目是单个字素簇（因此 👨‍💻 这类 ZWJ 序列没问题）；每个条目都出现在 `emojiKeywordTable` 中；原有 32 个保持在最前（在开头和索引 31 处抽查）。新 emoji 请追加到某个分组，不要重排列表开头。

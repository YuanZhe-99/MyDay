# lib/features/todo/widgets/emoji_suggestion_row.dart

显示在 [`AddTaskDialog`](add_task_dialog.md) 和 [`EditTaskDialog`](edit_task_dialog.md) 标题字段下方的无状态建议 emoji 标签行。它只负责渲染；建议列表（来自 [`suggestEmojis`](../utils/emoji_suggester.md#suggestemojis)）由对话框持有，点按的标签被转给对话框的 `_pickEmoji`，算作手动选择。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `wrapKey` | static `const`（`EmojiSuggestionRow`） | B | 标签 `Wrap` 上的 `ValueKey('todoEmojiSuggestions')`，供测试查找该行。 |
| `EmojiSuggestionRow`（构造函数） | 构造函数（`EmojiSuggestionRow`） | B | 用 `suggestions`、`selected` 和 `onSelected` 创建表情建议行。 |
| [`build`](#build) | 方法（`EmojiSuggestionRow`） | A | 为当前建议构建标签行。 |

**对账：** `grep -c 'Purpose:' lib/features/todo/widgets/emoji_suggestion_row.dart` 报告 2，而表格有 3 行。`wrapKey` 带的是普通 `///` 注释而非 `Purpose:` 块，但它属于组件的公共表面（测试依赖它），因此被列出。

## 文档

### `Widget build(BuildContext context)` <a id="build"></a>
- **种类：** `EmojiSuggestionRow` 的方法
- **来源：** `lib/features/todo/widgets/emoji_suggestion_row.dart`（第 33-55 行）
- **用途：** 为每个建议 emoji 渲染一个紧凑的 `ChoiceChip`。
- **输入：** `context`。使用组件的 `suggestions`（最佳在前）、`selected`（对话框当前的 emoji，可能为 `null`）和 `onSelected`。
- **返回：** `Widget`——`suggestions` 为空时为 `SizedBox.shrink()`，否则为以 `todoSuggestedIcons` 标注的 `Semantics` 容器，包裹一个 `Wrap`（key 为 `wrapKey`，间距 6，行间距 6）。
- **副作用：** 除构建组件外无；点按标签调用 `onSelected(emoji)`。
- **算法：**
  1. 没有可建议的内容时返回空框。
  2. 否则为每个 emoji 构建一个 `ChoiceChip`：18 号 emoji 标签，等于 `selected` 时为选中状态，无勾选标记，紧凑视觉密度。
- **用法：**
  ```dart
  if (_suggestedEmojis.isNotEmpty) ...[
    const SizedBox(height: 8),
    EmojiSuggestionRow(
      suggestions: _suggestedEmojis,
      selected: _selectedEmoji,
      onSelected: _pickEmoji,
    ),
  ],
  ```
- **备注：** 使用 `Wrap` 而非横向列表，因此在窄对话框中八个标签会换到第二行，而不是溢出或藏在滚动之后。自动填充的 emoji 对应的标签显示为选中，让用户知道图标从何而来。

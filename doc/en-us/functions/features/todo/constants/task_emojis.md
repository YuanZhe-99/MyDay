# lib/features/todo/constants/task_emojis.dart

The shared candidate list for the task emoji picker. Both [`AddTaskDialog`](../widgets/add_task_dialog.md)
and [`EditTaskDialog`](../widgets/edit_task_dialog.md) render their picker grid from this one
constant; before v1.4.5 each dialog carried its own byte-identical private `_commonEmojis` list.
Every entry must also have keywords in [`emojiKeywordTable`](emoji_keywords.md), so anything the
picker offers can also be suggested from a title (see
[Todo — Emoji suggestions](../../../../features/todo.md#emoji-suggestions)).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`commonTaskEmojis`](#commontaskemojis) | top-level `const` | A | Hold the flat emoji candidate list shown in the task emoji picker grid. |

`grep -c 'Purpose:' lib/features/todo/constants/task_emojis.dart` reports 1, matching the single
declaration. The `/// Purpose:` block sits directly above the constant (the file has no `library;`
directive), so it documents `commonTaskEmojis`, not the file.

## Documentation

### `const List<String> commonTaskEmojis` <a id="commontaskemojis"></a>
- **Kind:** top-level `const`
- **Source:** `lib/features/todo/constants/task_emojis.dart` (lines 11-46)
- **Purpose:** The ordered list of emojis the picker grid shows before its trailing
  "custom emoji" cell.
- **Inputs:** None.
- **Returns:** None (constant).
- **Side effects:** None.
- **Algorithm:** None — a literal list, 98 entries. The original 32 (v0.1.x) come first and in
  their original order, followed by everyday groups: arrows, mail, delivery, money, gifts and
  events, health and family, home chores, pets and plants, tools, transport, leisure, food, time and
  pins, misc.
- **Usage:**
  ```dart
  itemCount: commonTaskEmojis.length + 1,
  itemBuilder: (context, index) {
    if (index < commonTaskEmojis.length) {
      final emoji = commonTaskEmojis[index];
      // ...
  ```
  (callers: `_showEmojiPicker` in both task dialogs)
- **Notes:** `test/emoji_suggester_test.dart` enforces that entries are distinct, that each is a
  single grapheme cluster (so ZWJ sequences such as 👨‍💻 are fine), that each appears in
  `emojiKeywordTable`, and that the original 32 stay first (spot-checked at the head and at index
31). Append new emojis to a group rather
  than reordering the head of the list.

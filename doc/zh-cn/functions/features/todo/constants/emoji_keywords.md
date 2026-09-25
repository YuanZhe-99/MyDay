# lib/features/todo/constants/emoji_keywords.dart

标题驱动表情建议背后的人工整理多语言关键词表。每个 `EmojiKeywordEntry` 把一个 emoji 与英语、简体中文、繁体中文和日语的关键词列表配对；[`suggestEmojis`](../utils/emoji_suggester.md#suggestemojis) 同时用所有语言匹配任务标题，与 UI 语言区域无关。表中共 188 个条目，按主题分组（写作与工作、沟通、箭头与状态、时间、快递与购物、金钱、礼物与活动、健康、运动、家务、家庭与宠物、交通与出行、地点、休闲、饮食、休息与天气、个人物品）。扩展方法见 [待办——表情建议](../../../../features/todo.md#emoji-suggestions)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| [`EmojiKeywordEntry`（构造函数）](#emojikeywordentry-new) | 构造函数（`EmojiKeywordEntry`） | A | 描述一个可建议的 emoji 及其各语言搜索关键词。 |
| `allKeywords` | getter（`EmojiKeywordEntry`） | B | 以一个可迭代对象返回所有语言的全部关键词（先 `en`，再 `zhHans`、`zhHant`、`ja`）。 |
| [`emojiKeywordTable`](#emojikeywordtable) | 顶层 `const` | A | `suggestEmojis` 使用的人工整理 emoji 关键词表。 |

`grep -c 'Purpose:' lib/features/todo/constants/emoji_keywords.dart` 报告 3，与三行匹配。`library;` 上方的文件级注释没有 `Purpose:` 块。`EmojiKeywordEntry` 的五个 final 字段（`emoji`、`en`、`zhHans`、`zhHant`、`ja`）不带 `Purpose:` 块，在构造函数条目中描述，不单独成行。

## 文档

### `const EmojiKeywordEntry(this.emoji, {this.en = const [], this.zhHans = const [], this.zhHant = const [], this.ja = const []})` <a id="emojikeywordentry-new"></a>
- **种类：** `EmojiKeywordEntry` 的 const 构造函数
- **来源：** `lib/features/todo/constants/emoji_keywords.dart`（第 18 行；类在第 5 行）
- **用途：** 关键词表的一行：一个 emoji 及应当建议它的词。
- **输入：** `emoji`（位置参数）；`en`、`zhHans`、`zhHant`、`ja`——关键词列表，默认均为空。
- **返回：** 新 `EmojiKeywordEntry`。
- **副作用：** 无。
- **算法：** 普通字段初始化 const 构造函数。
- **用法：**
  ```dart
  EmojiKeywordEntry(
    '📧',
    en: ['email', 'emails', 'e-mail', 'inbox', 'gmail', 'outlook'],
    zhHans: ['邮件', '电子邮件', '回邮件', '发邮件', '邮箱'],
    zhHant: ['郵件', '電子郵件', '回郵件', '寄郵件', '電郵'],
    ja: ['メール', 'めーる', 'eメール', '受信箱'],
  ),
  ```
- **备注：** 关键词必须小写、已修剪且非空，表中每个条目在四种语言中都至少有一个关键词——两条规则都由 `test/emoji_suggester_test.dart` 强制，尽管构造函数本身把列表默认为空。含任何 CJK 字符的关键词按子串匹配；其他关键词拆成拉丁词元，按整词或短语匹配（见 [`_scoreKeyword`](../utils/emoji_suggester.md#scorekeyword)），因此 `e-mail` 中的连字符之类标点充当词元分隔符。

### `const List<EmojiKeywordEntry> emojiKeywordTable` <a id="emojikeywordtable"></a>
- **种类：** 顶层 `const`
- **来源：** `lib/features/todo/constants/emoji_keywords.dart`（第 46-1856 行）
- **用途：** `suggestEmojis` 的默认 `table` 参数。
- **输入：** 无。
- **返回：** 无（常量）。
- **副作用：** 无。
- **算法：** 无——188 个条目的字面量列表。覆盖 [`commonTaskEmojis`](task_emojis.md) 中的每个 emoji，另加只能通过建议得到的额外 emoji（例如 🥛、⚡、💬）。
- **用法：**
  ```dart
  List<String> suggestEmojis(
    String title, {
    int max = 8,
    List<EmojiKeywordEntry> table = emojiKeywordTable,
  })
  ```
- **备注：**
  - **顺序决定平分。** 得分相同时按表索引排序，因此共享关键词的更常见含义应放在靠前的条目。
  - **每个 emoji 只出现一次**（测试强制）；请向既有条目添加关键词，不要再加第二个条目。
  - **刻意排除填充语。** 许多标题以此开头却不指明对象的短语（"don't forget"、别忘了、忘れずに）被刻意排除——📌 条目上的注释记录了原因：它们会压过后面的对象（"don't forget the keys" 应建议 🔑）。

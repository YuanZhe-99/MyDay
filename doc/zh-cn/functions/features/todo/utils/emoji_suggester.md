# lib/features/todo/utils/emoji_suggester.dart

纯 Dart、类似输入法（IME）的任务标题表情建议。本文件不依赖 Flutter，也没有状态：[`suggestEmojis`](#suggestemojis) 规范化标题，按任一语言中最佳匹配的关键词为 [`emojiKeywordTable`](../constants/emoji_keywords.md#emojikeywordtable) 的每个条目打分，并返回得分最高的不重复 emoji。两个任务对话框在每次标题变化时调用它（见 [`AddTaskDialog._onTitleChanged`](../widgets/add_task_dialog.md#ontitlechanged)）；面向用户的行为见 [待办——表情建议](../../../../features/todo.md#emoji-suggestions)。

## 声明

| 声明 | 种类 | Tier | 用途 |
|---|---|---|---|
| `_cjkCharWeight` | 顶层 `const`（私有） | B | 每个匹配的 CJK 关键词字符的得分：`30`。 |
| `_latinCharWeight` | 顶层 `const`（私有） | B | 每个匹配的拉丁关键词字母的得分：`10`。 |
| `_exactBonus` | 顶层 `const`（私有） | B | 精确整词、短语或整个标题匹配的加分：`5`。 |
| `_inflections` | 顶层 `const`（私有） | B | 标题词元可在关键词后附加的英语后缀：`s`、`es`、`ed`、`ing`、`er`、`ers`。 |
| [`normalizeTitle`](#normalizetitle) | 顶层函数 | A | 为关键词匹配规范化任务标题。 |
| [`containsCjk`](#containscjk) | 顶层函数 | A | 报告文本是否含 CJK 表意文字、假名或谚文。 |
| [`latinTokens`](#latintokens) | 顶层函数 | A | 把规范化文本拆分为拉丁字母/数字词元。 |
| [`_scoreKeyword`](#scorekeyword) | 顶层函数（私有） | A | 为一个关键词对规范化标题打分。 |
| [`suggestEmojis`](#suggestemojis) | 顶层函数 | A | 返回最多 `max` 个关键词与标题匹配的 emoji，最佳在前。 |

**对账：** `grep -c 'Purpose:' lib/features/todo/utils/emoji_suggester.dart` 报告 5，而表格有 9 行。四个打分常量带的是普通 `///` 注释而非 `Purpose:` 块，但它们决定排序，因此被列出。两个私有正则表达式（`_whitespace`、`_latinToken`）不列出；它们在 [`normalizeTitle`](#normalizetitle) 和 [`latinTokens`](#latintokens) 条目中描述。

## 文档

### `String normalizeTitle(String title)` <a id="normalizetitle"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/todo/utils/emoji_suggester.dart`（第 30-42 行）
- **用途：** 把标题转成关键词的书写形式，使匹配不区分大小写、全半角和空白。
- **输入：** `title`——原始标题文本。
- **返回：** `String`——小写并修剪，全角 ASCII 折叠为半角，每段空白（`\s+`，即私有 `_whitespace` 正则）压缩为一个空格。
- **副作用：** 无。
- **算法：**
  1. 遍历标题的 rune：U+FF01–U+FF5E 减去 `0xFEE0`（因此 `Ｍ` → `M`），表意空格 U+3000 变为普通空格，其余原样复制。
  2. 转小写、修剪并压缩空白段。
- **用法：**
  ```dart
  normalizeTitle('  Ｒｅｐｌｙ　TO   Mail '); // 'reply to mail'
  ```
- **备注：** Dart core 没有 NFKC 规范化，因此只折叠该全角区块和表意空格；例如半角片假名保持原样。

### `bool containsCjk(String text)` <a id="containscjk"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/todo/utils/emoji_suggester.dart`（第 50-62 行）
- **用途：** 决定关键词按 CJK 子串匹配还是按拉丁词元匹配。
- **输入：** `text`。
- **返回：** `bool`——任一 rune 落在以下范围时为 `true`：假名 U+3040–30FF、CJK 扩展 A U+3400–4DBF、CJK 统一表意文字 U+4E00–9FFF、CJK 兼容表意文字 U+F900–FAFF、谚文音节 U+AC00–D7AF、半角片假名 U+FF66–FF9F。
- **副作用：** 无。
- **算法：** 线性扫描 rune，遇到第一个命中即返回。
- **用法：**
  ```dart
  if (containsCjk(keyword)) {
    if (!title.contains(keyword)) return 0;
    // ...
  ```
- **备注：** 作用于*关键词*而非标题。`eメール` 这类混合关键词算作 CJK，按子串匹配。

### `List<String> latinTokens(String text)` <a id="latintokens"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/todo/utils/emoji_suggester.dart`（第 69-70 行）
- **用途：** 提取规范化字符串中的拉丁词。
- **输入：** `text`——已规范化（小写）。
- **返回：** `List<String>`——按顺序排列的每段 `[a-z0-9]+`（私有 `_latinToken` 正则）。
- **副作用：** 无。
- **算法：** 对文本执行 `RegExp.allMatches`。
- **用法：**
  ```dart
  final tokens = latinTokens(norm);
  ```
- **备注：** CJK 文本内的拉丁片段也会被找到，因此 `买iphone` 得到 `['iphone']`。撇号和连字符会拆分词元（`don't` → `don`、`t`）。

### `int _scoreKeyword(String keyword, String title, List<String> tokens)` <a id="scorekeyword"></a>
- **种类：** 顶层函数（私有）
- **来源：** `lib/features/todo/utils/emoji_suggester.dart`（第 80-123 行）
- **用途：** 为一个关键词与标题的匹配程度打分；0 表示不匹配。
- **输入：** `keyword`；`title`——已规范化；`tokens`——`latinTokens(title)`，由调用方计算一次。
- **返回：** `int` 得分。
- **副作用：** 无。
- **算法：**
  1. **CJK 关键词**（`containsCjk(keyword)`）：仅当 `title.contains(keyword)` 时匹配。得分为 `rune 数 × 30`，整个标题等于关键词时再加 `5`。CJK 没有词边界，子串是唯一可行的检测方式。
  2. **拉丁关键词**：标题或关键词没有拉丁词元时返回 0。
  3. **多词元关键词**（例如 `credit card`）：仅作为标题中连续相等的词元序列匹配。得分为 `字母总数 × 10 + 5`。
  4. **单词元关键词** `k`，与标题每个词元 `t` 比较，取最佳：
     - `t == k`：`k.length × 10 + 5`。
     - `k` 至少 3 个字母，且 `t` 是 `k` 加 `_inflections` 中的一个后缀（`emails`、`cooking`）：`k.length × 10`。任意扩展不算，因此标题词元 `card` 不匹配关键词 `car`。
     - 仅对用户可能仍在输入的**最后一个**词元：`t` 至少 3 个字母且 `k` 以 `t` 开头（`emai` → `email`）：`t.length × 10`。前面的词元是已完成的词，永不做前缀匹配。
- **用法：**
  ```dart
  for (final kw in entry.allKeywords) {
    final s = _scoreKeyword(kw, norm, tokens);
    if (s > best) best = s;
  }
  ```
- **备注：** 匹配出现在标题中的位置不加分。标题通常以动词开头（"reply to email"、"取快递"），后面的宾语名词才是更好的 emoji，位置加分会偏向错误的词。较长的匹配通过逐字符权重胜过较短的匹配；一个 CJK 字符的权重是拉丁字母的三倍，因为它承载的含义大致相当于一个短词片段。

### `List<String> suggestEmojis(String title, {int max = 8, List<EmojiKeywordEntry> table = emojiKeywordTable})` <a id="suggestemojis"></a>
- **种类：** 顶层函数
- **来源：** `lib/features/todo/utils/emoji_suggester.dart`（第 131-162 行）
- **用途：** 对关键词与任务标题匹配的 emoji 排序。
- **输入：** `title`——原始标题；`max`——结果上限（默认 8）；`table`——关键词表（默认 `emojiKeywordTable`；测试注入小表）。
- **返回：** `List<String>`——最多 `max` 个不重复 emoji，最佳在前；规范化标题为空或 `max <= 0` 时为 `const []`。
- **副作用：** 无。
- **算法：**
  1. 用 [`normalizeTitle`](#normalizetitle) 规范化标题；什么都不剩时返回空。
  2. 计算一次标题的拉丁词元。
  3. 对每个表条目，在 `entry.allKeywords`（全部四种语言，与 UI 语言区域无关）上取最佳 [`_scoreKeyword`](#scorekeyword)；保留得分大于 0 的条目及其表索引。
  4. 按得分降序、再按表索引升序排序。
  5. 按此顺序输出 emoji，跳过重复，直到收集满 `max` 个。
- **用法：**
  ```dart
  final next = suggestEmojis(_titleController.text);
  ```
  （调用方：两个任务对话框中的 `initState` 和 `_onTitleChanged`）
- **备注：** 对给定标题和表是确定性的。过短的输入不产生建议：`ma` 低于 3 个字母的前缀下限，也不匹配任何完整关键词。`test/emoji_suggester_test.dart` 固定的示例包括 `Reply to email` → 📧、`取快递` → 📦、`繳電費` → ⚡、`荷物を受け取る` → 📦、`买iPhone` → 📱、`ＭＡＩＬ` → ✉️。

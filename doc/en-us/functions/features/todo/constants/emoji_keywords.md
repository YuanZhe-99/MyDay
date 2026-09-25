# lib/features/todo/constants/emoji_keywords.dart

The curated multilingual keyword table behind title-driven emoji suggestions. Each
`EmojiKeywordEntry` pairs one emoji with keyword lists in English, Simplified Chinese, Traditional
Chinese, and Japanese; [`suggestEmojis`](../utils/emoji_suggester.md#suggestemojis) matches a task
title against every language at once, regardless of the UI locale. The table has 188 entries in
themed groups (writing and work, communication, arrows and status, time, delivery and shopping,
money, gifts and events, health, exercise, home chores, family and pets, transport and travel,
places, leisure, food and drink, rest and weather, personal items). How to extend it is described in
[Todo — Emoji suggestions](../../../../features/todo.md#emoji-suggestions).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`EmojiKeywordEntry` (constructor)](#emojikeywordentry-new) | constructor (`EmojiKeywordEntry`) | A | Describe one suggestible emoji and its search keywords per language. |
| `allKeywords` | getter (`EmojiKeywordEntry`) | B | Return every keyword of every language as one iterable (`en`, then `zhHans`, `zhHant`, `ja`). |
| [`emojiKeywordTable`](#emojikeywordtable) | top-level `const` | A | The curated emoji keyword table used by `suggestEmojis`. |

`grep -c 'Purpose:' lib/features/todo/constants/emoji_keywords.dart` reports 3, matching the three
rows. The file-level comment above `library;` has no `Purpose:` block. The five final fields of
`EmojiKeywordEntry` (`emoji`, `en`, `zhHans`, `zhHant`, `ja`) carry no `Purpose:` block and are
described in the constructor entry instead of getting rows.

## Documentation

### `const EmojiKeywordEntry(this.emoji, {this.en = const [], this.zhHans = const [], this.zhHant = const [], this.ja = const []})` <a id="emojikeywordentry-new"></a>
- **Kind:** const constructor of `EmojiKeywordEntry`
- **Source:** `lib/features/todo/constants/emoji_keywords.dart` (line 18; class at line 5)
- **Purpose:** One row of the keyword table: an emoji and the words that should suggest it.
- **Inputs:** `emoji` (positional); `en`, `zhHans`, `zhHant`, `ja` — keyword lists, each
  defaulting to empty.
- **Returns:** A new `EmojiKeywordEntry`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:**
  ```dart
  EmojiKeywordEntry(
    '📧',
    en: ['email', 'emails', 'e-mail', 'inbox', 'gmail', 'outlook'],
    zhHans: ['邮件', '电子邮件', '回邮件', '发邮件', '邮箱'],
    zhHant: ['郵件', '電子郵件', '回郵件', '寄郵件', '電郵'],
    ja: ['メール', 'めーる', 'eメール', '受信箱'],
  ),
  ```
- **Notes:** Keywords must be lowercase, trimmed, and non-empty, and every table entry must have at
  least one keyword in each of the four languages — both rules are enforced by
  `test/emoji_suggester_test.dart`, even though the constructor itself defaults the lists to empty.
  A keyword containing any CJK character matches as a substring; any other keyword is split into
  Latin tokens and matched as a whole token or phrase (see
  [`_scoreKeyword`](../utils/emoji_suggester.md#scorekeyword)), so punctuation such as the hyphen
  in `e-mail` acts as a token separator.

### `const List<EmojiKeywordEntry> emojiKeywordTable` <a id="emojikeywordtable"></a>
- **Kind:** top-level `const`
- **Source:** `lib/features/todo/constants/emoji_keywords.dart` (lines 46-1856)
- **Purpose:** The default `table` argument of `suggestEmojis`.
- **Inputs:** None.
- **Returns:** None (constant).
- **Side effects:** None.
- **Algorithm:** None — a literal list of 188 entries. Covers every emoji in
  [`commonTaskEmojis`](task_emojis.md) plus extras that are only reachable through suggestions
  (for example 🥛, ⚡, 💬).
- **Usage:**
  ```dart
  List<String> suggestEmojis(
    String title, {
    int max = 8,
    List<EmojiKeywordEntry> table = emojiKeywordTable,
  })
  ```
- **Notes:**
  - **Order is the tie-breaker.** Equal scores sort by table index, so put the more common reading
    of a shared keyword in the earlier entry.
  - **Each emoji appears once** (test-enforced); add keywords to the existing entry rather than
    adding a second one.
  - **Filler is excluded on purpose.** Phrases that open many titles without naming an object
    ("don't forget", 别忘了, 忘れずに) are deliberately left out — the comment on the 📌 entry
    records why: they would outrank the object that follows ("don't forget the keys" should suggest
    🔑).

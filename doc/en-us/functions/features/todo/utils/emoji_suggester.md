# lib/features/todo/utils/emoji_suggester.dart

Pure-Dart, IME-style emoji suggestions for task titles. The file has no Flutter dependency and no
state: [`suggestEmojis`](#suggestemojis) normalizes the title, scores every entry of
[`emojiKeywordTable`](../constants/emoji_keywords.md#emojikeywordtable) by its best-matching
keyword in any language, and returns the top distinct emojis. Both task dialogs call it on every
title change (see [`AddTaskDialog._onTitleChanged`](../widgets/add_task_dialog.md#ontitlechanged));
the user-facing behavior is described in
[Todo — Emoji suggestions](../../../../features/todo.md#emoji-suggestions).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `_cjkCharWeight` | top-level `const` (private) | B | Score per matched CJK keyword character: `30`. |
| `_latinCharWeight` | top-level `const` (private) | B | Score per matched Latin keyword letter: `10`. |
| `_exactBonus` | top-level `const` (private) | B | Bonus for an exact whole-token, phrase, or whole-title match: `5`. |
| `_inflections` | top-level `const` (private) | B | English suffixes a title token may add to a keyword: `s`, `es`, `ed`, `ing`, `er`, `ers`. |
| [`normalizeTitle`](#normalizetitle) | top-level function | A | Normalize a task title for keyword matching. |
| [`containsCjk`](#containscjk) | top-level function | A | Report whether text contains CJK ideographs, kana or Hangul. |
| [`latinTokens`](#latintokens) | top-level function | A | Split normalized text into its Latin letter/digit tokens. |
| [`_scoreKeyword`](#scorekeyword) | top-level function (private) | A | Score one keyword against a normalized title. |
| [`suggestEmojis`](#suggestemojis) | top-level function | A | Return up to `max` emojis whose keywords match the title, best first. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/todo/utils/emoji_suggester.dart` reports 5,
while the table has 9 rows. The four scoring constants carry plain `///` comments rather than
`Purpose:` blocks, but they define the ranking and are listed. The two private regular expressions
(`_whitespace`, `_latinToken`) are not listed; they are described in the
[`normalizeTitle`](#normalizetitle) and [`latinTokens`](#latintokens) entries.

## Documentation

### `String normalizeTitle(String title)` <a id="normalizetitle"></a>
- **Kind:** top-level function
- **Source:** `lib/features/todo/utils/emoji_suggester.dart` (lines 30-42)
- **Purpose:** Bring a title into the form keywords are written in, so matching is case-, width-,
  and spacing-insensitive.
- **Inputs:** `title` — raw title text.
- **Returns:** `String` — lowercased and trimmed, with full-width ASCII folded to half-width and
  every whitespace run (`\s+`, the private `_whitespace` regex) collapsed to one space.
- **Side effects:** None.
- **Algorithm:**
  1. Walk the title's runes: U+FF01–U+FF5E becomes the rune minus `0xFEE0` (so `Ｍ` → `M`), the
     ideographic space U+3000 becomes a normal space, everything else is copied.
  2. Lowercase, trim, and collapse whitespace runs.
- **Usage:**
  ```dart
  normalizeTitle('  Ｒｅｐｌｙ　TO   Mail '); // 'reply to mail'
  ```
- **Notes:** Dart core has no NFKC normalization, so only that full-width block and the ideographic
  space are folded; half-width katakana, for example, is left as is.

### `bool containsCjk(String text)` <a id="containscjk"></a>
- **Kind:** top-level function
- **Source:** `lib/features/todo/utils/emoji_suggester.dart` (lines 50-62)
- **Purpose:** Decide whether a keyword is matched as a CJK substring or as Latin tokens.
- **Inputs:** `text`.
- **Returns:** `bool` — `true` if any rune falls in one of: kana U+3040–30FF, CJK Extension A
  U+3400–4DBF, CJK Unified Ideographs U+4E00–9FFF, CJK Compatibility U+F900–FAFF, Hangul syllables
  U+AC00–D7AF, half-width katakana U+FF66–FF9F.
- **Side effects:** None.
- **Algorithm:** Linear scan over runes, returning on the first hit.
- **Usage:**
  ```dart
  if (containsCjk(keyword)) {
    if (!title.contains(keyword)) return 0;
    // ...
  ```
- **Notes:** Applied to the *keyword*, not the title. A mixed keyword such as `eメール` counts as
  CJK and is matched as a substring.

### `List<String> latinTokens(String text)` <a id="latintokens"></a>
- **Kind:** top-level function
- **Source:** `lib/features/todo/utils/emoji_suggester.dart` (lines 69-70)
- **Purpose:** Extract the Latin words of a normalized string.
- **Inputs:** `text` — already normalized (lowercase).
- **Returns:** `List<String>` — every `[a-z0-9]+` run (the private `_latinToken` regex), in order.
- **Side effects:** None.
- **Algorithm:** `RegExp.allMatches` over the text.
- **Usage:**
  ```dart
  final tokens = latinTokens(norm);
  ```
- **Notes:** Latin runs inside CJK text are found too, so `买iphone` yields `['iphone']`.
  Apostrophes and hyphens split tokens (`don't` → `don`, `t`).

### `int _scoreKeyword(String keyword, String title, List<String> tokens)` <a id="scorekeyword"></a>
- **Kind:** top-level function (private)
- **Source:** `lib/features/todo/utils/emoji_suggester.dart` (lines 80-123)
- **Purpose:** Score how well one keyword matches the title; 0 means no match.
- **Inputs:** `keyword`; `title` — normalized; `tokens` — `latinTokens(title)`, computed once by
  the caller.
- **Returns:** `int` score.
- **Side effects:** None.
- **Algorithm:**
  1. **CJK keyword** (`containsCjk(keyword)`): match only if `title.contains(keyword)`. Score is
     `rune count × 30`, plus `5` when the whole title equals the keyword. CJK has no word
     boundaries, so a substring is the only practical test.
  2. **Latin keyword**: return 0 if the title or the keyword has no Latin tokens.
  3. **Multi-token keyword** (for example `credit card`): match only as a contiguous run of equal
     tokens in the title. Score is `total letters × 10 + 5`.
  4. **Single-token keyword** `k`, checked against every title token `t`, keeping the best:
     - `t == k`: `k.length × 10 + 5`.
     - `k` has at least 3 letters and `t` is `k` plus one suffix from `_inflections`
       (`emails`, `cooking`): `k.length × 10`. Arbitrary extensions do not count, so the title
       token `card` does not match the keyword `car`.
     - Only for the **last** token, which the user may still be typing: `t` has at least 3 letters
       and `k` starts with `t` (`emai` → `email`): `t.length × 10`. Earlier tokens are finished
       words, so they never prefix-match.
- **Usage:**
  ```dart
  for (final kw in entry.allKeywords) {
    final s = _scoreKeyword(kw, norm, tokens);
    if (s > best) best = s;
  }
  ```
- **Notes:** There is no bonus for where in the title a match occurs. Titles usually open with a
  verb ("reply to email", "取快递") and the object noun that follows is the better emoji, so a
  position bonus would favor the wrong word. Longer matches outrank shorter ones through the
  per-character weights; a CJK character weighs three times a Latin letter because it carries
  roughly as much meaning as a short word fragment.

### `List<String> suggestEmojis(String title, {int max = 8, List<EmojiKeywordEntry> table = emojiKeywordTable})` <a id="suggestemojis"></a>
- **Kind:** top-level function
- **Source:** `lib/features/todo/utils/emoji_suggester.dart` (lines 131-162)
- **Purpose:** Rank the emojis whose keywords match a task title.
- **Inputs:** `title` — raw title; `max` — cap on results (default 8); `table` — keyword table
  (default `emojiKeywordTable`; tests inject a small one).
- **Returns:** `List<String>` — up to `max` distinct emojis, best first; `const []` when the
  normalized title is empty or `max <= 0`.
- **Side effects:** None.
- **Algorithm:**
  1. Normalize the title with [`normalizeTitle`](#normalizetitle); return empty if nothing is left.
  2. Compute the title's Latin tokens once.
  3. For each table entry, take the best [`_scoreKeyword`](#scorekeyword) over
     `entry.allKeywords` (all four languages, regardless of UI locale); keep entries scoring above
     0 together with their table index.
  4. Sort by score descending, then by table index ascending.
  5. Emit emojis in that order, skipping duplicates, until `max` are collected.
- **Usage:**
  ```dart
  final next = suggestEmojis(_titleController.text);
  ```
  (callers: `initState` and `_onTitleChanged` in both task dialogs)
- **Notes:** Deterministic for a given title and table. Too-short input suggests nothing: `ma`
  is under the 3-letter prefix minimum and matches no whole keyword. Examples pinned by
  `test/emoji_suggester_test.dart` include `Reply to email` → 📧, `取快递` → 📦, `繳電費` → ⚡,
  `荷物を受け取る` → 📦, `买iPhone` → 📱, and `ＭＡＩＬ` → ✉️.

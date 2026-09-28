# lib/features/ai/services/insight_prompts.dart

The vocabulary and wording of the insight cards: which card (`InsightModule`), Todo's time bucket,
the `InsightFacts` a pure fact builder produces, the versioned system instructions and prompt, the
parser that turns the model's `<number>: <sentence>` reply into validated lines, and the small
formatters the fact builders use so that fingerprints do not move with float noise. The fact
builders are [`todo_insight_facts.md`](../../todo/services/todo_insight_facts.md),
[`finance_insight_facts.md`](../../finance/services/finance_insight_facts.md),
[`weight_insight_facts.md`](../../weight/services/weight_insight_facts.md) and
[`intimacy_insight_facts.md`](../../intimacy/services/intimacy_insight_facts.md); the consumer is
[`insight_service.md`](insight_service.md); line validation comes from
[`output_validation.md`](output_validation.md). See
[On-device AI — What each card is given](../../../../on-device-ai.md#what-each-card-is-given) and
[Cache and fingerprint](../../../../on-device-ai.md#cache-and-fingerprint).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `insightPromptVersion` | top-level const (`int`) | B | Prompt version `2` (v1.5.1), part of every fingerprint; bump when wording or builder output changes. |
| `insightLineMaxLength` | top-level const (`int`) | B | `200`: the longest line kept, in characters; longer lines are dropped (`160` before v1.5.1). |
| `insightMaxOutputTokens` | top-level const (`int`) | B | `400`: the output budget for one card (`320` before v1.5.1). |
| `InsightModule` (enum) | enum | B | `todo` / `finance` / `weight` / `intimacy`; the name is the key in `ai_insights.json`. |
| `InsightTimeBucket` (enum) | enum | B | `none` / `morning` / `afternoon` / `evening`; only Todo uses anything but `none`. |
| [`todoBucketFor`](#todobucketfor) | top-level function | A | Pick the Todo card's time bucket for a local time. |
| [`InsightSlot` (constructor)](#insightslot-new) | const constructor (`InsightSlot`) | A | Create one numbered request. |
| [`InsightFacts` (constructor)](#insightfacts-new) | const constructor (`InsightFacts`) | A | Create a card's facts and requested answers. |
| [`canonical`](#canonical) | method (`InsightFacts`) | A | Serialize the facts for fingerprinting. |
| [`insightInstructions`](#insightinstructions) | top-level function | A | Build the system instructions for one card. |
| [`insightPrompt`](#insightprompt) | top-level function | A | Build the prompt: facts, then numbered requests. |
| `_answerLine` | private top-level variable (`RegExp`) | B | Matches `<number><sep><sentence>`, separators `:` `：` `.` `)` `、`. |
| `_bareNumber` | private top-level variable (`RegExp`) | B | Matches a number alone on a line, with an optional separator (`^\s*(\d+)\s*[:：.)、]?\s*$`). |
| `_heading` | private top-level variable (`RegExp`) | B | Matches a short line ending in a colon (`^\s*.{0,60}[:：]\s*$`), skipped in the unnumbered fallback. |
| `_inlineMarks` | private top-level variable (`RegExp`) | B | Code fences, `**`, `__` and backticks, removed before parsing. |
| [`parseInsightReply`](#parseinsightreply) | top-level function | A | Read and validate the model's numbered lines. |
| [`_normalize`](#_normalize) | private top-level function | A | Fold a line for the echoed-question comparison. |
| [`clipTitle`](#cliptitle) | top-level function | A | Shorten a user-typed title for a fact line. |
| [`factNumber`](#factnumber) | top-level function | A | Format a number without trailing zeros. |
| [`factDate`](#factdate) | top-level function | A | Format a date as `yyyy-MM-dd`. |
| [`factWeekday`](#factweekday) | top-level function | A | Name a weekday in English. |

`grep -c 'Purpose:' lib/features/ai/services/insight_prompts.dart` reports 12, matching the twelve
Tier A rows above.

**Reconciliation:** the table has 21 rows against 12 `Purpose:` blocks. The nine extra rows are
real top-level declarations with no `Purpose:` block: the three constants `insightPromptVersion`,
`insightLineMaxLength` and `insightMaxOutputTokens` and the two enums `InsightModule` and
`InsightTimeBucket` (each carrying only a plain doc comment), and the four private regular
expressions `_answerLine`, `_bareNumber`, `_heading` and `_inlineMarks` (no doc comment at all).
All nine are Tier B. The fields of `InsightSlot` and `InsightFacts` are not rows.

## Documentation

### `InsightTimeBucket todoBucketFor(DateTime now)` <a id="todobucketfor"></a>
- **Kind:** top-level function
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 31)
- **Purpose:** Pick the Todo card's mode for a local time.
- **Inputs:** `now` — local time.
- **Returns:** `InsightTimeBucket.morning` when `now.hour < 12`, `afternoon` when `< 18`,
  otherwise `evening`.
- **Side effects:** None.
- **Algorithm:** Two hour comparisons.
- **Usage:** `final bucket = todoBucketFor(now);`
  (`lib/features/todo/services/todo_insight_facts.dart`, `buildTodoInsightFacts`).
- **Notes:** Never returns `none`. The bucket is part of `InsightFacts.canonical()` and so of the
  Todo fingerprint: crossing 12:00 or 18:00 regenerates the card on the next page build.

### `const InsightSlot(this.id, this.ask)` <a id="insightslot-new"></a>
- **Kind:** const constructor of `InsightSlot`
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 50)
- **Purpose:** Create one numbered answer the model is asked for.
- **Inputs:** `id` — stable identifier (e.g. `plan`, `flowSummary`), part of the canonical form and
  stored per line in the cache; `ask` — the English request shown to the model.
- **Returns:** A new `InsightSlot`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** `InsightSlot('plan', "Today's plan, in one sentence."),`
  (`lib/features/todo/services/todo_insight_facts.dart`, `buildTodoInsightFacts`).
- **Notes:** Only the `id` enters the fingerprint, not the `ask` text; a wording change to `ask`
  must bump `insightPromptVersion` to replace cached cards.

### `const InsightFacts({required this.module, required this.bucket, required this.lines, required this.slots, this.quotedTerms = const []})` <a id="insightfacts-new"></a>
- **Kind:** const constructor of `InsightFacts`
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 80)
- **Purpose:** Create the app-computed facts for one card and the answers requested.
- **Inputs:** `module`; `bucket` (Todo's mode, else `none`); `lines` — English `- key: value`
  fact lines, already rounded and capped; `slots` — the numbered requests, in order;
  `quotedTerms` — user-typed words (task titles, category and subscription names) that may appear
  in an answer, default empty.
- **Returns:** A new `InsightFacts`.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:** `return InsightFacts(` at the end of each builder, e.g.
  `lib/features/todo/services/todo_insight_facts.dart` (`buildTodoInsightFacts`).
- **Notes:** Built only by the pure `*_insight_facts.dart` builders, which never put free-text notes
  or identifying details into `lines`. `quotedTerms` is not part of the canonical form.

### `String canonical()` <a id="canonical"></a>
- **Kind:** method of `InsightFacts`
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 93)
- **Purpose:** Serialize the facts for fingerprinting.
- **Inputs:** None.
- **Returns:** `String` — equal for equal facts.
- **Side effects:** None.
- **Algorithm:** Join with `\n`: `module.name`, `bucket.name`, every fact line, then the slot ids
  joined with `|`.
- **Usage:** `request.facts.canonical(),` (`lib/features/ai/services/insight_service.dart`,
  `insightFingerprint`).
- **Notes:** Changing any line, the bucket or the slot list changes the fingerprint; `ask` texts
  and `quotedTerms` do not.

### `String insightInstructions(InsightLanguage language)` <a id="insightinstructions"></a>
- **Kind:** top-level function
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 108)
- **Purpose:** Build the system instructions for one card.
- **Inputs:** `language` — see [`insight_language.md`](insight_language.md).
- **Returns:** `String` — one English paragraph.
- **Side effects:** None.
- **Algorithm:** A fixed template that states "The person's locale is `<localeTag>`", casts the
  model as a private assistant in a personal daily-life app, asks it, using only the facts given,
  to answer each numbered question with one short sentence in `<name>` under 30 words in the form
  `"<number>: <sentence>"`, tells it not to repeat the facts or the questions, to be concrete, calm
  and kind, and forbids medical, legal or investment advice, diagnoses and invented numbers.
- **Usage:** `instructions: insightInstructions(language),`
  (`lib/features/ai/services/insight_service.dart`, `AiInsightStore._generateParsed`).
- **Notes:** One template for every module. The locale sentence is the form Apple documents; the
  reply language is also named explicitly. Kept short on purpose: the reply shape is spelled out
  again at the end of [`insightPrompt`](#insightprompt) (v1.5.1). Any wording change needs an
  `insightPromptVersion` bump.

### `String insightPrompt(InsightFacts facts)` <a id="insightprompt"></a>
- **Kind:** top-level function
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 126)
- **Purpose:** Build the user prompt for one card.
- **Inputs:** `facts`.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** `Facts:` on the first line and each fact line; a blank line; `Questions:` and one
  line per slot `"<i+1>. <ask>"`; a blank line; `Reply with exactly N line(s), one per question, in
  this form:` (`line` when N is 1, `lines` otherwise); then one template line per slot
  `"<i+1>: <sentence>"`. Every line ends in `\n`.
- **Usage:** `prompt: insightPrompt(facts),`
  (`lib/features/ai/services/insight_service.dart`, `AiInsightStore._generateParsed`).
- **Notes:** The question numbers are 1-based and match what
  [`parseInsightReply`](#parseinsightreply) expects back. The trailing template is what keeps a
  small model on the `<number>: <sentence>` form, and the questions are headed `Questions:` rather
  than `Answer:` so they do not read as answers to be echoed (v1.5.1).

### `Map<int, String> parseInsightReply(String reply, int slotCount, String languageCode, {List<String> quotedTerms = const [], List<String> asks = const []})` <a id="parseinsightreply"></a>
- **Kind:** top-level function
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 167)
- **Purpose:** Read the model's `<number>: <sentence>` lines into validated sentences.
- **Inputs:** `reply` — the raw model output; `slotCount`; `languageCode` — `en`, `ja` or `zh`;
  `quotedTerms` — user-typed words removed before the script check; `asks` — the slot questions,
  so an echoed question is not taken as an answer (v1.5.1).
- **Returns:** `Map<int, String>` — 1-based slot number to cleaned sentence; empty when nothing
  valid was found.
- **Side effects:** None.
- **Algorithm:**
  1. Normalize every ask with [`_normalize`](#_normalize) into a set. Define `accept(raw)`:
     `cleanSentence(raw, maxLength: insightLineMaxLength)`, `null` when that is `null` (empty or
     over 200 characters) or when the normalized sentence equals one of the normalized asks; then
     replace every quoted term of at least 2 runes with a space in a copy and return `null` unless
     `matchesScript(copy, languageCode)` holds; otherwise return the cleaned (unreplaced) sentence.
  2. Remove only the inline marks `_inlineMarks` (code fences, `**`, `__`, backticks) from the
     reply and split on `\n`. `stripMarkdown` is deliberately **not** used: it also deletes a
     `1. ` list marker, which is the very number being looked for, and that is why a reply numbered
     `1. …` parsed to nothing in v1.5.0.
  3. For each line: a match against `_answerLine` (`^\s*(\d+)\s*[:：.)、]\s*(.+?)\s*$`) gives the
     body directly. Otherwise a match against `_bareNumber` (a number alone, optional separator)
     takes the next non-empty line as the body, unless there is none or it is itself an
     `_answerLine`; the loop index skips to that line. Any other line is ignored. Either match sets
     `numbered`.
  4. Skip numbers outside `1..slotCount` and numbers already seen (the first occurrence wins);
     store `accept(body)` under the number when non-null.
  5. If any line was numbered (or `slotCount` is 0), return. Otherwise walk the lines in order,
     skipping blank lines and lines matching `_heading` (up to 60 characters ending in a colon),
     and assign `accept(line)` to slots 1, 2, … until `slotCount` is reached; a line `accept`
     rejects still consumes its slot number.
- **Usage:**
  ```dart
  return parseInsightReply(
    reply,
    facts.slots.length,
    language.code,
    quotedTerms: facts.quotedTerms,
    asks: [for (final s in facts.slots) s.ask],
  );
  ```
  (`lib/features/ai/services/insight_service.dart`, `AiInsightStore._generateParsed`.)
- **Notes:** Three reply shapes are accepted, in order of preference: `<number>: <sentence>`; a
  number alone on a line with the sentence on the next; and, only when no line is numbered at all,
  the first `slotCount` prose lines in order. Over-long lines are dropped, never truncated. A
  sentence made only of quoted titles and numbers has no prose left for the script check and is
  dropped; a quoted term shorter than two runes is not removed, because it would gut the prose it
  appears in. Missing slots are allowed; the caller treats an empty map as a failure.
  `cleanSentence` and `matchesScript` are in [`output_validation.md`](output_validation.md).

### `String _normalize(String s)` <a id="_normalize"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 236)
- **Purpose:** Fold a line for the echoed-question comparison.
- **Inputs:** `s`.
- **Returns:** `String` — lower-case, with every run of whitespace and Unicode punctuation removed.
- **Side effects:** None.
- **Algorithm:** `toLowerCase()`, then `replaceAll(RegExp(r'[\s\p{P}]+', unicode: true), '')`.
- **Usage:** In [`parseInsightReply`](#parseinsightreply): once per ask to build the set, and once
  per cleaned sentence inside `accept`.
- **Notes:** Added in v1.5.1 so a model that echoes `Today's plan, in one sentence.` as its line 1
  does not get that echo shown as the answer. Only exact matches (after folding) are dropped; a
  paraphrased question still passes.

### `String clipTitle(String title, int maxRunes)` <a id="cliptitle"></a>
- **Kind:** top-level function
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 245)
- **Purpose:** Shorten a user-typed title for a fact line.
- **Inputs:** `title`; `maxRunes` — the longest result before the ellipsis, in Unicode code points.
- **Returns:** `String` — single-line and trimmed; when longer than `maxRunes`, the first
  `maxRunes` code points followed by `…`.
- **Side effects:** None.
- **Algorithm:** Collapse every whitespace run to one space and trim; compare the rune count; cut
  by runes and append `…` when needed.
- **Usage:** `String title(Task t) => clipTitle(t.title, maxTitleRunes);`
  (`lib/features/todo/services/todo_insight_facts.dart`, `buildTodoInsightFacts`, where
  `maxTitleRunes` defaults to 24 since v1.5.1); Finance clips category and subscription names to
  30.
- **Notes:** A clipped result is `maxRunes + 1` code points long. Cutting by runes keeps surrogate
  pairs intact but can still split a multi-code-point emoji sequence.

### `String factNumber(double value, [int digits = 1])` <a id="factnumber"></a>
- **Kind:** top-level function
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 257)
- **Purpose:** Format a number for a fact line.
- **Inputs:** `value`; `digits` — decimal places, default 1.
- **Returns:** `String` without trailing zeros (and without a trailing `.`).
- **Side effects:** None.
- **Algorithm:** `value.toStringAsFixed(digits)`; if it contains `.`, remove the regex
  `\.?0+$`.
- **Usage:** `'- Latest weight: ${factNumber(latest.weight)} kg on '`
  (`lib/features/weight/services/weight_insight_facts.dart`, `buildWeightInsightFacts`).
- **Notes:** Rounding to a fixed precision keeps fingerprints stable across float noise. Tiny
  negative values can format as `-0`.

### `String factDate(DateTime d)` <a id="factdate"></a>
- **Kind:** top-level function
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 268)
- **Purpose:** Format a date as `yyyy-MM-dd` for a fact line or the fingerprint.
- **Inputs:** `d`.
- **Returns:** `String` — zero-padded year (4), month (2) and day (2).
- **Side effects:** None.
- **Algorithm:** String interpolation with `padLeft`.
- **Usage:** `'date:${factDate(request.now)}',` (`lib/features/ai/services/insight_service.dart`,
  `insightFingerprint`); also every fact builder's `- Today:` line.
- **Notes:** Uses the calendar fields of `d` as given, so a local `DateTime` yields the local date.

### `String factWeekday(DateTime d)` <a id="factweekday"></a>
- **Kind:** top-level function
- **Source:** `lib/features/ai/services/insight_prompts.dart` (line 278)
- **Purpose:** Name a weekday in English for a fact line.
- **Inputs:** `d`.
- **Returns:** `String` — `Monday` … `Sunday`.
- **Side effects:** None.
- **Algorithm:** Index a const list with `d.weekday - 1`.
- **Usage:** `'- Today: ${factDate(today)} (${factWeekday(today)})',`
  (`lib/features/todo/services/todo_insight_facts.dart`, `buildTodoInsightFacts`).
- **Notes:** None.

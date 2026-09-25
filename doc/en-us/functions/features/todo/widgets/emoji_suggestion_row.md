# lib/features/todo/widgets/emoji_suggestion_row.dart

Stateless row of suggested-emoji chips shown under the title field of
[`AddTaskDialog`](add_task_dialog.md) and [`EditTaskDialog`](edit_task_dialog.md). It only
renders; the dialogs own the suggestion list (from
[`suggestEmojis`](../utils/emoji_suggester.md#suggestemojis)) and route a tapped chip to their
`_pickEmoji`, which counts as a manual choice.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `wrapKey` | static `const` (`EmojiSuggestionRow`) | B | `ValueKey('todoEmojiSuggestions')` on the chip `Wrap`, used by tests to find the row. |
| `EmojiSuggestionRow` (constructor) | constructor (`EmojiSuggestionRow`) | B | Create an emoji suggestion row from `suggestions`, `selected`, and `onSelected`. |
| [`build`](#build) | method (`EmojiSuggestionRow`) | A | Build the chip row for the current suggestions. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/todo/widgets/emoji_suggestion_row.dart`
reports 2, while the table has 3 rows. `wrapKey` has a plain `///` comment rather than a `Purpose:`
block, but it is part of the widget's public surface (tests depend on it), so it is listed.

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>
- **Kind:** method of `EmojiSuggestionRow`
- **Source:** `lib/features/todo/widgets/emoji_suggestion_row.dart` (lines 33-55)
- **Purpose:** Render one compact `ChoiceChip` per suggested emoji.
- **Inputs:** `context`. Uses the widget's `suggestions` (best first), `selected` (the dialog's
  current emoji, possibly `null`), and `onSelected`.
- **Returns:** `Widget` — `SizedBox.shrink()` when `suggestions` is empty, otherwise a
  `Semantics` container labelled `todoSuggestedIcons` around a `Wrap` (key `wrapKey`, spacing 6,
  run spacing 6).
- **Side effects:** None beyond building widgets; tapping a chip calls `onSelected(emoji)`.
- **Algorithm:**
  1. Return an empty box if there is nothing to suggest.
  2. Otherwise build one `ChoiceChip` per emoji: 18-point emoji label, `selected` when it equals
     `selected`, no checkmark, compact visual density.
- **Usage:**
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
- **Notes:** A `Wrap` rather than a horizontal list, so eight chips wrap onto a second line in a
  narrow dialog instead of overflowing or hiding behind a scroll. The chip for the auto-filled
  emoji shows as selected, which tells the user where the icon came from.

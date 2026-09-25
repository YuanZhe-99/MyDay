import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Wrapping row of suggested emoji chips shown under a task title field.
class EmojiSuggestionRow extends StatelessWidget {
  /// Key of the chip `Wrap`, used by tests to find the row.
  static const wrapKey = ValueKey('todoEmojiSuggestions');

  final List<String> suggestions;
  final String? selected;
  final ValueChanged<String> onSelected;

  /// Purpose: Create an emoji suggestion row.
  /// Inputs: `suggestions` (best first), `selected` (currently chosen emoji), `onSelected`.
  /// Returns: A new `EmojiSuggestionRow` instance.
  /// Side effects: None.
  /// Notes: Renders nothing when `suggestions` is empty.
  const EmojiSuggestionRow({
    super.key,
    required this.suggestions,
    required this.selected,
    required this.onSelected,
  });

  /// Purpose: Build the chip row for the current suggestions.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Uses `Wrap`, not a horizontal list, so eight chips never overflow a narrow dialog;
  /// the row is labelled for screen readers with `todoSuggestedIcons`.
  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      label: l10n.todoSuggestedIcons,
      child: Wrap(
        key: wrapKey,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final emoji in suggestions)
            ChoiceChip(
              label: Text(emoji, style: const TextStyle(fontSize: 18)),
              selected: selected == emoji,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onSelected(emoji),
            ),
        ],
      ),
    );
  }
}

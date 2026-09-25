/// Title-driven emoji suggestions for tasks, IME-style and language-independent.
library;

import '../constants/emoji_keywords.dart';

final RegExp _whitespace = RegExp(r'\s+');
final RegExp _latinToken = RegExp(r'[a-z0-9]+');

/// Score weight per matched character of a CJK keyword. A CJK character carries roughly as much
/// meaning as a short Latin word fragment, so it is weighted three times a Latin letter.
const int _cjkCharWeight = 30;

/// Score weight per matched letter of a Latin keyword.
const int _latinCharWeight = 10;

/// Bonus for an exact whole-token (or whole-title) match. There is deliberately no bonus for
/// position: titles usually open with a verb ("reply to email", "取快递"), and the object noun
/// that follows is the better emoji.
const int _exactBonus = 5;

/// English suffixes a title token may add to a keyword and still count as that keyword.
const Set<String> _inflections = {'s', 'es', 'ed', 'ing', 'er', 'ers'};

/// Purpose: Normalize a task title for keyword matching.
/// Inputs: `title`.
/// Returns: Lowercased, trimmed text with full-width ASCII folded to half-width and whitespace
/// runs collapsed to one space.
/// Side effects: None.
/// Notes: Dart core has no NFKC, so only U+FF01–U+FF5E and the ideographic space are folded.
String normalizeTitle(String title) {
  final buf = StringBuffer();
  for (final rune in title.runes) {
    if (rune >= 0xFF01 && rune <= 0xFF5E) {
      buf.writeCharCode(rune - 0xFEE0);
    } else if (rune == 0x3000) {
      buf.write(' ');
    } else {
      buf.writeCharCode(rune);
    }
  }
  return buf.toString().toLowerCase().trim().replaceAll(_whitespace, ' ');
}

/// Purpose: Report whether text contains CJK ideographs, kana or Hangul.
/// Inputs: `text`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Ranges: kana 3040–30FF, CJK Ext A 3400–4DBF, CJK 4E00–9FFF, compatibility F900–FAFF,
/// Hangul AC00–D7AF, half-width katakana FF66–FF9F. Decides substring vs token matching.
bool containsCjk(String text) {
  for (final r in text.runes) {
    if ((r >= 0x3040 && r <= 0x30FF) ||
        (r >= 0x3400 && r <= 0x4DBF) ||
        (r >= 0x4E00 && r <= 0x9FFF) ||
        (r >= 0xF900 && r <= 0xFAFF) ||
        (r >= 0xAC00 && r <= 0xD7AF) ||
        (r >= 0xFF66 && r <= 0xFF9F)) {
      return true;
    }
  }
  return false;
}

/// Purpose: Split normalized text into its Latin letter/digit tokens.
/// Inputs: `text` (already normalized).
/// Returns: `List<String>` of `[a-z0-9]+` runs in order.
/// Side effects: None.
/// Notes: Latin runs embedded in CJK text (for example "买iphone") are still found.
List<String> latinTokens(String text) =>
    _latinToken.allMatches(text).map((m) => m[0]!).toList();

/// Purpose: Score one keyword against a normalized title.
/// Inputs: `keyword`; `title` (normalized); `tokens` (the title's Latin tokens).
/// Returns: `int` score, 0 when the keyword does not match.
/// Side effects: None.
/// Notes: CJK keywords match as substrings. Multi-token Latin keywords match as a contiguous
/// token phrase. Single-token Latin keywords match a whole token, the keyword plus one of
/// `_inflections` ("emails", "cooking"; "card" does not match "car"), or — for the last token
/// only, while the user is still typing — a token of at least 3 letters the keyword starts with.
int _scoreKeyword(String keyword, String title, List<String> tokens) {
  if (containsCjk(keyword)) {
    if (!title.contains(keyword)) return 0;
    final score = keyword.runes.length * _cjkCharWeight;
    return title == keyword ? score + _exactBonus : score;
  }

  if (tokens.isEmpty) return 0;
  final kwTokens = latinTokens(keyword);
  if (kwTokens.isEmpty) return 0;

  if (kwTokens.length > 1) {
    final letters = kwTokens.fold<int>(0, (sum, t) => sum + t.length);
    for (var i = 0; i + kwTokens.length <= tokens.length; i++) {
      var all = true;
      for (var j = 0; j < kwTokens.length; j++) {
        if (tokens[i + j] != kwTokens[j]) {
          all = false;
          break;
        }
      }
      if (all) return letters * _latinCharWeight + _exactBonus;
    }
    return 0;
  }

  final k = kwTokens.single;
  var best = 0;
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    var score = 0;
    if (t == k) {
      score = k.length * _latinCharWeight + _exactBonus;
    } else if (k.length >= 3 &&
        t.startsWith(k) &&
        _inflections.contains(t.substring(k.length))) {
      score = k.length * _latinCharWeight;
    } else if (i == tokens.length - 1 && t.length >= 3 && k.startsWith(t)) {
      score = t.length * _latinCharWeight;
    }
    if (score > best) best = score;
  }
  return best;
}

/// Purpose: Return up to `max` emojis whose keywords match the title, best first.
/// Inputs: `title`; `max` (default 8); `table` (default `emojiKeywordTable`, injectable for tests).
/// Returns: `List<String>` of distinct emojis; empty when the normalized title is empty.
/// Side effects: None.
/// Notes: Each entry scores the best of its keywords in every language. Results sort by score
/// descending, then table order, so the output is deterministic for a given title.
List<String> suggestEmojis(
  String title, {
  int max = 8,
  List<EmojiKeywordEntry> table = emojiKeywordTable,
}) {
  final norm = normalizeTitle(title);
  if (norm.isEmpty || max <= 0) return const [];
  final tokens = latinTokens(norm);

  final scored = <({int score, int index, String emoji})>[];
  for (var i = 0; i < table.length; i++) {
    final entry = table[i];
    var best = 0;
    for (final kw in entry.allKeywords) {
      final s = _scoreKeyword(kw, norm, tokens);
      if (s > best) best = s;
    }
    if (best > 0) scored.add((score: best, index: i, emoji: entry.emoji));
  }
  scored.sort((a, b) {
    final c = b.score.compareTo(a.score);
    return c != 0 ? c : a.index.compareTo(b.index);
  });

  final out = <String>[];
  for (final s in scored) {
    if (out.contains(s.emoji)) continue;
    out.add(s.emoji);
    if (out.length >= max) break;
  }
  return out;
}

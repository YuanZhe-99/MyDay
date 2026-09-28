import 'insight_language.dart';
import 'output_validation.dart';

/// Bump when any wording below, or the facts a builder emits, changes in a
/// way that should replace cached insights. Part of every fingerprint.
const int insightPromptVersion = 1;

/// The longest insight line shown, in characters. Longer lines are dropped,
/// not truncated.
const int insightLineMaxLength = 160;

/// Output budget for one card. Up to four sentences of under 30 words.
const int insightMaxOutputTokens = 320;

/// Which card an insight belongs to. The name is the key in
/// `ai_insights.json`, so it must never be renamed.
enum InsightModule { todo, finance, weight, intimacy }

/// Todo's time-of-day modes. The other modules always use [none].
enum InsightTimeBucket { none, morning, afternoon, evening }

/// Purpose: Pick the Todo card's mode for a local time.
/// Inputs: `now` — local time.
/// Returns: `InsightTimeBucket` — morning before 12:00, afternoon from 12:00
/// to before 18:00, evening from 18:00.
/// Side effects: None.
/// Notes: Part of the Todo fingerprint, so crossing a boundary regenerates
/// on the next page build.
InsightTimeBucket todoBucketFor(DateTime now) {
  if (now.hour < 12) return InsightTimeBucket.morning;
  if (now.hour < 18) return InsightTimeBucket.afternoon;
  return InsightTimeBucket.evening;
}

/// One numbered answer the model is asked for.
class InsightSlot {
  /// Stable identifier, part of the canonical form.
  final String id;

  /// The English request shown to the model.
  final String ask;

  /// Purpose: Create a slot.
  /// Inputs: `id`, `ask`.
  /// Returns: A new `InsightSlot`.
  /// Side effects: None.
  /// Notes: None.
  const InsightSlot(this.id, this.ask);
}

/// The app-computed facts for one card and the answers requested.
///
/// Built only by the pure `*_insight_facts.dart` builders, which never put
/// free-text notes or identifying details into [lines].
class InsightFacts {
  /// Which card.
  final InsightModule module;

  /// Todo's mode, or [InsightTimeBucket.none].
  final InsightTimeBucket bucket;

  /// English `- key: value` fact lines, already rounded and capped.
  final List<String> lines;

  /// The numbered answers requested, in order.
  final List<InsightSlot> slots;

  /// Words the user typed (task titles) that may appear in an answer; they
  /// are ignored by the script check so a Chinese sentence that quotes an
  /// English title is not discarded.
  final List<String> quotedTerms;

  /// Purpose: Create a facts value.
  /// Inputs: see fields.
  /// Returns: A new `InsightFacts`.
  /// Side effects: None.
  /// Notes: None.
  const InsightFacts({
    required this.module,
    required this.bucket,
    required this.lines,
    required this.slots,
    this.quotedTerms = const [],
  });

  /// Purpose: Serialize the facts for fingerprinting.
  /// Inputs: None.
  /// Returns: `String` — stable for equal facts.
  /// Side effects: None.
  /// Notes: Changing any line or slot changes the fingerprint.
  String canonical() => [
    module.name,
    bucket.name,
    ...lines,
    slots.map((s) => s.id).join('|'),
  ].join('\n');
}

/// Purpose: Build the system instructions for one card.
/// Inputs: `language`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: Written in English with the locale sentence Apple documents; the
/// reply language is named explicitly. One template for every module.
String insightInstructions(InsightLanguage language) =>
    "The person's locale is ${language.localeTag}. "
    'You are a private assistant inside a personal daily-life app. '
    'Using only the facts given, answer each numbered request with one '
    'short sentence in ${language.name}, under 30 words, in the form '
    '"<number>: <sentence>" and nothing else. Be concrete, calm and kind. '
    'Never give medical, legal or investment advice, never diagnose, and '
    'never invent numbers that are not in the facts.';

/// Purpose: Build the prompt for one card.
/// Inputs: `facts`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: Facts first, then the numbered requests.
String insightPrompt(InsightFacts facts) {
  final b = StringBuffer('Facts:\n');
  for (final line in facts.lines) {
    b.writeln(line);
  }
  b.writeln('Answer:');
  for (var i = 0; i < facts.slots.length; i++) {
    b.writeln('${i + 1}. ${facts.slots[i].ask}');
  }
  return b.toString();
}

final _answerLine = RegExp(r'^\s*(\d+)\s*[:：.)、]\s*(.+?)\s*$');

/// Purpose: Read the model's `<number>: <sentence>` lines.
/// Inputs: `reply`; `slotCount`; `languageCode` — `en`, `ja` or `zh`;
/// `quotedTerms` — user-typed words removed before the script check.
/// Returns: `Map<int, String>` — slot number (1-based) to sentence.
/// Side effects: None.
/// Notes: Unknown or repeated numbers, over-long lines and lines in the wrong
/// script are dropped; Markdown is stripped first.
Map<int, String> parseInsightReply(
  String reply,
  int slotCount,
  String languageCode, {
  List<String> quotedTerms = const [],
}) {
  final out = <int, String>{};
  for (final line in stripMarkdown(reply).split('\n')) {
    final m = _answerLine.firstMatch(line);
    if (m == null) continue;
    final n = int.parse(m.group(1)!);
    if (n < 1 || n > slotCount || out.containsKey(n)) continue;
    final text = cleanSentence(m.group(2)!, maxLength: insightLineMaxLength);
    if (text == null) continue;
    var scriptText = text;
    for (final term in quotedTerms) {
      if (term.isNotEmpty) scriptText = scriptText.replaceAll(term, ' ');
    }
    // A sentence made only of quoted titles and numbers still has to carry
    // some prose in the right script.
    if (!matchesScript(scriptText, languageCode)) continue;
    out[n] = text;
  }
  return out;
}

/// Purpose: Shorten a user-typed title for a fact line.
/// Inputs: `title`, `maxRunes`.
/// Returns: `String` — single-line, trimmed, with `…` when cut.
/// Side effects: None.
/// Notes: Used by the fact builders.
String clipTitle(String title, int maxRunes) {
  final t = title.replaceAll(RegExp(r'\s+'), ' ').trim();
  final runes = t.runes.toList();
  if (runes.length <= maxRunes) return t;
  return '${String.fromCharCodes(runes.take(maxRunes))}…';
}

/// Purpose: Format a number for a fact line.
/// Inputs: `value`, `digits`.
/// Returns: `String` without trailing zeros.
/// Side effects: None.
/// Notes: Keeps fingerprints stable across float noise.
String factNumber(double value, [int digits = 1]) {
  final s = value.toStringAsFixed(digits);
  if (!s.contains('.')) return s;
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Purpose: Format a date as `yyyy-MM-dd` for a fact line.
/// Inputs: `d`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: Local calendar date.
String factDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Purpose: Name a weekday in English for a fact line.
/// Inputs: `d`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: None.
String factWeekday(DateTime d) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][d.weekday - 1];

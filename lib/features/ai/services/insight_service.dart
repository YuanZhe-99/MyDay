import 'dart:async';
import 'package:myapps_ai/myapps_ai.dart'
    show generateWithFallback, AiInsightCoordinator, AiInsightState;
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_insights_cache.dart';
import 'genai_backend.dart';
import 'insight_language.dart';
import 'insight_prompts.dart';
import 'on_device_ai_service.dart';

export 'package:myapps_ai/myapps_ai.dart' show AiInsightPhase, AiInsightState;

/// One card's request: its facts and the language to answer in.
class AiInsightRequest {
  /// The app-computed facts.
  final InsightFacts facts;

  /// The reply language.
  final InsightLanguage language;

  /// Local time the facts were computed for; its date is fingerprinted.
  final DateTime now;

  /// A plainer second try, or null: sent once when the model declines
  /// [facts] or returns nothing usable for them. Todo passes a counts-only
  /// version without task titles; Weight and Intimacy pass the v1.5.2
  /// prompt (v1.5.4). Not part of the fingerprint.
  final InsightFacts? fallbackFacts;

  /// The same facts with anonymous labels instead of names, or null: tried
  /// once, only after the model refuses [facts] on safety grounds
  /// (`guardrail`), before [fallbackFacts]. Intimacy passes it since 1.8.1.
  /// Its `labelNames` turn the labels the answer kept back into names. Not
  /// part of the fingerprint.
  final InsightFacts? guardrailFacts;

  /// Purpose: Create a request.
  /// Inputs: see fields.
  /// Returns: A new `AiInsightRequest`.
  /// Side effects: None.
  /// Notes: `fallbackFacts` must carry the same module, and its slot ids
  /// must be a subset of `facts`'s in the same order, so the card's
  /// sections still apply.
  const AiInsightRequest({
    required this.facts,
    required this.language,
    required this.now,
    this.fallbackFacts,
    this.guardrailFacts,
  });
}

/// Purpose: Name the model a status report describes.
/// Inputs: `report`.
/// Returns: `String` — e.g. `stable/full · nano-v3`, or `apple`.
/// Side effects: None.
/// Notes: Same rule as MyAnime!!!!!; a model update changes fingerprints.
String modelIdentityOf(GenAiStatusReport report) {
  final parts = [?report.variant, ?report.baseModelName];
  return parts.isEmpty ? 'apple' : parts.join(' · ');
}

/// Purpose: Write anonymous labels in a generated line back as the names
/// they stand for.
/// Inputs: `line`; `labelNames` — label (e.g. `partner A`) → name.
/// Returns: `String` — the line with every label it kept verbatim
/// (case-insensitive, optionally quoted) replaced by its name.
/// Side effects: None.
/// Notes: Longer labels are replaced first so `toy 1` never eats `toy 10`.
/// A label the model translated (`伴侣A`) is left as it is; the Intimacy
/// card explains any label still shown in its footnote.
String restoreLabelNames(String line, Map<String, String> labelNames) {
  if (labelNames.isEmpty) return line;
  final labels = labelNames.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  var out = line;
  for (final label in labels) {
    final words = label.split(' ').map(RegExp.escape).join(r'\s*');
    out = out.replaceAllMapped(
      RegExp('["“「『]?\\b$words\\b(?!\\d)["”」』]?', caseSensitive: false),
      (_) => labelNames[label]!,
    );
  }
  return out;
}

/// Purpose: Fingerprint one card request.
/// Inputs: `request`, `model` — from [modelIdentityOf].
/// Returns: `String` — hex SHA-256.
/// Side effects: None.
/// Notes: Covers the module, the prompt version, the language, the local
/// date, Todo's time bucket (inside the canonical facts), the model and the
/// facts. A change to any of them regenerates the card; nothing else does.
String insightFingerprint(AiInsightRequest request, String model) {
  final text = [
    request.facts.module.name,
    'prompt:$insightPromptVersion',
    'language:${request.language.localeTag}',
    'date:${factDate(request.now)}',
    'model:$model',
    request.facts.canonical(),
  ].join('\n');
  return sha256.convert(utf8.encode(text)).toString();
}

/// Owns the insight cards: the cache, what each card shows, and when to run
/// the model.
///
/// At most one generation per module runs or waits in the model queue; a
/// request that arrives meanwhile replaces the pending one, so rapid data
/// changes (ticking off several tasks) cost at most one extra run.
class AiInsightStore extends ChangeNotifier {
  /// Purpose: Create the store.
  /// Inputs: `ai` — the model service; `load`/`save`/`clear` — cache I/O,
  /// injectable for tests; `clock` — UTC clock for `generatedAt`.
  /// Returns: A new `AiInsightStore`.
  /// Side effects: None until first use.
  /// Notes: Defaults use `OnDeviceAiService.instance` and `AiInsightsCache`.
  AiInsightStore({
    OnDeviceAiService? ai,
    Future<AiInsights> Function()? load,
    Future<void> Function(AiInsights insights)? save,
    Future<void> Function()? clear,
    DateTime Function()? clock,
  }) : _aiOverride = ai,
       _load = load ?? AiInsightsCache.load,
       _save = save ?? AiInsightsCache.save,
       _clear = clear ?? AiInsightsCache.clear,
       _clock = clock ?? DateTime.now;

  /// The app-wide store.
  static AiInsightStore instance = AiInsightStore();

  /// Purpose: Replace the app-wide store.
  /// Inputs: `store`.
  /// Returns: None.
  /// Side effects: Swaps [instance].
  /// Notes: Tests only.
  @visibleForTesting
  static void setInstanceForTest(AiInsightStore store) => instance = store;

  final OnDeviceAiService? _aiOverride;
  final Future<AiInsights> Function() _load;
  final Future<void> Function(AiInsights insights) _save;
  final Future<void> Function() _clear;
  final DateTime Function() _clock;

  late final _coordinator =
      AiInsightCoordinator<InsightModule, AiInsightRequest>(
        keyOf: (request) => request.facts.module,
        fingerprintOf: insightFingerprint,
        modelOf: () => modelIdentityOf(_ai.report),
        canGenerate: () => _ai.canGenerate,
        load: () async => (await _load()).entries,
        save: (entries) => _save(AiInsights(entries)),
        clear: _clear,
        answer: (request, fingerprint, model, force) async {
          final (facts, parsed) = await _answer(request, force);
          if (parsed.isEmpty) return null;
          final numbers = parsed.keys.toList()..sort();
          return AiInsightEntry(
            fingerprint: fingerprint,
            lines: [
              for (final n in numbers)
                restoreLabelNames(
                  request.language.finish(parsed[n]!),
                  facts.labelNames,
                ),
            ],
            slots: [for (final n in numbers) facts.slots[n - 1].id],
            status: AiInsightStatus.ok,
            generatedAt: _clock().toUtc(),
            model: model,
            language: request.language.localeTag,
            promptVersion: insightPromptVersion,
          );
        },
        skippedEntry: (request, fingerprint, model) => AiInsightEntry(
          fingerprint: fingerprint,
          lines: const [],
          status: AiInsightStatus.skipped,
          generatedAt: _clock().toUtc(),
          model: model,
          language: request.language.localeTag,
          promptVersion: insightPromptVersion,
        ),
      )..addListener(notifyListeners);

  /// Purpose: Resolve the model service.
  /// Inputs: None.
  /// Returns: The injected service, else the current singleton.
  /// Side effects: None.
  /// Notes: Read on every use so `OnDeviceAiService.setInstanceForTest`
  /// takes effect without rebuilding the store.
  OnDeviceAiService get _ai => _aiOverride ?? OnDeviceAiService.instance;

  /// Purpose: Read shared state. Inputs: module. Returns: state. Side effects: None. Notes: App key.
  AiInsightState stateOf(InsightModule module) => _coordinator.stateOf(module);

  /// Purpose: Ensure current insight. Inputs: request, force. Returns: completion.
  /// Side effects: Shared generation/cache. Notes: Business callbacks remain here.
  Future<void> ensure(AiInsightRequest request, {bool force = false}) =>
      _coordinator.ensure(request, force: force);

  /// Purpose: Run the model once for one facts value and parse the reply.
  /// Inputs: `facts`, `language`, `force` — interactive priority when true.
  /// Returns: `Future<Map<int, String>>` — slot number to sentence; empty
  /// when nothing in the reply was usable.
  /// Side effects: Runs the model.
  /// Notes: Internal helper used within this file only. Throws
  /// `GenAiException` as the service does.
  Future<Map<int, String>> _generateParsed(
    InsightFacts facts,
    InsightLanguage language,
    bool force,
  ) async {
    final reply = await _ai.generate(
      instructions: insightInstructions(language),
      prompt: insightPrompt(facts),
      maxOutputTokens: insightMaxOutputTokens,
      priority: force ? AiPriority.interactive : AiPriority.background,
    );
    return parseInsightReply(
      reply,
      facts.slots.length,
      language.code,
      quotedTerms: facts.quotedTerms,
      asks: [for (final s in facts.slots) s.ask],
    );
  }

  /// Purpose: Answer a request, trying its guardrail and fallback facts
  /// when needed.
  /// Inputs: `request`, `force`.
  /// Returns: `Future<(InsightFacts, Map<int, String>)>` — the facts that
  /// were actually answered and the parsed reply, which may be empty.
  /// Side effects: Runs the model one to three times.
  /// Notes: Internal helper used within this file only. A safety refusal
  /// (`guardrail`) of the primary facts moves to `guardrailFacts` (labels
  /// instead of names) when the request has them; that variant, or the
  /// primary when there is none, then falls back to `fallbackFacts` on a
  /// refusal or a reply that parses to nothing — the one-step rule of
  /// `generateWithFallback`. An unusable primary reply skips the labelled
  /// variant: labels would not fix a reply in the wrong shape. A variant whose
  /// canonical form equals the facts already tried is skipped, since it
  /// would only repeat the refusal.
  Future<(InsightFacts, Map<int, String>)> _answer(
    AiInsightRequest request,
    bool force,
  ) async {
    final primary = request.facts;
    InsightFacts? distinct(InsightFacts? f, List<InsightFacts> tried) =>
        f != null && tried.every((t) => t.canonical() != f.canonical())
        ? f
        : null;
    final labelled = distinct(request.guardrailFacts, [primary]);
    Future<(InsightFacts, Map<int, String>)> withFallback(
      InsightFacts first,
      List<InsightFacts> tried,
    ) => generateWithFallback(
      primary: first,
      fallback: distinct(request.fallbackFacts, [...tried, first]),
      generate: (facts) => _generateParsed(facts, request.language, force),
      usable: (parsed) => parsed.isNotEmpty,
    );
    if (labelled == null) return withFallback(primary, const []);
    try {
      final parsed = await _generateParsed(primary, request.language, force);
      if (parsed.isNotEmpty) return (primary, parsed);
      final plain = distinct(request.fallbackFacts, [primary]);
      if (plain == null) return (primary, parsed);
      return (plain, await _generateParsed(plain, request.language, force));
    } on GenAiException catch (error) {
      if (error.failure != GenAiFailure.guardrail) rethrow;
      return withFallback(labelled, [primary]);
    }
  }

  /// Purpose: Clear cache. Inputs: None. Returns: completion. Side effects: Deletes local cache. Notes: Shared invalidation.
  Future<void> clearAll() => _coordinator.clearAll();

  /// Purpose: Release listeners. Inputs: None. Returns: None. Side effects: Disposes coordinator. Notes: App lifetime.
  @override
  void dispose() {
    _coordinator.removeListener(notifyListeners);
    _coordinator.dispose();
    super.dispose();
  }
}

/// A plain `Provider` over the singleton, like `onDeviceAiServiceProvider`,
/// so tests can override it; widgets listen to the store itself.
final aiInsightStoreProvider = Provider<AiInsightStore>(
  (ref) => AiInsightStore.instance,
);

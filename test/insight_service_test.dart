import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/ai/services/ai_insights_cache.dart';
import 'package:my_day/features/ai/services/genai_backend.dart';
import 'package:my_day/features/ai/services/insight_language.dart';
import 'package:my_day/features/ai/services/insight_prompts.dart';
import 'package:my_day/features/ai/services/insight_service.dart';
import 'package:my_day/features/ai/services/on_device_ai_service.dart';

import 'on_device_ai_test.dart' show FakeBackend;

const _en = InsightLanguage('en_US', 'English', 'en');

/// Purpose: Build a weight-card request with one fact line.
/// Inputs: `fact`, optional `language` and `now`.
/// Returns: `AiInsightRequest`.
/// Side effects: None.
/// Notes: Test helper.
AiInsightRequest _request(
  String fact, {
  InsightLanguage language = _en,
  DateTime? now,
}) => AiInsightRequest(
  facts: InsightFacts(
    module: InsightModule.weight,
    bucket: InsightTimeBucket.none,
    lines: ['- $fact'],
    slots: const [
      InsightSlot('trend', 'Describe the trend.'),
      InsightSlot('advice', 'One suggestion.'),
    ],
  ),
  language: language,
  now: now ?? DateTime(2026, 9, 28, 9),
);

/// Purpose: Test the insight store: caching, regeneration and failures.
/// Inputs: None.
/// Returns: None.
/// Side effects: None; the cache is in memory.
/// Notes: Uses the fake backend from `on_device_ai_test.dart`.
void main() {
  late FakeBackend backend;
  late OnDeviceAiService ai;
  late AiInsights saved;
  late int saves;
  late AiInsightStore store;

  int generations() =>
      backend.calls.where((c) => c.startsWith('generate:')).length;

  setUp(() async {
    backend = FakeBackend();
    ai = OnDeviceAiService(backend: backend);
    await ai.setEnabled(true);
    saved = AiInsights();
    saves = 0;
    store = AiInsightStore(
      ai: ai,
      load: () async => saved,
      save: (value) async {
        saved = value;
        saves++;
      },
      clear: () async => saved = AiInsights(),
      clock: () => DateTime.utc(2026, 9, 28, 1),
    );
  });

  test('generates once, caches, and answers from the cache after', () async {
    backend.generateReplies.add('1: Weight is steady.\n2: Keep walking.');
    await store.ensure(_request('weight 60 kg'));
    expect(generations(), 1);
    final state = store.stateOf(InsightModule.weight);
    expect(state.phase, AiInsightPhase.ready);
    expect(state.entry!.lines, ['Weight is steady.', 'Keep walking.']);
    expect(state.entry!.slots, ['trend', 'advice']);
    expect(saves, 1);

    await store.ensure(_request('weight 60 kg'));
    expect(generations(), 1);

    // A fresh store over the same file does not regenerate either.
    final reopened = AiInsightStore(ai: ai, load: () async => saved);
    await reopened.ensure(_request('weight 60 kg'));
    expect(generations(), 1);
    expect(reopened.stateOf(InsightModule.weight).entry!.lines.length, 2);
  });

  test('new facts, a new day, or a new model regenerate', () async {
    backend.generateReplies.addAll([
      '1: One.',
      '1: Two.',
      '1: Three.',
    ]);
    await store.ensure(_request('weight 60 kg'));
    await store.ensure(_request('weight 61 kg'));
    expect(generations(), 2);
    await store.ensure(
      _request('weight 61 kg', now: DateTime(2026, 9, 29, 9)),
    );
    expect(generations(), 3);

    final a = insightFingerprint(_request('x'), 'stable/full · nano-v3');
    final b = insightFingerprint(_request('x'), 'stable/full · nano-v4');
    final c = insightFingerprint(
      _request('x', language: const InsightLanguage('ja_JP', 'Japanese', 'ja')),
      'stable/full · nano-v3',
    );
    expect({a, b, c}.length, 3);
  });

  test('regenerate forces a run even when the cache matches', () async {
    backend.generateReplies.addAll(['1: First.', '1: Second.']);
    await store.ensure(_request('weight 60 kg'));
    await store.ensure(_request('weight 60 kg'), force: true);
    expect(generations(), 2);
    expect(store.stateOf(InsightModule.weight).entry!.lines, ['Second.']);
  });

  test('a guardrail refusal is cached as skipped', () async {
    backend.generateReplies.add(const GenAiException(GenAiFailure.guardrail));
    await store.ensure(_request('weight 60 kg'));
    final state = store.stateOf(InsightModule.weight);
    expect(state.phase, AiInsightPhase.ready);
    expect(state.entry!.status, AiInsightStatus.skipped);
    await store.ensure(_request('weight 60 kg'));
    expect(generations(), 1);
  });

  test('a failure keeps the previous text as stale and is not cached', () async {
    backend.generateReplies.addAll([
      '1: Old.',
      const GenAiException(GenAiFailure.failed),
    ]);
    await store.ensure(_request('weight 60 kg'));
    await store.ensure(_request('weight 61 kg'));
    final state = store.stateOf(InsightModule.weight);
    expect(state.phase, AiInsightPhase.failed);
    expect(state.failure, GenAiFailure.failed);
    expect(state.stale, isTrue);
    expect(state.entry!.lines, ['Old.']);
    expect(saves, 1);
    // A real failure is not retried by another page build.
    await store.ensure(_request('weight 61 kg'));
    expect(generations(), 2);
  });

  test('unusable output is a failure', () async {
    backend.generateReplies.add('Sure! Here is my answer without numbers.');
    await store.ensure(_request('weight 60 kg'));
    expect(store.stateOf(InsightModule.weight).phase, AiInsightPhase.failed);
    expect(saves, 0);
  });

  test('rapid changes run at most one extra generation', () async {
    backend.hold = Completer<String>();
    final first = store.ensure(_request('a'));
    await Future<void>.delayed(Duration.zero);
    unawaited(store.ensure(_request('b')));
    unawaited(store.ensure(_request('c')));
    await Future<void>.delayed(Duration.zero);
    expect(
      store.stateOf(InsightModule.weight).phase,
      AiInsightPhase.generating,
    );
    final hold = backend.hold!;
    backend.hold = null;
    backend.generateReplies.add('1: For c.');
    hold.complete('1: For a.');
    await first;
    expect(generations(), 2);
    expect(backend.calls.last, contains('- c'));
    final state = store.stateOf(InsightModule.weight);
    expect(state.phase, AiInsightPhase.ready);
    expect(state.entry!.lines, ['For c.']);
    expect(
      saved.entries[InsightModule.weight]!.fingerprint,
      insightFingerprint(_request('c'), modelIdentityOf(ai.report)),
    );
  });

  test('nothing runs while on-device AI is off', () async {
    await ai.setEnabled(false);
    backend.calls.clear();
    await store.ensure(_request('weight 60 kg'));
    expect(backend.calls, isEmpty);
    expect(store.stateOf(InsightModule.weight).phase, AiInsightPhase.idle);
  });

  test('clearAll forgets everything', () async {
    backend.generateReplies.addAll(['1: One.', '1: Again.']);
    await store.ensure(_request('weight 60 kg'));
    await store.clearAll();
    expect(saved.entries, isEmpty);
    expect(store.stateOf(InsightModule.weight).entry, isNull);
    await store.ensure(_request('weight 60 kg'));
    expect(generations(), 2);
  });

  test('Traditional Chinese output is converted', () async {
    final tw = InsightLanguage.forLocale(const Locale('zh', 'TW'))!;
    expect(tw.localeTag, 'zh_TW');
    backend.generateReplies.add('1: 体重保持稳定。');
    await store.ensure(_request('weight 60 kg', language: tw));
    expect(store.stateOf(InsightModule.weight).entry!.lines, ['體重保持穩定。']);
  });

  group('language choice', () {
    test('Apple rejecting Traditional falls back to Simplified + convert', () {
      final l = InsightLanguage.forLocale(
        const Locale('zh', 'TW'),
        localeSupported: false,
      )!;
      expect(l.localeTag, 'zh_CN');
      expect(l.toTraditional, isTrue);
    });

    test('an unsupported other language skips the card', () {
      expect(
        InsightLanguage.forLocale(const Locale('ja'), localeSupported: false),
        isNull,
      );
    });
  });

  group('reply parsing', () {
    test('keeps numbered lines in the right script only', () {
      final parsed = parseInsightReply(
        '**1:** 体重在下降。\n2: This is English.\n2: 继续保持。\n9: 多余的。',
        2,
        'zh',
      );
      expect(parsed, {1: '体重在下降。', 2: '继续保持。'});
    });

    test('drops over-long lines rather than truncating', () {
      final parsed = parseInsightReply('1: ${'a' * 200}', 1, 'en');
      expect(parsed, isEmpty);
    });

    test('quoted English titles do not fail a Chinese sentence', () {
      const line = '1: 先完成 Weekly report review 和 Team sync meeting。';
      expect(parseInsightReply(line, 1, 'zh'), isEmpty);
      expect(
        parseInsightReply(
          line,
          1,
          'zh',
          quotedTerms: const ['Weekly report review', 'Team sync meeting'],
        ),
        {1: '先完成 Weekly report review 和 Team sync meeting。'},
      );
    });

    test('the prompt lists facts then numbered requests', () {
      final prompt = insightPrompt(_request('weight 60 kg').facts);
      expect(
        prompt,
        'Facts:\n- weight 60 kg\nAnswer:\n1. Describe the trend.\n'
        '2. One suggestion.\n',
      );
      expect(insightInstructions(_en), contains('English'));
      expect(insightInstructions(_en), contains('never invent numbers'));
    });
  });
}

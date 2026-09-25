import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/todo/constants/emoji_keywords.dart';
import 'package:my_day/features/todo/constants/task_emojis.dart';
import 'package:my_day/features/todo/utils/emoji_suggester.dart';

/// Purpose: Run the title-driven emoji suggestion and keyword-table tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Pure tests; no widgets. Titles cover all four app languages.
void main() {
  group('suggestEmojis', () {
    /// Purpose: Assert the best suggestion for a title.
    /// Inputs: `title`, `emoji`.
    /// Returns: None.
    /// Side effects: Registers a test.
    /// Notes: None.
    void expectFirst(String title, String emoji) {
      test('"$title" suggests $emoji first', () {
        expect(suggestEmojis(title).firstOrNull, emoji);
      });
    }

    // English.
    expectFirst('mail', '✉️');
    expectFirst('Reply to email', '📧');
    expectFirst('pick up package', '📦');
    expectFirst('buy milk', '🥛');
    expectFirst('Pay credit card bill', '💳');
    expectFirst('dentist appointment', '🦷');
    expectFirst('take out the trash', '🗑️');
    expectFirst("don't forget the keys", '🔑');
    // Simplified Chinese.
    expectFirst('取快递', '📦');
    expectFirst('寄信', '✉️');
    expectFirst('买药', '💊');
    expectFirst('倒垃圾', '🗑️');
    expectFirst('回邮件', '📧');
    // Traditional Chinese.
    expectFirst('繳電費', '⚡');
    expectFirst('看牙醫', '🦷');
    // Japanese.
    expectFirst('荷物を受け取る', '📦');
    expectFirst('メール返信', '📧');
    expectFirst('ゴミ出し', '🗑️');
    expectFirst('確定申告', '🧾');
    // Mixed script and full-width input.
    expectFirst('买iPhone', '📱');
    expectFirst('ＭＡＩＬ', '✉️');

    test('an in-progress last word matches by prefix', () {
      expect(suggestEmojis('emai').first, '📧');
    });

    test('only real inflections extend a keyword', () {
      expect(suggestEmojis('reply to emails').first, '📧');
      expect(suggestEmojis('credit card'), isNot(contains('🚗')));
    });

    test('unrelated or too-short text suggests nothing', () {
      expect(suggestEmojis(''), isEmpty);
      expect(suggestEmojis('   '), isEmpty);
      expect(suggestEmojis('ma'), isEmpty);
      expect(suggestEmojis('相信自己'), isEmpty);
    });

    test('results are distinct, capped and deterministic', () {
      const title = 'buy milk bread eggs fruit coffee tea rice meat noodles';
      final a = suggestEmojis(title);
      expect(a.length, 8);
      expect(a.toSet().length, a.length);
      expect(suggestEmojis(title), a);
      expect(suggestEmojis(title, max: 3), a.take(3).toList());
    });

    test('a custom table can be injected', () {
      const table = [EmojiKeywordEntry('🧪', en: ['widget'])];
      expect(suggestEmojis('widget test', table: table), ['🧪']);
      expect(suggestEmojis('mail', table: table), isEmpty);
    });
  });

  group('normalizeTitle', () {
    test('folds full-width ASCII, case and whitespace', () {
      expect(normalizeTitle('  Ｒｅｐｌｙ　TO   Mail '), 'reply to mail');
    });
  });

  group('keyword table hygiene', () {
    test('keywords are lowercase, trimmed and non-empty', () {
      for (final entry in emojiKeywordTable) {
        for (final kw in entry.allKeywords) {
          expect(kw, isNotEmpty, reason: entry.emoji);
          expect(kw, kw.trim(), reason: '${entry.emoji} "$kw"');
          expect(kw, kw.toLowerCase(), reason: '${entry.emoji} "$kw"');
        }
      }
    });

    test('every entry has keywords in all four languages', () {
      for (final entry in emojiKeywordTable) {
        expect(entry.en, isNotEmpty, reason: entry.emoji);
        expect(entry.zhHans, isNotEmpty, reason: entry.emoji);
        expect(entry.zhHant, isNotEmpty, reason: entry.emoji);
        expect(entry.ja, isNotEmpty, reason: entry.emoji);
      }
    });

    test('each emoji appears once in the table', () {
      final emojis = emojiKeywordTable.map((e) => e.emoji).toList();
      expect(emojis.toSet().length, emojis.length);
    });

    test('the picker list is distinct single graphemes, all with keywords', () {
      expect(commonTaskEmojis.toSet().length, commonTaskEmojis.length);
      final keyed = emojiKeywordTable.map((e) => e.emoji).toSet();
      for (final emoji in commonTaskEmojis) {
        expect(emoji.characters.length, 1, reason: emoji);
        expect(keyed, contains(emoji), reason: emoji);
      }
    });

    test('the picker keeps the original 32 emojis first and in order', () {
      expect(commonTaskEmojis.take(4), ['📝', '🏃', '📖', '💪']);
      expect(commonTaskEmojis[31], '🧑‍🍳');
      expect(commonTaskEmojis, containsAll(['➡️', '✉️', '📦']));
    });
  });
}

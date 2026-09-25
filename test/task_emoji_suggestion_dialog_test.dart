import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/todo/models/task.dart';
import 'package:my_day/features/todo/widgets/add_task_dialog.dart';
import 'package:my_day/features/todo/widgets/edit_task_dialog.dart';
import 'package:my_day/features/todo/widgets/emoji_suggestion_row.dart';
import 'package:my_day/l10n/app_localizations.dart';

/// Purpose: Pump an app shell and open `dialog` on top of it.
/// Inputs: `tester`, `dialog`.
/// Returns: `Future<void>` once the dialog has settled.
/// Side effects: Pumps widgets.
/// Notes: English locale, so hint and button text are stable.
Future<void> _openDialog(WidgetTester tester, Widget dialog) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(),
    ),
  );
  final context = tester.element(find.byType(Scaffold));
  showDialog<Task>(context: context, builder: (_) => dialog);
  await tester.pumpAndSettle();
}

/// Purpose: Find the 44 dp emoji box's text for `emoji` (outside the chip row).
/// Inputs: `emoji`.
/// Returns: A `Finder` for the box glyph.
/// Side effects: None.
/// Notes: The chip row renders the same glyph, so chips are excluded explicitly.
Finder _boxEmoji(String emoji) => find.byWidgetPredicate(
      (w) => w is Text && w.data == emoji && w.style?.fontSize == 22,
    );

/// Purpose: Find the chip for `emoji` inside the suggestion row.
/// Inputs: `emoji`.
/// Returns: A `Finder` for the chip.
/// Side effects: None.
/// Notes: None.
Finder _chip(String emoji) => find.descendant(
      of: find.byKey(EmojiSuggestionRow.wrapKey),
      matching: find.widgetWithText(ChoiceChip, emoji),
    );

/// Purpose: Run the task dialog emoji suggestion widget tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Covers chip display, auto-fill, the manual-pick stop rule and clearing.
void main() {
  testWidgets('typing a title shows chips and auto-fills the icon', (tester) async {
    await _openDialog(tester, const AddTaskDialog());
    expect(find.byKey(EmojiSuggestionRow.wrapKey), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Reply to email');
    await tester.pump();
    expect(find.byKey(EmojiSuggestionRow.wrapKey), findsOneWidget);
    expect(_chip('📧'), findsOneWidget);
    expect(_boxEmoji('📧'), findsOneWidget);

    // Auto-fill follows the title while the user has not picked anything.
    await tester.enterText(find.byType(TextField).first, 'pick up package');
    await tester.pump();
    expect(_boxEmoji('📦'), findsOneWidget);

    // Clearing the title clears the auto-filled icon and the chips.
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    expect(find.byKey(EmojiSuggestionRow.wrapKey), findsNothing);
    expect(_boxEmoji('📦'), findsNothing);
    expect(find.byIcon(Icons.add_reaction_outlined), findsOneWidget);
  });

  testWidgets('a tapped chip sticks when the title changes', (tester) async {
    await _openDialog(tester, const AddTaskDialog());
    await tester.enterText(find.byType(TextField).first, 'Reply to email');
    await tester.pump();

    await tester.tap(_chip('💬'));
    await tester.pump();
    expect(_boxEmoji('💬'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'pick up package');
    await tester.pump();
    expect(_boxEmoji('💬'), findsOneWidget);
    expect(_chip('📦'), findsOneWidget);
  });

  testWidgets('editing a task that has an emoji never auto-fills', (tester) async {
    final task = Task(title: 'Old title', emoji: '🎯', type: TaskType.routineOnce);
    await _openDialog(tester, EditTaskDialog(task: task));

    await tester.enterText(find.byType(TextField).first, 'buy milk');
    await tester.pump();
    expect(_chip('🥛'), findsOneWidget);
    expect(_boxEmoji('🎯'), findsOneWidget);
    expect(_boxEmoji('🥛'), findsNothing);
  });

  testWidgets('opening an untouched task never auto-fills or dirties it', (tester) async {
    // The title field is autofocused; gaining focus places the cursor, which notifies the
    // controller's listeners without changing the text.
    final task = Task(title: 'buy milk', type: TaskType.routineOnce);
    await _openDialog(tester, EditTaskDialog(task: task));
    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    expect(_chip('🥛'), findsOneWidget);
    expect(_boxEmoji('🥛'), findsNothing);

    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(EditTaskDialog), findsNothing);
  });

  testWidgets('the picker grid scrolls to the new candidates', (tester) async {
    await _openDialog(tester, const AddTaskDialog());
    await tester.tap(find.byIcon(Icons.add_reaction_outlined));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('❗'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('❗'));
    await tester.pumpAndSettle();
    expect(_boxEmoji('❗'), findsOneWidget);
  });
}

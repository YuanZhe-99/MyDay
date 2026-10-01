import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/intimacy/models/intimacy_record.dart';
import 'package:my_day/features/intimacy/utils/thrust_timeline.dart';
import 'package:my_day/features/intimacy/widgets/add_record_dialog.dart';
import 'package:my_day/l10n/app_localizations.dart';

/// Purpose: Run AddRecordDialog widget regression tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: Covers editing a record whose partner was deleted while another
/// active partner exists, which used to crash the partner dropdown.
void main() {
  testWidgets(
    'editing a deleted-partner record builds and preserves its partner id',
    (WidgetTester tester) async {
      final record = IntimacyRecord(
        id: 'record-1',
        type: 'Regular',
        isSolo: false,
        partnerId: 'deleted-partner',
        pleasureLevel: 3,
        duration: const Duration(minutes: 15),
        datetime: DateTime(2026, 7, 1, 22),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(),
        ),
      );
      final context = tester.element(find.byType(Scaffold));
      final resultFuture = showDialog<IntimacyRecord>(
        context: context,
        builder: (_) => AddRecordDialog(
          record: record,
          partners: [Partner(id: 'partner-1', name: 'Alice')],
          toys: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AddRecordDialog), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final saved = await resultFuture;
      expect(saved?.partnerId, 'deleted-partner');
    },
  );

  group('timer prefill', () {
    final timeline = ThrustTimeline([
      const ThrustEvent(60000, 100),
      const ThrustEvent(120000, 50),
    ]);

    testWidgets('keeps exact seconds and the timeline when untouched', (
      tester,
    ) async {
      final (result,) = await _openDialog(
        tester,
        AddRecordDialog(
          prefillDuration: const Duration(minutes: 25, seconds: 10),
          initialThrustCount: 150,
          initialThrustCountUnit: 1,
          prefillThrustTimeline: timeline,
          partners: const [],
          toys: const [],
        ),
      );
      final saved = await _save(tester, result);
      expect(saved!.duration.inSeconds, 25 * 60 + 10);
      expect(saved.thrustTimeline!.events, timeline.events);
    });

    testWidgets('falls back to whole minutes once the duration is edited', (
      tester,
    ) async {
      final (result,) = await _openDialog(
        tester,
        AddRecordDialog(
          prefillDuration: const Duration(minutes: 25, seconds: 10),
          partners: const [],
          toys: const [],
        ),
      );
      await tester.enterText(_minutesField(), '26');
      final saved = await _save(tester, result);
      expect(saved!.duration.inSeconds, 26 * 60);
    });

    testWidgets('drops the timeline when the count no longer matches it', (
      tester,
    ) async {
      final (result,) = await _openDialog(
        tester,
        AddRecordDialog(
          prefillDuration: const Duration(minutes: 3),
          initialThrustCount: 150,
          initialThrustCountUnit: 1,
          prefillThrustTimeline: timeline,
          partners: const [],
          toys: const [],
        ),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Thrust count'),
        '200',
      );
      final saved = await _save(tester, result);
      expect(saved!.thrustCount, 200);
      expect(saved.thrustTimeline, isNull);
    });

    testWidgets('editing a record keeps its seconds and timeline', (
      tester,
    ) async {
      final record = IntimacyRecord(
        id: 'r1',
        type: 'Solo',
        isSolo: true,
        pleasureLevel: 4,
        duration: const Duration(minutes: 3, seconds: 42),
        thrustCount: 150,
        thrustCountUnit: 1,
        thrustTimeline: timeline,
        datetime: DateTime(2026, 9, 1, 22),
      );
      final (result,) = await _openDialog(
        tester,
        AddRecordDialog(record: record, partners: const [], toys: const []),
      );
      final saved = await _save(tester, result);
      expect(saved!.duration.inSeconds, 3 * 60 + 42);
      expect(saved.thrustTimeline!.total, 150);
    });
  });
}

/// Purpose: Pump an app and open `dialog` in it.
/// Inputs: `tester`, `dialog`.
/// Returns: A one-field record holding the dialog's result future, so the
/// enclosing `async` does not await it.
/// Side effects: Renders widgets.
/// Notes: English locale so field labels can be found by text.
Future<(Future<IntimacyRecord?>,)> _openDialog(
  WidgetTester tester,
  Widget dialog,
) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(),
    ),
  );
  final context = tester.element(find.byType(Scaffold));
  final result = showDialog<IntimacyRecord>(
    context: context,
    builder: (_) => dialog,
  );
  await tester.pumpAndSettle();
  return (result,);
}

/// Purpose: Tap Save and return the dialog's record.
/// Inputs: `tester`, `result`.
/// Returns: `Future<IntimacyRecord?>`.
/// Side effects: Closes the dialog.
/// Notes: None.
Future<IntimacyRecord?> _save(
  WidgetTester tester,
  Future<IntimacyRecord?> result,
) async {
  await tester.ensureVisible(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
  return result;
}

/// Purpose: Find the dialog's minutes field.
/// Inputs: None.
/// Returns: `Finder`.
/// Side effects: None.
/// Notes: The field has no label, only an `m` suffix.
Finder _minutesField() => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.suffixText == 'm',
);

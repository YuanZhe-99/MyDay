import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/intimacy/models/intimacy_record.dart';
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
}

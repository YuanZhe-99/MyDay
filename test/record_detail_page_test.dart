import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/intimacy/models/intimacy_record.dart';
import 'package:my_day/features/intimacy/utils/thrust_timeline.dart';
import 'package:my_day/features/intimacy/views/record_detail_page.dart';
import 'package:my_day/features/intimacy/widgets/thrust_timeline_chart.dart';
import 'package:my_day/l10n/app_localizations.dart';

/// Purpose: Build a test record.
/// Inputs: Optional `timeline` and `pleasure`.
/// Returns: `IntimacyRecord`.
/// Side effects: None.
/// Notes: Test helper only.
IntimacyRecord _record({ThrustTimeline? timeline, int pleasure = 3}) =>
    IntimacyRecord(
      id: 'r1',
      type: 'Solo',
      isSolo: true,
      pleasureLevel: pleasure,
      duration: const Duration(minutes: 4, seconds: 5),
      thrustCount: timeline?.total,
      thrustCountUnit: 1,
      thrustTimeline: timeline,
      notes: 'note text',
      datetime: DateTime(2026, 9, 1, 22),
    );

/// Purpose: Run the record detail page and chart helper tests.
/// Inputs: None.
/// Returns: None.
/// Side effects: None.
/// Notes: English locale; the page has no storage dependency.
void main() {
  final timeline = ThrustTimeline([
    const ThrustEvent(30000, 100),
    const ThrustEvent(90000, 50),
    const ThrustEvent(150000, 10),
  ]);

  /// Purpose: Pump the detail page under a host route.
  /// Inputs: `tester`, `record`, callbacks.
  /// Returns: `Future<void>`.
  /// Side effects: Renders and pushes the page.
  /// Notes: Pushed so a pop after delete can be observed.
  Future<void> pumpDetail(
    WidgetTester tester,
    IntimacyRecord record, {
    RecordEditCallback? onEdit,
    RecordDeleteCallback? onDelete,
  }) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RecordDetailPage(
                    record: record,
                    partners: const [],
                    toys: const [],
                    positions: const [],
                    onEdit: onEdit ?? (_) async => null,
                    onDelete: onDelete ?? (_) async {},
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the curve for a timer record', (tester) async {
    await pumpDetail(tester, _record(timeline: timeline));
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('00:04:05'), findsOneWidget);
    expect(find.text('160 x1'), findsOneWidget);
    expect(find.text('note text'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('has no curve for a typed-in record', (tester) async {
    await pumpDetail(tester, _record());
    expect(find.byType(LineChart), findsNothing);
    expect(find.text('Not recorded'), findsNWidgets(2));
  });

  testWidgets('an edit re-renders in place', (tester) async {
    await pumpDetail(
      tester,
      _record(),
      onEdit: (r) async => _record(pleasure: 5),
    );
    expect(find.text('★★★☆☆'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('★★★★★'), findsOneWidget);
  });

  testWidgets('delete confirms, deletes and closes', (tester) async {
    var deleted = 0;
    await pumpDetail(tester, _record(), onDelete: (_) async => deleted++);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
    expect(find.byType(RecordDetailPage), findsNothing);
  });

  group('chart helpers', () {
    test('niceStep picks 1, 2 or 5 times a power of ten', () {
      expect(ThrustTimelineChart.niceStep(160, 4), 50);
      expect(ThrustTimelineChart.niceStep(1000, 4), 500);
      expect(ThrustTimelineChart.niceStep(7, 5), 2);
      expect(ThrustTimelineChart.niceStep(0, 5), 1);
    });

    test('formatMinutes switches to h:mm past an hour', () {
      expect(ThrustTimelineChart.formatMinutes(12), '12');
      expect(ThrustTimelineChart.formatMinutes(75), '1:15');
    });
  });
}

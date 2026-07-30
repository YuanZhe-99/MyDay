import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_day/features/intimacy/models/intimacy_record.dart';
import 'package:my_day/features/intimacy/widgets/intimacy_trend_chart.dart';
import 'package:my_day/l10n/app_localizations.dart';

/// Purpose: Cover the consolidated intimacy trend chart's selection behavior.
/// Inputs: None.
/// Returns: None.
/// Side effects: Runs test assertions and pumps widgets.
/// Notes: Assertions target the reported settings rather than pixels, since the
/// selection is what gets persisted and synced.
void main() {
  /// Purpose: Build a small set of records spread across recent weeks.
  /// Inputs: None.
  /// Returns: `List<IntimacyRecord>`.
  /// Side effects: None.
  /// Notes: Every record carries a duration and a thrust count so all five
  /// metrics have data to draw.
  List<IntimacyRecord> buildRecords() {
    final now = DateTime.now();
    return List.generate(6, (index) {
      return IntimacyRecord(
        id: 'record-$index',
        type: 'Regular',
        pleasureLevel: 3 + (index % 3),
        duration: Duration(minutes: 10 + index * 2),
        thrustCount: 3 + index,
        thrustCountUnit: 100,
        datetime: now.subtract(Duration(days: index * 5 + 1)),
      );
    });
  }

  /// Purpose: Pump the chart and capture the settings it reports.
  /// Inputs: `tester`, `settings`, and the `reported` sink.
  /// Returns: `Future<void>`.
  /// Side effects: Pumps a widget tree and settles animations.
  /// Notes: Uses a bare `MaterialApp` with the app's localization delegates,
  /// matching the module's other widget test.
  Future<void> pumpChart(
    WidgetTester tester,
    IntimacyChartSettings settings,
    List<IntimacyChartSettings> reported,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: IntimacyTrendChart(
              records: buildRecords(),
              settings: settings,
              onSettingsChanged: reported.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders one chart with the default metric selection', (
    tester,
  ) async {
    final reported = <IntimacyChartSettings>[];
    await pumpChart(tester, const IntimacyChartSettings(), reported);

    expect(tester.takeException(), isNull);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Pleasure'), findsOneWidget);
    expect(find.text('Thrust rate'), findsOneWidget);
    expect(find.text('Frequency'), findsOneWidget);
    expect(reported, isEmpty);
  });

  testWidgets('reports an added metric when its chip is tapped', (
    tester,
  ) async {
    final reported = <IntimacyChartSettings>[];
    await pumpChart(tester, const IntimacyChartSettings(), reported);

    await tester.tap(find.text('Frequency'));
    await tester.pumpAndSettle();

    expect(reported, hasLength(1));
    expect(reported.single.metrics, contains('frequency'));
    expect(reported.single.metrics, contains('pleasure'));
    expect(reported.single.range, IntimacyChartSettings.defaultRange);
  });

  testWidgets('reports a removed metric when a selected chip is tapped', (
    tester,
  ) async {
    final reported = <IntimacyChartSettings>[];
    await pumpChart(tester, const IntimacyChartSettings(), reported);

    await tester.tap(find.text('Duration'));
    await tester.pumpAndSettle();

    expect(reported, hasLength(1));
    expect(reported.single.metrics, isNot(contains('duration')));
    expect(reported.single.metrics, contains('pleasure'));
  });

  testWidgets('refuses to clear the last selected metric', (tester) async {
    final reported = <IntimacyChartSettings>[];
    await pumpChart(
      tester,
      const IntimacyChartSettings(metrics: ['pleasure']),
      reported,
    );

    await tester.tap(find.text('Pleasure'));
    await tester.pumpAndSettle();

    expect(reported, isEmpty);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('reports a new range when a range chip is tapped', (
    tester,
  ) async {
    final reported = <IntimacyChartSettings>[];
    await pumpChart(tester, const IntimacyChartSettings(), reported);

    await tester.tap(find.text('1Y'));
    await tester.pumpAndSettle();

    expect(reported, hasLength(1));
    expect(reported.single.range, '1y');
    expect(reported.single.metrics, IntimacyChartSettings.defaultMetrics);
  });

  testWidgets('draws the defaults when every stored metric id is unknown', (
    tester,
  ) async {
    final reported = <IntimacyChartSettings>[];
    await pumpChart(
      tester,
      const IntimacyChartSettings(metrics: ['fromANewerBuild']),
      reported,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(LineChart), findsOneWidget);
  });
}

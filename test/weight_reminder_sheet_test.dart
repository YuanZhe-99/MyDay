import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:my_day/features/todo/services/todo_storage.dart';
import 'package:my_day/features/weight/views/weight_page.dart';
import 'package:my_day/l10n/app_localizations.dart';

/// Purpose: Regression-test that the weight reminder sheet stays fully reachable.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: Path provider is faked so app storage stays inside the test sandbox.
/// The sheet is rendered on a deliberately short surface because a default
/// (non-scroll-controlled) modal bottom sheet is capped at 9/16 of the screen
/// height — that cap is what clipped the trailing grace-window tile out of
/// reach, and an unscrollable `Column` overflowing it fails the pump.
/// `testWidgets` bodies run in fake-async time, so every real `dart:io` future
/// (the temp directory, and the page's own `WeightStorage.load()`) must be
/// driven inside `tester.runAsync`, with `pump` called outside it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Purpose: Point app storage at a fresh temp dir holding configured reminders.
  /// Inputs: `tester`, `mode` — `'once'` or `'twice'`.
  /// Returns: `Future<Directory>` — the temp directory, for teardown.
  /// Side effects: Creates `weight_data.json` in the fake app directory.
  /// Notes: Both reminder times are present so the sheet renders every row.
  Future<Directory> seedWeightData(WidgetTester tester, String mode) async {
    late Directory tempDir;
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('my_day_sheet_test_');
      PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
      final appDir = await TodoStorage.getAppDir();
      await File(p.join(appDir.path, 'weight_data.json')).writeAsString(
        jsonEncode({
          'records': <Map<String, dynamic>>[],
          'reminderMode': mode,
          'morningHour': 8,
          'morningMinute': 0,
          'eveningHour': 21,
          'eveningMinute': 0,
          'reminderGraceMinutes': 180,
          'settingsModifiedAt': DateTime.utc(2026, 7, 15).toIso8601String(),
        }),
      );
    });
    return tempDir;
  }

  /// Purpose: Pump the weight page on a short surface and open the reminder sheet.
  /// Inputs: `tester`.
  /// Returns: `Future<void>`.
  /// Side effects: Renders widgets and taps the app bar reminder bell.
  /// Notes: 400x640 is a realistic small phone; the 9/16 cap is then 360px.
  Future<void> openReminderSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const WeightPage(),
        ),
      ),
    );

    // `_loadData` is a chain of real `dart:io` awaits started inside the
    // fake-async zone, so each link needs one real event-loop turn followed by
    // a pump to drain the resulting rebuild. Loop until the spinner is gone.
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'the weight page never finished loading',
    );

    await tester.tap(find.byIcon(Icons.notifications_active).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets(
    'twice-daily reminder sheet renders without overflowing',
    (tester) async {
      final tempDir = await seedWeightData(tester, 'twice');
      addTearDown(() => tempDir.delete(recursive: true));
      await openReminderSheet(tester);

      // A RenderFlex overflow inside the sheet would already have failed the
      // pump above; assert the sheet actually opened so this stays meaningful.
      expect(find.text('Skip if already logged'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  testWidgets(
    'grace-window tile is on screen and tappable',
    (tester) async {
      final tempDir = await seedWeightData(tester, 'twice');
      addTearDown(() => tempDir.delete(recursive: true));
      await openReminderSheet(tester);

      final tile = find.text('Skip if already logged');
      final tileRect = tester.getRect(tile);
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;

      expect(
        tileRect.bottom,
        lessThanOrEqualTo(screenHeight),
        reason: 'the grace-window tile must not sit below the viewport',
      );
      expect(tileRect.top, greaterThanOrEqualTo(0.0));

      // Opens the hours dialog only if the tile is genuinely hit-testable.
      await tester.tap(tile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Hours before reminder'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  testWidgets(
    'grace-window tile shows the configured window',
    (tester) async {
      final tempDir = await seedWeightData(tester, 'once');
      addTearDown(() => tempDir.delete(recursive: true));
      await openReminderSheet(tester);

      expect(find.text('3 h before reminder'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}

class _FakePathProvider extends PathProviderPlatform {
  final String documentsPath;

  /// Purpose: Create a fake path provider for tests.
  /// Inputs: `documentsPath`.
  /// Returns: A new `_FakePathProvider` instance.
  /// Side effects: None.
  /// Notes: Only application documents path is needed by these tests.
  _FakePathProvider(this.documentsPath);

  /// Purpose: Return the fake application documents directory.
  /// Inputs: None.
  /// Returns: `Future<String?>`.
  /// Side effects: None.
  /// Notes: None.
  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

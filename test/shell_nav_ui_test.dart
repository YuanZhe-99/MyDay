import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:my_day/features/todo/services/todo_storage.dart';
import 'package:my_day/l10n/app_localizations.dart';
import 'package:my_day/shared/widgets/shell_scaffold.dart';

/// Purpose: Test that the shell swaps its bottom bar for a navigation rail.
/// Inputs: None.
/// Returns: None.
/// Side effects: Creates temporary files under the test temp directory.
/// Notes: Path provider is faked so app storage stays inside the test sandbox;
/// the shell reads `intimacyVisibilityProvider`, which loads from
/// `storage_config.json`. The shell is pumped with placeholder route children
/// rather than the real pages, because what is under test is the shell's own
/// navigation, not what any destination renders.
///
/// Driven in Simplified Chinese on purpose. `flutter_test` renders every glyph
/// of its default font as a full em square, inflating a Latin label to roughly
/// 2.5x its real width, so Latin layout tests report overflow at widths that
/// are perfectly comfortable in production. CJK glyphs really are square, so a
/// Chinese locale measures the real production layout. Do not "fix" this back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Purpose: Point app storage at a fresh temp dir with a known visibility.
  /// Inputs: `tester`, `intimacyVisible`.
  /// Returns: `Future<Directory>` — the temp directory, for teardown.
  /// Side effects: Creates `storage_config.json` in the fake app directory.
  /// Notes: The intimacy module defaults to hidden for new installs, so the
  /// visible case has to be seeded explicitly.
  Future<Directory> seedConfig(
    WidgetTester tester, {
    required bool intimacyVisible,
  }) async {
    late Directory tempDir;
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('my_day_shell_test_');
      PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
      await TodoStorage.writeConfig({'intimacyVisible': intimacyVisible});
      // Warm the static config cache while real dart:io futures can still
      // complete. Widget-test bodies run in fake-async time, so the
      // provider's own load would otherwise never resolve during a pump.
      // Writing through TodoStorage also invalidates its static config cache,
      // which is shared across every test in this isolate.
      await TodoStorage.getIntimacyVisible();
    });
    return tempDir;
  }

  /// Purpose: Pump the shell at a pinned viewport.
  /// Inputs: `tester`, `size` — the logical-pixel viewport.
  /// Returns: `Future<void>`.
  /// Side effects: Renders widgets.
  /// Notes: The viewport is always pinned, because the default 800x600 test
  /// surface is already wide enough for a rail and would silently decide the
  /// outcome of every test here.
  Future<void> pumpShell(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/todo',
      routes: [
        ShellRoute(
          builder: (context, state, child) => ShellScaffold(child: child),
          routes: [
            for (final path in [
              '/todo',
              '/finance',
              '/weight',
              '/intimacy',
              '/settings',
            ])
              GoRoute(
                path: path,
                builder: (context, state) =>
                    Scaffold(body: Center(child: Text('page $path'))),
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('zh'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a phone in portrait keeps the bottom navigation bar', (
    tester,
  ) async {
    final dir = await seedConfig(tester, intimacyVisible: true);
    addTearDown(() => dir.delete(recursive: true));

    // Pixel-class phone in portrait.
    await pumpShell(tester, const Size(412, 915));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('a phone in landscape gets a rail even though it cannot split', (
    tester,
  ) async {
    final dir = await seedConfig(tester, intimacyVisible: true);
    addTearDown(() => dir.delete(recursive: true));

    // The width-only rule at work: 915 dp of width, only 412 dp of height.
    await pumpShell(tester, const Size(915, 412));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an unfolded Galaxy Z Fold 8 shows the rail in both orientations',
    (tester) async {
      final dir = await seedConfig(tester, intimacyVisible: true);
      addTearDown(() => dir.delete(recursive: true));

      await pumpShell(tester, const Size(704, 932)); // portrait
      expect(find.byType(NavigationRail), findsOneWidget);

      await pumpShell(tester, const Size(932, 704)); // landscape
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the rail and the bottom bar carry the same destinations', (
    tester,
  ) async {
    final dir = await seedConfig(tester, intimacyVisible: true);
    addTearDown(() => dir.delete(recursive: true));

    await pumpShell(tester, const Size(412, 915));
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final barLabels = [
      for (final d in bar.destinations) (d as NavigationDestination).label,
    ];

    await pumpShell(tester, const Size(932, 704));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    final railLabels = [
      for (final d in rail.destinations) (d.label as Text).data,
    ];

    expect(barLabels, railLabels);
    expect(barLabels.length, 5);
  });

  testWidgets('hiding the intimacy module drops it from the rail too', (
    tester,
  ) async {
    final dir = await seedConfig(tester, intimacyVisible: false);
    addTearDown(() => dir.delete(recursive: true));

    await pumpShell(tester, const Size(932, 704));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));

    expect(rail.destinations.length, 4);
    expect([
      for (final d in rail.destinations) (d.label as Text).data,
    ], isNot(contains('亲密')));
  });

  testWidgets('the rail scrolls rather than overflowing a short window', (
    tester,
  ) async {
    final dir = await seedConfig(tester, intimacyVisible: true);
    addTearDown(() => dir.delete(recursive: true));

    // A folded Fold 8 cover screen in landscape is only 416 dp tall, and an
    // ordinary phone in landscape 412 — both earn a rail on width alone.
    await pumpShell(tester, const Size(915, 412));

    expect(tester.takeException(), isNull);
    expect(
      find.ancestor(
        of: find.byType(NavigationRail),
        matching: find.byType(Scrollable),
      ),
      findsOneWidget,
    );
  });
}

class _FakePathProvider extends PathProviderPlatform {
  final String root;

  /// Purpose: Create a fake path provider rooted at a test temp directory.
  /// Inputs: `root`.
  /// Returns: A new `_FakePathProvider` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  _FakePathProvider(this.root);

  /// Purpose: Return the fake application documents directory.
  /// Inputs: None.
  /// Returns: `Future<String?>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  /// Purpose: Return the fake application support directory.
  /// Inputs: None.
  /// Returns: `Future<String?>`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  @override
  Future<String?> getApplicationSupportPath() async => root;
}

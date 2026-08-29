/// Shared scaffolding for the adaptive-layout page tests.
///
/// The four shell pages each get their own `*_layout_ui_test.dart` file rather
/// than sharing one, and that is deliberate: `flutter test` runs every file in
/// its own isolate, while every test **inside** one file shares `TodoStorage`'s
/// static config cache and the `ReminderService` / `AutoSyncService`
/// singletons the pages register callbacks with. Sharing an isolate across
/// pages made failures move between runs, because a stale listener from an
/// already-torn-down page ran `_loadData` against a deleted temp directory.
///
/// The tests are driven in Simplified Chinese on purpose. `flutter_test`
/// renders every glyph of its default font as a full em square, inflating a
/// Latin label to roughly 2.5x its real width, so Latin layout tests report
/// overflow at widths that are perfectly comfortable in production. CJK glyphs
/// really are square, so a Chinese locale measures the real production layout.
/// Do not "fix" this back.
///
/// Every test pins an explicit viewport, because the default 800x600 test
/// surface already passes `canSplitLayout` and would otherwise decide these
/// outcomes silently.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:my_day/features/todo/services/todo_storage.dart';
import 'package:my_day/l10n/app_localizations.dart';

/// Purpose: Point app storage at a fresh temp dir holding seeded data files.
/// Inputs: `tester`; `files` — file name to JSON-encodable content.
/// Returns: `Future<Directory>` — the temp directory, for teardown.
/// Side effects: Creates the named files in the fake app directory and
/// invalidates `TodoStorage`'s static config cache.
/// Notes: `testWidgets` bodies run in fake-async time, so every real `dart:io`
/// future here is driven inside `tester.runAsync`. Writing through
/// `TodoStorage.writeConfig` is what clears the static cache a previous test in
/// the same isolate may have warmed.
Future<Directory> seedAppDir(
  WidgetTester tester,
  Map<String, Object> files,
) async {
  late Directory tempDir;
  await tester.runAsync(() async {
    tempDir = await Directory.systemTemp.createTemp('my_day_layout_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    await TodoStorage.writeConfig(<String, Object?>{});
    final appDir = await TodoStorage.getAppDir();
    for (final entry in files.entries) {
      await File(
        p.join(appDir.path, entry.key),
      ).writeAsString(jsonEncode(entry.value));
    }
    await TodoStorage.getWeekStartDay();
  });
  return tempDir;
}

/// Purpose: Pump one page at a pinned viewport and let its load chain settle.
/// Inputs: `tester`, `page`, `size`.
/// Returns: `Future<void>`.
/// Side effects: Renders widgets; registers a teardown that unmounts the page.
/// Notes: Alternates `runAsync` turns with pumps rather than calling
/// `pumpAndSettle`, which never settles while a real file read is pending. The
/// unmount teardown runs before the caller's temp-directory deletion, because
/// teardowns run in reverse registration order — without it a page's `dispose`
/// would never run and its storage listeners would outlive the directory.
Future<void> pumpAdaptivePage(
  WidgetTester tester,
  Widget page,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await settleAdaptivePage(tester);
}

/// Purpose: Drive a page's pending real-async work forward.
/// Inputs: `tester`.
/// Returns: `Future<void>`.
/// Side effects: Renders frames.
/// Notes: Twelve alternating turns; each page runs a multi-step load chain.
Future<void> settleAdaptivePage(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 50));
  }
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

/// Purpose: Delete a test temp directory, tolerating a Windows file lock.
/// Inputs: `dir`.
/// Returns: `Future<void>`.
/// Side effects: Removes the directory when the OS allows it.
/// Notes: A page can still be flushing a write when its test ends, and Windows
/// refuses to delete a directory holding an open handle. That is a teardown
/// artifact, not a layout fault, so it must not fail the test — the OS reclaims
/// the leftover directory itself.
Future<void> deleteQuietly(Directory dir) async {
  try {
    await dir.delete(recursive: true);
  } catch (_) {
    // Left for the OS to reclaim.
  }
}

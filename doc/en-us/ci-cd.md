# CI/CD and build commands

## Workflow

`.github/workflows/build.yml` runs on `v*` tag pushes and `workflow_dispatch`.

Every checkout step passes `submodules: recursive`. Without it `flutter pub get` fails on the missing
`packages/myapps_data` path dependency. The relative submodule URL resolves to the public GitHub copy
in CI, so the default `GITHUB_TOKEN` is sufficient.

## Jobs

| Job | Runner | Output | Notes |
| --- | --- | --- | --- |
| `android` | `ubuntu-latest` | APK + AAB | Java 17, optional signing secrets, APK `--flavor full` + `FLAVOR=full`, then the bank-logo strip step, then AAB `--flavor store` + `FLAVOR=store`, asserted free of `bank_logos` |
| `windows-x64` | `windows-latest` | Inno x64 installer | Stable Flutter `3.44.2`, `iscc installer.iss` |
| `windows-arm64` | `windows-11-arm` | Inno ARM64 installer | Flutter master for ARM64 engine, `iscc /DARM64 installer.iss` |
| `ios` | `macos-latest` | Sideload IPA | Release, no codesign; then `tool/check_weak_link.sh` on `Runner.app` |
| `macos` | `macos-latest` | DMG | `tool/check_weak_link.sh` on the built `.app`, then `create-dmg` |
| `release` | `ubuntu-latest` | GitHub Release | Only on tag push, collects all artifacts |

## Workflow caveats

- Keep the workflow Flutter version aligned with the Dart SDK constraint.
- All release builds use `--no-tree-shake-icons`.
- GitHub `secrets` cannot be used directly in step `if` expressions; route them through job-level
  `env`.
- Windows x64 and ARM64 CI jobs set `CL=/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` as a
  temporary VS/MSVC 18 compatibility workaround while Windows plugin/WinRT dependencies still include
  deprecated `<experimental/coroutine>`.
- Windows ARM64 uses Flutter master because stable may not include the needed ARM64 engine.
- **Android flavors.** Android has real product flavors, so every Android `flutter run` and
  `flutter build` must pass `--flavor full` or `--flavor store` (also pass the matching
  `--dart-define=FLAVOR=`, as CI does). Flavored outputs are
  `build/app/outputs/flutter-apk/app-full-release.apk` and
  `build/app/outputs/bundle/storeRelease/app-store-release.aab`; the job copies them to
  `dist/app-release.apk` and `dist/app-release.aab` so the published release asset names stay
  unchanged, and both uploads use `if-no-files-found: error` so a path change fails the job instead
  of silently publishing nothing.
- **The strip step must run after the Full build.** `dart run tool/strip_bank_logos.dart` deletes
  `assets/bank_logos/`, removes the exact `- assets/bank_logos/` line from `pubspec.yaml`, and
  rewrites the logo manifest to an empty map — in CI's throwaway checkout. `--verify` then fails the
  job if anything is left, and after the AAB build an `unzip -l` check fails the job if the AAB
  contains `bank_logos`. Never run the strip without `--dry-run` in a working tree you care about;
  restore with
  `git checkout -- assets/bank_logos pubspec.yaml lib/features/finance/services/bank_logo_manifest.g.dart`.
  Windows, iOS, and macOS are Full builds and are never stripped.
- **FoundationModels must stay weakly linked (1.5.0).** The on-device AI plugin links Apple's
  FoundationModels, which exists only on iOS/macOS 26+. After the iOS and macOS builds,
  `bash tool/check_weak_link.sh <app>` fails the job unless every binary that links it uses
  `LC_LOAD_WEAK_DYLIB`, and also fails when nothing links it (the plugin did not make it into the
  build, or the runner's Xcode lacks the 26 SDK — then fix the runner, not the code). The macOS
  bundle name contains `!!!!!`, so its path is found with `find` and always quoted. See
  [on-device-ai.md](on-device-ai.md#weak-linking).
- Android builds need nothing new for on-device AI: ML Kit resolves from Google Maven, and both
  flavors include it.
- Action versions: `actions/checkout@v7`, `actions/setup-java@v5`, `actions/upload-artifact@v7`,
  `actions/download-artifact@v8`, `softprops/action-gh-release@v3` (bumped from the Node 20-based
  majors GitHub deprecated). Validate workflow changes with a `workflow_dispatch` run before the next
  tag release.
- Known remaining warning: the Android job still prints Flutter's "plugins that apply KGP" warning
  for `flutter_timezone`, `package_info_plus`, `shared_preferences_android`, `wakelock_plus`,
  `flutter_local_notifications`, and `file_picker`. The app side is already migrated (AGP 9.1.1, no
  app-level `kotlin-android`); the remaining warning is plugin-side only and, as of 2026-07, even the
  latest releases of those plugins still apply KGP. Full elimination requires flipping
  `android.builtInKotlin=true` once every plugin ships Built-in Kotlin support; verify with real
  APK/AAB builds when attempting it.

## Commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter test test/balance_util_test.dart
flutter test test/json_preservation_test.dart
flutter test test/widget_test.dart
flutter test test/id_list_delta_test.dart test/subpage_merge_test.dart test/storage_hardening_test.dart test/local_api_server_test.dart
flutter test test/golden/webdav_golden_test.dart
flutter test test/on_device_ai_test.dart test/insight_facts_test.dart test/insight_service_test.dart test/ai_insights_cache_test.dart test/ai_insight_card_ui_test.dart test/ai_settings_tiles_ui_test.dart
bash tool/check_weak_link.sh build/ios/iphoneos/Runner.app
flutter gen-l10n
dart run tool/generate_ios_icons.dart
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
dart run tool/validate_ios_icons.dart
flutter test test/bank_logo_manifest_test.dart
flutter test test/strip_bank_logos_test.dart
flutter test test/stored_image_test.dart
dart run tool/fetch_bank_logos.dart --out <scratch dir> --infobox
dart run tool/fetch_bank_logos.dart --out <scratch dir> --site --only <country_id,...>
dart run tool/fetch_bank_logos.dart --out <scratch dir> --icons --only <country_id,...>
dart run tool/bank_logo_sheet.dart --dir <scratch dir>
dart run tool/apply_bank_logo_choices.dart --dir <scratch dir>
dart run tool/bank_logo_sheet.dart --final
dart run tool/gen_bank_logo_manifest.dart
dart run tool/strip_bank_logos.dart --dry-run
dart run tool/strip_bank_logos.dart --verify
flutter run --flavor full --dart-define=FLAVOR=full
flutter build apk --release --no-tree-shake-icons --flavor full --dart-define=FLAVOR=full
flutter build appbundle --release --no-tree-shake-icons --flavor store --dart-define=FLAVOR=store
flutter build windows --release --no-tree-shake-icons --dart-define=FLAVOR=full
iscc installer.iss
iscc /DARM64 installer.iss
```

Use the narrowest relevant command set for verification. For sync, model, or persistence changes,
include targeted tests and consider adding coverage for `JsonPreservation`, merge behavior, or
balance calculations. The bank-logo tools (`fetch_bank_logos`, `bank_logo_sheet`,
`apply_bank_logo_choices`, `gen_bank_logo_manifest`) are local maintenance tools (fetching and `@png`
installs use the network) that never run in CI; their workflow is in [Finance](features/finance.md#bankpresetservice).

`test/golden/webdav_golden_test.dart` keeps six request-sequence scenarios (first sync, local-only
change, remote-only change, conflict then finalize, force upload, image added on both sides) whose
transcripts stay byte-identical. Since v1.5.2 it imports the canonical fake server and request
recorder from `packages/myapps_data/test/golden/` instead of keeping local copies, and the
no-change, both-identical, force-download, interrupted-recovery, backup-v2, corrupt-bundle,
ZIP-export and ZIP-traversal scenarios are left to the shared package's own golden suite. `test/id_list_delta_test.dart` and `test/subpage_merge_test.dart`
cover the Finance and Intimacy merge-by-id sub-page saves. The DST tests in
`test/week_grouping_test.dart` and `test/audit_fixes_test.dart` only prove something in a time zone
that observes daylight saving; on Windows or in a UTC zone they pass trivially. Run them on Linux or
macOS as `TZ=America/New_York flutter test test/week_grouping_test.dart test/audit_fixes_test.dart`.
The release workflow itself does not run `flutter test`.

## Fresh clone

The shared engine package is a git submodule, so a plain `git clone` leaves `packages/myapps_data`
empty and `flutter pub get` fails:

```bash
git clone --recurse-submodules <app-url>
# or, after a plain clone:
git submodule update --init
```

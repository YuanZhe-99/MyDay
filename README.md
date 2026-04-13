# MyDay!!!!! — Your Daily Life Companion

A privacy-first Flutter app for task management, personal finance tracking, weight logging, and intimate life recording.

## Features

- **Todo Management** — Daily / routine / work task types with subtask support, emoji & icon per task.
- **Personal Finance** — Multi-account (fund, credit, recharge, financial), multi-currency with live exchange rates, expense / income / transfer tracking, custom categories, charts & analysis.
- **Weight Tracking** — Daily weight logging with date & time.
- **Intimacy Module** — Activity, partner & toy tracking with detailed logging. Disabled by default; toggle in Settings.
- **WebDAV Cloud Sync** — Sync data to your own cloud (e.g. Nextcloud) via WebDAV, with per-record three-way merge & auto-sync.
- **Backup & Restore** — Full local backup (data + images). Optional auto-backup with retention policies.
- **ZIP Export / Import** — Export all data as a `.zip` archive for easy migration or sharing.
- **CSV Import / Export** — Per-module CSV for finance, intimacy, and weight data.
- **Multi-Language** — English, Japanese, Simplified Chinese, Traditional Chinese.
- **Desktop** — System tray support (minimize-to-tray, close-to-tray), custom storage path.

## Platforms

| Platform | Artifact |
|----------|----------|
| Windows (x64) | Inno Setup installer (`MyDay_x.x.x_Setup.exe`) |
| Windows (ARM64) | Inno Setup installer (`MyDay_x.x.x_arm64_Setup.exe`) |
| Android  | APK (`app-release.apk`) |
| Android  | AAB (`app-release.aab`) |
| iOS      | Sideload IPA |
| macOS    | DMG |

## Build

```bash
# Windows x64 installer
flutter build windows --release
iscc installer.iss

# Windows ARM64 installer (requires Flutter master for ARM64 engine)
flutter build windows --release
iscc /DARM64 installer.iss

# Android APK (icons are dynamically stored, need --no-tree-shake-icons)
flutter build apk --release --no-tree-shake-icons

# Android AAB
flutter build appbundle --release --no-tree-shake-icons

# iOS Sideload
flutter build ios --release --no-codesign
mkdir -p build/ios/ipa/Payload
cp -r build/ios/iphoneos/Runner.app build/ios/ipa/Payload/
cd build/ios/ipa && zip -r MyDay_sideload.ipa Payload && cd -

# macOS DMG
flutter build macos --release
create-dmg \
  --volname "MyDay!!!!!" \
  --app-drop-link 400 150 \
  "build/macos/MyDay.dmg" \
  "build/macos/Build/Products/Release/MyDay!!!!!.app"
```


## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

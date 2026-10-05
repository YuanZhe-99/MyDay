# CI/CD 与构建命令

公共实现归属及全新克隆的接入说明见 [shared-ui.md](shared-ui.md)。

## 工作流

`.github/workflows/build.yml` 在 `v*` 标签推送和 `workflow_dispatch` 时运行。

每个检出步骤都传 `submodules: recursive`。没有它，`flutter pub get` 会因缺失的 `packages/myapps_data` 路径依赖而失败。相对子模块 URL 在 CI 中解析到公共 GitHub 副本，因此默认的 `GITHUB_TOKEN` 就足够了。

## 任务

| 任务 | 运行器 | 输出 | 备注 |
| --- | --- | --- | --- |
| `android` | `ubuntu-latest` | APK + AAB | Java 17、可选签名秘密、APK `--flavor full` + `FLAVOR=full`，然后银行标志剥离步骤，然后 AAB `--flavor store` + `FLAVOR=store`，并断言其中没有 `bank_logos` |
| `windows-x64` | `windows-latest` | Inno x64 安装包 | Stable Flutter `3.44.2`、`iscc installer.iss` |
| `windows-arm64` | `windows-11-arm` | Inno ARM64 安装包 | ARM64 引擎用 Flutter master、`iscc /DARM64 installer.iss` |
| `ios` | `macos-latest` | 侧载 IPA | Release、无签名；然后对 `Runner.app` 运行 `tool/check_weak_link.sh` |
| `macos` | `macos-latest` | DMG | 对构建出的 `.app` 运行 `tool/check_weak_link.sh`，然后 `create-dmg` |
| `release` | `ubuntu-latest` | GitHub Release | 只在标签推送时，收集所有工件 |

## 工作流注意事项

- 让工作流 Flutter 版本与 Dart SDK 约束保持一致。
- 所有发布构建使用 `--no-tree-shake-icons`。
- GitHub `secrets` 不能直接在步骤的 `if` 表达式中使用；要通过任务级 `env` 路由。
- Windows x64 和 ARM64 CI 任务把 `CL=/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` 设为临时 VS/MSVC 18 兼容变通，而 Windows 插件/WinRT 依赖仍包含已弃用的 `<experimental/coroutine>`。
- Windows ARM64 用 Flutter master，因为 stable 可能不含所需的 ARM64 引擎。
- **Android 构建风味。** Android 有真实的构建风味，因此每次 Android `flutter run` 和 `flutter build` 都必须传 `--flavor full` 或 `--flavor store`（并像 CI 一样同时传对应的 `--dart-define=FLAVOR=`）。带风味的输出是 `build/app/outputs/flutter-apk/app-full-release.apk` 和 `build/app/outputs/bundle/storeRelease/app-store-release.aab`；该任务把它们复制为 `dist/app-release.apk` 和 `dist/app-release.aab`，使发布的 release 资源名保持不变。两次上传都用 `if-no-files-found: error`，因此路径变化会让任务失败，而不是静默地什么都不发布。
- **剥离步骤必须在完整版构建之后运行。** `dart run tool/strip_bank_logos.dart` 在 CI 的一次性检出中删除 `assets/bank_logos/`，从 `pubspec.yaml` 移除精确的 `- assets/bank_logos/` 行，并把标志清单重写为空映射。随后 `--verify` 在有任何残留时让任务失败；AAB 构建之后，`unzip -l` 检查在 AAB 含有 `bank_logos` 时让任务失败。不要在在意的工作树中不带 `--dry-run` 运行剥离；恢复用 `git checkout -- assets/bank_logos pubspec.yaml lib/features/finance/services/bank_logo_manifest.g.dart`。Windows、iOS 和 macOS 都是完整版构建，从不剥离。
- **FoundationModels 必须保持弱链接（1.5.0）。** 端侧 AI 插件链接 Apple 的 FoundationModels，它只存在于 iOS/macOS 26+。iOS 和 macOS 构建之后，只要有任何链接它的二进制没有使用 `LC_LOAD_WEAK_DYLIB`，`bash tool/check_weak_link.sh <app>` 就让任务失败；没有任何二进制链接它时也会失败（插件没有进入构建，或 runner 的 Xcode 缺少 26 SDK——此时修 runner，而不是修代码）。macOS 包名含 `!!!!!`，因此它的路径用 `find` 查找并始终加引号。见 [on-device-ai.md](on-device-ai.md#weak-linking)。
- Android 构建不需要为端侧 AI 做任何新配置：ML Kit 从 Google Maven 解析，两种风味都包含它。
- Action 版本：`actions/checkout@v7`、`actions/setup-java@v5`、`actions/upload-artifact@v7`、`actions/download-artifact@v8`、`softprops/action-gh-release@v3`（从 GitHub 废弃的基于 Node 20 的 majors 升级）。在下次标签发布前用一次 `workflow_dispatch` 运行验证工作流变更。
- 已知的剩余警告：Android 任务仍会为 `flutter_timezone`、`package_info_plus`、`shared_preferences_android`、`wakelock_plus`、`flutter_local_notifications` 和 `file_picker` 打印 Flutter 的"应用 KGP 的插件"警告。应用侧已迁移（AGP 9.1.1，无应用级 `kotlin-android`）；剩余警告只在插件侧，且截至 2026-07，即使这些插件的最新版本仍应用 KGP。彻底消除需要在每个插件都提供 Built-in Kotlin 支持后翻转为 `android.builtInKotlin=true`；尝试时要用真实的 APK/AAB 构建验证。

## 命令

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

使用最窄的相关命令集做校验。同步、模型或持久化变更时，包含针对性测试，并考虑为 `JsonPreservation`、合并行为或余额计算添加覆盖。银行标志工具（`fetch_bank_logos`、`bank_logo_sheet`、`apply_bank_logo_choices`、`gen_bank_logo_manifest`）是本地维护工具（获取候选和 `@png` 安装需要联网），从不在 CI 中运行；其工作流见 [财务](features/finance.md#bankpresetservice)。

`test/golden/webdav_golden_test.dart` 保留六个请求序列场景（首次同步、仅本地变更、仅远端变更、冲突后定稿、强制上传、两端各自添加图片），其记录保持逐字节一致。自 v1.5.2 起，它从 `packages/myapps_data/test/golden/` 导入规范的假服务器和请求记录器，不再保留本地副本；无变更、两端相同、强制下载、中断恢复、备份 v2、损坏包、ZIP 导出和 ZIP 路径穿越场景交由共享包自己的黄金测试覆盖。`test/id_list_delta_test.dart` 和 `test/subpage_merge_test.dart` 覆盖财务与亲密模块的按 id 合并子页面保存。`test/week_grouping_test.dart` 和 `test/audit_fixes_test.dart` 中的夏令时测试只有在实行夏令时的时区里才能证明问题；在 Windows 或 UTC 时区中它们必然通过。请在 Linux 或 macOS 上以 `TZ=America/New_York flutter test test/week_grouping_test.dart test/audit_fixes_test.dart` 运行。发布工作流本身不运行 `flutter test`。

## 全新克隆

共享引擎包是 git 子模块，因此普通 `git clone` 会留下空的 `packages/myapps_data`，`flutter pub get` 失败：

```bash
git clone --recurse-submodules <app-url>
# or, after a plain clone:
git submodule update --init
```

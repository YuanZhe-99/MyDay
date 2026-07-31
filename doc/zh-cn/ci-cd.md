# CI/CD 与构建命令

## 工作流

`.github/workflows/build.yml` 在 `v*` 标签推送和 `workflow_dispatch` 时运行。

每个检出步骤都传 `submodules: recursive`。没有它，`flutter pub get` 会因缺失的 `packages/myapps_data` 路径依赖而失败。相对子模块 URL 在 CI 中解析到公共 GitHub 副本，因此默认的 `GITHUB_TOKEN` 就足够了。

## 任务

| 任务 | 运行器 | 输出 | 备注 |
| --- | --- | --- | --- |
| `android` | `ubuntu-latest` | APK + AAB | Java 17、可选签名秘密、APK `FLAVOR=full`、AAB `FLAVOR=store` |
| `windows-x64` | `windows-latest` | Inno x64 安装包 | Stable Flutter `3.44.2`、`iscc installer.iss` |
| `windows-arm64` | `windows-11-arm` | Inno ARM64 安装包 | ARM64 引擎用 Flutter master、`iscc /DARM64 installer.iss` |
| `ios` | `macos-latest` | 侧载 IPA | Release、无签名 |
| `macos` | `macos-latest` | DMG | 用 `create-dmg` |
| `release` | `ubuntu-latest` | GitHub Release | 只在标签推送时，收集所有工件 |

## 工作流注意事项

- 让工作流 Flutter 版本与 Dart SDK 约束保持一致。
- 所有发布构建使用 `--no-tree-shake-icons`。
- GitHub `secrets` 不能直接在步骤的 `if` 表达式中使用；要通过任务级 `env` 路由。
- Windows x64 和 ARM64 CI 任务把 `CL=/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` 设为临时 VS/MSVC 18 兼容变通，而 Windows 插件/WinRT 依赖仍包含已弃用的 `<experimental/coroutine>`。
- Windows ARM64 用 Flutter master，因为 stable 可能不含所需的 ARM64 引擎。
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
flutter gen-l10n
dart run tool/generate_ios_icons.dart
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
dart run tool/validate_ios_icons.dart
flutter build apk --release --no-tree-shake-icons --dart-define=FLAVOR=full
flutter build appbundle --release --no-tree-shake-icons --dart-define=FLAVOR=store
flutter build windows --release --no-tree-shake-icons --dart-define=FLAVOR=full
iscc installer.iss
iscc /DARM64 installer.iss
```

使用最窄的相关命令集做校验。同步、模型或持久化变更时，包含针对性测试，并考虑为 `JsonPreservation`、合并行为或余额计算添加覆盖。

## 全新克隆

共享引擎包是 git 子模块，因此普通 `git clone` 会留下空的 `packages/myapps_data`，`flutter pub get` 失败：

```bash
git clone --recurse-submodules <app-url>
# or, after a plain clone:
git submodule update --init
```

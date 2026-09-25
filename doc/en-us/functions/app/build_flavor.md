# lib/app/build_flavor.dart

The distribution flavor of this binary — Full or Store — as three compile-time constants. This is
the only place under `lib/` that reads the flavor: code that must behave differently in Store builds
imports `isStoreBuild` (or an intent-named alias such as `bundledBankLogosEnabled`) from here and
reads nothing else. Today the flavor gates exactly one behavior, the bundled bank-logo lookup in
[`BankPreset.bundledLogoAsset`](../features/finance/services/bank_preset_service.md#bundledlogoasset).
The flag only changes lookups; keeping Store-excluded bytes out of the package is the job of the CI
strip step (see [CI/CD](../../ci-cd.md) and [Architecture](../../architecture.md)).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `dartDefineFlavor` | top-level `const String` | B | The `--dart-define=FLAVOR=` value (empty when not passed). |
| [`isStoreBuild`](#isstorebuild) | top-level `const bool` | A | Whether this binary is a Store distribution. |
| `bundledBankLogosEnabled` | top-level `const bool` | B | `!isStoreBuild`, named for the bundled bank-logo gate. |

**Reconciliation:** `grep -c '/// Purpose:' lib/app/build_flavor.dart` returns 3, matching the 3
rows above exactly. The file's leading `library;` doc comment carries no `Purpose:` block and is not
a declaration.

## Documentation

### `const bool isStoreBuild` <a id="isstorebuild"></a>
- **Kind:** top-level compile-time constant
- **Source:** `lib/app/build_flavor.dart` (line 22)
- **Purpose:** Tell whether this binary is a Store distribution.
- **Inputs:** None (read from the build: `appFlavor` from `package:flutter/services.dart`, and
  `dartDefineFlavor`).
- **Returns:** `bool` — `true` when `appFlavor == 'store'` (Android `--flavor store`) **or**
  `dartDefineFlavor == 'store'` (`--dart-define=FLAVOR=store`); `false` otherwise, including a
  plain `flutter run` / `flutter test` with neither set.
- **Side effects:** None.
- **Algorithm:** A single `const` boolean expression over the two flavor channels. Either channel
  saying `store` is enough, so an Android build passing only `--flavor store` and a Windows build
  passing only the dart-define (Windows has no `--flavor`) both count as Store builds.
- **Usage:**
  ```dart
  const bool bundledBankLogosEnabled = !isStoreBuild;
  ```
  (`lib/app/build_flavor.dart:30`; `bundledBankLogosEnabled` is then read by
  `BankPreset.bundledLogoAsset` in `lib/features/finance/services/bank_preset_service.dart:58-59`.)
- **Notes:** The default is Full: a build that passes no flavor at all behaves as Full. The flag
  changes behavior only; it does not remove any asset from the package — CI runs
  `tool/strip_bank_logos.dart` before the Store build for that.

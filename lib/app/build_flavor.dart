/// Distribution flavor of this binary (Full vs Store). The only place `lib/` reads the flavor.
library;

import 'package:flutter/services.dart' show appFlavor;

/// Purpose: Carry the `--dart-define=FLAVOR=` value, the flavor channel on every platform.
/// Inputs: None.
/// Returns: None (compile-time constant).
/// Side effects: None.
/// Notes: Empty when not passed (plain `flutter run` / `flutter test`). Windows has no
/// `--flavor`, so this is the only signal there.
const String dartDefineFlavor = String.fromEnvironment('FLAVOR');

/// Purpose: Tell whether this binary is a Store distribution.
/// Inputs: None.
/// Returns: None (compile-time constant).
/// Side effects: None.
/// Notes: True when either the platform flavor (`--flavor store`, Android product flavor) or the
/// dart-define (`FLAVOR=store`) says so. Code that must behave differently in Store builds reads
/// this flag and nothing else; the CI strip step is what keeps Store-excluded assets out of the
/// package itself.
const bool isStoreBuild = appFlavor == 'store' || dartDefineFlavor == 'store';

/// Purpose: Gate the bundled bank-logo lookup.
/// Inputs: None.
/// Returns: None (compile-time constant).
/// Side effects: None.
/// Notes: `!isStoreBuild`. Named separately so call sites read as intent. Store builds use the
/// network logo chain only.
const bool bundledBankLogosEnabled = !isStoreBuild;

# lib/features/finance/services/bank_logo_manifest.g.dart

Generated file — do not edit by hand. Holds the logo manifest: one constant map from a bank
preset's country-qualified key to the bundled logo asset that ships for it in Full builds. It is
written by `tool/gen_bank_logo_manifest.dart` (and by `tool/apply_bank_logo_choices.dart`, which
calls the same generator), and rewritten to an empty map by `tool/strip_bank_logos.dart` before a
Store build. Both writers share `renderBankLogoManifest` in `tool/bank_logo_manifest_writer.dart`,
whose output is sorted by key and deterministic, so regenerating an unchanged logo set produces no
diff. See [Finance](../../../../features/finance.md#bankpresetservice) for the logo workflow.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`bankLogoAssets`](#banklogoassets) | top-level `const Map<String, String>` | A | Map a preset key (`<country>/<id>`) to its bundled logo asset. |

**Reconciliation:** `grep -c '/// Purpose:' lib/features/finance/services/bank_logo_manifest.g.dart`
returns 1, matching the single row above. The file's `//` header lines (generator name, Store-build
note, logo count) are plain comments, not declarations.

## Documentation

### `const Map<String, String> bankLogoAssets` <a id="banklogoassets"></a>
- **Kind:** top-level compile-time constant (generated)
- **Source:** `lib/features/finance/services/bank_logo_manifest.g.dart` (line 11)
- **Purpose:** Map a bank preset key to the bundled logo asset that ships for it.
- **Inputs:** None.
- **Returns:** `Map<String, String>` — keys are `BankPreset.key` values (`<country>/<id>`, e.g.
  `us/chase`); values are asset paths `assets/bank_logos/<country>_<id>.<svg|png>`. Presets without
  a reviewed logo are simply absent.
- **Side effects:** None.
- **Algorithm:** None at run time. At generation time `collectBankLogos` lists
  `assets/bank_logos/`, maps each file stem `<country>_<id>` back to a preset from
  `assets/banks.json`, and throws `FormatException` for a file that matches no preset, has an
  extension other than `.svg`/`.png`, or duplicates another file's key — so a stray file can never
  ship unnoticed.
- **Usage:**
  ```dart
  String? get bundledLogoAsset =>
      bundledBankLogosEnabled ? bankLogoAssets[key] : null;
  ```
  (`lib/features/finance/services/bank_preset_service.dart:58-59`, the only reader.)
- **Notes:** The key is country-qualified because preset ids repeat across countries (`icbc`,
  `hsbc`, `vtb`, …). In a Store build the map is empty (the strip step rewrites the file), and
  `bundledLogoAsset` also returns null through `bundledBankLogosEnabled`, so the lookup is off by two
  independent means. A listed asset can still fail to load, so every caller falls back to the
  network chain.

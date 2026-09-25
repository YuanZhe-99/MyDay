# lib/features/finance/widgets/bank_logo_image.dart

`BankLogoImage` shows a bank preset's logo in the bank preset picker through a three-tier chain:
the bundled logo asset (Full builds only), then the network preview (`BankPreset.logoUrl`, the
Clearbit URL the picker used before v1.4.5), then a caller-supplied fallback widget (the picker
passes the bank's initial letter). It is a picker-only widget: a logo the user actually keeps is
copied into `images/` by `_fetchBankIcon` and rendered from there with
[`StoredImage`](../../../shared/widgets/stored_image.md). See
[Finance](../../../../features/finance.md#bankpresetservice).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `BankLogoImage({...})` | const constructor (`BankLogoImage`) | B | Create a bank logo view (`bank`, `fallback`, `size` default 32). |
| `createState` | method (`BankLogoImage`) | B | Create the `_BankLogoImageState` that loads the bundled asset once. |
| `initState` | method (`_BankLogoImageState`) | B | Start loading the bundled asset, if this build lists one. |
| `didUpdateWidget` | method (`_BankLogoImageState`) | B | Reload when a recycled tile is reused for a different preset. |
| [`_load`](#load) | static method (`_BankLogoImageState`) | A | Load an asset's bytes, mapping every failure to null. |
| `_network` | method (`_BankLogoImageState`, widget helper) | B | Build the network preview, or the fallback when there is no domain. |
| [`build`](#build) | method (`_BankLogoImageState`) | A | Build the bundled logo, the network preview, or the fallback. |

**Reconciliation:** `grep -c '/// Purpose:' lib/features/finance/widgets/bank_logo_image.dart`
returns 7, matching the 7 rows above exactly (2 Tier A, 5 Tier B).

## Documentation

### `static Future<ByteData?>? _load(String? key)` <a id="load"></a>
- **Kind:** private static method of `_BankLogoImageState`
- **Source:** `lib/features/finance/widgets/bank_logo_image.dart` (line 69)
- **Purpose:** Load a bundled asset's bytes, turning every failure into a null result.
- **Inputs:** `key` — the preset's `bundledLogoAsset`; null when this build has no bundled logo for
  it (always null in Store builds).
- **Returns:** `Future<ByteData?>?` — a null *future* when `key` is null (nothing to load);
  otherwise a future that completes with the bytes, or with null if the asset bundle throws.
- **Side effects:** Reads the asset bundle via `rootBundle.load`.
- **Algorithm:** Return null for a null `key`; otherwise
  `rootBundle.load(key).then<ByteData?>((d) => d, onError: (_) => null)`.
- **Usage:**
  ```dart
  _asset = _load(widget.bank.bundledLogoAsset);
  ```
  (`lib/features/finance/widgets/bank_logo_image.dart:48` in `initState`, and line 60 in
  `didUpdateWidget` when `oldWidget.bank.key != widget.bank.key`.)
- **Notes:** Loading raw bytes (instead of `SvgPicture.asset`) is deliberate: a manifest entry whose
  file is missing becomes a null result, so the tile degrades quietly to the network preview
  instead of throwing.

### `Widget build(BuildContext context)` <a id="build"></a>
- **Kind:** method of `_BankLogoImageState`
- **Source:** `lib/features/finance/widgets/bank_logo_image.dart` (line 97)
- **Purpose:** Render the bundled logo when it loads, otherwise the network preview, otherwise the
  fallback.
- **Inputs:** `context`; the widget's `bank`, `size`, `fallback`.
- **Returns:** `Widget`.
- **Side effects:** None beyond the asset load started in `initState` and the `Image.network` fetch
  inside `_network`.
- **Algorithm:**
  1. No pending asset future (no bundled logo) → `_network()`: `Image.network(bank.logoUrl)` at
     `size` × `size` with `BoxFit.cover`, whose `errorBuilder` shows `fallback`; an empty `logoUrl`
     shows `fallback` directly.
  2. Otherwise a `FutureBuilder<ByteData?>`: while loading, an empty `size` × `size` box.
  3. Null bytes (load failed) → `_network()`.
  4. Bytes present → a white `size` × `size` container with 12% padding, holding
     `SvgPicture.memory` (asset key ends in `.svg`, case-insensitive) or `Image.memory`, both with
     `BoxFit.contain`; either decoder's `errorBuilder` falls back to `_network()`.
- **Usage:**
  ```dart
  child: ClipOval(
    child: BankLogoImage(bank: bank, size: 40, fallback: initial),
  ),
  ```
  (`lib/features/finance/widgets/bank_preset_picker.dart:276-278`, the leading avatar of
  `_BankTile.build`; `initial` is the bank's first letter in its brand color.)
- **Notes:** Bundled logos always sit on white with `contain`: many SVG logos are wordmarks drawn
  for light backgrounds, and this keeps them whole and legible in dark mode. The network tier keeps
  the pre-v1.4.5 look (`cover`, no white backing).

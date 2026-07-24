# lib/features/intimacy/services/body_metrics.dart

Pure Dart, no Flutter imports: bra-size estimation for six regional standards and the PSI reference
index. `widgets/body_section.dart` is the sole caller, using this file only for calculation — the
raw measurements are the persisted source of truth and the estimate is always recomputed live, never
stored. See [Body Metrics](../../../../algorithms/body-metrics.md) for the full standards table and
the PSI formula derivation, and [Intimacy](../../../../features/intimacy.md#the-body-layer-v124) for
how the Body layer UI uses these results.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `BraStandard` (enum) | enum | B | `eu` / `frEs` / `jp` / `uk` / `us` / `auNz` — no Purpose block (see Reconciliation). |
| [`braStandardFromCode`](#brastandardfromcode) | top-level function | A | Map a persisted standard code string to its `BraStandard` enum value. |
| [`braStandardCode`](#brastandardcode) | top-level function | A | Map a `BraStandard` enum value back to its persisted code string. |
| [`BraSizeEstimate()`](#brasizeestimate-new) | const constructor (`BraSizeEstimate`) | A | Create a bra size estimate value (band, cup, display string). |
| [`_roundedBand`](#_roundedband) | private top-level function | A | Round an underbust measurement to the nearest 5 cm EU band value. |
| [`_ukBandFromEu`](#_ukbandfromeu) | private top-level function | A | Convert an EU band number to the UK/US band number. |
| [`estimateBraSize`](#estimatebrasize) | top-level function | A | Estimate a bra size from bust/underbust measurements for a chosen regional standard. |
| [`calculatePsi`](#calculatepsi) | top-level function | A | Calculate the PSI size-reference index from length/circumference measurements. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/intimacy/services/body_metrics.dart` reports 7,
matching 7 of the 8 rows above exactly — every one of those 7 `/// Purpose:` blocks sits directly
above the real declaration it documents (no misattached blocks). The one additional row is the
`BraStandard` enum: it carries only a plain `///` summary comment ("Supported regional bra sizing
standards."), no `Purpose:` block, but is still a real top-level declaration and is included for
completeness, consistent with how plain enums are handled elsewhere in this doc set (e.g.
`finance/models/finance.md`'s `AccountType`). The four private cup-label lookup tables (`_euCups`,
`_ukCups`, `_usCups`, `_jpCups`) are plain internal data, not counted as declarations, the same way
`weight_storage.dart`'s private `fileName`/`_writeQueue` fields are excluded. All 7 documented
declarations are Tier A: `braStandardFromCode`/`braStandardCode` are the two directions of this
file's public standard/code mapping, `BraSizeEstimate`'s constructor is a real (if simple)
model-style value constructor, and `_roundedBand`/`_ukBandFromEu`/`estimateBraSize`/`calculatePsi`
all carry real branching logic central to the file's one job.

## Documentation

### `BraStandard braStandardFromCode(String? code)` <a id="brastandardfromcode"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/services/body_metrics.dart` (line 14)
- **Purpose:** Map a persisted standard code, as stored in `BodyProfile.braStandard`, to its
  `BraStandard` enum value.
- **Inputs:** `code` — the raw nullable string (`'fr_es'`, `'jp'`, `'uk'`, `'us'`, `'au_nz'`, or
  anything else including `null`).
- **Returns:** `BraStandard`.
- **Side effects:** None.
- **Algorithm:**
  1. Switch-expression match `code` against the five non-EU codes.
  2. Any other value — including `null`, an empty string, or a corrupted/unrecognized code — falls
     through the `_` case to `BraStandard.eu`.
- **Usage:**
  ```dart
  final standard = braStandardFromCode(_profile.braStandard);
  ```
  (`lib/features/intimacy/widgets/body_section.dart:550`, before calling `estimateBraSize`.)
- **Notes:** This is the single fallback point that guarantees an always-valid standard even when
  the stored code is missing or from a future/unknown version.

### `String braStandardCode(BraStandard standard)` <a id="brastandardcode"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/services/body_metrics.dart` (line 28)
- **Purpose:** Map a `BraStandard` enum value back to the code string persisted in
  `BodyProfile.braStandard`.
- **Inputs:** `standard`.
- **Returns:** `String` (`'eu'`, `'fr_es'`, `'jp'`, `'uk'`, `'us'`, or `'au_nz'`).
- **Side effects:** None.
- **Algorithm:** Exhaustive switch expression, one case per enum value, with no `default` — the
  exact inverse of [`braStandardFromCode`](#brastandardfromcode).
- **Usage:**
  ```dart
  onSelected: (s) => onProfileChanged(
    _profile.copyWith(braStandard: braStandardCode(s)),
  ),
  ```
  (`lib/features/intimacy/widgets/body_section.dart:623`, the standard-picker chip row.)
- **Notes:** Being exhaustive with no `default` means adding a new `BraStandard` value without also
  extending this switch is a compile-time error, not a silent runtime fallback.

### `const BraSizeEstimate({required int band, required String cup, required String display})` <a id="brasizeestimate-new"></a>
- **Kind:** const constructor of `BraSizeEstimate`
- **Source:** `lib/features/intimacy/services/body_metrics.dart` (line 53)
- **Purpose:** Hold one calculated bra size estimate's band number, cup label, and ready-to-display
  string.
- **Inputs:** `band`, `cup`, `display`, all required.
- **Returns:** A new `BraSizeEstimate`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor.
- **Usage:** Only constructed inside [`estimateBraSize`](#estimatebrasize) (e.g. `return
  BraSizeEstimate(band: band, cup: cup, display: '$band$cup');`, line 125).
- **Notes:** Never persisted — the estimate is a derived display value, recalculated from the raw
  bust/underbust measurements on every read.

### `int? _roundedBand(double underbustCm)` <a id="_roundedband"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/body_metrics.dart` (line 82)
- **Purpose:** Round an underbust measurement to the nearest 5 cm EU band value, the common starting
  point every regional standard below builds from.
- **Inputs:** `underbustCm`.
- **Returns:** `int?` — `null` if the rounded band falls outside 50-130 cm.
- **Side effects:** None.
- **Algorithm:**
  1. `band = (underbustCm / 5).round() * 5`.
  2. Reject (`return null`) if `band < 50 || band > 130`.
- **Usage:** Called once at the top of [`estimateBraSize`](#estimatebrasize) (line 115):
  `final euBand = _roundedBand(underbustCm);`.
- **Notes:** Being private, this is only reachable through `estimateBraSize`; band granularity is
  fixed at 5 cm steps for every standard.

### `int? _ukBandFromEu(int euBand)` <a id="_ukbandfromeu"></a>
- **Kind:** private top-level function
- **Source:** `lib/features/intimacy/services/body_metrics.dart` (line 94)
- **Purpose:** Convert an EU band number to the UK/US band number system.
- **Inputs:** `euBand`.
- **Returns:** `int?` — `null` if the converted band falls outside 24-56.
- **Side effects:** None.
- **Algorithm:** `band = 28 + (euBand - 60) ~/ 5 * 2`, then bounds-checked. EU 60 maps to UK/US 28;
  every 5 cm EU step adds 2 to the UK/US band (EU 80 -> UK/US 36).
- **Usage:** Called from `estimateBraSize`'s `uk`/`us` case (line 137) and `auNz` case (line 145).
- **Notes:** EU bands only ever arrive here in 5 cm steps (from `_roundedBand`), so the integer
  division `~/` never truncates a fractional band.

### `BraSizeEstimate? estimateBraSize({required double bustCm, required double underbustCm, required BraStandard standard})` <a id="estimatebrasize"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/services/body_metrics.dart` (line 107)
- **Purpose:** Estimate a bra size from full bust and underbust measurements for one of six regional
  sizing standards.
- **Inputs:** `bustCm` — full bust circumference; `underbustCm`; `standard` — which of the six
  regional tables to apply.
- **Returns:** `BraSizeEstimate?` — `null` when inputs are non-positive, `bustCm - underbustCm <= 0`,
  or the measurements fall outside that standard's supported conversion range.
- **Side effects:** None.
- **Algorithm:** See
  [Body Metrics — The six standards](../../../../algorithms/body-metrics.md#the-six-standards) for
  the full per-standard band/cup derivation table. In brief: reject non-positive or non-overlapping
  inputs, derive the EU band via `_roundedBand`, then switch on `standard` to pick the band
  conversion (EU/FR-ES share the EU band shifted by standard; JP uses 2.5 cm cup centers and displays
  cup-first; UK/US/AU-NZ convert to the UK band via `_ukBandFromEu` and derive cup from whole-inch
  difference) — each branch returns `null` the moment its own valid range is exceeded rather than
  clamping to a nearest size.
- **Usage:**
  ```dart
  final estimate = (bust != null && underbust != null)
      ? estimateBraSize(
          bustCm: bust,
          underbustCm: underbust,
          standard: standard,
        )
      : null;
  ```
  (`lib/features/intimacy/widgets/body_section.dart:553-559`, `_buildBraCard`.)
- **Notes:** All six branches deliberately return `null` instead of an approximate size when out of
  range, so the UI can show an explicit out-of-range hint rather than a misleading precise result.

### `double? calculatePsi({double? lengthCm, double? baseCircumferenceCm, double? frontCircumferenceCm})` <a id="calculatepsi"></a>
- **Kind:** top-level function
- **Source:** `lib/features/intimacy/services/body_metrics.dart` (line 167)
- **Purpose:** Calculate the PSI size-reference index from erect length and one or two
  circumference measurements.
- **Inputs:** `lengthCm` — erect length (h); `baseCircumferenceCm`/`frontCircumferenceCm` — the two
  optional circumferences (C and c).
- **Returns:** `double?` — `null` if `lengthCm` is missing/`<= 0`, or if both circumferences are
  absent/non-positive.
- **Side effects:** None.
- **Algorithm:** See
  [Body Metrics — The PSI reference index](../../../../algorithms/body-metrics.md#the-psi-reference-index)
  for the full derivation. In brief: normalize each `<= 0` circumference to absent, require at least
  one; if only one is present it is reused for both (`base ??= front; front ??= base;`); convert all
  three cm inputs to dm; return `h * (c1*c1 + c2*c2 + c1*c2)`, which collapses to `3hC^2` in the
  single-circumference case.
- **Usage:**
  ```dart
  final psi = calculatePsi(
    lengthCm: _profile.erectLengthCm,
    baseCircumferenceCm: _profile.baseCircumferenceCm,
    frontCircumferenceCm: _profile.frontCircumferenceCm,
  );
  ```
  (`lib/features/intimacy/widgets/body_section.dart:902-906`, `_buildPsiCard`.)
- **Notes:** A dm-based truncated-cone volume approximation shown purely as a personal reference
  number, never a qualitative rating — the source comment explicitly notes its cited statistical
  reference is for population statistics, not the formula itself.

## Related pages

- [Body Metrics](../../../../algorithms/body-metrics.md) — full derivation of every standard's
  band/cup rules and the PSI formula.
- [Intimacy](../../../../features/intimacy.md#the-body-layer-v124) — the Body layer UI
  (`widgets/body_section.dart`) that is this file's only caller.
- [Data Formats](../../../../data-formats.md) — the `BodyProfile` fields these functions read.

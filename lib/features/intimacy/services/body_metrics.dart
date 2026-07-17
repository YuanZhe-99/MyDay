/// Pure body-metric calculations: bra size estimation for six regional
/// standards and the PSI reference index. No Flutter imports so everything
/// here is unit-testable.
library;

/// Supported regional bra sizing standards.
enum BraStandard { eu, frEs, jp, uk, us, auNz }

/// Purpose: Map a persisted standard code to its enum value.
/// Inputs: `code` as stored in `BodyProfile.braStandard`.
/// Returns: `BraStandard`.
/// Side effects: None.
/// Notes: Unknown or null codes fall back to the EU standard.
BraStandard braStandardFromCode(String? code) => switch (code) {
  'fr_es' => BraStandard.frEs,
  'jp' => BraStandard.jp,
  'uk' => BraStandard.uk,
  'us' => BraStandard.us,
  'au_nz' => BraStandard.auNz,
  _ => BraStandard.eu,
};

/// Purpose: Map a standard enum value to its persisted code.
/// Inputs: `standard`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: Codes are stored in `BodyProfile.braStandard`.
String braStandardCode(BraStandard standard) => switch (standard) {
  BraStandard.eu => 'eu',
  BraStandard.frEs => 'fr_es',
  BraStandard.jp => 'jp',
  BraStandard.uk => 'uk',
  BraStandard.us => 'us',
  BraStandard.auNz => 'au_nz',
};

/// A calculated bra size estimate with structured parts.
class BraSizeEstimate {
  /// Band or dress-size number for the selected standard.
  final int band;

  /// Cup label for the selected standard.
  final String cup;

  /// Ready-to-display size string (Japan uses cup-first form like `C75`).
  final String display;

  /// Purpose: Create a bra size estimate value.
  /// Inputs: `band`, `cup`, `display`.
  /// Returns: A new `BraSizeEstimate` instance.
  /// Side effects: None.
  /// Notes: Only the raw measurements are persisted, never this estimate.
  const BraSizeEstimate({
    required this.band,
    required this.cup,
    required this.display,
  });
}

const _euCups = ['AA', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
const _ukCups = ['A', 'B', 'C', 'D', 'DD', 'E', 'F', 'FF', 'G', 'GG', 'H'];
const _usCups = [
  'A',
  'B',
  'C',
  'D',
  'DD/E',
  'DDD/F',
  'G',
  'H',
  'I',
  'J',
  'K',
];
const _jpCups = ['AAA', 'AA', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

/// Purpose: Round an underbust measurement to the nearest 5 cm band value.
/// Inputs: `underbustCm`.
/// Returns: `int?`.
/// Side effects: None.
/// Notes: Returns null outside the supported 50-130 cm band range.
int? _roundedBand(double underbustCm) {
  final band = (underbustCm / 5).round() * 5;
  if (band < 50 || band > 130) return null;
  return band;
}

/// Purpose: Convert an EU band number to the UK/US band number.
/// Inputs: `euBand`.
/// Returns: `int?`.
/// Side effects: None.
/// Notes: EU 60 -> 28, each 5 cm EU step adds 2 (EU 80 -> 36); odd EU
/// bands outside the mapped grid never occur because bands are 5 cm steps.
int? _ukBandFromEu(int euBand) {
  final band = 28 + (euBand - 60) ~/ 5 * 2;
  if (band < 24 || band > 56) return null;
  return band;
}

/// Purpose: Estimate a bra size from full bust and underbust measurements.
/// Inputs: `bustCm` full bust, `underbustCm`, and the regional `standard`.
/// Returns: `BraSizeEstimate?`.
/// Side effects: None.
/// Notes: Returns null when inputs are non-positive or the measurements
/// fall outside the supported conversion tables. Results are estimates
/// only; the raw measurements are the stored source of truth.
BraSizeEstimate? estimateBraSize({
  required double bustCm,
  required double underbustCm,
  required BraStandard standard,
}) {
  if (bustCm <= 0 || underbustCm <= 0) return null;
  final diff = bustCm - underbustCm;
  if (diff <= 0) return null;
  final euBand = _roundedBand(underbustCm);
  if (euBand == null) return null;

  switch (standard) {
    case BraStandard.eu:
    case BraStandard.frEs:
      // EU cups per 2 cm of difference starting at 10 cm -> AA.
      if (diff < 10 || diff >= 28) return null;
      final cup = _euCups[((diff - 10) / 2).floor()];
      final band = standard == BraStandard.eu ? euBand : euBand + 15;
      return BraSizeEstimate(band: band, cup: cup, display: '$band$cup');
    case BraStandard.jp:
      // JIS cups sit on 2.5 cm centers from 5.0 cm (AAA), each +-1.25 cm,
      // giving half-open bands [center - 1.25, center + 1.25).
      if (diff < 3.75 || diff >= 28.75) return null;
      final index = ((diff - 3.75) / 2.5).floor();
      if (index < 0 || index >= _jpCups.length) return null;
      final cup = _jpCups[index];
      // Japanese sizes are displayed cup-first, e.g. C75.
      return BraSizeEstimate(band: euBand, cup: cup, display: '$cup$euBand');
    case BraStandard.uk:
    case BraStandard.us:
      final band = _ukBandFromEu(euBand);
      if (band == null) return null;
      final inches = (diff / 2.54).round();
      if (inches < 1 || inches > 11) return null;
      final cups = standard == BraStandard.uk ? _ukCups : _usCups;
      final cup = cups[inches - 1];
      return BraSizeEstimate(band: band, cup: cup, display: '$band$cup');
    case BraStandard.auNz:
      final ukBand = _ukBandFromEu(euBand);
      if (ukBand == null) return null;
      // AU/NZ dress-size band: UK 30 -> 8, each UK step adds 2.
      final band = ukBand - 22;
      if (band < 4) return null;
      final inches = (diff / 2.54).round();
      if (inches < 1 || inches > 11) return null;
      final cup = _ukCups[inches - 1];
      return BraSizeEstimate(band: band, cup: cup, display: '$band$cup');
  }
}

/// Purpose: Calculate the PSI size-reference index from cm measurements.
/// Inputs: `lengthCm` erect length h, optional `baseCircumferenceCm` C and
/// `frontCircumferenceCm` c.
/// Returns: `double?`.
/// Side effects: None.
/// Notes: Values are converted to decimeters before applying
/// `PSI = h * (C^2 + c^2 + C*c)`. When only one circumference is entered it
/// is used for both C and c, which reduces the formula to `3hC^2`. PSI is a
/// truncated-cone shape approximation for personal reference only, not a
/// geometric volume and never a qualitative rating.
double? calculatePsi({
  double? lengthCm,
  double? baseCircumferenceCm,
  double? frontCircumferenceCm,
}) {
  if (lengthCm == null || lengthCm <= 0) return null;
  var base = baseCircumferenceCm;
  var front = frontCircumferenceCm;
  if (base != null && base <= 0) base = null;
  if (front != null && front <= 0) front = null;
  if (base == null && front == null) return null;
  base ??= front;
  front ??= base;
  final h = lengthCm / 10;
  final c1 = base! / 10;
  final c2 = front! / 10;
  return h * (c1 * c1 + c2 * c2 + c1 * c2);
}

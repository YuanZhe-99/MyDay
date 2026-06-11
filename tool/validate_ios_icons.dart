import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _appIconSetPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const _contentsPath = '$_appIconSetPath/Contents.json';

/// Purpose: Hold alpha-channel extrema for a PNG image.
/// Inputs: `min`, `max`, and `transparentPixels`.
/// Returns: A value object for alpha validation.
/// Side effects: None.
/// Notes: `transparentPixels` counts pixels whose alpha is exactly zero.
class AlphaStats {
  /// Purpose: Create immutable alpha statistics.
  /// Inputs: `min`, `max`, and `transparentPixels`.
  /// Returns: An `AlphaStats` instance.
  /// Side effects: None.
  /// Notes: None.
  const AlphaStats({
    required this.min,
    required this.max,
    required this.transparentPixels,
  });

  final int min;
  final int max;
  final int transparentPixels;

  /// Purpose: Report whether any pixel is fully transparent.
  /// Inputs: None.
  /// Returns: True when at least one pixel has alpha 0.
  /// Side effects: None.
  /// Notes: None.
  bool get hasTransparency => transparentPixels > 0;

  /// Purpose: Report whether all pixels are fully opaque.
  /// Inputs: None.
  /// Returns: True when alpha never drops below 255.
  /// Side effects: None.
  /// Notes: RGB images are treated as opaque by `alphaStats`.
  bool get isOpaque => min == 255 && max == 255;
}

/// Purpose: Hold one iOS AppIcon Contents.json image entry.
/// Inputs: `filename`, `size`, `scale`, and optional `appearance`.
/// Returns: A value object for AppIcon validation.
/// Side effects: None.
/// Notes: `appearance` is null for default and marketing icons.
class IconEntry {
  /// Purpose: Create an immutable icon entry value.
  /// Inputs: `filename`, `size`, `scale`, and optional `appearance`.
  /// Returns: An `IconEntry` instance.
  /// Side effects: None.
  /// Notes: None.
  const IconEntry({
    required this.filename,
    required this.size,
    required this.scale,
    required this.appearance,
  });

  final String filename;
  final String size;
  final String scale;
  final String? appearance;

  /// Purpose: Calculate the required pixel side for this icon entry.
  /// Inputs: None.
  /// Returns: Expected square PNG side in pixels.
  /// Side effects: None.
  /// Notes: Handles fractional iPad sizes such as 83.5 at 2x.
  int get expectedPixels {
    final pointSize = double.parse(size.split('x').first);
    final multiplier = double.parse(scale.replaceAll('x', ''));
    return (pointSize * multiplier).round();
  }
}

/// Purpose: Decode a PNG file from disk.
/// Inputs: PNG `path`.
/// Returns: Decoded image.
/// Side effects: Reads the file and throws if it cannot be decoded.
/// Notes: This validator only supports PNG icon assets.
img.Image readPng(String path) {
  final image = img.decodePng(File(path).readAsBytesSync());
  if (image == null) {
    throw StateError('Could not decode $path');
  }
  return image;
}

/// Purpose: Calculate alpha extrema for an image.
/// Inputs: Decoded `image`.
/// Returns: Alpha statistics.
/// Side effects: None.
/// Notes: Images without alpha are considered fully opaque.
AlphaStats alphaStats(img.Image image) {
  if (!image.hasAlpha) {
    return const AlphaStats(min: 255, max: 255, transparentPixels: 0);
  }
  var minAlpha = 255;
  var maxAlpha = 0;
  var transparentPixels = 0;
  for (final pixel in image) {
    final alpha = pixel.a.toInt();
    minAlpha = math.min(minAlpha, alpha);
    maxAlpha = math.max(maxAlpha, alpha);
    if (alpha == 0) {
      transparentPixels++;
    }
  }
  return AlphaStats(
    min: minAlpha,
    max: maxAlpha,
    transparentPixels: transparentPixels,
  );
}

/// Purpose: Check whether all visible pixels are grayscale.
/// Inputs: Decoded `image`.
/// Returns: True when every non-transparent pixel has equal RGB channels.
/// Side effects: None.
/// Notes: Transparent pixels are ignored because they are not user-visible.
bool isVisibleContentGrayscale(img.Image image) {
  for (final pixel in image) {
    if (pixel.a == 0) {
      continue;
    }
    if (pixel.r != pixel.g || pixel.g != pixel.b) {
      return false;
    }
  }
  return true;
}

/// Purpose: Parse iOS AppIcon entries from Contents.json.
/// Inputs: None.
/// Returns: List of icon entries.
/// Side effects: Reads `Contents.json`.
/// Notes: Only fields relevant to file, size, scale, and appearance are kept.
List<IconEntry> readContentsEntries() {
  final decoded = json.decode(File(_contentsPath).readAsStringSync());
  final images = (decoded as Map<String, dynamic>)['images'] as List<dynamic>;
  return images.map((raw) {
    final item = raw as Map<String, dynamic>;
    final appearances = item['appearances'] as List<dynamic>?;
    return IconEntry(
      filename: item['filename'] as String,
      size: item['size'] as String,
      scale: item['scale'] as String,
      appearance: appearances == null || appearances.isEmpty
          ? null
          : (appearances.first as Map<String, dynamic>)['value'] as String?,
    );
  }).toList();
}

/// Purpose: Validate top-level iOS source icon files.
/// Inputs: None.
/// Returns: A list of human-readable validation summaries.
/// Side effects: Reads source PNG files and throws on invalid output.
/// Notes: Default must be opaque; dark and tinted must retain transparency.
List<String> validateSourceIcons() {
  final lines = <String>[];
  final defaultIcon = readPng('assets/icon/app_icon_ios.png');
  final darkIcon = readPng('assets/icon/app_icon_ios_dark.png');
  final tintedIcon = readPng('assets/icon/app_icon_ios_tinted.png');

  for (final entry in [
    ('default', defaultIcon),
    ('dark', darkIcon),
    ('tinted', tintedIcon),
  ]) {
    if (entry.$2.width != 2560 || entry.$2.height != 2560) {
      throw StateError('${entry.$1} source is not 2560x2560');
    }
  }

  final defaultAlpha = alphaStats(defaultIcon);
  final darkAlpha = alphaStats(darkIcon);
  final tintedAlpha = alphaStats(tintedIcon);
  if (!defaultAlpha.isOpaque) {
    throw StateError('default source is not fully opaque');
  }
  if (!darkAlpha.hasTransparency || darkAlpha.max == 0) {
    throw StateError('dark source does not contain transparent artwork');
  }
  if (!tintedAlpha.hasTransparency || tintedAlpha.max == 0) {
    throw StateError('tinted source does not contain transparent artwork');
  }
  if (!isVisibleContentGrayscale(tintedIcon)) {
    throw StateError('tinted source visible pixels are not grayscale');
  }

  lines.add(
    'sources: default opaque, dark transparent, tinted transparent grayscale',
  );
  lines.add(
    'source alpha: default ${defaultAlpha.min}-${defaultAlpha.max}, '
    'dark ${darkAlpha.min}-${darkAlpha.max}, '
    'tinted ${tintedAlpha.min}-${tintedAlpha.max}',
  );
  return lines;
}

/// Purpose: Validate generated AppIcon files against Contents.json.
/// Inputs: None.
/// Returns: A list of human-readable validation summaries.
/// Side effects: Reads Contents.json and generated PNG files.
/// Notes: The 1024 default icon is intentionally referenced twice.
List<String> validateAppIconSet() {
  final entries = readContentsEntries();
  final referenced = entries.map((entry) => entry.filename).toSet();
  final actualFiles = Directory(_appIconSetPath)
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.png'))
      .map((file) => file.uri.pathSegments.last)
      .toSet();

  final missing = referenced.difference(actualFiles).toList()..sort();
  final unreferenced = actualFiles.difference(referenced).toList()..sort();
  if (missing.isNotEmpty) {
    throw StateError('missing referenced files: ${missing.join(', ')}');
  }
  if (unreferenced.isNotEmpty) {
    throw StateError('unreferenced PNG files: ${unreferenced.join(', ')}');
  }

  var defaultCount = 0;
  var darkCount = 0;
  var tintedCount = 0;
  for (final entry in entries) {
    final image = readPng('$_appIconSetPath/${entry.filename}');
    if (image.width != entry.expectedPixels ||
        image.height != entry.expectedPixels) {
      throw StateError(
        '${entry.filename} is ${image.width}x${image.height}, '
        'expected ${entry.expectedPixels}x${entry.expectedPixels}',
      );
    }

    final alpha = alphaStats(image);
    if (entry.appearance == 'dark') {
      darkCount++;
      if (!alpha.hasTransparency || alpha.max == 0) {
        throw StateError('${entry.filename} is not a transparent dark icon');
      }
    } else if (entry.appearance == 'tinted') {
      tintedCount++;
      if (!alpha.hasTransparency || alpha.max == 0) {
        throw StateError('${entry.filename} is not a transparent tinted icon');
      }
      if (!isVisibleContentGrayscale(image)) {
        throw StateError('${entry.filename} is not grayscale');
      }
    } else {
      defaultCount++;
      if (!alpha.isOpaque) {
        throw StateError('${entry.filename} is not fully opaque');
      }
    }
  }

  return [
    'contents: ${entries.length} entries, ${referenced.length} unique PNG files',
    'variants: default entries=$defaultCount, dark entries=$darkCount, tinted entries=$tintedCount',
    'generated PNGs: dimensions, opacity, transparency, and grayscale checks passed',
  ];
}

/// Purpose: Run iOS icon source and AppIcon validation.
/// Inputs: None.
/// Returns: None.
/// Side effects: Prints validation summaries and exits with failure on errors.
/// Notes: Run from the repository root after icon generation.
void main() {
  final lines = [...validateSourceIcons(), ...validateAppIconSet()];
  for (final line in lines) {
    stdout.writeln(line);
  }
}

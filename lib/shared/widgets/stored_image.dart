import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;

/// Purpose: Tell whether a stored image file is an SVG.
/// Inputs: `file`.
/// Returns: `bool` — true for a `.svg` extension (case-insensitive).
/// Side effects: None.
/// Notes: `images/` names come from `ImageService`, which always sets the extension from the
/// content type or asset key, so the extension is authoritative.
bool isSvgFile(File file) => p.extension(file.path).toLowerCase() == '.svg';

/// Renders an image file from app storage with the SVG or raster decoder, by extension.
class StoredImage extends StatelessWidget {
  final File file;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Purpose: Create a stored-image view.
  /// Inputs: `file` (resolved by `ImageService.resolve`), `width`, `height`, `fit`.
  /// Returns: A new `StoredImage` instance.
  /// Side effects: None.
  /// Notes: Callers keep their existing `existsSync()` guard; this widget only picks a decoder.
  const StoredImage(
    this.file, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  /// Purpose: Build the SVG or raster image for `file`.
  /// Inputs: `context`.
  /// Returns: `SvgPicture.file` for `.svg`, otherwise `Image.file`.
  /// Side effects: Reads the file when painted.
  /// Notes: An SVG that cannot be parsed renders as an empty box instead of throwing.
  @override
  Widget build(BuildContext context) {
    if (isSvgFile(file)) {
      return SvgPicture.file(
        file,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (_) => SizedBox(width: width, height: height),
        errorBuilder: (_, _, _) => SizedBox(width: width, height: height),
      );
    }
    return Image.file(file, width: width, height: height, fit: fit);
  }
}

/// Circular avatar for a stored image, replacing `CircleAvatar(backgroundImage: FileImage(..))`.
class StoredImageAvatar extends StatelessWidget {
  final File file;
  final double radius;
  final Color? backgroundColor;

  /// Purpose: Create a circular stored-image avatar.
  /// Inputs: `file`, `radius` (default 20, the `CircleAvatar` default), `backgroundColor`.
  /// Returns: A new `StoredImageAvatar` instance.
  /// Side effects: None.
  /// Notes: `CircleAvatar.backgroundImage` needs an `ImageProvider`, which an SVG cannot supply,
  /// so the image is a clipped child instead.
  const StoredImageAvatar(
    this.file, {
    super.key,
    this.radius = 20,
    this.backgroundColor,
  });

  /// Purpose: Build the clipped avatar.
  /// Inputs: `context`.
  /// Returns: A `CircleAvatar` with the image clipped to its circle.
  /// Side effects: None beyond `StoredImage`.
  /// Notes: Raster images fill the circle (`cover`, as before) over `backgroundColor`. SVG logos
  /// are wordmarks as often as symbols and are drawn for light backgrounds, so they always sit on
  /// a white disc with `contain` and a small inset, staying whole and legible in dark mode.
  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    if (isSvgFile(file)) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Padding(
            padding: EdgeInsets.all(radius * 0.18),
            child: StoredImage(
              file,
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: StoredImage(file, width: size, height: size, fit: BoxFit.cover),
      ),
    );
  }
}

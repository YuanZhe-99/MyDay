// Install reviewed bank logo candidates into assets/bank_logos/ and regenerate the manifest.
//
// Run: dart run tool/apply_bank_logo_choices.dart --dir <scratch dir from fetch_bank_logos.dart>
//
// Reads tool/bank_logo_choices.json: { "<country>/<id>": "c0.svg" | "c0.svg#crop=x,y,w,h" |
// "c0.svg@png" | "reject" }. "#crop=" keeps only the symbol of a symbol-plus-wordmark SVG.
// SVGs have their <style> rules inlined (flutter_svg ignores style sheets); "@png" installs
// Wikimedia's PNG rendering of that SVG instead. Rasters are
// centred on a white square canvas with a margin and scaled to
// 256 px, so every PNG fills a circular avatar evenly. Presets that are rejected or absent get no
// bundled logo and keep using the network chain.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'bank_logo_manifest_writer.dart';
import 'gen_bank_logo_manifest.dart' as gen;

const _rasterEdge = 256;
const _userAgent =
    'MyDayLogoFetcher/1.1 (https://github.com/YuanZhe-99/MyDay; one-off dev tool)';

/// Purpose: Normalize a raster logo to a 256 px white square PNG.
/// Inputs: `bytes` of a PNG/JPEG/WebP/GIF.
/// Returns: `List<int>?` PNG bytes, or null when the image cannot be decoded.
/// Side effects: None.
/// Notes: Transparent pixels become white, matching how the app shows SVG logos. Small sources
/// are scaled up to 256 px; the reviewer rejects ones too small to stay sharp.
List<int>? normalizeRaster(List<int> bytes) {
  final src = img.decodeImage(bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
  if (src == null) return null;
  final side = (math.max(src.width, src.height) * 1.16).round();
  final canvas = img.Image(width: side, height: side, numChannels: 4)
    ..clear(img.ColorRgba8(255, 255, 255, 255));
  img.compositeImage(
    canvas,
    src,
    dstX: (side - src.width) ~/ 2,
    dstY: (side - src.height) ~/ 2,
  );
  // Always exactly 256 px: downscale with averaging, upscale smoothly (cubic).
  final out = img.copyResize(
    canvas,
    width: _rasterEdge,
    height: _rasterEdge,
    interpolation: side > _rasterEdge
        ? img.Interpolation.average
        : img.Interpolation.cubic,
  );
  return img.encodePng(out, level: 9);
}

final RegExp _styleBlock = RegExp(r'<style[^>]*>([\s\S]*?)</style>', caseSensitive: false);
final RegExp _cssRule = RegExp(r'([^{}]+)\{([^{}]*)\}');
final RegExp _classedTag = RegExp(r'<([a-zA-Z][\w:.-]*)(\s[^<>]*?\bclass\s*=\s*"([^"]*)"[^<>]*?)(/?)>');

/// Purpose: Inline an SVG's `<style>` class rules into each element's `style` attribute.
/// Inputs: `svg` source.
/// Returns: `String` SVG with class declarations merged into `style` attributes.
/// Side effects: None.
/// Notes: flutter_svg ignores `<style>` sheets, so Illustrator-style exports (`.st0{fill:…}`)
/// otherwise render black. Only simple `.class` and bare element selectors are understood —
/// enough for exported logos. Rule order is preserved, and an element's own inline `style`
/// still wins, matching CSS precedence for these cases.
String inlineSvgStyles(String svg) {
  final classRules = <String, String>{};
  final tagRules = <String, String>{};
  for (final block in _styleBlock.allMatches(svg)) {
    final css = block[1]!
        .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    for (final rule in _cssRule.allMatches(css)) {
      final decls = rule[2]!.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (decls.isEmpty) continue;
      for (final sel in rule[1]!.split(',').map((s) => s.trim())) {
        final cls = RegExp(r'^\.([\w-]+)$').firstMatch(sel);
        if (cls != null) {
          classRules[cls[1]!] = '${classRules[cls[1]!] ?? ''}$decls;';
        } else if (RegExp(r'^[a-zA-Z]+$').hasMatch(sel)) {
          tagRules[sel] = '${tagRules[sel] ?? ''}$decls;';
        }
      }
    }
  }
  if (classRules.isEmpty && tagRules.isEmpty) return svg;

  var out = svg.replaceAllMapped(_classedTag, (m) {
    final tag = m[1]!;
    var attrs = m[2]!;
    final merged = StringBuffer(tagRules[tag] ?? '');
    for (final c in m[3]!.split(RegExp(r'\s+'))) {
      merged.write(classRules[c] ?? '');
    }
    if (merged.isEmpty) return m[0]!;
    final own = RegExp(r'\sstyle\s*=\s*"([^"]*)"').firstMatch(attrs);
    if (own != null) {
      attrs = attrs.replaceFirst(own[0]!, ' style="$merged${own[1]}"');
    } else {
      attrs = '$attrs style="$merged"';
    }
    return '<$tag$attrs${m[4]}>';
  });
  // Bare element selectors also apply to elements without a class attribute.
  for (final e in tagRules.entries) {
    out = out.replaceAllMapped(
      RegExp('<(${e.key})((?:\\s(?![^<>]*\\bclass=)[^<>]*?)?)(/?)>'),
      (m) => (m[2] ?? '').contains('style="')
          ? m[0]!
          : '<${m[1]}${m[2] ?? ''} style="${e.value}"${m[3]}>',
    );
  }
  return out;
}

/// Purpose: Crop an SVG to its symbol by replacing the root element's viewport.
/// Inputs: `svg` source; `crop` — `"x,y,w,h"` in the SVG's user units.
/// Returns: `String` SVG whose root `viewBox` is the crop and whose `width`/`height` are `w`/`h`.
/// Side effects: None.
/// Notes: Used to show only the symbol of a symbol-plus-wordmark logo in the circular avatar.
/// No path is edited; content outside the viewBox is clipped by the root viewport. Crops come
/// from measuring each shape's bounding box in a browser and are reviewed as rendered by
/// flutter_svg.
String cropSvg(String svg, String crop) {
  final v = crop.split(',').map((s) => s.trim()).toList();
  if (v.length != 4) throw FormatException('crop must be x,y,w,h: $crop');
  return svg.replaceFirstMapped(RegExp(r'<svg\b([^>]*)>', caseSensitive: false), (m) {
    final attrs = m[1]!.replaceAll(
      RegExp(r'''\s(?:viewBox|width|height|preserveAspectRatio)\s*=\s*(?:"[^"]*"|'[^']*')''',
          caseSensitive: false),
      '',
    );
    return '<svg$attrs viewBox="${v.join(' ')}" width="${v[2]}" height="${v[3]}">';
  });
}

/// Purpose: Build the Wikimedia PNG rendering URL for a Commons/Wikipedia SVG file URL.
/// Inputs: `url` — `https://upload.wikimedia.org/wikipedia/<wiki>/<a>/<ab>/<Name>.svg`.
/// Returns: `String?` thumbnail URL at 500 px (a width Wikimedia serves; arbitrary widths
/// return HTTP 400), or null for non-Wikimedia URLs.
/// Side effects: None.
/// Notes: Used for the few SVGs flutter_svg cannot draw even after style inlining
/// (foreignObject switches, unsupported clip/gradient combinations).
String? wikimediaPngUrl(String url) {
  final u = Uri.parse(url.split('?').first);
  if (u.host != 'upload.wikimedia.org' || u.pathSegments.length < 5) return null;
  final seg = u.pathSegments;
  final name = seg.last;
  return 'https://upload.wikimedia.org/${[
    ...seg.take(2),
    'thumb',
    ...seg.skip(2),
  ].join('/')}/500px-$name.png';
}


/// Purpose: Install every accepted choice and regenerate the manifest.
/// Inputs: `args` — `--dir <scratch>`.
/// Returns: `Future<void>`.
/// Side effects: Replaces the contents of `assets/bank_logos/`; rewrites the manifest; may
/// download Wikimedia PNG renderings (cached next to the candidate); prints coverage and size.
/// Notes: The logo directory is rebuilt from scratch each run, so a changed choice never leaves
/// a stale file behind. A choice of `c0.svg@png` installs Wikimedia's own 500 px PNG rendering of
/// that SVG instead of the SVG (for the few files flutter_svg cannot draw).
Future<void> main(List<String> args) async {
  final dir = Directory(args[args.indexOf('--dir') + 1]);
  final choices = (jsonDecode(File('tool/bank_logo_choices.json').readAsStringSync()) as Map)
      .cast<String, String>();
  final assetDir = Directory(bankLogoAssetDir);
  if (assetDir.existsSync()) assetDir.deleteSync(recursive: true);
  assetDir.createSync(recursive: true);

  var installed = 0;
  final problems = <String>[];
  for (final entry in choices.entries) {
    if (entry.value == 'reject') continue;
    final stem = entry.key.replaceFirst('/', '_');
    final cropAt = entry.value.indexOf('#crop=');
    final crop = cropAt < 0 ? null : entry.value.substring(cropAt + 6);
    final value = cropAt < 0 ? entry.value : entry.value.substring(0, cropAt);
    final asPng = value.endsWith('@png');
    final file = asPng ? value.substring(0, value.length - 4) : value;
    final src = File(p.join(dir.path, stem, file));
    if (!src.existsSync()) {
      problems.add('${entry.key}: missing $file');
      continue;
    }
    final ext = p.extension(src.path).toLowerCase();
    if (ext == '.svg' && !asPng) {
      var svg = inlineSvgStyles(src.readAsStringSync());
      if (crop != null) svg = cropSvg(svg, crop);
      File(p.join(assetDir.path, '$stem.svg')).writeAsStringSync(svg);
    } else {
      var source = src;
      if (asPng) {
        source = File('${src.path}.wm.png');
        if (!source.existsSync()) {
          final index = jsonDecode(
            File(p.join(dir.path, stem, 'candidates.json')).readAsStringSync(),
          ) as Map<String, dynamic>;
          final cand = (index['candidates'] as List)
              .cast<Map<String, dynamic>>()
              .firstWhere((c) => c['file'] == file);
          final thumb = wikimediaPngUrl(cand['url'] as String);
          final r = thumb == null
              ? null
              : await http.get(Uri.parse(thumb), headers: {'User-Agent': _userAgent});
          if (r == null || r.statusCode != 200) {
            problems.add('${entry.key}: no PNG rendering for $file (${r?.statusCode})');
            continue;
          }
          source.writeAsBytesSync(r.bodyBytes);
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      final png = normalizeRaster(source.readAsBytesSync());
      if (png == null) {
        problems.add('${entry.key}: undecodable ${entry.value}');
        continue;
      }
      File(p.join(assetDir.path, '$stem.png')).writeAsBytesSync(png);
    }
    installed++;
  }

  final assets = gen.collectBankLogos(Directory.current);
  File(bankLogoManifestPath).writeAsStringSync(renderBankLogoManifest(assets));
  var bytes = 0;
  for (final a in assets.values) {
    bytes += File(a).lengthSync();
  }
  stdout.writeln('installed $installed logos, ${(bytes / 1024).toStringAsFixed(0)} KB');
  for (final pr in problems) {
    stderr.writeln('  ! $pr');
  }
}

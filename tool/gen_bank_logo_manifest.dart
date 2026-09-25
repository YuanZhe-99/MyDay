// Regenerate lib/features/finance/services/bank_logo_manifest.g.dart from assets/bank_logos/.
// Run: dart run tool/gen_bank_logo_manifest.dart

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'bank_logo_manifest_writer.dart';

/// Purpose: Build the key → asset map from the logo directory, validating every file.
/// Inputs: `root` — project root.
/// Returns: `Map<String, String>` preset key → asset path.
/// Side effects: Reads `assets/banks.json` and lists `assets/bank_logos/`.
/// Notes: Throws `FormatException` for a file whose stem is not `<country>_<id>` of a preset, or
/// whose extension is not svg/png, so a stray file can never ship unnoticed.
Map<String, String> collectBankLogos(Directory root) {
  final presets =
      (jsonDecode(
                File(
                  p.join(root.path, 'assets', 'banks.json'),
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();
  final keyByStem = {
    for (final b in presets)
      '${b['country']}_${b['id']}': '${b['country']}/${b['id']}',
  };
  final dir = Directory(p.join(root.path, bankLogoAssetDir));
  final out = <String, String>{};
  if (!dir.existsSync()) return out;
  for (final f in dir.listSync().whereType<File>()) {
    final name = p.basename(f.path);
    final ext = p.extension(name).toLowerCase();
    final stem = p.basenameWithoutExtension(name);
    if (ext != '.svg' && ext != '.png') {
      throw FormatException('Unsupported logo file type: $name');
    }
    final key = keyByStem[stem];
    if (key == null) {
      throw FormatException('Logo file does not match a preset: $name');
    }
    if (out.containsKey(key)) throw FormatException('Two logo files for $key');
    out[key] = '$bankLogoAssetDir$name';
  }
  return out;
}

/// Purpose: Write the manifest and print coverage and size.
/// Inputs: None.
/// Returns: None.
/// Side effects: Overwrites the manifest file; prints to stdout.
/// Notes: Run from the project root.
void main() {
  final root = Directory.current;
  final assets = collectBankLogos(root);
  File(
    p.join(root.path, bankLogoManifestPath),
  ).writeAsStringSync(renderBankLogoManifest(assets));
  var bytes = 0;
  for (final a in assets.values) {
    bytes += File(p.join(root.path, a)).lengthSync();
  }
  final svg = assets.values.where((a) => a.endsWith('.svg')).length;
  stdout.writeln(
    '${assets.length} logos ($svg SVG, ${assets.length - svg} PNG), '
    '${(bytes / 1024).toStringAsFixed(0)} KB → $bankLogoManifestPath',
  );
}

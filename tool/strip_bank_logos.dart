// Remove every bundled bank logo from the tree before a Store build.
//
// Run (CI, on a throwaway checkout): dart run tool/strip_bank_logos.dart
//   --dry-run   report what would change, change nothing
//   --verify    exit 1 if any logo artifact is still present (run after stripping)
//   --root DIR  operate on DIR instead of the current directory
//
// Never run it without --dry-run in a working tree you care about; restore with
// `git checkout -- assets/bank_logos pubspec.yaml lib/features/finance/services/bank_logo_manifest.g.dart`.

import 'dart:io';

import 'package:path/path.dart' as p;

import 'bank_logo_manifest_writer.dart';

final RegExp _pubspecLine = RegExp(r'^\s*-\s*assets/bank_logos/\s*$');

/// Result of one strip run.
class StripResult {
  final int filesDeleted;
  final int bytesFreed;
  final bool pubspecLineRemoved;
  final bool manifestEmptied;

  /// Purpose: Create a strip result.
  /// Inputs: Counts and flags of the work done (or that would be done in a dry run).
  /// Returns: A new `StripResult` instance.
  /// Side effects: None.
  /// Notes: None.
  const StripResult({
    required this.filesDeleted,
    required this.bytesFreed,
    required this.pubspecLineRemoved,
    required this.manifestEmptied,
  });

  /// Purpose: Report whether the run had anything to do.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: False on a second run over an already stripped tree.
  bool get didWork => filesDeleted > 0 || pubspecLineRemoved || manifestEmptied;

  /// Purpose: Render a one-line summary.
  /// Inputs: None.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: None.
  @override
  String toString() =>
      '$filesDeleted file(s), ${(bytesFreed / 1024).toStringAsFixed(0)} KB, '
      'pubspec line ${pubspecLineRemoved ? 'removed' : 'absent'}, '
      'manifest ${manifestEmptied ? 'emptied' : 'already empty'}';
}

/// Purpose: Report whether the manifest source still lists at least one logo.
/// Inputs: `source`.
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Any quoted `'assets/bank_logos/` value counts as an entry.
bool _manifestHasEntries(String source) =>
    source.contains("'$bankLogoAssetDir");

/// Purpose: Remove every bundled bank logo byte and reference from the tree.
/// Inputs: `root` — project directory; `dryRun`.
/// Returns: `StripResult` describing the work done (or that would be done).
/// Side effects: Deletes `assets/bank_logos/`, removes its pubspec asset line and rewrites the
/// manifest to an empty map. Nothing changes when `dryRun` is true.
/// Notes: Idempotent. Never touches git.
StripResult stripBankLogos(Directory root, {bool dryRun = false}) {
  final dir = Directory(p.join(root.path, bankLogoAssetDir));
  var files = 0;
  var bytes = 0;
  if (dir.existsSync()) {
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      files++;
      bytes += f.lengthSync();
    }
    if (!dryRun) dir.deleteSync(recursive: true);
  }

  var lineRemoved = false;
  final pubspec = File(p.join(root.path, 'pubspec.yaml'));
  if (pubspec.existsSync()) {
    final lines = pubspec.readAsLinesSync();
    final kept = lines.where((l) => !_pubspecLine.hasMatch(l)).toList();
    lineRemoved = kept.length != lines.length;
    if (lineRemoved && !dryRun) {
      pubspec.writeAsStringSync('${kept.join('\n')}\n');
    }
  }

  var emptied = false;
  final manifest = File(p.join(root.path, bankLogoManifestPath));
  if (manifest.existsSync() &&
      _manifestHasEntries(manifest.readAsStringSync())) {
    emptied = true;
    if (!dryRun) {
      manifest.writeAsStringSync(
        renderBankLogoManifest(const {}, stripped: true),
      );
    }
  }

  return StripResult(
    filesDeleted: files,
    bytesFreed: bytes,
    pubspecLineRemoved: lineRemoved,
    manifestEmptied: emptied,
  );
}

/// Purpose: List logo artifacts still present in the tree.
/// Inputs: `root`.
/// Returns: `List<String>` human-readable leftovers; empty when fully stripped.
/// Side effects: Reads files.
/// Notes: Used by `--verify` in CI after stripping.
List<String> bankLogoLeftovers(Directory root) {
  final left = <String>[];
  if (Directory(p.join(root.path, bankLogoAssetDir)).existsSync()) {
    left.add(bankLogoAssetDir);
  }
  final pubspec = File(p.join(root.path, 'pubspec.yaml'));
  if (pubspec.existsSync() &&
      pubspec.readAsLinesSync().any(_pubspecLine.hasMatch)) {
    left.add('pubspec.yaml asset entry');
  }
  final manifest = File(p.join(root.path, bankLogoManifestPath));
  if (manifest.existsSync() &&
      _manifestHasEntries(manifest.readAsStringSync())) {
    left.add('$bankLogoManifestPath entries');
  }
  return left;
}

/// Purpose: CLI entry point.
/// Inputs: `args` — `--dry-run`, `--verify`, `--root <dir>`.
/// Returns: None.
/// Side effects: See `stripBankLogos`; sets the exit code.
/// Notes: `--verify` exits 1 when anything is left.
void main(List<String> args) {
  var root = Directory.current;
  final i = args.indexOf('--root');
  if (i >= 0 && i + 1 < args.length) root = Directory(args[i + 1]);

  if (args.contains('--verify')) {
    final left = bankLogoLeftovers(root);
    if (left.isEmpty) {
      stdout.writeln('verify: no bundled bank logos left');
    } else {
      stderr.writeln(
        'verify: bundled bank logos still present: ${left.join(', ')}',
      );
      exitCode = 1;
    }
    return;
  }

  final dryRun = args.contains('--dry-run');
  final r = stripBankLogos(root, dryRun: dryRun);
  stdout.writeln('${dryRun ? 'would strip' : 'stripped'}: $r');
}

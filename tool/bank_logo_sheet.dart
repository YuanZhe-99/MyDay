// Render HTML contact sheets of bank logo candidates for visual review.
//
// Run: dart run tool/bank_logo_sheet.dart --dir <scratch dir from fetch_bank_logos.dart>
//      dart run tool/bank_logo_sheet.dart --final     (sheets of the installed assets/bank_logos/)
//
// Add --only <country_id,...> to render a subset.
//
// Writes <dir>/sheet_<country>_<n>.html (12 presets per page, one screenshot each) and
// <dir>/sheet_index.html. Each candidate is shown on white and inside an avatar-sized circle,
// labelled with its file name (the value to record in tool/bank_logo_choices.json), source and size.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Purpose: Escape text for HTML.
/// Inputs: `s`.
/// Returns: `String`.
/// Side effects: None.
/// Notes: None.
String _esc(String s) => const HtmlEscape().convert(s);

/// Purpose: Abbreviate a candidate source label for the compact sheet.
/// Inputs: `source`.
/// Returns: `String`, for example `site-icon`, `NAME?` or `infobox-ja`.
/// Side effects: None.
/// Notes: NAME-ONLY matches keep a visible warning so the reviewer checks the institution.
String _shortSource(String source) {
  final s = source.split(' ').first.replaceFirst('wikidata-', '');
  return source.contains('NAME-ONLY') ? '$s NAME?' : s;
}

/// Purpose: Render one HTML page for a list of preset cells.
/// Inputs: `title`; `cells` — rows of (key, title, domain, candidates).
/// Returns: `String` HTML.
/// Side effects: None.
/// Notes: Image paths are relative to the sheet file.
String _page(
  String title,
  List<({String key, String title, String domain, List<Map<String, dynamic>> cands})> cells,
) {
  final b = StringBuffer()
    ..writeln('<!doctype html><meta charset="utf-8"><title>${_esc(title)}</title><style>')
    ..writeln('body{font:12px system-ui,sans-serif;margin:8px;background:#eee}')
    ..writeln('.cell{display:inline-block;vertical-align:top;margin:2px;padding:3px;'
        'background:#fff;border:1px solid #ccc;max-width:385px}')
    ..writeln('.k{font-weight:700}.none{color:#c00;font-weight:700}')
    ..writeln('.c{display:inline-flex;align-items:center;gap:3px;margin:1px 3px;font-size:10px}')
    ..writeln('.c img{object-fit:contain;display:block}')
    ..writeln('.lt{background:#fff;border:1px solid #ddd}.dk{background:#222}')
    ..writeln('.av{width:40px;height:40px;border-radius:50%;background:#fff;border:1px solid #bbb;'
        'overflow:hidden;display:flex;align-items:center;justify-content:center}')
    ..writeln('.av img{width:30px;height:30px}')
    ..writeln('.warn{color:#c60}</style>')
    ..writeln('<h3>${_esc(title)} — ${cells.length} presets</h3>');
  for (final c in cells) {
    b.writeln('<div class="cell"><div class="k">${_esc(c.key)}</div>'
        '<div>${_esc(c.title)} · ${_esc(c.domain)}</div>');
    if (c.cands.isEmpty) b.writeln('<div class="none">NO CANDIDATE</div>');
    for (var i = 0; i < c.cands.length; i++) {
      final cand = c.cands[i];
      final src = _esc(cand['path'] as String);
      final source = (cand['source'] as String?) ?? '';
      if (i > 0 && i % 2 == 0) b.writeln('<br>');
      b.writeln('<div class="c"><b>${_esc((cand['file'] as String?) ?? '#$i')}</b> '
          '${((cand['bytes'] as int) / 1024).toStringAsFixed(0)}K'
          '<div class="lt"><img src="$src" width="96" height="44"></div>'
          '<div class="av"><img src="$src"></div>'
          '<span class="${source.contains('NAME-ONLY') ? 'warn' : ''}">'
          '${_esc(_shortSource(source))}</span></div>');
    }
    b.writeln('</div>');
  }
  return b.toString();
}

/// Purpose: Write per-country contact sheets.
/// Inputs: `args` — `--dir <scratch>` or `--final`.
/// Returns: None.
/// Side effects: Writes HTML files; prints their paths.
/// Notes: `--final` renders the installed logos (from the manifest directory) into
/// `<scratch or tmp>/final_sheets/` so the shipped set can be re-checked.
void main(List<String> args) {
  final isFinal = args.contains('--final');
  final onlyIdx = args.indexOf('--only');
  final only = onlyIdx >= 0 ? args[onlyIdx + 1].split(',').toSet() : null;
  final dirIdx = args.indexOf('--dir');
  final presets = (jsonDecode(File('assets/banks.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final seen = <String>{};
  final byCountry = <String, List<({String key, String title, String domain,
      List<Map<String, dynamic>> cands})>>{};

  late final Directory outDir;
  if (isFinal) {
    outDir = Directory(dirIdx >= 0 ? args[dirIdx + 1] : p.join(Directory.systemTemp.path, 'final_sheets'))
      ..createSync(recursive: true);
  } else {
    outDir = Directory(args[dirIdx + 1]);
  }

  for (final b in presets) {
    final key = '${b['country']}/${b['id']}';
    if (!seen.add(key)) continue;
    final stem = '${b['country']}_${b['id']}';
    if (only != null && !only.contains(stem)) continue;
    final cands = <Map<String, dynamic>>[];
    if (isFinal) {
      for (final ext in ['svg', 'png']) {
        final f = File(p.join('assets', 'bank_logos', '$stem.$ext'));
        if (f.existsSync()) {
          cands.add({
            'path': Uri.file(f.absolute.path).toString(),
            'ext': ext,
            'bytes': f.lengthSync(),
            'source': 'installed',
          });
        }
      }
    } else {
      final index = File(p.join(outDir.path, stem, 'candidates.json'));
      if (index.existsSync()) {
        final j = jsonDecode(index.readAsStringSync()) as Map<String, dynamic>;
        for (final c in (j['candidates'] as List).cast<Map<String, dynamic>>()) {
          cands.add({...c, 'path': '$stem/${c['file']}'});
        }
      }
    }
    (byCountry[b['country'] as String] ??= []).add((
      key: key,
      title: b['engTitle'] as String,
      domain: (b['domain'] as String?) ?? '',
      cands: cands,
    ));
  }

  final links = StringBuffer('<!doctype html><meta charset="utf-8"><h3>Sheets</h3>');
  for (final country in byCountry.keys.toList()..sort()) {
    final cells = byCountry[country]!;
    final missing = cells.where((c) => c.cands.isEmpty).length;
    links.write('$country (${cells.length}, $missing missing):');
    // Pages of 12 presets fit one screenshot, so review never depends on scrolling.
    for (var start = 0, n = 1; start < cells.length; start += 12, n++) {
      final end = start + 12 > cells.length ? cells.length : start + 12;
      final name = 'sheet_${country}_$n.html';
      File(p.join(outDir.path, name))
          .writeAsStringSync(_page('$country $n', cells.sublist(start, end)));
      links.write(' <a href="$name">$n</a>');
    }
    links.writeln('<br>');
  }
  File(p.join(outDir.path, 'sheet_index.html')).writeAsStringSync(links.toString());
  stdout.writeln(p.join(outDir.path, 'sheet_index.html'));
}

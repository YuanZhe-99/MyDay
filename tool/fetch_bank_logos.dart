// Fetch candidate bank logos for every preset in assets/banks.json into a scratch directory.
//
// Run: dart run tool/fetch_bank_logos.dart --out <scratch dir> [--only <country_id,...>]
//          [--infobox] [--site | --icons]
//
// Phase 1 (resolve) picks Wikimedia Commons file names per preset: the Wikidata "small logo or
// icon" (P8972/P2910) and "logo image" (P154) of the institution whose official website (P856)
// matches the preset domain, found by bulk SPARQL, else by a per-name entity search. Direct URLs
// listed for the preset in tool/bank_logo_overrides.json are added first. With --infobox, presets
// that still have nothing get the logo named in their English and local-language Wikipedia
// infoboxes. The result is cached in <out>/plan.json.
// Phase 2 (download) resolves direct file URLs through the Commons API in batches of 50 and
// downloads each file once, slowly, into <out>/<country>_<id>/ with a candidates.json index.
// Both phases resume: cached plans, SPARQL results and downloaded files are reused.
//
// Nothing is copied into assets/ — a human reviews the contact sheets (tool/bank_logo_sheet.dart),
// records choices in tool/bank_logo_choices.json, then runs tool/apply_bank_logo_choices.dart.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

const _userAgent =
    'MyDayLogoFetcher/1.1 (https://github.com/YuanZhe-99/MyDay; one-off dev tool)';
const _maxSvgBytes = 400 * 1024;
const _maxRasterBytes = 2 * 1024 * 1024;
const _maxCandidates = 6;

/// Minimum spacing before every request.
const _gap = Duration(milliseconds: 900);

/// One preset's identity for fetching.
class _Preset {
  final String country;
  final String id;
  final String engTitle;
  final String domain;

  /// Purpose: Create a preset record.
  /// Inputs: `country`, `id`, `engTitle`, `domain`.
  /// Returns: A new `_Preset` instance.
  /// Side effects: None.
  /// Notes: None.
  _Preset(this.country, this.id, this.engTitle, this.domain);

  /// Purpose: Return the unique manifest key.
  /// Inputs: None.
  /// Returns: `String` `<country>/<id>`.
  /// Side effects: None.
  /// Notes: `id` alone repeats across countries.
  String get key => '$country/$id';

  /// Purpose: Return the flat directory/file stem for this preset.
  /// Inputs: None.
  /// Returns: `String` `<country>_<id>`.
  /// Side effects: None.
  /// Notes: None.
  String get stem => '${country}_$id';
}

/// Purpose: Reduce a URL or domain to a bare lowercase host without `www.`.
/// Inputs: `urlOrHost`.
/// Returns: `String` host, possibly empty.
/// Side effects: None.
/// Notes: None.
String hostOf(String urlOrHost) {
  var s = urlOrHost.trim().toLowerCase();
  s = s.replaceFirst(RegExp(r'^[a-z]+://'), '');
  s = s.replaceFirst(RegExp(r'[/?#:].*$'), '');
  return s.replaceFirst(RegExp(r'^www\d?\.'), '');
}

/// Purpose: Decide whether two hosts denote the same site.
/// Inputs: `a`, `b` (hosts from `hostOf`).
/// Returns: `bool`.
/// Side effects: None.
/// Notes: Equal hosts, or one is a subdomain of the other ("online.citi.com" ~ "citi.com").
bool sameSite(String a, String b) {
  if (a.isEmpty || b.isEmpty || !a.contains('.') || !b.contains('.')) {
    return false;
  }
  return a == b || a.endsWith('.$b') || b.endsWith('.$a');
}

/// Purpose: Turn a Commons `Special:FilePath` URL or bare name into a file name.
/// Inputs: `value`.
/// Returns: `String` file name with spaces (Commons title form without `File:`).
/// Side effects: None.
/// Notes: None.
String commonsName(String value) {
  // SPARQL gives percent-encoded Special:FilePath URLs; the entity API gives raw names, which
  // may legitimately contain '%'.
  if (!value.contains('/')) return value.replaceAll('_', ' ');
  return Uri.decodeComponent(value.split('/').last).replaceAll('_', ' ');
}

/// Purpose: GET a URL with the tool's user agent, pacing and retrying politely.
/// Inputs: `url`, `accept` header, `timeout`, `attempts` (bank sites use fewer).
/// Returns: `Future<http.Response?>`, null when every attempt failed.
/// Side effects: Network request; sleeps between requests.
/// Notes: Wikimedia rate-limits bursts (HTTP 429): every request waits `_gap` first and a 429
/// waits `Retry-After` (capped at 120 s), up to four attempts.
Future<http.Response?> _get(
  String url, {
  String accept = '*/*',
  Duration timeout = const Duration(seconds: 40),
  int attempts = 4,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await Future<void>.delayed(_gap);
    try {
      final r = await http
          .get(
            Uri.parse(url),
            headers: {'User-Agent': _userAgent, 'Accept': accept},
          )
          .timeout(timeout);
      if (r.statusCode == 429) {
        var wait = int.tryParse(r.headers['retry-after'] ?? '') ?? 30;
        if (wait > 120) wait = 120;
        stderr.writeln('  429, waiting ${wait}s: $url');
        await Future<void>.delayed(Duration(seconds: wait));
        continue;
      }
      return r;
    } catch (e) {
      stderr.writeln('  error $e: $url');
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }
  return null;
}

/// Purpose: Run a SPARQL query once and cache the JSON result.
/// Inputs: `query`, `cache` file.
/// Returns: `Future<List<Map<String, dynamic>>>` result bindings.
/// Side effects: One request when the cache is missing; writes the cache.
/// Notes: The logo query takes about a minute on the public endpoint.
Future<List<Map<String, dynamic>>> _sparql(String query, File cache) async {
  if (!cache.existsSync()) {
    final url =
        'https://query.wikidata.org/sparql?query=${Uri.encodeQueryComponent(query)}';
    final r = await _get(
      url,
      accept: 'application/sparql-results+json',
      timeout: const Duration(minutes: 3),
    );
    if (r == null || r.statusCode != 200) {
      throw StateError('SPARQL failed: ${r?.statusCode}');
    }
    cache.writeAsStringSync(utf8.decode(r.bodyBytes));
  }
  return (jsonDecode(cache.readAsStringSync())['results']['bindings'] as List)
      .cast<Map<String, dynamic>>();
}

const _classes =
    'VALUES ?cls { wd:Q650241 wd:Q1851940 wd:Q17127659 wd:Q2111088 }';

/// Purpose: Find Wikidata items for a preset by name and return their icon/logo files.
/// Inputs: `preset`.
/// Returns: `Future<List<({String file, String source})>>`.
/// Side effects: Two Wikidata API requests.
/// Notes: Items whose website matches the domain come first; the rest are labelled NAME-ONLY
/// so the reviewer checks they are the right institution.
Future<List<({String file, String source})>> _searchByName(
  _Preset preset,
) async {
  final search = await _get(
    'https://www.wikidata.org/w/api.php?action=wbsearchentities'
    '&format=json&language=en&type=item&limit=6'
    '&search=${Uri.encodeQueryComponent(preset.engTitle)}',
  );
  if (search == null || search.statusCode != 200) return [];
  final ids = [
    for (final e in (jsonDecode(search.body)['search'] as List))
      e['id'] as String,
  ];
  if (ids.isEmpty) return [];
  final ents = await _get(
    'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json'
    '&props=claims&ids=${ids.join('|')}',
  );
  if (ents == null || ents.statusCode != 200) return [];
  final entities = (jsonDecode(ents.body)['entities'] as Map)
      .cast<String, dynamic>();
  final domain = hostOf(preset.domain);
  final matched = <({String file, String source})>[];
  final nameOnly = <({String file, String source})>[];

  /// Purpose: Read string values of one property from an entity's claims.
  /// Inputs: `claims`, `prop`.
  /// Returns: `List<String>`.
  /// Side effects: None.
  /// Notes: None.
  List<String> values(Map<String, dynamic> claims, String prop) => [
    for (final c in (claims[prop] as List? ?? const []))
      if (c['mainsnak']?['datavalue']?['value'] is String)
        c['mainsnak']['datavalue']['value'] as String,
  ];

  for (final id in ids) {
    final claims =
        (entities[id]?['claims'] as Map?)?.cast<String, dynamic>() ?? {};
    final files = [
      ...values(claims, 'P8972'),
      ...values(claims, 'P2910'),
      ...values(claims, 'P154'),
    ];
    if (files.isEmpty) continue;
    final siteMatch = values(
      claims,
      'P856',
    ).map(hostOf).any((s) => sameSite(s, domain));
    for (final f in files) {
      (siteMatch ? matched : nameOnly).add((
        file: f,
        source: siteMatch ? 'wikidata-site $id' : 'wikidata-NAME-ONLY $id',
      ));
    }
  }
  return [...matched, ...nameOnly];
}

/// Purpose: Resolve direct download URLs for Commons files, 50 per API request.
/// Inputs: `names` — Commons file names.
/// Returns: `Future<Map<String, ({String url, String mime, int size})>>` keyed by name.
/// Side effects: Commons API requests.
/// Notes: Uses `imageinfo`, which serves from the API cluster rather than the throttled
/// `Special:FilePath` redirect. Missing files are simply absent from the result.
Future<Map<String, ({String url, String mime, int size})>> _resolveCommons(
  List<String> names,
) async {
  final out = <String, ({String url, String mime, int size})>{};
  for (var i = 0; i < names.length; i += 50) {
    final batch = names.sublist(
      i,
      i + 50 > names.length ? names.length : i + 50,
    );
    final titles = batch.map((n) => 'File:$n').join('|');
    final r = await _get(
      'https://commons.wikimedia.org/w/api.php?action=query&format=json&formatversion=2'
      '&prop=imageinfo&iiprop=url|mime|size&titles=${Uri.encodeQueryComponent(titles)}',
    );
    if (r == null || r.statusCode != 200) continue;
    final body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final query = body['query'] as Map<String, dynamic>? ?? {};
    final normalized = {
      for (final n in (query['normalized'] as List? ?? const []))
        n['to'] as String: n['from'] as String,
    };
    for (final page in (query['pages'] as List? ?? const [])) {
      final info = (page['imageinfo'] as List?)?.firstOrNull;
      if (info == null) continue;
      final title = page['title'] as String;
      final from = normalized[title] ?? title;
      out[from.replaceFirst('File:', '').replaceAll('_', ' ')] = (
        url: info['url'] as String,
        mime: (info['mime'] as String?) ?? '',
        size: (info['size'] as int?) ?? 0,
      );
    }
  }
  return out;
}

/// Wikipedia language used for a preset's home country (English is always tried first).
const _localWiki = {
  'ar': 'es',
  'be': 'nl',
  'by': 'ru',
  'cn': 'zh',
  'cy': 'el',
  'cz': 'cs',
  'de': 'de', //
  'dk': 'da',
  'fi': 'fi',
  'fr': 'fr',
  'ir': 'fa',
  'jp': 'ja',
  'kg': 'ru',
  'kz': 'ru', //
  'nl': 'nl',
  'pl': 'pl',
  'pt': 'pt',
  'rs': 'sr',
  'ru': 'ru',
  'tr': 'tr',
  'tw': 'zh', //
  'ua': 'uk', 'uy': 'es',
};

/// Infobox logo parameter, in the parameter names used by the wikis above.
final RegExp _logoParam = RegExp(
  r'\|\s*(?:logo|logo_image|image_logo|logo_file|ロゴ|логотип|لوگو|標誌|标志|標識)\s*=\s*'
  r'(?:\[\[)?\s*(?:[^:|\]\n]{2,12}:)?\s*([^|\]\}\n<]+?\.(?:svg|png|jpe?g|gif|webp))',
  caseSensitive: false,
);

/// Purpose: Find logo files named in the preset's Wikipedia infoboxes.
/// Inputs: `preset`.
/// Returns: `Future<List<Map<String, String>>>` entries with a direct `url` and a `source`.
/// Side effects: Wikidata and Wikipedia API requests.
/// Notes: Used only when Wikidata has no logo property. The institution is found by English
/// name, then by local name; items whose website does not match the domain are labelled
/// NAME-ONLY. File URLs are resolved through the same wiki, because many logos are local
/// (non-Commons) uploads.
Future<List<Map<String, String>>> _infoboxLogos(
  _Preset preset,
  String localTitle,
) async {
  final local = _localWiki[preset.country];
  final domain = hostOf(preset.domain);
  final ids = <String>[];
  for (final (text, lang) in [
    (preset.engTitle, 'en'),
    (localTitle, local ?? 'en'),
  ]) {
    final search = await _get(
      'https://www.wikidata.org/w/api.php?action=wbsearchentities'
      '&format=json&language=$lang&uselang=$lang&type=item&limit=5'
      '&search=${Uri.encodeQueryComponent(text)}',
    );
    if (search == null || search.statusCode != 200) continue;
    for (final e in (jsonDecode(search.body)['search'] as List)) {
      if (!ids.contains(e['id'])) ids.add(e['id'] as String);
    }
  }
  if (ids.isEmpty) return [];
  final ents = await _get(
    'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json'
    '&props=claims|sitelinks&ids=${ids.take(10).join('|')}',
  );
  if (ents == null || ents.statusCode != 200) return [];
  final entities = (jsonDecode(ents.body)['entities'] as Map)
      .cast<String, dynamic>();

  String? chosen;
  var siteMatch = false;
  for (final id in ids.take(10)) {
    final claims =
        (entities[id]?['claims'] as Map?)?.cast<String, dynamic>() ?? {};
    final sites = [
      for (final c in (claims['P856'] as List? ?? const []))
        if (c['mainsnak']?['datavalue']?['value'] is String)
          hostOf(c['mainsnak']['datavalue']['value'] as String),
    ];
    if (sites.any((s) => sameSite(s, domain))) {
      chosen = id;
      siteMatch = true;
      break;
    }
  }
  chosen ??= ids.first;
  final sitelinks =
      (entities[chosen]?['sitelinks'] as Map?)?.cast<String, dynamic>() ?? {};

  final out = <Map<String, String>>[];
  for (final lang in {'en', ?local}) {
    final title = sitelinks['${lang}wiki']?['title'] as String?;
    if (title == null) continue;
    final api = 'https://$lang.wikipedia.org/w/api.php';
    final page = await _get(
      '$api?action=query&format=json&formatversion=2&prop=revisions&rvprop=content'
      '&rvslots=main&rvsection=0&redirects=1&titles=${Uri.encodeQueryComponent(title)}',
    );
    if (page == null || page.statusCode != 200) continue;
    final pages =
        (jsonDecode(utf8.decode(page.bodyBytes))['query']?['pages'] as List?) ??
        [];
    final content = pages.isEmpty
        ? null
        : (pages.first['revisions'] as List?)
              ?.firstOrNull?['slots']?['main']?['content'];
    if (content is! String) continue;
    for (final m in _logoParam.allMatches(content).take(2)) {
      final file = m[1]!.trim();
      final info = await _get(
        '$api?action=query&format=json&formatversion=2&prop=imageinfo&iiprop=url'
        '&titles=${Uri.encodeQueryComponent('File:$file')}',
      );
      if (info == null || info.statusCode != 200) continue;
      final ipages =
          (jsonDecode(utf8.decode(info.bodyBytes))['query']?['pages']
              as List?) ??
          [];
      final url = ipages.isEmpty
          ? null
          : (ipages.first['imageinfo'] as List?)?.firstOrNull?['url']
                as String?;
      if (url != null) {
        out.add({
          'url': url,
          'source': 'infobox-$lang ${siteMatch ? '' : 'NAME-ONLY '}$chosen',
        });
      }
    }
  }
  return out;
}

/// Logo-looking references in a bank's own homepage, most specific first.
final List<RegExp> _sitePatterns = [
  // <img ... class/id/alt containing "logo" ... src="...svg|png">, either attribute order.
  RegExp(
    r'''<img[^>]*(?:logo)[^>]*\ssrc\s*=\s*["']([^"']+\.(?:svg|png)(?:\?[^"']*)?)["']''',
    caseSensitive: false,
  ),
  RegExp(
    r'''<img[^>]*\ssrc\s*=\s*["']([^"']*logo[^"']*\.(?:svg|png)(?:\?[^"']*)?)["']''',
    caseSensitive: false,
  ),
  RegExp(
    r'''<link[^>]*rel\s*=\s*["'](?:mask-)?icon["'][^>]*href\s*=\s*["']([^"']+\.svg[^"']*)["']''',
    caseSensitive: false,
  ),
  RegExp(
    r'''<link[^>]*rel\s*=\s*["']apple-touch-icon[^"']*["'][^>]*href\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  ),
  RegExp(
    r'''<link[^>]*href\s*=\s*["']([^"']+)["'][^>]*rel\s*=\s*["']apple-touch-icon''',
    caseSensitive: false,
  ),
  RegExp(
    r'''<meta[^>]*property\s*=\s*["']og:image["'][^>]*content\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  ),
];

/// Purpose: Find logo image URLs on the institution's own homepage.
/// Inputs: `preset`.
/// Returns: `Future<List<Map<String, String>>>` entries with an absolute `url` and a `source`.
/// Side effects: One homepage request.
/// Notes: Last-resort source for presets Wikimedia cannot cover. Results are often wordmarks,
/// touch icons or social images, so every one is reviewed on the sheet like any other candidate.
Future<List<Map<String, String>>> _siteLogos(_Preset preset) async {
  if (preset.domain.isEmpty) return [];
  final home = Uri.parse('https://${preset.domain}/');
  final r = await _get(home.toString(), accept: 'text/html');
  if (r == null || r.statusCode != 200) return [];
  final html = utf8.decode(r.bodyBytes, allowMalformed: true);
  final base = r.request?.url ?? home;
  final out = <Map<String, String>>[];
  final seen = <String>{};
  for (final (i, pattern) in _sitePatterns.indexed) {
    for (final m in pattern.allMatches(html).take(2)) {
      final raw = m[1]!.replaceAll('&amp;', '&').trim();
      if (raw.startsWith('data:')) continue;
      final url = base.resolve(raw).toString();
      if (seen.add(url)) out.add({'url': url, 'source': 'bank-site p$i'});
    }
  }
  return out.take(4).toList();
}

final RegExp _linkTag = RegExp(r'<link\b[^>]*>', caseSensitive: false);

/// Purpose: Read one attribute from an HTML tag.
/// Inputs: `tag`, `name`.
/// Returns: `String?` attribute value, entity-decoded for `&amp;`.
/// Side effects: None.
/// Notes: Handles single and double quotes.
String? _attr(String tag, String name) {
  final m = RegExp(
    '\\b$name\\s*=\\s*["\']([^"\']*)["\']',
    caseSensitive: false,
  ).firstMatch(tag);
  return m?[1]?.replaceAll('&amp;', '&').trim();
}

/// Purpose: Largest edge declared in a `sizes` attribute or manifest entry.
/// Inputs: `sizes` (e.g. "180x180", "192x192 512x512", "any").
/// Returns: `int` — 0 when unknown, 4096 for "any" (vector).
/// Side effects: None.
/// Notes: None.
int _declaredEdge(String? sizes) {
  if (sizes == null) return 0;
  if (sizes.toLowerCase().contains('any')) return 4096;
  var best = 0;
  for (final m in RegExp(r'(\d+)x(\d+)').allMatches(sizes)) {
    final v = int.parse(m[1]!);
    if (v > best) best = v;
  }
  return best;
}

/// Purpose: Find the institution's official square icons on its own website.
/// Inputs: `preset`.
/// Returns: `Future<List<Map<String, String>>>` entries with an absolute `url` and a `source`,
/// best first (SVG icon, largest manifest/touch icon, then the conventional touch-icon path).
/// Side effects: Homepage and web-manifest requests.
/// Notes: Icons are the symbol a bank itself chose for small square spaces (home-screen icons,
/// pinned tabs), which is exactly the avatar use case; wordmark logos are not collected here.
Future<List<Map<String, String>>> _siteIcons(_Preset preset) async {
  if (preset.domain.isEmpty) return [];
  final home = Uri.parse('https://${preset.domain}/');
  final r = await _get(
    home.toString(),
    accept: 'text/html',
    timeout: const Duration(seconds: 15),
    attempts: 2,
  );
  if (r == null || r.statusCode != 200) return [];
  final html = utf8.decode(r.bodyBytes, allowMalformed: true);
  final base = r.request?.url ?? home;
  final found = <({String url, int score, String source})>[];

  for (final m in _linkTag.allMatches(html)) {
    final tag = m[0]!;
    final rel = (_attr(tag, 'rel') ?? '').toLowerCase();
    final href = _attr(tag, 'href');
    if (href == null || href.isEmpty || href.startsWith('data:')) continue;
    final url = base.resolve(href).toString();
    final svg =
        href.toLowerCase().split('?').first.endsWith('.svg') ||
        (_attr(tag, 'type') ?? '').contains('svg');
    if (rel.split(RegExp(r'\s+')).contains('manifest')) {
      final man = await _get(
        url,
        timeout: const Duration(seconds: 15),
        attempts: 2,
      );
      if (man == null || man.statusCode != 200) continue;
      try {
        final icons =
            (jsonDecode(utf8.decode(man.bodyBytes)) as Map)['icons'] as List? ??
            [];
        final mBase = man.request?.url ?? Uri.parse(url);
        for (final i in icons.cast<Map>()) {
          final src = i['src'] as String?;
          if (src == null) continue;
          final edge = _declaredEdge(i['sizes'] as String?);
          if (edge < 128) continue;
          found.add((
            url: mBase.resolve(src).toString(),
            score: edge,
            source: 'site-manifest $edge',
          ));
        }
      } catch (_) {}
    } else if (rel.contains('apple-touch-icon')) {
      final edge = _declaredEdge(_attr(tag, 'sizes'));
      found.add((
        url: url,
        score: edge == 0 ? 180 : edge,
        source: 'site-touch-icon',
      ));
    } else if ((rel.contains('icon') || rel.contains('mask-icon')) && svg) {
      found.add((url: url, score: 5000, source: 'site-svg-icon'));
    } else if (rel.contains('icon')) {
      final edge = _declaredEdge(_attr(tag, 'sizes'));
      if (edge >= 128) {
        found.add((url: url, score: edge, source: 'site-icon $edge'));
      }
    }
  }
  // The conventional path is served by many sites that never declare it.
  found.add((
    url: base.resolve('/apple-touch-icon.png').toString(),
    score: 1,
    source: 'site-touch-icon default',
  ));

  found.sort((a, b) => b.score.compareTo(a.score));
  final seen = <String>{};
  return [
    for (final f in found)
      if (seen.add(f.url)) {'url': f.url, 'source': f.source},
  ].take(4).toList();
}

/// Purpose: Download one candidate file and validate its type and size.
/// Inputs: `url`, `dir`, `name` (file stem).
/// Returns: `Future<Map<String, Object?>?>` candidate metadata, or null when rejected.
/// Side effects: Writes the file into `dir`.
/// Notes: Accepts SVG (must contain `<svg`, ≤ 400 KB), PNG, JPEG, WebP and GIF (≤ 2 MB).
Future<Map<String, Object?>?> _download(
  String url,
  Directory dir,
  String name,
) async {
  final r = await _get(url);
  if (r == null || r.statusCode != 200) {
    stderr.writeln('  download ${r?.statusCode ?? 'failed'}: $url');
    return null;
  }
  final bytes = r.bodyBytes;
  final type = (r.headers['content-type'] ?? '').toLowerCase();
  final head = utf8.decode(bytes.take(1024).toList(), allowMalformed: true);
  String? ext;
  if (type.contains('svg') || head.contains('<svg')) {
    ext = 'svg';
  } else if (type.contains('png')) {
    ext = 'png';
  } else if (type.contains('jpeg') || type.contains('jpg')) {
    ext = 'jpg';
  } else if (type.contains('webp')) {
    ext = 'webp';
  } else if (type.contains('gif')) {
    ext = 'gif';
  }
  if (ext == null || bytes.length < 200) return null;
  if (ext == 'svg') {
    if (bytes.length > _maxSvgBytes) return null;
    if (!utf8.decode(bytes, allowMalformed: true).contains('<svg')) return null;
  } else if (bytes.length > _maxRasterBytes) {
    return null;
  }
  final file = File(p.join(dir.path, '$name.$ext'));
  await file.writeAsBytes(bytes);
  return {
    'file': p.basename(file.path),
    'url': url,
    'bytes': bytes.length,
    'ext': ext,
  };
}

/// Purpose: Fetch candidates for every preset and write per-preset `candidates.json` files.
/// Inputs: `args` — `--out <dir>` (required), `--only <stem,...>` (optional subset).
/// Returns: `Future<void>`.
/// Side effects: Network requests; writes under the output directory; prints a summary.
/// Notes: Delete `<out>/<stem>/candidates.json` (and `plan.json` for new sources) to refetch.
Future<void> main(List<String> args) async {
  String? out;
  Set<String>? only;
  final infobox = args.contains('--infobox');
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out') out = args[++i];
    if (args[i] == '--only') only = args[++i].split(',').toSet();
  }
  if (out == null) {
    stderr.writeln(
      'usage: dart run tool/fetch_bank_logos.dart --out <dir> [--only a_b,c_d]',
    );
    exit(64);
  }
  final outDir = Directory(out)..createSync(recursive: true);

  final raw = (jsonDecode(File('assets/banks.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final seen = <String>{};
  final presets = <_Preset>[];
  final localTitles = <String, String>{};
  for (final b in raw) {
    localTitles['${b['country']}/${b['id']}'] =
        (b['localTitle'] as String?) ?? (b['engTitle'] as String);
    final pr = _Preset(
      b['country'] as String,
      b['id'] as String,
      b['engTitle'] as String,
      (b['domain'] as String?) ?? '',
    );
    if (seen.add(pr.key) && (only == null || only.contains(pr.stem))) {
      presets.add(pr);
    }
  }

  final overridesFile = File('tool/bank_logo_overrides.json');
  final overrides = overridesFile.existsSync()
      ? (jsonDecode(overridesFile.readAsStringSync()) as Map)
            .cast<String, dynamic>()
      : <String, dynamic>{};

  // ── --site / --icons: append candidates from each bank's own homepage, then stop ──
  // --site collects logo images (files s0…); --icons collects official square icons (i0…).
  final icons = args.contains('--icons');
  if (args.contains('--site') || icons) {
    final prefix = icons ? 'i' : 's';
    final queue = List.of(presets);
    // Bank sites are independent hosts, so several run at once; a preset already marked done
    // for this mode is skipped, which makes the pass resumable.
    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final pr = queue.removeLast();
        final dir = Directory(p.join(outDir.path, pr.stem))
          ..createSync(recursive: true);
        final index = File(p.join(dir.path, 'candidates.json'));
        final json = index.existsSync()
            ? jsonDecode(index.readAsStringSync()) as Map<String, dynamic>
            : <String, dynamic>{
                'key': pr.key,
                'engTitle': pr.engTitle,
                'domain': pr.domain,
                'candidates': <dynamic>[],
              };
        if (json['${prefix}Done'] == true) continue;
        final candidates =
            (json['candidates'] as List).cast<Map<String, dynamic>>()
              ..removeWhere((c) => (c['file'] as String).startsWith(prefix));
        var n = 0;
        for (final e in await (icons ? _siteIcons(pr) : _siteLogos(pr))) {
          final c = await _download(e['url']!, dir, '$prefix${n++}');
          if (c != null) candidates.add({...c, 'source': e['source']});
        }
        json['candidates'] = candidates;
        json['${prefix}Done'] = true;
        index.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(json),
        );
        stdout.writeln(
          '${pr.stem.padRight(34)} ${n > 0 ? '' : 'no '}${icons ? 'icon' : 'site'} candidates',
        );
      }
    }

    await Future.wait([for (var i = 0; i < 6; i++) worker()]);
    return;
  }

  // ── Phase 1: resolve file names per preset ──
  final planFile = File(p.join(outDir.path, 'plan.json'));
  final plan = planFile.existsSync()
      ? (jsonDecode(planFile.readAsStringSync()) as Map).cast<String, dynamic>()
      : <String, dynamic>{};
  // --infobox revisits presets whose plan came back empty.
  final todo = presets
      .where(
        (pr) =>
            !plan.containsKey(pr.key) ||
            (infobox && (plan[pr.key] as List).isEmpty),
      )
      .toList();
  if (todo.isNotEmpty) {
    stdout.writeln('Resolving ${todo.length} presets…');
    final logos = await _sparql(
      '''
SELECT ?item ?site ?logo WHERE { $_classes
  ?item wdt:P154 ?logo; wdt:P856 ?site. ?item wdt:P31/wdt:P279* ?cls. }''',
      File(p.join(outDir.path, 'sparql.json')),
    );
    final icons = await _sparql(
      '''
SELECT ?item ?site ?logo WHERE { $_classes
  { ?item wdt:P8972 ?logo } UNION { ?item wdt:P2910 ?logo }
  ?item wdt:P856 ?site. ?item wdt:P31/wdt:P279* ?cls. }''',
      File(p.join(outDir.path, 'sparql_icons.json')),
    );
    for (final pr in todo) {
      final domain = hostOf(pr.domain);
      final entries = <Map<String, String>>[
        for (final u in (overrides[pr.key] as List? ?? const []))
          {'url': u as String, 'source': 'override'},
      ];
      for (final (rows, kind) in [(icons, 'icon'), (logos, 'logo')]) {
        for (final row in rows) {
          final value = row['logo']?['value'] ?? row['icon']?['value'];
          if (value is! String) continue;
          if (sameSite(hostOf(row['site']['value'] as String), domain)) {
            final item = (row['item']['value'] as String).split('/').last;
            entries.add({
              'file': commonsName(value),
              'source': 'wikidata-site-$kind $item',
            });
          }
        }
      }
      if (entries.every((e) => e['source'] == 'override')) {
        for (final m in await _searchByName(pr)) {
          entries.add({'file': commonsName(m.file), 'source': m.source});
        }
      }
      if (infobox && entries.every((e) => e['source'] == 'override')) {
        entries.addAll(await _infoboxLogos(pr, localTitles[pr.key]!));
        if (entries.isNotEmpty) {
          final stale = File(p.join(outDir.path, pr.stem, 'candidates.json'));
          if (stale.existsSync()) stale.deleteSync();
        }
      }
      final unique = <String>{};
      plan[pr.key] = [
        for (final e in entries)
          if (unique.add(e['file'] ?? e['url']!)) e,
      ].take(_maxCandidates).toList();
      stdout.writeln(
        '  ${pr.stem.padRight(34)} ${(plan[pr.key] as List).length} source(s)',
      );
      planFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(plan),
      );
    }
  }

  // ── Phase 2: download ──
  final pending = [
    for (final pr in presets)
      if (!File(p.join(outDir.path, pr.stem, 'candidates.json')).existsSync())
        pr,
  ];
  final names = <String>{
    for (final pr in pending)
      for (final e in (plan[pr.key] as List).cast<Map<String, dynamic>>())
        if (e['file'] != null) e['file'] as String,
  }.toList();
  stdout.writeln(
    'Resolving ${names.length} Commons files for ${pending.length} presets…',
  );
  final urls = await _resolveCommons(names);

  var withCandidates = 0;
  for (final pr in pending) {
    final dir = Directory(p.join(outDir.path, pr.stem))
      ..createSync(recursive: true);
    final candidates = <Map<String, Object?>>[];
    var n = 0;
    for (final e in (plan[pr.key] as List).cast<Map<String, dynamic>>()) {
      final file = e['file'] as String?;
      final url = file != null ? urls[file]?.url : e['url'] as String?;
      if (url == null) continue;
      if (file != null) {
        final info = urls[file]!;
        final svg = info.mime.contains('svg');
        if (svg ? info.size > _maxSvgBytes : info.size > _maxRasterBytes) {
          continue;
        }
      }
      final c = await _download(url, dir, 'c${n++}');
      if (c != null) {
        candidates.add({...c, 'source': e['source'], 'commons': file});
      }
    }
    File(p.join(dir.path, 'candidates.json')).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'key': pr.key,
        'engTitle': pr.engTitle,
        'domain': pr.domain,
        'candidates': candidates,
      }),
    );
    if (candidates.isNotEmpty) withCandidates++;
    stdout.writeln('${pr.stem.padRight(34)} ${candidates.length} candidate(s)');
  }
  stdout.writeln(
    '\n$withCandidates / ${pending.length} fetched presets have candidates.',
  );
}

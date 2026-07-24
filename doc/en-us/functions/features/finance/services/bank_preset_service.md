# lib/features/finance/services/bank_preset_service.dart

Loads and caches the 250+ bundled bank/fintech presets from `assets/banks.json` via
`rootBundle.loadString`, and provides country grouping, name search, a per-country default currency
lookup, and a priority-ordered list of logo URL sources to try (`BankPreset.logoUrls`) since no
single free logo API reliably covers every bank. `BankPresetService` is a lazily-instantiated
singleton (`BankPresetService.instance`) so the JSON asset is parsed at most once per app session.
See [Finance](../../../../features/finance.md#bankpresetservice) for how the bank preset picker uses
this.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`BankPreset()`](#bankpreset-new) | const constructor (`BankPreset`) | A | Create a bank preset entry. |
| [`BankPreset.fromJson`](#bankpreset-fromjson) | factory constructor (`BankPreset`) | A | Parse a preset from the bundled `banks.json` entry. |
| [`logoUrls`](#logourls) | getter (`BankPreset`) | A | Return logo URLs to try in priority order. |
| `logoUrl` | getter (`BankPreset`) | B | Primary (Clearbit) logo URL for a quick preview. |
| `countryCurrency` (static const map) | field | B | Country code -> default currency map — no Purpose block (see Reconciliation). |
| `defaultCurrency` | getter (`BankPreset`) | B | Default currency for this bank's country, via `countryCurrency`. |
| `BankPresetService._()` | private constructor (`BankPresetService`) | B | Prevent direct instantiation of the singleton. |
| [`getAll`](#getall) | method (`BankPresetService`) | A | Load (and cache) the full bank preset list. |
| [`groupedByCountry`](#groupedbycountry) | method (`BankPresetService`) | A | Group and sort presets by country code. |
| [`search`](#search) | method (`BankPresetService`) | A | Case-insensitive name search over the preset list. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/finance/services/bank_preset_service.dart`
returns 9, matching the 9 documented rows above exactly — each block sits immediately above its real
declaration (constructor, factory constructor, getter, or method); none were found misattached above
a call-site statement. The table has one additional row beyond those 9: the plain
`static const countryCurrency = <String, String>{...}` field, which carries no `/// Purpose:` block,
consistent with this codebase's convention of documenting callable members rather than plain data
fields — the same pattern seen in `shared/services/webdav_service.md`'s undocumented `static
const`/`static final` fields. Cross-checking every `class`, `factory`, `get`, and method declaration
in the file against this list turned up no undocumented callable declaration. `getAll`,
`groupedByCountry`, `search`, and both constructors are classified Tier A (real IO/caching or
looping logic); `logoUrl`, `defaultCurrency`, and `BankPresetService._()` are classified Tier B as
trivial one-line accessors/forwarding constructors, and `logoUrls` is classified Tier A despite being
a getter because it builds the prioritized multi-source URL list called out in
[Finance](../../../../features/finance.md#bankpresetservice).

## Documentation

### `const BankPreset({required String id, required String country, required String localTitle, required String engTitle, required String color, required String domain})` <a id="bankpreset-new"></a>
- **Kind:** const constructor of `BankPreset`
- **Source:** `lib/features/finance/services/bank_preset_service.dart` (line 19)
- **Purpose:** Hold one bank/fintech preset entry's id, country, localized/English titles, brand
  color, and web domain (used to derive logo URLs).
- **Inputs:** All six fields required.
- **Returns:** A new `BankPreset`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor.
- **Usage:** Constructed exclusively via [`BankPreset.fromJson`](#bankpreset-fromjson) when parsing
  `assets/banks.json` — there is no direct `BankPreset(...)` call site outside this file.
- **Notes:** None.

### `factory BankPreset.fromJson(Map<String, dynamic> json)` <a id="bankpreset-fromjson"></a>
- **Kind:** factory constructor of `BankPreset`
- **Source:** `lib/features/finance/services/bank_preset_service.dart` (line 33)
- **Purpose:** Parse one entry of the bundled `assets/banks.json` preset list.
- **Inputs:** `json` — one decoded map from the asset's top-level array.
- **Returns:** A new `BankPreset`.
- **Side effects:** None.
- **Algorithm:** Cast `id`/`country`/`engTitle` as required strings; `localTitle` falls back to
  `engTitle` when absent; `color` defaults `'#888888'`; `domain` defaults `''` (empty domain means no
  logo URLs, per [`logoUrls`](#logourls)).
- **Usage:**
  ```dart
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  _cache = list.map(BankPreset.fromJson).toList();
  ```
  (`lib/features/finance/services/bank_preset_service.dart:114-115`, inside
  [`getAll`](#getall).)
- **Notes:** A preset entry with no `localTitle` in the asset silently reuses `engTitle` for both
  fields — this is not a data error, just the JSON format's shorthand for "same name in both
  languages."

### `List<String> get logoUrls` <a id="logourls"></a>
- **Kind:** getter of `BankPreset`
- **Source:** `lib/features/finance/services/bank_preset_service.dart` (line 48)
- **Purpose:** Return this bank's candidate logo URLs across multiple free logo/favicon services, in
  priority order from highest to lowest expected quality, so the caller can try each until one
  succeeds.
- **Inputs:** None.
- **Returns:** `List<String>` — empty if `domain` is empty (no domain to derive a logo from).
  Otherwise, in order: Clearbit, logo.dev, Brandfetch, icon.horse, Favicone, Google's `s2/favicons`,
  DuckDuckGo's favicon proxy, and Google's `t3.gstatic` favicon CDN as a last resort.
- **Side effects:** None.
- **Algorithm:** A conditional list literal keyed on `domain.isNotEmpty`, interpolating `domain` into
  each service's URL template.
- **Usage:**
  ```dart
  if (bank == null || bank.logoUrls.isEmpty) return;
  ...
  for (final url in bank.logoUrls) {
    path = await ImageService.downloadAndSave(url);
    if (path != null) break;
  }
  ```
  (`lib/features/finance/views/accounts_page.dart:2000-2007`, `_fetchBankIcon`, trying each URL in
  order until a download succeeds.)
- **Notes:** Classified Tier A despite being a getter because it is the multi-source logo fallback
  chain called out explicitly in [Finance](../../../../features/finance.md#bankpresetservice) — no
  single source is reliable enough alone.

### `static Future<List<BankPreset>> getAll()` <a id="getall"></a>
- **Kind:** method of `BankPresetService`
- **Source:** `lib/features/finance/services/bank_preset_service.dart` (line 111)
- **Purpose:** Load and parse the full bundled bank preset list, caching the result so the asset is
  only read and parsed once per app session.
- **Inputs:** None.
- **Returns:** `Future<List<BankPreset>>`.
- **Side effects:** Reads `assets/banks.json` via `rootBundle.loadString` on a cache miss; populates
  the instance-level `_cache` field.
- **Algorithm:**
  1. Return `_cache` immediately if already populated.
  2. Otherwise load and `jsonDecode` `assets/banks.json`, cast to a list of maps, map each through
     [`BankPreset.fromJson`](#bankpreset-fromjson), store in `_cache`, and return it.
- **Usage:** Called from [`groupedByCountry`](#groupedbycountry) and [`search`](#search) as their
  shared data source; there is no direct external call site — every consumer goes through one of
  those two.
- **Notes:** The cache is never invalidated for the lifetime of the singleton — `assets/banks.json`
  is a build-time asset, so this is safe as long as the app isn't hot-reloaded with a changed asset
  bundle.

### `Future<Map<String, List<BankPreset>>> groupedByCountry()` <a id="groupedbycountry"></a>
- **Kind:** method of `BankPresetService`
- **Source:** `lib/features/finance/services/bank_preset_service.dart` (line 125)
- **Purpose:** Group every preset by country code, with each country's list sorted alphabetically by
  `localTitle`, for the bank picker's grouped display.
- **Inputs:** None.
- **Returns:** `Future<Map<String, List<BankPreset>>>`.
- **Side effects:** May trigger the one-time `assets/banks.json` load via [`getAll`](#getall).
- **Algorithm:**
  1. Fetch the full list via `getAll()`.
  2. Bucket each preset into `map[b.country]` (creating the list lazily with `??=`).
  3. Sort each country's list by `localTitle`.
- **Usage:**
  ```dart
  final grouped = await BankPresetService.instance.groupedByCountry();
  if (mounted) setState(() { _grouped = grouped; _loading = false; });
  ```
  (`lib/features/finance/widgets/bank_preset_picker.dart:106-107`, `_load`, the bank picker's initial
  grouped view.)
- **Notes:** None.

### `Future<List<BankPreset>> search(String query)` <a id="search"></a>
- **Kind:** method of `BankPresetService`
- **Source:** `lib/features/finance/services/bank_preset_service.dart` (line 143)
- **Purpose:** Case-insensitive substring search over both `localTitle` and `engTitle`, for the bank
  picker's search box.
- **Inputs:** `query` — free-text search string.
- **Returns:** `Future<List<BankPreset>>` — the full unsorted list (via [`getAll`](#getall)) when
  `query` is empty, otherwise only matching presets.
- **Side effects:** May trigger the one-time `assets/banks.json` load via [`getAll`](#getall).
- **Algorithm:**
  1. If `query` is empty, return `getAll()` unfiltered.
  2. Otherwise lowercase `query` and filter presets whose `localTitle` or `engTitle` (lowercased)
     contains it.
- **Usage:**
  ```dart
  final results = await BankPresetService.instance.search(query);
  if (mounted) {
    setState(() { ... });
  }
  ```
  (`lib/features/finance/widgets/bank_preset_picker.dart:120-122`, the bank picker's live search
  handler.)
- **Notes:** Matches are unsorted (in whatever order they appear in the cached list), unlike
  [`groupedByCountry`](#groupedbycountry)'s alphabetized groups.

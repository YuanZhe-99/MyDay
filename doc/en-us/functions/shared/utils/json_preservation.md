# lib/shared/utils/json_preservation.dart

Generic, schema-driven "don't clobber fields you don't recognize" engine, plus a hardcoded field
schema for every one of the app's five synced data files. Unlike MyDevice's schema-free sibling of
this file, MyDay's version is two things stacked together: a small generic recursive engine
(`JsonListPreservation`/`JsonPreservationSchema`/`JsonPreservation`, lines 1-251) that walks a
`next` JSON map against one or more prior-version `source` JSON maps and copies forward any
top-level or schema-declared-nested key that `next` doesn't already carry, plus ~370 lines of
per-module `JsonPreservationSchema` constants (lines 253-619) enumerating every known key of
`todo_data.json`, `finance_data.json`, `exchange_rates.json`, `intimacy_data.json`, and
`weight_data.json`, wired together in the `dataFilePreservationSchemas` map keyed by file name. The
purpose is forward/backward compatibility: if a newer (or older, or platform-specific) build of the
app writes a field this schema doesn't know about, a plain "serialize the in-memory model and
overwrite the file" would silently delete it; every `*_storage.dart`'s `save()`/`_saveNow()` calls
`JsonPreservation.encodeForFile` against the file already on disk before overwriting it, and
`WebDavService._preserveUnknownJson` (`lib/shared/services/webdav_service.dart`) calls
`JsonPreservation.preserveJsonString` against the base/local/remote JSON right after the
[three-way merge](../../../algorithms/three-way-merge.md) engine in `sync_merge.dart` produces a
merged record set, so an unrecognized field survives sync too. See
[Weight](../../../features/weight.md) for how `weight_data.json`'s own schema
(`_weightRecordSchema`/`_weightDataSchema`, lines 579-611) fits into that feature.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`JsonListPreservation` (constructor)](#jsonlistpreservation-new) | constructor (`JsonListPreservation`) | A | Describe how to key-match and preserve items of a JSON list field. |
| [`JsonPreservationSchema` (constructor)](#jsonpreservationschema-new) | constructor (`JsonPreservationSchema`) | A | Describe which keys of a JSON object are known, and any nested schemas. |
| `JsonPreservation._()` | private constructor (`JsonPreservation`) | B | Prevent instantiation of the static-only preservation utility. |
| [`encodeForFile`](#encodeforfile) | static method (`JsonPreservation`) | A | Preserve unknown fields from the file already on disk, then JSON-encode. |
| [`preserveJsonString`](#preservejsonstring) | static method (`JsonPreservation`) | A | Preserve unknown fields from one or more prior JSON strings, then re-encode. |
| [`preserve`](#preserve) | static method (`JsonPreservation`) | A | Fold unknown-key preservation from each prior source map into `next`. |
| [`_preserveOne`](#_preserveone) | static method (`JsonPreservation`) | A | Merge one source map's unknown/nested-known keys into a copy of `next`. |
| [`_preserveKeyedObjects`](#_preservekeyedobjects) | static method (`JsonPreservation`) | A | Recurse preservation into a map-of-objects field keyed by arbitrary string keys. |
| [`_preserveListItems`](#_preservelistitems) | static method (`JsonPreservation`) | A | Recurse preservation into a JSON list field, matching items by a key field. |
| [`_copyMap`](#_copymap) | static method (`JsonPreservation`) | A | Deep-copy a JSON object map. |
| [`_stringKeyMap`](#_stringkeymap) | static method (`JsonPreservation`) | A | Recast a decoded `Map` (dynamic keys) to `Map<String, dynamic>`. |
| [`_copyJsonValue`](#_copyjsonvalue) | static method (`JsonPreservation`) | A | Recursively deep-copy any decoded JSON value. |

`grep -c 'Purpose:' lib/shared/utils/json_preservation.dart` reports 12, matching all twelve real
declarations in this file exactly (the three model classes' fields and the ~20 trailing
`JsonPreservationSchema`/`JsonListPreservation` const *instances*, e.g. `_taskSchema`,
`_weightDataSchema`, and the `dataFilePreservationSchemas` map itself, are data, not
functions/methods/constructors, so they carry no `Purpose:` block and are not counted as
declarations here — they are described in prose above and under `preserve`'s Notes instead). No
misattached doc comments were found: every `/// Purpose:` block sits directly above the real
declaration it documents. Only `JsonPreservation._()` is Tier B — it is a pure
prevent-instantiation marker with no data and no logic (the same boilerplate pattern as
`DataFileSafety._()` in `lib/shared/services/data_file_safety.dart`); every other declaration
either models real schema data (the two config constructors) or performs real recursive/IO logic
over that schema.

## Documentation

### `const JsonListPreservation({required this.keyField, required this.itemSchema})` <a id="jsonlistpreservation-new"></a>
- **Kind:** const constructor of `JsonListPreservation`
- **Source:** `lib/shared/utils/json_preservation.dart` (line 13)
- **Purpose:** Describe how a JSON list-valued field should be preserved: which key field
  identifies matching items across `next`/`source`, and the schema to apply to each item.
- **Inputs:** `keyField` (e.g. `'id'` or `'start'`), `itemSchema` (a `JsonPreservationSchema` for
  one list item).
- **Returns:** A new `JsonListPreservation` instance.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:**
  ```dart
  'subtasks': JsonListPreservation(
    keyField: 'id',
    itemSchema: _subTaskSchema,
  ),
  ```
  (from `_taskSchema`'s `listFields`, line 282).
- **Notes:** `keyField` must name a field present on every item for matching to work; items whose
  `keyField` value is `null` are simply never matched against a source item (see
  `_preserveListItems`).

### `const JsonPreservationSchema({required this.knownKeys, this.objectFields = const {}, this.listFields = const {}, this.keyedObjectFields = const {}})` <a id="jsonpreservationschema-new"></a>
- **Kind:** const constructor of `JsonPreservationSchema`
- **Source:** `lib/shared/utils/json_preservation.dart` (line 30)
- **Purpose:** Describe one JSON object's shape for preservation purposes: every key this schema
  understands (`knownKeys`), plus any nested object/list/keyed-object fields that need their own
  recursive schema rather than being copied wholesale.
- **Inputs:** `knownKeys` (required `Set<String>`); `objectFields`, `listFields`,
  `keyedObjectFields` (each optional, default empty, mapping a field name to its nested schema).
- **Returns:** A new `JsonPreservationSchema` instance.
- **Side effects:** None.
- **Algorithm:** Plain field-initializing const constructor.
- **Usage:**
  ```dart
  const _weightDataSchema = JsonPreservationSchema(
    knownKeys: {
      'height', 'records', 'reminderMode', 'morningHour', 'morningMinute',
      'eveningHour', 'eveningMinute', 'reminderGraceMinutes', 'settingsModifiedAt',
    },
    listFields: {
      'records': JsonListPreservation(keyField: 'id', itemSchema: _weightRecordSchema),
    },
  );
  ```
  (lines 593-611).
- **Notes:** A key absent from `knownKeys` and from every nested-field map is treated as "unknown"
  and blindly preserved by `_preserveOne`'s final loop — so leaving a newly-added field out of
  `knownKeys` still works (it round-trips as an opaque unknown key) but means it never gets its own
  recursive nested-schema treatment if it happens to be an object/list itself.

### `static Future<String> encodeForFile({required File file, required Map<String, dynamic> next, required JsonPreservationSchema schema})` <a id="encodeforfile"></a>
- **Kind:** static method of `JsonPreservation`
- **Source:** `lib/shared/utils/json_preservation.dart` (line 51)
- **Purpose:** Read whatever JSON currently exists at `file` (if any), preserve any of its unknown
  fields into `next`, and return the final JSON string ready to write.
- **Inputs:** `file` (the on-disk data file), `next` (the freshly-serialized in-memory model as a
  map), `schema` (that file's `JsonPreservationSchema`, looked up from
  `dataFilePreservationSchemas`).
- **Returns:** `Future<String>` — the encoded JSON to persist.
- **Side effects:** Reads `file` from disk if it exists.
- **Algorithm:**
  1. If `file` exists, read and `jsonDecode` it into a single-element `sources` list.
  2. Any exception during that read/decode (missing file races, corrupt JSON) is swallowed by a
     bare `catch (_) {}` — `sources` is simply left empty in that case, so preservation is skipped
     rather than the caller being told the existing file was unreadable.
  3. Call `preserve(next: next, sources: sources, schema: schema)` and `jsonEncode` the result.
- **Usage:**
  ```dart
  final jsonStr = await JsonPreservation.encodeForFile(
    file: file,
    next: data.toJson(),
    schema: dataFilePreservationSchemas[fileName]!,
  );
  await DataFileSafety.writeValidatedDataJson(file, jsonStr);
  ```
  (`WeightStorage._saveNow`, `lib/features/weight/services/weight_storage.dart` lines 86-91 — the
  same pattern is repeated in `todo_storage.dart`, `finance_storage.dart`,
  `exchange_rate_storage.dart`, and `intimacy_storage.dart`).
- **Notes:** Unlike `WeightStorage.load()` (which throws a typed `WeightStorageException` on a
  corrupt existing file so callers never mistake corruption for an empty dataset), a corrupt
  *existing* file here is silently treated as "no source to preserve from" — the save still
  succeeds and simply doesn't carry forward any of that file's unknown fields.

### `static String preserveJsonString({required String nextJson, required Iterable<String?> sourceJsons, required JsonPreservationSchema schema})` <a id="preservejsonstring"></a>
- **Kind:** static method of `JsonPreservation`
- **Source:** `lib/shared/utils/json_preservation.dart` (line 72)
- **Purpose:** Same preservation as `encodeForFile`, but starting from JSON strings already in
  memory (used during sync, where base/local/remote JSON are all already loaded) instead of a
  single on-disk file.
- **Inputs:** `nextJson` (the merged JSON to preserve into), `sourceJsons` (an ordered iterable of
  nullable JSON strings — `null` entries are skipped), `schema`.
- **Returns:** `String` — the re-encoded JSON.
- **Side effects:** None (pure string/JSON transformation).
- **Algorithm:**
  1. `jsonDecode(nextJson)` — **not** wrapped in a try/catch, so a malformed `nextJson` throws
     straight to the caller (unlike each `sourceJson`, below).
  2. For each non-null entry of `sourceJsons`, attempt `jsonDecode`; a `FormatException` (or any
     other decode error) on an individual source is swallowed and that source is simply skipped.
  3. Call `preserve(next: next, sources: sources, schema: schema)` and `jsonEncode` the result.
- **Usage:**
  ```dart
  return JsonPreservation.preserveJsonString(
    nextJson: mergedJson,
    sourceJsons: [baseJson, localJson, remoteJson],
    schema: schema,
  );
  ```
  (`WebDavService._preserveUnknownJson`, `lib/shared/services/webdav_service.dart` lines 623-627).
- **Notes:** The order of `sourceJsons` matters when the same unknown key exists in more than one
  source with different values: `preserve` applies sources in list order and later sources
  overwrite earlier ones for that key (see `preserve`'s Notes) — so with the
  `[baseJson, localJson, remoteJson]` order used by `_preserveUnknownJson`, remote's value for an
  unrecognized field wins over local's, which wins over base's.

### `static Map<String, dynamic> preserve({required Map<String, dynamic> next, required Iterable<Map<String, dynamic>> sources, required JsonPreservationSchema schema})` <a id="preserve"></a>
- **Kind:** static method of `JsonPreservation`
- **Source:** `lib/shared/utils/json_preservation.dart` (line 93)
- **Purpose:** Fold unknown-field preservation from every map in `sources` into a deep copy of
  `next`, in order.
- **Inputs:** `next`, `sources` (zero or more prior-version maps to preserve from), `schema`.
- **Returns:** `Map<String, dynamic>` — `next` with unknown/nested-known fields from every source
  layered in.
- **Side effects:** None.
- **Algorithm:**
  1. `result = _copyMap(next)` (deep copy, so the caller's `next` map is never mutated).
  2. For each `source` in `sources`, in iteration order:
     `result = _preserveOne(next: result, source: source, schema: schema)`.
  3. Return the final `result`.
- **Usage:**
  ```dart
  return jsonEncode(preserve(next: next, sources: sources, schema: schema));
  ```
  (called from both `encodeForFile`, line 64, and `preserveJsonString`, line 85).
- **Notes:** Because each iteration's output becomes the next iteration's `next`, a later source's
  value for a given unrecognized key always overwrites an earlier source's value for that same key
  — `sources` is not a "first match wins" list, it's a fold where the last entry has final say on
  any unknown-key collision.

### `static Map<String, dynamic> _preserveOne({required Map<String, dynamic> next, required Map<String, dynamic> source, required JsonPreservationSchema schema})` <a id="_preserveone"></a>
- **Kind:** private static method of `JsonPreservation`
- **Source:** `lib/shared/utils/json_preservation.dart` (line 110)
- **Purpose:** Merge a single `source` map into a copy of `next`, recursing into any
  schema-declared nested object/keyed-object/list field and copying forward every other key
  `source` has that `schema.knownKeys` doesn't recognize.
- **Inputs:** `next`, `source`, `schema`.
- **Returns:** `Map<String, dynamic>`.
- **Side effects:** None.
- **Algorithm:**
  1. `result = _copyMap(next)`.
  2. For each `objectFields` entry: if both `result[key]` and `source[key]` are `Map`s, replace
     `result[key]` with `_preserveOne` recursed into that nested schema. If `next` doesn't have that
     key as a `Map` at all (e.g. a nullable field omitted by `toJson()`'s
     `if (x != null) 'key': x` pattern), nothing is preserved into it from `source` — the branch is
     silently skipped.
  3. For each `keyedObjectFields` entry (maps-of-objects keyed by arbitrary strings, e.g.
     `dailyScores` by date or `snapshots` by id): same Map/Map check, delegated to
     `_preserveKeyedObjects`.
  4. For each `listFields` entry: same Map/Map check (but `List`/`List` here), delegated to
     `_preserveListItems`.
  5. Finally, for every entry in `source` whose key is **not** in `schema.knownKeys`, copy it
     (`_copyJsonValue`) into `result`, overwriting whatever was there — this is the actual "carry
     forward a field this schema doesn't know about" step; steps 2-4 only handle fields the schema
     *does* know about but wants to preserve recursively rather than wholesale-overwrite.
- **Usage:**
  ```dart
  result = _preserveOne(next: result, source: source, schema: schema);
  ```
  (`preserve`, line 100 — the only two other call sites, `_preserveKeyedObjects` line 175 and
  `_preserveListItems` line 209, recurse into nested object/list-item schemas the same way).
- **Notes:** Step 5 always wins over whatever `next` already had for an unknown key, so if the
  in-memory model somehow already wrote a value under a key outside `schema.knownKeys` (shouldn't
  normally happen, since `toJson()` only emits known keys), the on-disk/source value for that key
  would silently replace it.

### `static Map<String, dynamic> _preserveKeyedObjects({required Map<String, dynamic> next, required Map<String, dynamic> source, required JsonPreservationSchema schema})` <a id="_preservekeyedobjects"></a>
- **Kind:** private static method of `JsonPreservation`
- **Source:** `lib/shared/utils/json_preservation.dart` (line 166)
- **Purpose:** Preserve unknown fields within each entry of a map-of-objects field (e.g.
  `dailyScores`, `snapshots`), keyed by an arbitrary string rather than a list index or `id` field.
- **Inputs:** `next`, `source`, `schema` (applied to every value in the map).
- **Returns:** `Map<String, dynamic>`.
- **Side effects:** None.
- **Algorithm:**
  1. `result = _copyMap(next)`.
  2. For every key currently in `result` (i.e. present in `next`): if both `result[key]` and
     `source[key]` are `Map`s, recurse `_preserveOne` into them under `schema`.
  3. Return `result`.
- **Usage:**
  ```dart
  result[entry.key] = _preserveKeyedObjects(
    next: _stringKeyMap(nextValue),
    source: _stringKeyMap(sourceValue),
    schema: entry.value,
  );
  ```
  (`_preserveOne`, lines 133-137).
- **Notes:** Iteration is driven by `next`'s keys only — an entry present in `source` but no longer
  in `next` (deleted) is never resurrected here; this preservation layer never decides which
  dictionary entries exist, only what unknown sub-fields survive within entries `next` already has.

### `static List<dynamic> _preserveListItems({required List<dynamic> next, required List<dynamic> source, required JsonListPreservation listSchema})` <a id="_preservelistitems"></a>
- **Kind:** private static method of `JsonPreservation`
- **Source:** `lib/shared/utils/json_preservation.dart` (line 190)
- **Purpose:** Preserve unknown per-item fields within a JSON list, matching `next` items to
  `source` items by `listSchema.keyField` (e.g. record `id`).
- **Inputs:** `next`, `source`, `listSchema`.
- **Returns:** `List<dynamic>`.
- **Side effects:** None.
- **Algorithm:**
  1. Build `sourceByKey`: for every `Map` item in `source`, key it by
     `itemMap[listSchema.keyField]` (items with a `null` key value are skipped).
  2. Map over `next` in order: non-`Map` items are copied as-is via `_copyJsonValue`; `Map` items
     look up their matching `source` item by the same key field — no match (a new item) → plain
     `_copyMap`; a match found → `_preserveOne` merges that source item's unknown fields in.
  3. Return the mapped list.
- **Usage:**
  ```dart
  result[entry.key] = _preserveListItems(
    next: nextValue,
    source: sourceValue,
    listSchema: entry.value,
  );
  ```
  (`_preserveOne`, lines 145-149).
- **Notes:** Order and membership of the resulting list always follow `next` — an item present in
  `source` but absent from `next` (deleted upstream, e.g. by `mergeRecords` — see
  [Three-Way Merge](../../../algorithms/three-way-merge.md)) is simply never added back; this layer
  only enriches items that already survived whatever produced `next`.

### `static Map<String, dynamic> _copyMap(Map<String, dynamic> map)` <a id="_copymap"></a>
- **Kind:** private static method of `JsonPreservation`
- **Source:** `lib/shared/utils/json_preservation.dart` (line 222)
- **Purpose:** Deep-copy a JSON object map so downstream mutation never aliases the caller's map.
- **Inputs:** `map`.
- **Returns:** `Map<String, dynamic>` — a new map with every value passed through `_copyJsonValue`.
- **Side effects:** None.
- **Algorithm:** `map.map((key, value) => MapEntry(key, _copyJsonValue(value)))` — one pass over
  every entry, recursively deep-copying each value.
- **Usage:**
  ```dart
  var result = _copyMap(next);
  ```
  (`preserve`, line 98; also used at the start of `_preserveOne`, `_preserveKeyedObjects`, and for
  matched-less list items in `_preserveListItems`).
- **Notes:** None.

### `static Map<String, dynamic> _stringKeyMap(Map map)` <a id="_stringkeymap"></a>
- **Kind:** private static method of `JsonPreservation`
- **Source:** `lib/shared/utils/json_preservation.dart` (line 231)
- **Purpose:** Recast a `Map` decoded by `jsonDecode` (whose static type is `Map<dynamic, dynamic>`)
  to the `Map<String, dynamic>` shape the rest of this file assumes.
- **Inputs:** `map`.
- **Returns:** `Map<String, dynamic>`.
- **Side effects:** None.
- **Algorithm:** `map.map((key, value) => MapEntry(key as String, value))` — a hard `as String`
  cast on every key, values passed through unchanged.
- **Usage:**
  ```dart
  result[entry.key] = _preserveOne(
    next: _stringKeyMap(nextValue),
    source: _stringKeyMap(sourceValue),
    schema: entry.value,
  );
  ```
  (`_preserveOne`, lines 121-125, when recursing into an `objectFields` entry).
- **Notes:** Throws a `TypeError` if any key in `map` is not actually a `String` — not expected for
  JSON-decoded data (JSON object keys are always strings), so this is effectively a type-narrowing
  cast rather than a validated conversion.

### `static dynamic _copyJsonValue(dynamic value)` <a id="_copyjsonvalue"></a>
- **Kind:** private static method of `JsonPreservation`
- **Source:** `lib/shared/utils/json_preservation.dart` (line 240)
- **Purpose:** Recursively deep-copy any value that can appear in decoded JSON (`Map`, `List`, or a
  scalar), so no returned structure shares a mutable `Map`/`List` with its source.
- **Inputs:** `value`.
- **Returns:** `dynamic` — a structurally-copied value; scalars are returned unchanged (they're
  already immutable in Dart).
- **Side effects:** None.
- **Algorithm:** If `value is Map`, recurse into every entry's value; if `value is List`, recurse
  into every element; otherwise return `value` as-is.
- **Usage:**
  ```dart
  return map.map((key, value) => MapEntry(key, _copyJsonValue(value)));
  ```
  (`_copyMap`, line 223; also called directly on non-`Map` list items in `_preserveListItems`,
  line 204, and on every unknown-key value copied in `_preserveOne`, line 155).
- **Notes:** None.

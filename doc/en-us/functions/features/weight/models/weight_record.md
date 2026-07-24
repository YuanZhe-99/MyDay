# lib/features/weight/models/weight_record.dart

Data model for the Weight feature: `WeightRecord` (one logged weight/body-composition entry) and
`WeightData` (the whole `weight_data.json` document — height, records, and reminder settings), plus
the BMI/waist-hip-ratio formulas and the "inherit the latest positive measurement" display logic
described in [Weight](../../../../features/weight.md). Persisted and loaded by
[`WeightStorage`](../services/weight_storage.md), preserved field-by-field across saves/sync by the
hardcoded `_weightRecordSchema`/`_weightDataSchema` in
[`json_preservation.dart`](../../../shared/utils/json_preservation.md), and merged across
devices by `mergeWeightData` (see [Three-Way Merge](../../../../algorithms/three-way-merge.md)).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`WeightRecord` (constructor)](#weightrecord-new) | constructor (`WeightRecord`) | A | Create a weight record, defaulting `id`/`datetime`/`modifiedAt`. |
| [`WeightRecord.toJson`](#weightrecord-tojson) | method (`WeightRecord`) | A | Serialize this record to a JSON-compatible map. |
| [`WeightRecord.fromJson`](#weightrecord-fromjson) | factory constructor (`WeightRecord`) | A | Parse a record from its persisted/synced JSON shape. |
| [`WeightRecord.copyWith`](#copywith) | method (`WeightRecord`) | A | Copy this record with selected fields replaced or cleared. |
| [`WeightData` (constructor)](#weightdata-new) | constructor (`WeightData`) | A | Create a weight data document, defaulting `reminderGraceMinutes`/`settingsModifiedAt`. |
| [`WeightData.toJson`](#weightdata-tojson) | method (`WeightData`) | A | Serialize the whole weight document to a JSON-compatible map. |
| [`WeightData.fromJson`](#weightdata-fromjson) | factory constructor (`WeightData`) | A | Parse the whole weight document from its persisted/synced JSON shape. |
| [`WeightData.calculateBMI`](#calculatebmi) | static method (`WeightData`) | A | Compute BMI from height and weight. |
| [`WeightData.calculateWaistHipRatio`](#calculatewaisthipratio) | static method (`WeightData`) | A | Compute waist-hip ratio from two circumferences. |
| [`WeightData.effectiveMeasurementsUpTo`](#effectivemeasurementsupto) | static method (`WeightData`) | A | Return the latest-known bust/waist/hip as of a given time. |
| [`WeightData.effectiveMeasurementTimeline`](#effectivemeasurementtimeline) | static method (`WeightData`) | A | Build a per-record timeline of latest-known bust/waist/hip. |
| [`WeightData._positiveMeasurement`](#_positivemeasurement) | private static method (`WeightData`) | A | Normalize a measurement to `null` unless it is strictly positive. |
| [`WeightData._compareRecordsChronologically`](#_comparerecordschronologically) | private static method (`WeightData`) | A | Order records by datetime, then `modifiedAt`, then `id`. |

`grep -c 'Purpose:' lib/features/weight/models/weight_record.dart` reports 13, matching all thirteen
real declarations in this file exactly. No misattached doc comments were found (every block sits
directly above the real constructor/method it documents), and no undocumented real declaration
exists — the two record typedefs (`EffectiveWeightMeasurements`,
`EffectiveWeightMeasurementPoint`) are plain type aliases with no `Purpose:` block, which is
expected since they declare a shape, not behavior. Every declaration is Tier A: the two public
constructors and both `toJson`/`fromJson`/`copyWith` pairs fall under the explicit
constructors/`fromJson`/`toJson`/`copyWith` Tier A rule, and every remaining static method
(`calculateBMI`, `calculateWaistHipRatio`, `effectiveMeasurementsUpTo`,
`effectiveMeasurementTimeline`, and the two private helpers) contains real branching, sorting, or
looping — there is no plain getter/setter or widget-building code in this file.

## Documentation

### `WeightRecord({String? id, required this.weight, this.bodyFat, this.bustCm, this.waistCm, this.hipCm, DateTime? datetime, this.notes, DateTime? modifiedAt})` <a id="weightrecord-new"></a>
- **Kind:** constructor of `WeightRecord`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 31)
- **Purpose:** Create a weight record, generating a fresh `id`/`datetime`/`modifiedAt` when they're
  omitted.
- **Inputs:** `weight` (kg, required); optional `bodyFat` (%), `bustCm`/`waistCm`/`hipCm` (cm),
  `notes`; optional `id`, `datetime`, `modifiedAt` overrides.
- **Returns:** A new `WeightRecord`.
- **Side effects:** None (`Uuid().v4()`/`DateTime.now()` are pure w.r.t. the object itself, though
  each call produces a fresh value).
- **Algorithm:** `id ??= Uuid().v4()`; `datetime ??= DateTime.now()` (local time); `modifiedAt ??=
  DateTime.now().toUtc()` — note `datetime` defaults to local time while `modifiedAt` always
  defaults to UTC.
- **Usage:**
  ```dart
  WeightRecord(
    weight: weight,
    bustCm: bustCm,
    waistCm: waistCm,
    hipCm: hipCm,
    datetime: _date,
    notes: notes,
  );
  ```
  (`lib/features/weight/views/weight_page.dart`, lines 2206-2213, the "no existing record to copy
  from" branch of the add/edit dialog's save handler).
- **Notes:** Circumference fields are stored in centimeters; all three are independently optional.

### `Map<String, dynamic> toJson()` <a id="weightrecord-tojson"></a>
- **Kind:** method of `WeightRecord`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 50)
- **Purpose:** Serialize this record into the JSON shape persisted in `weight_data.json` and sent
  over sync.
- **Inputs:** None.
- **Returns:** `Map<String, dynamic>` with `id`, `weight`, `datetime` (ISO 8601), `modifiedAt` (ISO
  8601), plus `bodyFat`/`bustCm`/`waistCm`/`hipCm`/`notes` only when non-null.
- **Side effects:** None.
- **Algorithm:** Map literal with `if (x != null) 'key': x` conditional entries for every optional
  field, so a null field is omitted from the map entirely rather than written as JSON `null`.
- **Usage:** `data.toJson()` passed as `next` to
  `JsonPreservation.encodeForFile` in [`WeightStorage._saveNow`](../services/weight_storage.md#_savenow).
- **Notes:** Because optional fields are omitted (not nulled) when absent, `_weightRecordSchema` in
  `json_preservation.dart` never needs to distinguish "explicitly null" from "not present" — both
  produce a missing key.

### `factory WeightRecord.fromJson(Map<String, dynamic> json)` <a id="weightrecord-fromjson"></a>
- **Kind:** factory constructor of `WeightRecord`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 67)
- **Purpose:** Reconstruct a `WeightRecord` from its persisted or synced JSON shape.
- **Inputs:** `json` — expected to contain at least `id`, `weight`, `datetime`.
- **Returns:** A new `WeightRecord`.
- **Side effects:** None.
- **Algorithm:** Casts `weight`/`bodyFat`/`bustCm`/`waistCm`/`hipCm` through `(num?).toDouble()`
  (accepting either JSON int or double), parses `datetime` via `DateTime.parse`; if
  `modifiedAt` is absent, defaults to `DateTime.now()` (local time, **not** UTC — unlike the
  constructor's own default) rather than throwing.
- **Usage:**
  ```dart
  records: (json['records'] as List? ?? [])
      .map((e) => WeightRecord.fromJson(e as Map<String, dynamic>))
      .toList(),
  ```
  (`WeightData.fromJson`, lines 167-169).
- **Notes:** A record whose stored `datetime`/`weight` are malformed or missing throws (via the
  non-null casts / `DateTime.parse`), matching `WeightStorage.load()`'s intent that a corrupt file
  surface as an error rather than silently becoming an empty dataset.

### `WeightRecord copyWith({double? weight, double? bodyFat, bool clearBodyFat = false, double? bustCm, bool clearBustCm = false, double? waistCm, bool clearWaistCm = false, double? hipCm, bool clearHipCm = false, DateTime? datetime, String? notes, bool clearNotes = false})` <a id="copywith"></a>
- **Kind:** method of `WeightRecord`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 86)
- **Purpose:** Produce a modified copy of this record, keeping the same `id`, replacing given
  fields, and clearing nullable fields via explicit `clearXxx` flags rather than by passing `null`.
- **Inputs:** Replacement values for `weight`/`bodyFat`/`bustCm`/`waistCm`/`hipCm`/`datetime`/
  `notes`; `clearBodyFat`/`clearBustCm`/`clearWaistCm`/`clearHipCm`/`clearNotes` booleans.
- **Returns:** A new `WeightRecord` with the same `id` as `this`.
- **Side effects:** None (`modifiedAt` is stamped to `DateTime.now().toUtc()` on the new instance).
- **Algorithm:** For each nullable field, `clearX ? null : (x ?? this.x)` — the clear flag takes
  precedence over any replacement value passed alongside it. `weight`/`datetime` (non-nullable
  fields) simply fall back to `this.weight`/`this.datetime` when omitted. `modifiedAt` is always
  regenerated (never inherited from `this`), so every `copyWith` call bumps the record's
  modification time.
- **Usage:**
  ```dart
  widget.initialRecord?.copyWith(
    weight: weight,
    bustCm: bustCm,
    clearBustCm: bustCm == null,
    waistCm: waistCm,
    clearWaistCm: waistCm == null,
    hipCm: hipCm,
    clearHipCm: hipCm == null,
    datetime: _date,
    notes: notes,
    clearNotes: notes == null,
  ) ?? WeightRecord(/* ... */);
  ```
  (`lib/features/weight/views/weight_page.dart`, lines 2194-2213 — the edit dialog always passes
  `clearX: x == null` alongside `x`, so clearing a field in the UI reliably nulls it out instead of
  being ignored by the `x ?? this.x` fallback).
- **Notes:** Passing a non-null replacement value together with its `clear` flag set to `true`
  still clears the field — `clearBodyFat ? null : (...)` checks the flag first.

### `WeightData({this.height, required this.records, this.reminderMode = 'none', this.morningHour, this.morningMinute, this.eveningHour, this.eveningMinute, this.reminderGraceMinutes = 180, DateTime? settingsModifiedAt})` <a id="weightdata-new"></a>
- **Kind:** constructor of `WeightData`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 130)
- **Purpose:** Create the whole weight document: height, the record list, and reminder settings,
  with `reminderGraceMinutes` defaulting to **180** and `settingsModifiedAt` defaulting to the Unix
  epoch when not supplied.
- **Inputs:** `records` (required); optional `height`, `reminderMode` (`'none'`/`'once'`/`'twice'`),
  `morningHour`/`morningMinute`, `eveningHour`/`eveningMinute`, `reminderGraceMinutes`,
  `settingsModifiedAt`.
- **Returns:** A new `WeightData`.
- **Side effects:** None.
- **Algorithm:** `settingsModifiedAt ??= DateTime.fromMillisecondsSinceEpoch(0)` — every other field
  is a direct assignment or literal default.
- **Usage:**
  ```dart
  await WeightStorage.save(
    WeightData(
      height: _height,
      records: _records,
      reminderMode: _reminderMode,
      morningHour: _weightMorningReminder?.hour,
      morningMinute: _weightMorningReminder?.minute,
      eveningHour: _weightEveningReminder?.hour,
      eveningMinute: _weightEveningReminder?.minute,
      /* ... */
    ),
  );
  ```
  (`lib/features/weight/views/weight_page.dart`, lines 161-169).
- **Notes:** Defaulting `settingsModifiedAt` to the epoch (rather than "now") means a freshly
  created `WeightData` always loses a last-writer-wins settings merge against any peer that has
  ever saved settings before — this is deliberate so an unsaved-settings device never overwrites a
  real prior settings value during sync.

### `Map<String, dynamic> toJson()` <a id="weightdata-tojson"></a>
- **Kind:** method of `WeightData`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 148)
- **Purpose:** Serialize the whole weight document into the `weight_data.json` shape.
- **Inputs:** None.
- **Returns:** `Map<String, dynamic>` with `records` (always present, as a list), `reminderMode`,
  `reminderGraceMinutes`, `settingsModifiedAt` (always present), and `height`/`morningHour`/
  `morningMinute`/`eveningHour`/`eveningMinute` only when non-null.
- **Side effects:** None.
- **Algorithm:** Map literal; `records.map((r) => r.toJson()).toList()` for the record list, plus
  conditional entries for the nullable settings fields.
- **Usage:** `data.toJson()` passed as `next` to
  `JsonPreservation.encodeForFile` in [`WeightStorage._saveNow`](../services/weight_storage.md#_savenow).
- **Notes:** None.

### `factory WeightData.fromJson(Map<String, dynamic> json)` <a id="weightdata-fromjson"></a>
- **Kind:** factory constructor of `WeightData`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 165)
- **Purpose:** Reconstruct the whole weight document from its persisted/synced JSON shape.
- **Inputs:** `json`.
- **Returns:** A new `WeightData`.
- **Side effects:** None.
- **Algorithm:** `records` defaults to `[]` if absent/null (rather than throwing), then each entry
  is parsed via `WeightRecord.fromJson`; `reminderMode` defaults to `'none'`;
  `reminderGraceMinutes` defaults to **180**; `settingsModifiedAt` defaults to the Unix epoch if
  absent — the same defaults as the constructor, applied explicitly here for the JSON-parsing path.
- **Usage:** `WeightData.fromJson(json)` in `WeightStorage.load()` (see
  [`WeightStorage.load`](../services/weight_storage.md#load)).
- **Notes:** A missing/null `records` key parses as an empty list rather than throwing, so an
  otherwise-valid weight file that has never logged a record still loads successfully.

### `static double? calculateBMI(double? heightCm, double weightKg)` <a id="calculatebmi"></a>
- **Kind:** static method of `WeightData`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 187)
- **Purpose:** Calculate BMI from height and weight.
- **Inputs:** `heightCm` (nullable), `weightKg`.
- **Returns:** `double?` — `null` when `heightCm` is `null` or `<= 0`; otherwise
  `weightKg / (heightM * heightM)` with `heightM = heightCm / 100`.
- **Side effects:** None.
- **Algorithm:** Guard clause on `heightCm`, then the standard BMI formula in meters.
- **Usage:** `WeightData.calculateBMI(_height, latest.weight)` (`weight_page.dart`, line 205, and
  again at lines 1446 and 2154 for history-row and dialog-preview BMI display).
- **Notes:** Does not validate `weightKg` (a zero or negative weight is not guarded against here;
  the UI's own entry validation is what keeps `weight` positive).

### `static double? calculateWaistHipRatio(double? waistCm, double? hipCm)` <a id="calculatewaisthipratio"></a>
- **Kind:** static method of `WeightData`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 198)
- **Purpose:** Calculate waist-hip ratio from circumference measurements.
- **Inputs:** `waistCm`, `hipCm` (both nullable).
- **Returns:** `double?` — `null` unless **both** are non-null and `> 0`; otherwise
  `waistCm / hipCm`.
- **Side effects:** None.
- **Algorithm:** Two sequential guard clauses (waist, then hip), then plain division.
- **Usage:**
  ```dart
  final waistHipRatio = WeightData.calculateWaistHipRatio(
    effectiveMeasurements.waistCm,
    effectiveMeasurements.hipCm,
  );
  ```
  (`weight_page.dart`, lines 389-391 — fed from `effectiveMeasurementsUpTo`'s inherited values
  rather than the raw record fields).
- **Notes:** None.

### `static EffectiveWeightMeasurements effectiveMeasurementsUpTo(List<WeightRecord> records, DateTime at)` <a id="effectivemeasurementsupto"></a>
- **Kind:** static method of `WeightData`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 209)
- **Purpose:** Return the bust/waist/hip values that should be *displayed* as of a given moment,
  independently inheriting each field's latest positive value from earlier records without
  mutating any stored record. See [Weight](../../../../features/weight.md#bustwaisthip-inheritance-from-the-latest-positive-value)
  for the concept-level explanation.
- **Inputs:** `records`, `at` (the cutoff moment — typically the latest record's `datetime`).
- **Returns:** `EffectiveWeightMeasurements` — a `({double? bustCm, double? waistCm, double? hipCm})`
  record type.
- **Side effects:** None.
- **Algorithm:**
  1. Filter to records with `datetime <= at`, sort via `_compareRecordsChronologically`.
  2. Walk the sorted list forward; for each of bust/waist/hip independently, keep the most recent
     value that passes `_positiveMeasurement` (i.e. non-null and `> 0`), falling back to whatever
     was already accumulated (`_positiveMeasurement(record.bustCm) ?? bustCm`) when the current
     record's value is absent/non-positive.
  3. Return the three accumulated values as a single record.
- **Usage:**
  ```dart
  final effectiveMeasurements = WeightData.effectiveMeasurementsUpTo(
    _records,
    latest.datetime,
  );
  ```
  (`weight_page.dart`, lines 384-386, feeding the summary cards; the Intimacy feature's Body layer
  calls the same function to mirror the user's measurements — see
  [Weight](../../../../features/weight.md#related-pages)).
- **Notes:** A record that only updates `weight` (leaving bust/waist/hip blank) still displays the
  last-known bust/waist/hip from earlier records — the inheritance is display-only and never
  written back into the stored record.

### `static List<EffectiveWeightMeasurementPoint> effectiveMeasurementTimeline(List<WeightRecord> records)` <a id="effectivemeasurementtimeline"></a>
- **Kind:** static method of `WeightData`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 232)
- **Purpose:** Build the same latest-positive-value inheritance as `effectiveMeasurementsUpTo`, but
  as a full per-record timeline for chart rendering instead of a single cutoff snapshot.
- **Inputs:** `records`.
- **Returns:** `List<EffectiveWeightMeasurementPoint>` — one point per record, in chronological
  order, each carrying `datetime` plus the accumulated `bustCm`/`waistCm`/`hipCm`.
- **Side effects:** None.
- **Algorithm:** Same forward walk as `effectiveMeasurementsUpTo` over *all* records (no `at`
  cutoff/filter), appending one `EffectiveWeightMeasurementPoint` per record as it accumulates each
  field's latest positive value.
- **Usage:**
  ```dart
  final timeline = WeightData.effectiveMeasurementTimeline(_records);
  final visibleTimeline = timeline
      .where((point) => !point.datetime.isBefore(cutoff))
  ```
  (`weight_page.dart`, lines 967-969, feeding the bust-waist-hip trend chart).
- **Notes:** Unlike `effectiveMeasurementsUpTo`, this always processes the full record list; range
  filtering (e.g. `cutoff`) is applied by the caller afterward on the returned timeline, not by this
  function.

### `static double? _positiveMeasurement(double? value)` <a id="_positivemeasurement"></a>
- **Kind:** private static method of `WeightData`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 260)
- **Purpose:** Normalize a stored measurement value for the inheritance walk: treat null, zero, and
  negative as "not measured".
- **Inputs:** `value`.
- **Returns:** `double?` — `null` if `value` is `null` or `<= 0`; otherwise `value` unchanged.
- **Side effects:** None.
- **Algorithm:** Single guard clause.
- **Usage:** `bustCm = _positiveMeasurement(record.bustCm) ?? bustCm;` (inside both
  `effectiveMeasurementsUpTo` and `effectiveMeasurementTimeline`, lines 220/242 etc.).
- **Notes:** None.

### `static int _compareRecordsChronologically(WeightRecord a, WeightRecord b)` <a id="_comparerecordschronologically"></a>
- **Kind:** private static method of `WeightData`
- **Source:** `lib/features/weight/models/weight_record.dart` (line 270)
- **Purpose:** Provide a deterministic total order for records sharing the same `datetime`.
- **Inputs:** `a`, `b`.
- **Returns:** `int` — standard `Comparable`-style sort-order result.
- **Side effects:** None.
- **Algorithm:** Compare `datetime` first; if equal, compare `modifiedAt`; if still equal, compare
  `id` (`String.compareTo`) — a three-level tie-break that guarantees a stable order even for two
  records logged at the exact same instant.
- **Usage:** `..sort(_compareRecordsChronologically)` in both `effectiveMeasurementsUpTo` (line 215)
  and `effectiveMeasurementTimeline` (line 236).
- **Notes:** None.

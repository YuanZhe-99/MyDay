# lib/features/intimacy/models/intimacy_record.dart

The data models for the entire Intimacy feature: `BodyProfile`, `CycleRecord`, `Partner`, `Toy`,
`Position`, `IntimacyRecord`, `TimerHistoryEntry`, `IntimacyTimerSession`, and the top-level
`IntimacyData` container. Every model follows the same shape as the rest of this codebase's feature
models: a field-assigning constructor with a generated `id` (via `uuid`) and `modifiedAt` (UTC "now")
when not supplied, plus a `toJson`/`fromJson` pair for the persisted/synced `intimacy_data.json`
format — `BodyProfile` and `Partner` additionally have `copyWith`. `services/intimacy_storage.dart`
loads/saves the whole `IntimacyData` tree; `services/body_metrics.dart` and
`services/cycle_predictor.dart` are pure calculators that read `BodyProfile`/`CycleRecord` fields but
never store their own results. See [Intimacy](../../../../features/intimacy.md) for how these models
fit into the feature, [Data Formats](../../../../data-formats.md#intimacy--intimacy_datajson) for the
exact JSON field list, and
[Three-Way Merge](../../../../algorithms/three-way-merge.md#deletionunion-semantics) for
`CycleRecord`'s add/delete-only sync semantics.

## Declarations

Anchor note: `toJson` is defined on nine different classes in this file (`BodyProfile`,
`CycleRecord`, `Partner`, `Toy`, `Position`, `IntimacyRecord`, `TimerHistoryEntry`,
`IntimacyTimerSession`, `IntimacyData`), and `copyWith` is defined on two (`BodyProfile`, `Partner`).
To keep anchors unique on this page, those rows use a class-qualified anchor (`bodyprofile-tojson`,
`partner-copywith`, etc.) instead of the bare-name anchor the general rule would otherwise produce;
every other row uses the plain bare-name anchor. The `fromJson` factory constructors and default
constructors are already unique per the `<classname>-<namedConstructorLowercased>`/`<classname>-new`
anchor rule.

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`BodyProfile()`](#bodyprofile-new) | constructor (`BodyProfile`) | A | Create a body profile instance from optional measurements and cycle display preferences. |
| [`isEmpty`](#isempty) | getter (`BodyProfile`) | A | Report whether this profile carries no data at all. |
| [`toJson`](#bodyprofile-tojson) | method (`BodyProfile`) | A | Serialize a body profile to JSON, omitting absent fields entirely. |
| [`BodyProfile.fromJson`](#bodyprofile-fromjson) | factory constructor (`BodyProfile`) | A | Parse a body profile from JSON. |
| [`copyWith`](#bodyprofile-copywith) | method (`BodyProfile`) | A | Copy a body profile with selected fields replaced or cleared. |
| [`CycleRecord()`](#cyclerecord-new) | constructor (`CycleRecord`) | A | Create a cycle record for one recorded menstrual period start date. |
| [`day`](#day) | getter (`CycleRecord`) | A | Return the record's calendar day as a date-only local `DateTime`. |
| [`formatDate`](#formatdate) | static method (`CycleRecord`) | A | Format a calendar date as the stored `yyyy-MM-dd` string. |
| [`toJson`](#cyclerecord-tojson) | method (`CycleRecord`) | A | Serialize a cycle record to JSON. |
| [`CycleRecord.fromJson`](#cyclerecord-fromjson) | factory constructor (`CycleRecord`) | A | Parse a cycle record from JSON. |
| [`Partner()`](#partner-new) | constructor (`Partner`) | A | Create a partner instance, generating `id`/`modifiedAt` if omitted. |
| [`toJson`](#partner-tojson) | method (`Partner`) | A | Serialize a partner (and its optional `BodyProfile`) to JSON. |
| [`Partner.fromJson`](#partner-fromjson) | factory constructor (`Partner`) | A | Parse a partner from JSON. |
| [`copyWith`](#partner-copywith) | method (`Partner`) | A | Copy a partner with selected fields replaced or cleared, always stamping a fresh `modifiedAt`. |
| [`Toy()`](#toy-new) | constructor (`Toy`) | A | Create a toy instance, generating `id`/`modifiedAt` if omitted. |
| [`hasCostData`](#hascostdata) | getter (`Toy`) | A | Report whether this toy has cost data (a non-null price) to summarize. |
| [`serviceDays`](#servicedays) | method (`Toy`) | A | Calculate the toy's service days (purchase to retirement/now) for cost averaging. |
| [`totalCost`](#totalcost) | method (`Toy`) | A | Return the toy's total recorded cost. |
| [`averageDailyCost`](#averagedailycost) | method (`Toy`) | A | Calculate the toy's average daily cost. |
| [`toJson`](#toy-tojson) | method (`Toy`) | A | Serialize a toy to JSON. |
| [`Toy.fromJson`](#toy-fromjson) | factory constructor (`Toy`) | A | Parse a toy from JSON. |
| [`Position()`](#position-new) | constructor (`Position`) | A | Create a position instance, generating `id`/`modifiedAt` if omitted. |
| [`toJson`](#position-tojson) | method (`Position`) | A | Serialize a position to JSON. |
| [`Position.fromJson`](#position-fromjson) | factory constructor (`Position`) | A | Parse a position from JSON. |
| [`IntimacyRecord()`](#intimacyrecord-new) | constructor (`IntimacyRecord`) | A | Create an intimacy record, normalizing the thrust-count unit and generating `id`/`datetime`/`modifiedAt` if omitted. |
| [`resolvedThrustCount`](#resolvedthrustcount) | getter (`IntimacyRecord`) | A | The record's thrust count in actual repetitions, resolving the x1/x100 unit. |
| [`thrustsPerMinute`](#thrustsperminute) | getter (`IntimacyRecord`) | A | The record's average thrusting rate, derived from duration and thrust count. |
| [`toJson`](#intimacyrecord-tojson) | method (`IntimacyRecord`) | A | Serialize an intimacy record to JSON. |
| [`IntimacyRecord.fromJson`](#intimacyrecord-fromjson) | factory constructor (`IntimacyRecord`) | A | Parse an intimacy record from JSON, tolerating legacy fields. |
| [`TimerHistoryEntry()`](#timerhistoryentry-new) | constructor (`TimerHistoryEntry`) | A | Create a timer history entry, clamping thrust count and normalizing its unit. |
| [`toJson`](#timerhistoryentry-tojson) | method (`TimerHistoryEntry`) | A | Serialize a timer history entry to JSON. |
| [`TimerHistoryEntry.fromJson`](#timerhistoryentry-fromjson) | factory constructor (`TimerHistoryEntry`) | A | Parse a timer history entry from JSON, migrating the legacy `end`-timestamp format. |
| [`IntimacyTimerSession()`](#intimacytimersession-new) | constructor (`IntimacyTimerSession`) | A | Create an intimacy timer session snapshot, clamping thrust count and normalizing its unit. |
| [`elapsedAt`](#elapsedat) | method (`IntimacyTimerSession`) | A | Calculate elapsed timer duration at a given wall-clock instant. |
| [`toJson`](#intimacytimersession-tojson) | method (`IntimacyTimerSession`) | A | Serialize a timer session to JSON. |
| [`IntimacyTimerSession.fromJson`](#intimacytimersession-fromjson) | factory constructor (`IntimacyTimerSession`) | A | Parse a timer session from JSON. |
| [`IntimacyChartSettings()`](#intimacychartsettings-new) | constructor (`IntimacyChartSettings`) | A | Create trend-chart view preferences, defaulting the metric selection and range. |
| [`toJson`](#intimacychartsettings-tojson) | method (`IntimacyChartSettings`) | A | Serialize the chart view preferences to JSON. |
| [`IntimacyChartSettings.fromJson`](#intimacychartsettings-fromjson) | factory constructor (`IntimacyChartSettings`) | A | Parse chart view preferences from JSON, tolerating null and empty values. |
| [`copyWith`](#intimacychartsettings-copywith) | method (`IntimacyChartSettings`) | A | Return a copy of the chart view preferences with selected fields replaced. |
| [`IntimacyData()`](#intimacydata-new) | constructor (`IntimacyData`) | A | Create the top-level intimacy data container, defaulting the three independent LWW timestamps. |
| [`toJson`](#intimacydata-tojson) | method (`IntimacyData`) | A | Serialize the entire intimacy data tree to JSON. |
| [`IntimacyData.fromJson`](#intimacydata-fromjson) | factory constructor (`IntimacyData`) | A | Parse the entire intimacy data tree from JSON. |

**Reconciliation:** `grep -c 'Purpose:' lib/features/intimacy/models/intimacy_record.dart` reports
43, matching all 43 rows above exactly — every `/// Purpose:` block sits directly above the real
declaration it documents (no misattached blocks were found), and no undocumented real declaration
exists anywhere in the file. v1.3.2 added six: the two derived thrust getters and the four
`IntimacyChartSettings` members. All 43 are classified Tier A: every one is a model
constructor/`toJson`/
`fromJson`/`copyWith` (the tiering rule's explicit Tier A bucket) or a getter/method carrying real
logic used elsewhere (`isEmpty`, `day`, `formatDate`, the four `Toy` cost helpers, `elapsedAt`,
`resolvedThrustCount`, `thrustsPerMinute`), the
same standard applied to `finance/models/finance.md`'s `firstBillingDate` getter. Each class's plain
data fields (e.g. `BodyProfile.bustCm`, `Partner.name`, `IntimacyRecord.pleasureLevel`) are not
counted as separate declarations, consistent with how every other model page in this doc set treats
constructor-backing fields.

## Documentation

### `const BodyProfile({double? bustCm, double? waistCm, double? hipCm, double? underbustCm, String? braStandard, bool cycleEnabled = false, bool showCycleOnCalendar = false, double? erectLengthCm, double? baseCircumferenceCm, double? frontCircumferenceCm})` <a id="bodyprofile-new"></a>
- **Kind:** const constructor of `BodyProfile`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 24)
- **Purpose:** Create a gender-neutral, all-optional body profile: bust/waist/hip/underbust
  measurements, a bra-standard code, the two cycle-display flags (both default off), and the three
  PSI reference measurements.
- **Inputs:** Every field optional except the two `bool` flags, which default `false`.
- **Returns:** A new `BodyProfile`.
- **Side effects:** None.
- **Algorithm:** Plain `const` field-assigning constructor; no generated `id`/`modifiedAt` (unlike
  most other models here) because a `BodyProfile` is embedded inline, not tracked independently — its
  owner (`Partner.modifiedAt` or `IntimacyData.userBodyModifiedAt`) carries the LWW timestamp.
- **Usage:**
  ```dart
  BodyProfile get _profile => widget.profile ?? const BodyProfile();
  ```
  (`lib/features/intimacy/widgets/body_section.dart:101`, the default empty profile used when no
  profile has been set yet.)
- **Notes:** The user's own bust/waist/hip deliberately stay `null` here — they live in the Weight
  module instead (`WeightData.effectiveMeasurementsUpTo`), per
  [Intimacy](../../../../features/intimacy.md#the-body-layer-v124).

### `bool get isEmpty` <a id="isempty"></a>
- **Kind:** getter of `BodyProfile`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 42)
- **Purpose:** Report whether this profile carries no data at all (every field at its default/null).
- **Inputs:** None.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** A single `&&` chain checking all 10 fields are `null`/`false`.
- **Usage:**
  ```dart
  if (body != null && !body!.isEmpty) 'body': body!.toJson(),
  ```
  (this file, `Partner.toJson`, line 247 — an empty profile is omitted from JSON entirely rather than
  serialized as `{}`.) Also used in
  `lib/features/intimacy/views/intimacy_page.dart:5577`: `body: profile.isEmpty ? null : profile,
  clearBody: profile.isEmpty`.
- **Notes:** Empty profiles are stored as absent/`null` (not `{}`) so an untouched profile never
  perturbs sync merges.

### `Map<String, dynamic> toJson()` <a id="bodyprofile-tojson"></a>
- **Kind:** method of `BodyProfile`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 59)
- **Purpose:** Serialize a body profile into the JSON nested under a partner's `body` key or
  `IntimacyData`'s `userBody` key.
- **Inputs:** None.
- **Returns:** A map with every field guarded by `if (field != null)` (or `if (flag)` for the two
  booleans) — an empty profile serializes to `{}`.
- **Side effects:** None.
- **Algorithm:** Map literal, one `if`-guarded entry per field.
- **Usage:** Called from `Partner.toJson` (line 247: `'body': body!.toJson()`) and from
  `IntimacyData.toJson` (line 866: `'userBody': userBody!.toJson()`), both only when `!isEmpty`.
- **Notes:** Callers are responsible for the `isEmpty` check — `toJson()` itself will still produce
  `{}` for an empty profile if called directly.

### `factory BodyProfile.fromJson(Map<String, dynamic> json)` <a id="bodyprofile-fromjson"></a>
- **Kind:** factory constructor of `BodyProfile`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 79)
- **Purpose:** Parse a body profile back out of its persisted/synced JSON form.
- **Inputs:** `json` — decoded map.
- **Returns:** A new `BodyProfile`.
- **Side effects:** None.
- **Algorithm:** Every numeric field cast via `(json[k] as num?)?.toDouble()`; the two booleans read
  as `json[k] == true` (so a missing/non-`true` value defaults `false`); `braStandard` cast directly
  as `String?`.
- **Usage:** Called from `Partner.fromJson` (line 268: `BodyProfile.fromJson(json['body'] as
  Map<String, dynamic>)`) and `IntimacyData.fromJson` (line 922, for `userBody`), both guarded by
  `json['body'] is Map<String, dynamic>`.
- **Notes:** None beyond what's covered above — every field degrades independently, so a partially
  malformed profile never fails the whole parse.

### `BodyProfile copyWith({double? bustCm, bool clearBustCm = false, double? waistCm, bool clearWaistCm = false, double? hipCm, bool clearHipCm = false, double? underbustCm, bool clearUnderbustCm = false, String? braStandard, bool clearBraStandard = false, bool? cycleEnabled, bool? showCycleOnCalendar, double? erectLengthCm, bool clearErectLengthCm = false, double? baseCircumferenceCm, bool clearBaseCircumferenceCm = false, double? frontCircumferenceCm, bool clearFrontCircumferenceCm = false})` <a id="bodyprofile-copywith"></a>
- **Kind:** method of `BodyProfile`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 97)
- **Purpose:** Return a copy of this profile with selected fields replaced, using a separate `clearX`
  flag per nullable field so a field can be explicitly cleared (as opposed to left unchanged).
- **Inputs:** One optional replacement value plus one optional `clearX` boolean per nullable field;
  `cycleEnabled`/`showCycleOnCalendar` are plain nullable overrides (no clear flag needed since they
  are non-nullable `bool`s with a default).
- **Returns:** A new `BodyProfile`.
- **Side effects:** None.
- **Algorithm:** Per nullable field: `clearX ? null : (x ?? this.x)` — the clear flag takes priority
  over a replacement value. The two booleans use plain `?? this.field`.
- **Usage:**
  ```dart
  _updateProfile(_profile.copyWith(cycleEnabled: v)),
  ```
  (`lib/features/intimacy/widgets/body_section.dart:769`, the cycle-tracking toggle switch.)
- **Notes:** Unlike `Partner.copyWith`, this method does not stamp any timestamp of its own —
  `BodyProfile` has no `modifiedAt`; the owning `Partner` or `IntimacyData.userBodyModifiedAt` is
  responsible for that.

### `CycleRecord({String? id, String? personId, required String date, DateTime? modifiedAt})` <a id="cyclerecord-new"></a>
- **Kind:** constructor of `CycleRecord`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 152)
- **Purpose:** Create a cycle record for one recorded menstrual period start date, for the user
  (`personId: null`) or a specific partner.
- **Inputs:** `date` required, a `yyyy-MM-dd` local calendar-date string; `personId` optional (`null`
  = the user); `id`/`modifiedAt` generated if omitted.
- **Returns:** A new `CycleRecord`.
- **Side effects:** None.
- **Algorithm:** `id = id ?? const Uuid().v4()`, `modifiedAt = modifiedAt ?? DateTime.now().toUtc()`.
- **Usage:**
  ```dart
  widget.onCycleRecordsChanged([
    ...widget.cycleRecords,
    CycleRecord(
      personId: widget.personId,
      date: CycleRecord.formatDate(date),
    ),
  ]);
  ```
  (`lib/features/intimacy/widgets/body_section.dart:379-385`, `_addCycleStart`.)
- **Notes:** Records are add/delete only; there is no edit flow — changing a period start means
  deleting the old record and adding a new one. See
  [Three-Way Merge](../../../../algorithms/three-way-merge.md#deletionunion-semantics) for how
  deletions still sync correctly despite this being a simple per-id merge.

### `DateTime get day` <a id="day"></a>
- **Kind:** getter of `CycleRecord`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 165)
- **Purpose:** Return the record's calendar day as a date-only local `DateTime`.
- **Inputs:** None.
- **Returns:** `DateTime`, always local midnight.
- **Side effects:** None.
- **Algorithm:** `DateTime.parse(date)` then rebuilt as `DateTime(parsed.year, parsed.month,
  parsed.day)` to strip any time component.
- **Usage:**
  ```dart
  actualStarts: _cycleRecords
      .where((c) => c.personId == personId)
      .map((c) => c.day),
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:314-316`, feeding
  [`predictCycle`](../services/cycle_predictor.md#predictcycle).)
- **Notes:** The time component is always midnight local time, matching every other date-only value
  `cycle_predictor.dart` works with (see [`dateOnly`](../services/cycle_predictor.md#dateonly)).

### `static String formatDate(DateTime day)` <a id="formatdate"></a>
- **Kind:** static method of `CycleRecord`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 175)
- **Purpose:** Format a calendar date as the stored `yyyy-MM-dd` string.
- **Inputs:** `day`.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** Zero-pads `month`/`day` to 2 digits and joins as `'${day.year}-$month-$dayOfMonth'`.
- **Usage:**
  ```dart
  date: CycleRecord.formatDate(date),
  ```
  (`lib/features/intimacy/widgets/body_section.dart:383`, when adding a cycle start; also line 399
  when checking whether a record for that day already exists.)
- **Notes:** Ignores any time component on the input, the inverse of [`day`](#day).

### `Map<String, dynamic> toJson()` <a id="cyclerecord-tojson"></a>
- **Kind:** method of `CycleRecord`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 186)
- **Purpose:** Serialize a cycle record into the JSON stored in `intimacy_data.json`'s `cycleRecords`
  array.
- **Inputs:** None.
- **Returns:** `{id, personId?, date, modifiedAt}`.
- **Side effects:** None.
- **Algorithm:** Map literal; `personId` omitted when `null` (the user's own records).
- **Usage:** Called from `IntimacyData.toJson` (line 870): `cycleRecords.map((c) =>
  c.toJson()).toList()`, only when `cycleRecords.isNotEmpty`.
- **Notes:** None.

### `factory CycleRecord.fromJson(Map<String, dynamic> json)` <a id="cyclerecord-fromjson"></a>
- **Kind:** factory constructor of `CycleRecord`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 198)
- **Purpose:** Parse a cycle record back out of its persisted/synced JSON form.
- **Inputs:** `json` — decoded map.
- **Returns:** A new `CycleRecord`.
- **Side effects:** None.
- **Algorithm:** Cast `id`/`date` as required `String`s; `personId` nullable; `modifiedAt` falls back
  to the Unix epoch when absent.
- **Usage:** Called from `IntimacyData.fromJson` (line 929):
  `(json['cycleRecords'] as List<dynamic>?)?.map((c) => CycleRecord.fromJson(c as Map<String,
  dynamic>))`.
- **Notes:** None.

### `Partner({String? id, required String name, String? emoji, String? imagePath, DateTime? startDate, DateTime? endDate, BodyProfile? body, DateTime? modifiedAt})` <a id="partner-new"></a>
- **Kind:** constructor of `Partner`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 223)
- **Purpose:** Create a partner record: name, optional emoji/image, relationship start/end dates, and
  an optional embedded `BodyProfile`.
- **Inputs:** `name` required; every other field optional; `id`/`modifiedAt` generated if omitted.
- **Returns:** A new `Partner`.
- **Side effects:** None.
- **Algorithm:** Field-assigning constructor; `id = id ?? const Uuid().v4()`, `modifiedAt = modifiedAt
  ?? DateTime.now().toUtc()`.
- **Usage:**
  ```dart
  _partners.add(
    Partner(
      id: p.id,
      name: p.name,
      emoji: p.emoji,
      imagePath: p.imagePath,
      startDate: p.startDate,
      endDate: now,
      body: p.body?.copyWith(showCycleOnCalendar: false),
    ),
  );
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:2807-2815`, `_breakUpPartner` — reconstructing the
  partner with an `endDate` set and cycle-calendar visibility turned off.)
- **Notes:** The `BodyProfile` travels atomically with the partner record in sync — body edits go
  through [`Partner.copyWith`](#partner-copywith), which bumps the partner's own `modifiedAt`, per
  [Intimacy](../../../../features/intimacy.md#models).

### `Map<String, dynamic> toJson()` <a id="partner-tojson"></a>
- **Kind:** method of `Partner`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 240)
- **Purpose:** Serialize a partner (and its optional non-empty `BodyProfile`) into the JSON stored in
  `intimacy_data.json`'s `partners` array.
- **Inputs:** None.
- **Returns:** A map with `id`/`name`/`modifiedAt` always present; `emoji`/`imagePath`/`startDate`/
  `endDate`/`body` included only when set (`body` only when non-null **and** `!body!.isEmpty`).
- **Side effects:** None.
- **Algorithm:** Map literal with `if` guards per optional field; nested `body!.toJson()` when
  present.
- **Usage:** Called from `IntimacyData.toJson` (line 859): `partners.map((p) => p.toJson()).toList()`.
- **Notes:** An empty (all-null) body profile is never nested in the output, matching
  [`BodyProfile.isEmpty`](#isempty)'s "stored as absent" rule.

### `factory Partner.fromJson(Map<String, dynamic> json)` <a id="partner-fromjson"></a>
- **Kind:** factory constructor of `Partner`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 256)
- **Purpose:** Parse a partner back out of its persisted/synced JSON form.
- **Inputs:** `json` — decoded map.
- **Returns:** A new `Partner`.
- **Side effects:** None.
- **Algorithm:** Cast `id`/`name` required; `emoji`/`imagePath` nullable strings; `startDate`/
  `endDate` parsed via `DateTime.parse` when present; `body` parsed via
  [`BodyProfile.fromJson`](#bodyprofile-fromjson) when `json['body'] is Map<String, dynamic>`;
  `modifiedAt` falls back to the Unix epoch when absent.
- **Usage:** Called from `IntimacyData.fromJson` (line 890):
  `(json['partners'] as List<dynamic>?)?.map((p) => Partner.fromJson(p as Map<String, dynamic>))`.
- **Notes:** None.

### `Partner copyWith({String? name, String? emoji, bool clearEmoji = false, String? imagePath, bool clearImagePath = false, DateTime? startDate, bool clearStartDate = false, DateTime? endDate, bool clearEndDate = false, BodyProfile? body, bool clearBody = false})` <a id="partner-copywith"></a>
- **Kind:** method of `Partner`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 280)
- **Purpose:** Return a copy of this partner with selected fields replaced or cleared, always
  stamping a fresh `modifiedAt` so the edit wins later LWW merges.
- **Inputs:** Optional replacement value plus `clearX` flag per nullable field (`id` is never
  changeable — always carried over from `this.id`).
- **Returns:** A new `Partner`.
- **Side effects:** None.
- **Algorithm:** Per nullable field: `clearX ? null : (x ?? this.x)`; `modifiedAt` is unconditionally
  set to `DateTime.now().toUtc()` (unlike `BodyProfile.copyWith`, which stamps nothing).
- **Usage:**
  ```dart
  final updated = partner.copyWith(
    body: profile.isEmpty ? null : profile,
    clearBody: profile.isEmpty,
  );
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:5576-5579`, the partner-mode Body tab's
  `onProfileChanged` callback.)
- **Notes:** Always bumping `modifiedAt` — even for a body-only edit — is what makes the body profile
  travel atomically with the partner record through sync, per
  [Intimacy](../../../../features/intimacy.md#models).

### `Toy({String? id, required String name, String? emoji, String? imagePath, DateTime? purchaseDate, DateTime? retiredDate, String? purchaseLink, double? price, DateTime? modifiedAt})` <a id="toy-new"></a>
- **Kind:** constructor of `Toy`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 320)
- **Purpose:** Create a toy record: name, optional emoji/image, purchase/retirement dates, purchase
  link, and price.
- **Inputs:** `name` required; every other field optional; `id`/`modifiedAt` generated if omitted.
- **Returns:** A new `Toy`.
- **Side effects:** None.
- **Algorithm:** Field-assigning constructor; `id`/`modifiedAt` default the same way as `Partner`.
- **Usage:**
  ```dart
  _toys.add(
    Toy(
      id: t.id,
      name: t.name,
      emoji: t.emoji,
      imagePath: t.imagePath,
      purchaseDate: t.purchaseDate,
      retiredDate: now,
      purchaseLink: t.purchaseLink,
      price: t.price,
    ),
  );
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:3842-3851`, `_retireToy`.)
- **Notes:** None.

### `bool get hasCostData` <a id="hascostdata"></a>
- **Kind:** getter of `Toy`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 338)
- **Purpose:** Report whether this toy has cost data (a recorded price) to summarize.
- **Inputs:** None.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** `price != null`.
- **Usage:**
  ```dart
  value: toy.hasCostData ? _formatMoney(toy.totalCost()) : '-',
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:5274`, the toy cost-summary card.)
- **Notes:** A zero price is still treated as explicit cost data (only `null` counts as "no cost
  data").

### `int? serviceDays({DateTime? asOf})` <a id="servicedays"></a>
- **Kind:** method of `Toy`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 345)
- **Purpose:** Calculate the toy's service days (purchase date through retirement or `asOf`) used to
  average its cost.
- **Inputs:** `asOf` — optional reference date, defaults to `DateTime.now()`.
- **Returns:** `int?` — `null` if `purchaseDate` is unset; otherwise at least `1`.
- **Side effects:** None.
- **Algorithm:**
  1. Return `null` if `purchaseDate == null`.
  2. `end = asOf ?? DateTime.now()`; if `retiredDate` is set and before `end`, use `retiredDate`
     instead (a retired toy's service period stops at retirement, not at `asOf`).
  3. `days = end.difference(purchaseDate!).inDays + 1`, clamped to a minimum of `1`.
- **Usage:** Called internally by [`averageDailyCost`](#averagedailycost) (line 370): `final days =
  serviceDays(asOf: asOf);`.
- **Notes:** The `+ 1` and minimum-of-`1` clamp mean a toy purchased and retired the same day still
  counts as one full day of service, never a division by zero.

### `double totalCost({DateTime? asOf})` <a id="totalcost"></a>
- **Kind:** method of `Toy`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 361)
- **Purpose:** Return the toy's total recorded cost.
- **Inputs:** `asOf` — accepted for API symmetry with `averageDailyCost`/`serviceDays` but unused.
- **Returns:** `double` — `price ?? 0`.
- **Side effects:** None.
- **Algorithm:** `price ?? 0`.
- **Usage:**
  ```dart
  toys.fold(0.0, (sum, toy) => sum + toy.totalCost());
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:3650`, the aggregate toy-cost overview.)
- **Notes:** The current model only has a one-time purchase cost, so `asOf` is presently ignored;
  it exists so a future recurring-cost model could add real logic without changing the call sites.

### `double? averageDailyCost({DateTime? asOf})` <a id="averagedailycost"></a>
- **Kind:** method of `Toy`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 368)
- **Purpose:** Calculate the toy's average daily cost.
- **Inputs:** `asOf` — optional reference date, forwarded to `serviceDays`/`totalCost`.
- **Returns:** `double?` — `null` until both `price` and `purchaseDate` are available.
- **Side effects:** None.
- **Algorithm:** Return `null` if `!hasCostData`; return `null` if `serviceDays(asOf: asOf)` is
  `null`; otherwise `totalCost(asOf: asOf) / days`.
- **Usage:**
  ```dart
  final dailyCost = toy.averageDailyCost();
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:3661`, the active/all daily-cost trend chart; also
  used per-toy at lines 4225, 5279-5281, 6134, 6376 for detail-page/summary displays.)
- **Notes:** None.

### `Map<String, dynamic> toJson()` <a id="toy-tojson"></a>
- **Kind:** method of `Toy`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 380)
- **Purpose:** Serialize a toy into the JSON stored in `intimacy_data.json`'s `toys` array.
- **Inputs:** None.
- **Returns:** A map with `id`/`name`/`modifiedAt` always present; every other field only when
  non-null.
- **Side effects:** None.
- **Algorithm:** Map literal with `if (field != null)` guards; dates as `toIso8601String()`.
- **Usage:** Called from `IntimacyData.toJson` (line 860): `toys.map((t) => t.toJson()).toList()`.
- **Notes:** None.

### `factory Toy.fromJson(Map<String, dynamic> json)` <a id="toy-fromjson"></a>
- **Kind:** factory constructor of `Toy`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 397)
- **Purpose:** Parse a toy back out of its persisted/synced JSON form.
- **Inputs:** `json` — decoded map.
- **Returns:** A new `Toy`.
- **Side effects:** None.
- **Algorithm:** Cast `id`/`name` required; every optional field null-safe; `price` via `(json['price']
  as num?)?.toDouble()`; `modifiedAt` falls back to the Unix epoch when absent.
- **Usage:** Called from `IntimacyData.fromJson` (line 895): `(json['toys'] as
  List<dynamic>?)?.map((t) => Toy.fromJson(t as Map<String, dynamic>))`.
- **Notes:** None.

### `Position({String? id, required String name, String? emoji, DateTime? modifiedAt})` <a id="position-new"></a>
- **Kind:** constructor of `Position`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 427)
- **Purpose:** Create a position record: name and optional emoji.
- **Inputs:** `name` required; `emoji` optional; `id`/`modifiedAt` generated if omitted.
- **Returns:** A new `Position`.
- **Side effects:** None.
- **Algorithm:** Field-assigning constructor; `id`/`modifiedAt` default the same way as `Partner`.
- **Usage:**
  ```dart
  _positions.add(
    Position(name: nameCtrl.text.trim(), emoji: selectedEmoji),
  );
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:4893-4895`, adding a new position; editing an
  existing one at line 4886-4890 passes the existing `id` through instead.)
- **Notes:** None.

### `Map<String, dynamic> toJson()` <a id="position-tojson"></a>
- **Kind:** method of `Position`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 436)
- **Purpose:** Serialize a position into the JSON stored in `intimacy_data.json`'s `positions` array.
- **Inputs:** None.
- **Returns:** `{id, name, emoji?, modifiedAt}`.
- **Side effects:** None.
- **Algorithm:** Map literal; `emoji` omitted when `null`.
- **Usage:** Called from `IntimacyData.toJson` (line 861): `positions.map((p) =>
  p.toJson()).toList()`.
- **Notes:** None.

### `factory Position.fromJson(Map<String, dynamic> json)` <a id="position-fromjson"></a>
- **Kind:** factory constructor of `Position`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 448)
- **Purpose:** Parse a position back out of its persisted/synced JSON form.
- **Inputs:** `json` — decoded map.
- **Returns:** A new `Position`.
- **Side effects:** None.
- **Algorithm:** Cast `id`/`name` required; `emoji` nullable; `modifiedAt` falls back to the Unix
  epoch when absent.
- **Usage:** Called from `IntimacyData.fromJson` (line 900): `(json['positions'] as
  List<dynamic>?)?.map((p) => Position.fromJson(p as Map<String, dynamic>))`.
- **Notes:** None.

### `IntimacyRecord({String? id, required String type, String? location, bool isSolo = false, String? partnerId, List<String> toyIds = const [], List<String> positionIds = const [], required int pleasureLevel, required Duration duration, int? thrustCount, int? thrustCountUnit, DateTime? datetime, String? notes, bool hadOrgasm = false, bool watchedPorn = false, bool usedCondom = false, DateTime? modifiedAt})` <a id="intimacyrecord-new"></a>
- **Kind:** constructor of `IntimacyRecord`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 482)
- **Purpose:** Create an intimacy activity record: solo/partnered type, location, partner/toy/
  position links, pleasure level, duration, optional thrust count, and orgasm/porn/condom flags.
- **Inputs:** `type`, `pleasureLevel`, `duration` required; `isSolo` defaults `false`; `toyIds`/
  `positionIds` default to empty lists; `thrustCountUnit` normalized (see Algorithm); `id`/`datetime`/
  `modifiedAt` generated if omitted.
- **Returns:** A new `IntimacyRecord`.
- **Side effects:** None.
- **Algorithm:** Field-assigning constructor; `id = id ?? const Uuid().v4()`, `thrustCountUnit =
  thrustCountUnit == 1 ? 1 : 100` (always normalized to exactly `1` or `100`), `datetime = datetime ??
  DateTime.now()` (local time, unlike `modifiedAt`), `modifiedAt = modifiedAt ??
  DateTime.now().toUtc()`.
- **Usage:**
  ```dart
  final record = IntimacyRecord(
    id: widget.record?.id,
    type: _isSolo ? 'Solo' : 'Regular',
    partnerId: _isSolo ? null : _selectedPartnerId,
    isSolo: _isSolo,
    pleasureLevel: _pleasureLevel,
    duration: Duration(minutes: totalMinutes),
    thrustCount: normalizedThrustCount,
    thrustCountUnit: _thrustCountUnit,
    datetime: _datetime,
    toyIds: _selectedToyIds.toList(),
    positionIds: _selectedPositionIds.toList(),
    hadOrgasm: _hadOrgasm,
    watchedPorn: _watchedPorn,
    usedCondom: _usedCondom,
    // ...
  );
  ```
  (`lib/features/intimacy/widgets/add_record_dialog.dart:520-538`, the add/edit record dialog's
  submit handler.)
- **Notes:** `thrustCountUnit` normalization means any other stored/passed value (e.g. corrupted data)
  is silently coerced to `100`, matching the `x100`/`x1` estimate-vs-exact convention described in
  [Intimacy](../../../../features/intimacy.md#timerstopwatch-session-persistence). This model has no
  `copyWith` — edits go through the dialog reconstructing a full `IntimacyRecord`.

### `double? get resolvedThrustCount` <a id="resolvedthrustcount"></a>
- **Kind:** getter of `IntimacyRecord`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 510)
- **Purpose:** Return this record's thrust count in actual repetitions.
- **Inputs:** None.
- **Returns:** `double?` — null when no usable thrust count was recorded.
- **Side effects:** None.
- **Algorithm:** Return null when `thrustCount` is null or non-positive; otherwise multiply it by
  `thrustCountUnit` (always exactly `1` or `100`).
- **Usage:** The numerator of [`thrustsPerMinute`](#thrustsperminute), and the value extractor for
  the trend chart's `thrustCount` metric
  ([`intimacy_trend_chart.dart`](../widgets/intimacy_trend_chart.md#metricspecs)).
- **Notes:** Derived, never persisted. Promoted onto the model in v1.3.2 from a private helper in
  `intimacy_page.dart` so the x1/x100 arithmetic is unit-testable and reusable.

### `double? get thrustsPerMinute` <a id="thrustsperminute"></a>
- **Kind:** getter of `IntimacyRecord`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 523)
- **Purpose:** Return this record's average thrusting rate in thrusts per minute.
- **Inputs:** None.
- **Returns:** `double?` — null unless the record has **both** a positive duration and a usable
  thrust count.
- **Side effects:** None.
- **Algorithm:** Divide [`resolvedThrustCount`](#resolvedthrustcount) by the duration expressed in
  minutes (`duration.inSeconds / 60`), returning null if either input is missing or the duration is
  zero.
- **Usage:** The `thrustRate` metric on the consolidated trend chart, and the "Avg thrust rate"
  tile on the partner/toy detail summary card
  (`_FilteredRecordsPageState._buildSummaryCard`).
- **Notes:** Derived, never persisted. Durations are stored in seconds while the entry dialog only
  accepts whole minutes, so timer-derived sub-minute entries can produce large rates — that is
  arithmetic, not a bug. The zero-duration guard is what keeps the division safe.

### `Map<String, dynamic> toJson()` <a id="intimacyrecord-tojson"></a>
- **Kind:** method of `IntimacyRecord`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 510)
- **Purpose:** Serialize an intimacy record into the JSON stored in `intimacy_data.json`'s `records`
  array.
- **Inputs:** None.
- **Returns:** A map with `id`/`type`/`isSolo`/`pleasureLevel`/`duration`/`datetime`/`hadOrgasm`/
  `watchedPorn`/`usedCondom`/`modifiedAt` always present; `location`/`partnerId`/`toyIds`/
  `positionIds`/`thrustCount`(+`thrustCountUnit`)/`notes` only when set/non-empty.
- **Side effects:** None.
- **Algorithm:** Map literal with `if` guards; `duration` as `.inSeconds`; `thrustCountUnit` only
  written alongside a non-null `thrustCount`.
- **Usage:** Called from `IntimacyData.toJson` (line 862): `records.map((r) =>
  r.toJson()).toList()`.
- **Notes:** None.

### `factory IntimacyRecord.fromJson(Map<String, dynamic> json)` <a id="intimacyrecord-fromjson"></a>
- **Kind:** factory constructor of `IntimacyRecord`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 535)
- **Purpose:** Parse an intimacy record back out of its persisted/synced JSON form, tolerating an
  old schema.
- **Inputs:** `json` — decoded map.
- **Returns:** A new `IntimacyRecord`.
- **Side effects:** None.
- **Algorithm:** Cast required fields (`type`, `pleasureLevel`, `datetime` via `DateTime.parse`);
  `duration` from `Duration(seconds: json['duration'] as int)`; `thrustCountUnit` re-normalized to `1`
  or `100`; `isSolo` defaults `false` if absent (comment notes old records instead had a `'partner'`
  string field, no longer read); `modifiedAt` falls back to the Unix epoch when absent.
- **Usage:** Called from `IntimacyData.fromJson` (line 905): `(json['records'] as
  List<dynamic>?)?.map((r) => IntimacyRecord.fromJson(r as Map<String, dynamic>))`.
- **Notes:** A record whose `partnerId` no longer matches any existing partner (the partner was
  deleted) still parses fine — deleted-partner references are tolerated by design, per
  [Intimacy](../../../../features/intimacy.md#deleted-partner-handling).

### `TimerHistoryEntry({required DateTime start, required Duration duration, int thrustCount = 0, int? thrustCountUnit})` <a id="timerhistoryentry-new"></a>
- **Kind:** constructor of `TimerHistoryEntry`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 582)
- **Purpose:** Create a single timer history entry (independent of any `IntimacyRecord`): start time,
  duration, and optional thrust count.
- **Inputs:** `start`, `duration` required; `thrustCount` defaults `0`; `thrustCountUnit` normalized.
- **Returns:** A new `TimerHistoryEntry`.
- **Side effects:** None.
- **Algorithm:** `thrustCount = thrustCount < 0 ? 0 : thrustCount` (clamped non-negative);
  `thrustCountUnit = thrustCountUnit == 1 ? 1 : 100`.
- **Usage:**
  ```dart
  final entry = TimerHistoryEntry(
    start: sessionStart,
    duration: elapsed,
    thrustCount: _storedThrustCount,
    thrustCountUnit: _storedThrustCountUnit,
  );
  ```
  (`lib/features/intimacy/widgets/timer_page.dart:458-463`, stopping/saving the stopwatch.)
- **Notes:** Also constructed by [`TimerHistoryEntry.fromJson`](#timerhistoryentry-fromjson)'s legacy
  `end`-timestamp migration path.

### `Map<String, dynamic> toJson()` <a id="timerhistoryentry-tojson"></a>
- **Kind:** method of `TimerHistoryEntry`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 595)
- **Purpose:** Serialize a timer history entry into the JSON stored in `intimacy_data.json`'s
  `timerHistory` array.
- **Inputs:** None.
- **Returns:** `{start, durationMs, thrustCount?, thrustCountUnit?}` — the thrust fields are omitted
  entirely when `thrustCount` is `0`.
- **Side effects:** None.
- **Algorithm:** Map literal; `duration` as `.inMilliseconds` under the `durationMs` key (not
  `duration`, to distinguish from the legacy `end`-based format).
- **Usage:** Called from `IntimacyData.toJson` (line 863): `timerHistory.map((e) =>
  e.toJson()).toList()`.
- **Notes:** None.

### `factory TimerHistoryEntry.fromJson(Map<String, dynamic> json)` <a id="timerhistoryentry-fromjson"></a>
- **Kind:** factory constructor of `TimerHistoryEntry`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 607)
- **Purpose:** Parse a timer history entry from JSON, migrating older entries that stored an `end`
  timestamp instead of a duration.
- **Inputs:** `json` — decoded map.
- **Returns:** A new `TimerHistoryEntry`.
- **Side effects:** None.
- **Algorithm:**
  1. Read `thrustCount` (default `0`, re-clamped non-negative) and `thrustCountUnit` (normalized to
     `1`/`100`).
  2. If `json` contains `durationMs`, build directly from `start`/`Duration(milliseconds:
     durationMs)`.
  3. Otherwise (legacy format), parse both `start` and `end`, and compute `duration:
     end.difference(start)`.
- **Usage:**
  ```dart
  final legacyEntries = list
      .map((e) => TimerHistoryEntry.fromJson(e as Map<String, dynamic>))
      .toList();
  ```
  (`lib/features/intimacy/services/intimacy_storage.dart:117`, parsing the standalone legacy
  `timer_history.json` file during
  [`_migrateLegacyTimerHistory`](../services/intimacy_storage.md#_migratelegacytimerhistory).) Also
  called from `IntimacyData.fromJson` (line 910) for the normal `timerHistory` array.
- **Notes:** The legacy `end`-based branch is what lets `IntimacyStorage` migrate a pre-duration
  `timer_history.json` file transparently, without a separate migration code path for the entry
  format itself.

### `IntimacyTimerSession({required DateTime firstStartedAt, DateTime? startedAt, required Duration accumulated, required bool running, int thrustCount = 0, int? thrustCountUnit})` <a id="intimacytimersession-new"></a>
- **Kind:** constructor of `IntimacyTimerSession`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 644)
- **Purpose:** Create a persisted active/paused stopwatch session snapshot: original start time, last
  resume time, accumulated elapsed time, running flag, and optional thrust count.
- **Inputs:** `firstStartedAt`, `accumulated`, `running` required; `startedAt` optional (the most
  recent resume time, `null` when paused); `thrustCount` defaults `0`; `thrustCountUnit` normalized.
- **Returns:** A new `IntimacyTimerSession`.
- **Side effects:** None.
- **Algorithm:** `thrustCount` clamped non-negative; `thrustCountUnit` normalized to `1`/`100`, same
  as `TimerHistoryEntry`.
- **Usage:**
  ```dart
  return IntimacyTimerSession(
    firstStartedAt: firstStartedAt,
    startedAt: _running ? _startedAt : null,
    accumulated: _accumulated,
    running: _running,
    thrustCount: _storedThrustCount,
    thrustCountUnit: _storedThrustCountUnit,
  );
  ```
  (`lib/features/intimacy/widgets/timer_page.dart:380-387`, the `_timerSession` getter that snapshots
  the live timer for persistence.)
- **Notes:** `accumulated` stores elapsed time before the latest running segment — see
  [`elapsedAt`](#elapsedat) for how the two combine.

### `Duration elapsedAt(DateTime now)` <a id="elapsedat"></a>
- **Kind:** method of `IntimacyTimerSession`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 659)
- **Purpose:** Calculate elapsed timer duration at a given wall-clock instant.
- **Inputs:** `now`.
- **Returns:** `Duration`.
- **Side effects:** None.
- **Algorithm:** If not `running` or `startedAt == null`, return `accumulated` unchanged; otherwise
  return `accumulated + now.difference(startedAt!)`.
- **Usage:** Not currently called from any other file in this repo (only `toJson`/`fromJson` and the
  timer widget's own separately-maintained `_accumulated`/`_startedAt` fields are exercised today);
  the intended call shape, per
  [Intimacy](../../../../features/intimacy.md#timerstopwatch-session-persistence), is
  `session.elapsedAt(DateTime.now())` to recompute live elapsed time from a restored session.
- **Notes:** This is what lets a running session resume from real wall-clock time after an app
  restart, rather than a stale in-memory counter — `accumulated + (now - startedAt)` while running.

### `Map<String, dynamic> toJson()` <a id="intimacytimersession-tojson"></a>
- **Kind:** method of `IntimacyTimerSession`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 669)
- **Purpose:** Serialize a timer session into the JSON stored in `intimacy_data.json`'s
  `timerSession` key.
- **Inputs:** None.
- **Returns:** `{firstStartedAt, startedAt?, accumulatedMs, running, thrustCount?, thrustCountUnit?}`
  — `startedAt` and the thrust fields omitted when absent/zero.
- **Side effects:** None.
- **Algorithm:** Map literal; `accumulated` as `.inMilliseconds` under `accumulatedMs`.
- **Usage:** Called from `IntimacyData.toJson` (line 864): `timerSession!.toJson()`, only when
  `timerSession != null`.
- **Notes:** None.

### `factory IntimacyTimerSession.fromJson(Map<String, dynamic> json)` <a id="intimacytimersession-fromjson"></a>
- **Kind:** factory constructor of `IntimacyTimerSession`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 683)
- **Purpose:** Parse a timer session back out of its persisted JSON form, restoring an interrupted
  active/paused stopwatch.
- **Inputs:** `json` — decoded map.
- **Returns:** A new `IntimacyTimerSession`.
- **Side effects:** None.
- **Algorithm:**
  1. Parse `firstStartedAt` (required) and `startedAt` (nullable).
  2. `running = json['running'] as bool? ?? startedAt != null` — infers running from the presence of
     `startedAt` when the `running` key itself is absent (older data).
  3. `startedAt` in the result is `running ? (startedAt ?? firstStartedAt) : null` — a running
     session without its own `startedAt` falls back to `firstStartedAt`.
  4. `thrustCount` re-clamped non-negative; `thrustCountUnit` re-normalized.
- **Usage:** Called from `IntimacyData.fromJson` (line 914-916), guarded by `json['timerSession'] is
  Map<String, dynamic>`.
- **Notes:** Step 2's inference is what lets a session persisted before the explicit `running` key
  existed still restore correctly, per
  [Intimacy](../../../../features/intimacy.md#timerstopwatch-session-persistence)'s recovery rules
  (stopped-but-unsaved and paused sessions restore as paused; running sessions resume live).

### `const IntimacyChartSettings({List<String> metrics = defaultMetrics, String range = defaultRange})` <a id="intimacychartsettings-new"></a>
- **Kind:** constructor of `IntimacyChartSettings`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 752)
- **Purpose:** Create an intimacy chart settings instance.
- **Inputs:** `metrics` and `range`, both defaulting to the built-in selection
  (`['pleasure', 'duration', 'thrustRate']` and `'3m'`).
- **Returns:** A new `IntimacyChartSettings` instance.
- **Side effects:** None.
- **Notes:** Identifiers are **not** validated here, deliberately: unknown values must survive a
  round trip so a newer build's selection is not destroyed by an older one. The chart widget
  filters them at render time instead. `const` so the default can be a compile-time constant.

### `Map<String, dynamic> toJson()` <a id="intimacychartsettings-tojson"></a>
- **Kind:** method of `IntimacyChartSettings`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 762)
- **Purpose:** Serialize this value into a JSON-compatible map.
- **Inputs:** None.
- **Returns:** `{'metrics': [...], 'range': '...'}` — both keys always written.
- **Side effects:** None.
- **Notes:** Unconditional here, but `IntimacyData.toJson` only emits the whole `chartSettings`
  object when it is non-null, which is what kept the WebDAV golden transcripts byte-identical
  across v1.3.2.

### `factory IntimacyChartSettings.fromJson(Map<String, dynamic>? json)` <a id="intimacychartsettings-fromjson"></a>
- **Kind:** factory constructor of `IntimacyChartSettings`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 770)
- **Purpose:** Create an instance from a JSON-compatible map.
- **Inputs:** `json`, which may be null.
- **Returns:** A new `IntimacyChartSettings` instance.
- **Side effects:** None.
- **Algorithm:** Null map yields the default. Otherwise take the `metrics` list filtered to
  strings, falling back to the default when it is missing or empty, and `range` falling back to
  the default when absent.
- **Notes:** Never throws on malformed input, matching `AccountPickerSettings.fromJson` in the
  Finance module. Non-string entries in `metrics` are dropped rather than crashing the load —
  intimacy data is never treated as empty on a parse problem, so tolerance here matters.

### `IntimacyChartSettings copyWith({List<String>? metrics, String? range})` <a id="intimacychartsettings-copywith"></a>
- **Kind:** method of `IntimacyChartSettings`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 786)
- **Purpose:** Return a copy of these settings with selected fields replaced.
- **Inputs:** `metrics`, `range`.
- **Returns:** A new `IntimacyChartSettings` instance.
- **Side effects:** None.
- **Usage:** `IntimacyTrendChart._toggleMetric` and its range chips both build the reported value
  this way.
- **Notes:** None.

### `IntimacyData({required List<Partner> partners, required List<Toy> toys, List<Position> positions = const [], required List<IntimacyRecord> records, List<TimerHistoryEntry> timerHistory = const [], IntimacyTimerSession? timerSession, DateTime? timerSessionModifiedAt, BodyProfile? userBody, DateTime? userBodyModifiedAt, List<CycleRecord> cycleRecords = const [], int? timerHistoryRetentionDays, Map<String, String> partnerSortModes = const {}, Map<String, List<String>> partnerCustomOrders = const {}, Map<String, String> toySortModes = const {}, Map<String, List<String>> toyCustomOrders = const {}, IntimacyChartSettings? chartSettings, DateTime? settingsModifiedAt})` <a id="intimacydata-new"></a>
- **Kind:** constructor of `IntimacyData`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 828)
- **Purpose:** Create the top-level intimacy data container: partners, toys, positions, records,
  timer history/session, the user's own body profile, cycle records, and partner/toy sort settings.
- **Inputs:** `partners`, `toys`, `records` required; everything else optional with empty-collection
  or `null` defaults.
- **Returns:** A new `IntimacyData`.
- **Side effects:** None.
- **Algorithm:** Field-assigning constructor; three independent LWW timestamps each default to the
  Unix epoch in UTC when not supplied (`timerSessionModifiedAt`, `userBodyModifiedAt`) except
  `settingsModifiedAt`, which defaults to `DateTime.now().toUtc()` (the "now" default, unlike the
  other two's epoch-zero "never touched" sentinel).
- **Usage:**
  ```dart
  await IntimacyStorage.save(
    IntimacyData(
      partners: _partners,
      toys: _toys,
      positions: _positions,
      records: _records,
      timerHistory: _timerHistory,
      timerSession: _timerSession,
      timerSessionModifiedAt: _timerSessionModifiedAt,
      userBody: _userBody,
      userBodyModifiedAt: _userBodyModifiedAt,
      cycleRecords: _cycleRecords,
      timerHistoryRetentionDays: _timerHistoryRetentionDays,
      partnerSortModes: _partnerSortModes,
      partnerCustomOrders: _partnerCustomOrders,
      toySortModes: _toySortModes,
      toyCustomOrders: _toyCustomOrders,
      settingsModifiedAt: _settingsModifiedAt,
    ),
  );
  ```
  (`lib/features/intimacy/views/intimacy_page.dart:234-253`, `_saveData()`.)
- **Notes:** `timerSessionModifiedAt`/`userBodyModifiedAt` each track only their own field
  independently of `settingsModifiedAt`, so an LWW sync merge on one never clobbers the others — the
  same independent-timestamp pattern documented in
  [Intimacy](../../../../features/intimacy.md#models). This model has no `copyWith`;
  [`IntimacyStorage._migrateLegacyTimerHistory`](../services/intimacy_storage.md#_migratelegacytimerhistory)
  reconstructs a full new instance field-by-field instead.

### `Map<String, dynamic> toJson()` <a id="intimacydata-tojson"></a>
- **Kind:** method of `IntimacyData`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 858)
- **Purpose:** Serialize the entire intimacy data tree into the top-level JSON written to
  `intimacy_data.json`.
- **Inputs:** None.
- **Returns:** A map with `partners`/`toys`/`positions`/`records`/`timerHistory`/
  `timerSessionModifiedAt`/`settingsModifiedAt` always present (as lists of each element's own
  `toJson()`); `timerSession`/`userBody`(only if `!isEmpty`)/`userBodyModifiedAt`(only if
  non-epoch-zero)/`cycleRecords`/`timerHistoryRetentionDays`/the four sort-mode/custom-order
  maps included only when non-null/non-empty.
- **Side effects:** None.
- **Algorithm:** Map literal; every list field mapped through its element type's own `toJson()`.
- **Usage:** Called from
  [`IntimacyStorage._saveNow`](../services/intimacy_storage.md#_savenow) (line 94): `next:
  data.toJson()`.
- **Notes:** None.

### `factory IntimacyData.fromJson(Map<String, dynamic> json)` <a id="intimacydata-fromjson"></a>
- **Kind:** factory constructor of `IntimacyData`
- **Source:** `lib/features/intimacy/models/intimacy_record.dart` (line 886)
- **Purpose:** Parse the entire intimacy data tree back out of `intimacy_data.json`.
- **Inputs:** `json` — decoded top-level map.
- **Returns:** A new `IntimacyData`.
- **Side effects:** None.
- **Algorithm:** Every list field parsed via `(json[k] as List<dynamic>?)?.map(...).toList() ?? []`
  through the corresponding model's own `fromJson`; `timerSession`/`userBody` guarded by an `is
  Map<String, dynamic>` type check; both `timerSessionModifiedAt` and `userBodyModifiedAt` fall back
  to the Unix epoch in UTC when absent; the two sort-mode maps and two custom-order maps are each
  parsed with a null-safe `.map(...)` or default to `const {}`.
- **Usage:** Called from
  [`IntimacyStorage.load`](../services/intimacy_storage.md#load) (line 58): `var data =
  IntimacyData.fromJson(json);`.
- **Notes:** None beyond what's covered above — every collection/timestamp field degrades to an empty/
  epoch-zero default independently, so a partially malformed file still parses as much as it can.

## Related pages

- [Intimacy](../../../../features/intimacy.md) — the feature these models back, including the
  hidden-by-default visibility toggle, the Body layer, and deleted-partner handling.
- [Data Formats](../../../../data-formats.md#intimacy--intimacy_datajson) — the exact JSON field list
  for every model above.
- [Three-Way Merge](../../../../algorithms/three-way-merge.md#deletionunion-semantics) —
  `CycleRecord`'s add/delete-only, per-id merge semantics.
- [Body Metrics](../../../../algorithms/body-metrics.md) — the bra-size/PSI/cycle-prediction
  calculations that read `BodyProfile`/`CycleRecord` fields (`services/body_metrics.md`,
  `services/cycle_predictor.md`).
- [`intimacy_storage.dart`](../services/intimacy_storage.md) — loads/saves the `IntimacyData` tree
  defined here.

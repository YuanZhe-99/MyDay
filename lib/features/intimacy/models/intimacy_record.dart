import 'package:uuid/uuid.dart';

/// Optional gender-neutral body measurements and preferences for one person.
class BodyProfile {
  final double? bustCm;
  final double? waistCm;
  final double? hipCm;
  final double? underbustCm;

  /// 'eu' | 'fr_es' | 'jp' | 'uk' | 'us' | 'au_nz'; null means the display default.
  final String? braStandard;
  final bool cycleEnabled;
  final bool showCycleOnCalendar;
  final double? erectLengthCm;
  final double? baseCircumferenceCm;
  final double? frontCircumferenceCm;

  /// Purpose: Create a body profile instance.
  /// Inputs: Optional measurement values and cycle display preferences.
  /// Returns: A new `BodyProfile` instance.
  /// Side effects: None.
  /// Notes: Every field is optional; the user's bust/waist/hip live in the
  /// Weight module instead, so those stay null on the user profile.
  const BodyProfile({
    this.bustCm,
    this.waistCm,
    this.hipCm,
    this.underbustCm,
    this.braStandard,
    this.cycleEnabled = false,
    this.showCycleOnCalendar = false,
    this.erectLengthCm,
    this.baseCircumferenceCm,
    this.frontCircumferenceCm,
  });

  /// Purpose: Report whether this profile carries no data at all.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: Empty profiles are stored as null so untouched data stays unchanged.
  bool get isEmpty =>
      bustCm == null &&
      waistCm == null &&
      hipCm == null &&
      underbustCm == null &&
      braStandard == null &&
      !cycleEnabled &&
      !showCycleOnCalendar &&
      erectLengthCm == null &&
      baseCircumferenceCm == null &&
      frontCircumferenceCm == null;

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    if (bustCm != null) 'bustCm': bustCm,
    if (waistCm != null) 'waistCm': waistCm,
    if (hipCm != null) 'hipCm': hipCm,
    if (underbustCm != null) 'underbustCm': underbustCm,
    if (braStandard != null) 'braStandard': braStandard,
    if (cycleEnabled) 'cycleEnabled': cycleEnabled,
    if (showCycleOnCalendar) 'showCycleOnCalendar': showCycleOnCalendar,
    if (erectLengthCm != null) 'erectLengthCm': erectLengthCm,
    if (baseCircumferenceCm != null)
      'baseCircumferenceCm': baseCircumferenceCm,
    if (frontCircumferenceCm != null)
      'frontCircumferenceCm': frontCircumferenceCm,
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `BodyProfile.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory BodyProfile.fromJson(Map<String, dynamic> json) => BodyProfile(
    bustCm: (json['bustCm'] as num?)?.toDouble(),
    waistCm: (json['waistCm'] as num?)?.toDouble(),
    hipCm: (json['hipCm'] as num?)?.toDouble(),
    underbustCm: (json['underbustCm'] as num?)?.toDouble(),
    braStandard: json['braStandard'] as String?,
    cycleEnabled: json['cycleEnabled'] == true,
    showCycleOnCalendar: json['showCycleOnCalendar'] == true,
    erectLengthCm: (json['erectLengthCm'] as num?)?.toDouble(),
    baseCircumferenceCm: (json['baseCircumferenceCm'] as num?)?.toDouble(),
    frontCircumferenceCm: (json['frontCircumferenceCm'] as num?)?.toDouble(),
  );

  /// Purpose: Create a copy of this value with selected fields replaced.
  /// Inputs: Optional replacement and clear flags for nullable fields.
  /// Returns: `BodyProfile`.
  /// Side effects: None.
  /// Notes: Use clear flags when a nullable field must be removed.
  BodyProfile copyWith({
    double? bustCm,
    bool clearBustCm = false,
    double? waistCm,
    bool clearWaistCm = false,
    double? hipCm,
    bool clearHipCm = false,
    double? underbustCm,
    bool clearUnderbustCm = false,
    String? braStandard,
    bool clearBraStandard = false,
    bool? cycleEnabled,
    bool? showCycleOnCalendar,
    double? erectLengthCm,
    bool clearErectLengthCm = false,
    double? baseCircumferenceCm,
    bool clearBaseCircumferenceCm = false,
    double? frontCircumferenceCm,
    bool clearFrontCircumferenceCm = false,
  }) => BodyProfile(
    bustCm: clearBustCm ? null : (bustCm ?? this.bustCm),
    waistCm: clearWaistCm ? null : (waistCm ?? this.waistCm),
    hipCm: clearHipCm ? null : (hipCm ?? this.hipCm),
    underbustCm: clearUnderbustCm ? null : (underbustCm ?? this.underbustCm),
    braStandard: clearBraStandard ? null : (braStandard ?? this.braStandard),
    cycleEnabled: cycleEnabled ?? this.cycleEnabled,
    showCycleOnCalendar: showCycleOnCalendar ?? this.showCycleOnCalendar,
    erectLengthCm: clearErectLengthCm
        ? null
        : (erectLengthCm ?? this.erectLengthCm),
    baseCircumferenceCm: clearBaseCircumferenceCm
        ? null
        : (baseCircumferenceCm ?? this.baseCircumferenceCm),
    frontCircumferenceCm: clearFrontCircumferenceCm
        ? null
        : (frontCircumferenceCm ?? this.frontCircumferenceCm),
  );
}

/// One recorded menstrual period start date for the user or a partner.
class CycleRecord {
  final String id;

  /// null means this record belongs to the user; otherwise a `Partner.id`.
  final String? personId;

  /// Local calendar date in `yyyy-MM-dd`; no time component is stored.
  final String date;
  final DateTime modifiedAt;

  /// Purpose: Create a cycle record instance.
  /// Inputs: `date` as a `yyyy-MM-dd` local calendar date, optional `personId`.
  /// Returns: A new `CycleRecord` instance.
  /// Side effects: None.
  /// Notes: Records are add/delete only; there is no edit flow.
  CycleRecord({
    String? id,
    this.personId,
    required this.date,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Return the record's calendar day as a date-only local DateTime.
  /// Inputs: None.
  /// Returns: `DateTime`.
  /// Side effects: None.
  /// Notes: The time component is always midnight local time.
  DateTime get day {
    final parsed = DateTime.parse(date);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Purpose: Format a calendar date as the stored `yyyy-MM-dd` string.
  /// Inputs: `day`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Ignores any time component on the input.
  static String formatDate(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$dayOfMonth';
  }

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    if (personId != null) 'personId': personId,
    'date': date,
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `CycleRecord.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory CycleRecord.fromJson(Map<String, dynamic> json) => CycleRecord(
    id: json['id'] as String,
    personId: json['personId'] as String?,
    date: json['date'] as String,
    modifiedAt: json['modifiedAt'] != null
        ? DateTime.parse(json['modifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class Partner {
  final String id;
  final String name;
  final String? emoji;
  final String? imagePath;
  final DateTime? startDate;
  final DateTime? endDate;
  final BodyProfile? body;
  final DateTime modifiedAt;

  /// Purpose: Create a partner instance.
  /// Inputs: None.
  /// Returns: A new `Partner` instance.
  /// Side effects: None.
  /// Notes: None.
  Partner({
    String? id,
    required this.name,
    this.emoji,
    this.imagePath,
    this.startDate,
    this.endDate,
    this.body,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (emoji != null) 'emoji': emoji,
    if (imagePath != null) 'imagePath': imagePath,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    if (body != null && !body!.isEmpty) 'body': body!.toJson(),
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `Partner.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory Partner.fromJson(Map<String, dynamic> json) => Partner(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String?,
    imagePath: json['imagePath'] as String?,
    startDate: json['startDate'] != null
        ? DateTime.parse(json['startDate'] as String)
        : null,
    endDate: json['endDate'] != null
        ? DateTime.parse(json['endDate'] as String)
        : null,
    body: json['body'] is Map<String, dynamic>
        ? BodyProfile.fromJson(json['body'] as Map<String, dynamic>)
        : null,
    modifiedAt: json['modifiedAt'] != null
        ? DateTime.parse(json['modifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Purpose: Create a copy of this value with selected fields replaced.
  /// Inputs: Optional replacement and clear flags for nullable fields.
  /// Returns: `Partner`.
  /// Side effects: None.
  /// Notes: Always stamps a fresh UTC `modifiedAt` so edits win LWW merges.
  Partner copyWith({
    String? name,
    String? emoji,
    bool clearEmoji = false,
    String? imagePath,
    bool clearImagePath = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    BodyProfile? body,
    bool clearBody = false,
  }) => Partner(
    id: id,
    name: name ?? this.name,
    emoji: clearEmoji ? null : (emoji ?? this.emoji),
    imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
    startDate: clearStartDate ? null : (startDate ?? this.startDate),
    endDate: clearEndDate ? null : (endDate ?? this.endDate),
    body: clearBody ? null : (body ?? this.body),
    modifiedAt: DateTime.now().toUtc(),
  );
}

class Toy {
  final String id;
  final String name;
  final String? emoji;
  final String? imagePath;
  final DateTime? purchaseDate;
  final DateTime? retiredDate;
  final String? purchaseLink;
  final double? price;
  final DateTime modifiedAt;

  /// Purpose: Create a toy instance.
  /// Inputs: None.
  /// Returns: A new `Toy` instance.
  /// Side effects: None.
  /// Notes: None.
  Toy({
    String? id,
    required this.name,
    this.emoji,
    this.imagePath,
    this.purchaseDate,
    this.retiredDate,
    this.purchaseLink,
    this.price,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Report whether this toy has cost data to summarize.
  /// Inputs: None.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: A zero price is still treated as explicit cost data.
  bool get hasCostData => price != null;

  /// Purpose: Calculate the toy's service days for cost averaging.
  /// Inputs: Optional `asOf` date.
  /// Returns: `int?`.
  /// Side effects: None.
  /// Notes: Requires a purchase date and clamps the minimum to one day.
  int? serviceDays({DateTime? asOf}) {
    if (purchaseDate == null) return null;
    final now = asOf ?? DateTime.now();
    var end = now;
    if (retiredDate != null && retiredDate!.isBefore(end)) {
      end = retiredDate!;
    }
    final days = end.difference(purchaseDate!).inDays + 1;
    return days < 1 ? 1 : days;
  }

  /// Purpose: Return the toy's total recorded cost.
  /// Inputs: Optional `asOf` date for API symmetry with daily cost.
  /// Returns: `double`.
  /// Side effects: None.
  /// Notes: The current model has purchase cost only, so `asOf` is ignored.
  double totalCost({DateTime? asOf}) => price ?? 0;

  /// Purpose: Calculate the toy's average daily cost.
  /// Inputs: Optional `asOf` date.
  /// Returns: `double?`.
  /// Side effects: None.
  /// Notes: Returns null until both price and purchase date are available.
  double? averageDailyCost({DateTime? asOf}) {
    if (!hasCostData) return null;
    final days = serviceDays(asOf: asOf);
    if (days == null) return null;
    return totalCost(asOf: asOf) / days;
  }

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (emoji != null) 'emoji': emoji,
    if (imagePath != null) 'imagePath': imagePath,
    if (purchaseDate != null) 'purchaseDate': purchaseDate!.toIso8601String(),
    if (retiredDate != null) 'retiredDate': retiredDate!.toIso8601String(),
    if (purchaseLink != null) 'purchaseLink': purchaseLink,
    if (price != null) 'price': price,
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `Toy.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory Toy.fromJson(Map<String, dynamic> json) => Toy(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String?,
    imagePath: json['imagePath'] as String?,
    purchaseDate: json['purchaseDate'] != null
        ? DateTime.parse(json['purchaseDate'] as String)
        : null,
    retiredDate: json['retiredDate'] != null
        ? DateTime.parse(json['retiredDate'] as String)
        : null,
    purchaseLink: json['purchaseLink'] as String?,
    price: (json['price'] as num?)?.toDouble(),
    modifiedAt: json['modifiedAt'] != null
        ? DateTime.parse(json['modifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class Position {
  final String id;
  final String name;
  final String? emoji;
  final DateTime modifiedAt;

  /// Purpose: Create a position instance.
  /// Inputs: `modifiedAt`.
  /// Returns: A new `Position` instance.
  /// Side effects: None.
  /// Notes: None.
  Position({String? id, required this.name, this.emoji, DateTime? modifiedAt})
    : id = id ?? const Uuid().v4(),
      modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (emoji != null) 'emoji': emoji,
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `Position.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory Position.fromJson(Map<String, dynamic> json) => Position(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String?,
    modifiedAt: json['modifiedAt'] != null
        ? DateTime.parse(json['modifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class IntimacyRecord {
  final String id;
  final String type; // 'Regular', 'Solo'
  final String? location;
  final bool isSolo;
  final String? partnerId;
  final List<String> toyIds;
  final List<String> positionIds;
  final int pleasureLevel; // 1-5
  final Duration duration;
  final int? thrustCount;
  final int thrustCountUnit;
  final DateTime datetime;
  final String? notes;
  final bool hadOrgasm;
  final bool watchedPorn;
  final bool usedCondom;
  final DateTime modifiedAt;

  /// Purpose: Create a intimacy record instance.
  /// Inputs: `isSolo`, optional thrust count value/unit, and protection flag.
  /// Returns: A new `IntimacyRecord` instance.
  /// Side effects: None.
  /// Notes: None.
  IntimacyRecord({
    String? id,
    required this.type,
    this.location,
    this.isSolo = false,
    this.partnerId,
    this.toyIds = const [],
    this.positionIds = const [],
    required this.pleasureLevel,
    required this.duration,
    this.thrustCount,
    int? thrustCountUnit,
    DateTime? datetime,
    this.notes,
    this.hadOrgasm = false,
    this.watchedPorn = false,
    this.usedCondom = false,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       thrustCountUnit = thrustCountUnit == 1 ? 1 : 100,
       datetime = datetime ?? DateTime.now(),
       modifiedAt = modifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    if (location != null) 'location': location,
    'isSolo': isSolo,
    if (partnerId != null) 'partnerId': partnerId,
    if (toyIds.isNotEmpty) 'toyIds': toyIds,
    if (positionIds.isNotEmpty) 'positionIds': positionIds,
    'pleasureLevel': pleasureLevel,
    'duration': duration.inSeconds,
    if (thrustCount != null) 'thrustCount': thrustCount,
    if (thrustCount != null) 'thrustCountUnit': thrustCountUnit,
    'datetime': datetime.toIso8601String(),
    if (notes != null) 'notes': notes,
    'hadOrgasm': hadOrgasm,
    'watchedPorn': watchedPorn,
    'usedCondom': usedCondom,
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `IntimacyRecord.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory IntimacyRecord.fromJson(Map<String, dynamic> json) {
    // Backward compat: old records had 'partner' string field
    final isSolo = json['isSolo'] as bool? ?? false;
    return IntimacyRecord(
      id: json['id'] as String,
      type: json['type'] as String,
      location: json['location'] as String?,
      isSolo: isSolo,
      partnerId: json['partnerId'] as String?,
      toyIds:
          (json['toyIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      positionIds:
          (json['positionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      pleasureLevel: json['pleasureLevel'] as int,
      duration: Duration(seconds: json['duration'] as int),
      thrustCount: (json['thrustCount'] as num?)?.toInt(),
      thrustCountUnit: json['thrustCountUnit'] == 1 ? 1 : 100,
      datetime: DateTime.parse(json['datetime'] as String),
      notes: json['notes'] as String?,
      hadOrgasm: json['hadOrgasm'] as bool? ?? false,
      watchedPorn: json['watchedPorn'] as bool? ?? false,
      usedCondom: json['usedCondom'] as bool? ?? false,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// A single timer history entry (independent of IntimacyRecord).
class TimerHistoryEntry {
  final DateTime start;
  final Duration duration;
  final int thrustCount;
  final int thrustCountUnit;

  /// Purpose: Create a timer history entry instance.
  /// Inputs: `duration` and optional thrust count value/unit.
  /// Returns: A new `TimerHistoryEntry` instance.
  /// Side effects: None.
  /// Notes: None.
  TimerHistoryEntry({
    required this.start,
    required this.duration,
    int thrustCount = 0,
    int? thrustCountUnit,
  }) : thrustCount = thrustCount < 0 ? 0 : thrustCount,
       thrustCountUnit = thrustCountUnit == 1 ? 1 : 100;

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'durationMs': duration.inMilliseconds,
    if (thrustCount > 0) 'thrustCount': thrustCount,
    if (thrustCount > 0) 'thrustCountUnit': thrustCountUnit,
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `TimerHistoryEntry.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory TimerHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawThrustCount = (json['thrustCount'] as num?)?.toInt() ?? 0;
    final thrustCount = rawThrustCount > 0 ? rawThrustCount : 0;
    final thrustCountUnit = json['thrustCountUnit'] == 1 ? 1 : 100;
    // Support legacy entries that stored 'end' instead of 'durationMs'
    if (json.containsKey('durationMs')) {
      return TimerHistoryEntry(
        start: DateTime.parse(json['start'] as String),
        duration: Duration(milliseconds: json['durationMs'] as int),
        thrustCount: thrustCount,
        thrustCountUnit: thrustCountUnit,
      );
    }
    final start = DateTime.parse(json['start'] as String);
    final end = DateTime.parse(json['end'] as String);
    return TimerHistoryEntry(
      start: start,
      duration: end.difference(start),
      thrustCount: thrustCount,
      thrustCountUnit: thrustCountUnit,
    );
  }
}

class IntimacyTimerSession {
  final DateTime firstStartedAt;
  final DateTime? startedAt;
  final Duration accumulated;
  final bool running;
  final int thrustCount;
  final int thrustCountUnit;

  /// Purpose: Create an intimacy timer session snapshot.
  /// Inputs: `firstStartedAt`, optional `startedAt`, elapsed `accumulated`, `running`, and optional thrust count value/unit.
  /// Returns: A new `IntimacyTimerSession` instance.
  /// Side effects: None.
  /// Notes: `accumulated` stores elapsed time before the latest running segment.
  IntimacyTimerSession({
    required this.firstStartedAt,
    this.startedAt,
    required this.accumulated,
    required this.running,
    int thrustCount = 0,
    int? thrustCountUnit,
  }) : thrustCount = thrustCount < 0 ? 0 : thrustCount,
       thrustCountUnit = thrustCountUnit == 1 ? 1 : 100;

  /// Purpose: Calculate elapsed timer duration at a wall-clock instant.
  /// Inputs: `now`.
  /// Returns: `Duration`.
  /// Side effects: None.
  /// Notes: Running sessions continue over app restarts; paused sessions return `accumulated`.
  Duration elapsedAt(DateTime now) {
    if (!running || startedAt == null) return accumulated;
    return accumulated + now.difference(startedAt!);
  }

  /// Purpose: Serialize this timer session into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep this aligned with `intimacy_data.json` and sync merge behavior.
  Map<String, dynamic> toJson() => {
    'firstStartedAt': firstStartedAt.toIso8601String(),
    if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
    'accumulatedMs': accumulated.inMilliseconds,
    'running': running,
    if (thrustCount > 0) 'thrustCount': thrustCount,
    if (thrustCount > 0) 'thrustCountUnit': thrustCountUnit,
  };

  /// Purpose: Create a timer session from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `IntimacyTimerSession.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when restoring an interrupted stopwatch session.
  factory IntimacyTimerSession.fromJson(Map<String, dynamic> json) {
    final firstStartedAt = DateTime.parse(json['firstStartedAt'] as String);
    final startedAt = json['startedAt'] != null
        ? DateTime.parse(json['startedAt'] as String)
        : null;
    final running = json['running'] as bool? ?? startedAt != null;
    final rawThrustCount = (json['thrustCount'] as num?)?.toInt() ?? 0;
    return IntimacyTimerSession(
      firstStartedAt: firstStartedAt,
      startedAt: running ? (startedAt ?? firstStartedAt) : null,
      accumulated: Duration(milliseconds: json['accumulatedMs'] as int? ?? 0),
      running: running,
      thrustCount: rawThrustCount > 0 ? rawThrustCount : 0,
      thrustCountUnit: json['thrustCountUnit'] == 1 ? 1 : 100,
    );
  }
}

class IntimacyData {
  final List<Partner> partners;
  final List<Toy> toys;
  final List<Position> positions;
  final List<IntimacyRecord> records;
  final List<TimerHistoryEntry> timerHistory;
  final IntimacyTimerSession? timerSession;
  final DateTime timerSessionModifiedAt;

  /// The user's own body profile; null until the user records something.
  final BodyProfile? userBody;

  /// LWW timestamp for `userBody` only, independent of `settingsModifiedAt`.
  final DateTime userBodyModifiedAt;

  /// Period start dates for the user and partners, merged per record id.
  final List<CycleRecord> cycleRecords;

  /// null = permanent, otherwise days (3, 7, 14)
  final int? timerHistoryRetentionDays;
  final Map<String, String> partnerSortModes;
  final Map<String, List<String>> partnerCustomOrders;
  final Map<String, String> toySortModes;
  final Map<String, List<String>> toyCustomOrders;
  final DateTime settingsModifiedAt;

  /// Purpose: Create a intimacy data instance.
  /// Inputs: `positions` and persisted timer session state.
  /// Returns: A new `IntimacyData` instance.
  /// Side effects: None.
  /// Notes: None.
  IntimacyData({
    required this.partners,
    required this.toys,
    this.positions = const [],
    required this.records,
    this.timerHistory = const [],
    this.timerSession,
    DateTime? timerSessionModifiedAt,
    this.userBody,
    DateTime? userBodyModifiedAt,
    this.cycleRecords = const [],
    this.timerHistoryRetentionDays,
    this.partnerSortModes = const {},
    this.partnerCustomOrders = const {},
    this.toySortModes = const {},
    this.toyCustomOrders = const {},
    DateTime? settingsModifiedAt,
  }) : timerSessionModifiedAt =
           timerSessionModifiedAt ??
           DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
       userBodyModifiedAt =
           userBodyModifiedAt ??
           DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
       settingsModifiedAt = settingsModifiedAt ?? DateTime.now().toUtc();

  /// Purpose: Serialize this value into a JSON-compatible map.
  /// Inputs: None.
  /// Returns: A JSON-compatible map.
  /// Side effects: None.
  /// Notes: Keep the output aligned with the persisted file and sync format.
  Map<String, dynamic> toJson() => {
    'partners': partners.map((p) => p.toJson()).toList(),
    'toys': toys.map((t) => t.toJson()).toList(),
    'positions': positions.map((p) => p.toJson()).toList(),
    'records': records.map((r) => r.toJson()).toList(),
    'timerHistory': timerHistory.map((e) => e.toJson()).toList(),
    if (timerSession != null) 'timerSession': timerSession!.toJson(),
    'timerSessionModifiedAt': timerSessionModifiedAt.toIso8601String(),
    if (userBody != null && !userBody!.isEmpty) 'userBody': userBody!.toJson(),
    if (userBodyModifiedAt.millisecondsSinceEpoch != 0)
      'userBodyModifiedAt': userBodyModifiedAt.toIso8601String(),
    if (cycleRecords.isNotEmpty)
      'cycleRecords': cycleRecords.map((c) => c.toJson()).toList(),
    if (timerHistoryRetentionDays != null)
      'timerHistoryRetentionDays': timerHistoryRetentionDays,
    if (partnerSortModes.isNotEmpty) 'partnerSortModes': partnerSortModes,
    if (partnerCustomOrders.isNotEmpty)
      'partnerCustomOrders': partnerCustomOrders,
    if (toySortModes.isNotEmpty) 'toySortModes': toySortModes,
    if (toyCustomOrders.isNotEmpty) 'toyCustomOrders': toyCustomOrders,
    'settingsModifiedAt': settingsModifiedAt.toIso8601String(),
  };

  /// Purpose: Create an instance from a JSON-compatible map.
  /// Inputs: `json`.
  /// Returns: A new `IntimacyData.fromJson` instance.
  /// Side effects: None.
  /// Notes: Use this path when reading the persisted or transferred data format for this type.
  factory IntimacyData.fromJson(Map<String, dynamic> json) => IntimacyData(
    partners:
        (json['partners'] as List<dynamic>?)
            ?.map((p) => Partner.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [],
    toys:
        (json['toys'] as List<dynamic>?)
            ?.map((t) => Toy.fromJson(t as Map<String, dynamic>))
            .toList() ??
        [],
    positions:
        (json['positions'] as List<dynamic>?)
            ?.map((p) => Position.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [],
    records:
        (json['records'] as List<dynamic>?)
            ?.map((r) => IntimacyRecord.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [],
    timerHistory:
        (json['timerHistory'] as List<dynamic>?)
            ?.map((e) => TimerHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    timerSession: json['timerSession'] is Map<String, dynamic>
        ? IntimacyTimerSession.fromJson(
            json['timerSession'] as Map<String, dynamic>,
          )
        : null,
    timerSessionModifiedAt: json['timerSessionModifiedAt'] != null
        ? DateTime.parse(json['timerSessionModifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    userBody: json['userBody'] is Map<String, dynamic>
        ? BodyProfile.fromJson(json['userBody'] as Map<String, dynamic>)
        : null,
    userBodyModifiedAt: json['userBodyModifiedAt'] != null
        ? DateTime.parse(json['userBodyModifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    cycleRecords:
        (json['cycleRecords'] as List<dynamic>?)
            ?.map((c) => CycleRecord.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [],
    timerHistoryRetentionDays: json['timerHistoryRetentionDays'] as int?,
    partnerSortModes:
        (json['partnerSortModes'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as String),
        ) ??
        const {},
    partnerCustomOrders:
        (json['partnerCustomOrders'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>).map((e) => e as String).toList(),
          ),
        ) ??
        const {},
    toySortModes:
        (json['toySortModes'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as String),
        ) ??
        const {},
    toyCustomOrders:
        (json['toyCustomOrders'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>).map((e) => e as String).toList(),
          ),
        ) ??
        const {},
    settingsModifiedAt: json['settingsModifiedAt'] != null
        ? DateTime.parse(json['settingsModifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
  );
}

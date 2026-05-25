import 'package:uuid/uuid.dart';

class Partner {
  final String id;
  final String name;
  final String? emoji;
  final String? imagePath;
  final DateTime? startDate;
  final DateTime? endDate;
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
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now();

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
    modifiedAt: json['modifiedAt'] != null
        ? DateTime.parse(json['modifiedAt'] as String)
        : DateTime.fromMillisecondsSinceEpoch(0),
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
       modifiedAt = modifiedAt ?? DateTime.now();

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
      modifiedAt = modifiedAt ?? DateTime.now();

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
       modifiedAt = modifiedAt ?? DateTime.now();

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
    this.timerHistoryRetentionDays,
    this.partnerSortModes = const {},
    this.partnerCustomOrders = const {},
    this.toySortModes = const {},
    this.toyCustomOrders = const {},
    DateTime? settingsModifiedAt,
  }) : timerSessionModifiedAt =
           timerSessionModifiedAt ??
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

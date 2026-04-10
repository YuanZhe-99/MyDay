import 'package:uuid/uuid.dart';

class Partner {
  final String id;
  final String name;
  final String? emoji;
  final String? imagePath;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime modifiedAt;

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (emoji != null) 'emoji': emoji,
        if (imagePath != null) 'imagePath': imagePath,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
      };

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

  Position({
    String? id,
    required this.name,
    this.emoji,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (emoji != null) 'emoji': emoji,
        'modifiedAt': modifiedAt.toIso8601String(),
      };

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
  final DateTime datetime;
  final String? notes;
  final bool hadOrgasm;
  final bool watchedPorn;
  final DateTime modifiedAt;

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
    DateTime? datetime,
    this.notes,
    this.hadOrgasm = false,
    this.watchedPorn = false,
    DateTime? modifiedAt,
  })  : id = id ?? const Uuid().v4(),
        datetime = datetime ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

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
        'datetime': datetime.toIso8601String(),
        if (notes != null) 'notes': notes,
        'hadOrgasm': hadOrgasm,
        'watchedPorn': watchedPorn,
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory IntimacyRecord.fromJson(Map<String, dynamic> json) {
    // Backward compat: old records had 'partner' string field
    final isSolo = json['isSolo'] as bool? ?? false;
    return IntimacyRecord(
      id: json['id'] as String,
      type: json['type'] as String,
      location: json['location'] as String?,
      isSolo: isSolo,
      partnerId: json['partnerId'] as String?,
      toyIds: (json['toyIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      positionIds: (json['positionIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      pleasureLevel: json['pleasureLevel'] as int,
      duration: Duration(seconds: json['duration'] as int),
      datetime: DateTime.parse(json['datetime'] as String),
      notes: json['notes'] as String?,
      hadOrgasm: json['hadOrgasm'] as bool? ?? false,
      watchedPorn: json['watchedPorn'] as bool? ?? false,
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
  const TimerHistoryEntry({required this.start, required this.duration});

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'durationMs': duration.inMilliseconds,
      };

  factory TimerHistoryEntry.fromJson(Map<String, dynamic> json) {
    // Support legacy entries that stored 'end' instead of 'durationMs'
    if (json.containsKey('durationMs')) {
      return TimerHistoryEntry(
        start: DateTime.parse(json['start'] as String),
        duration: Duration(milliseconds: json['durationMs'] as int),
      );
    }
    final start = DateTime.parse(json['start'] as String);
    final end = DateTime.parse(json['end'] as String);
    return TimerHistoryEntry(start: start, duration: end.difference(start));
  }
}

class IntimacyData {
  final List<Partner> partners;
  final List<Toy> toys;
  final List<Position> positions;
  final List<IntimacyRecord> records;
  final List<TimerHistoryEntry> timerHistory;
  /// null = permanent, otherwise days (3, 7, 14)
  final int? timerHistoryRetentionDays;
  final DateTime settingsModifiedAt;

  IntimacyData({
    required this.partners,
    required this.toys,
    this.positions = const [],
    required this.records,
    this.timerHistory = const [],
    this.timerHistoryRetentionDays,
    DateTime? settingsModifiedAt,
  }) : settingsModifiedAt = settingsModifiedAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
        'partners': partners.map((p) => p.toJson()).toList(),
        'toys': toys.map((t) => t.toJson()).toList(),
        'positions': positions.map((p) => p.toJson()).toList(),
        'records': records.map((r) => r.toJson()).toList(),
        'timerHistory': timerHistory.map((e) => e.toJson()).toList(),
        if (timerHistoryRetentionDays != null)
          'timerHistoryRetentionDays': timerHistoryRetentionDays,
        'settingsModifiedAt': settingsModifiedAt.toIso8601String(),
      };

  factory IntimacyData.fromJson(Map<String, dynamic> json) => IntimacyData(
        partners: (json['partners'] as List<dynamic>?)
                ?.map((p) => Partner.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        toys: (json['toys'] as List<dynamic>?)
                ?.map((t) => Toy.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        positions: (json['positions'] as List<dynamic>?)
                ?.map((p) => Position.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        records: (json['records'] as List<dynamic>?)
                ?.map((r) => IntimacyRecord.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        timerHistory: (json['timerHistory'] as List<dynamic>?)
                ?.map((e) =>
                    TimerHistoryEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        timerHistoryRetentionDays:
            json['timerHistoryRetentionDays'] as int?,
        settingsModifiedAt: json['settingsModifiedAt'] != null
            ? DateTime.parse(json['settingsModifiedAt'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0),
      );
}

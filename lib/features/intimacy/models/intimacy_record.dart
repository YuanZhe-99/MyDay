import 'package:uuid/uuid.dart';

class Partner {
  final String id;
  final String name;
  final String? emoji;
  final String? imagePath;
  final DateTime modifiedAt;

  Partner({
    String? id,
    required this.name,
    this.emoji,
    this.imagePath,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (emoji != null) 'emoji': emoji,
        if (imagePath != null) 'imagePath': imagePath,
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory Partner.fromJson(Map<String, dynamic> json) => Partner(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String?,
        imagePath: json['imagePath'] as String?,
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
  final DateTime modifiedAt;

  Toy({
    String? id,
    required this.name,
    this.emoji,
    this.imagePath,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       modifiedAt = modifiedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (emoji != null) 'emoji': emoji,
        if (imagePath != null) 'imagePath': imagePath,
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory Toy.fromJson(Map<String, dynamic> json) => Toy(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String?,
        imagePath: json['imagePath'] as String?,
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

class IntimacyData {
  final List<Partner> partners;
  final List<Toy> toys;
  final List<IntimacyRecord> records;

  IntimacyData({
    required this.partners,
    required this.toys,
    required this.records,
  });

  Map<String, dynamic> toJson() => {
        'partners': partners.map((p) => p.toJson()).toList(),
        'toys': toys.map((t) => t.toJson()).toList(),
        'records': records.map((r) => r.toJson()).toList(),
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
        records: (json['records'] as List<dynamic>?)
                ?.map((r) => IntimacyRecord.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

import 'package:uuid/uuid.dart';

class WeightRecord {
  final String id;
  final double weight; // kg
  final double? bodyFat; // percentage, optional
  final DateTime datetime;
  final String? notes;
  final DateTime modifiedAt;

  WeightRecord({
    String? id,
    required this.weight,
    this.bodyFat,
    DateTime? datetime,
    this.notes,
    DateTime? modifiedAt,
  })  : id = id ?? const Uuid().v4(),
        datetime = datetime ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'weight': weight,
        if (bodyFat != null) 'bodyFat': bodyFat,
        'datetime': datetime.toIso8601String(),
        if (notes != null) 'notes': notes,
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
        id: json['id'] as String,
        weight: (json['weight'] as num).toDouble(),
        bodyFat: (json['bodyFat'] as num?)?.toDouble(),
        datetime: DateTime.parse(json['datetime'] as String),
        notes: json['notes'] as String?,
        modifiedAt: json['modifiedAt'] != null
            ? DateTime.parse(json['modifiedAt'] as String)
            : DateTime.now(),
      );

  WeightRecord copyWith({
    double? weight,
    double? bodyFat,
    DateTime? datetime,
    String? notes,
  }) =>
      WeightRecord(
        id: id,
        weight: weight ?? this.weight,
        bodyFat: bodyFat ?? this.bodyFat,
        datetime: datetime ?? this.datetime,
        notes: notes ?? this.notes,
        modifiedAt: DateTime.now(),
      );
}

class WeightData {
  final double? height; // cm
  final List<WeightRecord> records;
  /// 'none' | 'once' | 'twice'
  final String reminderMode;
  final int? morningHour;
  final int? morningMinute;
  final int? eveningHour;
  final int? eveningMinute;
  final DateTime settingsModifiedAt;

  WeightData({
    this.height,
    required this.records,
    this.reminderMode = 'none',
    this.morningHour,
    this.morningMinute,
    this.eveningHour,
    this.eveningMinute,
    DateTime? settingsModifiedAt,
  }) : settingsModifiedAt =
            settingsModifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  Map<String, dynamic> toJson() => {
        if (height != null) 'height': height,
        'records': records.map((r) => r.toJson()).toList(),
        'reminderMode': reminderMode,
        if (morningHour != null) 'morningHour': morningHour,
        if (morningMinute != null) 'morningMinute': morningMinute,
        if (eveningHour != null) 'eveningHour': eveningHour,
        if (eveningMinute != null) 'eveningMinute': eveningMinute,
        'settingsModifiedAt': settingsModifiedAt.toIso8601String(),
      };

  factory WeightData.fromJson(Map<String, dynamic> json) => WeightData(
        height: (json['height'] as num?)?.toDouble(),
        records: (json['records'] as List? ?? [])
            .map((e) => WeightRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        reminderMode: json['reminderMode'] as String? ?? 'none',
        morningHour: json['morningHour'] as int?,
        morningMinute: json['morningMinute'] as int?,
        eveningHour: json['eveningHour'] as int?,
        eveningMinute: json['eveningMinute'] as int?,
        settingsModifiedAt: json['settingsModifiedAt'] != null
            ? DateTime.parse(json['settingsModifiedAt'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0),
      );

  /// Calculate BMI from height (cm) and weight (kg).
  static double? calculateBMI(double? heightCm, double weightKg) {
    if (heightCm == null || heightCm <= 0) return null;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }
}

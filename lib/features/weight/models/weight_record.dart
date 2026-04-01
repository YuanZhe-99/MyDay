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

  WeightData({
    this.height,
    required this.records,
  });

  Map<String, dynamic> toJson() => {
        if (height != null) 'height': height,
        'records': records.map((r) => r.toJson()).toList(),
      };

  factory WeightData.fromJson(Map<String, dynamic> json) => WeightData(
        height: (json['height'] as num?)?.toDouble(),
        records: (json['records'] as List? ?? [])
            .map((e) => WeightRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Calculate BMI from height (cm) and weight (kg).
  static double? calculateBMI(double? heightCm, double weightKg) {
    if (heightCm == null || heightCm <= 0) return null;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }
}

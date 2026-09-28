import '../../ai/services/insight_prompts.dart';
import '../models/weight_record.dart';

/// Purpose: Describe the weight change over a window.
/// Inputs: `sorted` — records oldest first; `now`; `days`.
/// Returns: `String?` — null when fewer than two records fall in the window.
/// Side effects: None.
/// Notes: First versus last record inside the window.
String? _change(List<WeightRecord> sorted, DateTime now, int days) {
  final from = now.subtract(Duration(days: days));
  final inWindow = sorted
      .where((r) => !r.datetime.isBefore(from) && !r.datetime.isAfter(now))
      .toList();
  if (inWindow.length < 2) return null;
  final delta = inWindow.last.weight - inWindow.first.weight;
  final sign = delta > 0 ? '+' : '';
  return '$sign${factNumber(delta)} kg over $days days '
      '(${inWindow.length} weigh-ins)';
}

/// Purpose: Build the Weight card's facts.
/// Inputs: `now` — local time; `heightCm`; `records`.
/// Returns: `InsightFacts?` — null without records.
/// Side effects: None.
/// Notes: Record notes are never sent. Measurements carry forward per field
/// exactly as the Weight page shows them.
InsightFacts? buildWeightInsightFacts({
  required DateTime now,
  required double? heightCm,
  required List<WeightRecord> records,
}) {
  final sorted =
      records.where((r) => !r.datetime.isAfter(now)).toList()
        ..sort((a, b) => a.datetime.compareTo(b.datetime));
  if (sorted.isEmpty) return null;
  final latest = sorted.last;
  final lines = <String>[
    '- Today: ${factDate(now)}',
    '- Latest weight: ${factNumber(latest.weight)} kg on '
        '${factDate(latest.datetime)} '
        '(${DateTime(now.year, now.month, now.day).difference(DateTime(latest.datetime.year, latest.datetime.month, latest.datetime.day)).inDays} days ago)',
  ];
  if (heightCm != null && heightCm > 0) {
    lines.add('- Height: ${factNumber(heightCm)} cm');
    final bmi = WeightData.calculateBMI(heightCm, latest.weight);
    if (bmi != null) lines.add('- BMI: ${factNumber(bmi)}');
  }
  for (final days in const [7, 30, 90]) {
    final change = _change(sorted, now, days);
    if (change != null) lines.add('- Change: $change');
  }
  final recent = sorted.length > 7
      ? sorted.sublist(sorted.length - 7)
      : sorted;
  if (recent.length >= 2) {
    final ws = recent.map((r) => r.weight);
    lines.add(
      '- Last ${recent.length} weigh-ins range: '
      '${factNumber(ws.reduce((a, b) => a < b ? a : b))}–'
      '${factNumber(ws.reduce((a, b) => a > b ? a : b))} kg',
    );
  }
  final since30 = now.subtract(const Duration(days: 30));
  lines.add(
    '- Weigh-ins in the last 30 days: '
    '${sorted.where((r) => !r.datetime.isBefore(since30)).length}',
  );
  final fat = sorted.lastWhere(
    (r) => r.bodyFat != null && r.bodyFat! > 0,
    orElse: () => latest,
  );
  if (fat.bodyFat != null && fat.bodyFat! > 0) {
    lines.add(
      '- Body fat: ${factNumber(fat.bodyFat!)}% on ${factDate(fat.datetime)}',
    );
  }
  final m = WeightData.effectiveMeasurementsUpTo(sorted, now);
  final parts = [
    if (m.bustCm != null) 'bust ${factNumber(m.bustCm!)} cm',
    if (m.waistCm != null) 'waist ${factNumber(m.waistCm!)} cm',
    if (m.hipCm != null) 'hip ${factNumber(m.hipCm!)} cm',
  ];
  if (parts.isNotEmpty) lines.add('- Latest measurements: ${parts.join(', ')}');
  final whr = WeightData.calculateWaistHipRatio(m.waistCm, m.hipCm);
  if (whr != null) lines.add('- Waist-to-hip ratio: ${factNumber(whr, 2)}');

  return InsightFacts(
    module: InsightModule.weight,
    bucket: InsightTimeBucket.none,
    lines: lines,
    slots: const [
      InsightSlot('trend', 'Describe the weight trend.'),
      InsightSlot(
        'advice',
        'One gentle, practical suggestion based on the trend.',
      ),
    ],
  );
}

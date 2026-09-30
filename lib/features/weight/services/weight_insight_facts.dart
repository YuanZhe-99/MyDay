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
  return '${_signed(delta)} kg over $days days '
      '(${inWindow.length} weigh-ins)';
}

/// Purpose: Format a signed difference for a fact line.
/// Inputs: `delta`; `digits` — decimal places, default 1.
/// Returns: `String` — `+1.2`, `-0.5` or `0`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
String _signed(double delta, [int digits = 1]) {
  final text = factNumber(delta, digits);
  return delta > 0 && text != '0' ? '+$text' : text;
}

/// Purpose: Name the BMI band the Weight page's colored bar shows.
/// Inputs: `bmi`.
/// Returns: `String` — `underweight`, `normal`, `overweight` or `obese`
/// range.
/// Side effects: None.
/// Notes: Same cut-offs as `_buildBMIBar` in `weight_page.dart`
/// (18.5, 25, 30). A band, not a diagnosis.
String _bmiBand(double bmi) {
  if (bmi < 18.5) return 'underweight range';
  if (bmi < 25) return 'normal range';
  if (bmi < 30) return 'overweight range';
  return 'obese range';
}

/// Purpose: Describe how one optional field moved inside a window.
/// Inputs: `sorted` — records oldest first; `from`; `now`; `value` — the
/// field reader.
/// Returns: `({double first, double last, DateTime firstAt})?` — null when
/// fewer than two records in the window have a positive value.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Only records that
/// measured the field count; carried-forward values are not.
({double first, double last, DateTime firstAt})? _fieldChange(
  List<WeightRecord> sorted,
  DateTime from,
  DateTime now,
  double? Function(WeightRecord r) value,
) {
  final points = sorted
      .where(
        (r) =>
            !r.datetime.isBefore(from) &&
            !r.datetime.isAfter(now) &&
            (value(r) ?? 0) > 0,
      )
      .toList();
  if (points.length < 2) return null;
  return (
    first: value(points.first)!,
    last: value(points.last)!,
    firstAt: points.first.datetime,
  );
}

/// Purpose: Build the Weight card's facts.
/// Inputs: `now` — local time; `heightCm`; `records`.
/// Returns: `InsightFacts?` — null without records. Slots `trend`, `body`
/// (only when a BMI, body-fat or measurement fact was sent) and `advice`.
/// Side effects: None.
/// Notes: Record notes are never sent. Measurements carry forward per field
/// exactly as the Weight page shows them; the 90-day body-fat and
/// measurement changes use only records that measured the field. The page
/// pairs this with [buildWeightFallbackInsightFacts].
InsightFacts? buildWeightInsightFacts({
  required DateTime now,
  required double? heightCm,
  required List<WeightRecord> records,
}) => _weightFacts(now, heightCm, records, detailed: true);

/// Purpose: Build the Weight card's fallback facts: the v1.5.2 prompt.
/// Inputs: `now` — local time; `heightCm`; `records`.
/// Returns: `InsightFacts?` — null without records. Slots `trend` and
/// `advice`, with the v1.5.2 wording.
/// Side effects: None.
/// Notes: Sent once, as `AiInsightRequest.fallbackFacts`, only when the model
/// declines the detailed facts or answers nothing usable. No BMI band, no
/// tracking start, no 90-day body changes and no `body` question.
InsightFacts? buildWeightFallbackInsightFacts({
  required DateTime now,
  required double? heightCm,
  required List<WeightRecord> records,
}) => _weightFacts(now, heightCm, records, detailed: false);

/// Purpose: Build either version of the Weight card's facts.
/// Inputs: `now`; `heightCm`; `records`; `detailed` — true for the v1.5.3
/// facts, false for the v1.5.2 facts.
/// Returns: `InsightFacts?` — null without records.
/// Side effects: None.
/// Notes: Internal helper used within this file only. With `detailed`
/// false the output is exactly what v1.5.2 sent.
InsightFacts? _weightFacts(
  DateTime now,
  double? heightCm,
  List<WeightRecord> records, {
  required bool detailed,
}) {
  final sorted = records.where((r) => !r.datetime.isAfter(now)).toList()
    ..sort((a, b) => a.datetime.compareTo(b.datetime));
  if (sorted.isEmpty) return null;
  final latest = sorted.last;
  var hasBody = false;
  final lines = <String>[
    '- Today: ${factDate(now)}',
    '- Latest weight: ${factNumber(latest.weight)} kg on '
        '${factDate(latest.datetime)} '
        '(${DateTime(now.year, now.month, now.day).difference(DateTime(latest.datetime.year, latest.datetime.month, latest.datetime.day)).inDays} days ago)',
  ];
  if (heightCm != null && heightCm > 0) {
    lines.add('- Height: ${factNumber(heightCm)} cm');
    final bmi = WeightData.calculateBMI(heightCm, latest.weight);
    if (bmi != null) {
      lines.add(
        detailed
            ? '- BMI: ${factNumber(bmi)} (${_bmiBand(bmi)})'
            : '- BMI: ${factNumber(bmi)}',
      );
      hasBody = true;
    }
  }
  for (final days in const [7, 30, 90]) {
    final change = _change(sorted, now, days);
    if (change != null) lines.add('- Change: $change');
  }
  final recent = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
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
  if (detailed) {
    lines.add(
      '- Tracking since: ${factDate(sorted.first.datetime)} '
      '(${sorted.length} weigh-ins in total)',
    );
  }
  final fat = sorted.lastWhere(
    (r) => r.bodyFat != null && r.bodyFat! > 0,
    orElse: () => latest,
  );
  if (fat.bodyFat != null && fat.bodyFat! > 0) {
    lines.add(
      '- Body fat: ${factNumber(fat.bodyFat!)}% on ${factDate(fat.datetime)}',
    );
    hasBody = true;
  }
  final since90 = now.subtract(const Duration(days: 90));
  final fatChange = detailed
      ? _fieldChange(sorted, since90, now, (r) => r.bodyFat)
      : null;
  if (fatChange != null) {
    lines.add(
      '- Body fat change over 90 days: '
      '${_signed(fatChange.last - fatChange.first)} points '
      '(from ${factNumber(fatChange.first)}% on '
      '${factDate(fatChange.firstAt)})',
    );
  }
  final m = WeightData.effectiveMeasurementsUpTo(sorted, now);
  final parts = [
    if (m.bustCm != null) 'bust ${factNumber(m.bustCm!)} cm',
    if (m.waistCm != null) 'waist ${factNumber(m.waistCm!)} cm',
    if (m.hipCm != null) 'hip ${factNumber(m.hipCm!)} cm',
  ];
  if (parts.isNotEmpty) {
    lines.add('- Latest measurements: ${parts.join(', ')}');
    hasBody = true;
  }
  final whr = WeightData.calculateWaistHipRatio(m.waistCm, m.hipCm);
  if (whr != null) lines.add('- Waist-to-hip ratio: ${factNumber(whr, 2)}');
  final moved = <String>[
    if (detailed)
      for (final (name, read) in <(String, double? Function(WeightRecord))>[
        ('bust', (r) => r.bustCm),
        ('waist', (r) => r.waistCm),
        ('hip', (r) => r.hipCm),
      ])
        if (_fieldChange(sorted, since90, now, read) case final c?)
          '$name ${_signed(c.last - c.first)} cm',
  ];
  if (moved.isNotEmpty) {
    lines.add('- Measurement change over 90 days: ${moved.join(', ')}');
  }

  return InsightFacts(
    module: InsightModule.weight,
    bucket: InsightTimeBucket.none,
    lines: lines,
    slots: [
      const InsightSlot('trend', 'Describe the weight trend.'),
      if (detailed && hasBody)
        const InsightSlot(
          'body',
          'Sum up the body condition neutrally: BMI, body fat and '
              'measurements, and how they have moved.',
        ),
      if (detailed)
        const InsightSlot(
          'advice',
          'One gentle, practical suggestion based on the trend and the body '
              'facts.',
        )
      else
        const InsightSlot(
          'advice',
          'One gentle, practical suggestion based on the trend.',
        ),
    ],
  );
}

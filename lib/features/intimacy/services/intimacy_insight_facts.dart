import '../../ai/services/insight_prompts.dart';
import '../../weight/models/weight_record.dart';
import '../models/intimacy_record.dart';
import 'body_metrics.dart';
import 'cycle_predictor.dart';

/// Purpose: Summarize the records in one window.
/// Inputs: `records`, `from` (inclusive), `to` (exclusive).
/// Returns: `String` — counts, average rating, average duration, rates.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Durations of zero
/// (no timer) are left out of the average.
String _window(List<IntimacyRecord> records, DateTime from, DateTime to) {
  final inWindow = records
      .where((r) => !r.datetime.isBefore(from) && r.datetime.isBefore(to))
      .toList();
  if (inWindow.isEmpty) return '0 entries';
  final solo = inWindow.where((r) => r.isSolo).length;
  final partnered = inWindow.length - solo;
  final rating =
      inWindow.map((r) => r.pleasureLevel).reduce((a, b) => a + b) /
      inWindow.length;
  final timed = inWindow.where((r) => r.duration.inSeconds > 0).toList();
  final parts = <String>[
    '${inWindow.length} entries ($partnered with a partner, $solo solo)',
    'average rating ${factNumber(rating)} of 5',
    if (timed.isNotEmpty)
      'average length ${factNumber(timed.map((r) => r.duration.inSeconds).reduce((a, b) => a + b) / timed.length / 60)} min',
    'climax in ${(100 * inWindow.where((r) => r.hadOrgasm).length / inWindow.length).round()}%',
  ];
  final withPartner = inWindow.where((r) => !r.isSolo).toList();
  if (withPartner.isNotEmpty) {
    parts.add(
      'protection used in '
      '${(100 * withPartner.where((r) => r.usedCondom).length / withPartner.length).round()}% of partnered',
    );
  }
  return parts.join(', ');
}

/// Purpose: Build the Intimacy card's facts, including the body condition.
/// Inputs: `now` — local time; `records`; `userBody`; `cycleRecords`;
/// `weightRecords` — for the user's own bust/waist/hip.
/// Returns: `InsightFacts?` — null when there are no records and no body
/// facts.
/// Side effects: None.
/// Notes: Only statistics are sent. Notes, locations, partner, toy and
/// position names, thrust counts, the porn flag and genital measurements
/// never are — both for privacy and to stay inside the on-device models'
/// acceptable-use rules. A cycle phase is sent only when the user tracks
/// their own cycle; predictions are estimates and the card says so.
InsightFacts? buildIntimacyInsightFacts({
  required DateTime now,
  required List<IntimacyRecord> records,
  required BodyProfile? userBody,
  required List<CycleRecord> cycleRecords,
  required List<WeightRecord> weightRecords,
}) {
  final today = dateOnly(now);
  final past = records.where((r) => !r.datetime.isAfter(now)).toList()
    ..sort((a, b) => a.datetime.compareTo(b.datetime));
  final lines = <String>['- Today: ${factDate(today)}'];
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final d30 = DateTime(today.year, today.month, today.day - 29);
  final d60 = DateTime(today.year, today.month, today.day - 59);
  final d90 = DateTime(today.year, today.month, today.day - 89);
  if (past.isNotEmpty) {
    lines
      ..add('- Last 30 days: ${_window(past, d30, tomorrow)}')
      ..add('- The 30 days before: ${_window(past, d60, d30)}')
      ..add(
        '- Last 90 days: '
        '${past.where((r) => !r.datetime.isBefore(d90)).length} entries',
      )
      ..add(
        '- Days since the last entry: '
        '${today.difference(dateOnly(past.last.datetime)).inDays}',
      );
  }

  // Body condition.
  final body = <String>[];
  final m = WeightData.effectiveMeasurementsUpTo(weightRecords, now);
  if (m.bustCm != null) body.add('bust ${factNumber(m.bustCm!)} cm');
  if (m.waistCm != null) body.add('waist ${factNumber(m.waistCm!)} cm');
  if (m.hipCm != null) body.add('hip ${factNumber(m.hipCm!)} cm');
  final underbust = userBody?.underbustCm;
  if (underbust != null && underbust > 0) {
    body.add('underbust ${factNumber(underbust)} cm');
    if (m.bustCm != null) {
      final bra = estimateBraSize(
        bustCm: m.bustCm!,
        underbustCm: underbust,
        standard: braStandardFromCode(userBody?.braStandard),
      );
      if (bra != null) body.add('estimated bra size ${bra.display}');
    }
  }
  final whr = WeightData.calculateWaistHipRatio(m.waistCm, m.hipCm);
  if (whr != null) body.add('waist-to-hip ratio ${factNumber(whr, 2)}');
  if (body.isNotEmpty) lines.add('- Body measurements: ${body.join(', ')}');

  var cycleSent = false;
  if (userBody != null && userBody.cycleEnabled) {
    final starts = cycleRecords
        .where((c) => c.personId == null)
        .map((c) => c.day)
        .toList();
    if (starts.isNotEmpty) {
      final prediction = predictCycle(
        actualStarts: starts,
        windowStart: DateTime(today.year, today.month, today.day - 1),
        windowEnd: DateTime(today.year, today.month, today.day + 60),
      );
      final info = prediction.days[today];
      final next = prediction.predictedStarts
          .where((d) => d.isAfter(today))
          .firstOrNull;
      final lastStart = starts.reduce((a, b) => a.isAfter(b) ? a : b);
      final parts = <String>[
        'typical cycle ${prediction.cycleLengthDays} days',
        'last recorded start ${factDate(lastStart)}',
        if (info != null) 'today is estimated ${info.phase.name} phase',
        if (info != null && info.inFertileWindow)
          'estimated fertile window',
        if (next != null)
          'next start estimated in ${next.difference(today).inDays} days',
      ];
      lines.add('- Cycle (estimate): ${parts.join(', ')}');
      cycleSent = true;
    }
  }

  if (past.isEmpty && body.isEmpty && !cycleSent) return null;

  return InsightFacts(
    module: InsightModule.intimacy,
    bucket: InsightTimeBucket.none,
    lines: lines,
    slots: [
      if (past.isNotEmpty) ...const [
        InsightSlot(
          'trend',
          'Describe the trend of the last 30 days compared with the 30 '
              'before.',
        ),
        InsightSlot(
          'advice',
          'One gentle, practical suggestion about wellbeing or safety.',
        ),
      ],
      if (body.isNotEmpty || cycleSent)
        InsightSlot(
          'body',
          cycleSent
              ? 'Sum up the body facts neutrally, mention the cycle phase, '
                    'and say that cycle predictions are estimates.'
              : 'Sum up the body facts neutrally.',
        ),
    ],
  );
}

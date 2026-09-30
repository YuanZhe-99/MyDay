import '../../ai/services/insight_prompts.dart';
import '../../weight/models/weight_record.dart';
import '../models/intimacy_record.dart';
import '../widgets/intimacy_trend_chart.dart'
    show IntimacyChartMetric, IntimacyChartRange;
import 'body_metrics.dart';
import 'cycle_predictor.dart';

/// Purpose: Format a share of a total as a whole percent.
/// Inputs: `part`; `total` — must be positive.
/// Returns: `int`.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
int _pct(int part, int total) => (100 * part / total).round();

/// Purpose: Average the non-null values a reader returns.
/// Inputs: `records`; `value`.
/// Returns: `double?` — null when no record has a value.
/// Side effects: None.
/// Notes: Internal helper used within this file only.
double? _avg(
  Iterable<IntimacyRecord> records,
  double? Function(IntimacyRecord r) value,
) {
  var sum = 0.0;
  var n = 0;
  for (final r in records) {
    final v = value(r);
    if (v == null) continue;
    sum += v;
    n++;
  }
  return n == 0 ? null : sum / n;
}

/// Purpose: Read a record's timed length in minutes.
/// Inputs: `r`.
/// Returns: `double?` — null when no timer was used.
/// Side effects: None.
/// Notes: Same rule as the trend chart's duration metric.
double? _minutes(IntimacyRecord r) =>
    r.duration.inSeconds > 0 ? r.duration.inSeconds / 60.0 : null;

/// Purpose: Read a record's rating for the chart's pleasure metric.
/// Inputs: `r`.
/// Returns: `double?` — null for a non-positive rating.
/// Side effects: None.
/// Notes: Same rule as the trend chart's pleasure metric.
double? _rating(IntimacyRecord r) =>
    r.pleasureLevel > 0 ? r.pleasureLevel.toDouble() : null;

/// Purpose: Summarize the records in one window.
/// Inputs: `records`, `from` (inclusive), `to` (exclusive); `detailed` —
/// false for the v1.5.2 wording.
/// Returns: `String` — counts, average rating, average duration, rates and,
/// when `detailed`, the porn-watched share and the thrust count and rate
/// when recorded.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Durations of zero
/// (no timer) and missing thrust counts are left out of their averages.
String _window(
  List<IntimacyRecord> records,
  DateTime from,
  DateTime to, {
  required bool detailed,
}) {
  final inWindow = records
      .where((r) => !r.datetime.isBefore(from) && r.datetime.isBefore(to))
      .toList();
  if (inWindow.isEmpty) return '0 entries';
  final solo = inWindow.where((r) => r.isSolo).length;
  final partnered = inWindow.length - solo;
  final rating = _avg(inWindow, (r) => r.pleasureLevel.toDouble())!;
  final length = _avg(inWindow, _minutes);
  final thrusts = _avg(inWindow, (r) => r.resolvedThrustCount);
  final rate = _avg(inWindow, (r) => r.thrustsPerMinute);
  final n = inWindow.length;
  final parts = <String>[
    '$n entries ($partnered with a partner, $solo solo)',
    'average rating ${factNumber(rating)} of 5',
    if (length != null) 'average length ${factNumber(length)} min',
    'climax in ${_pct(inWindow.where((r) => r.hadOrgasm).length, n)}%',
    if (detailed) ...[
      'porn watched in '
          '${_pct(inWindow.where((r) => r.watchedPorn).length, n)}%',
      if (thrusts != null) 'average thrust count ${factNumber(thrusts, 0)}',
      if (rate != null) 'average thrust rate ${factNumber(rate, 0)}/min',
    ],
  ];
  final withPartner = inWindow.where((r) => !r.isSolo).toList();
  if (withPartner.isNotEmpty) {
    final used = withPartner.where((r) => r.usedCondom).length;
    parts.add(
      'protection used in ${_pct(used, withPartner.length)}% of partnered',
    );
  }
  return parts.join(', ');
}

/// Purpose: Describe one metric of the trend chart over its visible span.
/// Inputs: `metric`; `visible` — records in the span, oldest first;
/// `start`, `mid`, `end` — the span and the point splitting it in halves.
/// Returns: `String` — the metric name, its overall figure and the figure
/// for each half, or `no data`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Per-record values use
/// the chart's own extractors; frequency is entries per week of span.
String _chartMetric(
  IntimacyChartMetric metric,
  List<IntimacyRecord> visible,
  DateTime start,
  DateTime mid,
  DateTime end,
) {
  final first = visible.where((r) => r.datetime.isBefore(mid)).toList();
  final second = visible.where((r) => !r.datetime.isBefore(mid)).toList();
  if (metric == IntimacyChartMetric.frequency) {
    /// Purpose: Entries per week over a span.
    /// Inputs: `n`; `a`, `b` — the span.
    /// Returns: `double`.
    /// Side effects: None.
    /// Notes: Spans shorter than one day count as one day.
    double perWeek(int n, DateTime a, DateTime b) {
      final days = b.difference(a).inHours / 24;
      return n / ((days < 1 ? 1 : days) / 7);
    }

    return 'frequency ${factNumber(perWeek(visible.length, start, end))}'
        '/week (first half ${factNumber(perWeek(first.length, start, mid))}, '
        'second half ${factNumber(perWeek(second.length, mid, end))})';
  }
  final (
    String name,
    String unit,
    int digits,
    double? Function(IntimacyRecord) read,
  ) = switch (metric) {
    IntimacyChartMetric.pleasure => ('rating', ' of 5', 1, _rating),
    IntimacyChartMetric.duration => ('length', ' min', 0, _minutes),
    IntimacyChartMetric.thrustCount => (
      'thrust count',
      '',
      0,
      (IntimacyRecord r) => r.resolvedThrustCount,
    ),
    IntimacyChartMetric.thrustRate => (
      'thrust rate',
      '/min',
      0,
      (IntimacyRecord r) => r.thrustsPerMinute,
    ),
    IntimacyChartMetric.frequency => throw StateError('handled above'),
  };

  /// Purpose: Format one average with the metric's unit.
  /// Inputs: `v`.
  /// Returns: `String` — `no data` for null.
  /// Side effects: None.
  /// Notes: None.
  String fmt(double? v) =>
      v == null ? 'no data' : '${factNumber(v, digits)}$unit';
  final all = _avg(visible, read);
  if (all == null) return '$name no data';
  return '$name average ${fmt(all)} '
      '(first half ${fmt(_avg(first, read))}, '
      'second half ${fmt(_avg(second, read))})';
}

/// Purpose: Summarize the trend chart exactly as the user has set it up.
/// Inputs: `sorted` — past records, oldest first; `settings` — the
/// persisted chart selection; `now`.
/// Returns: `String?` — one fact line, or null when fewer than two records
/// fall in the chosen range (the chart's own empty state).
/// Side effects: None.
/// Notes: Unknown range or metric ids fall back to the defaults the chart
/// widget uses, so the card and the chart always describe the same view.
String? _chartSummary(
  List<IntimacyRecord> sorted,
  IntimacyChartSettings settings,
  DateTime now,
) {
  final range =
      IntimacyChartRange.fromId(settings.range) ??
      IntimacyChartRange.fromId(IntimacyChartSettings.defaultRange)!;
  var ids = settings.metrics.toSet();
  var metrics = IntimacyChartMetric.values
      .where((m) => ids.contains(m.id))
      .toList();
  if (metrics.isEmpty) {
    ids = IntimacyChartSettings.defaultMetrics.toSet();
    metrics = IntimacyChartMetric.values
        .where((m) => ids.contains(m.id))
        .toList();
  }
  final cutoff = range.cutoffFrom(now);
  final visible = sorted.where((r) => !r.datetime.isBefore(cutoff)).toList();
  if (visible.length < 2) return null;
  final start = range == IntimacyChartRange.all
      ? visible.first.datetime
      : cutoff;
  final mid = start.add(
    Duration(milliseconds: now.difference(start).inMilliseconds ~/ 2),
  );
  final label = switch (range) {
    IntimacyChartRange.oneWeek => 'last week',
    IntimacyChartRange.oneMonth => 'last month',
    IntimacyChartRange.threeMonths => 'last 3 months',
    IntimacyChartRange.sixMonths => 'last 6 months',
    IntimacyChartRange.oneYear => 'last year',
    IntimacyChartRange.all => 'all time since ${factDate(start)}',
  };
  final parts = [
    for (final m in metrics) _chartMetric(m, visible, start, mid, now),
  ];
  return '- Chart being viewed ($label, ${visible.length} entries): '
      '${parts.join('; ')}';
}

/// Purpose: Rank ids by how often they occur, most frequent first.
/// Inputs: `counts` — id to count; `firstSeen` — id to its earliest use.
/// Returns: `List<String>` — ids, ties broken by earliest use, then id.
/// Side effects: None.
/// Notes: Internal helper used within this file only. The rank decides the
/// anonymous label (`partner A`, `toy 1`), so it must be deterministic.
List<String> _ranked(Map<String, int> counts, Map<String, DateTime> firstSeen) {
  return counts.keys.toList()..sort((a, b) {
    final byCount = counts[b]!.compareTo(counts[a]!);
    if (byCount != 0) return byCount;
    final byDate = firstSeen[a]!.compareTo(firstSeen[b]!);
    return byDate != 0 ? byDate : a.compareTo(b);
  });
}

/// Purpose: Describe how often labelled items were used.
/// Inputs: `recent` — records, oldest first; `noun` — `toy` or `position`;
/// `ids` — reader for a record's item ids; `validIds` — ids that exist.
/// Returns: `String?` — null when none was used.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Items are labelled
/// `<noun> 1`, `<noun> 2`, … by use, at most five.
String? _usage(
  List<IntimacyRecord> recent,
  String noun,
  List<String> Function(IntimacyRecord r) ids,
  Set<String> validIds,
) {
  final counts = <String, int>{};
  final firstSeen = <String, DateTime>{};
  var withAny = 0;
  for (final r in recent) {
    final used = ids(r).where(validIds.contains).toSet();
    if (used.isEmpty) continue;
    withAny++;
    for (final id in used) {
      counts[id] = (counts[id] ?? 0) + 1;
      firstSeen.putIfAbsent(id, () => r.datetime);
    }
  }
  if (withAny == 0) return null;
  final order = _ranked(counts, firstSeen).take(_maxListed).toList();
  final items = [
    for (var i = 0; i < order.length; i++)
      '$noun ${i + 1} ${counts[order[i]]} times',
  ];
  return 'used in ${_pct(withAny, recent.length)}% of entries in the last '
      '90 days: ${items.join(', ')}';
}

/// The most partners, toys or positions listed on one fact line.
const int _maxListed = 5;

/// Purpose: Describe partners, toys and positions with anonymous labels.
/// Inputs: `recent` — past records of the last 90 days, oldest first;
/// `today`; `now`; `partners`; `toys`; `positions`.
/// Returns: `List<String>` — zero to four fact lines.
/// Side effects: None.
/// Notes: Internal helper used within this file only. Names, emoji, images,
/// prices and links are never read; each partner is `partner A`,
/// `partner B`, … by 90-day entries, at most five. Partnered records whose
/// partner is unset or deleted count as `unspecified partner`.
List<String> _companions(
  List<IntimacyRecord> recent,
  DateTime today,
  DateTime now,
  List<Partner> partners,
  List<Toy> toys,
  List<Position> positions,
) {
  final lines = <String>[];
  if (partners.isNotEmpty) {
    final active = partners
        .where((p) => p.endDate == null || p.endDate!.isAfter(now))
        .length;
    lines.add('- Partners: ${partners.length} on record, $active active');
  }
  final known = {for (final p in partners) p.id};
  final byPartner = <String, List<IntimacyRecord>>{};
  for (final r in recent.where((r) => !r.isSolo)) {
    final id = known.contains(r.partnerId) ? r.partnerId! : '';
    byPartner.putIfAbsent(id, () => []).add(r);
  }
  if (byPartner.isNotEmpty) {
    final order = _ranked(
      {for (final e in byPartner.entries) e.key: e.value.length},
      {for (final e in byPartner.entries) e.key: e.value.first.datetime},
    );
    var letter = 0;
    final parts = <String>[];
    for (final id in order.take(_maxListed)) {
      final rs = byPartner[id]!;
      final name = id.isEmpty
          ? 'unspecified partner'
          : 'partner ${String.fromCharCode(0x41 + letter++)}';
      final rating = _avg(rs, (r) => r.pleasureLevel.toDouble())!;
      final ago = today.difference(dateOnly(rs.last.datetime)).inDays;
      parts.add(
        '$name ${rs.length} entries, average rating ${factNumber(rating)}, '
        'climax ${_pct(rs.where((r) => r.hadOrgasm).length, rs.length)}%, '
        'protection ${_pct(rs.where((r) => r.usedCondom).length, rs.length)}%, '
        'last $ago days ago',
      );
    }
    lines.add('- Partners in the last 90 days: ${parts.join('; ')}');
  }

  final toyUse = _usage(recent, 'toy', (r) => r.toyIds, {
    for (final t in toys) t.id,
  });
  if (toys.isNotEmpty) {
    final active = toys
        .where((t) => t.retiredDate == null || t.retiredDate!.isAfter(now))
        .length;
    lines.add(
      '- Toys: ${toys.length} on record, $active in use; '
      '${toyUse ?? 'none used in the last 90 days'}',
    );
  }
  final positionUse = _usage(recent, 'position', (r) => r.positionIds, {
    for (final p in positions) p.id,
  });
  if (positionUse != null) lines.add('- Positions: $positionUse');
  return lines;
}

/// Purpose: Build the Intimacy card's facts: trend, the chart being viewed,
/// partners, toys and positions, and the body condition.
/// Inputs: `now` — local time; `records`; `userBody`; `cycleRecords`;
/// `weightRecords` — for the user's own bust/waist/hip; `partners`, `toys`,
/// `positions` — for anonymous per-item statistics; `chartSettings` — the
/// trend chart's persisted metric and range selection.
/// Returns: `InsightFacts?` — null when there are no records and no body
/// facts. Slots, each only when its facts exist: `trend`, `chart`,
/// `advice`, `partners`, `body`.
/// Side effects: None.
/// Notes: Only statistics are sent. Notes, locations, partner, toy and
/// position names (and emoji, images, prices, links) and genital
/// measurements never are; partners, toys and positions appear only as
/// `partner A`, `toy 1`, `position 1`. Thrust figures and the porn-watched
/// share are sent since v1.5.3. A cycle phase is sent only when the user
/// tracks their own cycle; predictions are estimates and the card says so.
/// The page pairs this with [buildIntimacyFallbackInsightFacts].
InsightFacts? buildIntimacyInsightFacts({
  required DateTime now,
  required List<IntimacyRecord> records,
  required BodyProfile? userBody,
  required List<CycleRecord> cycleRecords,
  required List<WeightRecord> weightRecords,
  required List<Partner> partners,
  required List<Toy> toys,
  required List<Position> positions,
  required IntimacyChartSettings chartSettings,
}) => _intimacyFacts(
  now: now,
  records: records,
  userBody: userBody,
  cycleRecords: cycleRecords,
  weightRecords: weightRecords,
  partners: partners,
  toys: toys,
  positions: positions,
  chartSettings: chartSettings,
  detailed: true,
);

/// Purpose: Build the Intimacy card's fallback facts: the v1.5.2 prompt.
/// Inputs: `now` — local time; `records`; `userBody`; `cycleRecords`;
/// `weightRecords`.
/// Returns: `InsightFacts?` — null when there are no records and no body
/// facts. Slots `trend`, `advice` and `body`, each only when its facts
/// exist.
/// Side effects: None.
/// Notes: Sent once, as `AiInsightRequest.fallbackFacts`, only when the model
/// declines the detailed facts or answers nothing usable. No chart line, no
/// partner, toy or position lines, no thrust figures and no porn-watched
/// share: exactly what v1.5.2 sent. A refusal of these too is cached as
/// skipped and the card says *declined*.
InsightFacts? buildIntimacyFallbackInsightFacts({
  required DateTime now,
  required List<IntimacyRecord> records,
  required BodyProfile? userBody,
  required List<CycleRecord> cycleRecords,
  required List<WeightRecord> weightRecords,
}) => _intimacyFacts(
  now: now,
  records: records,
  userBody: userBody,
  cycleRecords: cycleRecords,
  weightRecords: weightRecords,
  partners: const [],
  toys: const [],
  positions: const [],
  chartSettings: const IntimacyChartSettings(),
  detailed: false,
);

/// Purpose: Build either version of the Intimacy card's facts.
/// Inputs: as [buildIntimacyInsightFacts], plus `detailed` — true for the
/// v1.5.3 facts, false for the v1.5.2 facts.
/// Returns: `InsightFacts?`.
/// Side effects: None.
/// Notes: Internal helper used within this file only. With `detailed`
/// false, `partners`, `toys`, `positions` and `chartSettings` are ignored.
InsightFacts? _intimacyFacts({
  required DateTime now,
  required List<IntimacyRecord> records,
  required BodyProfile? userBody,
  required List<CycleRecord> cycleRecords,
  required List<WeightRecord> weightRecords,
  required List<Partner> partners,
  required List<Toy> toys,
  required List<Position> positions,
  required IntimacyChartSettings chartSettings,
  required bool detailed,
}) {
  final today = dateOnly(now);
  final past = records.where((r) => !r.datetime.isAfter(now)).toList()
    ..sort((a, b) => a.datetime.compareTo(b.datetime));
  final lines = <String>['- Today: ${factDate(today)}'];
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final d30 = DateTime(today.year, today.month, today.day - 29);
  final d60 = DateTime(today.year, today.month, today.day - 59);
  final d90 = DateTime(today.year, today.month, today.day - 89);
  String? chart;
  var companions = const <String>[];
  if (past.isNotEmpty) {
    final recent = past.where((r) => !r.datetime.isBefore(d90)).toList();
    lines
      ..add(
        '- Last 30 days: '
        '${_window(past, d30, tomorrow, detailed: detailed)}',
      )
      ..add(
        '- The 30 days before: '
        '${_window(past, d60, d30, detailed: detailed)}',
      )
      ..add('- Last 90 days: ${recent.length} entries')
      ..add(
        '- Days since the last entry: '
        '${today.difference(dateOnly(past.last.datetime)).inDays}',
      );
    if (detailed) {
      chart = _chartSummary(past, chartSettings, now);
      if (chart != null) lines.add(chart);
      companions = _companions(recent, today, now, partners, toys, positions);
      lines.addAll(companions);
    }
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
        if (info != null && info.inFertileWindow) 'estimated fertile window',
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
      if (past.isNotEmpty)
        const InsightSlot(
          'trend',
          'Describe the trend of the last 30 days compared with the 30 '
              'before.',
        ),
      if (chart != null)
        const InsightSlot(
          'chart',
          'Describe what the chart being viewed shows for its metrics, '
              'first half against second half.',
        ),
      if (past.isNotEmpty)
        const InsightSlot(
          'advice',
          'One gentle, practical suggestion about wellbeing or safety.',
        ),
      if (companions.isNotEmpty)
        const InsightSlot(
          'partners',
          'Sum up the partner, toy and position facts neutrally, using the '
              'labels given.',
        ),
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

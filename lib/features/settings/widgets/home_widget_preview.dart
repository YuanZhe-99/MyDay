import 'package:flutter/material.dart';
import 'package:myapps_widget_ui/myapps_widget_ui.dart';

import '../../../shared/services/home_widget_payloads.dart';
import '../../../shared/services/home_widget_service.dart';

/// Live preview of one home-screen widget kind on the widget settings page.
///
/// It draws the 2×2 widget from the same payload the native widget receives
/// (built by `HomeWidgetService.payloadBuilders` from the real data), with
/// text sizes times the kind's text scale and its privacy choice applied.
/// It approximates the native widgets in the app's colors; it is not a pixel
/// copy of either platform.
class HomeWidgetPreview extends StatelessWidget {
  /// Purpose: Create a preview.
  /// Inputs: `kind`; `payload` — the unmasked payload, or null when the kind
  /// has no envelope (Intimacy hidden) or nothing loaded yet; `settings`.
  /// Returns: A new `HomeWidgetPreview`.
  /// Side effects: None.
  /// Notes: None.
  const HomeWidgetPreview({
    super.key,
    required this.kind,
    required this.payload,
    required this.settings,
  });

  final String kind;
  final Map<String, dynamic>? payload;
  final HomeWidgetKindSettings settings;

  /// Factor the 2×2 card is drawn at; at 1.0 it looked larger than on most
  /// home screens.
  static const double displayScale = 0.85;

  /// Purpose: Build the preview card.
  /// Inputs: `context`.
  /// Returns: The card, centered and scaled.
  /// Side effects: None.
  /// Notes: *Icon only* and a missing payload draw the neutral placeholder.
  @override
  Widget build(BuildContext context) {
    const side = WidgetPreviewSurface.smallSide;
    final p = payload;
    final Widget content;
    if (p == null || settings.privacy == HomeWidgetPrivacyChoice.iconOnly) {
      content = const _Placeholder();
    } else {
      final mask = settings.privacy == HomeWidgetPrivacyChoice.maskValues;
      final t = _Text(Theme.of(context), settings.textScale, mask);
      content = switch (kind) {
        HomeWidgetService.todoKind => _todo(p, t),
        HomeWidgetService.weightKind => _weight(p, t),
        HomeWidgetService.financeKind => _finance(p, t),
        HomeWidgetService.intimacyKind => _intimacy(p, t),
        _ => _timer(p, t),
      };
    }
    return Center(
      child: SizedBox(
        width: side * displayScale,
        height: side * displayScale,
        child: FittedBox(
          child: WidgetPreviewSurface(
            width: side,
            height: side,
            child: content,
          ),
        ),
      ),
    );
  }

  /// Purpose: Draw the Todo widget.
  /// Inputs: `p` — payload; `t` — text helper.
  /// Returns: The card content.
  /// Side effects: None.
  /// Notes: Shows today's day entry, as the native widget does.
  Widget _todo(Map<String, dynamic> p, _Text t) {
    final labels = _labels(p);
    final days = (p['days'] as List?) ?? const [];
    final today = HomeWidgetPayloads.dayKey(DateTime.now());
    final day =
        days.whereType<Map>().where((d) => d['date'] == today).firstOrNull ??
        const {};
    final items = ((day['items'] as List?) ?? const []).whereType<Map>();
    final open = items.where((i) => i['done'] != true).toList();
    final total = items.length;
    final done = total - open.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(t, Icons.checklist, '${day['label'] ?? ''}', labels['new']),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            t.big(open.isEmpty ? '✓' : '${open.length}', mask: false),
            const SizedBox(width: 6),
            Flexible(
              child: t.small(
                _fill(labels['progress'], '$done', '$total'),
                mask: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: total == 0 ? 0 : done / total),
        const SizedBox(height: 4),
        if (open.isEmpty)
          t.small(total == 0 ? labels['nothing'] : labels['allDone'])
        else
          for (final item in open.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_box_outline_blank,
                    size: 14 * t.scale,
                    color: item['late'] == true
                        ? t.theme.colorScheme.error
                        : null,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: t.body(
                      '${item['e'] ?? ''} ${item['t'] ?? ''}'.trim(),
                    ),
                  ),
                  if ('${item['time']}'.isNotEmpty)
                    t.small('${item['time']}', mask: false),
                ],
              ),
            ),
      ],
    );
  }

  /// Purpose: Draw the Weight widget.
  /// Inputs: `p`, `t`.
  /// Returns: The card content.
  /// Side effects: None.
  /// Notes: The sparkline is a simple polyline of `points`.
  Widget _weight(Map<String, dynamic> p, _Text t) {
    final labels = _labels(p);
    final latest = p['latest'] as Map?;
    final change = (p['change30'] as num?)?.toDouble();
    final bmi = p['bmi'] as num?;
    final points = ((p['points'] as List?) ?? const [])
        .whereType<num>()
        .map((n) => n.toDouble())
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          t,
          Icons.monitor_weight_outlined,
          labels['title'],
          labels['log'],
        ),
        const SizedBox(height: 6),
        if (latest == null)
          t.body(labels['noData'])
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              t.big((latest['kg'] as num).toStringAsFixed(1)),
              const SizedBox(width: 4),
              t.small(labels['unit'], mask: false),
            ],
          ),
          t.small(
            [
              if (change != null) '${labels['change30']} ${_signed(change)}',
              if (bmi != null) 'BMI ${bmi.toStringAsFixed(1)}',
            ].join(' · '),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: t.mask
                ? const SizedBox.shrink()
                : CustomPaint(
                    size: Size.infinite,
                    painter: _SparkPainter(points, t.theme.colorScheme.primary),
                  ),
          ),
        ],
      ],
    );
  }

  /// Purpose: Draw the Finance widget.
  /// Inputs: `p`, `t`.
  /// Returns: The card content.
  /// Side effects: None.
  /// Notes: Shows the first bill, or the "no bills" line.
  Widget _finance(Map<String, dynamic> p, _Text t) {
    final labels = _labels(p);
    final bills = ((p['bills'] as List?) ?? const []).whereType<Map>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          t,
          Icons.account_balance_wallet_outlined,
          '${p['monthLabel'] ?? ''}',
          labels['add'],
        ),
        const SizedBox(height: 6),
        t.small(labels['expense'], mask: false),
        t.big('${p['expense'] ?? ''}'),
        t.small(
          '${labels['income']} ${t.value('${p['income'] ?? ''}')} · '
          '${labels['net']} ${t.value('${p['net'] ?? ''}')}',
          mask: false,
        ),
        const Spacer(),
        if (bills.isEmpty)
          t.small(labels['noBills'], mask: false)
        else
          t.small(
            '${bills.first['name']} ${bills.first['date']} '
            '${t.value('${bills.first['amount']}')}',
            mask: false,
          ),
      ],
    );
  }

  /// Purpose: Draw the Private widget.
  /// Inputs: `p`, `t`.
  /// Returns: The card content.
  /// Side effects: None.
  /// Notes: Days are counted by local calendar day.
  Widget _intimacy(Map<String, dynamic> p, _Text t) {
    final labels = _labels(p);
    final lastAt = p['lastAt'] as num?;
    final today = DateUtils.dateOnly(DateTime.now());
    final days = lastAt == null
        ? null
        : today
              .difference(
                DateUtils.dateOnly(
                  DateTime.fromMillisecondsSinceEpoch(lastAt.toInt()),
                ),
              )
              .inDays;
    final avg = p['avgMinutes'];
    final cycle = DateTime.tryParse('${p['cycleNext'] ?? ''}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(t, Icons.lock_outline, labels['title'], labels['add']),
        const SizedBox(height: 6),
        if (days == null)
          t.body(labels['noData'])
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              t.big(days == 0 ? labels['today'] : '$days'),
              const SizedBox(width: 4),
              if (days > 0) t.small(labels['daysAgo'], mask: false),
            ],
          ),
        t.small(
          [
            _fill(labels['month'], '${p['monthCount'] ?? 0}'),
            if (avg != null) _fill(labels['avg'], '$avg'),
          ].join(' · '),
        ),
        const Spacer(),
        if (cycle != null)
          t.small(
            cycle.difference(today).inDays <= 0
                ? labels['cycleToday']
                : _fill(labels['cycleIn'], '${cycle.difference(today).inDays}'),
          ),
      ],
    );
  }

  /// Purpose: Draw the Timer widget.
  /// Inputs: `p`, `t`.
  /// Returns: The card content.
  /// Side effects: None.
  /// Notes: Static; the native widget counts up while running.
  Widget _timer(Map<String, dynamic> p, _Text t) {
    final labels = _labels(p);
    final session = p['session'] as Map?;
    final running = session?['running'] == true;
    var elapsed = Duration(
      milliseconds: (session?['accumulatedMs'] as num?)?.toInt() ?? 0,
    );
    final startedAt = session?['startedAt'] as num?;
    if (running && startedAt != null) {
      elapsed += DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(startedAt.toInt()),
      );
    }
    String clock(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
    }

    Widget button(String? label, {bool primary = false}) => Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary
              ? t.theme.colorScheme.primaryContainer
              : t.theme.colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: t.small(label, mask: false),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          t,
          Icons.timer_outlined,
          labels['title'],
          session == null
              ? null
              : (running ? labels['running'] : labels['paused']),
        ),
        const SizedBox(height: 6),
        t.big(session == null ? '00:00' : clock(elapsed)),
        t.small(
          session == null
              ? labels['idle']
              : _fill(labels['count'], '${session['count'] ?? 0}'),
        ),
        const Spacer(),
        Row(
          children: session == null
              ? [button(labels['start'], primary: true)]
              : [
                  button(running ? labels['pause'] : labels['resume']),
                  if (running) button('+${p['step'] ?? 100}', primary: true),
                  button(labels['finish']),
                ],
        ),
      ],
    );
  }

  /// Purpose: Draw a card header: icon, title and an action pill.
  /// Inputs: `t`; `icon`; `title`; `pill` or null.
  /// Returns: A row.
  /// Side effects: None.
  /// Notes: None.
  Widget _header(_Text t, IconData icon, String? title, String? pill) => Row(
    children: [
      Icon(icon, size: 14 * t.scale),
      const SizedBox(width: 4),
      Expanded(child: t.small(title, mask: false)),
      if (pill != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: t.theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(99),
          ),
          child: t.small(pill, mask: false),
        ),
    ],
  );

  /// Purpose: Read a payload's labels.
  /// Inputs: `p`.
  /// Returns: Label strings by key.
  /// Side effects: None.
  /// Notes: None.
  static Map<String, String> _labels(Map<String, dynamic> p) => {
    for (final e in ((p['labels'] as Map?) ?? const {}).entries)
      '${e.key}': '${e.value}',
  };

  /// Purpose: Replace `{n}` and `{m}` in a label.
  /// Inputs: `label`; `n`; optional `m`.
  /// Returns: The filled label.
  /// Side effects: None.
  /// Notes: Same placeholders as the native renderers.
  static String _fill(String? label, String n, [String m = '']) =>
      (label ?? '').replaceAll('{n}', n).replaceAll('{m}', m);

  /// Purpose: Format a signed one-decimal change with a real minus sign.
  /// Inputs: `v`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: None.
  static String _signed(double v) =>
      '${v < 0 ? '−' : '+'}${v.abs().toStringAsFixed(1)}';
}

/// Scaled, optionally masked text styles for one preview.
class _Text {
  /// Purpose: Hold the preview's theme, scale and mask flag.
  /// Inputs: `theme`, `scale`, `mask`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: None.
  _Text(this.theme, this.scale, this.mask);

  final ThemeData theme;
  final double scale;
  final bool mask;

  /// Purpose: Return a value, masked when values are hidden.
  /// Inputs: `v`.
  /// Returns: `v` or `••••`.
  /// Side effects: None.
  /// Notes: Mirrors the native `mask` rule.
  String value(String v) => mask ? '••••' : v;

  /// Purpose: Build a large number.
  /// Inputs: `s`; `mask` — whether it is a value (default true).
  /// Returns: A `Text`.
  /// Side effects: None.
  /// Notes: None.
  Widget big(String? s, {bool mask = true}) => Text(
    mask ? value(s ?? '') : (s ?? ''),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(fontSize: 28 * scale, fontWeight: FontWeight.w600),
  );

  /// Purpose: Build a body line.
  /// Inputs: `s`.
  /// Returns: A `Text`.
  /// Side effects: None.
  /// Notes: Titles are never masked.
  Widget body(String? s) => Text(
    s ?? '',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(fontSize: 13 * scale),
  );

  /// Purpose: Build a secondary line.
  /// Inputs: `s`; `mask` — whether it holds values (default true).
  /// Returns: A `Text`.
  /// Side effects: None.
  /// Notes: Masks digits only, keeping words readable.
  Widget small(String? s, {bool mask = true}) => Text(
    mask && this.mask
        ? (s ?? '').replaceAll(RegExp(r'[0-9.,]+'), '••')
        : s ?? '',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: 11.5 * scale,
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}

/// The neutral placeholder drawn for *Icon only* and missing envelopes.
class _Placeholder extends StatelessWidget {
  /// Purpose: Create the placeholder.
  /// Inputs: None.
  /// Returns: A new `_Placeholder`.
  /// Side effects: None.
  /// Notes: None.
  const _Placeholder();

  /// Purpose: Build the placeholder.
  /// Inputs: `context`.
  /// Returns: An icon over "MyDay".
  /// Side effects: None.
  /// Notes: None.
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(Icons.lock_outline, size: 28), Text('MyDay')],
    ),
  );
}

/// Draws the weight sparkline.
class _SparkPainter extends CustomPainter {
  /// Purpose: Create the painter.
  /// Inputs: `points` — weights, oldest first; `color`.
  /// Returns: None.
  /// Side effects: None.
  /// Notes: None.
  _SparkPainter(this.points, this.color);

  final List<double> points;
  final Color color;

  /// Purpose: Paint the polyline.
  /// Inputs: `canvas`, `size`.
  /// Returns: None.
  /// Side effects: Draws on `canvas`.
  /// Notes: Fewer than two points draws nothing.
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final lo = points.reduce((a, b) => a < b ? a : b);
    final hi = points.reduce((a, b) => a > b ? a : b);
    final span = hi - lo == 0 ? 1 : hi - lo;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height * (1 - (points[i] - lo) / span);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// Purpose: Repaint when the data changes.
  /// Inputs: `old`.
  /// Returns: `bool`.
  /// Side effects: None.
  /// Notes: None.
  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.points != points || old.color != color;
}

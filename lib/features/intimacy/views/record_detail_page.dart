import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/image_service.dart';
import '../../../shared/utils/adaptive_layout.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../models/intimacy_record.dart';
import '../widgets/thrust_timeline_chart.dart';

/// Opens the record editor and saves the result; returns the saved record, or
/// null when the editor was cancelled.
typedef RecordEditCallback =
    Future<IntimacyRecord?> Function(IntimacyRecord record);

/// Removes the record and saves the change.
typedef RecordDeleteCallback = Future<void> Function(IntimacyRecord record);

/// Read-only view of one intimacy record, with edit and delete actions.
class RecordDetailPage extends StatefulWidget {
  final IntimacyRecord record;
  final List<Partner> partners;
  final List<Toy> toys;
  final List<Position> positions;
  final RecordEditCallback onEdit;
  final RecordDeleteCallback onDelete;

  /// Purpose: Create a record detail page.
  /// Inputs: `record`; full `partners`, `toys` and `positions` lists for name
  /// lookup; `onEdit` and `onDelete`, which the caller implements with its own
  /// editor and save path.
  /// Returns: A new `RecordDetailPage` instance.
  /// Side effects: None.
  /// Notes: Pass every partner and toy, including ended and retired ones, so
  /// old records still show their names.
  const RecordDetailPage({
    super.key,
    required this.record,
    required this.partners,
    required this.toys,
    required this.positions,
    required this.onEdit,
    required this.onDelete,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: None.
  /// Notes: None.
  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  late IntimacyRecord _record;

  /// Purpose: Take the initial record from the widget.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Sets `_record`.
  /// Notes: The page keeps its own copy so an edit re-renders in place.
  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  /// Purpose: Edit the record through the caller and show the result.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Opens the caller's editor; updates `_record` on save.
  /// Notes: None.
  Future<void> _edit() async {
    final updated = await widget.onEdit(_record);
    if (updated != null && mounted) setState(() => _record = updated);
  }

  /// Purpose: Confirm, delete the record through the caller, and close.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: Shows the shared delete confirmation; deletes; pops.
  /// Notes: None.
  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmDelete(context, l10n.commonThisRecord);
    if (!confirmed || !mounted) return;
    await widget.onDelete(_record);
    if (mounted) Navigator.of(context).pop();
  }

  /// Purpose: Format a duration as `HH:MM:SS`.
  /// Inputs: `d`.
  /// Returns: `String`.
  /// Side effects: None.
  /// Notes: Matches the timer page, so timer-made records read the same.
  static String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Purpose: Build the page.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current record.
  /// Side effects: None.
  /// Notes: Width-capped at `readingMaxContentWidth`; no split layout. The
  /// thrust chart only appears for records with at least two timer presses.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final record = _record;
    final partner = record.partnerId == null
        ? null
        : widget.partners.where((p) => p.id == record.partnerId).firstOrNull;
    final toys = record.toyIds
        .map((id) => widget.toys.where((t) => t.id == id).firstOrNull)
        .whereType<Toy>()
        .toList();
    final positions = record.positionIds
        .map((id) => widget.positions.where((p) => p.id == id).firstOrNull)
        .whereType<Position>()
        .toList();
    final rate = record.thrustsPerMinute;
    final notRecorded = l10n.intimacyNotRecorded;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.intimacyRecordDetail),
        actions: [
          IconButton(
            tooltip: l10n.commonEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
          IconButton(
            tooltip: l10n.commonDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: readingMaxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderCard(record: record, partner: partner),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatTile(
                      icon: Icons.timer_outlined,
                      label: l10n.intimacyDuration,
                      value: _formatDuration(record.duration),
                    ),
                    _StatTile(
                      icon: Icons.swap_horiz,
                      label: l10n.intimacyThrustCount,
                      value: (record.thrustCount ?? 0) > 0
                          ? '${record.thrustCount} x${record.thrustCountUnit}'
                          : notRecorded,
                    ),
                    _StatTile(
                      icon: Icons.speed,
                      label: l10n.intimacyThrustRate,
                      value: rate == null
                          ? notRecorded
                          : '${rate.toStringAsFixed(0)}/min',
                    ),
                  ],
                ),
                if (record.hasThrustTimeline) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.intimacyThrustTimeline,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          ThrustTimelineChart(
                            timeline: record.thrustTimeline!,
                            duration: record.duration,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (toys.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: l10n.intimacyToys,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final t in toys) _ToyChip(toy: t)],
                    ),
                  ),
                ],
                if (positions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: l10n.intimacyPositions,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in positions)
                          Chip(
                            label: Text(
                              p.emoji != null ? '${p.emoji} ${p.name}' : p.name,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _FlagTile(
                        icon: Icons.favorite_outline,
                        label: l10n.intimacyOrgasmStatus,
                        value: record.hadOrgasm,
                      ),
                      _FlagTile(
                        icon: Icons.ondemand_video,
                        label: l10n.intimacyWatchedPornStatus,
                        value: record.watchedPorn,
                      ),
                      _FlagTile(
                        icon: Icons.health_and_safety_outlined,
                        label: l10n.intimacyUsedCondomStatus,
                        value: record.usedCondom,
                      ),
                    ],
                  ),
                ),
                if (record.location != null) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: l10n.intimacyDetailLocation,
                    child: Text(record.location!),
                  ),
                ],
                if (record.notes != null) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: l10n.intimacyDetailNotes,
                    child: SelectableText(record.notes!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final IntimacyRecord record;
  final Partner? partner;

  /// Purpose: Create the header card.
  /// Inputs: `record`, resolved `partner`.
  /// Returns: A new `_HeaderCard` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _HeaderCard({required this.record, this.partner});

  /// Purpose: Show who, when, and the pleasure rating.
  /// Inputs: `context`.
  /// Returns: The header card.
  /// Side effects: Resolves the partner image from the blob store.
  /// Notes: Mirrors the record list tile's avatar fallback.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final p = partner;
    final title = record.isSolo
        ? l10n.intimacySolo
        : p == null
        ? l10n.intimacyPartner
        : (p.emoji != null ? '${p.emoji} ${p.name}' : p.name);
    final fallback = Icon(
      record.isSolo ? Icons.person : Icons.favorite,
      color: theme.colorScheme.primary,
    );
    final stars = '★' * record.pleasureLevel + '☆' * (5 - record.pleasureLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (!record.isSolo && p?.imagePath != null)
              FutureBuilder<File>(
                future: ImageService.resolve(p!.imagePath!),
                builder: (context, snap) {
                  if (snap.hasData && snap.data!.existsSync()) {
                    return CircleAvatar(
                      radius: 20,
                      backgroundImage: FileImage(snap.data!),
                    );
                  }
                  return fallback;
                },
              )
            else
              fallback,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.yMMMd(
                      l10n.localeName,
                    ).add_Hm().format(record.datetime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: l10n.intimacyPleasure,
              child: Text(
                stars,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  /// Purpose: Create one headline figure.
  /// Inputs: `icon`, `label`, `value`.
  /// Returns: A new `_StatTile` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  /// Purpose: Build a fixed-width tile showing a label and a value.
  /// Inputs: `context`.
  /// Returns: The tile.
  /// Side effects: None.
  /// Notes: Fixed width so the three tiles wrap evenly on narrow screens.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 150,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  /// Purpose: Create a titled card section.
  /// Inputs: `title`, `child`.
  /// Returns: A new `_Section` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _Section({required this.title, required this.child});

  /// Purpose: Build a card with a small title above its content.
  /// Inputs: `context`.
  /// Returns: The section card.
  /// Side effects: None.
  /// Notes: None.
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _FlagTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;

  /// Purpose: Create a yes/no row.
  /// Inputs: `icon`, `label`, `value`.
  /// Returns: A new `_FlagTile` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _FlagTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  /// Purpose: Build a dense list row with a check or empty-circle mark.
  /// Inputs: `context`.
  /// Returns: The row.
  /// Side effects: None.
  /// Notes: None.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(label),
      trailing: Icon(
        value ? Icons.check_circle : Icons.radio_button_unchecked,
        color: value ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
    );
  }
}

class _ToyChip extends StatelessWidget {
  final Toy toy;

  /// Purpose: Create a toy chip.
  /// Inputs: `toy`.
  /// Returns: A new `_ToyChip` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _ToyChip({required this.toy});

  /// Purpose: Build a chip with the toy's image avatar when it has one.
  /// Inputs: `context`.
  /// Returns: The chip.
  /// Side effects: Resolves the toy image from the blob store.
  /// Notes: Falls back to the emoji label, as the record list tile does.
  @override
  Widget build(BuildContext context) {
    final label = toy.emoji != null ? '${toy.emoji} ${toy.name}' : toy.name;
    final plain = Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
    if (toy.imagePath == null) return plain;
    return FutureBuilder<File>(
      future: ImageService.resolve(toy.imagePath!),
      builder: (context, snap) {
        if (snap.hasData && snap.data!.existsSync()) {
          return Chip(
            avatar: CircleAvatar(
              backgroundImage: FileImage(snap.data!),
              radius: 12,
            ),
            label: Text(toy.name),
            visualDensity: VisualDensity.compact,
          );
        }
        return plain;
      },
    );
  }
}

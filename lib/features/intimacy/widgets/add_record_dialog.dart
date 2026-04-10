import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../models/intimacy_record.dart';

class AddRecordDialog extends StatefulWidget {
  final Duration? prefillDuration;
  final IntimacyRecord? record;
  final List<Partner> partners;
  final List<Toy> toys;
  final List<Position> positions;

  const AddRecordDialog({
    super.key,
    this.prefillDuration,
    this.record,
    required this.partners,
    required this.toys,
    this.positions = const [],
  });

  @override
  State<AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<AddRecordDialog> {
  late bool _isSolo;
  late String? _selectedPartnerId;
  late Set<String> _selectedToyIds;
  late Set<String> _selectedPositionIds;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late int _pleasureLevel;
  late DateTime _datetime;
  late bool _hadOrgasm;
  late bool _watchedPorn;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _isSolo = r?.isSolo ?? (widget.partners.isEmpty);
    _selectedPartnerId = r?.partnerId;
    _selectedToyIds = Set.of(r?.toyIds ?? []);
    _selectedPositionIds = Set.of(r?.positionIds ?? []);
    _locationController = TextEditingController(text: r?.location ?? '');
    _notesController = TextEditingController(text: r?.notes ?? '');
    _pleasureLevel = r?.pleasureLevel ?? 3;
    var initMinutes = r?.duration.inMinutes ?? 15;
    _datetime = r?.datetime ?? DateTime.now();
    _hadOrgasm = r?.hadOrgasm ?? false;
    _watchedPorn = r?.watchedPorn ?? false;
    if (widget.prefillDuration != null && r == null) {
      initMinutes = widget.prefillDuration!.inMinutes.clamp(0, 5999);
    }
    _hoursController = TextEditingController(
      text: (initMinutes ~/ 60).toString(),
    );
    _minutesController = TextEditingController(
      text: (initMinutes % 60).toString(),
    );
    // Default to first partner if none selected and not solo
    if (!_isSolo && _selectedPartnerId == null && widget.partners.isNotEmpty) {
      _selectedPartnerId = widget.partners.first.id;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? l10n.intimacyEditRecord : l10n.intimacyNewRecord,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Solo toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.intimacySolo),
              value: _isSolo,
              onChanged: (v) => setState(() {
                _isSolo = v;
                if (!v &&
                    _selectedPartnerId == null &&
                    widget.partners.isNotEmpty) {
                  _selectedPartnerId = widget.partners.first.id;
                }
              }),
            ),

            // Partner picker (hidden if solo)
            if (!_isSolo) ...[
              if (widget.partners.isEmpty)
                Text(
                  l10n.intimacyNoPartnersHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedPartnerId,
                  decoration: InputDecoration(labelText: l10n.intimacyPartner),
                  items: widget.partners
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            p.emoji != null ? '${p.emoji} ${p.name}' : p.name,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPartnerId = v),
                ),
              const SizedBox(height: 12),
            ],

            // Toy multi-select
            if (widget.toys.isNotEmpty) ...[
              Text('Toys:', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.toys.map((toy) {
                  final selected = _selectedToyIds.contains(toy.id);
                  return FilterChip(
                    label: Text(
                      toy.emoji != null ? '${toy.emoji} ${toy.name}' : toy.name,
                    ),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedToyIds.add(toy.id);
                        } else {
                          _selectedToyIds.remove(toy.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Position multi-select
            if (widget.positions.isNotEmpty) ...[
              Text('${l10n.intimacyPositions}:', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.positions.map((pos) {
                  final selected = _selectedPositionIds.contains(pos.id);
                  return FilterChip(
                    label: Text(
                      pos.emoji != null ? '${pos.emoji} ${pos.name}' : pos.name,
                    ),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedPositionIds.add(pos.id);
                        } else {
                          _selectedPositionIds.remove(pos.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Pleasure level
            Row(
              children: [
                Text(
                  '${l10n.intimacyPleasure}:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                ...List.generate(5, (i) {
                  final level = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _pleasureLevel = level),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        level <= _pleasureLevel
                            ? Icons.star
                            : Icons.star_border,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),

            // Duration input (hours + minutes)
            Row(
              children: [
                Text(
                  '${l10n.intimacyDuration}:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 56,
                  child: TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      suffixText: 'h',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      suffixText: 'm',
                    ),
                  ),
                ),
              ],
            ),

            // Orgasm toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.intimacyOrgasm),
              value: _hadOrgasm,
              onChanged: (v) => setState(() => _hadOrgasm = v),
            ),

            // Watched porn toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.intimacyWatchedPorn),
              value: _watchedPorn,
              onChanged: (v) => setState(() => _watchedPorn = v),
            ),

            // Location
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: l10n.intimacyLocation),
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.intimacyNotes),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Date/time picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_datetime.year}-${_datetime.month.toString().padLeft(2, '0')}-${_datetime.day.toString().padLeft(2, '0')} '
                '${_datetime.hour.toString().padLeft(2, '0')}:${_datetime.minute.toString().padLeft(2, '0')}',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _datetime,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (date == null || !mounted) return;
                if (!context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_datetime),
                );
                if (time != null) {
                  setState(() {
                    _datetime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.commonCancel),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _submit, child: Text(l10n.commonSave)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final totalMinutes = (hours * 60 + minutes).clamp(0, 5999);
    final record = IntimacyRecord(
      id: widget.record?.id,
      type: _isSolo ? 'Solo' : 'Regular',
      partnerId: _isSolo ? null : _selectedPartnerId,
      isSolo: _isSolo,
      pleasureLevel: _pleasureLevel,
      duration: Duration(minutes: totalMinutes),
      datetime: _datetime,
      toyIds: _selectedToyIds.toList(),
      positionIds: _selectedPositionIds.toList(),
      hadOrgasm: _hadOrgasm,
      watchedPorn: _watchedPorn,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    Navigator.pop(context, record);
  }
}

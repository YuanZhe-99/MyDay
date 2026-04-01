import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/auto_sync_service.dart';
import '../../../shared/services/image_service.dart';
import '../../../shared/widgets/delete_confirm.dart';
import '../models/intimacy_record.dart';
import '../services/intimacy_storage.dart';
import '../widgets/add_record_dialog.dart';
import '../widgets/timer_page.dart';

enum _SortMode { dateDesc, dateAsc, pleasureDesc, durationDesc }
enum _FilterMode { all, solo, partnered, orgasm, noOrgasm }

class IntimacyPage extends StatefulWidget {
  const IntimacyPage({super.key});

  @override
  State<IntimacyPage> createState() => _IntimacyPageState();
}

class _IntimacyPageState extends State<IntimacyPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  List<Partner> _partners = [];
  List<Toy> _toys = [];
  List<IntimacyRecord> _records = [];
  bool _loaded = false;

  _SortMode _sortMode = _SortMode.dateDesc;
  _FilterMode _filterMode = _FilterMode.all;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await IntimacyStorage.load();
    setState(() {
      if (data != null) {
        _partners = data.partners;
        _toys = data.toys;
        _records = data.records;
      }
      _loaded = true;
    });
  }

  Future<void> _saveData() async {
    await IntimacyStorage.save(IntimacyData(
      partners: _partners,
      toys: _toys,
      records: _records,
    ));
    AutoSyncService.instance.notifySaved();
  }

  Set<DateTime> get _markedDates {
    return _records
        .map((r) => DateTime(r.datetime.year, r.datetime.month, r.datetime.day))
        .toSet();
  }

  List<IntimacyRecord> get _filteredRecords {
    var list = List<IntimacyRecord>.from(_records);

    // Date filter (calendar selection)
    if (_selectedDate != null) {
      list = list.where((r) {
        final d = r.datetime;
        return d.year == _selectedDate!.year &&
            d.month == _selectedDate!.month &&
            d.day == _selectedDate!.day;
      }).toList();
    }

    // Type filter
    switch (_filterMode) {
      case _FilterMode.solo:
        list = list.where((r) => r.isSolo).toList();
      case _FilterMode.partnered:
        list = list.where((r) => !r.isSolo).toList();
      case _FilterMode.orgasm:
        list = list.where((r) => r.hadOrgasm).toList();
      case _FilterMode.noOrgasm:
        list = list.where((r) => !r.hadOrgasm).toList();
      case _FilterMode.all:
        break;
    }

    // Sort
    switch (_sortMode) {
      case _SortMode.dateDesc:
        list.sort((a, b) => b.datetime.compareTo(a.datetime));
      case _SortMode.dateAsc:
        list.sort((a, b) => a.datetime.compareTo(b.datetime));
      case _SortMode.pleasureDesc:
        list.sort((a, b) => b.pleasureLevel.compareTo(a.pleasureLevel));
      case _SortMode.durationDesc:
        list.sort((a, b) => b.duration.compareTo(a.duration));
    }

    return list;
  }

  Future<void> _addRecord() async {
    final record = await showDialog<IntimacyRecord>(
      context: context,
      builder: (_) => AddRecordDialog(partners: _partners, toys: _toys),
    );
    if (record != null) {
      setState(() => _records.insert(0, record));
      await _saveData();
    }
  }

  void _deleteRecord(IntimacyRecord record) {
    setState(() => _records.removeWhere((r) => r.id == record.id));
    _saveData();
  }

  Future<void> _editRecord(IntimacyRecord record) async {
    final updated = await showDialog<IntimacyRecord>(
      context: context,
      builder: (_) =>
          AddRecordDialog(record: record, partners: _partners, toys: _toys),
    );
    if (updated != null) {
      setState(() {
        final index = _records.indexWhere((r) => r.id == updated.id);
        if (index != -1) _records[index] = updated;
      });
      await _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.intimacyTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Timer',
            onPressed: () async {
              final record = await Navigator.push<IntimacyRecord>(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        TimerPage(partners: _partners, toys: _toys)),
              );
              if (record != null) {
                setState(() => _records.insert(0, record));
                await _saveData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Manage',
            onPressed: () => _showManageMenu(context),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar
                _CalendarWidget(
                  focusedMonth: _focusedMonth,
                  selectedDate: _selectedDate,
                  markedDates: _markedDates,
                  onMonthChanged: (month) {
                    setState(() => _focusedMonth = month);
                  },
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate =
                          _selectedDate == date ? null : date; // toggle
                    });
                  },
                ),
                const Divider(height: 1),

                // Records header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('MMM d').format(_selectedDate!)
                            : AppLocalizations.of(context)!.intimacyAllRecords,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedDate = null),
                          child: Text(AppLocalizations.of(context)!.intimacyShowAll),
                        ),
                      ],
                    ],
                  ),
                ),

                // Sort & filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      _buildSortChip(context),
                      const SizedBox(width: 6),
                      _buildFilterChip(context),
                    ],
                  ),
                ),

                Expanded(
                  child: _filteredRecords.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)!.intimacyNoRecords,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            return Dismissible(
                              key: ValueKey(record.id),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                color: theme.colorScheme.primary,
                                child: Icon(Icons.edit_outlined,
                                    color: theme.colorScheme.onPrimary),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: theme.colorScheme.error,
                                child: Icon(Icons.delete_outline,
                                    color: theme.colorScheme.onError),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction ==
                                    DismissDirection.startToEnd) {
                                  _editRecord(record);
                                  return false;
                                }
                                return confirmDelete(
                                    context, 'this record');
                              },
                              onDismissed: (_) => _deleteRecord(record),
                              child: _RecordTile(
                                record: record,
                                partner: record.partnerId != null
                                    ? _partners.where((p) => p.id == record.partnerId).firstOrNull
                                    : null,
                                toys: record.toyIds
                                    .map((id) => _toys.where((t) => t.id == id).firstOrNull)
                                    .whereType<Toy>()
                                    .toList(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSortChip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      _SortMode.dateDesc: l10n.intimacySortNewest,
      _SortMode.dateAsc: l10n.intimacySortOldest,
      _SortMode.pleasureDesc: l10n.intimacySortPleasure,
      _SortMode.durationDesc: l10n.intimacySortDuration,
    };
    return PopupMenuButton<_SortMode>(
      initialValue: _sortMode,
      onSelected: (v) => setState(() => _sortMode = v),
      itemBuilder: (_) => labels.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      child: Chip(
        avatar: const Icon(Icons.sort, size: 18),
        label: Text(labels[_sortMode]!),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      _FilterMode.all: l10n.intimacyFilterAll,
      _FilterMode.solo: l10n.intimacyFilterSolo,
      _FilterMode.partnered: l10n.intimacyFilterPartnered,
      _FilterMode.orgasm: l10n.intimacyFilterOrgasm,
      _FilterMode.noOrgasm: l10n.intimacyFilterNoOrgasm,
    };
    return PopupMenuButton<_FilterMode>(
      initialValue: _filterMode,
      onSelected: (v) => setState(() => _filterMode = v),
      itemBuilder: (_) => labels.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      child: Chip(
        avatar: const Icon(Icons.filter_list, size: 18),
        label: Text(labels[_filterMode]!),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _showManageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people),
              title: Text(AppLocalizations.of(context)!.intimacyPartners),
              trailing: Text('${_partners.length}'),
              onTap: () {
                Navigator.pop(context);
                _openPartnerManagement();
              },
            ),
            ListTile(
              leading: const Icon(Icons.toys),
              title: Text(AppLocalizations.of(context)!.intimacyToys),
              trailing: Text('${_toys.length}'),
              onTap: () {
                Navigator.pop(context);
                _openToyManagement();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPartnerManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PartnerManagementPage(
          partners: _partners,
          records: _records,
          toys: _toys,
          onChanged: (updated) {
            setState(() => _partners = updated);
            _saveData();
          },
        ),
      ),
    );
  }

  Future<void> _openToyManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ToyManagementPage(
          toys: _toys,
          records: _records,
          partners: _partners,
          onChanged: (updated) {
            setState(() => _toys = updated);
            _saveData();
          },
        ),
      ),
    );
  }
}

// Simple calendar grid widget
class _CalendarWidget extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final Set<DateTime> markedDates;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime) onDateSelected;

  const _CalendarWidget({
    required this.focusedMonth,
    required this.selectedDate,
    required this.markedDates,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = focusedMonth.year;
    final month = focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onMonthChanged(
                  DateTime(year, month - 1, 1),
                ),
              ),
              Text(
                DateFormat('yyyy MMMM').format(focusedMonth),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onMonthChanged(
                  DateTime(year, month + 1, 1),
                ),
              ),
            ],
          ),
        ),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Day grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildDayGrid(context, startWeekday, daysInMonth, year, month),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDayGrid(
      BuildContext context, int startWeekday, int daysInMonth, int year, int month) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final rows = <Widget>[];
    var day = 1 - startWeekday;

    while (day <= daysInMonth) {
      final cells = <Widget>[];
      for (var i = 0; i < 7; i++) {
        if (day < 1 || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 36)));
        } else {
          final date = DateTime(year, month, day);
          final isMarked = markedDates.contains(date);
          final isSelected = selectedDate == date;
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          cells.add(Expanded(
            child: GestureDetector(
              onTap: () => onDateSelected(date),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : isMarked
                          ? theme.colorScheme.primaryContainer
                          : null,
                  border: isToday && !isSelected
                      ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : isMarked
                              ? theme.colorScheme.onPrimaryContainer
                              : null,
                      fontWeight: isMarked || isToday ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ),
            ),
          ));
        }
        day++;
      }
      rows.add(Row(children: cells));
    }
    return Column(children: rows);
  }
}

class _RecordTile extends StatelessWidget {
  final IntimacyRecord record;
  final Partner? partner;
  final List<Toy> toys;

  const _RecordTile({
    required this.record,
    this.partner,
    this.toys = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, HH:mm').format(record.datetime);
    final durationStr = '${record.duration.inMinutes}min';
    final stars =
        '★' * record.pleasureLevel + '☆' * (5 - record.pleasureLevel);

    final partnerLabel = partner != null
        ? (partner!.emoji != null ? '${partner!.emoji} ${partner!.name}' : partner!.name)
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!record.isSolo && partner?.imagePath != null)
                  FutureBuilder<File>(
                    future: ImageService.resolve(partner!.imagePath!),
                    builder: (context, snap) {
                      if (snap.hasData && snap.data!.existsSync()) {
                        return CircleAvatar(
                          radius: 12,
                          backgroundImage: FileImage(snap.data!),
                        );
                      }
                      return Icon(Icons.favorite, size: 18, color: theme.colorScheme.primary);
                    },
                  )
                else
                  Icon(
                    record.isSolo ? Icons.person : Icons.favorite,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                const SizedBox(width: 8),
                Text(
                  record.isSolo ? AppLocalizations.of(context)!.intimacySolo : partnerLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  stars,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(durationStr, style: theme.textTheme.bodySmall),
                if (record.hadOrgasm)
                  Icon(Icons.favorite, size: 14, color: theme.colorScheme.tertiary),
                if (record.watchedPorn) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.ondemand_video, size: 14, color: theme.colorScheme.onSurfaceVariant),
                ],
                if (record.location != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.location_on_outlined,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(record.location!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            if (toys.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: toys.map((t) {
                  final label = t.emoji != null ? '${t.emoji} ${t.name}' : t.name;
                  if (t.imagePath != null) {
                    return FutureBuilder<File>(
                      future: ImageService.resolve(t.imagePath!),
                      builder: (context, snap) {
                        if (snap.hasData && snap.data!.existsSync()) {
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundImage: FileImage(snap.data!),
                              radius: 12,
                            ),
                            label: Text(t.name),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }
                        return Chip(
                          label: Text(label),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      },
                    );
                  }
                  return Chip(
                    label: Text(label),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                record.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Partner Management ─────────────────────────────────────────────
class _PartnerManagementPage extends StatefulWidget {
  final List<Partner> partners;
  final List<IntimacyRecord> records;
  final List<Toy> toys;
  final ValueChanged<List<Partner>> onChanged;

  const _PartnerManagementPage({
    required this.partners,
    required this.records,
    required this.toys,
    required this.onChanged,
  });

  @override
  State<_PartnerManagementPage> createState() =>
      _PartnerManagementPageState();
}

class _PartnerManagementPageState extends State<_PartnerManagementPage> {
  late List<Partner> _partners;

  static const _commonEmojis = [
    '👩', '👨', '👩‍🦰', '👨‍🦰', '👱‍♀️', '👱', '🧑', '👧',
    '💑', '❤️', '💕', '😍', '🥰', '💋', '🌹', '✨',
  ];

  @override
  void initState() {
    super.initState();
    _partners = List.of(widget.partners);
  }

  void _addPartner() => _showEditDialog(null);

  void _editPartner(Partner p) => _showEditDialog(p);

  void _deletePartner(Partner p) {
    setState(() => _partners.removeWhere((x) => x.id == p.id));
    widget.onChanged(_partners);
  }

  void _showPartnerRecords(Partner p) {
    final related = widget.records
        .where((r) => r.partnerId == p.id)
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FilteredRecordsPage(
          title: p.name,
          records: related,
          partners: _partners,
          toys: widget.toys,
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Partner? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? selectedEmoji = existing?.emoji;
    String? imagePath = existing?.imagePath;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? AppLocalizations.of(context)!.intimacyAddPartner : AppLocalizations.of(context)!.intimacyEditPartner),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.commonName),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.commonEmojiOptional,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              _buildImageRow(imagePath, Theme.of(context), (path) {
                setDialogState(() {
                  imagePath = path;
                  if (path != null) selectedEmoji = null;
                });
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _commonEmojis.map((emoji) {
                    final isSelected = emoji == selectedEmoji;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setDialogState(() {
                        selectedEmoji = isSelected ? null : emoji;
                        if (!isSelected) imagePath = null;
                      }),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.commonCancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(context)!.commonSave)),
          ],
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        if (existing != null) {
          final idx = _partners.indexWhere((p) => p.id == existing.id);
          if (idx != -1) {
            _partners[idx] = Partner(
              id: existing.id,
              name: nameCtrl.text.trim(),
              emoji: selectedEmoji,
              imagePath: imagePath,
            );
          }
        } else {
          _partners.add(Partner(
            name: nameCtrl.text.trim(),
            emoji: selectedEmoji,
            imagePath: imagePath,
          ));
        }
      });
      widget.onChanged(_partners);
    }
  }

  Widget _buildImageRow(String? imagePath, ThemeData theme, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        if (imagePath != null)
          FutureBuilder<File>(
            future: ImageService.resolve(imagePath),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(snap.data!, width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => onChanged(null),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 12, color: theme.colorScheme.onError),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        if (imagePath != null) const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.image_outlined, size: 16),
          label: Text(imagePath != null ? 'Change' : 'Pick Image'),
          onPressed: () async {
            final path = await ImageService.pickAndSaveImage();
            if (path != null) onChanged(path);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.intimacyPartners),
        centerTitle: true,
      ),
      body: _partners.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.intimacyNoPartners))
          : ListView.builder(
              itemCount: _partners.length,
              itemBuilder: (context, index) {
                final p = _partners[index];
                final recordCount = widget.records
                    .where((r) => r.partnerId == p.id)
                    .length;
                return Dismissible(
                  key: ValueKey(p.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    color: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.edit_outlined,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.error,
                    child: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onError),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _editPartner(p);
                      return false;
                    }
                    return confirmDelete(context, p.name);
                  },
                  onDismissed: (_) => _deletePartner(p),
                  child: ListTile(
                    leading: _buildPartnerAvatar(p),
                    title: Text(p.name),
                    subtitle: Text(AppLocalizations.of(context)!
                        .intimacyRecordCount(recordCount)),
                    onTap: () => _showPartnerRecords(p),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPartner,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPartnerAvatar(Partner p) {
    if (p.imagePath != null) {
      return FutureBuilder<File>(
        future: ImageService.resolve(p.imagePath!),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.existsSync()) {
            return CircleAvatar(backgroundImage: FileImage(snap.data!));
          }
          return CircleAvatar(child: Text(p.emoji ?? p.name[0]));
        },
      );
    }
    return CircleAvatar(child: Text(p.emoji ?? p.name[0]));
  }
}

// ─── Toy Management ─────────────────────────────────────────────────
class _ToyManagementPage extends StatefulWidget {
  final List<Toy> toys;
  final List<IntimacyRecord> records;
  final List<Partner> partners;
  final ValueChanged<List<Toy>> onChanged;

  const _ToyManagementPage({
    required this.toys,
    required this.records,
    required this.partners,
    required this.onChanged,
  });

  @override
  State<_ToyManagementPage> createState() => _ToyManagementPageState();
}

class _ToyManagementPageState extends State<_ToyManagementPage> {
  late List<Toy> _toys;

  static const _commonEmojis = [
    '🎀', '🧸', '💎', '🔮', '🎯', '🪄', '🌡️', '💫',
    '🎁', '🦋', '🌸', '🍭', '⭐', '🔥', '💜', '✨',
  ];

  @override
  void initState() {
    super.initState();
    _toys = List.of(widget.toys);
  }

  void _addToy() => _showEditDialog(null);

  void _editToy(Toy t) => _showEditDialog(t);

  void _deleteToy(Toy t) {
    setState(() => _toys.removeWhere((x) => x.id == t.id));
    widget.onChanged(_toys);
  }

  void _showToyRecords(Toy t) {
    final related = widget.records
        .where((r) => r.toyIds.contains(t.id))
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FilteredRecordsPage(
          title: t.name,
          records: related,
          partners: widget.partners,
          toys: _toys,
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Toy? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String? selectedEmoji = existing?.emoji;
    String? imagePath = existing?.imagePath;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? AppLocalizations.of(context)!.intimacyAddToy : AppLocalizations.of(context)!.intimacyEditToy),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.commonName),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.commonEmojiOptional,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              _buildImageRow(imagePath, Theme.of(context), (path) {
                setDialogState(() {
                  imagePath = path;
                  if (path != null) selectedEmoji = null;
                });
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _commonEmojis.map((emoji) {
                    final isSelected = emoji == selectedEmoji;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setDialogState(() {
                        selectedEmoji = isSelected ? null : emoji;
                        if (!isSelected) imagePath = null;
                      }),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.commonCancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(context)!.commonSave)),
          ],
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        if (existing != null) {
          final idx = _toys.indexWhere((t) => t.id == existing.id);
          if (idx != -1) {
            _toys[idx] = Toy(
              id: existing.id,
              name: nameCtrl.text.trim(),
              emoji: selectedEmoji,
              imagePath: imagePath,
            );
          }
        } else {
          _toys.add(Toy(
            name: nameCtrl.text.trim(),
            emoji: selectedEmoji,
            imagePath: imagePath,
          ));
        }
      });
      widget.onChanged(_toys);
    }
  }

  Widget _buildImageRow(String? imagePath, ThemeData theme, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        if (imagePath != null)
          FutureBuilder<File>(
            future: ImageService.resolve(imagePath),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(snap.data!, width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => onChanged(null),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 12, color: theme.colorScheme.onError),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        if (imagePath != null) const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.image_outlined, size: 16),
          label: Text(imagePath != null ? 'Change' : 'Pick Image'),
          onPressed: () async {
            final path = await ImageService.pickAndSaveImage();
            if (path != null) onChanged(path);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.intimacyToys),
        centerTitle: true,
      ),
      body: _toys.isEmpty
          ? Center(child: Text(AppLocalizations.of(context)!.intimacyNoToys))
          : ListView.builder(
              itemCount: _toys.length,
              itemBuilder: (context, index) {
                final t = _toys[index];
                final recordCount = widget.records
                    .where((r) => r.toyIds.contains(t.id))
                    .length;
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    color: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.edit_outlined,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.error,
                    child: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onError),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _editToy(t);
                      return false;
                    }
                    return confirmDelete(context, t.name);
                  },
                  onDismissed: (_) => _deleteToy(t),
                  child: ListTile(
                    leading: _buildToyAvatar(t),
                    title: Text(t.name),
                    subtitle: Text(AppLocalizations.of(context)!
                        .intimacyRecordCount(recordCount)),
                    onTap: () => _showToyRecords(t),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addToy,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildToyAvatar(Toy t) {
    if (t.imagePath != null) {
      return FutureBuilder<File>(
        future: ImageService.resolve(t.imagePath!),
        builder: (context, snap) {
          if (snap.hasData && snap.data!.existsSync()) {
            return CircleAvatar(backgroundImage: FileImage(snap.data!));
          }
          return CircleAvatar(child: Text(t.emoji ?? t.name[0]));
        },
      );
    }
    return CircleAvatar(child: Text(t.emoji ?? t.name[0]));
  }
}

// ─── Filtered Records (by partner or toy) ───────────────────────────
class _FilteredRecordsPage extends StatelessWidget {
  final String title;
  final List<IntimacyRecord> records;
  final List<Partner> partners;
  final List<Toy> toys;

  const _FilteredRecordsPage({
    required this.title,
    required this.records,
    required this.partners,
    required this.toys,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: records.isEmpty
          ? Center(child: Text(l10n.intimacyNoRecords))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final partner = record.partnerId != null
                    ? partners
                        .where((p) => p.id == record.partnerId)
                        .firstOrNull
                    : null;
                final recordToys = record.toyIds
                    .map((id) => toys.where((t) => t.id == id).firstOrNull)
                    .whereType<Toy>()
                    .toList();
                return _RecordTile(
                  record: record,
                  partner: partner,
                  toys: recordToys,
                );
              },
            ),
    );
  }
}

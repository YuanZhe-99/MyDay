import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../services/backup_service.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  List<BackupInfo> _backups = [];
  bool _autoBackup = false;
  int _retentionDays = 0; // 0 = forever
  bool _loading = true;

  static const _retentionOptions = [0, 7, 14, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await BackupService.loadSettings();
    final backups = await BackupService.listBackups();
    if (mounted) {
      setState(() {
        _autoBackup = BackupService.autoBackupEnabled;
        _retentionDays = BackupService.retentionDays;
        _backups = backups;
        _loading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final file = await BackupService.createBackup();
    if (!mounted) return;
    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupCreated)),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupFailed)),
      );
    }
  }

  Future<void> _toggleAutoBackup(bool value) async {
    setState(() => _autoBackup = value);
    BackupService.autoBackupEnabled = value;
    await BackupService.saveSettings();
  }

  Future<void> _setRetention(int days) async {
    setState(() => _retentionDays = days);
    BackupService.retentionDays = days;
    await BackupService.saveSettings();
  }

  Future<void> _deleteBackup(BackupInfo info) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupDeleteConfirmTitle),
        content: Text(l10n.backupDeleteConfirmDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await BackupService.deleteBackup(info.file);
      _load();
    }
  }

  Future<void> _restoreBackup(BackupInfo info) async {
    final l10n = AppLocalizations.of(context)!;

    final availableModules = await BackupService.getBackupModules(info.file);
    if (!mounted) return;
    if (availableModules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupRestoreFailed)),
      );
      return;
    }

    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => _RestoreModuleDialog(
        availableModules: availableModules,
      ),
    );
    if (selected == null || selected.isEmpty) return;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupRestoreConfirmTitle),
        content: Text(l10n.backupRestoreConfirmDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.backupRestore),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await BackupService.restoreBackup(
      info.file,
      moduleKeys: selected,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.backupRestoreSuccess : l10n.backupRestoreFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupTitle),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Local-only note
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.backupLocalOnlyNote,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Settings section
                _buildSection(context, l10n.backupSettings, [
                  SwitchListTile(
                    secondary: const Icon(Icons.schedule),
                    title: Text(l10n.backupAutoDaily),
                    subtitle: Text(l10n.backupAutoDailyDesc),
                    value: _autoBackup,
                    onChanged: _toggleAutoBackup,
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_delete),
                    title: Text(l10n.backupRetention),
                    trailing: DropdownButton<int>(
                      value: _retentionDays,
                      underline: const SizedBox.shrink(),
                      items: _retentionOptions.map((d) {
                        final label = d == 0
                            ? l10n.backupRetentionForever
                            : l10n.backupRetentionDays(d);
                        return DropdownMenuItem(value: d, child: Text(label));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) _setRetention(v);
                      },
                    ),
                  ),
                ]),

                // Manual backup
                _buildSection(context, l10n.backupManual, [
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: Text(l10n.backupCreateNow),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _createBackup,
                  ),
                ]),

                // Backup list
                _buildSection(
                  context,
                  l10n.backupHistory(_backups.length),
                  _backups.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              l10n.backupEmpty,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ]
                      : _backups.map((b) {
                          final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(b.date);
                          return ListTile(
                            leading: const Icon(Icons.inventory_2_outlined),
                            title: Text(dateStr),
                            subtitle: Text(b.displaySize),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.restore),
                                  tooltip: l10n.backupRestore,
                                  onPressed: () => _restoreBackup(b),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: l10n.commonDelete,
                                  onPressed: () => _deleteBackup(b),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Dialog to pick which modules to restore.
class _RestoreModuleDialog extends StatefulWidget {
  final List<String> availableModules;
  const _RestoreModuleDialog({required this.availableModules});

  @override
  State<_RestoreModuleDialog> createState() => _RestoreModuleDialogState();
}

class _RestoreModuleDialogState extends State<_RestoreModuleDialog> {
  late final Set<String> _selected;
  bool _selectAll = true;

  static const _moduleLabels = {
    'todo': ('Todo', Icons.check_circle_outline),
    'finance': ('Finance', Icons.account_balance_wallet_outlined),
    'exchangeRates': ('Exchange Rates', Icons.currency_exchange),
    'intimacy': ('Intimacy', Icons.favorite_outline),
  };

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.availableModules);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.backupRestoreSelectModules),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: Text(l10n.backupRestoreAll),
            value: _selectAll,
            onChanged: (v) {
              setState(() {
                _selectAll = v ?? false;
                if (_selectAll) {
                  _selected.addAll(widget.availableModules);
                } else {
                  _selected.clear();
                }
              });
            },
          ),
          const Divider(),
          ...widget.availableModules.map((m) {
            final info = _moduleLabels[m];
            final label = _localizedModuleName(l10n, m);
            return CheckboxListTile(
              secondary: Icon(info?.$2 ?? Icons.extension),
              title: Text(label),
              value: _selected.contains(m),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selected.add(m);
                  } else {
                    _selected.remove(m);
                  }
                  _selectAll = _selected.length == widget.availableModules.length;
                });
              },
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected),
          child: Text(l10n.backupRestore),
        ),
      ],
    );
  }

  String _localizedModuleName(AppLocalizations l10n, String moduleId) {
    return switch (moduleId) {
      'todo' => l10n.backupModuleTodo,
      'finance' => l10n.backupModuleFinance,
      'exchangeRates' => l10n.backupModuleRates,
      'intimacy' => l10n.backupModuleIntimacy,
      _ => moduleId,
    };
  }
}

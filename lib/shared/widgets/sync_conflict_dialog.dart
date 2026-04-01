import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../services/sync_merge.dart';

/// Dialog that shows per-record sync conflicts and lets the user choose
/// "Keep Local" or "Keep Remote" for each one.
///
/// Returns a `Map<String, dynamic>` mapping record ID → the chosen record
/// object, or `null` if the user cancels.
class SyncConflictDialog extends StatefulWidget {
  final List<RecordConflict> conflicts;

  const SyncConflictDialog({super.key, required this.conflicts});

  @override
  State<SyncConflictDialog> createState() => _SyncConflictDialogState();
}

class _SyncConflictDialogState extends State<SyncConflictDialog> {
  // Maps record ID → true for local, false for remote
  final Map<String, bool> _choices = {};

  bool get _allResolved => _choices.length == widget.conflicts.length;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(loc.settingsWebDAVConflictTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.settingsWebDAVConflictDesc,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.conflicts.length,
                separatorBuilder: (context, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conflict = widget.conflicts[index];
                  final choice = _choices[conflict.id];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conflict.displayName,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _ChoiceButton(
                                label: loc.settingsWebDAVKeepLocal,
                                icon: Icons.phone_android,
                                selected: choice == true,
                                onTap: () => setState(() =>
                                    _choices[conflict.id] = true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ChoiceButton(
                                label: loc.settingsWebDAVKeepRemote,
                                icon: Icons.cloud,
                                selected: choice == false,
                                onTap: () => setState(() =>
                                    _choices[conflict.id] = false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(loc.commonCancel),
        ),
        FilledButton(
          onPressed: _allResolved
              ? () {
                  final resolutions = <String, dynamic>{};
                  for (final conflict in widget.conflicts) {
                    final keepLocal = _choices[conflict.id]!;
                    resolutions[conflict.id] = keepLocal
                        ? conflict.localRecord
                        : conflict.remoteRecord;
                  }
                  Navigator.of(context).pop(resolutions);
                }
              : null,
          child: Text(loc.settingsWebDAVConflictApply),
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.bold : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

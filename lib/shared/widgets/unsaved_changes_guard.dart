import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

abstract class UnsavedChangesController {
  Future<bool> maybeDiscardAndPop<T extends Object?>([T? result]);

  void pop<T extends Object?>([T? result]);
}

class UnsavedChangesGuard extends StatefulWidget {
  final bool Function() hasUnsavedChanges;
  final Widget Function(BuildContext context, UnsavedChangesController guard)
  builder;

  const UnsavedChangesGuard({
    super.key,
    required this.hasUnsavedChanges,
    required this.builder,
  });

  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard>
    implements UnsavedChangesController {
  bool _allowPop = false;
  bool _closing = false;
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        maybeDiscardAndPop(result);
      },
      child: Builder(builder: (context) => widget.builder(context, this)),
    );
  }

  @override
  Future<bool> maybeDiscardAndPop<T extends Object?>([T? result]) async {
    if (_closing || _confirming) return false;
    if (!widget.hasUnsavedChanges()) {
      pop(result);
      return true;
    }

    _confirming = true;
    final discard = await showDiscardChangesDialog(context);
    _confirming = false;
    if (!mounted || discard != true) return false;

    pop(result);
    return true;
  }

  @override
  void pop<T extends Object?>([T? result]) {
    if (_closing || !mounted) return;
    _closing = true;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop<T>(result);
    });
  }
}

Future<bool> showDiscardChangesDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.commonDiscardChangesTitle),
      content: Text(l10n.commonDiscardChangesMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.commonDiscard),
        ),
      ],
    ),
  );
  return result ?? false;
}

String formSignature(Iterable<Object?> values) =>
    values.map(_formValueSignature).join('\u001f');

String _formValueSignature(Object? value) {
  if (value == null) return '';
  if (value is DateTime) return value.toIso8601String();
  if (value is TimeOfDay) return '${value.hour}:${value.minute}';
  if (value is Iterable) {
    return value.map(_formValueSignature).join('\u001e');
  }
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    return entries
        .map((entry) => '${entry.key}:${_formValueSignature(entry.value)}')
        .join('\u001d');
  }
  return value.toString();
}

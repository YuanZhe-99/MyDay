import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

abstract class UnsavedChangesController {
  /// Purpose: Confirm whether pending changes can be discarded before popping.
  /// Inputs: `result`.
  /// Returns: `Future<bool>`.
  /// Side effects: May show confirmation UI and may pop the current route.
  /// Notes: Implementations should return whether the route was actually popped.
  Future<bool> maybeDiscardAndPop<T extends Object?>([T? result]);

  /// Purpose: Implement the pop behavior for this file.
  /// Inputs: `result`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  void pop<T extends Object?>([T? result]);
}

class UnsavedChangesGuard extends StatefulWidget {
  final bool Function() hasUnsavedChanges;
  final Widget Function(BuildContext context, UnsavedChangesController guard)
  builder;

  /// Purpose: Create a unsaved changes guard instance.
  /// Inputs: None.
  /// Returns: A new `UnsavedChangesGuard` instance.
  /// Side effects: None.
  /// Notes: None.
  const UnsavedChangesGuard({
    super.key,
    required this.hasUnsavedChanges,
    required this.builder,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard>
    implements UnsavedChangesController {
  bool _allowPop = false;
  bool _closing = false;
  bool _confirming = false;

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
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

  /// Purpose: Implement the maybe discard and pop behavior for this file.
  /// Inputs: `result`.
  /// Returns: `Future<bool>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
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

  /// Purpose: Implement the pop behavior for this file.
  /// Inputs: `result`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
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

/// Purpose: Show discard changes dialog through the current flow.
/// Inputs: `context`.
/// Returns: `Future<bool>`.
/// Side effects: May update UI state or trigger user-facing flows.
/// Notes: None.
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

/// Purpose: Implement the form signature behavior for this file.
/// Inputs: `values`.
/// Returns: `String`.
/// Side effects: May update UI state or trigger user-facing flows.
/// Notes: None.
String formSignature(Iterable<Object?> values) =>
    values.map(_formValueSignature).join('\u001f');

/// Purpose: Provide the internal form value signature helper for this file.
/// Inputs: `value`.
/// Returns: `String`.
/// Side effects: May update UI state or trigger user-facing flows.
/// Notes: Internal helper used within this file only.
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

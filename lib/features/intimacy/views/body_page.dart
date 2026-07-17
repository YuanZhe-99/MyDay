import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/intimacy_record.dart';
import '../widgets/body_section.dart';

/// Full-page Body settings for the user, opened from the intimacy manage
/// menu alongside partner/toy/position management.
class BodySettingsPage extends StatefulWidget {
  final BodyProfile? userBody;
  final List<CycleRecord> cycleRecords;
  final ValueChanged<BodyProfile> onUserBodyChanged;
  final ValueChanged<List<CycleRecord>> onCycleRecordsChanged;

  /// Purpose: Create a body settings page instance.
  /// Inputs: Current user body profile, cycle records, and change callbacks.
  /// Returns: A new `BodySettingsPage` instance.
  /// Side effects: None.
  /// Notes: Every field is optional and all changes save automatically
  /// through the callbacks.
  const BodySettingsPage({
    super.key,
    required this.userBody,
    required this.cycleRecords,
    required this.onUserBodyChanged,
    required this.onCycleRecordsChanged,
  });

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  State<BodySettingsPage> createState() => _BodySettingsPageState();
}

class _BodySettingsPageState extends State<BodySettingsPage> {
  BodyProfile? _userBody;
  late List<CycleRecord> _cycleRecords;

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Copies incoming data so edits refresh this page directly.
  /// Notes: None.
  @override
  void initState() {
    super.initState();
    _userBody = widget.userBody;
    _cycleRecords = List.of(widget.cycleRecords);
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.intimacyBody), centerTitle: true),
      body: ListView(
        children: [
          BodySectionView(
            mode: BodySectionMode.user,
            profile: _userBody,
            personId: null,
            personColor: cyclePersonColor(
              personId: null,
              allPartnerIdsSorted: const [],
            ),
            cycleRecords: _cycleRecords,
            onProfileChanged: (profile) {
              if (mounted) {
                setState(() => _userBody = profile);
              } else {
                _userBody = profile;
              }
              widget.onUserBodyChanged(profile);
            },
            onCycleRecordsChanged: (records) {
              if (mounted) {
                setState(() => _cycleRecords = List.of(records));
              } else {
                _cycleRecords = List.of(records);
              }
              widget.onCycleRecordsChanged(records);
            },
          ),
        ],
      ),
    );
  }
}

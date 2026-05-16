import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/todo/services/todo_storage.dart';

/// State for the intimacy module visibility.
///
/// The toggle is always shown in Settings. Default OFF for new installs.
/// Turning it off hides the tab but does NOT delete data.
/// If existing data is found, the toggle defaults to ON.
class IntimacyVisibility {
  final bool visible;

  /// Purpose: Create a intimacy visibility instance.
  /// Inputs: `visible`.
  /// Returns: A new `IntimacyVisibility` instance.
  /// Side effects: None.
  /// Notes: None.
  const IntimacyVisibility({this.visible = false});

  /// Purpose: Create a copy of this value with selected fields replaced.
  /// Inputs: `visible`.
  /// Returns: `IntimacyVisibility`.
  /// Side effects: None.
  /// Notes: None.
  IntimacyVisibility copyWith({bool? visible}) {
    return IntimacyVisibility(visible: visible ?? this.visible);
  }
}

class IntimacyVisibilityNotifier extends StateNotifier<IntimacyVisibility> {
  /// Purpose: Create an intimacy visibility notifier instance.
  /// Inputs: None.
  /// Returns: A new `IntimacyVisibilityNotifier` instance.
  /// Side effects: Starts loading persisted visibility into state.
  /// Notes: Initializes with the default hidden state before async loading finishes.
  IntimacyVisibilityNotifier() : super(const IntimacyVisibility()) {
    _loadPersistedState();
  }

  /// Purpose: Provide the internal load persisted state helper for this file.
  /// Inputs: None.
  /// Returns: `Future<void>`.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: Internal helper used within this file only.
  Future<void> _loadPersistedState() async {
    final visible = await TodoStorage.getIntimacyVisible();
    state = IntimacyVisibility(visible: visible);
  }

  /// Toggle visibility from Settings.
  /// Purpose: Implement the set visible behavior for this file.
  /// Inputs: `visible`.
  /// Returns: None.
  /// Side effects: May read or mutate application state, storage, or service resources.
  /// Notes: None.
  void setVisible(bool visible) {
    state = state.copyWith(visible: visible);
    TodoStorage.setIntimacyVisible(visible);
  }
}

final intimacyVisibilityProvider =
    StateNotifierProvider<IntimacyVisibilityNotifier, IntimacyVisibility>(
  (ref) => IntimacyVisibilityNotifier(),
);

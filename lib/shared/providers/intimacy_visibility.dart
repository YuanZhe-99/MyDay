import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/todo/services/todo_storage.dart';

/// State for the intimacy module visibility.
///
/// The toggle is always shown in Settings. Default OFF for new installs.
/// Turning it off hides the tab but does NOT delete data.
/// If existing data is found, the toggle defaults to ON.
class IntimacyVisibility {
  final bool visible;

  const IntimacyVisibility({this.visible = false});

  IntimacyVisibility copyWith({bool? visible}) {
    return IntimacyVisibility(visible: visible ?? this.visible);
  }
}

class IntimacyVisibilityNotifier extends StateNotifier<IntimacyVisibility> {
  IntimacyVisibilityNotifier() : super(const IntimacyVisibility()) {
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    final visible = await TodoStorage.getIntimacyVisible();
    state = IntimacyVisibility(visible: visible);
  }

  /// Toggle visibility from Settings.
  void setVisible(bool visible) {
    state = state.copyWith(visible: visible);
    TodoStorage.setIntimacyVisible(visible);
  }
}

final intimacyVisibilityProvider =
    StateNotifierProvider<IntimacyVisibilityNotifier, IntimacyVisibility>(
  (ref) => IntimacyVisibilityNotifier(),
);

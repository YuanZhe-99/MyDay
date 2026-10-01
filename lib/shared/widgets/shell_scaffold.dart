import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../providers/app_settings.dart';
import '../providers/intimacy_visibility.dart';
import '../services/reminder_service.dart';
import '../utils/adaptive_layout.dart';

class ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;

  /// Purpose: Create a shell scaffold instance.
  /// Inputs: `child`.
  /// Returns: A new `ShellScaffold` instance.
  /// Side effects: None.
  /// Notes: None.
  const ShellScaffold({super.key, required this.child});

  /// Purpose: Create the mutable state object for this widget.
  /// Inputs: None.
  /// Returns: A new `State` instance.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: None.
  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  static const _routes = [
    '/todo',
    '/finance',
    '/weight',
    '/intimacy',
    '/settings',
  ];
  static const _routesHidden = ['/todo', '/finance', '/weight', '/settings'];

  /// Purpose: Provide the internal active routes helper for this file.
  /// Inputs: `visible`.
  /// Returns: `List<String>`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  List<String> _activeRoutes(bool visible) => visible ? _routes : _routesHidden;

  /// Purpose: Describe the shell's destinations once, icons and labels included.
  /// Inputs: `l10n`, `visible`.
  /// Returns: `List<_ShellDestination>` in the same order as `_activeRoutes`.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only. Both the bottom bar and
  /// the navigation rail read from this, so a destination can never end up in
  /// one and not the other, or in a different order between them — and the
  /// Intimacy destination is filtered out in one place rather than in each.
  List<_ShellDestination> _destinations(AppLocalizations l10n, bool visible) {
    return [
      _ShellDestination(
        Icons.check_circle_outline,
        Icons.check_circle,
        l10n.navTodo,
      ),
      _ShellDestination(
        Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet,
        l10n.navFinance,
      ),
      _ShellDestination(
        Icons.monitor_weight_outlined,
        Icons.monitor_weight,
        l10n.navWeight,
      ),
      if (visible)
        _ShellDestination(
          Icons.favorite_border,
          Icons.favorite,
          l10n.navIntimacy,
        ),
      _ShellDestination(
        Icons.settings_outlined,
        Icons.settings,
        l10n.navSettings,
      ),
    ];
  }

  /// Purpose: Provide the internal current index helper for this file.
  /// Inputs: `context`, `visible`.
  /// Returns: `int`.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  int _currentIndex(BuildContext context, bool visible) {
    final location = GoRouterState.of(context).uri.path;
    final routes = _activeRoutes(visible);
    for (var i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) return i;
    }
    return 0;
  }

  /// Purpose: Initialize listeners, controllers, and first-load work for this state object.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Registers listeners and may kick off asynchronous loading.
  /// Notes: Guard any post-await UI updates with `mounted` when needed.
  @override
  void initState() {
    super.initState();
    // Wire in-app snackbar to global reminder service
    ReminderService.instance.onShowSnackbar = _showReminderSnackbar;
  }

  /// Purpose: Release listeners, controllers, and other owned resources.
  /// Inputs: None.
  /// Returns: None.
  /// Side effects: Releases owned resources and unregisters listeners.
  /// Notes: Call the superclass implementation in the expected lifecycle order.
  @override
  void dispose() {
    ReminderService.instance.onShowSnackbar = null;
    super.dispose();
  }

  /// Purpose: Provide the internal show reminder snackbar helper for this file.
  /// Inputs: `message`.
  /// Returns: None.
  /// Side effects: May update UI state or trigger user-facing flows.
  /// Notes: Internal helper used within this file only.
  void _showReminderSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Purpose: Build the current widget subtree for the active UI state.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often. The rail
  /// and the bottom bar are two renderings of the same destination list; which
  /// one appears is [useNavigationRail]'s width-only decision, deliberately not
  /// the app-wide split rule. Nothing here is stateful beyond the reminder
  /// callback, so folding a device swaps one for the other on the next frame
  /// with no route change.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visible = ref.watch(intimacyVisibilityProvider).visible;
    final routes = _activeRoutes(visible);
    final destinations = _destinations(l10n, visible);
    // Expressive (the default style) floats the bottom bar; Material 3 keeps
    // the classic full-width bar.
    final floatingNavBar = ref.watch(
      appSettingsProvider.select((s) => s.uiStyle == AppUiStyle.expressive),
    );
    final index = _currentIndex(context, visible);

    void select(int i) => context.go(routes[i]);

    if (!useNavigationRail(MediaQuery.sizeOf(context).width)) {
      final navDestinations = [
        for (final d in destinations)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          ),
      ];
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: floatingNavBar
            ? _FloatingNavBar(
                selectedIndex: index,
                onDestinationSelected: select,
                destinations: navDestinations,
              )
            : NavigationBar(
                selectedIndex: index,
                onDestinationSelected: select,
                destinations: navDestinations,
              ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Five destinations with labels run to roughly 370 logical pixels,
          // which fits every window wide enough to earn a rail — but a rail can
          // appear at compact heights, so let it scroll rather than overflow.
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: index,
                    onDestinationSelected: select,
                    labelType: NavigationRailLabelType.all,
                    // Centred rather than the default top alignment. A rail
                    // top-aligns to sit under a leading menu button or FAB;
                    // this one has neither, so destinations pinned to the top
                    // of a tall rail would leave the whole lower half empty.
                    // Centring also keeps them near the thumb when the window
                    // is tall.
                    groupAlignment: 0,
                    destinations: [
                      for (final d in destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

/// The bottom navigation bar drawn as a floating, pill-shaped island (1.6.0,
/// the default). Flutter ships no floating navigation bar, so this wraps the
/// stock [NavigationBar] in a stadium-shaped [Material] with side and bottom
/// margins. It sits in the Scaffold's `bottomNavigationBar` slot rather than
/// over the body, so pages never draw underneath it and keep their layout and
/// FAB positions.
class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> destinations;

  /// Key on the island's surface, so tests can tell the floating bar from the
  /// classic one.
  static const islandKey = ValueKey('floatingNavBarIsland');

  /// Purpose: Create a floating navigation bar instance.
  /// Inputs: `selectedIndex`, `onDestinationSelected`, `destinations` — passed
  /// through unchanged to the inner [NavigationBar].
  /// Returns: A new `_FloatingNavBar` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  /// Purpose: Build the island: margins, rounded surface, inner bar.
  /// Inputs: `context`.
  /// Returns: The widget tree for the floating bar.
  /// Side effects: None.
  /// Notes: The bottom system inset (gesture bar) is applied once, outside
  /// the island, and removed for the inner [NavigationBar] so it does not pad
  /// itself a second time. The island is capped in width so it stays a
  /// compact pill on wider phones and small tablets in portrait.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              key: islandKey,
              color: colorScheme.surfaceContainer,
              surfaceTintColor: Colors.transparent,
              shadowColor: colorScheme.shadow,
              elevation: 3,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: true,
                removeRight: true,
                removeBottom: true,
                child: NavigationBar(
                  height: 68,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: destinations,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Purpose: Create a shell destination instance.
  /// Inputs: `icon`, `selectedIcon`, `label`.
  /// Returns: A new `_ShellDestination` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _ShellDestination(this.icon, this.selectedIcon, this.label);
}

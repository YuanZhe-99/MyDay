import 'dart:math' as math;

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
  /// and the bottom bar are two renderings of the same destination list. The
  /// rail appears according to the navigation placement setting (1.6.1): never
  /// (`bottom`, the default), when [useNavigationRail] says the window is wide
  /// enough (`sideOnWide`), or always (`side`, phones included). The rail sits
  /// on the left or, by setting, the right. Expressive's bottom bar floats over
  /// the pages (`extendBody`), and the Scaffold reports its height as bottom
  /// padding so every page can leave room to scroll its last content above it
  /// (see [navBarAwarePadding]). Nothing here is stateful beyond the reminder
  /// callback, so folding a device swaps layouts on the next frame with no
  /// route change.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visible = ref.watch(intimacyVisibilityProvider).visible;
    final routes = _activeRoutes(visible);
    final destinations = _destinations(l10n, visible);
    final expressive = ref.watch(
      appSettingsProvider.select((s) => s.uiStyle == AppUiStyle.expressive),
    );
    final placement = ref.watch(
      appSettingsProvider.select((s) => s.navPlacement),
    );
    final railOnRight = ref.watch(
      appSettingsProvider.select((s) => s.navRailOnRight),
    );
    final index = _currentIndex(context, visible);

    void select(int i) => context.go(routes[i]);

    final wide = useNavigationRail(MediaQuery.sizeOf(context).width);
    // Navigation placement (1.6.1, bottom by default): the same for both
    // styles. Material 3 with the bottom placement uses the standard
    // NavigationBar on wide windows too.
    final showRail = switch (placement) {
      NavPlacement.bottom => false,
      NavPlacement.sideOnWide => wide,
      NavPlacement.side => true,
    };

    if (!showRail) {
      if (expressive) {
        return Scaffold(
          extendBody: true,
          // extendBody reports the bar's height as `padding`, which lists and
          // navBarAwarePadding use. A page's own Scaffold places its FAB from
          // `viewPadding` instead, so raise that too, or the FAB would sit
          // behind the floating bar.
          body: Builder(
            builder: (context) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  viewPadding: mq.viewPadding.copyWith(
                    bottom: math.max(mq.viewPadding.bottom, mq.padding.bottom),
                  ),
                ),
                child: widget.child,
              );
            },
          ),
          bottomNavigationBar: _ExpressiveNavBar(
            destinations: destinations,
            selectedIndex: index,
            onSelected: select,
          ),
        );
      }
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: select,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    // Five destinations with labels run to roughly 370 logical pixels, which
    // fits every window wide enough to earn a rail — but a rail can appear at
    // compact heights, so let it scroll rather than overflow.
    final rail = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: index,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              // Centred rather than the default top alignment. A rail
              // top-aligns to sit under a leading menu button or FAB; this one
              // has neither, so destinations pinned to the top of a tall rail
              // would leave the whole lower half empty. Centring also keeps
              // them near the thumb when the window is tall.
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
    );
    const divider = VerticalDivider(width: 1);
    return Scaffold(
      body: Row(
        children: railOnRight
            ? [Expanded(child: widget.child), divider, rail]
            : [rail, divider, Expanded(child: widget.child)],
      ),
    );
  }
}

/// The Expressive bottom navigation bar (1.7.2): a compact floating pill that
/// hugs its items, modelled on Material 3 Expressive's floating navigation.
/// The selected destination shows its icon and label side by side in a
/// tonal pill; the others show their icon only. It floats over the page
/// (the shell sets `extendBody`), with margins from the screen edges.
class _ExpressiveNavBar extends StatelessWidget {
  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Key on the island's surface, so tests can tell it from the classic bar.
  static const islandKey = ValueKey('floatingNavBarIsland');

  /// Purpose: Create the Expressive navigation bar.
  /// Inputs: `destinations`, `selectedIndex`, `onSelected`.
  /// Returns: A new `_ExpressiveNavBar` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _ExpressiveNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Purpose: Build the island and its items.
  /// Inputs: `context`.
  /// Returns: The floating bar, centred above the system inset.
  /// Side effects: None.
  /// Notes: The bar is as wide as its items; on very narrow screens it scales
  /// down instead of overflowing.
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          heightFactor: 1,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Material(
              key: islandKey,
              color: cs.surfaceContainer,
              surfaceTintColor: Colors.transparent,
              shadowColor: cs.shadow,
              elevation: 3,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < destinations.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      _ExpressiveNavItem(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        onTap: () => onSelected(i),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One destination of [_ExpressiveNavBar].
class _ExpressiveNavItem extends StatelessWidget {
  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  /// Purpose: Create one Expressive navigation item.
  /// Inputs: `destination`, `selected`, `onTap`.
  /// Returns: A new `_ExpressiveNavItem` instance.
  /// Side effects: None.
  /// Notes: Internal helper used within this file only.
  const _ExpressiveNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  /// Purpose: Build the item: icon, plus the label while selected.
  /// Inputs: `context`.
  /// Returns: A tappable pill.
  /// Side effects: Calls [onTap] when tapped.
  /// Notes: The pill's width and colour animate when the selection moves.
  /// Unselected items carry a tooltip and a semantic label, since their text
  /// is hidden.
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    const duration = Duration(milliseconds: 250);
    Widget item = InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: selected ? 20 : 16),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: selected ? cs.secondaryContainer : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              color: fg,
              size: 24,
            ),
            AnimatedSize(
              duration: duration,
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: fg),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
    if (!selected) {
      item = Tooltip(message: destination.label, child: item);
    }
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: selected ? null : destination.label,
      child: item,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../providers/intimacy_visibility.dart';
import '../services/reminder_service.dart';

class ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  static const _routes = ['/todo', '/finance', '/weight', '/intimacy', '/settings'];
  static const _routesHidden = ['/todo', '/finance', '/weight', '/settings'];

  List<String> _activeRoutes(bool visible) => visible ? _routes : _routesHidden;

  int _currentIndex(BuildContext context, bool visible) {
    final location = GoRouterState.of(context).uri.path;
    final routes = _activeRoutes(visible);
    for (var i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) return i;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    // Wire in-app snackbar to global reminder service
    ReminderService.instance.onShowSnackbar = _showReminderSnackbar;
  }

  @override
  void dispose() {
    ReminderService.instance.onShowSnackbar = null;
    super.dispose();
  }

  void _showReminderSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = ref.watch(intimacyVisibilityProvider).visible;
    final routes = _activeRoutes(visible);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context, visible),
        onDestinationSelected: (index) {
          context.go(routes[index]);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.check_circle_outline),
            selectedIcon: const Icon(Icons.check_circle),
            label: AppLocalizations.of(context)!.navTodo,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: AppLocalizations.of(context)!.navFinance,
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_weight_outlined),
            selectedIcon: const Icon(Icons.monitor_weight),
            label: AppLocalizations.of(context)!.navWeight,
          ),
          if (visible)
            NavigationDestination(
              icon: const Icon(Icons.favorite_border),
              selectedIcon: const Icon(Icons.favorite),
              label: AppLocalizations.of(context)!.navIntimacy,
            ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.navSettings,
          ),
        ],
      ),
    );
  }
}

import 'package:go_router/go_router.dart';

import '../features/todo/views/todo_page.dart';
import '../features/finance/views/finance_page.dart';
import '../features/settings/views/settings_page.dart';
import '../features/intimacy/views/intimacy_page.dart';
import '../features/weight/views/weight_page.dart';
import '../shared/widgets/shell_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/todo',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/todo',
          builder: (context, state) => const TodoPage(),
        ),
        GoRoute(
          path: '/finance',
          builder: (context, state) => const FinancePage(),
        ),
        GoRoute(
          path: '/weight',
          builder: (context, state) => const WeightPage(),
        ),
        GoRoute(
          path: '/intimacy',
          builder: (context, state) => const IntimacyPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);

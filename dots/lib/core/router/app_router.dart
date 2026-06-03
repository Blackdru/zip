import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/practice/practice_screen.dart';
import '../../features/puzzle/connect_dots_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/practice',
      name: 'practice',
      builder: (context, state) => const PracticeScreen(),
    ),
    GoRoute(
      path: '/puzzle',
      name: 'puzzle',
      builder: (context, state) {
        final puzzleId = state.uri.queryParameters['puzzleId'];
        final isPractice = state.uri.queryParameters['isPractice'] == 'true';
        return ConnectDotsScreen(
          puzzleId: puzzleId,
          isPractice: isPractice,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

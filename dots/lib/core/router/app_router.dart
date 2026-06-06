import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/practice/practice_screen.dart';
import '../../features/puzzle/connect_dots_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
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

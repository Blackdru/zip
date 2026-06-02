import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/home_screen.dart';
import '../../features/practice/practice_screen.dart';
import '../../features/puzzle/puzzle_screen.dart';
import '../../features/settings/settings_screen.dart';

/// App routes
class AppRoutes {
  static const String home = '/home';
  static const String practice = '/play';
  static const String puzzle = '/puzzle';
  static const String settings = '/settings';
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.practice,
        builder: (context, state) => const PracticeScreen(),
      ),
      GoRoute(
        path: AppRoutes.puzzle,
        builder: (context, state) {
          final puzzleId = state.uri.queryParameters['id'];
          final isPractice = state.uri.queryParameters['practice'] == 'true';
          return PuzzleScreen(
            puzzleId: puzzleId,
            isPractice: isPractice,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

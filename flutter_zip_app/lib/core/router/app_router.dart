import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/home_screen.dart';
import '../../features/tournament/tournament_screen.dart';
import '../../features/practice/practice_screen.dart';
import '../../features/puzzle/puzzle_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';

/// App routes
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String tournament = '/tournament';
  static const String practice = '/practice';
  static const String puzzle = '/puzzle';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';
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
        path: AppRoutes.tournament,
        builder: (context, state) => const TournamentScreen(),
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
        path: AppRoutes.leaderboard,
        builder: (context, state) {
          final tournamentId = state.uri.queryParameters['tournamentId'];
          return LeaderboardScreen(tournamentId: tournamentId);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/puzzle_service.dart';
import '../services/tournament_service.dart';
import '../services/leaderboard_service.dart';

/// API Client provider - keepAlive to maintain connection across rebuilds
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  // Keep alive to prevent recreation on every rebuild
  ref.keepAlive();
  return client;
});

/// Auth Service provider - keepAlive for consistency
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final service = AuthService(apiClient);
  ref.keepAlive();
  return service;
});

/// Puzzle Service provider - keepAlive for consistency
final puzzleServiceProvider = Provider<PuzzleService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final service = PuzzleService(apiClient);
  ref.keepAlive();
  return service;
});

/// Tournament Service provider - keepAlive for consistency
final tournamentServiceProvider = Provider<TournamentService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final service = TournamentService(apiClient);
  ref.keepAlive();
  return service;
});

/// Leaderboard Service provider - keepAlive for consistency
final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final service = LeaderboardService(apiClient);
  ref.keepAlive();
  return service;
});

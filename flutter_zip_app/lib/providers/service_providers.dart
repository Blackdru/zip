import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../services/puzzle_service.dart';
import '../services/puzzle_stats_service.dart';

/// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// API Client provider - keepAlive to maintain connection across rebuilds
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  // Keep alive to prevent recreation on every rebuild
  ref.keepAlive();
  return client;
});

/// Puzzle Service provider - keepAlive for consistency
final puzzleServiceProvider = Provider<PuzzleService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final service = PuzzleService(apiClient);
  ref.keepAlive();
  return service;
});

/// Puzzle Stats Service Provider
final puzzleStatsServiceProvider = Provider<PuzzleStatsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PuzzleStatsService(prefs);
});

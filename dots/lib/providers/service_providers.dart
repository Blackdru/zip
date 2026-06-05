import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../services/connect_dots_service.dart';
import '../services/puzzle_stats_service.dart';

/// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Connect Dots Service Provider
final connectDotsServiceProvider = Provider<ConnectDotsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ConnectDotsService(apiClient);
});

/// Puzzle Stats Service Provider
final puzzleStatsServiceProvider = Provider<PuzzleStatsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PuzzleStatsService(prefs);
});

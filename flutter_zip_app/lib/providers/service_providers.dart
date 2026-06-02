import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/puzzle_service.dart';

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

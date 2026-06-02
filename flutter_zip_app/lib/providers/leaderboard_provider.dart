import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard.dart';
import '../services/leaderboard_service.dart';
import 'service_providers.dart';

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? myEntry;
  final int total;
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    this.entries = const [],
    this.myEntry,
    this.total = 0,
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    LeaderboardEntry? myEntry,
    int? total,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      myEntry: myEntry ?? this.myEntry,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final LeaderboardService _leaderboardService;

  LeaderboardNotifier(this._leaderboardService) : super(const LeaderboardState());

  Future<void> loadLeaderboard(String tournamentId, {int limit = 100, int offset = 0}) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _leaderboardService.getLeaderboard(
        tournamentId: tournamentId,
        limit: limit,
        offset: offset,
      );

      state = LeaderboardState(
        entries: response.entries,
        myEntry: response.myEntry,
        total: response.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  final leaderboardService = ref.watch(leaderboardServiceProvider);
  return LeaderboardNotifier(leaderboardService);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/puzzle_stats_service.dart';
import 'service_providers.dart';

/// State class for puzzle statistics
class PuzzleStatsState {
  final int totalCompleted;
  
  const PuzzleStatsState({
    required this.totalCompleted,
  });
  
  PuzzleStatsState copyWith({
    int? totalCompleted,
  }) {
    return PuzzleStatsState(
      totalCompleted: totalCompleted ?? this.totalCompleted,
    );
  }
}

/// Notifier for managing puzzle statistics
class PuzzleStatsNotifier extends StateNotifier<PuzzleStatsState> {
  final PuzzleStatsService _statsService;
  
  PuzzleStatsNotifier(this._statsService)
      : super(PuzzleStatsState(
          totalCompleted: _statsService.getTotalCompletedPuzzles(),
        ));
  
  /// Mark a puzzle as completed
  Future<void> markPuzzleCompleted() async {
    await _statsService.incrementCompletedPuzzles();
    state = PuzzleStatsState(
      totalCompleted: _statsService.getTotalCompletedPuzzles(),
    );
  }
  
  /// Reset total count
  Future<void> resetTotal() async {
    await _statsService.resetTotalCount();
    state = state.copyWith(totalCompleted: 0);
  }
  
  /// Refresh stats from storage
  void refresh() {
    state = PuzzleStatsState(
      totalCompleted: _statsService.getTotalCompletedPuzzles(),
    );
  }
}

/// Provider for puzzle statistics
final puzzleStatsProvider = StateNotifierProvider<PuzzleStatsNotifier, PuzzleStatsState>((ref) {
  final statsService = ref.watch(puzzleStatsServiceProvider);
  return PuzzleStatsNotifier(statsService);
});

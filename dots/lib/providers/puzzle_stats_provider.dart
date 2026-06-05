import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/puzzle_stats_service.dart';
import 'service_providers.dart';

/// State class for puzzle statistics
class PuzzleStatsState {
  final int totalCompleted;
  final int sessionCompleted;
  
  const PuzzleStatsState({
    required this.totalCompleted,
    required this.sessionCompleted,
  });
  
  PuzzleStatsState copyWith({
    int? totalCompleted,
    int? sessionCompleted,
  }) {
    return PuzzleStatsState(
      totalCompleted: totalCompleted ?? this.totalCompleted,
      sessionCompleted: sessionCompleted ?? this.sessionCompleted,
    );
  }
}

/// Notifier for managing puzzle statistics
class PuzzleStatsNotifier extends StateNotifier<PuzzleStatsState> {
  final PuzzleStatsService _statsService;
  
  PuzzleStatsNotifier(this._statsService)
      : super(PuzzleStatsState(
          totalCompleted: _statsService.getTotalCompletedPuzzles(),
          sessionCompleted: _statsService.getSessionCompletedPuzzles(),
        ));
  
  /// Mark a puzzle as completed
  Future<void> markPuzzleCompleted() async {
    await _statsService.incrementCompletedPuzzles();
    state = PuzzleStatsState(
      totalCompleted: _statsService.getTotalCompletedPuzzles(),
      sessionCompleted: _statsService.getSessionCompletedPuzzles(),
    );
  }
  
  /// Reset session count
  Future<void> resetSession() async {
    await _statsService.resetSessionCount();
    state = state.copyWith(sessionCompleted: 0);
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
      sessionCompleted: _statsService.getSessionCompletedPuzzles(),
    );
  }
}

/// Provider for puzzle statistics
final puzzleStatsProvider = StateNotifierProvider<PuzzleStatsNotifier, PuzzleStatsState>((ref) {
  final statsService = ref.watch(puzzleStatsServiceProvider);
  return PuzzleStatsNotifier(statsService);
});

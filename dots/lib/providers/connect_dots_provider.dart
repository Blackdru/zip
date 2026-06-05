import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connect_dots_puzzle.dart';
import '../models/color_dot.dart';
import '../services/connect_dots_service.dart';
import 'service_providers.dart';

// Private sentinel: distinguishes "caller did not supply error" from
// "caller explicitly passed null to clear the error".
const Object _kKeepError = Object();

class ConnectDotsState {
  final ConnectDotsPuzzle? puzzle;
  final bool isLoading;
  final String? error;
  final PuzzleResult? lastResult;
  final List<SolutionPath> practiceSolutionPaths;

  const ConnectDotsState({
    this.puzzle,
    this.isLoading = false,
    this.error,
    this.lastResult,
    this.practiceSolutionPaths = const [],
  });

  /// BUG FIX: The original `copyWith` used `error: error` which ALWAYS
  /// overwrote the stored error, even when the caller omitted the argument
  /// (Dart defaults it to null). This meant `state.copyWith(isLoading: false)`
  /// silently cleared any active error string.
  ///
  /// Solution: use a private sentinel constant so we can tell the difference
  /// between "caller passed nothing" (_kKeepError) and "caller explicitly
  /// passed null to clear the error".
  ConnectDotsState copyWith({
    ConnectDotsPuzzle? puzzle,
    bool? isLoading,
    Object? error = _kKeepError, // sentinel default
    PuzzleResult? lastResult,
    List<SolutionPath>? practiceSolutionPaths,
  }) {
    return ConnectDotsState(
      puzzle: puzzle ?? this.puzzle,
      isLoading: isLoading ?? this.isLoading,
      // Only replace error when the caller explicitly supplied a value.
      error: identical(error, _kKeepError) ? this.error : error as String?,
      lastResult: lastResult ?? this.lastResult,
      practiceSolutionPaths:
          practiceSolutionPaths ?? this.practiceSolutionPaths,
    );
  }

  /// Convenience: explicitly clear the error without touching other fields.
  ConnectDotsState clearError() => copyWith(error: null);
}

class ConnectDotsNotifier extends StateNotifier<ConnectDotsState> {
  final ConnectDotsService _service;

  ConnectDotsNotifier(this._service) : super(const ConnectDotsState());

  Future<void> loadPuzzle(String puzzleId) async {
    state = state.copyWith(isLoading: true);

    try {
      final puzzle = await _service.getPuzzle(puzzleId);
      state = ConnectDotsState(
        puzzle: puzzle,
        practiceSolutionPaths: puzzle.solutionPaths,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> generatePracticePuzzle(
      Difficulty difficulty, int sequence) async {
    state = state.copyWith(isLoading: true);

    try {
      final puzzle = await _service.getPracticePuzzle(
        difficulty: difficulty,
        sequence: sequence,
      );
      state = ConnectDotsState(
        puzzle: puzzle,
        practiceSolutionPaths: puzzle.solutionPaths,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Generate a random puzzle from the server (random difficulty)
  Future<void> generateRandomPuzzle() async {
    state = state.copyWith(isLoading: true);

    try {
      final puzzle = await _service.getRandomPuzzle();
      state = ConnectDotsState(
        puzzle: puzzle,
        practiceSolutionPaths: puzzle.solutionPaths,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> submitSolution(
    String puzzleId,
    List<PlayerPath> playerPaths,
    int clientSolveTimeMs,
  ) async {
    try {
      final result = await _service.submitSolution(
        puzzleId: puzzleId,
        playerPaths: playerPaths,
        clientSolveTimeMs: clientSolveTimeMs,
      );
      state = state.copyWith(lastResult: result);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Explicitly dismiss any active error without triggering a new load.
  void clearError() {
    state = state.clearError();
  }
}

final connectDotsProvider =
    StateNotifierProvider<ConnectDotsNotifier, ConnectDotsState>((ref) {
  final service = ref.watch(connectDotsServiceProvider);
  return ConnectDotsNotifier(service);
});

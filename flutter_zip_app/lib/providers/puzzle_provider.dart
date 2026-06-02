import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/puzzle.dart';
import '../models/grid_cell.dart';
import '../services/puzzle_service.dart';
import 'service_providers.dart';

class PuzzleState {
  final PuzzleData? puzzle;
  final bool isLoading;
  final String? error;
  final SubmitResult? lastResult;
  /// Solution path for unlimited puzzles — used for reveal-next-step hints
  final List<SolutionStep> practiceSolutionPath;

  const PuzzleState({
    this.puzzle,
    this.isLoading = false,
    this.error,
    this.lastResult,
    this.practiceSolutionPath = const [],
  });

  PuzzleState copyWith({
    PuzzleData? puzzle,
    bool? isLoading,
    String? error,
    SubmitResult? lastResult,
    List<SolutionStep>? practiceSolutionPath,
  }) {
    return PuzzleState(
      puzzle: puzzle ?? this.puzzle,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastResult: lastResult ?? this.lastResult,
      practiceSolutionPath: practiceSolutionPath ?? this.practiceSolutionPath,
    );
  }
}

class PuzzleNotifier extends StateNotifier<PuzzleState> {
  final PuzzleService _puzzleService;

  PuzzleNotifier(this._puzzleService) : super(const PuzzleState());

  Future<void> loadPuzzle(String puzzleId) async {
    state = state.copyWith(isLoading: true);

    try {
      final puzzle = await _puzzleService.getPuzzle(puzzleId);
      state = PuzzleState(
        puzzle: puzzle,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> generatePracticePuzzle(Difficulty difficulty, int sequence) async {
    state = state.copyWith(isLoading: true);

    try {
      final result = await _puzzleService.getPracticePuzzle(
        difficulty: difficulty,
        sequence: sequence,
      );
      state = PuzzleState(
        puzzle: result.puzzle,
        practiceSolutionPath: result.solutionPath,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Generate a fully random puzzle — random difficulty + random sequence
  Future<void> generateRandomPuzzle() async {
    final rng = Random();
    const difficulties = Difficulty.values;
    final difficulty = difficulties[rng.nextInt(difficulties.length)];
    final sequence = rng.nextInt(999) + 1;
    await generatePracticePuzzle(difficulty, sequence);
  }

  Future<void> submitSolution(
    String puzzleId,
    List<Move> moveSequence,
    int clientSolveTimeMs,
  ) async {
    try {
      final result = await _puzzleService.submitSolution(
        puzzleId: puzzleId,
        moveSequence: moveSequence,
        clientSolveTimeMs: clientSolveTimeMs,
        serverStartedAt: DateTime.now()
            .subtract(Duration(milliseconds: clientSolveTimeMs))
            .toIso8601String(),
      );

      state = state.copyWith(lastResult: result);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final puzzleProvider = StateNotifierProvider<PuzzleNotifier, PuzzleState>((ref) {
  final puzzleService = ref.watch(puzzleServiceProvider);
  return PuzzleNotifier(puzzleService);
});

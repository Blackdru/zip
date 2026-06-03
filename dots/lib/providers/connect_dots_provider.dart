import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connect_dots_puzzle.dart';
import '../models/color_dot.dart';
import '../services/connect_dots_service.dart';
import 'service_providers.dart';

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

  ConnectDotsState copyWith({
    ConnectDotsPuzzle? puzzle,
    bool? isLoading,
    String? error,
    PuzzleResult? lastResult,
    List<SolutionPath>? practiceSolutionPaths,
  }) {
    return ConnectDotsState(
      puzzle: puzzle ?? this.puzzle,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastResult: lastResult ?? this.lastResult,
      practiceSolutionPaths:
          practiceSolutionPaths ?? this.practiceSolutionPaths,
    );
  }
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

  Future<void> generateRandomPuzzle() async {
    final rng = Random();
    const difficulties = Difficulty.values;
    final difficulty = difficulties[rng.nextInt(difficulties.length)];
    final sequence = rng.nextInt(999) + 1;
    await generatePracticePuzzle(difficulty, sequence);
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
}

final connectDotsProvider =
    StateNotifierProvider<ConnectDotsNotifier, ConnectDotsState>((ref) {
  final service = ref.watch(connectDotsServiceProvider);
  return ConnectDotsNotifier(service);
});

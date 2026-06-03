import 'package:freezed_annotation/freezed_annotation.dart';
import 'color_dot.dart';

part 'connect_dots_puzzle.freezed.dart';
part 'connect_dots_puzzle.g.dart';

enum Difficulty {
  @JsonValue('easy')
  easy,
  @JsonValue('medium')
  medium,
  @JsonValue('hard')
  hard,
}

/// Represents Connect Dots puzzle data from the backend
@freezed
class ConnectDotsPuzzle with _$ConnectDotsPuzzle {
  const factory ConnectDotsPuzzle({
    String? id,
    required String seed,
    required int gridSize,
    required Difficulty difficulty,
    required List<ColorDot> colorDots,
    required int totalPairs,
    @Default([]) List<SolutionPath> solutionPaths,
  }) = _ConnectDotsPuzzle;

  factory ConnectDotsPuzzle.fromJson(Map<String, dynamic> json) =>
      _$ConnectDotsPuzzleFromJson(json);
}

/// Represents the result of a puzzle submission
@freezed
class PuzzleResult with _$PuzzleResult {
  const factory PuzzleResult({
    String? puzzleId,
    required int solveTimeMs,
    required bool isPersonalBest,
    required bool isValid,
    @Default([]) List<String> errors,
    @Default([]) List<String> warnings,
  }) = _PuzzleResult;

  factory PuzzleResult.fromJson(Map<String, dynamic> json) =>
      _$PuzzleResultFromJson(json);
}

/// Represents the game phase
enum GamePhase {
  idle,
  playing,
  completed,
  invalid,
}

/// Represents the current game state
@freezed
class GameState with _$GameState {
  const factory GameState({
    @Default(GamePhase.idle) GamePhase phase,
    @Default({}) Map<int, List<PathCell>> activePaths, // pairId -> path
    @Default(null) int? currentPairId, // Currently drawing path for this pair
    required int totalPairs,
    @Default(0) int completedPairs,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
}

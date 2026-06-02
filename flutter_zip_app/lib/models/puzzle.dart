import 'package:freezed_annotation/freezed_annotation.dart';
import 'grid_cell.dart';
import 'wall.dart';

part 'puzzle.freezed.dart';
part 'puzzle.g.dart';

enum Difficulty {
  @JsonValue('easy')
  easy,
  @JsonValue('medium')
  medium,
  @JsonValue('hard')
  hard,
}

/// Represents puzzle data from the backend
@freezed
class PuzzleData with _$PuzzleData {
  const factory PuzzleData({
    String? id,
    required String seed,
    required int gridSize,
    required Difficulty difficulty,
    required List<ClueNumber> clueNumbers,
    required int totalCheckpoints,
    @Default([]) List<GridCell> obstacles,
    @Default([]) List<Wall> walls,
  }) = _PuzzleData;

  factory PuzzleData.fromJson(Map<String, dynamic> json) =>
      _$PuzzleDataFromJson(json);
}

/// Represents the result of a puzzle submission
@freezed
class PuzzleResult with _$PuzzleResult {
  const factory PuzzleResult({
    String? puzzleId,
    required int solveTimeMs,
    required bool isPersonalBest,
    required bool isValid,
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
    @Default([]) List<GridCell> currentPath,
    @Default(0) int solvedCheckpoints,
    required int totalCheckpoints,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
}

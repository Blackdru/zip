import 'package:freezed_annotation/freezed_annotation.dart';

part 'grid_cell.freezed.dart';
part 'grid_cell.g.dart';

/// Represents a cell position in the puzzle grid
@freezed
class GridCell with _$GridCell {
  const factory GridCell({
    required int x, // column (0-indexed)
    required int y, // row (0-indexed)
  }) = _GridCell;

  factory GridCell.fromJson(Map<String, dynamic> json) =>
      _$GridCellFromJson(json);
}

/// Represents a clue number with its position
@freezed
class ClueNumber with _$ClueNumber {
  const factory ClueNumber({
    required int x,
    required int y,
    required int num,
  }) = _ClueNumber;

  factory ClueNumber.fromJson(Map<String, dynamic> json) =>
      _$ClueNumberFromJson(json);
}

/// Represents a solution step
@freezed
class SolutionStep with _$SolutionStep {
  const factory SolutionStep({
    required int x,
    required int y,
    int? num,
  }) = _SolutionStep;

  factory SolutionStep.fromJson(Map<String, dynamic> json) =>
      _$SolutionStepFromJson(json);
}

/// Represents a move with timestamp for replay
@freezed
class Move with _$Move {
  const factory Move({
    required int x,
    required int y,
    required int timestampMs,
  }) = _Move;

  factory Move.fromJson(Map<String, dynamic> json) => _$MoveFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'color_dot.freezed.dart';
part 'color_dot.g.dart';

/// Represents a colored dot in the Connect Dots puzzle
@freezed
class ColorDot with _$ColorDot {
  const factory ColorDot({
    required int x,
    required int y,
    required String color,
    required int pairId,
  }) = _ColorDot;

  factory ColorDot.fromJson(Map<String, dynamic> json) =>
      _$ColorDotFromJson(json);
}

/// Represents a cell in a path
@freezed
class PathCell with _$PathCell {
  const factory PathCell({
    required int x,
    required int y,
    int? timestampMs,
  }) = _PathCell;

  factory PathCell.fromJson(Map<String, dynamic> json) =>
      _$PathCellFromJson(json);
}

/// Represents a complete path for a pair
@freezed
class PlayerPath with _$PlayerPath {
  const factory PlayerPath({
    required int pairId,
    required List<PathCell> path,
  }) = _PlayerPath;

  factory PlayerPath.fromJson(Map<String, dynamic> json) =>
      _$PlayerPathFromJson(json);
}

/// Represents a solution path hint
@freezed
class SolutionPath with _$SolutionPath {
  const factory SolutionPath({
    required int pairId,
    required List<PathCell> path,
  }) = _SolutionPath;

  factory SolutionPath.fromJson(Map<String, dynamic> json) =>
      _$SolutionPathFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'wall.freezed.dart';
part 'wall.g.dart';

/// Represents a wall barrier in the puzzle
@freezed
class Wall with _$Wall {
  const factory Wall({
    required int x,
    required int y,
    required int length,
    required bool isVertical,
  }) = _Wall;

  factory Wall.fromJson(Map<String, dynamic> json) => _$WallFromJson(json);
}

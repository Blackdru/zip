import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/grid_cell.dart';
import '../../models/wall.dart';

/// Renders the puzzle board grid and clue numbers
class PuzzleBoard extends PositionComponent with HasGameRef {
  final int gridSize;
  final List<ClueNumber> clueNumbers;
  final List<GridCell> obstacles;
  final List<Wall> walls;

  late double cellSize;
  late double boardSize;

  PuzzleBoard({
    required this.gridSize,
    required this.clueNumbers,
    required this.obstacles,
    required this.walls,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Calculate cell size based on game size
    final gameSize = gameRef.size;
    const padding = 40.0;
    final availableSize = gameSize.x < gameSize.y ? gameSize.x : gameSize.y;
    boardSize = availableSize - (padding * 2);
    cellSize = boardSize / gridSize;

    // Center the board
    position = Vector2(
      (gameSize.x - boardSize) / 2,
      (gameSize.y - boardSize) / 2,
    );

    size = Vector2(boardSize, boardSize);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _drawObstacles(canvas);
    _drawGrid(canvas);
    // Checkpoints moved to separate component to render on top of path
  }

  void _drawObstacles(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.fill;

    const obstaclePadding = 4.0;

    for (final obstacle in obstacles) {
      final rect = Rect.fromLTWH(
        (obstacle.x * cellSize) + obstaclePadding,
        (obstacle.y * cellSize) + obstaclePadding,
        cellSize - (obstaclePadding * 2),
        cellSize - (obstaclePadding * 2),
      );
      canvas.drawRect(rect, paint);
    }
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF424242) // Dark grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // Slightly thicker for visibility

    const cornerRadius = 8.0; // Rounded corners

    // Draw cells with rounded corners
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            col * cellSize,
            row * cellSize,
            cellSize,
            cellSize,
          ),
          const Radius.circular(cornerRadius),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  /// Convert screen position to grid cell
  GridCell? screenToGrid(Vector2 screenPos) {
    final localPos = screenPos - position;

    if (localPos.x < 0 ||
        localPos.y < 0 ||
        localPos.x > boardSize ||
        localPos.y > boardSize) {
      return null;
    }

    final x = (localPos.x / cellSize).floor();
    final y = (localPos.y / cellSize).floor();

    if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
      return GridCell(x: x, y: y);
    }

    return null;
  }

  /// Convert grid cell to screen center position
  Vector2 gridToScreenCenter(GridCell cell) {
    return position +
        Vector2(
          (cell.x * cellSize) + (cellSize / 2),
          (cell.y * cellSize) + (cellSize / 2),
        );
  }
}

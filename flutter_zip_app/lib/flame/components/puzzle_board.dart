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
    // Enhanced obstacles with glow
    for (final obstacle in obstacles) {
      const obstaclePadding = 4.0;
      
      final rect = Rect.fromLTWH(
        (obstacle.x * cellSize) + obstaclePadding,
        (obstacle.y * cellSize) + obstaclePadding,
        cellSize - (obstaclePadding * 2),
        cellSize - (obstaclePadding * 2),
      );
      
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      
      // Outer glow
      final glowPaint = Paint()
        ..color = const Color(0xFF1A0B2E).withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(rrect, glowPaint);
      
      // Dark gradient fill
      final gradientPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0B2E), // Deep purple
            Color(0xFF0A0515), // Almost black
          ],
        ).createShader(rect);
      
      canvas.drawRRect(rrect, gradientPaint);
      
      // Bright border with subtle glow
      final borderGlowPaint = Paint()
        ..color = const Color(0xFF6C3AFF).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(rrect, borderGlowPaint);
      
      // Solid border
      final borderPaint = Paint()
        ..color = const Color(0xFF6C3AFF).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  void _drawGrid(Canvas canvas) {
    // Draw cell backgrounds with subtle gradient
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final rect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        );
        
        // Gradient background for each cell
        final gradientPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2D1B4E).withValues(alpha: 0.4), // Rich purple
              const Color(0xFF1A0B2E).withValues(alpha: 0.3), // Deep purple
            ],
          ).createShader(rect);
        
        final cellRRect = RRect.fromRectAndRadius(
          rect,
          const Radius.circular(8.0),
        );
        
        canvas.drawRRect(cellRRect, gradientPaint);
      }
    }
    
    // Draw glowing borders (subtle)
    final glowPaint = Paint()
      ..color = const Color(0xFF6C3AFF).withValues(alpha: 0.2) // Reduced glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    final borderPaint = Paint()
      ..color = const Color(0xFF6C3AFF).withValues(alpha: 0.5) // Slightly reduced
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Draw cell borders with glow
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            col * cellSize,
            row * cellSize,
            cellSize,
            cellSize,
          ),
          const Radius.circular(8.0),
        );
        
        // Glow layer
        canvas.drawRRect(rect, glowPaint);
        // Solid border
        canvas.drawRRect(rect, borderPaint);
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

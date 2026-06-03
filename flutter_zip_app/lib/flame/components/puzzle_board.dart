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
    const padding = 20.0; // Reduced padding to increase board size
    final availableSize = gameSize.x < gameSize.y ? gameSize.x : gameSize.y;
    boardSize = availableSize - (padding * 2);
    cellSize = boardSize / gridSize;

    // Center the board horizontally, position slightly higher for banner ad at bottom
    position = Vector2(
      (gameSize.x - boardSize) / 2,
      (gameSize.y - boardSize) / 2 - 30, // Moved up by 30px to accommodate banner ad
    );

    size = Vector2(boardSize, boardSize);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _drawBoardBorder(canvas);
    _drawGrid(canvas);
    _drawGridDots(canvas);
    _drawObstacles(canvas);
  }

  void _drawBoardBorder(Canvas canvas) {
    // Draw thick purple gradient border - NO outer glow/shadow
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-5, -5, boardSize + 10, boardSize + 10),
      Radius.circular(cellSize * 0.4),
    );

    // Main gradient border - doubled thickness, NO glow
    final borderPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF8B5CF6), // Bright purple
          Color(0xFF6366F1), // Indigo
          Color(0xFFA855F7), // Lighter purple
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(borderRect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10; // Doubled from 5 to 10
    canvas.drawRRect(borderRect, borderPaint);

    // Inner subtle highlight
    final innerHighlightPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-4, -4, boardSize + 8, boardSize + 8),
        Radius.circular(cellSize * 0.4),
      ),
      innerHighlightPaint,
    );
  }

  void _drawObstacles(Canvas canvas) {
    // Obstacles slightly more visible than before
    for (final obstacle in obstacles) {
      const obstaclePadding = 3.0;
      
      final rect = Rect.fromLTWH(
        (obstacle.x * cellSize) + obstaclePadding,
        (obstacle.y * cellSize) + obstaclePadding,
        cellSize - (obstaclePadding * 2),
        cellSize - (obstaclePadding * 2),
      );
      
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cellSize * 0.12));
      
      // Dark but slightly visible fill
      final fillPaint = Paint()
        ..color = const Color(0xFF0E0E18);
      canvas.drawRRect(rrect, fillPaint);
      
      // Visible border
      final borderPaint = Paint()
        ..color = const Color(0xFF1E1E30).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  void _drawGrid(Canvas canvas) {
    // Draw cell backgrounds - more visible with clear purple/blue tint
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final rect = Rect.fromLTWH(
          col * cellSize + 1,
          row * cellSize + 1,
          cellSize - 2,
          cellSize - 2,
        );
        
        final cellRRect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(cellSize * 0.15),
        );
        
        // More visible cell background with clear gradient
        final cellPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF242438), // More visible dark blue-purple
              Color(0xFF1A1A2A), // Lighter dark
            ],
          ).createShader(rect);
        canvas.drawRRect(cellRRect, cellPaint);
        
        // Clearer border for cell definition
        final borderPaint = Paint()
          ..color = const Color(0xFF34344A).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawRRect(cellRRect, borderPaint);
      }
    }
  }

  void _drawGridDots(Canvas canvas) {
    // Draw dots only at internal cell intersections (not on the board edges)
    final dotRadius = cellSize * 0.045;
    
    // Draw dots at internal grid intersections only (exclude edges)
    for (int row = 1; row < gridSize; row++) {
      for (int col = 1; col < gridSize; col++) {
        final x = col * cellSize;
        final y = row * cellSize;
        final center = Offset(x, y);
        
        // Visible glow around dot
        final glowPaint = Paint()
          ..color = const Color(0xFF6B7AFF).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(center, dotRadius * 2.2, glowPaint);
        
        // Main dot - more visible
        final dotPaint = Paint()
          ..color = const Color(0xFF5A6AAA).withValues(alpha: 0.85);
        canvas.drawCircle(center, dotRadius, dotPaint);
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

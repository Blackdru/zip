import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/color_dot.dart';

/// Renders the puzzle board grid (identical to ZIP puzzle board)
class DotsBoard extends PositionComponent with HasGameReference {
  final int gridSize;
  final List<ColorDot> colorDots;

  late double cellSize;
  late double boardSize;

  DotsBoard({
    required this.gridSize,
    required this.colorDots,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final gameSize = game.size;
    const padding = 20.0;
    final availableSize = gameSize.x < gameSize.y ? gameSize.x : gameSize.y;
    boardSize = availableSize - (padding * 2);
    cellSize = boardSize / gridSize;

    position = Vector2(
      (gameSize.x - boardSize) / 2,
      (gameSize.y - boardSize) / 2 - 30,
    );

    size = Vector2(boardSize, boardSize);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawBoardBorder(canvas);
    _drawGrid(canvas);
    _drawGridDots(canvas);
  }

  void _drawBoardBorder(Canvas canvas) {
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-5, -5, boardSize + 10, boardSize + 10),
      Radius.circular(cellSize * 0.4),
    );

    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF8B5CF6),
          const Color(0xFF6366F1),
          const Color(0xFFA855F7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(borderRect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawRRect(borderRect, borderPaint);

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

  void _drawGrid(Canvas canvas) {
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

        final cellPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF242438),
              const Color(0xFF1A1A2A),
            ],
          ).createShader(rect);
        canvas.drawRRect(cellRRect, cellPaint);

        final borderPaint = Paint()
          ..color = const Color(0xFF34344A).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawRRect(cellRRect, borderPaint);
      }
    }
  }

  void _drawGridDots(Canvas canvas) {
    final dotRadius = cellSize * 0.045;

    for (int row = 1; row < gridSize; row++) {
      for (int col = 1; col < gridSize; col++) {
        final x = col * cellSize;
        final y = row * cellSize;
        final center = Offset(x, y);

        final glowPaint = Paint()
          ..color = const Color(0xFF6B7AFF).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(center, dotRadius * 2.2, glowPaint);

        final dotPaint = Paint()
          ..color = const Color(0xFF5A6AAA).withValues(alpha: 0.85);
        canvas.drawCircle(center, dotRadius, dotPaint);
      }
    }
  }
}

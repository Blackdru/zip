import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/grid_cell.dart';

/// Renders checkpoint numbers on top of everything else
class CheckpointRenderer extends PositionComponent {
  final int gridSize;
  final double cellSize;
  final List<ClueNumber> clueNumbers;

  CheckpointRenderer({
    required this.gridSize,
    required this.cellSize,
    required this.clueNumbers,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(cellSize * gridSize, cellSize * gridSize);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawClueNumbers(canvas);
  }

  void _drawClueNumbers(Canvas canvas) {
    // Vibrant checkpoint colors matching the reference image
    final checkpointColors = [
      const Color(0xFFB843FF), // Purple for 1
      const Color(0xFF43C6FF), // Cyan for 2
      const Color(0xFFFFC043), // Yellow/Orange for 3
      const Color(0xFF7BFF43), // Green for 4
      const Color(0xFFFF5543), // Red for 5
    ];

    for (final clue in clueNumbers) {
      final centerX = (clue.x * cellSize) + (cellSize / 2);
      final centerY = (clue.y * cellSize) + (cellSize / 2);
      final center = Offset(centerX, centerY);
      final radius = cellSize * 0.28; // Reduced from 0.32 to 0.28

      // Get color for this checkpoint number
      final color = checkpointColors[(clue.num - 1) % checkpointColors.length];

      // NO GLOW - Clean solid badges only
      
      // Main badge circle with solid color - NO gradient, NO highlights
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, circlePaint);

      // Very subtle border for definition only
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, radius, borderPaint);

      // Draw white number text - completely flat, no effects
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${clue.num}',
          style: TextStyle(
            color: Colors.white,
            fontSize: cellSize * 0.30, // Reduced from 0.36 to 0.30
            fontWeight: FontWeight.w900,
            fontFamily: 'Poppins',
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          centerX - (textPainter.width / 2),
          centerY - (textPainter.height / 2),
        ),
      );
    }
  }
}

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
    for (final clue in clueNumbers) {
      final centerX = (clue.x * cellSize) + (cellSize / 2);
      final centerY = (clue.y * cellSize) + (cellSize / 2);
      final center = Offset(centerX, centerY);
      final radius = cellSize * 0.28; // Reduced from 0.35 to 0.28

      // Subtle outer glow ring (dark to make white circle pop)
      final outerGlowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, radius * 1.3, outerGlowPaint);

      // Main circle background - WHITE
      final circlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, circlePaint);

      // Subtle shadow border
      final borderShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(center, radius, borderShadowPaint);

      // Clean border
      final borderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, borderPaint);

      // Draw number - BLACK text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${clue.num}',
          style: TextStyle(
            color: Colors.black,
            fontSize: cellSize * 0.32, // Reduced from 0.4 to 0.32
            fontWeight: FontWeight.w900,
            fontFamily: 'Poppins',
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 1,
                offset: const Offset(0, 0.5),
              ),
            ],
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

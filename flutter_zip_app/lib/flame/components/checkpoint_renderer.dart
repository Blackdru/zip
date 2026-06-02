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

      // Draw circle background - BLACK
      final circlePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(centerX, centerY),
        cellSize * 0.35,
        circlePaint,
      );

      // Draw number - WHITE text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${clue.num}',
          style: TextStyle(
            color: Colors.white,
            fontSize: cellSize * 0.4,
            fontWeight: FontWeight.bold,
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

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/color_dot.dart';

/// Renders colored dots on the board
class DotRenderer extends PositionComponent {
  final int gridSize;
  final double cellSize;
  final List<ColorDot> colorDots;

  // Color mapping for dots
  final Map<String, Color> _colorMap = {
    'red': const Color(0xFFFF5543),
    'blue': const Color(0xFF43C6FF),
    'green': const Color(0xFF7BFF43),
    'yellow': const Color(0xFFFFC043),
    'orange': const Color(0xFFFF8A43),
    'purple': const Color(0xFFB843FF),
    'cyan': const Color(0xFF43FFFF),
    'pink': const Color(0xFFFF43B8),
  };

  DotRenderer({
    required this.gridSize,
    required this.cellSize,
    required this.colorDots,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(cellSize * gridSize, cellSize * gridSize);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawDots(canvas);
  }

  void _drawDots(Canvas canvas) {
    for (final dot in colorDots) {
      final centerX = (dot.x * cellSize) + (cellSize / 2);
      final centerY = (dot.y * cellSize) + (cellSize / 2);
      final center = Offset(centerX, centerY);
      final radius = cellSize * 0.32;

      final color = _colorMap[dot.color] ?? const Color(0xFFFFFFFF);

      // Subtle outer glow (reduced significantly)
      final outerGlowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, radius * 1.4, outerGlowPaint);

      // Main dot circle
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, circlePaint);

      // Inner highlight for 3D effect
      final highlightPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.4),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.7],
        ).createShader(
          Rect.fromCircle(
            center: Offset(centerX - radius * 0.2, centerY - radius * 0.2),
            radius: radius * 0.5,
          ),
        );
      canvas.drawCircle(center, radius, highlightPaint);

      // Subtle border for definition
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, radius, borderPaint);
    }
  }
}

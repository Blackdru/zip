import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/grid_cell.dart';

/// Renders the path with thick rounded lines and gradient colors
/// Matches the premium visual style from the reference design
class PathRenderer extends PositionComponent {
  final int gridSize;
  final double cellSize;

  List<GridCell> _path = [];
  Vector2? _currentDragPosition;

  // Thick path width (about 20% of cell size for prominent visibility)
  late double pathWidth;

  PathRenderer({
    required this.gridSize,
    required this.cellSize,
  }) {
    pathWidth = cellSize * 0.38; // Further increased path width for prominence
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(cellSize * gridSize, cellSize * gridSize);
  }

  void updatePath(List<GridCell> path, {Vector2? dragPosition}) {
    if (_path.length != path.length || 
        _currentDragPosition != dragPosition ||
        !_pathsEqual(_path, path)) {
      _path = List.from(path);
      _currentDragPosition = dragPosition;
    }
  }

  bool _pathsEqual(List<GridCell> a, List<GridCell> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].x != b[i].x || a[i].y != b[i].y) return false;
    }
    return true;
  }

  void clearPath() {
    _path = [];
    _currentDragPosition = null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_path.isEmpty) return;

    _drawPath(canvas);
  }

  void _drawPath(Canvas canvas) {
    if (_path.isEmpty) return;

    if (_path.length == 1 && _currentDragPosition == null) {
      _drawSinglePoint(canvas, _path.first);
      return;
    }

    // Convert grid cells to screen positions
    final points = _path.map((cell) => _getCellCenter(cell)).toList();
    
    // Add drag position if available (snapped to axis)
    if (_currentDragPosition != null && points.isNotEmpty) {
      final lastPoint = points.last;
      final clampedX = _currentDragPosition!.x.clamp(0.0, cellSize * gridSize);
      final clampedY = _currentDragPosition!.y.clamp(0.0, cellSize * gridSize);
      final dragOffset = Offset(clampedX, clampedY);
      
      final dx = (dragOffset.dx - lastPoint.dx).abs();
      final dy = (dragOffset.dy - lastPoint.dy).abs();
      
      if (dx > dy) {
        points.add(Offset(dragOffset.dx, lastPoint.dy));
      } else {
        points.add(Offset(lastPoint.dx, dragOffset.dy));
      }
    }

    if (points.length == 1) {
      _drawSinglePoint(canvas, _path.first);
      return;
    }

    // Draw path segments with gradient colors
    _drawSegmentedPath(canvas, points);
  }

  void _drawSegmentedPath(Canvas canvas, List<Offset> points) {
    // Gradient colors matching the reference (purple → cyan → yellow → green → orange/red)
    final gradientColors = [
      const Color(0xFFB843FF), // Bright purple/magenta
      const Color(0xFF43C6FF), // Bright cyan
      const Color(0xFFFFC043), // Yellow/orange
      const Color(0xFF7BFF43), // Bright green
      const Color(0xFFFF5543), // Orange/red
    ];

    // Draw glow effect behind the path
    for (int i = 0; i < points.length - 1; i++) {
      final t = i / math.max(1, points.length - 1);
      final glowColor = _getGradientColor(gradientColors, t);
      
      // Outer glow
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = pathWidth * 1.8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      
      canvas.drawLine(points[i], points[i + 1], glowPaint);
    }

    // Draw main path with gradient
    for (int i = 0; i < points.length - 1; i++) {
      final t = i / math.max(1, points.length - 1);
      final color = _getGradientColor(gradientColors, t);
      
      // Main path stroke
      final pathPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            _getGradientColor(gradientColors, i / math.max(1, points.length - 1)),
            _getGradientColor(gradientColors, (i + 1) / math.max(1, points.length - 1)),
          ],
        ).createShader(Rect.fromPoints(points[i], points[i + 1]))
        ..style = PaintingStyle.stroke
        ..strokeWidth = pathWidth
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(points[i], points[i + 1], pathPaint);
    }

    // Add subtle inner highlight for depth
    for (int i = 0; i < points.length - 1; i++) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = pathWidth * 0.4
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(points[i], points[i + 1], highlightPaint);
    }
  }

  Color _getGradientColor(List<Color> colors, double t) {
    if (t <= 0) return colors.first;
    if (t >= 1) return colors.last;
    
    final scaledT = t * (colors.length - 1);
    final index = scaledT.floor();
    final nextIndex = (index + 1).clamp(0, colors.length - 1);
    final localT = scaledT - index;
    
    return Color.lerp(colors[index], colors[nextIndex], localT)!;
  }

  void _drawSinglePoint(Canvas canvas, GridCell cell) {
    final center = _getCellCenter(cell);

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFB843FF).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, pathWidth * 0.9, glowPaint);

    // Main dot
    final paint = Paint()
      ..color = const Color(0xFFB843FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pathWidth * 0.55, paint);

    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pathWidth * 0.3, highlightPaint);
  }

  Offset _getCellCenter(GridCell cell) {
    return Offset(
      (cell.x * cellSize) + (cellSize / 2),
      (cell.y * cellSize) + (cellSize / 2),
    );
  }
}

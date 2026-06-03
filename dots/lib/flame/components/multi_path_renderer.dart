import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/color_dot.dart';

/// Renders multiple paths simultaneously, each with its own color
class MultiPathRenderer extends PositionComponent {
  final int gridSize;
  final double cellSize;
  final List<ColorDot> colorDots;

  Map<int, List<PathCell>> _activePaths = {};
  Vector2? _currentDragPosition;
  late double pathWidth;

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

  MultiPathRenderer({
    required this.gridSize,
    required this.cellSize,
    required this.colorDots,
  }) {
    pathWidth = cellSize * 0.28; // Reduced from 0.38 for cleaner paths
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(cellSize * gridSize, cellSize * gridSize);
  }

  void updatePaths(Map<int, List<PathCell>> paths, {Vector2? dragPosition}) {
    _activePaths = Map.from(paths);
    _currentDragPosition = dragPosition;
  }

  void clearPaths() {
    _activePaths.clear();
    _currentDragPosition = null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_activePaths.isEmpty) return;

    // Render each path with its color
    for (final entry in _activePaths.entries) {
      final pairId = entry.key;
      final path = entry.value;
      if (path.isEmpty) continue;

      // Get color for this pair
      final dot = colorDots.firstWhere((d) => d.pairId == pairId);
      final color = _colorMap[dot.color] ?? const Color(0xFFFFFFFF);

      _drawPath(canvas, path, color, pairId);
    }
  }

  void _drawPath(Canvas canvas, List<PathCell> path, Color color, int pairId) {
    if (path.isEmpty) return;

    if (path.length == 1 && _currentDragPosition == null) {
      _drawSinglePoint(canvas, path.first, color);
      return;
    }

    final points = path.map((cell) => _getCellCenter(cell)).toList();

    // Add drag position if this is the active path
    if (_currentDragPosition != null && _activePaths[pairId] == path) {
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
      _drawSinglePoint(canvas, path.first, color);
      return;
    }

    _drawSegmentedPath(canvas, points, color);
  }

  void _drawSegmentedPath(Canvas canvas, List<Offset> points, Color color) {
    // Draw subtle glow effect (reduced significantly)
    for (int i = 0; i < points.length - 1; i++) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = pathWidth * 1.3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawLine(points[i], points[i + 1], glowPaint);
    }

    // Draw main path
    for (int i = 0; i < points.length - 1; i++) {
      final pathPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = pathWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(points[i], points[i + 1], pathPaint);
    }

    // Add subtle inner highlight
    for (int i = 0; i < points.length - 1; i++) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = pathWidth * 0.3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(points[i], points[i + 1], highlightPaint);
    }
  }

  void _drawSinglePoint(Canvas canvas, PathCell cell, Color color) {
    final center = _getCellCenter(cell);

    // Subtle glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, pathWidth * 0.7, glowPaint);

    // Main dot
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pathWidth * 0.5, paint);

    // Subtle inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pathWidth * 0.2, highlightPaint);
  }

  Offset _getCellCenter(PathCell cell) {
    return Offset(
      (cell.x * cellSize) + (cellSize / 2),
      (cell.y * cellSize) + (cellSize / 2),
    );
  }
}

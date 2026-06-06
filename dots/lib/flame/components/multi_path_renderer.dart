import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/color_dot.dart';
import '../../core/theme/dot_colors.dart';

/// Renders multiple paths simultaneously, each with its own color
class MultiPathRenderer extends PositionComponent {
  final int gridSize;
  final double cellSize;
  final List<ColorDot> colorDots;

  Map<int, List<PathCell>> _activePaths = {};
  Vector2? _currentDragPosition;
  // Track which pair is actively being drawn so the preview is only shown
  // for that pair, not for every path in the map.
  int? _currentActivePairId;
  late double pathWidth;

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

  void updatePaths(
    Map<int, List<PathCell>> paths, {
    Vector2? dragPosition,
    // currentPairId identifies which pair owns the ongoing drag gesture.
    // Only that pair should show the preview extension toward the finger.
    int? currentPairId,
  }) {
    // FIX #3: Deep-copy both the map and each inner list so the renderer
    // holds an independent snapshot. The gesture controller mutates its lists
    // in-place (e.g. backtracking removes the last element), which could
    // cause the renderer to see inconsistent state mid-frame with a shallow copy.
    _activePaths = paths.map((k, v) => MapEntry(k, List<PathCell>.from(v)));
    _currentDragPosition = dragPosition;
    _currentActivePairId = currentPairId;
  }

  void clearPaths() {
    _activePaths.clear();
    _currentDragPosition = null;
    _currentActivePairId = null;
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

      // FIX #7: Use shared DotColors instead of a local duplicate map.
      final dot = colorDots.firstWhere((d) => d.pairId == pairId);
      final color = DotColors.resolve(dot.color);

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

    // FIX #6: Only extend the path toward the drag position when:
    //   1. There IS an active drag position
    //   2. This pair IS the one currently being drawn
    // When a path completes, _finishPath() sets _currentDragPosition to null
    // and _currentActivePairId to null BEFORE calling updatePaths, so the
    // preview tail is never rendered for completed/idle paths.
    if (_currentDragPosition != null && pairId == _currentActivePairId) {
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

import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/grid_cell.dart';

/// Renders the path drawn by the user with premium visual effects
/// Uses smooth Catmull-Rom splines for elegant curves
/// Path is centered and takes 35-50% of cell width
class PathRenderer extends PositionComponent {
  final int gridSize;
  final double cellSize;

  List<GridCell> _path = [];
  Vector2? _currentDragPosition;

  // Path width is 40% of cell size for centered routing
  late double pathWidth;
  
  // Animation for glow effect
  double _glowPhase = 0.0;

  // Random VIBGYOR color for each puzzle
  late Color pathColor;

  PathRenderer({
    required this.gridSize,
    required this.cellSize,
  }) {
    pathWidth = cellSize * 0.4;
    // Generate random VIBGYOR color
    pathColor = _getRandomVIBGYORColor();
  }

  /// Get random color from VIBGYOR spectrum
  Color _getRandomVIBGYORColor() {
    final random = math.Random();
    final vibgyorColors = [
      const Color(0xFF9400D3), // Violet
      const Color(0xFF4B0082), // Indigo
      const Color(0xFF0000FF), // Blue
      const Color(0xFF00FF00), // Green
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFFFF7F00), // Orange
      const Color(0xFFFF0000), // Red
    ];
    return vibgyorColors[random.nextInt(vibgyorColors.length)];
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(cellSize * gridSize, cellSize * gridSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Animate glow effect
    _glowPhase = (_glowPhase + dt * 2) % (2 * math.pi);
  }

  void updatePath(List<GridCell> path, {Vector2? dragPosition}) {
    // Only update if path or drag position actually changed
    if (_path.length != path.length || 
        _currentDragPosition != dragPosition ||
        !_pathsEqual(_path, path)) {
      _path = List.from(path); // Create a copy to avoid reference issues
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

    _drawGlowEffect(canvas);
    _drawPath(canvas);
  }

  void _drawPath(Canvas canvas) {
    if (_path.isEmpty) return;

    if (_path.length == 1 && _currentDragPosition == null) {
      // Draw single point
      _drawSinglePoint(canvas, _path.first);
      return;
    }

    // Main path with brighter, more saturated color
    final paint = Paint()
      ..color = pathColor // Random VIBGYOR color
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _createSmoothPath();
    canvas.drawPath(path, paint);
    
    // Add subtle white highlight on top for extra pop
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathWidth * 0.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    canvas.drawPath(path, highlightPaint);
  }

  void _drawGlowEffect(Canvas canvas) {
    if (_path.isEmpty) return;
    if (_path.length == 1 && _currentDragPosition == null) return;

    // Animated glow intensity (subtle)
    final glowIntensity = 0.15 + (math.sin(_glowPhase) * 0.08);

    final path = _createSmoothPath();

    // Outer glow - reduced blur and opacity
    final outerGlowPaint = Paint()
      ..color = pathColor.withValues(alpha: glowIntensity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathWidth * 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(path, outerGlowPaint);

    // Inner glow - tighter and more subtle
    final innerGlowPaint = Paint()
      ..color = pathColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = pathWidth * 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, innerGlowPaint);
  }

  /// Creates straight orthogonal path (horizontal/vertical lines only)
  Path _createSmoothPath() {
    final path = Path();
    
    if (_path.isEmpty) return path;

    // Convert grid cells to screen positions
    final points = _path.map((cell) => _getCellCenter(cell)).toList();
    
    // Add drag position if available (snapped to last cell's axis and clamped to bounds)
    if (_currentDragPosition != null && points.isNotEmpty) {
      final lastPoint = points.last;
      
      // Clamp drag position to grid bounds
      final clampedX = _currentDragPosition!.x.clamp(0.0, cellSize * gridSize);
      final clampedY = _currentDragPosition!.y.clamp(0.0, cellSize * gridSize);
      final dragOffset = Offset(clampedX, clampedY);
      
      // Snap drag position to horizontal or vertical axis
      final dx = (dragOffset.dx - lastPoint.dx).abs();
      final dy = (dragOffset.dy - lastPoint.dy).abs();
      
      if (dx > dy) {
        // Horizontal movement
        points.add(Offset(dragOffset.dx, lastPoint.dy));
      } else {
        // Vertical movement
        points.add(Offset(lastPoint.dx, dragOffset.dy));
      }
    }

    if (points.length == 1) {
      path.addOval(Rect.fromCircle(center: points[0], radius: pathWidth / 2));
      return path;
    }

    // Draw straight lines between points
    path.moveTo(points[0].dx, points[0].dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    return path;
  }

  void _drawSinglePoint(Canvas canvas, GridCell cell) {
    final center = _getCellCenter(cell);

    // Reduced outer glow
    final outerGlowPaint = Paint()
      ..color = pathColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, pathWidth * 0.9, outerGlowPaint);

    // Main point - random VIBGYOR color
    final paint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pathWidth / 2, paint);

    // Small white highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pathWidth / 4, highlightPaint);
  }

  Offset _getCellCenter(GridCell cell) {
    return Offset(
      (cell.x * cellSize) + (cellSize / 2),
      (cell.y * cellSize) + (cellSize / 2),
    );
  }
}

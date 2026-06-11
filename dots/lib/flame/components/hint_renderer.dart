import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/color_dot.dart';
import '../../core/theme/dot_colors.dart';

/// Renders animated, directional hints on the board.
///
/// Instead of just highlighting cells, this renderer shows a clear
/// "draw from HERE, go THIS direction" sequence:
///
/// 1. A "START HERE" pulsing ring on the dot the user should begin from
/// 2. Animated directional arrows (→ ↓ ← ↑) showing the exact path to draw
/// 3. Numbered step markers so order is unambiguous
/// 4. A label banner (e.g. "Pair 5") so the user knows which pair to work on
///
/// The hint auto-fades after [_hintDurationSeconds] seconds.
class HintRenderer extends PositionComponent {
  final int gridSize;
  final double cellSize;
  final List<ColorDot> colorDots;

  /// The starting cell (dot position the user should draw FROM).
  PathCell? _startCell;

  /// Cells the user should draw THROUGH, in order.
  List<PathCell> _hintCells = [];

  /// The pairId of the hinted pair.
  int? _hintPairId;

  /// The pair's label number for the banner display.
  int? _hintPairLabel;

  /// The color name string for the hinted pair.
  String? _hintColorName;

  /// Whether a hint is currently being shown.
  bool _isShowingHint = false;

  /// Elapsed time since the hint was triggered.
  double _hintElapsed = 0.0;

  /// Total duration the hint stays visible.
  static const double _hintDurationSeconds = 4.5;

  /// Duration of the fade-in phase.
  static const double _fadeInDuration = 0.35;

  /// Duration of the fade-out phase.
  static const double _fadeOutDuration = 1.0;

  /// Pulse animation speed (radians per second).
  static const double _pulseSpeed = 3.5;

  /// Arrow animation speed — arrows appear sequentially.
  static const double _arrowStaggerDelay = 0.25;

  HintRenderer({
    required this.gridSize,
    required this.cellSize,
    required this.colorDots,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(cellSize * gridSize, cellSize * gridSize);
  }

  /// Show a directional hint.
  ///
  /// [pairId]: which pair this hint is for.
  /// [startCell]: the dot cell the user should start drawing FROM.
  /// [pathCells]: the next cells to draw THROUGH (in order).
  /// [pairLabel]: the display number for this pair (e.g. 5).
  void showHint(int pairId, PathCell startCell, List<PathCell> pathCells, int pairLabel) {
    if (pathCells.isEmpty) return;

    _hintPairId = pairId;
    _startCell = startCell;
    _hintCells = List.from(pathCells);
    _hintPairLabel = pairLabel;
    _hintElapsed = 0.0;
    _isShowingHint = true;

    // Resolve color name from the colorDots list.
    final dot = colorDots.where((d) => d.pairId == pairId).firstOrNull;
    _hintColorName = dot?.color;
  }

  /// Immediately clear any visible hint.
  void clearHint() {
    _isShowingHint = false;
    _hintCells = [];
    _startCell = null;
    _hintPairId = null;
    _hintPairLabel = null;
    _hintColorName = null;
    _hintElapsed = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isShowingHint) return;
    _hintElapsed += dt;
    if (_hintElapsed >= _hintDurationSeconds) {
      clearHint();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_isShowingHint || _hintCells.isEmpty || _hintColorName == null) return;

    final baseColor = DotColors.resolve(_hintColorName!);
    final overallOpacity = _computeOverallOpacity();

    // 1. Draw "START HERE" indicator on the starting cell.
    if (_startCell != null) {
      _drawStartIndicator(canvas, _startCell!, baseColor, overallOpacity);
    }

    // 2. Draw directional arrows and numbered step markers.
    // Build the full chain: startCell → hintCells[0] → hintCells[1] → ...
    final fullChain = <PathCell>[];
    if (_startCell != null) fullChain.add(_startCell!);
    fullChain.addAll(_hintCells);

    for (int i = 0; i < fullChain.length - 1; i++) {
      // Stagger: each arrow appears after a delay.
      final arrowAppearTime = _fadeInDuration + (i * _arrowStaggerDelay);
      if (_hintElapsed < arrowAppearTime) continue;

      final arrowOpacity =
          ((_hintElapsed - arrowAppearTime) / 0.2).clamp(0.0, 1.0) *
              overallOpacity;

      _drawDirectionalArrow(
        canvas,
        fullChain[i],
        fullChain[i + 1],
        baseColor,
        arrowOpacity,
      );
    }

    // 3. Draw numbered step markers on each hint cell.
    for (int i = 0; i < _hintCells.length; i++) {
      final stepAppearTime =
          _fadeInDuration + ((i + (_startCell != null ? 1 : 0)) * _arrowStaggerDelay);
      if (_hintElapsed < stepAppearTime) continue;

      final stepOpacity =
          ((_hintElapsed - stepAppearTime) / 0.2).clamp(0.0, 1.0) *
              overallOpacity;

      _drawStepMarker(canvas, _hintCells[i], i + 1, baseColor, stepOpacity);
    }

    // 4. Draw label banner ("Pair X") near the start.
    if (_hintPairLabel != null && _startCell != null) {
      _drawPairLabel(canvas, _startCell!, baseColor, overallOpacity);
    }
  }

  double _computeOverallOpacity() {
    if (_hintElapsed < _fadeInDuration) {
      return (_hintElapsed / _fadeInDuration).clamp(0.0, 1.0);
    } else if (_hintElapsed > _hintDurationSeconds - _fadeOutDuration) {
      return ((_hintDurationSeconds - _hintElapsed) / _fadeOutDuration)
          .clamp(0.0, 1.0);
    }
    return 1.0;
  }

  /// Draw a prominent pulsing ring on the start cell with "START" text.
  void _drawStartIndicator(
      Canvas canvas, PathCell cell, Color color, double opacity) {
    final center = _cellCenter(cell);
    final pulse = 0.85 + 0.15 * sin(_hintElapsed * _pulseSpeed);
    final radius = cellSize * 0.42 * pulse;

    // Outer pulsing glow.
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3 * opacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, radius * 1.5, glowPaint);

    // Pulsing ring.
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.8 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, ringPaint);

    // Second inner ring for emphasis.
    final innerRingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.75, innerRingPaint);
  }

  /// Draw a directional arrow from one cell to the next.
  void _drawDirectionalArrow(Canvas canvas, PathCell from, PathCell to,
      Color color, double opacity) {
    final fromCenter = _cellCenter(from);
    final toCenter = _cellCenter(to);

    // Shorten the line slightly so it doesn't overlap the markers.
    final dx = toCenter.dx - fromCenter.dx;
    final dy = toCenter.dy - fromCenter.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final ux = dx / dist;
    final uy = dy / dist;
    final shortenFrom = cellSize * 0.25;
    final shortenTo = cellSize * 0.25;

    final lineStart = Offset(
      fromCenter.dx + ux * shortenFrom,
      fromCenter.dy + uy * shortenFrom,
    );
    final lineEnd = Offset(
      toCenter.dx - ux * shortenTo,
      toCenter.dy - uy * shortenTo,
    );

    // Animated dash offset for a "flowing" effect.
    final dashPhase = (_hintElapsed * 40.0) % 20.0;

    // Draw the arrow shaft with animated dashes.
    final shaftPaint = Paint()
      ..color = color.withValues(alpha: 0.7 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    _drawAnimatedDashedLine(canvas, lineStart, lineEnd, shaftPaint, dashPhase);

    // Arrowhead at the end.
    final arrowSize = cellSize * 0.12;
    final arrowPaint = Paint()
      ..color = color.withValues(alpha: 0.9 * opacity)
      ..style = PaintingStyle.fill;

    final arrowTip = lineEnd;
    final arrowLeft = Offset(
      arrowTip.dx - ux * arrowSize - uy * arrowSize * 0.6,
      arrowTip.dy - uy * arrowSize + ux * arrowSize * 0.6,
    );
    final arrowRight = Offset(
      arrowTip.dx - ux * arrowSize + uy * arrowSize * 0.6,
      arrowTip.dy - uy * arrowSize - ux * arrowSize * 0.6,
    );

    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowLeft.dx, arrowLeft.dy)
      ..lineTo(arrowRight.dx, arrowRight.dy)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  /// Draw a numbered step marker on a cell.
  void _drawStepMarker(Canvas canvas, PathCell cell, int stepNumber,
      Color color, double opacity) {
    final center = _cellCenter(cell);
    final radius = cellSize * 0.2;

    // Background circle.
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.25 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Border.
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.7 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    // Number text.
    final textSpan = TextSpan(
      text: '$stepNumber',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.95 * opacity),
        fontSize: cellSize * 0.22,
        fontWeight: FontWeight.w800,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  /// Draw a label banner near the start cell (e.g. "Pair 5").
  void _drawPairLabel(
      Canvas canvas, PathCell cell, Color color, double opacity) {
    final center = _cellCenter(cell);
    // Position the label above the start cell.
    final labelY = center.dy - cellSize * 0.6;
    final labelCenter = Offset(center.dx, labelY);

    // Background pill.
    final labelWidth = cellSize * 1.1;
    final labelHeight = cellSize * 0.35;
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: labelCenter, width: labelWidth, height: labelHeight),
      const Radius.circular(8),
    );

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.85 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(labelRect, bgPaint);

    // "Draw here" text.
    final textSpan = TextSpan(
      text: 'Draw here',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.95 * opacity),
        fontSize: cellSize * 0.18,
        fontWeight: FontWeight.w700,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(labelCenter.dx - tp.width / 2, labelCenter.dy - tp.height / 2),
    );
  }

  /// Draw a dashed line with an animated offset for a "flowing" effect.
  void _drawAnimatedDashedLine(
      Canvas canvas, Offset start, Offset end, Paint paint, double phase) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    const dashLength = 8.0;
    const gapLength = 5.0;
    final unitX = dx / distance;
    final unitY = dy / distance;

    // Start drawing with a phase offset for animation.
    double drawn = -(phase % (dashLength + gapLength));
    bool drawing = true;

    while (drawn < distance) {
      final segLength = drawing ? dashLength : gapLength;
      final segStart = drawn.clamp(0.0, distance);
      final segEnd = (drawn + segLength).clamp(0.0, distance);

      if (drawing && segEnd > segStart) {
        canvas.drawLine(
          Offset(start.dx + unitX * segStart, start.dy + unitY * segStart),
          Offset(start.dx + unitX * segEnd, start.dy + unitY * segEnd),
          paint,
        );
      }

      drawn += segLength;
      drawing = !drawing;
    }
  }

  Offset _cellCenter(PathCell cell) {
    return Offset(
      (cell.x * cellSize) + (cellSize / 2),
      (cell.y * cellSize) + (cellSize / 2),
    );
  }
}

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../models/grid_cell.dart';
import 'components/puzzle_board.dart';
import 'components/path_renderer.dart';
import 'components/checkpoint_renderer.dart';
import 'components/gesture_controller.dart';

/// Main Flame game class for the puzzle
class PuzzleGame extends FlameGame {
  final PuzzleData puzzleData;
  final Function(List<Move> moves, int solveTimeMs) onPuzzleComplete;
  final Function(GameState state) onStateChanged;
  final VoidCallback? onPathStuck; // called when player is deadlocked

  late PuzzleBoard _board;
  late PathRenderer _pathRenderer;
  late CheckpointRenderer _checkpointRenderer;
  late GestureController _gestureController;
  PositionComponent? _hintOverlay;

  GameState _gameState = const GameState(
    totalCheckpoints: 0,
  );

  final List<Move> _moveHistory = [];
  int _startTimeMs = 0;
  bool _isCompleted = false; // guard against double-firing onPuzzleComplete

  PuzzleGame({
    required this.puzzleData,
    required this.onPuzzleComplete,
    required this.onStateChanged,
    this.onPathStuck,
  });

  @override
  Color backgroundColor() => const Color(0xFF0F0A1E); // Dark theme background

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _gameState = GameState(
      totalCheckpoints: puzzleData.totalCheckpoints,
    );

    _board = PuzzleBoard(
      gridSize: puzzleData.gridSize,
      clueNumbers: puzzleData.clueNumbers,
      obstacles: puzzleData.obstacles,
      walls: puzzleData.walls,
    );
    await add(_board);

    // Wait for board to calculate its position and size
    await Future.delayed(const Duration(milliseconds: 100));

    // Path renderer — renders BELOW checkpoints
    _pathRenderer = PathRenderer(
      gridSize: puzzleData.gridSize,
      cellSize: _board.cellSize,
    );
    _pathRenderer.position = _board.position;
    await add(_pathRenderer);

    // Checkpoint renderer — renders ABOVE path
    _checkpointRenderer = CheckpointRenderer(
      gridSize: puzzleData.gridSize,
      cellSize: _board.cellSize,
      clueNumbers: puzzleData.clueNumbers,
    );
    _checkpointRenderer.position = _board.position;
    await add(_checkpointRenderer);

    _gestureController = GestureController(
      gridSize: puzzleData.gridSize,
      cellSize: _board.cellSize,
      boardPosition: _board.position,
      clueNumbers: puzzleData.clueNumbers,
      obstacles: puzzleData.obstacles,
      walls: puzzleData.walls,
      onPathUpdate: _handlePathUpdate,
      onPathComplete: _handlePathComplete,
      onPathStuck: _handlePathStuck,
    );
    _gestureController.position = _board.position;
    _gestureController.size = Vector2(
      _board.cellSize * puzzleData.gridSize,
      _board.cellSize * puzzleData.gridSize,
    );
    await add(_gestureController);
  }

  // ── Hint ──────────────────────────────────────────────────────────────────

  /// Show a directional hint: from the user's current cell, draw arrows
  /// through [hintCells] showing the next steps of the correct path.
  void showDirectionalHint(GridCell fromCell, List<GridCell> hintCells,
      {int durationMs = 4000}) {
    clearHint();
    _hintOverlay = _DirectionalHintOverlay(
      fromCell: fromCell,
      hintCells: hintCells,
      cellSize: _board.cellSize,
      boardPosition: _board.position,
    );
    add(_hintOverlay!);
    Future.delayed(Duration(milliseconds: durationMs), clearHint);
  }

  /// Show a divergence hint: highlight the wrong cells the user must undo.
  void showHintDiverged(int stepsToUndo, {int durationMs = 4000}) {
    clearHint();
    // We highlight the last N cells of the current path as "wrong".
    final currentPath = _gameState.currentPath;
    if (currentPath.isEmpty || stepsToUndo <= 0) return;

    final wrongCells = currentPath
        .sublist((currentPath.length - stepsToUndo).clamp(0, currentPath.length))
        .toList();

    _hintOverlay = _DivergedHintOverlay(
      wrongCells: wrongCells,
      cellSize: _board.cellSize,
      boardPosition: _board.position,
    );
    add(_hintOverlay!);
    Future.delayed(Duration(milliseconds: durationMs), clearHint);
  }

  /// Keep old showHint for backwards compatibility.
  void showHint(GridCell cell, {int durationMs = 3000}) {
    showDirectionalHint(cell, [cell], durationMs: durationMs);
  }

  /// Remove any active hint overlay immediately.
  void clearHint() {
    if (_hintOverlay != null) {
      _hintOverlay!.removeFromParent();
      _hintOverlay = null;
    }
  }

  // ── Game lifecycle ────────────────────────────────────────────────────────

  /// Start the puzzle timer.
  void startPuzzle() {
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _gameState = _gameState.copyWith(phase: GamePhase.playing);
    onStateChanged(_gameState);
  }

  void _handlePathUpdate(
    List<GridCell> path,
    int checkpoints,
    Vector2? dragPosition,
  ) {
    _gameState = _gameState.copyWith(
      currentPath: path,
      solvedCheckpoints: checkpoints,
    );
    _pathRenderer.updatePath(path, dragPosition: dragPosition);
    onStateChanged(_gameState);

    // Only record move when a new cell is appended
    if (path.isNotEmpty) {
      final lastCell = path.last;
      if (_moveHistory.isEmpty ||
          _moveHistory.last.x != lastCell.x ||
          _moveHistory.last.y != lastCell.y) {
        _moveHistory.add(Move(
          x: lastCell.x,
          y: lastCell.y,
          timestampMs: DateTime.now().millisecondsSinceEpoch - _startTimeMs,
        ),);
      }
    }
  }

  void _handlePathComplete(bool isValid) {
    if (_isCompleted) return; // guard against double-firing
    if (isValid) _isCompleted = true;

    final solveTimeMs =
        DateTime.now().millisecondsSinceEpoch - _startTimeMs;
    _gameState = _gameState.copyWith(
      phase: isValid ? GamePhase.completed : GamePhase.invalid,
    );
    onStateChanged(_gameState);
    if (isValid) {
      onPuzzleComplete(_moveHistory, solveTimeMs);
    }
  }

  void _handlePathStuck() {
    // Forward directly to the UI — no game state change needed
    // (avoids requiring freezed regeneration for an isStuck field)
    onPathStuck?.call();
  }

  /// Reset the puzzle to its initial state.
  void reset() {
    clearHint();
    _moveHistory.clear();
    _startTimeMs = 0;
    _isCompleted = false;
    _gameState = GameState(totalCheckpoints: puzzleData.totalCheckpoints);
    _pathRenderer.clearPath();
    _gestureController.reset();
    onStateChanged(_gameState);
  }

  GameState get gameState => _gameState;
}

// ─── Directional Hint Overlay ─────────────────────────────────────────────────
// Shows numbered step markers with animated arrows from the current cell
// through the next hint cells, so the user knows exactly where to draw.

class _DirectionalHintOverlay extends PositionComponent {
  final GridCell fromCell;
  final List<GridCell> hintCells;
  final double cellSize;
  final Vector2 boardPosition;

  double _elapsed = 0;
  static const double _arrowStaggerDelay = 0.2;

  _DirectionalHintOverlay({
    required this.fromCell,
    required this.hintCells,
    required this.cellSize,
    required this.boardPosition,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = boardPosition;
    size = Vector2(cellSize * 20, cellSize * 20); // large enough
    priority = 100;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    const hintColor = Color(0xFF4ADE80); // Green — "go here"
    final fullChain = <GridCell>[fromCell, ...hintCells];

    // 1. Draw "start here" pulsing ring on fromCell.
    final pulse = 0.85 + 0.15 * (_elapsed * 3.5).remainder(6.28).abs();
    final startCenter = _cellCenter(fromCell);
    final startRadius = cellSize * 0.4 * pulse;

    canvas.drawCircle(
      startCenter,
      startRadius * 1.4,
      Paint()
        ..color = hintColor.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      startCenter,
      startRadius,
      Paint()
        ..color = hintColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 2. Draw arrows from each cell to the next.
    for (int i = 0; i < fullChain.length - 1; i++) {
      final appearTime = i * _arrowStaggerDelay;
      if (_elapsed < appearTime) continue;

      final opacity = ((_elapsed - appearTime) / 0.2).clamp(0.0, 1.0);
      _drawArrow(canvas, fullChain[i], fullChain[i + 1], hintColor, opacity);
    }

    // 3. Draw numbered step markers on hint cells.
    for (int i = 0; i < hintCells.length; i++) {
      final appearTime = (i + 1) * _arrowStaggerDelay;
      if (_elapsed < appearTime) continue;

      final opacity = ((_elapsed - appearTime) / 0.2).clamp(0.0, 1.0);
      _drawStepMarker(canvas, hintCells[i], i + 1, hintColor, opacity);
    }

    // 4. "Go here" label above the first hint cell.
    if (hintCells.isNotEmpty && _elapsed > _arrowStaggerDelay) {
      final labelOpacity =
          ((_elapsed - _arrowStaggerDelay) / 0.3).clamp(0.0, 1.0);
      _drawLabel(canvas, hintCells[0], 'Go here →', hintColor, labelOpacity);
    }
  }

  void _drawArrow(Canvas canvas, GridCell from, GridCell to, Color color,
      double opacity) {
    final fromCenter = _cellCenter(from);
    final toCenter = _cellCenter(to);

    final dx = toCenter.dx - fromCenter.dx;
    final dy = toCenter.dy - fromCenter.dy;
    final dist = (dx * dx + dy * dy);
    if (dist == 0) return;
    final d = dist > 0 ? dist.toDouble() : 1.0;
    final sqrtD = d > 0 ? _sqrt(d) : 1.0;
    final ux = dx / sqrtD;
    final uy = dy / sqrtD;

    final shortenFrom = cellSize * 0.3;
    final shortenTo = cellSize * 0.3;

    final lineStart = Offset(
      fromCenter.dx + ux * shortenFrom,
      fromCenter.dy + uy * shortenFrom,
    );
    final lineEnd = Offset(
      toCenter.dx - ux * shortenTo,
      toCenter.dy - uy * shortenTo,
    );

    // Animated dashes.
    final dashPhase = (_elapsed * 40.0) % 18.0;
    _drawDashedLine(canvas, lineStart, lineEnd,
        color.withValues(alpha: 0.7 * opacity), dashPhase);

    // Arrowhead.
    final arrowSize = cellSize * 0.13;
    final tip = lineEnd;
    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
          tip.dx - ux * arrowSize - uy * arrowSize * 0.6,
          tip.dy - uy * arrowSize + ux * arrowSize * 0.6)
      ..lineTo(
          tip.dx - ux * arrowSize + uy * arrowSize * 0.6,
          tip.dy - uy * arrowSize - ux * arrowSize * 0.6)
      ..close();
    canvas.drawPath(
        arrowPath, Paint()..color = color.withValues(alpha: 0.9 * opacity));
  }

  void _drawStepMarker(Canvas canvas, GridCell cell, int step, Color color,
      double opacity) {
    final center = _cellCenter(cell);
    final radius = cellSize * 0.22;

    // Background.
    canvas.drawCircle(
        center, radius, Paint()..color = color.withValues(alpha: 0.3 * opacity));
    // Border.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.8 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    // Number.
    final tp = TextPainter(
      text: TextSpan(
        text: '$step',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95 * opacity),
          fontSize: cellSize * 0.24,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawLabel(Canvas canvas, GridCell cell, String text, Color color,
      double opacity) {
    final center = _cellCenter(cell);
    final labelY = center.dy - cellSize * 0.65;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95 * opacity),
          fontSize: cellSize * 0.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Background pill.
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, labelY),
        width: tp.width + 16,
        height: tp.height + 8,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
        pillRect, Paint()..color = color.withValues(alpha: 0.85 * opacity));
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, labelY - tp.height / 2));
  }

  void _drawDashedLine(
      Canvas canvas, Offset start, Offset end, Color color, double phase) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = _sqrt(dx * dx + dy * dy);
    if (distance < 1) return;

    const dashLen = 7.0;
    const gapLen = 4.0;
    final ux = dx / distance;
    final uy = dy / distance;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    double drawn = -(phase % (dashLen + gapLen));
    bool drawing = true;
    while (drawn < distance) {
      final segLen = drawing ? dashLen : gapLen;
      final segStart = drawn.clamp(0.0, distance);
      final segEnd = (drawn + segLen).clamp(0.0, distance);
      if (drawing && segEnd > segStart) {
        canvas.drawLine(
          Offset(start.dx + ux * segStart, start.dy + uy * segStart),
          Offset(start.dx + ux * segEnd, start.dy + uy * segEnd),
          paint,
        );
      }
      drawn += segLen;
      drawing = !drawing;
    }
  }

  Offset _cellCenter(GridCell cell) {
    return Offset(
      cell.x * cellSize + cellSize / 2,
      cell.y * cellSize + cellSize / 2,
    );
  }

  double _sqrt(double v) {
    if (v <= 0) return 0;
    // Newton's method — good enough for a render call.
    double x = v;
    for (int i = 0; i < 10; i++) {
      x = (x + v / x) / 2;
    }
    return x;
  }
}

// ─── Diverged Hint Overlay ────────────────────────────────────────────────────
// Highlights the wrong cells the user must undo, with a red "X" and a
// pulsing effect to clearly communicate "go back".

class _DivergedHintOverlay extends PositionComponent {
  final List<GridCell> wrongCells;
  final double cellSize;
  final Vector2 boardPosition;

  double _elapsed = 0;

  _DivergedHintOverlay({
    required this.wrongCells,
    required this.cellSize,
    required this.boardPosition,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = boardPosition;
    size = Vector2(cellSize * 20, cellSize * 20);
    priority = 100;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    const wrongColor = Color(0xFFEF4444); // Red
    final pulse = 0.6 + 0.4 * ((_elapsed * 3.0).remainder(6.28)).abs().clamp(0.0, 1.0);

    for (int i = 0; i < wrongCells.length; i++) {
      final cell = wrongCells[i];
      final center = Offset(
        cell.x * cellSize + cellSize / 2,
        cell.y * cellSize + cellSize / 2,
      );
      final rect = Rect.fromCenter(
          center: center, width: cellSize * 0.85, height: cellSize * 0.85);

      // Red overlay.
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = wrongColor.withValues(alpha: 0.3 * pulse),
      );
      // Red border.
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..color = wrongColor.withValues(alpha: 0.7 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // "✕" cross.
      final crossSize = cellSize * 0.15;
      final crossPaint = Paint()
        ..color = wrongColor.withValues(alpha: 0.9 * pulse)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx - crossSize, center.dy - crossSize),
        Offset(center.dx + crossSize, center.dy + crossSize),
        crossPaint,
      );
      canvas.drawLine(
        Offset(center.dx + crossSize, center.dy - crossSize),
        Offset(center.dx - crossSize, center.dy + crossSize),
        crossPaint,
      );
    }

    // "Go back" label above the first wrong cell.
    if (wrongCells.isNotEmpty) {
      final firstCenter = Offset(
        wrongCells.first.x * cellSize + cellSize / 2,
        wrongCells.first.y * cellSize + cellSize / 2,
      );
      final labelY = firstCenter.dy - cellSize * 0.65;

      final tp = TextPainter(
        text: TextSpan(
          text: '← Go back',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: cellSize * 0.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(firstCenter.dx, labelY),
          width: tp.width + 16,
          height: tp.height + 8,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(
          pillRect, Paint()..color = wrongColor.withValues(alpha: 0.85));
      tp.paint(canvas,
          Offset(firstCenter.dx - tp.width / 2, labelY - tp.height / 2));
    }
  }
}


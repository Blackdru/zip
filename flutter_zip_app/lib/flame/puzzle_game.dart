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
  _HintOverlayComponent? _hintOverlay;

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

  /// Show a pulsing hint highlight on [cell] for [durationMs] milliseconds.
  /// Rendered entirely inside Flame using the board's own coordinate system.
  void showHint(GridCell cell, {int durationMs = 3000}) {
    clearHint();
    _hintOverlay = _HintOverlayComponent(
      cell: cell,
      cellSize: _board.cellSize,
      boardPosition: _board.position,
    );
    add(_hintOverlay!);
    Future.delayed(Duration(milliseconds: durationMs), clearHint);
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

// ─── Hint Overlay Component ───────────────────────────────────────────────────
// A native Flame PositionComponent — uses board-local coordinates directly,
// so the highlight always falls on the exact correct cell.

class _HintOverlayComponent extends PositionComponent {
  final GridCell cell;
  final double cellSize;
  final Vector2 boardPosition;

  double _pulseT = 0;
  bool _increasing = true;

  _HintOverlayComponent({
    required this.cell,
    required this.cellSize,
    required this.boardPosition,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(
      boardPosition.x + cell.x * cellSize,
      boardPosition.y + cell.y * cellSize,
    );
    size = Vector2(cellSize, cellSize);
    priority = 100; // render above checkpoints
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Pulse between opacity 0.25 and 0.65
    const speed = 2.0;
    if (_increasing) {
      _pulseT += dt * speed;
      if (_pulseT >= 1.0) {
        _pulseT = 1.0;
        _increasing = false;
      }
    } else {
      _pulseT -= dt * speed;
      if (_pulseT <= 0.0) {
        _pulseT = 0.0;
        _increasing = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final alpha = (0.25 + _pulseT * 0.40).clamp(0.0, 1.0);
    final rect = Rect.fromLTWH(0, 0, cellSize, cellSize);

    // Filled overlay with warm orange (hint color)
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = const Color(0xFFFF8C42).withValues(alpha: alpha), // Warm orange
    );
    // Solid border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFFFF8C42) // Warm orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }
}

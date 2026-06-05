import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/connect_dots_puzzle.dart';
import '../models/color_dot.dart';
import 'components/dots_board.dart';
import 'components/multi_path_renderer.dart';
import 'components/dot_renderer.dart';
import 'components/dots_gesture_controller.dart';

/// Main Flame game class for Connect Dots puzzle
class ConnectDotsGame extends FlameGame {
  final ConnectDotsPuzzle puzzleData;
  final Function(List<PlayerPath> paths, int solveTimeMs) onPuzzleComplete;
  final Function(GameState state) onStateChanged;
  final VoidCallback? onPathConflict;

  late DotsBoard _board;
  late MultiPathRenderer _pathRenderer;
  late DotRenderer _dotRenderer;
  late DotsGestureController _gestureController;

  GameState _gameState = const GameState(totalPairs: 0);

  int _startTimeMs = 0;
  bool _isCompleted = false;

  ConnectDotsGame({
    required this.puzzleData,
    required this.onPuzzleComplete,
    required this.onStateChanged,
    this.onPathConflict,
  });

  @override
  Color backgroundColor() => const Color(0xFF0F0A1E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _gameState = GameState(
      totalPairs: puzzleData.totalPairs,
    );

    // Board renderer
    _board = DotsBoard(
      gridSize: puzzleData.gridSize,
      colorDots: puzzleData.colorDots,
    );
    await add(_board);

    await Future.delayed(const Duration(milliseconds: 100));

    // Multi-path renderer (below dots)
    _pathRenderer = MultiPathRenderer(
      gridSize: puzzleData.gridSize,
      cellSize: _board.cellSize,
      colorDots: puzzleData.colorDots,
    );
    _pathRenderer.position = _board.position;
    await add(_pathRenderer);

    // Dot renderer (on top)
    _dotRenderer = DotRenderer(
      gridSize: puzzleData.gridSize,
      cellSize: _board.cellSize,
      colorDots: puzzleData.colorDots,
    );
    _dotRenderer.position = _board.position;
    await add(_dotRenderer);

    // Gesture controller
    _gestureController = DotsGestureController(
      gridSize: puzzleData.gridSize,
      cellSize: _board.cellSize,
      boardPosition: _board.position,
      colorDots: puzzleData.colorDots,
      onPathUpdate: _handlePathUpdate,
      onPuzzleComplete: _handlePuzzleComplete,
      onPathConflict: _handlePathConflict,
    );
    _gestureController.position = _board.position;
    _gestureController.size = Vector2(
      _board.cellSize * puzzleData.gridSize,
      _board.cellSize * puzzleData.gridSize,
    );
    await add(_gestureController);
  }

  void startPuzzle() {
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _gameState = _gameState.copyWith(phase: GamePhase.playing);
    onStateChanged(_gameState);
  }

  void _handlePathUpdate(
    Map<int, List<PathCell>> activePaths,
    int? currentPairId,
    Vector2? dragPosition,
  ) {
    final completedCount = activePaths.values
        .where((path) => _isPathComplete(path))
        .length;

    _gameState = _gameState.copyWith(
      activePaths: activePaths,
      currentPairId: currentPairId,
      completedPairs: completedCount,
    );

    _pathRenderer.updatePaths(
      activePaths,
      dragPosition: dragPosition,
      // FIX: tell the renderer which pair is being drawn so only that pair
      // gets the live drag-preview extension toward the finger.
      currentPairId: currentPairId,
    );
    onStateChanged(_gameState);
  }

  bool _isPathComplete(List<PathCell> path) {
    if (path.length < 2) return false;

    // FIX #5: Find the pairId that owns the first cell of this path, then check
    // whether the last cell matches the other dot of that pair. This is O(n)
    // instead of the previous O(n²) double-loop and is consistent with the
    // gesture controller’s own _isPathComplete(path, pairId).
    final firstCell = path.first;
    final lastCell = path.last;

    // Identify which dot the path starts at.
    ColorDot? startDot;
    for (final dot in puzzleData.colorDots) {
      if (dot.x == firstCell.x && dot.y == firstCell.y) {
        startDot = dot;
        break;
      }
    }
    if (startDot == null) return false;

    // Find the other dot of the same pair and check if the path ends there.
    for (final dot in puzzleData.colorDots) {
      if (dot.pairId == startDot.pairId &&
          (dot.x != startDot.x || dot.y != startDot.y)) {
        return lastCell.x == dot.x && lastCell.y == dot.y;
      }
    }

    return false;
  }

  void _handlePuzzleComplete(List<PlayerPath> playerPaths) {
    if (_isCompleted) return;
    _isCompleted = true;

    final solveTimeMs = DateTime.now().millisecondsSinceEpoch - _startTimeMs;
    
    _gameState = _gameState.copyWith(
      phase: GamePhase.completed,
    );
    onStateChanged(_gameState);
    
    onPuzzleComplete(playerPaths, solveTimeMs);
  }

  void _handlePathConflict() {
    onPathConflict?.call();
  }

  void reset() {
    _gestureController.reset();
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _isCompleted = false;
    _gameState = GameState(
      totalPairs: puzzleData.totalPairs,
      phase: GamePhase.playing,
    );
    onStateChanged(_gameState);
  }

  void showHint(int pairId, PathCell nextCell) {
    // TODO: Implement hint visualization
    // Show pulsing circle on the next cell for this path
  }

  GameState get gameState => _gameState;
}

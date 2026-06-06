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
  // FIX #4: Track whether onLoad has finished so startPuzzle() can set the
  // correct start time AFTER all components are ready.
  bool _isLoaded = false;

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

    // FIX #4: Mark as loaded and start the timer now that all components
    // are initialized. If startPuzzle() was called before onLoad completed,
    // the deferred start will happen here.
    _isLoaded = true;
    if (_gameState.phase == GamePhase.playing) {
      // startPuzzle() was called early — set the real start time now.
      _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    }
  }

  /// FIX #4: Start the puzzle. If onLoad hasn't finished yet, mark the phase
  /// as playing so onLoad's tail will set the start time once ready.
  void startPuzzle() {
    _gameState = _gameState.copyWith(phase: GamePhase.playing);
    onStateChanged(_gameState);

    if (_isLoaded) {
      _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    }
    // else: onLoad will set _startTimeMs when it finishes.
  }

  void _handlePathUpdate(
    Map<int, List<PathCell>> activePaths,
    int? currentPairId,
    Vector2? dragPosition,
  ) {
    // FIX #11: Use the gesture controller's authoritative _isPathComplete
    // implicitly — count completed pairs by checking if both dots of each pair
    // are connected. This is consistent with the gesture controller and avoids
    // having a second, potentially-divergent implementation.
    int completedCount = 0;
    for (final entry in activePaths.entries) {
      final path = entry.value;
      if (path.length < 2) continue;
      final pairId = entry.key;
      final pairDots = puzzleData.colorDots.where((d) => d.pairId == pairId).toList();
      if (pairDots.length != 2) continue;

      final first = path.first;
      final last = path.last;
      final connects = (first.x == pairDots[0].x && first.y == pairDots[0].y &&
              last.x == pairDots[1].x && last.y == pairDots[1].y) ||
          (first.x == pairDots[1].x && first.y == pairDots[1].y &&
              last.x == pairDots[0].x && last.y == pairDots[0].y);
      if (connects) completedCount++;
    }

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

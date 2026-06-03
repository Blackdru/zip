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

    _pathRenderer.updatePaths(activePaths, dragPosition: dragPosition);
    onStateChanged(_gameState);
  }

  bool _isPathComplete(List<PathCell> path) {
    if (path.length < 2) return false;
    
    // Find the dots for this path
    final firstCell = path.first;
    final lastCell = path.last;
    
    // Check if path connects two dots of the same color
    for (int i = 0; i < puzzleData.colorDots.length; i++) {
      final dot1 = puzzleData.colorDots[i];
      for (int j = i + 1; j < puzzleData.colorDots.length; j++) {
        final dot2 = puzzleData.colorDots[j];
        
        if (dot1.pairId == dot2.pairId) {
          final startsAt1 = firstCell.x == dot1.x && firstCell.y == dot1.y;
          final endsAt2 = lastCell.x == dot2.x && lastCell.y == dot2.y;
          final startsAt2 = firstCell.x == dot2.x && firstCell.y == dot2.y;
          final endsAt1 = lastCell.x == dot1.x && lastCell.y == dot1.y;
          
          if ((startsAt1 && endsAt2) || (startsAt2 && endsAt1)) {
            return true;
          }
        }
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

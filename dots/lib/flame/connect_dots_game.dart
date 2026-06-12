import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/connect_dots_puzzle.dart';
import '../models/color_dot.dart';
import 'components/dots_board.dart';
import 'components/multi_path_renderer.dart';
import 'components/dot_renderer.dart';
import 'components/dots_gesture_controller.dart';
import 'components/hint_renderer.dart';

/// Main Flame game class for Connect Dots puzzle
class ConnectDotsGame extends FlameGame {
  final ConnectDotsPuzzle puzzleData;
  final Function(List<PlayerPath> paths, int solveTimeMs) onPuzzleComplete;
  final Function(GameState state) onStateChanged;
  final VoidCallback? onPathConflict;
  final VoidCallback? onGameReady;

  late DotsBoard _board;
  late MultiPathRenderer _pathRenderer;
  late DotRenderer _dotRenderer;
  late DotsGestureController _gestureController;
  late HintRenderer _hintRenderer;

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
    this.onGameReady,
  });

  @override
  Color backgroundColor() => const Color(0xFF0F0A1E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _gameState = GameState(
      totalPairs: puzzleData.totalPairs,
      phase: _gameState.phase,
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

    // Hint renderer (on very top)
    _hintRenderer = HintRenderer(
      gridSize: puzzleData.gridSize,
      cellSize: _board.cellSize,
      colorDots: puzzleData.colorDots,
    );
    _hintRenderer.position = _board.position;
    await add(_hintRenderer);

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

    // FIX #4: Mark as loaded and start the timer NOW that all components
    // are initialized. Always set start time here to ensure widget timer
    // and game timer are synchronized.
    _isLoaded = true;
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _gameState = _gameState.copyWith(phase: GamePhase.playing);
    onStateChanged(_gameState);
    // Notify the widget that game is ready and timer should start
    onGameReady?.call();
  }

  /// Start the puzzle timer - this is now called automatically in onLoad()
  /// but kept for manual reset functionality.
  void startPuzzle() {
    if (_isLoaded) {
      _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    }
    _gameState = _gameState.copyWith(phase: GamePhase.playing);
    onStateChanged(_gameState);
  }

  void _handlePathUpdate(
    Map<int, List<PathCell>> activePaths,
    int? currentPairId,
    Vector2? dragPosition,
  ) {
    if (currentPairId != null) {
      _hintRenderer.clearHint();
    }
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
    _hintRenderer.clearHint();
    _startTimeMs = DateTime.now().millisecondsSinceEpoch;
    _isCompleted = false;
    _gameState = GameState(
      totalPairs: puzzleData.totalPairs,
      phase: GamePhase.playing,
    );
    onStateChanged(_gameState);
  }

  void showPathHint(SolutionPath solutionPath, int pairLabel, {bool forceComplete = false}) {
    if (solutionPath.path.isEmpty) return;

    final solPath = solutionPath.path;
    int startIndex = 0;

    // For dead-end hints, show the complete path from the beginning
    // so the player can see the entire correct route
    if (!forceComplete) {
      // If the player already has a path for this pair, skip the matching
      // prefix so the hint starts at the divergence point (where they went
      // wrong) instead of redundantly showing cells they already have correct.
      final playerPath = _gameState.activePaths[solutionPath.pairId];
      if (playerPath != null && playerPath.length >= 2) {
        // Try forward match (player drew in same direction as solution)
        int forwardMatch = 0;
        for (int i = 0; i < playerPath.length && i < solPath.length; i++) {
          if (playerPath[i].x == solPath[i].x &&
              playerPath[i].y == solPath[i].y) {
            forwardMatch++;
          } else {
            break;
          }
        }

        // Try reverse match (player drew from the other dot)
        int reverseMatch = 0;
        for (int i = 0; i < playerPath.length && i < solPath.length; i++) {
          final si = solPath.length - 1 - i;
          if (playerPath[i].x == solPath[si].x &&
              playerPath[i].y == solPath[si].y) {
            reverseMatch++;
          } else {
            break;
          }
        }

        if (forwardMatch >= reverseMatch && forwardMatch > 1) {
          // Show from last matching cell so user sees where to change direction
          startIndex = (forwardMatch - 1).clamp(0, solPath.length - 2);
        } else if (reverseMatch > forwardMatch && reverseMatch > 1) {
          // Player drew in reverse — divergence is near the start of solution.
          // Show from the divergence point in solution's forward direction.
          final divergeInSol = (solPath.length - reverseMatch).clamp(0, solPath.length - 2);
          // Back up one cell so the user sees the "turn" context
          startIndex = (divergeInSol > 0 ? divergeInSol - 1 : 0);
        }
      }
    }

    final startCell = solPath[startIndex];
    // Show the complete remaining path from the divergence point.
    final hintCells = solPath.sublist(startIndex + 1);
    _hintRenderer.showHint(
      solutionPath.pairId,
      startCell,
      hintCells,
      pairLabel,
    );
  }

  void clearPath(int pairId) {
    _gestureController.clearPath(pairId);
  }


  GameState get gameState => _gameState;
}

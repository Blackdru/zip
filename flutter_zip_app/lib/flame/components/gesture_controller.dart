import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import '../../models/grid_cell.dart';
import '../../models/wall.dart';

/// Handles gesture input and path validation
/// Uses DragCallbacks for smooth continuous drawing with real-time finger following
class GestureController extends PositionComponent with HasGameRef, DragCallbacks {
  final int gridSize;
  final double cellSize;
  final Vector2 boardPosition;
  final List<ClueNumber> clueNumbers;
  final List<GridCell> obstacles;
  final List<Wall> walls;
  final Function(List<GridCell> path, int checkpoints, Vector2? dragPosition) onPathUpdate;
  final Function(bool isValid) onPathComplete;
  final VoidCallback? onPathStuck; // fired when player has no valid moves and puzzle is not done

  final List<GridCell> _currentPath = [];
  final Set<String> _visitedCells = {};
  int _currentCheckpoint = 0;
  bool _isDrawing = false;
  Vector2? _currentDragPosition;

  GestureController({
    required this.gridSize,
    required this.cellSize,
    required this.boardPosition,
    required this.clueNumbers,
    required this.obstacles,
    required this.walls,
    required this.onPathUpdate,
    required this.onPathComplete,
    this.onPathStuck,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    
    final cell = _screenToGrid(event.localPosition);
    if (cell == null) return;

    // If there's an existing path, ONLY allow continuing from the last cell
    if (_currentPath.isNotEmpty) {
      final lastCell = _currentPath.last;
      
      // Check if starting from the last cell
      if (_isSameCell(cell, lastCell)) {
        // Continue from same cell
        _isDrawing = true;
        _currentDragPosition = event.localPosition;
        onPathUpdate(_currentPath, _currentCheckpoint, _currentDragPosition);
        return;
      } else if (_isValidMove(cell)) {
        // Continue from adjacent cell
        _isDrawing = true;
        _currentPath.add(cell);
        _visitedCells.add(_cellKey(cell));
        _updateCheckpoint(cell);
        _currentDragPosition = event.localPosition;
        onPathUpdate(_currentPath, _currentCheckpoint, _currentDragPosition);
        return;
      } else {
        // Invalid move - do not start drawing
        return;
      }
    }

    // Start new path ONLY if starting at checkpoint 1
    if (_isValidStartCell(cell)) {
      _isDrawing = true;
      _currentPath.clear();
      _visitedCells.clear();
      _currentCheckpoint = 0;
      _currentPath.add(cell);
      _visitedCells.add(_cellKey(cell));
      _updateCheckpoint(cell);
      _currentDragPosition = event.localPosition;
      onPathUpdate(_currentPath, _currentCheckpoint, _currentDragPosition);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    
    if (!_isDrawing) return;

    final cell = _screenToGrid(event.localEndPosition);
    
    // Only update drag position if within bounds
    if (cell != null) {
      _currentDragPosition = event.localEndPosition;
    } else {
      // Outside bounds - don't update drag position
      _currentDragPosition = null;
    }
    
    if (cell == null) {
      // Outside grid - just update with current path
      onPathUpdate(_currentPath, _currentCheckpoint, _currentDragPosition);
      return;
    }

    // Only add cell if it's different from the last cell
    if (_currentPath.isNotEmpty && _isSameCell(_currentPath.last, cell)) {
      // Same cell, just update drag position
      onPathUpdate(_currentPath, _currentCheckpoint, _currentDragPosition);
      return;
    }

    // Check if moving backwards (to second-to-last cell)
    // Allow backtracking one step at a time in both tournament and practice modes
    if (_currentPath.length >= 2 && _isSameCell(_currentPath[_currentPath.length - 2], cell)) {
      // Moving backwards - remove last cell (undo)
      final removedCell = _currentPath.removeLast();
      _visitedCells.remove(_cellKey(removedCell));
      
      // Update checkpoint if we're moving back from a checkpoint
      _recalculateCheckpoint();
      
      onPathUpdate(_currentPath, _currentCheckpoint, _currentDragPosition);
      return;
    }

    // Validate and add new cell (forward movement only)
    if (_isValidMove(cell)) {
      _currentPath.add(cell);
      _visitedCells.add(_cellKey(cell));
      _updateCheckpoint(cell);
      onPathUpdate(_currentPath, _currentCheckpoint, _currentDragPosition);
    } else {
      // Invalid move - just update drag position for visual feedback
      onPathUpdate(_currentPath, _currentCheckpoint, _currentDragPosition);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _currentDragPosition = null;
    _finishPath();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _currentDragPosition = null;
    _cancelPath();
  }

  void _finishPath() {
    if (!_isDrawing) return;

    _isDrawing = false;

    if (_validateCompletePath()) {
      onPathComplete(true);
    } else {
      // Path incomplete — keep it visible so the user can continue
      onPathUpdate(_currentPath, _currentCheckpoint, null);
      // Detect deadlock: no valid forward moves remain
      _checkIfStuck();
    }
  }

  void _cancelPath() {
    _isDrawing = false;
    _currentPath.clear();
    _visitedCells.clear();
    _currentCheckpoint = 0;
    onPathUpdate(_currentPath, _currentCheckpoint, null);
  }

  void reset() {
    _currentPath.clear();
    _visitedCells.clear();
    _currentCheckpoint = 0;
    _isDrawing = false;
    _currentDragPosition = null;
  }

  /// Returns true if there is at least one valid move from the current path head.
  bool _hasValidMoves() {
    if (_currentPath.isEmpty) return false;
    final last = _currentPath.last;
    const deltas = [[-1, 0], [1, 0], [0, -1], [0, 1]];
    for (final d in deltas) {
      final candidate = GridCell(x: last.x + d[0], y: last.y + d[1]);
      if (_isValidMove(candidate)) return true;
    }
    return false;
  }

  /// Fires onPathStuck when the player has no valid moves and the puzzle is incomplete.
  void _checkIfStuck() {
    if (_currentPath.isEmpty) return;
    if (_validateCompletePath()) return; // already won
    if (!_hasValidMoves()) {
      onPathStuck?.call();
    }
  }

  String _cellKey(GridCell cell) => '${cell.x},${cell.y}';

  GridCell? _screenToGrid(Vector2 screenPos) {
    // screenPos is already relative to this component's position
    final x = (screenPos.x / cellSize).floor();
    final y = (screenPos.y / cellSize).floor();

    if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
      return GridCell(x: x, y: y);
    }
    return null;
  }

  bool _isSameCell(GridCell a, GridCell b) {
    return a.x == b.x && a.y == b.y;
  }

  bool _isValidStartCell(GridCell cell) {
    // Must start at checkpoint 1
    final firstClue = clueNumbers.firstWhere(
      (c) => c.num == 1,
      orElse: () => const ClueNumber(x: -1, y: -1, num: -1),
    );

    return _isSameCell(cell, GridCell(x: firstClue.x, y: firstClue.y));
  }

  bool _isValidMove(GridCell cell) {
    if (_currentPath.isEmpty) return false;

    // RULE 4: The last checkpoint must be the last cell visited.
    // Once the last checkpoint is reached, no further moves are allowed.
    // The path must END at checkpoint N.
    if (_currentCheckpoint == clueNumbers.length) return false;

    final lastCell = _currentPath.last;

    // Check if adjacent (horizontal or vertical only)
    final dx = (cell.x - lastCell.x).abs();
    final dy = (cell.y - lastCell.y).abs();

    if (!((dx == 1 && dy == 0) || (dx == 0 && dy == 1))) {
      return false;
    }

    // Check if cell is an obstacle
    if (obstacles.any((o) => _isSameCell(o, cell))) {
      return false;
    }

    // Check if cell already visited (no overlaps)
    if (_visitedCells.contains(_cellKey(cell))) {
      return false;
    }

    // RULE 2: If this cell has a checkpoint number,
    // it must be the NEXT checkpoint in sequence.
    final cellCheckpoint = clueNumbers.firstWhere(
      (c) => _isSameCell(GridCell(x: c.x, y: c.y), cell),
      orElse: () => const ClueNumber(x: -1, y: -1, num: -1),
    );

    if (cellCheckpoint.num != -1) {
      final expectedNext = _currentCheckpoint + 1;
      if (cellCheckpoint.num != expectedNext) {
        // Out-of-sequence checkpoint — REJECT
        return false;
      }
    }

    return true;
  }

  void _updateCheckpoint(GridCell cell) {
    // Check if this cell is the next checkpoint
    final nextCheckpoint = _currentCheckpoint + 1;
    final clue = clueNumbers.firstWhere(
      (c) => c.num == nextCheckpoint,
      orElse: () => const ClueNumber(x: -1, y: -1, num: -1),
    );

    if (clue.num != -1 && _isSameCell(cell, GridCell(x: clue.x, y: clue.y))) {
      _currentCheckpoint = nextCheckpoint;
      // NOTE: Do NOT trigger completion here.
      // Completion is only validated when the user lifts their finger (_finishPath).
      // The path must cover ALL cells, not just reach the last checkpoint.
    }
  }

  void _recalculateCheckpoint() {
    // Recalculate checkpoint based on current path
    _currentCheckpoint = 0;
    for (final cell in _currentPath) {
      final nextCheckpoint = _currentCheckpoint + 1;
      final clue = clueNumbers.firstWhere(
        (c) => c.num == nextCheckpoint,
        orElse: () => const ClueNumber(x: -1, y: -1, num: -1),
      );

      if (clue.num != -1 && _isSameCell(cell, GridCell(x: clue.x, y: clue.y))) {
        _currentCheckpoint = nextCheckpoint;
      }
    }
  }

  bool _validateCompletePath() {
    // RULE 2: All checkpoints must be visited in order (1 through N).
    if (_currentCheckpoint != clueNumbers.length) return false;

    // RULE 3: The path must cover EVERY non-obstacle cell on the grid.
    final totalTraversable = (gridSize * gridSize) - obstacles.length;
    if (_currentPath.length != totalTraversable) return false;

    // RULE 4: The very last cell in the path must be checkpoint N.
    // (Implicitly guaranteed by _isValidMove blocking moves after checkpoint N,
    // but we verify explicitly for safety.)
    final lastCp = clueNumbers.firstWhere(
      (c) => c.num == clueNumbers.length,
      orElse: () => const ClueNumber(x: -1, y: -1, num: -1),
    );
    if (lastCp.num == -1) return false;
    return _isSameCell(_currentPath.last, GridCell(x: lastCp.x, y: lastCp.y));
  }
}

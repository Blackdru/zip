import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';
import '../../models/color_dot.dart';

/// Handles gesture input and multi-path validation for Connect Dots
class DotsGestureController extends PositionComponent
    with HasGameReference, DragCallbacks {
  final int gridSize;
  final double cellSize;
  final Vector2 boardPosition;
  final List<ColorDot> colorDots;
  final Function(
    Map<int, List<PathCell>> paths,
    int? currentPairId,
    Vector2? dragPosition,
  ) onPathUpdate;
  final Function(List<PlayerPath> playerPaths) onPuzzleComplete;
  final VoidCallback? onPathConflict;

  // State for all paths
  final Map<int, List<PathCell>> _allPaths = {};
  final Map<int, Set<String>> _visitedCellsPerPath = {};
  
  int? _currentPairId;
  bool _isDrawing = false;
  Vector2? _currentDragPosition;

  DotsGestureController({
    required this.gridSize,
    required this.cellSize,
    required this.boardPosition,
    required this.colorDots,
    required this.onPathUpdate,
    required this.onPuzzleComplete,
    this.onPathConflict,
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

    // IMPORTANT: Check if starting from a dot (not just any cell)
    final dot = _getDotAtCell(cell);
    if (dot == null) {
      // Not starting from a dot, ignore this gesture
      return;
    }

    final pairId = dot.pairId;

    // Check if path already exists for this pair
    if (_allPaths.containsKey(pairId) && _allPaths[pairId]!.isNotEmpty) {
      final existingPath = _allPaths[pairId]!;
      final firstCell = existingPath.first;
      final lastCell = existingPath.last;

      // Check if this path is complete
      final isComplete = _isPathComplete(existingPath, pairId);

      // Only allow continuing from the exact dot endpoints
      if (_isSameCell(cell, firstCell)) {
        if (isComplete) {
          // Complete path - clear it completely to restart
          _clearPath(pairId);
        } else {
          // Incomplete path - reverse and continue
          _allPaths[pairId] = existingPath.reversed.toList();
          _visitedCellsPerPath[pairId] = Set.from(existingPath.map(_cellKey));
        }
        _currentPairId = pairId;
        _isDrawing = true;
        _allPaths[pairId] = [PathCell(x: cell.x, y: cell.y)];
        _visitedCellsPerPath[pairId] = {_cellKey(cell)};
        _currentDragPosition = event.localPosition;
        onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
        return;
      } else if (_isSameCell(cell, lastCell)) {
        if (isComplete) {
          // Complete path - clear it completely to restart
          _clearPath(pairId);
          _currentPairId = pairId;
          _isDrawing = true;
          _allPaths[pairId] = [PathCell(x: cell.x, y: cell.y)];
          _visitedCellsPerPath[pairId] = {_cellKey(cell)};
        } else {
          // Incomplete path - continue from end
          _currentPairId = pairId;
          _isDrawing = true;
        }
        _currentDragPosition = event.localPosition;
        onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
        return;
      } else {
        // Clicked on a dot but not an endpoint - clear path and start fresh
        _clearPath(pairId);
      }
    }

    // Start new path (only if we clicked on a dot)
    _currentPairId = pairId;
    _isDrawing = true;
    _allPaths[pairId] = [PathCell(x: cell.x, y: cell.y)];
    _visitedCellsPerPath[pairId] = {_cellKey(cell)};
    _currentDragPosition = event.localPosition;
    onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    if (!_isDrawing || _currentPairId == null) return;

    final cell = _screenToGrid(event.localEndPosition);

    if (cell != null) {
      _currentDragPosition = event.localEndPosition;
    } else {
      _currentDragPosition = null;
    }

    if (cell == null) {
      onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
      return;
    }

    final currentPath = _allPaths[_currentPairId]!;

    // Check if same cell as last
    if (currentPath.isNotEmpty && _isSameCell(currentPath.last, cell)) {
      onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
      return;
    }

    // Check if path is already complete (both dots connected)
    if (_isPathComplete(currentPath, _currentPairId!)) {
      // Path is complete, stop drawing
      _finishPath();
      return;
    }

    // Check for backtracking - search through the entire path
    for (int i = currentPath.length - 2; i >= 0; i--) {
      if (_isSameCell(currentPath[i], cell)) {
        // Found the cell in the path - backtrack to it
        while (currentPath.length > i + 1) {
          final removed = currentPath.removeLast();
          _visitedCellsPerPath[_currentPairId]!.remove(_cellKey(removed));
        }
        onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
        return;
      }
    }

    // Not backtracking, try to add new cell
    if (_isValidMove(cell, _currentPairId!)) {
      currentPath.add(PathCell(x: cell.x, y: cell.y));
      _visitedCellsPerPath[_currentPairId]!.add(_cellKey(cell));
      
      // Check if path just became complete
      if (_isPathComplete(currentPath, _currentPairId!)) {
        // Path is now complete, finish immediately
        _currentDragPosition = null;
        _finishPath();
        return;
      }
      
      onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
    } else {
      // Invalid move - show conflict if trying to cross another path
      final cellKey = _cellKey(cell);
      for (final entry in _allPaths.entries) {
        if (entry.key != _currentPairId && 
            _visitedCellsPerPath[entry.key]!.contains(cellKey)) {
          onPathConflict?.call();
          break;
        }
      }
      // Keep drag position for visual feedback
      onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
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
    _isDrawing = false;
    _currentPairId = null;
    onPathUpdate(_allPaths, null, null);
  }

  void _finishPath() {
    if (!_isDrawing || _currentPairId == null) return;

    _isDrawing = false;
    _currentPairId = null;

    // Check if puzzle is complete
    if (_validateCompletePuzzle()) {
      final playerPaths = _allPaths.entries
          .map((entry) => PlayerPath(pairId: entry.key, path: entry.value))
          .toList();
      onPuzzleComplete(playerPaths);
    } else {
      onPathUpdate(_allPaths, null, null);
    }
  }

  void _clearPath(int pairId) {
    _allPaths.remove(pairId);
    _visitedCellsPerPath.remove(pairId);
  }

  bool _isPathComplete(List<PathCell> path, int pairId) {
    if (path.length < 2) return false;

    final pairDots = colorDots.where((d) => d.pairId == pairId).toList();
    if (pairDots.length != 2) return false;

    final firstCell = path.first;
    final lastCell = path.last;

    // Check if path connects both dots of this pair
    final connectsDots = (_isSameCell(firstCell, pairDots[0]) &&
            _isSameCell(lastCell, pairDots[1])) ||
        (_isSameCell(firstCell, pairDots[1]) &&
            _isSameCell(lastCell, pairDots[0]));

    return connectsDots;
  }

  bool _isValidMove(PathCell cell, int pairId) {
    final currentPath = _allPaths[pairId]!;
    if (currentPath.isEmpty) return false;

    final lastCell = currentPath.last;

    // Check adjacency
    final dx = (cell.x - lastCell.x).abs();
    final dy = (cell.y - lastCell.y).abs();
    if (!((dx == 1 && dy == 0) || (dx == 0 && dy == 1))) {
      return false;
    }

    // Check if cell already visited by THIS path
    if (_visitedCellsPerPath[pairId]!.contains(_cellKey(cell))) {
      return false;
    }

    // Check if cell is occupied by another path
    for (final entry in _allPaths.entries) {
      if (entry.key == pairId) continue;
      if (_visitedCellsPerPath[entry.key]!.contains(_cellKey(cell))) {
        return false; // Cell occupied by another path
      }
    }

    // Check if cell is a dot
    final dotAtCell = _getDotAtCell(cell);
    if (dotAtCell != null) {
      // Can only move to dot of the same pair
      return dotAtCell.pairId == pairId;
    }

    return true;
  }

  bool _validateCompletePuzzle() {
    // Check all pairs are connected
    final pairIds = <int>{};
    for (final dot in colorDots) {
      pairIds.add(dot.pairId);
    }

    if (_allPaths.length != pairIds.length) return false;

    // Check each path connects its two dots
    for (final pairId in pairIds) {
      if (!_allPaths.containsKey(pairId)) return false;
      
      final path = _allPaths[pairId]!;
      if (path.length < 2) return false;

      final pairDots = colorDots.where((d) => d.pairId == pairId).toList();
      if (pairDots.length != 2) return false;

      final firstCell = path.first;
      final lastCell = path.last;

      final connectsDots = (_isSameCell(firstCell, pairDots[0]) &&
              _isSameCell(lastCell, pairDots[1])) ||
          (_isSameCell(firstCell, pairDots[1]) &&
              _isSameCell(lastCell, pairDots[0]));

      if (!connectsDots) return false;
    }

    // Check all cells are filled
    final totalCells = gridSize * gridSize;
    final filledCells = <String>{};
    for (final path in _allPaths.values) {
      for (final cell in path) {
        filledCells.add(_cellKey(cell));
      }
    }

    return filledCells.length == totalCells;
  }

  ColorDot? _getDotAtCell(PathCell cell) {
    for (final dot in colorDots) {
      if (dot.x == cell.x && dot.y == cell.y) {
        return dot;
      }
    }
    return null;
  }

  bool _isSameCell(PathCell a, dynamic b) {
    if (b is PathCell) {
      return a.x == b.x && a.y == b.y;
    } else if (b is ColorDot) {
      return a.x == b.x && a.y == b.y;
    }
    return false;
  }

  String _cellKey(PathCell cell) => '${cell.x},${cell.y}';

  PathCell? _screenToGrid(Vector2 screenPos) {
    final x = (screenPos.x / cellSize).floor();
    final y = (screenPos.y / cellSize).floor();

    if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
      return PathCell(x: x, y: y);
    }
    return null;
  }

  void reset() {
    _allPaths.clear();
    _visitedCellsPerPath.clear();
    _currentPairId = null;
    _isDrawing = false;
    _currentDragPosition = null;
    onPathUpdate(_allPaths, null, null);
  }

  Map<int, List<PathCell>> get allPaths => Map.unmodifiable(_allPaths);
}

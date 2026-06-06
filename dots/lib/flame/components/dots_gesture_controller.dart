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
  final Set<int> _completedPairIds = {}; // Track which pairs are complete
  
  int? _currentPairId;
  bool _isDrawing = false;
  Vector2? _currentDragPosition;

  // FIX #10: Flag to block all gestures after puzzle completion.
  bool _puzzleCompleted = false;

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

    // FIX #10: Block all gestures after puzzle is completed.
    if (_puzzleCompleted) return;

    final cell = _screenToGrid(event.localPosition);
    if (cell == null) return;

    // IMPORTANT: Must start from a dot (not any cell)
    final dot = _getDotAtCell(cell);
    if (dot == null) {
      // Not starting from a dot - ignore completely
      return;
    }

    final pairId = dot.pairId;

    // CRITICAL: If we're switching to a different pair, end the previous drawing session
    if (_isDrawing && _currentPairId != null && _currentPairId != pairId) {
      // Finish the previous path first
      final previousPath = _allPaths[_currentPairId];
      if (previousPath != null && _isPathComplete(previousPath, _currentPairId!)) {
        _completedPairIds.add(_currentPairId!);
      }
      
      _isDrawing = false;
      _currentPairId = null;
      _currentDragPosition = null;
      
      // Update UI to reflect the finished previous path
      onPathUpdate(_allPaths, null, null);
    }

    // Check if this pair has a path
    if (_allPaths.containsKey(pairId) && _allPaths[pairId]!.isNotEmpty) {
      final existingPath = _allPaths[pairId]!;
      final firstCell = existingPath.first;
      final lastCell = existingPath.last;

      // Check if path is complete (locked)
      final isComplete = _completedPairIds.contains(pairId);

      if (isComplete) {
        // COMPLETE PATH - LOCKED
        // Only allow clicking on endpoint dots to restart
        final clickedOnEndpoint = _isSameCell(cell, firstCell) || _isSameCell(cell, lastCell);
        
        if (clickedOnEndpoint) {
          // Clear the complete path to restart
          _clearPath(pairId);
          _currentPairId = pairId;
          _isDrawing = true;
          _allPaths[pairId] = [PathCell(x: cell.x, y: cell.y)];
          _visitedCellsPerPath[pairId] = {_cellKey(cell)};
          _currentDragPosition = event.localPosition;
          onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
        }
        // If clicked elsewhere on a complete path, ignore
        return;
      } else {
        // INCOMPLETE PATH - ALWAYS ALLOW INTERACTION FROM ENDPOINTS
        if (_isSameCell(cell, firstCell)) {
          // Clicked on first endpoint - reverse and continue from other end
          _allPaths[pairId] = existingPath.reversed.toList();
          _visitedCellsPerPath[pairId] = Set.from(existingPath.map(_cellKey));
          _currentPairId = pairId;
          _isDrawing = true;
          _currentDragPosition = event.localPosition;
          onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
          return;
        } else if (_isSameCell(cell, lastCell)) {
          // Clicked on last endpoint - continue from current end
          _currentPairId = pairId;
          _isDrawing = true;
          _currentDragPosition = event.localPosition;
          onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
          return;
        } else {
          // The user tapped a dot of this pair that is NOT at either current
          // endpoint (firstCell or lastCell).
          //
          // We know `cell` IS a valid dot of this pair because _getDotAtCell
          // returned non-null with dot.pairId == pairId. And the two checks
          // above already confirmed it is neither firstCell nor lastCell.
          // Since each pair has exactly 2 dots and firstCell is always at one
          // of them, `cell` MUST be the partner dot.
          //
          // FROZEN-DOT BUG FIX: the previous code did:
          //   matchingDot = find the dot of this pair that ≠ dot (clicked dot)
          //   if (_isSameCell(cell, matchingDot)) { restart }
          //
          // `matchingDot` was the OTHER dot (e.g. dotA when user clicked dotB),
          // so the check `_isSameCell(dotB, dotA)` was ALWAYS false → nothing
          // ever happened → the pair's dots became permanently unresponsive.
          //
          // Fix: skip the redundant guard and always clear + restart from `cell`.
          _clearPath(pairId);
          _currentPairId = pairId;
          _isDrawing = true;
          _allPaths[pairId] = [PathCell(x: cell.x, y: cell.y)];
          _visitedCellsPerPath[pairId] = {_cellKey(cell)};
          _currentDragPosition = event.localPosition;
          onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
          return;
        }
      }
    }

    // No existing path for this pair - start fresh
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

    // FIX #10: Block gestures after puzzle completion.
    if (_puzzleCompleted) return;

    // CRITICAL: Only process if actively drawing and have a current pair
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

    // FIX #2: When dragging over a different pair's dot, DON'T kill the current
    // path. Simply treat it as an impassable cell and let the user keep drawing.
    // The path just won't extend into that cell.
    final dotAtCell = _getDotAtCell(cell);
    if (dotAtCell != null && dotAtCell.pairId != _currentPairId) {
      // Dragging over a different pair's dot — skip this cell, keep drawing.
      onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
      return;
    }

    // IMPORTANT: Check if path is already complete - if so, lock it immediately
    if (_isPathComplete(currentPath, _currentPairId!)) {
      // Path is complete, stop drawing and lock it
      _currentDragPosition = null;
      _finishPath();
      return;
    }

    // BACKTRACKING LOGIC: Only allow backtracking to the immediate previous cell
    // User must be dragging FROM an endpoint dot to backtrack
    if (currentPath.length >= 2) {
      final previousCell = currentPath[currentPath.length - 2];

      if (_isSameCell(previousCell, cell)) {
        // User is moving back to the previous cell - allow backtracking one step
        final removed = currentPath.removeLast();
        // FIX #4: Use safe null-coalescing access; the sets should always exist
        // alongside their path, but guard against any transient out-of-sync state.
        _visitedCellsPerPath[_currentPairId]?.remove(_cellKey(removed));
        onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
        return;
      }
    }

    // FIX #1: Interpolate intermediate cells to handle fast drags.
    // Instead of only accepting adjacent cells, walk from the last cell toward
    // the target cell along a straight line (horizontal or vertical only).
    // If the target is diagonal, try horizontal-first then vertical-first.
    if (_isAdjacent(currentPath.last, cell)) {
      // Direct neighbor — fast path, no interpolation needed.
      if (_isValidMove(cell, _currentPairId!)) {
        _addCellToPath(cell, currentPath);
      } else {
        _handleInvalidMove(cell);
      }
    } else {
      // Not adjacent — attempt to interpolate a path of cells between
      // the current endpoint and the target cell.
      _interpolateAndAdd(currentPath, cell);
    }
  }

  /// FIX #1: Walk from the last cell of [currentPath] toward [target],
  /// adding each intermediate cell if it passes validation.
  /// Tries horizontal-then-vertical first; if that fails at any step,
  /// tries vertical-then-horizontal.
  void _interpolateAndAdd(List<PathCell> currentPath, PathCell target) {
    final start = currentPath.last;
    final dx = target.x - start.x;
    final dy = target.y - start.y;

    // Build list of intermediate cells: horizontal first, then vertical.
    List<PathCell> hFirstCells = _buildInterpolatedCells(start, target, true);
    if (_tryAddCells(currentPath, hFirstCells)) return;

    // If horizontal-first failed, try vertical-first.
    List<PathCell> vFirstCells = _buildInterpolatedCells(start, target, false);
    if (_tryAddCells(currentPath, vFirstCells)) return;

    // Neither worked — show conflict feedback for the target cell.
    _handleInvalidMove(target);
  }

  /// Build a list of cells from [start] to [target] (exclusive of start).
  /// If [horizontalFirst] is true, move along X first then Y; otherwise Y first.
  List<PathCell> _buildInterpolatedCells(PathCell start, PathCell target, bool horizontalFirst) {
    final cells = <PathCell>[];
    int cx = start.x;
    int cy = start.y;

    if (horizontalFirst) {
      // Horizontal movement
      final stepX = target.x > cx ? 1 : -1;
      while (cx != target.x) {
        cx += stepX;
        cells.add(PathCell(x: cx, y: cy));
      }
      // Vertical movement
      final stepY = target.y > cy ? 1 : -1;
      while (cy != target.y) {
        cy += stepY;
        cells.add(PathCell(x: cx, y: cy));
      }
    } else {
      // Vertical movement first
      final stepY = target.y > cy ? 1 : -1;
      while (cy != target.y) {
        cy += stepY;
        cells.add(PathCell(x: cx, y: cy));
      }
      // Horizontal movement
      final stepX = target.x > cx ? 1 : -1;
      while (cx != target.x) {
        cx += stepX;
        cells.add(PathCell(x: cx, y: cy));
      }
    }

    return cells;
  }

  /// Try to add all [cells] to [currentPath]. Returns true if ALL cells were
  /// successfully added. If any cell fails validation, rolls back ALL additions
  /// from this batch and returns false.
  bool _tryAddCells(List<PathCell> currentPath, List<PathCell> cells) {
    final addedCells = <PathCell>[];

    for (final cell in cells) {
      if (_isValidMove(cell, _currentPairId!)) {
        _addCellToPath(cell, currentPath);
        addedCells.add(cell);

        // If path just became complete, finish immediately.
        if (_isPathComplete(currentPath, _currentPairId!)) {
          _currentDragPosition = null;
          _finishPath();
          return true;
        }
      } else {
        // Rollback all cells added in this batch.
        for (final added in addedCells.reversed) {
          currentPath.removeLast();
          _visitedCellsPerPath[_currentPairId]?.remove(_cellKey(added));
        }
        return false;
      }
    }

    onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
    return true;
  }

  /// Helper: add a single cell to the current path and its visited set.
  void _addCellToPath(PathCell cell, List<PathCell> currentPath) {
    currentPath.add(PathCell(x: cell.x, y: cell.y));
    _visitedCellsPerPath[_currentPairId]!.add(_cellKey(cell));
  }

  /// Helper: check if two cells are orthogonally adjacent.
  bool _isAdjacent(PathCell a, PathCell b) {
    final dx = (a.x - b.x).abs();
    final dy = (a.y - b.y).abs();
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }

  /// Handle an invalid move attempt — show conflict feedback if the cell
  /// is occupied by another path.
  void _handleInvalidMove(PathCell cell) {
    final cellKey = _cellKey(cell);
    for (final entry in _allPaths.entries) {
      if (entry.key != _currentPairId &&
          (_visitedCellsPerPath[entry.key] ?? {}).contains(cellKey)) {
        onPathConflict?.call();
        break;
      }
    }
    // Keep drag position for visual feedback
    onPathUpdate(_allPaths, _currentPairId, _currentDragPosition);
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

    // Check if the current path is complete before finishing
    final currentPath = _allPaths[_currentPairId];
    if (currentPath != null && _isPathComplete(currentPath, _currentPairId!)) {
      _completedPairIds.add(_currentPairId!);
    }

    _isDrawing = false;
    _currentPairId = null;

    // Check if puzzle is complete
    if (_validateCompletePuzzle()) {
      // FIX #10: Mark puzzle as completed to block further gestures.
      _puzzleCompleted = true;

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
    _completedPairIds.remove(pairId);
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
      // FIX #4: Safe lookup — guard against _visitedCellsPerPath being out of
      // sync with _allPaths (e.g. if a path was added but the set was not yet
      // initialised). Treat missing as empty.
      if ((_visitedCellsPerPath[entry.key] ?? {}).contains(_cellKey(cell))) {
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
    _completedPairIds.clear();
    _currentPairId = null;
    _isDrawing = false;
    _currentDragPosition = null;
    _puzzleCompleted = false; // FIX #10: Reset completion flag on puzzle reset.
    onPathUpdate(_allPaths, null, null);
  }

  Map<int, List<PathCell>> get allPaths => Map.unmodifiable(_allPaths);
}

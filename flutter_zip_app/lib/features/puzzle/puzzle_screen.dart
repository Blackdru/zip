import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../flame/puzzle_game.dart';
import '../../models/puzzle.dart';
import '../../models/grid_cell.dart';
import '../../providers/puzzle_provider.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  final String? puzzleId;
  final bool isPractice;

  const PuzzleScreen({
    super.key,
    this.puzzleId,
    this.isPractice = false,
  });

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  PuzzleGame? _game;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _isShowingCompletionDialog = false; // Prevent multiple dialogs

  // Hint state (only used to style the AppBar 'Hint' text)
  bool _hintActive = false;

  @override
  void initState() {
    super.initState();
    _loadPuzzle();
  }

  Future<void> _loadPuzzle() async {
    await Future.microtask(() async {
      if (widget.isPractice) {
        // For unlimited mode the puzzle is already loaded by PracticeScreen
        // Just use whatever is in puzzleProvider
      } else if (widget.puzzleId != null) {
        await ref.read(puzzleProvider.notifier).loadPuzzle(widget.puzzleId!);
      }

      final puzzleState = ref.read(puzzleProvider);
      if (puzzleState.puzzle != null) {
        _initializeGame(puzzleState.puzzle!);
        // Auto-start timer for all modes when puzzle is loaded
        _startTimer();
      }
    });
  }

  void _initializeGame(PuzzleData puzzle) {
    setState(() {
      _game = PuzzleGame(
        puzzleData: puzzle,
        onPuzzleComplete: _handlePuzzleComplete,
        onStateChanged: _handleStateChanged,
        onPathStuck: _handlePathStuck,
      );
    });
    // Start the Flame game timer (sets the internal startTimeMs reference)
    Future.microtask(() => _game?.startPuzzle());
  }

  void _handleStateChanged(GameState state) {
    setState(() {});
  }

  /// Called by PuzzleGame when the player reaches a dead end
  /// (no valid moves remain but the puzzle is not complete).
  void _handlePathStuck() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Dead end — no valid moves left. Backtrack or reset.',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFFB91C1C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'RESET',
          textColor: Colors.white,
          onPressed: () {
            _game?.reset();
            setState(() {
              _elapsedSeconds = 0;
              _isTimerRunning = false;
              _isShowingCompletionDialog = false;
            });
            _startTimer();
            Future.microtask(() => _game?.startPuzzle());
          },
        ),
      ),
    );
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
      _elapsedSeconds = 0;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isTimerRunning) return false;
      setState(() => _elapsedSeconds++);
      return true;
    });
  }

  void _handlePuzzleComplete(List<Move> moves, int solveTimeMs) async {
    if (_isShowingCompletionDialog) return; // Prevent multiple dialogs

    // Snapshot the elapsed UI-timer seconds before stopping the timer.
    // The game's internal solveTimeMs can be a huge Unix-timestamp-based value
    // if startPuzzle() was not called in time, so we use the Flutter timer for display.
    final displayTimeMs = _elapsedSeconds * 1000;

    setState(() {
      _isTimerRunning = false;
      _isShowingCompletionDialog = true;
    });

    if (!widget.isPractice && widget.puzzleId != null) {
      await ref.read(puzzleProvider.notifier).submitSolution(
            widget.puzzleId!,
            moves,
            solveTimeMs, // accurate ms for backend
          );
    }

    if (mounted) {
      _showCompletionDialog(displayTimeMs); // correct elapsed time for display
    }
  }

  // ─── Hint ───────────────────────────────────────────────────────────

  void _showHint() {
    final gameState = _game?.gameState;
    if (gameState == null || _game == null) return;

    final solutionPath = ref.read(puzzleProvider).practiceSolutionPath;
    final currentPath = gameState.currentPath;

    if (solutionPath.isNotEmpty) {
      int nextIdx = 0;
      if (currentPath.isNotEmpty) {
        final last = currentPath.last;
        final foundIdx = solutionPath.indexWhere(
          (s) => s.x == last.x && s.y == last.y,
        );
        nextIdx = (foundIdx >= 0) ? foundIdx + 1 : 0;
      }

      if (nextIdx < solutionPath.length) {
        final next = solutionPath[nextIdx];
        final cell = GridCell(x: next.x, y: next.y);

        // Delegate rendering to Flame — uses exact board coordinates
        _game!.showHint(cell);

        // Style the Hint button text for 3 seconds
        setState(() => _hintActive = true);
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (mounted) setState(() => _hintActive = false);
        });
      }
    }
  }

  // ─── Completion Dialog ────────────────────────────────────────────────────

  void _showCompletionDialog(int solveTimeMs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 32),
            SizedBox(width: 12),
            Text('Puzzle Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_rounded,
                      color: Color(0xFF4CAF50), size: 20,),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(solveTimeMs),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.isPractice
                  ? '🎉 Great job! Ready for another?'
                  : '✅ Solution submitted to tournament!',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          if (widget.isPractice) ...[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog using dialogContext
                _isShowingCompletionDialog = false; // Reset flag
                context.pop(); // Go back to practice screen for new puzzle
              },
              child: const Text('BACK'),
            ),
            ElevatedButton(
              onPressed: () {
                // Close dialog immediately
                Navigator.of(dialogContext).pop();
                
                // Reset dialog flag
                _isShowingCompletionDialog = false;
                
                // Then generate new puzzle (non-blocking)
                Future.microtask(() async {
                  try {
                    await ref.read(puzzleProvider.notifier).generateRandomPuzzle();
                    
                    if (mounted) {
                      final puzzleState = ref.read(puzzleProvider);
                      if (puzzleState.puzzle != null) {
                        setState(() {
                          _elapsedSeconds = 0;
                          _isTimerRunning = false;
                          _hintActive = false;
                        });
                        _initializeGame(puzzleState.puzzle!);
                        _startTimer();
                      }
                    }
                  } catch (e) {
                    print('Error generating puzzle: $e');
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3AFF),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('NEXT PUZZLE'),
            ),
          ] else
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog using dialogContext
                _isShowingCompletionDialog = false; // Reset flag
                context.pop(); // Go back
              },
              child: const Text('DONE'),
            ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(puzzleProvider);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.canvas,
        title: Text(
          widget.isPractice ? 'Practice' : 'Tournament',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.ink,
          ),
        ),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.ink),
          ),
        ),
        actions: [
          // Hint — text label, only for practice
          if (widget.isPractice && _game != null)
            GestureDetector(
              onTap: _showHint,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  'Hint',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _hintActive
                        ? const Color(0xFFB45309)
                        : AppTheme.inkLight,
                  ),
                ),
              ),
            ),
          // Reset — text label
          if (_game != null)
            GestureDetector(
              onTap: () {
                _game?.reset();
                setState(() {
                  _elapsedSeconds = 0;
                  _isTimerRunning = false;
                  _hintActive = false;
                  _isShowingCompletionDialog = false;
                });
                // Re-start timer immediately for both modes
                _startTimer();
                Future.microtask(() => _game?.startPuzzle());
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 20),
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.inkLight,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: puzzleState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : puzzleState.error != null
              ? _buildError(puzzleState.error!)
              : _game == null
                  ? const Center(
                      child: Text('Loading puzzle...',
                          style: TextStyle(color: AppTheme.inkLight),),
                    )
                  : Column(
                      children: [
                        _buildGameInfo(),
                        Expanded(
                          child: GameWidget(game: _game!),
                        ),
                      ],
                    ),
    );
  }

  // ─── Game Info Bar ────────────────────────────────────────────────────────

  Widget _buildGameInfo() {
    final gameState = _game?.gameState;
    final gridSize = ref.read(puzzleProvider).puzzle?.gridSize ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          _infoCell('TIME', _formatTime(_elapsedSeconds * 1000)),
          _divider(),
          _infoCell(
            'CHECKPOINTS',
            '${gameState?.solvedCheckpoints ?? 0} / ${gameState?.totalCheckpoints ?? 0}',
          ),
          _divider(),
          _infoCell('GRID', '$gridSize × $gridSize'),
        ],
      ),
    );
  }


  Widget _infoCell(String label, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkLight,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      color: AppTheme.border,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }



  // ─── Error ────────────────────────────────────────────────────────────────

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(error, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPuzzle,
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _isTimerRunning = false;
    super.dispose();
  }
}

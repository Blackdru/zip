import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../flame/connect_dots_game.dart';
import '../../models/connect_dots_puzzle.dart';
import '../../models/color_dot.dart';
import '../../providers/connect_dots_provider.dart';
import '../../providers/puzzle_stats_provider.dart';

class ConnectDotsScreen extends ConsumerStatefulWidget {
  final String? puzzleId;
  final bool isPractice;

  const ConnectDotsScreen({
    super.key,
    this.puzzleId,
    this.isPractice = false,
  });

  @override
  ConsumerState<ConnectDotsScreen> createState() => _ConnectDotsScreenState();
}

class _ConnectDotsScreenState extends ConsumerState<ConnectDotsScreen> {
  ConnectDotsGame? _game;
  int _elapsedSeconds = 0;
  // FIX #1: Use a cancellable Timer instead of Future.doWhile to prevent
  // setState calls on a disposed widget.
  Timer? _timer;
  bool _isShowingCompletionDialog = false;

  // FIX #9: Track last-known display values so we only rebuild when they change.
  int _lastCompletedPairs = 0;
  GamePhase _lastPhase = GamePhase.idle;

  @override
  void initState() {
    super.initState();
    _loadPuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPuzzle() async {
    // FIX #2: Use microtask to defer provider access until after the first frame,
    // then wait for the notifier's async work to complete before reading state.
    await Future.microtask(() async {
      if (widget.isPractice) {
        // Puzzle already loaded by PracticeScreen — read it directly.
        final puzzleState = ref.read(connectDotsProvider);
        if (puzzleState.puzzle != null && mounted) {
          _initializeGame(puzzleState.puzzle!);
          _startTimer();
        }
      } else if (widget.puzzleId != null) {
        // Await the full async load so the state is settled before we read it.
        await ref.read(connectDotsProvider.notifier).loadPuzzle(widget.puzzleId!);
        if (!mounted) return;
        final puzzleState = ref.read(connectDotsProvider);
        if (puzzleState.puzzle != null) {
          _initializeGame(puzzleState.puzzle!);
          _startTimer();
        }
      }
    });
  }

  void _initializeGame(ConnectDotsPuzzle puzzle) {
    setState(() {
      _game = ConnectDotsGame(
        puzzleData: puzzle,
        onPuzzleComplete: _handlePuzzleComplete,
        onStateChanged: _handleStateChanged,
        onPathConflict: _handlePathConflict,
      );
    });
    Future.microtask(() => _game?.startPuzzle());
  }

  void _handleStateChanged(GameState state) {
    // FIX #9: Only rebuild the widget tree when values shown in the AppBar
    // actually change. During active drawing, the game fires onStateChanged
    // for every cell crossed (30-60 times/sec), but only completedPairs and
    // phase are visible in this screen — skip the rebuild otherwise.
    if (state.completedPairs != _lastCompletedPairs || state.phase != _lastPhase) {
      _lastCompletedPairs = state.completedPairs;
      _lastPhase = state.phase;
      if (mounted) setState(() {});
    }
  }

  void _handlePathConflict() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Paths cannot cross or overlap',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFFB91C1C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _startTimer() {
    // FIX #1: Cancel any existing timer before starting a new one to prevent
    // double-timer bugs (e.g. reset → new puzzle path).
    _timer?.cancel();
    setState(() {
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _handlePuzzleComplete(
    List<PlayerPath> playerPaths,
    int solveTimeMs,
  ) async {
    if (_isShowingCompletionDialog) return;

    // BUG FIX #8: The old code used `_elapsedSeconds * 1000` which is only
    // 1-second granular (the widget-side Timer.periodic ticks once per second).
    // The game engine already tracks precise milliseconds from startPuzzle() to
    // completion — use that directly for both display and server submission.
    final displayTimeMs = solveTimeMs;

    // Stop the timer when the puzzle completes.
    _timer?.cancel();
    setState(() {
      _isShowingCompletionDialog = true;
    });

    // Increment completed puzzles count for practice mode
    if (widget.isPractice) {
      await ref.read(puzzleStatsProvider.notifier).markPuzzleCompleted();
    }

    if (!widget.isPractice && widget.puzzleId != null) {
      await ref.read(connectDotsProvider.notifier).submitSolution(
            widget.puzzleId!,
            playerPaths,
            solveTimeMs,
          );
    }

    if (mounted) {
      _showCompletionDialog(displayTimeMs);
    }
  }

  void _showCompletionDialog(int solveTimeMs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              ),
              child: const Icon(
                Icons.check,
                size: 48,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Puzzle Complete!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _formatTime(solveTimeMs ~/ 1000),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                foreground: Paint()
                  ..shader = AppTheme.primaryGradient.createShader(
                    const Rect.fromLTWH(0, 0, 200, 70),
                  ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Time to complete',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // FIX #12: Use context.go() instead of double context.pop().
              // The double-pop assumed a specific stack depth which could
              // break with deep links or stack manipulation.
              context.go('/practice');
            },
            child: const Text('BACK'),
          ),
          
          if (widget.isPractice)
            ElevatedButton(
              onPressed: () {
                context.pop(); // Close dialog
                // FIX #3: Don't call _resetPuzzle() here — it would start a
                // timer that _startNewPuzzle() immediately starts a second one.
                // Instead, reset state flags and let _startNewPuzzle manage
                // the game + timer lifecycle entirely.
                setState(() {
                  _isShowingCompletionDialog = false;
                  _elapsedSeconds = 0;
                });
                _startNewPuzzle();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
              ),
              child: const Text('NEXT PUZZLE'),
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _resetPuzzle() {
    setState(() {
      _elapsedSeconds = 0;
      _isShowingCompletionDialog = false;
    });
    _game?.reset();
    // _startTimer() cancels any previous timer internally before starting fresh.
    _startTimer();
  }

  Future<void> _startNewPuzzle() async {
    final puzzleState = ref.read(connectDotsProvider);
    if (puzzleState.puzzle != null) {
      final difficulty = puzzleState.puzzle!.difficulty;
      final sequence = DateTime.now().millisecondsSinceEpoch % 1000;

      // Clear any stale error before starting a new request (same fix as in
      // practice_screen). The copyWith sentinel means isLoading=true no longer
      // wipes the error, so we must clear it explicitly before a new attempt.
      ref.read(connectDotsProvider.notifier).clearError();

      await ref
          .read(connectDotsProvider.notifier)
          .generatePracticePuzzle(difficulty, sequence);

      if (!mounted) return;

      final newState = ref.read(connectDotsProvider);
      if (newState.error != null) {
        // Network / server failure: show error and clear it from the provider.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load next puzzle: ${newState.error}'),
            backgroundColor: const Color(0xFFB91C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(connectDotsProvider.notifier).clearError();
        return;
      }

      final newPuzzle = newState.puzzle;
      if (newPuzzle != null) {
        // _initializeGame + _startTimer are the single path that starts the
        // timer; no duplicate start happens here.
        _initializeGame(newPuzzle);
        _startTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(connectDotsProvider);
    final gameState = _game?.gameState;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_elapsedSeconds),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Progress
            if (gameState != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${gameState.completedPairs}/${gameState.totalPairs}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        actions: [
          // Reset button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: _resetPuzzle,
          ),
        ],
      ),
      body: puzzleState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _game == null
              ? const Center(child: Text('No puzzle loaded'))
              : GameWidget(game: _game!),
    );
  }
}

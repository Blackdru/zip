import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../flame/connect_dots_game.dart';
import '../../models/connect_dots_puzzle.dart';
import '../../models/color_dot.dart';
import '../../providers/connect_dots_provider.dart';

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
  bool _isTimerRunning = false;
  bool _isShowingCompletionDialog = false;

  @override
  void initState() {
    super.initState();
    _loadPuzzle();
  }

  Future<void> _loadPuzzle() async {
    await Future.microtask(() async {
      if (widget.isPractice) {
        // Puzzle already loaded by PracticeScreen
      } else if (widget.puzzleId != null) {
        await ref.read(connectDotsProvider.notifier).loadPuzzle(widget.puzzleId!);
      }

      final puzzleState = ref.read(connectDotsProvider);
      if (puzzleState.puzzle != null) {
        _initializeGame(puzzleState.puzzle!);
        _startTimer();
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
    setState(() {});
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

  void _handlePuzzleComplete(
    List<PlayerPath> playerPaths,
    int solveTimeMs,
  ) async {
    if (_isShowingCompletionDialog) return;

    final displayTimeMs = _elapsedSeconds * 1000;

    setState(() {
      _isTimerRunning = false;
      _isShowingCompletionDialog = true;
    });

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
              context.pop(); // Close dialog
              context.pop(); // Back to practice screen
            },
            child: const Text('BACK'),
          ),
          
          if (widget.isPractice)
            ElevatedButton(
              onPressed: () {
                context.pop(); // Close dialog
                _resetPuzzle();
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
      _isTimerRunning = false;
      _isShowingCompletionDialog = false;
    });
    _game?.reset();
    _startTimer();
  }

  Future<void> _startNewPuzzle() async {
    final puzzleState = ref.read(connectDotsProvider);
    if (puzzleState.puzzle != null) {
      final difficulty = puzzleState.puzzle!.difficulty;
      final sequence = DateTime.now().millisecondsSinceEpoch % 1000;
      
      await ref
          .read(connectDotsProvider.notifier)
          .generatePracticePuzzle(difficulty, sequence);
      
      final newPuzzle = ref.read(connectDotsProvider).puzzle;
      if (newPuzzle != null) {
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

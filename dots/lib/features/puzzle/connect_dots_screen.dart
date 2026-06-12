import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/app_theme.dart';
import '../../flame/connect_dots_game.dart';
import '../../models/connect_dots_puzzle.dart';
import '../../models/color_dot.dart';
import '../../providers/connect_dots_provider.dart';
import '../../providers/puzzle_stats_provider.dart';
import '../../services/ad_service.dart';

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

  // Banner ad
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPuzzle();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = AdService().createBannerAd();
    if (_bannerAd != null) {
      _bannerAd!.load().then((_) {
        setState(() {
          _isBannerAdLoaded = true;
        });
      });
    }
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
        }
      } else if (widget.puzzleId != null) {
        // Await the full async load so the state is settled before we read it.
        await ref.read(connectDotsProvider.notifier).loadPuzzle(widget.puzzleId!);
        if (!mounted) return;
        final puzzleState = ref.read(connectDotsProvider);
        if (puzzleState.puzzle != null) {
          _initializeGame(puzzleState.puzzle!);
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
        onGameReady: () {
          // Start widget timer when game engine timer starts
          _startTimer();
        },
      );
    });
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

  void _startTimer({bool resetSeconds = true}) {
    // FIX #1: Cancel any existing timer before starting a new one to prevent
    // double-timer bugs (e.g. reset → new puzzle path).
    _timer?.cancel();
    if (resetSeconds) {
      setState(() {
        _elapsedSeconds = 0;
      });
    }
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
      // Notify ad service about puzzle completion (for interstitial ads)
      AdService().onPuzzleCompleted();
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
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CompletionSheet(
        solveTimeMs: solveTimeMs,
        isPractice: widget.isPractice,
        formattedTime: _formatTime(solveTimeMs ~/ 1000),
        onBack: () => context.go('/practice'),
        onNextPuzzle: widget.isPractice
            ? () {
                Navigator.of(ctx).pop();
                setState(() {
                  _isShowingCompletionDialog = false;
                  _elapsedSeconds = 0;
                });
                _startNewPuzzle();
              }
            : null,
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
      // Do NOT reset _elapsedSeconds — timer keeps running on puzzle reset.
      _isShowingCompletionDialog = false;
    });
    _game?.reset();
    // Resume timer without resetting the elapsed time.
    _startTimer(resetSeconds: false);
  }

  void _showHint() {
    final puzzleState = ref.read(connectDotsProvider);
    final puzzle = puzzleState.puzzle;
    if (puzzle == null || _game == null) return;

    final solutionPaths = puzzle.solutionPaths;
    if (solutionPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hints available for this puzzle'),
          backgroundColor: AppTheme.primaryPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final activePaths = _game!.gameState.activePaths;
    final colorDots = puzzle.colorDots;

    int? targetPairId;
    int pairLabel = 1;

    final pairIds = colorDots.map((d) => d.pairId).toSet().toList()..sort();

    // 1. First, look for an unconnected pair (no path drawn at all, or path
    //    doesn't reach both dots).
    for (int i = 0; i < pairIds.length; i++) {
      final pid = pairIds[i];
      final path = activePaths[pid];
      bool isCompleted = false;
      if (path != null && path.length >= 2) {
        final pairDots = colorDots.where((d) => d.pairId == pid).toList();
        if (pairDots.length == 2) {
          final first = path.first;
          final last = path.last;
          isCompleted = (first.x == pairDots[0].x && first.y == pairDots[0].y &&
                  last.x == pairDots[1].x && last.y == pairDots[1].y) ||
              (first.x == pairDots[1].x && first.y == pairDots[1].y &&
                  last.x == pairDots[0].x && last.y == pairDots[0].y);
        }
      }
      if (!isCompleted) {
        targetPairId = pid;
        pairLabel = i + 1;
        break;
      }
    }

    // 2. Dead-end fallback: all pairs are connected but the puzzle isn't solved
    //    (paths are wrong). Find which path needs to change to fill empty cells.
    bool isDeadEndHint = false;
    if (targetPairId == null && _game!.gameState.phase != GamePhase.completed) {
      // Calculate which cells are currently empty
      final gridSize = puzzle.gridSize;
      final totalCells = gridSize * gridSize;
      final filledCells = <String>{};
      for (final path in activePaths.values) {
        for (final cell in path) {
          filledCells.add('${cell.x},${cell.y}');
        }
      }
      final emptyCellCount = totalCells - filledCells.length;
      
      if (emptyCellCount > 0) {
        // Find the path that, when replaced with the solution, would fill the most empty cells
        int maxEmptyCellsCovered = 0;
        int? bestPairId;
        
        for (int i = 0; i < pairIds.length; i++) {
          final pid = pairIds[i];
          final playerPath = activePaths[pid];
          if (playerPath == null) continue;
          
          final solution = solutionPaths.where((s) => s.pairId == pid).firstOrNull;
          if (solution == null) continue;
          
          // Calculate how many currently-empty cells this solution path would cover
          final solutionCells = <String>{};
          for (final cell in solution.path) {
            final key = '${cell.x},${cell.y}';
            if (!filledCells.contains(key)) {
              solutionCells.add(key);
            }
          }
          
          // Also check if the current player path differs from solution
          bool pathMatches = false;
          if (playerPath.length == solution.path.length) {
            bool forwardMatch = true;
            for (int j = 0; j < playerPath.length; j++) {
              if (playerPath[j].x != solution.path[j].x ||
                  playerPath[j].y != solution.path[j].y) {
                forwardMatch = false;
                break;
              }
            }
            if (!forwardMatch) {
              bool reverseMatch = true;
              for (int j = 0; j < playerPath.length; j++) {
                final sj = solution.path[solution.path.length - 1 - j];
                if (playerPath[j].x != sj.x || playerPath[j].y != sj.y) {
                  reverseMatch = false;
                  break;
                }
              }
              pathMatches = reverseMatch;
            } else {
              pathMatches = true;
            }
          }
          
          // Prioritize paths that: 1) don't match solution, AND 2) would cover empty cells
          if (!pathMatches && solutionCells.length > maxEmptyCellsCovered) {
            maxEmptyCellsCovered = solutionCells.length;
            bestPairId = pid;
          }
        }
        
        if (bestPairId != null) {
          targetPairId = bestPairId;
          pairLabel = pairIds.indexOf(bestPairId) + 1;
          isDeadEndHint = true;
        } else {
          // Fallback: just find the first mismatched path
          for (int i = 0; i < pairIds.length; i++) {
            final pid = pairIds[i];
            final playerPath = activePaths[pid];
            if (playerPath == null) continue;

            final solution = solutionPaths.where((s) => s.pairId == pid).firstOrNull;
            if (solution == null) continue;

            bool pathMatches = false;
            if (playerPath.length == solution.path.length) {
              bool forwardMatch = true;
              for (int j = 0; j < playerPath.length; j++) {
                if (playerPath[j].x != solution.path[j].x ||
                    playerPath[j].y != solution.path[j].y) {
                  forwardMatch = false;
                  break;
                }
              }
              if (!forwardMatch) {
                bool reverseMatch = true;
                for (int j = 0; j < playerPath.length; j++) {
                  final sj = solution.path[solution.path.length - 1 - j];
                  if (playerPath[j].x != sj.x || playerPath[j].y != sj.y) {
                    reverseMatch = false;
                    break;
                  }
                }
                pathMatches = reverseMatch;
              } else {
                pathMatches = true;
              }
            }

            if (!pathMatches) {
              targetPairId = pid;
              pairLabel = i + 1;
              isDeadEndHint = true;
              break;
            }
          }
        }
      }
    }

    if (targetPairId != null) {
      final solution = solutionPaths.firstWhere(
        (s) => s.pairId == targetPairId,
        orElse: () => solutionPaths.first,
      );

      // For dead-end hints, show a message explaining which path needs to change
      if (isDeadEndHint) {
        final dot = colorDots.where((d) => d.pairId == targetPairId).firstOrNull;
        final colorName = dot?.color ?? 'this';
        
        // Count empty cells to give better feedback
        final gridSize = puzzle.gridSize;
        final totalCells = gridSize * gridSize;
        final filledCells = <String>{};
        for (final path in activePaths.values) {
          for (final cell in path) {
            filledCells.add('${cell.x},${cell.y}');
          }
        }
        final emptyCellCount = totalCells - filledCells.length;
        
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              emptyCellCount > 1
                  ? 'Change the $colorName path - $emptyCellCount cells need to be filled'
                  : 'Adjust the $colorName path to fill the last cell',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
          ),
        );
        
        // For dead-end hints, clear the player's path first so they can
        // see the complete correct solution without confusion
        _game!.clearPath(targetPairId);
      }

      // Show the hint
      _game!.showPathHint(solution, pairLabel, forceComplete: isDeadEndHint);
    }
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
        // _initializeGame will start both game and widget timers via callback
        _initializeGame(newPuzzle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(connectDotsProvider);
    final gameState = _game?.gameState;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      // ── Top bar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            // ── Timer pill ──────────────────────────────────────────────────
            _StatPill(
              icon: Icons.timer_outlined,
              label: _formatTime(_elapsedSeconds),
              iconColor: AppTheme.primaryCyan,
            ),
            const SizedBox(width: 10),
            // ── Pairs progress pill ─────────────────────────────────────────
            if (gameState != null)
              _StatPill(
                icon: Icons.radio_button_checked,
                label: '${gameState.completedPairs} / ${gameState.totalPairs}',
                iconColor: AppTheme.accentGreen,
              ),
          ],
        ),
        actions: [
          // ── Hint button ────────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Colors.white70),
            tooltip: 'Hint',
            onPressed: _showHint,
          ),
          // ── Reset button ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              tooltip: 'Reset',
              onPressed: _resetPuzzle,
            ),
          ),
        ],
      ),
      // ── Game body ──────────────────────────────────────────────────────────
      body: puzzleState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryPurple))
          : _game == null
              ? const Center(
                  child: Text('No puzzle loaded',
                      style: TextStyle(color: Colors.white54)))
              : Column(
                  children: [
                    // Game area
                    Expanded(
                      child: GameWidget(game: _game!),
                    ),
                    // Banner ad at the bottom
                    if (_isBannerAdLoaded && _bannerAd != null)
                      Container(
                        alignment: Alignment.center,
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                  ],
                ),
    );
  }
}

// ── Stat pill widget used in the AppBar ───────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Puzzle completion bottom sheet ────────────────────────────────────────────
class _CompletionSheet extends StatelessWidget {
  final int solveTimeMs;
  final bool isPractice;
  final String formattedTime;
  final VoidCallback onBack;
  final VoidCallback? onNextPuzzle;

  const _CompletionSheet({
    required this.solveTimeMs,
    required this.isPractice,
    required this.formattedTime,
    required this.onBack,
    this.onNextPuzzle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Trophy icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentGreen.withValues(alpha: 0.12),
              border: Border.all(
                color: AppTheme.accentGreen.withValues(alpha: 0.40),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 42,
              color: AppTheme.accentGreen,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Puzzle Complete!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Great job solving the puzzle',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.50),
            ),
          ),

          const SizedBox(height: 28),

          // Time stat box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 22,
                  color: AppTheme.primaryCyan,
                ),
                const SizedBox(width: 10),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'solve time',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Action buttons ─────────────────────────────────────────────────
          if (isPractice && onNextPuzzle != null)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onNextPuzzle,
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text(
                  'NEXT PUZZLE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),

          if (isPractice && onNextPuzzle != null) const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.home_outlined, size: 20),
              label: const Text(
                'BACK TO HOME',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

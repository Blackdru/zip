import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../flame/puzzle_game.dart';
import '../../models/puzzle.dart';
import '../../models/grid_cell.dart';
import '../../providers/puzzle_provider.dart';
import '../../services/ad_service.dart';
import '../../widgets/banner_ad_widget.dart';

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
        duration: const Duration(seconds: 5),
        content: const Text(
          'Wrong Turn — Move back and take a Hint or restart',
          style:  TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color.fromARGB(255, 196, 10, 10),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

    // Show interstitial ad after every 3-4 games
    AdService().onPuzzleCompleted();

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

    if (solutionPath.isEmpty) return;

    // Find the longest matching prefix between current path and solution path
    int matchingLength = 0;
    for (int i = 0; i < currentPath.length && i < solutionPath.length; i++) {
      final current = currentPath[i];
      final solution = solutionPath[i];
      if (current.x == solution.x && current.y == solution.y) {
        matchingLength = i + 1;
      } else {
        // Stop at first mismatch
        break;
      }
    }

    // The next hint is the cell right after the longest matching sequence
    final nextIdx = matchingLength;
    
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

  // ─── Completion Dialog ────────────────────────────────────────────────────

  void _showCompletionDialog(int solveTimeMs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.richPurple,
                AppTheme.deepPurple,
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppTheme.vibrantPurple.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.vibrantPurple.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with glow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neonGreen.withValues(alpha: 0.1),
                      AppTheme.electricBlue.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonGreen.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Color.fromARGB(255, 17, 221, 105),
                ),
              ),
              
              const SizedBox(height: 24),
              
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.successGradient.createShader(bounds),
                child: const Text(
                  'Excellent !',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Time display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.vibrantPurple.withValues(alpha: 0.3),
                      AppTheme.neonPink.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.vibrantPurple.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_rounded,
                      color: AppTheme.electricBlue,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatTime(solveTimeMs),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                widget.isPractice
                    ? ''
                    : ' Solution submitted successfully!',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.inkLight.withValues(alpha: 0.9),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              if (widget.isPractice) ...[
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _isShowingCompletionDialog = false;
                      
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
                      backgroundColor: AppTheme.vibrantPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'NEXT PUZZLE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _isShowingCompletionDialog = false;
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'BACK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _isShowingCompletionDialog = false;
                      context.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.vibrantPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final puzzleState = ref.watch(puzzleProvider);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.richPurple.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.vibrantPurple.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        actions: [
          // Hint button
          if (widget.isPractice && _game != null)
            GestureDetector(
              onTap: _showHint,
              child: Container(
                margin: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _hintActive
                        ? [
                            AppTheme.warmOrange.withValues(alpha: 0.5),
                            AppTheme.warmOrange.withValues(alpha: 0.4),
                          ]
                        : [
                            AppTheme.vibrantPurple.withValues(alpha: 0.4),
                            AppTheme.neonPink.withValues(alpha: 0.3),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hintActive
                        ? AppTheme.warmOrange.withValues(alpha: 0.7)
                        : AppTheme.vibrantPurple.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      size: 16,
                      color: _hintActive ? AppTheme.warmOrange : AppTheme.electricBlue,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Hint',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Reset button
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
                _startTimer();
                Future.microtask(() => _game?.startPuzzle());
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 2, bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neonPink.withValues(alpha: 0.2),
                      AppTheme.errorRed.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.neonPink.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: AppTheme.neonPink,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
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
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.vibrantPurple.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: GameWidget(game: _game!),
                            ),
                          ),
                        ),
                        // Banner Ad at the bottom
                        const BannerAdWidget(),
                      ],
                    ),
    );
  }

  // ─── Game Info Bar ────────────────────────────────────────────────────────

  Widget _buildGameInfo() {
    final gameState = _game?.gameState;
    final gridSize = ref.read(puzzleProvider).puzzle?.gridSize ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.richPurple.withValues(alpha: 0.9),
            AppTheme.richPurple.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.vibrantPurple.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vibrantPurple.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          _infoCell(
            Icons.timer_rounded,
            'TIME',
            _formatTime(_elapsedSeconds * 1000),
            AppTheme.electricBlue,
          ),
          _divider(),
          _infoCell(
            Icons.flag_rounded,
            'PROGRESS',
            '${gameState?.solvedCheckpoints ?? 0}/${gameState?.totalCheckpoints ?? 0}',
            AppTheme.neonGreen,
          ),
          _divider(),
          _infoCell(
            Icons.grid_4x4_rounded,
            'GRID',
            '$gridSize×$gridSize',
            AppTheme.neonPink,
          ),
        ],
      ),
    );
  }

  Widget _infoCell(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.inkLight.withValues(alpha: 0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 2,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.border.withValues(alpha: 0.3),
            AppTheme.vibrantPurple.withValues(alpha: 0.2),
            AppTheme.border.withValues(alpha: 0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
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
    // Clear any snackbars when leaving the puzzle screen
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
    super.dispose();
  }
}

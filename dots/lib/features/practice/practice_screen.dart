import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/connect_dots_provider.dart';
import '../../providers/puzzle_stats_provider.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(puzzleStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Connect Dots',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          // "Try Path Puzzle" promo button
          _buildTryZipButton(context),
          IconButton(
            icon: const Icon(Icons.settings, size: 22),
            color: Colors.white60,
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      // ── Scrollable content ─────────────────────────────────
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),

                              // ── Hero icon ──────────────────────────────────
                              _buildHeroIcon(),

                              const SizedBox(height: 28),

                              // ── Gradient title ─────────────────────────────
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    AppTheme.primaryGradient.createShader(bounds),
                                child: const Text(
                                  'Unlimited',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -2,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              const Text(
                                'Puzzles',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -2,
                                  height: 1.05,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                'Uniquely generated every time.\nEasy to hard — play at your pace.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  height: 1.65,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ── Stats card — always visible ────────────────
                              _buildStatsCard(statsState.totalCompleted),

                              const SizedBox(height: 28),

                              // ── Difficulty section ─────────────────────────
                              _buildDifficultySection(),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),

                      // ── Pinned CTA button ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: _buildStartButton(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Loading overlay ──────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryPurple,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Generating puzzle…',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero: App icon with glow effect ──────────────────────────────────────────
  Widget _buildHeroIcon() {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.30),
            const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.20),
          ],
        ),
        
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(
          'assets/icons/app_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to original dot grid if icon not found
            return _buildFallbackDotGrid();
          },
        ),
      ),
    );
  }

  // Fallback dot grid in case icon fails to load
  Widget _buildFallbackDotGrid() {
    final dotColors = [
      AppTheme.primaryPurple,
      AppTheme.primaryCyan,
      AppTheme.primaryPurple,
      AppTheme.accentGreen,
      AppTheme.primaryPink,
      AppTheme.accentGreen,
      AppTheme.primaryCyan,
      AppTheme.accentYellow,
      AppTheme.primaryCyan,
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: dotColors.map((c) => _dot(c)).toList(),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // ── Stats card ───────────────────────────────────────────────────────────────
  Widget _buildStatsCard(int total) {
    final hasCompleted = total > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasCompleted
              ? [
                  AppTheme.accentGreen.withValues(alpha: 0.12),
                  AppTheme.primaryCyan.withValues(alpha: 0.07),
                ]
              : [
                  AppTheme.cardBackground.withValues(alpha: 0.80),
                  AppTheme.cardBackground.withValues(alpha: 0.50),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasCompleted
              ? AppTheme.accentGreen.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.10),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: hasCompleted
                  ? AppTheme.accentGreen.withValues(alpha: 0.15)
                  : AppTheme.primaryPurple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasCompleted ? Icons.emoji_events_rounded : Icons.grid_on_rounded,
              size: 22,
              color: hasCompleted ? AppTheme.accentGreen : AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCompleted
                      ? '$total ${total == 1 ? 'Puzzle' : 'Puzzles'} Completed'
                      : 'No puzzles yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: hasCompleted ? Colors.white : Colors.white60,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasCompleted
                      ? 'Keep going — your streak is building!'
                      : 'Start your first puzzle below',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          if (hasCompleted) const Text('', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  // ── Difficulty section ───────────────────────────────────────────────────────
  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: AppTheme.primaryPurple.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              'RANDOM DIFFICULTY MODES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.45),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Three difficulty cards side by side
        Row(
          children: [
            Expanded(
              child: _diffCard(
                'Easy',
                '6×6',
                '3 pairs',
                AppTheme.accentGreen,
                Icons.sentiment_satisfied_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _diffCard(
                'Medium',
                '7×7',
                '4–5 pairs',
                AppTheme.accentYellow,
                Icons.sentiment_neutral_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _diffCard(
                'Hard',
                '8×8',
                '6–7 pairs',
                AppTheme.primaryPink,
                Icons.sentiment_very_dissatisfied_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Random note
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.30),
              ),
              const SizedBox(width: 6),
              Text(
                'Mode is randomly selected for each puzzle',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.30),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _diffCard(
    String label,
    String grid,
    String detail,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            grid,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          Text(
            detail,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.30),
            ),
          ),
        ],
      ),
    );
  }

  // ── Start button ─────────────────────────────────────────────────────────────
  Widget _buildStartButton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Shimmer
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    painter: _ShimmerPainter(animation: _shimmerController),
                  ),
                ),
              ),
              // Content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _startRandomPuzzle,
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 26,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'START NEW PUZZLE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Try Path Puzzle promo button ─────────────────────────────────────────────
  Widget _buildTryZipButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPink,
            AppTheme.primaryPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final url = Uri.parse(
                'https://play.google.com/store/apps/details?id=com.robotpdf.zip');
            try {
              if (!await launchUrl(url,
                  mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open store link')),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/zip/app_icon.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.videogame_asset,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Try Path Puzzle',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Business logic ───────────────────────────────────────────────────────────
  Future<void> _startRandomPuzzle() async {
    setState(() => _isLoading = true);

    ref.read(connectDotsProvider.notifier).clearError();

    try {
      await ref.read(connectDotsProvider.notifier).generateRandomPuzzle();

      if (!mounted) return;

      final puzzleState = ref.read(connectDotsProvider);

      if (puzzleState.error != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${puzzleState.error}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        ref.read(connectDotsProvider.notifier).clearError();
        return;
      }

      setState(() => _isLoading = false);
      context.push('/puzzle?isPractice=true');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load puzzle: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

// ── Shimmer painter ───────────────────────────────────────────────────────────
class _ShimmerPainter extends CustomPainter {
  final Animation<double> animation;

  _ShimmerPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(animation.value * 2 * 3.14159),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) => true;
}

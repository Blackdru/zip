import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../providers/puzzle_provider.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with SingleTickerProviderStateMixin {
  int _sessionCount = 0;
  bool _isGenerating = false;
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

  Future<void> _startPuzzle() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    
    try {
      await ref.read(puzzleProvider.notifier).generateRandomPuzzle();
      if (mounted) {
        setState(() {
          _sessionCount++;
          _isGenerating = false;
        });
        context.push('${AppRoutes.puzzle}?practice=true');
      }
    } catch (_) {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _showHowToPlay,
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.electricBlue.withValues(alpha: 0.2),
                    AppTheme.vibrantPurple.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.electricBlue.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: AppTheme.electricBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'How to Play',
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
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  AppTheme.vibrantPurple.withValues(alpha: 0.15),
                  AppTheme.canvas,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  // Title with gradient
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.neonGradient.createShader(bounds),
                    child: const Text(
                      'Unlimited',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.8,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const Text(
                    'Puzzles',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                      letterSpacing: -1.8,
                      height: 1.1,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Each puzzle is uniquely generated.\nPlay endless puzzles at your own pace.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.inkLight.withValues(alpha: 0.8),
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Difficulty cards
                  _buildDifficultyCards(),
                  
                  const Spacer(),
                  
                  // Session count
                  if (_sessionCount > 0) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.neonGreen.withValues(alpha: 0.2),
                              AppTheme.electricBlue.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.neonGreen.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              size: 20,
                              color: AppTheme.neonGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_sessionCount ${_sessionCount == 1 ? 'PUZZLE' : 'PUZZLES'} COMPLETED',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // CTA Button
                  _buildStartButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyCards() {
    final difficulties = [
      (
        'EASY',
        '5×5',
        '5-6 checkpoints',
        AppTheme.neonGreen,
        Icons.sentiment_satisfied_alt_rounded
      ),
      (
        'MEDIUM',
        '6×6',
        '7-9 checkpoints',
        const Color.fromARGB(255, 235, 160, 23),
        Icons.sentiment_neutral_rounded
      ),
      (
        'HARD',
        '7×7',
        '10-12 checkpoints',
        const Color.fromARGB(255, 161, 7, 7),
        Icons.sentiment_very_dissatisfied_rounded
      ),
    ];

    return Column(
      children: difficulties.map((diff) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                diff.$4.withValues(alpha: 0.15),
                diff.$4.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: diff.$4.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: diff.$4.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(diff.$5, size: 28, color: diff.$4),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diff.$1,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: diff.$4,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${diff.$2} • ${diff.$3}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.inkLight.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: diff.$4.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: diff.$4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartButton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            gradient: AppTheme.neonGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.vibrantPurple.withValues(alpha: 0.5),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer effect
              if (!_isGenerating)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(
                      painter: _ShimmerPainter(
                        animation: _shimmerController,
                      ),
                    ),
                  ),
                ),
              
              // Button content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isGenerating ? null : _startPuzzle,
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: _isGenerating
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 24,
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

  void _showHowToPlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _HowToPlaySheet(),
    );
  }
}

// Shimmer effect painter
class _ShimmerPainter extends CustomPainter {
  final Animation<double> animation;

  _ShimmerPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.3),
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

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.richPurple,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 32, top: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.neonGradient.createShader(bounds),
                child: const Text(
                  'How to Play',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              _rule(
                Icons.flag_rounded,
                'The Goal',
                'Draw a single continuous path that visits every cell exactly once.',
                AppTheme.vibrantPurple,
              ),
              _rule(
                Icons.looks_one_rounded,
                'Checkpoints',
                'Numbered cells must be visited in order — 1, 2, 3…',
                AppTheme.electricBlue,
              ),
              _rule(
                Icons.touch_app_rounded,
                'Drawing',
                'Tap and drag across cells to draw your path.',
                AppTheme.neonGreen,
              ),
              _rule(
                Icons.lightbulb_rounded,
                'Hints',
                'Tap "Hint" during play to reveal the next correct step.',
                AppTheme.warmOrange,
              ),
              
              const SizedBox(height: 32),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.vibrantPurple.withValues(alpha: 0.2),
                      AppTheme.neonPink.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.vibrantPurple.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DIFFICULTY LEVELS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inkLight,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _diffRow('Easy', '5×5 grid, 5–6 checkpoints',
                        AppTheme.neonGreen),
                    _diffRow('Medium', '6×6 grid, 7–9 checkpoints',
                        AppTheme.warmOrange),
                    _diffRow('Hard', '7×7 grid, 10–12 checkpoints',
                        AppTheme.neonPink),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vibrantPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'GOT IT!',
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

  Widget _rule(IconData icon, String title, String body, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.inkLight.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diffRow(String level, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            level,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.inkLight.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

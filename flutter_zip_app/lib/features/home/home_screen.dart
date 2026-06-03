import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulsing glow animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Floating animation
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: Stack(
        children: [
          // Animated background particles
          ..._buildBackgroundParticles(),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Header with logo and settings
                  _buildHeader(context),
                  
                  const SizedBox(height: 60),
                  
                  // Hero title with gradient
                  _buildHeroTitle(),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  Text(
                    'Connect the checkpoints. Fill the grid.\nChallenge your mind.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.inkLight.withValues(alpha: 0.8),
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // App icon/logo
                  Center(
                    child: Container(
                      width: 300,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Main play button with animation
                  _buildPlayButton(),
                  
                  const SizedBox(height: 50),
                  
                  // Stats cards
                  _buildStatsCards(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo with gradient
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.neonGradient.createShader(bounds),
          child: const Text(
            'PATH PUZZLE',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ),
        
        // Settings button with glow
        GestureDetector(
          onTap: () => context.push(AppRoutes.settings),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.vibrantPurple.withValues(alpha: 0.3),
                  AppTheme.neonPink.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.vibrantPurple.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.settings_rounded,
              size: 24,
              color: AppTheme.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.neonGradient.createShader(bounds),
          child: const Text(
            'Challenge',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
              height: 1.1,
            ),
          ),
        ),
        const Text(
          'Your Mind',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: AppTheme.ink,
            letterSpacing: -2,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _floatAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.practice),
            child: Container(
              width: double.infinity,
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: AppTheme.neonGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.vibrantPurple.withValues(alpha: 0.1 * _pulseAnimation.value),
                    blurRadius: 30 * _pulseAnimation.value,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'START PLAYING',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Endless Fun Awaits',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatInfo(
          icon: Icons.grid_4x4_rounded,
          label: 'DIFFICULTY',
          value: 'EASY→HARD',
          color: AppTheme.electricBlue,
        ),
        const SizedBox(width: 48),
        _buildStatInfo(
          icon: Icons.emoji_events_rounded,
          label: 'CHALLENGE',
          value: 'YOURSELF',
          color: AppTheme.neonGreen,
        ),
      ],
    );
  }

  Widget _buildStatInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkLight.withValues(alpha: 0.6),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink.withValues(alpha: 0.85),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBackgroundParticles() {
    return List.generate(6, (index) {
      final random = math.Random(index);
      final size = 100.0 + random.nextDouble() * 150;
      final top = random.nextDouble() * 800;
      final left = random.nextDouble() * 400 - 50;
      
      return Positioned(
        top: top,
        left: left,
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_floatController.value * 2 * math.pi + index) * 20,
                math.cos(_floatController.value * 2 * math.pi + index) * 30,
              ),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      index % 2 == 0
                          ? AppTheme.vibrantPurple.withValues(alpha: 0.1)
                          : AppTheme.neonPink.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

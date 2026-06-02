import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final username = auth.user?.username ?? 'Player';

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.canvas,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'ZIP',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                  letterSpacing: -1.2,
                ),
              ),
              TextSpan(
                text: '.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accent,
                  letterSpacing: -1.2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.profile),
            child: Container(
              margin: const EdgeInsets.only(right: 18),
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppTheme.ink,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  username[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Greeting
              Text(
                'Hello, $username.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ready to play?',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.inkLight,
                ),
              ),
              const SizedBox(height: 32),

              // Hero card — Tournament
              _HeroCard(
                label: 'TOURNAMENT',
                title: 'Weekly\nCompetition',
                description: 'Compete globally. New puzzles every Monday.',
                accentColor: AppTheme.accent,
                onTap: () => context.push(AppRoutes.tournament),
              ),
              const SizedBox(height: 14),

              // Secondary cards — two in a row
              Row(
                children: [
                  Expanded(
                    child: _SecondaryCard(
                      label: 'PRACTICE',
                      title: 'Unlimited\nPuzzles',
                      onTap: () => context.push(AppRoutes.practice),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SecondaryCard(
                      label: 'RANKINGS',
                      title: 'Leader-\nboard',
                      onTap: () => context.push(AppRoutes.leaderboard),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String label;
  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  const _HeroCard({
    required this.label,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.ink,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.2,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.55),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Play now',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryCard extends StatelessWidget {
  final String label;
  final String title;
  final VoidCallback onTap;

  const _SecondaryCard({
    required this.label,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkLight,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
                letterSpacing: -0.6,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.canvas,
                border: Border.all(color: AppTheme.border, width: 1.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, size: 13, color: AppTheme.ink),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );
    _ctrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1600)),
      _tryLoadUser().timeout(
        const Duration(seconds: 3),
        onTimeout: () => debugPrint('Auth timed out'),
      ),
    ]);
    if (!mounted) return;
    final auth = ref.read(authProvider);
    context.go(auth.isAuthenticated ? AppRoutes.home : AppRoutes.login);
  }

  Future<void> _tryLoadUser() async {
    try {
      await ref.read(authProvider.notifier).loadUser();
    } catch (e) {
      debugPrint('Auth check failed: $e');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wordmark
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'ZIP',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 72,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                          letterSpacing: -4,
                          height: 1.0,
                        ),
                      ),
                      TextSpan(
                        text: '.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 72,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accent,
                          letterSpacing: -4,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Competitive Logic Puzzles',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.inkLight,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

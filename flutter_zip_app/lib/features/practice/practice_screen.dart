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

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  int _sessionCount = 0;
  bool _isGenerating = false;

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
      appBar: AppBar(
        backgroundColor: AppTheme.canvas,
        title: const Text('Practice'),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _showHowToPlay,
            child: const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Text(
                'How to play',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.inkLight,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Title block
            const Text(
              'Unlimited\nPuzzles',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
                letterSpacing: -1.5,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Each puzzle is uniquely generated.\nConnect all numbers and fill every cell.',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.inkLight,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 32),

            // Difficulty chips — plain text, no icons
            _difficultyRow(),
            const SizedBox(height: 40),

            // Session count — minimal
            if (_sessionCount > 0) ...[
              Text(
                '$_sessionCount ${_sessionCount == 1 ? 'puzzle' : 'puzzles'} played this session',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.inkLight,
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Spacer(),

            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _startPuzzle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  disabledBackgroundColor: AppTheme.accent.withOpacity(0.5),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'New puzzle',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _difficultyRow() {
    const items = [
      ('Easy', '5×5'),
      ('Medium', '6×6'),
      ('Hard', '7×7'),
    ];
    return Row(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.$2,
                  style: const TextStyle(fontSize: 11, color: AppTheme.inkLight),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showHowToPlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => const _HowToPlaySheet(),
    );
  }
}

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 28, top: 8),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'How to play ZIP',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 28),
            _rule('The goal', 'Draw a single continuous path that visits every cell exactly once.'),
            _rule('Checkpoints', 'Numbered cells must be visited in order — 1, 2, 3…'),
            _rule('Drawing', 'Tap and drag across cells to draw your path.'),
            _rule('Rules', 'Start at 1. Visit every cell once. End at the last checkpoint.'),
            _rule('Hints', 'Tap the lightbulb during play to reveal the next correct step.'),
            const SizedBox(height: 28),
            // Difficulty table
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.canvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Difficulty levels',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 14),
                  _diffRow('Easy', '5×5 grid, 5–6 checkpoints'),
                  _diffRow('Medium', '6×6 grid, 7–9 checkpoints'),
                  _diffRow('Hard', '7×7 grid, 10–12 checkpoints'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Got it', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rule(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.canvas,
              border: Border.all(color: AppTheme.border, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(fontSize: 13, color: AppTheme.inkLight, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diffRow(String level, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(level, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.ink)),
          ),
          Text(desc, style: const TextStyle(fontSize: 13, color: AppTheme.inkLight)),
        ],
      ),
    );
  }
}

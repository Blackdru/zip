import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../providers/tournament_provider.dart';
import '../../models/tournament.dart';
import '../../models/puzzle.dart';

class TournamentScreen extends ConsumerStatefulWidget {
  const TournamentScreen({super.key});

  @override
  ConsumerState<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends ConsumerState<TournamentScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(tournamentProvider.notifier).loadCurrentTournament(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ts = ref.watch(tournamentProvider);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.canvas,
        title: const Text('Tournament'),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        actions: [
          if (ts.tournament != null)
            GestureDetector(
              onTap: () => context.push(
                '${AppRoutes.leaderboard}?tournamentId=${ts.tournament!.id}',
              ),
              child: const Padding(
                padding: EdgeInsets.only(right: 20),
                child: Text(
                  'Leaderboard',
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
      body: ts.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ts.error != null
              ? _buildError(ts.error!)
              : ts.tournament == null
                  ? _buildEmpty()
                  : _buildContent(ts.tournament!),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.inkLight),),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref
                  .read(tournamentProvider.notifier)
                  .loadCurrentTournament(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No active tournament',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back on Monday for the next week.',
            style: TextStyle(fontSize: 14, color: AppTheme.inkLight),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Tournament t) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(tournamentProvider.notifier).loadCurrentTournament(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Title
            Text(
              t.title ?? 'Week ${t.weekNumber}, ${t.year}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
                letterSpacing: -1.0,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            _statusPill(t),
            if (t.rewardDescription != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.3),),
                ),
                child: Text(
                  t.rewardDescription!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              'Puzzles',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.inkLight,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            ...t.puzzles.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _puzzleRow(e.value, e.key + 1),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(Tournament t) {
    final now = DateTime.now();
    final endsAt = DateTime.parse(t.endsAt);

    String text;
    Color bg;
    Color fg;

    switch (t.status) {
      case TournamentStatus.active:
        final diff = endsAt.difference(now);
        text = 'Ends in ${_fmtDuration(diff)}';
        bg = AppTheme.successGreen.withOpacity(0.1);
        fg = AppTheme.successGreen;
        break;
      case TournamentStatus.upcoming:
        text = 'Starts ${DateFormat('MMM d').format(DateTime.parse(t.startsAt))}';
        bg = AppTheme.warning.withOpacity(0.1);
        fg = AppTheme.warning;
        break;
      case TournamentStatus.frozen:
        text = 'Frozen — results pending';
        bg = AppTheme.border;
        fg = AppTheme.inkMid;
        break;
      case TournamentStatus.archived:
        text = 'Tournament ended';
        bg = AppTheme.border;
        fg = AppTheme.inkLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }

  Widget _puzzleRow(PuzzleData puzzle, int number) {
    return GestureDetector(
      onTap: () {
        if (puzzle.id != null) {
          context.push('${AppRoutes.puzzle}?id=${puzzle.id}&practice=false');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: Row(
          children: [
            // Number
            SizedBox(
              width: 40,
              child: Text(
                '$number',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puzzle $number',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${puzzle.gridSize}×${puzzle.gridSize}  ·  ${puzzle.difficulty.name[0].toUpperCase()}${puzzle.difficulty.name.substring(1)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.inkLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.inkFaint),
          ],
        ),
      ),
    );
  }

  String _fmtDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }
}

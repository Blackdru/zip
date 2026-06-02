import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String? tournamentId;

  const LeaderboardScreen({super.key, this.tournamentId});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.tournamentId != null) {
      Future.microtask(
        () => ref
            .read(leaderboardProvider.notifier)
            .loadLeaderboard(widget.tournamentId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: AppTheme.canvas,
        title: const Text('Leaderboard'),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        actions: [
          if (widget.tournamentId != null)
            GestureDetector(
              onTap: () => ref
                  .read(leaderboardProvider.notifier)
                  .loadLeaderboard(widget.tournamentId!),
              child: const Padding(
                padding: EdgeInsets.only(right: 20),
                child: Text(
                  'Refresh',
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
      body: widget.tournamentId == null
          ? _buildEmpty('No tournament selected')
          : state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? _buildError(state.error!)
                  : _buildLeaderboard(state),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Text(msg,
          style: const TextStyle(fontSize: 15, color: AppTheme.inkLight),),
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
                  .read(leaderboardProvider.notifier)
                  .loadLeaderboard(widget.tournamentId!),
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

  Widget _buildLeaderboard(LeaderboardState state) {
    return RefreshIndicator(
      onRefresh: () => ref
          .read(leaderboardProvider.notifier)
          .loadLeaderboard(widget.tournamentId!),
      child: Column(
        children: [
          if (state.myEntry != null) _buildMyRank(state.myEntry!),
          Expanded(
            child: state.entries.isEmpty
                ? _buildEmpty('No entries yet.\nBe the first to complete the tournament!')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: state.entries.length,
                    itemBuilder: (context, i) {
                      final entry = state.entries[i];
                      final isMe =
                          state.myEntry?.userId == entry.userId;
                      return _buildRow(entry, i + 1, isMe);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRank(dynamic me) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _rankLabel(me.rank, dark: false),
          const SizedBox(width: 14),
          _avatar(me.username, isMe: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your rank',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
                Text(
                  me.username,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtTime(me.totalTimeMs),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${me.puzzlesSolved} puzzles',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(dynamic entry, int rank, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.accentLight : AppTheme.surface,
        border: Border.all(
          color: isMe ? AppTheme.accent.withOpacity(0.4) : AppTheme.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _rankLabel(rank),
          const SizedBox(width: 14),
          _avatar(entry.username, isMe: isMe),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isMe ? AppTheme.accent : AppTheme.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${entry.puzzlesSolved} completed',
                  style: const TextStyle(fontSize: 12, color: AppTheme.inkLight),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtTime(entry.totalTimeMs),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              if (entry.completedAt != null)
                Text(
                  DateFormat('MMM d').format(DateTime.parse(entry.completedAt!)),
                  style: const TextStyle(fontSize: 11, color: AppTheme.inkLight),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rankLabel(int rank, {bool dark = true}) {
    // Top 3 get their rank number with accent colors, rest plain
    Color? rankColor;
    if (rank == 1) {
      rankColor = AppTheme.gold;
    } else if (rank == 2) rankColor = AppTheme.inkLight;
    else if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return SizedBox(
      width: 32,
      child: Text(
        rank <= 999 ? '#$rank' : '$rank',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: rank <= 3 ? 16 : 14,
          fontWeight: FontWeight.w800,
          color: rankColor ??
              (dark ? AppTheme.inkLight : Colors.white54),
        ),
      ),
    );
  }

  Widget _avatar(String username, {bool isMe = false}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isMe ? AppTheme.accent : AppTheme.canvas,
        border: Border.all(color: AppTheme.border, width: 1.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          username[0].toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isMe ? Colors.white : AppTheme.ink,
          ),
        ),
      ),
    );
  }

  String _fmtTime(int ms) {
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

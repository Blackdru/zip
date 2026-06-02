import { db } from '../../db/client';
import { createError } from '../../middleware/errorHandler';
import type { LeaderboardEntry } from '../../types';

export class LeaderboardService {
  /**
   * Fetch ranked leaderboard for a tournament.
   * Sorted by: total_time_ms ASC (lower = better), then completed_at ASC (tie-breaker)
   */
  static async getLeaderboard(
    tournamentId: string,
    limit = 100,
    offset = 0,
    userId?: string
  ): Promise<{
    entries: LeaderboardEntry[];
    myEntry?: LeaderboardEntry & { rank: number };
    total: number;
  }> {
    const { data, error, count } = await db.client
      .from('leaderboard_entries')
      .select(
        `id, tournament_id, user_id, total_time_ms, puzzles_solved, completed_at, is_disqualified,
         users!inner(username, avatar_url, country_code)`,
        { count: 'exact' }
      )
      .eq('tournament_id', tournamentId)
      .eq('is_disqualified', false)
      .order('total_time_ms', { ascending: true })
      .order('completed_at', { ascending: true, nullsFirst: false })
      .range(offset, offset + limit - 1);

    if (error) throw createError(error.message, 500, 'DB_ERROR');

    const entries: LeaderboardEntry[] = (data ?? []).map((row, idx) => ({
      id: row.id,
      tournamentId: row.tournament_id,
      userId: row.user_id,
      username: (row.users as unknown as Record<string, string>).username,
      avatarUrl: (row.users as unknown as Record<string, string>).avatar_url,
      countryCode: (row.users as unknown as Record<string, string>).country_code,
      totalTimeMs: row.total_time_ms,
      puzzlesSolved: row.puzzles_solved,
      completedAt: row.completed_at,
      rank: offset + idx + 1,
      isDisqualified: row.is_disqualified,
    }));

    // My rank (if userId provided)
    let myEntry: (LeaderboardEntry & { rank: number }) | undefined;
    if (userId) {
      const myIdx = entries.findIndex(e => e.userId === userId);
      if (myIdx >= 0) {
        myEntry = entries[myIdx] as LeaderboardEntry & { rank: number };
      } else {
        // Fetch my entry separately
        myEntry = await this.getMyRank(tournamentId, userId);
      }
    }

    return { entries, myEntry, total: count ?? 0 };
  }

  private static async getMyRank(
    tournamentId: string,
    userId: string
  ): Promise<(LeaderboardEntry & { rank: number }) | undefined> {
    const { data: myRow } = await db.client
      .from('leaderboard_entries')
      .select(`id, total_time_ms, puzzles_solved, completed_at, is_disqualified,
               users!inner(username, avatar_url, country_code)`)
      .eq('tournament_id', tournamentId)
      .eq('user_id', userId)
      .maybeSingle();

    if (!myRow) return undefined;

    // Count how many players have a better time
    const { count: betterCount } = await db.client
      .from('leaderboard_entries')
      .select('*', { count: 'exact', head: true })
      .eq('tournament_id', tournamentId)
      .eq('is_disqualified', false)
      .lt('total_time_ms', myRow.total_time_ms);

    const rank = (betterCount ?? 0) + 1;

    return {
      id: myRow.id,
      tournamentId,
      userId,
      username: (myRow.users as unknown as Record<string, string>).username,
      avatarUrl: (myRow.users as unknown as Record<string, string>).avatar_url,
      countryCode: (myRow.users as unknown as Record<string, string>).country_code,
      totalTimeMs: myRow.total_time_ms,
      puzzlesSolved: myRow.puzzles_solved,
      completedAt: myRow.completed_at,
      rank,
      isDisqualified: myRow.is_disqualified,
    };
  }

  /** Admin: disqualify a user from a tournament */
  static async disqualify(
    tournamentId: string,
    userId: string,
    reason: string
  ): Promise<void> {
    const { error } = await db.client
      .from('leaderboard_entries')
      .update({ is_disqualified: true, disqualify_reason: reason })
      .eq('tournament_id', tournamentId)
      .eq('user_id', userId);

    if (error) throw createError(error.message, 500, 'DB_ERROR');
  }
}

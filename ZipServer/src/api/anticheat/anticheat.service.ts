import { db } from '../../db/client';
import { createError } from '../../middleware/errorHandler';
import type { AntiCheatFlag, AntiCheatFlagType, AntiCheatSeverity } from '../../types';

export class AntiCheatService {
  /**
   * Check if a user has already submitted a valid solution for this puzzle
   */
  static async checkDuplicate(userId: string, puzzleId: string): Promise<boolean> {
    const { count } = await db.client
      .from('puzzle_attempts')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('puzzle_id', puzzleId)
      .eq('is_valid', true);

    return (count ?? 0) > 0;
  }

  /**
   * Store anti-cheat flags for admin review
   */
  static async storeFlags(
    userId: string,
    attemptId: string,
    flags: AntiCheatFlag[]
  ): Promise<void> {
    const inserts = flags.map(flag => ({
      user_id: userId,
      attempt_id: attemptId,
      flag_type: flag.flagType,
      severity: flag.severity,
      details: flag.details ? JSON.stringify(flag.details) : null,
    }));

    await db.client.from('anticheat_flags').insert(inserts);
  }

  /**
   * Full scan: check all recent attempts for suspicious patterns.
   * Called by cron job nightly.
   */
  static async runFullScan(): Promise<{ flagged: number; scanned: number }> {
    // Get recent unvalidated replays
    const { data: replays } = await db.client
      .from('replay_data')
      .select('id, attempt_id, move_sequence, total_moves, puzzle_attempts!inner(user_id, solve_time_ms, puzzle_id)')
      .eq('is_validated', false)
      .limit(500);

    if (!replays) return { flagged: 0, scanned: 0 };

    let flagged = 0;

    for (const replay of replays) {
      const attempt = (replay as unknown as Record<string, Record<string, unknown>>).puzzle_attempts;
      const newFlags: AntiCheatFlag[] = [];

      // Check impossible speed
      const solveTimeMs = attempt.solve_time_ms as number;
      if (solveTimeMs < 3000) {
        newFlags.push({
          flagType: 'impossible_speed',
          severity: 'critical',
          details: { solveTimeMs },
        });
      }

      // Check suspiciously low move count for puzzle size
      if (replay.total_moves < 5) {
        newFlags.push({
          flagType: 'replay_mismatch',
          severity: 'high',
          details: { totalMoves: replay.total_moves },
        });
      }

      if (newFlags.length > 0) {
        await this.storeFlags(
          attempt.user_id as string,
          replay.attempt_id,
          newFlags
        );
        flagged++;
      }

      // Mark as validated
      await db.client
        .from('replay_data')
        .update({ is_validated: true })
        .eq('id', replay.id);
    }

    return { flagged, scanned: replays.length };
  }

  /**
   * Get all flags for admin review
   */
  static async getFlags(
    reviewed?: boolean,
    severity?: AntiCheatSeverity,
    limit = 50
  ): Promise<unknown[]> {
    let query = db.client
      .from('anticheat_flags')
      .select(`*, users!inner(username, email)`)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (reviewed !== undefined) query = query.eq('reviewed', reviewed);
    if (severity) query = query.eq('severity', severity);

    const { data, error } = await query;
    if (error) throw createError(error.message, 500, 'DB_ERROR');
    return data ?? [];
  }

  /**
   * Admin: mark flag as reviewed, optionally ban user
   */
  static async reviewFlag(
    flagId: string,
    adminUserId: string,
    action: 'dismiss' | 'warn' | 'ban',
    banUserId?: string
  ): Promise<void> {
    await db.client
      .from('anticheat_flags')
      .update({
        reviewed: true,
        reviewed_by: adminUserId,
        action_taken: action,
      })
      .eq('id', flagId);

    if (action === 'ban' && banUserId) {
      await db.client
        .from('users')
        .update({ is_banned: true, ban_reason: 'Banned for cheating' })
        .eq('id', banUserId);
    }
  }
}

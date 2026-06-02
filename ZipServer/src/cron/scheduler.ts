import cron from 'node-cron';
import { db } from '../db/client';
import { TournamentService } from '../api/tournaments/tournaments.service';
import { AntiCheatService } from '../api/anticheat/anticheat.service';
import { config } from '../config';
import { logger } from '../utils/logger';

/**
 * Weekly tournament reset — every Monday 00:00 UTC.
 * 1. Archives previous tournament
 * 2. Creates and activates new tournament
 */
export function scheduleWeeklyReset(): void {
  cron.schedule(config.tournament.resetCron, async () => {
    logger.info('[CRON] Weekly tournament reset triggered');

    try {
      // Archive any active tournament
      const { data: active } = await db.client
        .from('tournaments')
        .select('id, week_number, year')
        .eq('status', 'active')
        .maybeSingle();

      if (active) {
        await db.client.from('tournaments').update({ status: 'archived' }).eq('id', active.id);

        // Snapshot top 10 for season history
        const { data: top10 } = await db.client
          .from('leaderboard_entries')
          .select('user_id, total_time_ms, completed_at, users!inner(username)')
          .eq('tournament_id', active.id)
          .eq('is_disqualified', false)
          .order('total_time_ms', { ascending: true })
          .limit(10);

        const winner = top10?.[0];

        await db.client.from('season_history').insert({
          tournament_id: active.id,
          winner_user_id: winner?.user_id ?? null,
          winner_username: winner ? (winner.users as unknown as Record<string, string>).username : null,
          winner_time_ms: winner?.total_time_ms ?? null,
          total_participants: top10?.length ?? 0,
          snapshot_leaderboard: JSON.stringify(top10),
        });

        logger.info(`[CRON] Tournament ${active.id} archived`);
      }

      // Calculate new week number
      const now = new Date();
      const year = now.getUTCFullYear();
      const weekNumber = getISOWeek(now);

      const startsAt = new Date(now);
      startsAt.setUTCHours(0, 0, 0, 0);

      const endsAt = new Date(startsAt);
      endsAt.setUTCDate(endsAt.getUTCDate() + 6);
      endsAt.setUTCHours(23, 59, 59, 999);

      await TournamentService.createTournament(weekNumber, year, startsAt, endsAt);
      await db.client
        .from('tournaments')
        .update({ status: 'active' })
        .eq('week_number', weekNumber)
        .eq('year', year);

      logger.info(`[CRON] New tournament created: Week ${weekNumber}, ${year}`);
    } catch (err) {
      logger.error('[CRON] Weekly reset failed', err);
    }
  });

  logger.info(`[CRON] Weekly reset scheduled: ${config.tournament.resetCron}`);
}

/**
 * Leaderboard freeze — every Sunday 23:59 UTC.
 */
export function scheduleLeaderboardFreeze(): void {
  cron.schedule(config.tournament.freezeCron, async () => {
    logger.info('[CRON] Leaderboard freeze triggered');

    try {
      await db.client
        .from('tournaments')
        .update({ status: 'frozen' })
        .eq('status', 'active');

      logger.info('[CRON] Active tournaments frozen');
    } catch (err) {
      logger.error('[CRON] Freeze failed', err);
    }
  });

  logger.info(`[CRON] Leaderboard freeze scheduled: ${config.tournament.freezeCron}`);
}

/**
 * Anti-cheat nightly scan.
 */
export function scheduleAntiCheatScan(): void {
  cron.schedule(config.antiCheat.scanCron, async () => {
    logger.info('[CRON] Anti-cheat scan triggered');

    try {
      const result = await AntiCheatService.runFullScan();
      logger.info(`[CRON] Anti-cheat scan complete: ${result.scanned} scanned, ${result.flagged} flagged`);
    } catch (err) {
      logger.error('[CRON] Anti-cheat scan failed', err);
    }
  });

  logger.info(`[CRON] Anti-cheat scan scheduled: ${config.antiCheat.scanCron}`);
}

/** ISO week number utility */
function getISOWeek(date: Date): number {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil(((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
}

export function startAllCronJobs(): void {
  scheduleWeeklyReset();
  scheduleLeaderboardFreeze();
  scheduleAntiCheatScan();
  logger.info('[CRON] All scheduled jobs registered');
}

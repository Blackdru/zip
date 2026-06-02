#!/usr/bin/env ts-node
/**
 * seedInitialPuzzles.ts
 *
 * One-shot seeding script to populate 5 puzzles for the current week's tournament.
 *
 * Behaviour:
 *   1. If an active/upcoming tournament already HAS puzzles → exits safely (no-op).
 *   2. If an active/upcoming tournament EXISTS but has 0 puzzles → generates the 5 puzzles.
 *   3. If NO tournament exists → creates a new one (week ends in 7 days), generates puzzles, activates it.
 *
 * Usage:
 *   npx ts-node src/scripts/seedInitialPuzzles.ts
 */

import 'dotenv/config';
import { db } from '../db/client';
import { TournamentService } from '../api/tournaments/tournaments.service';
import { logger } from '../utils/logger';

// ─── ISO week helper (same as scheduler.ts) ──────────────────────────────────

function getISOWeek(date: Date): number {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil(((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function seedInitialPuzzles(): Promise<void> {
  logger.info('=== Seed Initial Puzzles ===');

  const now = new Date();

  // ── Step 1: Find existing active or upcoming tournament ───────────────────
  const { data: existing, error: fetchErr } = await db.client
    .from('tournaments')
    .select('id, week_number, year, status, title')
    .in('status', ['active', 'upcoming'])
    .order('starts_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (fetchErr) {
    logger.error('Failed to query tournaments:', fetchErr);
    process.exit(1);
  }

  let tournamentId: string;
  let weekNumber: number;
  let year: number;

  if (existing) {
    tournamentId = existing.id;
    weekNumber   = existing.week_number;
    year         = existing.year;
    logger.info(`Found tournament: "${existing.title ?? 'Untitled'}" (Week ${weekNumber}/${year}) — status: ${existing.status}`);

    // ── Step 2: Check if puzzles already exist ──────────────────────────────
    const { count: puzzleCount, error: countErr } = await db.client
      .from('puzzles')
      .select('*', { count: 'exact', head: true })
      .eq('tournament_id', tournamentId)
      .eq('is_practice', false);

    if (countErr) {
      logger.error('Failed to count puzzles:', countErr);
      process.exit(1);
    }

    if ((puzzleCount ?? 0) > 0) {
      logger.info(`✅ Tournament already has ${puzzleCount} puzzle(s). Nothing to do!`);
      process.exit(0);
    }

    logger.info('Tournament has 0 puzzles — generating 5 now...');
  } else {
    // ── Step 3: No tournament found — create a brand new one ─────────────
    weekNumber = getISOWeek(now);
    year       = now.getUTCFullYear();

    const startsAt = new Date(now);
    startsAt.setUTCHours(0, 0, 0, 0);

    const endsAt = new Date(startsAt);
    endsAt.setUTCDate(endsAt.getUTCDate() + 6);
    endsAt.setUTCHours(23, 59, 59, 999);

    logger.info(`No active tournament found. Creating Week ${weekNumber}/${year}...`);
    logger.info(`  Starts: ${startsAt.toISOString()}`);
    logger.info(`  Ends:   ${endsAt.toISOString()}`);

    let created;
    try {
      created = await TournamentService.createTournament(
        weekNumber,
        year,
        startsAt,
        endsAt,
        'Weekly Tournament — Compete for glory!'
      );
    } catch (err: unknown) {
      // Handle duplicate week/year (tournament already created just without puzzles)
      if (err instanceof Error && err.message?.toLowerCase().includes('duplicate')) {
        logger.warn('Duplicate tournament detected — fetching existing record...');
        const { data: dup } = await db.client
          .from('tournaments')
          .select('id, week_number, year, status')
          .eq('week_number', weekNumber)
          .eq('year', year)
          .single();
        if (!dup) throw err;
        tournamentId = dup.id;
        weekNumber   = dup.week_number;
        year         = dup.year;
        logger.info(`Using existing tournament: ${tournamentId}`);
      } else {
        throw err;
      }
    }

    if (created) {
      tournamentId = created.id;
      // Activate it
      await TournamentService.setStatus(tournamentId, 'active');
      logger.info(`✅ Tournament created & activated: ${tournamentId}`);
    }
  }

  // ── Step 4: Generate the 5 puzzles ────────────────────────────────────────
  try {
    await TournamentService.generateWeeklyPuzzles(tournamentId!, weekNumber, year);
    logger.info('✅ 5 puzzles generated successfully!');
    logger.info('   Difficulty order: easy · medium · medium · hard · hard');
  } catch (err) {
    logger.error('❌ Failed to generate puzzles:', err);
    process.exit(1);
  }

  // ── Step 5: Confirm ───────────────────────────────────────────────────────
  const { data: puzzles } = await db.client
    .from('puzzles')
    .select('id, difficulty, order_index, seed')
    .eq('tournament_id', tournamentId!)
    .eq('is_practice', false)
    .order('order_index', { ascending: true });

  if (puzzles && puzzles.length > 0) {
    logger.info('\n📋 Puzzle summary:');
    for (const p of puzzles) {
      logger.info(`   #${p.order_index} [${p.difficulty.padEnd(6)}] id=${p.id}  seed=${p.seed}`);
    }
  }

  logger.info('\n🎮 Tournament is ready — players can compete now!');
  logger.info(`   Tournament ID: ${tournamentId!}`);
  process.exit(0);
}

seedInitialPuzzles().catch(err => {
  logger.error('Unhandled error:', err);
  process.exit(1);
});

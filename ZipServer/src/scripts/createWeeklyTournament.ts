#!/usr/bin/env ts-node
/**
 * Script to create a new weekly tournament
 * Usage: npx ts-node src/scripts/createWeeklyTournament.ts
 */

import 'dotenv/config';
import { TournamentService } from '../api/tournaments/tournaments.service';
import { logger } from '../utils/logger';

async function createWeeklyTournament() {
  try {
    // Get current week number and year
    const now = new Date();
    const year = now.getFullYear();
    
    // Calculate ISO week number
    const startOfYear = new Date(year, 0, 1);
    const days = Math.floor((now.getTime() - startOfYear.getTime()) / (24 * 60 * 60 * 1000));
    const weekNumber = Math.ceil((days + startOfYear.getDay() + 1) / 7);

    // Tournament runs for 7 days
    const startsAt = new Date();
    const endsAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    logger.info(`Creating tournament for Week ${weekNumber}, ${year}`);
    logger.info(`Start: ${startsAt.toISOString()}`);
    logger.info(`End: ${endsAt.toISOString()}`);

    const tournament = await TournamentService.createTournament(
      weekNumber,
      year,
      startsAt,
      endsAt,
      'Weekly Tournament Prize - Compete for glory!'
    );

    logger.info(`✅ Tournament created: ${tournament.id}`);
    logger.info(`   Week: ${tournament.weekNumber}`);
    logger.info(`   Status: ${tournament.status}`);

    // Activate tournament
    await TournamentService.setStatus(tournament.id, 'active');
    logger.info(`✅ Tournament activated!`);

    logger.info('\n🎮 Tournament is ready! Players can now compete.');
    logger.info(`   Tournament ID: ${tournament.id}`);
    logger.info(`   Puzzles: 5 (easy, medium, medium, hard, hard)`);
    
    process.exit(0);
  } catch (error) {
    logger.error('❌ Failed to create tournament:', error);
    process.exit(1);
  }
}

createWeeklyTournament();

import { v4 as uuidv4 } from 'uuid';
import { db } from '../../db/client';
import { PuzzleEngine } from '../../core/puzzleEngine';
import { PathValidator } from '../../core/pathValidator';
import { AntiCheatService } from '../anticheat/anticheat.service';
import { createError } from '../../middleware/errorHandler';
import type { GeneratedPuzzle, Move, Difficulty } from '../../types';

export class PuzzleService {
  // ─── Get Puzzle (client-safe — no solution) ────────────────────────────────

  static async getPuzzle(puzzleId: string): Promise<Omit<GeneratedPuzzle, 'solutionPath'>> {
    const { data: row, error } = await db.client
      .from('puzzles')
      .select('id, seed, grid_size, difficulty, clue_numbers, obstacles, walls')
      .eq('id', puzzleId)
      .single();

    if (error || !row) throw createError('Puzzle not found', 404, 'PUZZLE_NOT_FOUND');

    const clueNumbers = Array.isArray(row.clue_numbers)
      ? row.clue_numbers
      : JSON.parse(row.clue_numbers as string);

    const obstacles = row.obstacles
      ? (Array.isArray(row.obstacles) ? row.obstacles : JSON.parse(row.obstacles as string))
      : [];

    const walls = row.walls
      ? (Array.isArray(row.walls) ? row.walls : JSON.parse(row.walls as string))
      : [];

    return {
      seed: row.seed,
      gridSize: row.grid_size as number,
      difficulty: row.difficulty as Difficulty,
      clueNumbers,
      totalCheckpoints: clueNumbers.length,
      obstacles,
      walls,
    };
  }

  // ─── Submit Solution ───────────────────────────────────────────────────────

  static async submitSolution(
    userId: string,
    puzzleId: string,
    moveSequence: Move[],
    clientSolveTimeMs: number,
    serverStartedAt: Date
  ): Promise<{
    isValid: boolean;
    solveTimeMs: number;
    isPersonalBest: boolean;
    flags: unknown[];
  }> {
    // Load puzzle with solution
    const { data: row, error } = await db.client
      .from('puzzles')
      .select('seed, grid_size, difficulty, solution_path, clue_numbers, obstacles, tournament_id, is_practice')
      .eq('id', puzzleId)
      .single();

    if (error || !row) throw createError('Puzzle not found', 404, 'PUZZLE_NOT_FOUND');

    // Check if tournament is still active
    if (row.tournament_id) {
      const { data: tournament } = await db.client
        .from('tournaments')
        .select('status')
        .eq('id', row.tournament_id)
        .single();

      if (tournament?.status === 'frozen' || tournament?.status === 'archived') {
        throw createError('Tournament is no longer accepting submissions', 403, 'TOURNAMENT_CLOSED');
      }
    }

    // Server-recorded end time
    const serverEndedAt = new Date();
    const serverSolveTimeMs = serverEndedAt.getTime() - serverStartedAt.getTime();

    // Use server time (never trust client timers)
    const solveTimeMs = serverSolveTimeMs;

    // Supabase returns JSONB as already-parsed objects — only JSON.parse if it's a raw string
    const solutionPath = Array.isArray(row.solution_path)
      ? row.solution_path
      : JSON.parse(row.solution_path as string);
    const clueNumbers = Array.isArray(row.clue_numbers)
      ? row.clue_numbers
      : JSON.parse(row.clue_numbers as string);
    const obstacles = row.obstacles
      ? (Array.isArray(row.obstacles) ? row.obstacles : JSON.parse(row.obstacles as string))
      : [];

    // Validate path
    const validation = PathValidator.validate(
      moveSequence,
      solutionPath,
      clueNumbers,
      row.grid_size,
      solveTimeMs,
      obstacles
    );

    // Check for duplicate submission BEFORE recording attempt
    const isDuplicate = await AntiCheatService.checkDuplicate(userId, puzzleId);
    if (isDuplicate) {
      return {
        isValid: false,
        solveTimeMs,
        isPersonalBest: false,
        flags: [...validation.flags, {
          flagType: 'duplicate_submission' as const,
          severity: 'low' as const,
          details: {},
        }],
      };
    }

    // Save attempt
    const attemptId = uuidv4();
    await db.client.from('puzzle_attempts').insert({
      id: attemptId,
      user_id: userId,
      puzzle_id: puzzleId,
      solve_time_ms: solveTimeMs,
      is_valid: validation.isValid,
      anticheat_flags: validation.flags.length ? JSON.stringify(validation.flags) : null,
      server_started_at: serverStartedAt.toISOString(),
      server_ended_at: serverEndedAt.toISOString(),
    });

    // Save replay data
    await db.client.from('replay_data').insert({
      attempt_id: attemptId,
      move_sequence: JSON.stringify(moveSequence),
      total_moves: moveSequence.length,
      path_length: moveSequence.length,
      is_validated: validation.isValid,
    });

    // Store anti-cheat flags
    if (validation.flags.length > 0) {
      await AntiCheatService.storeFlags(userId, attemptId, validation.flags);
    }

    let isPersonalBest = false;

    if (validation.isValid) {
      // Check / update personal best
      isPersonalBest = await this.updatePersonalBest(userId, puzzleId, attemptId, solveTimeMs);

      // Update leaderboard entry if tournament puzzle
      if (row.tournament_id && !row.is_practice) {
        await this.updateLeaderboard(userId, row.tournament_id, puzzleId);
      }

      // Update user stats
      await this.updateUserStats(userId, solveTimeMs, row.is_practice);
    }

    return {
      isValid: validation.isValid,
      solveTimeMs,
      isPersonalBest,
      flags: validation.flags,
    };
  }

  // ─── Generate Practice Puzzle ─────────────────────────────────────────────

  static async getPracticePuzzle(
    difficulty: Difficulty,
    sequence: number
  ): Promise<Omit<GeneratedPuzzle, never>> {
    const seed = PuzzleEngine.practiceSeed(difficulty, sequence);
    const generated = PuzzleEngine.generate({ seed, difficulty, gridSize: 0 });

    return {
      seed: generated.seed,
      gridSize: generated.gridSize,
      difficulty: generated.difficulty,
      clueNumbers: generated.clueNumbers,
      totalCheckpoints: generated.totalCheckpoints,
      obstacles: generated.obstacles || [],
      walls: generated.walls || [],
      // Solution path is safe to expose for practice — enables reveal-next-step hints
      solutionPath: generated.solutionPath,
    };
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────

  private static async updatePersonalBest(
    userId: string,
    puzzleId: string,
    attemptId: string,
    solveTimeMs: number
  ): Promise<boolean> {
    const { data: existing } = await db.client
      .from('puzzle_attempts')
      .select('id, solve_time_ms')
      .eq('user_id', userId)
      .eq('puzzle_id', puzzleId)
      .eq('is_best', true)
      .maybeSingle();

    if (!existing || solveTimeMs < existing.solve_time_ms) {
      // Clear old best
      if (existing) {
        await db.client.from('puzzle_attempts').update({ is_best: false }).eq('id', existing.id);
      }
      // Set new best
      await db.client.from('puzzle_attempts').update({ is_best: true }).eq('id', attemptId);
      return true;
    }
    return false;
  }

  private static async updateLeaderboard(
    userId: string,
    tournamentId: string,
    puzzleId: string
  ): Promise<void> {
    // Sum of all best attempts for this tournament's puzzles
    const { data: puzzles } = await db.client
      .from('puzzles')
      .select('id')
      .eq('tournament_id', tournamentId)
      .eq('is_practice', false);

    if (!puzzles) return;
    const puzzleIds = puzzles.map(p => p.id);

    const { data: bestAttempts } = await db.client
      .from('puzzle_attempts')
      .select('solve_time_ms, puzzle_id')
      .eq('user_id', userId)
      .eq('is_best', true)
      .eq('is_valid', true)
      .in('puzzle_id', puzzleIds);

    if (!bestAttempts) return;

    const totalTimeMs = bestAttempts.reduce((sum, a) => sum + a.solve_time_ms, 0);
    const puzzlesSolved = bestAttempts.length;
    const allSolved = puzzlesSolved === puzzleIds.length;

    await db.client.from('leaderboard_entries').upsert(
      {
        tournament_id: tournamentId,
        user_id: userId,
        total_time_ms: totalTimeMs,
        puzzles_solved: puzzlesSolved,
        completed_at: allSolved ? new Date().toISOString() : null,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'tournament_id,user_id' }
    );
  }

  private static async updateUserStats(
    userId: string,
    solveTimeMs: number,
    isPractice: boolean
  ): Promise<void> {
    let { data: stats } = await db.client
      .from('user_stats')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (!stats) {
      const { data: newStats, error: insertErr } = await db.client
        .from('user_stats')
        .insert({
          user_id: userId,
          total_puzzles_solved: 0,
          practice_puzzles: 0,
          fastest_solve_ms: null,
          average_solve_ms: null,
          last_active_at: new Date().toISOString(),
        })
        .select('*')
        .single();

      if (insertErr || !newStats) return;
      stats = newStats;
    }

    const updates: Record<string, unknown> = {
      total_puzzles_solved: stats.total_puzzles_solved + 1,
      last_active_at: new Date().toISOString(),
    };

    if (isPractice) {
      updates.practice_puzzles = stats.practice_puzzles + 1;
    }

    if (!stats.fastest_solve_ms || solveTimeMs < stats.fastest_solve_ms) {
      updates.fastest_solve_ms = solveTimeMs;
    }

    // Recalculate average
    const totalSolved = stats.total_puzzles_solved + 1;
    const prevAvg = stats.average_solve_ms ?? solveTimeMs;
    updates.average_solve_ms = Math.round((prevAvg * (totalSolved - 1) + solveTimeMs) / totalSolved);

    await db.client.from('user_stats').update(updates).eq('user_id', userId);
  }
}

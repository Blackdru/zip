import { db } from '../../db/client';
import { PuzzleEngine } from '../../core/puzzleEngine';
import { createError } from '../../middleware/errorHandler';
import type { Tournament, GeneratedPuzzle, Difficulty, ClueNumber, SolutionStep } from '../../types';

export class TournamentService {
  // ─── Get Current Active Tournament ─────────────────────────────────────────

  static async getCurrentTournament(): Promise<Tournament & { puzzles: (Omit<GeneratedPuzzle, 'solutionPath'> & { id: string })[] }> {
    const { data: tournament, error } = await db.client
      .from('tournaments')
      .select('*')
      .eq('status', 'active')
      .order('starts_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) throw createError(error.message, 500, 'DB_ERROR');
    if (!tournament) throw createError('No active tournament', 404, 'NO_ACTIVE_TOURNAMENT');

    const { data: puzzleRows, error: puzzleErr } = await db.client
      .from('puzzles')
      .select('id, seed, grid_size, difficulty, clue_numbers, obstacles, walls, order_index')
      .eq('tournament_id', tournament.id)
      .eq('is_practice', false)
      .order('order_index', { ascending: true });

    if (puzzleErr) throw createError(puzzleErr.message, 500, 'DB_ERROR');

    // Build client-safe puzzle objects from stored data — NEVER re-run PuzzleEngine here.
    // solution_path is intentionally excluded; clue_numbers/gridSize come from DB.
    const puzzles = (puzzleRows ?? []).map(row => {
      const clueNumbers: ClueNumber[] = Array.isArray(row.clue_numbers)
        ? row.clue_numbers
        : JSON.parse(row.clue_numbers as string);

      const obstacles: SolutionStep[] = row.obstacles
        ? (Array.isArray(row.obstacles) ? row.obstacles : JSON.parse(row.obstacles as string))
        : [];

      const walls = row.walls
        ? (Array.isArray(row.walls) ? row.walls : JSON.parse(row.walls as string))
        : [];

      return {
        id: row.id,
        seed: row.seed,
        gridSize: row.grid_size as number,
        difficulty: row.difficulty as Difficulty,
        clueNumbers,
        totalCheckpoints: clueNumbers.length,
        obstacles,
        walls,
      };
    });

    return {
      id: tournament.id,
      weekNumber: tournament.week_number,
      year: tournament.year,
      title: tournament.title,
      status: tournament.status,
      startsAt: tournament.starts_at,
      endsAt: tournament.ends_at,
      freezeAt: tournament.freeze_at,
      rewardDescription: tournament.reward_description,
      puzzles,
    };
  }

  // ─── Create Tournament (Admin) ────────────────────────────────────────────

  static async createTournament(
    weekNumber: number,
    year: number,
    startsAt: Date,
    endsAt: Date,
    rewardDescription?: string
  ): Promise<Tournament> {
    const freezeAt = new Date(endsAt.getTime() - 60 * 1000); // 1 min before end

    const { data, error } = await db.client
      .from('tournaments')
      .insert({
        week_number: weekNumber,
        year,
        starts_at: startsAt.toISOString(),
        ends_at: endsAt.toISOString(),
        freeze_at: freezeAt.toISOString(),
        reward_description: rewardDescription,
        status: 'upcoming',
      })
      .select()
      .single();

    if (error) throw createError(error.message, 500, 'DB_ERROR');

    // Auto-generate weekly puzzles
    await this.generateWeeklyPuzzles(data.id, weekNumber, year);

    return {
      id: data.id,
      weekNumber: data.week_number,
      year: data.year,
      status: data.status,
      startsAt: data.starts_at,
      endsAt: data.ends_at,
      freezeAt: data.freeze_at,
      rewardDescription: data.reward_description,
    };
  }

  // ─── Generate Weekly Puzzles ──────────────────────────────────────────────

  static async generateWeeklyPuzzles(
    tournamentId: string,
    weekNumber: number,
    year: number
  ): Promise<void> {
    const difficulties: Difficulty[] = ['easy', 'medium', 'medium', 'hard', 'hard'];
    const puzzleInserts = [];

    for (let i = 0; i < difficulties.length; i++) {
      const difficulty = difficulties[i];
      // Use the same seed format and engine call as the practice endpoint —
      // this guarantees identical puzzle config (path, obstacles, walls, colors).
      const seed = PuzzleEngine.tournamentSeed(year, weekNumber, i + 1);
      const generated = PuzzleEngine.generate({ seed, difficulty, gridSize: 0 });

      puzzleInserts.push({
        tournament_id: tournamentId,
        seed,
        grid_size: generated.gridSize,
        difficulty,
        order_index: i + 1,
        solution_path: JSON.stringify(generated.solutionPath),
        clue_numbers: JSON.stringify(generated.clueNumbers),
        obstacles: JSON.stringify(generated.obstacles || []),
        walls: JSON.stringify(generated.walls || []),
        is_practice: false,
      });
    }

    const { error } = await db.client.from('puzzles').insert(puzzleInserts);
    if (error) throw createError(`Failed to generate puzzles: ${error.message}`, 500, 'PUZZLE_GEN_ERROR');
  }

  // ─── List All Tournaments ─────────────────────────────────────────────────

  static async listTournaments(limit = 20): Promise<Tournament[]> {
    const { data, error } = await db.client
      .from('tournaments')
      .select('*')
      .order('starts_at', { ascending: false })
      .limit(limit);

    if (error) throw createError(error.message, 500, 'DB_ERROR');

    return (data ?? []).map(row => ({
      id: row.id,
      weekNumber: row.week_number,
      year: row.year,
      title: row.title,
      status: row.status,
      startsAt: row.starts_at,
      endsAt: row.ends_at,
      freezeAt: row.freeze_at,
      rewardDescription: row.reward_description,
      winnerId: row.winner_user_id,
    }));
  }

  // ─── Activate / Freeze Tournament ────────────────────────────────────────

  static async setStatus(tournamentId: string, status: string): Promise<void> {
    const { error } = await db.client
      .from('tournaments')
      .update({ status })
      .eq('id', tournamentId);

    if (error) throw createError(error.message, 500, 'DB_ERROR');
  }
}

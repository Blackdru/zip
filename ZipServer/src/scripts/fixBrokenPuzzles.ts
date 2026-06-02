#!/usr/bin/env ts-node
/**
 * fixBrokenPuzzles.ts
 *
 * One-shot migration script to regenerate ALL existing tournament puzzles
 * that have isolated non-obstacle cells (dead-end cells left by the old
 * buggy DFS which had an iteration cap too low for full Hamiltonian coverage).
 *
 * What it does:
 *   1. Loads every puzzle from the DB.
 *   2. Validates each puzzle: checks that every non-obstacle cell is reachable
 *      from the start cell of the solution path (BFS connectivity check).
 *   3. If broken, regenerates the puzzle from its seed using the fixed engine.
 *   4. Updates the DB row with the corrected path, checkpoints, and obstacles.
 *
 * Usage:
 *   npx ts-node src/scripts/fixBrokenPuzzles.ts
 */

import 'dotenv/config';
import { db } from '../db/client';
import { PuzzleEngine } from '../core/puzzleEngine';
import { logger } from '../utils/logger';
import type { Difficulty } from '../../src/types';

// ─── Connectivity check ───────────────────────────────────────────────────────

/**
 * Returns the set of cells reachable from (startX, startY) on the grid,
 * excluding obstacle cells. Uses BFS.
 */
function reachableCells(
  startX: number,
  startY: number,
  gridSize: number,
  obstacleSet: Set<string>
): Set<string> {
  const key = (x: number, y: number) => `${x},${y}`;
  const visited = new Set<string>();
  const queue: Array<{ x: number; y: number }> = [{ x: startX, y: startY }];
  visited.add(key(startX, startY));

  while (queue.length > 0) {
    const { x, y } = queue.shift()!;
    for (const [dx, dy] of [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
      const nx = x + dx;
      const ny = y + dy;
      if (nx < 0 || nx >= gridSize || ny < 0 || ny >= gridSize) continue;
      const k = key(nx, ny);
      if (visited.has(k) || obstacleSet.has(k)) continue;
      visited.add(k);
      queue.push({ x: nx, y: ny });
    }
  }
  return visited;
}

/**
 * Returns true if the puzzle is valid:
 * - Every non-obstacle cell is reachable from the solution path start.
 * - The solution path itself covers every reachable non-obstacle cell.
 */
function isPuzzleValid(
  gridSize: number,
  solutionPath: Array<{ x: number; y: number }>,
  obstacles: Array<{ x: number; y: number }>
): boolean {
  if (solutionPath.length === 0) return false;

  const obstacleSet = new Set(obstacles.map(o => `${o.x},${o.y}`));
  const start = solutionPath[0];

  const reachable = reachableCells(start.x, start.y, gridSize, obstacleSet);
  const pathSet = new Set(solutionPath.map(s => `${s.x},${s.y}`));

  // Every reachable cell must be on the solution path
  for (const cell of reachable) {
    if (!pathSet.has(cell)) return false;
  }

  return true;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function fixBrokenPuzzles(): Promise<void> {
  logger.info('=== Fix Broken Puzzles (Hamiltonian Coverage) ===\n');

  // Load all puzzles (tournament + practice)
  const { data: puzzles, error } = await db.client
    .from('puzzles')
    .select('id, seed, grid_size, difficulty, solution_path, clue_numbers, obstacles');

  if (error || !puzzles) {
    logger.error('Failed to load puzzles:', error);
    process.exit(1);
  }

  logger.info(`Loaded ${puzzles.length} puzzles. Checking validity...\n`);

  let broken = 0;
  let fixed = 0;
  let failed = 0;

  for (const row of puzzles) {
    const gridSize = row.grid_size as number;
    const difficulty = row.difficulty as Difficulty;
    const seed = row.seed as string;

    const solutionPath = Array.isArray(row.solution_path)
      ? row.solution_path
      : JSON.parse(row.solution_path as string ?? '[]');

    const obstacles = row.obstacles
      ? (Array.isArray(row.obstacles) ? row.obstacles : JSON.parse(row.obstacles as string))
      : [];

    const valid = isPuzzleValid(gridSize, solutionPath, obstacles);

    if (valid) {
      logger.info(`  ✅ Puzzle ${row.id} [${difficulty} ${gridSize}x${gridSize}] — OK`);
      continue;
    }

    broken++;
    logger.warn(`  ⚠️  Puzzle ${row.id} [${difficulty} ${gridSize}x${gridSize}] — BROKEN (isolated cells). Regenerating...`);

    // Regenerate using fixed engine
    try {
      const generated = PuzzleEngine.generate(
        { seed, difficulty, gridSize },
        500
      );

      // Update DB
      const { error: updateErr } = await db.client
        .from('puzzles')
        .update({
          solution_path: generated.solutionPath,
          clue_numbers: generated.clueNumbers,
          obstacles: generated.obstacles,
          walls: generated.walls,
        })
        .eq('id', row.id);

      if (updateErr) {
        logger.error(`     ❌ DB update failed for ${row.id}:`, updateErr);
        failed++;
      } else {
        logger.info(`     ✅ Regenerated: path=${generated.solutionPath.length} cells, obstacles=${generated.obstacles.length}, checkpoints=${generated.clueNumbers.length}`);
        fixed++;
      }
    } catch (genErr) {
      logger.error(`     ❌ Generation failed for ${row.id} (seed=${seed}):`, genErr);
      failed++;
    }
  }

  logger.info(`\n=== Summary ===`);
  logger.info(`  Total puzzles:  ${puzzles.length}`);
  logger.info(`  Already valid:  ${puzzles.length - broken}`);
  logger.info(`  Broken found:   ${broken}`);
  logger.info(`  Fixed:          ${fixed}`);
  logger.info(`  Failed:         ${failed}`);

  if (failed > 0) {
    logger.error('\n⚠️  Some puzzles could not be regenerated. Check seeds above.');
    process.exit(1);
  }

  logger.info('\n✅ All broken puzzles fixed!');
  process.exit(0);
}

fixBrokenPuzzles().catch(err => {
  logger.error('Unhandled error:', err);
  process.exit(1);
});

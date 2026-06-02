import { SeedRng } from './seedRng';
import type {
  GeneratedPuzzle,
  PuzzleConfig,
  SolutionStep,
  ClueNumber,
  Difficulty,
} from '../types';

// ─── Difficulty Parameters ────────────────────────────────────────────────────

interface DifficultyParams {
  gridSize: number;
  minCheckpoints: number;
  maxCheckpoints: number;
  minPathCoverage: number; // fraction of cells that must be in path
  obstacleCount: number; // number of obstacle cells
}

const DIFFICULTY_PARAMS: Record<Difficulty, DifficultyParams> = {
  easy: { gridSize: 5, minCheckpoints: 5, maxCheckpoints: 6, minPathCoverage: 1.0, obstacleCount: 2 },
  medium: { gridSize: 6, minCheckpoints: 6, maxCheckpoints: 10, minPathCoverage: 1.0, obstacleCount: 4 },
  hard: { gridSize: 7, minCheckpoints: 8, maxCheckpoints: 12, minPathCoverage: 1.0, obstacleCount: 6 },
};

// Direction vectors: up, down, left, right
const DIRECTIONS = [
  { dx: 0, dy: -1 },
  { dx: 0, dy: 1 },
  { dx: -1, dy: 0 },
  { dx: 1, dy: 0 },
];

// ─── Puzzle Generation Engine ─────────────────────────────────────────────────

export class PuzzleEngine {
  /**
   * Generates a fully valid puzzle from a seed + difficulty.
   * The same seed + difficulty always produces the same puzzle.
   *
   * STEP 1: Generate a random Hamiltonian-style path via randomized DFS
   * STEP 2: Place obstacles in cells NOT on the path
   * STEP 3: Strategically reveal checkpoint numbers
   * STEP 4: Validate solvability
   */
  static generate(config: PuzzleConfig, maxAttempts = 500): GeneratedPuzzle {
    const params = this.getDifficultyParams(config.difficulty, config.gridSize);

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      const attemptSeed = `${config.seed}:attempt:${attempt}`;
      const rng = SeedRng.fromString(attemptSeed);

      // Always aim for a complete Hamiltonian path (visits every cell).
      // The DFS will try to visit all cells; any truly isolated leftover cells
      // become obstacles, but we validate they are genuinely unreachable.
      const path = this.generatePath(params.gridSize, rng);
      if (!path) continue;

      const walls = this.generateWalls(path, params.gridSize, params.obstacleCount, rng);

      // Any cell not on the path must be genuinely unreachable from the path end.
      // If any leftover cell is reachable from the path endpoint, the path is incomplete
      // (player could visit it) — reject this attempt.
      const pathSet = new Set(path.map(s => `${s.x},${s.y}`));
      const leftoverCells: Array<{x: number; y: number}> = [];
      for (let x = 0; x < params.gridSize; x++) {
        for (let y = 0; y < params.gridSize; y++) {
          if (!pathSet.has(`${x},${y}`)) leftoverCells.push({ x, y });
        }
      }

      // Reject if any leftover cell is reachable from any path cell
      // (it would be an un-fillable dead end, not a true obstacle).
      if (leftoverCells.length > 0) {
        const hasReachableLeftover = leftoverCells.some(cell =>
          this.isCellReachableFromPath(cell, pathSet, params.gridSize)
        );
        if (hasReachableLeftover) continue; // path is not truly Hamiltonian for traversable region
      }

      const obstacles: Array<{x: number; y: number}> = leftoverCells;

      const checkpoints = this.selectCheckpoints(
        path,
        rng,
        params.minCheckpoints,
        params.maxCheckpoints
      );
      if (checkpoints.length < params.minCheckpoints) continue;

      if (!this.validateSolvability(path, checkpoints, params.gridSize)) continue;

      return {
        seed: config.seed,
        gridSize: params.gridSize,
        difficulty: config.difficulty,
        solutionPath: path,
        clueNumbers: checkpoints,
        totalCheckpoints: checkpoints.length,
        walls,
        obstacles,
      };
    }

    throw new Error(
      `PuzzleEngine: Failed to generate valid puzzle after ${maxAttempts} attempts. ` +
      `Seed: ${config.seed}, Difficulty: ${config.difficulty}`
    );
  }

  /**
   * Checks if a leftover (non-path) cell is adjacent to any path cell.
   * If it is, the player COULD reach it from the path, making it an
   * unreachable dead-end — not a valid obstacle.
   */
  private static isCellReachableFromPath(
    cell: { x: number; y: number },
    pathSet: Set<string>,
    gridSize: number
  ): boolean {
    // A leftover cell is −0reachable’ if any of its 4 neighbours is a path cell.
    // (If a neighbour is on the path, the player could potentially visit this cell
    // before the neighbour is visited — making it a true dead-end, not obstacle.)
    for (const { dx, dy } of DIRECTIONS) {
      const nx = cell.x + dx;
      const ny = cell.y + dy;
      if (nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize) {
        if (pathSet.has(`${nx},${ny}`)) return true;
      }
    }
    return false;
  }

  // ─── Step 1: Path Generation via Randomized DFS ──────────────────────────

  private static generatePath(
    gridSize: number,
    rng: SeedRng
  ): SolutionStep[] | null {
    const totalCells = gridSize * gridSize;

    const visited = new Set<string>();
    const path: SolutionStep[] = [];

    // Random start cell
    const startX = rng.nextInt(0, gridSize - 1);
    const startY = rng.nextInt(0, gridSize - 1);

    const key = (x: number, y: number) => `${x},${y}`;

    // Generous iteration limit — Hamiltonian path DFS on large grids needs room to backtrack.
    // gridSize² × 10000 gives 8×8 grid ~6.4M iterations — enough to find a solution.
    let iterations = 0;
    const maxIterations = totalCells * 10000;

    const dfs = (x: number, y: number): boolean => {
      iterations++;
      if (iterations > maxIterations) return false;

      visited.add(key(x, y));
      path.push({ x, y });

      // SUCCESS: visited every cell (true Hamiltonian path)
      if (path.length === totalCells) return true;

      // Warnsdorff's heuristic: prefer neighbors with fewest onward moves.
      // This dramatically cuts backtracking for Hamiltonian path finding.
      // Small RNG noise on ties preserves seed-based variety.
      const neighbors: Array<{ dx: number; dy: number; degree: number }> = [];
      for (const { dx, dy } of DIRECTIONS) {
        const nx = x + dx;
        const ny = y + dy;
        if (
          nx >= 0 && nx < gridSize &&
          ny >= 0 && ny < gridSize &&
          !visited.has(key(nx, ny))
        ) {
          // Count unvisited neighbors of (nx, ny)
          let degree = 0;
          for (const { dx: dx2, dy: dy2 } of DIRECTIONS) {
            const nnx = nx + dx2;
            const nny = ny + dy2;
            if (
              nnx >= 0 && nnx < gridSize &&
              nny >= 0 && nny < gridSize &&
              !visited.has(key(nnx, nny))
            ) degree++;
          }
          neighbors.push({ dx, dy, degree });
        }
      }

      // Sort by degree ascending (Warnsdorff) + tiny RNG noise for variety
      neighbors.sort((a, b) => (a.degree + rng.next() * 0.3) - (b.degree + rng.next() * 0.3));

      for (const { dx, dy } of neighbors) {
        if (dfs(x + dx, y + dy)) return true;
      }

      // Backtrack
      visited.delete(key(x, y));
      path.pop();
      return false;
    };

    const success = dfs(startX, startY);
    return success ? path : null;
  }

  // ─── Step 2: Generate Walls ──────────────────────────────────────────────

  private static generateWalls(
    path: SolutionStep[],
    gridSize: number,
    wallCount: number,
    rng: SeedRng
  ): { x: number; y: number; length: number; isVertical: boolean }[] {
    const walls: { x: number; y: number; length: number; isVertical: boolean }[] = [];
    const pathSet = new Set(path.map(s => `${s.x},${s.y}`));

    for (let i = 0; i < wallCount * 3 && walls.length < wallCount; i++) {
      const isVertical = rng.nextInt(0, 1) === 1;

      if (isVertical) {
        const x = rng.nextInt(0, gridSize - 1);
        const startY = rng.nextInt(0, gridSize - 3);
        const length = rng.nextInt(2, Math.min(4, gridSize - startY));

        let blocksPath = false;
        for (let y = startY; y < startY + length; y++) {
          if (pathSet.has(`${x},${y}`) && pathSet.has(`${x + 1},${y}`)) {
            blocksPath = true;
            break;
          }
        }

        if (!blocksPath) {
          walls.push({ x, y: startY, length, isVertical: true });
        }
      } else {
        const y = rng.nextInt(0, gridSize - 1);
        const startX = rng.nextInt(0, gridSize - 3);
        const length = rng.nextInt(2, Math.min(4, gridSize - startX));

        let blocksPath = false;
        for (let x = startX; x < startX + length; x++) {
          if (pathSet.has(`${x},${y}`) && pathSet.has(`${x},${y + 1}`)) {
            blocksPath = true;
            break;
          }
        }

        if (!blocksPath) {
          walls.push({ x: startX, y, length, isVertical: false });
        }
      }
    }

    return walls;
  }

  // ─── Step 3: Checkpoint Number Reveal ────────────────────────────────────

  private static selectCheckpoints(
    path: SolutionStep[],
    rng: SeedRng,
    minCount: number,
    maxCount: number
  ): ClueNumber[] {
    const pathLen = path.length;
    const targetCount = rng.nextInt(minCount, Math.min(maxCount, pathLen - 1));

    // Always include start (index 0) and end (last index)
    const forcedIndices = new Set<number>([0, pathLen - 1]);

    // Sample intermediate checkpoints
    const intermediateIndices: number[] = [];
    for (let i = 1; i < pathLen - 1; i++) {
      intermediateIndices.push(i);
    }
    rng.shuffle(intermediateIndices);

    // Select evenly-spaced checkpoints to avoid clustering
    const step = Math.floor(intermediateIndices.length / (targetCount - 2 + 1));
    for (let i = 0; i < targetCount - 2 && i * step < intermediateIndices.length; i++) {
      forcedIndices.add(intermediateIndices[i * step]);
    }

    // Build ordered checkpoint list
    const sortedIndices = Array.from(forcedIndices).sort((a, b) => a - b);

    return sortedIndices.map((pathIdx, seqNum) => ({
      x: path[pathIdx].x,
      y: path[pathIdx].y,
      num: seqNum + 1,
    }));
  }

  // ─── Step 4: Solvability Validation ──────────────────────────────────────

  /**
   * Validates that given the revealed checkpoints, the puzzle is:
   * - Logically solvable (path connecting all checkpoints exists)
   * - Not trivially easy (path is non-obvious)
   * - Not degenerate (checkpoints aren't too clustered)
   */
  private static validateSolvability(
    path: SolutionStep[],
    checkpoints: ClueNumber[],
    gridSize: number
  ): boolean {
    if (checkpoints.length < 3) return false;

    // Check all checkpoints are on the actual solution path
    const pathSet = new Set(path.map(s => `${s.x},${s.y}`));
    for (const cp of checkpoints) {
      if (!pathSet.has(`${cp.x},${cp.y}`)) return false;
    }

    // Check no two consecutive checkpoints are adjacent (too easy)
    // This is soft — only reject if ALL pairs are trivially adjacent
    let adjacentPairs = 0;
    for (let i = 0; i < checkpoints.length - 1; i++) {
      const a = checkpoints[i];
      const b = checkpoints[i + 1];
      const dist = Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
      if (dist === 1) adjacentPairs++;
    }
    if (adjacentPairs === checkpoints.length - 1) return false; // all trivially adjacent

    // Check spread: checkpoints should cover the grid reasonably
    const xSpan = Math.max(...checkpoints.map(c => c.x)) - Math.min(...checkpoints.map(c => c.x));
    const ySpan = Math.max(...checkpoints.map(c => c.y)) - Math.min(...checkpoints.map(c => c.y));
    if (xSpan < Math.floor(gridSize / 2) || ySpan < Math.floor(gridSize / 2)) return false;

    return true;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  private static getDifficultyParams(
    difficulty: Difficulty,
    overrideGridSize?: number
  ): DifficultyParams {
    const params = { ...DIFFICULTY_PARAMS[difficulty] };
    if (overrideGridSize) {
      params.gridSize = Math.max(5, Math.min(8, overrideGridSize));
    }
    return params;
  }

  /**
   * Generates the seed string for a weekly tournament puzzle.
   * Format: "zip:week:{year}:{weekNum}:puzzle:{index}"
   */
  static tournamentSeed(year: number, weekNumber: number, puzzleIndex: number): string {
    return `zip:week:${year}:${weekNumber}:puzzle:${puzzleIndex}`;
  }

  /**
   * Generates the seed string for a practice puzzle.
   * Format: "zip:practice:{difficulty}:{sequence}"
   */
  static practiceSeed(difficulty: Difficulty, sequence: number): string {
    return `zip:practice:${difficulty}:${sequence}`;
  }
}

import { SeedRng } from './seedRng';
import type {
  Difficulty,
} from '../types';

// ─── Connect Dots Types ────────────────────────────────────────────────────

export interface ColorDot {
  x: number;
  y: number;
  color: string; // e.g., 'red', 'blue', 'green', 'yellow', 'orange', 'purple'
  pairId: number; // unique ID for each pair (1, 2, 3, ...)
}

export interface ConnectDotsPuzzle {
  seed: string;
  gridSize: number;
  difficulty: Difficulty;
  colorDots: ColorDot[]; // all dots (pairs)
  totalPairs: number;
  solutionPaths: Map<number, Array<{ x: number; y: number }>>; // pairId -> path
}

// ─── Difficulty Parameters ────────────────────────────────────────────────────

interface DifficultyParams {
  gridSize: number;
  minPairs: number;
  maxPairs: number;
}

const DIFFICULTY_PARAMS: Record<Difficulty, DifficultyParams> = {
  easy: { gridSize: 6, minPairs: 3, maxPairs: 3 },
  medium: { gridSize: 7, minPairs: 4, maxPairs: 5 },
  hard: { gridSize: 8, minPairs: 6, maxPairs: 7 },
};

// Available colors for dots
const DOT_COLORS = ['red', 'blue', 'green', 'yellow', 'orange', 'purple', 'cyan', 'pink'];

// Direction vectors: up, down, left, right
const DIRECTIONS = [
  { dx: 0, dy: -1 },
  { dx: 0, dy: 1 },
  { dx: -1, dy: 0 },
  { dx: 1, dy: 0 },
];

// ─── Connect Dots Engine ──────────────────────────────────────────────────────

export class ConnectDotsEngine {
  /**
   * Generates a Connect Dots puzzle from a seed + difficulty.
   * The same seed + difficulty always produces the same puzzle.
   *
   * RULES:
   * 1. Grid contains pairs of colored dots
   * 2. Each pair must be connected by a non-overlapping orthogonal path
   * 3. All cells must be filled (no empty cells remain)
   * 4. Paths cannot cross or overlap
   *
   * GENERATION STRATEGY:
   * 1. Generate a valid tiling (space-filling paths) via backtracking
   * 2. Place endpoint dots at path terminals
   * 3. Validate solvability
   */
  static generate(seed: string, difficulty: Difficulty, maxAttempts = 500): ConnectDotsPuzzle {
    const params = this.getDifficultyParams(difficulty);

    // Try with different pair counts to increase success rate
    const pairCounts = [];
    for (let p = params.minPairs; p <= params.maxPairs; p++) {
      pairCounts.push(p);
    }
    // Add one less pair as fallback
    if (params.minPairs > 2) {
      pairCounts.push(params.minPairs - 1);
    }

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      const attemptSeed = `${seed}:attempt:${attempt}`;
      const rng = SeedRng.fromString(attemptSeed);

      // Cycle through different pair counts
      const pairCount = pairCounts[attempt % pairCounts.length];
      
      // Generate space-filling paths with improved algorithm
      const result = this.generateSpaceFillingPaths(params.gridSize, pairCount, rng);
      if (!result) continue;

      const { paths, dots } = result;

      // Validate: all cells must be covered
      const totalCells = params.gridSize * params.gridSize;
      const coveredCells = new Set<string>();
      paths.forEach((path) => {
        path.forEach((cell) => coveredCells.add(`${cell.x},${cell.y}`));
      });

      if (coveredCells.size !== totalCells) continue;

      // Validate solvability (no impossible configurations)
      if (!this.validateSolvability(paths, dots, params.gridSize)) continue;

      return {
        seed,
        gridSize: params.gridSize,
        difficulty,
        colorDots: dots,
        totalPairs: pairCount,
        solutionPaths: paths,
      };
    }

    // Last resort: try with minimum pairs and more aggressive settings
    for (let attempt = 0; attempt < 200; attempt++) {
      const attemptSeed = `${seed}:lastresort:${attempt}`;
      const rng = SeedRng.fromString(attemptSeed);
      const pairCount = Math.max(2, params.minPairs - 1);
      
      const result = this.generateSpaceFillingPaths(params.gridSize, pairCount, rng);
      if (!result) continue;

      const { paths, dots } = result;
      const totalCells = params.gridSize * params.gridSize;
      const coveredCells = new Set<string>();
      paths.forEach((path) => {
        path.forEach((cell) => coveredCells.add(`${cell.x},${cell.y}`));
      });

      if (coveredCells.size !== totalCells) continue;
      if (!this.validateSolvability(paths, dots, params.gridSize)) continue;

      return {
        seed,
        gridSize: params.gridSize,
        difficulty,
        colorDots: dots,
        totalPairs: pairCount,
        solutionPaths: paths,
      };
    }

    throw new Error(
      `ConnectDotsEngine: Failed to generate valid puzzle after ${maxAttempts} attempts. ` +
      `Seed: ${seed}, Difficulty: ${difficulty}`
    );
  }

  /**
   * Generates space-filling paths via backtracking.
   * Returns paths and their endpoint dots.
   *
   * Uses Warnsdorff's heuristic (prefer cells with fewer unvisited neighbors)
   * to dramatically reduce dead-ends, especially on larger grids (8×8).
   */
  private static generateSpaceFillingPaths(
    gridSize: number,
    pairCount: number,
    rng: SeedRng
  ): { paths: Map<number, Array<{ x: number; y: number }>>; dots: ColorDot[] } | null {
    const totalCells = gridSize * gridSize;
    const grid: number[][] = Array(gridSize).fill(0).map(() => Array(gridSize).fill(-1));
    const paths: Map<number, Array<{ x: number; y: number }>> = new Map();

    // Scale iteration budget with grid area — larger grids need exponentially more work
    const maxIterations = Math.max(200000, totalCells * totalCells * 800);

    const isValid = (x: number, y: number): boolean => {
      return x >= 0 && x < gridSize && y >= 0 && y < gridSize && grid[y][x] === -1;
    };

    const getUnvisitedNeighbors = (x: number, y: number): Array<{ x: number; y: number }> => {
      const neighbors: Array<{ x: number; y: number }> = [];
      for (const { dx, dy } of DIRECTIONS) {
        const nx = x + dx;
        const ny = y + dy;
        if (isValid(nx, ny)) {
          neighbors.push({ x: nx, y: ny });
        }
      }
      return neighbors;
    };

    /** Warnsdorff degree: count unvisited neighbors of a cell */
    const warnsdorffDegree = (x: number, y: number): number => {
      let count = 0;
      for (const { dx, dy } of DIRECTIONS) {
        if (isValid(x + dx, y + dy)) count++;
      }
      return count;
    };

    /**
     * Check that all empty cells remain reachable from each other
     * (i.e., no isolated pockets). Uses simple flood-fill.
     */
    const isConnected = (): boolean => {
      // Find first empty cell
      let startX = -1, startY = -1;
      let emptyCount = 0;
      outer:
      for (let y = 0; y < gridSize; y++) {
        for (let x = 0; x < gridSize; x++) {
          if (grid[y][x] === -1) {
            if (startX === -1) { startX = x; startY = y; }
            emptyCount++;
          }
        }
      }
      if (emptyCount <= 1) return true;

      // Flood fill
      const visited = new Set<string>();
      const queue: Array<{ x: number; y: number }> = [{ x: startX, y: startY }];
      visited.add(`${startX},${startY}`);
      while (queue.length > 0) {
        const { x, y } = queue.shift()!;
        for (const { dx, dy } of DIRECTIONS) {
          const nx = x + dx, ny = y + dy;
          const key = `${nx},${ny}`;
          if (isValid(nx, ny) && !visited.has(key)) {
            visited.add(key);
            queue.push({ x: nx, y: ny });
          }
        }
      }
      return visited.size === emptyCount;
    };

    let iteration = 0;

    const buildPath = (pairId: number, remainingCells: number): boolean => {
      iteration++;
      if (iteration > maxIterations) return false;

      // Find all empty cells
      const emptyCells: Array<{ x: number; y: number }> = [];
      for (let y = 0; y < gridSize; y++) {
        for (let x = 0; x < gridSize; x++) {
          if (grid[y][x] === -1) emptyCells.push({ x, y });
        }
      }

      if (emptyCells.length === 0) return true; // All filled

      // Choose starting position: prefer corners/edges (fewer neighbors)
      // to avoid creating unreachable pockets
      const cellsByDegree = emptyCells.map(cell => ({
        cell,
        degree: warnsdorffDegree(cell.x, cell.y),
      }));
      cellsByDegree.sort((a, b) => a.degree - b.degree);

      // Pick from the bottom 30% (fewest neighbors) with some randomness
      const pickCount = Math.max(1, Math.floor(cellsByDegree.length * 0.3));
      const start = cellsByDegree[rng.nextInt(0, pickCount - 1)].cell;

      // Determine path length
      const avgLength = Math.ceil(remainingCells / (pairCount - pairId + 1));
      let minLength = Math.max(3, Math.floor(avgLength * 0.5));
      let maxLength = Math.min(remainingCells, Math.ceil(avgLength * 1.6));
      
      // For last path, use all remaining cells
      if (pairId === pairCount) {
        minLength = remainingCells;
        maxLength = remainingCells;
      }
      
      const targetLength = rng.nextInt(minLength, maxLength);

      // Build path via DFS with backtracking and Warnsdorff's heuristic
      const path: Array<{ x: number; y: number }> = [];

      const dfs = (x: number, y: number, depth: number): boolean => {
        iteration++;
        if (iteration > maxIterations) return false;

        path.push({ x, y });
        grid[y][x] = pairId;

        // Stop when target length reached
        if (depth >= targetLength) {
          // For non-last paths, verify remaining empty cells are still connected
          if (pairId < pairCount && !isConnected()) {
            path.pop();
            grid[y][x] = -1;
            return false;
          }
          return true;
        }

        const neighbors = getUnvisitedNeighbors(x, y);

        // Warnsdorff's heuristic: sort by ascending degree (prefer cells with
        // fewer remaining exits). This dramatically reduces dead-ends.
        // Add small random tiebreaker for variety.
        neighbors.sort((a, b) => {
          const degA = warnsdorffDegree(a.x, a.y);
          const degB = warnsdorffDegree(b.x, b.y);
          if (degA !== degB) return degA - degB;
          return rng.nextInt(0, 1) === 0 ? -1 : 1; // random tiebreaker
        });

        for (const { x: nx, y: ny } of neighbors) {
          if (dfs(nx, ny, depth + 1)) return true;
        }

        // Backtrack
        path.pop();
        grid[y][x] = -1;
        return false;
      };

      if (!dfs(start.x, start.y, 1)) {
        // Failed to build path, reset
        path.forEach(({ x, y }) => { grid[y][x] = -1; });
        return false;
      }

      // Ensure path has at least 2 cells
      if (path.length < 2) {
        path.forEach(({ x, y }) => { grid[y][x] = -1; });
        return false;
      }

      paths.set(pairId, path);
      return true;
    };

    // Build all paths
    let currentCells = totalCells;
    for (let pairId = 1; pairId <= pairCount; pairId++) {
      let success = false;
      // More retries for later paths (they're more constrained)
      const retries = pairId === pairCount ? 80 : 50;
      for (let retry = 0; retry < retries; retry++) {
        if (buildPath(pairId, currentCells)) {
          const pathLength = paths.get(pairId)!.length;
          currentCells -= pathLength;
          success = true;
          break;
        }
        // Reset grid for retry
        for (let y = 0; y < gridSize; y++) {
          for (let x = 0; x < gridSize; x++) {
            if (grid[y][x] === pairId) grid[y][x] = -1;
          }
        }
      }
      if (!success) return null;
    }

    // Create dots from path endpoints
    const dots: ColorDot[] = [];
    let colorIdx = 0;
    paths.forEach((path, pairId) => {
      const color = DOT_COLORS[colorIdx % DOT_COLORS.length];
      colorIdx++;

      const start = path[0];
      const end = path[path.length - 1];

      dots.push({ x: start.x, y: start.y, color, pairId });
      dots.push({ x: end.x, y: end.y, color, pairId });
    });

    return { paths, dots };
  }

  /**
   * Validates that the puzzle is solvable and not degenerate.
   */
  private static validateSolvability(
    paths: Map<number, Array<{ x: number; y: number }>>,
    dots: ColorDot[],
    gridSize: number
  ): boolean {
    // Check all paths have length >= 2
    for (const path of paths.values()) {
      if (path.length < 2) return false;
    }

    // Check dots are not overlapping
    const dotSet = new Set<string>();
    for (const dot of dots) {
      const key = `${dot.x},${dot.y}`;
      if (dotSet.has(key)) return false;
      dotSet.add(key);
    }

    // Check paths don't create impossible bottlenecks
    // (Simple heuristic: ensure paths have some minimum spread)
    for (const path of paths.values()) {
      const xCoords = path.map((p) => p.x);
      const yCoords = path.map((p) => p.y);
      const xSpan = Math.max(...xCoords) - Math.min(...xCoords);
      const ySpan = Math.max(...yCoords) - Math.min(...yCoords);
      
      // At least some variation in direction
      if (xSpan === 0 && ySpan === 0) return false;
    }

    return true;
  }

  private static getDifficultyParams(difficulty: Difficulty): DifficultyParams {
    return { ...DIFFICULTY_PARAMS[difficulty] };
  }

  /**
   * Generates the seed string for a weekly tournament puzzle.
   */
  static tournamentSeed(year: number, weekNumber: number, puzzleIndex: number): string {
    return `connectdots:week:${year}:${weekNumber}:puzzle:${puzzleIndex}`;
  }

  /**
   * Generates the seed string for a practice puzzle.
   */
  static practiceSeed(difficulty: Difficulty, sequence: number): string {
    return `connectdots:practice:${difficulty}:${sequence}`;
  }

  /**
   * Generates a random seed for one-off puzzles.
   */
  static randomSeed(): string {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 1000000);
    return `connectdots:random:${timestamp}:${random}`;
  }
}

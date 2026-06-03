import type { ColorDot } from './connectDotsEngine';

// ─── Connect Dots Validation Types ────────────────────────────────────────────

export interface PathSegment {
  x: number;
  y: number;
  timestampMs?: number;
}

export interface PlayerPath {
  pairId: number;
  path: PathSegment[];
}

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
}

// ─── Connect Dots Path Validator ──────────────────────────────────────────────

export class ConnectDotsValidator {
  /**
   * Validates a player's submitted solution for Connect Dots puzzle.
   *
   * RULES:
   * 1. Each pair of dots must be connected by a path
   * 2. Paths must be continuous (orthogonal adjacency)
   * 3. Paths cannot overlap or cross
   * 4. All cells must be filled
   * 5. Each path connects exactly two dots of the same color
   */
  static validate(
    playerPaths: PlayerPath[],
    dots: ColorDot[],
    gridSize: number,
    solutionPaths: Map<number, Array<{ x: number; y: number }>>
  ): ValidationResult {
    const errors: string[] = [];
    const warnings: string[] = [];

    // Build dot pair map
    const dotPairs = new Map<number, ColorDot[]>();
    for (const dot of dots) {
      if (!dotPairs.has(dot.pairId)) {
        dotPairs.set(dot.pairId, []);
      }
      dotPairs.get(dot.pairId)!.push(dot);
    }

    // Validate each pair has exactly 2 dots
    for (const [pairId, pairDots] of dotPairs.entries()) {
      if (pairDots.length !== 2) {
        errors.push(`Pair ${pairId} must have exactly 2 dots`);
        return { isValid: false, errors, warnings };
      }
    }

    // ── 1. Check all pairs are connected ─────────────────────────────────────
    const submittedPairIds = new Set(playerPaths.map((p) => p.pairId));
    for (const pairId of dotPairs.keys()) {
      if (!submittedPairIds.has(pairId)) {
        errors.push(`Missing path for pair ${pairId}`);
      }
    }

    if (errors.length > 0) {
      return { isValid: false, errors, warnings };
    }

    // ── 2. Validate each path ───────────────────────────────────────────────
    const globalVisited = new Set<string>();

    for (const playerPath of playerPaths) {
      const { pairId, path } = playerPath;

      if (!dotPairs.has(pairId)) {
        errors.push(`Unknown pair ID: ${pairId}`);
        continue;
      }

      const [dot1, dot2] = dotPairs.get(pairId)!;

      // Check path is not empty
      if (path.length === 0) {
        errors.push(`Path for pair ${pairId} is empty`);
        continue;
      }

      // Check path starts and ends at the correct dots
      const firstCell = path[0];
      const lastCell = path[path.length - 1];

      const startsAtDot1 =
        firstCell.x === dot1.x && firstCell.y === dot1.y;
      const startsAtDot2 =
        firstCell.x === dot2.x && firstCell.y === dot2.y;
      const endsAtDot1 =
        lastCell.x === dot1.x && lastCell.y === dot1.y;
      const endsAtDot2 =
        lastCell.x === dot2.x && lastCell.y === dot2.y;

      if (
        !(
          (startsAtDot1 && endsAtDot2) ||
          (startsAtDot2 && endsAtDot1)
        )
      ) {
        errors.push(
          `Path for pair ${pairId} must connect dots at (${dot1.x},${dot1.y}) and (${dot2.x},${dot2.y})`
        );
      }

      // Check path continuity (orthogonal adjacency)
      for (let i = 1; i < path.length; i++) {
        const prev = path[i - 1];
        const curr = path[i];
        const dist = Math.abs(prev.x - curr.x) + Math.abs(prev.y - curr.y);
        if (dist !== 1) {
          errors.push(
            `Path for pair ${pairId} is not continuous at step ${i}`
          );
          break;
        }
      }

      // Check path stays within bounds
      for (const cell of path) {
        if (
          cell.x < 0 ||
          cell.x >= gridSize ||
          cell.y < 0 ||
          cell.y >= gridSize
        ) {
          errors.push(
            `Path for pair ${pairId} goes out of bounds at (${cell.x},${cell.y})`
          );
          break;
        }
      }

      // Check for overlaps with other paths
      for (const cell of path) {
        const key = `${cell.x},${cell.y}`;
        if (globalVisited.has(key)) {
          errors.push(
            `Path for pair ${pairId} overlaps at (${cell.x},${cell.y})`
          );
          break;
        }
        globalVisited.add(key);
      }
    }

    if (errors.length > 0) {
      return { isValid: false, errors, warnings };
    }

    // ── 3. Check all cells are filled ────────────────────────────────────────
    const totalCells = gridSize * gridSize;
    if (globalVisited.size !== totalCells) {
      errors.push(
        `Not all cells filled. Covered: ${globalVisited.size}, Required: ${totalCells}`
      );
      return { isValid: false, errors, warnings };
    }

    // ── 4. Verify against solution (optional, for anti-cheat) ───────────────
    if (solutionPaths.size > 0) {
      for (const playerPath of playerPaths) {
        const { pairId, path } = playerPath;
        const solutionPath = solutionPaths.get(pairId);
        
        if (solutionPath && !this.pathsMatch(path, solutionPath)) {
          warnings.push(
            `Path for pair ${pairId} differs from expected solution`
          );
        }
      }
    }

    return { isValid: true, errors, warnings };
  }

  /**
   * Checks if two paths are equivalent (same cells, possibly reversed)
   */
  private static pathsMatch(
    path1: PathSegment[],
    path2: Array<{ x: number; y: number }>
  ): boolean {
    if (path1.length !== path2.length) return false;

    // Check forward direction
    const forwardMatch = path1.every(
      (cell, i) => cell.x === path2[i].x && cell.y === path2[i].y
    );

    // Check reverse direction
    const reverseMatch = path1.every(
      (cell, i) =>
        cell.x === path2[path2.length - 1 - i].x &&
        cell.y === path2[path2.length - 1 - i].y
    );

    return forwardMatch || reverseMatch;
  }

  /**
   * Checks if the solution timing is suspicious (anti-cheat)
   */
  static validateTiming(
    solveTimeMs: number,
    minTimeMs: number = 2000
  ): boolean {
    return solveTimeMs >= minTimeMs;
  }
}

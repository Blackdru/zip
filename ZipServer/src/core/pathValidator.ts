import type {
  SolutionStep,
  ClueNumber,
  Move,
  SubmissionValidationResult,
  AntiCheatFlag,
} from '../types';
import { config } from '../config';

// ─── Grid Path Validator ──────────────────────────────────────────────────────

export class PathValidator {
  /**
   * Server-side validation of a player-submitted path against the known solution.
   *
   * Checks:
   * 1. Path is continuous (each step is adjacent to the previous)
   * 2. Path covers all checkpoints in sequence order
   * 3. No cell is visited twice (no overlaps)
   * 4. Path follows valid grid bounds
   * 5. Path doesn't go through obstacles
   * 6. Solve time is within human-possible range (anti-cheat)
   */
  static validate(
    submittedPath: Move[],
    solution: SolutionStep[],
    checkpoints: ClueNumber[],
    gridSize: number,
    solveTimeMs: number,
    obstacles: SolutionStep[] = []
  ): SubmissionValidationResult {
    const flags: AntiCheatFlag[] = [];

    // ── 1. Impossible speed check ────────────────────────────────────────────
    if (solveTimeMs < config.antiCheat.minSolveTimeMs) {
      flags.push({
        flagType: 'impossible_speed',
        severity: 'critical',
        details: { solveTimeMs, minAllowed: config.antiCheat.minSolveTimeMs },
      });
      return { isValid: false, flags };
    }

    // ── 2. Basic path integrity ──────────────────────────────────────────────
    if (submittedPath.length === 0) {
      flags.push({ flagType: 'invalid_path', severity: 'medium', details: { reason: 'empty_path' } });
      return { isValid: false, flags };
    }

    // ── 3. Grid bounds check ─────────────────────────────────────────────────
    for (const move of submittedPath) {
      if (move.x < 0 || move.x >= gridSize || move.y < 0 || move.y >= gridSize) {
        flags.push({
          flagType: 'invalid_path',
          severity: 'high',
          details: { reason: 'out_of_bounds', move },
        });
        return { isValid: false, flags };
      }
    }

    // ── 4. Continuity check ──────────────────────────────────────────────────
    for (let i = 1; i < submittedPath.length; i++) {
      const prev = submittedPath[i - 1];
      const curr = submittedPath[i];
      const dist = Math.abs(prev.x - curr.x) + Math.abs(prev.y - curr.y);
      if (dist !== 1) {
        flags.push({
          flagType: 'invalid_path',
          severity: 'high',
          details: { reason: 'non_continuous', step: i, prev, curr },
        });
        return { isValid: false, flags };
      }
    }

    // Sort checkpoints by num to safely reference first and last
    const sortedCheckpoints = [...checkpoints].sort((a, b) => a.num - b.num);

    // ── 4.5. Rule 1: Path must START at checkpoint 1 ───────────────────────
    const firstCheckpoint = sortedCheckpoints[0];
    const firstMove = submittedPath[0];
    if (firstMove.x !== firstCheckpoint.x || firstMove.y !== firstCheckpoint.y) {
      flags.push({
        flagType: 'invalid_path',
        severity: 'high',
        details: {
          reason: 'path_does_not_start_at_checkpoint_1',
          firstMove,
          expected: { x: firstCheckpoint.x, y: firstCheckpoint.y },
        },
      });
      return { isValid: false, flags };
    }

    // ── 5. No overlaps ───────────────────────────────────────────────────────
    const visited = new Set<string>();
    for (const move of submittedPath) {
      const key = `${move.x},${move.y}`;
      if (visited.has(key)) {
        flags.push({
          flagType: 'invalid_path',
          severity: 'medium',
          details: { reason: 'overlap', move },
        });
        return { isValid: false, flags };
      }
      visited.add(key);
    }

    // ── 5.5. Obstacle collision check ───────────────────────────────────────
    if (obstacles.length > 0) {
      const obstacleSet = new Set(obstacles.map(o => `${o.x},${o.y}`));
      for (const move of submittedPath) {
        const key = `${move.x},${move.y}`;
        if (obstacleSet.has(key)) {
          flags.push({
            flagType: 'invalid_path',
            severity: 'high',
            details: { reason: 'obstacle_collision', move },
          });
          return { isValid: false, flags };
        }
      }
    }

    // ── 6. All checkpoints visited in sequence ───────────────────────────────
    const pathCells = submittedPath.map((m, idx) => ({ x: m.x, y: m.y, pathIdx: idx }));
    let cpIdx = 0;
    let lastCpPathIdx = -1;

    for (const cell of pathCells) {
      if (cpIdx < checkpoints.length) {
        const cp = checkpoints[cpIdx];
        if (cell.x === cp.x && cell.y === cp.y) {
          if (cell.pathIdx < lastCpPathIdx) {
            flags.push({
              flagType: 'invalid_path',
              severity: 'high',
              details: { reason: 'checkpoint_out_of_order', checkpoint: cp.num },
            });
            return { isValid: false, flags };
          }
          lastCpPathIdx = cell.pathIdx;
          cpIdx++;
        }
      }
    }

    if (cpIdx < checkpoints.length) {
      flags.push({
        flagType: 'invalid_path',
        severity: 'medium',
        details: { reason: 'missing_checkpoints', reached: cpIdx, total: checkpoints.length },
      });
      return { isValid: false, flags };
    }

    // ── 6.5. Rule 3: Full cell coverage ─────────────────────────────────────
    // The path must visit EVERY non-obstacle cell on the grid.
    const totalTraversable = gridSize * gridSize - obstacles.length;
    if (submittedPath.length !== totalTraversable) {
      flags.push({
        flagType: 'invalid_path',
        severity: 'high',
        details: {
          reason: 'incomplete_coverage',
          pathLength: submittedPath.length,
          required: totalTraversable,
        },
      });
      return { isValid: false, flags };
    }

    // ── 6.6. Rule 4: Path must END at checkpoint N ───────────────────────────
    const lastCheckpoint = sortedCheckpoints[sortedCheckpoints.length - 1];
    const lastMove = submittedPath[submittedPath.length - 1];
    if (lastMove.x !== lastCheckpoint.x || lastMove.y !== lastCheckpoint.y) {
      flags.push({
        flagType: 'invalid_path',
        severity: 'high',
        details: {
          reason: 'path_does_not_end_at_last_checkpoint',
          lastMove,
          expected: { x: lastCheckpoint.x, y: lastCheckpoint.y },
        },
      });
      return { isValid: false, flags };
    }

    // ── 7. Replay timestamp sanity check ────────────────────────────────────
    if (this.hasTimestampAnomalies(submittedPath)) {
      flags.push({
        flagType: 'replay_mismatch',
        severity: 'high',
        details: { reason: 'timestamp_anomaly' },
      });
      // Don't reject — flag for review but allow the submission
    }

    // ── 8. Solution match verification ──────────────────────────────────────
    if (!this.verifySolutionMatch(submittedPath, solution)) {
      flags.push({
        flagType: 'replay_mismatch',
        severity: 'medium',
        details: {
          reason: 'path_does_not_match_solution',
          submittedLength: submittedPath.length,
          solutionLength: solution.length,
        },
      });
    }

    return {
      isValid: true,
      flags,
      correctedTimeMs: solveTimeMs,
    };
  }

  /**
   * Checks if move timestamps have anomalies (e.g., backwards time, impossible speed)
   */
  private static hasTimestampAnomalies(moves: Move[]): boolean {
    for (let i = 1; i < moves.length; i++) {
      if (moves[i].timestampMs < moves[i - 1].timestampMs) return true;
      const delta = moves[i].timestampMs - moves[i - 1].timestampMs;
      if (delta > 30000) return true; // 30s gap between moves — suspicious
    }
    return false;
  }

  /**
   * Verifies that a submitted path matches the known solution path.
   * Used for replay verification.
   */
  static verifySolutionMatch(
    submittedPath: Move[],
    solution: SolutionStep[]
  ): boolean {
    if (submittedPath.length !== solution.length) return false;
    return submittedPath.every(
      (move, i) => move.x === solution[i].x && move.y === solution[i].y
    );
  }
}

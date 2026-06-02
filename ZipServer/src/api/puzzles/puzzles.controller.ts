import { Request, Response, NextFunction } from 'express';
import { PuzzleService } from './puzzles.service';
import type { Difficulty } from '../../types';

export class PuzzleController {
  static async getPuzzle(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await PuzzleService.getPuzzle(req.params.id);
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }

  static async submitSolution(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id: puzzleId } = req.params;
      const { moveSequence, clientSolveTimeMs, serverStartedAt } = req.body;

      if (!moveSequence || !Array.isArray(moveSequence)) {
        res.status(400).json({ success: false, error: 'moveSequence array is required' });
        return;
      }

      // Validate each move has valid x, y coordinates
      for (let i = 0; i < moveSequence.length; i++) {
        const m = moveSequence[i];
        if (
          typeof m.x !== 'number' || isNaN(m.x) ||
          typeof m.y !== 'number' || isNaN(m.y) ||
          !Number.isFinite(m.x) || !Number.isFinite(m.y)
        ) {
          res.status(400).json({
            success: false,
            error: `Invalid move at index ${i}: x and y must be finite numbers`,
          });
          return;
        }
      }

      // Validate serverStartedAt is a valid date if provided
      let parsedStartedAt: Date;
      if (serverStartedAt) {
        parsedStartedAt = new Date(serverStartedAt);
        if (isNaN(parsedStartedAt.getTime())) {
          res.status(400).json({
            success: false,
            error: 'serverStartedAt must be a valid ISO 8601 date string',
          });
          return;
        }
      } else {
        parsedStartedAt = new Date(Date.now() - (clientSolveTimeMs ?? 0));
      }

      // Use userId if authenticated, otherwise use a guest ID
      const userId = req.user?.userId ?? 'guest';

      const data = await PuzzleService.submitSolution(
        userId,
        puzzleId,
        moveSequence,
        clientSolveTimeMs ?? 0,
        parsedStartedAt
      );

      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }

  static async getPracticePuzzle(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const difficulty = (req.query.difficulty as Difficulty) ?? 'easy';
      const sequence = parseInt(req.query.sequence as string ?? '1', 10);

      if (!['easy', 'medium', 'hard'].includes(difficulty)) {
        res.status(400).json({ success: false, error: 'Invalid difficulty. Use easy|medium|hard' });
        return;
      }

      const data = await PuzzleService.getPracticePuzzle(difficulty, sequence);
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }
}

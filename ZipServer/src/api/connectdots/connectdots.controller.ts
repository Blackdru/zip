import { Request, Response, NextFunction } from 'express';
import { ConnectDotsService } from './connectdots.service';
import type { Difficulty } from '../../types';

export class ConnectDotsController {
  /**
   * GET /api/v1/connectdots/random
   * Get a random puzzle with random difficulty
   */
  static async getRandomPuzzle(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const puzzle = await ConnectDotsService.generateRandomPuzzle();

      res.json({
        success: true,
        data: puzzle,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/connectdots/practice
   * Get a practice puzzle with solution for hints
   * Now supports optional parameters - generates random if not provided
   */
  static async getPracticePuzzle(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { difficulty, sequence } = req.query;

      // If no parameters provided, generate random puzzle
      if (!difficulty && !sequence) {
        const puzzle = await ConnectDotsService.generateRandomPuzzle();
        res.json({
          success: true,
          data: puzzle,
        });
        return;
      }

      if (!difficulty || !sequence) {
        res.status(400).json({
          success: false,
          error: 'Missing required parameters: difficulty, sequence',
        });
        return;
      }

      const puzzleDifficulty = difficulty as Difficulty;
      const puzzleSequence = parseInt(sequence as string, 10);

      if (!['easy', 'medium', 'hard'].includes(puzzleDifficulty)) {
        res.status(400).json({
          success: false,
          error: 'Invalid difficulty. Must be: easy, medium, or hard',
        });
        return;
      }

      if (isNaN(puzzleSequence) || puzzleSequence < 1) {
        res.status(400).json({
          success: false,
          error: 'Invalid sequence number',
        });
        return;
      }

      const puzzle = await ConnectDotsService.generatePracticePuzzle(
        puzzleDifficulty,
        puzzleSequence
      );

      res.json({
        success: true,
        data: puzzle,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/connectdots/:puzzleId
   * Get a specific puzzle by ID
   */
  static async getPuzzle(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { puzzleId } = req.params;

      const puzzle = await ConnectDotsService.getPuzzle(puzzleId);

      res.json({
        success: true,
        data: puzzle,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/connectdots/:puzzleId/submit
   * Submit a solution for validation
   */
  static async submitSolution(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { puzzleId } = req.params;
      const { playerPaths, clientSolveTimeMs } = req.body;

      if (!playerPaths || !Array.isArray(playerPaths)) {
        res.status(400).json({
          success: false,
          error: 'Missing or invalid playerPaths',
        });
        return;
      }

      if (typeof clientSolveTimeMs !== 'number') {
        res.status(400).json({
          success: false,
          error: 'Missing or invalid clientSolveTimeMs',
        });
        return;
      }

      const result = await ConnectDotsService.submitSolution(puzzleId, {
        playerPaths,
        clientSolveTimeMs,
      });

      res.json({
        success: result.isValid,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/connectdots/tournament/:year/:week/:index
   * Get a tournament puzzle
   */
  static async getTournamentPuzzle(
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { year, week, index } = req.params;

      const puzzleYear = parseInt(year, 10);
      const weekNumber = parseInt(week, 10);
      const puzzleIndex = parseInt(index, 10);

      if (isNaN(puzzleYear) || isNaN(weekNumber) || isNaN(puzzleIndex)) {
        res.status(400).json({
          success: false,
          error: 'Invalid tournament parameters',
        });
        return;
      }

      const puzzle = await ConnectDotsService.generateTournamentPuzzle(
        puzzleYear,
        weekNumber,
        puzzleIndex,
        'medium' // Default difficulty
      );

      res.json({
        success: true,
        data: puzzle,
      });
    } catch (error) {
      next(error);
    }
  }
}

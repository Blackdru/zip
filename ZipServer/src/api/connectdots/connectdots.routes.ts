import { Router } from 'express';
import { ConnectDotsController } from './connectdots.controller';

const router = Router();

// GET /api/v1/connectdots/random - Get random puzzle with random difficulty
router.get('/random', ConnectDotsController.getRandomPuzzle);

// GET /api/v1/connectdots/practice - Get practice puzzle with solution
router.get('/practice', ConnectDotsController.getPracticePuzzle);

// GET /api/v1/connectdots/tournament/:year/:week/:index - Get tournament puzzle
router.get(
  '/tournament/:year/:week/:index',
  ConnectDotsController.getTournamentPuzzle
);

// GET /api/v1/connectdots/:puzzleId - Get specific puzzle
router.get('/:puzzleId', ConnectDotsController.getPuzzle);

// POST /api/v1/connectdots/:puzzleId/submit - Submit solution
router.post('/:puzzleId/submit', ConnectDotsController.submitSolution);

export default router;

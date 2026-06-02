import { Router } from 'express';
import { PuzzleController } from './puzzles.controller';
import { authMiddleware } from '../../middleware/auth.middleware';
import { submissionLimiter } from '../../middleware/rateLimit.middleware';

const router = Router();

// Remove auth middleware for now - allow public access to puzzles
router.get('/practice', PuzzleController.getPracticePuzzle);
router.get('/:id', PuzzleController.getPuzzle);
router.post('/:id/submit', submissionLimiter, PuzzleController.submitSolution);

export default router;

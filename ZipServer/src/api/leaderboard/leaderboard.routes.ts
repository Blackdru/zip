import { Router } from 'express';
import { LeaderboardController } from './leaderboard.controller';
import { authMiddleware, adminMiddleware } from '../../middleware/auth.middleware';

const router = Router();

router.get('/:tournamentId', authMiddleware, LeaderboardController.getLeaderboard);

// Admin only
router.post(
  '/:tournamentId/disqualify/:userId',
  authMiddleware,
  adminMiddleware,
  LeaderboardController.disqualify
);

export default router;

import { Router } from 'express';
import { StatsController } from './stats.controller';
import { authMiddleware } from '../../middleware/auth.middleware';

const router = Router();

router.get('/me', authMiddleware, StatsController.getMyStats);
router.get('/seasons', StatsController.getSeasonHistory);
router.get('/users/:userId', StatsController.getUserProfile);

export default router;

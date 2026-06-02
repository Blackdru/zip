import { Router } from 'express';
import { AntiCheatController } from './anticheat.controller';
import { authMiddleware, adminMiddleware } from '../../middleware/auth.middleware';

const router = Router();

// All admin-only
router.get('/flags', authMiddleware, adminMiddleware, AntiCheatController.getFlags);
router.patch('/flags/:flagId/review', authMiddleware, adminMiddleware, AntiCheatController.reviewFlag);
router.post('/scan', authMiddleware, adminMiddleware, AntiCheatController.runScan);

export default router;

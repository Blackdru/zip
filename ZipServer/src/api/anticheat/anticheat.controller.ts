import { Request, Response, NextFunction } from 'express';
import { AntiCheatService } from './anticheat.service';
import type { AntiCheatSeverity } from '../../types';

export class AntiCheatController {
  static async getFlags(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const reviewed = req.query.reviewed !== undefined
        ? req.query.reviewed === 'true'
        : undefined;
      const severity = req.query.severity as AntiCheatSeverity | undefined;
      const data = await AntiCheatService.getFlags(reviewed, severity);
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }

  static async reviewFlag(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { flagId } = req.params;
      const { action, banUserId } = req.body;
      await AntiCheatService.reviewFlag(flagId, req.user!.userId, action, banUserId);
      res.json({ success: true, data: { message: 'Flag reviewed' } });
    } catch (err) {
      next(err);
    }
  }

  static async runScan(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await AntiCheatService.runFullScan();
      res.json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }
}

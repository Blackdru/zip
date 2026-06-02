import { Request, Response, NextFunction } from 'express';
import { LeaderboardService } from './leaderboard.service';

export class LeaderboardController {
  static async getLeaderboard(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { tournamentId } = req.params;
      const limit = Math.min(parseInt(req.query.limit as string ?? '100', 10), 200);
      const offset = parseInt(req.query.offset as string ?? '0', 10);
      const userId = req.user?.userId;

      const data = await LeaderboardService.getLeaderboard(tournamentId, limit, offset, userId);
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }

  static async disqualify(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { tournamentId, userId } = req.params;
      const { reason } = req.body;
      await LeaderboardService.disqualify(tournamentId, userId, reason ?? 'Disqualified by admin');
      res.json({ success: true, data: { message: 'User disqualified' } });
    } catch (err) {
      next(err);
    }
  }
}

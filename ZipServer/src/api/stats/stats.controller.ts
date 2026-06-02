import { Request, Response, NextFunction } from 'express';
import { db } from '../../db/client';
import { createError } from '../../middleware/errorHandler';

export class StatsController {
  static async getMyStats(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { data, error } = await db.client
        .from('user_stats')
        .select('*')
        .eq('user_id', req.user!.userId)
        .single();

      if (error) throw createError(error.message, 500, 'DB_ERROR');
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }

  static async getUserProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { userId } = req.params;

      const { data: user, error: userError } = await db.client
        .from('users')
        .select('id, username, avatar_url, country_code, created_at')
        .eq('id', userId)
        .single();

      if (userError || !user) throw createError('User not found', 404, 'USER_NOT_FOUND');

      const { data: stats } = await db.client
        .from('user_stats')
        .select('*')
        .eq('user_id', userId)
        .single();

      res.json({ success: true, data: { user, stats } });
    } catch (err) {
      next(err);
    }
  }

  static async getSeasonHistory(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { data, error } = await db.client
        .from('season_history')
        .select('*, tournaments(week_number, year, title)')
        .order('archived_at', { ascending: false })
        .limit(20);

      if (error) throw createError(error.message, 500, 'DB_ERROR');
      res.json({ success: true, data: data ?? [] });
    } catch (err) {
      next(err);
    }
  }
}

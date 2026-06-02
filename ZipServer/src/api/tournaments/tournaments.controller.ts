import { Request, Response, NextFunction } from 'express';
import { TournamentService } from './tournaments.service';

export class TournamentController {
  static async getCurrent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await TournamentService.getCurrentTournament();
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }

  static async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await TournamentService.listTournaments();
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }

  static async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { weekNumber, year, startsAt, endsAt, rewardDescription } = req.body;
      const data = await TournamentService.createTournament(
        weekNumber,
        year,
        new Date(startsAt),
        new Date(endsAt),
        rewardDescription
      );
      res.status(201).json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }

  static async setStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { status } = req.body;
      await TournamentService.setStatus(id, status);
      res.json({ success: true, data: { message: 'Tournament status updated' } });
    } catch (err) {
      next(err);
    }
  }
}

import { Router } from 'express';
import { body } from 'express-validator';
import { TournamentController } from './tournaments.controller';
import { authMiddleware, adminMiddleware } from '../../middleware/auth.middleware';
import { validate } from '../../middleware/validate';

const router = Router();

router.get('/current', TournamentController.getCurrent);
router.get('/', authMiddleware, TournamentController.list);

const createValidation = [
  body('weekNumber')
    .isInt({ min: 1, max: 53 })
    .withMessage('weekNumber must be an integer between 1 and 53'),
  body('year')
    .isInt({ min: 2024 })
    .withMessage('year must be an integer >= 2024'),
  body('startsAt')
    .isISO8601()
    .withMessage('startsAt must be a valid ISO 8601 date'),
  body('endsAt')
    .isISO8601()
    .withMessage('endsAt must be a valid ISO 8601 date')
    .custom((value, { req }) => {
      if (new Date(value) <= new Date(req.body.startsAt)) {
        throw new Error('endsAt must be after startsAt');
      }
      return true;
    }),
  body('rewardDescription')
    .optional()
    .isString()
    .trim()
    .withMessage('rewardDescription must be a string'),
];

router.post('/', authMiddleware, adminMiddleware, createValidation, validate, TournamentController.create);
router.patch('/:id/status', authMiddleware, adminMiddleware, TournamentController.setStatus);

export default router;

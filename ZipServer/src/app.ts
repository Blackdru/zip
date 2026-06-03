import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import { config } from './config';
import { generalLimiter } from './middleware/rateLimit.middleware';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';

// Route imports
import authRoutes from './api/auth/auth.routes';
import tournamentRoutes from './api/tournaments/tournaments.routes';
import puzzleRoutes from './api/puzzles/puzzles.routes';
import leaderboardRoutes from './api/leaderboard/leaderboard.routes';
import statsRoutes from './api/stats/stats.routes';
import antiCheatRoutes from './api/anticheat/anticheat.routes';
import connectDotsRoutes from './api/connectdots/connectdots.routes';

const app = express();

// ─── Security ─────────────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) {
      callback(null, true);
      return;
    }
    
    // In development, allow all origins
    if (config.env === 'development') {
      callback(null, true);
      return;
    }
    
    // In production, check against allowed origins
    if (config.cors.allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('CORS: Not allowed'));
    }
  },
  credentials: true,
}));

// ─── Performance ──────────────────────────────────────────────────────────────
app.use(compression());
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));

// ─── Rate Limit (global) ───────────────────────────────────────────────────────
app.use('/api', generalLimiter);

// ─── Health Check ─────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ─── API Routes ────────────────────────────────────────────────────────────────
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/tournaments', tournamentRoutes);
app.use('/api/v1/puzzles', puzzleRoutes);
app.use('/api/v1/leaderboard', leaderboardRoutes);
app.use('/api/v1/stats', statsRoutes);
app.use('/api/v1/anticheat', antiCheatRoutes);
app.use('/api/v1/connectdots', connectDotsRoutes);

// ─── Error Handling ─────────────────────────────────────────────────────────
app.use(notFoundHandler);
app.use(errorHandler);

export default app;

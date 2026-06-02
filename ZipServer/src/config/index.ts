import dotenv from 'dotenv';
dotenv.config();

function requireEnv(key: string): string {
  const val = process.env[key];
  if (!val) throw new Error(`Missing required environment variable: ${key}`);
  return val;
}

export const config = {
  env: (process.env.NODE_ENV ?? 'development') as 'development' | 'production' | 'test',
  port: parseInt(process.env.PORT ?? '3000', 10),

  jwt: {
    secret: requireEnv('JWT_SECRET'),
    expiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  },

  supabase: {
    url: requireEnv('SUPABASE_URL'),
    anonKey: requireEnv('SUPABASE_ANON_KEY'),
    serviceRoleKey: requireEnv('SUPABASE_SERVICE_ROLE_KEY'),
  },

  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS ?? '900000', 10),
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS ?? '100', 10),
  },

  antiCheat: {
    minSolveTimeMs: parseInt(process.env.MIN_SOLVE_TIME_MS ?? '3000', 10),
    scanCron: process.env.ANTICHEAT_SCAN_CRON ?? '0 2 * * *',
  },

  tournament: {
    resetCron: process.env.TOURNAMENT_RESET_CRON ?? '0 0 * * 1',
    freezeCron: process.env.TOURNAMENT_FREEZE_CRON ?? '59 23 * * 0',
  },

  cors: {
    allowedOrigins: (process.env.ALLOWED_ORIGINS ?? 'http://localhost:3001')
      .split(',')
      .map(o => o.trim()),
  },
} as const;

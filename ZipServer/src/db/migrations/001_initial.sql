-- ============================================================================
-- ZIP Competitive Puzzle Platform — Database Schema
-- Migration: 001_initial
-- Target:    Supabase PostgreSQL
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- USERS
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  username         VARCHAR(30)  NOT NULL UNIQUE,
  email            VARCHAR(255) NOT NULL UNIQUE,
  password_hash    VARCHAR(255) NOT NULL,
  avatar_url       TEXT,
  country_code     CHAR(2),                          -- ISO 3166-1 alpha-2
  is_active        BOOLEAN      NOT NULL DEFAULT TRUE,
  is_admin         BOOLEAN      NOT NULL DEFAULT FALSE,
  is_banned        BOOLEAN      NOT NULL DEFAULT FALSE,
  ban_reason       TEXT,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  last_login_at    TIMESTAMPTZ
);

CREATE INDEX idx_users_email     ON users (email);
CREATE INDEX idx_users_username  ON users (username);
CREATE INDEX idx_users_is_banned ON users (is_banned);

-- ============================================================================
-- TOURNAMENTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS tournaments (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  week_number      INTEGER      NOT NULL,              -- ISO week number
  year             INTEGER      NOT NULL,
  title            VARCHAR(100),
  status           VARCHAR(20)  NOT NULL DEFAULT 'upcoming'
                   CHECK (status IN ('upcoming', 'active', 'frozen', 'archived')),
  starts_at        TIMESTAMPTZ  NOT NULL,
  ends_at          TIMESTAMPTZ  NOT NULL,
  freeze_at        TIMESTAMPTZ  NOT NULL,
  reward_description TEXT,
  winner_user_id   UUID         REFERENCES users(id) ON DELETE SET NULL,
  winner_notified  BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (week_number, year)
);

CREATE INDEX idx_tournaments_status    ON tournaments (status);
CREATE INDEX idx_tournaments_starts_at ON tournaments (starts_at);

-- ============================================================================
-- PUZZLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS puzzles (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  tournament_id    UUID         REFERENCES tournaments(id) ON DELETE CASCADE,
  seed             VARCHAR(64)  NOT NULL,             -- deterministic seed for generation
  grid_size        SMALLINT     NOT NULL CHECK (grid_size BETWEEN 5 AND 8),
  difficulty       VARCHAR(10)  NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  order_index      SMALLINT     NOT NULL DEFAULT 0,   -- puzzle 1-5 ordering within tournament
  solution_path    JSONB        NOT NULL,             -- [{x, y, num?}] full solution
  clue_numbers     JSONB        NOT NULL,             -- [{x, y, num}] revealed checkpoints
  is_practice      BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (tournament_id, order_index)
);

CREATE INDEX idx_puzzles_tournament_id ON puzzles (tournament_id);
CREATE INDEX idx_puzzles_seed          ON puzzles (seed);
CREATE INDEX idx_puzzles_is_practice   ON puzzles (is_practice);

-- ============================================================================
-- PUZZLE ATTEMPTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS puzzle_attempts (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  puzzle_id        UUID         NOT NULL REFERENCES puzzles(id) ON DELETE CASCADE,
  solve_time_ms    INTEGER      NOT NULL CHECK (solve_time_ms >= 0),
  is_valid         BOOLEAN      NOT NULL DEFAULT FALSE,
  is_best          BOOLEAN      NOT NULL DEFAULT FALSE, -- user's best attempt for this puzzle
  anticheat_flags  JSONB,                              -- any flags raised by anti-cheat
  server_started_at TIMESTAMPTZ NOT NULL,             -- server-recorded start time
  server_ended_at  TIMESTAMPTZ NOT NULL,              -- server-recorded end time
  submitted_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_attempts_user_id       ON puzzle_attempts (user_id);
CREATE INDEX idx_attempts_puzzle_id     ON puzzle_attempts (puzzle_id);
CREATE INDEX idx_attempts_is_best       ON puzzle_attempts (is_best);
CREATE INDEX idx_attempts_user_puzzle   ON puzzle_attempts (user_id, puzzle_id);

-- ============================================================================
-- REPLAY DATA
-- ============================================================================
CREATE TABLE IF NOT EXISTS replay_data (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  attempt_id       UUID         NOT NULL UNIQUE REFERENCES puzzle_attempts(id) ON DELETE CASCADE,
  move_sequence    JSONB        NOT NULL,             -- [{x, y, timestamp_ms}]
  total_moves      INTEGER      NOT NULL,
  path_length      INTEGER      NOT NULL,
  is_validated     BOOLEAN      NOT NULL DEFAULT FALSE,
  validation_error TEXT,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_replay_attempt_id   ON replay_data (attempt_id);
CREATE INDEX idx_replay_is_validated ON replay_data (is_validated);

-- ============================================================================
-- LEADERBOARD ENTRIES
-- ============================================================================
CREATE TABLE IF NOT EXISTS leaderboard_entries (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  tournament_id    UUID         NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id          UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_time_ms    BIGINT       NOT NULL,             -- sum of best attempt times
  puzzles_solved   SMALLINT     NOT NULL DEFAULT 0,
  completed_at     TIMESTAMPTZ,                       -- when all puzzles solved
  rank             INTEGER,                           -- computed/cached rank
  is_disqualified  BOOLEAN      NOT NULL DEFAULT FALSE,
  disqualify_reason TEXT,
  updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (tournament_id, user_id)
);

CREATE INDEX idx_leaderboard_tournament ON leaderboard_entries (tournament_id);
CREATE INDEX idx_leaderboard_total_time ON leaderboard_entries (tournament_id, total_time_ms ASC);
CREATE INDEX idx_leaderboard_completed  ON leaderboard_entries (tournament_id, completed_at ASC NULLS LAST);

-- ============================================================================
-- USER STATS
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_stats (
  user_id             UUID         PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  tournaments_played  INTEGER      NOT NULL DEFAULT 0,
  tournaments_won     INTEGER      NOT NULL DEFAULT 0,
  best_finish         INTEGER,                         -- lowest rank ever achieved
  fastest_solve_ms    INTEGER,                         -- fastest single puzzle solve
  total_puzzles_solved INTEGER     NOT NULL DEFAULT 0,
  practice_puzzles    INTEGER      NOT NULL DEFAULT 0,
  current_streak      INTEGER      NOT NULL DEFAULT 0,
  longest_streak      INTEGER      NOT NULL DEFAULT 0,
  average_solve_ms    INTEGER,
  last_active_at      TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- SEASON HISTORY (Archived tournaments)
-- ============================================================================
CREATE TABLE IF NOT EXISTS season_history (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  tournament_id    UUID         NOT NULL UNIQUE REFERENCES tournaments(id),
  winner_user_id   UUID         REFERENCES users(id) ON DELETE SET NULL,
  winner_username  VARCHAR(30),
  winner_time_ms   BIGINT,
  total_participants INTEGER    NOT NULL DEFAULT 0,
  snapshot_leaderboard JSONB,                          -- top 10 snapshot at freeze
  archived_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_season_history_archived ON season_history (archived_at DESC);

-- ============================================================================
-- REFRESH TOKENS (for secure auth)
-- ============================================================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash       VARCHAR(255) NOT NULL UNIQUE,
  expires_at       TIMESTAMPTZ  NOT NULL,
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  revoked_at       TIMESTAMPTZ
);

CREATE INDEX idx_refresh_tokens_user_id   ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_token     ON refresh_tokens (token_hash);

-- ============================================================================
-- ANTICHEAT FLAGS
-- ============================================================================
CREATE TABLE IF NOT EXISTS anticheat_flags (
  id               UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  attempt_id       UUID         REFERENCES puzzle_attempts(id) ON DELETE SET NULL,
  flag_type        VARCHAR(50)  NOT NULL,
  -- Types: 'impossible_speed', 'invalid_path', 'replay_mismatch',
  --        'emulator_detected', 'rooted_device', 'apk_tamper',
  --        'rate_abuse', 'duplicate_submission'
  severity         VARCHAR(10)  NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  details          JSONB,
  reviewed         BOOLEAN      NOT NULL DEFAULT FALSE,
  reviewed_by      UUID         REFERENCES users(id) ON DELETE SET NULL,
  action_taken     VARCHAR(50),
  created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_anticheat_user_id  ON anticheat_flags (user_id);
CREATE INDEX idx_anticheat_reviewed ON anticheat_flags (reviewed);
CREATE INDEX idx_anticheat_severity ON anticheat_flags (severity);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_tournaments_updated_at
  BEFORE UPDATE ON tournaments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_leaderboard_updated_at
  BEFORE UPDATE ON leaderboard_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Initialize user_stats row on user creation
CREATE OR REPLACE FUNCTION create_user_stats()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_stats (user_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_user_stats
  AFTER INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION create_user_stats();

-- ============================================================================
-- ROW LEVEL SECURITY (Supabase)
-- ============================================================================

ALTER TABLE users                ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE puzzles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE puzzle_attempts      ENABLE ROW LEVEL SECURITY;
ALTER TABLE replay_data          ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard_entries  ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stats           ENABLE ROW LEVEL SECURITY;
ALTER TABLE season_history       ENABLE ROW LEVEL SECURITY;
ALTER TABLE refresh_tokens       ENABLE ROW LEVEL SECURITY;
ALTER TABLE anticheat_flags      ENABLE ROW LEVEL SECURITY;

-- Service role bypasses RLS (used by backend server)
-- Client apps should use the backend API, not direct Supabase access

-- Public read: leaderboard, season history, tournaments
CREATE POLICY "Leaderboard is publicly readable"
  ON leaderboard_entries FOR SELECT USING (true);

CREATE POLICY "Tournaments are publicly readable"
  ON tournaments FOR SELECT USING (true);

CREATE POLICY "Season history is publicly readable"
  ON season_history FOR SELECT USING (true);

-- Users can read their own data
CREATE POLICY "Users can read own profile"
  ON users FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE USING (auth.uid()::text = id::text);

CREATE POLICY "Users can read own stats"
  ON user_stats FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can read own attempts"
  ON puzzle_attempts FOR SELECT USING (auth.uid()::text = user_id::text);

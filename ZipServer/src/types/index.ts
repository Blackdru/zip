// ============================================================================
// SHARED TYPES — ZIP Platform
// ============================================================================

// ─── Grid & Puzzle ──────────────────────────────────────────────────────────

export interface GridCell {
  x: number;  // column (0-indexed)
  y: number;  // row (0-indexed)
}

export interface ClueNumber extends GridCell {
  num: number;  // sequence number revealed to player
}

export interface SolutionStep extends GridCell {
  num?: number;  // present only on checkpoint cells
}

export type Difficulty = 'easy' | 'medium' | 'hard';

export interface PuzzleConfig {
  gridSize: number;       // 5–8
  difficulty: Difficulty;
  seed: string;
}

export interface Wall {
  x: number;
  y: number;
  length: number;
  isVertical: boolean;
}

export interface GeneratedPuzzle {
  seed: string;
  gridSize: number;
  difficulty: Difficulty;
  solutionPath: SolutionStep[];   // full hidden solution
  clueNumbers: ClueNumber[];      // visible checkpoints
  totalCheckpoints: number;
  walls: Wall[];                  // internal wall segments
  obstacles: SolutionStep[];      // obstacle cells (blocked squares)
}

// ─── Move & Replay ──────────────────────────────────────────────────────────

export interface Move {
  x: number;
  y: number;
  timestampMs: number;  // ms since puzzle start
}

export interface ReplayData {
  attemptId: string;
  moveSequence: Move[];
  totalMoves: number;
  pathLength: number;
}

// ─── Tournament ─────────────────────────────────────────────────────────────

export type TournamentStatus = 'upcoming' | 'active' | 'frozen' | 'archived';

export interface Tournament {
  id: string;
  weekNumber: number;
  year: number;
  title?: string;
  status: TournamentStatus;
  startsAt: string;
  endsAt: string;
  freezeAt: string;
  rewardDescription?: string;
  winnerId?: string;
}

// ─── User ────────────────────────────────────────────────────────────────────

export interface User {
  id: string;
  username: string;
  email: string;
  avatarUrl?: string;
  countryCode?: string;
  isAdmin: boolean;
  createdAt: string;
}

export interface UserStats {
  userId: string;
  tournamentsPlayed: number;
  tournamentsWon: number;
  bestFinish?: number;
  fastestSolveMs?: number;
  totalPuzzlesSolved: number;
  practiceCount: number;
  currentStreak: number;
  longestStreak: number;
  averageSolveMs?: number;
}

// ─── Leaderboard ─────────────────────────────────────────────────────────────

export interface LeaderboardEntry {
  id: string;
  tournamentId: string;
  userId: string;
  username: string;
  avatarUrl?: string;
  countryCode?: string;
  totalTimeMs: number;
  puzzlesSolved: number;
  completedAt?: string;
  rank: number;
  isDisqualified: boolean;
}

// ─── API Response Envelopes ───────────────────────────────────────────────────

export interface ApiResponse<T> {
  success: true;
  data: T;
  message?: string;
}

export interface ApiError {
  success: false;
  error: string;
  code?: string;
  details?: unknown;
}

export type ApiResult<T> = ApiResponse<T> | ApiError;

// ─── Auth ─────────────────────────────────────────────────────────────────────

export interface AuthTokenPayload {
  userId: string;
  email: string;
  username: string;
  isAdmin: boolean;
  iat?: number;
  exp?: number;
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  user: User;
}

// ─── Anti-Cheat ───────────────────────────────────────────────────────────────

export type AntiCheatFlagType =
  | 'impossible_speed'
  | 'invalid_path'
  | 'replay_mismatch'
  | 'emulator_detected'
  | 'rooted_device'
  | 'apk_tamper'
  | 'rate_abuse'
  | 'duplicate_submission';

export type AntiCheatSeverity = 'low' | 'medium' | 'high' | 'critical';

export interface AntiCheatFlag {
  flagType: AntiCheatFlagType;
  severity: AntiCheatSeverity;
  details?: Record<string, unknown>;
}

export interface SubmissionValidationResult {
  isValid: boolean;
  flags: AntiCheatFlag[];
  correctedTimeMs?: number;
}

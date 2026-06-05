import { ConnectDotsEngine, type ColorDot, type ConnectDotsPuzzle } from '../../core/connectDotsEngine';
import { ConnectDotsValidator, type PlayerPath } from '../../core/connectDotsValidator';
import type { Difficulty } from '../../types';

export interface ConnectDotsPuzzleResponse {
  id: string;
  seed: string;
  gridSize: number;
  difficulty: Difficulty;
  colorDots: ColorDot[];
  totalPairs: number;
  solutionPaths?: Array<{ pairId: number; path: Array<{ x: number; y: number }> }>;
}

export interface SubmitSolutionRequest {
  playerPaths: PlayerPath[];
  clientSolveTimeMs: number;
}

export interface SubmitSolutionResponse {
  isValid: boolean;
  solveTimeMs: number;
  isPersonalBest: boolean;
  errors?: string[];
  warnings?: string[];
}

export class ConnectDotsService {
  /**
   * Generate a random practice puzzle with random difficulty
   */
  static async generateRandomPuzzle(): Promise<ConnectDotsPuzzleResponse> {
    const difficulties: Difficulty[] = ['easy', 'medium', 'hard'];
    const randomDifficulty = difficulties[Math.floor(Math.random() * difficulties.length)];
    const randomSequence = Math.floor(Math.random() * 10000) + Date.now();
    
    const seed = ConnectDotsEngine.randomSeed();
    const puzzle = ConnectDotsEngine.generate(seed, randomDifficulty);

    // Convert solution paths to array format
    const solutionPaths = Array.from(puzzle.solutionPaths.entries()).map(
      ([pairId, path]) => ({ pairId, path })
    );

    return {
      id: `random-${randomDifficulty}-${randomSequence}`,
      seed: puzzle.seed,
      gridSize: puzzle.gridSize,
      difficulty: puzzle.difficulty,
      colorDots: puzzle.colorDots,
      totalPairs: puzzle.totalPairs,
      solutionPaths,
    };
  }

  /**
   * Generate a practice puzzle with solution paths (for hints)
   */
  static async generatePracticePuzzle(
    difficulty: Difficulty,
    sequence: number
  ): Promise<ConnectDotsPuzzleResponse> {
    const seed = ConnectDotsEngine.practiceSeed(difficulty, sequence);
    const puzzle = ConnectDotsEngine.generate(seed, difficulty);

    // Convert solution paths to array format
    const solutionPaths = Array.from(puzzle.solutionPaths.entries()).map(
      ([pairId, path]) => ({ pairId, path })
    );

    return {
      id: `practice-${difficulty}-${sequence}`,
      seed: puzzle.seed,
      gridSize: puzzle.gridSize,
      difficulty: puzzle.difficulty,
      colorDots: puzzle.colorDots,
      totalPairs: puzzle.totalPairs,
      solutionPaths,
    };
  }

  /**
   * Generate a tournament puzzle (no solution paths returned)
   */
  static async generateTournamentPuzzle(
    year: number,
    weekNumber: number,
    puzzleIndex: number,
    difficulty: Difficulty
  ): Promise<ConnectDotsPuzzleResponse> {
    const seed = ConnectDotsEngine.tournamentSeed(year, weekNumber, puzzleIndex);
    const puzzle = ConnectDotsEngine.generate(seed, difficulty);

    return {
      id: `tournament-${year}-${weekNumber}-${puzzleIndex}`,
      seed: puzzle.seed,
      gridSize: puzzle.gridSize,
      difficulty: puzzle.difficulty,
      colorDots: puzzle.colorDots,
      totalPairs: puzzle.totalPairs,
      // No solution paths for tournament mode
    };
  }

  /**
   * Get a specific puzzle by ID
   */
  static async getPuzzle(puzzleId: string): Promise<ConnectDotsPuzzleResponse> {
    // Parse puzzle ID to determine type and regenerate
    // Format: practice-{difficulty}-{sequence} or tournament-{year}-{week}-{index}
    
    const parts = puzzleId.split('-');
    
    if (parts[0] === 'practice') {
      const difficulty = parts[1] as Difficulty;
      const sequence = parseInt(parts[2], 10);
      return this.generatePracticePuzzle(difficulty, sequence);
    } else if (parts[0] === 'tournament') {
      const year = parseInt(parts[1], 10);
      const weekNumber = parseInt(parts[2], 10);
      const puzzleIndex = parseInt(parts[3], 10);
      // Default to medium difficulty for tournaments
      return this.generateTournamentPuzzle(year, weekNumber, puzzleIndex, 'medium');
    }

    throw new Error(`Invalid puzzle ID: ${puzzleId}`);
  }

  /**
   * Validate and submit a solution
   */
  static async submitSolution(
    puzzleId: string,
    request: SubmitSolutionRequest
  ): Promise<SubmitSolutionResponse> {
    // Regenerate puzzle to validate against
    const puzzleResponse = await this.getPuzzle(puzzleId);
    
    // Regenerate full puzzle with solution
    const parts = puzzleId.split('-');
    let puzzle: ConnectDotsPuzzle;
    
    if (parts[0] === 'practice') {
      const difficulty = parts[1] as Difficulty;
      const sequence = parseInt(parts[2], 10);
      const seed = ConnectDotsEngine.practiceSeed(difficulty, sequence);
      puzzle = ConnectDotsEngine.generate(seed, difficulty);
    } else {
      const year = parseInt(parts[1], 10);
      const weekNumber = parseInt(parts[2], 10);
      const puzzleIndex = parseInt(parts[3], 10);
      const seed = ConnectDotsEngine.tournamentSeed(year, weekNumber, puzzleIndex);
      puzzle = ConnectDotsEngine.generate(seed, 'medium');
    }

    // Validate timing
    if (!ConnectDotsValidator.validateTiming(request.clientSolveTimeMs)) {
      return {
        isValid: false,
        solveTimeMs: request.clientSolveTimeMs,
        isPersonalBest: false,
        errors: ['Solution time too fast - possible cheating'],
      };
    }

    // Validate solution
    const validation = ConnectDotsValidator.validate(
      request.playerPaths,
      puzzle.colorDots,
      puzzle.gridSize,
      puzzle.solutionPaths
    );

    if (!validation.isValid) {
      return {
        isValid: false,
        solveTimeMs: request.clientSolveTimeMs,
        isPersonalBest: false,
        errors: validation.errors,
        warnings: validation.warnings,
      };
    }

    // TODO: Store in database, check for personal best
    // For now, always return success
    return {
      isValid: true,
      solveTimeMs: request.clientSolveTimeMs,
      isPersonalBest: false,
      warnings: validation.warnings,
    };
  }
}

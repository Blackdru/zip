import 'package:dio/dio.dart';
import '../models/puzzle.dart';
import '../models/grid_cell.dart';
import 'api_client.dart';

/// Result of puzzle submission
class SubmitResult {
  final bool isValid;
  final int solveTimeMs;
  final bool isPersonalBest;
  final List<dynamic> flags;

  SubmitResult({
    required this.isValid,
    required this.solveTimeMs,
    required this.isPersonalBest,
    required this.flags,
  });

  factory SubmitResult.fromJson(Map<String, dynamic> json) {
    return SubmitResult(
      isValid: json['isValid'] as bool,
      solveTimeMs: json['solveTimeMs'] as int,
      isPersonalBest: json['isPersonalBest'] as bool,
      flags: json['flags'] as List<dynamic>,
    );
  }
}

/// Result of an unlimited puzzle request — puzzle data AND solution path for hints
class PracticePuzzleResult {
  final PuzzleData puzzle;
  final List<SolutionStep> solutionPath;

  PracticePuzzleResult({required this.puzzle, required this.solutionPath});
}

/// Puzzle service for fetching and submitting puzzles
class PuzzleService {
  final ApiClient _apiClient;

  PuzzleService(this._apiClient);

  /// Get a specific puzzle by ID
  Future<PuzzleData> getPuzzle(String puzzleId) async {
    try {
      final response = await _apiClient.dio.get('/puzzles/$puzzleId');
      return PuzzleData.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Submit puzzle solution
  Future<SubmitResult> submitSolution({
    required String puzzleId,
    required List<Move> moveSequence,
    required int clientSolveTimeMs,
    required String serverStartedAt,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/puzzles/$puzzleId/submit',
        data: {
          'moveSequence': moveSequence.map((m) => m.toJson()).toList(),
          'clientSolveTimeMs': clientSolveTimeMs,
          'serverStartedAt': serverStartedAt,
        },
      );

      return SubmitResult.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get an unlimited puzzle — returns puzzle data AND solution path for hints
  Future<PracticePuzzleResult> getPracticePuzzle({
    required Difficulty difficulty,
    required int sequence,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/puzzles/practice',
        queryParameters: {
          'difficulty': difficulty.name,
          'sequence': sequence,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;

      // Extract solutionPath before building PuzzleData (it's not part of PuzzleData model)
      final rawPath = data['solutionPath'] as List<dynamic>? ?? [];
      final solutionPath = rawPath
          .map((s) => SolutionStep.fromJson(s as Map<String, dynamic>))
          .toList();

      // Remove solutionPath from data so PuzzleData.fromJson doesn't see it
      final puzzleJson = Map<String, dynamic>.from(data)..remove('solutionPath');
      final puzzle = PuzzleData.fromJson(puzzleJson);

      return PracticePuzzleResult(puzzle: puzzle, solutionPath: solutionPath);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('error')) {
        return data['error'] as String;
      }
      return 'Server error: ${e.response!.statusCode}';
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Receive timeout';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection';
    }
    return 'An unexpected error occurred';
  }
}

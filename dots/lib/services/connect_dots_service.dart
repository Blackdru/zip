import 'package:dio/dio.dart';
import '../models/connect_dots_puzzle.dart';
import '../models/color_dot.dart';
import 'api_client.dart';

/// Service for Connect Dots puzzles
class ConnectDotsService {
  final ApiClient _apiClient;

  ConnectDotsService(this._apiClient);

  /// Get a specific puzzle by ID
  Future<ConnectDotsPuzzle> getPuzzle(String puzzleId) async {
    try {
      final response = await _apiClient.dio.get('/connectdots/$puzzleId');
      return ConnectDotsPuzzle.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Submit puzzle solution
  Future<PuzzleResult> submitSolution({
    required String puzzleId,
    required List<PlayerPath> playerPaths,
    required int clientSolveTimeMs,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/connectdots/$puzzleId/submit',
        data: {
          'playerPaths': playerPaths.map((p) => p.toJson()).toList(),
          'clientSolveTimeMs': clientSolveTimeMs,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return PuzzleResult.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a practice puzzle with solution paths for hints
  Future<ConnectDotsPuzzle> getPracticePuzzle({
    required Difficulty difficulty,
    required int sequence,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/connectdots/practice',
        queryParameters: {
          'difficulty': difficulty.name,
          'sequence': sequence,
        },
      );

      return ConnectDotsPuzzle.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('error')) {
        return data['error'].toString();
      }
      return 'Server error: ${e.response!.statusCode}';
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Network error. Please check your internet connection.';
    }

    return 'An unexpected error occurred';
  }
}

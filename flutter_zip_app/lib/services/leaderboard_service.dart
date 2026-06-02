import 'package:dio/dio.dart';
import '../models/leaderboard.dart';
import 'api_client.dart';

/// Leaderboard service
class LeaderboardService {
  final ApiClient _apiClient;

  LeaderboardService(this._apiClient);

  /// Get leaderboard for a tournament
  Future<LeaderboardResponse> getLeaderboard({
    required String tournamentId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/leaderboard/$tournamentId',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      return LeaderboardResponse.fromJson(response.data['data']);
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

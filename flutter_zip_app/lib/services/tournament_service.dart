import 'package:dio/dio.dart';
import '../models/tournament.dart';
import 'api_client.dart';

/// Tournament service
class TournamentService {
  final ApiClient _apiClient;

  TournamentService(this._apiClient);

  /// Get current active tournament
  Future<Tournament> getCurrent() async {
    try {
      final response = await _apiClient.dio.get('/tournaments/current');
      return Tournament.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get list of all tournaments
  Future<List<Tournament>> list() async {
    try {
      final response = await _apiClient.dio.get('/tournaments');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Tournament.fromJson(json)).toList();
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

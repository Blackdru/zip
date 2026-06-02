import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api_client.dart';

/// Authentication service
class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  /// Register a new user
  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data['data']);
      await _apiClient.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data['data']);
      await _apiClient.saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
      );

      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (e) {
      // Continue with local logout even if server request fails
    } finally {
      await _apiClient.clearAuth();
    }
  }

  /// Get current user profile
  Future<User> getMe() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      return User.fromJson(response.data['data']['user']);
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

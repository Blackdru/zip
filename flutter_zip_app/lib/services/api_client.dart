import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';

/// Dio-based API client with JWT authentication and auto-refresh
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(_getBaseOptions());
    _setupInterceptors();
  }

  Dio get dio => _dio;

  BaseOptions _getBaseOptions() {
    String baseUrl;

    if (kReleaseMode) {
      baseUrl = ApiConstants.productionBaseUrl;
    } else {
      // Development mode - detect platform
      if (Platform.isAndroid) {
        baseUrl = ApiConstants.androidEmulatorBaseUrl;
      } else {
        baseUrl = ApiConstants.developmentBaseUrl;
      }
    }

    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
      },
    );
  }

  void _setupInterceptors() {
    // Request interceptor - attach JWT (skip for certain endpoints)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip auth for these endpoints
          final path = options.path;
          final shouldSkipAuth = 
            path.contains('/puzzles') ||
            path.contains('/practice') ||
            path.contains('/tournaments');
          
          if (!shouldSkipAuth) {
            final token = await _storage.read(key: ApiConstants.accessTokenKey);
            if (token != null) {
              options.headers[ApiConstants.authorizationHeader] = 'Bearer $token';
            }
          } else {
            // Explicitly remove auth header if it exists
            options.headers.remove(ApiConstants.authorizationHeader);
            debugPrint('🔓 Skipping auth for: ${options.path}');
          }
          
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 - token expired
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;

            try {
              final refreshToken =
                  await _storage.read(key: ApiConstants.refreshTokenKey);

              if (refreshToken == null) {
                return handler.reject(error);
              }

              // Attempt to refresh token
              final response = await _dio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );

              final newAccessToken = response.data['data']['accessToken'];
              await _storage.write(
                key: ApiConstants.accessTokenKey,
                value: newAccessToken,
              );

              // Retry original request with new token
              final opts = error.requestOptions;
              opts.headers[ApiConstants.authorizationHeader] =
                  'Bearer $newAccessToken';

              _isRefreshing = false;
              final retryResponse = await _dio.fetch(opts);
              return handler.resolve(retryResponse);
            } catch (e) {
              _isRefreshing = false;
              // Clear tokens on refresh failure
              await _clearTokens();
              return handler.reject(error);
            }
          }

          return handler.next(error);
        },
      ),
    );

    // Logging interceptor (debug only)
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: ApiConstants.refreshTokenKey);
    await _storage.delete(key: ApiConstants.userKey);
  }

  /// Save authentication tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: ApiConstants.accessTokenKey, value: accessToken);
    await _storage.write(
        key: ApiConstants.refreshTokenKey, value: refreshToken,);
  }

  /// Clear all authentication data
  Future<void> clearAuth() async {
    await _clearTokens();
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: ApiConstants.accessTokenKey);
  }
}

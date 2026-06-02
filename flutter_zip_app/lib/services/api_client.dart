import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';

/// Dio-based API client for puzzle and unlimited modes
class ApiClient {
  late final Dio _dio;

  ApiClient() {
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
}

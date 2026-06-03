import 'package:dio/dio.dart';
import '../core/config/api_config.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // ignore: avoid_print
          print('🌐 API REQUEST[${options.method}] => ${options.baseUrl}${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print('✅ API RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          // ignore: avoid_print
          print('❌ API ERROR[${error.response?.statusCode ?? 'NO_RESPONSE'}] => ${error.requestOptions.path}');
          // ignore: avoid_print
          print('   Type: ${error.type}');
          // ignore: avoid_print
          print('   Message: ${error.message}');
          if (error.response != null) {
            // ignore: avoid_print
            print('   Response: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }
}

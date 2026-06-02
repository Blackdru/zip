/// API configuration constants
class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String productionBaseUrl = 'https://your-api-domain.com/api/v1';
  static const String developmentBaseUrl = 'http://localhost:3000/api/v1';
  // Android emulator uses 10.0.2.2 to access host machine's localhost
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:3000/api/v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 10);

  // Storage keys
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String userKey = 'user';

  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';
}

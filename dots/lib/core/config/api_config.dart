import 'dart:io' show Platform;

class ApiConfig {
  // Change this to match your setup:
  // - 'development': Use localhost for development
  // - 'emulator': Use 10.0.2.2 for Android emulator
  // - 'physical': Use your computer's local IP address
  // - 'production': Use production server
  static const String environment = 'emulator'; // Change based on your testing environment
  
  // Your computer's local IP address (for physical devices)
  // Find it by running: ipconfig (Windows) or ifconfig (Mac/Linux)
  static const String localIpAddress = '192.168.1.100'; // Replace with your actual IP
  
  static String get baseUrl {
    switch (environment) {
      case 'development':
        return 'http://localhost:2020/api/v1';
      case 'physical':
        return 'http://$localIpAddress:2020/api/v1';
      case 'production':
        return 'https://zip.robotpdf.com/api/v1';
      case 'emulator':
      default:
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:2020/api/v1'; // Android emulator
        } else {
          return 'http://localhost:2020/api/v1'; // iOS simulator
        }
    }
  }
  
  // Helper method to check if using production
  static bool get isProduction => environment == 'production';
  
  // Helper method to check if using secure connection
  static bool get isSecure => baseUrl.startsWith('https');
}

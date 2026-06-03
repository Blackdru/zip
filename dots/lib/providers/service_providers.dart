import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/connect_dots_service.dart';

/// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Connect Dots Service Provider
final connectDotsServiceProvider = Provider<ConnectDotsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ConnectDotsService(apiClient);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'service_providers.dart';

/// Auth state
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    // Debug: Log initial state
    print('🔐 AuthNotifier initialized with isLoading: ${state.isLoading}');
  }

  /// Register new user
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final authResponse = await _authService.register(
        username: username,
        email: email,
        password: password,
      );

      state = AuthState(
        user: authResponse.user,
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Login user
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final authResponse = await _authService.login(
        email: email,
        password: password,
      );

      state = AuthState(
        user: authResponse.user,
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  /// Load current user
  Future<void> loadUser() async {
    print('🔐 loadUser() called - setting isLoading: true');
    state = state.copyWith(isLoading: true);

    try {
      final user = await _authService.getMe();
      print('🔐 loadUser() success - setting isLoading: false');
      state = AuthState(
        user: user,
        isAuthenticated: true,
      );
    } catch (e) {
      print('🔐 loadUser() error: $e - setting isLoading: false');
      state = const AuthState(
        
      );
    }
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/service_locator.dart';
import '../services/auth_service.dart';

/// Represents the authentication state.
class AuthState {
  final bool isLoggedIn;
  final bool isInitialized;

  const AuthState({this.isLoggedIn = false, this.isInitialized = false});

  AuthState copyWith({bool? isLoggedIn, bool? isInitialized}) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Notifier for managing authentication state.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  AuthService get authService => _authService;

  /// Initializes the auth service and restores session if available.
  Future<void> init() async {
    await _authService.init();
    state = state.copyWith(
      isLoggedIn: _authService.isLoggedIn,
      isInitialized: true,
    );
  }

  /// Initiates the login flow.
  Future<bool> login() async {
    final success = await _authService.authenticate();
    if (success) {
      state = state.copyWith(isLoggedIn: true);
    }
    return success;
  }

  /// Logs out the user.
  Future<void> logout() async {
    await _authService.logout();
    state = state.copyWith(isLoggedIn: false);
  }
}

/// Provider for AuthNotifier using get_it service locator.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(getIt<AuthService>());
});

import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';

/// Notifier for managing authentication state.
class AuthNotifier extends ChangeNotifier {
  AuthRepository? _repository;

  bool _isLoggedIn = false;
  bool _isInitialized = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;

  /// Sets the repository. Called by ProxyProvider.
  void setRepository(AuthRepository repository) {
    _repository = repository;
  }

  /// Initializes auth and restores session if available.
  Future<void> init() async {
    if (_repository == null) return;
    await _repository!.init();
    _isLoggedIn = _repository!.isLoggedIn;
    _isInitialized = true;
    notifyListeners();
  }

  /// Initiates the login flow.
  Future<bool> login() async {
    if (_repository == null) return false;
    final success = await _repository!.login();
    if (success) {
      _isLoggedIn = true;
      notifyListeners();
    }
    return success;
  }

  /// Logs out the user.
  Future<void> logout() async {
    if (_repository == null) return;
    await _repository!.logout();
    _isLoggedIn = false;
    notifyListeners();
  }
}

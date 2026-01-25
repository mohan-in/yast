import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:draw/draw.dart';

/// Service responsible for Reddit OAuth2 authentication.
class AuthService {
  static const String _clientId = String.fromEnvironment('REDDIT_CLIENT_ID');
  static const String _userAgent =
      'flutter_reddit_demo/1.0.0 (by /u/antigravity)';
  static const String _credentialsKey = 'reddit_credentials';
  static const List<String> _oauthScopes = [
    'read',
    'identity',
    'mysubreddits',
    'vote',
    'history',
  ];

  static const String _redirectUri = 'com.mohan.reddit.client://callback';

  Reddit? _reddit;
  String? _lastSavedCredentials;

  /// Returns the Reddit client instance.
  Reddit? get reddit => _reddit;

  /// Checks if the user is currently logged in.
  /// Returns true if we have valid credentials with a refresh token,
  /// even if the access token has expired (it will be refreshed automatically).
  bool get isLoggedIn {
    if (_reddit == null) return false;
    try {
      final credentials = _reddit!.auth.credentials;
      // A session is valid if we have a refresh token (for permanent sessions)
      return credentials.refreshToken != null;
    } catch (_) {
      return false;
    }
  }

  /// Persists the current credentials to storage.
  /// Should be called after API operations that may trigger a token refresh.
  Future<void> persistCredentials() async {
    if (_reddit == null || !_reddit!.auth.isValid) return;

    try {
      final currentCredentials = _reddit!.auth.credentials.toJson();
      // Only save if credentials have changed to avoid unnecessary writes
      if (currentCredentials != _lastSavedCredentials) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_credentialsKey, currentCredentials);
        _lastSavedCredentials = currentCredentials;
      }
    } catch (_) {
      // Silently fail - we don't want to crash the app if credential saving fails
    }
  }

  /// Initializes the data source, restoring the session if available.
  /// If the access token has expired, it will be refreshed automatically.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final credentialsJson = prefs.getString(_credentialsKey);

    if (credentialsJson != null) {
      try {
        _reddit = Reddit.restoreAuthenticatedInstance(
          credentialsJson,
          clientId: _clientId,
          userAgent: _userAgent,
          redirectUri: Uri.parse(_redirectUri),
        );
        _lastSavedCredentials = credentialsJson;

        // If the access token is expired but we have a refresh token,
        // proactively refresh to ensure the session is ready
        if (!_reddit!.auth.isValid && isLoggedIn) {
          await _reddit!.auth.refresh();
          await persistCredentials();
        }
      } catch (_) {
        await logout();
      }
    }
  }

  /// Initiates the OAuth2 authentication flow.
  Future<bool> authenticate() async {
    final redditConfig = Reddit.createInstalledFlowInstance(
      clientId: _clientId,
      userAgent: _userAgent,
      redirectUri: Uri.parse(_redirectUri),
    );

    final url = redditConfig.auth.url(
      _oauthScopes,
      'random_string',
      compactLogin: true,
    );

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: 'com.mohan.reddit.client',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code != null) {
        await _exchangeCodeForToken(code, redditConfig);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Exchanges the authorization code for an access token.
  Future<void> _exchangeCodeForToken(String code, Reddit redditInstance) async {
    try {
      await redditInstance.auth.authorize(code);
      _reddit = redditInstance;

      final credentialsJson = _reddit!.auth.credentials.toJson();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_credentialsKey, credentialsJson);
      _lastSavedCredentials = credentialsJson;
    } catch (_) {
      rethrow;
    }
  }

  /// Logs out the user by clearing stored credentials.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_credentialsKey);
    _reddit = null;
  }
}

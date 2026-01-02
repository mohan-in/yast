import 'dart:async';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:draw/draw.dart';
import 'auth_listener.dart';

/// Service responsible for handling Reddit OAuth2 authentication using the `draw` package.
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

  /// Returns the Redirect URI based on the platform.
  String get _redirectUri {
    if (kIsWeb) {
      return '${Uri.base.origin}/auth.html';
    }
    return 'com.mohan.reddit.client://callback';
  }

  Reddit? _reddit;
  Reddit? get reddit => _reddit;

  /// Initializes the service, restoring the session if available.
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
      } catch (e) {
        debugPrint('Failed to restore Reddit session: $e');
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
      final fallbackFuture = listenForAuthToken();

      final authFuture = FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: kIsWeb ? 'http' : 'com.mohan.reddit.client',
      );

      final result = await Future.any([
        authFuture,
        fallbackFuture.then((value) => value ?? Completer<String>().future),
      ]);

      final code = Uri.parse(result as String).queryParameters['code'];
      if (code != null) {
        await _exchangeCodeForToken(code, redditConfig);
        return true;
      }
    } catch (e) {
      debugPrint('Authentication failed: $e');
    }
    return false;
  }

  /// Exchanges the authorization code for an access token using draw.
  Future<void> _exchangeCodeForToken(String code, Reddit redditInstance) async {
    try {
      await redditInstance.auth.authorize(code);
      _reddit = redditInstance;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _credentialsKey,
        _reddit!.auth.credentials.toJson(),
      );
    } catch (e) {
      debugPrint('Token exchange error: $e');
      rethrow;
    }
  }

  /// Logs out the user by clearing stored credentials.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_credentialsKey);
    _reddit = null;
  }

  /// Checks if the user is currently logged in.
  bool get isLoggedIn => _reddit != null && _reddit!.auth.isValid;
}

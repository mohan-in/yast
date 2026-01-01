import 'dart:convert';
import 'dart:async'; // Added for Completer
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'auth_listener.dart';

/// Service responsible for handling Reddit OAuth2 authentication.
///
/// This service manages the OAuth flow, including:
/// - Constructing the authorization URL.
/// - launching the web authentication flow via [FlutterWebAuth2].
/// - Exchanging the authorization code for an access token.
/// - Storing and retrieving tokens from [SharedPreferences].
class AuthService {
  // NOTE: For Web, you must add "http://localhost:<port>/auth.html" to your Redirect URIs in Reddit App preferences.
  // Provide via: flutter run --dart-define=REDDIT_CLIENT_ID=your_client_id
  static const String _clientId = String.fromEnvironment('REDDIT_CLIENT_ID');

  /// Returns the Redirect URI based on the platform.
  ///
  /// For Web, it dynamically constructs the URL based on the current origin.
  /// For Mobile, it uses a custom scheme 'com.mohan.reddit.client://callback'.
  String get _redirectUri {
    if (kIsWeb) {
      // Dynamically get the current origin (e.g., http://localhost:8080) and append auth.html
      // This requires the user to access the app via the same Origin as registered in Reddit.
      // For local dev, this is usually http://localhost:some_port/
      // The user MUST register this exact URL in Reddit Prefs.
      // We strip any query params/fragments from Uri.base
      return '${Uri.base.origin}/auth.html';
    }
    return 'com.mohan.reddit.client://callback';
  }

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// Initiates the OAuth2 authentication flow.
  ///
  /// Returns `true` if authentication is successful, `false` otherwise.
  Future<bool> authenticate() async {
    final redirectUri = _redirectUri;

    // Manually construct the URL to ensure exact encoding (e.g. %20 for spaces)
    // Use Uri.https for robust parameter encoding and construction
    // We use authorize.compact for a better mobile experience
    final url = Uri.https('www.reddit.com', '/api/v1/authorize.compact', {
      'client_id': _clientId,
      'response_type': 'code',
      'state': 'random_string',
      'redirect_uri': redirectUri,
      'duration': 'permanent',
      'scope': 'read identity mysubreddits vote history',
    }).toString();

    debugPrint('Authenticating with URL: $url');
    debugPrint('Redirect URI: $redirectUri');

    try {
      // Start listening for LocalStorage fallback (Web only)
      final fallbackFuture = listenForAuthToken();

      // Start standard authentication
      final authFuture = FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: kIsWeb ? 'http' : 'com.mohan.reddit.client',
        // Note: callbackUrlScheme on web is less critical for flutter_web_auth_2 as it relies on postMessage,
        // but passing 'http' or 'https' is good practice.
      );

      // Wait for either the standard result OR the fallback listener
      final result = await Future.any([
        authFuture,
        // Wrap fallback in a future that throws if null so Future.any doesn't pick it immediately if empty
        fallbackFuture.then((value) => value ?? Completer<String>().future),
      ]);

      // If result is the URL/Code string
      final code = Uri.parse(result as String).queryParameters['code'];
      if (code != null) {
        return await _exchangeCodeForToken(code, redirectUri);
      }
    } catch (e) {
      debugPrint('Authentication failed: $e');
    }
    return false;
  }

  /// Exchanges the authorization code for an access token.
  Future<bool> _exchangeCodeForToken(String code, String redirectUri) async {
    final url = Uri.parse('https://www.reddit.com/api/v1/access_token');
    final credentials = base64Encode(utf8.encode('$_clientId:'));

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'flutter_reddit_demo/1.0.0 (by /u/antigravity)',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access_token'];
        final refreshToken =
            data['refresh_token']; // Might be null if not requesting permanent

        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_accessTokenKey, accessToken);
          if (refreshToken != null) {
            await prefs.setString(_refreshTokenKey, refreshToken);
          }
          return true;
        }
      } else {
        debugPrint(
          'Token exchange failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Token exchange error: $e');
    }
    return false;
  }

  /// Retrieves the stored access token, if valid.
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Logs out the user by clearing stored tokens.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  /// Checks if the user is currently logged in.
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }
}

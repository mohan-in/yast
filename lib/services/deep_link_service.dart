import 'package:app_links/app_links.dart';
import 'dart:async';

/// Parsed deep link result for navigation
class DeepLinkResult {
  final DeepLinkType type;
  final String? subreddit;
  final String? postId;
  final String? username;

  const DeepLinkResult({
    required this.type,
    this.subreddit,
    this.postId,
    this.username,
  });
}

enum DeepLinkType { subreddit, post, user, home, unknown }

/// Service for handling Reddit deep links
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Get the initial link that opened the app (cold start)
  Future<DeepLinkResult?> getInitialLink() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      return parseRedditUrl(uri);
    }
    return null;
  }

  /// Listen for incoming links while app is running (warm start)
  Stream<DeepLinkResult> get linkStream {
    return _appLinks.uriLinkStream.map((uri) => parseRedditUrl(uri));
  }

  /// Parse a Reddit URL into a DeepLinkResult
  DeepLinkResult parseRedditUrl(Uri uri) {
    final pathSegments = uri.pathSegments;

    // Handle empty path -> home
    if (pathSegments.isEmpty) {
      return const DeepLinkResult(type: DeepLinkType.home);
    }

    // /r/{subreddit} or /r/{subreddit}/comments/{id}/...
    if (pathSegments.isNotEmpty && pathSegments[0] == 'r') {
      if (pathSegments.length >= 2) {
        final subreddit = pathSegments[1];

        // Check if this is a post link: /r/{sub}/comments/{id}/...
        if (pathSegments.length >= 4 && pathSegments[2] == 'comments') {
          final postId = pathSegments[3];
          return DeepLinkResult(
            type: DeepLinkType.post,
            subreddit: subreddit,
            postId: postId,
          );
        }

        // Just subreddit link
        return DeepLinkResult(
          type: DeepLinkType.subreddit,
          subreddit: subreddit,
        );
      }
    }

    // /u/{username} or /user/{username}
    if (pathSegments.isNotEmpty &&
        (pathSegments[0] == 'u' || pathSegments[0] == 'user')) {
      if (pathSegments.length >= 2) {
        return DeepLinkResult(
          type: DeepLinkType.user,
          username: pathSegments[1],
        );
      }
    }

    // /comments/{id}/... (direct post link without subreddit)
    if (pathSegments.isNotEmpty && pathSegments[0] == 'comments') {
      if (pathSegments.length >= 2) {
        return DeepLinkResult(type: DeepLinkType.post, postId: pathSegments[1]);
      }
    }

    return const DeepLinkResult(type: DeepLinkType.unknown);
  }

  /// Dispose of any subscriptions
  void dispose() {
    _linkSubscription?.cancel();
  }
}

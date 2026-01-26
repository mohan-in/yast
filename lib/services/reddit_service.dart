import 'package:draw/draw.dart' as draw;
import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/subreddit.dart';
import '../models/types.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

/// Service for Reddit API calls.
class RedditService {
  final AuthService _authService;

  RedditService(this._authService);

  draw.Reddit? get _reddit => _authService.reddit;

  /// Fetches posts from the home feed or a specific subreddit.
  ///
  /// Returns a [PostsResult] containing the list of posts and pagination cursor.
  Future<PostsResult> fetchPosts({String? subreddit, String? after}) async {
    final reddit = _reddit;
    if (reddit == null) {
      throw Exception('Reddit client not initialized or logged out');
    }

    final Map<String, String> params = {'limit': '$kDefaultPostLimit'};
    if (after != null) {
      params['after'] = after;
    }

    final stream = subreddit != null
        ? reddit
              .subreddit(subreddit)
              .hot(limit: kDefaultPostLimit, params: params)
        : reddit.front.best(limit: kDefaultPostLimit, params: params);

    final List<Post> posts = [];
    String? nextAfterToken;

    try {
      await for (final content in stream) {
        if (content is draw.Submission) {
          posts.add(Post.fromSubmission(content));
          nextAfterToken = content.fullname;
        }
      }
      // Persist credentials after successful API call (token may have been refreshed)
      await _authService.persistCredentials();
    } catch (e) {
      debugPrint('Failed to fetch posts: $e');
    }

    return (posts: posts, nextAfter: nextAfterToken);
  }

  /// Fetches comments for a post.
  Future<List<Comment>> fetchComments(String postId) async {
    final reddit = _reddit;
    if (reddit == null) {
      throw Exception('Reddit client not initialized or logged out');
    }

    try {
      final ref = reddit.submission(id: postId);
      final submission = await ref.populate();

      // Persist credentials after successful API call (token may have been refreshed)
      await _authService.persistCredentials();

      if (submission.comments != null) {
        return submission.comments!.comments
            .whereType<draw.Comment>()
            .map((c) => Comment.fromDraw(c))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  /// Fetches the user's subscribed subreddits.
  Future<List<Subreddit>> fetchSubscribedSubreddits() async {
    final reddit = _reddit;
    if (reddit == null) return [];

    try {
      final List<Subreddit> subs = [];
      await for (final sub in reddit.user.subreddits()) {
        subs.add(Subreddit.fromDraw(sub));
      }
      // Persist credentials after successful API call (token may have been refreshed)
      await _authService.persistCredentials();
      return subs;
    } catch (e) {
      debugPrint('Failed to fetch subscribed subreddits: $e');
      return [];
    }
  }

  /// Searches for subreddits by name prefix.
  Future<List<Subreddit>> searchSubreddits(String query) async {
    final reddit = _reddit;
    if (reddit == null || query.isEmpty) return [];

    try {
      final results = await reddit.subreddits.searchByName(
        query,
        includeNsfw: false,
      );
      // Fetch full subreddit info for each result
      final List<Subreddit> subs = [];
      for (final ref in results) {
        try {
          final sub = await ref.populate();
          subs.add(Subreddit.fromDraw(sub));
        } catch (_) {
          // Skip subreddits that fail to load
        }
      }
      // Persist credentials after successful API call (token may have been refreshed)
      await _authService.persistCredentials();
      return subs;
    } catch (e) {
      debugPrint('Failed to search subreddits: $e');
      return [];
    }
  }
}

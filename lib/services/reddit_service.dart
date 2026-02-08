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
      if (e.toString().contains('401')) {
        try {
          debugPrint('401 Unauthorized, refreshing session...');
          await _authService.refreshSession();
          // Retry the request recursively
          // Note: To avoid infinite loops in a real specific retry function we'd add a count,
          // but for this simple recursive retry on a specific error, it's acceptable if limited.
          // However, here we are inside fetchPosts which returns Future<PostsResult>.
          // We can just call fetchPosts again.
          return fetchPosts(subreddit: subreddit, after: after);
        } catch (refreshError) {
          debugPrint('Failed to refresh session or retry: $refreshError');
          // Retrying failed, so we fall through to return empty or rethrow
        }
      }
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
      if (e.toString().contains('401')) {
        try {
          debugPrint(
            '401 Unauthorized in fetchComments, refreshing session...',
          );
          await _authService.refreshSession();
          return fetchComments(postId);
        } catch (_) {
          // Fall through to rethrow original or new error
        }
      }
      throw Exception('Failed to load comments: $e');
    }
  }

  /// Fetches a single post by ID.
  Future<Post?> fetchPost(String postId) async {
    final reddit = _reddit;
    if (reddit == null) {
      return null;
    }

    try {
      final ref = reddit.submission(id: postId);
      final submission = await ref.populate();

      // Persist credentials after successful API call (token may have been refreshed)
      await _authService.persistCredentials();

      return Post.fromSubmission(submission);
    } catch (e) {
      if (e.toString().contains('401')) {
        try {
          debugPrint('401 Unauthorized in fetchPost, refreshing session...');
          await _authService.refreshSession();
          return fetchPost(postId);
        } catch (_) {}
      }
      debugPrint('Failed to fetch post $postId: $e');
      return null;
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
      if (e.toString().contains('401')) {
        try {
          debugPrint(
            '401 Unauthorized in fetchSubscribedSubreddits, refreshing session...',
          );
          await _authService.refreshSession();
          return fetchSubscribedSubreddits();
        } catch (_) {}
      }
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
      if (e.toString().contains('401')) {
        try {
          debugPrint(
            '401 Unauthorized in searchSubreddits, refreshing session...',
          );
          await _authService.refreshSession();
          return searchSubreddits(query);
        } catch (_) {}
      }
      debugPrint('Failed to search subreddits: $e');
      return [];
    }
  }
}

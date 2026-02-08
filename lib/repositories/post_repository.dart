import '../models/post.dart';
import '../models/comment.dart';
import '../models/types.dart';
import '../services/reddit_service.dart';
import '../services/cache_service.dart';

/// Repository for post operations with caching support.
class PostRepository {
  final RedditService _redditService;
  final CacheService _cacheService;

  PostRepository(this._redditService, this._cacheService);

  /// Fetches posts with optional caching.
  ///
  /// Returns a [PostsResult] containing posts and the pagination cursor.
  Future<PostsResult> getPosts({
    String? subreddit,
    String? after,
    bool useCache = true,
  }) async {
    if (useCache && after == null) {
      final cached = await _cacheService.getCachedPosts(subreddit);
      if (cached.isNotEmpty) {
        _fetchAndCacheInBackground(subreddit);
        return (posts: cached, nextAfter: null);
      }
    }

    return await _fetchFromApi(subreddit, after);
  }

  /// Fetches fresh posts from API and caches them.
  Future<PostsResult> refresh({String? subreddit}) async {
    final result = await _redditService.fetchPosts(subreddit: subreddit);
    await _cacheService.cachePosts(subreddit, result.posts);
    return result;
  }

  Future<PostsResult> _fetchFromApi(String? subreddit, String? after) async {
    final result = await _redditService.fetchPosts(
      subreddit: subreddit,
      after: after,
    );
    if (after == null) {
      await _cacheService.cachePosts(subreddit, result.posts);
    }
    return result;
  }

  void _fetchAndCacheInBackground(String? subreddit) {
    _redditService
        .fetchPosts(subreddit: subreddit)
        .then((result) {
          _cacheService.cachePosts(subreddit, result.posts);
        })
        .catchError((_) {});
  }

  /// Fetches comments for a post.
  Future<List<Comment>> getComments(String postId) async {
    return await _redditService.fetchComments(postId);
  }

  /// Gets cached posts for a subreddit.
  Future<List<Post>> getCachedPosts(String? subreddit) async {
    return await _cacheService.getCachedPosts(subreddit);
  }

  /// Marks a post as read.
  Future<void> markAsRead(String postId) async {
    await _cacheService.markAsRead(postId);
  }

  /// Gets all read post IDs.
  Future<Set<String>> getReadPostIds() async {
    return await _cacheService.getReadPostIds();
  }
}

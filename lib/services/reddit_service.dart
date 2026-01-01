import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../models/comment.dart';
import '../models/subreddit.dart';
import '../services/auth_service.dart'; // Assuming AuthService is in this path

class RedditService {
  final http.Client? client;
  final AuthService? authService;

  RedditService({this.client, this.authService});

  Future<({List<Post> posts, String? nextAfter})> fetchPosts({
    String? subreddit,
    String? after,
  }) async {
    final token = await authService?.getAccessToken();
    final isAuth = token != null;
    final baseUrl = isAuth ? 'oauth.reddit.com' : 'www.reddit.com';

    // If subreddit is provided, use r/$subreddit, otherwise use default home feed (best)
    // For authenticated users, /best provides a personalized mix.
    final path = subreddit != null ? '/r/$subreddit/hot.json' : '/best.json';

    final url = Uri.https(baseUrl, path, {
      'limit': '10',
      if (after != null) 'after': after,
    });

    final headers = {
      'User-Agent': 'flutter_reddit_demo/1.0.0 (by /u/antigravity)',
      if (isAuth) 'Authorization': 'Bearer $token',
    };

    final response =
        await (client?.get(url, headers: headers) ??
            http.get(url, headers: headers));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> children = data['data']['children'];
      final posts = children.map((json) => Post.fromJson(json)).toList();
      final String? nextAfter = data['data']['after'];
      return (posts: posts, nextAfter: nextAfter);
    } else if (response.statusCode == 401 && isAuth) {
      // Token might be expired. For V1 we just fail or could try refresh.
      // Logout or handle error.
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }

  Future<List<Comment>> fetchComments(String permalink) async {
    final token = await authService?.getAccessToken();
    final isAuth = token != null;
    final baseUrl = isAuth ? 'oauth.reddit.com' : 'www.reddit.com';

    // Permalink usually starts with /r/..., we append .json
    // Ensure we handle local paths correctly.
    final path = '$permalink.json';

    final url = Uri.https(baseUrl, path);

    final headers = {
      'User-Agent': 'flutter_reddit_demo/1.0.0 (by /u/antigravity)',
      if (isAuth) 'Authorization': 'Bearer $token',
    };

    final response =
        await (client?.get(url, headers: headers) ??
            http.get(url, headers: headers));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.length > 1) {
        final List<dynamic> children = data[1]['data']['children'];
        return children
            .where(
              (json) => json['kind'] == 't1',
            ) // t1 is the kind for comments
            .map((json) => Comment.fromJson(json))
            .toList();
      }
      return [];
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<List<Subreddit>> fetchSubscribedSubreddits() async {
    final token = await authService?.getAccessToken();
    if (token == null) return [];

    final url = Uri.https('oauth.reddit.com', '/subreddits/mine/subscriber', {
      'limit': '100', // Fetch up to 100 subreddits
    });

    final headers = {
      'User-Agent': 'flutter_reddit_demo/1.0.0 (by /u/antigravity)',
      'Authorization': 'Bearer $token',
    };

    final response =
        await (client?.get(url, headers: headers) ??
            http.get(url, headers: headers));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> children = data['data']['children'];
      return children.map((json) => Subreddit.fromJson(json)).toList();
    } else {
      // If failed (e.g. 401), just return empty list or throw
      // For now, return empty to avoid breaking UI
      return [];
    }
  }
}

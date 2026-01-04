import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/reddit_service.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/feed_notifier.dart';
import '../notifiers/subreddits_notifier.dart';
import '../widgets/app_drawer.dart';
import '../widgets/login_prompt.dart';
import '../widgets/post_list.dart';
import '../widgets/subreddit_search_delegate.dart';
import '../utils/image_utils.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Prefetch threshold: Start loading next page when 800px from bottom
  // This is roughly 2-3 cards ahead, giving seamless infinite scroll
  static const int _scrollThreshold = 800;

  final ScrollController _scrollController = ScrollController();

  // Track last precache scroll position to throttle precaching
  double _lastPrecachePosition = 0;
  static const double _precacheScrollThreshold =
      600; // Precache every 600px of scroll

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // Initialize auth on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    final authNotifier = context.read<AuthNotifier>();
    final feedNotifier = context.read<FeedNotifier>();
    final subredditsNotifier = context.read<SubredditsNotifier>();
    await authNotifier.init();
    if (authNotifier.isLoggedIn && mounted) {
      feedNotifier.loadPosts();
      subredditsNotifier.fetch();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final currentPosition = _scrollController.position.pixels;

    // Load more posts when near bottom
    if (currentPosition >=
        _scrollController.position.maxScrollExtent - _scrollThreshold) {
      context.read<FeedNotifier>().loadPosts();
    }

    // Precache images as user scrolls (throttled to every 600px)
    if ((currentPosition - _lastPrecachePosition).abs() >=
        _precacheScrollThreshold) {
      _lastPrecachePosition = currentPosition;
      _precachePostImages();
    }
  }

  Future<void> _handleLogin() async {
    final authNotifier = context.read<AuthNotifier>();
    final success = await authNotifier.login();
    if (success && mounted) {
      context.read<FeedNotifier>().loadPosts();
      context.read<SubredditsNotifier>().fetch();
    }
  }

  Future<void> _handleLogout() async {
    await context.read<AuthNotifier>().logout();
    if (!mounted) return;
    context.read<FeedNotifier>().clear();
    context.read<SubredditsNotifier>().clear();
  }

  /// Precaches images for upcoming posts (not yet visible).
  /// Uses CachedNetworkImage's cache manager for disk caching.
  void _precachePostImages() {
    final feedNotifier = context.read<FeedNotifier>();
    final posts = feedNotifier.visiblePosts;

    // Calculate roughly which posts are visible (estimate ~3 posts per screen)
    final scrollPosition = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;
    final estimatedVisibleIndex = (scrollPosition / 300)
        .floor(); // ~300px per card

    // Prefetch next 5 posts beyond the visible area
    final startIndex = (estimatedVisibleIndex + 3).clamp(0, posts.length);
    final endIndex = (startIndex + 5).clamp(0, posts.length);

    for (var i = startIndex; i < endIndex; i++) {
      final post = posts[i];

      // Collect all image URLs for this post (carousel or single image)
      final imagesToCache = <String>[];

      // Add carousel images
      if (post.images.isNotEmpty) {
        imagesToCache.addAll(post.images);
      }
      // Add single image if exists and not already in carousel
      else if (post.imageUrl != null) {
        imagesToCache.add(post.imageUrl!);
      }
      // Add thumbnail as fallback
      else if (post.thumbnail != null) {
        imagesToCache.add(post.thumbnail!);
      }

      // Precache all images for this post
      for (final imageUrl in imagesToCache) {
        precacheImage(
          CachedNetworkImageProvider(
            ImageUtils.getCorsUrl(imageUrl),
            headers: ImageUtils.authHeaders,
          ),
          context,
        ).catchError((_) {});
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final feedNotifier = context.watch<FeedNotifier>();
    final subredditsNotifier = context.watch<SubredditsNotifier>();
    final redditService = context.read<RedditService>();

    // Handle back gesture: go to home feed if viewing a subreddit
    return PopScope(
      canPop: feedNotifier.currentSubreddit == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && feedNotifier.currentSubreddit != null) {
          context.read<FeedNotifier>().selectSubreddit(null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            feedNotifier.currentSubreddit != null
                ? 'r/${feedNotifier.currentSubreddit}'
                : (authNotifier.isLoggedIn ? 'Home' : 'YARC'),
          ),
          actions: _buildAppBarActions(authNotifier, feedNotifier),
        ),
        drawer: !authNotifier.isLoggedIn
            ? null
            : AppDrawer(
                subreddits: subredditsNotifier.subreddits,
                onSubredditSelected: (sub) {
                  context.read<FeedNotifier>().selectSubreddit(sub.displayName);
                },
                onLogout: _handleLogout,
              ),
        body: _buildBody(authNotifier, feedNotifier, redditService),
      ),
    );
  }

  List<Widget> _buildAppBarActions(
    AuthNotifier authNotifier,
    FeedNotifier feedNotifier,
  ) {
    return [
      if (feedNotifier.currentSubreddit != null)
        IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            context.read<FeedNotifier>().selectSubreddit(null);
          },
          tooltip: 'Go Home',
        ),
      if (authNotifier.isLoggedIn || feedNotifier.currentSubreddit != null) ...[
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _openSearch,
          tooltip: 'Search Subreddits',
        ),
        IconButton(
          icon: Icon(
            feedNotifier.hideRead ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            context.read<FeedNotifier>().toggleHideRead();
            _scrollToTop();
          },
          tooltip: feedNotifier.hideRead ? 'Show All Posts' : 'Hide Read Posts',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<FeedNotifier>().refresh();
            _scrollToTop();
          },
        ),
      ],
      if (!authNotifier.isLoggedIn)
        TextButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Login'),
          onPressed: _handleLogin,
          style: TextButton.styleFrom(foregroundColor: Colors.black),
        ),
    ];
  }

  Future<void> _openSearch() async {
    final selectedSubreddit = await showSearch<String?>(
      context: context,
      delegate: SubredditSearchDelegate(),
    );

    if (selectedSubreddit != null && mounted) {
      context.read<FeedNotifier>().selectSubreddit(selectedSubreddit);
    }
  }

  Widget _buildBody(
    AuthNotifier authNotifier,
    FeedNotifier feedNotifier,
    RedditService redditService,
  ) {
    // Show login prompt if not logged in and no subreddit selected
    if (!authNotifier.isLoggedIn && feedNotifier.currentSubreddit == null) {
      return LoginPrompt(onLogin: _handleLogin);
    }

    // Show post list
    return PostList(
      posts: feedNotifier.visiblePosts,
      isLoading: feedNotifier.isLoading,
      scrollController: _scrollController,
      onRefresh: () => context.read<FeedNotifier>().refresh(),
      onPostTap: (post) {
        context.read<FeedNotifier>().markAsRead(post.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostDetailScreen(post: post, redditService: redditService),
          ),
        );
      },
    );
  }
}

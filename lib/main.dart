import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/theme.dart';
import 'services/auth_service.dart';
import 'services/cache_service.dart';
import 'services/reddit_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/post_repository.dart';
import 'data/repositories/subreddit_repository.dart';
import 'notifiers/auth_notifier.dart';
import 'notifiers/feed_notifier.dart';
import 'notifiers/search_notifier.dart';
import 'notifiers/subreddits_notifier.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for caching
  await CacheService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => CacheService()),
        ProxyProvider<AuthService, RedditService>(
          update: (_, auth, prev) => RedditService(auth),
        ),

        // Repositories
        ProxyProvider<AuthService, AuthRepository>(
          update: (_, auth, prev) => AuthRepository(auth),
        ),
        ProxyProvider2<RedditService, CacheService, PostRepository>(
          update: (_, reddit, cache, prev) => PostRepository(reddit, cache),
        ),
        ProxyProvider<RedditService, SubredditRepository>(
          update: (_, reddit, prev) => SubredditRepository(reddit),
        ),

        // Notifiers
        ChangeNotifierProxyProvider<AuthRepository, AuthNotifier>(
          create: (_) => AuthNotifier(),
          update: (_, repo, notifier) => notifier!..setRepository(repo),
        ),
        ChangeNotifierProxyProvider<PostRepository, FeedNotifier>(
          create: (_) => FeedNotifier(),
          update: (_, repo, notifier) => notifier!..setRepository(repo),
        ),
        ChangeNotifierProxyProvider<SubredditRepository, SubredditsNotifier>(
          create: (_) => SubredditsNotifier(),
          update: (_, repo, notifier) => notifier!..setRepository(repo),
        ),
        ChangeNotifierProxyProvider<SubredditRepository, SearchNotifier>(
          create: (_) => SearchNotifier(),
          update: (_, repo, notifier) => notifier!..setRepository(repo),
        ),
      ],
      child: MaterialApp(
        title: 'YARC - Yet Another Reddit Client',
        theme: appTheme,
        home: const HomeScreen(),
      ),
    );
  }
}

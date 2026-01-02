import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/service_locator.dart';
import '../models/subreddit.dart';
import '../services/reddit_service.dart';

/// Notifier for managing subscribed subreddits.
class SubredditsNotifier extends StateNotifier<List<Subreddit>> {
  final RedditService _redditService;

  SubredditsNotifier(this._redditService) : super([]);

  /// Fetches and sorts the user's subscribed subreddits.
  Future<void> fetchSubreddits() async {
    try {
      final subs = await _redditService.fetchSubscribedSubreddits();
      subs.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      state = subs;
    } catch (e) {
      // Keep current state on error
    }
  }

  /// Clears the subreddits list (e.g., on logout).
  void clear() {
    state = [];
  }
}

/// Provider for SubredditsNotifier using get_it.
final subredditsProvider =
    StateNotifierProvider<SubredditsNotifier, List<Subreddit>>((ref) {
      return SubredditsNotifier(getIt<RedditService>());
    });

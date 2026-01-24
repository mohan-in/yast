import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/subreddit.dart';
import 'post_card.dart';
import 'subreddit_info_card.dart';

/// A scrollable list of posts with pull-to-refresh and infinite scroll support.
class PostList extends StatelessWidget {
  final List<Post> posts;
  final bool isLoading;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(Post post) onPostTap;
  final Subreddit? subredditInfo;

  const PostList({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.scrollController,
    required this.onRefresh,
    required this.onPostTap,
    this.subredditInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate item count: subreddit header (if any) + posts + loading indicator
    final hasHeader = subredditInfo != null;
    final headerCount = hasHeader ? 1 : 0;
    final itemCount = headerCount + posts.length + (isLoading ? 1 : 0);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Subreddit info card at the top
          if (hasHeader && index == 0) {
            return SubredditInfoCard(subreddit: subredditInfo!);
          }

          // Adjust index for header offset
          final postIndex = index - headerCount;

          // Loading indicator at the bottom
          if (postIndex == posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = posts[postIndex];
          return PostCard(
            key: ValueKey(post.id),
            post: post,
            onTap: () => onPostTap(post),
          );
        },
      ),
    );
  }
}

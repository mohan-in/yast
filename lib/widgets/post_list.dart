import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/subreddit.dart';
import 'post_card.dart';
import 'subreddit_info_card.dart';

/// A sliver list of posts with infinite scroll support.
///
/// Must be used inside a [CustomScrollView].
class SliverPostList extends StatelessWidget {
  final List<Post> posts;
  final bool isLoading;
  final void Function(Post post) onPostTap;
  final Subreddit? subredditInfo;

  const SliverPostList({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.onPostTap,
    this.subredditInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty && isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Calculate item count: subreddit header (if any) + posts + loading indicator
    final hasHeader = subredditInfo != null;
    final headerCount = hasHeader ? 1 : 0;
    final itemCount = headerCount + posts.length + (isLoading ? 1 : 0);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
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
      }, childCount: itemCount),
    );
  }
}

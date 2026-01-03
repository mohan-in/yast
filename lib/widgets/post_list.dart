import 'package:flutter/material.dart';
import '../models/post.dart';
import 'post_card.dart';

/// A scrollable list of posts with pull-to-refresh and infinite scroll support.
class PostList extends StatelessWidget {
  final List<Post> posts;
  final bool isLoading;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final void Function(Post post) onPostTap;

  const PostList({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.scrollController,
    required this.onRefresh,
    required this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        itemCount: posts.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = posts[index];
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

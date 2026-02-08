import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/reddit_service.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_tile.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final RedditService redditService;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.redditService,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<List<Comment>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = widget.redditService.fetchComments(widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(pinned: true, title: Text('r/${widget.post.subreddit}')),
          SliverToBoxAdapter(
            child: PostCard(post: widget.post, expanded: true),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'Comments',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          FutureBuilder<List<Comment>>(
            future: _commentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No comments yet.')),
                );
              } else {
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return CommentTile(comment: snapshot.data![index]);
                  }, childCount: snapshot.data!.length),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

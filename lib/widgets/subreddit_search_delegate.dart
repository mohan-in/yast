import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subreddit.dart';
import '../notifiers/search_notifier.dart';
import '../utils/image_utils.dart';

/// A SearchDelegate for searching subreddits.
/// Returns the selected subreddit's display name when a result is tapped.
class SubredditSearchDelegate extends SearchDelegate<String?> {
  SubredditSearchDelegate();

  @override
  String get searchFieldLabel => 'Search subreddits';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            context.read<SearchNotifier>().clear();
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        context.read<SearchNotifier>().clear();
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Trigger search when user types
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchNotifier>().search(query);
    });

    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<SearchNotifier>(
      builder: (context, searchNotifier, child) {
        if (searchNotifier.query.length < 2) {
          return const Center(
            child: Text('Type at least 2 characters to search'),
          );
        }

        if (searchNotifier.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (searchNotifier.results.isEmpty) {
          return const Center(child: Text('No subreddits found'));
        }

        return ListView.builder(
          itemCount: searchNotifier.results.length,
          itemBuilder: (context, index) {
            final subreddit = searchNotifier.results[index];
            return _buildSubredditTile(context, subreddit);
          },
        );
      },
    );
  }

  Widget _buildSubredditTile(BuildContext context, Subreddit subreddit) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: subreddit.iconImg != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(
                ImageUtils.getCorsUrl(subreddit.iconImg!),
              ),
            )
          : const CircleAvatar(child: Icon(Icons.group)),
      title: Text(
        'r/${subreddit.displayName}',
        style: textTheme.bodyLarge?.copyWith(
          fontSize: (textTheme.bodyLarge?.fontSize ?? 16) - 1,
        ),
      ),
      subtitle: subreddit.title.isNotEmpty
          ? Text(
              subreddit.title,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: (textTheme.bodyMedium?.fontSize ?? 14) - 1,
              ),
            )
          : null,
      onTap: () {
        context.read<SearchNotifier>().clear();
        close(context, subreddit.displayName);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/date_utils.dart';

/// A widget displaying post metadata: time, comments, upvotes, and external link.
class PostMetadata extends StatelessWidget {
  final double createdUtc;
  final int numComments;
  final int ups;
  final String permalink;

  const PostMetadata({
    super.key,
    required this.createdUtc,
    required this.numComments,
    required this.ups,
    required this.permalink,
  });

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.reddit.com$permalink');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateUtilsHelper.formatTimeAgo(createdUtc),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: _launchURL,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Open on Reddit',
            ),
            const SizedBox(width: 16),
            const Icon(Icons.mode_comment_outlined, size: 16),
            const SizedBox(width: 4),
            Text('$numComments'),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_upward, size: 16),
            const SizedBox(width: 4),
            Text('$ups'),
          ],
        ),
      ],
    );
  }
}

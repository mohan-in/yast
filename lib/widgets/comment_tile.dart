import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../utils/html_utils.dart';
import '../utils/date_utils.dart';
import 'markdown_content.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;
  final int depth;

  const CommentTile({super.key, required this.comment, this.depth = 0});

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _isCollapsed = false;

  // Define rainbow colors for depth lines
  static const List<Color> _depthColors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Select color based on reply depth (next level)
    final nextDepth = widget.depth + 1;
    final depthColor = _depthColors[widget.depth % _depthColors.length];

    // Build the content of the comment tile (header, body, replies)
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comment Content
        InkWell(
          onTap: _toggleCollapse,
          child: Padding(
            // Reduced horizontal padding from 16.0 to 8.0 to save space
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Text(
                            'u/${widget.comment.author}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateUtilsHelper.formatTimeAgo(
                              widget.comment.createdUtc,
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_isCollapsed) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.expand_more,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.comment.replies.length} replies',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Body (if not collapsed)
                      if (!_isCollapsed) ...[
                        const SizedBox(height: 4),
                        ...widget.comment.body
                            .split(RegExp(r'\n\s*\n'))
                            .where((p) => p.trim().isNotEmpty)
                            .expand(
                              (p) => [
                                MarkdownContent(
                                  text: HtmlUtils.unescape(p.trim()),
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                              ],
                            )
                            .toList()
                          ..removeLast(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Replies
        if (!_isCollapsed && widget.comment.replies.isNotEmpty)
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    // Reduced indentation margin from 16.0 to 8.0
                    margin: const EdgeInsets.only(left: 8.0),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          // Apply rainbow color to the border
                          color: depthColor.withOpacity(0.5),
                          width: 2.0,
                        ),
                      ),
                    ),
                    child: Column(
                      children: widget.comment.replies
                          .map(
                            (reply) =>
                                CommentTile(comment: reply, depth: nextDepth),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    // If this is a top-level comment (depth 0), wrap it in a Card
    if (widget.depth == 0) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: content,
      );
    }

    return content;
  }
}

class Comment {
  final String id;
  final String author;
  final String body;
  final int ups;
  final double createdUtc;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.author,
    required this.body,
    required this.ups,
    required this.createdUtc,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<Comment> replies = [];
    if (data['replies'] != null && data['replies'] is Map) {
      final repliesData = data['replies']['data'];
      if (repliesData != null && repliesData['children'] != null) {
        final children = repliesData['children'] as List;
        replies = children
            .where((c) => c['kind'] == 't1')
            .map((c) => Comment.fromJson(c))
            .toList();
      }
    }

    return Comment(
      id: data['id'] ?? '',
      author: data['author'] ?? '[deleted]',
      body: data['body'] ?? '',
      ups: data['ups'] ?? 0,
      createdUtc: (data['created_utc'] as num?)?.toDouble() ?? 0.0,
      replies: replies,
    );
  }
}

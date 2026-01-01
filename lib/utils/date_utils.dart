class DateUtilsHelper {
  static String formatTimeAgo(double createdUtc) {
    final now = DateTime.now().toUtc();
    final created = DateTime.fromMillisecondsSinceEpoch(
      (createdUtc * 1000).toInt(),
      isUtc: true,
    );
    final difference = now.difference(created);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

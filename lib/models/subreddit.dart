import 'package:draw/draw.dart' as draw;
import '../utils/html_utils.dart';

class Subreddit {
  final String displayName;
  final String title;
  final String? iconImg;
  final String url;
  final int? subscriberCount;
  final String? description;

  Subreddit({
    required this.displayName,
    required this.title,
    this.iconImg,
    required this.url,
    this.subscriberCount,
    this.description,
  });

  factory Subreddit.fromDraw(draw.Subreddit sub) {
    String? icon;
    final iconUri = sub.iconImage;
    if (iconUri != null) {
      icon = HtmlUtils.unescape(iconUri.toString());
    }

    if ((icon == null || icon.isEmpty) && sub.data != null) {
      final commIcon = sub.data!['community_icon'];
      if (commIcon != null && commIcon is String && commIcon.isNotEmpty) {
        icon = HtmlUtils.unescape(commIcon);
      }
    }

    if (icon != null && icon.isEmpty) icon = null;

    // Extract subscriber count from the raw data
    int? subscribers;
    if (sub.data != null && sub.data!['subscribers'] != null) {
      subscribers = sub.data!['subscribers'] as int?;
    }

    // Extract public description
    String? description;
    if (sub.data != null && sub.data!['public_description'] != null) {
      description = sub.data!['public_description'] as String?;
      if (description != null && description.isEmpty) description = null;
    }

    return Subreddit(
      displayName: sub.displayName,
      title: sub.title,
      iconImg: icon,
      url: sub.path,
      subscriberCount: subscribers,
      description: description,
    );
  }
}

class Subreddit {
  final String displayName;
  final String title;
  final String? iconImg;
  final String url;

  Subreddit({
    required this.displayName,
    required this.title,
    this.iconImg,
    required this.url,
  });

  factory Subreddit.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    String? icon = data['icon_img'];
    if (icon != null && icon.isNotEmpty) {
      // Decode HTML entities if present
      icon = icon.replaceAll('&amp;', '&');
    } else {
      icon = data['community_icon'];
      if (icon != null && icon.isNotEmpty) {
        // Community icons often have query params, remove them if needed or use as is
        // but definitely decode
        icon = icon.replaceAll('&amp;', '&');
      }
    }

    // Fallback if icon is empty string
    if (icon == '') icon = null;

    return Subreddit(
      displayName: data['display_name'],
      title: data['title'],
      iconImg: icon,
      url: data['url'],
    );
  }
}

/// A data model representing a Reddit post.
class Post {
  /// The unique ID of the post (e.g., "t3_12345").
  final String id;

  /// The title of the post.
  final String title;

  /// The username of the author (without "u/").
  final String author;

  /// The subreddit name (without "r/").
  final String subreddit;

  /// The number of upvotes.
  final int ups;

  /// The URL of the thumbnail image, if available.
  final String? thumbnail;

  /// The URL of the main image, if available.
  final String? imageUrl;

  /// The permalink path to the post (e.g., "/r/flutter/comments/...").
  final String permalink;

  /// The number of comments.
  final int numComments;

  /// The textual content of the post (selftext).
  final String content;

  /// The creation time in UTC seconds.
  final double createdUtc;

  /// A list of image URLs for gallery posts.
  final List<String> images;

  Post({
    required this.id,
    required this.title,
    required this.author,
    required this.subreddit,
    required this.ups,
    required this.numComments,
    this.thumbnail,
    this.imageUrl,
    required this.permalink,
    required this.content,
    required this.createdUtc,
    this.images = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    String? imageUrl;
    List<String> images = [];

    // Parse logic for imageUrl (single image)
    if (data['preview'] != null &&
        data['preview']['images'] != null &&
        data['preview']['images'].isNotEmpty) {
      final image = data['preview']['images'][0]['source'];
      if (image != null && image['url'] != null) {
        imageUrl = (image['url'] as String).replaceAll('&amp;', '&');
      }
    }

    if (imageUrl == null && data['media_metadata'] != null) {
      final metadata = data['media_metadata'] as Map;
      for (final key in metadata.keys) {
        final item = metadata[key];
        if (item['status'] == 'valid' && item['e'] == 'Image') {
          if (item['s'] != null && item['s']['u'] != null) {
            imageUrl = (item['s']['u'] as String).replaceAll('&amp;', '&');
            break; // Use the first valid image found
          }
        }
      }
    }

    if (imageUrl == null && data['url'] != null) {
      final String url = data['url'];
      if (url.endsWith('.jpg') ||
          url.endsWith('.jpeg') ||
          url.endsWith('.png') ||
          url.endsWith('.gif')) {
        imageUrl = url;
      }
    }

    // Parse logic for gallery images
    if (data['gallery_data'] != null && data['media_metadata'] != null) {
      final galleryData = data['gallery_data'];
      final metadata = data['media_metadata'];
      if (galleryData['items'] != null) {
        for (final item in galleryData['items']) {
          final mediaId = item['media_id'];
          if (metadata[mediaId] != null) {
            final mediaItem = metadata[mediaId];
            if (mediaItem['status'] == 'valid' && mediaItem['e'] == 'Image') {
              if (mediaItem['s'] != null && mediaItem['s']['u'] != null) {
                String url = (mediaItem['s']['u'] as String).replaceAll(
                  '&amp;',
                  '&',
                );
                images.add(url);
              }
            }
          }
        }
      }
    } else if (imageUrl != null) {
      // If not a gallery but has a main image, add it to images list as fallback
      images.add(imageUrl);
    }

    return Post(
      id: data['id'],
      title: data['title'],
      author: data['author'],
      subreddit: data['subreddit'],
      ups: data['ups'],
      numComments: data['num_comments'] ?? 0,
      thumbnail:
          data['thumbnail'] != 'self' &&
              data['thumbnail'] != 'default' &&
              data['thumbnail'] != 'spoiler' &&
              data['thumbnail'] != 'image' &&
              data['thumbnail'] != 'nsfw' &&
              (data['thumbnail'] as String).startsWith('http')
          ? data['thumbnail']
          : null,
      imageUrl: imageUrl,
      permalink: data['permalink'],
      content: data['selftext'] ?? '',
      createdUtc: (data['created_utc'] as num).toDouble(),
      images: images,
    );
  }
}

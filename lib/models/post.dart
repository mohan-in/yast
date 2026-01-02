import 'package:draw/draw.dart' as sys;
import '../utils/html_utils.dart';

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

  /// Whether the post contains a video.
  final bool isVideo;

  /// The URL of the video, if available.
  final String? videoUrl;

  /// Whether the post is a YouTube video.
  final bool isYoutube;

  /// The YouTube video ID, if available.
  final String? youtubeId;

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
    this.isVideo = false,
    this.videoUrl,
    this.isYoutube = false,
    this.youtubeId,
  });

  factory Post.fromSubmission(sys.Submission submission) {
    String? imageUrl;
    List<String> images = [];
    bool isVideo = submission.isVideo;
    String? videoUrl;
    bool isYoutube = false;
    String? youtubeId;

    // Attempt to find the main image URL
    final preview = submission.preview;
    if (preview.isNotEmpty) {
      final image = preview[0].source;
      imageUrl = HtmlUtils.unescape(image.url.toString());
    }

    // Check for direct URL if it's an image
    if (imageUrl == null) {
      final String url = submission.url.toString();
      if (url.endsWith('.jpg') ||
          url.endsWith('.jpeg') ||
          url.endsWith('.png') ||
          url.endsWith('.gif')) {
        imageUrl = url;
      }
    }

    if (submission.data != null) {
      final data = submission.data!.cast<String, dynamic>();
      _parseGalleryData(data, images);

      // 1. Try extracting from main post data
      videoUrl = _extractVideoUrl(data);

      // 2. If no video found, check if it's a crosspost
      if (videoUrl == null && data['crosspost_parent_list'] != null) {
        final List crossposts = data['crosspost_parent_list'];
        if (crossposts.isNotEmpty) {
          final parentData = crossposts[0] as Map;
          videoUrl = _extractVideoUrl(parentData);
          if (videoUrl != null) {
            isVideo = true;
          }
        }
      }

      if (videoUrl != null) {
        isVideo = true;
      }

      // Check for YouTube in main data
      if (!isVideo) {
        youtubeId = _extractYoutubeId(data);
        if (youtubeId != null) {
          isYoutube = true;
        } else if (data['crosspost_parent_list'] != null) {
          // Check for YouTube in crosspost parent
          final List crossposts = data['crosspost_parent_list'];
          if (crossposts.isNotEmpty) {
            final parentData = crossposts[0] as Map;
            youtubeId = _extractYoutubeId(parentData);
            if (youtubeId != null) {
              isYoutube = true;
            }
          }
        }
      }
    }

    if (images.isEmpty && imageUrl != null) {
      images.add(imageUrl);
    }

    return Post(
      id: submission.id ?? '',
      title: submission.title,
      author: submission.author,
      subreddit: submission.subreddit.displayName,
      ups: submission.upvotes,
      numComments: submission.numComments,
      thumbnail: submission.thumbnail.toString().startsWith('http')
          ? submission.thumbnail.toString()
          : null,
      imageUrl: imageUrl,
      permalink: submission.data!['permalink'] ?? '',
      content: submission.selftext ?? '',
      createdUtc: submission.createdUtc.millisecondsSinceEpoch / 1000,
      images: images,
      isVideo: isVideo && videoUrl != null,
      videoUrl: videoUrl,
      isYoutube: isYoutube,
      youtubeId: youtubeId,
    );
  }

  static void _parseGalleryData(
    Map<String, dynamic> data,
    List<String> images,
  ) {
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
                String url = HtmlUtils.unescape(mediaItem['s']['u'] as String);
                images.add(url);
              }
            }
          }
        }
      }
    }
  }

  static String? _extractVideoUrl(Map dataMap) {
    final data = dataMap.cast<String, dynamic>();
    String? url;
    if (data['secure_media'] != null &&
        data['secure_media']['reddit_video'] != null) {
      url =
          data['secure_media']['reddit_video']['hls_url'] ??
          data['secure_media']['reddit_video']['fallback_url'];
    } else if (data['media'] != null && data['media']['reddit_video'] != null) {
      url =
          data['media']['reddit_video']['hls_url'] ??
          data['media']['reddit_video']['fallback_url'];
    } else if (data['preview'] != null &&
        data['preview']['reddit_video_preview'] != null) {
      url =
          data['preview']['reddit_video_preview']['hls_url'] ??
          data['preview']['reddit_video_preview']['fallback_url'];
    } else if (data['url'] != null && data['url'].toString().endsWith('.mp4')) {
      url = data['url'];
    }
    return url != null ? HtmlUtils.unescape(url) : null;
  }

  static String? _extractYoutubeId(Map dataMap) {
    final data = dataMap.cast<String, dynamic>();
    if (data['domain'] == 'youtube.com' ||
        data['domain'] == 'youtu.be' ||
        data['domain'] == 'm.youtube.com' ||
        (data['url'] != null &&
            data['url'].toString().contains('youtube.com')) ||
        (data['url'] != null && data['url'].toString().contains('youtu.be'))) {
      final String url = HtmlUtils.unescape(data['url'].toString());
      final RegExp regExp = RegExp(
        r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?)|(shorts\/)|(live\/))\??v?=?([^#&?]*).*',
        caseSensitive: false,
      );
      final match = regExp.firstMatch(url);
      if (match != null && match.group(9) != null) {
        final id = match.group(9);
        if (id != null && id.length == 11) {
          return id;
        }
      }
    }
    return null;
  }
}
